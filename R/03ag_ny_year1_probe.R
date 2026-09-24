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
source(here::here("R", "utils_recipient_classification.R"))

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
  "2026-09-22_ny_transforming_rural_healthcare.html",
  paste("DOH's RHTP programme page, RE-BASED session 52 after it was READ:",
        "it now links 'Rural Community Health Integration Awardees List' and",
        "the Governor's 2026-09-04 release. The name tripwire's baseline."),
  "programme_prior",
  NA_character_,
  "2026-09-02_ny_transforming_rural_healthcare.html",
  paste("The 2026-09-02 copy, KEPT (Louisiana's precedent): the only evidence",
        "of what the page said before New York awarded. Never re-fetched."),
  "roster",
  "https://www.health.ny.gov/facilities/transforming_rural_healthcare/awardees.htm",
  "2026-09-22_ny_rchi_awardees_list.html",
  paste("THE ROSTER. 'Rural Community Health Integration Awardees List':",
        "56 rows of Lead Applicant Name | Counties | Total Dollar Award",
        "Amount, summing to $76,190,022.00. Found live by session 51."),
  "gov_release",
  paste0("https://www.governor.ny.gov/news/governor-hochul-announces-76-",
         "million-strengthen-rural-healthcare-across-new-york-state"),
  "2026-09-22_ny_governor_rchi_awards_release.html",
  paste("The Governor's 2026-09-04 release: '90 awards to 56 organizations',",
        "$22.7M planning / $53.5M implementation, and the CMS footer."),
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
    if (is.na(src$url)) {
      # A superseded snapshot. It is evidence of what the page USED to say, so
      # it is never re-fetched -- a --force would overwrite it with today.
      if (!file.exists(dest)) stop("[NY] the kept snapshot ", src$file,
                                   " is missing.", call. = FALSE)
      message("[NY] kept ", src$file)
    } else if (file.exists(dest) && !force) {
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
    "Fetched 2026-09-02 by R/03ag_ny_year1_probe.R --fetch; the roster, the",
    "Governor's release and the re-based programme page were found live by",
    "session 51 on 2026-09-22 (data/evidence/recheck/2026-09-22/NY/) and",
    "copied here byte for byte by session 52.",
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
    "AWARDED_ROSTER_PUBLISHED", "Yes", "2026-09-04",
    paste("AWARDED 2026-09-04 (session 52 extracted it): the Governor's release",
          "says '90 awards to 56 organizations' and DOH's 'Rural Community",
          "Health Integration Awardees List' prices 56 lead-applicant rows to",
          "$76,190,022.00 exactly -- see ny_year1_awardees.csv. THE HISTORY:",
          "$76,190,022 for Budget Period 1. Released 2026-06-11, applications",
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
  rt <- rhtp_record_table_live()
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
  keys <- c("programme", "roster", "press_index", "scr")
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

  # NEW YORK HAS AWARDED (session 52), so the probe watches the ROSTER: the
  # same 56 priced rows summing to the pool. A 57th lead, a moved figure or a
  # renamed organisation fails here, and the name tripwire below catches a new
  # name on either page whatever the wording.
  ny_assert_roster(ny_parse_roster(live$roster))
  ny_assert_roster_linked(body = live$programme)
  ny_assert_footer_present(body = live$programme)
  ny_assert_press_channel_control(body = live$press_index)
  ny_assert_scr_unreadable(body = live$scr)

  # THE NAME TRIPWIRE (§2.3, session 48). The phrase assertions above ask HOW
  # this page is worded; this asks WHOM it names, against the committed
  # archive. New Mexico is why it exists: HCA named six Regional Hubs and not
  # one of its ten award phrases matched. Subject pages only -- a control or a
  # press index moves for reasons that are not this state awarding.
  nm_keys <- c("programme", "roster")
  rhtp_assert_no_new_organisations_across(
    live = stats::setNames(
      purrr::map(nm_keys, function(k) ny_html_text(k, live[[k]])), nm_keys),
    archived = stats::setNames(purrr::map(nm_keys, ny_html_text), nm_keys),
    state = "NY")

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
            ". The roster assertions and the name tripwire passed; read the ",
            "change before trusting ny_year1_awardees.csv.")
  } else {
    message("[NY] UNCHANGED. The RCHI roster is the 56 rows already extracted.")
  }
  message("[NY] contracts must be executed by 2026-10-30; the other three ",
          "initiatives ($122.5M) have named nobody.")
  invisible(cmp)
}


# -- THE AWARD EXTRACTION (session 52) ----------------------------------------
#
# NEW YORK AWARDED ON 2026-09-04 AND THIS REPOSITORY DID NOT KNOW FOR EIGHTEEN
# DAYS. The Governor's release says "90 awards to 56 organizations" and DOH's
# "Rural Community Health Integration Awardees List" prices every lead
# applicant. The Routine watching this page fired five times after that; the
# phrase list above did not contain "Awardees List" (§2.3's lesson again), and
# the verdicts it did print never reached `main` (§0.5; R/probe_coverage.R).
#
# READ THE GRAIN BEFORE THE MONEY. The roster is ONE ROW PER LEAD APPLICANT,
# 56 rows, 55 distinct names (Ellenville Regional Hospital is printed twice),
# and each row is the lead's TOTAL ("Total Dollar Award Amount"). The release
# counts 90 AWARDS -- so a row may be a planning and an implementation award
# together, and DOH publishes no per-award split ($22.7M planning, $53.5M
# implementation, in aggregate only). Michigan's grain lesson: this file is
# 56 rows because New York publishes 56 prices, and it never pretends to 90.
#
# AND READ §7's THIRD ELIGIBLE CLASS BEFORE THE CODING. RCHI requires "A
# hospital must be included as either the lead applicant or the partner
# Organization", and the roster names ONLY THE LEAD. So, one award at a time:
#   * the lead IS a hospital       -> DIRECT, Yes, NAMED_HOSPITAL (ordinary §10.2)
#   * the lead is NOT a hospital   -> PASS_THROUGH_UNRESOLVED, Unclear. The
#     partner hospital's presence is a fact about the APPLICATION; nothing on
#     either document says a dollar reaches it. A required partner is not a
#     recipient.
# The eligibility sentence is never the coding. A session that took it as one
# would publish all $76,190,022 as hospital money.

NY_ROSTER_ROWS   <- 56L
NY_ROSTER_NAMES  <- 55L
NY_RELEASE_DATE  <- as.Date("2026-09-04")
NY_RCHI_AWARDS   <- 90L
NY_NOA_DATE      <- as.Date("2025-12-29")   # cms_state_noa_dates.csv
NY_CMS_ENROLMENT_DIR <- here::here("data", "evidence", "federal_records",
                                   "2026-09-22")

# THE TYPING, ONE ROW PER ORGANISATION, HAND-READ. The roster states no form.
# `ORG_WEBSITE`/MEDIUM = CMS's own Hospital, CAH, REH or FQHC enrolment file
# (archived under data/evidence/federal_records/2026-09-22/, cms_*_NY.json)
# carries the roster's string EXACTLY as an ORGANIZATION NAME or DBA, and the
# CCN is recorded. `GENERAL_KNOWLEDGE`/LOW = a HAND-READ BRIDGE from the
# roster's string to a CMS record whose name differs; each says why, so a
# reader can subtract them (session 49's rule). The rest are REFUSED and keep
# §8's standing fallback. §7 reserves HIGH for a CCN match made by Stage 5;
# nothing here claims it.
NY_LEAD_TYPES <- tibble::tribble(
  ~awardee, ~recipient_type, ~basis_type, ~ccn, ~cms_type, ~evidence,
  # -- EXACT CMS enrolment matches: hospitals ---------------------------------
  "Alice Hyde Medical Center", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "331321", "CAH", "CMS ORGANIZATION NAME, Malone",
  "Canton-Potsdam Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "330197", "HOSPITAL", "CMS ORGANIZATION NAME, Potsdam",
  "Clifton Springs Hospital & Clinic", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "330265", "HOSPITAL", "CMS DBA 'CLIFTON SPRINGS HOSPITAL AND CLINIC'",
  "Columbia Memorial Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "330094", "HOSPITAL", "CMS ORGANIZATION NAME, Hudson",
  "Community Memorial Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "331316", "CAH", "CMS ORGANIZATION NAME, Hamilton (Madison County, an award county)",
  "Elizabethtown Community Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "331302", "CAH", "CMS ORGANIZATION NAME, Elizabethtown",
  "Ellenville Regional Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "331310", "CAH", "CMS DBA, Ellenville",
  "Geneva General Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "330058", "HOSPITAL", "CMS ORGANIZATION NAME, Geneva",
  "Glens Falls Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "330191", "HOSPITAL", "CMS ORGANIZATION NAME, Glens Falls",
  "Guthrie Cortland Medical Center", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "330175", "HOSPITAL", "CMS ORGANIZATION NAME, Cortland",
  "Jones Memorial Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "330096", "HOSPITAL", "CMS DBA, Wellsville",
  "Lewis County General Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "331317", "CAH", "CMS ORGANIZATION NAME, Lowville",
  "Margaretville Memorial Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "331304", "CAH", "CMS ORGANIZATION NAME, Margaretville",
  "Montefiore St. Luke's Cornwall", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "330264", "HOSPITAL", "CMS DBA, Newburgh",
  "Nathan Littauer Hospital and Nursing Home", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "330276", "HOSPITAL", "CMS DBA, Gloversville",
  "Newark-Wayne Community Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "330030", "HOSPITAL", "CMS ORGANIZATION NAME, Newark",
  "Northern Dutchess Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "330049", "HOSPITAL", "CMS ORGANIZATION NAME, Rhinebeck",
  "Oneida Health", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "330115", "HOSPITAL", "CMS DBA 'ONEIDA HEALTH', Oneida -- the shared classifier alone falls to the fallback on this name",
  "Oswego Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "330218", "HOSPITAL", "CMS ORGANIZATION NAME, Oswego",
  "Rome Memorial Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "330215", "HOSPITAL", "CMS ORGANIZATION NAME, Rome",
  "Soldiers and Sailors Memorial Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "331314", "CAH", "CMS ORGANIZATION NAME 'SOLDIERS & SAILORS MEMORIAL HOSPITAL', Penn Yan",
  "St. James Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "330151", "HOSPITAL", "CMS ORGANIZATION NAME 'ST JAMES HOSPITAL', Hornell",
  "St. Mary's Healthcare", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "330047", "HOSPITAL", "CMS ORGANIZATION NAME, Amsterdam",
  "United Memorial Medical Center", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "330073", "HOSPITAL", "CMS ORGANIZATION NAME, Batavia",
  "Westfield Memorial Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "330801", "REH", "CMS ORGANIZATION NAME, Westfield -- enrolled as a RURAL EMERGENCY HOSPITAL",
  # -- EXACT CMS enrolment matches: FQHCs --------------------------------------
  "East Hill Family Medical", "FQHC_OR_RHC", "ORG_WEBSITE", "331007", "FQHC", "CMS FQHC ORGANIZATION NAME, Auburn",
  "Institute for Family Health", "FQHC_OR_RHC", "ORG_WEBSITE", "331012", "FQHC", "CMS FQHC ORGANIZATION NAME 'THE INSTITUTE FOR FAMILY HEALTH'",
  "ODA Primary Health Care Network", "FQHC_OR_RHC", "ORG_WEBSITE", "331042", "FQHC", "CMS FQHC ORGANIZATION NAME; sites include Woodridge (Sullivan, the award county)",
  "Refuah Health Center", "FQHC_OR_RHC", "ORG_WEBSITE", "331050", "FQHC", "CMS FQHC ORGANIZATION NAME; sites include South Fallsburg (Sullivan)",
  "Sun River Health", "FQHC_OR_RHC", "ORG_WEBSITE", "331000", "FQHC", "CMS FQHC ORGANIZATION NAME 'SUN RIVER HEALTH INC.'",
  "The Chautauqua Center", "FQHC_OR_RHC", "ORG_WEBSITE", "571147", "FQHC", "CMS FQHC ORGANIZATION NAME, Dunkirk",
  # -- HAND-READ BRIDGES (LOW; subtractable) ------------------------------------
  "Adirondack Health", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "330079", "HOSPITAL", "BRIDGE: Adirondack Health is the system whose hospital CMS enrols as ADIRONDACK MEDICAL CENTER, Saranac Lake -- in Franklin County, this row's only county",
  "Bassett Medical Center", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "330136", "HOSPITAL", "BRIDGE: CMS enrols MARY IMOGENE BASSETT HOSPITAL, Cooperstown (Otsego, an award county) with the DBA misspelt 'BASSET MEDICAL CENTER' -- one letter, CMS's typo not the roster's",
  "Cayuga Medical Center", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "330307", "HOSPITAL", "BRIDGE: CMS 'CAYUGA MEDICAL CENTER AT ITHACA' (Tompkins, an award county); the roster drops 'at Ithaca'",
  "Champlain Valley Physicians Hospital", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "330250", "HOSPITAL", "BRIDGE: CMS 'CHAMPLAIN VALLEY PHYSICIANS HOSPITAL MEDICAL CENTER', Plattsburgh (Clinton, an award county); the roster's string is its prefix",
  "F.F. Thompson Hospital", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "330074", "HOSPITAL", "BRIDGE: CMS 'THE FREDERICK FERRIS THOMPSON HOSPITAL', Canandaigua (Ontario, this row's county); F.F. are its initials",
  "HealthAlliance of the Hudson Valley", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "330224", "HOSPITAL", "BRIDGE: CMS 'HEALTHALLIANCE HOSPITAL MARYS AVENUE CAMPUS', Kingston (Ulster, this row's county)",
  "Mohawk Valley Health System", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "330044", "HOSPITAL", "BRIDGE: CMS 'MVHS INC' dba WYNN HOSPITAL, Utica (Oneida, an award county). TRAP REFUSED: a stem match on 'Mohawk Valley' also finds the NYS Office of Mental Health's MOHAWK VALLEY PSYCHIATRIC CENTER, a state agency",
  "Nicholas Noyes Hospital", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "330238", "HOSPITAL", "BRIDGE: CMS 'NICHOLAS H NOYES MEMORIAL HOSPITAL', Dansville (Livingston, this row's county)",
  "Putnam Hospital", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "330273", "HOSPITAL", "BRIDGE: CMS 'PUTNAM HOSPITAL CENTER', Carmel (Putnam, an award county). TRAP REFUSED: HUDSON VALLEY REGIONAL COMMUNITY HEALTH CENTERS -PUTNAM is an FQHC and is not the string",
  "Hudson Headwaters", "FQHC_OR_RHC", "GENERAL_KNOWLEDGE", "331026", "FQHC", "BRIDGE: CMS FQHC 'HUDSON HEADWATERS HEALTH NETWORK', Warren County sites; the roster drops 'Health Network'",
  # -- THE NAME STATES THE FORM --------------------------------------------------
  "Western New York Rural Area Health Education Center", "AHEC", "STATE_SOURCE", NA, NA, "The roster's own string names an Area Health Education Center",
  "Greenport Rescue Squad", "EMS_OR_PSAP", "STATE_SOURCE", NA, NA, "The roster's own string names a rescue squad, an EMS agency"
)

# REFUSED: no CMS enrolment carries the string and none is bridgeable without
# guessing. §8's standing fallback, flag RECIPIENT_TYPE_INFERRED. None can be
# a hospital row either way -- a non-hospital lead is Unclear under §7's third
# class whatever its form -- so the refusals move NO dollar. Southern Tier
# Health Care System is NOT "Southern Tier Community Health Center Network", an
# FQHC in the same county; a stem match would have typed it, and §2 forbids
# that.
NY_LEAD_REFUSED <- c(
  "Care Compass Collaborative", "Chautauqua Health Network",
  "Chenango Health Network", "Coordinated Behavioral Health Services",
  "Fort Drum Regional Health Planning Org", "Healthy Alliance Foundation",
  "Madison County Rural Health Council", "Pivital Public Health Partnership",
  "Southern Tier Health Care System",
  "The Family Counseling Center of Fulton County",
  "Trustees of the Masonic Hall & Asylum Fund", "Upstate Caring Partners")

#' Parse the roster: one row per LEAD APPLICANT, as printed
ny_parse_roster <- function(body = NULL) {
  raw <- if (is.null(body)) readBin(ny_path("roster"), "raw",
                                    file.size(ny_path("roster"))) else body
  doc <- xml2::read_html(raw)
  rows <- xml2::xml_find_all(doc, "//table//tr")
  cells <- purrr::map(rows, function(r) {
    stringr::str_squish(xml2::xml_text(xml2::xml_find_all(r, "./td|./th")))
  })
  hdr <- purrr::detect(cells, function(c) any(grepl("Lead Applicant", c)))
  if (is.null(hdr) || !identical(hdr, c("Lead Applicant Name",
                                        "Counties (separated by spaces)",
                                        "Total Dollar Award Amount"))) {
    stop("[NY] the roster's header is not the three columns it was: ",
         paste(sQuote(hdr), collapse = " | "),
         ". Re-read the page before trusting a positional parse.",
         call. = FALSE)
  }
  body_rows <- purrr::keep(cells, function(c) {
    length(c) == 3L && grepl("^[0-9,]+\\.[0-9]{2}$", c[3])
  })
  tibble::tibble(
    roster_row = seq_along(body_rows),
    awardee = purrr::map_chr(body_rows, 1L),
    counties = purrr::map_chr(body_rows, 2L),
    amount = as.numeric(gsub(",", "", purrr::map_chr(body_rows, 3L))))
}

#' The roster is what it was: 56 lead rows, 55 names, exactly the RCHI pool
ny_assert_roster <- function(roster = ny_parse_roster()) {
  if (nrow(roster) != NY_ROSTER_ROWS) {
    stop("[NY] the RCHI roster carries ", nrow(roster), " priced rows, not ",
         NY_ROSTER_ROWS, ". New York has changed it -- re-read before ",
         "rebuilding.", call. = FALSE)
  }
  if (dplyr::n_distinct(roster$awardee) != NY_ROSTER_NAMES) {
    stop("[NY] the roster now carries ", dplyr::n_distinct(roster$awardee),
         " distinct names, not ", NY_ROSTER_NAMES, ".", call. = FALSE)
  }
  # EXACT TO THE CENT. all.equal()'s relative tolerance (1.5e-8) would let a
  # $1 change on a $76M pool through -- caught by this file's own test.
  if (round(sum(roster$amount), 2) != NY_RCHI_POOL) {
    stop("[NY] the roster sums to $", format(sum(roster$amount), nsmall = 2,
                                             big.mark = ","),
         ", not RCHI's $76,190,022 allocation.", call. = FALSE)
  }
  ell <- roster$amount[roster$awardee == "Ellenville Regional Hospital"]
  if (!identical(sort(ell), c(500000, 3000000))) {
    stop("[NY] Ellenville Regional Hospital no longer holds its two printed ",
         "rows ($3,000,000 and $500,000).", call. = FALSE)
  }
  # Every lead is typed or refused, by hand -- a new name is a new organisation
  # and must be read, never classified by default.
  typed <- c(NY_LEAD_TYPES$awardee, NY_LEAD_REFUSED)
  unknown <- setdiff(unique(roster$awardee), typed)
  if (length(unknown)) {
    stop("[NY] the roster names lead(s) nobody has read: ",
         paste(sQuote(unknown), collapse = ", "), call. = FALSE)
  }
  stale <- setdiff(typed, roster$awardee)
  if (length(stale)) {
    stop("[NY] typed lead(s) no longer on the roster: ",
         paste(sQuote(stale), collapse = ", "), call. = FALSE)
  }
  if (anyDuplicated(typed)) {
    stop("[NY] a lead is both typed and refused.", call. = FALSE)
  }
  invisible(roster)
}

#' The typing's CMS half is reproducible from the archived federal records
#'
#' Every ORG_WEBSITE row's CCN must be in the archived NY enrolment slice, with
#' the provider type recorded, so the typing rests on committed bytes (§0.5)
#' and not on a live API.
ny_assert_cms_typing <- function() {
  read <- function(k) jsonlite::fromJSON(
    file.path(NY_CMS_ENROLMENT_DIR, paste0("cms_", k, "_enrollments_NY.json")))
  enr <- dplyr::bind_rows(read("hosp"), read("fqhc"), read("rhc"))
  cms <- NY_LEAD_TYPES[!is.na(NY_LEAD_TYPES$ccn), ]
  miss <- setdiff(cms$ccn, enr$CCN)
  if (length(miss)) {
    stop("[NY] CCN(s) not in the archived CMS enrolment slice: ",
         paste(miss, collapse = ", "), call. = FALSE)
  }
  norm <- function(x) stringr::str_squish(gsub(
    "\\b(INC|THE)\\b|[^A-Z0-9 ]", " ",
    gsub("&", " AND ", toupper(gsub("['’.]", "", x)))))
  ex <- cms[cms$basis_type == "ORG_WEBSITE", ]
  for (i in seq_len(nrow(ex))) {
    e <- enr[enr$CCN == ex$ccn[i], ]
    names_here <- norm(c(e$`ORGANIZATION NAME`, e$`DOING BUSINESS AS NAME`))
    if (!norm(ex$awardee[i]) %in% names_here) {
      stop("[NY] '", ex$awardee[i], "' is typed ORG_WEBSITE but CCN ",
           ex$ccn[i], " does not carry that name. It is a BRIDGE and must be ",
           "GENERAL_KNOWLEDGE/LOW.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' §6.2: the release ties the roster to RHTP, and postdates the NOA
ny_assert_release_provenance <- function(body = NULL) {
  txt <- stringr::str_squish(ny_html_text("gov_release", body))
  want <- c("90 awards to 56 organizations",
            "Rural Community Health Integration Initiative",
            "federal Rural Health Transformation Program",
            "approximately $22.7 million for planning awards and $53.5 million for implementation awards",
            "with 100 percent funded by CMS/HHS",
            "September 4, 2026")
  miss <- want[!vapply(want, function(w) grepl(w, txt, fixed = TRUE),
                       logical(1))]
  if (length(miss)) {
    stop("[NY] the Governor's release no longer says: ",
         paste(sQuote(miss), collapse = "; "), call. = FALSE)
  }
  if (!(NY_RELEASE_DATE > NY_NOA_DATE)) {
    stop("[NY] the release does not postdate the NOA.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The programme page links the roster -- and names it as RCHI's
ny_assert_roster_linked <- function(body = NULL) {
  txt <- ny_html_text("programme", body)
  if (!grepl("Rural Community Health Integration Awardees List", txt,
             fixed = TRUE)) {
    stop("[NY] the programme page no longer links the RCHI Awardees List.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' The eligibility sentence is NOT the coding: a guard with a counterfactual
#'
#' Coding every lead Yes because "a hospital must be included" would publish
#' the whole pool as hospital money. This asserts the non-hospital leads are
#' held out, and says what the mistake would cost.
ny_assert_participation_not_receipt <- function(rows = ny_award_rows()) {
  nonhosp <- rows[rows$recipient_type != "HOSPITAL_OR_SYSTEM", ]
  if (any(nonhosp$distributed_to_hospital != "Unclear")) {
    stop("[NY] a non-hospital RCHI lead is coded other than Unclear.",
         call. = FALSE)
  }
  if (any(nonhosp$flow_type != "PASS_THROUGH_UNRESOLVED")) {
    stop("[NY] a non-hospital RCHI lead is not PASS_THROUGH_UNRESOLVED.",
         call. = FALSE)
  }
  hosp <- rows[rows$recipient_type == "HOSPITAL_OR_SYSTEM", ]
  if (any(hosp$distributed_to_hospital != "Yes" | hosp$flow_type != "DIRECT")) {
    stop("[NY] a hospital lead is not DIRECT/Yes.", call. = FALSE)
  }
  invisible(list(hospital = sum(hosp$amount), held_out = sum(nonhosp$amount)))
}

ny_award_rows <- function(roster = ny_assert_roster()) {
  types <- dplyr::bind_rows(
    NY_LEAD_TYPES,
    tibble::tibble(awardee = NY_LEAD_REFUSED, recipient_type = "NONPROFIT_CBO",
                   basis_type = NA_character_, ccn = NA_character_,
                   cms_type = NA_character_,
                   evidence = paste("REFUSED: no CMS enrolment file carries",
                                    "the string and no bridge is available",
                                    "without guessing (§2).")))
  machine <- rhtp_classify_recipient_type(roster$awardee, NY_STATE)
  r <- roster %>%
    dplyr::left_join(types, by = "awardee") %>%
    dplyr::mutate(
      machine_type = machine$recipient_type,
      machine_conf = machine$determination_confidence,
      hospital = .data$recipient_type == "HOSPITAL_OR_SYSTEM",
      refused = .data$awardee %in% NY_LEAD_REFUSED)

  src <- ny_source("roster", "url")
  tibble::tibble(
    state = NY_STATE,
    row_no = r$roster_row,
    awardee = r$awardee,
    amount = r$amount,
    recipient_type = r$recipient_type,
    distributed_to_hospital = ifelse(r$hospital, "Yes", "Unclear"),
    note = paste0(
      "RCHI lead applicant; counties: ", r$counties, ". ",
      ifelse(r$hospital,
             "The LEAD IS THE HOSPITAL, so §10.2's ordinary DIRECT row applies and the partnership rule adds nothing.",
             "The lead is NOT a hospital. RCHI required a hospital partner, and the roster names only the lead, so a hospital's presence is a fact about the APPLICATION and not about where a dollar went (§7, the third eligible class).")),
    recipient_confirmed = "Yes",
    amount_confirmed = "Yes",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = "Rural Community Health Integration Awardees List",
    state_source_url = src,
    validation_source_type = "NOTICE_OF_AWARD",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03ag_ny_year1_probe.R",
    ccn = r$ccn,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    counties = r$counties,
    award_pool = "Rural Community Health Integration (RCHI)",
    awardee_as_published = r$awardee,
    recipient_type_source = paste0("machine: ", r$machine_type, "/",
                                   r$machine_conf),
    determination_confidence = dplyr::case_when(
      r$refused ~ "LOW",
      r$basis_type == "GENERAL_KNOWLEDGE" ~ "LOW",
      TRUE ~ "MEDIUM"),
    flag_reason = dplyr::case_when(
      r$hospital ~ NA_character_,
      r$refused ~ "ELIGIBILITY_NOT_RECEIPT;RECIPIENT_TYPE_INFERRED",
      TRUE ~ "ELIGIBILITY_NOT_RECEIPT"),
    budget_period = "Budget Period 1",
    flow_type = ifelse(r$hospital, "DIRECT", "PASS_THROUGH_UNRESOLVED"),
    hospital_benefiting = ifelse(r$hospital, "Yes", "Unclear"),
    hospital_attribution = ifelse(r$hospital, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = ifelse(r$hospital, NA_character_, r$awardee),
    determination_basis = paste0(
      ifelse(r$hospital,
             "§10.2 DIRECT: the RCHI lead applicant is itself a hospital. ",
             "§7 third eligible class: the lead is not a hospital and the roster names no partner hospital, so PASS_THROUGH_UNRESOLVED / Unclear -- a required partner is not a recipient. "),
      "Form: ", r$evidence,
      ifelse(is.na(r$basis_type), "", paste0(" [", r$basis_type, "]"))),
    amount_basis = paste(
      "The roster's 'Total Dollar Award Amount' for this LEAD APPLICANT --",
      "the lead's total across its awards (the Governor counts 90 awards to",
      "56 organizations; DOH publishes no per-award or planning/",
      "implementation split). Never divided (§6.2)."),
    round_amount = NA_real_,
    announcement_date = as.character(NY_RELEASE_DATE),
    source_archive_path = file.path("data", "evidence", "NY",
                                    ny_source("roster", "file")),
    basis_type = r$basis_type,
    verified_by = "session 52 (hand-read against CMS enrolment)",
    verified_basis = r$evidence)
}

NY_AWARDS_CSV <- here::here("data", "reference", "ny_year1_awardees.csv")


# -- validate / build / report -----------------------------------------------

ny_validate <- function() {
  if (!ny_have_archive()) {
    stop("[NY] the evidence archive is incomplete; run --fetch first.",
         call. = FALSE)
  }
  ny_assert_roster()
  ny_assert_roster_linked()
  ny_assert_cms_typing()
  ny_assert_release_provenance()
  ny_assert_participation_not_receipt()
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
  aw <- ny_award_rows()
  ny_assert_participation_not_receipt(aw)
  readr::write_csv(aw, NY_AWARDS_CSV, na = "NA")
  message("[NY] wrote ", NY_AWARDS_CSV, " (", nrow(aw), " rows, $",
          format(sum(aw$amount), big.mark = ",", nsmall = 2), ")")
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
  aw <- ny_award_rows()
  h <- aw[aw$distributed_to_hospital == "Yes", ]
  u <- aw[aw$distributed_to_hospital == "Unclear", ]
  cat("\nNEW YORK -- RCHI AWARDED 2026-09-04, extracted session 52\n")
  cat(strrep("=", 68), "\n\n")
  cat("Allotment (§7.1)          : $", format(NY_ALLOTMENT, big.mark = ","), "\n", sep = "")
  cat("RCHI roster               : ", nrow(aw), " lead rows / ",
      dplyr::n_distinct(aw$awardee), " names / $",
      format(sum(aw$amount), big.mark = ",", nsmall = 2),
      " (the Governor: 90 awards to 56 organizations)\n", sep = "")
  cat("Hospital leads (DIRECT)   : ", nrow(h), " rows / $",
      format(sum(h$amount), big.mark = ",", nsmall = 2), "\n", sep = "")
  cat("  of which hand-read bridges (LOW, subtract): ",
      sum(h$basis_type == "GENERAL_KNOWLEDGE", na.rm = TRUE), " rows / $",
      format(sum(h$amount[h$basis_type %in% "GENERAL_KNOWLEDGE"]), big.mark = ",", nsmall = 2),
      "\n", sep = "")
  cat("Non-hospital leads (Unclear, NEITHER bucket): ", nrow(u), " rows / $",
      format(sum(u$amount), big.mark = ",", nsmall = 2), "\n", sep = "")
  cat("\nA hospital was REQUIRED in every partnership; the roster names only\n")
  cat("the lead. Participation is not receipt (§7), so the non-hospital\n")
  cat("leads' dollars are NOT hospital dollars on this document.\n")
  invisible(aw)
}


if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) ny_fetch(force = "--force" %in% args)
  if ("--validate" %in% args) ny_validate()
  if ("--build" %in% args) ny_build()
  if ("--probe" %in% args) rhtp_probe_run("NY", ny_probe())
  if ("--report" %in% args) ny_report()
  if (!length(args)) {
    message("Usage: --fetch [--force] | --validate | --build | --probe | --report")
  }
}
