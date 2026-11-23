test_that("first_name_pairs is well formed", {
  v <- first_name_pairs
  expect_true(all(c("name_short", "name_long", "type", "lexicon", "n_emp_ids",
                    "formal") %in% names(v)))
  expect_false(anyDuplicated(v[, c("name_short", "name_long")]) > 0)
  expect_true(all(v$formal[v$type == "nickname"] %in% c("short", "long")))
  expect_true(all(is.na(v$formal[v$type != "nickname"])))
  # orientation: diminutives and pet forms are the nickname side
  side <- function(s, l) v$formal[v$name_short == s & v$name_long == l]
  expect_equal(side("JOHN", "JOHNNY"), "short")
  expect_equal(side("KATHY", "KATHLEEN"), "long")
  expect_equal(side("BOB", "ROBERT"), "long")
})

test_that("nicknames resolve to their formal name", {
  r <- nickname_lookup(c("BOB", "BILL", "JACK", "JIM", "JIMMY", "PETE", "PEGGY"),
                       gender = c("M", "M", "M", "M", "M", "M", "F"), gender_confidence = 99)
  expect_equal(r$first_name_canonical,
               c("ROBERT", "WILLIAM", "JOHN", "JAMES", "JAMES", "PETER", "MARGARET"))
  expect_true(all(r$canonical_rule == "nickname"))
})

test_that("spellings collapse to the most common spelling", {
  r <- nickname_lookup(c("STEVEN", "STEPHEN", "KATHRYN", "KATHERINE"))
  expect_equal(r$first_name_canonical, c("STEPHEN", "STEPHEN", "CATHERINE", "CATHERINE"))
  expect_equal(r$canonical_rule, c("spelling", "self", "spelling", "spelling"))
  # a nickname of two spellings resolves to the shared spelling root
  expect_equal(canonical_first_name("STEVE"), "STEPHEN")
})

test_that("chains are not followed: KATHLEEN and CATHERINE stay apart", {
  r <- nickname_lookup(c("KATHLEEN", "CATHERINE", "KATE", "KATHY"), "F", 99)
  expect_equal(r$first_name_canonical[1:3], c("KATHLEEN", "CATHERINE", "CATHERINE"))
  expect_equal(r$canonical_rule[4], "ambiguous")   # KATHLEEN vs KATHERINE
})

test_that("gender picks among formal names; no usable gender means ambiguous", {
  r <- nickname_lookup(c("PAT", "PAT", "PAT", "CHRIS"), gender = c("F", "M", "U", "F"),
                       gender_confidence = c(95, 95, 50, 95))
  expect_equal(r$first_name_canonical, c("PATRICIA", "PATRICK", "PAT", "CHRIS"))
  expect_equal(r$canonical_rule[3:4], c("ambiguous", "self"))   # CHRIS (F): no female formal name
  expect_false(grepl("PATRICK", r$first_name_formal[1]))
})

test_that("a gendered salutation overrides weak census gender", {
  r <- nickname_lookup("PAT", gender = "F", gender_confidence = 60, salutation = "MRS")
  expect_equal(r$first_name_canonical, "PATRICIA")
  p <- parse_name("MRS PAT SMITH", add_nicknames = TRUE)
  expect_equal(p$first_name_canonical, "PATRICIA")
})

test_that("sibling nicknames are not listed as variants of each other", {
  r <- nickname_lookup("BETH", gender = "F", gender_confidence = 99)
  expect_false(grepl("LISA", r$first_name_formal))
  expect_false(grepl("LISA", r$first_name_nicknames))
})

test_that("initials, unknown and empty names pass through", {
  r <- nickname_lookup(c("J", "ZEBEDIAHX", ""))
  expect_equal(r$first_name_type, c("initial", "unknown", ""))
  expect_equal(r$first_name_canonical, c("J", "ZEBEDIAHX", ""))
})

test_that("parse_names adds nickname columns only on request", {
  x <- c("Dr Leslie Smith", "BOB JONES")
  expect_false("first_name_canonical" %in% names(parse_names(x)))
  p <- parse_names(x, add_nicknames = TRUE)
  expect_equal(p$first_name_canonical[2], "ROBERT")
})

test_that("standalone names are not resolved through rare nickname links", {
  # MARK/MARCUS, MARK/MARCO: MARK is a name in its own right
  expect_equal(canonical_first_name("MARK"), "MARK")
  expect_equal(canonical_first_name("MARCO"), "MARCO")
})

test_that("first_name_variants lists the family of the canonical name", {
  f <- first_name_variants("kate")
  expect_true(all(f$canonical == "CATHERINE"))
  m <- f$name[f$in_canonical]
  expect_true(all(c("CATHERINE", "KATHERINE", "KATHRYN", "KATE", "KATIE") %in% m))
  expect_false("KATHLEEN" %in% f$name)          # a separate name, joined only through KATE
  expect_equal(f$relation[f$name == "KATHY"], "ambiguous nickname")
  expect_false(f$in_canonical[f$name == "KATHY"])
  expect_equal(f$relation[f$name == "CATHERINE"], "canonical")

  s <- first_name_variants("steve", related = FALSE)
  expect_true(all(s$in_canonical))
  expect_equal(s$via[s$name == "STEVI"], "STEVE")
  expect_equal(s$relation[s$name == "STEVI"], "misspelling")

  expect_true("PAT" %in% first_name_variants("patricia", gender = "F")$name)
  expect_false("PAT" %in% first_name_variants("patricia", gender = "M")$name)

  u <- first_name_variants("zebediahx")
  expect_equal(nrow(u), 1L)
  expect_equal(u$relation, "canonical")
})
