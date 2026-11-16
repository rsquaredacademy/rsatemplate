# rsatemplate

A [pkgdown](https://pkgdown.r-lib.org) template package for Rsquared Academy
R packages. It gives every package site the same "Structured Workbench"
identity: Bootstrap 5 theme tokens, a hero and install card, card-style
function reference, dark mode, a quiet course card, a branded 404 page, and
the Rsquared Academy site-kit (GA4 consent + e-mail sign-up).

This package is only a template. It has no R API except the optional
`fix_site()` post-build helper.

## Use it in a package

1. Add the template package to `DESCRIPTION`:

```yaml
Config/Needs/website: rsquaredacademy/rsatemplate
```

2. Point pkgdown at it in `_pkgdown.yml`:

```yaml
url: https://olsrr.rsquaredacademy.com

template:
  package: rsatemplate
  params:
    site_url: https://olsrr.rsquaredacademy.com
    hero_description: Tools for building ordinary least squares regression models.
    course_topic: OLS regression
    course_url: https://app.rsquaredacademy.com
    dev_repo: rsquaredacademy/olsrr   # optional
```

`site_url` is required for the canonical tag. It is the same value as `url`
(pkgdown needs both). `course_topic` and `course_url` drive the home sidebar
card; the UTM campaign is filled in automatically from the package name.
`dev_repo` adds the `pak::pak()` line to the install card and can be omitted.

3. Build the site:

```r
pkgdown::build_site()
rsatemplate::fix_site("docs")
```

`fix_site()` is the post-build step that pkgdown cannot do from a template:
it writes the final lowercase, extensionless canonical URL into every page,
removes `AGENTS`/`ISSUE_TEMPLATE` pages from the sitemap, and points
`robots.txt` at the real sitemap. It is idempotent; run it after every build,
for example at the end of your `pkgdown.yaml` workflow.

## What the template provides

- Bootstrap 5 + bslib theme: primary `#2563eb` (light) / `#60a5fa` (dark),
  Schibsted Grotesk headings, Source Sans 3 body, JetBrains Mono code.
- `light-switch: true`, so readers can choose light, dark or auto.
- Home page hero, quick-install card, README, and a quiet "Learn" course card
  in the sidebar.
- Card-style reference index with category filter chips.
- A "Practise this" box at the end of selected articles. Off by default:

```yaml
template:
  package: rsatemplate
  params:
    practise:
      articles:
        - file: variable_selection.html
          topic: variable selection
          url: https://app.rsquaredacademy.com/courses/ols-regression
```

- Footer with the Rsquared Academy sign-up card and analytics opt-out link.
- A branded `404.html`, copied to the site root.
- site-kit v1.3.0 in `site-kit/`: `rsa-analytics.js`, `rsa-consent.css`,
  `rsa-signup.css`, `rsa-signup.js`.

### Migrating an existing site

Existing sites may already vendor site-kit and load it from
`pkgdown/templates/in-header.html`. Delete these before adopting the
template, otherwise the old copy is applied after the template and duplicates
the head tags:

```text
pkgdown/assets/site-kit/
pkgdown/templates/in-header.html
```

`pkgdown/favicon/` can stay. If the site also sets
`template.params.ganalytics`, remove it: site-kit owns GA4 and two loaders
would double-count page views.

## Content Security Policy

If the site sends a CSP, allow the site-kit origins:

```http
script-src  https://www.googletagmanager.com
connect-src https://*.google-analytics.com https://*.analytics.google.com https://www.googletagmanager.com https://zgnp-zngp.maillist-manage.com
img-src     https://*.google-analytics.com https://*.googletagmanager.com
```

The sign-up uses `fetch`, so no Zoho `script-src` is required. See
`site-kit/CSP.md` in the source repository for details.

## License

MIT © Rsquared Academy.
