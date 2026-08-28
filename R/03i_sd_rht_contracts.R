# 03i_sd_rht_contracts.R -----------------------------------------------------
# South Dakota RHTP contracts from the state transparency portal
# -> data/reference/sd_rht_contracts.csv (+ a render).
#
# READ THIS FIRST: THIS IS NOT SOUTH DAKOTA'S SUBAWARD LIST, AND THE SUBAWARD
# LIST IS NOT PUBLISHED ANYWHERE THIS SESSION COULD REACH.
#
# South Dakota has announced two rounds of recipient-level RHTP awards:
#   - $31,500,000 to 28 projects across 20 health systems (2026-07-23)
#   - $90,000,000 to 82 rural healthcare organizations   (2026-08-19)
# Session 11 recorded that the reporting says grant contracts post to the state
# transparency portal once finalised, and named open.sd.gov as the route.
#
# The portal was reachable this session and it was searched exhaustively.
# NEITHER ROUND IS THERE. What the register does hold under the state's own
# `RHT` document-number series is 13 executed contracts totalling $5,618,367 --
# every one of them programme management, consulting, evaluation or workforce
# training. The largest is $1,462,802. Searching DOH's grants with no filter at
# all returns 463 rows totalling $39.4M whose single largest row is $2.6M and
# is not RHTP; "Rural Strong", the name of the $31.5M round, returns zero rows.
# An 82-organisation, $90M round cannot be hiding in that.
#
# So the finding is a negative one and it is worth having: the route session 11
# identified is the right route, the contracts have not been posted to it yet,
# and this file is the extractor that picks them up when they are. The 13 rows
# below are real, executed, recipient-level RHTP award actions on a primary
# source (§8 PROCUREMENT_PORTAL_POSTING) and they belong in the record -- but
# they are administrative spend, they are NOT the announced rounds, and
# rhtp_sd_reconcile() states that in the output rather than leaving a reader to
# infer it from a total that looks small.
#
# THE PORTAL'S SHAPE. https://open.sd.gov/contracts.aspx is an ASP.NET WebForms
# search: a POST carrying __VIEWSTATE and __EVENTVALIDATION, with a department
# dropdown, three "contains" boxes (vendor, description, contract/grant number)
# and an All/Contracts-only/Grants-only filter. Results come back as one HTML
# table -- Contract/Grant Number, Description (TRUNCATED to ~75 characters),
# Vendor Name, Agency, Begin Date, Amount -- unpaged; a 463-row result arrived
# in a single response. Each row's number links to a STABLE GET url,
# contractsDocShow.aspx?DocID=<number>, which carries the FULL description plus
# the vendor's city and state and the solicitation type. So the search is how
# you find the series and the detail pages are what you quote, and both are
# archived here.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only -- never |>. No setwd(); all
# paths go through here::here(). --fetch is the only mode that touches the
# network.
#
# CLI:
#   Rscript R/03i_sd_rht_contracts.R --probe     # report the portal's shape only
#   Rscript R/03i_sd_rht_contracts.R --fetch     # archive search + details
#   Rscript R/03i_sd_rht_contracts.R --validate  # parse + assert, no writes
#   Rscript R/03i_sd_rht_contracts.R --build     # assert, write CSV + xlsx

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

SD_STATE <- "SD"

SD_PORTAL_SEARCH_URL <- "https://open.sd.gov/contracts.aspx"
SD_PORTAL_DOC_URL    <- "https://open.sd.gov/contractsDocShow.aspx?DocID="
SD_DOH_PROGRAM_URL   <- paste0(
  "https://doh.sd.gov/healthcare-professionals/rural-health/",
  "rural-health-transformation-project/"
)

# South Dakota's own document-number series for Rural Health Transformation.
# The search is a substring match on the number, so "RHT" catches every fiscal
# year's prefix (26RHT..., 27RHT...) without this file having to know them.
SD_SERIES <- "RHT"

SD_EVIDENCE_DIR    <- "data/evidence/SD"
SD_SEARCH_FILE     <- "2026-08-28_open_sd_contract_search_RHT.html"
SD_DETAIL_SUBDIR   <- "contract_details"
SD_MANIFEST_FILE   <- "sd_rht_contracts.manifest.txt"
SD_CSV  <- "data/reference/sd_rht_contracts.csv"
SD_XLSX <- "SD_rht_contracts.xlsx"

# What South Dakota has ANNOUNCED but not posted. Held here so the
# reconciliation can name the gap instead of a reader having to know it.
SD_ANNOUNCED_ROUNDS <- tibble::tribble(
  ~round,                                       ~announced,   ~recipients, ~amount,
  "Rural Strong grants (2026-07-23)",           "2026-07-23", "28 projects across 20 health systems", 31500000,
  "Technology and data grants (2026-08-19)",    "2026-08-19", "82 rural healthcare organizations",    90000000
)
SD_CMS_YEAR1_AWARD <- 189477607.26  # stated in DOH's own press-release footnote


# -- Fetch -------------------------------------------------------------------

#' Post the portal's contract/grant search
#'
#' The form is ASP.NET WebForms, so the hidden state has to be read from a fresh
#' GET of the form page and echoed back. Returns the response HTML.
rhtp_sd_portal_search <- function(number_contains = SD_SERIES,
                                  description_contains = "",
                                  department = "0", filter = "Radio1") {
  cfg <- rhtp_config()

  form <- httr2::request(SD_PORTAL_SEARCH_URL) %>%
    httr2::req_user_agent(cfg$api$user_agent) %>%
    httr2::req_timeout(cfg$api$timeout_seconds) %>%
    httr2::req_retry(max_tries = 3, backoff = ~ 2^.x) %>%
    httr2::req_perform() %>%
    httr2::resp_body_string()

  doc <- rvest::read_html(form)
  hidden <- function(name) {
    node <- rvest::html_element(doc, paste0("input[name='", name, "']"))
    if (length(node) == 0L || is.na(node)) {
      stop("[SD] the search form carries no `", name, "` field. open.sd.gov has ",
           "changed shape; refusing to post a request it will not understand.",
           call. = FALSE)
    }
    rvest::html_attr(node, "value")
  }

  body <- list(
    `__VIEWSTATE` = hidden("__VIEWSTATE"),
    `__VIEWSTATEGENERATOR` = hidden("__VIEWSTATEGENERATOR"),
    `__EVENTVALIDATION` = hidden("__EVENTVALIDATION"),
    `__EVENTTARGET` = "", `__EVENTARGUMENT` = "",
    ddl_DoA = department,
    tb_Vendor = "",
    tb_Doc_Descp = description_contains,
    tb_Contract_number = number_contains,
    RadioGroup1 = filter,
    btn_Search = "Search"
  )

  resp <- httr2::request(SD_PORTAL_SEARCH_URL) %>%
    httr2::req_user_agent(cfg$api$user_agent) %>%
    httr2::req_timeout(cfg$api$timeout_seconds) %>%
    httr2::req_headers(Referer = SD_PORTAL_SEARCH_URL) %>%
    httr2::req_body_form(!!!body) %>%
    httr2::req_retry(max_tries = 3, backoff = ~ 2^.x) %>%
    httr2::req_perform()

  if (httr2::resp_status(resp) != 200) {
    stop("[SD] the contract search returned HTTP ", httr2::resp_status(resp),
         call. = FALSE)
  }
  httr2::resp_body_string(resp)
}


#' Report the portal's shape without writing anything
#'
#' This is the probe that established the negative finding above, kept as a
#' runnable check rather than a claim in a comment. Re-run it to see whether the
#' announced rounds have posted since.
rhtp_sd_probe <- function() {
  probes <- tibble::tribble(
    ~label,                              ~args,
    "RHT number series (all agencies)",  list(number_contains = SD_SERIES),
    "'Rural Strong' in the description", list(number_contains = "", description_contains = "Rural Strong"),
    "'Rural Health Transformation'",     list(number_contains = "", description_contains = "Rural Health Transformation"),
    "DOH grants, no filter",             list(number_contains = "", department = "09 ", filter = "Radio3")
  )

  purrr::pmap_dfr(probes, function(label, args) {
    html <- do.call(rhtp_sd_portal_search, args)
    rows <- rhtp_sd_parse_search(html)
    # A probe that returns nothing is a result, not an error -- "Rural Strong"
    # returning zero rows is half the finding -- so an empty table must not
    # blow up on a missing amount column.
    amounts <- if (nrow(rows)) rows$amount else numeric(0)
    tibble::tibble(
      probe = label,
      rows = nrow(rows),
      total = sum(amounts, na.rm = TRUE),
      largest = if (length(amounts)) max(amounts, na.rm = TRUE) else NA_real_
    )
  })
}


rhtp_sd_fetch <- function(force = FALSE) {
  cfg <- rhtp_config()
  dir <- here::here(SD_EVIDENCE_DIR)
  detail_dir <- file.path(dir, SD_DETAIL_SUBDIR)
  dir.create(detail_dir, recursive = TRUE, showWarnings = FALSE)
  search_path <- file.path(dir, SD_SEARCH_FILE)

  if (file.exists(search_path) && !force) {
    message("  already archived: ", SD_SEARCH_FILE, " -- pass --force to re-fetch.")
    return(invisible(dir))
  }

  html <- rhtp_sd_portal_search(SD_SERIES)
  found <- rhtp_sd_parse_search(html)
  if (!nrow(found)) {
    stop("[SD] the '", SD_SERIES, "' number search returned zero rows. It ",
         "returned 13 when this was written; zero means the portal changed or ",
         "the series was renumbered. Refusing to archive an empty result, ",
         "which would read as 'South Dakota has awarded nothing'.",
         call. = FALSE)
  }

  writeBin(charToRaw(html), search_path)

  details <- purrr::map(found$contract_number, function(number) {
    # The DocID is the number space-padded to the portal's own column width;
    # the portal is tolerant of the trimmed form, so the trimmed form is what is
    # requested and what names the archived file.
    url <- paste0(SD_PORTAL_DOC_URL, utils::URLencode(number, reserved = TRUE))
    body <- httr2::request(url) %>%
      httr2::req_user_agent(cfg$api$user_agent) %>%
      httr2::req_timeout(cfg$api$timeout_seconds) %>%
      httr2::req_retry(max_tries = 3, backoff = ~ 2^.x) %>%
      httr2::req_perform() %>%
      httr2::resp_body_string()

    path <- file.path(detail_dir, paste0(number, ".html"))
    writeBin(charToRaw(body), path)
    list(number = number, url = url, body = body, path = path)
  })

  sha <- function(x) digest::digest(x, algo = "sha256", serialize = FALSE)

  writeLines(c(
    paste0(
      "RHTP tracker archive (spec 0.4 / 0.5): South Dakota RHTP contracts on the\n",
      "state transparency portal.\n\n",
      "fetched_utc     : ", format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), "\n",
      "state           : SD\n",
      "host            : open.sd.gov\n",
      "source_doc_type : PROCUREMENT_PORTAL_POSTING\n",
      "program         : South Dakota Rural Health Transformation, DOH\n",
      "cms_year1_award : $189,477,607.26 (stated in DOH's press-release footnote)\n\n",
      "WHAT IS HERE, AND WHAT IS NOT\n\n",
      "THIS IS NOT SOUTH DAKOTA'S SUBAWARD LIST. SD has announced $31.5M to 28\n",
      "projects (2026-07-23) and $90M to 82 rural healthcare organizations\n",
      "(2026-08-19). NEITHER IS ON THIS PORTAL as of the fetch date above. The\n",
      "register was searched on the RHT number series, on 'Rural Strong', on\n",
      "'Rural Health Transformation', and with DOH's grants listed unfiltered\n",
      "(463 rows, $39.4M, largest single row $2.6M and not RHTP). An\n",
      "82-organisation, $90M round is not in that.\n\n",
      "What IS here is the RHT series: ", nrow(found), " executed contracts totalling $",
      format(sum(found$amount), big.mark = ","), ", all programme management,\n",
      "consulting, evaluation or workforce training. Real, primary, recipient-\n",
      "level RHTP award actions -- and administrative spend, not the announced\n",
      "rounds. Do not read the total as South Dakota's Tier 3 figure.\n\n",
      "THE TWO ANNOUNCEMENTS THEMSELVES could not be archived: they live on\n",
      "news.sd.gov, which is refused at CONNECT (403) from this session. Only\n",
      "doh.sd.gov and open.sd.gov are reachable. Ask for news.sd.gov.\n\n",
      "SEARCH ARCHIVE\n\n",
      "  file    : ", SD_SEARCH_FILE, "\n",
      "  query   : contract/grant number contains '", SD_SERIES,
      "', all agencies, all types\n",
      "  method  : POST ", SD_PORTAL_SEARCH_URL,
      " (ASP.NET WebForms; __VIEWSTATE echoed)\n",
      "  bytes   : ", nchar(html, type = "bytes"), "\n",
      "  sha256  : ", sha(html), "\n",
      "  rows    : ", nrow(found), "\n\n",
      "DETAIL PAGES (stable GET urls; each carries the FULL description, which\n",
      "the search table truncates to ~75 characters)\n"
    ),
    purrr::map_chr(details, function(d) paste0(
      "\n  file    : ", SD_DETAIL_SUBDIR, "/", basename(d$path), "\n",
      "  url     : ", d$url, "\n",
      "  bytes   : ", nchar(d$body, type = "bytes"), "\n",
      "  sha256  : ", sha(d$body)
    ))
  ), file.path(dir, SD_MANIFEST_FILE))

  message("  archived South Dakota's RHT series to ", SD_EVIDENCE_DIR,
          " (", nrow(found), " contracts, $",
          format(sum(found$amount), big.mark = ","),
          " -- NOT the announced $31.5M and $90M rounds)")
  invisible(dir)
}


# -- Parse -------------------------------------------------------------------

SD_SEARCH_COLUMNS <- c("contract_number", "description_truncated", "awardee",
                       "agency", "begin_date", "amount_raw")

#' Parse the portal's result table
rhtp_sd_parse_search <- function(html) {
  doc <- rvest::read_html(html)
  tables <- rvest::html_elements(doc, "table")
  if (length(tables) == 0L) return(tibble::tibble())
  if (length(tables) != 1L) {
    stop("[SD] expected exactly 1 result table, found ", length(tables),
         ". Refusing to guess which one holds the contracts.", call. = FALSE)
  }

  rows <- rvest::html_elements(tables[[1]], "tr")
  cells <- purrr::map(rows, function(r) {
    stringr::str_squish(rvest::html_text2(rvest::html_elements(r, "td")))
  })
  cells <- purrr::keep(cells, ~ length(.x) == length(SD_SEARCH_COLUMNS))
  if (!length(cells)) return(tibble::tibble())

  out <- tibble::as_tibble(
    do.call(rbind, cells), .name_repair = ~ SD_SEARCH_COLUMNS)

  out %>%
    dplyr::mutate(
      contract_number = stringr::str_squish(.data$contract_number),
      awardee = stringr::str_squish(.data$awardee),
      amount = readr::parse_number(.data$amount_raw),
      begin_date = as.Date(.data$begin_date, format = "%Y%m%d")
    ) %>%
    dplyr::filter(nzchar(.data$contract_number))
}


# The labelled fields a detail page carries, in the order the page prints them.
# Two SHAPES exist and the difference matters: a CONTRACT page carries
# `Solicitation Type` and ends with the "* If an image..." footer, while a GRANT
# page carries no solicitation type and ends with a `CFDA` block -- the federal
# assistance listing number, 93.798, which is the Rural Health Transformation
# Program itself and is independent corroboration that the row is RHTP.
#
# Parsing by a trailing sentinel got this wrong: keyed on the contract footer,
# the description on a grant page ran on into the portal's CFDA GLOSSARY text
# ("CFDA stands for Catalog of Federal Domestic Assistance..."), which would
# then be quoted as the state's own description of the award and fed to the
# §10.2 flow rules. Fields are taken between their own label and whichever
# label comes next instead, so a page that lacks one simply skips it.
SD_DETAIL_LABELS <- c("Amount", "Agency", "Vendor Name", "City", "State",
                      "Solicitation Type", "Description", "CFDA")


#' Pull the labelled fields off an archived detail page
rhtp_sd_parse_detail <- function(html) {
  text <- stringr::str_squish(rvest::html_text2(rvest::read_html(html)))
  # The page's own footer, on the contract shape. Treated as a terminator so the
  # last field does not swallow it.
  text <- stringr::str_replace(text, "\\* If an image.*$", "|END|")

  field <- function(label) {
    later <- SD_DETAIL_LABELS[seq(match(label, SD_DETAIL_LABELS) + 1L,
                                  length(SD_DETAIL_LABELS))]
    later <- later[!is.na(later)]
    stops <- paste(c(paste0(later, ":"), "\\|END\\|"), collapse = "|")
    m <- stringr::str_match(text, paste0(label, ":\\s*(.*?)\\s*(?:", stops, ")"))
    if (is.na(m[1, 2])) NA_character_ else stringr::str_squish(m[1, 2])
  }

  cfda <- field("CFDA")
  # The CFDA field is preceded on the page by the portal's glossary blurb; the
  # number itself is the last token.
  cfda_number <- if (is.na(cfda)) NA_character_ else {
    hit <- stringr::str_extract(cfda, "\\d{2}\\.\\d{3}")
    hit
  }

  tibble::tibble(
    vendor_city = field("City"),
    vendor_state = field("State"),
    solicitation_type = field("Solicitation Type"),
    description = field("Description"),
    cfda_number = cfda_number
  )
}


rhtp_sd_build <- function() {
  dir <- here::here(SD_EVIDENCE_DIR)
  search_path <- file.path(dir, SD_SEARCH_FILE)
  if (!file.exists(search_path)) {
    stop("[SD] the search archive is missing: ", search_path,
         ". Run --fetch first.", call. = FALSE)
  }

  found <- rhtp_sd_parse_search(readr::read_file(search_path))

  details <- purrr::map_dfr(found$contract_number, function(number) {
    path <- file.path(dir, SD_DETAIL_SUBDIR, paste0(number, ".html"))
    if (!file.exists(path)) {
      stop("[SD] no archived detail page for ", number,
           ". The search table truncates descriptions, so the detail page is ",
           "what the determination quotes; refusing to code from a truncation.",
           call. = FALSE)
    }
    rhtp_sd_parse_detail(readr::read_file(path)) %>%
      dplyr::mutate(contract_number = number)
  })

  joined <- found %>%
    dplyr::left_join(details, by = "contract_number") %>%
    dplyr::arrange(.data$contract_number)

  if (any(is.na(joined$description) | !nzchar(joined$description))) {
    missing <- joined$contract_number[is.na(joined$description)]
    stop("[SD] no full description parsed for: ",
         paste(missing, collapse = ", "), call. = FALSE)
  }

  classified <- joined %>%
    rhtp_classify_records(state = SD_STATE, description_col = "description")

  classified %>%
    dplyr::mutate(
      state = SD_STATE,
      row_no = dplyr::row_number(),
      note = paste0(.data$agency, " | ", .data$solicitation_type,
                    " | ", .data$vendor_city, ", ", .data$vendor_state),
      recipient_confirmed = "Yes",
      amount_confirmed = "Yes",
      fiscal_year = "FY2026 (Year 1)",
      source_document_title = paste0(
        "South Dakota Open SD - Grants and Contracts register, contract ",
        .data$contract_number
      ),
      state_source_url = paste0(SD_PORTAL_DOC_URL, .data$contract_number),
      validation_source_type = "PROCUREMENT_PORTAL_POSTING",
      extraction_method = "MODEL_ASSISTED",
      validator = "AI-assisted - CONFIRM",
      ccn = NA_character_,
      aha_id = NA_character_,
      rural_designation = NA_character_,
      reviewer = NA_character_,
      recipient_type_source = NA_character_,
      amount_basis = "PER_CONTRACT",
      amount_precision = "EXACT_AS_PUBLISHED",
      disbursement_status = "CONTRACT_EXECUTED",
      source_archive_path = file.path(SD_EVIDENCE_DIR, SD_DETAIL_SUBDIR,
                                      paste0(.data$contract_number, ".html")),
      recipient_names_source_url = paste0(SD_PORTAL_DOC_URL,
                                          .data$contract_number),
      activity_type_raw = .data$solicitation_type,
      determination_basis = paste0(
        .data$determination_basis,
        " Source: South Dakota's Grants and Contracts register (SDCL 1-56-10 /",
        " 1-27-46), contract ", .data$contract_number, ", begun ",
        .data$begin_date,
        ". This is ADMINISTRATIVE RHTP spend and is NOT part of South Dakota's",
        " announced $31.5M (28 projects) or $90M (82 organisations) rounds,",
        " neither of which has been posted to this register."
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
      # -- South Dakota's own fields -------------------------------------
      "contract_number", "agency", "begin_date", "vendor_city", "vendor_state",
      "solicitation_type", "cfda_number", "description"
    )
}


rhtp_sd_records <- function(path = SD_CSV) {
  full <- here::here(path)
  if (!file.exists(full)) {
    stop("[SD] ", path, " does not exist. Run --build.", call. = FALSE)
  }
  readr::read_csv(full, show_col_types = FALSE, progress = FALSE)
}


# -- Reconciliation and assertions -------------------------------------------

#' What was extracted, and -- more importantly -- what was not
#'
#' The gap is the finding. A reader who sees $5.6M for a state that announced
#' $121.5M must be told why in the same table, not left to infer a shortfall.
rhtp_sd_reconcile <- function(records = rhtp_sd_build()) {
  hosp <- records$distributed_to_hospital == "Yes"

  tibble::tribble(
    ~measure,                                        ~value,
    "contracts extracted from the RHT series",       as.character(nrow(records)),
    "distinct vendors",                              as.character(dplyr::n_distinct(records$awardee)),
    "total extracted",                               format(sum(records$amount), big.mark = ",", nsmall = 2),
    "largest single contract",                       format(max(records$amount), big.mark = ",", nsmall = 2),
    "what these are",                                "programme management, consulting, evaluation, workforce training",
    "-- NOT EXTRACTED, BECAUSE NOT PUBLISHED --",    "",
    "Rural Strong round announced 2026-07-23",       "$31,500,000 to 28 projects across 20 health systems",
    "Technology/data round announced 2026-08-19",    "$90,000,000 to 82 rural healthcare organizations",
    "either round found on open.sd.gov",             "no",
    "announcements archived",                        "no -- they are on news.sd.gov, refused at CONNECT (403)",
    "announced but unextracted",                     format(121500000, big.mark = ",", nsmall = 2),
    "CMS Year 1 award for South Dakota",             format(SD_CMS_YEAR1_AWARD, big.mark = ",", nsmall = 2),
    "-- CODING --",                                  "",
    "rows distributed_to_hospital = Yes",            as.character(sum(hosp)),
    "dollars distributed_to_hospital = Yes",         format(sum(records$amount[hosp]), big.mark = ",", nsmall = 2)
  )
}


rhtp_sd_assert <- function(records = rhtp_sd_build()) {
  if (!nrow(records)) {
    stop("[SD] zero contracts extracted; an empty table would read as 'South ",
         "Dakota has awarded nothing', which is the opposite of the truth.",
         call. = FALSE)
  }

  if (dplyr::n_distinct(records$contract_number) != nrow(records)) {
    stop("[SD] the contract number is the key and must be unique.",
         call. = FALSE)
  }
  if (!all(stringr::str_detect(records$contract_number, SD_SERIES))) {
    stop("[SD] a row outside the ", SD_SERIES, " series was captured.",
         call. = FALSE)
  }

  if (any(is.na(records$amount)) || any(records$amount <= 0)) {
    stop("[SD] every contract must carry a positive amount.", call. = FALSE)
  }

  # THE ASSERTION THAT KEEPS THE CLAIM HONEST. If this table ever grows to
  # anything like the announced rounds, it is no longer administrative spend and
  # the file's whole framing -- and its reconciliation -- has to be rewritten
  # rather than silently carrying a total it describes as small.
  if (sum(records$amount) > 20e6) {
    stop("[SD] the RHT series now totals ",
         format(sum(records$amount), big.mark = ","),
         ", which is far beyond the administrative spend this file describes. ",
         "The announced rounds may have posted. Re-read the register and ",
         "rewrite this file's framing rather than letting it report a figure ",
         "it calls small.", call. = FALSE)
  }
  if (sum(records$amount) > SD_CMS_YEAR1_AWARD) {
    stop("[SD] the extraction exceeds the CMS Year 1 award. §6.2 ceiling.",
         call. = FALSE)
  }

  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "determination_confidence", "flag_reason")) {
    bad <- setdiff(stats::na.omit(unique(records[[col]])), rhtp_vocabulary(col))
    if (length(bad)) {
      stop("[SD] ", col, " outside §8: ", paste(bad, collapse = ", "),
           call. = FALSE)
    }
  }

  wrong <- records %>%
    dplyr::filter(.data$distributed_to_hospital == "Yes",
                  !.data$recipient_type %in% c("HOSPITAL_OR_SYSTEM",
                                               "HOSPITAL_AFFILIATED_ENTITY"))
  if (nrow(wrong)) {
    stop("[SD] distributed_to_hospital = Yes on a non-hospital recipient: ",
         paste(wrong$awardee, collapse = "; "), call. = FALSE)
  }

  # Every row must say in its own basis that it is not the announced rounds.
  # This is the sentence that stops the $5.6M being quoted as South Dakota's
  # Tier 3 total once the row is separated from this file.
  if (!all(stringr::str_detect(records$determination_basis, "NOT part of"))) {
    stop("[SD] every row's determination_basis must state that it is not part ",
         "of the announced rounds.", call. = FALSE)
  }

  invisible(TRUE)
}


# -- Write -------------------------------------------------------------------

rhtp_sd_write <- function() {
  records <- rhtp_sd_build()
  rhtp_sd_assert(records)

  readr::write_csv(records, here::here(SD_CSV), na = "")

  wb <- openxlsx::createWorkbook()
  add <- function(sheet, data) {
    openxlsx::addWorksheet(wb, sheet)
    openxlsx::writeData(wb, sheet, data)
    openxlsx::freezePane(wb, sheet, firstRow = TRUE)
  }
  add("Contracts", records)
  add("Reconciliation", rhtp_sd_reconcile(records))
  add("Announced not published", SD_ANNOUNCED_ROUNDS)
  openxlsx::saveWorkbook(wb, here::here(SD_XLSX), overwrite = TRUE)

  message("  wrote ", SD_CSV, " and ", SD_XLSX, " (", nrow(records), " rows)")
  invisible(records)
}


# -- CLI ---------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--probe" %in% args) {
    print(rhtp_sd_probe(), n = Inf)
  } else if ("--fetch" %in% args) {
    rhtp_sd_fetch(force = "--force" %in% args)
  } else if ("--build" %in% args) {
    rhtp_sd_write()
    print(rhtp_sd_reconcile(rhtp_sd_records()), n = Inf)
  } else if ("--validate" %in% args) {
    recs <- rhtp_sd_build()
    rhtp_sd_assert(recs)
    print(rhtp_sd_reconcile(recs), n = Inf)
    message("[SD] all assertions passed.")
  } else {
    message("Usage: Rscript R/03i_sd_rht_contracts.R [--probe|--fetch|--validate|--build]")
  }
}
