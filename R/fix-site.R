# Post-build fixes for pkgdown sites using rsatemplate.
#
# pkgdown 2.x has no option to emit self-referencing <link rel="canonical">
# tags, and its sitemap is built from every *.html file in the output
# directory. This helper closes those gaps after pkgdown::build_site():
#
#   1. removes rendered admin pages that should not be published;
#   2. inserts exactly one canonical link into every HTML page, using the
#      final lowercase, extensionless URL that Netlify serves;
#   3. rewrites sitemap.xml so it lists only reader-facing pages that
#      really exist (no 404, AGENTS, ISSUE_TEMPLATE or verification file);
#   4. points robots.txt at the real sitemap URL;
#   5. writes Netlify `_redirects` rules that return 404 for repository and
#      agent-instruction files, even if a later build re-renders them.
#
# The function is idempotent.

#' Post-process a built pkgdown site
#'
#' Adds canonical links, removes admin pages and verification files from the
#' sitemap, writes the correct sitemap URL into `robots.txt`, and writes
#' Netlify `_redirects` rules that return 404 for agent-instruction and
#' repository files (AGENTS, GEMINI, CLAUDE, README, build scripts). It is
#' designed for sites built with the `rsatemplate` pkgdown template and is
#' idempotent, so it can run after every build.
#'
#' @param path Path to the built site, usually `"docs"`.
#' @param url Site URL, without a trailing slash. When `NULL`, the URL is read
#'   from the first `<loc>` entry in `sitemap.xml`, or from the `url:` field in
#'   the package's `_pkgdown.yml`.
#'
#' @return Invisibly, a list with the number of canonical links added and the
#'   number of sitemap entries kept.
#' @export
#' @examples
#' \dontrun{
#' pkgdown::build_site()
#' rsatemplate::fix_site("docs")
#' }
fix_site <- function(path = "docs", url = NULL) {
  if (!dir.exists(path)) {
    stop("Site directory not found: ", path, call. = FALSE)
  }
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)

  url <- url %||% site_url_from_sitemap(path) %||% site_url_from_config(path)
  if (is.null(url) || !nzchar(url)) {
    stop(
      "Could not determine the site URL. Pass `url =` or add `url:` to ",
      "_pkgdown.yml.",
      call. = FALSE
    )
  }
  url <- sub("/+$", "", url)

  removed <- remove_admin_pages(path)
  html <- list.files(path, pattern = "\\.html$", recursive = TRUE,
                     full.names = TRUE)
  html <- html[!is_verification_file(html)]

  added <- 0L
  stubs <- 0L
  for (file in html) {
    lines <- readLines(file, warn = FALSE, encoding = "bytes")
    # pkgdown may put the whole <head> on one line, so remove just the tag,
    # not the line that happens to contain it.
    lines <- gsub(
      "<link[^>]+rel=[\"']canonical[\"'][^>]*>",
      "",
      lines,
      perl = TRUE
    )
    head_end <- grep("</head>", lines, ignore.case = TRUE)
    if (length(head_end) == 0L) {
      warning("No </head> in ", file, "; skipped", call. = FALSE)
      next
    }
    target <- redirect_target(lines)
    href <- if (is.null(target)) {
      canonical_url(file, path, url)
    } else {
      final_url(target, url)
    }
    if (!is.null(target)) {
      stubs <- stubs + 1L
    }
    tag <- sprintf('<link rel="canonical" href="%s">', href)
    line <- head_end[[1]]
    lines[[line]] <- sub(
      "(?i)</head>",
      paste0(tag, "</head>"),
      lines[[line]],
      perl = TRUE
    )
    writeLines(lines, file, useBytes = TRUE)
    added <- added + 1L
  }

  kept <- rewrite_sitemap(path, url)
  rewrite_robots(path, url)
  write_redirects(path)

  invisible(list(
    canonical = added,
    redirect_stubs = stubs,
    sitemap_kept = kept,
    removed = removed
  ))
}

`%||%` <- function(x, y) if (is.null(x)) y else x

site_url_from_sitemap <- function(path) {
  sitemap <- file.path(path, "sitemap.xml")
  if (!file.exists(sitemap)) {
    return(NULL)
  }
  txt <- paste(readLines(sitemap, warn = FALSE), collapse = "\n")
  loc <- regmatches(txt, regexpr("<loc>[^<]+</loc>", txt))
  if (length(loc) == 0L) {
    return(NULL)
  }
  loc <- sub("^<loc>", "", loc)
  loc <- sub("</loc>$", "", loc)
  sub("^(https?://[^/]+).*$", "\\1", loc)
}

site_url_from_config <- function(path) {
  candidates <- c(
    file.path(dirname(path), "_pkgdown.yml"),
    file.path(dirname(path), "_pkgdown.yaml"),
    file.path(dirname(path), "pkgdown", "_pkgdown.yml")
  )
  for (config in candidates) {
    if (!file.exists(config)) {
      next
    }
    lines <- readLines(config, warn = FALSE)
    hit <- grep("^url:[[:space:]]*", lines, value = TRUE)
    if (length(hit) > 0L) {
      return(sub("^url:[[:space:]]*", "", hit[[1]]))
    }
  }
  NULL
}

remove_admin_pages <- function(path) {
  stale <- file.path(
    path,
    c(
      "AGENTS.html", "AGENTS.md", "GEMINI.html", "GEMINI.md",
      "CLAUDE.html", "CLAUDE.md", "ISSUE_TEMPLATE.html", "ISSUE_TEMPLATE.md"
    )
  )
  stale <- stale[file.exists(stale)]
  if (length(stale) > 0L) {
    file.remove(stale)
  }
  basename(stale)
}

# Paths that must never be served from a published site: contributor and
# agent instruction files, repository metadata and build tooling.
blocked_paths <- c(
  "/AGENTS.html", "/AGENTS.md", "/agents", "/agents.html",
  "/GEMINI.html", "/GEMINI.md", "/gemini", "/gemini.html",
  "/CLAUDE.html", "/CLAUDE.md", "/claude", "/claude.html",
  "/README.md", "/CONTRIBUTING.md", "/package.json", "/package-lock.json",
  "/build.mjs", "/check.mjs", "/hash.mjs"
)

redirects_begin <- "# >>> rsatemplate: blocked paths (do not edit inside this block)"
redirects_end <- "# <<< rsatemplate: blocked paths"

# Keep one managed block in `_redirects`; lines outside it are preserved.
write_redirects <- function(path) {
  file <- file.path(path, "_redirects")
  lines <- if (file.exists(file)) readLines(file, warn = FALSE) else character()
  begin <- which(lines == redirects_begin)
  end <- which(lines == redirects_end)
  if (length(begin) == 1L && length(end) == 1L && end > begin) {
    lines <- lines[-seq(begin, end)]
  }
  block <- c(
    redirects_begin,
    sprintf("%-20s /404.html   404!", blocked_paths),
    redirects_end
  )
  writeLines(c(block, lines), file, useBytes = TRUE)
  invisible(file)
}

is_verification_file <- function(path) {
  grepl("^google[0-9a-f]+\\.html$", basename(path), ignore.case = TRUE)
}

redirect_target <- function(lines) {
  hit <- grep('http-equiv="refresh"', lines, value = TRUE, fixed = TRUE)
  if (length(hit) == 0L) {
    return(NULL)
  }
  url <- sub('.*URL=([^"]+)".*', "\\1", hit[[1]])
  if (identical(url, hit[[1]])) NULL else url
}

canonical_url <- function(file, root, url) {
  rel <- sub(paste0("^", gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", root), "/?"),
             "", gsub("\\\\", "/", file))
  rel <- tolower(rel)
  rel <- sub("/?index\\.html$", "", rel)
  rel <- sub("\\.html$", "", rel)
  if (!nzchar(rel)) {
    paste0(url, "/")
  } else {
    paste0(url, "/", rel)
  }
}

final_url <- function(target, url) {
  target <- sub("^https?://[^/]+", "", target)
  target <- sub("^/", "", target)
  target <- tolower(target)
  target <- sub("/?index\\.html$", "", target)
  target <- sub("\\.html$", "", target)
  if (!nzchar(target)) {
    paste0(url, "/")
  } else {
    paste0(url, "/", target)
  }
}

rewrite_sitemap <- function(path, url) {
  sitemap <- file.path(path, "sitemap.xml")
  if (!file.exists(sitemap)) {
    warning("sitemap.xml not found in ", path, call. = FALSE)
    return(0L)
  }
  txt <- paste(readLines(sitemap, warn = FALSE), collapse = "\n")
  locs <- regmatches(txt, gregexpr("<loc>[^<]+</loc>", txt))[[1]]
  if (length(locs) == 0L) {
    return(0L)
  }
  locs <- sub("^<loc>", "", locs)
  locs <- sub("</loc>$", "", locs)

  rel <- sub("^https?://[^/]+/?", "", locs)
  rel <- sub("^/", "", rel)
  rel <- sub("/?index\\.html$", "", rel)
  rel <- sub("\\.html$", "", rel)
  rel <- tolower(rel)

  # Build the list of real output pages in lower-case, extensionless form.
  # This keeps CONTRIBUTING.html on case-sensitive file systems (Linux CI)
  # while still producing the lower-case Netlify URL.
  actual <- list.files(path, pattern = "\\.html$", recursive = TRUE)
  actual <- tolower(gsub("\\\\", "/", actual))
  actual <- sub("/?index\\.html$", "", actual)
  actual <- sub("\\.html$", "", actual)

  excluded <- c("404", "agents", "issue_template", "conduct")
  keep <- !(rel %in% excluded)
  keep <- keep & !grepl("^google[0-9a-f]+$", rel, ignore.case = TRUE)
  keep <- keep & (rel == "" | rel %in% actual)

  urls <- ifelse(nzchar(rel), paste0(url, "/", rel), paste0(url, "/"))
  new <- paste0(
    "<urlset xmlns = 'http://www.sitemaps.org/schemas/sitemap/0.9'>\n",
    paste0("<url><loc>", urls[keep], "</loc></url>\n", collapse = ""),
    "</urlset>\n"
  )
  writeLines(new, sitemap, useBytes = TRUE)
  sum(keep)
}

rewrite_robots <- function(path, url) {
  robots <- file.path(path, "robots.txt")
  sitemap_line <- paste0("Sitemap: ", url, "/sitemap.xml")
  if (!file.exists(robots)) {
    writeLines(
      c("User-agent: *", "Allow: /", "", sitemap_line),
      robots,
      useBytes = TRUE
    )
    return(invisible(NULL))
  }
  lines <- readLines(robots, warn = FALSE)
  lines <- lines[!grepl("^Sitemap:", lines, ignore.case = TRUE)]
  while (length(lines) > 0L && !nzchar(lines[[length(lines)]])) {
    lines <- lines[-length(lines)]
  }
  writeLines(c(lines, "", sitemap_line), robots, useBytes = TRUE)
  invisible(NULL)
}
