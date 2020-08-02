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
  return.value <- toupper(gsub('.', ' ', return.value, fixed = TRUE))

  # remove punctuation
  return.value <- gsub('[[:punct:]]', '', return.value)
  return.value <- gsub('[[:digit:]]', '', return.value)

  # remove dup'd spaces
  return.value <- trim.spaces(return.value)

  # dash compound last names
  n <- strsplit(return.value,' ')[[1]]
  zz <- c('LA','VON','VAN','DEL','DE')
  zzz <- paste(n, '-', sep='')
  b <- (n %in% zz)
  n[b] <- zzz[b]

  return.value <- gsub('- ', '-', paste(n, collapse = ' '))

  return(return.value)
}
