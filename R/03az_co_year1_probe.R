#!/usr/bin/env Rscript
# 03az_co_year1_probe.R ------------------------------------------------------
#
# COLORADO -- A WATCH, NOT AN EXTRACTION (session 59). Colorado is QUEUED
# (session 55, §4): HCPF's $160M RHTP grant RFA closed 2026-08-03 and no award
# is published. What makes it worth a twice-weekly Routine is HCPF's own date:
#
#   "The RHTP team anticipates making our award announcements by the end of
#    September 2026."
#
# TWICE-WEEKLY because the state PUBLISHED that date (Wisconsin's, Connecticut's
# and Mississippi's footing), and it is a week away.
#
# THE WATCH, READ-ONLY (§2.2):
#   * HCPF's RHTP programme page -- name-diffed (§2.3); TRIPS if the dated
#     sentence above goes (awarded, re-dated or re-worded: all worth reading)
#     or if a NEW sentence speaks of awards, awardees, recipients or selection.
#     "HCPF has awarded a contract to the Colorado Rural Health Center" is in
#     the baseline and costs nothing: the phrase check is a DIFF.
#   * the Governor's press index -- NOT name-diffed (a press index moves every
#     week, §2.3 subject pages only); TRIPS on any new item mentioning the
#     Rural Health Transformation Program.
#
# The host needs the RFC crawler agent carrying our name and contact URL, which
# is what TN/WV/VT already send (session 43: identifying honestly is the fix).
#
# Usage: Rscript R/03az_co_year1_probe.R --validate | --probe

suppressPackageStartupMessages({ library(dplyr); library(stringr) })
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))

CO_STATE <- "CO"
CO_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                   "+https://www.aha.org)")
CO_DIR <- file.path("data", "evidence", "recheck", "2026-09-23", "CO")
CO_PAGES <- tibble::tribble(
  ~key, ~url, ~file, ~name_diff,
  "rhtp", "https://hcpf.colorado.gov/rural-health-transformation-program",
  file.path(CO_DIR, "co_hcpf_rhtp.html"), TRUE,
  "governor_news", "https://governorsoffice.colorado.gov/governor/news",
  file.path(CO_DIR, "co_governor_news_index.html"), FALSE)

CO_ANCHOR <- paste("The RHTP team anticipates making our award announcements",
                   "by the end of September 2026.")
CO_AWARD_WORDS <- "\\baward(s|ed|ee|ees)?\\b|\\brecipients?\\b|\\bselected\\b|\\bgrantees?\\b"
CO_RHTP_WORDS  <- "Rural Health Transformation|\\bRHTP\\b"

co_assert_watch <- function(live, arch) {
  rhtp_watch_require(live$rhtp, CO_ANCHOR, CO_STATE, "rhtp")
  rhtp_watch_forbid_new(live$rhtp, arch$rhtp, CO_AWARD_WORDS, CO_STATE, "rhtp",
    paste("HCPF said it would announce awards by the end of September 2026.",
          "Read the page and extract what it names."))
  rhtp_watch_forbid_new(live$governor_news, arch$governor_news, CO_RHTP_WORDS,
    CO_STATE, "governor_news",
    "A Governor's release on the RHTP is the likeliest award announcement.")
  invisible(TRUE)
}

co_validate <- function() {
  arch <- lapply(stats::setNames(CO_PAGES$file, CO_PAGES$key),
                 function(f) rhtp_watch_reduce(here::here(f)))
  co_assert_watch(arch, arch)
  message("[CO] the archive carries the dated anchor and no award sentence.")
  invisible(TRUE)
}

co_probe <- function() {
  w <- rhtp_watch_pages(CO_PAGES, CO_AGENT)
  co_assert_watch(w$live_all, w$arch_all)
  rhtp_assert_no_new_organisations_across(live = w$live, archived = w$arch,
                                          state = CO_STATE)
  message("[CO] ", paste0(w$changed$key, ": ",
                          ifelse(w$changed$changed, "CHANGED", "UNCHANGED"),
                          collapse = "; "), " -- no award announcement.")
  invisible(w$changed)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) co_validate()
  if ("--probe" %in% args) rhtp_probe_run("CO", co_probe())
  if (!length(args)) message("Usage: --validate | --probe")
}
