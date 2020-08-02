# peopleparser

R package to convert a raw text version of an individual name into a structured format and disambiguate first, last and titles.


### Installation

```r
devtools::install_github( "Nonprofit-Open-Data-Collective/peopleparser" )
library( peopleparser )
```

### Use

```r
x <- 'livingston III,  Mr. MICHAEL JOHN9'
parse.name(x)
# [1] "MR|III,|MICHAEL  JOHN|LIVINGSTON||M|99.6"
 
x <- "THOMAS H VON KAMECKE"
parse.name(x)
# [1] "|THOMAS|H|VON-KAMECKE||M|99.8"
 
x <- get_example_names( n=10 )
parse.names(x)

                 name salutation first_name middle_name last_name suffix gender gender_confidence
1       SCOTT BURGESS                 SCOTT               BURGESS             M              99.6
2         DAVID SYKES                 DAVID                 SYKES             M              99.7
3        JACKSON FRED                  FRED               JACKSON             M              99.6
4          DAN FARLEY                   DAN                FARLEY             M                99
5     DEBORAH HAMPTON               DEBORAH               HAMPTON             F               100
6  KATHLEEN HOLLISTER              KATHLEEN             HOLLISTER             F               100
7      CARYL JOHNSTON                 CARYL              JOHNSTON             F               100
8         John Mugler                  JOHN                MUGLER             M              99.6
9    ROBERT CLEVELAND                ROBERT             CLEVELAND             M              99.7
10       SARAH SHIKES                 SARAH                SHIKES             F               100

 head( census.names )
      name male_value female_value first_name_value last_name_value
1:     AAB          0            0                0             133
2:  AABERG          0            0                0             469
3:    AABY          0            0                0             220
4: AADLAND          0            0                0             374
5:  AAFEDT          0            0                0             138
6: AAGAARD          0            0                0             300


 
x <- get_example_names( n=1000 )
 
start_time <- Sys.time()
pn <- parse.names( x )
end_time <- Sys.time()
end_time - start_time
# Time difference of 10.45299 secs
```
