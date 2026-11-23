# Repair Glued Tokens in a Name Vector

Always applies
[`split_glued_honorific()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/split_glued_honorific.md)
(Defect 2), and from the third token on
[`split_glued_credentials()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/split_glued_credentials.md)
(`JRMD`, `MDMPH`). The stray-initial split
[`split_glued_initial()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/split_glued_initial.md)
(Defect 3) is applied only when `split_initials` is `TRUE`, because it
cannot be made safe from a single record: a foreign given name absent
from the census (e.g. `KYUN`) is indistinguishable from a glued
initial + surname (`C` + `WOOLFOLK`) on frequency alone, so it should
run only where cross-year consensus (synthid) can vet the result.

## Usage

``` r
deglue_tokens(name_vec, split_initials = FALSE)
```

## Arguments

- name_vec:

  A character vector of name tokens.

- split_initials:

  Logical; enable the Defect 3 stray-initial split. Defaults to `FALSE`.

## Value

A character vector, possibly longer than the input.
