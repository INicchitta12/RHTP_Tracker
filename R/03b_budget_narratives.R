# 03b_budget_narratives.R ---------------------------------------------------
# Stage 2.5 — state RHTP budget narratives into the initiative table (§7A).
#
# This is the backbone (§0.1). RCJ has an unbounded completeness problem; the
# narratives do not. CMS required one from every state, so fifty documents
# cover the full $10B, and they reconcile against the §7.1 allotment anchor —
# which means the parse self-validates. That gate is §7A.4 and it is the whole
# reason this stage sits ahead of Stage 4.
#
# WHY THIS IS A FORMAT-DETECTING PARSER AND NOT TWO READERS
#
# The two committed reference extractions are shaped differently on purpose:
#
#   OK_initiative_table.xlsx  sheet "Fund uses (28)"    28 fund uses under 6
#                             initiatives, one row per fund use, a Lead Agency
#                             named on every single one, amount in `amount_bp1`.
#
#   DE_initiative_table.xlsx  sheet "Initiatives (Y1)"  15 initiatives (14 rows,
#                             two share initiative_no 0), recipients TBD on 11
#                             of them, amount in `amount_y1`, no lead-agency
#                             column at all.
#
# Different sheet names, different column names, different grain, different
# recipient column, and one carries `extraction_method` while the other does
# not. §7A.1 is explicit: "Assume format variation is the norm." So the parser
# resolves columns by synonym against the §7A.3 canonical schema, scores every
# sheet in the workbook, and picks the best — and REFUSES rather than guesses
# when two sheets tie or when the required minimum is unresolvable. A silent
# mis-mapping here would put a wrong dollar figure under a right initiative
# name, which is worse than no parse at all.
#
# WHAT THIS STAGE DOES NOT DO
#
# It does not re-derive `has_hospital_recipient`. That is a human coding call
# under Part B of reviewer-coding-instructions.md, keyed on the recipient
# (§0.3a) and often on flow language where no recipient is named at all. The
# parser carries the coded value through and asserts it against the §10.2
# flow table; it never invents one.
#
# It does not divide an initiative budget across recipients. States do not
# publish the split and inventing one would be the most damaging thing this
# project could do (§7A.5).
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only — never |>. No setwd();
# all paths go through here::here(). Contains no network calls, spends no
# RCJ quota.
#
# CLI:
#   Rscript R/03b_budget_narratives.R --validate   # parse + assert, no writes
#   Rscript R/03b_budget_narratives.R --build      # parse, assert, reconcile, write

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(readr)
  library(stringr)
  library(tibble)
  library(tidyr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "03_state_registry.R"))


# -- The §7A.3 canonical schema --------------------------------------------

# Every parsed workbook lands in exactly these columns, in this order, whatever
# it looked like on disk. Columns a given state's workbook cannot supply are
# carried as NA rather than dropped, so the shape is stable across states and
# a missing field is visible as a gap instead of as an absent column.
RHTP_INITIATIVE_SCHEMA <- c(
  "state",
  "initiative_id",
  "initiative_no_source",
  "initiative_name",
  "initiative_group",
  "initiative_budget",
  "activity_type",
  "activity_type_raw",
  "initiative_description",
  "named_recipient_or_contractor",
  "recipient_status",
  "flow_type",
  "has_hospital_recipient",
  "evidence_from_document",
  "budget_narrative_version",
  "source_document",
  "source_archive_path",
  "page_reference",
  "extraction_method",
  "initiative_grain",
  "source_workbook",
  "source_sheet"
)

# Fields without which a sheet is not an initiative table. Everything else is
# optional, because §7A.5 warns that a parser requiring named recipients will
# fail on most states.
RHTP_INITIATIVE_REQUIRED <- c("initiative_name", "initiative_budget")


# -- Column resolution ------------------------------------------------------

# Ordered synonyms per canonical field. First match wins, so put the most
# specific pattern first. Matched against snake_cased column names.
#
# `initiative_name` deliberately prefers `fund_use` over `initiative`: in the
# Oklahoma workbook `initiative` is the six-way grouping and `fund_use` is the
# row's own identity, so mapping `initiative` here would collapse 28 rows onto
# 6 names. The grouping is kept separately as `initiative_group`.
RHTP_NARRATIVE_SYNONYMS <- list(
  state = c("^state$", "^state_code$", "^st$"),
  initiative_no_source = c("^initiative_no$", "^initiative_number$", "^no$",
                           "^row_no$", "^line_no$"),
  initiative_name = c("^fund_use$", "^initiative_name$", "^fund_use_name$",
                      "^project$", "^program$", "^initiative$", "^line$",
                      "^activity$", "^use_of_funds$"),
  initiative_group = c("^initiative$", "^initiative_group$", "^goal$",
                       "^pillar$", "^strategy$"),
  initiative_budget = c("^amount_bp1$", "^amount_y1$", "^initiative_budget$",
                        "^amount$", "^budget$", "^total$", "^allocation$",
                        "^amount_.*$", "^budget_.*$"),
  activity_type = c("^activity_type$", "^cms_category$", "^allowable_use$"),
  activity_type_raw = c("^activity_type_raw$", "^activity_raw$",
                        "^state_activity$"),
  initiative_description = c("^initiative_description$", "^description$",
                             "^narrative$", "^detail$"),
  named_recipient_or_contractor = c("^named_recipient_or_contractor$",
                                    "^named_recipient$", "^lead_agency$",
                                    "^recipient$", "^contractor$",
                                    "^subrecipient$", "^awardee$",
                                    "^lead_entity$", "^administering_agency$"),
  recipient_status = c("^recipient_status$", "^recipient_state$"),
  flow_type = c("^flow_type$", "^flow$"),
  has_hospital_recipient = c("^has_hospital_recipient$", "^hospital_directed$",
                             "^hospital_recipient$"),
  evidence_from_document = c("^evidence_from_document$", "^evidence$",
                             "^supporting_sentence$", "^quote$"),
  budget_narrative_version = c("^budget_narrative_version$", "^version$",
                               "^revision$"),
  source_document = c("^source_document$", "^source_doc$", "^document$",
                      "^source$"),
  source_archive_path = c("^source_archive_path$", "^archive_path$"),
  page_reference = c("^page_reference$", "^page$", "^page_no$", "^pp$"),
  extraction_method = c("^extraction_method$", "^extraction$", "^method$")
)

# `lead_agency_type` and `budget_period` are read but do not map into the
# canonical schema: the first is a recipient_type claim about an intermediary
# (Stage 5's job, §10.1) and the second describes the whole workbook, not the
# row. Both are preserved in the per-state provenance record instead.


#' Snake-case a column name the way this parser expects to see it
#'
#' @param x A character vector of column names.
#' @return A character vector.
rhtp_narrative_normalise_name <- function(x) {
  x %>%
    stringr::str_trim() %>%
    stringr::str_replace_all("[^A-Za-z0-9]+", "_") %>%
    stringr::str_replace_all("^_+|_+$", "") %>%
    stringr::str_to_lower()
}


#' Map a sheet's columns onto the §7A.3 canonical schema
#'
#' Each canonical field claims the first column matching one of its synonyms,
#' and a column can only be claimed once — so `initiative` cannot serve as both
#' `initiative_name` and `initiative_group`.
#'
#' @param cols Character vector of the sheet's column names, as read.
#' @return A list: `mapping` (named character, canonical -> actual column),
#'   `unmapped_columns`, and `score` (count of canonical fields resolved).
rhtp_narrative_resolve_columns <- function(cols) {
  normalised <- rhtp_narrative_normalise_name(cols)
  claimed <- rep(FALSE, length(cols))
  mapping <- character(0)

  for (field in names(RHTP_NARRATIVE_SYNONYMS)) {
    hit <- NA_integer_

    for (pattern in RHTP_NARRATIVE_SYNONYMS[[field]]) {
      candidates <- which(!claimed & stringr::str_detect(normalised, pattern))
      if (length(candidates) > 0) {
        hit <- candidates[1]
        break
      }
    }

    if (!is.na(hit)) {
      mapping[[field]] <- cols[hit]
      claimed[hit] <- TRUE
    }
  }

  list(
    mapping = mapping,
    unmapped_columns = cols[!claimed],
    score = length(mapping)
  )
}


#' Choose which sheet of a workbook is the initiative table
#'
#' Scores every sheet by how many canonical fields resolve, requires the
#' §7A.3 minimum, and requires the amount column to actually be numeric — a
#' summary sheet whose "amount" column is a formatted string is not the table.
#'
#' Refuses on a tie. Two sheets scoring identically means the parser cannot
#' tell which one holds the initiatives, and guessing would silently publish
#' the wrong one.
#'
#' @param path Path to the workbook.
#' @return A list: `sheet`, `mapping`, `score`, `all_scores`.
rhtp_narrative_pick_sheet <- function(path) {
  sheets <- readxl::excel_sheets(path)

  assessed <- purrr::map(sheets, function(sheet) {
    peek <- suppressWarnings(
      readxl::read_excel(path, sheet = sheet, n_max = 200, .name_repair = "minimal")
    )

    if (ncol(peek) == 0 || nrow(peek) == 0) {
      return(list(sheet = sheet, score = 0L, mapping = character(0),
                  reason = "empty sheet"))
    }

    resolved <- rhtp_narrative_resolve_columns(names(peek))
    missing <- setdiff(RHTP_INITIATIVE_REQUIRED, names(resolved$mapping))

    if (length(missing) > 0) {
      return(list(sheet = sheet, score = 0L, mapping = resolved$mapping,
                  reason = paste0("no ", paste(missing, collapse = " / "))))
    }

    amounts <- peek[[resolved$mapping[["initiative_budget"]]]]
    if (!is.numeric(amounts) || all(is.na(amounts))) {
      return(list(sheet = sheet, score = 0L, mapping = resolved$mapping,
                  reason = "amount column is not numeric"))
    }

    list(sheet = sheet, score = resolved$score, mapping = resolved$mapping,
         reason = NA_character_)
  })

  scores <- purrr::map_int(assessed, "score")
  best <- max(scores)

  if (best == 0L) {
    stop(
      "No sheet in '", basename(path), "' resolves as an initiative table.\n",
      paste0("  ", purrr::map_chr(assessed, "sheet"), ": ",
             purrr::map_chr(assessed, ~ dplyr::coalesce(.x$reason, "ok")),
             collapse = "\n"), "\n",
      "§7A.3 needs at least an initiative name and a numeric budget. Add the ",
      "workbook's column names to RHTP_NARRATIVE_SYNONYMS rather than renaming ",
      "the workbook — the next state will be shaped differently again (§7A.1).",
      call. = FALSE
    )
  }

  winners <- which(scores == best)

  if (length(winners) > 1) {
    stop(
      "Ambiguous initiative table in '", basename(path), "': sheets ",
      paste0("'", purrr::map_chr(assessed[winners], "sheet"), "'", collapse = " and "),
      " score identically (", best, " fields resolved).\n",
      "Refusing to guess. Name the intended sheet explicitly via the `sheet` ",
      "argument to rhtp_parse_narrative_workbook().",
      call. = FALSE
    )
  }

  chosen <- assessed[[winners]]

  list(
    sheet = chosen$sheet,
    mapping = chosen$mapping,
    score = chosen$score,
    all_scores = stats::setNames(scores, purrr::map_chr(assessed, "sheet"))
  )
}


# -- Derivations ------------------------------------------------------------

# An explicit statement that the recipient is not resolved. Narrower than the
# §6.1 program-name table on purpose: `\bprogram\b`, `\bfund\b` and
# `\binitiative\b` all appear inside real organisation names, and here the
# question is only whether the state said "we have not picked anyone yet".
RHTP_RECIPIENT_TBD_RE <- paste0(
  "\\bTBD\\b|\\bto be (determined|named|announced|selected|identified)\\b|",
  "\\bnot yet (determined|named|announced|selected|identified)\\b|",
  "\\bnot identified\\b|\\bunnamed\\b|\\bunspecified\\b|\\bforthcoming\\b"
)

#' Infer `recipient_status` where a workbook does not carry it
#'
#' §7A.3 defines it as NAMED | NAMED + TBD | TBD. Oklahoma has no such column —
#' it names a Lead Agency on all 28 fund uses — so it has to be derived, while
#' Delaware carries one and keeps it (the workbook's own column always wins).
#'
#' Three steps, and the order matters:
#'
#'   1. Strip quoted spans. Both reference workbooks quote award-PROGRAM labels
#'      — "'3 Rural Provider/FQHC Readiness Awards' - recipients TBD",
#'      "'Lead Partner Institution' - accredited medical school, TBD". Those
#'      are programmes, not recipients, and reading them as names is the §6.1
#'      PROGRAM_NAME_AS_AWARDEE error and the §0.3 error at once.
#'   2. Strip the TBD phrases themselves.
#'   3. Ask whether two consecutive capitalised words survive. A proper
#'      organisation name almost always has them ("Delaware State Housing
#'      Authority", "Oklahoma Health Care Authority"); a recipient *class* does
#'      not ("Contractor TBD", "Technology vendor(s) TBD").
#'
#' Deliberately conservative: a single-token organisation name ("CareerTech",
#' "Bayhealth") derives as TBD rather than NAMED. Under-claiming a recipient is
#' the safe direction (§0.3, eligibility is not receipt); over-claiming is how
#' a programme label becomes an awardee.
#'
#' Reproduces Delaware's hand coding on all 14 of its rows, which is the only
#' fidelity check available — see tests/testthat/test_03b_budget_narratives.R.
#'
#' @param recipient Character vector of recipient text.
#' @return A character vector of `recipient_status` values.
rhtp_derive_recipient_status <- function(recipient) {
  txt <- dplyr::coalesce(recipient, "")

  has_tbd <- stringr::str_detect(
    txt, stringr::regex(RHTP_RECIPIENT_TBD_RE, ignore_case = TRUE)
  )

  residue <- txt %>%
    stringr::str_remove_all("'[^']*'") %>%
    stringr::str_remove_all('"[^"]*"') %>%
    stringr::str_remove_all(stringr::regex(RHTP_RECIPIENT_TBD_RE, ignore_case = TRUE))

  # Two capitalised words, optionally with lowercase connectors between them so
  # "University of Oklahoma" and "Delaware Division of Libraries" both count.
  proper_name_re <- paste0(
    "\\b[A-Z][A-Za-z&'.-]*",
    "(\\s+(of|the|and|for|at|in|on|de|la|del|und|&))*",
    "\\s+[A-Z][A-Za-z&'.-]*"
  )

  names_somebody <- stringr::str_detect(residue, proper_name_re)

  dplyr::case_when(
    names_somebody & has_tbd ~ "NAMED + TBD",
    names_somebody           ~ "NAMED",
    TRUE                     ~ "TBD"
  )
}


#' Pull a version token out of a source-document string
#'
#' Delaware: "Final-RHTP-Revised-Budget-1.30.26.pdf" -> "Revised 1.30.26".
#' Oklahoma: "RHTP_InitiativeFundingSummary.pdf (Updated 03.10.26)" ->
#' "Updated 03.10.26". Anything else returns NA rather than a guess — §7A.3
#' wants a version a reviewer can match against the archived PDF, and a
#' fabricated one is worse than a blank.
#'
#' @param source_document Character vector.
#' @return A character vector.
rhtp_derive_narrative_version <- function(source_document) {
  txt <- dplyr::coalesce(source_document, "")

  date_re <- "[0-9]{1,2}[.\\-/][0-9]{1,2}[.\\-/][0-9]{2,4}"
  labelled <- stringr::str_match(
    txt,
    stringr::regex(paste0("(Revised|Updated|Rev|Revision|Final)[^0-9]{0,12}(", date_re, ")"),
                   ignore_case = TRUE)
  )

  out <- dplyr::if_else(
    !is.na(labelled[, 1]),
    paste(stringr::str_to_title(labelled[, 2]), labelled[, 3]),
    NA_character_
  )

  out[txt == ""] <- NA_character_
  out
}


#' Where a state's archived budget narrative should live (§7A.2)
#'
#' @param state Two-letter state code.
#' @param document Source document file name, or NA.
#' @return Path if the archive exists, otherwise NA.
rhtp_narrative_archive_path <- function(state, document) {
  purrr::map2_chr(state, document, function(st, doc) {
    if (is.na(st) || is.na(doc)) return(NA_character_)

    candidate <- here::here("data", "evidence", "budget_narratives", st, basename(doc))
    if (file.exists(candidate)) candidate else NA_character_
  })
}


# -- Parse ------------------------------------------------------------------

#' Parse one budget-narrative extraction workbook into the canonical schema
#'
#' @param path Path to the workbook.
#' @param sheet Sheet name. Omit to auto-detect (the normal case).
#' @param state Two-letter code. Omit to take it from the workbook's `state`
#'   column, falling back to the file-name prefix.
#' @return A tibble with the [RHTP_INITIATIVE_SCHEMA] columns.
rhtp_parse_narrative_workbook <- function(path, sheet = NULL, state = NULL) {
  if (!file.exists(path)) {
    stop("Budget-narrative workbook not found at '", path, "'.", call. = FALSE)
  }

  picked <- if (is.null(sheet)) {
    rhtp_narrative_pick_sheet(path)
  } else {
    peek <- suppressWarnings(
      readxl::read_excel(path, sheet = sheet, n_max = 1, .name_repair = "minimal")
    )
    resolved <- rhtp_narrative_resolve_columns(names(peek))
    list(sheet = sheet, mapping = resolved$mapping, score = resolved$score)
  }

  raw <- suppressWarnings(
    readxl::read_excel(path, sheet = picked$sheet, .name_repair = "minimal")
  )

  mapping <- picked$mapping

  take <- function(field) {
    if (!field %in% names(mapping)) return(rep(NA, nrow(raw)))
    raw[[mapping[[field]]]]
  }

  parsed <- tibble::tibble(
    initiative_no_source   = as.character(take("initiative_no_source")),
    initiative_name        = as.character(take("initiative_name")),
    initiative_group       = as.character(take("initiative_group")),
    initiative_budget      = suppressWarnings(as.numeric(take("initiative_budget"))),
    activity_type          = as.character(take("activity_type")),
    activity_type_raw      = as.character(take("activity_type_raw")),
    initiative_description = as.character(take("initiative_description")),
    named_recipient_or_contractor = as.character(take("named_recipient_or_contractor")),
    recipient_status       = as.character(take("recipient_status")),
    flow_type              = as.character(take("flow_type")),
    has_hospital_recipient = as.character(take("has_hospital_recipient")),
    evidence_from_document = as.character(take("evidence_from_document")),
    budget_narrative_version = as.character(take("budget_narrative_version")),
    source_document        = as.character(take("source_document")),
    source_archive_path    = as.character(take("source_archive_path")),
    page_reference         = as.character(take("page_reference")),
    extraction_method      = as.character(take("extraction_method")),
    state_in_sheet         = as.character(take("state"))
  )

  # A wholly blank row is spreadsheet padding, not an initiative.
  parsed <- parsed %>%
    dplyr::filter(
      !is.na(.data$initiative_name) | !is.na(.data$initiative_budget)
    )

  resolved_state <- state
  if (is.null(resolved_state)) {
    from_sheet <- unique(stats::na.omit(parsed$state_in_sheet))
    resolved_state <- if (length(from_sheet) == 1) {
      from_sheet
    } else if (length(from_sheet) > 1) {
      stop(
        "'", basename(path), "' mixes ", length(from_sheet), " state codes (",
        paste(from_sheet, collapse = ", "), ") on sheet '", picked$sheet, "'.\n",
        "One workbook, one state — the §7A.4 reconciliation is per state and a ",
        "mixed table would reconcile against the wrong allotment.",
        call. = FALSE
      )
    } else {
      stringr::str_extract(basename(path), "^[A-Za-z]{2}")
    }
  }

  resolved_state <- stringr::str_to_upper(resolved_state)

  # §7A.1: the grain is a property of the workbook, and mixing grains within a
  # state would double-count. A `fund_use` column beneath a broader
  # `initiative` grouping means fund-use grain.
  grain <- if ("initiative_group" %in% names(mapping) &&
               stringr::str_detect(
                 rhtp_narrative_normalise_name(mapping[["initiative_name"]]),
                 "fund_use"
               )) {
    "FUND_USE"
  } else {
    "INITIATIVE"
  }

  out <- parsed %>%
    dplyr::mutate(
      state = resolved_state,
      initiative_id = sprintf("%s-%03d", resolved_state, dplyr::row_number()),
      recipient_status = dplyr::if_else(
        is.na(.data$recipient_status),
        rhtp_derive_recipient_status(.data$named_recipient_or_contractor),
        .data$recipient_status
      ),
      budget_narrative_version = dplyr::if_else(
        is.na(.data$budget_narrative_version),
        rhtp_derive_narrative_version(.data$source_document),
        .data$budget_narrative_version
      ),
      source_archive_path = dplyr::if_else(
        is.na(.data$source_archive_path),
        rhtp_narrative_archive_path(.data$state, .data$source_document),
        .data$source_archive_path
      ),
      # §8 requires a value; both reference states were typed by a person.
      extraction_method = dplyr::coalesce(.data$extraction_method, "MANUAL"),
      # §7A.3 wants the state's own activity language retained and never
      # discarded. Where a workbook carries no activity column, the state's own
      # initiative grouping is the closest thing it published — and mapping to
      # the CMS allowable-use categories stays NA rather than being invented.
      activity_type_raw = dplyr::coalesce(
        .data$activity_type_raw, .data$initiative_group
      ),
      initiative_grain = grain,
      source_workbook = basename(path),
      source_sheet = picked$sheet
    ) %>%
    dplyr::select(dplyr::all_of(RHTP_INITIATIVE_SCHEMA))

  attr(out, "rhtp_format") <- list(
    workbook = basename(path),
    sheet = picked$sheet,
    fields_resolved = picked$score,
    mapping = mapping,
    grain = grain
  )

  out
}


#' Read a stated grand total out of a workbook's reconciliation sheet
#'
#' §7A.4 distinguishes two structures, and the distinguishing fact is whether
#' the narrative states a grand total equal to the award. Delaware does
#' ("Budget narrative TOTAL", $157,394,963.86); Oklahoma does not — it states
#' the award and the allocated sum separately.
#'
#' Deliberately narrow. "Subtotal Direct" and "Sum of BP1 fund-use allocations"
#' must not match, or Oklahoma would be misread as TOTAL_INCLUSIVE.
#'
#' @param path Path to the workbook.
#' @return A single numeric, or NA if the workbook states no such total.
rhtp_narrative_stated_total <- function(path) {
  sheets <- readxl::excel_sheets(path)
  recon <- sheets[stringr::str_detect(sheets, stringr::regex("reconcil", ignore_case = TRUE))]

  if (length(recon) == 0) return(NA_real_)

  totals <- purrr::map_dbl(recon, function(sheet) {
    tbl <- suppressWarnings(
      readxl::read_excel(path, sheet = sheet, .name_repair = "minimal")
    )

    resolved <- rhtp_narrative_resolve_columns(names(tbl))
    label_col <- names(tbl)[1]
    amount_col <- if ("initiative_budget" %in% names(resolved$mapping)) {
      resolved$mapping[["initiative_budget"]]
    } else {
      NA_character_
    }

    if (is.na(amount_col) || !amount_col %in% names(tbl)) return(NA_real_)

    hits <- tbl %>%
      dplyr::filter(stringr::str_detect(
        dplyr::coalesce(as.character(.data[[label_col]]), ""),
        stringr::regex("narrative\\s+total|grand\\s+total|^total\\b", ignore_case = TRUE)
      ))

    if (nrow(hits) == 0) return(NA_real_)
    suppressWarnings(as.numeric(hits[[amount_col]])[1])
  })

  totals <- totals[!is.na(totals)]
  if (length(totals) == 0) NA_real_ else totals[1]
}


# -- Assertions -------------------------------------------------------------

#' Validate the initiative table's categorical columns against §8
#'
#' @param initiatives The canonical initiative table.
#' @return `initiatives`, invisibly. Errors on any failure.
rhtp_assert_initiative_categoricals <- function(initiatives) {
  problems <- character(0)

  checks <- list(
    flow_type              = "flow_type",
    has_hospital_recipient = "has_hospital_recipient",
    recipient_status       = "recipient_status",
    extraction_method      = "extraction_method",
    initiative_grain       = "initiative_grain"
  )

  for (column in names(checks)) {
    allowed <- rhtp_vocabulary(checks[[column]])
    present <- unique(stats::na.omit(initiatives[[column]]))
    bad <- setdiff(present, allowed)

    if (length(bad) > 0) {
      problems <- c(problems, paste0(
        column, " outside the §8 vocabulary: ", paste(bad, collapse = ", "),
        " (allowed: ", paste(allowed, collapse = " | "), ")"
      ))
    }
  }

  missing_budget <- initiatives %>%
    dplyr::filter(is.na(.data$initiative_budget) | .data$initiative_budget < 0)
  if (nrow(missing_budget) > 0) {
    problems <- c(problems, paste0(
      nrow(missing_budget), " row(s) with a missing or negative initiative_budget: ",
      paste(utils::head(missing_budget$initiative_id, 5), collapse = ", ")
    ))
  }

  missing_evidence <- initiatives %>%
    dplyr::filter(
      .data$has_hospital_recipient == "Yes",
      is.na(.data$evidence_from_document) | .data$evidence_from_document == ""
    )
  if (nrow(missing_evidence) > 0) {
    problems <- c(problems, paste0(
      nrow(missing_evidence), " row(s) coded has_hospital_recipient = Yes with no ",
      "evidence_from_document. §7A.3 requires the supporting sentence on the row ",
      "so a reviewer can check the call without reopening the PDF: ",
      paste(utils::head(missing_evidence$initiative_id, 5), collapse = ", ")
    ))
  }

  dupes <- initiatives %>%
    dplyr::count(.data$state, .data$initiative_id, name = "n") %>%
    dplyr::filter(.data$n > 1)
  if (nrow(dupes) > 0) {
    problems <- c(problems, paste0(
      nrow(dupes), " duplicate initiative_id(s) within a state."
    ))
  }

  mixed_grain <- initiatives %>%
    dplyr::distinct(.data$state, .data$initiative_grain) %>%
    dplyr::count(.data$state, name = "n") %>%
    dplyr::filter(.data$n > 1)
  if (nrow(mixed_grain) > 0) {
    problems <- c(problems, paste0(
      "mixed initiative_grain within state(s): ",
      paste(mixed_grain$state, collapse = ", "),
      ". Summing across grains double-counts (§7A.1)."
    ))
  }

  if (length(problems) > 0) {
    stop(
      "Initiative table failed §8 validation:\n",
      paste0("  - ", problems, collapse = "\n"),
      call. = FALSE
    )
  }

  invisible(initiatives)
}


#' Assert `has_hospital_recipient` against the §10.2 flow table
#'
#' The parser does not derive the flag, but the two columns are not free to
#' disagree: §10.2 fixes the mapping. A disagreement is either a coding slip
#' or a column mis-mapping, and both must surface before the figure is
#' published.
#'
#' @param initiatives The canonical initiative table.
#' @return A tibble of disagreements, invisibly. Errors when any exist.
rhtp_assert_flow_consistency <- function(initiatives) {
  expected <- tibble::tribble(
    ~flow_type,                 ~expected_hospital,
    "DIRECT",                   "Yes",
    "PASS_THROUGH_DESIGNATED",  "Yes",
    "PASS_THROUGH_UNRESOLVED",  "Unclear",
    "IN_KIND_BENEFIT",          "No",
    "NON_HOSPITAL",             "No"
  )

  conflicts <- initiatives %>%
    dplyr::filter(!is.na(.data$flow_type), !is.na(.data$has_hospital_recipient)) %>%
    dplyr::inner_join(expected, by = "flow_type") %>%
    dplyr::filter(.data$has_hospital_recipient != .data$expected_hospital) %>%
    dplyr::select(
      "state", "initiative_id", "initiative_name", "flow_type",
      "has_hospital_recipient", "expected_hospital"
    )

  if (nrow(conflicts) > 0) {
    stop(
      nrow(conflicts), " initiative(s) whose has_hospital_recipient contradicts ",
      "their flow_type under §10.2:\n",
      paste0("  ", conflicts$state, " ", conflicts$initiative_id, " — ",
             conflicts$flow_type, " should be '", conflicts$expected_hospital,
             "', coded '", conflicts$has_hospital_recipient, "': ",
             conflicts$initiative_name, collapse = "\n"), "\n",
      "Either the coding is wrong or a column mis-mapped. Fix at the source; ",
      "do not relax this check.",
      call. = FALSE
    )
  }

  invisible(conflicts)
}


# -- §7A.4 The reconciliation gate ------------------------------------------

# Rounding slack on a "matches the award to the dollar" claim. Delaware is
# $0.14 off; a dollar of headroom is generous and still far tighter than the
# 15-point band below it.
RHTP_RECONCILE_ROUNDING_USD <- 1

# §7A.4: "the sum of allocated fund uses falls between 85% and 100% of it with
# the remainder attributable to administrative and indirect costs."
RHTP_RECONCILE_FLOOR_PCT <- 0.85


#' Reconcile each state's initiative table to its CMS allotment (§7A.4)
#'
#' This is the QA gate and the central advantage of the backbone approach —
#' RCJ offers no equivalent. Two legitimate structures, both seen in the
#' reference states:
#'
#'   TOTAL_INCLUSIVE  the narrative states a grand total equal to the award,
#'                    with administration and indirect INSIDE it (Delaware).
#'   ALLOCATED_ONLY   the narrative allocates fund uses that fall short, with
#'                    administration and indirect held OUTSIDE (Oklahoma, 91.7%).
#'
#' `reconciliation_structure` records which document a state wrote.
#' `reconciliation_status` judges what was actually PARSED, in both structures
#' alike — because a narrative whose stated total matches the award tells you
#' nothing about whether the extraction captured all of its lines. Delaware is
#' the live proof: its narrative total is exact to $0.14, and the committed
#' extraction still stops at Initiative 12 and covers 84.6% of the award.
#'
#' @param initiatives The canonical initiative table.
#' @param stated_totals Tibble of `state` and `narrative_stated_total`.
#' @param allotments The §7.1 anchor. Defaults to the committed file.
#' @return A tibble, one row per state in `allotments`.
rhtp_reconcile_narratives <- function(initiatives,
                                      stated_totals = NULL,
                                      allotments = rhtp_load_cms_allotments()) {
  if (is.null(stated_totals)) {
    stated_totals <- tibble::tibble(
      state = character(0), narrative_stated_total = numeric(0)
    )
  }

  captured <- initiatives %>%
    dplyr::group_by(.data$state) %>%
    dplyr::summarise(
      n_initiatives = dplyr::n(),
      initiative_grain = dplyr::first(.data$initiative_grain),
      captured_total = sum(.data$initiative_budget, na.rm = TRUE),
      hospital_directed_total = sum(
        .data$initiative_budget[.data$has_hospital_recipient == "Yes"],
        na.rm = TRUE
      ),
      unclear_total = sum(
        .data$initiative_budget[.data$has_hospital_recipient == "Unclear"],
        na.rm = TRUE
      ),
      .groups = "drop"
    )

  allotments %>%
    dplyr::select("state", "state_name", "fy2026_allotment") %>%
    dplyr::left_join(captured, by = "state") %>%
    dplyr::left_join(stated_totals, by = "state") %>%
    dplyr::mutate(
      n_initiatives = dplyr::coalesce(.data$n_initiatives, 0L),
      captured_total = dplyr::coalesce(.data$captured_total, 0),
      reconciliation_pct = dplyr::if_else(
        .data$fy2026_allotment > 0,
        .data$captured_total / .data$fy2026_allotment,
        NA_real_
      ),
      stated_total_matches_award = !is.na(.data$narrative_stated_total) &
        abs(.data$narrative_stated_total - .data$fy2026_allotment) <=
          RHTP_RECONCILE_ROUNDING_USD,
      reconciliation_structure = dplyr::case_when(
        .data$n_initiatives == 0            ~ NA_character_,
        .data$stated_total_matches_award    ~ "TOTAL_INCLUSIVE",
        TRUE                                ~ "ALLOCATED_ONLY"
      ),
      reconciliation_status = dplyr::case_when(
        .data$n_initiatives == 0 ~ "NO_NARRATIVE",
        .data$captured_total <= 0 ~ "FAILED",
        .data$captured_total - .data$fy2026_allotment >
          RHTP_RECONCILE_ROUNDING_USD ~ "FAILED",
        .data$reconciliation_pct >= RHTP_RECONCILE_FLOOR_PCT ~ "RECONCILED",
        TRUE ~ "VARIANCE"
      ),
      unreconciled_remainder = .data$fy2026_allotment - .data$captured_total,
      hospital_directed_pct = dplyr::if_else(
        .data$captured_total > 0,
        .data$hospital_directed_total / .data$captured_total,
        NA_real_
      ),
      unclear_pct = dplyr::if_else(
        .data$captured_total > 0,
        .data$unclear_total / .data$captured_total,
        NA_real_
      ),
      publishable = .data$reconciliation_status == "RECONCILED",
      reconciliation_note = dplyr::case_when(
        .data$reconciliation_status == "NO_NARRATIVE" ~
          "No budget narrative extracted. A reportable gap (§7A.2), not an absence of spending.",
        .data$reconciliation_status == "FAILED" ~
          "Captured lines exceed the CMS allotment, or sum to zero. A state cannot allocate more than it received: bad parse, quarantined.",
        .data$reconciliation_status == "VARIANCE" ~
          "Captured lines fall below 85% of the allotment. Goes to review before being called a bad parse (§7A.4) — but not published while VARIANCE.",
        .data$reconciliation_structure == "TOTAL_INCLUSIVE" ~
          "Narrative states a grand total equal to the award; administration and indirect sit inside it.",
        TRUE ~
          "Fund-use lines fall short of the award, remainder attributable to administration and indirect held outside them."
      )
    ) %>%
    dplyr::arrange(dplyr::desc(.data$n_initiatives), .data$state)
}


# -- Build ------------------------------------------------------------------

#' Locate the committed budget-narrative extraction workbooks
#'
#' @return A character vector of paths.
rhtp_narrative_workbooks <- function() {
  patterns <- c(
    here::here("*_initiative_table.xlsx"),
    here::here("data", "reference", "initiative_tables", "*.xlsx")
  )

  paths <- unlist(lapply(patterns, Sys.glob), use.names = FALSE)
  sort(unique(paths[!stringr::str_detect(basename(paths), "^~\\$")]))
}


#' Parse every available narrative, validate, reconcile, and write
#'
#' @param paths Workbook paths. Defaults to [rhtp_narrative_workbooks()].
#' @param write Write outputs to `data/interim/`. FALSE validates only.
#' @return A list of `initiatives`, `reconciliation`, and `formats`.
rhtp_build_initiative_table <- function(paths = rhtp_narrative_workbooks(),
                                        write = TRUE) {
  if (length(paths) == 0) {
    stop(
      "No budget-narrative extraction workbooks found.\n",
      "Expected <ST>_initiative_table.xlsx at the repository root or under ",
      "data/reference/initiative_tables/.",
      call. = FALSE
    )
  }

  message("Parsing ", length(paths), " budget-narrative extraction(s)...")

  parsed <- purrr::map(paths, function(path) {
    tbl <- rhtp_parse_narrative_workbook(path)
    fmt <- attr(tbl, "rhtp_format")

    message("  ", basename(path), " -> sheet '", fmt$sheet, "', grain ",
            fmt$grain, ", ", fmt$fields_resolved, " of ",
            length(RHTP_NARRATIVE_SYNONYMS), " fields resolved, ",
            nrow(tbl), " rows")

    tbl
  })

  formats <- purrr::map_dfr(seq_along(parsed), function(i) {
    fmt <- attr(parsed[[i]], "rhtp_format")
    tibble::tibble(
      state = parsed[[i]]$state[1],
      source_workbook = fmt$workbook,
      source_sheet = fmt$sheet,
      initiative_grain = fmt$grain,
      fields_resolved = fmt$fields_resolved,
      canonical_fields = length(RHTP_NARRATIVE_SYNONYMS),
      column_mapping = paste0(names(fmt$mapping), " <- ", unname(fmt$mapping),
                              collapse = "; ")
    )
  })

  initiatives <- dplyr::bind_rows(parsed)

  rhtp_assert_initiative_categoricals(initiatives)
  rhtp_assert_flow_consistency(initiatives)

  stated_totals <- tibble::tibble(
    state = purrr::map_chr(parsed, ~ .x$state[1]),
    narrative_stated_total = purrr::map_dbl(paths, rhtp_narrative_stated_total)
  )

  reconciliation <- rhtp_reconcile_narratives(initiatives, stated_totals)

  covered <- reconciliation %>% dplyr::filter(.data$n_initiatives > 0)

  message("")
  message("§7A.4 reconciliation:")
  for (i in seq_len(nrow(covered))) {
    row <- covered[i, ]
    message(sprintf(
      "  %s  %-16s %-12s %6.1f%% of allotment  (%s of %s; %d %s lines)",
      row$state,
      row$reconciliation_structure,
      row$reconciliation_status,
      100 * row$reconciliation_pct,
      formatC(row$captured_total, format = "d", big.mark = ","),
      formatC(row$fy2026_allotment, format = "d", big.mark = ","),
      row$n_initiatives,
      row$initiative_grain
    ))
  }

  quarantined <- covered %>% dplyr::filter(!.data$publishable)
  if (nrow(quarantined) > 0) {
    message("")
    message("  QUARANTINED, not published (§7A.4): ",
            paste(quarantined$state, collapse = ", "))
    for (i in seq_len(nrow(quarantined))) {
      message("    ", quarantined$state[i], ": short by $",
              formatC(quarantined$unreconciled_remainder[i],
                      format = "d", big.mark = ","),
              " — ", quarantined$reconciliation_note[i])
    }
  }

  message("")
  message("  ", nrow(initiatives), " initiative rows across ",
          nrow(covered), " state(s); ",
          sum(reconciliation$reconciliation_status == "NO_NARRATIVE"),
          " states have no narrative extracted yet (§7A.2).")

  if (isTRUE(write)) {
    interim <- rhtp_path("interim", create = TRUE)

    saveRDS(initiatives, file.path(interim, "initiatives.rds"))
    readr::write_csv(initiatives, file.path(interim, "initiatives.csv"), na = "")

    saveRDS(reconciliation, file.path(interim, "initiative_reconciliation.rds"))
    readr::write_csv(reconciliation,
                     file.path(interim, "initiative_reconciliation.csv"), na = "")

    readr::write_csv(formats,
                     file.path(interim, "initiative_format_detection.csv"), na = "")

    message("  wrote data/interim/initiatives.{rds,csv}, ",
            "initiative_reconciliation.{rds,csv}, initiative_format_detection.csv")
    message("  commit these before the session ends (§0.5).")
  }

  invisible(list(
    initiatives = initiatives,
    reconciliation = reconciliation,
    formats = formats
  ))
}


# -- CLI --------------------------------------------------------------------

# Sourcing this file does nothing. Both modes are offline and spend no RCJ
# quota.
#
#   Rscript R/03b_budget_narratives.R --validate
#   Rscript R/03b_budget_narratives.R --build
#
if (!interactive() && identical(sys.nframe(), 0L)) {
  cli_args <- commandArgs(trailingOnly = TRUE)

  if ("--validate" %in% cli_args) {
    rhtp_build_initiative_table(write = FALSE)
  } else if ("--build" %in% cli_args) {
    rhtp_build_initiative_table(write = TRUE)
  } else {
    message(
      "Usage:\n",
      "  Rscript R/03b_budget_narratives.R --validate   # parse + assert, no writes\n",
      "  Rscript R/03b_budget_narratives.R --build      # parse, assert, reconcile, write"
    )
  }
}
