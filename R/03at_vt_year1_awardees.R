#!/usr/bin/env Rscript
# 03at_vt_year1_awardees.R ---------------------------------------------------
#
# VERMONT -- 112 EXECUTED AGREEMENTS, $87,175,011.33, AND A PAGE THAT SAYS IT
# IS PARTIAL.
#
# AHS's "RHT Year 1 Awards and Contracts -- Updated as of September 18, 2026"
# lists "executed agreements for Vermont's Rural Health Transformation (RHT)
# Program". 112 priced rows, and the table's own total row prints
# $87,175,011.33, which the rows sum to TO THE CENT. So the reconciliation
# target is the publisher's own figure, not the sum of the rows (South
# Carolina's problem does not arise here).
#
# THEY ARE EXECUTED AGREEMENTS, WHICH IS STRONGER THAN MOST STATES HERE.
# Oregon, Alaska, Arkansas and Wyoming publish intents; Maryland publishes
# offers. Vermont's word is "executed", so every row is `NOTICE_OF_AWARD` +
# `amount_confirmed = Yes`.
#
# AND THE LIST IS PARTIAL IN VERMONT'S OWN WORDS: "This is a partial and
# ongoing list and does not represent the full Year 1 awards or funding
# decisions." So $84.5M of award rows is a FLOOR, and `--probe` watches the
# page for the next update (it says it "will be updated regularly").
#
# TWO DECISIONS WERE TAKEN WITH THE OWNER BEFORE THIS FILE WAS WRITTEN
# (session 54):
#
#   1. MARY HITCHCOCK MEMORIAL HOSPITAL IS IN NEW HAMPSHIRE AND COUNTS AS A
#      VERMONT HOSPITAL ROW. CMS enrols it at CCN 300003, Lebanon NH. The page
#      stars it: "*RHT funding is specific to services and activities
#      benefiting Vermont patients". The money is Vermont's RHTP money and the
#      recipient is a hospital, so it is `HOSPITAL_OR_SYSTEM`/`DIRECT`/`Yes`
#      under VT -- with `facility_state = NH` on every one of its three rows,
#      so a reader can subtract the out-of-state facility ($8,820,815.60).
#
#   2. THE GMCB MEMORANDUM OF UNDERSTANDING IS NOT A SUBAWARD. The row reads
#      "Memorandum of Understanding between AHS and GMCB; additional details
#      coming soon", $2,635,000 -- one state agency moving money to another.
#      It is kept OUT of the award file and recorded in `vt_year1_status.csv`,
#      and the reconciliation puts it back: 111 award rows + the MOU = the
#      page's printed total.
#
# THE TYPING IS A FEDERAL RECORD WHERE ONE EXISTS, AND IT CAUGHT TWO TRAPS
# THE NAME RULE WALKS INTO. AHS publishes a legal name and a DBA and nothing
# about the recipient's form (the unstated-form question, Vermont's turn).
# CMS's Hospital, FQHC, SNF and HHA enrolment files for Vermont were fetched
# and archived under `data/evidence/federal_records/2026-09-23/`, and every
# override in VT_TYPES says which record settles it.
#
#   * "1248 HOSPITAL DRIVE OPCO LLC" IS A NURSING HOME. §8's name rule reads
#     "Hospital" in the STREET ADDRESS that forms this LLC's legal name and
#     returns HOSPITAL_OR_SYSTEM at HIGH. CMS enrols it as a SKILLED NURSING
#     FACILITY (CCN 475019B, dba St. Johnsbury Center for Living and
#     Rehabilitation). Three rows, $2,081,510, that the machine would have
#     put in the hospital total. §0.3a's second half: read the recipient.
#
#   * "GIFFORD HEALTH CARE" IS THE FQHC, NOT THE HOSPITAL. Anyone who knows
#     Randolph would type it as Gifford Medical Center. CMS enrols THE
#     HOSPITAL as "GIFFORD MEDICAL CENTER INC" (CCN 471301) and "GIFFORD
#     HEALTH CARE INC" as an FQHC (CCN 471852). The awardee string is the
#     FQHC's legal name. $510,763.57 kept OUT of the hospital total on a
#     federal record, where general knowledge would have put it in.
#
# ONE HOSPITAL TYPING RESTS ON GENERAL KNOWLEDGE AND IS PRICED AT LOW SO A
# READER CAN SUBTRACT IT: The University of Vermont Health Network Inc. (two
# spellings, $2,474,684.82) is the parent system of UVM Medical Center (CMS
# 470003) and Central Vermont Medical Center (CMS 470001) and is not itself an
# enrolled provider. §8 types a health system HOSPITAL_OR_SYSTEM; the shared
# classifier reads "University" in the name and says UNIVERSITY_OR_AHC, which
# is wrong about this body.
#
# NOTHING IS MERGED (§2). North Country Hospital appears under three
# spellings, Northeastern Vermont Regional Hospital under three, Northern
# Counties Health Care under four. One row per EXECUTED AGREEMENT.
#
# Usage:
#   Rscript R/03at_vt_year1_awardees.R --validate | --build | --probe | --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
  library(purrr); library(httr); library(digest); library(here); library(rlang)
  library(rvest); library(xml2)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

VT_STATE        <- "VT"
VT_ALLOTMENT    <- 195053740      # cms_fy2026_allotments.csv (§7.1)
VT_PAGE_TOTAL   <- 87175011.33    # the table's own total row
VT_PAGE_ROWS    <- 112L
VT_MOU_AMOUNT   <- 2635000
VT_UPDATED      <- as.Date("2026-09-18")
VT_NOA_DATE     <- as.Date("2025-12-29")

VT_ARCHIVE_DIR  <- file.path("data", "evidence", "recheck", "2026-09-23", "VT")
VT_FED_DIR      <- file.path("data", "evidence", "federal_records", "2026-09-23")
VT_AWARDS_FILE  <- file.path(VT_ARCHIVE_DIR, "vt_year1_awards.html")
VT_AWARDS_URL   <- paste0("https://healthcarereform.vermont.gov/",
                          "rht-year-1-executed-agreements-and-contracts")

VT_CSV        <- here::here("data", "reference", "vt_year1_awardees.csv")
VT_STATUS_CSV <- here::here("data", "reference", "vt_year1_status.csv")

VT_USER_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                        "+https://www.aha.org)")

VT_DOC_TITLE <- "RHT Year 1 Awards and Contracts -- Updated as of September 18, 2026"


# -- the form of each recipient ----------------------------------------------
#
# Keyed on the LEGAL NAME exactly as printed (a trailing "*" footnote marker
# and whitespace trimmed). A name not listed here keeps the shared
# classifier's answer -- which, for a name carrying no token, is §8's standing
# fallback with RECIPIENT_TYPE_INFERRED.
#
# `basis_type` follows session 49: FEDERAL_RECORD answers are ORG_WEBSITE ->
# MEDIUM (session 50's precedent for a CMS enrolment match), a hand-read
# bridge or general knowledge is GENERAL_KNOWLEDGE -> LOW.

VT_FED <- "ORG_WEBSITE"
VT_GK  <- "GENERAL_KNOWLEDGE"

VT_TYPES <- tibble::tribble(
  ~legal, ~recipient_type, ~basis_type, ~facility_state, ~why,
  # ---- hospitals -----------------------------------------------------------
  "Mary Hitchcock Memorial Hospital", "HOSPITAL_OR_SYSTEM", VT_FED, "NH",
  "CMS Hospital Enrollment: MARY HITCHCOCK MEMORIAL HOSPITAL, CCN 300003, LEBANON NH. OUT-OF-STATE FACILITY, counted under Vermont by owner decision (session 54): the page stars it, '*RHT funding is specific to services and activities benefiting Vermont patients'.",
  "Rutland Regional Medical Center", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: RUTLAND HOSPITAL, INC. dba RUTLAND REGIONAL MEDICAL CENTER, CCN 470005.",
  "Brattleboro Memorial Hospital", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: BRATTLEBORO MEMORIAL HOSPITAL, CCN 470011.",
  "Northeastern Vermont Regional Hospital", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: NORTHEASTERN VERMONT REGIONAL HOSPITAL INC dba NVRH, CCN 471303 (CAH).",
  "Northeastern Vermont Regional Hospital (NVRH)", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: NORTHEASTERN VERMONT REGIONAL HOSPITAL INC dba NVRH, CCN 471303 (CAH).",
  "Northeastern Vermont Regional Hospital Inc.", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: NORTHEASTERN VERMONT REGIONAL HOSPITAL INC, CCN 471303 (CAH).",
  "North Country Hospital & Health Center", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: NORTH COUNTRY HOSPITAL & HEALTH CENTER INC, CCN 471304 (CAH).",
  "North Country Hospital and Health Center, Inc.", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: NORTH COUNTRY HOSPITAL & HEALTH CENTER INC, CCN 471304 (CAH).",
  "North Country Hospital and Health Center", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: NORTH COUNTRY HOSPITAL & HEALTH CENTER INC, CCN 471304 (CAH).",
  "Northwestern Medical Center", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: NORTHWESTERN MEDICAL CENTER INC, CCN 470024.",
  "Southwestern Vermont Medical Center, Inc.", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: SOUTHWESTERN VERMONT MEDICAL CENTER, INC, CCN 470012.",
  "Grace Cottage Hospital", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: CARLOS G OTIS HEALTH CARE CENTER INC dba GRACE COTTAGE HOSPITAL, CCN 47Z300 / 471300 (CAH).",
  "Central Vermont Medical Center Inc.", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: CENTRAL VERMONT MEDICAL CENTER INC, CCN 470001.",
  "Brattleboro Retreat", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: BRATTLEBORO RETREAT, CCN 474001, PSYCHIATRIC subgroup. A psychiatric hospital -- the SC benchmark's 'psychiatric excluded' reading would subtract it.",
  "THE UNIVERSITY OF VERMONT HEALTH NETWORK INC.", "HOSPITAL_OR_SYSTEM", VT_GK, "VT",
  "GENERAL KNOWLEDGE, NOT A FEDERAL RECORD: the parent health system of UVM Medical Center (CMS-certified 470003) and Central Vermont Medical Center (CMS-certified 470001); it is not itself an enrolled provider, so no CCN is recorded for it. The shared classifier's UNIVERSITY_OR_AHC reads the word 'University' and is wrong about this body. Priced at LOW so a reader can subtract it.",
  "UVM - Health Network", "HOSPITAL_OR_SYSTEM", VT_GK, "VT",
  "GENERAL KNOWLEDGE: a second spelling of The University of Vermont Health Network Inc. (not merged, §2). See that row.",
  # ---- the two traps -------------------------------------------------------
  "1248 Hospital Drive Opco LLC", "OTHER", VT_FED, "VT",
  "NURSING FACILITY. CMS SNF Enrollment: 1248 HOSPITAL DRIVE OPCO LLC dba ST JOHNSBURY CENTER FOR LIVING AND REHABILITATION, CCN 475019B. 'Hospital' is the STREET in the LLC's name; §8's name rule returns HOSPITAL_OR_SYSTEM at HIGH and is wrong.",
  "Gifford Health Care", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: GIFFORD HEALTH CARE INC, CCN 471852. THE HOSPITAL is enrolled separately as GIFFORD MEDICAL CENTER INC (CCN 471301); the awardee string is the FQHC's legal name, so this is NOT a hospital row.",
  # ---- FQHCs ---------------------------------------------------------------
  "Community Health Centers of the Rutland Region", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: COMMUNITY HEALTH CENTERS OF THE RUTLAND REGION INC.",
  "Community Health Centers- Rutland", "FQHC_OR_RHC", VT_GK, "VT",
  "A shortened spelling of Community Health Centers of the Rutland Region (CMS FQHC); the bridge is a reading, so LOW.",
  "Community Health Centers of Burlington, Inc.", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: COMMUNITY HEALTH CENTERS OF BURLINGTON INC, CCN 471800.",
  "Northern Counties Health Care", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: NORTHERN COUNTIES HEALTH CARE INC (St. Johnsbury Community Health Center and others).",
  "Northern Counties Health Care, Inc.", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: NORTHERN COUNTIES HEALTH CARE INC. This row's DBA is its home-health division (Caledonia Home Health Care and Hospice, CMS HHA 477010); the LEGAL recipient is the FQHC.",
  "Northern Counties Health Care Inc.", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: NORTHERN COUNTIES HEALTH CARE INC.",
  "Little Rivers Health Care", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: LITTLE RIVERS HEALTH CARE, INC.",
  "Little Rivers Health Care, Inc. (LRHC)", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: LITTLE RIVERS HEALTH CARE, INC.",
  "Little Rivers Health Care, Inc.", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: LITTLE RIVERS HEALTH CARE, INC.",
  "Richford Health Center, Inc. (NOTCH)", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: THE RICHFORD HEALTH CENTER, INC. (NOTCH Primary Care).",
  "Richford Health Center Inc", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: THE RICHFORD HEALTH CENTER, INC.",
  "Richford Health Center Inc.", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: THE RICHFORD HEALTH CENTER, INC.",
  "Northern Tier Center for Health (NOTCH)", "FQHC_OR_RHC", VT_GK, "VT",
  "NOTCH is the trade name of The Richford Health Center, Inc. (CMS FQHC, 'NOTCH PRIMARY CARE'); this row prints only the trade name, so the bridge is a reading -- LOW.",
  "Five-Town Health Alliance Inc.", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: FIVE-TOWN HEALTH ALLIANCE, INC dba MOUNTAIN HEALTH CENTER, CCN 471846.",
  "Mountain Community Health", "FQHC_OR_RHC", VT_GK, "VT",
  "The page's own DBA is 'Five Town Health Alliance, INC' (CMS FQHC 471846); the bridge is the page's pairing plus a reading -- LOW.",
  # ---- nursing facilities --------------------------------------------------
  "105 Chester Road Opco LLC", "OTHER", VT_FED, "VT",
  "NURSING FACILITY. CMS SNF Enrollment: 105 CHESTER ROAD OPCO LLC dba SPRINGFIELD CENTER FOR LIVING AND REHABILITATION, CCN 475025B.",
  "105 Chester Rd Opco LLC", "OTHER", VT_FED, "VT",
  "NURSING FACILITY. CMS SNF Enrollment: 105 CHESTER ROAD OPCO LLC, CCN 475025B (the page abbreviates 'Road').",
  "46 NICHOLS STREET OPCO LLC", "OTHER", VT_FED, "VT",
  "NURSING FACILITY. CMS SNF Enrollment: 46 NICHOLS STREET OPCO LLC dba RUTLAND CENTER FOR LIVING AND REHABILITATION, CCN 475039.",
  "Rutland Center for Living and Rehabilitation", "OTHER", VT_FED, "VT",
  "NURSING FACILITY. CMS SNF Enrollment carries this string as the DBA of 46 NICHOLS STREET OPCO LLC, CCN 475039.",
  "CLR Opco", "OTHER", VT_FED, "VT",
  "NURSING FACILITY. CMS SNF Enrollment: CLR OPCO LLC dba CENTER FOR LIVING & REHABILITATION, Bennington, CCN 475029.",
  "The Manor", "OTHER", VT_FED, "VT",
  "NURSING FACILITY. CMS SNF Enrollment: THE MANOR INC, Morrisville, CCN 475057.",
  "Rutland Crossings, LLC", "OTHER", VT_FED, "VT",
  "NURSING FACILITY. CMS SNF Enrollment: RUTLAND CROSSINGS LLC dba THE PINES AT RUTLAND CENTER FOR NURSING AND REHABILITATION, CCN 475018.",
  # ---- home health agencies ------------------------------------------------
  "VNA & Hospice of the Southwest Region, Inc.", "OTHER", VT_FED, "VT",
  "HOME HEALTH AGENCY. CMS HHA Enrollment: VNA & HOSPICE OF THE SOUTHWEST REGION, INC., CCN 477007.",
  "VNA & Hospice of the Southwest Region", "OTHER", VT_FED, "VT",
  "HOME HEALTH AGENCY. CMS HHA Enrollment: VNA & HOSPICE OF THE SOUTHWEST REGION, INC., CCN 477007.",
  "Central Vermont Home Health & Hospice, Inc.", "OTHER", VT_FED, "VT",
  "HOME HEALTH AGENCY. CMS HHA Enrollment: CENTRAL VERMONT HOME HEALTH & HOSPICE, INC, CCN 477003.",
  "Central Vermont Home Health & Hospice", "OTHER", VT_FED, "VT",
  "HOME HEALTH AGENCY. CMS HHA Enrollment: CENTRAL VERMONT HOME HEALTH & HOSPICE, INC, CCN 477003.",
  "Central Vermont Home Health & Hospice (CVHHH)", "OTHER", VT_FED, "VT",
  "HOME HEALTH AGENCY. CMS HHA Enrollment: CENTRAL VERMONT HOME HEALTH & HOSPICE, INC, CCN 477003.",
  "Lamoille Home Health & Hospice", "OTHER", VT_FED, "VT",
  "HOME HEALTH AGENCY. CMS HHA Enrollment: LAMOILLE HOME HEALTH AGENCY, INC. dba LAMOILLE HOME HEALTH & HOSPICE, CCN 477015.",
  "Lamoille Home Health and Hospice", "OTHER", VT_FED, "VT",
  "HOME HEALTH AGENCY. CMS HHA Enrollment: LAMOILLE HOME HEALTH AGENCY, INC. dba LAMOILLE HOME HEALTH & HOSPICE, CCN 477015.",
  "University of Vermont Health - Home Health & Hospice", "OTHER", VT_FED, "VT",
  "HOME HEALTH AGENCY. CMS HHA Enrollment: THE UNIVERSITY OF VERMONT HEALTH NETWORK HOME HEALTH & HOSPICE, INC., CCN 477000. The classifier's UNIVERSITY_OR_AHC reads 'University' and is wrong; a hospital system's home-health subsidiary is not the hospital (session 49's affiliated-arm test turns on a FOUNDATION of a named hospital, and this is a separately enrolled provider type).",
  "Dartmouth Health Home Care, Inc.", "OTHER", VT_GK, "NH",
  "HOME HEALTH AGENCY, by general knowledge (Dartmouth Health's home-care arm, New Hampshire-based; starred on the page as funding for Vermont patients). Not in CMS's VT HHA file under this name -- LOW.",
  "Dartmouth Health Home Care", "OTHER", VT_GK, "NH",
  "HOME HEALTH AGENCY, by general knowledge. See 'Dartmouth Health Home Care, Inc.' -- not merged (§2).",
  # ---- designated mental-health agencies -----------------------------------
  "Health Care and Rehabilitation Services (HCRS)", "OTHER", VT_GK, "VT",
  "COMMUNITY MENTAL HEALTH DESIGNATED AGENCY (southeastern Vermont), by general knowledge. Mississippi's CMHC precedent: neither a hospital nor the awarding agency.",
  "Clara Martin Center", "OTHER", VT_GK, "VT",
  "COMMUNITY MENTAL HEALTH DESIGNATED AGENCY (Orange County), by general knowledge.",
  "Howard Center", "OTHER", VT_GK, "VT",
  "COMMUNITY MENTAL HEALTH DESIGNATED AGENCY (Chittenden County), by general knowledge.",
  "Counseling Service of Addison County, Inc.", "OTHER", VT_GK, "VT",
  "COMMUNITY MENTAL HEALTH DESIGNATED AGENCY (Addison County), by general knowledge.",
  "Washington County Mental Health", "OTHER", VT_GK, "VT",
  "COMMUNITY MENTAL HEALTH DESIGNATED AGENCY (Washington County), by general knowledge.",
  # ---- vendors and others --------------------------------------------------
  "McKinsey & Co.", "VENDOR_OR_CONTRACTOR", VT_GK, NA,
  "Management consultancy contracted by the State.",
  "Bailit Health Purchasing, LLC", "VENDOR_OR_CONTRACTOR", VT_GK, NA,
  "Health-policy consultancy contracted by the State.",
  "Wakely Consulting Group", "VENDOR_OR_CONTRACTOR", VT_GK, NA,
  "Actuarial consultancy contracted by the State.",
  "National Opinion Research Center (NORC)", "VENDOR_OR_CONTRACTOR", VT_GK, NA,
  "The programme's independent evaluator, contracted by the State.",
  "GMS - AGATE IGX", "VENDOR_OR_CONTRACTOR", VT_GK, NA,
  "Grants-management software (Agate IntelliGrants) for programme administration.",
  "KPH Healthcare Services Inc.", "OTHER", VT_GK, "VT",
  "RETAIL PHARMACY CHAIN (dba Kinney Drugs), by general knowledge; funded to expand pharmacists' test-to-treat scope.",
  "Vermont Student Assistance Corporation", "OTHER", VT_GK, "VT",
  "STATE STUDENT-AID CORPORATION (a public nonprofit created by statute), administering conditional financial assistance to health-care students.",
  "Vermont State Colleges", "UNIVERSITY_OR_AHC", VT_GK, "VT",
  "The Vermont State Colleges system (public higher education).",
  "Thomas Chittenden Health Center", "PHYSICIAN_PRACTICE", VT_GK, "VT",
  "Independent primary-care practice (Williston), by general knowledge.",
  "Primary Health Care Partners", "PHYSICIAN_PRACTICE", VT_GK, "VT",
  "Independent primary-care practice group, by general knowledge. Printed two ways on the page; not merged (§2).",
  "Primary Care Health Partners", "PHYSICIAN_PRACTICE", VT_GK, "VT",
  "Independent primary-care practice group, by general knowledge.",
  "Ophthalmic Consultants of Vermont", "PHYSICIAN_PRACTICE", VT_GK, "VT",
  "Ophthalmology practice, by general knowledge.",
  "Eye Care Associates", "PHYSICIAN_PRACTICE", VT_GK, "VT",
  "Eye-care practice, by general knowledge."
)

vt_legal_key <- function(x) stringr::str_squish(stringr::str_remove(x, "\\s*\\*+\\s*$"))


# -- the page ----------------------------------------------------------------

vt_read_page <- function(body = NULL) {
  h <- if (is.null(body)) xml2::read_html(here::here(VT_AWARDS_FILE)) else
    xml2::read_html(rawToChar(body))
  h
}

#' The award table as printed, rowspans filled
vt_parse_table <- function(body = NULL) {
  h <- vt_read_page(body)
  tabs <- rvest::html_elements(h, "table")
  if (length(tabs) != 1L) {
    stop("[VT] expected ONE table on the awards page; found ", length(tabs),
         ". The page's shape changed -- read it.", call. = FALSE)
  }
  tb <- rvest::html_table(tabs[[1]], header = TRUE)
  if (ncol(tb) != 5L ||
      !grepl("Initiative", names(tb)[1]) || !grepl("Amount", names(tb)[5])) {
    stop("[VT] the awards table's header changed: ",
         paste(names(tb), collapse = " | "), call. = FALSE)
  }
  names(tb) <- c("initiative", "activity", "legal", "dba", "amount_txt")
  total_row <- grepl("^\\*RHT funding", tb$initiative)
  if (sum(total_row) != 1L) {
    stop("[VT] expected exactly one total row.", call. = FALSE)
  }
  printed_total <- as.numeric(gsub("[$,\\s]", "", tb$amount_txt[total_row],
                                   perl = TRUE))
  tb <- tb[!total_row, ]
  clean <- function(x) stringr::str_squish(gsub(" ", " ", x))
  tb <- tb %>%
    dplyr::mutate(dplyr::across(c("initiative", "activity", "legal", "dba"),
                                clean),
                  amount = as.numeric(gsub("[$,\\s ]", "", .data$amount_txt,
                                           perl = TRUE)),
                  page_row = dplyr::row_number())
  attr(tb, "printed_total") <- printed_total
  tb
}

vt_is_mou <- function(tb) grepl("^Memorandum of Understanding between AHS and GMCB",
                                tb$legal)


# -- assertions --------------------------------------------------------------

vt_assert_reconciles <- function(tb = vt_parse_table()) {
  pt <- attr(tb, "printed_total")
  if (nrow(tb) != VT_PAGE_ROWS) {
    stop("[VT] the page now carries ", nrow(tb), " agreements, not ",
         VT_PAGE_ROWS, ". Vermont said it would update this list -- re-read ",
         "it and re-type the new rows.", call. = FALSE)
  }
  if (anyNA(tb$amount)) stop("[VT] an amount did not parse.", call. = FALSE)
  if (abs(pt - VT_PAGE_TOTAL) > 0.005 || abs(sum(tb$amount) - pt) > 0.005) {
    stop("[VT] the rows ($", format(sum(tb$amount), nsmall = 2),
         ") no longer sum to the printed total ($", format(pt, nsmall = 2),
         ").", call. = FALSE)
  }
  if (sum(vt_is_mou(tb)) != 1L ||
      abs(tb$amount[vt_is_mou(tb)] - VT_MOU_AMOUNT) > 0.005) {
    stop("[VT] the GMCB MOU row ($2,635,000) is not where it was.",
         call. = FALSE)
  }
  invisible(TRUE)
}

vt_assert_partial_and_executed <- function(body = NULL) {
  txt <- stringr::str_squish(rvest::html_text2(vt_read_page(body)))
  want <- c("executed agreements for Vermont",
            "partial and ongoing list",
            "Updated as of September 18, 2026")
  miss <- want[!vapply(want, function(w) grepl(w, txt, fixed = TRUE), TRUE)]
  if (length(miss)) {
    stop("[VT] the page no longer says: ", paste(sQuote(miss), collapse = "; "),
         ". 'executed' is why these are NOTICE_OF_AWARD rows and 'partial' is ",
         "why the figure is a floor -- re-read before rebuilding.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' §0.2: the page's CMS footer prints the ALLOTMENT, and the rule agrees
vt_assert_footer_is_allotment <- function() {
  txt <- rvest::html_text2(vt_read_page())
  rhtp_assert_footer_text_tier(txt, VT_STATE, "STATE_ALLOTMENT",
                               label = "VT awards-page footer")
  invisible(TRUE)
}

vt_assert_after_noa <- function() {
  if (VT_UPDATED <= VT_NOA_DATE) stop("[VT] date test.", call. = FALSE)
  invisible(TRUE)
}

#' Every page legal name is typed or deliberately left to the classifier
vt_assert_types_cover <- function(tb = vt_parse_table()) {
  unused <- setdiff(VT_TYPES$legal, vt_legal_key(tb$legal))
  if (length(unused)) {
    stop("[VT] VT_TYPES carries names the page no longer prints: ",
         paste(unused, collapse = "; "), call. = FALSE)
  }
  invisible(TRUE)
}


# -- the award file ----------------------------------------------------------

vt_year1_awardees <- function(tb = vt_parse_table()) {
  aw <- tb[!vt_is_mou(tb), ]
  key <- vt_legal_key(aw$legal)
  awardee <- ifelse(nzchar(aw$dba) & aw$dba != aw$legal,
                    paste0(key, " DBA ", aw$dba), key)
  cls <- rhtp_classify_recipient_type(awardee, VT_STATE)
  ty <- VT_TYPES[match(key, VT_TYPES$legal), ]
  typed <- !is.na(ty$legal)
  rtype <- ifelse(typed, ty$recipient_type, cls$recipient_type)
  conf <- dplyr::case_when(
    typed & ty$basis_type == VT_GK ~ "LOW",
    typed ~ "MEDIUM",
    TRUE ~ cls$determination_confidence)
  # A hospital the classifier also reached on its own name keeps its HIGH.
  conf <- ifelse(typed & ty$basis_type == VT_FED &
                   rtype == "HOSPITAL_OR_SYSTEM" &
                   cls$recipient_type == "HOSPITAL_OR_SYSTEM",
                 cls$determination_confidence, conf)
  flow <- rhtp_classify_flow(rtype, aw$activity, award_made = TRUE)
  flag <- ifelse(!typed & rtype == "NONPROFIT_CBO" &
                   cls$determination_confidence == "LOW",
                 "RECIPIENT_TYPE_INFERRED", NA_character_)
  ff <- if ("flag_reason" %in% names(flow)) flow$flag_reason else rep(NA_character_, nrow(flow))
  flag <- ifelse(is.na(flag) & !is.na(ff), ff, flag)
  hosp <- flow$distributed_to_hospital == "Yes"

  tibble::tibble(
    state = VT_STATE,
    row_no = seq_len(nrow(aw)),
    awardee = awardee,
    amount = aw$amount,
    recipient_type = rtype,
    distributed_to_hospital = flow$distributed_to_hospital,
    note = paste0("Executed agreement, ", aw$initiative, ": ", aw$activity,
                  ". Vermont's list is 'partial and ongoing'."),
    recipient_confirmed = "Yes",
    amount_confirmed = "Yes",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = VT_DOC_TITLE,
    state_source_url = VT_AWARDS_URL,
    validation_source_type = "NOTICE_OF_AWARD",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03at_vt_year1_awardees.R",
    ccn = NA_character_,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    initiative = aw$initiative,
    activity = aw$activity,
    awardee_legal_as_published = aw$legal,
    dba_as_published = dplyr::na_if(aw$dba, ""),
    facility_state = ifelse(typed, ty$facility_state, NA_character_),
    recipient_type_source = ifelse(
      typed,
      paste0("TYPED (session 54): ", ty$why, " Classifier said ",
             cls$recipient_type, "/", cls$determination_confidence, "."),
      paste0("rhtp_classify_recipient_type() on the name: ",
             cls$recipient_type, "/", cls$determination_confidence, ".")),
    determination_confidence = conf,
    flag_reason = flag,
    award_pool = aw$initiative,
    budget_period = "Budget Period 1",
    flow_type = flow$flow_type,
    hospital_benefiting = flow$hospital_benefiting,
    hospital_attribution = ifelse(hosp, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = ifelse(
      hosp,
      paste0("§10.2 DIRECT: the recipient is a hospital (", ifelse(is.na(ty$why), "", ty$why),
             ") and AHS lists the agreement as EXECUTED. §0.3a judges the ",
             "recipient, not the activity."),
      paste0(flow$flow_basis,
             ifelse(typed & rtype == "OTHER", paste0(" Determined form: ", ty$why), ""))),
    amount_basis = paste0("EXACT, as printed on AHS's list; the 112 rows sum ",
                          "to the table's own total ($87,175,011.33) to the cent."),
    basis_type = ifelse(typed, ty$basis_type, NA_character_),
    round_amount = NA_real_,
    announcement_date = VT_UPDATED,
    source_archive_path = VT_AWARDS_FILE,
    page_row = aw$page_row)
}

vt_status_table <- function(tb = vt_parse_table()) {
  mou <- tb[vt_is_mou(tb), ]
  tibble::tribble(
    ~state, ~channel, ~stage, ~publishes_roster, ~year1_figure, ~note,
    VT_STATE, "RHT Year 1 Awards and Contracts (AHS)",
    "EXECUTED_ROSTER_PUBLISHED_PARTIAL", "Yes",
    sum(tb$amount[!vt_is_mou(tb)]),
    paste("111 executed agreements to named recipients in the award file.",
          "The page calls itself 'a partial and ongoing list and does not",
          "represent the full Year 1 awards or funding decisions', so this is",
          "a FLOOR. Updated as of 2026-09-18."),
    VT_STATE, "GMCB inter-agency MOU (NOT A SUBAWARD)",
    "INTER_AGENCY_NOT_SUBAWARD", "No", mou$amount,
    paste0("'", mou$legal, "' -- ", mou$activity, ". One state agency (AHS) ",
           "to another (the Green Mountain Care Board): not a Tier 3 award ",
           "to a subrecipient, kept OUT of the award file by owner decision ",
           "(session 54). 111 award rows + this = the page's printed total, ",
           "$87,175,011.33."),
    VT_STATE, "Mary Hitchcock Memorial Hospital (Lebanon, NH)",
    "OUT_OF_STATE_FACILITY_COUNTED", "Yes",
    sum(tb$amount[vt_legal_key(tb$legal) == "Mary Hitchcock Memorial Hospital"]),
    paste("Three executed agreements to a NEW HAMPSHIRE hospital, counted as",
          "Vermont named-hospital dollars by owner decision (session 54); the",
          "page stars them: '*RHT funding is specific to services and",
          "activities benefiting Vermont patients'. facility_state = NH on",
          "each row so a reader can subtract them.")
  )
}


# -- probe / validate / build / report ---------------------------------------

vt_probe <- function() {
  resp <- httr::GET(VT_AWARDS_URL, httr::user_agent(VT_USER_AGENT),
                    httr::timeout(120))
  if (httr::status_code(resp) != 200L) {
    stop("[VT] HTTP ", httr::status_code(resp), " from the awards page.",
         call. = FALSE)
  }
  live <- httr::content(resp, as = "raw")
  txt_of <- function(h) {
    main <- rvest::html_element(h, "main")
    stringr::str_squish(rvest::html_text2(if (inherits(main, "xml_missing")) h else main))
  }
  live_txt <- txt_of(vt_read_page(live))
  arch_txt <- txt_of(vt_read_page())
  changed <- digest::digest(live_txt) != digest::digest(arch_txt)

  vt_assert_partial_and_executed(body = live)
  rhtp_assert_no_new_organisations_across(
    live = list(awards = live_txt), archived = list(awards = arch_txt),
    state = "VT")
  lt <- vt_parse_table(live)
  if (nrow(lt) != VT_PAGE_ROWS) {
    stop("[VT] the list now carries ", nrow(lt), " agreements (was ",
         VT_PAGE_ROWS, "), printed total $",
         format(attr(lt, "printed_total"), nsmall = 2),
         ". Vermont has executed more -- re-archive and re-type.",
         call. = FALSE)
  }
  message("[VT] ", if (changed) "CONTENT CHANGED" else "UNCHANGED",
          " -- 112 executed agreements.")
  invisible(tibble::tibble(key = "awards", changed = changed))
}

vt_validate <- function() {
  tb <- vt_parse_table()
  vt_assert_reconciles(tb)
  vt_assert_partial_and_executed()
  vt_assert_footer_is_allotment()
  vt_assert_after_noa()
  vt_assert_types_cover(tb)
  d <- vt_year1_awardees(tb)
  stopifnot(nrow(d) == VT_PAGE_ROWS - 1L,
            abs(sum(d$amount) + VT_MOU_AMOUNT - VT_PAGE_TOTAL) < 0.005)
  message("[VT] all assertions pass.")
  invisible(TRUE)
}

vt_build <- function() {
  vt_validate()
  d <- vt_year1_awardees()
  readr::write_csv(d, VT_CSV, na = "")
  st <- vt_status_table()
  readr::write_csv(st, VT_STATUS_CSV, na = "")
  message("[VT] wrote ", nrow(d), " award rows and ", nrow(st), " status rows.")
  invisible(d)
}

vt_report <- function() {
  d <- vt_year1_awardees()
  h <- d[d$distributed_to_hospital == "Yes", ]
  cat("\nVERMONT -- executed agreements, partial list\n")
  cat(sprintf("Award rows: %d, $%s  (+ GMCB MOU $2,635,000 out of file)\n",
              nrow(d), format(sum(d$amount), big.mark = ",", nsmall = 2)))
  cat(sprintf("Named-hospital rows: %d, $%s\n", nrow(h),
              format(round(sum(h$amount), 2), big.mark = ",", nsmall = 2)))
  s <- h %>% dplyr::group_by(.data$awardee, .data$facility_state,
                              .data$basis_type, .data$determination_confidence) %>%
    dplyr::summarise(rows = dplyr::n(), dollars = sum(.data$amount),
                     .groups = "drop") %>% dplyr::arrange(dplyr::desc(.data$dollars))
  print(as.data.frame(s), row.names = FALSE)
  invisible(d)
}


if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) vt_validate()
  if ("--build" %in% args) vt_build()
  if ("--probe" %in% args) rhtp_probe_run("VT", vt_probe())
  if ("--report" %in% args) vt_report()
  if (!length(args)) message("Usage: --validate | --build | --probe | --report")
}
