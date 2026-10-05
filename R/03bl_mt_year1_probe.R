#!/usr/bin/env Rscript
# 03bl_mt_year1_probe.R ------------------------------------------------------
#
# MONTANA -- A ROSTER WATCH ON AN EXTRACTED STATE (session 88).
#
# Session 75 wrote this as a pre-award watch on DPHHS's dated anchor ("funding
# decisions will be shared in September"). DPHHS awarded on 2026-09-29: the
# Grants page now reads "Date Awarded: Sept. 29, 2026 · Amount: $8.7 million ·
# The funds will support 78 EMS agencies", and the Governor/DPHHS release names
# the four ambulance awardees at "approximately $340,000 each" and NOBODY among
# the 75 equipment awards. R/03bv extracts that: four rounded rows and one
# unnamed pool (mt_year1_awardees.csv). This file now watches for what is
# still missing.
#
# THE WATCH, READ-ONLY (§2.2), against the 2026-10-05 baselines:
#   * release -- the 2026-09-29 award release. NAME-DIFFED (§2.3): DPHHS adding
#     the 75 equipment awardees to it, in any words, is a new organisation.
#     It TRIPS if the ambulance sentence or the "75 agencies" sentence goes,
#     because those two sentences are what R/03bv's five rows rest on.
#   * grants -- NAME-DIFFED; TRIPS if the "Date Awarded: Sept. 29, 2026" block
#     goes, or on a NEW award sentence (a second round, the CIH pilot grant).
#   * rfps, home -- NAME-DIFFED; TRIP on a new award sentence.
#   * communications -- DPHHS's RHTP announcement index. NOT name-diffed (an
#     index of headlines moves every week, §2.3); TRIPS on a new headline
#     speaking of awards or recipients.
#
# WHEN IT FIRES: a named equipment roster moves rows OUT of R/03bv's pool row
# into named rows (re-run R/03bv, never edit the CSV); a new round is a new
# pool in mt_year1_awardees.csv.
#
# §0.3 TRAP, RECORDED SO IT IS NOT MISREAD: DPHHS's "Vendor and Subcontractor
# Directory" lists 100+ organisations and says it "does not guarantee a
# partnership, subcontracting opportunity, or contract award". It is NOT
# watched: a directory growing is not an award.
#
# Usage: Rscript R/03bl_mt_year1_probe.R --fetch | --validate | --probe

suppressPackageStartupMessages({ library(dplyr); library(stringr) })
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))

MT_STATE <- "MT"
MT_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                   "+https://www.aha.org)")
MT_DIR <- file.path("data", "evidence", "MT")
MT_BASE <- "https://dphhs.mt.gov/RuralHealthTransformationProgram/"
MT_PAGES <- tibble::tribble(
  ~key, ~url, ~file, ~name_diff,
  "release", "https://dphhs.mt.gov/News/2026/September/Investment-in-Rural-EMS",
  file.path(MT_DIR, "2026-10-05_mt_dphhs_rural_ems_award_release.html"), TRUE,
  "grants", paste0(MT_BASE, "Grants"),
  file.path(MT_DIR, "2026-10-05_mt_rhtp_grants.html"), TRUE,
  "rfps", paste0(MT_BASE, "RHTP-RFPs"),
  file.path(MT_DIR, "2026-10-05_mt_rhtp_rfps.html"), TRUE,
  "home", MT_BASE,
  file.path(MT_DIR, "2026-10-05_mt_rhtp_home.html"), TRUE,
  "communications", paste0(MT_BASE, "Communications"),
  file.path(MT_DIR, "2026-10-05_mt_rhtp_communications.html"), FALSE)

# What R/03bv's five rows rest on, and the Grants page's award block. The
# session-75 anchor ("funding decisions will be shared in September") is gone
# because DPHHS awarded; these replace it.
MT_ANCHORS <- list(
  release = c(
    "Four agencies were awarded ambulances at a cost of approximately $340,000 each",
    "75 agencies, including three tribal governments, have been awarded funding for 238 pieces of equipment"),
  grants = c("Date Awarded: Sept. 29, 2026", "Amount: $8.7 million",
             "The funds will support 78 EMS agencies."))
MT_AWARD_WORDS <- paste0("\\baward(s|ed|ee|ees)?\\b|\\brecipients?\\b|",
                         "\\bselected\\b|\\bgrantees?\\b|\\bfunding decisions\\b")

mt_assert_watch <- function(live, arch) {
  for (k in names(MT_ANCHORS)) {
    rhtp_watch_require(live[[k]], MT_ANCHORS[[k]], MT_STATE, k)
  }
  why <- paste("Montana has awarded its EMS Equipment Grant and named only the",
               "four ambulance awardees. A new award sentence is a roster for",
               "the 75 or a new round: read it, then re-run R/03bv.")
  for (k in c("release", "grants", "rfps", "home", "communications")) {
    rhtp_watch_forbid_new(live[[k]], arch[[k]], MT_AWARD_WORDS, MT_STATE, k, why)
  }
  invisible(TRUE)
}

mt_fetch <- function() {
  for (i in seq_len(nrow(MT_PAGES))) {
    rhtp_watch_archive(MT_PAGES$url[i], MT_PAGES$file[i], MT_AGENT)
    Sys.sleep(3)
  }
  message("[MT] archived ", nrow(MT_PAGES), " baseline pages to ", MT_DIR, ".")
}

mt_validate <- function() {
  arch <- lapply(stats::setNames(MT_PAGES$file, MT_PAGES$key),
                 function(f) rhtp_watch_reduce(here::here(f)))
  mt_assert_watch(arch, arch)
  message("[MT] the archive carries the 2026-09-29 award block; four ",
          "ambulance awardees named, 75 equipment awardees unnamed.")
  invisible(TRUE)
}

mt_probe <- function() {
  w <- rhtp_watch_pages(MT_PAGES, MT_AGENT)
  mt_assert_watch(w$live_all, w$arch_all)
  rhtp_assert_no_new_organisations_across(live = w$live, archived = w$arch,
                                          state = MT_STATE)
  message("[MT] ", paste0(w$changed$key, ": ",
                          ifelse(w$changed$changed, "CHANGED", "UNCHANGED"),
                          collapse = "; "), " -- no new roster or round.")
  invisible(w$changed)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) mt_fetch()
  if ("--validate" %in% args) mt_validate()
  if ("--probe" %in% args) rhtp_probe_run("MT", mt_probe())
  if (!length(args)) message("Usage: --fetch | --validate | --probe")
}
