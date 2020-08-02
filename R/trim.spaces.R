
trim.spaces <- function(x) {
  return(gsub('(?<=[\\s])\\s*|^\\s+|\\s+$', '', x, perl=TRUE))
}
