#' Parse single name
#'
#' This function returns
#' @param x Provide the character vector to parse.
#' @param prefixes x
#' @param suffixes x
#' @keywords remove
#' @export
#' @examples
#' x <- 'LIVINGSTON III MICHAEL JOHN'
#' parse.name(x)
parse.name <- function(x,
                       prefixes = c('MR','DR','MISS','MS','MRS'),
                       suffixes = c('JR','II','III','IV','SR')) {
  # make a copy
  input.name <- x[1]

  # prepare name for parsing
  x <- prep.name(x)

  # split words in to vector
  x <- strsplit(x,' ')[[1]]

  # remove prefix
  removal <- remove.elements(x, prefixes)
  prefix <- removal$removed_names
  x <- removal$names
  salutation.name <- prefix[1]

  # remove suffix
  removal <- remove.elements(x, suffixes)
  suffix <- removal$removed_names
  x <- removal$names
  suffix.name <- suffix[1]

  # re-org/order name based on simple ruling
  l <- nchar(x)  # length of each element
  i <- length(x) # number of elements in the vector
  s <- 1 %in% l

  #
  if (i == 3 & s) {

    # and the last character is a single letter, flip names with far right initial
    if (l[i] == 1) {
      x <- x[c(2:i,1)]
      l <- nchar(x)  # length of each element
    }

    # remove the last element, and any single character elements as they wont be in the census matrix
    xx <- x[-3]
    xx <- xx[nchar(xx) > 1]

    #

    # define names
    first.name <- x[1]
    middle.name <- x[2]
    last.name <- x[3]

    # define gender
    if (length(xx) != 0) {
      working.set <- get.census.data(xx)
      gender <- determine.gender(working.set)
    } else {
      gender <- c('U','0.0')
    }

  }
  # if the name contains only a single word, use it as the last name
  else if (i == 1) {
    first.name <- ''
    middle.name <- ''
    last.name <- x[1]
    gender <- c(ifelse(suffix.name != '', 'M', 'U'),'50.0')
  }
  # if there is an empty vector, return empty strings
  else if (i == 0) {
    first.name <- ''
    middle.name <- ''
    last.name <- ''
    gender <- c('U','0.0')
  }
  #
  else {

    # load census data for all name parts
    working.set <- get.census.data(x)

    # get surname insight, and remove from name vector
    surname.findings <- determine.surname(working.set)
    xx <- x[-(surname.findings[1])]

    # remove surname from name vector
    working.set <- working.set[-(surname.findings[1]), ]

    # define names and gender
    i <- length(xx)
    first.name <- xx[1]
    middle.name <- trimws(ifelse(i >= 2, paste(xx[2:length(xx)], '', collapse = ' '), ''))
    last.name <- x[surname.findings[1]]
    gender <- determine.gender(working.set)

    if (gender[1] == 'U') {
      if (suffix.name != '') {
        gender <- c('M','50.0')
      }
      gender[2] <- '50.0'
    }

  }

  # build return value
  rv <- paste(c(salutation.name, first.name, middle.name, last.name, suffix.name, gender[1], gender[2]), collapse = '|')

  return(rv)
}
