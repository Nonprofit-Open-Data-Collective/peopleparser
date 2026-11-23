# Gender scoring and the census name table

Every parse returns a `gender` code (`M`, `F` or `U`) and a
`gender_confidence`. Both are estimates from how often the given names
are recorded for men and for women in U.S. Census name lists. This
article shows how the score is computed, what the confidence means, when
the parser falls back to a default, and where the census table comes
from.

## The score

[`determine_gender()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/determine_gender.md)
takes the census rows for the given-name tokens (the first name and any
middle names, never the surname), adds up their male and female counts,
and reports the larger side:

``` math

\text{confidence} = 100 \times \frac{\max(n_{male},\, n_{female})}{n_{male} + n_{female}}
```

rounded to one decimal place.

``` r
cd <- get_census_data(c("LESLIE"))
cd[, c("name", "male_value", "female_value")]
#>      name male_value female_value
#>    <char>      <num>        <num>
#> 1: LESLIE     116012       233858
determine_gender(cd)
#> [1] "F"    "66.8"
```

The confidence is the share of people with these names who have the
reported gender. It runs from 50 (an even split) to 100 (only one gender
recorded). It is not the probability that this particular person has
that gender, which also depends on their age and on the population the
record comes from.

``` r
show(c("JOHN SMITH", "MARY SMITH", "LESLIE SMITH", "PAT SMITH",
       "CHRIS JONES", "TAYLOR SWIFT"))
#>            raw salutation first_name middle_name suffix gender gender_confidence
#> 1   JOHN SMITH                  JOHN                         M              99.6
#> 2   MARY SMITH                  MARY                         F              99.7
#> 3 LESLIE SMITH                LESLIE                         F              66.8
#> 4    PAT SMITH                   PAT                         F              65.8
#> 5  CHRIS JONES                 CHRIS                         M              88.6
#> 6 TAYLOR SWIFT                TAYLOR                         M              65.4
```

Most first names in the table are strongly gendered. Of the 5163 first
names, the majority gender holds 95% or more of the count for most of
them:

``` r
fn <- census.names[census.names$first_name_value > 0, ]
share <- pmax(fn$male_value, fn$female_value) / (fn$male_value + fn$female_value)
table(cut(share, c(0.5, 0.8, 0.95, 1), include.lowest = TRUE,
          labels = c("50-80%", "80-95%", "95-100%")))
#> 
#>  50-80%  80-95% 95-100% 
#>      90      91    4982
```

### Middle names count too

The counts of all given-name tokens are pooled, so the middle name can
move the score. Because the counts are pooled rather than averaged, a
very common name outweighs a rare one, and two names of opposite gender
give a weak score whatever their order:

``` r
show(c("SARAH MAY WILSON", "JOHN MARY SMITH", "MARY JOHN SMITH"))
#>                raw salutation first_name middle_name suffix gender gender_confidence
#> 1 SARAH MAY WILSON                 SARAH         MAY             F               100
#> 2  JOHN MARY SMITH                  JOHN        MARY             M              53.9
#> 3  MARY JOHN SMITH                  MARY        JOHN             M              53.9
```

## When there is no evidence

When no given-name token is in the census (an initial, a rare name, or
no given name at all), the parser falls back:

| Situation | `gender` | `gender_confidence` |
|----|----|----|
| given names not in the census, no suffix | `U` | `50.0` |
| given names not in the census, with `JR`, `SR`, `II`, … | `M` | `50.0` |
| nothing left to parse | `U` | `0.0` |

The suffix rule reflects that generational suffixes are almost always
used by men. The 50.0 says that the call is a default, not evidence.

``` r
show(c("J SMITH", "J SMITH JR", "A J SMITH", "KYUN CHO", "SMITH JR"))
#>          raw salutation first_name middle_name suffix gender gender_confidence
#> 1    J SMITH                     J                         U              50.0
#> 2 J SMITH JR                     J                 JR      M              50.0
#> 3  A J SMITH                     A           J             U              50.0
#> 4   KYUN CHO                  KYUN                         U              50.0
#> 5   SMITH JR                                       JR      M              50.0
```

## Salutations

[`parse_name()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_name.md)
does not use the salutation for gender: `MR PAT SMITH` is scored from
`PAT` alone. If you need a salutation to override the census score, do
it after parsing:

``` r
d <- show(c("MR PAT SMITH", "MRS PAT SMITH", "DR PAT SMITH"))
d$gender_sal <- ifelse(d$salutation == "MR", "M",
                ifelse(d$salutation %in% c("MRS", "MS", "MISS"), "F", d$gender))
d
#>             raw salutation first_name middle_name suffix gender gender_confidence gender_sal
#> 1  MR PAT SMITH         MR        PAT                         F              65.8          M
#> 2 MRS PAT SMITH        MRS        PAT                         F              65.8          F
#> 3  DR PAT SMITH         DR        PAT                         F              65.8          F
```

The nickname functions do this already: in
[`nickname_lookup()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/nickname_lookup.md)
a gendered salutation (`MR`, `MRS`, `MS`, `MISS`) beats the census
score. See
[`vignette("canonical-first-names")`](https://nonprofit-open-data-collective.github.io/peopleparser/articles/canonical-first-names.md).

## Using the scores

`gender_confidence` is returned as text. Convert it before comparing:

``` r
d <- parse_names(c("JOHN SMITH", "LESLIE SMITH", "J SMITH", "CHRIS JONES"))
d$gender_confidence <- as.numeric(d$gender_confidence)
d$gender_80 <- ifelse(d$gender_confidence >= 80, d$gender, "U")
d[c("name", "gender", "gender_confidence", "gender_80")]
#>           name gender gender_confidence gender_80
#> 1   JOHN SMITH      M              99.6         M
#> 2 LESLIE SMITH      F              66.8         U
#> 3      J SMITH      U              50.0         U
#> 4  CHRIS JONES      M              88.6         M
```

A threshold of 80 (what
[`nickname_lookup()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/nickname_lookup.md)
uses) keeps most names and drops the ones that are close to even. For
counts of women and men in a population, summing the shares can be
better than counting hard calls, because it does not round every
`LESLIE` to female.

Keep in mind:

- The counts are for the whole U.S. population around 1990. Name use
  changes over time (`LESLIE` and `ASHLEY` were once mostly male names)
  and across countries, so the score fits some groups better than
  others.
- The census lists record only male and female. The scores say nothing
  about how people identify.
- Names missing from the list, many of them non-English given names, get
  no score at all.

## Where the census table comes from

`census.names` is a frozen copy bundled with the package in
`data/census.names.RData`. It is not downloaded or rebuilt when the
package is installed or used, and the package has no script that
rebuilds it. Its contents are unchanged since the package’s first commit
(August 2020; a 2026 refresh only recompressed the file), which adapted
the original **Name-Parser** package by Michael Flanigan; no record of
how it was built was kept.

The table itself shows what it was built from:

``` r
cn <- census.names
c(rows           = nrow(cn),
  male_names     = sum(cn$male_value > 0),
  female_names   = sum(cn$female_value > 0),
  first_names    = sum(cn$first_name_value > 0),
  surnames       = sum(cn$last_name_value > 0))
#>         rows   male_names female_names  first_names     surnames 
#>       164850         1219         4275         5163       162254
cn[cn$name %in% c("SMITH", "ALL OTHER NAMES"), ]
#> Key: <name>
#>               name male_value female_value first_name_value last_name_value
#>             <fctr>      <num>        <num>            <num>           <num>
#> 1: ALL OTHER NAMES          0            0                0        29312001
#> 2:           SMITH          0            0                0         2442977
```

- **Given names and gender:** 1,219 male and 4,275 female names, exactly
  the size of the Census Bureau’s 1990 first-name lists (from the 1990
  Post Enumeration Survey). Those lists publish percentages, so the
  counts here are the percentages scaled up to population totals.
  `first_name_value` is `male_value + female_value`.
- **Surnames:** 162,253 surnames with at least 100 people, plus a
  catch-all `ALL OTHER NAMES` row. That matches the 2010 Census surname
  file; `SMITH`’s count of 2,442,977 is the 2010 figure.

So the given-name side reflects the U.S. population of 1990 and the
surname side that of 2010. Neither is a birth-certificate count.

To update the table you would download newer files (for example, the
Social Security Administration’s baby-name counts by year and sex for
given names, and a later Census surname file), rebuild the same five
columns, key the table on `name` with
[`data.table::setkey()`](https://rdrr.io/pkg/data.table/man/setkey.html),
and save it with `usethis::use_data(census.names, overwrite = TRUE)`.
Adding a script for this to `data-raw/` would make the source
reproducible. Any change moves name-order and gender results, so rerun
the tests and compare the parses before and after.
