# peopleparser

R package to convert a raw text version of an individual's name into a structured format.

The functions attempt to disambiguate proper name ordering (first, middle, and last), parse prefixes and suffixes, and assign gender based upon first names.


## Installation

```r
devtools::install_github( "Nonprofit-Open-Data-Collective/peopleparser" )
library( peopleparser )
```

## Use

The program takes raw text individual names as the input and returns a data table with the name parsed into the component parts: 

* SALUTATION 
* FIRST_NAME 
* MIDDLE_NAME 
* LAST_NAME 
* SUFFIX 
* GENDER 

The matching is done probabilistically based upon frequencies of the name appearing as a first name or last name on US birth certificates. 

Gender coding is similarly done probabilistically using the first name from the parsed string and the same Census data table. 

```r

x <- 'livingston III,  Mr. MICHAEL JOHN9'
parse.name(x)
# [1] "MR|III,|MICHAEL  JOHN|LIVINGSTON||M|99.6"
 
x <- "THOMAS H VON KAMECKE"
parse.name(x)
# [1] "|THOMAS|H|VON-KAMECKE||M|99.8"
 
x <- get_example_names( n=10 )
parse.names(x)
                    name salutation first_name middle_name  last_name suffix gender gender_confidence
1          Karen H Green                 KAREN           H      GREEN             F               100
2               ED MARKS                    ED                  MARKS             M               100
3     MATTHEW BERSHADKER               MATTHEW             BERSHADKER             M              99.7
4     LINDA L SCHOELKOPF                 LINDA           L SCHOELKOPF             F               100
5            JAMES ROWAN                 JAMES                  ROWAN             M              99.7
6              R Blincoe                     R                BLINCOE             U              50.0
7       DENNIS PAGLIOTTI                DENNIS              PAGLIOTTI             M              99.5
8  HAFER JR EDMUND L AIA                 HAFER   EDMUND  L        AIA     JR      M               100
9          LESLIE CARNES                LESLIE                 CARNES             F              66.8
10     ALEXANDER PFEFFER             ALEXANDER                PFEFFER             M              98.4


# census data table used for name position assignment and gender 
head( census.names )
      name male_value female_value first_name_value last_name_value
1:     AAB          0            0                0             133
2:  AABERG          0            0                0             469
3:    AABY          0            0                0             220
4: AADLAND          0            0                0             374
5:  AAFEDT          0            0                0             138
6: AAGAARD          0            0                0             300
```

The **parse.names()** function utilizes parallelization to speed up large jobs. 

```r
x <- get_example_names( n=1000 )
 
start_time <- Sys.time()
pn <- parse.names( x )
end_time <- Sys.time()

end_time - start_time
# Time difference of 8.7648 secs
```

## Examples

To parse a name:

```r
# returns a single pipe (`|`) delimted string, e.g. "salutation|first|middle|last|suffix|gender|confidence".
x <- 'livingston III,  Mr. MICHAEL JOHN9'
parse.name(x)
# or, for multiple names in a `data.table` with similar attributes
parse.names(x)
```

To 'prepare' a name:
```r
x <- 'livingston III,  Mr. MICHAEL JOHN9'
prep.name(x)  
```

To get the census data:
```r
x <- 'livingston III,  Mr. MICHAEL JOHN9'
x <- prep.name(x)
x <- strsplit(x,' ')[[1]]
get.census.data(x)
```

To determine surname (last name) ordinal:
```r
x <- 'livingston III,  Mr. MICHAEL JOHN9'
x <- prep.name(x)
x <- strsplit(x,' ')[[1]]
cd <- get.census.data(x)
print(x)
determine.surname(cd)
```

To determine gender:
```r
x <- 'livingston III,  Mr. MICHAEL JOHN9'
x <- prep.name(x)
x <- strsplit(x,' ')[[1]]
cd <- get.census.data(x)
determine.gender(cd)
```

## Contributors

This package was adapted by Jesse Lecy. 

The original package by Michael Flanigan was called **Name-Parser**.

available at: https://github.com/mjfii/Name-Parser  


## Versioning

Initial release 2020-08-01
