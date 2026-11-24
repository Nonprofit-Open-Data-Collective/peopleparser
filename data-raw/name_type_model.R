# Build the organisation model behind classify_names() and the list of real
# surnames that split_run_together() must not split. Writes R/sysdata.rda.
#
# Input: the national Form 990 Part VII files (F9-P07-T01-COMPENSATION-<year>
# .parquet, 2009-2025, from panel990::download_tables()), 61 million rows.
# Set PART7_PARQUET to a glob for them.
#
# Labels:
#   organisations - the filers' own names (ORG_NAME_L1, 982,000 distinct
#     nonprofit names), plus person-field names with a legal-form word (INC,
#     LLC, BANK, ...) that do not start with a person's name, so banks and
#     companies serving as trustees are represented;
#   people - all other names in the person-name field (9.4 million distinct;
#     about 0.1% are really organisations or notes).
# The business-name field (NAME_ORG_L1) is not used: most of its entries are
#   people's names.
#
# Model: every word gets a smoothed log-likelihood ratio (organisation names
# vs people's names, words in 10+ names, clamped to [-5, 8]), computed on two
# thirds of the names. A logistic regression on the other third combines the
# word scores with the number of words and census evidence (org_features()).
# Half of that third trains the regression, half tests it.

suppressMessages({ library(data.table); devtools::load_all(quiet = TRUE) })
glob <- Sys.getenv("PART7_PARQUET",
                   "C:/Users/jlecy/Documents/NPMERGER/PANEL990/*/F9-P07-T01-COMPENSATION-*.parquet")
con <- DBI::dbConnect(duckdb::duckdb())
q <- function(s) as.data.table(DBI::dbGetQuery(con, s))
src <- sprintf("read_parquet('%s', union_by_name = true)", glob)
cl  <- function(v) sprintf("trim(regexp_replace(regexp_replace(regexp_replace(upper(%s), '[^A-Z0-9&]+', ' ', 'g'), '&', ' & ', 'g'), ' +', ' ', 'g'))", v)

# ---- labelled names -------------------------------------------------------
legal <- "(^| )(INC|INCORPORATED|LLC|LLP|PLLC|CORP|CORPORATION|COMPANY|FSB|BANK|BANCORP|TRUST CO|FOUNDATION|ASSOCIATION|UNIVERSITY)( |$)"
DBI::dbExecute(con, sprintf("CREATE TABLE L AS
  WITH p AS (SELECT %s nm, count(*) n FROM %s
             WHERE F9_07_COMP_DTK_NAME_PERS IS NOT NULL AND coalesce(F9_07_COMP_DTK_NAME_ORG_L1, '') = '' GROUP BY 1),
       f AS (SELECT DISTINCT %s nm FROM %s)
  SELECT nm, max(y) y, CASE WHEN max(filer) = 1 THEN 'filer' WHEN max(y) = 1 THEN 'rule' ELSE 'person' END src FROM (
    SELECT nm, 1 y, 1 filer FROM f
    UNION ALL SELECT nm, CASE WHEN regexp_matches(nm, '%s') THEN 1 ELSE 0 END, 0 FROM p)
  WHERE nm <> '' GROUP BY nm",
  cl("F9_07_COMP_DTK_NAME_PERS"), src, cl("ORG_NAME_L1"), src, legal))
DBI::dbExecute(con, "ALTER TABLE L ADD COLUMN part INTEGER; UPDATE L SET part = hash(nm || 'x') % 3")
print(q("SELECT src, count(*) n FROM L GROUP BY 1 ORDER BY 1"))

# ---- word scores (parts 0 and 1) -------------------------------------------
tok <- q("SELECT t, sum(y) d1, sum(1 - y) d0 FROM (
            SELECT DISTINCT nm, y, unnest(string_split(regexp_replace(nm, '[0-9]+', '#', 'g'), ' ')) t
            FROM L WHERE part < 2) WHERE t <> '' GROUP BY t")
N <- q("SELECT sum(y) n1, sum(1 - y) n0 FROM L WHERE part < 2")
tok[, llr := log((d1 + 0.5) / N$n1) - log((d0 + 0.5) / N$n0)]
vocab <- tok[d1 + d0 >= 10, .(token = t, llr = round(pmin(pmax(llr, -5), 8), 3))]
setorder(vocab, token)
cat("vocabulary:", nrow(vocab), "words\n")
venv <- list2env(as.list(setNames(vocab$llr, vocab$token)), hash = TRUE)

# ---- regression (part 2) ---------------------------------------------------
set.seed(1)
ev <- q("SELECT nm, y, src, hash(nm || 'y') % 2 AS tt FROM L WHERE part = 2")
ev <- rbind(ev[y == 1], ev[y == 0][sample(.N, 600000)])
ev <- cbind(ev, org_features(ev$nm, venv))
# person-field rule positives that are a note ("RICHARD NA") or a person and
# an employer ("JENNIFER HOOVER BALL CORPORATION") are not organisations
ev <- ev[!(src == "rule" & (grepl(" N ?A$", nm) | g1s2))]
fml <- y ~ nb + nb_max + nb_min + lntok + two + frac_given + frac_cens +
  any_init + has_num + unk + g1 + sl + g1s2 + nb_max:two
tr <- ev[tt == 0]; te <- ev[tt == 1]
w <- ifelse(tr$y == 1, 0.5 / mean(tr$y == 1), 0.5 / mean(tr$y == 0))
m <- suppressWarnings(glm(fml, binomial, data = tr, weights = w / mean(w)))
print(round(coef(m), 3))

org_model <- list(
  vocab = as.data.frame(vocab),
  coef  = coef(m),
  info  = sprintf("Trained %s on Form 990 Part VII names 2009-2025: %d filer names, %d person-field names.",
                  format(Sys.Date()), sum(ev$src == "filer"), sum(ev$y == 0))
)

# held-out performance, at the shipped thresholds
score <- org_score_from_features
environment(score) <- list2env(list(org_model = org_model), parent = asNamespace("peopleparser"))
te[, p := score(te)]
te[, th := ifelse(ntok <= 2, .org_threshold_short, .org_threshold)]
auc <- function(p, y) { r <- rank(p); n1 <- sum(y); (sum(r[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * sum(1 - y)) }
cat("held-out AUC:", round(auc(te$p, te$y), 5), "\n")
print(te[, .(names = .N, flagged_as_org = round(mean(p >= th), 4)), by = .(src, words = pmin(ntok, 4))][order(src, words)])

# ---- institutions written without an organisation word ---------------------
# BNY MELLON, WELLS FARGO: ticked as institutional trustee at 5+ organisations,
# for at least 80% of their organisations and rows, with an organisation score
# of at least 0.01. The shares keep out trust officers who are named at many
# foundations (one is ticked at 27 organisations, but on 26% of her rows).
inst <- q(sprintf("SELECT %s nm,
    count(DISTINCT CASE WHEN F9_07_COMP_DTK_POS_INST_TRUST_X = 'X' THEN EIN2 END) ein_inst,
    count(DISTINCT EIN2) ein_all,
    sum(CASE WHEN F9_07_COMP_DTK_POS_INST_TRUST_X = 'X' THEN 1 ELSE 0 END) inst_rows, count(*) n
  FROM %s WHERE F9_07_COMP_DTK_NAME_PERS IS NOT NULL GROUP BY 1", cl("F9_07_COMP_DTK_NAME_PERS"), src))
inst <- inst[ein_inst >= 5 & ein_inst >= 0.8 * ein_all & inst_rows >= 0.8 * n]
inst[, p := score(org_features(nm, venv))]
institutional_names <- sort(inst[p >= 0.01, nm])
cat("institutional names:", paste(institutional_names, collapse = ", "), "\n")

# ---- run-together: recurring all-caps words that look splittable ----------
caps <- q(sprintf("SELECT t, count(DISTINCT nm) n_names FROM (
    SELECT nm, unnest(string_split(regexp_replace(nm, '[^A-Z ]', ' ', 'g'), ' ')) t FROM (
      SELECT DISTINCT F9_07_COMP_DTK_NAME_PERS nm FROM %s
      WHERE F9_07_COMP_DTK_NAME_PERS IS NOT NULL AND NOT regexp_matches(F9_07_COMP_DTK_NAME_PERS, '[a-z]')))
  WHERE length(t) >= 8 GROUP BY t HAVING count(DISTINCT nm) >= 3", src))
DBI::dbDisconnect(con, shutdown = TRUE)
cnt <- function(x) { d <- get_census_data(x); list(f = d$first_name_value, l = d$last_name_value) }
wc <- cnt(caps$t); caps <- caps[wc$f + wc$l == 0]
splittable <- unique(unlist(lapply(4:20, function(i) {
  z <- caps[nchar(t) >= i + 4]$t
  if (!length(z)) return(NULL)
  ok <- run_together_pair_ok(cnt(substr(z, 1, i)), cnt(substring(z, i + 1)),
                             share = 0.95, min_l = 2000, min_f = 20000)
  z[ok]
})))
run_together_block <- sort(splittable)
cat("run-together block list:", length(run_together_block), "words, e.g.",
    paste(head(run_together_block, 8), collapse = ", "), "\n")

usethis::use_data(org_model, run_together_block, institutional_names,
                  internal = TRUE, overwrite = TRUE, compress = "xz")
