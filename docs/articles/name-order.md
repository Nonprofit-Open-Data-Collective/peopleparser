# Name order and compound surnames

Records list names in different orders: `JOHN A SMITH`, `SMITH JOHN A`,
`SMITH, JOHN`. Nothing in the string says which order was used, so
peopleparser guesses from how often each token is used as a given name
or as a surname. This article explains that evidence, the rules that use
it for names of two, three and more tokens, and the rules that keep
compound surnames (`VON KAMECKE`, `GARCIA LOPEZ`) together.

The rules run after cleaning, on the tokens that are left once titles,
credentials and suffixes are gone (see
[`vignette("name-cleaning")`](https://nonprofit-open-data-collective.github.io/peopleparser/articles/name-cleaning.md)).

## The evidence: first-name and surname counts

`census.names` counts how often each name is a first name and how often
a surname in U.S. Census Bureau name files (see
[`vignette("gender-scoring")`](https://nonprofit-open-data-collective.github.io/peopleparser/articles/gender-scoring.md)
for where the table comes from).
[`get_census_data()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/get_census_data.md)
looks up each token:

``` r
get_census_data(c("JOHN", "SMITH", "JORDAN", "TAYLOR", "LESLIE", "KYUN"))
#> Key: <ordinal>
#>      name ordinal male_value female_value first_name_value last_name_value
#>    <char>   <int>      <num>        <num>            <num>           <num>
#> 1:   JOHN       1    4684909        18222          4703131           33543
#> 2:  SMITH       2          0            0                0         2442977
#> 3: JORDAN       3      80206        18222            98428          208403
#> 4: TAYLOR       4      34374        18222            52596          751209
#> 5: LESLIE       5     116012       233858           349870           25078
#> 6:   KYUN       6          0            0                0               0
```

Some tokens are clearly one or the other (`JOHN`, `SMITH`). Others are
both: `JORDAN` and `TAYLOR` are common in both positions, and `LESLIE`
is a common surname too. `KYUN` is in neither list.

[`check_if_surname()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/check_if_surname.md)
turns the counts into a yes/no: a token reads as a surname when more
than half of its count is in the surname position. A token found in
neither list reads as a surname.

``` r
x <- c("JOHN", "SMITH", "JORDAN", "TAYLOR", "LESLIE", "KYUN")
setNames(check_if_surname(x), x)
#>   JOHN  SMITH JORDAN TAYLOR LESLIE   KYUN 
#>  FALSE   TRUE   TRUE   TRUE  FALSE   TRUE
```

[`determine_surname()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/determine_surname.md)
picks the single most likely surname in a name. It ranks tokens by the
share of their count in the surname position, with one added to the
surname count so that unknown tokens score high:

``` math

p_{last} = \frac{1 + n_{last}}{1 + n_{first} + n_{last}}
```

Ties go to the more common token, then to the later position.

``` r
cd <- get_census_data(c("TAYLOR", "JORDAN"))
determine_surname(cd)   # position of the surname: JORDAN is first, TAYLOR the surname
#> [1] 1
```

## Rules by number of tokens

### One token

A lone token is treated as the surname.

``` r
show(c("SMITH", "MADONNA"))
#>       raw first_name middle_name last_name
#> 1   SMITH                            SMITH
#> 2 MADONNA                          MADONNA
```

### Two tokens

The token that
[`determine_surname()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/determine_surname.md)
picks is the surname; the other is the first name. Order in the string
does not matter.

``` r
show(c("JOHN SMITH", "SMITH JOHN", "JORDAN TAYLOR", "TAYLOR JORDAN",
       "LESLIE JAMES", "R BLINCOE"))
#>             raw first_name middle_name last_name
#> 1    JOHN SMITH       JOHN                 SMITH
#> 2    SMITH JOHN       JOHN                 SMITH
#> 3 JORDAN TAYLOR     JORDAN                TAYLOR
#> 4 TAYLOR JORDAN     JORDAN                TAYLOR
#> 5  LESLIE JAMES      JAMES                LESLIE
#> 6     R BLINCOE          R               BLINCOE
```

`LESLIE JAMES` shows the cost of this rule: both names are used in both
positions, and `JAMES` is the stronger given name, so the parse comes
out as `JAMES LESLIE`.

### Three tokens with two initials

The full token is the surname and the initials are the first and middle
initials, in order: `A J SMITH` and `SMITH A J` both give `A J SMITH`.

### Three tokens with one initial

A single-letter token is a middle initial (or a first initial). The
rules assume two orders, `FIRST M LAST` and `LAST FIRST M`:

- a trailing initial means the name was written surname first:
  `SMITH JOHN A` becomes `JOHN A SMITH`;
- an initial in the middle with a surname in front and a given name at
  the end (`SMITH J ALAN`) is also reordered;
- otherwise the order is kept.

``` r
show(c("JOHN A SMITH", "SMITH JOHN A", "SMITH J ALAN", "J ALAN SMITH"))
#>            raw first_name middle_name last_name
#> 1 JOHN A SMITH       JOHN           A     SMITH
#> 2 SMITH JOHN A       JOHN           A     SMITH
#> 3 SMITH J ALAN          J        ALAN     SMITH
#> 4 J ALAN SMITH          J        ALAN     SMITH
```

The trailing-initial rule cannot tell `JOHN SMITH A` (given name first,
stray initial at the end) from `SMITH JOHN A`, and reads both as surname
first.

### Three full tokens

[`check_if_surname()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/check_if_surname.md)
is applied to each token:

- surname, surname, given name (`GARCIA LOPEZ MARIA`): the given name
  moves to the front;
- surname, given name, any (`SMITH JOHN ALAN`): the first token moves to
  the end;
- otherwise the order is kept: first, middle, last.

``` r
show(c("JOHN ALAN SMITH", "SMITH JOHN ALAN", "GARCIA LOPEZ MARIA"))
#>                  raw first_name middle_name    last_name
#> 1    JOHN ALAN SMITH       JOHN        ALAN        SMITH
#> 2    SMITH JOHN ALAN       JOHN        ALAN        SMITH
#> 3 GARCIA LOPEZ MARIA      MARIA             GARCIA-LOPEZ
```

### Four or more tokens

The first token is the first name and
[`determine_surname()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/determine_surname.md)
picks the surname. Everything else is the middle name. If the name opens
with two surnames followed by a given name (`SMITH JONES MARY ANN`), the
two surnames are joined into one.

``` r
show(c("JOHN PAUL GEORGE RINGO", "SMITH JONES MARY ANN"))
#>                      raw first_name middle_name   last_name
#> 1 JOHN PAUL GEORGE RINGO       JOHN PAUL GEORGE       RINGO
#> 2   SMITH JONES MARY ANN       MARY         ANN SMITH-JONES
```

## Compound surnames

Compound surnames are kept together by joining their parts with a dash,
so they stay one token through the rest of the parse. The census looks
names up with the dashes removed (`VON-KAMECKE` as `VONKAMECKE`).

### Surname particles

[`prep_name()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/prep_name.md)
and
[`fix_locative_surnames()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/fix_locative_surnames.md)
join a particle to the word after it. The particles are `LA`, `VON`,
`VAN`, `VANDER`, `DEL`, `DE`, `DI`, `DEN`, `DER`, `MC` and `O`, plus
`ST` inside a name (Saint) and `LO GRANDE`.

Particles chain, so `DE LA ROSA` and `VAN DER BERG` become one token.

``` r
fix_locative_surnames(c("Jane Van Dyke", "Carlos De La Rosa", "Dylan Van"))
#> [1] "Jane Van-Dyke"     "Carlos De-La-Rosa" "Dylan Van"
show(c("THOMAS H VON KAMECKE", "SEAN ST CLAIR", "JULIA DI BUSSOLO",
       "JUAN CARLOS DE LA ROSA", "MARY VAN DER BERG"))
#>                      raw first_name middle_name    last_name
#> 1   THOMAS H VON KAMECKE     THOMAS           H  VON-KAMECKE
#> 2          SEAN ST CLAIR       SEAN                 ST-CLAIR
#> 3       JULIA DI BUSSOLO      JULIA               DI-BUSSOLO
#> 4 JUAN CARLOS DE LA ROSA       JUAN      CARLOS   DE-LA-ROSA
#> 5      MARY VAN DER BERG       MARY             VAN-DER-BERG
```

A particle at the end of a name (`Dylan Van`) has nothing to join and is
left alone. `ST` at the start of a name is not joined, because there it
is usually a title.

### Two surnames: middle tokens that read as surnames

After the first, middle and last names are assigned, a middle name of
three or more letters is checked again. If it reads as a surname, it is
joined to the last name:

- one middle token that reads as a surname joins the last name
  (`MARIA GARCIA LOPEZ` gives `GARCIA-LOPEZ`);
- with several middle tokens, an initial followed by a full token keeps
  the initial as the middle name and joins the rest to the surname;
- otherwise, everything from the first surname-like middle token on
  joins the surname, and the tokens before it stay as the middle name.

When the surname parts are next to each other in the original string,
they are joined in the order they were written. `MARY ANN SMITH JONES`
gives `SMITH-JONES`, even though `SMITH` was picked as the main surname.
When they are not next to each other (`SMITH JOHN WALKER`, written
surname first), the middle part goes first.

``` r
show(c("MARIA GARCIA LOPEZ", "ELIZABETH ANNE WALKER SMITH",
       "JOHN Q PUBLIC SMITH", "MARY ANN SMITH JONES", "JEAN A DU PONT"))
#>                           raw first_name middle_name    last_name
#> 1          MARIA GARCIA LOPEZ      MARIA             GARCIA-LOPEZ
#> 2 ELIZABETH ANNE WALKER SMITH  ELIZABETH        ANNE WALKER-SMITH
#> 3         JOHN Q PUBLIC SMITH       JOHN           Q PUBLIC-SMITH
#> 4        MARY ANN SMITH JONES       MARY         ANN  SMITH-JONES
#> 5              JEAN A DU PONT       JEAN           A      DU-PONT
```

One exception: `MAY` is a common middle name and a surname. If it ends
up at the front of a compound surname, it is moved back to the middle
name.

``` r
show(c("SARAH MAY WILSON", "MARY MAY"))
#>                raw first_name middle_name last_name
#> 1 SARAH MAY WILSON      SARAH         MAY    WILSON
#> 2         MARY MAY       MARY                   MAY
```

### Titles that turned out to be names

When a token is both a title and a name (`EARL`, `MAJOR`), cleaning may
strip it and leave no first name. The parser then puts it back, using
its position in the original string: a leading token is the first name
and a trailing one is the surname. See
[`vignette("name-cleaning")`](https://nonprofit-open-data-collective.github.io/peopleparser/articles/name-cleaning.md).

## Limits

- The rules know only how common each token is, not which order a source
  uses. If you know the source writes `LAST FIRST`, reorder the tokens
  before parsing.
- Tokens absent from the census read as surnames. A rare given name
  (`KYUN`) can end up as the surname. When both tokens read as surnames,
  the more common one wins: in `LUDWIG VAN BEETHOVEN`, `LUDWIG` (a
  census surname, never a census first name) beats the unlisted
  `VAN-BEETHOVEN`.
- A name that is both a common given name and a common surname (`JAMES`,
  `LESLIE`, `TAYLOR`, `JORDAN`) is decided by a small margin. Treat such
  parses as uncertain.
- A middle name that is also a surname (`ANNE WALKER`) is joined to the
  last name. That is right for Spanish and Portuguese double surnames
  and for maiden names kept as a middle name, but not for given middle
  names that are also surnames.
