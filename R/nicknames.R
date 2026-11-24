# Nickname / formal-name lookup and canonical first names, built on the
# first_name_pairs table. Plan and pilot: data-raw/PLAN-nicknames.md.
#
# Canonical rule (see ?nickname_lookup for the user-facing version):
#   1. Spelling root. Spelling pairs form a graph. Each name points to its most
#      common spelling neighbour if that neighbour is more common nationally;
#      the root is the end of that path (KATHRYN -> KATHERINE -> CATHERINE).
#      Each step strictly increases frequency, so there are no cycles, and a
#      name only moves through spellings of itself.
#   2. Nickname resolution, per spelling family. A family that is mostly used as
#      the nickname side of nickname pairs (more people carry it as the nickname
#      than as the formal name) is resolved to a formal name: its direct formal
#      partners (only for families used as a nickname by at least min_nick_rate
#      of the people with the name) are grouped by their spelling roots and weighted by the number
#      of people carrying each pair. Partners that are themselves nicknames
#      (KATE for KATIE) are dropped when any other partner exists. Gender, when
#      known, drops partners of the other gender. The top group wins if it holds
#      at least `min_share` of the weight; otherwise the family is ambiguous
#      (KATHY: KATHLEEN vs KATHERINE; PAT with no gender).
#   3. Chains are never followed beyond one nickname step, so KATHLEEN and
#      CATHERINE stay apart even though KATE links them.

## Package-internal cache of the lookup indexes (one per parameter setting).
.nick_cache <- new.env(parent = emptyenv())

## A misspelling row joins the spelling step only if its rare form has fewer
## national Part VII records than this.
MISSPELLING_MAX_FREQ <- 1000

get_variants_table <- function() {
  as.data.frame(first_name_pairs_table())
}

variant_index <- function(spelling = c("lexicon", "misspelling"), min_share = 0.6,
                          min_nick_rate = 0.002) {
  key <- paste(c(sort(spelling), min_share, min_nick_rate), collapse = "|")
  if (!is.null(.nick_cache[[key]])) return(.nick_cache[[key]])
  v <- get_variants_table()

  # per-name national frequency and female share
  nm <- data.frame(name = c(v$name_short, v$name_long),
                   freq = c(v$freq_short, v$freq_long),
                   fem  = c(v$f_short, v$f_long))
  nm <- nm[!duplicated(nm$name), ]
  freq <- stats::setNames(nm$freq, nm$name)
  fem  <- stats::setNames(nm$fem, nm$name)

  # 1. spelling roots. Misspelling rows are unreviewed: a form under 2% as
  # common as its partner. Some are distinct names next to a very common one
  # (MARCO/MARK: 8,069 vs 591,323 records), so only rare forms are used.
  sp_rows <- (v$lexicon & v$type == "spelling") |
    ("misspelling" %in% spelling & v$type == "misspelling" &
       pmin(v$freq_short, v$freq_long) < MISSPELLING_MAX_FREQ) |
    ("sound_alike" %in% spelling & v$type == "sound_alike")
  sp <- v[sp_rows, ]
  a <- c(sp$name_short, sp$name_long); b <- c(sp$name_long, sp$name_short)
  o <- order(a, -freq[b], b); a <- a[o]; b <- b[o]
  first <- !duplicated(a)
  best <- stats::setNames(b[first], a[first])
  up <- freq[best] > freq[names(best)] |
    (freq[best] == freq[names(best)] & best < names(best))
  parent <- best[up]
  sp_type <- stats::setNames(c(sp$type, sp$type),
                             c(paste(sp$name_short, sp$name_long), paste(sp$name_long, sp$name_short)))
  parent_type <- stats::setNames(unname(sp_type[paste(names(parent), parent)]), names(parent))
  spelling_root <- function(x) {
    r <- x
    for (k in seq_len(100)) {
      p <- parent[r]; hit <- !is.na(p)
      if (!any(hit)) break
      r[hit] <- p[hit]
    }
    unname(r)
  }

  # 2. nickname pairs, oriented
  nk <- v[v$lexicon & v$type == "nickname", ]
  formal_nm <- ifelse(nk$formal == "long", nk$name_long, nk$name_short)
  nick_nm   <- ifelse(nk$formal == "long", nk$name_short, nk$name_long)
  E <- data.frame(nick = nick_nm, formal = formal_nm, n = nk$n_emp_ids,
                  fam = spelling_root(nick_nm), tgt = spelling_root(formal_nm),
                  fem = unname(fem[formal_nm]))
  # families mostly used as the nickname side
  as_nick   <- tapply(E$n, E$fam, sum)
  as_formal <- tapply(E$n, E$tgt, sum)
  fams <- names(as_nick)
  af <- as_formal[fams]; af[is.na(af)] <- 0
  fams <- fams[as_nick[fams] > af]
  # ...and used as a nickname often enough relative to how common the name is:
  # 50 people carry MARK/MARCUS out of 591,323 MARK records (0.008%), so MARK
  # is a name in its own right and is not resolved to MARCUS.
  fams <- fams[as_nick[fams] / freq[fams] >= min_nick_rate]
  # a partner whose own family is mostly a nickname (KATE for KATIE) is not a
  # target
  E$formal_is_nick <- E$tgt %in% fams

  resolve <- function(e, g) {
    if (any(!e$formal_is_nick)) e <- e[!e$formal_is_nick, ]
    if (g != "U") {
      keep <- if (g == "F") e$fem >= 0.5 else e$fem < 0.5
      if (!any(keep)) return("")   # CHRIS (F) with only male formal names: keep the name
      e <- e[keep, ]
    }
    w <- sort(tapply(e$n, e$tgt, sum), decreasing = TRUE)
    if (w[1] / sum(w) >= min_share) names(w)[1] else NA_character_
  }
  canon <- lapply(c(U = "U", M = "M", F = "F"), function(g)
    stats::setNames(vapply(fams, function(fm) resolve(E[E$fam == fm, ], g), ""), fams))

  ix <- list(
    spelling_root = spelling_root,
    canon = canon,                                        # family -> formal root, by gender
    formal_of = split(E[, c("formal", "n", "fem")], E$nick),
    nicks_of  = split(E[, c("nick", "n")], E$formal),
    known = unique(c(v$name_short, v$name_long)),
    freq = freq, fem = fem,
    parent = parent, parent_type = parent_type,           # spelling step: name -> more common spelling
    nick_fams = fams,
    settings = list(spelling = spelling, min_share = min_share, min_nick_rate = min_nick_rate)
  )
  .nick_cache[[key]] <- ix
  ix
}

## Gender evidence for one record: a gendered salutation beats census gender.
gender_evidence <- function(gender, gender_confidence, salutation, min_confidence) {
  sal <- toupper(ifelse(is.na(salutation), "", salutation))
  conf <- suppressWarnings(as.numeric(gender_confidence))
  g <- ifelse(!is.na(gender) & gender %in% c("M", "F") & !is.na(conf) & conf >= min_confidence,
              gender, "U")
  g[sal == "MR"] <- "M"
  g[sal %in% c("MRS", "MS", "MISS")] <- "F"
  g
}

list_names <- function(df, col, g, sep) {
  if (is.null(df) || !nrow(df)) return("")
  if (g != "U" && "fem" %in% names(df)) {
    keep <- if (g == "F") df$fem >= 0.5 else df$fem < 0.5
    if (any(keep)) df <- df[keep, , drop = FALSE]
  }
  paste(df[[col]][order(-df$n)], collapse = sep)
}

#' Look up nicknames, formal names and a canonical form for first names
#'
#' Matches each first name exactly (after upper-casing) against the bundled
#' [first_name_pairs] table. Returns the name's formal forms, its nicknames,
#' and one canonical form for grouping. A name can be both a nickname and a
#' formal name (`KATIE`: a nickname of KATHERINE and the formal form of KATE).
#' Only direct pairs are listed: two nicknames of one name (`BETH`, `LISA`) are
#' not each other's variants.
#'
#' **Canonical rule.**
#' 1. *Spelling root.* Each name moves to its most common spelling variant,
#'    repeatedly, while that is more common nationally (KATHRYN -> KATHERINE ->
#'    CATHERINE; STEVEN -> STEPHEN). Spelling pairs come from the reviewed
#'    lexicon and, by default, the misspelling rows (a rare form of a common
#'    name, used only when the rare form has fewer than 1,000 national
#'    records: MARCO is not a misspelling of MARK).
#' 2. *Nickname step.* A name whose spelling family is mostly carried as a
#'    nickname, by at least `min_nick_rate` of the people with that name (so
#'    MARK, a name in its own right, is not resolved to MARCUS), is resolved
#'    to a formal name. Its direct formal partners are
#'    grouped by spelling root and weighted by the number of people carrying
#'    each pair; partners that are themselves nicknames are dropped when others
#'    exist; with known gender, partners of the other gender are dropped. The
#'    top group wins with at least `min_share` of the weight. Otherwise the name
#'    is `"ambiguous"` and keeps its spelling root (KATHY: KATHLEEN vs
#'    KATHERINE; AL: ALAN vs ALBERT; PAT with no gender).
#' 3. Chains are not followed: one nickname step at most, so KATHLEEN and
#'    CATHERINE are not merged through KATE.
#'
#' Gender comes from a gendered salutation (`MR`, `MRS`, `MS`, `MISS`),
#' otherwise from `gender` when `gender_confidence >= min_confidence`.
#'
#' @param first_name Character vector of first names.
#' @param gender Optional vector of `"M"`, `"F"` or `"U"`, as returned by
#'   [parse_name()], used to choose among formal names.
#' @param gender_confidence Optional vector of gender confidence (0-100), as
#'   returned by [parse_name()].
#' @param salutation Optional vector of salutations, as returned by
#'   [parse_name()]; `MR`, `MRS`, `MS` and `MISS` set the gender.
#' @param sep Separator for the list columns. Defaults to `";; "`.
#' @param min_confidence Minimum `gender_confidence` (0-100) to trust census
#'   gender. Defaults to 80.
#' @param min_share Share of the nickname evidence the top formal name needs.
#'   Defaults to 0.6.
#' @param min_nick_rate Minimum ratio of people carrying the name as a
#'   nickname (people with the name and a formal form) to national records
#'   with the name, for the name to be resolved. Defaults to 0.002.
#' @param spelling Which spelling pairs define spelling roots: any of
#'   `"lexicon"` (reviewed spelling pairs), `"misspelling"` (rare forms of
#'   common names), `"sound_alike"` (unreviewed sound-alike pairs). Defaults
#'   to `c("lexicon", "misspelling")`.
#'
#' @return A `data.frame` with one row per input and columns
#'   `first_name_type` (`formal`, `nickname`, `both`, `variant` for a name
#'   only in spelling, cognate or compound pairs, `unknown`, `initial`, or `""`
#'   for a missing name), `first_name_formal`, `first_name_nicknames`,
#'   `first_name_canonical`, and `canonical_rule` (`self`, `spelling`,
#'   `nickname`, `ambiguous`).
#' @export
#' @examples
#' nickname_lookup(c("BOB", "KATHY", "KATIE", "PAT", "PAT", "STEVEN", "KAREN", "J"),
#'                 gender = c("M", "F", "F", "F", "U", "M", "F", "U"),
#'                 gender_confidence = c(99, 99, 99, 90, 50, 99, 99, 50))
nickname_lookup <- function(first_name, gender = NULL, gender_confidence = NULL,
                            salutation = NULL, sep = ";; ",
                            min_confidence = 80, min_share = 0.6,
                            min_nick_rate = 0.002,
                            spelling = c("lexicon", "misspelling")) {
  n <- length(first_name)
  f <- toupper(trimws(as.character(first_name))); f[is.na(f)] <- ""
  rep_or <- function(v) if (is.null(v)) rep(NA, n) else rep_len(v, n)
  g <- gender_evidence(rep_or(gender), rep_or(gender_confidence),
                       rep_or(salutation), min_confidence)
  ix <- variant_index(spelling, min_share, min_nick_rate)

  root <- ix$spelling_root(f)
  is_nick <- f %in% names(ix$formal_of)
  is_formal <- f %in% names(ix$nicks_of)
  resolved <- rep(NA_character_, n); tried <- root %in% names(ix$canon$U)
  for (gg in c("U", "M", "F")) {
    i <- tried & g == gg
    resolved[i] <- ix$canon[[gg]][root[i]]
  }
  ok <- tried & !is.na(resolved) & resolved != ""
  canonical <- ifelse(ok, resolved, root)
  rule <- ifelse(ok, "nickname",
          ifelse(tried & is.na(resolved), "ambiguous", ifelse(root != f, "spelling", "self")))

  type <- ifelse(is_nick & is_formal, "both",
          ifelse(is_nick, "nickname",
          ifelse(is_formal, "formal",
          ifelse(f %in% ix$known, "variant", "unknown"))))
  ini <- nchar(f) == 1L
  type[ini] <- "initial"; canonical[ini] <- f[ini]; rule[ini] <- "self"
  type[f == ""] <- ""; canonical[f == ""] <- ""; rule[f == ""] <- ""

  key <- paste(f, g); u <- !duplicated(key)
  fl <- vapply(which(u), function(i) list_names(ix$formal_of[[f[i]]], "formal", g[i], sep), "")
  nl <- vapply(which(u), function(i) list_names(ix$nicks_of[[f[i]]], "nick", "U", sep), "")
  m <- match(key, key[u])

  data.frame(first_name_type = type,
             first_name_formal = fl[m],
             first_name_nicknames = nl[m],
             first_name_canonical = canonical,
             canonical_rule = rule,
             stringsAsFactors = FALSE)
}

#' Nicknames of a formal first name
#'
#' @param x Character vector of first names.
#' @param sep Separator. Defaults to `";; "`.
#' @return Character vector: the nicknames of each name, most used first, or
#'   `""` if none.
#' @export
#' @examples
#' get_nicknames(c("RICHARD", "ELIZABETH", "KAREN"))
get_nicknames <- function(x, sep = ";; ") {
  nickname_lookup(x, sep = sep)$first_name_nicknames
}

#' Formal names of a nickname
#'
#' @inheritParams nickname_lookup
#' @param x Character vector of first names.
#' @return Character vector: the formal forms of each name, most used first,
#'   or `""` if none.
#' @export
#' @examples
#' get_formal_names(c("BOB", "PAT", "PAT"), gender = c("M", "F", "M"),
#'                  gender_confidence = 99)
get_formal_names <- function(x, gender = NULL, gender_confidence = NULL, sep = ";; ") {
  nickname_lookup(x, gender = gender, gender_confidence = gender_confidence, sep = sep)$first_name_formal
}

#' Canonical first name
#'
#' @inheritParams nickname_lookup
#' @param x Character vector of first names.
#' @return Character vector of canonical first names (see [nickname_lookup()]).
#' @export
#' @examples
#' canonical_first_name(c("BOB", "BILL", "STEVEN", "KATHY", "KAREN"))
canonical_first_name <- function(x, gender = NULL, gender_confidence = NULL) {
  nickname_lookup(x, gender = gender, gender_confidence = gender_confidence)$first_name_canonical
}

## Lookup of every known name, per gender and setting (cached): the universe
## first_name_variants() groups by canonical form.
all_names_lookup <- function(g, spelling, min_share, min_nick_rate) {
  key <- paste("all", g, paste(sort(spelling), collapse = "+"), min_share, min_nick_rate)
  if (!is.null(.nick_cache[[key]])) return(.nick_cache[[key]])
  ix <- variant_index(spelling, min_share, min_nick_rate)
  nm <- ix$known
  r <- nickname_lookup(nm, gender = g, gender_confidence = 100,
                       min_share = min_share, min_nick_rate = min_nick_rate, spelling = spelling)
  r <- data.frame(name = nm, r, stringsAsFactors = FALSE)
  .nick_cache[[key]] <- r
  r
}

#' All variants in a first name's family
#'
#' Lists every name that shares the canonical form of `x` (see
#' [nickname_lookup()] for the rule), and how each one gets there: spellings,
#' misspellings and nicknames of that canonical name. It also lists, with
#' `in_canonical = FALSE`, names that are related but are **not** merged into
#' the canonical form: unreviewed sound-alike spellings, cognates (JOSE for
#' JOSEPH), compound names (MARYANN), and nicknames that are ambiguous between
#' this name and another (KATHY between KATHLEEN and KATHERINE).
#'
#' @param x A first name (a single string; case is ignored).
#' @param gender `"U"` (default), `"M"` or `"F"`. Gender can change the
#'   canonical form of a nickname (`PAT`) and so the family.
#' @param related Logical; include the related names that are not merged
#'   (`in_canonical = FALSE`). Defaults to `TRUE`.
#' @param min_freq Drop names with fewer national Part VII records than this
#'   (most misspellings are rare). Defaults to 0 (keep all).
#' @inheritParams nickname_lookup
#'
#' @return A `data.frame`, one row per name, with columns `name`, `canonical`,
#'   `relation` (`canonical`, `spelling`, `misspelling`, `sound_alike`,
#'   `nickname`, `ambiguous nickname`, `cognate`, `compound`), `via` (the name
#'   it connects through, for a spelling step or a nickname step),
#'   `in_canonical`, `freq` (national Part VII records with the name) and
#'   `share_female`. Merged names come first, most common first.
#' @export
#' @examples
#' first_name_variants("kate", min_freq = 1000)
#' first_name_variants("steve", related = FALSE)
#' first_name_variants("pat", gender = "F")
first_name_variants <- function(x, gender = "U", related = TRUE, min_freq = 0,
                                min_share = 0.6, min_nick_rate = 0.002,
                                spelling = c("lexicon", "misspelling")) {
  stopifnot(length(x) == 1L, gender %in% c("U", "M", "F"))
  x <- toupper(trimws(x))
  ix <- variant_index(spelling, min_share, min_nick_rate)
  all <- all_names_lookup(gender, spelling, min_share, min_nick_rate)
  c0 <- nickname_lookup(x, gender = gender, gender_confidence = 100, min_share = min_share,
                        min_nick_rate = min_nick_rate, spelling = spelling)$first_name_canonical

  m <- all[all$first_name_canonical == c0, ]
  if (!c0 %in% m$name) {            # a name not in the table: its family is itself
    m <- rbind(m, data.frame(name = c0, first_name_type = "unknown", first_name_formal = "",
                             first_name_nicknames = "", first_name_canonical = c0,
                             canonical_rule = "self", stringsAsFactors = FALSE))
  }
  # A name with a more common spelling is reached through that spelling step
  # (STEVI -> STEVE, KATHRYN -> KATHERINE); otherwise a resolved nickname is
  # reached through its formal partner (STEVE -> STEVEN).
  has_parent <- m$name %in% names(ix$parent)
  relation <- ifelse(m$name == c0, "canonical",
              ifelse(has_parent, unname(ix$parent_type[m$name]),
              ifelse(m$canonical_rule == "nickname", "nickname", "spelling")))
  via <- ifelse(m$name == c0, "",
         ifelse(has_parent, unname(ix$parent[m$name]),
                vapply(m$name, function(n) {
                  f <- ix$formal_of[[n]]
                  if (is.null(f)) return("")
                  f <- f$formal[ix$spelling_root(f$formal) == c0]
                  if (length(f)) f[1] else ""
                }, "")))
  out <- data.frame(name = m$name, canonical = c0, relation = relation, via = via,
                    in_canonical = TRUE, stringsAsFactors = FALSE)

  if (related) {
    members <- out$name
    # ambiguous nicknames with this name among their candidates
    amb <- all[all$canonical_rule == "ambiguous" & nzchar(all$first_name_formal), ]
    hit <- vapply(strsplit(amb$first_name_formal, ";; ", fixed = TRUE),
                  function(f) c0 %in% ix$spelling_root(f), logical(1))
    amb <- amb[hit & !amb$name %in% members, ]
    rel <- data.frame(name = amb$name, canonical = rep(c0, nrow(amb)),
                      relation = rep("ambiguous nickname", nrow(amb)),
                      via = amb$first_name_canonical, in_canonical = rep(FALSE, nrow(amb)),
                      stringsAsFactors = FALSE)
    # sound-alike, cognate and compound pairs touching a member, not merged
    v <- get_variants_table()
    tp <- c("sound_alike", "cognate", "compound")
    tp <- setdiff(tp, if ("sound_alike" %in% spelling) "sound_alike")
    e <- v[v$type %in% tp & (v$name_short %in% members | v$name_long %in% members), ]
    if (nrow(e)) {
      other <- ifelse(e$name_short %in% members, e$name_long, e$name_short)
      thru  <- ifelse(e$name_short %in% members, e$name_short, e$name_long)
      keep <- !other %in% c(members, rel$name)
      e2 <- data.frame(name = other[keep], canonical = rep(c0, sum(keep)), relation = e$type[keep],
                       via = thru[keep], in_canonical = rep(FALSE, sum(keep)),
                       stringsAsFactors = FALSE)
      e2 <- e2[!duplicated(e2$name), ]
      rel <- rbind(rel, e2)
    }
    out <- rbind(out, rel)
  }
  out$freq <- unname(ix$freq[out$name]); out$freq[is.na(out$freq)] <- 0
  out$share_female <- unname(ix$fem[out$name])
  ord <- c("canonical", "spelling", "misspelling", "sound_alike", "nickname",
           "ambiguous nickname", "cognate", "compound")
  out <- out[out$freq >= min_freq | out$relation == "canonical", ]
  out <- out[order(!out$in_canonical, match(out$relation, ord), -out$freq), ]
  rownames(out) <- NULL
  out
}
