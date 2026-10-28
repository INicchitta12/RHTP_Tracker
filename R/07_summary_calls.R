# 07_summary_calls.R ----------------------------------------------------------
# Session 110. THE SUMMARY-CALL LAYER: A HOSPITAL / NOT_HOSPITAL CALL ON EVERY
# AWARD ROW, WITHOUT TOUCHING THE STRICT CODING.
#
# The Year 1 summary table (due 2026-11-02) may carry no unknown or unclear
# hospital status (owner instruction). This script writes three columns onto
# every file in STATE_FILES (tests/testthat/test_state_union.R) through ONE
# shared function, rhtp_summary_calls() (R/utils_summary_calls.R):
#
#   summary_hospital_call   HOSPITAL | NOT_HOSPITAL
#   summary_call_basis      CODED (the strict determination carries over) |
#                           BEST_JUDGMENT (a written reading, below)
#   summary_call_rationale  one sentence, required for BEST_JUDGMENT
#
# THE STRICT PARTITION IS UNCHANGED BY CONSTRUCTION: nothing here writes
# recipient_type, flow_type, distributed_to_hospital, confidence or
# hospital_attribution, and rhtp_hospital_dollar_partition() never reads the
# summary columns.
#
# WHAT A BEST_JUDGMENT CALL MAY USE (owner, session 110): CMS enrolment, the
# recipient's own site, the award text, general knowledge, and the owner's
# standing rulings -- hospital associations, hospital networks and fundraising
# foundations count as hospitals; academic health centres count (flagged);
# system parents count; EMS run by a hospital counts; universities, FQHCs,
# vendors and state agencies do not. A joint or shared award (one amount,
# several recipients) is called on its lead or majority recipient, says so,
# and is never split.
#
# THREE KINDS OF JUDGMENT, IN THIS ORDER OF WEIGHT:
#   1. SC_JUDGMENTS -- a written call on a named row, with the strongest
#      counter-argument beside it (the review list prints both).
#   2. SC_POOLS -- a shared pool priced ONLY at pool level whose members are
#      rows of the file at no amount (Georgia's three mixed pools, Ohio's two
#      shared sub-pools, Indiana GROW's eight regions, North Carolina's SBHC
#      pool). The pool is called on its majority member and its dollars are
#      counted whole on that call, once, in R/08 -- never on a row, never
#      divided. A pool whose members carry priced rows elsewhere (South
#      Dakota's Rural Strong round) is NOT here: adding it would count the
#      priced contracts twice.
#   3. The DEFAULT for a row whose ONLY open question is an unstated form
#      (§8's standing fallback, RECIPIENT_TYPE_INFERRED, coded No): if its
#      name carries no hospital marker and no archived CMS hospital enrolment
#      in its state carries the name, it is called NOT_HOSPITAL. A marker or
#      an enrolment hit refuses the default and demands a written judgment.
#
# EVERY OPEN QUEUE QUESTION IS ACCOUNTED FOR: SC_OPEN_QUEUE maps each OPEN
# question in classification_review_queue.csv to its rows, or SC_QUEUE_EXEMPT
# says why it is not a question about hospital status. A new OPEN question
# fails --validate until it is placed in one or the other.
#
# Usage:
#   Rscript R/07_summary_calls.R --apply     # write the three columns (LAST
#                                            # overlay: after every --build and
#                                            # every other overlay)
#   Rscript R/07_summary_calls.R --validate  # committed columns == computed
#   Rscript R/07_summary_calls.R --review    # data/reference/summary_calls_for_review.csv:
#                                            # every BEST_JUDGMENT over $1M, every strict-Unclear
#                                            # row, and the rows the owner named (SC_REVIEW_ALWAYS)
#   Rscript R/07_summary_calls.R --missing   # rows still needing a judgment
#   Rscript R/07_summary_calls.R --report

suppressPackageStartupMessages({
  library(dplyr)
})
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))
source(here::here("R", "utils_summary_calls.R"))

SC_REVIEW_CSV <- "data/reference/summary_calls_for_review.csv"
SC_POOLS_CSV  <- "data/reference/summary_call_pools.csv"
SC_QUEUE_CSV  <- "data/reference/classification_review_queue.csv"
SC_REVIEW_FLOOR <- 1000000

#' The state files, read from the union test so the two cannot drift apart
sc_state_files <- function() {
  tf <- readLines(here::here("tests/testthat/test_state_union.R"))
  i0 <- grep("^STATE_FILES <- c\\(", tf)
  i1 <- i0 + which(grepl("^\\)", tf[(i0 + 1):length(tf)]))[1]
  eval(parse(text = tf[i0:i1]))
  STATE_FILES
}

# -- the open review queue ------------------------------------------------------

# Each OPEN question, and the rows it names. `awardee` is exact; NA means the
# question covers every RECIPIENT_TYPE_INFERRED row of the file, which the
# FORM_INFERRED reason already routes to a judgment.
SC_OPEN_QUEUE <- tibble::tribble(
  ~question_id, ~file_key, ~awardee,
  "MI_MHA_FLOW", "MI", "Michigan Health and Hospital Association (MHA)",
  "ME_UNE_HOSPITAL_TO_HOME_FLOW", "ME", "University of New England (Shaw Institute for Public and Planetary Health)",
  "NC_HUB_LEAD_FORM_NOT_IN_VOCABULARY", "NC", "Access East, Inc.",
  "KS_CITIZENS_FOUNDATION_TWO_SPELLINGS", "KS", "Citizens Foundation",
  "NV_UNIDENTIFIED_RECIPIENT", "NV", "93 X 95 NV",
  "UF_FORM_NOT_DETERMINABLE", "MS", "CAMHP Foundation",
  "UF_FORM_NOT_DETERMINABLE", "MS", "Delta Health Transformation Council, Inc.",
  "SC_ACADIA_PARENT_SCOPE", "SC", "Acadia Healthcare Co.",
  "WA_WSHA_FLOW", "WA", "Washington State Hospital Association",
  "NJ_RECIPIENT_FORM_NOT_STATED", "NJ", NA,
  "NJ_VIRTUA_PARENT_BRIDGE", "NJ", "Virtua Health Inc.",
  "IN_GROW_HOSPITAL_BRIDGES", "IN_GROW", "Goshen Health System",
  "IN_GROW_HOSPITAL_BRIDGES", "IN_GROW", "Northwest Health Starke Hospital",
  "IN_GROW_HOSPITAL_BRIDGES", "IN_GROW", "Franciscan Health Foundation",
  "IN_GROW_HOSPITAL_BRIDGES", "IN_GROW", "Union Health Inc.",
  "IN_GROW_HOSPITAL_BRIDGES", "IN_GROW", "St. Elizabeth Dearborn",
  "IN_GROW_HOSPITAL_BRIDGES", "IN_GROW", "Ascension St. Vincent",
  "IN_GROW_CMHC_HOLDS_HOSPITAL_CCN", "IN_GROW", "Northeastern Center",
  "IN_GROW_CMHC_HOLDS_HOSPITAL_CCN", "IN_GROW", "Hamilton Center, Inc.",
  "IN_GROW_CMHC_HOLDS_HOSPITAL_CCN", "IN_GROW", "INcompass Healthcare",
  "IN_GROW_RECIPIENT_FORM_NOT_STATED", "IN_GROW", NA,
  "NE_5_3_FORM_NOT_STATED", "NE", NA,
  "NE_WINNEBAGO_TRIBE_HOSPITAL_SCOPE", "NE", "Winnebago Tribe of Nebraska DBA Winnebago Comprehensive Healthcare System",
  "NV_RECIPIENT_FORM_NOT_STATED_0924", "NV", NA,
  "LA_RECIPIENT_FORM_NOT_STATED", "LA", NA,
  "AR_R2_QUEUED_FORM", "AR_R2", "University of Arkansas for Medical Sciences",
  "AR_R2_QUEUED_FORM", "AR_R2", "CARTI",
  "AR_R2_RECIPIENT_FORM_NOT_STATED", "AR_R2", NA,
  "VT_S74_LOW_HOSPITAL_TYPINGS", "VT", "Southwestern Vermont Health",
  "AK_KETCHIKAN_ALL_TYPES_TICKED", "AK", "City of Ketchikan",
  "CO_HOSPITAL_DISTRICT_NO_HOSPITAL_ENROLMENT", "CO", "Walsh Hospital District",
  "CO_HOSPITAL_DISTRICT_NO_HOSPITAL_ENROLMENT", "CO", "West Custer County Hospital District",
  "CO_HOSPITAL_DISTRICT_NO_HOSPITAL_ENROLMENT", "CO", "Telluride Regional Medical Center",
  "CO_RECIPIENT_FORM_NOT_STATED", "CO", NA,
  "AL_R2_GREENE_COUNTY_HEALTH_SYSTEM_BRIDGE", "AL_R2", "Greene County Health System",
  "AL_R2_RECIPIENT_FORM_NOT_STATED", "AL_R2", NA,
  "CA_FM_OB_FRESNO_SPONSOR_NOT_NAMED", "CA", "Maternal Child Health Fellowship: Fresno Family Medicine Obstetrics")

# OPEN questions that are not about any award row's hospital status.
SC_QUEUE_EXEMPT <- tibble::tribble(
  ~question_id, ~why,
  "MO_ANCHOR_IS_NOT_AN_AWARD", "mo_hub_anchors.csv is not an award file (never in STATE_FILES).",
  "ME_RHEF_COHORT_IS_NOT_AN_AWARD", "me_rhef_cohort.csv is not an award file (never in STATE_FILES).",
  "TX_BP1_DISTRICT_ENROLMENT", "tx_bp1_first_tier_floor.csv is a floor report, not an award file.",
  "CO_ROSTER_VS_RELEASE_TOTAL", "A question about Colorado's round TOTAL ($623,394.26), not about any row's hospital status.",
  "SD_CCBHC_COHORT_13_VS_12_GRANTS", "A question about the grant COUNT; every cohort row's hospital status is settled and no row is priced.")

sc_open_queue <- function() {
  q <- readr::read_csv(here::here(SC_QUEUE_CSV), col_types = readr::cols(.default = "c"),
                       progress = FALSE)
  q$question_id[q$queue_status == "OPEN"]
}

#' Every OPEN question is mapped or exempt; every mapping names an OPEN one.
sc_assert_queue_covered <- function(open_ids = sc_open_queue()) {
  placed <- union(SC_OPEN_QUEUE$question_id, SC_QUEUE_EXEMPT$question_id)
  loose <- setdiff(open_ids, placed)
  if (length(loose)) {
    stop("[summary calls] OPEN queue question(s) not placed in SC_OPEN_QUEUE or ",
         "SC_QUEUE_EXEMPT: ", paste(loose, collapse = ", "), call. = FALSE)
  }
  stale <- setdiff(placed, open_ids)
  if (length(stale)) {
    stop("[summary calls] SC_OPEN_QUEUE / SC_QUEUE_EXEMPT name question(s) that are ",
         "no longer OPEN: ", paste(stale, collapse = ", "), ". Remove them.", call. = FALSE)
  }
  invisible(TRUE)
}

sc_open_rows <- function(d, key) {
  m <- SC_OPEN_QUEUE[SC_OPEN_QUEUE$file_key == key, ]
  if (!nrow(m)) return(rep(FALSE, nrow(d)))
  named <- m$awardee[!is.na(m$awardee)]
  miss <- setdiff(named, d$awardee)
  if (length(miss)) {
    stop("[summary calls] ", key, ": queue rows not in the file: ",
         paste(miss, collapse = "; "), call. = FALSE)
  }
  # A question mapped with awardee = NA covers the file's
  # RECIPIENT_TYPE_INFERRED rows, which FORM_INFERRED already routes to a
  # judgment; it adds no reason of its own, so the default rule still reads
  # them.
  d$awardee %in% named
}

# -- CMS hospital enrolment, for the default rule -------------------------------

sc_norm <- function(x) {
  x <- toupper(x)
  x <- gsub("[^A-Z0-9 ]", " ", x)
  x <- gsub("\\b(INC|LLC|THE|CORP|CORPORATION|CO|LTD|PLLC|PC|PA)\\b", " ", x)
  stringr::str_squish(x)
}

#' The latest archived CMS Hospital Enrollment file for each state
sc_enrolment <- function() {
  fs <- list.files(here::here("data/evidence/federal_records"),
                   "^cms_hosp_enrollments_[A-Z]{2}\\.json$", recursive = TRUE, full.names = TRUE)
  st <- sub("^cms_hosp_enrollments_([A-Z]{2})\\.json$", "\\1", basename(fs))
  latest <- tapply(fs, st, function(x) sort(x, decreasing = TRUE)[1])
  dplyr::bind_rows(lapply(names(latest), function(s) {
    j <- jsonlite::fromJSON(latest[[s]])
    tibble::tibble(state = s, file = sub(paste0(here::here(), "/"), "", latest[[s]]),
                   org = sc_norm(j$`ORGANIZATION NAME`),
                   dba = sc_norm(dplyr::coalesce(j$`DOING BUSINESS AS NAME`, "")))
  }))
}

sc_default_rationale <- function(st, enr) {
  e <- enr[enr$state == st, ]
  function(awardee) {
    n <- sc_norm(awardee)
    if (nrow(e) && (n %in% e$org || n %in% e$dba)) {
      stop("[summary calls] '", awardee, "' (", st, ") is a CMS hospital enrolment ",
           "name: the default refuses it; write a judgment.", call. = FALSE)
    }
    paste0("The source states no form, the name carries no hospital marker",
           if (nrow(e)) paste0(" and no archived CMS ", st, " Hospital Enrollment record carries it")
           else paste0(" and no CMS ", st, " hospital enrolment file is archived to say otherwise"),
           ", so it is called a non-hospital (§8 standing-fallback row).")
  }
}
SC_DEFAULT_COUNTER <- paste(
  "The form is undetermined: if the recipient proves to be hospital-owned, a",
  "hospital's foundation or a network of hospitals, the call reverses.")

# -- written judgments -----------------------------------------------------------
# Built by helpers so the reading of each class is written once.

sc_j <- function(file_key, awardee, call, rationale, counter, row_no = NA_character_) {
  tibble::tibble(file_key = file_key, awardee = awardee, row_no = as.character(row_no),
                 call = call, rationale = rationale, counter = counter)
}

# New York RCHI: the roster names only the lead, and RCHI required a hospital
# partner in every award (§7, the third eligible class). Called on the lead.
sc_ny <- function(awardee, form, counter = NULL) {
  sc_j("NY", awardee, "NOT_HOSPITAL",
       paste0("The RCHI lead applicant is ", form, ", not a hospital, and the award is called on its lead; RCHI's required hospital partner is not named."),
       if (is.null(counter)) "RCHI required a hospital in every partnership, so part of the award may reach the unnamed partner hospital." else counter)
}

# Virginia's Mobile & Hybrid Care first-tier partners: planning district
# commissions and regional collaboratives, no amounts (owner ruling, session 109).
sc_va_collab <- function(awardee) {
  sc_j("VA", awardee, "NOT_HOSPITAL",
       "A planning district commission or regional collaborative (local government) administering an open RFA; not a hospital. No dollars on the row.",
       "Its eventual subrecipients may include hospitals.")
}

SC_JUDGMENTS <- dplyr::bind_rows(
  sc_j("GA", "Type 2 ambulances - rural hospitals eligible to apply, not yet awarded", "HOSPITAL",
       "DCH's eligible class for this procurement is select rural hospitals, so any award from it goes to a hospital; the row carries no dollars.",
       "Nothing has been awarded and eligibility is not receipt (§0.3)."),
  sc_j("GA", "Nursing Care Improvements (clinical faculty orientation and training) - recipient not named", "NOT_HOSPITAL",
       "Phase 1 awarded this strategy to the University System of Georgia, the likeliest recipient again; the row carries no dollars.",
       "Clinical faculty orientation could be paid to the hospitals that host clinical placements."),
  sc_j("GA", "AHEAD readiness assessments for all 87 hospitals - provider not named", "NOT_HOSPITAL",
       "The 87 hospitals are assessed, not paid; the unnamed provider is an assessor (in-kind), and the row carries no dollars.",
       "Every beneficiary is a hospital."),
  sc_j("GA", "Planning and actuarial development, Nutrition and Weight Management eligibility category - recipient not named", "NOT_HOSPITAL",
       "Actuarial and planning work on a proposed Medicaid eligibility category is contractor or state work; the row carries no dollars.",
       "None."),
  sc_j("GA", "University System of Georgia and Georgia Board of Health Care Workforce (GA-CARE partnership)", "NOT_HOSPITAL",
       "Joint award called on its lead, the University System of Georgia; neither party is a hospital.",
       "None."),
  sc_j("SD_ANNOUNCEMENTS", "28 grants (Rural Strong project grants) to 20 health systems - recipient names not published", "HOSPITAL",
       "The Governor says the 28 Rural Strong grants fund projects across 20 health systems, so the majority recipient is a hospital system; the row carries no dollars because the $31.5M overlaps contracts already priced in sd_rht_contracts.csv.",
       "The release names nobody and SD's register shows non-hospital Rural Strong contracts inside the same $31.5M."),
  sc_j("SD_ANNOUNCEMENTS", "82 grants (Technology and data grants) to 82 rural healthcare organizations - recipient names not published", "NOT_HOSPITAL",
       "The release describes a mixed class (providers, Regional Innovation Centers, aging services, academic and technology partners), so no hospital majority can be shown; the row carries no dollars.",
       "Most rural healthcare organisations in South Dakota are hospital-owned (Sanford, Avera, Monument)."),
  sc_j("MI", "Michigan Health and Hospital Association (MHA)", "HOSPITAL",
       "The Michigan Health and Hospital Association is the state hospital association, and the owner's standing ruling counts hospital associations as hospitals.",
       "MDHHS never says the $8.625M reaches member hospitals; MHA may spend it on its own programmes, which §10.2 would code NON_HOSPITAL or IN_KIND_BENEFIT."),
  sc_j("OR", "Alano Club, Comagine Health, Tabor North", "NOT_HOSPITAL",
       "Joint award called on its lead, Alano Club (a recovery club); none of the three named parties is a hospital.",
       "None."),
  sc_j("OR", "Northwest Regional ESD, Clatsop Community College, Providence Seaside Hospital, Seaside School District", "NOT_HOSPITAL",
       "Joint award called on its lead, Northwest Regional ESD; three of the four named parties are education bodies.",
       "Providence Seaside Hospital is a named party, and its share is unknown."),
  sc_j("OR", "Oregon Rural Practice-based Research Network (ORPRN), Oregon Community Health Workers' Association (ORCHWA), Familia's en Acción, and Oregon Wellness Network (OWN)", "NOT_HOSPITAL",
       "Joint award called on its lead, ORPRN, an OHSU research programme (owner ruling a: a programme is not a hospital); the other three are nonprofits.",
       "ORPRN sits inside OHSU, an enrolled hospital operator."),
  sc_j("OR", "Mercy Flights, & additional partners TBD", "NOT_HOSPITAL",
       "Joint award called on its lead, Mercy Flights, an independent nonprofit ambulance service, not hospital-run EMS.",
       "The unnamed partners could include hospitals."),
  sc_j("OR", "Not identified in the source", "NOT_HOSPITAL",
       "An aggregate of unnamed tribal governments or local public health authorities, neither of them hospitals; the row carries no dollars.",
       "None.", row_no = NA),
  sc_j("OR", "Regional Partners", "NOT_HOSPITAL",
       "Unnamed regional partners of a pool OHA describes as community organisations; the row carries no dollars.",
       "Regional partners could include hospitals."),
  sc_j("OR", "School-Based Health Center Planning Grants", "NOT_HOSPITAL",
       "Planning grants for school-based health centres go to sponsors that are mostly FQHCs, schools and health departments; the row carries no dollars.",
       "Some SBHC sponsors are hospitals."),
  sc_j("MS", "Delta Health Transformation Council, Inc.", "HOSPITAL",
       "Its $3M funds robotic-assisted surgery in Washington County, which only a hospital can deliver, and its name tracks Delta Health System (DELTA HEALTH-THE MEDICAL CENTER, CCN 250082, Greenville); read as that hospital's affiliated arm.",
       "No record establishes the affiliation (sessions 50-51 could not determine the form); the council could be a community coalition buying equipment for a hospital, which is in-kind."),
  sc_j("MS_R2", "Delta Health Transformation Council, Inc.", "HOSPITAL",
       "The same recipient as round 1's robotic-surgery award, read as Delta Health System's affiliated arm; this award funds a Delta Earn While You Learn workforce initiative.",
       "No record establishes the affiliation; a regional workforce council is more often a coalition than a hospital arm."),
  sc_j("MS", "CAMHP Foundation", "NOT_HOSPITAL",
       "A behavioral-health hub in Franklin County with no hospital enrolment and nothing tying it to a hospital; called a non-hospital.",
       "'Foundation' could be a hospital's, e.g. Franklin County Memorial Hospital's."),
  sc_j("MS_R2", "Mississippi Center for Advancement of Prehospital Medicine", "NOT_HOSPITAL",
       "An EMS education and training centre ('prehospital'), not a hospital.",
       "It may be housed at a hospital or university medical centre."),
  sc_j("CA", "Pacific Central Coast Health Centers", "NOT_HOSPITAL",
       "A Dignity Health medical-foundation clinic network on the Central Coast; under ruling (b) a California medical foundation operates clinics and is not a hospital.",
       "It is affiliated with Dignity Health's Marian and French hospitals."),
  sc_j("CA", "Maternal Child Health Fellowship: Fresno Family Medicine Obstetrics", "NOT_HOSPITAL",
       "The row names a fellowship programme, and owner ruling (a) makes a programme row non-hospital.",
       "The sponsor is probably UCSF Fresno at Community Regional Medical Center, an enrolled hospital (+$289,039)."),
  sc_j("KS", "Citizens Foundation", "HOSPITAL",
       "Read as the same organisation as the CAP row's Citizen's Foundation (Citizens Health), the fundraising foundation of Citizens Medical Center in Colby; fundraising foundations count.",
       "The RPGP string names no parent, and two spellings may be two bodies."),
  sc_j("KS", "Attica Hospital District #1", "NOT_HOSPITAL",
       "No CMS KS hospital enrolment carries the district, and the only Attica facility CMS enrols is a rural health clinic run by Harper County Hospital District No 6, so it is called a non-hospital.",
       "Its legal form is a hospital district (a special district for hospital purposes)."),
  sc_j("NV", "93 X 95 NV", "NOT_HOSPITAL",
       "An unidentified string attached to reopening the Goldfield Wellness Clinic (primary care); NVHA dropped it on 09-24, and the row carries no dollars.",
       "None."),
  sc_j("NV", "Lyon County", "NOT_HOSPITAL",
       "A county launching a countywide Mobile Integrated Health and Community Paramedicine programme: county-run EMS, not hospital-run.",
       "Lyon County owns South Lyon Medical Center; if its hospital runs the programme, the call reverses (+$4,289,351)."),
  sc_j("NV", "Esmeralda County Board of Commissioners", "NOT_HOSPITAL",
       "County-run paid EMS for Esmeralda County, which has no hospital.",
       "None."),
  sc_j("NV", "Mineral County", "NOT_HOSPITAL",
       "A county buying an ambulance, a ventilator and an ultrasound: county EMS equipment.",
       "Mineral County's Mount Grant General Hospital may be the user of the ventilator and ultrasound."),
  sc_j("NV", "Nevada Health Centers", "NOT_HOSPITAL",
       "Nevada Health Centers, Inc. is the state's largest FQHC network, not a hospital.",
       "None."),
  sc_j("NV", "Nevada Rural Hospital Partners Foundation", "HOSPITAL",
       "Shared award: a rural hospital network passing funds to its named member hospitals (owner rulings, sessions 101-102), called on those members.",
       "No per-hospital split is published, and some lines buy services for hospitals rather than paying them."),
  sc_j("NV", "Nevada Rural Hospital Partners", "HOSPITAL",
       "Shared award: the rural hospital network's line for all rural hospitals (owner ruling, session 102), called on its member hospitals.",
       "The line names no hospital and builds capacity through the network itself (ASSOCIATION_SERVICE)."),
  sc_j("NE", "Nebraska High Value Network^", "HOSPITAL",
       "Shared award: DHHS names the 21 hospitals receiving funding through the network, so every member is a hospital.",
       "No per-hospital split is published, and the network may keep some for administration."),
  sc_j("NE", "Winnebago Tribe of Nebraska DBA Winnebago Comprehensive Healthcare System", "HOSPITAL",
       "CMS enrols the Tribe's own name as the provider of Twelve Clans Unity Hospital (CCN 280059), and the award is to the health system that runs it.",
       "The awardee is a tribal government, and the 5.3 award modifies facilities for mental-health crisis care that may be outpatient."),
  sc_j("NH", "Foundation for Healthy Communities (FHC)", "HOSPITAL",
       "FHC is the New Hampshire Hospital Association's foundation and the designated GO-NORTH administrator, and the owner's standing ruling counts hospital associations and their foundations as hospitals.",
       "FHC's eligible class is primary care, CAHs, EMS, behavioral health, oral health and CBOs (§0.3), its CAH RFA is about $17.5M of the $66.5M, and it has named no subrecipient."),
  sc_j("ME", "University of New England (Shaw Institute for Public and Planetary Health)", "NOT_HOSPITAL",
       "A university, subawarding to public health districts and tribal health centres.",
       "Hospitals may benefit from the CHW expansion (in-kind)."),
  sc_j("NC", "Impact Health", "NOT_HOSPITAL",
       "A Healthy Opportunities network lead (a community care network), not a hospital; no dollars on the row.",
       "Its regional network may include hospitals."),
  sc_j("NC", "Trillium Health Resources", "NOT_HOSPITAL",
       "A Medicaid managed care organisation; an MCO is never a hospital type. No dollars on the row.", "None."),
  sc_j("NC", "Vaya Health", "NOT_HOSPITAL",
       "A Medicaid managed care organisation; an MCO is never a hospital type. No dollars on the row.", "None."),
  sc_j("NC", "Access East, Inc.", "NOT_HOSPITAL",
       "A care management provider (NCDHHS's own words), not a hospital; no dollars on the row.",
       "It is affiliated with ECU Health by general knowledge."),
  sc_j("WY", "Wyoming Innovation Partnership (WIP)", "NOT_HOSPITAL",
       "The University of Wyoming and community-college workforce partnership, administering education support: a university consortium, not a hospital.",
       "Individual workforce support may reach hospital employees."),
  sc_j("WY", "No bidders, recommend sole source w Tribal provider", "NOT_HOSPITAL",
       "No recipient is named; the committee recommended a sole-source Tribal provider. No dollars on the row.", "None."),
  sc_j("ID", "The Hospital Cooperative", "HOSPITAL",
       "A cooperative of hospitals in eastern Idaho, and the owner's standing ruling counts hospital networks as hospitals.",
       "DHW's list says nothing of where its money goes; it may fund the cooperative's own services (session 109 ruling b kept it Unclear)."),
  sc_j("ID", "Hospital Network of Idaho", "HOSPITAL",
       "A network of Idaho hospitals, and the owner's standing ruling counts hospital networks as hospitals.",
       "DHW's list says nothing of where its money goes (session 109 ruling b kept it Unclear)."),
  sc_j("ID", "Public Consulting Group LLC", "NOT_HOSPITAL",
       "A vendor contracted as third-party administrator for the Ladder Payment Program; vendors do not count, and the payees are not named.",
       "If the ladder payments go to hospitals for recruitment and retention, PCG is a pass-through and the $14.52M is hospital money."),
  sc_j("OH", paste0("22 rural hospitals named by ODH (Joint Township District Memorial Hospital; Knox Community Hospital; ",
                    "Pomerene Hospital; Salem Community Hospital; Van Wert County Hospital; Mercer County Community Hospital; ",
                    "Southeastern Ohio Regional Medical Center; TriHealth Clinton Regional Hospital; Holzer Medical Center; ",
                    "Ashtabula County Medical Center; Wilson Memorial Hospital; Marion General Hospital; O'Bleness Memorial ",
                    "Hospital; Sojourn at Seneca; Fisher-Titus Medical Center; Mary Rutan Hospital; Blanchard Valley Regional ",
                    "Health Center; Community Hospital of Williams County; Coshocton Regional Medical Center; East Liverpool ",
                    "City Hospitals; Memorial Hospital; Wooster Community Hospital)"), "HOSPITAL",
       "Shared award: ODH states the $30.3M as direct payments to these 22 named rural hospitals, so every recipient is a hospital.",
       "No per-hospital split is published, and the figure is rounded."),
  sc_j("OH", "Ohio High Value Network", "HOSPITAL",
       "A clinically integrated network of Ohio hospitals, and the owner's standing ruling counts hospital networks as hospitals; no dollars on the row.",
       "ODH prices only the shared pool, which also funds health centres."),
  sc_j("OH", "Ohio State Health Network", "HOSPITAL",
       "Ohio State's affiliate network of community hospitals, and the owner's standing ruling counts hospital networks as hospitals; no dollars on the row.",
       "ODH prices only the shared pool, which also funds health centres."),
  sc_j("SC", "Acadia Healthcare Co.", "HOSPITAL",
       "A system parent operating psychiatric hospitals in South Carolina (Lighthouse Behavioral Health Hospital, CCN 424002), and system parents count.",
       "Its SC estate also includes two outpatient treatment centres, so part of the $5.57M may fund non-hospital sites."),
  sc_j("NY", "Glens Falls Hospital/ Hudson Headwaters", "HOSPITAL",
       "Joint award called on its lead, Glens Falls Hospital (CCN 330191), listed first; the dollars are not split.",
       "Hudson Headwaters, an FQHC, is the co-recipient, and the hospital's share is unknown."),
  sc_j("VA", "Virginia Hospital Research and Education Foundation (d/b/a VHHA Foundation)", "HOSPITAL",
       "The Virginia Hospital & Healthcare Association's foundation, and the owner's standing ruling counts hospital associations and their foundations; no dollars on the row.",
       "It administers Remote Patient Monitoring, GME and Food is Medicine, whose subrecipients may include non-hospitals."),
  sc_j("VA", "Virginia Health Care Foundation", "NOT_HOSPITAL",
       "A public-private foundation funding safety-net providers; not a hospital body. No dollars on the row.",
       "Its subawards include hospital systems (R/03bx, R/03ch)."),
  sc_j("VA", "Virginia Works", "NOT_HOSPITAL", "A state agency. No dollars on the row.", "None."),
  sc_j("VA", "Virginia Department of Health", "NOT_HOSPITAL", "A state agency. No dollars on the row.", "None."),
  sc_j("VA", "Virginia Foundation for Healthy Youth", "NOT_HOSPITAL",
       "A state-created youth health foundation, not a hospital. No dollars on the row.", "None."),
  sc_j("WA", "Washington State Hospital Association", "HOSPITAL",
       "The state hospital association, which HCA's deck says is taking applications from hospitals for technology and cybersecurity; the owner's standing ruling counts hospital associations.",
       "HCA's deck does not say the money is paid to hospitals rather than spent by WSHA on their behalf (in-kind)."),
  sc_j("WA", "The Rural Collaborative", "HOSPITAL",
       "A collaborative of 30 independent rural hospitals, and the owner's standing ruling counts hospital networks as hospitals.",
       "HCA describes a revenue-cycle service delivered to the hospitals (strictly IN_KIND_BENEFIT), not money paid to them."),
  sc_j("WA", "Rural Health Redesign Center", "NOT_HOSPITAL",
       "A payment-model consultancy (sole source), i.e. a vendor of services to hospitals.",
       "None."),
  sc_j("NJ", "Virtua Health Inc.", "HOSPITAL",
       "The parent of four CMS-enrolled Virtua hospitals, and system parents count.",
       "The parent is not itself enrolled, so no CCN is on the row."),
  sc_j("NJ", "Health Center Network of New York, Inc. aka Health Efficient", "NOT_HOSPITAL",
       "A health-centre (FQHC) network services organisation, not a hospital.", "None."),
  sc_j("NJ", "Parker Family Health Center Inc.", "NOT_HOSPITAL",
       "A free primary-care clinic, not a hospital.", "None."),
  sc_j("LA", "48 Rural Clinician Credit Bank awards (single home parish) - recipient names not published", "NOT_HOSPITAL",
       "Called on the majority: LDH's own split puts 20 of the round's 53 awards in hospital settings, so most of the 48 unnamed awards are not hospitals; the row carries no dollars.",
       "Up to 19 of the 48 may be hospital-setting awards (about $4.8M)."),
  sc_j("LA", "Outpatient Medical Center", "NOT_HOSPITAL",
       "A multi-parish outpatient primary-care clinic group, not a hospital.", "None."),
  sc_j("MT", "75 EMS agencies (equipment awards) - recipient names not published", "NOT_HOSPITAL",
       "EMS agencies, called on the class Montana states; the row carries no dollars.",
       "Some rural Montana ambulance services are run by hospitals."),
  sc_j("AK", "City of Ketchikan", "NOT_HOSPITAL",
       "The City's Mobile Integrated Healthcare and nurse-practitioner expansion is municipal EMS; PeaceHealth, not the City, operates Ketchikan Medical Center.",
       "Alaska's own notice ticked 'Hospital (all types)' (with every other type), and the City owns the hospital facility."),
  sc_j("IN_GROW", "Goshen Health System", "HOSPITAL",
       "The operator of Goshen Hospital, typed on a hand-read bridge; system parents count.", "No exact CMS IN enrolment carries the string."),
  sc_j("IN_GROW", "Northwest Health Starke Hospital", "HOSPITAL",
       "A hospital by name (Northwest Health - Starke, Knox), typed on a hand-read bridge.", "No exact CMS IN enrolment carries the string."),
  sc_j("IN_GROW", "Franciscan Health Foundation", "HOSPITAL",
       "The fundraising foundation of Franciscan Health's hospitals, and fundraising foundations count.", "No exact CMS IN enrolment carries the string."),
  sc_j("IN_GROW", "Union Health Inc.", "HOSPITAL",
       "The parent of Union Hospital (Terre Haute and Clinton), and system parents count.", "No exact CMS IN enrolment carries the string."),
  sc_j("IN_GROW", "St. Elizabeth Dearborn", "HOSPITAL",
       "St. Elizabeth Healthcare's Dearborn hospital in Lawrenceburg, typed on a hand-read bridge.", "No exact CMS IN enrolment carries the string."),
  sc_j("IN_GROW", "Ascension St. Vincent", "HOSPITAL",
       "Ascension St. Vincent, the system operating St. Vincent hospitals in Indiana; system parents count.", "No exact CMS IN enrolment carries the string."),
  sc_j("IN_GROW", "Northeastern Center", "HOSPITAL",
       "A community mental health centre that holds a psychiatric hospital CCN in its own name (the Lifeways precedent, session 109).",
       "Its RHTP work may be outpatient CMHC services."),
  sc_j("IN_GROW", "Hamilton Center, Inc.", "HOSPITAL",
       "A community mental health centre that holds a psychiatric hospital CCN in its own name (the Lifeways precedent, session 109).",
       "Its RHTP work may be outpatient CMHC services."),
  sc_j("IN_GROW", "INcompass Healthcare", "HOSPITAL",
       "A community mental health centre that holds a psychiatric hospital CCN in its own name (the Lifeways precedent, session 109).",
       "Its RHTP work may be outpatient CMHC services."),
  sc_j("IN_GROW", "Cummins Behavioral Health Systems, Inc.", "NOT_HOSPITAL",
       "A community mental health centre with no hospital enrolment.", "None."),
  sc_j("AR_R2", "University of Arkansas for Medical Sciences", "HOSPITAL",
       "UAMS is CMS-enrolled as a hospital (UAMS MEDICAL CENTER, CCN 040016) and academic health centres count, flagged.",
       "The owner asked for round 2's UAMS rows to be queued; RISE AR and HEART fund education and healthy-eating work."),
  sc_j("AR_R2", "CARTI", "NOT_HOSPITAL",
       "A cancer treatment provider with no CMS AR hospital enrolment: outpatient oncology clinics.",
       "CARTI runs a large Little Rock cancer centre that may hold inpatient beds under another enrolment."),
  sc_j("VT", "Southwestern Vermont Health", "HOSPITAL",
       "Read as Southwestern Vermont Health Care, parent of Southwestern Vermont Medical Center; system parents count.",
       "The string matches no enrolment exactly."),
  sc_j("VT", "Jenna Tatro Memorial Fund, Inc. DBA Jenna’s Promise", "NOT_HOSPITAL",
       "A recovery-community nonprofit; 'Memorial' names a person, not a hospital.", "None."),
  sc_j("CO", "Walsh Hospital District", "NOT_HOSPITAL",
       "The district's only CMS record is a rural health clinic (WALSH HOSPITAL DISTRICT HEALTHCARE CENTER, 063874); it runs no enrolled hospital.",
       "Its legal form is a hospital district."),
  sc_j("CO", "West Custer County Hospital District", "NOT_HOSPITAL",
       "The district holds no CMS enrolment and runs no hospital (the Westcliffe clinic is enrolled under Salida's hospital district).",
       "Its legal form is a hospital district, and its clinic is part of an enrolled hospital's operation."),
  sc_j("CO", "Telluride Regional Medical Center", "NOT_HOSPITAL",
       "A clinic with emergency services and no CMS hospital enrolment.",
       "'Medical Center' and 24-hour emergency care read as a hospital to a lay reader."),
  sc_j("CO", "Centennial Mental Health Center, Inc", "NOT_HOSPITAL",
       "A community mental health centre with no hospital enrolment.", "None."),
  sc_j("CO", "West Central Mental Health Center, Inc., dba Solvista Health", "NOT_HOSPITAL",
       "A community mental health centre with no hospital enrolment.", "None."),
  sc_j("CO", "Eastern Plains Healthcare Consortium", "NOT_HOSPITAL",
       "A regional consortium of eastern-plains providers whose form HCPF does not state; its membership is not shown to be hospitals, so it is not called a hospital network.",
       "If its members are the eastern-plains critical access hospitals, it is a hospital network and the call reverses (+$1,420,182)."),
  sc_j("AL_R2", "Greene County Health System", "HOSPITAL",
       "Read as the operator of Greene County Hospital (CCN 010051, Eutaw); system parents count.",
       "No CMS record carries the string."),
  sc_j("SD_CONTRACTS", "AVERA AT HOME", "NOT_HOSPITAL",
       "Avera Health's home-health, hospice and DME operator; like a California medical foundation (ruling b), an affiliate that operates non-hospital services is judged as what it operates.",
       "It is an affiliated arm of a named health system, and system parents count."),
  sc_j("SD_CONTRACTS", "COMPLETE HEALTH CENTER OF BH", "NOT_HOSPITAL",
       "A Black Hills primary-care clinic, not a hospital.", "None."),
  sc_j("SD_CCBHC", "Avera Behavioral Health", "HOSPITAL",
       "Avera's behavioral-health service line, run from Avera McKennan's behavioral health hospital in Sioux Falls; affiliated arms of a named system count. No dollars on the row.",
       "The owner declined the strict enrolment bridge in session 91."),
  sc_j("SD_CCBHC", "Northeastern Mental Health Center", "NOT_HOSPITAL",
       "A community mental health centre. No dollars on the row.", "None."),
  sc_j("OK_RRR", "Grand Lake Mental Health Center, Inc.", "NOT_HOSPITAL",
       "A community mental health centre, not a hospital.", "None."),
  sc_j("OK", "60 grants (OSDE's ROOTS Competitive Grant) to PK-12 rural school sites at $10,000 each - recipient names not published", "NOT_HOSPITAL",
       "School sites, a class OSDE states. No dollars on the row.", "None."),
  sc_j("TX", "St. Joseph Health Burleson", "HOSPITAL",
       "CMS TX enrols BURLESON ST JOSEPH HEALTH CENTER OF CALDWELL TEXAS dba CHI ST JOSEPH HEALTH BURLESON HOSPITAL (CAH 451305), and the line sits in Initiative 1, the rural-hospital initiative.",
       "The string matches no enrolment exactly; R/03ce did not bridge it (a candidate for the strict file)."),
  sc_j("TX", "Coastal Gateway Health Center", "NOT_HOSPITAL",
       "A community health centre, not a hospital.", "None."),
  sc_j("CT", "Hartford HealthCare -- Windham Hospital (Willimantic) and Charlotte Hungerford Hospital (Torrington)", "HOSPITAL",
       "Shared award: both named recipients are Hartford HealthCare hospitals, so the call is HOSPITAL whatever the split.",
       "No per-hospital split is published."),
  sc_j("VA_VHCF_PP", "VCU Health, Community Memorial & Tappahannock Hospitals", "HOSPITAL",
       "Shared award: both named recipients are VCU Health hospitals (CCNs 490098, 490084), so the call is HOSPITAL whatever the split.",
       "No per-hospital split is published."),
  sc_va_collab("Northern Shenandoah Valley Regional Commission"),
  sc_va_collab("SWVA Regional Collaborative"),
  sc_va_collab("Roanoke-Alleghany/Central Shenandoah/New River Valley Regional Collaborative"),
  sc_va_collab("Northern Piedmont Regional Collaborative"),
  sc_va_collab("Southside Regional Collaborative"),
  sc_va_collab("Eastern Shore Regional Collaborative"),
  sc_ny("Care Compass Collaborative", "a regional collaborative of providers and community organisations (the successor of a DSRIP PPS)",
        "Its membership includes the region's hospitals, and RCHI required a hospital partner."),
  sc_ny("Chautauqua Health Network", "a county rural health network",
        "If the network is the county's hospitals acting together, it is a hospital network and the call reverses (+$1,838,750)."),
  sc_ny("Chenango Health Network", "a county rural health network"),
  sc_ny("Coordinated Behavioral Health Services", "a behavioral-health provider network"),
  sc_ny("East Hill Family Medical", "an FQHC (CMS FQHC enrolment)"),
  sc_ny("Fort Drum Regional Health Planning Org", "a regional health planning organisation",
        "Its members include the North Country hospitals, and RCHI required a hospital partner."),
  sc_ny("Greenport Rescue Squad", "an independent EMS agency"),
  sc_ny("Healthy Alliance Foundation", "a social-care network foundation"),
  sc_ny("Hudson Headwaters", "an FQHC (CMS FQHC enrolment)"),
  sc_ny("Institute for Family Health", "an FQHC (CMS FQHC enrolment)"),
  sc_ny("Madison County Rural Health Council", "a county rural health council"),
  sc_ny("ODA Primary Health Care Network", "an FQHC (CMS FQHC enrolment)"),
  sc_ny("Pivital Public Health Partnership", "a public-health partnership"),
  sc_ny("Refuah Health Center", "an FQHC (CMS FQHC enrolment)"),
  sc_ny("Southern Tier Health Care System", "a rural health network, not an enrolled hospital despite its name",
        "Its name reads as a hospital system and its members may include the region's hospitals."),
  sc_ny("Sun River Health", "an FQHC (CMS FQHC enrolment)"),
  sc_ny("The Chautauqua Center", "an FQHC (CMS FQHC enrolment)"),
  sc_ny("The Family Counseling Center of Fulton County", "a counselling agency"),
  sc_ny("Trustees of the Masonic Hall & Asylum Fund", "the Masonic Care Community's governing trust (a continuing-care and nursing community)"),
  sc_ny("Upstate Caring Partners", "a developmental-disabilities services provider"),
  sc_ny("Western New York Rural Area Health Education Center", "an AHEC"))

# -- shared pools priced only at pool level --------------------------------------

#' One row per pool. `member_col`/`member_value` select its member rows in the
#' file; every member must carry no amount (the pool is on no row).
SC_POOLS <- tibble::tribble(
  ~pool_id, ~file_key, ~state, ~pool_name, ~pool_usd, ~member_col, ~member_value, ~call, ~rationale, ~counter,
  "GA_P2_CONNECTING_TO_CARE", "GA", "GA", "Connecting to Care to Improve Healthcare Access in Rural Georgia (Phase 2)", 6500000,
  "initiative", "Connecting to Care to Improve Healthcare Access in Rural Georgia", "HOSPITAL",
  "Shared pool called on its majority: 17 of its 18 named recipients are hospitals (the other is DBHDD's mobile dental clinic); not split.",
  "DBHDD's award is inside the $6.5M and no split is published, so part of it is not hospital money.",
  "GA_P4_STRENGTHENING_CONTINUUM", "GA", "GA", "Strengthening the Continuum of Care in Rural Georgia (Phase 4)", 6209688,
  "initiative", "Strengthening the Continuum of Care in Rural Georgia", "NOT_HOSPITAL",
  "Shared pool called on its majority: one named hospital (Emory University) against five non-hospital members (GHCA, DPH, BPRC, actuarial work, the unawarded ambulances).",
  "The ambulance procurement's eligible class is rural hospitals.",
  "GA_P4_TRANSFORMING", "GA", "GA", "Transforming for a Sustainable Health System in Rural Georgia (Phase 4)", 15635000,
  "initiative", "Transforming for a Sustainable Health System in Rural Georgia", "HOSPITAL",
  "Shared pool called on its majority: its seven named recipients are hospitals, and the only other line (AHEAD assessments) is a service delivered to hospitals; not split.",
  "The AHEAD assessments of all 87 hospitals are inside the $15.6M and pay an assessor, not a hospital.",
  "OH_CIN_HUBS", "OH", "OH", "Clinically Integrated Networks and Rural Health Innovation Hubs ($31.4M)", 31400000,
  "award_pool", NA, "HOSPITAL",
  "Shared pool called on its majority: five of seven named members are hospitals or hospital networks (UH, Kettering's Beavercreek, Mercy St. Rita's, Ohio High Value Network, Ohio State Health Network); not split.",
  "Two members are not hospitals (the Ohio Association of Community Health Centers and the Child & Family Health Collaborative), and ODH publishes no split.",
  "OH_MATERNAL", "OH", "OH", "Maternal Care ($30.3M)", 30300000,
  "award_pool", NA, "HOSPITAL",
  "Shared pool called on its majority: four of six named members are hospitals or hospital networks (Beavercreek, Mercy St. Rita's, Ohio High Value Network, Ohio State Health Network); not split.",
  "CMS says the money 'will go to hospital networks and health centers', and OACHC and the Ohio Health Institute are members.")

sc_pool_members <- function(p, d) {
  if (p$file_key == "OH") {
    # Ohio's two shared sub-pools are identified by the page section each
    # listing is printed under (R/03an's note), not by a column of their own.
    sec <- if (p$pool_id == "OH_CIN_HUBS") "Clinically Integrated Networks and Rural Health Innovation Hubs" else "'Maternal Care' list"
    return(grepl(sec, d$note, fixed = TRUE))
  }
  if (p$file_key == "GA") {
    # Georgia's pools are an initiative WITHIN a phase: Phase 1 rows of the
    # same initiative are priced and are not this pool.
    ph <- c(GA_P2_CONNECTING_TO_CARE = "2", GA_P4_STRENGTHENING_CONTINUUM = "4",
            GA_P4_TRANSFORMING = "4")[[p$pool_id]]
    return(d$phase == ph & d$initiative == p$member_value)
  }
  if (p$file_key == "IN_GROW") return(d$region == p$member_value)
  if (p$file_key == "NC_SBHC") return(rep(TRUE, nrow(d)))
  d[[p$member_col]] == p$member_value
}

# Indiana GROW's eight regions and NC's SBHC pool: one figure per pool, every
# member named, none priced. Built from the files so the counts are read, not
# typed.
sc_pools_from_files <- function(files = sc_state_files()) {
  g <- rhtp_summary_read(here::here(files[["IN_GROW"]]))
  reg <- g %>% dplyr::group_by(region, round_amount) %>%
    dplyr::summarise(n = dplyr::n(), hosp = sum(distributed_to_hospital == "Yes"), .groups = "drop")
  in_pools <- tibble::tibble(
    pool_id = paste0("IN_GROW_REGION_", reg$region), file_key = "IN_GROW", state = "IN",
    pool_name = paste0("GROW Regional Grants, Region ", reg$region),
    pool_usd = as.numeric(reg$round_amount), member_col = "region", member_value = reg$region,
    call = ifelse(reg$hosp > reg$n / 2, "HOSPITAL", "NOT_HOSPITAL"),
    rationale = paste0("Shared regional pool called on its majority: ", reg$hosp, " of ", reg$n,
                       " named recipients are hospitals", ifelse(reg$hosp * 2 == reg$n, " (a tie is not a majority)", ""),
                       "; not split."),
    counter = paste0(reg$hosp, " named hospitals share the region's figure, and Indiana publishes no split."))
  s <- rhtp_summary_read(here::here(files[["NC_SBHC"]]))
  nc <- tibble::tibble(
    pool_id = "NC_SBHC", file_key = "NC_SBHC", state = "NC",
    pool_name = "NC School-Based Health Center grants", pool_usd = as.numeric(unique(s$round_amount)),
    member_col = NA_character_, member_value = NA_character_,
    call = if (sum(s$distributed_to_hospital == "Yes") > nrow(s) / 2) "HOSPITAL" else "NOT_HOSPITAL",
    rationale = paste0("Shared pool called on its majority: ", sum(s$distributed_to_hospital == "Yes"), " of ",
                       nrow(s), " named recipients is a hospital (FirstHealth); not split."),
    counter = "FirstHealth of the Carolinas is a named recipient, and its share is unknown.")
  dplyr::bind_rows(SC_POOLS, in_pools, nc)
}

sc_pools <- function(files = sc_state_files()) {
  pools <- sc_pools_from_files(files)
  pools$members <- NA_integer_
  pools$hospital_members <- NA_integer_
  pools$in_file_round_figures <- NA
  for (i in seq_len(nrow(pools))) {
    p <- pools[i, ]
    d <- rhtp_summary_read(here::here(files[[p$file_key]]))
    m <- sc_pool_members(p, d)
    if (!any(m)) stop("[summary calls] pool ", p$pool_id, " has no member rows.", call. = FALSE)
    priced <- nzchar(d$amount[m]) & d$amount[m] != "NA"
    if (any(priced)) {
      stop("[summary calls] pool ", p$pool_id, " has PRICED member rows: counting the pool ",
           "would count them twice.", call. = FALSE)
    }
    pools$members[i] <- sum(m)
    pools$hospital_members[i] <- sum(d$distributed_to_hospital[m] == "Yes")
    # Does the file already carry this pool as a round figure (R/03aw's
    # published-total rule reads those)? Georgia's per-initiative figures and
    # a round_amount on every member say yes; Ohio's shared sub-pools are on
    # no row, so R/08 adds them to the published total itself.
    ra <- suppressWarnings(as.numeric(rhtp_summary_col(d, "round_amount")[m]))
    pools$in_file_round_figures[i] <- p$file_key == "GA" ||
      (all(!is.na(ra)) && all(abs(ra - p$pool_usd) < 0.01))
  }
  if (any(!pools$call %in% RHTP_SUMMARY_CALL_VALUES)) stop("[summary calls] a pool call is not two-valued.", call. = FALSE)
  pools
}

# -- compute, apply, validate ------------------------------------------------------

sc_compute <- function(files = sc_state_files(), strict = TRUE) {
  sc_assert_queue_covered()
  enr <- sc_enrolment()
  dup <- SC_JUDGMENTS %>% dplyr::count(file_key, awardee, row_no) %>% dplyr::filter(n > 1)
  if (nrow(dup)) stop("[summary calls] duplicate written judgments: ", paste(dup$awardee, collapse = "; "), call. = FALSE)
  out <- list(); missing <- list(); used <- character(0)
  for (k in names(files)) {
    d <- rhtp_summary_read(here::here(files[[k]]))
    st <- unique(d$state)[1]
    j <- SC_JUDGMENTS[SC_JUDGMENTS$file_key == k, ]
    open <- sc_open_rows(d, k)
    if (!strict) {
      r <- rhtp_summary_reasons(d, open)
      need <- nzchar(r) & !d$awardee %in% j$awardee &
        !(r == "FORM_INFERRED" & d$distributed_to_hospital == "No" &
            !grepl(RHTP_SUMMARY_HOSPITAL_MARKER, d$awardee, ignore.case = TRUE))
      if (any(need)) missing[[k]] <- tibble::tibble(file_key = k, row_no = d$row_no[need],
                                                   awardee = d$awardee[need], amount = d$amount[need],
                                                   reasons = r[need])
      next
    }
    calls <- rhtp_summary_calls(d, j, open, sc_default_rationale(st, enr), label = k)
    used <- c(used, paste(k, d$awardee[calls$judgment_source %in% "WRITTEN"], sep = " :: "))
    out[[k]] <- dplyr::bind_cols(
      tibble::tibble(file_key = k, state = d$state, row_no = d$row_no, awardee = d$awardee,
                     amount = suppressWarnings(as.numeric(d$amount)),
                     distributed_to_hospital = d$distributed_to_hospital,
                     hospital_attribution = rhtp_summary_col(d, "hospital_attribution")),
      calls)
  }
  if (!strict) return(dplyr::bind_rows(missing))
  unused <- setdiff(paste(SC_JUDGMENTS$file_key, SC_JUDGMENTS$awardee, sep = " :: "), used)
  if (length(unused)) {
    stop("[summary calls] written judgments that reach no judged row: ",
         paste(unused, collapse = "; "), call. = FALSE)
  }
  out
}

sc_apply <- function(files = sc_state_files()) {
  calls <- sc_compute(files)
  for (k in names(files)) rhtp_summary_write(here::here(files[[k]]), calls[[k]])
  p <- sc_pools(files)
  readr::write_csv(p, here::here(SC_POOLS_CSV), na = "")
  sc_write_review(calls, p)
  u <- dplyr::bind_rows(calls)
  message("[summary calls] wrote the three columns to ", length(files), " files: ",
          sum(u$summary_call_basis == "CODED"), " CODED, ",
          sum(u$summary_call_basis == "BEST_JUDGMENT"), " BEST_JUDGMENT rows; ",
          nrow(p), " pool-level calls in ", SC_POOLS_CSV, ".")
  invisible(calls)
}

sc_validate <- function(files = sc_state_files()) {
  calls <- sc_compute(files)
  for (k in names(files)) {
    d <- rhtp_summary_read(here::here(files[[k]]))
    rhtp_assert_summary_calls(d, k)
    for (col in RHTP_SUMMARY_COLUMNS) {
      want <- ifelse(is.na(calls[[k]][[col]]), "", calls[[k]][[col]])
      if (!identical(d[[col]], want)) {
        stop("[summary calls] ", k, ": committed ", col, " differs from the computed calls. ",
             "Re-run Rscript R/07_summary_calls.R --apply.", call. = FALSE)
      }
    }
  }
  p <- sc_pools(files)
  committed <- readr::read_csv(here::here(SC_POOLS_CSV), col_types = readr::cols(.default = "c"), progress = FALSE)
  if (!identical(committed$pool_id, p$pool_id) || !identical(committed$call, p$call) ||
      !isTRUE(all.equal(as.numeric(committed$pool_usd), p$pool_usd))) {
    stop("[summary calls] ", SC_POOLS_CSV, " is stale. Re-run --apply.", call. = FALSE)
  }
  invisible(calls)
}

# -- the owner's review list ---------------------------------------------------------

# Rows the owner named for the list whatever their amount (session 110).
SC_REVIEW_ALWAYS <- tibble::tribble(
  ~file_key, ~awardee,
  "AK", "City of Ketchikan",
  "CA", "Maternal Child Health Fellowship: Fresno Family Medicine Obstetrics",
  "LA", "48 Rural Clinician Credit Bank awards (single home parish) - recipient names not published")

sc_review <- function(calls, pools) {
  u <- dplyr::bind_rows(calls)
  always <- paste(u$file_key, u$awardee) %in% paste(SC_REVIEW_ALWAYS$file_key, SC_REVIEW_ALWAYS$awardee)
  over <- !is.na(u$amount) & u$amount > SC_REVIEW_FLOOR
  unclear <- !u$distributed_to_hospital %in% c("Yes", "No")
  u$listed_because <- dplyr::case_when(over ~ "OVER_1M", always ~ "OWNER_NAMED",
                                       unclear ~ "STRICT_UNCLEAR", TRUE ~ NA_character_)
  bj <- u %>% dplyr::filter(summary_call_basis == "BEST_JUDGMENT", !is.na(listed_because))
  ctr <- SC_JUDGMENTS %>% dplyr::select(file_key, awardee, counter) %>% dplyr::distinct(file_key, awardee, .keep_all = TRUE)
  rows <- bj %>%
    dplyr::left_join(ctr, by = c("file_key", "awardee")) %>%
    dplyr::mutate(counter = dplyr::coalesce(counter, SC_DEFAULT_COUNTER),
                  record_kind = "AWARD_ROW", strict_status = distributed_to_hospital) %>%
    dplyr::transmute(state, file_key, record_kind, row_no, recipient = awardee, amount,
                     strict_status, call = summary_hospital_call, rationale = summary_call_rationale,
                     counter_argument = counter, reasons, judgment_source, listed_because)
  pl <- pools %>% dplyr::filter(pool_usd > SC_REVIEW_FLOOR) %>%
    dplyr::transmute(state, file_key, record_kind = "SHARED_POOL", row_no = pool_id,
                     recipient = paste0(pool_name, " [", members, " named members, ", hospital_members, " hospital rows]"),
                     amount = pool_usd, strict_status = "NO_BUCKET (pool priced only at pool level)",
                     call, rationale, counter_argument = counter, reasons = "SHARED_AWARD",
                     judgment_source = "WRITTEN_POOL", listed_because = "OVER_1M")
  dplyr::bind_rows(rows, pl) %>%
    dplyr::arrange(dplyr::desc(dplyr::coalesce(amount, 0)), state, recipient)
}

sc_write_review <- function(calls, pools) {
  r <- sc_review(calls, pools)
  readr::write_csv(r, here::here(SC_REVIEW_CSV), na = "")
  invisible(r)
}

sc_report <- function() {
  calls <- sc_compute()
  pools <- sc_pools()
  u <- dplyr::bind_rows(calls)
  cat("\nSUMMARY CALLS (session 110)\n")
  print(as.data.frame(u %>% dplyr::count(summary_call_basis, summary_hospital_call)))
  bj <- u %>% dplyr::filter(summary_call_basis == "BEST_JUDGMENT", summary_hospital_call == "HOSPITAL")
  cat(sprintf("BEST_JUDGMENT HOSPITAL rows: %d / $%s; pool-level HOSPITAL: $%s\n", nrow(bj),
              format(sum(bj$amount, na.rm = TRUE), big.mark = ",", nsmall = 2),
              format(sum(pools$pool_usd[pools$call == "HOSPITAL"]), big.mark = ",", nsmall = 2)))
  invisible(u)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--missing" %in% args) print(as.data.frame(sc_compute(strict = FALSE)), right = FALSE)
  if ("--apply" %in% args) sc_apply()
  if ("--validate" %in% args) { sc_validate(); message("[summary calls] all assertions pass.") }
  if ("--review" %in% args) { sc_write_review(sc_compute(), sc_pools()); message("[summary calls] wrote ", SC_REVIEW_CSV) }
  if ("--report" %in% args) sc_report()
  if (!length(intersect(args, c("--missing", "--apply", "--validate", "--review", "--report")))) {
    message("usage: Rscript R/07_summary_calls.R [--apply] [--validate] [--review] [--missing] [--report]")
  }
}
