# Package index

## Parse names

Top-level entry points for turning raw names into structured components.

- [`parse_name()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_name.md)
  : Parse a Full Name into Components
- [`parse_names()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_names.md)
  : Parse a Vector of Names

## Prepare & clean

Sanitize and normalize raw name strings before parsing.

- [`sanitize_input()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/sanitize_input.md)
  : Sanitize Raw Name Input
- [`prep_name()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/prep_name.md)
  : Prep a Name for Parsing
- [`de_clutter()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/de_clutter.md)
  : Remove Nuisance Text From a Name
- [`trim_spaces()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/trim_spaces.md)
  : Collapse and Trim Whitespace
- [`remove_punctuation()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/remove_punctuation.md)
  : Remove Punctuation
- [`fix_locative_surnames()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/fix_locative_surnames.md)
  : Fix Locative or Compound Surnames by Adding Dashes
- [`remove_elements()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/remove_elements.md)
  : Remove Character Elements From a Vector
- [`extract_component()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/extract_component.md)
  : Extract Specific Name Components

## Census-based inference

Resolve name ordering, surnames, and gender from census frequencies.

- [`get_census_data()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/get_census_data.md)
  : Look Up Census Name-Frequency Data for a Character Vector
- [`check_if_surname()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/check_if_surname.md)
  : Check Whether Tokens Read as Surnames
- [`determine_gender()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/determine_gender.md)
  : Infer Gender from a Census Name Matrix
- [`determine_surname()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/determine_surname.md)
  : Determine the Surname (Last Name) Position
- [`assign_names()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/assign_names.md)
  : Parse Core Name Components and Gender
- [`resolve_middle_name()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/resolve_middle_name.md)
  : Resolve Middle Names as Potential Surnames

## Nicknames and canonical first names

Formal names, nicknames, spelling variants and one canonical form per
first name.

- [`nickname_lookup()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/nickname_lookup.md)
  : Look up nicknames, formal names and a canonical form for first names
- [`canonical_first_name()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/canonical_first_name.md)
  : Canonical first name
- [`first_name_variants()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/first_name_variants.md)
  : All variants in a first name's family
- [`get_formal_names()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/get_formal_names.md)
  : Formal names of a nickname
- [`get_nicknames()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/get_nicknames.md)
  : Nicknames of a formal first name
- [`first_name_pairs`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/first_name_pairs.md)
  : First-name variants: nicknames, spellings, cognates and compounds.

## Reference data

Bundled datasets and lookup tables.

- [`census.names`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/census.names.md)
  : Frequency of name occurrence on US birth certificates.
- [`known_titles()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/known_titles.md)
  : Known Titles and Abbreviations
- [`prx`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/prx.md)
  : Known Prefix (Salutation / Title) Strings
- [`sfx`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/sfx.md)
  : Known Suffix Strings
- [`names_100`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/names_100.md)
  : Sample of 100 Names for Testing
- [`names_1000`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/names_1000.md)
  : Sample of 1,000 Names for Testing
- [`get_example_names()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/get_example_names.md)
  : Build a test sample of names from IRS 990s
