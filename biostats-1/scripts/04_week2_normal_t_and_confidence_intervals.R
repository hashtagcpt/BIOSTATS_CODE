# =============================================================================
#  SCRIPT 04: NORMAL & t DISTRIBUTIONS, CLT & CONFIDENCE INTERVALS
#  Course  : Biostatistics & Experimental Design I (NECO GRS97003)
#  Week    : Week 2 - t-Tests & Uncertainty
#  Slides  : BioStats-1_2026_reformat.pptx (Slides 43-90)
#  Reuses  : confidence_intervals_teaching_script.R (core structure preserved!)
#  Datasets: Simulated populations (IQ and adult IOP) + biostats-1/data/02_iop_clinical_trial.csv
#
#  Topics Covered:
#    1. Normal distribution: dnorm(), pnorm(), qnorm(), rnorm() & Z-scores
#    2. Student's t-distribution across degrees of freedom: dt(), pt(), qt()
#    3. Central Limit Theorem & the sampling distribution of the mean
#    4. 95% Confidence Intervals by hand: known sigma (z) vs. unknown sigma (t)
#    5. Margin of Error & required sample size n = (Z * sigma / MoE)^2
#    6. The 100-study CI simulation & why plugging s into z under-covers
#    7. Bridge between 95% CIs and two-sided hypothesis tests
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------
rm(list = ls())
library(tidyverse)
library(broom)
theme_set(theme_minimal(base_size = 13))
set.seed(2026)


# ---- 1. Standard Normal Probabilities & Z-Scores (Slides 59-68) -------------
# R gives four core functions for every distribution (here `norm`):
#   dnorm(x) : height of probability density curve (PDF)
#   pnorm(q) : cumulative probability P(Z <= q) (area to the LEFT of q)
#   qnorm(p) : quantile / critical value with probability p to its LEFT
#   rnorm(n) : generate n random draws

# Exact exercises from Slide 63:
cat("P(Z <= 0)         :", pnorm(0), "\n")
cat("P(Z > -1)         :", pnorm(-1, lower.tail = FALSE), "\n")
cat("P(Z < 1)          :", pnorm(1), "\n")
cat("P(-1 < Z < 1.05)  :", pnorm(1.05) - pnorm(-1), "\n")

# Empirical 68-95-99.7% rule verification
tibble(
  sd_band     = c("+/- 1 SD", "+/- 1.96 SD", "+/- 2 SD", "+/- 3 SD"),
  probability = c(pnorm(1) - pnorm(-1),
                  pnorm(1.96) - pnorm(-1.96),
                  pnorm(2) - pnorm(-2),
                  pnorm(3) - pnorm(-3))
)

# IQ Z-score example (Slides 64-66): mu = 100, sigma = 15
z_115 <- (115 - 100) / 15
z_130 <- (130 - 100) / 15
cat(sprintf("P(IQ > 115) = P(Z > %.1f) = %.4f (%.1f%%)\n",
            z_115, pnorm(z_115, lower.tail = FALSE), 100 * pnorm(z_115, lower.tail = FALSE)))
cat(sprintf("P(IQ > 130) = P(Z > %.1f) = %.4f (%.2f%%)\n",
            z_130, pnorm(z_130, lower.tail = FALSE), 100 * pnorm(z_130, lower.tail = FALSE)))

# Optometry Z-score example: Healthy adult IOP ~ N(mu = 15.5 mmHg, sigma = 2.6 mmHg)
# What proportion of healthy eyes have IOP > 21 mmHg (ocular hypertension cutoff)?
p_above_21 <- pnorm(21, mean = 15.5, sd = 2.6, lower.tail = FALSE)
cat(sprintf("P(IOP > 21 mmHg | N(15.5, 2.6)) = %.4f (%.1f%%)\n",
            p_above_21, 100 * p_above_21))


# ---- 2. Student's t-Distribution vs. Standard Normal (Slides 78-89) ---------
# When population sigma is unknown and estimated by sample s, the standardized
# mean follows Student's t-distribution with df = n - 1 (heavier tails!).

# Exact commands from Slides 88-89:
cat("\nqnorm(0.025)          :", qnorm(0.025), "\n")
cat("qt(0.025, df = 44)    :", qt(0.025, df = 44), "\n")
cat("P(-2 < T_3 < 1)       :", pt(1, df = 3) - pt(-2, df = 3), "\n")

# Visualize how Student's t approaches the Normal curve as df increases
x_grid <- seq(-4.5, 4.5, length.out = 400)
t_curves <- bind_rows(
  tibble(x = x_grid, density = dt(x_grid, df = 2),  dist = "t (df = 2)"),
  tibble(x = x_grid, density = dt(x_grid, df = 5),  dist = "t (df = 5)"),
  tibble(x = x_grid, density = dt(x_grid, df = 20), dist = "t (df = 20)"),
  tibble(x = x_grid, density = dnorm(x_grid),       dist = "Standard Normal (Z)")
) |>
  mutate(dist = factor(dist, levels = c("t (df = 2)", "t (df = 5)",
                                        "t (df = 20)", "Standard Normal (Z)")))

ggplot(t_curves, aes(x = x, y = density, colour = dist, linetype = dist)) +
  geom_line(linewidth = 1) +
  labs(
    title    = "Student's t-Distribution Converges to Standard Normal",
    subtitle = "Small df produces heavier tails -> larger critical values and wider CIs",
    x        = "Standardized Value", y = "Density",
    colour   = NULL, linetype = NULL
  ) +
  theme(legend.position = "bottom")


# ---- 3. Sampling Distribution of the Mean & Central Limit Theorem -----------
# Reused from confidence_intervals_teaching_script.R, adapted to clinical IOP:
# Pretend we know a population of adult IOPs: mu = 16.0 mmHg, sigma = 3.0 mmHg.
mu    <- 16.0   # True population mean IOP (mmHg)
sigma <- 3.0    # True population SD (mmHg)
n     <- 25     # Patients per study
conf  <- 0.95
alpha <- 1 - conf

# Draw ONE sample of n = 25 patients
samp <- tibble(
  patient_id = 1:n,
  iop        = rnorm(n, mean = mu, sd = sigma)
)

# Compute mean and SD by hand and verify with built-in functions
hand <- samp |>
  summarize(
    n_obs        = n(),
    xbar         = sum(iop) / n_obs,
    s            = sqrt(sum((iop - xbar)^2) / (n_obs - 1)),
    xbar_builtin = mean(iop),
    s_builtin    = sd(iop)
  )
print(hand)

xbar <- hand$xbar
s    <- hand$s

# Repeat sampling 5,000 times to see the SAMPLING DISTRIBUTION of xbar
n_reps  <- 5000
xbars   <- tibble(rep = 1:n_reps,
                  xbar = replicate(n_reps, mean(rnorm(n, mean = mu, sd = sigma))))
se_true <- sigma / sqrt(n)
z_crit  <- qnorm(1 - alpha / 2)   # ~1.96

ggplot(xbars, aes(x = xbar)) +
  geom_histogram(aes(y = after_stat(density)), bins = 45,
                 fill = "grey80", colour = "white") +
  stat_function(fun = dnorm, args = list(mean = mu, sd = se_true),
                colour = "#0072B2", linewidth = 1) +
  geom_vline(xintercept = mu + c(-1, 1) * z_crit * se_true,
             colour = "#D55E00", linetype = "dashed", linewidth = 0.9) +
  labs(
    title    = paste0("Sampling Distribution of Mean IOP (n = ", n, ", 5,000 studies)"),
    subtitle = "Blue curve: Normal(mu, sigma/sqrt(n)). Dashed lines: mu +/- 1.96 SE (95% band)",
    x        = "Sample Mean IOP (mmHg)", y = "Density"
  )

xbars |>
  summarize(
    simulated_se = sd(xbar),
    theory_se    = se_true,
    prop_in_95   = mean(abs(xbar - mu) <= z_crit * se_true)
  )


# ---- 4. Building 95% Confidence Intervals by Hand (Slides 85-87) ------------
# Known sigma  : xbar +/- z_crit * (sigma / sqrt(n))
# Unknown sigma: xbar +/- t_crit * (s / sqrt(n))   <-- standard in real research!

t_crit <- qt(1 - alpha / 2, df = n - 1)

ci_table <- tibble(
  method = c("z (sigma known)", "t (sigma unknown)"),
  se     = c(sigma / sqrt(n), s / sqrt(n)),
  crit   = c(z_crit, t_crit)
) |>
  mutate(
    moe   = crit * se,
    lower = xbar - moe,
    upper = xbar + moe
  )
print(ci_table)

# Verify the t-interval directly against R's t.test()
t.test(samp$iop, conf.level = conf) |>
  broom::tidy() |>
  select(estimate, conf.low, conf.high)

# Margin of Error -> Required Sample Size formula (Slides 87 & 338):
# Suppose we want to estimate mean IOP to within +/- 0.5 mmHg (95% CI, sigma = 3).
desired_moe <- 0.5
n_needed_moe <- ceiling((qnorm(0.975) * sigma / desired_moe)^2)
cat(sprintf("\nTo achieve MoE <= +/- %.2f mmHg (sigma = %.1f), need n = %d patients.\n",
            desired_moe, sigma, n_needed_moe))


# ---- 5. The Big Simulation: 100 Studies, 100 Confidence Intervals -----------
# Reused from confidence_intervals_teaching_script.R:
# "95% confidence" describes the long-run reliability of the PROCEDURE,
# NOT a 95% probability that mu is inside any single realized interval.

n_studies <- 100
sims <- expand_grid(study = 1:n_studies, patient = 1:n) |>
  mutate(iop = rnorm(n_studies * n, mean = mu, sd = sigma)) |>
  group_by(study) |>
  summarize(
    mean = mean(iop),
    se   = sd(iop) / sqrt(n()),
    .groups = "drop"
  ) |>
  mutate(
    lower  = mean - t_crit * se,
    upper  = mean + t_crit * se,
    covers = lower <= mu & upper >= mu
  )

cat("Out of 100 simulated 95% CIs, number capturing true mu =", sum(sims$covers), "\n")

ggplot(sims, aes(y = study, xmin = lower, xmax = upper, colour = covers)) +
  geom_vline(xintercept = mu, colour = "#0072B2", linetype = "dashed", linewidth = 0.9) +
  geom_linerange(aes(linewidth = covers)) +
  geom_point(aes(x = mean), size = 0.9) +
  scale_colour_manual(values = c(`TRUE` = "grey45", `FALSE` = "firebrick"),
                      labels = c(`TRUE` = "Captures true mu", `FALSE` = "Misses true mu"),
                      name = NULL) +
  scale_linewidth_manual(values = c(`TRUE` = 0.45, `FALSE` = 1.1), guide = "none") +
  labs(
    title    = paste0("100 Simulated 95% t-Intervals: ", sum(sims$covers), " Captured True Mean IOP"),
    subtitle = "Blue dashed line = true population mean (16.0 mmHg). Red intervals missed by chance.",
    x        = "IOP (mmHg)", y = "Simulated Study Number"
  ) +
  theme(legend.position = "top")


# ---- 6. Why We Need t Instead of z When Sigma Is Estimated ------------------
# Reused from confidence_intervals_teaching_script.R Section 9:
coverage_sim <- function(n_val, reps = 3000, conf = 0.95, mu = 16, sigma = 3) {
  a      <- 1 - conf
  zc     <- qnorm(1 - a / 2)
  tc     <- qt(1 - a / 2, df = n_val - 1)
  draws  <- matrix(rnorm(reps * n_val, mean = mu, sd = sigma), nrow = reps)
  m      <- rowMeans(draws)
  s_hat  <- apply(draws, 1, sd)
  tibble(
    n        = n_val,
    z_known  = mean(abs(m - mu) <= zc * sigma / sqrt(n_val)),
    z_plugin = mean(abs(m - mu) <= zc * s_hat / sqrt(n_val)),
    t_exact  = mean(abs(m - mu) <= tc * s_hat / sqrt(n_val))
  )
}

ns <- c(3, 5, 10, 20, 30, 50, 100)
cov_table <- map_dfr(ns, coverage_sim)
print(cov_table)

cov_table |>
  pivot_longer(-n, names_to = "method", values_to = "coverage") |>
  mutate(method = factor(method,
                         levels = c("z_known", "z_plugin", "t_exact"),
                         labels = c("z with true sigma", "z with sample s (WRONG)", "t with sample s (CORRECT)"))) |>
  ggplot(aes(x = n, y = coverage, colour = method)) +
  geom_hline(yintercept = 0.95, linetype = "dashed") +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  scale_x_log10(breaks = ns) +
  scale_colour_manual(values = c("#0072B2", "firebrick", "#009E73"), name = NULL) +
  coord_cartesian(ylim = c(0.80, 1.0)) +
  labs(
    title    = "Using z Instead of t Under-Covers at Small Sample Sizes",
    subtitle = "Student's t maintains 95% nominal coverage even at n = 3",
    x        = "Sample Size n (log scale)", y = "Empirical 95% Coverage"
  ) +
  theme(legend.position = "bottom")


# ---- 7. Bridge to Hypothesis Testing (CI <-> Two-Sided t-Test) --------------
# Testing H0: mu = 17.5 mmHg at alpha = 0.05 gives the EXACT same decision as
# checking whether 17.5 falls outside the 95% CI!
mu0 <- 17.5
ci_t <- filter(ci_table, method == "t (sigma unknown)")

tibble(
  mu0         = mu0,
  inside_ci   = between(mu0, ci_t$lower, ci_t$upper),
  t_statistic = (xbar - mu0) / ci_t$se,
  reject_H0   = abs(t_statistic) > t_crit
)
t.test(samp$iop, mu = mu0) |> broom::tidy()


# ---- 8. Try It Yourself (Exercises) -----------------------------------------
# 1. Compute a 95% t-CI for `iop_baseline` in `biostats-1/data/02_iop_clinical_trial.csv`
#    both by hand and with `t.test()`.
# 2. Change `conf` from 0.95 to 0.99 in Section 0. How much wider does the CI get?
# 3. What sample size is needed to estimate mean axial length (sigma = 1.0 mm)
#    with a 95% margin of error of +/- 0.20 mm?
