# Rebuild census.names from U.S. Census Bureau name files.
#
# Run from the package root:
#   source("data-raw/census_names.R")                 # download, build, compare
#   Sys.setenv(CENSUS_NAMES_SAVE = "TRUE"); source("data-raw/census_names.R")
#                                                      # ... and overwrite data/
#
# Sources (Census Bureau genealogy data, census.gov/topics/population/genealogy):
#
#   2020 release ("Frequently Occurring First Names and Last Names from the 2020
#   Census", revised 2026-04-09), the default:
#     Names2020_FirstNames_Sex.xlsx          FIRST NAME, RANK, FREQUENCY (COUNT),
#                                            PROPORTION PER 100,000, CUMULATIVE
#                                            PROPORTION, MALE, FEMALE
#                                            (53,615 names with 91+ people)
#     Names2020_LastNames_RaceHispanic.xlsx  LAST NAME, RANK, FREQUENCY (COUNT),
#                                            ..., counts by race and Hispanic origin
#                                            (156,621 names with 92+ people)
#   Both end in an ALL OTHER NAMES row.
#
#   The table bundled before this script existed used the 1990 first-name lists
#   (dist.male.first / dist.female.first: percentages, scaled to counts by about
#   1,432,240 for men and 1,518,500 for women) and the 2010 surname file
#   (2010surnames/names.zip). check_1990_first_names() below shows the 1990 side
#   can be reproduced. The 2010 zip is refused to scripted downloads by the
#   Census server (an HTML "Request Rejected" page), so that side cannot be
#   re-downloaded here; the 2020 surnames replace it.
#
# Output: census.names, the same five columns as before, keyed on `name`:
#   name              upper-case name (factor)
#   male_value        people with this first name recorded male
#   female_value      people with this first name recorded female
#   first_name_value  male_value + female_value
#   last_name_value   people with this surname
# Downloaded files go to data-raw/census-names-src/ (git-ignored); their sizes
# and SHA-256 hashes are written to data-raw/census-names-src.csv (committed),
# so a later download can be checked against the one used.

library(data.table)

base_url <- "https://www2.census.gov/topics/genealogy"
src_dir  <- "data-raw/census-names-src"
files_2020 <- c(first = "2020surnames/Names2020_FirstNames_Sex.xlsx",
                last  = "2020surnames/Names2020_LastNames_RaceHispanic.xlsx")
files_1990 <- c(male = "1990surnames/dist.male.first",
                female = "1990surnames/dist.female.first")

download_census <- function(paths, dir = src_dir, refresh = FALSE) {
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  out <- vapply(paths, function(p) {
    f <- file.path(dir, basename(p))
    if (refresh || !file.exists(f)) {
      utils::download.file(file.path(base_url, p), f, mode = "wb", quiet = TRUE)
    }
    # the Census server answers some scripted requests with an HTML page
    if (grepl("^<", readChar(f, 1L, useBytes = TRUE)) && !grepl("first$", f)) {
      stop("Download of ", p, " returned an HTML page, not the data file: ",
           "fetch it in a browser and put it in ", dir, call. = FALSE)
    }
    f
  }, "")
  manifest <- data.table(file = basename(out), url = file.path(base_url, paths),
                         bytes = file.size(out),
                         sha256 = vapply(out, function(f) digest::digest(file = f, algo = "sha256"), ""),
                         downloaded = format(file.mtime(out), "%Y-%m-%d"))
  manifest
}

read_2020 <- function(f, name_col) {
  x <- as.data.table(readxl::read_excel(f, skip = 3, col_names = FALSE, .name_repair = "minimal"))
  hdr <- as.character(readxl::read_excel(f, skip = 2, n_max = 1, col_names = FALSE,
                                         .name_repair = "minimal")[1, ])
  setnames(x, make.unique(hdr))
  stopifnot(names(x)[1] == name_col, "FREQUENCY (COUNT)" %in% names(x))
  x[!is.na(get(name_col))]
}

build_census_names <- function(first_file, last_file) {
  fn <- read_2020(first_file, "FIRST NAME")
  ln <- read_2020(last_file, "LAST NAME")
  stopifnot(all(c("MALE", "FEMALE") %in% names(fn)),
            all(fn$MALE + fn$FEMALE == fn$`FREQUENCY (COUNT)`))
  first <- fn[, .(name = toupper(`FIRST NAME`), male_value = as.numeric(MALE),
                  female_value = as.numeric(FEMALE))]
  last  <- ln[, .(name = toupper(`LAST NAME`), last_name_value = as.numeric(`FREQUENCY (COUNT)`))]
  cn <- merge(first, last, by = "name", all = TRUE)
  for (v in c("male_value", "female_value", "last_name_value")) set(cn, which(is.na(cn[[v]])), v, 0)
  cn[, first_name_value := male_value + female_value]
  setcolorder(cn, c("name", "male_value", "female_value", "first_name_value", "last_name_value"))
  cn[, name := factor(name)]
  setkey(cn, name)
  cn[]
}

# The bundled 1990 side, rebuilt from the 1990 percentage files.
check_1990_first_names <- function(male_file, female_file, bundled) {
  rd <- function(f) fread(f, header = FALSE, col.names = c("name", "pct", "cum", "rank"))
  m <- rd(male_file); f <- rd(female_file)
  b <- bundled[, .(name = as.character(name), male_value, female_value)]
  km <- median(b[m, on = "name"][, male_value / pct], na.rm = TRUE)
  kf <- median(b[f, on = "name"][, female_value / pct], na.rm = TRUE)
  rm <- b[m, on = "name"][, abs(male_value - pct * km) / male_value]
  rf <- b[f, on = "name"][, abs(female_value - pct * kf) / female_value]
  data.table(side = c("male", "female"), names_1990 = c(nrow(m), nrow(f)),
             in_bundle = c(sum(m$name %in% b$name[b$male_value > 0]), sum(f$name %in% b$name[b$female_value > 0])),
             scale = round(c(km, kf)), max_rel_diff = signif(c(max(rm), max(rf)), 3))
}

compare_census_names <- function(new, old) {
  o <- old[, .(name = as.character(name), of = first_name_value, ol = last_name_value,
               om = male_value, ofe = female_value)]
  n <- new[, .(name = as.character(name), nf = first_name_value, nl = last_name_value,
               nm = male_value, nfe = female_value)]
  j <- merge(o, n, by = "name", all = TRUE)
  for (v in names(j)[-1]) set(j, which(is.na(j[[v]])), v, 0)
  j[, `:=`(old_role = fifelse(of > ol, "first", fifelse(ol > 0, "last", "none")),
           new_role = fifelse(nf > nl, "first", fifelse(nl > 0, "last", "none")))]
  g <- function(m, f) fifelse(m + f == 0, NA_character_, fifelse(m >= f, "M", "F"))
  j[, `:=`(old_gender = g(om, ofe), new_gender = g(nm, nfe))]
  list(
    sizes = data.table(table = c("bundled", "rebuilt"), rows = c(nrow(old), nrow(new)),
                       first_names = c(sum(old$first_name_value > 0), sum(new$first_name_value > 0)),
                       surnames = c(sum(old$last_name_value > 0), sum(new$last_name_value > 0))),
    role_changes = j[old_role != new_role & old_role != "none" & new_role != "none",
                     .N, by = .(old_role, new_role)],
    gender_flips = j[!is.na(old_gender) & !is.na(new_gender) & old_gender != new_gender,
                     .(name, old_m = om, old_f = ofe, new_m = nm, new_f = nfe)][order(-(new_m + new_f))],
    joined = j)
}

# ---- run -----------------------------------------------------------------------
manifest <- download_census(c(files_2020, files_1990))
fwrite(manifest, "data-raw/census-names-src.csv")
print(manifest[, .(file, bytes, downloaded)])

e <- new.env(); utils::data("census.names", package = "peopleparser", envir = e)
bundled <- as.data.table(e$census.names)

cat("\n1990 first-name side of the bundled table, rebuilt from the 1990 files:\n")
print(check_1990_first_names(file.path(src_dir, "dist.male.first"),
                             file.path(src_dir, "dist.female.first"), bundled))

census.names <- build_census_names(file.path(src_dir, basename(files_2020[["first"]])),
                                   file.path(src_dir, basename(files_2020[["last"]])))
cmp <- compare_census_names(census.names, bundled)
cat("\nBundled vs rebuilt from 2020:\n"); print(cmp$sizes)
cat("\nNames whose dominant role (first vs surname) changes:\n"); print(cmp$role_changes)
cat("\nGiven names whose majority gender flips (most common first):\n")
print(head(cmp$gender_flips, 20))

if (identical(Sys.getenv("CENSUS_NAMES_SAVE"), "TRUE")) {
  old <- "data/census.names.RData"
  usethis::use_data(census.names, overwrite = TRUE, compress = "xz")
  if (file.exists(old)) file.remove(old)   # use_data writes census.names.rda
  message("Saved data/census.names.rda. Update R/data.R, NEWS.md and rerun the tests.")
} else {
  message("Not saved. Set CENSUS_NAMES_SAVE=TRUE to overwrite the bundled table.")
}
