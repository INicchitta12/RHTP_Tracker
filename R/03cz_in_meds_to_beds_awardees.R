#!/usr/bin/env Rscript
# 03cz_in_meds_to_beds_awardees.R --------------------------------------------
#
# INDIANA -- MEDS-TO-BEDS: 20 NAMED HOSPITALS, NO AMOUNTS (session 121, Task 7).
#
# IDOH's Initiative 6 page ("Growing Access to Hospital Post-Discharge
# Medications", in.gov/grow-rural-health/initiatives/initiative-6), read
# 2026-11-20, now reports "Year 1 Grant Agreements | Executed July 2026" and
# "Meds to Beds Program Awardees ... 13 hospitals are in the implementation
# stage, with 7 in the planning and developing stage. See the map below to view
# the 20 selected sites." The map ("Meds-to-Beds Awardees", IDOH Office of Data
# Analytics, created October 2026) names all twenty, coded "Planning" or
# "Planning and Implementation". The October newsletter had said "20 hospitals
# awarded funding for Budget Period One" and named none; R/03bi's probe tripped
# on the page on 2026-11-20.
#
# THE MAP IS AN IMAGE WITH NO TEXT LAYER, so the twenty names are HAND-READ from
# the archived JPEG (SHA-256 pinned below), each against CMS IN Hospital
# Enrollments: 16 are an exact legal name or DBA (MEDIUM, CCN on the row), 4
# are hand-read bridges (LOW): "Adams Memorial Hospital" (ADAMS COUNTY MEMORIAL
# HOSPITAL), "Marion Health MGH Campus" (MARION GENERAL HOSPITAL), "Greene
# County General Hosptial" (sic; GREENE COUNTY GENERAL HOSPITAL) and "St.
# Elizabeth Healthcare Dearborn Hospital" (ST ELIZABETH MEDICAL CENTER dba ST.
# ELIZABETH DEARBORN HOSPITAL).
#
# NO AMOUNT IS PUBLISHED, per hospital or in total. Nevada's and Iowa's shape:
# twenty hospital rows at $0 -- READ THE ROW COUNT. Year 1: the page dates the
# grant agreements "Executed July 2026"; the map's footer prints Indiana's
# FY2026 allotment ($206,927,896.80, Tier 1, §0.2).
#
# Conventions: tidyverse, %>% only. --validate | --build.

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
})
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))

MTB_STATE <- "IN"
MTB_DIR   <- file.path("data", "evidence", "recheck", "2026-11-20", "IN")
MTB_PAGE  <- file.path(MTB_DIR, "2026-11-20_in_grow_initiative_6_meds_to_beds.html")
MTB_MAP   <- file.path(MTB_DIR, "2026-11-20_in_meds_to_beds_awardees_map.jpg")
MTB_MAP_SHA <- "754ed90aa4a2e77f064255581bd57f7f831d7312a3e75ae293486e794f68b115"
MTB_PAGE_URL <- "https://www.in.gov/grow-rural-health/initiatives/initiative-6"
MTB_MAP_URL  <- "https://www.in.gov/dA/9c00666de0/Meds%20to%20Beds%20Awardees%20Map.jpg?language_id=1"
MTB_CSV   <- here::here("data", "reference", "in_meds_to_beds_awardees.csv")
MTB_ENROL <- "data/evidence/federal_records/2026-09-24/cms_hosp_enrollments_IN.json"

# The twenty, as printed on the map (left to right, top to bottom), with the
# award type its colour codes and the CMS enrolment each was read against.
MTB_ROSTER <- tibble::tribble(
  ~awardee, ~award_type, ~cms_org, ~cms_dba, ~ccn, ~bridge,
  "Community Hospital of Bremen", "Planning and Implementation", "COMMUNITY HOSPITAL OF BREMEN INC", "COMMUNITY HOSPITAL OF BREMEN INC", "151300", NA,
  "Northwest Health Starke", "Planning", "KNOX HOSPITAL COMPANY LLC", "NORTHWEST HEALTH-STARKE", "150102", NA,
  "Lutheran Kosciusko Hospital", "Planning and Implementation", "WARSAW HEALTH SYSTEM LLC", "LUTHERAN KOSCIUSKO HOSPITAL", "150133", NA,
  "Adams Memorial Hospital", "Planning and Implementation", "ADAMS COUNTY MEMORIAL HOSPITAL", "ADAMS COUNTY MEMORIAL HOSPITAL", "151330",
  "the map drops 'County' from the enrolled name (Decatur, IN, the only Adams enrolment)",
  "Dukes Memorial Hospital", "Planning", "DUKES HEALTH SYSTEM LLC", "DUKES MEMORIAL HOSPITAL", "151318", NA,
  "Marion Health MGH Campus", "Planning and Implementation", "MARION GENERAL HOSPITAL", "MARION GENERAL HOSPITAL", "150011",
  "'MGH' is Marion General Hospital, which trades as Marion Health (general knowledge); the only enrolment of that name in Marion, IN",
  "Bluffton Regional Medical Center", "Planning and Implementation", "BLUFFTON HEALTH SYSTEM LLC", "BLUFFTON REGIONAL MEDICAL CENTER", "150075", NA,
  "Reid Health", "Planning and Implementation", "REID HOSPITAL & HEALTH CARE SERVICES INC", "REID HEALTH", "150048", NA,
  "Union Hospital Clinton", "Planning", "UNION HOSPITAL INC", "UNION HOSPITAL CLINTON", "151326", NA,
  "Putnam County Hospital", "Planning", "PUTNAM COUNTY HOSPITAL", "", "151333", NA,
  "Rush Memorial Hospital", "Planning and Implementation", "RUSH MEMORIAL HOSPITAL", "RUSH MEMORIAL HOSPITAL", "151304", NA,
  "Margaret Mary Health", "Planning", "MARGARET MARY COMMUNITY HOSPITAL INC", "MARGARET MARY HEALTH", "151329", NA,
  "Decatur County Memorial Hospital", "Planning and Implementation", "DECATUR COUNTY MEMORIAL HOSPITAL", "DECATUR COUNTY MEMORIAL HOSPITAL", "151332", NA,
  "Greene County General Hosptial", "Planning and Implementation", "GREENE COUNTY GENERAL HOSPITAL", "GREENE COUNTY GENERAL HOSPITAL", "151317",
  "the map misspells 'Hospital' ('Hosptial'); the string is kept as printed",
  "St. Elizabeth Healthcare Dearborn Hospital", "Planning and Implementation", "ST ELIZABETH MEDICAL CENTER, INC", "ST. ELIZABETH DEARBORN HOSPITAL", "150086",
  "the map prefixes the system name to the enrolled DBA (R/03bi's St. Elizabeth Dearborn bridge, the same CCN)",
  "Schneck Medical Center", "Planning and Implementation", "JACKSON COUNTY SCHNECK MEMORIAL HOSPITAL", "SCHNECK MEDICAL CENTER", "150065", NA,
  "Good Samaritan Hospital", "Planning and Implementation", "GOOD SAMARITAN HOSPITAL", "GOOD SAMARITAN HOSPITAL", "150042", NA,
  "Daviess Community Hospital", "Planning and Implementation", "DAVIESS COUNTY HOSPITAL", "DAVIESS COMMUNITY HOSPITAL", "150061", NA,
  "Harrison County Hospital", "Planning", "HARRISON COUNTY HOSPITAL", "", "151331", NA,
  "Perry County Memorial Hospital", "Planning", "PERRY COUNTY MEMORIAL HOSPITAL", "PERRY COUNTY MEMORIAL HOSPITAL", "151322", NA)

mtb_page_text <- function() rhtp_watch_reduce(here::here(MTB_PAGE))

mtb_assert <- function(r = MTB_ROSTER) {
  t <- mtb_page_text()
  need <- c("Year 1 Grant Agreements Executed July 2026",
            "13 hospitals are in the implementation stage, with 7 in the planning and developing stage",
            "See the map below to view the 20 selected sites")
  miss <- need[!vapply(need, function(x) grepl(x, t, fixed = TRUE), logical(1))]
  if (length(miss)) stop("[IN-MTB] the Initiative 6 page no longer says: ", paste(miss, collapse = " | "), call. = FALSE)
  if (nrow(r) != 20L || sum(r$award_type == "Planning and Implementation") != 13L ||
      sum(r$award_type == "Planning") != 7L || anyDuplicated(r$awardee)) {
    stop("[IN-MTB] the roster is not 20 hospitals, 13 implementation + 7 planning.", call. = FALSE)
  }
  sha <- digest::digest(file = here::here(MTB_MAP), algo = "sha256")
  if (MTB_MAP_SHA != "PINNED_AT_BUILD" && sha != MTB_MAP_SHA) {
    stop("[IN-MTB] the archived map's SHA-256 moved; the hand-read names are of a different image.", call. = FALSE)
  }
  e <- jsonlite::fromJSON(here::here(MTB_ENROL))
  for (i in seq_len(nrow(r))) {
    hit <- e[e$CCN == r$ccn[i] & toupper(e$`ORGANIZATION NAME`) == r$cms_org[i], ]
    if (!nrow(hit)) stop("[IN-MTB] CCN ", r$ccn[i], " / ", r$cms_org[i], " is not on CMS IN enrolment.", call. = FALSE)
    nm <- function(x) stringr::str_squish(gsub("\\b(INC|LLC|THE)\\b", " ", gsub("[^A-Z0-9 ]", " ", toupper(x))))
    exact <- nm(r$awardee[i]) %in% nm(c(hit$`ORGANIZATION NAME`, hit$`DOING BUSINESS AS NAME`))
    if (exact != is.na(r$bridge[i])) {
      stop("[IN-MTB] '", r$awardee[i], "': an exact name must carry no bridge and a bridge must not be exact.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

mtb_awardees <- function(r = MTB_ROSTER) {
  mtb_assert(r)
  br <- !is.na(r$bridge)
  rec <- paste0("CMS Hospital Enrollments (", MTB_ENROL, "): ", r$cms_org,
                ifelse(nzchar(r$cms_dba), paste0(" dba ", r$cms_dba), ""), ", CCN ", r$ccn)
  tibble::tibble(
    state = MTB_STATE, row_no = seq_len(nrow(r)), awardee = r$awardee, amount = NA_real_,
    recipient_type = "HOSPITAL_OR_SYSTEM", distributed_to_hospital = "Yes",
    note = paste0("Meds-to-Beds (Initiative 6, Growing Access to Hospital Post-Discharge Medications) awardee, '",
                  r$award_type, "', named on IDOH's 'Meds-to-Beds Awardees' map (October 2026). Year 1 grant ",
                  "agreements 'Executed July 2026'. NO AMOUNT PUBLISHED, per hospital or in total."),
    recipient_confirmed = "Yes", amount_confirmed = "No", fiscal_year = "FY2026 (Year 1)",
    source_document_title = "IDOH, Grow Rural Health Initiative 6 page and its 'Meds-to-Beds Awardees' map (read 2026-11-20)",
    state_source_url = MTB_PAGE_URL, validation_source_type = "AGENCY_PRESS_RELEASE",
    extraction_method = "MODEL_ASSISTED", validator = "AI-assisted - CONFIRM",
    ccn = r$ccn, aha_id = NA_character_, rural_designation = NA_character_, reviewer = NA_character_,
    award_type = r$award_type,
    recipient_type_source = paste0(rec, ifelse(br, paste0(". HAND-READ BRIDGE (session 121): ", r$bridge, "."),
                                               ". EXACT legal name or DBA (session 121).")),
    determination_confidence = ifelse(br, "LOW", "MEDIUM"),
    flag_reason = NA_character_, award_pool = "Meds-to-Beds (Initiative 6) -- Year 1 grantees, no amount published",
    budget_period = "Budget Period 1", flow_type = "DIRECT", hospital_benefiting = "Yes",
    hospital_attribution = "NAMED_HOSPITAL", intermediary_name = NA_character_,
    determination_basis = paste0("§10.2 DIRECT: the recipient is a hospital on its CMS enrolment (", rec, ")",
                                 ifelse(br, ", read through a hand bridge (LOW)", ""),
                                 ". The map is the state's own roster of the twenty Meds-to-Beds awardees; the names are ",
                                 "HAND-READ from the archived image (no text layer)."),
    amount_basis = "NOT PUBLISHED: IDOH names twenty awardees and prices none; no pool figure is printed. $0, read the row count.",
    basis_type = ifelse(br, "GENERAL_KNOWLEDGE", "ORG_WEBSITE"),
    round_amount = NA_real_, announcement_date = as.Date("2026-11-20"),
    source_archive_path = MTB_MAP,
    cms_enrolment_match = NA_character_,   # recorded in cms_enrolment_record; no R/03bj re-typing (§10.2 hospitals by name)
    cms_enrolment_record = rec)
}

mtb_build <- function() {
  d <- mtb_awardees()
  readr::write_csv(d, MTB_CSV, na = "")
  message("[IN-MTB] wrote ", nrow(d), " rows (", sum(d$determination_confidence == "LOW"), " LOW bridges), $0.")
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) { mtb_assert(); message("[IN-MTB] all assertions pass.") }
  if ("--build" %in% args) mtb_build()
  if (!length(args)) message("Usage: --validate | --build")
}
