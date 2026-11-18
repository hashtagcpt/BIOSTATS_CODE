# =============================================================================
#  BIOSTATS 2 — SHARED HELPER FUNCTIONS (`biostats-2/R/biostats2_helpers.R`)
#  Course  : Biostatistics & Experimental Design II (NECO)
#
#  HOW TO USE IN ANY SCRIPT OR ASSIGNMENT:
#    Put this ONE line near the top of your script (right after `library(...)`):
#
#      source("biostats-2/R/biostats2_helpers.R")
#
#  WHY THIS EXISTS:
#    Instead of scrolling to the bottom of a long script to re-run multi-line
#    functions every time you restart R or run `rm(list = ls())`, running
#    `source()` loads every helper cleanly into your Environment in one step —
#    just like loading a package, without needing to build or install one!
#
#  FUNCTIONS PROVIDED:
#    1. load_spd()           - Load a LEDmotive Excel spectral power distribution
#    2. make_dTransform()    - Load & log10-transform `full_data.csv` cone thresholds
#    3. summary_se_within()  - Within-subject means, SD, SE & 95% CI (Morey 2008)
#    4. score_subsets()      - Score all k-predictor linear regression subsets
#    5. boot_mean()          - `boot::boot()` callback for the sample mean
#    6. boot_median()        - `boot::boot()` callback for the sample median
#    7. boot_reg()           - `boot::boot()` callback for `lm()` coefficients
#    8. boot_cohens_d()      - `boot::boot()` callback for two-group Cohen's d
#    9. datasim()            - Simulate 2AFC / Yes-No psychometric trial data
# =============================================================================


# -----------------------------------------------------------------------------
# 1. load_spd(): Read a LEDmotive Excel Spectral Power Distribution report
# -----------------------------------------------------------------------------
load_spd <- function(file_path, condition_name, start_row = 16, end_row = 96) {
  raw <- readxl::read_xlsx(
    file_path,
    sheet = "SPD raw data",
    .name_repair = "minimal"
  )

  tibble::tibble(
    wavelength = as.numeric(raw[[1]][start_row:end_row]),
    spd        = as.numeric(raw[[2]][start_row:end_row]),
    condition  = factor(condition_name)
  ) |>
    dplyr::filter(!is.na(wavelength), !is.na(spd)) |>
    dplyr::arrange(wavelength)
}


# -----------------------------------------------------------------------------
# 2. make_dTransform(): Load & log10-transform human cone-threshold psychophysics
# -----------------------------------------------------------------------------
make_dTransform <- function(path = "biostats-2/data/full_data.csv") {
  d_full <- utils::read.csv(path, check.names = TRUE)
  tibble::tibble(
    subject = factor(d_full$subject),
    RE      = d_full$RE,
    A       = log10(d_full$thr1),
    L       = log10(d_full$thr2),
    M       = log10(d_full$thr3),
    Sneg    = log10(d_full$thr4),
    Spos    = log10(d_full$thr5),
    S       = log10(d_full$thr6)
  )
}


# -----------------------------------------------------------------------------
# 3. summary_se_within(): Cousineau-Morey (2008) within-subject SE & 95% CI
#    Removes between-subject baseline differences so error bars accurately
#    reflect WITHIN-subject precision across repeated conditions.
# -----------------------------------------------------------------------------
summary_se_within <- function(data, id_col, within_col, value_col, conf_level = 0.95) {
  k          <- dplyr::n_distinct(data[[within_col]])
  grand_mean <- mean(data[[value_col]], na.rm = TRUE)

  normed <- data |>
    dplyr::group_by(.data[[id_col]]) |>
    dplyr::mutate(
      subj_mean = mean(.data[[value_col]], na.rm = TRUE),
      val_norm  = .data[[value_col]] - subj_mean + grand_mean
    ) |>
    dplyr::ungroup()

  morey_factor <- sqrt(k / (k - 1))

  normed |>
    dplyr::group_by(.data[[within_col]]) |>
    dplyr::summarize(
      n         = sum(!is.na(.data[[value_col]])),
      mean_val  = mean(.data[[value_col]], na.rm = TRUE),
      sd_within = stats::sd(val_norm, na.rm = TRUE) * morey_factor,
      se_within = sd_within / sqrt(n),
      ci_within = se_within * stats::qt(0.5 + conf_level / 2, df = n - 1),
      .groups   = "drop"
    )
}


# -----------------------------------------------------------------------------
# 4. score_subsets(): Evaluate every k-predictor linear regression subset
# -----------------------------------------------------------------------------
score_subsets <- function(data, response, predictors, k) {
  combos <- utils::combn(predictors, k, simplify = FALSE)
  purrr::map_dfr(combos, \(vars) {
    fml <- stats::reformulate(vars, response = response)
    fit <- stats::lm(fml, data = data)
    tibble::tibble(
      k       = k,
      formula = paste(response, "~", paste(vars, collapse = " + ")),
      r2      = summary(fit)$r.squared,
      adj_r2  = summary(fit)$adj.r.squared,
      aic     = stats::AIC(fit)
    )
  }) |>
    dplyr::arrange(dplyr::desc(r2))
}


# -----------------------------------------------------------------------------
# 5-8. Reusable `boot::boot()` callback functions
# -----------------------------------------------------------------------------
boot_mean <- function(data, idx) {
  mean(data[idx], na.rm = TRUE)
}

boot_median <- function(data, idx) {
  stats::median(data[idx], na.rm = TRUE)
}

boot_reg <- function(formula, data, idx) {
  fit <- stats::lm(formula, data = data[idx, ])
  stats::coef(fit)
}

boot_cohens_d <- function(data, idx, formula) {
  d_sub <- data[idx, ]
  group_var <- all.vars(formula)[2]
  if (dplyr::n_distinct(d_sub[[group_var]]) < 2) return(NA_real_)
  effsize::cohen.d(formula, data = d_sub)$estimate
}


# -----------------------------------------------------------------------------
# 9. datasim(): Simulate trial-by-trial psychometric responses
# -----------------------------------------------------------------------------
datasim <- function(contrasts, pcorrect, ntrials) {
  stopifnot(length(contrasts) == length(pcorrect))
  purrr::map2_dfr(contrasts, pcorrect, \(c_val, p_val) {
    tibble::tibble(
      contrast = rep(c_val, ntrials),
      correct  = stats::rbinom(ntrials, size = 1, prob = p_val)
    )
  })
}


message(
  "Loaded Biostats II helpers: load_spd(), make_dTransform(), summary_se_within(), ",
  "score_subsets(), boot_mean(), boot_median(), boot_reg(), boot_cohens_d(), datasim()"
)
