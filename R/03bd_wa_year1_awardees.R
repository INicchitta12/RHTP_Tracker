#!/usr/bin/env Rscript
# 03bd_wa_year1_awardees.R ---------------------------------------------------
#
# WASHINGTON -- THE FIRST-TIER LIST, EXTRACTED (session 60). SEVEN NAMED,
# PRICED FIRST-TIER RECIPIENTS AND ONE UNNAMED CLASS, $67,020,000 NAMED, AND
# NOT ONE NAMED-HOSPITAL DOLLAR.
#
# Source: HCA's 2026-09-16 webinar deck, slide 9, "How the money flows", which
# prices every first-tier line, and HCA's "What we're working on" page, which
# lists the same organisations under "Sub-awardees:". Both archived by session
# 55 under data/evidence/recheck/2026-09-23/WA/. R/03bc still watches the
# pages; this file holds the rows.
#
#   SUB-RECIPIENT    1.3 WSHA - tech & cyber            $42M
#                    1.1 TRC - 30 member hospitals       $5.43M
#   SOLE SOURCE      3.1 WA 29 Federally Recognized Tribes $19.41M
#                    1.2 Rural Health Redesign Center    $2.14M
#   INTERAGENCY      5.1 UW - WWAMI residency            $5.46M
#                    6.3 OSPI - youth in rural areas     $5.14M
#                    4.1 UW - Project ECHO               $4.28M
#                    5.2 WSU - rural training            $2.57M
#
# THE $42M IS THE STATE HOSPITAL ASSOCIATION, AND IT IS `Unclear`, NOT A
# HOSPITAL DOLLAR. The shared classifier types "Washington State Hospital
# Association" HOSPITAL_OR_SYSTEM at HIGH on the word "Hospital" -- Michigan's
# MHA trap (session 27), here worth $42M -- so the type is overridden to
# NONPROFIT_CBO under §10.2's association row. That row then needs the source
# to show funds "administered to or on behalf of member hospitals", and the
# deck's one sentence is: "Washington State Hospital Association is receiving
# applications from hospitals for critical technology infrastructure and
# maintenance needs, including replacing 15-year-old filtration and
# sterilization equipment, computer servers, and sanitation equipment."
# The flow classifier reads that as IN_KIND_BENEFIT (no money-movement
# marker). HOSPITALS APPLYING reads more like a re-grant than a service, and
# the deck prices non-hospital tech & cyber separately (4.2, $11.05M), which
# looks like a hospitals-only class. NEITHER READING IS WHAT THE SOURCE SAYS.
# So it is PASS_THROUGH_UNRESOLVED + Unclear + FLOW_UNRESOLVED_HOSPITAL_
# AFFILIATED, in NEITHER bucket, and queued as WA_WSHA_FLOW (§0.4).
#
# THE RURAL COLLABORATIVE ($5.43M, "30 member hospitals") IS A SERVICE, ON ITS
# OWN SENTENCE: "is working with 30 independent rural hospitals to build
# capacity and improve revenue cycle management". Alaska's AHHA assessments
# precedent (session 18): the hospitals receive work, not money, so
# IN_KIND_BENEFIT / No / hospital_benefiting = Yes. The slide's label "30
# member hospitals" names nobody and says nothing about money; it is recorded
# in the queue row, not coded.
#
# THE 29 TRIBES ARE ONE AGGREGATE ROW WITH `amount` EMPTY (Oklahoma's ROOTS
# device): a class, sole source, no per-Tribe figure. $19.41M is in
# `round_amount`. RCJ carries the same class at $18,100,000; the deck is used.
#
# DOH ($31.72M) AND DSHS ($14.96M) ARE NOT IN THIS FILE. The deck names HCA,
# DOH and DSHS as the three agencies that jointly run the programme ("Joint
# effort of HCA DOH and DSHS"), so their lines are allocations inside the
# state's own administering structure (Tier 2 from here), not first-tier
# awards to an outside recipient. They are in wa_year1_status.csv with HCA's
# five competitive pools, whose winners are unpublished -- including 1.4,
# $10.71M for "36 rural hospitals statewide", whose bid HCA says is
# "Completed". ONE CLOSURE: HCA's programme page carries the RNEP footer,
# "through a subaward ... with $3,500,000 and 80 percent funded by CMS/HHS",
# and the deck prices DOH 5.3 Rural Nursing Education at $3.50M.
#
# THE DECK'S OWN SUBTOTALS DISAGREE WITH ITS ROWS, RECORDED NOT CORRECTED:
# SUB-RECIPIENT header $47.42M vs 42 + 5.43 = $47.43M; INTERAGENCY header
# $17.46M vs $17.45M; COMPETITIVE BID header $43.56M vs its five rows
# $39.54M; and slide 10 totals the same five rows as $39.97M. Every figure is
# rounded to $10,000, so every priced row carries AMOUNT_ROUNDED_IN_SOURCE and
# amount_confirmed = No.
#
# §0.2: the deck's footer prints $181,257,515.06, the ALLOTMENT.
#
# Usage: Rscript R/03bd_wa_year1_awardees.R --validate | --build | --report

suppressPackageStartupMessages({ library(dplyr); library(stringr) })
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_pdf_text.R"))
source(here::here("R", "utils_recipient_classification.R"))

WAA_STATE <- "WA"
WAA_DIR <- file.path("data", "evidence", "recheck", "2026-09-23", "WA")
WAA_DECK <- file.path(WAA_DIR, "hca_rhtp_webinar_2026-09-16.pdf")
WAA_WORKING <- file.path(WAA_DIR, "hca_rhtp_what_were_working_on.html")
WAA_PROGRAMME <- file.path(WAA_DIR, "hca_rhtp_programme.html")
WAA_DECK_URL <- paste0("https://www.hca.wa.gov/about-hca/programs-and-initiatives/",
                       "rural-health-transformation-program")
WAA_DECK_DATE <- as.Date("2026-09-16")
WAA_NOA_DATE <- as.Date("2025-12-29")
WAA_AWARD_CSV <- file.path("data", "reference", "wa_year1_awardees.csv")
WAA_STATUS_CSV <- file.path("data", "reference", "wa_year1_status.csv")

waa_squish <- function(x) {
  x <- stringr::str_replace_all(x, "[‘’]", "'")
  stringr::str_squish(x)
}

waa_deck_text <- function(path = WAA_DECK) {
  waa_squish(paste(rhtp_pdf_text(here::here(path)), collapse = " "))
}

waa_html_text <- function(path) {
  t <- paste(readLines(here::here(path), warn = FALSE, encoding = "UTF-8"),
             collapse = " ")
  t <- stringr::str_remove_all(t, stringr::regex(
    "<(script|style|noscript)[^>]*>.*?</\\1>", dotall = TRUE, ignore_case = TRUE))
  t <- stringr::str_replace_all(t, "<[^>]+>", " ")
  t <- stringr::str_replace_all(t, "&nbsp;|&#160;", " ")
  t <- stringr::str_replace_all(t, "&amp;", "&")
  waa_squish(t)
}

# One row per first-tier line on slide 9. `quote` is the slide's own line and
# is asserted present in the deck text.
WAA_ROWS <- tibble::tribble(
  ~awardee, ~activity, ~amount, ~quote, ~channel,
  ~recipient_type, ~flow_type, ~dist, ~benefit, ~attr, ~flags, ~why, ~basis_type,
  "Washington State Hospital Association", "1.3 Hospital technology & cybersecurity",
  42000000, "1.3 WSHA - tech & cyber $42M", "SUB-RECIPIENT",
  "NONPROFIT_CBO", "PASS_THROUGH_UNRESOLVED", "Unclear", "Yes", "NOT_HOSPITAL",
  "AMOUNT_ROUNDED_IN_SOURCE;FLOW_UNRESOLVED_HOSPITAL_AFFILIATED",
  paste("The state HOSPITAL ASSOCIATION (§10.2 association row), not a hospital;",
        "the classifier's HOSPITAL_OR_SYSTEM/HIGH on the name is overridden",
        "(Michigan's MHA precedent). The deck: 'is receiving applications from",
        "hospitals for critical technology infrastructure and maintenance",
        "needs'. That does not say the funds are administered TO hospitals",
        "(the flow classifier reads it IN_KIND_BENEFIT) and does not say WSHA",
        "keeps them either. Unclear, neither bucket; WA_WSHA_FLOW."),
  "STATE_SOURCE",
  "The Rural Collaborative", "1.1 Rural hospital capacity and revenue cycle",
  5430000, "1.1 TRC - 30 member hospitals $5.43M", "SUB-RECIPIENT",
  "NONPROFIT_CBO", "IN_KIND_BENEFIT", "No", "Yes", "NOT_HOSPITAL",
  "AMOUNT_ROUNDED_IN_SOURCE;RECIPIENT_TYPE_INFERRED",
  paste("The deck: 'The Rural Collaborative is working with 30 independent",
        "rural hospitals to build capacity and improve revenue cycle",
        "management' -- a service delivered to hospitals (Alaska AHHA",
        "precedent). Form not stated: §8 fallback. The '30 member hospitals'",
        "label names nobody and is not a statement that money moves."),
  "STATE_SOURCE",
  "Rural Health Redesign Center", "1.2 Payment model co-design",
  2140000, "1.2 Rural Health Redesign Center $2.14M", "SOLE SOURCE",
  "NONPROFIT_CBO", "IN_KIND_BENEFIT", "No", "Yes", "NOT_HOSPITAL",
  "AMOUNT_ROUNDED_IN_SOURCE;RECIPIENT_TYPE_INFERRED",
  paste("The deck: 'HCA and the Rural Health Redesign Center are meeting with",
        "rural hospital CEOs and CFOs to begin co-designing a payment model'.",
        "A sole-source service; hospitals receive work. Form not stated."),
  "STATE_SOURCE",
  "University of Washington (WWAMI Family Medicine Residency Network)",
  "5.1 WWAMI residency", 5460000, "5.1 UW - WWAMI residency $5.46M",
  "INTERAGENCY AGREEMENT",
  "UNIVERSITY_OR_AHC", "NON_HOSPITAL", "No", "No", "NOT_HOSPITAL",
  "AMOUNT_ROUNDED_IN_SOURCE",
  "A university by name (§8 name rule). §10.2 NON_HOSPITAL.", "STATE_SOURCE",
  "Office of Superintendent of Public Instruction", "6.3 Youth in rural areas",
  5140000, "6.3 OSPI - youth in rural areas $5.14M", "INTERAGENCY AGREEMENT",
  "STATE_AGENCY", "NON_HOSPITAL", "No", "No", "NOT_HOSPITAL",
  "AMOUNT_ROUNDED_IN_SOURCE",
  paste("Washington's state education agency; the deck: 'Contracted with the",
        "Office of Superintendent of Public Instruction (OSPI) to expand the",
        "number of school systems able to utilize Medicaid Funding'. The",
        "classifier's NONPROFIT_CBO fallback is overridden."),
  "STATE_SOURCE",
  "University of Washington (School of Medicine, Project ECHO)",
  "4.1 Project ECHO", 4280000, "4.1 UW - Project ECHO $4.28M",
  "INTERAGENCY AGREEMENT",
  "UNIVERSITY_OR_AHC", "NON_HOSPITAL", "No", "No", "NOT_HOSPITAL",
  "AMOUNT_ROUNDED_IN_SOURCE",
  "A university by name (§8 name rule). §10.2 NON_HOSPITAL.", "STATE_SOURCE",
  "Washington State University", "5.2 Rural practitioner training",
  2570000, "5.2 WSU - rural training $2.57M", "INTERAGENCY AGREEMENT",
  "UNIVERSITY_OR_AHC", "NON_HOSPITAL", "No", "No", "NOT_HOSPITAL",
  "AMOUNT_ROUNDED_IN_SOURCE",
  "A university by name (§8 name rule). §10.2 NON_HOSPITAL.", "STATE_SOURCE",
  "Washington's 29 Federally Recognized Tribes (not individually named)",
  "3.1 Tribal health investments", NA_real_,
  "3.1 WA 29 Federally Recognized Tribes $19.41M", "SOLE SOURCE",
  "TRIBAL_ORG", "NON_HOSPITAL", "No", "No", "NOT_HOSPITAL",
  "RECIPIENT_NOT_NAMED;AMOUNT_ROUNDED_IN_SOURCE",
  paste("A CLASS with no per-Tribe figure: `amount` is EMPTY and $19,410,000 is",
        "in `round_amount` (Oklahoma's ROOTS device, §6.2). Sovereign Tribal",
        "governments are not hospitals."),
  "STATE_SOURCE"
)

WAA_TRIBES_POOL <- 19410000

# Tier 2 from here: pools with no published winners, and the lines of the two
# co-administering agencies. NO `amount` COLUMN (Texas's device).
WAA_STATUS <- tibble::tribble(
  ~line, ~administered_by, ~channel, ~pool_amount_in_source, ~stage, ~note,
  "4.2 Provider tech & cyber, non-hospital", "HCA", "COMPETITIVE BID", 11050000,
  "RFA_CLOSED_NO_WINNERS_PUBLISHED", "Non-hospital providers. 'Completed competitive bid process' (slide 14).",
  "1.4 Hospital specialty growth (maternal, emergency, specialty)", "HCA", "COMPETITIVE BID", 10710000,
  "RFA_CLOSED_NO_WINNERS_PUBLISHED", "'36 rural hospitals statewide'; 'Completed the competitive bid process for rural hospitals'. HOSPITALS ONLY -- the pool to watch.",
  "6.1 Mobile crisis MDT", "HCA", "CLIENT SERVICES", 7930000,
  "CONTRACTS_IN_PROCESS", "BH-ASOs, Tribes.",
  "6.4 OTP recruitment", "HCA", "COMPETITIVE BID", 6640000,
  "RFA_POSTED", "Opioid treatment providers.",
  "6.2 CCBHC transition", "HCA", "CLIENT SERVICES", 3210000,
  "CONTRACTS_IN_PROCESS", "CCBHCs.",
  "DOH interagency agreement (8 lines incl. 5.3 Rural Nursing Education $3.50M)", "DOH", "INTERAGENCY AGREEMENT", 31720000,
  "CO_ADMINISTERING_AGENCY", "The RNEP footer on HCA's page: 'through a subaward ... with $3,500,000 and 80 percent funded by CMS/HHS'. RNEP partners with 16 CAHs, none named.",
  "DSHS interagency agreement (6 lines)", "DSHS", "INTERAGENCY AGREEMENT", 14960000,
  "CO_ADMINISTERING_AGENCY", "Incl. 2.1 Long-term care workers (SEIU) $4.28M.",
  "Washington RHT Administration", "HCA", "ADMINISTRATION", 4590000,
  "ADMINISTRATION", "Slide 8."
)

waa_assert_sources <- function(deck = waa_deck_text(),
                               working = waa_html_text(WAA_WORKING),
                               programme = waa_html_text(WAA_PROGRAMME)) {
  want <- c(WAA_ROWS$quote,
            "SUB-RECIPIENT $47.42M", "SOLE SOURCE $21.55M",
            "INTERAGENCY AGREEMENT $17.46M",
            "COMPETITIVE BID and Client Services* $43.56M",
            "is receiving applications from hospitals",
            "is working with 30 independent rural hospitals")
  miss <- want[!vapply(want, function(w) grepl(w, deck, fixed = TRUE), TRUE)]
  if (length(miss)) stop("[WA] the deck no longer says: ",
                         paste(sQuote(miss), collapse = "; "), call. = FALSE)
  subs <- c("The Rural Collaborative", "Rural Health Redesign Center",
            "Washington State Hospital Association", "Project ECHO",
            "Washington State University",
            "Office of Superintendent of Public Instruction")
  miss <- subs[!vapply(subs, function(w) grepl(w, working, fixed = TRUE), TRUE)]
  if (length(miss)) stop("[WA] 'What we're working on' no longer lists as ",
                         "sub-awardees: ", paste(miss, collapse = ", "),
                         call. = FALSE)
  # The DECK's footer omits "with" before "100 percent" and
  # rhtp_footer_parse() does not read that variant; the shared parser was not
  # widened here (a shared-rule change needs its own inertness run). The
  # standard footer on "What we're working on" carries the same figure and is
  # tier-checked; the deck's figure is asserted literally.
  rhtp_assert_footer_text_tier(working, WAA_STATE, "STATE_ALLOTMENT",
                               label = "WA 'What we're working on' footer")
  if (!grepl("award totaling $181,257,515.06 to the Washington State Health",
             deck, fixed = TRUE)) {
    stop("[WA] the deck's footer no longer prints the allotment.", call. = FALSE)
  }
  # The closure: the RNEP subaward footer's CMS share is the deck's DOH 5.3.
  if (!grepl("with $3,500,000 and 80 percent funded by CMS/HHS", programme,
             fixed = TRUE) || !grepl("5.3 Rural Nursing Education $3.50M", deck,
                                     fixed = TRUE)) {
    stop("[WA] the RNEP footer / deck 5.3 closure no longer holds.", call. = FALSE)
  }
  if (WAA_DECK_DATE <= WAA_NOA_DATE) stop("[WA] date test.", call. = FALSE)
  invisible(TRUE)
}

# The deck's subtotals against its own rows. Recorded disagreements, pinned so
# a re-issued deck that fixes (or changes) them is noticed.
waa_subtotal_check <- function() {
  tibble::tribble(
    ~subtotal, ~stated, ~sum_of_rows,
    "SUB-RECIPIENT", 47420000, 42000000 + 5430000,
    "SOLE SOURCE", 21550000, 19410000 + 2140000,
    "INTERAGENCY AGREEMENT (HCA)", 17460000, 5460000 + 5140000 + 4280000 + 2570000,
    "COMPETITIVE BID and Client Services", 43560000,
    11050000 + 10710000 + 7930000 + 6640000 + 3210000,
    "Slide 10 competitive total", 39970000,
    11050000 + 10710000 + 7930000 + 6640000 + 3210000
  ) %>% mutate(gap = stated - sum_of_rows)
}

wa_year1_awardees <- function() {
  d <- wa_first_tier_rows()
  dplyr::bind_rows(d, waa_mes_rows(nrow(d) + 1L))
}

wa_first_tier_rows <- function() {
  a <- WAA_ROWS
  cls <- rhtp_classify_recipient_type(a$awardee, WAA_STATE)
  tibble::tibble(
    state = WAA_STATE,
    row_no = seq_len(nrow(a)),
    awardee = a$awardee,
    amount = a$amount,
    recipient_type = a$recipient_type,
    distributed_to_hospital = a$dist,
    note = paste0(a$channel, " line on HCA's 2026-09-16 deck, slide 9 ('",
                  a$quote, "')."),
    recipient_confirmed = ifelse(is.na(a$amount), "No", "Yes"),
    amount_confirmed = "No",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = paste("HCA, Rural Health Transformation Program",
                                  "Update webinar deck, 2026-09-16"),
    state_source_url = WAA_DECK_URL,
    validation_source_type = "OTHER",
    extraction_method = "PDF_TEXT",
    validator = "R/03bd_wa_year1_awardees.R",
    ccn = NA_character_, aha_id = NA_character_,
    rural_designation = NA_character_, reviewer = NA_character_,
    initiative = a$activity,
    recipient_type_source = paste0("TYPED (session 60): ", a$why,
                                   " Classifier said ", cls$recipient_type,
                                   "/", cls$determination_confidence, "."),
    determination_confidence = "LOW",
    flag_reason = a$flags,
    award_pool = a$activity,
    budget_period = "Budget Period 1",
    flow_type = a$flow_type,
    hospital_benefiting = a$benefit,
    hospital_attribution = a$attr,
    intermediary_name = ifelse(a$flow_type == "PASS_THROUGH_UNRESOLVED",
                               a$awardee, NA_character_),
    determination_basis = paste0("§10.2 ", a$flow_type, ": ", a$why),
    amount_basis = ifelse(is.na(a$amount),
      "No per-recipient figure; the class's pool is in round_amount.",
      "ROUNDED IN SOURCE to $10,000 ('$X.XXM') on slide 9; amount_confirmed = No."),
    basis_type = a$basis_type,
    round_amount = ifelse(is.na(a$amount), WAA_TRIBES_POOL, NA_real_),
    announcement_date = WAA_DECK_DATE,
    source_archive_path = WAA_DECK
  )
}

# -- SESSION 118, OWNER RULING (c): HCA's 28 "maternal, emergency, and specialty
# services" hospitals -----------------------------------------------------------
# HCA's "Washington's RHT funds are 100% obligated" (2026-11-05, archived
# recheck/2026-11-13/WA/) prices Initiative 1's activities under the column
# "Estimated amount", including "Maternal, emergency, and specialty services
# $9.67 million", and says: "As part of Initiative 1, hospitals could apply for
# funding to sustain and maintain essential maternal, emergency, and specialty
# services. Twenty-eight hospitals were approved through a competitive bid
# process:" -- then lists 28 names and no per-hospital figure. A figure stated
# for named hospitals alone: ONE POOL_NAMED_HOSPITALS row at the stated
# obligation, never divided (§6.2; §7 "a pool is judged per priced component";
# Ohio's shape). The 28 are rows at $0, typed on CMS WA Hospital Enrollments.
# "Estimated amount" is recorded on the pool row (AMOUNT_PRELIMINARY) and in
# the members' notes only. WA stays PARTIAL. This is very likely the deck's
# competitive line 1.4 ($10.71M, "36 rural hospitals statewide", status table),
# re-stated at award: that line was never an award row, so nothing is counted
# twice.
WAA_OBL_PDF <- file.path("data", "evidence", "recheck", "2026-11-13", "WA",
                         "2026-11-13_hca_rht_obligated_funds.pdf")
WAA_OBL_DATE <- as.Date("2026-11-05")
WAA_MES_POOL <- 9670000
WAA_MES_SENTENCE <- paste("Twenty-eight hospitals were approved through a competitive bid",
                          "process")
# match: EXACT (the string is the enrolled name or DBA) or BRIDGE (hand-read,
# LOW). An entity holding two hospital CCNs gets none (Ohio's rule).
WAA_MES <- tibble::tribble(
  ~awardee, ~match, ~ccn, ~enrolment,
  "Astria Sunnyside Hospital", "EXACT", "501330", "SUNNYSIDE COMMUNITY HOSPITAL ASSOCIATION dba ASTRIA SUNNYSIDE HOSPITAL (501330, Sunnyside, CAH)",
  "Astria Toppenish Hospital", "EXACT", "500037", "SHC MEDICAL CENTER TOPPENISH dba ASTRIA TOPPENISH HOSPITAL (500037, Toppenish)",
  "Cascade Medical Center", "EXACT", "501313", "CHELAN COUNTY PUBLIC HOSPITAL DISTRICT NO. 1 dba CASCADE MEDICAL CENTER (501313, Leavenworth, CAH)",
  "Confluence Health", "BRIDGE", "500016", "CENTRAL WASHINGTON HEALTH SERVICES ASSOCIATION dba CONFLUENCE HEALTH HOSPITAL (500016, Wenatchee): the string is the DBA less 'Hospital'",
  "EvergreenHealth Monroe", "BRIDGE", "500084", "PUBLIC HOSPITAL DISTRICT 1 OF SNOHOMISH COUNTY dba EVERGREEN HEALTH MONROE (500084, Monroe): the DBA spelled with a space",
  "Forks Community Hospital", "EXACT", "501325", "CLALLAM COUNTY PUBLIC HOSPITAL DISTRICT NO 1 dba FORKS COMMUNITY HOSPITAL (501325, Forks, CAH)",
  "Garfield County Hospital", "BRIDGE", "501301", "GARFIELD COUNTY MEMORIAL HOSPITAL DISTRICT dba GARFIELD COUNTY PUBLIC HOSPITAL DISTRICT #1 (501301, Pomeroy, CAH): the only Garfield County hospital",
  "Grays Harbor Community Hospital", "EXACT", "500031", "GRAYS HARBOR COMMUNITY HOSPITAL (500031, Aberdeen)",
  "Island Health", "BRIDGE", "500007", "PUBLIC HOSPITAL DISTRICT NO 2 SKAGIT COUNTY WASHINGTON dba ISLAND HOSPITAL (500007, Anacortes): Island Health is the Anacortes district's trading name (general knowledge)",
  "Jefferson Healthcare", "EXACT", "501323", "JEFFERSON COUNTY PUBLIC HOSPITAL DISTRICT NO 2 dba JEFFERSON HEALTHCARE (501323, Port Townsend, CAH)",
  "Kittitas Valley Healthcare", "EXACT", "501333", "KITTITAS COUNTY PUBLIC HOSPITAL DIST 1 dba KITTITAS VALLEY HEALTHCARE (501333, Ellensburg, CAH)",
  "Mid Valley Hospital", "EXACT", "501328", "OKANOGAN COUNTY PUBLIC HOSPITAL DISTRICT NO. 3 dba MID VALLEY HOSPITAL (501328, Omak, CAH)",
  "Newport Community Hospital", "EXACT", "501310", "PEND OREILLE COUNTY PUBLIC HOSPITAL DISTRICT NO 1 dba NEWPORT COMMUNITY HOSPITAL (501310, Newport, CAH)",
  "North Valley Hospital District", "BRIDGE", "501321", "OKANOGAN COUNTY PUBLIC HOSPITAL DIST NO 4 dba NORTH VALLEY HOSPITAL (501321, Tonasket, CAH)",
  "Odessa Memorial Healthcare Center", "EXACT", "501307", "LINCOLN COUNTY PUBLIC HOSPITAL DISTRICT 1 dba ODESSA MEMORIAL HEALTHCARE CENTER (501307, Odessa, CAH)",
  "Olympic Medical Center", "EXACT", "500072", "CLALLAM COUNTY PUBLIC HOSPITAL DISTRICT 2 dba OLYMPIC MEDICAL CENTER (500072, Port Angeles)",
  "Othello Community Hospital", "EXACT", "501318", "ADAMS COUNTY PUBLIC HOSPITAL DISTRICT 3 dba OTHELLO COMMUNITY HOSPITAL (501318, Othello, CAH)",
  "Prosser Public Hospital", "BRIDGE", "501312", "PROSSER PUBLIC HOSPITAL DISTRICT OF BENTON COUNTY dba PROSSER MEMORIAL HEALTH (501312, Prosser, CAH): the legal name's prefix",
  "Providence St. Mary Medical Center", "EXACT", "500002", "PROVIDENCE HEALTH & SERVICES - WASHINGTON dba PROVIDENCE ST MARY MEDICAL CENTER (500002, Walla Walla)",
  "Samaritan Healthcare", "BRIDGE", "500033", "GRANT COUNTY PUBLIC HOSPITAL DISTRICT 1 dba SAMARITAN HOSPITAL (500033, Moses Lake): Samaritan Healthcare is the district's trading name (general knowledge); MultiCare Good Samaritan (Puyallup) is a different body",
  "Seattle Children's Hospital", "EXACT", "503300", "SEATTLE CHILDRENS HOSPITAL (503300, Seattle)",
  "Skagit Regional Health", "BRIDGE", NA, "PUBLIC HOSPITAL DIST NO 1 SKAGIT dba SKAGIT VALLEY HOSPITAL (500003, Mount Vernon) and dba CASCADE VALLEY HOSPITAL (500060, Arlington): Skagit Regional Health is the district's trading name (general knowledge), and the entity holds two hospital CCNs, so none on the row",
  "Skyline Health", "BRIDGE", "501315", "PUBLIC HOSPITAL DISTRICT NO. 2, KLICKITAT COUNTY dba SKYLINE HOSPITAL (501315, White Salmon, CAH)",
  "Summit Pacific Medical Center", "EXACT", "501304", "GRAYS HARBOR COUNTY PUBLIC HOSPITAL DISTRICT NO 1 dba SUMMIT PACIFIC MEDICAL CENTER (501304, Elma, CAH)",
  "Snoqualmie Valley Health", "BRIDGE", "501338", "PUBLIC HOSPITAL DISTRICT NO 4 KING COUNTY dba SNOQUALMIE VALLEY HOSPITAL (501338, Snoqualmie, CAH)",
  "Trios Health", "EXACT", "500053", "RCCH TRIOS HEALTH LLC dba TRIOS HEALTH (500053, Kennewick)",
  "St. Elizabeth Hospital", "EXACT", "501335", "ENUMCLAW REGIONAL HOSPITAL ASSOCIATION dba ST ELIZABETH HOSPITAL (501335, Enumclaw, CAH)",
  "Whitman Hospital", "BRIDGE", "501327", "PUBLIC HOSPITAL DISTRICT NO 3 OF WHITMAN COUNTY dba WHITMAN HOSPITAL & MEDICAL CLINICS (501327, Colfax, CAH); Pullman Regional (Whitman County District 1-A) is a different body")
WAA_WA_FED <- "data/evidence/federal_records/2026-09-25/cms_hosp_enrollments_WA.json"

waa_obl_text <- function() waa_squish(paste(rhtp_pdf_text(here::here(WAA_OBL_PDF)), collapse = " "))

waa_assert_obl <- function() {
  t <- waa_obl_text()
  need <- c(WAA_MES_SENTENCE, "Maternal, emergency, and specialty services $9.67 million",
            "Estimated amount", "November 5, 2026",
            "financial assistance award totaling $181,257,515.06 with 100 percent funded by CMS/HHS")
  miss <- need[!vapply(need, function(w) grepl(w, t, fixed = TRUE), logical(1))]
  if (length(miss)) stop("[WA] HCA's obligation summary no longer says: ", paste(miss, collapse = " | "), call. = FALSE)
  # every one of the 28 names is printed, and there are 28
  if (nrow(WAA_MES) != 28L || anyDuplicated(WAA_MES$awardee)) stop("[WA] WAA_MES is not 28 distinct names.", call. = FALSE)
  nm <- gsub("'", "'", WAA_MES$awardee)
  absent <- nm[!vapply(nm, function(w) grepl(w, t, fixed = TRUE), logical(1))]
  if (length(absent)) stop("[WA] not on HCA's list: ", paste(absent, collapse = "; "), call. = FALSE)
  # the footer is the allotment (Tier 1), never this pool (§0.2)
  rhtp_assert_footer_tiers(tibble::tibble(state = WAA_STATE, rfp = "HCA obligation summary 2026-11-05",
                                          footer_amount = 181257515.06, footer_tier = "STATE_ALLOTMENT"))
  if (WAA_OBL_DATE <= WAA_NOA_DATE) stop("[WA] date test.", call. = FALSE)
  invisible(TRUE)
}

waa_mes_rows <- function(start_row) {
  m <- WAA_MES
  why <- paste0(ifelse(m$match == "EXACT",
                       "EXACT federal record: CMS WA Hospital Enrollments carry the string as the enrolled name or DBA: ",
                       "HAND-READ BRIDGE (LOW): "), m$enrolment, ".")
  base <- tibble::tibble(state = WAA_STATE, recipient_confirmed = "Yes", amount_confirmed = "No",
    fiscal_year = "FY2026 (Year 1)", source_document_title = "HCA, Washington's RHT funds are 100% obligated (2026-11-05)",
    state_source_url = WAA_DECK_URL, validation_source_type = "AGENCY_PRESS_RELEASE",
    extraction_method = "PDF_TEXT", validator = "R/03bd_wa_year1_awardees.R", aha_id = NA_character_,
    rural_designation = NA_character_, reviewer = NA_character_,
    initiative = "1. Ignite innovation in rural hospitals: Maternal, emergency, and specialty services",
    award_pool = "HCA Initiative 1: Maternal, emergency, and specialty services ($9.67M estimated, 28 hospitals)",
    budget_period = "Budget Period 1", flow_type = "DIRECT", hospital_benefiting = "Yes",
    intermediary_name = NA_character_, round_amount = NA_real_, announcement_date = WAA_OBL_DATE,
    source_archive_path = WAA_OBL_PDF)
  mem <- dplyr::bind_cols(base[rep(1, 28), ], tibble::tibble(
    awardee = m$awardee, amount = NA_real_, recipient_type = "HOSPITAL_OR_SYSTEM",
    distributed_to_hospital = "Yes",
    note = paste0("One of the 28 hospitals HCA lists for maternal, emergency, and specialty services (2026-11-05): '",
                  WAA_MES_SENTENCE, "'. No per-hospital figure; the pool's $9.67 million is printed under HCA's ",
                  "column 'Estimated amount' and is ONE POOL_NAMED_HOSPITALS row of this file, never divided (§6.2)."),
    ccn = m$ccn,
    recipient_type_source = paste0("TYPED (session 118, ", m$match, "): ", why),
    determination_confidence = ifelse(m$match == "EXACT", "MEDIUM", "LOW"),
    flag_reason = NA_character_, hospital_attribution = "NAMED_HOSPITAL",
    determination_basis = paste0("§10.2 DIRECT: ", why, " NAMED AT $0: HCA prices only the 28-hospital pool (owner ruling c, session 118)."),
    amount_basis = "NO AMOUNT: HCA publishes no per-hospital figure. The pool is a separate row; it is never divided.",
    basis_type = ifelse(m$match == "EXACT", "ORG_WEBSITE", "GENERAL_KNOWLEDGE"),
    cms_enrolment_record = paste0("CMS WA Hospital Enrollments: ", m$enrolment, " (", WAA_WA_FED, ")")))
  pool <- dplyr::bind_cols(base, tibble::tibble(
    awardee = paste0("28 hospitals named by HCA for maternal, emergency, and specialty services (",
                     paste(m$awardee, collapse = "; "), ")"),
    amount = WAA_MES_POOL, recipient_type = "HOSPITAL_OR_SYSTEM", distributed_to_hospital = "Yes",
    note = paste0("HCA (2026-11-05), Initiative 1, under 'Estimated amount': 'Maternal, emergency, and specialty services $9.67 million'; '",
                  WAA_MES_SENTENCE, "'. 28 named, no split. The page says Washington's funds are '100% obligated'."),
    ccn = NA_character_,
    recipient_type_source = "TYPED (session 118): each of the 28 named recipients is a hospital on CMS WA Hospital Enrollments (see their own rows).",
    determination_confidence = "MEDIUM", flag_reason = "AMOUNT_ROUNDED_IN_SOURCE;AMOUNT_PRELIMINARY;MULTI_RECIPIENT_FIELD",
    hospital_attribution = "POOL_NAMED_HOSPITALS",
    determination_basis = paste0("§10.2 DIRECT, POOL_NAMED_HOSPITALS (owner ruling c, session 118; §7 'a pool is judged per priced component'): ",
                                 "a figure HCA states for this activity, whose recipients are the 28 hospitals it names and no one else ('hospitals could apply'). ",
                                 "No per-hospital split, so one pool row, never divided (§6.2); Ohio's shape. VULNERABILITY: HCA labels every figure 'Estimated amount'."),
    amount_basis = "HCA's 'Estimated amount', rounded to $10,000 ('$9.67 million'); the stated obligation, never un-rounded or split.",
    basis_type = "STATE_SOURCE", cms_enrolment_record = NA_character_))
  dplyr::bind_rows(mem, pool) %>% dplyr::mutate(row_no = start_row + dplyr::row_number() - 1L)
}

wa_year1_status <- function() {
  WAA_STATUS %>%
    mutate(state = WAA_STATE, source = WAA_DECK,
           as_of = as.character(WAA_DECK_DATE)) %>%
    select(state, everything())
}

wa_validate <- function() {
  waa_assert_sources()
  waa_assert_obl()
  d <- wa_year1_awardees()
  stopifnot(nrow(d) == 8L + 29L,
            abs(sum(d$amount, na.rm = TRUE) - (67020000 + WAA_MES_POOL)) < 0.5,
            !"amount" %in% names(wa_year1_status()))
  mp <- rhtp_hospital_dollar_partition(d[d$row_no > 8L, ])
  stopifnot(sum(mp$rows[mp$bucket == "NAMED_HOSPITAL"]) == 28L,
            abs(sum(mp$dollars[mp$bucket == "POOL_NAMED_HOSPITALS"]) - WAA_MES_POOL) < 0.5)
  p <- rhtp_hospital_dollar_partition(d[d$row_no <= 8L, ])
  if (nrow(p) > 0 && sum(p$rows) > 0) {
    # The BUILDER's own name-rule typing reaches no bucket. The two University
    # of Washington rows reach NAMED_HOSPITAL only through session 71's
    # enrolled-hospital-operator overlay (R/03bj, CCN 500008), applied in
    # wa_build() after this check.
    stop("[WA] a Washington row reached a hospital bucket by the builder's own ",
         "typing; none should (session 71's CMS overlay is applied after).",
         call. = FALSE)
  }
  message("[WA] all assertions pass.")
  invisible(TRUE)
}

wa_build <- function() {
  wa_validate()
  # SESSION 71: §10.2's enrolled-hospital-operator overlay (University of
  # Washington, CCN 500008), so a rebuild does not wipe it.
  s71 <- new.env()
  suppressMessages(source(here::here("R", "03bj_enrolled_hospital_operator.R"),
                          local = s71))
  readr::write_csv(s71$s71_overlay(wa_year1_awardees(), "wa_year1_awardees.csv"),
                   here::here(WAA_AWARD_CSV), na = "")
  readr::write_csv(wa_year1_status(), here::here(WAA_STATUS_CSV), na = "")
  message("[WA] wrote ", nrow(wa_year1_awardees()), " award rows and ", nrow(WAA_STATUS), " status rows.")
}

wa_report <- function() {
  d <- wa_year1_awardees()
  print(as.data.frame(d[, c("awardee", "amount", "flow_type",
                            "distributed_to_hospital")]), row.names = FALSE)
  print(as.data.frame(waa_subtotal_check()), row.names = FALSE)
}

if (!interactive() && identical(sys.nframe(), 0L)) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) wa_validate()
  if ("--build" %in% args) wa_build()
  if ("--report" %in% args) wa_report()
  if (!length(args)) message("Usage: --validate | --build | --report")
}
