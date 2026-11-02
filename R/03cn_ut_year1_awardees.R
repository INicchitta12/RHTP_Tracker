#!/usr/bin/env Rscript
# 03cn_ut_year1_awardees.R ------------------------------------------------------
#
# UTAH -- DHHS'S "RHTP AWARDEE ANNOUNCEMENT" (a Google Doc linked from
# dhhs.utah.gov/ruralhealth/, "View the Awardee Announcement here."; page
# Last-Modified 2026-10-29). 40 PRICED FIRST-TIER LINES, $192,939,906.92, PLUS
# ONE UNNAMED CLASS ("73 Rural Clinical Preceptors", $156,000.00): 41 ROWS,
# $193,095,906.92. Session 112.
#
# WHAT THE ROWS ARE: INTENTS. The document's own first sentence:
#   "The Utah Department of Health and Human Services (DHHS) is preparing to
#    formally announce the grant awardees for the Rural Health Transformation
#    Program (RHTP), supported by the $195,743,566 first-year award from CMS."
# "Preparing to formally announce" is not an award, so validation_source_type
# = NOTICE_OF_INTENT_TO_AWARD, amount_confirmed = No and AMOUNT_PRELIMINARY on
# every row (California's and Texas's intent coding). The document is undated;
# announcement_date carries the linking page's Last-Modified (2026-10-29).
#
# NO PRINTED TOTAL. The document prints no total for its lines; the assertion
# is the 40 "Amount:" lines summing to $192,939,906.92 and the one "Year 1
# Award:" line at $156,000.00, both THIS FILE'S SUMS, to the cent.
#
# §0.2: "$195,743,566 first-year award from CMS" is Utah's ALLOTMENT (anchor
# $195,743,566, to the dollar), Tier 1, asserted by machine below. It is not a
# pool and is in no numeric column. The page also says "CMS has officially
# reported that Utah has successfully demonstrated obligation for 100% of its
# Year 1 RHTP funding": an OBLIGATION statement (standing rules, session 97),
# never an award figure.
#
# TYPING. Every row is in UT_HAND below, keyed on the exact awardee string (and
# the amount where one string carries two codings), each with its sentence;
# CMS UT Hospital / FQHC / RHC Enrollment (federal_records/2026-11-02/) is
# asserted for every CCN or FQHC bridge used. A row the hand table does not
# cover STOPS the build.
#   * "[Fiscal Agent & Open Subgrant Administrator]" STATE AGENCIES (UDAF,
#     USBE, UDOT, USHE x2, DPS, UETN x2), plus DEQ and the Utah Geospatial
#     Resource Center: STATE_AGENCY / NON_HOSPITAL. Their subgrants are Tier 2
#     pools whose recipients are not named (session-112 instruction).
#   * Hospitals on CMS UT enrolment: Uintah Basin Medical Center (460019),
#     Gunnison Valley Hospital (CAH 461306), Moab Valley Healthcare (CAH
#     461302, LOW: its contact is the Moab Free Health Clinic's), University of
#     Utah (460009; ACADEMIC_HEALTH_CENTER, §10.2's enrolled-operator row).
#   * Intermountain Health Center (IHC), two lines: a SYSTEM PARENT (owner
#     rulings: Vandalia, Sanford/Avera, Guthrie, St. Luke's), LOW,
#     GENERAL_KNOWLEDGE, no CCN.
#   * Utah Hospital Association, RISE 2.5 ($9,891,739): §7's association rule
#     -- "Allocates formula-based recruitment and retention subawards across
#     21 rural Critical Access and Prospective Payment System hospitals" --
#     a hospitals-only class, administered to hospitals: PASS_THROUGH_DESIGNATED,
#     POOL_UNNAMED_HOSPITALS (it names no hospital), ICAHN's shape.
#   * Utah Hospital Association, SPRINT ($38,300,000): "capital grants for
#     rural facilities" -- not a hospitals-only class (§0.3):
#     PASS_THROUGH_UNRESOLVED, Unclear, no bucket.
#   * Utah Rural Independent Hospital Network ($750,000): names its nine
#     hospitals and delivers SERVICES to them ("shared payer dashboards, denial
#     management, ..."): §10.2's GHA/AHHA negative, IN_KIND_BENEFIT, No,
#     hospital_benefiting = Yes.
#   * Utah Health Information Network ($3,000,000): "distributes
#     non-competitive funding ... to connect rural hospitals, clinics, and
#     tribal health entities" -- hospitals among others (§0.3):
#     PASS_THROUGH_UNRESOLVED, Unclear.
#
# Usage:
#   Rscript R/03cn_ut_year1_awardees.R --validate   assertions, offline
#   Rscript R/03cn_ut_year1_awardees.R --build      write ut_year1_awardees.csv
#   Rscript R/03cn_ut_year1_awardees.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

UTR_STATE <- "UT"
UTR_DIR   <- file.path("data", "evidence", "recheck", "2026-11-02", "UT")
UTR_FILE  <- file.path(UTR_DIR, "2026-11-02_ut_dhhs_rhtp_awardee_announcement_gdoc.txt")
UTR_PDF   <- file.path(UTR_DIR, "2026-11-02_ut_dhhs_rhtp_awardee_announcement_gdoc.pdf")
UTR_PAGE  <- file.path(UTR_DIR, "2026-11-02_ut_dhhs_ruralhealth_page.html")
UTR_UHA   <- file.path(UTR_DIR, "2026-11-02_ut_uha_rhtp_page_script_stripped.html")
UTR_SHA   <- "178149083c6db6c931792d16b2da636719d7decf29ed2fa768089afe502c685b"
UTR_URL   <- "https://docs.google.com/document/d/1IDrbHOZTIIzUEtvlQXfC7RHPO0dhJktxW0Lkm52mt1M/"
UTR_TITLE <- paste0("Utah DHHS, 'RHTP Awardee Announcement' (Google Doc linked from ",
                    "https://dhhs.utah.gov/ruralhealth/ as 'View the Awardee Announcement here.'; ",
                    "page Last-Modified 2026-10-29)")
UTR_DATE  <- as.Date("2026-10-29")
UTR_OUT   <- "data/reference/ut_year1_awardees.csv"
UTR_PRICED_LINES <- 40L
UTR_PRICED_TOTAL <- 192939906.92
UTR_CLASS_TOTAL  <- 156000.00
UTR_ROWS  <- 41L
UTR_ALLOTMENT_SENTENCE <- "supported by the $195,743,566 first-year award from CMS"
UTR_INTENT_SENTENCE <- "is preparing to formally announce the grant awardees"
UTR_OBLIGATION_SENTENCE <- paste0("CMS has officially reported that Utah has successfully demonstrated ",
                                  "obligation for 100% of its Year 1 RHTP funding")
UTR_FED <- c(
  HOSPITAL = file.path("data", "evidence", "federal_records", "2026-11-02", "cms_hosp_enrollments_UT.json"),
  FQHC     = file.path("data", "evidence", "federal_records", "2026-11-02", "cms_fqhc_enrollments_UT.json"),
  RHC      = file.path("data", "evidence", "federal_records", "2026-11-02", "cms_rhc_enrollments_UT.json"))

UTR_STATED_COUNTS <- tibble::tribble(
  ~heading, ~n, ~sentence,
  "RISE 2.5: Recruit and Retain - Hospitals", 4L, "Four (4) organizations were selected to serve as fiscal agents",
  "SHIFT 3.2: Rural Health Provider Networks", 5L, "Five (5) organizations were selected",
  "SHIFT 3.4: New Models of Care", 11L, "Eleven (11) organizations were selected")

UTR_INITIATIVE_RE <-"^(PATH|RISE|SHIFT|FAST|LIFT|SPRINT|LINCS) Initiative$|^Independent Contracts$"
UTR_HEADING_RE <- paste0("^(PATH|RISE|SHIFT|FAST|LIFT|SPRINT|LINCS) [0-9]|",
                         "^Independent RHTP Program Performance Monitoring|^Geospatial Mapping$")

# -- reading --------------------------------------------------------------------

utr_lines <- function(path = here::here(UTR_FILE)) {
  x <- readr::read_lines(path, progress = FALSE)
  x <- sub("^﻿", "", x)
  stringr::str_squish(gsub("\r", "", x, fixed = TRUE))
}

#' One row per "Awardee:" block, in document order.
utr_read <- function(x = utr_lines()) {
  aw <- which(grepl("^Awardee:", x))
  initiative <- NA_character_; heading <- NA_character_
  ini_at <- which(grepl(UTR_INITIATIVE_RE, x))
  hd_at  <- which(grepl(UTR_HEADING_RE, x))
  out <- lapply(seq_along(aw), function(k) {
    i <- aw[k]
    end <- if (k < length(aw)) aw[k + 1] - 1L else length(x)
    blk <- x[i:end]
    amt_line <- blk[grepl("^(Amount|Year 1 Award):", blk)]
    if (length(amt_line) != 1L) stop("[UT roster] awardee block at line ", i, " has ",
                                     length(amt_line), " amount lines.", call. = FALSE)
    scope <- blk[grepl("^Project Scope:", blk)]
    tibble::tibble(
      doc_line = i,
      initiative = sub(" Initiative$", "", x[max(ini_at[ini_at < i])]),
      heading = x[max(hd_at[hd_at < i])],
      awardee = stringr::str_squish(sub("^Awardee:", "", x[i])),
      fiscal_agent_tag = any(blk == "[Fiscal Agent & Open Subgrant Administrator]"),
      amount_label = sub(":.*$", "", amt_line),
      amount = round(as.numeric(gsub("[^0-9.]", "", sub("^[^:]*:", "", amt_line))), 2),
      project_scope = if (length(scope)) stringr::str_squish(sub("^Project Scope:", "", scope[1])) else NA_character_)
  })
  dplyr::bind_rows(out)
}

utr_assert_roster <- function(d = utr_read(), x = utr_lines()) {
  got <- digest::digest(file = here::here(UTR_FILE), algo = "sha256")
  if (!identical(got, UTR_SHA)) stop("[UT roster] the archived text is not the manifest's bytes.", call. = FALSE)
  if (nrow(d) != UTR_ROWS) stop("[UT roster] ", nrow(d), " awardee blocks, not 41.", call. = FALSE)
  pr <- d[d$amount_label == "Amount", ]
  cl <- d[d$amount_label == "Year 1 Award", ]
  if (nrow(pr) != UTR_PRICED_LINES) stop("[UT roster] ", nrow(pr), " 'Amount:' lines, not 40.", call. = FALSE)
  if (abs(sum(pr$amount) - UTR_PRICED_TOTAL) > 0.005) {
    stop("[UT roster] the 40 lines sum to $", format(sum(pr$amount), nsmall = 2, big.mark = ","),
         ", not $192,939,906.92.", call. = FALSE)
  }
  if (nrow(cl) != 1L || cl$awardee != "73 Rural Clinical Preceptors" || abs(cl$amount - UTR_CLASS_TOTAL) > 0.005) {
    stop("[UT roster] the preceptor class line moved.", call. = FALSE)
  }
  if (anyNA(d$amount) || anyNA(d$heading) || anyNA(d$initiative)) stop("[UT roster] a block lost its amount or heading.", call. = FALSE)
  # The document's own counts: "Four (4) organizations", "Five (5)", "Eleven (11)".
  for (k in seq_len(nrow(UTR_STATED_COUNTS))) {
    n <- sum(d$heading == UTR_STATED_COUNTS$heading[k])
    if (n != UTR_STATED_COUNTS$n[k] || !grepl(UTR_STATED_COUNTS$sentence[k], paste(x, collapse = " "), fixed = TRUE)) {
      stop("[UT roster] '", UTR_STATED_COUNTS$heading[k], "' holds ", n, " awardees against the document's stated ",
           UTR_STATED_COUNTS$n[k], ".", call. = FALSE)
    }
  }
  # No printed total: a "Total" line appearing means the document changed.
  if (any(grepl("^Total", x, ignore.case = TRUE))) stop("[UT roster] the document now prints a total: read it.", call. = FALSE)
  # The intent sentence and the allotment (Tier 1, never a pool).
  doc <- paste(x, collapse = " ")
  for (s in c(UTR_INTENT_SENTENCE, UTR_ALLOTMENT_SENTENCE)) {
    if (!grepl(s, doc, fixed = TRUE)) stop("[UT roster] the document no longer says '", s, "'.", call. = FALSE)
  }
  rhtp_assert_footer_not_allotment(195743566, UTR_STATE, "STATE_ALLOTMENT",
                                   label = "UT announcement's 'first-year award from CMS'")
  invisible(TRUE)
}

utr_page_text <- function(path = here::here(UTR_PAGE)) {
  stringr::str_squish(rvest::html_text2(xml2::read_html(path)))
}

# -- federal records --------------------------------------------------------------

utr_federal <- function() {
  dplyr::bind_rows(lapply(names(UTR_FED), function(k) {
    j <- jsonlite::fromJSON(here::here(UTR_FED[[k]]))
    tibble::tibble(kind = k, ccn = as.character(j$CCN), org = j$`ORGANIZATION NAME`,
                   dba = j$`DOING BUSINESS AS NAME`, city = j$CITY, ptype = j$`PROVIDER TYPE TEXT`)
  }))
}

# Every enrolment record a hand read relies on: (kind, ccn, org) must be in the
# archived file, or the build stops.
UTR_FED_RELIED <- tibble::tribble(
  ~kind,      ~ccn,     ~org,
  "HOSPITAL", "460019", "UINTAH BASIN MEDICAL CENTER",
  "HOSPITAL", "461306", "GUNNISON VALLEY HOSPITAL",
  "HOSPITAL", "461302", "MOAB VALLEY HEALTHCARE, INC.",
  "HOSPITAL", "460009", "UNIVERSITY OF UTAH",
  "HOSPITAL", "460001", "IHC HEALTH SERVICES INC",
  "FQHC",     "461847", "COMMUNITY HEALTH CENTERS INC",
  "FQHC",     "461821", "WAYNE COMMUNITY HEALTH CENTERS, INC.",
  "FQHC",     "461833", "UTAH NAVAJO HEALTH SYSTEM INCORPORATED")

utr_assert_federal <- function(f = utr_federal()) {
  k <- paste(f$kind, f$ccn, f$org)
  miss <- UTR_FED_RELIED[!paste(UTR_FED_RELIED$kind, UTR_FED_RELIED$ccn, UTR_FED_RELIED$org) %in% k, ]
  if (nrow(miss)) stop("[UT roster] enrolment records relied on are not in the archive: ",
                       paste(miss$org, collapse = "; "), call. = FALSE)
  # Moab Free Health Clinic and the University of North Carolina are on no
  # UT enrolment file (they are typed off it).
  for (s in c("MOAB FREE", "NORTH CAROLINA")) {
    if (any(grepl(s, c(f$org, f$dba), fixed = TRUE))) stop("[UT roster] '", s, "' is now enrolled: re-read.", call. = FALSE)
  }
  invisible(TRUE)
}

# -- typing ---------------------------------------------------------------------

UTR_STATE_AGENCY <- paste0(
  "A STATE AGENCY designated '[Fiscal Agent & Open Subgrant Administrator]': the document says such ",
  "agencies 'launch competitive funding calls or solicit participation interest and are open to all ",
  "eligible rural applicants'. Its subgrants are Tier 2 pools whose recipients are not named (session-112 ",
  "instruction): STATE_AGENCY, NON_HOSPITAL. A hospital that later receives a subgrant is a second-tier row ",
  "for that agency's own roster, never this one.")
UTR_PARENT <- paste0(
  "SYSTEM PARENT, LOW, GENERAL_KNOWLEDGE (owner rulings: Vandalia, Sanford/Avera, Guthrie, St. Luke's): ",
  "'Intermountain Health Center (IHC)', contact osp@imail.org (Intermountain Health's domain). The string is ",
  "not an enrolled name; the enrolled legal entity is IHC HEALTH SERVICES INC, which holds some twenty CMS UT ",
  "hospital CCNs (460001 Utah Valley Hospital and others, incl. CAHs 461300, 461301, 461303, 461307), so no ",
  "CCN goes on the row. Subtractable by basis_type. §0.3a: the CHW activity does not decide it.")
UTR_FALLBACK <- paste0("The document states no form and no CMS UT Hospital, FQHC or RHC enrolment carries ",
                       "the string (§8's standing fallback, RECIPIENT_TYPE_INFERRED). Not a hospital.")

# key: exact awardee string; amt: NA = every line of that string.
UT_HAND <- tibble::tribble(
  ~key, ~amt, ~recipient_type, ~basis_type, ~confidence, ~ccn, ~flow, ~attribution, ~dist, ~subtype, ~flag, ~why,
  "Utah Department of Agriculture and Food (UDAF)", NA, "STATE_AGENCY", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, NA,
  paste0(UTR_STATE_AGENCY, " Its class: 'rural food producers, processors, cold storage facilities, and slaughterhouses'."),
  "Utah State Board of Education (USBE)", NA, "STATE_AGENCY", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, NA,
  paste0(UTR_STATE_AGENCY, " Its class: 'rural Local Education Agencies (LEAs) in 3rd-6th class counties'."),
  "Utah Department of Transportation (UDOT)", NA, "STATE_AGENCY", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, NA,
  paste0(UTR_STATE_AGENCY, " Its scope is built-environment active transportation infrastructure and non-emergency transportation."),
  "Utah System of Higher Education (USHE) Talent Ready Utah (TRU)", NA, "STATE_AGENCY", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, NA,
  paste0(UTR_STATE_AGENCY, " Its class: 'K-12 school districts and higher education institutions with rural healthcare employers' ",
         "(hospitals may be among the employers; nobody is named, §0.3)."),
  "Utah System of Higher Education (USHE)", NA, "STATE_AGENCY", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, NA,
  paste0(UTR_STATE_AGENCY, " Its class: 'technical colleges, universities, and rural healthcare employers' (hospitals may be ",
         "among the employers; nobody is named, §0.3)."),
  "Department of Public Safety (DPS)", NA, "STATE_AGENCY", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, NA,
  paste0(UTR_STATE_AGENCY, " Its class: 'rural EMS agencies' (and EMT-to-Paramedic scholarships, Tribal EMS)."),
  "Utah Education and Telehealth Network (UETN)", NA, "STATE_AGENCY", "GENERAL_KNOWLEDGE", "LOW", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, NA,
  paste0(UTR_STATE_AGENCY, " UETN is a state entity within Utah's public higher-education system (general knowledge; the ",
         "document gives it the fiscal-agent tag). Its class is mixed -- LIFT: 'rural hospitals, RHCs, CHCs, schools, and ",
         "senior centers'; SPRINT: 'rural EHR modernization ... cybersecurity ... clinical AI/virtual scribe ... ",
         "interoperability grants' -- so hospitals are AMONG the eligible and none is named (§0.3)."),
  "Department of Environmental Quality (DEQ)", NA, "STATE_AGENCY", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, NA,
  "A state department (the form is in the string), funding 'capital water treatment facility upgrades' for the Ukon drinking water system. Not a hospital.",
  "Utah Geospatial Resource Center", NA, "STATE_AGENCY", "GENERAL_KNOWLEDGE", "LOW", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, NA,
  "Utah's state GIS office (general knowledge), engaged for 'Geographic Information Systems (GIS)' analysis. Not a hospital.",
  "Comagine", NA, "NONPROFIT_CBO", NA, "LOW", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, "RECIPIENT_TYPE_INFERRED",
  paste0(UTR_FALLBACK, " Both lines describe services and participation (a Community Care Hub; value-based care ",
         "recruitment, 'Comagine is currently soliciting interest'), and no sentence sends money to a hospital."),
  "Community Health Center (CHC)", NA, "FQHC_OR_RHC", "ORG_WEBSITE", "LOW", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, NA,
  paste0("HAND-READ BRIDGE: the project is at 'Tremonton (Bear River) and Brigham City clinics'; CMS UT FQHC Enrollment ",
         "carries COMMUNITY HEALTH CENTERS INC with a Tremonton site (461847). The string is singular and generic, so LOW. ",
         "An FQHC, not a hospital."),
  "Moab Valley Healthcare (MVH)", NA, "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "461302", "DIRECT", "NAMED_HOSPITAL", "Yes", NA, NA,
  paste0("ENROLLED HOSPITAL OPERATOR: 'Moab Valley Healthcare' is the legal name (less ', INC.') of MOAB VALLEY HEALTHCARE, ",
         "INC., which CMS UT Hospital Enrollment carries dba MOAB REGIONAL HOSPITAL, PART A PROVIDER - CRITICAL ACCESS ",
         "HOSPITAL (461302, Moab). LOW, NOT MEDIUM, BECAUSE THE DOCUMENT CONTRADICTS ITSELF: the line's contact is ",
         "'www.moabfreehealthclinic.org ... director@moabfreehealthclinic.org', the Moab Free Health Clinic's, and the scope ",
         "is a 'One Door' system 'uniting Moab Regional Hospital, the Moab Recovery Center, and Moab Free Health Clinic'. ",
         "The awardee field names the hospital's operator and §0.3a codes the recipient field, so the row is a hospital ",
         "row; if DHHS's contract is with the free clinic, it is not (owner question)."),
  "Wayne Community Healthcare (WCH)", NA, "FQHC_OR_RHC", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, NA,
  paste0("An FQHC: the line itself says 'across 3 independent FQHCs (Wayne CHC, Creek Valley Health Clinic, Green River ",
         "Medical Center)', and CMS UT FQHC Enrollment carries WAYNE COMMUNITY HEALTH CENTERS, INC. (461821). 'Green River ",
         "Medical Center' is an FQHC (GREEN RIVER MEDICAL CENTER INC, 461804), not a hospital. Not a hospital."),
  "University of North Carolina", NA, "UNIVERSITY_OR_AHC", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, NA,
  paste0("A university (contact info@stategme.org / shepsgme.org, the Sheps Center), delivering a GME strategic plan 'with ",
         "Manatt Health'. Not University of North Carolina Hospitals: §10.2 forbids matching a prefix of an enrolled name, ",
         "and the enrolled body is out of state anyway. Not a hospital."),
  "73 Rural Clinical Preceptors", NA, "NOT_YET_NAMED", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, NA,
  paste0("A CLASS OF INDIVIDUALS, NOT AN ORGANISATION: 'direct stipends ($1K-$5K) for 73 rural clinical preceptors (MDs, ",
         "DOs, APRNs, PAs)'. None is named; the recipients are clinicians, never hospitals. One row, never divided (§6.2)."),
  "Utah Hospital Association (UHA)", 9891739.00, "NONPROFIT_CBO", "STATE_SOURCE", "MEDIUM", NA, "PASS_THROUGH_DESIGNATED", "POOL_UNNAMED_HOSPITALS", "Yes", NA, NA,
  paste0("§7's HOSPITAL-ASSOCIATION ROW, ICAHN'S SHAPE. Under 'RISE 2.5: Recruit and Retain - Hospitals', the document's ",
         "own sentence: 'Allocates formula-based recruitment and retention subawards across 21 rural Critical Access and ",
         "Prospective Payment System hospitals tied to 5-year rural service commitments. UHA is currently working directly ",
         "with rural hospitals to administer this funding.' The class is hospitals only and the funds are administered TO ",
         "them, so PASS_THROUGH_DESIGNATED, Yes, intermediary UHA. No hospital is named, so POOL_UNNAMED_HOSPITALS, never ",
         "divided (§6.2). UHA's own RHTP page (archived) says the RISE 2.5 RFA is 'to inform Utah's 25 eligible Tier 1 ",
         "rural hospitals how to apply for funding as a subrecipient' (25 eligible vs the document's 21: recorded, not ",
         "resolved), and that the 'Utah Healthcare Education & Research Foundation, a 501(c)3 subsidiary of the Utah ",
         "Hospital Association, is administering four key activities'. The second-tier awards are NOT yet made (RFA ",
         "webinar 2026-11-02); the first-tier line is itself an intent."),
  "Utah Hospital Association (UHA)", 38300000.00, "NONPROFIT_CBO", "STATE_SOURCE", "MEDIUM", NA, "PASS_THROUGH_UNRESOLVED", "NOT_HOSPITAL", "Unclear", NA, "FLOW_UNRESOLVED_HOSPITAL_AFFILIATED",
  paste0("§0.3: ELIGIBILITY IS NOT RECEIPT, AND THE CLASS IS NOT HOSPITALS ONLY. The document's own sentence (SPRINT 3-1, ",
         "4-2, 4-3): 'Awards competitive capital grants for rural facilities to expand local service lines (ex. dialysis, ",
         "cancer, OB, tele-ICU), upgrade diagnostic equipment, minor capital infrastructure renovations, optimize revenue ",
         "cycle management, and pilot per-diem specialist coverage.' 'Rural facilities' is not hospitals-only, and UHA's ",
         "own page (archived) states the class wider still: FAST 4.2 is 'to help rural hospitals, clinics, and other ",
         "eligible providers'; FAST 4.3 pays specialists 'at small rural hospitals and clinics'; SHIFT 3.1 includes 'rural ",
         "receiving centers offering 24/7 crisis stabilization'. A hospital association administering a pool with ",
         "hospitals AMONG the eligible and nobody named: PASS_THROUGH_UNRESOLVED, Unclear, no bucket. NOT promoted."),
  "Association for Utah Health (AUCH)", NA, "NONPROFIT_CBO", "GENERAL_KNOWLEDGE", "LOW", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, NA,
  paste0("Utah's primary care association of community health centres (general knowledge; the document's lines are ",
         "'across Utah's 11 rural FQHC organizations', 'across all rural FQHC organizations', 'across rural FQHCs'). ",
         "Its pass-throughs reach FQHCs, never hospitals. Not a hospital."),
  "Utah Health Care Association (UTHCA)", NA, "NONPROFIT_CBO", "GENERAL_KNOWLEDGE", "LOW", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, NA,
  paste0("A long-term-care trade association (general knowledge); the line's class is 'eligible rural Skilled Nursing ",
         "Facilities (SNFs)'. Not a hospital, and not a hospital association."),
  "Rural Health Association of Utah (RHAU)", NA, "NONPROFIT_CBO", "GENERAL_KNOWLEDGE", "LOW", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, NA,
  paste0("A rural-health membership association (general knowledge). Its two lines reach 'clinicians in certified Rural ",
         "Health Clinics and independent rural practices' and 'rural health clinics' -- not hospitals (a hospital-owned ",
         "RHC's clinician may be among them; none is named, §0.3). Not a hospital."),
  "Utah Rural Independent Hospital Network", NA, "NONPROFIT_CBO", "STATE_SOURCE", "MEDIUM", NA, "IN_KIND_BENEFIT", "NOT_HOSPITAL", "No", NA, NA,
  paste0("§10.2's GHA/AHHA NEGATIVE: A NETWORK OF HOSPITALS THAT DELIVERS SERVICES, NOT MONEY. The document's own ",
         "sentence: 'Supports the Rural 9 Independent Hospital Network (Beaver Valley, Blue Mountain, Central Valley, ",
         "Gunnison, Kane, Milford, Moab, San Juan, Uintah Basin) with shared payer dashboards, denial management, patient ",
         "outmigration analytics, and maternal/OB gap assessments.' It NAMES nine hospitals and administers nothing to ",
         "them: the network delivers tools and analyses. IN_KIND_BENEFIT, No, hospital_benefiting = Yes; no bucket. (Its ",
         "contact is UHA's. Nevada's NRHP service lines were ruled POOL_NAMED by the owner, flag ASSOCIATION_SERVICE; this ",
         "row has no such ruling.)"),
  "Intermountain Health Center (IHC)", NA, "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", NA, "DIRECT", "NAMED_HOSPITAL", "Yes", NA, NA,
  UTR_PARENT,
  "University of Utah", NA, "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "460009", "DIRECT", "NAMED_HOSPITAL", "Yes", "ACADEMIC_HEALTH_CENTER", NA,
  paste0("§10.2's ENROLLED-HOSPITAL-OPERATOR ROW (UAMS precedent): 'University of Utah' is EXACTLY the ORGANIZATION NAME ",
         "on CMS UT Hospital Enrollment, dba UNIVERSITY OF UTAH HOSPITALS AND CLINICS, PART A PROVIDER - HOSPITAL ",
         "(460009, Salt Lake City). The awardee's legal entity is the hospital's, so HOSPITAL_OR_SYSTEM, subtype ",
         "ACADEMIC_HEALTH_CENTER, MEDIUM (EXACT_LEGAL_NAME). The activity (the Utah System for Trauma and Emergency ",
         "Networks) does not decide it (§0.3a); contact clinicalops@med.utah.edu."),
  "Grand County", NA, "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, NA,
  "A county government (the form is in the string), operating a non-emergency medical transportation dispatch system. Not a hospital.",
  "Moab Free Health Clinic", NA, "OTHER", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, NA,
  paste0("DETERMINED FORM: a free clinic (the form is in the string); on no CMS UT Hospital, FQHC or RHC enrolment. Its ",
         "line names Moab Regional Hospital only as a partner ('ED diversion pathways with Moab Regional Hospital'). Not a hospital."),
  "Northwest Band of the Shoshone Nation (NWBSN)", NA, "TRIBAL_ORG", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, NA,
  "A federally recognised tribe (the form is in the string). Not a hospital.",
  "Uintah Basin Medical Center (UBMC)", NA, "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "460019", "DIRECT", "NAMED_HOSPITAL", "Yes", NA, NA,
  paste0("EXACT federal record: 'Uintah Basin Medical Center' (the parenthesised abbreviation set aside) is the ORGANIZATION ",
         "NAME on CMS UT Hospital Enrollment, PART A PROVIDER - HOSPITAL (460019, Roosevelt). MEDIUM. The clinic-based ",
         "specialty hub does not change the recipient (§0.3a)."),
  "Utah State University (USU)", NA, "UNIVERSITY_OR_AHC", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, NA,
  "A public university (USU Extension). Not a hospital.",
  "Building Blocks", NA, "NONPROFIT_CBO", NA, "LOW", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, "RECIPIENT_TYPE_INFERRED",
  UTR_FALLBACK,
  "Utah Navajo Health System (UNHS)", NA, "FQHC_OR_RHC", "ORG_WEBSITE", "MEDIUM", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, NA,
  paste0("EXACT federal record: CMS UT FQHC Enrollment carries UTAH NAVAJO HEALTH SYSTEM INCORPORATED (461833 Blanding, ",
         "461818 Montezuma Creek, 461835 Monument Valley). An FQHC, not a hospital."),
  "Gunnison Valley Hospital", NA, "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "461306", "DIRECT", "NAMED_HOSPITAL", "Yes", NA, NA,
  paste0("EXACT federal record: CMS UT Hospital Enrollment carries GUNNISON VALLEY HOSPITAL, PART A PROVIDER - CRITICAL ",
         "ACCESS HOSPITAL (461306, Gunnison; 46Z306 is its swing-bed unit). MEDIUM. The Connected Care Hub does not change ",
         "the recipient (§0.3a)."),
  "U of U Physician Assistant Program (UPAP)/Switchpoint", NA, "UNIVERSITY_OR_AHC", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, "MULTI_RECIPIENT_FIELD",
  paste0("TWO RECIPIENTS IN ONE FIELD (§6.2), NEITHER A HOSPITAL: a university PROGRAMME string (owner ruling (a), ",
         "session 110: a school, department or programme string is not the enrolled University of Utah) and Switchpoint, ",
         "a shelter operator ('Switchpoint's Red Hills Stable Living Facility'). Never divided. Not a hospital."),
  "Utah Health Information Network (UHIN)", NA, "NONPROFIT_CBO", NA, "LOW", NA, "PASS_THROUGH_UNRESOLVED", "NOT_HOSPITAL", "Unclear", NA, "RECIPIENT_TYPE_INFERRED",
  paste0("§0.3: HOSPITALS AMONG OTHERS. The document's own sentence: 'Conducts a rural provider Health Information ",
         "Exchange (HIE) readiness assessment and distributes non-competitive funding and technical assistance to connect ",
         "rural hospitals, clinics, and tribal health entities to the state HIE for bidirectional data exchange.' An ",
         "intermediary distributing to a class that includes hospitals, recipients not named: PASS_THROUGH_UNRESOLVED, ",
         "Unclear, no bucket. Its form is not stated (§8's standing fallback)."),
  "HK Consulting", NA, "VENDOR_OR_CONTRACTOR", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, NA,
  "A consulting firm (the form is in the string) building a semantic data platform. Not a hospital.",
  "RTI International", NA, "VENDOR_OR_CONTRACTOR", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL", "NOT_HOSPITAL", "No", NA, NA,
  "Under 'Independent Contracts': 'the independent state data evaluation contractor'. Not a hospital.")

utr_hand_row <- function(awardee, amount) {
  h <- UT_HAND[UT_HAND$key == awardee & (is.na(UT_HAND$amt) | abs(UT_HAND$amt - amount) < 0.005), ]
  if (nrow(h) != 1L) stop("[UT roster] ", nrow(h), " hand reads cover '", awardee, "' at $", amount,
                          ": every row must have exactly one.", call. = FALSE)
  h
}

#' The award file.
ut_year1_awardees <- function(d = utr_read()) {
  cls <- rhtp_classify_recipient_type(d$awardee, UTR_STATE)
  h <- dplyr::bind_rows(lapply(seq_len(nrow(d)), function(i) utr_hand_row(d$awardee[i], d$amount[i])))
  intent <- paste0(" AN INTENT, NOT AN AWARD: DHHS 'is preparing to formally announce the grant awardees'.")
  flag <- ifelse(is.na(h$flag), "AMOUNT_PRELIMINARY", paste0("AMOUNT_PRELIMINARY;", h$flag))
  hosp_benefit <- dplyr::case_when(
    h$dist == "Yes" ~ "Yes",
    h$flow == "IN_KIND_BENEFIT" ~ "Yes",
    TRUE ~ "Unclear")
  tibble::tibble(
    state = UTR_STATE,
    row_no = seq_len(nrow(d)),
    awardee = d$awardee,
    amount = d$amount,
    recipient_type = h$recipient_type,
    distributed_to_hospital = h$dist,
    note = paste0(d$initiative, " Initiative, '", d$heading, "', on DHHS's RHTP Awardee Announcement",
                  ifelse(d$fiscal_agent_tag, " [Fiscal Agent & Open Subgrant Administrator]", ""), "."),
    recipient_confirmed = ifelse(h$recipient_type == "NOT_YET_NAMED", "Unclear", "Yes"),
    amount_confirmed = "No",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = UTR_TITLE,
    state_source_url = UTR_URL,
    validation_source_type = "NOTICE_OF_INTENT_TO_AWARD",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03cn_ut_year1_awardees.R",
    ccn = h$ccn,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    roster_line = d$doc_line,
    roster_type = d$initiative,
    recipient_type_source = paste0("TYPED (session 112, HAND-READ): ", h$why, " Classifier said ",
                                   cls$recipient_type, "/", rhtp_confidence_ceiling(cls$determination_confidence), "."),
    determination_confidence = rhtp_confidence_ceiling(h$confidence, h$ccn),
    flag_reason = flag,
    award_pool = d$heading,
    budget_period = "Budget Period 1",
    flow_type = h$flow,
    hospital_benefiting = hosp_benefit,
    hospital_attribution = h$attribution,
    intermediary_name = ifelse(grepl("^PASS_THROUGH", h$flow), d$awardee, NA_character_),
    determination_basis = paste0("§10.2 ", h$flow, ": ", h$why,
                                 ifelse(h$flow == "DIRECT", " §0.3a: the recipient is a hospital or health system whatever the activity.", ""),
                                 intent),
    amount_basis = paste0("The line's own '", d$amount_label, "', exact as printed: a figure DHHS is 'preparing to ",
                          "formally announce' (AMOUNT_PRELIMINARY). The document prints no total; its 40 'Amount:' ",
                          "lines sum to $192,939,906.92 and the one 'Year 1 Award:' line (73 preceptors) is $156,000.00, ",
                          "together $193,095,906.92 against Utah's $195,743,566 allotment (98.6%)."),
    basis_type = h$basis_type,
    recipient_subtype = h$subtype,
    round_amount = NA_real_,
    announcement_date = UTR_DATE,
    source_archive_path = UTR_FILE,
    fiscal_agent_tag = d$fiscal_agent_tag,
    project_scope = d$project_scope)
}

utr_assert_typing <- function(a = ut_year1_awardees()) {
  y <- a[a$distributed_to_hospital == "Yes", ]
  dir_ok <- y$recipient_type == "HOSPITAL_OR_SYSTEM" & y$flow_type == "DIRECT" & y$hospital_attribution == "NAMED_HOSPITAL"
  pt_ok <- y$flow_type == "PASS_THROUGH_DESIGNATED" & !is.na(y$intermediary_name) &
    y$hospital_attribution %in% c("POOL_UNNAMED_HOSPITALS", "POOL_NAMED_HOSPITALS")
  if (!all(dir_ok | pt_ok)) stop("[UT roster] a Yes row is neither DIRECT-named nor a designated pool.", call. = FALSE)
  if (any(a$hospital_attribution != "NOT_HOSPITAL" & a$distributed_to_hospital != "Yes")) {
    stop("[UT roster] a bucketed row is not Yes.", call. = FALSE)
  }
  un <- a[a$distributed_to_hospital == "Unclear", ]
  if (nrow(un) != 2L ||
      !setequal(sprintf("%s|%.2f", un$awardee, un$amount),
                c("Utah Hospital Association (UHA)|38300000.00", "Utah Health Information Network (UHIN)|3000000.00"))) {
    stop("[UT roster] the Unclear rows are not UHA's capital line and UHIN.", call. = FALSE)
  }
  unused <- UT_HAND$key[!vapply(seq_len(nrow(UT_HAND)), function(i)
    any(a$awardee == UT_HAND$key[i] & (is.na(UT_HAND$amt[i]) | abs(a$amount - UT_HAND$amt[i]) < 0.005)), logical(1))]
  if (length(unused)) stop("[UT roster] hand reads match no line: ", paste(unused, collapse = "; "), call. = FALSE)
  if (!all(grepl("AMOUNT_PRELIMINARY", a$flag_reason, fixed = TRUE))) stop("[UT roster] an intent row lost AMOUNT_PRELIMINARY.", call. = FALSE)
  if (any(a$determination_confidence[a$basis_type %in% "GENERAL_KNOWLEDGE"] != "LOW")) {
    stop("[UT roster] a GENERAL_KNOWLEDGE row is not LOW (§0.4).", call. = FALSE)
  }
  rhtp_assert_high_has_ccn(a, "UT roster")
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital", "determination_confidence",
                "hospital_attribution", "basis_type", "recipient_subtype", "recipient_confirmed",
                "amount_confirmed", "hospital_benefiting", "extraction_method")) {
    bad <- setdiff(stats::na.omit(unique(a[[col]])), rhtp_vocabulary(col))
    if (length(bad)) stop("[UT roster] ", col, " outside §8: ", paste(bad, collapse = ", "), call. = FALSE)
  }
  if (length(setdiff(a$validation_source_type, rhtp_vocabulary("source_doc_type")))) {
    stop("[UT roster] validation_source_type outside §8.", call. = FALSE)
  }
  fl <- unlist(strsplit(stats::na.omit(a$flag_reason), ";"))
  if (length(setdiff(fl, rhtp_vocabulary("flag_reason")))) stop("[UT roster] flag_reason outside §8.", call. = FALSE)
  invisible(TRUE)
}

utr_validate <- function() {
  x <- utr_lines()
  d <- utr_read(x)
  utr_assert_roster(d, x)
  utr_assert_federal()
  pg <- utr_page_text()
  if (!grepl(UTR_OBLIGATION_SENTENCE, pg, fixed = TRUE)) stop("[UT roster] the page's obligation sentence moved.", call. = FALSE)
  a <- ut_year1_awardees(d)
  utr_assert_typing(a)
  invisible(a)
}

utr_fmt <- function(x) formatC(x, format = "f", digits = 2, big.mark = ",")

utr_build <- function() {
  a <- utr_validate()
  readr::write_csv(a, here::here(UTR_OUT), na = "")
  h <- a[a$hospital_attribution == "NAMED_HOSPITAL", ]
  message("[UT roster] wrote ", UTR_OUT, ": ", nrow(a), " rows, $", utr_fmt(sum(a$amount)),
          "; NAMED_HOSPITAL ", nrow(h), " / $", utr_fmt(sum(h$amount)), ".")
  invisible(a)
}

utr_report <- function(a = utr_validate()) {
  cat("\nUTAH -- DHHS RHTP Awardee Announcement (INTENTS)\n")
  cat(sprintf("  rows %d  $%s (40 priced lines $%s + preceptor class $%s)\n", nrow(a), utr_fmt(sum(a$amount)),
              utr_fmt(UTR_PRICED_TOTAL), utr_fmt(UTR_CLASS_TOTAL)))
  print(as.data.frame(a %>% dplyr::group_by(hospital_attribution, distributed_to_hospital, flow_type) %>%
                        dplyr::summarise(rows = dplyr::n(), amount = sum(amount), .groups = "drop")))
  invisible(a)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) { utr_validate(); message("[UT roster] all assertions pass.") }
  if ("--build" %in% args)    utr_build()
  if ("--report" %in% args)   utr_report()
  if (!length(intersect(args, c("--validate", "--build", "--report")))) {
    message("usage: Rscript R/03cn_ut_year1_awardees.R [--validate] [--build] [--report]")
  }
}
