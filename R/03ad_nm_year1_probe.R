#!/usr/bin/env Rscript
# 03ad_nm_year1_probe.R -------------------------------------------------------
#
# NEW MEXICO -- RHTP Year 1. A NEGATIVE, and the first candidate set in this
# project to carry THREE recorded false-positive shapes at once. New Mexico led
# the RCJ_ONLY queue jointly with Connecticut at 7 Tier 3 candidates, and not
# one is an RHTP subaward: all seven are recipients of a NEW MEXICO STATE FUND,
# taken from a PAST award roster, filed under the title of a FUTURE funding
# opportunity, and priced at $1 each.
#
# WHAT NEW MEXICO HAS PUBLISHED.
#
#   The Health Care Authority (HCA) runs RHTP and has opened SIX procurements.
#   Every one of them is pre-award, and HCA's own page says so in its own
#   words: the Administrative Services Organization RFP, the Center for Rural
#   Health Sustainability & Innovation, Healthy Horizons and the Rural Health
#   Innovation Fund all read "Currently under evaluation"; Rooted in New Mexico
#   reads "Submissions due: September 4, 2026 at 5PM MDT" -- TWO DAYS AFTER
#   THIS FILE RAN; and the Rural Health Data Hub reads "Submissions due: TBD"
#   with its RFP marked "Coming Soon". NOT ONE NAMED RECIPIENT ANYWHERE.
#
#   The two largest pools are dated by their own announcements: Healthy
#   Horizons is $76.2 million with applications due 2026-07-02, and the Rural
#   Health Innovation Fund is $47 million with proposals due 2026-07-27. Both
#   deadlines have passed and neither has a roster.
#
# §6.2 WITH THE FOOTER DEMOTED (session 27's audit, session 28's switch). HCA's
# footer is the WEAK form -- "This PROJECT is supported by ... a financial
# assistance award totaling $211,484,740.89" -- so it corroborates the AMOUNT,
# where it matches the §7.1 anchor ($211,484,741) to the cent, and two
# programme-scoped sentences carry the provenance: "Authorized under H.R. 1,
# Public Law 119-21, the RHT Program is a national investment" and "The Rural
# Health Innovation Fund IS PART OF New Mexico's Rural Health Transformation
# Program". `strict = FALSE` is the same switch Kansas, New Hampshire,
# Wisconsin, California and Connecticut already carry.
#
# §0.1 -- THREE RECORDED DEFECTS IN ONE CANDIDATE SET, AND THE THIRD IS THE ONE
# THAT MAKES THE OTHER TWO INVISIBLE.
#
#   1. THE WRONG PROGRAMME (Texas's defect, California's). All seven come from
#      the RURAL HEALTH CARE DELIVERY FUND (RHCDF), which is NEW MEXICO STATE
#      MONEY. The Governor's own release says it in one sentence: "41 rural
#      health care providers and facilities will receive a combined $50
#      million IN STATE FUNDING from the Rural Health Care Delivery Fund". The
#      fund was "originally established in 2023" and "received an additional
#      $50 million during the OCTOBER 2025 SPECIAL SESSION at the governor's
#      request" -- a state appropriation made BEFORE the 2025-12-29 CMS Notice
#      of Award. HCA's own RFA webinar deck calls it "a $50 million STATE
#      investment", and contains RHTP, "Rural Health Transformation", "CMS"
#      and "federal" ZERO TIMES EACH.
#
#      AND HCA'S OWN SITE ARCHITECTURE SEPARATES THEM. The RHCDF lives under
#      the Primary Care Council; the RHT Program is a sibling menu item. The
#      RHCDF page mentions "Rural Health Transformation" three times and ALL
#      THREE ARE THE NAVIGATION MENU -- its own prose never names the
#      programme, and it carries NO CMS FOOTER AT ALL. Its one mention of CMS
#      is New Mexico's Turquoise Care 1115 Medicaid waiver, "approved by the
#      Centers for Medicare & Medicaid Services on July 25, 2024" -- seventeen
#      months before the RHTP Notice of Award.
#
#   2. THE TITLE FROM THE WRONG PART OF THE PAGE (Nebraska's defect, session
#      23). Every one of the seven is filed under "NM - 2026 - RHCDF Announces
#      Stabilization Fund: $50 Million Rural Health Funding Opportunity for
#      FY27-29" -- a FUTURE opportunity whose applications opened 2026-03-16.
#      But the seven NAMES are not applicants to it. They are FY26-27 funding
#      RECIPIENTS, a PAST award roster printed further down the same page.
#      RCJ took its title from one section and its rows from another.
#
#   3. THE $1 PLACEHOLDER (Missouri's defect, session 28; Maine's, session
#      33). Every one of the seven carries an amount of $1, and New Mexico's
#      whole `rcj_federal_amount_sum` in the survey is therefore $7. That is
#      the defect no amount check can see -- and here it is what HIDES the
#      other two, because a row priced at $1 looks like missing data rather
#      than like the wrong programme.
#
# TWO OF THE SEVEN ARE NAMED HOSPITALS -- Alta Vista Regional Hospital and
# Cibola General Hospital -- so the shape is California's SRHRP again: real,
# executed, named, recipient-level state awards to rural hospitals, published
# by THE SAME AGENCY that administers RHTP. What keeps the dollar cost at $0
# here rather than California's $5,475,000 is only that RCJ priced them at $1.
# A session that "repaired" those amounts from the state page would publish
# state Medicaid stabilization money as New Mexico's RHTP hospital dollars.
#
# AND RCJ'S CAPTURE IS PARTIAL, WHICH IS ITS OWN TELL. The FY26-27 roster's
# first eight names in document order are Cañoncito, Cibola General, Duke City,
# First Nations, GALLUP COMMUNITY HEALTH, Las Cumbres, New Mexico Premier
# Health and Alta Vista. RCJ carries seven of those eight and DROPS Gallup --
# Texas's 32-of-33 (session 19) and Kansas's Greeley County (session 20) a
# third time.
#
# THE POSITIVE CONTROL, AND IT IS THE STRONGEST ARGUMENT IN THE FILE.
# HCA demonstrably publishes award announcements in a recognisable form, with
# named organisations, on the same news feed: "New Mexico awards $50 million to
# 41 rural healthcare organizations", "New Mexico awards $24.5 million under
# behavioral health reform law". So "New Mexico has published no RHTP roster"
# is a statement about the programme and not about our reading.
#
# AND THE POSITIVE CONTROL AND THE §0.1 NEGATIVE ARE ONE CLICK APART ON ONE
# FEED, WHICH IS THE TRANSFERABLE WARNING. "New Mexico awards $50 million to 41
# rural healthcare organizations" (2026-08-04, STATE money, AWARDED, NAMED)
# sits four items from "NM opens $47 million fund for rural health projects"
# (2026-07-07, RHTP, OPEN, UNNAMED). A hunt that scans a state news index for
# "awards" + "rural" + a large figure takes the state one every time.
#
# WHERE NEW MEXICO'S HOSPITAL MONEY WILL BE, AND WHY IT IS §0.3 EITHER WAY.
# Healthy Horizons is $76.2 million and HCA "will select six organizations to
# manage hub regions"; each "must use at least 90% of its award to support
# local projects" and hubs "are not expected to provide all services directly.
# Instead, they will coordinate local efforts and direct funding to providers,
# Tribal health programs, community organizations, public health groups and
# other partners". That is Missouri's ToRCH hub shape, and its eligible class
# is providers AMONG OTHERS -- New Hampshire's FHC answer
# (PASS_THROUGH_UNRESOLVED + Unclear, in NEITHER bucket), not Illinois's ICAHN
# answer.
#
# THE HOST'S DIGEST MECHANISM IS THE SIXTH THIS PROJECT HAS MET. `hca.nm.gov`
# runs the WordPress Complianz cookie-consent plugin, which writes a
# `privacy-statement-children` URL into a JSON config inside a script body --
# and the URL is drawn from the site's own posts AT RANDOM on each render.
# Twenty minutes apart it served "/snapchanges/" and a 2021 suicide-prevention
# press release, changing the page from 199,369 to 199,464 bytes. It is
# California's antispambot() finding one plugin over, with the difference that
# CALIFORNIA'S RE-ROLL WAS CONSTANT-LENGTH AND NEW MEXICO'S IS NOT: a
# byte-count check passes California's and fails New Mexico's, and neither is
# caught by a back-to-back pair. THREE FETCHES SECONDS APART HERE WERE
# BYTE-IDENTICAL while the copy taken twenty minutes earlier was not, which is
# California's lesson confirmed a third time by a third mechanism.
# `ct_reduce_html`'s counterpart here strips script bodies, so the reduced text
# is IDENTICAL across all four copies at 6,978 characters. robots.txt is 200.
#
# CLI:
#   --fetch [--force]  archive the 9 sources + SHA-256 manifest
#   --validate         every assertion, offline
#   --build            write the two status/disposition CSVs (NO award file)
#   --probe            LIVE: has New Mexico awarded yet?
#   --report           the negative, and the state roster it must never absorb
#
# Sessions: 35.

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(stringr)
  library(purrr)
})

source(here::here("R", "utils_config.R"))

NM_EVIDENCE_DIR <- here::here("data", "evidence", "NM")
NM_STATUS_CSV   <- "data/reference/nm_year1_status.csv"
NM_DISPO_CSV    <- "data/reference/nm_rcj_candidate_disposition.csv"
NM_AWARDS_CSV   <- "data/reference/nm_year1_awardees.csv"   # MUST NOT EXIST
NM_HOST_THROTTLE_S <- 3

# www.hca.nm.gov answers the project's honest agent with HTTP 200 on every path
# used here, and robots.txt is 200, so §3's michigan.gov exception is not
# reached and must not be.
NM_USER_AGENT <- paste(
  "AHA-RHTP-Tracker/0.1 (+https://www.aha.org;",
  "contact: AHA Data and Policy; R httr2)"
)

NM_SOURCES <- tibble::tribble(
  ~key, ~file, ~url,

  "programme",
  "2026-09-02_nm_hca_rht_programme.html",
  "https://www.hca.nm.gov/rural-health-transformation-program/",

  "rhcdf",
  "2026-09-02_nm_hca_rhcdf_BOTH_CONTROLS.html",
  "https://www.hca.nm.gov/primary-care-council/rural-health-care-delivery-fund/",

  "rhcdf_deck",
  "2026-09-02_nm_hca_rhcdf_rfa_webinar_STATE_INVESTMENT.pdf",
  "https://www.hca.nm.gov/wp-content/uploads/RHCDF-FY27-29-RFA-and-Application-Webinar.pdf",

  "award50",
  "2026-08-04_nm_governor_rhcdf_50m_41_orgs_NEGATIVE_CONTROL.html",
  paste0("https://www.hca.nm.gov/2026/08/04/",
         "new-mexico-awards-50-million-to-41-rural-healthcare-organizations/"),

  "fund47",
  "2026-07-07_nm_hca_rural_health_innovation_fund_47m.html",
  paste0("https://www.hca.nm.gov/2026/07/07/",
         "nm-opens-47-million-fund-for-rural-health-projects/"),

  "horizons",
  "2026-06-03_nm_hca_healthy_horizons_76m.html",
  paste0("https://www.hca.nm.gov/2026/06/03/",
         "new-mexico-announces-76-2-million-investment-in-rural-health-care/"),

  "news",
  "2026-09-02_nm_hca_news_index_CONTROL.html",
  "https://www.hca.nm.gov/news/",

  "advisory",
  "2026-08-19_nm_hca_stakeholder_advisory_committee.html",
  paste0("https://www.hca.nm.gov/2026/08/19/",
         "state-opens-applications-for-rural-health-advisory-committee/"),

  "vendors",
  "2026-04-27_nm_hca_seeks_vendors_aso.html",
  paste0("https://www.hca.nm.gov/2026/04/27/",
         "new-mexico-seeks-vendors-to-support-rural-and-",
         "behavioral-health-program-administration/")
)

# Every figure New Mexico states, in its own words. These are the state's
# numbers, not ours.
NM_STATED <- list(
  footer_amount  = "$211,484,740.89",
  horizons_pool  = "$76.2 million",
  innovation_pool = "$47 million",
  rhcdf_cycle    = "$50 million",
  rhcdf_prior    = "$20 million",
  horizons_hubs  = 6L,
  horizons_due   = "Applications are due July 2, 2026",
  innovation_due = "Proposals are due by 5 p.m. MDT on July 27, 2026",
  rinm_due       = "Submissions due: September 4, 2026 at 5PM MDT"
)

NM_ARCHIVE_DATE <- as.Date("2026-09-02")

NM_CREDENTIAL_SHAPES <- c(
  mapbox_token   = "[ps]k\\.ey[A-Za-z0-9_-]{10,}",
  google_api_key = "AIza[A-Za-z0-9_-]{30,}",
  bearer_token   = "(?i)bearer\\s+[A-Za-z0-9._-]{25,}",
  aws_key        = "AKIA[A-Z0-9]{12,}"
)


# -- fetch --------------------------------------------------------------------

nm_path <- function(key) {
  row <- NM_SOURCES[NM_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[NM] unknown source key: ", key, call. = FALSE)
  file.path(NM_EVIDENCE_DIR, row$file)
}

nm_source <- function(key, field) {
  row <- NM_SOURCES[NM_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[NM] unknown source key: ", key, call. = FALSE)
  row[[field]]
}

nm_assert_credential_free <- function(body, label) {
  chunk <- body[seq_len(min(length(body), 4e6))]
  txt   <- rawToChar(chunk[chunk != as.raw(0)])
  Encoding(txt) <- "latin1"
  for (nm in names(NM_CREDENTIAL_SHAPES)) {
    if (stringr::str_detect(txt, NM_CREDENTIAL_SHAPES[[nm]])) {
      stop("[NM] refusing to archive ", label, ": it carries what looks like ",
           "a ", nm, ".", call. = FALSE)
    }
  }
  invisible(TRUE)
}

nm_get <- function(url, label) {
  message("[NM] fetching ", url)
  resp <- httr::GET(url, httr::user_agent(NM_USER_AGENT),
                    httr::config(followlocation = TRUE), httr::timeout(240))
  if (httr::status_code(resp) != 200L) {
    stop("[NM] HTTP ", httr::status_code(resp), " for ", url, call. = FALSE)
  }
  served <- httr::content(resp, as = "raw")
  nm_assert_credential_free(served, label)
  served
}

nm_fetch <- function(force = FALSE) {
  dir.create(NM_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  entries <- purrr::map_dfr(seq_len(nrow(NM_SOURCES)), function(i) {
    src  <- NM_SOURCES[i, ]
    dest <- file.path(NM_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[NM] cached, not re-fetched: ", src$file)
    } else {
      if (i > 1L) Sys.sleep(NM_HOST_THROTTLE_S)
      writeBin(nm_get(src$url, src$file), dest)
    }
    tibble::tibble(file = src$file, url = src$url, bytes = file.size(dest),
                   sha256 = digest::digest(file = dest, algo = "sha256"))
  })
  nm_write_manifest(entries)
  invisible(entries)
}

nm_write_manifest <- function(entries) {
  path <- file.path(NM_EVIDENCE_DIR, "MANIFEST.txt")
  writeLines(c(
    "New Mexico -- Rural Health Transformation Program, Year 1.",
    "Archived by R/03ad_nm_year1_probe.R --fetch",
    paste0("User-agent: ", NM_USER_AGENT),
    "",
    "Every file is the body the server sent, BYTE FOR BYTE, written with",
    "writeBin(), so re-hashing a file on disk reproduces its digest below.",
    "The credential guard runs on every fetch and finds nothing, so there is",
    "no reduction to explain.",
    "",
    "NEW MEXICO HAS PUBLISHED NO RECIPIENT-LEVEL RHTP AWARD LIST. HCA has",
    "opened SIX RHT procurements and every one is pre-award in HCA's own",
    "words: four read 'Currently under evaluation', Rooted in New Mexico",
    "reads 'Submissions due: September 4, 2026' (TWO DAYS AFTER this archive",
    "was taken) and the Rural Health Data Hub reads 'Submissions due: TBD'.",
    "The two largest pools -- Healthy Horizons $76.2M and the Rural Health",
    "Innovation Fund $47M -- closed to applications on 2026-07-02 and",
    "2026-07-27 respectively and neither has a roster.",
    "",
    "ONE FILE IS BOTH CONTROLS AT ONCE, AND IT IS NAMED SO.",
    "  *_BOTH_CONTROLS.html is HCA's Rural Health Care Delivery Fund page.",
    "  POSITIVE: HCA publishes recipient-level rosters in a recognisable form",
    "    -- 'FY26-27 - Total Funding Recipients: 30', named by region. So",
    "    'the RHT Program has published no roster' is a statement about the",
    "    programme, not about our reading.",
    "  NEGATIVE (§0.1): the RHCDF is NEW MEXICO STATE MONEY, and ALL SEVEN of",
    "    RCJ's New Mexico Tier 3 candidates come from this page. Its own prose",
    "    NEVER names RHTP -- the three occurrences of 'Rural Health",
    "    Transformation' on it are all the NAVIGATION MENU -- and it carries",
    "    NO CMS FOOTER AT ALL. Its one mention of CMS is New Mexico's",
    "    Turquoise Care 1115 Medicaid waiver, approved 2024-07-25.",
    "",
    "  *_NEGATIVE_CONTROL.html is the Governor's 2026-08-04 release, which",
    "    says the funding source in one sentence: '41 rural health care",
    "    providers and facilities will receive a combined $50 million IN",
    "    STATE FUNDING from the Rural Health Care Delivery Fund', a fund",
    "    'originally established in 2023' that 'received an additional $50",
    "    million during the OCTOBER 2025 SPECIAL SESSION' -- a state",
    "    appropriation predating the 2025-12-29 CMS Notice of Award. It names",
    "    41 organisations including SIX HOSPITALS.",
    "  *_STATE_INVESTMENT.pdf is HCA's own RHCDF webinar deck, which calls it",
    "    'a $50 million STATE investment' and contains 'RHTP', 'Rural Health",
    "    Transformation', 'CMS' and 'federal' ZERO TIMES EACH.",
    "  *_CONTROL.html is HCA's news index -- and it carries BOTH the positive",
    "    control and the §0.1 negative ONE CLICK APART: 'New Mexico awards",
    "    $50 million to 41 rural healthcare organizations' (STATE, awarded,",
    "    named) four items from 'NM opens $47 million fund for rural health",
    "    projects' (RHTP, open, unnamed). A hunt scanning a news index for",
    "    'awards' + 'rural' + a large figure takes the state one every time.",
    "",
    "THESE FILE DIGESTS ARE NOT A CHANGE TEST, AND THE MECHANISM IS THE SIXTH",
    "THIS PROJECT HAS MET. hca.nm.gov runs the WordPress Complianz",
    "cookie-consent plugin, which writes a 'privacy-statement-children' URL",
    "into a JSON config inside a script body -- drawn from the site's own",
    "posts AT RANDOM on each render. Twenty minutes apart it served",
    "'/snapchanges/' and a 2021 press release, moving the page from 199,369",
    "to 199,464 bytes. It is California's antispambot() finding one plugin",
    "over, with the difference that CALIFORNIA'S RE-ROLL WAS CONSTANT-LENGTH",
    "AND THIS ONE IS NOT -- so a byte-count check passes California's and",
    "fails this. THREE FETCHES SECONDS APART WERE BYTE-IDENTICAL while the",
    "copy taken twenty minutes earlier was not: California's lesson confirmed",
    "a third time, by a third mechanism. --probe compares a CONTENT digest",
    "via nm_reduce_html(); the reduced text is IDENTICAL across all four",
    "copies at 6,978 characters. robots.txt is 200.",
    "",
    "file  bytes  sha256",
    paste(entries$file, entries$bytes, entries$sha256, sep = "  ")
  ), path)
  invisible(path)
}


# -- readers ------------------------------------------------------------------

#' The one HTML reduction, so the probe and the assertions read the same bytes
#'
#' Missouri's rule (session 29). Stripping script BODIES is what absorbs
#' Complianz's randomly-drawn privacy-statement URL -- see `nm_probe()`.
nm_reduce_html <- function(raw) {
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "UTF-8"
  txt <- stringr::str_remove_all(txt, "(?s)<(script|style)[^>]*>.*?</\\1>")
  txt <- stringr::str_replace_all(txt, "<[^>]+>", " ")
  txt <- rhtp_nm_unescape(txt)
  txt <- stringr::str_remove_all(txt, "[​‌‍﻿]")
  stringr::str_squish(txt)
}

rhtp_nm_unescape <- function(x) {
  x <- stringr::str_replace_all(x, "&nbsp;", " ")
  x <- stringr::str_replace_all(x, "&amp;", "&")
  x <- stringr::str_replace_all(x, "&#39;|&rsquo;|&#8217;", "'")
  x <- stringr::str_replace_all(x, "&quot;|&ldquo;|&rdquo;", '"')
  x <- stringr::str_replace_all(x, "&lt;", "<")
  x <- stringr::str_replace_all(x, "&gt;", ">")
  x <- stringr::str_replace_all(x, "&#8211;|&ndash;", "-")
  x <- stringr::str_replace_all(x, "[‘’‛]", "'")
  x <- stringr::str_replace_all(x, "[“”‟]", '"')
  x <- stringr::str_replace_all(x, "[‐‑‒–—]", "-")
  x
}

nm_html_text <- function(key, body = NULL) {
  if (is.null(body)) {
    p <- nm_path(key)
    body <- readBin(p, "raw", file.size(p))
  }
  nm_reduce_html(body)
}

nm_pdf_text <- function(key, body = NULL) {
  if (!exists("rhtp_pdf_text")) source(here::here("R", "utils_pdf_text.R"))
  path <- if (is.null(body)) {
    nm_path(key)
  } else {
    tmp <- tempfile(fileext = ".pdf"); writeBin(body, tmp); tmp
  }
  stringr::str_squish(paste(rhtp_pdf_text(path), collapse = " "))
}

#' The §7.1 allotment anchor for New Mexico, read rather than typed
nm_allotment_anchor <- function() {
  path <- here::here("data", "reference", "cms_fy2026_allotments.csv")
  a <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  v <- a$fy2026_allotment[a$state == "NM"]
  if (length(v) != 1L) {
    stop("[NM] the §7.1 anchor does not carry exactly one NM row.",
         call. = FALSE)
  }
  v
}

#' The §6.2 NOA date anchor for New Mexico, read rather than typed
nm_noa_anchor <- function() {
  path <- here::here("data", "reference", "cms_state_noa_dates.csv")
  if (!file.exists(path)) return(as.Date("2025-12-29"))
  d <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  v <- d$noa_date[d$state == "NM"]
  if (length(v) != 1L) return(as.Date("2025-12-29"))
  as.Date(v)
}

#' The FY26-27 RHCDF roster -- the state award list RCJ's seven names come from
#'
#' Read as a LIST rather than asserted as a count, because the point is which
#' names are on it: seven of its first eight, in document order, are RCJ's
#' seven New Mexico Tier 3 candidates, and the one it drops is Gallup Community
#' Health.
nm_rhcdf_fy2627_names <- function(body = NULL) {
  t <- if (is.null(body)) nm_html_text("rhcdf") else body
  seg <- stringr::str_extract(
    t, "FY26-27 - Total Funding Recipients: 30.*?FY24-26 Funded Organizations")
  if (is.na(seg)) return(character(0))
  # each entry reads "<Name>: <counties>"; take the name half
  parts <- stringr::str_extract_all(seg, "[A-Z][^:]{3,80}:")[[1]]
  stringr::str_squish(stringr::str_remove(parts, ":$"))
}


# -- assertions ---------------------------------------------------------------

#' The provenance, carried by programme-scoped sentences and not by the footer
nm_assert_programme_provenance <- function(programme = NULL, fund47 = NULL) {
  t  <- if (is.null(programme)) nm_html_text("programme") else programme
  t2 <- if (is.null(fund47)) nm_html_text("fund47") else fund47
  if (!stringr::str_detect(t, stringr::fixed(
        "Authorized under H.R. 1, Public Law 119-21"))) {
    stop("[NM] HCA's RHT page no longer carries its programme-scoped ",
         "statutory sentence. The CMS footer alone is the WEAK form ",
         "(session 27) and does not replace it.", call. = FALSE)
  }
  if (!stringr::str_detect(t2, stringr::fixed(
        "is part of New Mexico's Rural Health Transformation Program"))) {
    stop("[NM] the Rural Health Innovation Fund release no longer states that ",
         "the fund is part of RHTP. That is the second, independent ",
         "programme-scoped sentence.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The footer corroborates the AMOUNT and is not the provenance
#'
#' Kansas's demotion (session 28) and the same `strict =` switch New Hampshire,
#' Wisconsin, California and Connecticut carry.
nm_assert_footer_corroborates <- function(strict = FALSE, programme = NULL) {
  t <- if (is.null(programme)) nm_html_text("programme") else programme
  want <- paste0("financial assistance award totaling ", NM_STATED$footer_amount)
  if (!stringr::str_detect(t, stringr::fixed(want))) {
    msg <- paste0("[NM] the CMS financial-assistance footer is not on HCA's ",
                  "RHT page in the expected form. It is the WEAK form ('This ",
                  "project is supported by') and corroborates the AMOUNT ",
                  "only; the provenance is carried by ",
                  "nm_assert_programme_provenance().")
    if (strict) stop(msg, call. = FALSE)
    message(msg); return(invisible(NA))
  }
  cents <- as.numeric(stringr::str_remove_all(NM_STATED$footer_amount, "[$,]"))
  if (round(cents) != nm_allotment_anchor()) {
    stop("[NM] the footer amount ", NM_STATED$footer_amount, " no longer ",
         "rounds to the §7.1 anchor ", nm_allotment_anchor(), ".",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' THE TRIPWIRE: New Mexico has named no RHTP recipient
#'
#' DESIGNED TO FAIL. HCA's RHT page is the one surface where a roster or an
#' award link would appear, and its six procurement blocks are the state's own
#' statement of where each stands. If it acquires award language, this file
#' must be REWRITTEN as an award extractor, not patched.
NM_AWARD_POSTED <- c(
  "has been awarded", "have been awarded", "awardees are", "selected for award",
  "notice of intent to award", "list of awardees", "award recipients",
  "funding recipients", "successful applicant", "selected organizations"
)

NM_PENDING_MARKERS <- c(
  "Currently under evaluation",
  "Administrative Services Organization (ASO) RFP",
  "Center for Rural Health Sustainability & Innovation",
  "Healthy Horizons",
  "Rural Health Innovation Fund",
  "Rooted in New Mexico",
  "Rural Health Data Hub"
)

nm_assert_no_award_roster <- function(programme = NULL) {
  t <- if (is.null(programme)) nm_html_text("programme") else programme
  hit <- NM_AWARD_POSTED[purrr::map_lgl(
    NM_AWARD_POSTED, ~ stringr::str_detect(t, stringr::regex(.x, ignore_case = TRUE)))]
  if (length(hit)) {
    stop("[NM] award language has appeared on HCA's RHT page: ",
         paste(hit, collapse = " | "),
         ". THAT IS THE SIGNAL, NOT A DEFECT. New Mexico may have published a ",
         "recipient-level roster: read it, and rewrite this file as an award ",
         "extractor rather than adjusting this constant.", call. = FALSE)
  }
  miss <- NM_PENDING_MARKERS[!purrr::map_lgl(
    NM_PENDING_MARKERS, ~ stringr::str_detect(t, stringr::fixed(.x)))]
  if (length(miss)) {
    stop("[NM] HCA's RHT page no longer carries: ",
         paste(miss, collapse = " | "),
         ". Those are the six procurements and the state's own word for their ",
         "stage; losing one means the page has moved on.", call. = FALSE)
  }
  invisible(TRUE)
}

#' Every RHTP deadline New Mexico has published, and what it means that they
#' have passed
nm_assert_pending_not_awarded <- function(programme = NULL, horizons = NULL,
                                          fund47 = NULL) {
  t  <- if (is.null(programme)) nm_html_text("programme") else programme
  th <- if (is.null(horizons)) nm_html_text("horizons") else horizons
  tf <- if (is.null(fund47)) nm_html_text("fund47") else fund47
  need <- list(programme = c(t, NM_STATED$rinm_due),
               horizons  = c(th, NM_STATED$horizons_due),
               fund47    = c(tf, NM_STATED$innovation_due))
  for (nm in names(need)) {
    if (!stringr::str_detect(need[[nm]][1], stringr::fixed(need[[nm]][2]))) {
      stop("[NM] the ", nm, " source no longer carries its own deadline (",
           need[[nm]][2], "). Those dates are what make New Mexico's negative ",
           "a dated one rather than an open-ended absence.", call. = FALSE)
    }
  }
  # Healthy Horizons is where the hospital money will be, and it is a HUB
  # model: Missouri's ToRCH shape, with an eligible class of providers AMONG
  # OTHERS (§0.3, New Hampshire's answer).
  hub <- c("will select six organizations to manage hub regions",
           "at least 90% of its award to support local projects")
  missing <- hub[!purrr::map_lgl(hub, ~ stringr::str_detect(th, stringr::fixed(.x)))]
  if (length(missing)) {
    stop("[NM] the Healthy Horizons release no longer describes the hub ",
         "model: ", paste(missing, collapse = " | "),
         ". That description is what makes it a PASS_THROUGH question rather ",
         "than a direct award when it lands.", call. = FALSE)
  }
  invisible(TRUE)
}

#' THE §0.1 NEGATIVE: the RHCDF is New Mexico STATE money, not RHTP
#'
#' Three independent statements, from three publishers, asserted together:
#' the Governor's release names the funding source, HCA's own webinar deck
#' calls it a state investment, and the RHCDF page carries no CMS footer and
#' never names the programme in its own prose.
nm_assert_rhcdf_is_not_rhtp <- function(award50 = NULL, deck = NULL,
                                        rhcdf = NULL) {
  ta <- if (is.null(award50)) nm_html_text("award50") else award50
  td <- if (is.null(deck)) nm_pdf_text("rhcdf_deck") else deck
  tr <- if (is.null(rhcdf)) nm_html_text("rhcdf") else rhcdf

  need <- c(
    paste("41 rural health care providers and facilities will receive a",
          "combined $50 million in state funding"),
    "Originally established in 2023",
    "additional $50 million during the October 2025 special session"
  )
  miss <- need[!purrr::map_lgl(need, ~ stringr::str_detect(ta, stringr::fixed(.x)))]
  if (length(miss)) {
    stop("[NM] the Governor's RHCDF release no longer states the fund's ",
         "source: ", paste(miss, collapse = " | "),
         ". That sentence is what disqualifies all seven RCJ candidates.",
         call. = FALSE)
  }
  if (!stringr::str_detect(td, stringr::regex("\\$50 million\\s*state\\s*investment|state\\s*investment"))) {
    stop("[NM] HCA's own RHCDF webinar deck no longer calls the cycle a ",
         "state investment.", call. = FALSE)
  }
  # And the deck must stay silent about the federal programme -- the strongest
  # form of the negative, because it is the document RCJ sourced the rows from.
  for (p in c("RHTP", "Rural Health Transformation", "CMS", "federal")) {
    if (stringr::str_detect(td, stringr::fixed(p))) {
      stop("[NM] the RHCDF webinar deck now mentions '", p, "'. It contained ",
           "RHTP, 'Rural Health Transformation', 'CMS' and 'federal' ZERO ",
           "times, which is why the seven candidates are disposed of as state ",
           "money. Read it before building.", call. = FALSE)
    }
  }
  # The RHCDF page's own prose never names the programme: the three matches are
  # the site navigation, so the count is asserted rather than the absence.
  n <- stringr::str_count(tr, stringr::fixed("Rural Health Transformation"))
  if (n != 3L) {
    stop("[NM] the RHCDF page now mentions 'Rural Health Transformation' ", n,
         " times rather than 3. All three were the NAVIGATION MENU; a fourth ",
         "would be in its prose, which would change the disposition.",
         call. = FALSE)
  }
  if (stringr::str_detect(tr, stringr::fixed("financial assistance award totaling"))) {
    stop("[NM] the RHCDF page now carries a CMS financial-assistance footer. ",
         "It carried none, which is half of why it is not RHTP.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' THE POSITIVE CONTROL: HCA publishes named rosters in a recognisable form
#'
#' Without it, "no RHTP roster" is indistinguishable from "we are reading the
#' wrong channel". It is a tripwire in both directions.
nm_assert_roster_control <- function(rhcdf = NULL, news = NULL) {
  tr <- if (is.null(rhcdf)) nm_html_text("rhcdf") else rhcdf
  tn <- if (is.null(news)) nm_html_text("news") else news
  need <- c("FY26-27 - Total Funding Recipients: 30",
            "$20 million funded to 30 rural health care organizations")
  miss <- need[!purrr::map_lgl(need, ~ stringr::str_detect(tr, stringr::fixed(.x)))]
  if (length(miss)) {
    stop("[NM] the RHCDF page no longer demonstrates that HCA publishes ",
         "recipient-level rosters: ", paste(miss, collapse = " | "),
         call. = FALSE)
  }
  # AND THE TWO SIT ONE CLICK APART ON ONE FEED. That is the transferable
  # warning, so both headlines are asserted on the same index.
  heads <- c("New Mexico awards $50 million to 41 rural healthcare organizations",
             "NM opens $47 million fund for rural health projects")
  miss2 <- heads[!purrr::map_lgl(heads, ~ stringr::str_detect(tn, stringr::fixed(.x)))]
  if (length(miss2)) {
    stop("[NM] HCA's news index no longer carries both the state award ",
         "announcement and the RHTP solicitation: ",
         paste(miss2, collapse = " | "),
         ". They sit four items apart and read almost identically, which is ",
         "the reason this control exists.", call. = FALSE)
  }
  invisible(TRUE)
}

#' RCJ's seven names are on the RHCDF's PAST roster, and one is missing
#'
#' The partial capture is its own tell -- Texas's 32-of-33 and Kansas's
#' Greeley County a third time -- so it is asserted rather than noted.
nm_assert_candidates_are_rhcdf_recipients <- function(rhcdf = NULL,
                                                      cands = NULL) {
  tr <- if (is.null(rhcdf)) nm_html_text("rhcdf") else rhcdf
  if (is.null(cands)) cands <- nm_rcj_candidates()
  # Every RCJ awardee name must appear on the RHCDF page. Matched on the
  # distinctive head of the name, because HCA and RCJ punctuate differently
  # (RCJ writes "Cañoncito Band of Navajo Health Center, Inc.").
  heads <- stringr::str_squish(stringr::str_remove(
    cands$awardee_name_clean, ",.*$"))
  miss <- heads[!purrr::map_lgl(heads, ~ stringr::str_detect(tr, stringr::fixed(.x)))]
  if (length(miss)) {
    stop("[NM] ", length(miss), " RCJ New Mexico candidate(s) are NOT on the ",
         "RHCDF page: ", paste(miss, collapse = " | "),
         ". This file's whole disposition is that all seven are RHCDF ",
         "recipients. Read the new ones before building.", call. = FALSE)
  }
  if (!stringr::str_detect(tr, stringr::fixed("Gallup Community Health"))) {
    stop("[NM] Gallup Community Health is no longer on the RHCDF roster. It ",
         "is the FY26-27 name RCJ drops -- seven of the roster's first eight ",
         "in document order -- and that partial capture is its own tell.",
         call. = FALSE)
  }
  if (any(stringr::str_detect(heads, stringr::fixed("Gallup")))) {
    stop("[NM] RCJ now carries Gallup Community Health. The partial capture ",
         "has changed; re-read the candidate set.", call. = FALSE)
  }
  invisible(TRUE)
}

#' EVERY CANDIDATE IS PRICED AT $1 -- Missouri's placeholder, and here it is
#' what HIDES the other two defects
nm_assert_placeholder_amounts <- function(cands = NULL) {
  if (is.null(cands)) cands <- nm_rcj_candidates()
  amt <- cands$amount_announced
  if (!all(!is.na(amt) & amt == 1)) {
    stop("[NM] not every New Mexico candidate is priced at $1 any more (",
         paste(unique(amt), collapse = ", "),
         "). The $1 placeholder is what makes these rows look like missing ",
         "data rather than like the wrong programme; if RCJ has repaired the ",
         "amounts, the dollar exposure of this negative changes and the ",
         "disposition must say so.", call. = FALSE)
  }
  invisible(TRUE)
}

nm_assert_no_award_file <- function() {
  if (file.exists(here::here(NM_AWARDS_CSV))) {
    stop("[NM] ", NM_AWARDS_CSV, " exists. New Mexico has published no ",
         "recipient-level RHTP award list; if that has changed, write the ",
         "extractor deliberately and delete this assertion in the same ",
         "commit.", call. = FALSE)
  }
  path <- here::here(NM_STATUS_CSV)
  if (file.exists(path)) {
    cols <- names(readr::read_csv(path, n_max = 0, show_col_types = FALSE))
    bad  <- intersect(cols, c("amount", "round_amount", "amount_announced"))
    if (length(bad)) {
      stop("[NM] nm_year1_status.csv carries an amount column (",
           paste(bad, collapse = ", "), "). It is a STATUS table: New Mexico ",
           "has named no RHTP recipient, so no sum over it could mean ",
           "anything.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

rhtp_nm_assert <- function(strict_footer = FALSE) {
  nm_assert_programme_provenance()
  nm_assert_footer_corroborates(strict = strict_footer)
  nm_assert_no_award_roster()
  nm_assert_pending_not_awarded()
  nm_assert_rhcdf_is_not_rhtp()
  nm_assert_roster_control()
  nm_assert_candidates_are_rhcdf_recipients()
  nm_assert_placeholder_amounts()
  nm_assert_no_award_file()
  invisible(TRUE)
}


# -- the status table ---------------------------------------------------------

#' What each New Mexico RHTP channel publishes
#'
#' DELIBERATELY NO `amount` COLUMN (Texas's device, and Wisconsin's, Maine's,
#' California's and Connecticut's after it). New Mexico has named no RHTP
#' recipient; the pool amounts live in `stated_pool` as the state's own words,
#' which cannot be summed by accident.
rhtp_nm_year1_status <- function() {
  tibble::tribble(
    ~channel, ~administrator, ~stated_pool, ~stage, ~eligible_class,
    ~publishes_roster, ~evidence,

    "Healthy Horizons -- THE POOL TO WATCH", "HCA",
    "$76.2 million; six regional hub organizations",
    "CLOSED_UNAWARDED",
    paste("PROVIDERS AMONG OTHERS. Hubs 'direct funding to providers, Tribal",
          "health programs, community organizations, public health groups and",
          "other partners'. New Hampshire's FHC class, NOT Illinois's ICAHN",
          "class, so §0.3 governs it either way."),
    "No",
    paste("HCA 'will select six organizations to manage hub regions'; each",
          "'must use at least 90% of its award to support local projects'.",
          "Applications were due 2026-07-02 and the RHT page still reads",
          "'Currently under evaluation'. MISSOURI'S ToRCH HUB SHAPE: when it",
          "lands it is a PASS_THROUGH question, not a direct award."),

    "Rural Health Innovation Fund", "HCA",
    "$47 million",
    "CLOSED_UNAWARDED",
    paste("'health care providers, Tribal entities, community-based",
          "organizations, local governments, academic institutions, regional",
          "partnerships, vendors and other organizations' -- hospitals are",
          "not even named as a class of their own."),
    "No",
    paste("'Proposals are due by 5 p.m. MDT on July 27, 2026'; the RHT page",
          "still reads 'Currently under evaluation'. Its release carries one",
          "of the two programme-scoped provenance sentences: the fund 'is",
          "part of New Mexico's Rural Health Transformation Program'."),

    "Administrative Services Organization (ASO) RFP", "HCA",
    "not stated", "CLOSED_UNAWARDED",
    "Administrative and operational support -- a vendor role.",
    "No",
    "'Currently under evaluation'.",

    "Center for Rural Health Sustainability & Innovation (CRHSI)", "HCA",
    "not stated", "CLOSED_UNAWARDED",
    "Administrative and operational support -- a vendor role.",
    "No",
    "'Currently under evaluation'.",

    "Rooted in New Mexico (RiNM) -- workforce", "HCA",
    "not stated", "OPEN",
    "Workforce programme coordination and contract administration.",
    "No",
    paste("'Submissions due: September 4, 2026 at 5PM MDT' -- TWO DAYS AFTER",
          "this archive was taken. The only RHT procurement still open."),

    "Rural Health Data Hub (RHDH)", "HCA",
    "not stated", "NOT_YET_SOLICITED",
    "Data project coordination -- a vendor role.",
    "No",
    "'Submissions due: TBD'; its RFP and application both read 'Coming Soon'.",

    "HCA news index -- THE POSITIVE CONTROL, AND THE §0.1 TRAP BESIDE IT",
    "HCA", "n/a", "NO_RHTP_ANNOUNCEMENT", "n/a", "No",
    paste("HCA demonstrably publishes award announcements with named",
          "organisations -- 'New Mexico awards $50 million to 41 rural",
          "healthcare organizations', 'New Mexico awards $24.5 million under",
          "behavioral health reform law'. So the RHT programme's silence is",
          "the programme's. AND THE TRAP IS FOUR ITEMS AWAY: that $50M award",
          "is STATE money, and it sits beside 'NM opens $47 million fund for",
          "rural health projects', which is RHTP and unawarded. A hunt",
          "scanning for 'awards' + 'rural' + a large figure takes the state",
          "one every time."),

    "Rural Health Care Delivery Fund (RHCDF) -- NOT RHTP", "HCA",
    paste("$50 million FY27-29 cycle; $20 million FY26-27 to 30 organisations;",
          "$80 million FY24-26 to 50"),
    "AWARDED_BUT_NOT_RHTP",
    paste("Rural NM Medicaid-enrolled providers in rural high-need HPSAs, and",
          "tribally operated facilities. A NAMED roster is published per",
          "cycle, with NO per-recipient amount."),
    "Yes -- FOR A DIFFERENT PROGRAMME",
    paste("BOTH CONTROLS AT ONCE. Positive: HCA publishes recipient-level",
          "rosters, named and regionally grouped, so CalRHT-style silence",
          "would be visible. Negative: this is NEW MEXICO STATE MONEY -- the",
          "Governor's release says '41 rural health care providers and",
          "facilities will receive a combined $50 million IN STATE FUNDING',",
          "a fund 'originally established in 2023' topped up 'during the",
          "October 2025 special session', and HCA's own webinar deck calls it",
          "'a $50 million STATE investment' while containing RHTP, 'Rural",
          "Health Transformation', 'CMS' and 'federal' ZERO TIMES. ALL SEVEN",
          "RCJ NEW MEXICO CANDIDATES COME FROM HERE, and its 2026-08-04 cycle",
          "names SIX HOSPITALS.")
  ) %>%
    dplyr::mutate(state = "NM", .before = 1)
}


# -- RCJ candidate disposition ------------------------------------------------

nm_rcj_candidates <- function() {
  rt <- readRDS(here::here("data", "interim", "stage2_record_table.rds"))
  rt %>% dplyr::filter(state == "NM", award_tier == "SUBAWARD")
}

NM_RHCDF_SOURCE_MARKER <- "RHCDF Announces Stabilization Fund"

#' Why each of RCJ's New Mexico Tier 3 candidates is not an RHTP subaward
#'
#' The counts are RE-DERIVED from the record table on every run, never typed,
#' and the disposition REFUSES a candidate it does not cover (California's
#' rule, session 34).
rhtp_nm_rcj_disposition <- function(cands = NULL) {
  if (is.null(cands)) cands <- nm_rcj_candidates()
  is_rhcdf <- stringr::str_detect(cands$source_doc_title,
                                  stringr::fixed(NM_RHCDF_SOURCE_MARKER))
  if (!all(is_rhcdf)) {
    stop("[NM] ", sum(!is_rhcdf), " New Mexico Tier 3 candidates are NOT from ",
         "the RHCDF stabilization-fund document. This file's whole ",
         "disposition is that all of them are. Read the new ones before ",
         "building: ",
         paste(unique(cands$source_doc_title[!is_rhcdf]), collapse = " | "),
         call. = FALSE)
  }
  amt  <- cands$amount_announced
  hosp <- stringr::str_detect(cands$awardee_name_clean,
                              stringr::regex("hospital", ignore_case = TRUE))

  tibble::tribble(
    ~group, ~rows, ~distinct_awardees, ~named_hospital_rows, ~rcj_amount_sum,
    ~disposition, ~why,

    paste("Rural Health Care Delivery Fund recipients -- NEW MEXICO STATE",
          "MEDICAID STABILIZATION MONEY"),
    sum(is_rhcdf), dplyr::n_distinct(cands$awardee_name_clean[is_rhcdf]),
    sum(hosp & is_rhcdf), sum(amt[is_rhcdf], na.rm = TRUE),
    "NOT_RHTP_STATE_PROGRAM",
    paste0(
      "ALL ", sum(is_rhcdf), " OF NEW MEXICO'S TIER 3 CANDIDATES, AND THREE ",
      "RECORDED DEFECTS AT ONCE. (1) THE WRONG PROGRAMME (Texas's, ",
      "California's): the Rural Health Care Delivery Fund is state money. ",
      "The Governor's own release says '41 rural health care providers and ",
      "facilities will receive a combined $50 million IN STATE FUNDING from ",
      "the Rural Health Care Delivery Fund', a fund 'originally established ",
      "in 2023' that 'received an additional $50 million during the OCTOBER ",
      "2025 SPECIAL SESSION' -- a state appropriation predating the ",
      "2025-12-29 Notice of Award -- and HCA's own webinar deck calls it 'a ",
      "$50 million STATE investment' while containing RHTP, 'Rural Health ",
      "Transformation', 'CMS' and 'federal' ZERO TIMES EACH. HCA's site ",
      "architecture agrees: the RHCDF sits under the Primary Care Council, ",
      "the RHT Program is a sibling menu item, and the RHCDF page's three ",
      "mentions of 'Rural Health Transformation' are ALL THE NAVIGATION ",
      "MENU. It carries no CMS footer at all; its one mention of CMS is New ",
      "Mexico's Turquoise Care 1115 Medicaid waiver, approved 2024-07-25. ",
      "(2) THE TITLE FROM THE WRONG PART OF THE PAGE (Nebraska's, session ",
      "23): every row is filed under 'RHCDF Announces Stabilization Fund: ",
      "$50 Million Rural Health Funding Opportunity for FY27-29', a FUTURE ",
      "opportunity, while the NAMES are FY26-27 funding RECIPIENTS printed ",
      "further down the same page -- a PAST award roster. And the capture is ",
      "partial in its own telling way: seven of the roster's first EIGHT ",
      "names in document order, DROPPING Gallup Community Health (Texas's ",
      "32-of-33, Kansas's Greeley County). (3) THE $1 PLACEHOLDER ",
      "(Missouri's, session 28; Maine's, session 33): every row is priced at ",
      "$1, so New Mexico's whole rcj_federal_amount_sum is $7 -- and HERE ",
      "THAT IS WHAT HIDES THE OTHER TWO, because a row priced at $1 reads as ",
      "missing data rather than as the wrong programme. ",
      sum(hosp & is_rhcdf), " OF THE ", sum(is_rhcdf), " ARE NAMED NEW ",
      "MEXICO HOSPITALS (Alta Vista Regional Hospital, Cibola General ",
      "Hospital), which is California's SRHRP shape again -- real, executed, ",
      "named state awards to rural hospitals from THE SAME AGENCY that ",
      "administers RHTP. What keeps the cost at $0 here rather than ",
      "California's $5,475,000 is only that RCJ priced them at $1; a session ",
      "that 'repaired' those amounts from the state page would publish state ",
      "Medicaid stabilization money as New Mexico's RHTP hospital dollars.")
  ) %>%
    dplyr::mutate(state = "NM", .before = 1)
}


# -- build / report -----------------------------------------------------------

rhtp_nm_build <- function() {
  rhtp_nm_assert()
  status <- rhtp_nm_year1_status()
  dispo  <- rhtp_nm_rcj_disposition()
  readr::write_csv(status, here::here(NM_STATUS_CSV))
  readr::write_csv(dispo,  here::here(NM_DISPO_CSV))
  nm_assert_no_award_file()
  message("[NM] wrote ", NM_STATUS_CSV, " (", nrow(status), " rows) and ",
          NM_DISPO_CSV, " (", nrow(dispo), " rows).")
  message("[NM] NO nm_year1_awardees.csv was written, and that is the finding.")
  invisible(list(status = status, disposition = dispo))
}

rhtp_nm_report <- function() {
  cands  <- nm_rcj_candidates()
  dispo  <- rhtp_nm_rcj_disposition(cands)
  status <- rhtp_nm_year1_status()
  allot  <- nm_allotment_anchor()

  cat("\nNEW MEXICO -- RHTP Year 1\n")
  cat(strrep("=", 78), "\n\n")
  cat(sprintf("  CMS FY2026 allotment           $%s\n",
              format(allot, big.mark = ",", scientific = FALSE)))
  cat("  RECIPIENT-LEVEL AWARD LIST     NONE PUBLISHED\n")
  cat("  NAMED HOSPITALS                0\n")
  cat("  HOSPITAL DOLLARS               $0\n\n")

  cat("  SIX RHT PROCUREMENTS, NOT ONE AWARDED, AND HCA SAYS SO ITSELF.\n")
  for (i in seq_len(nrow(status))) {
    cat(sprintf("    %-56s %-22s roster: %s\n",
                substr(status$channel[i], 1, 56),
                substr(status$stage[i], 1, 22),
                status$publishes_roster[i]))
  }

  cat(sprintf("\n  RCJ Tier 3 candidates          %d\n", nrow(cands)))
  for (i in seq_len(nrow(dispo))) {
    cat(sprintf("    %-52s %d rows  $%s\n",
                substr(dispo$group[i], 1, 52), dispo$rows[i],
                format(dispo$rcj_amount_sum[i], big.mark = ",",
                       scientific = FALSE)))
    cat(sprintf("      named hospitals among them: %d of %d\n",
                dispo$named_hospital_rows[i], dispo$rows[i]))
  }
  cat("  RHTP subawards among them      0\n\n")

  cat("  THREE RECORDED DEFECTS IN ONE CANDIDATE SET:\n")
  cat("    1. the wrong PROGRAMME  -- a state fund (Texas, California)\n")
  cat("    2. the wrong SECTION    -- a future opportunity's title on a past\n")
  cat("                               award roster's names (Nebraska)\n")
  cat("    3. the $1 PLACEHOLDER   -- which is what HIDES the other two\n")
  cat("                               (Missouri, Maine)\n\n")

  cat("  THE POOL TO WATCH IS HEALTHY HORIZONS, $76.2M and six regional hubs,\n")
  cat("  which 'direct funding to providers, Tribal health programs,\n")
  cat("  community organizations...' -- providers AMONG OTHERS, so §0.3\n")
  cat("  governs it and it is Missouri's ToRCH hub shape when it lands.\n")
  invisible(dispo)
}


# -- the live probe -----------------------------------------------------------

# WHICH SOURCES ANSWER "HAS NEW MEXICO AWARDED?" -- and only those.
#   programme  the six procurement blocks and their stage, where a roster would
#              appear
#   news       HCA's announcement channel, which is also the §0.1 trap
#   rhcdf      the state roster, watched because a NEW cycle appearing there is
#              the thing most likely to be mistaken for an RHTP award
NM_PROBE_KEYS <- c("programme", "news", "rhcdf")

#' The change test: a digest of the REDUCED text, not of the file
nm_content_digest <- function(body) {
  digest::digest(nm_reduce_html(body), algo = "sha256", serialize = FALSE)
}

#' LIVE: has New Mexico awarded yet?
#'
#' Missouri's `--probe` shape (session 29): fetch, compare, report, ARCHIVE
#' NOTHING. The tripwires run against the LIVE bytes rather than the archive --
#' session 25's Indiana lesson as code.
#'
#' IT COMPARES A CONTENT DIGEST, AND THE MECHANISM IS THE SIXTH THIS PROJECT
#' HAS MET. hca.nm.gov runs the WordPress Complianz cookie-consent plugin,
#' which writes a `privacy-statement-children` URL into a JSON config inside a
#' script body -- and draws that URL from the site's own posts AT RANDOM on
#' each render. Twenty minutes apart it served "/snapchanges/" and a 2021
#' suicide-prevention press release, moving the page from 199,369 to 199,464
#' bytes.
#'
#' IT IS CALIFORNIA'S antispambot() FINDING ONE PLUGIN OVER, WITH ONE
#' DIFFERENCE THAT MATTERS: California's re-roll was CONSTANT-LENGTH and this
#' one is not, so a byte-count check passes California's and fails this. And
#' THREE FETCHES SECONDS APART HERE WERE BYTE-IDENTICAL while the copy taken
#' twenty minutes earlier was not -- California's lesson confirmed a third
#' time, by a third mechanism. Stripping script bodies absorbs it: the reduced
#' text is identical across all four copies at 6,978 characters.
nm_probe <- function(keys = NM_PROBE_KEYS) {
  message("[NM] LIVE probe, ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"))
  changed <- character(0)
  bodies  <- list()
  for (i in seq_along(keys)) {
    key <- keys[[i]]
    if (i > 1L) Sys.sleep(NM_HOST_THROTTLE_S)
    served <- nm_get(nm_source(key, "url"), paste0("probe:", key))
    bodies[[key]] <- served
    live <- nm_content_digest(served)
    have <- nm_content_digest(readBin(nm_path(key), "raw",
                                      file.size(nm_path(key))))
    same <- identical(live, have)
    message(sprintf("  %-10s %s  %s", key, if (same) "UNCHANGED" else "CHANGED  ",
                    substr(live, 1, 16)))
    if (!same) changed <- c(changed, key)
  }

  txt <- lapply(bodies, nm_reduce_html)
  nm_assert_no_award_roster(programme = txt$programme)
  nm_assert_pending_not_awarded(programme = txt$programme)
  nm_assert_programme_provenance(programme = txt$programme)
  nm_assert_roster_control(rhcdf = txt$rhcdf, news = txt$news)
  nm_assert_candidates_are_rhcdf_recipients(rhcdf = txt$rhcdf)
  message("[NM] the award tripwires pass against the LIVE bytes: New Mexico ",
          "has not published a recipient-level RHTP award roster.")
  if (length(changed)) {
    message("[NM] CHANGED, read them: ", paste(changed, collapse = ", "))
  }
  invisible(list(changed = changed))
}


# -- CLI ----------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args  <- commandArgs(trailingOnly = TRUE)
  force <- "--force" %in% args
  if ("--probe" %in% args)    nm_probe()
  if ("--fetch" %in% args)    nm_fetch(force = force)
  if ("--validate" %in% args) {
    rhtp_nm_assert(strict_footer = "--strict" %in% args)
    message("[NM] all assertions pass.")
  }
  if ("--build" %in% args)    rhtp_nm_build()
  if ("--report" %in% args)   rhtp_nm_report()
  if (!length(intersect(args, c("--probe", "--fetch", "--validate", "--build",
                                "--report")))) {
    message("usage: Rscript R/03ad_nm_year1_probe.R ",
            "[--probe] [--fetch [--force]] [--validate] [--build] [--report]")
  }
}
