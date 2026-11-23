# Known Titles and Abbreviations

Returns a reference table of known name titles, academic degrees,
professional credentials, military ranks, civic honorifics, and related
abbreviations. Each entry includes the abbreviation (`abbr`), its
expanded descriptive form (`label`), and a general category (`type`).

## Usage

``` r
known_titles()
```

## Value

A tibble with three columns:

- abbr:

  Character abbreviation or short form of the title.

- label:

  Expanded descriptive form of the title or credential.

- type:

  Category of the title (e.g., "Academic Degree", "Military Rank").

## Details

This dataset is intended for use in name-parsing, record linkage, and
entity resolution applications, providing a consistent reference for
recognizing and expanding abbreviated titles in personal or
organizational names.

The `type` field groups each abbreviation into broad semantic categories
such as:

- **Personal Title**: honorifics like "Mr", "Ms", or "Dr".

- **Academic Degree**: academic or professional degrees (e.g., "PhD",
  "MD", "MBA").

- **Religious Title**: ecclesiastical or clerical designations (e.g.,
  "Rev", "Fr", "Sister").

- **Civic / Political Title**: governmental or judicial titles (e.g.,
  "Senator", "Judge", "Honorable").

- **Military Rank / Affiliation**: formal ranks or affiliations (e.g.,
  "Lt", "Col", "USAF").

- **Professional Credential**: licensed or certified professional
  credentials (e.g., "CPA", "PE", "RN").

- **Organizational Role**: internal titles or positions (e.g., "CEO",
  "VP", "Ex Officio").

- **Religious Order**: post-nominals of religious congregations (e.g.,
  "SJ", "OSB", "RSM").

- **Fraternal Office**: Masonic and similar offices (e.g., "RWGM",
  "PM").

- **Military Status**: service status such as retired (e.g., "USNRET").

- **Other**: geographic or contextual markers not part of formal titles
  (e.g., "La", "ZL").

## See also

<https://en.wikipedia.org/wiki/Title>,
<https://en.wikipedia.org/wiki/List_of_post-nominal_letters>

## Examples

``` r
titles <- known_titles()
dplyr::filter(titles, abbr %in% c("MD", "CPA", "LT"))
#> # A tibble: 3 × 3
#>   abbr  label                       type                   
#>   <chr> <chr>                       <chr>                  
#> 1 MD    Doctor of Medicine          Academic Degree        
#> 2 LT    Lieutenant                  Military Rank          
#> 3 CPA   Certified Public Accountant Professional Credential

# Lookup utility example
title_lookup <- setNames(titles$label, titles$abbr)
title_lookup["PHD"]
#>                    PHD 
#> "Doctor of Philosophy" 
```
