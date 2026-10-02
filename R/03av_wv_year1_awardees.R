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
WV_TOTAL     <- 9248417          # the PRICED rows; two Minnie Hamilton rows carry none
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
  mh   = "governor-morrisey-announces-more-4-million-rural-health-transformation-awards-minnie")

# Where each release is archived. The session-85 pair sits under
# data/evidence/WV/ with its fetch date, not under the 09-23 recheck folder.
WV_PATHS <- c(
  stats::setNames(file.path(WV_DIR, WV_FILES), names(WV_FILES)),
  ccwv = file.path("data", "evidence", "WV", "2026-10-02_wv_art_ccwv_rhtp_awards.html"),
  mh   = file.path("data", "evidence", "WV", "2026-10-02_wv_art_minnie_hamilton_rhtp_awards.html"))

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
  "news", "https://health.wv.gov/news", "2026-09-23_wv_news_index.html", FALSE,
  "rhtp", "https://health.wv.gov/rhtp", "2026-09-23_wv_rhtp_programme.html", TRUE,
  "grants", "https://health.wv.gov/grant-opportunities",
  "2026-09-23_wv_grant_opportunities.html", TRUE)
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
  for (k in names(WV_PATHS)) {
    rhtp_assert_footer_text_tier(wv_text(k), WV_STATE, "STATE_ALLOTMENT",
                                 label = paste("WV", k, "footer"))
  }
  if (abs(sum(WV_AWARDS$amount, na.rm = TRUE) - WV_TOTAL) > 0.005) {
    stop("[WV] the priced awards no longer sum to $9,248,417.", call. = FALSE)
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
  if (!all(as.Date(WV_AWARDS$date) > WV_NOA_DATE)) stop("[WV] date test.")
  invisible(TRUE)
}

wv_year1_awardees <- function() {
  a <- WV_AWARDS
  cls <- rhtp_classify_recipient_type(a$awardee, WV_STATE)
  typed <- !is.na(a$recipient_type)
  rtype <- ifelse(typed, a$recipient_type, cls$recipient_type)
  conf <- dplyr::case_when(!typed ~ cls$determination_confidence,
                           a$basis_type == "GENERAL_KNOWLEDGE" ~ "LOW",
                           TRUE ~ "MEDIUM")
  flag <- ifelse(!typed, "RECIPIENT_TYPE_INFERRED", NA_character_)
  flag <- ifelse(a$rounded, "AMOUNT_ROUNDED_IN_SOURCE", flag)
  flag <- ifelse(is.na(a$amount), "AMOUNT_MISSING", flag)
  hosp <- a$dist == "Yes"
  mh <- a$key == "mh"
  s85 <- a$key %in% c("ccwv", "mh")
  tibble::tibble(
    state = WV_STATE,
    row_no = seq_len(nrow(a)),
    awardee = a$awardee,
    amount = a$amount,
    recipient_type = rtype,
    distributed_to_hospital = a$dist,
    note = ifelse(
      mh & is.na(a$amount),
      paste0("One of three Minnie Hamilton projects in the 'More Than $4 ",
             "Million' release of ", a$date, "; the release prices only the ",
             "$1.7M mobile clinic, and the remainder is NOT divided (§6.2)."),
      paste0(a$initiative, " award, announced ", a$date,
             " by Governor Morrisey. 'Additional Rural Health ",
             "Transformation Program awards will be announced'.")),
    recipient_confirmed = "Yes",
    amount_confirmed = ifelse(a$rounded | is.na(a$amount), "No", "Yes"),
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = paste("WV Department of Health release,", a$date),
    state_source_url = paste0(WV_URL, WV_SLUG[a$key]),
    validation_source_type = "GOVERNOR_PRESS_RELEASE",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03av_wv_year1_awardees.R",
    ccn = ifelse(mh, "511303", NA_character_),
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    initiative = a$initiative,
    recipient_type_source = ifelse(
      typed, paste0(ifelse(s85, "TYPED (session 85): ", "TYPED (session 54): "), a$why, " Classifier said ",
                    cls$recipient_type, "/", cls$determination_confidence, "."),
      paste0("rhtp_classify_recipient_type() on the name: ",
             cls$recipient_type, "/", cls$determination_confidence, ". ", a$why)),
    determination_confidence = conf,
    flag_reason = flag,
    award_pool = a$initiative,
    budget_period = "Budget Period 1",
    flow_type = a$flow_type,
    hospital_benefiting = ifelse(hosp, "Yes",
                                 ifelse(a$key %in% c("nurs", "hin"), "Yes", "Unclear")),
    hospital_attribution = ifelse(hosp, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = ifelse(
      hosp, paste0("§10.2 DIRECT: ", a$why),
      paste0("§10.2 ", a$flow_type, ": ", a$why)),
    amount_basis = dplyr::case_when(
      is.na(a$amount) ~ "NOT PRICED: the release prices one of Minnie Hamilton's three projects; the rest of 'More Than $4 Million' is not divided (§6.2).",
      a$awardee == "Ascend WV" ~ "ROUNDED IN SOURCE: printed only as '$2.4 million'.",
      a$rounded ~ "ROUNDED IN SOURCE: printed only as '$1.7 million'.",
      TRUE ~ "EXACT, as printed in the release."),
    basis_type = a$basis_type,
    round_amount = NA_real_,
    announcement_date = as.Date(a$date),
    source_archive_path = unname(WV_PATHS[a$key]),
    recipient_subtype = NA_character_,
    cms_enrolment_match = ifelse(mh, "EXACT_LEGAL_NAME", NA_character_),
    cms_enrolment_record = ifelse(mh, WV_MH_ENROLMENT, NA_character_))
}

# -- probe (session 55) ------------------------------------------------------

#' The reduced text of a page: <main> if it has one, script and style dropped
wv_page_text <- function(raw) {
  h <- xml2::read_html(raw)
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
  new <- arts[grepl("award", paste(arts$headline, arts$slug), ignore.case = TRUE) &
                !arts$slug %in% known, , drop = FALSE]
  if (nrow(new)) {
    stop("[WV] NEW AWARD RELEASE(S) ON THE DoH NEWS INDEX: ",
         paste0("'", new$headline, "' (/article/", new$slug, ")", collapse = "; "),
         ". THAT IS THE SIGNAL. West Virginia said more awards would follow; ",
         "archive the release under data/evidence/ and add the row(s) to ",
         "WV_AWARDS with the quoted sentence.", call. = FALSE)
  }
  invisible(arts)
}

wv_probe <- function() {
  live <- list(); arch <- list(); changed <- logical(0)
  for (i in seq_len(nrow(WV_PROBE_PAGES))) {
    p <- WV_PROBE_PAGES[i, ]
    resp <- httr::GET(p$url, httr::user_agent(WV_USER_AGENT), httr::timeout(60))
    if (httr::status_code(resp) != 200L) {
      stop("[WV] HTTP ", httr::status_code(resp), " from ", p$url, call. = FALSE)
    }
    raw <- httr::content(resp, as = "raw")
    lt <- wv_page_text(raw)
    at <- wv_page_text(here::here(WV_PROBE_DIR, p$file))
    changed[p$key] <- !identical(digest::digest(lt), digest::digest(at))
    if (p$key == "news") wv_assert_no_new_award_release(raw)
    if (isTRUE(p$name_diff)) { live[[p$key]] <- lt; arch[[p$key]] <- at }
  }
  rhtp_assert_no_new_organisations_across(live = live, archived = arch,
                                          state = WV_STATE)
  message("[WV] ", paste0(names(changed), ": ",
                          ifelse(changed, "CHANGED", "UNCHANGED"), collapse = "; "),
          " -- no new award release.")
  invisible(tibble::tibble(key = names(changed), changed = unname(changed)))
}


wv_status_table <- function() {
  tibble::tribble(
    ~state, ~channel, ~stage, ~publishes_roster, ~note,
    WV_STATE, "WV Department of Health / Governor releases",
    "AWARDED_NAMED_AND_PRICED_PARTIAL", "Yes",
    "Fourteen award rows in seven releases (2026-09-04..30), twelve priced, $9,248,417. Minnie Hamilton's 'More Than $4 Million' prices one of three projects. Each release says more awards will follow, so this is a PARTIAL year. Watched by `--probe` (session 55).",
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
  stopifnot(nrow(d) == 14L, sum(!is.na(d$amount)) == 12L,
            sum(d$distributed_to_hospital == "Yes") == 5L,
            sum(d$amount[d$distributed_to_hospital == "Yes"], na.rm = TRUE) == 2924000)
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
  message("[WV] wrote 14 award rows.")
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
