#!/usr/bin/env Rscript
# 03ce_tx_rts_awardees.R -----------------------------------------------------
#
# TEXAS -- RURAL TEXAS STRONG, HHSC'S WEEKLY "INTENT TO AWARD" LIST: 312
# APPLICATION LINES, TYPED ON CMS'S TEXAS ENROLMENT FILES. Session 103.
#
# Texas was a NEGATIVE from session 19 (R/03n) and a 33-of-68 FLOOR from session
# 82 (R/03bp). On 2026-10-15 the Governor and HHSC announced that "HHSC plans to
# award $78 million in Rural Texas Strong grants to 216 rural healthcare
# providers", with "A list of the recipients is available here" linking
# 10-8-2026-list-award-recipients.xlsx. HHSC's programme page now links a newer
# list, 10-15-2026-list-award-recipients.xlsx ("as of 10/14/26"), and says
# "The list will be updated weekly". Both are archived; THE 10/14 LIST IS THE
# ONE EXTRACTED, because it supersedes the 10/8 list (asserted below: every
# 10/8 line, by initiative and both amounts, is on it).
#
# WHAT THE LIST IS. Its own header: "a list of applications for the Rural Texas
# Strong program for which HHSC has advanced the application to an 'Intent to
# Award' status ... A grant is not considered awarded until a contract has been
# fully executed." One row per APPLICATION, columns Legal Name of Subrecipient |
# Initiative Number | Total Award Amount | Year 1 Subset | Intent to Award |
# Awarded (Contract Fully Executed). So:
#   * validation_source_type = NOTICE_OF_INTENT_TO_AWARD for every row (AR r1
#     and OR precedent). A row whose "Awarded (Contract Fully Executed)" reads
#     Yes has an executed contract: amount_confirmed = Yes. Every other row is
#     an intent: amount_confirmed = No, flag AMOUNT_PRELIMINARY.
#   * `amount` is the YEAR 1 SUBSET -- the Budget Period 1 portion, the grain
#     every other state file carries. The multi-year "Total Award Amount" is
#     kept in `total_award_amount` and is NEVER summed with `amount`.
#   * GRAIN (§6.1 mode 4). One row per printed line. An organisation with two
#     applications (Comanche County Medical Center has three) has two rows.
#
# THE RECONCILIATION, TO THE CENT, ON THE 10/8 LIST THE RELEASE CITES.
#   10/8 list, Year 1 Subset, all 284 lines           $129,089,434.73
#   less the 68 lines whose contract is EXECUTED       -$51,000,000.00
#       (68 x $750,000: the 2026-09-28 release's "68 rural hospital districts
#        and authorities have been awarded $750,000 each")
#   = the 216 intent lines                              $78,089,434.73
#   = the release's "The $78,089,434.73 is a portion of the $281,319,360.67
#     first-year award", and its "216 rural healthcare providers" is the count
#     of those 216 LINES (applications), not of distinct organisations.
# CMS's 2026-10-15 Texas release ("$78 million") is the same figure, rounded.
# The release prints no total of its own for the list, so the identity above IS
# the assertion (tx_rts_assert_reconciles()).
#
# TIERS (§0.2). "$281,319,360.67 first-year award" is TEXAS'S ALLOTMENT (§7.1
# anchor $281,319,361), Tier 1, asserted STATE_ALLOTMENT through the shared
# rule in both directions. The rows are Tier 3.
#
# TYPING IS ON CMS'S TX HOSPITAL, FQHC AND RHC ENROLLMENT FILES
# (data/evidence/federal_records/2026-10-01/, the files R/03bp screened), NOT
# ON THE NAME. Three routes, reported separately (tx_rts_report()):
#   EXACT   The string -- or a ';'-separated half, parenthetical and trailing
#           CCN-like number dropped -- equals an ORGANIZATION NAME or DBA after
#           case, punctuation, a leading THE and a trailing INC/LLC/LP/LTD/PA/
#           PLLC are set aside ("LIMITED PARTNERSHIP" reads as LP). MEDIUM.
#   BRIDGE  HAND-READ, below (TX_RTS_BRIDGES): the string abbreviates or
#           truncates one enrolled legal entity's name or DBA. LOW, with the
#           CCN where the entity has exactly one six-digit hospital CCN
#           (Colorado's precedent, session 82).
#   NONE    No exact record and no bridge.
#
# THE 72 ABBREVIATED INITIATIVE 1 LINES. Initiative 1's $750,000 Year 1 lines
# ($3,500,000 total) carry short names ("Memorial Hospital", "Rolling Plains",
# "Lockney Gen Hosp"). They are the 2026-09-28 round (68 executed) plus four
# not yet executed (Llano, Mitchell, Hansford, Fairfield). Each is bridged by
# hand to one enrolled legal entity, cross-checked against the 33 full names in
# HHSC's BP1 annual report (R/03bp): every one of those 33 corresponds to
# exactly one bridged line (tx_rts_assert_bp1()). "Memorial Hospital" is
# bridged to MOORE COUNTY HOSPITAL DISTRICT dba MEMORIAL HOSPITAL (Dumas) BY
# ELIMINATION -- Moore County is the one BP1 name no other line abbreviates --
# and is the weakest bridge in the file; the 10/14 list's own Initiative 4 line
# "Memorial Hospital (Dumas)" names the same hospital.
#
# A DISTRICT WITH NO HOSPITAL ENROLMENT IS NOT A HOSPITAL ROW (the owner's
# Hardeman precedent, session 103). Five districts on the list carry no
# enrolment under their own name: Hardeman County HD (2 lines), Maverick County
# HD, Nolan County HD, Stonewall County HD and Winnie Stowell HD. A Texas
# hospital district is a political subdivision, so each is
# LOCAL_GOVT_OR_PUBLIC_HEALTH / NON_HOSPITAL at MEDIUM (the form is in the
# name), and $0 of hospital money. THREE OF THE FIVE SIT NEXT TO AN ENROLLED
# HOSPITAL CARRYING ANOTHER NAME: HARDEMAN COUNTY MEMORIAL HOSP (CAH 451352,
# Quanah), ROLLING PLAINS MEMORIAL HOSPITAL (450055, Sweetwater, Nolan County)
# and STONEWALL MEMORIAL HOSPITAL dba STONEWALL MEMORIAL HOSPITAL DISTRICT
# (CAH 451318, Aspermont). R/03bp's "Hardeman ... has no hospital enrolment at
# all" is therefore imprecise: the DISTRICT has none; a hospital in its county
# seat does. Whether each district operates that hospital is not on any
# document read, so nothing is bridged (§2, §0.4) and the three are queued
# (TX_RTS_DISTRICT_NAME_NOT_ENROLLED, ONE-DIRECTIONAL: bridging only adds).
#
# NOT BRIDGED, ALSO QUEUED: "Lamb County Hospital" (enrolled LAMB HEALTHCARE
# CENTER, Littlefield: a different name); "UT Health Henderson" (HENDERSON
# HOSPITAL LLC carries no UT Health DBA, unlike Carthage, Jacksonville and
# Pittsburg, which are bridged). Christus Trinity Clinic's 13 county lines are
# a system's PHYSICIAN GROUP, not an enrolled hospital: PHYSICIAN_PRACTICE,
# the CalvertHealth Medical Group footing (session 102).
#
# §6.2: the list post-dates Texas's 2025-12-29 NOA, and the release states the
# provenance: "Rural Texas Strong, the CMS-approved state plan, is 100%
# federally funded through the Rural Health Transformation Program". THE TRAP
# IS STILL R/03n's: HHS0015180 / HHS0015677 (Rider 88, state money) name rural
# hospitals too and are never read here.
#
# THE WATCH. R/03n's Routine trips when the programme page links a list other
# than the one extracted here (tx_rts_live_finding()): re-run --fetch with the
# new list, --build, and re-read the bridges.
#
# Usage:
#   Rscript R/03ce_tx_rts_awardees.R --fetch      # archive lists, releases, page
#   Rscript R/03ce_tx_rts_awardees.R --validate   # assertions, offline
#   Rscript R/03ce_tx_rts_awardees.R --build      # write tx_year1_awardees.csv
#   Rscript R/03ce_tx_rts_awardees.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))
source(here::here("R", "utils_page_watch.R"))

TRT_STATE      <- "TX"
TRT_ALLOTMENT  <- 281319361
TRT_FOOTER     <- 281319360.67
TRT_NOA_DATE   <- as.Date("2025-12-29")
TRT_ANNOUNCED  <- as.Date("2026-10-15")
TRT_RELEASE_Y1 <- 78089434.73
TRT_RELEASE_N  <- 216L
TRT_ROUND1_N   <- 68L        # 2026-09-28: "68 ... awarded $750,000 each"
TRT_ROUND1_Y1  <- 750000
TRT_DIR        <- file.path("data", "evidence", "recheck", "2026-10-16", "TX")
TRT_CSV        <- here::here("data", "reference", "tx_year1_awardees.csv")
TRT_AGENT      <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                         "research use; +https://www.aha.org)")
TRT_PFD        <- "https://pfd.hhs.texas.gov"
TRT_PROGRAMME_URL <- paste0(TRT_PFD, "/rural-health-transformation-program")
TRT_LIST_PATH  <- "/sites/default/files/documents/rural-hlth-prgm/10-15-2026-list-award-recipients.xlsx"
TRT_LIST_URL   <- paste0(TRT_PFD, TRT_LIST_PATH)
TRT_PRIOR_URL  <- paste0(TRT_PFD, "/sites/default/files/documents/rural-hlth-prgm/",
                         "2026/10-8-2026-list-award-recipients.xlsx")
TRT_SOURCES <- tibble::tribble(
  ~key, ~url, ~file, ~kind,
  "list", TRT_LIST_URL,
  file.path(TRT_DIR, "2026-10-16_hhsc_rts_list_award_recipients_as_of_2026-10-14.xlsx"), "xlsx",
  "prior", TRT_PRIOR_URL,
  file.path(TRT_DIR, "2026-10-16_hhsc_rts_list_award_recipients_as_of_2026-10-08.xlsx"), "xlsx",
  "gov_release", "https://gov.texas.gov/news/post/governor-abbott-announces-78-million-in-rural-healthcare-grants",
  file.path(TRT_DIR, "2026-10-16_governor_release_2026-10-15_78m_rural_texas_strong.html"), "html",
  "hhsc_release", "https://www.hhs.texas.gov/news/2026/10/gov-abbott-hhsc-announce-recipients-78-million-rural-texas-strong-grants",
  file.path(TRT_DIR, "2026-10-16_hhsc_release_2026-10-15_78m_rural_texas_strong.html"), "html",
  "programme", TRT_PROGRAMME_URL,
  file.path(TRT_DIR, "2026-10-16_pfd_rhtp_programme.html"), "html")
TRT_FED <- c(
  HOSPITAL = file.path("data", "evidence", "federal_records", "2026-10-01", "cms_hosp_enrollments_TX.json"),
  FQHC     = file.path("data", "evidence", "federal_records", "2026-10-01", "cms_fqhc_enrollments_TX.json"),
  RHC      = file.path("data", "evidence", "federal_records", "2026-10-01", "cms_rhc_enrollments_TX.json"))
TRT_TITLE <- paste0("HHSC, Rural Texas Strong list of applications at 'Intent to ",
                    "Award' status as of 10/14/26 (10-15-2026-list-award-recipients.xlsx)")
TRT_INITIATIVES <- c(
  "1" = "Initiative 1: Make Rural Texans Healthy Again (rural hospital districts)",
  "4" = "Initiative 4: Infrastructure and Capital Investments for Rural Texas",
  "6" = "Initiative 6: Next Generation of the Small Town Doctor and Team")

# -- the list --------------------------------------------------------------

#' One row per application line, with the "Added <date>" section it sits in
tx_rts_read <- function(path = here::here(TRT_SOURCES$file[TRT_SOURCES$key == "list"])) {
  d <- as.data.frame(suppressMessages(readxl::read_excel(
    path, col_names = FALSE, .name_repair = "minimal", col_types = "text")),
    stringsAsFactors = FALSE)
  hdr <- which(d[[1]] %in% "Legal Name of Subrecipient")
  if (length(hdr) != 1L ||
      !identical(unname(unlist(d[hdr, 1:6])),
                 c("Legal Name of Subrecipient", "Initiative Number", "Total Award Amount",
                   "Year 1 Subset", "Intent to Award", "Awarded (Contract Fully Executed)"))) {
    stop("[TX RTS] the list's header row moved or was renamed: re-read it (§0.4).",
         call. = FALSE)
  }
  head_txt <- paste(stats::na.omit(unlist(d[seq_len(hdr - 1L), ])), collapse = " ")
  as_of <- stringr::str_match(head_txt, "'?\"?Intent to Award\"?'? status as of ([0-9/]+)")[, 2]
  body <- d[(hdr + 1L):nrow(d), , drop = FALSE]
  # "Added Oct. 14, 2026" sits in column 3 of the header block and again in
  # column 3 of a blank-named marker row inside the body.
  added_marker <- ifelse(is.na(body[[1]]) & grepl("^Added ", body[[3]]), body[[3]], NA_character_)
  section <- c(stats::na.omit(unlist(d[seq_len(hdr - 1L), 3]))[grepl("^Added ", stats::na.omit(unlist(d[seq_len(hdr - 1L), 3])))], NA)[1]
  sec <- character(nrow(body)); cur <- section
  for (i in seq_len(nrow(body))) {
    if (!is.na(added_marker[i])) cur <- added_marker[i]
    sec[i] <- cur
  }
  keep <- !is.na(body[[1]]) & nzchar(stringr::str_squish(body[[1]]))
  out <- tibble::tibble(
    awardee = stringr::str_squish(body[[1]][keep]),
    initiative = as.character(body[[2]][keep]),
    total_award_amount = round(as.numeric(body[[3]][keep]), 2),
    amount = round(as.numeric(body[[4]][keep]), 2),
    intent_to_award = body[[5]][keep],
    contract_executed = stringr::str_squish(body[[6]][keep]),
    list_section = ifelse(is.na(sec[keep]), "On the list before Oct. 8, 2026", sec[keep]))
  attr(out, "as_of") <- as_of
  out
}

tx_rts_assert_list <- function(d = tx_rts_read()) {
  if (!identical(attr(d, "as_of"), "10/14/26")) {
    stop("[TX RTS] the list is no longer 'as of 10/14/26' (", attr(d, "as_of"),
         "): a new weekly list. Re-fetch and rebuild.", call. = FALSE)
  }
  if (nrow(d) != 312L) stop("[TX RTS] ", nrow(d), " lines, not 312.", call. = FALSE)
  if (anyNA(d$amount) || anyNA(d$total_award_amount)) {
    stop("[TX RTS] a line has no parseable amount.", call. = FALSE)
  }
  if (!all(d$initiative %in% names(TRT_INITIATIVES))) {
    stop("[TX RTS] an initiative number outside 1/4/6: ",
         paste(setdiff(d$initiative, names(TRT_INITIATIVES)), collapse = ", "), call. = FALSE)
  }
  if (!all(d$intent_to_award == "Yes") || !all(d$contract_executed %in% c("Yes", "No"))) {
    stop("[TX RTS] a status column holds something other than Yes/No.", call. = FALSE)
  }
  if (any(d$amount > d$total_award_amount + 0.005)) {
    stop("[TX RTS] a Year 1 subset exceeds its total award.", call. = FALSE)
  }
  if (abs(sum(d$amount) - 137234879.62) > 0.005) {
    stop("[TX RTS] the 10/14 list's Year 1 subset sums to $",
         format(sum(d$amount), nsmall = 2, big.mark = ","), ", not $137,234,879.62.",
         call. = FALSE)
  }
  if (sum(d$contract_executed == "Yes") != 97L) {
    stop("[TX RTS] executed lines are no longer 97.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The release's $78,089,434.73 and 216, out of the 10/8 list it links
tx_rts_assert_reconciles <- function(prior = tx_rts_read(here::here(TRT_SOURCES$file[TRT_SOURCES$key == "prior"])),
                                     cur = tx_rts_read()) {
  if (!identical(attr(prior, "as_of"), "10/8/26") || nrow(prior) != 284L) {
    stop("[TX RTS] the 10/8 list is not the 284-line list the release cites.", call. = FALSE)
  }
  ex <- prior[prior$contract_executed == "Yes", ]
  if (nrow(ex) != TRT_ROUND1_N || any(abs(ex$amount - TRT_ROUND1_Y1) > 0.005) ||
      any(ex$initiative != "1")) {
    stop("[TX RTS] the 10/8 list's executed lines are no longer the 68 Initiative 1 ",
         "lines at $750,000 (the 2026-09-28 round).", call. = FALSE)
  }
  it <- prior[prior$contract_executed == "No", ]
  if (nrow(it) != TRT_RELEASE_N || abs(sum(it$amount) - TRT_RELEASE_Y1) > 0.005) {
    stop("[TX RTS] the 10/8 list's intent lines are ", nrow(it), " / $",
         format(sum(it$amount), nsmall = 2, big.mark = ","),
         ", not the release's 216 / $78,089,434.73.", call. = FALSE)
  }
  if (abs(sum(prior$amount) - (TRT_RELEASE_Y1 + TRT_ROUND1_N * TRT_ROUND1_Y1)) > 0.005) {
    stop("[TX RTS] $129,089,434.73 = $78,089,434.73 + 68 x $750,000 no longer holds.",
         call. = FALSE)
  }
  # The 10/14 list supersedes the 10/8 list: every 10/8 line (initiative, both
  # amounts) is on it. Names are NOT compared -- HHSC re-cased and expanded
  # them between the two (e.g. 'SOUTH LIMESTONE' block names).
  k <- function(x) paste(x$initiative, sprintf("%.2f", x$total_award_amount), sprintf("%.2f", x$amount))
  miss <- vctrs::vec_count(k(prior)) %>%
    dplyr::left_join(vctrs::vec_count(k(cur)), by = "key", suffix = c("_p", "_c")) %>%
    dplyr::filter(is.na(count_c) | count_c < count_p)
  if (nrow(miss)) {
    stop("[TX RTS] ", nrow(miss), " 10/8 line shape(s) are missing from the 10/14 list: ",
         "the newer list does not supersede the older. Read both.", call. = FALSE)
  }
  invisible(TRUE)
}

tx_rts_text <- function(key) {
  h <- xml2::read_html(here::here(TRT_SOURCES$file[TRT_SOURCES$key == key]))
  t <- rvest::html_text2(h)
  t <- stringr::str_replace_all(t, "[ ‑]", function(x) ifelse(x == "‑", "-", " "))
  stringr::str_squish(stringr::str_replace_all(t, "[‘’]", "'"))
}

tx_rts_assert_release <- function() {
  g <- tx_rts_text("gov_release")
  for (p in c(
    "plans to award $78 million in Rural Texas Strong grants to 216 rural healthcare providers",
    "A list of the recipients is available here",
    "HHSC will continue to announce its intent to award funding on a weekly basis",
    "Funding will be available after contracts are finalized.",
    "The $78,089,434.73 is a portion of the $281,319,360.67 first-year award HHSC received from the Centers for Medicare & Medicaid Services (CMS) Rural Health Transformation Program.",
    "is 100% federally funded through the Rural Health Transformation Program")) {
    if (!grepl(p, g, fixed = TRUE)) stop("[TX RTS] the Governor's release no longer carries: ", p, call. = FALSE)
  }
  h <- tx_rts_text("hhsc_release")
  if (!grepl("HHSC plans to award $78 million in Rural Texas Strong grants to 216 rural health care providers",
             h, fixed = TRUE)) {
    stop("[TX RTS] HHSC's release moved.", call. = FALSE)
  }
  p <- tx_rts_text("programme")
  if (!grepl("10-15-2026-list-award-recipients.xlsx", paste(readLines(here::here(
    TRT_SOURCES$file[TRT_SOURCES$key == "programme"]), warn = FALSE), collapse = " "), fixed = TRUE)) {
    stop("[TX RTS] the archived programme page does not link the extracted list.", call. = FALSE)
  }
  # §0.2: the "first-year award" is the ALLOTMENT; refused as a pool.
  rhtp_assert_footer_not_allotment(TRT_FOOTER, TRT_STATE, "STATE_ALLOTMENT",
                                   label = "TX 10-15 release, 'first-year award'")
  refused <- tryCatch({
    rhtp_assert_footer_not_allotment(TRT_FOOTER, TRT_STATE, "SOLICITATION",
                                     label = "TX first-year award read as a pool")
    FALSE
  }, error = function(e) TRUE)
  if (!refused) stop("[TX RTS] §0.2 no longer refuses the allotment as a pool.", call. = FALSE)
  if (!(TRT_ANNOUNCED > TRT_NOA_DATE)) stop("[TX RTS] §6.2 date test.", call. = FALSE)
  invisible(TRUE)
}

# -- typing ----------------------------------------------------------------

tx_rts_norm <- function(x) {
  x <- toupper(x)
  x <- gsub("LIMITED PARTNERSHIP", "LP", x, fixed = TRUE)
  x <- gsub("[.,'’/&()–-]", " ", x)
  x <- stringr::str_squish(gsub("[^A-Z0-9 ]", "", x))
  x <- sub("^THE ", "", x)
  sub(" (INC|INCORPORATED|LLC|PLLC|PC|PA|LP|LTD)$", "", x)
}

#' The halves of an awardee string a federal record may equal
tx_rts_halves <- function(a) {
  parts <- c(a, strsplit(a, ";", fixed = TRUE)[[1]])
  parts <- c(parts, sub("\\s*\\([^)]*\\)", "", parts))
  parts <- sub("\\s+[0-9]{5,}$", "", stringr::str_squish(parts))
  unique(tx_rts_norm(parts))
}

tx_rts_federal <- function() {
  dplyr::bind_rows(lapply(names(TRT_FED), function(k) {
    j <- jsonlite::fromJSON(here::here(TRT_FED[[k]]))
    tibble::tibble(kind = k, ccn = as.character(j$CCN), org = j$`ORGANIZATION NAME`,
                   dba = j$`DOING BUSINESS AS NAME`, city = j$CITY,
                   ptype = if ("PROVIDER TYPE TEXT" %in% names(j)) j$`PROVIDER TYPE TEXT` else NA_character_)
  }))
}

tx_rts_exact <- function(a, f) {
  h <- tx_rts_halves(a)
  f[tx_rts_norm(f$org) %in% h | tx_rts_norm(dplyr::coalesce(f$dba, "")) %in% h, ]
}

# HAND-READ BRIDGES: awardee string (as printed on the 10/14 list) -> the ONE
# enrolled ORGANIZATION NAME it abbreviates or truncates. `bp1` is the BP1
# report's full name for that first-tier entity, where the report names it.
TRT_I1 <- "Initiative 1 $750,000 line (abbreviated name)"
TX_RTS_BRIDGES <- tibble::tribble(
  ~awardee, ~org, ~bp1, ~why,
  "Fannin County", "FANNIN COUNTY HOSPITAL AUTHORITY", NA, TRT_I1,
  "Coryell County", "CORYELL COUNTY MEMORIAL HOSPITAL AUTHORITY", "Coryell County Hospital Authority", TRT_I1,
  "Ballinger Memorial", "BALLINGER MEMORIAL HOSPITAL DISTRICT", NA, TRT_I1,
  "Stonewall Memorial", "STONEWALL MEMORIAL HOSPITAL", NA, paste(TRT_I1, "-- the enrolled entity's DBA is STONEWALL MEMORIAL HOSPITAL DISTRICT"),
  "Bosque County", "BOSQUE COUNTY HOSPITAL DISTRICT", "Bosque County Hospital District", TRT_I1,
  "Refugio County", "REFUGIO COUNTY MEMORIAL HOSPITAL DISTRICT", "Refugio County Memorial Hospital District", TRT_I1,
  "Martin County", "MARTIN COUNTY HOSPITAL DISTRICT", "Martin County Hospital District", TRT_I1,
  "Chambers County", "CHAMBERS COUNTY PUBLIC HOSPITAL DISTRICT NO. 1", NA, TRT_I1,
  "Karnes County", "KARNES COUNTY HOSPITAL DISTRICT", NA, TRT_I1,
  "Anson Hospital", "ANSON HOSPITAL DISTRICT", NA, TRT_I1,
  "Pecos County", "PECOS COUNTY MEMORIAL HOSPITAL DISTRICT", NA, TRT_I1,
  "Somervell County", "SOMERVELL COUNTY HOSPITAL DISTRICT", "Somervell County Hospital District", TRT_I1,
  "Matagorda County", "MATAGORDA COUNTY HOSPITAL DISTRICT", "Matagorda County Hospital District", TRT_I1,
  "Muenster Hospital", "MUENSTER HOSPITAL DISTRICT", "Muenster Hospital District", TRT_I1,
  "Childress County", "CHILDRESS COUNTY HOSPITAL DISTRICT", "Childress County Hospital District", TRT_I1,
  "Lockney Gen Hosp", "LOCKNEY GENERAL HOSPITAL DISTRICT", NA, TRT_I1,
  "Fisher County", "FISHER COUNTY HOSPITAL DISTRICT", "Fisher County Hospital District", TRT_I1,
  "Graham Regional", "GRAHAM HOSPITAL DISTRICT", NA, paste(TRT_I1, "-- DBA GRAHAM REGIONAL MEDICAL CENTER; the entity holds two hospital CCNs (450085, 671300), so none is put on the row"),
  "LLano Regional", "LLANO REGIONAL HOSPITAL", NA, TRT_I1,
  "Tyler County Hosp", "TYLER COUNTY HOSPITAL DISTRICT", NA, paste(TRT_I1, "-- Woodville; not the city of Tyler's hospitals"),
  "Reagan Hospital", "REAGAN HOSPITAL DISTRICT", NA, TRT_I1,
  "Gonzales Healthcare", "GONZALES HEALTHCARE SYSTEMS", "Gonzales Healthcare Systems", TRT_I1,
  "Rankin County", "RANKIN COUNTY HOSPITAL DISTRICT", "Rankin County Hospital District", TRT_I1,
  "Electra Hospital", "ELECTRA HOSPITAL DISTRICT", "Electra Hospital District", TRT_I1,
  "Ochiltree General", "OCHILTREE HOSPITAL DISTRICT", "Ochiltree County Hospital District", paste(TRT_I1, "-- DBA OCHILTREE GENERAL HOSPITAL"),
  "Jackson County", "JACKSON COUNTY HOSPITAL DISTRICT", "Jackson County Hospital District", TRT_I1,
  "Mitchell County", "MITCHELL COUNTY HOSPITAL DISTRICT", NA, TRT_I1,
  "Deaf Smith Co", "DEAF SMITH COUNTY HOSPITAL DISTRICT", "Deaf Smith County Hospital District", TRT_I1,
  "Scurry County", "SCURRY COUNTY HOSPITAL DISTRICT", "Scurry County Hospital District", TRT_I1,
  "Dawson County", "DAWSON COUNTY HOSPITAL DISTRICT", NA, TRT_I1,
  "Eastland Memorial", "EASTLAND MEMORIAL HOSPITAL DISTRICT", NA, TRT_I1,
  "Winkler County", "WINKLER COUNTY HOSPITAL DISTRICT", NA, TRT_I1,
  "Lavaca Medical", "LAVACA HOSPITAL DISTRICT", "Lavaca Hospital District", paste(TRT_I1, "-- DBA LAVACA MEDICAL CENTER"),
  "Haskell Memorial", "HASKELL COUNTY HOSPITAL", "Haskell County Hospital District", paste(TRT_I1, "-- DBA HASKELL MEMORIAL HOSPITAL; the BP1 report adds 'District' to the enrolled name"),
  "Olney-Hamilton Hosp", "OLNEY-HAMILTON HOSPITAL DISTRICT", NA, TRT_I1,
  "North Wheeler County", "NORTH WHEELER COUNTY HOSPITAL DISTRICT", NA, TRT_I1,
  "Nocona Hospital", "NOCONA HOSPITAL DISTRICT", NA, TRT_I1,
  "Knox County Hosp", "KNOX COUNTY HOSPITAL DISTRICT", "Knox County Hospital District", TRT_I1,
  "Seminole Hospital", "SEMINOLE HOSPITAL DISTRICT OF GAINES COUNTY TEXAS", "Seminole Hospital District of Gaines County, Texas", TRT_I1,
  "Baylor County", "BAYLOR COUNTY HOSPITAL DISTRICT", NA, paste(TRT_I1, "-- Seymour; not a Baylor Scott & White entity"),
  "Castro County Hosp", "CASTRO COUNTY HOSPITAL DISTRICT", "Castro County Hospital District", TRT_I1,
  "Concho County Hosp", "CONCHO COUNTY HOSPITAL DISTRICT", "Concho County Hospital District", TRT_I1,
  "Crane County Hosp", "CRANE COUNTY HOSPITAL DISTRICT", "Crane County Hospital District", TRT_I1,
  "Wilson County", "WILSON COUNTY MEMORIAL HOSPITAL DISTRICT", NA, TRT_I1,
  "Dallam-Hartley", "DALLAM-HARTLEY COUNTIES HOSPITAL DISTRICT", NA, TRT_I1,
  "Starr County Hosp", "STARR COUNTY HOSPITAL DISTRICT", NA, TRT_I1,
  "Hansford County", "HANSFORD COUNTY HOSPITAL DISTRICT", NA, TRT_I1,
  "Dewitt Medical Dis", "DEWITT MEDICAL DISTRICT", "DeWitt Medical District Cuero Regional Hospital", TRT_I1,
  "Hamilton County", "HAMILTON COUNTY HOSPITAL DISTRICT", "Hamilton County Hospital District", paste(TRT_I1, "-- Hamilton; not Olney-Hamilton"),
  "Hemphill County", "HEMPHILL COUNTY HOSPITAL DISTRICT", NA, paste(TRT_I1, "-- Canadian; not Preferred Hospital Leasing Hemphill (Sabine County)"),
  "Jack County Hosp", "JACK COUNTY HOSPITAL DISTRICT", NA, TRT_I1,
  "McCamey County Hosp", "MCCAMEY COUNTY HOSPITAL DISTRICT", NA, TRT_I1,
  "Sutton County Hosp", "SUTTON COUNTY HOSPITAL DISTRICT", NA, TRT_I1,
  "Liberty County Hosp", "LIBERTY COUNTY HOSPITAL DISTRICT NO 1", NA, TRT_I1,
  "Lynn County Hosp", "LYNN COUNTY HOSPITAL DISTRICT", "Lynn County Hospital District", TRT_I1,
  "Medina County Hosp", "MEDINA COUNTY HOSPITAL DISTRICT", NA, TRT_I1,
  "Muleshoe Area Hosp", "MULESHOE AREA HOSPITAL DISTRICT", "Muleshoe Area Hospital District", TRT_I1,
  "Stephens Memorial", "STEPHENS MEMORIAL HOSPITAL DISTRICT", "Stephens Memorial Hospital District", TRT_I1,
  "Sweeny Hospital Dis", "SWEENY HOSPITAL DISTRICT", NA, TRT_I1,
  "Uvalde County Hosp", "UVALDE COUNTY HOSPITAL AUTHORITY", NA, TRT_I1,
  "North Runnels Co", "NORTH RUNNELS COUNTY HOSPITAL", NA, TRT_I1,
  "Iraan Hospital Dis", "GENERAL HOSPITAL", NA, paste(TRT_I1, "-- the enrolled ORGANIZATION NAME is bare 'GENERAL HOSPITAL', DBA IRAAN GENERAL HOSPITAL DISTRICT (CAH, Iraan)"),
  "Wilbarger General", "WILBARGER COUNTY HOSPITAL DISTRICT", NA, paste(TRT_I1, "-- DBA WILBARGER GENERAL HOSPITAL"),
  "Memorial Hospital", "MOORE COUNTY HOSPITAL DISTRICT", "Moore County Hospital District",
  paste(TRT_I1, "-- BRIDGED BY ELIMINATION, THE WEAKEST BRIDGE IN THE FILE: 'Memorial Hospital' is the DBA of three enrolled entities (Moore County HD, Seminole HD, Gonzales Healthcare Systems). Seminole and Gonzales each have their own Initiative 1 line; Moore County Hospital District is the one BP1 first-tier name no other line abbreviates; the list's own Initiative 4 line 'Memorial Hospital (Dumas)' names the same hospital"),
  "Rolling Plains", "ROLLING PLAINS MEMORIAL HOSPITAL", NA, TRT_I1,
  "Andrews County", "ANDREWS COUNTY HOSPITAL DISTRICT", NA, TRT_I1,
  "Fairfield Hospital", "FAIRFIELD HOSPITAL DISTRICT", NA, TRT_I1,
  # Not Initiative 1's short block, but the same kind of hand-read bridge:
  "Christus Jasper Memorial Hospital", "CHRISTUS HEALTH SOUTHEAST TEXAS", NA, "DBA CHRISTUS SOUTHEAST TEXAS-JASPER MEMORIAL (Jasper)",
  "UT Health Carthage", "CARTHAGE HOSPITAL, LLC", NA, "DBA UT HEALTH EAST TEXAS CARTHAGE HOSPITAL",
  "UT Health Jacksonville", "JACKSONVILLE HOSPITAL LLC", NA, "DBA UT HEALTH EAST TEXAS JACKSONVILLE HOSPITAL",
  "Ut Health Pittsburg", "PITTSBURG HOSPITAL LLC", NA, "DBA UT HEALTH EAST TEXAS PITTSBURG HOSPITAL",
  "Chambers County Public Hospital District", "CHAMBERS COUNTY PUBLIC HOSPITAL DISTRICT NO. 1", NA, "the string drops 'No. 1'",
  "Lockney Gen Hospital District", "LOCKNEY GENERAL HOSPITAL DISTRICT", NA, "'Gen' for 'General'",
  "Lynn Co Hospital District", "LYNN COUNTY HOSPITAL DISTRICT", NA, "'Co' for 'County'",
  "Memorial Hospital (Dumas) 1711169", "MOORE COUNTY HOSPITAL DISTRICT", NA, "DBA MEMORIAL HOSPITAL, city DUMAS: the parenthetical names the city",
  "Throckmorton County Memorial Hospital", "THROCKMORTON COUNTY MEMORIAL HOSP", NA, "the enrolled name truncates 'HOSPITAL'",
  "Ward County", "COUNTY OF WARD", NA, "the same legal body, words reordered (DBA WARD MEMORIAL HOSPITAL, Monahans)",
  "Rolling Plains Memorial Hosp", "ROLLING PLAINS MEMORIAL HOSPITAL", NA, "'Hosp' for 'Hospital'",
  "Heart Of Texas Community Health Center I", "HEART OF TEXAS COMMUNITY HEALTH CENTER, INC.", NA, "the list truncates the name at 40 characters (FQHC)",
  "Matagorda Episcopal Health Outreach Prog", "MATAGORDA EPISCOPAL HEALTH OUTREACH PROGRAM CORPORATION", NA, "the list truncates the name at 40 characters (FQHC)",
  "Vida Y Salud Health System", "VIDA Y SALUD - HEALTH SYSTEMS, INC.", NA, "'System' against 'Systems' (FQHC)"
)

# Districts with no enrolment under their own name: NOT hospital rows (the
# owner's Hardeman precedent). `near` is the enrolled hospital a human may
# judge to be the district's -- recorded, never bridged.
TX_RTS_DISTRICTS_NOT_ENROLLED <- tibble::tribble(
  ~awardee, ~near,
  "Hardeman County Hospital District", "HARDEMAN COUNTY MEMORIAL HOSP (CAH 451352, Quanah)",
  "Hardeman County", "HARDEMAN COUNTY MEMORIAL HOSP (CAH 451352, Quanah); the BP1 report names this first-tier entity 'Hardeman County Hospital District'",
  "Stonewall County Hospital District", "STONEWALL MEMORIAL HOSPITAL dba STONEWALL MEMORIAL HOSPITAL DISTRICT (CAH 451318, Aspermont)",
  "Nolan County Hospital District", "ROLLING PLAINS MEMORIAL HOSPITAL (450055, Sweetwater, the Nolan County seat)",
  "Maverick County Hospital District", NA,
  "Winnie Stowell Hospital District", NA)

# Hand-read typings of non-hospital lines the exact screen and the classifier
# cannot settle. Everything else: exact federal record, bridge, or classifier.
TX_RTS_OVERRIDES <- tibble::tribble(
  ~pattern, ~recipient_type, ~basis_type, ~confidence, ~why,
  "^Chris?tus Trinity Clinic - ", "PHYSICIAN_PRACTICE", "GENERAL_KNOWLEDGE", "LOW",
  "CHRISTUS Trinity Clinic is CHRISTUS Health's physician group; no CMS TX Hospital, FQHC or RHC record carries the string. A system's medical group is not an enrolled hospital (CalvertHealth Medical Group footing, session 102). Queued with the system-affiliate question (TX_RTS_HOSPITAL_SHAPED_NOT_BRIDGED).",
  "(M\\.D\\., P\\.A\\.|Md Pa$|O\\.D\\., PLLC)", "PHYSICIAN_PRACTICE", "STATE_SOURCE", "MEDIUM",
  "A physician's or optometrist's professional association (the form is in the string). Not a hospital.",
  "^Lamb County Hospital$", "NONPROFIT_CBO", NA, "LOW",
  "NOT BRIDGED: the enrolled hospital in Lamb County is LAMB HEALTHCARE CENTER (450698, Littlefield), a different name; no record carries 'Lamb County Hospital' (§2). §8's standing fallback; queued (TX_RTS_HOSPITAL_SHAPED_NOT_BRIDGED), one-directional.",
  "^UT Health Henderson$", "NONPROFIT_CBO", NA, "LOW",
  "NOT BRIDGED: HENDERSON HOSPITAL LLC (450475) carries no 'UT Health' DBA, unlike Carthage, Jacksonville and Pittsburg; the string may name a clinic. §8's standing fallback; queued (TX_RTS_HOSPITAL_SHAPED_NOT_BRIDGED), one-directional.",
  "(Pharmacy|Apothecary|Pharmacare|Pharmaceuticals| Rx )|Rx LLC$", "OTHER", "STATE_SOURCE", "MEDIUM",
  "DETERMINED FORM: a retail pharmacy (the form is in the string). Not a hospital.",
  "^Brookshire Brothers Inc$", "OTHER", "GENERAL_KNOWLEDGE", "LOW",
  "DETERMINED FORM: a grocery and retail-pharmacy chain (general knowledge). Not a hospital.",
  "(EMS|Ambulance Service|VFD)", "EMS_OR_PSAP", "STATE_SOURCE", "MEDIUM",
  "An EMS provider or volunteer fire department (the form is in the string).",
  "^Lifenet Inc$", "EMS_OR_PSAP", "GENERAL_KNOWLEDGE", "LOW",
  "LifeNet, an East Texas EMS provider (general knowledge); no CMS record.",
  "MHMR", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "GENERAL_KNOWLEDGE", "LOW",
  "A Texas community MHMR centre, a unit of local government (Tex. Health & Safety Code ch. 534; general knowledge). Not a hospital.",
  "^USRC ", "OTHER", "GENERAL_KNOWLEDGE", "LOW",
  "DETERMINED FORM: a dialysis facility of U.S. Renal Care (general knowledge). Not a hospital.",
  "^(Coleman Medical Group|Pediatric Practice Association)$", "PHYSICIAN_PRACTICE", "STATE_SOURCE", "MEDIUM",
  "A medical group / pediatric practice (the form is in the string); no CMS hospital record.",
  "^Principle Hs, LLC; Principle Health Systems$", "NONPROFIT_CBO", NA, "LOW",
  "NOT BRIDGED: no CMS TX record carries either half of the string. The enrolled hospitals Palestine Principal Healthcare LP and Mexia Principal Healthcare LP have their own lines; a parent or management company is not their enrolment (§2). §8's standing fallback; queued (TX_RTS_HOSPITAL_SHAPED_NOT_BRIDGED), one-directional.",
  "^State of Texas Electronic Provider System - STEPS$", "NONPROFIT_CBO", NA, "LOW",
  "The string names an electronic-provider system, not an organisation form; no CMS record (§8's standing fallback)."
)

TRT_DISTRICT_NOTE <- paste0(
  "NOT A HOSPITAL ROW (the owner's Hardeman precedent, session 103): no CMS TX ",
  "Hospital, FQHC or RHC enrolment carries this district's name. A Texas hospital ",
  "district is a political subdivision, so LOCAL_GOVT_OR_PUBLIC_HEALTH (the form is ",
  "in the name). ")

tx_rts_type_one <- function(a, f, cls_type) {
  b <- TX_RTS_BRIDGES[TX_RTS_BRIDGES$awardee == a, ]
  dn <- TX_RTS_DISTRICTS_NOT_ENROLLED[TX_RTS_DISTRICTS_NOT_ENROLLED$awardee == a, ]
  ov <- TX_RTS_OVERRIDES[vapply(TX_RTS_OVERRIDES$pattern, grepl, logical(1), x = a), ][1, ]
  hit <- tx_rts_exact(a, f)
  res <- function(rt, bt, cf, how, why, ccn = NA_character_, rec = NA_character_) {
    tibble::tibble(recipient_type = rt, basis_type = bt, determination_confidence = cf,
                   typing = how, why = why, ccn = ccn, enrolment = rec)
  }
  pick <- function(h) {
    k <- if ("HOSPITAL" %in% h$kind) "HOSPITAL" else if ("FQHC" %in% h$kind) "FQHC" else "RHC"
    hk <- h[h$kind == k, ]
    six <- sort(unique(hk$ccn[grepl("^[0-9]{6}$", hk$ccn)]))
    list(k = k, hk = hk, six = six,
         ccn = if (k == "HOSPITAL" && length(six) == 1L) six else NA_character_,
         rec = paste0(paste(unique(hk$org), collapse = "; "),
                      if (any(!is.na(hk$dba) & nzchar(hk$dba)))
                        paste0(" dba ", paste(unique(stats::na.omit(hk$dba[nzchar(hk$dba)])), collapse = " / ")) else "",
                      " (", paste(six, collapse = "/"), ", ", unique(hk$city)[1], ")"))
  }
  if (nrow(dn)) {
    return(res("LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM", "DISTRICT_NOT_ENROLLED",
               paste0(TRT_DISTRICT_NOTE, if (!is.na(dn$near))
                 paste0("An enrolled hospital nearby carries another name: ", dn$near,
                        ". Whether the district operates it is on no document read, so it is NOT bridged (§2, §0.4); queued TX_RTS_DISTRICT_NAME_NOT_ENROLLED, one-directional.")
                 else "No enrolled hospital in the file carries the county's or district's name.")))
  }
  if (nrow(b)) {
    h <- f[f$org == b$org, ]
    # One legal entity enrolling several hospitals: keep the record whose DBA
    # the string names (CHRISTUS HEALTH SOUTHEAST TEXAS: St. Elizabeth and Jasper).
    if (grepl("JASPER", toupper(a)) && b$org == "CHRISTUS HEALTH SOUTHEAST TEXAS") {
      h <- h[grepl("JASPER", dplyr::coalesce(h$dba, "")), ]
    }
    if (!nrow(h)) stop("[TX RTS] bridge target '", b$org, "' is not in the TX files.", call. = FALSE)
    p <- pick(h)
    rt <- c(HOSPITAL = "HOSPITAL_OR_SYSTEM", FQHC = "FQHC_OR_RHC", RHC = "FQHC_OR_RHC")[[p$k]]
    return(res(rt, "ORG_WEBSITE", "LOW", "BRIDGE",
               paste0("HAND-READ BRIDGE: CMS TX ", c(HOSPITAL = "Hospital", FQHC = "FQHC", RHC = "RHC")[[p$k]],
                      " Enrollment carries ", p$rec, ", ", p$hk$ptype[p$hk$ccn %in% p$six][1], ". ", b$why,
                      if (!is.na(b$bp1)) paste0("; HHSC's BP1 report names this first-tier entity '", b$bp1, "'") else "",
                      ". The string is not the enrolled name, so LOW."),
               ccn = p$ccn, rec = p$rec))
  }
  if (nrow(hit)) {
    p <- pick(hit)
    rt <- c(HOSPITAL = "HOSPITAL_OR_SYSTEM", FQHC = "FQHC_OR_RHC", RHC = "FQHC_OR_RHC")[[p$k]]
    if (p$k == "RHC" && !is.na(ov$pattern)) {
      # a practice's own RHC enrolment: the override's form stands
    } else {
      return(res(rt, "ORG_WEBSITE", "MEDIUM", "EXACT",
                 paste0("EXACT federal record: CMS TX ", c(HOSPITAL = "Hospital", FQHC = "FQHC", RHC = "RHC")[[p$k]],
                        " Enrollment carries this string as an ORGANIZATION NAME or DBA: ", p$rec,
                        if (p$k == "HOSPITAL") paste0(", ", p$hk$ptype[p$hk$ccn %in% p$six][1]) else "", "."),
                 ccn = p$ccn, rec = p$rec))
    }
  }
  if (!is.na(ov$pattern)) return(res(ov$recipient_type, ov$basis_type, ov$confidence, "HAND-READ", ov$why))
  if (cls_type == "HOSPITAL_OR_SYSTEM") {
    stop("[TX RTS] the classifier calls '", a, "' a hospital and no federal record, ",
         "bridge or hand-read decision covers it. Read it.", call. = FALSE)
  }
  NULL
}

tx_rts_awardees <- function(d = tx_rts_read(), f = tx_rts_federal()) {
  cls <- rhtp_classify_recipient_type(d$awardee, TRT_STATE)
  out <- lapply(seq_len(nrow(d)), function(i) {
    r <- tx_rts_type_one(d$awardee[i], f, cls$recipient_type[i])
    if (is.null(r)) {
      fb <- cls$rule[i] == "FALLBACK"
      r <- tibble::tibble(
        recipient_type = cls$recipient_type[i],
        basis_type = if (fb) NA_character_ else "STATE_SOURCE",
        determination_confidence = if (fb) "LOW" else rhtp_confidence_ceiling(cls$determination_confidence[i]),
        typing = if (fb) "FALLBACK" else "CLASSIFIER",
        why = if (fb) "The list states no form and no CMS TX Hospital, FQHC or RHC enrolment carries the string (§8's standing fallback, RECIPIENT_TYPE_INFERRED)."
              else paste0("No CMS TX enrolment carries the string; the form is read from the string itself (", cls$recipient_type_basis[i], ")."),
        ccn = NA_character_, enrolment = NA_character_)
    }
    r$classifier <- paste0(cls$recipient_type[i], "/", rhtp_confidence_ceiling(cls$determination_confidence[i]))
    r
  })
  t <- dplyr::bind_rows(out)
  hosp <- t$recipient_type == "HOSPITAL_OR_SYSTEM"
  ex <- d$contract_executed == "Yes"
  flag <- ifelse(ex, NA_character_, "AMOUNT_PRELIMINARY")
  flag <- ifelse(t$typing == "FALLBACK", ifelse(is.na(flag), "RECIPIENT_TYPE_INFERRED",
                                                paste0(flag, ";RECIPIENT_TYPE_INFERRED")), flag)
  tibble::tibble(
    state = TRT_STATE,
    row_no = seq_len(nrow(d)),
    awardee = d$awardee,
    amount = d$amount,
    recipient_type = t$recipient_type,
    distributed_to_hospital = ifelse(hosp, "Yes", "No"),
    note = paste0("Rural Texas Strong application line, ", TRT_INITIATIVES[d$initiative],
                  ". 'Intent to Award' as of 10/14/26; contract fully executed: ",
                  d$contract_executed, ". ", d$list_section, ". Total (multi-year) award $",
                  formatC(d$total_award_amount, format = "f", digits = 2, big.mark = ","), "."),
    recipient_confirmed = "Yes",
    amount_confirmed = ifelse(ex, "Yes", "No"),
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = TRT_TITLE,
    state_source_url = TRT_LIST_URL,
    validation_source_type = "NOTICE_OF_INTENT_TO_AWARD",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03ce_tx_rts_awardees.R",
    ccn = t$ccn,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    initiative = d$initiative,
    total_award_amount = d$total_award_amount,
    contract_executed = d$contract_executed,
    list_section = d$list_section,
    award_pool = paste0("Rural Texas Strong ", sub(":.*", "", TRT_INITIATIVES[d$initiative])),
    recipient_type_source = paste0("TYPED (session 103, ", t$typing, "): ", t$why,
                                   " Classifier said ", t$classifier, "."),
    cms_enrolment_record = t$enrolment,
    determination_confidence = rhtp_confidence_ceiling(t$determination_confidence, t$ccn),
    flag_reason = flag,
    budget_period = "Budget Period 1",
    flow_type = ifelse(hosp, "DIRECT", "NON_HOSPITAL"),
    hospital_benefiting = ifelse(hosp, "Yes", "Unclear"),
    hospital_attribution = ifelse(hosp, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = paste0("§10.2 ", ifelse(hosp, "DIRECT", "NON_HOSPITAL"), ": ", t$why,
                                 ifelse(hosp, " §0.3a: the recipient is a hospital whatever the activity.", "")),
    amount_basis = paste0("The line's 'Year 1 Subset' on HHSC's list, exact",
                          ifelse(ex, " (contract fully executed).",
                                 "; an INTENT, 'not considered awarded until a contract has been fully executed'."),
                          " The multi-year 'Total Award Amount' is in total_award_amount and is never added to amount."),
    basis_type = t$basis_type,
    announcement_date = TRT_ANNOUNCED,
    source_archive_path = TRT_SOURCES$file[TRT_SOURCES$key == "list"])
}

#' Every BP1 first-tier district corresponds to exactly one line: by its own
#' full name on the list, or by a bridge that cites it.
tx_rts_assert_bp1 <- function(a = tx_rts_awardees()) {
  bp1 <- readr::read_csv(here::here("data", "reference", "tx_bp1_first_tier_floor.csv"),
                         show_col_types = FALSE)$entity
  i1 <- a[a$initiative == "1" & abs(a$amount - TRT_ROUND1_Y1) < 0.005 &
            abs(a$total_award_amount - 3500000) < 0.005, ]
  if (nrow(i1) != 72L) stop("[TX RTS] Initiative 1 has ", nrow(i1), " $750,000 lines, not 72.", call. = FALSE)
  cited <- TX_RTS_BRIDGES$bp1[TX_RTS_BRIDGES$awardee %in% i1$awardee]
  cited <- c(cited, "Hardeman County Hospital District")   # not enrolled; still the BP1 name
  full  <- intersect(bp1, i1$awardee)
  got <- c(stats::na.omit(cited), full)
  if (!setequal(got, bp1) || anyDuplicated(got)) {
    stop("[TX RTS] the 33 BP1 districts no longer correspond one-to-one to the ",
         "Initiative 1 lines. Missing: ", paste(setdiff(bp1, got), collapse = "; "),
         ". Extra: ", paste(setdiff(got, bp1), collapse = "; "), call. = FALSE)
  }
  invisible(TRUE)
}

tx_rts_assert_typing <- function(a = tx_rts_awardees()) {
  h <- a[a$distributed_to_hospital == "Yes", ]
  if (any(h$recipient_type != "HOSPITAL_OR_SYSTEM") || any(h$flow_type != "DIRECT")) {
    stop("[TX RTS] a Yes row is not a DIRECT hospital row.", call. = FALSE)
  }
  dn <- a[a$awardee %in% TX_RTS_DISTRICTS_NOT_ENROLLED$awardee, ]
  if (nrow(dn) != 6L || any(dn$distributed_to_hospital != "No")) {
    stop("[TX RTS] the six lines of districts with no enrolment must stay NON_HOSPITAL.", call. = FALSE)
  }
  unused <- setdiff(TX_RTS_BRIDGES$awardee, a$awardee)
  if (length(unused)) stop("[TX RTS] bridges match no line: ", paste(unused, collapse = "; "), call. = FALSE)
  rhtp_assert_high_has_ccn(a, "TX RTS")
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "determination_confidence", "hospital_attribution", "basis_type")) {
    bad <- setdiff(stats::na.omit(unique(a[[col]])), rhtp_vocabulary(col))
    if (length(bad)) stop("[TX RTS] ", col, " outside §8: ", paste(bad, collapse = ", "), call. = FALSE)
  }
  fl <- unlist(strsplit(stats::na.omit(a$flag_reason), ";"))
  if (length(setdiff(fl, rhtp_vocabulary("flag_reason")))) stop("[TX RTS] flag_reason outside §8.", call. = FALSE)
  invisible(TRUE)
}

# -- fetch, validate, build -------------------------------------------------

tx_rts_fetch <- function() {
  dir.create(here::here(TRT_DIR), recursive = TRUE, showWarnings = FALSE)
  for (i in seq_len(nrow(TRT_SOURCES))) {
    s <- TRT_SOURCES[i, ]
    if (i > 1L) Sys.sleep(2)
    if (s$kind == "html") {
      rhtp_watch_archive(s$url, s$file, TRT_AGENT)
    } else {
      dest <- here::here(s$file)
      r <- httr::GET(s$url, httr::user_agent(TRT_AGENT), httr::timeout(90),
                     httr::write_disk(dest, overwrite = TRUE))
      stopifnot(httr::status_code(r) == 200L)
      cat(paste(digest::digest(file = dest, algo = "sha256"), basename(dest), s$url,
                paste0("last_modified=", httr::headers(r)[["last-modified"]]),
                format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), sep = "  "),
          "\n", file = here::here(TRT_DIR, "MANIFEST.txt"), append = TRUE, sep = "")
    }
  }
  message("[TX RTS] archived ", nrow(TRT_SOURCES), " sources under ", TRT_DIR)
}

tx_rts_validate <- function() {
  d <- tx_rts_read()
  tx_rts_assert_list(d)
  tx_rts_assert_reconciles(cur = d)
  tx_rts_assert_release()
  a <- tx_rts_awardees(d)
  tx_rts_assert_typing(a)
  tx_rts_assert_bp1(a)
  message("[TX RTS] all assertions pass.")
  invisible(a)
}

tx_rts_build <- function() {
  a <- tx_rts_validate()
  readr::write_csv(a, TRT_CSV, na = "")
  h <- a[a$distributed_to_hospital == "Yes", ]
  message(sprintf("[TX RTS] wrote %d lines, Year 1 $%s; %d named-hospital lines, $%s.",
                  nrow(a), format(sum(a$amount), nsmall = 2, big.mark = ","), nrow(h),
                  format(sum(h$amount), nsmall = 2, big.mark = ",")))
}

tx_rts_report <- function(a = tx_rts_awardees()) {
  money <- function(x) paste0("$", formatC(sum(x), format = "f", digits = 2, big.mark = ","))
  cat(sprintf("%d lines, Year 1 %s (executed %d / %s; intents %d / %s).\n",
              nrow(a), money(a$amount), sum(a$contract_executed == "Yes"),
              money(a$amount[a$contract_executed == "Yes"]),
              sum(a$contract_executed == "No"), money(a$amount[a$contract_executed == "No"])))
  ty <- sub("^TYPED \\(session 103, ([A-Z_-]+)\\).*", "\\1", a$recipient_type_source)
  print(a %>% dplyr::mutate(route = ty) %>%
          dplyr::group_by(route, distributed_to_hospital) %>%
          dplyr::summarise(rows = dplyr::n(), year1 = sum(amount), .groups = "drop"))
  h <- a[a$distributed_to_hospital == "Yes", ]
  cat(sprintf("NAMED_HOSPITAL %d rows / %s; of which LOW bridges %d / %s; with CCN %d.\n",
              nrow(h), money(h$amount), sum(h$determination_confidence == "LOW"),
              money(h$amount[h$determination_confidence == "LOW"]), sum(!is.na(h$ccn) & nzchar(h$ccn))))
}

# -- the watch, called from R/03n's probe ------------------------------------

#' Has HHSC linked a newer weekly list? Reads the live programme page into
#' memory (never data/evidence/, §2.2).
tx_rts_live_finding <- function(body = NULL) {
  if (is.null(body)) {
    r <- httr::GET(TRT_PROGRAMME_URL, httr::user_agent(TRT_AGENT), httr::timeout(60))
    if (httr::status_code(r) != 200L) {
      stop("[TX] HTTP ", httr::status_code(r), " from the RHTP programme page.", call. = FALSE)
    }
    body <- httr::content(r, as = "text", encoding = "UTF-8")
  }
  links <- unique(stringr::str_match_all(body, "href=\"([^\"]*list-award-recipients[^\"]*\\.xlsx)\"")[[1]][, 2])
  links <- sub("^https?://pfd\\.hhs\\.texas\\.gov", "", links)
  list(links = links,
       finding = if (!identical(links, TRT_LIST_PATH)) paste0(
         "RURAL TEXAS STRONG LIST: the programme page links ",
         if (length(links)) paste(links, collapse = ", ") else "NO award-recipient list",
         ", not the extracted ", basename(TRT_LIST_PATH),
         ". A new weekly list: update R/03ce's TRT_LIST_PATH, --fetch, --build, re-read the bridges.") else NULL)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) tx_rts_fetch()
  if ("--validate" %in% args) tx_rts_validate()
  if ("--build" %in% args) tx_rts_build()
  if ("--report" %in% args) tx_rts_report()
  if (!length(args)) message("Usage: --fetch | --validate | --build | --report")
}
