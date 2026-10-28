#!/usr/bin/env Rscript
# 03ch_va_vhcf_productivity_awardees.R -----------------------------------------
#
# VIRGINIA -- VHCF'S PROVIDER PRODUCTIVITY ROUND: 23 PRICED AWARD LINES,
# $8,644,000, TYPED ON CMS'S VIRGINIA ENROLMENT FILES. Session 107.
#
# The Virginia Health Care Foundation's 2026-10-16 release ("VHCF Invests $8.6
# Million to Strengthen Rural Health Care Practices Across Virginia") "today
# announced 23 additional awards totaling $8.6 million" and calls them "the
# first grants through Virginia's Provider Productivity sub-initiative". It
# prints them under four category headings, as "<recipient> (<region>) :
# $<amount> to <purpose>", or with the recipient on its own line and two
# priced sub-lines (Buchanan General Hospital, Tri-Area Community Health). The
# 23 amounts sum to $8,644,000 (asserted), which the release rounds to "$8.6
# million". It was found by R/03bb's Routine: the 10-20 and 10-23 firings
# tripped on VHCF's dated anchor ("October 15, 2026, for Provider
# Productivity") going from /rural-health/, which now says VHCF "has awarded
# $23 million to 31 organizations" across the two rounds.
#
# EVERYTHING ABOUT ADMISSIBILITY, TIERS AND TYPING IS R/03bx's, AND IS SOURCED
# FROM IT, NOT RE-WRITTEN. VHCF is DMAS's designated administrator for this
# sub-initiative (§7, ICAHN's route); the CMS footer is Virginia's ALLOTMENT
# ($189,544,888, Tier 1; this release prints it without cents) and is not the
# round total (§0.2); a line is typed from an exact CMS VA Hospital, FQHC or RHC
# enrolment record, else from a hand-read decision, else §8's fallback.
# R/03bx's HVA_OVERRIDES carry over unchanged: Valley Health System, Ballad
# Health and Sentara Health are SYSTEM PARENTS (owner, session 93; LOW,
# GENERAL_KNOWLEDGE, no CCN, subtractable), and Monroe County Health Center and
# Virginia Community Healthcare Association keep their session-92 readings.
#
# HAND READS THIS ROUND ADDS (VA_PP_OVERRIDES below).
#   * "VCU Health, Community Memorial & Tappahannock Hospitals" ($1,000,000) is
#     CONNECTICUT'S SHAPE EXACTLY: a system and two SEPARATELY ENROLLED
#     hospitals -- COMMUNITY MEMORIAL HOSPITAL (CCN 490098, South Hill) and VCU
#     HEALTH TAPPAHANNOCK HOSPITAL (CCN 490084) -- at ONE figure. It is one
#     row, POOL_NAMED_HOSPITALS, MULTI_RECIPIENT_FIELD, never divided (§6.2),
#     on the Hartford HealthCare pair's footing (R/03au, session 54). LOW, not
#     CT's MEDIUM: "Tappahannock Hospitals" is a hand-read bridge, not the
#     enrolled string.
#   * "UVA Health" ($62,000) names the health system: a LOW hospital row with
#     recipient_subtype ACADEMIC_HEALTH_CENTER (owner ruling, session 110,
#     resolving AHC_STRING_NAMES_NO_ENROLLED_ENTITY). R/03bx's two UVA
#     programme strings stay NON_HOSPITAL under the same ruling.
#   * The four Community Services Boards: the release heads them "Community
#     Services Boards (CSBs)", which states the form: LOCAL_GOVT_OR_PUBLIC_HEALTH,
#     Western Tidewater CSB's reading (R/03bx).
#   * Old Dominion University Research Foundation: a university's research
#     foundation, UNIVERSITY_OR_AHC. Virginia Health Information: a statewide
#     health-data nonprofit (the release's heading), NONPROFIT_CBO.
#
# §6.2: announced 2026-10-16, after Virginia's 2025-12-29 NOA; RHTP provenance
# in the release's own words ("funded through the federal Rural Health
# Transformation Program").
#
# Usage:
#   Rscript R/03ch_va_vhcf_productivity_awardees.R --fetch     # archive the release
#   Rscript R/03ch_va_vhcf_productivity_awardees.R --validate  # assertions, offline
#   Rscript R/03ch_va_vhcf_productivity_awardees.R --build     # write the award file
#   Rscript R/03ch_va_vhcf_productivity_awardees.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})

source(here::here("R", "03bx_va_vhcf_awardees.R"))

VA_PP_ANNOUNCED <- as.Date("2026-10-16")
VA_PP_LINES     <- 23L
VA_PP_TOTAL     <- 8644000
VA_PP_URL <- paste0("https://www.vhcf.org/2026/10/16/vhcf-invests-8-6-million-",
                    "to-strengthen-rural-health-care-practices-across-virginia/")
VA_PP_FILE <- file.path(HVA_DIR, "2026-10-26_vhcf_release_2026-10-16_rht_productivity_awards.html")
VA_PP_CSV  <- here::here("data", "reference", "va_year1_vhcf_productivity_awardees.csv")
VA_PP_TITLE <- paste0("VHCF, 'VHCF Invests $8.6 Million to Strengthen Rural ",
                      "Health Care Practices Across Virginia' (2026-10-16)")
VA_PP_POOL  <- "VHCF Provider Productivity, first award round (Virginia RHTP)"
VA_PP_CATEGORIES <- c("Hospitals/Health Systems",
                      "Federally Qualified Health Centers (FQHCs)",
                      "Community Services Boards (CSBs)",
                      "Statewide Health Care Nonprofits and Universities")
VA_PP_PAIR <- "VCU Health, Community Memorial & Tappahannock Hospitals"

VA_PP_CSB_WHY <- paste0(
  "A Virginia community services board, the local public behavioral-health ",
  "authority: the release lists it under 'Community Services Boards (CSBs)', ",
  "which states the form (Western Tidewater CSB's reading, R/03bx).")
VA_PP_OVERRIDES <- tibble::tribble(
  ~awardee, ~recipient_type, ~basis_type, ~confidence, ~why,
  VA_PP_PAIR, "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW",
  paste0("TWO NAMED HOSPITALS, ONE FIGURE, NO SPLIT (Connecticut's Hartford ",
         "HealthCare pair, R/03au, session 54). CMS VA Hospital Enrollment: ",
         "COMMUNITY MEMORIAL HOSPITAL (CCN 490098, South Hill) and VCU HEALTH ",
         "TAPPAHANNOCK HOSPITAL (CCN 490084, Tappahannock), two separately ",
         "enrolled hospitals of the VCU Health system. The release prints one ",
         "$1,000,000; it is NOT divided (§6.2). POOL_NAMED_HOSPITALS. LOW: ",
         "'Tappahannock Hospitals' is a hand-read bridge to the enrolled string."),
  # The three system parents: R/03bx's readings, with its round-1 activity
  # sentences dropped (they describe the Interoperability awards, not these).
  "Valley Health System", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW",
  paste0(HVA_PARENT_NOTE, "WINCHESTER MEDICAL CENTER (490005), WARREN MEMORIAL HOSPITAL, INC. (490033), SHENANDOAH MEMORIAL HOSPITAL, INC. (CAH 491305) and PAGE MEMORIAL HOSPITAL INC (CAH 491307). Session 107 applies the same reading to this round's line."),
  "Ballad Health", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW",
  paste0(HVA_PARENT_NOTE, "MOUNTAIN STATES HEALTH ALLIANCE (490002 dba RUSSELL COUNTY HOSPITAL; CAH 491309 dba LEE COUNTY COMMUNITY HOSPITAL) and WELLMONT HEALTH SYSTEM (490114 dba LONESOME PINE HOSPITAL). This round's line funds an AI suite 'across its Southwest Virginia hospitals'."),
  "Sentara Health", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW",
  paste0(HVA_PARENT_NOTE, "SENTARA HOSPITALS (490007, 490044, 490046, 490057, 490066, 490093), SENTARA RMH MEDICAL CENTER (490004), SENTARA PRINCESS ANNE HOSPITAL (490119) and others. This round's line partners 'with rural practices': the recipient is the system, whatever the activity (§0.3a)."),
  "UVA Health", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW",
  paste0("OWNER RULING, SESSION 110 (AHC_STRING_NAMES_NO_ENROLLED_ENTITY): A ROW ",
         "NAMING THE HEALTH SYSTEM IS A HOSPITAL ROW. 'UVA Health' is the trading ",
         "name of the health system CMS enrols as RECTOR & VISITORS OF THE ",
         "UNIVERSITY OF VIRGINIA dba UVA HEALTH SCIENCES CENTER (CCN 490009). ",
         "HOSPITAL_OR_SYSTEM, recipient_subtype ACADEMIC_HEALTH_CENTER, LOW, ",
         "GENERAL_KNOWLEDGE, no CCN on the row (the string does not print the ",
         "enrolled legal entity). Subtractable by subtype and by basis_type."),
  "Horizon Behavioral Health", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM", VA_PP_CSB_WHY,
  "Middle Peninsula Northern Neck CSB", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM", VA_PP_CSB_WHY,
  "Piedmont Regional CSB", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM", VA_PP_CSB_WHY,
  "Southside Behavioral Health", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM", VA_PP_CSB_WHY,
  "Old Dominion University Research Foundation", "UNIVERSITY_OR_AHC", "STATE_SOURCE", "MEDIUM",
  paste0("A university's research foundation (stated in the string; the release ",
         "heads it 'Statewide Health Care Nonprofits and Universities'). Its award ",
         "serves 'three free clinic partner sites'. No hospital."),
  "Virginia Health Information", "NONPROFIT_CBO", "STATE_SOURCE", "MEDIUM",
  paste0("A statewide health-data nonprofit (the release's heading, 'Statewide ",
         "Health Care Nonprofits'); its award modernizes the Advanced Care ",
         "Planning Registry. Hospitals USE the registry and do not receive the money."))

va_pp_text <- function(src = here::here(VA_PP_FILE)) hva_text(src)

#' The 23 lines, each under the category heading that precedes it. A line
#' ending in ":" is a recipient whose priced sub-lines follow.
va_pp_parse <- function(l = va_pp_text()) {
  start <- which(l == VA_PP_CATEGORIES[1])
  stop_at <- which(l == "Virginia's Rural Health Transformation Program")
  if (length(start) != 1L || length(stop_at) < 1L) {
    stop("[VA VHCF PP] the roster block is not where it was: re-read the release (§0.4).",
         call. = FALSE)
  }
  blk <- l[start:(min(stop_at[stop_at > start]) - 1L)]
  out <- list(); cat_now <- NA_character_; held <- NULL
  for (x in blk) {
    if (x %in% VA_PP_CATEGORIES) { cat_now <- x; held <- NULL; next }
    m <- stringr::str_match(x, "^(.+?) \\(([^)]+)\\) ?: \\$([0-9,]+) to (.+)$")
    h <- stringr::str_match(x, "^(.+?) \\(([^)]+)\\) ?:$")
    s <- stringr::str_match(x, "^\\$([0-9,]+) to (.+)$")
    if (!is.na(m[1, 1])) {
      out[[length(out) + 1L]] <- tibble::tibble(category = cat_now, awardee = m[1, 2],
        site = stringr::str_squish(m[1, 3]), amount = as.numeric(gsub(",", "", m[1, 4])), purpose = m[1, 5])
      held <- NULL
    } else if (!is.na(h[1, 1])) {
      held <- h[1, ]
    } else if (!is.na(s[1, 1]) && !is.null(held)) {
      out[[length(out) + 1L]] <- tibble::tibble(category = cat_now, awardee = held[2],
        site = stringr::str_squish(held[3]), amount = as.numeric(gsub(",", "", s[1, 2])), purpose = s[1, 3])
    } else {
      stop("[VA VHCF PP] a line of no known shape: '", x, "'. Re-read the release.", call. = FALSE)
    }
  }
  dplyr::bind_rows(out)
}

va_pp_assert_roster <- function(d = va_pp_parse(), l = va_pp_text()) {
  if (nrow(d) != VA_PP_LINES) stop("[VA VHCF PP] ", nrow(d), " lines, not 23.", call. = FALSE)
  if (sum(d$amount) != VA_PP_TOTAL) {
    stop("[VA VHCF PP] the lines sum to $", format(sum(d$amount), big.mark = ","),
         ", not $8,644,000.", call. = FALSE)
  }
  t <- paste(l, collapse = " ")
  for (p in c(
    "today announced 23 additional awards totaling $8.6 million",
    "The new awards are the first grants through Virginia's Provider Productivity sub-initiative",
    "VHCF administers the Provider Productivity and Provider Interoperability sub-initiatives",
    "The awards are funded through the federal Rural Health Transformation Program")) {
    if (!grepl(p, t, fixed = TRUE)) {
      stop("[VA VHCF PP] the release no longer carries: ", p, call. = FALSE)
    }
  }
  # §0.2: the footer is the ALLOTMENT (printed here without cents) and is
  # refused as a round total.
  ft <- "as part of a financial assistance award totaling $189,544,888 with 100 percent funded by CMS/HHS"
  if (!grepl(ft, t, fixed = TRUE)) stop("[VA VHCF PP] the CMS footer moved.", call. = FALSE)
  rhtp_assert_footer_not_allotment(HVA_ALLOTMENT, HVA_STATE, "STATE_ALLOTMENT",
                                   label = "VA VHCF PP release footer")
  refused <- tryCatch({
    rhtp_assert_footer_not_allotment(HVA_ALLOTMENT, HVA_STATE, "SOLICITATION",
                                     label = "VA VHCF PP footer read as the round total")
    FALSE
  }, error = function(e) TRUE)
  if (!refused) stop("[VA VHCF PP] the §0.2 rule no longer refuses the footer.", call. = FALSE)
  if (!(VA_PP_ANNOUNCED > HVA_NOA_DATE)) stop("[VA VHCF PP] §6.2 date test.", call. = FALSE)
  invisible(TRUE)
}

va_pp_awardees <- function(d = va_pp_parse(), f = hva_federal()) {
  hva_assert_highland(f)
  cls <- rhtp_classify_recipient_type(d$awardee, HVA_STATE)
  ovs <- dplyr::bind_rows(VA_PP_OVERRIDES, HVA_OVERRIDES)
  out <- vector("list", nrow(d))
  for (i in seq_len(nrow(d))) {
    a <- d$awardee[i]
    ccn_i <- NA_character_
    ov <- ovs[ovs$awardee == a, ][1, ]
    hit <- hva_match(a, f)
    if (!is.na(ov$awardee)) {
      rt <- ov$recipient_type; bt <- ov$basis_type; cf <- ov$confidence
      why <- ov$why; how <- "HAND-READ"
    } else if (nrow(hit)) {
      k <- if ("HOSPITAL" %in% hit$kind) "HOSPITAL" else if ("FQHC" %in% hit$kind) "FQHC" else "RHC"
      hk <- hit[hit$kind == k, ]
      rt <- if (k == "HOSPITAL") "HOSPITAL_OR_SYSTEM" else "FQHC_OR_RHC"
      bt <- "ORG_WEBSITE"; cf <- "MEDIUM"; how <- "FEDERAL RECORD"
      six <- sort(unique(hk$ccn[grepl("^[0-9]{6}$", hk$ccn)]))
      if (k == "HOSPITAL" && length(six) == 1L) ccn_i <- six
      why <- paste0("EXACT federal record: CMS VA ",
                    c(HOSPITAL = "Hospital", FQHC = "FQHC", RHC = "RHC")[[k]],
                    " Enrollment carries this string as an ORGANIZATION NAME or DBA (",
                    paste(unique(hk$org), collapse = "; "), ") at CCN",
                    if (length(six) > 1L) "s " else " ", paste(six, collapse = "/"),
                    if (k == "HOSPITAL") paste0(", ", unique(hk$ptype[hk$ccn %in% six])[1]) else "", ".")
    } else if (cls$recipient_type[i] == "HOSPITAL_OR_SYSTEM") {
      stop("[VA VHCF PP] the classifier calls '", a, "' a hospital and no federal ",
           "record or hand-read decision covers it. Read it.", call. = FALSE)
    } else {
      rt <- "NONPROFIT_CBO"; bt <- NA_character_; cf <- "LOW"; how <- "FALLBACK"
      why <- "The release states no form and no CMS VA Hospital, FQHC or RHC enrolment carries the string (§8's standing fallback, RECIPIENT_TYPE_INFERRED)."
    }
    out[[i]] <- tibble::tibble(recipient_type = rt, basis_type = bt,
                               determination_confidence = cf, typing = how,
                               why = why, ccn = ccn_i,
                               classifier = paste0(cls$recipient_type[i], "/",
                                                   rhtp_confidence_ceiling(cls$determination_confidence[i])))
  }
  t <- dplyr::bind_rows(out)
  hosp <- t$recipient_type == "HOSPITAL_OR_SYSTEM"
  pair <- d$awardee == VA_PP_PAIR
  flag <- dplyr::case_when(t$typing == "FALLBACK" ~ "RECIPIENT_TYPE_INFERRED",
                           pair ~ "MULTI_RECIPIENT_FIELD",
                           TRUE ~ NA_character_)
  tibble::tibble(
    state = HVA_STATE,
    row_no = seq_len(nrow(d)),
    awardee = d$awardee,
    amount = d$amount,
    recipient_type = t$recipient_type,
    distributed_to_hospital = ifelse(hosp, "Yes", "No"),
    note = paste0("VHCF Provider Productivity award, announced 2026-10-16 (",
                  d$category, "): ", d$purpose, " REGION (not the recipient): ", d$site, "."),
    recipient_confirmed = "Yes",
    amount_confirmed = "Yes",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = VA_PP_TITLE,
    state_source_url = VA_PP_URL,
    validation_source_type = "AGENCY_PRESS_RELEASE",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03ch_va_vhcf_productivity_awardees.R",
    ccn = t$ccn,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    award_pool = VA_PP_POOL,
    category = d$category,
    site = d$site,
    recipient_type_source = paste0("TYPED (session 107, ", t$typing, "): ", t$why,
                                   " Classifier said ", t$classifier, "."),
    determination_confidence = rhtp_confidence_ceiling(t$determination_confidence),
    flag_reason = flag,
    budget_period = "Budget Period 1",
    flow_type = ifelse(hosp, "DIRECT", "NON_HOSPITAL"),
    hospital_benefiting = ifelse(hosp | d$awardee == "Virginia Health Information", "Yes", "Unclear"),
    hospital_attribution = dplyr::case_when(pair ~ "POOL_NAMED_HOSPITALS",
                                            hosp ~ "NAMED_HOSPITAL",
                                            TRUE ~ "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = paste0("§10.2 ", ifelse(hosp, "DIRECT", "NON_HOSPITAL"), ": ", t$why,
                                 ifelse(hosp, " §0.3a: the recipient is a hospital or health system whatever the activity.", "")),
    amount_basis = paste0("The line's own amount in VHCF's release, exact. The 23 lines sum ",
                          "to $8,644,000, the release's '$8.6 million'. The release's CMS ",
                          "footer ($189,544,888) is Virginia's ALLOTMENT, Tier 1, and is ",
                          "not this round's total (§0.2)."),
    basis_type = t$basis_type,
    recipient_subtype = ifelse(d$awardee == "UVA Health", "ACADEMIC_HEALTH_CENTER", NA_character_),
    round_amount = VA_PP_TOTAL,
    announcement_date = VA_PP_ANNOUNCED,
    source_archive_path = VA_PP_FILE)
}

va_pp_assert_typing <- function(a = va_pp_awardees()) {
  h <- a[a$distributed_to_hospital == "Yes", ]
  if (any(h$recipient_type != "HOSPITAL_OR_SYSTEM") || any(h$flow_type != "DIRECT")) {
    stop("[VA VHCF PP] a Yes row is not a DIRECT hospital row.", call. = FALSE)
  }
  if (any(a$determination_confidence == "HIGH")) stop("[VA VHCF PP] HIGH without Stage 5 (§7).", call. = FALSE)
  pr <- a[a$hospital_attribution == "POOL_NAMED_HOSPITALS", ]
  if (nrow(pr) != 1L || pr$awardee != VA_PP_PAIR || pr$amount != 1000000) {
    stop("[VA VHCF PP] the VCU pair must be the one POOL_NAMED row, $1,000,000, undivided.", call. = FALSE)
  }
  uva <- a[a$awardee == "UVA Health", ]
  if (nrow(uva) != 1L || uva$hospital_attribution != "NAMED_HOSPITAL" ||
      !identical(uva$recipient_subtype, "ACADEMIC_HEALTH_CENTER") ||
      uva$determination_confidence != "LOW") {
    stop("[VA VHCF PP] 'UVA Health' must be a LOW NAMED_HOSPITAL row with ",
         "recipient_subtype ACADEMIC_HEALTH_CENTER (owner ruling, session 110).", call. = FALSE)
  }
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "determination_confidence", "hospital_attribution", "basis_type")) {
    bad <- setdiff(stats::na.omit(unique(a[[col]])), rhtp_vocabulary(col))
    if (length(bad)) stop("[VA VHCF PP] ", col, " outside §8: ", paste(bad, collapse = ", "), call. = FALSE)
  }
  fl <- unlist(strsplit(stats::na.omit(a$flag_reason), ";", fixed = TRUE))
  if (length(setdiff(fl, rhtp_vocabulary("flag_reason")))) stop("[VA VHCF PP] flag_reason outside §8.", call. = FALSE)
  invisible(TRUE)
}

va_pp_fetch <- function() {
  rhtp_watch_archive(VA_PP_URL, VA_PP_FILE, HVA_AGENT)
  message("[VA VHCF PP] archived the release to ", VA_PP_FILE)
}

va_pp_validate <- function() {
  l <- va_pp_text()
  d <- va_pp_parse(l)
  va_pp_assert_roster(d, l)
  a <- va_pp_awardees(d)
  va_pp_assert_typing(a)
  message("[VA VHCF PP] all assertions pass.")
  invisible(a)
}

va_pp_build <- function() {
  a <- va_pp_validate()
  readr::write_csv(a, VA_PP_CSV, na = "")
  h <- a[a$hospital_attribution == "NAMED_HOSPITAL", ]
  message(sprintf("[VA VHCF PP] wrote %d award lines, $%s; %d NAMED_HOSPITAL lines, $%s; POOL_NAMED $1,000,000.",
                  nrow(a), format(sum(a$amount), big.mark = ","), nrow(h),
                  format(sum(h$amount), big.mark = ",")))
}

va_pp_report <- function() {
  a <- va_pp_awardees()
  print(a %>% dplyr::select(awardee, amount, recipient_type, hospital_attribution,
                            determination_confidence, basis_type, ccn), n = 30)
  h <- a[a$hospital_attribution == "NAMED_HOSPITAL", ]
  gk <- h$basis_type %in% "GENERAL_KNOWLEDGE"
  cat(sprintf(paste0("\n%d lines, $%s. NAMED_HOSPITAL %d lines, $%s; POOL_NAMED 1 / $1,000,000.\n",
                     "  system parents (GENERAL_KNOWLEDGE, LOW, subtractable): %d lines, $%s\n"),
              nrow(a), format(sum(a$amount), big.mark = ","), nrow(h),
              format(sum(h$amount), big.mark = ","), sum(gk), format(sum(h$amount[gk]), big.mark = ",", scientific = FALSE)))
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) va_pp_fetch()
  if ("--validate" %in% args) va_pp_validate()
  if ("--build" %in% args) va_pp_build()
  if ("--report" %in% args) va_pp_report()
  if (!length(args)) message("Usage: --fetch | --validate | --build | --report")
}
