#!/usr/bin/env Rscript
# 03ak_ms_year1_awardees.R ------------------------------------------------------
#
# MISSISSIPPI -- THE MOST IMMINENT STATE IN THIS REPOSITORY, AND THE FIRST
# WHOSE CMS FOOTER IS NOT 100% FEDERAL.
#
# Mississippi holds $205,907,220 (§7.1) and carries THREE RCJ Tier 3
# candidates, none of them an RHTP subaward (see ms_disposition()). It has
# published NO recipient-level award list -- and unlike every other negative in
# this project, it has SAID IT IS ABOUT TO. `mississippirhtp.com` is a
# DEDICATED RHTP DOMAIN, the third after Kentucky's and Arkansas's, and
# Arkansas's was the one that had already awarded $149M.
#
# THE STATE'S OWN WORDS, ON ITS FUNDING PAGE:
#
#   "The selection process is complete for the Rural Capital Care Gap Closure
#    (RCGC), Rural Technology Grant (RTG), and Telehealth Hub Connectivity,
#    Equipment, and Education (TCE) grant programs. Authorized representatives
#    of selected applicants will be contacted by email this week to begin the
#    sub-award execution process."
#
#   "Governor Tate Reeves will formally announce details regarding all executed
#    sub-awards in the coming weeks."
#
# IT IS SOUTH CAROLINA'S EMAIL SHAPE WITH A PUBLIC ANNOUNCEMENT ATTACHED.
# SCDHHS also notified by email and published nothing further; Mississippi has
# PROMISED a named announcement and named the channel it will use. That makes
# the negative unusually cheap to watch and unusually likely to break: this
# file's job is to notice the day it does.
#
# ============================================================================
# THE FOOTER FINDING, WHICH IS THE REASON THIS FILE EXISTS BEFORE THE ROSTER
# ============================================================================
#
# Every CMS financial-assistance footer this project had ever read was 100%
# federal, so the headline figure and the CMS share were the same number and
# nothing had to tell them apart. MEASURED, not assumed: 222 footer
# occurrences parse out of the committed corpus (186 from HTML and text, 36
# from PDFs) and ALL 222 are 100 percent, with `tier_amount == headline` on
# every one.
#
# MISSISSIPPI'S IS THE FIRST THAT IS NOT:
#
#   "...as part of a financial assistance award totaling $205,990,180.16, with
#    99.96% funded by CMS/HHS ($205,907,220.16) and 0.04% funded by
#    non-government sources ($82,960)."
#
# SO THE FOOTER CARRIES TWO FIGURES AND ONLY THE SMALLER ONE IS THE ALLOTMENT.
# The CMS share matches the §7.1 anchor to within the anchor's own rounding
# ($205,907,220.16 against $205,907,220 -- CMS publishes the allotment whole).
#
# AND THE FOOTER IS INTERNALLY EXACT, WHICH SESSION 43 DID NOT SAY AND WHICH
# MATTERS: headline MINUS CMS share is $82,960.00, and that is the
# non-government figure the footer prints, TO THE CENT. The publisher's three
# numbers close on each other, so the CMS share is a STATED figure whose
# arithmetic checks out, not a reading of ours. (Session 43 recorded the gap
# as $82,960.16. That is the headline against the §7.1 ANCHOR, which carries
# the anchor's own 16 cents of rounding -- a different comparison, also true,
# and not the one that shows the footer is self-consistent.)
#
# Either way the gap is EIGHT TIMES `RHTP_FOOTER_ALLOTMENT_MARGIN`, so, driven
# rather than reasoned about:
#
#   headline  $205,990,180.16  declared STATE_ALLOTMENT -> REFUSED  (correct)
#   headline  $205,990,180.16  declared SOLICITATION    -> ACCEPTED (WRONG)
#   CMS share $205,907,220.16  declared STATE_ALLOTMENT -> ACCEPTED (correct)
#   CMS share $205,907,220.16  declared SOLICITATION    -> REFUSED  (correct)
#
# The second line is the defect. The headline is Tier 1 PLUS A NON-FEDERAL
# MATCH and there is no Tier 2 pool in that sentence at all, so a session that
# fed the headline to the tier check would have it accepted as a solicitation
# pool and would publish $205,990,180.16 as one programme's budget.
#
# THE ANSWER IS TO PARSE THE CMS SHARE, NOT TO WIDEN THE MARGIN. §0.2's own
# rule is that a figure failing this check is a DOCUMENT TO RE-READ, and the
# field to re-read is the PERCENTAGE -- which this project had never had to
# look at because it had always been 100. Widening to $82,960 would also be
# arbitrary: that is ONE STATE'S match amount and the next state's will differ,
# so it buys nothing and costs the check its only signal.
# `rhtp_footer_parse()` / `rhtp_assert_footer_text_tier()` (R/utils_config.R)
# do the parse, and they are INERT on all 222 committed footers.
#
# ============================================================================
# THE CONTROLS
# ============================================================================
#
# THE POSITIVE CONTROL IS THE CHANNEL THE STATE ITSELF NAMED. The promised
# announcement is the GOVERNOR'S, so `governorreeves.ms.gov/newsroom/` is
# where it lands, and that newsroom demonstrably publishes award
# announcements in a recognisable form -- "Gov. Reeves Announces Investment In
# Mental Health Services For Mississippi Youth ... deploying $3,375,709"
# (2026-08-24). So Mississippi's silence is measured against a channel that is
# working, and against the state's own stated intention to use it.
#
# THE NEGATIVE CONTROL AND RCJ'S THIRD CANDIDATE ARE THE SAME DOCUMENT, AND
# §6.2's DATE TEST ALREADY DISPOSED OF IT BY MACHINE. DOM's Completed
# Procurements page carries an RHTP-titled award:
#
#   "Quote - Rural Health Transformation Program - RFX #3140004330 - 7/28/2025"
#   "Public Notice of Award - 8/13/2025"
#   "DOM has provided the basis for the selection of HORNE LLP in the Written
#    Determination for Emergency letter"
#
# That is a NAMED AWARDEE on a state host under an RHTP title, and it is not an
# RHTP subaward: it is the consultant Mississippi hired to help WRITE ITS
# APPLICATION, awarded 2025-08-13, FOUR AND A HALF MONTHS BEFORE the
# 2025-12-29 Notice of Award. Money the state did not yet have cannot have
# funded it. RCJ carries it as a Tier 3 candidate at $150,000 and session 20's
# provenance sweep ALREADY flagged it `PROVENANCE_PREDATES_NOA` off the
# document title's own date -- so the machine and this session's live read of
# DOM's page agree, from two directions, and nothing was arranged.
#
# The same page is also a SECOND positive control: DOM publishes ten "Public
# Notice of Intent to Award" documents in one uniform form, so "no RHTP award
# posted there" is about Mississippi and not about our reading.
#
# THE §0.3 NUMBERS ARE ALREADY VISIBLE AND THEY ARE THIRD-PARTY. Reporting of
# 2026-08-06 gives 700+ applications, ~$82 million available in round one and
# $676 million sought -- oversubscribed better than eight to one -- with "the
# first awards are expected by the end of the month", A DATE THAT HAS PASSED.
# §8 makes third-party news unable to support a `Yes` and this file codes
# nothing from it; it is in the status table's note as context and is labelled
# as such.
#
# TWO DIGEST MECHANISMS, ON THE TWO HOSTS, AND ONLY ONE OF THEM IS NEW.
#
# `mississippirhtp.com` runs Cloudflare Email Address Obfuscation, which
# XOR-encodes two mailto links with a RANDOM ONE-BYTE KEY on every render:
# three fetches three seconds apart were 217,198 bytes EVERY TIME with THREE
# DISTINCT file digests, differing on exactly two lines, both inside
# `data-cfemail` attributes, while the reduced text was identical at 7,185
# chars. That is session 36's SEVENTH mechanism (Louisiana) for the second
# time, and it is recorded as a RECURRENCE rather than as a discovery.
#
# `medicaid.ms.gov` IS NEW, AND IT IS THE MOST LITERAL ONE THIS PROJECT HAS
# MET. The WordPress "Simple Banner" plugin serialises the RENDER WALL-CLOCK
# TIME TO THE MICROSECOND into a `<script>` body, three times per render:
#
#   "current_date":{"date":"2026-09-03 19:25:41.029022", ...}
#   "current_date":{"date":"2026-09-03 19:25:48.143016", ...}
#
# Two fetches seven seconds apart, 101,840 bytes BOTH TIMES, one differing
# line. Fixed-width, so a byte-count check passes it (session 34's California
# lesson); script-body-borne like Wisconsin's Boomerang nonce and Arkansas's
# block-styles placeholder, so the reduction absorbs it. It differs from
# Arkansas's in the way that matters for how you TEST it: Arkansas's token is
# derived from a coarse render timestamp and is therefore IDENTICAL across a
# back-to-back pair, which is what made that pair useless; this one changes on
# every single request, so a pair does expose it.
#
# The consequence is the same either way and is why --probe compares a CONTENT
# digest: THREE of the four watched pages rotate their file digest on every
# fetch while nothing about the awards moves.
#
# Usage:
#   Rscript R/03ak_ms_year1_awardees.R --fetch [--force]
#   Rscript R/03ak_ms_year1_awardees.R --validate
#   Rscript R/03ak_ms_year1_awardees.R --build
#   Rscript R/03ak_ms_year1_awardees.R --probe
#   Rscript R/03ak_ms_year1_awardees.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
  library(purrr); library(httr); library(digest); library(here); library(rlang)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

MS_STATE     <- "MS"
MS_ALLOTMENT <- 205907220            # cms_fy2026_allotments.csv (§7.1)

# THE TWO FIGURES IN ONE FOOTER. Only the second may be tier-checked.
MS_FOOTER_HEADLINE   <- 205990180.16 # federal + non-federal match
MS_FOOTER_CMS_SHARE  <- 205907220.16 # 99.96% -- the allotment, to the dollar
MS_FOOTER_NONFEDERAL <- 82960        # 0.04%

MS_NOA_DATE           <- as.Date("2025-12-29")  # cms_state_noa_dates.csv
MS_CONSULTANT_AWARDED <- as.Date("2025-08-13")  # HORNE LLP, DOM's own page

MS_EVIDENCE_DIR <- here::here("data", "evidence", "MS")
MS_STATUS_CSV   <- here::here("data", "reference", "ms_year1_status.csv")
MS_DISPO_CSV    <- here::here("data", "reference",
                              "ms_rcj_candidate_disposition.csv")

MS_USER_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                        "+https://www.aha.org)")

MS_SOURCES <- tibble::tribble(
  ~key, ~url, ~file, ~note,
  "release",
  paste0("https://governorreeves.ms.gov/governor-reeves-announces-167-rural-",
         "health-transformation-program-awards-totaling-more-than-104-",
         "million/"),
  "2026-09-14_ms_governor_167_awards_ROSTER.html",
  paste("THE ROSTER. Governor Reeves's 2026-09-14 release names and prices",
        "ALL 167 awards across the THREE programmes the funding page had said",
        "were complete -- recipient, county, amount and description on every",
        "row. This is the announcement session 44 recorded as promised and",
        "overdue, and it arrived nine days later."),
  "funding",
  "https://mississippirhtp.com/funding/",
  "2026-09-21_ms_rhtp_funding_ANNOUNCEMENT_BANNER.html",
  paste("THE PAGE THIS FILE BEGAN AS. 'The selection process is complete' for",
        "RCGC, RTG and TCE; sub-awards executing by email; the Governor 'will",
        "formally announce details regarding all executed sub-awards'. All",
        "three sentences are still here -- what CHANGED between 2026-09-03 and",
        "2026-09-21 is a banner, 'Mississippi RHTP Announces First Round of",
        "Technology and Infrastructure Awards', which is the announcement",
        "arriving. And the footer that is 99.96% federal."),
  "home",
  "https://mississippirhtp.com/",
  "2026-09-21_ms_rhtp_home.html",
  paste("The programme home page. Five initiatives (CRIS, WEI, HTAM, TAPS,",
        "BRIDGE) and no recipient named."),
  "gov_newsroom",
  "https://governorreeves.ms.gov/newsroom/",
  "2026-09-21_ms_governor_newsroom_CARRIES_THE_ANNOUNCEMENT.html",
  paste("THE CHANNEL MISSISSIPPI ITSELF NAMED, AND IT DELIVERED. Session 44",
        "archived this page as a positive control -- it carried dated, priced",
        "award announcements and no RHTP award, which is what made",
        "Mississippi's RHTP silence Mississippi's rather than our reading. It",
        "now carries 'Governor Reeves Announces 167 Rural Health",
        "Transformation Program Awards Totaling More Than $104 Million',",
        "dated 2026-09-14. The control's job has therefore inverted: it no",
        "longer proves the channel works, it proves the release is ON that",
        "channel and links the roster this file parses."),
  "dom_completed",
  "https://medicaid.ms.gov/resources/procurement/completed-procurements/",
  "2026-09-03_ms_dom_completed_procurements.html",
  paste("BOTH CONTROLS ON ONE PAGE. Ten 'Public Notice of Intent to Award'",
        "documents in one uniform form (positive), and the RHTP-titled",
        "HORNE LLP consultant award of 2025-08-13 -- FOUR AND A HALF MONTHS",
        "BEFORE the NOA (§6.2 negative, and RCJ's third candidate)."),
  "dom_programme",
  "https://medicaid.ms.gov/rural-health-transformation-program/",
  "2026-09-03_ms_dom_rhtp_programme.html",
  paste("DOM's RHTP page, and it is STALE in Ohio's way: it still describes",
        "the state as intending to 'submit a timely application'. Recorded,",
        "because a stale page is not evidence of a stalled programme.")
)

ms_source <- function(key, field) {
  row <- MS_SOURCES[MS_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[MS] unknown source key: ", key, call. = FALSE)
  row[[field]]
}

ms_path <- function(key) file.path(MS_EVIDENCE_DIR, ms_source(key, "file"))


# -- retrieval ---------------------------------------------------------------

ms_get <- function(url, label) {
  resp <- httr::GET(url, httr::user_agent(MS_USER_AGENT),
                    httr::config(followlocation = TRUE), httr::timeout(120))
  if (httr::status_code(resp) != 200L) {
    stop("[MS] ", label, ": HTTP ", httr::status_code(resp), " from ", url,
         call. = FALSE)
  }
  httr::content(resp, as = "raw")
}

ms_assert_no_credentials <- function(raw, label) {
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "bytes"
  bad <- c("[ps]k\\.ey[A-Za-z0-9._-]{10,}", "AIza[0-9A-Za-z_-]{30,}")
  for (p in bad) {
    if (grepl(p, txt, useBytes = TRUE, perl = TRUE)) {
      stop("[MS] ", label, " carries a credential-shaped string (", p,
           "); it was NOT written.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

ms_fetch <- function(force = FALSE) {
  dir.create(MS_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  entries <- purrr::map_dfr(seq_len(nrow(MS_SOURCES)), function(i) {
    src <- MS_SOURCES[i, ]
    dest <- file.path(MS_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[MS] have ", src$file)
    } else {
      raw <- ms_get(src$url, src$key)
      ms_assert_no_credentials(raw, src$key)
      writeBin(raw, dest)
      message("[MS] wrote ", src$file, " (", length(raw), " bytes)")
      Sys.sleep(2)
    }
    tibble::tibble(file = src$file, bytes = file.size(dest),
                   sha256 = digest::digest(file = dest, algo = "sha256"))
  })
  ms_write_manifest(entries)
  invisible(entries)
}

ms_write_manifest <- function(entries) {
  path <- file.path(MS_EVIDENCE_DIR, "MANIFEST.txt")
  entries <- entries[entries$file != "MANIFEST.txt", ]
  writeLines(c(
    "MISSISSIPPI -- RHTP evidence archive",
    "",
    "Fetched 2026-09-03 by R/03ak_ms_year1_awardees.R --fetch.",
    "Bodies are written with writeBin(), so re-hashing a file on disk",
    "reproduces its digest below.",
    "",
    "THE FILE DIGESTS ARE USELESS AS A CHANGE TEST ON BOTH HOSTS, AND BOTH",
    "MECHANISMS WERE MEASURED HERE RATHER THAN INHERITED.",
    "",
    "mississippirhtp.com: Cloudflare Email Address Obfuscation re-rolls a",
    "one-byte XOR key per render -- three fetches three seconds apart,",
    "217,198 bytes EVERY TIME, THREE DISTINCT digests, differing on exactly",
    "two lines, both inside data-cfemail attributes, reduced text identical",
    "at 7,185 chars. Session 36's seventh mechanism (Louisiana), recurring.",
    "",
    "medicaid.ms.gov: NEW. The WordPress Simple Banner plugin serialises the",
    "render wall-clock time TO THE MICROSECOND into a <script> body --",
    "\"current_date\":{\"date\":\"2026-09-03 19:25:41.029022\"} -- three times",
    "per render. Two fetches seven seconds apart, 101,840 bytes both times,",
    "one differing line. Fixed-width, so a byte-count check passes it.",
    "",
    "--probe compares a CONTENT digest on both.",
    "",
    "file  bytes  sha256",
    paste(entries$file, entries$bytes, entries$sha256, sep = "  ")
  ), path)
  invisible(path)
}


# -- reduction ---------------------------------------------------------------

ms_reduce_html <- function(raw) {
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "UTF-8"
  txt <- stringr::str_remove_all(
    txt, stringr::regex("<(script|style|noscript)[^>]*>.*?</\\1>",
                        dotall = TRUE, ignore_case = TRUE))
  txt <- stringr::str_replace_all(txt, "<[^>]+>", " ")
  txt <- stringr::str_replace_all(txt, "&nbsp;|&#160;", " ")
  txt <- stringr::str_replace_all(txt, "&amp;", "&")
  txt <- stringr::str_replace_all(txt, "&#8217;|&#39;|&rsquo;", "'")
  txt <- stringr::str_replace_all(txt, "&#8211;|&ndash;|&#8212;|&mdash;", "-")
  # DOM's page mixes the ENTITY and the LITERAL character in the same list --
  # "Public Notice of Intent to Award &#8211; 8/22/25" one line, "Public
  # Notice of Award \u2013 8/13/2025" the next -- so an assertion written
  # against either form fails on half the page. Normalise both to a hyphen.
  txt <- stringr::str_replace_all(txt, "[\u2010-\u2015\u2212]", "-")
  txt <- stringr::str_replace_all(txt, "&quot;|&ldquo;|&rdquo;", "\"")
  txt <- stringr::str_replace_all(txt, "[ \t\u00a0]+", " ")
  txt <- stringr::str_replace_all(txt, "\\s*\n\\s*", "\n")
  stringr::str_trim(txt)
}

ms_html_text <- function(key, body = NULL) {
  raw <- if (is.null(body)) readBin(ms_path(key), "raw",
                                    file.size(ms_path(key))) else body
  ms_reduce_html(raw)
}

ms_content_digest <- function(key, body = NULL) {
  digest::digest(ms_html_text(key, body), algo = "sha256")
}

ms_have_archive <- function() {
  all(file.exists(file.path(MS_EVIDENCE_DIR, MS_SOURCES$file)))
}


# -- the award-language tripwire ---------------------------------------------
#
# "selected applicants" and "sub-award execution" are ALREADY on the funding
# page and must not be in this list, or it fires every run and stops being
# read. Session 29's Missouri rule: the phrases here are the ones that would
# accompany a ROSTER, measured against the live page rather than guessed.

MS_AWARD_POSTED <- c(
  "notice of intent to award", "list of awardees", "awardees are",
  "award recipients", "recipients are", "the following organizations",
  "sub-awards have been executed", "sub-award recipients",
  "has been awarded to", "have been awarded to", "successful applicants are",
  "list of organization and award"
)

ms_award_language <- function(txt) {
  low <- stringr::str_to_lower(txt)
  MS_AWARD_POSTED[vapply(MS_AWARD_POSTED,
                         function(p) stringr::str_detect(low,
                                                         stringr::fixed(p)),
                         logical(1))]
}

#' THE NEXT TRANCHE HAS NOT BEEN ANNOUNCED
#'
#' Until 2026-09-14 this asserted that Mississippi had named NOBODY, and it was
#' right to: the funding page said selection was complete and the Governor had
#' promised an announcement. The announcement came, so that assertion has done
#' its job and asserting it again would be asserting something false.
#'
#' What replaces it is the same question one tranche further on. The release
#' itself names what is still outstanding -- the Workforce Expansion Initiative
#' and Psychiatric Emergency Services, "currently being reviewed and will be
#' announced in the next 30 to 45 days", plus two October opportunities -- so
#' Mississippi's Year 1 is PARTIAL by construction and $101,792,074 of its
#' $205.9 million first-year budget is in no public roster. This fires the day
#' either of those lands, which is the day this file gains rows.
ms_assert_remaining_tranches <- function(bodies = NULL) {
  for (k in c("funding", "home", "gov_newsroom")) {
    txt <- ms_html_text(k, if (!is.null(bodies)) bodies[[k]] else NULL)
    # The 167 are RECORDED, so the roster language that announced them must
    # not re-fire here every run -- Kentucky's and New Mexico's device. What
    # is watched is award language mentioning the two named pending
    # initiatives, or a SECOND award headline on the newsroom.
    pending <- stringr::str_detect(
      stringr::str_to_lower(txt),
      stringr::regex(paste0("(workforce expansion|empath|psychiatric ",
                            "emergency)[^.]{0,160}(award|selected|recipient)")))
    if (pending) {
      stop("[MS] '", k, "' now carries AWARD language against the Workforce ",
           "Expansion Initiative or Psychiatric Emergency Services. THAT IS ",
           "THE SIGNAL, NOT A DEFECT: the release dated these to 2026-10-14 ",
           "-- 2026-10-29, and this is the second tranche landing. Re-fetch ",
           "the roster, extend ms_parse_release() to its section, and ",
           "re-derive -- ms_year1_awardees.csv is 167 rows of a PARTIAL year.",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' The 167-award announcement is on the channel Mississippi named
#'
#' The positive control, inverted. It no longer proves the Governor's newsroom
#' CAN carry an award announcement; it proves it DOES carry this one, and it
#' fails if the release leaves the channel this file cites.
ms_assert_announcement_on_channel <- function(body = NULL) {
  txt <- stringr::str_replace_all(ms_html_text("gov_newsroom", body),
                                  "\\s+", " ")
  want <- paste("Governor Reeves Announces 167 Rural Health Transformation",
                "Program Awards Totaling More Than $104 Million")
  if (!stringr::str_detect(txt, stringr::fixed(want))) {
    stop("[MS] the Governor's newsroom no longer carries the 167-award ",
         "announcement. That headline is what puts the roster this file ",
         "parses on the state channel Mississippi itself named -- without ",
         "it the extraction rests on a single deep link.", call. = FALSE)
  }
  invisible(TRUE)
}

#' Selection is complete, the announcement is promised, and NOBODY is named
#'
#' The two sentences the whole finding rests on. Losing either means the page
#' has moved on and the status table is stale.
ms_assert_selection_complete_unnamed <- function(body = NULL) {
  txt <- stringr::str_replace_all(ms_html_text("funding", body), "\\s+", " ")
  want <- c(
    "The selection process is complete for the Rural Capital Care Gap Closure",
    "will be contacted by email this week to begin the sub-award execution",
    "Governor Tate Reeves will formally announce details regarding all executed")
  missing <- want[!vapply(want,
                          function(w) stringr::str_detect(txt,
                                                          stringr::fixed(w)),
                          logical(1))]
  if (length(missing)) {
    stop("[MS] the funding page no longer says: ",
         paste(sQuote(missing), collapse = "; "),
         ". Either the announcement has happened or the page has been ",
         "rewritten. Read it -- this file's finding is measured against ",
         "those exact sentences.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- §0.2: THE FOOTER THAT IS NOT 100% FEDERAL -------------------------------

#' Mississippi's footer states a PARTIAL CMS share, and prints its dollars
#'
#' The observation the parser exists for. If Mississippi ever restates this
#' footer as 100 percent, the whole finding changes and this must fail rather
#' than quietly keep asserting a percentage the page no longer carries.
ms_assert_footer_is_not_fully_federal <- function(body = NULL) {
  f <- rhtp_footer_parse(ms_html_text("funding", body))
  if (nrow(f) != 1L) {
    stop("[MS] expected exactly ONE CMS footer on the funding page; parsed ",
         nrow(f), ".", call. = FALSE)
  }
  if (f$fully_federal) {
    stop("[MS] the funding page's footer is now 100% federal. Mississippi was ",
         "THE ONLY non-100% footer in this repository and the §0.2 CMS-share ",
         "rule was written for it. Re-read the page before changing anything.",
         call. = FALSE)
  }
  stopifnot(abs(f$cms_pct - 99.96) < 1e-9,
            abs(f$headline_amount - MS_FOOTER_HEADLINE) < 0.005,
            abs(f$cms_amount - MS_FOOTER_CMS_SHARE) < 0.005,
            abs(f$nonfederal_amount - MS_FOOTER_NONFEDERAL) < 0.005)
  # THE FOOTER IS INTERNALLY EXACT, AND THAT IS WHAT MAKES THE CMS SHARE
  # TRUSTWORTHY RATHER THAN A GUESS: headline - CMS share = $82,960.00, which
  # is the non-government figure the footer prints, TO THE CENT. So the
  # publisher's own three numbers close on each other and nothing here is
  # derived.
  gap <- f$headline_amount - f$cms_amount
  stopifnot(abs(gap - MS_FOOTER_NONFEDERAL) < 0.005,
            gap > 8 * RHTP_FOOTER_ALLOTMENT_MARGIN)
  # And the CMS share lands on the §7.1 anchor within the anchor's OWN
  # rounding -- 16 cents, because CMS publishes the allotment whole.
  stopifnot(abs(f$cms_amount - MS_ALLOTMENT) < 1)
  invisible(f)
}

#' The CMS SHARE is the allotment; the HEADLINE is not, and is not a pool
#'
#' Driven in all four directions, because the failure this prevents is the
#' one that ACCEPTS rather than the one that refuses.
ms_assert_footer_cms_share_is_the_allotment <- function(body = NULL) {
  txt <- ms_html_text("funding", body)

  # (1) The CMS share, taken from the text, tiers as STATE_ALLOTMENT.
  ok <- rhtp_assert_footer_text_tier(
    txt, MS_STATE, "STATE_ALLOTMENT",
    label = "MS funding-page CMS footer (CMS share)")
  if (!isTRUE(ok)) {
    message("[MS] the §0.2 tier check did not run -- see above. That is a gap ",
            "in the anchor, not a pass (§0.4).")
    return(invisible(NA))
  }

  # (2) The same share read as a pool is refused.
  refused <- tryCatch({
    rhtp_assert_footer_not_allotment(
      MS_FOOTER_CMS_SHARE, MS_STATE, "SOLICITATION",
      label = "MS CMS share read as a pool")
    FALSE
  }, error = function(e) TRUE)
  if (!refused) {
    stop("[MS] the §0.2 rule no longer refuses Mississippi's allotment being ",
         "read as a solicitation pool.", call. = FALSE)
  }

  # (3) THE DEFECT ITSELF, PINNED. The headline declared STATE_ALLOTMENT is
  #     refused -- correctly, it is not the allotment ...
  headline_refused <- tryCatch({
    rhtp_assert_footer_not_allotment(
      MS_FOOTER_HEADLINE, MS_STATE, "STATE_ALLOTMENT",
      label = "MS headline read as the allotment")
    FALSE
  }, error = function(e) TRUE)
  if (!headline_refused) {
    stop("[MS] the headline $205,990,180.16 is now accepted as Mississippi's ",
         "allotment. Either the anchor moved or the page did.", call. = FALSE)
  }

  # (4) ... and declared SOLICITATION it is ACCEPTED, WHICH IS WRONG. This is
  #     asserted rather than fixed, because the fix is upstream -- parse the
  #     CMS share -- and pretending the margin catches it would hide the only
  #     case in this repository that it does not.
  headline_accepted <- isTRUE(rhtp_assert_footer_not_allotment(
    MS_FOOTER_HEADLINE, MS_STATE, "SOLICITATION",
    label = "MS headline read as a pool"))
  if (!headline_accepted) {
    stop("[MS] the margin now catches Mississippi's HEADLINE as well as its ",
         "CMS share. If someone widened RHTP_FOOTER_ALLOTMENT_MARGIN to make ",
         "this pass, put it back: $82,960 is ONE STATE'S match amount, the ",
         "next state's will differ, and §0.2 says a figure that fails the ",
         "check is a document to re-read, never a margin to widen.",
         call. = FALSE)
  }
  invisible(TRUE)
}


# -- the controls ------------------------------------------------------------

#' THE CHANNEL CONTROL, RETIRED AND SAID SO
#'
#' This counted "announce"-shaped headlines on the Governor's newsroom and
#' required at least three, on the reasoning that a channel demonstrably
#' carrying award announcements is what made Mississippi's RHTP silence
#' Mississippi's rather than our reading.
#'
#' IT HALTED THE ROUTINE, AND FOR TWO REASONS AT ONCE. The newsroom is a
#' "Load More" page whose static HTML carries only its first few items, and by
#' 2026-09-21 exactly ONE of them matched "announce" -- so the control failed
#' on ordinary newsroom churn, on a threshold that was never measuring what it
#' meant to. And underneath that, the thing it was guarding had ALREADY
#' happened: the one matching headline was Mississippi's own RHTP award
#' announcement, which the control's second half would have caught had the
#' first half not stopped first.
#'
#' A count of headlines was the wrong instrument either way. It is replaced by
#' `ms_assert_announcement_on_channel()`, which asserts the ONE headline this
#' file actually depends on, by name -- a name cannot drift with pagination.
ms_assert_governor_channel_control <- function(body = NULL) {
  .Deprecated("ms_assert_announcement_on_channel")
  ms_assert_announcement_on_channel(body)
}

#' DOM's ONE RHTP-titled award PREDATES the Notice of Award by 4.5 months
#'
#' §6.2's date test with the document in hand. This is simultaneously the
#' negative control, RCJ's third Tier 3 candidate, and the closest thing to a
#' true positive Mississippi has: a NAMED awardee, on a state host, under an
#' RHTP title. It is the consultant hired to help write the application.
ms_assert_dom_consultant_predates_noa <- function(body = NULL) {
  txt <- stringr::str_replace_all(ms_html_text("dom_completed", body),
                                  "\\s+", " ")
  want <- c("Quote - Rural Health Transformation Program - RFX #3140004330",
            "Public Notice of Award - 8/13/2025",
            "the selection of HORNE LLP")
  missing <- want[!vapply(want,
                          function(w) stringr::str_detect(txt,
                                                          stringr::fixed(w)),
                          logical(1))]
  if (length(missing)) {
    stop("[MS] DOM's Completed Procurements page no longer carries: ",
         paste(sQuote(missing), collapse = "; "),
         ". That page is BOTH this state's positive control and its §6.2 ",
         "negative control; re-read it.", call. = FALSE)
  }
  if (MS_CONSULTANT_AWARDED >= MS_NOA_DATE) {
    stop("[MS] the consultant award no longer predates the Notice of Award. ",
         "The date test is what disposes of RCJ's third candidate.",
         call. = FALSE)
  }
  # And the positive half: DOM publishes named award notices in a uniform form.
  n_intents <- stringr::str_count(txt,
                                  stringr::fixed("Notice of Intent to Award"))
  if (n_intents < 5L) {
    stop("[MS] DOM's page carries only ", n_intents, " intent-to-award ",
         "notices. Without them, 'no RHTP award posted here' is a statement ",
         "about our reading rather than about Mississippi.", call. = FALSE)
  }
  invisible(list(intents = n_intents,
                 days_before_noa = as.integer(MS_NOA_DATE -
                                              MS_CONSULTANT_AWARDED)))
}



# -- THE ROSTER: 167 AWARDS, THREE PROGRAMMES, $104,115,146.80 ---------------
#
# Mississippi announced on 2026-09-14, nine days after session 44 recorded the
# announcement as promised and already overdue. The Governor's release names
# and prices every one of 167 awards -- recipient, county, amount and a
# one-line description per row -- across the THREE grant programmes its funding
# page had said were complete: Rural Technology Grant (RTG), Rural Capital
# Project Care Gap Closure (RCGC) and Telehealth Hub Connectivity, Equipment &
# Education (TCE).
#
# THE PARSE IS ANCHORED ON THE AMOUNT, NOT ON SEPARATOR POSITION, AND TWO ROWS
# ARE WHY. Every row is printed as
#
#     <n>. <organisation> - <county> - $<amount> - <description>
#
# and 165 of the 167 honour that exactly. The two that do not each break a
# different naive reading, and only one of them costs a dollar -- which is the
# part worth remembering, because a reconciliation that closes is not proof
# that a parse is right:
#
#   * ROW 23 OF RCGC, "North Mississippi Medical Center, Inc. - Lee County-
#     $2,500,000 - ...". THE SPACE BEFORE THE HYPHEN IS MISSING, so the row
#     carries two " - " separators where its siblings carry three. A parse
#     that splits on " - " and takes the third field as the amount finds no
#     amount at all and DROPS THE ROW: 166 awards and $101,615,146.80, short
#     by $2,500,000 -- and short by the single largest award in the section.
#     This one the total catches.
#
#   * ROW 30 OF RCGC, "Northeast Mental Health - Mental Retardation Commission
#     d.b.a. LIFECORE Health Group - Monroe County - $27,600 - ...". THE
#     ORGANISATION'S OWN LEGAL NAME CONTAINS " - ", so the row carries four
#     separators. A left-to-right split reads the awardee as "Northeast Mental
#     Health" and the COUNTY as "Mental Retardation Commission d.b.a. LIFECORE
#     Health Group". THE MONEY IS UNTOUCHED. Every total reconciles to the
#     cent, the row count is 167, and the file quietly contains an
#     organisation that does not exist in a county that does not exist.
#
# So the row count and the total agree on a defective parse, and the second
# defect is invisible to both. Anchoring on the amount and on the county's own
# suffix -- "<something> County" or "Co." -- reads both rows correctly, and
# `ms_assert_odd_shape_rows()` drives each mistake in the order it is made.
#
# A THIRD SHAPE EXISTS AND IS NOT A DEFECT: row 9 of TCE prints "Lafayette
# Co." where the other 166 print "County". An anchor requiring the full word
# silently drops it -- one row, $300,000 -- so the suffix is matched both ways
# and a test pins that too.

MS_RELEASE_TOTAL   <- 104115146          # the Governor's stated headline
MS_RELEASE_AWARDS  <- 167L
MS_RELEASE_DATE    <- as.Date("2026-09-14")
MS_AWARDEES_CSV    <- here::here("data", "reference", "ms_year1_awardees.csv")

# The three sections, in the order the release prints them, keyed on the
# heading Mississippi itself uses. These are the three the funding page names
# as complete (RTG, RCGC, TCE), and the mapping is asserted rather than assumed.
MS_POOLS <- tibble::tribble(
  ~heading,                                                          ~pool, ~n,
  "Rural Provider Technology Grant Program Awards",
  "Rural Technology Grant (RTG)",                                          97L,
  "Mississippi Rural Capital Project Care Gap Closure Grant Program Awards",
  "Rural Capital Project Care Gap Closure (RCGC)",                         43L,
  "Telehealth Hub Connectivity, Equipment & Education Grant Program Awards",
  "Telehealth Hub Connectivity, Equipment & Education (TCE)",              27L
)

# <n>. <organisation> - <county|Co.> - $<amount> - <description>
MS_ROW_RX <- paste0(
  "^(\\d+)\\.\\s+",                       # the row number, per section
  "(.*?)\\s*-\\s*",                       # organisation (may itself contain -)
  "([A-Za-z .]+?(?:County|Co\\.))\\s*-\\s*",  # county, either spelling
  "\\$([\\d,]+(?:\\.\\d{1,2})?)\\s*-\\s*",    # amount, cents optional
  "(.+)$")                                # description

#' Parse the Governor's release into one row per award
#'
#' PARSED, NEVER TRANSCRIBED (the §7.1 posture), out of the committed archive,
#' so a re-run on the same bytes reproduces the file exactly and the roster
#' cannot drift from the document. A numbered line that does not parse is
#' REFUSED rather than dropped: dropping it is precisely how row 23 would cost
#' $2,500,000 in silence.
ms_parse_release <- function(body = NULL) {
  txt   <- ms_html_text("release", body)
  lines <- stringr::str_split(txt, "\n")[[1]]

  heads <- match(MS_POOLS$heading, lines)
  if (anyNA(heads)) {
    stop("[MS] the release no longer carries these section headings: ",
         paste(MS_POOLS$heading[is.na(heads)], collapse = "; "),
         ". The three headings are how each award is attributed to a ",
         "programme -- without them every row would land in one undifferent",
         "iated pool.", call. = FALSE)
  }
  if (is.unsorted(heads, strictly = TRUE)) {
    stop("[MS] the release's three sections are no longer in the order this ",
         "file reads them. Section attribution is POSITIONAL (the rows",
         " between one heading and the next), so a re-ordering silently ",
         "re-labels awards.", call. = FALSE)
  }

  numbered <- grep("^\\d+\\. ", lines)
  out <- purrr::map_dfr(numbered, function(i) {
    m <- stringr::str_match(lines[i], MS_ROW_RX)
    if (is.na(m[1, 1])) {
      stop("[MS] a numbered award line did not parse, and it is REFUSED ",
           "rather than skipped: line ", i, " -- '",
           substr(lines[i], 1, 180), "'. Mississippi prints two rows that ",
           "break the ordinary shape already (a missing space before a ",
           "hyphen, and an organisation whose legal name contains ' - '); a ",
           "THIRD would be silently dropped here if this did not stop.",
           call. = FALSE)
    }
    tibble::tibble(
      pool        = MS_POOLS$pool[max(which(heads < i))],
      row_in_pool = as.integer(m[1, 2]),
      awardee     = stringr::str_squish(m[1, 3]),
      county      = stringr::str_squish(m[1, 4]),
      amount      = as.numeric(stringr::str_remove_all(m[1, 5], ",")),
      description = stringr::str_squish(m[1, 6]))
  })
  out
}

#' THE TWO ODD-SHAPE ROWS, AND WHAT EACH NAIVE READING COSTS
#'
#' Asserted rather than described, and driven in the order a reader makes the
#' mistakes: the missing space first (it costs $2,500,000 and the total catches
#' it), then the embedded " - " (it costs a NAME and a COUNTY and no total
#' anywhere will ever notice).
ms_assert_odd_shape_rows <- function(d = ms_parse_release()) {
  odd1 <- d %>%
    dplyr::filter(.data$awardee == "North Mississippi Medical Center, Inc.")
  if (nrow(odd1) != 1L || odd1$county != "Lee County" ||
      odd1$amount != 2500000) {
    stop("[MS] the missing-space row is no longer as recorded. It is the row ",
         "a ' - ' split DROPS, taking $2,500,000 and the largest RCGC award ",
         "with it -- if the Governor's office has fixed the typo, say so and ",
         "re-derive; do not just delete this check.", call. = FALSE)
  }
  # TWO SPELLINGS OF ONE ORGANISATION, AND ONLY ONE OF THEM BREAKS A PARSE.
  # Mississippi awards LIFECORE Health Group twice: "Northeast Mental Health -
  # Mental Retardation Commission d.b.a. LIFECORE Health Group" under RCGC
  # ($27,600) and "Northeast Mental Health d.b.a. LIFECORE Health Group" under
  # TCE ($30,610). The longer form carries the embedded " - "; the shorter one
  # does not. THEY ARE NOT MERGED (§2 forbids a machine resolving a fuzzy name
  # match) -- both are award ACTIONS and both stand, exactly as Arkansas's nine
  # divergent spellings and North Carolina's two spellings of UNC stand.
  lifecore <- d %>% dplyr::filter(grepl("LIFECORE", .data$awardee, fixed = TRUE))
  if (nrow(lifecore) != 2L) {
    stop("[MS] LIFECORE Health Group no longer holds exactly two awards under ",
         "two spellings (found ", nrow(lifecore), "). That pair is what shows ",
         "the embedded-hyphen shape is the publisher's and not the parser's.",
         call. = FALSE)
  }
  odd2 <- lifecore %>%
    dplyr::filter(.data$pool == "Rural Capital Project Care Gap Closure (RCGC)")
  if (nrow(odd2) != 1L ||
      odd2$awardee != paste("Northeast Mental Health - Mental Retardation",
                            "Commission d.b.a. LIFECORE Health Group") ||
      odd2$county != "Monroe County" || odd2$amount != 27600) {
    stop("[MS] the embedded-hyphen row is no longer as recorded. A ",
         "left-to-right ' - ' split reads this awardee as 'Northeast Mental ",
         "Health' and its COUNTY as 'Mental Retardation Commission d.b.a. ",
         "LIFECORE Health Group', and EVERY TOTAL STILL RECONCILES. That is ",
         "why this is asserted on the name and not on the money.",
         call. = FALSE)
  }
  # The third shape, which is not a defect but is a silent drop if unhandled.
  abbrev <- d %>% dplyr::filter(grepl("Co\\.$", .data$county))
  if (nrow(abbrev) != 1L || abbrev$county != "Lafayette Co.") {
    stop("[MS] the abbreviated-county row is no longer as recorded. An ",
         "anchor requiring the full word 'County' drops it -- one row, ",
         "$300,000 -- and the row count then reads 166.", call. = FALSE)
  }
  invisible(TRUE)
}

#' 167 awards, three pools, and a total that closes to $0.80
#'
#' Mississippi's rows sum to $104,115,146.80 and its Governor states
#' $104,115,146. The difference is EXACTLY $0.80 and it is TRUNCATION, not a
#' discrepancy: nine of the 167 rows carry cents, those cents sum to $3.80, and
#' the headline drops the remainder rather than rounding it (which would have
#' given $104,115,147). NOTHING IS CORRECTED (§8) -- both figures are the
#' state's own and both are pinned here, because a future session meeting a
#' 20-cent gap should find it already explained rather than re-derive it.
ms_reconcile <- function(d = ms_parse_release()) {
  by_pool <- d %>%
    dplyr::group_by(.data$pool) %>%
    dplyr::summarise(awards = dplyr::n(), dollars = sum(.data$amount),
                     .groups = "drop")
  tibble::tibble(
    pool = c(by_pool$pool, "ALL THREE (parsed)", "ALL THREE (as stated)"),
    awards = c(by_pool$awards, sum(by_pool$awards), MS_RELEASE_AWARDS),
    dollars = c(by_pool$dollars, sum(by_pool$dollars), MS_RELEASE_TOTAL))
}

ms_assert_reconciles <- function(d = ms_parse_release()) {
  if (nrow(d) != MS_RELEASE_AWARDS) {
    stop("[MS] parsed ", nrow(d), " awards against the Governor's stated ",
         MS_RELEASE_AWARDS, ". The count is in the headline, the first ",
         "sentence and the section rows, so a mismatch is a parse defect, ",
         "not a publisher disagreement.", call. = FALSE)
  }
  per_pool <- d %>% dplyr::count(.data$pool)
  want <- MS_POOLS %>% dplyr::select("pool", "n")
  got  <- per_pool$n[match(want$pool, per_pool$pool)]
  if (!isTRUE(all.equal(got, want$n))) {
    stop("[MS] the three sections no longer hold ",
         paste(want$n, collapse = "/"), " awards but ",
         paste(got, collapse = "/"), ". 97 + 43 + 27 = 167 is what ties the ",
         "positional section attribution to the stated total.", call. = FALSE)
  }
  total <- sum(d$amount)
  gap   <- total - MS_RELEASE_TOTAL
  if (!isTRUE(all.equal(gap, 0.80))) {
    stop("[MS] the 167 rows sum to ", format(total, nsmall = 2),
         " against the Governor's stated ", MS_RELEASE_TOTAL,
         ", a gap of ", format(gap, nsmall = 2),
         " where $0.80 of TRUNCATION is expected. A gap that is not $0.80 is ",
         "a ROW that is wrong, not a rounding rule to widen -- §0.2's lesson ",
         "applied to a total.", call. = FALSE)
    }
  cents <- sum(d$amount %% 1)
  if (!isTRUE(all.equal(cents, 3.80))) {
    stop("[MS] the cents across all 167 rows no longer sum to $3.80 (got ",
         format(cents, nsmall = 2), "). That figure is what makes the $0.80 ",
         "headline gap truncation rather than a missing row.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The 167 award actions, in the leading-19 schema every state file shares
#'
#' ONE ROW PER AWARD ACTION, NOT PER ORGANISATION, and that is Michigan's
#' lesson (session 27) taken as the default rather than learned again: 167
#' award actions are held by 103 distinct awardee strings, and Memorial Health
#' System alone holds TWELVE. Collapsing to the organisation would report
#' Mississippi as a 103-award state, and collapsing on a fuzzy name match would
#' additionally merge LIFECORE's two spellings, which §2 forbids.
#'
#' §0.3a GOVERNS THE TYPING AND THE DESCRIPTIONS ARE NOT USED FOR IT. The
#' release gives a one-line description per award -- "To modernize diagnostic
#' imaging services", "To expand outpatient pediatric PT, OT, and STT services"
#' -- and a description describes an ACTIVITY while §0.3a judges the RECIPIENT.
#' Arkansas established this in session 40 and measured that feeding the
#' descriptions to the classifier moved eleven rows and not one dollar. Here
#' the descriptions go into `note`, where a reviewer reads them, and
#' `recipient_type` is derived from the recipient's own NAME alone.
ms_year1_awardees <- function(d = ms_parse_release()) {
  cls <- purrr::map(d$awardee, rhtp_classify_recipient_type,
                    state_code = MS_STATE)
  rtype <- purrr::map_chr(cls, "recipient_type")
  conf  <- purrr::map_chr(cls, "determination_confidence")

  # §10.2, with award_made = TRUE: these are ANNOUNCED awards, not intents.
  flow <- rhtp_classify_flow(rtype, d$description, award_made = TRUE)

  fallback <- rtype == "NONPROFIT_CBO" & conf == "LOW"

  tibble::tibble(
    state = MS_STATE,
    row_no = seq_len(nrow(d)),
    awardee = d$awardee,
    amount = d$amount,
    recipient_type = rtype,
    distributed_to_hospital = flow$distributed_to_hospital,
    note = paste0(d$description, " [", d$county, "]"),
    recipient_confirmed = "Yes",
    amount_confirmed = "Yes",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = paste(
      "Governor Reeves Announces 167 Rural Health Transformation Program",
      "Awards Totaling More Than $104 Million"),
    state_source_url = ms_source("release", "url"),
    validation_source_type = "GOVERNOR_PRESS_RELEASE",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03ak_ms_year1_awardees.R",
    ccn = NA_character_,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    county = d$county,
    award_pool = d$pool,
    row_in_pool = d$row_in_pool,
    awardee_as_published = d$awardee,
    recipient_type_source = dplyr::if_else(
      fallback,
      paste("§8's STANDING FALLBACK. The Governor's release publishes a",
            "recipient, a county, an amount and a description of the WORK,",
            "and says NOTHING about the recipient's organisational form --",
            "Kansas's, Maryland's, Nebraska's, Oklahoma's, Nevada's,",
            "Michigan's, Missouri's, Iowa's, North Carolina's, Arkansas's and",
            "Wyoming's shape a TWELFTH time. NOTHING WAS PROMOTED (§0.4):",
            "several of these read as FQHCs or physician practices to anyone",
            "who knows Mississippi, and reading them that way would be this",
            "pipeline asserting a form the state has not."),
      "DERIVED FROM THE RECIPIENT'S OWN NAME by rhtp_classify_recipient_type()."),
    determination_confidence = conf,
    flag_reason = dplyr::if_else(fallback, "RECIPIENT_TYPE_INFERRED",
                                 NA_character_),
    budget_period = "Budget Period 1",
    flow_type = flow$flow_type,
    hospital_benefiting = flow$hospital_benefiting,
    hospital_attribution = dplyr::if_else(
      flow$distributed_to_hospital == "Yes", "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = dplyr::if_else(
      flow$distributed_to_hospital == "Yes",
      paste("§10.2 DIRECT -- the named recipient is itself a hospital or",
            "health system, so recipient identity IS the flow test and no",
            "description decides it (§0.3a). The award is ANNOUNCED, not",
            "intended: the Governor's release says 'today announced 167",
            "awards', so recipient_confirmed and amount_confirmed are both",
            "Yes -- stronger than Arkansas's or Wyoming's intents."),
      paste("§10.2 -- the named recipient is not a hospital, so no hospital",
            "dollar is claimed. Where recipient_type is §8's standing",
            "fallback this is the CONSERVATIVE answer and the row is queued",
            "as MS_RECIPIENT_FORM_NOT_STATED: resolving it could only raise",
            "Mississippi's hospital figure, never lower it.")),
    amount_basis = paste(
      "EXACT, per-recipient, and published by the Governor for every one of",
      "the 167 rows. The 167 sum to $104,115,146.80 against a stated",
      "$104,115,146 -- a $0.80 TRUNCATION of the cents, not a discrepancy",
      "(§8: both figures are the state's own and neither is corrected)."),
    round_amount = NA_real_,
    announcement_date = MS_RELEASE_DATE,
    source_archive_path = file.path("data", "evidence", "MS",
                                    ms_source("release", "file")))
}

#' NOTHING WAS PROMOTED, AND THE UNCERTAINTY RUNS ONE WAY ONLY
#'
#' The unstated-form question a TWELFTH time and among the largest in dollars.
#' Every row carrying §8's fallback is already `distributed_to_hospital = No`,
#' so resolving any of them can only RAISE Mississippi's hospital figure:
#' the named-hospital total is a genuine FLOOR and floor + fallback a genuine
#' CEILING. That one-directionality is asserted rather than claimed, because it
#' is what lets the report state a ceiling at all (Oklahoma's rule, session 25).
ms_assert_nothing_promoted <- function(d = ms_year1_awardees()) {
  fb <- d %>% dplyr::filter(.data$flag_reason == "RECIPIENT_TYPE_INFERRED")
  if (!nrow(fb)) {
    stop("[MS] no row carries §8's standing fallback, which cannot be right ",
         "for a publisher that states no recipient form anywhere.",
         call. = FALSE)
  }
  if (any(fb$distributed_to_hospital != "No")) {
    stop("[MS] a row on §8's standing fallback is no longer ",
         "distributed_to_hospital = No. The floor/ceiling reported for ",
         "Mississippi depends on that uncertainty being ONE-DIRECTIONAL; if ",
         "it is not, the ceiling is not a ceiling.", call. = FALSE)
  }
  if (any(fb$recipient_type != "NONPROFIT_CBO" |
          fb$determination_confidence != "LOW")) {
    stop("[MS] a fallback row has been promoted off NONPROFIT_CBO/LOW. ",
         "Nothing here may be typed from this pipeline's own knowledge of ",
         "Mississippi (§0.4) -- the CCN match (blocker 5) resolves it.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' The unstated-form question is QUEUED, not answered here
#'
#' 96 of 167 rows -- 53.8% of everything Mississippi has awarded -- carry §8's
#' standing fallback, and a reviewer resolving them is the only thing that
#' moves them. This asserts the queue row exists and is OPEN, so the
#' disclosure cannot quietly stop being made while the file keeps reporting a
#' floor as though it were a total.
MS_FORM_NOT_STATED_QUESTION <- "MS_RECIPIENT_FORM_NOT_STATED"
MS_REVIEW_QUEUE <- file.path("data", "reference",
                             "classification_review_queue.csv")

ms_assert_form_not_stated_queued <- function(d = ms_year1_awardees()) {
  fb <- d %>% dplyr::filter(.data$flag_reason == "RECIPIENT_TYPE_INFERRED")
  q <- readr::read_csv(here::here(MS_REVIEW_QUEUE), show_col_types = FALSE,
                       progress = FALSE)
  row <- q[q$question_id == MS_FORM_NOT_STATED_QUESTION, ]
  if (nrow(row) != 1L || !identical(row$queue_status[[1]], "OPEN")) {
    stop("[MS] ", MS_FORM_NOT_STATED_QUESTION, " is not an OPEN row in ",
         MS_REVIEW_QUEUE, ". ", nrow(fb), " rows and $",
         format(sum(fb$amount), big.mark = ",", nsmall = 2),
         " turn on it, and it is ONE-DIRECTIONAL: resolving any of them can ",
         "only raise Mississippi's hospital figure.", call. = FALSE)
  }
  # The uncertainty is larger than the figure, as in Kansas, Michigan and
  # Arkansas. If that stops being true the sentence published about
  # Mississippi has to change.
  named <- sum(d$amount[d$distributed_to_hospital == "Yes"])
  if (sum(fb$amount) <= named) {
    stop("[MS] the unstated-form dollars ($",
         format(sum(fb$amount), big.mark = ",", nsmall = 2),
         ") no longer exceed the named-hospital floor ($",
         format(named, big.mark = ",", nsmall = 2),
         "). Re-word the finding before publishing it.", call. = FALSE)
  }
  invisible(TRUE)
}

#' §6.2: this release is RHTP, and it says so three ways
ms_assert_release_provenance <- function(body = NULL) {
  txt <- stringr::str_replace_all(ms_html_text("release", body), "\\s+", " ")

  # 1. The programme, named in the state's own sentence about these awards.
  want <- paste("Governor Tate Reeves today announced 167 awards totaling",
                "$104,115,146 through the Mississippi Rural Health",
                "Transformation Program")
  if (!stringr::str_detect(txt, stringr::fixed(want))) {
    stop("[MS] the release no longer ties these 167 awards to the Rural ",
         "Health Transformation Program in one sentence. That sentence is ",
         "the provenance; the CMS footer corroborates the AMOUNT and cannot ",
         "carry the programme on its own (session 27's audit).", call. = FALSE)
  }
  # 2. The CMS footer -- and its CMS SHARE, never its headline (session 44).
  share <- rhtp_footer_cms_share(txt)
  if (is.na(share) || abs(share - MS_ALLOTMENT) > 1) {
    stop("[MS] the release's CMS footer share (", share, ") is not ",
         "Mississippi's §7.1 allotment (", MS_ALLOTMENT, "). Mississippi's ",
         "footer is the only non-100%-federal one in this repository: its ",
         "HEADLINE is the allotment PLUS an $82,960 match and must never be ",
         "read as either a pool or the allotment.", call. = FALSE)
  }
  # 3. The date test -- nine months after the 2025-12-29 Notice of Award.
  if (MS_RELEASE_DATE <= MS_NOA_DATE) {
    stop("[MS] the release date does not postdate Mississippi's Notice of ",
         "Award.", call. = FALSE)
  }
  invisible(list(cms_share = share))
}

# -- the status table --------------------------------------------------------

ms_status_table <- function() {
  tibble::tribble(
    ~state, ~channel, ~stage, ~publishes_roster, ~award_date_published, ~note,
    MS_STATE, "Rural Capital Care Gap Closure (RCGC) - BRIDGE",
    "AWARDED_ROSTER_PUBLISHED", "Yes - 43 NAMED AND PRICED", "2026-09-14",
    paste("ANNOUNCED. 43 awards, $43,334,338.62, named and priced in the",
          "Governor's 2026-09-14 release. Holds BOTH odd-shape rows: the",
          "missing space before a hyphen (North Mississippi Medical Center,",
          "$2,500,000) and the organisation whose legal name contains ' - '",
          "(LIFECORE Health Group, $27,600)."),
    MS_STATE, "Rural Provider Technology Grant (RTG) - HTAM",
    "AWARDED_ROSTER_PUBLISHED", "Yes - 97 NAMED AND PRICED", "2026-09-14",
    paste("ANNOUNCED. 97 awards, $47,406,374.18 -- the largest of the three",
          "by count and by dollars."),
    MS_STATE, "Telehealth Hub Connectivity, Equipment & Education (TCE) - TAPS",
    "AWARDED_ROSTER_PUBLISHED", "Yes - 27 NAMED AND PRICED", "2026-09-14",
    paste("ANNOUNCED. 27 awards, $13,374,434. Carries the abbreviated-county",
          "row ('Lafayette Co.', $300,000) that a full-word anchor drops."),
    MS_STATE, "Workforce Expansion Initiative (WEI)",
    "CLOSED_AWARD_DATE_PUBLISHED_PENDING", "No", "2026-10-14 to 2026-10-29",
    paste("APPLICATIONS UNDER REVIEW AND MISSISSIPPI HAS NOW DATED IT. The",
          "2026-09-14 release says the workforce and psychiatric emergency",
          "services initiatives 'are currently being reviewed and will be",
          "announced in the next 30 to 45 days' -- so between 2026-10-14 and",
          "2026-10-29, derived from the release rather than typed. THIS IS",
          "THE NEXT TRANCHE and ms_assert_remaining_tranches() watches it."),
    MS_STATE, "Psychiatric Emergency Services - EmPATH Units - BRIDGE",
    "CLOSED_AWARD_DATE_PUBLISHED_PENDING", "No", "2026-10-14 to 2026-10-29",
    paste("The second half of the same sentence: 'currently being reviewed",
          "and will be announced in the next 30 to 45 days'."),
    MS_STATE, "October opportunities (care-gap innovation; EHR modernization)",
    "ANNOUNCED_NOT_YET_SOLICITED", "No", NA_character_,
    paste("'Additionally, in October, Mississippi will launch additional",
          "opportunities focused on innovative ways to close gaps in rural",
          "care and helping rural providers modernize the electronic health",
          "record systems they rely on every day.' Not yet open, so not yet",
          "a roster to watch -- but it is why Year 1 is PARTIAL."),
    MS_STATE, "EMS Capacity Assessment RFP",
    "CLOSED_NO_AWARD_DATE_PUBLISHED", "No", NA_character_,
    paste("Vendor RFP, closed 2026-07-24. A statewide EMS assessment, so a",
          "vendor award rather than a subaward when it lands."),
    MS_STATE, "Statewide Health Information Exchange consultant",
    "OPEN", "No", NA_character_,
    paste("MSDH procuring consulting services through the ITS Managed",
          "Services Provider Program, posting 162359. Vendor channel, open."),
    MS_STATE, "Governor Reeves newsroom (channel control)",
    "CARRIES_THE_RHTP_ANNOUNCEMENT", "Yes - THE 167-AWARD ROSTER", "2026-09-14",
    paste("THE CONTROL DELIVERED, AND ITS JOB HAS INVERTED. Session 44",
          "archived this page because it carried dated, priced award",
          "announcements and NO RHTP award, which is what made Mississippi's",
          "RHTP silence Mississippi's rather than our reading. It now carries",
          "'Governor Reeves Announces 167 Rural Health Transformation Program",
          "Awards Totaling More Than $104 Million'. The channel Mississippi",
          "named as where the announcement would come from is the channel it",
          "came from."),
    MS_STATE, "MS Division of Medicaid - Completed Procurements",
    "AWARDED_BUT_NOT_AN_RHTP_SUBAWARD", "Yes - FOR A PRE-NOA PROCUREMENT",
    "2025-08-13",
    paste("BOTH CONTROLS ON ONE PAGE. Ten 'Public Notice of Intent to Award'",
          "documents in a uniform form (positive control), and ONE",
          "RHTP-titled award: HORNE LLP, the consultant hired to help write",
          "the application, Public Notice of Award 2025-08-13 -- 138 days",
          "BEFORE the 2025-12-29 CMS Notice of Award. §6.2's date test",
          "disposes of it and session 20's sweep already flagged it",
          "PROVENANCE_PREDATES_NOA."),
    MS_STATE, "MS Division of Medicaid - RHTP programme page",
    "STALE", "No", NA_character_,
    paste("Still describes Mississippi as intending to 'submit a timely",
          "application' for a programme it was awarded in December 2025.",
          "Ohio's staleness on a second host: a stale page is not evidence",
          "of a stalled programme, and it is recorded rather than read.")
  )
}

ms_disposition <- function() {
  rt <- readRDS(here::here("data", "interim", "stage2_record_table.rds"))
  ms <- rt %>% dplyr::filter(.data$state == MS_STATE)
  t3 <- ms %>% dplyr::filter(.data$award_tier == "SUBAWARD")
  n_t3 <- nrow(t3)
  if (n_t3 != 3L) {
    stop("[MS] this disposition covers THREE Tier 3 candidates and the record ",
         "table now holds ", n_t3, ". Read the new ones before rebuilding ",
         "(§0.1 -- a disposition that does not cover its candidates is worse ",
         "than none).", call. = FALSE)
  }
  tibble::tribble(
    ~state, ~group, ~rcj_rows, ~disposition, ~evidence,
    MS_STATE, "RHTP planning consultant (Horne LLP)", 1L,
    "NOT_A_SUBAWARD_PREDATES_NOA",
    paste0("$150,000 to Horne LLP under 'Notice Of Contract Award RHTP - ",
           "Consultant Quotation #20250728 Emergency Contract #8400003450'. ",
           "GENUINELY RHTP-RELATED AND STILL NOT A SUBAWARD: DOM's own ",
           "Completed Procurements page shows 'Public Notice of Award - ",
           "8/13/2025' and 'the selection of HORNE LLP', which is 138 days ",
           "BEFORE Mississippi's 2025-12-29 Notice of Award. It is the ",
           "consultant hired to help WRITE THE APPLICATION; money the state ",
           "did not yet have cannot have funded it. Session 20's provenance ",
           "sweep already flagged this row PROVENANCE_PREDATES_NOA off the ",
           "document title's own date -- machine and hand agree."),
    MS_STATE, "Comprehensive State Health Plan RFP", 1L,
    "NOT_RHTP_STATE_PROCUREMENT",
    paste0("Premier Healthcare Solutions, Inc, amount $0, under 'Notice of ",
           "Intent to Award June 9, 2026 RFP RFx#3180002944 - Comprehensive ",
           "State Health Plan RFP'. An ordinary MSDH procurement for the ",
           "State Health Plan, which is a statutory planning document and ",
           "not an RHTP initiative. Indiana's appended-label shape: the ",
           "publisher is right, the programme label is the aggregator's."),
    MS_STATE, "Quality Incentive Payment Program (QIPP)", 1L,
    "NOT_RHTP_MEDICAID_AND_A_DOCUMENT_TITLE",
    paste0("$50,000,000 against an 'awardee' of 'QIPP PPHR, PPC, and AM-PPC ",
           "Presentation - July 2025' -- which is A DOCUMENT TITLE, not an ",
           "organisation (§6.1 PROGRAM_NAME_AS_AWARDEE). QIPP is ",
           "Mississippi's Quality Incentive Payment Program, a Medicaid ",
           "supplemental payment programme, and the deck is dated July 2025, ",
           "five months before the NOA. Two independent disqualifications ",
           "on one row.")
  )
}


# -- the live probe ----------------------------------------------------------

ms_probe <- function() {
  keys <- c("funding", "home", "gov_newsroom", "dom_completed")
  live <- purrr::map(keys, function(k) {
    r <- ms_get(ms_source(k, "url"), k); Sys.sleep(2); r
  })
  names(live) <- keys

  cmp <- purrr::map_dfr(keys, function(k) {
    tibble::tibble(
      key = k,
      archived_content = ms_content_digest(k),
      live_content = ms_content_digest(k, live[[k]]),
      archived_file = digest::digest(file = ms_path(k), algo = "sha256"),
      live_file = digest::digest(live[[k]], algo = "sha256",
                                 serialize = FALSE))
  }) %>%
    dplyr::mutate(content_changed = .data$archived_content != .data$live_content,
                  file_changed = .data$archived_file != .data$live_file)

  # The tripwires run against the LIVE bytes (session 25's Indiana lesson).
  ms_assert_remaining_tranches(bodies = live)
  ms_assert_selection_complete_unnamed(body = live$funding)
  ms_assert_footer_is_not_fully_federal(body = live$funding)
  ms_assert_announcement_on_channel(body = live$gov_newsroom)
  ms_assert_dom_consultant_predates_noa(body = live$dom_completed)

  # THE NAME TRIPWIRE (§2.3, session 48). The phrase assertions above ask HOW
  # this page is worded; this asks WHOM it names, against the committed
  # archive. New Mexico is why it exists: HCA named six Regional Hubs and not
  # one of its ten award phrases matched. Subject pages only -- a control or a
  # press index moves for reasons that are not this state awarding.
  nm_keys <- c("funding", "home")
  rhtp_assert_no_new_organisations_across(
    live = stats::setNames(
      purrr::map(nm_keys, function(k) ms_html_text(k, live[[k]])), nm_keys),
    archived = stats::setNames(purrr::map(nm_keys, ms_html_text), nm_keys),
    state = "MS")

  message("[MS] live probe ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " UTC")
  purrr::walk(seq_len(nrow(cmp)), function(i) {
    r <- cmp[i, ]
    message(sprintf("  %-14s content %s   file %s", r$key,
                    if (r$content_changed) "CHANGED" else "unchanged",
                    if (r$file_changed) "differs" else "unchanged"))
  })
  if (any(cmp$content_changed)) {
    message("[MS] CONTENT CHANGED on: ",
            paste(cmp$key[cmp$content_changed], collapse = ", "),
            ". Re-fetch and READ -- Mississippi has promised to announce its ",
            "executed sub-awards, so a change here is the thing this Routine ",
            "exists for.")
  } else {
    message("[MS] UNCHANGED. Selection is still complete and Mississippi has ",
            "still named nobody.")
  }
  invisible(cmp)
}


# -- validate / build / report -----------------------------------------------

ms_validate <- function() {
  if (!ms_have_archive()) {
    stop("[MS] the evidence archive is incomplete; run --fetch first.",
         call. = FALSE)
  }
  ms_assert_remaining_tranches()
  ms_assert_selection_complete_unnamed()
  ms_assert_footer_is_not_fully_federal()
  ms_assert_footer_cms_share_is_the_allotment()
  ms_assert_announcement_on_channel()
  ms_assert_dom_consultant_predates_noa()
  # The roster.
  d <- ms_parse_release()
  ms_assert_odd_shape_rows(d)
  ms_assert_reconciles(d)
  ms_assert_release_provenance()
  aw <- ms_year1_awardees(d)
  ms_assert_nothing_promoted(aw)
  ms_assert_form_not_stated_queued(aw)
  message("[MS] all assertions pass.")
  invisible(TRUE)
}

ms_build <- function() {
  d <- ms_parse_release()
  ms_assert_odd_shape_rows(d)
  ms_assert_reconciles(d)
  aw <- ms_year1_awardees(d)
  ms_assert_nothing_promoted(aw)
  ms_assert_form_not_stated_queued(aw)
  readr::write_csv(aw, MS_AWARDEES_CSV)
  message("[MS] wrote ", MS_AWARDEES_CSV, " (", nrow(aw), " award actions, $",
          format(sum(aw$amount), big.mark = ",", nsmall = 2), ")")

  st <- ms_status_table()
  if ("amount" %in% names(st)) {
    stop("[MS] ms_year1_status.csv must STILL have no amount column. The ",
         "per-recipient money lives in ms_year1_awardees.csv; a status table ",
         "that acquires an amount column is two files claiming one figure ",
         "(Texas's device, and Arkansas's reason for keeping its project ",
         "file out of the union).", call. = FALSE)
  }
  readr::write_csv(st, MS_STATUS_CSV)
  message("[MS] wrote ", MS_STATUS_CSV, " (", nrow(st), " rows)")
  dp <- ms_disposition()
  readr::write_csv(dp, MS_DISPO_CSV)
  message("[MS] wrote ", MS_DISPO_CSV, " (", nrow(dp), " rows)")
  invisible(list(awards = aw, status = st, disposition = dp))
}

ms_report <- function() {
  st <- ms_status_table()
  d  <- ms_year1_awardees()
  part <- rhtp_hospital_dollar_partition(d)
  fb <- d %>% dplyr::filter(.data$flag_reason == "RECIPIENT_TYPE_INFERRED")
  floor_d <- sum(d$amount[d$distributed_to_hospital == "Yes"])

  cat("\nMISSISSIPPI -- 167 AWARDS ANNOUNCED, NAMED AND PRICED\n")
  cat(strrep("=", 72), "\n\n")
  cat("Allotment (§7.1)        : $", format(MS_ALLOTMENT, big.mark = ","),
      "\n", sep = "")
  cat("Year 1 budget (stated)  : $205.9 million\n")
  cat("Announced 2026-09-14    : ", nrow(d), " award actions, $",
      formatC(sum(d$amount), format = "f", digits = 2, big.mark = ","),
      "  (", round(100 * sum(d$amount) / MS_ALLOTMENT, 1), "% of allotment)\n",
      sep = "")
  cat("Distinct awardee strings: ", dplyr::n_distinct(d$awardee),
      "   <- 167 ACTIONS, not 167 organisations (Michigan's grain)\n", sep = "")
  cat("\n")
  print(as.data.frame(ms_reconcile()), row.names = FALSE)
  cat("\nThe 167 sum to $104,115,146.80 and the Governor states $104,115,146.\n")
  cat("The $0.80 is TRUNCATION -- nine rows carry cents summing to $3.80 --\n")
  cat("and NEITHER figure is corrected (§8).\n")

  cat("\nTHE TWO ODD-SHAPE ROWS, AND ONLY ONE COSTS A DOLLAR:\n")
  cat("  RCGC 23  'Lee County-'  missing the space before the hyphen.\n")
  cat("           A ' - ' split DROPS the row: 166 awards, -$2,500,000,\n")
  cat("           and the largest RCGC award. THE TOTAL CATCHES THIS.\n")
  cat("  RCGC 30  'Northeast Mental Health - Mental Retardation Commission\n")
  cat("           d.b.a. LIFECORE Health Group' -- the ORGANISATION'S NAME\n")
  cat("           contains ' - '. A left-to-right split reads the awardee as\n")
  cat("           'Northeast Mental Health' and the COUNTY as the rest.\n")
  cat("           THE MONEY IS UNTOUCHED AND NO TOTAL EVER NOTICES.\n")
  cat("  (plus 'Lafayette Co.', which a full-word anchor drops: -$300,000)\n")

  cat("\nHOSPITAL DOLLARS\n")
  print(as.data.frame(part), row.names = FALSE)
  cat("\n  FLOOR   $", formatC(floor_d, format = "f", digits = 2,
                               big.mark = ","),
      " across ", sum(d$distributed_to_hospital == "Yes"),
      " named-hospital award actions\n", sep = "")
  cat("  QUEUED  $", formatC(sum(fb$amount), format = "f", digits = 2,
                             big.mark = ","),
      " across ", nrow(fb), " rows on §8's standing fallback\n", sep = "")
  cat("  CEILING $", formatC(floor_d + sum(fb$amount), format = "f",
                             digits = 2, big.mark = ","),
      " -- the uncertainty is ONE-DIRECTIONAL (every\n", sep = "")
  cat("          fallback row is already No), so the floor is genuine.\n")
  cat("  NOTHING WAS PROMOTED (§0.4). The CCN match resolves it.\n")

  cat("\nTHE FOOTER, WHICH IS THE FIRST HERE THAT IS NOT 100% FEDERAL:\n")
  cat("  headline   $", formatC(MS_FOOTER_HEADLINE, format = "f", digits = 2,
                                big.mark = ","),
      "   <- federal PLUS a match; NOT the allotment and NOT a pool\n", sep = "")
  cat("  CMS share  $", formatC(MS_FOOTER_CMS_SHARE, format = "f", digits = 2,
                                big.mark = ","),
      "   <- 99.96%, and the §7.1 anchor to the dollar\n", sep = "")
  cat("  match      $", formatC(MS_FOOTER_NONFEDERAL, format = "f", digits = 2,
                                big.mark = ","),
      "   <- 0.04%, and EIGHT TIMES the $10,000 margin\n", sep = "")
  cat("\nPARSE THE CMS SHARE, NEVER THE HEADLINE, AND DO NOT WIDEN THE MARGIN.\n")

  cat("\nTHE YEAR IS PARTIAL AND MISSISSIPPI DATES THE REST ITSELF:\n")
  cat("  Workforce Expansion + Psychiatric Emergency Services --\n")
  cat("  'currently being reviewed and will be announced in the next 30 to\n")
  cat("  45 days' from 2026-09-14, so 2026-10-14 .. 2026-10-29.\n")
  cat("  Plus two OCTOBER opportunities not yet opened.\n")
  cat("  $", formatC(MS_ALLOTMENT - sum(d$amount), format = "f", digits = 0,
                     big.mark = ","),
      " of the allotment is in no public roster.\n", sep = "")
  cat("\n")
  print(as.data.frame(st[, c("channel", "stage", "publishes_roster")]),
        row.names = FALSE)
  invisible(list(status = st, awards = d, partition = part))
}


if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) ms_fetch(force = "--force" %in% args)
  if ("--validate" %in% args) ms_validate()
  if ("--build" %in% args) ms_build()
  if ("--probe" %in% args) rhtp_probe_run("MS", ms_probe())
  if ("--report" %in% args) ms_report()
  if (!length(args)) {
    message("Usage: --fetch [--force] | --validate | --build | --probe | --report")
  }
}
