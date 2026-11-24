# What changed since the parses in synthid

synthid’s Form 990 Part VII people tables
(`s3://nccs-efile/dev/synthid/partvii-v3_1/people/`) were parsed in
October 2026 with peopleparser commit `cb01547`, version 0.0.0.9000,
called 0.0.9 here. This page compares those parses with version 0.2.2 on
a sample of names, to show what the changes since then do to real data
and where the parser is still wrong.

## The sample

Twenty thousand rows were drawn at random from each of the 2017 and 2024
people files, and 10,000 distinct names taken from them. Each name was
parsed again with 0.2.2, with `split_run_together = TRUE` and
`classify = TRUE`, and the salutation, first, middle and last name,
suffix and gender compared with the stored values. The script is
`data-raw/compare_versions.R`; every changed name is listed in
`data-raw/compare-v0.0.9-v0.2.2.csv`. Parts are shown below as
`salutation | first | middle | last | suffix`.

## Summary

903 of the 10,000 names (9%) parse differently. The rest are unchanged.

| Change | Names | Assessment |
|:---|---:|:---|
| Gender only | 485 | Mostly gains: names newly coded from the 2020 census |
| First and last name swapped | 262 | Nearly all now keep the written order |
| Other changes | 62 | Mixed; most are compound-surname order and names wrong in both |
| Middle name no longer joined to the surname | 50 | Mostly better; a few names written surname first are now wrong |
| Title or credential taken out of the name | 41 | Better |
| Particle joined to the surname | 3 | Better |

[`split_run_together()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/split_run_together.md)
changed none of these names: about one Part VII name in 10,000 is
written as one run-together word, so a sample this size holds few or
none.

## Gender

| Change                   | Names |
|:-------------------------|------:|
| Unknown to F or M        |   562 |
| Switched between F and M |    98 |
| F or M to unknown        |    42 |

Most gains come from the 2020 census given-name lists, which hold about
ten times as many names as the 1990 lists the old build used. The F/M
switches are unisex names whose balance moved between 1990 and 2020:

| First name | Names | Now M | Now F |
|:-----------|------:|------:|------:|
| KERRY      |    10 |     0 |    10 |
| KRIS       |     8 |     8 |     0 |
| TAYLOR     |     6 |     0 |     6 |
| QUINN      |     3 |     0 |     3 |
| RILEY      |     3 |     0 |     3 |
| CAREY      |     3 |     0 |     3 |
| ROBBIE     |     2 |     2 |     0 |
| DAKOTA     |     2 |     2 |     0 |
| KIM        |     2 |     0 |     2 |
| KERN       |     1 |     1 |     0 |

Gender for these names is close to a coin toss in either census; read
the `gender_confidence` column before relying on it.

## First and last name swapped

262 names have their first and last names swapped. In 258 the new parse
keeps the order the name was written in, first name first. The old build
often read a two-word name as surname first when the census leaned that
way at all.

| Name | 0.0.9 | 0.2.2 |
|:---|:---|:---|
| QIAOYUN LI | \| LI \| \| QIAOYUN \| | \| QIAOYUN \| \| LI \| |
| BRODY STAPEL | \| STAPEL \| \| BRODY \| | \| BRODY \| \| STAPEL \| |
| PEIYING YANG | \| YANG \| \| PEIYING \| | \| PEIYING \| \| YANG \| |
| CHAMP THOMASKUTTY | \| THOMASKUTTY \| \| CHAMP \| | \| CHAMP \| \| THOMASKUTTY \| |
| TRUONG HOANG | \| HOANG \| \| TRUONG \| | \| TRUONG \| \| HOANG \| |
| Kern Kim | \| KIM \| \| KERN \| | \| KERN \| \| KIM \| |

The others are swapped away from the written order. Some may be right
either way (`Sandoh Mayu`); the rest are the known weakness described
under [Gaps](#gaps-that-persist).

| Name | 0.0.9 | 0.2.2 |
|:---|:---|:---|
| DR MASSUMEH FARHAD | DR \| MASSUMEH \| \| FARHAD \| | DR \| FARHAD \| \| MASSUMEH \| |
| CLEVELAND TAYLER | \| CLEVELAND \| \| TAYLER \| | \| TAYLER \| \| CLEVELAND \| |
| Sandoh Mayu | \| SANDOH \| \| MAYU \| | \| MAYU \| \| SANDOH \| |
| HOWARD AINSLEY | \| HOWARD \| \| AINSLEY \| | \| AINSLEY \| \| HOWARD \| |

## Middle names that are also surnames

The old build joined a middle name to the surname whenever the census
listed it more often as a surname, so `DAVID LEE SMITH` got the surname
`LEE-SMITH`. Version 0.2.2 joins a middle word only when at least 90% of
its census records are surnames (`GARCIA LOPEZ`). Initials are never
joined.

| Name | 0.0.9 | 0.2.2 |
|:---|:---|:---|
| Summer Lee Jenkins | \| SUMMER \| \| LEE-JENKINS \| | \| SUMMER \| LEE \| JENKINS \| |
| MARY GAY SHIPLEY | \| MARY \| \| GAY-SHIPLEY \| | \| MARY \| GAY \| SHIPLEY \| |
| MS Marian Grant RD | MS \| MARIAN \| \| GRANT-RD \| | MS \| MARIAN \| GRANT \| RD \| |
| Mary Jac Brennan | \| MARY \| \| JAC-BRENNAN \| | \| MARY \| JAC \| BRENNAN \| |
| S FINLEY EWING IV | \| S \| \| FINLEY-EWING \| IV | \| S \| FINLEY \| EWING \| IV |
| KIM PERRY GARDNER | \| KIM \| \| PERRY-GARDNER \| | \| KIM \| PERRY \| GARDNER \| |
| KEVIN W SOWERS MSN RN FAAN | MSN_RN \| KEVIN \| W \| FAAN-SOWERS \| | MSN_RN_FAAN \| KEVIN \| W \| SOWERS \| |
| SHLOMO YEHUDAH RECHNITZ | \| SHLOMO \| \| YEHUDAH-RECHNITZ \| | \| SHLOMO \| YEHUDAH \| RECHNITZ \| |
| Roger Jarrett MUN | \| ROGER \| \| JARRETT-MUN \| | \| ROGER \| JARRETT \| MUN \| |
| PAUL CHIP BLILEY JR | \| PAUL \| \| CHIP-BLILEY \| JR | \| PAUL \| CHIP \| BLILEY \| JR |

A few names that were written surname first lost a right parse:
`WALPERT LEVY TARA` was `TARA WALPERT-LEVY` and is now first name
`LEVY`.

## Titles, credentials and particles

| Name | 0.0.9 | 0.2.2 |
|:---|:---|:---|
| COUNCILMAN BOBBY HENON | \| BOBBY \| \| HENON-COUNCILMAN \| | COUNCILMAN \| BOBBY \| \| HENON \| |
| SIR HUGH TAYLOR | \| HUGH \| \| TAYLOR-SIR \| | SIR \| HUGH \| \| TAYLOR \| |
| SCOTT CRABDREE CIC | \| SCOTT \| \| CRABDREE-CIC \| | CIC \| SCOTT \| \| CRABDREE \| |
| Sr Katherine Glosenger RSM | \| KATHERINE \| \| GLOSENGER-RSM \| SR | RSM \| KATHERINE \| \| GLOSENGER \| SR |
| SHERIFF KURT PICKNELL | \| KURT \| \| PICKNELL-SHERIFF \| | SHERIFF \| KURT \| \| PICKNELL \| |
| MONSIGNOR CHRISTOPHER NALTY | \| CHRISTOPHER \| \| NALTY-MONSIGNOR \| | MONSIGNOR \| CHRISTOPHER \| \| NALTY \| |
| KELLY GRATTAN PHD MBA CFRE | PHD_MBA \| KELLY \| \| GRATTAN-CFRE \| | PHD_MBA_CFRE \| KELLY \| \| GRATTAN \| |
| Aksone Nouvong DPM FACFAS | \| AKSONE \| \| NOUVONG-DPM-FACFAS \| | DPM \| AKSONE \| \| NOUVONG-FACFAS \| |
| RABBI MICHAEL BEYO | \| MICHAEL \| \| BEYO-RABBI \| | RABBI \| MICHAEL \| \| BEYO \| |
| ARCHBISHOP GINTARAS GRUSAS | \| ARCHBISHOP \| \| GINTARAS-GRUSAS \| | ARCHBISHOP \| GINTARAS \| \| GRUSAS \| |

| Name           | 0.0.9                      | 0.2.2                      |
|:---------------|:---------------------------|:---------------------------|
| Beth St George | ST \| BETH \| \| GEORGE \| | \| BETH \| \| ST-GEORGE \| |
| LEANA DA SILVA | \| LEANA \| DA \| SILVA \| | \| LEANA \| \| DA-SILVA \| |
| ERIC ST JOHN   | ST \| ERIC \| \| JOHN \|   | \| ERIC \| \| ST-JOHN \|   |

## Other changes

Most of the rest are compound surnames now kept in written order
(`GUTIERREZ-VALVERDE`), stray words fixed (`KENNETHVAN-DER-VLIET`
becomes `KENNETH VAN-DER-VLIET`) and `DO` and `DOCTOR` read as surnames.
About half are names that are wrong in both versions: an unknown
credential left in the surname (`OWENS-SSND`) or an organisation parsed
as a person.

| Name | 0.0.9 | 0.2.2 |
|:---|:---|:---|
| SR MARY ANN OWENS SSND | \| MARY \| ANN \| SSND-OWENS \| SR | \| MARY \| ANN \| OWENS-SSND \| SR |
| FRIELDEN BERTIE JONES | \| BERTIE \| \| JONES-FRIELDEN \| | \| FRIELDEN \| BERTIE \| JONES \| |
| STEPHANIE DO | DO \| \| \| STEPHANIE \| | \| STEPHANIE \| \| DO \| |
| BRIAN P GLANCEY SIOR | \| BRIAN \| P \| SIOR-GLANCEY \| | \| BRIAN \| P \| GLANCEY-SIOR \| |
| D P Thayer Montague | \| D \| P \| MONTAGUE-THAYER \| | \| D \| P \| THAYER-MONTAGUE \| |
| MARK THOMPSON VISIT PLANO | \| MARK \| \| VISIT-PLANO-THOMPSON \| | \| MARK \| \| THOMPSON-VISIT-PLANO \| |
| CHARLES DOCTOR | DOCTOR \| \| \| CHARLES \| | \| CHARLES \| \| DOCTOR \| |
| CHAD MARTIN S VILLANUEVA | \| CHAD \| \| MARTIN-S-VILLANUEVA \| | \| CHAD \| MARTIN S \| VILLANUEVA \| |
| KENNETH VAN DER VLIET | \| \| \| KENNETHVAN-DER-VLIET \| | \| KENNETH \| \| VAN-DER-VLIET \| |
| JEREMY EISEMANN LIBERTY MUTUAL INS | \| JEREMY \| \| LIBERTY-MUTUAL-INS-EISEMANN \| | \| JEREMY \| LIBERTY \| MUTUAL-INS-EISEMANN \| |
| TOBI M E YOUNG | \| TOBI \| M \| YOUNG-E \| | \| TOBI \| M E \| YOUNG \| |
| T MICHAEL REDMOND PHD FARVO | PHD \| T \| MICHAEL \| FARVO-REDMOND \| | PHD \| T \| MICHAEL \| REDMOND-FARVO \| |

## Regressions in 0.2.1 that 0.2.2 fixes

The same comparison run with 0.2.1 found names that 0.2.1 parsed worse
than 0.0.9. These were fixed in 0.2.2:

| Name | 0.2.1 | 0.2.2 |
|:---|:---|:---|
| KATRINA VANDEN HEUVEL | \| KATRINA \| VANDEN \| HEUVEL \| | \| KATRINA \| \| VANDEN-HEUVEL \| |
| PATRICIA SAN PEDRO | \| PATRICIA \| SAN \| PEDRO \| | \| PATRICIA \| \| SAN-PEDRO \| |
| ESTELLA DE LOS RIOS | \| ESTELLA \| DE-LOS \| RIOS \| | \| ESTELLA \| \| DE-LOS-RIOS \| |
| SIR HUGH TAYLOR | \| SIR \| HUGH \| TAYLOR \| | SIR \| HUGH \| \| TAYLOR \| |
| CHIEF TODD SCHMADERER | \| CHIEF \| TODD \| SCHMADERER \| | CHIEF \| TODD \| \| SCHMADERER \| |
| GEN PERRIN | \| GEN \| \| PERRIN \| | GEN \| \| \| PERRIN \| |
| COL RET CLARENCE MAXWELL | \| COL \| \| \| | COL \| CLARENCE \| \| MAXWELL \| |
| TOKS MALIK ASHIRU | \| MALIK \| \| ASHIRU-TOKS \| | \| TOKS \| MALIK \| ASHIRU \| |
| DONG JOON YI | \| JOON \| YI \| DONG \| | \| DONG \| JOON \| YI \| |
| TOBI M E YOUNG | \| TOBI \| \| M-E-YOUNG \| | \| TOBI \| M E \| YOUNG \| |
| Albert J A Young ESQ | ESQ \| ALBERT \| \| J-A-YOUNG \| | ESQ \| ALBERT \| J A \| YOUNG \| |
| BOYD RAY SCOTT | \| SCOTT \| \| BOYD-RAY \| | \| BOYD \| RAY \| SCOTT \| |
| CHIYA AYDIN AYHAN | \| AYDIN \| AYHAN \| CHIYA \| | \| AYDIN \| AYHAN \| CHIYA \| |

`CHIYA AYDIN AYHAN` is still read as surname first; see below.

## Name types

[`classify_names()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/classify_names.md)
labels 19 of the 10,000 entries (0.19%) as something other than a
person. Nearly all are right; `Sun Cheer Sheen` is a person labelled an
organisation, and `METTA WORLD PEACE` (the basketball player’s legal
name) is labelled a person and an organisation.

| Name | Type | Org score |
|:---|:---|:---|
| THE NORTHERN TRUST COMPANY | organisation | 1 |
| Northwestern Mutual Life Insurance Company | organisation | 1 |
| TEXAS HOSPITAL ASSOCIATION | organisation | 1 |
| TIAA-CREF TRUST COMPANY FSB | organisation | 1 |
| Community Bank NA | organisation | 1 |
| PENINSULA LIBRARY & HISTORICAL SOCIET | organisation | 1 |
| SPIRE ALABAMA INC | organisation | 1 |
| HUNTINGTON NATIONAL BANK | organisation | 1 |
| Hand Benefit Trust Co | organisation | 0.9999 |
| RP MARZULLI CO INC | organisation | 0.9998 |
| Metzen Marketing and Consulting LLC | organisation | 0.9997 |
| State Farm Ins Co | organisation | 0.9994 |
| Sun Cheer Sheen | organisation | 0.9943 |
| CHARLEVOIX MINISTERIAL REP | organisation | 0.9933 |
| METTA WORLD PEACE | person and organisation | 0.9989 |
| SEE ATTACHED HOURS VARY | placeholder | 0.0498 |
| VACANT | placeholder | 0.0193 |
| vacant | placeholder | 0.0193 |
| JULIE AND STEVE BROOKOVER | several people | 0.0162 |

## Gaps that persist

- **An unlisted given name before a listed name.** A word missing from
  the census counts as a likely surname, so `DR MASSUMEH FARHAD`,
  `CLEVELAND TAYLER` and `CHIYA AYDIN AYHAN` are read as written surname
  first.
- **Names written surname first with weak evidence.** The written-order
  rule keeps the order unless the census is clear, so
  `WALPERT LEVY TARA` and `Soh Yeun Kim` are read in written order.
- **Credentials the lists do not know** stay in the surname: `SSND`,
  `SIOR`, `CNHA`, `MSCJ`, `FCAP`, `FACFAS`, `CPPO`, `CPSM`, `VG`. Add
  them with `prefixes = c(prx, ...)`.
- **Organisations and notes in person fields** are parsed as people
  (`NORTHWESTERN MUTUAL LIFE INSURANCE COMPANY`,
  `PHILIP JONES VISIT DALLAS`). Use `classify = TRUE` and drop the
  entries that are not people.
- **Unisex names** (`KERRY`, `TAYLOR`, `KRIS`, `RILEY`) get a gender
  close to a coin toss.
- **Double surnames made of common given names** (`LEE`, `RAY`, `GRANT`)
  are now split into a middle name and a surname.
