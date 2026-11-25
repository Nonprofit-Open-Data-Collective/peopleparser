#' Classify Names as People, Organisations or Placeholders
#'
#' Officer lists hold more than people's names: banks and companies serving as
#' trustees, notes such as `SEE SCHEDULE O`, and couples. `classify_names()`
#' sorts each entry into one of five types, so that only people are matched
#' as people.
#'
#' * `"person"`: a person's name.
#' * `"organisation"`: an organisation (`PNC BANK NA`, `TEAMSTERS LOCAL 338`).
#' * `"person and organisation"`: a person's name followed by an
#'   organisation, usually an employer (`JAMES LUISI NORTH END COMMUNITY HC`).
#'   Parsing such a name usually still finds the person.
#' * `"several people"`: two or more people (`MICHAEL AND ASHLEY SMITH`).
#' * `"placeholder"`: a note instead of a name (`SEE SCHEDULE O`, `VACANT`,
#'   `NO COMPENSATED OFFICERS`), or nothing left after cleaning.
#'
#' Placeholders and several people are found by rules. Organisations are
#' found by a model: each word gets a score from how much more often it appears
#' in organisation names than in people's names, and a logistic regression
#' combines those scores with how many words the name has and how many are
#' given names or surnames in [census.names]. The model was trained on Form 990
#' Part VII names, 2009-2025: 982,000 filer names and 9.4 million names from
#' the person-name field (see `data-raw/name_type_model.R` and
#' `vignette("name-types")`).
#'
#' A name is an organisation when `org_score` reaches `threshold`. The default
#' thresholds are stricter for names of one or two words (0.99) than for longer
#' names (0.95), because short organisation names (`MUNROE EAGLES`) are hard
#' to tell from people's names and most two-word entries are people.
#'
#' @param x A character vector of raw names.
#' @param threshold `NULL` (the default) for the thresholds above, or one
#'   number between 0 and 1 for all names.
#'
#' @return A `data.frame` with one row per input and columns `name` (the
#'   input), `name_type` and `org_score` (the model's probability that the
#'   name is an organisation, for a population with equal shares of people and
#'   organisations).
#' @export
#' @examples
#' classify_names(c("JOHN A SMITH", "PNC BANK NA", "SEE SCHEDULE O",
#'                  "MICHAEL AND ASHLEY SMITH", "TEAMSTERS LOCAL NO 338",
#'                  "JAMES LUISI NORTH END COMMUNITY HC"))
classify_names <- function( x, threshold = NULL ) {
  if ( !is.null( threshold ) &&
       ( !is.numeric( threshold ) || length( threshold ) != 1 ||
         is.na( threshold ) || threshold < 0 || threshold > 1 ) )
    stop( "`threshold` must be NULL or a single number between 0 and 1.", call. = FALSE )
  x  <- as.character( x )
  cl <- clean_for_classify( x )
  # dates and tenure notes at the end say nothing about the name's type
  core <- sub( .note_tail_regex, "", cl )
  f  <- org_features( core, org_vocab_env() )
  score <- org_score_from_features( f )
  th <- if ( is.null( threshold ) ) ifelse( f$ntok <= 2, .org_threshold_short, .org_threshold ) else threshold

  type <- rep( "person", length( x ) )
  org  <- ( !is.na( score ) & score >= th ) | core %in% institutional_names
  type[ org ] <- "organisation"
  # a person's name, then an organisation (an employer or a note)
  first_word <- sub( " .*$", "", core )
  starts_person <- f$g1s2 & !first_word %in% .not_given_names
  dash <- grepl( "[A-Za-z] ?- ?[A-Za-z]", ifelse( is.na( x ), "", x ) )
  eponym <- grepl( .org_eponym_end, core )
  type[ org & starts_person & f$ntok >= 3 & ( !eponym | dash ) ] <- "person and organisation"
  # an organisation, then its representative (PRUDENTIAL INSURANCE - KYLE SMITH)
  rep_after <- !is.na( person_after_org_split( toupper( gsub( ".", " ", ifelse( is.na( x ), "", x ), fixed = TRUE ) ) ) )
  type[ rep_after ] <- "person and organisation"
  # couples: a given name on each side of AND / &
  several <- grepl( "(^| )(AND|&)( |$)", core ) &
    ( ( !org & f$ntok >= 3 ) | given_names_around_and( core ) )
  type[ several ] <- "several people"
  type[ is.na( x ) | cl == "" | grepl( .placeholder_regex, cl ) ] <- "placeholder"

  data.frame( name = x, name_type = type, org_score = round( score, 4 ),
              stringsAsFactors = FALSE )
}

# Default organisation thresholds (see data-raw/name_type_model.R).
.org_threshold       <- 0.95
.org_threshold_short <- 0.99

# Organisation names that begin with a person's name but are the organisation
# itself (KURT SUZUKI FAMILY FOUNDATION), not a person and an employer. INC,
# LLC and the like are left out: in officer lists "MARY SHURTS LHS INC" is
# far more often a person and an employer than an eponymous company.
.org_eponym_end <- paste0(
  "(^| )(FOUNDATION|FDN|FUND|TRUST|MEMORIAL|SCHOLARSHIP|ENDOWMENT|",
  "SCHOOL|ACADEMY|PROJECT|HOUSE|HOME|CENTER|INSTITUTE|CHURCH|LODGE|CLUB|",
  "DEPARTMENT|DEPT|INTERNATIONAL|ACTION|BOOSTERS?|GYMNASTICS)( |$)" )

# First words that are census given names but, at the start of an
# organisation's name, are not a person's (THE BANK OF NEW YORK MELLON).
.not_given_names <- c( "THE", "A", "AN", "OF", "FIRST", "SAINT", "ST", "MOUNT", "MT",
                       "NEW", "UNITED", "AMERICAN", "NORTH", "SOUTH", "EAST", "WEST",
                       "GREAT", "OUR", "HOLY", "CHRISTIAN", "ROYAL", "NATIONAL" )

# Dates and tenure notes at the end of an entry ("DRUPATTI PHULBAS AS OF 624").
.note_tail_regex <- paste0(
  " (AS OF|ASOF|SINCE|THRU|THROUGH|UNTIL|TIL|EFFECTIVE|EFF|PARTIAL YEAR|",
  "RESIGNED|DECEASED|FORMER|INTERIM|STARTED|BEGAN|ENDED|LEFT|TERM ENDED|TERMED)( .*)?$" )

# TRUE where a given name (or MR/MRS/DR) stands on each side of AND or &.
given_names_around_and <- function( cl ) {
  out <- logical( length( cl ) )
  hit <- which( grepl( "[A-Z] (AND|&) [A-Z]", cl ) )
  if ( !length( hit ) ) return( out )
  m <- regmatches( cl[ hit ], regexec( "([A-Z]+) (AND|&) ([A-Z]+)", cl[ hit ] ) )
  a <- vapply( m, `[`, "", 2 ); b <- vapply( m, `[`, "", 4 )
  # 2 = a given name or title, 1 = a word in neither census list, 0 = other
  kind <- function( w ) {
    cd <- get_census_data( w )
    g <- w %in% c( "MR", "MRS", "MS", "DR" ) |
      ( cd$first_name_value >= 100 & cd$first_name_value >= cd$last_name_value )
    u <- cd$first_name_value + cd$last_name_value == 0 & nchar( w ) >= 3
    ifelse( g, 2L, ifelse( u, 1L, 0L ) )
  }
  ka <- kind( a ); kb <- kind( b )
  out[ hit ] <- ka >= 1 & kb >= 1 & ka + kb >= 3
  out
}

# Entries that hold a note instead of a name (cleaned, upper case). SEE on its
# own word is a note only before a word such as SCHEDULE (SEE MOUA is a name).
.placeholder_regex <- paste0(
  "^(",
  "VACANT|VACANCY|NONE|N A|NA|TBD|TBA|UNKNOWN|VARIOUS|OPEN|OPEN POSITION|",
  "POSITION VACANT|NOT APPLICABLE|NO ONE|NOBODY|BLANK|X+|0+|SEE|",
  "SEE (SCHEDULE|SCHED|SCH|ATTACHED|ATTACHMENT|ATTACH|ATTCH|STATEMENT|STMT|LIST|",
  "LISTING|PART|PAGE|PG|BELOW|ABOVE|VARIOUS|ADDITIONAL|ADDL|ADDENDUM|",
  "SUPPLEMENTAL|FORM|NOTE|NOTES|EXHIBIT|ALSO|THE|O)( .*)?|",
  "ALL OTHERS?( .*)?|TO BE (APPOINTED|ELECTED|NAMED|DETERMINED)( .*)?|",
  "NOT (APPOINTED|ELECTED|FILLED)( .*)?|",
  "(THE )?(BOARD OF (DIRECTORS|TRUSTEES)|DIRECTORS|TRUSTEES|OFFICERS|",
  "BOARD MEMBERS?|BOARD|STAFF|VOLUNTEERS?)|",
  "[0-9]+ (DIRECTORS|TRUSTEES|OFFICERS|BOARD MEMBERS)|",
  "(NO|NON) (COMPENSATED|COMPENSATION|PAID|EMPLOYEES|OFFICERS|ONE)( .*)?|",
  "NONE OF THE( .*)?",
  ")$" )

# Clean names the way the model was trained: upper case, anything but letters,
# digits and & becomes a space, & is its own word.
clean_for_classify <- function( x ) {
  x <- toupper( ifelse( is.na( x ), "", x ) )
  x <- gsub( "[^A-Z0-9&]+", " ", x )
  x <- gsub( "&", " & ", x, fixed = TRUE )
  trimws( gsub( " +", " ", x ) )
}

# Word scores as a hashed environment, built once per session.
org_vocab_env <- function() {
  h <- .pp_data[[ "org.vocab" ]]
  if ( is.null( h ) ) {
    v <- org_model$vocab
    h <- list2env( as.list( stats::setNames( v$llr, v$token ) ), hash = TRUE,
                   size = nrow( v ) )
    .pp_data[[ "org.vocab" ]] <- h
  }
  h
}

#' Features for the Organisation Model
#'
#' One row of features per cleaned name. Used both to train the model
#' (`data-raw/name_type_model.R`) and by [classify_names()].
#'
#' @param cl Cleaned names from `clean_for_classify()`.
#' @param vocab An environment mapping words to word scores.
#' @return A `data.frame` of features.
#' @keywords internal
org_features <- function( cl, vocab ) {
  s   <- strsplit( gsub( "[0-9]+", "#", cl ), " ", fixed = TRUE )
  len <- lengths( s )
  id  <- rep( seq_along( cl ), len )
  t   <- unlist( s, use.names = FALSE )
  keep <- t != ""
  id <- id[ keep ]; t <- t[ keep ]
  n  <- length( cl )
  z <- numeric( n ); no <- logical( n )
  out <- data.frame( nb = z, nb_max = z, nb_min = z, ntok = integer( n ),
                     frac_given = z, frac_cens = z, any_init = no,
                     has_num = no, unk = z, g1 = z, sl = z, g1s2 = no )
  if ( length( t ) == 0 ) { out$lntok <- z; out$two <- no; return( out ) }

  llr <- unlist( mget( t, envir = vocab, ifnotfound = list( 0 ) ), use.names = FALSE )
  cd  <- get_census_data( t )
  f <- cd$first_name_value; l <- cd$last_name_value
  given <- f >= 100 & f >= l
  cens  <- f + l > 0
  init  <- nchar( t ) == 1 & t != "&"
  sh <- function( a, b, k = 20 ) ( a + k ) / ( a + b + 2 * k )

  ntok  <- tabulate( id, n )
  first <- !duplicated( id )
  last  <- !duplicated( id, fromLast = TRUE )
  second <- c( FALSE, first[ -length( first ) ] ) & !first
  has <- ntok > 0
  ix  <- which( has )

  out$ntok       <- ntok
  out$nb[ ix ]   <- as.numeric( rowsum( llr, id ) )
  out$nb_max[ ix ] <- as.numeric( tapply( llr, id, max ) )
  out$nb_min[ ix ] <- as.numeric( tapply( llr, id, min ) )
  out$frac_given[ ix ] <- as.numeric( rowsum( as.numeric( given ), id ) ) / ntok[ ix ]
  out$frac_cens[ ix ]  <- as.numeric( rowsum( as.numeric( cens ), id ) ) / ntok[ ix ]
  out$any_init[ ix ]   <- as.numeric( rowsum( as.numeric( init ), id ) ) > 0
  out$has_num[ ix ]    <- as.numeric( rowsum( as.numeric( t == "#" ), id ) ) > 0
  out$unk[ ix ] <- as.numeric( rowsum( as.numeric( llr == 0 & !cens ), id ) ) / ntok[ ix ]
  out$g1[ id[ first ] ] <- log1p( f[ first ] ) * sh( f[ first ], l[ first ] )
  out$sl[ id[ last ] ]  <- log1p( l[ last ] ) * sh( l[ last ], f[ last ] )
  g1ok <- f[ first ] >= 100 & f[ first ] >= l[ first ]
  s2ok <- rep( FALSE, n ); s2ok[ id[ second ] ] <- l[ second ] >= 100
  out$g1s2[ id[ first ] ] <- ntok[ id[ first ] ] >= 2 & g1ok & s2ok[ id[ first ] ]
  out$lntok <- log1p( out$ntok )
  out$two   <- out$ntok == 2
  out
}

# Probability that a name is an organisation, from its features.
org_score_from_features <- function( f ) {
  b <- org_model$coef
  eta <- b[[ "(Intercept)" ]] +
    b[[ "nb" ]] * f$nb + b[[ "nb_max" ]] * f$nb_max + b[[ "nb_min" ]] * f$nb_min +
    b[[ "lntok" ]] * f$lntok + b[[ "twoTRUE" ]] * f$two +
    b[[ "frac_given" ]] * f$frac_given + b[[ "frac_cens" ]] * f$frac_cens +
    b[[ "any_initTRUE" ]] * f$any_init + b[[ "has_numTRUE" ]] * f$has_num +
    b[[ "unk" ]] * f$unk + b[[ "g1" ]] * f$g1 + b[[ "sl" ]] * f$sl +
    b[[ "g1s2TRUE" ]] * f$g1s2 + b[[ "nb_max:twoTRUE" ]] * f$nb_max * f$two
  p <- stats::plogis( eta )
  p[ f$ntok == 0 ] <- NA_real_
  p
}
