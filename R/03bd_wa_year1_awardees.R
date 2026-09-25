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

wa_year1_status <- function() {
  WAA_STATUS %>%
    mutate(state = WAA_STATE, source = WAA_DECK,
           as_of = as.character(WAA_DECK_DATE)) %>%
    select(state, everything())
}

wa_validate <- function() {
  waa_assert_sources()
  d <- wa_year1_awardees()
  stopifnot(nrow(d) == 8L,
            abs(sum(d$amount, na.rm = TRUE) - 67020000) < 0.5,
            !"amount" %in% names(wa_year1_status()))
  p <- rhtp_hospital_dollar_partition(d)
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
  message("[WA] wrote 8 award rows and ", nrow(WAA_STATUS), " status rows.")
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
