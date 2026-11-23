# Look up nicknames, formal names and a canonical form for first names

Matches each first name exactly (after upper-casing) against the bundled
[first_name_pairs](https://nonprofit-open-data-collective.github.io/peopleparser/reference/first_name_pairs.md)
table. Returns the name's formal forms, its nicknames, and one canonical
form for grouping. A name can be both a nickname and a formal name
(`KATIE`: a nickname of KATHERINE and the formal form of KATE). Only
direct pairs are listed: two nicknames of one name (`BETH`, `LISA`) are
not each other's variants.

## Usage

``` r
nickname_lookup(
  first_name,
  gender = NULL,
  gender_confidence = NULL,
  salutation = NULL,
  sep = ";; ",
  min_confidence = 80,
  min_share = 0.6,
  min_nick_rate = 0.002,
  spelling = c("lexicon", "misspelling")
)
```

## Arguments

- first_name:

  Character vector of first names.

- gender:

  Optional vector of `"M"`, `"F"` or `"U"`, as returned by
  [`parse_name()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_name.md),
  used to choose among formal names.

- gender_confidence:

  Optional vector of gender confidence (0-100), as returned by
  [`parse_name()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_name.md).

- salutation:

  Optional vector of salutations, as returned by
  [`parse_name()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_name.md);
  `MR`, `MRS`, `MS` and `MISS` set the gender.

- sep:

  Separator for the list columns. Defaults to `";; "`.

- min_confidence:

  Minimum `gender_confidence` (0-100) to trust census gender. Defaults
  to 80.

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

A `data.frame` with one row per input and columns `first_name_type`
(`formal`, `nickname`, `both`, `variant` for a name only in spelling,
cognate or compound pairs, `unknown`, `initial`, or `""` for a missing
name), `first_name_formal`, `first_name_nicknames`,
`first_name_canonical`, and `canonical_rule` (`self`, `spelling`,
`nickname`, `ambiguous`).

## Details

**Canonical rule.**

1.  *Spelling root.* Each name moves to its most common spelling
    variant, repeatedly, while that is more common nationally (KATHRYN
    -\> KATHERINE -\> CATHERINE; STEVEN -\> STEPHEN). Spelling pairs
    come from the reviewed lexicon and, by default, the misspelling rows
    (a rare form of a common name, used only when the rare form has
    fewer than 1,000 national records: MARCO is not a misspelling of
    MARK).

2.  *Nickname step.* A name whose spelling family is mostly carried as a
    nickname, by at least `min_nick_rate` of the people with that name
    (so MARK, a name in its own right, is not resolved to MARCUS), is
    resolved to a formal name. Its direct formal partners are grouped by
    spelling root and weighted by the number of people carrying each
    pair; partners that are themselves nicknames are dropped when others
    exist; with known gender, partners of the other gender are dropped.
    The top group wins with at least `min_share` of the weight.
    Otherwise the name is `"ambiguous"` and keeps its spelling root
    (KATHY: KATHLEEN vs KATHERINE; AL: ALAN vs ALBERT; PAT with no
    gender).

3.  Chains are not followed: one nickname step at most, so KATHLEEN and
    CATHERINE are not merged through KATE.

Gender comes from a gendered salutation (`MR`, `MRS`, `MS`, `MISS`),
otherwise from `gender` when `gender_confidence >= min_confidence`.

## Examples

``` r
nickname_lookup(c("BOB", "KATHY", "KATIE", "PAT", "PAT", "STEVEN", "KAREN", "J"),
                gender = c("M", "F", "F", "F", "U", "M", "F", "U"),
                gender_confidence = c(99, 99, 99, 90, 50, 99, 99, 50))
#>   first_name_type                                   first_name_formal
#> 1            both                                              ROBERT
#> 2        nickname          KATHLEEN;; KATHRYN;; KATHERINE;; KATHARINE
#> 3        nickname KATHERINE;; KATE;; KATHLEEN;; CATHERINE;; KATHARINE
#> 4            both                                    PATRICIA;; PATSY
#> 5            both                          PATRICIA;; PATRICK;; PATSY
#> 6          formal                                                    
#> 7         variant                                                    
#> 8         initial                                                    
#>   first_name_nicknames first_name_canonical canonical_rule
#> 1          BOBBY;; ROB               ROBERT       nickname
#> 2                                     KATHY      ambiguous
#> 3                                 CATHERINE       nickname
#> 4                PATTY             PATRICIA       nickname
#> 5                PATTY                  PAT      ambiguous
#> 6                STEVE              STEPHEN       spelling
#> 7                                     KAREN           self
#> 8                                         J           self
```
