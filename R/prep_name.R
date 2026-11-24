#' Collapse and Trim Whitespace
#'
#' Removes leading and trailing whitespace and collapses runs of internal
#' whitespace to a single space.
#'
#' @param x A character vector.
#'
#' @return A character vector with normalized whitespace.
#' @export
#' @examples
#' trim_spaces("  JOHN   Q   PUBLIC  ")
trim_spaces <- function(x) {
  return(gsub('(?<=[\\s])\\s*|^\\s+|\\s+$', '', x, perl=TRUE))
}

#' Remove Punctuation
#'
#' Strips all punctuation characters from a string.
#'
#' @param x A character vector.
#'
#' @return A character vector with punctuation removed.
#' @export
#' @examples
#' remove_punctuation("O'BRIEN, JR.")
remove_punctuation <- function(x) {
   return(gsub('[[:punct:]]', '', x))
}

#' Fix Locative or Compound Surnames by Adding Dashes
#'
#' This function identifies common surname particles (e.g., *Van*, *De*, *Von*)
#' that typically appear in compound or locative surnames (e.g., *Van Dyke*, *De La Rosa*)
#' and merges them with the following word using a dash (e.g., *Van-Dyke*, *De-La-Rosa*).
#'
#' These particles, known as *nobiliary particles* or *locative prefixes*, often denote
#' origin or family lineage and are part of many compound surnames in European languages.
#'
#' @param x A character vector of full names.
#' @param particles A character vector of common surname particles to merge
#'   with the following word. Matching is case-insensitive. `MC` is not a
#'   default particle: [prep_name()] joins a split `MC` surname without a dash
#'   (`MC CORMICK` -> `MCCORMICK`, see `join_mc()`), and a leading or trailing
#'   `MC` is initials or a credential (Medical Corps).
#' @param inner_particles Particles that are joined only when they are not
#'   the first word and the next word is not a title or suffix:
#'   `PATRICIA SAN PEDRO` -> `SAN-PEDRO`, `KATRINA VANDEN HEUVEL` ->
#'   `VANDEN-HEUVEL`, `ESTELLA DE LOS RIOS` -> `DE-LOS-RIOS`. Some of them
#'   are also given names or words (`SANTA`, `TEN`), so they never join
#'   from the start of a name.
#'
#' @return A character vector of names with compound surnames corrected
#'   by inserting dashes between the particle and the following surname component.
#'
#' @examples
#' names <- c(
#'   "Jane Van Dyke",
#'   "Bob VAN DERVAL",
#'   "Mary von Diesel",
#'   "Carlos De La Rosa",
#'   "VAN CLIBURN",
#'   "Dylan Van"
#' )
#'
#' fix_locative_surnames(names)
#' #> [1] "Jane Van-Dyke"     "Bob VAN-DERVAL"     "Mary von-Diesel"
#' #> [4] "Carlos De-La-Rosa" "VAN-CLIBURN"        "Dylan Van"
#'
#' @seealso
#'   For background on surname particles and compound surnames, see
#'   \href{https://en.wikipedia.org/wiki/Particle_(surname)}{Wikipedia: Nobiliary particle}.
#'
#' @export
fix_locative_surnames <- function(x,
                                  particles = c("LA", "VON", "VAN", "VANDER", "DEL", "DE", "DI", "DEN", "DER", "O"),
                                  inner_particles = .inner_particles) {
  particles <- toupper(particles)
  inner_particles <- toupper(inner_particles)
  lapply(strsplit(x, "\\s+"), function(words) {
    # Join a word that is (or, once dashed, ends in) a particle to the next
    # word, and keep going, so chains join fully: DE LA ROSA -> DE-LA-ROSA,
    # and DE-LA ROSA (after prep_name()'s " DE " rule) -> DE-LA-ROSA.
    # An inner particle joins only after the first word and before a word
    # that is not a title or suffix (SAN PEDRO, but not RITA TEN MD).
    j <- 1
    while (j < length(words)) {
      tail_part <- sub(".*-", "", toupper(words[j]))
      inner <- j > 1 && tail_part %in% inner_particles &&
        !toupper(words[j + 1]) %in% c(prx, sfx)
      if (tail_part %in% particles || inner) {
        words[j] <- paste0(words[j], "-", words[j + 1])
        words <- words[-(j + 1)]
      } else {
        j <- j + 1
      }
    }
    paste(words, collapse = " ")
  }) |> unlist()
}



# Particles joined only inside a name (fix_locative_surnames()). In Part VII
# names each appears mostly as an inner word before a surname (SAN 51 inner,
# 1 first; VANDEN 12, 0). LE is left out: inside a name it is as often a
# Vietnamese surname or middle name (HANG LE TO) as a particle. AL and EL
# (0.2.3): MOHAMMED M AL HAEMLI -> AL-HAEMLI.
.inner_particles <- c("VANDEN", "VANDE", "SAN", "SANTA", "LOS", "LAS", "DELLA", "AL", "EL",
                      "DALLA", "DELA", "DOS", "DAS", "DA", "DU", "TEN", "TER")

#' Prep a Name for Parsing
#'
#' Normalizes raw name strings ahead of parsing: replaces periods with spaces,
#' upper-cases, strips punctuation (keeping dashes) and digits, collapses
#' whitespace, folds a set of period-separated abbreviations (e.g. `PH D` ->
#' `PHD`), and dashes compound / locative surnames (see [fix_locative_surnames()]).
#'
#' @param x A character vector of raw names to prep.
#'
#' @return A character vector of cleaned, upper-cased names.
#' @export
#' @examples
#' prep_name("livingston III,   MICHAEL JOHN9")
prep_name <- function(x) {

  # replace periods with spaces and cast to upper case
  x <- gsub( '.', ' ', x, fixed = TRUE ) 
  x <- toupper( x )

  # remove punctuation except dashes (compound last names)
  x <- gsub( '(?!-)[[:punct:]]', '', x, perl=T )
  x <- gsub( '[[:digit:]]', '', x )

  # remove dup'd spaces
  x <- trim_spaces( x )

  # clean-up compound words or abbreviations
  # with periods in the middle
  x <- gsub( " PH D", " PHD", x )
  x <- gsub( " PYS D", " PYSD", x )
  x <- gsub( " ED D", " EDD", x ) 
  x <- gsub( "LT GEN", "LTGEN", x )
  x <- gsub( "EX OFFICIO", "EXOFFICIO", x )
  x <- gsub( "EX-OFFICIO", "EXOFFICIO", x )
  # suffix gaps (data-raw/SUFFIX-GAPS-PART7.md)
  x <- gsub( "\\bDR PH\\b", "DRPH", x )                 # Dr.P.H. -> DRPH
  x <- gsub( "\\bNON[ -]VOTING\\b", "NONVOTING", x )
  x <- gsub( "\\bVICE[ -](CHAIR|CHAIRMAN|CHAIRWOMAN|CHAIRPERSON|PRESIDENT|PRES)\\b",
             "VICE\\1", x )                            # VICE alone is a surname
  # ST inside a name is "Saint" in a surname (SEAN ST CLAIR), not a title to
  # strip: join it to the next word, as for DE
  x <- gsub( "(?<=[A-Z]) ST (?=[A-Z])", " ST-", x, perl = TRUE )
  x <- gsub( "LO GRANDE", "LO-GRANDE", x )
  x <- gsub( " VAN DER ", " VAN-DER-", x )
  x <- gsub( " DE ", " DE-", x )  # DE LEEUW to DE-LEEUW
  x <- gsub( "-DE ", "-DE-", x )  # BAILEY-DE LEEUW to BAILEY-DE-LEEUW: double compound last name
  x <- gsub( " DI ", " DI-", x )  # Julia Di Bussolo  
  x <- join_mc( x )

  # turn locative surnames (van=from, de=of, etc) into compounds
  x <- fix_locative_surnames( x )

  return(x)
}

#' Join a Split "MC" Surname Prefix
#'
#' Inside a name, a standalone `MC` starts a surname written with a space
#' (`STEVE MC CORMICK`, `DENISE MC DERMOTT`). It is joined to the next word
#' without a dash (`MCCORMICK`), the spelling the census lists and other
#' records use. A leading `MC` before two or more words is joined to the next
#' word with a dash (`MC NELLY TORRES` -> `MC-NELLY`); before one word it is
#' left as initials (`MC OLSON`). A trailing `MC` is a credential (Navy
#' Medical Corps) and is left for the title rules, as is an `MC` followed by a
#' credential or suffix (`SANFORD MC USN`) or by a word starting with `MC`.
#'
#' (This replaces a rule that cut everything after a standalone `MC`, which
#' turned `CHARLES MC SPADDEN` into `CHARLES MC`.)
#'
#' @param x A character vector of upper-cased, space-separated names.
#' @return `x` with split `MC` surnames joined.
#' @keywords internal
join_mc <- function( x ) {
  vapply( strsplit( x, " ", fixed = TRUE ), function( t ) {
    i <- which( t == "MC" )
    i <- i[ i > 1 & i < length( t ) ]
    for ( j in rev( i ) ) {
      if ( !t[ j + 1 ] %in% c( prx, sfx ) && !startsWith( t[ j + 1 ], "MC" ) ) {
        t[ j + 1 ] <- paste0( "MC", t[ j + 1 ] )
        t <- t[ -j ]
      }
    }
    # a leading MC before two or more words belongs to the first name
    # (MC NELLY TORRES -> MC-NELLY TORRES), as the old particle rule did
    if ( length( t ) >= 3 && t[1] == "MC" && !t[2] %in% c( prx, sfx ) ) {
      t[2] <- paste0( "MC-", t[2] )
      t <- t[-1]
    }
    paste( t, collapse = " " )
  }, "" )
}
