#!/usr/bin/env Rscript
# 03cq_mo_smart_growth_awardees.R ---------------------------------------------
#
# MISSOURI'S SMART GROWTH AND SERVICE LINE MODERNIZATION CONTINGENT ROSTER ->
# data/reference/mo_smart_growth_awardees.csv. Session 114, OWNER RULING (Task 2):
# extract as INTENTS pending CMS approval, as with California's tentative list.
#
# THE SOURCE. https://dss.mo.gov/mhd/rhtp-modernize-rural-healthcare-services
# (archived by R/03w --fetch as data/evidence/MO/2026-11-04_dss_smart_growth_
# contingent_roster.html; session 112 first read it on 11-02 under
# recheck/2026-11-02/MO/, content-identical). "The Missouri Department of Social
# Services (DSS) has awarded approximately $39.4 million in Smart Growth and
# Service Line Modernization funding under Missouri's Rural Health
# Transformation Program (RHTP)" over ONE table headed "Contingent Awardee |
# City and County | Award", 25 rows, "Total $39,400,820.55". Two rows carry
# "(approved by CMS)".
#
# WHY INTENTS. The release (2026-10-30; data/evidence/MO/2026-11-04_dss_smart_
# growth_release.html) says: "All contingent awards have to be approved by the
# Centers for Medicare and Medicaid Services before a final award can be made."
# So 23 rows are NOTICE_OF_INTENT_TO_AWARD + AMOUNT_PRELIMINARY (California's
# coding). The two "(approved by CMS)" rows have met the one stated condition:
# they are NOTICE_OF_AWARD, amount_confirmed = Yes, and `cms_approval` records
# which is which. Nothing about the AMOUNT changes with approval.
#
# 26 vs 25. The release and the page both say "awarding full or partial
# funding to 26 rural providers"; the table lists 25 and totals $39,400,820.55.
# RECORDED, NOT FILLED: no 26th row is imputed, and the gap sits in every row's
# note and in the assertion below.
#
# PROVENANCE AND TIER. The page is DSS's RHTP office; the money is the
# Smart Growth IFB's (DSS26015-02, Horizon 2, "Funding is open to hospitals",
# up to $5M per award: Heartland's $5,000,000.00 is exactly the cap). The
# figures are per-recipient Tier 3 amounts and none collides with the §7.1
# anchor ($216,276,818). The page's date (posted 2026-10-30) is after the NOA.
#
# TYPING (on CMS MO Hospital / FQHC / RHC Enrollments, archived 2026-11-04 under
# data/evidence/federal_records/2026-11-04/). DSS states no form.
#   * 14 HOSPITAL rows ($31,862,169.80): exact legal name (less Inc) MEDIUM;
#     an exact DBA or a near name in the same city is a hand-read bridge, LOW.
#   * 6 FQHC rows on the CMS FQHC file (exact legal name MEDIUM, DBA LOW).
#   * 5 rows with no enrolment of any kind under their name: §8's standing
#     fallback (NONPROFIT_CBO, LOW, RECIPIENT_TYPE_INFERRED). One of them is
#     "Ozarks Community Hospital" (Webb City): the word "Hospital" is in its
#     name and NO Missouri hospital enrolment carries it, so it is NOT a hospital
#     row (§0.4; the summary layer carries a written judgment). Another is
#     "Ozark Center" (Joplin), Freeman Health System's behavioural-health
#     affiliate on general knowledge: its name and the page name no hospital,
#     so §7's affiliated-arm row (which needs the parent NAMED) does not reach it.
#
# cms_enrolment_match is left EMPTY on every row (the CCN and the enrolment are
# in ccn and cms_enrolment_record), so R/03bj's overlay does not claim them.
#
# Usage:
#   Rscript R/03cq_mo_smart_growth_awardees.R --validate | --build | --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

MOSG_STATE   <- "MO"
MOSG_URL     <- "https://dss.mo.gov/mhd/rhtp-modernize-rural-healthcare-services"
MOSG_ROSTER  <- file.path("data", "evidence", "MO", "2026-11-04_dss_smart_growth_contingent_roster.html")
MOSG_RELEASE <- file.path("data", "evidence", "MO", "2026-11-04_dss_smart_growth_release.html")
MOSG_FED_DIR <- file.path("data", "evidence", "federal_records", "2026-11-04")
MOSG_CSV     <- file.path("data", "reference", "mo_smart_growth_awardees.csv")
MOSG_POSTED  <- as.Date("2026-10-30")
MOSG_NOA     <- as.Date("2025-12-29")
MOSG_TOTAL   <- 39400820.55
MOSG_HOSP_TOTAL <- 31862169.80
MOSG_LABEL   <- "Smart Growth and Service Line Modernization (contingent awards)"

# The roster as printed (awardee without the "(approved by CMS)" marker).
#   kind:  HOSP | FQHC | FALLBACK
#   grade: LEGAL (MEDIUM) | BRIDGE (LOW) | NONE
#   enrol: "<file>|<ORG NAME>|<CCN or ->" on the 2026-11-04 CMS MO files.
MOSG_ROWS <- tibble::tribble(
  ~awardee, ~city_county, ~amount, ~approved, ~kind, ~grade, ~ccn, ~enrol, ~why,
  "Missouri Delta Medical Center", "Sikeston (Scott)", 3265760.63, TRUE, "HOSP", "LEGAL", "260113",
    "hosp|MISSOURI DELTA MEDICAL CENTER|260113", "the exact legal name MISSOURI DELTA MEDICAL CENTER (PART A PROVIDER - HOSPITAL, CCN 260113, Sikeston).",
  "Heartland Regional Medical Center", "St. Joseph (Buchanan)", 5000000.00, TRUE, "HOSP", "LEGAL", "260006",
    "hosp|HEARTLAND REGIONAL MEDICAL CENTER|260006", "the exact legal name HEARTLAND REGIONAL MEDICAL CENTER (dba MOSAIC LIFE CARE AT ST JOSEPH MEDICAL CENTER, PART A PROVIDER - HOSPITAL, CCN 260006, Saint Joseph).",
  "Arthur Center", "Mexico (Audrain)", 542165.50, FALSE, "FQHC", "BRIDGE", NA,
    "fqhc|EAST CENTRAL MISSOURI BEHAVIORAL HEALTH SERVICES INC|-", "the trading name of EAST CENTRAL MISSOURI BEHAVIORAL HEALTH SERVICES INC, enrolled as an FQHC dba ARTHUR CENTER COMMUNITY HEALTH (Mexico): a hand-read bridge, LOW. A community mental health centre that runs an FQHC; not a hospital either way.",
  "Big Springs Medical Association", "Ellington (Reynolds)", 247387.00, FALSE, "FQHC", "LEGAL", NA,
    "fqhc|BIG SPRINGS MEDICAL ASSOCIATION|-", "the exact legal name BIG SPRINGS MEDICAL ASSOCIATION, enrolled as an FQHC (dba MISSOURI HIGHLANDS HEALTH CENTER, Ellington).",
  "Cameron Regional Medical Center", "Cameron (Clinton)", 922262.25, FALSE, "HOSP", "LEGAL", "260057",
    "hosp|CAMERON REGIONAL MEDICAL CENTER INC|260057", "the legal name CAMERON REGIONAL MEDICAL CENTER INC less 'Inc' (PART A PROVIDER - HOSPITAL, CCN 260057, Cameron).",
  "Centerstone of Missouri", "Kirksville (Adair)", 1830777.00, FALSE, "FALLBACK", "NONE", NA, NA,
    "no CMS hospital, FQHC or RHC enrolment in Missouri carries the name; a behavioural-health provider on general knowledge, form unstated by DSS.",
  "Compass Health", "Clinton (Henry)", 526500.00, FALSE, "FQHC", "LEGAL", NA,
    "fqhc|COMPASS HEALTH INC|-", "the legal name COMPASS HEALTH INC less 'Inc', enrolled as an FQHC (Clinton among its sites).",
  "Four Rivers Community Health Center", "Rolla (Phelps)", 800000.00, FALSE, "FQHC", "BRIDGE", NA,
    "fqhc|SOUTH CENTRAL MISSOURI COMMUNITY HEALTH CENTER|-", "the exact DBA FOUR RIVERS COMMUNITY HEALTH CENTER of SOUTH CENTRAL MISSOURI COMMUNITY HEALTH CENTER, an enrolled FQHC (Rolla).",
  "Gibson Center for Behavioral Change", "Cape Girardeau (Cape Girardeau)", 98965.14, FALSE, "FALLBACK", "NONE", NA, NA,
    "no CMS hospital, FQHC or RHC enrolment in Missouri carries the name; a behavioural-health provider, form unstated by DSS.",
  "Hannibal Regional Healthcare System", "Hannibal (Marion)", 1086247.96, FALSE, "HOSP", "LEGAL", "260025",
    "hosp|HANNIBAL REGIONAL HEALTHCARE SYSTEM INC|260025", "the legal name HANNIBAL REGIONAL HEALTHCARE SYSTEM INC less 'Inc' (dba HANNIBAL REGIONAL HOSPITAL, CCN 260025).",
  "Hermann Area District Hospital", "Hermann (Gasconade)", 3637412.00, FALSE, "HOSP", "BRIDGE", "261314",
    "hosp|HERMANN AREA HOSPITAL DISTRICT|261314", "the exact DBA HERMANN AREA DISTRICT HOSPITAL of HERMANN AREA HOSPITAL DISTRICT (CAH 261314, Hermann).",
  "Katy Trail Community Health", "Sedalia (Pettis)", 847225.64, FALSE, "FQHC", "BRIDGE", NA,
    "fqhc|REGIONAL HEALTH CARE CLINIC INC|-", "the exact DBA KATY TRAIL COMMUNITY HEALTH of REGIONAL HEALTH CARE CLINIC INC, an enrolled FQHC (Sedalia).",
  "Lake Regional Health Center", "Osage Beach (Camden)", 2510342.00, FALSE, "HOSP", "BRIDGE", "260186",
    "hosp|LAKE REGIONAL HEALTH SYSTEM|260186", "HAND-READ BRIDGE: DSS prints 'Lake Regional Health Center'; the one enrolled Lake Regional body in Osage Beach is LAKE REGIONAL HEALTH SYSTEM (PART A PROVIDER - HOSPITAL, CCN 260186), named exactly on the SMRP roster.",
  "Mark Twain Behavioral Health", "Hannibal (Marion)", 271104.75, FALSE, "FALLBACK", "NONE", NA, NA,
    "no CMS hospital, FQHC or RHC enrolment in Missouri carries the name; a behavioural-health provider, form unstated by DSS.",
  "Mercy Hospital Perry", "Perryville (Perry)", 2028750.00, FALSE, "HOSP", "LEGAL", "261311",
    "hosp|MERCY HOSPITAL PERRY|261311", "the exact legal name MERCY HOSPITAL PERRY (CAH 261311, Perryville).",
  "Nevada Regional Medical Center", "Nevada (Vernon)", 2431783.13, FALSE, "HOSP", "BRIDGE", "260061",
    "hosp|NEVADA CITY HOSPITAL|260061", "the exact DBA NEVADA REGIONAL MEDICAL CENTER of NEVADA CITY HOSPITAL (PART A PROVIDER - HOSPITAL, CCN 260061).",
  "Ozark Center", "Joplin (Jasper)", 1466432.37, FALSE, "FALLBACK", "NONE", NA, NA,
    "no CMS hospital, FQHC or RHC enrolment in Missouri carries the name. On general knowledge Ozark Center is Freeman Health System's behavioural-health affiliate (Freeman is enrolled as FREEMAN-OAK HILL HEALTH SYSTEM, CCN 260137), but neither the name nor DSS's page names Freeman, so §7's affiliated-arm row does not reach it.",
  "Ozarks Community Hospital", "Webb City (Jasper)", 787430.36, FALSE, "FALLBACK", "NONE", NA, NA,
    "NO CMS hospital, FQHC or RHC enrolment in Missouri carries the name, although the name says 'Hospital'. Not a hospital row on this pipeline's authority (§0.4); the summary layer carries a written judgment.",
  "Ozarks Medical Center", "West Plains (Howell)", 3582525.00, FALSE, "HOSP", "LEGAL", "260078",
    "hosp|OZARKS MEDICAL CENTER|260078", "the exact legal name OZARKS MEDICAL CENTER (dba OZARKS HEALTHCARE, PART A PROVIDER - HOSPITAL, CCN 260078, West Plains).",
  "Ozarks Resource Group", "Hermitage (Hickory)", 120662.99, FALSE, "FQHC", "LEGAL", NA,
    "fqhc|OZARKS RESOURCE GROUP|-", "the exact legal name OZARKS RESOURCE GROUP, enrolled as an FQHC (dba OZARKS COMMUNITY HEALTH CENTER, Hermitage).",
  "Phelps County Regional Medical Center", "Rolla (Phelps)", 1585002.75, FALSE, "HOSP", "LEGAL", "260017",
    "hosp|PHELPS COUNTY REGIONAL MEDICAL CENTER|260017", "the exact legal name PHELPS COUNTY REGIONAL MEDICAL CENTER (dba PHELPS HEALTH, CCN 260017, Rolla).",
  "Scotland County Hospital", "Memphis (Scotland)", 611782.76, FALSE, "HOSP", "BRIDGE", "261310",
    "hosp|SCOTLAND COUNTY MEMORIAL HOSPITAL|261310", "the exact DBA SCOTLAND COUNTY HOSPITAL of SCOTLAND COUNTY MEMORIAL HOSPITAL (CAH 261310, Memphis).",
  "Texas County Memorial Hospital", "Houston (Texas)", 989445.32, FALSE, "HOSP", "LEGAL", "260024",
    "hosp|TEXAS COUNTY MEMORIAL HOSPITAL|260024", "the exact legal name TEXAS COUNTY MEMORIAL HOSPITAL (PART A PROVIDER - HOSPITAL, CCN 260024, Houston).",
  "Washington County Memorial Hospital", "Potosi (Washington)", 1027413.00, FALSE, "HOSP", "LEGAL", "261308",
    "hosp|WASHINGTON COUNTY MEMORIAL HOSPITAL|261308", "the exact legal name WASHINGTON COUNTY MEMORIAL HOSPITAL (CAH 261308, Potosi).",
  "Western Missouri Medical Center", "Warrensburg (Johnson)", 3183443.00, FALSE, "HOSP", "LEGAL", "260097",
    "hosp|WESTERN MISSOURI MEDICAL CENTER|260097", "the exact legal name WESTERN MISSOURI MEDICAL CENTER (PART A PROVIDER - HOSPITAL, CCN 260097, Warrensburg).")

mosg_text <- function(f) {
  doc <- xml2::read_html(here::here(f))
  xml2::xml_remove(xml2::xml_find_all(doc, "//script | //style"))
  stringr::str_squish(gsub(" ", " ", xml2::xml_text(doc)))
}

#' The table as printed: awardee (marker kept), city and county, amount
mosg_parse <- function(f = MOSG_ROSTER) {
  h <- if (is.raw(f)) xml2::read_html(f) else xml2::read_html(here::here(f))
  tabs <- xml2::xml_find_all(h, "//table")
  if (length(tabs) != 1L) stop("[MO SG] expected ONE table, found ", length(tabs), ".", call. = FALSE)
  rows <- xml2::xml_find_all(tabs[[1]], ".//tr")
  cells <- lapply(rows, function(r) stringr::str_squish(gsub(" ", " ",
    xml2::xml_text(xml2::xml_find_all(r, "./td|./th")))))
  if (!identical(cells[[1]], c("Contingent Awardee", "City and County", "Award"))) {
    stop("[MO SG] the header is no longer 'Contingent Awardee | City and County | Award': ",
         paste(cells[[1]], collapse = " | "), ". Read what the column now IS.", call. = FALSE)
  }
  last <- cells[[length(cells)]]
  if (last[1] != "Total") stop("[MO SG] the table no longer ends in its Total row.", call. = FALSE)
  body <- cells[-c(1, length(cells))]
  out <- tibble::tibble(
    printed = vapply(body, `[`, "", 1),
    city_county = vapply(body, `[`, "", 2),
    amount_txt = vapply(body, `[`, "", 3))
  if (!all(grepl("^\\$[0-9]{1,3}(,[0-9]{3})*\\.[0-9]{2}$", out$amount_txt))) {
    stop("[MO SG] an amount is not dollars-and-cents.", call. = FALSE)
  }
  out$amount <- as.numeric(gsub("[$,]", "", out$amount_txt))
  out$approved <- grepl("\\(approved by CMS\\)", out$printed)
  out$awardee <- stringr::str_squish(sub("\\s*\\(approved by CMS\\)", "", out$printed))
  attr(out, "total") <- as.numeric(gsub("[$,]", "", last[length(last)]))
  out
}

#' THE PROBE'S QUESTION (R/03w --probe): does the live table still equal the
#' extracted rows? A new row, a re-pricing, a CMS-approval marker added or
#' dropped, or a changed Total all trip, so the file is REWRITTEN, not patched.
mosg_assert_live <- function(body) {
  p <- mosg_parse(body)
  if (!identical(p$awardee, MOSG_ROWS$awardee) || any(abs(p$amount - MOSG_ROWS$amount) >= 0.005) ||
      !identical(p$approved, MOSG_ROWS$approved) || abs(attr(p, "total") - MOSG_TOTAL) >= 0.005) {
    newly <- p$awardee[p$approved & !(p$awardee %in% MOSG_ROWS$awardee[MOSG_ROWS$approved])]
    stop("[MO SG] the contingent roster moved: ", nrow(p), " rows / $",
         formatC(sum(p$amount), format = "f", digits = 2, big.mark = ","), ", ", sum(p$approved),
         " approved by CMS", if (length(newly)) paste0(" (newly approved: ", paste(newly, collapse = "; "), ")") else "",
         ". Rewrite MOSG_ROWS from the page and rebuild R/03cq.", call. = FALSE)
  }
  invisible(TRUE)
}

mosg_assert_sources <- function() {
  p <- mosg_parse()
  if (!identical(p$awardee, MOSG_ROWS$awardee)) {
    stop("[MO SG] the roster changed: ", paste(union(setdiff(p$awardee, MOSG_ROWS$awardee),
                                                     setdiff(MOSG_ROWS$awardee, p$awardee)),
                                               collapse = "; "), ". REWRITE, do not patch.", call. = FALSE)
  }
  if (any(abs(p$amount - MOSG_ROWS$amount) >= 0.005) || !identical(p$approved, MOSG_ROWS$approved) ||
      !identical(p$city_county, MOSG_ROWS$city_county)) {
    stop("[MO SG] an amount, a CMS-approval marker or a city moved. REWRITE.", call. = FALSE)
  }
  if (abs(attr(p, "total") - MOSG_TOTAL) >= 0.005 || abs(sum(p$amount) - MOSG_TOTAL) >= 0.005) {
    stop("[MO SG] the rows or the printed Total no longer equal $39,400,820.55.", call. = FALSE)
  }
  if (nrow(p) != 25L || sum(p$approved) != 2L) stop("[MO SG] expected 25 rows, 2 approved.", call. = FALSE)
  rt <- mosg_text(MOSG_ROSTER)
  rl <- mosg_text(MOSG_RELEASE)
  for (w in c("has awarded approximately $39.4 million in Smart Growth and Service Line Modernization funding",
              "awarding full or partial funding to 26 rural providers")) {
    if (!grepl(w, rt, fixed = TRUE)) stop("[MO SG] the roster page no longer says '", w, "'.", call. = FALSE)
  }
  if (!grepl("All contingent awards have to be approved by the Centers for Medicare and Medicaid Services before a final award can be made",
             rl, fixed = TRUE)) {
    stop("[MO SG] the release no longer carries the CMS-approval condition.", call. = FALSE)
  }
  if (!(MOSG_POSTED > MOSG_NOA)) stop("[MO SG] §6.2 date test.", call. = FALSE)
  if (any(abs(p$amount - 216276818) < RHTP_FOOTER_ALLOTMENT_MARGIN)) stop("[MO SG] a line equals the allotment (§0.2).", call. = FALSE)
  # Every enrolment cited is on the archived CMS file.
  fed <- list(
    hosp = jsonlite::fromJSON(here::here(MOSG_FED_DIR, "cms_hosp_enrollments_MO.json")),
    fqhc = jsonlite::fromJSON(here::here(MOSG_FED_DIR, "cms_fqhc_enrollments_MO.json")),
    rhc  = jsonlite::fromJSON(here::here(MOSG_FED_DIR, "cms_rhc_enrollments_MO.json")))
  for (x in stats::na.omit(MOSG_ROWS$enrol)) {
    q <- strsplit(x, "|", fixed = TRUE)[[1]]
    e <- fed[[q[1]]]
    ok <- any(e[["ORGANIZATION NAME"]] == q[2] & (q[3] == "-" | as.character(e$CCN) == q[3]))
    if (!ok) stop("[MO SG] the archived ", q[1], " file no longer carries ", q[2], ".", call. = FALSE)
  }
  # A FALLBACK row must carry no enrolment of any kind under its own name.
  for (a in MOSG_ROWS$awardee[MOSG_ROWS$kind == "FALLBACK"]) {
    for (k in names(fed)) {
      nm <- toupper(c(fed[[k]][["ORGANIZATION NAME"]], fed[[k]][["DOING BUSINESS AS NAME"]]))
      if (toupper(a) %in% nm) stop("[MO SG] '", a, "' IS on the CMS ", k, " file: re-type it.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

mosg_rows <- function() {
  mosg_assert_sources()
  r <- MOSG_ROWS
  hosp <- r$kind == "HOSP"
  fb <- r$kind == "FALLBACK"
  cls <- rhtp_classify_recipient_type(r$awardee, MOSG_STATE)
  conf <- dplyr::case_when(fb ~ "LOW", r$grade == "LEGAL" ~ "MEDIUM", TRUE ~ "LOW")
  flag <- mapply(function(f, a) {
    x <- c(if (f) "RECIPIENT_TYPE_INFERRED", if (!a) "AMOUNT_PRELIMINARY")
    if (length(x)) paste(x, collapse = ";") else NA_character_
  }, fb, r$approved)
  fed_file <- function(x) ifelse(is.na(x), NA_character_, paste0(
    "CMS ", ifelse(startsWith(x, "hosp|"), "Hospital", "FQHC"), " Enrollments: ",
    sub("\\|-$", "", sub("^[a-z]+\\|", "", gsub("\\|([0-9]{6})$", ", CCN \\1", x))),
    " (", MOSG_FED_DIR, ")"))
  tibble::tibble(
    state = MOSG_STATE,
    row_no = seq_len(nrow(r)),
    awardee = r$awardee,
    amount = r$amount,
    recipient_type = dplyr::case_when(hosp ~ "HOSPITAL_OR_SYSTEM", r$kind == "FQHC" ~ "FQHC_OR_RHC",
                                      TRUE ~ "NONPROFIT_CBO"),
    distributed_to_hospital = ifelse(hosp, "Yes", "No"),
    note = paste0(MOSG_LABEL, ", DSS (posted 2026-10-30, read 2026-11-04). As printed: '", r$awardee,
                  ifelse(r$approved, " (approved by CMS)", ""), " | ", r$city_county, " | $",
                  formatC(r$amount, format = "f", digits = 2, big.mark = ","), "'. ",
                  ifelse(r$approved,
                         "Marked '(approved by CMS)': the release's one condition ('All contingent awards have to be approved by the Centers for Medicare and Medicaid Services before a final award can be made') is met.",
                         "A CONTINGENT award: 'All contingent awards have to be approved by the Centers for Medicare and Medicaid Services before a final award can be made' (DSS, 10-30). An INTENT, not an executed award."),
                  " DSS says '26 rural providers'; the table lists 25 and totals $39,400,820.55 (the 26th is not imputed)."),
    recipient_confirmed = "Yes",
    amount_confirmed = ifelse(r$approved, "Yes", "No"),
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = "RHTP Modernize Rural Healthcare Services (DSS Smart Growth and Service Line Modernization contingent awards)",
    state_source_url = MOSG_URL,
    validation_source_type = ifelse(r$approved, "NOTICE_OF_AWARD", "NOTICE_OF_INTENT_TO_AWARD"),
    extraction_method = "DIRECT_TEXT",
    validator = "R/03cq_mo_smart_growth_awardees.R",
    ccn = ifelse(hosp, r$ccn, NA_character_),
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    city_county = r$city_county,
    cms_approval = ifelse(r$approved, "APPROVED_BY_CMS", "PENDING_CMS_APPROVAL"),
    recipient_type_source = paste0("TYPED (session 114, owner ruling; HAND-READ on CMS MO enrolment): ", r$why,
                                   " Classifier said ", cls$recipient_type, "/",
                                   rhtp_confidence_ceiling(cls$determination_confidence), "."),
    determination_confidence = conf,
    flag_reason = unname(flag),
    award_pool = MOSG_LABEL,
    budget_period = "Budget Period 1",
    flow_type = ifelse(hosp, "DIRECT", "NON_HOSPITAL"),
    hospital_benefiting = ifelse(hosp, "Yes", "No"),
    hospital_attribution = ifelse(hosp, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = dplyr::case_when(
      hosp ~ paste0("§10.2 DIRECT: DSS names this recipient on its Smart Growth contingent roster with its own amount; it is ",
                    r$why, " §0.3a: the recipient is a hospital whatever the project."),
      r$kind == "FQHC" ~ paste0("§10.2 NON_HOSPITAL: ", r$why),
      TRUE ~ paste0("§8 standing fallback (form unstated by DSS): ", r$why)),
    amount_basis = ifelse(r$approved,
                          "EXACT, as published per row by DSS; CMS-approved.",
                          "PRELIMINARY: printed exactly, contingent on CMS approval (AMOUNT_PRELIMINARY)."),
    basis_type = dplyr::case_when(fb ~ NA_character_, TRUE ~ "STATE_SOURCE"),
    recipient_subtype = NA_character_,
    round_amount = NA_real_,
    announcement_date = MOSG_POSTED,
    source_archive_path = MOSG_ROSTER,
    cms_enrolment_record = fed_file(r$enrol))
}

mosg_assert_rows <- function(a) {
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital", "determination_confidence",
                "hospital_attribution", "basis_type", "flag_reason", "hospital_benefiting")) {
    vals <- unlist(strsplit(stats::na.omit(as.character(a[[col]])), ";", fixed = TRUE))
    bad <- setdiff(unique(vals), rhtp_vocabulary(col))
    if (length(bad)) stop("[MO SG] ", col, " outside §8: ", paste(bad, collapse = ", "), call. = FALSE)
  }
  h <- a[a$distributed_to_hospital == "Yes", ]
  if (nrow(h) != 14L || abs(sum(h$amount) - MOSG_HOSP_TOTAL) >= 0.005 || any(is.na(h$ccn))) {
    stop("[MO SG] expected 14 hospital rows / $31,862,169.80, each with a CCN.", call. = FALSE)
  }
  if (any(a$determination_confidence == "HIGH")) stop("[MO SG] HIGH (§7).", call. = FALSE)
  if (sum(a$validation_source_type == "NOTICE_OF_INTENT_TO_AWARD") != 23L) stop("[MO SG] expected 23 intents.", call. = FALSE)
  invisible(TRUE)
}

mosg_build <- function() {
  a <- mosg_rows()
  mosg_assert_rows(a)
  num <- function(x) ifelse(is.na(x), NA_character_,
                            vapply(x, function(v) format(v, scientific = FALSE, digits = 15), character(1)))
  out <- dplyr::mutate(a, dplyr::across(dplyr::where(is.numeric), num),
                       dplyr::across(dplyr::everything(), as.character))
  readr::write_csv(out, here::here(MOSG_CSV), na = "")
  h <- a[a$distributed_to_hospital == "Yes", ]
  message(sprintf("[MO SG] %d rows / $%s; %d hospital rows / $%s; %d intents.", nrow(a),
                  format(sum(a$amount), big.mark = ",", nsmall = 2), nrow(h),
                  format(sum(h$amount), big.mark = ",", nsmall = 2),
                  sum(a$validation_source_type == "NOTICE_OF_INTENT_TO_AWARD")))
  invisible(a)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) { mosg_assert_rows(mosg_rows()); message("[MO SG] all assertions pass.") }
  if ("--build" %in% args) mosg_build()
  if ("--report" %in% args) {
    a <- mosg_rows()
    print(as.data.frame(a[, c("awardee", "amount", "recipient_type", "distributed_to_hospital",
                              "cms_approval", "determination_confidence", "ccn")]), row.names = FALSE)
  }
  if (!length(args)) message("Usage: --validate | --build | --report")
}
