# 03i_sd_rht_contracts.R -----------------------------------------------------
# South Dakota RHTP contracts from the state transparency portal
# -> data/reference/sd_rht_contracts.csv (+ a render).
#
# READ THIS FIRST: THE FILE NOW HOLDS TWO KINDS OF AWARD ACTION, AND THEY ARE
# TWO POOLS THAT MUST BE READ SEPARATELY. Read `award_pool` before any figure.
#
# South Dakota has announced two rounds of recipient-level RHTP awards:
#   - $31,500,000 to 28 "Rural Strong" grants across 20 health systems
#     (2026-07-23, KB0046839), contracts to post to OpenSD "once finalized"
#   - $90,000,000 to 82 rural healthcare organizations (2026-08-19, KB0047023)
# Both releases name NOBODY (R/03j). open.sd.gov, the state's Grants and
# Contracts register, is where a finalised contract appears.
#
# 2026-08-28 (session 12): the register's `RHT` document-number series held 13
# executed contracts, $5,618,367, every one programme management, consulting,
# evaluation or workforce training, and "Rural Strong" returned ZERO rows. The
# file was written as a negative: the route is right, the rounds are not there.
# That archive and its manifest block are kept exactly as written, because they
# are a true statement about that date.
#
# 2026-09-24 (session 64): the SAME series holds 26 contracts, $9,223,177:
#   * the 13 above, rows 1-13, unchanged in order and amount;
#   * 5 more administrative contracts (South Dakota Doulas, University of South
#     Dakota's training platform, Black Hills Special Services, South Dakota
#     State University's training platform, Engineering Solutions Inc), $1,725,658;
#   * 8 RURAL STRONG GRANTS, $1,879,152 -- each described on its detail page
#     "Implementation of a Rural Strong Grant as a part of the federal Rural
#     Health Transformation Program" (seven posted as grants under CFDA 93.798,
#     USD's as a contract with a state agency). These are TIER 3 AWARDS
#     TO NAMED RECIPIENTS, which this series had never carried, and FIVE are
#     hospitals: Bennett County Hospital (Martin), Community Memorial Hospital
#     (Burke), Community Memorial Hospital (Redfield) -- TWO DIFFERENT
#     HOSPITALS under one string, told apart only by the vendor city and never
#     merged -- Faulkton Area Medical Center, and Philip Health Services Inc.
#     Philip carries no hospital token; it is typed a hospital ONLY because
#     CMS's archived Hospital Enrollments file carries that exact string in
#     Philip, SD (CCN 431319, a CAH) -- data/evidence/SD/federal_records/.
#
# THE RURAL STRONG CONTRACTS ARE INSIDE THE $31.5M ROUND, NEVER ON TOP OF IT
# (§6.2). sd_year1_awardees.csv carries the round as one aggregate row whose
# round_amount already includes these eight; the two files are two readings of
# one pool of money. 20 of the 28 grants are still named nowhere, and their
# amount is stated by no source and is NOT computed by subtraction here.
#
# The $90M Technology and data round is STILL NOT on the register. Two RHTP
# contracts OUTSIDE the RHT series are recorded in SD_OUTSIDE_SERIES and not
# extracted.
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
#   Rscript R/03i_sd_rht_contracts.R --probe     # LIVE vs the archives, READ-ONLY
#   Rscript R/03i_sd_rht_contracts.R --fetch --force  # NEW dated archives + new details
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
SD_DETAIL_SUBDIR   <- "contract_details"
SD_MANIFEST_FILE   <- "sd_rht_contracts.manifest.txt"
SD_CSV  <- "data/reference/sd_rht_contracts.csv"
SD_XLSX <- "SD_rht_contracts.xlsx"

# THE SEARCH ARCHIVES, OLDEST FIRST (session 64). The register is re-read by a
# deliberate --fetch --force, which writes a NEW dated file and never rewrites
# an old one: the 2026-08-28 archive is the only evidence that the series then
# held 13 contracts, and the growth to 26 is measurable only as a diff of two
# archived documents (Alaska's rule, session 22). The LATEST archive is what
# the file is built from; every earlier one fixes the ROW ORDER, so the rows a
# reader already has keep their position and new contracts are appended.
SD_SEARCH_ARCHIVES <- c(
  "2026-08-28_open_sd_contract_search_RHT.html",
  "2026-09-24_open_sd_contract_search_RHT.html"
)
SD_SEARCH_FILE <- SD_SEARCH_ARCHIVES[1]                          # the first read
SD_SEARCH_LATEST <- SD_SEARCH_ARCHIVES[length(SD_SEARCH_ARCHIVES)]

# The two DESCRIPTION searches, archived from 2026-09-24 so --probe has a
# committed baseline for each rather than a number typed into a comment.
#   * "Rural Strong" is the name of the $31.5M round (2026-07-23). It returned
#     ZERO rows on 2026-08-28 and 8 on 2026-09-24.
#   * "Rural Health Transformation" catches RHTP contracts OUTSIDE the RHT
#     number series -- two of them on 2026-09-24 (see SD_OUTSIDE_SERIES).
SD_DESC_SEARCHES <- tibble::tribble(
  ~probe_key,     ~description_contains,          ~file,
  "rural_strong", "Rural Strong",                 "2026-09-24_open_sd_contract_search_desc_rural_strong.html",
  "rht_desc",     "Rural Health Transformation",  "2026-09-24_open_sd_contract_search_desc_rural_health_transformation.html"
)

# A Rural Strong GRANT is identified by the register's own full description on
# the detail page, never by the vendor's name or the amount.
SD_RURAL_STRONG_PATTERN <- "Implementation of a Rural Strong Grant"

# THE ROUND THE RURAL STRONG CONTRACTS BELONG TO. KB0046839 (2026-07-23):
# "28 Rural Strong grants" worth "$31.5 million" across "20 health systems",
# contracts to be posted to OpenSD "once finalized". The contracts here are
# SOME of those 28 and are INSIDE that $31.5M, never on top of it (§6.2).
SD_RS_ROUND_GRANTS <- 28L
SD_RS_ROUND_AMOUNT <- 31500000

# Pool labels. Two different kinds of award action share one number series.
SD_POOL_ADMIN <- "RHT series - programme administration, consulting, evaluation and workforce contracts"
SD_POOL_RS    <- "RHT series - Rural Strong grants (subset of the 28-grant, $31.5M round of 2026-07-23)"

# RHTP contracts on the register OUTSIDE the RHT number series, seen by the
# 'Rural Health Transformation' description search on 2026-09-24. NOT
# EXTRACTED -- this file is the RHT series -- and recorded so a reader knows
# the series is not the whole of what the register holds.
SD_OUTSIDE_SERIES <- tibble::tribble(
  ~contract_number, ~awardee,                         ~amount, ~what,
  "27SC091800",     "SD FOUNDATION FOR MEDICAL CARE", 150000,  "grant, begun 2026-05-01, CFDA 93.798; description is DOH's generic Rural Health Transformation paragraph -- RHTP money outside the series, a candidate for extraction",
  "26SC090058",     "BLACK HILLS SPECIAL SERVICES",   45000,   "contract, begun 2025-09-22 -- BEFORE the 2025-12-29 Notice of Award -- Professional Services under $50K; 'grant writing support for the Rural Health Transformation Program funding opportunity': APPLICATION support, not an award of RHTP money (§6.2 date test)"
)

# What South Dakota has ANNOUNCED. Held here so the reconciliation can name
# the gap instead of a reader having to know it.
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


#' Re-read the register LIVE and compare it with the committed archives
#'
#' READ-ONLY (§2.2): the live responses are parsed in memory and compared with
#' the archived search results on disk; nothing is written to data/evidence.
#' Until session 64 this returned bare row counts with no baseline, so every
#' run logged UNCHANGED/(unreported) -- including the runs after eight Rural
#' Strong contracts had posted. Each page now carries `changed`, which is TRUE
#' when the live result holds a contract the archive does not, lacks one it
#' does, or prices one differently. Re-basing is `--fetch --force` after a human
#' has READ what changed.
rhtp_sd_probe <- function(dir = here::here(SD_EVIDENCE_DIR)) {
  archived <- function(file) {
    rhtp_sd_parse_search(readr::read_file(file.path(dir, file)))
  }
  pages <- dplyr::bind_rows(
    tibble::tibble(page = "RHT number series (all agencies)",
                   number_contains = SD_SERIES, description_contains = "",
                   file = SD_SEARCH_LATEST),
    tibble::tibble(page = paste0("'", SD_DESC_SEARCHES$description_contains,
                                 "' in the description"),
                   number_contains = "",
                   description_contains = SD_DESC_SEARCHES$description_contains,
                   file = SD_DESC_SEARCHES$file)
  )

  purrr::pmap_dfr(pages, function(page, number_contains, description_contains, file) {
    live <- rhtp_sd_parse_search(rhtp_sd_portal_search(
      number_contains = number_contains,
      description_contains = description_contains))
    base <- archived(file)
    key <- function(x) if (nrow(x)) sort(paste(x$contract_number, x$amount)) else character(0)
    added <- setdiff(if (nrow(live)) live$contract_number else character(0),
                     if (nrow(base)) base$contract_number else character(0))
    tibble::tibble(
      page = page,
      changed = !identical(key(live), key(base)),
      rows = nrow(live),
      total = if (nrow(live)) sum(live$amount, na.rm = TRUE) else 0,
      archived_rows = nrow(base),
      archived_total = if (nrow(base)) sum(base$amount, na.rm = TRUE) else 0,
      new_contracts = paste(added, collapse = "; ")
    )
  })
}


#' Archive the register: the RHT series, the two description searches, and a
#' detail page for every contract not already archived
#'
#' RE-READING IS A DELIBERATE ACT (§2.2), AND IT NEVER REWRITES AN OLD ARCHIVE.
#' Session 12's fetch rewrote its one search file and every detail page on
#' --force, and its manifest from scratch. Here a re-read writes NEW files named
#' for the fetch date, fetches detail pages only for contracts that have none
#' (an archived detail page is the evidence a row's coding quotes; re-dating it
#' silently would make the manifest's fetch date stop meaning when it was read),
#' and APPENDS a dated block to the manifest. The 2026-08-28 block stays exactly
#' as written, because it is a true statement about 2026-08-28.
rhtp_sd_fetch <- function(force = FALSE, fetch_date = Sys.Date()) {
  cfg <- rhtp_config()
  dir <- here::here(SD_EVIDENCE_DIR)
  detail_dir <- file.path(dir, SD_DETAIL_SUBDIR)
  dir.create(detail_dir, recursive = TRUE, showWarnings = FALSE)

  stamp <- format(as.Date(fetch_date), "%Y-%m-%d")
  series_file <- paste0(stamp, "_open_sd_contract_search_RHT.html")
  series_path <- file.path(dir, series_file)

  if (file.exists(series_path) && !force) {
    message("  already archived: ", series_file, " -- pass --force to re-fetch.")
    return(invisible(dir))
  }
  if (series_file == SD_SEARCH_ARCHIVES[1]) {
    stop("[SD] refusing to overwrite the first search archive (",
         series_file, "): it is the only evidence of what the series held ",
         "on that date.", call. = FALSE)
  }

  html <- rhtp_sd_portal_search(SD_SERIES)
  found <- rhtp_sd_parse_search(html)
  if (!nrow(found)) {
    stop("[SD] the '", SD_SERIES, "' number search returned zero rows. It ",
         "returned 13 on 2026-08-28 and 26 on 2026-09-24; zero means the portal ",
         "changed or the series was renumbered. Refusing to archive an empty ",
         "result, which would read as 'South Dakota has awarded nothing'.",
         call. = FALSE)
  }

  desc <- purrr::pmap(SD_DESC_SEARCHES, function(probe_key, description_contains, file) {
    body <- rhtp_sd_portal_search(number_contains = "",
                                  description_contains = description_contains)
    list(file = paste0(stamp, sub("^\\d{4}-\\d{2}-\\d{2}", "", file)),
         query = description_contains, body = body,
         rows = rhtp_sd_parse_search(body))
  })

  writeBin(charToRaw(html), series_path)
  for (d in desc) writeBin(charToRaw(d$body), file.path(dir, d$file))

  # Detail pages: every RHT-series contract, plus the RHTP contracts the
  # description search finds outside the series (their pages are the evidence
  # for SD_OUTSIDE_SERIES; they are not extracted).
  wanted <- unique(c(found$contract_number,
                     unlist(purrr::map(desc, ~ .x$rows$contract_number))))
  missing <- wanted[!file.exists(file.path(detail_dir, paste0(wanted, ".html")))]

  details <- purrr::map(missing, function(number) {
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
  rs <- found %>%
    dplyr::filter(.data$contract_number %in% desc[[1]]$rows$contract_number)

  block <- c(
    paste0(
      "\n\n==========================================================================\n",
      "REFRESH ", stamp, " (fetched_utc ",
      format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), ")\n",
      "==========================================================================\n\n",
      "THE BLOCK ABOVE IS A TRUE STATEMENT ABOUT 2026-08-28 AND IS LEFT AS\n",
      "WRITTEN. As of this refresh the RHT series holds ", nrow(found),
      " contracts totalling $", format(sum(found$amount), big.mark = ","), ",\n",
      "and ", nrow(rs), " of them ($", format(sum(rs$amount), big.mark = ","),
      ") are described 'Implementation of a Rural Strong Grant as\n",
      "a part of the federal Rural Health Transformation Program' -- SOME of the\n",
      "28 Rural Strong grants ($31.5M) announced 2026-07-23. Those are Tier 3\n",
      "grants to named recipients, INSIDE the $31.5M round and never to be added\n",
      "on top of it. The Technology and data round ($90M, 82 grants) is still\n",
      "not on this register. Earlier archives were NOT re-fetched; detail pages\n",
      "below are only those that had no archived copy.\n\n",
      "SEARCH ARCHIVES\n",
      "\n  file    : ", series_file, "\n",
      "  query   : contract/grant number contains '", SD_SERIES,
      "', all agencies, all types\n",
      "  method  : POST ", SD_PORTAL_SEARCH_URL, " (ASP.NET WebForms)\n",
      "  bytes   : ", nchar(html, type = "bytes"), "\n",
      "  sha256  : ", sha(html), "\n",
      "  rows    : ", nrow(found)
    ),
    purrr::map_chr(desc, function(d) paste0(
      "\n  file    : ", d$file, "\n",
      "  query   : description contains '", d$query, "', all agencies, all types\n",
      "  bytes   : ", nchar(d$body, type = "bytes"), "\n",
      "  sha256  : ", sha(d$body), "\n",
      "  rows    : ", nrow(d$rows)
    )),
    "\nDETAIL PAGES (newly archived)",
    purrr::map_chr(details, function(d) paste0(
      "\n  file    : ", SD_DETAIL_SUBDIR, "/", basename(d$path), "\n",
      "  url     : ", d$url, "\n",
      "  bytes   : ", nchar(d$body, type = "bytes"), "\n",
      "  sha256  : ", sha(d$body)
    ))
  )
  cat(block, file = file.path(dir, SD_MANIFEST_FILE), sep = "\n", append = TRUE)

  if (!series_file %in% SD_SEARCH_ARCHIVES) {
    message("  NOTE: add '", series_file, "' to SD_SEARCH_ARCHIVES before --build.")
  }
  message("  archived South Dakota's RHT series (", nrow(found), " contracts, $",
          format(sum(found$amount), big.mark = ","), "; ", nrow(rs),
          " Rural Strong grants) and ", length(details), " new detail page(s).")
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


SD_FEDERAL_DIR <- "data/evidence/SD/federal_records/2026-09-24"
SD_FEDERAL_HOSP_FILE <- "cms_hosp_enrollments_SD.json"


#' CMS's own Hospital Enrollments for South Dakota, as archived
#'
#' Read at build time so a CCN or a form is never typed into this file by hand.
#' Swing-bed CCNs (the third character is a letter, "43Z...") are dropped: they
#' are the same hospital's swing-bed enrolment, not a second hospital.
rhtp_sd_cms_hospitals <- function() {
  path <- here::here(SD_FEDERAL_DIR, SD_FEDERAL_HOSP_FILE)
  if (!file.exists(path)) {
    stop("[SD] the archived CMS hospital enrolment file is missing: ", path,
         call. = FALSE)
  }
  j <- jsonlite::fromJSON(readr::read_file(path))
  tibble::tibble(
    org = stringr::str_squish(toupper(j[["ORGANIZATION NAME"]])),
    dba = stringr::str_squish(toupper(j[["DOING BUSINESS AS NAME"]])),
    city = stringr::str_squish(toupper(j[["CITY"]])),
    ccn = as.character(j[["CCN"]]),
    provider_type = j[["PROVIDER TYPE TEXT"]]
  ) %>%
    dplyr::filter(stringr::str_detect(.data$ccn, "^\\d{6}$"))
}


#' Exact-string CMS hospital match: ORGANIZATION NAME or DBA, SAME city
#'
#' Returns one row per awardee that matches, or none. EXACT and city-keyed by
#' construction -- South Dakota has two different "COMMUNITY MEMORIAL
#' HOSPITAL"s (Burke and Redfield) and only the city tells them apart, and a
#' stem match would type anything (§2 forbids a fuzzy hospital match).
rhtp_sd_cms_match <- function(awardee, city, cms = rhtp_sd_cms_hospitals()) {
  key <- tibble::tibble(i = seq_along(awardee),
                        a = stringr::str_squish(toupper(awardee)),
                        c = stringr::str_squish(toupper(city)))
  hits <- dplyr::bind_rows(
    key %>% dplyr::inner_join(cms, by = c(a = "org", c = "city")) %>%
      dplyr::mutate(field = "ORGANIZATION NAME"),
    key %>% dplyr::inner_join(cms %>% dplyr::filter(nzchar(.data$dba)),
                              by = c(a = "dba", c = "city")) %>%
      dplyr::mutate(field = "DOING BUSINESS AS NAME")
  ) %>%
    dplyr::distinct(.data$i, .data$ccn, .keep_all = TRUE)
  if (any(duplicated(hits$i))) {
    stop("[SD] one awardee matched more than one CMS hospital CCN in its own ",
         "city; refusing to choose.", call. = FALSE)
  }
  hits %>% dplyr::select("i", "ccn", "field", "provider_type")
}


#' Parse every search archive, and fix the row order across them
#'
#' The LATEST archive is the current register. Every contract keeps the
#' position it had in the first archive that carried it -- so the 13 rows of
#' 2026-08-28 are rows 1-13 exactly as before, and later contracts are
#' appended in contract-number order.
rhtp_sd_search_rows <- function(dir = here::here(SD_EVIDENCE_DIR)) {
  archives <- purrr::map(SD_SEARCH_ARCHIVES, function(f) {
    path <- file.path(dir, f)
    if (!file.exists(path)) {
      stop("[SD] search archive missing: ", path, ". Run --fetch first.",
           call. = FALSE)
    }
    rhtp_sd_parse_search(readr::read_file(path)) %>%
      dplyr::mutate(first_seen_archive = f)
  })
  latest <- archives[[length(archives)]]

  # A contract that was on the register and is gone, or whose amount moved,
  # is an amendment or a withdrawal. Neither is re-coded silently.
  for (k in seq_along(archives)[-length(archives)]) {
    prior <- archives[[k]]
    gone <- setdiff(prior$contract_number, latest$contract_number)
    if (length(gone)) {
      stop("[SD] contract(s) in ", SD_SEARCH_ARCHIVES[k], " are no longer on ",
           "the register: ", paste(gone, collapse = ", "), call. = FALSE)
    }
    moved <- prior %>%
      dplyr::inner_join(latest, by = "contract_number",
                        suffix = c("_prior", "_latest")) %>%
      dplyr::filter(.data$amount_prior != .data$amount_latest |
                      .data$awardee_prior != .data$awardee_latest)
    if (nrow(moved)) {
      stop("[SD] contract(s) changed amount or vendor between archives: ",
           paste(moved$contract_number, collapse = ", "),
           ". Read the register before rebuilding.", call. = FALSE)
    }
  }

  first_seen <- dplyr::bind_rows(archives) %>%
    dplyr::mutate(archive_order = match(.data$first_seen_archive,
                                        SD_SEARCH_ARCHIVES)) %>%
    dplyr::group_by(.data$contract_number) %>%
    dplyr::summarise(archive_order = min(.data$archive_order), .groups = "drop")

  latest %>%
    dplyr::select(-"first_seen_archive") %>%
    dplyr::left_join(first_seen, by = "contract_number") %>%
    dplyr::mutate(first_seen_archive = SD_SEARCH_ARCHIVES[.data$archive_order]) %>%
    dplyr::arrange(.data$archive_order, .data$contract_number) %>%
    dplyr::select(-"archive_order")
}


rhtp_sd_build <- function() {
  dir <- here::here(SD_EVIDENCE_DIR)
  found <- rhtp_sd_search_rows(dir)

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
    dplyr::left_join(details, by = "contract_number")

  if (any(is.na(joined$description) | !nzchar(joined$description))) {
    missing <- joined$contract_number[is.na(joined$description)]
    stop("[SD] no full description parsed for: ",
         paste(missing, collapse = ", "), call. = FALSE)
  }

  classified <- joined %>%
    rhtp_classify_records(state = SD_STATE, description_col = "description") %>%
    dplyr::mutate(
      is_rural_strong = stringr::str_detect(.data$description,
                                            stringr::fixed(SD_RURAL_STRONG_PATTERN))
    )

  # -- The federal record, and ONLY on an exact string in the same city ------
  cms <- rhtp_sd_cms_hospitals()
  hits <- rhtp_sd_cms_match(classified$awardee, classified$vendor_city, cms)
  classified$ccn <- NA_character_
  classified$ccn[hits$i] <- hits$ccn
  classified$recipient_type_source <- NA_character_
  classified$recipient_type_source[hits$i] <- paste0(
    "CMS Hospital Enrollments (archived ", SD_FEDERAL_DIR, "/",
    SD_FEDERAL_HOSP_FILE, "): ", hits$field, " = the register's own string, city ",
    toupper(classified$vendor_city[hits$i]), ", CCN ", hits$ccn, ", ",
    hits$provider_type, ". Machine answer on the name: ",
    classified$recipient_type[hits$i], "/",
    classified$determination_confidence[hits$i], "."
  )

  # Promote ONLY a fallback row that the federal record carries by its exact
  # string. A row the name rule already typed a hospital keeps its type and
  # gains the CCN; nothing is ever demoted here.
  promote <- hits$i[classified$classification_rule[hits$i] == "FALLBACK"]
  if (length(promote)) {
    flow <- rhtp_classify_flow(rep("HOSPITAL_OR_SYSTEM", length(promote)),
                               classified$description[promote])
    classified$recipient_type[promote] <- "HOSPITAL_OR_SYSTEM"
    classified$determination_confidence[promote] <- "MEDIUM"
    classified$flow_type[promote] <- flow$flow_type
    classified$distributed_to_hospital[promote] <- flow$distributed_to_hospital
    classified$hospital_benefiting[promote] <- flow$hospital_benefiting
    classified$flag_reason[promote] <- NA_character_
    classified$classification_rule[promote] <- "FEDERAL_RECORD"
    classified$determination_basis[promote] <- paste(
      "Recipient typed HOSPITAL_OR_SYSTEM on an ARCHIVED FEDERAL RECORD, not on",
      "its name: the register publishes no form, and CMS's Hospital Enrollments",
      "file carries this exact string in the same city (see",
      "recipient_type_source). MEDIUM, not HIGH: the match is on CMS's",
      "enrolment file, not an AHA/POS CCN reconciliation.",
      flow$flow_basis
    )
  }

  classified %>%
    dplyr::mutate(
      state = SD_STATE,
      row_no = dplyr::row_number(),
      award_pool = dplyr::if_else(.data$is_rural_strong, SD_POOL_RS, SD_POOL_ADMIN),
      round_id = dplyr::if_else(.data$is_rural_strong, "RS", NA_character_),
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
      aha_id = NA_character_,
      rural_designation = NA_character_,
      reviewer = NA_character_,
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
        .data$begin_date, ".",
        dplyr::if_else(
          .data$is_rural_strong,
          paste0(
            " This is a RURAL STRONG GRANT -- the register's own description is '",
            SD_RURAL_STRONG_PATTERN, " as a part of the federal Rural Health",
            " Transformation Program' -- one of the 28 grants ($31.5M) South",
            " Dakota announced on 2026-07-23 (KB0046839). It is INSIDE that",
            " round total and NEVER in addition to it: sd_year1_awardees.csv",
            " carries the round as one aggregate row whose round_amount",
            " ($31,500,000) already includes this contract. Tier 3, named",
            " recipient, primary source."
          ),
          paste0(
            " This is ADMINISTRATIVE RHTP spend and is NOT part of South",
            " Dakota's announced $31.5M (28 projects) or $90M (82 organisations)",
            " rounds."
          )
        )
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
      "solicitation_type", "cfda_number", "description",
      # -- appended session 64 -------------------------------------------
      "award_pool", "round_id", "first_seen_archive"
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
#' The gap is still the finding, and since session 64 it has two halves: the
#' Rural Strong round is PARTLY on the register (8 of 28 grants), and the
#' Technology and data round is not on it at all.
rhtp_sd_reconcile <- function(records = rhtp_sd_build()) {
  hosp <- records$distributed_to_hospital == "Yes"
  rs <- records$round_id %in% "RS"
  admin <- !rs
  money <- function(x) format(x, big.mark = ",", nsmall = 2, scientific = FALSE)

  tibble::tribble(
    ~measure,                                        ~value,
    "contracts extracted from the RHT series",       as.character(nrow(records)),
    "distinct vendor strings",                       as.character(dplyr::n_distinct(records$awardee)),
    "total extracted (BOTH pools; never add to sd_year1_awardees.csv round totals)", money(sum(records$amount)),
    "-- POOL 1: ADMINISTRATIVE --",                  "",
    "administrative / programme contracts",          as.character(sum(admin)),
    "administrative total",                          money(sum(records$amount[admin])),
    "what these are",                                "programme management, consulting, evaluation, workforce training, doula workforce, training platforms",
    "-- POOL 2: RURAL STRONG GRANTS (Tier 3) --",    "",
    "Rural Strong grant contracts on the register",  paste0(sum(rs), " of the ", SD_RS_ROUND_GRANTS, " announced 2026-07-23"),
    "Rural Strong total on the register",            money(sum(records$amount[rs])),
    "Rural Strong round total (KB0046839)",          money(SD_RS_ROUND_AMOUNT),
    "relationship",                                  "the register's contracts are INSIDE the round total; the round total already includes them",
    "Rural Strong grants not yet on the register",   paste0(SD_RS_ROUND_GRANTS - sum(rs), " -- NAMED NOWHERE; their amount is stated by no source and is NOT computed here (§6.2)"),
    "-- NOT ON THE REGISTER --",                     "",
    "Technology/data round announced 2026-08-19",    "$90,000,000 to 82 rural healthcare organizations -- no contract on open.sd.gov",
    "RHTP contracts OUTSIDE the RHT series (not extracted)", paste0(nrow(SD_OUTSIDE_SERIES), " -- ", paste0(SD_OUTSIDE_SERIES$contract_number, " ", SD_OUTSIDE_SERIES$awardee, " $", format(SD_OUTSIDE_SERIES$amount, big.mark = ","), collapse = "; ")),
    "CMS Year 1 award for South Dakota",             money(SD_CMS_YEAR1_AWARD),
    "-- CODING --",                                  "",
    "rows distributed_to_hospital = Yes",            as.character(sum(hosp)),
    "dollars distributed_to_hospital = Yes",         money(sum(records$amount[hosp])),
    "distinct hospitals among them",                 as.character(dplyr::n_distinct(paste(records$awardee[hosp], records$vendor_city[hosp])))
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

  # ROW ORDER. The contracts of the first archive keep rows 1..n exactly.
  first <- rhtp_sd_parse_search(readr::read_file(
    here::here(SD_EVIDENCE_DIR, SD_SEARCH_ARCHIVES[1])))
  n1 <- nrow(first)
  if (!identical(records$contract_number[seq_len(n1)],
                 sort(first$contract_number))) {
    stop("[SD] the first ", n1, " rows are no longer the contracts of ",
         SD_SEARCH_ARCHIVES[1], " in their original order. New contracts are ",
         "APPENDED; existing rows keep their position.", call. = FALSE)
  }

  rs <- records$round_id %in% "RS"
  admin <- !rs

  # A RURAL STRONG ROW IS DEFINED BY THE REGISTER'S OWN WORDS, AND TWO
  # INDEPENDENT READS OF THE REGISTER MUST AGREE ON WHICH ROWS THOSE ARE: the
  # full description on each archived detail page, and the register's own
  # 'Rural Strong' description search.
  rs_by_detail <- stringr::str_detect(records$description,
                                      stringr::fixed(SD_RURAL_STRONG_PATTERN))
  if (!identical(rs, rs_by_detail)) {
    stop("[SD] round_id 'RS' and the detail pages disagree about which rows ",
         "are Rural Strong grants.", call. = FALSE)
  }
  rs_search <- rhtp_sd_parse_search(readr::read_file(here::here(
    SD_EVIDENCE_DIR,
    SD_DESC_SEARCHES$file[SD_DESC_SEARCHES$probe_key == "rural_strong"])))
  if (!setequal(records$contract_number[rs], rs_search$contract_number)) {
    stop("[SD] the register's own 'Rural Strong' search returns ",
         paste(sort(rs_search$contract_number), collapse = ", "),
         " but this file marks ",
         paste(sort(records$contract_number[rs]), collapse = ", "),
         ". Two reads of one register disagree; read both before rebuilding.",
         call. = FALSE)
  }
  if (any(records$award_pool[rs] != SD_POOL_RS) ||
      any(records$award_pool[admin] != SD_POOL_ADMIN)) {
    stop("[SD] award_pool does not match round_id.", call. = FALSE)
  }

  # THE RURAL STRONG CONTRACTS ARE INSIDE THE $31.5M ROUND, AND CANNOT EXCEED
  # IT (§6.2). If they do, either more than one round is being carried under
  # one label or the round was re-stated, and the file must be re-read.
  if (sum(rs) > SD_RS_ROUND_GRANTS || sum(records$amount[rs]) > SD_RS_ROUND_AMOUNT) {
    stop("[SD] ", sum(rs), " Rural Strong contracts worth ",
         format(sum(records$amount[rs]), big.mark = ","),
         " exceed the round South Dakota announced (", SD_RS_ROUND_GRANTS,
         " grants, $31.5M). Re-read the register and the release.", call. = FALSE)
  }

  # THE ASSERTION THAT KEEPS THE CLAIM HONEST, re-based in session 64 rather
  # than deleted. The ADMINISTRATIVE pool is small, and if it ever grows to
  # anything like an award round it is no longer administrative spend and the
  # file's framing must be rewritten. And the series as a whole cannot exceed
  # administration plus the whole Rural Strong round without something else --
  # most likely the $90M Technology and data round -- having posted into it.
  if (sum(records$amount[admin]) > 20e6) {
    stop("[SD] the RHT series' non-Rural-Strong contracts now total ",
         format(sum(records$amount[admin]), big.mark = ","),
         ", which is far beyond the administrative spend this file describes. ",
         "The Technology and data round ($90M) may have posted. Re-read the ",
         "register and rewrite this file's framing rather than letting it ",
         "report a figure it calls administrative.", call. = FALSE)
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

  # A FEDERAL-RECORD TYPING MUST CARRY ITS CCN AND SAY WHERE IT CAME FROM, and
  # nothing reaches HIGH on it.
  fed <- records$classification_rule %in% "FEDERAL_RECORD"
  if (any(fed & (is.na(records$ccn) | !grepl("CMS Hospital Enrollments",
                                               records$recipient_type_source) |
                   records$determination_confidence == "HIGH"))) {
    stop("[SD] a FEDERAL_RECORD row lacks its CCN or its source, or claims HIGH.",
         call. = FALSE)
  }

  # Every row must say in its own basis which pool it is and how it relates to
  # the announced rounds -- the sentence that stops a row being mis-summed once
  # it is separated from this file.
  if (!all(stringr::str_detect(records$determination_basis[admin], "NOT part of"))) {
    stop("[SD] every administrative row's determination_basis must state that ",
         "it is not part of the announced rounds.", call. = FALSE)
  }
  if (!all(stringr::str_detect(records$determination_basis[rs],
                               "INSIDE that round total and NEVER in addition"))) {
    stop("[SD] every Rural Strong row's determination_basis must state that it ",
         "is inside the $31.5M round total, never on top of it.", call. = FALSE)
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
  add("Announced rounds", SD_ANNOUNCED_ROUNDS)
  add("Outside the RHT series", SD_OUTSIDE_SERIES)
  openxlsx::saveWorkbook(wb, here::here(SD_XLSX), overwrite = TRUE)

  message("  wrote ", SD_CSV, " and ", SD_XLSX, " (", nrow(records), " rows)")
  invisible(records)
}


# -- CLI ---------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--probe" %in% args) {
    print(rhtp_probe_run("SD", rhtp_sd_probe()), n = Inf)
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
