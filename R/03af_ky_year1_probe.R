#!/usr/bin/env Rscript
# 03af_ky_year1_probe.R -------------------------------------------------------
#
# KENTUCKY -- A NEGATIVE, AND THE FIRST ONE WHOSE OWN AWARD-NOTIFICATION DATES
# HAVE PASSED WITH THE STATE NAMING BOTH THE DATE AND THE FORM.
#
# Kentucky holds $212,905,591 (§7.1) and was one of TWELVE states carrying NO
# RCJ Tier 3 signal at all -- eleven of them `NOT_EXTRACTED` with no CMS press
# release either. Session 36 named that group as the next phase, on Florida's
# precedent: Florida is invisible to both discovery layers and had published a
# complete Year 1 roster the whole time. Kentucky is not Florida. It has
# published NO recipient-level award list.
#
# WHAT IT HAS PUBLISHED is `ruralhealthplan.ky.gov` -- a dedicated RHTP domain,
# which no other state in this repository has -- carrying NINE Requests for
# Application under five initiative brands (Crisis to Care, Rapid Response to
# Recovery, Rooted in Health, Community Health Worker, Rural Community Hubs).
# Not one names a recipient. The words "awarded", "awardee", "recipients",
# "selected" and "Notice of Intent" occur ZERO times each on that page.
#
# AND THE STATE PUBLISHES THE DATE AND THE FORM, WHICH IS WHAT MAKES THE
# SILENCE MEASURABLE (Louisiana's control, sharpened). Each RFA carries a
# "IV. Timeline" block naming the step by name:
#
#   CMHC Support  : "July 10, 2026: Notification of Award to Grantees"
#   CHW Certificate: "August 26, 2026 Anticipated Notification of Award to
#                     Recipients"
#
# BOTH HAVE PASSED. Connecticut was the first negative here whose award date
# had gone by (one solicitation); Louisiana had seven windows; Kentucky names
# the recipients-notification step itself, twice, and neither has produced a
# roster. `ky_assert_award_dates_passed()` re-derives that against Sys.Date()
# every run, so it is a live finding and not a sentence typed once.
#
# §6.2 PASSES IN ITS STRONGEST FORM: KENTUCKY PUBLISHES CMS'S OWN NOTICE OF
# AWARD -- the FOURTH state after Nevada, California and Connecticut. Award#
# RHT332079, FAIN RHT4158, Assistance Listing 93.798, recipient "Kentucky
# Cabinet for Health Services", $212,905,590.56, budget period 12/29/2025 -
# 10/30/2026.
#
# AND IT IS THE FIRST PUBLISHED STATE NOA THAT IS NOT A REVISION, WHICH
# CORROBORATES SESSION 36 DIRECTLY. Nevada's, California's and Connecticut's
# all carry Award Action Type "Revision (Budget)" and a Federal Award Date
# LATER than the budget period start -- +52, +92 and +206 days -- which is why
# session 36 pinned the §6.2 date test to the BUDGET PERIOD and not to the
# "Federal Award Date" field. Kentucky's carries Award Action Type "New" and
# Federal Award Date 12/29/2025, equal to its budget period start and to the
# committed anchor. The two agree exactly when there has been no revision,
# which is the proposition session 36 argued from three revised documents and
# could not observe directly. `ky_assert_noa_is_original()` pins it.
#
# THE §0.2 TRAP, AND KENTUCKY CARRIES IT NINE TIMES OVER. That Notice of Award
# is attached to EVERY RFA, as "Attachment B" or "Attachment C". So each of the
# nine solicitations ships a document whose only headline figure is the WHOLE
# STATE ALLOTMENT -- and the CHW RFA's own stated maximum award is $800,000.
# An extractor reading "the CMS Notice of Award attached to the CHW RFA" as
# that RFA's pool would publish $212,905,590.56 as a Community Health Worker
# pool: the allotment, 266 times the actual ceiling, attributed to one of nine
# solicitations. Nothing in the attachment's grammar says otherwise -- it is a
# real CMS Notice of Award for a real Kentucky RHTP programme.
#
# That is exactly the failure §0.2's tier-indistinguishability rule was written
# for this session, so `ky_assert_noa_is_not_a_pool()` drives the shared
# `rhtp_assert_footer_not_allotment()` against it in BOTH directions.
#
# AND IT POISONS THE OBVIOUS SEARCH. "Notice of Award" occurs TEN times across
# Kentucky's two funding pages and NOT ONE is a state award to a recipient --
# every one is CMS's award to Kentucky, shipped as an attachment. A hunt keyed
# on that phrase returns ten hits in a state that has awarded nobody.
#
# THE DESIGNATED PASS-THROUGH NAMES NOBODY EITHER. The Foundation for a Healthy
# Kentucky is "a primary partner" for the Rural Community Hubs initiative and
# publishes its own RHTP page; §7 admits a designated pass-through
# administrator's document (Illinois/ICAHN), so it was read. It describes the
# Hub Lead ROLE and names no Hub Lead: "awarded", "awardee", "selected" and
# "recipient" are ZERO on it.
#
# THE DIGEST FINDING, AND IT IS THE EIGHTH MECHANISM IN THIS PROJECT.
# `ruralhealthplan.ky.gov` is SharePoint, and every render re-rolls TWO things
# at once: a fresh GUID in each `<link id="CssLink-<guid>">` (the id ATTRIBUTE
# moves, the href does not) and a fresh ASP.NET `__VIEWSTATE`. Three fetches
# gave THREE distinct SHA-256s. Both are attribute-borne, so the tag-stripping
# reduction absorbs them free -- reduced text identical at 7,412 characters
# across every fetch -- and `ky_probe()` compares a CONTENT digest.
#
# Unlike California's and Louisiana's constant-length re-rolls, Kentucky's
# byte COUNT does move (83,997 vs 84,004), so a byte-count check would catch
# this one. That is a fact about SharePoint's viewstate, not a general rule:
# the content digest is what the probe compares.
#
# Usage:
#   Rscript R/03af_ky_year1_probe.R --fetch [--force]
#   Rscript R/03af_ky_year1_probe.R --validate
#   Rscript R/03af_ky_year1_probe.R --build
#   Rscript R/03af_ky_year1_probe.R --probe
#   Rscript R/03af_ky_year1_probe.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
  library(purrr); library(httr); library(digest); library(here); library(rlang)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_pdf_text.R"))

KY_STATE        <- "KY"
KY_ALLOTMENT    <- 212905591        # cms_fy2026_allotments.csv (§7.1)
KY_NOA_AMOUNT   <- 212905590.56     # CMS's own Notice of Award, to the cent
KY_EVIDENCE_DIR <- here::here("data", "evidence", "KY")
KY_STATUS_CSV   <- here::here("data", "reference", "ky_year1_status.csv")
KY_DISPO_CSV    <- here::here("data", "reference",
                              "ky_rcj_candidate_disposition.csv")

# §3: identify honestly. Kentucky's hosts accept the project's own agent on
# every path read here -- measured, not assumed -- so no exception arises.
KY_USER_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                        "+https://www.aha.org)")

KY_SOURCES <- tibble::tribble(
  ~key,          ~url, ~file, ~note,
  "programme",
  "https://ruralhealthplan.ky.gov/Pages/index.aspx",
  "2026-09-02_ky_ruralhealthplan_home.html",
  "Team Kentucky Rural Health Transformation -- the programme home.",
  "funding",
  "https://ruralhealthplan.ky.gov/Pages/Request_For_Applications.aspx",
  "2026-09-02_ky_ruralhealthplan_funding_opportunities.html",
  paste("NINE RFAs, NOT ONE naming a recipient. The page this whole finding",
        "rests on."),
  "chfs_grants",
  "https://www.chfs.ky.gov/agencies/os/oas/Pages/grants.aspx",
  "2026-09-02_ky_chfs_grant_opportunities.html",
  paste("THE POSITIVE CONTROL. CHFS's cabinet-wide grants channel, which",
        "states presence or absence PER AGENCY in its own words ('No grant",
        "opportunities are available at this time'), so silence is a",
        "statement rather than a gap in our reading."),
  "rfa_chw",
  paste0("https://www.chfs.ky.gov/agencies/os/oas/Documents/",
         "RHT%20-%20Community%20Health%20Worker%20-%20RFA.pdf"),
  "2026-09-02_ky_rfa_community_health_worker.pdf",
  paste("Carries 'August 26, 2026 Anticipated Notification of Award to",
        "Recipients' and a MAXIMUM AWARD of $800,000."),
  "rfa_cmhc",
  paste0("https://www.chfs.ky.gov/agencies/os/oas/Documents/",
         "RHT%20CMHC%20Support%20-%20RFA.pdf"),
  "2026-09-02_ky_rfa_cmhc_support.pdf",
  "Carries 'July 10, 2026: Notification of Award to Grantees'.",
  "cms_noa",
  paste0("https://www.chfs.ky.gov/agencies/os/oas/Documents/",
         "CMS%20Notice%20of%20Award%20-%20Attachment%20B.pdf"),
  "2026-09-02_ky_cms_notice_of_award_attachment_b.pdf",
  paste("CMS's OWN Notice of Award, attached to EVERY RFA. §6.2 in its",
        "strongest form AND the §0.2 trap nine times over."),
  "rch",
  "https://healthy-ky.org/rch",
  "2026-09-02_ky_foundation_healthy_kentucky_rch.html",
  paste("The designated pass-through's own page (§7, Illinois/ICAHN's",
        "route). Describes the Hub Lead ROLE and names NO Hub Lead.")
)

ky_source <- function(key, field) {
  row <- KY_SOURCES[KY_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[KY] unknown source key: ", key, call. = FALSE)
  row[[field]]
}

ky_path <- function(key) file.path(KY_EVIDENCE_DIR, ky_source(key, "file"))


# -- retrieval ---------------------------------------------------------------

ky_get <- function(url, label) {
  resp <- httr::GET(url, httr::user_agent(KY_USER_AGENT),
                    httr::timeout(120))
  if (httr::status_code(resp) != 200L) {
    stop("[KY] ", label, ": HTTP ", httr::status_code(resp), " from ", url,
         call. = FALSE)
  }
  httr::content(resp, as = "raw")
}

#' No credential-shaped string reaches the archive (§7.1, Illinois's remedy)
ky_assert_no_credentials <- function(raw, label) {
  # useBytes = TRUE, and it is not optional: a PDF carries arbitrary binary in
  # its object dictionaries, and a UTF-8 regex over that errors outright
  # rather than answering (session 24's lesson in R/utils_pdf_text.R).
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "bytes"
  bad <- c("[ps]k\\.ey[A-Za-z0-9._-]{10,}", "AIza[0-9A-Za-z_-]{30,}")
  for (p in bad) {
    if (grepl(p, txt, useBytes = TRUE, perl = TRUE)) {
      stop("[KY] ", label, " carries a credential-shaped string (", p,
           "); it was NOT written.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

ky_fetch <- function(force = FALSE) {
  dir.create(KY_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  entries <- purrr::map_dfr(seq_len(nrow(KY_SOURCES)), function(i) {
    src <- KY_SOURCES[i, ]
    dest <- file.path(KY_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[KY] have ", src$file)
    } else {
      raw <- ky_get(src$url, src$key)
      ky_assert_no_credentials(raw, src$key)
      writeBin(raw, dest)          # exact bytes; the manifest digest verifies
      message("[KY] wrote ", src$file, " (", length(raw), " bytes)")
      Sys.sleep(2)                 # §9.5 throttle
    }
    tibble::tibble(file = src$file, bytes = file.size(dest),
                   sha256 = digest::digest(file = dest, algo = "sha256"))
  })
  ky_write_manifest(entries)
  invisible(entries)
}

ky_write_manifest <- function(entries) {
  path <- file.path(KY_EVIDENCE_DIR, "MANIFEST.txt")
  # §15 (session 15): a manifest never lists itself -- the value would be
  # stale the instant the file is written.
  entries <- entries[entries$file != "MANIFEST.txt", ]
  writeLines(c(
    "KENTUCKY -- RHTP evidence archive",
    "",
    "Fetched 2026-09-02 by R/03af_ky_year1_probe.R --fetch.",
    "Bodies are written with writeBin(), so re-hashing a file on disk",
    "reproduces its digest below.",
    "",
    "THE FILE DIGEST OF THE TWO ruralhealthplan.ky.gov PAGES IS NOT A CHANGE",
    "TEST. SharePoint re-rolls a GUID in every <link id=\"CssLink-...\"> and a",
    "fresh ASP.NET __VIEWSTATE on every render: three fetches, three distinct",
    "SHA-256s. Both are attribute-borne, so ky_reduce_html() absorbs them and",
    "--probe compares a CONTENT digest. Re-verify with ky_content_digest().",
    "",
    "file  bytes  sha256",
    paste(entries$file, entries$bytes, entries$sha256, sep = "  ")
  ), path)
  invisible(path)
}


# -- reduction ---------------------------------------------------------------

#' Strip tags and scripts; what survives is the text a reader sees
#'
#' THIS IS THE CHANGE TEST, NOT THE FILE DIGEST. It discards ATTRIBUTES, which
#' is what absorbs SharePoint's CssLink GUIDs and its __VIEWSTATE at once.
ky_reduce_html <- function(raw) {
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "UTF-8"
  txt <- stringr::str_remove_all(
    txt, stringr::regex("<(script|style|noscript)[^>]*>.*?</\\1>",
                        dotall = TRUE, ignore_case = TRUE))
  txt <- stringr::str_replace_all(txt, "<[^>]+>", " ")
  txt <- stringr::str_replace_all(txt, "&nbsp;|&#160;", " ")
  txt <- stringr::str_replace_all(txt, "&amp;", "&")
  txt <- stringr::str_replace_all(txt, "&#39;|&rsquo;|&#8217;", "'")
  txt <- stringr::str_replace_all(txt, "&quot;|&ldquo;|&rdquo;", "\"")
  txt <- stringr::str_replace_all(txt, "[ \t\u00a0]+", " ")
  txt <- stringr::str_replace_all(txt, "\\s*\n\\s*", "\n")
  stringr::str_trim(txt)
}

ky_html_text <- function(key, body = NULL) {
  raw <- if (is.null(body)) readBin(ky_path(key), "raw",
                                    file.size(ky_path(key))) else body
  ky_reduce_html(raw)
}

ky_pdf_text <- function(key, body = NULL) {
  path <- if (is.null(body)) ky_path(key) else {
    tmp <- tempfile(fileext = ".pdf"); writeBin(body, tmp); tmp
  }
  paste(rhtp_pdf_text(path), collapse = "\n")
}

ky_content_digest <- function(key, body = NULL) {
  txt <- if (grepl("\\.pdf$", ky_source(key, "file"))) {
    ky_pdf_text(key, body)
  } else {
    ky_html_text(key, body)
  }
  digest::digest(txt, algo = "sha256")
}

ky_have_archive <- function() {
  all(file.exists(file.path(KY_EVIDENCE_DIR, KY_SOURCES$file)))
}


# -- the award-language tripwire ---------------------------------------------

# THE PHRASES THAT WOULD MEAN KENTUCKY HAS AWARDED.
#
# "Notice of Award" IS DELIBERATELY NOT AMONG THEM, and that is the single
# most important line in this file. It occurs TEN times across Kentucky's two
# funding pages and every one is CMS's award to KENTUCKY shipped as an RFA
# attachment -- not a state award to a recipient. Included, this tripwire
# would fire on every run from the day it was written and be switched off by
# whoever met it first. Measured on the live pages, not guessed.
KY_AWARD_POSTED <- c(
  "notice of intent to award",
  "intent to award",
  "has been selected for award",
  "selected for award",
  "awardees are",
  "award recipients",
  "grant recipients",
  "funded organizations",
  "list of awardees",
  "successful applicants"
)

ky_award_language <- function(txt) {
  low <- stringr::str_to_lower(txt)
  KY_AWARD_POSTED[vapply(KY_AWARD_POSTED,
                         function(p) stringr::str_detect(low,
                                                         stringr::fixed(p)),
                         logical(1))]
}

#' Kentucky has named no recipient on any watched surface
#'
#' Runs against the archive by default and against LIVE bytes from --probe
#' (session 25's Indiana lesson: --validate reads the committed copy and can
#' only answer "had Kentucky awarded on the day the archive was taken?").
ky_assert_no_roster <- function(bodies = NULL) {
  keys <- c("funding", "programme", "rch")
  hits <- purrr::map_dfr(keys, function(k) {
    body <- if (!is.null(bodies) && !is.null(bodies[[k]])) bodies[[k]] else NULL
    found <- ky_award_language(ky_html_text(k, body))
    if (!length(found)) return(tibble::tibble())
    tibble::tibble(key = k, phrase = found)
  })
  if (nrow(hits)) {
    stop("[KY] award language has appeared on a watched page: ",
         paste(sprintf("%s -> '%s'", hits$key, hits$phrase), collapse = "; "),
         ". Kentucky may have published a roster. This file must be REWRITTEN ",
         "as an award extractor, not patched -- ky_year1_status.csv has no ",
         "amount column by design.", call. = FALSE)
  }
  invisible(TRUE)
}

#' Collapse to LETTERS ONLY before matching a name
#'
#' SESSION 36'S LOUISIANA FINDING, MET ON A DIFFERENT PRODUCER. Kentucky's
#' SharePoint editor paints headings with stray spacing inside words -- the
#' live page carries "R ural Community Hubs", "Ro oted in Health", "Fr om
#' Crisis to Care" and "K entucky" -- so a fixed-string match on the brand
#' name fails on text a reader sees as ordinary. Louisiana's producer split
#' "Food isMedicine" the other way (a missing space); the answer is the same
#' either way, which is why it is a shared idea rather than a Louisiana quirk.
ky_letters_only <- function(x) {
  stringr::str_to_lower(stringr::str_replace_all(x, "[^A-Za-z]", ""))
}

#' The nine RFAs are on the page and none of them names anybody
ky_assert_nine_rfas <- function(body = NULL) {
  txt <- ky_letters_only(ky_html_text("funding", body))
  brands <- c("Community Health Worker Specialized Certificate",
              "Establish or Expand Community Paramedicine Program",
              "EMS Training Equipment", "EMS Transformation",
              "CMHC Support", "Telebehavioral Health Support",
              "Definitive Mobile Dental Services", "Rural Dental Access",
              "Accredited Dental Hygiene Programs",
              "Rural Community Hubs for Chronic Care Innovation")
  missing <- brands[!vapply(brands, function(b)
    stringr::str_detect(txt, stringr::fixed(ky_letters_only(b))),
    logical(1))]
  if (length(missing)) {
    stop("[KY] the funding page no longer carries: ",
         paste(missing, collapse = "; "),
         ". The solicitation set has changed and this file's finding with it.",
         call. = FALSE)
  }
  invisible(TRUE)
}


# -- the dates, re-derived every run -----------------------------------------

# THE STATE NAMED THE STEP AND THE DAY. Both are read out of the archived RFAs
# rather than typed, so a re-issued RFA that moves its date moves this finding.
KY_AWARD_DATES <- tibble::tribble(
  ~key,       ~rfa,                                  ~date,        ~quote,
  "rfa_cmhc", "Rapid Response to Recovery: CMHC Support",
  "2026-07-10", "July 10, 2026: Notification of Award to Grantees",
  "rfa_chw",  "Community Health Worker Specialized Certificate",
  "2026-08-26", "August 26, 2026 Anticipated Notification of Award to Recipients"
)

#' Every published award-notification date has passed, and no roster followed
#'
#' THE CHEAPEST TRIPWIRE IN THIS FILE (§0.2's twentieth question, session 35).
#' A state that publishes the date AND the form of its own announcement makes
#' its silence measurable: this is not "we could not find a roster", it is
#' "Kentucky said it would notify recipients on these days and has published
#' nothing since".
ky_assert_award_dates_passed <- function(today = Sys.Date(), bodies = NULL) {
  purrr::walk(seq_len(nrow(KY_AWARD_DATES)), function(i) {
    row <- KY_AWARD_DATES[i, ]
    body <- if (!is.null(bodies)) bodies[[row$key]] else NULL
    txt <- ky_pdf_text(row$key, body)
    flat <- stringr::str_replace_all(txt, "\\s+", " ")
    want <- stringr::str_replace_all(row$quote, "\\s+", " ")
    if (!stringr::str_detect(flat, stringr::fixed(want))) {
      stop("[KY] ", row$rfa, " no longer carries its own award-notification ",
           "sentence \"", row$quote, "\". The date this finding is measured ",
           "against has moved; re-read the RFA.", call. = FALSE)
    }
  })
  passed <- KY_AWARD_DATES$date[as.Date(KY_AWARD_DATES$date) < today]
  if (!length(passed)) {
    message("[KY] no published award-notification date has passed yet; the ",
            "negative is not yet overdue.")
  }
  invisible(as.Date(KY_AWARD_DATES$date) < today)
}


# -- §6.2 provenance, and the §0.2 tier trap ---------------------------------

#' Kentucky publishes CMS's OWN Notice of Award -- the fourth state to do so
ky_assert_cms_noa <- function(body = NULL) {
  txt <- stringr::str_replace_all(ky_pdf_text("cms_noa", body), "\\s+", " ")
  want <- c("Notice of Award", "93.798", "Rural Health Transformation Program",
            "Kentucky Cabinet for Health Services", "212,905,590.56")
  missing <- want[!vapply(want,
                          function(w) stringr::str_detect(txt,
                                                          stringr::fixed(w)),
                          logical(1))]
  if (length(missing)) {
    stop("[KY] the archived CMS Notice of Award no longer carries: ",
         paste(missing, collapse = "; "), call. = FALSE)
  }
  if (abs(KY_NOA_AMOUNT - KY_ALLOTMENT) > 1) {
    stop("[KY] the NOA amount and the §7.1 anchor have diverged.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' The NOA is Kentucky's ALLOTMENT and is never any RFA's pool (§0.2)
#'
#' THE ASSERTION THIS SESSION'S §0.2 RULE WAS WRITTEN FOR, MEETING A LIVE
#' EXPOSURE NINE TIMES OVER. Kentucky attaches this Notice of Award to every
#' one of its nine RFAs, so each solicitation ships a document whose only
#' headline figure is the whole state allotment -- against a stated maximum
#' award of $800,000 on the CHW RFA. Read as that RFA's pool it publishes the
#' allotment, 266x the actual ceiling, as one solicitation's budget.
ky_assert_noa_is_not_a_pool <- function() {
  # Declared correctly: it IS the allotment, and the shared rule agrees.
  ok <- rhtp_assert_footer_not_allotment(
    KY_NOA_AMOUNT, KY_STATE, "STATE_ALLOTMENT",
    label = "KY CMS Notice of Award (attached to all nine RFAs)")
  if (!isTRUE(ok)) {
    message("[KY] the §0.2 tier check did not run -- see the message above. ",
            "That is a gap in the anchor, not a pass (§0.4).")
    return(invisible(NA))
  }
  # And the misreading is refused. This is the branch that matters.
  refused <- tryCatch({
    rhtp_assert_footer_not_allotment(
      KY_NOA_AMOUNT, KY_STATE, "SOLICITATION",
      label = "KY CMS Notice of Award read as an RFA pool")
    FALSE
  }, error = function(e) TRUE)
  if (!refused) {
    stop("[KY] the §0.2 rule NO LONGER REFUSES Kentucky's allotment being ",
         "read as a solicitation pool. That refusal is the only thing ",
         "standing between this archive and a $212.9M pool figure.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Kentucky's NOA is the ORIGINAL award, not a revision (corroborates §6.2)
#'
#' Nevada's, California's and Connecticut's published NOAs are all
#' "Revision (Budget)" and all carry a Federal Award Date LATER than the
#' budget period start (+52, +92, +206 days), which is why session 36 pinned
#' the date test to the budget period. Kentucky's is Action Type "New" with
#' Federal Award Date 12/29/2025 -- equal to its budget period start and to
#' the committed anchor. The first direct observation that the two fields
#' agree when there has been no revision.
ky_assert_noa_is_original <- function(body = NULL) {
  path <- if (is.null(body)) ky_path("cms_noa") else {
    tmp <- tempfile(fileext = ".pdf"); writeBin(body, tmp); tmp
  }
  lines <- trimws(rhtp_pdf_text(path))

  # SCOPE THE CHECK TO THE HEADER BLOCK, AND THE REASON IS A FALSE POSITIVE
  # THIS FILE ALREADY HIT. The NOA's terms and conditions instruct the
  # recipient to "utilize Revision (Budget) amendment type" for future
  # changes -- boilerplate present on EVERY NOA including an original one. A
  # whole-document search for "Revision (Budget)" therefore reports every
  # NOA as a revision, which is the opposite of this assertion's finding.
  # The field value lives in the header block, above the terms.
  terms <- grep("Recipient Specific Terms", lines)
  head_block <- lines[seq_len(if (length(terms)) terms[1] - 1L else
                              min(length(lines), 120L))]

  if (!any(head_block == "12/29/2025")) {
    stop("[KY] the NOA header no longer carries the 12/29/2025 anchor date.",
         call. = FALSE)
  }
  if (!any(grepl("Award Action Type", head_block, fixed = TRUE))) {
    stop("[KY] the NOA's Award Action Type field is gone.", call. = FALSE)
  }
  if (!any(head_block == "New")) {
    stop("[KY] the NOA header no longer carries Award Action Type 'New'. If ",
         "Kentucky has replaced its original NOA with a revised one, the ",
         "corroboration this file offers session 36 -- the only direct ",
         "observation that Federal Award Date and budget-period start AGREE ",
         "when there has been no revision -- is gone, and the note must be ",
         "rewritten rather than kept.", call. = FALSE)
  }
  if (any(grepl("Revision (Budget)", head_block, fixed = TRUE))) {
    stop("[KY] the NOA HEADER now carries 'Revision (Budget)'. Kentucky has ",
         "published a revised NOA; re-read it before relying on the ",
         "original-award corroboration.", call. = FALSE)
  }
  anchor <- readr::read_csv(
    here::here("data", "reference", "cms_state_noa_dates.csv"),
    show_col_types = FALSE, progress = FALSE)
  ky_anchor <- anchor$noa_date[anchor$state == KY_STATE]
  if (length(ky_anchor) == 1L &&
      !identical(as.character(ky_anchor), "2025-12-29")) {
    stop("[KY] the committed NOA anchor for KY is ", ky_anchor,
         ", but Kentucky's own Notice of Award prints 12/29/2025.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' "Notice of Award" on Kentucky's estate is CMS's, never a state award
#'
#' The trap that poisons the obvious search, asserted so that a future session
#' cannot re-derive it the hard way.
ky_assert_noa_phrase_is_not_an_award <- function(bodies = NULL) {
  n <- purrr::map_int(c("funding", "chfs_grants"), function(k) {
    body <- if (!is.null(bodies)) bodies[[k]] else NULL
    txt <- ky_html_text(k, body)
    length(stringr::str_extract_all(txt, "Notice of Award")[[1]])
  })
  if (sum(n) < 2L) {
    stop("[KY] 'Notice of Award' has nearly vanished from Kentucky's funding ",
         "pages (", sum(n), " occurrences). It was the CMS attachment on ",
         "every RFA; if that has changed, re-read the pages.", call. = FALSE)
  }
  # Every one must be the CMS attachment, i.e. adjacent to "Attachment".
  purrr::walk(c("funding", "chfs_grants"), function(k) {
    body <- if (!is.null(bodies)) bodies[[k]] else NULL
    txt <- stringr::str_replace_all(ky_html_text(k, body), "\\s+", " ")
    ctx <- stringr::str_extract_all(txt, ".{0,20}Notice of Award.{0,20}")[[1]]
    bare <- ctx[!stringr::str_detect(ctx, "CMS Notice of Award")]
    if (length(bare)) {
      stop("[KY] a 'Notice of Award' on ", k, " is NOT the CMS attachment: ",
           paste(sQuote(stringr::str_trim(bare)), collapse = "; "),
           ". Kentucky may have posted a state award -- read it.",
           call. = FALSE)
    }
  })
  invisible(sum(n))
}


# -- the positive controls ---------------------------------------------------

#' Kentucky's grants channel states ABSENCE in its own words
#'
#' THE CONTROL THAT MAKES THE NEGATIVE MEAN SOMETHING. Without it, "no roster
#' on the RFA page" is indistinguishable from "we are reading the wrong page".
#' CHFS's cabinet-wide grants channel enumerates every agency and says, for
#' those with nothing, "No grant opportunities are available at this time" --
#' so the channel distinguishes presence from absence explicitly, and it
#' carries Kentucky's RHTP RFAs under Public Health beside the others.
ky_assert_grants_channel_control <- function(body = NULL) {
  txt <- ky_html_text("chfs_grants", body)
  n_absent <- length(stringr::str_extract_all(
    txt, "No grant opportunities are available at this time")[[1]])
  if (n_absent < 3L) {
    stop("[KY] the CHFS grants channel no longer states absence per agency (",
         n_absent, " occurrences). The control is gone; the negative it ",
         "supports must be re-established before it is reported.",
         call. = FALSE)
  }
  if (!stringr::str_detect(txt, stringr::fixed("RHT "))) {
    stop("[KY] the CHFS grants channel no longer carries Kentucky's RHTP ",
         "solicitations, so it no longer controls this finding.",
         call. = FALSE)
  }
  invisible(n_absent)
}

#' The CHW RFA's own maximum award, which is what sizes the §0.2 trap
ky_assert_chw_ceiling <- function(body = NULL) {
  txt <- stringr::str_replace_all(ky_pdf_text("rfa_chw", body), "\\s+", " ")
  if (!stringr::str_detect(txt, stringr::fixed("$800,000"))) {
    stop("[KY] the CHW RFA no longer states its $800,000 maximum award, ",
         "which is the figure the §0.2 trap is measured against.",
         call. = FALSE)
  }
  invisible(800000)
}


# -- the status table --------------------------------------------------------

# NO `amount` COLUMN, DELIBERATELY (Texas's device). Kentucky has named no
# recipient and published no per-recipient figure, so there is nothing for an
# amount column to hold and everything for it to imply.
ky_status_table <- function() {
  tibble::tribble(
    ~state, ~channel, ~stage, ~publishes_roster, ~award_date_published, ~note,
    KY_STATE, "Community Health Worker Specialized Certificate",
    "CLOSED_AWARD_DATE_PASSED", "No", "2026-08-26",
    paste("Applications closed 2026-08-05. The RFA's own timeline gives",
          "'August 26, 2026 Anticipated Notification of Award to",
          "Recipients'. Maximum award $800,000; funding period begins",
          "2026-10-07. No roster."),
    KY_STATE, "Rapid Response to Recovery: CMHC Support",
    "CLOSED_AWARD_DATE_PASSED", "No", "2026-07-10",
    paste("Applications closed 2026-07-03. The RFA's own timeline gives",
          "'July 10, 2026: Notification of Award to Grantees'. Funding",
          "period begins 2026-10-01. No roster."),
    KY_STATE, "Rapid Response to Recovery: Telebehavioral Health Support",
    "CLOSED_UNAWARDED", "No", NA_character_,
    "Applications closed 2026-07-06. No roster, no published award date.",
    KY_STATE, "Crisis to Care: Community Paramedicine",
    "CLOSED_UNAWARDED", "No", NA_character_,
    "'Applications currently closed'. No roster.",
    KY_STATE, "Crisis to Care: EMS Training Equipment / Mobile Training Units",
    "CLOSED_UNAWARDED", "No", NA_character_,
    "'Applications currently closed'. No roster.",
    KY_STATE, "Crisis to Care: EMS Transformation",
    "CLOSED_UNAWARDED", "No", NA_character_,
    "'Applications currently closed'. No roster.",
    KY_STATE, "Rooted in Health: Definitive Mobile Dental Services",
    "OPEN_ROLLING", "No", NA_character_,
    paste("Closed 2026-06-12 but 'remains open to applications during this",
          "budget period until funds are exhausted'. No roster."),
    KY_STATE, "Rooted in Health: Rural Dental Access Program",
    "CLOSED_UNAWARDED", "No", NA_character_,
    paste("Closed 2026-04-12; 'Applications will be considered on a rolling",
          "basis, but Year 1 funding is not guaranteed.' No roster."),
    KY_STATE, "Rooted in Health: Accredited Dental Hygiene Programs",
    "CLOSED_UNAWARDED", "No", NA_character_,
    "Closed 2026-08-01 per the CHFS channel. No roster.",
    KY_STATE, "Rural Community Hubs for Chronic Care Innovation",
    "CLOSED_UNAWARDED", "No", NA_character_,
    paste("Hub Lead RFA closed 2026-06-01 for the Big Sandy, Lake Cumberland",
          "and Purchase ADDs. THE POOL TO WATCH -- see the report."),
    KY_STATE, "Foundation for a Healthy Kentucky (designated pass-through)",
    "NO_ROSTER", "No", NA_character_,
    paste("FHKY is 'a primary partner' for the Rural Community Hubs",
          "initiative and publishes its own RHTP page (§7's route). It",
          "describes the Hub Lead ROLE and names NO Hub Lead: 'awarded',",
          "'awardee', 'selected' and 'recipient' are ZERO on it.")
  )
}

ky_disposition <- function() {
  rt <- readRDS(here::here("data", "interim", "stage2_record_table.rds"))
  ky <- rt %>% dplyr::filter(.data$state == KY_STATE)
  n_t3 <- sum(ky$award_tier == "SUBAWARD")
  tibble::tribble(
    ~state, ~group, ~rcj_rows, ~disposition, ~evidence,
    KY_STATE, "Tier 3 (SUBAWARD) candidates", n_t3,
    "NO_TIER_3_SIGNAL_AT_ALL",
    paste0("Kentucky is one of TWELVE states carrying NO RCJ Tier 3 ",
           "candidate. It holds ", nrow(ky), " RCJ records in total -- ",
           "SOLICITATION and STATE_ALLOTMENT rows for its own RFAs and its ",
           "CMS award -- and NOT ONE is a subaward. The aggregator is right ",
           "about Kentucky, which is the unusual case: the state has awarded ",
           "nobody publicly, so there is nothing for it to get wrong. A zero ",
           "here is a fact about the DISCOVERY LAYER and never about the ",
           "state (§0.1) -- Florida had 81 awards and no candidate either.")
  )
}


# -- the live probe ----------------------------------------------------------

#' Re-read the watched pages LIVE and run the tripwires against those bytes
#'
#' --validate reads the committed archive and passes trivially; only a fetch
#' answers "has Kentucky awarded?". Session 25's Indiana lesson as code.
ky_probe <- function() {
  keys <- c("funding", "programme", "rch", "chfs_grants")
  live <- purrr::map(keys, function(k) ky_get(ky_source(k, "url"), k))
  names(live) <- keys
  Sys.sleep(1)

  cmp <- purrr::map_dfr(keys, function(k) {
    tibble::tibble(
      key = k,
      archived_content = ky_content_digest(k),
      live_content = ky_content_digest(k, live[[k]]),
      archived_file = digest::digest(file = ky_path(k), algo = "sha256"),
      live_file = digest::digest(live[[k]], algo = "sha256", serialize = FALSE)
    )
  }) %>%
    dplyr::mutate(content_changed = .data$archived_content != .data$live_content,
                  file_changed = .data$archived_file != .data$live_file)

  ky_assert_no_roster(bodies = live)
  ky_assert_nine_rfas(body = live$funding)
  ky_assert_noa_phrase_is_not_an_award(bodies = live)
  ky_assert_grants_channel_control(body = live$chfs_grants)

  message("[KY] live probe ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " UTC")
  purrr::walk(seq_len(nrow(cmp)), function(i) {
    r <- cmp[i, ]
    message(sprintf("  %-12s content %s   file %s", r$key,
                    if (r$content_changed) "CHANGED" else "unchanged",
                    if (r$file_changed) "differs (expected -- SharePoint)"
                    else "unchanged"))
  })
  if (any(cmp$content_changed)) {
    message("[KY] CONTENT CHANGED on: ",
            paste(cmp$key[cmp$content_changed], collapse = ", "),
            ". Re-fetch and read before trusting ky_year1_status.csv.")
  } else {
    message("[KY] UNCHANGED. Kentucky has still named no recipient.")
  }
  passed <- ky_assert_award_dates_passed()
  message("[KY] published award-notification dates passed: ", sum(passed),
          " of ", length(passed), " (", paste(KY_AWARD_DATES$date[passed],
                                              collapse = ", "), ")")
  invisible(cmp)
}


# -- validate / build / report -----------------------------------------------

ky_validate <- function() {
  if (!ky_have_archive()) {
    stop("[KY] the evidence archive is incomplete; run --fetch first.",
         call. = FALSE)
  }
  ky_assert_no_roster()
  ky_assert_nine_rfas()
  ky_assert_award_dates_passed()
  ky_assert_cms_noa()
  ky_assert_noa_is_not_a_pool()
  ky_assert_noa_is_original()
  ky_assert_noa_phrase_is_not_an_award()
  ky_assert_grants_channel_control()
  ky_assert_chw_ceiling()
  message("[KY] all assertions pass.")
  invisible(TRUE)
}

ky_build <- function() {
  st <- ky_status_table()
  if ("amount" %in% names(st)) {
    stop("[KY] ky_year1_status.csv must have NO amount column: Kentucky has ",
         "published no per-recipient figure (Texas's device).", call. = FALSE)
  }
  readr::write_csv(st, KY_STATUS_CSV)
  message("[KY] wrote ", KY_STATUS_CSV, " (", nrow(st), " rows)")
  d <- ky_disposition()
  readr::write_csv(d, KY_DISPO_CSV)
  message("[KY] wrote ", KY_DISPO_CSV, " (", nrow(d), " rows)")
  invisible(list(status = st, disposition = d))
}

ky_report <- function() {
  st <- ky_status_table()
  cat("\nKENTUCKY -- a NEGATIVE, and its own award dates have passed\n")
  cat(strrep("=", 68), "\n\n")
  cat("Allotment (§7.1)        : $", format(KY_ALLOTMENT, big.mark = ","),
      "\n", sep = "")
  cat("Recipient-level awards  : NONE PUBLISHED\n")
  cat("RCJ Tier 3 candidates   : 0 -- no signal on either discovery layer\n\n")
  cat("Channels:\n")
  print(as.data.frame(st[, c("channel", "stage", "award_date_published")]),
        row.names = FALSE)
  cat("\nTHE DATES KENTUCKY PUBLISHED, AND WHETHER THEY HAVE PASSED:\n")
  for (i in seq_len(nrow(KY_AWARD_DATES))) {
    r <- KY_AWARD_DATES[i, ]
    cat(sprintf("  %-46s %s  %s\n", r$rfa, r$date,
                if (as.Date(r$date) < Sys.Date()) "PASSED" else "upcoming"))
  }
  cat("\n§6.2: Kentucky publishes CMS's OWN Notice of Award (4th state).\n")
  cat("      Action Type 'New', Federal Award Date 12/29/2025 -- the FIRST\n")
  cat("      published state NOA that is not a revision.\n")
  cat("\n§0.2: that NOA is attached to ALL NINE RFAs. Read as a pool it\n")
  cat("      publishes $212,905,590.56 against a stated $800,000 ceiling.\n")
  invisible(st)
}


if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) ky_fetch(force = "--force" %in% args)
  if ("--validate" %in% args) ky_validate()
  if ("--build" %in% args) ky_build()
  if ("--probe" %in% args) ky_probe()
  if ("--report" %in% args) ky_report()
  if (!length(args)) {
    message("Usage: --fetch [--force] | --validate | --build | --probe | --report")
  }
}
