# Parse Core Name Components and Gender

Uses vector length and surname heuristics to extract first, middle, and
last names, and infer gender.

## Usage

``` r
assign_names(x, suffix.name)
```

## Arguments

- x:

  A character vector of name parts (after cleaning).

- suffix.name:

  Optional suffix name for fallback gender guessing.

## Value

A list with `first`, `middle`, `last`, and `gender` (vector of code and
confidence).
