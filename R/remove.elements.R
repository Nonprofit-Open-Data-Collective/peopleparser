#' Remove Character Elements From a Vector 
#'
#' This function returns a two part list of character vectors.  First, the new vector with the removed strings, 
#' and second, the vector with the elements that have been removed.
#' @param x Provide the character vector to parse.
#' @param remove.this Provide the elements that you want to remove.
#' @keywords remove
#' @export
#' @examples
#' x <- c('MICHAEL','JOHN','LIVINGSTON','III')
#' remove.elements(x, c('JR','II','III','IV'))
remove.elements <- function(x, remove.this) {

  removed <- x[x %in% remove.this]
  if (length(removed)==0) {
    removed[1] <- ''
  } else {
    x <- x[! x %in% remove.this]
  }

  rv <- list(names = x, removed_names = removed)
  
  return(rv)
}