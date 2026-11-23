# Build data/first_name_pairs.rda from synthid's first-name variant table.
#
# Run from the package root:  source("data-raw/first_name_pairs.R")
#
# Source: synthid dev/name-variants/first-name-variants.csv at synthid commit
# 07c320f (2026-11-23). How the table was built: synthid vignette
# "First-name variants - how the table was built" (vignettes/first-name-variants.Rmd)
# and dev/name-variants/README.md. In short: pairs of first-name forms carried by
# one person (EMP_ID) across their own organization's Part VII filings,
# 2010-2024, 15.0 million people. The 1,007 pairs seen in 25+ people were
# reviewed by hand (lexicon = TRUE); 23,965 sound-alike and misspelling pairs
# from rarer pairs are kept with lexicon = FALSE.
#
# Kept columns (the rest are matcher- or build-specific and stay in synthid):
#   name_short, name_long  the pair, shorter form first (as in synthid)
#   type          nickname, spelling, cognate, compound (lexicon);
#                 sound_alike, misspelling (not lexicon)
#   lexicon       TRUE for the reviewed pairs
#   n_emp_ids     people carrying the pair
#   freq_short, freq_long   national Part VII rows with that first name
#   f_short, f_long         share of those rows recorded female
#   cofiling_rate two forms on one return as separate people, same surname,
#                 per person carrying the pair (high = weaker evidence)
#   flags         "", "gender", "cofiling", "cofiling gender"
#   chain_id      variant chain (connected component of lexicon pairs)
# Added here:
#   formal        for nickname pairs, which side is the formal name (see below);
#                 NA for other types

library(data.table)

synthid_repo <- Sys.getenv("SYNTHID_REPO", "../synthid")
v <- fread(file.path(synthid_repo, "dev/name-variants/first-name-variants.csv"))

first_name_pairs <- v[, .(
  name_short, name_long, type, lexicon, n_emp_ids,
  freq_short, freq_long,
  f_short = round(f_short, 3), f_long = round(f_long, 3),
  cofiling_rate = round(cofiling_rate, 4),
  flags, chain_id
)]

# ---- orient nickname pairs -------------------------------------------------
# synthid stores the shorter form first, which is not always the formal name
# (JOHN/JOHNNY, DEBRA/DEBBIE, CHARLES/CHARLIE). Rules, in order:
#   1. diminutive: the longer form is the shorter plus a pet ending (Y, IE, EY,
#      I), optionally with the last consonant doubled or a final E dropped
#      (JOHNNY, JIMMY, DONNIE, BILLY, KATIE from KATE) -> the shorter is formal.
#   2. pet ending: exactly one form ends in Y/IE/EY/I, it is at most one letter
#      longer than the other, and it is not more than twice as common
#      (KATHY/KATHLEEN, DEBBIE/DEBRA, CHARLIE/CHARLES; not HENRY/HANK)
#      -> that form is the nickname.
#   3. otherwise the longer form is formal; at equal length the more common one.
#   4. overrides below, from reviewing the result.
pet <- "(Y|IE|EY|I)$"
is_dim <- function(s, l) {
  vapply(seq_along(s), function(i) {
    st <- unique(c(s[i], sub("E$", "", s[i]), paste0(s[i], substring(s[i], nchar(s[i])))))
    any(l[i] %in% c(paste0(st, "Y"), paste0(st, "IE"), paste0(st, "EY"), paste0(st, "I")))
  }, logical(1))
}
nk <- first_name_pairs$type == "nickname"
s <- first_name_pairs$name_short; l <- first_name_pairs$name_long
fs <- first_name_pairs$freq_short; fl <- first_name_pairs$freq_long
pet_s <- grepl(pet, s); pet_l <- grepl(pet, l)
rule1 <- is_dim(s, l)
rule2_l <- !rule1 & pet_l & !pet_s & nchar(l) - nchar(s) <= 1 & fl <= 2 * fs   # long is nickname
rule2_s <- !rule1 & pet_s & !pet_l & nchar(l) - nchar(s) <= 1 & fs <= 2 * fl   # short is nickname
formal <- ifelse(rule1 | rule2_l, "short",
          ifelse(rule2_s, "long",
          ifelse(nchar(l) > nchar(s), "long", ifelse(fl >= fs, "long", "short"))))

# Overrides: pairs where the rules pick the wrong side. Format "SHORT LONG" = formal side.
# Reviewed 2026-11-23 against the printed list below (90 pairs where the formal
# side is the shorter form or ends in a pet ending). Most are two nicknames of
# one name (BOB/ROB, KATE/KATIE), where the side does not matter.
overrides <- c(
  "SHERRY SHERYL" = "long",    # SHERYL is the formal name
  "BONITA BONNIE" = "short",   # BONNIE is the pet form of BONITA
  "JULE JULIE"    = "long"     # JULE is a rare short form
)
key <- paste(s, l)
formal[key %in% names(overrides)] <- overrides[key[key %in% names(overrides)]]
first_name_pairs[, formal := fifelse(nk, formal, NA_character_)]

# Pairs to eyeball: where the formal side is the shorter form or ends in a pet ending
chk <- first_name_pairs[type == "nickname"][
  (formal == "short") | (formal == "long" & grepl(pet, name_long)),
  .(name_short, name_long, formal, n_emp_ids, freq_short, freq_long)][order(-n_emp_ids)]
cat("nickname pairs:", sum(nk), " formal = shorter form or pet-ending formal:", nrow(chk), "\n")
print(chk, nrows = 200)

setkey(first_name_pairs, name_short)
usethis::use_data(first_name_pairs, overwrite = TRUE, compress = "xz")
