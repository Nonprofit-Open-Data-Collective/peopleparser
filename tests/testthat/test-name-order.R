# Regression tests for name-order and compound-surname bugs found while
# writing the name-order and gender-scoring vignettes.

pn <- function(x) parse_name(x, sanitize = TRUE)

test_that("VAN DER keeps the space before it", {
  expect_equal(prep_name("MARY VAN DER BERG"), "MARY VAN-DER-BERG")
  r <- pn("MARY VAN DER BERG")
  expect_equal(r$first_name, "MARY")
  expect_equal(r$last_name, "VAN-DER-BERG")
})

test_that("particle chains join fully (DE LA ROSA)", {
  expect_equal(fix_locative_surnames("Carlos De La Rosa"), "Carlos De-La-Rosa")
  expect_equal(fix_locative_surnames("CARLOS DE-LA ROSA"), "CARLOS DE-LA-ROSA")
  expect_equal(fix_locative_surnames("Dylan Van"), "Dylan Van")
  r <- pn("JUAN CARLOS DE LA ROSA")
  expect_equal(r$first_name, "JUAN")
  expect_equal(r$middle_name, "CARLOS")
  expect_equal(r$last_name, "DE-LA-ROSA")
  expect_equal(pn("ANNA MARIA DE LA CRUZ")$last_name, "DE-LA-CRUZ")
})

test_that("double surnames keep their written order", {
  r <- pn("MARY ANN SMITH JONES")
  expect_equal(r$middle_name, "ANN")
  expect_equal(r$last_name, "SMITH-JONES")
  expect_equal(pn("MARIA GARCIA LOPEZ")$last_name, "GARCIA-LOPEZ")
  expect_equal(pn("ELIZABETH ANNE WALKER SMITH")$last_name, "WALKER-SMITH")
})

test_that("three-word names keep their written order unless clearly surname first", {
  r <- pn("SMITH JOHN ROBERT")
  expect_equal(c(r$first_name, r$middle_name, r$last_name), c("JOHN", "ROBERT", "SMITH"))
  r <- pn("DONG JOON YI")
  expect_equal(c(r$first_name, r$middle_name, r$last_name), c("DONG", "JOON", "YI"))
  r <- pn("TOKS MALIK ASHIRU")
  expect_equal(c(r$first_name, r$last_name), c("TOKS", "ASHIRU"))
  r <- pn("BOYD RAY SCOTT")
  expect_equal(c(r$first_name, r$middle_name, r$last_name), c("BOYD", "RAY", "SCOTT"))
})

test_that("a middle name that is also a surname stays the middle name", {
  expect_equal(pn("JOHN LEE SMITH")$middle_name, "LEE")
  expect_equal(pn("BILLY RAY JONES")$last_name, "JONES")
  expect_equal(pn("TOBI M E YOUNG")$middle_name, "M E")
  expect_equal(pn("Albert J A Young ESQ")$last_name, "YOUNG")
  r <- pn("Glynn C W Scott")
  expect_equal(c(r$first_name, r$middle_name, r$last_name), c("GLYNN", "C W", "SCOTT"))
  expect_equal(pn("COUNCILMAN BOBBY HENON")$first_name, "BOBBY")
})

test_that("unknown trailing credentials are stripped, unlisted surnames kept", {
  expect_equal(pn("ANDREA M GORDON NMF")$last_name, "GORDON")
  expect_equal(pn("ANTHONY F CHONG MD FAAFP")$last_name, "CHONG")
  expect_equal(pn("Brian Fritz UHC")$last_name, "FRITZ")
  expect_equal(pn("SUSAN M ROBEL RN BSN MHA NEA-BC")$last_name, "ROBEL")
  expect_equal(pn("Samuel C Scott III NMHC")$last_name, "SCOTT")
  expect_equal(pn("MARGARET RUSSELL SR MANAGER")$last_name, "RUSSELL")
  expect_equal(pn("ROBERT J SLOAN CO-CHAIR")$last_name, "SLOAN")
  expect_equal(pn("Cynthia Simon Skjodt")$last_name, "SKJODT")
  expect_equal(pn("Noreen Gordon Sablotsky")$last_name, "SABLOTSKY")
  expect_equal(pn("MARISSA PIAZZA PASKY")$last_name, "PIAZZA-PASKY")
  expect_equal(pn("MOHAMMED M AL HAEMLI")$last_name, "AL-HAEMLI")
})

test_that("a lone ambiguous credential at the end is stripped after a surname", {
  expect_equal(pn("CAROL RUSSELL NP")$last_name, "RUSSELL")
  expect_equal(pn("ERIC HARTMAN DC")$last_name, "HARTMAN")
  expect_equal(pn("JOHN BURKE MA")$last_name, "BURKE")
  expect_equal(pn("XIAOYI ALICIA MA")$last_name, "MA")
  expect_equal(pn("MAMADOU YACINE BA")$last_name, "BA")
  expect_equal(pn("WEI MA")$last_name, "MA")
})

test_that("a leading ambiguous credential before a given name is a title", {
  r <- pn("DC David Beer")
  expect_equal(c(r$salutation, r$first_name, r$last_name), c("DC", "DAVID", "BEER"))
  expect_equal(pn("PT RISHI MISIR")$first_name, "RISHI")
  expect_equal(pn("MA BERNADETTE SALGARINO")$first_name, "MA")   # Maria
  expect_equal(pn("AB SKIP CONLEY")$first_name, "AB")            # AB is a census name
})

test_that("role words, tenure words and employers do not become the surname", {
  expect_equal(pn("CRAIG WILSON MANAGING DIR")$last_name, "WILSON")
  expect_equal(pn("ARASH DIBA MANAGING")$last_name, "DIBA")
  expect_equal(pn("BISI OYEDELE MANAGING PARTNER")$last_name, "OYEDELE")
  r <- pn("DUANE LARSON STARTING 6-2022")
  expect_equal(c(r$last_name, r$status), c("LARSON", "STARTING"))
  expect_equal(pn("RANDY FRISK STARTING JUNE 2019")$last_name, "FRISK")
  expect_equal(pn("RYAN SCHLABAUGH APPOINTED 122021")$last_name, "SCHLABAUGH")
  expect_equal(pn("JOHN HEISER INSURANCE")$last_name, "HEISER")
  expect_equal(pn("LISA PIERCE ALLSTATE INSURANCE CO")$last_name, "PIERCE")
  expect_equal(pn("RANDY DENNIS DENNIS COMPANY")$last_name, "DENNIS")
  r <- pn("DR JOHN SMITH JR STATE FARM INSURANCE")
  expect_equal(c(r$salutation, r$last_name, r$suffix), c("DR", "SMITH", "JR"))
  expect_equal(pn("LINDA K COMPANY")$last_name, "COMPANY")   # a surname
  expect_equal(classify_names("NOT APPOINTED")$name_type, "placeholder")
})

test_that("an organisation followed by a person keeps the person", {
  for (x in c("PRUDENTIAL INSURANCE - KYLE SMITH", "Prudential Ins. Co. - Kyle Smith",
              "PLEXUS GROUP-KYLE SMITH", "INDIANA INSURANCE CO KYLE SMITH",
              "ANTHEM INC KYLE SMITH")) {
    r <- pn(x)
    expect_equal(c(r$first_name, r$last_name), c("KYLE", "SMITH"), info = x)
  }
  r <- pn("C R R ENTERPRISE INC - RONALD J RAB")
  expect_equal(c(r$first_name, r$middle_name, r$last_name), c("RONALD", "J", "RAB"))
  expect_equal(pn("NY LIFE INSURANCE D WHEELER")$last_name, "WHEELER")
  # not a person after the organisation
  expect_equal(peopleparser:::person_after_org_split(
    c("CITIZENS BANK AND TRUST", "BANK OF NY MELLON", "US BANK AS TRUSTEE",
      "COMERICA BANK - TRUST DIVISION", "FIRST DAKOTA NATIONAL BANK - MED SC",
      "JOHN HEISER INSURANCE")), rep(NA_character_, 6))
  expect_equal(classify_names("PRUDENTIAL INSURANCE - KYLE SMITH")$name_type,
               "person and organisation")
  # CO before more words is care of an employer
  expect_equal(pn("CHAD COTTER CO BURNS MCDONELL")$last_name, "COTTER")
  expect_equal(pn("JOHN SMITH CO")$last_name, "SMITH")
})

test_that("a dash at the end of a word joins a double surname or cuts a note", {
  expect_equal(pn("DEADERIA MORRIS- BOWMAN")$last_name, "MORRIS-BOWMAN")
  expect_equal(pn("HANA BEN- SHABAT")$last_name, "BEN-SHABAT")
  r <- pn("ADKINS- RICEHOUSE PAULA")
  expect_equal(c(r$first_name, r$last_name), c("PAULA", "ADKINS-RICEHOUSE"))
  expect_equal(pn("JASON FRENN- MANAGING DIRECTOR")$last_name, "FRENN")
  expect_equal(pn("RICK DIETZ- JAN THRU JUNE")$last_name, "DIETZ")
  expect_equal(pn("JOHN EVANS- PAST")$last_name, "EVANS")
  expect_equal(pn("TRICIA BRUNING- ABRAMSON CANCER CTR")$last_name, "BRUNING")
})

test_that("inner particles, titles and ranks", {
  expect_equal(pn("KATRINA VANDEN HEUVEL")$last_name, "VANDEN-HEUVEL")
  expect_equal(pn("PATRICIA SAN PEDRO")$last_name, "SAN-PEDRO")
  expect_equal(pn("ESTELLA DE LOS RIOS")$last_name, "DE-LOS-RIOS")
  expect_equal(pn("RITA TEN MD")$last_name, "TEN")
  r <- pn("SIR HUGH TAYLOR")
  expect_equal(c(r$salutation, r$first_name, r$last_name), c("SIR", "HUGH", "TAYLOR"))
  expect_equal(pn("CHIEF TODD SCHMADERER")$first_name, "TODD")
  r <- pn("GEN PERRIN")
  expect_equal(c(r$salutation, r$first_name, r$last_name), c("GEN", "", "PERRIN"))
  r <- pn("COL RET CLARENCE MAXWELL")
  expect_equal(c(r$salutation, r$first_name, r$last_name), c("COL", "CLARENCE", "MAXWELL"))
})

test_that("resolve_middle_name orders adjacent parts by the tokens", {
  expect_equal(resolve_middle_name("ANN JONES", "SMITH"), c("ANN", "JONES-SMITH"))
  expect_equal(resolve_middle_name("ANN JONES", "SMITH",
                                   tokens = c("MARY", "ANN", "SMITH", "JONES")),
               c("ANN", "SMITH-JONES"))
})

test_that("names with two initials are parsed and never get NA confidence", {
  for (x in c("A J SMITH", "SMITH A J")) {
    r <- pn(x)
    expect_equal(r$first_name, "A")
    expect_equal(r$middle_name, "J")
    expect_equal(r$last_name, "SMITH")
    expect_equal(r$gender, "U")
    expect_equal(r$gender_confidence, "50.0")
  }
  expect_equal(pn("A J SMITH JR")$gender, "M")
  expect_false(is.na(pn("JOHN SMITH A")$gender_confidence))
})

test_that("no NA gender confidence on the sample names", {
  set.seed(1)
  d <- do.call(rbind, lapply(sanitize_input(sample(names_1000, 200)), parse_name))
  expect_false(anyNA(d$gender_confidence))
})
