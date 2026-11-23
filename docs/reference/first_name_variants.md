# All variants in a first name's family

Lists every name that shares the canonical form of `x` (see
[`nickname_lookup()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/nickname_lookup.md)
for the rule), and how each one gets there: spellings, misspellings and
nicknames of that canonical name. It also lists, with
`in_canonical = FALSE`, names that are related but are **not** merged
into the canonical form: unreviewed sound-alike spellings, cognates
(JOSE for JOSEPH), compound names (MARYANN), and nicknames that are
ambiguous between this name and another (KATHY between KATHLEEN and
KATHERINE).

## Usage

``` r
first_name_variants(
  x,
  gender = "U",
  related = TRUE,
  min_freq = 0,
  min_share = 0.6,
  min_nick_rate = 0.002,
  spelling = c("lexicon", "misspelling")
)
```

## Arguments

- x:

  A first name (a single string; case is ignored).

- gender:

  `"U"` (default), `"M"` or `"F"`. Gender can change the canonical form
  of a nickname (`PAT`) and so the family.

- related:

  Logical; include the related names that are not merged
  (`in_canonical = FALSE`). Defaults to `TRUE`.

- min_freq:

  Drop names with fewer national Part VII records than this (most
  misspellings are rare). Defaults to 0 (keep all).

- min_share:

  Share of the nickname evidence the top formal name needs. Defaults to
  0.6.

- min_nick_rate:

  Minimum ratio of people carrying the name as a nickname (people with
  the name and a formal form) to national records with the name, for the
  name to be resolved. Defaults to 0.002.

- spelling:

  Which spelling pairs define spelling roots: any of `"lexicon"`
  (reviewed spelling pairs), `"misspelling"` (rare forms of common
  names), `"sound_alike"` (unreviewed sound-alike pairs). Defaults to
  `c("lexicon", "misspelling")`.

## Value

A `data.frame`, one row per name, with columns `name`, `canonical`,
`relation` (`canonical`, `spelling`, `misspelling`, `sound_alike`,
`nickname`, `ambiguous nickname`, `cognate`, `compound`), `via` (the
name it connects through, for a spelling step or a nickname step),
`in_canonical`, `freq` (national Part VII records with the name) and
`share_female`. Merged names come first, most common first.

## Examples

``` r
first_name_variants("kate", min_freq = 1000)
#>         name canonical           relation       via in_canonical   freq
#> 1  CATHERINE CATHERINE          canonical                   TRUE  80652
#> 2  KATHERINE CATHERINE           spelling CATHERINE         TRUE  68778
#> 3    KATHRYN CATHERINE           spelling KATHERINE         TRUE  56874
#> 4  KATHARINE CATHERINE           spelling KATHERINE         TRUE   6640
#> 5       KATI CATHERINE           spelling     KATIE         TRUE   1936
#> 6  CATHARINE CATHERINE           spelling CATHERINE         TRUE   1624
#> 7   KATHERYN CATHERINE           spelling   KATHRYN         TRUE   1529
#> 8      KATIE CATHERINE           nickname KATHERINE         TRUE  83422
#> 9       KATE CATHERINE           nickname KATHERINE         TRUE  60703
#> 10     KITTY CATHERINE           nickname KATHERINE         TRUE   4930
#> 11       KAT CATHERINE           nickname KATHERINE         TRUE   2510
#> 12   KATRINA CATHERINE        sound_alike KATHERINE        FALSE  13742
#> 13     KATHI CATHERINE        sound_alike      KATE        FALSE   6391
#> 14   CATHRYN CATHERINE        sound_alike   CATHRIN        FALSE   2059
#> 15   CATRINA CATHERINE        sound_alike  CATERINA        FALSE   1067
#> 16     KATHY CATHERINE ambiguous nickname     KATHY        FALSE 170348
#> 17     CATHY CATHERINE ambiguous nickname     KATHY        FALSE  77965
#> 18      KATY CATHERINE ambiguous nickname     KATHY        FALSE  11867
#> 19    KATHIE CATHERINE ambiguous nickname     KATHY        FALSE   7323
#> 20    CATHIE CATHERINE ambiguous nickname     KATHY        FALSE   3165
#>    share_female
#> 1         0.999
#> 2         0.999
#> 3         0.999
#> 4         0.990
#> 5         0.998
#> 6         0.978
#> 7         0.991
#> 8         0.999
#> 9         0.997
#> 10        0.997
#> 11        0.750
#> 12        0.999
#> 13        0.990
#> 14        1.000
#> 15        1.000
#> 16        1.000
#> 17        0.999
#> 18        0.993
#> 19        0.997
#> 20        0.996
first_name_variants("steve", related = FALSE)
#>        name canonical    relation     via in_canonical   freq share_female
#> 1   STEPHEN   STEPHEN   canonical                 TRUE 218193        0.000
#> 2    STEVEN   STEPHEN    spelling STEPHEN         TRUE 204799        0.000
#> 3   STEPHAN   STEPHEN    spelling STEPHEN         TRUE   6925        0.000
#> 4  STEPHANE   STEPHEN misspelling STEPHEN         TRUE    806        0.998
#> 5    STEVAN   STEPHEN misspelling  STEVEN         TRUE    714        0.000
#> 6   STEPHON   STEPHEN misspelling STEPHEN         TRUE    237        0.000
#> 7     STEVI   STEPHEN misspelling   STEVE         TRUE    184        0.000
#> 8    STEFEN   STEPHEN misspelling  STEVEN         TRUE     78        0.000
#> 9      STEV   STEPHEN misspelling   STEVE         TRUE     62        0.000
#> 10   STEVIN   STEPHEN misspelling  STEVEN         TRUE     62        0.000
#> 11  STEPHNE   STEPHEN misspelling STEPHEN         TRUE     45        0.000
#> 12 STEPHENE   STEPHEN misspelling STEPHEN         TRUE     44        0.000
#> 13   STEEVE   STEPHEN misspelling   STEVE         TRUE     41        0.000
#> 14   STEVEE   STEPHEN misspelling   STEVE         TRUE     25        0.000
#> 15   STEPHN   STEPHEN misspelling STEPHEN         TRUE     17        0.000
#> 16    STEVN   STEPHEN misspelling  STEVEN         TRUE     16        0.000
#> 17   STEAVE   STEPHEN misspelling   STEVE         TRUE     14        0.000
#> 18 STHEPHEN   STEPHEN misspelling STEPHEN         TRUE     12        0.000
#> 19   STEVEY   STEPHEN misspelling   STEVE         TRUE     11        0.000
#> 20    STEVA   STEPHEN misspelling   STEVE         TRUE      9        0.000
#> 21 STEPHAEN   STEPHEN misspelling STEPHEN         TRUE      9        0.000
#> 22 STEAPHEN   STEPHEN misspelling STEPHEN         TRUE      8        0.000
#> 23  STEVENN   STEPHEN misspelling  STEVEN         TRUE      5        0.000
#> 24 STEHPHEN   STEPHEN misspelling STEPHEN         TRUE      4        0.000
#> 25 SSTEPHEN   STEPHEN misspelling STEPHEN         TRUE      4        0.000
#> 26 STEPHEAN   STEPHEN misspelling STEPHEN         TRUE      4        0.000
#> 27  SSTEVEN   STEPHEN misspelling  STEVEN         TRUE      4        0.000
#> 28 STEVPHEN   STEPHEN misspelling STEPHEN         TRUE      3        0.000
#> 29 STEPHEHN   STEPHEN misspelling STEPHEN         TRUE      3        0.000
#> 30 STEPHHEN   STEPHEN misspelling STEPHEN         TRUE      2        0.000
#> 31   STEVVE   STEPHEN misspelling   STEVE         TRUE      2        0.000
#> 32   STEVEI   STEPHEN misspelling   STEVE         TRUE      2        0.000
#> 33   STEIVE   STEPHEN misspelling   STEVE         TRUE      1        0.000
#> 34   SSTEVE   STEPHEN misspelling   STEVE         TRUE      1        0.000
#> 35   STEVEH   STEPHEN misspelling   STEVE         TRUE      1        0.000
#> 36  STEVFEN   STEPHEN misspelling  STEVEN         TRUE      1        0.000
#> 37  STTEVEN   STEPHEN misspelling  STEVEN         TRUE      1        0.000
#> 38    STEVE   STEPHEN    nickname  STEVEN         TRUE 419562        0.000
first_name_variants("pat", gender = "F")
#>         name canonical    relation      via in_canonical   freq share_female
#> 1   PATRICIA  PATRICIA   canonical                  TRUE 175659        1.000
#> 2      PATTI  PATRICIA    spelling    PATTY         TRUE  29761        0.998
#> 3     TRISHA  PATRICIA    spelling   TRICIA         TRUE   8246        0.997
#> 4     PATTIE  PATRICIA    spelling    PATTY         TRUE   2411        0.983
#> 5       PATT  PATRICIA    spelling      PAT         TRUE    308        0.000
#> 6       PATI  PATRICIA misspelling    PATTI         TRUE    459        0.000
#> 7   PATRICIO  PATRICIA misspelling PATRICIA         TRUE    360        0.000
#> 8   PATRIZIA  PATRICIA misspelling PATRICIA         TRUE    133        0.000
#> 9      TRISA  PATRICIA misspelling   TRISHA         TRUE    111        0.000
#> 10   TRISHIA  PATRICIA misspelling   TRICIA         TRUE    103        0.000
#> 11      PATY  PATRICIA misspelling    PATTY         TRUE     80        0.000
#> 12  PATRISHA  PATRICIA misspelling PATRICIA         TRUE     62        0.000
#> 13  PATRECIA  PATRICIA misspelling PATRICIA         TRUE     46        0.000
#> 14 PATTRICIA  PATRICIA misspelling PATRICIA         TRUE     18        0.000
#> 15     PATIE  PATRICIA misspelling   PATTIE         TRUE     17        0.000
#> 16   PATRICI  PATRICIA misspelling PATRICIA         TRUE     15        0.000
#> 17  PATRYCIA  PATRICIA misspelling PATRICIA         TRUE     15        0.000
#> 18  PATIRCIA  PATRICIA misspelling PATRICIA         TRUE     14        0.000
#> 19  PATRICIE  PATRICIA misspelling PATRICIA         TRUE     14        0.000
#> 20 PATIRICIA  PATRICIA misspelling PATRICIA         TRUE     14        0.000
#> 21  PATRACIA  PATRICIA misspelling PATRICIA         TRUE     10        0.000
#> 22    PATTII  PATRICIA misspelling    PATTI         TRUE     10        0.000
#> 23     TRICI  PATRICIA misspelling   TRICIA         TRUE      8        0.000
#> 24 PATRRICIA  PATRICIA misspelling PATRICIA         TRUE      7        0.000
#> 25     PATII  PATRICIA misspelling    PATTI         TRUE      5        0.000
#> 26   PATRISA  PATRICIA misspelling PATRICIA         TRUE      5        0.000
#> 27    THRISA  PATRICIA misspelling   TRISHA         TRUE      4        0.000
#> 28 PATRIICIA  PATRICIA misspelling PATRICIA         TRUE      4        0.000
#> 29   TRISHAH  PATRICIA misspelling   TRISHA         TRUE      4        0.000
#> 30    TRISAH  PATRICIA misspelling   TRISHA         TRUE      3        0.000
#> 31     PATYY  PATRICIA misspelling    PATTY         TRUE      3        0.000
#> 32 PPATRICIA  PATRICIA misspelling PATRICIA         TRUE      2        0.000
#> 33 PATARICIA  PATRICIA misspelling PATRICIA         TRUE      2        0.000
#> 34 PATRICIAA  PATRICIA misspelling PATRICIA         TRUE      2        0.000
#> 35     PATEY  PATRICIA misspelling      PAT         TRUE      1        0.000
#> 36      PPAT  PATRICIA misspelling      PAT         TRUE      1        0.000
#> 37 PATRICIAS  PATRICIA misspelling PATRICIA         TRUE      1        0.000
#> 38 PAATRICIA  PATRICIA misspelling PATRICIA         TRUE      1        0.000
#> 39 PATRICIAI  PATRICIA misspelling PATRICIA         TRUE      1        0.000
#> 40       PAT  PATRICIA    nickname PATRICIA         TRUE 110517        0.998
#> 41     PATTY  PATRICIA    nickname PATRICIA         TRUE  35193        0.998
#> 42    TRICIA  PATRICIA    nickname PATRICIA         TRUE  17703        0.996
#> 43     PATTE  PATRICIA sound_alike   PATTIE        FALSE    200        0.000
#> 44 PATYRICIA  PATRICIA sound_alike PATRYCIA        FALSE      2        0.000
#> 45   PATRICE  PATRICIA     cognate PATRICIA        FALSE   8788        0.998
```
