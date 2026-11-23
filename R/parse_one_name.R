#  parse_one_name.R
#  +-- sanitize_input       # text cleaning
#  +-- extract_component    # prefix/suffix/temp removal
#  +-- assign_names         # core parsing logic
#  +-- resolve_middle_name  # handle hyphenation and surname inference
#  +-- parse_name           # main wrapper



#' Sanitize Raw Name Input
#'
#' Removes punctuation, converts to uppercase, and applies custom cleanup.
#'
#' @param x A raw name string.
#'
#' @return Cleaned character string.
#' @export
sanitize_input <- function( x ) {
  x <- gsub( '.', ' ', x, fixed = TRUE )
  x <- toupper( x )
  x <- de_clutter( x )
  prep_name( x )
}



#' Extract Specific Name Components
#'
#' Removes one element (e.g., salutation, suffix, or status flag) from a name vector.
#'
#' @param name_vec A character vector of name parts.
#' @param elements A character vector of items to remove.
#'
#' @return A list with `name` (the removed item or "") and `remainder` (the updated vector).
#' @export
extract_component <- function( name_vec, elements ) {
  removal <- remove_elements( name_vec, elements )
  list( name = removal$removed_names[1], remainder = removal$names )
}



#' Parse Core Name Components and Gender
#'
#' Uses vector length and surname heuristics to extract first, middle, and last names, and infer gender.
#'
#' @param x A character vector of name parts (after cleaning).
#' @param suffix.name Optional suffix name for fallback gender guessing.
#'
#' @return A list with `first`, `middle`, `last`, and `gender` (vector of code and confidence).
#' @export
assign_names <- function( x, suffix.name ) {
  l <- nchar( x )
  i <- length( x )
  s <- l == 1                            # which tokens are initials

  # gender from the given-name tokens; with no census evidence, fall back to
  # "U" (or "M" when a generational suffix is present) at 50.0 -- the same
  # fallback as the 2-token and 4+-token branches. determine_gender() returns
  # a bare "U" in that case, which used to leave gender_confidence NA.
  get_gender <- function(xx) {
    if ( length(xx) == 0 ) return( c("U", "0.0") )
    g <- determine_gender( get_census_data( xx ) )
    if ( g[1] == "U" ) g <- c( ifelse( suffix.name != "", "M", "U" ), "50.0" )
    g
  }

  if ( i == 3 && sum( s ) == 1 ) {
    is.surname <- check_if_surname( x )
    if ( l[2] == 1 && is.surname[1] && !is.surname[3] ) x <- x[c(2,3,1)]
    if ( l[3] == 1 ) x <- x[c(2,3,1)]
    first <- x[1]; middle <- x[2]; last <- x[3]
    gender <- get_gender( x[-3] )

  } else if ( i == 3 && sum( s ) == 2 ) {
    last <- x[ which( l > 1 ) ]; first <- x[ - which( l > 1 ) ][1]; middle <- x[ - which( l > 1 ) ][2]
    gender <- get_gender( c( first, middle ) )

  } else if ( i == 3 ) {
    is.surname <- check_if_surname( x )
    if ( is.surname[1] && is.surname[2] && !is.surname[3] ) x <- x[c(3,1,2)]
    if ( is.surname[1] && !is.surname[2] ) x <- x[c(2,3,1)]
    first <- x[1]; middle <- x[2]; last <- x[3]
    gender <- get_gender( x[-3] )

  } else if ( i == 2 ) {
    data <- get_census_data( x )
    pos <- two_token_surname( x, data )
    last <- x[pos]; first <- x[-pos]; middle <- ""
    gender <- determine_gender( data[-pos, ] )
    if ( gender[1] == "U" ) gender <- c( ifelse( suffix.name != "", "M", "U" ), "50.0" )

  } else if ( i == 1 ) {
    first <- ""; middle <- ""; last <- x[1]
    gender <- c( ifelse( suffix.name != "", "M", "U" ), "50.0" )

  } else if ( i == 0 ) {
    first <- ""; middle <- ""; last <- ""; gender <- c("U", "0.0")

  } else {
    data <- get_census_data( x )
    pos <- determine_surname( data )
    is.surname <- check_if_surname( x )
    if ( is.surname[1] && is.surname[2] && !is.surname[3] ) {
      last <- paste( x[1:2], collapse = "-" ); first <- x[3]; middle <- paste( x[-(1:3)], collapse = " " )
    } else {
      last <- x[pos]; rest <- x[-pos]; first <- rest[1]
      middle <- if ( length( rest ) > 1 ) paste( rest[-1], collapse = " " ) else ""
    }
    gender <- determine_gender( data[-pos, ] )
    if ( gender[1] == "U" ) gender <- c( ifelse( suffix.name != "", "M", "U" ), "50.0" )
  }

  list( first = first, middle = middle, last = last, gender = gender )
}


#' Surname Position in a Two-Token Name
#'
#' [determine_surname()] with two extra rules for a two-token name in which
#' exactly one token is absent from the census (there, the unlisted token
#' otherwise ranks as the likely surname):
#' * an unlisted first token of one or two letters is initials, not the
#'   surname (`HM CHERRY`, `DC ALLEN`, `J MARKEL`);
#' * a listed token whose surname share is at least 0.85 is the surname
#'   (`NICKHATH SHERIFF`, `REETIKA KUMAR`, `SANRDA COHEN`). Names that are
#'   also common given names stay below that (`IRWIN` 0.84, `LEE` 0.81,
#'   `HOWARD` 0.65), so `HOWARD SITRON` keeps `SITRON` as the surname.
#'
#' @param x A length-2 character vector of name tokens.
#' @param data Census rows for `x`, as returned by [get_census_data()].
#' @return The position (1 or 2) of the surname.
#' @keywords internal
two_token_surname <- function( x, data ) {
  pos <- determine_surname( data )
  f <- data$first_name_value; l <- data$last_name_value
  known <- f + l > 0
  if ( sum( known ) != 1 ) return( pos )
  k <- which( known ); u <- which( !known )
  # leading initials (HM CHERRY); a trailing one is a middle initial left after
  # a stripped surname or title (THOMAS H [LEED]) and keeps the old ranking
  if ( nchar( x[u] ) <= 2 ) return( if ( u == 1L ) k else pos )
  p_last <- ( 1 + l[k] ) / ( 1 + f[k] + l[k] )
  if ( p_last >= .two_token_surname_min ) return( k )
  pos
}

# Surname share at or above which a listed token beats an unlisted one as the
# surname of a two-token name (two_token_surname()).
.two_token_surname_min <- 0.85

#' Resolve Middle Names as Potential Surnames
#'
#' Checks if a middle name segment is actually part of the last name.
#'
#' @param middle Character string of middle name.
#' @param last Character string of last name.
#' @param tokens Optional character vector of the name tokens in their original
#'   order. When the surname parts sit next to each other there, they are joined
#'   in that order (`MARY ANN SMITH JONES` gives `SMITH-JONES`, not
#'   `JONES-SMITH`). Otherwise they are joined middle first, then last.
#'
#' @return A character vector of length 2: updated middle name and last name.
#' @export
resolve_middle_name <- function( middle, last, tokens = NULL ) {
  mn <- strsplit( middle, ' ' )[[1]]

  join_surname <- function( parts ) {
    if ( !is.null( tokens ) ) {
      p <- match( parts, tokens )
      if ( !anyNA( p ) && !anyDuplicated( p ) &&
           all( diff( sort( p ) ) == 1 ) ) parts <- parts[ order( p ) ]
    }
    paste( parts, collapse = "-" )
  }

  if ( length( mn ) == 1 && check_if_surname( mn ) ) return( c("", join_surname( c( mn, last ) )) )

  if ( length( mn ) > 1 ) {
    if ( nchar( mn[1] ) == 1 && nchar( mn[2] ) > 1 )
      return( c( mn[1], join_surname( c( mn[-1], last ) ) ) )

    surname_flags <- check_if_surname( mn )
    if ( any( surname_flags ) ) {
      start <- min( which( surname_flags ) )
      mid <- if ( start > 1 ) paste( mn[1:(start - 1)], collapse = " " ) else ""
      return( c( mid, join_surname( c( mn[start:length(mn)], last ) ) ) )
    }
  }

  c( middle, last )
}


# --- Tokenizer repairs for glued tokens ------------------------------------
# Addresses Defects 2 & 3 in data-raw/PARSE-FAIL-NOTES.md: a title or a stray
# initial that lost its separating space and fused onto the next token. Every
# split is gated on census evidence so real names are never broken apart.

# Personal-title honorifics eligible to be un-glued from a following given name.
.honorific_glue_prefixes <- c("MRS", "MISS", "MR", "MS", "DR")
.initial_consonants <- strsplit("BCDFGHJKLMNPQRSTVWXZ", "")[[1]]
# A remainder must clear these census counts to count as a real name. Given
# names in the census run to the millions; the flagged surnames (e.g. WOOLFOLK,
# ~3.3k) sit lower, so the surname bar is deliberately modest.
.glue_given_min   <- 10000
.glue_surname_min <- 2000

# TRUE when a token is itself a known census name (given or surname); such a
# token is a real name and must never be split.
.is_census_name <- function( tok ) {
  cd <- get_census_data( tok )
  cd$first_name_value[1] > 0 || cd$last_name_value[1] > 0
}

#' Split a Title Glued to a Given Name
#'
#' Defect 2: `MRWILLIAM` -> `c("MR", "WILLIAM")`. Only splits when the leading
#' run is a known personal title, the remainder is a strong census given name,
#' and the whole token is not itself a known census name (guards `FREDDIE`,
#' `FRANK`, `DREW`).
#'
#' @param tok A single uppercased name token.
#' @return The token unchanged, or a length-2 vector `c(title, given)`.
#' @keywords internal
split_glued_honorific <- function( tok ) {
  if ( nchar( tok ) < 4 || .is_census_name( tok ) ) return( tok )
  for ( p in .honorific_glue_prefixes ) {
    if ( startsWith( tok, p ) ) {
      rem <- substring( tok, nchar( p ) + 1 )
      if ( nchar( rem ) < 3 ) next
      if ( get_census_data( rem )$first_name_value[1] >= .glue_given_min )
        return( c( p, rem ) )
    }
  }
  tok
}

#' Split a Stray Initial Glued to a Surname
#'
#' Defect 3: `CWOOLFOLK` -> `c("C", "WOOLFOLK")`. Only splits when the token is
#' a single leading consonant followed by a run that is itself a valid census
#' surname, and the whole token is not a known census name (guards `BLAKE`,
#' `SHAW`, `WOOD`).
#'
#' @param tok A single uppercased name token.
#' @return The token unchanged, or a length-2 vector `c(initial, surname)`.
#' @keywords internal
split_glued_initial <- function( tok ) {
  if ( nchar( tok ) < 4 ) return( tok )
  if ( !substring( tok, 1, 1 ) %in% .initial_consonants ) return( tok )
  if ( .is_census_name( tok ) ) return( tok )
  rem <- substring( tok, 2 )
  if ( nchar( rem ) < 3 ) return( tok )
  if ( get_census_data( rem )$last_name_value[1] >= .glue_surname_min )
    return( c( substring( tok, 1, 1 ), rem ) )
  tok
}

#' Split Two Credentials Fused Into One Token
#'
#' Suffix gaps (data-raw/SUFFIX-GAPS-PART7.md): `JRMD` -> `c("JR", "MD")`,
#' `MDMPH` -> `c("MD", "MPH")`. Splits only when both parts are known suffixes
#' or credentials of two or more letters, and the whole token is not itself a
#' census name. [deglue_tokens()] applies it only from the third token on, so
#' a given name or initials at the start are never split.
#'
#' @param tok A single uppercased name token.
#' @param parts Known suffixes and credentials. Defaults to `sfx` and the
#'   single-word entries of `prx`.
#' @return The token unchanged, or a length-2 vector of the two credentials.
#' @keywords internal
split_glued_credentials <- function( tok, parts = c( sfx, prx[ !grepl( " ", prx ) ] ) ) {
  n <- nchar( tok )
  if ( n < 4 || tok %in% c( parts, .status_words, .trailing_status_words,
                            .trailing_only_titles, .leading_only_titles ) ||
       .is_census_name( tok ) ) return( tok )
  for ( i in 2:( n - 2 ) ) {
    a <- substring( tok, 1, i ); b <- substring( tok, i + 1 )
    if ( a %in% .glue_credential_syllables ) next
    if ( a %in% parts && b %in% parts ) return( c( a, b ) )
  }
  tok
}

# Two-letter prx entries that are also common name syllables; they may not
# start a fused-credential split (COVERY is a surname, CODO a given name).
.glue_credential_syllables <- c("CO", "DO", "EX", "AP", "HE", "LA", "LL", "TG",
                                "BG", "MG", "FC", "CE", "RT")

#' Repair Glued Tokens in a Name Vector
#'
#' Always applies [split_glued_honorific()] (Defect 2), and from the third
#' token on [split_glued_credentials()] (`JRMD`, `MDMPH`). The stray-initial
#' split [split_glued_initial()] (Defect 3) is applied only when
#' `split_initials` is `TRUE`, because it cannot be made safe from a single
#' record: a foreign given name absent from the census (e.g. `KYUN`) is
#' indistinguishable from a glued initial + surname (`C` + `WOOLFOLK`) on
#' frequency alone, so it should run only where cross-year consensus (synthid)
#' can vet the result.
#'
#' @param name_vec A character vector of name tokens.
#' @param split_initials Logical; enable the Defect 3 stray-initial split.
#'   Defaults to `FALSE`.
#' @return A character vector, possibly longer than the input.
#' @keywords internal
deglue_tokens <- function( name_vec, split_initials = FALSE ) {
  if ( length( name_vec ) == 0 ) return( name_vec )
  unlist( lapply( seq_along( name_vec ), function( i ) {
    tok <- name_vec[ i ]
    h <- split_glued_honorific( tok )
    if ( length( h ) > 1 ) return( h )
    if ( i >= 3 ) {
      g <- split_glued_credentials( tok )
      if ( length( g ) > 1 ) return( g )
    }
    if ( split_initials ) split_glued_initial( tok ) else tok
  } ), use.names = FALSE )
}

# Ambiguous short credentials (Defect 1 follow-up): stripped only when they sit
# in a TRAILING run of known titles/suffixes that also contains at least one
# unambiguous credential -- so "MA LIN" (a real name) is never mistaken for a
# credential, but "... RDMS RM" is.
.ambiguous_suffix_credentials <- c(
  "RM",
  # Suffix gaps tier 2 (data-raw/SUFFIX-GAPS-PART7.md): short credentials that
  # collide with surnames (MA, BA), initials (NP, AB), places (DC, ND) or words
  # (APR, PT, DBA, STD) even at the end of a name, so they need a real
  # credential beside them. (OP, SC, SP, CR, HM, DD are trailing-only titles.)
  "MA", "BA", "AB", "ND", "NP", "PT", "DC",
  "VF", "VG", "PM", "APR", "DBA", "CEM", "CRP", "MSA", "AUD", "STD")

# Status words that parse_name() always moves to `status`.
.status_words <- c("-RESIGNED", "RESIGNED", "INTERIM", "EXOFFICIO",
                   "FORMER", "PAST", "DECEASED", "RETIRED", "OUTGOING",
                   "ASOF", "TEMPORARY", "THRU", "THROUGH", "PRESENT")

# Tenure notes (suffix gaps): moved to `status` only from the trailing run,
# because some are also surnames (BEGIN 2,644 and BEGAN 351 census records;
# PART 103): "KENT CASHELL TERM ENDED" -> status TERM_ENDED.
.trailing_status_words <- c(
  "TERM", "ENDED", "EXIT", "EXITED", "JOINED", "BEGAN", "BEGIN", "ENTERED",
  "ENTRY", "TERMINATED", "RESIGN", "SINCE", "TIL", "THR", "EFFECTIVE",
  "INCOMING", "EMERITUS", "DECD", "NONVOTING", "PART", "PARTIAL", "YEAR")

# Titles stripped only from the trailing run, with at least two name tokens
# before it: SJ and CISA begin some names as initials or a given name, IHM and
# FAIA are rare surnames, and role words appended to a name ("LARRY BLACK
# SECRETARY") include surnames (PRESIDENT 895, CHAIR 139). VICE is joined to
# its role word by prep_name() (VICE CHAIR -> VICECHAIR).
.trailing_only_titles <- c(
  "SJ", "CISA", "IHM", "FAIA",
  # MC at the end is a credential (Navy Medical Corps); a split MC surname
  # inside a name is joined by prep_name() before this point (MC CORMICK)
  "MC",
  # Short religious-order and church post-nominals: Dominicans (OP), Sisters of
  # Charity (SC), Sisters of Providence (SP), Resurrectionists (CR), Humility of
  # Mary (HM), Doctor of Divinity (DD). In 410,071 Part VII names none is a
  # census name; at the end of a name they are the order (26 of 28 OP), while
  # first-word uses are initials (CR HACKWORTHY, HM CHERRY, BRUCE DD MACRAE).
  "OP", "SC", "SP", "CR", "HM", "DD",
  "PRESIDENT", "CHAIR", "CHAIRMAN", "CHAIRWOMAN", "CHAIRPERSON", "SECRETARY",
  "TREASURER", "TRUSTEE", "SVP", "EVP", "ASSOCIATE", "ASSOC", "ASST",
  "VICECHAIR", "VICECHAIRMAN", "VICECHAIRWOMAN", "VICECHAIRPERSON",
  "VICEPRESIDENT", "VICEPRES")

# Titles that are also common surnames (BISHOP 116,618 census records; SHERIFF,
# CANTOR, DEACON, CAPTAIN, MOST, IMAM, BROTHER): stripped only as the first
# token with at least two tokens after it ("RABBI"-style "BISHOP JOHN SMITH"),
# so "JOHN BISHOP" keeps its surname. MOST is nearly always "MOST REV".
.leading_only_titles <- c("BISHOP", "SHERIFF", "CANTOR", "DEACON", "CAPTAIN",
                          "MOTHER", "MOST", "IMAM", "BROTHER")

#' Position-Restricted Titles and Status Words to Strip
#'
#' Finds the tokens that may be stripped from this name only because of where
#' they sit: trailing-only titles and tenure status words inside the maximal
#' trailing run of known tokens (each with at least two tokens before it), and a
#' leading-only title in first position (with at least two tokens after it).
#'
#' @param name_vec A character vector of name tokens.
#' @param prefixes,suffixes The active prefix/suffix removal sets.
#' @return A list with `titles` (tokens to add to the prefix set for this name)
#'   and `status` (tokens to add to the status set).
#' @keywords internal
positional_tokens <- function( name_vec, prefixes, suffixes ) {
  out <- list( titles = character( 0 ), status = character( 0 ) )
  n <- length( name_vec )
  if ( n == 0 ) return( out )
  known <- c( prefixes, suffixes, .ambiguous_suffix_credentials, .status_words,
              .trailing_status_words, .trailing_only_titles )
  k <- 0
  while ( k < n && name_vec[ n - k ] %in% known ) k <- k + 1
  if ( k > 0 ) {
    idx <- ( n - k + 1 ):n
    idx <- idx[ idx >= 3 ]          # at least two tokens before the token itself
    run <- name_vec[ idx ]
    out$titles <- unique( run[ run %in% .trailing_only_titles ] )
    out$status <- unique( run[ run %in% .trailing_status_words ] )
  }
  if ( n >= 3 && name_vec[1] %in% .leading_only_titles )
    out$titles <- unique( c( out$titles, name_vec[1] ) )
  # two tokens: a leading title before a word that is not mostly a given name
  # ("SHERIFF MASRY", "BROTHER STEWART"); "BISHOP JOHN" is left alone, since it
  # may be JOHN BISHOP written surname first
  if ( n == 2 && name_vec[1] %in% .leading_only_titles && nchar( name_vec[2] ) > 1 ) {
    cd <- get_census_data( name_vec[2] )
    if ( cd$first_name_value[1] <= cd$last_name_value[1] )
      out$titles <- unique( c( out$titles, name_vec[1] ) )
  }
  out
}

#' Ambiguous Suffix Credentials Eligible to Strip
#'
#' Returns the ambiguous short credentials (e.g. `RM`) that appear inside the
#' maximal trailing run of known prefix/suffix tokens, provided that run also
#' contains at least one unambiguous credential. Callers add the result to the
#' prefix-removal set for that name only.
#'
#' A religious title as the first word also licenses `DC` (Daughters of
#' Charity) and `MA` in the trailing run, when at least two tokens sit between
#' the title and the credential: `"SR ELLEN KRON DC"` -> `KRON`, while
#' `"SR ANNA MA"` keeps `MA`.
#'
#' @param name_vec A character vector of name tokens.
#' @param prefixes,suffixes The active prefix/suffix removal sets.
#' @param ambiguous The ambiguous short-credential set.
#' @return A character vector of tokens to strip (possibly empty).
#' @keywords internal
trailing_ambiguous_credentials <- function( name_vec, prefixes, suffixes,
                                            ambiguous = .ambiguous_suffix_credentials ) {
  n <- length( name_vec )
  if ( n == 0 ) return( character( 0 ) )
  # the run may also hold role words and tenure notes ("... RN MA TERM ENDED"),
  # but only real credentials (prefixes/suffixes) license an ambiguous strip
  known <- c( prefixes, suffixes, ambiguous, .status_words,
              .trailing_status_words, .trailing_only_titles )
  k <- 0
  while ( k < n && name_vec[ n - k ] %in% known ) k <- k + 1
  if ( k == 0 ) return( character( 0 ) )
  idx <- ( n - k + 1 ):n
  run <- name_vec[ idx ]
  out <- if ( any( run %in% c( prefixes, suffixes ) ) ) unique( run[ run %in% ambiguous ] ) else character( 0 )
  # religious-title licence: a leading religious title, and the token at least
  # fourth (title + two names before it)
  if ( name_vec[1] %in% .religious_titles ) {
    rel <- name_vec[ idx[ idx >= 4 ] ]
    out <- unique( c( out, rel[ rel %in% .religious_licensed_credentials ] ) )
  }
  out
}

# Religious titles that, as the first word, license .religious_licensed_credentials
# at the end of the name. In 410,071 Part VII names, 39 of the 100 names ending in
# DC start with SR/SISTER (Daughters of Charity); MA after a religious title is
# the degree (1 of 57).
.religious_titles <- c("SR", "SISTER", "SIS", "FR", "FATHER", "REV", "REVEREND",
                       "BR", "BROTHER", "MSGR", "MONSIGNOR", "MOST", "VERY",
                       "BISHOP", "ARCHBISHOP", "DEACON", "MOTHER")
.religious_licensed_credentials <- c("DC", "MA")


#' Parse a Full Name into Components
#'
#' Parses a full name string into components such as salutation, first name, middle name, last name,
#' suffix, status, and inferred gender.
#'
#' @param x A character string representing a person's name.
#' @param prefixes A character vector of salutations/prefixes to remove.
#'   Defaults to [prx].
#' @param suffixes A character vector of suffixes to remove. Defaults to [sfx].
#' @param sanitize Logical; if `TRUE`, run [sanitize_input()] on `x` first. Set
#'   `FALSE` (the default) when the input has already been sanitized, as
#'   [parse_names()] does for the whole vector.
#' @param split_initials Logical; if `TRUE`, also split a stray initial fused
#'   onto a surname (Defect 3, e.g. `CWOOLFOLK` -> `C WOOLFOLK`). Off by default
#'   because it is unreliable on a single record and can break legitimate names
#'   absent from the census; enable only where cross-year consensus can vet the
#'   output. See [deglue_tokens()].
#' @param add_nicknames Logical; if `TRUE`, append the nickname columns from
#'   [nickname_lookup()]. Defaults to `FALSE`.
#'
#' @return A one-row `data.frame` with columns `salutation`, `first_name`,
#'   `middle_name`, `last_name`, `suffix`, `status`, `gender`, and
#'   `gender_confidence` (plus the nickname columns if `add_nicknames = TRUE`).
#' @export
#'
#' @examples
#' parse_name("LIVINGSTON III MICHAEL JOHN")
#' parse_name("livingston III,  Mr. MICHAEL JOHN9", sanitize = TRUE)
parse_name <- function( x, prefixes = prx, suffixes = sfx, sanitize = FALSE,
                        split_initials = FALSE, add_nicknames = FALSE ) {
  if ( sanitize ) { x <- sanitize_input( x ) }
  Lx <- strsplit( x, ' ' ) |> unlist()   # strsplit( x, ' ' )[[1]]

  # Repair tokens where a title fused onto the next token (Defect 2,
  # PARSE-FAIL-NOTES.md), e.g. "MRWILLIAM" -> "MR" "WILLIAM"; optionally also
  # split a stray initial glued to a surname (Defect 3).
  Lx <- deglue_tokens( Lx, split_initials = split_initials )
  orig.tokens <- Lx                      # original order, for salutation recovery

  # Ambiguous short credentials (e.g. RM) strip only from a trailing credential
  # run (Defect 1 follow-up); fold the eligible ones into the prefix set here.
  # Position-restricted titles and tenure notes (suffix gaps,
  # data-raw/SUFFIX-GAPS-PART7.md): trailing-only titles and role words,
  # leading-only titles that are also surnames, tenure words at the end.
  pos <- positional_tokens( Lx, prefixes, suffixes )
  prefixes <- c( prefixes,
                 trailing_ambiguous_credentials( Lx, prefixes, suffixes ),
                 pos$titles )

  salutation.out <- extract_component( Lx, prefixes )
  salutation.name <- salutation.out$name; Lx <- salutation.out$remainder

  suffix.out <- extract_component( Lx, suffixes )
  suffix.name <- suffix.out$name; Lx <- suffix.out$remainder

  status.out <- extract_component( Lx, c( .status_words, pos$status ) )
  status <- status.out$name; Lx <- status.out$remainder

  name.parts <- assign_names( Lx, suffix.name )
  first.name <- name.parts$first
  middle.name <- name.parts$middle
  last.name <- name.parts$last
  gender <- name.parts$gender

  # fix middle/last inference
  if ( nchar( middle.name ) > 2 ) {
    mn_fixed <- resolve_middle_name( middle.name, last.name, tokens = Lx )
    middle.name <- mn_fixed[1]
    last.name <- mn_fixed[2]
  }

  # Recover a salutation that was really part of the name. Some tokens are BOTH
  # a title/credential and a common census name (EARL, DEAN, ED, JD, PA, MAJOR,
  # CAPT...). If stripping the salutation left no first name and the removed
  # token is a known census name, restore it -- using its ORIGINAL position to
  # decide its role: a LEADING token is the given name ("EARL FAHNESTOCK" ->
  # first EARL), a TRAILING token is the surname and the remaining token is the
  # given name ("TOM MAJOR" -> first TOM, last MAJOR). JD/ED are kept explicitly
  # in case they fall below the census first-name threshold.
  # A leading-only title stripped from a two-token name ("SHERIFF MASRY") was
  # judged a title on purpose, so it is not restored.
  if ( first.name == "" && salutation.name != "" &&
       !salutation.name %in% .leading_only_titles &&
       ( salutation.name %in% c( "JD", "ED" ) ||
         get_census_data( salutation.name )$first_name_value[1] > 0 ) ) {
    sal.pos  <- match( salutation.name, orig.tokens )
    last.pos <- match( last.name, orig.tokens )
    if ( !is.na( sal.pos ) && !is.na( last.pos ) && sal.pos > last.pos ) {
      # salutation trailed the name -> it is the surname; promote the remainder
      first.name <- last.name
      last.name  <- salutation.name
    } else {
      # salutation led the name (or position unknown) -> it is the given name
      first.name <- salutation.name
    }
    salutation.name <- ""
    # gender was inferred from the surname-only remainder; recompute from the
    # now-resolved first name.
    g <- determine_gender( get_census_data( first.name ) )
    if ( length( g ) == 2 ) gender <- g
  }

  if ( grepl( "^MAY-", last.name ) ) {
    middle.name <- paste0( middle.name, " MAY" )
    last.name <- gsub( "^MAY-", "", last.name )
  }

  out <- data.frame(
    salutation        = salutation.name,
    first_name        = first.name,
    middle_name       = middle.name,
    last_name         = last.name,
    suffix            = suffix.name,
    status            = status,
    gender            = gender[1],
    gender_confidence = gender[2]
  )
  if ( add_nicknames ) out <- add_nickname_columns( out )
  out
}
