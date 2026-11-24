test_that("classify_names() sorts people, organisations, couples and notes", {
  x <- c("JOHN A SMITH", "Mary Garcia Lopez", "PNC BANK NA", "THE NORTHERN TRUST COMPANY",
         "TEAMSTERS LOCAL NO 338", "FARIBAULT AREA CHAMBER OF COMMERCE",
         "SEE SCHEDULE O", "VACANT", "NO COMPENSATED OFFICERS", "",
         "MICHAEL AND ASHLEY SMITH", "JAMES LUISI NORTH END COMMUNITY HC",
         "KURT SUZUKI FAMILY FOUNDATION", NA)
  ct <- classify_names(x)
  expect_identical(names(ct), c("name", "name_type", "org_score"))
  expect_identical(ct$name, x)
  expect_identical(ct$name_type, c(
    "person", "person", "organisation", "organisation", "organisation",
    "organisation", "placeholder", "placeholder", "placeholder", "placeholder",
    "several people", "person and organisation", "organisation", "placeholder"))
  expect_true(all(ct$org_score[1:2] < 0.5))
  expect_true(all(ct$org_score[3:6] > 0.95))
})

test_that("people whose names are also words or surnames stay people", {
  x <- c("LARRY CHURCH", "KEVIN CENTER", "JOHN BISHOP", "MARY BANKS",
         "RICHARD RUVIN", "HARRIS MORRISON", "S KRISHNAN", "SMITH JOHN A",
         "TSHEPO CHO", "NGUYEN THANH", "BOB HOPE", "JOY WELLS")
  expect_identical(classify_names(x)$name_type, rep("person", length(x)))
})

test_that("classify_names() checks threshold and handles empty input", {
  expect_error(classify_names("JOHN SMITH", threshold = 2), "threshold")
  expect_identical(nrow(classify_names(character(0))), 0L)
  expect_identical(classify_names("TEAMSTERS LOCAL NO 338", threshold = 1)$name_type, "person")
})

test_that("banks written without an organisation word, couples and notes", {
  x <- c("BNY MELLON", "Wells Fargo", "THE BANK OF NEW YORK MELLON",
         "Rodito and Tita Ocfemia", "SEE MOUA", "Drupatti Phulbas as of 624",
         "MARY SHURTS - LHS INC", "PAULA MILLER")
  expect_identical(classify_names(x)$name_type, c(
    "organisation", "organisation", "organisation", "several people", "person",
    "person", "person and organisation", "person"))
})

test_that("split_run_together() splits run-together names only", {
  x <- c("KramerKenneth", "LedbetterJennifer A", "Ledbetter-Jennifer", "MURPHYSANDRA",
         "KLINESUZANNE", "McDonald", "MacArthur Smith", "LaToya Jones", "DeShawn Lee",
         "JOHN MARKWALD", "MARKWALD J", "PEARLSTONE", "WILLIAMSON", "John Smith",
         "KramerKenneth,", NA)
  expect_identical(split_run_together(x), c(
    "Kramer Kenneth", "Ledbetter Jennifer A", "Ledbetter-Jennifer", "MURPHY SANDRA",
    "KLINE SUZANNE", "McDonald", "MacArthur Smith", "LaToya Jones", "DeShawn Lee",
    "JOHN MARKWALD", "MARKWALD J", "PEARLSTONE", "WILLIAMSON", "John Smith",
    "Kramer Kenneth,", NA))
})

test_that("split_run_together is opt-in in parse_names() and parse_name()", {
  x <- c("LedbetterJennifer A", "KramerKenneth", "John Smith")
  off <- parse_names(x)
  on  <- parse_names(x, split_run_together = TRUE)
  expect_identical(off$last_name[1:2], c("LEDBETTERJENNIFER", "KRAMERKENNETH"))
  expect_identical(on$first_name, c("JENNIFER", "KENNETH", "JOHN"))
  expect_identical(on$last_name, c("LEDBETTER", "KRAMER", "SMITH"))
  expect_identical(on$name, x)
  p <- parse_name("KramerKenneth", sanitize = TRUE, split_run_together = TRUE)
  expect_identical(c(p$first_name, p$last_name), c("KENNETH", "KRAMER"))
})

test_that("parse_names(classify = TRUE) adds the name type columns", {
  x <- c("JOHN A SMITH", "PNC BANK NA", "SEE SCHEDULE O")
  p <- parse_names(x, classify = TRUE)
  expect_identical(p$name_type, c("person", "organisation", "placeholder"))
  expect_true(is.numeric(p$org_score))
  expect_false(any(c("name_type", "org_score") %in% names(parse_names(x))))
})
