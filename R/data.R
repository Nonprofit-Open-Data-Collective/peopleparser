#' Frequency of name occurrence on US birth certificates.
#'
#' A dataset containing names cross-tabbed by whether they
#' are listed as first or last names in the US Census.
#'
#' @format A [data.table::data.table] with 164,850 rows and 5 variables, keyed on
#'   `name`:
#' \describe{
#'   \item{name}{name as listed on US birth certificates}
#'   \item{male_value}{count of times the name is listed for a male}
#'   \item{female_value}{count of times the name is listed for a female}
#'   \item{first_name_value}{count of times the name appears in the first-name position}
#'   \item{last_name_value}{count of times the name appears in the last-name position}
#' }
#' @source \url{https://www.census.gov/en.html}
"census.names"


#' First-name variants: nicknames, spellings, cognates and compounds.
#'
#' Pairs of first names that are two forms of one given name, observed as the
#' same person (one EMP_ID) across their own organization's Form 990 Part VII
#' filings, 2010-2024 (15.0 million people). Built in synthid
#' (`dev/name-variants/`; see the synthid vignette "First-name variants - how
#' the table was built") and copied here by `data-raw/first_name_pairs.R`,
#' with some columns dropped and a `formal` column added. Used by
#' [nickname_lookup()].
#'
#' The 1,007 rows with `lexicon = TRUE` are the pairs seen in 25+ people,
#' reviewed by hand. The other 23,965 rows are sound-alike and misspelling pairs
#' from rarer pairs, not reviewed.
#'
#' @format A [data.table::data.table] with 24,972 rows and 13 variables, keyed
#'   on `name_short`:
#' \describe{
#'   \item{name_short, name_long}{the pair, shorter form first}
#'   \item{type}{`nickname`, `spelling`, `cognate`, `compound` (lexicon), or
#'     `sound_alike`, `misspelling` (not lexicon)}
#'   \item{lexicon}{`TRUE` for the reviewed pairs}
#'   \item{n_emp_ids}{number of people carrying the pair}
#'   \item{freq_short, freq_long}{national Part VII rows with each first name}
#'   \item{f_short, f_long}{share of those rows recorded female}
#'   \item{cofiling_rate}{how often the two forms appear as separate people
#'     with one surname on one return, per person carrying the pair; high
#'     values are weaker evidence (JOHN/JOHNNY: father and son)}
#'   \item{flags}{`""`, `"gender"`, `"cofiling"` or `"cofiling gender"`}
#'   \item{chain_id}{variant chain: connected component of the lexicon pairs}
#'   \item{formal}{nickname pairs only: `"short"` or `"long"`, the side that
#'     is the formal name; `NA` for other types}
#' }
#' @source synthid `dev/name-variants/first-name-variants.csv`, commit
#'   07c320f (2026-11-23).
"first_name_pairs"
