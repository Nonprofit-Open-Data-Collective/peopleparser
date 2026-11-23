# census.names: rebuilt from the 2020 Census

Dev note, 2026-11-23. Commit `fd5bcdb` (local, not pushed; see Open items).

## What changed

* **Source.** `census.names` is now built from the Census Bureau's 2020
  release, "Frequently Occurring First Names and Last Names from the 2020
  Census" (revised 2026-04-09):
  * `Names2020_FirstNames_Sex.xlsx`: 53,615 first names held by 91+ people,
    with counts recorded male and female;
  * `Names2020_LastNames_RaceHispanic.xlsx`: 156,621 surnames held by 92+
    people.

  Both end in an `ALL OTHER NAMES` row. The table keeps the same five
  columns. It is now `data/census.names.rda`, replacing
  `data/census.names.RData`.
* **Old table.** The 1990 first-name lists (1,219 male and 4,275 female
  names), published as percentages and scaled to counts by about 1,432,240
  (men) and 1,518,500 (women), and the 2010 surname file (162,253 names).
  `check_1990_first_names()` in the build script rebuilds that given-name
  side from the 1990 files: all 1,219 male and 4,274 of 4,275 female names
  match, within 0.007%.
* **Surname ranking.** `determine_surname()` now ranks in tiers:
  1. known names with surname share at least 0.95 (`.surname_tier_min`),
     the more common first;
  2. unlisted tokens;
  3. the rest by share.

  The 2020 lists give nearly every common surname a few given-name uses
  (SMITH: 4,999), so a plain share let an initial or an unlisted token
  outrank SMITH ("SJ SMITH", "BEGIN SMITH").

## How it was tested

The same 9,608 Part VII names (npmerger `part7` table) were parsed
sequentially with each table: 4,608 names holding a suffix-gap token and
5,000 random controls.

| Table | Written order kept, plain 2-3 word names (5,268) | Same, controls (4,012) | Parses changed | Gender = MR/MRS/MS (87) | Gender U |
|---|---|---|---|---|---|
| old (1990/2010) | 95.44% | 95.91% | 0 | 79.3% | 727 |
| 2020, untiered | 95.88% | 96.56% | 315 | 86.2% | 159 |
| 2020, tier 0.90 | 96.17% | 96.71% | 242 | 86.2% | 249 |
| **2020, tier 0.95** | **96.32%** | **96.93%** | 253 | 86.2% | 227 |
| 2020, tier 0.99 | 96.26% | 96.96% | 275 | 86.2% | 197 |

* **Order changes.** Of the 136 plain names whose order changed (old vs
  0.95), the written order is kept by 2020 in 96 and by the old table in 50.
  The remaining 2020 misses are short two-word names (SHERIFF MASRY,
  SJ SWANSON), which the position rules deliberately skip.
* **Role changes.** 5,135 names move from mostly-surname to mostly-first
  (JORDAN, HUNTER, MASON, LOGAN: popular for children since 1990), and 57
  the other way (HOWARD, RUSSELL, WARREN, FLOYD).
* **Gender flips.** Mostly names that shifted since 1990 (TAYLOR, RILEY,
  AVERY, AUBREY now mostly female). Most gender changes are names missing
  from the 1990 lists getting a gender (ILAN, ARYEH, DIVYA, PHILIPPE,
  GODWIN).
* **Caveats.**
  * The 2020 counts include children, and 990 officers skew older.
  * The gender check covers only 87 salutation-gendered names.
  * The written-order measure is a proxy: most Part VII names are written
    first name first, not all.

Comparison scripts and parses were scratch files; they can be rebuilt from
`data-raw/census_names.R`, plus a sequential `parse_name()` loop over the
same sample.

## Refreshing the table

1. When the Bureau publishes new lists, update the file names in
   `files_2020` in `data-raw/census_names.R`.
2. Run `source("data-raw/census_names.R")` from the package root. It
   downloads into `data-raw/census-names-src/` (git-ignored), writes sizes and
   SHA-256 hashes to `data-raw/census-names-src.csv`, rebuilds the table, and
   prints a comparison with the bundled one: sizes, role changes, gender
   flips.
3. Set `CENSUS_NAMES_SAVE=TRUE` and run it again to overwrite the bundle.
4. Re-run the tests, compare parses before and after (sequentially:
   `parse_names()` workers load the installed package, not the development
   code), and update R/data.R, NEWS.md and the gender-scoring vignette.

Download notes:

* R's `download.file()` gets the 2020 and 1990 files.
* The server answers any scripted request for the 2010 zip
  (`2010surnames/names.zip`) with an HTML "Request Rejected" page. The script
  stops on an HTML response rather than saving it. Fetch such files in a
  browser into `data-raw/census-names-src/` if they are ever needed.

## Open items (status 2026-11-23, evening)

* **Push: done.** `937d8d4` and `fd5bcdb` went to GitHub together with
  `fcc4afb` (version 0.1.0).
* **Two-word names with a title or an unlisted token: done**
  (`two_token_surname()` and the two-token case in `positional_tokens()`).
  In the 410,071 npmerger names only 160 two-word names hold a
  position-restricted title, and most were already right (JOHN BISHOP). The
  changes:
  * an unlisted *leading* token of one or two letters is initials
    (HM CHERRY, DC ALLEN, J MARKEL). A trailing one is left alone: it is
    usually a middle initial after a stripped surname (THOMAS H [LEED]);
  * a listed token with surname share >= 0.85 beats an unlisted one
    (NICKHATH SHERIFF, REETIKA KUMAR, SANRDA COHEN, JONETHAN MORRIS).
    A first try at 0.5 broke HOWARD SITRON, WARREN ORTLAND, LEE DORILL and
    RABBI IRWIN ZEPLOWITZ, since HOWARD (0.65), WARREN (0.63), LEE (0.81) and
    IRWIN (0.84) are also common first names;
  * a leading-only title before a token that is not mostly a given name, and
    not a single letter, is a title (SHERIFF MASRY, BROTHER STEWART).
    BISHOP JOHN and BISHOP J are left alone (possibly surname first).

  Result on the 9,608-name sample: 20 parses change, 18 fixes, 1 worse
  (WALLIS ANNENBERG: WALLIS has share 0.85+), 1 unclear (Gruzensky Denton).
  Cross-year consistency on synthid's linked slice: 410 of 829 people
  written more than one way parse the same, before and after.
* **Unlisted given names next to common given names: not changed.**
  A written-order rule (keep the last token as surname when the listed token
  is also a real surname, as in SEOKJIN JAMES) was tested against ground
  truth: two-word forms of linked people whose other forms are
  unambiguous ("FIRST M LAST"). There were only 270 such forms and 21 with
  exactly one unlisted token, and every rule variant scored the same on them
  (21 of 21). The proxy measures disagree by construction: written-order
  accuracy rewards the rule, and cross-year consistency penalises it. Without
  evidence, the rule was dropped. Revisit with a larger linked panel (the
  national synthid build) using the same ground-truth construction.
* **Age-weighted gender: tested, not adopted.** SSA national baby names
  (yob1880-yob2025; SSA refuses scripted downloads, so names.zip was
  downloaded by hand into `data-raw/ssa-names-src/`) were compared with the
  2020 census on 3,707 npmerger names whose salutation gives the gender
  (`data-raw/ssa_gender_eval.R`):

  | Source | Correct | Wrong | Unknown | Correct when known |
  |---|---|---|---|---|
  | census.names (2020) | 94.25% | 130 | 83 | 96.41% |
  | SSA births 1930-1995 | 94.17% | 124 | 92 | 96.57% |
  | SSA births 1940-1985 | 94.01% | 118 | 104 | 96.72% |
  | SSA births 1880-2025 | 94.50% | 128 | 76 | 96.47% |
  | SSA births 1990-2025 | 93.20% | 137 | 115 | 96.19% |

  The census and the board-age window disagree on 16 names (SSA right on
  9). No measurable gain, so no second gender table was added.
* **New: `MC` truncation.** `prep_name()` has `gsub(" MC .*$", " MC", x)`,
  which cuts everything after a standalone MC: CHARLES MC SPADDEN ->
  CHARLES MC, DENISE MC DERMOTT -> DENISE MC. MC should join the next word
  like the other particles.
