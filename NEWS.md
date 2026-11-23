# peopleparser (development version)

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
* `census.names` is documented as what it is: a bundled, frozen table of 1990
  Census first names and 2010 Census surnames, not birth-certificate counts.
  The README is corrected to match.
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
