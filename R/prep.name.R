#' Prep Character Vector for Name Parsing
#'
#' This function
#' @param x Provide the character vector to prep.
#' @export
#' @note If more then one element is passed in, only the first element will be preppred and returned.
#' @examples
#' x <- 'livingston III,   MICHAEL JOHN9'
#' prep.name(x)
prep.name <- function(x) {

  return.value <- x[1]

  # replace periods with spaces and cast to upper case
  return.value <- gsub( '.', ' ', return.value, fixed = TRUE ) 
  return.value <- toupper( return.value )

  # remove punctuation except dashes (compound last names)
  return.value <- gsub( '(?!-)[[:punct:]]', '', return.value, perl=T )
  return.value <- gsub( '[[:digit:]]', '', return.value )

  # remove dup'd spaces
  return.value <- trim.spaces( return.value )

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
  x <- gsub( "-DE ", "-DE-", x )  # BAILEY-DE LEEUW to BAILEY-DE-LEEUW
  x <- gsub( " DI ", " DI-", x )  # Julia Di Bussolo  
  
  # dash compound last names
  n <- strsplit( return.value, ' ' )[[1]]
  zz <- c( 'LA','VON','VAN','DEL','DE' )
  zzz <- paste( n, '-', sep='' )
  b <- ( n %in% zz )
  n[b] <- zzz[b]

  return.value <- gsub('- ', '-', paste( n, collapse = ' ') )

  return(return.value)
}
