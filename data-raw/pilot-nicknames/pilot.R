# Nickname / canonical first-name pilot. Plan and results: data-raw/PLAN-nicknames.md.
#
# Run from the package root:  source("data-raw/pilot-nicknames/pilot.R")
# Needs the sibling synthid repo: dev/data/linked_slice.rds (33,984 Form 990
# Part VII records, 1,000 orgs, 2010-2012, linked into persons by synthid) and
# R/first_names.R (the old 70-name nickname_table(), as the baseline).
#
# Caveats on the same-person test: synthid linked these records using its
# 70-name table, and first_name_pairs was itself built from within-org
# person links of the national panel, which includes these organizations. So
# same-person recall is partly circular and is an upper bound. The
# different-person test (two people on one return in one year) does not have
# this problem.

suppressMessages({ devtools::load_all(quiet = TRUE); library(data.table) })
out_dir <- "data-raw/pilot-nicknames/results"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
set.seed(20261123)

# ---- data ------------------------------------------------------------------
d <- as.data.table(readRDS("../synthid/dev/data/linked_slice.rds"))
cache <- file.path(out_dir, "parsed_unique.rds")
if (file.exists(cache)) { pu <- readRDS(cache) } else {
  pu <- as.data.table(parse_names(unique(d$name))); saveRDS(pu, cache)
}
p <- pu[match(d$name, pu$name)]
d <- cbind(d[, .(ein, taxyr, name, EMP_ID)],
           p[, .(salutation, first = first_name, last = last_name, gender, gender_confidence)])
d <- d[nchar(first) > 1]

# ---- comparators -------------------------------------------------------------
ex <- parse("../synthid/R/first_names.R"); e <- new.env()
for (x in ex) if (is.call(x) && identical(x[[1]], as.name("<-")) &&
                  identical(as.character(x[[2]]), "nickname_table")) eval(x, e)
nt <- e$nickname_table()
key_old <- paste(rep(names(nt), lengths(nt)), unlist(nt))
v <- first_name_pairs[lexicon == TRUE]
key_lex <- paste(v$name_short, v$name_long)
dir_in <- function(a, b, k) paste(a, b) %in% k | paste(b, a) %in% k

# ---- pairs -----------------------------------------------------------------
pf <- unique(d[, .(EMP_ID, first, salutation, gender, gender_confidence)], by = c("EMP_ID", "first"))
pf[, row := .I]
pp <- pf[, if (.N >= 2) { cb <- utils::combn(.N, 2); .(ra = row[cb[1, ]], rb = row[cb[2, ]]) }, by = EMP_ID]
pp[, `:=`(a = pf$first[ra], b = pf$first[rb])]
dy <- unique(d, by = c("ein", "taxyr", "EMP_ID"))
dy[, row := pf[dy, on = .(EMP_ID, first), row]]
neg <- dy[dy, on = .(ein, taxyr), allow.cartesian = TRUE, nomatch = 0L
          ][EMP_ID < i.EMP_ID & first != i.first,
            .(ein, taxyr, a = first, b = i.first, la = last, lb = i.last, ra = row, rb = i.row)]
# people seen under a nickname and its formal name (a lexicon nickname pair)
vn <- first_name_pairs[type == "nickname" & lexicon == TRUE]
vn[, `:=`(nick = fifelse(formal == "long", name_short, name_long),
          frm  = fifelse(formal == "long", name_long, name_short))]
lab <- pp[paste(a, b) %in% paste(vn$nick, vn$frm) | paste(b, a) %in% paste(vn$nick, vn$frm)]
lab[, nick_is_a := paste(a, b) %in% paste(vn$nick, vn$frm)]
cat("records:", nrow(d), " persons:", uniqueN(d$EMP_ID),
    " same-person pairs:", nrow(pp), " different-person pairs:", nrow(neg),
    " nickname+formal people:", nrow(lab), "\n")

# ---- sweep -----------------------------------------------------------------
lm <- c("lexicon", "misspelling")
settings <- list(
  list(min_share = 0.6,  rate = 0.002, spelling = lm),   # default
  list(min_share = 0.5,  rate = 0.002, spelling = lm),
  list(min_share = 0.75, rate = 0.002, spelling = lm),
  list(min_share = 0.6,  rate = 0,     spelling = lm),
  list(min_share = 0.6,  rate = 0.001, spelling = lm),
  list(min_share = 0.6,  rate = 0.005, spelling = lm),
  list(min_share = 0.6,  rate = 0.002, spelling = "lexicon"),
  list(min_share = 0.6,  rate = 0.002, spelling = c(lm, "sound_alike"))
)
rows <- list(data.table(setting = "old: synthid 70-name direct pairs", rule = "direct pair",
                        same_person = round(mean(pp$a == pp$b | dir_in(pp$a, pp$b, key_old)), 3),
                        diff_per_1k = round(1000 * mean(dir_in(neg$a, neg$b, key_old)), 2)))
t_lookup <- NA
for (s in settings) {
  t0 <- Sys.time()
  nk <- nickname_lookup(pf$first, pf$gender, pf$gender_confidence, pf$salutation,
                        min_share = s$min_share, min_nick_rate = s$rate, spelling = s$spelling)
  if (is.na(t_lookup)) t_lookup <- as.numeric(Sys.time() - t0, units = "secs")
  can <- nk$first_name_canonical
  lab_key <- mean(can[lab$ra] == can[lab$rb])
  rec <- nk[match(paste(d$EMP_ID, d$first), paste(pf$EMP_ID, pf$first)), ]
  nm <- sprintf("min_share %s, min_nick_rate %s, spelling %s", s$min_share, s$rate,
                paste(s$spelling, collapse = "+"))
  for (r in c("canonical", "canonical or lexicon pair")) {
    f <- if (r == "canonical") function(a, b, ra, rb) can[ra] == can[rb]
         else function(a, b, ra, rb) can[ra] == can[rb] | dir_in(a, b, key_lex)
    rows[[length(rows) + 1]] <- data.table(
      setting = nm, rule = r,
      same_person = round(mean(f(pp$a, pp$b, pp$ra, pp$rb)), 3),
      diff_per_1k = round(1000 * mean(f(neg$a, neg$b, neg$ra, neg$rb)), 2),
      nick_formal_same_key = round(lab_key, 3),
      records_rewritten = round(mean(rec$first_name_canonical != d$first), 3),
      records_ambiguous = round(mean(rec$canonical_rule == "ambiguous"), 3))
  }
}
sw <- rbindlist(rows, fill = TRUE)
fwrite(sw, file.path(out_dir, "sweep.csv"))
print(sw)

# ---- details at the default setting ------------------------------------------
nk <- nickname_lookup(pf$first, pf$gender, pf$gender_confidence, pf$salutation)
pf <- cbind(pf, nk)
can <- pf$first_name_canonical
rec <- pf[match(paste(d$EMP_ID, d$first), paste(pf$EMP_ID, pf$first))]

cov <- rec[, .N, by = .(first_name_type)][, pct := round(100 * N / sum(N), 1)][order(-N)]
rul <- rec[, .N, by = .(canonical_rule)][, pct := round(100 * N / sum(N), 1)][order(-N)]
fwrite(cov, file.path(out_dir, "coverage-type.csv")); fwrite(rul, file.path(out_dir, "coverage-rule.csv"))
print(cov); print(rul)

fwrite(rec[first != first_name_canonical, .N, by = .(first, canonical = first_name_canonical, rule = canonical_rule)][order(-N)],
       file.path(out_dir, "rewrites.csv"))
fwrite(rec[canonical_rule == "ambiguous", .N, by = .(first, gender, formal = first_name_formal)][order(-N)],
       file.path(out_dir, "ambiguous.csv"))
fwrite(rec[first_name_type == "unknown", .N, by = first][order(-N)][1:100],
       file.path(out_dir, "top-unknown.csv"))

pp[, `:=`(ca = can[ra], cb = can[rb])]
pp[, `:=`(same_canon = ca == cb, lex = dir_in(a, b, key_lex), old = dir_in(a, b, key_old))]
fwrite(pp[!same_canon & !lex, .(a, b, ca, cb)], file.path(out_dir, "same-person-missed.csv"))
neg[, `:=`(ca = can[ra], cb = can[rb])]
neg[, pr := paste(pmin(a, b), pmax(a, b))]
fwrite(neg[ca == cb, .N, by = .(pr, canonical = ca)][order(-N)],
       file.path(out_dir, "different-person-same-canonical.csv"))

lab[, `:=`(nick = fifelse(nick_is_a, a, b), frm = fifelse(nick_is_a, b, a))]
lab[, `:=`(c_nick = can[fifelse(nick_is_a, ra, rb)], c_frm = can[fifelse(nick_is_a, rb, ra)])]
fwrite(lab[c_nick != c_frm, .N, by = .(nick, frm, c_nick, c_frm)][order(-N)],
       file.path(out_dir, "nick-formal-key-misses.csv"))

# ---- runtime -------------------------------------------------------------------
x <- get_example_names(1000)
t_off <- system.time(a <- parse_names(x))[["elapsed"]]
t_on  <- system.time(parse_names(x, add_nicknames = TRUE))[["elapsed"]]
rt <- data.table(parse_1000_s = t_off, parse_1000_with_nicknames_s = t_on,
                 lookup_unique_persons_names_s = round(t_lookup, 2), n_lookup = nrow(pf))
fwrite(rt, file.path(out_dir, "runtime.csv")); print(rt)
