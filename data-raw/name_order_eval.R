# Name order for two-word names: evaluation used to tune two_token_surname().
#
# Labels: Form 990 Part VII names on the same return (EIN + tax year) are
# usually all written the same way. For each plain two-word name, the
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
#   Rscript data-raw/name_order_eval.R [path/to/npmerger.duckdb]
# Takes about five minutes (it parses every distinct name).

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
k1 <- two$f1 + two$l1 > 0; k2 <- two$f2 + two$l2 > 0
prior_swap <- function(a, su, odds) {
  s1 <- fifelse(k1, (two$l1 + a) / (two$f1 + two$l1 + 2 * a), su)
  s2 <- fifelse(k2, (two$l2 + a) / (two$f2 + two$l2 + 2 * a), su)
  sw <- (s1 * (1 - s2)) / ((1 - s1) * s2) > odds
  sw[nchar(two$w1) <= 2 & !k1] <- FALSE
  sw
}
grid <- CJ(a = c(20, 50, 100, 300, 1000), su = c(0.5, 0.7, 0.85, 0.95), odds = c(5, 10, 20, 30, 50, 100))
grid[, errors := mapply(function(a, su, odds) sum(prior_swap(a, su, odds) != truth), a, su, odds)]
print(grid[order(errors)][1:10])

# 2. the package's rule (devtools::load_all), through parse_name(): all rules
un <- unique(two$u)
p <- rbindlist(lapply(un, parse_name))
two[data.table(u = un, last = p$last_name), on = "u", parsed_last := i.last]
ok <- two$parsed_last %in% c(two$w1, two$w2)
cat("\nparse_name(): errors", sum((two$parsed_last == two$w1)[ok] != truth[ok]), "of", sum(ok),
    "; surname-first names swapped", round(100 * mean((two$parsed_last == two$w1)[ok & truth]), 1), "%",
    "; first-name-first kept", round(100 * mean((two$parsed_last == two$w2)[ok & !truth]), 2), "%\n")
