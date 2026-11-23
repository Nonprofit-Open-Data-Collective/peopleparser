# Split a Stray Initial Glued to a Surname

Defect 3: `CWOOLFOLK` -\> `c("C", "WOOLFOLK")`. Only splits when the
token is a single leading consonant followed by a run that is itself a
valid census surname, and the whole token is not a known census name
(guards `BLAKE`, `SHAW`, `WOOD`).

## Usage

``` r
split_glued_initial(tok)
```

## Arguments

- tok:

  A single uppercased name token.

## Value

The token unchanged, or a length-2 vector `c(initial, surname)`.
