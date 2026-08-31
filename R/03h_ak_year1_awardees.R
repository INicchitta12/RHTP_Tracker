# 03h_ak_year1_awardees.R ----------------------------------------------------
# Alaska Year 1 awardees -> data/reference/ak_year1_awardees.csv (+ a render).
#
# WHAT THIS IS. Alaska DOH publishes its RHTP awards as a workbook,
# ak_rhtp_awardsnotice_2026.xlsx, whose single sheet is named "Notice of Intent
# to Award". 185 rows, ten columns, one row per project: App ID, Project Type,
# Org Name, Project Title, Project Summary, Initiative, Award Amount
# (Preliminary), Organization Type, Service Area, Notification Date.
#
# ALASKA IS THE FIRST STATE IN THIS PROJECT THAT NEEDS A SCHEDULE, NOT AN
# EXTRACTION. Its own funding-cycle update says awards are announced "on a
# rolling weekly basis", from ONE url that is overwritten each week. Session 12
# extracted 161 rows; three days after session 21's completeness re-check the
# same url served 185 and $181,871,366. Nothing was wrong with the extraction --
# a snapshot of a rolling file is stale by construction, and the only defence is
# to re-check it on a cadence and to keep the snapshot it is measured against.
# --probe is that check (live, archives nothing) and rhtp_ak_growth() is the
# diff. Both snapshots stay committed.
#
# WHAT THE REFRESH MOVED, AND WHERE IT CAME FROM:
#
#     2026-08-28   161 award actions   $160,701,975
#     2026-08-31   185 award actions   $181,871,366
#     ---------------------------------------------
#     + 24 NEW award actions           $ 16,862,504
#     + 1 EXISTING award REVISED UP    $  4,306,887   (Southcentral Foundation,
#                                                      BP1-IA-308, 1,548,208 ->
#                                                      5,855,095)
#     0 withdrawn
#
# The revision is not a new award and is not counted as one; the row says so in
# its own determination_basis. Alaska's update: "subaward budget finalization is
# still in progress ... minor adjustments to award amounts may occur."
#
# THE 161-VS-142 GAP IS RESOLVED, NOT AVERAGED -- AND IT IS ASSERTED WHERE IT IS
# TRUE. Session 11 recorded 161 RCJ rows against CMS's stated "142 projects" and
# left it open, with a hypothesis that Alaska carried one line per activity
# type. That hypothesis was wrong and the real answer is in the file's own
# Project Type column, on the file CMS described:
#
#     Implementation  142
#     Planning         19
#     -----------------
#     total           161
#
# CMS counts the IMPLEMENTATION awards. The App ID prefixes corroborate it
# independently -- BP1-PL (planning) appears on exactly 19 rows. So both figures
# are right and they count different things.
#
# THE CURRENT FILE HOLDS 166 IMPLEMENTATION ROWS, AND THAT IS NOT A BROKEN
# RECONCILIATION. CMS's 142 is a fact about the 2026-08-28 snapshot, so it is
# asserted THERE, offline, against the committed archive -- and the current file
# is required only to be a superset of it, with nothing withdrawn and the
# Planning count unmoved at 19. Re-pointing the constant at 166 would have
# thrown session 12's finding away to make an assertion pass.
#
# THE POSITIVE CONTROL IS ALASKA'S OWN. Its Year 1 Funding Cycle Update prints
# the weekly cumulative counts -- "Week 4 | Aug 28 ... $16.9M ... 24 Projects",
# cumulative "$182M ... 185 Projects". rhtp_ak_assert_cycle_control() DERIVES
# those figures from the parsed rows, rounds them the way Alaska rounds, and
# requires the results to appear in Alaska's text. Without it, "the file got
# bigger" is indistinguishable from "we fetched it twice".
#
# THESE ARE NOTICES OF INTENT TO AWARD, AND THE AMOUNTS SAY "PRELIMINARY".
# Alaska's own sheet name and its own column header both say so, and DOH is
# releasing these on a rolling weekly basis -- the file carries three
# notification dates (2026-08-07, -14, -21) and will carry more. Rows therefore
# carry validation_source_type = NOTICE_OF_INTENT_TO_AWARD, amount_precision =
# PRELIMINARY_AS_PUBLISHED and amount_confirmed = No. §8 makes intent-to-award
# primary and it can support a Yes; the preliminary AMOUNT is a separate
# question from the confirmed RECIPIENT, and §9.3's split-confirmation design
# is the reason those are two columns.
#
# THIS EXTRACTION IS A SNAPSHOT OF A ROLLING FILE. `notification_date` carries
# each row's own date and the manifest records the fetch date and digest, so a
# later pull is diffed against this one rather than replacing it blind -- which
# is exactly what happened on 2026-08-31, and is why AK_PRIOR_FILE exists.
#
# ALASKA CLASSIFIES ITS OWN AWARDEES AND THAT OUTRANKS ANY READING OF THE NAME.
# The Organization Type column is semicolon-delimited and mixes organisational
# form ("Hospital (all types)") with service line ("Maternal health"), so only
# the form tokens decide; a row whose field carries service lines only takes the
# §8 settled fallback rather than having a form invented for it. An unrecognised
# token hard-fails rather than being ignored -- see
# R/utils_recipient_classification.R.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only -- never |>. No setwd(); all
# paths go through here::here(). --fetch is the only mode that touches the
# network.
#
# CLI:
#   Rscript R/03h_ak_year1_awardees.R --probe     # LIVE: has the notice grown?
#   Rscript R/03h_ak_year1_awardees.R --fetch     # archive the XLSX + SHA-256
#   Rscript R/03h_ak_year1_awardees.R --validate  # parse + assert, no writes
#   Rscript R/03h_ak_year1_awardees.R --build     # assert, write CSV + xlsx

suppressPackageStartupMessages({
  library(dplyr)
  library(openxlsx)
  library(purrr)
  library(readr)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))
source(here::here("R", "utils_pdf_text.R"))

AK_STATE <- "AK"

AK_AWARDS_URL <-
  "https://health.alaska.gov/media/tcvker5a/ak_rhtp_awardsnotice_2026.xlsx"
AK_PROGRAM_URL <- paste0(
  "https://health.alaska.gov/en/education/",
  "rural-health-transformation-program/"
)
# THE CURRENT SNAPSHOT AND THE ONE BEFORE IT. Alaska announces awards weekly and
# serves every week from the SAME url, so a snapshot is only ever the file as it
# stood on the date in its name. Both are kept: the prior one is what makes the
# growth a diff of two archived documents rather than a claim, and it is the
# snapshot against which CMS's "142 projects" reconciles exactly (see below).
AK_AWARDS_FILE   <- "2026-08-31_ak_rhtp_awardsnotice_2026.xlsx"
AK_PRIOR_FILE    <- "2026-08-28_ak_rhtp_awardsnotice_2026.xlsx"
AK_MANIFEST_FILE <- "ak_rhtp_year1_awards.manifest.txt"

# THE POSITIVE CONTROL. Alaska publishes its own weekly cumulative counts in a
# separate document, so the growth below is a STATE-PUBLISHED FACT and not this
# pipeline's diff of two downloads. Without it, "the file got bigger" is
# indistinguishable from "we fetched it twice and something changed".
AK_CYCLE_UPDATE_URL <- paste0(
  "https://health.alaska.gov/media/lyrcb3pc/",
  "alaska-rhtp-year-1-funding-cycle-update.pdf"
)
AK_CYCLE_UPDATE_FILE <- "2026-08-31_alaska_rhtp_year1_funding_cycle_update.pdf"

AK_EVIDENCE_DIR <- "data/evidence/AK"
AK_CSV  <- "data/reference/ak_year1_awardees.csv"
AK_XLSX <- "AK_year1_awardees.xlsx"

AK_SHEET_NAME <- "Notice of Intent to Award"

# The columns Alaska publishes, in the order it publishes them. Resolved by name
# and asserted -- never mapped by position (§7A.1's lesson: a workbook whose
# obvious-looking column is the wrong one costs you the grain of the table).
AK_EXPECTED_COLUMNS <- c(
  "App ID", "Project Type", "Org Name", "Project Title", "Project Summary",
  "Initiative", "Award Amount (Preliminary)", "Organization Type",
  "Service Area", "Notification Date"
)

# What CMS states in its 2026-08-25 Alaska release. Session 12 asserted this
# EQUAL to Alaska's own Implementation count, and it was: 142 exactly, which is
# what resolved the 161-vs-142 gap. THAT ASSERTION WAS RIGHT ABOUT A SNAPSHOT
# AND WRONG AS A STANDING INVARIANT -- CMS described the file as it stood in
# August, and Alaska has kept awarding since. The finding is preserved by
# asserting it where it is true, against the committed 2026-08-28 archive, and
# the current file is required only to be a SUPERSET of it. Adjusting the
# constant to 166 would have thrown the finding away to make a test pass.
AK_CMS_STATED_PROJECTS <- 142L

# What CMS's 2026-08-25 release described as announced TO DATE. It is not a
# ceiling and must never be used as one: it is a point-in-time count of a
# rolling file, and Alaska passed it in week 4.
AK_CMS_ANNOUNCED_TO_DATE <- 160702462

# THE §6.2 CEILING IS THE ALLOTMENT, AND IT IS READ FROM THE §7.1 ANCHOR RATHER
# THAN TYPED (§0.2a: Tier 1 comes from CMS, never from a state document or from
# this file). Alaska's FY2026 allotment is $272,174,856; the earlier ceiling was
# keyed on the announced-to-date figure above, which a rolling file necessarily
# outruns -- it fired on this session's refresh, on money Alaska plainly has.
rhtp_ak_allotment <- function() {
  anchor <- readr::read_csv(
    here::here("data", "reference", "cms_fy2026_allotments.csv"),
    show_col_types = FALSE, progress = FALSE)
  row <- anchor %>% dplyr::filter(.data$state == AK_STATE)
  if (nrow(row) != 1L) {
    stop("[AK] the §7.1 allotment anchor does not carry exactly one AK row.",
         call. = FALSE)
  }
  row$fy2026_allotment[[1]]
}


# -- Fetch and archive -------------------------------------------------------

rhtp_ak_fetch <- function(force = FALSE) {
  cfg <- rhtp_config()
  dir <- here::here(AK_EVIDENCE_DIR)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  path <- file.path(dir, AK_AWARDS_FILE)

  if (file.exists(path) && !force) {
    message("  already archived: ", AK_AWARDS_FILE, " -- pass --force to re-fetch.")
    return(invisible(path))
  }

  resp <- httr2::request(AK_AWARDS_URL) %>%
    httr2::req_user_agent(cfg$api$user_agent) %>%
    httr2::req_timeout(cfg$api$timeout_seconds) %>%
    httr2::req_retry(max_tries = 3, backoff = ~ 2^.x) %>%
    httr2::req_perform()

  status <- httr2::resp_status(resp)
  if (status != 200) {
    stop("[AK] ", AK_AWARDS_URL, " returned HTTP ", status,
         "; refusing to archive a non-200 body.", call. = FALSE)
  }
  body <- httr2::resp_body_raw(resp)

  # Parse before writing (the R/00 posture), through a temp file so a workbook
  # that will not open never lands in the evidence archive.
  tmp <- tempfile(fileext = ".xlsx")
  writeBin(body, tmp)
  parsed <- rhtp_ak_parse_awards(tmp)
  unlink(tmp)

  writeBin(body, path)

  # The positive control, fetched in the same pass so it can never be one week
  # older than the file it corroborates.
  control <- file.path(dir, AK_CYCLE_UPDATE_FILE)
  cresp <- httr2::request(AK_CYCLE_UPDATE_URL) %>%
    httr2::req_user_agent(cfg$api$user_agent) %>%
    httr2::req_timeout(cfg$api$timeout_seconds) %>%
    httr2::req_retry(max_tries = 3, backoff = ~ 2^.x) %>%
    httr2::req_perform()
  if (httr2::resp_status(cresp) != 200) {
    stop("[AK] the Year 1 Funding Cycle Update returned HTTP ",
         httr2::resp_status(cresp),
         "; without it the growth is only a diff of two downloads.",
         call. = FALSE)
  }
  writeBin(httr2::resp_body_raw(cresp), control)

  by_type <- parsed %>% dplyr::count(.data$project_type)
  writeLines(paste0(
    "RHTP tracker archive (spec 0.4 / 0.5): Alaska RHTP Year 1 notices of intent\n",
    "to award.\n\n",
    "fetched_utc     : ", format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), "\n",
    "state           : AK\n",
    "host            : health.alaska.gov\n",
    "http_status     : ", status, "\n",
    "source_doc_type : NOTICE_OF_INTENT_TO_AWARD\n",
    "program         : Alaska Rural Health Transformation Program, DOH\n",
    "sheet           : ", AK_SHEET_NAME, "\n",
    "cms_year1_award : ~$160,000,000 (CMS 2026-08-25 release)\n\n",
    "FILE\n\n",
    "  file    : ", AK_AWARDS_FILE, "\n",
    "  title   : Alaska RHTP Awards Notice 2026\n",
    "  url     : ", AK_AWARDS_URL, "\n",
    "  program : ", AK_PROGRAM_URL, "\n",
    "  bytes   : ", length(body), "\n",
    "  sha256  : ", digest::digest(body, algo = "sha256", serialize = FALSE), "\n",
    "  rows    : ", nrow(parsed), "\n\n",
    "  by Project Type:\n",
    paste0("    ", by_type$project_type, "  ", by_type$n, collapse = "\n"), "\n\n",
    "  notification dates present: ",
    paste(sort(unique(as.character(parsed$notification_date))), collapse = ", "),
    "\n\n",
    "  file    : ", AK_CYCLE_UPDATE_FILE, "\n",
    "  title   : Alaska RHTP Year 1 Funding Cycle Update\n",
    "  url     : ", AK_CYCLE_UPDATE_URL, "\n",
    "  bytes   : ", file.info(control)$size, "\n",
    "  sha256  : ", digest::digest(file = control, algo = "sha256"), "\n",
    "  role    : POSITIVE CONTROL. Alaska's own weekly cumulative counts, which\n",
    "            are what make the growth of the notice a STATE-PUBLISHED fact\n",
    "            rather than this pipeline's diff of two downloads.\n\n",
    "  file    : ", AK_PRIOR_FILE, "\n",
    "  role    : the PRIOR SNAPSHOT, kept rather than replaced. It is what the\n",
    "            growth is measured against, and it is the snapshot where CMS's\n",
    "            stated 142 projects reconciles to Alaska's own Implementation\n",
    "            count exactly (session 12's finding, asserted every run).\n\n",
    "WHAT THIS DOCUMENT SUPPORTS (spec 9.2, Part A of reviewer-coding-instructions)\n\n",
    "THE 161-VS-142 GAP IS RESOLVED HERE. CMS states '142 projects' for Alaska.\n",
    "The file holds 161 rows because 19 of them are PLANNING awards and 142 are\n",
    "IMPLEMENTATION awards -- Alaska's own Project Type column, corroborated\n",
    "independently by the App ID prefix (BP1-PL appears on exactly 19). Both\n",
    "figures are right and they count different things. Nothing is dropped and\n",
    "no average is taken (session 11 left this open with a different and wrong\n",
    "hypothesis: one line per activity type).\n\n",
    "THESE ARE NOTICES OF INTENT TO AWARD AND THE AMOUNTS ARE PRELIMINARY.\n",
    "Alaska says both in its own sheet name and its own column header. Rows carry\n",
    "recipient_confirmed = Yes and amount_confirmed = No: §9.3 splits those two\n",
    "questions precisely so a preliminary figure does not drag a confirmed\n",
    "recipient down with it.\n\n",
    "THIS IS A SNAPSHOT OF A ROLLING FILE. DOH is releasing notices weekly and\n",
    "has said it will publish a comprehensive dashboard once all awards are\n",
    "announced. notification_date is on every row; diff a later pull against this\n",
    "digest rather than replacing it blind.\n"
  ), file.path(dir, AK_MANIFEST_FILE))

  message("  archived the Alaska award notice to ", AK_EVIDENCE_DIR,
          " (", nrow(parsed), " rows: ",
          paste0(by_type$project_type, " ", by_type$n, collapse = ", "), ")")
  invisible(path)
}


# -- Parse -------------------------------------------------------------------

#' Parse the Alaska award-notice workbook
#'
#' Resolves columns by name against AK_EXPECTED_COLUMNS and refuses on a
#' mismatch. `Notification Date` arrives as an Excel serial; it is converted
#' once, here, so no downstream stage has to know that.
rhtp_ak_parse_awards <- function(path) {
  sheets <- openxlsx::getSheetNames(path)
  if (!AK_SHEET_NAME %in% sheets) {
    stop("[AK] the workbook has no '", AK_SHEET_NAME, "' sheet; found: ",
         paste(sQuote(sheets), collapse = ", "),
         ". Refusing to read a sheet by position.", call. = FALSE)
  }

  raw <- openxlsx::read.xlsx(path, sheet = AK_SHEET_NAME,
                             check.names = FALSE, sep.names = " ") %>%
    tibble::as_tibble()

  missing <- setdiff(AK_EXPECTED_COLUMNS, names(raw))
  if (length(missing)) {
    stop("[AK] the award notice is missing column(s): ",
         paste(sQuote(missing), collapse = ", "), ". Found: ",
         paste(sQuote(names(raw)), collapse = ", "),
         ". Refusing to map columns by position.", call. = FALSE)
  }

  raw %>%
    dplyr::select(dplyr::all_of(AK_EXPECTED_COLUMNS)) %>%
    dplyr::rename(
      app_id = "App ID",
      project_type = "Project Type",
      awardee = "Org Name",
      project_title = "Project Title",
      project_summary = "Project Summary",
      initiative_raw = "Initiative",
      amount = "Award Amount (Preliminary)",
      organization_type_raw = "Organization Type",
      service_area = "Service Area",
      notification_serial = "Notification Date"
    ) %>%
    dplyr::mutate(
      dplyr::across(dplyr::where(is.character), ~ stringr::str_squish(.x)),
      amount = as.numeric(.data$amount),
      notification_date = as.Date(as.numeric(.data$notification_serial),
                                  origin = "1899-12-30")
    ) %>%
    dplyr::select(-"notification_serial") %>%
    dplyr::filter(nzchar(.data$awardee))
}


# -- The rolling growth, and Alaska's own corroboration of it ----------------

#' Diff the current notice against the prior committed snapshot.
#'
#' Alaska serves every week from the same url, so "the file changed" is not by
#' itself information. What is information is WHICH awards are new, which
#' existing award had its preliminary figure revised, and whether anything
#' disappeared. All three are read from two archived documents, offline.
rhtp_ak_growth <- function(current = NULL, prior = NULL) {
  if (is.null(current)) {
    current <- rhtp_ak_parse_awards(here::here(AK_EVIDENCE_DIR, AK_AWARDS_FILE))
  }
  if (is.null(prior)) {
    prior <- rhtp_ak_parse_awards(here::here(AK_EVIDENCE_DIR, AK_PRIOR_FILE))
  }

  added <- current %>% dplyr::filter(!.data$app_id %in% prior$app_id)
  revised <- current %>%
    dplyr::inner_join(
      prior %>% dplyr::select("app_id", prior_amount = "amount"),
      by = "app_id") %>%
    dplyr::filter(abs(.data$amount - .data$prior_amount) > 0.005)

  list(
    prior_rows = nrow(prior),
    prior_total = sum(prior$amount),
    rows = nrow(current),
    total = sum(current$amount),
    added = added,
    added_total = sum(added$amount),
    revised = revised,
    revised_delta = sum(revised$amount - revised$prior_amount),
    vanished = setdiff(prior$app_id, current$app_id)
  )
}

#' Alaska's Year 1 Funding Cycle Update, as text.
rhtp_ak_cycle_update_text <- function(
    path = file.path(AK_EVIDENCE_DIR, AK_CYCLE_UPDATE_FILE)) {
  full <- here::here(path)
  if (!file.exists(full)) {
    stop("[AK] the Year 1 Funding Cycle Update is missing: ", path,
         ". It is the positive control for the growth of the award notice; ",
         "without it the growth is only a diff of two downloads. Run --fetch.",
         call. = FALSE)
  }
  paste(rhtp_pdf_text(full), collapse = "\n")
}

#' Assert Alaska's own document states the totals this extraction derives.
#'
#' THE FIGURES ARE DERIVED AND THEN LOOKED FOR, never read off and copied. The
#' update rounds -- $181,871,366 is printed "$182M" and $16,862,504 "$16.9M" --
#' so the rounding is done here, from the parsed rows, and the RESULT is
#' required to appear in Alaska's text. That is a closure in the direction that
#' matters: the state has to agree with what this file computed.
rhtp_ak_assert_cycle_control <- function(growth = rhtp_ak_growth(),
                                         text = rhtp_ak_cycle_update_text()) {
  want <- c(
    cumulative_total   = sprintf("$%.0fM", growth$total / 1e6),
    cumulative_projects = as.character(growth$rows),
    week_added_total   = sprintf("$%.1fM", round(growth$added_total / 1e6, 1)),
    week_added_projects = as.character(nrow(growth$added))
  )
  missing <- want[!vapply(want, function(w) grepl(w, text, fixed = TRUE),
                          logical(1))]
  if (length(missing)) {
    stop("[AK] Alaska's Year 1 Funding Cycle Update does not state ",
         paste(paste0(names(missing), " = ", missing), collapse = ", "),
         ". The award notice and the state's own weekly counts disagree; ",
         "re-read both before publishing either.", call. = FALSE)
  }
  # And the control has to be about a ROLLING file, or it is the wrong control.
  if (!grepl("rolling weekly basis", text, fixed = TRUE)) {
    stop("[AK] the funding cycle update no longer says awards are announced ",
         "'on a rolling weekly basis'. Alaska's publication model is what ",
         "makes this file a snapshot; re-read it.", call. = FALSE)
  }
  invisible(TRUE)
}

rhtp_ak_build <- function() {
  path <- here::here(AK_EVIDENCE_DIR, AK_AWARDS_FILE)
  if (!file.exists(path)) {
    stop("[AK] the award-notice archive is missing: ", path,
         ". Run --fetch first.", call. = FALSE)
  }

  parsed <- rhtp_ak_parse_awards(path)

  # Alaska's own Organization Type decides `recipient_type` (§0.1 in miniature:
  # the state is the source of record for its own awardees). The flow rules then
  # read the project summary, and only after the type is fixed.
  classified <- parsed %>%
    dplyr::mutate(flow_text = paste(.data$project_title, .data$project_summary)) %>%
    rhtp_classify_records(state = AK_STATE,
                          description_col = "flow_text",
                          org_type_col = "organization_type_raw") %>%
    dplyr::select(-"flow_text")

  classified %>%
    dplyr::mutate(
      state = AK_STATE,
      row_no = dplyr::row_number(),
      note = paste0(.data$project_type, " | ", .data$initiative_raw,
                    " | ", .data$service_area),
      recipient_confirmed = "Yes",
      # Alaska's own column header says "(Preliminary)". A preliminary figure is
      # not a confirmed one, and §9.3 keeps that separate from the recipient.
      amount_confirmed = "No",
      fiscal_year = "FY2026 (Year 1)",
      source_document_title = "Alaska RHTP Awards Notice 2026 - Notice of Intent to Award",
      state_source_url = AK_AWARDS_URL,
      validation_source_type = "NOTICE_OF_INTENT_TO_AWARD",
      extraction_method = "MODEL_ASSISTED",
      validator = "AI-assisted - CONFIRM",
      ccn = NA_character_,
      aha_id = NA_character_,
      rural_designation = NA_character_,
      reviewer = NA_character_,
      recipient_type_source = .data$organization_type_raw,
      amount_basis = "PER_PROJECT",
      amount_precision = "PRELIMINARY_AS_PUBLISHED",
      disbursement_status = "INTENT_TO_AWARD",
      source_archive_path = file.path(AK_EVIDENCE_DIR, AK_AWARDS_FILE),
      recipient_names_source_url = AK_AWARDS_URL,
      activity_type_raw = .data$initiative_raw,
      determination_basis = paste0(
        .data$determination_basis,
        " Source: Alaska DOH's rolling RHTP award notice (sheet '",
        AK_SHEET_NAME, "'), project ", .data$app_id, ", notified ",
        .data$notification_date,
        ". The amount is published as preliminary and the document is a notice",
        " of intent to award, not a notice of award."
      ),
      flag_reason = dplyr::coalesce(.data$flag_reason, "AMOUNT_PRELIMINARY")
    ) %>%
    # Alaska's Organization Type is set per PROJECT, not per organisation, so
    # one awardee can arrive with two different forms across its own rows -- the
    # Alaska Native Tribal Health Consortium is "Hospital (all types)" on one
    # project and "Tribal Health Organization" on another. The per-row value
    # stays faithful to the source and is NOT harmonised: harmonising upward
    # would move money into the hospital total on this pipeline's authority
    # rather than the state's, and harmonising downward would discard the
    # state's own word. Flagged instead, and reported.
    dplyr::group_by(.data$awardee) %>%
    dplyr::mutate(
      awardee_type_count = dplyr::n_distinct(.data$recipient_type),
      awardee_types = paste(sort(unique(.data$recipient_type)), collapse = " / ")
    ) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      flag_reason = dplyr::if_else(.data$awardee_type_count > 1L,
                                   "RECIPIENT_TYPE_VARIES_IN_SOURCE",
                                   .data$flag_reason),
      determination_basis = dplyr::if_else(
        .data$awardee_type_count > 1L,
        paste0(.data$determination_basis,
               " NOTE: Alaska's Organization Type field gives this recipient a",
               " different organisational form on another of its own projects (",
               .data$awardee_types,
               "). The per-row value is kept as the state published it and is",
               " not harmonised; a reviewer resolves which form the entity has."),
        .data$determination_basis
      )
    ) %>%
    dplyr::select(-"awardee_type_count", -"awardee_types") %>%
    # A preliminary figure that has since been revised says so on its own row.
    # No new flag code: AMOUNT_PRELIMINARY already means "this may move", and
    # this is that happening. What the row gains is WHICH WAY it moved, in the
    # free text §7 makes mandatory, so a reader is not left comparing archives.
    dplyr::left_join(
      rhtp_ak_growth()$revised %>%
        dplyr::select("app_id", "prior_amount"),
      by = "app_id") %>%
    dplyr::mutate(
      determination_basis = dplyr::if_else(
        is.na(.data$prior_amount),
        .data$determination_basis,
        paste0(.data$determination_basis,
               " NOTE: Alaska REVISED this preliminary figure between the ",
               "2026-08-28 and 2026-08-31 snapshots, from ",
               format(.data$prior_amount, big.mark = ","), " to ",
               format(.data$amount, big.mark = ","),
               ". Both are archived; the state's own update says 'subaward ",
               "budget finalization is still in progress'.")
      )
    ) %>%
    dplyr::select(-"prior_amount") %>%
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
      # -- Alaska's own fields -------------------------------------------
      "app_id", "project_type", "initiative_raw", "project_title",
      "project_summary", "service_area", "organization_type_raw",
      "notification_date"
    )
}


rhtp_ak_records <- function(path = AK_CSV) {
  full <- here::here(path)
  if (!file.exists(full)) {
    stop("[AK] ", path, " does not exist. Run --build.", call. = FALSE)
  }
  readr::read_csv(full, show_col_types = FALSE, progress = FALSE)
}


# -- Reconciliation and assertions -------------------------------------------

rhtp_ak_reconcile <- function(records = rhtp_ak_build()) {
  impl <- records$project_type == "Implementation"
  plan <- records$project_type == "Planning"
  hosp <- records$distributed_to_hospital == "Yes"
  unclear <- records$distributed_to_hospital == "Unclear"
  varies <- records$flag_reason == "RECIPIENT_TYPE_VARIES_IN_SOURCE"

  tibble::tribble(
    ~measure,                                     ~value,
    "rows in Alaska's award notice",              as.character(nrow(records)),
    "  of which Implementation",                  as.character(sum(impl)),
    "  of which Planning",                        as.character(sum(plan)),
    "projects stated by CMS (2026-08-25 release)", as.character(AK_CMS_STATED_PROJECTS),
    "CMS count reconciles to the 2026-08-28 snapshot",
      paste0("yes, exactly -- ",
             sum(rhtp_ak_parse_awards(here::here(AK_EVIDENCE_DIR, AK_PRIOR_FILE))$project_type ==
                   "Implementation"),
             " Implementation rows on the file CMS described. The CURRENT ",
             "file holds ", sum(impl), ", because Alaska has kept awarding ",
             "weekly since; both are right and they count different days."),
    "distinct awardees",                          as.character(dplyr::n_distinct(records$awardee)),
    "notification dates in this snapshot",        paste(sort(unique(as.character(records$notification_date))), collapse = ", "),
    "total (preliminary) summed",                 format(sum(records$amount), big.mark = ",", nsmall = 2),
    "  Implementation only",                      format(sum(records$amount[impl]), big.mark = ",", nsmall = 2),
    "  Planning only",                            format(sum(records$amount[plan]), big.mark = ",", nsmall = 2),
    "CMS announced-to-date figure (2026-08-25 release)",
                                                  format(AK_CMS_ANNOUNCED_TO_DATE, big.mark = ","),
    "Alaska FY2026 CMS allotment (§7.1 anchor)",  format(rhtp_ak_allotment(), big.mark = ","),
    "  awarded as % of the allotment",            sprintf("%.1f%%", 100 * sum(records$amount) / rhtp_ak_allotment()),
    "awardees whose form varies across their own rows",
                                                  as.character(dplyr::n_distinct(
                                                    records$awardee[varies])),
    "rows so flagged",                            as.character(sum(varies)),
    "dollars on those rows",                      format(sum(records$amount[varies]), big.mark = ",", nsmall = 2),
    "  of which already counted as hospital",     format(sum(records$amount[varies & hosp]), big.mark = ",", nsmall = 2),
    "  of which a reviewer could move in",        format(sum(records$amount[varies & !hosp]), big.mark = ",", nsmall = 2),
    "rows distributed_to_hospital = Yes",         as.character(sum(hosp)),
    "dollars distributed_to_hospital = Yes",      format(sum(records$amount[hosp]), big.mark = ",", nsmall = 2),
    "rows distributed_to_hospital = Unclear",     as.character(sum(unclear)),
    "dollars distributed_to_hospital = Unclear",  format(sum(records$amount[unclear]), big.mark = ",", nsmall = 2)
  ) %>%
    dplyr::bind_rows(rhtp_ak_growth_lines())
}

#' The rolling-growth block of the reconciliation, kept separate because it is
#' about TWO archived documents rather than about the current one.
rhtp_ak_growth_lines <- function(growth = rhtp_ak_growth()) {
  tibble::tribble(
    ~measure, ~value,
    "-- rolling growth since the prior snapshot --", "",
    "prior snapshot (2026-08-28) rows",       as.character(growth$prior_rows),
    "prior snapshot total",                   format(growth$prior_total, big.mark = ","),
    "award actions added since",              as.character(nrow(growth$added)),
    "dollars added since",                    format(growth$added_total, big.mark = ","),
    "existing awards revised",                as.character(nrow(growth$revised)),
    "dollars from revision, not from new awards",
                                              format(growth$revised_delta, big.mark = ","),
    "award actions withdrawn",                as.character(length(growth$vanished)),
    "corroborated by Alaska's own weekly counts",
      "yes -- Year 1 Funding Cycle Update states the cumulative and week-4 figures",
    "this file is a SNAPSHOT of a weekly release",
      "yes -- Alaska: 'Project awards are being announced on a rolling weekly basis'"
  )
}


rhtp_ak_assert <- function(records = rhtp_ak_build()) {
  if (!nrow(records)) stop("[AK] the award notice parsed to zero rows.",
                           call. = FALSE)

  # THE GAP. This is the assertion that keeps session 11's open question closed:
  # CMS's 142 must equal Alaska's own Implementation count, from Alaska's own
  # column. If a later pull breaks it, the reconciliation is a live question
  # again and must not be papered over.
  # CMS's 142 reconciles against the snapshot CMS described, and is asserted
  # THERE -- against the committed 2026-08-28 archive, offline, every run. That
  # is where session 12's finding lives, and it stays checkable however far the
  # rolling file moves on.
  prior <- rhtp_ak_parse_awards(here::here(AK_EVIDENCE_DIR, AK_PRIOR_FILE))
  n_impl_prior <- sum(prior$project_type == "Implementation")
  if (n_impl_prior != AK_CMS_STATED_PROJECTS) {
    stop("[AK] the 2026-08-28 snapshot holds ", n_impl_prior,
         " Implementation rows against CMS's stated ", AK_CMS_STATED_PROJECTS,
         ". That agreement is what resolved the 161-vs-142 gap; it is a fact ",
         "about an archived file and cannot legitimately change.", call. = FALSE)
  }

  # The current file must be a SUPERSET of the snapshot CMS described. Growth is
  # expected on a rolling notice; a row disappearing is not, and would mean an
  # award this repository has published was withdrawn.
  n_impl <- sum(records$project_type == "Implementation")
  if (n_impl < AK_CMS_STATED_PROJECTS) {
    stop("[AK] Alaska's Implementation rows number ", n_impl,
         ", FEWER than the ", AK_CMS_STATED_PROJECTS,
         " CMS described. A rolling notice grows; it does not shrink.",
         call. = FALSE)
  }
  vanished <- setdiff(prior$app_id, records$app_id)
  if (length(vanished)) {
    stop("[AK] ", length(vanished), " award(s) present on 2026-08-28 are gone ",
         "from the current notice: ", paste(vanished, collapse = ", "),
         ". Alaska has withdrawn an award this repository published; that is a ",
         "finding, not a parse to wave through.", call. = FALSE)
  }

  # The BP1-PL corroboration held at 19 planning awards through the growth, and
  # is worth pinning: it is the independent check on the Project Type column.
  n_plan <- sum(records$project_type == "Planning")
  if (n_plan != sum(prior$project_type == "Planning")) {
    stop("[AK] the Planning count moved from ",
         sum(prior$project_type == "Planning"), " to ", n_plan,
         ". Re-read the notice: every award added since 2026-08-28 has been an ",
         "Implementation award, and a Planning award appearing changes what ",
         "CMS's project count is counting.", call. = FALSE)
  }

  # And the independent corroboration: the App ID prefix must agree with the
  # Project Type column on every row. Two columns disagreeing means the file's
  # own bookkeeping has drifted and the split above cannot be trusted.
  mismatched <- records %>%
    dplyr::mutate(
      prefix_says_planning = stringr::str_detect(.data$app_id, "^BP1-PL"),
      column_says_planning = .data$project_type == "Planning"
    ) %>%
    dplyr::filter(.data$prefix_says_planning != .data$column_says_planning)
  if (nrow(mismatched)) {
    stop("[AK] App ID prefix and Project Type disagree on ", nrow(mismatched),
         " row(s): ", paste(mismatched$app_id, collapse = ", "), call. = FALSE)
  }

  if (dplyr::n_distinct(records$app_id) != nrow(records)) {
    dupes <- records$app_id[duplicated(records$app_id)]
    stop("[AK] App ID is the project key and must be unique; duplicated: ",
         paste(unique(dupes), collapse = ", "), call. = FALSE)
  }

  if (any(is.na(records$amount)) || any(records$amount <= 0)) {
    stop("[AK] every project must carry a positive preliminary amount.",
         call. = FALSE)
  }
  if (any(is.na(records$notification_date))) {
    stop("[AK] every row must carry a notification date.", call. = FALSE)
  }

  # §6.2 ceiling, against the §7.1 ALLOTMENT. A rolling file necessarily outruns
  # a point-in-time count of what had been announced, so keying the ceiling on
  # CMS's "$160 million" made week 4 look like an overrun of money Alaska has.
  summed <- sum(records$amount)
  allotment <- rhtp_ak_allotment()
  if (summed > allotment) {
    stop("[AK] the preliminary total ", format(summed, big.mark = ","),
         " exceeds Alaska's FY2026 CMS allotment of ",
         format(allotment, big.mark = ","), ". §6.2 ceiling.", call. = FALSE)
  }

  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "determination_confidence", "flag_reason")) {
    bad <- setdiff(stats::na.omit(unique(records[[col]])), rhtp_vocabulary(col))
    if (length(bad)) {
      stop("[AK] ", col, " outside §8: ", paste(bad, collapse = ", "),
           call. = FALSE)
    }
  }

  wrong <- records %>%
    dplyr::filter(.data$distributed_to_hospital == "Yes",
                  !.data$recipient_type %in% c("HOSPITAL_OR_SYSTEM",
                                               "HOSPITAL_AFFILIATED_ENTITY"))
  if (nrow(wrong)) {
    stop("[AK] distributed_to_hospital = Yes on a non-hospital recipient: ",
         paste(unique(wrong$awardee), collapse = "; "), call. = FALSE)
  }

  # Every row must say the amount is preliminary. Losing that flag is how a
  # figure Alaska called preliminary turns into one AHA published.
  if (!all(records$amount_confirmed == "No")) {
    stop("[AK] amount_confirmed must be No on every row: Alaska's own column ",
         "header reads 'Award Amount (Preliminary)'.", call. = FALSE)
  }

  if (any(is.na(records$determination_basis) |
          !nzchar(records$determination_basis))) {
    stop("[AK] determination_basis is mandatory free text (§7).", call. = FALSE)
  }

  # THE GROWTH IS ALASKA'S CLAIM, NOT THIS PIPELINE'S. The award notice and the
  # state's own weekly funding-cycle counts have to agree on the cumulative
  # total, the cumulative project count, and what week 4 added -- derived here
  # and then looked for in Alaska's text, never copied out of it.
  rhtp_ak_assert_cycle_control()

  invisible(TRUE)
}


# -- Write -------------------------------------------------------------------

rhtp_ak_write <- function() {
  records <- rhtp_ak_build()
  rhtp_ak_assert(records)

  readr::write_csv(records, here::here(AK_CSV), na = "")

  wb <- openxlsx::createWorkbook()
  add <- function(sheet, data) {
    openxlsx::addWorksheet(wb, sheet)
    openxlsx::writeData(wb, sheet, data)
    openxlsx::freezePane(wb, sheet, firstRow = TRUE)
  }
  add("Awardees", records)
  add("Reconciliation", rhtp_ak_reconcile(records))
  openxlsx::saveWorkbook(wb, here::here(AK_XLSX), overwrite = TRUE)

  message("  wrote ", AK_CSV, " and ", AK_XLSX, " (", nrow(records), " rows)")
  invisible(records)
}


#' LIVE: has Alaska's rolling notice moved since the committed snapshot?
#'
#' The SD `--probe` precedent -- fetch, diff, report, ARCHIVE NOTHING. Alaska is
#' the first state in this project that needs a scheduled re-check rather than
#' an extraction: it announces awards "on a rolling weekly basis" from a single
#' unchanging url, so the committed file is stale by design and the only
#' question worth asking on a schedule is how stale.
#'
#' Exits 0 and prints UNCHANGED when the digest matches, so a scheduled run that
#' finds nothing is cheap and silent.
rhtp_ak_probe <- function() {
  cfg <- rhtp_config()
  committed <- here::here(AK_EVIDENCE_DIR, AK_AWARDS_FILE)
  resp <- httr2::request(AK_AWARDS_URL) %>%
    httr2::req_user_agent(cfg$api$user_agent) %>%
    httr2::req_timeout(cfg$api$timeout_seconds) %>%
    httr2::req_retry(max_tries = 3, backoff = ~ 2^.x) %>%
    httr2::req_perform()
  if (httr2::resp_status(resp) != 200) {
    stop("[AK] probe: HTTP ", httr2::resp_status(resp), " for ", AK_AWARDS_URL,
         call. = FALSE)
  }
  body <- httr2::resp_body_raw(resp)
  live_sha <- digest::digest(body, algo = "sha256", serialize = FALSE)
  held_sha <- digest::digest(file = committed, algo = "sha256")

  if (identical(live_sha, held_sha)) {
    message("[AK] UNCHANGED -- the live notice is byte-identical to ",
            AK_AWARDS_FILE, " (sha256 ", substr(live_sha, 1, 12), ").")
    return(invisible(list(changed = FALSE)))
  }

  tmp <- tempfile(fileext = ".xlsx")
  writeBin(body, tmp)
  growth <- rhtp_ak_growth(current = rhtp_ak_parse_awards(tmp),
                           prior = rhtp_ak_parse_awards(committed))
  unlink(tmp)

  message("[AK] CHANGED -- Alaska has published since ", AK_AWARDS_FILE, ".")
  message("[AK]   rows    ", growth$prior_rows, " -> ", growth$rows)
  message("[AK]   total   ", format(growth$prior_total, big.mark = ","),
          " -> ", format(growth$total, big.mark = ","))
  message("[AK]   added   ", nrow(growth$added), " award actions, ",
          format(growth$added_total, big.mark = ","))
  message("[AK]   revised ", nrow(growth$revised), " existing award(s), ",
          format(growth$revised_delta, big.mark = ","))
  if (length(growth$vanished)) {
    message("[AK]   WITHDRAWN ", length(growth$vanished), ": ",
            paste(growth$vanished, collapse = ", "))
  }
  message("[AK] Re-run: --fetch --force (with AK_AWARDS_FILE re-dated and the ",
          "current file moved to AK_PRIOR_FILE), then --build, then COMMIT.")
  invisible(list(changed = TRUE, growth = growth))
}

# -- CLI ---------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--probe" %in% args) {
    rhtp_ak_probe()
  } else if ("--fetch" %in% args) {
    rhtp_ak_fetch(force = "--force" %in% args)
  } else if ("--build" %in% args) {
    rhtp_ak_write()
    print(rhtp_ak_reconcile(rhtp_ak_records()), n = Inf)
  } else if ("--validate" %in% args) {
    recs <- rhtp_ak_build()
    rhtp_ak_assert(recs)
    print(rhtp_ak_reconcile(recs), n = Inf)
    message("[AK] all assertions passed.")
  } else {
    message("Usage: Rscript R/03h_ak_year1_awardees.R ",
            "[--probe|--fetch|--validate|--build]")
  }
}
