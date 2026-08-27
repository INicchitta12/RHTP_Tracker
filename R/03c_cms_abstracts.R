# 03c_cms_abstracts.R -------------------------------------------------------
# CMS RHT Program State Project Abstracts (December 2025) -> candidate list of
# named organizations, one row per (state, organization).
#
# Build spec §4.1. These are PRE-AWARD application documents. CMS says so in
# the document's own executive summary:
#
#   "Budget amounts/requested funds highlighted in the State's Abstract are
#    purely illustrative and hypothetical and do not reflect the State's final
#    award amount or approved use of funds."
#
# Two rules follow, and both are asserted here rather than left to discipline:
#
#   1. NO DOLLAR FIGURE from this source may enter any table. Nearly every
#      state reports $1,000,000,000 or $200 million/year -- the NOFO
#      placeholder. Wisconsin's three initiatives sum to $945M against an
#      actual FY2026 award of $203,670,005; Virginia's first three sum to
#      $826.6M against $189,544,888. rhtp_assert_no_dollar_figures() hard-fails
#      on any currency-shaped string in any column.
#
#   2. Every row is status = CANDIDATE_ONLY. Being named as a partner or an
#      intended subrecipient in an application is not evidence of receiving
#      money (§0.3, eligibility is not receipt). Delaware is the worked proof:
#      its abstract names five hospital systems, independent verification
#      confirmed three, and Bayhealth and ChristianaCare appear in no verified
#      award -- a 40% overstatement on a five-name list.
#
# Source of record is data/reference/abstract_named_organizations.csv. The
# workbook is a render of it, never the other way round (§0.2a: an
# authoritative number has exactly one home).
#
# The abstracts PDF is archived verbatim under data/raw/cms/<fetch_date>/ with
# a SHA-256 manifest, so this extraction is re-checkable offline against the
# bytes CMS served (§0.5).
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only -- never |>. No setwd();
# all paths go through here::here(). Contains no network calls.
#
# CLI:
#   Rscript R/03c_cms_abstracts.R --validate   # assertions only, no writes
#   Rscript R/03c_cms_abstracts.R --build      # assertions, then render xlsx

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(readr)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))


# -- Paths -----------------------------------------------------------------

RHTP_ABSTRACT_CANDIDATES_CSV <- "data/reference/abstract_named_organizations.csv"
RHTP_ABSTRACT_COVERAGE_CSV   <- "data/reference/abstract_coverage_by_state.csv"
RHTP_ABSTRACT_WORKBOOK       <- "abstract_named_organizations.xlsx"

RHTP_ABSTRACT_SOURCE_URL <-
  "https://www.cms.gov/files/document/rht-program-state-provided-abstracts.pdf"


#' Where the fetched CMS abstracts PDF is archived
#'
#' Under data/raw/ and therefore committed (§0.5). Unlike the §7.1 allotment
#' table, the whole PDF is archived: it carries no third-party tokens, it is
#' 484 KB, and a page-level extract would not let a reviewer check
#' `page_reference` on a candidate.
#'
#' @param fetch_date Date the archive was written.
#' @return Path to the archived PDF.
rhtp_abstract_archive_path <- function(fetch_date = as.Date("2026-08-27")) {
  cfg <- rhtp_config()
  here::here(
    cfg$paths$raw_cms,
    format(fetch_date, "%Y-%m-%d"),
    "rht_program_state_provided_abstracts.pdf"
  )
}


# -- Load ------------------------------------------------------------------

#' Read the candidate organization table
#'
#' @param path Reference CSV, relative to the repo root.
#' @return A tibble, one row per (state, named_organization).
rhtp_abstract_candidates <- function(path = RHTP_ABSTRACT_CANDIDATES_CSV) {
  full_path <- here::here(path)

  if (!file.exists(full_path)) {
    stop(
      "Abstract candidate table not found at '", full_path, "'.\n",
      "It is the source of record for the CMS abstract extraction and is ",
      "committed; if it is missing the working tree is incomplete.",
      call. = FALSE
    )
  }

  readr::read_csv(full_path, col_types = readr::cols(.default = readr::col_character()))
}


#' Read the per-state coverage table
#'
#' @param path Reference CSV, relative to the repo root.
#' @return A tibble, one row per state.
rhtp_abstract_coverage <- function(path = RHTP_ABSTRACT_COVERAGE_CSV) {
  full_path <- here::here(path)

  if (!file.exists(full_path)) {
    stop("Abstract coverage table not found at '", full_path, "'.", call. = FALSE)
  }

  readr::read_csv(
    full_path,
    col_types = readr::cols(
      state           = readr::col_character(),
      abstract_status = readr::col_character(),
      n_named         = readr::col_double(),
      note            = readr::col_character()
    )
  )
}


# -- Assertions ------------------------------------------------------------

#' Hard-fail on any currency-shaped string anywhere in a table
#'
#' Spec §4.1. The abstracts' dollar figures are illustrative and CMS says so;
#' a figure that leaks out of this stage would be indistinguishable downstream
#' from a real award amount. This is cheap to run and catches the leak at the
#' only point where anyone would notice.
#'
#' Deliberately broad: `$1,000,000,000`, `$200 million`, `200M`, and a bare
#' numeric column all trip it.
#'
#' @param tbl A data frame.
#' @param what Label used in the error message.
#' @return `tbl`, invisibly.
rhtp_assert_no_dollar_figures <- function(tbl, what = "abstract candidate table") {
  numeric_cols <- names(tbl)[purrr::map_lgl(tbl, is.numeric)]
  numeric_cols <- setdiff(numeric_cols, "n_named")

  if (length(numeric_cols) > 0) {
    stop(
      "§4.1 violation in the ", what, ": numeric column(s) ",
      paste(numeric_cols, collapse = ", "), ".\n",
      "The CMS abstracts carry no usable amounts -- their figures are the NOFO ",
      "placeholder, not awards. Extract named organizations only.",
      call. = FALSE
    )
  }

  currency_re <- paste0(
    "\\$\\s*[0-9]",                      # $1,000,000,000  /  $ 200
    "|[0-9][0-9,\\.]*\\s*(million|billion|M\\b|B\\b)",  # 200 million / 43.1M
    "|[0-9]{1,3}(,[0-9]{3}){2,}"         # 1,000,000,000 without a sign
  )

  hits <- tbl %>%
    dplyr::mutate(dplyr::across(dplyr::everything(), as.character)) %>%
    tidyr::pivot_longer(
      dplyr::everything(),
      names_to = "column", values_to = "value", values_drop_na = TRUE
    ) %>%
    dplyr::filter(stringr::str_detect(.data$value, stringr::regex(currency_re, ignore_case = TRUE)))

  if (nrow(hits) > 0) {
    stop(
      "§4.1 violation in the ", what, ": ", nrow(hits),
      " currency-shaped value(s) found. First few:\n",
      paste0("  ", hits$column, ": ", hits$value, collapse = "\n"),
      call. = FALSE
    )
  }

  invisible(tbl)
}


#' Validate the candidate table against §8 and the §4.1 rules
#'
#' @param candidates Output of [rhtp_abstract_candidates()].
#' @param coverage Output of [rhtp_abstract_coverage()].
#' @return A tibble of check results, invisibly. Errors on any failure.
rhtp_assert_abstract_candidates <- function(candidates = rhtp_abstract_candidates(),
                                            coverage   = rhtp_abstract_coverage()) {
  problems <- character(0)

  rhtp_assert_no_dollar_figures(candidates, "abstract candidate table")
  rhtp_assert_no_dollar_figures(coverage,   "abstract coverage table")

  # -- §8: org_type is the recipient_type vocabulary -----------------------
  allowed_types <- rhtp_vocabulary("recipient_type")
  bad_types <- setdiff(unique(candidates$org_type), allowed_types)
  if (length(bad_types) > 0) {
    problems <- c(problems, paste0(
      "org_type values outside the §8 recipient_type vocabulary: ",
      paste(bad_types, collapse = ", ")
    ))
  }

  # -- Everything is a candidate, and stays one until Stage 4 --------------
  bad_status <- setdiff(unique(candidates$status), "CANDIDATE_ONLY")
  if (length(bad_status) > 0) {
    problems <- c(problems, paste0(
      "status must be CANDIDATE_ONLY on every row (§0.3, eligibility is not ",
      "receipt). Found: ", paste(bad_status, collapse = ", ")
    ))
  }

  confirmed <- candidates %>%
    dplyr::filter(!is.na(.data$confirmed_recipient) & .data$confirmed_recipient != "")
  if (nrow(confirmed) > 0) {
    problems <- c(problems, paste0(
      nrow(confirmed), " row(s) carry confirmed_recipient. A CMS abstract can ",
      "never confirm a recipient -- confirmation comes from a state award ",
      "notice via Stage 4 (§9.3)."
    ))
  }

  bad_source <- setdiff(unique(candidates$source), "CMS_ABSTRACT_PREAWARD")
  if (length(bad_source) > 0) {
    problems <- c(problems, paste0(
      "source must be CMS_ABSTRACT_PREAWARD on every row. Found: ",
      paste(bad_source, collapse = ", ")
    ))
  }

  # -- Coverage is all 50 CMS states, and only those -----------------------
  cms_states <- rhtp_cms_states()$state
  missing_states <- setdiff(cms_states, coverage$state)
  extra_states   <- setdiff(coverage$state, cms_states)

  if (length(missing_states) > 0) {
    problems <- c(problems, paste0(
      "coverage is missing ", length(missing_states), " CMS state(s): ",
      paste(missing_states, collapse = ", ")
    ))
  }
  if (length(extra_states) > 0) {
    problems <- c(problems, paste0(
      "coverage carries non-CMS state code(s): ",
      paste(extra_states, collapse = ", ")
    ))
  }

  orphan_states <- setdiff(candidates$state, coverage$state)
  if (length(orphan_states) > 0) {
    problems <- c(problems, paste0(
      "candidate rows for state(s) absent from coverage: ",
      paste(unique(orphan_states), collapse = ", ")
    ))
  }

  # -- n_named is derived, not asserted by hand ----------------------------
  counted <- candidates %>%
    dplyr::count(.data$state, name = "n_actual")

  drift <- coverage %>%
    dplyr::left_join(counted, by = "state") %>%
    dplyr::mutate(n_actual = dplyr::coalesce(.data$n_actual, 0)) %>%
    dplyr::filter(.data$n_named != .data$n_actual)

  if (nrow(drift) > 0) {
    problems <- c(problems, paste0(
      "coverage n_named disagrees with the candidate table for ", nrow(drift),
      " state(s): ",
      paste0(drift$state, " (says ", drift$n_named, ", holds ", drift$n_actual, ")",
             collapse = "; ")
    ))
  }

  # -- Nothing is left unextracted -----------------------------------------
  not_extracted <- coverage %>%
    dplyr::filter(.data$abstract_status == "NOT YET EXTRACTED")
  if (nrow(not_extracted) > 0) {
    problems <- c(problems, paste0(
      nrow(not_extracted), " state(s) still NOT YET EXTRACTED: ",
      paste(not_extracted$state, collapse = ", ")
    ))
  }

  bad_cov_status <- setdiff(
    unique(coverage$abstract_status),
    c("NAMED ORGANIZATIONS", "NONE NAMED", "NOT YET EXTRACTED")
  )
  if (length(bad_cov_status) > 0) {
    problems <- c(problems, paste0(
      "abstract_status outside its controlled set: ",
      paste(bad_cov_status, collapse = ", ")
    ))
  }

  # -- Duplicate (state, organization) -------------------------------------
  dupes <- candidates %>%
    dplyr::count(.data$state, .data$named_organization, name = "n") %>%
    dplyr::filter(.data$n > 1)
  if (nrow(dupes) > 0) {
    problems <- c(problems, paste0(
      nrow(dupes), " duplicate (state, named_organization) pair(s): ",
      paste0(dupes$state, " / ", dupes$named_organization, collapse = "; ")
    ))
  }

  if (length(problems) > 0) {
    stop(
      "CMS abstract candidate table failed validation:\n",
      paste0("  - ", problems, collapse = "\n"),
      call. = FALSE
    )
  }

  message("  abstract candidates: ", nrow(candidates), " rows across ",
          dplyr::n_distinct(candidates$state), " states; coverage complete for all 50.")

  invisible(candidates)
}


# -- Render ----------------------------------------------------------------

#' The READ FIRST sheet
#'
#' Kept in code rather than in the workbook so a rebuild cannot quietly drop
#' it -- the same failure that removed a committed section of
#' reviewer-coding-instructions.md at 0a51145.
#'
#' @param candidates The candidate table.
#' @param coverage The coverage table.
#' @return A two-column tibble.
rhtp_abstract_read_first <- function(candidates, coverage) {
  n_states_named <- coverage %>%
    dplyr::filter(.data$abstract_status == "NAMED ORGANIZATIONS") %>%
    nrow()

  # Named entities only. Three states (IL, NE, VA) carry a "(unnamed)" row
  # standing for a hospital *class* their abstract cites without naming
  # anyone; counting those as named hospitals is the §0.3 error in miniature.
  n_hospital <- candidates %>%
    dplyr::filter(
      .data$org_type == "HOSPITAL_OR_SYSTEM",
      !stringr::str_detect(.data$named_organization, stringr::fixed("(unnamed)"))
    ) %>%
    nrow()

  n_hospital_class <- candidates %>%
    dplyr::filter(
      .data$org_type == "HOSPITAL_OR_SYSTEM",
      stringr::str_detect(.data$named_organization, stringr::fixed("(unnamed)"))
    ) %>%
    nrow()

  tibble::tribble(
    ~`Abstract-derived candidate list — NOT a recipient list`, ~` `,
    NA_character_, NA_character_,
    "What this is",
      paste0("Organizations named in each state's CMS RHT Program Project Abstract ",
             "(December 2025). Source: ", RHTP_ABSTRACT_SOURCE_URL),
    "Archived",
      paste0("data/raw/cms/2026-08-27/rht_program_state_provided_abstracts.pdf, ",
             "verbatim with a SHA-256 manifest. Rebuild with ",
             "Rscript R/03c_cms_abstracts.R --build"),
    "Source of record",
      paste0("data/reference/abstract_named_organizations.csv. This workbook is a ",
             "render of that CSV -- edit the CSV, never this file."),
    NA_character_, NA_character_,
    "CANDIDATES ONLY — do not promote",
      paste0("These are PRE-AWARD application documents. Being named as a partner is ",
             "not evidence of receiving money. Nothing here may be counted as a ",
             "confirmed recipient without a state award notice (spec section 9.3)."),
    "Worked proof",
      paste0("Delaware's abstract names 5 hospital systems: Tidal Health, Beebe ",
             "Healthcare, Bayhealth, ChristianaCare, Nemours. Independent verification ",
             "confirmed only 3. Bayhealth and ChristianaCare appear in no verified ",
             "award. A 40% overstatement on a 5-name list."),
    NA_character_, NA_character_,
    "Honest assessment of yield", NA_character_,
      paste0("All 50 states extracted; ", n_states_named, " named any organizations"),
      "The other 34 said 'to be determined', 'TBD', or 'to be selected through procurement'.",
      paste0("Only ", n_hospital, " hospital entities named across all 50"),
      paste0("5 in Delaware, 1 in New Jersey, 1 in Rhode Island (Eleanor Slater, a ",
             "state hospital named as an initiative site rather than an awardee). ",
             n_hospital_class, " further rows -- Illinois, Nebraska, Virginia -- name ",
             "'hospitals' as a category, not by name, and are counted separately."),
    "So this is a modest head start, not a national lead list",
      paste0("Useful for identifying pass-through administrators and intermediaries. ",
             "Weak for finding hospitals."),
    NA_character_, NA_character_,
    "Two things it IS good for", NA_character_,
    "Pass-through administrator identification",
      paste0("NH names the Foundation for Healthy Communities. NC names Duke-Margolis ",
             "and UNC Sheps. GA names Deloitte, RSM, ShareCare. RI names the Hospital ",
             "Association of Rhode Island; WA names the Washington State Hospital ",
             "Association. These are the intermediaries section 10.2 needs classified."),
    "A clue worth chasing",
      paste0("Minnesota's abstract says the complete subrecipient list is IN THE BUDGET ",
             "NARRATIVE. If that is a general pattern, budget narratives carry both ",
             "approved dollars AND named subrecipients - reinforcing them as the ",
             "section 7A backbone."),
    NA_character_, NA_character_,
    "Dollar figures: unusable", NA_character_,
    "CMS says so directly",
      paste0("'Budget amounts/requested funds highlighted in the State's Abstract are ",
             "purely illustrative and hypothetical and do not reflect the State's final ",
             "award amount or approved use of funds.'"),
    "Confirmed by inspection",
      paste0("Nearly every state reports the NOFO placeholder, not the actual award. ",
             "Wisconsin's three initiatives sum to 4.6x its real FY2026 award; ",
             "Virginia's first three sum to 4.4x its own. New Mexico's detailed ",
             "5-initiative breakdown sums to exactly the placeholder against an actual ",
             "award near half of one initiative."),
    "Enforced, not just documented",
      paste0("rhtp_assert_no_dollar_figures() hard-fails the build on any ",
             "currency-shaped string in either reference CSV.")
  )
}


#' Render the workbook from the reference CSVs
#'
#' @param out_path Workbook path, relative to the repo root.
#' @return `out_path`, invisibly.
rhtp_build_abstract_workbook <- function(out_path = RHTP_ABSTRACT_WORKBOOK) {
  candidates <- rhtp_abstract_candidates()
  coverage   <- rhtp_abstract_coverage()

  rhtp_assert_abstract_candidates(candidates, coverage)

  wb <- openxlsx::createWorkbook()
  header <- openxlsx::createStyle(textDecoration = "bold", valign = "top")
  wrap   <- openxlsx::createStyle(wrapText = TRUE, valign = "top")

  openxlsx::addWorksheet(wb, "READ FIRST")
  openxlsx::writeData(wb, "READ FIRST", rhtp_abstract_read_first(candidates, coverage))
  openxlsx::setColWidths(wb, "READ FIRST", cols = 1:2, widths = c(46, 110))
  openxlsx::addStyle(wb, "READ FIRST", wrap, rows = 1:40, cols = 1:2,
                     gridExpand = TRUE, stack = TRUE)
  openxlsx::addStyle(wb, "READ FIRST", header, rows = 1, cols = 1:2,
                     gridExpand = TRUE, stack = TRUE)

  openxlsx::addWorksheet(wb, "Named organizations")
  openxlsx::writeData(wb, "Named organizations", candidates, headerStyle = header)
  openxlsx::setColWidths(wb, "Named organizations", cols = 1:ncol(candidates),
                         widths = c(7, 58, 30, 62, 24, 16, 20, 22, 14))
  openxlsx::freezePane(wb, "Named organizations", firstActiveRow = 2)

  openxlsx::addWorksheet(wb, "Coverage by state")
  openxlsx::writeData(wb, "Coverage by state", coverage, headerStyle = header)
  openxlsx::setColWidths(wb, "Coverage by state", cols = 1:4,
                         widths = c(7, 22, 10, 96))
  openxlsx::freezePane(wb, "Coverage by state", firstActiveRow = 2)

  full_path <- here::here(out_path)
  openxlsx::saveWorkbook(wb, full_path, overwrite = TRUE)

  message("  wrote ", out_path, " (", nrow(candidates), " candidates, ",
          nrow(coverage), " states)")

  invisible(out_path)
}


# -- CLI -------------------------------------------------------------------

if (!interactive() && identical(sys.nframe(), 0L)) {
  args <- commandArgs(trailingOnly = TRUE)

  if ("--validate" %in% args) {
    message("Validating the CMS abstract candidate table (§4.1, §8)...")
    rhtp_assert_abstract_candidates()
    message("OK.")
  } else if ("--build" %in% args) {
    message("Building ", RHTP_ABSTRACT_WORKBOOK, " from the reference CSVs...")
    rhtp_build_abstract_workbook()
    message("Done.")
  } else {
    message(
      "Usage:\n",
      "  Rscript R/03c_cms_abstracts.R --validate   # assertions only\n",
      "  Rscript R/03c_cms_abstracts.R --build      # assertions, then render the workbook"
    )
  }
}
