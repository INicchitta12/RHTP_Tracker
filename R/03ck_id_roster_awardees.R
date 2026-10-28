#!/usr/bin/env Rscript
# 03ck_id_roster_awardees.R -----------------------------------------------------
#
# IDAHO -- DHW'S FIRST ROSTER: "Idaho-RHTP_List of Awardees dated 10192026.xlsx",
# 114 PRICED LINES, $180,701,813.99, TYPED ON CMS'S IDAHO ENROLMENT FILES.
# Session 108. R/03am sources this file and writes id_year1_awardees.csv from it.
#
# WHAT THE ROWS ARE (owner instruction: "record whether the rows are awards,
# intents or allocations before extracting"). AWARDS. DHW's funding page heads
# the section "Closed and awarded funding opportunities" and links the file as
# "See the list of awardees as of Oct. 16"; the page says the Year 1
# opportunities "are in the award and procurement process" and that it will be
# updated "as awardees and start dates are determined". The workbook's own
# columns are Type | Solicitation Name | Sub Recipient / Contractor / MOA_MOU
# Holder | Amount: a NAMED recipient and a figure on every line. They are not
# allocations to an eligible class (no line names a class), and the word
# "intent" appears nowhere. NO PRINTED TOTAL: the workbook has no total row and
# the page prints no figure for it, so $180,701,813.99 is THIS FILE'S SUM (to
# the cent; session 107's "$180,701,814" rounded it), and the assertion is the
# 114 lines and the three type subtotals as read.
#   Subrecipient 100 lines  $125,412,900.01
#   Contractor    12 lines   $32,388,913.98
#   MOA/ MOU       2 lines   $22,900,000.00
# Execution is not stated, so validation_source_type = NOTICE_OF_AWARD (an
# agency award list: South Carolina's precedent) with amount_confirmed = Yes on
# DHW's figure. Against Idaho's $185,974,368 allotment the lines are 97.2%.
#
# THE TWO MOA/MOU LINES ARE NOT SUBAWARDS AND ARE KEPT OUT OF THE AWARD FILE.
# "The Office of the State Board of Education (OSBE)", $8,000,000 (GME
# Expansion), and "Idaho Military Division (IMD)", $14,900,000 (NG-911), are
# memoranda between DHW and two other state bodies: Vermont's GMCB MOU on the
# same footing (owner decision, session 54; R/03at). They are recorded in
# id_year1_status.csv. The award file is 112 lines, $157,801,813.99.
#
# TYPING (owner instruction: "type on CMS enrolment"), in order:
#   1. ID_HAND below, each with its sentence.
#   2. EXACT: the string equals an ORGANIZATION NAME or DBA on CMS's ID Hospital
#      (2026-09-25), FQHC or RHC (2026-10-26) Enrollment after case,
#      punctuation, apostrophes, "&"/"and" and a trailing INC/LLC are set aside.
#      MEDIUM. AN RHC OR FQHC RECORD WHOSE LEGAL ENTITY IS ALSO CMS-ENROLLED AS
#      A HOSPITAL types the recipient a hospital (§10.2's enrolled-operator row):
#      "Syringa Hospital and Clinics" is the RHC DBA of SYRINGA GENERAL HOSPITAL
#      DISTRICT C I F, a CAH (131315).
#   3. The classifier on the name, or §8's standing fallback.
#
# HAND READS THAT MOVE OR KEEP HOSPITAL DOLLARS:
#   * St. Luke's Health System (three lines, two spellings) is a SYSTEM PARENT
#     (owner rulings: Vandalia, Sanford/Avera, Guthrie, Ballad/Sentara/Valley):
#     LOW, GENERAL_KNOWLEDGE, no CCN, subtractable.
#   * Hand-read bridges, LOW: "St. Luke's Magic Valley" (a truncation of ST
#     LUKES MAGIC VALLEY REGIONAL MEDICAL CENTER LTD, which holds 130002 and CAH
#     131310, so no CCN); "Bear Lake Memorial Healthcare" (BEAR LAKE COUNTY
#     MEMORIAL HOSPITAL, CAH 131316); "St. Mary's Hospital Health" (ST MARYS
#     HOSPITAL INC dba ST. MARY'S HEALTH, CAH 131321: the two names welded);
#     "Clearwater Valley Hospitals and Clinics" (plural; CAH 131320).
#   * "Lifeways" is the exact legal name of LIFEWAYS INC, CMS-enrolled as
#     LIFEWAYS HOSPITAL (134009, Boise, psychiatric): a hospital on its
#     enrolment (§10.2), MEDIUM. CONFIRMED by owner ruling (a), session 109.
#   * The Hospital Cooperative and Hospital Network of Idaho are networks of
#     hospitals, and the list says nothing of where their money goes: WSHA's
#     shape (§10.2's association row needs the source to SHOW funds reaching
#     member hospitals) -- PASS_THROUGH_UNRESOLVED, Unclear, no bucket,
#     FLOW_UNRESOLVED_HOSPITAL_AFFILIATED. Four lines, $3,833,321.00.
#   * Public Consulting Group, "Third Party Administrator for Ladder Payment
#     Program" ($14,520,000): a contractor administering payments whose
#     recipients the list does not name; Idaho's plan describes "ladder payments
#     for recruitment, retention" (CMS abstract). Hospitals may be among the
#     payees and nothing says so (§0.3): PASS_THROUGH_UNRESOLVED, Unclear.
#
# §6.2: the list post-dates Idaho's 2025-12-29 NOA, and DHW's page carries the
# programme's own scope (its CMS footer is the ALLOTMENT, Tier 1, R/03am).
#
# Usage: sourced by R/03am_id_year1_awardees.R (--validate / --build).

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

IDR_STATE  <- "ID"
IDR_FILE   <- file.path("data", "evidence", "recheck", "2026-10-26", "ID",
                        "id_rhtp_list_of_awardees_dated_2026-10-19.xlsx")
IDR_URL    <- "https://publicdocuments.dhw.idaho.gov/WebLink/ElectronicFile.aspx?docid=37915"
IDR_TITLE  <- paste0("Idaho DHW, 'Idaho-RHTP_List of Awardees dated 10192026.xlsx' ",
                     "('See the list of awardees as of Oct. 16')")
IDR_AS_OF  <- as.Date("2026-10-16")
IDR_LINES  <- 114L
IDR_TOTAL  <- 180701813.99
IDR_BY_TYPE <- c(Subrecipient = 125412900.01, Contractor = 32388913.98, `MOA/ MOU` = 22900000.00)
IDR_FED <- c(
  HOSPITAL = file.path("data", "evidence", "federal_records", "2026-09-25", "cms_hosp_enrollments_ID.json"),
  FQHC     = file.path("data", "evidence", "federal_records", "2026-10-26", "cms_fqhc_enrollments_ID.json"),
  RHC      = file.path("data", "evidence", "federal_records", "2026-10-26", "cms_rhc_enrollments_ID.json"))

idr_read <- function(path = here::here(IDR_FILE)) {
  d <- suppressMessages(readxl::read_excel(path, col_names = FALSE, col_types = "text"))
  hdr <- unname(unlist(d[1, ]))
  if (!identical(hdr, c("Type", "Solicitation Name", "Sub Recipient / Contractor / MOA_MOU Holder", "Amount"))) {
    stop("[ID roster] the workbook's header moved: re-read it (§0.4).", call. = FALSE)
  }
  b <- d[-1, ]
  tibble::tibble(
    line = seq_len(nrow(b)),
    type = stringr::str_squish(b[[1]]),
    solicitation = stringr::str_squish(b[[2]]),
    awardee = stringr::str_squish(b[[3]]),
    amount = round(as.numeric(b[[4]]), 2))
}

idr_assert_roster <- function(d = idr_read()) {
  if (nrow(d) != IDR_LINES) stop("[ID roster] ", nrow(d), " lines, not 114.", call. = FALSE)
  if (anyNA(d$amount) || any(!nzchar(d$awardee))) stop("[ID roster] a line has no amount or name.", call. = FALSE)
  if (abs(sum(d$amount) - IDR_TOTAL) > 0.005) {
    stop("[ID roster] the lines sum to $", format(sum(d$amount), nsmall = 2, big.mark = ","),
         ", not $180,701,813.99.", call. = FALSE)
  }
  by <- tapply(d$amount, d$type, sum)
  if (!setequal(names(by), names(IDR_BY_TYPE)) ||
      any(abs(by[names(IDR_BY_TYPE)] - IDR_BY_TYPE) > 0.005)) {
    stop("[ID roster] the type subtotals moved.", call. = FALSE)
  }
  if (sum(d$type == "MOA/ MOU") != 2L) stop("[ID roster] the MOA/MOU lines are not the two recorded.", call. = FALSE)
  invisible(TRUE)
}

# -- typing ---------------------------------------------------------------------

idr_norm <- function(x) {
  x <- toupper(x)
  x <- gsub("['\u2019]", "", x)
  x <- gsub("&", " AND ", x, fixed = TRUE)
  x <- gsub("[.,/()\u2013-]", " ", x)
  x <- stringr::str_squish(gsub("[^A-Z0-9 ]", "", x))
  x <- sub("^THE ", "", x)
  sub(" (INC|INCORPORATED|LLC|PLLC|PC|PA|LP|LTD)$", "", x)
}

idr_federal <- function() {
  dplyr::bind_rows(lapply(names(IDR_FED), function(k) {
    j <- jsonlite::fromJSON(here::here(IDR_FED[[k]]))
    tibble::tibble(kind = k, ccn = as.character(j$CCN), org = j$`ORGANIZATION NAME`,
                   dba = j$`DOING BUSINESS AS NAME`, city = j$CITY,
                   ptype = if ("PROVIDER TYPE TEXT" %in% names(j)) j$`PROVIDER TYPE TEXT` else NA_character_)
  }))
}

IDR_PARENT <- paste0(
  "SYSTEM PARENT, LOW, GENERAL_KNOWLEDGE (owner rulings: Vandalia, Sanford/Avera, Guthrie, ",
  "Ballad/Sentara/Valley): St. Luke's Health System is the parent of ST LUKES REGIONAL MEDICAL ",
  "CENTER (130006, and CAH 131311 Elmore), ST LUKES MAGIC VALLEY REGIONAL MEDICAL CENTER LTD (130002; ",
  "CAH 131310 Jerome), ST LUKES NAMPA MEDICAL CENTER LTD (130071), ST LUKES WOOD RIVER MEDICAL CENTER ",
  "LTD (CAH 131323) and ST LUKES MCCALL, LTD (CAH 131312). It is not itself enrolled, so no CCN. ",
  "Subtractable by basis_type.")
IDR_ASSOC <- paste0(
  "A NETWORK OF HOSPITALS, AND THE LIST SAYS NOTHING OF WHERE ITS MONEY GOES. §10.2's association ",
  "row requires the source to SHOW funds administered to or on behalf of member hospitals; the list ",
  "prints a name, a solicitation (Healthcare Infrastructure Support) and a figure. WSHA's shape ",
  "(R/03bd): PASS_THROUGH_UNRESOLVED, Unclear, no bucket. OWNER RULING (b), session 109: 'quote the ",
  "source sentence; if it says the money goes to member hospitals, POOL_UNNAMED_HOSPITALS (ICAHN rule); ",
  "otherwise Unclear'. THE ONLY SOURCE SENTENCE IS THE LIST LINE ITSELF -- Type 'Subrecipient', ",
  "Solicitation Name 'Healthcare Infrastructure Support', the network's name and an Amount -- and it ",
  "says nothing of member hospitals. The HIS FAQ (archived recheck/2026-10-28/ID/) says only that 'An ",
  "applicant must fall within an eligible applicant type' under 'Sections 2.1-2.3 of the posted ",
  "solicitation', and contemplates non-hospital applicants ('Could a generator at a retail WIC site be ",
  "eligible under HIS?'): not ICAHN's hospitals-only class. STAYS Unclear.")
IDR_EMS <- "An EMS provider (the form is in the string). Not a hospital."
IDR_UNI <- "A public university or college programme (the institution is named in the string). Not a hospital."
IDR_VENDOR <- paste0("A commercial firm by its name (the list's Type column is 'Contractor' on every such line ",
                     "but 22nd Century Tech's Crisis Intervention Training subgrant). Not a hospital.")

ID_HAND <- tibble::tribble(
  ~pattern, ~recipient_type, ~basis_type, ~confidence, ~ccn, ~flow, ~why,
  "^St\\. Luke.s Health System$", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", NA, "DIRECT", IDR_PARENT,
  "^St\\. Luke's Magic Valley$", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", NA, "DIRECT",
  "HAND-READ BRIDGE: CMS ID Hospital Enrollment carries ST LUKES MAGIC VALLEY REGIONAL MEDICAL CENTER LTD (130002, Twin Falls; it also holds CAH 131310, Jerome), which the string truncates. Two hospital CCNs, so none is put on the row. LOW.",
  "^Bear Lake Memorial Healthcare$", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "131316", "DIRECT",
  "HAND-READ BRIDGE: CMS ID Hospital Enrollment carries BEAR LAKE COUNTY MEMORIAL HOSPITAL (CAH 131316, Montpelier); the string is its trading name, not the enrolled one. LOW.",
  "^St\\. Mary's Hospital Health$", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "131321", "DIRECT",
  "HAND-READ BRIDGE: CMS ID Hospital Enrollment carries ST MARYS HOSPITAL INC dba ST. MARY'S HEALTH (CAH 131321, Cottonwood); the string welds the legal name and the DBA. LOW.",
  "^Clearwater Valley Hospitals and Clinics$", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "131320", "DIRECT",
  "HAND-READ BRIDGE: CMS ID Hospital Enrollment carries CLEARWATER VALLEY HOSPITAL & CLINICS (CAH 131320, Orofino); the string pluralises 'Hospital'. LOW.",
  "^(The Hospital Cooperative|Hospital Network of Idaho)$", "NONPROFIT_CBO", "GENERAL_KNOWLEDGE", "LOW", NA, "PASS_THROUGH_UNRESOLVED", IDR_ASSOC,
  "^Public Consulting Group LLC$", "VENDOR_OR_CONTRACTOR", "STATE_SOURCE", "MEDIUM", NA, "PASS_THROUGH_UNRESOLVED",
  paste0("THIRD PARTY ADMINISTRATOR for the Ladder Payment Program (the list's Solicitation Name; Type ",
         "'Contractor'). The $14,520,000 includes payments whose recipients the list does not name; Idaho's ",
         "plan describes 'ladder payments for recruitment, retention' (CMS project abstract). Hospitals may be ",
         "among the payees and nothing says so (§0.3): PASS_THROUGH_UNRESOLVED, Unclear, no bucket. ",
         "OWNER RULING (b), session 109: PCG stays Unclear unless the ladder payments are stated to go only to ",
         "hospitals. DHW's own description is 'Ladder payments based on priority positions and rural presence' ",
         "(RHTP about page, Initiative 3, 'Sustaining rural workforce'), which ties payments to POSITIONS, not to ",
         "hospitals; the TPA RFP sits on Idaho's Infor supplier portal, which serves an empty JavaScript shell ",
         "(UNREADABLE, recorded UNKNOWN, never NO). Nothing states hospitals-only. STAYS Unclear."),
  "^Lifeways$", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "134009", "DIRECT",
  paste0("OWNER RULING (a), session 109 (Brattleboro Retreat precedent: a psychiatric hospital on its CMS ",
         "enrolment is a hospital): 'Lifeways' is the exact legal name of LIFEWAYS INC, which CMS ID Hospital ",
         "Enrollment (2026-09-25) carries dba LIFEWAYS HOSPITAL (134009, Boise), PROVIDER TYPE 'PART A PROVIDER - ",
         "HOSPITAL', LOCATION OTHER TYPE TEXT 'FREE STANDING PSYCHIATRIC HOSPITAL', SUBGROUP - PSYCHIATRIC 'Y'. The ",
         "ruling's condition holds, so HOSPITAL_OR_SYSTEM stands (§10.2's enrolled-operator row). MEDIUM."),
  "^CHAS Health$", "FQHC_OR_RHC", "ORG_WEBSITE", "LOW", NA, "NON_HOSPITAL",
  "HAND-READ BRIDGE: CMS ID FQHC Enrollment carries COMMUNITY HEALTH ASSOCIATION OF SPOKANE (dba CHAS LATAH COMMUNITY HEALTH and others); 'CHAS Health' is its trading name. An FQHC. LOW.",
  "(Ambulance|Paramedics|Fire Department|Fire District)", "EMS_OR_PSAP", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL", IDR_EMS,
  "^(BSU|ISU|LCSC) [-\u2013] |^University of Idaho|^ISU \u2013 ", "UNIVERSITY_OR_AHC", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL", IDR_UNI,
  "District Health$", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL",
  "An Idaho public health district (the form is in the string). Not a hospital.",
  "(Tribes?( Inc)?$|^Kootenai Tribe|^Coeur D'Alene Tribe|^Nez Perce Tribe)", "TRIBAL_ORG", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL",
  "A federally recognised tribe (the form is in the string; the solicitation is 'Tribal Rural Health Transformation Support'). Not a hospital.",
  "^Idaho Educational Services for the Deaf & Blind$", "SCHOOL_OR_DISTRICT", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL",
  "The state's school for deaf and blind students (the form is in the string). Not a hospital.",
  "^Inclusive Care Clinic Pharmacy$", "OTHER", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL",
  "DETERMINED FORM: a pharmacy (the form is in the string). Not a hospital.",
  "^(Guidehouse, Inc\\.|BDO Government Services, LLC|SHI International|Deloitte Consulting LLP|22nd Century Tech)", "VENDOR_OR_CONTRACTOR", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL", IDR_VENDOR,
  "^Alzheimer.s Association$", "NONPROFIT_CBO", "GENERAL_KNOWLEDGE", "LOW", NA, "NON_HOSPITAL",
  "A national nonprofit (general knowledge), contracted for the Cognitive Health Workforce Response Network. Not a hospital.",
  "^(Comagine Health|Co Magine Health)$", "NONPROFIT_CBO", NA, "LOW", NA, "NON_HOSPITAL",
  "§8's standing fallback, as R/03am read the same body in session 41: the list states no form. 'Co Magine Health' is printed with a space on the Contractor line; NOT merged (§2). Not a hospital.")

idr_type <- function(d = idr_read(), f = idr_federal()) {
  cls <- rhtp_classify_recipient_type(d$awardee, IDR_STATE)
  hosp_orgs <- unique(f$org[f$kind == "HOSPITAL"])
  out <- lapply(seq_len(nrow(d)), function(i) {
    a <- d$awardee[i]
    hd <- ID_HAND[vapply(ID_HAND$pattern, grepl, logical(1), x = a), ][1, ]
    if (!is.na(hd$pattern)) {
      return(tibble::tibble(recipient_type = hd$recipient_type, basis_type = hd$basis_type,
                            determination_confidence = hd$confidence, typing = "HAND-READ",
                            why = hd$why, ccn = hd$ccn, flow = hd$flow))
    }
    hit <- f[idr_norm(f$org) %in% idr_norm(a) | idr_norm(dplyr::coalesce(f$dba, "")) %in% idr_norm(a), ]
    if (nrow(hit)) {
      ent <- unique(hit$org)
      is_hosp <- any(hit$kind == "HOSPITAL") || any(ent %in% hosp_orgs)
      k <- if (is_hosp) "HOSPITAL" else if ("FQHC" %in% hit$kind) "FQHC" else "RHC"
      recs <- if (is_hosp) f[f$kind == "HOSPITAL" & f$org %in% ent, ] else hit[hit$kind == k, ]
      six <- sort(unique(recs$ccn[grepl("^[0-9]{6}$", recs$ccn)]))
      via <- if (is_hosp && !any(hit$kind == "HOSPITAL"))
        paste0(" The string is the ", paste(unique(hit$kind), collapse = "/"), " DBA of ",
               paste(ent, collapse = "; "), ", WHICH CMS ALSO ENROLS AS A HOSPITAL: a hospital on ",
               "its enrolment (§10.2's enrolled-operator row).") else ""
      rec <- paste0(paste(ent, collapse = "; "),
                    if (any(nzchar(dplyr::coalesce(recs$dba, ""))))
                      paste0(" dba ", paste(unique(recs$dba[nzchar(dplyr::coalesce(recs$dba, ""))]), collapse = " / ")) else "",
                    " (", paste(six, collapse = "/"), ")")
      return(tibble::tibble(
        recipient_type = if (is_hosp) "HOSPITAL_OR_SYSTEM" else "FQHC_OR_RHC",
        basis_type = "ORG_WEBSITE", determination_confidence = "MEDIUM", typing = "EXACT",
        why = paste0("EXACT federal record: CMS ID ", paste(unique(hit$kind), collapse = "/"),
                     " Enrollment carries this string as an ORGANIZATION NAME or DBA: ", rec,
                     if (is_hosp) paste0(", ", unique(recs$ptype)[1]) else "", ".", via),
        ccn = if (is_hosp && length(six) == 1L) six else NA_character_,
        flow = if (is_hosp) "DIRECT" else "NON_HOSPITAL"))
    }
    if (cls$recipient_type[i] == "HOSPITAL_OR_SYSTEM") {
      stop("[ID roster] the classifier calls '", a, "' a hospital and no federal record or ",
           "hand-read decision covers it. Read it.", call. = FALSE)
    }
    fb <- cls$rule[i] == "FALLBACK"
    tibble::tibble(
      recipient_type = cls$recipient_type[i],
      basis_type = if (fb) NA_character_ else "STATE_SOURCE",
      determination_confidence = if (fb) "LOW" else rhtp_confidence_ceiling(cls$determination_confidence[i]),
      typing = if (fb) "FALLBACK" else "CLASSIFIER",
      why = if (fb) "The list states no form and no CMS ID Hospital, FQHC or RHC enrolment carries the string (§8's standing fallback, RECIPIENT_TYPE_INFERRED)."
            else paste0("No CMS ID enrolment carries the string; the form is read from the string itself (",
                        cls$recipient_type_basis[i], ")."),
      ccn = NA_character_, flow = "NON_HOSPITAL")
  })
  t <- dplyr::bind_rows(out)
  t$classifier <- paste0(cls$recipient_type, "/", rhtp_confidence_ceiling(cls$determination_confidence))
  t
}

#' The award file: every line but the two inter-agency MOA/MOU lines.
id_roster_awardees <- function(d = idr_read(), f = idr_federal()) {
  d <- d[d$type != "MOA/ MOU", ]
  t <- idr_type(d, f)
  hosp <- t$recipient_type == "HOSPITAL_OR_SYSTEM" & t$flow == "DIRECT"
  unres <- t$flow == "PASS_THROUGH_UNRESOLVED"
  dist <- ifelse(hosp, "Yes", ifelse(unres, "Unclear", "No"))
  flag <- dplyr::case_when(
    t$typing == "FALLBACK" ~ "RECIPIENT_TYPE_INFERRED",
    unres & t$recipient_type == "NONPROFIT_CBO" ~ "FLOW_UNRESOLVED_HOSPITAL_AFFILIATED",
    TRUE ~ NA_character_)
  tibble::tibble(
    state = IDR_STATE,
    row_no = seq_len(nrow(d)),
    awardee = d$awardee,
    amount = d$amount,
    recipient_type = t$recipient_type,
    distributed_to_hospital = dist,
    note = paste0(d$type, " line ", d$line, " on DHW's list of awardees as of Oct. 16 (dated 10-19-2026): ",
                  d$solicitation, "."),
    recipient_confirmed = "Yes",
    amount_confirmed = "Yes",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = IDR_TITLE,
    state_source_url = IDR_URL,
    validation_source_type = "NOTICE_OF_AWARD",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03ck_id_roster_awardees.R",
    ccn = t$ccn,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    roster_line = d$line,
    roster_type = d$type,
    recipient_type_source = paste0("TYPED (session 108, ", t$typing, "): ", t$why,
                                   " Classifier said ", t$classifier, "."),
    determination_confidence = rhtp_confidence_ceiling(t$determination_confidence, t$ccn),
    flag_reason = flag,
    award_pool = d$solicitation,
    budget_period = "Budget Period 1",
    flow_type = t$flow,
    hospital_benefiting = ifelse(hosp, "Yes", "Unclear"),
    hospital_attribution = ifelse(hosp, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = ifelse(unres, d$awardee, NA_character_),
    determination_basis = paste0("§10.2 ", t$flow, ": ", t$why,
                                 ifelse(hosp, " §0.3a: the recipient is a hospital or health system whatever the activity.", ""),
                                 " AN AWARD, NOT AN INTENT OR AN ALLOCATION: DHW lists it under 'Closed and awarded ",
                                 "funding opportunities' as an awardee; execution is not stated."),
    amount_basis = paste0("The line's own Amount on DHW's list, exact. The list prints no total; its 114 ",
                          "lines sum to $180,701,813.99, of which the two MOA/MOU lines ($22,900,000) are ",
                          "inter-agency and are not in this file."),
    basis_type = t$basis_type,
    round_amount = NA_real_,
    announcement_date = IDR_AS_OF,
    source_archive_path = IDR_FILE)
}

#' The two inter-agency memoranda, for the status table (never award rows).
id_roster_moas <- function(d = idr_read()) d[d$type == "MOA/ MOU", ]

idr_assert_typing <- function(a = id_roster_awardees()) {
  h <- a[a$distributed_to_hospital == "Yes", ]
  if (any(h$recipient_type != "HOSPITAL_OR_SYSTEM") || any(h$flow_type != "DIRECT")) {
    stop("[ID roster] a Yes row is not a DIRECT hospital row.", call. = FALSE)
  }
  if (any(grepl("MOA", a$note, fixed = TRUE) & grepl("^MOA", a$note))) {
    stop("[ID roster] an MOA/MOU line reached the award file.", call. = FALSE)
  }
  un <- a[a$distributed_to_hospital == "Unclear", ]
  if (!setequal(unique(un$awardee), c("The Hospital Cooperative", "Hospital Network of Idaho", "Public Consulting Group LLC"))) {
    stop("[ID roster] the Unclear lines are not the two hospital networks and the ladder-payment TPA.", call. = FALSE)
  }
  unused <- ID_HAND$pattern[!vapply(ID_HAND$pattern, function(p) any(grepl(p, a$awardee)), logical(1))]
  if (length(unused)) stop("[ID roster] hand reads match no line: ", paste(unused, collapse = "; "), call. = FALSE)
  rhtp_assert_high_has_ccn(a, "ID roster")
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "determination_confidence", "hospital_attribution", "basis_type")) {
    bad <- setdiff(stats::na.omit(unique(a[[col]])), rhtp_vocabulary(col))
    if (length(bad)) stop("[ID roster] ", col, " outside §8: ", paste(bad, collapse = ", "), call. = FALSE)
  }
  fl <- unlist(strsplit(stats::na.omit(a$flag_reason), ";"))
  if (length(setdiff(fl, rhtp_vocabulary("flag_reason")))) stop("[ID roster] flag_reason outside §8.", call. = FALSE)
  invisible(TRUE)
}
