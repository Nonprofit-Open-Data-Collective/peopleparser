# Suffix gaps on Form 990 Part VII names

Dev note, 2026-11-23. Which trailing tokens does peopleparser fail to strip,
measured on real Part VII names, with a proposed suffix list and a
definition for every entry.

<!-- STATUS 2026-11-23: steps 1-5 of "Suggested order of work" IMPLEMENTED.
  * Tier 1 (90 tokens) and the hyphenated credentials are in `prx`
    (R/utils.R). SJ, CISA, IHM and FAIA strip only from the trailing run
    (`.trailing_only_titles`), per the front-strip caveat and their
    surname counts.
  * Tier 2 is in `.ambiguous_suffix_credentials` (strip only inside a
    trailing run that holds a real credential, like RM).
  * Tenure words are in `.trailing_status_words`: moved to `status` only
    from the trailing run, since BEGIN, BEGAN and PART are surnames.
  * Role words (with VICE joined to its role word in prep_name()) are
    trailing-only titles. PRESIDENT (895) and CHAIR (139) are surnames.
  * Prefixes that are not surnames are in `prx`. BISHOP, SHERIFF, CANTOR,
    DEACON, CAPTAIN, MOTHER, MOST, IMAM and BROTHER are
    `.leading_only_titles`: first token only, with at least two tokens after.
  * prep_name(): `DR PH` -> `DRPH`, `NON VOTING` -> `NONVOTING`,
    `ST <word>` inside a name -> `ST-<word>`; VANDER is a locative particle.
  * known_titles() has a row for every new token, plus the new types
    Religious Order, Fraternal Office and Military Status. CSC is retyped.
  * Check on a 9,608-name sample (4,608 names with a listed token, plus
    5,000 controls), parsed sequentially before and after:
    - controls: 0 changed;
    - names with a listed token left inside a name field: 3,771 -> 742.
    Most of the 742 are by design. Real surnames are kept (BISHOP, CANTOR,
    DEACON, SHERIFF, BEGIN, VANDER-...). Tier-2 tokens with no real
    credential beside them are kept (DC 105, MA 76, OP 28, SC 21).
  * Not done: step 6 (entity names, affiliate codes); fused JRMD/MDMPH;
    new credentials seen in the check (FNP-BC, FHIMSS, CNS). A rerun of
    suffix-gaps-part7.R now treats all of the lists above as known. -->


## Summary

* **Data.** 410,071 unique Part VII names (1,325,633 person-year rows): the
  rosters of the donors and recipients in 12,684 nonprofit mergers, tax
  years 2009-2025, from an npmerger project database.
* **Finding.** The screen found 274 trailing tokens that peopleparser does
  not strip; 241 of them end up inside `first_name` or `last_name` on real
  examples. They are glued to the surname with hyphens, e.g.
  `"Sister Maureen Reardon RSM"` → `last_name = "REARDON-RSM"`.
* **Tier 1 fix (94 tokens, below).** Passed as extra `prefixes`, they clean
  1,732 of the 1,733 affected names (5,466 person-years) and change none of
  a 3,000-name control sample.
* **Also proposed:**
  * hyphenated credentials (`PA-C`, `RN-BC`, ...), which need tokenizer
    support;
  * 23 ambiguous short tokens (`MA`, `DC`, `OP`, ...), which should strip
    only inside a trailing credential run, the way `RM` does;
  * more words for the `status` list;
  * 25 prefixes (`RABBI`, `BISHOP`, `MOST REV`, `RADM`, ...).
* **Not suffixes.** Filer-specific affiliate codes (`NMHC`, `UPM`, ...)
  and real surnames that the screen surfaced are listed separately, so
  they stay out of the lists.

Counts are unique names with the token among the last four tokens (first
token for prefixes), and the person-year rows those names cover.

## How stripping works today

* `parse_name()` removes tokens in `prx` (salutations, degrees,
  credentials) and `sfx` (generational: `JR`, `SR`, `II`, ...) from either
  end of the name.
* `RM` is the one *ambiguous* credential. It strips only inside a trailing
  run of known credentials (`trailing_ambiguous_credentials()`).
* Anything else at the end becomes part of the surname, joined with
  hyphens, so one unknown credential corrupts the surname (`TRAN-CSJ`,
  `MASON-PHARMD`).
* For matching people across organizations or years, that is the costly
  failure: the same person gets different surnames in different years.

## Method

`data-raw/suffix-gaps-part7.R` reproduces every number here:

1. Tokenize with `prep_name()`.
2. From the end of each name, drop tokens already in `prx`, `sfx`, the
   ambiguous list, or the status words. Record the final remaining token
   when at least two tokens precede it. Repeat, also dropping the
   candidates found so far, to catch runs such as `RN MSN CNO`. This took
   two passes.
3. Keep tokens seen in at least 5 names whose preceding token looks like
   a surname (Census last-name count above its first-name count) at least
   half the time.
4. Run `parse_names()` on up to 15 real names per candidate, and count
   how often the token survives inside `first_name` or `last_name`.
5. Add common credentials checked directly against `prx` (FACP, MPA,
   CLU, ...). Count everything, and test the tier 1 list as extra
   `prefixes`.

Outputs: `data-raw/suffix-gaps-part7-candidates.csv` (the 274 screened
tokens with leak checks) and `data-raw/suffix-gaps-part7-counts.csv`
(counts for every token below).

Each candidate was then read and classified by hand. Definitions are the
standard expansions. Where an abbreviation has more than one common
meaning, the entry gives the likely one for these data and says so.

---

## Tier 1: add to `prx` and `known_titles()`

These are unambiguous. None is a given name, and only `IHM` (359) and
`FAIA` (271) appear in the Census surname list, both rarely. They can be
stripped wherever they occur.

One caveat: `prx` strips from the **front** too. `SJ` begins five names
as initials ("SJ Smith"), and `CISA` begins one as a given name. If
front-stripping matters, restrict those two to the trailing position.

### Religious orders and church degrees

The `type` for the orders is new. Suggested: **Religious Order**. Note
that `CSC` (Congregation of Holy Cross) is already in `prx` but is typed
"Professional Credential" in `known_titles()`; it belongs here too.

| abbr | definition | proposed type | names | person-years |
|---|---|---|---:|---:|
| `SJ` | Society of Jesus (Jesuits) | Religious Order | 142 | 346 |
| `RSM` | Religious Sisters of Mercy (Sisters of Mercy) | Religious Order | 101 | 506 |
| `OSF` | Order of Saint Francis (Franciscan sisters and friars) | Religious Order | 52 | 267 |
| `CSJ` | Congregation of Saint Joseph (Sisters of St. Joseph) | Religious Order | 29 | 96 |
| `IHM` | Sisters, Servants of the Immaculate Heart of Mary | Religious Order | 22 | 125 |
| `FSC` | Brothers of the Christian Schools (De La Salle Brothers) | Religious Order | 18 | 52 |
| `CBS` | Congregation of Bon Secours (Sisters of Bon Secours) | Religious Order | 16 | 47 |
| `CSJP` | Sisters of St. Joseph of Peace | Religious Order | 15 | 62 |
| `SCC` | Sisters of Christian Charity | Religious Order | 14 | 42 |
| `OSB` | Order of Saint Benedict (Benedictines) | Religious Order | 13 | 34 |
| `SSJ` | Sisters of St. Joseph | Religious Order | 10 | 46 |
| `CSJB` | Sisters of St. John the Baptist | Religious Order | 8 | 17 |
| `SCL` | Sisters of Charity of Leavenworth | Religious Order | 7 | 30 |
| `FSGM` | Franciscan Sisters of St. George Martyr | Religious Order | 6 | 36 |
| `CCVI` | Congregation of the Sisters of Charity of the Incarnate Word | Religious Order | 5 | 7 |
| `PHJC` | Poor Handmaids of Jesus Christ | Religious Order | 5 | 11 |
| `DMIN` | Doctor of Ministry | Academic Degree | 15 | 38 |
| `MDIV` | Master of Divinity | Academic Degree | 8 | 22 |
| `JCD` | Doctor of Canon Law (Juris Canonici Doctor) | Academic Degree | 5 | 27 |
| `JCL` | Licentiate in Canon Law | Academic Degree | 4 | 10 |
| `STL` | Licentiate in Sacred Theology | Academic Degree | 1 | 2 |

### Health care

| abbr | definition | proposed type | names | person-years |
|---|---|---|---:|---:|
| `FACHE` | Fellow, American College of Healthcare Executives | Professional Credential | 97 | 301 |
| `BSN` | Bachelor of Science in Nursing | Academic Degree | 85 | 181 |
| `PHARMD` | Doctor of Pharmacy | Academic Degree | 74 | 168 |
| `FCCP` | Fellow, American College of Chest Physicians (also American College of Clinical Pharmacy) | Professional Credential | 54 | 132 |
| `DPM` | Doctor of Podiatric Medicine | Academic Degree | 53 | 121 |
| `FACP` | Fellow, American College of Physicians | Professional Credential | 53 | 179 |
| `CRNA` | Certified Registered Nurse Anesthetist | Professional Credential | 35 | 121 |
| `MBBS` | Bachelor of Medicine, Bachelor of Surgery | Academic Degree | 20 | 54 |
| `CCM` | Certified Case Manager | Professional Credential | 19 | 44 |
| `LICSW` | Licensed Independent Clinical Social Worker | Professional Credential | 18 | 34 |
| `FAAP` | Fellow, American Academy of Pediatrics | Professional Credential | 16 | 53 |
| `FACC` | Fellow, American College of Cardiology | Professional Credential | 15 | 76 |
| `FAAN` | Fellow, American Academy of Nursing | Professional Credential | 15 | 149 |
| `LMSW` | Licensed Master Social Worker | Professional Credential | 15 | 23 |
| `FNP` | Family Nurse Practitioner | Professional Credential | 14 | 41 |
| `PSYD` | Doctor of Psychology | Academic Degree | 13 | 30 |
| `APRN` | Advanced Practice Registered Nurse | Professional Credential | 12 | 27 |
| `FHFMA` | Fellow, Healthcare Financial Management Association | Professional Credential | 12 | 89 |
| `DSW` | Doctor of Social Work | Academic Degree | 10 | 28 |
| `CCRN` | Critical Care Registered Nurse (certification) | Professional Credential | 9 | 12 |
| `DHA` | Doctor of Health Administration | Academic Degree | 9 | 29 |
| `MHSA` | Master of Health Services Administration | Academic Degree | 9 | 26 |
| `MSPH` | Master of Science in Public Health | Academic Degree | 9 | 20 |
| `DPT` | Doctor of Physical Therapy | Academic Degree | 7 | 48 |
| `MSHA` | Master of Science in Health Administration | Academic Degree | 7 | 19 |
| `BDS` | Bachelor of Dental Surgery | Academic Degree | 6 | 22 |
| `CNM` | Certified Nurse-Midwife | Professional Credential | 6 | 42 |
| `CPHQ` | Certified Professional in Healthcare Quality | Professional Credential | 5 | 9 |
| `LPC` | Licensed Professional Counselor | Professional Credential | 5 | 11 |
| `LSCSW` | Licensed Specialist Clinical Social Worker | Professional Credential | 5 | 7 |
| `CPHIMS` | Certified Professional in Healthcare Information and Management Systems | Professional Credential | 4 | 6 |
| `FACOG` | Fellow, American College of Obstetricians and Gynecologists | Professional Credential | 4 | 8 |
| `OTRL` | Occupational Therapist, Registered, Licensed | Professional Credential | 4 | 13 |
| `CHFP` | Certified Healthcare Financial Professional | Professional Credential | 3 | 4 |
| `LMFT` | Licensed Marriage and Family Therapist | Professional Credential | 3 | 5 |
| `LPN` | Licensed Practical Nurse | Professional Credential | 3 | 5 |
| `MDS` | Master of Dental Surgery | Academic Degree | 1 | 5 |

### Professional, business, and legal

| abbr | definition | proposed type | names | person-years |
|---|---|---|---:|---:|
| `CFRE` | Certified Fund Raising Executive | Professional Credential | 70 | 111 |
| `ESQUIRE` | Esquire (spelled out; `ESQ` is already in `prx`) | Personal Title | 66 | 488 |
| `MPA` | Master of Public Administration | Academic Degree | 53 | 134 |
| `CCIFP` | Certified Construction Industry Financial Professional | Professional Credential | 50 | 94 |
| `CIC` | Certified Insurance Counselor | Professional Credential | 44 | 97 |
| `SPHR` | Senior Professional in Human Resources | Professional Credential | 38 | 85 |
| `CPM` | Certified Property Manager | Professional Credential | 26 | 44 |
| `CLU` | Chartered Life Underwriter | Professional Credential | 24 | 115 |
| `CHFC` | Chartered Financial Consultant | Professional Credential | 22 | 103 |
| `CPCU` | Chartered Property Casualty Underwriter | Professional Credential | 16 | 44 |
| `ACFRE` | Advanced Certified Fundraising Executive | Professional Credential | 11 | 16 |
| `CHMM` | Certified Hazardous Materials Manager | Professional Credential | 11 | 34 |
| `PMP` | Project Management Professional | Professional Credential | 10 | 20 |
| `CDT` | Certified Dental Technician | Professional Credential | 9 | 17 |
| `CLFP` | Certified Lease and Finance Professional | Professional Credential | 9 | 9 |
| `CMA` | Certified Management Accountant | Professional Credential | 9 | 21 |
| `LEED` | LEED Accredited Professional (usually `LEED AP`; `AP` is in `prx`) | Professional Credential | 9 | 21 |
| `CCIM` | Certified Commercial Investment Member | Professional Credential | 8 | 17 |
| `CFM` | Certified Financial Manager; also Certified Floodplain Manager and Certified Facility Manager | Professional Credential | 8 | 25 |
| `LLM` | Master of Laws | Academic Degree | 8 | 20 |
| `CGMA` | Chartered Global Management Accountant | Professional Credential | 6 | 26 |
| `MPP` | Master of Public Policy | Academic Degree | 6 | 15 |
| `AICP` | American Institute of Certified Planners | Professional Credential | 5 | 9 |
| `CTFA` | Certified Trust and Financial Advisor | Professional Credential | 5 | 9 |
| `PHR` | Professional in Human Resources | Professional Credential | 5 | 15 |
| `CISA` | Certified Information Systems Auditor | Professional Credential | 2 | 8 |
| `FAIA` | Fellow, American Institute of Architects | Professional Credential | 2 | 2 |
| `CEBS` | Certified Employee Benefit Specialist | Professional Credential | 1 | 2 |
| `CFE` | Certified Fraud Examiner | Professional Credential | 1 | 1 |

### Masonic offices and retired military

Masonic titles come from the lodges and Grand Lodges in these data. `WM`
(Worshipful Master) is already in `prx`. A new `type`, **Fraternal Office**,
would fit.

| abbr | definition | proposed type | names | person-years |
|---|---|---|---:|---:|
| `RWJGW` | Right Worshipful Junior Grand Warden | Fraternal Office | 8 | 20 |
| `RWGM` | Right Worshipful Grand Master | Fraternal Office | 7 | 19 |
| `RWDGM` | Right Worshipful Deputy Grand Master | Fraternal Office | 7 | 21 |
| `RWSGW` | Right Worshipful Senior Grand Warden | Fraternal Office | 7 | 18 |
| `USNRET` | U.S. Navy, retired (`USN` + `RET` fused) | Military Status | 16 | 22 |
| `USMCRET` | U.S. Marine Corps, retired (`USMC` + `RET` fused) | Military Status | 7 | 16 |
| `USAFRET` | U.S. Air Force, retired (`USAF` + `RET` fused) | Military Status | 5 | 8 |

The three fused military tokens could instead be split by
`deglue_tokens()` into two known tokens. Other fused credentials seen are
`JRMD` (`JR` + `MD`, 6 names, leaks) and `MDMPH` (2). `MDPHD` already
parses correctly.

---

## Hyphenated credentials: need tokenizer support

`prep_name()` keeps hyphens (for compound surnames), so these survive as
single tokens and are glued on: `"JANE DOE PA-C"` → `last_name = "DOE-PA-C"`,
and `"KIM RAY NP-C"` → `last_name = "NP-C"`. Adding the hyphenated forms
to `prx` should work. The alternative, stripping the hyphen first, would
turn `PA-C` into `PA` + `C`, which is worse.

| abbr | definition | proposed type | names | person-years |
|---|---|---|---:|---:|
| `SHRM-SCP` | SHRM Senior Certified Professional (human resources) | Professional Credential | 36 | 84 |
| `PA-C` | Physician Assistant, Certified | Professional Credential | 13 | 41 |
| `RN-BC` | Registered Nurse, Board Certified | Professional Credential | 6 | 7 |
| `NP-C` | Nurse Practitioner, Certified | Professional Credential | 3 | 6 |
| `RNC-OB` | Registered Nurse Certified, Inpatient Obstetric Nursing | Professional Credential | 2 | 2 |
| `SHRM-CP` | SHRM Certified Professional | Professional Credential | 1 | 1 |

(`CCC-SLP`, Certificate of Clinical Competence in Speech-Language
Pathology, already parses correctly.)

## Tier 2: ambiguous short tokens, strip only inside a trailing credential run

These collide with surnames, initials, places, or ordinary words. Handle
them like `RM`: add them to `.ambiguous_suffix_credentials`, so they strip
only when they sit in a trailing run that also contains at least one
unambiguous credential. That keeps `"KATHY WILDE RN MA"` → `WILDE` but
leaves `"JACK MA"` alone.

| abbr | definition | collision | names | person-years |
|---|---|---|---:|---:|
| `MA` | Master of Arts | Common surname (Ma; Census 28,452) and given name | 116 | 304 |
| `DC` | Doctor of Chiropractic | Washington, DC in addresses and affiliations | 109 | 262 |
| `SC` | Sisters of Charity (several congregations) | Initials; South Carolina | 34 | 112 |
| `APR` | Accredited in Public Relations | April, in tenure notes ("THRU APR") | 29 | 56 |
| `OP` | Order of Preachers (Dominicans) | Initials | 28 | 83 |
| `BA` | Bachelor of Arts | Surname (Ba; Census 2,451) | 25 | 77 |
| `PT` | Physical Therapist | Part-time ("PT" in role notes) | 19 | 95 |
| `NP` | Nurse Practitioner | Initials | 17 | 30 |
| `CEM` | Certified Energy Manager | Also an affiliate code in these data | 17 | 73 |
| `SP` | Sisters of Providence | Initials | 16 | 103 |
| `PM` | Past Master (Masonic) | Post meridiem; initials | 12 | 15 |
| `CR` | Congregation of the Resurrection | Initials | 11 | 29 |
| `DD` | Doctor of Divinity | Initials ("BRUCE DD MAC RAE") | 11 | 21 |
| `HM` | Sisters of the Humility of Mary | Initials | 10 | 30 |
| `DBA` | Doctor of Business Administration | "Doing business as" before an entity name | 8 | 32 |
| `MSA` | Master of Science in Accountancy (or Administration) | Metropolitan Statistical Area | 7 | 29 |
| `CRP` | Certified Relocation Professional (several credentials share it) | Unclear in these data | 6 | 41 |
| `ND` | Naturopathic Doctor | North Dakota | 6 | 10 |
| `AB` | Bachelor of Arts (Artium Baccalaureus) | Initials | 3 | 9 |
| `STD` | Doctor of Sacred Theology | "Standard" | 3 | 9 |
| `AUD` | Doctor of Audiology (AuD) | Rare given name | 2 | 3 |
| `VF` | Vicar Forane (Catholic clergy) | Initials | 2 | 4 |
| `VG` | Vicar General (Catholic clergy) | Initials | 1 | 5 |

`PH` appears in `"DR PH"`. That is the degree DrPH (Doctor of Public
Health, already in `prx` as `DRPH`) split by a space, so it is better
fixed in `prep_name()` like `PH D` → `PHD`: add `" DR PH"` → `" DRPH"`.

---

## Trailing words that are not suffixes

These are not credentials, but they are stripped by the same mechanism or
belong in the `status` vector of `parse_name()`.

**Tenure notes** (extend the `status` list). Part VII names often carry the
term of service, e.g. `"Kent Cashell term ended 1231"` → `last_name`
keeps `TERM-ENDED`. The digits are already removed by `prep_name()`.

| token | meaning | names | leaked in sample |
|---|---|---:|---|
| `TERM` | as in "term ended", "term began" | 172 | 4 of 15 |
| `YEAR` | as in "partial year", "part year" | 123 | 1 of 15 |
| `ENDED` | service ended | 106 | 8 of 15 |
| `PART` | as in "part time", "part year" | 91 | 2 of 15 |
| `EXIT` | left the board | 62 | 15 of 15 |
| `JOINED` | joined the board | 61 | 14 of 15 |
| `EFFECTIVE` | as in "effective 7/1" | 39 | 1 of 15 |
| `BEGIN`, `BEGAN` | service began | 27, 26 | 14 and 13 of 15 |
| `EXITED` | left the board | 26 | 14 of 15 |
| `ENTERED` | joined the board | 24 | 15 of 15 |
| `TERMINATED` | service ended | 23 | 15 of 15 |
| `RESIGN` | resigned (`RESIGNED` is already handled) | 18 | 15 of 15 |
| `SINCE` | as in "since 11/18" | 15 | 15 of 15 |
| `TIL`, `THR` | until, through (abbreviated) | 9, 7 | 8 of 9, 6 of 7 |
| `INCOMING` | incoming officer (`OUTGOING` is already handled) | 9 | 9 of 9 |
| `DECD` | deceased (from `DEC'D`; `DECEASED` is already handled) | 8 | 8 of 8 |
| `ENTRY` | date of entry | 7 | 7 of 7 |
| `EMERITUS` | emeritus member | 5 | 5 of 5 |
| `NON VOTING` | non-voting member (two tokens) | 10 | 10 of 10 |
| month names | `JANUARY`, `SEPTEMBER`, ... in dates | 18, 5 | some; both are also surnames |

`THRU`, `THROUGH`, `PRESENT`, `OUTGOING`, `PARTIAL`, and month ranges such
as `JAN-JUL` did **not** leak in the sample.

**Role words** appended to the name (`"LARRY BLACK SECRETARY"`): `SECRETARY`
(33 names), `CHAIR` (37), `TREASURER` (21), `TRUSTEE` (16), `CHAIRMAN`
(14), `SVP` (24), `EVP` (24), `ASST` (12), `ASSOC` (9), `ASSOCIATE` (7),
and `PRESIDENT` (69). All but `PRESIDENT` leaked in most samples. `VICE`
(48) leaked too, but it is also a surname (Census 5,403), so strip it only
together with a following role word, as in `VICE CHAIR`.

**Organizations listed as people** (65 names ending in an entity word):
`BANK` (33 names), `INC` (15), `TRUST` (12), `COMPANY` (7), `LLC` (6),
`CORP` (5), `PARTNERS`, `FOUNDATION` (3 each). Examples: `"US Bank NA"`,
`"THE NORTHERN TRUST COMPANY"`, `"DAVID ROBERTS - LHS INC"`. A
`status = "ENTITY"` flag would serve better than stripping, so callers
can drop these records.

**Affiliate codes.** Large health systems list each officer with the code
of the affiliate they serve. Examples include `NMHC`, `NMH`, `NLFH`,
`NMF` and `NMPG` (Northwestern Medicine entities), `UPM`, `HMT`, `KAN`,
and `HNV`. About 55 codes appear in at least 5 names:

> NMF 85, UPM 75, NMHC 72, ALT 40, BDF 40, HMT 40, CHF 36, PSV 36, JMC 34,
> NWH 34, SHF 33, SMH 33, HRF 31, NMH 31, CAC 30, ALF 29, NLFH 28, HNV 27,
> WEL 27, CF 25, HRZ 25, JHF 24, SPS 24, JAM 23, SHS 22, CCB 21, CHS 21,
> LHS 21, SUN 20, MUN 19, HNA 18, JHS 18, THS 18, ULH 18, CMI 17, BHM 16,
> CCH 16, HNF 16, KAN 16, SHB 16, DVP 15, FYO 15, HCM 15, HCV 15, APH 14,
> SOH 14, THC 14, MYC 13, NMPG 12, EPN 11, HHC 10, SOM 10, UTS 8, OVI 6,
> UF 6, SCS 5

**Do not add these to `prx`.** They are filer-specific, and several are
words or names (`SUN`, `JAM`, `ALT`, `KAN`, `MUN`, `ALF`). Options:

* a `drop_trailing` argument through which a caller passes codes it
  knows;
* a rule that drops a final 2-4 letter token absent from the Census lists
  when the same token ends many names within one filer. That needs the
  filer ID, so it belongs in the caller, e.g. npmerger or synthid.

---

## Prefixes found in passing

The suffix screen also surfaced prefixes that `prx` lacks. They leak into
the surname the same way: `"RABBI DAVID COHEN"` → `COHEN-RABBI`,
`"MOST REV JOHN SMITH"` → `SMITH-MOST`.

| prefix | definition | proposed type | names | person-years |
|---|---|---|---:|---:|
| `RABBI` | Rabbi | Religious Title | 240 | 941 |
| `BISHOP` | Bishop | Religious Title | 91 | 290 |
| `RADM` | Rear Admiral | Military Rank | 58 | 138 |
| `PROFESSOR` | Professor (`PROF` is in `prx`) | Personal Title | 57 | 86 |
| `MOST` | as in "Most Reverend" (archbishops and bishops; 36 of 37 are `MOST REV`) | Religious Title | 37 | 132 |
| `BR` | Brother (religious) | Religious Title | 35 | 87 |
| `DEACON` | Deacon | Religious Title | 34 | 107 |
| `VADM` | Vice Admiral | Military Rank | 30 | 74 |
| `BROTHER` | Brother (religious) | Religious Title | 29 | 55 |
| `SHERIFF` | Sheriff | Civic / Political Title | 21 | 53 |
| `CAPTAIN` | Captain (`CAPT` is in `prx`) | Military Rank | 17 | 36 |
| `MONSIGNOR` | Monsignor (`MSGR` is in `prx`) | Religious Title | 12 | 23 |
| `ADM` | Admiral | Military Rank | 12 | 30 |
| `ATTY` | Attorney | Personal Title | 12 | 26 |
| `IMAM` | Imam | Religious Title | 6 | 15 |
| `ARCHBISHOP` | Archbishop | Religious Title | 5 | 24 |
| `ADMIRAL` | Admiral | Military Rank | 5 | 14 |
| `CANTOR` | Cantor (Jewish clergy) | Religious Title | 5 | 18 |
| `MOTHER` | Mother (superior of a religious community) | Religious Title | 4 | 5 |
| `BGEN` | Brigadier General | Military Rank | 3 | 6 |
| `CMSGT` | Chief Master Sergeant | Military Rank | 3 | 5 |
| `MSGT` | Master Sergeant | Military Rank | 3 | 3 |
| `CPL` | Corporal | Military Rank | 2 | 3 |
| `CSM` | Command Sergeant Major | Military Rank | 2 | 2 |
| `SGTMAJ` | Sergeant Major | Military Rank | 2 | 3 |

`BISHOP`, `CANTOR`, `CAPTAIN`, `SHERIFF`, `DEACON`, and `MOTHER` are also
surnames. Strip them only in the first position with at least two tokens
after them. `S` (187 names) often means Sister (`"S Mary Agnes Patterson
OSB"`), but it is usually an initial, so leave it out. `DEAN` (405) is
almost always a given name; leave it out too.

## Related defects seen

* **`ST` in `prx` strips "St." from surnames.** `"SEAN ST CLAIR"` →
  `last_name = "CLAIR"`, and `"ROBERT ST PETER"` → `PETER`. 135 names have
  `ST` before the final token. Join it in `prep_name()` as is done for
  `DE`: `" ST "` → `" ST-"` when followed by a surname, and keep `ST` out
  of the stripping set or make it front-only.
* **`VANDER` reorders.** `"... H VANDER GHEYNST"` → `GHEYNST-VANDER` (48
  names have `VANDER` before the last token). `VAN DER` is joined, but
  `VANDER` written as one word is not.
* **Name order flips** on a few doctors: `"MURALI CHAKINALA MD FCCP"` →
  `first_name = "CHAKINALA"`, `last_name = "MURALI"`. This is the
  probabilistic ordering, not suffixes; noted here because it showed up in
  the tier 1 check.
* **`known_titles()` and `prx` have drifted** (as `PARSE-FAIL-NOTES.md`
  also says): `CSC` is mistyped, and many `prx` entries have no
  `known_titles()` row. Adding the tables above to both keeps them in step.

## Real surnames the screen surfaced (exclude)

A token that ends many names after a surname-like token can still be a
surname: double surnames, maternal surnames, or names written surname
first. These leaked in the check only because they *are* the surname.
Keep them out of every list.

> ALVAREZ, MORENO, GUERRERO, VARGAS, LOZANO, NIEVES, TRAN, LIU, KUMAR,
> AGARWAL, TSAI, PAK, PENDLETON, GLASS, REICH, KOHRMAN, LENIHAN, GAINES,
> LINDEN, PETTIT, BOLDT, GILLIS, BLANC, COE, DAVEY, EWERS, JEFFERS, KOHL,
> LINDSTROM, MAYFIELD, MCELROY, POWER, SCHLUSSEL, TATUM, WECHSLER, AGEE,
> BROCKMAN, FETTER, GEE, GODSEY, LURIE, MANSOUR, METZGER, NAGEL, ODELL,
> PALERMO, PEROT, THRASHER, HARBOR, plus the given names JIM, LINN, ROBB,
> ALI, DIEGO, and ASA, and PASO (from "El Paso").

## Suggested order of work

1. Add the tier 1 tables (94 tokens) and the hyphenated credentials to
   `prx`, and to `known_titles()` with the labels and types above. Add
   regression cases to `data-raw/hard_cases.R`, one per group, from the
   examples in `suffix-gaps-part7-candidates.csv`.
2. Add the tier 2 tokens to `.ambiguous_suffix_credentials`.
3. Extend the `status` list with the tenure words, and handle role words.
4. Add the prefixes, with the surname caveat for the six that are also
   surnames.
5. Fix `ST` and `VANDER` in `prep_name()`, and the `DR PH` join.
6. Decide on entity names (`status = "ENTITY"`) and on a caller-supplied
   `drop_trailing` list for affiliate codes.

To recheck after a change, run `data-raw/suffix-gaps-part7.R`. The tier 1
line at the end should still read "after 1" (or 0) with "control changes
0", and the candidate file should shrink.
