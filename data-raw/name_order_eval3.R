# Name order for three-word names: evaluation behind three_token_surname_first()
# (0.2.2). Compares the old rule (check_if_surname() on each word, unlisted =
# surname) with the two-word written-order prior applied to the first and last
# words. Result: 28,811 labelled names, 672 surname first; old rule 1,298
# errors (1,210 wrong reorders), prior with a = 20, unlisted 0.85, odds 30
# 235 errors (53 wrong reorders).
#
# Labels, as in data-raw/name_order_eval.R: Form 990 Part VII names on the same
# return (EIN + tax year) are usually all written the same way. For each name, the
# convention is read from the OTHER names on its return that show their order
# without the census shares of the name being labelled:
#   * "LAST, FIRST" (comma)                  -> surname first
#   * "AAA BBB C" (trailing initial)          -> surname first
#   * "AAA B CCC" (middle initial)            -> first name first
#   * two-word names with an unmistakable given name (share >= 0.9, 1,000+
#     records) and an unmistakable surname    -> their order
# A name is labelled S (surname first) when 3+ such names on the return are
# 80%+ surname first, F when 3+ are 10% or less, otherwise left out.
#
# The labels are noisy both ways (returns mix conventions), so use them to
# compare rules, not as ground truth for single names.
#
# Needs npmerger's duckdb (part7). Run from the package root:
#   Rscript data-raw/name_order_eval3.R [path/to/npmerger.duckdb]
# Takes a few minutes.

args <- commandArgs(TRUE)
db <- if (length(args)) args[1] else "C:/Users/jlecy/Documents/NPMERGER/npmerger.duckdb"
suppressMessages({ devtools::load_all(quiet = TRUE); library(data.table) })
con <- DBI::dbConnect(duckdb::duckdb(dbdir = db, read_only = TRUE))
d <- as.data.table(DBI::dbGetQuery(con, "SELECT DISTINCT EIN2, TAX_YEAR, PERSON_NAME AS raw FROM part7 WHERE PERSON_NAME IS NOT NULL"))
DBI::dbDisconnect(con, shutdown = TRUE)
d[, u := toupper(trimws(gsub("[[:space:]]+", " ", raw)))][, filing := paste(EIN2, TAX_YEAR)]
bad <- c(prx, sfx)
lk <- function(t) { cd <- get_census_data(t); list(f = cd$first_name_value, l = cd$last_name_value) }
# evidence names
d[, ev := NA_integer_]                                 # 1 = surname first, 0 = first name first
d[grepl("^[A-Z]{2,}, ?[A-Z]{2,}", u), ev := 1L]
three <- d[is.na(ev) & grepl("^[A-Z]{2,} [A-Z]{2,} [A-Z]$|^[A-Z]{2,} [A-Z] [A-Z]{2,}$", u)]
three[, c("a", "b", "c") := tstrsplit(u, " ")]
three <- three[!a %in% bad & !b %in% bad & !c %in% bad]
d[three[nchar(c) == 1], on = c("filing", "u"), ev := 1L]
d[three[nchar(b) == 1], on = c("filing", "u"), ev := 0L]
two <- d[grepl("^[A-Z]{2,} [A-Z]{2,}$", u)]
two[, c("w1", "w2") := tstrsplit(u, " ")]
two <- two[!w1 %in% bad & !w2 %in% bad]
x1 <- lk(two$w1); x2 <- lk(two$w2)
two[, `:=`(f1 = x1$f, l1 = x1$l, f2 = x2$f, l2 = x2$l)]
strong_f <- function(f, l) f + l >= 1000 & f / pmax(f + l, 1) >= 0.9
strong_l <- function(f, l) f + l >= 1000 & l / pmax(f + l, 1) >= 0.9
two[, ev2 := fifelse(strong_f(f1, l1) & strong_l(f2, l2), 0L, fifelse(strong_l(f1, l1) & strong_f(f2, l2), 1L, NA_integer_))]
d[two[!is.na(ev2)], on = c("filing", "u"), ev := i.ev2]
# filing convention, leaving the target name out
conv <- d[!is.na(ev), .(n_ev = .N, s_ev = sum(ev)), by = filing]
two[conv, on = "filing", `:=`(n_ev = i.n_ev, s_ev = i.s_ev)]
two[is.na(n_ev), `:=`(n_ev = 0L, s_ev = 0L)]
two[!is.na(ev2), `:=`(n_ev = n_ev - 1L, s_ev = s_ev - ev2)]
two[, label := fifelse(n_ev >= 3 & s_ev / pmax(n_ev, 1) >= 0.8, "S", fifelse(n_ev >= 3 & s_ev / pmax(n_ev, 1) <= 0.1, "F", NA_character_))]
two <- two[!is.na(label)]
cat("labelled two-word rows:", nrow(two), " surname first:", sum(two$label == "S"), "\n")

# 1. grid over the prior's settings (vectorised; same formula as two_token_surname())
truth <- two$label == "S"

# three-word names with no initials, titles or suffixes
w3 <- d[grepl("^[A-Z]{2,} [A-Z]{2,} [A-Z]{2,}$", u)]
w3[, c("w1", "w2", "w3") := tstrsplit(u, " ")]
w3 <- w3[!w1 %in% bad & !w2 %in% bad & !w3 %in% bad]
y1 <- lk(w3$w1); y2 <- lk(w3$w2); y3 <- lk(w3$w3)
w3[, `:=`(f1 = y1$f, l1 = y1$l, f2 = y2$f, l2 = y2$l, f3 = y3$f, l3 = y3$l)]
w3[conv, on = "filing", `:=`(n_ev = i.n_ev, s_ev = i.s_ev)]
w3[is.na(n_ev), `:=`(n_ev = 0L, s_ev = 0L)]
w3[, label := fifelse(n_ev >= 3 & s_ev / pmax(n_ev, 1) >= 0.8, "S", fifelse(n_ev >= 3 & s_ev / pmax(n_ev, 1) <= 0.1, "F", NA_character_))]
w3 <- w3[!is.na(label)]
cat("labelled three-word rows:", nrow(w3), " surname first:", sum(w3$label == "S"), "\n")
truth3 <- w3$label == "S"

# the rule before 0.2.2: check_if_surname() (unlisted = surname)
iss <- function(f, l) ifelse(f + l == 0, TRUE, l / pmax(f + l, 1) > 0.5)
s1 <- iss(w3$f1, w3$l1); s2 <- iss(w3$f2, w3$l2); s3 <- iss(w3$f3, w3$l3)
old_rot <- (s1 & !s2) | (s1 & s2 & !s3)
cat("old rule: errors", sum(old_rot != truth3), " reorders", sum(old_rot),
    " of which first-name-first", sum(old_rot & !truth3), "\n")

# the prior: tokens 1 and 3 as in two_token_surname()
share <- function(f, l, a, su) fifelse(f + l > 0, (l + a) / (f + l + 2 * a), su)
prior3 <- function(a, su, odds) {
  t1 <- share(w3$f1, w3$l1, a, su); t3 <- share(w3$f3, w3$l3, a, su)
  (t1 * (1 - t3)) / ((1 - t1) * t3) > odds
}
grid <- CJ(a = c(20, 100), su = c(0.5, 0.7, 0.85), odds = c(10, 30, 100, 300, 1000))
grid[, errors := mapply(function(a, su, odds) sum(prior3(a, su, odds) != truth3), a, su, odds)]
grid[, reorders := mapply(function(a, su, odds) sum(prior3(a, su, odds)), a, su, odds)]
grid[, wrong_reorders := mapply(function(a, su, odds) sum(prior3(a, su, odds) & !truth3), a, su, odds)]
print(grid[order(errors)][1:12])
saveRDS(w3, file.path(tempdir(), "w3.rds"))
