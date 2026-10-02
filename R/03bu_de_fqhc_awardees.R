#!/usr/bin/env Rscript
# 03bu_de_fqhc_awardees.R ------------------------------------------------------
#
# DELAWARE'S SECOND AWARD RELEASE: THREE FQHCs, ~$22.69M, NO HOSPITAL. Session 86.
#
# The NEWSROOM sweep tripped on news.delaware.gov's 2026-09-24 release
# "Governor Meyer Awards Nearly $23 Million to FQHCs Through Rural Health
# Transformation Program". Session 85 read and archived it
# (data/evidence/DE/2026-10-02_de_fqhc_award_release.html) and held it over
# the owner's $10M report-first line. The owner approved it in session 86.
#
#   "Westside Family Healthcare will receive $11.3 million, La Red Health
#    Center will receive $10.1 million and Henrietta Johnson Medical Center
#    will receive $1.29 million."
#
# ALL THREE AMOUNTS ARE ROUNDED IN THE SOURCE (AMOUNT_ROUNDED_IN_SOURCE,
# Alabama's code): the release prints millions to one or two decimals and its
# own headline says "nearly $23 million". Nothing here un-rounds them.
#
# RHTP: the release says so ("Rural Health Transformation Program funding")
# and carries the CMS footer, whose figure, $157,394,963.86, is Delaware's
# ALLOTMENT (Tier 1, §0.2) -- asserted, and never placed in `amount`.
#
# FORM: STATED BY THE STATE. "Delaware's three Federally Qualified Health
# Centers (FQHCs)" -- FQHC_OR_RHC, basis STATE_SOURCE, MEDIUM. CMS's DE FQHC
# Enrollments (federal_records/2026-10-02) agree for all three, and none of
# the three is on the DE Hospital Enrollments file (2026-09-25). Henrietta
# Johnson enrols as SOUTHBRIDGE MEDICAL ADVISORY COUNCIL INC dba HENRIETTA
# JOHNSON MEDICAL CENTER -- recorded, not used to re-type (§10.2 precedence:
# the state's stated form stands).
#
# NO HOSPITAL ROW. Delaware's hospital contribution is unchanged by this file.
#
# THE INITIATIVE IS NOT NAMED IN THE RELEASE. Session 85 noted the sum sits
# under DHSS's "Value-based care transformation" Year 1 budget
# ($24,322,042.48, "rural health care providers and FQHCs"); the release
# speaks of "value-based care" in the Secretary's quote but never names the
# line, so `award_pool` names the release and the budget line is a note only
# (§0.3: a budget line is not an award, and is never subtracted from).
#
# A SEPARATE FILE, NOT ROWS IN de_year1_awardees.csv, whose R/03al asserts
# exactly four school-based health centre awards from the July release (NC
# SBHC's and Alabama round 2's precedent: a later roster gets its own file).
#
# Usage:
#   Rscript R/03bu_de_fqhc_awardees.R --validate | --build | --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})

source(here::here("R", "utils_config.R"))

DEF_STATE     <- "DE"
DEF_URL       <- paste0("https://news.delaware.gov/2026/09/24/governor-meyer-awards-",
                        "nearly-23-million-to-fqhcs-through-rural-health-transformation-program/")
DEF_ARCHIVE   <- file.path("data", "evidence", "DE", "2026-10-02_de_fqhc_award_release.html")
DEF_SHA256    <- "a0d111e463ad71300d23ab83b870569866ddc17b22c285feae9feef9672b220d"
DEF_ANNOUNCED <- as.Date("2026-09-24")
DEF_NOA_DATE  <- as.Date("2025-12-29")
DEF_FOOTER    <- 157394963.86
DEF_CSV       <- here::here("data", "reference", "de_year1_fqhc_awardees.csv")
DEF_FQHC_FED  <- file.path("data", "evidence", "federal_records", "2026-10-02",
                           "cms_fqhc_enrollments_DE.json")
DEF_HOSP_FED  <- file.path("data", "evidence", "federal_records", "2026-09-25",
                           "cms_hosp_enrollments_DE.json")
DEF_POOL      <- "FQHC awards, Governor's release of 2026-09-24"

# In the order the release's "will support the following work" list prints
# them, with the sentence that prices each and the CMS FQHC record.
DEF_AWARDS <- tibble::tribble(
  ~awardee,                          ~amount,  ~heading,                                      ~cms_org,                                   ~cms_dba,
  "La Red Health Center",            10100000, "La Red Health Center - $10.1 million",        "LA RED HEALTH CENTER INC",                 "",
  "Westside Family Healthcare",      11300000, "Westside Family Healthcare - $11.3 million",  "WESTSIDE FAMILY HEALTHCARE, INC.",         "",
  "Henrietta Johnson Medical Center", 1290000, "Henrietta Johnson Medical Center - $1.29 million", "SOUTHBRIDGE MEDICAL ADVISORY COUNCIL INC", "HENRIETTA JOHNSON MEDICAL CENTER"
)

def_text <- function() {
  raw <- readr::read_file_raw(here::here(DEF_ARCHIVE))
  if (digest::digest(raw, algo = "sha256", serialize = FALSE) != DEF_SHA256) {
    stop("[DE FQHC] the archive's SHA-256 does not match data/evidence/DE/MANIFEST.txt.",
         call. = FALSE)
  }
  t <- rvest::html_text2(xml2::read_html(raw))
  t <- gsub("[‐-―−]", "-", t)
  t <- gsub("’", "'", t, fixed = TRUE)
  t <- stringr::str_squish(t)
  # The ARTICLE, not the page: the sidebar is a rolling site-wide news feed.
  from <- regexpr("GEORGETOWN - Governor Matt Meyer", t, fixed = TRUE)
  to <- regexpr("nor an endorsement, by CMS/HHS", t, fixed = TRUE)
  if (from < 0 || to < 0) {
    stop("[DE FQHC] the article's dateline or CMS footer is gone.", call. = FALSE)
  }
  substr(t, from, to + attr(to, "match.length") - 1L)
}

def_assert_source <- function(t = def_text()) {
  need <- c(
    "announced nearly $23 million in Rural Health Transformation Program funding for Delaware's three Federally Qualified Health Centers (FQHCs)",
    "Westside Family Healthcare will receive $11.3 million, La Red Health Center will receive $10.1 million and Henrietta Johnson Medical Center will receive $1.29 million.",
    DEF_AWARDS$heading,
    "as part of a financial assistance award totaling $157,394,963.86 with 100 percent funded by CMS/HHS")
  miss <- need[!vapply(need, function(s) grepl(s, t, fixed = TRUE), logical(1))]
  if (length(miss)) {
    stop("[DE FQHC] the release no longer says: ", paste(sQuote(miss), collapse = "; "),
         call. = FALSE)
  }
  # §0.2: the one footer figure is the ALLOTMENT, and nothing priced equals it.
  rhtp_assert_footer_not_allotment(DEF_FOOTER, DEF_STATE, "STATE_ALLOTMENT",
                                   label = "the 2026-09-24 FQHC release footer")
  if (any(abs(DEF_AWARDS$amount - DEF_FOOTER) < RHTP_FOOTER_ALLOTMENT_MARGIN)) {
    stop("[DE FQHC] an award equals the allotment.", call. = FALSE)
  }
  # "nearly $23 million": the three rounded figures stay under it.
  if (!(sum(DEF_AWARDS$amount) < 23e6 && sum(DEF_AWARDS$amount) > 22e6)) {
    stop("[DE FQHC] the three figures no longer read as 'nearly $23 million'.",
         call. = FALSE)
  }
  # Exactly three dollar figures in millions besides the headline and the
  # "$157.4 million" federal-funding sentence: no fourth award is hiding.
  m <- unique(stringr::str_extract_all(t, "\\$[0-9.]+ million")[[1]])
  if (!setequal(m, c("$23 million", "$11.3 million", "$10.1 million",
                     "$1.29 million", "$157.4 million"))) {
    stop("[DE FQHC] the release's million-dollar figures changed: ",
         paste(m, collapse = ", "), call. = FALSE)
  }
  if (!(DEF_ANNOUNCED > DEF_NOA_DATE)) stop("[DE FQHC] §6.2 date test.", call. = FALSE)
  invisible(TRUE)
}

def_assert_federal <- function() {
  f <- jsonlite::fromJSON(here::here(DEF_FQHC_FED))
  for (i in seq_len(nrow(DEF_AWARDS))) {
    ok <- f[["ORGANIZATION NAME"]] == DEF_AWARDS$cms_org[i] &
      (!nzchar(DEF_AWARDS$cms_dba[i]) | f[["DOING BUSINESS AS NAME"]] == DEF_AWARDS$cms_dba[i])
    if (!any(ok)) {
      stop("[DE FQHC] the archived DE FQHC file no longer carries ",
           DEF_AWARDS$cms_org[i], ".", call. = FALSE)
    }
  }
  h <- jsonlite::fromJSON(here::here(DEF_HOSP_FED))
  hit <- grepl("WESTSIDE|LA RED|HENRIETTA|SOUTHBRIDGE",
               paste(h[["ORGANIZATION NAME"]], h[["DOING BUSINESS AS NAME"]]))
  if (any(hit)) {
    stop("[DE FQHC] an FQHC awardee now appears on the DE hospital enrolment ",
         "file -- read it before trusting this file's NO-HOSPITAL finding.", call. = FALSE)
  }
  invisible(TRUE)
}

def_rows <- function() {
  a <- DEF_AWARDS
  why <- paste0(
    "The state states the form: Governor Meyer and DHSS announced the funding 'for ",
    "Delaware's three Federally Qualified Health Centers (FQHCs)', naming this ",
    "recipient. CMS DE FQHC Enrollments agree (", a$cms_org,
    ifelse(nzchar(a$cms_dba), paste0(" dba ", a$cms_dba), ""), "); no DE hospital ",
    "enrolment. §10.2 NON_HOSPITAL on the recipient, not the activity (§0.3a).")
  tibble::tibble(
    state = DEF_STATE,
    row_no = seq_len(nrow(a)),
    awardee = a$awardee,
    amount = a$amount,
    recipient_type = "FQHC_OR_RHC",
    distributed_to_hospital = "No",
    note = paste0("Governor's release of ", DEF_ANNOUNCED, ": '", a$heading,
                  "'. ROUNDED in the source. The release names no initiative; the sum ",
                  "sits under DHSS's 'Value-based care transformation' Year 1 budget ",
                  "line ($24,322,042.48) -- a budget, never subtracted from (§0.3)."),
    recipient_confirmed = "Yes",
    amount_confirmed = "Yes",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = "Governor Meyer Awards Nearly $23 Million to FQHCs Through Rural Health Transformation Program",
    state_source_url = DEF_URL,
    validation_source_type = "GOVERNOR_PRESS_RELEASE",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03bu_de_fqhc_awardees.R",
    ccn = NA_character_,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    recipient_type_source = paste0("TYPED (session 86, HAND-READ): ", why),
    determination_confidence = "MEDIUM",
    flag_reason = "AMOUNT_ROUNDED_IN_SOURCE",
    award_pool = DEF_POOL,
    budget_period = "Budget Period 1",
    flow_type = "NON_HOSPITAL",
    hospital_benefiting = "No",
    hospital_attribution = "NOT_HOSPITAL",
    intermediary_name = NA_character_,
    determination_basis = paste0("§10.2 NON_HOSPITAL: ", why),
    amount_basis = paste0("ROUNDED as published ('", sub("^.* - ", "", a$heading),
                          "'); never un-rounded."),
    round_name = DEF_POOL,
    round_awards = nrow(a),
    round_amount = NA_real_,
    announcement_date = DEF_ANNOUNCED,
    source_archive_path = DEF_ARCHIVE,
    basis_type = "STATE_SOURCE",
    recipient_subtype = NA_character_,
    cms_enrolment_match = NA_character_,
    cms_enrolment_record = paste0("CMS FQHC Enrollments: ", a$cms_org,
                                  ifelse(nzchar(a$cms_dba), paste0(" dba ", a$cms_dba), ""),
                                  " (", DEF_FQHC_FED, ")"))
}

def_assert_rows <- function(d) {
  if (nrow(d) != 3L || sum(d$amount) != 22690000) {
    stop("[DE FQHC] three rows, $22,690,000 (rounded).", call. = FALSE)
  }
  if (any(d$distributed_to_hospital != "No")) {
    stop("[DE FQHC] no row of this file reaches a hospital.", call. = FALSE)
  }
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "determination_confidence", "hospital_attribution", "basis_type",
                "flag_reason", "hospital_benefiting")) {
    bad <- setdiff(stats::na.omit(unique(d[[col]])), rhtp_vocabulary(col))
    if (length(bad)) stop("[DE FQHC] ", col, " outside §8: ",
                          paste(bad, collapse = ", "), call. = FALSE)
  }
  if (!all(d$validation_source_type %in% rhtp_vocabulary("source_doc_type"))) {
    stop("[DE FQHC] validation_source_type outside §8's source_doc_type.", call. = FALSE)
  }
  invisible(TRUE)
}

def_validate <- function() {
  def_assert_source()
  def_assert_federal()
  d <- def_rows()
  def_assert_rows(d)
  message("[DE FQHC] all assertions pass: 3 FQHCs, $22,690,000 (rounded), no hospital.")
  invisible(d)
}

def_build <- function() {
  d <- def_validate()
  readr::write_csv(d, DEF_CSV, na = "")
  message("[DE FQHC] wrote ", nrow(d), " rows to ", DEF_CSV, ".")
  invisible(d)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) def_validate()
  if ("--build" %in% args) def_build()
  if ("--report" %in% args) print(as.data.frame(def_rows()[, c("awardee", "amount", "recipient_type")]))
  if (!length(args)) message("Usage: --validate | --build | --report")
}
