# Package datasets, loaded once per session.
#
# A bare reference to a LazyData dataset inside package code only resolves
# when peopleparser is attached (library()). Loaded but not attached -- as with
# peopleparser::parse_name() or in a future worker -- the old
# `if (!exists(...)) utils::data(...)` guards reloaded the table into a local
# environment on every lookup, about 25 times slower. These accessors load
# each table into a package environment the first time it is needed.

.pp_data <- new.env(parent = emptyenv())

pp_dataset <- function(name) {
  if (is.null(.pp_data[[name]])) {
    utils::data(list = name, package = "peopleparser", envir = .pp_data)
  }
  .pp_data[[name]]
}

# census.names, keyed on `name` (see get_census_data()).
census_names_table <- function() {
  d <- .pp_data[["census.names.keyed"]]
  if (is.null(d)) {
    d <- data.table::copy(data.table::as.data.table(pp_dataset("census.names")))
    if (!identical(data.table::key(d), "name")) data.table::setkeyv(d, "name")
    .pp_data[["census.names.keyed"]] <- d
  }
  d
}

first_name_pairs_table <- function() pp_dataset("first_name_pairs")

# Row of each token in census_names_table(), 0 when absent. A hashed
# environment (name -> row), built once per session, makes each lookup a hash
# probe instead of a join.
census_row <- function(x) {
  h <- .pp_data[["census.index"]]
  if (is.null(h)) {
    nm <- census_names_table()$name
    h <- list2env(as.list(stats::setNames(seq_along(nm), nm)),
                  hash = TRUE, size = length(nm))
    .pp_data[["census.index"]] <- h
  }
  ok <- !is.na(x) & nzchar(x)
  out <- integer(length(x))
  if (any(ok)) {
    out[ok] <- unlist(mget(x[ok], envir = h, ifnotfound = list(0L)),
                      use.names = FALSE)
  }
  out
}
