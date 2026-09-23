#!/usr/bin/env Rscript
# 03bc_wa_year1_probe.R ------------------------------------------------------
#
# WASHINGTON -- A WATCH, NOT AN EXTRACTION (session 59). HCA's 2026-09-16
# webinar deck PRICES Washington's first-tier sub-recipients (session 55, §4):
#
#   Washington State Hospital Association  $42,000,000  (tech & cyber, taking
#                                                        hospital applications)
#   The Rural Collaborative                 $5,430,000  "30 member hospitals",
#                                                        unnamed
#   A rural-hospital competitive bid       $10,710,000  COMPLETED, no winners
#                                                        published
#
# About $58.1M of hospital-facing money behind rosters Washington has not
# published. None of it is a named-hospital dollar today: WSHA and The Rural
# Collaborative are hospital-governed intermediaries (§10.2's association row
# decides them on what the source says the money DOES), and the competitive
# bid names nobody. The day any of the three names its hospitals is the day
# this state becomes an extraction.
#
# WEEKLY, because Washington publishes no award date for any of the three --
# the project's own rule (North Carolina's and New Mexico's footing).
#
# THE WATCH, READ-ONLY (§2.2): the programme page (at its MOVED url --
# "/programs-and-initiatives/", HCA says "Temporarily"), What We're Working On
# (which lists sub-awardees BY CLASS today) and How to Participate are all
# name-diffed (§2.3). HCA's Bids and Contracts page is a procurement index that
# moves for reasons unrelated to RHTP, so it is not name-diffed; a NEW sentence
# on it about rural health, the RHT programme or an apparent successful bidder
# trips instead.
#
# §0.2 NOTE. The programme page carries TWO CMS footers: the 100% form printing
# the $181,257,515.06 allotment, and the RNEP item's SUBAWARD form, "with
# $3,500,000 and 80 percent funded by CMS/HHS and $914,538 and 20 percent funded
# by other source(s)". Session 55 found rhtp_footer_parse() returned ZERO rows
# on the second; session 59 taught it the SUBAWARD_OF form, and this probe
# REQUIRES both footers to parse -- the headline of each colliding with the
# allotment -- so a page edit that breaks the parse is a tripwire, not a
# silence.
#
# Usage: Rscript R/03bc_wa_year1_probe.R --validate | --probe

suppressPackageStartupMessages({ library(dplyr); library(stringr) })
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))

WA_STATE <- "WA"
WA_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                   "+https://www.aha.org)")
WA_DIR <- file.path("data", "evidence", "recheck", "2026-09-23", "WA")
WA_BASE <- paste0("https://www.hca.wa.gov/about-hca/programs-and-initiatives/",
                  "rural-health-transformation-program")
WA_PAGES <- tibble::tribble(
  ~key, ~url, ~file, ~name_diff,
  "programme", WA_BASE, file.path(WA_DIR, "hca_rhtp_programme.html"), TRUE,
  "working_on", paste0(WA_BASE, "/what-we-re-working"),
  file.path(WA_DIR, "hca_rhtp_what_were_working_on.html"), TRUE,
  "participate", paste0(WA_BASE, "/how-participate"),
  file.path(WA_DIR, "hca_rhtp_how_to_participate.html"), TRUE,
  "bids", "https://www.hca.wa.gov/about-hca/bids-and-contracts",
  file.path(WA_DIR, "hca_bids_and_contracts.html"), FALSE)

WA_BIDS_WORDS <- paste0("Rural Health|\\bRHT\\b|\\bRHTP\\b|apparent successful|",
                        "successful bidder|intent to award")
WA_AWARD_WORDS <- "\\bawardees?\\b|\\bawarded to\\b|\\bselected\\b|\\brecipients? (are|include)\\b"

wa_assert_footers <- function(programme_text) {
  f <- rhtp_footer_parse(programme_text)
  sub <- f[f$form == "SUBAWARD_OF", ]
  if (nrow(sub) < 1L) {
    stop("[WA] the programme page's SUBAWARD footer no longer parses. Either ",
         "HCA re-worded it or removed the RNEP item -- read the page (§0.2).",
         call. = FALSE)
  }
  for (i in seq_len(nrow(f))) {
    rhtp_assert_footer_text_tier(programme_text, WA_STATE, "STATE_ALLOTMENT",
                                 label = paste("WA programme footer", i),
                                 which = i)
  }
  invisible(f)
}

wa_assert_watch <- function(live, arch) {
  wa_assert_footers(live$programme)
  rhtp_watch_forbid_new(live$bids, arch$bids, WA_BIDS_WORDS, WA_STATE, "bids",
    paste("HCA's procurement index now mentions rural health / RHT or an",
          "apparent successful bidder. The $10.71M rural-hospital bid is",
          "COMPLETED with no winners published -- this may be them."))
  for (k in c("programme", "working_on", "participate")) {
    rhtp_watch_forbid_new(live[[k]], arch[[k]], WA_AWARD_WORDS, WA_STATE, k,
      "Washington naming sub-award recipients. Read the page and extract them.")
  }
  invisible(TRUE)
}

wa_validate <- function() {
  arch <- lapply(stats::setNames(WA_PAGES$file, WA_PAGES$key),
                 function(f) rhtp_watch_reduce(here::here(f)))
  wa_assert_watch(arch, arch)
  message("[WA] the archive's two footers parse and tier-check; no award ",
          "sentence.")
  invisible(TRUE)
}

wa_probe <- function() {
  w <- rhtp_watch_pages(WA_PAGES, WA_AGENT)
  wa_assert_watch(w$live_all, w$arch_all)
  rhtp_assert_no_new_organisations_across(live = w$live, archived = w$arch,
                                          state = WA_STATE)
  message("[WA] ", paste0(w$changed$key, ": ",
                          ifelse(w$changed$changed, "CHANGED", "UNCHANGED"),
                          collapse = "; "), " -- no sub-recipient roster.")
  invisible(w$changed)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) wa_validate()
  if ("--probe" %in% args) rhtp_probe_run("WA", wa_probe())
  if (!length(args)) message("Usage: --validate | --probe")
}
