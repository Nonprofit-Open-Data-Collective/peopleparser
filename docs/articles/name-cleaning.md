# Cleaning names: clutter, titles, credentials and suffixes

Names in administrative records rarely arrive clean. A Form 990 Part VII
list holds entries like `livingston III, Mr. MICHAEL JOHN9`,
`ROBERT NAGLE - SMFA BOARD OF` or `JANE DOE RN MA TERM ENDED`. Before
peopleparser can decide which token is the first name and which the
surname (see
[`vignette("name-order")`](https://nonprofit-open-data-collective.github.io/peopleparser/articles/name-order.md)),
it has to strip everything that is not a name. This article walks
through those cleaning steps in the order they run.

The examples parse a few names with
[`parse_names()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_names.md)
and show the columns that matter here as a table:

``` r
library(peopleparser)

# parse names and show the columns this article is about
show <- function( x ) {
  vars <- c( "name", "salutation", "first_name", "middle_name",
             "last_name", "suffix", "status" )
  parse_names( x )[ vars ] |> knitr::kable()
}
```

## The pipeline at a glance

    raw string
      |  sanitize_input()           (parse_names() does this for you;
      |    1. periods -> spaces       parse_name() only with sanitize = TRUE)
      |    2. upper case
      |    3. de_clutter()          drop tenure notes, schedule references, roles
      |    4. prep_name()           drop punctuation and digits, join compounds
      v
    tokens (split on spaces)
      |  parse_name()
      |    5. deglue_tokens()       MRWILLIAM -> MR WILLIAM, JRMD -> JR MD
      |       employer words        JOHN HEISER INSURANCE -> JOHN HEISER
      |    6. positional rules      which titles may be stripped *here*
      |    7. strip prefixes        -> salutation
      |    8. strip suffixes        -> suffix
      |    9. strip status words    -> status
      v
    name tokens -> name order and gender

``` r
x <- c( "livingston III,  Mr. MICHAEL JOHN9",
        "ROBERT NAGLE - SMFA BOARD OF",
        "JANE DOE RN MA TERM ENDED" )
show( x )
```

| name | salutation | first_name | middle_name | last_name | suffix | status |
|:---|:---|:---|:---|:---|:---|:---|
| livingston III, Mr. MICHAEL JOHN9 | MR | MICHAEL | JOHN | LIVINGSTON | III |  |
| ROBERT NAGLE - SMFA BOARD OF |  | ROBERT |  | NAGLE |  |  |
| JANE DOE RN MA TERM ENDED | RN_MA | JANE |  | DOE |  |  |

[`parse_names()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_names.md)
sanitizes the whole vector once.
[`parse_name()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_name.md)
assumes its input is already sanitized; pass `sanitize = TRUE` for raw
text.

## Step 3: removing clutter with `de_clutter()`

[`de_clutter()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/de_clutter.md)
is a list of regular expressions for noise that shows up after the name:
tenure notes, role descriptions, schedule references and date ranges.
Most patterns delete everything from the marker to the end of the
string.

``` r
x <- c( "ROBERT NAGLE - SMFA BOARD OF",
        "MARY JONES EXECUTIVE DIRECTOR",
        "JOHN SMITH SEE SCHEDULE O",
        "ANN LEE THROUGH 6/30",
        "MR AND MRS PATRICK VETERS" )

data.frame( raw = x, cleaned = de_clutter(x) ) |> knitr::kable()
```

| raw                           | cleaned        |
|:------------------------------|:---------------|
| ROBERT NAGLE - SMFA BOARD OF  | ROBERT NAGLE   |
| MARY JONES EXECUTIVE DIRECTOR | MARY JONES     |
| JOHN SMITH SEE SCHEDULE O     | JOHN SMITH     |
| ANN LEE THROUGH 6/30          | ANN LEE        |
| MR AND MRS PATRICK VETERS     | PATRICK VETERS |

A few markers are kept as a single word so that they can be reported in
the `status` column later instead of being lost: `AS OF ...` becomes
`ASOF`; `PAST`, `FORMER` and `OUTGOING` keep their own word; and
`STARTING`, `APPOINTED` and `ELECTED` keep their word but lose the date
after it.

``` r
x <- c( "JOHN SMITH AS OF 6/2019",
        "ANN LEE FORMER PRESIDENT",
        "DUANE LARSON STARTING 6-2022" )

data.frame( raw = x, cleaned = de_clutter(x) ) |> knitr::kable()
```

| raw                          | cleaned               |
|:-----------------------------|:----------------------|
| JOHN SMITH AS OF 6/2019      | JOHN SMITH ASOF       |
| ANN LEE FORMER PRESIDENT     | ANN LEE FORMER        |
| DUANE LARSON STARTING 6-2022 | DUANE LARSON STARTING |

A dash at the end of a word, followed by a space, is either half of a
double surname or the start of a note. When one word follows and it is
not a title or a note word, the two are joined as a double surname
(`KARA JAMES- JOHNSON` becomes `JAMES-JOHNSON`); the same holds after a
single word (`ADKINS- RICEHOUSE PAULA`). Otherwise the dash starts a
note and the rest is cut, as for `-`.

``` r
# the first two are double surnames, the last two start a note
x <- c( "KARA JAMES- JOHNSON",
        "ADKINS- RICEHOUSE PAULA",
        "JASON FRENN- MANAGING DIRECTOR",
        "RICK DIETZ- JAN THRU JUNE" )

data.frame( raw = x, cleaned = de_clutter(x) ) |> knitr::kable()
```

| raw                            | cleaned                |
|:-------------------------------|:-----------------------|
| KARA JAMES- JOHNSON            | KARA JAMES-JOHNSON     |
| ADKINS- RICEHOUSE PAULA        | ADKINS-RICEHOUSE PAULA |
| JASON FRENN- MANAGING DIRECTOR | JASON FRENN            |
| RICK DIETZ- JAN THRU JUNE      | RICK DIETZ             |

## Step 4: normalizing with `prep_name()`

[`prep_name()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/prep_name.md)
produces the token string the parser works on:

- periods become spaces, then everything is upper-cased;
- punctuation is dropped **except dashes**, which mark compound
  surnames;
- digits are dropped and runs of spaces collapse to one;
- abbreviations that periods split apart are re-joined: `PH D` to `PHD`,
  `ED D` to `EDD`, `DR PH` to `DRPH`, `EX OFFICIO` to `EXOFFICIO`,
  `NON VOTING` to `NONVOTING`, `VICE CHAIR` to `VICECHAIR`;
- surname particles are joined to the following word (`VON KAMECKE` to
  `VON-KAMECKE`, `ST CLAIR` to `ST-CLAIR`). Those rules are covered in
  [`vignette("name-order")`](https://nonprofit-open-data-collective.github.io/peopleparser/articles/name-order.md).

``` r
x <- c( "livingston III,  Mr. MICHAEL JOHN9",
        "Jane O'Brien-Smith, Ph.D.",
        "THOMAS H VON KAMECKE",
        "SEAN ST CLAIR, VICE CHAIR" )

data.frame( raw = x, prepped = prep_name(x) ) |> knitr::kable()
```

| raw                               | prepped                        |
|:----------------------------------|:-------------------------------|
| livingston III, Mr. MICHAEL JOHN9 | LIVINGSTON III MR MICHAEL JOHN |
| Jane O’Brien-Smith, Ph.D.         | JANE OBRIEN-SMITH PHD          |
| THOMAS H VON KAMECKE              | THOMAS H VON-KAMECKE           |
| SEAN ST CLAIR, VICE CHAIR         | SEAN ST-CLAIR VICECHAIR        |

The re-joins matter because the pieces are otherwise ambiguous: `ED` is
a given name, `VICE` is a surname, and `ST` on its own is in the prefix
list.

## Step 5: repairing glued tokens

Some records lose the space between a title and a name (`MRWILLIAM`) or
between two credentials (`JRMD`).
[`parse_name()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_name.md)
splits these back apart, but only when census evidence says the pieces
are real:

- **A title glued to a given name.** `MR`, `MRS`, `MS`, `MISS` or `DR`
  followed by a common census given name is split, unless the whole
  token is itself a census name. `MRWILLIAM` splits; `DREW` and `FRANK`
  do not.
- **Two fused credentials.** `JRMD` or `MDMPH` is split when both parts
  are known suffixes or credentials. This only applies from the third
  token on, so a leading given name is never split.
- **A stray initial glued to a surname** (`CWOOLFOLK`). This split is
  off by default because it cannot be told apart from a given name
  missing from the census (`TSHEPO`). Turn it on with
  `split_initials = TRUE` when you can check the results another way,
  for example against the same person in other years.

``` r
show( c("MRWILLIAM JONES", "JOHN SMITH JRMD", "DREW CAREY") )
```

| name            | salutation | first_name | middle_name | last_name | suffix | status |
|:----------------|:-----------|:-----------|:------------|:----------|:-------|:-------|
| MRWILLIAM JONES | MR         | WILLIAM    |             | JONES     |        |        |
| JOHN SMITH JRMD | MD         | JOHN       |             | SMITH     | JR     |        |
| DREW CAREY      |            | DREW       |             | CAREY     |        |        |

``` r

# off by default: split a stray initial from the surname
parse_name( "JOHN CWOOLFOLK", split_initials = TRUE ) |> knitr::kable()
```

| salutation | first_name | middle_name | last_name | suffix | status | gender | gender_confidence |
|:---|:---|:---|:---|:---|:---|:---|:---|
|  | JOHN | C | WOOLFOLK |  |  | M | 99.8 |

### An employer after the name

Insurance agents and company officers are often listed with their
employer: `JOHN HEISER INSURANCE`, `LISA PIERCE ALLSTATE INSURANCE CO`.
When an employer word (`INSURANCE`, `ASSURANCE`, `COMPANY`, `COMPANIES`,
`AGENCY`, `CORPORATION`, `CORP`, `INC`, `LLC`) is the third word or
later, the name keeps its given name and surname, plus any title or
suffix right after them, and the rest is dropped. `CO` followed by more
words is “care of” an employer and ends the name the same way.

``` r
x <- c( "JOHN HEISER INSURANCE",
        "LISA PIERCE ALLSTATE INSURANCE CO",
        "RANDY DENNIS DENNIS COMPANY",
        "DR JOHN SMITH JR STATE FARM INSURANCE",
        "CHAD COTTER CO BURNS MCDONELL" )
show( x )
```

| name | salutation | first_name | middle_name | last_name | suffix | status |
|:---|:---|:---|:---|:---|:---|:---|
| JOHN HEISER INSURANCE |  | JOHN |  | HEISER |  |  |
| LISA PIERCE ALLSTATE INSURANCE CO |  | LISA |  | PIERCE |  |  |
| RANDY DENNIS DENNIS COMPANY |  | RANDY |  | DENNIS |  |  |
| DR JOHN SMITH JR STATE FARM INSURANCE | DR | JOHN |  | SMITH | JR |  |
| CHAD COTTER CO BURNS MCDONELL |  | CHAD |  | COTTER |  |  |

### An organisation, then its representative

The order can also be reversed: the organisation first, then the person
who represents it (`PRUDENTIAL INSURANCE - KYLE SMITH`).
[`de_clutter()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/de_clutter.md)
keeps the person when the organisation ends in a clear organisation word
(`INSURANCE`, `INS`, `BANK`, `INC`, `LLC`, `CORPORATION`, `GROUP`,
`SERVICES`, …), and the rest looks like a person: two to four words, the
first a census given name or an initial.
[`classify_names()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/classify_names.md)
labels these entries `"person and organisation"`.

``` r
# the person after the organisation is kept
x <- c( "PRUDENTIAL INSURANCE - KYLE SMITH",
        "INDIANA INSURANCE CO JOSEPH YEAGER",
        "PLEXUS GROUP-ROGER HISER",
        "NY LIFE INSURANCE D WHEELER" )
show( x )
```

| name | salutation | first_name | middle_name | last_name | suffix | status |
|:---|:---|:---|:---|:---|:---|:---|
| PRUDENTIAL INSURANCE - KYLE SMITH |  | KYLE |  | SMITH |  |  |
| INDIANA INSURANCE CO JOSEPH YEAGER |  | JOSEPH |  | YEAGER |  |  |
| PLEXUS GROUP-ROGER HISER |  | ROGER |  | HISER |  |  |
| NY LIFE INSURANCE D WHEELER |  | D |  | WHEELER |  |  |

``` r

# no person after the organisation, so nothing changes
x <- c( "CITIZENS BANK AND TRUST",
        "COMERICA BANK - TRUST DIVISION" )
data.frame( raw = x, cleaned = de_clutter(x) ) |> knitr::kable()
```

| raw                            | cleaned                 |
|:-------------------------------|:------------------------|
| CITIZENS BANK AND TRUST        | CITIZENS BANK AND TRUST |
| COMERICA BANK - TRUST DIVISION | COMERICA BANK           |

## Steps 6-9: stripping titles, credentials, suffixes and status

### The removal lists

Three lists of tokens are removed from the name:

- `prx`, a few hundred titles, degrees, credentials, ranks,
  religious-order post-nominals and role words. Whatever is removed goes
  to `salutation`.
- `sfx`, the generational suffixes `JR`, `JUNIOR`, `SR`, `SENIOR`, `II`,
  `III`, `IV`. Removed tokens go to `suffix`.
- status words such as `RESIGNED`, `INTERIM`, `FORMER`, `PAST`,
  `DECEASED` and `ASOF`. Removed tokens go to `status`.

``` r
# number of titles and credentials, and the generational suffixes
length( prx )
#> [1] 266
sfx
#> [1] "JR"     "JUNIOR" "SR"     "SENIOR" "II"     "III"    "IV"
```

A token is removed wherever it sits in the name, not only at the front
or the end. When several tokens match, they are all removed and joined
with `_`:

``` r
show( c("DR JOHN SMITH MD PHD", "REV JANE DOE JR") )
```

| name                 | salutation | first_name | middle_name | last_name | suffix | status |
|:---------------------|:-----------|:-----------|:------------|:----------|:-------|:-------|
| DR JOHN SMITH MD PHD | DR_MD_PHD  | JOHN       |             | SMITH     |        |        |
| REV JANE DOE JR      | REV        | JANE       |             | DOE       | JR     |        |

[`known_titles()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/known_titles.md)
gives a label and a type for each token, which helps when you want to
keep the credentials rather than throw them away:

``` r
titles <- known_titles()

# how many tokens of each type
table( type = titles$type ) |>
  sort( decreasing = TRUE ) |>
  knitr::kable( col.names = c("Title type", "Tokens") )
```

| Title type                 | Tokens |
|:---------------------------|-------:|
| Professional Credential    |     84 |
| Academic Degree            |     57 |
| Organizational Role        |     32 |
| Military Rank              |     28 |
| Religious Title            |     24 |
| Religious Order            |     22 |
| Civic / Political Title    |     15 |
| Military Affiliation       |      9 |
| Personal Title             |      9 |
| Fraternal Office           |      5 |
| Military Status            |      4 |
| Geographic / Other         |      1 |
| Honorific / Nobiliary      |      1 |
| Other                      |      1 |
| Personal Name Abbreviation |      1 |
| Religious Honorific        |      1 |

``` r

# a few of the rows
subset( titles, abbr %in% c("RSM", "FACHE", "CFRE", "USNRET") ) |> knitr::kable()
```

| abbr | label | type |
|:---|:---|:---|
| RSM | Religious Sisters of Mercy | Religious Order |
| FACHE | Fellow, American College of Healthcare Executives | Professional Credential |
| CFRE | Certified Fund Raising Executive | Professional Credential |
| USNRET | U.S. Navy, retired | Military Status |

### Tokens that are both a title and a name

The hard part of cleaning is that many titles are also names. `BISHOP`
is a common surname, `MA` is a surname and a credential, `SJ` can be
initials, and `EARL` and `MAJOR` are names as well as titles. Stripping
these everywhere would destroy real names, so their removal depends on
where they sit.

| Rule | Tokens (examples) | Removed only when |
|----|----|----|
| Leading-only titles | `BISHOP`, `SHERIFF`, `CANTOR`, `DEACON`, `CAPTAIN`, `MOTHER`, `BROTHER`, `IMAM`, `MOST`, `SIR`, `DAME`, `CHIEF`, `COUNCILMAN`, `CORPORAL`, `REP`, `CHAPLAIN` | they are the first token and two or more tokens follow |
| Trailing-only titles | `SJ`, `CISA`, `OP`, `SC`, `DD`, and role words: `PRESIDENT`, `CHAIR`, `SECRETARY`, `TREASURER`, `TRUSTEE`, `VICECHAIR`, `MANAGER`, `FOUNDER`, `CONTROLLER`, `MANAGING`, `DIR` | they sit in the run of known tokens at the end of the name, with at least two tokens before them |
| Ambiguous credentials | `MA`, `BA`, `AB`, `NP`, `PT`, `DC`, `ND`, `RM`, `PM`, `APR`, … | they sit in that trailing run **and** the run also holds an unambiguous credential; or, alone at the end after two name words, they are not census names (`CAROL RUSSELL NP`) or follow a strong surname (`JOHN BURKE MA`); or they lead the name before a strong given name and are not census names (`DC DAVID BEER`) |
| Tenure words | `TERM`, `ENDED`, `JOINED`, `SINCE`, `EMERITUS`, `NONVOTING`, `STARTING`, `APPOINTED`, … | they sit in that trailing run; they go to `status` |
| Unknown trailing credentials | `NMF`, `FAAFP`, `NEA-BC`, `UHC`, and over a thousand more learned from Part VII names | they end the name after a census surname or another credential, are not census names, and are on the learned list or look like a code (2-5 letters, at most one vowel); at least two name words stay |

``` r
x <- c( "BISHOP JOHN SMITH",       "JOHN BISHOP",
        "JANE DOE RN MA",          "MA LIN",
        "LARRY BLACK SECRETARY",
        "KENT CASHELL TERM ENDED",
        "ANDREA M GORDON NMF",     "ANTHONY F CHONG MD FAAFP" )
show( x )
```

| name | salutation | first_name | middle_name | last_name | suffix | status |
|:---|:---|:---|:---|:---|:---|:---|
| BISHOP JOHN SMITH | BISHOP | JOHN |  | SMITH |  |  |
| JOHN BISHOP |  | JOHN |  | BISHOP |  |  |
| JANE DOE RN MA | RN_MA | JANE |  | DOE |  |  |
| MA LIN |  | MA |  | LIN |  |  |
| LARRY BLACK SECRETARY | SECRETARY | LARRY |  | BLACK |  |  |
| KENT CASHELL TERM ENDED |  | KENT |  | CASHELL |  |  |
| ANDREA M GORDON NMF | NMF | ANDREA | M | GORDON |  |  |
| ANTHONY F CHONG MD FAAFP | MD_FAAFP | ANTHONY | F | CHONG |  |  |

`JOHN BISHOP` keeps its surname because `BISHOP` is not leading.
`MA LIN` keeps `MA` because it is not in a trailing run with a real
credential, while `JANE DOE RN MA` loses it because `RN` vouches for it.

The tenure words overlap with
[`de_clutter()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/de_clutter.md).
On sanitized input (as above, and always in
[`parse_names()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_names.md)),
[`de_clutter()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/de_clutter.md)
has already cut `TERM ENDED`, so `status` is empty. The tenure-word rule
matters for input that skips sanitizing:

``` r
# not sanitized, so TERM ENDED is still there for the tenure-word rule
p <- parse_name( "KENT CASHELL TERM ENDED" )
p[ c("first_name", "last_name", "status") ] |> knitr::kable()
```

| first_name | last_name | status     |
|:-----------|:----------|:-----------|
| KENT       | CASHELL   | TERM_ENDED |

### Putting back a name that was stripped

A last safety net catches titles that are also given names. If stripping
leaves no first name, and the removed token is a census given name (or
`JD` or `ED`), the token is restored. Its original position decides its
role: a leading token becomes the first name, a trailing one the
surname. Ranks and offices (`GEN`, `COL`, `ADM`, `SGT`, `GOV`, `SEN`,
`HON`, `REV`, `SIR`) are never restored, although some are rare given
names in the 2020 census, so `GEN PERRIN` keeps `GEN` as the title.

``` r
x <- c( "EARL FAHNESTOCK", "TOM MAJOR",
        "GEN PERRIN",      "COL RET CLARENCE MAXWELL" )
show( x )
```

| name | salutation | first_name | middle_name | last_name | suffix | status |
|:---|:---|:---|:---|:---|:---|:---|
| EARL FAHNESTOCK |  | EARL |  | FAHNESTOCK |  |  |
| TOM MAJOR |  | TOM |  | MAJOR |  |  |
| GEN PERRIN | GEN |  |  | PERRIN |  |  |
| COL RET CLARENCE MAXWELL | COL | CLARENCE |  | MAXWELL |  |  |

## Using your own lists

[`parse_name()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_name.md)
and
[`parse_names()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_names.md)
take `prefixes` and `suffixes` arguments. Extend the defaults rather
than replace them, so the built-in credentials are still removed:

``` r
x    <- "JANE DOE CFRE BOARDCHAIR"
vars <- c( "salutation", "last_name" )

# the default list plus one more word
my_prx <- c( prx, "BOARDCHAIR" )

rbind(
  default  = parse_name( x )[ vars ],
  extended = parse_name( x, prefixes = my_prx )[ vars ]
) |> knitr::kable()
```

|          | salutation      | last_name |
|:---------|:----------------|:----------|
| default  | CFRE_BOARDCHAIR | DOE       |
| extended | CFRE_BOARDCHAIR | DOE       |

The position rules (leading-only, trailing-only, ambiguous) use fixed
internal lists and apply on top of whatever you pass.

## Limits

- The `salutation` column mixes honorifics (`MR`), degrees (`PHD`) and
  roles (`SECRETARY`). Use
  [`known_titles()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/known_titles.md)
  to sort them by type.
- [`de_clutter()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/de_clutter.md)
  cuts at the first marker it finds, so a surname that is also a marker
  word in the middle of a name (`JOHN FROM SMITH`) loses what follows.
- A credential that is not in `prx`, not on the learned list and does
  not look like a code can still survive into the name, often as the
  last name. The lists were built from the tokens that leaked on Form
  990 Part VII names (`data-raw/SUFFIX-GAPS-PART7.md`,
  `data-raw/trailing_credentials.R`), so they fit that source best.
