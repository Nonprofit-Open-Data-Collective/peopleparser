#' U.S. Census first-name and surname frequencies.
#'
#' Names with how often each is a given name (by gender) and a surname in U.S.
#' Census Bureau name lists. Used to decide name order and to score gender.
#'
#' Built by `data-raw/census_names.R` from the Census Bureau's 2020 release,
#' "Frequently Occurring First Names and Last Names from the 2020 Census"
#' (revised 2026-04-09): 53,615 first names held by 91 or more people, with
#' counts by sex, and 156,621 surnames held by 92 or more people, each list
#' ending in an `ALL OTHER NAMES` row. The script downloads the files, records
#' their hashes in `data-raw/census-names-src.csv`, and rebuilds the table, so
#' it can be refreshed when the Bureau publishes new lists.
#'
#' Until November 2026 the package shipped a table from the 1990 first-name
#' lists (1,219 male and 4,275 female names, given as percentages and scaled
#' to counts) and the 2010 surname file. The 2020 lists cover ten times as many
#' given names and fit Form 990 names better (see NEWS.md). See
#' `vignette("gender-scoring")`.
#'
#' @format A [data.table::data.table] with 195,311 rows and 5 variables, keyed on
#'   `name`:
#' \describe{
#'   \item{name}{upper-case name (a factor)}
#'   \item{male_value}{people with this first name recorded male (2020)}
#'   \item{female_value}{people with this first name recorded female (2020)}
#'   \item{first_name_value}{count as a first name: `male_value + female_value`}
#'   \item{last_name_value}{people with this surname (2020)}
#' }
#' @source U.S. Census Bureau, Frequently Occurring First Names and Last Names
#'   from the 2020 Census:
#'   \url{https://www.census.gov/topics/population/genealogy/data/2020_names.html}
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
