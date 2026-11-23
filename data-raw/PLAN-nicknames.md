# Plan: nickname / formal-name functionality + pilot

Drafted 2026-11-23. Status: v2 implemented (not committed). **Section 8 is current**;
sections 2-7 record the first design and its pilot, built on public nickname lists,
which v2 replaced with synthid's variant table. Original status line: v1 implemented and piloted the same
day. See **section 7** for the results and the next steps.

What was built: `data-raw/nicknames.R` (merged dataset), `R/nicknames.R`
(`nickname_lookup()` and helpers), `add_nicknames = FALSE` in `parse_name()` /
`parse_names()`, `tests/testthat/test-nicknames.R`, and the pilot in
`data-raw/pilot-nicknames/` (`pilot.R`, `sweep.R`, `results/`).

## 1. What already exists

**In peopleparser: nothing.** No nickname table, no code, no notes. The only
first-name resource is `census.names` (token counts in first/last position and
male/female counts). That table is useful here: it supplies frequency and gender
for choosing among formal forms.

**In synthid (sibling repo) there is a working first version:**

| Piece | Where | What it does |
|---|---|---|
| `nickname_table()` | `synthid/R/first_names.R` | Hand-written list: 70 formal names mapped to their nicknames. Many-to-many (`AL` -> `ALBERT`, `ALEXANDER`). |
| `first_name_roots()` | same | Name -> its formal roots (itself if unknown). |
| `nickname_equivalent_vec()` | same | `TRUE` only for a *direct* formal/nickname pair. Sibling nicknames (`LISA` vs `BETH`) are deliberately **not** equivalent. |
| `compare_first_names()` | same | Comparator for linking: exact 1, nickname 0.95, initial 0.6, otherwise Jaro-Winkler with a Soundex floor. |
| First-name relation check | `synthid/dev/partvii-panel/06k-name-checks.R` | Labels pairs as same / nickname / initial / different. Results are in `csa-test-*/name-checks-results.csv`. |

Lessons recorded in `synthid/dev/PLAN-board-interlocks.md`:

- The 70-name table is too small. Only 112 of 2,000 seeds had a formal name in
  it, while 16% of records use a nickname form. The note says to extend it with
  a standard list of about 1,000 names. This plan does that.
- About 2.7% of linked persons switch first-name form across years. That figure
  gives a recall target.
- Do not impute nicknames into blocking sets. Expanding every name to all its
  variants widens candidate sets with no gain. This argues for keeping the
  peopleparser output descriptive (columns) and not adding extra rows.

**networked990** (found after the first draft) already merges carltonnorthern
with synthid's table in `networked990/inst/refdata/nicknames.csv` (2,840 rows,
`formal, nickname, source`, ported from gather in October 2026).
`person_variant_keys()` in `R/person_names.R` expands first names to "keys".
It uses synthid's curated pairs first, and expands a formal name only to longer
formal names it is a prefix of (JOHN -> JOHNATHAN). The reason given:
carltonnorthern lists formal names under unrelated formal names (JOHN under
IAN, MARY under MARIAH, BILL under ROBERT). The pilot below confirms that
problem.

**Implication:** the dictionary should live in peopleparser, the lower-level
package. synthid and networked990 can then both use it. synthid then imports it in place of its hand-written table. That
migration is a later step.

## 2. Answers to the design questions

### Exact or phonetic matching?

Match exactly on the cleaned, upper-cased `first_name` token. Phonetic codes do
not suit nicknames:

- Most nickname pairs do not sound alike (`BOB`/`ROBERT`, `PEGGY`/`MARGARET`,
  `JACK`/`JOHN`, `TED`/`EDWARD`). Soundex misses them.
- Soundex merges distinct names (`JOHN`, `JEAN`, `JUAN`, `JOAN` all code to
  J500), so a phonetic match would attach the wrong family and sometimes the
  wrong gender.

Spelling variants (`CATHY`/`KATHY`, `STEPHEN`/`STEVEN`, `JON`/`JOHN`) are a
separate problem. They are better handled as a later, separate `variant` relation
than mixed into nickname lookup (see section 5). One cheap exception is safe for
v1: if the exact token misses, retry with a trailing `IE`/`Y`/`I` swap
(`KATIE`/`KATY`, `DEBBIE`/`DEBBY`), and flag that the retry was used.

### Can a name be both a nickname and a formal name?

Yes, often. The data is a graph, not two lists:

| Case | Examples |
|---|---|
| Nickname that is also a given name in its own right | `JACK`, `ALEX`, `BETH`, `JAMIE`, `NELL`, `ELIZA`, `MOLLY`, `SADIE`, `HARRY` |
| Nickname with several formal sources | `AL` (Albert, Alan, Alexander, Alfred), `PAT` (Patricia, Patrick), `CHRIS` (Christopher, Christine, Christian, Christina), `SANDY` (Sandra, Alexander), `TERRY` (Terence, Theresa), `FRAN`, `JO`, `SAM` |
| Formal name that is a nickname of another | `ELIZA` and `LISA` (Elizabeth), `JOHN`/`JACK`, `HENRY`/`HARRY`/`HAL`, `MARY`/`POLLY`/`MOLLY` |
| Archaic links few users would expect | `PATSY` (Martha), `PEGGY` (Margaret), `POLLY` (Mary), `SALLY` (Sarah), `NANCY` (Ann) |

So populate the two columns independently. Do not use an either/or rule:

- `first_name_nicknames`: the nicknames of `first_name` if it is a formal name.
- `first_name_formal`: the formal forms of `first_name` if it is a nickname.
- A name like `JACK` fills both: nicknames `JACKIE`, formal `JOHN`, `JACOB`.

### Is there a canonical form?

No database supplies a universal canonical form. The usual convention is the
"root" or formal name: the full name that a diminutive is derived from. It is
often not unique (`PAT`, `CHRIS`, `AL`), so a canonical form has to be
*chosen*. Proposed rule for `first_name_canonical`, one value:

1. If `first_name` is not a nickname, or is a nickname but is also an
   established given name more often than any of its formal forms, use it as is.
   (Rule 1 needs a threshold, settled in the pilot.)
2. Otherwise, among its formal forms keep those consistent with the parsed
   `gender` (`PAT` + F -> Patricia, `PAT` + M -> Patrick), using `census.names`
   male/female counts.
3. Among those, take the one with the highest `first_name_value` in
   `census.names`.
4. If gender is `U` and the top two candidates differ in gender, leave
   `first_name_canonical` equal to `first_name` and set
   `first_name_type = "ambiguous"`. Do not guess.

The canonical form is a blocking and grouping key for downstream linking. It is
not a claim about the person's legal name.

### Other useful content in name-variant databases

- **Relationship type:** diminutive/short form (`BOB`), spelling variant
  (`STEVEN`), cognate in another language (`JUAN`, `GIOVANNI`, `JOHANN` for
  John), feminine/masculine counterparts (`ROBERTA`), archaic or pet forms. Most
  free lists hold only the first type.
- **Gender** of each form. Gender resolves most multi-root nicknames.
- **Language or culture of origin.** Relevant because the 990 names are
  US-heavy, but Spanish, Korean and other names are present (see Defect 3).
- **Frequency or popularity, sometimes by decade.** Use it to rank candidates.
  It also shows that some "nicknames" (`JACK`, `MOLLY`) are top-100 birth names.
- **Direction and confidence.** A few lists mark which side is the formal
  name, or how common a link is.

Candidate sources (licences need checking before anything is vendored):

| Source | Content | Licence / use |
|---|---|---|
| `carltonnorthern/nicknames` (GitHub, ODU Web Science and Digital Libraries group) | About 1,100 formal names. Pairwise `name1,has_nickname,name2`, many-to-many, no gender. Built from a genealogy list, so it is US/English-centric and contains many archaic forms. | Apache-2.0, which is compatible with GPL-3. **Recommended base.** |
| synthid `nickname_table()` | 70 curated formal names | Ours. Merge it in. |
| `census.names` (already bundled) | Gender and frequency per token | Ours. Used for ranking and gender. |
| SSA baby names (`babynames` R package) | Frequency and gender by birth year | CC0. Optional, for "is this nickname also registered as a birth name?" |
| FEBRL name-standardisation tables | Nickname-to-standard lookups split by gender | Worth checking. Contents and licence not verified here. |
| Behind the Name | Rich data: variants, diminutives, cognates, gender, language | API key and terms of use. Do not vendor it. At most, use it for manual review. |
| Commercial (pdNickname and similar) | Gender, usage type, multilingual | Paid. Only if the pilot shows a large coverage gap. |

## 3. Proposed output

Add an opt-in argument `nicknames = FALSE` to `parse_name()` and `parse_names()`.
The default output stays unchanged and fast. When `TRUE`, append:

| Column | Example: `RICHARD` | `DICK` | `PAT` (F) | `JACK` | `KAREN` |
|---|---|---|---|---|---|
| `first_name_type` | formal | nickname | nickname | both | unknown |
| `first_name_formal` | | RICHARD | PATRICIA;; MARTHA | JOHN;; JACOB | |
| `first_name_nicknames` | DICK;; RICH;; RICK;; RICKY;; RICHIE | | | JACKIE | |
| `first_name_canonical` | RICHARD | RICHARD | PATRICIA | JACK | KAREN |

- Lists use the `";; "` separator and are ordered by census frequency, most
  common first. Gender-inconsistent forms are dropped when gender confidence is
  high. (Example: `PAT` (F) drops Patrick.)
- Sibling nicknames are never listed (`BETH` does not list `LISA`), which keeps
  synthid's rule.
- `first_name_type` values: `formal`, `nickname`, `both`, `ambiguous`,
  `unknown`, `initial`. An initial is skipped, not looked up.
- Name: these columns follow the package's `first_name` style. The user's
  `name_nickname` and `name_proper` work equally well. Pick one before
  implementing.

Exported helpers, all vectorised and usable without parsing:
`get_nicknames(x)`, `get_formal_names(x, gender = NULL)`,
`canonical_first_name(x, gender = NULL)`, `nicknames` (the dataset).

## 4. Implementation steps

1. **`data-raw/nicknames.R`**: download `names.csv` from carltonnorthern, pinned
   to a commit SHA. Upper-case, trim, dedupe, drop self-links. Merge synthid's
   70-name table and tag each row with a `source`. Join `census.names` counts.
   Save `data/nicknames.rda` as a keyed `data.table` with columns
   (`formal`, `nickname`, `source`). Record the Apache-2.0 attribution in
   `R/data.R` and in `inst/COPYRIGHTS`.
2. **`R/nicknames.R`**: build the formal->nickname and nickname->formal indexes
   once and cache them in a package environment, as synthid's
   `nickname_cache()` does. Write the helpers and the canonical rule from
   section 2.
3. **Wire into `parse_name()` / `parse_names()`**: run after gender is set,
   because the rule needs gender.
4. **Tests**: cover the cases in the section 2 table (`PAT`+F/M/U, `AL`,
   `JACK`, `BETH`/`LISA` siblings, initials, an unknown name, `KATIE`/`KATY`
   retry). Add fixtures to `data-raw/hard_cases.R`.
5. **Docs**: README section, NEWS entry, pkgdown reference.
6. **Later, in synthid**: point `nickname_table()` / `first_name_roots()` at
   `peopleparser::nicknames`, then rerun its seeded test (06j) and its threshold
   tuning.

## 5. Pilot experiment (small sample)

Goal: measure, before committing to the design, (a) how much of a real 990 name
stream the dictionary covers, (b) how often the canonical form is right, and
(c) whether it recovers real same-person nickname switches better than synthid's
70-name table. The pilot can run as a script in `data-raw/pilot-nicknames/`
before any package code is final.

**Samples**

- **S1, coverage: 1,000 names** from `get_example_names(1000)`, plus a 2,000-row
  random draw from the synthid 2010-2024 Part VII slice. Parse both, then look up
  each `first_name`.
- **S2, accuracy: 200 hand-labelled records.** Stratify S1's dictionary hits:
  100 unambiguous nicknames, 60 multi-root nicknames (`PAT`, `CHRIS`, `AL`,
  `TERRY`, `SANDY`, `JO`...), and 40 `both`-type names (`JACK`, `BETH`,
  `ALEX`). Label the correct formal form, or "is itself the name", using the
  person's other filings in synthid where possible.
- **S3, linkage truth: same-person pairs whose first names differ.** Take these
  from synthid's linked clusters (06k `first_name_relation`, `csa-test-*`
  results). As a negative set, take different-person pairs in the same
  organisation that share a surname.

**Metrics**

| # | Metric | On | Target (to confirm) |
|---|---|---|---|
| M1 | % of first names that are formal / nickname / both / unknown. Also the top 50 unknown first names, to look for gaps. | S1 | Report only |
| M2 | Nickname recall: share of nickname-form first names that are recognised | S1, hand-checked | >= 90% |
| M3 | Canonical accuracy, unambiguous / multi-root / both-type | S2 | >= 97% / >= 85% / >= 80% |
| M4 | True formal form appears in `first_name_formal` | S2 | >= 95% |
| M5 | Same-person differing pairs called equivalent (same canonical, or a direct pair): new dictionary vs synthid's 70-name table | S3 | Large gain over the old table |
| M6 | Different-person pairs wrongly called equivalent | S3 negatives | No rise over the old table |
| M7 | Runtime overhead of `nicknames = TRUE` in `parse_names()` on 1,000 names | S1 | < 10% |

**Decisions the pilot settles**

- The rule-1 threshold: when a nickname-shaped name such as `JACK` or `BETH`
  counts as its own canonical form.
- Whether the gender filter needs a confidence cut-off, or can use the parsed
  gender directly.
- Whether the gaps in M1 justify a second source (FEBRL, SSA) or a phonetic
  spelling-variant pass in v2.
- Whether the archaic links (`PATSY`->Martha, `POLLY`->Mary) cause false
  equivalences in M6 and should be dropped or flagged.

## 6. Out of scope for v1

- People who go by their middle name (`J ROBERT SMITH`).
- Cognates across languages (`JUAN` <-> `JOHN`).
- Spelling-variant matching beyond the `IE`/`Y` retry.
- Nickname handling for surnames.

## 7. Pilot results (2026-11-23)

### What was added

- **Sources.** carltonnorthern (2,827 rows, Apache-2.0, pinned commit
  `ed160b3`). onyxrev/common_nickname_csv (1,431 rows, public domain, pinned
  commit `b28d65b`). synthid's 70-name table (159 pairs). Snapshots are in
  `data-raw/nicknames-src/`.
- **Merged result.** 2,729 pairs, 1,183 formal names, 1,353 nicknames. onyxrev
  adds only 29 new pairs, but it confirms 1,338 carltonnorthern pairs. That
  confirmation is the "cross-check": a pair that synthid curates or that two
  sources list ranks first.
- **Two-way pairs oriented.** 161 pairs were listed in both directions, for
  example `DICK has_nickname RICHARD`. Without the fix, RICHARD gets DICK as a
  "formal" form and most names are typed `both`. Rule: the longer name is the
  formal one; at equal length, the name more common as a census first name.
- **Output columns.** As in section 3, plus `nickname_match`
  (`exact` / `suffix_variant`).

### Data

synthid's `dev/data/linked_slice.rds`: 33,984 Part VII records, 1,000 orgs,
2010-2012, linked into 15,409 persons. Re-parsed with the current parser
(16,471 unique raw names in 27 s, in parallel).

**Caveat:** synthid made these links using its own 70-name table. Same-person
pairs that table covers are linked by construction, so "old table" recall is
flattered.

### Coverage (M1)

| first_name_type | persons | % |
|---|---:|---:|
| formal | 4,813 | 31.2 |
| both | 4,891 | 31.7 |
| nickname | 2,535 | 16.5 |
| unknown | 2,880 | 18.7 |
| initial | 182 | 1.2 |
| ambiguous | 79 | 0.5 |

`get_example_names(1000)` gives a similar split: 37 / 29 / 15 / 18 / 2 / 0.1.
About a quarter of records get a canonical form that differs from the first
name.

The unknowns are mostly ordinary given names with no nickname in either source:
KAREN, BRUCE, TODD, KEITH, WAYNE, CRAIG, DAWN, DEAN, ADAM. That is correct
behaviour, not a gap. A coverage gap would show up as unknown *nicknames*, and
none appear in the top 60 (`results/M1-top-unknown-first-names.csv`).

### Matching the same person and different people (M5, M6), and the settings sweep

There are 204 same-person pairs with differing first names (no initials), and
297,086 different-person pairs (two people on the same return in the same
year, with different first names). Full grid: `results/sweep.csv`.

| Rule (default settings) | same-person pairs matched | different-person pairs matched, per 1,000 |
|---|---:|---:|
| old: synthid 70-name direct pairs | 56.4% | 2.17 |
| new: same canonical | 56.9% | 2.76 |
| new: same canonical, or a well-supported direct pair | 65.2% | 3.41 |
| new: same canonical, or any direct pair | 69.6% | 3.95 |

- **Recall.** The new table connects 27 same-person pairs the old one missed
  (JEFF/JEFFREY, DOUG/DOUGLAS, BRAD/BRADLEY, JUDY/JUDITH, RANDY/RANDALL,
  ROD/RODNEY, VICKI/VICKY) and loses none.
- **The remaining ~30% are not nicknames.** They are spelling variants and
  typos: STEVEN/STEPHEN, PHILLIP/PHILIP, MICHELE/MICHELLE, GALE/GAIL,
  WIILIAM/WILLIAM, MARGERET/MARGARET. No nickname list fixes these; they need
  the separate spelling layer (synthid's Jaro-Winkler already covers them).
- **Different-person "matches"** are mostly two different people with
  same-root names on one board (JIM and JAMES: 79; JACK and JOHN: 69; TOM and
  THOMAS: 67). That is inherent in any nickname equivalence; surname and other
  fields have to separate them. The avoidable part is the bad links: BILL/ROBERT
  (70), JOHN/JONATHAN, ERIC/RICK, ANN/NANCY, BILL/FRED, IAN/JOHN, CHRIS/KRISTIN,
  MARY/ROSEMARY, PATRICK/PETER, LISA/MELISSA, ROBIN/ROGER, JOE/JOSHUA.

### Canonical accuracy (M3), from people seen under both a nickname and its formal name

141 people. Test 1: both of their names get the same canonical (what a grouping
key needs). Test 2: the nickname's canonical is exactly the formal name they
also used.

| Setting | same canonical | exact formal |
|---|---:|---:|
| `rank = "support"`, `keep_ratio = 1` (**default**) | **81.6%** | 80.1% |
| support, 0.5 | 79.4% | 78.7% |
| support, 0.25 | 67.4% | 66.7% |
| frequency, 1 | 77.3% | 75.9% |

- Single-root nicknames scored 18/18. Multi-root nicknames scored 95/123 (77%).
- **Many misses are spelling-variant formal names, not wrong people:**
  JEFF -> JEFFREY vs JEFFERY, STEVE -> STEVEN vs STEPHEN, PHIL -> PHILLIP vs
  PHILIP, JON -> JOHN vs JONATHAN.
- **Real misses come from bad source links.** These names are being rewritten
  at the default setting (`results/rewrites-default.csv`):

| first name -> canonical | records | verdict |
|---|---:|---|
| PETER -> PATRICK | 90 | wrong (Irish genealogical use) |
| FRED -> WILLIE | 41 | wrong |
| ANN -> NANCY | 42 | wrong direction (NANCY is a pet form of ANN) |
| JANE -> VIRGINIA | 30 | wrong |
| LEE -> SHIRLEY | 24 | wrong |
| JAY -> JACOB, JILL -> JULIA, LYNN -> LINDA, ANNE -> ANNA | 20-33 each | wrong or doubtful |
| CARL -> CHARLES, CARRIE -> CAROL | about 20 each | doubtful (a cognate; a loose link) |

  These come from carltonnorthern's genealogical links. onyxrev copies many of
  them, so "two sources agree" does not protect against them.

### Runtime (M7)

`parse_names()` on 1,000 names takes 3.9 s, and 5.1 s with
`add_nicknames = TRUE`. The lookup alone takes 1.3 s, about +32%. That misses
the 10% target. Cause: per-name census joins inside `lookup_one()`.

### Conclusions and next steps

1. **The design works.** Exact matching, independent formal and nickname lists,
   a gender-aware canonical form, and "ambiguous" when gender is unknown. The
   defaults (`support`, `keep_ratio = 1`) beat every alternative tried.
2. **Fix the source links before relying on `first_name_canonical`.** Add a
   small reviewed block list to `data-raw/nicknames.R`, starting with the
   rewrite table above and the different-person bad links. Then re-run
   `sweep.R`. Expected effect: same-canonical agreement well above 82%, and the
   avoidable different-person matches gone. The first ~60 rows of
   `results/rewrites-default.csv` cover most records and can be reviewed in
   about 15 minutes.
3. **Treat spelling variants as one name** (STEVEN/STEPHEN,
   JEFFREY/JEFFERY, PHILIP/PHILLIP). Either add a short curated variant-family
   table, or have the canonical step collapse formal names within edit
   distance 1-2 that share a nickname. That fixes most of the remaining M3
   misses.
4. **Speed.** Precompute census counts and gender shares for every table name
   inside `nick_index()`, then vectorise. That should remove most of the 1.3 s.
5. **Hand labels.** `results/S2-hand-label-sample.csv` (200 rows: 100
   unambiguous, 60 multi-root, 40 both-type) has blank `label_correct_formal`
   and `notes` columns. These give an accuracy figure that does not depend on
   synthid's links.
6. **Then** point synthid's `nickname_table()` and networked990's
   `nickname_map()` at `peopleparser::nicknames`.

## 8. v2: synthid's variant table and the canonical rule (current)

### What changed

- **Source.** The public lists (carltonnorthern, onyxrev) were replaced by
  synthid's `dev/name-variants/first-name-variants.csv` (commit `07c320f`),
  bundled as `first_name_pairs`. It has 24,972 pairs. 1,007 are reviewed
  lexicon pairs (nickname, spelling, cognate, compound), each seen in 25+
  people. The rest are unreviewed sound-alikes and misspellings. Each row
  carries people counts, national frequencies and female shares. Build script:
  `data-raw/first_name_pairs.R`. It drops the matcher-specific columns (fuzzy
  scores, public-table flags, chain summaries) and adds `formal`, which says
  which side of a nickname pair is the formal name. Three pairs are
  overridden by hand.
- **Canonical rule.** Full text in `?nickname_lookup` and the vignette.
  1. Spelling root: the most common spelling, reached by steps to more common
     spellings. Misspellings count only when the rare form has fewer than
     1,000 records.
  2. One nickname step, for families mainly used as a nickname, and only when
     the nickname use is at least `min_nick_rate` = 0.2% of the name's
     records. That keeps MARK from resolving to MARCUS.
  3. Candidates are the direct formal partners, grouped by spelling root and
     weighted by people. Gender drops the other gender's candidates. The top
     group must hold `min_share` = 60%; otherwise the name is `ambiguous`.
  4. Chains are never followed.
- **New** `first_name_variants(x)`: the whole family behind a canonical name,
  with relation and `via` for each member, plus related names that are not
  merged.
- **New vignette** `vignettes/canonical-first-names.Rmd`, with figures from
  `data-raw/vignette-figures.R`.

### Pilot (`data-raw/pilot-nicknames/pilot.R`, results in `results/`)

Same slice as before: 33,535 records with a full first name. The same-person
test is partly circular, because the table was built from the same kind of
within-org person links. The different-person test is not.

| Rule | same-person pairs matched (204) | different people matched, per 1,000 | nickname+formal people sharing a canonical name |
|---|---:|---:|---:|
| old 70-name table | 56.4% | 2.17 | - |
| v1 (public lists), same canonical | 56.9% | 2.76 | 81.6% |
| **v2 default, same canonical** | **83.3%** | **2.85** | **93.4%** |
| v2, same canonical or lexicon pair | 89.2% | 3.39 | 93.4% |

- **Sweep** (`results/sweep.csv`).
  - `min_share` 0.5 / 0.6 / 0.75 trades ambiguous records (0.1% / 1.2% /
    1.9%) against small recall changes.
  - `min_nick_rate = 0.002` (against 0) cuts rewritten records from 30.4% to
    26.4% and different-person matches from 3.01 to 2.85, and loses one
    same-person pair.
  - Adding the sound-alikes raises recall to 85% but false matches to 3.5.
    Left off.
- **Rewrites.** All of the top 40 are correct (`results/rewrites.csv`).
- **Ambiguous names.** The 33 ambiguous names are the expected ones: KATHY,
  PAT without gender, JULIE, JAN, HARRY, AL, BERT (`results/ambiguous.csv`).
- **Speed.** About 0.3 s for 15,000 names. The index is built once per
  session.

### Open items

1. **Gender is circular.** Both the parse's gender and the table's female
   shares come from the first name. PAT parses as F at 66% confidence, so it
   stays ambiguous unless a salutation gives the gender. A gender source
   independent of the first name (middle name, title, other records of the
   person) would resolve more names.
2. **Unreviewed rows.** Misspelling rows above the 1,000-record cap and all
   sound-alike rows are unreviewed, so they are not merged. Promote them
   after the review synthid plans for its candidate gates.
3. **Downstream use.** Point synthid's `compare_first_names()` and
   networked990's `nickname_map()` at `peopleparser::first_name_pairs`, and
   use `first_name_canonical` as a blocking key.
4. **Refresh.** Re-run `data-raw/first_name_pairs.R` when synthid rebuilds
   the table. Check the orientation review list it prints, then re-run the
   pilot and `data-raw/vignette-figures.R`.
