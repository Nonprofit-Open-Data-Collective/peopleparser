# Workers, data loading, and name-order flips

Dev note, 2026-11-23. Two related defects in `parse_names()`, found when
npmerger started parsing all of its Form 990 Part VII names (about 410,000
distinct names) with peopleparser: they broke a long build and hid a large
slowdown. A third section covers names whose first and last name v0.1.0
swaps (see *Name-order flips in v0.1.0*).

## Summary

1. **`parse_names()` starts its own worker cluster on every call.** It sets
   `future::plan(multisession, workers = availableCores() - 1)` inside the
   function. Each call therefore starts fresh R processes, and each one
   loads whatever peopleparser is installed at that moment. A long job
   that calls it repeatedly can end up with workers on a different version
   than the session that called it.
2. **Bundled datasets reload on every lookup unless the package is
   attached.** `get_census_data()` and `get_variants_table()` check
   `exists("census.names")` and otherwise call `utils::data()`. When
   peopleparser is only loaded, not attached (for example when another
   package imports it), `exists()` is always `FALSE`. The 165,000-row
   census table is then read from disk on every lookup, about 0.04 s each,
   several times per name. Parsing falls to about 5 names a second, and the
   worker cluster in (1) hid that.

3. **v0.1.0 swaps first and last name in 259 of 42,774 two-word names**
   that `7f06080` parsed in written order (while fixing 726 the other
   way). Most have a common given name written first: `RICHARD RUVIN` →
   last name `RICHARD`, `HARRIS MORRISON` → `HARRIS`, `S KRISHNAN` → `S`.

Recommended fixes:

* Load each dataset once into a package-level environment (or use
  `peopleparser::census.names`).
* Remove the internal `plan()` call, and let the caller choose the plan or
  a worker count.
* Longer term, vectorize the census lookups per batch.
* For name order, keep the written order unless the evidence for a swap is
  strong, never make an initial the surname, and weigh Census shares by how
  many records they rest on.

## What happened

* At 15:11 an npmerger build started. Its session loaded peopleparser
  `7f06080`.
* The build calls `parse_names()` once per 20,000-name chunk, so it started
  a new 23-process cluster about 20 times.
* At 15:53, peopleparser 0.1.0 was installed into the shared user library
  by another session.
* At 15:59, workers started after that install loaded 0.1.0, while the
  build's session still ran `7f06080`. A worker failed with
  `data set 'census.names' not found`, and the build stopped after 47
  minutes. The exact trigger is not confirmed: either the session's
  `7f06080` code ran against 0.1.0's data (which renamed
  `data/census.names.RData` to `census.names.rda`), or a worker started
  while the install was still writing files.
* At the same time, two other R jobs each ran `parse_names()`, so three
  23-worker clusters competed for the CPU. Stopping a parent process left
  its workers running until they were killed by hand.

Neither version is at fault. The design lets a running job pick up a
different version, and it overrides the caller's plan. The `future`
package's own guidance is that packages should not call `plan()`.

## Timings

The same 600 Part VII names, on one machine. "Attached" means
`library(peopleparser)`; "unattached" means called as
`peopleparser::parse_names()` from another package or script, the way
npmerger uses it.

| version | how | `parse_names()` (workers) | in-process `parse_name()` loop |
|---|---|---:|---:|
| `05aa895` | attached | 140/s | 133/s |
| `1665ea3` | attached | 140/s | 128/s |
| `7f06080` | attached | 139/s | 131/s |
| `7f06080` | unattached | 41/s | 6/s |
| `v0.1.0` | attached | 137/s | 103/s |
| `v0.1.0` | unattached | 37/s | 5/s |

`05aa895` and `1665ea3` fail outright when unattached (`census.names` not
found); `7f06080` fixed that by naming the package in `utils::data()`, which
made the reload path work rather than fail.

Two things stand out:

* **Attached, workers do not help on batches this size.** 139 against 131
  names a second: starting 23 processes and shipping the names to them
  costs about what the parallel work saves. On larger batches (4,000
  names) the earlier measurement was about 460 a second, so the cluster
  pays off only on big inputs.
* **Unattached, the reload dominates.** Counting calls confirms it: three
  census lookups make three `utils::data()` calls, at about 0.037 s each.

## Recommended fixes

### 1. Load each dataset once

Keep the data in a package-level environment and load it on first use:

```r
.pp_data <- new.env(parent = emptyenv())

census_names <- function() {
  if (is.null(.pp_data$census.names))
    utils::data("census.names", package = "peopleparser", envir = .pp_data)
  .pp_data$census.names
}
```

Then call `census_names()` in `get_census_data()` (and the same for
`first_name_pairs` in `get_variants_table()`). Alternatively, refer to the
data as `peopleparser::census.names`: `::` reaches lazy-loaded data without
attaching the package.

This alone should bring unattached parsing from about 5 to about 130 names
a second, and it makes the package behave the same attached or not.

### 2. Stop setting the plan inside `parse_names()`

Replace

```r
old_plan <- future::plan(future::multisession, workers = max(1, future::availableCores() - 1))
on.exit(future::plan(old_plan), add = TRUE)
```

with either:

* nothing, so `furrr::future_map_dfr()` uses whatever plan the caller has
  set. The default plan is sequential, so a plain call runs in-process and
  a caller who wants parallel sets `future::plan(multisession)` once for a
  whole job; or
* a `workers = 1` argument that, when above 1, sets a plan for the call
  and documents that it starts new processes.

Either way, one plan per job rather than one cluster per call removes the
version-skew window, the repeated start-up cost, and the orphaned workers.

### 3. If the package keeps its own workers, check them

When a call does start workers, have each report
`packageDescription("peopleparser")$Version` and `$RemoteSha` (or `$Built`),
and stop if any differs from the calling session. npmerger now does this
for its own clusters (`npmerger:::.parse_people()`), with this message:
"peopleparser on the workers (...) differs from this session (...). Was it
reinstalled while R was running?"

### 4. Longer term: vectorize the lookups

`parse_name()` handles one name at a time and calls `get_census_data()`
several times per name. Even with the data loaded once, about 130 names a
second means 410,000 names take about an hour. Looking up all tokens of a
batch in one keyed join, then assigning name parts with vectorized rules,
would likely be much faster than any worker count.

## How npmerger handles it now

npmerger no longer calls `parse_names()`. `npmerger::name_keys()`:

* calls `parse_name()` and `nickname_lookup()` itself, in its own R
  session by default, so the parser is always the one that session loaded;
* attaches peopleparser's namespace only while parsing, so the datasets
  load once (about 116-130 names a second), and detaches it afterwards;
* with `workers > 1` (or `options(npmerger.name_workers = n)`), starts one
  PSOCK cluster for the whole call, not one per chunk, and stops if any
  worker loaded a different peopleparser build (about 490 names a second
  with 8 workers);
* saves parsed names in the project database with the parser's version and
  commit, and reuses them only when the same parser build is installed.

Once fix 1 lands here, npmerger can drop the attach step.

## Name-order flips in v0.1.0

Found while deciding whether npmerger should move from `7f06080` to
v0.1.0. Both versions parsed the 59,164 distinct Part VII names in 1,500
sampled merger cases. On balance v0.1.0 is better: for the 42,774 plain
two-word names (letters only, no comma), it keeps the written order
(first word = first name, second = surname) 96.81% of the time, against
95.72% for `7f06080`.

Of the 985 two-word names whose order differs between the versions,
v0.1.0 **restores** the written order in 726 (`DEOSSIE ZAK` → `ZAK
DEOSSIE`, `FAWLEY DORMAN` → `DORMAN FAWLEY`). It **breaks** it in 259,
listed here.

Most of the 259 are clear errors: 142 have a common given name (10,000 or
more first-name records) as the first word. Every one also changes the
canonical first name, so for a caller that matches people on canonical
first name plus surname, it is a different person. Counts below are from
v0.1.0's own `census.names` (2020 lists).

### 1. A rare token listed only as a first name beats a common first name (98 flips, 38%)

| name | v0.1.0 first \| last | first-name records (word 1 / word 2) | surname records (word 1 / word 2) |
|---|---|---:|---:|
| RICHARD RUVIN | RUVIN \| RICHARD | 1,575,998 / 106 | 51,000 / 0 |
| JOE ZENAS | ZENAS \| JOE | 275,876 / 365 | 10,128 / 0 |
| PAUL AYAN | AYAN \| PAUL | 907,225 / 4,622 | 80,097 / 327 |
| KRIS CALEN | CALEN \| KRIS | 33,727 / 2,415 | 256 / 0 |
| TOM LUCIA | LUCIA \| TOM | 118,350 / 71,628 | 10,364 / 3,693 |
| LYNN RYAN | RYAN \| LYNN | 193,296 / 874,269 | 36,656 / 137,599 |
| ALLAN MACKENZIE | MACKENZIE \| ALLAN | 69,671 / 125,027 | 10,607 / 13,446 |
| HENRY COLT | COLT \| HENRY | 354,666 / 18,214 | 166,610 / 1,372 |

Others: Michael Fania, Dan Vitina, Bill Noah, Jim Lanard, Mark Michael,
Clay Morgan.

The 2020 first-name list now includes rare names (53,615 against 5,494
before), so a surname like RUVIN appears as a 106-record first name with no
surname records. Its surname share is 0. That puts it last in surname
ranking, and RICHARD (3% surname) takes the surname slot. Ranking by share
alone ignores how little evidence 106 records are.

### 2. A written first name that is mostly a surname in the Census (89 flips, 34%)

| name | v0.1.0 first \| last | word 1 first / surname records | word 2 first / surname records |
|---|---|---:|---:|
| HARRIS MORRISON | MORRISON \| HARRIS | 10,007 / 603,371 | 1,356 / 115,546 |
| FOSTER MCDONALD | MCDONALD \| FOSTER | 7,033 / 218,824 | 506 / 172,700 |
| WILLIAMS LAKE | LAKE \| WILLIAMS | 8,123 / 1,561,395 | 2,760 / 31,187 |
| ALLEN ARROW | ARROW \| ALLEN | 166,924 / 465,583 | 1,516 / 460 |
| HARRIS NYDICK | NYDICK \| HARRIS | 10,007 / 603,371 | 0 / 0 |
| YOUNG SEESEE | SEESEE \| YOUNG | 22,168 / 468,920 | 0 / 0 |

These are given names that are also common surnames (Harris, Foster,
Allen, Williams, Young). When both words are surname-like, `7f06080` kept
the written order. v0.1.0 takes the more surname-like word as the surname,
even when the other word is written second and is itself mostly a surname
(MORRISON, MCDONALD), or is not in the Census at all (NYDICK, SEESEE).

### 3. An unlisted first word against a surname just under the 95% tier (69 flips, 27%)

| name | v0.1.0 first \| last | word 2 surname share |
|---|---|---:|
| ARBANNAH HOLLAND | HOLLAND \| ARBANNAH | 94% |
| PRISSANA ALSTON | ALSTON \| PRISSANA | 93% |
| BETONY BRADDOCK | BRADDOCK \| BETONY | 91% |
| LOARRAINE WYNNE | WYNNE \| LOARRAINE | 86% |
| S KRISHNAN | KRISHNAN \| S | 88% |
| FAHEEMAH MUHAMMAD | MUHAMMAD \| FAHEEMAH | 38% |

The tiers put tokens that are at least 95% surnames first and unlisted
tokens second. So an unlisted given name (ARBANNAH, PRISSANA) outranks a
surname at 94% and becomes the surname. The same rule makes a lone
initial the surname (`S KRISHNAN` → last name `S`).

### Suggested fixes

* **Never make a single-letter initial the surname** when another token is
  available.
* **Use the written order as the prior.** On Part VII it is right about 96%
  of the time for two-word names. Swap only when the evidence is strong:
  for example, when the second word is clearly a given name and the first
  clearly a surname, both with enough records. Do not swap when both words
  lean the same way (patterns 1 and 2).
* **Weigh shares by evidence.** Treat a token with very few records (say
  under 1,000) like an unlisted token instead of trusting its share, so
  RUVIN at 106 first-name records does not count as a first name.
* **Soften the 95% tier.** A fixed cutoff makes HOLLAND (94%) lose to an
  unlisted word. Comparing the two tokens' surname odds directly avoids
  the cliff.

All 259 cases, with both versions' parses, the pattern, and the Census
counts, are in `data-raw/name-order-flips-v0.1.0.csv`. Good regression
cases for `data-raw/hard_cases.R` are those above, plus Michael
Fania, Dan Vitina, Bill Noah, Jim Lanard, Mark Michael, Clay Morgan,
Coleman Levy, Lee Kort, and Shengli Yuan.

## To reproduce

```r
# unattached: each census lookup reloads the dataset
f <- get("get_census_data", asNamespace("peopleparser"))
n <- 0L; trace(utils::data, quote(n <<- n + 1L), print = FALSE)
invisible(f("SMITH")); invisible(f("JONES")); invisible(f("LEE"))
n                                        # 3: one reload per lookup
system.time(for (i in 1:20) f("SMITH"))  # about 0.04 s per lookup

# parse_names() starts workers on every call
x <- rep(c("ROBERT SMITH", "BOB JONES"), 300)
system.time(peopleparser::parse_names(x))            # workers, unattached
library(peopleparser)
system.time(parse_names(x))                          # workers, attached
system.time(lapply(sanitize_input(x), parse_name))   # in-process, attached
```
