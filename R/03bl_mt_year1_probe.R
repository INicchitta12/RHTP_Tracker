#!/usr/bin/env Rscript
# 03bl_mt_year1_probe.R ------------------------------------------------------
#
# MONTANA -- A WATCH, NOT AN EXTRACTION (session 75). Montana is QUEUED: the
# largest allotment in the country without a probe ($233,509,359) and no
# published award of any kind. DPHHS runs its grants through Submittable and
# its RFPs through bids.mt.gov (a JavaScript application this environment
# cannot read), and publishes each one's status on its own RHTP pages. On
# 2026-09-28 those pages say:
#
#   * EMS Equipment Grant, $4 million, closed 8/15/26: "Grant applications are
#     now being reviewed, and funding decisions will be shared in September."
#     That is the dated anchor, and it runs out in two days.
#   * Community Integrated Health (CIH) Pilot Site Grant, for EMS: "It expired
#     on 9/15/26." No decision date.
#   * RFPs: Emergency Medical Dispatch System (closed 2026-09-23), Community
#     Health Aide Program TA (closes 2026-10-01), a DLI workforce RFI (closed
#     2026-08-31), and two Center of Excellence RFPs.
#
# NEITHER GRANT IS HOSPITAL MONEY BY ITS OWN CLASS: both are open to EMS
# agencies. An EMS agency run by a hospital would still be coded on the
# RECIPIENT (§0.3a), so the watch does not dismiss them. Montana's hospital-
# facing initiatives have not been solicited on these pages at all.
#
# TWICE-WEEKLY, because Montana PUBLISHED a decision month and it is this one
# (Wisconsin's, Connecticut's and Colorado's footing).
#
# THE WATCH, READ-ONLY (§2.2):
#   * grants -- name-diffed (§2.3); TRIPS if the "September" sentence goes or
#     if a NEW sentence speaks of awards, awardees, recipients or selection.
#   * rfps, home -- name-diffed; TRIP on a new award sentence. The home page
#     already says DPHHS "was awarded a historic $233 million" (Tier 1); the
#     phrase check is a DIFF, so a baseline sentence costs nothing.
#   * communications -- DPHHS's own RHTP announcement index. NOT name-diffed
#     (an index of headlines moves every week, §2.3); TRIPS on a new headline
#     speaking of awards or recipients.
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
  "grants", paste0(MT_BASE, "Grants"),
  file.path(MT_DIR, "2026-09-28_mt_rhtp_grants.html"), TRUE,
  "rfps", paste0(MT_BASE, "RHTP-RFPs"),
  file.path(MT_DIR, "2026-09-28_mt_rhtp_rfps.html"), TRUE,
  "home", MT_BASE,
  file.path(MT_DIR, "2026-09-28_mt_rhtp_home.html"), TRUE,
  "communications", paste0(MT_BASE, "Communications"),
  file.path(MT_DIR, "2026-09-28_mt_rhtp_communications.html"), FALSE)

MT_ANCHOR <- paste("Grant applications are now being reviewed, and funding",
                   "decisions will be shared in September.")
MT_AWARD_WORDS <- paste0("\\baward(s|ed|ee|ees)?\\b|\\brecipients?\\b|",
                         "\\bselected\\b|\\bgrantees?\\b|\\bfunding decisions\\b")

mt_assert_watch <- function(live, arch) {
  rhtp_watch_require(live$grants, MT_ANCHOR, MT_STATE, "grants")
  why <- paste("Montana said EMS Equipment Grant decisions would be shared in",
               "September 2026. Read the page and extract what it names.")
  for (k in c("grants", "rfps", "home", "communications")) {
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
  stopifnot(grepl("It expired on 9/15/26", arch$grants, fixed = TRUE),
            grepl("A total of $4 million", arch$grants, fixed = TRUE))
  message("[MT] the archive carries the September anchor and no award ",
          "sentence; both grants closed, nobody named.")
  invisible(TRUE)
}

mt_probe <- function() {
  w <- rhtp_watch_pages(MT_PAGES, MT_AGENT)
  mt_assert_watch(w$live_all, w$arch_all)
  rhtp_assert_no_new_organisations_across(live = w$live, archived = w$arch,
                                          state = MT_STATE)
  message("[MT] ", paste0(w$changed$key, ": ",
                          ifelse(w$changed$changed, "CHANGED", "UNCHANGED"),
                          collapse = "; "), " -- no award announcement.")
  invisible(w$changed)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) mt_fetch()
  if ("--validate" %in% args) mt_validate()
  if ("--probe" %in% args) rhtp_probe_run("MT", mt_probe())
  if (!length(args)) message("Usage: --fetch | --validate | --probe")
}
