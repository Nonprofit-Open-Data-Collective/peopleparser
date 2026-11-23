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
#> 1: LESLIE      52838       237654
determine_gender(cd)
#> [1] "F"    "81.8"
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
#> 1   JOHN SMITH                  JOHN                         M              99.8
#> 2   MARY SMITH                  MARY                         F              99.8
#> 3 LESLIE SMITH                LESLIE                         F              81.8
#> 4    PAT SMITH                   PAT                         F              59.5
#> 5  CHRIS JONES                 CHRIS                         M              94.4
#> 6 TAYLOR SWIFT                TAYLOR                         F              75.5
```

Most first names in the table are strongly gendered. Of the 53616 first
names, the majority gender holds 95% or more of the count for most of
them:

``` r
fn <- census.names[census.names$first_name_value > 0, ]
share <- pmax(fn$male_value, fn$female_value) / (fn$male_value + fn$female_value)
table(cut(share, c(0.5, 0.8, 0.95, 1), include.lowest = TRUE,
          labels = c("50-80%", "80-95%", "95-100%")))
#> 
#>  50-80%  80-95% 95-100% 
#>    7454    9093   37069
```

### Middle names count too

The counts of all given-name tokens are pooled, so the middle name can
move the score. Because the counts are pooled rather than averaged, a
very common name outweighs a rare one, and two names of opposite gender
give a weak score whatever their order:

``` r
show(c("SARAH MAY WILSON", "JOHN MARY SMITH", "MARY JOHN SMITH"))
#>                raw salutation first_name middle_name suffix gender gender_confidence
#> 1 SARAH MAY WILSON                 SARAH         MAY             F              99.8
#> 2  JOHN MARY SMITH                  JOHN        MARY             M              63.8
#> 3  MARY JOHN SMITH                  MARY        JOHN             M              63.8
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
show(c("J SMITH", "J SMITH JR", "A J SMITH", "TSHEPO CHO", "SMITH JR"))
#>          raw salutation first_name middle_name suffix gender gender_confidence
#> 1    J SMITH                     J                         U              50.0
#> 2 J SMITH JR                     J                 JR      M              50.0
#> 3  A J SMITH                     A           J             U              50.0
#> 4 TSHEPO CHO                TSHEPO                         U              50.0
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
#> 1  MR PAT SMITH         MR        PAT                         F              59.5          M
#> 2 MRS PAT SMITH        MRS        PAT                         F              59.5          F
#> 3  DR PAT SMITH         DR        PAT                         F              59.5          F
```

The nickname functions do this already: in
[`nickname_lookup()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/nickname_lookup.md)
a gendered salutation (`MR`, `MRS`, `MS`, `MISS`) beats the census
score. See
[`vignette("canonical-first-names")`](https://nonprofit-open-data-collective.github.io/peopleparser/articles/canonical-first-names.md).

## Using the scores

`gender_confidence` is returned as text. Convert it before comparing:

``` r
d <- parse_names(c("JOHN SMITH", "PAT SMITH", "J SMITH", "CHRIS JONES"))
d$gender_confidence <- as.numeric(d$gender_confidence)
d$gender_80 <- ifelse(d$gender_confidence >= 80, d$gender, "U")
d[c("name", "gender", "gender_confidence", "gender_80")]
#>          name gender gender_confidence gender_80
#> 1  JOHN SMITH      M              99.8         M
#> 2   PAT SMITH      F              59.5         U
#> 3     J SMITH      U              50.0         U
#> 4 CHRIS JONES      M              94.4         M
```

A threshold of 80 (what
[`nickname_lookup()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/nickname_lookup.md)
uses) keeps most names and drops the ones that are close to even. For
counts of women and men in a population, summing the shares can be
better than counting hard calls, because it does not round every `PAT`
to female.

Keep in mind:

- The counts are for the whole U.S. population in 2020, children
  included. Name use changes over time (`LESLIE` and `ASHLEY` were once
  mostly male names; `TAYLOR` and `RILEY` have become mostly female) and
  across countries, so the score fits some groups better than others.
- The census lists record only male and female. The scores say nothing
  about how people identify.
- Names missing from the list, many of them non-English given names, get
  no score at all.

## Where the census table comes from

`census.names` is bundled with the package in `data/census.names.rda`.
It is not downloaded when the package is installed or used. It is built
by `data-raw/census_names.R` from the Census Bureau’s 2020 name release,
*Frequently Occurring First Names and Last Names from the 2020 Census*
(revised April 2026):

``` r
cn <- census.names
c(rows           = nrow(cn),
  male_names     = sum(cn$male_value > 0),
  female_names   = sum(cn$female_value > 0),
  first_names    = sum(cn$first_name_value > 0),
  surnames       = sum(cn$last_name_value > 0))
#>         rows   male_names female_names  first_names     surnames 
#>       195311        47089        51475        53616       156622
cn[cn$name %in% c("SMITH", "ALL OTHER NAMES"), ]
#> Key: <name>
#>               name male_value female_value first_name_value last_name_value
#>             <fctr>      <num>        <num>            <num>           <num>
#> 1: ALL OTHER NAMES    7768920     11025786         18794706        36257637
#> 2:           SMITH       4102          897             4999         2369644
```

- **Given names and gender:** every first name held by 91 or more people
  in the 2020 Census, with the count of people recorded male and female.
  `first_name_value` is `male_value + female_value`.
- **Surnames:** every surname held by 92 or more people, plus a
  catch-all `ALL OTHER NAMES` row (which no single name token matches).

**Earlier table.** Until November 2026 the package shipped a table built
from the 1990 first-name lists (1,219 male and 4,275 female names,
published as percentages and scaled to counts) and the 2010 surname
file. The 2020 lists hold ten times as many given names, so far fewer
names get no gender. On a sample of 9,608 Form 990 Part VII names, the
2020 table:

- matched the gender implied by an `MR`, `MRS` or `MS` salutation in 86%
  of cases, against 79%;
- left 227 names with unknown gender, against 727;
- kept the written first word as the first name in 96.3% of plain two-
  and three-word names, against 95.4%.

**Refreshing the table.** When the Bureau publishes new lists, update
the file names in `data-raw/census_names.R` and run it from the package
root. It downloads the files, records their sizes and SHA-256 hashes in
`data-raw/census-names-src.csv`, rebuilds the five columns, and prints a
comparison with the bundled table: size, names whose main role (first
name or surname) changes, and names whose majority gender flips. Set
`CENSUS_NAMES_SAVE=TRUE` to overwrite the bundled table, then rerun the
tests and compare parses before and after, since any change moves
name-order and gender results.
