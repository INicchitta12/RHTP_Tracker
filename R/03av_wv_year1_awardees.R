#!/usr/bin/env Rscript
# 03av_wv_year1_awardees.R ---------------------------------------------------
#
# WEST VIRGINIA -- SEVEN NAMED, PRICED AWARDS IN FIVE GOVERNOR'S RELEASES,
# $6,444,803, AND TWO OF THEM REACH A HOSPITAL.
#
# The Department of Health's newsroom carries five releases between
# 2026-09-04 and 2026-09-22, each announcing RHTP awards by name and amount:
#
#   09-04  Health to Prosperity: Spotted Owl Healthcare Organization
#          $1,174,000; CAMC/Vandalia Health $612,000; Cabell Huntington
#          Foundation $612,000 ("nearly $2.4 million")
#   09-09  Mountain State Care Force: Ascend WV $2.4 million (ROUNDED)
#   09-17  Connected Care Grid: WV Health Information Network $855,400
#   09-21  Mountain State Care Force: WVU Medicine Center for Nursing
#          Education $291,403
#   09-22  Provider Productivity Support Fund: CHANGE, Inc. $500,000
#
# SEVEN ROWS SUM TO $6,444,803. Session 53's note said $6,442,803; the
# $2,000 is session 53's addition, not a source figure, and the rows are what
# is recorded here. Ascend WV's figure is printed only as "$2.4 million", so
# it carries AMOUNT_ROUNDED_IN_SOURCE and the sum inherits that rounding.
#
# TYPING (session 54, owner decisions where stated):
#   * CAMC/Vandalia Health -- HOSPITAL_OR_SYSTEM. CMS Hospital Enrollment:
#     CHARLESTON AREA MEDICAL CENTER INC dba VANDALIA HEALTH CHARLESTON AREA
#     MEDICAL CENTER, CCN 510022. The activity is worksite clinics; §0.3a
#     judges the recipient, so DIRECT (Beebe's school-based centre).
#   * Cabell Huntington Foundation -- HOSPITAL_OR_SYSTEM by §10.2's
#     hospital-foundation row (session 49): the foundation of a NAMED hospital,
#     Cabell Huntington Hospital (CMS CCN 510055), whose name it carries.
#   * WVU Medicine Center for Nursing Education -- UNIVERSITY_OR_AHC (owner
#     decision). A nursing school of the WVU academic health system; the
#     release's own reason for the award is WVU Health System's nursing
#     vacancies, which is a hospital BENEFITING, not a hospital receiving --
#     so NON_HOSPITAL with hospital_benefiting noted, and $0 of hospital money.
#   * Ascend WV -- UNIVERSITY_OR_AHC, the release's own words: "Operated
#     under West Virginia University".
#   * CHANGE, Inc. -- FQHC_OR_RHC, stated by the source ("both a Federally
#     Qualified Health Center and Community Action Agency") and by CMS's FQHC
#     enrolment (CHANGE INCORPORATED, Weirton).
#   * West Virginia Health Information Network -- OTHER: the state's health
#     information exchange, in the release's own words. IN_KIND_BENEFIT --
#     §10.2's "a state system that hospitals use but do not receive".
#   * Spotted Owl Healthcare Organization -- §8's standing fallback. No
#     federal record and no stated form; NOT promoted (§0.4).
#
# §0.2: every release's CMS footer prints $199,476,098.72, West Virginia's
# ALLOTMENT, and the rule agrees -- a Tier 1 footer on Tier 3 releases.
# The 2026-08-14 "$4.2 million" release is two OPPORTUNITIES (Tier 2) and is
# not in this file.
#
# A PARTIAL YEAR in West Virginia's own words: "Additional Rural Health
# Transformation Program awards will be announced".
#
# SESSION 85: TWO MORE RELEASES (2026-09-30), SEVEN MORE ROWS. The probe
# tripped on 10-02 11:41Z; both releases are archived under data/evidence/WV/.
#   * Community Care of West Virginia -- FOUR priced awards, $1,103,614
#     ("more than $1.1 million"), CCG and MSCF. FQHC_OR_RHC: the release says
#     "a West Virginia-based Federally Qualified Health Center", and CMS FQHC
#     Enrollments carry COMMUNITY CARE OF WEST VIRGINIA, INC. at ~80 sites. It
#     has NO CMS hospital enrolment. NON_HOSPITAL.
#   * Minnie Hamilton Health Care Center -- "More Than $4 Million", THREE
#     projects, ONE priced: the Connected Care Grid mobile clinic, "$1.7
#     million" (ROUNDED). The drone collaborative and the AI documentation
#     project carry NO amount, and the >$2.3M between them is NOT divided
#     (§6.2). HOSPITAL_OR_SYSTEM on its CMS enrolment: CMS Hospital
#     Enrollments carry ORGANIZATION NAME "MINNIE HAMILTON HEALTH CARE CENTER
#     INC", DBA "MINNIE HAMILTON HEALTH SYSTEM", PART A PROVIDER - CRITICAL
#     ACCESS HOSPITAL, CCN 511303, Grantsville -- the awardee's own legal name
#     (EXACT_LEGAL_NAME, MEDIUM). The SAME legal entity also enrols an FQHC
#     (CCN 511871, Glenville), so the name reading "Health Care Center" is not
#     a form; the enrolment is (§10.2's enrolled-hospital-operator row). The
#     release states no contrary form -- it says "Per the hospital" -- so the
#     session-72 precedence rule does not bite. All three rows are DIRECT and
#     NAMED_HOSPITAL; two of them contribute ROWS and $0.
#
# FOURTEEN ROWS, TWELVE PRICED, $9,248,417 (Ascend WV and Minnie Hamilton's
# $1.7M rounded in source). Hospital: 5 rows / $2,924,000.
#
# THE PROBE (session 55). `--probe` reads three pages LIVE and never writes
# to data/evidence/ (§2.2):
#   * the DoH NEWS INDEX -- the channel all five award releases came through.
#     It TRIPS on any article whose headline says "Award" and is not one of the
#     five releases above. It is NOT name-diffed: it is a press index, and WIC
#     and flood notices move it every week (§2.3, subject pages only).
#   * the RHTP PROGRAMME page and GRANT OPPORTUNITIES page -- the subject
#     pages, name-diffed against data/evidence/WV/ (§2.3). Grant Opportunities
#     reads "No active funding opportunities at this time" today; a new
#     solicitation there is CHANGED, not a tripwire (Tier 2, §0.2).
#
# SESSION 100: THE 2026-09-30 "$3.2 MILLION ... INVESTMENTS" RELEASE, SEVEN
# MORE ROWS, NONE PRICED (owner-approved). Session 99 found it on the news
# index (its headline says "Investments", not "Award") and held it. It says
# "Today's awards" and "The awards were made through the SmartCare Catalyst
# Provider Productivity Support Fund and Mountain State Care Force
# initiatives", names seven recipients, and prices none: "more than $3.2
# million" in all, NOT divided (§6.2). Like Nevada and Iowa, the rows carry
# the names at $0.
#   * The five ambient-listening hospitals and Broaddus Hospital are typed on
#     CMS WV Hospital Enrollments (data/evidence/federal_records/2026-09-23/):
#     Mon Health Marion Neighborhood Hospital (510093), Preston Memorial
#     Hospital (511312, CAH) and Webster Memorial Hospital (511301, CAH) match
#     the enrolled legal name exactly (MEDIUM). Stonewall Jackson Memorial
#     Hospital (510038, legal name "... HOSPITAL COMPANY"), Plateau Medical
#     Center (511317, CAH, "CAMC PLATEAU MEDICAL CENTER, INC.") and Broaddus
#     Hospital (511300, CAH, "BROADDUS HOSPITAL ASSOCIATION INC.") are
#     hand-read LEGAL_NAME_TRUNCATED bridges (LOW): each is the one enrolled
#     hospital of that name in West Virginia, and the release calls all six
#     hospitals. Each is also in R/03bj's EH_APPLY.
#   * SESSION 101: OWNER RULING. Vandalia Health is typed HOSPITAL_OR_SYSTEM
#     as a system parent (LOW, GENERAL_KNOWLEDGE, no CCN), a NAMED_HOSPITAL
#     row at $0; WV_VANDALIA_SYSTEM_PARENT resolved at (b). Session 100's
#     reading, kept as the record:
#   * Vandalia Health is a SYSTEM PARENT with no enrolment under that legal
#     name (its hospitals enrol as "VANDALIA HEALTH <hospital>" DBAs, which a
#     prefix may not match, §2). It stays on §8's standing fallback, and its
#     award ("help rural hospitals and clinics fill critical staffing
#     shortages") reaches hospitals AMONG OTHERS, so PASS_THROUGH_UNRESOLVED +
#     Unclear (§0.3). The system-parent precedent (Sanford/Avera, Valley
#     Health/Ballad/Sentara, Guthrie, Mercy) is an OWNER ruling each time, so
#     it is queued as WV_VANDALIA_SYSTEM_PARENT, not applied. $0 either way.
#
# TWENTY-ONE ROWS, TWELVE PRICED, $9,248,417 (unchanged). Hospital: 11 rows /
# $2,924,000 (six of them at $0); 12 rows / $2,924,000 from session 101
# (Vandalia Health, owner ruling, $0).
#
# Usage:
#   Rscript R/03av_wv_year1_awardees.R --validate | --build | --probe | --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
  library(purrr); library(here); library(rlang)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

WV_STATE     <- "WV"
WV_ALLOTMENT <- 199476099        # cms_fy2026_allotments.csv (§7.1)
WV_TOTAL     <- 48827616         # the PRICED rows (session 103: + $6,156,458; session 107: + $3,400,000; session 112: + $1,589,077; session 115: + $3,930,266; session 117a: + $16,976,480; session 121: + $7,526,918); unpriced rows carry none
WV_NOA_DATE  <- as.Date("2025-12-29")
WV_DIR       <- file.path("data", "evidence", "recheck", "2026-09-23", "WV")
WV_CSV       <- here::here("data", "reference", "wv_year1_awardees.csv")
WV_STATUS_CSV <- here::here("data", "reference", "wv_year1_status.csv")

WV_FILES <- c(
  hp   = "wv_art_first-rural-health-transformation-progra.html",
  asc  = "wv_art_24-million-award-ascend-wv-strengthen-he.html",
  hin  = "wv_art_855400-award-strengthen-statewide-health.html",
  nurs = "wv_art_award-expand-nursing-education-and-stren.html",
  chg  = "wv_art_first-provider-productivity-support-fund.html")

WV_URL <- "https://health.wv.gov/article/"
# The canonical URLs, read from each archived page's <link rel="canonical">.
WV_SLUG <- c(
  hp   = "governor-morrisey-announces-first-rural-health-transformation-program-awards",
  asc  = "governor-morrisey-announces-24-million-award-ascend-wv-strengthen-healthcare-workforce",
  hin  = "governor-morrisey-announces-855400-award-strengthen-statewide-health-data-infrastructure",
  nurs = "governor-morrisey-announces-award-expand-nursing-education-and-strengthen-west-virginias",
  chg  = "governor-morrisey-announces-first-provider-productivity-support-fund-award-through-rural",
  ccwv = "governor-morrisey-announces-more-11-million-rural-health-transformation-awards-community",
  mh   = "governor-morrisey-announces-more-4-million-rural-health-transformation-awards-minnie",
  inv  = "governor-morrisey-announces-more-32-million-rural-health-transformation-investments",
  eye  = "governor-morrisey-announces-2-million-investment-expand-teleophthalmology-network-across",
  phg  = "governor-morrisey-announces-500000-strengthen-mental-health-and-addiction-recovery-services",
  pca  = "governor-morrisey-announces-nearly-22-million-strengthen-community-health-centers-across",
  ars  = "governor-morrisey-announces-more-17-million-help-west-virginians-recovery-return-work",
  wvu  = "governor-morrisey-announces-more-34-million-rural-health-transformation-awards-west",
  can  = "governor-morrisey-announces-13-million-expand-mobile-cancer-screenings-across-west-virginia",
  whwc = "governor-patrick-morrisey-today-announced-250000-award-williamson-health-wellness-center",
  camc = "governor-morrisey-announces-39-million-expand-rural-healthcare-training-and-workforce",
  dia  = "governor-morrisey-announces-nearly-17-million-rural-health-transformation-awards-strengthen",
  rni  = "governor-morrisey-announces-more-93-million-help-west-virginians-stay-recovery-and-grow",
  cp   = "governor-morrisey-announces-more-11-million-investment-launch-community-paramedicine")

# AWARD RELEASES READ AND JUDGED NOT RHTP (session 99). Each slug is excluded
# from the tripwire with the sentence that justifies it; a release is never
# listed here to make a trip quiet without being read (§2.3's furniture rule).
WV_NOT_RHTP <- tibble::tribble(
  ~slug, ~why,
  "west-virginia-awarded-195825-federal-grant-upgrade-wic-clinics-needle-free-screening",
  paste("Read 2026-10-12 (session 99; tripped the 10-09 Routine): 'a new",
        "$195,825 federal infrastructure grant from the USDA Food and Nutrition",
        "Service' for Masimo Pronto devices in WIC clinics, received by DH's own",
        "Office of Nutrition Services. RHTP and CMS appear only in the site",
        "navigation. §0.1 mode 1, wrong programme."))

# AWARD RELEASES READ AND NOT YET EXTRACTED -- OWNER DECISION. A release listed
# here keeps the tripwire quiet without being in WV_AWARDS; each entry carries
# its sentence. EMPTY since session 100: the one entry session 99 held, the
# 2026-09-30 "$3.2 Million ... Investments" release, was extracted on the
# owner's approval (key `inv` in WV_SLUG and WV_AWARDS_S100).
# SESSION 121: two releases read and NOT extracted, each with its reason.
WV_READ_UNEXTRACTED <- tibble::tribble(
  ~slug, ~why,
  "governor-morrisey-announces-202-million-new-rural-health-funding-bringing-two-year-total",
  paste("Read 2026-11-20 (session 121; tripped the 11-20 Routine): the YEAR 2 award",
        "release ('$202 Million in New Rural Health Funding, Bringing Two-Year Total",
        "to More Than $401 Million'), the health.wv.gov copy of the release archived",
        "2026-11-13 (WV_Y2_RELEASE). Year 2 is safeguards only (session 116): no row."),
  "governor-morrisey-announces-reopening-labor-and-delivery-services-greenbrier-valley-medical",
  paste("Read 2026-11-20 (session 121). Its award IS extracted, from the state's",
        "Year 1 roster (row 57: West Virginia School of Osteopathic Medicine,",
        "$3,999,993, 'Birthing Center'); the release itself is not a source of a row.",
        "The release reads: 'a nearly $4 million Rural Health",
        "Transformation Program award to establish West Virginia's second freestanding",
        "birthing center' that 'will support a new WVSOM community-based birthing",
        "center and also provide assistance for more complex pregnancies'. The release",
        "names NO recipient of the award (WVSOM, Vandalia Health/CAMC and Greenbrier",
        "Valley Medical Center are all in it) and prints the amount only as 'nearly $4",
        "million'. Not extracted: a recipient is not inferred from a setting (§0.3a,",
        "§0.4). Archived recheck/2026-11-20/WV/."))

# Where each release is archived. The session-85 pair sits under
# data/evidence/WV/ with its fetch date, not under the 09-23 recheck folder.
WV_PATHS <- c(
  stats::setNames(file.path(WV_DIR, WV_FILES), names(WV_FILES)),
  ccwv = file.path("data", "evidence", "WV", "2026-10-02_wv_art_ccwv_rhtp_awards.html"),
  mh   = file.path("data", "evidence", "WV", "2026-10-02_wv_art_minnie_hamilton_rhtp_awards.html"),
  inv  = file.path("data", "evidence", "WV", "2026-10-12_wv_art_32m_rhtp_investments.html"),
  eye  = file.path("data", "evidence", "WV", "2026-10-16_wv_art_wvu_eye_institute_2m.html"),
  phg  = file.path("data", "evidence", "WV", "2026-10-16_wv_art_potomac_highlands_guild_500k.html"),
  pca  = file.path("data", "evidence", "WV", "2026-10-16_wv_art_wvpca_mva_2_2m.html"),
  ars  = file.path("data", "evidence", "WV", "2026-10-16_wv_art_ascension_recovery_1_5m_and_arc.html"),
  wvu  = file.path("data", "evidence", "WV", "2026-10-26_wv_art_wvu_health_system_3_4m.html"),
  can  = file.path("data", "evidence", "WV", "2026-11-02_wv_art_wvu_cancer_institute_1_3m.html"),
  whwc = file.path("data", "evidence", "WV", "2026-11-02_wv_art_williamson_hwc_250k.html"),
  camc = file.path("data", "evidence", "WV", "2026-11-09_wv_art_camc_3_9m.html"),
  dia  = file.path("data", "evidence", "recheck", "2026-11-13", "WV", "2026-11-13_wv_gov_17m_diabetes_awards.html"),
  rni  = file.path("data", "evidence", "recheck", "2026-11-20", "WV", "2026-11-20_wv_art_rni_6_3m_recovery.html"),
  cp   = file.path("data", "evidence", "recheck", "2026-11-20", "WV", "2026-11-20_wv_art_wvu_medicine_community_paramedicine_1_1m.html"))

# Minnie Hamilton's CMS enrolment (session 85), read from the archived file.
WV_MH_ENROLMENT <- paste0(
  "CMS Hospital Enrollments (data/evidence/federal_records/2026-09-23/",
  "cms_hosp_enrollments_WV.json): ORGANIZATION NAME 'MINNIE HAMILTON HEALTH ",
  "CARE CENTER INC', DBA 'MINNIE HAMILTON HEALTH SYSTEM', PART A PROVIDER - ",
  "CRITICAL ACCESS HOSPITAL, CCN 511303, GRANTSVILLE. The same legal entity ",
  "also enrols an FQHC (CCN 511871, Glenville).")

WV_PROBE_DIR <- file.path("data", "evidence", "WV")
WV_PROBE_PAGES <- tibble::tribble(
  ~key, ~url, ~file, ~name_diff,
  # Session 121: all three re-based to 2026-11-20 after READING each diff: the
  # news index added the four articles read above; the programme page renamed
  # a menu item (Grants -> Funding) and its footer now prints FY2026 + FY2027;
  # /grant-opportunities REDIRECTS to /funding-opportunities, which links the
  # state's Year 1 roster (extracted) and one Tier 2 solicitation ("Mountain
  # State Care Force: Public Education and Marketing").
  "news", "https://health.wv.gov/news", "2026-11-20_wv_news_index.html", FALSE,
  "rhtp", "https://health.wv.gov/rhtp", "2026-11-20_wv_rhtp_programme.html", TRUE,
  "grants", "https://health.wv.gov/funding-opportunities",
  "2026-11-20_wv_funding_opportunities.html", TRUE)
WV_USER_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                        "+https://www.aha.org)")

wv_text <- function(key) {
  f <- here::here(WV_PATHS[[key]])
  t <- paste(readLines(f, warn = FALSE, encoding = "UTF-8"), collapse = " ")
  t <- stringr::str_remove_all(t, stringr::regex(
    "<(script|style|noscript)[^>]*>.*?</\\1>", dotall = TRUE, ignore_case = TRUE))
  t <- stringr::str_replace_all(t, "<[^>]+>", " ")
  t <- stringr::str_replace_all(t, "&nbsp;|&#160;", " ")
  t <- stringr::str_replace_all(t, "&amp;", "&")
  t <- stringr::str_replace_all(t, "&#039;|&#8217;|’", "'")
  stringr::str_squish(t)
}

# Each award, with the sentence that carries it (asserted verbatim).
WV_AWARDS <- tibble::tribble(
  ~key, ~date, ~initiative, ~awardee, ~amount, ~quote,
  ~recipient_type, ~basis_type, ~flow_type, ~dist, ~why,
  "hp", "2026-09-04", "Health to Prosperity",
  "Spotted Owl Healthcare Organization", 1174000,
  "Spotted Owl Healthcare Organization: $1,174,000",
  NA, NA, "NON_HOSPITAL", "No",
  "No stated form and no CMS enrolment under this name: §8's standing fallback, NOT promoted (§0.4).",
  "hp", "2026-09-04", "Health to Prosperity",
  "CAMC/Vandalia Health", 612000,
  "CAMC/Vandalia Health: $612,000",
  "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "DIRECT", "Yes",
  "CMS Hospital Enrollment: CHARLESTON AREA MEDICAL CENTER INC dba VANDALIA HEALTH CHARLESTON AREA MEDICAL CENTER, CCN 510022. The activity is worksite clinics; §0.3a judges the recipient.",
  "hp", "2026-09-04", "Health to Prosperity",
  "Cabell Huntington Foundation", 612000,
  "Cabell Huntington Foundation: $612,000",
  "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "DIRECT", "Yes",
  "§10.2 HOSPITAL-FOUNDATION ROW (session 49; owner decision session 54): the foundation of a NAMED hospital, Cabell Huntington Hospital (CMS CCN 510055), whose name it carries. The parent tie is a reading, not a stated fact, so LOW.",
  "asc", "2026-09-09", "Mountain State Care Force",
  "Ascend WV", 2400000,
  "announced a $2.4 million award to Ascend WV",
  "UNIVERSITY_OR_AHC", "STATE_SOURCE", "NON_HOSPITAL", "No",
  "The release: 'Operated under West Virginia University, Ascend WV is expected to implement a statewide recruitment and relocation program'. A university programme; §10.2 NON_HOSPITAL.",
  "hin", "2026-09-17", "Connected Care Grid",
  "West Virginia Health Information Network (WVHIN)", 855400,
  "announced an $855,400 award to the West Virginia Health Information Network (WVHIN)",
  "OTHER", "STATE_SOURCE", "IN_KIND_BENEFIT", "No",
  "DETERMINED FORM: the state's health information exchange -- 'WVHIN serves as the state's Health Information Exchange'. Hospitals USE it and do not receive the money.",
  "nurs", "2026-09-21", "Mountain State Care Force",
  "WVU Medicine Center for Nursing Education", 291403,
  "announced a $291,403 award to the WVU Medicine Center for Nursing Education",
  "UNIVERSITY_OR_AHC", "GENERAL_KNOWLEDGE", "NON_HOSPITAL", "No",
  "OWNER DECISION (session 54): UNIVERSITY_OR_AHC -- a nursing school of the WVU academic health system. The release's reason is WVU Health System's ~1,000 nursing vacancies: a hospital BENEFITING from graduates, not a hospital receiving the award.",
  "chg", "2026-09-22", "Provider Productivity Support Fund",
  "CHANGE, Inc.", 500000,
  "announced a $500,000 award to CHANGE, Inc.",
  "FQHC_OR_RHC", "STATE_SOURCE", "NON_HOSPITAL", "No",
  "The release: 'CHANGE, Inc. has served West Virginia communities for more than 40 years as both a Federally Qualified Health Center and Community Action Agency'; CMS FQHC Enrollment: CHANGE INCORPORATED, Weirton."
)

# Session 85: the two 2026-09-30 releases. The CCWV release names CCG and MSCF
# for its four awards together and does not assign each one; the initiative
# below is therefore the PAIR, never a guess at which.
WV_CCWV_WHY <- paste0(
  "The release: 'Community Care of West Virginia is a West Virginia-based ",
  "Federally Qualified Health Center'; CMS FQHC Enrollments: COMMUNITY CARE OF ",
  "WEST VIRGINIA, INC. (~80 sites). No CMS hospital enrolment under this name.")
WV_MH_WHY <- paste0(
  "§10.2 ENROLLED HOSPITAL OPERATOR: ", WV_MH_ENROLMENT, " The awardee string ",
  "is the enrolled legal name (EXACT_LEGAL_NAME, MEDIUM). The release states ",
  "no other form ('Per the hospital'), so the enrolment decides (session 72).")
WV_AWARDS_S85 <- tibble::tribble(
  ~key, ~date, ~initiative, ~awardee, ~amount, ~quote,
  ~recipient_type, ~basis_type, ~flow_type, ~dist, ~why, ~rounded,
  "ccwv", "2026-09-30", "Connected Care Grid / Mountain State Care Force",
  "Community Care of West Virginia", 92736,
  "$92,736 to expand virtual access to care",
  "FQHC_OR_RHC", "STATE_SOURCE", "NON_HOSPITAL", "No", WV_CCWV_WHY, FALSE,
  "ccwv", "2026-09-30", "Connected Care Grid / Mountain State Care Force",
  "Community Care of West Virginia", 574082,
  "$574,082 to deploy a mobile healthcare unit",
  "FQHC_OR_RHC", "STATE_SOURCE", "NON_HOSPITAL", "No", WV_CCWV_WHY, FALSE,
  "ccwv", "2026-09-30", "Connected Care Grid / Mountain State Care Force",
  "Community Care of West Virginia", 82432,
  "$82,432 to help current healthcare employees advance their careers",
  "FQHC_OR_RHC", "STATE_SOURCE", "NON_HOSPITAL", "No", WV_CCWV_WHY, FALSE,
  "ccwv", "2026-09-30", "Connected Care Grid / Mountain State Care Force",
  "Community Care of West Virginia", 354364,
  "$354,364 to establish a statewide rural healthcare apprenticeship program",
  "FQHC_OR_RHC", "STATE_SOURCE", "NON_HOSPITAL", "No", WV_CCWV_WHY, FALSE,
  "mh", "2026-09-30", "Connected Care Grid",
  "Minnie Hamilton Health Care Center", 1700000,
  "One of the awards, totaling to $1.7 million through the State's Connected Care Grid initiative",
  "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "DIRECT", "Yes", WV_MH_WHY, TRUE,
  "mh", "2026-09-30", "Not stated per award (release: 'additional provider productivity investments')",
  "Minnie Hamilton Health Care Center", NA_real_,
  "deploying autonomous drone delivery for time-critical supplies",
  "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "DIRECT", "Yes", WV_MH_WHY, FALSE,
  "mh", "2026-09-30", "Not stated per award (release: 'additional provider productivity investments')",
  "Minnie Hamilton Health Care Center", NA_real_,
  "A third project will implement artificial intelligence-supported clinical documentation technology",
  "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "DIRECT", "Yes", WV_MH_WHY, FALSE
)
WV_AWARDS <- dplyr::bind_rows(
  dplyr::mutate(WV_AWARDS, rounded = .data$awardee == "Ascend WV"),
  WV_AWARDS_S85)

# Session 100: the 2026-09-30 "$3.2 Million ... Investments" release. The
# release names the initiative PAIR for all seven awards together and assigns
# none, so the initiative below is the pair, never a guess at which.
WV_INV_INITIATIVE <- "SmartCare Catalyst Provider Productivity Support Fund / Mountain State Care Force"
WV_INV_FIVE <- paste0(
  "Five rural hospitals (Stonewall Jackson Memorial Hospital, Mon Health ",
  "Marion Neighborhood Hospital, Preston Memorial Hospital, Plateau Medical ",
  "Center, and Webster Memorial Hospital) received funding to deploy ",
  "artificial intelligence (AI)-powered ambient clinical listening technology")
WV_INV_ENROL_FILE <- "data/evidence/federal_records/2026-09-23/cms_hosp_enrollments_WV.json"
# One row per recipient; the CMS enrolment each hospital is typed on.
WV_INV_ENROL <- tibble::tribble(
  ~awardee, ~ccn, ~cms_org, ~match,
  "Stonewall Jackson Memorial Hospital", "510038",
    "STONEWALL JACKSON MEMORIAL HOSPITAL COMPANY (Weston; PART A PROVIDER - HOSPITAL)",
    "LEGAL_NAME_TRUNCATED",
  "Mon Health Marion Neighborhood Hospital", "510093",
    "MON HEALTH MARION NEIGHBORHOOD HOSPITAL, INC. (dba MON HEALTH MARION; White Hall; PART A PROVIDER - HOSPITAL)",
    "EXACT_LEGAL_NAME",
  "Preston Memorial Hospital", "511312",
    "PRESTON MEMORIAL HOSPITAL CORPORATION (Kingwood; PART A PROVIDER - CRITICAL ACCESS HOSPITAL)",
    "EXACT_LEGAL_NAME",
  "Plateau Medical Center", "511317",
    "CAMC PLATEAU MEDICAL CENTER, INC. (dba CAMC PLATEAU MEDICAL CENTER; Oak Hill; PART A PROVIDER - CRITICAL ACCESS HOSPITAL)",
    "LEGAL_NAME_TRUNCATED",
  "Webster Memorial Hospital", "511301",
    "WEBSTER MEMORIAL HOSPITAL INC (dba VANDALIA HEALTH WEBSTER MEMORIAL HOSPITAL; Webster Springs; CAH)",
    "EXACT_LEGAL_NAME",
  "Broaddus Hospital", "511300",
    "BROADDUS HOSPITAL ASSOCIATION INC. (dba VANDALIA HEALTH BROADDUS HOSPITAL; Philippi; PART A PROVIDER - CRITICAL ACCESS HOSPITAL)",
    "LEGAL_NAME_TRUNCATED")
WV_INV_BRIDGE_WHY <- c(
  "Stonewall Jackson Memorial Hospital" = "HAND-READ BRIDGE: the enrolled legal name less 'Company', a statement of corporate form that names no different body; the only enrolment of this name in WV. ",
  "Plateau Medical Center" = "HAND-READ BRIDGE: the enrolled legal name less the 'CAMC' prefix of its parent; the only enrolled Plateau Medical Center in WV (Oak Hill). ",
  "Broaddus Hospital" = "HAND-READ BRIDGE: the enrolled legal name less 'Association Inc.', a statement of form; its own DBA is 'VANDALIA HEALTH BROADDUS HOSPITAL'. ")
wv_inv_why <- function(a) {
  e <- WV_INV_ENROL[WV_INV_ENROL$awardee == a, ]
  paste0("§10.2 ENROLLED HOSPITAL (session 100): CMS Hospital Enrollments (",
         WV_INV_ENROL_FILE, "): ", e$cms_org, ", CCN ", e$ccn, ". ",
         if (e$match == "EXACT_LEGAL_NAME") "The awardee string is the enrolled legal name (EXACT_LEGAL_NAME, MEDIUM). "
         else paste0(WV_INV_BRIDGE_WHY[[a]], "LEGAL_NAME_TRUNCATED, LOW. "),
         "The release itself calls it a hospital and states no other form.")
}
WV_INV_HOSP <- function(a, quote) {
  tibble::tibble(
    key = "inv", date = "2026-09-30", initiative = WV_INV_INITIATIVE,
    awardee = a, amount = NA_real_, quote = quote,
    recipient_type = "HOSPITAL_OR_SYSTEM",
    basis_type = ifelse(WV_INV_ENROL$match[WV_INV_ENROL$awardee == a] == "EXACT_LEGAL_NAME",
                        "ORG_WEBSITE", "GENERAL_KNOWLEDGE"),
    flow_type = "DIRECT", dist = "Yes", why = wv_inv_why(a), rounded = FALSE)
}
WV_AWARDS_S100 <- dplyr::bind_rows(
  purrr::map_dfr(c("Stonewall Jackson Memorial Hospital",
                   "Mon Health Marion Neighborhood Hospital",
                   "Preston Memorial Hospital", "Plateau Medical Center",
                   "Webster Memorial Hospital"), WV_INV_HOSP, quote = WV_INV_FIVE),
  WV_INV_HOSP("Broaddus Hospital",
              "Broaddus Hospital received funding to establish the Mansfield Place TeleHub Pilot"),
  tibble::tibble(
    key = "inv", date = "2026-09-30", initiative = WV_INV_INITIATIVE,
    awardee = "Vandalia Health", amount = NA_real_,
    quote = "Vandalia Health received an additional award to help rural hospitals and clinics fill critical staffing shortages",
    recipient_type = "HOSPITAL_OR_SYSTEM", basis_type = "GENERAL_KNOWLEDGE",
    flow_type = "DIRECT", dist = "Yes",
    why = paste0(
      "OWNER RULING (session 101, WV_VANDALIA_SYSTEM_PARENT resolved at (b)): ",
      "a SYSTEM PARENT, typed HOSPITAL_OR_SYSTEM on the system-parent rulings ",
      "(Sanford/Avera, Valley Health/Ballad/Sentara, Guthrie, Mercy) -- LOW, ",
      "GENERAL_KNOWLEDGE, no CCN, $0. No CMS enrolment carries this legal name: ",
      "its hospitals enrol as 'VANDALIA HEALTH <hospital>' DBAs (CAMC, Davis, ",
      "Webster, Broaddus), and a prefix is never matched by machine (§2). The ",
      "award helps 'rural hospitals and clinics' fill staffing; PRIOR CODING ",
      "(session 100): §8's fallback, PASS_THROUGH_UNRESOLVED, Unclear."),
    rounded = FALSE))
WV_AWARDS <- dplyr::bind_rows(WV_AWARDS, WV_AWARDS_S100)

# Session 103: the four 2026-10-13/14 releases the probe passed as CHANGED
# (headlines say "Investment" and "$X to Strengthen", not "award"). Owner
# approval, session 103. WVU EYE INSTITUTE: no CMS WV enrolment carries
# "WVU Eye Institute" or any "Eye" string on a hospital record; the enrolled
# legal entity, WEST VIRGINIA UNIVERSITY HOSPITALS INC (CCN 510001), is not
# named, and §10.2 never reaches a sub-unit named without its legal entity.
# Session 103 coded it Unclear on the owner's instruction; SESSION 104's owner
# ruling makes it UNIVERSITY_OR_AHC / NON_HOSPITAL. LAUREN'S WISH ($211,700, same release as ARS) is
# Appalachian Regional Commission INSPIRE money, never a row (§0.1 mode 1).
WV_EYE_WHY <- paste0(
  "NON_HOSPITAL ON THE OWNER'S RULING (session 104; session 103 had it Unclear): ",
  "the release names 'the West Virginia University (WVU) Eye Institute', a unit of ",
  "the university, and states no other form. CMS Hospital Enrollments (",
  WV_INV_ENROL_FILE, ") carries WEST VIRGINIA UNIVERSITY HOSPITALS INC dba WVU ",
  "HOSPITALS (CCN 510001, Morgantown) and no hospital record whose name or DBA ",
  "contains 'Eye'; the enrolled legal entity is not named, so the row is not ",
  "bridged (§10.2, 'what it does not reach'). UNIVERSITY_OR_AHC / NON_HOSPITAL, ",
  "$0 of hospital money. WV_WVU_EYE_INSTITUTE_UNCLEAR resolved.")
WV_PPSF <- "Provider Productivity Support Fund"
WV_AWARDS_S103 <- tibble::tribble(
  ~key, ~date, ~initiative, ~awardee, ~amount, ~quote,
  ~recipient_type, ~basis_type, ~flow_type, ~dist, ~why, ~rounded,
  "eye", "2026-10-14", "Connected Care Grid",
  "West Virginia University (WVU) Eye Institute", 2000026,
  "announced a $2,000,026 West Virginia Rural Health Transformation Program (WV RHTP) award to the West Virginia University (WVU) Eye Institute",
  "UNIVERSITY_OR_AHC", "STATE_SOURCE", "NON_HOSPITAL", "No", WV_EYE_WHY, FALSE,
  "phg", "2026-10-14", paste0(WV_PPSF, " (the release's closing line; the award sentence names no initiative)"),
  "Potomac Highlands Guild", 500000,
  "announced a $500,000 Rural Health Transformation Program award to Potomac Highlands Guild",
  NA, NA, "NON_HOSPITAL", "No",
  "NON_HOSPITAL on the owner's approval (session 103): a mental-health and addiction-recovery provider ('has served these communities for more than 40 years'); the release states no form and no CMS WV hospital, FQHC or RHC enrolment carries the name, so §8's standing fallback, NOT promoted (§0.4).", FALSE,
  "pca", "2026-10-13", WV_PPSF,
  "West Virginia Primary Care Association (WVPCA)", 1656432,
  "includes a $1,656,432 award to the West Virginia Primary Care Association (WVPCA)",
  "NONPROFIT_CBO", "STATE_SOURCE", "NON_HOSPITAL", "No",
  "NON_HOSPITAL on the owner's approval (session 103): the state's association of community health centres, funding 'a statewide clinically integrated network, beginning with 16 community health center organizations'. Not a hospital association, so §10.2's association row is not reached; on no CMS WV enrolment.", FALSE,
  "pca", "2026-10-13", WV_PPSF,
  "Monongahela Valley Association of Health Centers (MVA)", 500000,
  "a $500,000 award to the Monongahela Valley Association of Health Centers (MVA)",
  "FQHC_OR_RHC", "STATE_SOURCE", "NON_HOSPITAL", "No",
  "The release: 'MVA, a Federally Qualified Health Center (FQHC)'; CMS FQHC Enrollments: MONONGAHELA VALLEY ASSOCIATION OF HEALTH CENTERS, INC (CCNs 511923, 511925, 511115). No hospital record.", FALSE,
  "ars", "2026-10-13", "Health to Prosperity",
  "Ascension Recovery Services (ARS)", 1500000,
  "announced a $1.5 million award to Ascension Recovery Services (ARS)",
  NA, NA, "NON_HOSPITAL", "No",
  "NON_HOSPITAL on the owner's approval (session 103): a recovery-services provider, not the Ascension health system; the release states no form and no CMS WV enrolment carries 'Ascension' or 'Recovery', so §8's standing fallback. The same release's $211,700 to Lauren's Wish is Appalachian Regional Commission INSPIRE money and is not a row.", TRUE)
WV_AWARDS <- dplyr::bind_rows(WV_AWARDS, WV_AWARDS_S103)
WV_S103_KEYS <- c("eye", "phg", "pca", "ars")

# Session 107: the 2026-10-19 release, "More Than $3.4 Million in Rural Health
# Transformation Awards to West Virginia United Health" (the 10-23 Routine's
# TRIPWIRE). Two awards to one recipient, "West Virginia United (WVU) Health
# System". Pre-approved under session 107's Task 3 (under $10M of hospital
# money, no new ruling): the recipient is a SYSTEM PARENT, typed on the
# system-parent rulings exactly as Vandalia Health was (session 101). No CMS WV
# enrolment carries its legal name; "WEST VIRGINIA UNIVERSITY HEALTH SYSTEM" is
# the DBA of WEIRTON MEDICAL CENTER INC (CCN 510023), a different legal body,
# and a DBA coincidence is never a bridge (§2). The CCG award is printed only as
# "more than $2.5 million": the row carries $2,500,000, the published floor,
# flagged AMOUNT_ROUNDED_IN_SOURCE, so the figure understates and never
# overstates. The $900,000 MSCF award is exact.
WV_WVU_WHY <- paste0(
  "SYSTEM PARENT (session 107), typed HOSPITAL_OR_SYSTEM on the system-parent ",
  "rulings (Vandalia Health session 101; Sanford/Avera, Valley Health/Ballad/",
  "Sentara, Guthrie, Mercy) -- LOW, GENERAL_KNOWLEDGE, no CCN. The release ",
  "names 'West Virginia United (WVU) Health System' and states no form; the ",
  "MSCF award deploys staff 'across multiple WVU Health facilities' to 'hospitals ",
  "experiencing staffing shortages'. CMS Hospital Enrollments (",
  WV_INV_ENROL_FILE, ") carries no record under this legal name: its flagship ",
  "enrols as WEST VIRGINIA UNIVERSITY HOSPITALS INC (CCN 510001), which the ",
  "release does not name, and 'WEST VIRGINIA UNIVERSITY HEALTH SYSTEM' is only ",
  "the DBA of WEIRTON MEDICAL CENTER INC (CCN 510023), a different legal body, so ",
  "nothing is bridged (§2). Not the session-104 WVU Eye Institute or the ",
  "session-54 Center for Nursing Education rulings: those named university ",
  "units, this names the health system.")
WV_AWARDS_S107 <- tibble::tribble(
  ~key, ~date, ~initiative, ~awardee, ~amount, ~quote,
  ~recipient_type, ~basis_type, ~flow_type, ~dist, ~why, ~rounded,
  "wvu", "2026-10-19", "Connected Care Grid",
  "West Virginia United (WVU) Health System", 2500000,
  "One of the awards, totaling more than $2.5 million through the State's Connected Care Grid (CCG) initiative",
  "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "DIRECT", "Yes", WV_WVU_WHY, TRUE,
  "wvu", "2026-10-19", "Mountain State Care Force",
  "West Virginia United (WVU) Health System", 900000,
  "A second award of $900,000 through the Mountain State Care Force (MSCF) initiative",
  "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "DIRECT", "Yes", WV_WVU_WHY, FALSE)
WV_AWARDS <- dplyr::bind_rows(WV_AWARDS, WV_AWARDS_S107)
WV_S107_KEYS <- "wvu"

# Session 112: the two releases the 10-30 Routine's name check found
# (2026-10-26 WVU Cancer Institute, 2026-10-27 Williamson Health & Wellness
# Center). Both priced, exact, neither a hospital row.
#   * WILLIAMSON HEALTH & WELLNESS CENTER is the EXACT legal name of an FQHC on
#     CMS FQHC Enrollments (WILLIAMSON HEALTH & WELLNESS CENTER INC, CCN 511032
#     and eleven more sites). It is NOT Williamson Memorial Hospital: CMS
#     Hospital Enrollments carry WILLIAMSON MEMORIAL INC (CCN 510094) whose DBA
#     is "WILLIAMSON HEALTH & WELLNESS CENTER- BEHAVIORAL MEDICINE CLINIC" -- a
#     DBA of a different legal body, which is never a bridge (§2; the session-107
#     Weirton precedent). The awardee string is the FQHC's own legal name.
#   * WVU CANCER INSTITUTE is a university unit named without its legal entity:
#     UNIVERSITY_OR_AHC / NON_HOSPITAL on the session-104 WVU Eye Institute
#     owner ruling. The release does not name West Virginia University Hospitals.
WV_WHWC_WHY <- paste0(
  "FQHC on CMS FQHC Enrollments (data/evidence/federal_records/2026-09-23/",
  "cms_fqhc_enrollments_WV.json): ORGANIZATION NAME 'WILLIAMSON HEALTH & WELLNESS ",
  "CENTER INC' (CCN 511032, Williamson; eleven further FQHC sites) -- the awardee's ",
  "own legal name. The release states no form ('the center's New Heights ",
  "recovery-to-work program'). NOT a hospital: CMS Hospital Enrollments (",
  WV_INV_ENROL_FILE, ") carry WILLIAMSON MEMORIAL INC (CCN 510094) with DBA ",
  "'WILLIAMSON HEALTH & WELLNESS CENTER- BEHAVIORAL MEDICINE CLINIC', a DBA of a ",
  "different legal body, never a bridge (§2). FQHC_OR_RHC / NON_HOSPITAL, $0 of ",
  "hospital money.")
WV_CANCER_WHY <- paste0(
  "NON_HOSPITAL ON THE SESSION-104 OWNER RULING (WVU Eye Institute): the release ",
  "names 'the WVU Cancer Institute', a unit of the university, and states no other ",
  "form. CMS Hospital Enrollments (", WV_INV_ENROL_FILE, ") carry WEST VIRGINIA ",
  "UNIVERSITY HOSPITALS INC dba WVU HOSPITALS (CCN 510001) and no hospital record ",
  "whose name or DBA contains 'Cancer'; the enrolled legal entity is not named, so ",
  "the row is not bridged (§10.2, 'what it does not reach'). UNIVERSITY_OR_AHC / ",
  "NON_HOSPITAL, $0 of hospital money.")
WV_AWARDS_S112 <- tibble::tribble(
  ~key, ~date, ~initiative, ~awardee, ~amount, ~quote,
  ~recipient_type, ~basis_type, ~flow_type, ~dist, ~why, ~rounded,
  "can", "2026-10-26", "Connected Care Grid",
  "WVU Cancer Institute", 1339077,
  "announced a $1,339,077 Rural Health Transformation Program award to the WVU Cancer Institute",
  "UNIVERSITY_OR_AHC", "STATE_SOURCE", "NON_HOSPITAL", "No", WV_CANCER_WHY, FALSE,
  "whwc", "2026-10-27", "Not named in the release (New Heights recovery-to-work program)",
  "Williamson Health & Wellness Center", 250000,
  "announced a $250,000 award to Williamson Health & Wellness Center through West Virginia's Rural Health Transformation Program",
  "FQHC_OR_RHC", "ORG_WEBSITE", "NON_HOSPITAL", "No", WV_WHWC_WHY, FALSE)
WV_AWARDS <- dplyr::bind_rows(WV_AWARDS, WV_AWARDS_S112)
WV_S112_KEYS <- c("can", "whwc")

# Session 115: the 2026-10-30 CAMC release, found by the 11-06 Routine's name
# check. "more than $3.9 million in West Virginia Rural Health Transformation
# Program (WV RHTP) awards to Charleston Area Medical Center (CAMC)": three
# awards, each printed exactly, summing to $3,930,266. Typed exactly as the
# 09-04 'CAMC/Vandalia Health' row (CCN 510022, ORG_WEBSITE, MEDIUM, no CCN on
# the row). A separate award from that row: different amount, date and
# programme; the release does not relate them.
WV_CAMC_WHY <- paste0(
  "CMS Hospital Enrollments (", WV_INV_ENROL_FILE, "): CHARLESTON AREA MEDICAL ",
  "CENTER INC dba VANDALIA HEALTH CHARLESTON AREA MEDICAL CENTER, CCN 510022 -- ",
  "the awardee's own name. The activities (provider training, APP fellows, ",
  "workforce health liaisons) do not decide it; §0.3a judges the recipient.")
WV_AWARDS_S115 <- tibble::tribble(
  ~key, ~date, ~initiative, ~awardee, ~amount, ~quote,
  ~recipient_type, ~basis_type, ~flow_type, ~dist, ~why, ~rounded,
  "camc", "2026-10-30", "Mountain State Care Force",
  "Charleston Area Medical Center (CAMC)", 500000,
  "A $500,000 award will expand hands-on clinical education, simulation-enhanced training, and virtual mentorship",
  "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "DIRECT", "Yes", WV_CAMC_WHY, FALSE,
  "camc", "2026-10-30", "Mountain State Care Force",
  "Charleston Area Medical Center (CAMC)", 1693946,
  "A $1,693,946 award focused on Kanawha County",
  "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "DIRECT", "Yes", WV_CAMC_WHY, FALSE,
  "camc", "2026-10-30", "Health to Prosperity",
  "Charleston Area Medical Center (CAMC)", 1736320,
  "A $1,736,320 award will support CAMC's Pathways to Success program",
  "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "DIRECT", "Yes", WV_CAMC_WHY, FALSE)
WV_AWARDS <- dplyr::bind_rows(WV_AWARDS, WV_AWARDS_S115)
WV_S115_KEYS <- "camc"

# Session 117a: the 2026-11-10 "Nearly $17 Million" release (seven awards, each
# printed exactly, $16,976,480), found by the 11-13 Routine's name check and
# extracted on the standing pre-approval. Announced after 10-30, but the 11-09
# Year 2 release says all 145 Year 1 agreements were "finalized ahead of the
# October 30 federal deadline", so these are Budget Period 1 awards.
#   * CABELL HUNTINGTON HOSPITAL is the exact DBA (and legal name less 'INC') on
#     CMS Hospital Enrollments, CCN 510055, Huntington: a hospital row, typed as
#     the CAMC rows are (no CCN on the row; HIGH needs Stage 5).
#   * MARSHALL UNIVERSITY RESEARCH CORPORATION is the university's research
#     corporation: UNIVERSITY_OR_AHC / NON_HOSPITAL (no CMS hospital record).
#   * WVPCA: NON_HOSPITAL on the session-103 owner approval (same recipient).
#   * ROAM WEST VIRGINIA: the release states no form and no CMS WV enrolment
#     carries the name; the Potomac Highlands Guild precedent (NON_HOSPITAL).
WV_CABELL_WHY <- paste0(
  "CMS Hospital Enrollments (", WV_INV_ENROL_FILE, "): CABELL HUNTINGTON HOSPITAL ",
  "INC dba CABELL HUNTINGTON HOSPITAL, CCN 510055, Huntington, general/acute -- the ",
  "awardee's own name ('Cabell Huntington Hospital, under Marshall Health Network'). ",
  "Care coordination does not decide it; §0.3a judges the recipient.")
WV_MURC_WHY <- paste0(
  "UNIVERSITY_OR_AHC / NON_HOSPITAL: Marshall University Research Corporation is ",
  "Marshall University's sponsored-research corporation (general knowledge; the ",
  "release states no form). No CMS WV hospital record carries the name, and the ",
  "release names no enrolled hospital as the recipient.")
WV_ROAM_WHY <- paste0(
  "NON_HOSPITAL on the Potomac Highlands Guild precedent (session 103): the release ",
  "states no form ('ROAM West Virginia to recruit and train licensed practical nurse ",
  "apprentices'; 'in-home foot scanning and nursing review') and no CMS WV hospital, ",
  "FQHC or RHC enrolment carries the name; §8's standing fallback, NOT promoted (§0.4).")
WV_DIA_INIT <- "One of: Personal Health Accelerator, Connected Care Grid, SmartCare Catalyst, Mountain State Care Force (the release maps no award to an initiative)"
WV_AWARDS_S117 <- tibble::tribble(
  ~key, ~date, ~initiative, ~awardee, ~amount, ~quote,
  ~recipient_type, ~basis_type, ~flow_type, ~dist, ~why, ~rounded,
  "dia", "2026-11-10", WV_DIA_INIT, "Marshall University Research Corporation", 5043333,
  "$5,043,333 to Marshall University Research Corporation",
  "UNIVERSITY_OR_AHC", "GENERAL_KNOWLEDGE", "NON_HOSPITAL", "No", WV_MURC_WHY, FALSE,
  "dia", "2026-11-10", WV_DIA_INIT, "Marshall University Research Corporation", 4640188,
  "$4,640,188 to Marshall University Research Corporation",
  "UNIVERSITY_OR_AHC", "GENERAL_KNOWLEDGE", "NON_HOSPITAL", "No", WV_MURC_WHY, FALSE,
  "dia", "2026-11-10", WV_DIA_INIT, "West Virginia Primary Care Association", 2795000,
  "$2,795,000 to the West Virginia Primary Care Association",
  "NONPROFIT_CBO", "STATE_SOURCE", "NON_HOSPITAL", "No",
  "NON_HOSPITAL on the owner's approval (session 103): the state's association of community health centres ('expand diabetes management through community health centers'); not a hospital association; on no CMS WV enrolment.", FALSE,
  "dia", "2026-11-10", WV_DIA_INIT, "Marshall University Research Corporation", 1753646,
  "$1,753,646 to Marshall University Research Corporation",
  "UNIVERSITY_OR_AHC", "GENERAL_KNOWLEDGE", "NON_HOSPITAL", "No", WV_MURC_WHY, FALSE,
  "dia", "2026-11-10", WV_DIA_INIT, "Cabell Huntington Hospital", 1544313,
  "$1,544,313 to Cabell Huntington Hospital",
  "HOSPITAL_OR_SYSTEM", "STATE_SOURCE", "DIRECT", "Yes", WV_CABELL_WHY, FALSE,
  "dia", "2026-11-10", WV_DIA_INIT, "ROAM West Virginia", 700000,
  "$700,000 to ROAM West Virginia",
  NA, NA, "NON_HOSPITAL", "No", WV_ROAM_WHY, FALSE,
  "dia", "2026-11-10", WV_DIA_INIT, "ROAM West Virginia", 500000,
  "$500,000 to ROAM West Virginia",
  NA, NA, "NON_HOSPITAL", "No", WV_ROAM_WHY, FALSE)
WV_AWARDS <- dplyr::bind_rows(WV_AWARDS, WV_AWARDS_S117)
WV_S117_KEYS <- "dia"

# Session 121 (Task 7): the 11-16 community paramedicine and 11-19 recovery
# releases, found by the 11-20 Routine's article check and extracted on the
# standing pre-approval. Both are announced after 10-30; they are Year 1 on a
# STATE SOURCE DATE (session 121 owner ruling, CLAUDE.md §7): the 11-09 Year 2
# release says every Year 1 agreement was "finalized ahead of the October 30
# federal deadline" (WV_Y2_RELEASE), the 117a precedent. Both footers print
# FY2026 + FY2027 ($401,557,453.35, "combined Year 1 and Year 2 funding").
#   * WEST VIRGINIA UNIVERSITY HOSPITALS, INC. is the exact legal name on CMS
#     Hospital Enrollments (WEST VIRGINIA UNIVERSITY HOSPITALS INC, CCN 510001,
#     Morgantown): a hospital row, typed as Cabell's (no CCN on the row). The
#     money serves WVU's Rockefeller Neuroscience Institute ("on behalf of
#     RNI"); §0.3a judges the recipient, and the recipient is the hospital.
#   * WEST VIRGINIA UNITED HEALTH SYSTEM and "WEST VIRGINIA UNIVERSITY (WVU)
#     MEDICINE" (the system's trading name) are the session-107 SYSTEM PARENT:
#     LOW, GENERAL_KNOWLEDGE, no CCN. Counter-argument recorded: "WVU Medicine"
#     could be read as the university's medical school; the release describes
#     a care-delivery programme run with EMS agencies and home health, which is
#     the health system's, and session 54 typed only NAMED UNITS of WVU
#     (Center for Nursing Education) as the university.
#   * The $9.3M headline's other $3,000,000 (WVUIC incubator labs) is "from the
#     Office of Economic Development": STATE money, §0.1 mode 1, no row.
WV_WVUH_WHY <- paste0(
  "CMS Hospital Enrollments (", WV_INV_ENROL_FILE, "): WEST VIRGINIA UNIVERSITY ",
  "HOSPITALS INC, CCN 510001, Morgantown -- the awardee's own legal name ('Awarded ",
  "to West Virginia University Hospitals, Inc., on behalf of RNI'). The recovery ",
  "platform serves WVU's Rockefeller Neuroscience Institute; §0.3a judges the ",
  "recipient. Year 1 on the 11-09 release's 'finalized ahead of the October 30 ",
  "federal deadline' (session 121 date rule).")
WV_WVU_S121_WHY <- paste0(WV_WVU_WHY, " Session 121: the same system parent, ",
  "named here as '", c("West Virginia United Health System", "West Virginia University (WVU) Medicine"),
  "'. Year 1 on the 11-09 release's 'finalized ahead of the October 30 federal ",
  "deadline' (session 121 date rule).")
WV_AWARDS_S121 <- tibble::tribble(
  ~key, ~date, ~initiative, ~awardee, ~amount, ~quote,
  ~recipient_type, ~basis_type, ~flow_type, ~dist, ~why, ~rounded,
  "rni", "2026-11-19", "Personal Health Accelerator / Rural Health Link (the release names the pair for both awards)",
  "West Virginia University Hospitals, Inc.", 3000000,
  "Awarded to West Virginia University Hospitals, Inc., on behalf of RNI",
  "HOSPITAL_OR_SYSTEM", "STATE_SOURCE", "DIRECT", "Yes", WV_WVUH_WHY, FALSE,
  "rni", "2026-11-19", "Personal Health Accelerator / Rural Health Link (the release names the pair for both awards)",
  "West Virginia United Health System", 3382229,
  "Recovery Access Coordination Hub ($3,382,229): Awarded to West Virginia United Health System, on behalf of the RNI Addiction Ecosystem",
  "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "DIRECT", "Yes", WV_WVU_S121_WHY[1], FALSE,
  "cp", "2026-11-16", "Connected Care Grid",
  "West Virginia University (WVU) Medicine", 1144689,
  "announced a $1,144,689 award to West Virginia University (WVU) Medicine through the Connected Care Grid (CCG) initiative",
  "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "DIRECT", "Yes", WV_WVU_S121_WHY[2], FALSE)
WV_AWARDS <- dplyr::bind_rows(WV_AWARDS, WV_AWARDS_S121)
WV_S121_KEYS <- c("rni", "cp")
WV_BP1_BP2_FOOTER_KEYS <- c("dia", WV_S121_KEYS)
# Its footer prints BP1 + the FULL Year 2 award ($401,557,453 = $199,476,099 +
# $202,081,354), which rhtp_footer_class() does not know (it knows only the
# $100M initial award). Checked here against the 11-09 Year 2 release instead
# of widening the shared check.
WV_DIA_FOOTER <- 401557453
WV_Y2_RELEASE <- file.path("data", "evidence", "recheck", "2026-11-13", "WV",
                           "2026-11-13_wv_gov_202m_year2_100pct_obligated.html")

# Each release's own headline total, which the priced rows must not exceed
# (CCWV) or which bounds the unpriced remainder (Minnie Hamilton).
WV_CCWV_TOTAL <- 1103614     # "more than $1.1 million": the four rows, exactly

wv_assert_sources <- function() {
  for (i in seq_len(nrow(WV_AWARDS))) {
    a <- WV_AWARDS[i, ]
    t <- wv_text(a$key)
    if (!grepl(a$quote, t, fixed = TRUE)) {
      stop("[WV] the ", a$key, " release no longer says '", a$quote, "'.",
           call. = FALSE)
    }
    if (!grepl("Rural Health Transformation Program", t, fixed = TRUE)) {
      stop("[WV] the ", a$key, " release no longer names the RHTP.", call. = FALSE)
    }
  }
  # §0.2: the footer on every release prints the ALLOTMENT.
  for (k in setdiff(names(WV_PATHS), WV_BP1_BP2_FOOTER_KEYS)) {
    rhtp_assert_footer_text_tier(wv_text(k), WV_STATE, "STATE_ALLOTMENT",
                                 label = paste("WV", k, "footer"))
  }
  if (abs(sum(WV_AWARDS$amount, na.rm = TRUE) - WV_TOTAL) > 0.005) {
    stop("[WV] the priced awards no longer sum to WV_TOTAL.", call. = FALSE)
  }
  if (sum(WV_AWARDS$amount[WV_AWARDS$key == "ccwv"]) != WV_CCWV_TOTAL ||
      !grepl("more than $1.1 million", wv_text("ccwv"), fixed = TRUE)) {
    stop("[WV] CCWV's four awards no longer make its 'more than $1.1 million'.",
         call. = FALSE)
  }
  if (!grepl("More Than $4 Million", wv_text("mh"), fixed = TRUE)) {
    stop("[WV] Minnie Hamilton's release no longer says 'More Than $4 Million'.",
         call. = FALSE)
  }
  inv <- wv_text("inv")
  if (!grepl("more than $3.2 million", inv, fixed = TRUE) ||
      !grepl("Today's awards", inv, fixed = TRUE) ||
      !grepl("Additional awards will be announced", inv, fixed = TRUE)) {
    stop("[WV] the 09-30 Investments release no longer reads as a partial ",
         "award release of 'more than $3.2 million'.", call. = FALSE)
  }
  # §6.2: it prices no single award, so no row may carry one.
  if (any(!is.na(WV_AWARDS$amount[WV_AWARDS$key == "inv"]))) {
    stop("[WV] a 09-30 Investments row carries an amount the release does not print.",
         call. = FALSE)
  }
  # Session 103: WVPCA + MVA make the release's "nearly $2.2 million"; the
  # ARS release's "More Than $1.7 Million" includes $211,700 of ARC money.
  if (sum(WV_AWARDS$amount[WV_AWARDS$key == "pca"]) != 2156432 ||
      !grepl("nearly $2.2 million in Rural Health Transformation Program awards", wv_text("pca"), fixed = TRUE)) {
    stop("[WV] WVPCA + MVA no longer make the release's 'nearly $2.2 million'.", call. = FALSE)
  }
  ars <- wv_text("ars")
  if (!grepl("Lauren's Wish CAREERS Program will receive $211,700 in Appalachian Regional Commission funding", ars, fixed = TRUE)) {
    stop("[WV] the ARS release no longer marks Lauren's Wish as ARC money.", call. = FALSE)
  }
  # Session 107: the CCG floor plus the exact MSCF award make the headline's
  # "More Than $3.4 Million", and the CCG figure is a floor ("more than").
  wvu <- wv_text("wvu")
  if (sum(WV_AWARDS$amount[WV_AWARDS$key == "wvu"]) != 3400000 ||
      !grepl("More Than $3.4 Million", wvu, fixed = TRUE) ||
      !grepl("Additional awards will be announced", wvu, fixed = TRUE)) {
    stop("[WV] the WVU Health System release no longer reads as 'More Than ",
         "$3.4 Million' in two awards with more to follow.", call. = FALSE)
  }
  # Session 117a: seven awards make "nearly $17 million"; the footer is BP1 + BP2.
  dia <- wv_text("dia")
  y2 <- paste(readLines(here::here(WV_Y2_RELEASE), warn = FALSE), collapse = " ")
  if (sum(WV_AWARDS$amount[WV_AWARDS$key == "dia"]) != 16976480 ||
      !grepl("nearly $17 million across seven", dia, fixed = TRUE) ||
      !grepl("financial assistance award totaling $401,557,453", dia, fixed = TRUE) ||
      !grepl("$202,081,355", y2, fixed = TRUE) ||
      abs(WV_DIA_FOOTER - rhtp_footer_allotments()$fy2026_allotment[
        rhtp_footer_allotments()$state == WV_STATE] - 202081355) > 2) {
    stop("[WV] the 11-10 release no longer reads as 'nearly $17 million' in seven ",
         "awards with a BP1 + BP2 footer.", call. = FALSE)
  }
  # Session 121: the two releases' sums and their FY2026 + FY2027 footers.
  rni <- wv_text("rni"); cp <- wv_text("cp")
  if (sum(WV_AWARDS$amount[WV_AWARDS$key == "rni"]) != 6382229 ||
      !grepl("more than $6.3 million in West Virginia Rural Health Transformation Program (WV RHTP) awards", rni, fixed = TRUE) ||
      !grepl("$3 million from the Office of Economic Development", rni, fixed = TRUE) ||
      !grepl("Digital Disease Management Platform ($3,000,000)", rni, fixed = TRUE) ||
      sum(WV_AWARDS$amount[WV_AWARDS$key == "cp"]) != 1144689 ||
      !all(grepl("financial assistance award totaling $401,557,453.35 in combined Year 1 and Year 2 funding",
                 c(rni, cp), fixed = TRUE)) ||
      !grepl("finalized ahead of the October 30 federal deadline", y2, fixed = TRUE)) {
    stop("[WV] the 11-16/11-19 releases no longer read as $6,382,229 (two RHTP awards; ",
         "the OED $3M is state money) and $1,144,689, with BP1 + BP2 footers and the ",
         "11-09 'finalized ahead of the October 30' sentence.", call. = FALSE)
  }
  # Session 115: the three CAMC awards make "more than $3.9 million".
  camc <- wv_text("camc")
  if (sum(WV_AWARDS$amount[WV_AWARDS$key == "camc"]) != 3930266 ||
      !grepl("more than $3.9 million", camc, fixed = TRUE) ||
      !grepl("Charleston Area Medical Center (CAMC)", camc, fixed = TRUE)) {
    stop("[WV] the CAMC release no longer reads as 'more than $3.9 million' in ",
         "three awards to Charleston Area Medical Center.", call. = FALSE)
  }
  if (!all(as.Date(WV_AWARDS$date) > WV_NOA_DATE)) stop("[WV] date test.")
  invisible(TRUE)
}

wv_year1_release_rows <- function() {
  a <- WV_AWARDS
  cls <- rhtp_classify_recipient_type(a$awardee, WV_STATE)
  typed <- !is.na(a$recipient_type)
  rtype <- ifelse(typed, a$recipient_type, cls$recipient_type)
  conf <- dplyr::case_when(!typed ~ cls$determination_confidence,
                           a$basis_type == "GENERAL_KNOWLEDGE" ~ "LOW",
                           TRUE ~ "MEDIUM")
  flag <- ifelse(!typed, "RECIPIENT_TYPE_INFERRED", NA_character_)
  flag <- ifelse(a$rounded, ifelse(is.na(flag), "AMOUNT_ROUNDED_IN_SOURCE",
                                   paste0(flag, ";AMOUNT_ROUNDED_IN_SOURCE")), flag)
  flag <- ifelse(is.na(a$amount),
                 ifelse(!typed, "RECIPIENT_TYPE_INFERRED;AMOUNT_MISSING", "AMOUNT_MISSING"),
                 flag)
  hosp <- a$dist == "Yes"
  mh <- a$key == "mh"
  inv <- a$key == "inv"
  s85 <- a$key %in% c("ccwv", "mh")
  ie <- WV_INV_ENROL[match(a$awardee, WV_INV_ENROL$awardee), ]
  ie_hit <- inv & !is.na(ie$ccn)
  conf <- ifelse(ie_hit & ie$match != "EXACT_LEGAL_NAME", "LOW", conf)
  tibble::tibble(
    state = WV_STATE,
    row_no = seq_len(nrow(a)),
    awardee = a$awardee,
    amount = a$amount,
    recipient_type = rtype,
    distributed_to_hospital = a$dist,
    note = ifelse(
      inv,
      paste0("One of seven recipients in the 'More Than $3.2 Million in Rural ",
             "Health Transformation Investments' release of ", a$date,
             "; the release prices no single award, and its total is NOT ",
             "divided (§6.2). 'Additional awards will be announced'."),
      ifelse(
      mh & is.na(a$amount),
      paste0("One of three Minnie Hamilton projects in the 'More Than $4 ",
             "Million' release of ", a$date, "; the release prices only the ",
             "$1.7M mobile clinic, and the remainder is NOT divided (§6.2)."),
      paste0(a$initiative, " award, announced ", a$date,
             " by Governor Morrisey. 'Additional Rural Health ",
             "Transformation Program awards will be announced'."))),
    recipient_confirmed = "Yes",
    amount_confirmed = ifelse(a$rounded | is.na(a$amount), "No", "Yes"),
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = paste("WV Department of Health release,", a$date),
    state_source_url = paste0(WV_URL, WV_SLUG[a$key]),
    validation_source_type = "GOVERNOR_PRESS_RELEASE",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03av_wv_year1_awardees.R",
    ccn = ifelse(mh, "511303", ifelse(ie_hit, ie$ccn, NA_character_)),
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    initiative = a$initiative,
    recipient_type_source = ifelse(
      typed, paste0(ifelse(a$key %in% WV_S121_KEYS, "TYPED (session 121): ", ifelse(a$key %in% WV_S117_KEYS, "TYPED (session 117a): ", ifelse(a$key %in% WV_S115_KEYS, "TYPED (session 115): ", ifelse(a$key %in% WV_S112_KEYS, "TYPED (session 112): ", ifelse(a$key %in% WV_S107_KEYS, "TYPED (session 107): ", ifelse(a$key %in% WV_S103_KEYS, "TYPED (session 103): ", ifelse(inv, "TYPED (session 100): ",
                           ifelse(s85, "TYPED (session 85): ", "TYPED (session 54): ")))))))),
                    a$why, " Classifier said ",
                    cls$recipient_type, "/", cls$determination_confidence, "."),
      paste0("rhtp_classify_recipient_type() on the name: ",
             cls$recipient_type, "/", cls$determination_confidence, ". ", a$why)),
    determination_confidence = conf,
    flag_reason = flag,
    award_pool = a$initiative,
    budget_period = "Budget Period 1",
    flow_type = a$flow_type,
    hospital_benefiting = ifelse(hosp, "Yes",
                                 ifelse(a$key %in% c("nurs", "hin") |
                                          a$awardee == "Vandalia Health", "Yes", "Unclear")),
    hospital_attribution = ifelse(hosp, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = ifelse(
      hosp, paste0("§10.2 DIRECT: ", a$why),
      paste0("§10.2 ", a$flow_type, ": ", a$why)),
    amount_basis = dplyr::case_when(
      inv ~ "NOT PRICED: the 2026-09-30 release prints only 'more than $3.2 million' across seven recipients and prices none; never divided (§6.2).",
      is.na(a$amount) ~ "NOT PRICED: the release prices one of Minnie Hamilton's three projects; the rest of 'More Than $4 Million' is not divided (§6.2).",
      a$awardee == "Ascend WV" ~ "ROUNDED IN SOURCE: printed only as '$2.4 million'.",
      a$key == "ars" ~ "ROUNDED IN SOURCE: printed only as '$1.5 million'. The headline's '$1.7 million' adds ARC money and is not this row's total.",
      a$key == "wvu" & a$rounded ~ "A FLOOR IN SOURCE: printed only as 'more than $2.5 million'; $2,500,000 is the published lower bound, never reconstructed upward. Kept at $2,500,000 on the owner's ruling (session 108).",
      a$rounded ~ "ROUNDED IN SOURCE: printed only as '$1.7 million'.",
      TRUE ~ "EXACT, as printed in the release."),
    basis_type = a$basis_type,
    round_amount = NA_real_,
    announcement_date = as.Date(a$date),
    source_archive_path = unname(WV_PATHS[a$key]),
    recipient_subtype = NA_character_,
    cms_enrolment_match = ifelse(mh, "EXACT_LEGAL_NAME",
                                 ifelse(ie_hit, ie$match, NA_character_)),
    cms_enrolment_record = ifelse(mh, WV_MH_ENROLMENT,
                                  ifelse(ie_hit, paste0("CMS Hospital Enrollments (",
                                                        WV_INV_ENROL_FILE, "): ",
                                                        ie$cms_org, ", CCN ", ie$ccn),
                                         NA_character_)))
}


# -- session 121: the Year 1 "Released Awards" roster --------------------------
#
# SESSION 121 (Task 7). health.wv.gov/funding-opportunities (the old
# /grant-opportunities path now redirects there) links "Year 1 Released Awards
# File: RHTP Released Awards.pdf" -- WV Department of Health's own roster of
# Year 1 awards: initiative, activity, organisation, "Awarded Amount", service
# area and summary, closing "Total Announced (67 awards): $108,261,312.68".
# It is the STATE'S OWN AWARD LIST and the latest list governs (the CO and VT
# precedent): it prices the rows the releases left at $0 or as a floor, and it
# adds awards no release announced. It is a FLOOR ("Released", "Total
# Announced") against the 11-09 statement that all 145 Year 1 agreements were
# finalized by 10-30; nothing is computed for the rest.
#
# The PDF is read through poppler's word boxes (pdftotext -bbox, version
# 24.02.0), committed beside it, because the cloud reader carries no table
# model; each row is anchored on its "$" amount, and the parse must reproduce
# the printed total to the cent and the printed count (67).
WV_RA_DIR  <- file.path("data", "evidence", "recheck", "2026-11-20", "WV")
WV_RA_PDF  <- file.path(WV_RA_DIR, "2026-11-20_wv_rhtp_released_awards_year1.pdf")
WV_RA_BBOX <- file.path(WV_RA_DIR, "2026-11-20_wv_rhtp_released_awards_year1.pdftotext_bbox.html")
WV_RA_URL  <- "https://health.wv.gov/sites/default/files/2026-11/RHTP%20Released%20Awards_1.pdf"
WV_RA_TOTAL <- 108261312.68
WV_RA_COUNT <- 67L
WV_RA_COLS <- c(activity = 60, org = 166, amount = 281, area = 378, summary = 505)

wv_ra_words <- function(path = here::here(WV_RA_BBOX)) {
  x <- xml2::read_html(path)
  pages <- xml2::xml_find_all(x, "//page")
  dplyr::bind_rows(lapply(seq_along(pages), function(p) {
    w <- xml2::xml_find_all(pages[[p]], ".//word")
    tibble::tibble(page = p, t = xml2::xml_text(w),
                   x0 = as.numeric(xml2::xml_attr(w, "xmin")),
                   y0 = as.numeric(xml2::xml_attr(w, "ymin")))
  }))
}

#' One row per award, in document order
wv_ra_parse <- function(path = here::here(WV_RA_BBOX)) {
  w <- wv_ra_words(path) %>%
    dplyr::mutate(col = cut(.data$x0, c(WV_RA_COLS, Inf), labels = names(WV_RA_COLS), right = FALSE),
                  key = .data$page * 1e4 + .data$y0)
  # initiative headers ("Initiative: Connected Care Grid (CCG)") and the total line
  init <- w %>% dplyr::filter(.data$t == "Initiative:") %>% dplyr::select(page, y0, key)
  init$name <- vapply(seq_len(nrow(init)), function(i) {
    l <- w[w$page == init$page[i] & abs(w$y0 - init$y0[i]) < 2 & w$t != "Initiative:", ]
    paste(l$t[order(l$x0)], collapse = " ")
  }, character(1))
  tot_i <- which(w$t == "Total")
  amt <- w %>% dplyr::filter(.data$col == "amount", grepl("^\\$[0-9]", .data$t), !.data$key %in% c()) %>%
    dplyr::arrange(.data$key)
  tot_key <- if (length(tot_i)) w$key[tot_i[1]] else Inf
  amt <- amt[amt$key < tot_key - 1, ]
  ends <- c(amt$key[-1], tot_key) - 1
  # an initiative header also ends a row's text window
  ends <- vapply(seq_len(nrow(amt)), function(i) {
    nx <- init$key[init$key > amt$key[i] + 1]
    min(c(ends[i], nx - 1))
  }, numeric(1))
  txt <- function(colname, k0, k1) {
    l <- w[w$col == colname & w$key >= k0 - 2 & w$key < k1, ]
    l <- l[order(l$key, l$x0), ]
    stringr::str_squish(paste(l$t, collapse = " "))
  }
  out <- tibble::tibble(
    ra_row = seq_len(nrow(amt)),
    page = amt$page,
    initiative = vapply(amt$key, function(k) init$name[max(which(init$key < k))], character(1)),
    activity_raw = vapply(seq_len(nrow(amt)), function(i) txt("activity", amt$key[i], ends[i]), character(1)),
    organization = vapply(seq_len(nrow(amt)), function(i) txt("org", amt$key[i], ends[i]), character(1)),
    amount_text = amt$t,
    amount = as.numeric(gsub("[$,]", "", amt$t)),
    service_area = vapply(seq_len(nrow(amt)), function(i) txt("area", amt$key[i], ends[i]), character(1)),
    summary = vapply(seq_len(nrow(amt)), function(i) txt("summary", amt$key[i], ends[i]), character(1)))
  # an empty activity cell is the merged cell above it
  for (i in seq_len(nrow(out))) {
    if (!nzchar(out$activity_raw[i]) && i > 1 && out$initiative[i] == out$initiative[i - 1]) {
      out$activity_raw[i] <- out$activity_raw[i - 1]
    }
  }
  tl <- w[w$page == w$page[tot_i[1]] & abs(w$y0 - w$y0[tot_i[1]]) < 2, ]
  attr(out, "total_line") <- paste(tl$t[order(tl$x0)], collapse = " ")
  out
}

wv_ra_assert <- function(ra = wv_ra_parse()) {
  tl <- attr(ra, "total_line")
  if (!grepl(paste0("Total Announced (", WV_RA_COUNT, " awards): $108,261,312.68"), tl, fixed = TRUE)) {
    stop("[WV] the roster's total line is not 'Total Announced (67 awards): $108,261,312.68' (read: ", tl, ").", call. = FALSE)
  }
  if (nrow(ra) != WV_RA_COUNT || abs(sum(ra$amount) - WV_RA_TOTAL) > 0.005) {
    stop("[WV] the roster parses to ", nrow(ra), " rows / $", format(sum(ra$amount), nsmall = 2, big.mark = ","),
         ", not the printed 67 / $108,261,312.68.", call. = FALSE)
  }
  if (any(!nzchar(ra$organization))) stop("[WV] a roster row has no organisation.", call. = FALSE)
  invisible(TRUE)
}

# Each release row, mapped by hand to its roster row (read 2026-11-20, session
# 121). Every release row is on the roster; row 14 (Minnie Hamilton's AI
# documentation project) shares roster row 41 with row 13 (the drone project):
# the roster prices the two together at $2,363,000 ("Launches autonomous drone
# delivery ... and deploys AI ambient clinical listening"), so row 13 carries it
# and row 14 stays at $0, pointing at row 13 -- never divided (§6.2).
WV_RA_MAP <- tibble::tribble(
  ~row_no, ~ra_row,
  1, 15,  2, 17,  3, 16,  4, 30,  5, 7,   6, 23,  7, 43,  8, 1,   9, 6,   10, 24,
  11, 36, 12, 4,  13, 41, 14, 41, 15, 50, 16, 51, 17, 53, 18, 49, 19, 52, 20, 44,
  21, 31, 22, 9,  23, 45, 24, 42, 25, 46, 26, 19, 27, 11, 28, 32, 29, 5,  30, 20,
  31, 28, 32, 33, 33, 18, 34, 61, 35, 14, 36, 62, 37, 34, 38, 55, 39, 37, 40, 56,
  41, 59, 42, 63, 43, 3)
WV_RA_SIBLING <- c(`14` = 13)

# The roster-only awards' typing, read by hand where the roster or a federal
# record states the form; every other roster-only row takes the shared
# classifier on its name (§8's fallback where it states nothing).
WV_RA_HAND <- tibble::tribble(
  ~ra_row, ~recipient_type, ~basis_type, ~flow_type, ~dist, ~why,
  12, "FQHC_OR_RHC", "ORG_WEBSITE", "NON_HOSPITAL", "No",
  "CMS FQHC Enrollments (data/evidence/federal_records/2026-09-23/cms_fqhc_enrollments_WV.json): VALLEY HEALTH SYSTEMS, INC (Harts, Cedar Grove, Wayne ...). The West Virginia FQHC network, not Virginia's Valley Health hospital system.",
  40, "FQHC_OR_RHC", "ORG_WEBSITE", "NON_HOSPITAL", "No",
  "CMS FQHC Enrollments (data/evidence/federal_records/2026-09-23/cms_fqhc_enrollments_WV.json): VALLEY HEALTH SYSTEMS, INC; the roster's own summary says 'across a regional community health center network'.",
  13, "FQHC_OR_RHC", "ORG_WEBSITE", "NON_HOSPITAL", "No",
  "CMS FQHC Enrollments (data/evidence/federal_records/2026-09-23/cms_fqhc_enrollments_WV.json): RAINELLE MEDICAL CENTER INC, CCN 511817, Rainelle. An FQHC, not a hospital, whatever its name.",
  54, "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "DIRECT", "Yes",
  "§10.2 HOSPITAL-FOUNDATION ROW (session 49): the foundation of a NAMED hospital whose name it carries -- PLEASANT VALLEY HOSPITAL, INC. dba RIVERS HEALTH, CCN 510012, Point Pleasant (CMS Hospital Enrollments, data/evidence/federal_records/2026-09-23/cms_hosp_enrollments_WV.json); the roster prints '(under Rivers Health Foundation)'. The parent tie is a reading, so LOW.",
  57, "UNIVERSITY_OR_AHC", "GENERAL_KNOWLEDGE", "NON_HOSPITAL", "No",
  "The West Virginia School of Osteopathic Medicine is a state medical school (general knowledge; the roster states no form); it is on no CMS WV hospital enrolment. The 11-06 Greenbrier release names Vandalia Health/CAMC and Greenbrier Valley Medical Center in the same story, but the roster names WVSOM as the organisation of this award: §0.3a judges the recipient.",
  25, "STATE_AGENCY", "STATE_SOURCE", "NON_HOSPITAL", "No",
  "A state agency named as the organisation; the roster: 'A qualified entity will be selected through a competitive process to carry out the work.' The eventual contractor is not named; never a hospital.",
  58, "STATE_AGENCY", "STATE_SOURCE", "NON_HOSPITAL", "No",
  "A state agency (WV Department of Environmental Protection); the roster: 'A qualified entity will be selected through a competitive process to carry out the work.' Water testing and filters; never a hospital.",
  26, "STATE_AGENCY", "STATE_SOURCE", "NON_HOSPITAL", "No",
  "The West Virginia Higher Education Policy Commission, a state agency (general knowledge); career-exposure outreach for high-school students; never a hospital.",
  22, "OTHER", "GENERAL_KNOWLEDGE", "NON_HOSPITAL", "No",
  "DETERMINED FORM: the West Virginia Jobs Investment Trust is a public venture-capital body created by state statute (general knowledge); the roster: 'Administers HealthTech Appalachia's accelerator and seed funding programs'. An administrator of a startup programme, not a hospital and not the awarding agency.",
  67, "EMS_OR_PSAP", "STATE_SOURCE", "NON_HOSPITAL", "No",
  "Grant Town Emergency Medical Services: an EMS agency by its own name ('Adds new ambulances and EMTs for medical transport').",
  39, "OTHER", "GENERAL_KNOWLEDGE", "NON_HOSPITAL", "No",
  "DETERMINED FORM: Hospice of Huntington is a hospice (general knowledge); 'Opens a new adult day center ... and funds a State PACE Director'. Not a hospital.",
  29, "OTHER", "GENERAL_KNOWLEDGE", "NON_HOSPITAL", "No",
  "DETERMINED FORM: the American College of Lifestyle Medicine is a physicians' professional society (general knowledge), not a college or university; the shared classifier's 'College' token is overridden here only. 'Trains rural clinicians and care teams in lifestyle medicine'.",
  2, "VENDOR_OR_CONTRACTOR", "GENERAL_KNOWLEDGE", "NON_HOSPITAL", "No",
  "IBM (International Business Machines), a technology vendor (general knowledge): 'Builds the State's health data spine, the shared data system all RHTP grantees will connect to'. A supplier to the state, never a hospital.")

#' The release rows priced or re-priced from the roster, and the roster-only rows appended
wv_apply_roster <- function(d, ra = wv_ra_parse()) {
  wv_ra_assert(ra)
  if (!setequal(WV_RA_MAP$row_no, d$row_no)) {
    stop("[WV] WV_RA_MAP must map every release row (", nrow(d), "); a new release row is mapped by hand.", call. = FALSE)
  }
  src <- paste0("WV Department of Health, 'West Virginia Rural Health Transformation Program (WV RHTP) - ",
                "Released Awards' (Year 1 Released Awards File, health.wv.gov/funding-opportunities, ",
                "fetched 2026-11-20; 'Total Announced (67 awards): $108,261,312.68')")
  d$wv_roster_row <- WV_RA_MAP$ra_row[match(d$row_no, WV_RA_MAP$row_no)]
  d$roster_organization <- ra$organization[d$wv_roster_row]
  d$roster_amount <- ra$amount[d$wv_roster_row]
  sib <- as.character(d$row_no) %in% names(WV_RA_SIBLING)
  d$roster_amount[sib] <- NA_real_
  move <- !sib & (is.na(d$amount) | abs(d$amount - d$roster_amount) > 0.005)
  prior <- d$amount
  d$amount[move] <- d$roster_amount[move]
  d$amount_confirmed[move] <- "Yes"
  d$validation_source_type[move] <- "NOTICE_OF_AWARD"
  strip <- function(f, codes) {
    out <- vapply(strsplit(dplyr::coalesce(f, ""), ";", fixed = TRUE),
                  function(x) paste(setdiff(x, codes), collapse = ";"), character(1))
    ifelse(nzchar(out), out, NA_character_)
  }
  d$flag_reason[move] <- strip(d$flag_reason[move], c("AMOUNT_ROUNDED_IN_SOURCE", "AMOUNT_MISSING"))
  d$amount_basis[move] <- paste0(
    ifelse(is.na(prior[move]), "PRICED", "RE-PRICED"), " FROM THE STATE'S YEAR 1 ROSTER (session 121): ", src,
    ", roster row ", d$wv_roster_row[move], " ('", d$roster_organization[move], "', ", ra$amount_text[d$wv_roster_row[move]], ").",
    ifelse(is.na(prior[move]), " The release printed no per-award amount.",
           paste0(" The release printed $", format(prior[move], big.mark = ",", scientific = FALSE),
                  "; the latest list governs (the CO and VT precedent).")),
    ifelse(d$row_no[move] == 13, " This roster row prices TWO of the release's projects together (drone delivery and AI ambient listening); row 14 points here and stays at $0, never divided (§6.2).", ""))
  d$amount_basis[sib] <- paste0("PRICED ON ROW ", WV_RA_SIBLING[as.character(d$row_no[sib])],
                                " (session 121): the roster's row 41 prices this project together with row 13's; never divided (§6.2).")
  d$note <- paste0(d$note, ifelse(is.na(d$wv_roster_row), "", paste0(" [Session 121: on the state's Year 1 roster, row ", d$wv_roster_row, ".]")))

  # the roster-only awards
  used <- unique(WV_RA_MAP$ra_row)
  nr <- ra[!ra$ra_row %in% used, ]
  cls <- rhtp_classify_recipient_type(nr$organization, WV_STATE)
  h <- WV_RA_HAND[match(nr$ra_row, WV_RA_HAND$ra_row), ]
  typed <- !is.na(h$recipient_type)
  rtype <- ifelse(typed, h$recipient_type, cls$recipient_type)
  dist <- ifelse(typed, h$dist, ifelse(rtype %in% c("HOSPITAL_OR_SYSTEM"), "Yes", "No"))
  flow <- ifelse(typed, h$flow_type, ifelse(dist == "Yes", "DIRECT", "NON_HOSPITAL"))
  conf <- ifelse(typed, ifelse(h$basis_type == "GENERAL_KNOWLEDGE", "LOW", "MEDIUM"), cls$determination_confidence)
  btype <- ifelse(typed, h$basis_type, NA_character_)
  why <- ifelse(typed, h$why, paste0("rhtp_classify_recipient_type() on the name: ", cls$recipient_type, "/",
                                     cls$determination_confidence, ". The roster states no form."))
  new <- tibble::tibble(
    state = WV_STATE, row_no = max(d$row_no) + seq_len(nrow(nr)), awardee = nr$organization, amount = nr$amount,
    recipient_type = rtype, distributed_to_hospital = dist,
    note = paste0(nr$initiative, " award (", nr$activity_raw, "), on the state's Year 1 roster, row ", nr$ra_row,
                  "; announced in no release read. Service area: ", nr$service_area, ". Summary as printed: '",
                  nr$summary, "'"),
    recipient_confirmed = "Yes", amount_confirmed = "Yes", fiscal_year = "FY2026 (Year 1)",
    source_document_title = src, state_source_url = WV_RA_URL,
    validation_source_type = "NOTICE_OF_AWARD", extraction_method = "DIRECT_TEXT",
    validator = "R/03av_wv_year1_awardees.R", ccn = NA_character_, aha_id = NA_character_,
    rural_designation = NA_character_, reviewer = NA_character_, initiative = nr$initiative,
    recipient_type_source = ifelse(typed, paste0("TYPED (session 121): ", why, " Classifier said ",
                                                 cls$recipient_type, "/", cls$determination_confidence, "."), why),
    determination_confidence = conf,
    flag_reason = ifelse(!typed & cls$rule == "FALLBACK", "RECIPIENT_TYPE_INFERRED", NA_character_),
    award_pool = nr$initiative, budget_period = "Budget Period 1", flow_type = flow,
    hospital_benefiting = ifelse(dist == "Yes", "Yes", "Unclear"),
    hospital_attribution = ifelse(dist == "Yes", "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = paste0("§10.2 ", ifelse(dist == "Yes", "DIRECT", flow), ": ", why,
                                 " Year 1: the state's own 'Year 1 Released Awards' list; the 11-09 release says every ",
                                 "Year 1 agreement was 'finalized ahead of the October 30 federal deadline'."),
    amount_basis = paste0("EXACT, as printed on the state's Year 1 roster (", nr$amount_text, ")."),
    basis_type = btype, round_amount = NA_real_, announcement_date = as.Date(NA),
    source_archive_path = WV_RA_PDF, recipient_subtype = NA_character_,
    cms_enrolment_match = NA_character_, cms_enrolment_record = NA_character_,
    wv_roster_row = nr$ra_row, roster_organization = nr$organization, roster_amount = nr$amount)
  out <- dplyr::bind_rows(d, new)
  # the file and the roster must agree to the cent
  if (abs(sum(out$roster_amount, na.rm = TRUE) - WV_RA_TOTAL) > 0.005 ||
      any(abs(out$amount[!is.na(out$roster_amount)] - out$roster_amount[!is.na(out$roster_amount)]) > 0.005) ||
      sum(!is.na(out$wv_roster_row) & !sib[seq_len(nrow(out))] %in% TRUE) != WV_RA_COUNT) {
    stop("[WV] the file no longer reproduces the roster's 67 awards / $108,261,312.68.", call. = FALSE)
  }
  out
}

#' The award file: the release rows, priced from and extended by the roster
wv_year1_awardees <- function() wv_apply_roster(wv_year1_release_rows())

# -- probe (session 55) ------------------------------------------------------

#' The reduced text of a page: <main> if it has one, script and style dropped
wv_page_text <- function(raw) {
  h <- xml2::read_html(raw)
  # Session 99: these pages have no <main>, so the whole document is read, and
  # its inline scripts carry a TBMegaMenu element UUID that ROTATES on every
  # render (fe42c847-... on 09-23, 2724ec90-... on 10-12) -- the rhtp and
  # grants pages logged CHANGED on nothing else. Scripts are not text a reader
  # sees; dropping them from BOTH copies is the reduction, not a re-base.
  xml2::xml_remove(xml2::xml_find_all(h, "//script|//style|//noscript"))
  m <- rvest::html_element(h, "main")
  stringr::str_squish(rvest::html_text2(if (inherits(m, "xml_missing")) h else m))
}

#' Every /article/ slug on a news-index page, with the headline it links from
wv_news_articles <- function(raw) {
  h <- xml2::read_html(raw)
  a <- rvest::html_elements(h, "a[href^='/article/']")
  # The only link per item reads "Full Story"; the headline is in its title
  # attribute, "Read article: <headline>".
  tibble::tibble(slug = sub("^/article/", "", rvest::html_attr(a, "href")),
                 headline = stringr::str_squish(sub(
                   "^Read article:\\s*", "", rvest::html_attr(a, "title")))) %>%
    dplyr::filter(!is.na(.data$headline), nzchar(.data$headline)) %>%
    dplyr::distinct(.data$slug, .keep_all = TRUE)
}

#' THE TRIPWIRE: an award release on the news index this file has not recorded
#'
#' Keyed on the SLUG, which West Virginia derives from the headline, and on the
#' word "award" in the headline or slug. All five recorded releases say
#' "Award"; every funding OPPORTUNITY release says "Investment" or "Funding
#' Opportunity" and none says "Award" -- measured on the 2026-09-23 index, 30
#' articles, and asserted in the test file.
wv_assert_no_new_award_release <- function(raw) {
  arts <- wv_news_articles(raw)
  if (nrow(arts) < 10L) {
    stop("[WV] the news index yields ", nrow(arts), " articles; the reader, ",
         "not West Virginia, has changed (§0.4).", call. = FALSE)
  }
  known <- unname(WV_SLUG)
  if (!all(known %in% arts$slug) && nrow(arts) < 25L) {
    stop("[WV] a recorded award release has left the news index's first page ",
         "while the page is short -- re-read it.", call. = FALSE)
  }
  # Session 99: an RHTP headline trips too, whatever its verb -- the 09-30
  # "$3.2 Million ... Investments" release awarded seven named recipients and
  # said "Award" nowhere in its headline or slug.
  new <- arts[grepl("award|rural health transformation|\\brhtp\\b",
                    paste(arts$headline, arts$slug), ignore.case = TRUE) &
                !arts$slug %in% known & !arts$slug %in% WV_NOT_RHTP$slug &
                !arts$slug %in% WV_READ_UNEXTRACTED$slug, , drop = FALSE]
  if (nrow(new)) {
    stop("[WV] NEW AWARD RELEASE(S) ON THE DoH NEWS INDEX: ",
         paste0("'", new$headline, "' (/article/", new$slug, ")", collapse = "; "),
         ". THAT IS THE SIGNAL. West Virginia said more awards would follow; ",
         "archive the release under data/evidence/ and add the row(s) to ",
         "WV_AWARDS with the quoted sentence.", call. = FALSE)
  }
  invisible(arts)
}

#' THE NAME CHECK (session 103): read the BODY of every article new to the
#' index, whatever its headline says.
#'
#' The headline filter above missed the 09-30 "Investments" release and then
#' all four 10-13/10-14 award releases ("$2 Million Investment ...", "$500,000
#' to Strengthen ..."): a phrase list holds only the phrasings West Virginia
#' has already used (§2.3). So every slug on the live index that the archived
#' index does not carry, and that this file has not recorded or judged, is
#' fetched (into memory, never data/evidence/, §2.2) and trips when its body
#' says "Rural Health Transformation" and "award". The finding names the
#' organisations in its award sentences, so the recipient trips regardless of
#' the headline's wording.
#'
#' @param raw The live index. @param archived_raw The committed index.
#' @param fetch_article function(slug) returning the article's raw HTML.
#' @return The findings (character), empty when nothing new awards.
wv_new_article_findings <- function(raw, archived_raw, fetch_article, cap = 12L) {
  live <- wv_news_articles(raw)
  held <- wv_news_articles(archived_raw)
  new <- live[!live$slug %in% c(held$slug, unname(WV_SLUG), WV_NOT_RHTP$slug,
                                WV_READ_UNEXTRACTED$slug), , drop = FALSE]
  if (nrow(new) > cap) {
    return(paste0("NEWS INDEX: ", nrow(new), " articles are new against the ",
                  "archived index -- more than the ", cap, " this check reads. ",
                  "Re-base the index (READ it first) so the name check can run."))
  }
  out <- character(0)
  for (i in seq_len(nrow(new))) {
    body <- wv_page_text(fetch_article(new$slug[i]))
    if (!grepl("Rural Health Transformation", body, fixed = TRUE) ||
        !grepl("\\bawards?\\b|\\bawarded\\b", body, ignore.case = TRUE)) next
    sent <- rhtp_sentences(body)
    sent <- sent[grepl("\\baward", sent, ignore.case = TRUE)]
    nm <- rhtp_organisation_names(paste(sent, collapse = " "))
    out <- c(out, paste0("NEW RHTP AWARD ARTICLE: '", new$headline[i], "' (/article/",
                         new$slug[i], ") names ",
                         if (length(nm)) paste(nm, collapse = "; ") else "no organisation-shaped name",
                         ". Read it; archive it and add the row(s) to WV_AWARDS, or ",
                         "record it in WV_NOT_RHTP with its sentence."))
  }
  out
}

wv_probe <- function() {
  live <- list(); arch <- list(); changed <- logical(0); findings <- character(0)
  for (i in seq_len(nrow(WV_PROBE_PAGES))) {
    p <- WV_PROBE_PAGES[i, ]
    raw <- rhtp_probe_get(p$key, function() {
      resp <- httr::GET(p$url, httr::user_agent(WV_USER_AGENT),
                        httr::timeout(60))
      if (httr::status_code(resp) != 200L) {
        stop("[WV] HTTP ", httr::status_code(resp), " from ", p$url,
             call. = FALSE)
      }
      httr::content(resp, as = "raw")
    }, here::here(WV_PROBE_DIR, p$file))
    lt <- wv_page_text(raw)
    at <- wv_page_text(here::here(WV_PROBE_DIR, p$file))
    changed[p$key] <- !identical(digest::digest(lt), digest::digest(at))
    if (p$key == "news") {
      held_raw <- here::here(WV_PROBE_DIR, p$file)
      found <- wv_new_article_findings(raw, held_raw, function(slug) {
        Sys.sleep(1)
        resp <- httr::GET(paste0(WV_URL, slug), httr::user_agent(WV_USER_AGENT),
                          httr::timeout(60))
        if (httr::status_code(resp) != 200L) {
          stop("[WV] HTTP ", httr::status_code(resp), " from /article/", slug,
               call. = FALSE)
        }
        httr::content(resp, as = "raw")
      })
      # Session 101's rule: nothing throws early. The headline trip and the
      # body check are both collected as findings and logged TRIPWIRE.
      head_trip <- tryCatch({ wv_assert_no_new_award_release(raw); NULL },
                            error = function(e) conditionMessage(e))
      findings <- c(findings, head_trip, found)
    }
    if (isTRUE(p$name_diff)) { live[[p$key]] <- lt; arch[[p$key]] <- at }
  }
  rhtp_assert_no_new_organisations_across(live = live, archived = arch,
                                          state = WV_STATE)
  message("[WV] ", paste0(names(changed), ": ",
                          ifelse(changed, "CHANGED", "UNCHANGED"), collapse = "; "),
          if (length(findings)) paste0(" -- ", length(findings), " FINDING(S).")
          else " -- no new award release.")
  invisible(list(sources = stats::setNames(lapply(changed, function(x) list(changed = x)),
                                           names(changed)),
                 findings = findings))
}


wv_status_table <- function() {
  tibble::tribble(
    ~state, ~channel, ~stage, ~publishes_roster, ~note,
    WV_STATE, "WV Department of Health / Governor releases",
    "AWARDED_NAMED_AND_PRICED_PARTIAL", "Yes",
    "Twenty-one award rows in eight releases (2026-09-04..30), twelve priced, $9,248,417; sessions 103 and 107 add seven rows in five more releases (10-13..19), all priced, for 28 rows / $18,804,875; session 112 adds two releases (10-26, 10-27), both priced, for 30 rows / $20,393,952; session 115 adds the 10-30 CAMC release, three priced hospital awards, for 33 rows / $24,324,218 in all. Minnie Hamilton's 'More Than $4 Million' prices one of three projects; the 09-30 'Investments' release prices none of its seven. Each release says more awards will follow, so this is a PARTIAL year. Watched by `--probe` (session 55).",
    WV_STATE, "2026-09-30 'More Than $3.2 Million in Rural Health Transformation Investments' release",
    "AWARDED_NAMED_NOT_PRICED", "Yes",
    "Seven named recipients, no per-recipient amount ('more than $3.2 million' in all, never divided, §6.2). Six hospitals typed on CMS WV enrolment (rows at $0); Vandalia Health, a system parent, typed HOSPITAL_OR_SYSTEM at $0, LOW, on the owner's ruling (session 101; WV_VANDALIA_SYSTEM_PARENT resolved). Extracted session 100 on the owner's approval; the headline says 'Investments', which the pre-session-99 tripwire missed.",
    WV_STATE, "2026-10-19 'More Than $3.4 Million ... to West Virginia United Health' release",
    "AWARDED_NAMED_AND_PRICED_PARTIAL", "Yes",
    "Two awards to West Virginia United (WVU) Health System: CCG 'more than $2.5 million' (a floor, carried as $2,500,000) and MSCF $900,000. A system parent, typed HOSPITAL_OR_SYSTEM, LOW, GENERAL_KNOWLEDGE, no CCN, on the system-parent rulings (session 107). 'Additional awards will be announced'.",
    WV_STATE, "2026-10-26 WVU Cancer Institute and 2026-10-27 Williamson Health & Wellness Center releases",
    "AWARDED_NAMED_AND_PRICED_PARTIAL", "Yes",
    "WVU Cancer Institute $1,339,077 (Connected Care Grid; a university unit, NON_HOSPITAL on the session-104 WVU Eye Institute ruling) and Williamson Health & Wellness Center $250,000 (an FQHC on its exact CMS FQHC legal name; not Williamson Memorial Hospital). Extracted session 112. 'Additional awards will be announced' (10-26 release).",
    WV_STATE, "2026-10-30 'More Than $3.9 Million to Expand Rural Healthcare Training and Workforce Programs' release",
    "AWARDED_NAMED_AND_PRICED_PARTIAL", "Yes",
    "Three awards to Charleston Area Medical Center (CAMC): MSCF $500,000 and $1,693,946, HTP $1,736,320 ($3,930,266, 'more than $3.9 million'). A hospital on its CMS WV enrolment (CCN 510022), typed as the 09-04 CAMC/Vandalia Health row. Found by the 11-06 Routine's name check; extracted session 115.",
    WV_STATE, "WV DoH 'Year 1 Released Awards' roster (health.wv.gov/funding-opportunities, fetched 2026-11-20)",
    "AWARDED_NAMED_AND_PRICED_PARTIAL", "Yes",
    "THE STATE'S OWN YEAR 1 AWARD LIST: 67 awards, 'Total Announced (67 awards): $108,261,312.68', parsed from poppler word boxes and reproduced to the cent. It prices every release row (the 09-30 Investments rows, Minnie Hamilton's projects, the WVU floor) and adds 25 awards no release announced (IBM's data spine, WV Jobs Investment Trust $18.8M, VeeOne, Cartwheel, Unite Us, Pleasant Valley Hospital Foundation, WVSOM's birthing center ...). The latest list governs (session 121). A FLOOR: the 11-09 release counts 145 Year 1 agreements.",
    WV_STATE, "2026-08-14 '$4.2 million investment' release",
    "SOLICITATION_TIER_2", "No",
    "Two funding OPPORTUNITIES (Tier 2), not awards. Kept out of the award file (§0.2).",
    WV_STATE, "RCJ's four WV Tier 3 candidates", "NOT_THESE_AWARDS", "n/a",
    "None of RCJ's four WV candidates is one of these seven awards (session 53)."
  )
}

wv_validate <- function() {
  wv_assert_sources()
  d <- wv_year1_awardees()
  # Session 103: + 5 rows, all priced. Session 104: WVU Eye Institute is
  # NON_HOSPITAL on the owner's ruling (was Unclear), so no WV row is Unclear.
  # Session 107: + 2 rows, both priced and both hospital (WVU Health System).
  # Session 112: + 2 rows, both priced, neither a hospital (WVU Cancer
  # Institute, Williamson Health & Wellness Center).
  # Session 115: + 3 rows, all priced, all hospital (CAMC, $3,930,266).
  # Session 117a: + 7 rows, all priced, one hospital (Cabell Huntington, $1,544,313).
  # Session 121: + 3 rows, all priced, all hospital (WVU Hospitals + the WVU system parent, $7,526,918).
  # Session 121: + the state's Year 1 roster (67 awards, $108,261,312.68): 25
  # roster-only rows appended, every release row priced from it but one (row 14,
  # Minnie Hamilton's second project, priced on row 13). The file IS the roster.
  stopifnot(nrow(d) == 68L, sum(!is.na(d$amount)) == 67L,
            abs(sum(d$amount, na.rm = TRUE) - WV_RA_TOTAL) < 0.005,
            sum(d$distributed_to_hospital == "Unclear") == 0L,
            sum(d$distributed_to_hospital == "Yes") == 22L,   # session 101: + Vandalia Health; session 121: + Pleasant Valley Hospital Foundation
            sum(d$amount[d$distributed_to_hospital == "Yes"], na.rm = TRUE) == 25162640)
  message("[WV] all assertions pass.")
  invisible(TRUE)
}

wv_build <- function() {
  wv_validate()
  # Session 86: R/03bj's enrolled-hospital overlay (Minnie Hamilton, EH_APPLY).
  s71 <- new.env()
  suppressMessages(source(here::here("R", "03bj_enrolled_hospital_operator.R"),
                          local = s71))
  # Numbers in full: as.character(500000) is "5e+05".
  num <- function(x) ifelse(is.na(x), NA_character_,
                            vapply(x, function(v) format(v, scientific = FALSE, digits = 15),
                                   character(1)))
  d <- dplyr::mutate(wv_year1_awardees(), dplyr::across(dplyr::where(is.numeric), num),
                     dplyr::across(dplyr::everything(), as.character))
  readr::write_csv(s71$s71_overlay(d, basename(WV_CSV)), WV_CSV, na = "")
  readr::write_csv(wv_status_table(), WV_STATUS_CSV, na = "")
  message("[WV] wrote ", nrow(d), " award rows.")
}

wv_report <- function() {
  d <- wv_year1_awardees()
  print(as.data.frame(d[, c("awardee", "amount", "recipient_type",
                            "distributed_to_hospital", "determination_confidence")]),
        row.names = FALSE)
  cat(sprintf("\nTotal $%s; named-hospital %d rows / $%s\n",
              format(sum(d$amount, na.rm = TRUE), big.mark = ","),
              sum(d$distributed_to_hospital == "Yes"),
              format(sum(d$amount[d$distributed_to_hospital == "Yes"], na.rm = TRUE),
                     big.mark = ",")))
}

if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) wv_validate()
  if ("--build" %in% args) wv_build()
  if ("--probe" %in% args) rhtp_probe_run("WV", wv_probe())
  if ("--report" %in% args) wv_report()
  if (!length(args)) message("Usage: --validate | --build | --probe | --report")
}
