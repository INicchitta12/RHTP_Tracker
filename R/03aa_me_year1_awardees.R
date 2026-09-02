#!/usr/bin/env Rscript
# 03aa_me_year1_awardees.R ----------------------------------------------------
#
# MAINE -- RHTP Year 1. Maine led the RCJ_ONLY queue at 12 Tier 3 candidates,
# and ELEVEN OF THE TWELVE ARE NAMED MAINE HOSPITALS. No state has arrived at
# the top of that queue looking more like a hospital extraction. It is not one,
# and the state says so in its own words.
#
# WHAT MAINE HAS PUBLISHED.
#
#   ELEVEN NAMED RURAL HOSPITALS, and they are INVITED, not awarded. DHHS's
#   2026-07-31 release is headed "Maine DHHS Releases $30 Million to Strengthen
#   Rural Hospital Resiliency" and its sub-headline reads "Eleven rural
#   hospitals INVITED TO RECEIVE funding and technical assistance". DHHS
#   "identified and invited" them from Maine Health Data Organization financial
#   data; they did not apply. NO PER-HOSPITAL AMOUNT IS PUBLISHED, and the
#   State's own RHTP Advisory Committee deck of 2026-08-05 -- five days later --
#   says why: "Award amount and approved budget WILL BE CONFIRMED AFTER START OF
#   PARTICIPATION in the HE Cohort", against a timeline whose "Funding approved
#   and provided" milestone is FALL/WINTER and whose "HE Cohort begins" is
#   SEPTEMBER. This file ran 2026-09-02.
#
#   ONE NAMED PARTNER WITH AN AMOUNT: the University of New England's Shaw
#   Institute, $12,000,000, announced on DHHS's own blog. That is the ONLY
#   Maine RHTP award action this repository can evidence to a named recipient
#   and a figure, and UNE is a UNIVERSITY whose stated subrecipients are Public
#   Health District organisations and Tribal Health Centers. MAINE'S
#   NAMED-HOSPITAL DOLLARS ARE $0 AND ITS NAMED-HOSPITAL ROWS ARE 0.
#
# SO MAINE INVERTS NEVADA'S AND IOWA'S PAIRING, AND THAT IS THE POINT OF THE
# FILE. Nevada and Iowa publish named hospitals with no amounts, and the danger
# is reporting the $0 without the row count. Maine publishes eleven named
# hospitals that are NOT RECIPIENTS, and the danger runs the other way: a reader
# who counts them has invented eleven hospital awards. `me_rhef_cohort.csv`
# therefore has NO `amount` COLUMN (Texas's and Missouri's device), is NOT in
# `test_state_union.R`, and `me_assert_cohort_not_awarded()` is DESIGNED TO FAIL
# the day Maine confirms an award amount -- at which point the file must be
# REWRITTEN, not patched.
#
# EVERY OTHER MAINE CHANNEL IS PRE-AWARD, EACH WITH A DATE ON IT (Wisconsin's
# shape, four times over):
#
#   EMR Modernization  $30.0M  applications closed 8/14; "Provider contracts
#                              executed" FALL; ~70 eligible orgs / ~330 sites
#   APM Transition     $28.5M  applications due late August; "Payments issued"
#                              SEPTEMBER/OCTOBER; 58 eligible orgs
#   Rural Hosp. Effic. $30.0M  cohort invited; funding approved FALL/WINTER
#   DOE Careers Expl.  $0.5M   "Award Announcement: August 31, 2026" -- TWO DAYS
#                              BEFORE THIS RAN, and no roster was published
#
# §6.2 WITH THE FOOTER NON-STRICT (session 27's audit, session 30's form). All
# four DHHS RHTP pages carry "This PROGRAM is supported by ... $190,008,051.09",
# whose grammatical subject names no programme -- Wisconsin's weak form -- so it
# corroborates the AMOUNT against the §7.1 anchor and carries no provenance.
#
# AND MAINE SUPPLIES THE MEASUREMENT FROM THE OTHER DIRECTION. The Maine DOE
# funding opportunity carries NO CMS FOOTER AT ALL -- not the sentence, not the
# amount, not "Centers for Medicare" -- and is unambiguously RHTP, because it
# says so in its own words: "Funding for this opportunity is made available
# through Maine's federal Rural Health Transformation Program award". So on
# Maine's own estate the footer is neither necessary nor sufficient, and the
# thing present on every RHTP document is a PROGRAMME-SCOPED SENTENCE. Three of
# them, from three publishers, carry the provenance, and each is asserted.
#
# THE POSITIVE CONTROL IS MAINE'S OWN PROCUREMENT ARCHIVE, and it is the largest
# this project has used: 1,408 solicitations, 1,362 of them carrying a NAMED
# AWARDED VENDOR, DHHS among the issuing departments. Maine publishes awarded
# vendors in a recognisable, machine-readable form at scale. NOT ONE ROW IS
# RHTP. The NEGATIVE CONTROL is in the same table -- "Small Rural Hospital
# Improvement Program (SHIP)", awarded, named vendor, DHHS, "Rural Hospital" in
# its title, and HRSA-funded rather than RHTP (§6.2's federal branch).
#
# CLI:
#   --fetch [--force]  archive the 13 sources + SHA-256 manifest
#   --validate         every assertion, offline
#   --build            write the four CSVs and the xlsx render
#   --probe            LIVE: has Maine awarded yet? (the four tripwires)
#   --report           what Maine has published, and what it has not
#
# Sessions: 33.

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(stringr)
  library(purrr)
  library(openxlsx)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_pdf_text.R"))
source(here::here("R", "utils_recipient_classification.R"))


# -- constants ----------------------------------------------------------------

ME_STATE        <- "ME"
ME_EVIDENCE_DIR <- here::here("data", "evidence", "ME")
ME_CSV          <- "data/reference/me_year1_awardees.csv"
ME_COHORT_CSV   <- "data/reference/me_rhef_cohort.csv"
ME_STATUS_CSV   <- "data/reference/me_year1_status.csv"
ME_DISPO_CSV    <- "data/reference/me_rcj_candidate_disposition.csv"
ME_XLSX         <- "ME_year1_awardees.xlsx"

# maine.gov answers the project's honest agent with HTTP 200 on every host used
# here, so §3's michigan.gov exception is not reached and must not be.
ME_USER_AGENT <- paste(
  "AHA-RHTP-Tracker/0.1 (+https://www.aha.org;",
  "contact: AHA Data and Policy; R httr2)"
)
ME_HOST_THROTTLE_S <- 3

ME_CREDENTIAL_SHAPES <- c(
  "Mapbox token"    = "\\b[ps]k\\.ey[A-Za-z0-9._-]{20,}",
  "Google API key"  = "\\bAIza[0-9A-Za-z_-]{30,}",
  "AWS access key"  = "\\bAKIA[0-9A-Z]{16}\\b"
)

ME_SOURCES <- tibble::tribble(
  ~key, ~file, ~url,

  "programme",
  "2026-09-02_me_dhhs_rhtp_programme.html",
  "https://www.maine.gov/dhhs/ruralhealth",

  "rhef",
  "2026-07-31_me_dhhs_rural_hospital_resiliency.html",
  paste0("https://www.maine.gov/dhhs/news/",
         "maine-dhhs-releases-30-million-strengthen-rural-hospital-",
         "resiliency-2026-07-31"),

  "une",
  "2026-07-31_me_dhhs_une_12m_partnership.html",
  paste0("https://www.maine.gov/dhhs/blog/",
         "maine-rural-health-transformation-program-announces-12m-partnership-",
         "university-new-england-expand-2026-07-31"),

  "emr",
  "2026-07-10_me_dhhs_emr_modernization.html",
  paste0("https://www.maine.gov/dhhs/news/",
         "maine-dhhs-announces-30-million-investment-help-health-care-",
         "providers-modernize-electronic-medical-2026-07-10"),

  "advisory_aug",
  "2026-08-05_me_rhtp_advisory_updates.pdf",
  paste0("https://www.maine.gov/dhhs/sites/maine.gov.dhhs/files/inline-files/",
         "20260805%20Advisory%20Updates_F.pdf"),

  "advisory_jul",
  "2026-07-01_me_rhtp_advisory_committee.pdf",
  paste0("https://www.maine.gov/dhhs/sites/maine.gov.dhhs/files/inline-files/",
         "20260701%20Maine%20RHTP%20Advisory%20Committee.pdf"),

  "doe",
  "2026-09-02_me_doe_healthcare_careers_exploration.html",
  "https://www.maine.gov/doe/pathways/healthcareexplorations",

  "mcd",
  "2026-09-02_mcd_global_health_maine_rhtp.html",
  "https://www.mcd.org/focus-areas/maine-rural-health-transformation-program",

  "governor",
  "2025-12-29_governor_mills_rhtp_award.html",
  paste0("https://www.maine.gov/governor/mills/news/",
         "governor-mills-statement-rural-health-transformation-program-award-",
         "2025-12-29"),

  "news_index",
  "2026-09-02_me_dhhs_news_index.html",
  "https://www.maine.gov/dhhs/news",

  "blog_index",
  "2026-09-02_me_dhhs_blog_index.html",
  "https://www.maine.gov/dhhs/blog",

  # THE POSITIVE CONTROL, and the NEGATIVE CONTROL inside it.
  "rfp_archive",
  "2026-09-02_me_procurement_rfp_archive.html",
  "https://www.maine.gov/dafs/bbm/procurementservices/vendors/rfps/rfp-archives",

  "rfa_current",
  "2026-09-02_me_procurement_grant_rfas.html",
  "https://www.maine.gov/dafs/bbm/procurementservices/vendors/grants"
)


# -- what MAINE states, so a change in the source fails rather than passes -----

# The §7.1 anchor has Maine at $190,008,051; every Maine footer prints
# $190,008,051.09, which is the same award to the cent.
ME_ALLOTMENT       <- 190008051.09
ME_ALLOTMENT_ROUND <- 190008051
ME_NOA_DATE        <- as.Date("2025-12-29")

ME_UNE_AMOUNT      <- 12000000
ME_RHEF_POOL       <- 30000000
ME_RHEF_PHASE1     <- 3000000
ME_RHEF_PHASE2     <- 27000000
ME_RHEF_COHORT_N   <- 11L
ME_EMR_POOL        <- 30000000
ME_APM_POOL        <- 28500000
ME_DOE_POOL        <- 500000
ME_DOE_MAX_AWARDS  <- 4L

# The THREE programme-scoped sentences, from THREE publishers. These, and NOT
# the CMS footer, are why this file's rows are RHTP (§6.2, session 27's audit).
ME_PROVENANCE <- list(
  rhef_is_rhtp = paste0(
    "$30 million in funding through Maine’s Rural Health Transformation ",
    "Program (RHTP)"),
  rhef_component = paste0(
    "The Rural Hospital Efficiency Fund is one component of Maine’s ",
    "broader Rural Health Transformation Program"),
  une_is_rhtp = paste0(
    "Maine has allocated $12 million for a comprehensive partnership with the ",
    "University of New England’s (UNE) Shaw Institute"),
  doe_is_rhtp = paste0(
    "Funding for this opportunity is made available through Maine’s ",
    "federal Rural Health Transformation Program award")
)

# The CMS financial-assistance footer. Its grammatical subject is "This
# PROGRAM" -- session 30's Wisconsin form, not session 27's strong form -- so it
# corroborates the AMOUNT and nothing else. It is on all four DHHS RHTP pages
# and on NEITHER the Maine DOE opportunity (which is RHTP and says so in its own
# words) nor the Governor's statement, so on this estate it is neither necessary
# nor sufficient. Note the UNE post's extra clause, which no other Maine
# document carries.
ME_FOOTER <- list(
  amount = paste0("financial assistance award totaling $190,008,051.09 with ",
                  "100 percent funded by CMS/HHS"),
  subject = "This program is supported by the Centers for Medicare",
  une_pending = "pending approval of revised budget"
)

# THE TRIPWIRE SENTENCES. Each one says, in the publisher's own words, that
# Maine has not yet awarded. Every one is asserted on every run and on every
# --probe; a sentence that goes is a signal, not a defect to be worked around.
ME_NOT_AWARDED <- list(
  rhef_invited = paste0(
    "Maine DHHS has identified and invited 11 rural hospitals to participate ",
    "in the initiative"),
  rhef_headline = paste0(
    "Eleven rural hospitals invited to receive funding and technical ",
    "assistance"),
  rhef_phase1 = paste0(
    "Approximately $3 million will be distributed among participating ",
    "hospitals"),
  rhef_phase2 = paste0(
    "Approximately $27 million will be available to support approved ",
    "hospital-identified efficiency projects"),
  emr_expected = paste0(
    "All eligible organizations that submit a qualifying application are ",
    "expected to receive an award"),
  doe_announcement = "Award Announcement: August 31, 2026",
  doe_up_to_four = "Maine DOE anticipates making up to four (4) awards"
)

# The same claim from the STATE'S OWN advisory deck, four days after the press
# release. This is the load-bearing evidence that the eleven are not awards.
ME_DECK_NOT_AWARDED <- c(
  "Eligible hospitals to participate in this cohort identified.",
  paste0("Award amount and approved budget will be confirmed after start of ",
         "participation in the HE Cohort"),
  "HE Cohort begins",
  "Funding approved and provided",
  "Provider contracts executed",
  "Payments issued"
)

# What a Maine award posting would look like. Deliberately SIX SPECIFIC FORMS
# and not the bare token "award" -- "Award Announcement", "awards", "Award
# amounts" are all already on the live pages in pre-award boilerplate, so a bare
# token fires every run (Missouri's lesson, session 29, measured not guessed).
ME_AWARD_POSTED <- c(
  "hospitals awarded",
  "awarded the following",
  "the following organizations were awarded",
  "award recipients",
  "awardees are",
  "has awarded the"
)

# The negative control INSIDE the positive control: a real, awarded, named
# vendor DHHS contract with "Rural Hospital" in its title that is HRSA's Small
# Rural Hospital Improvement Program and not RHTP.
ME_PROCUREMENT_NEGATIVE <- "Small Rural Hospital Improvement Program (SHIP)"
ME_PROCUREMENT_MIN_ROWS <- 1000L
ME_PROCUREMENT_MIN_AWARDED <- 1000L

# Titles a Maine RHTP procurement award would have to carry. If one appears in
# the archive, the archive has become an award channel and this file is wrong.
ME_PROCUREMENT_RHTP <- c("Rural Health Transformation", "RHTP")


# -- fetch --------------------------------------------------------------------

me_source <- function(key, field) {
  row <- ME_SOURCES[ME_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[ME] unknown source key: ", key, call. = FALSE)
  row[[field]]
}

me_path <- function(key) file.path(ME_EVIDENCE_DIR, me_source(key, "file"))

#' Refuse to archive anything carrying a credential (§7.1, sessions 14/16/17/20)
me_assert_credential_free <- function(body, label) {
  chunk <- body[seq_len(min(length(body), 4e6))]
  txt <- rawToChar(chunk[chunk != as.raw(0)])
  Encoding(txt) <- "latin1"
  for (nm in names(ME_CREDENTIAL_SHAPES)) {
    if (stringr::str_detect(txt, ME_CREDENTIAL_SHAPES[[nm]])) {
      stop("[ME] refusing to archive ", label, ": it carries what looks like ",
           "a ", nm, ".", call. = FALSE)
    }
  }
  invisible(TRUE)
}

me_get <- function(url, label) {
  message("[ME] fetching ", url)
  resp <- httr::GET(url, httr::user_agent(ME_USER_AGENT), httr::timeout(300))
  if (httr::status_code(resp) != 200L) {
    stop("[ME] HTTP ", httr::status_code(resp), " for ", url, call. = FALSE)
  }
  served <- httr::content(resp, as = "raw")
  me_assert_credential_free(served, label)
  served
}

me_fetch <- function(force = FALSE) {
  dir.create(ME_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  entries <- purrr::map_dfr(seq_len(nrow(ME_SOURCES)), function(i) {
    src <- ME_SOURCES[i, ]
    dest <- file.path(ME_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[ME] cached, not re-fetched: ", src$file)
    } else {
      if (i > 1L) Sys.sleep(ME_HOST_THROTTLE_S)
      writeBin(me_get(src$url, src$file), dest)
    }
    tibble::tibble(
      key = src$key, file = src$file, url = src$url,
      bytes = file.info(dest)$size,
      sha256 = digest::digest(file = dest, algo = "sha256")
    )
  })
  me_write_manifest(entries)
  entries
}

me_write_manifest <- function(entries) {
  path <- file.path(ME_EVIDENCE_DIR, "MANIFEST.txt")
  writeLines(c(
    "Maine -- RHTP Year 1. The state's RHTP programme page, its THREE RHTP",
    "announcements (two on the DHHS news index, one on the DHHS blog), the",
    "Maine DOE funding opportunity, the TWO RHTP Advisory Committee decks,",
    "MCD Global Health's own partner page, the Governor's 2025-12-29 statement,",
    "the two DHHS indexes that are the award-index control, and Maine's",
    "procurement archive, which is BOTH the positive control (1,362 named",
    "awarded vendors, none of them RHTP) and the negative control (HRSA's",
    "Small Rural Hospital Improvement Program, awarded, DHHS, with 'Rural",
    "Hospital' in its title).",
    "",
    "USER AGENT: the project's own honest agent, which every host here answers",
    "with HTTP 200. §3's michigan.gov exception is NOT reached and must not be.",
    "",
    "Every file is archived VERBATIM as served -- no reduction was needed,",
    "because none of the thirteen carries a credential shape (asserted before",
    "each write). The page digests are stable: two fetches of the programme",
    "page three seconds apart returned the SAME SHA-256, so unlike Nevada,",
    "Missouri and Wisconsin a file digest is a usable change test here.",
    "",
    format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    "",
    sprintf("%-14s %-58s %10s  %s", "KEY", "FILE", "BYTES", "SHA-256"),
    sprintf("%-14s %-58s %10s  %s", entries$key, entries$file, entries$bytes,
            entries$sha256),
    "",
    "URLs:",
    sprintf("  %-14s %s", entries$key, entries$url)
  ), path)
  message("[ME] manifest written: ", path)
  invisible(path)
}


# -- readers ------------------------------------------------------------------

me_read_raw <- function(key) {
  path <- me_path(key)
  if (!file.exists(path)) {
    stop("[ME] ", basename(path), " is not archived. Run --fetch.",
         call. = FALSE)
  }
  path
}

#' Squished visible text of an archived HTML source
me_html_text <- function(key, body = NULL) {
  doc <- if (is.null(body)) xml2::read_html(me_read_raw(key)) else
    xml2::read_html(body)
  xml2::xml_remove(xml2::xml_find_all(doc, "//script | //style"))
  stringr::str_squish(xml2::xml_text(doc))
}

me_pdf_cache <- new.env(parent = emptyenv())

me_pdf_text <- function(key) {
  if (is.null(me_pdf_cache[[key]])) {
    me_pdf_cache[[key]] <- stringr::str_squish(
      paste(rhtp_pdf_text(me_read_raw(key)), collapse = " "))
  }
  me_pdf_cache[[key]]
}


# -- the eleven, PARSED and never transcribed (§7.1) --------------------------

#' The Rural Hospital Efficiency Fund cohort, read out of the release's own list
#'
#' DHHS prints the eleven as a `<ul>` immediately after the sentence "The 11
#' hospitals invited to participate are:". The parser locates that list by the
#' sentence and REFUSES if the count is not eleven -- Georgia's device, and the
#' reason a re-issued release that added a twelfth hospital fails the build
#' rather than silently changing the finding.
me_rhef_cohort_names <- function(body = NULL) {
  doc <- if (is.null(body)) xml2::read_html(me_read_raw("rhef")) else
    xml2::read_html(body)
  xml2::xml_remove(xml2::xml_find_all(doc, "//script | //style"))

  anchor <- xml2::xml_find_first(
    doc, "//p[contains(., 'hospitals invited to participate are')]")
  if (inherits(anchor, "xml_missing")) {
    stop("[ME] the release no longer carries the sentence that introduces the ",
         "cohort list ('The 11 hospitals invited to participate are:'). The ",
         "list is located BY that sentence, so this is a source change and ",
         "not a parse failure.", call. = FALSE)
  }
  ul <- xml2::xml_find_first(anchor, "following::ul[1]")
  if (inherits(ul, "xml_missing")) {
    stop("[ME] no list follows the cohort sentence.", call. = FALSE)
  }
  names <- stringr::str_squish(
    xml2::xml_text(xml2::xml_find_all(ul, "./li")))
  names <- names[nzchar(names)]

  if (length(names) != ME_RHEF_COHORT_N) {
    stop("[ME] the cohort list holds ", length(names), " hospitals, not ",
         ME_RHEF_COHORT_N, ". DHHS states eleven in its own headline and in ",
         "the sentence above the list. A changed count is a CHANGED COHORT ",
         "and this file must be rewritten, not re-run.", call. = FALSE)
    }
  names
}


rhtp_me_allotment <- function() {
  row <- readr::read_csv(
    here::here("data", "reference", "cms_fy2026_allotments.csv"),
    show_col_types = FALSE, progress = FALSE)
  row <- row[row$state == ME_STATE, ]
  if (nrow(row) != 1L) {
    stop("[ME] the §7.1 allotment anchor does not carry exactly one ME row.",
         call. = FALSE)
  }
  row$fy2026_allotment[[1]]
}

# -- provenance (§6.2), with the footer NON-STRICT ----------------------------

#' Three programme-scoped sentences, from THREE publishers
#'
#' Session 27's audit: the axis is the footer's grammatical SUBJECT. Maine's
#' footer says "This PROGRAM is supported by", which is Wisconsin's weak form --
#' the identical sentence appears on a Maine DOE page describing a DOE award --
#' so it can corroborate an AMOUNT and never a provenance. These sentences take
#' the MONEY or the FUND as their subject, and they carry it instead.
me_assert_programme_provenance <- function(rhef = NULL, une = NULL,
                                           doe = NULL) {
  if (is.null(rhef)) rhef <- me_html_text("rhef")
  if (is.null(une))  une  <- me_html_text("une")
  if (is.null(doe))  doe  <- me_html_text("doe")

  checks <- list(
    rhef_is_rhtp   = rhef, rhef_component = rhef,
    une_is_rhtp    = une,  doe_is_rhtp    = doe
  )
  for (nm in names(checks)) {
    if (!stringr::str_detect(checks[[nm]],
                             stringr::fixed(ME_PROVENANCE[[nm]]))) {
      stop("[ME] the programme-scoped sentence '", nm, "' is gone. That ",
           "sentence, NOT the CMS footer, is why this file's rows are RHTP ",
           "(§6.2, session 27's audit).", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' The footer, KEPT AND DEMOTED (Kansas's shape, session 28)
#'
#' Non-strict by default: it returns NA with a message rather than throwing, so
#' a re-post that drops the boilerplate cannot hard-fail Maine for no reason --
#' and a future state whose ONLY evidence is a "this program" footer does not
#' pass the test Maine passes.
me_assert_footer_corroborates <- function(rhef = NULL, strict = FALSE) {
  if (is.null(rhef)) rhef <- me_html_text("rhef")
  ok <- stringr::str_detect(rhef, stringr::fixed(ME_FOOTER$amount))
  if (!ok) {
    msg <- paste0("[ME] the CMS financial-assistance footer's amount is not ",
                  "on the release. It corroborates the AMOUNT only; the ",
                  "provenance is carried by three programme-scoped sentences.")
    if (strict) stop(msg, call. = FALSE)
    message(msg); return(invisible(NA))
  }
  me_allot <- rhtp_me_allotment()
  if (!isTRUE(all.equal(round(ME_ALLOTMENT), as.numeric(me_allot)))) {
    stop("[ME] the footer's $", format(ME_ALLOTMENT, big.mark = ","),
         " does not round to the §7.1 anchor's ", me_allot, ".", call. = FALSE)
  }
  invisible(TRUE)
}

#' Every Maine RHTP document postdates the 2025-12-29 Notice of Award
#'
#' Read out of the Governor's own statement rather than typed, and checked
#' against `cms_state_noa_dates.csv`. Texas's HHS0015180 closed eight months
#' before its state had the money; this is the check that separates the two.
me_assert_after_noa <- function(gov = NULL) {
  if (is.null(gov)) gov <- me_html_text("governor")
  if (!stringr::str_detect(gov, stringr::fixed("December 29, 2025"))) {
    stop("[ME] the Governor's statement no longer carries its own date, which ",
         "is this file's independent reading of the NOA date.", call. = FALSE)
  }
  anchor <- readr::read_csv(here::here("data", "reference",
                                       "cms_state_noa_dates.csv"),
                            show_col_types = FALSE, progress = FALSE)
  noa <- as.Date(anchor$noa_date[anchor$state == "ME"])
  if (!identical(noa, ME_NOA_DATE)) {
    stop("[ME] the §6.2 anchor gives Maine's NOA as ", noa, ", not ",
         ME_NOA_DATE, ".", call. = FALSE)
  }
  # Every source in this file is dated 2026, after the NOA. The dates are in
  # the archived file names, which are derived from the documents themselves.
  dated <- stringr::str_extract(ME_SOURCES$file, "^\\d{4}-\\d{2}-\\d{2}")
  later <- as.Date(dated) > ME_NOA_DATE
  # the Governor's statement is the NOA announcement itself and is the one
  # source that does not postdate it.
  later[ME_SOURCES$key == "governor"] <-
    as.Date(dated[ME_SOURCES$key == "governor"]) == ME_NOA_DATE
  if (!all(later)) {
    stop("[ME] a source predates the Notice of Award: ",
         paste(ME_SOURCES$key[!later], collapse = ", "), call. = FALSE)
  }
  invisible(TRUE)
}


# -- THE TRIPWIRES ------------------------------------------------------------

#' The eleven hospitals are INVITED, NOT AWARDED -- and Maine says so twice
#'
#' DESIGNED TO FAIL. `me_rhef_cohort.csv` has no `amount` column and asserts
#' none, on the strength of these sentences. The day DHHS confirms an award
#' amount for the cohort, the eleven become award rows and the file must be
#' REWRITTEN rather than patched -- exactly as `mo_assert_anchors_not_awarded()`
#' is designed to fail for Missouri's Hub Anchors.
me_assert_cohort_not_awarded <- function(rhef = NULL, deck = NULL) {
  if (is.null(rhef)) rhef <- me_html_text("rhef")
  if (is.null(deck)) deck <- me_pdf_text("advisory_aug")

  for (nm in c("rhef_invited", "rhef_headline", "rhef_phase1", "rhef_phase2")) {
    if (!stringr::str_detect(rhef, stringr::fixed(ME_NOT_AWARDED[[nm]]))) {
      stop("[ME] the release no longer says '", nm, "'. THE ELEVEN HOSPITALS ",
           "ARE IN THIS REPOSITORY AS AN INVITED COHORT AND NOT AS ",
           "RECIPIENTS, and that sentence is why. Re-read the source before ",
           "changing anything.", call. = FALSE)
    }
  }
  for (s in ME_DECK_NOT_AWARDED[1:2]) {
    if (!stringr::str_detect(deck, stringr::fixed(s))) {
      stop("[ME] the 2026-08-05 advisory deck no longer says '", substr(s, 1, 50),
           "...'. That is the STATE'S OWN statement, five days after the press ",
           "release, that no award amount exists yet.", call. = FALSE)
    }
  }
  # And the release must NOT have acquired award language.
  hit <- ME_AWARD_POSTED[purrr::map_lgl(
    ME_AWARD_POSTED, ~ stringr::str_detect(tolower(rhef), stringr::fixed(.x)))]
  if (length(hit)) {
    stop("[ME] the Rural Hospital Efficiency Fund release now carries award ",
         "language (", paste(hit, collapse = "; "), "). THIS IS THE SIGNAL, ",
         "not a defect: rewrite me_rhef_cohort.csv as an award file.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' No per-hospital amount is published anywhere for the cohort
#'
#' The pool is $30M in two phases; DHHS divides it nowhere, and §6.2 forbids
#' this pipeline dividing it. `$3,000,000 / 11` is a number nobody published.
me_assert_no_per_hospital_amount <- function(rhef = NULL, deck = NULL) {
  if (is.null(rhef)) rhef <- me_html_text("rhef")
  if (is.null(deck)) deck <- me_pdf_text("advisory_aug")
  names <- me_rhef_cohort_names()

  # A per-hospital figure would put a dollar amount within 120 characters of a
  # cohort hospital's name. None does today.
  for (n in names) {
    at <- stringr::str_locate(rhef, stringr::fixed(n))
    if (is.na(at[1, 1])) next
    window <- substr(rhef, at[1, 1], min(nchar(rhef), at[1, 2] + 120))
    if (stringr::str_detect(window, "\\$[0-9][0-9,\\.]*")) {
      stop("[ME] a dollar figure now sits beside '", n, "'. Maine has begun ",
           "publishing per-hospital amounts and this file must be rewritten.",
           call. = FALSE)
    }
  }
  # And the deck's cohort slide still carries no roster in its text layer.
  if (any(purrr::map_lgl(names, ~ stringr::str_detect(deck, stringr::fixed(.x))))) {
    stop("[ME] the advisory deck now names a cohort hospital in its text ",
         "layer. Slide 15 ('RHEF Year 1 Cohort Mapped') was IMAGE-ONLY when ",
         "this file was written; re-read it.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The EMR, APM and DOE channels have not awarded either, and each has a DATE
#'
#' DOE's is the sharpest: its own RFA page prints "Award Announcement: August
#' 31, 2026", which was TWO DAYS BEFORE this file was written, and publishes no
#' roster. Wisconsin's shape, and Maine's is already overdue.
me_assert_channels_not_awarded <- function(emr = NULL, doe = NULL,
                                           mcd = NULL, deck = NULL) {
  if (is.null(emr))  emr  <- me_html_text("emr")
  if (is.null(doe))  doe  <- me_html_text("doe")
  if (is.null(mcd))  mcd  <- me_html_text("mcd")
  if (is.null(deck)) deck <- me_pdf_text("advisory_aug")

  if (!stringr::str_detect(emr, stringr::fixed(ME_NOT_AWARDED$emr_expected))) {
    stop("[ME] the EMR release no longer says applicants are 'expected to ",
         "receive an award' -- future tense is what makes it a solicitation.",
         call. = FALSE)
  }
  for (nm in c("doe_announcement", "doe_up_to_four")) {
    if (!stringr::str_detect(doe, stringr::fixed(ME_NOT_AWARDED[[nm]]))) {
      stop("[ME] Maine DOE's page no longer carries '", nm, "'. Its award ",
           "announcement date is what dates this negative.", call. = FALSE)
    }
  }
  # DOE's page must not have acquired a roster: up to four awards of $125,000.
  if (any(purrr::map_lgl(ME_AWARD_POSTED,
                         ~ stringr::str_detect(tolower(doe), stringr::fixed(.x))))) {
    stop("[ME] Maine DOE's Healthcare Careers Exploration page now carries ",
         "award language. Its announcement date (August 31, 2026) has passed ",
         "-- THIS IS THE SIGNAL. Read the roster and extend this file.",
         call. = FALSE)
  }
  # MCD, the designated pass-through administrator (§7, Illinois/ICAHN), says
  # the same thing from a second host.
  if (!stringr::str_detect(mcd, stringr::fixed("APPLICATIONS CLOSED"))) {
    stop("[ME] MCD Global Health's page no longer says APPLICATIONS CLOSED ",
         "for the EMR Modernization Funds. It is the SECOND publisher of the ",
         "EMR channel's pre-award state.", call. = FALSE)
  }
  # The deck's own milestones put every payment in the future.
  for (s in ME_DECK_NOT_AWARDED[3:6]) {
    if (!stringr::str_detect(deck, stringr::fixed(s))) {
      stop("[ME] the advisory deck no longer carries the milestone '", s,
           "'. Those milestones are what date every Maine negative.",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}


# -- the controls -------------------------------------------------------------

#' Maine's procurement archive, read table by table and COLUMN BY HEADER
#'
#' THE PAGE CARRIES TWO TABLES WHOSE COLUMN ORDERS DIFFER. The first, 250 rows,
#' is headed "Title | RFP # | ..."; the second, 1,158 rows, is headed
#' "RFP # | RFP Title | ...". A positional reader that resolved columns once for
#' the page reads 1,158 titles as solicitation numbers and finds no RHTP row --
#' and finds no negative control either, which is how this was caught. Columns
#' are therefore resolved BY SYNONYM against each table's OWN header row
#' (session 10's rule), and a table whose header cannot be resolved is REFUSED
#' rather than read positionally.
ME_PROCUREMENT_COLS <- list(
  title   = c("rfp title", "title"),
  number  = c("rfp #", "rfp number"),
  dept    = c("issuing department", "issuing dept.", "issuing dept"),
  posted  = c("date posted"),
  status  = c("rfp status", "status"),
  awarded = c("awarded vendor(s)", "awarded vendor")
)

me_procurement_rows <- function(body = NULL) {
  doc <- if (is.null(body)) xml2::read_html(me_read_raw("rfp_archive")) else
    xml2::read_html(body)
  tables <- xml2::xml_find_all(doc, "//table")
  if (!length(tables)) {
    stop("[ME] the procurement archive holds no table at all.", call. = FALSE)
  }

  out <- purrr::map_dfr(seq_along(tables), function(ti) {
    rows <- xml2::xml_find_all(tables[[ti]], ".//tr")
    if (length(rows) < 2L) return(NULL)
    cells <- function(r) stringr::str_squish(
      xml2::xml_text(xml2::xml_find_all(r, "./td | ./th")))

    hdr <- tolower(cells(rows[[1]]))
    idx <- purrr::map_int(ME_PROCUREMENT_COLS, function(syn) {
      hit <- which(hdr %in% syn)
      if (length(hit)) hit[[1]] else NA_integer_
    })
    if (anyNA(idx)) {
      stop("[ME] table ", ti, " of the procurement archive has a header this ",
           "file cannot resolve (", paste(hdr, collapse = " | "), "). ",
           "REFUSING rather than reading it positionally: the two tables on ",
           "this page carry DIFFERENT column orders, and a positional read ",
           "silently swaps title with solicitation number.", call. = FALSE)
    }

    purrr::map_dfr(rows[-1], function(r) {
      c_ <- cells(r)
      if (length(c_) < max(idx)) return(NULL)
      tibble::tibble(
        table = ti,
        title = c_[[idx[["title"]]]], number = c_[[idx[["number"]]]],
        dept = c_[[idx[["dept"]]]], posted = c_[[idx[["posted"]]]],
        status = c_[[idx[["status"]]]], awarded = c_[[idx[["awarded"]]]]
      )
    })
  })
  out
}

#' THE POSITIVE CONTROL, and the NEGATIVE CONTROL inside the same table
#'
#' Maine's RFP archive is the largest control this project has used: over a
#' thousand solicitations, over a thousand of them carrying a NAMED AWARDED
#' VENDOR, with DHHS among the issuing departments. So "no RHTP award row" is a
#' statement about MAINE and not about our reading. And the negative control is
#' three rows down the same column: HRSA's Small Rural Hospital Improvement
#' Program, awarded, DHHS, "Rural Hospital" in its title, and NOT RHTP -- which
#' is what a title-keyed reader would take.
me_assert_procurement_control <- function(rows = NULL) {
  if (is.null(rows)) rows <- me_procurement_rows()

  if (nrow(rows) < ME_PROCUREMENT_MIN_ROWS) {
    stop("[ME] the procurement archive holds ", nrow(rows), " rows, under the ",
         ME_PROCUREMENT_MIN_ROWS, " this control needs. Without it, 'no RHTP ",
         "award' is indistinguishable from 'we are reading the wrong page'.",
         call. = FALSE)
  }
  named <- sum(nzchar(rows$awarded) &
                 !rows$awarded %in% c("N/A", "Awarded Vendor(s)"))
  if (named < ME_PROCUREMENT_MIN_AWARDED) {
    stop("[ME] only ", named, " archive rows name an awarded vendor. The ",
         "control is that Maine publishes awarded vendors AT SCALE.",
         call. = FALSE)
  }
  if (!any(stringr::str_detect(rows$title,
                               stringr::fixed(ME_PROCUREMENT_NEGATIVE)))) {
    stop("[ME] the NEGATIVE CONTROL is gone: '", ME_PROCUREMENT_NEGATIVE,
         "' is an awarded DHHS contract with 'Rural Hospital' in its title ",
         "that is HRSA-funded and not RHTP. It is what a title-keyed reader ",
         "would wrongly take.", call. = FALSE)
  }
  hit <- rows[purrr::map_lgl(rows$title, function(t) {
    any(purrr::map_lgl(ME_PROCUREMENT_RHTP,
                       ~ stringr::str_detect(t, stringr::fixed(.x))))
  }), ]
  if (nrow(hit)) {
    stop("[ME] Maine's procurement archive now carries an RHTP-titled row (",
         paste(hit$title, collapse = "; "), "). THIS IS THE SIGNAL: Maine's ",
         "award channel may be procurement (Indiana's sixth question) and ",
         "this file must be extended.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The award-index control: DHHS's two publication channels, and what is on them
#'
#' DHHS publishes RHTP announcements on exactly two indexes -- /dhhs/news and
#' /dhhs/blog -- and the UNE partnership is on the BLOG, not the news index. A
#' hunt that read only the news index would have missed Maine's only priced
#' award. Both indexes are asserted present and carrying the items this file
#' reads; a THIRD RHTP item on either is new and must be read.
me_assert_award_index <- function(news = NULL, blog = NULL) {
  if (is.null(news)) news <- me_html_text("news_index")
  if (is.null(blog)) blog <- me_html_text("blog_index")

  news_items <- c(
    "Maine DHHS Releases $30 Million to Strengthen Rural Hospital Resiliency",
    paste0("Maine DHHS Announces $30 Million Investment to Help Health Care ",
           "Providers Modernize Electronic Medical Record"))
  blog_items <- c(
    paste0("Maine Rural Health Transformation Program Announces $12M ",
           "Partnership with University of New England"))

  for (s in news_items) {
    if (!stringr::str_detect(news, stringr::fixed(s))) {
      stop("[ME] the DHHS news index no longer lists '", substr(s, 1, 48),
           "...'.", call. = FALSE)
    }
  }
  for (s in blog_items) {
    if (!stringr::str_detect(blog, stringr::fixed(s))) {
      stop("[ME] the DHHS blog index no longer lists '", substr(s, 1, 48),
           "...'. MAINE'S ONLY PRICED AWARD IS ANNOUNCED ON THE BLOG AND NOT ",
           "ON THE NEWS INDEX -- reading one channel is how it gets missed.",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}


# -- the award file: ONE ROW --------------------------------------------------

#' Maine's only evidenced RHTP award action
#'
#' The University of New England's Shaw Institute, $12,000,000, announced by
#' DHHS on its own blog and independently reported by Maine Public. It is a
#' UNIVERSITY, and the subrecipients UNE will establish agreements with are
#' named as a CLASS and are not hospitals -- "organizations in Maine's Public
#' Health Districts and ... each Tribal Health Center". So the eligible class is
#' stated and it is not hospitals: Missouri's MEMSA coding, NON_HOSPITAL, and
#' NOT Illinois's or New Hampshire's unresolved pass-through.
#'
#' `amount_confirmed` is No. DHHS's word is "ALLOCATED", the footer on this post
#' alone adds "pending approval of revised budget", and no execution date is
#' published.
rhtp_me_year1_awardees <- function() {
  une_url <- me_source("une", "url")
  tibble::tibble(
    state = "ME",
    row_no = 1L,
    awardee = "University of New England (Shaw Institute for Public and Planetary Health)",
    amount = ME_UNE_AMOUNT,
    recipient_type = "UNIVERSITY_OR_AHC",
    distributed_to_hospital = "No",
    note = paste0(
      "Initiative One: Population Health. DHHS: 'Maine has allocated $12 ",
      "million for a comprehensive partnership with the University of New ",
      "England's (UNE) Shaw Institute for Public and Planetary Health.' UNE ",
      "will expand community health workers across Maine's nine Public Health ",
      "Districts and five Tribal Health Centers, and integrate evidence-based ",
      "practices. IT IS A PASS-THROUGH WHOSE SUBRECIPIENT CLASS IS STATED AND ",
      "IS NOT HOSPITALS: 'UNE will provide this support by establishing ",
      "subrecipient agreements with organizations in Maine's Public Health ",
      "Districts and with each Tribal Health Center.' No subrecipient is ",
      "named; UNE's own solicitation for evidence-based activity proposals ",
      "'will be published' and its timeline 'shared once finalized'. The ",
      "'Hospital to Home' programme UNE will manage is a PROGRAMME NAME, not ",
      "a recipient (§0.3a)."),
    recipient_confirmed = "Yes",
    amount_confirmed = "No",
    fiscal_year = "FY2026",
    source_document_title = paste0(
      "Maine Rural Health Transformation Program Announces $12M Partnership ",
      "with University of New England to Expand Rural Health Initiatives"),
    state_source_url = une_url,
    validation_source_type = "AGENCY_PRESS_RELEASE",
    extraction_method = "MODEL_ASSISTED",
    validator = "AI-assisted - CONFIRM",
    ccn = NA_character_,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    round_amount = NA_real_,
    recipient_type_source = paste0(
      "Stated in the source: 'the University of New England's (UNE) Shaw ",
      "Institute for Public and Planetary Health'. §8 UNIVERSITY_OR_AHC, ",
      "which is Oregon's OHSU convention."),
    determination_confidence = "MEDIUM",
    flag_reason = "AMOUNT_PRELIMINARY;SUBAWARD_PROCESS_NOT_YET_RUN",
    flow_type = "NON_HOSPITAL",
    intermediary_name = NA_character_,
    hospital_attribution = "NOT_HOSPITAL",
    hospital_benefiting = "Unclear",
    determination_basis = paste0(
      "§10.2 NON_HOSPITAL on the recipient, not the activity (§0.3a): the ",
      "recipient is a university. It is also a pass-through, and the reason ",
      "it is not PASS_THROUGH_UNRESOLVED is that DHHS STATES the subrecipient ",
      "class -- 'organizations in Maine's Public Health Districts and ... ",
      "each Tribal Health Center' -- and that class contains no hospital. ",
      "That is Missouri's MEMSA coding (an eligible class stated, and not ",
      "hospitals), NOT New Hampshire's FHC, whose class named critical access ",
      "hospitals among others and is therefore Unclear. `hospital_benefiting` ",
      "is Unclear rather than No because one named activity -- the Hospital ",
      "to Home Social Needs Screening and Support programme -- is aimed at ",
      "preventing rehospitalisation, and DHHS does not say whether a hospital ",
      "receives anything for it."),
    amount_basis = paste0(
      "STATED, ROUND: DHHS's own '$12 million', matching RCJ's $12,000,000 ",
      "exactly -- the only Maine row where the aggregator's figure is ",
      "corroborated by a primary source. Maine Public independently reported ",
      "it as a '$12 million grant' on 2026-08-04. It is an ALLOCATION to a ",
      "named partnership, not an executed award: this post's CMS footer, ",
      "uniquely among Maine's three, adds 'pending approval of revised ",
      "budget', and no execution date is published."),
    amount_precision = "ROUND",
    disbursement_status = "ALLOCATED_PENDING_BUDGET_APPROVAL",
    initiative = "Initiative 1: Population Health",
    award_pool = "UNE Population Health Partnership",
    classification_rule = "ME_UNE_UNIVERSITY_PASS_THROUGH_NON_HOSPITAL",
    source_archive_path = file.path("data", "evidence", "ME",
                                    me_source("une", "file"))
  )
}


# -- the cohort file: ELEVEN HOSPITALS AND NO `amount` COLUMN -----------------

#' The Rural Hospital Efficiency Fund cohort. NOT AN AWARD FILE.
#'
#' Missouri's `mo_hub_anchors.csv` device, and Maine's case is sharper: all
#' eleven are hospitals, the fund is hospitals-only, and $30M has been
#' "released" for them. What has NOT happened is any award: DHHS "identified and
#' invited" the eleven, and its own advisory deck says the "award amount and
#' approved budget will be confirmed AFTER START OF PARTICIPATION".
#'
#' There is deliberately NO `amount` COLUMN, and `me_assert_cohort_no_amount()`
#' refuses one. Eleven named hospitals with a $30M pool beside them is the most
#' publishable-looking non-award this project has met.
rhtp_me_rhef_cohort <- function(names = NULL) {
  if (is.null(names)) names <- me_rhef_cohort_names()
  types <- rhtp_classify_recipient_type(names, "ME")

  tibble::tibble(
    state = "ME",
    row_no = seq_along(names),
    organization = names,
    recipient_type = types$recipient_type,
    recipient_type_confidence = types$determination_confidence,
    is_hospital_or_system = types$recipient_type == "HOSPITAL_OR_SYSTEM",
    invitation_date = as.Date("2026-07-31"),
    award_made = "No",
    amount_published = "No",
    agreement_executed = "No",
    role = paste0(
      "Invited participant in the Rural Hospital Efficiency Fund cohort. DHHS ",
      "'identified and invited' the eleven from an analysis of Maine Health ",
      "Data Organization financial data; they did not apply."),
    note = paste0(
      "AN INVITED COHORT, NOT AN AWARD (§0.3). DHHS's sub-headline is 'Eleven ",
      "rural hospitals INVITED TO RECEIVE funding and technical assistance'. ",
      "The State's own RHTP Advisory Committee deck of 2026-08-05 says ",
      "'Eligible hospitals to participate in this cohort identified' and ",
      "'Award amount and approved budget will be confirmed AFTER START OF ",
      "PARTICIPATION in the HE Cohort', against a timeline whose 'HE Cohort ",
      "begins' milestone is SEPTEMBER and whose 'Funding approved and ",
      "provided' milestone is FALL/WINTER. The $30M pool is published in two ",
      "phases -- ~$3M 'distributed among participating hospitals' for staff ",
      "time and ~$27M 'available to support APPROVED hospital-identified ",
      "efficiency projects' -- and DHHS divides neither. RCJ carries all ",
      "eleven as Tier 3 awards at $1 each."),
    source_document_title = paste0(
      "Maine DHHS Releases $30 Million to Strengthen Rural Hospital ",
      "Resiliency"),
    state_source_url = me_source("rhef", "url"),
    source_archive_path = file.path("data", "evidence", "ME",
                                    me_source("rhef", "file"))
  )
}

#' `me_rhef_cohort.csv` must never acquire an amount column
me_assert_cohort_no_amount <- function(cohort = NULL) {
  if (is.null(cohort)) cohort <- rhtp_me_rhef_cohort()
  bad <- grep("amount|dollar|\\$|round_amount", names(cohort),
              ignore.case = TRUE, value = TRUE)
  bad <- setdiff(bad, "amount_published")
  if (length(bad)) {
    stop("[ME] me_rhef_cohort.csv has grown an amount column (",
         paste(bad, collapse = ", "), "). It is NOT an award file. Maine ",
         "publishes no per-hospital figure and §6.2 forbids dividing the ",
         "$30M pool.", call. = FALSE)
  }
  if (file.exists(here::here(ME_COHORT_CSV))) {
    hdr <- names(readr::read_csv(here::here(ME_COHORT_CSV), n_max = 0,
                                 show_col_types = FALSE, progress = FALSE))
    bad <- setdiff(grep("amount", hdr, ignore.case = TRUE, value = TRUE),
                   "amount_published")
    if (length(bad)) {
      stop("[ME] the committed cohort CSV carries ",
           paste(bad, collapse = ", "), ".", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' THE ROW-COUNT / DOLLAR PAIRING, INVERTED
#'
#' Nevada and Iowa publish named hospitals with no amounts, so the danger is
#' reporting `dollars = 0` without `rows = 20` or `rows = 152`. MAINE IS THE
#' OPPOSITE CASE AND NEEDS THE OPPOSITE GUARD: it has ELEVEN NAMED HOSPITALS
#' AND ZERO HOSPITAL AWARD ROWS, and the mistake is counting them. This asserts
#' both halves at once -- that the award file contributes no named-hospital row
#' and no named-hospital dollar, and that eleven named hospitals nevertheless
#' exist in this repository, in a file that is not an award file.
me_assert_named_hospitals_are_not_recipients <- function(awards = NULL,
                                                         cohort = NULL) {
  if (is.null(awards)) awards <- rhtp_me_year1_awardees()
  if (is.null(cohort)) cohort <- rhtp_me_rhef_cohort()

  # The partition returns `bucket`, and for Maine it returns ZERO ROWS -- its
  # one award action is NOT_HOSPITAL and the partition drops that bucket. A
  # zero-row partition is the correct answer here and must not be read as a
  # failure to compute one.
  part <- rhtp_hospital_dollar_partition(awards)
  named <- part[!is.na(part$bucket) & part$bucket == "NAMED_HOSPITAL", ]
  rows <- if (nrow(named)) sum(named$rows) else 0L
  dollars <- if (nrow(named)) sum(named$dollars) else 0
  if (nrow(part) != 0L) {
    stop("[ME] the hospital partition now returns ", nrow(part), " bucket(s) ",
         "for Maine (", paste(part$bucket, collapse = ", "), "). It returned ",
         "NONE: Maine's only award action is to a university.", call. = FALSE)
  }
  if (rows != 0L || dollars != 0) {
    stop("[ME] Maine's award file now reports ", rows, " named-hospital rows ",
         "and $", format(dollars, big.mark = ",", scientific = FALSE), ". It held ZERO of each: ",
         "its one award action is to a university.", call. = FALSE)
  }
  n_hosp <- sum(cohort$is_hospital_or_system)
  if (n_hosp != ME_RHEF_COHORT_N) {
    stop("[ME] the cohort holds ", n_hosp, " hospitals of ", nrow(cohort),
         " rows, not ", ME_RHEF_COHORT_N, ". ALL ELEVEN ARE HOSPITALS, and ",
         "that is the whole reason this file needs the guard it has: a reader ",
         "who counts them has invented eleven hospital awards.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- the status table: NO `amount` COLUMN ------------------------------------

rhtp_me_year1_status <- function() {
  tibble::tribble(
    ~channel, ~administrator, ~initiative, ~stated_pool, ~stage,
    ~eligible_class, ~publishes_roster, ~evidence,

    "EMR Modernization", "Maine DHHS / MCD Global Health",
    "Initiative 3: Technology & Innovation",
    "approximately $30 million in Year 1 funding",
    "CLOSED_UNAWARDED",
    paste0("Critical Access Hospitals and general hospitals with a dedicated ",
           "emergency department; hospital-owned primary care practices and ",
           "RHCs; FQHCs and look-alikes; independent RHCs; independent rural ",
           "primary care practices; CCBHCs; OTPs. HOSPITALS AMONG OTHERS."),
    "No",
    paste0("'All eligible organizations that submit a qualifying application ",
           "are EXPECTED TO RECEIVE an award' -- future tense, and §0.3 ",
           "exactly. The advisory deck of 2026-08-05 identifies '~70 eligible ",
           "ownership organizations with ~330 sites' and puts 'Provider ",
           "contracts executed' in FALL. MCD, the contracted partner running ",
           "the portal, shows 'APPLICATIONS CLOSED 8/14' and 'COMING SOON'."),

    "APM Transition", "Maine DHHS (Office of MaineCare Services)",
    "Initiative 5: Sustainable Rural Health Ecosystems",
    "$28.5 million to support the transition to alternative payment models",
    "CLOSED_UNAWARDED",
    paste0("Acute care hospitals including hospital-owned primary care ",
           "practices; FQHCs; CCBHCs. HOSPITALS AMONG OTHERS."),
    "No",
    paste0("The advisory deck identifies '58 eligible ownership ",
           "organizations', puts applications due LATE AUGUST and 'Payments ",
           "issued' SEPTEMBER/OCTOBER. No recipient is named anywhere and no ",
           "press release has been issued for this channel at all."),

    "Rural Hospital Efficiency Fund", "Maine DHHS / Office of Affordable Health Care",
    "Initiative 5: Sustainable Rural Health Ecosystems",
    "$30 million, in two phases of approximately $3M and $27M",
    "COHORT_INVITED_UNAWARDED",
    paste0("HOSPITALS ONLY, AND NAMED: eleven rural hospitals identified and ",
           "invited by DHHS from Maine Health Data Organization financial ",
           "data. See me_rhef_cohort.csv -- WHICH IS NOT AN AWARD FILE."),
    "Named cohort, no award",
    paste0("'Eleven rural hospitals INVITED TO RECEIVE funding and technical ",
           "assistance'. The advisory deck: 'Award amount and approved budget ",
           "will be confirmed AFTER START OF PARTICIPATION in the HE Cohort'; ",
           "'HE Cohort begins' SEPTEMBER, 'Funding approved and provided' ",
           "FALL/WINTER. THIS IS THE HIGHEST-VALUE HOSPITAL ROW IN MAINE AND ",
           "IT IS WORTH $0 TODAY."),

    "Healthcare Careers Exploration", "Maine DOE (with Maine DHHS)",
    "Initiative 2: Workforce",
    "$500,000 total, up to four awards of $125,000",
    "CLOSED_AWARD_DATE_PASSED",
    paste0("'eligible organizations' developing grades 9-12 healthcare career ",
           "pipeline programming. Not hospitals (§0.3a: judge the recipient)."),
    "No",
    paste0("Maine DOE's own RFA page prints 'Award Announcement: August 31, ",
           "2026' -- TWO DAYS BEFORE this file was written -- and publishes ",
           "no roster. Applications were due 2026-08-04 through the State's ",
           "Vendor Self Service System. THIS IS THE MOST OVERDUE NEGATIVE IN ",
           "THE FILE and the first thing to re-probe."),

    "UNE Population Health Partnership", "Maine DHHS / University of New England",
    "Initiative 1: Population Health",
    "$12 million allocated",
    "PARTNER_NAMED_SUBAWARDS_PENDING",
    paste0("UNE's stated subrecipients are 'organizations in Maine's Public ",
           "Health Districts and ... each Tribal Health Center'. NOT ",
           "HOSPITALS."),
    "No",
    paste0("The only Maine RHTP row with a named recipient AND an amount, and ",
           "it is in me_year1_awardees.csv. UNE has named no subrecipient: ",
           "'An online solicitation for evidence-based activity proposals ",
           "will be published by UNE, and the timeline will be shared once ",
           "finalized.'"),

    "State procurement (Vendor Self Service)", "Maine DAFS Office of State Procurement",
    "n/a -- a CHANNEL, not an initiative",
    "n/a",
    "UNREADABLE",
    "n/a",
    "UNKNOWN",
    paste0("Maine's published RFP archive is this file's POSITIVE CONTROL: ",
           "1,408 solicitations, 1,362 with a NAMED AWARDED VENDOR, DHHS ",
           "among the issuers, and NOT ONE RHTP row. But its most recent ",
           "parsed posting date is 2025-10-08, and Maine's 2026 solicitations ",
           "route through the CGI Advantage Vendor Self Service portal, which ",
           "answers HTTP 200 but is a stateful JavaScript application this ",
           "environment cannot search. WHETHER A 2026 RHTP CONTRACT HAS BEEN ",
           "EXECUTED THERE IS UNKNOWN TO THIS REPOSITORY, WHICH IS A ",
           "STATEMENT ABOUT OUR ACCESS AND NOT ABOUT MAINE (§0.4).")
  ) %>%
    dplyr::mutate(state = "ME", .before = 1)
}

me_assert_status_no_amount <- function(status = NULL) {
  if (is.null(status)) status <- rhtp_me_year1_status()
  bad <- setdiff(grep("amount", names(status), ignore.case = TRUE, value = TRUE),
                 character(0))
  if (length(bad)) {
    stop("[ME] me_year1_status.csv has grown an amount column (",
         paste(bad, collapse = ", "), "). Texas's device: a status table with ",
         "an amount column can be summed into a Maine hospital dollar that ",
         "does not exist.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- §0.1: what RCJ carries ---------------------------------------------------

me_rcj_candidates <- function() {
  rt <- readRDS(here::here("data", "interim", "stage2_record_table.rds"))
  rt %>% dplyr::filter(state == "ME", award_tier == "SUBAWARD",
                       is.na(superseded_by))
}

#' Why each of RCJ's Maine Tier 3 candidates is, or is not, an award row
#'
#' The counts are RE-DERIVED from the record table on every run (Texas's rule).
rhtp_me_rcj_disposition <- function(cands = NULL) {
  if (is.null(cands)) cands <- me_rcj_candidates()
  nm <- cands$awardee_name_clean
  cohort <- me_rhef_cohort_names()
  norm <- function(x) stringr::str_squish(stringr::str_replace_all(x, "[‐-―]", "-"))

  is_cohort <- norm(nm) %in% norm(cohort)
  is_une    <- stringr::str_detect(nm, "University of New England")
  is_other  <- !(is_cohort | is_une)

  tibble::tribble(
    ~group, ~rows, ~disposition, ~why,

    "The Rural Hospital Efficiency Fund cohort -- ELEVEN NAMED HOSPITALS, AND NOT AWARDS",
    sum(is_cohort),
    "RHTP_COHORT_INVITED_NOT_AWARDED",
    paste0(
      "All eleven are real, named Maine rural hospitals, all eleven are in ",
      "DHHS's own 2026-07-31 release, and RCJ carries every one at an amount ",
      "of $1. THE NAMES ARE EXACTLY RIGHT -- they match DHHS's roster NAME ",
      "FOR NAME, eleven of eleven, once an en dash is normalised, which is ",
      "this file's only independent reading of the parse. WHAT IS WRONG IS ",
      "THE KIND OF ACTION: DHHS 'identified and invited' them, its own ",
      "advisory deck says the 'award amount and approved budget will be ",
      "confirmed after start of participation', and the funding milestone is ",
      "FALL/WINTER. This is MISSOURI'S DEFECT A SECOND TIME -- the wrong KIND ",
      "of action, published as a $1 placeholder so no amount check can see it ",
      "-- and it is worse here, because in Missouri 14 of 27 roster rows were ",
      "hospitals and in Maine ELEVEN OF ELEVEN are. An extractor built from ",
      "this candidate list would have published eleven named Maine hospitals ",
      "as RHTP recipients on the strength of a $1 figure."),

    "University of New England -- a real award, and RCJ prices it CORRECTLY",
    sum(is_une),
    "RHTP_AWARD_CARRIED_CORRECTLY",
    paste0(
      "RCJ carries $12,000,000, which is DHHS's own '$12 million' exactly. It ",
      "is the ONE Maine candidate that is an award action this repository can ",
      "evidence, it is in me_year1_awardees.csv at the state's figure, and it ",
      "is a UNIVERSITY -- so Maine's named-hospital dollars are $0. RCJ's ",
      "source-document title for it is truncated mid-sentence ('...University ",
      "of New England to Expand'), and the document is on the DHHS BLOG, not ",
      "the news index."),

    "Anything else",
    sum(is_other),
    "NONE",
    paste0(
      "Maine's candidate set is unusually clean: twelve rows, eleven of one ",
      "roster and one real award, with no Medicaid rows, no state ",
      "appropriations and no unrelated procurement. The §6.2 sweep catches ",
      "ZERO Maine rows and all twelve are undatable -- RCJ carries no date ",
      "for any of them -- so the sweep's clean line here is a statement about ",
      "the registry's coverage and not about Maine (Nebraska's lesson).")
  ) %>%
    dplyr::mutate(state = "ME", .before = 1)
}

#' RCJ's eleven names match DHHS's roster NAME FOR NAME
#'
#' The only independent reading this file has of the cohort list, and the same
#' device Iowa used in session 32. It is asserted, not observed in passing.
me_assert_rcj_names_match <- function(cands = NULL) {
  if (is.null(cands)) cands <- me_rcj_candidates()
  norm <- function(x) stringr::str_squish(stringr::str_replace_all(x, "[‐-―]", "-"))
  cohort <- norm(me_rhef_cohort_names())
  rcj <- norm(cands$awardee_name_clean)
  missed <- setdiff(cohort, rcj)
  if (length(missed)) {
    stop("[ME] RCJ no longer carries ", length(missed), " of the eleven ",
         "cohort hospitals (", paste(missed, collapse = "; "), "). That ",
         "match is this file's only independent reading of the roster parse.",
         call. = FALSE)
  }
  invisible(TRUE)
}


# -- reconcile, assert, build, report ----------------------------------------

rhtp_me_reconcile <- function(awards = NULL, cohort = NULL) {
  if (is.null(awards)) awards <- rhtp_me_year1_awardees()
  if (is.null(cohort)) cohort <- rhtp_me_rhef_cohort()
  me_allot <- rhtp_me_allotment()
  pools <- ME_EMR_POOL + ME_APM_POOL + ME_RHEF_POOL + ME_DOE_POOL + ME_UNE_AMOUNT
  list(
    award_rows        = nrow(awards),
    award_total       = sum(awards$amount, na.rm = TRUE),
    cohort_rows       = nrow(cohort),
    cohort_hospitals  = sum(cohort$is_hospital_or_system),
    named_hospital_rows = 0L,
    named_hospital_dollars = 0,
    announced_pools   = pools,
    cms_allotment     = me_allot,
    pools_share       = pools / me_allot,
    awarded_share     = sum(awards$amount, na.rm = TRUE) / me_allot
  )
}

rhtp_me_assert <- function(strict_footer = FALSE) {
  awards <- rhtp_me_year1_awardees()
  cohort <- rhtp_me_rhef_cohort()
  status <- rhtp_me_year1_status()

  me_assert_programme_provenance()
  me_assert_footer_corroborates(strict = strict_footer)
  me_assert_after_noa()
  me_assert_cohort_not_awarded()
  me_assert_no_per_hospital_amount()
  me_assert_channels_not_awarded()
  me_assert_award_index()
  me_assert_procurement_control()
  me_assert_cohort_no_amount(cohort)
  me_assert_status_no_amount(status)
  me_assert_named_hospitals_are_not_recipients(awards, cohort)
  me_assert_rcj_names_match()

  # §8 vocabulary, from both sides.
  stopifnot(all(awards$recipient_type %in% rhtp_vocabulary("recipient_type")))
  stopifnot(all(awards$flow_type %in% rhtp_vocabulary("flow_type")))
  stopifnot(all(awards$hospital_attribution %in%
                  rhtp_vocabulary("hospital_attribution")))
  stopifnot(all(awards$distributed_to_hospital %in%
                  rhtp_vocabulary("distributed_to_hospital")))
  flags <- unlist(strsplit(stats::na.omit(awards$flag_reason), ";"))
  stopifnot(all(flags %in% rhtp_vocabulary("flag_reason")))
  stopifnot(all(nzchar(awards$determination_basis)))

  # An award file this repository must never grow by accident: Maine's only
  # priced row is a university, so no Maine row may be a hospital.
  stopifnot(!any(awards$recipient_type == "HOSPITAL_OR_SYSTEM"))
  message("[ME] all assertions pass.")
  invisible(TRUE)
}

me_write_csv <- function(df, path) {
  readr::write_csv(df, here::here(path), na = "")
  message("[ME] wrote ", path, " (", nrow(df), " rows)")
}

rhtp_me_build <- function() {
  awards <- rhtp_me_year1_awardees()
  cohort <- rhtp_me_rhef_cohort()
  status <- rhtp_me_year1_status()
  dispo  <- rhtp_me_rcj_disposition()

  rhtp_me_assert()

  me_write_csv(awards, ME_CSV)
  me_write_csv(cohort, ME_COHORT_CSV)
  me_write_csv(status, ME_STATUS_CSV)
  me_write_csv(dispo,  ME_DISPO_CSV)
  rhtp_me_write_xlsx(awards, cohort, status, dispo)
  invisible(TRUE)
}

#' The workbook, whose FIRST SHEET IS THE WARNING (Illinois's and Nevada's device)
rhtp_me_write_xlsx <- function(awards, cohort, status, dispo) {
  r <- rhtp_me_reconcile(awards, cohort)
  wb  <- openxlsx::createWorkbook()
  hdr <- openxlsx::createStyle(textDecoration = "bold")
  wrap <- openxlsx::createStyle(wrapText = TRUE, valign = "top")

  readme <- tibble::tibble(
    `READ THIS BEFORE USING ANY FIGURE` = c(
      paste0("MAINE HAS ELEVEN NAMED RURAL HOSPITALS IN THIS WORKBOOK AND ",
             "NONE OF THEM IS A RECIPIENT."),
      paste0("The 'RHEF cohort' sheet lists eleven hospitals Maine DHHS ",
             "IDENTIFIED AND INVITED to participate in the $30 million Rural ",
             "Hospital Efficiency Fund on 2026-07-31. They did not apply, no ",
             "award has been made to any of them, and no per-hospital amount ",
             "exists. The State's own RHTP Advisory Committee deck of ",
             "2026-08-05 says the 'award amount and approved budget will be ",
             "confirmed AFTER START OF PARTICIPATION in the HE Cohort'."),
      paste0("That sheet therefore has NO AMOUNT COLUMN, and it is not part ",
             "of any award total. Counting those eleven as recipients would ",
             "invent eleven hospital awards (§0.3: eligibility is not ",
             "receipt)."),
      paste0("MAINE'S NAMED-HOSPITAL AWARD ROWS: 0.  ",
             "MAINE'S NAMED-HOSPITAL DOLLARS: $0."),
      paste0("The 'Awards' sheet holds ONE row -- the University of New ",
             "England's Shaw Institute, $12,000,000, Initiative 1. UNE is a ",
             "UNIVERSITY, and the subrecipients it will contract with are ",
             "Public Health District organisations and Tribal Health Centers, ",
             "not hospitals. The amount is DHHS's round '$12 million' and is ",
             "not confirmed: this announcement's CMS footer alone adds ",
             "'pending approval of revised budget'."),
      paste0("Maine has announced $", format(r$announced_pools, big.mark = ",", scientific = FALSE),
             " of Year 1 funding across five channels against a $",
             format(r$cms_allotment, big.mark = ",", scientific = FALSE), " allotment (",
             sprintf("%.1f%%", 100 * r$pools_share), "). Every channel except ",
             "UNE is PRE-AWARD, and each has a date: EMR contracts execute in ",
             "the Fall, APM payments issue Sept/Oct, RHEF funding is approved ",
             "Fall/Winter, and Maine DOE's own award announcement date of ",
             "August 31, 2026 has PASSED with no roster published."),
      paste0("See data/reference/me_year1_status.csv for what each channel ",
             "publishes, and me_rcj_candidate_disposition.csv for why the ",
             "aggregator's twelve Maine candidates are eleven non-awards and ",
             "one award.")
    )
  )

  add <- function(name, df, widths = "auto") {
    openxlsx::addWorksheet(wb, name)
    openxlsx::writeData(wb, name, df, headerStyle = hdr)
    openxlsx::freezePane(wb, name, firstActiveRow = 2)
    openxlsx::setColWidths(wb, name, cols = seq_along(df), widths = widths)
  }

  add("READ ME FIRST", readme, widths = 130)
  openxlsx::addStyle(wb, "READ ME FIRST", wrap, rows = 2:(nrow(readme) + 1),
                     cols = 1, gridExpand = TRUE)
  add("Awards", awards)
  add("RHEF cohort (NOT AWARDS)", cohort)
  add("Channel status", status)
  add("RCJ candidate disposition", dispo)

  openxlsx::saveWorkbook(wb, here::here(ME_XLSX), overwrite = TRUE)
  message("[ME] wrote ", ME_XLSX)
  invisible(TRUE)
}


# -- the LIVE probe -----------------------------------------------------------

#' Has Maine awarded yet? Runs the tripwires against the LIVE bytes.
#'
#' Session 25's Indiana lesson as code: `--validate` reads the committed archive
#' and can only answer "had Maine awarded on the day the archive was taken?".
#' Maine's page digests are STABLE -- two fetches three seconds apart return the
#' same SHA-256 -- so unlike Nevada, Missouri and Wisconsin a file digest is a
#' usable change test here, and it is used directly.
me_probe <- function() {
  watched <- c("rhef", "doe", "programme", "mcd")
  message("[ME] LIVE probe, ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"))
  changed <- character(0)
  bodies <- list()
  for (k in watched) {
    url <- me_source(k, "url")
    served <- me_get(url, k)
    bodies[[k]] <- served
    live <- digest::digest(served, algo = "sha256", serialize = FALSE)
    have <- digest::digest(file = me_path(k), algo = "sha256")
    same <- identical(live, have)
    message(sprintf("  %-10s %s  %s", k, if (same) "UNCHANGED" else "CHANGED  ",
                    substr(live, 1, 16)))
    if (!same) changed <- c(changed, k)
    Sys.sleep(ME_HOST_THROTTLE_S)
  }

  txt <- lapply(bodies, function(b) me_html_text(NULL, body = b))
  me_assert_cohort_not_awarded(rhef = txt$rhef,
                               deck = me_pdf_text("advisory_aug"))
  me_assert_channels_not_awarded(emr = me_html_text("emr"), doe = txt$doe,
                                 mcd = txt$mcd,
                                 deck = me_pdf_text("advisory_aug"))
  message("[ME] the award tripwires pass against the LIVE bytes: Maine has ",
          "not published a recipient-level award roster.")
  if (length(changed)) {
    message("[ME] CHANGED, read them: ", paste(changed, collapse = ", "))
  }
  invisible(list(changed = changed))
}


# -- report -------------------------------------------------------------------

rhtp_me_report <- function() {
  awards <- rhtp_me_year1_awardees()
  cohort <- rhtp_me_rhef_cohort()
  status <- rhtp_me_year1_status()
  r <- rhtp_me_reconcile(awards, cohort)

  cat("\nMAINE -- RHTP Year 1\n")
  cat(strrep("=", 78), "\n\n")
  cat(sprintf("  CMS FY2026 allotment           $%s\n",
              format(r$cms_allotment, big.mark = ",", scientific = FALSE)))
  cat(sprintf("  Announced across five channels $%s  (%.1f%%)\n",
              format(r$announced_pools, big.mark = ",", scientific = FALSE), 100 * r$pools_share))
  cat(sprintf("  AWARD ACTIONS EVIDENCED        %d, $%s  (%.1f%%)\n",
              r$award_rows, format(r$award_total, big.mark = ",", scientific = FALSE),
              100 * r$awarded_share))
  cat(sprintf("  NAMED-HOSPITAL AWARD ROWS      %d\n", r$named_hospital_rows))
  cat(sprintf("  NAMED-HOSPITAL DOLLARS         $%s\n",
              format(r$named_hospital_dollars, big.mark = ",", scientific = FALSE)))
  cat(sprintf("  NAMED HOSPITALS THAT ARE NOT RECIPIENTS   %d\n\n",
              r$cohort_hospitals))

  cat("  THE ELEVEN INVITED HOSPITALS (me_rhef_cohort.csv -- NOT AWARDS)\n")
  for (i in seq_len(nrow(cohort))) {
    cat(sprintf("    %2d  %s\n", cohort$row_no[i], cohort$organization[i]))
  }
  cat("\n  Maine DHHS 'identified and invited' these eleven on 2026-07-31.\n")
  cat("  Its own advisory deck, 2026-08-05: 'Award amount and approved\n")
  cat("  budget will be confirmed AFTER START OF PARTICIPATION in the HE\n")
  cat("  Cohort.' HE Cohort begins SEPTEMBER; funding approved FALL/WINTER.\n\n")

  cat("  WHAT EACH CHANNEL PUBLISHES\n")
  for (i in seq_len(nrow(status))) {
    cat(sprintf("    %-34s %-26s roster: %s\n",
                substr(status$channel[i], 1, 34),
                substr(status$stage[i], 1, 26),
                status$publishes_roster[i]))
  }
  cat("\n  THE AWARD FILE (me_year1_awardees.csv)\n")
  cat(sprintf("    %s\n    $%s -- %s, %s\n\n",
              awards$awardee[1], format(awards$amount[1], big.mark = ",", scientific = FALSE),
              awards$recipient_type[1], awards$flow_type[1]))
  invisible(TRUE)
}


# -- CLI ----------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args)    me_fetch(force = "--force" %in% args)
  if ("--validate" %in% args) rhtp_me_assert(strict_footer = "--strict" %in% args)
  if ("--build" %in% args)    rhtp_me_build()
  if ("--probe" %in% args)    me_probe()
  if ("--report" %in% args)   rhtp_me_report()
  if (!any(c("--fetch", "--validate", "--build", "--probe", "--report") %in% args)) {
    message("usage: Rscript R/03aa_me_year1_awardees.R ",
            "[--fetch [--force]] [--validate] [--build] [--probe] [--report]")
  }
}
