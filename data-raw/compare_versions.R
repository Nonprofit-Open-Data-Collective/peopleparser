# Compare peopleparser 0.2.1 with the parses in synthid's Part VII panel
# (s3://nccs-efile/dev/synthid/partvii-v3_1/people/, parsed in October 2026
# with peopleparser cb01547, version 0.0.0.9000).
#
# 10,000 distinct names, drawn from random person rows of TY2017 and TY2024,
# are parsed three ways with the installed peopleparser:
#   default  - parse_names(name)
#   split    - parse_names(name, split_run_together = TRUE)
#   classify - name types from classify_names() on the same input
# Writes data-raw/compare-v0.0.9-v<version>.csv (every name whose parse changed
# or that is not classified as a person) and <dir>/compare-<version>.rds.
#
# Usage: Rscript data-raw/compare_versions.R <folder with people-<year>.parquet>

suppressMessages(library(data.table))
library(peopleparser)
dir <- commandArgs(TRUE)[1]
stopifnot(dir.exists(dir))
cat("peopleparser", format(packageVersion("peopleparser")), "\n")

con <- DBI::dbConnect(duckdb::duckdb())
files <- file.path(dir, c("people-2017.parquet", "people-2024.parquet"))
set.seed(20261124)
rows <- rbindlist(lapply(files, function(f) as.data.table(DBI::dbGetQuery(con, sprintf(
  "SELECT name, salutation, first_name, middle_name, last_name, suffix, gender
   FROM read_parquet('%s') USING SAMPLE 20000 ROWS (reservoir, 7)", f)))))
DBI::dbDisconnect(con, shutdown = TRUE)
old <- unique(rows[!is.na(name) & name != ""], by = "name")[sample(.N, 10000)]
cols <- c("salutation", "first_name", "middle_name", "last_name", "suffix", "gender")
for (v in cols) set(old, which(is.na(old[[v]])), v, "")

new   <- as.data.table(parse_names(old$name))
split <- as.data.table(parse_names(old$name, split_run_together = TRUE, classify = TRUE))
stopifnot(identical(new$name, old$name), identical(split$name, old$name))

cmp <- data.table(name = old$name)
for (v in cols) {
  cmp[, paste0(v, "_old") := old[[v]]]
  cmp[, paste0(v, "_new") := split[[v]]]
}
cmp[, name_type := split$name_type][, org_score := split$org_score]
cmp[, split_changed := Reduce(`|`, lapply(cols, function(v) new[[v]] != split[[v]]))]
chg <- function(v) cmp[[paste0(v, "_old")]] != cmp[[paste0(v, "_new")]]
for (v in cols) cmp[, paste0(v, "_chg") := chg(v)]
cmp[, any_chg := Reduce(`|`, lapply(cols, chg))]
cmp[, name_chg := first_name_chg | middle_name_chg | last_name_chg]
cmp[, order_flip := first_name_old != "" & first_name_old == last_name_new &
                    last_name_old == first_name_new]

cat("\nnames:", nrow(cmp), "\n")
cat("any field changed:", sum(cmp$any_chg), "\n")
print(cmp[, lapply(.SD, sum), .SDcols = paste0(cols, "_chg")])
cat("first/last swapped:", sum(cmp$order_flip), "\n")
cat("changed only by split_run_together:", sum(cmp$split_changed), "\n")
print(table(cmp$name_type))

ver <- format(packageVersion("peopleparser"))
fwrite(cmp[any_chg | name_type != "person"], sprintf("data-raw/compare-v0.0.9-v%s.csv", ver))
saveRDS(cmp, file.path(dir, sprintf("compare-%s.rds", ver)))
