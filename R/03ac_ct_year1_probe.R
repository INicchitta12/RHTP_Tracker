#!/usr/bin/env Rscript
# 03ac_ct_year1_probe.R -------------------------------------------------------
#
# CONNECTICUT -- RHTP Year 1. A NEGATIVE, and the first one this project has met
# whose award date is ALREADY IN THE PAST. Connecticut led the RCJ_ONLY queue
# jointly with New Mexico at 7 Tier 3 candidates, and NOT ONE of the seven is a
# subaward: all seven are BUDGET-NARRATIVE LINE ITEMS whose "awardee" is the
# administering state agency. Oklahoma's defect -- the wrong TIER.
#
# WHAT CONNECTICUT HAS PUBLISHED.
#
#   DSS is the lead agency for a $154,249,105.53 Budget Period 1 award and is
#   "partnering with other state agencies to implement 30 projects" across four
#   initiatives. Its RHTP Documents page carries EIGHT documents -- the
#   application, the Governor's endorsement, the Notice of Award, the project
#   narrative, the budget narrative, project summaries, overview slides and two
#   webinars -- and NOT ONE OF THEM IS AN AWARD ROSTER.
#
#   ONE RECIPIENT-LEVEL SOLICITATION HAS RUN, AND ITS AWARD DATE HAS PASSED.
#   OHS's NOFO #26OHS001 (Health Care Coordination and Remote Patient
#   Monitoring Using Artificial Intelligence) offers $1.8 million in Year 1,
#   "up to 5 grant awards", "$100,000 to $1,000,000" each. Applications closed
#   JULY 7, 2026 at 2:00 PM ET, and OPM's own published timeline gives
#   "Grant Awards Announced ... AUGUST 17, 2026". THIS FILE RAN 2026-09-02 --
#   SIXTEEN DAYS AFTER THAT DATE -- AND NO ROSTER EXISTS ON ANY REACHABLE
#   CONNECTICUT HOST. Wisconsin's negative was dated to a month in the future;
#   California's to the fortnight it ran in; Connecticut's date has gone by.
#
#   AND THE STATE SAYS IN ITS OWN WORDS THAT NOBODY HAS BEEN CHOSEN: "Parties
#   interested in being subrecipients of RHTP funding are encouraged to check
#   back here on this webpage regularly for updates, as well as the state
#   procurement website/portal and other standard channels for potential
#   funding opportunities."
#
# §6.2 IN ITS STRONGEST FORM -- THE THIRD STATE TO PUBLISH CMS'S OWN NOTICE OF
# AWARD, after Nevada (session 26) and California (session 34). Not a footer
# quoting an award: the award. `noa_rhtcms332073-01-03.pdf` is CMS's own form --
# recipient DEPARTMENT OF SOCIAL SERVICES CONNECTICUT, Assistance Listing
# 93.798 Rural Health Transformation Program, Award# RHTCMS332073-01-03,
# budget period 12/29/2025 - 10/30/2026, $154,249,105.53, statutory authority
# "Big Beautiful Bill Act of 2025, Section 71401".
#
# AND CALIFORNIA'S TWO-DATES TRAP, A SECOND TIME AND WIDER. The NOA's Federal
# Award Date is 07/23/2026 and its Award Action Type is "Revision (Budget)",
# while the budget period still starts 12/29/2025. California's revision was
# three months after the award; Connecticut's is SEVEN. A date test keyed on
# "Federal Award Date" would read Connecticut's award as seven months late and
# quarantine every genuine Connecticut row as PROVENANCE_PREDATES_NOA. The
# project's anchor is and remains the budget-period start.
#
# ONE CLOSURE, UNARRANGED. The NOA names "Mr. Daniel Mize Sinclair, Director,
# Rural Health Transformation Program" and "Julie Vigil, Deputy Director" as
# the state's officials; DSS's own press release of 2026-04-10 names Daniel
# Sinclair as Project Director and Julie Vigil as Deputy Director of
# Operations. Two publishers, one federal and one state, nothing arranged.
#
# THE FOOTER IS THE WEAK FORM AND IS DEMOTED ANYWAY (session 27's audit).
# Connecticut's reads "This PROJECT is supported by ... $154,249,105.53 in
# Budget Period 1" -- a claim about the paper, not the programme. It is used
# for the AMOUNT only, where it matches the §7.1 anchor ($154,249,106) to the
# cent, and `strict = FALSE` is the same switch Kansas, New Hampshire,
# Wisconsin and California already carry. Two programme-scoped sentences carry
# the provenance.
#
# §0.1 -- OKLAHOMA'S DEFECT, AND A MECHANISM THIS PROJECT HAD NOT RECORDED.
# All seven Connecticut Tier 3 candidates come from ONE document in TWO
# REVISIONS -- Connecticut's RHT Budget Narrative -- and their "awardees" are
# the implementing agencies and named budget columns:
#
#   * FOUR ARE STATE AGENCIES: the Department of Public Health ($21,714,915),
#     the Office of Health Strategy ($7,689,978) and the Department of Mental
#     Health and Addiction Services (twice, $5,749,236 and $5,600,000). The
#     narrative's own section heading for each is "<agency> -- Required
#     reporting information for SUBRECIPIENT", i.e. the pass-through structure
#     INSIDE state government, one tier above any provider.
#   * ONE IS A PROPOSAL NAME: "Area Health Education Center (AHEC)",
#     $1,500,000, which the narrative prints as "Proposal: W03-Area Health
#     Education Center (AHEC) Expansion" with "Contractor 1 AHEC" as a budget
#     COLUMN HEADING. §6.1's PROGRAM_NAME_AS_AWARDEE.
#   * TWO ARE ONE PLANNED CONTRACTOR: Carelon Behavioral Health, Inc.,
#     $3,800,000, twice -- printed as "Contractor 1 Carelon Behavioral Health,
#     Inc." in an itemised budget justification.
#
# AND THE NEW MECHANISM IS THE DOUBLE-COUNTING: RCJ PRICES DOCUMENT REVISIONS
# AS SEPARATE AWARDS. Connecticut published the narrative twice; RCJ carries
# Carelon's single $3,800,000 line from BOTH revisions as two candidates, and
# carries DMHAS's adult mental health line at TWO DIFFERENT AMOUNTS --
# $5,749,236 from one revision and $5,600,000 from the other. New Hampshire's
# CDFA appeared under three spellings at three prices (session 29); Connecticut
# is the same failure caused by REVISION rather than by spelling, and it is the
# cleaner case because the underlying document is provably one line item.
#
# THE NARRATIVE SAYS IN ITS OWN WORDS THAT IT IS A PLAN. "Personnel salaries
# will be updated ONCE AWARDED." Its contractor lists end "and Similar"; one
# names "Rural Community Mental Health Services Provider(s) TBD"; its summary
# table is headed "Proposal". Nothing in it is an award action.
#
# THE POSITIVE CONTROL IS THE CHANNEL, AND IT IS OHS'S. OHS demonstrably
# publishes named, recipient-level decisions in a recognisable form -- "Office
# of Health Strategy Approves UCONN Health Affiliate's Acquisition of Waterbury
# Hospital", "Approves Hartford HealthCare Subsidiary's Acquisition of Eastern
# Connecticut Hospital". So "Connecticut has published no RHTP roster" is a
# statement about the programme and not about our reading. What OHS's press
# room carries for RHTP is FOUR items and every one is pre-award: the NOFO, its
# legal notice, and two rounds of Q&A.
#
# THE NEGATIVE CONTROL IS DSS'S ONLY RHTP PRESS RELEASE, AND IT IS GOVERNANCE.
# "Connecticut Department of Social Services announces LEADERSHIP TEAM for new
# Rural Health Transformation Program" (2026-04-10) names FOUR PEOPLE. Missouri
# published a governance roster of 27 ORGANISATIONS and RCJ priced all of them
# at $1 (session 28); Connecticut's governance announcement is one tier further
# from money still, and it is the only thing DSS has announced about RHTP.
#
# ONE CHANNEL IS UNREADABLE AND IS RECORDED AS UNKNOWN, NOT AS A NEGATIVE
# (§0.4). The state directs subrecipients to the CTsource Contracting Portal.
# `portal.ct.gov/das/ctsource/bidboard` answers 200 but is a landing page onto
# an external stateful application this environment cannot search -- Maine's
# CGI Advantage portal, on a different vendor. Whether an RHTP award has been
# posted inside CTsource is a statement about OUR ACCESS, never about
# Connecticut. `biznet.ct.gov` answers 403 to the project's agent.
#
# THE HOST'S DIGEST MECHANISM IS THE FIFTH THIS PROJECT HAS MET AND THE FIRST
# THAT IS PER-NODE RATHER THAN PER-REQUEST. `portal.ct.gov` stamps a
# cache-busting `?v=<yyyymmddHHMMSS>` on seven static asset URLs, and the value
# is the SERVING NODE'S asset build time: six fetches of one page returned
# 80,531 bytes every time under FIVE DISTINCT file digests, one of which
# repeated. So it is not random per request (Missouri's Incapsula), not a
# script body nonce (Wisconsin's Boomerang), not rotating page content
# (Nevada's widget), and not a cache variant of differing length
# (California's). It is a small finite set of values, one per node.
#
# AND THAT MAKES CALIFORNIA'S LESSON SHARPER RATHER THAN MERELY REPEATING IT.
# A back-to-back pair run against TWO PAGES OF THIS ONE HOST gave SAME on the
# DSS programme page and DIFFER on the OPM page in the same minute: whether the
# pair catches it depends on which node answers, so a "SAME" result is not
# evidence of stability even for the page it was run on. `--probe` therefore
# compares a CONTENT digest via `ct_reduce_html()` -- the reduced text was
# IDENTICAL across all six fetches at 8,983 characters -- and it is the same
# reduction the assertions read (Missouri's rule, session 29).
#
# CLI:
#   --fetch [--force]  archive the 10 sources + SHA-256 manifest
#   --validate         every assertion, offline
#   --build            write the two status/disposition CSVs (NO award file)
#   --probe            LIVE: has Connecticut awarded yet?
#   --report           the negative, and the award date that has already passed
#
# Sessions: 35.

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(stringr)
  library(purrr)
})

source(here::here("R", "utils_config.R"))

CT_EVIDENCE_DIR <- here::here("data", "evidence", "CT")
CT_STATUS_CSV   <- "data/reference/ct_year1_status.csv"
CT_DISPO_CSV    <- "data/reference/ct_rcj_candidate_disposition.csv"
CT_AWARDS_CSV   <- "data/reference/ct_year1_awardees.csv"   # MUST NOT EXIST
CT_HOST_THROTTLE_S <- 3

# portal.ct.gov answers the project's honest agent with HTTP 200 on every path
# used here, and robots.txt is 200, so §3's michigan.gov exception is not
# reached and must not be.
CT_USER_AGENT <- paste(
  "AHA-RHTP-Tracker/0.1 (+https://www.aha.org;",
  "contact: AHA Data and Policy; R httr2)"
)

CT_MEDIA <- paste0("https://portal.ct.gov/dss/-/media/departments-and-agencies",
                   "/dss/health-and-home-care/rural-health-transformation-program")

CT_SOURCES <- tibble::tribble(
  ~key, ~file, ~url,

  "programme",
  "2026-09-02_ct_dss_rhtp_programme.html",
  "https://portal.ct.gov/dss/rural-health-transformation-program",

  "documents",
  "2026-09-02_ct_dss_rhtp_documents.html",
  "https://portal.ct.gov/dss/rural-health-transformation-program/documents",

  "noa",
  "2026-09-02_ct_cms_notice_of_award.pdf",
  paste0(CT_MEDIA, "/noa_rhtcms332073-01-03.pdf",
         "?rev=fec7066513854feca52987937e0eb67f",
         "&hash=F4AD4E87D13284D3DBD0E0FB8B3446EC"),

  "budget",
  "2026-09-02_ct_dss_rht_budget_narrative_20260407.pdf",
  paste0(CT_MEDIA, "/ct-rhtp-budget-narrative-updated-472026.pdf",
         "?rev=766d4389024a417b8dc2e7ffb07a5e49",
         "&hash=5649EA543D42A859DC5A3A73FB0FED1D"),

  "nofo",
  "2026-09-02_ct_ohs_nofo_26ohs001_release.html",
  paste0("https://portal.ct.gov/ohs/press-room/press-releases/",
         "2025-press-releases/",
         "notice-of-funding-opportunity-rural-health-transformation-program"),

  "opm",
  "2026-09-02_ct_opm_rfp_index_AWARD_DATE_PASSED.html",
  "https://portal.ct.gov/opm/root/rfp/request-for-proposals",

  "leadership",
  "2026-09-02_ct_dss_leadership_team_NEGATIVE_CONTROL.html",
  paste0("https://portal.ct.gov/dss/press-room/press-releases/",
         "ct-dss-announces-leadership-team-for-new-",
         "rural-health-transformation-program"),

  "ohs_press",
  "2026-09-02_ct_ohs_press_index_CONTROL.html",
  "https://portal.ct.gov/ohs/press-room/press-releases",

  "dss_press",
  "2026-09-02_ct_dss_press_index.html",
  "https://portal.ct.gov/dss/press-room/press-releases",

  "ctsource",
  "2026-09-02_ct_das_ctsource_bidboard_UNREADABLE.html",
  "https://portal.ct.gov/das/ctsource/bidboard"
)

# Every figure Connecticut states, in its own words, read rather than typed
# where the document supports it. These are the state's numbers, not ours.
CT_STATED <- list(
  footer_amount   = "$154,249,105.53",
  noa_award_num   = "RHTCMS332073-01-03",
  noa_listing     = "93.798",
  noa_bp_start    = "12/29/2025",
  noa_bp_end      = "10/30/2026",
  noa_award_date  = "07/23/2026",
  noa_action_type = "Revision (Budget)",
  nofo_number     = "#26OHS001",
  nofo_pool       = "A total of $1.8 million is available in Year 1",
  nofo_ceiling    = "Individual awards will range from $100,000 to $1,000,000",
  nofo_count      = "OHS anticipates making up to 5 grant awards for year 1",
  nofo_due        = "July 7, 2026, 2:00 PM ET",
  award_announced = "August 17, 2026",
  projects        = 30L
)

# THE AWARD DATE CONNECTICUT PUBLISHED FOR ITSELF, and the date this file was
# taken. Kept as data so the report can state the gap rather than assert a
# constant nobody re-reads.
CT_AWARD_DATE   <- as.Date("2026-08-17")
CT_ARCHIVE_DATE <- as.Date("2026-09-02")

CT_CREDENTIAL_SHAPES <- c(
  mapbox_token   = "[ps]k\\.ey[A-Za-z0-9_-]{10,}",
  google_api_key = "AIza[A-Za-z0-9_-]{30,}",
  bearer_token   = "(?i)bearer\\s+[A-Za-z0-9._-]{25,}",
  aws_key        = "AKIA[A-Z0-9]{12,}"
)


# -- fetch --------------------------------------------------------------------

ct_path <- function(key) {
  row <- CT_SOURCES[CT_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[CT] unknown source key: ", key, call. = FALSE)
  file.path(CT_EVIDENCE_DIR, row$file)
}

ct_source <- function(key, field) {
  row <- CT_SOURCES[CT_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[CT] unknown source key: ", key, call. = FALSE)
  row[[field]]
}

ct_assert_credential_free <- function(body, label) {
  chunk <- body[seq_len(min(length(body), 4e6))]
  txt   <- rawToChar(chunk[chunk != as.raw(0)])
  Encoding(txt) <- "latin1"
  for (nm in names(CT_CREDENTIAL_SHAPES)) {
    if (stringr::str_detect(txt, CT_CREDENTIAL_SHAPES[[nm]])) {
      stop("[CT] refusing to archive ", label, ": it carries what looks like ",
           "a ", nm, ".", call. = FALSE)
    }
  }
  invisible(TRUE)
}

ct_get <- function(url, label) {
  message("[CT] fetching ", url)
  resp <- httr::GET(url, httr::user_agent(CT_USER_AGENT),
                    httr::config(followlocation = TRUE), httr::timeout(240))
  if (httr::status_code(resp) != 200L) {
    stop("[CT] HTTP ", httr::status_code(resp), " for ", url, call. = FALSE)
  }
  served <- httr::content(resp, as = "raw")
  ct_assert_credential_free(served, label)
  served
}

ct_fetch <- function(force = FALSE) {
  dir.create(CT_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  entries <- purrr::map_dfr(seq_len(nrow(CT_SOURCES)), function(i) {
    src  <- CT_SOURCES[i, ]
    dest <- file.path(CT_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[CT] cached, not re-fetched: ", src$file)
    } else {
      if (i > 1L) Sys.sleep(CT_HOST_THROTTLE_S)
      writeBin(ct_get(src$url, src$file), dest)
    }
    tibble::tibble(file = src$file, url = src$url, bytes = file.size(dest),
                   sha256 = digest::digest(file = dest, algo = "sha256"))
  })
  ct_write_manifest(entries)
  invisible(entries)
}

ct_write_manifest <- function(entries) {
  path <- file.path(CT_EVIDENCE_DIR, "MANIFEST.txt")
  writeLines(c(
    "Connecticut -- Rural Health Transformation Program, Year 1.",
    "Archived by R/03ac_ct_year1_probe.R --fetch",
    paste0("User-agent: ", CT_USER_AGENT),
    "",
    "Every file is the body the server sent, BYTE FOR BYTE, written with",
    "writeBin(), so re-hashing a file on disk reproduces its digest below.",
    "The credential guard runs on every fetch and finds nothing, so there is",
    "no reduction to explain.",
    "",
    "CONNECTICUT HAS PUBLISHED NO RECIPIENT-LEVEL RHTP AWARD LIST, AND ITS OWN",
    "AWARD DATE HAS ALREADY PASSED. OHS's NOFO #26OHS001 closed to",
    "applications on JULY 7, 2026, and OPM's published timeline gives 'Grant",
    "Awards Announced ... August 17, 2026'. This archive was taken 2026-09-02,",
    "SIXTEEN DAYS LATER, and no roster exists on any reachable state host.",
    "DSS's RHTP Documents page carries eight documents and not one is a",
    "roster.",
    "",
    "THE §6.2 ANCHOR IS CMS'S OWN NOTICE OF AWARD, NOT A FOOTER QUOTING ONE.",
    "  2026-09-02_ct_cms_notice_of_award.pdf is CMS's own form: recipient",
    "  DEPARTMENT OF SOCIAL SERVICES CONNECTICUT, Assistance Listing 93.798",
    "  Rural Health Transformation Program, Award# RHTCMS332073-01-03, budget",
    "  period 12/29/2025 - 10/30/2026, $154,249,105.53. Connecticut is the",
    "  THIRD state to publish it, after Nevada and California.",
    "  ITS FEDERAL AWARD DATE OF 07/23/2026 IS THE DATE OF A BUDGET REVISION",
    "  (Award Action Type 'Revision (Budget)'), not the date of the award: the",
    "  budget period still starts 12/29/2025, which is the project's own NOA",
    "  anchor. California's revision was three months after the award;",
    "  Connecticut's is SEVEN, so a date test keyed on 'Federal Award Date'",
    "  would quarantine every genuine Connecticut row.",
    "",
    "ONE CLOSURE, UNARRANGED. The NOA names Daniel Mize Sinclair as Director",
    "and Julie Vigil as Deputy Director; DSS's own 2026-04-10 press release",
    "names the same two people in the same roles. One federal publisher, one",
    "state publisher, nothing arranged.",
    "",
    "THE CONTROLS.",
    "  *_CONTROL.html is OHS's press index -- THE POSITIVE CONTROL. OHS",
    "    publishes named, recipient-level decisions in a recognisable form",
    "    ('Approves UCONN Health Affiliate's Acquisition of Waterbury",
    "    Hospital'). So the absence of an RHTP roster is Connecticut's and not",
    "    our channel's. Its four RHTP items are all pre-award.",
    "  *_NEGATIVE_CONTROL.html is DSS's ONLY RHTP press release, and it",
    "    announces a LEADERSHIP TEAM -- four named PEOPLE, no organisation and",
    "    no money. Missouri's governance roster (27 organisations at $1 each)",
    "    one tier further from money still.",
    "  *_AWARD_DATE_PASSED.html is OPM's RFP index, which carries NOFO",
    "    #26OHS001's full timeline including the award date that has gone by.",
    "  *_UNREADABLE.html is the CTsource bid board landing page. The state",
    "    directs subrecipients to CTsource; it is an external stateful",
    "    application this environment cannot search, so whether an RHTP award",
    "    has been posted inside it is UNKNOWN -- a statement about our access,",
    "    never about Connecticut (§0.4). biznet.ct.gov answers 403.",
    "",
    "THESE FILE DIGESTS ARE NOT A CHANGE TEST, AND THE MECHANISM IS THE FIFTH",
    "THIS PROJECT HAS MET AND THE FIRST THAT IS PER-NODE. portal.ct.gov stamps",
    "a cache-busting '?v=<yyyymmddHHMMSS>' on seven static asset URLs and the",
    "value is the SERVING NODE'S asset build time. Six fetches of the OPM page",
    "returned 80,531 bytes every time under FIVE DISTINCT file digests, one of",
    "which repeated -- so it is a small finite set of values, one per node,",
    "not a per-request nonce. A back-to-back pair across two pages of this one",
    "host gave SAME on the programme page and DIFFER on the OPM page in the",
    "same minute, which is California's lesson made sharper: a 'SAME' result",
    "is not evidence of stability even for the page it was run on. --probe",
    "compares a CONTENT digest via ct_reduce_html(); the reduced text was",
    "IDENTICAL across all six fetches at 8,983 characters. robots.txt is 200",
    "and does not disallow any path used here.",
    "",
    "file  bytes  sha256",
    paste(entries$file, entries$bytes, entries$sha256, sep = "  ")
  ), path)
  invisible(path)
}


# -- readers ------------------------------------------------------------------

#' The one HTML reduction, so the probe and the assertions read the same bytes
#'
#' Missouri's rule (session 29). It also absorbs portal.ct.gov's per-node
#' asset-version stamp for free: the `?v=` lives in `href`/`src` ATTRIBUTES,
#' and replacing every tag with a space discards attributes entirely.
ct_reduce_html <- function(raw) {
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "UTF-8"
  txt <- stringr::str_remove_all(txt, "(?s)<(script|style)[^>]*>.*?</\\1>")
  txt <- stringr::str_replace_all(txt, "<[^>]+>", " ")
  txt <- rhtp_ct_unescape(txt)
  txt <- stringr::str_remove_all(txt, "[​‌‍﻿]")
  stringr::str_squish(txt)
}

rhtp_ct_unescape <- function(x) {
  x <- stringr::str_replace_all(x, "&nbsp;", " ")
  x <- stringr::str_replace_all(x, "&amp;", "&")
  x <- stringr::str_replace_all(x, "&#39;|&rsquo;|&#8217;", "'")
  x <- stringr::str_replace_all(x, "&quot;|&ldquo;|&rdquo;", '"')
  x <- stringr::str_replace_all(x, "&lt;", "<")
  x <- stringr::str_replace_all(x, "&gt;", ">")
  x <- stringr::str_replace_all(x, "&#8211;|&ndash;", "-")
  # California's finding, and Connecticut carries it too: typographic
  # punctuation folded to ASCII so an assertion written from a rendered copy
  # matches. THE ARCHIVED BYTES ARE UNTOUCHED -- this is the matching text only.
  x <- stringr::str_replace_all(x, "[‘’‛]", "'")
  x <- stringr::str_replace_all(x, "[“”‟]", '"')
  x <- stringr::str_replace_all(x, "[‐‑‒–—]", "-")
  x
}

ct_html_text <- function(key, body = NULL) {
  if (is.null(body)) {
    p <- ct_path(key)
    body <- readBin(p, "raw", file.size(p))
  }
  ct_reduce_html(body)
}

ct_pdf_text <- function(key, body = NULL) {
  if (!exists("rhtp_pdf_text")) source(here::here("R", "utils_pdf_text.R"))
  path <- if (is.null(body)) {
    ct_path(key)
  } else {
    tmp <- tempfile(fileext = ".pdf"); writeBin(body, tmp); tmp
  }
  stringr::str_squish(paste(rhtp_pdf_text(path), collapse = " "))
}

#' The §7.1 allotment anchor for Connecticut, read rather than typed
ct_allotment_anchor <- function() {
  path <- here::here("data", "reference", "cms_fy2026_allotments.csv")
  a <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  v <- a$fy2026_allotment[a$state == "CT"]
  if (length(v) != 1L) {
    stop("[CT] the §7.1 anchor does not carry exactly one CT row.",
         call. = FALSE)
  }
  v
}

#' The §6.2 NOA date anchor for Connecticut, read rather than typed
ct_noa_anchor <- function() {
  path <- here::here("data", "reference", "cms_state_noa_dates.csv")
  if (!file.exists(path)) return(as.Date("2025-12-29"))
  d <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  v <- d$noa_date[d$state == "CT"]
  if (length(v) != 1L) return(as.Date("2025-12-29"))
  as.Date(v)
}


# -- assertions ---------------------------------------------------------------

#' §6.2 in its strongest form: CMS's OWN Notice of Award
#'
#' Nevada was the first state to publish it (session 26), California the second
#' (session 34), Connecticut the third. A footer quotes an award; this IS one.
#'
#' AND IT CARRIES CALIFORNIA'S TWO-DATES TRAP, WIDER. The Federal Award Date is
#' 07/23/2026 and the Award Action Type is "Revision (Budget)", while the
#' budget period still starts 12/29/2025. Both are asserted together, so a
#' future session cannot read the later date as the award date without this
#' assertion telling it otherwise.
ct_assert_noa_is_cms_award <- function(noa = NULL) {
  t <- if (is.null(noa)) ct_pdf_text("noa") else noa
  need <- c(
    "Notice of Award",
    CT_STATED$noa_award_num,
    CT_STATED$noa_listing,
    "Rural Health Transformation Program",
    "DEPARTMENT OF SOCIAL SERVICES",
    "CONNECTICUT",
    CT_STATED$noa_bp_start,
    CT_STATED$noa_bp_end,
    CT_STATED$footer_amount
  )
  miss <- need[!purrr::map_lgl(need, ~ stringr::str_detect(t, stringr::fixed(.x)))]
  if (length(miss)) {
    stop("[CT] the archived Notice of Award no longer carries: ",
         paste(miss, collapse = " | "),
         ". That is the §6.2 anchor for the whole state -- read it before ",
         "changing anything.", call. = FALSE)
  }
  # The two dates, together, deliberately.
  if (!stringr::str_detect(t, stringr::fixed(CT_STATED$noa_action_type)) ||
      !stringr::str_detect(t, stringr::fixed(CT_STATED$noa_award_date))) {
    stop("[CT] the NOA no longer carries BOTH its 'Revision (Budget)' action ",
         "type and its 07/23/2026 Federal Award Date. Those two are asserted ",
         "together because a date test keyed on the later one would read ",
         "Connecticut's award as seven months late and quarantine every ",
         "genuine Connecticut row.", call. = FALSE)
  }
  # The award-date/budget-period gap is the point, so it is measured.
  if (as.Date("2026-07-23") <= ct_noa_anchor()) {
    stop("[CT] the Federal Award Date no longer postdates the NOA anchor. ",
         "This assertion exists because it does, by seven months.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' The provenance, carried by programme-scoped sentences and not by the footer
#'
#' Session 27's audit: Connecticut's footer subject is "This PROJECT", the weak
#' form. These two sentences name the programme and the federal grant together.
ct_assert_programme_provenance <- function(programme = NULL) {
  t <- if (is.null(programme)) ct_html_text("programme") else programme
  need <- c(
    "Rural Health Transformation Program (RHTP) federal grant",
    "Connecticut received a $154 million federal grant",
    "partnering with other state agencies to implement 30 projects"
  )
  miss <- need[!purrr::map_lgl(need, ~ stringr::str_detect(t, stringr::fixed(.x)))]
  if (length(miss)) {
    stop("[CT] the DSS programme page no longer carries the programme-scoped ",
         "provenance sentences: ", paste(miss, collapse = " | "),
         ". The CMS footer alone is the WEAK form (session 27) and does not ",
         "replace them.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The footer corroborates the AMOUNT and is not the provenance
#'
#' Kansas's demotion (session 28), and the same `strict =` switch New
#' Hampshire, Wisconsin and California carry: non-strict it returns NA with a
#' message rather than throwing, so a DSS re-post that drops the boilerplate
#' cannot hard-fail Connecticut for no reason -- AND a future state whose only
#' evidence is a "this project" footer does not pass the test Connecticut
#' passes.
ct_assert_footer_corroborates <- function(strict = FALSE, programme = NULL) {
  t <- if (is.null(programme)) ct_html_text("programme") else programme
  want <- paste0("financial assistance award totaling ", CT_STATED$footer_amount,
                 " in Budget Period 1")
  if (!stringr::str_detect(t, stringr::fixed(want))) {
    msg <- paste0("[CT] the CMS financial-assistance footer is not on the ",
                  "programme page in the expected form. It is the WEAK form ",
                  "('This project is supported by') and corroborates the ",
                  "AMOUNT only; the provenance is carried by ",
                  "ct_assert_programme_provenance().")
    if (strict) stop(msg, call. = FALSE)
    message(msg); return(invisible(NA))
  }
  # It matches the §7.1 anchor to the cent, which is the whole of its value.
  cents <- as.numeric(stringr::str_remove_all(CT_STATED$footer_amount, "[$,]"))
  if (round(cents) != ct_allotment_anchor()) {
    stop("[CT] the footer amount ", CT_STATED$footer_amount, " no longer ",
         "rounds to the §7.1 anchor ", ct_allotment_anchor(), ".",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Everything Connecticut has solicited postdates its Notice of Award
#'
#' Texas's HHS0015180 closed before its state had the money; Connecticut's one
#' solicitation opened five months after the NOA. Read from the archived page
#' rather than typed.
ct_assert_after_noa <- function(opm = NULL) {
  t <- if (is.null(opm)) ct_html_text("opm") else opm
  need <- c("May 22,2026", CT_STATED$nofo_due)
  miss <- need[!purrr::map_lgl(need, ~ stringr::str_detect(t, stringr::fixed(.x)))]
  if (length(miss)) {
    stop("[CT] the OPM timeline no longer carries NOFO #26OHS001's own dates: ",
         paste(miss, collapse = " | "), call. = FALSE)
  }
  if (as.Date("2026-05-22") <= ct_noa_anchor()) {
    stop("[CT] NOFO #26OHS001 no longer postdates Connecticut's Notice of ",
         "Award. That ordering is what rules out Texas's defect here.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' THE TRIPWIRE: Connecticut has named no RHTP recipient
#'
#' DESIGNED TO FAIL. Three surfaces at once -- the Documents page (which lists
#' every RHTP document DSS publishes), the programme page (which says outright
#' that prospective subrecipients should keep checking back), and OPM's RFP
#' index (which carries the solicitation and no roster). If any of them
#' acquires award language, this file must be REWRITTEN as an award extractor,
#' not patched.
CT_AWARD_POSTED <- c(
  "has been awarded",  "have been awarded",  "awardees are",
  "selected for award", "notice of intent to award", "list of awardees",
  "grant recipients", "funded organizations", "successful applicant"
)

ct_assert_no_award_roster <- function(documents = NULL, programme = NULL,
                                      opm = NULL) {
  docs <- if (is.null(documents)) ct_html_text("documents") else documents
  prog <- if (is.null(programme)) ct_html_text("programme") else programme
  op   <- if (is.null(opm)) ct_html_text("opm") else opm

  for (nm in c(documents = "documents", programme = "programme", opm = "opm")) {
    t <- switch(nm, documents = docs, programme = prog, opm = op)
    hit <- CT_AWARD_POSTED[purrr::map_lgl(
      CT_AWARD_POSTED, ~ stringr::str_detect(t, stringr::regex(.x, ignore_case = TRUE)))]
    if (length(hit)) {
      stop("[CT] award language has appeared on the ", nm, " page: ",
           paste(hit, collapse = " | "),
           ". THAT IS THE SIGNAL, NOT A DEFECT. Connecticut may have ",
           "published a recipient-level roster: read it, and rewrite this ",
           "file as an award extractor rather than adjusting this constant.",
           call. = FALSE)
    }
  }
  # And the state's own pre-award sentence must still be there.
  if (!stringr::str_detect(prog, stringr::fixed(
        "Parties interested in being subrecipients of RHTP funding are encouraged to check back"))) {
    stop("[CT] the programme page no longer tells prospective subrecipients ",
         "to check back for opportunities. That sentence is Connecticut ",
         "saying in its own words that nobody has been chosen.", call. = FALSE)
  }
  invisible(TRUE)
}

#' THE DATE THAT HAS ALREADY PASSED, asserted rather than narrated
#'
#' This is the sharpest thing about Connecticut's negative and the reason it is
#' worth watching twice a week. OPM publishes the NOFO's full timeline; its
#' "Grant Awards Announced" milestone is 2026-08-17 and this file was taken
#' 2026-09-02.
ct_assert_award_date_passed <- function(opm = NULL) {
  t <- if (is.null(opm)) ct_html_text("opm") else opm
  need <- c(
    CT_STATED$nofo_number,
    "Grant Awards Announced",
    CT_STATED$award_announced,
    "Once all negotiation is completed and contracts signed, awards will be announced"
  )
  miss <- need[!purrr::map_lgl(need, ~ stringr::str_detect(t, stringr::fixed(.x)))]
  if (length(miss)) {
    stop("[CT] OPM's page no longer carries NOFO #26OHS001's award milestone: ",
         paste(miss, collapse = " | "),
         ". If the NOFO has come down, Connecticut may have awarded -- check ",
         "before assuming it was tidied away.", call. = FALSE)
  }
  if (CT_AWARD_DATE >= CT_ARCHIVE_DATE) {
    stop("[CT] the published award date no longer precedes the archive date. ",
         "The whole point of this row is that Connecticut's own award date ",
         "has gone by with no roster.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The eligible class is HOSPITALS AMONG OTHERS -- §0.3, not Illinois's ICAHN
#'
#' New Hampshire's FHC answer (session 29). Losing this sentence must stop the
#' build rather than silently allow a pass-through to be coded `Yes`.
ct_assert_eligible_class_not_hospitals_only <- function(opm = NULL,
                                                        nofo = NULL) {
  t  <- if (is.null(opm)) ct_html_text("opm") else opm
  tn <- if (is.null(nofo)) ct_html_text("nofo") else nofo
  want <- paste("Hospitals and health systems, federally qualified health",
                "centers (FQHCs)")
  if (!stringr::str_detect(t, stringr::fixed(want)) ||
      !stringr::str_detect(tn, stringr::fixed(want))) {
    stop("[CT] NOFO #26OHS001's eligible-applicant sentence is missing from ",
         "one of its two publishers. It is what makes Connecticut's only ",
         "hospital-facing pool hospitals AMONG OTHERS (New Hampshire's FHC ",
         "class, §0.3) rather than Illinois's hospitals-only class.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' The budget narrative is a PLAN, in its own words
#'
#' This is the evidence for the whole RCJ disposition: all seven Connecticut
#' Tier 3 candidates are line items in this document, and the document says it
#' is pre-award.
ct_assert_budget_narrative_is_tier2 <- function(budget = NULL) {
  t <- if (is.null(budget)) ct_pdf_text("budget") else budget
  need <- c(
    "Personnel salaries will be updated once awarded",
    "Required reporting information for subrecipient",
    "Contractor 1 Carelon Behavioral Health, Inc.",
    "Proposal: W03-Area Health Education Center (AHEC) Expansion",
    "Rural Community Mental Health Services Provider(s) TBD"
  )
  miss <- need[!purrr::map_lgl(need, ~ stringr::str_detect(t, stringr::fixed(.x)))]
  if (length(miss)) {
    stop("[CT] the budget narrative no longer carries the sentences that make ",
         "it a PLAN rather than an award list: ", paste(miss, collapse = " | "),
         ". All seven RCJ Connecticut candidates are line items in this ",
         "document; if it has become an award document, read it.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' THE NEGATIVE CONTROL: DSS's only RHTP announcement is GOVERNANCE
#'
#' It names four PEOPLE. Missouri published a governance roster of 27
#' ORGANISATIONS and RCJ priced every one at $1 (session 28); Connecticut's is
#' one tier further from money still, and it is the only thing DSS has
#' announced about RHTP.
ct_assert_leadership_is_not_award <- function(leadership = NULL) {
  t <- if (is.null(leadership)) ct_html_text("leadership") else leadership
  need <- c(
    "announced the formation of the Rural Health Transformation Program leadership team",
    "Daniel Sinclair", "Julie Vigil", "4/10/2026"
  )
  miss <- need[!purrr::map_lgl(need, ~ stringr::str_detect(t, stringr::fixed(.x)))]
  if (length(miss)) {
    stop("[CT] the DSS leadership release no longer reads as a governance ",
         "announcement: ", paste(miss, collapse = " | "), call. = FALSE)
  }
  hit <- CT_AWARD_POSTED[purrr::map_lgl(
    CT_AWARD_POSTED, ~ stringr::str_detect(t, stringr::regex(.x, ignore_case = TRUE)))]
  if (length(hit)) {
    stop("[CT] DSS's leadership release has acquired award language (",
         paste(hit, collapse = " | "), "). Read it: DSS's press room is where ",
         "a state-level RHTP award announcement would land.", call. = FALSE)
  }
  invisible(TRUE)
}

#' THE POSITIVE CONTROL: OHS publishes named decisions in a recognisable form
#'
#' Without it, "no roster" is indistinguishable from "we are reading the wrong
#' channel". It is a tripwire in both directions: it fails if OHS stops naming
#' organisations, and it fails if OHS's RHTP items stop being pre-award.
ct_assert_channel_control <- function(ohs_press = NULL) {
  t <- if (is.null(ohs_press)) ct_html_text("ohs_press") else ohs_press
  named <- c("Approves UCONN Health Affiliate", "Waterbury Hospital",
             "Acquisition of Eastern Connecticut Hospital")
  miss <- named[!purrr::map_lgl(named, ~ stringr::str_detect(t, stringr::fixed(.x)))]
  if (length(miss)) {
    stop("[CT] OHS's press index no longer demonstrates that OHS names ",
         "organisations in its decisions: ", paste(miss, collapse = " | "),
         ". Without that, Connecticut's 'no roster' finding is a statement ",
         "about our reading rather than about Connecticut.", call. = FALSE)
  }
  # The four RHTP items, all pre-award.
  rhtp <- c(
    "Notice of Funding Opportunity Rural Health Transformation Information Technology Program",
    "Legal Notice - Notice of Funding Opportunity #26OHS001"
  )
  miss2 <- rhtp[!purrr::map_lgl(rhtp, ~ stringr::str_detect(t, stringr::fixed(.x)))]
  if (length(miss2)) {
    stop("[CT] OHS's RHTP press items have changed: ",
         paste(miss2, collapse = " | "),
         ". Read the index -- an award announcement would land here.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' CTsource is UNREADABLE to this environment, and that is not a negative
#'
#' §0.4, and Maine's precedent (a CGI Advantage portal). The state directs
#' subrecipients to CTsource; it is an external stateful application. The row
#' this backs reads publishes_roster = UNKNOWN.
ct_assert_ctsource_unreadable <- function(ctsource = NULL) {
  t <- if (is.null(ctsource)) ct_html_text("ctsource") else ctsource
  if (!stringr::str_detect(t, stringr::fixed("CTsource Bid Board"))) {
    stop("[CT] the CTsource landing page has changed shape. It is recorded ",
         "as UNREADABLE/UNKNOWN; if it now serves searchable content, that ",
         "is a new source to read.", call. = FALSE)
  }
  if (stringr::str_detect(t, stringr::regex("rural health transformation",
                                            ignore_case = TRUE))) {
    stop("[CT] the CTsource landing page now mentions RHTP directly. Read ",
         "it: this row exists because it did not.", call. = FALSE)
  }
  invisible(TRUE)
}

ct_assert_no_award_file <- function() {
  if (file.exists(here::here(CT_AWARDS_CSV))) {
    stop("[CT] ", CT_AWARDS_CSV, " exists. Connecticut has published no ",
         "recipient-level award list; if that has changed, write the ",
         "extractor deliberately and delete this assertion in the same ",
         "commit.", call. = FALSE)
  }
  path <- here::here(CT_STATUS_CSV)
  if (file.exists(path)) {
    cols <- names(readr::read_csv(path, n_max = 0, show_col_types = FALSE))
    bad  <- intersect(cols, c("amount", "round_amount", "amount_announced"))
    if (length(bad)) {
      stop("[CT] ct_year1_status.csv carries an amount column (",
           paste(bad, collapse = ", "), "). It is a STATUS table: Connecticut ",
           "has named no recipient, so no sum over it could mean anything.",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}

rhtp_ct_assert <- function(strict_footer = FALSE) {
  ct_assert_noa_is_cms_award()
  ct_assert_programme_provenance()
  ct_assert_footer_corroborates(strict = strict_footer)
  ct_assert_after_noa()
  ct_assert_no_award_roster()
  ct_assert_award_date_passed()
  ct_assert_eligible_class_not_hospitals_only()
  ct_assert_budget_narrative_is_tier2()
  ct_assert_leadership_is_not_award()
  ct_assert_channel_control()
  ct_assert_ctsource_unreadable()
  ct_assert_no_award_file()
  invisible(TRUE)
}


# -- the status table ---------------------------------------------------------

#' What each Connecticut RHTP channel publishes
#'
#' DELIBERATELY NO `amount` COLUMN (Texas's device, and Wisconsin's, Maine's
#' and California's after it). Connecticut has named no recipient and published
#' no per-recipient figure; the pool amounts live in `stated_pool` as the
#' state's own words, which cannot be summed by accident.
rhtp_ct_year1_status <- function() {
  tibble::tribble(
    ~channel, ~administrator, ~stated_pool, ~stage, ~eligible_class,
    ~publishes_roster, ~evidence,

    "NOFO #26OHS001 -- Care Coordination and Remote Patient Monitoring (AI)",
    "Office of Health Strategy (OHS)",
    paste("$1.8 million available in Year 1; up to 5 grant awards;",
          "individual awards $100,000 to $1,000,000"),
    "CLOSED_AWARD_DATE_PASSED",
    paste("HOSPITALS AMONG OTHERS -- 'Hospitals and health systems, federally",
          "qualified health centers (FQHCs), behavioral health providers,",
          "independent medical practices, municipal and state health",
          "departments, academic medical centers, and multi-entity consortia",
          "with a clinical lead'. New Hampshire's FHC class, NOT Illinois's",
          "ICAHN class, so §0.3 governs it either way."),
    "No",
    paste("CONNECTICUT'S OWN AWARD DATE HAS PASSED. OPM's published timeline:",
          "'Applications Due ... July 7, 2026, 2:00 PM ET', then 'Grant",
          "Awards Announced -- Once all negotiation is completed and",
          "contracts signed, awards will be announced -- AUGUST 17, 2026'.",
          "This archive was taken 2026-09-02, sixteen days later, and no",
          "roster exists. The only recipient-level RHTP solicitation",
          "Connecticut has run."),

    "DSS RHTP Documents page -- WHERE A ROSTER WOULD BE LINKED",
    "Department of Social Services (DSS)",
    "n/a -- $154,249,105.53 Budget Period 1 across 30 projects",
    "NO_ROSTER_PUBLISHED",
    paste("n/a. DSS is the lead agency 'partnering with other state agencies",
          "to implement 30 projects' across four initiatives."),
    "No",
    paste("EIGHT documents and not one is an award roster: the application,",
          "the Governor's endorsement letter, CMS's NOTICE OF AWARD, the",
          "project narrative, the budget narrative, project summaries,",
          "overview slides and two webinars. Every one is planning or",
          "federal-award material."),

    "DSS RHTP programme page -- THE STATE'S OWN PRE-AWARD SENTENCE",
    "Department of Social Services (DSS)",
    "$154,249,105.53 in Budget Period 1 (CMS footer, WEAK form)",
    "NO_ROSTER_PUBLISHED",
    "n/a",
    "No",
    paste("'Parties interested in being subrecipients of RHTP funding are",
          "encouraged to check back here on this webpage regularly for",
          "updates, as well as the state procurement website/portal and other",
          "standard channels for potential funding opportunities.' That is",
          "Connecticut saying in its own words that nobody has been chosen,",
          "and it points at the procurement channel (Indiana's sixth",
          "question, answered by the state rather than inferred)."),

    "DSS press room -- THE NEGATIVE CONTROL, AND IT IS GOVERNANCE",
    "Department of Social Services (DSS)",
    "n/a", "GOVERNANCE_ONLY", "n/a", "No",
    paste("DSS's ONLY RHTP press release announces a LEADERSHIP TEAM --",
          "'naming four experienced public health professionals to guide the",
          "initiative' (2026-04-10). It names PEOPLE, not organisations, and",
          "attaches no money. Missouri's Hub Anchors were a governance roster",
          "of 27 ORGANISATIONS that RCJ priced at $1 each; this is one tier",
          "further from money still. UNARRANGED CLOSURE: the two officials",
          "it names, Daniel Sinclair and Julie Vigil, are the same two named",
          "on CMS's Notice of Award."),

    "OHS press room -- THE POSITIVE CONTROL (THE CHANNEL)",
    "Office of Health Strategy (OHS)",
    "n/a", "NO_ANNOUNCEMENT", "n/a", "No",
    paste("OHS demonstrably publishes named, recipient-level decisions in a",
          "recognisable form -- 'Approves UCONN Health Affiliate's",
          "Acquisition of Waterbury Hospital', 'Approves Hartford HealthCare",
          "Subsidiary's Acquisition of Eastern Connecticut Hospital'. So",
          "'Connecticut has published no RHTP roster' is a statement about",
          "the programme, not about our reading. Its FOUR RHTP items are all",
          "pre-award: the NOFO, its legal notice, and two rounds of Q&A."),

    "CTsource Contracting Portal -- UNREADABLE TO THIS ENVIRONMENT",
    "Department of Administrative Services (DAS)",
    "n/a", "UNREADABLE", "n/a", "UNKNOWN",
    paste("§0.4, and Maine's precedent. The state directs prospective",
          "subrecipients to CTsource; portal.ct.gov/das/ctsource/bidboard",
          "answers 200 but is a landing page onto an external stateful",
          "application this environment cannot search, and biznet.ct.gov",
          "answers 403 to the project's agent. Whether an RHTP contract has",
          "been executed inside CTsource is a statement about OUR ACCESS,",
          "never about Connecticut.")
  ) %>%
    dplyr::mutate(state = "CT", .before = 1)
}


# -- RCJ candidate disposition ------------------------------------------------

ct_rcj_candidates <- function() {
  rt <- readRDS(here::here("data", "interim", "stage2_record_table.rds"))
  rt %>% dplyr::filter(state == "CT", award_tier == "SUBAWARD")
}

CT_BUDGET_NARRATIVE_MARKER <- "Budget Narrative"
CT_RHTP_DOC_MARKER         <- "Connecticut RHTP"

#' Why each of RCJ's Connecticut Tier 3 candidates is not an RHTP subaward
#'
#' The counts are RE-DERIVED from the record table on every run, never typed,
#' so the day Connecticut's candidate set moves the build fails instead of the
#' table quietly ceasing to cover it. The disposition REFUSES a candidate it
#' does not cover (California's rule, session 34).
rhtp_ct_rcj_disposition <- function(cands = NULL) {
  if (is.null(cands)) cands <- ct_rcj_candidates()
  title <- cands$source_doc_title
  amt   <- cands$amount_announced

  from_narrative <- stringr::str_detect(title,
    stringr::fixed(CT_BUDGET_NARRATIVE_MARKER)) |
    stringr::str_detect(title, stringr::fixed(CT_RHTP_DOC_MARKER))
  if (!all(from_narrative)) {
    stop("[CT] ", sum(!from_narrative), " Connecticut Tier 3 candidates are ",
         "NOT from the budget narrative or the RHTP plan document. This ",
         "file's whole disposition is that all of them are. Read the new ",
         "ones before building: ",
         paste(unique(title[!from_narrative]), collapse = " | "),
         call. = FALSE)
  }

  agency <- stringr::str_detect(cands$awardee_name_clean, stringr::regex(
    "Department of|Office of Health Strategy|DMHAS|DPH|\\(OHS\\)", ignore_case = TRUE))
  vendor <- stringr::str_detect(cands$awardee_name_clean,
                                stringr::fixed("Carelon"))
  proposal <- stringr::str_detect(cands$awardee_name_clean,
                                  stringr::fixed("Area Health Education Center"))

  if (!all(agency | vendor | proposal)) {
    stop("[CT] a Connecticut candidate matches none of the three groups this ",
         "disposition covers (state agency / planned contractor / proposal ",
         "name): ",
         paste(cands$awardee_name_clean[!(agency | vendor | proposal)],
               collapse = " | "), call. = FALSE)
  }

  # THE ARITHMETIC CLOSES, AND IT IS ASSERTED RATHER THAN NOTED. The seven
  # candidates sum to rcj_state_survey.csv's own figure for Connecticut, so a
  # disposition that quietly stopped covering one of them fails here.
  survey <- readr::read_csv(
    here::here("data", "reference", "rcj_state_survey.csv"),
    show_col_types = FALSE, progress = FALSE)
  expect <- survey$rcj_federal_amount_sum[survey$state == "CT"]
  got    <- sum(amt, na.rm = TRUE)
  if (length(expect) == 1L && !isTRUE(all.equal(got, expect))) {
    stop("[CT] the candidate amounts sum to ", format(got, big.mark = ","),
         " but rcj_state_survey.csv says ", format(expect, big.mark = ","),
         ". One of the two has moved; read both before building.",
         call. = FALSE)
  }

  tibble::tribble(
    ~group, ~rows, ~distinct_awardees, ~rcj_amount_sum, ~disposition, ~why,

    "State agencies named as implementing subrecipients in the budget narrative",
    sum(agency), dplyr::n_distinct(cands$awardee_name_clean[agency]),
    sum(amt[agency], na.rm = TRUE),
    "RHTP_BUT_NOT_A_SUBAWARD",
    paste0(
      "OKLAHOMA'S DEFECT -- THE WRONG TIER. These are the Department of ",
      "Public Health ($21,714,915), the Office of Health Strategy ",
      "($7,689,978) and the Department of Mental Health and Addiction ",
      "Services (TWICE, at $5,749,236 and $5,600,000). Every one is a line ",
      "in Connecticut's RHT Budget Narrative, whose section heading for each ",
      "is '<agency> - Required reporting information for SUBRECIPIENT' -- ",
      "the pass-through structure INSIDE state government, one tier above ",
      "any provider. The narrative says in its own words that it is a plan: ",
      "'Personnel salaries will be updated ONCE AWARDED.' Its summary table ",
      "is headed 'Proposal'. Nothing in it is an award action, and the ",
      "agencies are the administrators, not recipients (§6.1)."),

    "One planned contractor, carried twice from two revisions of one document",
    sum(vendor), dplyr::n_distinct(cands$awardee_name_clean[vendor]),
    sum(amt[vendor], na.rm = TRUE),
    "RHTP_BUT_NOT_A_SUBAWARD",
    paste0(
      "A MECHANISM THIS PROJECT HAD NOT RECORDED: RCJ PRICES DOCUMENT ",
      "REVISIONS AS SEPARATE AWARDS. Carelon Behavioral Health, Inc. is ",
      "printed in the narrative as 'Contractor 1 Carelon Behavioral Health, ",
      "Inc.' in an ITEMISED BUDGET JUSTIFICATION for the ACCESS ASD & ",
      "School-Based Mental Health proposal, totalling $3,800,000. ",
      "Connecticut published the narrative twice, so RCJ carries that ONE ",
      "line item as TWO candidates at $3,800,000 each. The same mechanism ",
      "gives DMHAS's adult mental health line TWO DIFFERENT AMOUNTS across ",
      "the two revisions ($5,749,236 and $5,600,000). New Hampshire's CDFA ",
      "appeared under three spellings at three prices (session 29); this is ",
      "the same failure caused by REVISION rather than spelling, and it is ",
      "the cleaner case because the underlying document is provably one ",
      "line. The narrative also names contractors it has not chosen -- ",
      "'Rural Community Mental Health Services Provider(s) TBD' -- and ends ",
      "one contractor list 'and Similar'."),

    "A proposal name read as an awardee",
    sum(proposal), dplyr::n_distinct(cands$awardee_name_clean[proposal]),
    sum(amt[proposal], na.rm = TRUE),
    "RHTP_BUT_NOT_A_SUBAWARD",
    paste0(
      "§6.1's PROGRAM_NAME_AS_AWARDEE. 'Area Health Education Center ",
      "(AHEC)', $1,500,000, is not a recipient string in the source: the ",
      "narrative prints it as 'Proposal: W03-Area Health Education Center ",
      "(AHEC) Expansion' with 'Contractor 1 AHEC' as a BUDGET COLUMN ",
      "HEADING, under the University of Connecticut Health Center's own ",
      "'UCHC Contracts: $1,500,000' section. The programme page separately ",
      "lists AHEC among the STATE AGENCIES DSS is collaborating with, which ",
      "is what it is here.")
  ) %>%
    dplyr::mutate(state = "CT", .before = 1)
}


# -- build / report -----------------------------------------------------------

rhtp_ct_build <- function() {
  rhtp_ct_assert()
  status <- rhtp_ct_year1_status()
  dispo  <- rhtp_ct_rcj_disposition()
  readr::write_csv(status, here::here(CT_STATUS_CSV))
  readr::write_csv(dispo,  here::here(CT_DISPO_CSV))
  ct_assert_no_award_file()
  message("[CT] wrote ", CT_STATUS_CSV, " (", nrow(status), " rows) and ",
          CT_DISPO_CSV, " (", nrow(dispo), " rows).")
  message("[CT] NO ct_year1_awardees.csv was written, and that is the finding.")
  invisible(list(status = status, disposition = dispo))
}

rhtp_ct_report <- function() {
  cands  <- ct_rcj_candidates()
  dispo  <- rhtp_ct_rcj_disposition(cands)
  status <- rhtp_ct_year1_status()
  allot  <- ct_allotment_anchor()
  overdue <- as.integer(CT_ARCHIVE_DATE - CT_AWARD_DATE)

  cat("\nCONNECTICUT -- RHTP Year 1\n")
  cat(strrep("=", 78), "\n\n")
  cat(sprintf("  CMS FY2026 allotment           $%s\n",
              format(allot, big.mark = ",", scientific = FALSE)))
  cat("  RECIPIENT-LEVEL AWARD LIST     NONE PUBLISHED\n")
  cat("  NAMED HOSPITALS                0\n")
  cat("  HOSPITAL DOLLARS               $0\n\n")

  cat("  CONNECTICUT'S OWN AWARD DATE HAS ALREADY PASSED.\n")
  cat(sprintf("    NOFO #26OHS001 applications due  %s\n", CT_STATED$nofo_due))
  cat(sprintf("    'Grant Awards Announced'         %s\n",
              CT_STATED$award_announced))
  cat(sprintf("    this archive taken               %s  (%d days later)\n\n",
              format(CT_ARCHIVE_DATE), overdue))

  cat("  WHAT EACH CHANNEL PUBLISHES\n")
  for (i in seq_len(nrow(status))) {
    cat(sprintf("    %-54s %-24s roster: %s\n",
                substr(status$channel[i], 1, 54),
                substr(status$stage[i], 1, 24),
                status$publishes_roster[i]))
  }

  cat(sprintf("\n  RCJ Tier 3 candidates          %d\n", nrow(cands)))
  for (i in seq_len(nrow(dispo))) {
    cat(sprintf("    %-58s %d rows  $%s\n",
                substr(dispo$group[i], 1, 58), dispo$rows[i],
                format(dispo$rcj_amount_sum[i], big.mark = ",",
                       scientific = FALSE)))
  }
  cat(sprintf("  RCJ candidate total            $%s\n",
              format(sum(dispo$rcj_amount_sum), big.mark = ",",
                     scientific = FALSE)))
  cat("  RHTP subawards among them      0\n\n")

  cat("  ALL SEVEN ARE BUDGET-NARRATIVE LINE ITEMS -- Oklahoma's defect, the\n")
  cat("  wrong TIER -- and RCJ prices DOCUMENT REVISIONS as separate awards:\n")
  cat("  Carelon's one $3,800,000 line is carried twice, and DMHAS's adult\n")
  cat("  mental health line is carried at TWO DIFFERENT AMOUNTS.\n\n")

  cat("  THE POOL TO WATCH IS NOFO #26OHS001, $1.8M and up to 5 awards, whose\n")
  cat("  eligible class is 'Hospitals and health systems, FQHCs, behavioral\n")
  cat("  health providers...' -- hospitals AMONG OTHERS, New Hampshire's FHC\n")
  cat("  class and not Illinois's. Until a recipient is named it is\n")
  cat("  eligibility, not receipt (§0.3).\n")
  invisible(dispo)
}


# -- the live probe -----------------------------------------------------------

# WHICH SOURCES ANSWER "HAS CONNECTICUT AWARDED?" -- and only those. The NOA
# and the budget narrative are static documents that cannot change the answer.
#   opm         the NOFO timeline whose award date has passed
#   programme   where a roster or an award link would appear
#   documents   DSS's own index of every RHTP document it publishes
#   ohs_press   OHS's announcement channel -- where an award release would land
#   dss_press   DSS's, where a state-level announcement would land
CT_PROBE_KEYS <- c("opm", "programme", "documents", "ohs_press", "dss_press")

#' The change test: a digest of the REDUCED text, not of the file
#'
#' See `ct_probe()`. It reduces with `ct_reduce_html()` -- the same function
#' the assertions read -- so the probe and the tripwires read the same bytes
#' and cannot drift apart (Missouri's rule, session 29).
ct_content_digest <- function(body) {
  digest::digest(ct_reduce_html(body), algo = "sha256", serialize = FALSE)
}

#' LIVE: has Connecticut awarded yet?
#'
#' Missouri's `--probe` shape (session 29): fetch, compare, report, ARCHIVE
#' NOTHING. The tripwires run against the LIVE bytes rather than the archive --
#' session 25's Indiana lesson as code, because `--validate` reads the
#' committed copy and can only answer "had Connecticut awarded on the day the
#' archive was taken?".
#'
#' IT COMPARES A CONTENT DIGEST, AND THE MECHANISM IS THE FIFTH THIS PROJECT
#' HAS MET -- THE FIRST THAT IS PER-NODE RATHER THAN PER-REQUEST.
#' `portal.ct.gov` stamps a cache-busting `?v=<yyyymmddHHMMSS>` on seven static
#' asset URLs, and the value is the SERVING NODE'S asset build time. Six
#' fetches of the OPM page returned 80,531 bytes every time under FIVE DISTINCT
#' file digests, one of which repeated -- a small finite set of values, one per
#' node, not a random per-request nonce (Missouri's Incapsula), not a script
#' body nonce (Wisconsin's Boomerang), not rotating page content (Nevada's
#' widget) and not a cache variant of differing length (California's).
#'
#' AND IT SHARPENS CALIFORNIA'S LESSON RATHER THAN REPEATING IT. A back-to-back
#' pair run against TWO PAGES OF THIS ONE HOST gave SAME on the programme page
#' and DIFFER on the OPM page in the same minute: whether the pair catches it
#' depends on which node answers, so a "SAME" result is not evidence of
#' stability even for the page it was run on. The reduced text was IDENTICAL
#' across all six fetches at 8,983 characters, because the `?v=` lives in
#' `href`/`src` ATTRIBUTES and the reduction discards attributes entirely.
ct_probe <- function(keys = CT_PROBE_KEYS) {
  message("[CT] LIVE probe, ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"))
  changed <- character(0)
  bodies  <- list()
  for (i in seq_along(keys)) {
    key <- keys[[i]]
    if (i > 1L) Sys.sleep(CT_HOST_THROTTLE_S)
    served <- ct_get(ct_source(key, "url"), paste0("probe:", key))
    bodies[[key]] <- served
    live <- ct_content_digest(served)
    have <- ct_content_digest(readBin(ct_path(key), "raw",
                                      file.size(ct_path(key))))
    same <- identical(live, have)
    message(sprintf("  %-10s %s  %s", key, if (same) "UNCHANGED" else "CHANGED  ",
                    substr(live, 1, 16)))
    if (!same) changed <- c(changed, key)
  }

  txt <- lapply(bodies, ct_reduce_html)
  ct_assert_no_award_roster(documents = txt$documents,
                            programme = txt$programme, opm = txt$opm)
  ct_assert_award_date_passed(opm = txt$opm)
  ct_assert_programme_provenance(programme = txt$programme)
  ct_assert_eligible_class_not_hospitals_only(opm = txt$opm,
                                              nofo = ct_html_text("nofo"))
  ct_assert_leadership_is_not_award(leadership = ct_html_text("leadership"))
  ct_assert_channel_control(ohs_press = txt$ohs_press)
  message("[CT] the award tripwires pass against the LIVE bytes: Connecticut ",
          "has not published a recipient-level RHTP award roster.")
  if (length(changed)) {
    message("[CT] CHANGED, read them: ", paste(changed, collapse = ", "))
  }
  invisible(list(changed = changed))
}


# -- CLI ----------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args  <- commandArgs(trailingOnly = TRUE)
  force <- "--force" %in% args
  if ("--probe" %in% args)    ct_probe()
  if ("--fetch" %in% args)    ct_fetch(force = force)
  if ("--validate" %in% args) {
    rhtp_ct_assert(strict_footer = "--strict" %in% args)
    message("[CT] all assertions pass.")
  }
  if ("--build" %in% args)    rhtp_ct_build()
  if ("--report" %in% args)   rhtp_ct_report()
  if (!length(intersect(args, c("--probe", "--fetch", "--validate", "--build",
                                "--report")))) {
    message("usage: Rscript R/03ac_ct_year1_probe.R ",
            "[--probe] [--fetch [--force]] [--validate] [--build] [--report]")
  }
}
