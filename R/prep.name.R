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
  return.value <- gsub( " PH D", " PHD", return.value )
  return.value <- gsub( " PYS D", " PYSD", return.value )
  return.value <- gsub( " ED D", " EDD", return.value ) 
  return.value <- gsub( "LT GEN", "LTGEN", return.value )
  return.value <- gsub( "EX OFFICIO", "EXOFFICIO", return.value )
  return.value <- gsub( "EX-OFFICIO", "EXOFFICIO", return.value )
  return.value <- gsub( "LO GRANDE", "LO-GRANDE", return.value )
  return.value <- gsub( " VAN DER ", "VAN-DER-", return.value )
  return.value <- gsub( " DE ", " DE-", return.value )  # DE LEEUW to DE-LEEUW
  return.value <- gsub( "-DE ", "-DE-", return.value )  # BAILEY-DE LEEUW to BAILEY-DE-LEEUW
  return.value <- gsub( " DI ", " DI-", return.value )  # Julia Di Bussolo  
  
  # dash compound last names
  n <- strsplit( return.value, ' ' )[[1]]
  zz <- c( 'LA','VON','VAN','DEL','DE' )
  zzz <- paste( n, '-', sep='' )
  b <- ( n %in% zz )
  n[b] <- zzz[b]

  return.value <- gsub('- ', '-', paste( n, collapse = ' ') )

  return(return.value)
}
