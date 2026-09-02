#!/usr/bin/env Rscript
# 03ab_ca_year1_probe.R -------------------------------------------------------
#
# CALIFORNIA -- RHTP Year 1. A NEGATIVE, and the second one this project has met
# with a DATE ON IT (Wisconsin's shape). California led the RCJ_ONLY queue at 11
# Tier 3 candidates, and ELEVEN OF THE ELEVEN ARE NAMED CALIFORNIA HOSPITALS
# CARRYING REAL DOLLAR AMOUNTS. Not one of them is an RHTP award.
#
# WHAT CALIFORNIA HAS PUBLISHED.
#
#   California brands RHTP as CalRHT, run by the Department of Health Care
#   Access and Information (HCAI). It has opened FOUR grant opportunities and
#   ALL FOUR ARE CLOSED WITH NO ROSTER: Accelerator Partners $39,010,000,
#   Workforce Development Recruitment and Retention $54,170,000, EHR
#   Modernization $11,650,000, and the FM-OB Fellowship Subaward Program
#   $6,500,000 -- $111,330,000 between them, 47.6% of the allotment, and NOT
#   ONE NAMED RECIPIENT.
#
#   AND THE WINDOW IS OPEN NOW, BY DAYS. Three of the four grant guides put
#   award notification in AUGUST / SEPTEMBER 2026 and grant agreements in
#   SEPTEMBER / OCTOBER 2026; the EHR guide's milestone is "Notify
#   Subrecipients September 2026"; and WDRR's application window closed
#   AUGUST 31, 2026. This file ran 2026-09-02.
#
# §6.2 IN ITS STRONGEST FORM, AND A NEW POSITION ON SESSION 27'S AXIS.
# California publishes CMS's OWN NOTICE OF AWARD -- not a footer quoting one.
# `NOA_Rural-Health-Transformation-2026-Revised-1.pdf` is CMS's own form:
# recipient CALIFORNIA DEPARTMENT OF HEALTH CARE ACCESS AND INFORMATION,
# Assistance Listing 93.798, Award# RHTCMS332078-01-02, budget period
# 12/29/2025 - 10/30/2026, $233,639,308.47. Nevada was the first state to
# publish the NOA; California is the second.
#
# AND CALIFORNIA'S CMS FOOTER IS THE **STRONG** FORM AND IS **STILL** DEMOTED,
# WHICH IS THE NEW POSITION. Session 27's audit split the footer on its
# grammatical SUBJECT: "This publication is supported by" (weak, Kansas) versus
# a subject that names the programme (strong). California's reads "The **CalRHT
# program** is supported by ... $233,639,308.46" -- it names the programme, so
# it is the strong form. It is used here for the AMOUNT only anyway, because
# the NOA is better evidence than any footer, and two programme-scoped
# sentences carry the provenance. The footer is demoted here not because it is
# weak but because something better exists, and `strict = FALSE` is the same
# switch Kansas, New Hampshire and Wisconsin already carry.
#
# THE ONE-CENT DISAGREEMENT, PINNED AND NOT CORRECTED (§8, Kansas's rule).
# CMS's NOA says $233,639,308.47. Five HCAI publications say $233,639,308.46.
# One HCAI grant guide -- the FM-OB one -- says .47, agreeing with CMS. So
# HCAI's own estate disagrees with itself by one cent and the outlier is the
# document that agrees with the federal record. All three are asserted.
#
# §0.1 -- THE MOST DANGEROUS CANDIDATE SET THIS PROJECT HAS MET, AND THE REASON
# IS THE RATIO. All 11 California Tier 3 candidates come from ONE document,
# "CA - 2026 - Small and Rural Hospital Relief Program (SRHRP) - HCAI", and the
# SRHRP is a CALIFORNIA STATE PROGRAMME:
#
#   * funded by the CALIFORNIA ELECTRONIC CIGARETTE EXCISE TAX -- "Ten percent
#     of the funds ... will be allocated to [HCAI] to operate the SRHRP (HSC
#     Section 130075)";
#   * created under the ALFRED E. ALQUIST HOSPITAL FACILITIES SEISMIC SAFETY
#     ACT (HSC Section 129675), for seismic compliance work;
#   * and its own page mentions "RHTP" ZERO times, "Rural Health
#     Transformation" ZERO times, and "federal" ZERO times.
#
# TEXAS'S DEFECT WITH MAINE'S RATIO. Texas's 53 rows were 78% of its candidate
# set and named rural Texas hospitals; California's are ELEVEN OF ELEVEN, every
# one a named California hospital, every one priced, every one a real executed
# HCAI award -- from the SAME AGENCY that administers CalRHT. An extractor
# built from the candidate list would publish $5,475,000 of state
# cigarette-tax money as California's RHTP hospital dollars, with 8 named
# hospitals, and every row would trace to a real award document.
#
# AND THE SRHRP PAGE CARRIES ALL THREE OF THIS PROJECT'S FAILURE MODES AT ONCE,
# WHICH IS WHY IT IS ARCHIVED AS BOTH CONTROLS:
#
#   1. THE POSITIVE CONTROL. HCAI demonstrably publishes recipient-level awards
#      in a recognisable form -- "29 grants (totaling $17.2 million) have been
#      awarded", five of them named with amounts. So "CalRHT has published no
#      roster" is a statement about CalRHT and not about our reading.
#   2. THE §0.1 NEGATIVE. Those same awards are not RHTP.
#   3. THE §0.3 TRAP, AND IT IS THE LARGEST NAMED-HOSPITAL TABLE THIS PROJECT
#      HAS MET. The same page carries "SRHRP Eligible Hospitals": 102 NAMED
#      California hospitals in a machine-readable table with county, rurality
#      and bed count. It is an ELIGIBILITY list. Wisconsin's 213 DPI districts
#      and Maine's eleven invited hospitals, on one page, one tier worse --
#      because here the eligibility table sits directly beneath real awards.
#
# THE ELIGIBLE CLASS IS HOSPITALS **AMONG OTHERS**, WHICH IS NEW HAMPSHIRE'S
# ANSWER AND NOT ILLINOIS'S. Every CalRHT pool that reaches hospitals reaches
# them alongside FQHCs, RHCs, Tribal clinics, health care districts and
# academic medical centres. So even when California awards, no pool is
# Illinois's hospitals-only class, and a pass-through to any of them is §0.3.
#
# THE HOST ANSWERS ORDINARILY AND ITS DIGESTS DO NOT, AND BOTH HALVES ARE
# MEASURED. hcai.ca.gov answers the project's honest agent with HTTP 200 on
# every path used here, and `robots.txt` is 404, so no crawler policy is on
# offer and none is being declined. But a FILE digest is NOT the change test:
# two fetches three seconds apart return the same SHA-256 on both probed pages,
# and an earlier version of this file concluded from exactly that measurement
# that a file digest would do -- then the first live probe reported two of
# three pages CHANGED half an hour later with nothing changed. TWO FETCHES
# SECONDS APART IS NOT A STABILITY TEST. Two mechanisms, neither one this
# project had met: a CACHE VARIANT (the CalRHT page served with or without a
# ~15 KB ElasticPress asset block, 142,605 or 157,732 bytes) and WordPress
# `antispambot()` RE-ROLLING EMAIL ENTITIES on every render of the newsroom
# (same length, different bytes, identical rendered text -- a byte-count check
# passes it). `--probe` therefore compares a CONTENT digest via
# `ca_reduce_html()`; see `ca_probe()`. That makes California the FOURTH
# mechanism, after Nevada (rotating page content), Missouri (an Incapsula
# cache-buster in a script SRC) and Wisconsin (an Akamai Boomerang nonce in a
# script BODY) -- and Connecticut's per-node asset-version stamp (session 35)
# is the fifth.
#
# CLI:
#   --fetch [--force]  archive the 10 sources + SHA-256 manifest
#   --validate         every assertion, offline
#   --build            write the two status/disposition CSVs (NO award file)
#   --probe            LIVE: has California awarded yet?
#   --report           the negative, and the $111.3M whose awards are due now
#
# Sessions: 34.

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(stringr)
  library(purrr)
})

source(here::here("R", "utils_config.R"))

CA_EVIDENCE_DIR <- here::here("data", "evidence", "CA")
CA_STATUS_CSV   <- "data/reference/ca_year1_status.csv"
CA_DISPO_CSV    <- "data/reference/ca_rcj_candidate_disposition.csv"
CA_AWARDS_CSV   <- "data/reference/ca_year1_awardees.csv"   # MUST NOT EXIST
CA_HOST_THROTTLE_S <- 3

# hcai.ca.gov answers the project's honest agent with HTTP 200 on every path
# used here, so §3's michigan.gov exception is not reached and must not be.
CA_USER_AGENT <- paste(
  "AHA-RHTP-Tracker/0.1 (+https://www.aha.org;",
  "contact: AHA Data and Policy; R httr2)"
)

CA_SOURCES <- tibble::tribble(
  ~key, ~file, ~url,

  "calrht",
  "2026-09-02_ca_hcai_calrht_programme.html",
  "https://hcai.ca.gov/rural-health/calrht/",

  "funding",
  "2026-09-02_ca_hcai_calrht_funding_opportunities.html",
  "https://hcai.ca.gov/rural-health/calrht/funding/",

  "cms_noa",
  "2026-03-31_ca_cms_notice_of_award_revised.pdf",
  paste0("https://hcai.ca.gov/wp-content/uploads/2026/04/",
         "NOA_Rural-Health-Transformation-2026-Revised-1.pdf"),

  "budget",
  "2026-03-27_ca_calrht_budget_narrative.pdf",
  paste0("https://hcai.ca.gov/wp-content/uploads/2026/05/",
         "Budget-Narrative-RHTP-v5-2026-03-27.pdf"),

  "gg_accel",
  "2026-06-30_ca_calrht_accelerator_partners_grant_guide.pdf",
  paste0("https://hcai.ca.gov/wp-content/uploads/2026/06/",
         "2026-2027-CalRHT-TCM-Accelerator-Partner-Grant-Guide-Version-for-",
         "Publishing-2026.06.30.pdf"),

  "gg_wdrr",
  "2026-09-02_ca_calrht_wdrr_grant_guide.pdf",
  "https://hcai.ca.gov/wp-content/uploads/2026/07/CalRHT-WDRR-Grant-Guide.pdf",

  "gg_ehr",
  "2026-09-02_ca_calrht_ehr_modernization_grant_guide.pdf",
  paste0("https://hcai.ca.gov/wp-content/uploads/2026/07/",
         "2026-2027-CalRHT-EHR-Modernization-Grant-Guide.pdf"),

  "gg_wcap",
  "2026-09-02_ca_calrht_expand_support_workforce_grant_guide.pdf",
  paste0("https://hcai.ca.gov/wp-content/uploads/2026/07/",
         "2026-2027-CalRHT-Expand-and-Support-Rural-Workforce-Capacity-",
         "Grant-Guide.pdf"),

  "srhrp",
  "2026-09-02_ca_hcai_srhrp_BOTH_CONTROLS.html",
  "https://hcai.ca.gov/facilities/health-facility-financing/srhrp/",

  "newsroom",
  "2026-09-02_ca_hcai_newsroom_CONTROL.html",
  "https://hcai.ca.gov/media-center/"
)

CA_STATED <- list(
  cms_allotment_anchor = 233639308,
  noa_amount           = "$233,639,308.47",
  footer_amount        = "$233,639,308.46",
  noa_award_number     = "RHTCMS332078-01-02",
  noa_fain             = "RHTCMS332078",
  noa_assistance_list  = "93.798",
  noa_recipient        = "CALIFORNIA DEPARTMENT OF HEALTH CARE ACCESS AND INFORMATION",
  noa_budget_start     = "12/29/2025",
  noa_federal_date     = "03/31/2026",
  noa_action_type      = "Revision (Budget)",
  closed_pools_n       = 4L,
  pool_accel           = 39010000,
  pool_wdrr            = 54170000,
  pool_ehr             = 11650000,
  pool_wcap            = 6500000,
  srhrp_awards_n       = 29L,
  srhrp_awards_stated  = "$17.2 million",
  srhrp_eligible_n     = 102L,
  rcj_candidates_n     = 11L
)

# THE PROVENANCE, PROGRAMME-SCOPED (session 27's axis). Each takes CalRHT or
# the award action as its grammatical subject.
CA_PROGRAMME_SCOPED <- c(
  implementation = paste(
    "The California Rural Health Transformation (CalRHT) program is",
    "California's approach to the federal Rural Health Transformation Program",
    "(RHTP), led by the Department of Health Care Access and Information"),
  award = paste(
    "Through RHTP, California has been awarded $233.6 million for Federal",
    "Fiscal Year 2026 to support rural communities across the state")
)

# The CMS footer. STRONG form -- its subject names the programme -- and used
# for the AMOUNT only, because the NOA is better evidence than any footer.
CA_FOOTER_STRONG <- "The CalRHT program is supported by the Centers for Medicare & Medicaid Services"

# CMS's OWN NOTICE OF AWARD -- the §6.2 anchor, stronger than any footer.
CA_NOA_MARKERS <- c(
  listing   = "Rural Health Transformation Program",
  recipient = "CALIFORNIA DEPARTMENT OF HEALTH CARE ACCESS AND INFORMATION",
  award_no  = "RHTCMS332078-01-02",
  amount    = "$233,639,308.47",
  al_number = "93.798"
)

# EVERY CalRHT OPPORTUNITY IS CLOSED AND UNAWARDED, IN HCAI'S OWN MARKUP. The
# heading suffix is what `ca_assert_no_award_roster()` counts, and it is
# DESIGNED TO FAIL the day the count moves -- in either direction.
CA_CLOSED_MARKER   <- "(Closed)"
CA_CLOSED_EXPECTED <- 4L
CA_POOL_HEADINGS <- c(
  accel = "Accelerator Partners (Closed)",
  wcap  = "Expand and Support Rural Workforce Capacity (Closed)",
  ehr   = "Electronic Health Record Modernization Grants (Closed)"
)
# WDRR's heading is deliberately NOT in the list above: HCAI's markup puts a
# ZERO-WIDTH SPACE (U+200B) between "Retention" and "(Closed)". It is invisible
# in every rendering and would make a literal assertion fail for no visible
# reason, which is the worst kind of tripwire. `ca_reduce_html()` strips
# zero-width characters, and the WDRR heading is matched without its suffix
# alongside the "(Closed)" COUNT, which reaches it either way.
CA_POOL_WDRR_HEADING <- "Workforce Development Recruitment and Retention"

# The page's own statement that nothing is final (Missouri's fourteenth
# question: does the state say what it has not done yet?).
CA_PHASED_MARKER <- "Grant funding opportunities will be released in phases"

# THE AWARD DATES, FROM THE GRANT GUIDES THEMSELVES. These are what make
# California a negative WITH A DATE rather than a negative of unknown age.
CA_AWARD_MILESTONES <- c(
  accel = "Award notifications issued August / September 2026",
  wcap  = "Award notifications issued August / September 2026",
  ehr   = "Notify Subrecipients September 2026",
  wdrr  = "open July 31, 2026, to August 31, 2026"
)

# THE POOL AMOUNTS, IN THE GUIDES' OWN WORDS.
CA_POOL_MARKERS <- c(
  accel = "planning amount totals $39,010,000 for Accelerator Partners",
  wdrr  = "$54,170,000 in CalRHT Budget Period 1 (BP1) funding will be available",
  ehr   = "$11,650,000 in CalRHT Budget Period 1 (BP1) funding will be available",
  wcap  = "$6,500,000 is available to expand and support rural workforce capacity"
)

# THE SRHRP -- the NEGATIVE control's own words. A named STATE funding source,
# which is what `non_rhtp_state_programs.csv` is keyed on.
CA_SRHRP_STATE_FUNDED <- c(
  tax    = paste("Ten percent of the funds from the California Electronic",
                 "Cigarette Excise Tax will be allocated to the Department of",
                 "Health Care Access and Information (HCAI) to operate the",
                 "SRHRP"),
  statute = "Alfred E. Alquist Hospital Facilities Seismic Safety Act",
  purpose = "funding seismic safety compliance projects"
)
# And what must be ABSENT from it. If any of these appears, the SRHRP page has
# changed character and the whole disposition must be re-read.
CA_SRHRP_ABSENT <- c("RHTP", "Rural Health Transformation", "financial assistance award")

# THE SRHRP -- the POSITIVE control's own words. HCAI publishes recipient-level
# awards, with names and amounts, in a recognisable form.
CA_SRHRP_AWARD_CONTROL <- c(
  awarded = "grants (totaling $17.2 million) have been awarded",
  named   = "Mountains Community Hospital",
  priced  = "$3,525,000"
)

# THE SRHRP -- the §0.3 trap on the SAME page. 102 named hospitals, eligible.
CA_SRHRP_ELIGIBILITY <- c(
  heading = "SRHRP Eligible Hospitals",
  clause  = "The table below lists the SRHRP eligible hospitals"
)

# EVERY POOL'S ELIGIBLE CLASS IS HOSPITALS AMONG OTHERS -- New Hampshire's FHC
# answer, not Illinois's ICAHN answer. Losing these sentences must stop the
# build rather than silently re-code a pass-through as hospital-bound.
CA_ELIGIBLE_CLASS_MARKERS <- c(
  ehr  = "Federally Qualified Health Center (FQHC) or FQHC Look-Alike",
  wcap = "Regional Collaborative or Consortium"
)

CA_CREDENTIAL_SHAPES <- c(
  mapbox_token   = "[ps]k\\.ey[A-Za-z0-9_-]{10,}",
  google_api_key = "AIza[A-Za-z0-9_-]{30,}",
  bearer_token   = "(?i)bearer\\s+[A-Za-z0-9._-]{25,}",
  aws_key        = "AKIA[A-Z0-9]{12,}"
)


# -- fetch --------------------------------------------------------------------

ca_path <- function(key) {
  row <- CA_SOURCES[CA_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[CA] unknown source key: ", key, call. = FALSE)
  file.path(CA_EVIDENCE_DIR, row$file)
}

ca_source <- function(key, field) {
  row <- CA_SOURCES[CA_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[CA] unknown source key: ", key, call. = FALSE)
  row[[field]]
}

ca_assert_credential_free <- function(body, label) {
  chunk <- body[seq_len(min(length(body), 4e6))]
  txt   <- rawToChar(chunk[chunk != as.raw(0)])
  Encoding(txt) <- "latin1"
  for (nm in names(CA_CREDENTIAL_SHAPES)) {
    if (stringr::str_detect(txt, CA_CREDENTIAL_SHAPES[[nm]])) {
      stop("[CA] refusing to archive ", label, ": it carries what looks like ",
           "a ", nm, ".", call. = FALSE)
    }
  }
  invisible(TRUE)
}

ca_get <- function(url, label) {
  message("[CA] fetching ", url)
  resp <- httr::GET(url, httr::user_agent(CA_USER_AGENT),
                    httr::config(followlocation = TRUE), httr::timeout(240))
  if (httr::status_code(resp) != 200L) {
    stop("[CA] HTTP ", httr::status_code(resp), " for ", url, call. = FALSE)
  }
  served <- httr::content(resp, as = "raw")
  ca_assert_credential_free(served, label)
  served
}

ca_fetch <- function(force = FALSE) {
  dir.create(CA_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  entries <- purrr::map_dfr(seq_len(nrow(CA_SOURCES)), function(i) {
    src  <- CA_SOURCES[i, ]
    dest <- file.path(CA_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[CA] cached, not re-fetched: ", src$file)
    } else {
      if (i > 1L) Sys.sleep(CA_HOST_THROTTLE_S)
      writeBin(ca_get(src$url, src$file), dest)
    }
    tibble::tibble(file = src$file, url = src$url, bytes = file.size(dest),
                   sha256 = digest::digest(file = dest, algo = "sha256"))
  })
  ca_write_manifest(entries)
  invisible(entries)
}

ca_write_manifest <- function(entries) {
  path <- file.path(CA_EVIDENCE_DIR, "MANIFEST.txt")
  writeLines(c(
    "California -- Rural Health Transformation Program (CalRHT), Year 1.",
    "Archived by R/03ab_ca_year1_probe.R --fetch",
    paste0("User-agent: ", CA_USER_AGENT),
    "",
    "Every file is the body the server sent, BYTE FOR BYTE, written with",
    "writeBin(), so re-hashing a file on disk reproduces its digest below.",
    "The credential guard runs on every fetch and finds nothing, so there is",
    "no reduction to explain.",
    "",
    "CALIFORNIA HAS PUBLISHED NO RECIPIENT-LEVEL RHTP AWARD LIST. Four CalRHT",
    "grant opportunities are all headed '(Closed)' and none names a recipient.",
    "Their own grant guides put award notification in AUGUST / SEPTEMBER 2026",
    "and grant agreements in SEPTEMBER / OCTOBER 2026; WDRR's application",
    "window closed AUGUST 31, 2026. This archive was taken 2026-09-02.",
    "",
    "THE §6.2 ANCHOR IS CMS'S OWN NOTICE OF AWARD, NOT A FOOTER QUOTING ONE.",
    "  2026-03-31_ca_cms_notice_of_award_revised.pdf is CMS's own form:",
    "  recipient CALIFORNIA DEPARTMENT OF HEALTH CARE ACCESS AND INFORMATION,",
    "  Assistance Listing 93.798 Rural Health Transformation Program, Award#",
    "  RHTCMS332078-01-02, budget period 12/29/2025 - 10/30/2026,",
    "  $233,639,308.47. Its Federal Award Date of 03/31/2026 is the date of a",
    "  BUDGET REVISION (Award Action Type 'Revision (Budget)'), not the date",
    "  of the award: the budget period still starts 12/29/2025, which is the",
    "  project's own NOA anchor. A date test keyed on 'Federal Award Date'",
    "  would read California's NOA as three months late.",
    "",
    "ONE FILE IS BOTH CONTROLS AT ONCE, AND IT IS NAMED SO.",
    "  *_BOTH_CONTROLS.html is HCAI's Small and Rural Hospital Relief Program",
    "  (SRHRP) page.",
    "  POSITIVE: HCAI publishes recipient-level awards in a recognisable form",
    "    -- '29 grants (totaling $17.2 million) have been awarded', five named",
    "    with amounts. So 'CalRHT has published no roster' is a statement",
    "    about CalRHT, not about our reading.",
    "  NEGATIVE (§0.1): those awards are NOT RHTP. The SRHRP is funded by the",
    "    California Electronic Cigarette Excise Tax (HSC 130075) under the",
    "    Alfred E. Alquist Hospital Facilities Seismic Safety Act (HSC",
    "    129675), and its page mentions 'RHTP' ZERO times, 'Rural Health",
    "    Transformation' ZERO times and 'federal' ZERO times. ALL ELEVEN of",
    "    RCJ's California Tier 3 candidates come from this programme.",
    "  AND §0.3 ON THE SAME PAGE: it also carries 'SRHRP Eligible Hospitals',",
    "    a table of 102 NAMED California hospitals. That is an ELIGIBILITY",
    "    list sitting directly beneath real awards.",
    "",
    "  *_CONTROL.html is HCAI's newsroom, which carries award announcements",
    "  in a recognisable form and NOT ONE mention of CalRHT or RHTP -- so the",
    "  absence of an award announcement is HCAI's, not our channel's.",
    "",
    "THESE FILE DIGESTS ARE NOT A CHANGE TEST, AND THE REASON IS TWOFOLD.",
    "hcai.ca.gov carries no per-request nonce -- two fetches seconds apart are",
    "byte-identical -- but two fetches HALF AN HOUR apart need not be:",
    "  * the CalRHT page is served with or WITHOUT a ~15 KB ElasticPress",
    "    autosuggest asset block (142,605 or 157,732 bytes), a CACHE VARIANT;",
    "  * the newsroom re-rolls WordPress antispambot() email entities on every",
    "    render -- same length, different bytes, identical rendered text.",
    "The reduced text is IDENTICAL across both variants of both pages (11,162",
    "characters), so --probe compares a CONTENT digest via ca_reduce_html(),",
    "the same reduction the assertions read. robots.txt is 404, so no crawler",
    "policy is on offer and none is being declined.",
    "",
    "file  bytes  sha256",
    paste(entries$file, entries$bytes, entries$sha256, sep = "  ")
  ), path)
  invisible(path)
}


# -- readers ------------------------------------------------------------------

#' The one HTML reduction, so the probe and the assertions read the same bytes
#'
#' Missouri's rule (session 29): a probe that reduces differently from the
#' assertions it feeds drifts away from them silently, and the drift shows up
#' as a tripwire that stops firing.
#'
#' IT STRIPS ZERO-WIDTH CHARACTERS, AND THAT IS NOT COSMETIC. HCAI's markup
#' puts a ZERO-WIDTH SPACE (U+200B) between "Retention" and "(Closed)" in the
#' WDRR heading. It is invisible in every rendering, in every diff and in every
#' error message, so a literal assertion on that heading fails with no visible
#' cause. Stripping it here means one reduction handles it for every reader.
ca_reduce_html <- function(raw) {
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "UTF-8"
  txt <- stringr::str_remove_all(txt, "(?s)<(script|style)[^>]*>.*?</\\1>")
  txt <- stringr::str_replace_all(txt, "<[^>]+>", " ")
  txt <- rhtp_ca_unescape(txt)
  txt <- stringr::str_remove_all(txt, "[​‌‍﻿]")
  stringr::str_squish(txt)
}

rhtp_ca_unescape <- function(x) {
  x <- stringr::str_replace_all(x, "&nbsp;", " ")
  x <- stringr::str_replace_all(x, "&amp;", "&")
  x <- stringr::str_replace_all(x, "&#39;|&rsquo;|&#8217;", "'")
  x <- stringr::str_replace_all(x, "&quot;|&ldquo;|&rdquo;", '"')
  x <- stringr::str_replace_all(x, "&lt;", "<")
  x <- stringr::str_replace_all(x, "&gt;", ">")
  x <- stringr::str_replace_all(x, "&#8211;|&ndash;", "-")
  # LITERAL typographic punctuation, folded to ASCII for the same reason the
  # zero-width space is stripped: HCAI's prose carries a curly apostrophe in
  # "California's approach" and a non-breaking hyphen in "state-driven", and an
  # assertion written from a rendered copy of the page fails against them with
  # no visible difference to point at. The ARCHIVED BYTES ARE UNTOUCHED -- this
  # is the matching text only.
  x <- stringr::str_replace_all(x, "[\u2018\u2019\u201b]", "'")
  x <- stringr::str_replace_all(x, "[\u201c\u201d\u201f]", '"')
  x <- stringr::str_replace_all(x, "[\u2010\u2011\u2012\u2013\u2014]", "-")
  x
}

ca_html_text <- function(key, body = NULL) {
  if (is.null(body)) {
    p <- ca_path(key)
    body <- readBin(p, "raw", file.size(p))
  }
  ca_reduce_html(body)
}

ca_pdf_text <- function(key, body = NULL) {
  if (!exists("rhtp_pdf_text")) source(here::here("R", "utils_pdf_text.R"))
  path <- if (is.null(body)) {
    ca_path(key)
  } else {
    tmp <- tempfile(fileext = ".pdf"); writeBin(body, tmp); tmp
  }
  stringr::str_squish(paste(rhtp_pdf_text(path), collapse = " "))
}

#' The SRHRP eligible-hospital table, counted rather than asserted
#'
#' §0.3's largest head count in this project. Read as a TABLE and not as a
#' number in prose, because the number is not in prose: HCAI publishes the
#' hospitals and never says how many there are.
ca_srhrp_eligible_rows <- function(body = NULL) {
  if (is.null(body)) {
    p <- ca_path("srhrp"); body <- readBin(p, "raw", file.size(p))
  }
  txt <- rawToChar(body[body != as.raw(0)])
  Encoding(txt) <- "UTF-8"
  tabs <- stringr::str_extract_all(txt, "(?s)<table.*?</table>")[[1]]
  if (!length(tabs)) return(character(0))
  rows <- stringr::str_extract_all(tabs[1], "(?s)<tr.*?</tr>")[[1]]
  cells <- purrr::map_chr(rows, function(r) {
    c1 <- stringr::str_extract(r, "(?s)<t[hd][^>]*>(.*?)</t[hd]>")
    if (is.na(c1)) return(NA_character_)
    stringr::str_squish(rhtp_ca_unescape(stringr::str_replace_all(c1, "<[^>]+>", " ")))
  })
  cells <- cells[!is.na(cells)]
  # drop the header row; every data row is "<facility id> - <name>"
  cells[stringr::str_detect(cells, "^\\d{5,}\\s*[-–]")]
}


#' The §7.1 allotment anchor for California, read rather than typed
ca_allotment_anchor <- function() {
  path <- here::here("data", "reference", "cms_fy2026_allotments.csv")
  a <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  v <- a$fy2026_allotment[a$state == "CA"]
  if (length(v) != 1L) {
    stop("[CA] cms_fy2026_allotments.csv has ", length(v), " rows for CA.",
         call. = FALSE)
  }
  v
}

#' The §6.2 NOA anchor for California, read rather than typed
ca_noa_anchor <- function() {
  path <- here::here("data", "reference", "cms_state_noa_dates.csv")
  d <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  v <- d$noa_date[d$state == "CA"]
  if (length(v) != 1L) {
    stop("[CA] cms_state_noa_dates.csv has ", length(v), " rows for CA.",
         call. = FALSE)
  }
  as.character(v)
}


# -- §6.2 provenance ----------------------------------------------------------

#' CMS'S OWN NOTICE OF AWARD -- the anchor, and stronger than any footer
#'
#' Nevada was the first state in this project to publish the NOA rather than a
#' footer quoting it; California is the second. Every field below is read out
#' of CMS's own form.
#'
#' AND IT CARRIES TWO DATES THAT MUST NOT BE CONFUSED. The Federal Award Date
#' is 03/31/2026 and the Award Action Type is "Revision (Budget)" -- CMS
#' approving a revised budget and lifting a $50,000,000 restriction. The BUDGET
#' PERIOD still starts 12/29/2025, which is the project's own NOA anchor in
#' `cms_state_noa_dates.csv`. A date test keyed on the words "Federal Award
#' Date" would read California's award as three months later than every other
#' state's and quarantine work that predates the revision. §0.2's lesson on a
#' new axis: two official dates on one document, and only the scope separates
#' them.
ca_assert_noa_is_cms_award <- function(noa = NULL) {
  if (is.null(noa)) noa <- ca_pdf_text("cms_noa")
  for (nm in names(CA_NOA_MARKERS)) {
    if (!stringr::str_detect(noa, stringr::fixed(CA_NOA_MARKERS[[nm]]))) {
      stop("[CA] the archived Notice of Award no longer carries '", nm,
           "' (", CA_NOA_MARKERS[[nm]], "). It is the §6.2 anchor for the ",
           "whole state.", call. = FALSE)
    }
  }
  if (!stringr::str_detect(noa, stringr::fixed(CA_STATED$noa_budget_start))) {
    stop("[CA] the Notice of Award no longer carries its budget period start ",
         CA_STATED$noa_budget_start, ", which is the 2025-12-29 anchor.",
         call. = FALSE)
  }
  if (!stringr::str_detect(noa, stringr::fixed(CA_STATED$noa_action_type))) {
    stop("[CA] the Notice of Award no longer calls itself '",
         CA_STATED$noa_action_type, "'. That word is what keeps its ",
         "03/31/2026 Federal Award Date from being read as the award date.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' The provenance, from PROGRAMME-SCOPED sentences (session 27's axis)
ca_assert_programme_provenance <- function(calrht = NULL) {
  if (is.null(calrht)) calrht <- ca_html_text("calrht")
  for (nm in names(CA_PROGRAMME_SCOPED)) {
    if (!stringr::str_detect(calrht, stringr::fixed(CA_PROGRAMME_SCOPED[[nm]]))) {
      stop("[CA] the CalRHT programme page no longer carries the ",
           "programme-scoped sentence '", nm, "'. Those sentences, and CMS's ",
           "own Notice of Award, are what tie this state to RHTP.",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' The CMS footer -- STRONG form, and demoted anyway
#'
#' Session 27's audit split the footer on its grammatical SUBJECT. California's
#' names the programme ("The CalRHT program is supported by"), so it is the
#' strong form -- and it is still used for the AMOUNT only, because the NOA is
#' better evidence than any footer. That is a NEW position on the axis: every
#' previous demotion in this repository was of a weak footer. `strict = FALSE`
#' returns NA with a message rather than throwing (Kansas's demotion), so an
#' HCAI re-post that drops the boilerplate cannot hard-fail California for no
#' reason -- and a future state whose ONLY evidence is a footer does not
#' thereby pass the test California passes.
#'
#' THE ONE-CENT DISAGREEMENT IS PINNED, NOT CORRECTED (§8). CMS's NOA says
#' .47; HCAI's pages say .46; HCAI's FM-OB grant guide says .47.
ca_assert_footer_corroborates <- function(strict = FALSE, calrht = NULL,
                                          wcap = NULL) {
  if (is.null(calrht)) calrht <- ca_html_text("calrht")
  if (!stringr::str_detect(calrht, stringr::fixed(CA_FOOTER_STRONG))) {
    msg <- "[CA] the CalRHT page no longer carries the CMS financial-assistance footer."
    if (strict) stop(msg, call. = FALSE)
    message(msg, " Non-strict: the NOA and two programme-scoped sentences ",
            "carry the provenance, so this is reported, not fatal.")
    return(invisible(NA))
  }
  if (!stringr::str_detect(calrht, stringr::fixed(CA_STATED$footer_amount))) {
    stop("[CA] the footer amount is no longer ", CA_STATED$footer_amount,
         ". It corroborates the §7.1 anchor and its cents are pinned.",
         call. = FALSE)
  }
  # The outlier that agrees with CMS.
  if (is.null(wcap)) wcap <- ca_pdf_text("gg_wcap")
  if (!stringr::str_detect(wcap, stringr::fixed(CA_STATED$noa_amount))) {
    stop("[CA] the FM-OB grant guide no longer carries ", CA_STATED$noa_amount,
         ". It is the one HCAI document whose cents agree with CMS's own ",
         "Notice of Award, and the disagreement is a finding, not a defect.",
         call. = FALSE)
  }
  anchor <- ca_allotment_anchor()
  if (round(anchor) != CA_STATED$cms_allotment_anchor) {
    stop("[CA] the §7.1 allotment anchor moved: ", anchor, call. = FALSE)
  }
  invisible(TRUE)
}

#' Every CalRHT opportunity postdates the 2025-12-29 Notice of Award
#'
#' Texas's cheapest test (session 19): a solicitation that closed before the
#' state had the money cannot have spent it. Here it runs the other way and
#' confirms these four DO postdate it -- all four guides are dated 2026.
ca_assert_after_noa <- function(accel = NULL, ehr = NULL) {
  if (is.null(accel)) accel <- ca_pdf_text("gg_accel")
  if (is.null(ehr))   ehr   <- ca_pdf_text("gg_ehr")
  noa <- ca_noa_anchor()
  if (!identical(as.character(noa), "2025-12-29")) {
    stop("[CA] the §6.2 NOA anchor for California is ", noa, ", not ",
         "2025-12-29.", call. = FALSE)
  }
  if (!stringr::str_detect(accel, stringr::fixed("Application close August 14"))) {
    stop("[CA] the Accelerator Partners guide no longer states its August 14, ",
         "2026 close. Its date is what puts it after the NOA.", call. = FALSE)
  }
  if (!stringr::str_detect(ehr, stringr::fixed("August 21, 2026"))) {
    stop("[CA] the EHR guide no longer states its August 21, 2026 close.",
         call. = FALSE)
  }
  invisible(TRUE)
}


# -- the negative, and the controls that make it mean something ---------------

#' CALIFORNIA HAS NAMED NO RECIPIENT. Four pools, all closed, no roster.
#'
#' DESIGNED TO FAIL the day the "(Closed)" count moves in EITHER direction: a
#' fifth opportunity has opened, or one has awarded and been relabelled.
ca_assert_no_award_roster <- function(funding = NULL) {
  if (is.null(funding)) funding <- ca_html_text("funding")
  n <- stringr::str_count(funding, stringr::fixed(CA_CLOSED_MARKER))
  if (n != CA_CLOSED_EXPECTED) {
    stop("[CA] the CalRHT funding page carries ", n, " '",
         CA_CLOSED_MARKER, "' headings, not ", CA_CLOSED_EXPECTED,
         ". Either a fifth opportunity opened or one has awarded. THIS IS ",
         "THE SIGNAL: read the page, and if California has published a ",
         "roster, R/03ab must be REWRITTEN as an award extractor -- ",
         "ca_year1_status.csv has no amount column by design.", call. = FALSE)
  }
  for (nm in names(CA_POOL_HEADINGS)) {
    if (!stringr::str_detect(funding, stringr::fixed(CA_POOL_HEADINGS[[nm]]))) {
      stop("[CA] the '", nm, "' pool is no longer headed '",
           CA_POOL_HEADINGS[[nm]], "'.", call. = FALSE)
    }
  }
  if (!stringr::str_detect(funding, stringr::fixed(CA_POOL_WDRR_HEADING))) {
    stop("[CA] the WDRR pool heading is gone.", call. = FALSE)
  }
  if (!stringr::str_detect(funding, stringr::fixed(CA_PHASED_MARKER))) {
    stop("[CA] the funding page no longer says opportunities '",
         CA_PHASED_MARKER, "'. That sentence is HCAI's own statement that ",
         "the programme is mid-rollout.", call. = FALSE)
  }
  invisible(TRUE)
}

#' THE AWARDS ARE DUE NOW, AND THE GUIDES SAY SO
#'
#' Missouri's fourteenth question, answered by the state: California's own
#' grant guides date the thing that has not happened. This is what makes it a
#' negative WITH A DATE (Wisconsin's shape) rather than a negative of unknown
#' age -- and the date is inside the week this ran.
ca_assert_award_dates_pending <- function(accel = NULL, wcap = NULL,
                                          ehr = NULL, wdrr = NULL) {
  if (is.null(accel)) accel <- ca_pdf_text("gg_accel")
  if (is.null(wcap))  wcap  <- ca_pdf_text("gg_wcap")
  if (is.null(ehr))   ehr   <- ca_pdf_text("gg_ehr")
  if (is.null(wdrr))  wdrr  <- ca_pdf_text("gg_wdrr")
  bodies <- list(accel = accel, wcap = wcap, ehr = ehr, wdrr = wdrr)
  for (nm in names(CA_AWARD_MILESTONES)) {
    if (!stringr::str_detect(bodies[[nm]],
                             stringr::fixed(CA_AWARD_MILESTONES[[nm]]))) {
      stop("[CA] the ", nm, " guide no longer carries its award milestone '",
           CA_AWARD_MILESTONES[[nm]], "'. Those milestones are what date ",
           "every California negative.", call. = FALSE)
    }
  }
  for (nm in names(CA_POOL_MARKERS)) {
    if (!stringr::str_detect(bodies[[nm]],
                             stringr::fixed(CA_POOL_MARKERS[[nm]]))) {
      stop("[CA] the ", nm, " guide no longer states its pool: '",
           CA_POOL_MARKERS[[nm]], "'.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' THE ELIGIBLE CLASS IS HOSPITALS AMONG OTHERS -- New Hampshire's answer
#'
#' Session 29's fifteenth question, and it decides whether a future California
#' pass-through dollar is a hospital dollar. Illinois's ICAHN codes `Yes`
#' because eligibility was HOSPITALS ONLY; New Hampshire's FHC codes `Unclear`
#' because its class is "critical access hospitals" among others. Every CalRHT
#' pool that reaches hospitals reaches them alongside FQHCs, RHCs, Tribal
#' clinics, health care districts and academic medical centres -- so when
#' California awards, NO pool here is Illinois's class, and §0.3 governs any
#' intermediary. Losing these sentences must stop the build rather than
#' silently re-code $111.3M as hospital-bound.
ca_assert_eligible_class_not_hospitals_only <- function(ehr = NULL,
                                                        wcap = NULL) {
  if (is.null(ehr))  ehr  <- ca_pdf_text("gg_ehr")
  if (is.null(wcap)) wcap <- ca_pdf_text("gg_wcap")
  bodies <- list(ehr = ehr, wcap = wcap)
  for (nm in names(CA_ELIGIBLE_CLASS_MARKERS)) {
    if (!stringr::str_detect(bodies[[nm]],
                             stringr::fixed(CA_ELIGIBLE_CLASS_MARKERS[[nm]]))) {
      stop("[CA] the ", nm, " guide's eligible class no longer names '",
           CA_ELIGIBLE_CLASS_MARKERS[[nm]], "'. If a pool has become ",
           "HOSPITALS ONLY that is Illinois's coding and a different answer ",
           "-- read it deliberately.", call. = FALSE)
    }
  }
  invisible(TRUE)
}


#' THE §0.1 NEGATIVE: the SRHRP is a CALIFORNIA STATE PROGRAMME
#'
#' All eleven California Tier 3 candidates come from this one programme, and
#' every one is a named California hospital with a real dollar amount on a real
#' executed HCAI award. Texas's defect (session 19) with Maine's ratio: Texas's
#' 53 rows were 78% of its candidate set; California's are ELEVEN OF ELEVEN.
#'
#' What disqualifies it is not a guess. The SRHRP names its own funding source
#' -- ten percent of the CALIFORNIA ELECTRONIC CIGARETTE EXCISE TAX (HSC
#' 130075) -- and its own statutory purpose, seismic compliance under the
#' ALFRED E. ALQUIST HOSPITAL FACILITIES SEISMIC SAFETY ACT (HSC 129675). The
#' page mentions RHTP zero times.
#'
#' THE ABSENCE HALF IS ASSERTED TOO, AND IT MATTERS MORE THAN THE PRESENCE
#' HALF. If "RHTP" ever appears on this page, either HCAI has begun funding
#' seismic work with RHTP money or the page has been merged with another -- and
#' either way the eleven candidates must be re-read from scratch rather than
#' left disposed of by a stale assertion.
ca_assert_srhrp_is_not_rhtp <- function(srhrp = NULL) {
  if (is.null(srhrp)) srhrp <- ca_html_text("srhrp")
  for (nm in names(CA_SRHRP_STATE_FUNDED)) {
    if (!stringr::str_detect(srhrp, stringr::fixed(CA_SRHRP_STATE_FUNDED[[nm]]))) {
      stop("[CA] the SRHRP page no longer states its '", nm, "'. That ",
           "sentence is what disposes of all eleven RCJ candidates.",
           call. = FALSE)
    }
  }
  for (tok in CA_SRHRP_ABSENT) {
    if (stringr::str_detect(srhrp, stringr::fixed(tok))) {
      stop("[CA] the SRHRP page now mentions '", tok, "'. It did not when the ",
           "eleven RCJ candidates were disposed of as state cigarette-tax ",
           "money. THIS IS THE SIGNAL: re-read the page and the candidates ",
           "before trusting ca_rcj_candidate_disposition.csv.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' THE POSITIVE CONTROL, ON THE SAME PAGE AS THE NEGATIVE
#'
#' Without it, "CalRHT has published no roster" is indistinguishable from "we
#' are reading the wrong page". HCAI demonstrably publishes recipient-level
#' awards, named and priced, in a recognisable form -- it just does not publish
#' any for CalRHT.
ca_assert_srhrp_is_award_control <- function(srhrp = NULL) {
  if (is.null(srhrp)) srhrp <- ca_html_text("srhrp")
  for (nm in names(CA_SRHRP_AWARD_CONTROL)) {
    if (!stringr::str_detect(srhrp, stringr::fixed(CA_SRHRP_AWARD_CONTROL[[nm]]))) {
      stop("[CA] the SRHRP page no longer carries its award control '", nm,
           "'. Without a demonstrated roster form on this host, California's ",
           "negative means nothing.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' §0.3 ON THE SAME PAGE AGAIN: 102 NAMED HOSPITALS WHO ARE MERELY ELIGIBLE
#'
#' The largest named-hospital table this project has met, and it sits directly
#' beneath real awards on the same page -- which is what makes it worse than
#' Wisconsin's 213 DPI districts (a separate page, and school districts) and
#' Maine's eleven (a separate release, and invited rather than eligible). A
#' reader who takes this table for a roster invents 102 California hospital
#' recipients.
#'
#' THE COUNT IS DERIVED FROM THE TABLE, NOT TYPED. HCAI publishes the hospitals
#' and never says how many there are, so a typed constant here would be this
#' pipeline's own arithmetic presented as the state's.
#'
#' AND THE TABLE HAS 105 `<tr>` ROWS AND 102 HOSPITALS. One is the header and
#' TWO ARE ENTIRELY BLANK SPACER ROWS, at positions 51 and 100. A reader that
#' counted rows would report 104. That is this file's own lesson arriving one
#' tier down -- a row count is not a hospital count -- so the reader requires
#' each kept row to open with HCAI's own facility id, and the blanks fall out
#' because they carry no identity rather than because a threshold excluded
#' them.
ca_assert_srhrp_eligibility_not_receipt <- function(srhrp = NULL,
                                                    rows = NULL) {
  if (is.null(srhrp)) srhrp <- ca_html_text("srhrp")
  for (nm in names(CA_SRHRP_ELIGIBILITY)) {
    if (!stringr::str_detect(srhrp, stringr::fixed(CA_SRHRP_ELIGIBILITY[[nm]]))) {
      stop("[CA] the SRHRP page no longer carries '", nm, "'. Its eligible-",
           "hospital table is a §0.3 trap and must stay labelled as one.",
           call. = FALSE)
    }
  }
  if (is.null(rows)) rows <- ca_srhrp_eligible_rows()
  if (length(rows) != CA_STATED$srhrp_eligible_n) {
    stop("[CA] the SRHRP eligible-hospital table has ", length(rows),
         " rows, not ", CA_STATED$srhrp_eligible_n, ". It is an ELIGIBILITY ",
         "list either way -- re-read it, and do not let the count drift into ",
         "a roster.", call. = FALSE)
  }
  invisible(rows)
}

#' HCAI'S NEWSROOM IS THE SECOND POSITIVE CONTROL, AND IT IS ABOUT THE CHANNEL
#'
#' Indiana's sixth question (session 24): is the state's award channel
#' somewhere other than its programme page? HCAI runs a newsroom that carries
#' award announcements in a recognisable form ("California Certifies 5,000
#' Wellness Coaches and Awards Scholarships to 613 Students Statewide") and
#' mentions CalRHT and RHTP ZERO times. So the absence of a CalRHT award
#' announcement is HCAI's, not our channel's.
#'
#' AND THE EHR GRANT GUIDE SAYS WHY THIS CHANNEL MATTERS: subrecipients must
#' submit press releases to HCAI two weeks in advance, and may only publish
#' after "HCAI, CalHHS, or the Governor's Office issues a statement". So when
#' California awards, the first public naming may well be a Governor's Office
#' or CalHHS release rather than the CalRHT page -- which is where to look.
ca_assert_newsroom_control <- function(news = NULL) {
  if (is.null(news)) news <- ca_html_text("newsroom")
  if (!stringr::str_detect(news, stringr::fixed("Awards Scholarships"))) {
    stop("[CA] the HCAI newsroom no longer carries an award announcement. It ",
         "is the control that makes 'no CalRHT announcement' mean something.",
         call. = FALSE)
  }
  for (tok in c("CalRHT", "Rural Health Transformation")) {
    if (stringr::str_detect(news, stringr::fixed(tok))) {
      stop("[CA] the HCAI newsroom now mentions '", tok, "'. THIS IS THE ",
           "SIGNAL -- California may have announced. Read it.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' No award file exists, and the status table cannot grow an amount column
ca_assert_no_award_file <- function() {
  if (file.exists(here::here(CA_AWARDS_CSV))) {
    stop("[CA] ", CA_AWARDS_CSV, " exists. California has published no ",
         "recipient-level award list; if that has changed, write the ",
         "extractor deliberately and delete this assertion in the same ",
         "commit.", call. = FALSE)
  }
  path <- here::here(CA_STATUS_CSV)
  if (file.exists(path)) {
    cols <- names(readr::read_csv(path, n_max = 0, show_col_types = FALSE))
    bad  <- intersect(cols, c("amount", "round_amount", "amount_announced"))
    if (length(bad)) {
      stop("[CA] ca_year1_status.csv carries an amount column (",
           paste(bad, collapse = ", "), "). It is a STATUS table: California ",
           "has named no recipient, so no sum over it could mean anything.",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}

rhtp_ca_assert <- function(strict_footer = FALSE) {
  ca_assert_noa_is_cms_award()
  ca_assert_programme_provenance()
  ca_assert_footer_corroborates(strict = strict_footer)
  ca_assert_after_noa()
  ca_assert_no_award_roster()
  ca_assert_award_dates_pending()
  ca_assert_eligible_class_not_hospitals_only()
  ca_assert_srhrp_is_not_rhtp()
  ca_assert_srhrp_is_award_control()
  ca_assert_srhrp_eligibility_not_receipt()
  ca_assert_newsroom_control()
  ca_assert_no_award_file()
  invisible(TRUE)
}


# -- the status table ---------------------------------------------------------

#' What each California RHTP funding channel publishes
#'
#' DELIBERATELY NO `amount` COLUMN (Texas's device, Wisconsin's and Maine's
#' after it). California has named no recipient and published no per-recipient
#' figure; the pool amounts live in `stated_pool` as the guides' own words,
#' which cannot be summed by accident.
rhtp_ca_year1_status <- function() {
  tibble::tribble(
    ~channel, ~administrator, ~stated_pool, ~stage, ~eligible_class,
    ~publishes_roster, ~evidence,

    "Accelerator Partners (Transformative Care Model)", "HCAI",
    "$39,010,000 BP1 planning amount; award ceiling $8 million; 5-25 awards",
    "CLOSED_UNAWARDED",
    paste("HOSPITALS AMONG OTHERS -- 'support for hospitals or other",
          "organizations in rural regions'; funding 'may also support",
          "hospitals, clinics, Tribal health programs, and affiliated",
          "providers'. New Hampshire's FHC class, not Illinois's ICAHN class."),
    "No",
    paste("Headed '(Closed)'. Its own grant guide: 'Application close August",
          "14, 2026', 'CMS review of selected applicants August 2026',",
          "'Award notifications issued August / September 2026', 'Grant",
          "agreements executed September / October 2026'. THE LARGEST",
          "HOSPITAL-FACING POOL CALIFORNIA HAS PUBLISHED, and §0.3 governs",
          "all of it until a recipient is named."),

    "Workforce Development Recruitment and Retention (WDRR)", "HCAI",
    "$54,170,000 BP1 funding",
    "CLOSED_UNAWARDED",
    paste("HOSPITALS AMONG OTHERS -- rural hospitals including CAHs, FQHCs",
          "and FQHC Look-Alikes, RHCs, Tribal clinics, health care districts.",
          "A TWO-STAGE programme: HCAI awards ORGANISATIONS, which then pay",
          "bonuses to individual Health Professionals, so even the eventual",
          "organisational awardees are not the ultimate recipients."),
    "No",
    paste("The largest single CalRHT pool. Its guide: the organisational",
          "application 'will be open July 31, 2026, to August 31, 2026' --",
          "CLOSED TWO DAYS BEFORE THIS FILE RAN. No roster."),

    "Electronic Health Record (EHR) Modernization", "HCAI",
    "$11,650,000 BP1 funding; up to 18 grants; maximum $2,000,000 each",
    "CLOSED_UNAWARDED",
    paste("HOSPITALS AMONG OTHERS -- 'Hospital (rural)' heads a table that",
          "also lists FQHC/Look-Alike, RHC, Tribal clinic, other comprehensive",
          "community health clinic and health care district."),
    "No",
    paste("Applications closed 'August 21, 2026, at 3:00 p.m.'; the guide's",
          "next milestone is 'Notify Subrecipients September 2026', then",
          "'Grant Agreement Execution September/October 2026'."),

    "FM-OB Fellowship Subaward (Expand and Support Rural Workforce Capacity)",
    "HCAI", "$6,500,000 BP1 funding",
    "CLOSED_UNAWARDED",
    paste("GME SPONSORING INSTITUTIONS that are also one of: hospital",
          "including CAH, FQHC or Look-Alike, Tribal clinic, RHC, other",
          "comprehensive community health clinic, regional collaborative or",
          "consortium, health care district, academic medical center or",
          "university. Hospitals among others, and university-weighted."),
    "No",
    paste("Headed '(Closed)'. Its guide: 'Application close August 14, 2026',",
          "'Award notifications issued August / September 2026'. THIS IS THE",
          "ONE HCAI DOCUMENT WHOSE CMS FOOTER CENTS AGREE WITH CMS'S OWN",
          "NOTICE OF AWARD ($233,639,308.47, against .46 elsewhere)."),

    "HCAI newsroom -- WHERE AN ANNOUNCEMENT WOULD LAND", "HCAI",
    "n/a", "NO_ANNOUNCEMENT", "n/a", "No",
    paste("THE CHANNEL CONTROL (Indiana's sixth question). HCAI's newsroom",
          "carries award announcements in a recognisable form and mentions",
          "CalRHT and RHTP ZERO times. And the EHR grant guide says the first",
          "public naming may not be HCAI's at all: subrecipients must submit",
          "press releases to HCAI two weeks in advance and may publish only",
          "after 'HCAI, CalHHS, or the Governor's Office issues a statement'."),

    "Small and Rural Hospital Relief Program (SRHRP) -- NOT RHTP", "HCAI",
    "$46 million available; 29 grants totalling $17.2 million awarded",
    "AWARDED_BUT_NOT_RHTP",
    paste("Small (<50 beds), rural or Critical Access hospitals. A table of",
          "102 NAMED eligible California hospitals is published beside the",
          "awards -- ELIGIBILITY, NOT RECEIPT (§0.3)."),
    "Yes -- FOR A DIFFERENT PROGRAMME",
    paste("BOTH CONTROLS AT ONCE. Positive: HCAI publishes recipient-level",
          "awards, named and priced, so CalRHT's silence is CalRHT's.",
          "Negative: this is CALIFORNIA STATE money -- 'Ten percent of the",
          "funds from the California Electronic Cigarette Excise Tax' (HSC",
          "130075), for seismic compliance under the Alfred E. Alquist",
          "Hospital Facilities Seismic Safety Act (HSC 129675) -- and the",
          "page mentions RHTP, 'Rural Health Transformation' and 'federal'",
          "ZERO times. ALL ELEVEN RCJ CALIFORNIA CANDIDATES COME FROM HERE.")
  ) %>%
    dplyr::mutate(state = "CA", .before = 1)
}


# -- RCJ candidate disposition ------------------------------------------------

ca_rcj_candidates <- function() {
  rt <- readRDS(here::here("data", "interim", "stage2_record_table.rds"))
  rt %>% dplyr::filter(state == "CA", award_tier == "SUBAWARD")
}

CA_SRHRP_SOURCE_MARKER <- "Small and Rural Hospital Relief Program"

#' Why each of RCJ's California Tier 3 candidates is not an RHTP award
#'
#' The counts are RE-DERIVED from the record table on every run, never typed,
#' so the day California's candidate set moves the build fails instead of the
#' table quietly ceasing to cover it.
rhtp_ca_rcj_disposition <- function(cands = NULL) {
  if (is.null(cands)) cands <- ca_rcj_candidates()
  prov    <- paste(cands$source_doc_title, cands$solicitation_number)
  is_srhrp <- stringr::str_detect(prov, stringr::fixed(CA_SRHRP_SOURCE_MARKER))
  amt     <- cands$amount_announced
  hosp    <- stringr::str_detect(cands$awardee_name_clean,
                                 stringr::regex("hospital|healthcare district|health care district",
                                                ignore_case = TRUE))

  if (!all(is_srhrp)) {
    stop("[CA] ", sum(!is_srhrp), " California Tier 3 candidates are NOT from ",
         "the SRHRP. This file's whole disposition is that all of them are. ",
         "Read the new ones before building.", call. = FALSE)
  }

  tibble::tribble(
    ~group, ~rows, ~distinct_awardees, ~named_hospital_rows, ~rcj_amount_sum,
    ~disposition, ~why,

    paste("Small and Rural Hospital Relief Program (SRHRP) seismic",
          "compliance grants -- CALIFORNIA STATE CIGARETTE-TAX MONEY"),
    sum(is_srhrp), dplyr::n_distinct(cands$awardee_name_clean[is_srhrp]),
    sum(hosp & is_srhrp), sum(amt[is_srhrp], na.rm = TRUE),
    "NOT_RHTP_STATE_PROGRAM",
    paste0(
      "ALL ", sum(is_srhrp), " OF CALIFORNIA'S TIER 3 CANDIDATES, AND ",
      sum(hosp & is_srhrp), " OF THEM ARE NAMED CALIFORNIA HOSPITALS WITH ",
      "REAL DOLLAR AMOUNTS. Every one is filed under one source document, ",
      "'CA - 2026 - Small and Rural Hospital Relief Program (SRHRP) - HCAI', ",
      "and the SRHRP is a CALIFORNIA STATE PROGRAMME: HCAI's own page says ",
      "'Ten percent of the funds from the California Electronic Cigarette ",
      "Excise Tax will be allocated to [HCAI] to operate the SRHRP (HSC ",
      "Section 130075)', and its statutory purpose is seismic compliance ",
      "under the Alfred E. Alquist Hospital Facilities Seismic Safety Act ",
      "(HSC Section 129675). The page mentions 'RHTP' ZERO times, 'Rural ",
      "Health Transformation' ZERO times and 'federal' ZERO times. THE ",
      "DESCRIPTIONS GIVE IT AWAY IN THE AGGREGATOR ITSELF and nobody read ",
      "them: MTCAP, MTCAR, SPC-4D and NPC evaluations are seismic ",
      "engineering deliverables, not health care. TEXAS'S DEFECT WITH ",
      "MAINE'S RATIO -- Texas's 53 rows were 78% of its candidate set; ",
      "California's are ELEVEN OF ELEVEN, every one a real executed award ",
      "from the SAME AGENCY that administers CalRHT. An extractor built ",
      "from this candidate list would publish $",
      format(sum(amt[is_srhrp], na.rm = TRUE), big.mark = ",",
             scientific = FALSE),
      " of state cigarette-tax money as California's RHTP hospital dollars. ",
      "RCJ ALSO CARRIES COMPONENTS RATHER THAN GRANTS: George L Mee Memorial ",
      "Hospital appears twice at $500,000 and $280,000, which is HCAI's own ",
      "published $780,000 grant split into its line items -- so even the ",
      "row COUNT is not the award count.")
  ) %>%
    dplyr::mutate(state = "CA", .before = 1)
}


# -- build / report -----------------------------------------------------------

rhtp_ca_build <- function() {
  rhtp_ca_assert()
  status <- rhtp_ca_year1_status()
  dispo  <- rhtp_ca_rcj_disposition()
  readr::write_csv(status, here::here(CA_STATUS_CSV))
  readr::write_csv(dispo,  here::here(CA_DISPO_CSV))
  ca_assert_no_award_file()
  message("[CA] wrote ", CA_STATUS_CSV, " (", nrow(status), " rows) and ",
          CA_DISPO_CSV, " (", nrow(dispo), " rows).")
  message("[CA] NO ca_year1_awardees.csv was written, and that is the finding.")
  invisible(list(status = status, disposition = dispo))
}

rhtp_ca_report <- function() {
  cands  <- ca_rcj_candidates()
  dispo  <- rhtp_ca_rcj_disposition(cands)
  status <- rhtp_ca_year1_status()
  pools  <- CA_STATED$pool_accel + CA_STATED$pool_wdrr + CA_STATED$pool_ehr +
    CA_STATED$pool_wcap
  allot  <- ca_allotment_anchor()

  cat("\nCALIFORNIA -- RHTP Year 1 (CalRHT)\n")
  cat(strrep("=", 78), "\n\n")
  cat(sprintf("  CMS FY2026 allotment           $%s\n",
              format(allot, big.mark = ",", scientific = FALSE)))
  cat(sprintf("  Announced across four pools    $%s  (%.1f%%)\n",
              format(pools, big.mark = ",", scientific = FALSE),
              100 * pools / allot))
  cat("  RECIPIENT-LEVEL AWARD LIST     NONE PUBLISHED\n")
  cat("  NAMED HOSPITALS                0\n")
  cat("  HOSPITAL DOLLARS               $0\n\n")

  cat("  California is at SOLICITATION stage, and the window is open NOW.\n")
  cat("  All four CalRHT opportunities are headed '(Closed)' and none names\n")
  cat("  a recipient. Their own grant guides put award notification in\n")
  cat("  AUGUST / SEPTEMBER 2026 and grant agreements in SEPTEMBER /\n")
  cat("  OCTOBER 2026; WDRR's window closed AUGUST 31, 2026.\n\n")

  cat("  WHAT EACH CHANNEL PUBLISHES\n")
  for (i in seq_len(nrow(status))) {
    cat(sprintf("    %-52s %-22s roster: %s\n",
                substr(status$channel[i], 1, 52),
                substr(status$stage[i], 1, 22),
                status$publishes_roster[i]))
  }

  cat(sprintf("\n  RCJ Tier 3 candidates          %d\n", nrow(cands)))
  for (i in seq_len(nrow(dispo))) {
    cat(sprintf("    %-46s %2d rows  $%s\n",
                substr(dispo$group[i], 1, 46), dispo$rows[i],
                format(dispo$rcj_amount_sum[i], big.mark = ",",
                       scientific = FALSE)))
    cat(sprintf("      named hospitals among them: %d of %d\n",
                dispo$named_hospital_rows[i], dispo$rows[i]))
  }
  cat("  RHTP subawards among them      0\n\n")

  cat("  THE POOL TO WATCH IS ACCELERATOR PARTNERS, $39,010,000, whose own\n")
  cat("  guide calls it 'support for hospitals or other organizations in\n")
  cat("  rural regions' -- hospitals AMONG OTHERS, which is New Hampshire's\n")
  cat("  FHC class and not Illinois's ICAHN class. Until a recipient is\n")
  cat("  named it is eligibility, not receipt (§0.3).\n")
  invisible(dispo)
}


# -- the live probe -----------------------------------------------------------

# WHICH SOURCES ANSWER "HAS CALIFORNIA AWARDED?" -- and only those. The four
# grant guides, the NOA and the budget narrative are static documents that
# cannot change the answer; the SRHRP page is a control. These three can:
#   funding   the four "(Closed)" headings -- a fifth pool, or one relabelled
#   calrht    the programme page, where a roster or an award link would appear
#   newsroom  HCAI's own announcement channel, which mentions RHTP zero times
CA_PROBE_KEYS <- c("funding", "calrht", "newsroom")

#' The change test: a digest of the REDUCED text, not of the file
#'
#' See `ca_probe()` for the two mechanisms this exists for. It reduces with
#' `ca_reduce_html()` -- the same function the assertions read -- so the probe
#' and the tripwires read the same bytes and cannot drift apart.
ca_content_digest <- function(body) {
  digest::digest(ca_reduce_html(body), algo = "sha256", serialize = FALSE)
}

#' LIVE: has California awarded yet?
#'
#' Missouri's `--probe` shape (session 29), Alaska's before it: fetch, compare,
#' report, ARCHIVE NOTHING. The tripwires run against the LIVE bytes rather
#' than the archive -- session 25's Indiana lesson as code, because
#' `--validate` reads the committed copy and can only answer "had California
#' awarded on the day the archive was taken?".
#'
#' IT COMPARES A CONTENT DIGEST, AND THE FILE DIGEST'S FAILURE IS MEASURED
#' RATHER THAN ASSUMED -- IN BOTH DIRECTIONS, WHICH IS THE POINT. Two fetches
#' of each probed page SECONDS APART are byte-identical, so hcai.ca.gov carries
#' no per-request nonce; an early version of this file concluded from exactly
#' that measurement that a file digest would do, and the first live probe
#' reported two of three pages CHANGED half an hour later with nothing changed.
#' Two mechanisms, neither one this project had met:
#'
#'   A CACHE VARIANT. The CalRHT page is served with or without a ~15 KB
#'   ElasticPress autosuggest asset block -- 142,605 or 157,732 bytes.
#'
#'   RANDOMISED EMAIL OBFUSCATION. The newsroom re-rolls WordPress
#'   `antispambot()` entities on every render: same length, different bytes,
#'   identical rendered text. A byte-count check would pass it.
#'
#' `ca_reduce_html()` absorbs both -- the reduced text is IDENTICAL across the
#' archived and live copies of both pages, 11,162 characters either way -- and
#' it is the same reduction the assertions read, so the probe and the tripwires
#' cannot drift apart (Missouri's rule, session 29).
#'
#' TWO FETCHES SECONDS APART IS NOT A STABILITY TEST. That is the transferable
#' lesson, and it is why the archived bytes are kept exactly as served: the
#' variant we hold is one of two legitimate responses, not the canonical one.
ca_probe <- function(keys = CA_PROBE_KEYS) {
  message("[CA] LIVE probe, ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"))
  changed <- character(0)
  bodies  <- list()
  for (i in seq_along(keys)) {
    key <- keys[[i]]
    if (i > 1L) Sys.sleep(CA_HOST_THROTTLE_S)
    served <- ca_get(ca_source(key, "url"), paste0("probe:", key))
    bodies[[key]] <- served
    live <- ca_content_digest(served)
    have <- ca_content_digest(readBin(ca_path(key), "raw",
                                      file.size(ca_path(key))))
    same <- identical(live, have)
    message(sprintf("  %-10s %s  %s", key, if (same) "UNCHANGED" else "CHANGED  ",
                    substr(live, 1, 16)))
    if (!same) changed <- c(changed, key)
  }

  txt <- lapply(bodies, ca_reduce_html)
  ca_assert_no_award_roster(funding = txt$funding)
  ca_assert_programme_provenance(calrht = txt$calrht)
  ca_assert_newsroom_control(news = txt$newsroom)
  message("[CA] the award tripwires pass against the LIVE bytes: California ",
          "has not published a recipient-level RHTP award roster.")
  if (length(changed)) {
    message("[CA] CHANGED, read them: ", paste(changed, collapse = ", "))
  }
  invisible(list(changed = changed))
}


# -- CLI ----------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args  <- commandArgs(trailingOnly = TRUE)
  force <- "--force" %in% args
  if ("--probe" %in% args)    ca_probe()
  if ("--fetch" %in% args)    ca_fetch(force = force)
  if ("--validate" %in% args) {
    rhtp_ca_assert(strict_footer = "--strict" %in% args)
    message("[CA] all assertions pass.")
  }
  if ("--build" %in% args)    rhtp_ca_build()
  if ("--report" %in% args)   rhtp_ca_report()
  if (!length(intersect(args, c("--probe", "--fetch", "--validate", "--build",
                                "--report")))) {
    message("usage: Rscript R/03ab_ca_year1_probe.R ",
            "[--probe] [--fetch [--force]] [--validate] [--build] [--report]")
  }
}
