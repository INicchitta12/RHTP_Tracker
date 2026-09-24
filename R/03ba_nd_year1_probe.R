#!/usr/bin/env Rscript
# 03ba_nd_year1_probe.R ------------------------------------------------------
#
# NORTH DAKOTA -- A WATCH, NOT AN EXTRACTION (session 59). ND HHS runs 25 RHTP
# funding opportunities from one page, each headed with its own status:
#
#   "Zero-Hour Physical Education (PE) Initiative – Closed (23 Applicants)"
#   ...
#   "Expand Rural Health Care Rotations – Awarded | 24 Applicants"
#
# On 2026-09-23, 24 read "Closed" and ONE reads "Awarded" -- naming nobody
# (session 55). 769 applicants between them. Several classes are hospitals
# outright ("Hospital-Based Wellness Equipment", "Workforce Retention Funding
# for Critical Access Hospitals ...", "Rightsizing ... Critical Access
# Hospitals"), so an awardee list here is likely to carry hospital money.
#
# WEEKLY, because North Dakota publishes no award date (the Zero-Hour PE
# estimate of ~early August has passed and nothing replaced it) -- North
# Carolina's and New Mexico's footing.
#
# THE TRIPWIRE IS THE HEADING, which is the cheapest one this project has had:
# a second "– Awarded" is the state telling us, in its own markup, that it has
# awarded. The one already Awarded is recorded here by name, so it cannot trip.
# A heading that disappears, a new opportunity, or a count change is CHANGED
# (the digest), not a tripwire. Fewer than 20 headings means our READER broke,
# never that North Dakota withdrew anything (§0.4).
#
# Both pages are name-diffed (§2.3): an awardee named in a FAQ answer or in a
# new "Awardees" paragraph fires even if the heading does not move.
#
# Usage: Rscript R/03ba_nd_year1_probe.R --validate | --probe

suppressPackageStartupMessages({ library(dplyr); library(stringr) })
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))

ND_STATE <- "ND"
ND_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                   "+https://www.aha.org)")
ND_DIR <- file.path("data", "evidence", "recheck", "2026-09-23", "ND")
ND_PAGES <- tibble::tribble(
  ~key, ~url, ~file, ~name_diff,
  "programme", "https://www.hhs.nd.gov/rural-health-transformation",
  file.path(ND_DIR, "hhs_rhtp_programme.html"), TRUE,
  "funding", "https://www.hhs.nd.gov/rural-health-transformation/funding",
  file.path(ND_DIR, "hhs_rhtp_funding.html"), TRUE)

ND_KNOWN_AWARDED <- "Expand Rural Health Care Rotations"

#' Every opportunity heading on the funding page, split into name and status
nd_headings <- function(raw) {
  h <- xml2::read_html(raw)
  x <- stringr::str_squish(rvest::html_text2(rvest::html_elements(h, "h2")))
  m <- stringr::str_match(x, "^(.*\\S)\\s+[–-]\\s+(Closed|Awarded|Open|Coming Soon|Forthcoming|Reopened|Cancelled)\\b(.*)$")
  tibble::tibble(heading = x, name = m[, 2], status = m[, 3]) %>%
    dplyr::filter(!is.na(.data$status))
}

nd_assert_headings <- function(raw) {
  hd <- nd_headings(raw)
  if (nrow(hd) < 20L) {
    stop("[ND] the funding page yields ", nrow(hd), " status headings; the ",
         "2026-09-23 archive has 25. That is our READER, not North Dakota ",
         "(§0.4) -- re-read the page's markup.", call. = FALSE)
  }
  awarded <- hd$name[hd$status == "Awarded"]
  new <- setdiff(awarded, ND_KNOWN_AWARDED)
  if (length(new)) {
    stop("[ND] NEW OPPORTUNITY HEADED 'AWARDED': ",
         paste0("'", rhtp_watch_quote(new), "'", collapse = "; "),
         ". THAT IS THE SIGNAL. North Dakota marks an award in the heading; ",
         "read the section for an awardee list and extract it.", call. = FALSE)
  }
  invisible(hd)
}

nd_validate <- function() {
  hd <- nd_assert_headings(here::here(ND_PAGES$file[ND_PAGES$key == "funding"]))
  stopifnot(nrow(hd) == 25L, sum(hd$status == "Awarded") == 1L)
  message("[ND] the archive carries 25 opportunities, one Awarded (",
          ND_KNOWN_AWARDED, "), nobody named.")
  invisible(TRUE)
}

nd_probe <- function() {
  w <- rhtp_watch_pages(ND_PAGES, ND_AGENT)
  nd_assert_headings(w$raw$funding)
  rhtp_assert_no_new_organisations_across(live = w$live, archived = w$arch,
                                          state = ND_STATE)
  message("[ND] ", paste0(w$changed$key, ": ",
                          ifelse(w$changed$changed, "CHANGED", "UNCHANGED"),
                          collapse = "; "), " -- still one Awarded heading.")
  invisible(w$changed)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) nd_validate()
  if ("--probe" %in% args) rhtp_probe_run("ND", nd_probe())
  if (!length(args)) message("Usage: --validate | --probe")
}
