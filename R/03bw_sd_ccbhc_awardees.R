#!/usr/bin/env Rscript
# 03bw_sd_ccbhc_awardees.R ----------------------------------------------------
#
# SOUTH DAKOTA'S CCBHC ROUND -- "12 ... GRANTS TOTALING MORE THAN $13 MILLION",
# A THIRTEEN-MEMBER COHORT, AND NO PER-GRANT AMOUNT. Session 90.
#
# Governor Rhoden's 2026-09-24 release (news.sd.gov KB0047183): "Governor
# Rhoden announced 12 Certified Community Behavioral Health Clinic (CCBHC)
# modernization and infrastructure grants totaling more than $13 million. These
# grants are part of the Rural Health Transformation (RHT) funds". It then
# names "The CCBHC Cohort ... made up of 13 agencies", "selected in April
# following an open application period". CMS's release of the same day
# (archived by the CMS Routine under data/raw/cms/2026-09-24/newsroom/) says
# "$13 million" and "12 modernization and infrastructure grants to providers
# participating in South Dakota's Certified Community Behavioral Health Clinic
# (CCBHC) initiative". Neither names a grant recipient, and neither prices one.
#
# THIRTEEN NAMED, TWELVE GRANTS, AND THE GAP IS RECORDED, NOT RESOLVED. The
# release names the COHORT, not the grantees. Twelve grants among thirteen
# members means either one member received no grant or one grant covers two
# members; the source says neither, so no single member is confirmed as a
# grant recipient. Every row is `recipient_confirmed = Unclear` and the queue
# carries SD_CCBHC_COHORT_13_VS_12_GRANTS. This is CLAUDE.md §10 question 7 --
# what is the roster a roster OF? -- and the answer is "a cohort that is a
# superset of the grantees by one".
#
# POOL SHAPE: NO SPLIT IS INVENTED (§6.2). "More than $13 million" is the
# round's total, a FLOOR in the state's own words. `amount` is EMPTY on all
# thirteen rows and the pool sits in `round_amount` (13,000,000), repeated per
# row and never summed down the column -- NC SBHC's device (R/03br). Dividing
# would publish ~$1.08M per grant, a figure South Dakota has not published.
#
# AVERA BEHAVIORAL HEALTH IS NOT TYPED A HOSPITAL, AND THE CHECK IS ON DISK.
# CMS SD Hospital Enrollments (archived 2026-09-24, the release's own date) were
# read on the EXACT legal name, as the owner asked:
#   - No ORGANIZATION NAME or DBA in the SD Hospital, FQHC or RHC enrolment
#     files is "AVERA BEHAVIORAL HEALTH".
#   - The ONE enrolment flagged SUBGROUP - PSYCHIATRIC = Y is CCN 434003, STATE
#     OF SOUTH DAKOTA, dba the DHS Human Services Center -- the state hospital.
#   - The nearest Avera string is CCN 43S016, ORGANIZATION NAME AVERA MCKENNAN,
#     DBA "AVERA MCKENNAN BEHAVIORAL HEALTH SERVICES" -- an S-suffix
#     (psychiatric distinct-part unit) CCN of Avera McKennan's hospital.
# The cohort string is neither name, so §2 forbids a machine bridge and §7's
# enrolled-operator row does not reach it. The row keeps §8's standing
# fallback (NONPROFIT_CBO, LOW, RECIPIENT_TYPE_INFERRED), and the owner question
# SD_CCBHC_AVERA_BH_ENROLMENT_BRIDGE asks whether to bridge it by hand. $0 moves
# either way: no amount is published, and receipt itself is Unclear.
#
# The other twelve are community mental health centres and a Volunteers of
# America affiliate. None appears on any SD enrolment file (asserted below);
# the release states no form for any of them, so all twelve take the same
# fallback from the shared classifier.
#
# §6.2: announced 2026-09-24, after the 2025-12-29 NOA; the cohort was
# "selected in April" (the year is not printed; the release is 2026's). The
# release states RHT provenance in its own words and carries no CMS footer, so
# there is no §0.2 footer figure to tier.
#
# A SEPARATE FILE, on NC SBHC's and OK's precedent: sd_rht_contracts.csv is the
# open.sd.gov register and sd_year1_awardees.csv is the two rounds that name
# nobody. This is the third SD shape: a named cohort with a pool.
#
# Usage:
#   Rscript R/03bw_sd_ccbhc_awardees.R --validate
#   Rscript R/03bw_sd_ccbhc_awardees.R --build
#   Rscript R/03bw_sd_ccbhc_awardees.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

SDC_STATE     <- "SD"
SDC_POOL      <- 13000000                 # "more than $13 million" -- a FLOOR
SDC_GRANTS    <- 12L                      # "12 ... grants"
SDC_COHORT    <- 13L                      # "made up of 13 agencies"
SDC_NOA_DATE  <- as.Date("2025-12-29")
SDC_ANNOUNCED <- as.Date("2026-09-24")
SDC_URL       <- "https://news.sd.gov/kb_view.do?sysparm_article=KB0047183"
SDC_ARCHIVE   <- file.path("data", "evidence", "SD", "ccbhc", "KB0047183.html")
SDC_SHA256    <- "1d6b5ef82437ae427e1dcb1c4542c1a2581e3d3c9c41bb8b6761371a32ac4628"
SDC_CMS_ARCHIVE <- file.path(
  "data", "raw", "cms", "2026-09-24", "newsroom", "releases",
  "trump-administration-announces-13-million-investment-expand-behavioral-healthcare-create-24-7-mobile.html")
SDC_CSV       <- here::here("data", "reference", "sd_year1_ccbhc_awardees.csv")
SDC_TITLE     <- "Gov. Rhoden Awards Behavioral Health Grants through RHT (2026-09-24)"
SDC_ROUND     <- "Certified Community Behavioral Health Clinic (CCBHC) modernization and infrastructure grants"
SDC_FED_DIR   <- file.path("data", "evidence", "SD", "federal_records", "2026-09-24")
SDC_FED <- c(hosp = "cms_hosp_enrollments_SD.json",
             fqhc = "cms_fqhc_enrollments_SD.json",
             rhc  = "cms_rhc_enrollments_SD.json")

SDC_ROSTER_PREFIX <- "Cohort members include "
SDC_NAMES <- c(
  "Avera Behavioral Health", "Brookings Behavioral Health and Wellness",
  "Capital Area Counseling", "Community Counseling Services",
  "Dakota Counseling Institute", "Human Service Agency",
  "Lewis & Clark Behavioral Health", "Northeastern Mental Health Center",
  "Southeastern Directions for Life", "Southern Plains Behavioral Health Services",
  "Three Rivers Mental Health and Chemical Dependency Center", "VOA - Dakotas",
  "West River Mental Health")

sdc_norm <- function(t) {
  t %>%
    stringr::str_replace_all(" ", " ") %>%
    stringr::str_replace_all("[‘’]", "'") %>%
    stringr::str_replace_all("[“”]", "\"") %>%
    stringr::str_replace_all("[–—]", "-") %>%
    stringr::str_squish()
}

sdc_text <- function() {
  raw <- readr::read_file_raw(here::here(SDC_ARCHIVE))
  if (digest::digest(raw, algo = "sha256", serialize = FALSE) != SDC_SHA256) {
    stop("[SD CCBHC] the archived release's SHA-256 does not match MANIFEST.txt.",
         call. = FALSE)
  }
  sdc_norm(rvest::html_text2(rvest::read_html(rawToChar(raw))))
}

#' The thirteen names, read out of the release's own cohort sentence
sdc_parse <- function(t = sdc_text()) {
  m <- stringr::str_match(t, paste0(SDC_ROSTER_PREFIX, "(.+?)\\. Governor Rhoden"))[, 2]
  if (is.na(m)) stop("[SD CCBHC] the cohort sentence is not in the archive.", call. = FALSE)
  nm <- stringr::str_trim(strsplit(sub(", and ", ", ", m, fixed = TRUE), ", ", fixed = TRUE)[[1]])
  if (!identical(nm, SDC_NAMES)) {
    stop("[SD CCBHC] the cohort sentence no longer reads as the thirteen names ",
         "this file was built on: ", paste(nm, collapse = " | "), call. = FALSE)
  }
  nm
}

sdc_assert_source <- function(t = sdc_text()) {
  nm <- sdc_parse(t)
  if (length(nm) != SDC_COHORT) stop("[SD CCBHC] thirteen names.", call. = FALSE)
  checks <- c(
    grants = "Governor Rhoden announced 12 Certified Community Behavioral Health Clinic (CCBHC) modernization and infrastructure grants totaling more than $13 million.",
    provenance = "These grants are part of the Rural Health Transformation (RHT) funds",
    cohort = "The CCBHC Cohort is made up of 13 agencies throughout the State of South Dakota.",
    selected = "The Cohort was selected in April following an open application period.",
    next_round = "The next round of funding is anticipated later this fall.")
  for (k in names(checks)) {
    if (!grepl(checks[[k]], t, fixed = TRUE)) {
      stop("[SD CCBHC] the '", k, "' sentence is gone from the archive.", call. = FALSE)
    }
  }
  # No per-grant figure and no CMS footer: the only currency figure is the pool.
  cur <- unique(tolower(stringr::str_extract_all(
    t, stringr::regex("\\$[0-9][0-9,.]*( million| billion)?", ignore_case = TRUE))[[1]]))
  if (!identical(cur, "$13 million")) {
    stop("[SD CCBHC] a currency figure the file does not account for: ",
         paste(setdiff(cur, "$13 million"), collapse = ", "),
         " -- a per-grant amount, or a footer? Then REWRITE the file.", call. = FALSE)
  }
  cms <- sdc_norm(xml2::xml_text(xml2::read_html(here::here(SDC_CMS_ARCHIVE))))
  for (p in c("a $13 million investment is being delivered",
              "12 modernization and infrastructure grants to providers participating in South Dakota's Certified Community Behavioral Health Clinic (CCBHC) initiative")) {
    if (!grepl(p, cms, fixed = TRUE)) {
      stop("[SD CCBHC] CMS's 2026-09-24 release no longer carries: ", p, call. = FALSE)
    }
  }
  if (!(SDC_ANNOUNCED > SDC_NOA_DATE)) stop("[SD CCBHC] §6.2 date test.", call. = FALSE)
  invisible(TRUE)
}

sdc_federal <- function() {
  rd <- function(f, k) {
    j <- jsonlite::fromJSON(here::here(SDC_FED_DIR, f))
    psych <- if ("SUBGROUP - PSYCHIATRIC" %in% names(j)) j$`SUBGROUP - PSYCHIATRIC` else NA_character_
    tibble::tibble(kind = k, ccn = as.character(j$CCN), org = j$`ORGANIZATION NAME`,
                   dba = j$`DOING BUSINESS AS NAME`, psychiatric = psych)
  }
  dplyr::bind_rows(rd(SDC_FED[["hosp"]], "HOSPITAL"), rd(SDC_FED[["fqhc"]], "FQHC"),
                   rd(SDC_FED[["rhc"]], "RHC"))
}

#' The owner's check: Avera Behavioral Health against CMS's SD enrolment, on
#' the EXACT legal name. Returns the facts the typing rests on, and fails if
#' any of them has moved.
sdc_avera_enrolment_check <- function(f = sdc_federal()) {
  key <- function(x) toupper(stringr::str_squish(dplyr::coalesce(x, "")))
  exact <- f[key(f$org) == "AVERA BEHAVIORAL HEALTH" | key(f$dba) == "AVERA BEHAVIORAL HEALTH", ]
  psych <- f[f$kind == "HOSPITAL" & f$psychiatric %in% "Y", ]
  near  <- f[f$kind == "HOSPITAL" & grepl("BEHAVIORAL", key(f$dba)) & grepl("^AVERA", key(f$org)), ]
  if (nrow(exact)) {
    stop("[SD CCBHC] CMS SD enrolment NOW carries 'AVERA BEHAVIORAL HEALTH' exactly (CCN ",
         paste(exact$ccn, collapse = "/"), "). Re-type the row under §7's enrolled-operator ",
         "rule and close SD_CCBHC_AVERA_BH_ENROLMENT_BRIDGE.", call. = FALSE)
  }
  if (!identical(psych$ccn, "434003") || psych$org != "STATE OF SOUTH DAKOTA") {
    stop("[SD CCBHC] SD's psychiatric-hospital enrolment set moved: ",
         paste(psych$ccn, psych$org, collapse = "; "), call. = FALSE)
  }
  if (!identical(near$ccn, "43S016") || near$org != "AVERA MCKENNAN" ||
      near$dba != "AVERA MCKENNAN BEHAVIORAL HEALTH SERVICES") {
    stop("[SD CCBHC] the nearest Avera behavioral-health enrolment moved: ",
         paste(near$ccn, near$org, near$dba, collapse = "; "), call. = FALSE)
  }
  # And none of the other twelve is on any SD enrolment file under its own name.
  hits <- f[key(f$org) %in% toupper(SDC_NAMES) | key(f$dba) %in% toupper(SDC_NAMES), ]
  if (nrow(hits)) {
    stop("[SD CCBHC] a cohort name is on a CMS SD enrolment file: ",
         paste(hits$kind, hits$org, hits$dba, collapse = "; "), call. = FALSE)
  }
  invisible(list(exact = exact, psychiatric = psych, nearest = near))
}

SDC_AVERA_FINDING <- paste0(
  "CMS SD enrolment checked on the EXACT legal name (archived 2026-09-24, ", SDC_FED_DIR,
  "): no Hospital, FQHC or RHC ORGANIZATION NAME or DBA is 'AVERA BEHAVIORAL HEALTH'. ",
  "SD's one SUBGROUP-PSYCHIATRIC hospital is CCN 434003, STATE OF SOUTH DAKOTA (DHS Human ",
  "Services Center). The nearest Avera string is CCN 43S016, ORGANIZATION NAME AVERA ",
  "MCKENNAN, DBA 'AVERA MCKENNAN BEHAVIORAL HEALTH SERVICES' -- a psychiatric distinct-part ",
  "unit CCN of Avera McKennan's hospital. Neither name is the cohort string, so no machine ",
  "bridge is made (§2) and §7's enrolled-operator row does not reach it. Owner question ",
  "SD_CCBHC_AVERA_BH_ENROLMENT_BRIDGE.")

sdc_awardees <- function(nm = sdc_parse()) {
  cl <- rhtp_classify_recipient_type(nm, SDC_STATE)
  fl <- rhtp_classify_flow(cl$recipient_type,
                           rep("CCBHC modernization and infrastructure grant", length(nm)),
                           award_made = TRUE)
  avera <- nm == "Avera Behavioral Health"
  gap <- paste0(
    "THE RELEASE NAMES THE COHORT, NOT THE GRANTEES: 'The CCBHC Cohort is made up of 13 ",
    "agencies' against '12 ... grants'. No single member is stated to have received a grant, ",
    "so recipient_confirmed = Unclear on every row; the 13-vs-12 gap is recorded, NOT ",
    "resolved (queue SD_CCBHC_COHORT_13_VS_12_GRANTS).")
  tibble::tibble(
    state = SDC_STATE,
    row_no = seq_along(nm),
    awardee = nm,
    amount = NA_real_,
    recipient_type = cl$recipient_type,
    distributed_to_hospital = fl$distributed_to_hospital,
    note = paste0(
      "Announced by Governor Rhoden on 2026-09-24: '12 Certified Community Behavioral Health ",
      "Clinic (CCBHC) modernization and infrastructure grants totaling more than $13 million. ",
      "These grants are part of the Rural Health Transformation (RHT) funds'. ", gap,
      " THE $13,000,000 IS A POOL FLOOR ('more than') -- no per-grant amount is published, so ",
      "`amount` is empty and nothing is divided (§6.2)."),
    recipient_confirmed = "Unclear",
    amount_confirmed = "No",
    fiscal_year = "2026",
    source_document_title = SDC_TITLE,
    state_source_url = SDC_URL,
    validation_source_type = "GOVERNOR_PRESS_RELEASE",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03bw_sd_ccbhc_awardees.R",
    ccn = NA_character_,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    recipient_type_source = paste0(
      "CLASSIFIER (", cl$rule, "): ", cl$recipient_type_basis,
      ifelse(avera, paste0(" ", SDC_AVERA_FINDING),
             " Not on any CMS SD Hospital, FQHC or RHC enrolment file under this name (checked 2026-09-24 archive).")),
    determination_confidence = rhtp_confidence_ceiling(cl$determination_confidence),
    flag_reason = "AMOUNT_MISSING;RECIPIENT_TYPE_INFERRED",
    award_pool = SDC_ROUND,
    budget_period = "BP1 (2025-12-29 to 2026-10-30)",
    flow_type = fl$flow_type,
    hospital_benefiting = fl$hospital_benefiting,
    hospital_attribution = "NOT_HOSPITAL",
    intermediary_name = NA_character_,
    determination_basis = paste0(
      fl$flow_basis, " Form not stated in the release; §8's standing fallback. ", gap),
    amount_basis = paste0(
      "South Dakota publishes NO per-grant amount. 'More than $13 million' is the round's ",
      "FLOOR, carried in `round_amount` on each of the thirteen rows and never summed down ",
      "the column. Thirteen cohort members, twelve grants: the pool is not one row per grant."),
    round_name = SDC_ROUND,
    round_awards = SDC_GRANTS,
    cohort_members = SDC_COHORT,
    round_amount = SDC_POOL,
    round_amount_is_floor = TRUE,
    announcement_date = SDC_ANNOUNCED,
    source_archive_path = SDC_ARCHIVE,
    basis_type = NA_character_)
}

sdc_assert_rows <- function(a) {
  if (nrow(a) != SDC_COHORT) stop("[SD CCBHC] thirteen rows.", call. = FALSE)
  if (any(!is.na(a$amount))) stop("[SD CCBHC] an amount appeared; none is published.",
                                  call. = FALSE)
  if (any(a$recipient_confirmed != "Unclear")) {
    stop("[SD CCBHC] a cohort member is coded a confirmed grantee; the release names ",
         "13 members for 12 grants and confirms none individually.", call. = FALSE)
  }
  if (any(a$distributed_to_hospital == "Yes")) {
    stop("[SD CCBHC] a hospital row appeared; no cohort member is enrolment-typed a hospital.",
         call. = FALSE)
  }
  if (any(a$determination_confidence == "HIGH")) stop("[SD CCBHC] HIGH without a CCN (§7).",
                                                       call. = FALSE)
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "determination_confidence", "hospital_attribution", "recipient_confirmed")) {
    bad <- setdiff(stats::na.omit(unique(a[[col]])), rhtp_vocabulary(col))
    if (length(bad)) stop("[SD CCBHC] ", col, " outside §8: ", paste(bad, collapse = ", "),
                          call. = FALSE)
  }
  fr <- unique(unlist(strsplit(a$flag_reason, ";", fixed = TRUE)))
  if (length(setdiff(fr, rhtp_vocabulary("flag_reason")))) {
    stop("[SD CCBHC] flag_reason outside §8.", call. = FALSE)
  }
  if (!all(a$validation_source_type %in% rhtp_vocabulary("source_doc_type"))) {
    stop("[SD CCBHC] validation_source_type outside §8's source_doc_type.", call. = FALSE)
  }
  invisible(TRUE)
}

sdc_validate <- function() {
  t <- sdc_text()
  sdc_assert_source(t)
  sdc_avera_enrolment_check()
  a <- sdc_awardees(sdc_parse(t))
  sdc_assert_rows(a)
  message("[SD CCBHC] all assertions pass.")
  invisible(a)
}

sdc_build <- function() {
  a <- sdc_validate()
  readr::write_csv(a, SDC_CSV, na = "")
  message("[SD CCBHC] wrote ", nrow(a), " rows, amount EMPTY on every one, ",
          "recipient_confirmed Unclear on every one; 0 hospital rows.")
  invisible(a)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) sdc_validate()
  if ("--build" %in% args) sdc_build()
  if ("--report" %in% args) print(readr::read_csv(SDC_CSV, show_col_types = FALSE) %>%
                                    dplyr::select(awardee, recipient_type,
                                                  distributed_to_hospital,
                                                  recipient_confirmed, round_amount))
  if (!length(args)) message("Usage: --validate | --build | --report")
}
