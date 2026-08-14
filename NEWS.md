# peopleparser (development version)

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
