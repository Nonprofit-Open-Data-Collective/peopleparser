# Suffix gaps on Form 990 Part VII names: reproduces the counts in
# data-raw/SUFFIX-GAPS-PART7.md.
#
# Input: a table of raw Part VII person names with a count of person-year
# rows each. The analysis used the `part7` table of an npmerger project
# database (every donor and recipient in 12,684 nonprofit mergers,
# 2009-2025): set NPMERGER_DB to its path. Any data frame with columns
# `raw` (name) and `rows` (count) works.
#
# Steps:
#   1. Tokenize with prep_name(), as parse_name() does.
#   2. Strip known tokens (prx, sfx, the ambiguous list, status words) from
#      the end of each name; record the final remaining token when at least
#      two tokens precede it. Repeat, also stripping the candidates found
#      so far, until no new candidates appear (credential runs).
#   3. Keep tokens seen in >= 5 names whose preceding token looks like a
#      surname (Census last-name count above its first-name count) in at
#      least half of them.
#   4. Confirm each candidate with parse_names(): does it end up inside
#      first_name or last_name?
#   5. Count every token proposed in the note, and test the tier 1 list as
#      extra `prefixes`.
#
# Run from the peopleparser repository root:
#   NPMERGER_DB=path/to/npmerger.duckdb Rscript data-raw/suffix-gaps-part7.R

library(data.table)
devtools::load_all(quiet = TRUE)

db <- Sys.getenv("NPMERGER_DB", "~/Documents/NPMERGER/npmerger.duckdb")
con <- DBI::dbConnect(duckdb::duckdb(), db, read_only = TRUE)
nm <- as.data.table(DBI::dbGetQuery(con, "SELECT PERSON_NAME AS raw, COUNT(*) AS rows FROM part7
                                          WHERE PERSON_NAME IS NOT NULL GROUP BY PERSON_NAME"))
DBI::dbDisconnect(con, shutdown = TRUE)

nm[, clean := prep_name(raw)]
tok <- strsplit(nm$clean, " ", fixed = TRUE)
# Everything parse_name() strips, including the position-restricted lists
# added from this note (so a rerun reports only what is still unhandled).
known <- unique(c(prx, sfx, .ambiguous_suffix_credentials, .status_words,
                  .trailing_status_words, .trailing_only_titles, .leading_only_titles))

utils::data("census.names", package = "peopleparser", envir = environment())
cn <- as.data.table(census.names)[, list(name, last = last_name_value, first = first_name_value)]
data.table::setkey(cn, name)
score <- function(x, v) { r <- cn[list(x)][[v]]; fifelse(is.na(r), 0, r) }

# ---- 1-3: trailing tokens that peopleparser does not strip ---------------------
trail <- function(strip) rbindlist(lapply(seq_along(tok), function(i) {
  t <- tok[[i]]
  while (length(t) && t[length(t)] %in% strip) t <- t[-length(t)]
  if (length(t) < 3L) return(NULL)
  list(i = i, token = t[length(t)], prev = t[length(t) - 1L])
}))
cand <- character(); res <- list()
for (pass in 1:5) {
  tr <- trail(c(known, cand))[!token %in% known & nchar(token) >= 2]
  tr[, rows := nm$rows[i]]
  st <- tr[, list(names = .N, rows = sum(rows),
                  prev_surname = mean(score(prev, "last") > score(prev, "first") & score(prev, "last") > 0)),
           by = token][names >= 5 & prev_surname >= 0.5]
  new <- setdiff(st$token, cand)
  if (!length(new)) break
  res[[pass]] <- st[token %in% new]
  cand <- c(cand, new)
}
cands <- rbindlist(res)
cands[, `:=`(census_last = score(token, "last"), census_first = score(token, "first"))]

# ---- 4: does the parser leave the token in a name field? ------------------------
set.seed(1)
cands <- merge(cands, rbindlist(lapply(cands$token, function(x) {
  ix <- which(vapply(tok, function(t) x %in% utils::tail(t, 3), FALSE))
  ix <- ix[sample.int(length(ix), min(15L, length(ix)))]
  r <- as.data.table(parse_names(nm$raw[ix]))
  inside <- function(v) vapply(strsplit(fcoalesce(v, ""), "-", fixed = TRUE), function(z) x %in% z, FALSE)
  data.table(token = x, checked = length(ix), leaked = sum(inside(r$last_name) | inside(r$first_name)))
})), by = "token")[order(-names)]
fwrite(cands, "data-raw/suffix-gaps-part7-candidates.csv")

# ---- 5: counts for the tokens proposed in the note -------------------------------
count_tail <- function(x) { h <- vapply(tok, function(t) x %in% utils::tail(t, 4), FALSE); c(sum(h), sum(nm$rows[h])) }
count_head <- function(x) { h <- vapply(tok, function(t) length(t) > 1 && t[1] == x, FALSE); c(sum(h), sum(nm$rows[h])) }

tier1 <- c("SJ", "RSM", "OSF", "CSJ", "IHM", "FSC", "CBS", "CSJP", "SCC", "OSB", "SSJ", "SCL", "CSJB", "FSGM",
           "CCVI", "PHJC", "DMIN", "JCD", "JCL", "MDIV", "STL", "FACHE", "DPM", "CRNA", "BSN", "PHARMD", "PSYD",
           "MBBS", "MDS", "LMSW", "LSCSW", "LICSW", "CNM", "FCCP", "FACP", "FAAP", "FACC", "FAAN", "FACOG", "FNP",
           "APRN", "CCRN", "DPT", "OTRL", "MSPH", "MSHA", "MHSA", "DHA", "DSW", "BDS", "CPHQ", "CPHIMS", "FHFMA",
           "CHFP", "LPC", "LMFT", "LPN", "CCM", "CFRE", "ACFRE", "CCIFP", "CPM", "CCIM", "CIC", "CPCU", "CFM",
           "CLFP", "CDT", "PMP", "PHR", "SPHR", "CLU", "CHFC", "CMA", "CGMA", "CTFA", "CEBS", "CFE", "CISA",
           "AICP", "LEED", "FAIA", "MPA", "MPP", "LLM", "CHMM", "ESQUIRE", "RWGM", "RWDGM", "RWSGW", "RWJGW",
           "USMCRET", "USNRET", "USAFRET")
tier2 <- c("MA", "BA", "AB", "ND", "NP", "PT", "DC", "SC", "OP", "HM", "CR", "SP", "DD", "VF", "VG", "PM", "APR",
           "DBA", "CEM", "CRP", "MSA", "AUD", "STD")
hyph <- c("RN-BC", "NP-C", "PA-C", "RNC-OB", "SHRM-SCP", "SHRM-CP", "CCC-SLP")
status <- c("TERM", "ENDED", "EXIT", "EXITED", "JOINED", "BEGAN", "BEGIN", "ENTERED", "ENTRY", "TERMINATED", "RESIGN",
            "SINCE", "TIL", "THR", "EFFECTIVE", "INCOMING", "EMERITUS", "DECD", "NONVOTING", "PART", "PARTIAL", "YEAR")
role <- c("PRESIDENT", "VICE", "CHAIR", "CHAIRMAN", "SECRETARY", "TREASURER", "TRUSTEE", "SVP", "EVP", "ASSOCIATE",
          "ASSOC", "ASST")
entity <- c("LLC", "INC", "COMPANY", "CORP", "BANK", "TRUST", "PARTNERS", "FOUNDATION")
fused <- c("MDPHD", "MDMPH", "JRMD")
prefix <- c("RABBI", "BISHOP", "ARCHBISHOP", "MOST", "BR", "BROTHER", "DEACON", "MONSIGNOR", "MOTHER", "CANTOR", "IMAM",
            "PROFESSOR", "ATTY", "SHERIFF", "CAPTAIN", "ADM", "ADMIRAL", "RADM", "VADM", "BGEN", "MSGT", "CMSGT", "CPL",
            "CSM", "SGTMAJ")
counts <- rbindlist(c(
  lapply(c(tier1, tier2, status, role, entity, fused), function(x) {
    v <- count_tail(x); data.table(token = x, where = "end", names = v[1], rows = v[2]) }),
  lapply(hyph, function(x) {   # hyphenated credentials survive prep_name as one token
    h <- grepl(paste0("(^| )", x, "( |$)"), nm$clean); data.table(token = x, where = "end", names = sum(h),
                                                                    rows = sum(nm$rows[h])) }),
  lapply(prefix, function(x) { v <- count_head(x); data.table(token = x, where = "start", names = v[1], rows = v[2]) })))
counts[, in_prx_or_sfx := token %in% c(prx, sfx)]
fwrite(counts, "data-raw/suffix-gaps-part7-counts.csv")

# tier 1 as extra prefixes: leaks before and after, and a control sample
hit <- which(vapply(tok, function(t) any(utils::tail(t, 4) %in% tier1), FALSE))
before <- as.data.table(parse_names(nm$raw[hit]))
after  <- as.data.table(parse_names(nm$raw[hit], prefixes = c(prx, tier1)))
left <- function(r) sum(Reduce(`|`, lapply(r[, list(first_name, middle_name, last_name)], function(v)
  vapply(strsplit(fcoalesce(v, ""), "-", fixed = TRUE), function(z) any(z %in% tier1), FALSE))))
set.seed(4)
ctrl <- sample(setdiff(seq_along(tok), hit), 3000)
b <- as.data.table(parse_names(nm$raw[ctrl])); a <- as.data.table(parse_names(nm$raw[ctrl], prefixes = c(prx, tier1)))
cat(sprintf("tier 1: %d names, %d person-years; token left in a name field before %d, after %d; control changes %d\n",
            length(hit), sum(nm$rows[hit]), left(before), left(after),
            sum(b$last_name != a$last_name | b$first_name != a$first_name, na.rm = TRUE)))
