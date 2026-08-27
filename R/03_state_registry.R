# 03_state_registry.R -----------------------------------------------------------
# Stage 3 — CMS FY2026 allotments and the state source registry — build spec §7
#
# CONTRACT: produce the two reference tables everything downstream keys off.
#
#   1. data/reference/cms_fy2026_allotments.csv  (§7.1)
#      50 rows, parsed from the CMS December 2025 press release, asserted on
#      load. THE reconciliation anchor: §6.1 tier rule 3, the §6.2 allotment
#      ceiling, the §7.1 state vocabulary cross-check, and QA assertions
#      §13.3, §13.4 and §13.17 all read it. Never transcribed by hand — a
#      typo here corrupts every figure downstream.
#
#   2. data/reference/state_source_registry_worksheet.csv  (§7.2)
#      The §7.2 candidate hosts, laid out as a verification worksheet with
#      empty award_posting_url / pass_through_admin / last_verified columns
#      for a human to fill in off-session. Machine-generated candidates are
#      never the registry; a person loads each URL and sets last_verified.
#
#   3. Validation of the hand-verified registry once it lands (§7.3), so the
#      file that gates Stage 4 cannot arrive malformed.
#
# The only network call in this file is the CMS fetch, which costs no RCJ
# quota and is archived verbatim so the parse is reproducible offline.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only — never |>. snake_case.
# Explicit dplyr:: namespacing. No setwd(); use here::here().

source(here::here("R", "utils_config.R"))

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(stringr)
  library(tibble)
})


# -- Constants -------------------------------------------------------------

# The worksheet columns a person fills in off-session. Kept as a constant so
# the writer, the reader and the tests cannot drift apart, and so a partially
# filled worksheet coming back from review is still recognisable.
RHTP_WORKSHEET_VERIFY_COLUMNS <- c(
  "lead_agency", "program_page_url", "award_posting_url",
  "pass_through_admin", "pass_through_admin_url",
  "last_verified", "verified_by", "verification_note"
)

# §7.3 registry schema. `fy2026_allotment` is deliberately NOT here: it comes
# from cms_fy2026_allotments.csv and is joined on, never re-keyed by hand in a
# second file where the two could disagree.
RHTP_REGISTRY_COLUMNS <- c(
  "state", "lead_agency", "program_page_url", "award_posting_url",
  "pass_through_admin", "pass_through_admin_url", "last_verified"
)


# -- §7.1 CMS FY2026 allotments --------------------------------------------

#' Where the fetched CMS allotment table is archived
#'
#' Under data/raw/ and therefore committed (§0.5). The parse reads the archive,
#' not the network, so re-running Stage 3 in a later session reproduces the
#' exact table that produced the committed CSV — even if CMS edits the page.
#'
#' What is archived is the allotment `<table>` verbatim, not the whole page.
#' The page is 66 KB of CMS site chrome around a 5 KB table, and its scripts
#' carry third-party API tokens that are CMS's to publish and not ours to
#' redistribute — GitHub push protection rejects them, correctly. The archive
#' header records the source URL, the fetch time and the SHA-256 of the full
#' response body, so the provenance chain still closes: anyone can re-fetch the
#' page and verify the digest.
rhtp_cms_archive_path <- function(fetch_date = Sys.Date()) {
  rhtp_path("raw_cms", as.character(fetch_date),
            "cms_fy2026_allotment_table.html")
}


#' Fetch and archive the CMS FY2026 allotment press release
#'
#' Requires cms.gov and www.cms.gov on the environment allowlist (§3.2). Costs
#' no RCJ quota — this is a different host entirely and nothing here touches
#' the RCJ key.
#'
#' @param fetch_date Archive subdirectory to write into.
#' @param force Re-fetch even when an archive for this date already exists.
#' @return The archive path, invisibly.
rhtp_fetch_cms_allotments <- function(fetch_date = Sys.Date(), force = FALSE) {
  cfg <- rhtp_config()
  url <- cfg$cms$fy2026_allotment_url
  path <- rhtp_cms_archive_path(fetch_date)

  if (file.exists(path) && !isTRUE(force)) {
    message("  CMS press release already archived at ", path,
            " (pass force = TRUE to re-fetch).")
    return(invisible(path))
  }

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)

  message("  fetching ", url)

  resp <- httr2::request(url) %>%
    httr2::req_user_agent(cfg$api$user_agent) %>%
    httr2::req_timeout(cfg$api$timeout_seconds) %>%
    httr2::req_retry(
      max_tries = cfg$retry$max_tries,
      backoff = function(i) min(cfg$retry$backoff_base_seconds^i,
                                cfg$retry$backoff_max_seconds)
    ) %>%
    httr2::req_perform()

  status <- httr2::resp_status(resp)

  if (status != 200) {
    stop(
      "CMS press release fetch returned HTTP ", status, " for ", url, ".\n",
      "A 403 here usually means cms.gov is not on the environment's network ",
      "allowlist (spec §3.2).",
      call. = FALSE
    )
  }

  body <- httr2::resp_body_string(resp)
  body_sha256 <- digest::digest(body, algo = "sha256", serialize = FALSE)

  # Assert the page shape at FETCH time, against the live response, so a CMS
  # redesign is caught before anything is written -- and so the archive is
  # never a table we picked arbitrarily out of several.
  tables <- xml2::read_html(body) %>% rvest::html_elements("table")
  expected_tables <- cfg$cms$fy2026_allotment_expected_tables

  if (length(tables) != expected_tables) {
    stop(
      "Expected ", expected_tables, " table(s) at ", url, "; found ",
      length(tables), ". The page layout has changed -- correct the parser ",
      "before trusting the output, because this file is the reconciliation ",
      "anchor for every QA assertion in §13.",
      call. = FALSE
    )
  }

  header <- paste0(
    "<!--\n",
    "  RHTP tracker \u00a77.1 archive: the CMS FY2026 state allotment table.\n",
    "  source_url      : ", url, "\n",
    "  fetched_utc     : ", format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), "\n",
    "  http_status     : ", status, "\n",
    "  full_page_bytes : ", nchar(body, type = "bytes"), "\n",
    "  full_page_sha256: ", body_sha256, "\n",
    "\n",
    "  The <table> below is verbatim from that response. The surrounding page\n",
    "  is not archived: it is CMS site chrome, and its scripts carry\n",
    "  third-party API tokens that are CMS's to publish and not ours to\n",
    "  redistribute. Re-fetch source_url and compare full_page_sha256 to\n",
    "  verify this extract against the page it came from.\n",
    "-->\n"
  )

  writeLines(paste0(header, as.character(tables[[1]])), path, useBytes = TRUE)
  message("  archived the allotment table to ", path, " (",
          format(file.size(path), big.mark = ","), " bytes; full page ",
          format(nchar(body, type = "bytes"), big.mark = ","),
          " bytes, sha256 ", substr(body_sha256, 1, 12), "...)")

  invisible(path)
}


#' Parse the 50-row FY2026 allotment table out of the archived press release
#'
#' The page carries exactly one <table>: `State | FY26 Award Amount`. That is
#' asserted rather than assumed — a CMS page redesign that adds a second table
#' must fail loudly here, not silently parse the wrong one into the file every
#' downstream figure reconciles against.
#'
#' State CODES come from cms_states.csv by joining on the state name. The
#' press release publishes names only, and inventing a name→code mapping in
#' this file would create a second, divergent state vocabulary (§7.1).
#'
#' @param path An archived HTML file. Defaults to today's archive.
#' @return A tibble: state, state_name, fy2026_allotment, source_url,
#'   source_fetched.
rhtp_parse_cms_allotments <- function(path = rhtp_cms_archive_path(),
                                      fetch_date = NULL) {
  cfg <- rhtp_config()

  if (!file.exists(path)) {
    stop(
      "No archived CMS allotment table at '", path, "'.\n",
      "Run rhtp_fetch_cms_allotments() first, or point `path` at an existing ",
      "archive under ", cfg$paths$raw_cms, "/.",
      call. = FALSE
    )
  }

  if (is.null(fetch_date)) {
    fetch_date <- basename(dirname(path))
  }

  tables <- rvest::read_html(path) %>% rvest::html_table()

  expected_tables <- cfg$cms$fy2026_allotment_expected_tables

  if (length(tables) != expected_tables) {
    stop(
      "Expected ", expected_tables, " table(s) in the archived CMS extract; ",
      "found ", length(tables), " in '", path, "'.\n",
      "The archive holds exactly the allotment table by construction, so this ",
      "means it is corrupt or was hand-edited. Re-fetch with ",
      "rhtp_fetch_cms_allotments(force = TRUE) rather than repairing it.",
      call. = FALSE
    )
  }

  raw_table <- tables[[1]]

  if (ncol(raw_table) != 2) {
    stop(
      "Expected a 2-column State | FY26 Award Amount table; found ",
      ncol(raw_table), " columns in '", path, "'.",
      call. = FALSE
    )
  }

  names(raw_table) <- c("state_name_raw", "amount_raw")

  # html_table() renders the leading &nbsp; on every state cell as U+00A0.
  # str_squish() handles it, but strip it explicitly so a locale that does not
  # fold NBSP into [:space:] cannot leave " Alabama" to fail the join.
  clean_text <- function(x) {
    x %>%
      stringr::str_replace_all(" ", " ") %>%
      stringr::str_squish()
  }

  header_regex <- cfg$cms$fy2026_allotment_header_regex

  allotments <- raw_table %>%
    dplyr::mutate(
      state_name_raw = clean_text(state_name_raw),
      amount_raw     = clean_text(amount_raw)
    ) %>%
    # Drop the header row wherever rvest placed it, rather than assuming it is
    # row 1: a <thead> would already have been consumed and slice(-1) would
    # then silently eat Alabama.
    dplyr::filter(
      !stringr::str_detect(
        tolower(state_name_raw), stringr::regex(header_regex)
      )
    ) %>%
    dplyr::mutate(
      fy2026_allotment = suppressWarnings(
        as.numeric(stringr::str_remove_all(amount_raw, "[^0-9.]"))
      )
    )

  unparsed <- allotments %>% dplyr::filter(is.na(fy2026_allotment))

  if (nrow(unparsed) > 0) {
    stop(
      "Could not parse an amount for ", nrow(unparsed), " row(s): ",
      paste(unparsed$state_name_raw, collapse = ", "), ".",
      call. = FALSE
    )
  }

  # The code comes from the 50-row CMS state vocabulary, by name join.
  states <- rhtp_cms_states()

  joined <- allotments %>%
    dplyr::left_join(states, by = c("state_name_raw" = "state_name"))

  unmatched <- joined %>% dplyr::filter(is.na(state))

  if (nrow(unmatched) > 0) {
    stop(
      "The CMS press release names ", nrow(unmatched),
      " row(s) that are not in data/reference/cms_states.csv: ",
      paste(unmatched$state_name_raw, collapse = ", "), ".\n",
      "Either CMS added a territory or a name is spelled differently. ",
      "Resolve it against the source before writing the anchor file — do not ",
      "drop the row.",
      call. = FALSE
    )
  }

  joined %>%
    dplyr::transmute(
      state,
      state_name       = state_name_raw,
      fy2026_allotment,
      fy2026_allotment_published = amount_raw,
      source_url       = cfg$cms$fy2026_allotment_url,
      source_fetched   = as.character(fetch_date)
    ) %>%
    dplyr::arrange(state)
}


#' QA assertion §13.17 — run on load, not on use
#'
#' Exactly 50 rows, one per CMS state, summing to approximately $10B, with the
#' minimum and maximum near $147M (NJ) and $281M (TX). Every bound comes from
#' config so a Year 2 table can be re-anchored without editing code.
#'
#' Hard-fails. A table that fails these checks is not a finding about the data;
#' it is a broken anchor, and every figure computed against it would be wrong.
#'
#' @return The input, invisibly.
rhtp_assert_allotments <- function(allotments) {
  cfg <- rhtp_config()
  qa <- cfg$qa

  fail <- function(...) stop("cms_fy2026_allotments.csv failed §13.17: ", ...,
                            call. = FALSE)

  # Every bound is coerced: R's yaml reader silently returns NA for an
  # integer literal above 2^31, and an NA bound turns a hard assertion into an
  # `argument is not interpretable as logical` crash rather than a pass --
  # noisy, but not the message the operator needs.
  qa_num <- function(key) {
    value <- suppressWarnings(as.numeric(qa[[key]]))
    if (length(value) != 1 || is.na(value)) {
      fail("config qa$", key, " is missing or not numeric. Write large ",
           "literals in exponent form (1.0e10), which the yaml reader ",
           "handles; a bare 10000000000 overflows to NA.")
    }
    value
  }

  required_cols <- c("state", "state_name", "fy2026_allotment")
  missing_cols <- setdiff(required_cols, names(allotments))

  if (length(missing_cols) > 0) {
    fail("missing column(s): ", paste(missing_cols, collapse = ", "), ".")
  }

  expected_states <- qa_num("allotment_expected_states")

  if (nrow(allotments) != expected_states) {
    fail("expected exactly ", expected_states, " rows; found ",
         nrow(allotments), ".")
  }

  if (anyNA(allotments$fy2026_allotment)) {
    fail(sum(is.na(allotments$fy2026_allotment)), " row(s) have no amount.")
  }

  if (dplyr::n_distinct(allotments$state) != nrow(allotments)) {
    fail("state codes are not unique.")
  }

  valid_states <- rhtp_cms_states()$state
  stray <- setdiff(allotments$state, valid_states)
  absent <- setdiff(valid_states, allotments$state)

  if (length(stray) > 0) {
    fail("state code(s) not in cms_states.csv: ",
         paste(stray, collapse = ", "), ".")
  }
  if (length(absent) > 0) {
    fail("state(s) missing from the table: ",
         paste(absent, collapse = ", "), ".")
  }

  total <- sum(allotments$fy2026_allotment)
  target <- qa_num("allotment_total_usd")
  tol <- qa_num("allotment_total_tolerance_fraction")

  if (abs(total - target) > tol * target) {
    fail("total is ", format(total, big.mark = ",", scientific = FALSE),
         ", more than ", tol * 100, "% from the published ",
         format(target, big.mark = ",", scientific = FALSE), ".")
  }

  bound_tol <- qa_num("allotment_bound_tolerance_fraction")
  expected_min <- qa_num("allotment_min_usd")
  expected_max <- qa_num("allotment_max_usd")
  observed_min <- min(allotments$fy2026_allotment)
  observed_max <- max(allotments$fy2026_allotment)

  if (abs(observed_min - expected_min) > bound_tol * expected_min) {
    fail("minimum is ", format(observed_min, big.mark = ",", scientific = FALSE),
         ", not within ", bound_tol * 100, "% of the expected ",
         format(expected_min, big.mark = ",", scientific = FALSE),
         " (New Jersey).")
  }

  if (abs(observed_max - expected_max) > bound_tol * expected_max) {
    fail("maximum is ", format(observed_max, big.mark = ",", scientific = FALSE),
         ", not within ", bound_tol * 100, "% of the expected ",
         format(expected_max, big.mark = ",", scientific = FALSE),
         " (Texas).")
  }

  invisible(allotments)
}


#' Build data/reference/cms_fy2026_allotments.csv end to end
#'
#' Fetch (unless an archive exists) → parse → assert → write. The assertion
#' runs BEFORE the write, so a failed parse can never leave a corrupt anchor
#' on disk for the next session to trust.
#'
#' @param fetch_date Archive subdirectory. Defaults to today.
#' @param force Re-fetch the page even if archived.
#' @param write Write the CSV. FALSE returns the parsed table only.
rhtp_build_cms_allotments <- function(fetch_date = Sys.Date(),
                                      force = FALSE,
                                      write = TRUE) {
  message("-- Stage 3 §7.1: CMS FY2026 state allotments --")

  archive <- rhtp_fetch_cms_allotments(fetch_date = fetch_date, force = force)
  allotments <- rhtp_parse_cms_allotments(archive, fetch_date = fetch_date)

  rhtp_assert_allotments(allotments)

  message("  parsed ", nrow(allotments), " states; total $",
          format(sum(allotments$fy2026_allotment), big.mark = ",",
                 scientific = FALSE))
  message("  min ", allotments$state[which.min(allotments$fy2026_allotment)],
          " $", format(min(allotments$fy2026_allotment), big.mark = ",",
                       scientific = FALSE),
          " | max ", allotments$state[which.max(allotments$fy2026_allotment)],
          " $", format(max(allotments$fy2026_allotment), big.mark = ",",
                       scientific = FALSE))

  if (isTRUE(write)) {
    path <- rhtp_path("cms_allotments", create = TRUE)
    readr::write_csv(allotments, path)
    message("  written to ", path)
  }

  invisible(allotments)
}


#' Read the committed allotment anchor, asserting §13.17 on the way in
#'
#' The reader every other stage should use. Errors if the file is absent —
#' unlike `rhtp_load_allotments()` in Stage 2, which degrades to an empty table
#' and reports the gap, because Stage 2 must still run without the anchor.
rhtp_load_cms_allotments <- function() {
  path <- rhtp_path("cms_allotments")

  if (!file.exists(path)) {
    stop(
      "data/reference/cms_fy2026_allotments.csv does not exist.\n",
      "Build it with: Rscript R/03_state_registry.R --allotments",
      call. = FALSE
    )
  }

  readr::read_csv(path, show_col_types = FALSE, progress = FALSE) %>%
    rhtp_assert_allotments()
}


# -- §7.2 The registry verification worksheet ------------------------------

rhtp_max_date <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) as.Date(NA) else max(x)
}


#' Turn the §7.2 candidate hosts into a worksheet a person can verify
#'
#' The candidate table says a host appeared in `/activity.siteUrl` for a state.
#' It does not say what that host is, which is the first thing a verifier needs
#' in order to decide whether to open it — so each row carries a sample source
#' document title drawn from the records that actually resolved to that host.
#'
#' The verification columns are emitted EMPTY, by design. §7.2: "the generated
#' candidates are a starting point, never the final registry. Every row still
#' needs `last_verified` set by a person who loaded the URL." Pre-filling
#' `award_posting_url` from the candidate host would manufacture exactly the
#' unverified registry §7.2 exists to prevent, and §13.12 makes registry
#' completeness a deliverable gate.
#'
#' States with no candidate host at all get a row anyway. They are the most
#' important rows in the file — a state with no registry entry cannot be
#' validated in Stage 4 at all (§13.12).
#'
#' @param state_sources The Stage 2 /activity table.
#' @param records The Stage 2 record table, for sample titles. Optional.
#' @param valid_states The 50-row CMS state vocabulary.
rhtp_registry_worksheet <- function(state_sources,
                                    records = NULL,
                                    valid_states = NULL) {
  if (is.null(valid_states)) valid_states <- rhtp_cms_states()$state

  host_of <- function(url) stringr::str_extract(url, "^https?://[^/]+")

  candidates <- state_sources %>%
    dplyr::filter(state %in% valid_states) %>%
    dplyr::mutate(url_host = host_of(state_source_url)) %>%
    dplyr::filter(!is.na(url_host)) %>%
    dplyr::group_by(state, url_host) %>%
    dplyr::summarise(
      n_activity_references = dplyr::n(),
      n_document_urls = sum(url_kind == "document_source_url"),
      example_url = dplyr::first(state_source_url),
      # max() over an all-NA Date returns -Inf with a warning, which would
      # write "-Inf" into a worksheet a person is meant to read.
      last_seen_activity = rhtp_max_date(occurred_at),
      .groups = "drop"
    )

  # Sample title: the most-repeated source document title among the records
  # that resolved to this host. Titles are RCJ's, i.e. a search aid and never
  # quotable (§0.1, CLAUDE.md §6) — this column exists so a verifier can tell
  # a procurement portal from a press-release archive at a glance.
  sample_titles <- if (!is.null(records) && nrow(records) > 0 &&
                       all(c("state", "state_source_url", "source_doc_title")
                           %in% names(records))) {
    records %>%
      dplyr::filter(!is.na(state_source_url), !is.na(source_doc_title)) %>%
      dplyr::mutate(url_host = host_of(state_source_url)) %>%
      dplyr::filter(!is.na(url_host)) %>%
      dplyr::count(state, url_host, source_doc_title, name = "n_title") %>%
      dplyr::group_by(state, url_host) %>%
      dplyr::slice_max(n_title, n = 1, with_ties = FALSE) %>%
      dplyr::ungroup() %>%
      dplyr::select(state, url_host, sample_source_title = source_doc_title)
  } else {
    tibble::tibble(state = character(), url_host = character(),
                   sample_source_title = character())
  }

  candidates <- candidates %>%
    dplyr::left_join(sample_titles, by = c("state", "url_host"))

  gaps <- setdiff(valid_states, unique(candidates$state))

  gap_rows <- tibble::tibble(
    state = gaps,
    url_host = NA_character_,
    n_activity_references = 0L,
    n_document_urls = 0L,
    example_url = NA_character_,
    last_seen_activity = as.Date(NA),
    sample_source_title = NA_character_
  )

  worksheet <- dplyr::bind_rows(candidates, gap_rows) %>%
    dplyr::arrange(state, dplyr::desc(n_activity_references), url_host) %>%
    dplyr::group_by(state) %>%
    dplyr::mutate(candidate_rank = dplyr::row_number()) %>%
    dplyr::ungroup()

  # Empty verification columns, in the §7.3 field order.
  for (col in RHTP_WORKSHEET_VERIFY_COLUMNS) {
    worksheet[[col]] <- NA_character_
  }

  worksheet %>%
    dplyr::mutate(
      verification_status = dplyr::if_else(
        n_activity_references == 0L, "NO_CANDIDATE", "UNVERIFIED"
      ),
      instruction = dplyr::if_else(
        n_activity_references == 0L,
        paste0("No /activity siteUrl for this state. Compile the RHTP program ",
               "page and award posting location by hand (§7.2, §7.3)."),
        paste0("Open example_url. If this host is where notices of award are ",
               "posted, put that page in award_posting_url and set ",
               "last_verified. If it is a pass-through administrator, fill ",
               "pass_through_admin instead (§7.3).")
      )
    ) %>%
    dplyr::relocate(
      state, candidate_rank, url_host, sample_source_title, example_url,
      n_activity_references, n_document_urls, last_seen_activity,
      verification_status
    )
}


#' Write the worksheet as a CSV and an Excel workbook
#'
#' CSV is the committed artefact — it diffs, and it is what comes back from
#' review. The workbook is the convenience copy for the actual browser work:
#' frozen header, autofilter, the verification columns visibly highlighted and
#' wide enough to type a URL into.
rhtp_write_registry_worksheet <- function(worksheet, xlsx = TRUE) {
  csv_path <- rhtp_path("state_source_registry_worksheet", create = TRUE)
  readr::write_csv(worksheet, csv_path)
  message("  written to ", csv_path)

  if (!isTRUE(xlsx)) return(invisible(csv_path))

  xlsx_path <- rhtp_path(
    "output", paste0("state_source_registry_worksheet_", Sys.Date(), ".xlsx"),
    create = TRUE
  )

  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "Registry verification")
  openxlsx::writeData(wb, "Registry verification", worksheet,
                      withFilter = TRUE)
  openxlsx::freezePane(wb, "Registry verification", firstActiveRow = 2)

  header <- openxlsx::createStyle(textDecoration = "bold", fgFill = "#D9E1F2",
                                  border = "bottom", wrapText = TRUE)
  to_fill <- openxlsx::createStyle(fgFill = "#FFF2CC")
  no_candidate <- openxlsx::createStyle(fgFill = "#FCE4D6")

  n_rows <- nrow(worksheet)
  openxlsx::addStyle(wb, "Registry verification", header, rows = 1,
                     cols = seq_len(ncol(worksheet)), gridExpand = TRUE)

  verify_cols <- match(RHTP_WORKSHEET_VERIFY_COLUMNS, names(worksheet))
  verify_cols <- verify_cols[!is.na(verify_cols)]

  if (n_rows > 0 && length(verify_cols) > 0) {
    openxlsx::addStyle(wb, "Registry verification", to_fill,
                       rows = seq_len(n_rows) + 1, cols = verify_cols,
                       gridExpand = TRUE, stack = TRUE)
  }

  gap_rows <- which(worksheet$verification_status == "NO_CANDIDATE")
  if (length(gap_rows) > 0) {
    openxlsx::addStyle(wb, "Registry verification", no_candidate,
                       rows = gap_rows + 1, cols = 1:3,
                       gridExpand = TRUE, stack = TRUE)
  }

  # Explicit widths, never auto (§11). Anything unnamed here -- the eight
  # verification columns -- gets a width wide enough to type a URL into.
  widths <- c(state = 7, candidate_rank = 7, url_host = 42,
              sample_source_title = 60, example_url = 60,
              n_activity_references = 12, n_document_urls = 12,
              last_seen_activity = 13, verification_status = 15,
              instruction = 70)

  col_width <- function(nm) {
    w <- unname(widths[nm])
    if (length(w) == 0 || is.na(w)) 26 else w
  }

  purrr::walk(seq_along(names(worksheet)), function(i) {
    openxlsx::setColWidths(wb, "Registry verification", cols = i,
                           widths = col_width(names(worksheet)[i]))
  })

  openxlsx::saveWorkbook(wb, xlsx_path, overwrite = TRUE)
  message("  written to ", xlsx_path)

  invisible(c(csv = csv_path, xlsx = xlsx_path))
}


# -- §7.3 Validating the hand-verified registry ----------------------------

#' Validate data/reference/state_source_registry.csv once a human has built it
#'
#' Called by Stage 4 before it fetches anything, and runnable on its own so
#' the file coming back from offline verification can be checked before it is
#' committed. §13.12: a state missing a verified `award_posting_url` cannot be
#' validated, and that is reported as a deliverable gap rather than silently
#' skipped.
#'
#' @param path The registry CSV.
#' @param require_complete Error rather than warn when states are unverified.
rhtp_validate_state_registry <- function(path = NULL,
                                         require_complete = FALSE) {
  if (is.null(path)) path <- rhtp_path("state_source_registry")

  if (!file.exists(path)) {
    stop(
      "data/reference/state_source_registry.csv does not exist.\n",
      "It is compiled OFF-SESSION from the verification worksheet (§7.2): ",
      "Rscript R/03_state_registry.R --worksheet",
      call. = FALSE
    )
  }

  registry <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)

  missing_cols <- setdiff(RHTP_REGISTRY_COLUMNS, names(registry))
  if (length(missing_cols) > 0) {
    stop(
      "state_source_registry.csv is missing §7.3 column(s): ",
      paste(missing_cols, collapse = ", "), ".",
      call. = FALSE
    )
  }

  valid_states <- rhtp_cms_states()$state

  stray <- setdiff(registry$state, valid_states)
  if (length(stray) > 0) {
    stop(
      "state_source_registry.csv carries state code(s) not in the 50-row CMS ",
      "list (§13.14): ", paste(stray, collapse = ", "), ".",
      call. = FALSE
    )
  }

  verified <- registry %>%
    dplyr::filter(!is.na(award_posting_url), nzchar(award_posting_url),
                  !is.na(last_verified), nzchar(as.character(last_verified)))

  unverified <- setdiff(valid_states, verified$state)

  status <- tibble::tibble(
    n_rows = nrow(registry),
    n_states_verified = length(unique(verified$state)),
    n_states_unverified = length(unverified),
    unverified_states = rhtp_collapse_states(unverified),
    complete = length(unverified) == 0
  )

  if (length(unverified) > 0) {
    msg <- paste0(
      length(unverified), " of 50 states have no verified award_posting_url ",
      "(§13.12): ", rhtp_collapse_states(unverified), ".\n",
      "Stage 4 cannot validate a Tier 3 candidate in those states. Report ",
      "them as deliverable gaps, never as zero."
    )
    if (isTRUE(require_complete)) {
      stop(msg, call. = FALSE)
    }
    warning(msg, call. = FALSE)
  }

  invisible(list(registry = registry, status = status,
                 unverified_states = unverified))
}

rhtp_collapse_states <- function(x) {
  if (length(x) == 0) return(NA_character_)
  paste(sort(x), collapse = " ")
}


# -- Orchestrator ----------------------------------------------------------

#' Run Stage 3
#'
#' @param allotments Build the §7.1 CMS anchor (one network call to cms.gov).
#' @param worksheet Build the §7.2 verification worksheet from Stage 2 output.
rhtp_state_registry <- function(allotments = TRUE, worksheet = TRUE,
                                fetch_date = Sys.Date(), force = FALSE,
                                write = TRUE) {
  out <- list()

  if (isTRUE(allotments)) {
    out$allotments <- rhtp_build_cms_allotments(
      fetch_date = fetch_date, force = force, write = write
    )
  }

  if (isTRUE(worksheet)) {
    message("\n-- Stage 3 §7.2: state source registry verification worksheet --")

    sources_path <- rhtp_path("interim", "stage2_state_sources.rds")
    records_path <- rhtp_path("interim", "stage2_record_table.rds")

    if (!file.exists(sources_path)) {
      stop(
        "No Stage 2 /activity output at '", sources_path, "'.\n",
        "Run Stage 2 first: Rscript R/02_normalize.R --run",
        call. = FALSE
      )
    }

    state_sources <- readRDS(sources_path)
    records <- if (file.exists(records_path)) {
      readRDS(records_path) %>% dplyr::filter(is.na(superseded_by))
    } else {
      NULL
    }

    ws <- rhtp_registry_worksheet(state_sources, records = records)
    out$worksheet <- ws

    n_gap <- sum(ws$verification_status == "NO_CANDIDATE")
    message("  ", nrow(ws), " rows: ", nrow(ws) - n_gap,
            " candidate hosts across ",
            dplyr::n_distinct(ws$state[ws$verification_status != "NO_CANDIDATE"]),
            " states, plus ", n_gap, " state(s) with no candidate.")
    message("  every row is UNVERIFIED by construction (§7.2) — a person ",
            "loads each URL and sets last_verified.")

    if (isTRUE(write)) {
      rhtp_write_registry_worksheet(ws)
    }
  }

  invisible(out)
}


# -- CLI entry point -------------------------------------------------------

# Sourcing this file does nothing. --allotments makes one call to cms.gov and
# spends no RCJ quota; --worksheet is offline and reads Stage 2's output.
#
#   Rscript R/03_state_registry.R --run           # both
#   Rscript R/03_state_registry.R --allotments    # §7.1 only
#   Rscript R/03_state_registry.R --worksheet     # §7.2 only
#   Rscript R/03_state_registry.R --validate      # §7.3, once the registry lands
#
if (!interactive() && identical(sys.nframe(), 0L)) {
  cli_args <- commandArgs(trailingOnly = TRUE)

  if ("--validate" %in% cli_args) {
    result <- rhtp_validate_state_registry()
    print(as.data.frame(result$status), row.names = FALSE)
  } else if (any(c("--run", "--allotments", "--worksheet") %in% cli_args)) {
    run_all <- "--run" %in% cli_args
    rhtp_state_registry(
      allotments = run_all || "--allotments" %in% cli_args,
      worksheet  = run_all || "--worksheet" %in% cli_args,
      force      = "--force" %in% cli_args
    )
  }
}
