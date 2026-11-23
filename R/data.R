#' U.S. Census first-name and surname frequencies.
#'
#' Names with how often each is a given name (by gender) and a surname in U.S.
#' Census Bureau name lists. Used to decide name order and to score gender.
#'
#' A frozen copy bundled with the package: it is not downloaded or rebuilt,
#' and no build script survives. Its contents date from the package's first
#' commit (2020-08-01), adapted from Michael Flanigan's Name-Parser. Judging by
#' its contents, the given names are the 1990 Census first-name lists (1,219
#' male and 4,275 female names, published as percentages and scaled here to
#' counts) and the surnames are the 2010 Census surname file (162,253 names
#' held by 100 or more people, plus an `ALL OTHER NAMES` row). See
#' `vignette("gender-scoring")`.
#'
#' @format A [data.table::data.table] with 164,850 rows and 5 variables, keyed on
#'   `name`:
#' \describe{
#'   \item{name}{upper-case name (a factor)}
#'   \item{male_value}{count of men with this first name (1990 lists)}
#'   \item{female_value}{count of women with this first name (1990 lists)}
#'   \item{first_name_value}{count as a first name: `male_value + female_value`}
#'   \item{last_name_value}{count as a surname (2010 surname file)}
#' }
#' @source U.S. Census Bureau: Frequently Occurring Surnames from the 2010
#'   Census, and Frequently Occurring Names from the 1990 Census.
#'   \url{https://www.census.gov/topics/population/genealogy/data.html}
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
