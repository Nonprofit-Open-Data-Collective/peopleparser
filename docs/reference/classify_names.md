# Classify Names as People, Organisations or Placeholders

Officer lists hold more than people's names: banks and companies serving
as trustees, notes such as `SEE SCHEDULE O`, and couples.
`classify_names()` sorts each entry into one of five types, so that only
people are matched as people.

## Usage

``` r
classify_names(x, threshold = NULL)
```

## Arguments

- x:

  A character vector of raw names.

- threshold:

  `NULL` (the default) for the thresholds above, or one number between 0
  and 1 for all names.

## Value

A `data.frame` with one row per input and columns `name` (the input),
`name_type` and `org_score` (the model's probability that the name is an
organisation, for a population with equal shares of people and
organisations).

## Details

- `"person"`: a person's name.

- `"organisation"`: an organisation (`PNC BANK NA`,
  `TEAMSTERS LOCAL 338`).

- `"person and organisation"`: a person's name followed by an
  organisation, usually an employer
  (`JAMES LUISI NORTH END COMMUNITY HC`). Parsing such a name usually
  still finds the person.

- `"several people"`: two or more people (`MICHAEL AND ASHLEY SMITH`).

- `"placeholder"`: a note instead of a name (`SEE SCHEDULE O`, `VACANT`,
  `NO COMPENSATED OFFICERS`), or nothing left after cleaning.

Placeholders and several people are found by rules. Organisations are
found by a model: each word gets a score from how much more often it
appears in organisation names than in people's names, and a logistic
regression combines those scores with how many words the name has and
how many are given names or surnames in
[census.names](https://nonprofit-open-data-collective.github.io/peopleparser/reference/census.names.md).
The model was trained on Form 990 Part VII names, 2009-2025: 982,000
filer names and 9.4 million names from the person-name field (see
`data-raw/name_type_model.R` and
[`vignette("name-types")`](https://nonprofit-open-data-collective.github.io/peopleparser/articles/name-types.md)).

A name is an organisation when `org_score` reaches `threshold`. The
default thresholds are stricter for names of one or two words (0.99)
than for longer names (0.95), because short organisation names
(`MUNROE EAGLES`) are hard to tell from people's names and most two-word
entries are people.

## Examples

``` r
classify_names(c("JOHN A SMITH", "PNC BANK NA", "SEE SCHEDULE O",
                 "MICHAEL AND ASHLEY SMITH", "TEAMSTERS LOCAL NO 338",
                 "JAMES LUISI NORTH END COMMUNITY HC"))
#>                                 name               name_type org_score
#> 1                       JOHN A SMITH                  person    0.0012
#> 2                        PNC BANK NA            organisation    0.9999
#> 3                     SEE SCHEDULE O             placeholder    0.0074
#> 4           MICHAEL AND ASHLEY SMITH          several people    0.0227
#> 5             TEAMSTERS LOCAL NO 338            organisation    0.9998
#> 6 JAMES LUISI NORTH END COMMUNITY HC person and organisation    0.9804
```
