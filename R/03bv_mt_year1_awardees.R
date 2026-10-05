#!/usr/bin/env Rscript
# 03bv_mt_year1_awardees.R ------------------------------------------------------
#
# MONTANA'S FIRST AWARD: THE EMS EQUIPMENT GRANT, $8.7M, 2026-09-29. Session 88.
#
# Montana was a watch (R/03bl, session 75) on a dated anchor: "funding
# decisions will be shared in September". DPHHS's Grants page now reads
# "Date Awarded: Sept. 29, 2026 · Amount: $8.7 million · The funds will
# support 78 EMS agencies", and the Governor/DPHHS release of that day
# (data/evidence/MT/2026-10-05_mt_dphhs_rural_ems_award_release.html) says:
#
#   "Four agencies were awarded ambulances at a cost of approximately
#    $340,000 each, including: Absarokee Rural Fire District, located in
#    Stillwater County; Avon Volunteer Fire and EMS, in southern Powell
#    County; Blackfeet Tribal Emergency Medical Services; and Prairie County
#    Ambulance Service."
#
#   "In addition to ambulance grants, 75 agencies, including three tribal
#    governments, have been awarded funding for 238 pieces of equipment ...
#    Awards range from $3,200 to $308,637 based on need and equipment type."
#
# WHAT THIS FILE HOLDS, AND WHAT IT REFUSES TO:
#   * FOUR NAMED ROWS at $340,000 each, AMOUNT_ROUNDED_IN_SOURCE (Alabama's
#     code). "Approximately $340,000 each" is the release's own rounding of a
#     per-ambulance COST; the four are never un-rounded and never summed into
#     a claim about the round.
#   * ONE POOL ROW for the 75 equipment awards: NOT_YET_NAMED, `amount` EMPTY.
#     DPHHS publishes no name, no per-award figure and NO SUBTOTAL for the 75
#     -- only the round's $8.7M, which covers the ambulances too, and a range.
#     $8.7M minus 4 x $340,000 would publish a figure the state has not, on
#     two rounded inputs (§6.2: a pool is never divided, and here it is not
#     even stated), so `round_amount` carries the $8.7M on every row and is
#     never summed down the column (§10).
#   * THE COUNT DOES NOT CLOSE AND THAT IS RECORDED, NOT RESOLVED. The release
#     and the Grants page say 78 agencies; 4 + 75 is 79 (CMS's own 09-29
#     release says 79). One ambulance agency may also hold an equipment award.
#     Nothing here guesses which.
#
# FORM: STATED BY THE STATE -- "EMS agencies" -- so EMS_OR_PSAP, basis
# STATE_SOURCE, MEDIUM. Blackfeet Tribal Emergency Medical Services is a tribal
# government's EMS service; the release counts it among the EMS agencies and
# the session-72 precedence rule keeps the state's stated form. EMS_OR_PSAP and
# TRIBAL_ORG are both non-hospital, so the choice moves no dollar.
#
# NO HOSPITAL ROW, AND ONE QUESTION QUEUED. CMS's MT Hospital Enrollments
# (federal_records/2026-10-05) carry PRAIRIE COUNTY HOSPITAL DISTRICT (Terry,
# CAH, CCN 271309). "Prairie County Ambulance Service" does not name that legal
# entity, and a name that merely shares a county is never matched by machine
# (§10.2, "a different legal body with a similar name"). It stays EMS_OR_PSAP
# and MT_PRAIRIE_COUNTY_AMBULANCE_OPERATOR is queued for a human ($340,000,
# rounded). None of the other three appears on the enrolment file.
#
# RHTP: the release carries the CMS footer, whose figure $233,509,358.76 is
# Montana's ALLOTMENT (Tier 1, §0.2) -- asserted, never placed in `amount`.
# §6.2 date test: announced 2026-09-29, after the 2025-12-29 NOA.
#
# Usage:
#   Rscript R/03bv_mt_year1_awardees.R --validate | --build | --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))

MT_STATE      <- "MT"
MT_URL        <- "https://dphhs.mt.gov/News/2026/September/Investment-in-Rural-EMS"
MT_ARCHIVE    <- file.path("data", "evidence", "MT",
                           "2026-10-05_mt_dphhs_rural_ems_award_release.html")
MT_SHA256     <- "c120cd8bcc39908a72d50d5e9a90645391ecf1270a6a6ec096e73eb7dadc7719"
MT_GRANTS     <- file.path("data", "evidence", "MT", "2026-10-05_mt_rhtp_grants.html")
MT_ANNOUNCED  <- as.Date("2026-09-29")
MT_NOA_DATE   <- as.Date("2025-12-29")
MT_FOOTER     <- 233509358.76
MT_ROUND      <- 8700000
MT_AMBULANCE  <- 340000
MT_POOL_N     <- 75L
MT_CSV        <- here::here("data", "reference", "mt_year1_awardees.csv")
MT_HOSP_FED   <- file.path("data", "evidence", "federal_records", "2026-10-05",
                           "cms_hosp_enrollments_MT.json")
MT_ROUND_NAME <- "EMS Equipment Grant (ambulance and equipment awards), awarded 2026-09-29"

MT_AMBULANCE_AWARDS <- tibble::tribble(
  ~awardee,                                        ~where,
  "Absarokee Rural Fire District",                 "located in Stillwater County",
  "Avon Volunteer Fire and EMS",                   "in southern Powell County",
  "Blackfeet Tribal Emergency Medical Services",   NA_character_,
  "Prairie County Ambulance Service",              NA_character_
)

MT_SENTENCES <- c(
  ambulances = paste(
    "Four agencies were awarded ambulances at a cost of approximately $340,000",
    "each, including: Absarokee Rural Fire District, located in Stillwater",
    "County; Avon Volunteer Fire and EMS, in southern Powell County; Blackfeet",
    "Tribal Emergency Medical Services; and Prairie County Ambulance Service."),
  equipment = paste(
    "In addition to ambulance grants, 75 agencies, including three tribal",
    "governments, have been awarded funding for 238 pieces of equipment"),
  range = "Awards range from $3,200 to $308,637 based on need and equipment type.",
  round = "today announced an $8.7 million investment to help strengthen emergency medical services (EMS) across rural Montana.",
  count = "The funds will support 78 EMS agencies serving rural and frontier areas to purchase needed equipment and four new ambulances.",
  footer = "as part of a financial assistance award totaling $233,509,358.76 with 100 percent funded by CMS/HHS")

mt_text <- function() {
  raw <- readr::read_file_raw(here::here(MT_ARCHIVE))
  if (digest::digest(raw, algo = "sha256", serialize = FALSE) != MT_SHA256) {
    stop("[MT] the release archive's SHA-256 does not match data/evidence/MT/MANIFEST.txt.",
         call. = FALSE)
  }
  t <- rhtp_watch_reduce(here::here(MT_ARCHIVE))
  t <- gsub("[‘’]", "'", t)
  t <- gsub("[‐-―−]", "-", t)
  stringr::str_squish(t)
}

mt_assert_source <- function(t = mt_text()) {
  miss <- MT_SENTENCES[!vapply(MT_SENTENCES, function(s) grepl(s, t, fixed = TRUE),
                               logical(1))]
  if (length(miss)) {
    stop("[MT] the release no longer says: ", paste(sQuote(miss), collapse = "; "),
         call. = FALSE)
  }
  g <- rhtp_watch_reduce(here::here(MT_GRANTS))
  for (k in c("Date Awarded: Sept. 29, 2026", "Amount: $8.7 million",
              "The funds will support 78 EMS agencies.")) {
    if (!grepl(k, g, fixed = TRUE)) {
      stop("[MT] the Grants page no longer says '", k, "'.", call. = FALSE)
    }
  }
  # §0.2: the one footer figure is the ALLOTMENT.
  rhtp_assert_footer_not_allotment(MT_FOOTER, MT_STATE, "STATE_ALLOTMENT",
                                   label = "the 2026-09-29 EMS release footer")
  # The release prices nothing per equipment award: exactly these figures.
  m <- unique(tolower(stringr::str_extract_all(
    t, stringr::regex("\\$[0-9][0-9,.]*( million)?", ignore_case = TRUE))[[1]]))
  if (!setequal(m, c("$8.7 million", "$340,000", "$3,200", "$308,637",
                     "$233,509,358.76"))) {
    stop("[MT] the release's dollar figures changed: ", paste(m, collapse = ", "),
         ". A new figure may price an award -- read it.", call. = FALSE)
  }
  if (!(MT_ANNOUNCED > MT_NOA_DATE)) stop("[MT] §6.2 date test.", call. = FALSE)
  invisible(TRUE)
}

mt_assert_federal <- function() {
  h <- jsonlite::fromJSON(here::here(MT_HOSP_FED))
  s <- toupper(paste(h[["ORGANIZATION NAME"]], h[["DOING BUSINESS AS NAME"]]))
  if (any(grepl("ABSAROKEE|AVON VOLUNTEER|BLACKFEET TRIBAL|AMBULANCE SERVICE", s))) {
    stop("[MT] an ambulance awardee now appears on the MT hospital enrolment ",
         "file -- read it before trusting this file's NO-HOSPITAL finding.",
         call. = FALSE)
  }
  if (!any(grepl("PRAIRIE COUNTY HOSPITAL DISTRICT", s))) {
    stop("[MT] Prairie County Hospital District is no longer on the archived ",
         "enrolment file; the queued question cites it.", call. = FALSE)
  }
  invisible(TRUE)
}

mt_rows <- function() {
  a <- MT_AMBULANCE_AWARDS
  why <- paste0(
    "The state states the form: the Governor/DPHHS release of 2026-09-29 says ",
    "'Four agencies were awarded ambulances' and that the funds 'will support ",
    "78 EMS agencies', naming this recipient among the four. Not on CMS's MT ",
    "Hospital Enrollments. §10.2 NON_HOSPITAL on the recipient (§0.3a).")
  why <- ifelse(a$awardee == "Blackfeet Tribal Emergency Medical Services",
                paste(why, "A tribal government's EMS service; the release counts",
                      "it as an EMS agency and the state's stated form stands",
                      "(§10.2 precedence). TRIBAL_ORG would equally be non-hospital."),
                why)
  why <- ifelse(a$awardee == "Prairie County Ambulance Service",
                paste(why, "QUEUED (MT_PRAIRIE_COUNTY_AMBULANCE_OPERATOR): CMS",
                      "enrols PRAIRIE COUNTY HOSPITAL DISTRICT (Terry, CAH, CCN",
                      "271309); the awardee string does not name that legal",
                      "entity and is not matched by machine (§10.2)."),
                why)
  named <- tibble::tibble(
    state = MT_STATE,
    row_no = seq_len(nrow(a)),
    awardee = a$awardee,
    amount = MT_AMBULANCE,
    recipient_type = "EMS_OR_PSAP",
    distributed_to_hospital = "No",
    note = paste0("Ambulance grant, EMS Equipment Grant round of 2026-09-29",
                  ifelse(is.na(a$where), "", paste0(" (", a$where, ")")),
                  ". 'Awarded ambulances at a cost of approximately $340,000 each': ",
                  "ROUNDED in the source, and a per-ambulance cost the state gives ",
                  "as the award; never un-rounded."),
    recipient_confirmed = "Yes",
    amount_confirmed = "No",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = "Gov. Gianforte, DPHHS announce $8.7 million investment in rural EMS",
    state_source_url = MT_URL,
    validation_source_type = "GOVERNOR_PRESS_RELEASE",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03bv_mt_year1_awardees.R",
    ccn = NA_character_,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    recipient_type_source = paste0("TYPED (session 88, HAND-READ): ", why),
    determination_confidence = "MEDIUM",
    flag_reason = "AMOUNT_ROUNDED_IN_SOURCE",
    award_pool = "Ambulance grants",
    budget_period = "Budget Period 1",
    flow_type = "NON_HOSPITAL",
    hospital_benefiting = "No",
    hospital_attribution = "NOT_HOSPITAL",
    intermediary_name = NA_character_,
    determination_basis = paste0("§10.2 NON_HOSPITAL: ", why),
    amount_basis = "ROUNDED as published ('approximately $340,000 each'); never un-rounded.",
    n_recipients = 1L,
    round_name = MT_ROUND_NAME,
    round_awards = "78 agencies (state); 4 ambulance + 75 equipment = 79 (CMS)",
    round_amount = MT_ROUND,
    announcement_date = MT_ANNOUNCED,
    source_archive_path = MT_ARCHIVE,
    basis_type = "STATE_SOURCE",
    recipient_subtype = NA_character_,
    cms_enrolment_match = NA_character_,
    cms_enrolment_record = paste0("Not on CMS MT Hospital Enrollments (", MT_HOSP_FED, ")"))

  pool_why <- paste(
    "AGGREGATE ROW, NOT A RECIPIENT. DPHHS says 75 agencies, 'including three",
    "tribal governments', were awarded equipment funding (238 pieces;",
    "'Awards range from $3,200 to $308,637') and names none of them. The class",
    "is EMS agencies; a hospital-operated EMS service could be among them, so",
    "nothing can be said about hospital receipt (§0.3) and the row enters no",
    "hospital bucket. `amount` is EMPTY: DPHHS states no subtotal for the 75,",
    "and $8.7M less the four rounded ambulance figures is not a number the",
    "state has published (§6.2).")
  pool <- named[1, ] %>%
    dplyr::mutate(
      row_no = nrow(a) + 1L,
      awardee = "75 EMS agencies (equipment awards) - recipient names not published",
      amount = NA_real_,
      recipient_type = "NOT_YET_NAMED",
      distributed_to_hospital = "Unclear",
      note = paste("Equipment awards, EMS Equipment Grant round of 2026-09-29.",
                   "75 awards, $3,200 to $308,637 each, unnamed and unpriced;",
                   "held as a pool. The state's 78-agency count and CMS's 79",
                   "(4 + 75) do not close and are not reconciled here."),
      recipient_confirmed = "No",
      amount_confirmed = "No",
      recipient_type_source = "NOT_YET_NAMED: the release names no equipment awardee.",
      determination_confidence = "LOW",
      flag_reason = "RECIPIENT_NAMES_NOT_CAPTURED",
      award_pool = "Equipment awards",
      flow_type = "PASS_THROUGH_UNRESOLVED",
      hospital_benefiting = "No",
      hospital_attribution = "NOT_HOSPITAL",
      determination_basis = pool_why,
      amount_basis = "NOT_PUBLISHED: no subtotal for the 75; range $3,200-$308,637 per award.",
      n_recipients = MT_POOL_N,
      basis_type = NA_character_,
      cms_enrolment_record = NA_character_)
  dplyr::bind_rows(named, pool)
}

mt_assert_rows <- function(d) {
  priced <- d[!is.na(d$amount), ]
  if (nrow(d) != 5L || nrow(priced) != 4L || sum(priced$amount) != 1360000) {
    stop("[MT] five rows: four ambulance grants at $340,000 (rounded) and one ",
         "unpriced pool.", call. = FALSE)
  }
  if (any(d$distributed_to_hospital == "Yes")) {
    stop("[MT] no row of this file reaches a hospital.", call. = FALSE)
  }
  if (any(d$determination_confidence == "HIGH")) {
    stop("[MT] HIGH needs a CCN match (§7).", call. = FALSE)
  }
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "determination_confidence", "hospital_attribution", "basis_type",
                "flag_reason", "hospital_benefiting")) {
    bad <- setdiff(stats::na.omit(unique(d[[col]])), rhtp_vocabulary(col))
    if (length(bad)) stop("[MT] ", col, " outside §8: ",
                          paste(bad, collapse = ", "), call. = FALSE)
  }
  if (!all(d$validation_source_type %in% rhtp_vocabulary("source_doc_type"))) {
    stop("[MT] validation_source_type outside §8's source_doc_type.", call. = FALSE)
  }
  invisible(TRUE)
}

mt_validate <- function() {
  mt_assert_source()
  mt_assert_federal()
  d <- mt_rows()
  mt_assert_rows(d)
  message("[MT] all assertions pass: 4 named ambulance grants ($340,000 each, ",
          "rounded), 1 unnamed pool of 75 equipment awards, no hospital.")
  invisible(d)
}

mt_build <- function() {
  d <- mt_validate()
  readr::write_csv(d, MT_CSV, na = "")
  message("[MT] wrote ", nrow(d), " rows to ", MT_CSV, ".")
  invisible(d)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) mt_validate()
  if ("--build" %in% args) mt_build()
  if ("--report" %in% args) print(as.data.frame(mt_rows()[, c("awardee", "amount", "recipient_type")]))
  if (!length(args)) message("Usage: --validate | --build | --report")
}
