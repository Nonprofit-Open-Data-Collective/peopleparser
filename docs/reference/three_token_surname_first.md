# Is a Three-Token Name Written Surname First?

Applies the written-order prior of
[`two_token_surname()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/two_token_surname.md)
to the first and last tokens: `DONG JOON YI` and `TOKS MALIK ASHIRU`
keep their order, and only a strong census surname before a strong given
name is reordered (`SMITH JOHN ROBERT` -\> `JOHN ROBERT SMITH`). This
replaced a rule that read any unlisted word as a surname. On 28,811
three-word Part VII names labelled by the convention of their return it
makes 235 order errors against 1,298 (see data-raw/name_order_eval3.R).

## Usage

``` r
three_token_surname_first(x)
```

## Arguments

- x:

  A length-3 character vector of name tokens.

## Value

`TRUE` when the name should be read as surname, given, middle.
