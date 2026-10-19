#!/usr/bin/env Rscript
# 03cc_ok_bhi_ems_rosters.R ----------------------------------------------------
#
# OKLAHOMA'S SIXTH AND SEVENTH ROSTERS. Session 99, on the owner's approval of
# session 98's proposal.
#
# The Funding Recipients page (now served from
# https://oklahoma.gov/rhtp/rhtp-funding-recipients.html, "Last Modified on Oct
# 12, 2026") carries two rosters that were not there on 2026-10-02:
#
#   Behavioral Health Integration (MOUD/MAUD)     3 recipients   $1,228,012.70
#     "Behavioral Health Program: List of Funding Recipients" -- a name, a
#     project and an EXACT amount per line.
#   Expanding Care: Community Paramedicine        38 + 13 lines  NO AMOUNTS
#     "Organizations receiving ambulance funding:" (38 lines) and
#     "Organizations receiving Community Paramedicine vehicle funding:" (13).
#     OSDH prints a recipient and its service counties, and no dollar figure
#     anywhere -- Nevada's shape. The rows carry `amount` EMPTY and add ROWS and
#     $0 to any hospital figure (CLAUDE.md: read the row count).
#
# Each roster is its own file (NC SBHC / AL round 2 / R/03bt precedent):
#   ok_year1_bhi_awardees.csv      ok_year1_ems_cp_awardees.csv
#
# TWO FACTS ABOUT THE EMS/CP LISTS THAT ARE RECORDED, NOT CORRECTED:
#   * "Town of Cheyenne, serving Roger Mills County" is printed TWICE in the
#     ambulance list. Whether that is two awards or one line printed twice is
#     not stated; both lines are kept as published (38) and the second says so.
#     Neither is a hospital, so no hospital figure turns on it.
#   * Five organisations are in BOTH lists (Elk City FD, Purcell Municipal
#     Hospital, Tonkawa FD, Oologah-Talala EMS District -- spelled "Oolagah" in
#     the ambulance list -- and Choctaw County Ambulance Authority): two award
#     actions each, one row each. A trailing "*" marks organisations that
#     "have received Community Paramedicine training from RHTP/OSU"; it is
#     stripped from the name and kept in the note.
#
# TYPING. Every hospital row is hand-read against the archived CMS OK Hospital
# Enrollments (federal_records/2026-09-25) and carries an R/03bj EH_APPLY
# verdict; every other row is the shared classifier's answer, refused where it
# would make a hospital. Mercy Health Oklahoma Communities follows R/03bt's
# owner-instructed typing (system, GENERAL_KNOWLEDGE, LOW, no CCN). The
# Choctaw Nation follows R/03bt's CDM row (owner resolution, session 87).
#
# §0.2: the page's CMS footer is OK's ALLOTMENT ($223,476,948.62), Tier 1.
#
# Usage:
#   Rscript R/03cc_ok_bhi_ems_rosters.R --validate | --build | --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

OKC_STATE   <- "OK"
OKC_URL     <- "https://oklahoma.gov/rhtp/rhtp-funding-recipients.html"
OKC_ARCHIVE <- file.path("data", "evidence", "OK", "new_rosters",
                         "2026-10-12_ok_rhtp_funding_recipients.html")
OKC_SHA256  <- "e000ef82c8fb8d3ee2f6c8dae955d524bab40cb0e6f075c0627deaf601725606"
OKC_READ    <- as.Date("2026-10-12")
OKC_NOA     <- as.Date("2025-12-29")
OKC_HOSP_FED <- file.path("data", "evidence", "federal_records", "2026-09-25",
                          "cms_hosp_enrollments_OK.json")
OKC_FOOTER  <- "as part of a financial assistance award totaling $223,476,948.62 with 100 percent funded by CMS/HHS"
OKC_BHI_CSV <- here::here("data", "reference", "ok_year1_bhi_awardees.csv")
OKC_EMS_CSV <- here::here("data", "reference", "ok_year1_ems_cp_awardees.csv")

OKC_BHI_ROUND <- "Behavioral Health Integration -- Medications for Opioid and Alcohol Use Disorder"
OKC_AMB_ROUND <- "Expanding Care: Community Paramedicine -- Ambulance Funding"
OKC_CPV_ROUND <- "Expanding Care: Community Paramedicine -- Community Paramedicine Vehicles"

# Counts and totals READ on 2026-10-12, asserted, never assumed.
OKC_BHI_N <- 3L; OKC_BHI_TOTAL <- 1228012.70
OKC_AMB_N <- 37L; OKC_CPV_N <- 13L   # session 103: ambulance 38 on 10-12, Wewoka removed 10-16

# SESSION 103: THE 2026-10-16 RE-READ (owner-approved, Task 4). "City of Wewoka
# (Fire Department), serving Hughes and Seminole Counties" is GONE from the
# AMBULANCE-funding list (38 -> 37; session 102's note said the vehicle list,
# and the archive says ambulance -- it is the first line under "Organizations
# receiving ambulance funding:"); nothing else in either
# roster moved (asserted). OSDH says nothing about why: it is recorded as
# REMOVED here, Alaska's rule, never shrunk silently. Not a hospital.
OKC_ARCHIVE_1016 <- file.path("data", "evidence", "OK", "new_rosters",
                              "2026-10-16_ok_rhtp_funding_recipients.html")
OKC_SHA256_1016  <- "4383da5dd3bd3690054c459b1cd204032d5b0a5e997139d535a5c972cf0f94ce"
OKC_EMS_WITHDRAWN <- tibble::tribble(
  ~round, ~line, ~last_seen, ~first_absent, ~coded_before,
  "Expanding Care: Community Paramedicine -- Ambulance Funding",
  "City of Wewoka (Fire Department), serving Hughes and Seminole Counties",
  "2026-10-12", "2026-10-16", "EMS_OR_PSAP / No")

okc_lines <- function(archive = OKC_ARCHIVE, sha = OKC_SHA256) {
  raw <- readr::read_file_raw(here::here(archive))
  if (digest::digest(raw, algo = "sha256", serialize = FALSE) != sha) {
    stop("[OK BHI/EMS] the archive's SHA-256 does not match its manifest.", call. = FALSE)
  }
  t <- rvest::html_text2(rvest::html_element(xml2::read_html(raw), "main"))
  t <- gsub("\u200b", "", t, fixed = TRUE)
  x <- stringr::str_squish(strsplit(t, "\n", fixed = TRUE)[[1]])
  x[nzchar(x)]
}

okc_between <- function(x, start, end) {
  i <- which(x == start)
  if (length(i) != 1L) stop("[OK BHI/EMS] '", start, "' not found once.", call. = FALSE)
  j <- which(startsWith(x, end)); j <- j[j > i][1]
  if (is.na(j)) stop("[OK BHI/EMS] no end marker after '", start, "'.", call. = FALSE)
  x[(i + 1):(j - 1)]
}

#' Behavioral Health: "<org> – <project>, $amount" or "<org>, $amount"
okc_parse_bhi <- function(x = okc_lines()) {
  y <- okc_between(x, "Behavioral Health Program: List of Funding Recipients",
                   "Rural Regional Reorientation (RRR) Program")
  m <- stringr::str_match(y, "^(.+?),?\\s+\\$([0-9][0-9,]*(?:\\.[0-9]{1,2})?)$")
  k <- which(!is.na(m[, 1]))
  head <- m[k, 2]
  org <- stringr::str_trim(sub("\\s+\u2013\\s+.*$", "", head))
  project <- ifelse(grepl("\u2013", head), stringr::str_trim(sub("^.*?\u2013\\s+", "", head)),
                    NA_character_)
  tibble::tibble(round = "bhi", line = y[k], awardee = org, project = project,
                 amount = as.numeric(gsub(",", "", m[k, 3])),
                 detail = vapply(k, function(z) paste(y[seq(z + 1, min(z + 2, length(y)))],
                                                      collapse = " "), character(1)))
}

#' EMS/CP: "<org>, serving <counties>" or "<org>[*]"
okc_parse_list <- function(y, round) {
  y <- y[!grepl("^var panels|^\\*These organizations", y)]
  star <- grepl("\\*$", y)
  core <- sub("\\*$", "", y)
  org <- stringr::str_trim(sub(",\\s*serving\\s+.*$", "", core))
  serving <- ifelse(grepl(",\\s*serving\\s+", core),
                    sub("^.*?,\\s*serving\\s+", "", core), NA_character_)
  tibble::tibble(round = round, line = y, awardee = org, serving = serving,
                 osu_trained = star)
}

okc_parse_ems <- function(x = okc_lines()) {
  amb <- okc_between(x, "Organizations receiving ambulance funding:", "Community Paramedicine Vehicles")
  cpv <- okc_between(x, "Organizations receiving Community Paramedicine vehicle funding:",
                     "*These organizations have received")
  dplyr::bind_rows(okc_parse_list(amb, OKC_AMB_ROUND), okc_parse_list(cpv, OKC_CPV_ROUND))
}

okc_assert_source <- function(x = okc_lines()) {
  full <- stringr::str_squish(rvest::html_text2(xml2::read_html(here::here(OKC_ARCHIVE))))
  if (!grepl(OKC_FOOTER, full, fixed = TRUE)) {
    stop("[OK BHI/EMS] the CMS footer is gone from the archive.", call. = FALSE)
  }
  b <- okc_parse_bhi(x)
  if (nrow(b) != OKC_BHI_N || abs(sum(b$amount) - OKC_BHI_TOTAL) > 0.005) {
    stop("[OK BHI] read ", nrow(b), " / $", sum(b$amount), "; expected 3 / $1,228,012.70.",
         call. = FALSE)
  }
  if (any(abs(b$amount - 223476949) < RHTP_FOOTER_ALLOTMENT_MARGIN)) {
    stop("[OK BHI] an award line equals the allotment (§0.2).", call. = FALSE)
  }
  e <- okc_parse_ems(x)
  if (sum(e$round == OKC_AMB_ROUND) != OKC_AMB_N + 1L || sum(e$round == OKC_CPV_ROUND) != OKC_CPV_N) {
    stop("[OK EMS/CP] read ", sum(e$round == OKC_AMB_ROUND), " + ",
         sum(e$round == OKC_CPV_ROUND), " lines; expected 38 + 13.", call. = FALSE)
  }
  # No dollar figure anywhere in the EMS/CP section: the rows are unpriced by
  # the SOURCE, not by this parse.
  sec <- okc_between(x, "Expanding Care: Community Paramedicine Vehicles Funding Recipients",
                     "Behavioral Health Integration")
  if (any(grepl("\\$[0-9]", sec))) {
    stop("[OK EMS/CP] the section now prints a dollar figure; re-read it.", call. = FALSE)
  }
  if (!(OKC_READ > OKC_NOA)) stop("[OK BHI/EMS] §6.2 date test.", call. = FALSE)
  invisible(TRUE)
}

# THE HAND-READ TYPING. `enrol` is "<ORG NAME>|<CCN>" on the archived CMS OK
# Hospital Enrollments; every hospital row with a CCN has an EH_APPLY verdict in
# R/03bj (session 99). Rows not listed take the shared classifier's answer.
OKC_TYPING <- tibble::tribble(
  ~awardee, ~recipient_type, ~basis_type, ~confidence, ~ccn, ~enrol_match, ~enrol, ~why,
  # ---- Behavioral Health --------------------------------------------------
  "Oklahoma State University Center for Health Sciences (OSU-CHS)", "UNIVERSITY_OR_AHC", "STATE_SOURCE", "MEDIUM", NA, NA, NA,
  "A state university's health-sciences centre. OSU's hospital is enrolled by a DIFFERENT legal body (CMS OK Hospital Enrollments: OKLAHOMA STATE UNIVERSITY MEDICAL TRUST dba OKLAHOMA STATE UNIVERSITY MEDICAL CENTER, CCN 370078, Tulsa), so §10.2's enrolled-operator row does not reach it (§2: a name that is a prefix of another body is never matched) -- R/03bt's OU Board of Regents precedent.",
  "Mercy Health Oklahoma Communities", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", NA, NA, NA,
  "§10.2 DIRECT, typed a HEALTH SYSTEM on general knowledge, exactly as R/03bt's RRR and CDM rows for the same organisation (owner's instruction, session 86): no CMS OK hospital enrolment carries this string -- Mercy's Oklahoma hospitals enrol under their own legal entities. OSDH's service area names 'seven hospitals and 37 clinics' as entry points: what the award reaches, not the recipient's form (§0.3a). No CCN, LOW.",
  "Andor Health, LLC", "NONPROFIT_CBO", NA, "LOW", NA, NA, NA,
  "OSDH states no form for this LLC and it has no CMS OK hospital enrolment under this name: §8's standing fallback, NOT promoted (§0.4). Not a hospital either way.",
  # ---- EMS / Community Paramedicine ---------------------------------------
  "Cheyenne and Arapaho Tribes", "TRIBAL_ORG", "GENERAL_KNOWLEDGE", "LOW", NA, NA, NA,
  "A federally recognised tribe (general knowledge; OSDH states no form) -- R/03bt's Wyandotte Nation precedent. The name rule misses the plural 'Tribes'. Not a hospital either way.",
  # ---- EMS / Community Paramedicine: the hospitals ------------------------
  "Baptist Healthcare of Oklahoma, LLC d/b/a INTEGRIS Miami Hospital", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", "370004", "DBA_OF_LEGAL_ENTITY",
  "INTEGRIS MIAMI HOSPITAL|370004",
  "§10.2 DIRECT on a HAND-READ BRIDGE: CMS OK Hospital Enrollments carry INTEGRIS MIAMI HOSPITAL (dba INTEGRIS MIAMI HOSPITAL), PART A PROVIDER - HOSPITAL, CCN 370004, Miami. OSDH prints the awardee as 'Baptist Healthcare of Oklahoma, LLC d/b/a INTEGRIS Miami Hospital': its d/b/a is the enrolled name and its legal entity is not, so the bridge is a judgement and LOW (the R/03bt Fairview / Cimarron precedent). Ambulance funding; §0.3a judges the recipient.",
  "Newman Memorial Hospital, Inc.", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "371336", "EXACT_LEGAL_NAME",
  "NEWMAN MEMORIAL HOSPITAL, INC|371336",
  "§10.2 DIRECT: CMS OK Hospital Enrollments carry NEWMAN MEMORIAL HOSPITAL, INC, CRITICAL ACCESS HOSPITAL, CCN 371336, Shattuck -- the awardee's exact legal name. The same hospital holds RRR and Doulas awards.",
  "Northeastern Health System", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "370089", "EXACT_LEGAL_NAME",
  "NORTHEASTERN HEALTH SYSTEM|370089",
  "§10.2 DIRECT: CMS OK Hospital Enrollments carry NORTHEASTERN HEALTH SYSTEM (dba TAHLEQUAH CITY HOSPITAL), PART A PROVIDER - HOSPITAL, CCN 370089, Tahlequah -- the awardee's exact legal name. (NORTHEASTERN HEALTH SYSTEM SEQUOYAH is the DBA of a different legal body, CCN 370112, and is not this row.)",
  "Purcell Municipal Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "370158", "EXACT_LEGAL_NAME",
  "PURCELL MUNICIPAL HOSPITAL|370158",
  "§10.2 DIRECT: CMS OK Hospital Enrollments carry PURCELL MUNICIPAL HOSPITAL, PART A PROVIDER - HOSPITAL, CCN 370158, Purcell -- the awardee's exact legal name. It is in BOTH lists (ambulance and community paramedicine vehicle): two award actions, two rows.",
  "The Choctaw Nation of Oklahoma", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "370172", "EXACT_LEGAL_NAME",
  "CHOCTAW NATION OF OKLAHOMA|370172",
  "§10.2 enrolled-operator row and its session-72 PRECEDENCE RULE: OSDH states no form, so the CMS enrolment decides -- CHOCTAW NATION OF OKLAHOMA is the ORGANIZATION NAME on PART A PROVIDER - HOSPITAL CCN 370172 (the awardee's exact legal name, less 'The'). The owner's resolution of OK_CDM_CHOCTAW_TRIBAL_HOSPITAL_ENROLMENT (session 87) applied to the same nation's ambulance award."
)

okc_assert_federal <- function() {
  e <- jsonlite::fromJSON(here::here(OKC_HOSP_FED))
  h <- tibble::tibble(org = e[["ORGANIZATION NAME"]], ccn = as.character(e$CCN))
  t <- OKC_TYPING[!is.na(OKC_TYPING$enrol), ]
  for (i in seq_len(nrow(t))) {
    p <- strsplit(t$enrol[i], "|", fixed = TRUE)[[1]]
    if (!any(h$org == p[1] & h$ccn == p[2])) {
      stop("[OK BHI/EMS] the archived hospital file no longer carries ", p[1],
           " (", p[2], ").", call. = FALSE)
    }
  }
  invisible(TRUE)
}

okc_rows <- function(p, round_label, file_kind) {
  ty <- OKC_TYPING[match(p$awardee, OKC_TYPING$awardee), ]
  typed <- !is.na(ty$awardee)
  cls <- rhtp_classify_recipient_type(p$awardee, OKC_STATE)
  # The name rule never makes a hospital here: every hospital is hand-read.
  if (any(!typed & cls$recipient_type == "HOSPITAL_OR_SYSTEM")) {
    stop("[OK BHI/EMS] the name rule types an un-read row a hospital: ",
         paste(p$awardee[!typed & cls$recipient_type == "HOSPITAL_OR_SYSTEM"],
               collapse = "; "), ". Read it and add it to OKC_TYPING.", call. = FALSE)
  }
  rtype <- ifelse(typed, ty$recipient_type, cls$recipient_type)
  conf  <- ifelse(typed, ty$confidence, rhtp_confidence_ceiling(cls$determination_confidence))
  fallback <- rtype == "NONPROFIT_CBO" & conf == "LOW" & (!typed | is.na(ty$basis_type))
  hosp <- rtype == "HOSPITAL_OR_SYSTEM"
  dup <- duplicated(paste(p$round, p$line))
  extra <- if (file_kind == "ems") paste0(
    ifelse(is.na(p$serving), "", paste0(" Serving ", p$serving, ".")),
    ifelse(p$osu_trained, " Marked '*': 'These organizations have received Community Paramedicine training from RHTP/OSU.'", ""),
    ifelse(dup, " OSDH PRINTS THIS LINE TWICE in the ambulance list; whether that is a second award or a repeated line is not stated, and both lines are kept as published.", "")
  ) else paste0(ifelse(is.na(p$project), "", paste0(" Project: ", p$project, ".")), " ", p$detail)
  tibble::tibble(
    state = OKC_STATE,
    row_no = seq_len(nrow(p)),
    awardee = p$awardee,
    amount = if (file_kind == "bhi") p$amount else NA_real_,
    recipient_type = rtype,
    distributed_to_hospital = ifelse(hosp, "Yes", "No"),
    note = paste0(p$round, ", OSDH Funding Recipients page (read ", OKC_READ, ").", extra),
    recipient_confirmed = "Yes",
    amount_confirmed = if (file_kind == "bhi") "Yes" else "No",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = paste0("Oklahoma RHTP Funding Recipients -- ", p$round),
    state_source_url = OKC_URL,
    validation_source_type = "NOTICE_OF_AWARD",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03cc_ok_bhi_ems_rosters.R",
    ccn = ifelse(hosp, ty$ccn, NA_character_),
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    recipient_type_source = ifelse(
      typed, paste0("TYPED (session 99, HAND-READ): ", ty$why, " Classifier said ",
                    cls$recipient_type, "/", rhtp_confidence_ceiling(cls$determination_confidence), "."),
      paste0("rhtp_classify_recipient_type() on the name: ", cls$recipient_type, "/",
             rhtp_confidence_ceiling(cls$determination_confidence),
             ". OSDH states no form; no CMS OK hospital enrolment read for this row.")),
    determination_confidence = conf,
    flag_reason = ifelse(fallback, "RECIPIENT_TYPE_INFERRED", NA_character_),
    award_pool = p$round,
    budget_period = "Budget Period 1",
    flow_type = ifelse(hosp, "DIRECT", "NON_HOSPITAL"),
    hospital_benefiting = ifelse(hosp, "Yes", "Unclear"),
    hospital_attribution = ifelse(hosp, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = paste0(
      "§10.2 ", ifelse(hosp, "DIRECT", "NON_HOSPITAL"), ": ",
      ifelse(typed, ty$why, paste0("the recipient is ", rtype, " on the shared classifier; OSDH states no form and the name is not a hospital's.")),
      if (file_kind == "ems") " OSDH publishes NO AMOUNT for any ambulance or community paramedicine vehicle award; `amount` is empty by the source, so this row adds a ROW and $0 to any hospital figure (Nevada's shape)." else ""),
    amount_basis = if (file_kind == "bhi") "EXACT, as published per recipient by OSDH." else "NOT PUBLISHED: OSDH names the recipient and its service counties and prints no amount.",
    round_name = p$round,
    round_awards = as.integer(table(p$round)[p$round]),
    round_amount = NA_real_,
    announcement_date = OKC_READ,
    source_archive_path = OKC_ARCHIVE,
    basis_type = ifelse(typed, ty$basis_type, NA_character_),
    recipient_subtype = NA_character_,
    cms_enrolment_match = ifelse(hosp, ty$enrol_match, NA_character_),
    cms_enrolment_record = ifelse(
      hosp & !is.na(ty$enrol),
      paste0("CMS Hospital Enrollments: ", sub("\\|", ", CCN ", ty$enrol), " (", OKC_HOSP_FED, ")"),
      NA_character_))
}

okc_assert_rows <- function(a, kind) {
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "determination_confidence", "hospital_attribution", "basis_type",
                "flag_reason", "cms_enrolment_match", "hospital_benefiting")) {
    bad <- setdiff(stats::na.omit(unique(a[[col]])), rhtp_vocabulary(col))
    if (length(bad)) stop("[OK ", kind, "] ", col, " outside §8: ",
                          paste(bad, collapse = ", "), call. = FALSE)
  }
  if (any(a$determination_confidence == "HIGH")) {
    stop("[OK ", kind, "] HIGH is reserved for Stage 5 (§7).", call. = FALSE)
  }
  h <- a[a$distributed_to_hospital == "Yes", ]
  if (any(h$recipient_type != "HOSPITAL_OR_SYSTEM")) {
    stop("[OK ", kind, "] a hospital row is not HOSPITAL_OR_SYSTEM.", call. = FALSE)
  }
  if (any(is.na(h$ccn) & h$determination_confidence != "LOW")) {
    stop("[OK ", kind, "] a hospital row with no CCN must be LOW.", call. = FALSE)
  }
  if (kind == "bhi") {
    if (nrow(h) != 1L || h$awardee != "Mercy Health Oklahoma Communities" ||
        abs(sum(h$amount) - 90171.53) > 0.005) {
      stop("[OK BHI] one hospital row, Mercy, $90,171.53.", call. = FALSE)
    }
  } else {
    if (any(!is.na(a$amount))) stop("[OK EMS/CP] a row carries an amount.", call. = FALSE)
    if (nrow(h) != 6L) stop("[OK EMS/CP] six hospital rows expected, found ", nrow(h), ".",
                            call. = FALSE)
  }
  invisible(TRUE)
}

#' The EMS/CP lists as of 10-16: the 10-12 lists less OKC_EMS_WITHDRAWN, and
#' nothing else; BHI unchanged. Rows keep their 10-12 strings and order.
okc_ems_now <- function(x = okc_lines()) {
  was <- okc_parse_ems(x)
  x16 <- okc_lines(OKC_ARCHIVE_1016, OKC_SHA256_1016)
  now <- okc_parse_ems(x16)
  k <- function(d) paste(d$round, d$line)
  gone <- k(was)[!k(was) %in% k(now)]
  if (!setequal(gone, paste(OKC_EMS_WITHDRAWN$round, OKC_EMS_WITHDRAWN$line)) ||
      !identical(k(was)[!k(was) %in% gone], k(now))) {
    stop("[OK EMS/CP] the 10-16 lists are not the 10-12 lists less OKC_EMS_WITHDRAWN; ",
         "re-read both archives.", call. = FALSE)
  }
  b0 <- okc_parse_bhi(x); b1 <- okc_parse_bhi(x16)
  if (!identical(paste(b0$awardee, b0$amount), paste(b1$awardee, b1$amount))) {
    stop("[OK BHI] the Behavioral Health roster moved between 10-12 and 10-16.", call. = FALSE)
  }
  was[!k(was) %in% gone, ]
}

okc_build_tables <- function() {
  x <- okc_lines()
  okc_assert_source(x)
  okc_assert_federal()
  b <- okc_rows(okc_parse_bhi(x) %>% dplyr::mutate(round = OKC_BHI_ROUND), OKC_BHI_ROUND, "bhi")
  e <- okc_rows(okc_ems_now(x), NA, "ems")
  okc_assert_rows(b, "bhi"); okc_assert_rows(e, "ems")
  list(bhi = b, ems = e)
}

okc_s71 <- function(a, file) {
  env <- new.env()
  suppressMessages(source(here::here("R", "03bj_enrolled_hospital_operator.R"), local = env))
  num <- function(x) ifelse(is.na(x), NA_character_,
                            vapply(x, function(v) format(v, scientific = FALSE, digits = 15),
                                   character(1)))
  a <- dplyr::mutate(a, dplyr::across(dplyr::where(is.numeric), num),
                     dplyr::across(dplyr::everything(), as.character))
  env$s71_overlay(a, file)
}

okc_build <- function() {
  t <- okc_build_tables()
  readr::write_csv(okc_s71(t$bhi, basename(OKC_BHI_CSV)), OKC_BHI_CSV, na = "")
  readr::write_csv(okc_s71(t$ems, basename(OKC_EMS_CSV)), OKC_EMS_CSV, na = "")
  message("[OK BHI] wrote ", nrow(t$bhi), " rows, $",
          format(sum(t$bhi$amount), big.mark = ",", nsmall = 2), "; 1 hospital row (Mercy, $90,171.53, LOW).")
  message("[OK EMS/CP] wrote ", nrow(t$ems), " rows, NO amounts; ",
          sum(t$ems$distributed_to_hospital == "Yes"), " hospital rows at $0.")
  invisible(t)
}

okc_report <- function() {
  t <- okc_build_tables()
  for (k in names(t)) {
    cat("\n==", k, "\n")
    print(as.data.frame(t[[k]] %>% dplyr::select(awardee, amount, recipient_type,
                                                  distributed_to_hospital, determination_confidence, ccn)),
          row.names = FALSE)
  }
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) { okc_build_tables(); message("[OK BHI/EMS] all assertions pass.") }
  if ("--build" %in% args) okc_build()
  if ("--report" %in% args) okc_report()
  if (!length(args)) message("Usage: --validate | --build | --report")
}
