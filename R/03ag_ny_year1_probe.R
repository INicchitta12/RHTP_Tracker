#!/usr/bin/env Rscript
# 03ag_ny_year1_probe.R -------------------------------------------------------
#
# NEW YORK -- A NEGATIVE WHOSE CONTRACTS WERE DUE TO BEGIN THE DAY BEFORE THIS
# RAN, AND THE FIRST STATE IN THIS PROJECT THAT REQUIRES A HOSPITAL IN EVERY
# AWARD.
#
# New York holds $212,058,208 (§7.1) and was one of TWELVE states carrying NO
# RCJ Tier 3 signal. It has published NO recipient-level award list.
#
# ITS ONE RECIPIENT-LEVEL SOLICITATION HAS RUN AND ITS CONTRACT START DATE HAS
# PASSED. The Rural Community Health Integration (RCHI) funding opportunity
# allocates "$76,190,022 for Budget Period 1" -- 35.9% of the allotment -- and
# its own guidance gives the whole timeline: released June 11 2026,
# applications due July 9 2026, and
#
#   "Contracts for funded grantees will begin on September 1, 2026 and end on
#    June 30, 2027"
#   "All contracts must be executed by October 30, 2026"
#
# THIS RAN 2026-09-02. The day contracts were to begin has gone by with no
# grantee named anywhere reachable. Connecticut was the first negative here
# whose award-announcement date had passed; Louisiana had seven announcement
# windows; Kentucky named the notification step twice. NEW YORK'S PASSED DATE
# IS A CONTRACT START, which is one step FURTHER down the process than any of
# them -- the state is past announcing and into performing, and still names
# nobody.
#
# AND THE STATE SAYS WHERE IT HAS GOT TO, IN ITS OWN DECK. The DOH update of
# 2026-08-12 prints, against RCHI:
#
#   "Applications Due: July 14, 2026"
#   "91 Applications, $156,000,000 total request"
#   "Reviews and Funding Recommendation In Progress"
#
# §0.3 IN THE STATE'S OWN NUMBERS, AND OVERSUBSCRIBED TWO TO ONE: 91
# applications and $156M of requests against $76.2M available, with NOT ONE
# award named. Louisiana's slide 18 said the same thing with 505 applications;
# New York says it with a status line reading "In Progress" three weeks before
# this ran. (The deck's July 14 and the guidance's July 9 are BOTH the state's
# own and are recorded as they stand -- §8 keeps the source's language and
# resolves nothing. The addendum of July 2 2026 is the likely reason and that
# is an inference, so it is not published as a finding.)
#
# THE ELIGIBLE CLASS IS NEW TO THIS REPOSITORY AND IT IS THE STRONGEST YET.
# Every pass-through question this project has met has been one of two shapes:
# Illinois/ICAHN, where eligibility is HOSPITALS ONLY (§10.2's second clause
# met, `Yes`), or New Hampshire/FHC, where hospitals are AMONG OTHERS (§0.3,
# `Unclear`). RCHI is NEITHER. Its guidance requires:
#
#   "A hospital must be included as either the lead applicant or the partner
#    Organization"
#   "At least one hospital located in the counties listed in Attachment 1 is
#    included in the [partnership]"
#
# HOSPITALS ARE MANDATORY IN EVERY AWARD, BUT NEED NOT BE THE RECIPIENT. The
# lead applicant may be "a registered not-for-profit 501(c)(3) organization or
# municipal hospital". So a hospital is guaranteed to be IN each partnership
# and is not guaranteed to RECEIVE anything -- which is §0.3 with the trap
# moved one step closer. When RCHI awards, the question for every row is
# whether the named lead applicant is the hospital or the partner beside it,
# and `distributed_to_hospital` must be read off the award, never off the
# eligibility rule. Recorded now, before there is a roster to be hasty with.
#
# THE POSITIVE CONTROL IS A CHANNEL, AND IT IS UNUSUALLY CLEAN. DOH's 2026
# press index carries FIFTEEN award announcements naming programmes and
# amounts -- "$10 Million to Expand Access to Dental Care for Children",
# "$74 Million to Make Local Water Infrastructure Projects Affordable",
# "Nearly $3 Million Renovation for SUNY Upstate Medical Center" -- so the
# department demonstrably publishes awards in a recognisable form on a channel
# this environment can read. On that same index, "Rural Health Transformation"
# occurs EXACTLY ONCE, and it is
#
#   "New York State Department of Health Announces First Rural Health
#    Transformation Program Funding Opportunity"
#
# -- an OPPORTUNITY, not an award. California's HCAI-newsroom control with the
# ratio stated: fifteen award announcements, one RHTP item, and it is the
# wrong kind of item.
#
# ONE CHANNEL IS UNREADABLE AND IS RECORDED AS UNKNOWN (§0.4). New York
# directs contracting to the NYS Contract Reporter (`nyscr.ny.gov`), which
# answers 200 and is a stateful search application behind a free account --
# Maine's CGI Advantage, Connecticut's CTsource and Louisiana's rhtla.net in a
# fourth costume. Whether an RHTP contract has been executed inside it is a
# statement about OUR ACCESS, never about New York.
#
# THE DIGEST FINDING, AND IT IS THE ONE THAT DID NOT MISBEHAVE. Three fetches
# of the programme page minutes apart returned the SAME SHA-256 and the same
# 28,125 bytes. Only MAINE's digests have held like that before. It is
# recorded as an observation and NOT relied on: session 34's California lesson
# is that a stable-looking pair proves nothing (a cache variant is guaranteed
# to be missed by back-to-back fetches), so `ny_probe()` compares a CONTENT
# digest exactly as every other probe here does.
#
# Usage:
#   Rscript R/03ag_ny_year1_probe.R --fetch [--force]
#   Rscript R/03ag_ny_year1_probe.R --validate
#   Rscript R/03ag_ny_year1_probe.R --build
#   Rscript R/03ag_ny_year1_probe.R --probe
#   Rscript R/03ag_ny_year1_probe.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
  library(purrr); library(httr); library(digest); library(here); library(rlang)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_pdf_text.R"))

NY_STATE        <- "NY"
NY_ALLOTMENT    <- 212058208          # cms_fy2026_allotments.csv (§7.1)
NY_FOOTER       <- 212058207.80       # the CMS footer, "in Budget Period 1"
NY_RCHI_POOL    <- 76190022           # RCHI Budget Period 1 allocation
NY_CONTRACT_START <- as.Date("2026-09-01")
NY_EVIDENCE_DIR <- here::here("data", "evidence", "NY")
NY_STATUS_CSV   <- here::here("data", "reference", "ny_year1_status.csv")
NY_DISPO_CSV    <- here::here("data", "reference",
                              "ny_rcj_candidate_disposition.csv")

NY_USER_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                        "+https://www.aha.org)")

NY_SOURCES <- tibble::tribble(
  ~key, ~url, ~file, ~note,
  "programme",
  "https://www.health.ny.gov/facilities/transforming_rural_healthcare/",
  "2026-09-02_ny_transforming_rural_healthcare.html",
  paste("DOH's RHTP programme page. Four initiatives, one funding",
        "opportunity, and NO recipient named anywhere."),
  "rchi_guidance",
  paste0("https://www.health.ny.gov/facilities/transforming_rural_healthcare/",
         "docs/rchi_funding_guidance.pdf"),
  "2026-09-02_ny_rchi_funding_guidance.pdf",
  paste("The RCHI funding guidance: $76,190,022, the full timeline",
        "including the 2026-09-01 contract start, and the eligibility rule",
        "requiring a hospital in every partnership."),
  "update_aug12",
  paste0("https://www.health.ny.gov/facilities/transforming_rural_healthcare/",
         "docs/2026-08-12_update.pdf"),
  "2026-09-02_ny_2026-08-12_update.pdf",
  paste("DOH's own status deck: 91 applications, $156,000,000 requested,",
        "'Reviews and Funding Recommendation In Progress'."),
  "press_index",
  "https://www.health.ny.gov/press/releases/2026/",
  "2026-09-02_ny_doh_press_releases_2026.html",
  paste("THE POSITIVE CONTROL. Fifteen named award announcements with",
        "amounts, and exactly ONE RHTP item -- a funding OPPORTUNITY."),
  "scr",
  "https://www.nyscr.ny.gov/",
  "2026-09-02_ny_contract_reporter.html",
  paste("The NYS Contract Reporter. UNREADABLE/UNKNOWN (§0.4): a stateful",
        "search application behind a free account.")
)

ny_source <- function(key, field) {
  row <- NY_SOURCES[NY_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[NY] unknown source key: ", key, call. = FALSE)
  row[[field]]
}

ny_path <- function(key) file.path(NY_EVIDENCE_DIR, ny_source(key, "file"))


# -- retrieval ---------------------------------------------------------------

ny_get <- function(url, label) {
  resp <- httr::GET(url, httr::user_agent(NY_USER_AGENT), httr::timeout(120))
  if (httr::status_code(resp) != 200L) {
    stop("[NY] ", label, ": HTTP ", httr::status_code(resp), " from ", url,
         call. = FALSE)
  }
  httr::content(resp, as = "raw")
}

ny_assert_no_credentials <- function(raw, label) {
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "bytes"
  bad <- c("[ps]k\\.ey[A-Za-z0-9._-]{10,}", "AIza[0-9A-Za-z_-]{30,}")
  for (p in bad) {
    if (grepl(p, txt, useBytes = TRUE, perl = TRUE)) {
      stop("[NY] ", label, " carries a credential-shaped string (", p,
           "); it was NOT written.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

ny_fetch <- function(force = FALSE) {
  dir.create(NY_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  entries <- purrr::map_dfr(seq_len(nrow(NY_SOURCES)), function(i) {
    src <- NY_SOURCES[i, ]
    dest <- file.path(NY_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[NY] have ", src$file)
    } else {
      raw <- ny_get(src$url, src$key)
      ny_assert_no_credentials(raw, src$key)
      writeBin(raw, dest)
      message("[NY] wrote ", src$file, " (", length(raw), " bytes)")
      Sys.sleep(2)
    }
    tibble::tibble(file = src$file, bytes = file.size(dest),
                   sha256 = digest::digest(file = dest, algo = "sha256"))
  })
  ny_write_manifest(entries)
  invisible(entries)
}

ny_write_manifest <- function(entries) {
  path <- file.path(NY_EVIDENCE_DIR, "MANIFEST.txt")
  entries <- entries[entries$file != "MANIFEST.txt", ]
  writeLines(c(
    "NEW YORK -- RHTP evidence archive",
    "",
    "Fetched 2026-09-02 by R/03ag_ny_year1_probe.R --fetch.",
    "Bodies are written with writeBin(), so re-hashing a file on disk",
    "reproduces its digest below.",
    "",
    "THE PROGRAMME PAGE'S FILE DIGEST HELD ACROSS THREE FETCHES (28,125 bytes,",
    "one SHA-256), which only Maine's has done before. That is recorded and",
    "NOT relied on: a stable-looking pair proves nothing (session 34's",
    "California cache variant is guaranteed to be missed by back-to-back",
    "fetches), so --probe compares a CONTENT digest like every other probe.",
    "",
    "file  bytes  sha256",
    paste(entries$file, entries$bytes, entries$sha256, sep = "  ")
  ), path)
  invisible(path)
}


# -- reduction ---------------------------------------------------------------

ny_reduce_html <- function(raw) {
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

ny_html_text <- function(key, body = NULL) {
  raw <- if (is.null(body)) readBin(ny_path(key), "raw",
                                    file.size(ny_path(key))) else body
  ny_reduce_html(raw)
}

ny_pdf_text <- function(key, body = NULL) {
  path <- if (is.null(body)) ny_path(key) else {
    tmp <- tempfile(fileext = ".pdf"); writeBin(body, tmp); tmp
  }
  paste(rhtp_pdf_text(path), collapse = "\n")
}

ny_content_digest <- function(key, body = NULL) {
  txt <- if (grepl("\\.pdf$", ny_source(key, "file"))) ny_pdf_text(key, body)
         else ny_html_text(key, body)
  digest::digest(txt, algo = "sha256")
}

ny_have_archive <- function() {
  all(file.exists(file.path(NY_EVIDENCE_DIR, NY_SOURCES$file)))
}


# -- the award-language tripwire ---------------------------------------------

NY_AWARD_POSTED <- c(
  "notice of intent to award", "intent to award",
  "selected for award", "has been awarded", "have been awarded",
  "award recipients", "grant recipients", "funded grantees are",
  "list of awardees", "awardees are", "successful applicants"
)

ny_award_language <- function(txt) {
  low <- stringr::str_to_lower(txt)
  NY_AWARD_POSTED[vapply(NY_AWARD_POSTED,
                         function(p) stringr::str_detect(low,
                                                         stringr::fixed(p)),
                         logical(1))]
}

#' New York has named no RCHI grantee on any watched surface
ny_assert_no_roster <- function(bodies = NULL) {
  found <- ny_award_language(
    ny_html_text("programme",
                 if (!is.null(bodies)) bodies[["programme"]] else NULL))
  if (length(found)) {
    stop("[NY] award language has appeared on the programme page: ",
         paste(sQuote(found), collapse = ", "),
         ". New York may have published a roster. This file must be REWRITTEN ",
         "as an award extractor, not patched -- ny_year1_status.csv has no ",
         "amount column by design.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The RCHI contract start date has passed and no grantee is named
#'
#' RE-DERIVED AGAINST Sys.Date() EVERY RUN, and read out of the archived
#' guidance rather than typed, so a re-issued guidance that moves the date
#' moves the finding with it.
ny_assert_contract_start_passed <- function(today = Sys.Date(), body = NULL) {
  txt <- stringr::str_replace_all(ny_pdf_text("rchi_guidance", body),
                                  "\\s+", " ")
  want <- paste("Contracts for funded grantees will begin on September 1 2026",
                "and end on June 30 2027")
  # The reader drops commas from this producer's text, so match on the
  # letters-and-digits skeleton rather than on punctuation.
  skel <- function(x) stringr::str_replace_all(
    stringr::str_to_lower(x), "[^a-z0-9]", "")
  if (!stringr::str_detect(skel(txt), stringr::fixed(skel(want)))) {
    stop("[NY] the RCHI guidance no longer carries its own contract-start ",
         "sentence. The date this finding is measured against has moved; ",
         "re-read the guidance.", call. = FALSE)
  }
  if (NY_CONTRACT_START >= today) {
    message("[NY] the RCHI contract start (", NY_CONTRACT_START,
            ") has not passed yet; the negative is not yet overdue.")
  }
  invisible(NY_CONTRACT_START < today)
}

#' RCHI is oversubscribed two to one and DOH says the reviews are unfinished
ny_assert_reviews_in_progress <- function(body = NULL) {
  txt <- stringr::str_replace_all(ny_pdf_text("update_aug12", body),
                                  "\\s+", " ")
  want <- c("91 Applications", "156,000,000",
            "Reviews and Funding Recommendation In Progress")
  missing <- want[!vapply(want,
                          function(w) stringr::str_detect(txt,
                                                          stringr::fixed(w)),
                          logical(1))]
  if (length(missing)) {
    stop("[NY] DOH's 2026-08-12 update no longer says: ",
         paste(sQuote(missing), collapse = ", "),
         ". If the reviews have concluded, New York may have awarded -- read ",
         "the deck.", call. = FALSE)
  }
  invisible(TRUE)
}

#' A hospital is REQUIRED in every RCHI partnership, and is not the recipient
#'
#' The sentence that decides how every future RCHI row is coded. Losing it
#' must stop the build rather than silently re-code a $76.2M pool.
ny_assert_hospital_required <- function(body = NULL) {
  txt <- stringr::str_replace_all(ny_pdf_text("rchi_guidance", body),
                                  "\\s+", " ")
  want <- c("A hospital must be included as either the lead applicant or the",
            "At least one hospital located in the counties")
  missing <- want[!vapply(want,
                          function(w) stringr::str_detect(txt,
                                                          stringr::fixed(w)),
                          logical(1))]
  if (length(missing)) {
    stop("[NY] the RCHI guidance no longer requires a hospital in every ",
         "partnership: missing ", paste(sQuote(missing), collapse = "; "),
         ". This is the sentence that separates New York's eligible class ",
         "from Illinois's (hospitals ONLY, `Yes`) and New Hampshire's ",
         "(hospitals AMONG OTHERS, `Unclear`). Re-read it before coding any ",
         "New York pass-through.", call. = FALSE)
  }
  # And the lead applicant need NOT be a hospital, which is why this is still
  # a §0.3 question rather than an answer.
  if (!stringr::str_detect(
        txt, stringr::fixed("registered not-for-profit 501(c)(3)"))) {
    stop("[NY] the RCHI guidance no longer allows a non-hospital lead ",
         "applicant. If hospitals are now the only eligible lead, New York ",
         "has become Illinois's case and the coding changes.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- §6.2 and §0.2 -----------------------------------------------------------

#' The CMS footer corroborates the AMOUNT; it is never this pool's figure
#'
#' §0.2, THIS SESSION'S RULE, ON A LIVE EXPOSURE. New York's programme page
#' carries one dollar figure -- "$212,058,207.80 in Budget Period 1" -- on a
#' page whose only recipient-level solicitation is a $76,190,022 pool. The
#' footer's phrasing ("This project is supported by ... in Budget Period 1")
#' reads as though it were scoped to the work described, and it is the
#' ALLOTMENT. Read as RCHI's budget it publishes 2.8x the real pool.
#'
#' The shared rule is driven in both directions: the footer figure declared
#' STATE_ALLOTMENT must pass, and declared SOLICITATION must be refused. RCHI's
#' own $76,190,022 must pass as a genuine pool, which is the check that proves
#' the margin is not simply refusing everything.
ny_assert_footer_is_the_allotment <- function() {
  ok <- rhtp_assert_footer_not_allotment(
    NY_FOOTER, NY_STATE, "STATE_ALLOTMENT",
    label = "NY programme-page CMS footer")
  if (!isTRUE(ok)) {
    message("[NY] the §0.2 tier check did not run -- see above. That is a ",
            "gap in the anchor, not a pass (§0.4).")
    return(invisible(NA))
  }
  refused <- tryCatch({
    rhtp_assert_footer_not_allotment(
      NY_FOOTER, NY_STATE, "SOLICITATION",
      label = "NY footer read as the RCHI pool")
    FALSE
  }, error = function(e) TRUE)
  if (!refused) {
    stop("[NY] the §0.2 rule no longer refuses New York's allotment being ",
         "read as a solicitation pool.", call. = FALSE)
  }
  # The genuine pool is not caught -- the margin discriminates.
  if (!isTRUE(rhtp_assert_footer_not_allotment(
        NY_RCHI_POOL, NY_STATE, "SOLICITATION", label = "NY RCHI pool"))) {
    stop("[NY] the §0.2 rule now refuses RCHI's own $76,190,022 pool, which ",
         "would make it useless. Re-check the margin.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The programme page states its own footer figure
ny_assert_footer_present <- function(body = NULL) {
  txt <- ny_html_text("programme", body)
  if (!stringr::str_detect(txt, stringr::fixed("212,058,207.80"))) {
    stop("[NY] the programme page no longer carries the CMS footer amount.",
         call. = FALSE)
  }
  invisible(TRUE)
}


# -- the positive control ----------------------------------------------------

#' DOH publishes awards in a recognisable form, and none of them is RHTP
#'
#' THE CONTROL THAT MAKES THE NEGATIVE MEAN SOMETHING (California's channel
#' control). Without it, "no RHTP award announcement" is indistinguishable
#' from "DOH does not announce awards on a page we can read".
ny_assert_press_channel_control <- function(body = NULL) {
  txt <- ny_html_text("press_index", body)
  lines <- stringr::str_split(txt, "\n")[[1]]
  award_shaped <- lines[stringr::str_detect(lines, "\\$") &
                        stringr::str_detect(
                          lines, stringr::regex("announce|award|grant",
                                                ignore_case = TRUE))]
  if (length(award_shaped) < 8L) {
    stop("[NY] DOH's 2026 press index carries only ", length(award_shaped),
         " award-shaped headlines. The control that makes New York's silence ",
         "meaningful is gone; re-establish it before reporting the negative.",
         call. = FALSE)
  }
  rhtp <- lines[stringr::str_detect(lines, "Rural Health Transformation")]
  if (!length(rhtp)) {
    stop("[NY] 'Rural Health Transformation' has vanished from DOH's 2026 ",
         "press index, so the index no longer controls this finding.",
         call. = FALSE)
  }
  awardish <- rhtp[stringr::str_detect(
    rhtp, stringr::regex("award|recipient|grantee", ignore_case = TRUE))]
  if (length(awardish)) {
    stop("[NY] an RHTP press item on DOH's index now reads as an AWARD: ",
         paste(sQuote(awardish), collapse = "; "),
         ". Read it -- New York may have published a roster.", call. = FALSE)
  }
  invisible(list(award_shaped = length(award_shaped), rhtp = length(rhtp)))
}

#' The Contract Reporter is unreadable, and that is about US (§0.4)
ny_assert_scr_unreadable <- function(body = NULL) {
  txt <- ny_html_text("scr", body)
  if (!stringr::str_detect(txt, stringr::fixed("Contract Reporter"))) {
    stop("[NY] the archived Contract Reporter page is not what it was.",
         call. = FALSE)
  }
  if (!stringr::str_detect(txt, stringr::regex("Create (an )?Account|Log In",
                                               ignore_case = TRUE))) {
    message("[NY] the Contract Reporter may no longer require an account. If ",
            "its search is now open, it becomes a readable channel and the ",
            "UNKNOWN row in ny_year1_status.csv must be revisited.")
  }
  invisible(TRUE)
}


# -- the status table --------------------------------------------------------

ny_status_table <- function() {
  tibble::tribble(
    ~state, ~channel, ~stage, ~publishes_roster, ~award_date_published, ~note,
    NY_STATE, "Rural Community Health Integration (RCHI)",
    "CLOSED_AWARD_DATE_PASSED", "No", "2026-09-01",
    paste("$76,190,022 for Budget Period 1. Released 2026-06-11, applications",
          "due 2026-07-09 (the 2026-08-12 deck says 2026-07-14; both are the",
          "state's own and neither is resolved, §8). Its guidance says",
          "'Contracts for funded grantees will begin on September 1, 2026'",
          "and 'All contracts must be executed by October 30, 2026'. THE",
          "START DATE HAS PASSED and no grantee is named. DOH's own deck says",
          "'Reviews and Funding Recommendation In Progress' against 91",
          "applications and $156,000,000 of requests. THE POOL TO WATCH, and",
          "read its eligible class before coding: A HOSPITAL IS REQUIRED in",
          "every partnership but need not be the recipient."),
    NY_STATE, "Strengthening Rural Communities with Technology - Enhanced Primary Care",
    "NO_SOLICITATION_PUBLISHED", "No", NA_character_,
    "An initiative in the CMS application. No funding opportunity published.",
    NY_STATE, "Rural Roots: Building a Sustainable Rural Healthcare Workforce",
    "NO_SOLICITATION_PUBLISHED", "No", NA_character_,
    "An initiative in the CMS application. No funding opportunity published.",
    NY_STATE, "Initiative 4: Technology Innovation and Cybersecurity",
    "PRE_SOLICITATION", "No", NA_character_,
    paste("DOH held a Cybersecurity Resilience webinar on 2026-08-17 and",
          "publishes an 'Interest Form'. An interest form is not a",
          "solicitation and a webinar is not an award."),
    NY_STATE, "NYS DOH press releases (channel control)",
    "PUBLISHES_AWARDS_FOR_OTHER_PROGRAMMES", "Yes - FOR OTHER PROGRAMMES",
    NA_character_,
    paste("THE POSITIVE CONTROL. Fifteen award announcements in 2026 naming",
          "programmes and amounts. 'Rural Health Transformation' occurs",
          "EXACTLY ONCE and it is a funding OPPORTUNITY announcement, not an",
          "award."),
    NY_STATE, "NYS Contract Reporter (nyscr.ny.gov)",
    "UNREADABLE", "UNKNOWN", NA_character_,
    paste("New York routes contracting here. It answers 200 and is a stateful",
          "search application behind a free account, so whether an RHTP",
          "contract has been executed inside it is a statement about OUR",
          "ACCESS, never about New York (§0.4). Maine's CGI Advantage,",
          "Connecticut's CTsource and Louisiana's rhtla.net precedent.")
  )
}

ny_disposition <- function() {
  rt <- readRDS(here::here("data", "interim", "stage2_record_table.rds"))
  ny <- rt %>% dplyr::filter(.data$state == NY_STATE)
  n_t3 <- sum(ny$award_tier == "SUBAWARD")
  tibble::tribble(
    ~state, ~group, ~rcj_rows, ~disposition, ~evidence,
    NY_STATE, "Tier 3 (SUBAWARD) candidates", n_t3,
    "NO_TIER_3_SIGNAL_AT_ALL",
    paste0("New York is one of TWELVE states carrying NO RCJ Tier 3 ",
           "candidate. It holds ", nrow(ny), " RCJ records in total -- the ",
           "fewest of any state investigated so far -- all SOLICITATION, ",
           "STATE_ALLOTMENT or UNASSIGNED. NOT ONE is a subaward, and that ",
           "is correct: New York has awarded nobody publicly. A zero here is ",
           "a fact about the DISCOVERY LAYER and never about the state ",
           "(§0.1); Florida had 81 awards and no candidate either.")
  )
}


# -- the live probe ----------------------------------------------------------

ny_probe <- function() {
  keys <- c("programme", "press_index", "scr")
  live <- purrr::map(keys, function(k) ny_get(ny_source(k, "url"), k))
  names(live) <- keys
  Sys.sleep(1)

  cmp <- purrr::map_dfr(keys, function(k) {
    tibble::tibble(
      key = k,
      archived_content = ny_content_digest(k),
      live_content = ny_content_digest(k, live[[k]]),
      archived_file = digest::digest(file = ny_path(k), algo = "sha256"),
      live_file = digest::digest(live[[k]], algo = "sha256", serialize = FALSE))
  }) %>%
    dplyr::mutate(content_changed = .data$archived_content != .data$live_content,
                  file_changed = .data$archived_file != .data$live_file)

  ny_assert_no_roster(bodies = live)
  ny_assert_footer_present(body = live$programme)
  ny_assert_press_channel_control(body = live$press_index)
  ny_assert_scr_unreadable(body = live$scr)

  message("[NY] live probe ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " UTC")
  purrr::walk(seq_len(nrow(cmp)), function(i) {
    r <- cmp[i, ]
    message(sprintf("  %-12s content %s   file %s", r$key,
                    if (r$content_changed) "CHANGED" else "unchanged",
                    if (r$file_changed) "differs" else "unchanged"))
  })
  if (any(cmp$content_changed)) {
    message("[NY] CONTENT CHANGED on: ",
            paste(cmp$key[cmp$content_changed], collapse = ", "),
            ". Re-fetch and read before trusting ny_year1_status.csv.")
  } else {
    message("[NY] UNCHANGED. New York has still named no grantee.")
  }
  message("[NY] RCHI contracts were due to begin ", NY_CONTRACT_START,
          " -- ", as.integer(Sys.Date() - NY_CONTRACT_START),
          " day(s) ago, with no roster.")
  invisible(cmp)
}


# -- validate / build / report -----------------------------------------------

ny_validate <- function() {
  if (!ny_have_archive()) {
    stop("[NY] the evidence archive is incomplete; run --fetch first.",
         call. = FALSE)
  }
  ny_assert_no_roster()
  ny_assert_contract_start_passed()
  ny_assert_reviews_in_progress()
  ny_assert_hospital_required()
  ny_assert_footer_present()
  ny_assert_footer_is_the_allotment()
  ny_assert_press_channel_control()
  ny_assert_scr_unreadable()
  message("[NY] all assertions pass.")
  invisible(TRUE)
}

ny_build <- function() {
  st <- ny_status_table()
  if ("amount" %in% names(st)) {
    stop("[NY] ny_year1_status.csv must have NO amount column.", call. = FALSE)
  }
  readr::write_csv(st, NY_STATUS_CSV)
  message("[NY] wrote ", NY_STATUS_CSV, " (", nrow(st), " rows)")
  d <- ny_disposition()
  readr::write_csv(d, NY_DISPO_CSV)
  message("[NY] wrote ", NY_DISPO_CSV, " (", nrow(d), " rows)")
  invisible(list(status = st, disposition = d))
}

ny_report <- function() {
  st <- ny_status_table()
  cat("\nNEW YORK -- a NEGATIVE whose contracts were due to BEGIN yesterday\n")
  cat(strrep("=", 68), "\n\n")
  cat("Allotment (§7.1)       : $", format(NY_ALLOTMENT, big.mark = ","),
      "\n", sep = "")
  cat("RCHI Budget Period 1   : $", format(NY_RCHI_POOL, big.mark = ","),
      " (", round(100 * NY_RCHI_POOL / NY_ALLOTMENT, 1), "% of allotment)\n",
      sep = "")
  cat("Recipient-level awards : NONE PUBLISHED\n")
  cat("RCJ Tier 3 candidates  : 0 -- no signal on either discovery layer\n\n")
  print(as.data.frame(st[, c("channel", "stage", "publishes_roster")]),
        row.names = FALSE)
  cat("\nTHE DATE: contracts 'will begin on September 1, 2026'. Today is ",
      format(Sys.Date()), ".\n", sep = "")
  cat("DOH's own deck: 91 applications, $156,000,000 requested,\n")
  cat("                'Reviews and Funding Recommendation In Progress'.\n")
  cat("\nTHE ELIGIBLE CLASS IS NEW: a hospital is REQUIRED in every RCHI\n")
  cat("partnership but need NOT be the recipient -- neither Illinois's\n")
  cat("'hospitals only' nor New Hampshire's 'hospitals among others'.\n")
  invisible(st)
}


if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) ny_fetch(force = "--force" %in% args)
  if ("--validate" %in% args) ny_validate()
  if ("--build" %in% args) ny_build()
  if ("--probe" %in% args) ny_probe()
  if ("--report" %in% args) ny_report()
  if (!length(args)) {
    message("Usage: --fetch [--force] | --validate | --build | --probe | --report")
  }
}
