#' Split a Surname and Given Name Written as One Word
#'
#' Some records run a person's surname and given name together: `KramerKenneth`,
#' `LedbetterJennifer A`, `MURPHYSANDRA`. `split_run_together()` puts the space
#' back when the evidence is strong, and leaves every other name alone. The
#' parser's order rules then decide which part is the surname, as for any
#' other name.
#'
#' Two rules, both requiring that the whole word is not itself a name in
#' [census.names]:
#'
#' * **A capital letter inside a word** (`KramerKenneth`): split at the
#'   capital when both parts have at least three letters, one is mostly a
#'   surname and the other mostly a given name in the census (at least 80% of
#'   500 or more records), and the first part is not a surname particle
#'   (`McDonald`, `MacArthur`, `DeShawn`, `LaToya`, `VanDyke` and similar are
#'   left alone).
#' * **All capitals** (`MURPHYSANDRA`): only when the word is the name's one
#'   word of two or more letters (other words are initials, titles or
#'   suffixes), has at least eight letters, and splits into a strong surname
#'   (95% of 2,000 or more records) and a strong given name (95% of 20,000 or
#'   more records), each of four or more letters. Words that recur in many
#'   different Form 990 names (`MARKWALD`, `PEARLSTONE`, `GLENFIELD`) are real
#'   surnames and are never split.
#'
#' The all-capitals rule is the riskier of the two: a rare surname can look
#' like two common names. That is why [parse_names()] runs neither rule unless
#' asked (`split_run_together = TRUE`).
#'
#' @param x A character vector of raw names.
#'
#' @return `x`, with a space inserted where a run-together word was split.
#' @seealso `vignette("name-types")`
#' @export
#' @examples
#' split_run_together(c("KramerKenneth", "LedbetterJennifer A", "MURPHYSANDRA",
#'                      "McDonald", "LaToya Smith", "JOHN MARKWALD", "MARKWALD J"))
split_run_together <- function( x ) {
  out <- as.character( x )
  ok  <- !is.na( out )
  # mixed case: a lower-case letter followed by a capital
  mc <- which( ok & grepl( "[a-z][A-Z]", out ) )
  if ( length( mc ) ) out[ mc ] <- vapply( out[ mc ], split_mixed_case_name, "", USE.NAMES = FALSE )
  # all capitals: one long word that is the name's only word of 2+ letters
  ac <- which( ok & !grepl( "[a-z]", out ) & grepl( "[A-Z]{8,}", out ) )
  if ( length( ac ) ) out[ ac ] <- vapply( out[ ac ], split_all_caps_name, "", USE.NAMES = FALSE )
  out
}

# Surname particles that begin a word with an inner capital (McDonald).
.run_together_particles <- c( "MC", "MAC", "DE", "DI", "DU", "DA", "LA", "LE", "LO",
                              "VAN", "VON", "VANDER", "DEN", "DER", "DEL", "DELLA",
                              "DOS", "DAS", "ST", "O", "FITZ", "BEN", "AL", "EL", "ABU" )

# Census counts as a list(f, l) for a vector of upper-case words.
run_together_counts <- function( w ) {
  cd <- get_census_data( w )
  list( f = cd$first_name_value, l = cd$last_name_value )
}

# TRUE where a is mostly a surname and b mostly a given name, or the reverse.
run_together_pair_ok <- function( A, B, share, min_l, min_f ) {
  sur <- function( z ) z$l >= min_l & z$l >= share * ( z$f + z$l )
  giv <- function( z ) z$f >= min_f & z$f >= share * ( z$f + z$l )
  ( sur( A ) & giv( B ) ) | ( giv( A ) & sur( B ) )
}

split_mixed_case_name <- function( s ) {
  words <- strsplit( s, " ", fixed = TRUE )[[1]]
  for ( j in seq_along( words ) ) {
    # leading or trailing punctuation is kept aside ("KramerKenneth,")
    pre  <- sub( "^([^A-Za-z]*).*$", "\\1", words[ j ] )
    post <- sub( "^.*?([^A-Za-z]*)$", "\\1", words[ j ], perl = TRUE )
    w <- substr( words[ j ], nchar( pre ) + 1, nchar( words[ j ] ) - nchar( post ) )
    if ( !grepl( "[a-z][A-Z]", w ) || grepl( "[^A-Za-z]", w ) ) next
    W <- toupper( w )
    wc <- run_together_counts( W )
    if ( wc$f + wc$l > 0 ) next
    k <- gregexpr( "[a-z][A-Z]", w )[[1]]
    a <- substr( rep( w, length( k ) ), 1, k )
    b <- substring( w, k + 1 )
    use <- nchar( a ) >= 3 & nchar( b ) >= 3 & !toupper( a ) %in% .run_together_particles
    if ( !any( use ) ) next
    a <- a[ use ]; b <- b[ use ]
    ok <- run_together_pair_ok( run_together_counts( toupper( a ) ),
                                run_together_counts( toupper( b ) ),
                                share = 0.8, min_l = 500, min_f = 500 )
    if ( any( ok ) ) {
      i <- which( ok )[1]
      words[ j ] <- paste0( pre, a[ i ], " ", b[ i ], post )
    }
  }
  paste( words, collapse = " " )
}

split_all_caps_name <- function( s ) {
  words <- strsplit( trimws( s ), " +" )[[1]]
  bare  <- gsub( "[^A-Z]", "", words )
  full  <- nchar( bare ) >= 2 & !bare %in% c( prx, sfx )
  if ( sum( full ) != 1 ) return( s )
  j <- which( full )
  w <- bare[ j ]
  if ( nchar( w ) < 8 || w != words[ j ] || w %in% run_together_block ) return( s )
  wc <- run_together_counts( w )
  if ( wc$f + wc$l > 0 ) return( s )
  i <- 4:( nchar( w ) - 4 )
  a <- substr( rep( w, length( i ) ), 1, i )
  b <- substring( w, i + 1 )
  A <- run_together_counts( a ); B <- run_together_counts( b )
  ok <- run_together_pair_ok( A, B, share = 0.95, min_l = 2000, min_f = 20000 )
  if ( !any( ok ) ) return( s )
  sc <- log1p( A$f + A$l ) + log1p( B$f + B$l )
  sc[ !ok ] <- -Inf
  k <- which.max( sc )
  words[ j ] <- paste( a[ k ], b[ k ] )
  paste( words, collapse = " " )
}
