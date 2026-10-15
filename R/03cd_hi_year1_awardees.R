# 03cd_hi_year1_awardees.R ---------------------------------------------------
# Hawaii Year 1 -> data/reference/hi_year1_awardees.csv   (session 101)
#
# HAWAII'S FIRST AWARD FILE: THREE NAMED NOTICES OF AWARD, NO AMOUNTS.
# SHPDA's RHTP page (archived script-stripped 2026-10-14, session 100) lists
# the Rural Value-Based Innovation (RVBI) line, "$25 million", and under it
# three projects, each "(Notice of Award on <date> to <recipient>)":
#
#   8/28  Hawaii Primary Care Association      Statewide FQHC Infrastructure,
#                                              Analytics, Readiness Funding,
#                                              and Transformation Support
#   9/3   Healthcare Association of Hawaii     Statewide Hospital Infrastructure,
#                                              Analytics, Readiness Funding,
#                                              and Transformation Support
#   9/11  Physicians of Southwest              Clinically Integrated Network and
#         Washington, LLC                      Managed Services Organization Support
#
# NO AMOUNT IS PUBLISHED ON THE PAGE. It links "Hawaii Awards & Notices Data
# System" (HANDS), where the amounts are, and HANDS answers 403 to this
# environment: the amounts are UNKNOWN, not zero (§0.4). The $25 million is
# the RVBI initiative's Tier 2 line, never divided (§6.2). RCJ prices HPCA at
# $17,000,000 and that figure is unverified (see Hawaii's RCJ disposition, built by R/03bh).
#
# THE CODINGS (owner instruction, session 101):
#   * Healthcare Association of Hawaii -- the state hospital association.
#     §10.2's hospital-association row: NONPROFIT_CBO, PASS_THROUGH_DESIGNATED,
#     Yes, POOL_UNNAMED_HOSPITALS, intermediary HAH, at $0. The page's own
#     words are the basis: "readiness funding, and transformation support
#     primarily for rural hospitals and, where applicable, associated care
#     delivery organizations ... and administration of approved Rural
#     Value-Based Innovation funding". LOW: "primarily" is not "only", and the
#     page names no hospital.
#   * Physicians of Southwest Washington, LLC -- not a hospital: a physician-
#     led independent practice association and management services company
#     (Vancouver, Washington), by general knowledge. OTHER, NON_HOSPITAL, No.
#   * Hawaii Primary Care Association -- the FQHC association; its award is
#     for FQHCs. NONPROFIT_CBO, NON_HOSPITAL, No. Included so the file carries
#     all three Notices the page lists; it moves no hospital figure.
#
# validation_source_type is OTHER: the source is SHPDA's programme page
# STATING that Notices of Award issued, not the Notices themselves.
#
# Usage:
#   Rscript R/03cd_hi_year1_awardees.R --validate | --build | --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
  library(purrr); library(here); library(xml2); library(rvest)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))
source(here::here("R", "utils_page_watch.R"))

HI_STATE    <- "HI"
HI_PAGE     <- file.path("data", "evidence", "recheck", "2026-10-14", "HI",
                         "hi_shpda_rhtp_programme_three_notices_of_award.html")
HI_PAGE_SHA <- "6c3381990e8cf8c253aa40ff8a99cf258538ba796270c8f1f741079a3c796ad1"
HI_PAGE_URL <- "https://health.hawaii.gov/shpda/rural-health-transformation-program/"
HI_CSV      <- here::here("data", "reference", "hi_year1_awardees.csv")
HI_NOA_DATE <- as.Date("2025-12-29")
HI_RVBI     <- "Rural Value Based Innovation (RVBI)"

HI_NOTICES <- tibble::tribble(
  ~awardee,                                   ~date,        ~project,
  "Hawaii Primary Care Association",          "2026-08-28", "Statewide Federally Qualified Health Center (“FQHC”) Infrastructure, Analytics, Readiness Funding, and Transformation Support",
  "Healthcare Association of Hawaii",         "2026-09-03", "Statewide Hospital Infrastructure, Analytics, Readiness Funding, and Transformation Support",
  "Physicians of Southwest Washington, LLC",  "2026-09-11", "Clinically Integrated Network and Managed Services Organization Support"
)
HI_NOA_PHRASE <- c(
  "Hawaii Primary Care Association"         = "(Notice of Award on 8/28 to Hawaii Primary Care Association)",
  "Healthcare Association of Hawaii"        = "(Notice of Award on 9/3 to Healthcare Association of Hawaii)",
  "Physicians of Southwest Washington, LLC" = "(Notice of Award on 9/11 to Physicians of Southwest Washington, LLC)")
HI_HAH_QUOTE <- paste(
  "Provide infrastructure, analytics, readiness funding, and transformation",
  "support primarily for rural hospitals and, where applicable, associated",
  "care delivery organizations.")
HI_HAH_ADMIN <- "administration of approved Rural Value-Based Innovation funding"
HI_HANDS_LINK <- "Link to Hawaii Awards & Notices Data System"

hi_text <- function() {
  # The archive is script-stripped (session 100); reduce it the probes' way.
  t <- rhtp_watch_reduce(here::here(HI_PAGE))
  gsub("ʻ", "'", t)
}

hi_assert_sources <- function() {
  if (!identical(digest::digest(file = here::here(HI_PAGE), algo = "sha256"),
                 HI_PAGE_SHA)) {
    stop("[HI] the archived SHPDA page is not the 2026-10-14 copy.", call. = FALSE)
  }
  t <- hi_text()
  for (s in c(HI_NOA_PHRASE, HI_HAH_QUOTE, HI_HAH_ADMIN, HI_HANDS_LINK,
              "RVBI- $25 million", HI_NOTICES$project)) {
    if (!grepl(s, t, fixed = TRUE)) {
      stop("[HI] SHPDA's page no longer says: '", s, "'.", call. = FALSE)
    }
  }
  # Exactly three Notices of Award, and no award amount anywhere on the page.
  n <- lengths(regmatches(t, gregexpr("Notice of Award on", t, fixed = TRUE)))
  if (n != 3L) stop("[HI] the page lists ", n, " Notices of Award, not 3.",
                    call. = FALSE)
  money <- unique(stringr::str_extract_all(t, "\\$[0-9][0-9,.]*( (M|m)illion)?")[[1]])
  if (!setequal(money, c("$189 Million", "$45 million", "$25 million"))) {
    stop("[HI] the page's currency figures changed: ",
         paste(money, collapse = "; "), ". An award may now be priced.",
         call. = FALSE)
  }
  if (!all(as.Date(HI_NOTICES$date) > HI_NOA_DATE)) stop("[HI] date test.")
  invisible(TRUE)
}

hi_row <- function(i) {
  n <- HI_NOTICES[i, ]
  cls <- rhtp_classify_recipient_type(n$awardee, HI_STATE)
  base <- tibble::tibble(
    state = HI_STATE, row_no = i, awardee = n$awardee, amount = NA_real_,
    note = paste0("RVBI Notice of Award issued ", n$date, " (SHPDA's RHTP page): '",
                  n$project, "'. No amount on the page; amounts are in HANDS, ",
                  "403 to this environment (UNKNOWN, §0.4)."),
    recipient_confirmed = "Yes", amount_confirmed = "No",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = "SHPDA -- Rural Health Transformation Program",
    state_source_url = HI_PAGE_URL,
    validation_source_type = "OTHER",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03cd_hi_year1_awardees.R",
    ccn = NA_character_, aha_id = NA_character_,
    rural_designation = NA_character_, reviewer = NA_character_,
    award_pool = HI_RVBI, award_date = n$date,
    amount_basis = paste0(
      "NOT PUBLISHED on SHPDA's page, which links the award to the Hawaii ",
      "Awards & Notices Data System (HANDS); HANDS answers HTTP 403 to this ",
      "environment, so the amount is UNKNOWN, not $0 (§0.4). RVBI's '$25 ",
      "million' is the initiative's Tier 2 line, never divided (§6.2)."),
    source_archive_path = HI_PAGE)
  if (n$awardee == "Healthcare Association of Hawaii") {
    return(base %>% dplyr::mutate(
      recipient_type = "NONPROFIT_CBO", distributed_to_hospital = "Yes",
      recipient_type_source = paste0(
        "TYPED (session 101): the state hospital association, by general ",
        "knowledge; SHPDA states no form. Classifier said ", cls$recipient_type,
        "/", cls$determination_confidence, "."),
      determination_confidence = "LOW",
      flag_reason = "AMOUNT_MISSING",
      flow_type = "PASS_THROUGH_DESIGNATED", hospital_benefiting = "Yes",
      hospital_attribution = "POOL_UNNAMED_HOSPITALS",
      intermediary_name = "Healthcare Association of Hawaii",
      determination_basis = paste0(
        "OWNER INSTRUCTION (session 101): §10.2's hospital-association row. ",
        "SHPDA's page: '", HI_HAH_QUOTE, "' and services include '", HI_HAH_ADMIN,
        "'. That is readiness FUNDING for hospitals administered by the ",
        "association, the money-moving shape (ICAHN, OHA), not services kept ",
        "and delivered (GHA's carts). LOW: 'primarily' is not 'only' -- ",
        "'associated care delivery organizations' may share it -- and no ",
        "hospital is named, so POOL_UNNAMED_HOSPITALS, at $0 until HANDS is ",
        "readable."),
      basis_type = "GENERAL_KNOWLEDGE"))
  }
  if (n$awardee == "Physicians of Southwest Washington, LLC") {
    return(base %>% dplyr::mutate(
      recipient_type = "OTHER", distributed_to_hospital = "No",
      recipient_type_source = paste0(
        "TYPED (session 101): Determined form: a physician-led independent ",
        "practice association and management services company (Vancouver, ",
        "Washington), by general knowledge; SHPDA states no form. Classifier ",
        "said ", cls$recipient_type, "/", cls$determination_confidence, "."),
      determination_confidence = "LOW",
      flag_reason = "AMOUNT_MISSING",
      flow_type = "NON_HOSPITAL", hospital_benefiting = "Unclear",
      hospital_attribution = "NOT_HOSPITAL", intermediary_name = NA_character_,
      determination_basis = paste0(
        "§10.2 NON_HOSPITAL on the RECIPIENT (§0.3a), by owner instruction ",
        "(session 101). Determined form: a physician-led independent practice ",
        "association / MSO, not a hospital and not a hospital's arm; the award ",
        "builds a CIN/MSO for 'independent and community-based primary care ",
        "providers'. An out-of-state organisation funded by Hawaii; the row ",
        "stays in Hawaii's file."),
      basis_type = "GENERAL_KNOWLEDGE"))
  }
  base %>% dplyr::mutate(
    recipient_type = "NONPROFIT_CBO", distributed_to_hospital = "No",
    recipient_type_source = paste0(
      "TYPED (session 101): the Hawaii Primary Care Association, the FQHCs' ",
      "membership association, by general knowledge; SHPDA states no form. ",
      "Classifier said ", cls$recipient_type, "/", cls$determination_confidence, "."),
    determination_confidence = "LOW",
    flag_reason = "AMOUNT_MISSING",
    flow_type = "NON_HOSPITAL", hospital_benefiting = "No",
    hospital_attribution = "NOT_HOSPITAL", intermediary_name = NA_character_,
    determination_basis = paste0(
      "§10.2 NON_HOSPITAL: an association of FQHCs whose award is 'Statewide ",
      "FQHC Infrastructure, Analytics, Readiness Funding, and Transformation ",
      "Support' -- money for FQHCs, not hospitals. RCJ prices it at ",
      "$17,000,000; that figure is unverified (HANDS is 403) and is not used."),
    basis_type = "GENERAL_KNOWLEDGE")
}

hi_year1_awardees <- function() {
  purrr::map_dfr(seq_len(nrow(HI_NOTICES)), hi_row) %>%
    dplyr::select(
      state, row_no, awardee, amount, recipient_type, distributed_to_hospital,
      note, recipient_confirmed, amount_confirmed, fiscal_year,
      source_document_title, state_source_url, validation_source_type,
      extraction_method, validator, ccn, aha_id, rural_designation, reviewer,
      recipient_type_source, determination_confidence, flag_reason, award_pool,
      award_date, flow_type, hospital_benefiting, hospital_attribution,
      intermediary_name, determination_basis, amount_basis, basis_type,
      source_archive_path)
}

hi_validate <- function() {
  hi_assert_sources()
  d <- hi_year1_awardees()
  vocab <- function(col, key = col) {
    bad <- setdiff(stats::na.omit(unique(d[[col]])), rhtp_vocabulary(key))
    if (length(bad)) stop("[HI] ", col, " outside §8: ", paste(bad, collapse = ", "),
                          call. = FALSE)
  }
  for (c in c("recipient_type", "distributed_to_hospital", "flow_type",
              "hospital_attribution", "determination_confidence")) vocab(c)
  vocab("validation_source_type", "source_doc_type")
  stopifnot(nrow(d) == 3L, all(is.na(d$amount)))
  p <- rhtp_hospital_dollar_partition(d)
  stopifnot(identical(p$bucket, "POOL_UNNAMED_HOSPITALS"), p$rows == 1L,
            p$dollars == 0)
  message("[HI] all assertions pass.")
  invisible(d)
}

hi_build <- function() {
  d <- hi_validate()
  readr::write_csv(d, HI_CSV, na = "")
  message("[HI] wrote ", nrow(d), " rows to ", HI_CSV)
  invisible(d)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) hi_validate()
  if ("--build" %in% args) hi_build()
  if ("--report" %in% args) print(as.data.frame(hi_year1_awardees()[
    , c("awardee", "award_date", "recipient_type", "hospital_attribution")]))
  if (!length(args)) message("Usage: --validate | --build | --report")
}
