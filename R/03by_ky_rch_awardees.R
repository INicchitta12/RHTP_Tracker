#!/usr/bin/env Rscript
# 03by_ky_rch_awardees.R -----------------------------------------------------
#
# KENTUCKY -- ONE NAMED HUB LEAD, NO AMOUNT, AND A FIVE-YEAR REGIONAL CEILING
# THAT IS NOT AN AWARD.
#
# Rural Community Hubs for Chronic Care Innovation (RCH) is the Kentucky pool
# R/03af has watched since session 37: a Hub Lead RFA, closed 2026-06-01, for
# the Big Sandy, Lake Cumberland and Purchase Area Development Districts. On
# 2026-10-05 Lake Cumberland District Health Department announced it "has been
# selected to lead the Rural Community Hub for the Lake Cumberland region",
# "through a competitive application process", and the Foundation for a
# Healthy Kentucky -- the RCH "convening partner", whose page R/03af watches --
# put that headline under "Program News" on its RCH page the same week.
#
# WHAT IS NAMED, AND BY WHOM. The recipient is named on FHKY's page (the
# headline links LCDHD's release) and in LCDHD's own release. Neither is a
# Kentucky state agency and NEITHER PRINTS AN AWARD AMOUNT, so the row is
# `amount` EMPTY, `amount_confirmed = No` and `validation_source_type = OTHER`
# (a convening partner's programme page plus the recipient's own release;
# session 92 treated recipient self-announcements as leads, and this one is
# carried only because FHKY's page names the selection too).
#
# "UP TO $10 MILLION" IS A CEILING ON A REGION OVER FIVE YEARS, NOT AN AWARD.
# LCDHD's sentence is "Throughout the grant period, the Lake Cumberland region
# will be eligible to receive up to $10 million in federal funding for the
# Rural Community Hubs program to support community health initiatives and Hub
# operations." Three things keep it out of `amount`: it is a maximum ("up
# to"), it attaches to the REGION rather than to the Hub Lead ("the Lake
# Cumberland region will be eligible"), and it spans FY2026-FY2030 rather than
# Budget Period 1. It is recorded as TEXT in `amount_ceiling_text` and in
# `amount_basis`, and deliberately carries no numeric column: a number beside
# a $0 row is the one a reader sums (§0.3, and the reason `round_amount` is
# never summed).
#
# THE RECIPIENT IS A LOCAL HEALTH DEPARTMENT. LCDHD is a Kentucky district
# health department (its own name, and its release's "Somerset, KY" dateline;
# the organisation's own site states the form), so `LOCAL_GOVT_OR_PUBLIC_HEALTH`
# on `basis_type = ORG_WEBSITE`, MEDIUM. Not a hospital: §10.2 NON_HOSPITAL on
# the RECIPIENT (§0.3a). The Hub "will bring together providers, schools,
# employers, faith communities, government agencies, and more" -- hospitals may
# be partners, and partnership is not receipt (§7's New York rule), so
# `hospital_benefiting` is Unclear and moves no figure.
#
# BIG SANDY AND PURCHASE ARE NOT YET NAMED. R/03af's RCH page is re-based on
# the 2026-10-07 copy (which carries this headline), so the next Hub Lead is a
# new organisation string and fires its name tripwire.
#
# Usage:
#   Rscript R/03by_ky_rch_awardees.R --fetch [--force] | --validate | --build | --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
  library(purrr); library(httr); library(digest); library(here)
  library(rvest); library(xml2)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))
source(here::here("R", "utils_page_watch.R"))

KYR_STATE       <- "KY"
KYR_DIR         <- file.path("data", "evidence", "KY", "rch")
KYR_RELEASE_URL <- "https://www.lcdhd.org/lcdhd-selected/"
KYR_RELEASE     <- file.path(KYR_DIR, "2026-10-07_lcdhd_hub_lead_selected.html")
KYR_FHKY_URL    <- "https://healthy-ky.org/rch"
# R/03af's re-based copy of FHKY's RCH page (session 94), which carries the
# "Program News" headline naming LCDHD.
KYR_FHKY_FILE   <- file.path("data", "evidence", "KY",
                             "2026-10-07_ky_foundation_healthy_kentucky_rch.html")
KYR_ANNOUNCED   <- as.Date("2026-10-05")
KYR_NOA_DATE    <- as.Date("2025-12-29")
KYR_CSV         <- here::here("data", "reference", "ky_year1_awardees.csv")

KYR_USER_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                         "+https://www.aha.org)")

KYR_SELECTED_SENTENCE <- paste(
  "Lake Cumberland District Health Department (LCDHD) has been selected to",
  "lead the Rural Community Hub for the Lake Cumberland region as part of the",
  "Rural Community Hubs for Chronic Care Innovation Program.")
KYR_CEILING_SENTENCE <- paste(
  "Throughout the grant period, the Lake Cumberland region will be eligible",
  "to receive up to $10 million in federal funding for the Rural Community",
  "Hubs program to support community health initiatives and Hub operations.")
KYR_FHKY_HEADLINE <- paste(
  "Lake Cumberland District Health Department Selected to Lead Local Efforts",
  "for New Program Supporting Healthier Rural Communities")


# -- retrieval ---------------------------------------------------------------

kyr_fetch <- function(force = FALSE) {
  if (file.exists(here::here(KYR_RELEASE)) && !force) {
    message("[KY RCH] have ", KYR_RELEASE)
    return(invisible(KYR_RELEASE))
  }
  rhtp_watch_archive(KYR_RELEASE_URL, KYR_RELEASE, KYR_USER_AGENT)
  message("[KY RCH] archived ", KYR_RELEASE)
  invisible(KYR_RELEASE)
}

kyr_text <- function(path) {
  h <- xml2::read_html(here::here(path))
  xml2::xml_remove(xml2::xml_find_all(h, "//script|//style|//noscript"))
  stringr::str_squish(rvest::html_text2(h))
}


# -- assertions --------------------------------------------------------------

kyr_assert_sources <- function() {
  rel <- kyr_text(KYR_RELEASE)
  for (s in c(KYR_SELECTED_SENTENCE, KYR_CEILING_SENTENCE,
              "October 5, 2026", "competitive application process")) {
    if (!grepl(s, rel, fixed = TRUE)) {
      stop("[KY RCH] LCDHD's release no longer says: '", s, "'. Re-read it.",
           call. = FALSE)
    }
  }
  fh <- kyr_text(KYR_FHKY_FILE)
  if (!grepl(KYR_FHKY_HEADLINE, fh, fixed = TRUE)) {
    stop("[KY RCH] FHKY's RCH page does not carry the LCDHD headline.",
         call. = FALSE)
  }
  # Three currency figures, and only one is about RCH money: "$10 million" is
  # the regional five-year CEILING; "$6.1 billion" is Kentucky's 2023 diabetes
  # cost; "$212.9 million" is the CMS footer -- Kentucky's ALLOTMENT
  # ($212,905,591, §7.1), Tier 1, never this award (§0.2).
  money <- unique(stringr::str_extract_all(rel, "\\$[0-9][0-9,.]*( (million|billion))?")[[1]])
  if (!setequal(money, c("$10 million", "$6.1 billion", "$212.9 million"))) {
    stop("[KY RCH] the release's currency figures changed: ",
         paste(money, collapse = "; "), ". Read them before building.",
         call. = FALSE)
  }
  if (KYR_ANNOUNCED <= KYR_NOA_DATE) stop("[KY RCH] date test.", call. = FALSE)
  invisible(TRUE)
}


# -- the award file ----------------------------------------------------------

kyr_awardees <- function() {
  awardee <- "Lake Cumberland District Health Department"
  rtype <- "LOCAL_GOVT_OR_PUBLIC_HEALTH"
  cls <- rhtp_classify_recipient_type(awardee, KYR_STATE)
  flow <- rhtp_classify_flow(rtype, "Rural Community Hub Lead Organization",
                             award_made = TRUE)
  tibble::tibble(
    state = KYR_STATE,
    row_no = 1L,
    awardee = awardee,
    amount = NA_real_,
    recipient_type = rtype,
    distributed_to_hospital = flow$distributed_to_hospital,
    note = paste(
      "Rural Community Hubs for Chronic Care Innovation: Hub Lead Organization",
      "for the Lake Cumberland region (Adair, Casey, Clinton, Cumberland,",
      "Green, McCreary, Pulaski, Russell, Taylor, Wayne), selected 'through a",
      "competitive application process' and announced 2026-10-05. NO AMOUNT",
      "PUBLISHED; 'up to $10 million' over the five-year grant period is a",
      "CEILING ON THE REGION, not this award (see amount_ceiling_text). Big",
      "Sandy and Purchase Hub Leads not yet named."),
    recipient_confirmed = "Yes",
    amount_confirmed = "No",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = paste("Lake Cumberland District Health Department",
                                  "Selected to Lead Local Efforts for New",
                                  "Program Supporting Healthier Rural Communities"),
    state_source_url = KYR_FHKY_URL,
    validation_source_type = "OTHER",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03by_ky_rch_awardees.R",
    ccn = NA_character_,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    recipient_type_source = paste0(
      "TYPED (session 94): a Kentucky district health department -- its own ",
      "name and its own site (ORG_WEBSITE). Classifier said ",
      cls$recipient_type, "/", cls$determination_confidence, "."),
    determination_confidence = "MEDIUM",
    flag_reason = NA_character_,
    award_pool = "Rural Community Hubs for Chronic Care Innovation",
    budget_period = "Grant period FY2026-FY2030; Budget Period 1 share not stated",
    flow_type = flow$flow_type,
    hospital_benefiting = "Unclear",
    hospital_attribution = "NOT_HOSPITAL",
    intermediary_name = NA_character_,
    determination_basis = paste0(
      "§10.2 NON_HOSPITAL on the RECIPIENT (§0.3a): a local health department, ",
      "not a hospital. The Hub convenes 'providers, schools, employers, faith ",
      "communities, government agencies, and more'; a hospital partner is not a ",
      "recipient (§7, New York's rule), so hospital_benefiting is Unclear and ",
      "moves no figure. RECIPIENT NAMED by FHKY's RCH page (the RCH convening ",
      "partner; headline '", KYR_FHKY_HEADLINE, "') and by LCDHD's own release: '",
      KYR_SELECTED_SENTENCE, "' Neither is a state agency, hence ",
      "validation_source_type = OTHER."),
    amount_basis = paste0(
      "NOT PUBLISHED. Neither source prints an award amount. The release's only ",
      "programme figure is a CEILING: '", KYR_CEILING_SENTENCE, "' It is a ",
      "maximum, attaches to the REGION, and spans FY2026-FY2030, so it is never ",
      "this row's amount and is held as text only."),
    amount_ceiling_text = "up to $10 million over five years (FY2026-FY2030), Lake Cumberland region; a ceiling, not an award",
    basis_type = "ORG_WEBSITE",
    round_amount = NA_real_,
    announcement_date = KYR_ANNOUNCED,
    source_archive_path = paste(KYR_RELEASE, KYR_FHKY_FILE, sep = "; "))
}


# -- validate / build / report -----------------------------------------------

kyr_validate <- function() {
  kyr_assert_sources()
  d <- kyr_awardees()
  stopifnot(nrow(d) == 1L, all(is.na(d$amount)),
            d$recipient_type %in% rhtp_vocabulary("recipient_type"),
            d$distributed_to_hospital == "No")
  message("[KY RCH] all assertions pass.")
  invisible(TRUE)
}

kyr_build <- function() {
  kyr_validate()
  d <- kyr_awardees()
  readr::write_csv(d, KYR_CSV, na = "")
  message("[KY RCH] wrote ", nrow(d), " row to ", KYR_CSV)
  invisible(d)
}

kyr_report <- function() {
  d <- kyr_awardees()
  cat("\nKENTUCKY -- Rural Community Hubs, Hub Leads named\n")
  cat(sprintf("  %s  amount: none published  %s / %s\n", d$awardee,
              d$recipient_type, d$distributed_to_hospital))
  cat("  Ceiling (text only):", d$amount_ceiling_text, "\n")
  invisible(d)
}


if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) kyr_fetch(force = "--force" %in% args)
  if ("--validate" %in% args) kyr_validate()
  if ("--build" %in% args) kyr_build()
  if ("--report" %in% args) kyr_report()
  if (!length(args)) message("Usage: --fetch [--force] | --validate | --build | --report")
}
