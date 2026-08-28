# 03e_fl_year1_awardees.R ----------------------------------------------------
# Florida Year 1 awardees -> data/reference/fl_year1_awardees.csv (+ a render).
#
# WHAT THIS IS FOR. The owner supplied FL_year1_awardees.xlsx: 81 Florida Year 1
# awards with recipient-level amounts, the first complete Deliverable 1 dataset
# and the answer to the §4.1 Florida gap. No stage read it, because two of its
# `recipient_type` values -- UNCLASSIFIED and PHYSICIAN_PRACTICE -- were outside
# the §8 controlled vocabulary, and §5 says every categorical column validates
# against that vocabulary. This file is what makes Florida ingestible.
#
# THE VOCABULARY QUESTION, SETTLED (session 10). Florida and Georgia had given
# two different answers to one question -- what `recipient_type` holds when the
# recipient is NAMED but its organisational form is not determinable from the
# source. Florida wrote UNCLASSIFIED; Georgia wrote NONPROFIT_CBO with a LOW
# confidence and a RECIPIENT_TYPE_INFERRED flag. Two answers to one question
# would split Stage 5's hospital determination, so the GEORGIA convention is
# adopted and Florida is back-fitted to it. Five rows move.
#
# PHYSICIAN_PRACTICE IS A DIFFERENT QUESTION, AND GREW THE VOCABULARY. Those
# eight rows are not undetermined -- a pediatrics group, a fetal medicine
# practice, a primary care clinic are all perfectly determinable, and none of
# the other twelve §8 values is true of one. Folding them into NONPROFIT_CBO
# would assert a form the source contradicts and would cost Stage 5 exactly the
# distinction the column exists to carry, so PHYSICIAN_PRACTICE was added to §8
# deliberately instead. All eight are already distributed_to_hospital = No, so
# no total moves either way.
#
# NOTHING ELSE IS RE-CODED. This is a vocabulary reconciliation, not a review of
# Florida's coding. `recipient_type_source` carries what the owner's workbook
# said on every row, so the back-fit is auditable and reversible (§8: never
# discard the source's own language).
#
# THE CSV IS THE SOURCE OF RECORD; the workbook at the repo root is a render of
# it, the same arrangement as R/03c. The owner's original upload is preserved at
# data/raw/owner_uploads/ with a SHA-256 manifest -- --ingest reads that, never
# the rendered copy, so re-running can never fold a render back on itself.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only -- never |>. No setwd(); all
# paths go through here::here(). Contains no network calls.
#
# CLI:
#   Rscript R/03e_fl_year1_awardees.R --ingest    # owner's workbook -> CSV
#   Rscript R/03e_fl_year1_awardees.R --validate  # assertions only, no writes
#   Rscript R/03e_fl_year1_awardees.R --build     # assert, then render the xlsx

suppressPackageStartupMessages({
  library(dplyr)
  library(openxlsx)
  library(readr)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))

FL_OWNER_WORKBOOK <-
  "data/raw/owner_uploads/FL_year1_awardees_original.xlsx"
FL_CSV <- "data/reference/fl_year1_awardees.csv"
FL_XLSX <- "FL_year1_awardees.xlsx"

# The one recipient_type value that moves, and what it becomes. Kept as a table
# rather than an if/else so the back-fit reads as data and a second entry is a
# data change, not a code change.
FL_RECIPIENT_TYPE_BACKFIT <- tibble::tribble(
  ~from,          ~to,             ~flag,                     ~confidence,
  "UNCLASSIFIED", "NONPROFIT_CBO", "RECIPIENT_TYPE_INFERRED", "LOW"
)

#' Ingest the owner's workbook into the committed CSV
#'
#' Applies the §8 back-fit and nothing else. Every other cell passes through.
rhtp_fl_ingest <- function(workbook = FL_OWNER_WORKBOOK) {
  full <- here::here(workbook)
  if (!file.exists(full)) {
    stop("[FL] the owner's workbook is missing: ", workbook,
         ". It is the ingest source and cannot be regenerated.", call. = FALSE)
  }

  raw <- openxlsx::read.xlsx(full, sheet = 1) %>% tibble::as_tibble()

  if (!nrow(raw)) stop("[FL] the owner's workbook parsed to zero rows.", call. = FALSE)
  for (col in c("state", "row_no", "awardee", "recipient_type",
                "distributed_to_hospital")) {
    if (!col %in% names(raw)) {
      stop("[FL] the owner's workbook has no `", col, "` column; found: ",
           paste(names(raw), collapse = ", "), call. = FALSE)
    }
  }

  out <- raw %>%
    dplyr::mutate(
      # openxlsx reads the stored string verbatim, and a few awardee names were
      # HTML-escaped on the way into the workbook ("Quintero &amp; Kontopoulos").
      # Unescaping is a transcription fix, not a re-coding.
      dplyr::across(dplyr::where(is.character), ~ stringr::str_replace_all(
        .x, c("&amp;" = "&", "&#39;" = "'", "&quot;" = '"', "&nbsp;" = " ")
      )),
      recipient_type_source = .data$recipient_type
    ) %>%
    dplyr::left_join(FL_RECIPIENT_TYPE_BACKFIT,
                     by = c("recipient_type_source" = "from")) %>%
    dplyr::mutate(
      recipient_type = dplyr::coalesce(.data$to, .data$recipient_type),
      flag_reason = .data$flag,
      # Florida's workbook carries no confidence column, so one is set only
      # where this file makes a judgement -- never invented for a row the owner
      # coded and this session did not touch.
      determination_confidence = .data$confidence
    ) %>%
    dplyr::select(-"to", -"flag", -"confidence")

  # Keep the owner's 19 columns in their order, then the three this file adds,
  # so Florida and Georgia still union on the leading block.
  owner_cols <- names(raw)
  out %>%
    dplyr::select(dplyr::all_of(owner_cols), "recipient_type_source",
                  "determination_confidence", "flag_reason")
}

rhtp_fl_records <- function(path = FL_CSV) {
  full <- here::here(path)
  if (!file.exists(full)) {
    stop("[FL] ", path, " does not exist. Run --ingest first.", call. = FALSE)
  }
  readr::read_csv(full, show_col_types = FALSE, progress = FALSE)
}

# --- assertions ------------------------------------------------------------

rhtp_fl_assert <- function(records = rhtp_fl_records()) {
  fail <- function(...) stop("[FL] ", ..., call. = FALSE)

  # 1. THE POINT OF THIS FILE. Every categorical column validates against the
  #    §8 vocabulary. Florida could not be ingested until this passed.
  for (col in c("recipient_type", "distributed_to_hospital",
                "recipient_confirmed", "amount_confirmed", "flag_reason",
                "determination_confidence")) {
    if (!col %in% names(records)) next
    allowed <- rhtp_vocabulary(col)
    bad <- setdiff(stats::na.omit(unique(records[[col]])), allowed)
    if (length(bad)) {
      fail("`", col, "` carries values outside the §8 vocabulary: ",
           paste(bad, collapse = ", "))
    }
  }

  # 2. The back-fit moved exactly the rows it was meant to, and no others.
  moved <- records %>%
    dplyr::filter(.data$recipient_type_source != .data$recipient_type)
  if (nrow(moved) != 5L) {
    fail("The recipient_type back-fit moved ", nrow(moved),
         " rows; the five UNCLASSIFIED rows are the whole of it.")
  }
  if (!all(moved$recipient_type_source == "UNCLASSIFIED") ||
      !all(moved$recipient_type == "NONPROFIT_CBO")) {
    fail("A row moved to or from a value the back-fit table does not name.")
  }
  if (!all(moved$flag_reason == "RECIPIENT_TYPE_INFERRED") ||
      !all(moved$determination_confidence == "LOW")) {
    fail("A back-fitted row is missing its RECIPIENT_TYPE_INFERRED flag or ",
         "its LOW confidence. The flag is what stops an inferred form reading ",
         "as a determined one.")
  }

  # 3. UNCLASSIFIED is gone, and nothing else was re-coded on the way past.
  if ("UNCLASSIFIED" %in% records$recipient_type) {
    fail("UNCLASSIFIED survives in recipient_type; it is not a §8 value.")
  }
  untouched <- records %>%
    dplyr::filter(is.na(.data$flag_reason) |
                    .data$flag_reason != "RECIPIENT_TYPE_INFERRED")
  if (any(untouched$recipient_type != untouched$recipient_type_source)) {
    fail("A row this file did not flag has a recipient_type differing from the ",
         "owner's. This is a vocabulary reconciliation, not a re-review.")
  }

  # 4. No confidence was invented for a row this session did not judge.
  if (any(!is.na(records$determination_confidence) &
          records$flag_reason != "RECIPIENT_TYPE_INFERRED")) {
    fail("determination_confidence is set on a row this file did not judge. ",
         "Florida's workbook carries no confidence column.")
  }

  # 5. The eight physician practices are still physician practices. Adding the
  #    code to §8 was the decision; quietly folding them in later would undo it.
  practices <- records %>%
    dplyr::filter(.data$recipient_type == "PHYSICIAN_PRACTICE")
  if (nrow(practices) != 8L) {
    fail("Florida has ", nrow(practices), " PHYSICIAN_PRACTICE rows; 8 expected.")
  }
  if (any(practices$distributed_to_hospital != "No")) {
    fail("A physician practice is coded as a distribution to a hospital.")
  }

  # 6. The ingest is faithful: the row count and every awardee still match the
  #    owner's workbook. A back-fit that dropped a row would be a data loss no
  #    vocabulary check would catch.
  owner <- openxlsx::read.xlsx(here::here(FL_OWNER_WORKBOOK), sheet = 1)
  if (nrow(records) != nrow(owner)) {
    fail("The CSV has ", nrow(records), " rows against the owner's ",
         nrow(owner), ".")
  }
  if (!setequal(records$row_no, owner$row_no)) {
    fail("The CSV's row_no set differs from the owner's workbook.")
  }

  # 7. Florida and Georgia union on the owner's leading column block, which is
  #    the reason that order is preserved.
  ga_path <- here::here("data", "reference", "ga_great_health_awards.csv")
  if (file.exists(ga_path)) {
    ga <- readr::read_csv(ga_path, show_col_types = FALSE, progress = FALSE)
    lead <- names(records)[seq_len(19)]
    if (!identical(lead, names(ga)[seq_len(19)])) {
      fail("Florida and Georgia no longer share their leading 19 columns, so ",
           "the two states stopped unioning. FL: ",
           paste(lead, collapse = ", "))
    }
    shared <- intersect(records$recipient_type, ga$recipient_type)
    if (!length(shared)) {
      fail("Florida and Georgia share no recipient_type value at all, which ",
           "means one of them is not on the §8 vocabulary.")
    }
  }

  invisible(TRUE)
}

# --- build -----------------------------------------------------------------

rhtp_fl_write_csv <- function() {
  records <- rhtp_fl_ingest()
  readr::write_csv(records, here::here(FL_CSV), na = "")
  message("[FL] ingested ", nrow(records), " award actions -> ", FL_CSV)
  invisible(records)
}

rhtp_fl_write <- function() {
  records <- rhtp_fl_records()
  rhtp_fl_assert(records)

  by_type <- records %>%
    dplyr::count(.data$recipient_type, name = "award_actions") %>%
    dplyr::arrange(dplyr::desc(.data$award_actions))

  hospitals <- records %>%
    dplyr::filter(.data$distributed_to_hospital == "Yes")

  backfit <- records %>%
    dplyr::filter(.data$flag_reason %in% "RECIPIENT_TYPE_INFERRED") %>%
    dplyr::select("row_no", "awardee", "recipient_type_source",
                  "recipient_type", "determination_confidence", "flag_reason")

  wb <- openxlsx::createWorkbook()
  hdr <- openxlsx::createStyle(textDecoration = "bold", halign = "left")
  money <- openxlsx::createStyle(numFmt = "#,##0")

  add <- function(name, df, money_cols = character()) {
    openxlsx::addWorksheet(wb, name)
    openxlsx::writeData(wb, name, df, headerStyle = hdr)
    for (mc in intersect(money_cols, names(df))) {
      openxlsx::addStyle(wb, name, money, rows = 2:(nrow(df) + 1),
                         cols = which(names(df) == mc), gridExpand = TRUE)
    }
    openxlsx::freezePane(wb, name, firstActiveRow = 2)
    openxlsx::setColWidths(wb, name, cols = seq_along(df), widths = "auto")
  }

  add(paste0("Awardees (", nrow(records), ")"), records, "amount")
  add("By recipient type", by_type)
  add(paste0("Hospitals (", nrow(hospitals), ")"), hospitals, "amount")
  add("Recipient type back-fit", backfit)

  openxlsx::saveWorkbook(wb, here::here(FL_XLSX), overwrite = TRUE)
  message("[FL] wrote ", nrow(records), " award actions")
  message("[FL]   ", FL_CSV)
  message("[FL]   ", FL_XLSX)
  invisible(records)
}

# --- CLI -------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--ingest" %in% args) {
    rhtp_fl_write_csv()
    rhtp_fl_assert()
    message("[FL] all assertions pass.")
  } else if ("--build" %in% args) {
    rhtp_fl_write()
  } else if ("--validate" %in% args) {
    recs <- rhtp_fl_records()
    rhtp_fl_assert(recs)
    message("[FL] ", nrow(recs), " award actions; all assertions pass.")
    print(recs %>% dplyr::count(recipient_type, name = "award_actions") %>%
            dplyr::arrange(dplyr::desc(award_actions)), n = Inf)
  } else {
    message("Usage: Rscript R/03e_fl_year1_awardees.R [--ingest | --validate | --build]")
  }
}
