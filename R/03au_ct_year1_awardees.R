#!/usr/bin/env Rscript
# 03au_ct_year1_awardees.R ---------------------------------------------------
#
# CONNECTICUT -- $50 MILLION OF EXECUTED GRANT AGREEMENTS, FOUR RURAL
# HOSPITALS AND ONE VENDOR, AND ONE PAIR OF HOSPITALS WITH NO SPLIT.
#
# The Governor's release of 2026-09-16 (the day BEFORE CMS's):
#
#   "the Connecticut Department of Social Services (DSS) has finalized $50
#    million in Rural Health Transformation Project (RHTP) grant agreements,
#    including $46 million going to four critical rural hospital systems and
#    $4 million awarded to a technical assistance vendor ... $20.23 million
#    for Day Kimball Hospital in Putnam; $13.12 million for Sharon Hospital in
#    Sharon; and $12.65 million for Hartford HealthCare's Windham Hospital in
#    Willimantic and Charlotte Hungerford Hospital in Torrington. As part of
#    this effort, Mathematica was awarded $3.98 million ..."
#
# FOUR ROWS, $49,980,000, AND EVERY FIGURE IS ROUNDED IN THE SOURCE (to the
# $10,000), so every row carries AMOUNT_ROUNDED_IN_SOURCE and
# `amount_confirmed = No`. The three hospital figures sum to the release's
# own "$46 million" exactly; with Mathematica the four sum to $49.98M against
# a headline "$50 million". Neither is corrected (§8).
#
# THE HARTFORD HEALTHCARE PAIR IS ONE ROW AND IS NOT DIVIDED. Windham
# Community Memorial Hospital (CMS CCN 070021) and The Charlotte Hungerford
# Hospital (CCN 070011) are two separately enrolled hospitals, both named, and
# the release publishes ONE figure for the two. $12.65M / 2 = $6.325M is
# nobody's figure (§6.2). The row is `HOSPITAL_OR_SYSTEM`/`DIRECT`/`Yes`
# with `hospital_attribution = POOL_NAMED_HOSPITALS` -- Nebraska's code for
# "hospitals NAMED, NO per-hospital split" -- and MULTI_RECIPIENT_FIELD. It is
# not an intermediary pass-through (Nebraska's NHVN was); the two hospitals
# are the grantees ("Four Rural Hospitals ... Execute Grant Agreements") and
# Hartford HealthCare is their system. NAMED_HOSPITAL would assert that one
# named hospital received $12.65M, which the release does not say.
#
# MATHEMATICA IS A VENDOR. "a technical assistance vendor to support
# hospitals" -- §10.2 IN_KIND_BENEFIT: the vendor keeps the money and
# hospitals receive a service. $0 of hospital money, hospital_benefiting Yes.
#
# §0.2: the release's CMS footer prints $154,249,105.53, the ALLOTMENT.
# DSS's own RHTP pages still name nobody; R/03ac watches them and asserts only
# that this file, not it, holds the award rows.
#
# Usage:
#   Rscript R/03au_ct_year1_awardees.R --validate | --build | --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
  library(here); library(rlang)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

CT_STATE      <- "CT"
CT_RELEASE_FILE <- file.path("data", "evidence", "recheck", "2026-09-23", "CT",
                             "ct_governor_rhtp_50m_release.html")
CT_RELEASE_URL <- paste0(
  "https://portal.ct.gov/governor/news/press-releases/2026/09-2026/",
  "governor-lamont-announces-rural-health-transformation-program-invests-",
  "50-million")
CT_RELEASE_DATE <- as.Date("2026-09-16")
CT_NOA_DATE     <- as.Date("2025-12-29")
CT_AWARD_CSV    <- here::here("data", "reference", "ct_year1_awardees.csv")

ct_release_text <- function() {
  t <- paste(readLines(here::here(CT_RELEASE_FILE), warn = FALSE,
                       encoding = "UTF-8"), collapse = " ")
  t <- stringr::str_remove_all(t, stringr::regex(
    "<(script|style|noscript)[^>]*>.*?</\\1>", dotall = TRUE, ignore_case = TRUE))
  t <- stringr::str_replace_all(t, "<[^>]+>", " ")
  t <- stringr::str_replace_all(t, "&nbsp;|&#160;", " ")
  t <- stringr::str_replace_all(t, "&amp;", "&")
  t <- stringr::str_replace_all(t, "[‘’]|&#8217;|&rsquo;", "'")
  t <- stringr::str_replace_all(t, "‑", "-")
  stringr::str_squish(t)
}

CT_AWARDS <- tibble::tribble(
  ~awardee, ~amount, ~quote, ~recipient_type, ~flow_type, ~dist, ~attr, ~flags, ~why,
  "Day Kimball Hospital", 20230000,
  "$20.23 million for Day Kimball Hospital in Putnam",
  "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes", "NAMED_HOSPITAL",
  "AMOUNT_ROUNDED_IN_SOURCE",
  "CMS Hospital Enrollment: DAY KIMBALL HEALTHCARE, INC., Putnam, CCN 070003.",
  "Sharon Hospital", 13120000,
  "$13.12 million for Sharon Hospital in Sharon",
  "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes", "NAMED_HOSPITAL",
  "AMOUNT_ROUNDED_IN_SOURCE",
  "CMS Hospital Enrollment: VASSAR HEALTH CONNECTICUT INC dba SHARON HOSPITAL, CCN 070004.",
  "Hartford HealthCare -- Windham Hospital (Willimantic) and Charlotte Hungerford Hospital (Torrington)",
  12650000,
  "$12.65 million for Hartford HealthCare's Windham Hospital in Willimantic and Charlotte Hungerford Hospital in Torrington",
  "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes", "POOL_NAMED_HOSPITALS",
  "AMOUNT_ROUNDED_IN_SOURCE;MULTI_RECIPIENT_FIELD",
  "TWO NAMED HOSPITALS, ONE FIGURE, NO SPLIT. CMS Hospital Enrollment: WINDHAM COMMUNITY MEMORIAL HOSPITAL INC (CCN 070021) and THE CHARLOTTE HUNGERFORD HOSPITAL (CCN 070011), two separately enrolled hospitals of the Hartford HealthCare system. The release prints one combined figure; it is NOT divided (§6.2) -- $6.325M each is nobody's figure. POOL_NAMED_HOSPITALS because both hospitals are named and no per-hospital amount is published.",
  "Mathematica", 3980000,
  "Mathematica was awarded $3.98 million to provide technical assistance support to the rural hospitals",
  "VENDOR_OR_CONTRACTOR", "IN_KIND_BENEFIT", "No", "NOT_HOSPITAL",
  "AMOUNT_ROUNDED_IN_SOURCE",
  "The release: 'a technical assistance vendor to support hospitals'. §10.2 IN_KIND_BENEFIT -- the vendor keeps the money and hospitals receive a service."
)

ct_assert_release <- function(t = ct_release_text()) {
  want <- c(CT_AWARDS$quote,
            "has finalized $50 million in Rural Health Transformation Project (RHTP) grant agreements",
            "including $46 million going to four critical rural hospital systems")
  miss <- want[!vapply(want, function(w) grepl(w, t, fixed = TRUE), TRUE)]
  if (length(miss)) {
    stop("[CT] the release no longer says: ", paste(sQuote(miss), collapse = "; "),
         call. = FALSE)
  }
  hosp <- sum(CT_AWARDS$amount[CT_AWARDS$dist == "Yes"])
  if (abs(hosp - 46e6) > 0.5) {
    stop("[CT] the three hospital figures no longer sum to the release's own ",
         "'$46 million'.", call. = FALSE)
  }
  rhtp_assert_footer_text_tier(t, CT_STATE, "STATE_ALLOTMENT",
                               label = "CT Governor release footer")
  if (CT_RELEASE_DATE <= CT_NOA_DATE) stop("[CT] date test.", call. = FALSE)
  invisible(TRUE)
}

ct_year1_awardees <- function() {
  a <- CT_AWARDS
  cls <- rhtp_classify_recipient_type(a$awardee, CT_STATE)
  hosp <- a$dist == "Yes"
  tibble::tibble(
    state = CT_STATE,
    row_no = seq_len(nrow(a)),
    awardee = a$awardee,
    amount = a$amount,
    recipient_type = a$recipient_type,
    distributed_to_hospital = a$dist,
    note = paste("Executed grant agreement with DSS, announced 2026-09-16 by",
                 "Governor Lamont: rural hospital right-sizing and",
                 "infrastructure, Year 1."),
    recipient_confirmed = "Yes",
    amount_confirmed = "No",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = paste(
      "Governor Lamont Announces Connecticut's Rural Health Transformation",
      "Program Invests $50 Million in Rural Hospital Right-Sizing and",
      "Infrastructure"),
    state_source_url = CT_RELEASE_URL,
    validation_source_type = "GOVERNOR_PRESS_RELEASE",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03au_ct_year1_awardees.R",
    ccn = NA_character_,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    recipient_type_source = paste0(
      "TYPED (session 54): ", a$why, " Classifier said ", cls$recipient_type,
      "/", cls$determination_confidence, "."),
    determination_confidence = ifelse(hosp, "MEDIUM", "LOW"),
    flag_reason = a$flags,
    award_pool = "Rural Hospital Right-Sizing and Infrastructure",
    budget_period = "Budget Period 1",
    flow_type = a$flow_type,
    hospital_benefiting = "Yes",
    hospital_attribution = a$attr,
    intermediary_name = NA_character_,
    determination_basis = paste0("§10.2 ", a$flow_type, ": ", a$why),
    amount_basis = paste("ROUNDED IN SOURCE to the $10,000 ('$X.XX million');",
                         "the three hospital figures sum to the release's own",
                         "'$46 million'."),
    basis_type = ifelse(hosp, "ORG_WEBSITE", "STATE_SOURCE"),
    round_amount = NA_real_,
    announcement_date = CT_RELEASE_DATE,
    source_archive_path = CT_RELEASE_FILE)
}

ct_validate <- function() {
  ct_assert_release()
  d <- ct_year1_awardees()
  stopifnot(nrow(d) == 4L, abs(sum(d$amount) - 49980000) < 0.5)
  p <- rhtp_hospital_dollar_partition(d)
  stopifnot(all(p$bucket %in% c("NAMED_HOSPITAL", "POOL_NAMED_HOSPITALS")))
  message("[CT] all assertions pass.")
  invisible(TRUE)
}

ct_build <- function() {
  ct_validate()
  readr::write_csv(ct_year1_awardees(), CT_AWARD_CSV, na = "")
  message("[CT] wrote 4 award rows.")
}

ct_report <- function() {
  d <- ct_year1_awardees()
  print(as.data.frame(d[, c("awardee", "amount", "hospital_attribution")]),
        row.names = FALSE)
  print(as.data.frame(rhtp_hospital_dollar_partition(d)), row.names = FALSE)
}

if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) ct_validate()
  if ("--build" %in% args) ct_build()
  if ("--report" %in% args) ct_report()
  if (!length(args)) message("Usage: --validate | --build | --report")
}
