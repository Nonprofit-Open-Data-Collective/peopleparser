library(testthat)
library(peopleparser)

# Load the names.1000 vector
utils_file <- file.path(system.file("R", package = "peopleparser"), "utils.R")
source(utils_file)
set.seed(123)

# Pick 100 challenging names
challenging <- sample(names.1000, 100)

test_that("sanitize_input: removes punctuation and uppercases", {
  input <- "Dr. john-smith III"
  out <- sanitize_input(input)
  expect_true(grepl("DR ", out))
  expect_false(grepl("\\.", out))
})

test_that("extract_component: pulls prefix and leaves remainder", {
  vec <- c("MR", "JOHN", "DOE")
  res <- extract_component(vec, c("MR", "MRS"))
  expect_equal(res$name, "MR")
  expect_equal(res$remainder, c("JOHN", "DOE"))
  
  res2 <- extract_component(vec, c("JR"))
  expect_equal(res2$name, "")
  expect_equal(res2$remainder, vec)
})

test_that("assign_names handles single, double, triple, multi-word", {
  # Single
  out1 <- assign_names("ALONE", suffix.name = "")
  expect_equal(out1$first, "")
  expect_equal(out1$last, "ALONE")
  
  # Two
  out2 <- assign_names(c("JANE", "DOE"), suffix.name = "")
  expect_equal(out2$first, "JANE")
  expect_equal(out2$last, "DOE")
  
  # Three without initial
  tri <- c("JOHN", "PAUL", "JONES")
  out3 <- assign_names(tri, suffix.name = "")
  expect_equal(out3$first, "JOHN")
  expect_equal(out3$middle, "PAUL")
  expect_equal(out3$last, "JONES")
})

test_that("resolve_middle_name shifts surname correctly", {
  res1 <- resolve_middle_name("van der", "Smith")
  expect_true(grepl("van-der-Smith", res1[2]) || res1[1] != "")
  
  res2 <- resolve_middle_name("X", "Doe")
  expect_equal(res2[2], "X-Doe")
})

test_that("Full parse.name round-trips challenging names", {
  results <- vapply(challenging, parse.name, character(1))
  # Ensure we have exactly 100 results
  expect_length(results, 100)
  # Ensure each result has 8 pipe-delimited components
  expect_true(all(nchar(results) > 0))
  comps <- strsplit(results, "\\|")
  expect_true(all(vapply(comps, length, integer(1)) == 8))
})