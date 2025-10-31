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
  removal <- remove.elements( name_vec, elements )
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
  s <- 1 %in% l

  get_gender <- function(xx, fallback = FALSE) {
    if ( length(xx) == 0 ) return( c("U", "0.0") )
    g <- determine.gender( get.census.data( xx ) )
    if ( g[1] == "U" && fallback ) {
      if ( suffix.name != "" ) g <- c("M", "50.0")
      g[2] <- "50.0"
    }
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
    gender <- c("U", "0.0")

  } else if ( i == 3 ) {
    is.surname <- check_if_surname( x )
    if ( is.surname[1] && is.surname[2] && !is.surname[3] ) x <- x[c(3,1,2)]
    if ( is.surname[1] && !is.surname[2] ) x <- x[c(2,3,1)]
    first <- x[1]; middle <- x[2]; last <- x[3]
    gender <- get_gender( x[-3] )

  } else if ( i == 2 ) {
    data <- get.census.data( x )
    pos <- determine.surname( data )
    last <- x[pos]; first <- x[-pos]; middle <- ""
    gender <- determine.gender( data[-pos, ] )
    if ( gender[1] == "U" && suffix.name != "" ) gender <- c("M", "50.0")

  } else if ( i == 1 ) {
    first <- ""; middle <- ""; last <- x[1]
    gender <- c( ifelse( suffix.name != "", "M", "U" ), "50.0" )

  } else if ( i == 0 ) {
    first <- ""; middle <- ""; last <- ""; gender <- c("U", "0.0")

  } else {
    data <- get.census.data( x )
    pos <- determine.surname( data )
    is.surname <- check_if_surname( x )
    if ( is.surname[1] && is.surname[2] && !is.surname[3] ) {
      last <- paste( x[1:2], collapse = "-" ); first <- x[3]; middle <- paste( x[-(1:3)], collapse = " " )
    } else {
      last <- x[pos]; rest <- x[-pos]; first <- rest[1]
      middle <- if ( length( rest ) > 1 ) paste( rest[-1], collapse = " " ) else ""
    }
    gender <- determine.gender( data[-pos, ] )
    if ( gender[1] == "U" && suffix.name != "" ) gender <- c("M", "50.0")
  }

  list( first = first, middle = middle, last = last, gender = gender )
}


#' Resolve Middle Names as Potential Surnames
#'
#' Checks if a middle name segment is actually part of the last name.
#'
#' @param middle Character string of middle name.
#' @param last Character string of last name.
#'
#' @return A character vector of length 2: updated middle name and last name.
#' @export
resolve_middle_name <- function( middle, last ) {
  mn <- strsplit( middle, ' ' )[[1]]
  
  if ( length( mn ) == 1 && check_if_surname( mn ) ) return( c("", paste( mn, last, sep = "-" )) )

  if ( length( mn ) > 1 ) {
    if ( nchar( mn[1] ) == 1 && nchar( mn[2] ) > 1 )
      return( c( mn[1], paste0( paste( mn[-1], collapse = "-" ), "-", last ) ) )

    surname_flags <- check_if_surname( mn )
    if ( any( surname_flags ) ) {
      start <- min( which( surname_flags ) )
      mid <- if ( start > 1 ) paste( mn[1:(start - 1)], collapse = " " ) else ""
      last <- paste0( paste( mn[start:length(mn)], collapse = "-" ), "-", last )
      return( c( mid, last ) )
    }
  }

  c( middle, last )
}


#' Parse a Full Name into Components
#'
#' Parses a full name string into components such as salutation, first name, middle name, last name,
#' suffix, status, and inferred gender.
#'
#' @param x A character string representing a person's name.
#' @param prefixes A character vector of salutations/prefixes to remove.
#' @param suffixes A character vector of suffixes to remove.
#'
#' @return A pipe-separated string: salutation | first name | middle name | last name | suffix | status | gender | confidence.
#' @export
#'
#' @examples
#' parse.name("LIVINGSTON III MICHAEL JOHN")
parse_name <- function( x, prefixes = prx, suffixes = sfx, sanitize=F ) {
  if( sanitize ){x <- sanitize_input( x ) }
  Lx <- strsplit( x, ' ' ) |> unlist()   # strsplit( x, ' ' )[[1]]

  salutation.out <- extract_component( Lx, prefixes )
  salutation.name <- salutation.out$name; Lx <- salutation.out$remainder

  suffix.out <- extract_component( Lx, suffixes )
  suffix.name <- suffix.out$name; Lx <- suffix.out$remainder

  status.out <- extract_component( Lx, c("-RESIGNED", "RESIGNED", "INTERIM", "EXOFFICIO",
                                        "FORMER", "PAST", "DECEASED", "RETIRED", "OUTGOING",
                                        "ASOF", "TEMPORARY", "THRU", "THROUGH", "PRESENT") )
  status <- status.out$name; Lx <- status.out$remainder

  name.parts <- assign_names( Lx, suffix.name )
  first.name <- name.parts$first
  middle.name <- name.parts$middle
  last.name <- name.parts$last
  gender <- name.parts$gender

  # fix middle/last inference
  if ( nchar( middle.name ) > 2 ) {
    mn_fixed <- resolve_middle_name( middle.name, last.name )
    middle.name <- mn_fixed[1]
    last.name <- mn_fixed[2]
  }

  # recover salutation as first name if necessary
  if ( salutation.name %in% c( "JD", "ED" ) && first.name == "" ) {
    first.name <- salutation.name
    salutation.name <- ""
  }

  if ( grepl( "^MAY-", last.name ) ) {
    middle.name <- paste0( middle.name, " MAY" )
    last.name <- gsub( "^MAY-", "", last.name )
  }

c('name','salutation','first_name','middle_name', 'last_name',
                             'suffix', 'status', 'gender', 'gender_confidence')
                             
  data.frame( 
    salutation=salutation.name, 
    first_name=first.name, 
    middle_name=middle.name, 
    last_name=last.name,
    suffix=suffix.name, 
    status=status, 
    gender=gender[1], 
    gender_confidence=gender[2] )
}
