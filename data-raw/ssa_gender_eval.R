# Does an age-weighted gender source beat census.names? (Answer, 2026-11-23: no.)
#
# Compares the gender implied by a given name under census.names (2020 Census)
# with Social Security Administration baby-name counts summed over birth-year
# windows, on names whose salutation states the gender (MR = male; MRS, MS,
# MISS = female). See data-raw/CENSUS-NAMES-2020.md for the result.
#
# Inputs:
#   * SSA national baby names, "Baby Names from Social Security Card
#     Applications - National Data" (yobYYYY.txt: name,sex,count),
#     https://catalog.data.gov/dataset/baby-names-from-social-security-card-applications-national-data
#     SSA refuses scripted downloads of names.zip (HTTP 403), so download it in
#     a browser and unzip it into data-raw/ssa-names-src/ (git-ignored).
#   * Part VII names: the npmerger project database (set NPMERGER_DB), or any
#     character vector of raw names in `raw_names`.
#
# Run from the package root:  source("data-raw/ssa_gender_eval.R")

suppressMessages({ library(data.table); devtools::load_all(quiet = TRUE) })

src <- "data-raw/ssa-names-src"
files <- list.files(src, pattern = "^yob[0-9]{4}\\.txt$", full.names = TRUE)
stopifnot("Unzip names.zip into data-raw/ssa-names-src first" = length(files) > 0)
ssa <- rbindlist(lapply(files, function(f)
  fread(f, header = FALSE, col.names = c("name", "sex", "n"))[, year := as.integer(substr(basename(f), 4, 7))]))
ssa[, name := toupper(name)]

ssa_window <- function(from, to) {
  w <- dcast(ssa[year %between% c(from, to), .(n = sum(n)), by = .(name, sex)],
             name ~ sex, value.var = "n", fill = 0)
  setnames(w, c("F", "M"), c("female", "male"))
  setkey(w, name)
  w
}
windows <- list(`SSA 1930-1995` = c(1930, 1995), `SSA 1940-1985` = c(1940, 1985),
                `SSA 1880-2025` = c(min(ssa$year), max(ssa$year)), `SSA 1990-2025` = c(1990, max(ssa$year)))

if (!exists("raw_names")) {
  db <- Sys.getenv("NPMERGER_DB", "C:/Users/jlecy/Documents/NPMERGER/npmerger.duckdb")
  con <- DBI::dbConnect(duckdb::duckdb(dbdir = db, read_only = TRUE, shared_home = FALSE))
  raw_names <- DBI::dbGetQuery(con, "SELECT DISTINCT PERSON_NAME FROM part7 WHERE PERSON_NAME IS NOT NULL")[[1]]
  DBI::dbDisconnect(con, shutdown = TRUE)
}
tk <- strsplit(sanitize_input(raw_names), " ", fixed = TRUE)
lead <- vapply(tk, `[`, "", 1)
truth <- fifelse(lead == "MR", "M", fifelse(lead %in% c("MRS", "MS", "MISS"), "F", NA_character_))
keep <- !is.na(truth) & lengths(tk) >= 3 & !vapply(tk, function(t) "AND" %in% t, FALSE)
given <- vapply(tk[keep], function(t) { g <- t[-1][nchar(t[-1]) >= 2]; if (length(g)) g[1] else NA_character_ }, "")
ev <- data.table(given = given, truth = truth[keep])[!is.na(given)]

score <- function(m, f) {
  tot <- m + f
  data.table(g = fifelse(tot == 0, "U", fifelse(m >= f, "M", "F")),
             conf = fifelse(tot == 0, NA_real_, 100 * pmax(m, f) / tot))
}
cd <- get_census_data(ev$given)
res <- list(census = score(cd$male_value, cd$female_value))
for (n in names(windows)) {
  w <- ssa_window(windows[[n]][1], windows[[n]][2])[J(ev$given)]
  res[[n]] <- score(fcoalesce(as.numeric(w$male), 0), fcoalesce(as.numeric(w$female), 0))
}
cat(sprintf("names with a gendered salutation: %d (M %d, F %d)\n",
            nrow(ev), sum(ev$truth == "M"), sum(ev$truth == "F")))
print(rbindlist(lapply(names(res), function(n) { r <- res[[n]]
  data.table(source = n, correct = round(100 * mean(r$g == ev$truth), 2),
             wrong = sum(r$g != "U" & r$g != ev$truth), unknown = sum(r$g == "U"),
             correct_when_known = round(100 * mean((r$g == ev$truth)[r$g != "U"]), 2))
})))
