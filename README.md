# peopleparser

R package to convert a raw text version of an individual's name into a structured format.

The functions attempt to disambiguate proper name ordering (first, middle, and last), parse prefixes and suffixes, and assign gender based upon first names.


## Installation

```r
devtools::install_github( "Nonprofit-Open-Data-Collective/peopleparser" )
library( peopleparser )
```

## Use

The program takes raw text individual names as the input and returns a data frame with the name parsed into the component parts: 

* SALUTATION 
* FIRST_NAME 
* MIDDLE_NAME 
* LAST_NAME 
* SUFFIX 
* STATUS
* GENDER 
* GENDER_CONFIDENCE

The matching is done probabilistically based upon how often each token appears as a first name or a surname in U.S. Census Bureau name lists (the bundled `census.names` table, built from the 2020 Census first-name and surname lists).

Gender coding is similarly done probabilistically using the given names from the parsed string and the same Census data table.

With `add_nicknames = TRUE`, `parse_name()` and `parse_names()` also add each first name's formal names, nicknames and one canonical first name.

## Guides

* [Cleaning names: clutter, titles, credentials and suffixes](https://nonprofit-open-data-collective.github.io/peopleparser/articles/name-cleaning.html)
* [Name order and compound surnames](https://nonprofit-open-data-collective.github.io/peopleparser/articles/name-order.html)
* [Gender scoring and the census name table](https://nonprofit-open-data-collective.github.io/peopleparser/articles/gender-scoring.html)
* [Canonical first names, nicknames and gender](https://nonprofit-open-data-collective.github.io/peopleparser/articles/canonical-first-names.html)

`parse_name()` parses a single name and returns a one-row data frame. Set `sanitize = TRUE` when the input still contains punctuation, titles, or other clutter:

```r

x <- 'livingston III,  Mr. MICHAEL JOHN9'
parse_name( x, sanitize = TRUE )
#   salutation first_name middle_name  last_name suffix status gender gender_confidence
# 1         MR    MICHAEL        JOHN LIVINGSTON    III             M              99.6

x <- "THOMAS H VON KAMECKE"
parse_name( x, sanitize = TRUE )
#   salutation first_name middle_name   last_name suffix status gender gender_confidence
# 1               THOMAS           H VON-KAMECKE                    M              99.8

x <- c("Karen H Green", "ED MARKS", "MATTHEW BERSHADKER", "R Blincoe",
       "HAFER JR EDMUND L AIA", "Dr Leslie Smith", "THOMAS H VON KAMECKE")
parse_names(x)
                   name salutation first_name middle_name   last_name suffix status gender gender_confidence
1         Karen H Green                 KAREN           H       GREEN                    F               100
2              ED MARKS                    ED                   MARKS                    M               100
3    MATTHEW BERSHADKER               MATTHEW              BERSHADKER                    M              99.7
4             R Blincoe                     R                 BLINCOE                    U              50.0
5 HAFER JR EDMUND L AIA        AIA     EDMUND           L       HAFER     JR             M               100
6       Dr Leslie Smith         DR     LESLIE                   SMITH                    F              66.8
7  THOMAS H VON KAMECKE                THOMAS           H VON-KAMECKE                    M              99.8


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

The **parse_names()** function utilizes parallelization to speed up large jobs. 

```r
x <- get_example_names( n=1000 )
 
start_time <- Sys.time()
pn <- parse_names( x )
end_time <- Sys.time()

end_time - start_time
# Time difference of 8.7648 secs
```

## Examples

To parse a name:

```r
# returns a one-row data frame:
# salutation | first_name | middle_name | last_name | suffix | status | gender | gender_confidence
x <- 'livingston III,  Mr. MICHAEL JOHN9'
parse_name( x, sanitize = TRUE )
# or, for a vector of names returned as a data frame
parse_names(x)
```

To 'prepare' a name:
```r
x <- 'livingston III,  Mr. MICHAEL JOHN9'
prep_name(x)  
```

To get the census data:
```r
x <- 'livingston III,  Mr. MICHAEL JOHN9'
x <- prep_name(x)
x <- strsplit(x,' ')[[1]]
get_census_data(x)
```

To determine surname (last name) ordinal:
```r
x <- 'livingston III,  Mr. MICHAEL JOHN9'
x <- prep_name(x)
x <- strsplit(x,' ')[[1]]
cd <- get_census_data(x)
print(x)
determine_surname(cd)
```

To determine gender:
```r
x <- 'livingston III,  Mr. MICHAEL JOHN9'
x <- prep_name(x)
x <- strsplit(x,' ')[[1]]
cd <- get_census_data(x)
determine_gender(cd)
```

## Contributors

This package was adapted by Jesse Lecy. 

The original package by Michael Flanigan was called **Name-Parser**.

available at: https://github.com/mjfii/Name-Parser  


## Versioning

Version 0.1.0 (2026-11-23) is the first tagged release; see `NEWS.md`.
Development began 2020-08-01.
