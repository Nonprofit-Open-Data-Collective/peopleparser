# Figures for vignettes/canonical-first-names.Rmd.
# Run from the package root:  source("data-raw/vignette-figures.R")
# Writes vignettes/figures/*.png. Needs igraph, ggraph, ggplot2 (not package
# dependencies; the vignette only includes the PNGs).
#
# Colours: the dataviz reference palette. Categorical slots 1-3 (blue, orange,
# aqua) are the set documented to pass all-pairs colour-blind checks; gender uses
# the documented diverging pair (blue <-> red, grey midpoint). Every colour is
# also labelled or in a legend.

suppressMessages({
  devtools::load_all(quiet = TRUE)
  library(data.table); library(igraph); library(ggraph); library(ggplot2)
})
dir.create("vignettes/figures", showWarnings = FALSE, recursive = TRUE)

BLUE <- "#2a78d6"; ORANGE <- "#eb6834"; AQUA <- "#1baf7a"; RED <- "#e34948"
GREY <- "#f0efec"; INK <- "#0b0b0b"; INK2 <- "#52514e"; MUTED <- "#b9b8b2"
type_col <- c(nickname = BLUE, spelling = ORANGE, other = AQUA)

v <- as.data.table(first_name_pairs)
save_fig <- function(p, file, w = 8, h = 6.2) {
  ggsave(file.path("vignettes/figures", file), p, width = w, height = h, dpi = 110, bg = "white")
}
theme_chain <- function() {
  theme_graph(base_family = "sans", title_size = 14, subtitle_size = 10, foreground = NA) +
    theme(legend.position = "bottom", legend.title = element_text(size = 9, colour = INK2),
          legend.text = element_text(size = 9, colour = INK2),
          plot.subtitle = element_text(colour = INK2))
}
chain_graph <- function(ids) {
  e <- v[lexicon == TRUE & chain_id %in% ids,
         .(from = name_short, to = name_long, n = n_emp_ids,
           type = fifelse(type %in% c("nickname", "spelling"), type, "other"))]
  graph_from_data_frame(e, directed = FALSE)
}

# ---- 1. the KATHERINE chain as pairs --------------------------------------------
kid <- v[name_long == "KATHERINE" & lexicon == TRUE, chain_id][1]
g <- chain_graph(kid)
set.seed(3)
lay <- create_layout(g, layout = "stress")
p1 <- ggraph(lay) +
  geom_edge_link(aes(colour = type, width = n), alpha = 0.85) +
  scale_edge_colour_manual(values = type_col, name = "Pair type") +
  scale_edge_width(range = c(0.4, 3.2), trans = "sqrt", name = "People carrying the pair",
                   breaks = c(100, 500, 1000)) +
  geom_node_point(size = 3.2, shape = 21, fill = "white", colour = INK2, stroke = 0.6) +
  geom_node_text(aes(label = name), repel = TRUE, size = 3, colour = INK) +
  labs(title = "The KATHERINE chain: 24 names joined by 40 pairs",
       subtitle = "Each line is a pair seen as one person's two first names. Following the lines would join KATHLEEN to CATHERINE.") +
  theme_chain()
save_fig(p1, "chain-katherine-pairs.png")

# ---- 2. the same chain after the canonical rule ------------------------------------
nm <- V(g)$name
r <- nickname_lookup(nm, gender = "F", gender_confidence = 100)
grp <- fifelse(r$canonical_rule == "ambiguous", "ambiguous: kept as its spelling root",
       fifelse(r$first_name_canonical == "CATHERINE", "-> CATHERINE",
       fifelse(r$first_name_canonical == "KATHLEEN", "-> KATHLEEN", "its own name (or another family)")))
grp_col <- c("-> CATHERINE" = BLUE, "-> KATHLEEN" = ORANGE,
             "ambiguous: kept as its spelling root" = MUTED, "its own name (or another family)" = "white")
lay$grp <- factor(grp, levels = names(grp_col))
lay$lab <- ifelse(r$first_name_canonical != nm & r$canonical_rule != "ambiguous",
                  paste0(nm, " -> ", r$first_name_canonical), nm)
p2 <- ggraph(lay) +
  geom_edge_link(colour = MUTED, width = 0.4, alpha = 0.8) +
  geom_node_point(aes(fill = grp), size = 4.2, shape = 21, colour = INK2, stroke = 0.6) +
  scale_fill_manual(values = grp_col, name = NULL, drop = FALSE) +
  geom_node_text(aes(label = lab), repel = TRUE, size = 3, colour = INK) +
  labs(title = "After the canonical rule (gender F)",
       subtitle = "Spellings collapse to CATHERINE, and KATE and KATIE resolve to it. KATHY's evidence splits between
KATHLEEN and KATHERINE, so KATHY and its spellings stay KATHY. KATHLEEN is not merged with CATHERINE.") +
  theme_chain() + guides(fill = guide_legend(nrow = 2, override.aes = list(size = 4)))
save_fig(p2, "chain-katherine-canonical.png")

# ---- 3. gender: PAT ----------------------------------------------------------------
pat <- c("PAT", "PATRICIA", "PATRICK", "PATTY", "PATSY", "TRICIA", "PATTI", "TRISH", "TRISHA", "PADDY")
e <- v[lexicon == TRUE & name_short %in% pat & name_long %in% pat,
       .(from = name_short, to = name_long, n = n_emp_ids, type)]
gp <- graph_from_data_frame(e, directed = FALSE)
fem <- unique(rbind(v[, .(name = name_short, f = f_short)], v[, .(name = name_long, f = f_long)]), by = "name")
V(gp)$f <- fem$f[match(V(gp)$name, fem$name)]
set.seed(1)
p3 <- ggraph(gp, layout = "stress") +
  geom_edge_link(aes(label = format(n, big.mark = ",")), colour = MUTED, width = 0.8,
                 angle_calc = "along", label_dodge = unit(2.5, "mm"), label_size = 2.8,
                 label_colour = INK2) +
  geom_node_point(aes(fill = f), size = 7, shape = 21, colour = INK2, stroke = 0.6) +
  scale_fill_gradient2(low = BLUE, mid = GREY, high = RED, midpoint = 0.5, limits = c(0, 1),
                       name = "Share of records female", breaks = c(0, 0.5, 1),
                       labels = c("0 (male)", "0.5", "1 (female)")) +
  geom_node_text(aes(label = name), repel = TRUE, size = 3.2, colour = INK, point.padding = unit(4, "mm")) +
  labs(title = "Gender decides PAT",
       subtitle = "Line labels: people carrying the pair. PAT -> PATRICIA (2,191) vs PATRICK (1,939) is 53%, below 60%,\nso with no gender PAT stays PAT. Female evidence drops PATRICK (PAT -> PATRICIA);\nmale evidence drops PATRICIA (PAT -> PATRICK).") +
  theme_chain() + theme(legend.key.width = unit(1.4, "cm"))
save_fig(p3, "gender-pat.png", h = 5.6)

# ---- 4. shares: AL -----------------------------------------------------------------
al <- v[lexicon == TRUE & type == "nickname" & name_short == "AL", .(formal = name_long, n = n_emp_ids)]
ix <- peopleparser:::variant_index()
al[, root := ix$spelling_root(formal)]
agg <- al[, .(n = sum(n), forms = paste(formal[order(-n)], collapse = " + ")), by = root][order(-n)]
agg[, share := n / sum(n)]
agg[, label := sprintf("%s  (%s)", root, forms)]
agg[, label := factor(label, levels = rev(label))]
p4 <- ggplot(agg, aes(share, label)) +
  geom_col(fill = BLUE, width = 0.6) +
  geom_vline(xintercept = 0.6, colour = INK2, linetype = "22", linewidth = 0.5) +
  annotate("text", x = 0.605, y = 0.6, label = "min_share = 0.6", hjust = 0, size = 3, colour = INK2) +
  geom_text(aes(label = sprintf("%.0f%%  (%s people)", 100 * share, prettyNum(n, big.mark = ","))),
            hjust = -0.08, size = 3, colour = INK) +
  scale_x_continuous(limits = c(0, 0.75), labels = function(x) paste0(100 * x, "%"), expand = c(0, 0)) +
  labs(title = "AL: formal candidates grouped by spelling root",
       subtitle = "ALAN, ALLEN and ALLAN are one name (spelling pairs) and pool their evidence.\nNo group reaches 60%, so AL is ambiguous and stays AL.",
       x = "Share of people pairing AL with the formal name", y = NULL) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(),
        panel.grid.major.x = element_line(colour = "#e6e5e0", linewidth = 0.3),
        axis.text = element_text(colour = INK2), plot.subtitle = element_text(colour = INK2))
save_fig(p4, "shares-al.png", h = 3.8)

cat("wrote:", paste(list.files("vignettes/figures"), collapse = ", "), "\n")
