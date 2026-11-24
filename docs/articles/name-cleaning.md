# Cleaning names: clutter, titles, credentials and suffixes

Names in administrative records rarely arrive clean. A Form 990 Part VII
list holds entries like `livingston III, Mr. MICHAEL JOHN9`,
`ROBERT NAGLE - SMFA BOARD OF` or `JANE DOE RN MA TERM ENDED`. Before
peopleparser can decide which token is the first name and which the
surname (see
[`vignette("name-order")`](https://nonprofit-open-data-collective.github.io/peopleparser/articles/name-order.md)),
it has to strip everything that is not a name. This article walks
through those cleaning steps in the order they run.

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
      |    6. positional rules      which titles may be stripped *here*
      |    7. strip prefixes        -> salutation
      |    8. strip suffixes        -> suffix
      |    9. strip status words    -> status
      v
    name tokens -> name order and gender

``` r
show(c("livingston III,  Mr. MICHAEL JOHN9",
       "ROBERT NAGLE - SMFA BOARD OF",
       "JANE DOE RN MA TERM ENDED"))
#>                                  raw salutation first_name middle_name  last_name suffix status
#> 1 livingston III,  Mr. MICHAEL JOHN9         MR    MICHAEL        JOHN LIVINGSTON    III       
#> 2       ROBERT NAGLE - SMFA BOARD OF                ROBERT                  NAGLE              
#> 3          JANE DOE RN MA TERM ENDED      RN_MA       JANE                    DOE
```

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
x <- c("ROBERT NAGLE - SMFA BOARD OF",
       "MARY JONES EXECUTIVE DIRECTOR",
       "JOHN SMITH SEE SCHEDULE O",
       "ANN LEE THROUGH 6/30",
       "MR AND MRS PATRICK VETERS")
data.frame(raw = x, cleaned = de_clutter(x))
#>                             raw         cleaned
#> 1  ROBERT NAGLE - SMFA BOARD OF    ROBERT NAGLE
#> 2 MARY JONES EXECUTIVE DIRECTOR      MARY JONES
#> 3     JOHN SMITH SEE SCHEDULE O     JOHN SMITH 
#> 4          ANN LEE THROUGH 6/30         ANN LEE
#> 5     MR AND MRS PATRICK VETERS  PATRICK VETERS
```

A few markers are kept as a single word so that they can be reported in
the `status` column later instead of being lost: `AS OF ...` becomes
`ASOF`, and `PAST`, `FORMER` and `OUTGOING` keep their own word.

``` r
de_clutter(c("JOHN SMITH AS OF 6/2019", "ANN LEE FORMER PRESIDENT"))
#> [1] "JOHN SMITH ASOF" "ANN LEE FORMER"
```

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
prep_name(c("livingston III,  Mr. MICHAEL JOHN9",
            "Jane O'Brien-Smith, Ph.D.",
            "THOMAS H VON KAMECKE",
            "SEAN ST CLAIR, VICE CHAIR"))
#> [1] "LIVINGSTON III MR MICHAEL JOHN" "JANE OBRIEN-SMITH PHD"         
#> [3] "THOMAS H VON-KAMECKE"           "SEAN ST-CLAIR VICECHAIR"
```

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
show(c("MRWILLIAM JONES", "JOHN SMITH JRMD", "DREW CAREY"))
#>               raw salutation first_name middle_name last_name suffix status
#> 1 MRWILLIAM JONES         MR    WILLIAM                 JONES              
#> 2 JOHN SMITH JRMD         MD       JOHN                 SMITH     JR       
#> 3      DREW CAREY                  DREW                 CAREY
parse_name("JOHN CWOOLFOLK", split_initials = TRUE)
#>   salutation first_name middle_name last_name suffix status gender gender_confidence
#> 1                  JOHN           C  WOOLFOLK                    M              99.8
```

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
length(prx)
#> [1] 266
sfx
#> [1] "JR"     "JUNIOR" "SR"     "SENIOR" "II"     "III"    "IV"
```

A token is removed wherever it sits in the name, not only at the front
or the end. When several tokens match, they are all removed and joined
with `_`:

``` r
show(c("DR JOHN SMITH MD PHD", "REV JANE DOE JR"))
#>                    raw salutation first_name middle_name last_name suffix status
#> 1 DR JOHN SMITH MD PHD  DR_MD_PHD       JOHN                 SMITH              
#> 2      REV JANE DOE JR        REV       JANE                   DOE     JR
```

[`known_titles()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/known_titles.md)
gives a label and a type for each token, which helps when you want to
keep the credentials rather than throw them away:

``` r
titles <- known_titles()
table(titles$type)
#> 
#>            Academic Degree    Civic / Political Title           Fraternal Office 
#>                         57                         15                          5 
#>         Geographic / Other      Honorific / Nobiliary       Military Affiliation 
#>                          1                          1                          9 
#>              Military Rank            Military Status        Organizational Role 
#>                         28                          4                         32 
#>                      Other Personal Name Abbreviation             Personal Title 
#>                          1                          1                          9 
#>    Professional Credential        Religious Honorific            Religious Order 
#>                         84                          1                         22 
#>            Religious Title 
#>                         24
subset(titles, abbr %in% c("RSM", "FACHE", "CFRE", "USNRET"))
#> # A tibble: 4 × 3
#>   abbr   label                                             type                   
#>   <chr>  <chr>                                             <chr>                  
#> 1 RSM    Religious Sisters of Mercy                        Religious Order        
#> 2 FACHE  Fellow, American College of Healthcare Executives Professional Credential
#> 3 CFRE   Certified Fund Raising Executive                  Professional Credential
#> 4 USNRET U.S. Navy, retired                                Military Status
```

### Tokens that are both a title and a name

The hard part of cleaning is that many titles are also names. `BISHOP`
is a common surname, `MA` is a surname and a credential, `SJ` can be
initials, and `EARL` and `MAJOR` are names as well as titles. Stripping
these everywhere would destroy real names, so their removal depends on
where they sit.

| Rule | Tokens (examples) | Removed only when |
|----|----|----|
| Leading-only titles | `BISHOP`, `SHERIFF`, `CANTOR`, `DEACON`, `CAPTAIN`, `MOTHER`, `BROTHER`, `IMAM`, `MOST` | they are the first token and two or more tokens follow |
| Trailing-only titles | `SJ`, `CISA`, `OP`, `SC`, `DD`, and role words: `PRESIDENT`, `CHAIR`, `SECRETARY`, `TREASURER`, `TRUSTEE`, `VICECHAIR` | they sit in the run of known tokens at the end of the name, with at least two tokens before them |
| Ambiguous credentials | `MA`, `BA`, `AB`, `NP`, `PT`, `DC`, `ND`, `RM`, `PM`, `APR`, … | they sit in that trailing run **and** the run also holds an unambiguous credential |
| Tenure words | `TERM`, `ENDED`, `JOINED`, `SINCE`, `EMERITUS`, `NONVOTING`, … | they sit in that trailing run; they go to `status` |

``` r
show(c("BISHOP JOHN SMITH", "JOHN BISHOP",
       "JANE DOE RN MA", "MA LIN",
       "LARRY BLACK SECRETARY",
       "KENT CASHELL TERM ENDED"))
#>                       raw salutation first_name middle_name last_name suffix status
#> 1       BISHOP JOHN SMITH     BISHOP       JOHN                 SMITH              
#> 2             JOHN BISHOP                  JOHN                BISHOP              
#> 3          JANE DOE RN MA      RN_MA       JANE                   DOE              
#> 4                  MA LIN                    MA                   LIN              
#> 5   LARRY BLACK SECRETARY  SECRETARY      LARRY                 BLACK              
#> 6 KENT CASHELL TERM ENDED                  KENT               CASHELL
```

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
parse_name("KENT CASHELL TERM ENDED")[c("first_name", "last_name", "status")]
#>   first_name last_name     status
#> 1       KENT   CASHELL TERM_ENDED
```

### Putting back a name that was stripped

A last safety net catches titles that are also given names. If stripping
leaves no first name, and the removed token is a census given name (or
`JD` or `ED`), the token is restored. Its original position decides its
role: a leading token becomes the first name, a trailing one the
surname.

``` r
show(c("EARL FAHNESTOCK", "TOM MAJOR"))
#>               raw salutation first_name middle_name  last_name suffix status
#> 1 EARL FAHNESTOCK                  EARL             FAHNESTOCK              
#> 2       TOM MAJOR                   TOM                  MAJOR
```

## Using your own lists

[`parse_name()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_name.md)
and
[`parse_names()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_names.md)
take `prefixes` and `suffixes` arguments. Extend the defaults rather
than replace them, so the built-in credentials are still removed:

``` r
x <- "JANE DOE CFRE BOARDCHAIR"
parse_name(x)[c("salutation", "last_name")]
#>   salutation      last_name
#> 1       CFRE DOE-BOARDCHAIR
parse_name(x, prefixes = c(prx, "BOARDCHAIR"))[c("salutation", "last_name")]
#>        salutation last_name
#> 1 CFRE_BOARDCHAIR       DOE
```

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
- A credential not in `prx` survives into the name, often as the last
  name. The lists were extended from the tokens that leaked on 410,071
  Form 990 Part VII names (`data-raw/SUFFIX-GAPS-PART7.md`), so they fit
  that source best.
