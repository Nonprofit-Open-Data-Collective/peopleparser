# Look Up Census Name-Frequency Data for a Character Vector

Joins each element of a name vector against the
[census.names](https://nonprofit-open-data-collective.github.io/peopleparser/reference/census.names.md)
reference table to retrieve its male, female, first-name, and last-name
occurrence counts. The lookup uses a keyed binary-search join on
[census.names](https://nonprofit-open-data-collective.github.io/peopleparser/reference/census.names.md)
(which is keyed on `name`), so it stays fast even though the reference
table has ~165k rows.

## Usage

``` r
get_census_data(x)
```

## Arguments

- x:

  A character vector of name tokens (typically the output of
  [`prep_name()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/prep_name.md)
  split on spaces). Dashes are stripped before lookup because the census
  data stores compound names without them.

## Value

A `data.table` with one row per input token, keyed and sorted on
`ordinal` (the token's original position). Columns: `name`, `ordinal`,
`male_value`, `female_value`, `first_name_value`, `last_name_value`.
Tokens absent from the census table get zero counts.

## Examples

``` r
x <- "livingston III,  Mr. MICHAEL JOHN9"
x <- prep_name(x)
x <- strsplit(x, " ")[[1]]
get_census_data(x)
#> Key: <ordinal>
#>          name ordinal male_value female_value first_name_value last_name_value
#>        <char>   <int>      <num>        <num>            <num>           <num>
#> 1: LIVINGSTON       1        653          102              755           40605
#> 2:        III       2          0            0                0               0
#> 3:         MR       3          0            0                0               0
#> 4:    MICHAEL       4    3469434         7287          3476721           37760
#> 5:       JOHN       5    3118620         6503          3125123           37363
```
