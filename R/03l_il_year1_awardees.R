# 03l_il_year1_awardees.R ----------------------------------------------------
# Illinois Year 1 -> data/reference/il_year1_awardees.csv (+ a render).
#
# WHY ILLINOIS, AND WHY NOW. Illinois is the state that proved the method had a
# hole in it. Every hunt this project has run started from the stage 00 CMS
# trigger list; CMS never issued a press release for Illinois; so no session
# ever looked at it. Meanwhile Illinois executed three grant agreements with
# the Illinois Critical Access Hospital Network on 2026-07-31 worth
# $50,008,264 -- a quarter of its $193,418,216.21 FY2026 allotment, and the
# largest single pass-through award this project has recorded in any state.
# R/03k is the survey that stops that recurring; this file is the state.
#
# WHAT ILLINOIS HAS PUBLISHED, AND WHAT IT HAS NOT. Searched this session:
#
#   hfs.illinois.gov/info/fedresctr/ruralhealthtp.html  -- the RHTP programme
#     page. NAMES NO RECIPIENT. Links a project overview, a project narrative,
#     a planning-grant methodology and a legislative update.
#   rhtprogup03092026.pdf (2026-03-09, 29pp) -- HFS's own programme update. It
#     names INTENDED sub-awardees per initiative (ICAHN, IPHCA, CBHA, Carle
#     Health, OSF Healthcare, SIHF Healthcare, the Office of Medicaid
#     Innovation, ICCB, the University of Illinois System) against PRELIMINARY
#     amounts, and stamps every page "Contents are for discussion purposes only
#     and are considered incomplete without oral comment." That is a PLAN
#     (§0.3, §9.2): intent to award is not an award, and none of those
#     organisations is coded here.
#   il.amplifund.com -- three open RHTP solicitations. The Hospital
#     Transformation one budgets $28,191,393 across 97 eligible hospitals,
#     distributed EQUALLY, floor $290,000. Open, unawarded, NAMES NOBODY:
#     Tier 2 (§0.2), and §0.3's textbook case.
#
# So Illinois has published NO recipient-level award list, and the ICAHN award
# is not in one. It is in ICAHN's own release -- and that is admissible under
# §7, which admits "a state agency OR DESIGNATED PASS-THROUGH ADMINISTRATOR
# document" that names both recipient and award. ICAHN is that administrator,
# named as such by HFS's own programme update and quoted in the release by
# HFS's own RHTP programme director. This is the first time this project has
# taken a §7 source that is not a state agency, and the reason it qualifies is
# recorded on the row rather than left to a reader to reconstruct.
#
# THE ROW IS ONE ROW, AND ITS AMOUNT IS REAL. Unlike South Dakota's two
# announced rounds -- where `amount` is deliberately EMPTY because $121.5M was
# a round total spread over 110 recipients nobody has named -- $50,008,264 is
# one organisation's own executed award. ICAHN received it. `amount` is
# populated and `amount_confirmed = Yes`.
#
# AND IT MUST NEVER BE ADDED TO FLORIDA'S. This is the first
# PASS_THROUGH_DESIGNATED row in the project, and it is the one shape that can
# silently inflate the headline number. Every other hospital dollar in this
# repo sits on a row whose own awardee is a named hospital. ICAHN's does not:
# the money is restricted to hospitals and the award to ICAHN has been made
# (which is what §10.2 requires for PASS_THROUGH_DESIGNATED and
# distributed_to_hospital = Yes), but NOT ONE HOSPITAL IS NAMED, and on
# ICAHN's own account not one has been CHOSEN yet -- hospitals "will apply"
# after a digital readiness assessment of the 78 eligible.
#
# So the row carries `hospital_attribution = POOL_UNNAMED_HOSPITALS`, and the
# separation is enforced in code rather than described in a note:
# rhtp_hospital_dollar_partition() in R/utils_recipient_classification.R
# returns the two figures and REFUSES to return their sum, the same device
# rhtp_ga_reconcile() uses to make Georgia's wrong total unobtainable.
#
# THREE HOSPITAL COUNTS, NOT ONE, AND THEY ARE NOT THE SAME SET. ICAHN's
# membership is 60 (56 critical access hospitals plus four other rural
# hospitals); the Technology Transformation Initiative names 78 eligible
# hospitals; HFS's separate planning-grant solicitation names 97. Nothing here
# reconciles them, because they are three different universes and the source
# says so. They are on the Reconciliation sheet as published.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only -- never |>. No setwd(); all
# paths go through here::here().
#
# CLI:
#   Rscript R/03l_il_year1_awardees.R --fetch     # LIVE: archive the sources
#   Rscript R/03l_il_year1_awardees.R --validate  # assertions only, no writes
#   Rscript R/03l_il_year1_awardees.R --build     # writes the CSV + the xlsx

suppressPackageStartupMessages({
  library(dplyr)
  library(openxlsx)
  library(readr)
  library(rvest)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

IL_CSV      <- "data/reference/il_year1_awardees.csv"
IL_XLSX     <- "IL_year1_awardees.xlsx"
IL_EVIDENCE <- "data/evidence/IL"

IL_FY2026_ALLOTMENT <- 193418216.21

# The executed award. Every figure below is quoted from ICAHN's release; the
# derived split is NOT here, it is on the Reconciliation sheet and labelled.
IL_ICAHN_AMOUNT      <- 50008264
IL_ICAHN_TECH_AMOUNT <- 31008264

# `reduce` is the §7.1 posture, per source rather than per project:
#   VERBATIM   -- archive exactly what the server served. Preferred: the
#                 digest then certifies the real document.
#   MAIN_MINUS_CREDENTIAL -- archive <main> with any node carrying a
#                 credential-shaped ATTRIBUTE removed. Required for
#                 hfs.illinois.gov, whose RHTP page embeds a store-locator
#                 <map-details api-key="pk.ey..."> -- a Mapbox token that is
#                 Illinois' to publish and not ours to redistribute, the same
#                 case as CMS's page chrome in §7.1. It sits INSIDE <main>, so
#                 unlike CMS this cannot be solved by picking a container; the
#                 offending node is removed by name and the result is asserted
#                 credential-free before writing.
IL_SOURCES <- tibble::tribble(
  ~key,          ~reduce,                 ~url,                                                                    ~role,
  "icahn_award", "VERBATIM",              "https://icahn.org/news/news-release-icahn-awarded-more-than-50-million-by-the-state-of-illinois-to-advance-rural-healthcare-transformation-across-illinois/", "THE AWARD SOURCE (§7 designated pass-through administrator)",
  "hfs_rhtp",    "MAIN_MINUS_CREDENTIAL", "https://hfs.illinois.gov/info/fedresctr/ruralhealthtp.html",             "THE NEGATIVE: the state programme page, which names no recipient",
  "hfs_update",  "VERBATIM",              "https://hfs.illinois.gov/content/dam/soi/en/web/hfs/info/fedresctr/rhtprogup03092026.pdf", "THE PLAN (§0.3): intended sub-awardees, preliminary amounts, 'discussion purposes only'"
)

# The credential shapes this repository has actually met: Mapbox public and
# secret tokens, and Google API keys. Matched by SHAPE, never by literal
# value, so a rotated token is caught too (session 14).
IL_CREDENTIAL_RE <- "[ps]k\\.ey[A-Za-z0-9._-]{10,}|AIza[A-Za-z0-9_-]{20,}"

# §9.5 conduct: a descriptive agent naming the organisation and a contact URL.
IL_USER_AGENT <- paste0(
  "AHA-RHTP-Tracker/1.0 (American Hospital Association data and policy ",
  "research; +https://www.aha.org)"
)


# -- Fetch -------------------------------------------------------------------

#' Archive the Illinois sources verbatim, with a SHA-256 manifest
#'
#' Verbatim, not reduced. The §7.1 reduction posture exists because CMS's page
#' chrome carries a third-party Mapbox token that is CMS's to publish and not
#' ours to redistribute. Neither Illinois host carries a secret of that shape
#' -- checked before writing, below -- so the whole document is archived and
#' its digest is the digest of what the server actually served. That is the
#' stronger provenance and is preferred wherever it is available.
#'
#' writeBin() of the exact response bytes, never writeLines(): session 12 found
#' writeLines() appends a trailing newline, so the archived file was one byte
#' longer than the digest recorded beside it and a reader verifying the archive
#' would get a mismatch.
rhtp_il_fetch <- function() {
  dir <- here::here(IL_EVIDENCE)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)

  fetched <- purrr::pmap_dfr(IL_SOURCES, function(key, reduce, url, role) {
    message("[IL] fetching ", key)

    resp <- httr::GET(
      url,
      httr::user_agent(IL_USER_AGENT),
      httr::timeout(90)
    )

    if (httr::status_code(resp) != 200) {
      stop("[IL] ", key, " returned HTTP ", httr::status_code(resp),
           call. = FALSE)
    }

    served      <- httr::content(resp, as = "raw")
    served_sha  <- digest::digest(served, algo = "sha256", serialize = FALSE)
    is_pdf      <- stringr::str_detect(url, "\\.pdf$")

    if (identical(reduce, "VERBATIM")) {
      body <- served

      # A VERBATIM archive must be credential-free, or the reduction was the
      # wrong call for this source. Fail rather than commit the token.
      if (!is_pdf) {
        text <- rawToChar(served)
        Encoding(text) <- "UTF-8"
        if (isTRUE(stringr::str_detect(text, IL_CREDENTIAL_RE))) {
          stop("[IL] ", key, " is marked VERBATIM but carries a ",
               "credential-shaped string. Set reduce = ",
               "'MAIN_MINUS_CREDENTIAL' for it; do not archive it as is.",
               call. = FALSE)
        }
      }
    } else {
      text <- rawToChar(served)
      Encoding(text) <- "UTF-8"
      doc  <- rvest::read_html(text)
      main <- rvest::html_element(doc, "main")

      if (inherits(main, "xml_missing")) {
        stop("[IL] ", key, " has no <main> to reduce to.", call. = FALSE)
      }

      # Drop every node carrying a credential in an ATTRIBUTE (Illinois'
      # <map-details api-key>), plus scripts and styles, which carry no
      # content this archive is for.
      xml2::xml_remove(xml2::xml_find_all(main, ".//script|.//style|.//noscript"))
      for (node in xml2::xml_find_all(main, ".//*")) {
        attrs <- xml2::xml_attrs(node)
        if (length(attrs) > 0 &&
            any(stringr::str_detect(attrs, IL_CREDENTIAL_RE))) {
          xml2::xml_remove(node)
        }
      }

      reduced <- as.character(main)

      # Assert the reduction actually worked before anything is written.
      if (isTRUE(stringr::str_detect(reduced, IL_CREDENTIAL_RE))) {
        stop("[IL] ", key, " still carries a credential after reduction; ",
             "not archiving.", call. = FALSE)
      }

      body <- charToRaw(enc2utf8(reduced))
    }

    ext  <- if (is_pdf) ".pdf" else ".html"
    file <- file.path(dir, paste0(Sys.Date(), "_", key, ext))

    con <- base::file(file, "wb")
    writeBin(body, con)
    close(con)

    # Re-hash the file ON DISK, not the response in memory. Hashing the
    # response would certify a byte string that may not be what landed.
    #
    # Computed BEFORE the tibble, deliberately. Inside tibble::tibble() a
    # `sha256 = digest(file = file)` would resolve `file` to the `file =
    # basename(file)` column defined one line above -- a basename, not a path
    # -- and digest would fail on a file that does exist. Same data-masking
    # trap as the pull_date defect this session fixed in R/02_normalize.R,
    # two files apart.
    file_sha256 <- digest::digest(file = file, algo = "sha256")

    tibble::tibble(
      key = key, url = url, role = role, reduce = reduce,
      file = basename(file),
      bytes = length(body),
      sha256 = file_sha256,
      served_sha256 = served_sha,
      served_bytes = length(served),
      fetched_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
    )
  })

  # The manifest must NOT list itself: its own digest is stale the instant it
  # is written, and a verification pass that skips missing files cannot tell a
  # wrong entry from an absent one (session 15).
  manifest <- file.path(dir, "MANIFEST.txt")
  writeLines(
    c(
      "Illinois RHTP evidence archive",
      paste("Fetched:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
      paste("User agent:", IL_USER_AGENT),
      "",
      "sha256        = the digest of the file archived here.",
      "served_sha256 = the digest of the FULL page as served, so provenance",
      "                closes even where the archive is a reduction. For a",
      "                VERBATIM source the two are identical.",
      "",
      "hfs_rhtp is reduced to <main> minus a <map-details api-key=...> store-",
      "locator widget: that Mapbox token is Illinois' to publish and not ours",
      "to redistribute (the §7.1 posture). Everything else is verbatim.",
      "MANIFEST.txt is excluded from its own listing.",
      "",
      apply(fetched, 1, function(r) {
        paste0(r[["file"]], "\n",
               "  url          : ", r[["url"]], "\n",
               "  role         : ", r[["role"]], "\n",
               "  archived     : ", r[["reduce"]], "\n",
               "  bytes        : ", r[["bytes"]], "\n",
               "  sha256       : ", r[["sha256"]], "\n",
               "  served_bytes : ", r[["served_bytes"]], "\n",
               "  served_sha256: ", r[["served_sha256"]], "\n",
               "  fetched      : ", r[["fetched_at"]])
      })
    ),
    manifest
  )

  message("[IL] archived ", nrow(fetched), " sources -> ", IL_EVIDENCE)
  invisible(fetched)
}


# -- The record --------------------------------------------------------------

#' Illinois Year 1 award actions
#'
#' One row. Not because Illinois made one award -- HFS's own plan names eight
#' further intended sub-awardees -- but because exactly one Illinois award is
#' EXECUTED AND PUBLISHED, and §0.3 is the rule that keeps the other eight out
#' of the file until a source says they happened.
rhtp_il_records <- function() {
  tibble::tibble(
    state = "IL",
    row_no = 1L,
    awardee = "Illinois Critical Access Hospital Network (ICAHN)",
    amount = IL_ICAHN_AMOUNT,
    recipient_type = "NONPROFIT_CBO",
    distributed_to_hospital = "Yes",
    note = paste0(
      "Three grant agreements with Illinois HFS totalling $50,008,264, ",
      "signed 2026-07-31, effective 2026-08-01 through 2027-06-30. ICAHN is ",
      "the designated pass-through administrator and will administer the ",
      "funds to Critical Access Hospitals and other eligible non-urban ",
      "Illinois hospitals in federally designated rural ZIP codes. ",
      "NO INDIVIDUAL HOSPITAL IS NAMED and, on ICAHN's own account, none has ",
      "yet been selected: hospitals will APPLY following a digital readiness ",
      "assessment of the 78 eligible. See hospital_attribution."
    ),
    recipient_confirmed = "Yes",
    amount_confirmed = "Yes",
    fiscal_year = "FY2026",
    source_document_title = paste0(
      "News Release: ICAHN Awarded More Than $50 Million by the State of ",
      "Illinois to Advance Rural Healthcare Transformation Across Illinois"
    ),
    state_source_url = IL_SOURCES$url[IL_SOURCES$key == "icahn_award"],
    validation_source_type = "AGENCY_PRESS_RELEASE",
    extraction_method = "MODEL_ASSISTED",
    validator = "AI-assisted - CONFIRM",
    ccn = NA_character_,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,

    # -- Illinois' own block --------------------------------------------------
    recipient_type_source = paste0(
      "Not stated by the source. ICAHN is a membership network of 60 rural ",
      "hospitals; the release does not state its corporate form, so §8's ",
      "standing answer for a named entity of undetermined form applies."
    ),
    determination_confidence = "MEDIUM",
    flag_reason = paste(
      "RECIPIENT_NAMES_NOT_CAPTURED",
      "SUBAWARD_PROCESS_NOT_YET_RUN",
      "RECIPIENT_TYPE_INFERRED",
      sep = ";"
    ),
    flow_type = "PASS_THROUGH_DESIGNATED",
    intermediary_name = "Illinois Critical Access Hospital Network (ICAHN)",
    hospital_attribution = "POOL_UNNAMED_HOSPITALS",
    hospital_recipient_count = NA_integer_,
    hospital_benefiting = "Yes",
    determination_basis = paste0(
      "§10.2 PASS_THROUGH_DESIGNATED, both clauses met on the source's own ",
      "words: the award TO THE INTERMEDIARY HAS BEEN MADE (three agreements ",
      "executed 2026-07-31, effective 2026-08-01) and ELIGIBILITY IS ",
      "RESTRICTED TO HOSPITALS (\"Critical Access Hospitals and other ",
      "eligible non-urban Illinois hospitals located in federally designated ",
      "rural ZIP codes\") -- hospitals ONLY, not hospitals among other ",
      "eligible entities, which is what would make it ",
      "PASS_THROUGH_UNRESOLVED. So distributed_to_hospital = Yes. ",
      "BUT NO HOSPITAL IS NAMED AND NONE IS YET CHOSEN: the release says ",
      "hospitals will apply after a digital readiness assessment of the 78 ",
      "eligible, and that further detail \"will be shared as it becomes ",
      "available\". These dollars are therefore attributable to a POOL and ",
      "to no hospital, they are NOT comparable to a named-hospital figure ",
      "such as Georgia's $60,000,000 or Florida's rows, and they must never ",
      "be added to one (§0.3). hospital_attribution carries that and ",
      "rhtp_hospital_dollar_partition() enforces it. ",
      "SOURCE ADMISSIBILITY (§7): ICAHN is not a state agency, but §7 admits ",
      "a designated pass-through administrator's document. HFS's own ",
      "2026-03-09 programme update names ICAHN the sub-awardee for these ",
      "three initiatives, and HFS's RHTP programme director is quoted by ",
      "name in the release, so the administrator designation is corroborated ",
      "by the state itself and not asserted by the recipient alone."
    ),
    source_archive_path = "data/evidence/IL/2026-08-28_icahn_award.html",
    recipient_names_source_url = NA_character_,
    amount_basis = paste0(
      "Stated exactly by the source: \"three grant agreements totalling ",
      "$50,008,264\". Not rounded, not derived, not preliminary."
    ),
    amount_precision = "EXACT",
    disbursement_status = "EXECUTED",
    classification_rule = "IL_ICAHN_PASS_THROUGH",
    agreement_count = 3L,
    agreement_signed_date = "2026-07-31",
    period_start = "2026-08-01",
    period_end = "2027-06-30",
    icahn_member_hospitals = 60L,
    technology_eligible_hospitals = 78L
  )
}


# -- Reconciliation ----------------------------------------------------------

#' What Illinois has published, against what it was allotted
#'
#' Reports gaps; closes none of them. The residual is not "unawarded money" --
#' it is money whose awards Illinois has not published, which is a different
#' claim and the only one the evidence supports.
rhtp_il_reconcile <- function(records = NULL) {
  if (is.null(records)) records <- rhtp_il_records()

  tibble::tribble(
    ~item, ~value, ~basis,
    "CMS FY2026 allotment", IL_FY2026_ALLOTMENT,
    "cms_fy2026_allotments.csv (§7.1). ICAHN's release restates it as $193,418,216.21.",

    "Published, executed subawards (this file)", sum(records$amount),
    "One award action: ICAHN, three agreements.",

    "Share of the allotment published", sum(records$amount) / IL_FY2026_ALLOTMENT,
    "NOT a disbursement rate. It is the share of Illinois' allotment for which an executed award has been PUBLISHED anywhere reachable.",

    "Named-hospital dollars in this file", 0,
    "ZERO. Not one Illinois hospital is named in any published Illinois source. The $50,008,264 is POOL_UNNAMED_HOSPITALS.",

    "Unpublished remainder", IL_FY2026_ALLOTMENT - sum(records$amount),
    "Money whose awards Illinois has NOT published. NOT evidence it is unawarded: HFS's plan names eight further intended sub-awardees."
  )
}


#' The three-agreement split -- DERIVED, and labelled as such on the sheet
#'
#' ICAHN's release states two figures: the $50,008,264 total and $31,008,264
#' for technology. It does not state the other two. HFS's 2026-03-09 plan gives
#' Year 1 preliminary figures of $14M for disease prevention and $5M for
#' workforce, and $19,000,000 is exactly what the release's two stated figures
#' leave over.
#'
#' That closure is worth recording and is NOT worth publishing as fact. It
#' combines a PLAN with an award release, and §0.3 is precisely the rule
#' against letting a planned figure become an awarded one because the
#' arithmetic happens to work. The row total stays one row at $50,008,264.
rhtp_il_agreement_split <- function() {
  tibble::tribble(
    ~initiative, ~amount, ~status, ~basis,
    "Technology Transformation Initiative (IC3)", IL_ICAHN_TECH_AMOUNT,
    "STATED", "ICAHN release: \"The largest portion of the grant, $31,008,264, is dedicated to technology.\"",

    "Hospital Disease Prevention Grant Program", 14000000,
    "DERIVED - DO NOT PUBLISH", "HFS 2026-03-09 plan, Year 1 PRELIMINARY. Not restated in the award release.",

    "Workforce (Incentives and Training for Clinical Professionals)", 5000000,
    "DERIVED - DO NOT PUBLISH", "HFS 2026-03-09 plan, Year 1 PRELIMINARY. Not restated in the award release.",

    "TOTAL", IL_ICAHN_AMOUNT,
    "STATED", "ICAHN release: three agreements totalling $50,008,264. The two derived lines sum to the $19,000,000 the stated figures leave over -- an unarranged closure, and still not a published fact."
  )
}


# -- Assertions --------------------------------------------------------------

rhtp_il_assert <- function(records = NULL) {
  if (is.null(records)) records <- rhtp_il_records()

  stopifnot(nrow(records) == 1L)
  stopifnot(records$state == "IL")
  stopifnot(records$amount == IL_ICAHN_AMOUNT)

  # -- §8 controlled vocabularies -------------------------------------------
  for (col in c("recipient_type", "distributed_to_hospital",
                "recipient_confirmed", "amount_confirmed", "flow_type",
                "hospital_benefiting", "determination_confidence",
                "extraction_method", "validator", "hospital_attribution")) {
    allowed <- rhtp_vocabulary(col)
    bad <- setdiff(stats::na.omit(records[[col]]), allowed)
    if (length(bad) > 0) {
      stop("[IL] value(s) outside §8 for ", col, ": ",
           paste(bad, collapse = ", "), call. = FALSE)
    }
  }

  flags <- unlist(stringr::str_split(records$flag_reason, ";"))
  flags <- stringr::str_trim(flags[nzchar(flags)])
  bad_flags <- setdiff(flags, rhtp_vocabulary("flag_reason"))
  if (length(bad_flags) > 0) {
    stop("[IL] flag_reason outside §8: ", paste(bad_flags, collapse = ", "),
         call. = FALSE)
  }

  stopifnot(records$validation_source_type %in%
              rhtp_vocabulary("source_doc_type"))

  # -- THE SEPARABILITY INVARIANT -------------------------------------------
  # The whole point of the file. A PASS_THROUGH_DESIGNATED row that reaches
  # hospitals must name an intermediary and must declare itself a pool, or the
  # $50,008,264 becomes indistinguishable from Florida's named-hospital rows
  # the moment somebody filters on distributed_to_hospital.
  pt <- records %>%
    dplyr::filter(flow_type == "PASS_THROUGH_DESIGNATED")

  if (nrow(pt) > 0) {
    stopifnot(all(!is.na(pt$intermediary_name) & nzchar(pt$intermediary_name)))
    stopifnot(all(pt$hospital_attribution == "POOL_UNNAMED_HOSPITALS"))
    # No hospital is named, so no hospital COUNT may be asserted either --
    # 60, 78 and 97 are three different Illinois universes and none of them is
    # a list of recipients.
    stopifnot(all(is.na(pt$hospital_recipient_count)))
    stopifnot(all(is.na(pt$recipient_names_source_url)))
    stopifnot(all(is.na(pt$ccn)))
  }

  # Not one row in this file may claim a named hospital.
  stopifnot(!any(records$hospital_attribution == "NAMED_HOSPITAL"))

  # -- §0.4/§0.5: the cited archive must be on disk --------------------------
  for (path in stats::na.omit(records$source_archive_path)) {
    if (!file.exists(here::here(path))) {
      stop("[IL] source_archive_path does not exist: ", path,
           "\n  Run: Rscript R/03l_il_year1_awardees.R --fetch", call. = FALSE)
    }
  }

  # -- The allotment ceiling (§6.2) -----------------------------------------
  if (sum(records$amount) > IL_FY2026_ALLOTMENT) {
    stop("[IL] published awards exceed the CMS FY2026 allotment.",
         call. = FALSE)
  }

  # -- The tripwire ---------------------------------------------------------
  # Illinois' hospital-level recipients are unnamed TODAY. The day HFS or
  # ICAHN publishes the roster, this file is wrong and must be rebuilt rather
  # than quietly left standing -- the failure mode session 13 built the South
  # Dakota tripwire for. A named roster would populate these columns; that
  # they are empty is what makes the pool coding correct, so the assertion
  # above IS the tripwire and this states why in the one place a reader looks.
  invisible(TRUE)
}


# -- Write -------------------------------------------------------------------

rhtp_il_write_csv <- function() {
  records <- rhtp_il_records()
  rhtp_il_assert(records)
  readr::write_csv(records, here::here(IL_CSV), na = "")
  message("[IL] wrote ", nrow(records), " award action -> ", IL_CSV)
  invisible(records)
}


rhtp_il_write <- function() {
  records <- rhtp_il_write_csv()

  wb  <- openxlsx::createWorkbook()
  hdr <- openxlsx::createStyle(textDecoration = "bold")
  money <- openxlsx::createStyle(numFmt = "#,##0")
  wrap  <- openxlsx::createStyle(wrapText = TRUE, valign = "top")

  add <- function(name, df, money_cols = character(), widths = "auto") {
    openxlsx::addWorksheet(wb, name)
    openxlsx::writeData(wb, name, df, headerStyle = hdr)
    for (mc in intersect(money_cols, names(df))) {
      openxlsx::addStyle(wb, name, money, rows = 2:(nrow(df) + 1),
                         cols = which(names(df) == mc), gridExpand = TRUE)
    }
    openxlsx::freezePane(wb, name, firstActiveRow = 2)
    openxlsx::setColWidths(wb, name, cols = seq_along(df), widths = widths)
  }

  # SHEET 1 IS THE WARNING, exactly as South Dakota's is. Anyone who opens
  # this workbook and reads nothing else must still not add $50,008,264 to a
  # named-hospital total.
  readme <- tibble::tribble(
    ~field, ~value,
    "State", "Illinois",
    "CMS FY2026 allotment", "$193,418,216.21",
    "Award actions in this file", "1",
    "Total published", "$50,008,264",
    "NAMED HOSPITAL DOLLARS", "$0",
    "READ THIS FIRST",
    paste0("The $50,008,264 reached the Illinois Critical Access Hospital ",
           "Network, NOT a hospital. It is coded distributed_to_hospital = ",
           "Yes because §10.2's PASS_THROUGH_DESIGNATED test is met -- the ",
           "award to ICAHN is executed and eligibility is restricted to rural ",
           "hospitals only. But NO HOSPITAL IS NAMED and none has yet been ",
           "chosen: ICAHN's release says hospitals WILL APPLY after a digital ",
           "readiness assessment. These dollars are attributable to a pool ",
           "and to no hospital. DO NOT ADD THEM to Georgia's $60,000,000 or ",
           "to Florida's rows -- those are named hospitals and this is not. ",
           "The column that separates them is hospital_attribution."),
    "Has Illinois published an award list?",
    paste0("NO. hfs.illinois.gov's RHTP page names no recipient; its ",
           "2026-03-09 programme update names INTENDED sub-awardees against ",
           "PRELIMINARY amounts and is stamped 'for discussion purposes ",
           "only'; the three il.amplifund.com solicitations are open and name ",
           "nobody. The ICAHN award is published only by ICAHN."),
    "Why is a recipient's own release admissible?",
    paste0("§7 admits a DESIGNATED PASS-THROUGH ADMINISTRATOR's document. HFS ",
           "designated ICAHN in its own programme update and HFS's RHTP ",
           "programme director is quoted by name in the release."),
    "Three hospital counts, three universes",
    paste0("ICAHN membership 60 (56 CAHs + 4 other rural); Technology ",
           "Transformation eligible 78; HFS planning-grant eligible 97. Not ",
           "reconciled here -- they are different sets and the sources say so."),
    "Next", paste0("The 97-hospital, $28,191,393 planning-grant solicitation ",
                   "on il.amplifund.com is how Illinois hospitals get NAMED. ",
                   "Re-check it; an award list there is a real extraction.")
  )

  add("READ ME FIRST", readme, widths = c(34, 105))
  openxlsx::addStyle(wb, "READ ME FIRST", wrap, rows = 2:(nrow(readme) + 1),
                     cols = 2, gridExpand = TRUE)

  add("Award actions (1)", records, "amount")
  add("Reconciliation", rhtp_il_reconcile(records), "value", widths = c(42, 20, 100))
  add("Three agreements (DERIVED)", rhtp_il_agreement_split(), "amount",
      widths = c(56, 16, 24, 100))

  openxlsx::saveWorkbook(wb, here::here(IL_XLSX), overwrite = TRUE)
  message("[IL]   ", IL_XLSX)
  invisible(records)
}


# --- CLI --------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) {
    rhtp_il_fetch()
  } else if ("--build" %in% args) {
    rhtp_il_write()
  } else if ("--validate" %in% args) {
    recs <- rhtp_il_records()
    rhtp_il_assert(recs)
    message("[IL] ", nrow(recs), " award action; all assertions pass.")
    print(as.data.frame(rhtp_il_reconcile(recs)))
  } else {
    message("Usage: Rscript R/03l_il_year1_awardees.R [--fetch | --validate | --build]")
  }
}
