#!/usr/bin/env Rscript
# 03bm_nh_year1_probe.R ------------------------------------------------------
#
# NEW HAMPSHIRE -- A WATCH ON THE DESIGNATED ADMINISTRATOR (session 75). Every
# nh.gov host is Akamai-403 to this environment on four agents (session 29,
# re-tested 2026-09-28: gonorth.nh.gov and its /contracts-awards page both
# 403), so what the STATE publishes is UNKNOWN (§0.4). What IS readable is the
# Foundation for Healthy Communities' own GO-NORTH page on healthynh.org -- the
# designated pass-through administrator §7 admits (Illinois/ICAHN's route) --
# and CDFA's statement. R/03x extracts the two administrator awards; this file
# watches for the SUBRECIPIENTS, which nobody has named.
#
# WHAT FHC'S PAGE SAID ON 2026-09-28 (it had moved since the 09-01 archive):
#   * Critical Access Hospital (CAH) and Acute Care Hospital -- "Coming Soon",
#     with "RFA Expected Published late August", a date that has PASSED. THIS
#     IS WHERE NEW HAMPSHIRE'S HOSPITAL MONEY WILL BE.
#   * Primary Care Access RFA -- Open; "Notification of Award (initial cohort):
#     Late October". The dated anchor.
#   * EMS -- now "Closed", nobody named. School-Based Oral Health -- closed
#     2026-09-25. Rural Health Technology & Digital Infrastructure -- "FHC is
#     no longer moving forward with this RFA."
#
# THE CLASS IS HOSPITALS AMONG OTHERS (§0.3): FHC will manage "50-100 active
# subrecipient awards across primary care, critical access hospitals, EMS,
# behavioral health, oral health, and community-based organizations". A roster
# here is read one award at a time; the CAH/Acute Care RFA is the one class
# that is hospitals only.
#
# WEEKLY, and the reason is stated: the only published decision date is "Late
# October", a month out; the CAH RFA going live is a publication, not an award.
#
# THE WATCH, READ-ONLY (§2.2):
#   * fhc -- name-diffed (§2.3). TRIPS if the CAH/Acute Care block stops
#     reading "Coming Soon" (the hospital RFA has been published: read it and
#     record its eligible class before anything is awarded against it), if the
#     "Late October" anchor goes, or if a NEW sentence speaks of awards,
#     awardees, recipients, subrecipients or selection. FHC's baseline already
#     says "administering awards", "50-100 active subrecipient awards" and
#     carries a news headline "EC approves recipients of GO NORTH federal
#     funding" (the 2026-03-16 administrators); the phrase check is a DIFF.
#   * cdfa -- name-diffed; trips on a new award sentence.
#
# Usage: Rscript R/03bm_nh_year1_probe.R --fetch | --validate | --probe

suppressPackageStartupMessages({ library(dplyr); library(stringr) })
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))

NH_STATE <- "NH"
NH_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                   "+https://www.aha.org)")
NH_DIR <- file.path("data", "evidence", "NH")
NH_PAGES <- tibble::tribble(
  ~key, ~url, ~file, ~name_diff,
  "fhc", "https://healthynh.org/initiatives/rural-health-transformation-program/",
  file.path(NH_DIR, "2026-09-28_fhc_go_north_rhtp.html"), TRUE,
  "cdfa", paste0("https://nhcdfa.org/cdfa-statement-about-the-rural-",
                 "community-health-infrastructure-programs/"),
  file.path(NH_DIR, "2026-09-28_cdfa_rchip_statement.html"), TRUE)

NH_ANCHORS <- c(
  "Critical Access Hospital (CAH) and Acute Care Hospital Coming Soon",
  "Notification of Award (initial cohort): Late October")
NH_AWARD_WORDS <- paste0("\\baward(s|ed|ee|ees)?\\b|\\b(sub)?recipients?\\b|",
                         "\\bselected\\b|\\bgrantees?\\b")

nh_assert_watch <- function(live, arch) {
  rhtp_watch_require(live$fhc, NH_ANCHORS, NH_STATE, "fhc")
  why <- paste("FHC has named no GO-NORTH subrecipient. A roster here is read",
               "one award at a time: hospitals are AMONG OTHERS (§0.3).")
  rhtp_watch_forbid_new(live$fhc, arch$fhc, NH_AWARD_WORDS, NH_STATE, "fhc", why)
  rhtp_watch_forbid_new(live$cdfa, arch$cdfa, NH_AWARD_WORDS, NH_STATE, "cdfa",
                        why)
  invisible(TRUE)
}

nh_fetch <- function() {
  for (i in seq_len(nrow(NH_PAGES))) {
    rhtp_watch_archive(NH_PAGES$url[i], NH_PAGES$file[i], NH_AGENT)
    Sys.sleep(3)
  }
  message("[NH] archived ", nrow(NH_PAGES), " baseline pages to ", NH_DIR, ".")
}

nh_validate <- function() {
  arch <- lapply(stats::setNames(NH_PAGES$file, NH_PAGES$key),
                 function(f) rhtp_watch_reduce(here::here(f)))
  nh_assert_watch(arch, arch)
  stopifnot(grepl("FHC is no longer moving forward with this RFA", arch$fhc,
                  fixed = TRUE),
            grepl("RFA Expected Published late August", arch$fhc, fixed = TRUE))
  message("[NH] the archive carries both anchors and no subrecipient; the ",
          "CAH/Acute Care RFA is still 'Coming Soon'.")
  invisible(TRUE)
}

nh_probe <- function() {
  w <- rhtp_watch_pages(NH_PAGES, NH_AGENT)
  nh_assert_watch(w$live_all, w$arch_all)
  rhtp_assert_no_new_organisations_across(live = w$live, archived = w$arch,
                                          state = NH_STATE)
  message("[NH] ", paste0(w$changed$key, ": ",
                          ifelse(w$changed$changed, "CHANGED", "UNCHANGED"),
                          collapse = "; "), " -- no GO-NORTH subrecipient named.")
  invisible(w$changed)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) nh_fetch()
  if ("--validate" %in% args) nh_validate()
  if ("--probe" %in% args) rhtp_probe_run("NH", nh_probe())
  if (!length(args)) message("Usage: --fetch | --validate | --probe")
}
