# peopleparser (development version)

## Split `MC` surnames

* `prep_name()` no longer cuts everything after a standalone `MC`
  (`CHARLES MC SPADDEN` gave last name `MC`). A split `MC` surname inside a
  name is now joined without a dash (`MCSPADDEN`, `MCDERMOTT`). A trailing
  `MC` is a credential (Navy Medical Corps) stripped at the end of a name, and
  a leading `MC` is initials before one word (`MC OLSON`) or part of the first
  name before two or more (`MC-NELLY TORRES`). `MC` is no longer a default
  particle of `fix_locative_surnames()`. `MCCM` is added as a credential.
  Of the 60 Form 990 Part VII names with a standalone `MC`, 55 now parse
  better and 5 are unchanged.

## Two-token names

* In a two-token name with exactly one token absent from the census, a
  leading token of one or two letters is read as initials (`HM CHERRY`,
  `DC ALLEN`), and a listed token whose surname share is at least 0.85 is the
  surname (`NICKHATH SHERIFF`, `SANRDA COHEN`). Before, the unlisted token
  always became the surname.
* A title that is also a surname (`SHERIFF`, `BROTHER`, `BISHOP`, ...) as the
  first of two tokens is a title when the other token is not mostly a given
  name (`SHERIFF MASRY` -> salutation `SHERIFF`, last name `MASRY`).
* On 9,608 Form 990 Part VII names, 20 parses change, 18 of them fixes.
  Parse consistency for the 829 linked people written more than one way is
  unchanged.

* `first_name_pairs` is refreshed from synthid's revised first-name variant
  table: 24,967 pairs, 1,002 in the reviewed lexicon (was 24,972 and 1,007).
  Five pairs were dropped after a review of matches across organizations
  showed they mostly link two different people: JOHN/JONATHAN,
  JOHN/JOHNATHAN, MARY/MARIE, MARY/MARIA and MARIA/MARIE. No other pair
  changed; `chain_id` numbers shift for 82 rows (same chains, new numbers).
* Effect on the nickname columns: JOHN is now `first_name_type = "formal"`
  with no formal names (was `"both"`, formal JONATHAN and JOHNATHAN), and
  JONATHAN and JOHNATHAN no longer list JOHN as a nickname. These are the only
  changes to the nickname columns across all names in the table, and no
  canonical first name changes. In `first_name_variants()`, MARIE and MARIA no
  longer list each other or MARY as cognates (MARY still reaches them as
  sound-alikes through MARI).

# peopleparser 0.1.0

First tagged release. peopleparser parses raw person names into salutation,
first, middle and last name, suffix and status, and scores gender from
U.S. Census name frequencies. This release adds first-name variants and
canonical first names, rebuilds the census table from the 2020 Census,
strips many more titles and credentials found on Form 990 Part VII names,
fixes several name-order bugs, and adds four guides.

## Census name table updated to the 2020 Census

* `census.names` is rebuilt from the Census Bureau's 2020 name release
  ("Frequently Occurring First Names and Last Names from the 2020 Census",
  revised April 2026): 53,615 first names with counts by sex (was 5,494 from
  the 1990 lists) and 156,621 surnames (was 162,253 from 2010). Real counts
  replace the 1990 percentages scaled to counts.
* New `data-raw/census_names.R` downloads the source files, records their
  hashes in `data-raw/census-names-src.csv`, rebuilds the table, compares it
  with the bundled one, and saves it when `CENSUS_NAMES_SAVE=TRUE`. It also
  checks that the old 1990 given-name side can be rebuilt from the 1990 files.
* `determine_surname()` now ranks tokens in tiers: known names that are at
  least 95% surnames first, then unlisted tokens, then the rest by surname
  share. In the 2020 lists nearly every common surname is also a rare given
  name, and without the tiers an initial or unlisted token outranked `SMITH`
  in `SJ SMITH`.
* Effect on 9,608 Form 990 Part VII names: gender agrees with an `MR`, `MRS`
  or `MS` salutation for 86% of names (was 79%), names with unknown gender
  fall from 727 to 227, and plain two- and three-word names keep the written
  first word as the first name 96.3% of the time (was 95.4%). 253 parses
  change first or last name. Gender changes most for names that shifted since
  1990 (`TAYLOR`, `RILEY`, `AVERY` are now mostly female).

## Religious titles license `DC` and `MA`

* After a leading religious title (`SR`, `SISTER`, `FR`, `REV`, ...), `DC`
  (Daughters of Charity) and `MA` strip at the end of the name, with at least
  two names in between: `SR ELLEN KRON DC` -> `KRON`. Without the title they
  still need a clear credential beside them.

## Name-order and gender fixes

* `prep_name()` no longer glues `VAN DER` onto the word before it
  (`MARY VAN DER BERG` gave `MARYVAN-DER-BERG`).
* `fix_locative_surnames()` joins particle chains fully: `DE LA ROSA` ->
  `DE-LA-ROSA` (was last name `DE-LA` with `ROSA` as a middle name).
* Double surnames keep their written order when the parts are adjacent:
  `MARY ANN SMITH JONES` -> `SMITH-JONES` (was `JONES-SMITH`), `JEAN A DU
  PONT` -> `DU-PONT`. `resolve_middle_name()` gains a `tokens` argument.
* Three-token names now count initials correctly, so two initials
  (`A J SMITH`, `SMITH A J`) take their own rule, and a three-token name with
  no census gender evidence gets `U`/`50.0` (or `M`/`50.0` with a suffix)
  instead of an `NA` confidence. On the 1,000 sample names, 7 parses change,
  all fixes.

## Documentation

* Three new guides: `vignette("name-cleaning")` (clutter, titles,
  credentials, suffixes, status), `vignette("name-order")` (name-order rules
  and compound surnames) and `vignette("gender-scoring")` (the gender score
  and where `census.names` comes from).
* `census.names` is documented as Census Bureau name lists, not
  birth-certificate counts, as the README and its help page used to say.
* `prx` and `sfx` are documented as removed wherever they occur, not only at
  the front or the end of a name.

## Suffix gaps on Form 990 Part VII names

* About 90 credentials, religious-order post-nominals, Masonic offices and
  fused military tokens (`RSM`, `CSJ`, `PHARMD`, `FACHE`, `CFRE`, `USNRET`,
  ...) and the hyphenated credentials (`PA-C`, `SHRM-SCP`, ...) are now
  stripped, so they no longer end up in `last_name` (`REARDON-RSM`). Source:
  `data-raw/SUFFIX-GAPS-PART7.md`.
* Some titles now strip only by position. `SJ`, `CISA`, role words
  (`TRUSTEE`, `SECRETARY`, `VICE CHAIR`, ...) and tenure notes (`TERM`,
  `JOINED`, `NON VOTING`, ...) strip only at the end of a name. `BISHOP`,
  `SHERIFF`, `CANTOR`, `DEACON`, `CAPTAIN`, `MOST` and similar strip only as
  the first word. So `JOHN BISHOP` keeps the surname.
* 17 short credentials that are also names or places (`MA`, `DC`, `NP`,
  ...) strip only inside a trailing run that has a clear credential, as `RM`
  already did. The short religious-order post-nominals `OP`, `SC`, `SP`, `CR`,
  `HM` and `DD` strip at the end of a name even on their own, but never as
  leading initials.
* Fused credentials are split before stripping (`JRMD` -> `JR` `MD`,
  `MDMPH` -> `MD` `MPH`), from the third token on and never for a census
  name.
* `prep_name()` joins `ST` to the following surname (`ST-CLAIR`, which no
  longer loses `ST`), `DR PH` into `DRPH` and `NON VOTING` into one word, and
  treats `VANDER` as a surname particle.
* `known_titles()` covers the new tokens and has new types: Religious Order,
  Fraternal Office and Military Status.
* The pkgdown site uses the NODC `pkgstyle` template.

## Name parsing: title vs. given-name / surname collisions

* Given names that were miscategorized as credentials in the `prx` prefix list
  (`EARL`, `ZOLA`) are removed, so records like `EARL FAHNESTOCK` no longer lose
  their first name to salutation stripping.
* `parse_name()` gained a general recovery step: when stripping a salutation
  leaves no first name and the removed token is a known census name, it is
  restored — and its role is decided by its **original position**. A leading
  token is the given name (`EARL FAHNESTOCK` -> first `EARL`); a trailing token
  is the surname and the remaining token becomes the first name (`TOM MAJOR` ->
  first `TOM`, last `MAJOR`). Gender is recomputed from the resolved first name.
* Real titles/credentials (`MR`, `DR`, `REV`, ...) are unaffected: they are not
  census names, so they are never restored as first names.
* Added regression tests covering these cases.

## Nicknames (experimental)

* New `first_name_pairs` dataset: synthid's first-name variant table
  (24,972 pairs observed as one person's first names across Form 990 Part VII
  filings; 1,007 reviewed nickname, spelling, cognate and compound pairs plus
  unreviewed sound-alikes and misspellings), with a `formal` column saying
  which side of a nickname pair is the formal name.
* New `nickname_lookup()`, `canonical_first_name()`, `get_formal_names()` and
  `get_nicknames()`. The canonical rule takes a spelling step to the most
  common spelling, then at most one nickname step, chosen by the people
  carrying each pair, filtered by gender, and left `"ambiguous"` when no formal
  name holds 60% of the evidence. Variant chains are never followed.
* New `first_name_variants()`: every name in a name's canonical family, with
  how it gets there, plus related names that are not merged.
* `parse_name()` and `parse_names()` gain `add_nicknames = FALSE`, which
  appends `first_name_type`, `first_name_formal`, `first_name_nicknames`,
  `first_name_canonical` and `canonical_rule`.
* New vignette, "Canonical first names, nicknames and gender".
* Pilot on 33,535 linked Part VII records: `data-raw/PLAN-nicknames.md`.
