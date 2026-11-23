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

# --- Regression: title/given-name collisions (2026-08) ---------------------

test_that("given-name honorifics are not stripped as titles (EARL, ZOLA)", {
  earl <- parse_name("EARL FAHNESTOCK", sanitize = TRUE)
  expect_equal(earl$first_name, "EARL")
  expect_equal(earl$last_name,  "FAHNESTOCK")
  expect_equal(earl$salutation, "")

  zola <- parse_name("ZOLA BUDD", sanitize = TRUE)
  expect_equal(zola$first_name, "ZOLA")
  expect_equal(zola$last_name,  "BUDD")
})

test_that("EARL removed from prefix list resolves multi-token names", {
  out <- parse_name("EARL DEAN SMITH", sanitize = TRUE)
  expect_equal(out$first_name, "EARL")
  expect_equal(out$last_name,  "SMITH")
})

test_that("a token that is both a title and a surname keeps order by position", {
  # trailing MAJOR is the surname; the remaining token is the first name
  tm <- parse_name("TOM MAJOR", sanitize = TRUE)
  expect_equal(tm$first_name, "TOM")
  expect_equal(tm$last_name,  "MAJOR")
  expect_equal(tm$gender,     "M")

  sm <- parse_name("SUE MAJOR", sanitize = TRUE)
  expect_equal(sm$first_name, "SUE")
  expect_equal(sm$last_name,  "MAJOR")
  expect_equal(sm$gender,     "F")

  # leading MAJOR is treated as the given name
  ms <- parse_name("MAJOR SMITH", sanitize = TRUE)
  expect_equal(ms$first_name, "MAJOR")
  expect_equal(ms$last_name,  "SMITH")
})

# --- Regression: post-nominal credentials leaking into last_name -----------
# Defect 1, data-raw/PARSE-FAIL-NOTES.md. Trailing health-care credential runs
# used to glue into the surname, e.g. "MARTINO EDD RTR FASRT CAE" ->
# last_name = "RTR-FASRT-MARTINO". They should now strip cleanly.

test_that("trailing health-care credentials strip out of last_name", {
  out <- parse_name("Salvatore Martino EdD RTR FASRT CAE", sanitize = TRUE)
  expect_equal(out$first_name, "SALVATORE")
  expect_equal(out$last_name,  "MARTINO")

  # each newly added credential, individually, is stripped and not glued in
  for (cred in c("RTR", "FASRT", "RDMS", "RVT", "LCSW",
                 "MHA", "CNMT", "CRA", "MSRS")) {
    res <- parse_name(paste("KAREN LEE", cred), sanitize = TRUE)
    expect_equal(res$last_name, "LEE",
                 info = paste("credential:", cred))
    expect_false(grepl(cred, res$last_name, fixed = TRUE),
                 info = paste("credential leaked:", cred))
  }
})

test_that("newly added credentials appear in known_titles()", {
  kt <- known_titles()
  expect_true(all(c("RTR", "FASRT", "RDMS", "RVT", "LCSW", "MHA",
                    "CNMT", "CRA", "MSRS", "CAE") %in% kt$abbr))
})

# --- Regression: title glued to given name with no space (Defect 2) --------

test_that("a title fused to a given name is split and stripped", {
  w <- parse_name("MRWILLIAM SMITH", sanitize = TRUE)
  expect_equal(w$salutation, "MR")
  expect_equal(w$first_name, "WILLIAM")
  expect_equal(w$last_name,  "SMITH")

  d <- parse_name("DRJOHN ADAMS", sanitize = TRUE)
  expect_equal(d$salutation, "DR")
  expect_equal(d$first_name, "JOHN")

  h <- parse_name("MRHENRY", sanitize = TRUE)
  expect_equal(h$salutation, "MR")
  expect_equal(h$last_name,  "HENRY")
})

test_that("names that merely start with a title fragment are not split", {
  for (nm in list(c("FREDDIE", "MERCURY"),
                  c("FRANK",   "SINATRA"),
                  c("DREW",    "BARRYMORE"))) {
    r <- parse_name(paste(nm[1], nm[2]), sanitize = TRUE)
    expect_equal(r$first_name, nm[1], info = nm[1])
    expect_equal(r$salutation, "",    info = nm[1])
  }
})

# --- Regression: ambiguous short credential RM (Defect 1 follow-up) ---------

test_that("RM strips only inside a corroborated trailing credential run", {
  # RM alongside a known credential in the trailing run -> stripped
  run <- parse_name("KAREN LEE RDMS RM", sanitize = TRUE)
  expect_equal(run$last_name, "LEE")
  expect_true(grepl("RM", run$salutation))

  # standalone trailing RM (no other credential) -> left in place, not a title
  solo <- parse_name("KAREN LEE RM", sanitize = TRUE)
  expect_equal(solo$salutation, "")

  # real name that happens to contain the token must be untouched
  ma <- parse_name("MA LIN", sanitize = TRUE)
  expect_equal(ma$first_name, "MA")
  expect_equal(ma$last_name,  "LIN")
})

# --- Regression: stray initial glued to surname (Defect 3, opt-in) ----------

test_that("stray-initial split is off by default and on via split_initials", {
  off <- parse_name("WILLIAM CWOOLFOLK", sanitize = TRUE)
  expect_equal(off$last_name, "CWOOLFOLK")

  on <- parse_name("WILLIAM CWOOLFOLK", sanitize = TRUE, split_initials = TRUE)
  expect_equal(on$first_name,  "WILLIAM")
  expect_equal(on$middle_name, "C")
  expect_equal(on$last_name,   "WOOLFOLK")

  # a short foreign given name must not be split as initial + surname on the
  # default path. (With the 1990 first-name lists KYUN was unknown and was
  # glued into the surname; the 2020 lists know it as a given name.)
  kyun <- parse_name("SUNG KYUN WOO MD", sanitize = TRUE)
  expect_equal(c(kyun$first_name, kyun$middle_name, kyun$last_name), c("SUNG", "KYUN", "WOO"))
})

test_that("real titles still strip and are not restored as names", {
  mr <- parse_name("MR SMITH", sanitize = TRUE)
  expect_equal(mr$salutation, "MR")
  expect_equal(mr$first_name, "")
  expect_equal(mr$last_name,  "SMITH")

  dr <- parse_name("DR JANE GOODALL", sanitize = TRUE)
  expect_equal(dr$salutation, "DR")
  expect_equal(dr$first_name, "JANE")
  expect_equal(dr$last_name,  "GOODALL")
})

test_that("census.names is the 2020 Census table and surnames win ties", {
  expect_true(data.table::is.data.table(census.names))
  expect_equal(data.table::key(census.names), "name")
  expect_equal(nrow(census.names), 195311L)
  smith <- census.names[census.names$name == "SMITH", ]
  expect_equal(smith$last_name_value, 2369644)
  expect_equal(smith$first_name_value, smith$male_value + smith$female_value)
  # SMITH is also a rare given name in 2020; it must still beat an unknown token
  expect_equal(parse_name("SJ SMITH", sanitize = TRUE)$last_name, "SMITH")
  expect_equal(parse_name("BEGIN SMITH", sanitize = TRUE)$last_name, "SMITH")
})

test_that("two-token names: leading initials, strong surnames, leading titles", {
  pn <- function(x) { r <- parse_name(x, sanitize = TRUE); c(r$salutation, r$first_name, r$last_name) }
  # an unlisted leading token of one or two letters is initials
  expect_equal(pn("HM CHERRY"), c("", "HM", "CHERRY"))
  expect_equal(pn("DC ALLEN"), c("", "DC", "ALLEN"))
  expect_equal(pn("J MARKEL"), c("", "J", "MARKEL"))
  # a trailing initial left after stripping keeps the old ranking
  expect_equal(pn("THOMAS H LEED")[2:3], c("THOMAS", "H"))
  # a listed token with surname share >= 0.85 beats an unlisted token
  expect_equal(pn("NICKHATH SHERIFF"), c("", "NICKHATH", "SHERIFF"))
  expect_equal(pn("SANRDA COHEN"), c("", "SANRDA", "COHEN"))
  # names that are also common given names do not (IRWIN 0.84, HOWARD 0.65)
  expect_equal(pn("HOWARD SITRON"), c("", "HOWARD", "SITRON"))
  expect_equal(pn("RABBI IRWIN ZEPLOWITZ"), c("RABBI", "IRWIN", "ZEPLOWITZ"))
  # a leading title before a non-given name is a title
  expect_equal(pn("SHERIFF MASRY"), c("SHERIFF", "", "MASRY"))
  expect_equal(pn("BROTHER STEWART"), c("BROTHER", "", "STEWART"))
  # ...but not before a given name or an initial (may be written surname first)
  expect_equal(pn("BISHOP JOHN"), c("", "JOHN", "BISHOP"))
  expect_equal(pn("BISHOP J"), c("", "J", "BISHOP"))
})

test_that("a split MC surname is joined, not truncated", {
  pn <- function(x) { r <- parse_name(x, sanitize = TRUE); c(r$first_name, r$middle_name, r$last_name) }
  expect_equal(pn("CHARLES MC SPADDEN"), c("CHARLES", "", "MCSPADDEN"))
  expect_equal(pn("DENISE MC DERMOTT"), c("DENISE", "", "MCDERMOTT"))
  expect_equal(pn("JOHN L MC DONNELL JR"), c("JOHN", "L", "MCDONNELL"))
  expect_equal(join_mc(c("STEVE MC CORMICK", "MC OLSON", "JOHN SMITH MC", "FRED SANFORD MC USN", "MC NELLY TORRES", "")),
               c("STEVE MCCORMICK", "MC OLSON", "JOHN SMITH MC", "FRED SANFORD MC USN", "MC-NELLY TORRES", ""))
})

test_that("MC: initials at the start, a credential at the end", {
  pn <- function(x) { r <- parse_name(x, sanitize = TRUE); c(r$salutation, r$first_name, r$last_name) }
  expect_equal(pn("MC OLSON")[2:3], c("MC", "OLSON"))
  expect_equal(pn("WAYNE DARVILLE MC"), c("MC", "WAYNE", "DARVILLE"))
  expect_equal(pn("RADM FREDERIC G SANFORD MC USN RET")[3], "SANFORD")
  expect_equal(pn("Neil A Halpern MC MCCM FACP")[3], "HALPERN")
  expect_equal(fix_locative_surnames("JOHN MC COY"), "JOHN MC COY")   # MC is no longer a particle
})
