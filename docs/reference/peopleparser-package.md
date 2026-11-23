# peopleparser: Parse Raw Person Names into Structured Components

Converts raw text names into structured components (salutation, first
name, middle name, last name, suffix, and status) and infers gender
using U.S. Census name-frequency data. Proper name ordering is
disambiguated probabilistically based on how often each token appears in
the first-name versus last-name position. First names can be linked to
their formal names, nicknames and spelling variants, and reduced to one
canonical form, using a variant table observed in Form 990 filings.

## See also

Useful links:

- <https://github.com/Nonprofit-Open-Data-Collective/peopleparser>

- Report bugs at
  <https://github.com/Nonprofit-Open-Data-Collective/peopleparser/issues>

## Author

**Maintainer**: Jesse Lecy <jdlecy@gmail.com>

Authors:

- Michael Flanigan (Original Name-Parser author)
