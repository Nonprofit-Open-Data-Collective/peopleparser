remove.punctuation <- function(x) {
   return(gsub('[[:punct:]]', '', x))
}
