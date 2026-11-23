# Frequency of name occurrence on US birth certificates.

A dataset containing names cross-tabbed by whether they are listed as
first or last names in the US Census.

## Usage

``` r
census.names
```

## Format

A
[data.table::data.table](https://rdrr.io/pkg/data.table/man/data.table.html)
with 164,850 rows and 5 variables, keyed on `name`:

- name:

  name as listed on US birth certificates

- male_value:

  count of times the name is listed for a male

- female_value:

  count of times the name is listed for a female

- first_name_value:

  count of times the name appears in the first-name position

- last_name_value:

  count of times the name appears in the last-name position

## Source

<https://www.census.gov/en.html>
