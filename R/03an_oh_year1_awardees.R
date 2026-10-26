#!/usr/bin/env Rscript
# 03an_oh_year1_awardees.R ---------------------------------------------------
#
# OHIO -- ONE NAMED, PRICED AWARD, AND THE FIRST CMS FOOTER IN THIS
# REPOSITORY WHOSE FIGURE IS THE SUBAWARD ITSELF.
#
# Ohio holds $202,030,262 (§7.1). The Governor announced on 2026-07-01:
#
#   "Ohio Governor Mike DeWine today announced the first Rural Health
#    Transformation Program award to Ohio University to strengthen the rural
#    healthcare workforce. This is the first of many initiatives that will be
#    funded through the $202 million awarded to Ohio ..."
#
# ONE AWARD ACTION, $10,000,000, TO A UNIVERSITY. So Ohio contributes ONE
# PRICED ROW AND ZERO HOSPITAL DOLLARS: §10.2 codes a university
# `NON_HOSPITAL` and §0.3a judges the RECIPIENT, so the workforce activity --
# summer camps, career fairs, apprenticeships for school students -- does not
# make it a hospital row. Maine's University of New England award is the
# precedent, and this is the same coding for the same reason.
#
# ============================================================================
# §0.2: THE FOOTER'S AMOUNT IS TIER 3, WHICH THE TIER CHECK CANNOT SEE
# ============================================================================
#
# Every CMS footer this project has read prints either the STATE ALLOTMENT
# (Tier 1 -- Iowa's June notices, Delaware, Idaho, Arkansas, Wyoming and most
# others) or an RFP's own POOL (Tier 2 -- Iowa's eight Jan/Feb notices). Ohio's
# prints NEITHER:
#
#   "This project is supported by the Centers for Medicare & Medicaid Services
#    (CMS) ... as part of a financial assistance award totaling $10,000,000
#    with 100 percent funded by CMS/HHS."
#
# $10,000,000 IS THE SUBAWARD -- the exact figure in the headline, on a release
# announcing one award to one recipient. That is a THIRD position on §0.2's
# axis and the first instance of it here.
#
# AND IT IS A LIMIT OF THE TIER CHECK, STATED RATHER THAN PATCHED.
# `rhtp_assert_footer_not_allotment()` asks ONE question: does this figure
# collide with the state's allotment? Ohio's $10,000,000 does not collide with
# $202,030,262, so declared `SOLICITATION` it is ACCEPTED -- and it is not a
# solicitation pool, it is a Tier 3 award. The check separates Tier 1 from
# NOT-TIER-1 and has never been able to separate Tier 2 from Tier 3, because
# the §7.1 anchor is the only external number it has.
#
# THE FIX IS NOT MORE MACHINERY, AND THAT IS THE POINT WORTH RECORDING. What
# tells you Ohio's footer is Tier 3 is the DOCUMENT: a release that names one
# recipient, states one figure in its own headline, and says "Additional
# contracts will be awarded in the coming months". Session 37's Iowa rule said
# the tier is not in the footer's GRAMMAR; Ohio adds that it is not always in
# the footer's ARITHMETIC either. Read what the document says the number is.
#
# THE TRIPWIRE IS THE STATE'S OWN SENTENCE. "Additional contracts will be
# awarded in the coming months" -- so this file is a PARTIAL year by
# construction, and `oh_assert_more_to_come()` is designed to notice when that
# sentence stops being true.
#
# ODH'S OWN PROGRAMME PAGE IS STALE, AND IT IS RECORDED RATHER THAN READ.
# `odh.ohio.gov`'s RHTP page still says "the State of Ohio WILL SUBMIT an
# application. IF AWARDED, it will manage the funds" -- on the same page that
# links the Governor's award announcement. A stale page is not evidence of a
# stalled programme (Mississippi's DOM page does the same thing), and it names
# no recipient.
#
# ONE CHANNEL IS UNREADABLE AND IS RECORDED AS UNKNOWN (§0.4). ODH's
# "Solicitation Invitations" page says "Please utilize the table and search
# functionality provided below" and the rows are not in the HTML -- Maine's CGI
# Advantage, Connecticut's CTsource, Louisiana's rhtla.net and Tennessee's
# Caspio portal in a fifth costume. What Ohio has solicited or awarded inside
# it is a statement about OUR ACCESS.
#
# §0.1: RCJ IS RIGHT ABOUT OHIO, WHICH IS THE UNUSUAL CASE. Its single Tier 3
# candidate is "Ohio University" at $10,000,000 under this exact release's
# title -- the correct recipient at the correct amount from the correct
# document. Iowa, Michigan and Kansas are the states where the aggregator's
# names are right; Ohio is one of very few where the AMOUNT is right too.
#
# Usage:
#   Rscript R/03an_oh_year1_awardees.R --fetch [--force] | --validate |
#           --build | --probe | --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
  library(purrr); library(httr); library(digest); library(here); library(rlang)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

OH_STATE     <- "OH"
OH_ALLOTMENT <- 202030262        # cms_fy2026_allotments.csv (§7.1)
OH_AWARD     <- 10000000         # Ohio University -- AND the footer's figure
OH_ANNOUNCED <- as.Date("2026-07-01")
OH_NOA_DATE  <- as.Date("2025-12-29")

OH_EVIDENCE_DIR <- here::here("data", "evidence", "OH")
OH_CSV        <- here::here("data", "reference", "oh_year1_awardees.csv")
OH_STATUS_CSV <- here::here("data", "reference", "oh_year1_status.csv")
OH_DISPO_CSV  <- here::here("data", "reference",
                            "oh_rcj_candidate_disposition.csv")

OH_USER_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                        "+https://www.aha.org)")

OH_RELEASE_URL <- paste0(
  "https://governor.ohio.gov/wps/portal/gov/governor/media/news-and-media/",
  "governor-dewine-announces-first-rural-health-transformation-program-",
  "award-to-ohio-university-for-10-million")

OH_SOURCES <- tibble::tribble(
  ~key, ~url, ~file, ~note,
  "release", OH_RELEASE_URL,
  "2026-09-03_oh_ohio_university_award_release.html",
  paste("THE AWARD SOURCE. 'the first Rural Health Transformation Program",
        "award to Ohio University', $10,000,000, 2026-07-01 -- and the CMS",
        "footer whose figure is that award rather than the allotment."),
  "odh",
  "https://odh.ohio.gov/know-our-programs/rural-health-transformation-program",
  "2026-10-26_oh_odh_rhtp_programme.html",
  paste("ODH's programme page, RE-BASED session 108 after reading the diff: the",
        "stale pre-award text (the 2026-09-03 copy, kept) is replaced by a link",
        "list of the RHT resource pages (Healthcare Workforce, Pharmacy, Hospitals",
        "and CINs, School-Based Health Centers, EMS and others). Names no recipient."),
  "allotment_release",
  paste0("https://governor.ohio.gov/media/news-and-media/",
         "governor-dewine-announces-ohios-rural-health-transformation-",
         "program-award"),
  "2026-09-03_oh_allotment_release.html",
  paste("THE TIER 1 RELEASE, archived as the contrast: 2025-12-29, 'Ohio will",
        "receive more than $200 million'. Same publisher, same programme,",
        "different tier -- §0.2 across two documents.")
)

oh_source <- function(key, field) {
  row <- OH_SOURCES[OH_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[OH] unknown source key: ", key, call. = FALSE)
  row[[field]]
}
oh_path <- function(key) file.path(OH_EVIDENCE_DIR, oh_source(key, "file"))


# -- retrieval ---------------------------------------------------------------

oh_get <- function(url, label) {
  resp <- httr::GET(url, httr::user_agent(OH_USER_AGENT),
                    httr::config(followlocation = TRUE), httr::timeout(120))
  if (httr::status_code(resp) != 200L) {
    stop("[OH] ", label, ": HTTP ", httr::status_code(resp), " from ", url,
         call. = FALSE)
  }
  httr::content(resp, as = "raw")
}

oh_fetch <- function(force = FALSE) {
  dir.create(OH_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  entries <- purrr::map_dfr(seq_len(nrow(OH_SOURCES)), function(i) {
    src <- OH_SOURCES[i, ]
    dest <- file.path(OH_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[OH] have ", src$file)
    } else {
      raw <- oh_get(src$url, src$key)
      txt <- rawToChar(raw[raw != as.raw(0)]); Encoding(txt) <- "bytes"
      if (grepl("[ps]k\\.ey[A-Za-z0-9._-]{10,}|AIza[0-9A-Za-z_-]{30,}", txt,
                useBytes = TRUE, perl = TRUE)) {
        stop("[OH] ", src$key, " carries a credential-shaped string; NOT ",
             "written.", call. = FALSE)
      }
      writeBin(raw, dest)
      message("[OH] wrote ", src$file, " (", length(raw), " bytes)")
      Sys.sleep(2)
    }
    tibble::tibble(file = src$file, bytes = file.size(dest),
                   sha256 = digest::digest(file = dest, algo = "sha256"))
  })
  writeLines(c(
    "OHIO -- RHTP evidence archive",
    "",
    "Fetched 2026-09-03 by R/03an_oh_year1_awardees.R --fetch.",
    "Bodies are written with writeBin(), so re-hashing reproduces the digest.",
    "",
    "governor.ohio.gov IS AN IBM WEBSPHERE PORTAL and its pages carry a large",
    "amount of component scaffolding in HTML comments. The reduction keeps",
    "them (they are inert), so the CONTENT digest is stable while remaining",
    "sensitive to the article text, which is what --probe compares.",
    "",
    "THE AWARD RELEASE'S CANONICAL PATH IS THE /wps/portal/ ONE. The shorter",
    "governor.ohio.gov/media/news-and-media/... form answers 200 for the",
    "ALLOTMENT release but serves a generic shell for this one.",
    "",
    "file  bytes  sha256",
    paste(entries$file, entries$bytes, entries$sha256, sep = "  ")),
    file.path(OH_EVIDENCE_DIR, "MANIFEST.txt"))
  invisible(entries)
}


# -- reduction ---------------------------------------------------------------

oh_reduce_html <- function(raw) {
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "UTF-8"
  txt <- stringr::str_remove_all(
    txt, stringr::regex("<(script|style|noscript)[^>]*>.*?</\\1>",
                        dotall = TRUE, ignore_case = TRUE))
  txt <- stringr::str_replace_all(txt, "<[^>]+>", " ")
  txt <- stringr::str_replace_all(txt, "&nbsp;|&#160;", " ")
  txt <- stringr::str_replace_all(txt, "&amp;|&#038;", "&")
  txt <- stringr::str_replace_all(txt, "&#8217;|&#39;|&rsquo;|&#8216;", "'")
  txt <- stringr::str_replace_all(txt, "&#8220;|&#8221;|&ldquo;|&rdquo;|&quot;",
                                  "\"")
  txt <- stringr::str_replace_all(txt, "&#8212;|&mdash;|&#8211;|&ndash;", "-")
  txt <- stringr::str_replace_all(txt, "[\u2010-\u2015\u2212]", "-")
  txt <- stringr::str_replace_all(txt, "[ \t\u00a0]+", " ")
  txt <- stringr::str_replace_all(txt, "\\s*\n\\s*", "\n")
  stringr::str_trim(txt)
}

oh_html_text <- function(key, body = NULL) {
  raw <- if (is.null(body)) readBin(oh_path(key), "raw",
                                    file.size(oh_path(key))) else body
  oh_reduce_html(raw)
}

oh_content_digest <- function(key, body = NULL) {
  digest::digest(oh_html_text(key, body), algo = "sha256")
}

oh_have_archive <- function() {
  all(file.exists(file.path(OH_EVIDENCE_DIR, OH_SOURCES$file)))
}


# -- assertions --------------------------------------------------------------

#' The release names Ohio University and prices it at $10,000,000
oh_assert_the_award <- function(body = NULL) {
  txt <- stringr::str_replace_all(oh_html_text("release", body), "\\s+", " ")
  want <- c(
    "announced the first Rural Health Transformation Program award to Ohio University",
    "financial assistance award totaling $10,000,000")
  missing <- want[!vapply(want,
                          function(w) stringr::str_detect(txt,
                                                          stringr::fixed(w)),
                          logical(1))]
  if (length(missing)) {
    stop("[OH] the release no longer says: ",
         paste(sQuote(missing), collapse = "; "), ".", call. = FALSE)
  }
  invisible(TRUE)
}

#' §0.2: the footer's figure IS the subaward, and the tier check cannot see it
#'
#' ASSERTED RATHER THAN REPAIRED. The point of this check is that the shared
#' rule ACCEPTS Ohio's footer as a SOLICITATION pool -- correctly, on the only
#' question it can ask -- while the figure is actually Tier 3. If someone
#' later teaches the rule to refuse it, they will have had to give it a
#' concept of Tier 3, and they should come and read this first.
oh_assert_footer_is_the_subaward <- function(body = NULL) {
  f <- rhtp_footer_parse(oh_html_text("release", body))
  if (nrow(f) != 1L) {
    stop("[OH] expected exactly ONE CMS footer on the release; parsed ",
         nrow(f), ".", call. = FALSE)
  }
  if (!f$fully_federal || abs(f$tier_amount - OH_AWARD) > 0.005) {
    stop("[OH] the release's footer no longer prints $10,000,000 at 100 ",
         "percent. Its figure being the SUBAWARD -- not the allotment, not a ",
         "pool -- is this state's §0.2 finding.", call. = FALSE)
  }
  # It is NOT the allotment, and the rule says so.
  refused <- tryCatch({
    rhtp_assert_footer_not_allotment(OH_AWARD, OH_STATE, "STATE_ALLOTMENT",
                                     label = "OH footer read as the allotment")
    FALSE
  }, error = function(e) TRUE)
  if (!refused) {
    stop("[OH] $10,000,000 is now accepted as Ohio's allotment.",
         call. = FALSE)
  }
  # And declared SOLICITATION it is ACCEPTED -- which is the limit, pinned.
  accepted <- isTRUE(rhtp_assert_footer_not_allotment(
    OH_AWARD, OH_STATE, "SOLICITATION", label = "OH footer read as a pool"))
  if (!accepted) {
    stop("[OH] the §0.2 rule now refuses Ohio's $10,000,000. If it has been ",
         "given a Tier 2/Tier 3 distinction, read this file's header: the ",
         "rule has only ever had the §7.1 anchor to compare against, and ",
         "what identifies Ohio's figure as a SUBAWARD is the document, not ",
         "the arithmetic.", call. = FALSE)
  }
  invisible(TRUE)
}

#' Ohio says more is coming, so this file is a PARTIAL year
oh_assert_more_to_come <- function(body = NULL) {
  txt <- stringr::str_replace_all(oh_html_text("release", body), "\\s+", " ")
  if (!stringr::str_detect(
        txt, stringr::fixed("Additional contracts will be awarded"))) {
    stop("[OH] the release no longer says 'Additional contracts will be ",
         "awarded in the coming months'. That sentence is why this file is a ",
         "PARTIAL year; if Ohio has finished awarding, re-read the channel.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' ODH's page names nobody and is stale
oh_assert_odh_names_nobody <- function(body = NULL) {
  txt <- stringr::str_replace_all(oh_html_text("odh", body), "\\s+", " ")
  if (stringr::str_detect(txt, stringr::fixed("Ohio University"))) {
    stop("[OH] ODH's programme page now names Ohio University. It may have ",
         "started publishing a roster -- read it.", call. = FALSE)
  }
  if (!stringr::str_detect(txt,
                           stringr::fixed("the State of Ohio will submit an application"))) {
    message("[OH] ODH's page no longer carries its stale pre-award sentence. ",
            "That is worth a look: it may have been rewritten with award ",
            "information.")
  }
  invisible(TRUE)
}

#' §6.2's date test
oh_assert_after_noa <- function() {
  if (OH_ANNOUNCED <= OH_NOA_DATE) {
    stop("[OH] the award no longer postdates the Notice of Award.",
         call. = FALSE)
  }
  invisible(as.integer(OH_ANNOUNCED - OH_NOA_DATE))
}

#' One priced row, and NO hospital bucket
oh_assert_contributes_no_bucket <- function(awards = NULL) {
  d <- if (is.null(awards)) oh_year1_awardees() else awards
  stopifnot(nrow(d) == 1L, d$amount == OH_AWARD)
  part <- rhtp_hospital_dollar_partition(d)
  if (nrow(part) != 0L) {
    stop("[OH] Ohio now contributes to a hospital bucket. Its one recipient ",
         "is a UNIVERSITY (§10.2 NON_HOSPITAL, Maine's UNE precedent), so it ",
         "should contribute to none. $10,000,000 is the largest single ",
         "misclassification available in this state.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- the award file ----------------------------------------------------------

oh_year1_awardees <- function() {
  cls <- rhtp_classify_recipient_type("Ohio University", OH_STATE)
  tibble::tibble(
    state = OH_STATE,
    row_no = 1L,
    awardee = "Ohio University",
    amount = OH_AWARD,
    recipient_type = cls$recipient_type,
    distributed_to_hospital = "No",
    note = paste(
      "Ohio's FIRST RHTP award, announced 2026-07-01 by Governor DeWine.",
      "Rural healthcare workforce: healthcare exploration for 8th-grade and",
      "high-school students through summer camps and career fairs, exposure",
      "for undergraduates and graduate students, and expanded paid",
      "apprenticeships. 'Additional contracts will be awarded in the coming",
      "months', so Ohio's Year 1 is PARTIAL by construction."),
    recipient_confirmed = "Yes",
    amount_confirmed = "Yes",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = paste(
      "Governor DeWine Announces First Rural Health Transformation Program",
      "Award to Ohio University for $10 Million"),
    state_source_url = OH_RELEASE_URL,
    validation_source_type = "GOVERNOR_PRESS_RELEASE",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03an_oh_year1_awardees.R",
    ccn = NA_character_,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    recipient_type_source = paste(
      "STATED BY THE SOURCE AND AGREED BY §8. The release quotes Ohio",
      "University's Vice President of Health Affairs and describes the",
      "recipient as a university throughout;",
      "rhtp_classify_recipient_type() independently returns",
      "UNIVERSITY_OR_AHC at HIGH on the name. Two readings, same answer, no",
      "override needed -- unlike Delaware, where §8's name rule misses all",
      "three recipients."),
    determination_confidence = cls$determination_confidence,
    flag_reason = NA_character_,
    award_pool = "Rural Health Workforce Development",
    budget_period = "Budget Period 1",
    flow_type = "NON_HOSPITAL",
    hospital_benefiting = "Unclear",
    hospital_attribution = "NOT_HOSPITAL",
    intermediary_name = NA_character_,
    determination_basis = paste(
      "§10.2 NON_HOSPITAL -- 'Recipient is clearly not a hospital -- a school",
      "district, a UNIVERSITY, an EMS agency, a vendor' -- and §0.3a judges",
      "the RECIPIENT, not the activity. The activity is rural healthcare",
      "workforce development and the recipient is Ohio University, so this is",
      "Maine's University of New England row for the same reason. The release",
      "names the subrecipient class as 'employers, schools, and community",
      "organizations' and students, which contains no hospital, so this is",
      "Missouri's MEMSA / Maine's UNE coding rather than New Hampshire's FHC",
      "(hospitals among others, Unclear). hospital_benefiting is Unclear",
      "rather than No because a rural healthcare workforce plainly reaches",
      "hospital employers eventually, and the release does not say so; it",
      "moves no figure either way. AMOUNT IS EXACT: $10,000,000 in the",
      "headline, the body and the CMS footer."),
    amount_basis = paste(
      "EXACT, and stated three times by the publisher -- the headline ('for",
      "$10 Million'), and the CMS footer ('a financial assistance award",
      "totaling $10,000,000'). NOTE THE FOOTER IS THE SUBAWARD HERE, not the",
      "state allotment and not a pool: the first such footer in this",
      "repository (§0.2)."),
    round_amount = NA_real_,
    announcement_date = OH_ANNOUNCED,
    source_archive_path = file.path("data", "evidence", "OH",
                                    oh_source("release", "file")))
}

# -- session 104: ODH's child pages (owner-approved) --------------------------
#
# ODH's "Hospitals, Clinically Integrated Networks and Rural Health Innovation
# Hubs, and Maternal Care" page (2026-10-16) and its "Pharmacy" page
# (2026-10-15), archived by session 103 under recheck/2026-10-16/OH/.
#
# THE $92M IS THREE SUB-POOLS, AND ONLY ONE IS HOSPITALS ONLY. The page's
# "Total Funding $92,000,000" is $30.3M + $31.4M + $30.3M:
#   Hospitals   "This investment provides $30.3 million in one-time direct
#               payments to 22 rural hospitals." -- 22 named, every one a
#               hospital on CMS OH enrolment (below).
#   CINs/Hubs   "$31.4 million to establish/expand these structured alliances"
#               -- 7 named, including the Ohio Association of Community Health
#               Centers and the Child & Family Health Collaborative of Ohio.
#   Maternal    "$30.3 million to improving maternal care" -- 6 named,
#               including the Ohio Association of Community Health Centers and
#               the Ohio Health Institute.
# CMS's 2026-10-16 Ohio release says the same: "another $30.3 million will fund
# one-time equipment and facility upgrades at 22 rural hospitals", and "An
# additional $30.3 million will go to hospital networks and health centers".
# So NON-HOSPITALS SHARE THE $92M, and the $92M, the $31.4M and the maternal
# $30.3M stay out of every bucket (owner rule, session 104). THE HOSPITAL
# $30.3M IS STATED FOR THE 22 HOSPITALS ALONE (owner ruling, session 105: the
# shared-with-non-hospitals test applies to each separately priced component,
# not to the headline; CLAUDE.md §7), so it is ONE
# POOL_NAMED_HOSPITALS row at the stated (rounded) amount, never split per
# hospital (§6.2) -- CT's Hartford HealthCare pair is the shape. The page also
# says "The funded projects haven't been announced yet", which is the row's
# stated vulnerability: the payments are announced, the per-hospital projects
# are not.
#
# THE 22 ARE ALSO ROWS AT $0 (owner instruction (a)), typed on CMS OH Hospital
# Enrollments (federal_records/2026-10-19/). The pool row carries the money;
# the 22 carry the names; the two buckets are never added.
#
# THE OHIO PHARMACISTS ASSOCIATION: "The Ohio Pharmacists Association (OPA)
# has been awarded $2 million" -- a non-hospital row. The State of Ohio Board of
# Pharmacy "will use $1.15 million" (the Funded Projects list prints "$1.5
# million", and the total "$3,150,00"): a STATE AGENCY's own allocation, never
# an award row (CT DEEP precedent); the page's internal conflict is recorded.

OH_S104_DIR <- file.path("data", "evidence", "recheck", "2026-10-16", "OH")
# SESSION 108: the hospitals page is RE-BASED to its 2026-10-26 copy after
# reading the diff -- the only change is "Funded Projects The funded projects
# haven't been announced yet. Please check back soon" replaced by a "News
# Release" link to the Governor's $92M release. The 2026-10-16 copy stays.
OH_S108_DIR <- file.path("data", "evidence", "recheck", "2026-10-26", "OH")
OH_S104_PAGES <- tibble::tribble(
  ~key, ~url, ~file, ~dir,
  "hospitals", "https://odh.ohio.gov/wps/portal/gov/odh/know-our-programs/rural-health-transformation-program/rht-resources/healthcare-centers",
  "2026-10-26_odh_rht_hospitals_cins_hubs_maternal.html", OH_S108_DIR,
  "pharmacy", "https://odh.ohio.gov/wps/portal/gov/odh/know-our-programs/rural-health-transformation-program/rht-resources/pharmacy",
  "2026-10-16_odh_rht_pharmacy.html", OH_S104_DIR)
OH_S104_HOSP_PRIOR <- file.path(OH_S104_DIR, "2026-10-16_odh_rht_hospitals_cins_hubs_maternal.html")
oh_s104_path <- function(key) file.path(OH_S104_PAGES$dir[OH_S104_PAGES$key == key],
                                        OH_S104_PAGES$file[OH_S104_PAGES$key == key])
OH_S104_ANNOUNCED <- as.Date("2026-10-16")
OH_HOSP_FED <- file.path("data", "evidence", "federal_records", "2026-10-19",
                         "cms_hosp_enrollments_OH.json")
OH_POOL_SENTENCE <- "This investment provides $30.3 million in one-time direct payments to 22 rural hospitals."
OH_HOSP_POOL <- 30300000

oh_s104_text <- function(key, body = NULL) {
  f <- oh_s104_path(key)
  raw <- if (is.null(body)) readBin(here::here(f), "raw", file.size(here::here(f))) else body
  stringr::str_squish(gsub("[\u2018\u2019]", "'", oh_reduce_html(raw)))
}

# The 22, as printed (trailing full stop dropped), with the CMS OH enrolment
# each is typed on. `ccn` only where ONE hospital CCN answers the string.
OH_22 <- tibble::tribble(
  ~awardee, ~match, ~ccn, ~enrolment,
  "Joint Township District Memorial Hospital", "EXACT", "360032", "JOINT TOWNSHIP DISTRICT MEMORIAL HOSPITAL dba GRAND LAKE HEALTH SYSTEM (360032, Saint Marys)",
  "Knox Community Hospital", "EXACT", "360040", "KNOX COMMUNITY HOSPITAL dba OVATION HEALTHCARE (360040, Mount Vernon)",
  "Pomerene Hospital", "EXACT", "361337", "POMERENE HOSPITAL (361337, Millersburg), CRITICAL ACCESS HOSPITAL",
  "Salem Community Hospital", "EXACT", "360185", "SALEM COMMUNITY HOSPITAL dba SALEM REGIONAL MEDICAL CENTER (360185, Salem)",
  "Van Wert County Hospital", "BRIDGE", "360071", "VAN WERT COUNTY HOSPITAL ASSOCIATION (360071, Van Wert): the string drops 'Association'",
  "Mercer County Community Hospital", "BRIDGE", "360058", "MERCER COUNTY JOINT TOWNSHIP COMMUNITY HOSPITAL dba MERCER HEALTH (360058, Coldwater): the string drops 'Joint Township'",
  "Southeastern Ohio Regional Medical Center", "EXACT", "360203", "SOUTHEASTERN OHIO REGIONAL MEDICAL CENTER INC dba OHIOHEALTH SOUTHEASTERN MEDICAL CENTER (360203, Cambridge)",
  "TriHealth Clinton Regional Hospital", "EXACT", "360175", "TRIHEALTH HOSPITAL, INC dba TRIHEALTH CLINTON REGIONAL HOSPITAL (360175, Wilmington)",
  "Holzer Medical Center", "BRIDGE", NA, "HOLZER MEDICAL CENTER JACKSON (361320, Jackson, CAH) and HOLZER HOSPITAL FOUNDATION dba HOLZER (360054, Gallipolis): the string names neither exactly, and two enrolled Holzer hospitals answer it, so no CCN",
  "Ashtabula County Medical Center", "EXACT", "360125", "ASHTABULA COUNTY MEDICAL CENTER dba ASHTABULA REGIONAL MEDICAL CENTER (360125, Ashtabula)",
  "Wilson Memorial Hospital", "BRIDGE", "360013", "SHELBY COUNTY MEMORIAL HOSPITAL ASSOCIATION INC. dba WILSON HEALTH (360013, Sidney): Wilson Memorial Hospital is that hospital's name (general knowledge)",
  "Marion General Hospital", "EXACT", "360011", "MARION GENERAL HOSPITAL INC. (360011, Marion)",
  "O'Bleness Memorial Hospital", "EXACT", "360014", "SHELTERING ARMS HOSPITAL FOUNDATION, INC. dba OBLENESS MEMORIAL HOSPITAL (360014, Athens)",
  "Sojourn at Seneca", "BRIDGE", "364055", "50 ST LAWRENCE OPCO LLC dba SOJOURN AT SENECA SENIOR BEHAVIORAL HEALTH HOSPITAL (364055, Tiffin): the string truncates the DBA; a senior behavioral health hospital",
  "Fisher-Titus Medical Center", "EXACT", "360065", "FISHER-TITUS MEDICAL CENTER dba FISHER-TITUS HOSPITAL (360065, Norwalk)",
  "Mary Rutan Hospital", "EXACT", "360197", "MARY RUTAN HOSPITAL (360197, Bellefontaine)",
  "Blanchard Valley Regional Health Center", "EXACT", NA, "BLANCHARD VALLEY REGIONAL HEALTH CENTER dba BLANCHARD VALLEY HOSPITAL (360095, Findlay) and dba BLUFFTON HOSPITAL (361322, Bluffton, CAH): one legal entity, two hospital CCNs, so none on the row",
  "Community Hospital of Williams County", "BRIDGE", NA, "COMMUNITY HOSPITALS AND WELLNESS CENTERS dba PARKVIEW BRYAN HOSPITAL (360121, Bryan) and dba PARKVIEW MONTPELIER HOSPITAL (361327, Montpelier, CAH), Williams County: the string is not the enrolled name and the entity holds two hospital CCNs, so none on the row",
  "Coshocton Regional Medical Center", "EXACT", "360109", "PRIME HEALTHCARE FOUNDATION - COSHOCTON, LLC dba COSHOCTON REGIONAL MEDICAL CENTER (360109, Coshocton)",
  "East Liverpool City Hospitals", "BRIDGE", "360096", "THE CITY HOSPITAL ASSOCIATION dba EAST LIVERPOOL CITY HOSPITAL (360096, East Liverpool): the string pluralises the DBA",
  "Memorial Hospital", "AMBIGUOUS", NA, "TWO enrolled entities carry 'Memorial Hospital' exactly: MEMORIAL HOSPITAL (360156, Fremont) and MEMORIAL HOSPITAL OF UNION COUNTY dba MEMORIAL HOSPITAL (360092, Marysville). The page carries no city, so neither is chosen (no bridge by elimination, session 104)",
  "Wooster Community Hospital", "EXACT", "360036", "CITY OF WOOSTER dba WOOSTER COMMUNITY HOSPITAL (360036, Wooster)")

oh_assert_s104_sources <- function(hospitals_body = NULL) {
  t <- oh_s104_text("hospitals", hospitals_body)
  need <- c(OH_POOL_SENTENCE,
            "This project provides $31.4 million to establish/expand these structured alliances.",
            "This investment dedicates $30.3 million to improving maternal care.",
            "Total Funding $92,000,000",
            "News Release Governor DeWine Announces $92 Million to Expand Access to Quality Healthcare in Rural Ohio",
            "Ohio Association of Community Health Centers.",
            paste0(OH_22$awardee, "."))
  miss <- need[!vapply(need, function(w) grepl(w, t, fixed = TRUE), logical(1))]
  if (length(miss)) stop("[OH] the ODH hospitals page no longer says: ", paste(sQuote(miss), collapse = "; "), call. = FALSE)
  # Exactly 22 names between the pool sentence and the CINs heading.
  i <- regexpr(OH_POOL_SENTENCE, t, fixed = TRUE)
  blk <- substr(t, i + nchar(OH_POOL_SENTENCE), nchar(t))
  blk <- substr(blk, 1L, regexpr(" Clinically Integrated Networks and Rural Health Innovation Hubs Clinically",
                                 blk, fixed = TRUE) - 1L)
  nm <- stringr::str_trim(strsplit(stringr::str_trim(blk), "\\. ")[[1]])
  nm <- sub("\\.$", "", nm[nzchar(nm)])
  if (!identical(nm, OH_22$awardee)) {
    stop("[OH] the 22 hospital names moved: ", paste(setdiff(nm, OH_22$awardee), collapse = "; "), call. = FALSE)
  }
  if (abs(30.3e6 + 31.4e6 + 30.3e6 - 92e6) > 1) stop("[OH] the three sub-pools no longer sum to $92M.", call. = FALSE)
  p <- oh_s104_text("pharmacy")
  if (!grepl("The Ohio Pharmacists Association (OPA) has been awarded $2 million", p, fixed = TRUE) ||
      !grepl("Ohio Pharmacists Association: $2 million.", p, fixed = TRUE)) {
    stop("[OH] the pharmacy page no longer awards OPA $2 million.", call. = FALSE)
  }
  # §0.2: both footers print "$202 million", the ALLOTMENT ROUNDED to the
  # million ($202,030,262). The shared parser reads "$202 million" as $202, so
  # the rounding is asserted here rather than through rhtp_assert_footer_text_tier().
  for (k in OH_S104_PAGES$key) {
    if (!grepl("as part of a financial assistance award totaling $202 million with 100 percent funded by CMS/HHS",
               oh_s104_text(k), fixed = TRUE) || round(OH_ALLOTMENT / 1e6) != 202) {
      stop("[OH] the ODH ", k, " footer no longer prints the allotment as '$202 million' at 100 percent.", call. = FALSE)
    }
  }
  f <- jsonlite::fromJSON(here::here(OH_HOSP_FED))
  for (cc in stats::na.omit(OH_22$ccn)) {
    if (!cc %in% f$CCN) stop("[OH] CCN ", cc, " is not in the CMS OH hospital file.", call. = FALSE)
  }
  mh <- f$CCN[f$`ORGANIZATION NAME` == "MEMORIAL HOSPITAL" | f$`DOING BUSINESS AS NAME` %in% "MEMORIAL HOSPITAL"]
  if (length(unique(mh[grepl("^[0-9]{6}$", mh)])) < 2L) {
    stop("[OH] 'Memorial Hospital' is no longer ambiguous on CMS OH enrolment: re-read it.", call. = FALSE)
  }
  invisible(TRUE)
}

oh_s104_rows <- function() {
  src <- c(OH_S104_HOSP_PRIOR, oh_s104_path("pharmacy"))
  url <- OH_S104_PAGES$url
  base <- function(n) tibble::tibble(
    state = OH_STATE, fiscal_year = "FY2026 (Year 1)", extraction_method = "DIRECT_TEXT",
    validator = "R/03an_oh_year1_awardees.R", aha_id = NA_character_,
    rural_designation = NA_character_, reviewer = NA_character_,
    budget_period = "Budget Period 1", intermediary_name = NA_character_,
    round_amount = NA_real_, validation_source_type = "AGENCY_PRESS_RELEASE")[rep(1, n), ]
  conf <- ifelse(OH_22$match == "EXACT", "MEDIUM", "LOW")
  why <- paste0(
    ifelse(OH_22$match == "EXACT", "EXACT federal record: CMS OH Hospital Enrollments carry the string as the enrolled name or DBA: ",
           ifelse(OH_22$match == "AMBIGUOUS", "A HOSPITAL WITH NO CCN: ", "HAND-READ BRIDGE (LOW): ")),
    OH_22$enrolment, ".")
  h <- dplyr::bind_cols(base(22L), tibble::tibble(
    awardee = OH_22$awardee, amount = NA_real_, recipient_type = "HOSPITAL_OR_SYSTEM",
    distributed_to_hospital = "Yes",
    note = paste0("One of the 22 rural hospitals ODH names under 'Hospitals' (2026-10-16): '", OH_POOL_SENTENCE,
                  "' No per-hospital amount is published; the $30.3M is ONE POOL_NAMED_HOSPITALS row of this file, never divided (§6.2)."),
    recipient_confirmed = "Yes", amount_confirmed = "No",
    source_document_title = "ODH, Hospitals, Clinically Integrated Networks and Rural Health Innovation Hubs, and Maternal Care",
    state_source_url = url[1], ccn = OH_22$ccn,
    recipient_type_source = paste0("TYPED (session 104, ", OH_22$match, "): ", why),
    determination_confidence = conf, flag_reason = NA_character_,
    award_pool = "ODH Hospitals: one-time direct payments to 22 rural hospitals ($30.3M)",
    flow_type = "DIRECT", hospital_benefiting = "Yes", hospital_attribution = "NAMED_HOSPITAL",
    determination_basis = paste0("§10.2 DIRECT: ", why, " NAMED AT $0: the state prices only the 22-hospital pool."),
    amount_basis = "NO AMOUNT: ODH publishes no per-hospital figure. The pool is a separate row; it is never divided.",
    basis_type = ifelse(OH_22$match == "EXACT", "ORG_WEBSITE", "GENERAL_KNOWLEDGE"),
    announcement_date = OH_S104_ANNOUNCED, source_archive_path = src[1],
    cms_enrolment_record = paste0("CMS OH Hospital Enrollments: ", OH_22$enrolment, " (", OH_HOSP_FED, ")")))
  pool <- dplyr::bind_cols(base(1L), tibble::tibble(
    awardee = paste0("22 rural hospitals named by ODH (", paste(OH_22$awardee, collapse = "; "), ")"),
    amount = OH_HOSP_POOL, recipient_type = "HOSPITAL_OR_SYSTEM", distributed_to_hospital = "Yes",
    note = paste0("ODH: '", OH_POOL_SENTENCE, "' CMS (2026-10-16): 'another $30.3 million will fund one-time equipment and facility upgrades at 22 rural hospitals'. ",
                  "The page also says 'The funded projects haven't been announced yet.' The rest of the $92M ($31.4M CINs/Hubs, $30.3M maternal care) is shared with non-hospitals and is in no bucket."),
    recipient_confirmed = "Yes", amount_confirmed = "No",
    source_document_title = "ODH, Hospitals, Clinically Integrated Networks and Rural Health Innovation Hubs, and Maternal Care",
    state_source_url = url[1], ccn = NA_character_,
    recipient_type_source = "TYPED (session 104): the 22 named recipients are each a hospital on CMS OH Hospital Enrollments (see their own rows).",
    determination_confidence = "MEDIUM", flag_reason = "AMOUNT_ROUNDED_IN_SOURCE;MULTI_RECIPIENT_FIELD",
    award_pool = "ODH Hospitals: one-time direct payments to 22 rural hospitals ($30.3M)",
    flow_type = "DIRECT", hospital_benefiting = "Yes", hospital_attribution = "POOL_NAMED_HOSPITALS",
    determination_basis = paste0("§10.2 DIRECT, POOL_NAMED_HOSPITALS (owner rule, session 104; confirmed session 105, CLAUDE.md §7: a separately priced component stated for named hospitals alone): the call rests on ODH's sentence '",
                                 OH_POOL_SENTENCE, "' -- a figure stated for those 22 hospitals and no one else, all 22 named. ",
                                 "No per-hospital split is published, so the figure is one pool row and is never divided (§6.2); CT's Hartford HealthCare pair is the shape. ",
                                 "VULNERABILITY: the payments are announced, but the page says the funded projects are not."),
    amount_basis = "ROUNDED IN SOURCE ('$30.3 million'); never un-rounded or split.",
    basis_type = "STATE_SOURCE", announcement_date = OH_S104_ANNOUNCED, source_archive_path = src[1],
    cms_enrolment_record = NA_character_))
  opa <- dplyr::bind_cols(base(1L), tibble::tibble(
    awardee = "Ohio Pharmacists Association", amount = 2000000, recipient_type = "NONPROFIT_CBO",
    distributed_to_hospital = "No",
    note = "ODH Pharmacy page (2026-10-15): 'The Ohio Pharmacists Association (OPA) has been awarded $2 million for this initiative' -- an HIE connection for rural pharmacies. The State of Ohio Board of Pharmacy's $1.15M ('$1.5 million' in the Funded Projects list) is a state agency's own allocation and is not a row.",
    recipient_confirmed = "Yes", amount_confirmed = "Yes",
    source_document_title = "ODH, Pharmacy (Rural Health Transformation Resources)",
    state_source_url = url[2], ccn = NA_character_,
    recipient_type_source = "TYPED (session 104, FALLBACK): the page states no form and no CMS OH hospital enrolment carries the name (§8's standing fallback).",
    determination_confidence = "LOW", flag_reason = "AMOUNT_ROUNDED_IN_SOURCE;RECIPIENT_TYPE_INFERRED",
    award_pool = "ODH Pharmacy initiative", flow_type = "NON_HOSPITAL", hospital_benefiting = "Unclear",
    hospital_attribution = "NOT_HOSPITAL",
    determination_basis = "§10.2 NON_HOSPITAL: a pharmacists' association, not a hospital; §0.3a, the HIE's outpatient-hospital-pharmacy users do not make it a hospital row.",
    amount_basis = "ROUNDED IN SOURCE ('$2 million'), stated twice on the page.",
    basis_type = NA_character_, announcement_date = as.Date("2026-10-15"), source_archive_path = src[2],
    cms_enrolment_record = NA_character_))
  dplyr::bind_rows(opa, h, pool)
}

# SESSION 108, OWNER RULING (c): ODH's 13 network and maternal-care recipients
# are added at $0, each typed; the two shared pools ($31.4M CINs/Hubs, $30.3M
# maternal care) stay out of every bucket (§7, session 105). ONE ROW PER POOL
# LISTING, as printed: five organisations appear in both lists, so 13 rows name
# eight organisations. No per-recipient figure exists, so every amount is NA.
OH_CIN_POOL <- "ODH Clinically Integrated Networks and Rural Health Innovation Hubs ($31.4M, shared with non-hospitals; no bucket)"
OH_MAT_POOL <- "ODH Maternal Care ($30.3M, shared with non-hospitals; no bucket)"
OH_CIN_NAMES <- c("Ohio High Value Network", "Child & Family Health Collaborative of Ohio",
                  "Ohio State Health Network", "University Hospitals Health System",
                  "Beavercreek Medical Center (Soin/Kettering Health)",
                  "Ohio Association of Community Health Centers",
                  "Mercy Health - St. Rita's Medical Center (Lima)")
OH_MAT_NAMES <- c("Ohio High Value Network", "Ohio State Health Network",
                  "Beavercreek Medical Center (Soin/Kettering Health)",
                  "Ohio Association of Community Health Centers", "Ohio Health Institute",
                  "Mercy Health - St. Rita's Medical Center (Lima)")
OH_NET_WHY <- paste0(
  "A NETWORK OF HOSPITALS (a clinically integrated network, general knowledge), and ODH prices only ",
  "the shared pool: §10.2's association row needs the source to show funds reaching member hospitals, ",
  "and nothing does. PASS_THROUGH_UNRESOLVED, Unclear, no bucket (WSHA's shape).")
OH_13_TYPES <- tibble::tribble(
  ~awardee, ~recipient_type, ~flow, ~basis_type, ~confidence, ~ccn, ~why,
  "Ohio High Value Network", "NONPROFIT_CBO", "PASS_THROUGH_UNRESOLVED", "GENERAL_KNOWLEDGE", "LOW", NA, OH_NET_WHY,
  "Ohio State Health Network", "NONPROFIT_CBO", "PASS_THROUGH_UNRESOLVED", "GENERAL_KNOWLEDGE", "LOW", NA,
  paste0(OH_NET_WHY, " Ohio State's affiliate network of community hospitals; not OHIO STATE UNIVERSITY HOSPITALS (360085), which CMS enrols under its own name (§2: no bridge)."),
  "Child & Family Health Collaborative of Ohio", "NONPROFIT_CBO", "NON_HOSPITAL", NA, "LOW", NA,
  "§8's standing fallback: ODH states no form and no CMS OH hospital enrolment carries the name.",
  "University Hospitals Health System", "HOSPITAL_OR_SYSTEM", "DIRECT", "GENERAL_KNOWLEDGE", "LOW", NA,
  paste0("SYSTEM PARENT, LOW, GENERAL_KNOWLEDGE (owner rulings: Vandalia, Sanford/Avera, Guthrie, ",
         "Ballad/Sentara/Valley): the parent of UNIVERSITY HOSPITALS CLEVELAND MEDICAL CENTER (360137), ",
         "UNIVERSITY HOSPITALS GENEVA MEDICAL CENTER (CAH 361307), UNIVERSITY HOSPITALS CONNEAUT MEDICAL ",
         "CENTER (CAH 361308) and others on CMS OH Hospital Enrollments; not itself enrolled, so no CCN."),
  "Beavercreek Medical Center (Soin/Kettering Health)", "HOSPITAL_OR_SYSTEM", "DIRECT", "ORG_WEBSITE", "MEDIUM", "360360",
  "EXACT federal record: CMS OH Hospital Enrollments carry BEAVERCREEK MEDICAL CENTER dba SOIN MEDICAL CENTER (360360, Beavercreek); the parenthetical names the same DBA and its system.",
  "Ohio Association of Community Health Centers", "NONPROFIT_CBO", "NON_HOSPITAL", "GENERAL_KNOWLEDGE", "LOW", NA,
  "Ohio's association of community health centers (FQHCs), by general knowledge. Not a hospital.",
  "Mercy Health - St. Rita's Medical Center (Lima)", "HOSPITAL_OR_SYSTEM", "DIRECT", "ORG_WEBSITE", "MEDIUM", "360066",
  "EXACT federal record: CMS OH Hospital Enrollments carry MERCY HEALTH-ST RITAS MEDICAL CENTER LLC dba MERCY HEALTH-ST RITA'S MEDICAL CENTER (360066, Lima).",
  "Ohio Health Institute", "NONPROFIT_CBO", "NON_HOSPITAL", NA, "LOW", NA,
  "§8's standing fallback: ODH states no form and no CMS OH hospital enrolment carries the name. Not OHIOHEALTH (a system); no bridge is made (§2).")

oh_s108_rows <- function() {
  d <- dplyr::bind_rows(tibble::tibble(awardee = OH_CIN_NAMES, award_pool = OH_CIN_POOL),
                        tibble::tibble(awardee = OH_MAT_NAMES, award_pool = OH_MAT_POOL))
  t <- OH_13_TYPES[match(d$awardee, OH_13_TYPES$awardee), ]
  if (anyNA(t$awardee)) stop("[OH] an ODH network/maternal recipient is untyped.", call. = FALSE)
  hosp <- t$flow == "DIRECT"
  unres <- t$flow == "PASS_THROUGH_UNRESOLVED"
  tibble::tibble(
    state = OH_STATE, fiscal_year = "FY2026 (Year 1)", extraction_method = "DIRECT_TEXT",
    validator = "R/03an_oh_year1_awardees.R", aha_id = NA_character_,
    rural_designation = NA_character_, reviewer = NA_character_,
    budget_period = "Budget Period 1", round_amount = NA_real_,
    validation_source_type = "AGENCY_PRESS_RELEASE",
    awardee = d$awardee, amount = NA_real_, recipient_type = t$recipient_type,
    distributed_to_hospital = ifelse(hosp, "Yes", ifelse(unres, "Unclear", "No")),
    note = paste0("Named under ODH's '", sub(" \\(.*", "", sub("^ODH ", "", d$award_pool)),
                  "' list (2026-10-16 page, re-read 2026-10-26). ODH prices the pool only; it is shared with ",
                  "non-hospitals and is in no bucket (§7, session 105). Added at $0 on the owner's ruling (session 108)."),
    recipient_confirmed = "Yes", amount_confirmed = "No",
    source_document_title = "ODH, Hospitals, Clinically Integrated Networks and Rural Health Innovation Hubs, and Maternal Care",
    state_source_url = OH_S104_PAGES$url[1], ccn = t$ccn,
    recipient_type_source = paste0("TYPED (session 108): ", t$why),
    determination_confidence = t$confidence,
    flag_reason = dplyr::case_when(unres ~ "FLOW_UNRESOLVED_HOSPITAL_AFFILIATED",
                                   is.na(t$basis_type) ~ "RECIPIENT_TYPE_INFERRED",
                                   TRUE ~ NA_character_),
    award_pool = d$award_pool, flow_type = t$flow,
    hospital_benefiting = ifelse(hosp, "Yes", "Unclear"),
    hospital_attribution = ifelse(hosp, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = ifelse(unres, d$awardee, NA_character_),
    determination_basis = paste0("§10.2 ", t$flow, ": ", t$why,
                                 " NAMED AT $0: ODH prices only the shared pool, which enters no bucket."),
    amount_basis = "NO AMOUNT: ODH publishes no per-recipient figure; the pool is shared with non-hospitals and is not a row.",
    basis_type = t$basis_type, announcement_date = OH_S104_ANNOUNCED,
    source_archive_path = oh_s104_path("hospitals"),
    cms_enrolment_record = NA_character_)
}

oh_assert_s108_lists <- function(hospitals_body = NULL) {
  t <- oh_s104_text("hospitals", hospitals_body)
  # Each list is printed as "<name>. <name>. ... <name>." between its pool
  # sentence and the next heading; a name may carry a full stop of its own
  # ("St. Rita's"), so the block is compared WHOLE, never split.
  blk <- function(from, to) {
    i <- regexpr(from, t, fixed = TRUE)
    if (i < 0) return(NA_character_)
    rest <- substr(t, i + nchar(from), nchar(t))
    j <- regexpr(to, rest, fixed = TRUE)
    if (j < 0) return(NA_character_)
    stringr::str_squish(substr(rest, 1L, j - 1L))
  }
  cin <- blk("This project provides $31.4 million to establish/expand these structured alliances.", " Maternal Care ")
  mat <- blk("This investment dedicates $30.3 million to improving maternal care.", " Total Funding")
  if (!identical(cin, paste0(paste(OH_CIN_NAMES, collapse = ". "), ".")) ||
      !identical(mat, paste0(paste(OH_MAT_NAMES, collapse = ". "), "."))) {
    stop("[OH] ODH's CIN/Hub or maternal-care recipient list moved: re-read it (session 108).", call. = FALSE)
  }
  invisible(TRUE)
}

oh_all_rows <- function() {
  d <- dplyr::bind_rows(oh_year1_awardees(), oh_s104_rows(), oh_s108_rows())
  d$row_no <- seq_len(nrow(d))
  d
}

oh_assert_s104_rows <- function(d = oh_all_rows()) {
  part <- rhtp_hospital_dollar_partition(d)
  nh <- part[part$bucket == "NAMED_HOSPITAL", ]; pn <- part[part$bucket == "POOL_NAMED_HOSPITALS", ]
  if (nrow(d) != 38L || nh$rows != 27L || nh$dollars != 0 || pn$rows != 1L || pn$dollars != OH_HOSP_POOL ||
      nrow(part) != 2L) {
    stop("[OH] expected 38 rows: NAMED_HOSPITAL 27 / $0 (22 + 5 network/maternal hospital rows, ",
         "session 108) and POOL_NAMED_HOSPITALS 1 / $30,300,000.", call. = FALSE)
  }
  if (any(d$amount %in% c(92e6, 31.4e6))) stop("[OH] a shared sub-pool became a row.", call. = FALSE)
  rhtp_assert_high_has_ccn(d, "OH")
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital", "determination_confidence",
                "hospital_attribution", "basis_type", "hospital_benefiting")) {
    bad <- setdiff(stats::na.omit(unique(d[[col]])), rhtp_vocabulary(col))
    if (length(bad)) stop("[OH] ", col, " outside §8: ", paste(bad, collapse = ", "), call. = FALSE)
  }
  fl <- unlist(strsplit(stats::na.omit(d$flag_reason), ";"))
  if (length(setdiff(fl, rhtp_vocabulary("flag_reason")))) stop("[OH] flag_reason outside §8.", call. = FALSE)
  invisible(TRUE)
}

oh_status_table <- function() {
  tibble::tribble(
    ~state, ~channel, ~stage, ~publishes_roster, ~note,
    OH_STATE, "Rural Health Workforce Development (Ohio University)",
    "AWARDED_ONE_NAMED_AND_PRICED", "Yes - ONE NAME, ONE FIGURE",
    paste("$10,000,000, announced 2026-07-01. Ohio's first and so far only",
          "named RHTP award. A UNIVERSITY, so $0 of it is a hospital dollar."),
    OH_STATE, "Additional contracts", "PRE_AWARD", "No",
    paste("The release's own words: 'Additional contracts will be awarded in",
          "the coming months'. Ohio's Year 1 is a PARTIAL view by",
          "construction -- $192,030,262 of the allotment is unaccounted for",
          "in any public roster."),
    OH_STATE, "ODH Rural Health Transformation Program page",
    "STALE_NAMES_NOBODY", "No",
    paste("Names no recipient, and still reads 'the State of Ohio will submit",
          "an application. If awarded, it will manage the funds' on the same",
          "page that links the Governor's award announcement. Recorded, not",
          "read as evidence: a stale page is not a stalled programme",
          "(Mississippi's DOM page does the same)."),
    OH_STATE, "ODH Solicitation Invitations", "UNREADABLE", "UNKNOWN",
    paste("'Please utilize the table and search functionality provided below'",
          "-- the rows are not in the HTML. A stateful application this",
          "environment cannot search, so what Ohio has solicited or awarded",
          "inside it is a statement about OUR ACCESS, never about Ohio",
          "(§0.4). Maine's, Connecticut's, Louisiana's and Tennessee's",
          "precedent."),
    OH_STATE, "ODH Hospitals: one-time direct payments to 22 rural hospitals ($30.3M)",
    "ANNOUNCED_NAMED_POOL_UNSPLIT", "Yes - 22 NAMES, ONE POOL FIGURE",
    paste("Session 104. ODH (2026-10-16): 'This investment provides $30.3 million in",
          "one-time direct payments to 22 rural hospitals.' 22 rows at $0 and ONE",
          "POOL_NAMED_HOSPITALS row at the rounded $30.3M, never divided. The 10-16",
          "page said 'The funded projects haven't been announced yet.'; by 10-26 that",
          "line is replaced by a News Release link, and no per-hospital figure is printed."),
    OH_STATE, "ODH CINs / Rural Health Innovation Hubs ($31.4M) and Maternal Care ($30.3M)",
    "ANNOUNCED_NAMED_NO_AMOUNTS_SHARED", "Yes - NAMES ONLY",
    paste("Session 104. 7 and 6 named organisations, no per-recipient amount, and",
          "non-hospitals among them (Ohio Association of Community Health Centers,",
          "Ohio Health Institute, Child & Family Health Collaborative of Ohio). SESSION",
          "108, OWNER RULING (c): the 13 listings are rows at $0, each typed (5 are",
          "hospital rows: University Hospitals Health System, a system parent; Soin",
          "Medical Center and Mercy Health-St. Rita's, each twice). The two pools stay",
          "in no bucket. With the hospital pool they make CMS's $92M."),
    OH_STATE, "Governor's newsroom (channel control)",
    "PUBLISHES_AWARDS", "Yes",
    paste("The channel that carried this award and the 2025-12-29 allotment",
          "announcement. Ohio demonstrably publishes RHTP awards here in a",
          "recognisable, priced form, which is what makes the absence of a",
          "second one meaningful.")
  )
}

oh_disposition <- function() {
  rt <- rhtp_record_table_live()
  t3 <- rt %>% dplyr::filter(.data$state == OH_STATE,
                             .data$award_tier == "SUBAWARD")
  if (nrow(t3) != 1L) {
    stop("[OH] this disposition covers ONE Tier 3 candidate and the record ",
         "table now holds ", nrow(t3), ".", call. = FALSE)
  }
  tibble::tribble(
    ~state, ~group, ~rcj_rows, ~disposition, ~evidence,
    OH_STATE, "Ohio University", 1L, "REAL_AWARD_CARRIED_CORRECTLY",
    # Session 63: the cross-state examples this sentence used to list
    # (Missouri, Maine, Delaware, Michigan ...) went stale with the
    # 2026-09-24 pull, so it now names only the failure MODES (§6.1) and the
    # one neighbour whose row this repository re-read that day (Idaho).
    paste0("RCJ's only Ohio Tier 3 candidate is '", t3$awardee_name_clean,
           "' at $", format(t3$amount_announced, big.mark = ",",
                            scientific = FALSE),
           ", sourced to '", sub("^OH - [0-9]{4} - ", "", t3$source_doc_title),
           "'. THE CORRECT RECIPIENT ",
           "AT THE CORRECT AMOUNT FROM THE CORRECT DOCUMENT -- which is rare ",
           "enough to be worth stating: elsewhere the aggregator more often ",
           "carries a real recipient at a $1 placeholder (Idaho's, unchanged ",
           "on the 2026-09-24 pull), at the wrong grain, or at the wrong tier ",
           "(§6.1). Ohio is one of few states where the aggregator gets the ",
           "name AND the figure right, and the row was unchanged on the ",
           "2026-09-24 pull. It is still not the source: this file's row is ",
           "built from the Governor's release (§0.1).")
  )
}


# -- probe / validate / build / report ---------------------------------------

oh_probe <- function() {
  keys <- c("release", "odh")
  live <- purrr::map(keys, function(k) {
    r <- rhtp_probe_get(k, function() oh_get(oh_source(k, "url"), k),
                          oh_path(k)); Sys.sleep(2); r
  })
  names(live) <- keys
  cmp <- purrr::map_dfr(keys, function(k) {
    tibble::tibble(key = k,
                   archived = oh_content_digest(k),
                   live = oh_content_digest(k, live[[k]]))
  }) %>% dplyr::mutate(changed = .data$archived != .data$live)

  oh_assert_the_award(body = live$release)
  oh_assert_more_to_come(body = live$release)
  oh_assert_odh_names_nobody(body = live$odh)

  # THE NAME TRIPWIRE (§2.3, session 48). The phrase assertions above ask HOW
  # this page is worded; this asks WHOM it names, against the committed
  # archive. New Mexico is why it exists: HCA named six Regional Hubs and not
  # one of its ten award phrases matched. Subject pages only -- a control or a
  # press index moves for reasons that are not this state awarding.
  nm_keys <- c("release", "odh")
  rhtp_assert_no_new_organisations_across(
    live = stats::setNames(
      purrr::map(nm_keys, function(k) oh_html_text(k, live[[k]])), nm_keys),
    archived = stats::setNames(purrr::map(nm_keys, oh_html_text), nm_keys),
    state = "OH")

  # SESSION 104: ODH's child pages, where the 22 hospitals and the pharmacy
  # award are. Session 103 found the roster on a page this probe never read.
  s104 <- oh_probe_s104()
  cmp <- dplyr::bind_rows(cmp, s104$cmp)

  message("[OH] live probe ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " UTC")
  purrr::walk(seq_len(nrow(cmp)), function(i) {
    message(sprintf("  %-9s content %s", cmp$key[i],
                    if (cmp$changed[i]) "CHANGED" else "unchanged"))
  })
  if (any(cmp$changed)) {
    message("[OH] CONTENT CHANGED. Ohio said additional contracts were ",
            "coming; re-read for a second named award.")
  } else {
    message("[OH] UNCHANGED.")
  }
  invisible(list(changed = cmp$key[cmp$changed], findings = s104$findings))
}

#' The child pages: content digest, the name tripwire scoped to the page body
#' (the WebSphere chrome is the same on both copies but is read out of scope
#' anyway), and two findings -- the 22-hospital sentence going, and "The funded
#' projects haven't been announced yet" going (the per-hospital projects).
OH_S104_SCOPE <- c(from = "\\|\\s*Agency", to = "This project is supported by the Centers")
oh_probe_s104 <- function(fetch = NULL) {
  keys <- OH_S104_PAGES$key
  live <- stats::setNames(lapply(keys, function(k) {
    path <- here::here(oh_s104_path(k))
    if (!is.null(fetch)) return(fetch[[k]])
    r <- rhtp_probe_get(k, function() oh_get(OH_S104_PAGES$url[OH_S104_PAGES$key == k], k), path)
    Sys.sleep(2); r
  }), keys)
  cmp <- tibble::tibble(
    key = keys,
    changed = vapply(keys, function(k) digest::digest(oh_s104_text(k)) != digest::digest(oh_s104_text(k, live[[k]])),
                     logical(1)))
  scope <- function(t, k) rhtp_name_scope(t, OH_S104_SCOPE[["from"]], OH_S104_SCOPE[["to"]], state = "OH", page = k)
  rhtp_assert_no_new_organisations_across(
    live = stats::setNames(lapply(keys, function(k) scope(oh_s104_text(k, live[[k]]), k)), keys),
    archived = stats::setNames(lapply(keys, function(k) scope(oh_s104_text(k), k)), keys),
    state = "OH")
  findings <- character(0)
  h <- oh_s104_text("hospitals", live$hospitals)
  if (!grepl(OH_POOL_SENTENCE, h, fixed = TRUE)) {
    findings <- c(findings, "OH ODH HOSPITALS PAGE: the '$30.3 million ... 22 rural hospitals' sentence is gone. Re-read the pool row (session 104).")
  }
  # SESSION 108: "The funded projects haven't been announced yet" went on
  # 2026-10-21 (a News Release link replaced it). The check is now on the two
  # recipient lists ODH prints, which session 108 added at $0, and on a priced
  # per-recipient figure appearing anywhere in the CIN or maternal blocks.
  lists <- tryCatch(oh_assert_s108_lists(live$hospitals), error = function(e) conditionMessage(e))
  if (!isTRUE(lists)) {
    findings <- c(findings, paste0("OH ODH HOSPITALS PAGE: ", lists))
  }
  if (grepl("Funded Projects", h, fixed = TRUE)) {
    findings <- c(findings, "OH ODH HOSPITALS PAGE: a 'Funded Projects' section is back -- ODH may now price the 22 hospitals or the CIN/Hub/maternal projects. Read it.")
  }
  if (!grepl("The Ohio Pharmacists Association (OPA) has been awarded $2 million", oh_s104_text("pharmacy", live$pharmacy), fixed = TRUE)) {
    findings <- c(findings, "OH ODH PHARMACY PAGE: the OPA $2 million award sentence is gone. Read it.")
  }
  list(cmp = cmp, findings = findings)
}

oh_validate <- function() {
  if (!oh_have_archive()) {
    stop("[OH] the evidence archive is incomplete; run --fetch first.",
         call. = FALSE)
  }
  oh_assert_the_award()
  oh_assert_footer_is_the_subaward()
  oh_assert_more_to_come()
  oh_assert_odh_names_nobody()
  oh_assert_after_noa()
  oh_assert_contributes_no_bucket()
  oh_assert_s104_sources()
  oh_assert_s108_lists()
  oh_assert_s104_rows()
  message("[OH] all assertions pass.")
  invisible(TRUE)
}

oh_build <- function() {
  oh_assert_contributes_no_bucket(oh_year1_awardees())
  # Session 104: + OPA, the 22 named hospitals at $0 and the $30.3M pool row.
  d <- oh_all_rows()
  oh_assert_s104_rows(d)
  readr::write_csv(d, OH_CSV, na = "")
  message("[OH] wrote ", OH_CSV, " (", nrow(d), " rows)")
  st <- oh_status_table()
  if ("amount" %in% names(st)) stop("[OH] status table must have no amount col")
  readr::write_csv(st, OH_STATUS_CSV)
  message("[OH] wrote ", OH_STATUS_CSV, " (", nrow(st), " rows)")
  dp <- oh_disposition()
  rhtp_assert_disposition_prose(dp, "OH")
  readr::write_csv(dp, OH_DISPO_CSV)
  message("[OH] wrote ", OH_DISPO_CSV, " (", nrow(dp), " rows)")
  invisible(list(awards = d, status = st, disposition = dp))
}

oh_report <- function() {
  d <- oh_year1_awardees()
  cat("\nOHIO -- one named, priced award, and no hospital dollars\n")
  cat(strrep("=", 58), "\n\n")
  cat("Allotment (§7.1)     : $", format(OH_ALLOTMENT, big.mark = ","), "\n",
      sep = "")
  cat("Awarded and named    : $", formatC(OH_AWARD, format = "f", digits = 0,
                                             big.mark = ","),
      "  (", round(100 * OH_AWARD / OH_ALLOTMENT, 1), "% of allotment)\n",
      sep = "")
  cat("Named-hospital rows  : 0 -- the recipient is a UNIVERSITY\n")
  cat("Hospital buckets     : NONE AT ALL (Maine's UNE outcome)\n\n")
  print(as.data.frame(d %>%
                        dplyr::mutate(amount = formatC(.data$amount,
                                                       format = "f", digits = 0,
                                                       big.mark = ",")) %>%
                        dplyr::select("awardee", "amount", "recipient_type",
                                      "distributed_to_hospital")),
        row.names = FALSE)
  cat("\n§0.2: THE CMS FOOTER ON THIS RELEASE PRINTS $10,000,000 -- THE\n")
  cat("SUBAWARD ITSELF, not the allotment and not a pool. The first such\n")
  cat("footer here, and one the tier check cannot classify: it collides\n")
  cat("with no allotment, so declared SOLICITATION it is ACCEPTED. What\n")
  cat("says it is Tier 3 is the document, not the arithmetic.\n")
  cat("\n'Additional contracts will be awarded in the coming months.'\n")
  invisible(d)
}


if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) oh_fetch(force = "--force" %in% args)
  if ("--validate" %in% args) oh_validate()
  if ("--build" %in% args) oh_build()
  if ("--probe" %in% args) rhtp_probe_run("OH", oh_probe())
  if ("--report" %in% args) oh_report()
  if (!length(args)) {
    message("Usage: --fetch [--force] | --validate | --build | --probe | --report")
  }
}
