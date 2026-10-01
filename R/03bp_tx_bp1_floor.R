#!/usr/bin/env Rscript
# 03bp_tx_bp1_floor.R --------------------------------------------------------
#
# TEXAS -- A KNOWN FLOOR, NOT AN EXTRACTION (session 82).
#
# HHSC and the Governor announced on 2026-09-28 that "68 rural hospital
# districts and authorities have been awarded $750,000 each" ($51M, Rural Texas
# Strong Initiative 1, direct awards). Neither release names one of them.
#
# The one document that names ANY is Texas's CMS Budget Period 1 annual report,
# bdgt-prd-1-ann-rpt.xlsx, linked from HHSC's RHTP programme page
# (Last-Modified 2026-09-28T15:33:17Z). Its "First-Tier Entities" tab lists 35
# entities: HHSC, DSHS, and 33 HOSPITAL DISTRICTS AND AUTHORITIES at $750,000
# OBLIGATED each ($24,750,000), $0 DISBURSED, every one typed "Other Local
# Government". That is a REPORTING-PERIOD SNAPSHOT of first-tier obligations,
# not the award round:
#   * 33 is a FLOOR on the 68 announced, never the round. The other 35 are
#     unnamed anywhere this project has found.
#   * "Obligated" is not "disbursed". Every district shows $0 disbursed.
#   * HHSC and DSHS are state agencies (DSHS: $22,389,223 obligated). They are
#     not subawards to hospitals and are not in the floor.
#
# WHY THIS IS NOT tx_year1_awardees.csv. A Texas hospital district is a local
# government that may or may not operate a hospital, and the report's own
# entity type is "Other Local Government". Each district counts as a hospital
# only on a CMS enrolment check (§0.4, the Colorado rule). This file RUNS the
# exact-name screen against CMS's TX Hospital Enrollment file
# (data/evidence/federal_records/2026-10-01/) and records the result, and it
# CODES NOTHING: no recipient_type, no distributed_to_hospital, no bucket. 28
# of 33 match an enrolled hospital's ORGANIZATION NAME exactly; 4 have a
# near-name enrolled entity that a human must bridge (Coryell, DeWitt, Haskell,
# Ochiltree); Hardeman County Hospital District has no hospital enrolment at
# all. The file is never in STATE_FILES, and its dollar column is named for
# what it is (obligated_bp1_report) so it is not read as an award amount.
#
# THE WATCH. R/03n's --probe reads the live xlsx (into a temp file, never
# data/evidence/) and TRIPS when the number of local-government first-tier
# entities is no longer 33 -- the day HHSC's report names more of the 68.
#
# Usage:
#   Rscript R/03bp_tx_bp1_floor.R --fetch      # archive the xlsx + manifest line
#   Rscript R/03bp_tx_bp1_floor.R --validate   # assertions against the archive
#   Rscript R/03bp_tx_bp1_floor.R --build      # write tx_bp1_first_tier_floor.csv

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})
source(here::here("R", "utils_config.R"))

TX_BP1_URL  <- paste0("https://pfd.hhs.texas.gov/sites/default/files/documents/",
                      "rural-hlth-prgm/bdgt-prd-1-ann-rpt.xlsx")
TX_BP1_FILE <- file.path("data", "evidence", "TX",
                         "2026-10-01_hhsc_bdgt_prd_1_ann_rpt.xlsx")
TX_BP1_CSV  <- here::here("data", "reference", "tx_bp1_first_tier_floor.csv")
TX_BP1_FEDERAL <- file.path("data", "evidence", "federal_records", "2026-10-01",
                            "cms_hosp_enrollments_TX.json")
TX_BP1_DISTRICTS <- 33L
TX_BP1_ANNOUNCED <- 68L
TX_BP1_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                       "research use; +https://www.aha.org)")

# Near-name enrolled entities, READ BY HAND from the TX Hospital Enrollment
# file. Recorded as candidates for Stage 5, never as matches (§2).
TX_BP1_NEAR <- c(
  "Coryell County Hospital Authority" =
    "CORYELL COUNTY MEMORIAL HOSPITAL AUTHORITY dba CORYELL MEMORIAL HOSPITAL (451379)",
  "DeWitt Medical District Cuero Regional Hospital" =
    "DEWITT MEDICAL DISTRICT (450597)",
  "Haskell County Hospital District" =
    "HASKELL COUNTY HOSPITAL dba HASKELL MEMORIAL HOSPITAL (451341)",
  "Ochiltree County Hospital District" =
    "OCHILTREE HOSPITAL DISTRICT dba OCHILTREE GENERAL HOSPITAL (451359)")

#' The First-Tier Entities tab, one row per entity
tx_bp1_first_tier <- function(path = here::here(TX_BP1_FILE)) {
  d <- suppressMessages(readxl::read_excel(path, "First-Tier Entities",
                                           col_names = FALSE,
                                           .name_repair = "minimal"))
  d <- as.data.frame(d, stringsAsFactors = FALSE)
  e <- d[grepl("^[0-9]+$", as.character(d[[1]])), , drop = FALSE]
  tibble::tibble(entity_id = as.integer(e[[1]]),
                 entity = stringr::str_squish(e[[2]]),
                 entity_type = stringr::str_squish(e[[3]]),
                 obligated_bp1_report = as.numeric(e[[4]]),
                 disbursed_bp1_report = as.numeric(e[[6]]))
}

tx_bp1_assert <- function(e = tx_bp1_first_tier()) {
  lg <- e[e$entity_type == "Other Local Government", ]
  if (nrow(lg) != TX_BP1_DISTRICTS) {
    stop("[TX] THE BP1 REPORT NOW NAMES ", nrow(lg), " LOCAL-GOVERNMENT ",
         "FIRST-TIER ENTITIES, NOT 33 (68 were announced). Read it, archive it ",
         "with --fetch, and rebuild the floor.", call. = FALSE)
  }
  if (any(abs(lg$obligated_bp1_report - 750000) > 0.005)) {
    stop("[TX] a district's obligation is no longer $750,000.", call. = FALSE)
  }
  if (any(lg$disbursed_bp1_report != 0)) {
    stop("[TX] a district now shows a DISBURSEMENT. Read it.", call. = FALSE)
  }
  if (!all(grepl("Hospital|Medical District|Healthcare", lg$entity))) {
    stop("[TX] a local-government entity is not a hospital district or ",
         "authority by name.", call. = FALSE)
  }
  if (!setequal(setdiff(e$entity_type, "Other Local Government"),
                c("State Health and Human Services Agency", "Other State Agency"))) {
    stop("[TX] the non-district first-tier entities changed type.", call. = FALSE)
  }
  invisible(lg)
}

tx_bp1_norm <- function(x) {
  x <- toupper(x)
  x <- gsub("[.,'’/&()-]", " ", x)
  x <- stringr::str_squish(gsub("[^A-Z0-9 ]", "", x))
  sub(" (INC|LLC)$", "", sub("^THE ", "", x))
}

#' The exact-name enrolment screen. Screens; never codes.
tx_bp1_floor <- function(e = tx_bp1_first_tier()) {
  lg <- tx_bp1_assert(e)
  j <- jsonlite::fromJSON(here::here(TX_BP1_FEDERAL))
  f <- tibble::tibble(ccn = j$CCN, org = j$`ORGANIZATION NAME`,
                      dba = dplyr::coalesce(j$`DOING BUSINESS AS NAME`, ""))
  hit <- vapply(lg$entity, function(a) {
    h <- f[tx_bp1_norm(f$org) == tx_bp1_norm(a) | tx_bp1_norm(f$dba) == tx_bp1_norm(a), ]
    six <- sort(unique(h$ccn[grepl("^[0-9]{6}$", h$ccn)]))
    if (length(six)) paste0(unique(h$org)[1], " (", paste(six, collapse = "/"), ")") else NA_character_
  }, character(1))
  lg %>%
    dplyr::mutate(
      state = "TX",
      cms_hospital_enrolment_exact = unname(hit),
      cms_hospital_enrolment_near = unname(TX_BP1_NEAR[entity]),
      enrolment_screen = dplyr::case_when(
        !is.na(cms_hospital_enrolment_exact) ~ "EXACT_LEGAL_NAME",
        !is.na(cms_hospital_enrolment_near) ~ "NEAR_NAME_NEEDS_HAND_BRIDGE",
        TRUE ~ "NO_HOSPITAL_ENROLMENT_FOUND"),
      note = paste0("Texas CMS Budget Period 1 annual report, First-Tier Entities tab: ",
                    "obligated, not disbursed. One of 33 named against 68 announced ",
                    "(2026-09-28); a FLOOR, never the round. NOT CODED: the enrolment ",
                    "screen is evidence for Stage 5, not a hospital determination."),
      source_archive_path = TX_BP1_FILE) %>%
    dplyr::select(state, entity_id, entity, entity_type, obligated_bp1_report,
                  disbursed_bp1_report, enrolment_screen,
                  cms_hospital_enrolment_exact, cms_hospital_enrolment_near,
                  note, source_archive_path)
}

#' Probe half, called from R/03n's tx_probe(): read the LIVE xlsx into a temp
#' file (never data/evidence/) and return the tripwire finding, if any.
tx_bp1_live_finding <- function() {
  tmp <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmp), add = TRUE)
  r <- httr::GET(TX_BP1_URL, httr::user_agent(TX_BP1_AGENT), httr::timeout(90),
                 httr::write_disk(tmp, overwrite = TRUE))
  if (httr::status_code(r) != 200L) {
    stop("[TX] HTTP ", httr::status_code(r), " from the BP1 report.", call. = FALSE)
  }
  e <- tx_bp1_first_tier(tmp)
  n <- sum(e$entity_type == "Other Local Government")
  held <- digest::digest(tx_bp1_first_tier(), algo = "sha256")
  list(n_districts = n,
       changed = !identical(digest::digest(e, algo = "sha256"), held),
       finding = if (n != TX_BP1_DISTRICTS) paste0(
         "BP1 REPORT: the First-Tier Entities tab now names ", n,
         " hospital districts/authorities (was 33; 68 were announced). ",
         "Archive it (R/03bp --fetch) and rebuild the floor.") else NULL)
}

tx_bp1_fetch <- function() {
  dest <- here::here(TX_BP1_FILE)
  r <- httr::GET(TX_BP1_URL, httr::user_agent(TX_BP1_AGENT), httr::timeout(90),
                 httr::write_disk(dest, overwrite = TRUE))
  stopifnot(httr::status_code(r) == 200L)
  line <- paste(digest::digest(file = dest, algo = "sha256"), basename(dest),
                TX_BP1_URL, paste0("last_modified=", httr::headers(r)[["last-modified"]]),
                format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), sep = "  ")
  cat(line, "\n", file = here::here(dirname(TX_BP1_FILE), "MANIFEST_bp1.txt"),
      append = TRUE, sep = "")
  message("[TX] archived ", TX_BP1_FILE)
}

tx_bp1_build <- function() {
  fl <- tx_bp1_floor()
  readr::write_csv(fl, TX_BP1_CSV, na = "")
  message("[TX] wrote ", nrow(fl), " floor rows: ",
          paste(names(table(fl$enrolment_screen)), table(fl$enrolment_screen),
                sep = " ", collapse = "; "))
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) tx_bp1_fetch()
  if ("--validate" %in% args) { tx_bp1_assert(); message("[TX] BP1 floor assertions pass.") }
  if ("--build" %in% args) tx_bp1_build()
  if (!length(args)) message("Usage: --fetch | --validate | --build")
}
