# BIOSTATS_CODE

Companion R scripts, optometry & vision-science datasets, assignments, and beginner AI-coding guides for **Biostatistics & Experimental Design I & II** at the **New England College of Optometry (NECO)** (Dr. Christopher Taylor).

---

## Never Coded Before? Start Right Here!

If you have **never written a line of code**—or aren't even sure what a *file path*, *ZIP file*, or *working directory* is—**this guide was written for you.** Follow the steps below once at the start of the semester, and everything in both Biostats I and Biostats II will run smoothly on your laptop.

### Quick Course Jump-Links

| Section | Course / Purpose | Open Guide |
|---|---|---|
| **Biostatistics I** (`biostats-1/`) | Fall semester — Concepts, experimental design, R basics & 11 simulated optometry datasets | **[Biostats I Guide](biostats-1/README.md)** |
| **Biostatistics II** (`biostats-2/`) | Spring semester — Applied R, vision-science lab data, psychophysics, Bayes Factors & assignments | **[Biostats II Guide](biostats-2/README.md)** |
| **LLM Coding Tools** (`llm-coding-guide/`) | Using ChatGPT/Claude/Gemini/Copilot safely to learn R + plain-text cut/paste prompt templates | **[LLM Coding Guide](llm-coding-guide/README.md)** · **[Plain-Text Prompts (.txt)](llm-coding-guide/prompt_templates.txt)** |

---

## A 2-Minute Plain-English Primer: Folders, ZIP Files & Paths

Before installing anything, three small computer concepts will save you hours of confusion:

1. **Folders & File Paths**
   - Think of your laptop like a filing cabinet. Inside your `Documents` folder you might keep a `NECO` folder, and inside that a `BIOSTATS_CODE` folder, and inside that a `biostats-1` folder, and inside that a `data` folder holding `01_student_vision_clinic.csv`.
   - A **file path** is simply the written address telling R which folders to open in order, separated by forward slashes (`/`):
     ```text
     "biostats-1/data/01_student_vision_clinic.csv"
     ```
     Read that left to right: *"Open `biostats-1`, then open `data`, then open `01_student_vision_clinic.csv`."*

2. **Zipped (`.zip`) Folders vs. Real Folders**
   - When you download files from GitHub, they arrive packed inside a compressed suitcase called a **`.zip` file** (`BIOSTATS_CODE-main.zip`).
   - **You must unpack (extract) the suitcase before R can read anything inside it!**
     - **Windows:** Right-click `BIOSTATS_CODE-main.zip` -> click **Extract All...** -> choose a permanent location like `Documents` (NOT `Downloads`). Do **not** just double-click the `.zip` file!
     - **macOS:** Double-click `BIOSTATS_CODE-main.zip`. Mac automatically creates a normal blue folder next to it. Drag that blue folder into your `Documents` folder so it stays organized.

3. **The "Working Directory" & Why `BIOSTATS_CODE.Rproj` Is Magic**
   - R always has one "home base" folder it looks inside first, called the **working directory**. If R is looking in the wrong folder (like `Downloads`), it will say `No such file or directory`.
   - Inside this repository is a special file called **`BIOSTATS_CODE.Rproj`**. Whenever you **double-click `BIOSTATS_CODE.Rproj`**, RStudio opens automatically *with its home base already set to `BIOSTATS_CODE`*.
   - **Result:** You **never** need to type `setwd(...)` or memorize long `C:/Users/...` paths! Every script in both courses finds its data automatically.

---

## Step-by-Step Installation (Do Once, ~10 Minutes)

> **Device Note:** You need a **macOS or Windows laptop**. iPads and Chromebooks cannot run desktop R and RStudio.

### Step 1: Install R (The Statistical Engine)
1. Go to **[https://cran.r-project.org/](https://cran.r-project.org/)**.
2. Click **Download R for macOS** or **Download R for Windows**:
   - **Windows:** Click **base** -> click **Download R 4.x.x for Windows** -> open the downloaded installer and accept the default options.
   - **macOS:** Choose the installer matching your Mac's chip (click the Apple menu ` -> About This Mac` to check: **Apple Silicon / M1–M4** uses the `arm64` `.pkg` installer; older **Intel** Macs use the `x86_64` `.pkg` installer).
3. Make sure your R version is **4.1 or newer** (required for modern R `|>` pipes used in class).

### Step 2: Install RStudio Desktop (The Friendly Workspace)
1. *After* installing R, go to **[https://posit.co/download/rstudio-desktop/](https://posit.co/download/rstudio-desktop/)**.
2. Scroll to **Step 2: Install RStudio** and download the free desktop installer for your operating system.
3. Install it like any normal app. From now on, **always open RStudio** (you never need to open the plain R app directly).

### Step 3: Download & Open `BIOSTATS_CODE`
1. At the top right of this GitHub page, click the green **`<> Code`** button -> click **Download ZIP**.
2. **Unzip** the downloaded file and move the unzipped folder into your **`Documents`** folder (see the Windows/Mac instructions above).
3. Open the unzipped `BIOSTATS_CODE` folder and **double-click `BIOSTATS_CODE.Rproj`**.
4. **Quick check:** Look at the **very top-right corner of RStudio**. It should display **`BIOSTATS_CODE`** (not `Project: (None)`). That confirms R is looking in the right folder!

### Step 4: Know Your Way Around RStudio's 4 Panes
When you open a script in RStudio, your screen is divided into four areas:
- **Top-Left (Script Editor):** Where you read and write `.R` scripts (nothing runs until you tell R to run it).
- **Bottom-Left (Console):** Where R actually runs commands and prints answers (look for the `>` prompt).
- **Top-Right (Environment):** Lists every dataset and variable currently loaded in memory.
- **Bottom-Right (Files / Plots / Help):** Browse folders (**Files**), view graphs (**Plots**), and read documentation (**Help**).

### Step 5: Install the Course Packages (Run Once)
Think of R **packages** like apps on a smartphone: you download them **once** with `install.packages()`, and then open them in each session with `library()`.

Click inside the **Console** (bottom-left pane), paste the block for your course, and press **Enter**:

```r
# For BIOSTATS I (Weeks 1–8 + LLM Coding Guide) — run once:
install.packages(c("tidyverse", "broom", "car", "psych", "effsize", "lsr", "pwr"))
```

```r
# Additional packages for BIOSTATS I Optional Modules & ALL of BIOSTATS II — run once:
install.packages(c(
  "boot", "BayesFactor", "ez", "lme4", "lmerTest",
  "readxl", "R.matlab", "patchwork", "knitr", "kableExtra",
  "lm.beta", "psyphy", "modelfree"
))
```

> **Tip during installation:** If the Console asks *"Do you want to install from sources the package which needs compilation? (Yes/no/cancel)"*, type **`n`** and press **Enter**. (Downloading pre-built binaries is much faster and avoids compiler errors.)

---

## How to Use This Repository in Each Class

### Using the Code in **Biostatistics I** (`biostats-1/`)
1. Always start by double-clicking **`BIOSTATS_CODE.Rproj`** (check top-right of RStudio for `BIOSTATS_CODE`).
2. In the bottom-right **Files** pane, click **`biostats-1`** -> **`scripts`**.
3. Click the script for the current week (for example, `01_week1_r_basics_and_import.R`). It opens in the top-left **Script Editor**.
4. **Run code one line at a time:** Put your cursor on the first command and press **`Ctrl + Enter`** (Windows) or **`Cmd + Enter`** (Mac) (or click the **Run** button at the top-right of the Script Editor). R runs that line and automatically jumps to the next line!
5. Watch numerical results appear in the **Console** (bottom-left) and graphs appear in the **Plots** tab (bottom-right).
6. Read the `#` comments—they explain both the statistical concept and what each line of R does—and try the short exercises at the bottom of each script.

### Using the Code in **Biostatistics II** (`biostats-2/`)
1. Start by double-clicking **`BIOSTATS_CODE.Rproj`**.
2. **Lecture scripts:** In the **Files** pane, open **`biostats-2`** -> **`scripts`**, and step through the lecture file with **`Ctrl + Enter`** / **`Cmd + Enter`**.
3. **One-line shared helpers:** Most Biostats II scripts start with:
   ```r
   source("biostats-2/R/biostats2_helpers.R")
   ```
   Just run that single line along with the `library(...)` lines at the top! It automatically loads all reusable course helper functions (`load_spd`, `make_dTransform`, `summary_se_within`, `boot_*`, `datasim`, etc.) and prints a confirmation message in the Console—no scrolling or copy-pasting function blocks required.
4. **Homeworks & Assignments:**
   - In the **Files** pane, open **`biostats-2`** -> **`assignments`** and click the starter file (e.g., `assignment_01_data_and_functions.R`).
   - Immediately click **File -> Save As...** and save your own copy named **`YourFullName_assignment_1.R`** (no spaces).
   - Fill in your code and written comments under each question.
   - **Before submitting:** Click **Session -> Restart R**, then click **Source** (top-right of the Script Editor) to verify your whole script runs cleanly from top to bottom with zero errors.

### Using **LLM Coding Tools** (`llm-coding-guide/`)
- If you want help understanding an R error, customizing a `ggplot2` graph, or checking your code with ChatGPT, Claude, Gemini, or Copilot, start with **[`llm-coding-guide/README.md`](llm-coding-guide/README.md)**.
- Open **[`llm-coding-guide/prompt_templates.txt`](llm-coding-guide/prompt_templates.txt)** directly inside RStudio (or Notepad/TextEdit) to copy-paste ready-made optometry prompts with zero Markdown formatting in the way.
- Run [`llm-coding-guide/scripts/02_catching_ai_stats_bugs_lab.R`](llm-coding-guide/scripts/02_catching_ai_stats_bugs_lab.R) to practice spotting 5 common silent statistical mistakes that AI tools make!

---

## Help! Top 5 Beginner Troubleshooting Fixes

| What You See | Why It Happened | How to Fix It in 10 Seconds |
|---|---|---|
| `Error: cannot open file 'biostats-1/data/...': No such file or directory` | R is looking in the wrong folder (working directory), or the folder is still zipped. | Close RStudio, make sure you **extracted** the `.zip` file, and reopen by double-clicking **`BIOSTATS_CODE.Rproj`**. Confirm **`BIOSTATS_CODE`** appears in the top-right corner. |
| `Error in library("..."): there is no package called '...'` | That package hasn't been installed on your laptop yet. | Run `install.packages("package_name")` once in the Console (with quotes), then re-run `library(package_name)`. |
| Console shows a **`+`** sign instead of **`>`** | R is waiting for a missing closing parenthesis `)` or quotation mark `"`. | Click inside the Console and press the **`Esc`** key until `>` returns, then check your line for a missing `)` or `"`. |
| `Error: object '...' not found` | Either you skipped running an earlier line that created that variable, or there is a capitalization typo (`IOP` vs. `iop`). | Run the script from the top (`library(...)` and data-loading lines first) and check exact spelling/case. |
| Where did my earlier graph go? | New plots cover previous ones in the **Plots** pane. | Click the **left/right blue arrows** at the top-left of the bottom-right **Plots** pane to flip between graphs. |

---

## Repository Folder Map

```text
BIOSTATS_CODE/
├── BIOSTATS_CODE.Rproj             # ALWAYS double-click this file to open RStudio!
├── README.md                       # Beginner setup & course navigation hub (you are here)
├── llm-coding-guide/               # Using LLM coding tools safely with R
│   ├── README.md                   # 5-step R + AI workflow, PHI privacy rules & 6-point checklist
│   ├── prompt_templates.md         # 8 copy-paste R + Biostatistics prompt recipes (Markdown)
│   ├── prompt_templates.txt        # Plain-text version of all 8 prompt templates (easy cut/paste)
│   └── scripts/                    # 2 hands-on LLM workflow & silent-AI-bug labs
├── biostats-1/                     # COURSE 1: Foundations, Design & Introductory R
│   ├── README.md                   # Full Biostats I syllabus map & dataset dictionary
│   ├── data/                       # 11 simulated optometry/vision-science CSVs + generator
│   └── scripts/                    # 15 numbered teaching scripts (Weeks 1–8 + Optional)
└── biostats-2/                     # COURSE 2: Applied R, Psychophysics, Bayes & Assignments
    ├── README.md                   # Full Biostats II lecture map & dataset dictionary
    ├── R/                          # Shared helpers (`biostats2_helpers.R`, loaded via one `source()` line)
    ├── data/                       # Lab CSV, Excel (.xlsx) & MATLAB (.mat) datasets + spectra/
    ├── scripts/                    # 10 numbered applied R lecture scripts
    └── assignments/                # Clean starter templates for Homeworks 1–2 & Assignments 1–4
```

---

## Complete Script Index Across Both Courses

### Course 1: Biostatistics & Experimental Design I (`biostats-1/scripts/`)
*Full slide alignment and dataset dictionary in [`biostats-1/README.md`](biostats-1/README.md).*

1. `01_week1_r_basics_and_import.R` — R basics, contrast formulas, NOIR scales, CSV import, `NA` checks, `dplyr`, wide-to-long OD/OS tidying
2. `02_week1_descriptive_stats_and_means.R` — Mean/median/IQR, Arithmetic/Geometric/Harmonic means, why visual acuity uses logMAR, $n-1$ variance simulation, SD vs. SEM
3. `03_week1_eda_and_visualization.R` — Deviations plots, Tukey boxplot anatomy, `#barbarplots` vs. raw points, scatterplots, *The Table 1 Fail* 1D strip graphic
4. `04_week2_normal_t_and_confidence_intervals.R` — Normal & Student's *t* functions, CLT, hand-built *z*/*t* CIs, MoE sample size, 100-study CI coverage simulation
5. `05_week2_t_tests_independent_and_paired.R` — Welch vs. Student independent *t*-tests, paired IOP change, fellow-eye pseudoreplication, statistical vs. clinical significance
6. `06_week3_sampling_normality_and_outliers.R` — Repeated sampling ($n=10$ vs. $40$), Normal Q–Q plot key, Shapiro–Wilk large-sample paradox, Dice Lab, outlier sensitivity, 5-year myopia simulation
7. `07_week3_measurement_agreement_bland_altman_icc.R` — Bias vs. noise target analogy, Bland–Altman Limits of Agreement & CIs, `psych::ICC()` consistency vs. absolute agreement
8. `08_week5_correlation_and_regression.R` — Pearson/Spearman, outlier distortion, simple & multiple `lm()`, variance partitioning, residuals, AIC, Collinearity Tax (VIF), 1,000-study *r* simulation
9. `09_week6_study_design_randomization_and_bias.R` — Allocation schemes (simple, permuted/variable blocks, stratified blocks), Causal DAGs (confounder, mediator, collider), prevalence/incidence & direct age standardization
10. `10_week7_anova_and_multiple_comparisons.R` — FWER inflation, worked One-Way ANOVA by hand, `aov()`/`lm()` unification, Welch ANOVA, Two-Way interaction plot, planned contrasts, `TukeyHSD()`, `p.adjust()` (Bonferroni, Holm, BH FDR)
11. `11_week8_effect_size_and_power_analysis.R` — Cohen's *d*, Hedges' *g*, $\eta^2$, $\omega^2$, Cohen's *f*, `power.t.test()` & `pwr` (+ attrition & NECO vs. BU check), noise-vs-*N* power curves, dichotomization power loss, post-hoc power circularity
12. `12_optional_categorical_screening_and_odds_ratios.R` — ARR/RR/NNT, exact vs. Wald binomial CI, Chi-square GoF & Independence, `fisher.test()`, PPV vs. prevalence curve, OR vs. RR & log-odds CIs
13. `13_optional_logistic_regression_and_roc.R` — Binomial `glm()`, clinical Odds Ratios, patient-level train/test validation, ROC curve & AUC from scratch, calibration plot
14. `14_optional_bootstrap_nonparametric_and_bayes.R` — `boot()` (mean, median, regression, patient-cluster bootstrap), Mann–Whitney U, Wilcoxon signed-rank, Kruskal–Wallis, Card Bayes updating (`runCardBayes()`), Beta-Binomial & `ttestBF()`
15. `15_optional_ancova_repeated_measures_and_ss_types.R` — Baseline-adjusted ANCOVA, mixed-design `ezANOVA()` with Mauchly's sphericity & Greenhouse–Geisser correction, `lmer()` for repeated measures & fellow eyes, unbalanced Type I/II/III Sums of Squares

### Course 2: Biostatistics & Experimental Design II (`biostats-2/scripts/` & `biostats-2/assignments/`)
*Full lecture guide, helper function list, and dataset dictionary in [`biostats-2/README.md`](biostats-2/README.md).*

1. `01_lecture1_r_programming_and_data_io.R` — Calculator, indexing, CSV/Excel/MATLAB import, `if/else`, `for`/`while`, writing functions, Lucky 13
2. `02_lecture2_functions_and_spectral_data.R` — Reusable Excel loader (`load_spd()`) for LEDmotive spectral power distributions (`purrr::map2_dfr`) & avian cone sensitivity plots
3. `03_lecture3_ggplot_reshaping_and_patchwork.R` — Log10 cone thresholds, `pivot_longer()`, within-subject SE (`summary_se_within()`), poster-ready grayscale bar charts & `patchwork` layouts
4. `04_lecture4_ttests_correlations_and_tables.R` — Cone-ratio *t*-tests, `p.adjust()`, Pearson vs. Spearman `cor.test()`, trimmed & winsorized means, CV, `knitr::kable()` tables
5. `05_lecture5_multiple_regression_and_selection.R` — Simple & multiple `lm()`, standardized betas (`lm.beta`), nested `anova()`, all-subsets color-vision RE regression & VIF
6. `06_lecture6_anova_tukey_and_bootstrap.R` — Levene's test, One-Way & Repeated-Measures ANOVA, `TukeyHSD()`, bootstrapping cards, CVI medians & regression slopes
7. `07_lecture7_effect_size_and_power_curves.R` — `cohen.d()` + bootstrap CI, Two-Way ANOVA `etaSquared()`, pre-planned *t*-test & multi-power ANOVA sample-size curves
8. `08_lecture8_psychometric_functions.R` — MATLAB 2AFC psychophysics import, `glm(..., binomial(mafc.logit(2)))`, `modelfree::threshold_slope()`, bootstrap threshold CI & `datasim()`
9. `09_lecture9_bayes_factors_in_r.R` — `correlationBF()`, `posterior()`, directional `nullInterval`, `anovaBF()`, `ttestBF()`, and `regressionBF()`
10. `10_special_mixed_models_and_simulations.R` — Factorial CSF simulation, naive `lm()` vs. `lme4::lmer()`, binomial psychometric curve, Sleeping Beauty Monte Carlo
- **`R/biostats2_helpers.R`** — All 9 reusable Biostats II helper functions loaded with one `source()` line
- **`assignments/`** — Starter templates for Homeworks 1–2 and Assignments 1–4 ([`biostats-2/assignments/README.md`](biostats-2/assignments/README.md))

### Using LLM Coding Tools (`llm-coding-guide/`)
1. `README.md` — 5-step R + AI workflow, privacy/PHI rules, and the 6-Point Statistical Sanity Checklist
2. `prompt_templates.md` & `prompt_templates.txt` — 8 copy-paste prompt recipes (Markdown and plain-text versions)
3. `scripts/01_llm_workflow_wide_to_long.R` — Why clean tidyverse choices (`read_csv`, `glimpse`, `pivot_longer`) keep LLMs out of column-mangling rabbit holes
4. `scripts/02_catching_ai_stats_bugs_lab.R` — Hands-on lab demonstrating **5 silent AI statistical bugs** and how to catch and fix each one

---

## Data & Provenance Notes
- **Simulated vs. Lab Data:** All CSV files in `biostats-1/data/` are simulated illustrative teaching datasets (reproducible via `source("biostats-1/data/generate_teaching_datasets.R")`). Datasets in `biostats-2/data/` are curated teaching datasets from `hashtagcpt/biostats-2` (past student submissions excluded).
- **Copyright:** Course materials are intended for educational use at the New England College of Optometry (NECO).
