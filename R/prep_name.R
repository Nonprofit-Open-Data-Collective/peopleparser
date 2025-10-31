#' Trim spaces from names 
#' @export
trim_spaces <- function(x) {
  return(gsub('(?<=[\\s])\\s*|^\\s+|\\s+$', '', x, perl=TRUE))
}

#' Remove punctuation
#' @export
remove_punctuation <- function(x) {
   return(gsub('[[:punct:]]', '', x))
}

#' Fix Locative or Compound Surnames by Adding Dashes
#'
#' This function identifies common surname particles (e.g., *Van*, *De*, *Von*, *Mc*)
#' that typically appear in compound or locative surnames (e.g., *Van Dyke*, *De La Rosa*)
#' and merges them with the following word using a dash (e.g., *Van-Dyke*, *De-La-Rosa*).
#'
#' These particles, known as *nobiliary particles* or *locative prefixes*, often denote
#' origin or family lineage and are part of many compound surnames in European languages.
#'
#' @param x A character vector of full names.
#' @param particles A character vector of common surname particles to merge
#'   with the following word. Matching is case-insensitive.
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
#' #> [4] "Carlos De-La-Rosa" "VAN CLIBURN"        "Dylan Van"
#'
#' @seealso
#'   For background on surname particles and compound surnames, see
#'   \href{https://en.wikipedia.org/wiki/Particle_(surname)}{Wikipedia: Nobiliary particle}.
#'
#' @export
fix_locative_surnames <- function(x,
                                  particles = c("LA", "VON", "VAN", "DEL", "DE", "DI", "DEN", "DER", "MC", "O")) {
  lapply(strsplit(x, "\\s+"), function(words) {
    upper_words <- toupper(words)
    i <- seq_along(words)
    
    # find positions where current word is a prefix and next exists
    b <- upper_words %in% particles & i < length(words)
    
    # merge prefix and next word with a dash
    if (any(b)) {
      for (j in which(b)) {
        words[j] <- paste0(words[j], "-", words[j + 1])
        words[j + 1] <- NA_character_  # remove merged element
      }
      words <- words[!is.na(words)]
    }
    
    paste(words, collapse = " ")
  }) |> unlist()
}



#' Prep Character Vector for Name Parsing
#'
#' This function
#' @param x Provide the character vector to prep.
#' @export
#' @note If more then one element is passed in, only the first element will be preppred and returned.
#' @examples
#' x <- 'livingston III,   MICHAEL JOHN9'
#' prep.name(x)
prep_name <- function(x) {

  # x <- x[1]

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
  x <- gsub( "LO GRANDE", "LO-GRANDE", x )
  x <- gsub( " VAN DER ", "VAN-DER-", x )        
  x <- gsub( " DE ", " DE-", x )  # DE LEEUW to DE-LEEUW
  x <- gsub( "-DE ", "-DE-", x )  # BAILEY-DE LEEUW to BAILEY-DE-LEEUW: double compound last name
  x <- gsub( " DI ", " DI-", x )  # Julia Di Bussolo  
  x <- gsub( " MC .*$", " MC", x )
  
  # turn locative surnames (van=from, de=of, etc) into compounds
  x <- fix_locative_surnames( x )
  
  # dash compound last names
  # n <- strsplit( x, ' ' )[[1]]
  # zz <- c( 'LA','VON','VAN','DEL','DE', 'DER', 'MC' )
  # zzz <- paste0( n, '-' )
  # b <- ( n %in% zz )
  # n[b] <- zzz[b]
  # x <- gsub('- ', '-', paste( n, collapse = ' ') )

  return(x)
}
