#!/usr/bin/env Rscript
# 03ak_ms_year1_probe.R ------------------------------------------------------
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
#   Rscript R/03ak_ms_year1_probe.R --fetch [--force]
#   Rscript R/03ak_ms_year1_probe.R --validate
#   Rscript R/03ak_ms_year1_probe.R --build
#   Rscript R/03ak_ms_year1_probe.R --probe
#   Rscript R/03ak_ms_year1_probe.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
  library(purrr); library(httr); library(digest); library(here); library(rlang)
})

source(here::here("R", "utils_config.R"))

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
  "funding",
  "https://mississippirhtp.com/funding/",
  "2026-09-03_ms_rhtp_funding.html",
  paste("THE PAGE THIS FILE IS ABOUT. 'The selection process is complete'",
        "for RCGC, RTG and TCE; sub-awards executing by email; the Governor",
        "'will formally announce details regarding all executed sub-awards'.",
        "And the footer that is 99.96% federal."),
  "home",
  "https://mississippirhtp.com/",
  "2026-09-03_ms_rhtp_home.html",
  paste("The programme home page. Five initiatives (CRIS, WEI, HTAM, TAPS,",
        "BRIDGE) and no recipient named."),
  "gov_newsroom",
  "https://governorreeves.ms.gov/newsroom/",
  "2026-09-03_ms_governor_newsroom.html",
  paste("THE POSITIVE CONTROL, and the channel Mississippi itself named as",
        "where the announcement will come from. Carries dated, priced award",
        "announcements and no RHTP award."),
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
    "Fetched 2026-09-03 by R/03ak_ms_year1_probe.R --fetch.",
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

#' Mississippi has named no sub-award recipient on any watched surface
ms_assert_no_roster <- function(bodies = NULL) {
  for (k in c("funding", "home", "gov_newsroom")) {
    txt <- ms_html_text(k, if (!is.null(bodies)) bodies[[k]] else NULL)
    found <- ms_award_language(txt)
    if (length(found)) {
      stop("[MS] award language has appeared on '", k, "': ",
           paste(sQuote(found), collapse = ", "),
           ". Mississippi promised to announce its executed sub-awards -- it ",
           "may have. This file must be REWRITTEN as an award extractor, not ",
           "patched: ms_year1_status.csv has no amount column by design.",
           call. = FALSE)
    }
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

#' The Governor's newsroom publishes awards, and none of them is RHTP
#'
#' THE CONTROL THAT MAKES THE SILENCE MEAN SOMETHING, and it is the channel
#' Mississippi's own funding page names as the one it will use.
ms_assert_governor_channel_control <- function(body = NULL) {
  txt <- ms_html_text("gov_newsroom", body)
  lines <- stringr::str_split(txt, "\n")[[1]]
  award_shaped <- lines[stringr::str_detect(
    lines, stringr::regex("announce", ignore_case = TRUE))]
  if (length(award_shaped) < 3L) {
    stop("[MS] the Governor's newsroom carries only ", length(award_shaped),
         " announcement headlines. The control that makes Mississippi's ",
         "silence meaningful is gone; re-establish it before reporting the ",
         "negative.", call. = FALSE)
  }
  rhtp_items <- lines[stringr::str_detect(
    lines, stringr::regex("rural health transformation|RHTP",
                          ignore_case = TRUE))]
  awardish <- rhtp_items[stringr::str_detect(
    rhtp_items, stringr::regex("award|recipient|sub-?award",
                               ignore_case = TRUE))]
  if (length(awardish)) {
    stop("[MS] an RHTP item on the Governor's newsroom now reads as an AWARD: ",
         paste(sQuote(awardish), collapse = "; "),
         ". This is the announcement Mississippi promised -- read it.",
         call. = FALSE)
  }
  invisible(list(announcements = length(award_shaped),
                 rhtp_items = length(rhtp_items)))
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


# -- the status table --------------------------------------------------------

ms_status_table <- function() {
  tibble::tribble(
    ~state, ~channel, ~stage, ~publishes_roster, ~award_date_published, ~note,
    MS_STATE, "Rural Capital Care Gap Closure (RCGC) - BRIDGE",
    "SELECTED_NOT_ANNOUNCED", "No", NA_character_,
    paste("Applications closed 2026-07-15. 'The selection process is",
          "complete'; selected applicants contacted BY EMAIL to begin",
          "sub-award execution. NO recipient named. The Governor 'will",
          "formally announce details regarding all executed sub-awards in the",
          "coming weeks'."),
    MS_STATE, "Rural Provider Technology Grant (RTG) - HTAM",
    "SELECTED_NOT_ANNOUNCED", "No", NA_character_,
    paste("Applications closed 2026-07-15. Selection complete, recipients",
          "notified by email, NOBODY NAMED."),
    MS_STATE, "Telehealth Hub Connectivity, Equipment & Education (TCE) - TAPS",
    "SELECTED_NOT_ANNOUNCED", "No", NA_character_,
    paste("Applications closed 2026-07-15. Selection complete, recipients",
          "notified by email, NOBODY NAMED."),
    MS_STATE, "Workforce Expansion Initiative (WEI)",
    "CLOSED_NO_AWARD_DATE_PUBLISHED", "No", NA_character_,
    paste("Applications closed 2026-08-17. Mississippi publishes no award",
          "date for it and the funding page's completion sentence does NOT",
          "name it -- Missouri's and North Carolina's footing."),
    MS_STATE, "Psychiatric Emergency Services - EmPATH Units - BRIDGE",
    "CLOSED_NO_AWARD_DATE_PUBLISHED", "No", NA_character_,
    paste("Applications closed 2026-08-17. Not among the three programmes",
          "whose selection is complete."),
    MS_STATE, "EMS Capacity Assessment RFP",
    "CLOSED_NO_AWARD_DATE_PUBLISHED", "No", NA_character_,
    paste("Vendor RFP, closed 2026-07-24. A statewide EMS assessment, so a",
          "vendor award rather than a subaward when it lands."),
    MS_STATE, "Statewide Health Information Exchange consultant",
    "OPEN", "No", NA_character_,
    paste("MSDH procuring consulting services through the ITS Managed",
          "Services Provider Program, posting 162359. Vendor channel, open."),
    MS_STATE, "Governor Reeves newsroom (channel control)",
    "PUBLISHES_AWARDS_FOR_OTHER_PROGRAMMES", "Yes - FOR OTHER PROGRAMMES",
    NA_character_,
    paste("THE POSITIVE CONTROL, and the channel Mississippi itself named.",
          "Carries dated, priced award announcements ('deploying $3,375,709'",
          "for youth mental health, 2026-08-24) and NO RHTP award."),
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
  ms_assert_no_roster(bodies = live)
  ms_assert_selection_complete_unnamed(body = live$funding)
  ms_assert_footer_is_not_fully_federal(body = live$funding)
  ms_assert_governor_channel_control(body = live$gov_newsroom)
  ms_assert_dom_consultant_predates_noa(body = live$dom_completed)

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
  ms_assert_no_roster()
  ms_assert_selection_complete_unnamed()
  ms_assert_footer_is_not_fully_federal()
  ms_assert_footer_cms_share_is_the_allotment()
  ms_assert_governor_channel_control()
  ms_assert_dom_consultant_predates_noa()
  message("[MS] all assertions pass.")
  invisible(TRUE)
}

ms_build <- function() {
  st <- ms_status_table()
  if ("amount" %in% names(st)) {
    stop("[MS] ms_year1_status.csv must have NO amount column: Mississippi ",
         "has named no recipient and published no per-recipient figure.",
         call. = FALSE)
  }
  readr::write_csv(st, MS_STATUS_CSV)
  message("[MS] wrote ", MS_STATUS_CSV, " (", nrow(st), " rows)")
  d <- ms_disposition()
  readr::write_csv(d, MS_DISPO_CSV)
  message("[MS] wrote ", MS_DISPO_CSV, " (", nrow(d), " rows)")
  invisible(list(status = st, disposition = d))
}

ms_report <- function() {
  st <- ms_status_table()
  cat("\nMISSISSIPPI -- selection COMPLETE, announcement PROMISED, nobody named\n")
  cat(strrep("=", 72), "\n\n")
  cat("Allotment (§7.1)        : $", format(MS_ALLOTMENT, big.mark = ","),
      "\n", sep = "")
  cat("Recipient-level awards  : NONE PUBLISHED\n")
  cat("RCJ Tier 3 candidates   : 3, and not one is an RHTP subaward\n\n")
  print(as.data.frame(st[, c("channel", "stage", "publishes_roster")]),
        row.names = FALSE)
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
  cat("\nTHE CLOCK: 'The first awards are expected by the end of the month'\n")
  cat("(third-party reporting, 2026-08-06). Today is ", format(Sys.Date()),
      ".\n", sep = "")
  invisible(st)
}


if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) ms_fetch(force = "--force" %in% args)
  if ("--validate" %in% args) ms_validate()
  if ("--build" %in% args) ms_build()
  if ("--probe" %in% args) ms_probe()
  if ("--report" %in% args) ms_report()
  if (!length(args)) {
    message("Usage: --fetch [--force] | --validate | --build | --probe | --report")
  }
}
