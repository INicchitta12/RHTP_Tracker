# 03f_pa_year1_awardees.R ----------------------------------------------------
# Pennsylvania Year 1 awardees -> data/reference/pa_year1_awardees.csv (+ render)
#
# WHAT THIS IS. Pennsylvania is the cleanest recipient-level award list this
# project has found (session 11's locator report). DHS publishes 66 authorized
# projects in one HTML table -- recipient, amount, project description, region,
# initiative -- and the table's own amounts sum to $42,198,309.80 against the
# $42,198,309 DHS states in the announcement. The count matches exactly.
#
# TWO DOCUMENTS, AND NEITHER SUPPORTS THE CODING ALONE. This is the Georgia
# arrangement (session 10) exactly, and it needs the same care:
#
#   - The DHS ANNOUNCEMENT (2026-07-23) supplies the award language -- "the
#     first qualified projects to RECEIVE $42 million", "sixty-six projects were
#     AUTHORIZED" -- and the state total. It names no recipient.
#   - The PROGRAM PAGE supplies the 66 names and amounts. Its own heading reads
#     "List of Eligible Projects", and read ALONE that is an eligibility list,
#     which §0.3 forbids coding as receipt.
#
# The announcement links to that page as the list of the projects it just said
# were authorized. So every row cites both, and `recipient_names_source_url`
# records which document supplied the names, exactly as Georgia's rows do.
#
# THE AWARDS ARE AUTHORIZED, NOT YET DISBURSED, AND THAT IS RECORDED. The
# announcement says "Distribution is pending approval of selected projects."
# That makes these NOTICE_OF_INTENT_TO_AWARD, not NOTICE_OF_AWARD -- both are
# primary under §8 and both can support a Yes, but they are different documents
# and flattening them would lose the distinction a reviewer needs. Every row
# carries `amount_confirmed = Yes` (the state published the figure) and
# `disbursement_status = PENDING_APPROVAL`.
#
# CLASSIFICATION IS NOT DONE HERE. recipient_type, flow_type and
# distributed_to_hospital come from R/utils_recipient_classification.R, which
# holds the §8/§10.2 rules for every state so they cannot drift apart.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only -- never |>. No setwd(); all
# paths go through here::here(). --fetch is the only mode that touches the
# network; everything else reads the committed archive.
#
# CLI:
#   Rscript R/03f_pa_year1_awardees.R --fetch     # archive both sources + SHA-256
#   Rscript R/03f_pa_year1_awardees.R --validate  # parse + assert, no writes
#   Rscript R/03f_pa_year1_awardees.R --build     # assert, write CSV + xlsx

suppressPackageStartupMessages({
  library(dplyr)
  library(openxlsx)
  library(purrr)
  library(readr)
  library(rvest)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

PA_STATE <- "PA"

PA_ANNOUNCEMENT_URL <-
  "https://www.pa.gov/agencies/dhs/newsroom/supporting-rural-health-care"
PA_PROJECTS_URL <- paste0(
  "https://www.pa.gov/agencies/dhs/programs-services/healthcare/rural-health/",
  "rural-health-selected-projects"
)

PA_ANNOUNCEMENT_FILE <- "2026-07-23_dhs_supporting_rural_health_care.html"
PA_PROJECTS_FILE     <- "2026-08-28_dhs_rural_health_selected_projects.html"
PA_MANIFEST_FILE     <- "pa_rhtp_year1_awards.manifest.txt"

PA_EVIDENCE_DIR <- "data/evidence/PA"
PA_CSV  <- "data/reference/pa_year1_awardees.csv"
PA_XLSX <- "PA_year1_awardees.xlsx"

# What DHS itself states, and what this file must reproduce or fail. Held as
# constants so an assertion can name the published figure rather than a literal
# buried in a comparison (§13 asserts against the state's own words).
PA_STATED_PROJECT_COUNT <- 66L
PA_STATED_TRANCHE_TOTAL <- 42198309      # "$42,198,309"
PA_STATED_YEAR1_AWARD   <- 193294053.98  # the CMS award named in the footnote


# -- Fetch and archive -------------------------------------------------------

#' Fetch both Pennsylvania sources and archive them with SHA-256
#'
#' Parses BEFORE writing, so a page redesign fails loudly instead of replacing a
#' good archive with an unparseable one -- the R/00 posture.
rhtp_pa_fetch <- function(force = FALSE) {
  cfg <- rhtp_config()
  dir <- here::here(PA_EVIDENCE_DIR)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)

  get_one <- function(url, file) {
    path <- file.path(dir, file)
    if (file.exists(path) && !force) {
      message("  already archived: ", file, " -- pass --force to re-fetch.")
      return(list(path = path, body = readr::read_file(path), status = NA_integer_))
    }
    resp <- httr2::request(url) %>%
      httr2::req_user_agent(cfg$api$user_agent) %>%
      httr2::req_timeout(cfg$api$timeout_seconds) %>%
      httr2::req_retry(max_tries = 3, backoff = ~ 2^.x) %>%
      httr2::req_perform()

    status <- httr2::resp_status(resp)
    if (status != 200) {
      stop("[PA] ", url, " returned HTTP ", status,
           "; refusing to archive a non-200 body.", call. = FALSE)
    }
    list(path = path, body = httr2::resp_body_string(resp), status = status)
  }

  announcement <- get_one(PA_ANNOUNCEMENT_URL, PA_ANNOUNCEMENT_FILE)
  projects     <- get_one(PA_PROJECTS_URL, PA_PROJECTS_FILE)

  parsed <- rhtp_pa_parse_projects(projects$body)
  if (nrow(parsed) != PA_STATED_PROJECT_COUNT) {
    stop("[PA] the selected-projects table parsed to ", nrow(parsed),
         " rows; DHS states ", PA_STATED_PROJECT_COUNT,
         ". Refusing to archive a parse that does not match the state's own ",
         "count.", call. = FALSE)
  }

  # writeBin, not writeLines. writeLines appends a trailing newline, which makes
  # the archived file one byte longer than the body that was digested -- so the
  # manifest's sha256 would not verify against the file a reader has in hand.
  # Writing the bytes exactly is what makes the digest checkable offline, and a
  # test does check it.
  writeBin(charToRaw(announcement$body), announcement$path)
  writeBin(charToRaw(projects$body), projects$path)

  sha <- function(x) digest::digest(x, algo = "sha256", serialize = FALSE)
  nbytes <- function(x) nchar(x, type = "bytes")

  writeLines(paste0(
    "RHTP tracker archive (spec 0.4 / 0.5): Pennsylvania RHTP Year 1, first\n",
    "tranche of authorized projects.\n\n",
    "fetched_utc     : ", format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), "\n",
    "state           : PA\n",
    "host            : www.pa.gov\n",
    "program         : Pennsylvania Rural Health Transformation Plan (RHTP)\n",
    "cms_year1_award : $193,294,053.98 (stated in the announcement's footnote)\n",
    "tranche_total   : $42,198,309 stated; $42,198,309.80 summed from the table\n",
    "projects        : ", PA_STATED_PROJECT_COUNT, " stated; ", nrow(parsed), " parsed\n\n",
    "FILES\n\n",
    "  file    : ", PA_ANNOUNCEMENT_FILE, "\n",
    "  role    : the AWARD LANGUAGE and the state total. Names no recipient.\n",
    "  title   : Supporting Rural Health Care: Shapiro Administration Announces\n",
    "            $42 Million to Support Technology and Infrastructure\n",
    "            Improvements, Upgrades for Rural Hospitals, Emergency\n",
    "            Medicine, and Health Care Providers\n",
    "  date    : 2026-07-23\n",
    "  url     : ", PA_ANNOUNCEMENT_URL, "\n",
    "  bytes   : ", nbytes(announcement$body), "\n",
    "  sha256  : ", sha(announcement$body), "\n\n",
    "  file    : ", PA_PROJECTS_FILE, "\n",
    "  role    : the 66 RECIPIENT NAMES and AMOUNTS. Supplies no award\n",
    "            language of its own -- its heading reads 'List of Eligible\n",
    "            Projects'.\n",
    "  title   : Rural Health Selected Projects\n",
    "  url     : ", PA_PROJECTS_URL, "\n",
    "  bytes   : ", nbytes(projects$body), "\n",
    "  sha256  : ", sha(projects$body), "\n\n",
    "WHAT THESE DOCUMENTS SUPPORT (spec 9.2, Part A of reviewer-coding-instructions)\n\n",
    "NEITHER DOCUMENT SUPPORTS THE CODING ALONE, and this is the same shape as\n",
    "Georgia's AHEAD roster (session 10). The program page read by itself is an\n",
    "ELIGIBILITY list, and §0.3 forbids coding eligibility as receipt. The\n",
    "announcement read by itself names no recipient. Together the announcement\n",
    "says sixty-six projects were AUTHORIZED to RECEIVE the money and links to\n",
    "this page as the list of them. Every row cites both.\n\n",
    "THESE ARE AUTHORIZATIONS, NOT DISBURSEMENTS. The announcement states\n",
    "'Distribution is pending approval of selected projects.' Rows therefore\n",
    "carry validation_source_type = NOTICE_OF_INTENT_TO_AWARD and\n",
    "disbursement_status = PENDING_APPROVAL. Both intent-to-award and award are\n",
    "primary under §8; the distinction belongs in the row, not flattened away.\n\n",
    "This tranche is the FIRST of Pennsylvania's $193,294,053.98 Year 1 award.\n",
    "$42.2M of $193.3M is 21.8%; the remainder is not yet awarded and no residual\n",
    "may be inferred from it (§0.3).\n"
  ), file.path(dir, PA_MANIFEST_FILE))

  message("  archived 2 Pennsylvania sources to ", PA_EVIDENCE_DIR,
          " (", nrow(parsed), " projects parsed)")
  invisible(dir)
}


# -- Parse -------------------------------------------------------------------

#' Parse the DHS selected-projects table out of archived HTML
#'
#' The page carries exactly one <table>. That is asserted rather than assumed:
#' picking "the first table" on a page that later grows a second one is how a
#' parser silently reads the wrong thing (the session 10 lesson).
rhtp_pa_parse_projects <- function(html) {
  doc <- rvest::read_html(html)
  tables <- rvest::html_elements(doc, "table")

  if (length(tables) != 1L) {
    stop("[PA] expected exactly 1 table on the selected-projects page, found ",
         length(tables), ". Refusing to guess which one holds the awards.",
         call. = FALSE)
  }

  raw <- rvest::html_table(tables[[1]], header = TRUE, trim = TRUE)

  wanted <- c("Name", "Total", "Project Description", "Region", "Initiative")
  if (!identical(names(raw), wanted)) {
    stop("[PA] the selected-projects table's columns are ",
         paste(sQuote(names(raw)), collapse = ", "),
         "; expected ", paste(sQuote(wanted), collapse = ", "),
         ". Refusing to map columns by position.", call. = FALSE)
  }

  raw %>%
    dplyr::rename(
      awardee = "Name",
      amount_raw = "Total",
      project_description = "Project Description",
      region = "Region",
      initiative_raw = "Initiative"
    ) %>%
    dplyr::mutate(
      dplyr::across(dplyr::everything(),
                    ~ stringr::str_squish(stringr::str_replace_all(.x, " ", " "))),
      amount = readr::parse_number(.data$amount_raw)
    ) %>%
    dplyr::filter(nzchar(.data$awardee))
}


#' The Pennsylvania award records, built from the committed archives
rhtp_pa_build <- function() {
  projects_path <- here::here(PA_EVIDENCE_DIR, PA_PROJECTS_FILE)
  if (!file.exists(projects_path)) {
    stop("[PA] the selected-projects archive is missing: ", projects_path,
         ". Run --fetch first.", call. = FALSE)
  }

  parsed <- rhtp_pa_parse_projects(readr::read_file(projects_path))

  classified <- parsed %>%
    rhtp_classify_records(state = PA_STATE,
                          description_col = "project_description")

  classified %>%
    dplyr::mutate(
      state = PA_STATE,
      row_no = dplyr::row_number(),
      note = paste0(.data$initiative_raw, " | ", .data$region, " region"),
      recipient_confirmed = "Yes",
      amount_confirmed = "Yes",
      fiscal_year = "FY2026 (Year 1)",
      source_document_title = paste0(
        "Supporting Rural Health Care: Shapiro Administration Announces $42 ",
        "Million to Support Technology and Infrastructure Improvements, ",
        "Upgrades for Rural Hospitals, Emergency Medicine, and Health Care ",
        "Providers"
      ),
      state_source_url = PA_ANNOUNCEMENT_URL,
      validation_source_type = "NOTICE_OF_INTENT_TO_AWARD",
      extraction_method = "MODEL_ASSISTED",
      validator = "AI-assisted - CONFIRM",
      ccn = NA_character_,
      aha_id = NA_character_,
      rural_designation = NA_character_,
      reviewer = NA_character_,
      recipient_type_source = NA_character_,
      amount_basis = "PER_RECIPIENT",
      amount_precision = "EXACT_AS_PUBLISHED",
      disbursement_status = "PENDING_APPROVAL",
      source_archive_path = file.path(PA_EVIDENCE_DIR, PA_ANNOUNCEMENT_FILE),
      recipient_names_source_url = PA_PROJECTS_URL,
      activity_type_raw = .data$initiative_raw,
      determination_basis = paste0(
        .data$determination_basis,
        " Source: PA DHS announced 66 authorized projects on 2026-07-23; the ",
        "names and amounts are from the DHS Rural Health Selected Projects ",
        "page it links to. Distribution is pending approval of selected ",
        "projects, so this is an intent to award."
      )
    ) %>%
    dplyr::select(
      # -- the FL_year1_awardees schema, in FL's order --------------------
      "state", "row_no", "awardee", "amount", "recipient_type",
      "distributed_to_hospital", "note", "recipient_confirmed",
      "amount_confirmed", "fiscal_year", "source_document_title",
      "state_source_url", "validation_source_type", "extraction_method",
      "validator", "ccn", "aha_id", "rural_designation", "reviewer",
      "recipient_type_source", "determination_confidence", "flag_reason",
      # -- appended, on the Georgia precedent ----------------------------
      "flow_type", "hospital_benefiting", "determination_basis",
      "source_archive_path", "recipient_names_source_url", "amount_basis",
      "amount_precision", "disbursement_status", "classification_rule",
      "activity_type_raw",
      # -- Pennsylvania's own fields -------------------------------------
      "region", "initiative_raw", "project_description"
    )
}


rhtp_pa_records <- function(path = PA_CSV) {
  full <- here::here(path)
  if (!file.exists(full)) {
    stop("[PA] ", path, " does not exist. Run --build.", call. = FALSE)
  }
  readr::read_csv(full, show_col_types = FALSE, progress = FALSE)
}


# -- Reconciliation and assertions -------------------------------------------

rhtp_pa_reconcile <- function(records = rhtp_pa_build()) {
  summed <- sum(records$amount)
  tibble::tribble(
    ~measure,                                  ~value,
    "projects stated by DHS",                  as.character(PA_STATED_PROJECT_COUNT),
    "projects extracted",                      as.character(nrow(records)),
    "distinct awardees",                       as.character(dplyr::n_distinct(records$awardee)),
    "tranche total stated by DHS",             format(PA_STATED_TRANCHE_TOTAL, big.mark = ",", nsmall = 2),
    "tranche total summed from the table",     format(summed, big.mark = ",", nsmall = 2),
    "difference",                              format(summed - PA_STATED_TRANCHE_TOTAL, nsmall = 2),
    "CMS Year 1 award",                        format(PA_STATED_YEAR1_AWARD, big.mark = ",", nsmall = 2),
    "this tranche as a share of Year 1",       paste0(round(100 * summed / PA_STATED_YEAR1_AWARD, 2), "%"),
    "rows distributed_to_hospital = Yes",      as.character(sum(records$distributed_to_hospital == "Yes")),
    "dollars distributed_to_hospital = Yes",   format(sum(records$amount[records$distributed_to_hospital == "Yes"]), big.mark = ",", nsmall = 2),
    "rows distributed_to_hospital = Unclear",  as.character(sum(records$distributed_to_hospital == "Unclear")),
    "dollars distributed_to_hospital = Unclear", format(sum(records$amount[records$distributed_to_hospital == "Unclear"]), big.mark = ",", nsmall = 2)
  )
}


rhtp_pa_assert <- function(records = rhtp_pa_build()) {
  stopifnot(nrow(records) == PA_STATED_PROJECT_COUNT)

  if (dplyr::n_distinct(records$awardee) != nrow(records)) {
    dupes <- records$awardee[duplicated(records$awardee)]
    stop("[PA] the table is one row per recipient and must stay that way; ",
         "duplicated: ", paste(unique(dupes), collapse = "; "), call. = FALSE)
  }

  # The stated total is a whole dollar and the table's own cents sum to $0.80
  # more. Asserting to the dollar keeps the check meaningful without pretending
  # DHS published cents.
  summed <- sum(records$amount)
  if (abs(summed - PA_STATED_TRANCHE_TOTAL) > 1) {
    stop("[PA] the table sums to ", format(summed, nsmall = 2),
         " against DHS's stated ", PA_STATED_TRANCHE_TOTAL,
         ". A gap larger than rounding means the parse or the page changed.",
         call. = FALSE)
  }

  if (any(records$amount <= 0)) {
    stop("[PA] every project must carry a positive amount.", call. = FALSE)
  }
  # DHS states "up to $1 million was available per project".
  if (any(records$amount > 1e6)) {
    over <- records$awardee[records$amount > 1e6]
    stop("[PA] amounts above the stated $1,000,000 per-project cap: ",
         paste(over, collapse = "; "), call. = FALSE)
  }

  # §0.2: Tier 3 must never exceed the state's Tier 1 allotment.
  if (summed > PA_STATED_YEAR1_AWARD) {
    stop("[PA] the tranche exceeds the CMS Year 1 award. §6.2 ceiling.",
         call. = FALSE)
  }

  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "determination_confidence", "flag_reason")) {
    bad <- setdiff(stats::na.omit(unique(records[[col]])), rhtp_vocabulary(col))
    if (length(bad)) {
      stop("[PA] ", col, " outside §8: ", paste(bad, collapse = ", "),
           call. = FALSE)
    }
  }

  # §10.2: only a hospital recipient may be coded DIRECT/Yes.
  wrong <- records %>%
    dplyr::filter(.data$distributed_to_hospital == "Yes",
                  !.data$recipient_type %in% c("HOSPITAL_OR_SYSTEM",
                                               "HOSPITAL_AFFILIATED_ENTITY"))
  if (nrow(wrong)) {
    stop("[PA] distributed_to_hospital = Yes on a non-hospital recipient: ",
         paste(wrong$awardee, collapse = "; "), call. = FALSE)
  }

  if (any(is.na(records$determination_basis) |
          !nzchar(records$determination_basis))) {
    stop("[PA] determination_basis is mandatory free text (§7).", call. = FALSE)
  }

  invisible(TRUE)
}


# -- Write -------------------------------------------------------------------

rhtp_pa_write <- function() {
  records <- rhtp_pa_build()
  rhtp_pa_assert(records)

  readr::write_csv(records, here::here(PA_CSV), na = "")

  wb <- openxlsx::createWorkbook()
  add <- function(sheet, data) {
    openxlsx::addWorksheet(wb, sheet)
    openxlsx::writeData(wb, sheet, data)
    openxlsx::freezePane(wb, sheet, firstRow = TRUE)
  }
  add("Awardees", records)
  add("Reconciliation", rhtp_pa_reconcile(records))
  openxlsx::saveWorkbook(wb, here::here(PA_XLSX), overwrite = TRUE)

  message("  wrote ", PA_CSV, " and ", PA_XLSX, " (", nrow(records), " rows)")
  invisible(records)
}


# -- CLI ---------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) {
    rhtp_pa_fetch(force = "--force" %in% args)
  } else if ("--build" %in% args) {
    rhtp_pa_write()
    print(rhtp_pa_reconcile(rhtp_pa_records()), n = Inf)
  } else if ("--validate" %in% args) {
    recs <- rhtp_pa_build()
    rhtp_pa_assert(recs)
    print(rhtp_pa_reconcile(recs), n = Inf)
    message("[PA] all assertions passed.")
  } else {
    message("Usage: Rscript R/03f_pa_year1_awardees.R [--fetch|--validate|--build]")
  }
}
