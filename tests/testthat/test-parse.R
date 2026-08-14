# Exported sample data (names_1000) is available via the loaded package.
set.seed(123)
challenging <- sample(names_1000, 100)

test_that("sanitize_input removes punctuation and uppercases", {
  out <- sanitize_input("Dr. john-smith III")
  expect_true(grepl("DR ", out))
  expect_false(grepl("\\.", out))
})

test_that("extract_component pulls prefix and leaves remainder", {
  vec <- c("MR", "JOHN", "DOE")
  res <- extract_component(vec, c("MR", "MRS"))
  expect_equal(res$name, "MR")
  expect_equal(res$remainder, c("JOHN", "DOE"))

  res2 <- extract_component(vec, c("JR"))
  expect_equal(res2$name, "")
  expect_equal(res2$remainder, vec)
})

test_that("remove_elements splits removed vs. remaining", {
  res <- remove_elements(c("MICHAEL", "JOHN", "LIVINGSTON", "III"),
                         c("JR", "II", "III", "IV"))
  expect_equal(res$names, c("MICHAEL", "JOHN", "LIVINGSTON"))
  expect_equal(res$removed_names, "III")

  none <- remove_elements(c("MICHAEL", "JOHN"), c("JR"))
  expect_equal(none$removed_names, "")
})

test_that("assign_names handles single, double, and triple word inputs", {
  out1 <- assign_names("ALONE", suffix.name = "")
  expect_equal(out1$first, "")
  expect_equal(out1$last, "ALONE")

  out2 <- assign_names(c("JANE", "DOE"), suffix.name = "")
  expect_equal(out2$first, "JANE")
  expect_equal(out2$last, "DOE")

  out3 <- assign_names(c("JOHN", "PAUL", "JONES"), suffix.name = "")
  expect_equal(out3$first, "JOHN")
  expect_equal(out3$middle, "PAUL")
  expect_equal(out3$last, "JONES")
})

test_that("resolve_middle_name shifts a surname into the last name", {
  res1 <- resolve_middle_name("van der", "Smith")
  expect_true(grepl("van-der-Smith", res1[2]) || res1[1] != "")

  res2 <- resolve_middle_name("X", "Doe")
  expect_equal(res2[2], "X-Doe")
})

test_that("get_census_data returns one row per token in order, zero-filling misses", {
  cd <- get_census_data(c("MICHAEL", "JOHN", "ZZZNOTANAME"))
  expect_s3_class(cd, "data.table")
  expect_equal(nrow(cd), 3L)
  expect_equal(cd$ordinal, 1:3)
  expect_equal(
    as.numeric(cd[cd$name == "ZZZNOTANAME",
                  c("male_value", "female_value",
                    "first_name_value", "last_name_value")][1, ]),
    c(0, 0, 0, 0)
  )
})

test_that("parse_name returns a one-row data frame with the 8 components", {
  out <- parse_name("livingston III MICHAEL JOHN")
  expect_s3_class(out, "data.frame")
  expect_equal(nrow(out), 1L)
  expect_named(out, c("salutation", "first_name", "middle_name", "last_name",
                      "suffix", "status", "gender", "gender_confidence"))
  expect_equal(out$first_name, "MICHAEL")
  expect_equal(toupper(out$last_name), "LIVINGSTON")
})

test_that("parse_name resolves a locative compound surname", {
  out <- parse_name("THOMAS H VON KAMECKE", sanitize = TRUE)
  expect_equal(out$last_name, "VON-KAMECKE")
})

test_that("parse_name parses 100 challenging names into 8-column rows", {
  results <- lapply(challenging, parse_name, sanitize = TRUE)
  expect_length(results, 100)
  expect_true(all(vapply(results, ncol, integer(1)) == 8))
  expect_true(all(vapply(results, nrow, integer(1)) == 1))
})
