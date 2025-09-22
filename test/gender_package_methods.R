

df <- d[ d$ENTITY != "ORGANIZATION" , ]

head( paste( df$FIRSTNAME, df$LASTNAME, sep=" " ), 1000 )



library( gender )

firstname <- head( df$FIRSTNAME, 100 )


  [1] "ADAM"             "DON"              "SCOTT"           
  [4] "MOHAMED"          "MONIFA"           "HAMDAN"          
  [7] "OMAR"             "DAMELIA"          "CURLEY"          
 [10] "OLAN"             "MAIMOUNA"         "REBECCA"         
 [13] "WHITNEY"          "GILDAS"           "RICHARD"         
 [16] "JAMIE"            "EFREN"            "AMY"             
 [19] "MARK"             "CHELSEA"          "MARGARET"        
 [22] "ARCHANA"          "PATRICK"          "BRITT ROBERT"    
 [25] "PROCOPIO"         "COREY"            "DANIELLE"        
 [28] "SANDRA"           "COURTNEY"         "CHRISTOPHER"     
 [31] "AMY"              "GIOIA"            "SHAWN"           
 [34] "TARA"             "JULIA"            "JM"              
 [37] "CHRISTOPHER"      "PUTHENPURACKAL C" "MEGAN"           
 [40] "CHARITY"          "RAY"              "JULIO"           
 [43] "HELEN"            "ABEL"             "CHRISTINA"       
 [46] "DWAYNE"           "TANIEKA"          "KIM"             
 [49] "CARL"             "STEVE"            "HUIMIN"          
 [52] "FAN"              "MACCON"           "PETER"           
 [55] "ANNA"             "TIMOTHY"          "KATHY"           
 [58] "CEVIN"            "OLENA"            "TALITHA"         
 [61] "ZHIYU"            "STACEY"           "DONALD"          
 [64] "IVAN"             "MELISSA"          "GLADYS"          
 [67] "TIM"              "AYMAN"            "PASQUALE"        
 [70] "DANIELLE"         "JONATHAN GARY"    "DARIA"           
 [73] "SAMUEL"           "JENNIFER"         "RICHARD"         
 [76] "MARK"             "ELTON"            "AWILDA"          
 [79] "SHERRY"           "JEFFREY"          "LORI"            
 [82] "LARRY"            "ERIK"             "ENEDINA"         
 [85] "JACKIE"           "FRANCESCA"        "MELONEY"         
 [88] "LORI"             "CALLISTUS"        "LUIS"            
 [91] "NICHOLAS"         "JIM"              "GREG"            
 [94] "VICTORIA"         "DEWAYNE"          "JOHN"            
 [97] "YOLANDA"          "WILL"             "DR SINDU"        
[100] "KEONA"           



g <- gender( firstname )
table(g$gender)

g <- gender( firstname, method="ipums" )
table(g$gender)

g <- gender( firstname, method="napp" )
table(g$gender)

g <- gender( firstname, method="kantrowitz" )
table(g$gender)

g <- gender( firstname, method="genderize" )
table(g$gender)
 



> g <- gender( firstname )
> table(g$gender)

female   male 
    44     46 
> 
> g <- gender( firstname, method="ipums" )
> table(g$gender)

female   male 
    33     55 
> 
> g <- gender( firstname, method="napp" )
> table(g$gender)

female   male 
    24     42 
> 
> g <- gender( firstname, method="kantrowitz" )
> table(g$gender)

either female   male 
     9     28     33 
> 
> g <- gender( firstname, method="genderize" )
Error in FUN(X[[i]], ...) : Too Many Requests (RFC 6585) (HTTP 429).
> table(g$gender)

either female   male 
     9     28     33 
>  





names <- paste( df$FIRSTNAME[1:10000], df$LASTNAME[1:10000] )
p <- peopleparser::parse.names( names )
table( p$gender ) |> knitr::kable()



