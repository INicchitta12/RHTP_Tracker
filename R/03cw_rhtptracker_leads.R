# 03cw_rhtptracker_leads.R -------------------------------------------------------
#
# rhtptracker.com AS A WEEKLY LEAD CHECK, NEVER A FIGURE SOURCE (session 118,
# owner chose option 2 of docs/session117_rhtptracker_assessment.md).
#
# WHAT IT IS. rhtptracker.com is a private aggregator (Moodr Health: "not
# operated by CMS or another government agency"). Its Terms of Use permit
# "research, planning, and internal analysis"; robots.txt disallows /api/,
# /reports/ and /auth/, and this script reads none of them. It carries RCJ's
# defects (multi-year totals shown as awards, wrong-state filings, machine
# summaries). So it is §0.1's discovery layer and nothing more: it tells us
# WHERE to look.
#
# WHAT THE PROBE DOES (read-only, §2.2). Against the committed baseline it diffs:
#   1. the sitemap's URL set: a NEW opportunity page or state awards page is a
#      document the aggregator has added;
#   2. each state's /states/<ST>/awards page: an OFFICIAL link (a .gov or .us
#      host) the archived copy did not carry.
# Every new item is logged as a LEAD row in logs/probe_results.csv, one per
# state per page: the state, the aggregator page, and the OFFICIAL-SOURCE
# link(s) it points at. LEAD is logged, never raised.
#
# WHAT IT NEVER DOES. It never writes a figure, a recipient, a date or a tier
# anywhere: a lead message carries URLs and a page title with every currency
# figure stripped (rtl_strip_money()). It never touches an award file. A LEAD is
# read by a human, who opens the official link and, if it is an award source,
# extracts it under the ordinary rules from the STATE's bytes.
#
# Exempt from the name tripwire (tests/testthat/test_utils_name_tripwire.R): a
# third-party page naming an organisation is not a state naming a recipient,
# and the diff here is by URL, Alaska's and FSRS's shape.
#
# CLI
#   Rscript R/03cw_rhtptracker_leads.R --fetch [--force]  # archive the baseline (deliberate)
#   Rscript R/03cw_rhtptracker_leads.R --validate         # baseline present and parseable
#   RHTP_PROBE_ORIGIN=interactive Rscript R/03cw_rhtptracker_leads.R --probe
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(tibble)
})
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))

RTL_STATE <- "RHTPTRACKER"
RTL_BASE <- "https://www.rhtptracker.com"
RTL_AS_OF <- "2026-11-16"
RTL_DIR <- file.path("data", "evidence", "leads", "rhtptracker", RTL_AS_OF)
RTL_SITEMAP <- file.path(RTL_DIR, "sitemap.xml")
RTL_LINKS <- file.path(RTL_DIR, "state_awards_official_links.csv")
RTL_AGENT <- "Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; +https://www.aha.org)"
RTL_DISALLOWED <- c("/api/", "/reports/", "/auth/")     # robots.txt; never read
RTL_MAX_NEW_PAGES <- 40L                                  # new pages opened per run
RTL_SLEEP <- 1                                            # seconds between requests
RTL_OFFICIAL_HOST <- "(\\.gov|\\.us)$"

rtl_get <- function(url) {
  if (any(vapply(RTL_DISALLOWED, function(p) grepl(p, url, fixed = TRUE), logical(1)))) {
    stop("[rhtptracker] refusing a robots.txt-disallowed path: ", url, call. = FALSE)
  }
  Sys.sleep(RTL_SLEEP)
  r <- httr::GET(url, httr::user_agent(RTL_AGENT), httr::timeout(60))
  if (httr::status_code(r) != 200L) {
    stop("[rhtptracker] HTTP ", httr::status_code(r), " from ", url, call. = FALSE)
  }
  httr::content(r, as = "raw")
}

rtl_sitemap_urls <- function(raw) {
  x <- rawToChar(raw)
  u <- stringr::str_match_all(x, "<loc>([^<]+)</loc>")[[1]][, 2]
  sort(unique(trimws(u)))
}

#' Official-source links on a page: absolute hrefs whose host ends .gov or .us.
rtl_official_links <- function(raw) {
  h <- xml2::read_html(raw)
  a <- unique(xml2::xml_attr(xml2::xml_find_all(h, "//a[@href]"), "href"))
  a <- a[grepl("^https?://", a)]
  host <- tolower(sub("^https?://([^/:?#]+).*$", "\\1", a))
  sort(unique(a[grepl(RTL_OFFICIAL_HOST, host)]))
}

rtl_title <- function(raw) {
  t <- xml2::xml_text(xml2::xml_find_first(xml2::read_html(raw), "//title"))
  rtl_strip_money(stringr::str_squish(sub("\\s*\\|\\s*RHTP Tracker\\s*$", "", t)))
}

#' A lead never carries a figure: every currency amount is removed.
rtl_strip_money <- function(x) {
  x <- gsub("\\$\\s?[0-9][0-9,.]*(\\s?(million|billion|thousand|[MBK]))?", "[amount removed]", x, ignore.case = TRUE)
  stringr::str_squish(x)
}

#' The state a page is about: /states/<ST>/..., else the "(State Name)" in its title.
rtl_state_of <- function(url, title = NA_character_) {
  m <- stringr::str_match(url, "/states/([A-Z]{2})(/|$)")[, 2]
  if (!is.na(m)) return(m)
  if (!is.na(title)) {
    nm <- stringr::str_match(title, "\\(([A-Za-z .]+)\\)\\s*$")[, 2]
    k <- match(nm, c(datasets::state.name, "District of Columbia"))
    if (!is.na(k)) return(c(datasets::state.abb, "DC")[k])
  }
  "UNKNOWN"
}

rtl_awards_urls <- function(urls) urls[grepl("/states/[A-Z]{2}/awards$", urls)]

# -- the baseline (a deliberate act, never called by --probe) ----------------------

rtl_fetch <- function(force = FALSE) {
  if (file.exists(here::here(RTL_SITEMAP)) && !force) {
    message("[rhtptracker] baseline exists; --force to re-archive.")
    return(invisible(RTL_DIR))
  }
  dir.create(here::here(RTL_DIR), recursive = TRUE, showWarnings = FALSE)
  sm <- rtl_get(paste0(RTL_BASE, "/sitemap.xml"))
  writeBin(sm, here::here(RTL_SITEMAP))
  urls <- rtl_sitemap_urls(sm)
  aw <- rtl_awards_urls(urls)
  links <- purrr::map_dfr(aw, function(u) {
    l <- tryCatch(rtl_official_links(rtl_get(u)), error = function(e) character(0))
    tibble::tibble(page = u, state = rtl_state_of(u), official_link = l)
  })
  readr::write_csv(links, here::here(RTL_LINKS), na = "")
  writeLines(c(
    "THIRD-PARTY LEAD BASELINE (session 118). rhtptracker.com is a private aggregator (Moodr Health).",
    "These files are a DISCOVERY baseline only (CLAUDE.md 0.1): never a source of any figure, recipient, date or tier.",
    paste0("sitemap.xml: ", RTL_BASE, "/sitemap.xml, ", length(urls), " URLs; ",
           "state_awards_official_links.csv: the .gov/.us links on ", length(aw), " /states/<ST>/awards pages."),
    paste0("fetched_at_utc: ", format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")),
    paste0("sitemap_sha256: ", digest::digest(sm, algo = "sha256", serialize = FALSE))),
    here::here(RTL_DIR, "PROVENANCE.txt"))
  message("[rhtptracker] archived ", length(urls), " sitemap URLs and ", nrow(links),
          " official links on ", length(aw), " awards pages.")
  invisible(RTL_DIR)
}

rtl_validate <- function() {
  sm <- readBin(here::here(RTL_SITEMAP), "raw", file.size(here::here(RTL_SITEMAP)))
  urls <- rtl_sitemap_urls(sm)
  links <- readr::read_csv(here::here(RTL_LINKS), show_col_types = FALSE)
  stopifnot(length(urls) >= 500L, length(rtl_awards_urls(urls)) >= 30L,
            nrow(links) > 0L, all(grepl(RTL_OFFICIAL_HOST, tolower(sub("^https?://([^/:?#]+).*$", "\\1", links$official_link)))))
  message("[rhtptracker] baseline OK: ", length(urls), " URLs, ", nrow(links), " official links.")
  invisible(TRUE)
}

# -- the probe ---------------------------------------------------------------------

#' One LEAD message per (state, aggregator page): its title (figures stripped)
#' and the official links it points at. No figure, ever.
rtl_lead_msg <- function(state, page, title, links) {
  paste0("[", state, "] rhtptracker.com lists a document this repository has not seen: ",
         page, if (!is.na(title) && nzchar(title)) paste0(" ('", title, "')") else "",
         ". Official source(s): ", if (length(links)) paste(links, collapse = " | ") else "none linked",
         ". A LEAD, never a figure: open the official source and extract from the state's bytes.")
}

rtl_probe <- function() {
  sm_old <- readBin(here::here(RTL_SITEMAP), "raw", file.size(here::here(RTL_SITEMAP)))
  old_urls <- rtl_sitemap_urls(sm_old)
  old_links <- readr::read_csv(here::here(RTL_LINKS), show_col_types = FALSE)
  live_urls <- rtl_sitemap_urls(rhtp_probe_get("sitemap", function() rtl_get(paste0(RTL_BASE, "/sitemap.xml")),
                                              here::here(RTL_SITEMAP)))
  new_urls <- setdiff(live_urls, old_urls)
  new_pages <- new_urls[grepl("/opportunities/|/states/[A-Z]{2}/awards$|/documents/", new_urls)]
  if (length(new_pages) > RTL_MAX_NEW_PAGES) {
    message("[rhtptracker] ", length(new_pages), " new pages; opening the first ", RTL_MAX_NEW_PAGES, ".")
  }
  n_leads <- 0L
  for (u in utils::head(new_pages, RTL_MAX_NEW_PAGES)) {
    raw <- tryCatch(rtl_get(u), error = function(e) NULL)
    if (is.null(raw)) {
      rhtp_probe_note("page_errors", "sitemap", paste0("[rhtptracker] could not open new page ", u))
      next
    }
    ti <- rtl_title(raw)
    rhtp_probe_note("lead", rtl_state_of(u, ti), rtl_lead_msg(rtl_state_of(u, ti), u, ti, rtl_official_links(raw)))
    n_leads <- n_leads + 1L
  }
  # every state awards page: official links the baseline did not carry
  aw <- rtl_awards_urls(live_urls)
  for (u in aw) {
    raw <- tryCatch(rtl_get(u), error = function(e) NULL)
    if (is.null(raw)) next
    st <- rtl_state_of(u)
    nl <- setdiff(rtl_official_links(raw), old_links$official_link[old_links$state == st])
    if (length(nl) && !u %in% new_pages) {
      rhtp_probe_note("lead", st, rtl_lead_msg(st, u, rtl_title(raw), nl))
      n_leads <- n_leads + 1L
    }
  }
  message("[rhtptracker] ", length(new_urls), " new sitemap URL(s); ", n_leads, " LEAD row(s) logged.")
  list(changed = if (length(new_urls)) "sitemap" else character(0), findings = character(0))
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) rtl_fetch(force = "--force" %in% args)
  if ("--validate" %in% args) rtl_validate()
  if ("--probe" %in% args) rhtp_probe_run(RTL_STATE, rtl_probe())
  if (!length(args)) message("Usage: --fetch [--force] | --validate | --probe")
}
