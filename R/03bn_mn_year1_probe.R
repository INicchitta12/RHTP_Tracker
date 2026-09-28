#!/usr/bin/env Rscript
# 03bn_mn_year1_probe.R ------------------------------------------------------
#
# MINNESOTA -- A WATCH, AND THE §0.3 TRAP WRITTEN DOWN BEFORE IT LANDS
# (session 75). Minnesota has been INVESTIGATED_NO_PROBE since session 43: MDH
# has awarded nobody publicly, and no probe was watching. On 2026-09-28 MDH's
# RHTP Funding page says "There are no current open grants and contracts
# opportunities", and every solicitation on it is under "Past Grants &
# Contracts Notices":
#
#   * THE DIRECT ALLOCATION -- "formula-based, non-competitive grants" to four
#     entity types, published as a table: Hospitals 70% of MN's RHTP Award, 94
#     eligible entities; FQHCs 5% / 5; CCBHCs/CMHCs 2% / 16; Tribal Nations 2%
#     / 10. Applications closed 2026-05-26. THIS IS MINNESOTA'S HOSPITAL MONEY
#     (~$135M at 70% of $193,090,618) AND IT IS §0.3 AT ITS MOST TEMPTING: a
#     formula allocation to a pre-identified class reads as though the eligible
#     list IS the award list. It is not. A hospital counts here when MDH names
#     it as a grantee with an amount, not before.
#   * Competitive RFPs, the last of which (Rural Telehealth Services, a
#     needs-assessment VENDOR contract) closed 2026-09-14. None names a winner.
#
# WEEKLY. MDH publishes no award date for the direct allocation or any RFP
# (North Carolina's and New Mexico's footing).
#
# THE WATCH, READ-ONLY (§2.2):
#   * grants -- name-diffed (§2.3). TRIPS if the entity table stops reading as
#     it does (MDH has re-cut the allocation, or replaced counts with names or
#     amounts: read it), or if a NEW sentence speaks of awards, awardees,
#     recipients, grantees or selection. The baseline already carries "Grant
#     recipients will select activities ...", "Subgrantees will include rural
#     hospitals ..." and "Applicants will be selected based on ..." -- all
#     future-tense or eligibility language, and all cost nothing because the
#     phrase check is a DIFF.
#   * programme -- name-diffed; same award-sentence diff.
# MDH's press index is already on R/03bg's newsroom sweep and is not repeated.
#
# Usage: Rscript R/03bn_mn_year1_probe.R --fetch | --validate | --probe

suppressPackageStartupMessages({ library(dplyr); library(stringr) })
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))

MN_STATE <- "MN"
MN_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                   "+https://www.aha.org)")
MN_DIR <- file.path("data", "evidence", "MN")
MN_BASE <- "https://www.health.state.mn.us/facilities/ruralhealth/ruraltrans/"
MN_PAGES <- tibble::tribble(
  ~key, ~url, ~file, ~name_diff,
  "grants", paste0(MN_BASE, "grants.html"),
  file.path(MN_DIR, "2026-09-28_mdh_rhtp_grants.html"), TRUE,
  "programme", paste0(MN_BASE, "index.html"),
  file.path(MN_DIR, "2026-09-28_mdh_rhtp_programme.html"), TRUE)

# Whitespace-free, because the table's cells are flattened by the reducer and
# the archive's re-serialisation adds spaces between them that the live bytes
# do not carry.
MN_TABLE <- paste0("Hospitals70%ofMN'sRHTPAward94FQHCs5%ofMN'sRHTPAward5",
                   "CCBHCs/CMHCs2%ofMN'sRHTPAward16TribalNations2%ofMN's",
                   "RHTPAward10")
MN_AWARD_WORDS <- paste0("\\baward(s|ed|ee|ees)?\\b|\\b(sub)?recipients?\\b|",
                         "\\bselected\\b|\\b(sub)?grantees?\\b")

mn_assert_watch <- function(live, arch) {
  if (!grepl(MN_TABLE, gsub("\\s+", "", live$grants), fixed = TRUE)) {
    stop("[MN] 'grants' NO LONGER CARRIES the direct-allocation table (",
         "Hospitals 70% / 94, FQHCs 5% / 5, CCBHCs/CMHCs 2% / 16, Tribal ",
         "Nations 2% / 10). MDH has re-cut or replaced it -- if it now names ",
         "grantees or amounts, that is Minnesota's hospital money. Read it; ",
         "the 94 are ELIGIBLE, not awarded, until MDH says otherwise (§0.3).",
         call. = FALSE)
  }
  why <- paste("MDH has named no RHTP grantee. The 94 eligible hospitals are",
               "a class, not a roster (§0.3); read what the page now names.")
  for (k in c("grants", "programme")) {
    rhtp_watch_forbid_new(live[[k]], arch[[k]], MN_AWARD_WORDS, MN_STATE, k, why)
  }
  invisible(TRUE)
}

mn_fetch <- function() {
  for (i in seq_len(nrow(MN_PAGES))) {
    rhtp_watch_archive(MN_PAGES$url[i], MN_PAGES$file[i], MN_AGENT)
    Sys.sleep(3)
  }
  message("[MN] archived ", nrow(MN_PAGES), " baseline pages to ", MN_DIR, ".")
}

mn_validate <- function() {
  arch <- lapply(stats::setNames(MN_PAGES$file, MN_PAGES$key),
                 function(f) rhtp_watch_reduce(here::here(f)))
  mn_assert_watch(arch, arch)
  stopifnot(grepl("There are no current open grants and contracts opportunities",
                  arch$grants, fixed = TRUE),
            grepl("formula-based, non-competitive grants", arch$grants,
                  fixed = TRUE))
  message("[MN] the archive carries the 94-hospital allocation table and no ",
          "award sentence; nothing open, nobody named.")
  invisible(TRUE)
}

mn_probe <- function() {
  w <- rhtp_watch_pages(MN_PAGES, MN_AGENT)
  mn_assert_watch(w$live_all, w$arch_all)
  rhtp_assert_no_new_organisations_across(live = w$live, archived = w$arch,
                                          state = MN_STATE)
  message("[MN] ", paste0(w$changed$key, ": ",
                          ifelse(w$changed$changed, "CHANGED", "UNCHANGED"),
                          collapse = "; "), " -- no RHTP grantee named.")
  invisible(w$changed)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) mn_fetch()
  if ("--validate" %in% args) mn_validate()
  if ("--probe" %in% args) rhtp_probe_run("MN", mn_probe())
  if (!length(args)) message("Usage: --fetch | --validate | --probe")
}
