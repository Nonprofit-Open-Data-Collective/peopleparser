devtools::build_github_devtools()

library(devtools)
has_devel()

setwd( "C:/Documents/GitHub" )
usethis::create_package( "peopleparser" )

setwd( "peopleparser" )
devtools::document()


setwd( ".." )
devtools::install( "peopleparser" )
library( "peopleparser" )



######

x <- 'livingston III,  Mr. MICHAEL JOHN9'
parse.name(x)

x <- "THOMAS H VON KAMECKE"
parse.name(x)

x <- get_example_names( n=10 )
parse.names(x)


