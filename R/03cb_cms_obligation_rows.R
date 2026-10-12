#!/usr/bin/env Rscript
# 03cb_cms_obligation_rows.R ---------------------------------------------------
#
# AWARD ROWS FROM CMS'S OBLIGATION REPORT, ON THE OWNER'S RULINGS OF 2026-10-12
# (session 98). Session 97 parsed CMS's "RHTP Obligated Funds Report" (data as
# of 2026-07-31; R/00c) and added nothing. The owner then ruled:
#
#   1. Hospital Association of Rhode Island (HARI, $15,839,907.67 on two
#      single-recipient lines) and Nebraska Hospital Association
#      ($3,474,937.50): hospital money under §10.2's hospital-association row
#      -- NONPROFIT_CBO, PASS_THROUGH_DESIGNATED, Yes -- and tagged
#      flag_reason = CMS_OBLIGATION_ASSOCIATION so a reader can subtract them.
#      Neither names a hospital, so the bucket is POOL_UNNAMED_HOSPITALS
#      (Illinois/ICAHN's), never NAMED_HOSPITAL.
#   2. The Guthrie Clinic ($2,963,577, PA) and Mayo Clinic ($120,000, NE):
#      HOSPITAL_OR_SYSTEM, LOW, GENERAL_KNOWLEDGE, no CCN -- the SD system-
#      parent treatment (R/03i). Mayo is OUT OF STATE (facility_state = MN),
#      as National Jewish Health is in Michigan's file.
#   3. CHI Health St Marys ($40,824.49, NE): typed on its CMS enrolment.
#   4. A new source_doc_type, CMS_OBLIGATION_REPORT, with as_of 2026-07-31.
#   5. data/reference/ri_year1_awardees.csv from the report's SINGLE-recipient
#      RI lines only, every row typed on CMS enrolment. Multi-recipient lines
#      stay in the leads files (cms_obligation_hospital_decision_lists.csv)
#      and are never divided (§6.2).
#
# WHAT A ROW HERE IS. An OBLIGATION the state reported to CMS, by activity, as
# of 2026-07-31 -- not a state-published notice of award. §7's `Yes` rule names
# a STATE document; these rows rest on CMS's federal compilation of the state's
# own report, accepted by owner ruling. `validation_source_type =
# CMS_OBLIGATION_REPORT` is on every row so the whole set can be subtracted
# from any figure in one step, and the association rows can be subtracted
# again on their own.
#
# DEDUPE (owner instruction). Before any NE or PA row is written, each is
# checked against the committed NE and PA award files by NAME and by AMOUNT
# (ob_dedupe()). The build refuses if any amount matches an existing row to
# the cent, or if a name matches an existing row this file does not record
# as a reviewed non-duplicate in OB_NAME_OVERLAPS.
#
# Usage:
#   Rscript R/03cb_cms_obligation_rows.R --build
#   Rscript R/03cb_cms_obligation_rows.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

OB_LINES <- here::here("data", "reference", "cms_obligations_bp1_lines.csv")
OB_OUT <- c(
  NE = here::here("data", "reference", "ne_cms_obligation_awardees.csv"),
  PA = here::here("data", "reference", "pa_cms_obligation_awardees.csv"),
  RI = here::here("data", "reference", "ri_year1_awardees.csv"))
OB_PDF <- "data/raw/cms/obligations/2026-07-31/RHTP-Obligated-Funds-10082026.pdf"
OB_URL <- paste0("https://www.medicaid.gov/resources-for-states/rural-health/",
                 "rhtp-resources/RHTP-Obligated-Funds-10082026.pdf")
OB_TITLE <- paste("CMS, RHTP Obligated Funds Report (data as of 2026-07-31,",
                  "posted 2026-10-08), Budget Period 1")
OB_AS_OF <- "2026-07-31"
OB_SOURCE <- "CMS_OBLIGATION_REPORT"
OB_RULING <- "owner ruling 2026-10-12 (session 98)"
OB_FED <- "data/evidence/federal_records"

OB_ENROL_FILES <- c(
  NE_HOSP = file.path(OB_FED, "2026-09-25", "cms_hosp_enrollments_NE.json"),
  PA_HOSP = file.path(OB_FED, "2026-09-25", "cms_hosp_enrollments_PA.json"),
  RI_HOSP = file.path(OB_FED, "2026-10-12", "cms_hosp_enrollments_RI.json"),
  RI_FQHC = file.path(OB_FED, "2026-10-12", "cms_fqhc_enrollments_RI.json"))

# The NE and PA lines the owner ruled on. Keyed on line id AND the report's
# exact recipient string AND amount: a re-parse that moves any of them stops.
OB_NE_PA <- tribble(
  ~line_id,        ~state, ~org,                            ~amount,
  "NE-002-08-13",  "NE",   "Nebraska Hospital Association", 3474937.50,
  "NE-004-26-116", "NE",   "Mayo Clinic",                   120000.00,
  "NE-004-16-59",  "NE",   "CHI Health St Marys",           38239.96,
  "NE-004-18-70",  "NE",   "CHI Health St Marys",           2584.53,
  "PA-005-20-59",  "PA",   "The Guthrie Clinic",            386553.62,
  "PA-005-21-60",  "PA",   "The Guthrie Clinic",            2577023.38)

# Name overlaps the dedupe found and a human READ (session 98). Each is the
# same organisation as an existing row and a DIFFERENT award, so it is written.
OB_NAME_OVERLAPS <- tribble(
  ~line_id,       ~existing_file,                         ~existing_row, ~why,
  "NE-004-16-59", "data/reference/ne_year1_awardees.csv", "40",
  paste("Existing row 40 'CHI St. Mary's' is the same hospital (CMS NE",
        "enrolment: ST MARYS COMMUNITY HOSPITAL dba CHI HEALTH ST MARYS, CCN",
        "281342) on a DIFFERENT award: Initiative 4.4b Remote Patient",
        "Monitoring, $908,475.54, on DHHS's Notice of Award. This CMS line is",
        "healthcare-associated INFECTION PREVENTION, $38,239.96; no infection-",
        "prevention pool is in ne_year1_awardees.csv at all. Not a duplicate."),
  "NE-004-18-70", "data/reference/ne_year1_awardees.csv", "40",
  paste("As NE-004-16-59: the same hospital as row 40, an infection-prevention",
        "line of $2,584.53 against row 40's RPM award. Not a duplicate."))

# --- the Rhode Island recipients -----------------------------------------------
# Every distinct string the report prints on a single-recipient RI line, mapped
# to one organisation and its typing. Each organisation was screened against
# CMS's RI Hospital and FQHC Enrollment files (archived 2026-10-12, session 97).
# One matched: the Narragansett Indian Tribe (FQHC, CCN 411809). No RI line
# names an enrolled hospital. Every other form is stated by the name itself
# (a state department) or is general knowledge, and is marked so.
OB_RI_ORGS <- tribble(
  ~printed, ~org, ~recipient_type, ~basis_type, ~confidence, ~flag_reason, ~form,
  "Hospital Association of Rhode Island (HARI)", "Hospital Association of Rhode Island", "NONPROFIT_CBO", "GENERAL_KNOWLEDGE", "LOW", "CMS_OBLIGATION_ASSOCIATION", "the state hospital association (its name)",
  "HARI", "Hospital Association of Rhode Island", "NONPROFIT_CBO", "GENERAL_KNOWLEDGE", "LOW", "CMS_OBLIGATION_ASSOCIATION", "the state hospital association (its name)",
  "RIDOH", "Rhode Island Department of Health", "STATE_AGENCY", "STATE_SOURCE", "MEDIUM", NA, "a state department (its name)",
  "Rhode Island Department of Education (RIDE)", "Rhode Island Department of Education", "STATE_AGENCY", "STATE_SOURCE", "MEDIUM", NA, "a state department (its name)",
  "RIDE", "Rhode Island Department of Education", "STATE_AGENCY", "STATE_SOURCE", "MEDIUM", NA, "a state department (its name)",
  "Department of Labor and Training (DLT)", "Rhode Island Department of Labor and Training", "STATE_AGENCY", "STATE_SOURCE", "MEDIUM", NA, "a state department (its name)",
  "Behavioral Healthcare, Developmental Disabilities & Hospitals (BHDDH)", "Rhode Island Department of Behavioral Healthcare, Developmental Disabilities & Hospitals", "STATE_AGENCY", "STATE_SOURCE", "MEDIUM", NA, "a state department (its name). The STATE OF RHODE ISLAND holds Eleanor Slater Hospital's enrolment (CCN 412001); a state agency that operates a state hospital is not a hospital recipient (session 97, the Texas DSHS/HHSC rule)",
  "BHDDH", "Rhode Island Department of Behavioral Healthcare, Developmental Disabilities & Hospitals", "STATE_AGENCY", "STATE_SOURCE", "MEDIUM", NA, "a state department (its name). The STATE OF RHODE ISLAND holds Eleanor Slater Hospital's enrolment (CCN 412001); a state agency that operates a state hospital is not a hospital recipient (session 97, the Texas DSHS/HHSC rule)",
  "EOHHS", "Rhode Island Executive Office of Health and Human Services", "STATE_AGENCY", "STATE_SOURCE", "MEDIUM", NA, "the state Medicaid agency, the RHTP grantee itself",
  "Alvarez & Marsal", "Alvarez & Marsal", "VENDOR_OR_CONTRACTOR", "GENERAL_KNOWLEDGE", "LOW", NA, "a management consulting firm",
  "Guidesoft", "Guidesoft", "VENDOR_OR_CONTRACTOR", "GENERAL_KNOWLEDGE", "LOW", NA, "a staffing and IT services firm",
  "RDW Group", "RDW Group", "VENDOR_OR_CONTRACTOR", "GENERAL_KNOWLEDGE", "LOW", NA, "a communications and marketing agency",
  "Chace Ruttenberg & Freedman", "Chace Ruttenberg & Freedman", "VENDOR_OR_CONTRACTOR", "GENERAL_KNOWLEDGE", "LOW", NA, "a law firm",
  "RI College", "Rhode Island College", "UNIVERSITY_OR_AHC", "GENERAL_KNOWLEDGE", "LOW", NA, "a public college",
  "CTC-RI", "Care Transformation Collaborative of Rhode Island", "NONPROFIT_CBO", "GENERAL_KNOWLEDGE", "LOW", NA, "a nonprofit primary-care transformation collaborative",
  "Rhode Island Health Center Association (RIHCA)", "Rhode Island Health Center Association", "NONPROFIT_CBO", "GENERAL_KNOWLEDGE", "LOW", NA, "the state association of community health centres, not itself a health centre",
  "RIHCA", "Rhode Island Health Center Association", "NONPROFIT_CBO", "GENERAL_KNOWLEDGE", "LOW", NA, "the state association of community health centres, not itself a health centre",
  "Rhode Island League of Cities and Towns (RILCT)", "Rhode Island League of Cities and Towns", "OTHER", "GENERAL_KNOWLEDGE", "LOW", NA, "an association of the state's municipal governments, not itself a government",
  "Westerly Area Rest Meals (WARM) Center", "Westerly Area Rest Meals (WARM) Center", "NONPROFIT_CBO", "GENERAL_KNOWLEDGE", "LOW", NA, "a nonprofit shelter and meals provider",
  "WARM Center", "Westerly Area Rest Meals (WARM) Center", "NONPROFIT_CBO", "GENERAL_KNOWLEDGE", "LOW", NA, "a nonprofit shelter and meals provider",
  "Child & Family Services of Newport", "Child & Family Services of Newport County", "NONPROFIT_CBO", "GENERAL_KNOWLEDGE", "LOW", NA, "a nonprofit social-services agency",
  "Block Island Health Services (BIHS)", "Block Island Health Services", "NONPROFIT_CBO", "GENERAL_KNOWLEDGE", "LOW", "RECIPIENT_TYPE_INFERRED", "UNDETERMINED: not on CMS's RI Hospital or FQHC enrolment; §8's standing fallback",
  "Block Island Health Services", "Block Island Health Services", "NONPROFIT_CBO", "GENERAL_KNOWLEDGE", "LOW", "RECIPIENT_TYPE_INFERRED", "UNDETERMINED: not on CMS's RI Hospital or FQHC enrolment; §8's standing fallback",
  "BIHS", "Block Island Health Services", "NONPROFIT_CBO", "GENERAL_KNOWLEDGE", "LOW", "RECIPIENT_TYPE_INFERRED", "UNDETERMINED: not on CMS's RI Hospital or FQHC enrolment; §8's standing fallback",
  "Narragansett Indian Tribe (NIT)", "Narragansett Indian Tribe", "FQHC_OR_RHC", "ORG_WEBSITE", "MEDIUM", NA, "CMS FQHC enrolment: NARRAGANSETT INDIAN TRIBE dba NARRAGANSETT INDIAN HEALTH CENTR, CCN 411809",
  "NIT", "Narragansett Indian Tribe", "FQHC_OR_RHC", "ORG_WEBSITE", "MEDIUM", NA, "CMS FQHC enrolment: NARRAGANSETT INDIAN TRIBE dba NARRAGANSETT INDIAN HEALTH CENTR, CCN 411809")
OB_RI_FQHC <- c("Narragansett Indian Tribe" = "411809")

# --- inputs ------------------------------------------------------------------

ob_lines <- function() {
  readr::read_csv(OB_LINES, col_types = readr::cols(.default = "c"),
                  na = c("", "NA"))
}

ob_single_recipient <- function(l, state) {
  l %>%
    dplyr::filter(.data$state == !!state, !is.na(.data$named_orgs)) %>%
    dplyr::mutate(n_named = lengths(strsplit(.data$named_orgs, ";"))) %>%
    dplyr::filter(.data$n_named == 1L, .data$n_unnamed_others == "0")
}

ob_existing <- function(st) {
  f <- here::here("data", "reference", paste0(tolower(st), "_year1_awardees.csv"))
  readr::read_csv(f, col_types = readr::cols(.default = "c"))
}

ob_name_key <- function(x) {
  x <- tolower(x)
  x <- gsub("[‘’']", "", x)
  x <- gsub("\\b(chi health|chi|the|inc|llc)\\b", " ", x)
  x <- gsub("\\bst\\.?\\s", "st ", x)
  stringr::str_squish(gsub("[^a-z0-9 ]", " ", x))
}

#' Dedupe the NE and PA rows against the committed award files.
#' Refuses an amount match to the cent, and any unreviewed name overlap.
ob_dedupe <- function(rows = OB_NE_PA) {
  out <- purrr::map_dfr(unique(rows$state), function(st) {
    ex <- ob_existing(st)
    ex_amt <- suppressWarnings(round(as.numeric(ex$amount), 2))
    ex_key <- ob_name_key(ex$awardee)
    r <- rows[rows$state == st, ]
    purrr::map_dfr(seq_len(nrow(r)), function(i) {
      k <- ob_name_key(r$org[i])
      name_hit <- which(nzchar(k) & (ex_key == k |
                          stringr::str_detect(ex_key, stringr::fixed(k)) |
                          stringr::str_detect(k, stringr::fixed(ex_key))))
      amt_hit <- which(!is.na(ex_amt) & ex_amt == round(r$amount[i], 2))
      tibble::tibble(line_id = r$line_id[i], state = st, org = r$org[i],
                     amount = r$amount[i],
                     name_match_rows = paste(ex$row_no[name_hit], collapse = ";"),
                     name_match_awardees = paste(ex$awardee[name_hit], collapse = "; "),
                     amount_match_rows = paste(ex$row_no[amt_hit], collapse = ";"))
    })
  })
  if (any(nzchar(out$amount_match_rows))) {
    stop("[CMS obl] an obligation line's amount equals an existing row to the ",
         "cent: ", paste(out$line_id[nzchar(out$amount_match_rows)], collapse = ", "),
         ". Read both before writing anything (owner dedupe rule).", call. = FALSE)
  }
  named <- out[nzchar(out$name_match_rows), ]
  unreviewed <- setdiff(paste(named$line_id, named$name_match_rows),
                        paste(OB_NAME_OVERLAPS$line_id, OB_NAME_OVERLAPS$existing_row))
  if (length(unreviewed)) {
    stop("[CMS obl] name overlap(s) nobody has read: ",
         paste(unreviewed, collapse = ", "), ". Read the existing row and record ",
         "the verdict in OB_NAME_OVERLAPS before writing.", call. = FALSE)
  }
  out
}

# --- row construction ----------------------------------------------------------

ob_row <- function(line, row_no, org, recipient_type, flow_type, dist,
                   attribution, intermediary, confidence, flag_reason,
                   basis_type, determination_basis, ccn = NA_character_,
                   cms_enrolment_match = NA_character_,
                   cms_enrolment_record = NA_character_,
                   facility_state = NA_character_,
                   hospital_benefiting = NA_character_) {
  tibble::tibble(
    state = line$state,
    row_no = as.character(row_no),
    awardee = org,
    amount = line$amount,
    recipient_type = recipient_type,
    distributed_to_hospital = dist,
    note = paste0("CMS obligation line ", line$line_id, " (p. ", line$page,
                  "): \"", line$description_clean, "\""),
    recipient_confirmed = "Yes",
    amount_confirmed = "Yes",
    fiscal_year = "FY2026",
    source_document_title = OB_TITLE,
    state_source_url = OB_URL,
    validation_source_type = OB_SOURCE,
    extraction_method = "DIRECT_TEXT",
    validator = "AUTO",
    ccn = ccn,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    recipient_type_source = "CMS_OBLIGATION_REPORT_NAME",
    determination_confidence = confidence,
    flag_reason = flag_reason,
    award_pool = paste0(line$initiative, " | ", line$category),
    budget_period = "BP1",
    flow_type = flow_type,
    hospital_benefiting = hospital_benefiting,
    hospital_attribution = attribution,
    intermediary_name = intermediary,
    determination_basis = determination_basis,
    basis_type = basis_type,
    amount_basis = paste0("OBLIGATION as of ", OB_AS_OF, ", single-recipient ",
                          "line, as printed. Not an executed-award figure."),
    tier = "SUBAWARD",
    as_of = OB_AS_OF,
    cms_line_id = line$line_id,
    recipient_subtype = NA_character_,
    cms_enrolment_match = cms_enrolment_match,
    cms_enrolment_record = cms_enrolment_record,
    facility_state = facility_state,
    source_archive_path = OB_PDF)
}

OB_ASSOC_BASIS <- paste(
  "§10.2 PASS_THROUGH_DESIGNATED, hospital trade associations, applied BY",
  OB_RULING, ": counted as hospital money under the standing hospital-",
  "association rule, intermediary = the association, no hospital named, so",
  "POOL_UNNAMED_HOSPITALS (ICAHN's bucket). flag_reason",
  "CMS_OBLIGATION_ASSOCIATION makes it subtractable. CAUTION, recorded for",
  "the reader: the line's own words describe work the association performs;",
  "§10.2's GHA/AHHA negatives code that IN_KIND_BENEFIT unless a source",
  "shows funds administered to hospitals, and no state document read shows",
  "either. The source is CMS's compilation of the state's self-reported",
  "obligation as of 2026-07-31, not a state notice of award.")

ob_ne_pa_rows <- function(l = ob_lines()) {
  ob_dedupe()
  sel <- l %>% dplyr::filter(.data$line_id %in% OB_NE_PA$line_id)
  chk <- dplyr::inner_join(sel, OB_NE_PA, by = c("line_id", "state"))
  if (nrow(chk) != nrow(OB_NE_PA) ||
      !all(chk$named_orgs == chk$org) ||
      !all(abs(as.numeric(chk$amount.x) - chk$amount.y) < 0.005)) {
    stop("[CMS obl] the six ruled NE/PA lines no longer match the parse ",
         "(id, string or amount). Re-read R/00c's output.", call. = FALSE)
  }
  rows <- purrr::map_dfr(seq_len(nrow(OB_NE_PA)), function(i) {
    line <- sel[sel$line_id == OB_NE_PA$line_id[i], ]
    org <- OB_NE_PA$org[i]
    switch(
      org,
      "Nebraska Hospital Association" = ob_row(
        line, i, org, "NONPROFIT_CBO", "PASS_THROUGH_DESIGNATED", "Yes",
        "POOL_UNNAMED_HOSPITALS", org, "LOW", "CMS_OBLIGATION_ASSOCIATION",
        "GENERAL_KNOWLEDGE", OB_ASSOC_BASIS, hospital_benefiting = "Yes"),
      "Mayo Clinic" = ob_row(
        line, i, org, "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes", "NAMED_HOSPITAL",
        NA_character_, "LOW", NA_character_, "GENERAL_KNOWLEDGE",
        paste("SYSTEM PARENT, GENERAL KNOWLEDGE (", OB_RULING, "; the SD",
              "Sanford/Avera treatment, R/03i): Mayo Clinic (Rochester, MN) is",
              "a hospital system. 'Mayo Clinic' is not on CMS's NE Hospital",
              "Enrollments, so no CCN; LOW. OUT-OF-STATE: facility_state = MN;",
              "the row stays in Nebraska's figure (National Jewish Health in",
              "Michigan's file is the precedent) and can be subtracted. §10.2",
              "DIRECT on recipient identity (§0.3a); the line's activity --",
              "'provide chronic disease management services' in the Training",
              "and Technical Assistance category -- does not decide it."),
        facility_state = "MN", hospital_benefiting = "Yes"),
      "CHI Health St Marys" = ob_row(
        line, i, org, "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes", "NAMED_HOSPITAL",
        NA_character_, "LOW", NA_character_, "ORG_WEBSITE",
        paste("RECIPIENT TYPE FROM CMS HOSPITAL ENROLMENT (", OB_RULING, "):",
              "'CHI Health St Marys' is the DOING BUSINESS AS NAME of ST MARYS",
              "COMMUNITY HOSPITAL, Nebraska City, a critical access hospital,",
              "CCN 281342. DBA_OF_LEGAL_ENTITY is a hand-read bridge, so LOW.",
              "§10.2 DIRECT. Deduped against ne_year1_awardees.csv row 40",
              "(the same hospital's RPM award): a different award, kept."),
        ccn = "281342", cms_enrolment_match = "DBA_OF_LEGAL_ENTITY",
        cms_enrolment_record = paste(
          "CMS Hospital Enrollments: ST MARYS COMMUNITY HOSPITAL dba CHI",
          "HEALTH ST MARYS, NEBRASKA CITY, NE, CCN 281342 (PART A PROVIDER -",
          "CRITICAL ACCESS HOSPITAL);", OB_ENROL_FILES[["NE_HOSP"]]),
        facility_state = "NE", hospital_benefiting = "Yes"),
      "The Guthrie Clinic" = ob_row(
        line, i, org, "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes", "NAMED_HOSPITAL",
        NA_character_, "LOW", NA_character_, "GENERAL_KNOWLEDGE",
        paste("SYSTEM PARENT, GENERAL KNOWLEDGE (", OB_RULING, "; the SD",
              "Sanford/Avera treatment, R/03i): The Guthrie Clinic (Sayre, PA)",
              "is the parent system of Robert Packer Hospital and Guthrie's",
              "other hospitals, which enrol with CMS under their own legal",
              "entities (e.g. ROBERT PACKER HOSPITAL, Sayre); 'The Guthrie",
              "Clinic' is not on CMS's PA Hospital Enrollments, so no CCN;",
              "LOW. §10.2 DIRECT. Not the same award as pa_year1_awardees.csv's",
              "Robert Packer row: this is the Pulse Center Pilot (virtual",
              "telesitting and nursing)."),
        facility_state = "PA", hospital_benefiting = "Yes"),
      stop("[CMS obl] no rule for ", org, call. = FALSE))
  })
  rows
}

ob_ri_rows <- function(l = ob_lines()) {
  s <- ob_single_recipient(l, "RI")
  miss <- setdiff(unique(s$named_orgs), OB_RI_ORGS$printed)
  if (length(miss)) {
    stop("[CMS obl] RI single-recipient strings with no typing: ",
         paste(miss, collapse = "; "), ". Read each and add it to OB_RI_ORGS.",
         call. = FALSE)
  }
  if (!all(s$amount_usable == "TRUE")) {
    stop("[CMS obl] an RI line is flagged amount_usable = FALSE.", call. = FALSE)
  }
  s <- s %>% dplyr::left_join(OB_RI_ORGS, by = c("named_orgs" = "printed"))
  purrr::map_dfr(seq_len(nrow(s)), function(i) {
    o <- s[i, ]
    # The FQHC enrolment TYPES the row but goes in cms_enrolment_record only:
    # `ccn` and cms_enrolment_match mean "re-typed as a HOSPITAL on its
    # enrolment" (§10.2, R/03bj), which an FQHC never is.
    enrol <- if (o$org %in% names(OB_RI_FQHC)) {
      list(ccn = NA_character_, match = NA_character_,
           rec = paste("CMS FQHC Enrollments: NARRAGANSETT INDIAN TRIBE dba",
                       "NARRAGANSETT INDIAN HEALTH CENTR, CCN 411809;",
                       OB_ENROL_FILES[["RI_FQHC"]]))
    } else {
      list(ccn = NA_character_, match = NA_character_,
           rec = paste("Screened 2026-10-12 against CMS RI Hospital and FQHC",
                       "Enrollments: NO MATCH;", OB_ENROL_FILES[["RI_HOSP"]], "+",
                       OB_ENROL_FILES[["RI_FQHC"]]))
    }
    if (o$flag_reason %in% "CMS_OBLIGATION_ASSOCIATION") {
      ob_row(o, i, o$org, o$recipient_type, "PASS_THROUGH_DESIGNATED", "Yes",
             "POOL_UNNAMED_HOSPITALS", o$org, o$confidence, o$flag_reason,
             o$basis_type, paste(OB_ASSOC_BASIS, "Form:", o$form),
             cms_enrolment_record = enrol$rec, facility_state = "RI",
             hospital_benefiting = "Yes")
    } else {
      ob_row(o, i, o$org, o$recipient_type, "NON_HOSPITAL", "No",
             "NOT_HOSPITAL", NA_character_, o$confidence, o$flag_reason,
             o$basis_type,
             paste0("Typed on CMS enrolment first (", OB_RULING, "): ",
                    if (o$org %in% names(OB_RI_FQHC)) "the RI FQHC enrolment matches. " else "no RI Hospital or FQHC enrolment matches. ",
                    "Determined form: ", o$form, " (", o$basis_type, "). §10.2 NON_HOSPITAL: the ",
                    "recipient is not a hospital (§0.3a, recipient not ",
                    "activity)."),
             ccn = enrol$ccn, cms_enrolment_match = enrol$match,
             cms_enrolment_record = enrol$rec, facility_state = "RI",
             hospital_benefiting = "No")
    }
  })
}

# --- assertions --------------------------------------------------------------

ob_assert <- function(d, label) {
  for (col in c("recipient_type", "distributed_to_hospital", "flow_type",
                "determination_confidence", "basis_type",
                "hospital_attribution")) {
    bad <- setdiff(stats::na.omit(unique(d[[col]])), rhtp_vocabulary(col))
    if (length(bad)) stop("[CMS obl] ", label, " ", col, " outside §8: ",
                          paste(bad, collapse = ", "), call. = FALSE)
  }
  fr <- setdiff(stats::na.omit(unique(d$flag_reason)), rhtp_vocabulary("flag_reason"))
  if (length(fr)) stop("[CMS obl] ", label, " flag_reason outside §8: ", fr, call. = FALSE)
  if (!all(d$validation_source_type == OB_SOURCE) ||
      !OB_SOURCE %in% rhtp_vocabulary("source_doc_type")) {
    stop("[CMS obl] ", label, ": every row must carry ", OB_SOURCE, call. = FALSE)
  }
  if (any(d$determination_confidence == "HIGH")) {
    stop("[CMS obl] ", label, ": nothing here is HIGH (§7).", call. = FALSE)
  }
  assoc <- d$flag_reason %in% "CMS_OBLIGATION_ASSOCIATION"
  if (any(assoc & (d$hospital_attribution != "POOL_UNNAMED_HOSPITALS" |
                   d$flow_type != "PASS_THROUGH_DESIGNATED"))) {
    stop("[CMS obl] ", label, ": an association row outside ",
         "PASS_THROUGH_DESIGNATED / POOL_UNNAMED_HOSPITALS.", call. = FALSE)
  }
  gk <- d$basis_type == "GENERAL_KNOWLEDGE"
  if (any(gk & d$determination_confidence != "LOW")) {
    stop("[CMS obl] ", label, ": GENERAL_KNOWLEDGE must be LOW (§0.4).", call. = FALSE)
  }
  invisible(TRUE)
}

#' R/03bj's enrolled-hospital overlay, chained as R/03bt chains it: a row
#' typed on its CMS hospital enrolment carries a verdict in EH_APPLY and the
#' session-71 tag on its basis (CHI Health St Marys). A no-op on PA and RI.
ob_s71 <- function(d, file) {
  s71 <- new.env()
  suppressMessages(source(here::here("R", "03bj_enrolled_hospital_operator.R"),
                          local = s71))
  num <- function(x) ifelse(is.na(x), NA_character_,
                            vapply(x, function(v) format(v, scientific = FALSE, digits = 15),
                                   character(1)))
  d <- dplyr::mutate(d, dplyr::across(dplyr::where(is.numeric), num),
                     dplyr::across(dplyr::everything(), as.character))
  s71$s71_overlay(d, file)
}

ob_build <- function() {
  l <- ob_lines()
  np <- ob_ne_pa_rows(l)
  ri <- ob_ri_rows(l)
  out <- list(NE = np[np$state == "NE", ], PA = np[np$state == "PA", ], RI = ri)
  for (k in names(out)) {
    d <- out[[k]] %>% dplyr::mutate(row_no = as.character(dplyr::row_number()))
    d <- ob_s71(d, basename(OB_OUT[[k]]))
    ob_assert(d, k)
    readr::write_csv(d, OB_OUT[[k]], na = "")
    message("[CMS obl] wrote ", basename(OB_OUT[[k]]), ": ", nrow(d), " rows, $",
            format(sum(as.numeric(d$amount)), big.mark = ",", nsmall = 2))
  }
  invisible(out)
}

ob_report <- function() {
  for (k in names(OB_OUT)) {
    d <- readr::read_csv(OB_OUT[[k]], col_types = readr::cols(.default = "c"))
    cat(sprintf("\n%s  %d rows  $%s\n", basename(OB_OUT[[k]]), nrow(d),
                format(sum(as.numeric(d$amount)), big.mark = ",", nsmall = 2)))
    d %>% dplyr::group_by(.data$hospital_attribution, .data$recipient_type) %>%
      dplyr::summarise(rows = dplyr::n(), dollars = sum(as.numeric(.data$amount)),
                       .groups = "drop") %>% as.data.frame() %>% print()
  }
  print(ob_dedupe())
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--build" %in% args) {
    ob_build(); ob_report()
  } else if ("--report" %in% args) {
    ob_report()
  } else {
    message("Usage: Rscript R/03cb_cms_obligation_rows.R [--build | --report]")
  }
}
