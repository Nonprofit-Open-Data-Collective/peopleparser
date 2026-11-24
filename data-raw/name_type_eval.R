# Check classify_names() and split_run_together() on Form 990 Part VII names
# (run after data-raw/name_type_model.R). Prints the type shares on a random
# sample of the person-name field, random examples of each type for review,
# the institutional-trustee names, and the run-together splits.

suppressMessages({ library(data.table); devtools::load_all(quiet = TRUE) })
glob <- Sys.getenv("PART7_PARQUET",
                   "C:/Users/jlecy/Documents/NPMERGER/PANEL990/*/F9-P07-T01-COMPENSATION-*.parquet")
con <- DBI::dbConnect(duckdb::duckdb())
src <- sprintf("read_parquet('%s', union_by_name = true)", glob)
d <- as.data.table(DBI::dbGetQuery(con, sprintf(
  "SELECT F9_07_COMP_DTK_NAME_PERS AS raw, count(*) n,
          sum(CASE WHEN F9_07_COMP_DTK_POS_INST_TRUST_X = 'X' THEN 1 ELSE 0 END) inst
   FROM %s WHERE F9_07_COMP_DTK_NAME_PERS IS NOT NULL GROUP BY 1", src)))
DBI::dbDisconnect(con, shutdown = TRUE)
options(width = 160)
set.seed(2026)

# ---- name types on a random sample of distinct names -----------------------
s <- d[sample(.N, 300000)]
t0 <- Sys.time(); ct <- classify_names(s$raw)
cat("classify_names():", round(nrow(s) / as.numeric(difftime(Sys.time(), t0, units = "secs"))), "names a second\n")
s <- cbind(s, ct[, c("name_type", "org_score")])
print(s[, .(distinct = .N, rows = sum(n), share_rows = round(sum(n) / sum(s$n), 5)), by = name_type][order(-rows)])
for (k in setdiff(unique(s$name_type), "person")) {
  cat("\n", k, ":\n", sep = ""); print(s[name_type == k][sample(.N, min(.N, 40)), .(raw, org_score)])
}
cat("\nperson, highest org_score:\n"); print(s[name_type == "person"][order(-org_score)][1:25, .(raw, org_score)])

# ---- institutional trustees ------------------------------------------------
top <- d[inst > 0][order(-inst)][1:60]
top <- cbind(top, classify_names(top$raw)[, c("name_type", "org_score")])
cat("\nmost frequent names with the institutional trustee box ticked:\n"); print(top[, .(raw, inst, name_type, org_score)], nrows = 60)
ri <- d[inst > 0][sample(.N, 40)]
ri <- cbind(ri, classify_names(ri$raw)[, c("name_type", "org_score")])
cat("\nrandom names with the box ticked:\n"); print(ri[, .(raw, name_type, org_score)])

# ---- run-together names ------------------------------------------------------
cand <- d[grepl("[a-z][A-Z]", raw) | (!grepl("[a-z]", raw) & grepl("[A-Z]{8,}", raw))]
t0 <- Sys.time(); sp <- split_run_together(cand$raw)
cat("\nsplit_run_together():", nrow(cand), "candidates in", round(as.numeric(difftime(Sys.time(), t0, units = "secs"))), "s\n")
cand[, split := sp][, changed := split != raw][, rule := ifelse(grepl("[a-z]", raw), "capital inside a word", "all capitals")]
print(cand[changed == TRUE, .(distinct = .N, rows = sum(n)), by = rule])
for (r in unique(cand$rule)) {
  cat("\n", r, ", random splits:\n", sep = "")
  print(cand[changed == TRUE & rule == r][sample(.N, min(.N, 40)), .(raw, split, n)])
}
