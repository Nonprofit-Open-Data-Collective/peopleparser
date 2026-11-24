# Features for the Organisation Model

One row of features per cleaned name. Used both to train the model
(`data-raw/name_type_model.R`) and by
[`classify_names()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/classify_names.md).

## Usage

``` r
org_features(cl, vocab)
```

## Arguments

- cl:

  Cleaned names from `clean_for_classify()`.

- vocab:

  An environment mapping words to word scores.

## Value

A `data.frame` of features.
