#!/usr/bin/env Rscript
# 03aj_wy_year1_awardees.R ----------------------------------------------------
#
# WYOMING -- RHTP Year 1. Wyoming is the FOURTH ZERO-SIGNAL STATE WITH A
# PUBLISHED, NAMED, PRICED ROSTER (Florida, North Carolina, Arkansas, Wyoming),
# and the roster is in a GOOGLE DRIVE FOLDER that `health.wyo.gov` links behind
# five words -- "View Documents In Google Drive". No CMS state release, no RCJ
# Tier 3 candidate: `trigger_source = NEITHER` on BOTH discovery layers, which
# is Florida's shape a fourth time.
#
# WHAT WYOMING PUBLISHES, AND IT IS ONE DOCUMENT.
#
#   AWARD APPROVALS    the Rural Health Transformation Advisory Committee's
#   2026-08-11         "Award Approvals - 8.11.26": a BUDGET SUMMARY across
#                      fifteen initiative lines that totals to the allotment
#                      exactly, and SIX recipient-level tables -- 1.1 Critical
#                      Access Hospital - Basic, 1.2 EMS Regionalization,
#                      2.2 Physician GME, 3.1 Technology Adoption Challenge,
#                      4.1 Integrated Primary Care, 4.2 Clinically-Integrated
#                      Care Coordination.
#   MINUTES            the same meeting's minutes, recording the motion behind
#   2026-08-11         every one of those tables, with the vote and the
#                      recusals. A SECOND READING of the same numbers.
#
# EVERY ROW IN THIS FILE IS A COMMITTEE APPROVAL, NOT AN EXECUTED AGREEMENT.
# The minutes state the deadline in Wyoming's own words -- "Year 1 Obligation
# Deadline: End of October 2026 (executed contracts/agreements)" -- and WDH's
# own programme-page timeline says "October 1, 2026: Contract execution
# deadline". Nothing has been executed, several approvals are explicitly
# CONDITIONAL, so all 77 rows are `NOTICE_OF_INTENT_TO_AWARD` +
# `amount_confirmed = No` + `AMOUNT_PRELIMINARY` (§8's existing code -- Alaska's
# and Arkansas's condition; NO NEW CODE WAS INVENTED, §2).
#
# WHY THIS FILE NEEDS SESSION 32'S RUN MODEL, AND WHAT IT COSTS WITHOUT IT.
# Six of the document's rows carry the RECIPIENT NAME IN A SEPARATE PAINTED RUN
# from the rest of the row -- two in 1.1 (North Lincoln County Hospital District
# dba Star Valley, South Big Horn County Hospital District) and four in 1.2
# (Star Valley again, Campbell County Health EMS, the Pine Bluffs consortium,
# the Shoshoni consortium). The producer paints a cell that overflows its
# column as its own text object, so `rhtp_pdf_lines()` -- which groups by the
# reader's line id -- emits the NAME as one line and THE WHOLE REST OF THE ROW
# as another. A line-model extractor therefore reports 1.1 as SIXTEEN hospitals
# and $43,044,174, orphaning $5,156,000 IN SILENCE: the two rows still exist,
# they simply have no name on them, and nothing about the output looks wrong.
#
# `wy_assert_line_model_splits_names()` asserts that the line model STILL
# splits them, and prices the loss, so that a later session cannot "simplify"
# this back to `rhtp_pdf_lines()` and get a quietly smaller Wyoming (session
# 35's lesson, and Arkansas's `ar_assert_line_model_merges()` in the mirror:
# Arkansas's line model WELDS three columns together, Wyoming's SPLITS one row
# apart, and both are the same reason for the same fix).
#
# THE PARSE IS x-BOUNDARY, WHICH ARKANSAS'S EXPLICITLY COULD NOT BE. This
# producer paints ONE GLYPH PER RUN, so a run's `x` is a character position and
# the columns of every table are separable at fixed x. `WY_TABLES` carries the
# boundaries; `wy_assert_reconciles()` is what proves them, because a wrong
# boundary cannot reconcile against SIX of the document's own `Total:` rows AND
# the budget summary AND the allotment at once.
#
# WITH ONE EXCEPTION, AND IT COST A NAME AND AN IDENTIFIER BEFORE IT WAS CAUGHT.
# FOUR of the six tables let a long applicant name OVERFLOW ITS COLUMN into the
# EIN's -- "North Lincoln County Hospital District dba Star Valley
# Heal83-0327251Y" is one painted row -- so a fixed boundary between those two
# either truncates the name or contaminates the identifier, and it silently did
# BOTH: Star Valley's Initiative 1.2 EIN came back `NA`, which is the exact key
# this file uses to carry Wyoming's stated hospital form from 1.1 into 1.2.
# The name and the EIN therefore come out of ONE WIDE BAND, SPLIT BY REGEX
# (`split_name_ein()`), and the name is kept AS PAINTED -- clipped by the
# producer at its own cell edge, never by this parse (§8).
#
# THE RECONCILIATION IS THE STRONGEST IN THIS REPOSITORY AFTER FLORIDA'S AND
# ARKANSAS'S, AND IT CLOSES AT THREE LEVELS.
#   per table   each of the six tables' approved column sums to that table's
#               own `Total:` row (4.2 has no total row and sums to the budget
#               summary line instead, and to the minutes' own $3,218,160)
#   per line    each table's total equals the budget summary's "Approved award"
#               for that initiative
#   whole       the budget summary's fifteen lines sum to $205,004,742, which
#               is the §7.1 allotment ($205,004,743) to a dollar and CMS's own
#               Notice of Award ($205,004,742.95) to a rounding
#
# §6.2. Wyoming's CMS footer is session 27's STRONG, programme-scoped form --
# "Wyoming's Rural Health Transformation Program is supported by ... a financial
# assistance award totaling $205,004,742.95 in Budget Period 1" -- AND ITS
# FIGURE IS THE ALLOTMENT, which is §0.2 and session 37's Iowa rule. It is
# declared `STATE_ALLOTMENT` and checked by `rhtp_assert_footer_not_allotment()`.
# It is NOT the provenance: the provenance is CMS's OWN NOTICE OF AWARD, which
# Wyoming publishes in the same Drive folder (RHTCMS332082-01-02) -- the FIFTH
# state to do so after Nevada, California, Connecticut and Kentucky.
#
# THE DATE TEST. Wyoming's NOA is a "Revision (Budget)" with a Federal Award
# Date of 05/14/2026 (+136 days) against a budget period that still starts
# 12/29/2025, which is session 36's pin holding a FIFTH time. The minutes
# corroborate the later date from the other side -- "Wyoming executed its formal
# agreement with CMS on May 14, 2026" -- and the awards are 2026-08-11, after
# both.
#
# §0.1 -- AND WYOMING ADDS A DEFECT CLASS THIS PROJECT HAD NOT RECORDED.
# RCJ FILES UTAH'S DOCUMENTS UNDER WYOMING. See
# `wy_rcj_candidate_disposition.csv` and `docs/session42_*`: five of RCJ's 29
# Wyoming records are Utah's, including Utah's $195.7M ALLOTMENT carried as an
# `UNASSIGNED` Wyoming row. Wrong STATE, after wrong programme (Texas), wrong
# tier (Oklahoma), wrong kind of action (Missouri), wrong grain (Michigan) and
# wrong section (Nebraska).
#
# WHAT IS DELIBERATELY NOT HERE.
#   $30,877,990 of the $205,004,742 -- 15.1% -- NAMES NOBODY AT ALL. The
#   fiscal-agent sweep (1., $17,612,195), the three competitive RFPs (3.2, 3.3,
#   3.4), 4.3, State Policy Action support and administration are approved at
#   POOL level with no recipient of any kind. They are in
#   `wy_year1_status.csv`, which has NO `amount` column (Texas's device), and
#   `wy_reconcile()` is what puts the halves back together.
#
#   THE OTHER TWO POOL LINES DO NAME A RECIPIENT AND ARE THEREFORE IN THE AWARD
#   FILE. Initiatives 2.1 and 2.3 are a sole-source master fiscal agent contract
#   with the WYOMING INNOVATION PARTNERSHIP, $38,618,260 -- Wyoming's largest
#   single recipient by far -- named by the minutes AND by the budget summary's
#   own Notes column. Missouri's Hub Anchors are the precedent that decides it:
#   they are OUT of Missouri's award file because DSS said they "will not act as
#   the fiscal agent", and WIP is IN because Wyoming's motion says it IS one.
#   It codes `PASS_THROUGH_UNRESOLVED` + `Unclear` -- New Hampshire's FHC and
#   NOT Illinois's ICAHN -- so it enters NEITHER bucket of the partition.
#
#   THE APPLICANTS WHO WERE NOT AWARDED. The document names them -- three late
#   1.1 submissions (all Banner Health, all EIN 94-2545356), nine 1.2
#   applicants, two 2.2, thirty-odd 3.1 and two 4.1 -- and Nebraska's lesson is
#   that reading an applicant roster as an award roster invents awards (§0.3).
#   `wy_assert_denied_not_awarded()` requires them ABSENT from the award file.
#
# Usage:
#   Rscript R/03aj_wy_year1_awardees.R --fetch [--force]
#   Rscript R/03aj_wy_year1_awardees.R --validate
#   Rscript R/03aj_wy_year1_awardees.R --build
#   Rscript R/03aj_wy_year1_awardees.R --probe
#   Rscript R/03aj_wy_year1_awardees.R --report

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_pdf_text.R"))
source(here::here("R", "utils_recipient_classification.R"))


# -- constants ----------------------------------------------------------------

WY_STATE          <- "WY"
WY_EVIDENCE_DIR   <- here::here("data", "evidence", "WY")
WY_OUT_CSV        <- here::here("data", "reference", "wy_year1_awardees.csv")
WY_STATUS_CSV     <- here::here("data", "reference", "wy_year1_status.csv")
WY_DISPOSITION_CSV<- here::here("data", "reference", "wy_rcj_candidate_disposition.csv")

# health.wyo.gov answers 200 to the project's honest agent and 403 to a bare
# Mozilla/5.0 -- the INVERSE of michigan.gov (§3). Identifying honestly is the
# fix here, as it is for medicaid.gov (session 10), and there is no exception to
# take.
WY_USER_AGENT     <- "Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; +https://www.aha.org)"
WY_HOST_THROTTLE_S <- 3

WY_ALLOTMENT        <- 205004743      # the §7.1 anchor, CMS's own table
WY_NOA_AMOUNT       <- 205004742.95   # CMS's own Notice of Award
WY_SUMMARY_TOTAL    <- 205004742      # WDH's budget summary `Total` row
WY_NOA_DATE         <- as.Date("2025-12-29")   # the §6.2 anchor: budget period start
WY_NOA_FEDERAL_DATE <- as.Date("2026-05-14")   # the NOA's own "Federal Award Date"
WY_APPROVAL_DATE    <- as.Date("2026-08-11")
WY_BUDGET_PERIOD    <- "Budget Period 1 (2025-12-29 to 2026-10-30)"
WY_OBLIGATION_DEADLINE <- "End of October 2026"

WY_SOURCES <- tibble::tribble(
  ~key,          ~file,                                                             ~url,
  "approvals",   "2026-09-03_wy_advisory_committee_award_approvals_2026-08-11.pdf",
  "https://drive.google.com/uc?export=download&id=1jqfbHzZPrX-_xT-uLg3TFXorckp3b3uX",
  "minutes",     "2026-09-03_wy_advisory_committee_minutes_2026-08-11.pdf",
  "https://drive.google.com/uc?export=download&id=1rx0ZDfGkPK2lG4L-W6aie9eXzU1t5pv2",
  "agenda",      "2026-09-03_wy_advisory_committee_agenda_2026-08-11.pdf",
  "https://drive.google.com/uc?export=download&id=16UYyAzM7WZUqW0Y7NKWrw2Zc85XmIF1O",
  "noa",         "2026-09-03_wy_cms_notice_of_award_2026-05-14.pdf",
  "https://drive.google.com/uc?export=download&id=1lGDh1Ndi_2ji1hwwsFFAyASUFAhk82ut",
  "narrative",   "2026-09-03_wy_revised_budget_narrative_2026-05-08.pdf",
  "https://drive.google.com/uc?export=download&id=1NFs2qS-q0QjeBOZ6TpbWwRF6H0YUNx-N",
  "programme",   "2026-09-03_wy_wdh_rhtp_programme.html",
  "https://health.wyo.gov/admin/rural-health-transformation-program/",
  "public_notice", "2026-09-03_wy_wdh_public_notice_advisory_committee_2026-08-11.html",
  "https://health.wyo.gov/public-notice-rural-health-transformation-advisory-committee-meeting/",
  "applications", "2026-09-03_wy_wdh_applications_opened_2026-07-01.html",
  "https://health.wyo.gov/applications-opened-july-1-for-wyomings-rural-health-transformation-funding/",
  "submittable", "2026-09-03_wy_submittable_no_open_calls.html",
  "https://wyrhtp.submittable.com/submit"
)

wy_path <- function(key) {
  hit <- WY_SOURCES$file[WY_SOURCES$key == key]
  if (length(hit) != 1L) stop("[WY] no source keyed ", key, call. = FALSE)
  file.path(WY_EVIDENCE_DIR, hit)
}
wy_url <- function(key) {
  hit <- WY_SOURCES$url[WY_SOURCES$key == key]
  if (length(hit) != 1L) stop("[WY] no source keyed ", key, call. = FALSE)
  hit
}

WY_PROGRAMME_URL <- "https://health.wyo.gov/admin/rural-health-transformation-program/"

wy_money <- function(x) {
  ifelse(is.na(x), "--",
         paste0("$", formatC(x, format = "f", digits = 2, big.mark = ",")))
}


# -- the run model ------------------------------------------------------------
#
# THE WHOLE PARSE RESTS ON `rhtp_pdf_runs()` AND THAT IS NOT A STYLE CHOICE.
# See the header. `wy_runs()` caches the run table for the session because the
# assertions read it a dozen times.

.wy_runs_cache <- new.env(parent = emptyenv())

#' The award-approvals PDF as painted RUNS, keyed on the VISUAL row
#'
#' `rhtp_pdf_runs()` returns `page, line, x, y, text`. This adds `yk`, the
#' rounded `y`, and THAT is the grouping key rather than `line` -- because six
#' of this document's rows carry their recipient name under a DIFFERENT line id
#' at the SAME y (see the header). Grouping by `line` is exactly the defect;
#' grouping by `y` is the fix.
wy_runs <- function(path = wy_path("approvals")) {
  key <- paste0("runs:", path)
  if (is.null(.wy_runs_cache[[key]])) {
    r <- rhtp_pdf_runs(path)
    r$yk <- round(r$y)
    .wy_runs_cache[[key]] <- r
  }
  .wy_runs_cache[[key]]
}

#' Cut one visual row into cells at fixed x boundaries
#'
#' @param runs The run table from `wy_runs()`.
#' @param page,yk The visual row.
#' @param bounds A tibble of `name`, `lo`, `hi`.
#' @return A named character vector, one entry per column, runs pasted in x
#'   order and then trimmed. PASTE FIRST, TRIM AFTER -- session 32 measured
#'   that runs are returned UNTRIMMED and that trimming each one first welds
#'   words together.
wy_cut_row <- function(runs, page, yk, bounds) {
  r <- runs[runs$page == page & runs$yk == yk, , drop = FALSE]
  r <- r[order(r$x), , drop = FALSE]
  out <- vapply(seq_len(nrow(bounds)), function(i) {
    sel <- r$x >= bounds$lo[i] & r$x < bounds$hi[i]
    trimws(paste0(r$text[sel], collapse = ""))
  }, character(1))
  names(out) <- bounds$name
  out
}

#' Build a column-boundary table from a named vector of left edges
wy_bounds <- function(...) {
  v <- c(...)
  tibble::tibble(name = names(v), lo = unname(v),
                 hi = c(unname(v)[-1], Inf))
}

#' Read one of the document's tables
wy_table <- function(page, y_from, y_to, bounds, path = wy_path("approvals")) {
  runs <- wy_runs(path)
  ys <- sort(unique(runs$yk[runs$page == page &
                              runs$yk >= y_from & runs$yk <= y_to]))
  out <- purrr::map_dfr(ys, function(y) {
    v <- wy_cut_row(runs, page, y, bounds)
    tibble::as_tibble(as.list(v))
  })
  out$page <- page
  out$y <- ys
  out
}

#' The leading currency figure of a cell, or NA
#'
#' Anchored at the START of the cell on purpose. Several cells in this document
#' are an amount followed immediately by wrapped note text from the column to
#' its right (the producer paints them within 10pt of each other), so an
#' unanchored search would find a figure quoted in a note -- "$1.7 procured via
#' competitive RFP", "$114,000.00 for the first year" -- and publish it as an
#' award.
wy_money_lead <- function(s) {
  m <- stringr::str_match(s, "^\\$([0-9][0-9,]*(?:\\.[0-9]{1,2})?)")[, 2]
  as.numeric(gsub(",", "", m))
}

#' A cell that is a currency figure AND NOTHING ELSE
wy_money_only <- function(s) {
  ok <- stringr::str_detect(s, "^\\$[0-9][0-9,]*(?:\\.[0-9]{1,2})?$")
  out <- rep(NA_real_, length(s))
  out[ok] <- as.numeric(gsub("[$,]", "", s[ok]))
  out
}


# -- the six recipient-level tables -------------------------------------------
#
# One entry per table: the page, the y band of its DATA rows (the header and any
# repeated header are outside it), the y of its own `Total:` row where it has
# one, and the x boundaries of its columns. The boundaries were hand-read off
# the painted glyph positions and are PROVED by `wy_assert_reconciles()`: a
# wrong boundary cannot close against six of the document's own totals, the
# budget summary and the allotment at once.
#
# `name_ein` IS ONE BAND ON PURPOSE. A long applicant name overflows its column
# into the EIN's in four of these tables, so there is no honest boundary between
# them; `split_name_ein()` separates them by regex instead. See the header.

WY_TABLES <- list(
  cah = list(
    initiative = "1.1 Critical Access Hospital - Basic",
    page = 2L, y_from = 932L, y_to = 1389L, total_y = 1389L,
    name_col = "name_ein",
    bounds = wy_bounds(name_ein = 0, score = 610, deliverable = 700,
                       swing_bed = 820, startup = 930, est_allowed = 1050,
                       excess_startup = 1140, excess_swing = 1255,
                       est_max = 1355, notes = 1435, recommendation = 1575,
                       recommended = 1700, approved = 1830,
                       approval_notes = 1920)
  ),
  ems = list(
    initiative = "1.2 EMS Regionalization",
    page = 3L, y_from = 899L, y_to = 1479L, total_y = 1479L,
    name_col = "name_ein",
    bounds = wy_bounds(name_ein = 0, score = 700, requested = 750,
                       recommended = 910, notes = 1010, approved = 1200,
                       approval_notes = 1290)
  ),
  gme = list(
    initiative = "2.2 Physician GME",
    page = 4L, y_from = 997L, y_to = 1262L, total_y = 1262L,
    name_col = "name_ein",
    bounds = wy_bounds(name_ein = 0, score = 630, requested = 700,
                       recommended = 860, notes = 960, approved = 1510,
                       approval_notes = 1615)
  ),
  primary_care = list(
    initiative = "4.1 Integrated Primary Care",
    page = 7L, y_from = 963L, y_to = 1861L, total_y = 1861L,
    name_col = "name_ein",
    bounds = wy_bounds(name_ein = 0, score = 690, requested = 755,
                       recommended = 905, notes = 1015, approved = 1533,
                       approval_notes = 1633)
  ),
  care_coordination = list(
    initiative = "4.2 Clinically-Integrated Care Coordination",
    page = 8L, y_from = 899L, y_to = 1403L, total_y = NA_integer_,
    name_col = "applicant",
    bounds = wy_bounds(county = 0, applicant = 380, duals = 800,
                       treatment = 1020, fixed = 1100, pmpm = 1180,
                       total = 1290)
  )
)

# 3.1 runs across TWO pages with its header REPEATED on the second, and its
# notes column overflows past x = 1700 there -- so its `approved` cell has to be
# read with `wy_money_only()` rather than `wy_money_lead()`, and its rows have
# to be taken from both pages. It also has NO approved total row: the document
# prints its total under "Recommended funding" and leaves the approved column's
# total blank, which is why `wy_assert_reconciles()` closes 3.1 against the
# RECOMMENDED total and the budget summary rather than against an approved one.
WY_TECH <- list(
  initiative = "3.1 Technology Adoption Challenge",
  pages = c(5L, 6L),
  y_from = c(917L, 113L), y_to = c(1987L, 1053L),
  total_page = 6L, total_y = 1053L,
  name_col = "applicant",
  bounds = wy_bounds(applicant = 0, requested = 520, match = 655, score = 740,
                     min_score = 795, round = 900, eligible_funding = 935,
                     recommended = 1140, notes = 1255, approved = 1700)
)

wy_read_table <- function(key) {
  spec <- WY_TABLES[[key]]
  t <- wy_table(spec$page, spec$y_from, spec$y_to, spec$bounds)
  t <- t[nzchar(t[[spec$name_col]]), , drop = FALSE]
  t$initiative <- spec$initiative
  t$table_key <- key
  t
}

wy_read_tech <- function() {
  spec <- WY_TECH
  t <- purrr::map_dfr(seq_along(spec$pages), function(i) {
    wy_table(spec$pages[i], spec$y_from[i], spec$y_to[i], spec$bounds)
  })
  t <- t[nzchar(t$applicant), , drop = FALSE]
  # The header is repeated on page 6 and its two rows land in the applicant
  # column as "Fu"/"Applicantre". They are dropped by requiring a requested
  # amount that is a currency figure and nothing else.
  t$requested_amount <- wy_money_only(t$requested)
  t$approved_amount  <- wy_money_only(t$approved)
  t <- t[!is.na(t$requested_amount) | t$applicant == "Total", , drop = FALSE]
  t$initiative <- spec$initiative
  t$table_key <- "tech"
  t
}


# -- the budget summary (Tier 2) ----------------------------------------------

WY_SUMMARY_BOUNDS <- wy_bounds(initiative = 0, original_budget = 500,
                               approved_award = 700, rest = 800)

#' WDH's own initiative-level budget summary -- SEVENTEEN LINES AND A TOTAL
#'
#' Tier 2 by construction (§0.2): these are pools, not awards, and they are NOT
#' in `wy_year1_awardees.csv`. They live in `wy_year1_status.csv`, whose amount
#' columns are named `initiative_*` precisely so that nothing summed out of it
#' can read as a per-recipient figure (Texas's device).
wy_budget_summary <- function() {
  t <- wy_table(1L, 900L, 1215L, WY_SUMMARY_BOUNDS)
  t <- t[nzchar(t$initiative), , drop = FALSE]
  t$original_budget_amount <- wy_money_lead(t$original_budget)
  t$approved_award_amount  <- wy_money_lead(t$approved_award)
  t$is_total <- t$initiative == "Total"
  t
}


# -- 1.1's recipient form is STATED BY WYOMING, and that moves dollars ---------
#
# THE SINGLE LARGEST CODING DECISION IN THIS FILE, AND IT IS SOURCE-BASED.
# The §8 name rule reaches 15 of 1.1's 18 approved hospitals and MISSES THREE --
# "Powell Valley Health Care Inc", "Cody Regional Health" and "Crook County
# Medical Services District", $7,525,331 between them -- because none of those
# names carries a hospital token.
#
# Wyoming states the form THREE TIMES, in two documents:
#   * the table's own first column is headed "Hospital";
#   * the initiative is "1.1. Critical Access Hospital - Basic";
#   * the Year 1 Revised Budget Narrative's "Wyoming Initiative Component:
#     Eligible Applicants" block for Initiative 1.1 gives one Facility Type,
#     "Critical Access Hospital (18 Total)", and nothing else.
#
# Leaving those three on §8's standing fallback would assert the form is
# UNDETERMINED where the state has stated it outright -- the one thing
# `RECIPIENT_TYPE_INFERRED`'s own note forbids, and session 38's UNC finding and
# session 39's MCO code are the two precedents for typing from the source
# instead. So all 21 of 1.1's rows are `HOSPITAL_OR_SYSTEM`, typed FROM THE
# SOURCE, at MEDIUM (§7 reserves HIGH for a CCN match, which this repository
# still cannot make -- blocker 5).
#
# THE ELIGIBLE CLASS IS ILLINOIS'S, NOT NEW HAMPSHIRE'S. Every possible
# recipient of 1.1 money is a hospital, so §0.3 has nothing to bite on and
# §10.2's `DIRECT` row applies row by row. That is ICAHN's class (hospitals
# only, `Yes`) and not FHC's (hospitals among others, `Unclear`) -- and here it
# does not even need §10.2's pass-through row, because the recipient IS the
# hospital in all 21 cases.
#
# AND THE TWO 18s ARE NOT THE SAME 18. The budget narrative names eighteen
# ELIGIBLE Critical Access Hospitals and the committee approved eighteen; three
# names differ in each direction (Weston, Community Hospital (Torrington) and
# Washakie Medical Center are eligible and unapproved; Sheridan Memorial
# Hospital, Crook County Medical Services District and Teton County Hospital
# District dba St. John's Health are approved and not on the eligible list).
# `wy_assert_two_different_eighteens()` pins that rather than letting the
# coincidence of count read as corroboration (§0.3: a plan is not an award).

WY_CAH_FORM_SOURCE <- paste(
  "Recipient form STATED BY WYOMING, not inferred from the name: the award",
  "table's first column is headed \"Hospital\", the initiative is",
  "\"1.1. Critical Access Hospital - Basic\", and the Year 1 Revised Budget",
  "Narrative's Eligible Applicants block for Initiative 1.1 gives one Facility",
  "Type -- \"Critical Access Hospital (18 Total)\". §8's name rule reaches only",
  "15 of the 18 approved; typing the other three from this pipeline's own",
  "knowledge would be the §0.4 failure, and leaving them on §8's standing",
  "fallback would assert the form is undetermined where the state has stated",
  "it (session 38's UNC precedent, session 39's MCO precedent)."
)

# The 1.2 rows whose recipient is an entity Wyoming ITSELF types as a hospital
# in table 1.1, JOINED ON THE EIN AND NEVER ON THE NAME. §2 forbids a machine
# resolving a fuzzy hospital name match; an EIN is an exact key from the same
# publisher in the same document, which is Georgia's application-number
# precedent (session 22, "joined on the application number, never the name").
WY_EMS_HOSPITAL_EINS_NOTE <- paste(
  "Recipient form taken from table 1.1 of the SAME document, joined on the",
  "EIN and never on the name: Wyoming's own Critical Access Hospital table",
  "carries this exact EIN under a column headed \"Hospital\". §0.3a judges the",
  "RECIPIENT and not the activity -- the activity here is EMS regionalization",
  "and the named lead agency is a hospital, which is Delaware's Beebe",
  "school-based health centre coded DIRECT, not Nebraska's school kitchen",
  "coded NON_HOSPITAL."
)

# 4.1's eligible class is stated by WDH's own disqualification of an applicant:
# "Entity is not an FQHC or a Tribally-run 638 clinic, and was therefore, not
# eligible." So every eligible 4.1 applicant is one or the other. WDH does not
# say WHICH per row and this file does not guess -- both codes are
# `NON_HOSPITAL`, so no dollar turns on it and nothing is promoted (§0.4).
WY_PRIMARY_CARE_CLASS <- paste(
  "Entity is not an FQHC or a Tribally-run 638 clinic, and was therefore, not",
  "eligible.")
WY_PRIMARY_CARE_FORM_SOURCE <- paste(
  "Recipient class STATED BY WDH in its own disqualification of an ineligible",
  "applicant -- \"Entity is not an FQHC or a Tribally-run 638 clinic, and was",
  "therefore, not eligible\" -- so every applicant WDH marked eligible is one",
  "or the other. WDH does not say WHICH per row and this file does not guess;",
  "`FQHC_OR_RHC` and `TRIBAL_ORG` are both NON_HOSPITAL, so no dollar turns on",
  "the distinction."
)

# 4.2's two tribal rows name NOBODY. The cell reads "No bidders, recommend sole
# source w Tribal provider", which is a SENTENCE and not an organisation --
# §6.1's `PROGRAM_NAME_AS_AWARDEE` hazard in a new costume, and the shared
# classifier types it `TRIBAL_ORG` at HIGH confidence if it is handed to it.
WY_NO_BIDDERS <- "No bidders, recommend sole source w Tribal provider"


# -- one long table across all six -------------------------------------------

#' Every row the six recipient-level tables carry, awarded or not
#'
#' Normalised onto one shape. `approved_amount` is NA on the rows Wyoming did
#' NOT approve -- the three late 1.1 submissions, the nine 1.2 applicants, the
#' two 2.2, the thirty-odd 3.1 and the two 4.1 -- and those rows are what
#' `wy_assert_denied_not_awarded()` requires to stay out of the award file
#' (Nebraska's lesson: an applicant roster read as an award roster invents
#' awards, §0.3).
wy_source_rows <- function() {
  # THE NAME AND THE EIN COME OUT OF ONE WIDE BAND, SPLIT BY REGEX, AND THAT IS
  # NOT A CONVENIENCE. Four of this document's tables let a long applicant name
  # OVERFLOW ITS COLUMN into the EIN's -- "North Lincoln County Hospital
  # District dba Star Valley Heal83-0327251Y" is one painted row -- so a fixed
  # boundary between the two either truncates the name or contaminates the
  # identifier, and it silently did BOTH before this was written: Star Valley's
  # 1.2 EIN came back NA, which is the exact key this file uses to carry
  # Wyoming's stated hospital form from Initiative 1.1 into Initiative 1.2.
  # The name is kept AS PAINTED, clipped by the producer at its own cell edge
  # (§8 -- keep the state's language, resolve nothing).
  split_name_ein <- function(x) {
    m <- stringr::str_match(
      x, "^(.*?)\\s*([0-9]{2}-[0-9]{7})\\s*([YN])?\\s*$")
    name <- ifelse(is.na(m[, 2]), trimws(x), trimws(m[, 2]))
    list(name = name, ein = m[, 3], eligibility = m[, 4])
  }

  cah <- wy_read_table("cah")
  cah <- cah[cah$name_ein != "Total", , drop = FALSE]
  cah_ein <- split_name_ein(cah$name_ein)
  cah_rows <- tibble::tibble(
    initiative = cah$initiative, table_key = "cah",
    awardee = cah_ein$name, ein = cah_ein$ein, eligibility = NA_character_,
    score = cah$score,
    requested_amount = wy_money_lead(cah$deliverable),
    recommended_amount = wy_money_lead(cah$recommended),
    approved_amount = wy_money_lead(cah$approved),
    notes = cah$notes, approval_notes = cah$approval_notes,
    county = NA_character_, page = cah$page, y = cah$y
  )
  # A denial prints "$0.00" in the approved column rather than leaving it empty;
  # a zero is not an award.
  cah_rows$approved_amount[cah_rows$approved_amount == 0] <- NA_real_

  ems <- wy_read_table("ems")
  ems <- ems[ems$name_ein != "Total", , drop = FALSE]
  ems_ein <- split_name_ein(ems$name_ein)
  ems_rows <- tibble::tibble(
    initiative = ems$initiative, table_key = "ems",
    awardee = ems_ein$name, ein = ems_ein$ein,
    eligibility = ems_ein$eligibility, score = ems$score,
    requested_amount = wy_money_lead(ems$requested),
    recommended_amount = wy_money_lead(ems$recommended),
    approved_amount = wy_money_lead(ems$approved),
    notes = ems$notes, approval_notes = ems$approval_notes,
    county = NA_character_, page = ems$page, y = ems$y
  )

  gme <- wy_read_table("gme")
  gme <- gme[gme$name_ein != "Total", , drop = FALSE]
  gme_split <- split_name_ein(gme$name_ein)
  gme$applicant <- gme_split$name
  gme$ein <- gme_split$ein
  gme$eligibility <- gme_split$eligibility
  # 2.2's applicant names WRAP over up to three visual rows; the EIN sits on the
  # last of them. The wrapped fragments are re-joined onto the row that carries
  # the money, in document order.
  gme <- wy_join_wrapped_names(gme, "applicant", "ein")
  gme_ein <- list(ein = gme$ein, eligibility = gme$eligibility)
  gme_rows <- tibble::tibble(
    initiative = gme$initiative, table_key = "gme",
    awardee = gme$applicant, ein = gme_ein$ein,
    eligibility = gme_ein$eligibility, score = gme$score,
    requested_amount = wy_money_lead(gme$requested),
    recommended_amount = wy_money_lead(gme$recommended),
    approved_amount = wy_money_lead(gme$approved),
    notes = gme$notes, approval_notes = gme$approval_notes,
    county = NA_character_, page = gme$page, y = gme$y
  )

  tech <- wy_read_tech()
  tech <- tech[tech$applicant != "Total", , drop = FALSE]
  tech_rows <- tibble::tibble(
    initiative = tech$initiative, table_key = "tech",
    awardee = tech$applicant, ein = NA_character_, eligibility = NA_character_,
    score = tech$score,
    requested_amount = tech$requested_amount,
    recommended_amount = wy_money_lead(tech$recommended),
    approved_amount = tech$approved_amount,
    notes = tech$notes, approval_notes = NA_character_,
    county = NA_character_, page = tech$page, y = tech$y
  )

  pc <- wy_read_table("primary_care")
  pc <- pc[pc$name_ein != "Total", , drop = FALSE]
  pc_ein <- split_name_ein(pc$name_ein)
  pc_rows <- tibble::tibble(
    initiative = pc$initiative, table_key = "primary_care",
    awardee = pc_ein$name, ein = pc_ein$ein, eligibility = pc_ein$eligibility,
    score = pc$score,
    requested_amount = wy_money_lead(pc$requested),
    recommended_amount = wy_money_lead(pc$recommended),
    approved_amount = wy_money_lead(pc$approved),
    notes = pc$notes, approval_notes = pc$approval_notes,
    county = NA_character_, page = pc$page, y = pc$y
  )

  cc <- wy_read_table("care_coordination")
  cc_rows <- tibble::tibble(
    initiative = cc$initiative, table_key = "care_coordination",
    awardee = cc$applicant, ein = NA_character_, eligibility = NA_character_,
    score = NA_character_,
    requested_amount = NA_real_,
    recommended_amount = wy_money_lead(cc$total),
    approved_amount = wy_money_lead(cc$total),
    notes = paste0("Fixed ", cc$fixed, "; PMPM ", cc$pmpm),
    approval_notes = NA_character_,
    county = cc$county, page = cc$page, y = cc$y
  )

  dplyr::bind_rows(cah_rows, ems_rows, gme_rows, tech_rows, pc_rows, cc_rows)
}

#' Re-join a wrapped applicant name onto the row that carries its money
#'
#' 2.2 and 4.1 wrap a long applicant name over two or three visual rows, and the
#' EIN and the money sit on the LAST of them. The earlier fragments are rows
#' with a name and nothing else. This walks the table in document order and
#' prefixes each such fragment onto the next row that has an identifier.
wy_join_wrapped_names <- function(t, name_col, id_col) {
  keep <- rep(TRUE, nrow(t))
  carry <- character(0)
  for (i in seq_len(nrow(t))) {
    has_id <- !is.na(t[[id_col]][i]) && nzchar(t[[id_col]][i])
    if (!has_id) {
      carry <- c(carry, t[[name_col]][i])
      keep[i] <- FALSE
    } else if (length(carry)) {
      t[[name_col]][i] <- paste(c(carry, t[[name_col]][i]), collapse = " ")
      carry <- character(0)
    }
  }
  if (length(carry)) {
    stop("[WY] a wrapped ", name_col, " fragment had no row to attach to: ",
         paste(carry, collapse = " | "), call. = FALSE)
  }
  t[keep, , drop = FALSE]
}


# -- the award rows -----------------------------------------------------------

#' Wyoming's 77 approved award actions, classified
#'
#' SEVENTY-FIVE come from the six recipient-level tables and TWO from the
#' MINUTES -- the sole-source master fiscal agent contract with the Wyoming
#' Innovation Partnership, $38,618,260, which is Wyoming's largest single
#' recipient. `award_source` tells them apart, and the reconciliation reads the
#' tables only.
#'
#' `sum(amount)` is $173,859,752 -- every approved dollar with a NAMED
#' recipient. The six tables' 75 rows sum to $135,241,492, which is NOT the
#' $135,508,492 those tables approve between them: 4.2's two tribal rows
#' ($164,700 + $102,300) name NOBODY, so their figures sit in `round_amount`
#' with `amount` empty (Oklahoma's ROOTS device, South Dakota's before it).
#'
#' And it is NOT Wyoming's Year 1 either: $30,877,990 more -- 15.1% -- is
#' approved at POOL level naming nobody at all.
wy_award_rows <- function() {
  src <- wy_source_rows()
  aw <- src[!is.na(src$approved_amount) & src$approved_amount > 0, , drop = FALSE]
  aw$award_source <- "APPROVALS_TABLE"
  admin <- wy_administrator_rows()
  admin$award_source <- "MINUTES_MOTION"
  aw <- dplyr::bind_rows(aw, admin)

  # -- §8 / §10.2, one table at a time, because Wyoming states the recipient's
  # -- form for some of them and not for others.
  cls <- rhtp_classify_recipient_type(aw$awardee, WY_STATE)
  aw$recipient_type <- cls$recipient_type
  aw$recipient_type_confidence <- cls$determination_confidence
  aw$recipient_type_source <- cls$recipient_type_basis
  aw$typed_from_source <- FALSE

  # (1) 1.1 -- Wyoming's own column is headed "Hospital". See the block above.
  is_cah <- aw$table_key == "cah"
  aw$recipient_type[is_cah] <- "HOSPITAL_OR_SYSTEM"
  aw$recipient_type_confidence[is_cah] <- "MEDIUM"
  aw$recipient_type_source[is_cah] <- WY_CAH_FORM_SOURCE
  aw$typed_from_source[is_cah] <- TRUE

  # (2) 1.2 -- an EMS lead agency that table 1.1 types as a hospital, joined on
  #     the EIN and never on the name (§2).
  cah_eins <- unique(stats::na.omit(src$ein[src$table_key == "cah"]))
  is_ems_hosp <- aw$table_key == "ems" & !is.na(aw$ein) & aw$ein %in% cah_eins
  aw$recipient_type[is_ems_hosp] <- "HOSPITAL_OR_SYSTEM"
  aw$recipient_type_confidence[is_ems_hosp] <- "MEDIUM"
  aw$recipient_type_source[is_ems_hosp] <- WY_EMS_HOSPITAL_EINS_NOTE
  aw$typed_from_source[is_ems_hosp] <- TRUE

  # (3) 4.1 -- WDH states the eligible class in its own disqualification.
  is_pc <- aw$table_key == "primary_care"
  aw$recipient_type[is_pc] <- "FQHC_OR_RHC"
  aw$recipient_type_confidence[is_pc] <- "MEDIUM"
  aw$recipient_type_source[is_pc] <- WY_PRIMARY_CARE_FORM_SOURCE
  aw$typed_from_source[is_pc] <- TRUE

  # (4) 4.2's two tribal rows NAME NOBODY. The cell is a sentence, and the
  #     shared classifier types it `TRIBAL_ORG` at HIGH if it is handed one --
  #     §6.1's programme-name-as-awardee hazard, and the reason this override is
  #     here rather than left to the classifier.
  is_unnamed <- aw$awardee == WY_NO_BIDDERS
  aw$recipient_type[is_unnamed] <- "NOT_YET_NAMED"
  aw$recipient_type_confidence[is_unnamed] <- "LOW"
  aw$recipient_type_source[is_unnamed] <- paste(
    "The cell is a SENTENCE and not an organisation --", shQuote(WY_NO_BIDDERS),
    "-- so no recipient is named (§6.1). The shared classifier types this",
    "string `TRIBAL_ORG` at HIGH confidence, which is exactly why it is",
    "overridden here rather than accepted.")
  aw$typed_from_source[is_unnamed] <- TRUE

  flow <- rhtp_classify_flow(aw$recipient_type, rep(NA_character_, nrow(aw)))
  aw$flow_type <- flow$flow_type
  aw$distributed_to_hospital <- flow$distributed_to_hospital
  aw$hospital_benefiting <- flow$hospital_benefiting
  aw$flow_basis <- flow$flow_basis

  # (5) The designated administrator. New Hampshire's FHC coding and NOT
  #     Illinois's ICAHN coding, because the eligible class is INDIVIDUALS AND
  #     INSTITUTIONS rather than hospitals only (§0.3).
  is_admin <- aw$award_source == "MINUTES_MOTION"
  aw$flow_type[is_admin] <- "PASS_THROUGH_UNRESOLVED"
  aw$distributed_to_hospital[is_admin] <- "Unclear"
  aw$hospital_benefiting[is_admin] <- NA_character_
  aw$flow_basis[is_admin] <- paste(
    "§10.2 PASS_THROUGH_UNRESOLVED. WIP is a DESIGNATED PASS-THROUGH",
    "ADMINISTRATOR -- Wyoming's minutes call it the \"master fiscal agent\" --",
    "and it has named no subrecipient. The eligible class is \"statewide",
    "individual and institutional workforce/nursing grants\": individuals and",
    "institutions, with no hospital named and no hospitals-only restriction.",
    "That is New Hampshire's FHC class (Unclear) and NOT Illinois's ICAHN",
    "class (Yes), so this row is in NEITHER bucket of the partition and",
    "$38,618,260 is hospital-bound on nobody's authority (§0.3).")
  aw$hospital_attribution <- rhtp_hospital_attribution(
    aw$flow_type, aw$distributed_to_hospital, aw$recipient_type)

  # -- The two rows that name nobody carry NO `amount` (§6.2, Oklahoma's ROOTS
  # -- device): their figure is in `round_amount` instead, so nothing summed out
  # -- of `amount` can read as money to a named recipient.
  amount <- aw$approved_amount
  amount[is_unnamed] <- NA_real_

  init_total <- wy_initiative_approved()
  pool <- init_total$approved[match(aw$initiative, init_total$initiative)]
  # The two administrator rows ARE their whole initiative, so their pool is
  # their own figure (Illinois's ICAHN row, which is also its own pool).
  pool[aw$award_source == "MINUTES_MOTION"] <-
    aw$approved_amount[aw$award_source == "MINUTES_MOTION"]
  round_amount <- pool
  round_amount[is_unnamed] <- aw$approved_amount[is_unnamed]

  condition <- wy_condition_text(aw)

  flag <- ifelse(is_unnamed,
                 "AMOUNT_PRELIMINARY;RECIPIENT_NOT_NAMED",
                 ifelse(aw$recipient_type_confidence == "LOW" &
                          aw$recipient_type == "NONPROFIT_CBO",
                        "AMOUNT_PRELIMINARY;RECIPIENT_TYPE_INFERRED",
                        "AMOUNT_PRELIMINARY"))

  out <- tibble::tibble(
    state = WY_STATE,
    row_no = seq_len(nrow(aw)),
    awardee = aw$awardee,
    amount = amount,
    recipient_type = aw$recipient_type,
    distributed_to_hospital = aw$distributed_to_hospital,
    note = paste0(
      "Initiative ", aw$initiative, ". ",
      "APPROVED BY THE RURAL HEALTH TRANSFORMATION ADVISORY COMMITTEE ON ",
      format(WY_APPROVAL_DATE), ", NOT EXECUTED: Wyoming's Year 1 obligation ",
      "deadline for executed contracts is ", WY_OBLIGATION_DEADLINE,
      " (the minutes' own words) and WDH's programme-page timeline gives ",
      "2026-10-01. `round_amount` is this INITIATIVE's approved pool and ",
      "repeats on every row of it -- never sum that column (Georgia's trap); ",
      "use wy_reconcile(). ",
      dplyr::if_else(nzchar(condition),
                     paste0("CONDITION AS PUBLISHED: ", condition, " "), ""),
      dplyr::if_else(is_unnamed,
                     paste("THIS ROW NAMES NOBODY: Wyoming allocated this",
                           "county's care-coordination budget and recorded",
                           "\"No bidders\", directing WDH to seek a voluntary",
                           "sole-source agreement with a Tribal provider. Its",
                           "`amount` is deliberately EMPTY and the figure is in",
                           "`round_amount` (§6.2)."), "")),
    recipient_confirmed = dplyr::if_else(is_unnamed, "No", "Yes"),
    amount_confirmed = "No",
    fiscal_year = 2026L,
    source_document_title = dplyr::if_else(
      aw$award_source == "MINUTES_MOTION",
      paste("Wyoming Rural Health Transformation Advisory Committee,",
            "Formal Meeting Minutes, August 11, 2026 (Initiatives 2.1 & 2.3),",
            "corroborated by the Award Approvals Budget Summary's own Notes",
            "column"),
      paste("Wyoming Rural Health Transformation Advisory Committee,",
            "Award Approvals - 8.11.26")),
    state_source_url = WY_PROGRAMME_URL,
    validation_source_type = "NOTICE_OF_INTENT_TO_AWARD",
    extraction_method = dplyr::if_else(
      aw$award_source == "MINUTES_MOTION", "PARSED_PDF_TEXT",
      "PARSED_PDF_RUNS"),
    validator = "R/03aj_wy_year1_awardees.R",
    ccn = NA_character_,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    recipient_type_source = aw$recipient_type_source,
    determination_confidence = dplyr::if_else(
      aw$recipient_type_confidence == "HIGH" & aw$distributed_to_hospital == "Yes",
      "MEDIUM", aw$recipient_type_confidence),
    flag_reason = flag,
    award_pool = aw$initiative,
    budget_period = WY_BUDGET_PERIOD,
    flow_type = aw$flow_type,
    hospital_benefiting = aw$hospital_benefiting,
    hospital_attribution = aw$hospital_attribution,
    intermediary_name = NA_character_,
    determination_basis = paste(aw$recipient_type_source, aw$flow_basis),
    amount_basis = paste(
      "The figure in the committee document's own APPROVED column for this",
      "row, read with session 32's run model. Six of this document's rows",
      "carry the recipient name in a SEPARATE PAINTED RUN from the rest of the",
      "row, so the line model splits them and loses $5,156,000 of Initiative",
      "1.1 in silence; the runs keep the name and the money together. Every",
      "table reconciles to the document's own Total row, to the budget",
      "summary's Approved award column, and thence to the $205,004,742",
      "allotment."),
    ein = aw$ein,
    score = aw$score,
    requested_amount = aw$requested_amount,
    recommended_amount = aw$recommended_amount,
    approval_condition = dplyr::if_else(nzchar(condition), condition,
                                        NA_character_),
    county = aw$county,
    round_amount = round_amount,
    award_source = aw$award_source,
    approval_date = as.character(WY_APPROVAL_DATE),
    source_archive_path = dplyr::if_else(
      aw$award_source == "MINUTES_MOTION",
      file.path("data/evidence/WY", basename(wy_path("minutes"))),
      file.path("data/evidence/WY", basename(wy_path("approvals"))))
  )
  out
}

#' Wyoming's TWO designated-administrator awards -- the Wyoming Innovation
#' Partnership, $38,618,260, from the MINUTES rather than from a table
#'
#' WHY THEY ARE HERE AND MISSOURI'S HUB ANCHORS ARE NOT. Missouri publishes a
#' named 27-organisation roster and it is NOT in its award file, because DSS's
#' own FAQ says the Hub Anchors "will not act as the fiscal agent". Wyoming's
#' motion says the opposite in the same words: WIP is the "master fiscal agent",
#' and a fiscal agent receives the money it administers. Two of Wyoming's own
#' documents name it against these two figures -- the minutes' motion and the
#' budget summary's own Notes column, "Sole-source contract with WIP".
#'
#' AND THEY CODE LIKE NEW HAMPSHIRE'S FHC, NOT LIKE ILLINOIS'S ICAHN, WHICH IS
#' THE WHOLE OF THE DIFFERENCE. ICAHN is `Yes` because Illinois restricted
#' eligibility to hospitals only, so every possible recipient is a hospital.
#' WIP administers "statewide individual and institutional workforce/nursing
#' grants" -- INDIVIDUALS and INSTITUTIONS, with no hospital named and no
#' hospitals-only class -- which is §0.3 exactly. So
#' `PASS_THROUGH_UNRESOLVED` + `Unclear`, in NEITHER bucket of the partition,
#' and $38,618,260 of Wyoming's Year 1 is hospital-bound on nobody's authority.
#'
#' They carry `award_source = "MINUTES_MOTION"` so they can never be mistaken
#' for rows of the six approval tables, which is what the reconciliation reads.
WY_ADMINISTRATOR <- "Wyoming Innovation Partnership (WIP)"

# The budget-summary line -> award_pool map, read by both the row builder and
# the status table so the two can never drift apart.
WY_ADMINISTRATOR_POOLS <- c(
  "2.1. Workforce education individual support" =
    "2.1 Workforce Education Individual Support",
  "2.3. Workforce education startup" =
    "2.3 Workforce Education Startup")

wy_administrator_rows <- function() {
  summary <- wy_budget_summary()
  hit <- summary[summary$initiative %in% WY_ADMINISTRATOR_SUMMARY_LINES, ,
                 drop = FALSE]
  if (nrow(hit) != 2L) {
    stop("[WY] the budget summary no longer carries both Workforce Education ",
         "lines.", call. = FALSE)
  }
  tibble::tibble(
    initiative = unname(WY_ADMINISTRATOR_POOLS[hit$initiative]),
    table_key = "administrator",
    awardee = WY_ADMINISTRATOR,
    ein = NA_character_,
    eligibility = NA_character_,
    score = NA_character_,
    requested_amount = NA_real_,
    recommended_amount = hit$approved_award_amount,
    approved_amount = hit$approved_award_amount,
    notes = "Sole-source contract with WIP",
    approval_notes = NA_character_,
    county = NA_character_,
    page = 1L,
    y = NA_integer_
  )
}

#' The condition Wyoming published against a row, where it published one
wy_condition_text <- function(aw) {
  txt <- trimws(paste(
    dplyr::coalesce(aw$notes, ""),
    dplyr::coalesce(aw$approval_notes, "")))
  txt <- stringr::str_squish(txt)
  # Keep only the sentences that state a CONDITION on the award. A note that
  # merely scores the application is not one.
  keep <- stringr::str_detect(
    txt, stringr::regex("condition|contingent|sustainability plan",
                        ignore_case = TRUE))
  ifelse(keep, txt, "")
}

#' The approved total per initiative, from the six tables themselves
wy_initiative_approved <- function() {
  src <- wy_source_rows()
  src %>%
    dplyr::filter(!is.na(.data$approved_amount), .data$approved_amount > 0) %>%
    dplyr::group_by(initiative = .data$initiative) %>%
    dplyr::summarise(approved = sum(.data$approved_amount),
                     rows = dplyr::n(), .groups = "drop")
}


# -- reading the other sources ------------------------------------------------

.wy_text_cache <- new.env(parent = emptyenv())

#' Reduce one of Wyoming's HTML sources to its text
#'
#' THE ELEVENTH ROTATING-DIGEST MECHANISM, AND THE FIRST THAT SURVIVES THE
#' REDUCTION. Measured, not inherited (session 34's California lesson):
#'
#'   * `health.wyo.gov` rotates SOMETHING on every request -- two fetches three
#'     seconds apart are 199,946 bytes each and hash differently -- so a FILE
#'     digest is useless as a change test, exactly as on dss.mo.gov,
#'     dhs.wisconsin.gov, portal.ct.gov and the rest. Tags are discarded here,
#'     so whatever that is, it is absorbed.
#'   * AND THE PROGRAMME PAGE CARRIES A SECOND ONE THAT TAG-STRIPPING CANNOT
#'     REACH. Its Gravity Forms contact form plants an ANTI-SPAM HONEYPOT whose
#'     FIELD LABEL is drawn at random per render, and that label is TEXT: one
#'     fetch reads "Email This field is for validation purposes and should be
#'     left unchanged." and the next reads "Name This field is for validation
#'     purposes...". Every earlier mechanism this project has met -- a nonce, a
#'     cache-buster, an asset-version stamp, a re-rolled mailto, a cache
#'     variant, a Dynatrace id, whitespace -- lived in an attribute or a script
#'     body and the reduction absorbed it for free. This one is in the rendered
#'     words, and the FIRST live probe reported the page CHANGED on it alone,
#'     one word out of 951, with nothing about Wyoming's programme changed.
#'
#' So the honeypot's label is normalised away by name. It is a form-field
#' label and never content, and the sentence after it is fixed boilerplate,
#' which is what makes the substitution safe to make.
wy_html_text <- function(x) {
  s <- if (length(x) == 1L && file.exists(x)) {
    paste(readLines(x, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  } else {
    paste(x, collapse = "\n")
  }
  s <- stringr::str_remove_all(
    s, stringr::regex("<(script|style|noscript)[^>]*>.*?</\\1>",
                      dotall = TRUE, ignore_case = TRUE))
  s <- stringr::str_remove_all(s, "<!--.*?-->")
  s <- stringr::str_replace_all(s, "<[^>]+>", " ")
  s <- stringr::str_replace_all(s, "&nbsp;?", " ")
  s <- stringr::str_replace_all(s, "&amp;", "&")
  s <- stringr::str_replace_all(s, "&#8217;|&rsquo;", "’")
  s <- stringr::str_replace_all(s, "&#8211;|&ndash;", "-")
  s <- stringr::str_squish(s)
  # The Gravity Forms honeypot label -- see above.
  stringr::str_replace_all(
    s, "\\S+ This field is for validation purposes and should be left unchanged\\.",
    "<HONEYPOT> This field is for validation purposes and should be left unchanged.")
}

#' The squished text of any archived Wyoming source, cached
wy_text <- function(key, body = NULL) {
  if (!is.null(body)) {
    return(if (grepl("\\.pdf$", wy_path(key))) stringr::str_squish(
      paste(body, collapse = " ")) else wy_html_text(body))
  }
  if (is.null(.wy_text_cache[[key]])) {
    p <- wy_path(key)
    .wy_text_cache[[key]] <- if (grepl("\\.pdf$", p)) {
      stringr::str_squish(paste(rhtp_pdf_text(p), collapse = " "))
    } else {
      wy_html_text(p)
    }
  }
  .wy_text_cache[[key]]
}

wy_content_digest <- function(key, body = NULL) {
  digest::digest(wy_text(key, body), algo = "sha256")
}


# -- reconciliation -----------------------------------------------------------

#' Wyoming's Year 1, put back together -- and NEVER by summing a column
#'
#' `round_amount` repeats an initiative's pool on every row of it, so summing
#' that column gives $2,177,412,637 for a state that approved $205,004,742
#' (Georgia's trap, Nevada's device). This sums DISTINCT initiatives instead,
#' and adds back the $69,496,250 approved at pool level against no recipient
#' table at all.
wy_reconcile <- function(rows = wy_award_rows()) {
  named <- rows %>%
    dplyr::group_by(initiative = .data$award_pool) %>%
    dplyr::summarise(
      rows = dplyr::n(),
      named_amount = sum(.data$amount, na.rm = TRUE),
      .groups = "drop")
  # THE POOL FIGURE COMES FROM THE INITIATIVE TOTAL AND NEVER FROM A ROW'S
  # `round_amount`, because two of Initiative 4.2's rows carry their OWN figure
  # there rather than the pool's -- the pair that name nobody.
  init <- wy_initiative_approved()
  named$approved <- init$approved[match(named$initiative, init$initiative)]
  # The two administrator initiatives have no approvals table, so their pool is
  # the row's own figure.
  admin <- rows %>%
    dplyr::filter(.data$award_source == "MINUTES_MOTION") %>%
    dplyr::select(initiative = "award_pool", amt = "amount")
  hit <- match(named$initiative, admin$initiative)
  named$approved[!is.na(hit)] <- admin$amt[hit[!is.na(hit)]]

  summary <- wy_budget_summary()
  unnamed <- summary %>%
    dplyr::filter(!.data$is_total,
                  !.data$initiative %in% wy_summary_keys_with_tables(),
                  !.data$initiative %in% WY_ADMINISTRATOR_SUMMARY_LINES) %>%
    dplyr::transmute(initiative = .data$initiative,
                     rows = 0L, named_amount = 0,
                     approved = .data$approved_award_amount)

  list(
    with_roster = named,
    without_roster = unnamed,
    named_total = sum(named$named_amount),
    roster_total = sum(named$approved),
    unnamed_total = sum(unnamed$approved),
    grand_total = sum(named$approved) + sum(unnamed$approved)
  )
}

#' Which budget-summary lines have a recipient-level table behind them
#'
#' Matched on the summary line's own leading initiative number, because the
#' summary spells an initiative differently from its own table -- "1.2. EMS
#' regionalization" against "1.2. Emergency Medical Services (EMS)", "3.1.
#' Technology adoption challenge" against "3.1. Technology challenge", "4.2.
#' Clinically-integrated care coordination" against "4.2. Clinical Care
#' Coordination". Matching on the words would silently pair nothing.
WY_SUMMARY_TABLE_LINES <- c(
  "1.1. Critical Access Hospital - Basic",
  "1.2. EMS regionalization",
  "2.2. Physician GME",
  "3.1. Technology adoption challenge",
  "4.1. Integrated primary care",
  "4.2. Clinically-integrated care coordination"
)
wy_summary_keys_with_tables <- function() WY_SUMMARY_TABLE_LINES

# THE TWO SUMMARY LINES THAT NAME A RECIPIENT WITHOUT A TABLE.
#
# Wyoming's minutes: "Motion passed to sole-source a master fiscal agent
# contract with the Wyoming Innovation Partnership (WIP) to administer
# statewide individual and institutional workforce/nursing grants for
# $35,424,820 (Initiative 2.1) and $3,193,440 (Initiative 2.3)." The budget
# summary's Notes column says the same thing twice -- "Sole-source contract with
# WIP" -- so TWO of Wyoming's own documents name this recipient against these
# two figures.
#
# THEY ARE AWARD ROWS, AND MISSOURI IS THE PRECEDENT THAT DECIDES IT. Missouri's
# 27 ToRCH Care Hub Anchors are NOT in its award file because DSS's own FAQ says
# they "will not act as the fiscal agent"; Wyoming's motion says WIP IS the
# master fiscal agent. A fiscal agent receives the money it administers. It is
# Illinois's ICAHN shape (a designated pass-through administrator holding a
# whole pool) and New Hampshire's FHC shape (approved by the governing body,
# named, priced, no subrecipient), and it CODES LIKE NEW HAMPSHIRE'S rather
# than Illinois's -- see `wy_administrator_rows()`.
WY_ADMINISTRATOR_SUMMARY_LINES <- c("2.1. Workforce education individual support",
                                    "2.3. Workforce education startup")

# The budget-summary line each recipient-level table answers to.
WY_TABLE_TO_SUMMARY <- c(
  "1.1 Critical Access Hospital - Basic"        = "1.1. Critical Access Hospital - Basic",
  "1.2 EMS Regionalization"                     = "1.2. EMS regionalization",
  "2.2 Physician GME"                           = "2.2. Physician GME",
  "3.1 Technology Adoption Challenge"           = "3.1. Technology adoption challenge",
  "4.1 Integrated Primary Care"                 = "4.1. Integrated primary care",
  "4.2 Clinically-Integrated Care Coordination" = "4.2. Clinically-integrated care coordination"
)


# -- assertions ---------------------------------------------------------------

#' THE RUN MODEL IS MANDATORY, AND THIS PRICES WHAT THE LINE MODEL LOSES
#'
#' Six visual rows of the award-approvals PDF carry the recipient name under a
#' DIFFERENT reader line id from the rest of the row -- two in Initiative 1.1
#' and four in 1.2. `rhtp_pdf_lines()` groups by that line id, so it emits the
#' name as one line and the whole rest of the row as another: a line-model
#' extractor reads 1.1 as SIXTEEN hospitals and $43,044,174 and orphans
#' $5,156,000 with nothing about the output looking wrong.
#'
#' This asserts that the line model STILL does that. It is the mirror of
#' Arkansas's `ar_assert_line_model_merges()` -- there the line model WELDS
#' three columns into one unparseable string, here it SPLITS one row into two --
#' and both exist for the same reason: so that a later session cannot
#' "simplify" the parse back to `rhtp_pdf_lines()` and get a quietly wrong
#' state (session 35's lesson).
WY_SPLIT_NAME_ROWS <- tibble::tribble(
  ~page, ~yk,   ~initiative,                            ~name_fragment,
  2L,    1037L, "1.1 Critical Access Hospital - Basic",  "North Lincoln County Hospital District dba Star Valley",
  2L,    1121L, "1.1 Critical Access Hospital - Basic",  "South Big Horn County Hospital District, DBA as Thre",
  3L,    1004L, "1.2 EMS Regionalization",               "North Lincoln County Hospital District dba Star Valley Heal",
  3L,    1046L, "1.2 EMS Regionalization",               "Campbell County Health (CCH) Emergency Medical Servic",
  3L,    1067L, "1.2 EMS Regionalization",               "The \"new\" EMS Department will consist of the Town of Pin",
  3L,    1152L, "1.2 EMS Regionalization",               "Shoshoni Ambulance License #236 leads. FCAG, a Wyom"
)
WY_LINE_MODEL_LOSS <- 5156000          # the two 1.1 rows: $2,500,000 + $2,656,000
WY_CAH_APPROVED    <- 48200174
WY_CAH_HOSPITALS   <- 18L

wy_assert_line_model_splits_names <- function() {
  runs <- wy_runs()
  for (i in seq_len(nrow(WY_SPLIT_NAME_ROWS))) {
    r <- WY_SPLIT_NAME_ROWS[i, ]
    here_runs <- runs[runs$page == r$page & runs$yk == r$yk, ]
    n_lines <- dplyr::n_distinct(here_runs$line)
    if (n_lines < 2L) {
      stop("[WY] page ", r$page, " y ", r$yk, " (", r$name_fragment, ") is no ",
           "longer painted as two runs. The whole reason this file uses ",
           "rhtp_pdf_runs() was that six rows are. Re-read the document ",
           "before changing the parser.", call. = FALSE)
    }
    name_line <- here_runs$line[which.min(here_runs$x)]
    money_line <- here_runs$line[here_runs$x > 700][1]
    if (identical(name_line, money_line)) {
      stop("[WY] page ", r$page, " y ", r$yk, ": the name and the money now ",
           "share a line id, so the line model would no longer drop this row's ",
           "recipient. Verify before relaxing anything.", call. = FALSE)
    }
  }

  # AND PRICE IT. A line-model read of Initiative 1.1 -- one composed line per
  # row, the recipient name at the left, the money welded to its right -- keeps
  # only the rows whose name and money share a line id. It recovers NINETEEN of
  # the twenty-one applicants (18 approved + 3 denied, less the two split rows),
  # so SIXTEEN of the eighteen approved hospitals, and the two it loses are
  # worth $2,500,000 and $2,656,000. Nothing about that output looks wrong: the
  # two rows still exist, with no name on them.
  lines <- rhtp_pdf_lines(wy_path("approvals"))
  named <- lines[lines$page == 2L & lines$x < 300 &
                   stringr::str_detect(lines$text, "\\$[0-9]") &
                   !stringr::str_starts(lines$text, "Total"), ]
  orphan <- lines[lines$page == 2L & lines$x >= 300 &
                    stringr::str_detect(lines$text, "^[0-9]{2}-[0-9]{7}"), ]
  if (nrow(named) != 19L || nrow(orphan) != 2L) {
    stop("[WY] the line model now recovers ", nrow(named), " named Initiative ",
         "1.1 rows and orphans ", nrow(orphan), "; it recovered 19 and ",
         "orphaned 2 when this was written. If the reader has changed, ",
         "re-derive WY_LINE_MODEL_LOSS before touching anything else.",
         call. = FALSE)
  }
  # What those two rows are worth is a fact about the rows, so it is taken from
  # the CORRECT parse and then checked against the orphaned lines' own EINs --
  # which is the only identifier the line model leaves attached to them.
  src <- wy_source_rows()
  split_11 <- src[src$table_key == "cah" &
                    src$y %in% WY_SPLIT_NAME_ROWS$yk[WY_SPLIT_NAME_ROWS$page == 2L], ]
  lost <- sum(split_11$approved_amount, na.rm = TRUE)
  orphan_eins <- stringr::str_extract(orphan$text, "^[0-9]{2}-[0-9]{7}")
  if (!setequal(orphan_eins, split_11$ein)) {
    stop("[WY] the rows the line model orphans (", paste(orphan_eins, collapse = ", "),
         ") are not the rows the run model finds split (",
         paste(split_11$ein, collapse = ", "), ").", call. = FALSE)
  }
  if (!isTRUE(all.equal(lost, WY_LINE_MODEL_LOSS))) {
    stop("[WY] the two rows the line model orphans are now worth ",
         wy_money(lost), ", not ", wy_money(WY_LINE_MODEL_LOSS), ".",
         call. = FALSE)
  }
  if (!isTRUE(all.equal(WY_CAH_APPROVED - lost, 43044174))) {
    stop("[WY] a line-model read of Initiative 1.1 no longer yields ",
         "$43,044,174. Re-derive before changing anything.", call. = FALSE)
  }
  # The rows it DOES recover still weld the name to the EIN
  # ("Memorial Hospital of Converse County (MHCC)83-6000097..."), so the run
  # model is what separates them even there.
  if (!any(stringr::str_detect(named$text, "Hospital[^ ]*[0-9]{2}-[0-9]{7}"))) {
    stop("[WY] the line model no longer welds the recipient name to the EIN. ",
         "Re-read the document.", call. = FALSE)
  }
  n_recovered <- nrow(named)
  invisible(list(loss = WY_LINE_MODEL_LOSS, recovered_rows = n_recovered))
}

#' Every table closes against its own total, the budget summary and the anchor
wy_assert_reconciles <- function() {
  runs <- wy_runs()

  # (a) each table against ITS OWN `Total:` row
  totals <- list()
  for (key in names(WY_TABLES)) {
    spec <- WY_TABLES[[key]]
    if (is.na(spec$total_y)) next
    v <- wy_cut_row(runs, spec$page, spec$total_y, spec$bounds)
    col <- if (key == "care_coordination") "total" else "approved"
    totals[[spec$initiative]] <- wy_money_lead(v[[col]])
  }
  init <- wy_initiative_approved()
  for (nm in names(totals)) {
    got <- init$approved[init$initiative == nm]
    if (length(got) != 1L || !isTRUE(all.equal(got, totals[[nm]]))) {
      stop("[WY] ", nm, " sums to ", wy_money(got), " against the document's ",
           "own Total row of ", wy_money(totals[[nm]]), ".", call. = FALSE)
    }
  }

  # (b) 3.1 has NO approved total. The document prints its total under
  #     "Recommended funding" and leaves the approved column blank, so 3.1 is
  #     closed against THAT and against the budget summary.
  tech_total <- wy_cut_row(runs, WY_TECH$total_page, WY_TECH$total_y,
                           WY_TECH$bounds)
  tech_recommended <- wy_money_lead(tech_total[["recommended"]])
  tech_got <- init$approved[init$initiative == WY_TECH$initiative]
  if (!isTRUE(all.equal(tech_got, tech_recommended))) {
    stop("[WY] 3.1 sums to ", wy_money(tech_got), " against the document's own ",
         "recommended total of ", wy_money(tech_recommended), ".", call. = FALSE)
  }

  # (c) every table against the budget summary's Approved award column
  summary <- wy_budget_summary()
  for (nm in init$initiative) {
    line <- WY_TABLE_TO_SUMMARY[[nm]]
    want <- summary$approved_award_amount[summary$initiative == line]
    got <- init$approved[init$initiative == nm]
    if (length(want) != 1L || abs(want - got) > 1) {
      stop("[WY] ", nm, " sums to ", wy_money(got), " against the budget ",
           "summary's ", wy_money(want), " for \"", line, "\".", call. = FALSE)
    }
  }

  # (d) the budget summary against ITS OWN Total row, and against §7.1
  body <- summary[!summary$is_total, ]
  tot <- summary$approved_award_amount[summary$is_total]
  if (!isTRUE(all.equal(sum(body$approved_award_amount), tot))) {
    stop("[WY] the budget summary's fifteen lines sum to ",
         wy_money(sum(body$approved_award_amount)), " against its own Total of ",
         wy_money(tot), ".", call. = FALSE)
  }
  if (!identical(as.integer(tot), as.integer(WY_SUMMARY_TOTAL))) {
    stop("[WY] the budget summary Total is ", wy_money(tot), ", not ",
         wy_money(WY_SUMMARY_TOTAL), ".", call. = FALSE)
  }
  # §7.1's anchor is $205,004,743 and CMS's own NOA is $205,004,742.95: WDH
  # floors, CMS's table rounds. Three figures, one dollar apart, ALL PINNED and
  # NONE corrected (§8).
  if (abs(WY_ALLOTMENT - tot) > 1) {
    stop("[WY] the budget summary Total ", wy_money(tot), " is more than a ",
         "dollar from the §7.1 anchor ", wy_money(WY_ALLOTMENT), ".",
         call. = FALSE)
  }
  invisible(list(per_initiative = init, summary_total = tot))
}


#' §6.2 -- the CMS footer is the STRONG form AND its figure is the ALLOTMENT
#'
#' Session 27's axis says Wyoming's footer is programme-scoped, which is the
#' strong form: "Wyoming's Rural Health Transformation Program is supported by
#' ...". Session 37's Iowa rule says that answers PROVENANCE and not TIER, and
#' the tier here is Tier 1 -- $205,004,742.95 IS the allotment (§0.2). So it is
#' declared `STATE_ALLOTMENT` and checked by the machine rule, which refuses a
#' `SOLICITATION` declaration within $10,000 of the anchor AND refuses a
#' `STATE_ALLOTMENT` declaration that stops colliding.
#'
#' It is DEMOTED as provenance anyway, and on the better of the two grounds
#' available: Wyoming publishes CMS's OWN NOTICE OF AWARD, which is better
#' evidence than any footer quoting it (California's demotion, session 34).
wy_assert_footer_is_the_allotment <- function() {
  txt <- wy_text("programme")
  if (!stringr::str_detect(txt, stringr::fixed(
    "Rural Health Transformation Program is supported by the Centers for Medicare"))) {
    stop("[WY] the programme page no longer carries the programme-scoped CMS ",
         "footer. Re-read it before relying on §6.2 here.", call. = FALSE)
  }
  if (!stringr::str_detect(txt, stringr::fixed(
    "financial assistance award totaling $205,004,742.95 in Budget Period 1"))) {
    stop("[WY] the CMS footer no longer states $205,004,742.95.", call. = FALSE)
  }
  rhtp_assert_footer_not_allotment(
    amount = WY_NOA_AMOUNT, state = WY_STATE, declared_tier = "STATE_ALLOTMENT",
    label = "the health.wyo.gov CMS financial-assistance footer")
}

#' The provenance is CMS's OWN NOTICE OF AWARD -- the FIFTH state to publish one
#'
#' And the header is read on its own, because session 37 caught a false positive
#' the other way: every NOA's terms instruct the recipient to "utilize Revision
#' (Budget) amendment type", so a whole-document search reports every NOA as a
#' revision. Wyoming's IS one, and that is read from the header block.
wy_assert_noa <- function() {
  lines <- rhtp_pdf_text(wy_path("noa"))
  head_txt <- stringr::str_squish(paste(head(lines, 120), collapse = " "))
  want <- c("Notice of Award", "RHTCMS332082-01-02", "93.798",
            "Rural Health Transformation Program", "Revision (Budget)",
            "12/29/2025", "10/30/2026", "05/14/2026", "$205,004,742.95")
  for (w in want) {
    if (!stringr::str_detect(head_txt, stringr::fixed(w))) {
      stop("[WY] CMS's Notice of Award header no longer carries ", shQuote(w),
           ".", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' The §6.2 date test, and session 36's pin holding a FIFTH time
#'
#' The anchor is the BUDGET PERIOD START (2025-12-29), not the NOA's "Federal
#' Award Date" -- which on Wyoming's document is 05/14/2026, 136 days later,
#' because the document is a "Revision (Budget)". Nevada was +52, California
#' +92, Connecticut +206, Kentucky +0 on an ORIGINAL. Keying the test on the
#' later field would read every Wyoming award as late; keying it on the budget
#' period start is what session 36 defended and this is the fifth state to test
#' it. The minutes corroborate the later date from the other side, in Wyoming's
#' own words: "Wyoming executed its formal agreement with CMS on May 14, 2026."
wy_assert_after_noa <- function() {
  if (WY_APPROVAL_DATE <= WY_NOA_DATE) {
    stop("[WY] the award approvals are dated on or before the Notice of Award.",
         call. = FALSE)
  }
  if (WY_APPROVAL_DATE <= WY_NOA_FEDERAL_DATE) {
    stop("[WY] the award approvals predate even the NOA's Federal Award Date.",
         call. = FALSE)
  }
  m <- wy_text("minutes")
  if (!stringr::str_detect(m, stringr::fixed(
    "Wyoming executed its formal agreement with CMS on May 14, 2026"))) {
    stop("[WY] the minutes no longer state the 2026-05-14 execution date.",
         call. = FALSE)
  }
  gap <- as.integer(WY_NOA_FEDERAL_DATE - WY_NOA_DATE)
  if (gap != 136L) {
    stop("[WY] the Federal Award Date is now ", gap, " days after the budget ",
         "period start, not 136. Re-read session 36 before changing the anchor.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' EVERY ROW IS A COMMITTEE APPROVAL, NOT AN EXECUTED AGREEMENT
#'
#' Two publishers say so and they do not agree on the day: the minutes give
#' "Year 1 Obligation Deadline: End of October 2026 (executed
#' contracts/agreements)" and WDH's own programme-page timeline gives "October
#' 1, 2026: Contract execution deadline". Both are Wyoming's; neither is
#' corrected (§8). What matters for the coding is that both are in the FUTURE of
#' the approvals, so `NOTICE_OF_INTENT_TO_AWARD` + `amount_confirmed = No` is
#' the only honest posture, and this assertion is DESIGNED TO FAIL the day
#' Wyoming publishes executed agreements -- at which point this file must be
#' REWRITTEN, not patched.
wy_assert_intent_not_award <- function(rows = NULL) {
  m <- wy_text("minutes")
  if (!stringr::str_detect(m, stringr::fixed(
    "Year 1 Obligation Deadline: End of October 2026"))) {
    stop("[WY] the minutes no longer state the obligation deadline. If Wyoming ",
         "has executed its agreements, this file must be REWRITTEN rather than ",
         "patched: its rows are intents.", call. = FALSE)
  }
  if (!stringr::str_detect(wy_text("programme"), stringr::fixed(
    "October 1, 2026: Contract execution deadline"))) {
    stop("[WY] WDH's timeline no longer carries the contract execution ",
         "deadline.", call. = FALSE)
  }
  if (is.null(rows)) rows <- wy_award_rows()
  if (!all(rows$validation_source_type == "NOTICE_OF_INTENT_TO_AWARD") ||
      !all(rows$amount_confirmed == "No") ||
      !all(stringr::str_detect(rows$flag_reason, "AMOUNT_PRELIMINARY"))) {
    stop("[WY] a row has been promoted above an intent to award.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The minutes are a SECOND READING of the same numbers -- and disagree once
#'
#' Six motions, six figures, and five of them match the tables to the dollar.
#' The sixth does not: the minutes give University of Utah $9,225,398 where the
#' GME table gives $9,255,398.00, and it is the TABLE'S figure that sums to the
#' $17,712,410 both documents state. NOTHING IS CORRECTED (§8) -- both figures
#' are pinned here, and the arithmetic is what says which one the initiative
#' total was built from.
WY_UTAH_TABLE   <- 9255398.00
WY_UTAH_MINUTES <- 9225398
wy_assert_minutes_corroborate <- function() {
  m <- wy_text("minutes")
  init <- wy_initiative_approved()
  pairs <- c(
    "1.2 EMS Regionalization" = NA,     # the minutes give it in two motions
    "2.2 Physician GME" = "$17,712,410",
    "3.1 Technology Adoption Challenge" = "$12,652,243",
    "4.2 Clinically-Integrated Care Coordination" = "$3,218,160"
  )
  for (nm in names(pairs)) {
    if (is.na(pairs[[nm]])) next
    if (!stringr::str_detect(m, stringr::fixed(pairs[[nm]]))) {
      stop("[WY] the minutes no longer state ", pairs[[nm]], " for ", nm, ".",
           call. = FALSE)
    }
    got <- init$approved[init$initiative == nm]
    want <- as.numeric(gsub("[$,]", "", pairs[[nm]]))
    if (!isTRUE(all.equal(got, want))) {
      stop("[WY] ", nm, " sums to ", wy_money(got), " against the minutes' ",
           pairs[[nm]], ".", call. = FALSE)
    }
  }

  # The one disagreement, pinned from both sides.
  if (!stringr::str_detect(m, stringr::fixed("University of Utah: $9,225,398"))) {
    stop("[WY] the minutes no longer print University of Utah at $9,225,398.",
         call. = FALSE)
  }
  src <- wy_source_rows()
  utah <- src$approved_amount[src$table_key == "gme" &
                                stringr::str_detect(src$awardee, "University of Utah")]
  if (length(utah) != 1L || !isTRUE(all.equal(utah, WY_UTAH_TABLE))) {
    stop("[WY] the GME table no longer prints University of Utah at ",
         wy_money(WY_UTAH_TABLE), ".", call. = FALSE)
  }
  gme_total <- init$approved[init$initiative == "2.2 Physician GME"]
  minutes_sum <- WY_UTAH_MINUTES + 6263043.10 + 2193968.90
  if (isTRUE(all.equal(minutes_sum, gme_total))) {
    stop("[WY] the minutes' three GME figures now sum to the stated total; ",
         "the discrepancy this assertion exists to record has gone.",
         call. = FALSE)
  }
  invisible(list(table = WY_UTAH_TABLE, minutes = WY_UTAH_MINUTES,
                 minutes_sum = minutes_sum, table_sum = gme_total))
}

#' THE TWO 18s ARE NOT THE SAME 18, AND THE COINCIDENCE MUST NOT READ AS PROOF
#'
#' The Year 1 Revised Budget Narrative names EIGHTEEN eligible Critical Access
#' Hospitals for Initiative 1.1; the committee approved EIGHTEEN. Three names
#' differ in each direction. §0.3: a plan is not an award, and an eligibility
#' list is not a roster of recipients.
WY_ELIGIBLE_NOT_APPROVED <- c("Weston", "Community Hospital (Torrington)",
                              "Washakie Medical Center")
WY_APPROVED_NOT_ELIGIBLE <- c("Sheridan Memorial Hospital",
                              "Crook County Medical Services District",
                              "Teton County Hospital District dba St. John")
wy_assert_two_different_eighteens <- function() {
  n <- wy_text("narrative")
  block <- stringr::str_match(
    n, "Critical Access Hospital \\(18 Total\\)(.*?)Rural Health Transformation in Wyoming")[, 2]
  if (is.na(block)) {
    stop("[WY] the budget narrative's Initiative 1.1 Eligible Applicants block ",
         "is no longer readable.", call. = FALSE)
  }
  rows <- wy_award_rows()
  cah <- rows$awardee[rows$award_pool == "1.1 Critical Access Hospital - Basic"]
  if (length(cah) != WY_CAH_HOSPITALS) {
    stop("[WY] Initiative 1.1 now approves ", length(cah), " hospitals, not ",
         WY_CAH_HOSPITALS, ".", call. = FALSE)
  }
  for (nm in WY_ELIGIBLE_NOT_APPROVED) {
    if (!stringr::str_detect(block, stringr::fixed(nm))) {
      stop("[WY] ", shQuote(nm), " is no longer on the narrative's eligible ",
           "list.", call. = FALSE)
    }
    if (any(stringr::str_detect(cah, stringr::fixed(
      stringr::str_extract(nm, "^[A-Za-z]+"))))) {
      stop("[WY] ", shQuote(nm), " now appears among the approved. The two 18s ",
           "have moved; re-derive them.", call. = FALSE)
    }
  }
  for (nm in WY_APPROVED_NOT_ELIGIBLE) {
    if (!any(stringr::str_detect(cah, stringr::fixed(nm)))) {
      stop("[WY] ", shQuote(nm), " is no longer among the approved.",
           call. = FALSE)
    }
    key <- stringr::str_extract(nm, "^[A-Za-z]+")
    if (stringr::str_detect(block, stringr::fixed(key))) {
      stop("[WY] ", shQuote(key), " now appears on the narrative's eligible ",
           "list, so the two 18s may have converged. Re-read both.",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' 1.1's ELIGIBLE CLASS IS HOSPITALS ONLY -- ILLINOIS'S ANSWER, NOT FHC'S
#'
#' ICAHN is `Yes` because Illinois restricted eligibility to hospitals only, so
#' every possible recipient of the money is a hospital; FHC is `Unclear`
#' because its class is hospitals AMONG OTHERS (§0.3). Wyoming's Initiative 1.1
#' is Illinois's class -- the narrative gives ONE Facility Type for it,
#' "Critical Access Hospital" -- and here it does not even need §10.2's
#' pass-through row, because in all 21 cases the recipient IS the hospital and
#' §10.2's `DIRECT` row applies directly.
#'
#' 1.2 IS NOT THAT CLASS and the same narrative says so: its eligible list is
#' 44 "EMS Agency (Ground)" providers, several of them hospital-operated. Its
#' hospital rows are hospital rows because the NAMED LEAD AGENCY is a hospital
#' (§0.3a judges the recipient, not the activity), not because the class is.
wy_assert_eligible_classes <- function() {
  n <- wy_text("narrative")
  if (!stringr::str_detect(n, stringr::fixed(
    "INITIATIVE 1.1: Critical Access Hospital - Basic Facility TypeFacility Names Critical Access Hospital"))) {
    stop("[WY] the narrative no longer gives Initiative 1.1 a single Facility ",
         "Type of Critical Access Hospital. Its eligible class is what makes ",
         "this Illinois's answer rather than New Hampshire's -- re-read it ",
         "before coding any Wyoming pass-through.", call. = FALSE)
  }
  if (!stringr::str_detect(n, stringr::fixed(
    "INITIATIVE 1.2: EMS Regionalization Provider TypeProvider Names EMS Agency (Ground)"))) {
    stop("[WY] the narrative no longer gives Initiative 1.2 an EMS provider ",
         "class.", call. = FALSE)
  }
  if (!stringr::str_detect(wy_text("approvals"), stringr::fixed(WY_PRIMARY_CARE_CLASS))) {
    stop("[WY] the award document no longer carries WDH's own statement of ",
         "Initiative 4.1's eligible class.", call. = FALSE)
  }
  invisible(TRUE)
}


#' THE APPLICANTS WYOMING DID NOT AWARD STAY OUT OF THE AWARD FILE
#'
#' Nebraska's lesson, and Wyoming is the largest instance of it in this
#' repository: the award-approvals document names FIFTY-SIX applicants it did
#' not award, and FORTY of them are Initiative 3.1's, requesting $38,794,342
#' between them -- MOSTLY NAMED WYOMING HOSPITALS. Sheridan Memorial Hospital
#' appears four times, Memorial Hospital of Converse County three, Memorial
#' Hospital of Laramie County three, Powell Valley three, Memorial Hospital of
#' Carbon County twice, Riverton Memorial twice, plus Ivinson Memorial, North
#' Big Horn, Niobrara County, Sweetwater County and South Big Horn. A reader who
#' took 3.1's table for a roster would publish roughly $38.8M of APPLICATIONS as
#' Wyoming hospital awards, on the awarding body's own document (§0.3).
#'
#' The check is on the (table, name) PAIR and not the name, because two of the
#' unawarded applicants are hospitals Wyoming awarded under a DIFFERENT
#' initiative -- Memorial Hospital of Converse County holds $3,058,000 under
#' 1.1 and $2,200,000 under 1.2 while being turned down under 2.2 and 3.1.
WY_DENIED_PAIRS <- tibble::tribble(
  ~table_key, ~awardee,                            ~why,
  "cah",  "Torrington Community Hospital",  "Late submission (Banner Health, EIN 94-2545356)",
  "cah",  "Washakie Medical Center",        "Late submission (Banner Health, EIN 94-2545356)",
  "cah",  "Platte County Hospital",         "Late submission (Banner Health, EIN 94-2545356)",
  "ems",  "Casper Fire-EMS",                "Withdrew application",
  "ems",  "South Lincoln EMS",              "Sole applicant -- not eligible for direct Year 1 funding",
  "gme",  "Powell Valley Health Care Inc.", "Newly formed GME Council hosted by CRMC will provide this service",
  "gme",  "Memorial Hospital of Converse County", "Newly formed GME Council hosted by CRMC will provide this service",
  "tech", "Ivinson Memorial Hospital",      "Did not reach the funded round",
  "primary_care", "Teton County Health Departmnet", "Not an FQHC or a Tribally-run 638 clinic"
)
WY_UNAWARDED_TOTAL <- 56L
WY_TECH_UNAWARDED_REQUESTED <- 38794342

wy_assert_denied_not_awarded <- function(rows = NULL) {
  src <- wy_source_rows()
  if (is.null(rows)) rows <- wy_award_rows()
  unawarded <- src[is.na(src$approved_amount), , drop = FALSE]
  if (nrow(unawarded) != WY_UNAWARDED_TOTAL) {
    stop("[WY] the document now names ", nrow(unawarded), " unawarded ",
         "applicants, not ", WY_UNAWARDED_TOTAL, ". Re-read it: an applicant ",
         "roster read as an award roster invents awards (§0.3).", call. = FALSE)
  }
  awarded_pairs <- paste(rows$award_pool, rows$awardee, sep = " || ")
  for (i in seq_len(nrow(WY_DENIED_PAIRS))) {
    d <- WY_DENIED_PAIRS[i, ]
    hit <- src[src$table_key == d$table_key &
                 src$awardee == d$awardee, , drop = FALSE]
    if (nrow(hit) == 0L) {
      stop("[WY] ", shQuote(d$awardee), " is no longer in table ", d$table_key,
           ".", call. = FALSE)
    }
    if (any(!is.na(hit$approved_amount))) {
      stop("[WY] ", shQuote(d$awardee), " now carries an approved amount under ",
           d$table_key, " (", d$why, "). If Wyoming has awarded it, this file ",
           "must be REBUILT rather than have a row added.", call. = FALSE)
    }
    init <- unique(hit$initiative)
    if (any(paste(init, d$awardee, sep = " || ") %in% awarded_pairs)) {
      stop("[WY] ", shQuote(d$awardee), " has appeared in the award file under ",
           init, ".", call. = FALSE)
    }
  }
  tech_req <- sum(src$requested_amount[is.na(src$approved_amount) &
                                         src$table_key == "tech"], na.rm = TRUE)
  if (abs(tech_req - WY_TECH_UNAWARDED_REQUESTED) > 1) {
    stop("[WY] Initiative 3.1's unawarded applicants now request ",
         wy_money(tech_req), ", not ", wy_money(WY_TECH_UNAWARDED_REQUESTED),
         ".", call. = FALSE)
  }
  invisible(list(unawarded = nrow(unawarded), tech_requested = tech_req))
}

#' `round_amount` REPEATS AN INITIATIVE'S POOL AND MUST NEVER BE SUMMED
wy_assert_round_amount_not_summable <- function(rows = NULL) {
  if (is.null(rows)) rows <- wy_award_rows()
  naive <- sum(rows$round_amount, na.rm = TRUE)
  rec <- wy_reconcile(rows)
  if (naive <= rec$roster_total) {
    stop("[WY] summing `round_amount` no longer over-states the state, which ",
         "means the column has changed shape. Re-read it before relying on ",
         "wy_reconcile().", call. = FALSE)
  }
  if (abs(rec$grand_total - WY_SUMMARY_TOTAL) > 1) {
    stop("[WY] wy_reconcile() puts Wyoming at ", wy_money(rec$grand_total),
         " against the budget summary's ", wy_money(WY_SUMMARY_TOTAL), ".",
         call. = FALSE)
  }
  invisible(list(naive = naive, correct = rec$grand_total))
}

#' THE TWO ROWS THAT NAME NOBODY CARRY NO `amount`
#'
#' Wyoming allocated Northern Arapaho $164,700 and Eastern Shoshone $102,300 of
#' care-coordination budget and recorded "No bidders", directing WDH to seek a
#' voluntary sole-source agreement with a Tribal provider. A priced allocation
#' to a class with no recipient is §0.3, so `amount` is empty and the figure is
#' in `round_amount` (Oklahoma's ROOTS device). It is also the reason the
#' classifier is overridden there: handed that sentence, it returns `TRIBAL_ORG`
#' at HIGH confidence, which would put a §6.1 programme-name-as-awardee row into
#' the file looking fully determined.
wy_assert_unnamed_rows_have_no_amount <- function(rows = NULL) {
  if (is.null(rows)) rows <- wy_award_rows()
  un <- rows[rows$awardee == WY_NO_BIDDERS, , drop = FALSE]
  if (nrow(un) != 2L) {
    stop("[WY] the care-coordination table now has ", nrow(un), " rows naming ",
         "nobody, not 2.", call. = FALSE)
  }
  if (any(!is.na(un$amount))) {
    stop("[WY] a row that names nobody has gained an `amount`. Its figure ",
         "belongs in `round_amount` (§6.2).", call. = FALSE)
  }
  if (!isTRUE(all.equal(sum(un$round_amount), 267000))) {
    stop("[WY] the two unnamed care-coordination allocations now total ",
         wy_money(sum(un$round_amount)), ", not $267,000.00.", call. = FALSE)
  }
  if (any(un$recipient_type != "NOT_YET_NAMED") ||
      any(un$recipient_confirmed != "No")) {
    stop("[WY] a row that names nobody has been given a recipient type.",
         call. = FALSE)
  }
  # The override is load-bearing: prove the classifier would do the wrong thing.
  naive <- rhtp_classify_recipient_type(WY_NO_BIDDERS, WY_STATE)
  if (naive$recipient_type != "TRIBAL_ORG") {
    stop("[WY] the shared classifier no longer types ", shQuote(WY_NO_BIDDERS),
         " as TRIBAL_ORG, so this override's reason has changed. Re-read it.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' NOTHING WAS PROMOTED (§0.4)
#'
#' Three recipients are typed FROM THE SOURCE and one class is refused, and the
#' difference is where the statement comes from.
#'
#'   TYPED FROM THE SOURCE  -- 1.1's twenty-one rows (Wyoming's own column
#'   header, initiative title and eligible-applicant Facility Type all say
#'   "Critical Access Hospital"); 1.2's four rows whose EIN Wyoming ITSELF
#'   carries in that hospital table; 4.1's eight rows (WDH's own statement of
#'   the eligible class).
#'
#'   REFUSED -- Initiative 3.1's four fallback rows, $1,535,722. Its table has
#'   NO organisation-type column AND NO EIN column, so there is no exact key to
#'   join on. Two of them are "Powell Valley Health Care", which Wyoming's 1.1
#'   table types as a hospital under the near-identical name "Powell Valley
#'   Health Care Inc" -- and §2 forbids a machine resolving a fuzzy hospital
#'   name match. One is "Bighorn Valley Health Center, Inc. dba One Health",
#'   THE IDENTICAL STRING as a 4.1 row this file types `FQHC_OR_RHC` from WDH's
#'   stated class: the same string classifies differently in two tables of one
#'   document because only one of the two tables states a class. That is
#'   RECORDED here rather than repaired, and it is worth $0 either way.
#'
#'   ALSO REFUSED -- 1.2's "Campbell County Health (CCH) Emergency Medical
#'   Servic[es]", $1,700,000, whose name the producer TRUNCATES at the cell
#'   edge and whose EIN (83-0234097) is not in the 1.1 hospital table.
WY_REFUSED_PROMOTIONS <- c("Powell Valley Health Care",
                           "Bighorn Valley Health Center, Inc. dba One Health",
                           "Campbell County Health (CCH) Emergency Medical Servic")
WY_FORM_NOT_STATED_ROWS <- 24L
WY_FORM_NOT_STATED_DOLLARS <- 5716842
WY_ADMINISTRATOR_TOTAL <- 38618260     # WIP, Initiatives 2.1 + 2.3
WY_NAMES_NOBODY        <- 30877990     # approved against no recipient at all
WY_NAMED_HOSPITAL_ROWS <- 31L
WY_NAMED_HOSPITAL_DOLLARS <- 72661323.90

wy_assert_nothing_promoted <- function(rows = NULL) {
  if (is.null(rows)) rows <- wy_award_rows()
  for (nm in WY_REFUSED_PROMOTIONS) {
    hit <- rows[rows$awardee == nm, , drop = FALSE]
    if (nrow(hit) == 0L) {
      stop("[WY] ", shQuote(nm), " has left the award file.", call. = FALSE)
    }
    if (any(hit$distributed_to_hospital != "No")) {
      stop("[WY] ", shQuote(nm), " has been promoted to a hospital dollar on ",
           "this pipeline's own knowledge, which is the §0.4 failure. Wyoming ",
           "states no form for it in the table it appears in.", call. = FALSE)
    }
  }
  # SCOPED TO THE APPROVALS TABLES. The two designated-administrator rows also
  # take §8's fallback, but they are `Unclear` rather than `No` and so are not
  # part of the one-directional question below; they have their own assertion.
  fb <- rows[rows$award_source == "APPROVALS_TABLE" &
               rows$recipient_type == "NONPROFIT_CBO" &
               rows$determination_confidence == "LOW", , drop = FALSE]
  if (nrow(fb) != WY_FORM_NOT_STATED_ROWS ||
      abs(sum(fb$amount, na.rm = TRUE) - WY_FORM_NOT_STATED_DOLLARS) > 1) {
    stop("[WY] the unstated-form question is now ", nrow(fb), " rows / ",
         wy_money(sum(fb$amount, na.rm = TRUE)), ", not ",
         WY_FORM_NOT_STATED_ROWS, " / ",
         wy_money(WY_FORM_NOT_STATED_DOLLARS), ".", call. = FALSE)
  }
  if (any(fb$distributed_to_hospital != "No")) {
    stop("[WY] the unstated-form question is no longer one-directional.",
         call. = FALSE)
  }
  part <- rhtp_hospital_dollar_partition(rows)
  named <- part[part$bucket == "NAMED_HOSPITAL" & part$state == WY_STATE, ]
  if (nrow(named) != 1L || named$rows != WY_NAMED_HOSPITAL_ROWS ||
      abs(named$dollars - WY_NAMED_HOSPITAL_DOLLARS) > 1) {
    stop("[WY] the named-hospital figure has moved to ",
         if (nrow(named)) paste(named$rows, "rows /", wy_money(named$dollars))
         else "nothing", ".", call. = FALSE)
  }
  invisible(list(fallback_rows = nrow(fb),
                 fallback_dollars = sum(fb$amount, na.rm = TRUE)))
}

#' THE DESIGNATED ADMINISTRATOR IS `Unclear`, AND THAT IS NEW HAMPSHIRE'S
#' ANSWER RATHER THAN ILLINOIS'S
#'
#' $38,618,260 -- 18.8% of Wyoming's Year 1 and its largest single recipient by
#' far -- to the Wyoming Innovation Partnership, with NO SUBRECIPIENT NAMED.
#' ICAHN is `Yes` because Illinois restricted eligibility to hospitals only;
#' WIP administers "statewide individual and institutional workforce/nursing
#' grants", which names no hospital and restricts to none, so it is FHC's class
#' and enters NEITHER bucket. A session that "tidied" the two into one coding
#' would publish $38.6M as hospital-bound money on this pipeline's authority.
#' Designed to fail if either sentence leaves its document.
wy_assert_administrator_is_unresolved <- function(rows = NULL) {
  m <- wy_text("minutes")
  for (phrase in c(
    "sole-source a master fiscal agent contract with the Wyoming Innovation Partnership (WIP)",
    "statewide individual and institutional workforce/nursing grants",
    "$35,424,820", "$3,193,440")) {
    if (!stringr::str_detect(m, stringr::fixed(phrase))) {
      stop("[WY] the minutes no longer carry ", shQuote(phrase), ". The two ",
           "administrator rows rest on that sentence; re-read it before ",
           "relying on them.", call. = FALSE)
    }
  }
  # Corroborated by a SECOND Wyoming document -- the budget summary's own Notes.
  if (!stringr::str_detect(wy_text("approvals"),
                           stringr::fixed("Sole-source contract with WIP"))) {
    stop("[WY] the budget summary no longer names WIP in its Notes column.",
         call. = FALSE)
  }
  if (is.null(rows)) rows <- wy_award_rows()
  admin <- rows[rows$award_source == "MINUTES_MOTION", , drop = FALSE]
  if (nrow(admin) != 2L ||
      !isTRUE(all.equal(sum(admin$amount), WY_ADMINISTRATOR_TOTAL))) {
    stop("[WY] the administrator rows are now ", nrow(admin), " / ",
         wy_money(sum(admin$amount)), ", not 2 / ",
         wy_money(WY_ADMINISTRATOR_TOTAL), ".", call. = FALSE)
  }
  if (any(admin$distributed_to_hospital != "Unclear") ||
      any(admin$flow_type != "PASS_THROUGH_UNRESOLVED")) {
    stop("[WY] the designated administrator has been coded `Yes`. Its eligible ",
         "class is INDIVIDUALS AND INSTITUTIONS, not hospitals only -- that is ",
         "New Hampshire's FHC and not Illinois's ICAHN, and the difference is ",
         wy_money(WY_ADMINISTRATOR_TOTAL), ".", call. = FALSE)
  }
  part <- rhtp_hospital_dollar_partition(rows)
  if (any(part$bucket %in% c("POOL_NAMED_HOSPITALS", "POOL_UNNAMED_HOSPITALS"))) {
    stop("[WY] Wyoming now contributes to a POOL bucket. It contributed to ",
         "none when this was written, because its one pass-through is ",
         "`Unclear`.", call. = FALSE)
  }
  invisible(admin)
}

#' ONE ENTITY, TWO EINs, IN ONE DOCUMENT -- RECORDED, NOT RESOLVED (§8)
#'
#' "Sheridan Memorial Hospital" is 83-6000241 in Initiative 1.1 and 92-0606087
#' in Initiative 1.2. Both are Wyoming's. The name rule types it a hospital
#' either way, so nothing turns on it here -- but the EIN is the exact key this
#' file uses to carry 1.1's stated form across to 1.2, and Sheridan is the one
#' row where that key does NOT close. It is a hospital in 1.2 on its NAME, not
#' on the join.
wy_assert_sheridan_two_eins <- function() {
  src <- wy_source_rows()
  cah <- src$ein[src$table_key == "cah" & src$awardee == "Sheridan Memorial Hospital"]
  ems <- src$ein[src$table_key == "ems" & src$awardee == "Sheridan Memorial Hospital"]
  if (length(cah) != 1L || length(ems) != 1L) {
    stop("[WY] Sheridan Memorial Hospital no longer appears exactly once in ",
         "each of Initiatives 1.1 and 1.2.", call. = FALSE)
  }
  if (identical(cah, ems)) {
    stop("[WY] Sheridan Memorial Hospital now carries ONE EIN across both ",
         "tables. The divergence this assertion records has gone; re-read the ",
         "document rather than deleting the assertion.", call. = FALSE)
  }
  invisible(c(cah = cah, ems = ems))
}

#' THE CONTROLS
#'
#' POSITIVE. The document itself is the positive control for the negative half
#' of this file: Wyoming demonstrably publishes a named, priced, recipient-level
#' roster when it has one, in six tables at once -- so the $69,496,250 approved
#' against NO recipient table is Wyoming's silence and not our reading.
#'
#' NEGATIVE / CHANNEL. `wyrhtp.submittable.com` is Wyoming's application portal
#' and reads "There are presently no open calls for submissions." -- the Year 1
#' application window is shut, which is what makes an August award document the
#' end of Year 1's competitive rounds rather than a partial view of them.
wy_assert_controls <- function() {
  init <- wy_initiative_approved()
  if (nrow(init) != 6L) {
    stop("[WY] the award document no longer carries six recipient-level ",
         "tables; it carries ", nrow(init), ". A seventh is a new roster and ",
         "this file must be rebuilt.", call. = FALSE)
  }
  summary <- wy_budget_summary()
  no_table <- summary[!summary$is_total &
                        !summary$initiative %in% wy_summary_keys_with_tables(), ]
  no_named <- no_table[!no_table$initiative %in% WY_ADMINISTRATOR_SUMMARY_LINES, ]
  if (nrow(no_table) != 9L || nrow(no_named) != 7L) {
    stop("[WY] the budget summary now has ", nrow(no_table), " lines with no ",
         "recipient table (", nrow(no_named), " of them naming nobody at all), ",
         "not 9 and 7.", call. = FALSE)
  }
  if (abs(sum(no_named$approved_award_amount) - WY_NAMES_NOBODY) > 1) {
    stop("[WY] the money approved against no recipient table AND no named ",
         "administrator is now ", wy_money(sum(no_named$approved_award_amount)),
         ", not ", wy_money(WY_NAMES_NOBODY), ".", call. = FALSE)
  }
  if (!stringr::str_detect(wy_text("submittable"), stringr::fixed(
    "no open calls for submissions"))) {
    stop("[WY] Wyoming's Submittable portal now has an OPEN CALL. A new ",
         "Year 1 round would make this file a partial view; re-read it.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' The review-queue rows this state opens, asserted present every run
WY_QUEUE_KEYS <- c("WY_TECH_FORM_NOT_STATED", "WY_EMS_LEAD_AGENCY_FORM")
wy_assert_form_not_stated_queued <- function() {
  path <- here::here("data", "reference", "classification_review_queue.csv")
  q <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  missing <- setdiff(WY_QUEUE_KEYS, q[[1]])
  if (length(missing)) {
    stop("[WY] the review queue is missing ", paste(missing, collapse = ", "),
         ". Wyoming's unstated-form rows must be visible to a human.",
         call. = FALSE)
  }
  invisible(TRUE)
}


wy_assert_all <- function() {
  wy_assert_line_model_splits_names()
  wy_assert_reconciles()
  wy_assert_footer_is_the_allotment()
  wy_assert_noa()
  wy_assert_after_noa()
  wy_assert_minutes_corroborate()
  wy_assert_two_different_eighteens()
  wy_assert_eligible_classes()
  wy_assert_sheridan_two_eins()
  wy_assert_controls()
  rows <- wy_award_rows()
  wy_assert_intent_not_award(rows)
  wy_assert_denied_not_awarded(rows)
  wy_assert_round_amount_not_summable(rows)
  wy_assert_unnamed_rows_have_no_amount(rows)
  wy_assert_nothing_promoted(rows)
  wy_assert_administrator_is_unresolved(rows)
  wy_assert_form_not_stated_queued()
  invisible(rows)
}


# -- the status table ---------------------------------------------------------

#' What each of Wyoming's fifteen budget-summary lines has published
#'
#' NO `amount` COLUMN (Texas's device). Its figures live in
#' `initiative_original_budget` and `initiative_approved_award`, which are POOL
#' figures, so nothing summed out of this table can read as a per-recipient
#' amount. `named_recipients` is the count this file extracted for that line,
#' and `0` beside a large approved award is the finding, not a gap.
wy_status_table <- function() {
  summary <- wy_budget_summary()
  body <- summary[!summary$is_total, , drop = FALSE]
  init <- wy_initiative_approved()
  rows <- wy_award_rows()

  table_for <- vapply(body$initiative, function(x) {
    hit <- names(WY_TABLE_TO_SUMMARY)[WY_TABLE_TO_SUMMARY == x]
    if (length(hit) == 1L) hit else NA_character_
  }, character(1), USE.NAMES = FALSE)

  named <- vapply(seq_along(table_for), function(i) {
    x <- table_for[i]
    if (!is.na(x)) {
      return(sum(rows$award_pool == x & rows$recipient_confirmed == "Yes"))
    }
    if (body$initiative[i] %in% WY_ADMINISTRATOR_SUMMARY_LINES) {
      # Joined on the POOL NAME, never on the amount: two initiatives could
      # share a figure, and a count is not a place to guess.
      pool <- WY_ADMINISTRATOR_POOLS[[body$initiative[i]]]
      return(sum(rows$award_source == "MINUTES_MOTION" &
                   rows$award_pool == pool))
    }
    0L
  }, integer(1))
  unnamed <- vapply(table_for, function(x) {
    if (is.na(x)) 0L else sum(rows$award_pool == x & rows$recipient_confirmed == "No")
  }, integer(1))

  tibble::tibble(
    state = WY_STATE,
    budget_summary_line = body$initiative,
    recipient_table = dplyr::coalesce(table_for, "NONE"),
    stage = dplyr::case_when(
      !is.na(table_for) ~ "APPROVED_ROSTER_PUBLISHED",
      body$initiative %in% WY_ADMINISTRATOR_SUMMARY_LINES ~
        "APPROVED_TO_NAMED_ADMINISTRATOR_NO_SUBRECIPIENT",
      TRUE ~ "APPROVED_AT_POOL_LEVEL_NO_ROSTER"),
    named_recipients = named,
    rows_naming_nobody = unnamed,
    initiative_original_budget = body$original_budget_amount,
    initiative_approved_award = body$approved_award_amount,
    channel = dplyr::case_when(
      body$initiative == "1. EMS & labor/delivery targeted (equal priority)" ~
        "One or more FISCAL AGENTS, to be contracted. The committee's own sweep of the unallocated balance, split ~50/50 between EMS sustainability and labor & delivery preservation. NOBODY NAMED.",
      body$initiative %in% c("2.1. Workforce education individual support",
                             "2.3. Workforce education startup") ~
        "SOLE-SOURCE master fiscal agent contract with the Wyoming Innovation Partnership (WIP), per the minutes. WIP is named as the ADMINISTRATOR; no subrecipient is.",
      body$initiative %in% c("3.2. Statewide tele-specialist",
                             "3.3. Transportation coordination",
                             "3.4. Centralized billing") ~
        "Authorised for a COMPETITIVE RFP that had not been issued. NOBODY NAMED.",
      body$initiative == "4.3. Exercise and healthy diet promotion" ~
        "$1.7M via RFP for a fiscal agent to run community mini-grants; the balance to the Department of Family Services for SNAP waivers and Centsible Nutrition. NOBODY NAMED.",
      body$initiative == "State Policy Action support" ~
        "Includes University of Wyoming Presidential Fitness Test contracts, per the minutes. No award document.",
      body$initiative == "Administrative expenditures" ~
        "WDH administration. No obligation requirement.",
      TRUE ~ "Recipient-level table in the 2026-08-11 Award Approvals document."),
    approval_date = as.character(WY_APPROVAL_DATE),
    source_document_title = paste(
      "Wyoming Rural Health Transformation Advisory Committee,",
      "Award Approvals - 8.11.26 (Budget Summary)"),
    state_source_url = WY_PROGRAMME_URL,
    note = dplyr::case_when(
      !is.na(table_for) ~ "Extracted into wy_year1_awardees.csv.",
      body$initiative %in% WY_ADMINISTRATOR_SUMMARY_LINES ~
        paste("APPROVED TO A NAMED DESIGNATED ADMINISTRATOR WITH NO",
              "SUBRECIPIENT NAMED. The Wyoming Innovation Partnership is",
              "Wyoming's largest single recipient at $38,618,260 across these",
              "two lines, and it is in wy_year1_awardees.csv as",
              "PASS_THROUGH_UNRESOLVED + Unclear -- New Hampshire's FHC coding",
              "and NOT Illinois's ICAHN coding, because the eligible class is",
              "individuals and institutions rather than hospitals only (§0.3)."),
      TRUE ~
        paste("APPROVED AT POOL LEVEL AGAINST NO RECIPIENT TABLE AND NO NAMED",
              "ADMINISTRATOR. This is the $30,877,990 that names nobody at",
              "all, and it is a fact about what Wyoming has PUBLISHED, never a",
              "claim that it awarded nothing (§0.4)."))
  )
}


# -- the RCJ candidate disposition -- and a NEW §0.1 FAILURE MODE -------------

#' Why Wyoming's RCJ record set contains no award, and whose documents it holds
#'
#' Wyoming carries ZERO Tier 3 candidates against 29 RCJ records -- Florida's,
#' North Carolina's and Arkansas's shape a fourth time, and the fourth proof
#' that a zero here is a fact about the DISCOVERY LAYER and never about the
#' state (§0.1). Wyoming had published 75 priced award actions the whole time.
#'
#' AND FIVE OF THE 29 ARE UTAH'S DOCUMENTS, FILED UNDER WYOMING. Including
#' Utah's own $195.7M Year 1 allotment, carried as an `UNASSIGNED` WYOMING row.
#' That is a failure mode this project had not recorded: every §0.1 defect
#' before it was WRONG ABOUT A RECORD, and this one is wrong about WHICH STATE
#' THE RECORD BELONGS TO. See `R/02c_state_attribution_sweep.R`, which measures
#' it across all fifty states.
wy_rcj_disposition <- function() {
  rt <- readRDS(here::here("data", "interim", "stage2_record_table.rds"))
  wy <- rt %>%
    dplyr::filter(.data$state == WY_STATE,
                  is.na(.data$superseded_by) | .data$superseded_by == "")
  blob <- paste(dplyr::coalesce(wy$source_doc_title, ""),
                dplyr::coalesce(wy$program_description, ""),
                dplyr::coalesce(wy$awardee_name_raw, ""))
  utah <- sum(stringr::str_detect(blob, "\\bUtah\\b"))
  tier3 <- sum(wy$award_tier == "SUBAWARD")

  if (tier3 != 0L) {
    stop("[WY] Wyoming now carries ", tier3, " Tier 3 candidates. This ",
         "disposition says it carries none; re-derive it.", call. = FALSE)
  }
  if (utah != 5L) {
    stop("[WY] ", utah, " of Wyoming's RCJ records mention Utah, not 5. ",
         "Re-read them before restating the defect.", call. = FALSE)
  }

  tibble::tribble(
    ~disposition_code, ~records, ~why, ~evidence,
    "NO_TIER_3_CANDIDATE_AT_ALL", nrow(wy),
    paste("Wyoming carries ZERO Tier 3 candidates against", nrow(wy), "RCJ",
          "records -- and had published SEVENTY-FIVE priced award actions,",
          "$135,241,492, at the time this ran. It also has no CMS state",
          "release, so `trigger_source = NEITHER` on BOTH discovery layers:",
          "Florida's shape a fourth time after North Carolina and Arkansas,",
          "and the fourth proof that a zero here is a fact about the",
          "DISCOVERY LAYER and never about the state (§0.1)."),
    "data/evidence/WY/2026-09-03_wy_advisory_committee_award_approvals_2026-08-11.pdf",

    "WRONG_STATE_UTAH_FILED_UNDER_WYOMING", utah,
    paste("FIVE of the 29 are UTAH'S DOCUMENTS, filed under Wyoming: 'Utah",
          "RHTP Stakeholder Meeting September 24, 2025'; 'Utah RHTP",
          "Cooperative Agreement Award: $195.7 million for Year 1' --",
          "UTAH'S OWN ALLOTMENT, carried as an `UNASSIGNED` WYOMING row at",
          "$195,700,000 against Wyoming's $205,004,743; 'Utah RHTP - Semantic",
          "Data Model RFGA'; 'SPRINT Consortium RHTP Grant Application'",
          "(its description opens 'Utah DHHS is soliciting applications');",
          "and 'PATH 1.4 Community Care Hubs RFGA', Utah's PATH initiative.",
          "A NEW §0.1 FAILURE MODE: wrong PROGRAMME (Texas), wrong TIER",
          "(Oklahoma), wrong KIND OF ACTION (Missouri), wrong GRAIN",
          "(Michigan) and wrong SECTION (Nebraska) are all defects in a",
          "record; this one is a defect in WHICH STATE THE RECORD IS. It is",
          "harmless in Wyoming only because none of the five is Tier 3 --",
          "had one been, an extractor keyed on the candidate list would have",
          "published Utah's subawards as Wyoming's."),
    "data/interim/stage2_record_table.rds",

    "STATE_PROGRAMME_NOT_RHTP", 1L,
    paste("'County Health Dept Seeks State Funds for Rural Health",
          "Initiatives' is a buckrail.com report of a Teton County (WY)",
          "health department seeking STATE funds. Genuinely Wyoming and",
          "genuinely not RHTP -- §6.2's state-programme filter, and the only",
          "one of the 29 that is."),
    "data/interim/stage2_record_table.rds"
  )
}


# -- build / report -----------------------------------------------------------

wy_build <- function() {
  rows <- wy_assert_all()
  readr::write_csv(rows, WY_OUT_CSV, na = "")
  message("[WY] wrote ", WY_OUT_CSV, " (", nrow(rows), " rows)")

  st <- wy_status_table()
  if ("amount" %in% names(st)) {
    stop("[WY] the status table has grown an `amount` column. Its pool figures ",
         "live in `initiative_*` columns precisely so that nothing summed out ",
         "of this table can be read as a per-recipient amount (Texas's ",
         "device).", call. = FALSE)
  }
  readr::write_csv(st, WY_STATUS_CSV, na = "")
  message("[WY] wrote ", WY_STATUS_CSV, " (", nrow(st), " rows)")

  disp <- wy_rcj_disposition()
  readr::write_csv(disp, WY_DISPOSITION_CSV, na = "")
  message("[WY] wrote ", WY_DISPOSITION_CSV, " (", nrow(disp), " rows)")
  invisible(rows)
}

wy_report <- function() {
  rows <- wy_award_rows()
  rec <- wy_reconcile(rows)
  part <- rhtp_hospital_dollar_partition(rows)
  cat("\nWYOMING -- RHTP Year 1, as approved by the Rural Health",
      "Transformation\nAdvisory Committee on", format(WY_APPROVAL_DATE), "\n")
  cat(strrep("-", 78), "\n")
  cat("  EVERY ROW IS A COMMITTEE APPROVAL, NOT AN EXECUTED AGREEMENT.\n")
  cat("  Wyoming's Year 1 obligation deadline for executed contracts is\n")
  cat("  END OF OCTOBER 2026 (the minutes) / 2026-10-01 (WDH's timeline).\n\n")

  cat(sprintf("  %d award actions, %s to a NAMED recipient\n",
              nrow(rows), wy_money(sum(rows$amount, na.rm = TRUE))))
  admin <- rows[rows$award_source == "MINUTES_MOTION", ]
  cat(sprintf("    of which %s is the DESIGNATED ADMINISTRATOR (WIP), 2 rows\n",
              wy_money(sum(admin$amount))))
  cat(sprintf("  %s approved across six recipient tables + the administrator\n",
              wy_money(rec$roster_total)))
  cat(sprintf("  %s approved at POOL level naming NOBODY AT ALL (%.1f%%)\n",
              wy_money(rec$unnamed_total),
              100 * rec$unnamed_total / WY_SUMMARY_TOTAL))
  cat(sprintf("  %s Wyoming's whole Year 1 -- the §7.1 allotment is %s\n",
              wy_money(rec$grand_total), wy_money(WY_ALLOTMENT)))
  cat("    THE $1.26 IS WYOMING'S OWN ROUNDING AND IS NOT CORRECTED (§8):\n")
  cat("    WDH's budget summary prints 4.1 as $30,465,505 where its own table\n")
  cat("    gives $30,465,504.74, and floors its Total to $205,004,742; CMS's\n")
  cat("    table rounds the same award UP to $205,004,743 and the Notice of\n")
  cat("    Award gives $205,004,742.95. Four figures, all official, all pinned.\n\n")

  cat("  BY INITIATIVE (read `award_pool` before quoting anything)\n")
  for (i in seq_len(nrow(rec$with_roster))) {
    r <- rec$with_roster[i, ]
    cat(sprintf("    %-45s %3d rows  %s\n", r$initiative, r$rows,
                wy_money(r$approved)))
  }

  cat("\n  HOSPITAL DOLLARS\n")
  for (i in seq_len(nrow(part))) {
    cat(sprintf("    %-24s rows = %3d   dollars = %s\n",
                part$bucket[i], part$rows[i], wy_money(part$dollars[i])))
  }
  hosp <- rows[rows$hospital_attribution == "NAMED_HOSPITAL", ]
  cat("    of which, by initiative:\n")
  bysrc <- hosp %>% dplyr::group_by(.data$award_pool) %>%
    dplyr::summarise(n = dplyr::n(), amt = sum(.data$amount), .groups = "drop")
  for (i in seq_len(nrow(bysrc))) {
    cat(sprintf("      %-45s %3d  %s\n", bysrc$award_pool[i], bysrc$n[i],
                wy_money(bysrc$amt[i])))
  }

  cat("\n  1.1's ELIGIBLE CLASS IS HOSPITALS ONLY -- ILLINOIS'S ANSWER.\n")
  cat("  The recipient's FORM IS STATED BY WYOMING, not inferred from its name:\n")
  cat("  the column is headed \"Hospital\", the initiative is \"Critical Access\n")
  cat("  Hospital - Basic\", and the budget narrative gives ONE Facility Type.\n")
  cat("  §8's name rule alone would MISS THREE of the eighteen -- Powell Valley\n")
  cat("  Health Care Inc, Cody Regional Health and Crook County Medical\n")
  cat("  Services District, $7,525,331 between them.\n")
  cat("  AND THE TWO 18s ARE NOT THE SAME 18: three names differ each way.\n")

  cat("\n  THE RUN MODEL IS MANDATORY\n")
  cat("  Six rows carry the recipient name in a SEPARATE PAINTED RUN. A\n")
  cat("  line-model read of Initiative 1.1 gives SIXTEEN hospitals and\n")
  cat("  $43,044,174, orphaning $5,156,000 in silence.\n")

  fb <- rows[rows$recipient_type == "NONPROFIT_CBO" &
               rows$determination_confidence == "LOW", ]
  cat("\n  THE UNSTATED-FORM QUESTION -- THE TENTH, AND ONE-DIRECTIONAL\n")
  cat(sprintf("    %d rows / %s against a %s named-hospital floor\n",
              nrow(fb), wy_money(sum(fb$amount, na.rm = TRUE)),
              wy_money(sum(hosp$amount))))
  cat("    Nothing was promoted (§0.4). Initiative 3.1 publishes NO EIN and NO\n")
  cat("    organisation-type column, so \"Powell Valley Health Care\" there\n")
  cat("    cannot be joined to \"Powell Valley Health Care Inc\" in 1.1 by any\n")
  cat("    means §2 permits.\n")

  cat("\n  THE LARGEST SINGLE RECIPIENT IS `Unclear`, AND THAT IS DELIBERATE\n")
  cat(sprintf("    %s to the Wyoming Innovation Partnership across Initiatives\n",
              wy_money(sum(admin$amount))))
  cat("    2.1 and 2.3 -- a SOLE-SOURCE MASTER FISCAL AGENT contract with NO\n")
  cat("    subrecipient named. It is in the award file because Wyoming's motion\n")
  cat("    calls it a fiscal agent, where Missouri's FAQ said its Hub Anchors\n")
  cat("    'will not act as the fiscal agent' and they are not in Missouri's.\n")
  cat("    Its class is INDIVIDUALS AND INSTITUTIONS, so it is New Hampshire's\n")
  cat("    FHC (`Unclear`, neither bucket) and NOT Illinois's ICAHN (`Yes`).\n")

  cat("\n  THE APPLICANT TRAP\n")
  cat(sprintf("    %d applicants are named and NOT awarded, %d of them under\n",
              WY_UNAWARDED_TOTAL, 40L))
  cat(sprintf("    Initiative 3.1 alone, requesting %s -- mostly NAMED WYOMING\n",
              wy_money(WY_TECH_UNAWARDED_REQUESTED)))
  cat("    HOSPITALS. Reading that table as a roster is §0.3 at $38.8M.\n")
  invisible(rows)
}


# -- fetch / probe ------------------------------------------------------------

wy_get <- function(url, label) {
  message("[WY] fetching ", url)
  resp <- httr::GET(url, httr::user_agent(WY_USER_AGENT), httr::timeout(300))
  if (httr::status_code(resp) != 200L) {
    stop("[WY] HTTP ", httr::status_code(resp), " for ", url, call. = FALSE)
  }
  httr::content(resp, as = "raw")
}

#' Fetch what is missing, and VERIFY what is already here
#'
#' The archive and its MANIFEST.txt were written by hand in session 41. This
#' does not rewrite that manifest -- it re-hashes every file on disk against it,
#' which is the check the manifest exists for, and downloads only what is
#' absent. `--force` re-downloads, and is the only path that can change a
#' committed byte.
wy_fetch <- function(force = FALSE) {
  dir.create(WY_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  fetched <- 0L
  for (i in seq_len(nrow(WY_SOURCES))) {
    dest <- file.path(WY_EVIDENCE_DIR, WY_SOURCES$file[i])
    if (file.exists(dest) && !force) {
      message("[WY] cached, not re-fetched: ", WY_SOURCES$file[i])
      next
    }
    if (fetched > 0L) Sys.sleep(WY_HOST_THROTTLE_S)
    writeBin(wy_get(WY_SOURCES$url[i], WY_SOURCES$file[i]), dest)
    fetched <- fetched + 1L
  }
  wy_verify_manifest()
}

#' Re-hash every archived file against MANIFEST.txt
#'
#' This verifies the COMMITTED BYTES and nothing else. It cannot be used on a
#' re-fetch: `health.wyo.gov` rotates a token on every request, so a re-fetched
#' page never reproduces its own manifest digest. That is why `--fetch` without
#' `--force` downloads only what is MISSING.
wy_verify_manifest <- function() {
  path <- file.path(WY_EVIDENCE_DIR, "MANIFEST.txt")
  lines <- readLines(path, warn = FALSE)
  rows <- lines[stringr::str_detect(lines, "^[0-9]{4}-[0-9]{2}-[0-9]{2}_wy_")]
  out <- purrr::map_dfr(rows, function(l) {
    p <- stringr::str_split(l, "\\s+")[[1]]
    dest <- file.path(WY_EVIDENCE_DIR, p[1])
    got <- if (file.exists(dest)) digest::digest(file = dest, algo = "sha256") else NA_character_
    tibble::tibble(file = p[1], manifest_sha256 = p[3], on_disk_sha256 = got,
                   ok = identical(got, p[3]))
  })
  bad <- out[!out$ok, ]
  if (nrow(bad)) {
    stop("[WY] ", nrow(bad), " archived file(s) no longer match MANIFEST.txt: ",
         paste(bad$file, collapse = ", "), call. = FALSE)
  }
  message("[WY] all ", nrow(out), " archived files match MANIFEST.txt.")
  invisible(out)
}

#' LIVE: has Wyoming published anything since the 2026-08-11 approvals?
#'
#' What is being watched, and why. The committee's NEXT MEETING is targeted for
#' 4 or 5 NOVEMBER 2026, "in conjunction with the upcoming CMS Federal Site
#' Visit to Wyoming" -- so the document this file rests on is the only one until
#' then, and what changes before then changes on the WDH pages: the Drive folder
#' gaining an executed-contract notice, the programme page gaining an award
#' announcement, or the Submittable portal opening a new call (which would make
#' this file a partial view of Year 1).
#'
#' It compares a CONTENT digest rather than a file digest, and that is MEASURED
#' here rather than inherited: two fetches of the programme page three seconds
#' apart are 199,946 bytes each and hash differently, so the file digest moves
#' on every request. See `wy_html_text()` for the second mechanism -- a Gravity
#' Forms honeypot label that rotates INSIDE THE TEXT and which the first live
#' probe reported as a CHANGED page, one word out of 951.
WY_AWARD_POSTED <- c(
  "executed contract", "executed agreement", "notice of award to",
  "contracts have been executed", "grant agreement signed"
)
wy_probe <- function() {
  keys <- c("programme", "public_notice", "applications", "submittable")
  cat("\nWYOMING -- live probe\n"); cat(strrep("-", 78), "\n")
  changed <- character(0)
  for (k in keys) {
    body <- tryCatch(rawToChar(wy_get(wy_url(k), k)), error = function(e) NULL)
    if (is.null(body)) { cat(sprintf("  %-16s UNREACHABLE\n", k)); next }
    live <- wy_content_digest(k, body)
    archived <- wy_content_digest(k)
    same <- identical(live, archived)
    if (!same) changed <- c(changed, k)
    cat(sprintf("  %-16s %s\n", k, if (same) "UNCHANGED" else "CHANGED"))
    live_txt <- wy_html_text(body)
    hits <- WY_AWARD_POSTED[stringr::str_detect(
      live_txt, stringr::regex(WY_AWARD_POSTED, ignore_case = TRUE))]
    if (length(hits)) {
      cat("      AWARD LANGUAGE ON THE LIVE PAGE: ",
          paste(hits, collapse = "; "), "\n")
    }
    if (k == "submittable" &&
        !stringr::str_detect(live_txt, stringr::fixed("no open calls for submissions"))) {
      cat("      THE APPLICATION PORTAL HAS AN OPEN CALL. Year 1 may have a\n")
      cat("      further round; this file would then be a partial view.\n")
    }
    Sys.sleep(WY_HOST_THROTTLE_S)
  }
  cat("\n  Next Advisory Committee meeting: 4 or 5 November 2026, with the CMS\n")
  cat("  federal site visit. Nothing is expected to move before then.\n")
  invisible(changed)
}


# -- CLI ----------------------------------------------------------------------

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) {
    wy_fetch(force = "--force" %in% args)
  } else if ("--validate" %in% args) {
    wy_assert_all()
    message("[WY] all assertions pass.")
  } else if ("--build" %in% args) {
    wy_build()
  } else if ("--probe" %in% args) {
    wy_probe()
  } else if ("--report" %in% args) {
    wy_report()
  } else {
    cat("usage: Rscript R/03aj_wy_year1_awardees.R",
        "[--fetch [--force] | --validate | --build | --probe | --report]\n")
  }
}
