# peopleparser 0.2.3

## Unknown credentials no longer become the surname

* In 0.2.2 a middle name joins the surname only when it is a strong surname.
  Where the last word was a credential or organisation code the lists do not
  know, that code became the whole surname: `ANDREA M GORDON NMF` gave
  `NMF`, where 0.2.1 gave `GORDON-NMF`. npmerger found 2,433 such last names
  in 1.77 million Part VII names (about half were real surnames missing from
  the census, which 0.2.2 parses correctly).
* A last word that is not in the census is now stripped as a credential when
  it follows a known title, suffix or credential (`CHONG MD FAAFP`,
  `ROBEL RN BSN MHA NEA-BC`, `SCOTT III NMHC`), when it is in a new list of
  1,223 trailing codes, or when it is a short code (five letters or fewer, at
  most one vowel) after a census surname (`BRIAN FRITZ UHC`,
  `SCOTT WILLIS USMCR`). A surname missing from the census after a given
  name is kept (`CYNTHIA SIMON SKJODT`, `MARISSA PIAZZA PASKY`).
* The list (`data-raw/trailing-credentials.csv`, built by
  `data-raw/trailing_credentials.R` from all Part VII names) holds words that
  end the names of at least three different people, follow a census surname
  or a credential in at least 70% of them, and look like a code: medical
  credentials and fellowships (`FACEP`, `FAAFP`, `FACR`, `CRNP`), dates and
  tenure notes (`OCT`, `JAN-JUNE`, `PART-YEAR`), other professions
  (`SIOR`, `CGCS`), religious orders (`SSND`, `OSFS`) and hospital or system
  codes (`UPMC`, `NMHC`).
* On npmerger's 2,433 names, 976 now get the true surname back; most of the
  rest are real surnames missing from the census. On the 10,000-name synthid
  sample, 29 names change from 0.2.2, all but one for the better.
* New trailing role words `MANAGER`, `FOUNDER`, `COFOUNDER`, `COCHAIR`,
  `CO-CHAIR`, `CONTROLLER`, and the inner particles `AL` and `EL`
  (`MOHAMMED M AL HAEMLI` -> `AL-HAEMLI`).

# peopleparser 0.2.2

## Compared with the parses in synthid

* New article, "What changed since the synthid parses"
  (`vignettes/articles/version-comparison.Rmd`), compares 0.2.2 with the
  parses stored in synthid's Part VII people tables (peopleparser `cb01547`,
  0.0.0.9000) on 10,000 random names from 2017 and 2024. 903 names (9%) parse
  differently:

  | Change | Names | Assessment |
  |---|---|---|
  | Gender only | 485 | 562 names newly coded from the 2020 census; 98 unisex names switched |
  | First and last name swapped | 262 | 256 now keep the written order |
  | Middle name no longer joined to the surname | 50 | `DAVID LEE SMITH` was `LEE-SMITH`; a few names written surname first are now wrong |
  | Title or credential taken out of the name | 41 | `SHERIFF`, `RABBI`, `MONSIGNOR`, `RSM`, `CRNA`, `PSYD` |
  | Particle joined to the surname | 3 | `ST-GEORGE`, `DA-SILVA` |
  | Other | 62 | compound surnames in written order, `KENNETHVAN` split; about half wrong in both |

  Gaps that remain: an unlisted given name before a listed one can still be
  read as surname first (`MASSUMEH FARHAD`); credentials the lists do not know
  stay in the surname (`SSND`, `SIOR`, `FCAP`); organisations in person fields
  are parsed as people unless `classify = TRUE` is used; unisex names get a
  near coin-toss gender. The script is `data-raw/compare_versions.R`.

## Fixes for names 0.2.1 parsed worse than the old build

* **Three-word names keep their written order** unless the first word is
  clearly a surname and the last a given name, with the same written-order
  test as two-word names. The old rule counted every word missing from the
  census as a surname, so `TOKS MALIK ASHIRU` and `DONG JOON YI` were
  reordered. On 28,811 three-word Part VII names labelled by the convention of
  their return, wrong reorders fall from 1,210 to 53
  (`data-raw/name_order_eval3.R`).
* **A middle name joins the surname only when it is a strong surname** (90%
  or more of its census records, or not in the census): `MARIA GARCIA LOPEZ`
  still gives `GARCIA-LOPEZ`, but `JOHN LEE SMITH`, `BILLY RAY JONES` and
  `BOYD RAY SCOTT` keep their middle names. Initials never join the surname
  (`TOBI M E YOUNG` was `M-E-YOUNG`).
* A word, two or more initials and a word (`GLYNN C W SCOTT`) is read like a
  two-word name with middle initials; elsewhere a single letter is chosen as
  the surname only when nothing else can be.
* More surname particles, joined only inside a name: `VANDEN`, `VANDE`,
  `SAN`, `SANTA`, `LOS`, `LAS`, `DELLA`, `DALLA`, `DELA`, `DOS`, `DAS`, `DA`,
  `DU`, `TEN`, `TER` (`PATRICIA SAN PEDRO`, `ESTELLA DE LOS RIOS`).
* New leading titles: `SIR`, `DAME`, `CHIEF`, `COUNCILMAN`, `COUNCILWOMAN`,
  `COUNCILMEMBER`, `CORPORAL`, `GENL`, `REP`, `CHAPLAIN`. Ranks and offices
  (`GEN`, `COL`, `ADM`, `SGT`, `GOV`, `SEN`, `HON`, `REV`) are no longer put
  back as a given name when stripping them leaves none (`GEN PERRIN`).
* `de_clutter()` no longer drops the whole name after a rank followed by
  `RET` (`COL RET CLARENCE MAXWELL` was `COL`).

# peopleparser 0.2.1

## Name types: people, organisations and placeholders

* New `classify_names()` labels each entry `person`, `organisation`,
  `person and organisation` (a name followed by an employer), `several people`
  or `placeholder` (`SEE SCHEDULE O`, `VACANT`), with an `org_score`. Placeholders
  and couples are found by rules; organisations by a model trained on Form 990
  Part VII names (982,000 filer names against 9.4 million person-field names;
  held-out AUC 0.9996), plus a list of trust banks written without an
  organisation word (`BNY MELLON`, `WELLS FARGO`). See
  `vignette("name-types")` and `data-raw/name_type_model.R`.
* `parse_names(classify = TRUE)` adds the `name_type` and `org_score`
  columns. Off by default.

## Run-together names (opt-in)

* New `split_run_together()` splits a surname and given name written as one
  word: at an inner capital (`KramerKenneth`, `LedbetterJennifer A`) or, more
  cautiously, in all capitals (`MURPHYSANDRA`). Surname particles (`McDonald`,
  `LaToya`) and 214 recurring surnames that look like two names (`MARKWALD`)
  are left alone. On Part VII names it splits about 6,600 rows, and about 19
  of 20 splits in random samples are right.
* `parse_names(split_run_together = TRUE)` and
  `parse_name(split_run_together = TRUE)` apply it before parsing. Off by
  default, so default parses are unchanged from 0.2.0.

# peopleparser 0.2.0

## `parse_names()` no longer starts its own workers (breaking)

* `parse_names()` used to start a new set of background R sessions on every
  call (`future::plan(multisession)` with all cores but one). It now runs in
  the current session unless the caller has set a `future::plan()`, or passes
  the new `workers` argument: `workers = 4` starts four workers for that call
  and restores the caller's plan afterwards; `workers = 1` forces sequential
  parsing. Code that relied on the old parallel default should pass
  `workers =` or set a plan.
* Workers load the installed copy of peopleparser. Each now reports its
  version and build time, and `parse_names()` stops with a clear message if
  any differs from the calling session (a reinstall while R was running, or a
  session using `devtools::load_all()`), instead of silently parsing with
  older code.

## Faster parsing

* Each dataset (`census.names`, `first_name_pairs`) is loaded once per
  session. Before, when peopleparser was loaded but not attached (calls like
  `peopleparser::parse_name()`, or inside workers), every census lookup
  reloaded the table.
* Census lookups use a hashed index built once per session instead of a
  keyed join per call, and `determine_surname()` ranks tokens in base R
  rather than dplyr. Parses are unchanged.
* Speed on 20,000 Form 990 Part VII names, names a second (24-core machine):

  | Call | 0.1.0 | Now |
  |---|---|---|
  | `peopleparser::parse_name()`, package not attached | 6 | 370 |
  | `parse_name()`, attached | 94 | 2,040 |
  | `parse_names()`, five calls of 200 names | 73 | 1,790 |
  | `parse_names()`, 20,000 names (default) | 586 | 1,660 |
  | `parse_names(workers = 7)`, 20,000 names | - | 3,860 |

  The 0.1.0 `parse_names()` rows used its built-in parallel default, here 23
  workers started on every call. The 20,000 parses are identical before and
  after.

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

## Two-token names keep their written order (changes parses)

* Two-word names now start from the written order (first name, then surname)
  and are swapped only when the census makes surname-first much more likely:
  smoothed surname shares (pseudo-count 20), odds of surname-first above 30.
  Before, the token with the higher raw surname share was the surname wherever
  it stood, so thin or mixed evidence flipped names: `HARRIS MORRISON`,
  `RICHARD RUVIN` (first name `RUVIN`), `FOSTER MCDONALD`, `MARK MICHAEL`,
  `MARSHALL RYAN`. Clear surname-first names are still swapped (`SMITH JOHN`,
  `GARCIA MARIA`).
* Tuned on 758,388 two-word Form 990 Part VII names, each labelled by the
  convention of the other names on its return (`data-raw/name_order_eval.R`):
  order errors fall from 12,463 to 2,687. Names written first name first keep
  their order 99.8% of the time (was 98.4%); 89% of names written surname
  first are swapped (was 97%, at the cost of many false swaps).
* A leading token of one or two letters absent from the census is initials
  (`HM CHERRY`, `DC ALLEN`), and a lone letter is rarely the surname
  (`BISHOP J` -> surname `BISHOP`). This replaces the 0.85 surname-share rule
  added earlier in this development cycle.
* Names of three or more words are unchanged.
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
