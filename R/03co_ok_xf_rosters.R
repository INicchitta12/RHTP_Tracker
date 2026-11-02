#!/usr/bin/env Rscript
# 03co_ok_xf_rosters.R --------------------------------------------------------
#
# OKLAHOMA'S PRICED ROSTERS ON THE MOVED FUNDING RECIPIENTS PAGE. Session 112,
# pre-approved by the owner.
#
# On 2026-11-02 https://oklahoma.gov/health/rhtp/rhtp-funding-recipients.html
# answered HTTP 302 to https://oklahoma.gov/rhtp/rhtp-funding-recipients.html
# ("Last Modified on Oct 23, 2026"), whose body carries no roster: a dropdown
# loads one AEM experience fragment per programme. All 29 fragments are
# archived under data/evidence/recheck/2026-11-02/OK/fragments/ (MANIFEST in
# the parent directory). The rosters this repository already holds (R/03t,
# R/03bt, R/03cc) are on it at their extracted figures. FIVE PRICED ROSTERS
# ARE NEW, each its own file (the R/03bt pattern):
#
#   Lung Cancer Screening      11 lines x $170,304.00    ok_year1_lung_screening_awardees.csv
#   Telestroke Expansion I      1 line   $499,555.00     ok_year1_telestroke_awardees.csv
#   Closed-Loop Community Care  1 line   $830,400.00     ok_year1_closed_loop_awardees.csv
#   High School LPN "Grow Your Own" 5 x $31,166.00       ok_year1_grow_your_own_awardees.csv
#   Transportation Expansion   1 + 10 lines              ok_year1_transportation_awardees.csv
#
# The unpriced fragments (CHW Expansion, Rural Residency, School-Based Health,
# Rural Re-Location, the "pending" programmes) are NOT extracted here.
#
# LUNG CANCER SCREENING. "Funding Administrator: Oklahoma Hospital
# Association ... Funded through subrecipient agreement. Lung Cancer
# Screening Subrecipients:" and then each HOSPITAL with its own amount. OHA
# administers; the hospitals are the named, priced SUBRECIPIENTS, so §7's
# association row (a pool OHA holds) is NOT reached: each line is the
# hospital's own award, DIRECT, with OHA recorded in intermediary_name as the
# administrator. Typed on CMS OK Hospital Enrollments (federal_records/
# 2026-09-25): every OSDH string is a short form, so every bridge is a
# hand-read judgement, LOW, apart from Duncan Regional Hospital (the enrolled
# legal name less "Inc", MEDIUM). Three lines are marked "*Contract not
# finalized": INTENTS, AMOUNT_PRELIMINARY, NOTICE_OF_INTENT_TO_AWARD.
#   * "Jackson County Memorial Hospital & Harmon Memorial Hospital" is ONE
#     legal body: CMS enrols both under JACKSON COUNTY MEMORIAL HOSPITAL
#     AUTHORITY (370022 Altus, 371338 Hollis CAH). One recipient, one priced
#     line, so NAMED_HOSPITAL; no CCN on the row because it names two.
#   * The two "SSM Affiliates:" lines each price ONE amount across three or
#     four DIFFERENT enrolled legal bodies. §7 (session 105): a component
#     priced for named hospitals alone is a POOL_NAMED_HOSPITALS row, never
#     divided (§6.2) -- the CT Hartford HealthCare / VA VCU pair shape,
#     MULTI_RECIPIENT_FIELD.
#
# TELESTROKE. OUHSC, $499,555, "Funded through interagency agreement".
# UNIVERSITY_OR_AHC: OU's hospital enrols as OU MEDICINE INC (CCN 370093), a
# different legal body, so the enrolled-operator row does not reach it
# (R/03bt's OU Board of Regents precedent). The 15 "Participating Sites" are
# sites of OUHSC's network; the page says nothing about money reaching them,
# so they are NOT rows (§0.3; hospital_benefiting = Yes).
#
# CLOSED-LOOP. Findhelp, Inc., $830,400: a VENDOR whose licences reach
# "critical access hospitals, rural emergency hospitals, and FQHCs" --
# IN_KIND_BENEFIT (§10.2), No, hospital_benefiting = Yes. The seven Cohort 1
# hospitals are participants, not payees, and are NOT rows.
#
# GROW YOUR OWN. Five Career Technology centre campuses at $31,166.00 each,
# "Funded through interagency agreement" via CareerTech. Oklahoma technology
# centres are public school districts: SCHOOL_OR_DISTRICT.
#
# TRANSPORTATION. SWODA (the administrator) "is providing $206,778.07 in
# mileage reimbursement" -- SWODA's own programme spend, one row; and "The
# following 12 transit agencies were awarded funding for 20 vehicle
# purchases" lists TEN, priced ($2,054,080.90). The 12-vs-10 gap is recorded,
# not filled. None is a hospital.
#
# No fragment carries a CMS footer; the page's (OK's allotment) is Tier 1.
#
# Usage:
#   Rscript R/03co_ok_xf_rosters.R --validate | --build | --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))
source(here::here("R", "utils_page_watch.R"))

OKX_STATE  <- "OK"
OKX_URL    <- "https://oklahoma.gov/rhtp/rhtp-funding-recipients.html"
OKX_DIR    <- file.path("data", "evidence", "recheck", "2026-11-02", "OK")
OKX_FRAG   <- file.path(OKX_DIR, "fragments")
OKX_READ   <- as.Date("2026-11-02")
OKX_PAGE_MODIFIED <- as.Date("2026-10-23")
OKX_NOA    <- as.Date("2025-12-29")
OKX_HOSP_FED <- file.path("data", "evidence", "federal_records", "2026-09-25",
                          "cms_hosp_enrollments_OK.json")
OKX_OHA    <- "Oklahoma Hospital Association (Funding Administrator; the hospital is the named subrecipient)"

okx_csv <- function(kind) here::here("data", "reference",
                                     paste0("ok_year1_", kind, "_awardees.csv"))

OKX_ROSTERS <- tibble::tribble(
  ~kind,            ~slug,                                       ~label,                                    ~n,  ~total,
  "lung_screening", "lung-cancer-screening-program",             "Lung Cancer Screening Program",           11L, 1873344,
  "telestroke",     "telestroke-expansion-i",                    "Telestroke Expansion I",                   1L, 499555,
  "closed_loop",    "closed-loop-community-care-platform",       "Closed-Loop Community Care Platform",      1L, 830400,
  "grow_your_own",  "high-school-lpn-program----grow-your-own-", "High School LPN Program - \"Grow Your Own\"", 5L, 155830,
  "transportation", "transportation-expansion",                  "Transportation Expansion",                11L, 2260858.97)

okx_text <- function(slug) {
  f <- here::here(OKX_FRAG, paste0(slug, ".html"))
  t <- rvest::html_text2(xml2::read_html(f))
  t <- gsub("[​  ]", " ", t)
  stringr::str_squish(t)
}

# Each award line: kind, the line as printed (asserted verbatim on the
# archived fragment), the awardee string, the amount, and its typing.
#   enrol: "<ORG NAME>|<CCN>" on the archived CMS OK Hospital Enrollments.
OKX_LINES <- tibble::tribble(
  ~kind, ~line, ~awardee, ~amount, ~prelim, ~rtype, ~flow, ~dth, ~attr, ~basis, ~conf, ~ccn, ~match, ~enrol, ~why,
  # ---- Lung Cancer Screening ------------------------------------------------
  "lung_screening", "Mercy Ada, $170,304.00", "Mercy Ada", 170304, FALSE,
    "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes", "NAMED_HOSPITAL", "GENERAL_KNOWLEDGE", "LOW", "370020", "LEGAL_NAME_TRUNCATED",
    "MERCY HOSPITAL ADA INC|370020",
    "HAND-READ BRIDGE: OSDH prints the short form 'Mercy Ada'; the one enrolled Mercy hospital in Ada is MERCY HOSPITAL ADA INC (PART A PROVIDER - HOSPITAL, CCN 370020).",
  "lung_screening", "Mercy Ardmore, $170,304.00", "Mercy Ardmore", 170304, FALSE,
    "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes", "NAMED_HOSPITAL", "GENERAL_KNOWLEDGE", "LOW", "370047", "LEGAL_NAME_TRUNCATED",
    "MERCY HOSPITAL ARDMORE INC|370047",
    "HAND-READ BRIDGE: 'Mercy Ardmore' is the short form of MERCY HOSPITAL ARDMORE INC (PART A PROVIDER - HOSPITAL, CCN 370047), the one enrolled Mercy hospital in Ardmore.",
  "lung_screening", "Saint Francis Muskogee, $170,304.00", "Saint Francis Muskogee", 170304, FALSE,
    "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes", "NAMED_HOSPITAL", "GENERAL_KNOWLEDGE", "LOW", "370025", "LEGAL_NAME_TRUNCATED",
    "SAINT FRANCIS HOSPITAL MUSKOGEE INC|370025",
    "HAND-READ BRIDGE: 'Saint Francis Muskogee' is the short form of SAINT FRANCIS HOSPITAL MUSKOGEE INC (PART A PROVIDER - HOSPITAL, CCN 370025), the one enrolled Saint Francis hospital in Muskogee.",
  "lung_screening", "Chickasaw Nation Medical Center, $170,304.00", "Chickasaw Nation Medical Center", 170304, FALSE,
    "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes", "NAMED_HOSPITAL", "GENERAL_KNOWLEDGE", "LOW", "370180", "DBA_OF_LEGAL_ENTITY",
    "CHICKASAW NATION DIVISION OF HEALTH|370180",
    "§10.2 enrolled-operator row with the session-72 precedence rule: OSDH states no form, so the CMS enrolment decides. CHICKASAW NATION MEDICAL CENTER is the exact DBA of CHICKASAW NATION DIVISION OF HEALTH (PART A PROVIDER - HOSPITAL, CCN 370180, Ada); the legal entity is not printed, so DBA_OF_LEGAL_ENTITY, LOW (the Choctaw Nation precedent, owner resolution session 87).",
  "lung_screening", "Stillwater Medical, $170,304.00", "Stillwater Medical", 170304, FALSE,
    "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes", "NAMED_HOSPITAL", "GENERAL_KNOWLEDGE", "LOW", "370049", "LEGAL_NAME_TRUNCATED",
    "STILLWATER MEDICAL CENTER AUTHORITY|370049",
    "HAND-READ BRIDGE: 'Stillwater Medical' is the trading name of STILLWATER MEDICAL CENTER AUTHORITY (dba STILLWATER MEDICAL CENTER, PART A PROVIDER - HOSPITAL, CCN 370049, Stillwater). The same authority also enrols two REHs (Perry 370779, Blackwell 370780); the line names no site, so the main hospital's CCN is carried and the legal body is the recipient either way.",
  "lung_screening", "Jackson County Memorial Hospital & Harmon Memorial Hospital, $170,304.00",
    "Jackson County Memorial Hospital & Harmon Memorial Hospital", 170304, FALSE,
    "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes", "NAMED_HOSPITAL", "GENERAL_KNOWLEDGE", "LOW", NA, "DBA_OF_LEGAL_ENTITY",
    "JACKSON COUNTY MEMORIAL HOSPITAL AUTHORITY|370022",
    "ONE LEGAL BODY, TWO HOSPITALS: CMS enrols JACKSON COUNTY MEMORIAL HOSPITAL AUTHORITY as dba JACKSON COUNTY MEMORIAL HOSPITAL (CCN 370022, Altus) AND dba HARMON MEMORIAL HOSPITAL (CRITICAL ACCESS HOSPITAL, CCN 371338, Hollis). The line names both hospitals of one authority at one amount, so it is one recipient's award and a NAMED_HOSPITAL row; no CCN is carried because the row names two (both in cms_enrolment_record). Not divided (§6.2).",
  "lung_screening", "Great Plains Medical Center, $170,304.00", "Great Plains Medical Center", 170304, FALSE,
    "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes", "NAMED_HOSPITAL", "GENERAL_KNOWLEDGE", "LOW", "370019", "DBA_OF_LEGAL_ENTITY",
    "FARMERS UNION HOSPITAL ASSOCIATION|370019",
    "HAND-READ BRIDGE: 'Great Plains Medical Center' is OSDH's short form of GREAT PLAINS REGIONAL MEDICAL CENTER, the DBA of FARMERS UNION HOSPITAL ASSOCIATION (PART A PROVIDER - HOSPITAL, CCN 370019, Elk City) -- the only enrolled 'Great Plains' hospital in Oklahoma, and named in full on the Telestroke and Closed-Loop fragments.",
  "lung_screening", "SSM Affiliates: Purcell Municipal, Newman Memorial, Harper County Community, Beaver County Memorial, $170,304.00*",
    "SSM Affiliates: Purcell Municipal, Newman Memorial, Harper County Community, Beaver County Memorial", 170304, TRUE,
    "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes", "POOL_NAMED_HOSPITALS", "GENERAL_KNOWLEDGE", "LOW", NA, NA, NA,
    "ONE AMOUNT ACROSS FOUR ENROLLED LEGAL BODIES: PURCELL MUNICIPAL HOSPITAL (370158), NEWMAN MEMORIAL HOSPITAL, INC (CAH 371336), HARPER COUNTY COMMUNITY HOSPITAL (REH 370781, Buffalo) and BEAVER COUNTY MEMORIAL HOSPITAL (CAH 371322). §7 (session 105): a component priced for named hospitals alone is a POOL_NAMED_HOSPITALS row and is never divided (§6.2) -- the CT Hartford HealthCare / VA VCU pair shape. 'SSM Affiliates' is OSDH's label for the group, not a payee the page names. Marked '*Contract not finalized'.",
  "lung_screening", "SSM Affiliates: Cordell Memorial Hospital, Okeene Municipal Hospital, Weatherford Regional Hospital, $170,304.00*",
    "SSM Affiliates: Cordell Memorial Hospital, Okeene Municipal Hospital, Weatherford Regional Hospital", 170304, TRUE,
    "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes", "POOL_NAMED_HOSPITALS", "GENERAL_KNOWLEDGE", "LOW", NA, NA, NA,
    "ONE AMOUNT ACROSS THREE ENROLLED LEGAL BODIES: CORDELL MEMORIAL HOSPITAL (CAH 371325), OKEENE MUNICIPAL HOSPITAL AND SCHALLMO AUTHORITY (CAH 371327) and WEATHERFORD HOSPITAL AUTHORITY dba WEATHERFORD REGIONAL HOSPITAL (CAH 371323). §7 (session 105): POOL_NAMED_HOSPITALS, never divided (§6.2). Marked '*Contract not finalized'.",
  "lung_screening", "Duncan Regional Hospital, $170,304.00", "Duncan Regional Hospital", 170304, FALSE,
    "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes", "NAMED_HOSPITAL", "ORG_WEBSITE", "MEDIUM", "370023", "EXACT_LEGAL_NAME",
    "DUNCAN REGIONAL HOSPITAL, INC|370023",
    "§10.2 DIRECT: CMS OK Hospital Enrollments carry DUNCAN REGIONAL HOSPITAL, INC (PART A PROVIDER - HOSPITAL, CCN 370023, Duncan) -- the awardee's legal name less 'Inc' (EXACT_LEGAL_NAME, MEDIUM). The same legal body also enrols Jefferson County Hospital (CAH 371311, Waurika); the line names Duncan.",
  "lung_screening", "Integris Enid, $170,304.00*", "Integris Enid", 170304, TRUE,
    "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes", "NAMED_HOSPITAL", "GENERAL_KNOWLEDGE", "LOW", "370016", "DBA_OF_LEGAL_ENTITY",
    "INTEGRIS BASS BAPTIST HEALTH CENTER|370016",
    "HAND-READ BRIDGE: 'Integris Enid' is the short form of INTEGRIS HEALTH ENID HOSPITAL, the DBA of INTEGRIS BASS BAPTIST HEALTH CENTER (PART A PROVIDER - HOSPITAL, CCN 370016, Enid), the one enrolled INTEGRIS hospital in Enid. Marked '*Contract not finalized'.",
  # ---- Telestroke -------------------------------------------------------------
  "telestroke", "University of Oklahoma – Health Sciences Center (OUHSC), $499,555.00",
    "University of Oklahoma – Health Sciences Center (OUHSC)", 499555, FALSE,
    "UNIVERSITY_OR_AHC", "NON_HOSPITAL", "No", "NOT_HOSPITAL", "STATE_SOURCE", "MEDIUM", NA, NA, NA,
    "A state university's health-sciences centre, 'Funded through interagency agreement'. OU's hospital is enrolled by a DIFFERENT legal body (CMS OK Hospital Enrollments: OU MEDICINE INC dba OU HEALTH UNIVERSITY OF OKLAHOMA MEDICAL CENTER, CCN 370093), so §10.2's enrolled-operator row does not reach it (R/03bt's OU Board of Regents precedent). The 15 'Participating Sites' (rural hospitals) are network sites; the page says nothing about money reaching them, so they are not rows (§0.3) and hospital_benefiting = Yes.",
  # ---- Closed-Loop --------------------------------------------------------------
  "closed_loop", "Findhelp, Inc., $830,400.00", "Findhelp, Inc.", 830400, FALSE,
    "VENDOR_OR_CONTRACTOR", "IN_KIND_BENEFIT", "No", "NOT_HOSPITAL", "STATE_SOURCE", "MEDIUM", NA, NA, NA,
    "The vendor of Oklahoma's closed-loop referral platform ('Funding will extend platform licenses to critical access hospitals, rural emergency hospitals, and FQHCs'; administered by the Oklahoma Health Care Authority). §10.2 IN_KIND_BENEFIT: hospitals use the licences and receive no money; the seven 'Cohort 1 participants' are not payees and are not rows. hospital_benefiting = Yes.",
  # ---- Grow Your Own --------------------------------------------------------------
  "grow_your_own", "Indian Capital Career and Technology Center, Tahlequah $31,166.00",
    "Indian Capital Career and Technology Center, Tahlequah", 31166, FALSE,
    "SCHOOL_OR_DISTRICT", "NON_HOSPITAL", "No", "NOT_HOSPITAL", "STATE_SOURCE", "MEDIUM", NA, NA, NA,
    "A CareerTech technology-centre campus ('local Career Technology centers', 'Funded through interagency agreement' via CareerTech); Oklahoma technology centres are public school districts. The same centre's Sallisaw campus is a separate priced line.",
  "grow_your_own", "Indian Capital Career and Technology Center, Sallisaw $31,166.00",
    "Indian Capital Career and Technology Center, Sallisaw", 31166, FALSE,
    "SCHOOL_OR_DISTRICT", "NON_HOSPITAL", "No", "NOT_HOSPITAL", "STATE_SOURCE", "MEDIUM", NA, NA, NA,
    "A CareerTech technology-centre campus; the same centre's Tahlequah campus is a separate priced line.",
  "grow_your_own", "Pontotoc Career and Technology Center, Ada $31,166.00",
    "Pontotoc Career and Technology Center, Ada", 31166, FALSE,
    "SCHOOL_OR_DISTRICT", "NON_HOSPITAL", "No", "NOT_HOSPITAL", "STATE_SOURCE", "MEDIUM", NA, NA, NA,
    "A CareerTech technology-centre campus.",
  "grow_your_own", "Red River Career and Technology Center, Duncan $31,166.00",
    "Red River Career and Technology Center, Duncan", 31166, FALSE,
    "SCHOOL_OR_DISTRICT", "NON_HOSPITAL", "No", "NOT_HOSPITAL", "STATE_SOURCE", "MEDIUM", NA, NA, NA,
    "A CareerTech technology-centre campus.",
  "grow_your_own", "Southern Oklahoma Technology Center, Ardmore $31,166.00",
    "Southern Oklahoma Technology Center, Ardmore", 31166, FALSE,
    "SCHOOL_OR_DISTRICT", "NON_HOSPITAL", "No", "NOT_HOSPITAL", "STATE_SOURCE", "MEDIUM", NA, NA, NA,
    "A CareerTech technology-centre campus.",
  # ---- Transportation ----------------------------------------------------------------
  "transportation", "Southwestern Oklahoma Development Authority (SWODA) is providing $206,778.07 in mileage reimbursement",
    "Southwestern Oklahoma Development Authority (SWODA)", 206778.07, FALSE,
    "LOCAL_GOVT_OR_PUBLIC_HEALTH", "NON_HOSPITAL", "No", "NOT_HOSPITAL", "STATE_SOURCE", "MEDIUM", NA, NA, NA,
    "The Funding Administrator ('Funded through interagency agreement'), a regional development authority of local governments, priced for its own Year 1 mileage-reimbursement programme for rural residents' medical, health and wellness trips. Not a hospital.",
  "transportation", "Big Five - SORTS, $117,376.00", "Big Five - SORTS", 117376, FALSE,
    NA, "NON_HOSPITAL", "No", "NOT_HOSPITAL", NA, NA, NA, NA, NA,
    "An FTA Section 5311 transit agency awarded vehicle funding through SWODA's competitive procurement; OSDH states no form.",
  "transportation", "Cherokee Strip, $240,000.00", "Cherokee Strip", 240000, FALSE,
    NA, "NON_HOSPITAL", "No", "NOT_HOSPITAL", NA, NA, NA, NA, NA,
    "An FTA Section 5311 transit agency (SWODA vehicle procurement); OSDH states no form.",
  "transportation", "COCAA/COTS, $276,486.00", "COCAA/COTS", 276486, FALSE,
    NA, "NON_HOSPITAL", "No", "NOT_HOSPITAL", NA, NA, NA, NA, NA,
    "An FTA Section 5311 transit agency (SWODA vehicle procurement); OSDH states no form.",
  "transportation", "Comanche Nations, $178,182.00", "Comanche Nations", 178182, FALSE,
    "TRIBAL_ORG", "NON_HOSPITAL", "No", "NOT_HOSPITAL", "GENERAL_KNOWLEDGE", "LOW", NA, NA, NA,
    "A tribal transit agency (SWODA vehicle procurement); a federally recognised tribe on general knowledge -- OSDH states no form (R/03cc's Cheyenne and Arapaho precedent). Not a hospital either way.",
  "transportation", "First Capital Trolley, $297,447.00", "First Capital Trolley", 297447, FALSE,
    NA, "NON_HOSPITAL", "No", "NOT_HOSPITAL", NA, NA, NA, NA, NA,
    "An FTA Section 5311 transit agency (SWODA vehicle procurement); OSDH states no form.",
  "transportation", "KATS, $203,595.90", "KATS", 203595.90, FALSE,
    NA, "NON_HOSPITAL", "No", "NOT_HOSPITAL", NA, NA, NA, NA, NA,
    "An FTA Section 5311 transit agency (SWODA vehicle procurement); OSDH states no form.",
  "transportation", "LIFT, $210,726.00", "LIFT", 210726, FALSE,
    NA, "NON_HOSPITAL", "No", "NOT_HOSPITAL", NA, NA, NA, NA, NA,
    "An FTA Section 5311 transit agency (SWODA vehicle procurement); OSDH states no form.",
  "transportation", "Pelivan, $118,058.00", "Pelivan", 118058, FALSE,
    NA, "NON_HOSPITAL", "No", "NOT_HOSPITAL", NA, NA, NA, NA, NA,
    "An FTA Section 5311 transit agency (SWODA vehicle procurement); OSDH states no form.",
  "transportation", "Southwest Transit, $182,210.00", "Southwest Transit", 182210, FALSE,
    NA, "NON_HOSPITAL", "No", "NOT_HOSPITAL", NA, NA, NA, NA, NA,
    "An FTA Section 5311 transit agency (SWODA vehicle procurement); OSDH states no form.",
  "transportation", "United Community Action, $230,000.00", "United Community Action", 230000, FALSE,
    NA, "NON_HOSPITAL", "No", "NOT_HOSPITAL", NA, NA, NA, NA, NA,
    "An FTA Section 5311 transit agency (SWODA vehicle procurement); OSDH states no form."
)

okx_assert_sources <- function() {
  for (i in seq_len(nrow(OKX_ROSTERS))) {
    r <- OKX_ROSTERS[i, ]
    t <- okx_text(r$slug)
    if (!startsWith(t, sub(" - .*$", "", r$label))) {
      stop("[OK XF] fragment '", r$slug, "' no longer opens with its programme name.",
           call. = FALSE)
    }
    l <- OKX_LINES[OKX_LINES$kind == r$kind, ]
    for (q in l$line) {
      if (!grepl(stringr::str_squish(q), t, fixed = TRUE)) {
        stop("[OK XF] '", r$slug, "' no longer prints: ", q, call. = FALSE)
      }
    }
    if (nrow(l) != r$n || abs(sum(l$amount) - r$total) > 0.005) {
      stop("[OK XF] ", r$kind, ": ", nrow(l), " lines / $", sum(l$amount),
           "; expected ", r$n, " / $", r$total, ".", call. = FALSE)
    }
    # Every dollar figure in the fragment is a line here (none dropped).
    am <- as.numeric(gsub("[$,]", "", stringr::str_extract_all(
      t, "\\$[0-9][0-9,]*(\\.[0-9]{2})?")[[1]]))
    if (abs(sum(am) - r$total) > 0.005) {
      stop("[OK XF] ", r$kind, ": the fragment's dollar figures sum to $", sum(am),
           ", not the lines' $", r$total, ".", call. = FALSE)
    }
    if (any(abs(am - 223476949) < RHTP_FOOTER_ALLOTMENT_MARGIN)) {
      stop("[OK XF] a line equals the allotment (§0.2).", call. = FALSE)
    }
  }
  lt <- okx_text("lung-cancer-screening-program")
  for (p in c("Funding Administrator: Oklahoma Hospital Association",
              "Funded through subrecipient agreement.",
              "Lung Cancer Screening Subrecipients:", "*Contract not finalized")) {
    if (!grepl(p, lt, fixed = TRUE)) stop("[OK XF] lung fragment lost '", p, "'.", call. = FALSE)
  }
  tt <- okx_text("transportation-expansion")
  if (!grepl("The following 12 transit agencies were awarded funding for 20 vehicle purchases", tt, fixed = TRUE)) {
    stop("[OK XF] the transportation fragment no longer says '12 transit agencies'.", call. = FALSE)
  }
  if (!(OKX_PAGE_MODIFIED > OKX_NOA)) stop("[OK XF] §6.2 date test.", call. = FALSE)
  invisible(TRUE)
}

okx_assert_federal <- function() {
  e <- jsonlite::fromJSON(here::here(OKX_HOSP_FED))
  h <- tibble::tibble(org = e[["ORGANIZATION NAME"]], ccn = as.character(e$CCN))
  t <- OKX_LINES[!is.na(OKX_LINES$enrol), ]
  for (i in seq_len(nrow(t))) {
    p <- strsplit(t$enrol[i], "|", fixed = TRUE)[[1]]
    if (!any(h$org == p[1] & h$ccn == p[2])) {
      stop("[OK XF] the archived hospital file no longer carries ", p[1], " (", p[2], ").",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}

okx_rows <- function(kind) {
  l <- OKX_LINES[OKX_LINES$kind == kind, ]
  r <- OKX_ROSTERS[OKX_ROSTERS$kind == kind, ]
  cls <- rhtp_classify_recipient_type(l$awardee, OKX_STATE)
  typed <- !is.na(l$rtype)
  rtype <- ifelse(typed, l$rtype, cls$recipient_type)
  if (any(!typed & rtype == "HOSPITAL_OR_SYSTEM")) {
    stop("[OK XF] the name rule types an un-read row a hospital.", call. = FALSE)
  }
  conf <- ifelse(typed, l$conf, rhtp_confidence_ceiling(cls$determination_confidence))
  fallback <- rtype == "NONPROFIT_CBO" & conf == "LOW" & is.na(l$basis)
  multi <- l$attr == "POOL_NAMED_HOSPITALS"
  flag <- mapply(function(fb, pr, mu) {
    f <- c(if (fb) "RECIPIENT_TYPE_INFERRED", if (pr) "AMOUNT_PRELIMINARY",
           if (mu) "MULTI_RECIPIENT_FIELD")
    if (length(f)) paste(f, collapse = ";") else NA_character_
  }, fallback, l$prelim, multi)
  hosp <- l$dth == "Yes"
  lung <- kind == "lung_screening"
  tibble::tibble(
    state = OKX_STATE,
    row_no = seq_len(nrow(l)),
    awardee = l$awardee,
    amount = l$amount,
    recipient_type = rtype,
    distributed_to_hospital = l$dth,
    note = paste0(r$label, ", OSDH Funding Recipients page (fragment '", r$slug,
                  "', page last modified ", OKX_PAGE_MODIFIED, ", read ", OKX_READ,
                  "). As printed: '", l$line, "'.",
                  ifelse(l$prelim, " '*Contract not finalized' (OSDH): an INTENT, not an executed award.", ""),
                  if (kind == "transportation") " OSDH says '12 transit agencies were awarded funding for 20 vehicle purchases' and lists TEN; the other two are not named and are not imputed." else ""),
    recipient_confirmed = "Yes",
    amount_confirmed = ifelse(l$prelim, "No", "Yes"),
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = paste0("Oklahoma RHTP Funding Recipients -- ", r$label),
    state_source_url = OKX_URL,
    validation_source_type = ifelse(l$prelim, "NOTICE_OF_INTENT_TO_AWARD", "NOTICE_OF_AWARD"),
    extraction_method = "DIRECT_TEXT",
    validator = "R/03co_ok_xf_rosters.R",
    ccn = ifelse(hosp, l$ccn, NA_character_),
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    recipient_type_source = ifelse(
      typed, paste0("TYPED (session 112, HAND-READ): ", l$why, " Classifier said ",
                    cls$recipient_type, "/", rhtp_confidence_ceiling(cls$determination_confidence), "."),
      paste0("rhtp_classify_recipient_type() on the name: ", cls$recipient_type, "/",
             rhtp_confidence_ceiling(cls$determination_confidence), ". ", l$why)),
    determination_confidence = conf,
    flag_reason = unname(flag),
    award_pool = r$label,
    budget_period = "Budget Period 1",
    flow_type = l$flow,
    hospital_benefiting = ifelse(hosp | kind %in% c("telestroke", "closed_loop"), "Yes", "Unclear"),
    hospital_attribution = l$attr,
    intermediary_name = if (lung) OKX_OHA else NA_character_,
    determination_basis = paste0("§10.2 ", l$flow, ": ", l$why,
                                 if (lung) " OHA administers the programme 'through subrecipient agreement' and OSDH prices each hospital line, so the hospital is the recipient and §7's association row (a pool OHA holds) is not reached." else "",
                                 ifelse(hosp, " §0.3a: the recipient is a hospital whatever the activity.", "")),
    amount_basis = ifelse(l$prelim,
                          "PRELIMINARY: printed exactly, marked '*Contract not finalized'.",
                          "EXACT, as published per line by OSDH."),
    round_name = r$label,
    round_awards = nrow(l),
    round_amount = NA_real_,
    announcement_date = OKX_PAGE_MODIFIED,
    source_archive_path = file.path(OKX_FRAG, paste0(r$slug, ".html")),
    basis_type = ifelse(typed, l$basis, NA_character_),
    recipient_subtype = NA_character_,
    cms_enrolment_match = ifelse(hosp, l$match, NA_character_),
    cms_enrolment_record = ifelse(
      hosp & !is.na(l$enrol),
      paste0("CMS Hospital Enrollments: ", sub("\\|", ", CCN ", l$enrol), " (", OKX_HOSP_FED, ")",
             ifelse(grepl("^Jackson County", l$awardee),
                    "; also JACKSON COUNTY MEMORIAL HOSPITAL AUTHORITY dba HARMON MEMORIAL HOSPITAL, CCN 371338", "")),
      NA_character_))
}

okx_assert_rows <- function(a, kind) {
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "determination_confidence", "hospital_attribution", "basis_type",
                "flag_reason", "cms_enrolment_match", "hospital_benefiting")) {
    vals <- unlist(strsplit(stats::na.omit(a[[col]]), ";", fixed = TRUE))
    bad <- setdiff(unique(vals), rhtp_vocabulary(col))
    if (length(bad)) stop("[OK XF ", kind, "] ", col, " outside §8: ",
                          paste(bad, collapse = ", "), call. = FALSE)
  }
  if (any(a$determination_confidence == "HIGH")) stop("[OK XF] HIGH (§7).", call. = FALSE)
  h <- a[a$distributed_to_hospital == "Yes", ]
  if (any(h$recipient_type != "HOSPITAL_OR_SYSTEM") || any(h$flow_type != "DIRECT")) {
    stop("[OK XF ", kind, "] a Yes row is not a DIRECT hospital row.", call. = FALSE)
  }
  if (any(is.na(h$ccn) & h$determination_confidence != "LOW")) {
    stop("[OK XF ", kind, "] a hospital row with no CCN must be LOW.", call. = FALSE)
  }
  if (kind == "lung_screening") {
    n <- h[h$hospital_attribution == "NAMED_HOSPITAL", ]
    p <- h[h$hospital_attribution == "POOL_NAMED_HOSPITALS", ]
    if (nrow(n) != 9L || sum(n$amount) != 1532736 || nrow(p) != 2L || sum(p$amount) != 340608) {
      stop("[OK XF lung] expected 9 named / $1,532,736 and 2 pooled / $340,608.", call. = FALSE)
    }
  } else if (nrow(h)) {
    stop("[OK XF ", kind, "] no hospital row expected.", call. = FALSE)
  }
  invisible(TRUE)
}

okx_build_tables <- function() {
  okx_assert_sources()
  okx_assert_federal()
  out <- lapply(OKX_ROSTERS$kind, function(k) { a <- okx_rows(k); okx_assert_rows(a, k); a })
  stats::setNames(out, OKX_ROSTERS$kind)
}

okx_build <- function() {
  t <- okx_build_tables()
  num <- function(x) ifelse(is.na(x), NA_character_,
                            vapply(x, function(v) format(v, scientific = FALSE, digits = 15),
                                   character(1)))
  for (k in names(t)) {
    a <- dplyr::mutate(t[[k]], dplyr::across(dplyr::where(is.numeric), num),
                       dplyr::across(dplyr::everything(), as.character))
    readr::write_csv(a, okx_csv(k), na = "")
    h <- t[[k]][t[[k]]$distributed_to_hospital == "Yes", ]
    message(sprintf("[OK XF] %s: %d rows, $%s; %d hospital rows, $%s.", k, nrow(t[[k]]),
                    format(sum(t[[k]]$amount), big.mark = ",", nsmall = 2), nrow(h),
                    format(sum(h$amount), big.mark = ",", nsmall = 2)))
  }
  invisible(t)
}

okx_report <- function() {
  t <- okx_build_tables()
  for (k in names(t)) {
    cat("\n==", k, "\n")
    print(as.data.frame(t[[k]][, c("awardee", "amount", "recipient_type",
                                   "distributed_to_hospital", "hospital_attribution",
                                   "determination_confidence", "ccn")]), row.names = FALSE)
  }
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) { okx_build_tables(); message("[OK XF] all assertions pass.") }
  if ("--build" %in% args) okx_build()
  if ("--report" %in% args) okx_report()
  if (!length(args)) message("Usage: --validate | --build | --report")
}
