# Plan: fix the problems in WORKERS-AND-DATA-LOADING.md

Drafted 2026-11-23 against `3001f96`. Phases reordered the same day (speed
before name order).

## Status (2026-11-23, evening)

Phases 1-3 implemented together (uncommitted at the time of writing):

* **Phase 1:** `R/data_cache.R` loads `census.names` and `first_name_pairs`
  once per session into `.pp_data`.
* **Phase 2:** `parse_names(workers = NULL)` with the sequential default;
  workers report a version/build fingerprint, and a mismatch stops the call.
  Workers parse chunks (four per worker) rather than one name per task.
* **Phase 3:** the first option was enough. `get_census_data()` uses a hashed
  name -> row index built once per session (`census_row()`); the old keyed
  join is kept as `get_census_data_join()` for an identity test.
  `determine_surname()` ranks in base R instead of dplyr. The profile before
  the change: 92% of parse time in `get_census_data()`, mostly the join's
  `chmatch`, called many times per name by `split_glued_honorific()`.
* **Speed** (20,000 npmerger Part VII names, names a second):

  | Call | 0.1.0 | Now |
  |---|---|---|
  | `peopleparser::parse_name()`, not attached (200 names) | 6 | 370 |
  | `parse_name()`, attached | 94 | 2,040 |
  | `parse_names()`, five calls of 200 | 73 | 1,790 |
  | `parse_names()`, 20,000 (default) | 586 | 1,660 |
  | `parse_names(workers = 7)`, 20,000 | - | 3,860 |

  0.1.0 started 23 workers per call on this 24-core machine. The 20,000
  parses are identical to 0.1.0's. 410,000 names now take about
  4 minutes sequentially, under 2 with 7 workers.
* **Phase 4 (two-token names):** done in 0.2.0. Hand labels were replaced by
  filing-convention labels (`data-raw/name_order_eval.R`): 758,388 labelled
  two-word names instead of ~200. Chosen settings: a = 20, unlisted
  s_u = 0.85, prior odds 30, lone letter s = 0.05. Order errors on the labels:
  12,463 -> 2,687. Still open: the same smoothing for three or more tokens
  (`check_if_surname()`, `determine_surname()`), and unlisted given names
  before a common given name (`SEOKJIN JAMES`).

## Where things stand

| Problem (from the note) | State in `3001f96` |
|---|---|
| Datasets reload on every lookup when peopleparser is not attached | Still there: `get_census_data()` and `get_variants_table()` use `if (!exists(...)) utils::data(...)` |
| `parse_names()` starts its own cluster on every call | Still there: `future::plan(multisession, availableCores() - 1)` inside the function |
| Name-order flips (259 names in the CSV) | 28 of 259 fixed by `e28414e` (all "word 1 not in census"); the other 231 come from `determine_surname()` comparing raw surname shares with no prior and no weight for thin evidence |
| `S KRISHNAN` -> last name `S` | Fixed by `e28414e` (a leading unlisted token of one or two letters is initials) |

## Phase 1: load each dataset once (small, no output changes)

1. New `R/data_cache.R`: a package environment `.pp_data` and accessors
   `census_names()` and `variant_pairs()`, each calling
   `utils::data(..., package = "peopleparser", envir = .pp_data)` once.
2. `get_census_data()` and `get_variants_table()` use the accessors.
   `R/nicknames.R` is also edited by other sessions, so check `git status`
   and coordinate before touching it.
3. Tests:
   * in a `callr` subprocess with peopleparser loaded, not attached, parse
     600 names, and assert that `utils::data()` ran once per dataset (trace
     count);
   * assert that parses are identical to the attached run.
4. Check: unattached in-process speed goes from about 5 to about 130 names
   a second (the note's measurements). `R CMD check` clean.

Then npmerger can drop its attach/detach step.

## Phase 2: `parse_names()` stops managing workers (behaviour change)

Decided 2026-11-23: an argument, not a second `parse_names_parallel()`
function, with a sequential default. Phase 3 makes sequential parsing fast
enough that workers rarely pay for their startup.

1. Remove the internal `future::plan()` call. Add `workers = NULL`:
   * `NULL` (default): use whatever plan the caller set. With the default
     sequential plan, it runs in-process and never starts workers on its own.
   * an integer above 1: start one multisession cluster for this call,
     restore the caller's plan on exit, and document that it starts new
     processes.
   * `1`: sequential, whatever plan the caller set.
2. When the call runs on workers, have each one report peopleparser's
   `Version` and `Built`/`RemoteSha`. Stop with a clear message if any
   differs from the calling session (npmerger's wording: "Was it
   reinstalled while R was running?").
3. Tests:
   * the default runs without a cluster;
   * `future::plan(multisession, workers = 2)` gives identical output;
   * `workers = 2` restores the caller's plan.
4. Docs: the `parse_names()` help, NEWS (a breaking default: plain calls are
   now sequential), and the README timing example.

## Phase 3: speed (no output changes)

`parse_name()` looks up census rows several times per name. After phase 1,
about 130 names a second means about an hour for 410,000 names. Options,
cheapest first:

* a session cache of token lookups inside `get_census_data()`;
* `parse_names()` collects a batch's unique tokens, looks them up in one
  keyed join, and hands the result to `parse_name()`.

Target: 1,000+ names a second sequentially, with identical output.

## Phase 4: name order with a written-order prior (changes parses)

1. Replace the two-token ranking (`determine_surname()` plus
   `two_token_surname()`) with `two_token_order()`:
   * **Smoothed surname share:** s = (last + a) / (first + last + 2a), with
     pseudo-count a = 1,000. Thin evidence moves toward 0.5, so RUVIN, with
     106 first-name records, no longer counts as a first name.
   * **Unlisted tokens:** s = s_u, 0.5 to start (tuned in step 2).
   * **Swap rule:** keep the written order unless the odds that the name is
     written surname first, s1(1-s2) / ((1-s1)s2), exceed a prior of 20.
   * **Hard rules:** a single letter is never the surname; a leading
     unlisted token of one or two letters stays initials.
   * **Retired:** the 0.85 rule from `e28414e`, which the prior supersedes
     (it also fixes WALLIS ANNENBERG).
2. Tune a, the prior odds, and s_u. Feasibility check already run on the
   294,015 plain two-word npmerger names:

   | rule | written order kept | swaps | listed flips restored (270 rows*) | surname-first tests swapped (6) |
   |---|---|---|---|---|
   | current | 96.85% | 9,258 | 25 | - |
   | odds 5, a 1,000 | 98.16% | 5,410 | 242 | 6 |
   | odds 20, a 1,000 | 98.71% | 3,797 | 263 | 6 |
   | odds 100, a 1,000 | 99.11% | 2,629 | 270 | 6 |

   *The CSV's 259 names occur as 270 distinct raw spellings.

   * **Swaps look right** on a sample: KIDDER MELISSA, COX JERRY,
     STANFORD GARY, SMITH TONY. The 6 surname-first tests are SMITH JOHN,
     GARCIA MARIA, and similar.
   * **Weak spot:** an unlisted word before a given name (ADDISCOTT LYNN,
     KAUWELA NEAL) is kept in written order, but is probably written
     surname first. s_u above 0.5 may fix it.
   * **Labels needed.** Written-order rate and cross-year consistency are
     both biased: one rewards the prior and the other penalises it. So
     label a sample: about 200 names on which the current and new rules
     disagree, stratified by pattern, with a first pass by Claude checked
     by a person. Pick the settings on those labels.
3. Three or more tokens: `check_if_surname()` uses the raw share too (rare
   first-name entries). Apply the same smoothing as a separate step, with
   its own before/after.
4. Tests and fixtures: the regression names in the note (RICHARD RUVIN,
   HARRIS MORRISON, FOSTER MCDONALD, HARRIS NYDICK, ARBANNAH HOLLAND,
   S KRISHNAN, Michael Fania, Dan Vitina, Bill Noah, Jim Lanard, Mark
   Michael, Clay Morgan, Coleman Levy, Lee Kort, Shengli Yuan), plus
   SMITH JOHN, GARCIA MARIA and WALLIS ANNENBERG. Add them to
   `data-raw/hard_cases.R` and testthat.
5. Docs: the `determine_surname()` help, the two-token section of the
   name-order vignette, and NEWS with before/after numbers.

## Order, versions, coordination

* **Order:** phase 1, then 2, then 3, then 4, one commit each. Phases 1 and
  3 change no parse output. Speed (3) moved ahead of name order (4) on
  2026-11-23, so the name-order tuning runs on the fast parser.
* **Versions:** 2 changes the `parse_names()` default and 4 changes
  parses, so release them as 0.2.0. npmerger keys its saved parses by
  parser version and commit, so it will re-parse.
* **Coordination:** other sessions edit this folder (nicknames,
  `first_name_pairs`). Stage only this work's files, and tell the npmerger
  side when phases 1 and 2 land.

## Decisions needed

1. **`parse_names()` default: decided.** Sequential unless the caller sets
   a plan, with `workers = n` to start workers for one call. No separate
   parallel function.
2. **Labels for phase 4:** label the ~200-name disagreement sample by hand,
   or accept Claude's first-pass labels with spot checks.
