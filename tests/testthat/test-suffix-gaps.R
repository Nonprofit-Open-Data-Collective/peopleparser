# Suffix gaps on Form 990 Part VII names (data-raw/SUFFIX-GAPS-PART7.md).
pn <- function(x) parse_name(x, sanitize = TRUE)

test_that("tier 1 credentials and religious orders are stripped", {
  expect_equal(pn("Sister Maureen Reardon RSM")$last_name, "REARDON")
  expect_equal(pn("THERESA TRAN CSJ")$last_name, "TRAN")
  expect_equal(pn("SALVATORE MASON PHARMD")$last_name, "MASON")
  expect_equal(pn("AMY LEE MD FACP")$last_name, "LEE")
  expect_equal(pn("JOE BLOW ESQUIRE")$last_name, "BLOW")
  expect_equal(pn("JOHN DOE USNRET")$last_name, "DOE")
  expect_equal(pn("MARY JONES CFRE")$last_name, "JONES")
})

test_that("hyphenated credentials are stripped whole", {
  expect_equal(pn("JANE DOE PA-C")$last_name, "DOE")
  expect_equal(pn("PAT JONES SHRM-SCP")$last_name, "JONES")
})

test_that("trailing-only titles strip at the end but not as initials or alone", {
  r <- pn("JOHN SMITH SJ")
  expect_equal(c(r$first_name, r$last_name), c("JOHN", "SMITH"))
  expect_equal(pn("SJ SMITH")$first_name, "SJ")          # initials, kept
  expect_equal(pn("LARRY BLACK SECRETARY")$last_name, "BLACK")
  expect_equal(pn("JOHN MA TRUSTEE")$last_name, "MA")
  expect_equal(pn("MARY ANN SMITH VICE CHAIR")$last_name, "SMITH")
  expect_equal(pn("JOHN VICE")$last_name, "VICE")        # VICE alone is a surname
})

test_that("ambiguous short credentials strip only inside a credential run", {
  expect_equal(pn("KATHY WILDE RN MA")$last_name, "WILDE")
  expect_equal(pn("JACK MA")$last_name, "MA")
  expect_equal(pn("MA LIN")$first_name, "MA")
  expect_equal(pn("JOHN DOE DC")$last_name, "DOE")       # lone DC after a surname (0.2.4)
  expect_equal(pn("JOHN DOE MD DC")$last_name, "DOE")
  expect_equal(pn("MAUREEN SMITH RSM MA TERM ENDED")$last_name, "SMITH")
})

test_that("prefixes strip; leading-only ones keep the surname", {
  expect_equal(pn("RABBI DAVID COHEN")$last_name, "COHEN")
  expect_equal(pn("MOST REV JOHN SMITH")$last_name, "SMITH")
  r <- pn("BISHOP JOHN SMITH")
  expect_equal(c(r$salutation, r$first_name, r$last_name), c("BISHOP", "JOHN", "SMITH"))
  expect_equal(pn("JOHN BISHOP")$last_name, "BISHOP")
  expect_equal(pn("MARY JANE BISHOP")$last_name, "BISHOP")
})

test_that("tenure notes go to status only at the end", {
  expect_equal(pn("BOB JONES NON VOTING")$status, "NONVOTING")
  expect_equal(pn("BOB JONES NON VOTING")$last_name, "JONES")
  expect_equal(pn("TOM BEGIN")$last_name, "BEGIN")
  expect_equal(pn("BEGIN SMITH")$first_name, "BEGIN")
})

test_that("ST, VANDER and DR PH are joined in prep_name", {
  expect_equal(pn("SEAN ST CLAIR")$last_name, "ST-CLAIR")
  expect_equal(pn("ROBERT ST PETER")$last_name, "ST-PETER")
  expect_equal(pn("ANNE H VANDER GHEYNST")$last_name, "VANDER-GHEYNST")
  expect_equal(pn("JANE DOE DR PH")$last_name, "DOE")
})

test_that("known_titles covers the new tokens without duplicates", {
  kt <- known_titles()
  expect_false(anyDuplicated(kt$abbr) > 0)
  expect_true(all(c("SJ", "RSM", "PA-C", "MA", "OP", "RABBI", "BISHOP", "TRUSTEE") %in% kt$abbr))
  expect_equal(kt$type[kt$abbr == "CSC"], "Religious Order")
})

test_that("short religious-order post-nominals strip at the end, not as initials", {
  expect_equal(pn("SISTER CATHERINE BAZAR OP")$last_name, "BAZAR")
  expect_equal(pn("SR VIVIENNE JOYCE SC")$last_name, "JOYCE")
  expect_equal(pn("FR JORGE RATIVA OP")$last_name, "RATIVA")
  expect_equal(pn("SR ANN M HORGAN SP")$last_name, "HORGAN")
  expect_equal(pn("Most Rev Richard C Hanifen DD")$last_name, "HANIFEN")
  expect_equal(pn("CR HACKWORTHY")$first_name, "CR")        # initials, kept
  r <- pn("HM CHERRY"); expect_true("HM" %in% c(r$first_name, r$last_name))   # kept (order is census-based)
  r <- pn("BRUCE DD MACRAE")
  expect_equal(c(r$first_name, r$last_name), c("BRUCE", "MACRAE"))
  expect_equal(r$middle_name, "DD")
})

test_that("fused credentials are split and stripped", {
  r <- pn("JOHN SMITH JRMD")
  expect_equal(c(r$first_name, r$last_name, r$suffix), c("JOHN", "SMITH", "JR"))
  expect_equal(pn("ANNA LEE MDMPH")$last_name, "LEE")
  expect_equal(pn("JANE ROE PHDMPH")$last_name, "ROE")
  expect_equal(split_glued_credentials("JRMD"), c("JR", "MD"))
  expect_equal(split_glued_credentials("COVERY"), "COVERY")      # a surname
  expect_equal(split_glued_credentials("EXOFFICIO"), "EXOFFICIO") # a status word
  expect_equal(pn("RONALD H COVERY JR")$last_name, "COVERY")
})

test_that("a leading religious title licenses DC and MA at the end", {
  expect_equal(pn("SR ELLEN KRON DC")$last_name, "KRON")
  expect_equal(pn("Sister Marie Rachelle Cruz DC")$last_name, "CRUZ")
  expect_equal(pn("SR PATRICIA MCLAUGHLIN MA")$last_name, "MCLAUGHLIN")
  expect_true("MA" %in% unlist(pn("SR ANNA MA")[c("first_name", "last_name")]))  # one name between: kept
  expect_equal(pn("JOHN DOE DC")$last_name, "DOE")         # 0.2.4: DC is not a census name
  expect_equal(pn("Palmer Piana DC")$last_name, "PIANA")
  expect_equal(pn("LINDA ROCK BA")$last_name, "BA")       # BA is a surname; ROCK is not a strong one
})
