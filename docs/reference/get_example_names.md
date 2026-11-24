# Build a test sample of names from IRS 990s

This function builds a test vector of up to 1000 names.

## Usage

``` r
get_example_names(n = 10)
```

## Arguments

- n:

  Size of the sample vector of names (maximum 1000).

## Examples

``` r
x <- get_example_names( n=10 )
pn <- parse_names( x )
head( pn )
#>                    name salutation first_name middle_name      last_name suffix
#> 1        Joseph S McCoy                JOSEPH           S          MCCOY       
#> 2 RHONDA BLANFORD-GREEN                RHONDA             BLANFORD-GREEN       
#> 3             TIM KITTS                   TIM                      KITTS       
#> 4             ADAM ROBE                  ADAM                       ROBE       
#> 5       CLAUDIA DAGGETT               CLAUDIA                    DAGGETT       
#> 6          JW CARPENTER                    JW                  CARPENTER       
#>   status gender gender_confidence
#> 1             M              99.9
#> 2             F              99.9
#> 3             M              99.7
#> 4             M              99.8
#> 5             F              99.8
#> 6             U              50.0

# micro-benchmark performance
x <- get_example_names( n=1000 )
start_time <- Sys.time()
pn <- parse_names( x )
end_time <- Sys.time()
end_time - start_time
#> Time difference of 0.695446 secs
```
