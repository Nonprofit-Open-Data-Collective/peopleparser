# Parse-fail notes (incoming from synthid QA)

A running to-do list of name-parse defects found downstream by **synthid**, which
links Form 990 Part VII records into cross-year persons and then audits each
linked cluster for internal inconsistency. When the *same person* is parsed
differently across years, the disagreeing record usually exposes a parse error,
and the person's other years supply the **expected** value. synthid emits these
as structured logs (see *Feeding this file*, below); this note tracks what to do
with them.

Provenance: `synthid::flag_links()` / `parse_fail_log()` / `parse_fail_tokens()`.
First pass: 2026-08-14, 33,984-record 2010–2024 slice → 32 defective records.

## Two lists this repo maintains

Post-nominal / honorific stripping is driven by the **`prx` (prefixes)** and
**`sfx` (suffixes)** character vectors defined inline in
[`R/utils.R`](../R/utils.R). (A former `data-raw/gen-prefixes-and-suffixes.R`
generator was broken and unused — its `.Rdata` outputs were never loaded — and
was deleted 2026-08-14; edit `R/utils.R` directly.)
[`R/known_titles.R`](../R/known_titles.R)
`known_titles()` is the human-readable reference table (`abbr`/`label`/`type`).
A token must be in **`prx`/`sfx`** to actually be stripped; add it to
**`known_titles()`** too, to keep the reference complete. (Observed: `EdD`, `CAE`
strip correctly but are absent from `known_titles()` — the two lists have already
drifted; worth reconciling.)

---

## Defect 1 — post-nominal credentials leak into `last_name`  ✳ highest priority
<!-- STATUS 2026-08-14: FIXED. Added RTR, FASRT, RDMS, RVT, LCSW, MHA, CNMT,
     CRA, MSRS to `prx` in R/utils.R and to known_titles() (plus CAE, which was
     already stripping but undocumented). RM now handled: it strips only inside
     a trailing run of known credentials that also contains >=1 unambiguous
     credential (trailing_ambiguous_credentials() in R/parse_one_name.R), so
     "... RDMS RM" strips but "MA LIN" and standalone "LEE RM" do not.
     Regression tests in tests/testthat/test-parse.R + fixtures in
     data-raw/hard_cases.R; full suite green. -->


Credential runs after the surname are not stripped, so they end up glued into the
parsed surname, e.g. `"Salvatore Martino EdD RTR FASRT CAE"` →
`last_name = "RTR-FASRT-MARTINO"` (expected `MARTINO`). All of the following are
**absent from both `prx` and `known_titles()`**. Add them (radiologic-tech
credentials dominate this batch; all are generic health-care post-nominals):

| abbr | n_rec | proposed label | proposed type |
|------|------:|----------------|---------------|
| `RTR`   | 6 | Registered Technologist (Radiography) | Professional Credential |
| `FASRT` | 4 | Fellow, Am. Society of Radiologic Technologists | Professional Credential |
| `RDMS`  | 4 | Registered Diagnostic Medical Sonographer | Professional Credential |
| `RVT`   | 4 | Registered Vascular Technologist | Professional Credential |
| `LCSW`  | 3 | Licensed Clinical Social Worker | Professional Credential |
| `MHA`   | 3 | Master of Health Administration | Academic Degree |
| `CNMT`  | 2 | Certified Nuclear Medicine Technologist | Professional Credential |
| `CRA`   | 2 | Certified Radiology Administrator | Professional Credential |
| `MSRS`  | 1 | Master of Science in Radiologic Sciences | Academic Degree |
| `RM`    | 2 | Registered Tech. (Mammography) — **ambiguous** | Professional Credential |

**`RM` and other 2-letter tokens** (`RM`, and existing `BS`/`BA`/`DO`/`PE`) are
easily confused with initials. Prefer to strip a short token only when it sits
inside a *trailing run* of ≥1 already-known credential, not standalone — otherwise
"MA LIN" (Ma Lin) loses `MA`. synthid deliberately excludes these from its own
detector's default set for the same reason.

## Defect 2 — honorific glued to the given name with no space  (tokenizer)
<!-- STATUS 2026-08-14: FIXED. split_glued_honorific() in R/parse_one_name.R
     splits a leading personal title (MR/MRS/MISS/MS/DR) off a token when the
     remainder is a strong census given name AND the whole token is not itself a
     census name -- exactly the FREDDIE/FRANK/DREW guard. Runs always-on inside
     deglue_tokens(); zero regressions across the 1,285-name corpus. -->

`MR` *is* known, but with no separating space the token is never split:
`MRWILLIAM` → first `WILLIAM`, `MRJOHN` → `JOHN`, `MRHENRY`, `MRTOM`, `MRJASON`,
`MREDWARD` (7 records, concentrated at BROOKSTONE SCHOOL INC). This is a
tokenizer/normalization gap, not a missing token.

Suggested rule: if a token has no leading-honorific split but *starts with* a
known personal-title prefix and the remainder is a valid census given name, split
it. **Guard** against real names that merely start with a short abbreviation —
`FREDDIE` (`FR`+`EDDIE`), `FRANK`, `DREW` — by requiring the remainder to be a
census name **and** the full token to not itself be a known name. (synthid's
detector uses exactly this guard; without it `FREDDIE`→`EDDIE` false-fired.)

## Defect 3 — single stray initial glued to the surname  (tokenizer, lower priority)
<!-- STATUS 2026-08-14: IMPLEMENTED BUT OFF BY DEFAULT. split_glued_initial()
     exists (R/parse_one_name.R) and is exposed via parse_name(split_initials=)
     / parse_names(split_initials=), default FALSE. It CANNOT be made safe on a
     single record: e.g. KYUN (Korean given name, absent from census) scores as
     a surname (last=8933) HIGHER than the true target WOOLFOLK (last=3295), so
     "SUNG KYUN WOO" mis-splits to K+YUN and "DENNY BREAMER" to B+REAMER. No
     frequency threshold separates true from false. Enable only where synthid's
     cross-year consensus can vet the output (the provenance this file already
     relies on). The apostrophe case "O'WEEKS"->"WEEKS" is NOT handled. -->

A middle initial that lost its space is read as part of the surname:
`WILLIAM C WOOLFOLK` → `CWOOLFOLK`; also `CMARTIN`→`MARTIN`, `BMACKEY`→`MACKEY`,
`BKEY`→`KEY`, `WSWIFT`→`SWIFT`, `WSMITH`→`SMITH` (8 records). One apostrophe case:
`O'WEEKS` → `OWEEKS` (expected `WEEKS`). Hard to catch from a single record (bare
`WSMITH` is not obviously wrong); synthid catches it only by cross-year consensus.
A candidate heuristic: a surname beginning with a single consonant immediately
followed by a capitalized run that is itself a valid surname.

---

## Feeding this file (the synthid → peopleparser handoff)

`synthid::dev/generate_link_review.R` writes three artifacts:

* **`peopleparser_token_candidates.csv`** — the *structured* bucket. One row per
  leaked token: `token, field, defect_type, n_records, n_persons, example,
  in_known`. `in_known` is checked against `toupper(known_titles()$abbr)`, so
  **`subset(x, !in_known)` is the ready-to-paste add-list** (Defect 1 above came
  straight from it). Regenerate and re-diff on each new slice.
* **`peopleparser_suspect_variants.csv`** — the *eyeball* bucket. One row per
  person for the defect-adjacent categories (`parser_honorific_glue`,
  `surname_credential`, `surname_compound`, `review`): `names_seen`,
  `first_seen`, `last_seen`. Skim for parse errors the token rule didn't catch
  (transliteration, hyphenation, order).
* **`peopleparser_parse_fails.csv`** — record-level `input → wrong → expected`
  with `OBJECTID`/`TABLE_ID` keys; use these rows directly as regression fixtures
  in `tests/` (and `data-raw/hard_cases.R`).

Workflow: run the generator on a fresh slice → paste `!in_known` tokens into
`prx`/`sfx` + `known_titles()` → copy a few parse-fail rows into `hard_cases.R` →
rebuild → the tokens drop out of the next slice's candidate list.
