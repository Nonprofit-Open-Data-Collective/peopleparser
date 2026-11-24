# Trailing credentials and organisation codes that the title lists do not know
# (0.2.3), stored in R/sysdata.rda as `trailing_credentials`.
#
# Background: 0.2.2 stopped joining a middle name to the surname unless it is a
# strong surname. That fixed JOHN LEE SMITH, but where the last word was an
# unknown credential (ANDREA M GORDON NMF, ANTHONY F CHONG MD FAAFP) the
# credential became the whole surname, where 0.2.1 had kept GORDON-NMF.
#
# A word is listed when, as the last word of Part VII person names of 3+
# words, it
#   * is not a census name and not already a known title, suffix or status word;
#   * ends names of at least 3 different people (distinct preceding words); and
#   * follows a census surname or a known credential in at least 70% of them.
# A real surname missing from the census follows a given name, not a surname,
# and rarely recurs after many different words.
#
# Run from the package root; PART7_PARQUET as in data-raw/name_type_model.R.
# Rewrites R/sysdata.rda, keeping the objects already there.

suppressMessages({ library(data.table); devtools::load_all(quiet = TRUE) })
glob <- Sys.getenv("PART7_PARQUET",
                   "C:/Users/jlecy/Documents/NPMERGER/PANEL990/*/F9-P07-T01-COMPENSATION-*.parquet")
con <- DBI::dbConnect(duckdb::duckdb())
d <- as.data.table(DBI::dbGetQuery(con, sprintf("
  WITH t AS (SELECT DISTINCT trim(regexp_replace(regexp_replace(upper(F9_07_COMP_DTK_NAME_PERS),
                    '[^A-Z -]', ' ', 'g'), ' +', ' ', 'g')) u
             FROM read_parquet('%s', union_by_name = true)
             WHERE F9_07_COMP_DTK_NAME_PERS IS NOT NULL),
       w AS (SELECT string_split(u, ' ') a FROM t WHERE len(string_split(u, ' ')) >= 3)
  SELECT a[len(a)] fin, a[len(a) - 1] prev, count(*) n FROM w GROUP BY ALL", glob)))
DBI::dbDisconnect(con, shutdown = TRUE)

known <- c(prx, sfx, .ambiguous_suffix_credentials, .trailing_only_titles,
           .status_words, .trailing_status_words)
d <- d[!fin %in% known & nchar(gsub("-", "", fin)) >= 2]
uf <- unique(d$fin); cf <- get_census_data(uf)
d <- d[data.table(fin = uf, tot = cf$first_name_value + cf$last_name_value)[tot == 0], on = "fin"]
up <- unique(d$prev); cp <- get_census_data(up)
d <- d[data.table(prev = up, pf = cp$first_name_value, pl = cp$last_name_value), on = "prev"]
d[, ok_prev := prev %in% known | (pl > pf & pl > 0)]
s <- d[, .(names = sum(n), n_prev = uniqueN(prev), share = sum(n[ok_prev]) / sum(n)), by = fin]
# ...and it looks like a code: at most one vowel, four letters or fewer, a
# fellowship (FA...) or a hyphenated note (JAN-APR, NEA-BC). Without this
# filter, recurring surnames missing from the census got in (SUHLER, KORINKE,
# ARSUAGA, MEIROWITZ), mostly second surnames of Hispanic names.
s[, code_like := nchar(gsub("[^AEIOUY]", "", fin)) <= 1 | nchar(fin) <= 4 |
                 grepl("^FA", fin) | grepl("-", fin)]
# surnames and words found on a read of the list (EYCK and ONGE follow TEN and ST)
not_credentials <- c("HARST", "MUIZ", "EYCK", "ONGE", "OLIO", "HAVE", "SURE", "EYES", "DOG", "AUTO")
trailing_credentials <- sort(setdiff(s[n_prev >= 3 & share >= 0.7 & code_like]$fin, not_credentials))
cat("trailing credentials:", length(trailing_credentials), "words, e.g.",
    paste(head(s[fin %in% trailing_credentials][order(-names)]$fin, 20), collapse = ", "), "\n")

fwrite(s[fin %in% trailing_credentials][order(-names), .(word = fin, names, preceding_words = n_prev,
                                                       after_surname_or_credential = round(share, 3))],
       "data-raw/trailing-credentials.csv")

e <- new.env(); load("R/sysdata.rda", envir = e)
org_model <- e$org_model; run_together_block <- e$run_together_block
institutional_names <- e$institutional_names
usethis::use_data(org_model, run_together_block, institutional_names, trailing_credentials,
                  internal = TRUE, overwrite = TRUE, compress = "xz")
