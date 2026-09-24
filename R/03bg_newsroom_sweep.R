#!/usr/bin/env Rscript
# 03bg_newsroom_sweep.R ------------------------------------------------------
#
# THE NEWSROOM SWEEP -- ONE PROBE OVER THE EIGHTEEN STATES WITH NO CMS RELEASE.
#
# Tennessee (2026-09-03) and New Jersey (2026-07-31) both published a named
# Year 1 roster ONLY through a newsroom: no CMS release, no link from the
# programme page, nothing in RCJ at the time, and no probe watching. Tennessee
# sat unseen for twenty days and New Jersey for fifty-five. Session 60 measured
# the blind spot: eighteen states on no Routine AND with no CMS state release
# on record -- AZ DE FL IA ID IL MA MD MN MT NE NH NJ NV OK OR TX UT.
#
# This file watches the NEWS INDEX of each, and asks one question: has a NEW
# headline appeared that pairs RHTP language with award language? It compares
# the live index's headlines with the committed baseline's, so the ordinary
# churn of a newsroom -- dozens of unrelated items a week -- never trips it;
# only a new item that names the programme and an award does.
#
# IT IS A NET, NOT A WATCH, AND IT SAYS SO. It sees headlines, not rosters. A
# state that awards in a PDF with no news item (New Jersey's programme page
# still links nothing) is caught only if the newsroom says so -- which is the
# case that cost 55 days, so it is the right case to cover first. A fired
# tripwire means READ THE ITEM; it never means the state has awarded.
#
# §2.3's NAME TRIPWIRE DOES NOT RUN HERE, DELIBERATELY. A press index is the
# textbook page that "moves for reasons that are not the state awarding", and
# a name diff on one halts every week. The phrase test is new-headline-scoped
# instead, which is the property that makes a phrase list tolerable: only
# headlines absent from the baseline are read at all.
#
# FOUR STATES ARE UNREADABLE AND ARE RECORDED, NOT SKIPPED (§0.4). MA
# (www.mass.gov 403), MD (governor.maryland.gov and health.maryland.gov both
# 403 on 2026-09-24), NH (every nh.gov host 403) and IL (gov-pressreleases.
# illinois.gov refused at CONNECT by this environment's proxy; hfs 404). Each
# run re-tests them and FAILS if one becomes readable, because an unwatched
# readable newsroom is exactly the gap this file exists to close. Their silence
# is a statement about our access, never about the state.
#
# Usage:
#   Rscript R/03bg_newsroom_sweep.R --fetch     # archive the baselines
#   Rscript R/03bg_newsroom_sweep.R --probe     # LIVE, READ-ONLY
#   Rscript R/03bg_newsroom_sweep.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))

NW_LOG_STATE  <- "NEWSROOM"
NW_DIR        <- file.path("data", "evidence", "newsroom_sweep")
NW_USER_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                        "+https://www.aha.org)")

NW_STATES <- c("AZ", "DE", "FL", "IA", "ID", "IL", "MA", "MD", "MN", "MT",
               "NE", "NH", "NJ", "NV", "OK", "OR", "TX", "UT")

# One or two index pages per readable state: the Governor's newsroom and the
# administering agency's, where each answered 200 on 2026-09-24.
NW_PAGES <- tibble::tribble(
  ~state, ~key, ~url,
  "AZ", "governor", "https://azgovernor.gov/news-releases",
  "AZ", "ahcccs",   "https://www.azahcccs.gov/shared/News.html",
  "DE", "news",     "https://news.delaware.gov/",
  "FL", "governor", "https://www.flgov.com/eog/news/press",
  "IA", "governor", "https://governor.iowa.gov/newsroom",
  "ID", "governor", "https://gov.idaho.gov/pressrelease/",
  "ID", "dhw",      "https://healthandwelfare.idaho.gov/news",
  "MN", "mdh",      "https://www.health.state.mn.us/news/pressrel/index.html",
  "MT", "news",     "https://news.mt.gov/",
  "MT", "dphhs",    "https://dphhs.mt.gov/News/",
  "NE", "governor", "https://governor.nebraska.gov/press-releases",
  "NE", "dhhs",     "https://dhhs.ne.gov/Pages/Newsroom.aspx",
  "NJ", "doh",      "https://www.nj.gov/health/news/2026/approved/news_archive.shtml",
  "NV", "governor", "https://www.gov.nv.gov/press-releases/",
  "NV", "nvha",     "https://www.nvha.nv.gov/",
  "OK", "governor", "https://oklahoma.gov/governor/newsroom/newsroom.html",
  "OR", "oha",      "https://www.oregon.gov/oha/erd/pages/news-releases.aspx",
  "TX", "governor", "https://gov.texas.gov/news",
  "TX", "hhsc",     "https://www.hhs.texas.gov/news",
  "UT", "governor", "https://governor.utah.gov/news/",
  "UT", "dhhs",     "https://dhhs.utah.gov/news/"
) %>%
  dplyr::mutate(file = file.path(NW_DIR, paste0("2026-09-24_", tolower(state),
                                                "_", key, ".html")),
                name_diff = FALSE)

NW_UNREADABLE <- tibble::tribble(
  ~state, ~url, ~observed,
  "MA", "https://www.mass.gov/news", "HTTP 403 (Akamai), every mass.gov path, four agents (sessions 41, 60, 61)",
  "MD", "https://governor.maryland.gov/news/press/", "HTTP 403 on 2026-09-24; health.maryland.gov/newsroom/ 403 too",
  "NH", "https://www.governor.nh.gov/news-and-media", "HTTP 403 (Akamai), every nh.gov host (sessions 29, 61)",
  "IL", "https://gov-pressreleases.illinois.gov/", "refused at CONNECT by this environment's proxy on 2026-09-24"
)

# RHTP language, generic and per-state brand. A headline must match this AND
# NW_AWARD to trip.
NW_RHTP <- paste0("Rural Health Transformation|\\bRHTP?\\b|\\bNJRHT\\b|",
                  "Healthy Hometowns|Rural Texas Strong|GO-NORTH|",
                  "rural health (care )?(grant|fund|award)")
NW_AWARD <- "award|grant|recipient|selected|funding|fund\\b|invest"

nw_headlines <- function(raw) {
  h <- xml2::read_html(raw)
  a <- rvest::html_elements(h, "a")
  x <- stringr::str_squish(rvest::html_text2(a))
  x <- gsub("[​‌‍⁠﻿]", "", x)
  unique(x[nchar(x) >= 12L])
}

#' The tripwire, on one page. Returns the new RHTP-and-award headlines; the
#' caller throws. Also refuses a page whose reader yields too few headlines
#' to have read anything (the message carries "HTTP 200" so the log files it
#' as ERROR, a statement about our reading and not the state).
nw_new_hot <- function(live_raw, arch_raw, st, key) {
  live <- nw_headlines(live_raw)
  arch <- nw_headlines(arch_raw)
  if (length(live) < 15L) {
    stop("[", st, ":", key, "] HTTP 200 served but the reader found only ",
         length(live), " headlines; our reading, not the state, has changed ",
         "(§0.4).", call. = FALSE)
  }
  new <- setdiff(live, arch)
  new[grepl(NW_RHTP, new, ignore.case = TRUE) &
        grepl(NW_AWARD, new, ignore.case = TRUE)]
}

#' One state's pages. Returns the per-page changed tibble for the log; throws
#' a TRIPWIRE naming every hot headline.
nw_probe_state <- function(st, pages = NW_PAGES) {
  p <- pages[pages$state == st, ]
  w <- rhtp_watch_pages(p, NW_USER_AGENT)
  hot <- character(0)
  for (k in p$key) {
    arch_raw <- paste(readLines(here::here(p$file[p$key == k]), warn = FALSE),
                      collapse = "\n")
    h <- nw_new_hot(w$raw[[k]], arch_raw, st, k)
    if (length(h)) hot <- c(hot, paste0(k, ": '", rhtp_watch_quote(h), "'"))
  }
  if (length(hot)) {
    stop("[", st, "] NEW RHTP AWARD HEADLINE ON A NEWSROOM INDEX: ",
         paste(hot, collapse = "; "),
         ". Open the item and look for a roster (Tennessee's and New Jersey's ",
         "shape). Then extract it, or re-base this page with --fetch after ",
         "READING it (§2.2).", call. = FALSE)
  }
  tibble::tibble(page = paste0(st, ":", w$changed$key),
                 changed = w$changed$changed)
}

nw_retest_unreadable <- function(u = NW_UNREADABLE) {
  now <- character(0)
  for (i in seq_len(nrow(u))) {
    code <- tryCatch(httr::status_code(httr::GET(
      u$url[i], httr::user_agent(NW_USER_AGENT), httr::timeout(60))),
      error = function(e) NA_integer_)
    if (isTRUE(code == 200L)) now <- c(now, u$state[i])
  }
  now
}

#' The sweep. Each state runs inside its OWN rhtp_probe_run(), so one state's
#' ERROR or TRIPWIRE is logged and does not stop the other seventeen. The exit
#' is non-zero if any state tripped.
nw_sweep <- function(states = unique(NW_PAGES$state)) {
  fired <- character(0); errored <- character(0)
  for (st in states) {
    r <- tryCatch({
      rhtp_probe_run(NW_LOG_STATE, nw_probe_state(st)); "ok"
    }, error = function(e) {
      m <- conditionMessage(e)
      if (grepl("HTTP|refused|timed out|timeout|resolve|connect", m,
                ignore.case = TRUE)) "error" else "tripwire"
    })
    if (r == "tripwire") fired <- c(fired, st)
    if (r == "error") errored <- c(errored, st)
  }
  opened <- nw_retest_unreadable()
  message("[NEWSROOM] ", length(states), " states swept; tripwire: ",
          if (length(fired)) paste(fired, collapse = " ") else "none",
          "; access errors: ",
          if (length(errored)) paste(errored, collapse = " ") else "none",
          "; unreadable re-tested (", paste(NW_UNREADABLE$state, collapse = " "),
          "): ", if (length(opened)) paste(opened, "NOW READABLE") else "still refused")
  if (length(opened)) {
    rhtp_probe_log(NW_LOG_STATE, tibble::tibble(
      verdict = "TRIPWIRE", page = paste0(opened, ":unreadable"),
      note = "a newsroom recorded as unreadable now answers 200 -- add it to NW_PAGES with a baseline"))
  }
  if (length(fired) || length(opened)) {
    stop("[NEWSROOM] tripwire in: ", paste(c(fired, opened), collapse = " "),
         call. = FALSE)
  }
  invisible(list(fired = fired, errored = errored))
}

nw_fetch <- function(pages = NW_PAGES) {
  for (i in seq_len(nrow(pages))) {
    rhtp_watch_archive(pages$url[i], pages$file[i], NW_USER_AGENT)
    Sys.sleep(2)
  }
  message("[NEWSROOM] archived ", nrow(pages), " baselines under ", NW_DIR)
}

nw_assert_coverage <- function() {
  covered <- union(NW_PAGES$state, NW_UNREADABLE$state)
  if (!setequal(covered, NW_STATES)) {
    stop("[NEWSROOM] the sweep covers ", paste(sort(covered), collapse = " "),
         "; the no-release set is ", paste(NW_STATES, collapse = " "), ".",
         call. = FALSE)
  }
  if (length(intersect(NW_PAGES$state, NW_UNREADABLE$state))) {
    stop("[NEWSROOM] a state is both watched and recorded unreadable.",
         call. = FALSE)
  }
  invisible(TRUE)
}

nw_report <- function() {
  nw_assert_coverage()
  for (i in seq_len(nrow(NW_PAGES))) {
    f <- here::here(NW_PAGES$file[i])
    n <- if (file.exists(f)) length(nw_headlines(paste(readLines(f, warn = FALSE),
                                                       collapse = "\n"))) else NA
    cat(sprintf("%s %-9s %4s headlines  %s\n", NW_PAGES$state[i], NW_PAGES$key[i],
                n, NW_PAGES$url[i]))
  }
  cat("\nUNREADABLE (re-tested every run):\n")
  cat(paste0(NW_UNREADABLE$state, "  ", NW_UNREADABLE$observed, "\n"), sep = "")
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) nw_fetch()
  # Each state is handed to rhtp_probe_run() inside nw_sweep(), so the
  # evidence guard wraps every page this probe reads.
  if ("--probe" %in% args) { nw_assert_coverage(); nw_sweep() }
  if ("--report" %in% args) nw_report()
  if (!length(args)) message("Usage: --fetch | --probe | --report")
}
