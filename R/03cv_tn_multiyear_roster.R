# 03cv_tn_multiyear_roster.R ----------------------------------------------------
#
# TENNESSEE'S "$422 MILLION ... 138 PROJECTS": A FIVE-YEAR ROSTER OF AMOUNTS
# "AWARDED OR REQUESTED", AND NOT A YEAR 1 FIGURE (session 118, owner ruling b).
#
# WHAT IT IS. TDH's release of 2026-11-09 ("Tennessee Announces $422 Million in
# Rural Health Transformation Grants for 138 Projects Statewide") says:
#
#   "RHTP funding to the 138 selected grantees will represent more than $422
#    million of total investment in rural health initiatives in Tennessee over
#    the next five years of the grant program's lifecycle."
#
# and its Project Grants page prints one table, "Grant Recipient | RHTP Priority
# Area and Project Name | Amount Awarded or Requested", ten priority-area
# subtotals and "Grand Total of Awarded Projects $422,241,081.71" -- about twice
# Tennessee's FY2026 allotment ($206,888,882).
#
# OWNER RULING (b), SESSION 118: FIVE-YEAR AWARDED-OR-REQUESTED TOTALS, NOT
# YEAR 1. The list is archived as a NON-AWARD MULTI-YEAR file, the shape of
# `nc_year1_budget_plan.csv`: never in STATE_FILES, no `amount` column (the
# figure is carried as the TEXT the state printed), and nothing here enters any
# Year 1 total. Each line is typed on CMS TN enrolment FOR REFERENCE only.
#
# THE YEAR 1 SPLIT WAS SEARCHED FOR AND IS NOT PUBLISHED (2026-11-16): neither
# the release, the Project Grants page (live copy read 2026-11-16, same grand
# total and column heading), nor the RHTP FAQ (which states BP1 at
# $206,888,882.11 and the spend-by dates) prices any line by budget period.
# Tennessee's only Year 1 per-recipient figures are its FFATA first-tier
# subaward filings, already applied through R/09b (`tn_fsrs_awardees.csv` and
# the FSRS overlay on `tn_year1_awardees.csv`) -- which is why some lines here
# (Cocke County HMA $643,500) equal an FSRS amount and most do not.
#
# WHAT RE-OPENS IT. A Tennessee source that prices a line for Budget Period 1
# makes that amount an award source; extract it then, into an award file.
#
# CLI:
#   Rscript R/03cv_tn_multiyear_roster.R --validate
#   Rscript R/03cv_tn_multiyear_roster.R --build
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(stringr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))
source(here::here("R", "utils_recipient_classification.R"))

TNM_DIR <- file.path("data", "evidence", "recheck", "2026-11-13", "TN")
TNM_ROSTER <- file.path(TNM_DIR, "2026-11-13_tn_rhtp_grants_awarded_projects_roster.html")
TNM_RELEASE <- file.path(TNM_DIR, "2026-11-13_tn_doh_422m_138_projects_release.html")
TNM_SHA <- c(
  roster  = "444fb776994f30e1a99fe7a56c6236b6c3235ed1bcbb1034ed9e171eaba1e833",
  release = "9e47b7d11a6de86a9495a8b74284b8e42dced6a3153841b5cf470339d5a86c3a")
TNM_URL <- "https://www.tn.gov/health/rural/grants"
TNM_RELEASE_URL <- paste0("https://www.tn.gov/health/news/2026/11/9/tennessee-announces--422-million-",
                          "in-rural-health-transformation-grants-for-138-projects-statewide.html")
TNM_OUT <- here::here("data", "reference", "tn_multiyear_awards_or_requests.csv")
TNM_N <- 138L
TNM_TOTAL_CENTS <- 42224108171     # $422,241,081.71
TNM_SECTIONS <- 10L
TNM_ALLOTMENT <- 206888882         # cms_fy2026_allotments.csv (§7.1)
TNM_SENTENCES <- c(
  five_years = "over the next five years of the grant program's lifecycle",
  heading = "Amount Awarded or Requested",
  grand_total = "Grand Total of Awarded Projects")
TNM_FED <- c(
  HOSPITAL = file.path("data", "evidence", "federal_records", "2026-09-23", "cms_hosp_enrollments_TN.json"),
  FQHC = file.path("data", "evidence", "federal_records", "2026-09-23", "cms_fqhc_enrollments_TN.json"),
  RHC = file.path("data", "evidence", "federal_records", "2026-09-23", "cms_rhc_enrollments_TN.json"))

tnm_sha <- function(p) digest::digest(file = here::here(p), algo = "sha256")

tnm_cents <- function(x) {
  if (any(!grepl("^\\$[0-9,]+\\.[0-9]{2}$", x))) {
    stop("[TN multi-year] an amount is not printed as $n.nn.", call. = FALSE)
  }
  as.numeric(gsub("[$,.]", "", x))
}

#' The table as printed: section rows (one cell spanned), project rows, and
#' subtotal rows. Returns the project rows with their priority area.
tnm_read <- function() {
  if (!identical(tnm_sha(TNM_ROSTER), TNM_SHA[["roster"]]) ||
      !identical(tnm_sha(TNM_RELEASE), TNM_SHA[["release"]])) {
    stop("[TN multi-year] an archived source's SHA-256 moved.", call. = FALSE)
  }
  tb <- rvest::html_table(xml2::read_html(here::here(TNM_ROSTER)))
  if (length(tb) != 1L) stop("[TN multi-year] expected one table.", call. = FALSE)
  t <- tb[[1]] %>% dplyr::mutate(dplyr::across(dplyr::everything(), stringr::str_squish))
  names(t) <- c("c1", "c2", "c3")
  if (!identical(unname(unlist(t[1, ])),
                 c("Grant Recipient", "RHTP Priority Area and Project Name", "Amount Awarded or Requested"))) {
    stop("[TN multi-year] the header row moved: ", paste(t[1, ], collapse = " | "), call. = FALSE)
  }
  t <- t[-1, ]
  sec <- t$c1 == t$c2 & t$c2 == t$c3
  tot <- t$c2 %in% c("Total", "Grand Total of Awarded Projects")
  area <- NA_character_; out <- list(); subt <- list()
  for (i in seq_len(nrow(t))) {
    if (sec[i]) { area <- t$c1[i]; next }
    if (tot[i]) { subt[[length(subt) + 1]] <- tibble::tibble(area = area, label = t$c2[i], text = t$c3[i]); next }
    out[[length(out) + 1]] <- tibble::tibble(priority_area = area, recipient = t$c1[i],
                                             project = t$c2[i], amount_text = t$c3[i])
  }
  d <- dplyr::bind_rows(out)
  attr(d, "subtotals") <- dplyr::bind_rows(subt)
  d
}

tnm_assert <- function() {
  d <- tnm_read()
  if (nrow(d) != TNM_N) stop("[TN multi-year] expected ", TNM_N, " project lines, read ", nrow(d), ".", call. = FALSE)
  s <- attr(d, "subtotals")
  sub <- s[s$label == "Total", ]
  if (nrow(sub) != TNM_SECTIONS) stop("[TN multi-year] expected ten priority-area subtotals.", call. = FALSE)
  per <- tapply(tnm_cents(d$amount_text), d$priority_area, sum)
  if (!all(abs(per[sub$area] - tnm_cents(sub$text)) < 0.5)) {
    stop("[TN multi-year] a priority area's lines do not sum to its printed subtotal.", call. = FALSE)
  }
  if (sum(tnm_cents(d$amount_text)) != TNM_TOTAL_CENTS ||
      tnm_cents(s$text[s$label == "Grand Total of Awarded Projects"]) != TNM_TOTAL_CENTS) {
    stop("[TN multi-year] the lines no longer sum to $422,241,081.71.", call. = FALSE)
  }
  # More than the allotment: this cannot be a Year 1 figure (§0.2's tier test, by value).
  if (TNM_TOTAL_CENTS / 100 <= TNM_ALLOTMENT) stop("[TN multi-year] total no longer exceeds the allotment.", call. = FALSE)
  t <- paste(rhtp_watch_reduce(here::here(TNM_RELEASE)), rhtp_watch_reduce(here::here(TNM_ROSTER)))
  t <- gsub("’", "'", t)
  for (k in names(TNM_SENTENCES)) {
    if (!grepl(TNM_SENTENCES[[k]], t, fixed = TRUE)) {
      stop("[TN multi-year] the '", k, "' sentence is gone from the archived sources.", call. = FALSE)
    }
  }
  if (grepl("Year 1|Year One|Budget Period 1", t)) {
    stop("[TN multi-year] a source now names Year 1 / Budget Period 1: read it for a Year 1 split.", call. = FALSE)
  }
  invisible(TRUE)
}

tnm_federal <- function() {
  purrr::imap_dfr(TNM_FED, function(f, k) {
    j <- jsonlite::fromJSON(here::here(f))
    tibble::tibble(kind = k, ccn = as.character(j$CCN),
                   org = j$`ORGANIZATION NAME`, dba = j$`DOING BUSINESS AS NAME`)
  })
}

#' Legal-name key: upper case, punctuation dropped, a trailing corporate suffix
#' dropped. Exact on that key only -- a prefix is never a match (§2).
tnm_key <- function(x) {
  k <- stringr::str_squish(toupper(gsub("[[:punct:]]", " ", x)))
  stringr::str_squish(sub(" (INC|INCORPORATED|LLC|LLLP|CORP|CORPORATION|PC|PLLC)$", "", k))
}

tnm_build <- function() {
  tnm_assert()
  d <- tnm_read()
  fed <- tnm_federal() %>% dplyr::filter(grepl("^[0-9]{2}[0-9A-Z][0-9]{3}$", ccn)) %>%
    dplyr::mutate(k_org = tnm_key(org), k_dba = tnm_key(dba))
  u <- unique(d$recipient)
  cls <- rhtp_classify_recipient_type(u, "TN") %>% dplyr::mutate(recipient = u)
  typ <- purrr::map_dfr(u, function(r) {
    k <- tnm_key(r)
    hit <- fed[fed$k_org == k | (!is.na(fed$k_dba) & fed$k_dba == k), ]
    kinds <- unique(hit$kind)
    c0 <- cls[cls$recipient == r, ]
    if ("HOSPITAL" %in% kinds) {
      ty <- "HOSPITAL_OR_SYSTEM"; bt <- "ORG_WEBSITE"
      why <- "CMS TN Hospital Enrollment carries the string as an ORGANIZATION NAME or DBA (corporate suffix aside)."
    } else if (length(kinds) && all(kinds %in% c("FQHC", "RHC"))) {
      ty <- "FQHC_OR_RHC"; bt <- "ORG_WEBSITE"
      why <- paste0("CMS TN ", paste(kinds, collapse = "/"), " Enrollment carries the string (corporate suffix aside).")
    } else {
      ty <- c0$recipient_type; bt <- if (identical(c0$rule, "FALLBACK")) "GENERAL_KNOWLEDGE" else "STATE_SOURCE"
      why <- paste0("No exact CMS TN enrolment; the §8 classifier on the name: ", c0$recipient_type_basis)
    }
    k1 <- if ("HOSPITAL" %in% kinds) "HOSPITAL" else if (length(kinds)) kinds[1] else NA_character_
    hk <- hit[hit$kind %in% k1, ]
    tibble::tibble(recipient = r, reference_recipient_type = ty, reference_basis_type = bt,
                   reference_confidence = rhtp_confidence_ceiling(if (bt == "GENERAL_KNOWLEDGE") "LOW" else "MEDIUM"),
                   cms_enrolment_kind = k1,
                   cms_enrolment_org = if (nrow(hk)) hk$org[1] else NA_character_,
                   cms_enrolment_ccns = if (nrow(hk)) paste(sort(unique(hk$ccn)), collapse = ";") else NA_character_,
                   reference_typing_note = why)
  })
  out <- d %>% dplyr::mutate(row_no = dplyr::row_number()) %>%
    dplyr::left_join(typ, by = "recipient") %>%
    dplyr::transmute(
      state = "TN", row_no, organization = recipient, priority_area, project,
      amount_awarded_or_requested_text = amount_text,
      amount_type = "FIVE_YEAR_AWARDED_OR_REQUESTED",
      year1_amount_published = "No",
      award_made = "Unclear",
      reference_recipient_type, reference_basis_type, reference_confidence,
      cms_enrolment_kind, cms_enrolment_org, cms_enrolment_ccns, reference_typing_note,
      note = paste(
        "NOT A YEAR 1 FIGURE (owner ruling b, session 118): TDH's 'Amount Awarded or Requested',",
        "a total 'over the next five years of the grant program's lifecycle'; the 138 lines sum to",
        "$422,241,081.71, about twice the FY2026 allotment. No Tennessee source gives a Year 1 split",
        "(searched 2026-11-16). Reference typing only; never in STATE_FILES; never in any Year 1 total."),
      budget_period = "1-5 (multi-year, not split)",
      source_document_title = "TDH, 2026 Awarded Projects of Tennessee's Rural Health Transformation Program",
      source_url = TNM_URL, source_release_url = TNM_RELEASE_URL,
      source_archive_path = TNM_ROSTER, basis_type = "STATE_SOURCE")
  stopifnot(nrow(out) == TNM_N, !any(c("amount", "round_amount", "hospital_attribution",
                                        "distributed_to_hospital") %in% names(out)),
            !any(is.na(out$reference_recipient_type)))
  readr::write_csv(out, TNM_OUT, na = "")
  message("[TN multi-year] wrote ", nrow(out), " FIVE-YEAR lines (NOT Year 1 awards) to ", basename(TNM_OUT))
  invisible(out)
}

#' Hospital-shaped reference lines, five-year -- a REPORT, never a figure.
tnm_report <- function(x = readr::read_csv(TNM_OUT, show_col_types = FALSE)) {
  h <- x[x$reference_recipient_type == "HOSPITAL_OR_SYSTEM", ]
  message(sprintf("[TN multi-year] hospital-typed lines (reference, five-year): %d / $%s",
                  nrow(h), formatC(sum(tnm_cents(h$amount_awarded_or_requested_text)) / 100,
                                   format = "f", digits = 2, big.mark = ",")))
  invisible(h)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) {
    tnm_assert(); message("[TN multi-year] all assertions pass.")
  } else if ("--build" %in% args) {
    tnm_build(); tnm_report()
  } else if ("--report" %in% args) {
    tnm_report()
  } else {
    message("Usage: Rscript R/03cv_tn_multiyear_roster.R [--validate | --build | --report]")
  }
}
