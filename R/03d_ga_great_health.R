# 03d_ga_great_health.R -----------------------------------------------------
# Georgia GREAT Health Program (Georgia's RHTP) -> Year 1 awardee table.
#
# Deliverable 1 for Georgia, in the schema of FL_year1_awardees.xlsx so the two
# states union without a reshape. Georgia is the second complete Deliverable 1
# dataset and the first assembled inside the repo rather than handed over as a
# finished workbook.
#
# SOURCES. Four DCH announcement pages, all archived verbatim with SHA-256
# under data/evidence/GA/ (§0.4, §0.5):
#
#   Phase 1  2026-06-08   $12,730,000   5 named awardees
#   Phase 2  2026-07-16   $30,600,000   26 organizations, initiatives 2-5
#   Phase 3  2026-07-23   $60,487,500   80 AHEAD hospitals at $750,000 + 1
#   Phase 4  2026-08-27   $93,330,827   all five initiatives, Year 1 complete
#
# They are AGENCY_PRESS_RELEASE under §8. Per §9.2 that supports a `Yes` only
# for a recipient the document NAMES, which is the whole of what is coded here.
#
# THE ONE THING TO UNDERSTAND ABOUT THIS STATE'S DATA. Georgia publishes an
# amount per INITIATIVE and then lists the awardees inside that initiative
# without splitting it. So `initiative_amount` is populated on every row and
# `amount` is populated on only the few rows where DCH states a recipient-level
# figure. §6.2 forbids dividing a pooled amount, and nothing here divides one:
# there is no per-fragment amount column for a sum to get wrong, exactly as in
# the §6.2 multi-recipient split. `amount_confirmed = No` on the pooled rows is
# the vocabulary's expected case -- "no recipient-level figure is published, not
# that verification failed" -- and is the same posture DE and OK sit in.
#
# Because of that, SUMMING `amount` DOES NOT GIVE GEORGIA'S TOTAL. Summing
# `initiative_amount` over distinct (phase, initiative) does.
# rhtp_ga_reconcile() is the function that does it correctly and it is what the
# Reconciliation sheet is built from; rhtp_ga_assert() hard-fails if anyone
# reaches the wrong total.
#
# THE 87 AHEAD HOSPITALS ARE TWO AGGREGATE ROWS, NOT 87 NAMED ROWS. Phase 3
# awards 80 rural hospitals $750,000 each and Phase 4 adds 7, completing a
# planned Year 1 group of 87. The roster is published at
# greathealth.georgia.gov/value-based-care-hospital-list, a host that is not on
# the egress allowlist (CONNECT rejected, 403) and could not be read in the
# session that built this file. Nothing is imputed: the count, the per-hospital
# figure and the hospital identity of the class are all stated by DCH. Allowlist
# that host and these two rows expand into 87 named rows -- $65.25M of directly
# hospital-bound money, the largest such block found in any state so far.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only -- never |>. No setwd(); all
# paths go through here::here(). Contains no network calls: it reads nothing off
# the wire and re-runs offline against the committed archive.
#
# CLI:
#   Rscript R/03d_ga_great_health.R --validate   # assertions only, no writes
#   Rscript R/03d_ga_great_health.R --build      # assertions, then write CSV + xlsx

suppressPackageStartupMessages({
  library(dplyr)
  library(openxlsx)
  library(purrr)
  library(readr)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))

# --- source documents ------------------------------------------------------

ga_source_url <- c(
  p1 = "https://dch.georgia.gov/announcement/2026-06-08/georgia-awards-first-great-health-program-subgrantees",
  p2 = "https://dch.georgia.gov/announcement/2026-07-16/georgia-issues-30-million-phase-2-great-health-awards-advance-rural",
  p3 = "https://dch.georgia.gov/announcement/2026-07-23/georgia-reaches-103-million-total-awards-date-expand-rural-healthcare",
  p4 = "https://dch.georgia.gov/announcement/2026-08-27/georgia-reaches-major-milestone-all-year-1-great-health-awards-fully"
)

ga_source_title <- c(
  p1 = "Georgia Awards First GREAT Health Program Subgrantees",
  p2 = "Georgia Issues $30 Million in Phase 2 GREAT Health Awards to Advance Rural Healthcare Transformation",
  p3 = "Georgia Reaches $103 Million in Total Awards to Date to Expand Rural Healthcare through GREAT Health Transformation",
  p4 = "Georgia Reaches Major Milestone with All Year 1 GREAT Health Awards Fully Committed"
)

ga_source_archive <- c(
  p1 = "data/evidence/GA/2026-06-08_great_health_phase1_first_subgrantees.html",
  p2 = "data/evidence/GA/2026-07-16_great_health_phase2_awards.html",
  p3 = "data/evidence/GA/2026-07-23_great_health_phase3_awards.html",
  p4 = "data/evidence/GA/2026-08-27_great_health_phase4_awards.html"
)

ga_phase_date <- c(
  p1 = "2026-06-08", p2 = "2026-07-16", p3 = "2026-07-23", p4 = "2026-08-27"
)

# Georgia's FY2026 CMS award, stated in the footnote of all four announcements.
GA_CMS_YEAR1_AWARD <- 218862169.63

# The Phase 2 page's own headline count of recipient organizations. The names
# printed on that page enumerate to 28 award actions across 27 distinct
# organizations (DBHDD is awarded under both Initiative 2 and Initiative 3), so
# DCH's count is one short of what its own page lists. The discrepancy is left
# standing and reported on the Reconciliation sheet rather than resolved by
# dropping a name: every organization coded here is printed on the page, and
# guessing which of the 27 DCH did not mean to count would be an invention.
GA_PHASE2_STATED_ORG_COUNT <- 26

# The five GREAT Health initiatives, as DCH names them.
ga_initiative_name <- c(
  "1" = "Transforming for a Sustainable Health System in Rural Georgia",
  "2" = "Strengthening the Continuum of Care in Rural Georgia",
  "3" = "Connecting to Care to Improve Healthcare Access in Rural Georgia",
  "4" = "Growing a Highly Skilled Healthcare Workforce in Rural Georgia",
  "5" = "Leveraging Technology for Healthcare Innovations in Rural Georgia"
)

# --- the record table ------------------------------------------------------
#
# One row per award action as DCH describes it. Kept in this file rather than a
# hand-edited CSV so that every change to a coding decision shows up as a diff
# a reviewer can read (§2.1). The CSV is a render of this, never the reverse.

rhtp_ga_records <- function() {
  tibble::tribble(
    ~phase, ~initiative_number, ~initiative_amount, ~awardee, ~recipient_count,
    ~amount, ~amount_basis, ~recipient_type, ~flow_type, ~distributed_to_hospital,
    ~hospital_benefiting, ~determination_confidence, ~recipient_confirmed,
    ~amount_confirmed, ~strategy, ~note, ~flag_reason,

    # -- Phase 1 (2026-06-08), $12,730,000 across five strategies ------------
    # The page does not map these to the numbered initiatives, so
    # initiative_number is NA rather than inferred. It states one pooled total
    # for all five, so initiative_amount carries the phase total and is
    # deduplicated on (phase, initiative) in the reconciliation.
    "1", NA_character_, 12730000, "Georgia Department of Public Health", 1L,
    NA_real_, "NOT_PUBLISHED", "STATE_AGENCY", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Public Health Investments: Georgia Newborn Screening Program",
    "Expands newborn screening at the Waycross laboratory. Recipient is the state health agency; the benefit is to rural families, not to a hospital (§10.2 judges the recipient).",
    NA_character_,

    "1", NA_character_, 12730000, "Side by Side", 1L,
    NA_real_, "NOT_PUBLISHED", "NONPROFIT_CBO", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Support for Acquired Brain Injury (ABI) Survivors",
    "Community-based brain injury program; funds the first rural ABI clubhouse.",
    NA_character_,

    "1", NA_character_, 12730000, "University System of Georgia", 1L,
    NA_real_, "NOT_PUBLISHED", "UNIVERSITY_OR_AHC", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Nursing Care Improvements",
    "Nurse Summer Camps to build the nursing pipeline.",
    NA_character_,

    "1", NA_character_, 12730000, "Georgia Statewide AHEC Network", 1L,
    NA_real_, "NOT_PUBLISHED", "AHEC", "NON_HOSPITAL", "No",
    "Yes", "HIGH", "Yes", "No",
    "Area Health Education Center (AHEC) Training & Housing",
    "Short-term housing for students in rural placements and Digital Health Navigator training. Rural sites host the placements, so hospitals benefit without receiving funds.",
    NA_character_,

    "1", NA_character_, 12730000, "Sharecare", 1L,
    NA_real_, "NOT_PUBLISHED", "VENDOR_OR_CONTRACTOR", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Consumer Engagement Enhancements",
    "Consumer wellness platform. A vendor receives the money and consumers use the product.",
    NA_character_,

    # -- Phase 2 (2026-07-16), Initiative 2, $4.6M --------------------------
    "2", "2", 4600000, "Georgia Health Information Network (GaHIN)", 1L,
    NA_real_, "NOT_PUBLISHED", "VENDOR_OR_CONTRACTOR", "NON_HOSPITAL", "No",
    "Yes", "MEDIUM", "Yes", "No",
    "Care coordination and cross-sector connection",
    "Statewide nonprofit health information exchange. Coded VENDOR_OR_CONTRACTOR for consistency with FL's CommunityHealth IT, which is the same kind of entity; recipient_type is inferred from the name and not stated by DCH.",
    NA_character_,

    "2", "2", 4600000, "Morehouse School of Medicine", 1L,
    NA_real_, "NOT_PUBLISHED", "UNIVERSITY_OR_AHC", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Care coordination and cross-sector connection", NA_character_, NA_character_,

    "2", "2", 4600000, "Georgia State University", 1L,
    NA_real_, "NOT_PUBLISHED", "UNIVERSITY_OR_AHC", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Care coordination and cross-sector connection", NA_character_, NA_character_,

    "2", "2", 4600000,
    "Georgia Department of Behavioral Health and Developmental Disabilities (DBHDD)", 1L,
    NA_real_, "NOT_PUBLISHED", "STATE_AGENCY", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Care coordination and cross-sector connection",
    "Transportation-to-treatment for people in mental health crisis.",
    NA_character_,

    "2", "2", 4600000, "Georgia Department of Education", 1L,
    NA_real_, "NOT_PUBLISHED", "STATE_AGENCY", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "School-based health infrastructure development",
    "§0.3a's worked contrast, in Georgia: school-based health infrastructure awarded to the Department of Education is NON_HOSPITAL because of the recipient, not the setting. Delaware's school-based health centre awarded to Beebe Healthcare is DIRECT.",
    NA_character_,

    # -- Phase 2, Initiative 3, $6.5M ---------------------------------------
    # 17 Rural Stabilization Grants to named rural hospitals, plus DBHDD.
    "2", "3", 6500000, "Appling Healthcare", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Clinch County Hospital Authority", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Colquitt Regional Medical Center", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Crisp Regional Hospital", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Dodge County Hospital", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Donalsonville Hospital, Inc.", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Effingham Hospital, Inc.", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Elbert Memorial Hospital", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000,
    "Hospital Authority of Jefferson County and the City of Louisville", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant",
    "Name contains ' and ' but is a single hospital authority, not two recipients -- the §6.2 delimiter split would be wrong here.",
    NA_character_,

    "2", "3", 6500000, "Jasper Health Services, Inc.", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Liberty Regional Medical Center", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Memorial Hospital and Manor", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant",
    "Name contains ' and ' but is one hospital (Bainbridge); not a §6.2 split.",
    NA_character_,

    "2", "3", 6500000, "Miller County Hospital", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Monroe County Hospital", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Putnam General Hospital", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "South Georgia Medical Center, Inc.", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Wills Memorial Hospital", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000,
    "Georgia Department of Behavioral Health and Developmental Disabilities (DBHDD)", 1L,
    NA_real_, "NOT_PUBLISHED", "STATE_AGENCY", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Mobile dental clinic",
    "DBHDD's second Phase 2 award; it also appears under Initiative 2. Two award actions, one organization.",
    NA_character_,

    # -- Phase 2, Initiative 4, $12.5M --------------------------------------
    "2", "4", 12500000, "Georgia Board of Health Care Workforce", 1L,
    NA_real_, "NOT_PUBLISHED", "STATE_AGENCY", "NON_HOSPITAL", "No",
    "Yes", "HIGH", "Yes", "No",
    "Graduate medical education expansion",
    "GME expansion places residents in rural hospitals, which benefit without receiving the award.",
    NA_character_,

    "2", "4", 12500000, "University System of Georgia", 1L,
    NA_real_, "NOT_PUBLISHED", "UNIVERSITY_OR_AHC", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Nursing education pathways and simulation-based clinical training",
    NA_character_, NA_character_,

    "2", "4", 12500000, "Alzheimer's Association", 1L,
    NA_real_, "NOT_PUBLISHED", "NONPROFIT_CBO", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Dementia care workforce development", NA_character_, NA_character_,

    # -- Phase 2, Initiative 5, $7M -----------------------------------------
    "2", "5", 7000000,
    "Georgia Cyber Innovation & Training Center at Augusta University", 1L,
    NA_real_, "NOT_PUBLISHED", "UNIVERSITY_OR_AHC", "IN_KIND_BENEFIT", "No",
    "Yes", "HIGH", "Yes", "No",
    "Cybersecurity enhancements for rural hospitals",
    "The source says the funding supports cybersecurity enhancements FOR rural hospitals. The university receives the money and hospitals receive the service: §10.2's in-kind test, met on its own terms. These dollars must never enter a funds-distributed-to-hospitals total.",
    NA_character_,

    "2", "5", 7000000, "Georgia Association of Emergency Medical Services", 1L,
    NA_real_, "NOT_PUBLISHED", "EMS_OR_PSAP", "NON_HOSPITAL", "No",
    "Yes", "HIGH", "Yes", "No",
    "EMS Treat-versus-Transport model",
    "Aims to reduce unnecessary emergency department utilisation; the benefit to hospitals is indirect.",
    NA_character_,

    # -- Phase 3 (2026-07-23), Initiative 1, $60M ---------------------------
    "3", "1", 60000000,
    "80 rural hospitals (AHEAD Model pre-implementation cohort) - names not captured", 80L,
    60000000, "STATED_PER_RECIPIENT", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "HIGH", "No", "Yes",
    "AHEAD Model pre-implementation funding",
    "DCH states 80 rural hospitals each awarded $750,000. 80 x $750,000 = $60,000,000, which closes on the stated initiative total independently. The roster is at greathealth.georgia.gov/value-based-care-hospital-list, a host not on the egress allowlist, so recipient_confirmed = No: the class is confirmed, the individual names are not captured. Expands to 80 named rows once that host is reachable.",
    "RECIPIENT_NAMES_NOT_CAPTURED",

    # -- Phase 3, Initiative 4, $487,500 ------------------------------------
    "3", "4", 487500, "Georgia Board of Health Care Workforce", 1L,
    487500, "SOLE_RECIPIENT_OF_INITIATIVE", "STATE_AGENCY", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "Yes",
    "GA-CARE nurse educator education awards",
    "Sole named recipient of the initiative, in collaboration with the University System of Georgia, so the initiative total is this recipient's amount.",
    NA_character_,

    # -- Phase 4 (2026-08-27), Initiative 1, $15,635,000 --------------------
    "4", "1", 15635000,
    "7 additional rural hospitals (AHEAD Model pre-implementation cohort) - names not captured", 7L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "HIGH", "No", "No",
    "AHEAD Model pre-implementation funding",
    "Completes the planned Year 1 group of 87. Phase 4 does not restate the $750,000 per-hospital figure, so no amount is carried: 7 x $750,000 = $5,250,000 would leave $10,385,000 for the readiness assessments below, but DCH states neither figure and neither is entered (§6.2 -- the amount is never divided).",
    "RECIPIENT_NAMES_NOT_CAPTURED",

    "4", "1", 15635000,
    "AHEAD readiness assessments for all 87 hospitals - provider not named", NA_integer_,
    NA_real_, "NOT_PUBLISHED", "NOT_YET_NAMED", "IN_KIND_BENEFIT", "No",
    "Yes", "MEDIUM", "No", "No",
    "Personalized AHEAD readiness assessments",
    "DCH funded assessments of all 87 hospitals but names no provider. The hospitals are assessed, not paid, so this is in-kind and never enters a distributed-to-hospitals total.",
    NA_character_,

    # -- Phase 4, Initiative 2, $6,209,688 ----------------------------------
    "4", "2", 6209688, "Georgia Health Care Association", 1L,
    NA_real_, "NOT_PUBLISHED", "NONPROFIT_CBO", "NON_HOSPITAL", "No",
    "No", "MEDIUM", "Yes", "No",
    "Regional Nursing Home Transportation Enhancement",
    "Long-term care trade association; the beneficiaries are nursing facility residents, not hospitals.",
    NA_character_,

    "4", "2", 6209688,
    "Type 2 ambulances - rural hospitals eligible to apply, not yet awarded", NA_integer_,
    NA_real_, "NOT_PUBLISHED", "NOT_YET_NAMED", "PASS_THROUGH_UNRESOLVED", "Unclear",
    "Yes", "LOW", "No", "No",
    "Type 2 ambulance procurement",
    "DCH completed the procurement and says select rural hospitals 'will be eligible to apply for soon'. §0.3 exactly: eligibility is not receipt. Unclear, and it must not be imputed to Yes.",
    "ELIGIBILITY_NOT_RECEIPT",

    "4", "2", 6209688,
    "Planning and actuarial development, Nutrition and Weight Management eligibility category - recipient not named", NA_integer_,
    NA_real_, "NOT_PUBLISHED", "NOT_YET_NAMED", "NON_HOSPITAL", "No",
    "No", "MEDIUM", "No", "No",
    "Planning for Healthy Babies demonstration",
    "Actuarial and planning work on a proposed Medicaid eligibility category. No recipient named.",
    NA_character_,

    "4", "2", 6209688, "Emory University", 1L,
    NA_real_, "NOT_PUBLISHED", "UNIVERSITY_OR_AHC", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Building Bridges (School-Based Health Care Services Infrastructure)",
    "The second §0.3a case in this file. School-based health infrastructure again, and again NON_HOSPITAL because Emory University is the recipient. Had DCH awarded it to a hospital system, as Delaware did to Beebe Healthcare, it would be DIRECT.",
    NA_character_,

    "4", "2", 6209688, "Behavioral Pediatric Resource Center", 1L,
    NA_real_, "NOT_PUBLISHED", "NONPROFIT_CBO", "NON_HOSPITAL", "No",
    "No", "LOW", "Yes", "No",
    "Rural Provider Nutrition Training for Autism Spectrum Disorder",
    "recipient_type inferred from the name and not stated by DCH; confidence LOW pending verification of the entity's form.",
    "RECIPIENT_TYPE_INFERRED",

    "4", "2", 6209688, "Georgia Department of Public Health", 1L,
    NA_real_, "NOT_PUBLISHED", "STATE_AGENCY", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Newborn Screening Investments (added funding)",
    "An addition to the Phase 1 award to the same agency.",
    NA_character_,

    # -- Phase 4, Initiative 3, $10,378,639 ---------------------------------
    "4", "3", 10378639,
    "8 hospitals (Care to Consumer Point-of-Care Telepods, 12 telepods) - names not captured", 8L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "HIGH", "No", "No",
    "Care to Consumer Point-of-Care Telepods",
    "DCH states grants to eight hospitals for 12 telepods but names none of them. The class is confirmed; the names are not published on this page.",
    "RECIPIENT_NAMES_NOT_CAPTURED",

    "4", "3", 10378639, "Georgia Hospital Association", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_AFFILIATED_ENTITY", "IN_KIND_BENEFIT", "No",
    "Yes", "HIGH", "Yes", "No",
    "Strengthening Perinatal Systems of Care",
    "GHA receives the grant and supplies obstetrical emergency carts to hospitals. Equipment reaches hospitals, dollars do not: §10.2 in-kind, hospital_benefiting = Yes.",
    NA_character_,

    "4", "3", 10378639, "Georgia Department of Public Health", 1L,
    NA_real_, "NOT_PUBLISHED", "STATE_AGENCY", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Public Health Telehealth Infrastructure",
    "Telehealth technology for rural public health sites, not hospitals.",
    NA_character_,

    "4", "3", 10378639,
    "Georgia Department of Behavioral Health and Developmental Disabilities (DBHDD)", 1L,
    NA_real_, "NOT_PUBLISHED", "STATE_AGENCY", "NON_HOSPITAL", "No",
    "Yes", "HIGH", "Yes", "No",
    "Rural Telepsychiatry (Project ECHO pediatric model)",
    "Trains rural providers; hospitals among the trained, but the award is to the agency.",
    NA_character_,

    "4", "3", 10378639, "Georgia Department of Public Health", 1L,
    NA_real_, "NOT_PUBLISHED", "STATE_AGENCY", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "PEACE for Moms (Perinatal Psychiatry, Education, Access and Community Engagement)",
    "DPH's second Initiative 3 award action.",
    NA_character_,

    # -- Phase 4, Initiative 4, $23,607,500 ---------------------------------
    "4", "4", 23607500, "Georgia Emergency Medical Services Association", 1L,
    NA_real_, "NOT_PUBLISHED", "EMS_OR_PSAP", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Emergency Services Education and Training Awards",
    "EMT and paramedic certification for rural students.",
    NA_character_,

    "4", "4", 23607500,
    "Nursing Care Improvements (clinical faculty orientation and training) - recipient not named", NA_integer_,
    NA_real_, "NOT_PUBLISHED", "NOT_YET_NAMED", "PASS_THROUGH_UNRESOLVED", "Unclear",
    "No", "LOW", "No", "No",
    "Nursing Care Improvements (added funding)",
    "Phase 4 adds funding to Nursing Care Improvements without naming a recipient. Phase 1 awarded that strategy to the University System of Georgia, but carrying that across phases would be an imputation, so it is not made (§0.3).",
    "RECIPIENT_NOT_NAMED",

    "4", "4", 23607500, "Georgia Board of Health Care Workforce", 1L,
    NA_real_, "NOT_PUBLISHED", "STATE_AGENCY", "NON_HOSPITAL", "No",
    "Yes", "HIGH", "Yes", "No",
    "Rural Provider Workforce and Graduate Medical Education Enhancements",
    "Rural hospitals host the GME placements this expands.",
    NA_character_,

    "4", "4", 23607500,
    "University System of Georgia and Georgia Board of Health Care Workforce (GA-CARE partnership)", 2L,
    NA_real_, "NOT_PUBLISHED", "UNIVERSITY_OR_AHC", "NON_HOSPITAL", "No",
    "No", "MEDIUM", "Yes", "No",
    "GA-CARE nursing faculty recruitment and development",
    "DCH describes one award to a two-party partnership. §6.2: the row names both and the amount is not divided between them. recipient_type follows the lead party.",
    "MULTI_RECIPIENT_FIELD",

    # -- Phase 4, Initiative 5, $37,500,000 ---------------------------------
    "4", "5", 37500000,
    "13 hospitals (Workforce Retention Technology, surgical robotics) - names not captured", 13L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "HIGH", "No", "No",
    "Workforce Retention Technology (surgical robotics)",
    "DCH, with the Georgia Board of Health Care Workforce, awarded 13 hospitals grants to purchase surgical robotics. Hospitals are the named class of recipient; individual names are not published on this page.",
    "RECIPIENT_NAMES_NOT_CAPTURED",

    "4", "5", 37500000, "Equifax", 1L,
    NA_real_, "NOT_PUBLISHED", "VENDOR_OR_CONTRACTOR", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Eligibility System Enhancements",
    "Reduces Medicaid eligibility determination delays. A vendor receives the money.",
    NA_character_
  ) %>%
    dplyr::mutate(
      state = "GA",
      phase_key = paste0("p", .data$phase),
      phase_date = unname(ga_phase_date[.data$phase_key]),
      initiative = dplyr::if_else(
        is.na(.data$initiative_number),
        NA_character_,
        unname(ga_initiative_name[.data$initiative_number])
      ),
      fiscal_year = "FY2026 (Year 1)",
      source_document_title = unname(ga_source_title[.data$phase_key]),
      state_source_url = unname(ga_source_url[.data$phase_key]),
      source_archive_path = unname(ga_source_archive[.data$phase_key]),
      validation_source_type = "AGENCY_PRESS_RELEASE",
      extraction_method = "MODEL_ASSISTED",
      validator = "AI-assisted - CONFIRM",
      ccn = NA_real_, aha_id = NA_real_,
      rural_designation = NA_character_, reviewer = NA_character_,
      determination_basis = paste0(
        "DCH ", .data$phase_date, " announcement, GREAT Health Phase ", .data$phase,
        dplyr::if_else(is.na(.data$initiative_number), "",
                       paste0(", Initiative ", .data$initiative_number)),
        ". ", dplyr::coalesce(.data$note, "Recipient named in the source; no recipient-level amount published.")
      )
    ) %>%
    dplyr::select(-"phase_key") %>%
    dplyr::mutate(row_no = dplyr::row_number()) %>%
    dplyr::select(
      # FL_year1_awardees.xlsx column order, so the two states union unchanged
      "state", "row_no", "awardee", "amount", "recipient_type",
      "distributed_to_hospital", "note", "recipient_confirmed", "amount_confirmed",
      "fiscal_year", "source_document_title", "state_source_url",
      "validation_source_type", "extraction_method", "validator",
      "ccn", "aha_id", "rural_designation", "reviewer",
      # Georgia-specific, appended
      "phase", "phase_date", "initiative_number", "initiative", "initiative_amount",
      "strategy", "recipient_count", "amount_basis", "flow_type",
      "hospital_benefiting", "determination_confidence", "determination_basis",
      "source_archive_path", "flag_reason"
    )
}

# --- reconciliation --------------------------------------------------------
#
# The only correct way to total Georgia. `amount` is recipient-level and mostly
# absent; the state's money is stated per initiative, so the total is the sum of
# distinct (phase, initiative) initiative_amount values.

rhtp_ga_reconcile <- function(records = rhtp_ga_records()) {
  by_initiative <- records %>%
    dplyr::distinct(.data$phase, .data$initiative_number, .data$initiative_amount) %>%
    dplyr::arrange(.data$phase, .data$initiative_number)

  awarded <- sum(by_initiative$initiative_amount)

  p2_distinct <- records %>%
    dplyr::filter(.data$phase == "2") %>%
    dplyr::distinct(.data$awardee) %>%
    nrow()

  tibble::tibble(
    line = c(
      "Georgia CMS FY2026 award",
      "GREAT Health Year 1 awarded (sum of initiative pools)",
      "Residual (administrative and programme costs)",
      "Residual as % of the CMS award",
      "Award actions in this table",
      "Distinct named organizations",
      "Hospital recipients - award actions",
      "Hospital recipients - hospitals covered",
      "Phase 2 distinct organizations enumerated",
      "Phase 2 distinct organizations per DCH"
    ),
    value = c(
      GA_CMS_YEAR1_AWARD,
      awarded,
      GA_CMS_YEAR1_AWARD - awarded,
      round(100 * (GA_CMS_YEAR1_AWARD - awarded) / GA_CMS_YEAR1_AWARD, 2),
      nrow(records),
      records %>%
        dplyr::filter(.data$recipient_count == 1L) %>%
        dplyr::distinct(.data$awardee) %>%
        nrow(),
      records %>% dplyr::filter(.data$distributed_to_hospital == "Yes") %>% nrow(),
      records %>%
        dplyr::filter(.data$distributed_to_hospital == "Yes") %>%
        dplyr::pull("recipient_count") %>%
        sum(na.rm = TRUE),
      p2_distinct,
      GA_PHASE2_STATED_ORG_COUNT
    ),
    note = c(
      "Stated in the footnote of all four DCH announcements",
      paste0("Phases 1-4; ", nrow(by_initiative), " initiative pools"),
      "DCH: 'less than 10% of Year 1's funding is dedicated to administrative costs'",
      "Independent closure on the DCH statement above",
      "One row per award action as DCH describes it",
      "Aggregate rows (multi-recipient cohorts) excluded from the count",
      "distributed_to_hospital = Yes",
      "Counts inside the 80/7/8/13 aggregate cohorts",
      "Names actually listed on the Phase 2 page (28 award actions; DBHDD twice)",
      "UNRECONCILED, off by one. The names on the page are what is coded."
    )
  )
}

# --- assertions ------------------------------------------------------------

rhtp_ga_assert <- function(records = rhtp_ga_records()) {
  fail <- function(...) stop("[GA] ", ..., call. = FALSE)

  # 1. Every categorical column validates against the §8 controlled vocabulary.
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "recipient_confirmed", "amount_confirmed", "extraction_method")) {
    allowed <- rhtp_vocabulary(col)
    seen <- stats::na.omit(unique(records[[col]]))
    bad <- setdiff(seen, allowed)
    if (length(bad)) {
      fail("`", col, "` carries values outside the vocabulary: ",
           paste(bad, collapse = ", "))
    }
  }

  # 2. The initiative pools reconcile to the phase totals DCH published.
  #    Phases 1 and 2 are stated to $0.1M in the source, so they are compared at
  #    that precision; phases 3 and 4 are stated to the dollar.
  stated <- c("1" = 12730000, "2" = 30600000, "3" = 60487500, "4" = 93330827)
  got <- records %>%
    dplyr::distinct(.data$phase, .data$initiative_number, .data$initiative_amount) %>%
    dplyr::group_by(.data$phase) %>%
    dplyr::summarise(total = sum(.data$initiative_amount), .groups = "drop")
  for (i in seq_len(nrow(got))) {
    ph <- got$phase[i]
    if (abs(got$total[i] - stated[[ph]]) > 1) {
      fail("Phase ", ph, " initiative pools sum to ", format(got$total[i], big.mark = ","),
           " against a stated ", format(stated[[ph]], big.mark = ","))
    }
  }

  # 3. The awarded total leaves a residual under 10% of the CMS award, which is
  #    the independent check on DCH's own administrative-cost statement.
  awarded <- sum(got$total)
  residual_pct <- 100 * (GA_CMS_YEAR1_AWARD - awarded) / GA_CMS_YEAR1_AWARD
  if (residual_pct < 0 || residual_pct >= 10) {
    fail("Residual after Year 1 awards is ", round(residual_pct, 2),
         "% of the CMS award; DCH states administrative costs are under 10%.")
  }

  # 4. Georgia's CMS figure matches the §7.1 anchor. Tier 1 comes from CMS,
  #    never from a state press release (§0.2a) -- this is the cross-check.
  anchor <- readr::read_csv(
    here::here("data", "reference", "cms_fy2026_allotments.csv"),
    show_col_types = FALSE
  )
  ga_anchor <- anchor %>%
    dplyr::filter(dplyr::if_any(dplyr::everything(),
                                ~ .x %in% c("GA", "Georgia"))) %>%
    dplyr::select(dplyr::where(is.numeric)) %>%
    unlist() %>%
    unname()
  ga_anchor <- ga_anchor[ga_anchor > 1e6]
  if (length(ga_anchor) != 1 || abs(ga_anchor[1] - GA_CMS_YEAR1_AWARD) > 1) {
    fail("Georgia's CMS FY2026 allotment in the §7.1 anchor is ",
         paste(format(ga_anchor, big.mark = ","), collapse = "/"),
         " but the DCH announcements state ",
         format(GA_CMS_YEAR1_AWARD, big.mark = ","), ".")
  }

  # 5. NO AMOUNT IS EVER DIVIDED (§6.2). A row may only carry an `amount` when
  #    the state stated a recipient-level figure -- never a share of a pool.
  divided <- records %>%
    dplyr::filter(!is.na(.data$amount), .data$amount_basis == "NOT_PUBLISHED")
  if (nrow(divided)) {
    fail(nrow(divided), " row(s) carry an amount with amount_basis NOT_PUBLISHED. ",
         "A pooled initiative amount must never be split across its recipients.")
  }
  if (any(!is.na(records$amount) & records$amount_confirmed != "Yes")) {
    fail("A row carries an amount without amount_confirmed = Yes.")
  }

  # 6. Eligibility is never receipt (§0.3): no PASS_THROUGH_UNRESOLVED row may
  #    be coded Yes.
  imputed <- records %>%
    dplyr::filter(.data$flow_type == "PASS_THROUGH_UNRESOLVED",
                  .data$distributed_to_hospital == "Yes")
  if (nrow(imputed)) {
    fail(nrow(imputed), " unresolved pass-through row(s) coded Yes. §0.3 forbids it.")
  }

  # 7. IN_KIND_BENEFIT never counts as distribution, and always flags the
  #    benefit (§10.2).
  in_kind <- records %>% dplyr::filter(.data$flow_type == "IN_KIND_BENEFIT")
  if (any(in_kind$distributed_to_hospital != "No") ||
      any(in_kind$hospital_benefiting != "Yes")) {
    fail("An IN_KIND_BENEFIT row is not coded No / hospital_benefiting = Yes.")
  }

  # 8. Every row is evidence-backed: an archived local copy, and a mandatory
  #    free-text determination_basis (§0.4, §10.2).
  missing_archive <- records$source_archive_path %>%
    unique() %>%
    purrr::discard(~ file.exists(here::here(.x)))
  if (length(missing_archive)) {
    fail("Archived source missing from disk: ", paste(missing_archive, collapse = ", "))
  }
  if (any(is.na(records$determination_basis) |
          !nzchar(records$determination_basis))) {
    fail("determination_basis is mandatory and is empty on at least one row.")
  }

  # 9. The 87-hospital AHEAD cohort is accounted for exactly once, across the
  #    two phases that announce it.
  ahead <- records %>%
    dplyr::filter(stringr::str_detect(.data$awardee, "AHEAD Model pre-implementation"))
  if (sum(ahead$recipient_count, na.rm = TRUE) != 87L) {
    fail("The AHEAD cohorts sum to ", sum(ahead$recipient_count, na.rm = TRUE),
         " hospitals; DCH states a planned Year 1 group of 87.")
  }

  # 10. The enumerated Phase 2 organization count is pinned. It does not match
  #     DCH's own headline of 26 and is not expected to -- the point of pinning
  #     it is that if a later edit changes the enumeration, the change is
  #     deliberate and visible rather than quietly closing a gap that is real.
  p2 <- records %>% dplyr::filter(.data$phase == "2")
  if (nrow(p2) != 28L || dplyr::n_distinct(p2$awardee) != 27L) {
    fail("Phase 2 enumerates ", nrow(p2), " award actions across ",
         dplyr::n_distinct(p2$awardee), " organizations; the page as read gives ",
         "28 and 27 (against DCH's stated ", GA_PHASE2_STATED_ORG_COUNT, ").")
  }

  invisible(TRUE)
}

# --- build -----------------------------------------------------------------

rhtp_ga_write <- function() {
  records <- rhtp_ga_records()
  rhtp_ga_assert(records)

  csv_path <- here::here("data", "reference", "ga_great_health_awards.csv")
  readr::write_csv(records, csv_path, na = "")

  hospitals <- records %>%
    dplyr::filter(.data$distributed_to_hospital == "Yes") %>%
    dplyr::select("phase", "initiative_number", "awardee", "recipient_count",
                  "amount", "recipient_confirmed", "flag_reason")

  by_type <- records %>%
    dplyr::count(.data$recipient_type, name = "award_actions") %>%
    dplyr::arrange(dplyr::desc(.data$award_actions))

  by_phase <- records %>%
    dplyr::distinct(.data$phase, .data$phase_date, .data$initiative_number,
                    .data$initiative, .data$initiative_amount) %>%
    dplyr::arrange(.data$phase, .data$initiative_number)

  wb <- openxlsx::createWorkbook()
  hdr <- openxlsx::createStyle(textDecoration = "bold", halign = "left")
  money <- openxlsx::createStyle(numFmt = "#,##0")

  add <- function(name, df, money_cols = character()) {
    openxlsx::addWorksheet(wb, name)
    openxlsx::writeData(wb, name, df, headerStyle = hdr)
    for (mc in intersect(money_cols, names(df))) {
      openxlsx::addStyle(wb, name, money, rows = 2:(nrow(df) + 1),
                         cols = which(names(df) == mc), gridExpand = TRUE)
    }
    openxlsx::freezePane(wb, name, firstActiveRow = 2)
    openxlsx::setColWidths(wb, name, cols = seq_along(df), widths = "auto")
  }

  add(paste0("Awardees (", nrow(records), ")"), records,
      c("amount", "initiative_amount"))
  add("Reconciliation", rhtp_ga_reconcile(records), "value")
  add("By phase and initiative", by_phase, "initiative_amount")
  add("By recipient type", by_type)
  add(paste0("Hospitals (", nrow(hospitals), ")"), hospitals, "amount")

  xlsx_path <- here::here("GA_year1_awardees.xlsx")
  openxlsx::saveWorkbook(wb, xlsx_path, overwrite = TRUE)

  message("[GA] wrote ", nrow(records), " award actions")
  message("[GA]   ", csv_path)
  message("[GA]   ", xlsx_path)
  invisible(list(csv = csv_path, xlsx = xlsx_path, records = records))
}

# --- CLI -------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--build" %in% args) {
    rhtp_ga_write()
  } else if ("--validate" %in% args) {
    rhtp_ga_assert()
    recs <- rhtp_ga_records()
    message("[GA] ", nrow(recs), " award actions; all assertions pass.")
    print(rhtp_ga_reconcile(recs), n = Inf)
  } else {
    message("Usage: Rscript R/03d_ga_great_health.R [--validate | --build]")
  }
}
