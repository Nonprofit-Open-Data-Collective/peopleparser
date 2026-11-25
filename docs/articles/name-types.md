# People, organisations and run-together names

Officer and board lists hold more than people’s names. A bank serves as
a foundation’s trustee, a filer writes `SEE SCHEDULE O` where a name
should go, a couple is listed on one line, or a name is typed with no
space between the surname and the given name. This article covers two
optional tools for these cases:

- [`classify_names()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/classify_names.md)
  labels each entry as a person, an organisation, a person and an
  organisation, several people, or a placeholder;
- [`split_run_together()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/split_run_together.md)
  splits a surname and given name written as one word.

Neither runs unless asked.
[`parse_names()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_names.md)
turns them on with `classify = TRUE` and `split_run_together = TRUE`.

## How common these cases are

Counts on the person-name field of Form 990 Part VII, 2009-2025 (60.8
million rows, 9.5 million distinct names):

| Entry | Share of rows | Examples |
|----|----|----|
| A person’s name | about 99.5% | `JOHN A SMITH` |
| A person with a date or note | about 0.3% | `KAREN JONES EXP 2019` |
| An organisation | about 0.05% | `PNC BANK NA`, `TEAMSTERS LOCAL NO 338` |
| A placeholder | about 0.05% | `SEE SCHEDULE O`, `VACANT` |
| Several people | about 0.02% | `MICHAEL AND ASHLEY SMITH` |
| A surname and given name run together | about 0.01% | `KramerKenneth`, `MURPHYSANDRA` |

The shares are small, but these entries are concentrated: organisations
appear again and again (`THE BANK OF NEW YORK MELLON` is listed as
trustee 939 times), and every one of them, parsed as a person, is a
false match waiting to happen.

## Classifying names

``` r
x <- c( "JOHN A SMITH",             "PNC BANK NA",
        "TEAMSTERS LOCAL NO 338",   "BNY MELLON",
        "SEE SCHEDULE O",           "VACANT",
        "MICHAEL AND ASHLEY SMITH", "MARY SHURTS - LHS INC",
        "LARRY CHURCH",             "SEE MOUA" )

classify_names( x ) |> knitr::kable()
```

| name                     | name_type               | org_score |
|:-------------------------|:------------------------|----------:|
| JOHN A SMITH             | person                  |    0.0012 |
| PNC BANK NA              | organisation            |    0.9999 |
| TEAMSTERS LOCAL NO 338   | organisation            |    0.9998 |
| BNY MELLON               | organisation            |    0.0412 |
| SEE SCHEDULE O           | placeholder             |    0.0074 |
| VACANT                   | placeholder             |    0.0193 |
| MICHAEL AND ASHLEY SMITH | several people          |    0.0227 |
| MARY SHURTS - LHS INC    | person and organisation |    0.9802 |
| LARRY CHURCH             | person                  |    0.0146 |
| SEE MOUA                 | person                  |    0.0004 |

- **Placeholders** are found by rules: notes such as `SEE SCHEDULE O`,
  `NONE`, `VACANT`, `NO COMPENSATED OFFICERS`, or nothing left after
  cleaning. `SEE` followed by a name (`SEE MOUA`) is a person: SEE is
  also a given name.
- **Several people** are found by `AND` or `&` with a given name on at
  least one side, or by `AND` in a three-word or longer name that is not
  an organisation.
- **Organisations** are found by a model (next section), plus a short
  list of institutions that serve as trustees under names with no
  organisation word, such as `BNY MELLON` and `WELLS FARGO`. The list
  holds names ticked as institutional trustee at five or more
  organisations, on at least 80% of their organisations and rows.
- **A person and an organisation** is an organisation whose first two
  words are a given name and a surname (`MARY SHURTS - LHS INC`, an
  employer after the name). Organisations named after a person
  (`KURT SUZUKI FAMILY FOUNDATION`) stay organisations, unless a dash
  separates the parts. An organisation followed by its representative
  (`PRUDENTIAL INSURANCE - KYLE SMITH`) is also a person and an
  organisation.
  [`parse_names()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_names.md)
  still finds the person in most of these: the part after a dash is cut,
  and from an employer word such as `INSURANCE` or `COMPANY` on, the
  rest is dropped (`JOHN HEISER INSURANCE` gives `JOHN HEISER`), and a
  person after an organisation is kept (`KYLE SMITH`; see
  [`vignette("name-cleaning")`](https://nonprofit-open-data-collective.github.io/peopleparser/articles/name-cleaning.md)).

`parse_names(x, classify = TRUE)` adds the `name_type` and `org_score`
columns to the parsed names, so the non-people can be set aside:

``` r
# parse and classify in one step
p <- parse_names( x, classify = TRUE )
p[ , c("name", "first_name", "last_name", "name_type") ] |> knitr::kable()
```

| name                     | first_name | last_name | name_type               |
|:-------------------------|:-----------|:----------|:------------------------|
| JOHN A SMITH             | JOHN       | SMITH     | person                  |
| PNC BANK NA              | PNC        | BANK-NA   | organisation            |
| TEAMSTERS LOCAL NO 338   | TEAMSTERS  | LOCAL-NO  | organisation            |
| BNY MELLON               | BNY        | MELLON    | organisation            |
| SEE SCHEDULE O           |            |           | placeholder             |
| VACANT                   |            | VACANT    | placeholder             |
| MICHAEL AND ASHLEY SMITH | MICHAEL    | SMITH     | several people          |
| MARY SHURTS - LHS INC    | MARY       | SHURTS    | person and organisation |
| LARRY CHURCH             | LARRY      | CHURCH    | person                  |
| SEE MOUA                 | SEE        | MOUA      | person                  |

### The organisation model

Each word gets a score: the log of how much more often it appears in
organisation names than in people’s names. `BANK`, `LODGE` and `LLC`
score high; `JOHN` and `SMITH` score low. A logistic regression combines
the word scores with the number of words, the share of words that are
given names or surnames in `census.names`, and whether the name starts
with a given name followed by a surname. `org_score` is the model’s
probability that the name is an organisation.

The model was trained on Form 990 Part VII names, 2009-2025:

- organisations: 982,000 filers’ own names, plus person-field names with
  a legal-form word (`INC`, `LLC`, `BANK`) that do not start with a
  person’s name;
- people: the other 9.4 million distinct names in the person-name field.

The word scores come from two thirds of the names, and the regression
was fit and tested on the rest. On the held-out names (AUC 0.9996):

| Words in the name | Organisations found | People flagged as organisations |
|-------------------|---------------------|---------------------------------|
| 1                 | 6%                  | 1.3%                            |
| 2                 | 77%                 | 0.01%                           |
| 3                 | 98%                 | 0.10%                           |
| 4 or more         | 99%                 | 0.6%                            |

Names of one or two words need `org_score` of at least 0.99 to count as
an organisation, longer names 0.95, because most short entries are
people and short organisation names (`MUNROE EAGLES`) are hard to tell
apart from people’s names. Pass `threshold =` to use one cut-off for all
names.

Many of the “people flagged” in the table are not people either: the
person-name field also holds unlabelled organisations and notes. In a
random sample of flagged names, about one in ten was a person with no
organisation in the entry (`DAWSON HER MANY HORSES`); the rest were
organisations, placeholders, or a person with an employer.

The training and test code is in `data-raw/name_type_model.R`, and the
checks in this article in `data-raw/name_type_eval.R`.

### Limits

- An organisation written as a person’s name (`PAULA MILLER` for a trust
  officer, or a small business called by its owner’s name) is a person.
- Short organisation names without organisation words
  (`CLAY ELEMENTARY`, `LAZY LADY`) are often missed.
- People whose names are all rare words (`DAWSON HER MANY HORSES`) can
  be scored as organisations.
- A note in the middle of an entry, rather than at the end, can push a
  person’s name toward organisation.

## Splitting run-together names

``` r
x <- c( "KramerKenneth", "LedbetterJennifer A",
        "MURPHYSANDRA",  "KLINESUZANNE",
        "McDonald",      "LaToya Jones",
        "JOHN MARKWALD", "MARKWALD J" )

data.frame( raw = x, split = split_run_together(x) ) |> knitr::kable()
```

| raw                 | split                |
|:--------------------|:---------------------|
| KramerKenneth       | Kramer Kenneth       |
| LedbetterJennifer A | Ledbetter Jennifer A |
| MURPHYSANDRA        | MURPHY SANDRA        |
| KLINESUZANNE        | KLINE SUZANNE        |
| McDonald            | McDonald             |
| LaToya Jones        | LaToya Jones         |
| JOHN MARKWALD       | JOHN MARKWALD        |
| MARKWALD J          | MARKWALD J           |

A word is split only when the whole word is not a census name and the
two parts are a strong surname and a strong given name:

- **With a capital inside the word** (`KramerKenneth`), at the capital.
  Words that start with a surname particle (`McDonald`, `MacArthur`,
  `LaToya`, `DeShawn`, `VanDyke`) are not split there.
- **In all capitals** (`MURPHYSANDRA`), only when the word is the only
  word of two or more letters in the name, has eight or more letters,
  and splits into parts of four or more letters with stricter census
  evidence. Real surnames that look like two names (`MARKWALD`,
  `PEARLSTONE`) recur across many different names in Form 990 filings,
  so the 214 such words are never split.

The parser’s order rules then decide which part is the surname:

``` r
x    <- c( "LedbetterJennifer A", "KramerKenneth", "MURPHYSANDRA" )
vars <- c( "name", "first_name", "middle_name", "last_name" )

parse_names( x, split_run_together = TRUE )[ , vars ] |> knitr::kable()
```

| name                | first_name | middle_name | last_name |
|:--------------------|:-----------|:------------|:----------|
| LedbetterJennifer A | JENNIFER   | A           | LEDBETTER |
| KramerKenneth       | KENNETH    |             | KRAMER    |
| MURPHYSANDRA        | SANDRA     |             | MURPHY    |

On the Part VII names, the capital-letter rule splits 2,014 distinct
words (4,524 rows) and the all-capitals rule 1,093 (2,131 rows). In
random samples of 40, about 37 and 39 splits were right. The errors are
given names or surnames with an inner capital (`ChaMira`, `RiverWind`)
and rare surnames that are two names (`M HEADERICK` becomes
`HEAD ERICK`).
