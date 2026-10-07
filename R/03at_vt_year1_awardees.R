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
# SESSION 94 -- THE 2026-10-02 UPDATE: 166 ROWS, $127,419,853.91. Twenty new
# agreements ($18,124,660.41), every 2026-09-25 agreement still printed and
# none re-priced, eleven re-spelled again, and ONE re-filed under a different
# initiative (Northern Counties Health Care, $226,194.70; VT_NCHC_MOVE). A key
# on (initiative, activity, amount) alone mis-pairs the four $2,000,000
# facility-upgrade rows; the diff is keyed on the name first.
#
# Usage:
#   Rscript R/03at_vt_year1_awardees.R --fetch [--force] | --validate | --build
#                                      | --probe | --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
  library(purrr); library(httr); library(digest); library(here); library(rlang)
  library(rvest); library(xml2)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

VT_STATE        <- "VT"
VT_ALLOTMENT    <- 195053740      # cms_fy2026_allotments.csv (§7.1)
VT_PAGE_TOTAL   <- 127419853.91   # the table's own total row (2026-10-02 update)
VT_PAGE_ROWS    <- 166L           # 112 on 09-18; 146 on 09-25; 166 on 10-02
VT_MOU_AMOUNT   <- 2635000
VT_UPDATED      <- as.Date("2026-10-02")
VT_UPDATED_TXT  <- "Updated as of October 2, 2026"
VT_NOA_DATE     <- as.Date("2025-12-29")

VT_ARCHIVE_DIR  <- file.path("data", "evidence", "recheck", "2026-10-07", "VT")
# Each superseded list stays archived; the diffs are of two documents.
# 2026-09-25 (146 rows, $109,295,193.50) is the immediate prior (session 94);
# 2026-09-18 (112 rows, $87,175,011.33) made session 74's +34.
VT_PRIOR_FILE   <- file.path("data", "evidence", "recheck", "2026-09-28", "VT",
                             "vt_year1_awards.html")
VT_PRIOR_FILE_0918 <- file.path("data", "evidence", "recheck", "2026-09-23", "VT",
                                "vt_year1_awards.html")

# SESSION 94: ONE AGREEMENT CHANGED INITIATIVE, AND NOTHING ELSE ABOUT IT DID.
# Northern Counties Health Care's $226,194.70 agreement was printed on
# 2026-09-25 under Regionalization / "Transformation, innovation, and
# regionalization support grants"; on 2026-10-02 the same recipient and the
# same amount are printed under Primary Care / "Expanding access to Federally
# Qualified Health Center (FQHC) primary care services". Same legal name, same
# cents, no other NCHC row moved and no other row carries that amount -- so it
# is read as ONE agreement re-filed, not one ended and one begun. A key on
# (initiative, activity, amount) reports it as one removed and one added,
# which is why the 2026-10-02 diff reads "21 added" when 20 are new.
VT_NCHC_MOVE <- list(
  legal = "Northern Counties Health Care", amount = 226194.70,
  from = c("Regionalization", "Transformation, innovation, and regionalization support grants"),
  to   = c("Primary Care", "Expanding access to Federally Qualified Health Center (FQHC) primary care services"))
VT_FED_DIR      <- file.path("data", "evidence", "federal_records", "2026-09-23")
VT_AWARDS_FILE  <- file.path(VT_ARCHIVE_DIR, "vt_year1_awards.html")
VT_AWARDS_URL   <- paste0("https://healthcarereform.vermont.gov/",
                          "rht-year-1-executed-agreements-and-contracts")

VT_CSV        <- here::here("data", "reference", "vt_year1_awardees.csv")
VT_STATUS_CSV <- here::here("data", "reference", "vt_year1_status.csv")

VT_USER_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                        "+https://www.aha.org)")

VT_DOC_TITLE <- paste("RHT Year 1 Awards and Contracts --", VT_UPDATED_TXT)


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
  "North Country Hospital & Health Center", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: NORTH COUNTRY HOSPITAL & HEALTH CENTER INC, CCN 471304 (CAH).",
  "Northwestern Medical Center", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: NORTHWESTERN MEDICAL CENTER INC, CCN 470024.",
  "Southwestern Vermont Medical Center, Inc.", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: SOUTHWESTERN VERMONT MEDICAL CENTER, INC, CCN 470012.",
  "Grace Cottage Hospital", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: CARLOS G OTIS HEALTH CARE CENTER INC dba GRACE COTTAGE HOSPITAL, CCN 47Z300 / 471300 (CAH).",
  "Brattleboro Retreat", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: BRATTLEBORO RETREAT, CCN 474001, PSYCHIATRIC subgroup. A psychiatric hospital -- the SC benchmark's 'psychiatric excluded' reading would subtract it.",
  "THE UNIVERSITY OF VERMONT HEALTH NETWORK INC.", "HOSPITAL_OR_SYSTEM", VT_GK, "VT",
  "GENERAL KNOWLEDGE, NOT A FEDERAL RECORD: the parent health system of UVM Medical Center (CMS-certified 470003) and Central Vermont Medical Center (CMS-certified 470001); it is not itself an enrolled provider, so no CCN is recorded for it. The shared classifier's UNIVERSITY_OR_AHC reads the word 'University' and is wrong about this body. Priced at LOW so a reader can subtract it.",
  # ---- session 74: the 2026-09-25 update ----------------------------------
  # Re-spellings of recipients already typed above (the page re-printed 34
  # existing agreements with a different legal-name string and the SAME
  # initiative, activity and amount), then the new recipients.
  "Central Vermont Medical Center", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: CENTRAL VERMONT MEDICAL CENTER INC, CCN 470001 (the page drops 'Inc.' from 2026-09-25).",
  "Northeastern Vermont Regional Hospital Inc", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: NORTHEASTERN VERMONT REGIONAL HOSPITAL INC, CCN 471303 (CAH).",
  "University of Vermont Medical Center", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: UNIVERSITY OF VERMONT MEDICAL CENTER INC, CCN 470003, Burlington. The enrolled hospital, not the university -- the name is the hospital's own legal name less 'Inc'.",
  "Springfield Hospital", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: SPRINGFIELD HOSPITAL INC., CCN 471306 (CAH).",
  "Copley Hospital, Inc.", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: COPLEY HOSPITAL INC, CCN 471305 (CAH), Morrisville. (Printed 'Copley Hospital' on 2026-09-25.)",
  "Porter Hospital, Inc.", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: PORTER HOSPITAL INC, CCN 471307 (CAH), Middlebury. (Printed 'Porter Hospital' on 2026-09-25.)",
  "Gifford Medical", "HOSPITAL_OR_SYSTEM", VT_GK, "VT",
  "HAND-READ BRIDGE, LOW (session 74; LEGAL_NAME_TRUNCATED's shape): the only Vermont enrolment whose legal name begins 'GIFFORD MEDICAL' is GIFFORD MEDICAL CENTER INC, CCN 471301 (CAH), Randolph -- the hospital. The FQHC is a different legal body, GIFFORD HEALTH CARE INC, and is printed under that name elsewhere on the same page. A prefix is never matched by machine (§2); this is a reading, priced at LOW so a reader can subtract it, and queued.",
  "Southwestern Vermont Health", "HOSPITAL_OR_SYSTEM", VT_GK, "VT",
  "GENERAL KNOWLEDGE, LOW (session 74): Southwestern Vermont Health Care, the parent system of SOUTHWESTERN VERMONT MEDICAL CENTER, INC (CMS 470012, Bennington). The page truncates the system's name and the system is not itself an enrolled provider -- the UVM Health Network precedent in this file. Priced at LOW so a reader can subtract it, and queued.",
  "Gifford Health Care, Inc", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: GIFFORD HEALTH CARE INC, CCN 471852. NOT the hospital (GIFFORD MEDICAL CENTER INC, CCN 471301).",
  "Five-Town Health Alliance Inc", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: FIVE-TOWN HEALTH ALLIANCE, INC dba MOUNTAIN HEALTH CENTER, CCN 471846.",
  "North Star Health", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: SPRINGFIELD MEDICAL CARE SYSTEMS INC (CCN 471839 and sites) -- the page prints that legal name as this row's DBA; North Star Health is its trade name.",
  "Rutland Crossings, LLC.", "OTHER", VT_FED, "VT",
  "NURSING FACILITY. CMS SNF Enrollment: RUTLAND CROSSINGS LLC dba THE PINES AT RUTLAND CENTER FOR NURSING AND REHABILITATION, CCN 475018.",
  "Health Care and Rehabilitation Services of Southeastern Vermont, Inc.", "OTHER", VT_GK, "VT",
  "COMMUNITY MENTAL HEALTH DESIGNATED AGENCY (HCRS, southeastern Vermont), by general knowledge. The page's full legal name for the row printed as 'Health Care and Rehabilitation Services (HCRS)' on 2026-09-18.",
  "Howard Center, Inc.", "OTHER", VT_GK, "VT",
  "COMMUNITY MENTAL HEALTH DESIGNATED AGENCY (Chittenden County), by general knowledge. Not merged with 'Howard Center' (§2).",
  "Rutland Mental Health Services", "OTHER", VT_GK, "VT",
  "COMMUNITY MENTAL HEALTH DESIGNATED AGENCY (Rutland County; Community Care Network), by general knowledge.",
  "BAART St Albans", "OTHER", VT_GK, "VT",
  "OPIOID TREATMENT PROGRAM (a BAART Programs clinic, BayMark Health Services), by general knowledge. Neither a hospital nor a practice.",
  "BAART St Johnsbury", "OTHER", VT_GK, "VT",
  "OPIOID TREATMENT PROGRAM (a BAART Programs clinic, BayMark Health Services), by general knowledge.",
  "Northeast Kingdom Community Action (NEKCA)", "NONPROFIT_CBO", VT_GK, "VT",
  "COMMUNITY ACTION AGENCY (nonprofit), by general knowledge -- a determined form, not §8's fallback.",
  "UVM - State Agricultural College", "UNIVERSITY_OR_AHC", VT_GK, "VT",
  "The University of Vermont and State Agricultural College -- the UNIVERSITY's legal name. Not the enrolled hospital (UNIVERSITY OF VERMONT MEDICAL CENTER INC, CCN 470003, a separate legal body), so §10.2's enrolled-operator row does not reach it.",
  "University of Vermont Cancer Center", "UNIVERSITY_OR_AHC", VT_GK, "VT",
  "A UNIVERSITY research centre, by general knowledge; no CMS enrolment carries this string. §10.2's AHC row does not reach a sub-unit named without its legal entity (the 'OHSU Casey Eye Institute' shape), so it is not a hospital row. Queued with the other name-only AHC strings.",
  "Richmond Family Medicine", "PHYSICIAN_PRACTICE", VT_GK, "VT",
  "Independent family-medicine practice (Richmond), by general knowledge.",
  "Drs Hogenkamp", "PHYSICIAN_PRACTICE", VT_GK, "VT",
  "Printed 'Drs Peter and Lisa Hogenkamp, PC' until 2026-09-25: A PROFESSIONAL CORPORATION of two named doctors -- a practice, by its own name. Specialty not established here; the form is.",
  # ---- session 94: the 2026-10-02 update ----------------------------------
  # Re-spellings first (same initiative, activity and amount as a 2026-09-25
  # agreement, a different legal-name string), each carrying its prior typing.
  "Brattleboro Memorial Hospital, Inc.", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: BRATTLEBORO MEMORIAL HOSPITAL, CCN 470011 (re-spelled with ', Inc.' on 2026-10-02).",
  "Central Vermont Medical Center, Inc.", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: CENTRAL VERMONT MEDICAL CENTER INC, CCN 470001.",
  "North Country Hospital", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: NORTH COUNTRY HOSPITAL & HEALTH CENTER INC, CCN 471304 (CAH); printed 'North Country Hospital & Health Center' until 2026-09-25, same agreement.",
  "Rutland Hospital, Inc.", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: RUTLAND HOSPITAL, INC. dba RUTLAND REGIONAL MEDICAL CENTER, CCN 470005 -- the enrolment's legal name exactly, and the page prints the enrolment's DBA beside it.",
  "Springfield Center for Living and Rehabilitation", "OTHER", VT_FED, "VT",
  "NURSING FACILITY. CMS SNF Enrollment: 105 CHESTER ROAD OPCO LLC dba SPRINGFIELD CENTER FOR LIVING AND REHABILITATION, CCN 475025B. The page now prints the DBA in the legal-name column (was '105 Chester Road Opco LLC').",
  "Gifford Health Care, Inc.", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: GIFFORD HEALTH CARE INC, CCN 471852. NOT the hospital (GIFFORD MEDICAL CENTER INC, CCN 471301).",
  "Little Rivers Health Care", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: LITTLE RIVERS HEALTH CARE, INC. (printed with 'Inc.' until 2026-09-25).",
  "The Richford Health Center Inc", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: THE RICHFORD HEALTH CENTER, INC. (dba Northern Tier Center for Health).",
  "Community Health Centers of the Rutland Regional", "FQHC_OR_RHC", VT_GK, "VT",
  "The page's MISSPELLING of COMMUNITY HEALTH CENTERS OF THE RUTLAND REGION INC (CMS FQHC). The same agreement was printed with the correct name on 2026-09-25; a misspelling is not an exact match, so it is LOW. It is not a hospital either way.",
  "Richmond Family Med", "PHYSICIAN_PRACTICE", VT_GK, "VT",
  "Printed 'Richmond Family Medicine' until 2026-09-25: independent family-medicine practice (Richmond), by general knowledge.",
  # New recipients and new agreements.
  "Northeastern Vermont Regional Hospital (NVRH)", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: NORTHEASTERN VERMONT REGIONAL HOSPITAL INC dba NVRH, CCN 471303 (CAH). The string is the enrolment's legal name less 'Inc' with the enrolment's own DBA in parentheses -- both halves on one record.",
  "Grace Cottage", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: CARLOS G OTIS HEALTH CARE CENTER INC dba GRACE COTTAGE INC, CCN 471300 (CAH) -- the enrolment's DBA less 'Inc'.",
  "Grace Cottage Family Health and Hospital", "HOSPITAL_OR_SYSTEM", VT_GK, "VT",
  "HAND-READ BRIDGE, LOW, ACCEPTED BY THE OWNER (session 95, VT_S94_GRACE_COTTAGE_FAMILY_HEALTH_BRIDGE): bridged to Grace Cottage's enrolled critical access hospital, CCN 471300 (CMS Hospital Enrollment: CARLOS G OTIS HEALTH CARE CENTER INC, DBAs 'GRACE COTTAGE INC' and 'GRACE COTTAGE HOSPITAL'). No CMS enrolment carries the printed string; 'Grace Cottage Family Health & Hospital' is the organisation's public trade name by general knowledge, so the bridge is a reading, not a federal match (§2). The CCN is recorded here and NOT in the ccn column, which would mean a confirmed match (§7). Priced at LOW so a reader can subtract it.",
  "Gifford Medical Center", "HOSPITAL_OR_SYSTEM", VT_FED, "VT",
  "CMS Hospital Enrollment: GIFFORD MEDICAL CENTER INC, CCN 471301 (CAH), Randolph -- the enrolment's legal name less 'Inc'. The hospital, not GIFFORD HEALTH CARE INC (the FQHC).",
  "Gifford Health Care", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: GIFFORD HEALTH CARE INC, CCN 471852 -- the legal name less 'Inc'. THE FQHC, NOT THE HOSPITAL (GIFFORD MEDICAL CENTER INC, CCN 471301): its new $633,201.40 facility-upgrade agreement stays out of the hospital total on a federal record.",
  "UVM - Health Network", "HOSPITAL_OR_SYSTEM", VT_GK, "VT",
  "GENERAL KNOWLEDGE, LOW (session 94; the system-parent rule this file applies to 'THE UNIVERSITY OF VERMONT HEALTH NETWORK INC.'): the parent health system of UVM Medical Center (470003), Central Vermont Medical Center (470001) and others; not itself an enrolled provider, so no CCN. Priced at LOW so a reader can subtract it.",
  "Kinney Drugs", "OTHER", VT_GK, "VT",
  "RETAIL PHARMACY CHAIN, by general knowledge -- the trade name of KPH Healthcare Services Inc., typed OTHER elsewhere in this file. Not merged with that row (§2).",
  "Bennington Rescue Squad", "EMS_OR_PSAP", VT_GK, "VT",
  "Volunteer ambulance service (Bennington), by general knowledge and by its own name.",
  "Bristol Rescue Squad, Inc.", "EMS_OR_PSAP", VT_GK, "VT",
  "Ambulance service (Bristol), by general knowledge and by its own name.",
  "Bi-State Primary Care", "NONPROFIT_CBO", VT_GK, "VT",
  "Bi-State Primary Care Association, the nonprofit primary care association for Vermont and New Hampshire FQHCs, by general knowledge -- a determined form, not §8's fallback.",
  "Vermont Program for Quality in Health Care (VPQHC)", "NONPROFIT_CBO", VT_GK, "VT",
  "Nonprofit health-care quality-improvement organisation (VPQHC), by general knowledge; this agreement funds e-Consult / VTCPAP capacity.",
  "Behavioral Health Network of Vermont", "NONPROFIT_CBO", VT_GK, "VT",
  "Nonprofit network of Vermont's designated mental-health agencies (dba Vermont Care Network, as printed), by general knowledge. A network of agencies, not a provider.",
  "Real Time Medical Systems", "OTHER", VT_GK, NA,
  "PRIVATE HEALTH-INFORMATION-TECHNOLOGY COMPANY (post-acute care analytics), by general knowledge. Not VENDOR_OR_CONTRACTOR: the row is a support grant, not a supply contract to the State.",
  # ---- the two traps -------------------------------------------------------
  "1248 Hospital Drive Opco LLC", "OTHER", VT_FED, "VT",
  "NURSING FACILITY. CMS SNF Enrollment: 1248 HOSPITAL DRIVE OPCO LLC dba ST JOHNSBURY CENTER FOR LIVING AND REHABILITATION, CCN 475019B. 'Hospital' is the STREET in the LLC's name; §8's name rule returns HOSPITAL_OR_SYSTEM at HIGH and is wrong.",
  # ---- FQHCs ---------------------------------------------------------------
  "Community Health Centers of the Rutland Region", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: COMMUNITY HEALTH CENTERS OF THE RUTLAND REGION INC.",
  "Community Health Centers of Burlington, Inc.", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: COMMUNITY HEALTH CENTERS OF BURLINGTON INC, CCN 471800.",
  "Northern Counties Health Care", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: NORTHERN COUNTIES HEALTH CARE INC (St. Johnsbury Community Health Center and others).",
  "Little Rivers Health Care, Inc.", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: LITTLE RIVERS HEALTH CARE, INC.",
  "Richford Health Center Inc", "FQHC_OR_RHC", VT_FED, "VT",
  "CMS FQHC Enrollment: THE RICHFORD HEALTH CENTER, INC.",
  "Mountain Community Health", "FQHC_OR_RHC", VT_GK, "VT",
  "The page's own DBA is 'Five Town Health Alliance, INC' (CMS FQHC 471846); the bridge is the page's pairing plus a reading -- LOW.",
  # ---- nursing facilities --------------------------------------------------
  "105 Chester Road Opco LLC", "OTHER", VT_FED, "VT",
  "NURSING FACILITY. CMS SNF Enrollment: 105 CHESTER ROAD OPCO LLC dba SPRINGFIELD CENTER FOR LIVING AND REHABILITATION, CCN 475025B.",
  "46 NICHOLS STREET OPCO LLC", "OTHER", VT_FED, "VT",
  "NURSING FACILITY. CMS SNF Enrollment: 46 NICHOLS STREET OPCO LLC dba RUTLAND CENTER FOR LIVING AND REHABILITATION, CCN 475039.",
  "Rutland Center for Living and Rehabilitation", "OTHER", VT_FED, "VT",
  "NURSING FACILITY. CMS SNF Enrollment carries this string as the DBA of 46 NICHOLS STREET OPCO LLC, CCN 475039.",
  "CLR Opco", "OTHER", VT_FED, "VT",
  "NURSING FACILITY. CMS SNF Enrollment: CLR OPCO LLC dba CENTER FOR LIVING & REHABILITATION, Bennington, CCN 475029.",
  "The Manor", "OTHER", VT_FED, "VT",
  "NURSING FACILITY. CMS SNF Enrollment: THE MANOR INC, Morrisville, CCN 475057.",
  # ---- home health agencies ------------------------------------------------
  "VNA & Hospice of the Southwest Region, Inc.", "OTHER", VT_FED, "VT",
  "HOME HEALTH AGENCY. CMS HHA Enrollment: VNA & HOSPICE OF THE SOUTHWEST REGION, INC., CCN 477007.",
  "Central Vermont Home Health & Hospice", "OTHER", VT_FED, "VT",
  "HOME HEALTH AGENCY. CMS HHA Enrollment: CENTRAL VERMONT HOME HEALTH & HOSPICE, INC, CCN 477003.",
  "Lamoille Home Health & Hospice", "OTHER", VT_FED, "VT",
  "HOME HEALTH AGENCY. CMS HHA Enrollment: LAMOILLE HOME HEALTH AGENCY, INC. dba LAMOILLE HOME HEALTH & HOSPICE, CCN 477015.",
  "University of Vermont Health - Home Health & Hospice", "OTHER", VT_FED, "VT",
  "HOME HEALTH AGENCY. CMS HHA Enrollment: THE UNIVERSITY OF VERMONT HEALTH NETWORK HOME HEALTH & HOSPICE, INC., CCN 477000. The classifier's UNIVERSITY_OR_AHC reads 'University' and is wrong; a hospital system's home-health subsidiary is not the hospital (session 49's affiliated-arm test turns on a FOUNDATION of a named hospital, and this is a separately enrolled provider type).",
  "Dartmouth Health Home Care, Inc.", "OTHER", VT_GK, "NH",
  "HOME HEALTH AGENCY, by general knowledge (Dartmouth Health's home-care arm, New Hampshire-based; starred on the page as funding for Vermont patients). Not in CMS's VT HHA file under this name -- LOW.",
  # ---- designated mental-health agencies -----------------------------------
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
  "Bailit Health Purchasing, LLC.", "VENDOR_OR_CONTRACTOR", VT_GK, NA,
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
            VT_UPDATED_TXT)
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
      paste0("TYPED (session 54/74/94): ", ty$why, " Classifier said ",
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
    amount_basis = paste0("EXACT, as printed on AHS's list; the ", VT_PAGE_ROWS, " rows sum ",
                          "to the table's own total ($", format(VT_PAGE_TOTAL, big.mark = ",", nsmall = 2), ") to the cent."),
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
    paste(VT_PAGE_ROWS - 1L, "executed agreements to named recipients in the award file.",
          "The page calls itself 'a partial and ongoing list and does not",
          "represent the full Year 1 awards or funding decisions', so this is",
          "a FLOOR. Updated as of 2026-10-02 (145 award rows on 2026-09-25,",
          "111 on 2026-09-18)."),
    VT_STATE, "Northern Counties Health Care -- initiative re-filed (2026-10-02)",
    "AGREEMENT_REFILED_SAME_AMOUNT", "Yes", VT_NCHC_MOVE$amount,
    paste0("One executed agreement, $226,194.70, printed under '",
           VT_NCHC_MOVE$from[1], " / ", VT_NCHC_MOVE$from[2], "' on 2026-09-25 and under '",
           VT_NCHC_MOVE$to[1], " / ", VT_NCHC_MOVE$to[2], "' on 2026-10-02. Same recipient, ",
           "same amount, no other row carries it: read as one agreement re-filed ",
           "(session 94), not one ended and one begun. NCHC is an FQHC, so no ",
           "hospital figure moves. The award file carries the 2026-10-02 filing."),
    VT_STATE, "GMCB inter-agency MOU (NOT A SUBAWARD)",
    "INTER_AGENCY_NOT_SUBAWARD", "No", mou$amount,
    paste0("'", mou$legal, "' -- ", mou$activity, ". One state agency (AHS) ",
           "to another (the Green Mountain Care Board): not a Tier 3 award ",
           "to a subrecipient, kept OUT of the award file by owner decision ",
           "(session 54). The award rows + this = the page's printed total, $",
           format(VT_PAGE_TOTAL, big.mark = ",", nsmall = 2), "."),
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
          " -- ", VT_PAGE_ROWS, " executed agreements.")
  invisible(tibble::tibble(key = "awards", changed = changed))
}

#' Archive the live list VERBATIM into VT_ARCHIVE_DIR (session 94). Writes
#' data/evidence/ -- a deliberate act after READING what changed (§2.2), never
#' called by --probe. Refuses a credential-shaped string.
vt_fetch <- function(force = FALSE) {
  dest <- here::here(VT_AWARDS_FILE)
  if (file.exists(dest) && !force) {
    message("[VT] ", VT_AWARDS_FILE, " exists; --force to re-fetch.")
    return(invisible(dest))
  }
  resp <- httr::GET(VT_AWARDS_URL, httr::user_agent(VT_USER_AGENT),
                    httr::timeout(120))
  if (httr::status_code(resp) != 200L) {
    stop("[VT] HTTP ", httr::status_code(resp), " from the awards page.",
         call. = FALSE)
  }
  raw <- httr::content(resp, as = "raw")
  if (grepl("AIza[0-9A-Za-z_-]{20,}|pk\\.ey[0-9A-Za-z_-]{20,}|accessToken",
            rawToChar(raw))) {
    stop("[VT] the page carries a credential-shaped string; not archived.",
         call. = FALSE)
  }
  dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
  writeBin(raw, dest)
  man <- here::here(dirname(VT_ARCHIVE_DIR), "MANIFEST.txt")
  cat(paste0(digest::digest(raw, algo = "sha256", serialize = FALSE), "  ./VT/",
             basename(dest), "\n"), file = man, append = TRUE)
  message("[VT] archived ", length(raw), " bytes to ", VT_AWARDS_FILE)
  invisible(dest)
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
  if ("--fetch" %in% args) vt_fetch(force = "--force" %in% args)
  if ("--validate" %in% args) vt_validate()
  if ("--build" %in% args) vt_build()
  if ("--probe" %in% args) rhtp_probe_run("VT", vt_probe())
  if ("--report" %in% args) vt_report()
  if (!length(args)) message("Usage: --fetch [--force] | --validate | --build | --probe | --report")
}
