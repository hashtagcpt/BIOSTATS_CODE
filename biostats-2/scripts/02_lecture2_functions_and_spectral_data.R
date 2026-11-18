# =============================================================================
#  BIOSTATS 2 — SCRIPT 02: REUSABLE FUNCTIONS & OPTICAL SPECTRAL DATA
#  Course  : Biostatistics & Experimental Design II (NECO)
#  Source  : Reorganized from b2_functions_review.R
#  Datasets: biostats-2/data/spectra/spectrum-report-*.xlsx
#            biostats-2/data/ledmotive_max_outputs.csv
#            biostats-2/data/l_m_s_u_dbl.csv
#
#  Topics Covered:
#    1. Why write functions? Avoiding copy-paste errors across many lab files
#    2. Reading structured instrument spreadsheets (LEDmotive SPD reports)
#    3. Batch-loading multiple Excel files with `purrr::map2_dfr()`
#    4. Tidying multi-channel LED & chick photoreceptor sensitivity spectra
#       with `tidyr::pivot_longer()` and ordering plot legends sensibly
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
library(readxl)
library(patchwork)
theme_set(theme_minimal(base_size = 13))


# ---- 1. Writing a Clean Helper Function for Instrument Excel Files ----------
# Lab spectroradiometers (like LEDmotive) export multi-sheet Excel workbooks
# where the raw Spectral Power Distribution (SPD, in W / nm / m^2) sits in
# specific rows of the 'SPD raw data' sheet.
# Instead of repeating 15 lines of cleaning code 8 times, write ONE function!

load_spd <- function(file_path, condition_name,
                     start_row = 16, end_row = 96) {
  raw <- readxl::read_xlsx(file_path, sheet = "SPD raw data",
                           .name_repair = "minimal")

  tibble(
    wavelength = as.numeric(raw[[1]][start_row:end_row]),
    spd        = as.numeric(raw[[2]][start_row:end_row]),
    condition  = factor(condition_name)
  ) |>
    filter(!is.na(wavelength), !is.na(spd)) |>
    arrange(wavelength)
}


# ---- 2. Batch-Loading Spectral Reports with purrr::map2_dfr() ---------------
# Compare loading conditions cleanly using a lookup table of filenames + labels!
spectra_dir <- "biostats-2/data/spectra"

light_catalog <- tibble(
  file = c(
    "spectrum-report-ledmotive-flatwhite.xlsx",
    "spectrum-report-ledmotive-melanopsin-max.xlsx",
    "spectrum-report-ledmotive-melanopsin-min.xlsx",
    "spectrum-report-ledmotive-yellow.xlsx"
  ),
  condition = c("White Flat", "Melanopsin Max", "Melanopsin Min", "Yellow")
)

spd_all <- purrr::map2_dfr(
  file.path(spectra_dir, light_catalog$file),
  light_catalog$condition,
  load_spd
)

glimpse(spd_all)

# Plot Spectral Power Distribution (380-780 nm visible spectrum)
p_spd <- ggplot(spd_all, aes(x = wavelength, y = spd, colour = condition)) +
  geom_line(linewidth = 1.1) +
  scale_colour_manual(values = c(
    "White Flat"     = "black",
    "Melanopsin Max" = "#0072B2",
    "Melanopsin Min" = "#D55E00",
    "Yellow"         = "#E69F00"
  ), name = "Lighting Condition") +
  coord_cartesian(xlim = c(360, 780)) +
  labs(
    title    = "LEDmotive Spectral Power Distributions (SPDs)",
    subtitle = "Loaded cleanly from 4 Excel workbooks via one reusable `load_spd()` function",
    x        = "Wavelength (nm)",
    y        = expression("Spectral Irradiance (W / nm / m"^2*")")
  ) +
  theme(legend.position = "bottom")

print(p_spd)


# ---- 3. Multi-Channel LED Outputs & Chick Cone Sensitivities ----------------
# Chick ocular-growth experiments (e.g., Rucker Lab) stimulate 5 avian
# photoreceptor classes: U (UV), S (short), M (medium), L (long), D (double).

d_leds  <- readr::read_csv("biostats-2/data/ledmotive_max_outputs.csv", show_col_types = FALSE)
d_chick <- readr::read_csv("biostats-2/data/l_m_s_u_dbl.csv", show_col_types = FALSE) |>
  mutate(wavelength = d_leds$wavelength)

# Pivot LEDs (wide L1..L7 -> long)
d_leds_long <- d_leds |>
  pivot_longer(cols = L1:L7, names_to = "LED", values_to = "power")

# Pivot chick cones (wide L..D -> long) AND set factor order from shortest
# peak wavelength to longest (U -> S -> M -> L -> D) so the legend matches
# the left-to-right order of peaks in the plot! (Answers the question in b2_functions_review.R!)
d_chick_long <- d_chick |>
  pivot_longer(cols = c(L, M, S, U, D), names_to = "cone", values_to = "response") |>
  mutate(cone = factor(cone, levels = c("U", "S", "M", "L", "D")))

p_cones <- ggplot(d_chick_long, aes(x = wavelength, y = response, colour = cone)) +
  geom_line(linewidth = 1.1) +
  scale_colour_manual(values = c(
    "U" = "purple", "S" = "#0072B2", "M" = "#009E73", "L" = "#D55E00", "D" = "black"
  ), name = "Avian Cone") +
  labs(
    title    = "Chick Photoreceptor Spectral Sensitivities",
    subtitle = "Factor levels ordered U -> S -> M -> L -> D so the legend matches peak wavelength order",
    x        = "Wavelength (nm)",
    y        = "Normalized Relative Sensitivity"
  ) +
  theme(legend.position = "bottom")

p_leds <- ggplot(d_leds_long, aes(x = wavelength, y = power, colour = LED)) +
  geom_line(linewidth = 1.0) +
  labs(
    title = "LEDmotive 7-Channel Max Output Spectra",
    x     = "Wavelength (nm)",
    y     = "Relative Power"
  ) +
  theme(legend.position = "bottom")

# Combine vertically with patchwork!
p_cones / p_leds


# ---- 4. Try It Yourself (Exercises) -----------------------------------------
# 1. Load `spectrum-report-cold-white.xlsx` and `spectrum-report-warm-white.xlsx`
#    from `biostats-2/data/spectra/` using `load_spd()` and plot them side-by-side.
# 2. Compute the peak wavelength (nm) of each avian cone class (`U, S, M, L, D`)
#    using `group_by(cone) |> slice_max(response, n = 1)`.
# 3. Compute the integrated area under each lighting condition's SPD curve
#    (`sum(spd) * 5` assuming 5 nm steps) to compare total optical power.
