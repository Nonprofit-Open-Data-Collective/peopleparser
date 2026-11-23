# Extract Specific Name Components

Removes one element (e.g., salutation, suffix, or status flag) from a
name vector.

## Usage

``` r
extract_component(name_vec, elements)
```

## Arguments

- name_vec:

  A character vector of name parts.

- elements:

  A character vector of items to remove.

## Value

A list with `name` (the removed item or "") and `remainder` (the updated
vector).
