#!/usr/bin/env Rscript
# 03bt_ok_new_rosters.R --------------------------------------------------------
#
# OKLAHOMA'S THIRD, FOURTH AND FIFTH ROSTERS. Session 85.
#
# The OK Routine tripped on 2026-10-01 18:12Z: "Expanding Care: Doulas
# Program" was on the Funding Recipients page. Read on 10-02, the page carries
# THREE new rosters, not one, each "List of Funding Recipients" with a name
# and an exact amount per line:
#
#   Rural Regional Reorientation (RRR)   20 recipients   $39,578,523.00
#   Expanding Care: Doulas                4 recipients      $647,967.83
#   Chronic Disease Management (CDM)     15 recipients   $15,608,845.22
#
# SESSION 86: RRR AND CDM ARE NOW WRITTEN, on the owner's instruction, each to
# its own file (ok_year1_rrr_awardees.csv, ok_year1_cdm_awardees.csv). Every
# row is HAND-TYPED in OKN_RRR_CDM_TYPING against the archived CMS OK Hospital
# (federal_records/2026-09-25) and FQHC (federal_records/2026-10-02) Enrollment
# files; nothing is left to the name rule, which calls Central Oklahoma Family
# Medical Center a hospital (it is an FQHC on CMS's file) and misses Mercy,
# McCurtain and Ascension Jane Phillips. The owner's instructions, applied:
#   * Mercy, Fairview, Lindsay and Ascension Jane Phillips are LOW: none is an
#     exact legal-name match (DBA, reversed truncation, trading name, or no
#     enrolment at all).
#   * Choctaw Nation follows §10.2's precedence rule: OSDH's entry states no
#     form, so the CMS enrolment decides -- CHOCTAW NATION OF OKLAHOMA is the
#     ORGANIZATION NAME on hospital CCN 370172, exact, MEDIUM.
#   * Central Oklahoma Family Medical Center is checked against the FQHC file:
#     exact legal name, sixteen FQHC sites, no hospital enrolment.
#
# (Session 85's text follows.) ONLY DOULAS WAS WRITTEN. The owner's standing instruction is to report before
# extracting anything over $10M, and RRR and CDM are both over it. They are
# PARSED and ASSERTED here (count and total), so the day they are approved
# the work is a typing pass and a --build, not a re-read -- but no file
# carries them and nothing in the partition moves for them. `--report` prints
# all three.
#
# A SEPARATE FILE, NOT ROWS APPENDED TO ok_year1_awardees.csv. That file
# carries session 49's ROW-INDEX overlay and R/03bj's, and R/03t's --build
# does not re-apply 49's; it is built from the 2026-08-31 archive, which this
# page's 10-02 copy does not replace. North Carolina SBHC's and Alabama round
# 2's precedent: a second file for a later roster.
#
# DOULAS TYPING (hand-read, each checked against an archived federal file):
#   * Newman Memorial Hospital, $38,525 -- HOSPITAL_OR_SYSTEM. CMS Hospital
#     Enrollments (OK, 2026-09-25): NEWMAN MEMORIAL HOSPITAL, INC, PART A
#     PROVIDER - CRITICAL ACCESS HOSPITAL, CCN 371336, Shattuck. The awardee
#     string is the legal name less ", Inc" (EXACT_LEGAL_NAME, MEDIUM). The
#     activity is a doula workforce programme; §0.3a judges the recipient.
#   * Board of Regents of the University of Oklahoma Health Sciences Center,
#     $5,445.49 -- UNIVERSITY_OR_AHC. The programme named under it is the
#     Oklahoma Breastfeeding Resource Center. OU's hospital is enrolled by a
#     DIFFERENT legal body (OU MEDICINE INC, CCN 370093), so §10.2's
#     enrolled-operator row does not reach the Board of Regents (§2: a name
#     that is a prefix of another body is never matched).
#   * Tulsa Community Foundation, $240,907 -- NONPROFIT_CBO, the source's own
#     words: "fiscal sponsor for Oklahoma Birth Equity Initiative". A
#     community foundation, not a hospital foundation (§10.2: the test is the
#     PARENT, and it has none).
#   * Western Plains Youth and Family Services, $363,090.34 -- §8's standing
#     fallback (no stated form, no federal record searched beyond the hospital
#     file, where it is absent).
#
# §0.2: the page's CMS footer prints $223,476,948.62, OK's ALLOTMENT (Tier 1).
#
# Usage:
#   Rscript R/03bt_ok_new_rosters.R --validate | --build | --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

OKN_STATE    <- "OK"
OKN_URL      <- "https://oklahoma.gov/health/rhtp/rhtp-funding-recipients.html"
OKN_ARCHIVE  <- file.path("data", "evidence", "OK", "new_rosters",
                         "2026-10-02_ok_rhtp_funding_recipients.html")
OKN_SHA256   <- "7aa998ab5f362d880dd73181c643ab4080fe122079b951d9283b131e44e8e056"
OKN_READ     <- as.Date("2026-10-02")
OKN_NOA_DATE <- as.Date("2025-12-29")
OKN_CSV      <- here::here("data", "reference", "ok_year1_doulas_awardees.csv")
OKN_HOSP_FED <- file.path("data", "evidence", "federal_records", "2026-09-25",
                          "cms_hosp_enrollments_OK.json")
OKN_FOOTER   <- "as part of a financial assistance award totaling $223,476,948.62 with 100 percent funded by CMS/HHS"

# Each roster: the heading it sits under, the heading that ends it, and the
# count and total READ on 2026-10-02 (asserted, never assumed).
OKN_ROSTERS <- tibble::tribble(
  ~key,      ~round_name,                       ~start,                                                   ~end,                                  ~n,  ~total,       ~written,
  "rrr",     "Rural Regional Reorientation (RRR) Program", "RRR Program: List of Funding Recipients",     "Expanding Care: Doulas Program",      20L, 39578523.00, TRUE,
  "doulas",  "Expanding Care: Doulas Program",  "Expanding Care: Doulas Program: List of Funding Recipients", "Chronic Disease Management Program", 4L,  647967.83,   TRUE,
  "cdm",     "Chronic Disease Management Program", "Chronic Disease Management Program: List of Funding Recipients", "OSDE's ROOTS Competitive Grant", 15L, 15608845.22, TRUE)

okn_lines <- function() {
  raw <- readr::read_file_raw(here::here(OKN_ARCHIVE))
  if (digest::digest(raw, algo = "sha256", serialize = FALSE) != OKN_SHA256) {
    stop("[OK new rosters] the archive's SHA-256 does not match its manifest.",
         call. = FALSE)
  }
  h <- xml2::read_html(raw)
  t <- rvest::html_text2(rvest::html_element(h, "main"))
  t <- gsub("​", "", t, fixed = TRUE)
  x <- stringr::str_squish(strsplit(t, "\n", fixed = TRUE)[[1]])
  x[nzchar(x)]
}

#' One roster's recipient lines: "Name, $amount" or "Name $amountCounties ..."
okn_parse <- function(key, x = okn_lines(), n_detail = 2L) {
  r <- OKN_ROSTERS[OKN_ROSTERS$key == key, ]
  i <- which(x == r$start)
  if (length(i) != 1L) stop("[OK new rosters] '", r$start, "' heading not found once.",
                            call. = FALSE)
  j <- which(x == r$end); j <- j[j > i][1]
  if (is.na(j)) stop("[OK new rosters] no end heading after '", r$start, "'.", call. = FALSE)
  y <- x[(i + 1):(j - 1)]
  m <- stringr::str_match(y, "^(.+?),?\\s+\\$([0-9][0-9,]*(?:\\.[0-9]{1,2})?)(?:\\s|Counties|$)")
  k <- which(!is.na(m[, 1]))
  tibble::tibble(round = key, line = y[k], awardee = stringr::str_trim(m[k, 2]),
                 amount = as.numeric(gsub(",", "", m[k, 3])),
                 detail = vapply(k, function(z) paste(y[seq(z + 1, min(z + n_detail, length(y)))],
                                                      collapse = " "), character(1)))
}

okn_assert_source <- function(x = okn_lines()) {
  # The CMS footer sits outside <main>, so it is read off the whole page.
  full <- stringr::str_squish(rvest::html_text2(xml2::read_html(here::here(OKN_ARCHIVE))))
  if (!grepl(OKN_FOOTER, full, fixed = TRUE)) {
    stop("[OK new rosters] the CMS footer is gone from the archive.", call. = FALSE)
  }
  t <- paste(x, collapse = " ")
  for (s in c("This page provides information about funded projects, award amounts, and the organizations selected to receive RHTP funding.")) {
    if (!grepl(s, t, fixed = TRUE)) stop("[OK new rosters] missing: '", s, "'.", call. = FALSE)
  }
  for (k in OKN_ROSTERS$key) {
    r <- OKN_ROSTERS[OKN_ROSTERS$key == k, ]
    p <- okn_parse(k, x)
    if (nrow(p) != r$n || abs(sum(p$amount) - r$total) > 0.005) {
      stop("[OK new rosters] ", k, ": read ", nrow(p), " rows / $",
           format(sum(p$amount), big.mark = ",", nsmall = 2), "; the 10-02 read was ",
           r$n, " / $", format(r$total, big.mark = ",", nsmall = 2), ".", call. = FALSE)
    }
    # A roster figure is never the allotment (§0.2).
    if (any(abs(p$amount - 223476949) < RHTP_FOOTER_ALLOTMENT_MARGIN)) {
      stop("[OK new rosters] an award line equals the allotment.", call. = FALSE)
    }
  }
  if (!(OKN_READ > OKN_NOA_DATE)) stop("[OK new rosters] §6.2 date test.", call. = FALSE)
  invisible(TRUE)
}

OKN_DOULAS_TYPING <- tibble::tribble(
  ~awardee, ~recipient_type, ~basis_type, ~confidence, ~ccn, ~enrol_match, ~why,
  "Board of Regents of the University of Oklahoma Health Sciences Center",
  "UNIVERSITY_OR_AHC", "STATE_SOURCE", "MEDIUM", NA, NA,
  "The awardee is a university's board of regents; the programme named under it is the Oklahoma Breastfeeding Resource Center. OU's hospital is enrolled by a DIFFERENT legal body (CMS OK Hospital Enrollments: OU MEDICINE INC dba OU HEALTH UNIVERSITY OF OKLAHOMA MEDICAL CENTER, CCN 370093), so §10.2's enrolled-operator row does not reach it.",
  "Newman Memorial Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "371336", "EXACT_LEGAL_NAME",
  "§10.2 DIRECT: CMS OK Hospital Enrollments (federal_records/2026-09-25) carry NEWMAN MEMORIAL HOSPITAL, INC, PART A PROVIDER - CRITICAL ACCESS HOSPITAL, CCN 371336, Shattuck -- the awardee's legal name less its corporate suffix. The activity is a doula workforce programme; §0.3a judges the recipient.",
  "Tulsa Community Foundation", "NONPROFIT_CBO", "STATE_SOURCE", "MEDIUM", NA, NA,
  "The source: 'Tulsa Community Foundation is the fiscal sponsor for Oklahoma Birth Equity Initiative (OKBEI)'. A community foundation with no hospital parent (§10.2: the test is the PARENT).",
  "Western Plains Youth and Family Services", NA, NA, NA, NA, NA,
  "No stated form and no CMS hospital enrolment under this name: §8's standing fallback, NOT promoted (§0.4)."
)

okn_assert_federal <- function() {
  e <- jsonlite::fromJSON(here::here(OKN_HOSP_FED))
  nm <- e[["ORGANIZATION NAME"]]
  if (!"371336" %in% e$CCN[nm == "NEWMAN MEMORIAL HOSPITAL, INC"]) {
    stop("[OK new rosters] the archived OK hospital file no longer carries Newman (371336).",
         call. = FALSE)
  }
  if (any(grepl("REGENTS|TULSA COMMUNITY FOUNDATION|WESTERN PLAINS", nm))) {
    stop("[OK new rosters] a non-hospital Doulas awardee now appears in the OK ",
         "hospital enrolment file -- re-type it.", call. = FALSE)
  }
  invisible(TRUE)
}

okn_doulas <- function(p = okn_parse("doulas")) {
  ty <- OKN_DOULAS_TYPING[match(p$awardee, OKN_DOULAS_TYPING$awardee), ]
  if (any(is.na(ty$awardee))) {
    stop("[OK new rosters] no hand-read typing for: ",
         paste(p$awardee[is.na(ty$awardee)], collapse = "; "), call. = FALSE)
  }
  cls <- rhtp_classify_recipient_type(p$awardee, OKN_STATE)
  typed <- !is.na(ty$recipient_type)
  rtype <- ifelse(typed, ty$recipient_type, cls$recipient_type)
  hosp <- rtype == "HOSPITAL_OR_SYSTEM"
  tibble::tibble(
    state = OKN_STATE,
    row_no = seq_len(nrow(p)),
    awardee = p$awardee,
    amount = p$amount,
    recipient_type = rtype,
    distributed_to_hospital = ifelse(hosp, "Yes", "No"),
    note = paste0("Expanding Care: Doulas Program, List of Funding Recipients (OSDH, read ",
                  OKN_READ, "). ", p$detail),
    recipient_confirmed = "Yes",
    amount_confirmed = "Yes",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = "Oklahoma RHTP Funding Recipients -- Expanding Care: Doulas Program, List of Funding Recipients",
    state_source_url = OKN_URL,
    validation_source_type = "NOTICE_OF_AWARD",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03bt_ok_new_rosters.R",
    ccn = ty$ccn,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    recipient_type_source = ifelse(
      typed, paste0("TYPED (session 85, HAND-READ): ", ty$why, " Classifier said ",
                    cls$recipient_type, "/", cls$determination_confidence, "."),
      paste0("rhtp_classify_recipient_type() on the name: ", cls$recipient_type, "/",
             cls$determination_confidence, ". ", ty$why)),
    determination_confidence = ifelse(typed, ty$confidence, cls$determination_confidence),
    flag_reason = ifelse(typed, NA_character_, "RECIPIENT_TYPE_INFERRED"),
    award_pool = "Expanding Care: Doulas Program",
    budget_period = "Budget Period 1",
    flow_type = ifelse(hosp, "DIRECT", "NON_HOSPITAL"),
    hospital_benefiting = ifelse(hosp, "Yes", "Unclear"),
    hospital_attribution = ifelse(hosp, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = paste0("§10.2 ", ifelse(hosp, "DIRECT", "NON_HOSPITAL"), ": ", ty$why),
    amount_basis = "EXACT, as published per recipient by OSDH.",
    round_name = "Expanding Care: Doulas Program",
    round_awards = nrow(p),
    round_amount = NA_real_,
    announcement_date = OKN_READ,
    source_archive_path = OKN_ARCHIVE,
    basis_type = ty$basis_type,
    recipient_subtype = NA_character_,
    cms_enrolment_match = ty$enrol_match,
    cms_enrolment_record = ifelse(
      !is.na(ty$enrol_match),
      paste0("CMS Hospital Enrollments: NEWMAN MEMORIAL HOSPITAL, INC, CCN 371336 (", OKN_HOSP_FED, ")"),
      NA_character_))
}

okn_assert_rows <- function(a) {
  if (nrow(a) != 4L || abs(sum(a$amount) - 647967.83) > 0.005) {
    stop("[OK Doulas] four rows, $647,967.83.", call. = FALSE)
  }
  h <- a[a$distributed_to_hospital == "Yes", ]
  if (nrow(h) != 1L || h$awardee != "Newman Memorial Hospital") {
    stop("[OK Doulas] exactly one hospital row, Newman Memorial.", call. = FALSE)
  }
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "determination_confidence", "hospital_attribution", "basis_type",
                "flag_reason", "cms_enrolment_match")) {
    bad <- setdiff(stats::na.omit(unique(a[[col]])), rhtp_vocabulary(col))
    if (length(bad)) stop("[OK Doulas] ", col, " outside §8: ", paste(bad, collapse = ", "),
                          call. = FALSE)
  }
  invisible(TRUE)
}

OKN_FQHC_FED <- file.path("data", "evidence", "federal_records", "2026-10-02",
                          "cms_fqhc_enrollments_OK.json")
OKN_RRR_CSV  <- here::here("data", "reference", "ok_year1_rrr_awardees.csv")
OKN_CDM_CSV  <- here::here("data", "reference", "ok_year1_cdm_awardees.csv")

# THE RRR AND CDM TYPING (session 86). One row per (roster, awardee as OSDH
# prints it). `flow` NA = derived from the type (DIRECT for a hospital,
# NON_HOSPITAL otherwise); set only where the award text decides it.
# `enrol` is the CMS record the row rests on: "H:<ORG NAME>|<CCN>" (Hospital
# Enrollments, 2026-09-25) or "F:<ORG NAME>|<CCN>" (FQHC Enrollments,
# 2026-10-02). A type of NONPROFIT_CBO with confidence LOW is §8's standing
# fallback: no form stated and no CMS hospital or FQHC record under the name.
OKN_FB <- "No form stated by OSDH and no CMS OK hospital or FQHC enrolment under this name: §8's standing fallback, NOT promoted (§0.4)."
OKN_RRR_CDM_TYPING <- tibble::tribble(
  ~key, ~awardee, ~recipient_type, ~basis_type, ~confidence, ~ccn, ~enrol_match, ~flow, ~enrol, ~why,
  # ---- RRR ----------------------------------------------------------------
  "rrr", "Ascension St. John Jane Phillips Medical Center", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", "370018", "DBA_OF_LEGAL_ENTITY", NA,
  "H:JANE PHILLIPS MEMORIAL MEDICAL CENTER INC|370018",
  "§10.2 DIRECT on a HAND-READ BRIDGE: CMS OK Hospital Enrollments carry JANE PHILLIPS MEMORIAL MEDICAL CENTER INC, PART A PROVIDER - HOSPITAL, CCN 370018, Bartlesville, with no DBA on the record; 'Ascension St. John Jane Phillips Medical Center' is that hospital's trading name under Ascension St. John (general knowledge, not on the record). Not an exact legal-name match, so LOW (owner's instruction, session 86).",
  "rrr", "Brighter Heights Oklahoma", "NONPROFIT_CBO", NA, "LOW", NA, NA, NA, NA, OKN_FB,
  "rrr", "Cancer Centers of Southwest Oklahoma LLC", "NONPROFIT_CBO", NA, "LOW", NA, NA, NA, NA,
  "An LLC oncology provider with no CMS OK hospital enrolment under this name. §8's standing fallback, NOT promoted (§0.4).",
  "rrr", "CREOKS Mental Health Services, Inc. DBA CREOKS Health Services, Inc.", "NONPROFIT_CBO", NA, "LOW", NA, NA, NA, NA, OKN_FB,
  "rrr", "Fairview Regional Medical Center", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", "371329", "DBA_OF_LEGAL_ENTITY", NA,
  "H:FAIRVIEW REGIONAL MEDICAL CENTER AUTHORITY|371329",
  "§10.2 DIRECT: CMS OK Hospital Enrollments carry FAIRVIEW REGIONAL MEDICAL CENTER AUTHORITY dba FAIRVIEW REGIONAL MEDICAL CENTER, CRITICAL ACCESS HOSPITAL, CCN 371329, Fairview. The awardee string is the DBA, not the legal name, so LOW (owner's instruction, session 86).",
  "rrr", "Foundation for a Healthy Oklahoma DBA Oklahoma Perinatal Quality Improvement Collaborative (OPQIC)", "NONPROFIT_CBO", NA, "LOW", NA, NA, "IN_KIND_BENEFIT", NA,
  "A foundation with no hospital parent (§10.2: the test is the PARENT). The award 'Provide[s] 24 rural birthing hospitals with obstetric emergency training ... Funding will support training from certified instructors and supplies': training reaches hospitals, dollars do not -- the Georgia Hospital Association carts shape. IN_KIND_BENEFIT, hospital_benefiting = Yes, never in a hospital total.",
  "rrr", "Grand Lake Mental Health Center, Inc.", "NONPROFIT_CBO", NA, "LOW", NA, NA, NA, NA, OKN_FB,
  "rrr", "Green Country Behavioral Health Services, Inc.", "NONPROFIT_CBO", NA, "LOW", NA, NA, NA, NA, OKN_FB,
  "rrr", "Jackson County Memorial Hospital Authority", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "370022", "EXACT_LEGAL_NAME", NA,
  "H:JACKSON COUNTY MEMORIAL HOSPITAL AUTHORITY|370022",
  "§10.2 DIRECT: CMS OK Hospital Enrollments carry JACKSON COUNTY MEMORIAL HOSPITAL AUTHORITY dba JACKSON COUNTY MEMORIAL HOSPITAL, PART A PROVIDER - HOSPITAL, CCN 370022, Altus -- the awardee's exact legal name.",
  "rrr", "Keetoowah Economic Development Authority", "NONPROFIT_CBO", NA, "LOW", NA, NA, NA, NA, OKN_FB,
  "rrr", "Lighthouse Behavioral Wellness Centers, Inc.", "NONPROFIT_CBO", NA, "LOW", NA, NA, NA, NA, OKN_FB,
  "rrr", "Lindsay Municipal Hospital Authority", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", "370214", "LEGAL_NAME_TRUNCATED", NA,
  "H:LINDSAY MUNICIPAL HOSPITAL|370214",
  "§10.2 DIRECT on a HAND-READ BRIDGE: CMS OK Hospital Enrollments carry LINDSAY MUNICIPAL HOSPITAL, PART A PROVIDER - HOSPITAL, CCN 370214, Lindsay. The awardee string adds 'Authority' (an Oklahoma public-trust hospital authority) to the enrolled name, naming no different body. Recorded under LEGAL_NAME_TRUNCATED, the nearest bridge code, whose example runs the other way (the awardee shorter than the record); LOW (owner's instruction, session 86).",
  "rrr", "McCurtain Memorial Medical Management, Inc.", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "371342", "EXACT_LEGAL_NAME", NA,
  "H:MCCURTAIN MEMORIAL MEDICAL MANAGEMENT, INC.|371342",
  "§10.2 DIRECT: CMS OK Hospital Enrollments carry MCCURTAIN MEMORIAL MEDICAL MANAGEMENT, INC. dba MCCURTAIN MEMORIAL HOSPITAL, CRITICAL ACCESS HOSPITAL, CCN 371342, Idabel -- the awardee's exact legal name. The name rule misses it ('Medical Management').",
  "rrr", "Memorial Hospital of Texas County Authority", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "371340", "EXACT_LEGAL_NAME", NA,
  "H:MEMORIAL HOSPITAL OF TEXAS COUNTY AUTHORITY|371340",
  "§10.2 DIRECT: CMS OK Hospital Enrollments carry MEMORIAL HOSPITAL OF TEXAS COUNTY AUTHORITY, CRITICAL ACCESS HOSPITAL, CCN 371340, Guymon -- the awardee's exact legal name.",
  "rrr", "Mercy Health Oklahoma Communities, Inc.", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", NA, NA, NA, NA,
  "§10.2 DIRECT, typed a HEALTH SYSTEM on general knowledge: no CMS OK hospital enrolment carries this string -- Mercy's Oklahoma hospitals enrol under their own legal entities (MERCY HOSPITAL WATONGA INC, KINGFISHER, LOGAN COUNTY, HEALDTON, TISHOMINGO, ADA, ARDMORE). OSDH's own award text has the money modernise rooms 'across seven rural hospitals', which is what the award BUYS, not the recipient's form (§0.3a). No CCN, LOW (owner's instruction, session 86).",
  "rrr", "Newman Memorial Hospital, Inc.", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "371336", "EXACT_LEGAL_NAME", NA,
  "H:NEWMAN MEMORIAL HOSPITAL, INC|371336",
  "§10.2 DIRECT: CMS OK Hospital Enrollments carry NEWMAN MEMORIAL HOSPITAL, INC, CRITICAL ACCESS HOSPITAL, CCN 371336, Shattuck -- the awardee's exact legal name. The same hospital holds a Doulas award (ok_year1_doulas_awardees.csv).",
  "rrr", "South Central Medical and Resource Center, Inc.", "FQHC_OR_RHC", "ORG_WEBSITE", "MEDIUM", NA, NA, NA,
  "F:SOUTH CENTRAL MEDICAL AND RESOURCE CENTER INC|371850",
  "CMS OK FQHC Enrollments (federal_records/2026-10-02) carry SOUTH CENTRAL MEDICAL AND RESOURCE CENTER INC, the awardee's exact legal name, at eight FQHC sites (Lindsay, Maysville, Chickasha, Washington, Pauls Valley, Blanchard); no CMS OK hospital enrolment. Not a hospital.",
  "rrr", "Southwestern Oklahoma State University", "UNIVERSITY_OR_AHC", "STATE_SOURCE", "MEDIUM", NA, NA, NA, NA,
  "A state university; no CMS OK hospital enrolment under its name. The award will 'Add robotic-assisted surgery at a local hospital and equip a clinic' -- the hospital is UNNAMED and the source does not say the money reaches it, so §10.2 NON_HOSPITAL on the recipient, hospital_benefiting = Unclear. Queued: OK_RRR_SWOSU_LOCAL_HOSPITAL.",
  "rrr", "SSM Health Care of Oklahoma", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "370037", "EXACT_LEGAL_NAME", NA,
  "H:SSM HEALTH CARE OF OKLAHOMA, INC.|370037",
  "§10.2 DIRECT: CMS OK Hospital Enrollments carry SSM HEALTH CARE OF OKLAHOMA, INC. dba SSM HEALTH ST ANTHONY HOSPITAL - OKLAHOMA CITY, PART A PROVIDER - HOSPITAL, CCN 370037 (and 370094, Midwest City) -- the awardee's legal name less its corporate suffix. The enrolled hospitals are URBAN; the award is for 'pulmonary rehabilitation access at a local hospital ... across seven rural hospitals'. The rural cut is R/03ar's, never a re-coding.",
  "rrr", "Stillwater Medical Center Authority", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "370049", "EXACT_LEGAL_NAME", NA,
  "H:STILLWATER MEDICAL CENTER AUTHORITY|370049",
  "§10.2 DIRECT: CMS OK Hospital Enrollments carry STILLWATER MEDICAL CENTER AUTHORITY dba STILLWATER MEDICAL CENTER, PART A PROVIDER - HOSPITAL, CCN 370049 -- the awardee's exact legal name.",
  # ---- CDM ----------------------------------------------------------------
  "cdm", "Central Oklahoma Family Medical Center, Inc.", "FQHC_OR_RHC", "ORG_WEBSITE", "MEDIUM", NA, NA, NA,
  "F:CENTRAL OKLAHOMA FAMILY MEDICAL CENTER INC|371804",
  "CMS OK FQHC Enrollments (federal_records/2026-10-02) carry CENTRAL OKLAHOMA FAMILY MEDICAL CENTER INC, the awardee's exact legal name, at sixteen FQHC sites (Konawa, Ada, Seminole, Stratford); no CMS OK hospital enrolment. The NAME RULE calls it a hospital on 'Medical Center' -- the false positive session 85 flagged, overridden here on the federal record.",
  "cdm", "Cherokee County Health Services Council", "NONPROFIT_CBO", NA, "LOW", NA, NA, NA, NA, OKN_FB,
  "cdm", "Choctaw Nation of Oklahoma", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "370172", "EXACT_LEGAL_NAME", NA,
  "H:CHOCTAW NATION OF OKLAHOMA|370172",
  "§10.2 enrolled-operator row and its session-72 PRECEDENCE RULE. OSDH's entry states NO form for this recipient (its text is the project description only), so the CMS enrolment decides: CMS OK Hospital Enrollments carry CHOCTAW NATION OF OKLAHOMA as the ORGANIZATION NAME of PART A PROVIDER - HOSPITAL CCN 370172 -- the awardee's exact legal name. The legal entity is a sovereign tribal government that also enrols a hospital; that is the AltaPointe shape (state silent, enrolment decides), not Alaska's (state states 'Tribal Health Organization'). Queued: OK_CDM_CHOCTAW_TRIBAL_HOSPITAL_ENROLMENT.",
  "cdm", "Cimarron Memorial Hospital and Rural Health Clinic", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", "371307", "DBA_OF_LEGAL_ENTITY", NA,
  "H:CIMARRON MEMORIAL HOSPITAL AND NURSING HOME|371307",
  "§10.2 DIRECT on a HAND-READ BRIDGE: CMS OK Hospital Enrollments carry CIMARRON MEMORIAL HOSPITAL AND NURSING HOME dba CIMARRON MEMORIAL HOSPITAL, CRITICAL ACCESS HOSPITAL, CCN 371307, Boise City; the same legal entity enrols CIMARRON MEMORIAL RURAL HEALTH CLINIC (RHC, CCN 373459). The awardee string is the DBA plus its RHC, not the legal name, so LOW.",
  "cdm", "Comanche Nation", "TRIBAL_ORG", "STATE_SOURCE", "MEDIUM", NA, NA, NA, NA,
  "OSDH's text: 'The Comanche Nation will expand its long-standing, community-based chronic disease management services for rural tribal members'. A federally recognised tribe; no CMS OK hospital enrolment under its name (COMANCHE COUNTY HOSPITAL AUTHORITY is a different body).",
  "cdm", "Fairview Regional Medical Center", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", "371329", "DBA_OF_LEGAL_ENTITY", NA,
  "H:FAIRVIEW REGIONAL MEDICAL CENTER AUTHORITY|371329",
  "§10.2 DIRECT: CMS OK Hospital Enrollments carry FAIRVIEW REGIONAL MEDICAL CENTER AUTHORITY dba FAIRVIEW REGIONAL MEDICAL CENTER, CRITICAL ACCESS HOSPITAL, CCN 371329. The awardee string is the DBA, so LOW (owner's instruction, session 86). The same hospital holds an RRR award.",
  "cdm", "Genesis Medical PLLC, dba Southern Oklahoma Pain Management", "NONPROFIT_CBO", NA, "LOW", NA, NA, NA, NA, OKN_FB,
  "cdm", "Jackson County Memorial Hospital Authority", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "370022", "EXACT_LEGAL_NAME", NA,
  "H:JACKSON COUNTY MEMORIAL HOSPITAL AUTHORITY|370022",
  "§10.2 DIRECT: CMS OK Hospital Enrollments carry JACKSON COUNTY MEMORIAL HOSPITAL AUTHORITY, CCN 370022, Altus -- the awardee's exact legal name. The same hospital holds an RRR award.",
  "cdm", "Lighthouse Behavioral Wellness Centers, Inc.", "NONPROFIT_CBO", NA, "LOW", NA, NA, NA, NA, OKN_FB,
  "cdm", "Long Term Care Specialists", "NONPROFIT_CBO", NA, "LOW", NA, NA, NA, NA, OKN_FB,
  "cdm", "Mercy Health Oklahoma Communities, Inc.", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", NA, NA, NA, NA,
  "§10.2 DIRECT, typed a HEALTH SYSTEM on general knowledge: no CMS OK hospital enrolment carries this string (Mercy's Oklahoma hospitals enrol under their own legal entities). OSDH's text: 'MHOC will expand its virtual capabilities in rural primary care clinics' -- what the award buys, not the recipient's form (§0.3a). No CCN, LOW (owner's instruction, session 86).",
  "cdm", "Midwest Wellness and Wound Care, LLC", "NONPROFIT_CBO", NA, "LOW", NA, NA, NA, NA, OKN_FB,
  "cdm", "Urology Center of Southern Oklahoma", "NONPROFIT_CBO", NA, "LOW", NA, NA, NA, NA, OKN_FB,
  "cdm", "Wagoner Hospital Authority, an Oklahoma Public Trust, DBA Wagoner Community Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "370166", "EXACT_LEGAL_NAME", NA,
  "H:WAGONER HOSPITAL AUTHORITY|370166",
  "§10.2 DIRECT: CMS OK Hospital Enrollments carry WAGONER HOSPITAL AUTHORITY dba WAGONER COMMUNITY HOSPITAL, PART A PROVIDER - HOSPITAL, CCN 370166 -- the awardee's entity half (before the comma) is the exact legal name, and its DBA is the record's DBA.",
  "cdm", "Wyandotte Nation", "TRIBAL_ORG", "GENERAL_KNOWLEDGE", "LOW", NA, NA, NA, NA,
  "A federally recognised tribe (general knowledge; OSDH's entry does not state the form). No CMS OK hospital enrolment; the 'CHC/OK WYANDOTTE CLINIC' FQHC site belongs to COMMUNITY HEALTH CENTER OF SOUTHEAST KANSAS INC, a different body."
)

okn_fed <- function(path) {
  e <- jsonlite::fromJSON(here::here(path))
  tibble::tibble(org = e[["ORGANIZATION NAME"]], ccn = as.character(e$CCN))
}

#' Every enrolment a typing row cites is on the archived federal file, and no
#' fallback or non-hospital row's exact name is on the hospital file.
okn_assert_rrr_cdm_federal <- function() {
  h <- okn_fed(OKN_HOSP_FED); f <- okn_fed(OKN_FQHC_FED)
  t <- OKN_RRR_CDM_TYPING[!is.na(OKN_RRR_CDM_TYPING$enrol), ]
  for (i in seq_len(nrow(t))) {
    kind <- substr(t$enrol[i], 1, 1)
    parts <- strsplit(substring(t$enrol[i], 3), "|", fixed = TRUE)[[1]]
    src <- if (kind == "H") h else f
    if (!any(src$org == parts[1] & src$ccn == parts[2])) {
      stop("[OK RRR/CDM] the archived ", if (kind == "H") "hospital" else "FQHC",
           " file no longer carries ", parts[1], " (", parts[2], ").", call. = FALSE)
    }
  }
  hosp_types <- OKN_RRR_CDM_TYPING$recipient_type == "HOSPITAL_OR_SYSTEM"
  if (any(hosp_types & is.na(OKN_RRR_CDM_TYPING$ccn) &
          OKN_RRR_CDM_TYPING$confidence != "LOW")) {
    stop("[OK RRR/CDM] a hospital row with no CCN must be LOW.", call. = FALSE)
  }
  nonh <- toupper(gsub("[.,]", "", OKN_RRR_CDM_TYPING$awardee[!hosp_types]))
  orgs <- toupper(gsub("[.,]", "", h$org))
  if (any(nonh %in% orgs)) {
    stop("[OK RRR/CDM] a non-hospital row's exact name is on the CMS OK hospital ",
         "file: ", paste(nonh[nonh %in% orgs], collapse = "; "), call. = FALSE)
  }
  invisible(TRUE)
}

okn_roster_rows <- function(key, p = okn_parse(key, n_detail = 1L)) {
  r <- OKN_ROSTERS[OKN_ROSTERS$key == key, ]
  ty <- OKN_RRR_CDM_TYPING[OKN_RRR_CDM_TYPING$key == key, ]
  ty <- ty[match(p$awardee, ty$awardee), ]
  if (any(is.na(ty$awardee))) {
    stop("[OK ", key, "] no hand-read typing for: ",
         paste(p$awardee[is.na(ty$awardee)], collapse = "; "), call. = FALSE)
  }
  cls <- rhtp_classify_recipient_type(p$awardee, OKN_STATE)
  hosp <- ty$recipient_type == "HOSPITAL_OR_SYSTEM"
  flow <- dplyr::coalesce(ty$flow, ifelse(hosp, "DIRECT", "NON_HOSPITAL"))
  fallback <- ty$recipient_type == "NONPROFIT_CBO" & ty$confidence == "LOW" & is.na(ty$basis_type)
  enrol_record <- ifelse(
    is.na(ty$enrol), NA_character_,
    paste0(ifelse(substr(ty$enrol, 1, 1) == "H", "CMS Hospital Enrollments: ",
                  "CMS FQHC Enrollments: "),
           sub("\\|", ", CCN ", substring(ty$enrol, 3)), " (",
           ifelse(substr(ty$enrol, 1, 1) == "H", OKN_HOSP_FED, OKN_FQHC_FED), ")"))
  tibble::tibble(
    state = OKN_STATE,
    row_no = seq_len(nrow(p)),
    awardee = p$awardee,
    amount = p$amount,
    recipient_type = ty$recipient_type,
    distributed_to_hospital = ifelse(hosp, "Yes", "No"),
    note = paste0(r$round_name, ", List of Funding Recipients (OSDH, read ", OKN_READ,
                  "). ", p$detail),
    recipient_confirmed = "Yes",
    amount_confirmed = "Yes",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = paste0("Oklahoma RHTP Funding Recipients -- ", r$round_name,
                                   ", List of Funding Recipients"),
    state_source_url = OKN_URL,
    validation_source_type = "NOTICE_OF_AWARD",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03bt_ok_new_rosters.R",
    ccn = ifelse(hosp, ty$ccn, NA_character_),
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    recipient_type_source = paste0(
      ifelse(fallback, "FALLBACK (session 86): ", "TYPED (session 86, HAND-READ): "),
      ty$why, " Classifier said ", cls$recipient_type, "/",
      cls$determination_confidence, "."),
    determination_confidence = ty$confidence,
    flag_reason = ifelse(fallback, "RECIPIENT_TYPE_INFERRED", NA_character_),
    award_pool = r$round_name,
    budget_period = "Budget Period 1",
    flow_type = flow,
    hospital_benefiting = dplyr::case_when(hosp ~ "Yes",
                                           flow == "IN_KIND_BENEFIT" ~ "Yes",
                                           TRUE ~ "Unclear"),
    hospital_attribution = ifelse(hosp, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = paste0("§10.2 ", flow, ": ", ty$why),
    amount_basis = "EXACT, as published per recipient by OSDH.",
    round_name = r$round_name,
    round_awards = nrow(p),
    round_amount = NA_real_,
    announcement_date = OKN_READ,
    source_archive_path = OKN_ARCHIVE,
    basis_type = ty$basis_type,
    recipient_subtype = NA_character_,
    cms_enrolment_match = ifelse(hosp, ty$enrol_match, NA_character_),
    cms_enrolment_record = enrol_record)
}

# The hospital figures each roster is pinned to (session 86).
OKN_HOSP_PIN <- tibble::tribble(
  ~key,  ~rows, ~usd,        ~low_rows, ~low_usd,
  "rrr", 10L,   21099804,    4L,        8272013,
  "cdm", 6L,    9197657.15,  3L,        5108475.41)

okn_assert_roster_rows <- function(key, a) {
  r <- OKN_ROSTERS[OKN_ROSTERS$key == key, ]
  if (nrow(a) != r$n || abs(sum(a$amount) - r$total) > 0.005) {
    stop("[OK ", key, "] ", r$n, " rows / $", r$total, " expected.", call. = FALSE)
  }
  h <- a[a$distributed_to_hospital == "Yes", ]
  pin <- OKN_HOSP_PIN[OKN_HOSP_PIN$key == key, ]
  lo <- h$determination_confidence == "LOW"
  if (nrow(h) != pin$rows || abs(sum(h$amount) - pin$usd) > 0.005 ||
      sum(lo) != pin$low_rows || abs(sum(h$amount[lo]) - pin$low_usd) > 0.005) {
    stop("[OK ", key, "] hospital rows moved: ", nrow(h), " / $", sum(h$amount),
         " (LOW ", sum(lo), " / $", sum(h$amount[lo]), ").", call. = FALSE)
  }
  if (any(h$recipient_type != "HOSPITAL_OR_SYSTEM")) {
    stop("[OK ", key, "] a hospital row is not HOSPITAL_OR_SYSTEM.", call. = FALSE)
  }
  # §7: HIGH needs a Stage 5 CCN match; nothing here reaches it.
  if (any(a$determination_confidence == "HIGH")) {
    stop("[OK ", key, "] HIGH is reserved for Stage 5.", call. = FALSE)
  }
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "determination_confidence", "hospital_attribution", "basis_type",
                "flag_reason", "cms_enrolment_match", "hospital_benefiting")) {
    bad <- setdiff(stats::na.omit(unique(a[[col]])), rhtp_vocabulary(col))
    if (length(bad)) stop("[OK ", key, "] ", col, " outside §8: ",
                          paste(bad, collapse = ", "), call. = FALSE)
  }
  invisible(TRUE)
}

okn_validate <- function() {
  x <- okn_lines()
  okn_assert_source(x)
  okn_assert_federal()
  a <- okn_doulas(okn_parse("doulas", x))
  okn_assert_rows(a)
  okn_assert_rrr_cdm_federal()
  for (k in c("rrr", "cdm")) okn_assert_roster_rows(k, okn_roster_rows(k, okn_parse(k, x, 1L)))
  message("[OK new rosters] all assertions pass (Doulas, RRR, CDM).")
  invisible(a)
}

#' R/03bj's enrolled-hospital overlay (session 86): every row typed on its CMS
#' enrolment carries a verdict in EH_APPLY and the session-71 tag on its basis.
okn_s71 <- function(a, file) {
  s71 <- new.env()
  suppressMessages(source(here::here("R", "03bj_enrolled_hospital_operator.R"),
                          local = s71))
  s71$s71_overlay(okn_chr(a), file)
}

#' Every column as character, numbers written in full: as.character(500000)
#' is "5e+05", the round-trip defect CLAUDE.md warns of.
okn_chr <- function(a) {
  num <- function(x) ifelse(is.na(x), NA_character_,
                            vapply(x, function(v) format(v, scientific = FALSE, digits = 15),
                                   character(1)))
  dplyr::mutate(a, dplyr::across(dplyr::where(is.numeric), num),
                dplyr::across(dplyr::everything(), as.character))
}

okn_build <- function() {
  a <- okn_validate()
  readr::write_csv(okn_s71(a, basename(OKN_CSV)), OKN_CSV, na = "")
  for (k in c("rrr", "cdm")) {
    f <- if (k == "rrr") OKN_RRR_CSV else OKN_CDM_CSV
    b <- okn_roster_rows(k)
    readr::write_csv(okn_s71(b, basename(f)), f, na = "")
    message("[OK ", toupper(k), "] wrote ", nrow(b), " rows, $",
            format(sum(b$amount), big.mark = ",", nsmall = 2), "; ",
            sum(b$distributed_to_hospital == "Yes"), " named-hospital rows, $",
            format(sum(b$amount[b$distributed_to_hospital == "Yes"]), big.mark = ",", nsmall = 2), ".")
  }
  message("[OK Doulas] wrote ", nrow(a), " rows, $",
          format(sum(a$amount), big.mark = ",", nsmall = 2), "; 1 named-hospital row, $",
          format(sum(a$amount[a$distributed_to_hospital == "Yes"]), big.mark = ","), ".")
  invisible(a)
}

okn_report <- function() {
  x <- okn_lines()
  for (k in OKN_ROSTERS$key) {
    p <- okn_parse(k, x)
    cls <- rhtp_classify_recipient_type(p$awardee, OKN_STATE)
    cat(sprintf("\n== %s: %d rows, $%s%s\n", k, nrow(p),
                format(sum(p$amount), big.mark = ",", nsmall = 2),
                if (OKN_ROSTERS$written[OKN_ROSTERS$key == k]) "" else "  [NOT WRITTEN]"))
    print(as.data.frame(tibble::tibble(awardee = p$awardee, amount = p$amount,
                                       name_rule = cls$recipient_type)), row.names = FALSE)
  }
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) okn_validate()
  if ("--build" %in% args) okn_build()
  if ("--report" %in% args) okn_report()
  if (!length(args)) message("Usage: --validate | --build | --report")
}
