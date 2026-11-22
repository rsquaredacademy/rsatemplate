# Package README template (Rsquared Academy)

Approved by Aravind 2026-11-22. Use it for every package README (`README.Rmd` → `README.md`). Fill each section in order. Keep it short: a reader should know what the package does and run a first example within a minute.

## Rules

- **Package only:** no platform, course or Academy marketing in the README.
- **No download numbers** or "most-used" claims.
- **Business data** in every example (stores, customers, campaigns, sales); no iris, mtcars, penguins or trees.
- **Real output:** examples are evaluated by knitr; show the actual printed output or plot, never pasted or invented numbers.
- **Writing style** (the same audit as for vignettes):
  - one idea per paragraph;
  - plain, beginner-friendly words, with jargon glossed;
  - short sentences (aim ≤ 20 words);
  - British spelling;
  - no hype or deficit words ("simply", "just", "easy", "powerful").
- **Review path:** draft → writing-style audit → highlighted before/after sheet → Aravind's OK → merge to develop. Rebuild the site only after that.

## Sections

### 1. Badges

One line under the title, in this order:

- CRAN status;
- R-CMD-check (GitHub Actions);
- test coverage (Codecov).

```markdown
<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/PKG)](https://CRAN.R-project.org/package=PKG)
[![R-CMD-check](https://github.com/rsquaredacademy/PKG/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/rsquaredacademy/PKG/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/rsquaredacademy/PKG/branch/develop/graph/badge.svg)](https://app.codecov.io/gh/rsquaredacademy/PKG?branch=develop)
<!-- badges: end -->
```

Don't add download badges.

### 2. What it does and for whom

ONE sentence covering what the package does and who it helps.

> olsrr helps analysts build and check linear regression models, with tools for diagnostics, variable selection and clear reports.

### 3. Installation

```r
# Release version from CRAN
install.packages("PKG")

# Development version from GitHub
# install.packages("pak")
pak::pak("rsquaredacademy/PKG")
```

### 4. Quick example

Show the top 2–3 features, chosen by evidence (most-used functions, docs traffic, issues), on business data. For each feature:

1. a one-line purpose: the business question it answers;
2. the call;
3. the real output or plot;
4. one sentence reading the result.

Keep the whole section within one screen of scrolling. Use a package dataset or a small simulated business dataset created in the chunk (set a seed).

### 5. Learn more

- Documentation site (the pkgdown URL);
- Vignettes (link each by its title);
- NEWS (the changelog on the site).

### 6. Getting help and contributing

- **Help:** open an issue with a minimal reproducible example (link to the repo's issues and to `reprex`).
- **Contributing:** link to `CONTRIBUTING.md` (or `.github/CONTRIBUTING.md`).
- **Code of Conduct:** "Please note that the PKG project is released with a [Contributor Code of Conduct](https://rsquaredacademy.github.io/PKG/CODE_OF_CONDUCT.html). By contributing to this project, you agree to abide by its terms."
- **Citation:** `citation("PKG")`, with a link to the site's authors/citation page.
