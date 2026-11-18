# =============================================================================
#  BIOSTATS 2 — SCRIPT 03: DATA RESHAPING, GGPLOT2, WITHIN-SUBJECT SE & PATCHWORK
#  Course  : Biostatistics & Experimental Design II (NECO)
#  Source  : Reorganized from B2_Lecture_3.R & B2_bar_graph_review.R
#  Datasets: biostats-2/data/full_data.csv (Human cone-isolating psychophysics)
#            biostats-2/data/rbg_noise_ir_data.csv (Chick refractive error)
#
#  Topics Covered:
#    1. Log10 transformation of psychophysical contrast thresholds (Fechner's law)
#    2. Wide-to-long reshaping using modern `tidyr::pivot_longer()` (replacing `reshape2::melt`)
#    3. Within-subject error bars (Cousineau-Morey 2008 adjustment) cleanly in tidyverse
#    4. Scatterplots with `geom_smooth(method = "lm")`, boxplots + jitter,
#       and publication-ready grayscale bar charts
#    5. Multi-panel figure layouts with `patchwork` & high-res export (`ggsave()`)
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
library(patchwork)   # Now on CRAN: install.packages("patchwork")
source("biostats-2/R/biostats2_helpers.R")   # Loads make_dTransform() & summary_se_within()!
theme_set(theme_minimal(base_size = 14))


# ---- 1. Load & Transform Cone-Isolating Psychophysics Data ------------------
# `full_data.csv`: human subjects measured on 6 contrast detection conditions:
#   A = Achromatic, L = L-cone, M = M-cone, Sneg = S-decrement, Spos = S-increment, S = S-Gabor
# `make_dTransform()` (from biostats2_helpers.R) loads and log10-transforms all 6 channels.
d_trans <- make_dTransform("biostats-2/data/full_data.csv")
head(d_trans)


# ---- 2. Scatterplot with Linear Fit & Math Expression Axis Labels -----------
p_scatter <- ggplot(d_trans, aes(x = RE, y = A)) +
  geom_point(size = 2.8, alpha = 0.75, colour = "#0072B2") +
  geom_smooth(method = "lm", se = TRUE, colour = "firebrick", linewidth = 0.9) +
  labs(
    title = "Achromatic Threshold vs. Refractive Error",
    x     = "Refractive Error (Diopters)",
    y     = expression(log[10]("Contrast Threshold"))
  )
print(p_scatter)


# ---- 3. Reshaping Wide -> Long & Within-Subject Error Bars (Morey, 2008) ----
# In `d_trans`, each subject is ONE row with 6 threshold columns (WIDE format).
# ggplot2 needs ONE column for stimulus condition and ONE column for threshold (LONG format).
d_long <- d_trans |>
  pivot_longer(
    cols      = c(A, L, M, Sneg, Spos, S),
    names_to  = "stimulus",
    values_to = "log_thresh"
  ) |>
  mutate(stimulus = factor(stimulus,
                           levels = c("A", "L", "M", "Sneg", "Spos", "S"),
                           labels = c("A", "L", "M", "S-", "S+", "S")))

# Within-subject summary helper `summary_se_within()` (Cousineau-Morey 2008):
# Loaded automatically from `biostats-2/R/biostats2_helpers.R`!
# Removes between-subject baseline differences before computing SE and 95% CI,
# then multiplies by sqrt(k / (k - 1)) so error bars reflect WITHIN-subject precision.
within_summary <- summary_se_within(d_long, id_col = "subject",
                                    within_col = "stimulus", value_col = "log_thresh")
print(within_summary)


# ---- 4. Comparing Bar Plot (Within-Subject 95% CI) vs. Boxplot + Raw Points -
p_bar <- ggplot(within_summary, aes(x = stimulus, y = mean_val, fill = stimulus)) +
  geom_col(width = 0.65, alpha = 0.85, colour = "black") +
  geom_errorbar(aes(ymin = mean_val - ci_within, ymax = mean_val + ci_within),
                width = 0.18, linewidth = 0.9) +
  labs(
    title    = "Mean Log Thresholds (+/- Within-Subject 95% CI)",
    x        = "Cone-Isolating Stimulus",
    y        = expression(log[10]("Contrast Threshold"))
  ) +
  theme(legend.position = "none")

p_box <- ggplot(d_long, aes(x = stimulus, y = log_thresh, fill = stimulus)) +
  geom_boxplot(width = 0.55, alpha = 0.55, outlier.shape = NA) +
  geom_jitter(width = 0.12, size = 1.6, alpha = 0.65) +
  labs(
    title = "Distribution Across Cone Conditions",
    x     = "Cone-Isolating Stimulus",
    y     = expression(log[10]("Contrast Threshold"))
  ) +
  theme(legend.position = "none")

# Combine plots into a publication-style multi-panel figure with `patchwork`!
# `+` places panels side-by-side; `/` stacks panels vertically.
combined_fig <- p_scatter / (p_box + p_bar) +
  plot_annotation(tag_levels = "A")
print(combined_fig)

# Saving high-resolution figures (uncomment when ready to export):
# ggsave("biostats-2/cone_thresholds_figure.png", plot = combined_fig, width = 10, height = 8, dpi = 300)


# ---- 5. Poster-Ready Grayscale Grouped Bar Chart (from B2_bar_graph_review.R)
# Fixes the legacy script's one-sided error bars & external `aes()` bug!
re_dat <- readr::read_csv("biostats-2/data/rbg_noise_ir_data.csv", show_col_types = FALSE) |>
  mutate(condition = forcats::fct_recode(factor(condition), "RGB" = "rgb", "White" = "white"))

re_summary <- re_dat |>
  pivot_longer(cols = c(preD, postD), names_to = "timing", values_to = "re_diopters") |>
  mutate(timing = factor(timing, levels = c("preD", "postD"),
                         labels = c("Pre-Exposure", "Post-Exposure"))) |>
  group_by(timing, condition) |>
  summarize(
    n    = n(),
    mean = mean(re_diopters),
    sd   = sd(re_diopters),
    se   = sd / sqrt(n),
    .groups = "drop"
  )

print(re_summary)

p_gray <- ggplot(re_summary, aes(x = timing, y = mean, fill = condition)) +
  geom_hline(yintercept = 0, colour = "grey30", linewidth = 0.5) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7, colour = "black") +
  geom_errorbar(
    aes(ymin = mean - se, ymax = mean + se),
    position  = position_dodge(width = 0.8),
    width     = 0.18,
    linewidth = 0.9
  ) +
  scale_fill_manual(values = c("White" = "gray80", "RGB" = "gray35"), name = "Light") +
  labs(
    title    = "Chick Refractive Error: Pre vs. Post Light Exposure",
    subtitle = "Grayscale poster style; error bars show +/- 1 SEM",
    x        = "Measurement Timing",
    y        = "Refractive Error (Diopters)"
  ) +
  theme_classic(base_size = 15)

print(p_gray)


# ---- 6. Try It Yourself (Exercises — Matching Lecture 3 Exercises) ----------
# 1. Create a minimal data frame with UNTRANSFORMED `thr4`, `thr5`, and `thr6`
#    from `d_full`, renamed to `S_negative`, `S_positive`, and `S`.
# 2. Make two scatterplots (`S_positive` vs. `S`, and `S_negative` vs. `S`),
#    each with `geom_smooth(method = "lm")`, and combine them with `patchwork`.
# 3. Change `theme_classic()` on `p_gray` to `theme_bw()` and increase axis text
#    size with `theme(axis.text = element_text(size = 16))`.
