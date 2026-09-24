# 03ar_rural_cut_report.R ------------------------------------------------------
# Session 51. THE RURAL CUT OF `NAMED_HOSPITAL`, AS A REPORT AND NEVER A
# RE-CODING.
#
# The question this answers is one a reader is likely to ask next: of the
# named-hospital rows and dollars, how many are attributable to RURAL hospitals
# specifically? RHTP money is rural by programme and not by recipient -- a
# state may pay an urban hospital to serve rural patients, and Florida's owner
# workbook says so outright on two rows -- so "it is RHTP" is never evidence
# that the hospital is rural.
#
# THE RULE IS: USE WHAT THE SOURCES ALREADY CARRY, AND REPORT THE GAP WHERE
# THEY CARRY NOTHING. No rural status is inferred -- not from a county name,
# not from a pool's title ("Rural Technology Grant"), not from a project
# description, not from this project's own knowledge of a hospital. Every row
# of `NAMED_HOSPITAL` lands in exactly ONE evidence class below, in this
# precedence order, and the class says WHO made the statement:
#
#   STATE_SOURCE_RURAL      the state's own award document designates the
#                           RECIPIENT rural: Georgia's AHEAD roster (CMS CAH /
#                           RRC and Georgia's own "Rural" and "In 126 Rural/
#                           Partial Rural Counties" classes), Wyoming's
#                           Initiative 1.1 table (headed "Hospital", initiative
#                           "Critical Access Hospital - Basic"), Oregon's
#                           Transformation Fund table ("The 32 rural hospitals
#                           ... The three rural hospitals ...").
#   STATE_SOURCE_NOT_RURAL  the source says the recipient is NOT rural:
#                           Florida's "URBAN hospital serving rural areas".
#   SITE_NOT_RECIPIENT      a rural designation IS recorded, but it describes
#                           WHERE THE ACTIVITY SITS, not the hospital that was
#                           paid: Delaware's "Sussex County (rural)" is the
#                           schools' county, and Nemours is a Wilmington system.
#                           §0.3a applied to rurality -- judge the recipient.
#   FEDERAL_RECORD_CCN      the row's recorded basis cites a CMS CCN (session
#                           50's enrolment matches, MS and SC), and the CCN is
#                           looked up in CMS Hospital Enrollments as ARCHIVED
#                           under data/evidence/federal_records/2026-09-22/. The
#                           designation is that record's own PROVIDER TYPE TEXT:
#                           "CRITICAL ACCESS HOSPITAL" or "RURAL EMERGENCY
#                           HOSPITAL (REH)" counts as rural; "PART A PROVIDER -
#                           HOSPITAL" carries no rural designation -- which is
#                           NOT a finding that the hospital is urban.
#
#                           THE RECORD, NOT THE PROSE. Session 50's basis text
#                           calls Progressive Health of Houston and Webster
#                           Healthcare Services "critical access hospital
#                           operator[s]". CMS enrols Progressive (CCN 250785) as
#                           a RURAL EMERGENCY HOSPITAL and Webster (CCN 250020)
#                           as an ordinary hospital. Neither is a CAH; the
#                           HOSPITAL_OR_SYSTEM typing is right either way, and
#                           this file reads the enrolment field.
#   GENERAL_KNOWLEDGE_ONLY  the only rural statement on the row is a verifier's
#                           general-knowledge "critical access hospital" (basis
#                           type GENERAL_KNOWLEDGE). Shown so a reader can see
#                           it; EXCLUDED from the rural figure, because it is
#                           not something a source carries.
#   NOT_RECORDED            nothing on the row says either way. The gap.
#
# Nothing here writes to a state file. The two outputs are report tables:
#   data/reference/rural_cut_rows.csv      one row per NAMED_HOSPITAL row
#   data/reference/rural_cut_by_state.csv  state x class, rows and dollars
#
# ROWS AND DOLLARS ARE BOTH LOAD-BEARING (Nevada's rule). Iowa, Nevada,
# Delaware and North Carolina price nobody, so their rows carry $0 and a
# dollar-only reading drops them.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only. No setwd(); here::here().
# Contains no network calls.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

RC_ENROLMENTS <- c(
  MS = "data/evidence/federal_records/2026-09-22/cms_hosp_enrollments_MS.json",
  SC = "data/evidence/federal_records/2026-09-22/cms_hosp_enrollments_SC.json",
  # Session 52: New York's RCHI leads and Kansas's Emerging Technology rows
  # carry their CCN in the `ccn` column, typed against these slices.
  NY = "data/evidence/federal_records/2026-09-22/cms_hosp_enrollments_NY.json",
  KS = "data/evidence/federal_records/2026-09-22/cms_hosp_enrollments_KS.json",
  # Session 54: the four states extracted this session, plus NEW HAMPSHIRE,
  # because Vermont's three Mary Hitchcock rows cite a Lebanon NH CCN.
  VT = "data/evidence/federal_records/2026-09-23/cms_hosp_enrollments_VT.json",
  NH = "data/evidence/federal_records/2026-09-23/cms_hosp_enrollments_NH.json",
  CT = "data/evidence/federal_records/2026-09-23/cms_hosp_enrollments_CT.json",
  WV = "data/evidence/federal_records/2026-09-23/cms_hosp_enrollments_WV.json",
  MO = "data/evidence/federal_records/2026-09-23/cms_hosp_enrollments_MO.json",
  # Session 59: Tennessee's two hospital rows cite CCN 441305 (Macon, a CAH
  # number -- on a hand-read BRIDGE) and 440059 (Cookeville, the foundation's
  # parent).
  TN = "data/evidence/federal_records/2026-09-23/cms_hosp_enrollments_TN.json",
  # Session 61: New Jersey's 33 federal-record hospital rows; a CCN is cited
  # singly only where it is the facility (a bracketed site, or a
  # single-hospital corporation).
  NJ = "data/evidence/federal_records/2026-09-24/cms_hosp_enrollments_NJ.json",
  # Session 63: Indiana's GROW regional recipients, typed on CMS's IN files.
  IN = "data/evidence/federal_records/2026-09-24/cms_hosp_enrollments_IN.json")

RC_ROWS_CSV <- "data/reference/rural_cut_rows.csv"
RC_STATE_CSV <- "data/reference/rural_cut_by_state.csv"

RC_CLASSES <- c("STATE_SOURCE_RURAL", "STATE_SOURCE_NOT_RURAL",
                "SITE_NOT_RECIPIENT", "FEDERAL_RECORD_CCN",
                "GENERAL_KNOWLEDGE_ONLY", "NOT_RECORDED")

#' The state files, read from the union test so the two cannot drift apart
rc_state_files <- function() {
  tf <- readLines(here::here("tests/testthat/test_state_union.R"))
  i0 <- grep("^STATE_FILES <- c\\(", tf)
  i1 <- i0 + which(grepl("^\\)", tf[(i0 + 1):length(tf)]))[1]
  eval(parse(text = tf[i0:i1]))
}

rc_col <- function(d, c) if (c %in% names(d)) d[[c]] else rep(NA_character_, nrow(d))

#' Every NAMED_HOSPITAL row, with the columns the classes read
rc_named_rows <- function(files = rc_state_files()) {
  purrr::imap_dfr(files, function(path, key) {
    d <- readr::read_csv(here::here(path), col_types = readr::cols(.default = "c"),
                         na = c("", "NA"), progress = FALSE)
    if (!"distributed_to_hospital" %in% names(d)) return(NULL)
    b <- rhtp_hospital_attribution(rc_col(d, "flow_type"),
                                   d$distributed_to_hospital,
                                   rc_col(d, "recipient_type"),
                                   rc_col(d, "hospital_attribution"))
    keep <- b == "NAMED_HOSPITAL"
    if (!any(keep)) return(NULL)
    tibble::tibble(
      state = d$state[keep],
      file = basename(path),
      row_index = which(keep),
      awardee = d$awardee[keep],
      amount = suppressWarnings(as.numeric(d$amount[keep])),
      award_pool = rc_col(d, "award_pool")[keep],
      rural_designation = rc_col(d, "rural_designation")[keep],
      rural_designation_raw = rc_col(d, "rural_designation_raw")[keep],
      note = rc_col(d, "note")[keep],
      basis_type = rc_col(d, "basis_type")[keep],
      ccn_col = rc_col(d, "ccn")[keep],
      basis_text = paste(dplyr::coalesce(rc_col(d, "verified_basis")[keep], ""),
                         dplyr::coalesce(rc_col(d, "determination_basis")[keep], ""))
    )
  })
}

#' CCN -> CMS's own provider type, from the ARCHIVED enrolment files
rc_ccn_types <- function() {
  purrr::map_dfr(RC_ENROLMENTS, function(f) {
    e <- jsonlite::fromJSON(here::here(f))
    # CMS serves Connecticut's CCNs without their leading zero ("70003" for
    # 070003); a CCN is six characters, so pad before matching (session 54).
    tibble::tibble(ccn = stringr::str_pad(e$CCN, 6, pad = "0"),
                   provider_type = e$`PROVIDER TYPE TEXT`)
  }) %>% dplyr::distinct(ccn, .keep_all = TRUE)
}

#' One evidence class per row, in precedence order. See the file header.
rc_classify <- function(r) {
  ccn <- stringr::str_match(r$basis_text, "CCN (\\d{2}[0-9A-Z]\\d{3})")[, 2]
  # A CCN the row records in its own `ccn` column wins (session 52: NY, KS).
  ccn <- dplyr::coalesce(r$ccn_col, ccn)
  pt <- rc_ccn_types()
  ptype <- pt$provider_type[match(ccn, pt$ccn)]
  if (any(!is.na(ccn) & is.na(ptype))) {
    stop("[rural cut] ", sum(!is.na(ccn) & is.na(ptype)), " cited CCN(s) are ",
         "not in the archived enrolment files: ",
         paste(unique(ccn[!is.na(ccn) & is.na(ptype)]), collapse = ", "),
         call. = FALSE)
  }
  fed_rural <- !is.na(ptype) &
    stringr::str_detect(ptype, "CRITICAL ACCESS|RURAL EMERGENCY")
  ga_rural <- r$state == "GA" & !is.na(r$rural_designation_raw)
  wy_cah <- r$state == "WY" & !is.na(r$award_pool) &
    r$award_pool == "1.1 Critical Access Hospital - Basic"
  or_rural <- r$state == "OR" & !is.na(r$award_pool) &
    r$award_pool == "TRANSFORMATION_HOSPITAL"
  fl_urban <- r$state == "FL" & !is.na(r$note) &
    stringr::str_detect(r$note, "^URBAN hospital")
  de_site <- r$state == "DE" & !is.na(r$rural_designation)
  gk_cah <- !is.na(r$basis_type) & r$basis_type == "GENERAL_KNOWLEDGE" &
    stringr::str_detect(r$basis_text, stringr::regex("critical access",
                                                      ignore_case = TRUE))
  r %>%
    dplyr::mutate(
      ccn = ccn,
      rural_class = dplyr::case_when(
        ga_rural | wy_cah | or_rural ~ "STATE_SOURCE_RURAL",
        fl_urban                     ~ "STATE_SOURCE_NOT_RURAL",
        de_site                      ~ "SITE_NOT_RECIPIENT",
        !is.na(ccn)                  ~ "FEDERAL_RECORD_CCN",
        gk_cah                       ~ "GENERAL_KNOWLEDGE_ONLY",
        TRUE                         ~ "NOT_RECORDED"),
      designation = dplyr::case_when(
        ga_rural ~ paste0("GA roster: ", rural_designation_raw),
        wy_cah ~ "WY: Critical Access Hospital (Initiative 1.1 table)",
        or_rural ~ "OR: OHA 'rural hospital' (Transformation Fund table)",
        fl_urban ~ "FL owner workbook: URBAN hospital serving rural areas",
        de_site ~ paste0("DE: ", rural_designation, " -- the SCHOOL's county"),
        !is.na(ccn) ~ paste0("CMS enrolment, CCN ", ccn, ": ", ptype),
        gk_cah ~ "verifier's general knowledge: critical access hospital",
        TRUE ~ NA_character_),
      counts_as_rural = rural_class == "STATE_SOURCE_RURAL" |
        (rural_class == "FEDERAL_RECORD_CCN" & fed_rural)
    ) %>%
    dplyr::mutate(counts_as_rural = dplyr::coalesce(counts_as_rural, FALSE))
}

rc_rows <- function() rc_classify(rc_named_rows())

rc_by_state <- function(rows = rc_rows()) {
  rows %>%
    dplyr::group_by(state, rural_class) %>%
    dplyr::summarise(rows = dplyr::n(),
                     dollars = round(sum(amount, na.rm = TRUE), 2),
                     rural_rows = sum(counts_as_rural),
                     rural_dollars = round(sum(amount[counts_as_rural],
                                               na.rm = TRUE), 2),
                     .groups = "drop") %>%
    dplyr::arrange(state, match(rural_class, RC_CLASSES))
}

#' The partition is unchanged by construction; assert it.
rc_assert <- function(rows = rc_rows()) {
  if (!all(rows$rural_class %in% RC_CLASSES)) stop("unknown rural class")
  # SESSION 54's NAMED_HOSPITAL: 1,033 rows / $902,386,742.75 / 24 states --
  # session 53's 982 / $845,170,923.32 / 20 plus Vermont's 27 executed
  # hospital agreements ($22,641,819.43), Connecticut's Day Kimball and Sharon
  # ($33,350,000), West Virginia's CAMC and Cabell Huntington Foundation
  # ($1,224,000) and Missouri's 20 UNPRICED Strategic Minor Renovations
  # hospitals ($0). Session 53's figure was session 52's 981 plus Self
  # Regional Healthcare (Greenwood Pediatrics), $145,000.
  # SESSION 59: + Tennessee's two UNPRICED hospital rows (Macon Hospital, Inc;
  # Cookeville Regional Medical Center Foundation) -- 1,035 / $902,386,742.75
  # / 25 states. Rows and states move; dollars do not.
  # Session 61: NEW JERSEY adds 35 rows / $35,275,076 and a 26th state.
  # Session 63: INDIANA's GROW regional recipients add 44 UNPRICED rows and
  # (Indiana being new to the bucket) a 27th state. Dollars do not move.
  if (nrow(rows) != 1114L ||
      abs(sum(rows$amount, na.rm = TRUE) - 937661818.75) > 0.005 ||
      dplyr::n_distinct(rows$state) != 27L) {
    stop("[rural cut] NAMED_HOSPITAL is no longer 1,114 rows / $937,661,818.75 ",
         "/ 27 states; re-state the rural cut against the new partition.",
         call. = FALSE)
  }
  invisible(TRUE)
}

rc_build <- function() {
  rows <- rc_rows()
  rc_assert(rows)
  readr::write_csv(rows %>% dplyr::select(state, file, row_index, awardee,
                                          amount, rural_class, designation,
                                          counts_as_rural, ccn, basis_type),
                   here::here(RC_ROWS_CSV), na = "")
  readr::write_csv(rc_by_state(rows), here::here(RC_STATE_CSV), na = "")
  message("[rural cut] wrote ", RC_ROWS_CSV, " (", nrow(rows), " rows) and ",
          RC_STATE_CSV)
  invisible(rows)
}

rc_report <- function(rows = rc_rows()) {
  tot <- rows %>% dplyr::group_by(rural_class) %>%
    dplyr::summarise(rows = dplyr::n(),
                     dollars = sum(amount, na.rm = TRUE),
                     states = dplyr::n_distinct(state), .groups = "drop") %>%
    dplyr::arrange(match(rural_class, RC_CLASSES))
  print(tot)
  cat("\nCOUNTS AS RURAL (state source + CMS CAH/REH enrolment):",
      sum(rows$counts_as_rural), "rows /",
      format(sum(rows$amount[rows$counts_as_rural], na.rm = TRUE),
             big.mark = ","), "\n")
  invisible(tot)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--build" %in% args) rc_build()
  if ("--report" %in% args || length(args) == 0L) rc_report()
}
