
prefixes <- c("MR", "DR", "MISS", "MS", "MRS", 
              "MD", "SENATOR", "COMMISSIONER",
              "DELEGATE", "PhD", "CFA", "CPA",


suffixes <- c("JR","II", "III", "IV", "SR")


save( "suffixes", file="sfx.Rdata" )
save( "prefixes", file="prx.Rdata" )

# save( prefixes, suffixes, file="sysdata.rda" )