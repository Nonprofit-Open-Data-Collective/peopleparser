# Dataset loading, the hashed census lookup, and parse_names() workers
# (data-raw/WORKERS-AND-DATA-LOADING.md, data-raw/PLAN-WORKERS-AND-NAME-ORDER.md).

test_that("the hashed census lookup matches the keyed join exactly", {
  tok <- unique(unlist(strsplit(sanitize_input(names_1000), " ")))
  tok <- c(tok, "", NA, "SMITH-JONES", "ZZZQQQXX", "SMITH", "SMITH", "MARY")
  expect_identical(get_census_data(tok), get_census_data_join(tok))
  expect_identical(get_census_data(character(0)), get_census_data_join(character(0)))
})

test_that("each dataset is loaded once per session", {
  n <- new.env(); n$calls <- 0L
  suppressMessages(trace("data", where = asNamespace("utils"), print = FALSE,
                         tracer = bquote(assign("calls", get("calls", envir = .(n)) + 1L, envir = .(n)))))
  on.exit(suppressMessages(untrace("data", where = asNamespace("utils"))), add = TRUE)
  rm(list = ls(.pp_data), envir = .pp_data)

  for (x in sanitize_input(names_1000[1:30])) parse_name(x)
  get_census_data("SMITH")
  expect_equal(n$calls, 1L)

  first_name_variants("kate")
  first_name_variants("bill")
  expect_lte(n$calls, 2L)
})

test_that("parsing does not depend on peopleparser being attached", {
  skip_on_cran()
  skip_if_not_installed("callr")
  # a subprocess loads the installed copy, so only meaningful when the code
  # under test is installed (R CMD check), not under devtools::load_all()
  skip_if(pkgload::is_dev_package("peopleparser"))
  x <- names_1000[1:100]
  attached <- parse_names(x)
  res <- callr::r(function(x) {
    loadNamespace("peopleparser")
    stopifnot(!"package:peopleparser" %in% search())
    t <- system.time(p <- peopleparser::parse_names(x))[["elapsed"]]
    list(p = p, secs = t)
  }, args = list(x = x))
  expect_identical(res$p, attached)
  expect_lt(res$secs, 10)   # was about 15 seconds per 100 names before the cache
})

test_that("parse_names() runs sequentially by default and leaves the plan alone", {
  old <- future::plan(future::sequential)
  on.exit(future::plan(old), add = TRUE)
  x <- names_1000[1:40]
  a <- parse_names(x)
  expect_true(inherits(future::plan(), "sequential"))
  expect_identical(a, parse_names(x, workers = 1))
  expect_identical(a$name, x)
})

test_that("parse_names() checks the workers argument", {
  expect_error(parse_names("JOHN SMITH", workers = 0), "workers")
  expect_error(parse_names("JOHN SMITH", workers = "many"), "workers")
  expect_error(parse_names("JOHN SMITH", workers = c(2, 3)), "workers")
})

test_that("workers = 2 gives the same parse and restores the caller's plan", {
  skip_on_cran()
  skip_if_not_installed("future")
  old <- future::plan(future::sequential)
  on.exit(future::plan(old), add = TRUE)
  x <- names_1000[1:60]
  if (pkgload::is_dev_package("peopleparser")) {
    # workers load the installed copy, which is not this development code
    expect_error(parse_names(x, workers = 2), "different peopleparser")
  } else {
    expect_identical(parse_names(x, workers = 2), parse_names(x))
  }
  expect_true(inherits(future::plan(), "sequential"))
})
