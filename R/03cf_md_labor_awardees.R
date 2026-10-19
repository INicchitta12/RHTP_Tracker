#!/usr/bin/env Rscript
# 03cf_md_labor_awardees.R ---------------------------------------------------
#
# MARYLAND -- THE MD LABOR RHTP WORKFORCE ROSTER: 38 LINES, 34 ORGANISATIONS,
# $13,965,196. Session 104, on the owner's approval (MD_LABOR_ROSTER_UNRECONCILED).
#
# THE SOURCE. MD Labor's "Rural Health Transformation Program" page
# (labor.maryland.gov/employment/wdrhtp.shtml, archived 2026-10-16 by session
# 103) prints four tables -- Grantee | Award Amount | Jurisdictions Impacted |
# Occupations | Use of Funding -- under four headings:
#   Pathways to Health Careers: Rural Advancement for Maryland Peers - Allied Health   9 lines  $1,572,011
#   Pathways to Health Careers: Registered Apprenticeship Intermediaries               5 lines  $1,756,416
#   RISE: Advanced Provider Pathways                                                   13 lines $6,283,614
#   RISE: Talent Pipelines                                                             11 lines $4,353,155
#                                                                                      38 lines $13,965,196
# Each is a line, not an organisation: TidalHealth Peninsula Regional has three,
# Argentum and the Dwyer Workforce Development Center two each (§6.1 mode 4).
#
# "$16.4 MILLION" IS NOT THE AWARD TOTAL. The page says "In October 2026, MD
# Labor awarded a total of $16.4 million to 39 organizations", and the
# Governor's 2026-10-14 release headlines "$16.4 Million". MD Labor's policy
# issuance MPI 10-26 says what $16.4M is: "Of the $168 million awarded to
# Maryland, $20.1 million is subawarded from SORH to the Maryland Department of
# Labor ... through two distinct RHTP funding streams: the Immediate Impact Fund
# ($3,700,000); and Transformation Fund ($16,400,000)." It is the TRANSFORMATION
# FUND'S SIZE, a Tier 2 figure, and it is recorded here as that and never as an
# award. MPI 10-26 also says "With the RHTP Transformation Fund, MD Labor
# launched ... (RISE)", and the page calls Pathways "designed for immediate
# impact": RISE's 24 lines ($10,636,769) sit against the $16.4M Transformation
# Fund and Pathways' 14 lines ($3,328,427) against the $3.7M Immediate Impact
# Fund. The page prints 34 distinct organisations, not 39, and no 39th line is
# on it, in the release, the FAQ or the policy PDFs (session 103). The gap to
# $16.4M ($2,434,804) is unexplained and is NOT imputed to anybody.
#
# TIERS (§0.2). The page's footer prints $168,180,837.61 at 100 percent: the
# allotment (asserted STATE_ALLOTMENT). The flow is CMS -> MDH (SORH) -> MD
# Labor -> grantee; each line is a Tier 3 subaward from MD Labor.
#
# TYPING. Hospital rows are typed on CMS's MD Hospital Enrollment file
# (federal_records/2026-09-25/), never on the name:
#   EXACT  TidalHealth Peninsula Regional, Inc. (3 lines; 210019), CalvertHealth
#          Medical Center (210039), Frederick Health Hospital, Inc. (210005).
#          MEDIUM, CCN on the row.
#   LOW    University of Maryland Charles Regional Medical Center: enrolled as
#          CIVISTA MEDICAL CENTER INC (210035, La Plata), its former name
#          (general knowledge), CCN on the row. University of Maryland Shore
#          Regional Health and University of Maryland Upper Chesapeake Health:
#          system names whose enrolled hospitals are SHORE HEALTH SYSTEM INC
#          (210037) + CHESTER RIVER HOSPITAL CENTER (210030), and UPPER
#          CHESAPEAKE MEDICAL CENTER INC (210049 and 214022); system parents
#          (the Sanford/Avera footing), no CCN. Meritus Health Foundation:
#          §10.2's FOUNDATION rule -- its own name names its parent, Meritus
#          Health, whose hospital is MERITUS MEDICAL CENTER INC (210001); no CCN.
# CalvertHealth Medical Group is a physician group (PHYSICIAN_PRACTICE), not the
# hospital. Choptank Community Health System is an FQHC (verified on its website
# in session 49 for md_year1_awardees.csv), not a hospital, whatever its name
# reads. Everything else is §8's classifier or its standing fallback.
#
# §6.2: the awards are October 2026, after Maryland's 2025-12-29 NOA, and the
# page and MPI 10-26 state the provenance ("$20.1 million sub-awarded to MD
# Labor from a larger $168 million federal RHTP cooperative agreement").
#
# THE WATCH. R/03bg's NEWSROOM sweep runs md_labor_live_finding() inside its MD
# probe: it reads the live roster into memory and trips when any (table,
# grantee, amount) line differs from this file's archive.
#
# Usage:
#   Rscript R/03cf_md_labor_awardees.R --validate   # assertions, offline
#   Rscript R/03cf_md_labor_awardees.R --build      # write md_labor_awardees.csv
#   Rscript R/03cf_md_labor_awardees.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))
source(here::here("R", "utils_pdf_text.R"))

MDL_STATE     <- "MD"
MDL_DIR       <- file.path("data", "evidence", "recheck", "2026-10-16", "MD")
MDL_ARCHIVE   <- file.path(MDL_DIR, "2026-10-16_md_labor_wdrhtp_roster.html")
MDL_RELEASE   <- file.path(MDL_DIR, "2026-10-16_md_governor_release_2026-10-14_16_4m.html")
MDL_POLICY    <- file.path(MDL_DIR, "2026-10-16_md_labor_policy_mpi10-26_rise.pdf")
MDL_URL       <- "https://www.labor.maryland.gov/employment/wdrhtp.shtml"
MDL_AGENT     <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                        "+https://www.aha.org)")
MDL_ANNOUNCED <- as.Date("2026-10-14")
MDL_NOA_DATE  <- as.Date("2025-12-29")
MDL_FOOTER    <- 168180837.61
MDL_TOTAL     <- 13965196
MDL_TF_SIZE   <- 16400000     # Transformation Fund (MPI 10-26): Tier 2, never an award
MDL_IIF_SIZE  <- 3700000      # Immediate Impact Fund (MPI 10-26): Tier 2, never an award
MDL_CSV       <- here::here("data", "reference", "md_labor_awardees.csv")
MDL_HOSP_FED  <- file.path("data", "evidence", "federal_records", "2026-09-25",
                           "cms_hosp_enrollments_MD.json")
MDL_TITLE     <- "MD Labor, Rural Health Transformation Program - Division of Workforce Development and Adult Learning (Awardees)"

MDL_TABLES <- tibble::tribble(
  ~table, ~heading, ~fund, ~lines, ~sum,
  1L, "Pathways to Health Careers: Rural Advancement for Maryland Peers - Allied Health",
  "Immediate Impact Fund ($3,700,000, MPI 10-26)", 9L, 1572011,
  2L, "Pathways to Health Careers: Registered Apprenticeship Intermediaries",
  "Immediate Impact Fund ($3,700,000, MPI 10-26)", 5L, 1756416,
  3L, "Rural Incentives for Strengthening Employment in Healthcare (RISE): Advanced Provider Pathways",
  "Transformation Fund ($16,400,000, MPI 10-26)", 13L, 6283614,
  4L, "Rural Incentives for Strengthening Employment in Healthcare (RISE): Talent Pipelines",
  "Transformation Fund ($16,400,000, MPI 10-26)", 11L, 4353155)

# Hand-read typings. `ccn` only where the enrolled legal entity has one hospital
# CCN and the string names it. Everything not listed: the classifier.
MDL_TYPES <- tibble::tribble(
  ~awardee, ~recipient_type, ~basis_type, ~confidence, ~ccn, ~enrolment, ~why,
  "TidalHealth Peninsula Regional, Inc.", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "210019",
  "TIDALHEALTH PENINSULA REGIONAL INC (210019, Salisbury), PART A PROVIDER - HOSPITAL",
  "EXACT federal record: CMS MD Hospital Enrollments carry the awardee's legal name.",
  "CalvertHealth Medical Center", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "210039",
  "CALVERTHEALTH MEDICAL CENTER INC dba CALVERTHEALTH MEDICAL CENTER (210039, Prince Frederick), PART A PROVIDER - HOSPITAL",
  "EXACT federal record: CMS MD Hospital Enrollments carry the string as the enrolled DBA.",
  "Frederick Health Hospital, Inc.", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "210005",
  "FREDERICK HEALTH HOSPITAL INC (210005, Frederick), PART A PROVIDER - HOSPITAL",
  "EXACT federal record: CMS MD Hospital Enrollments carry the awardee's legal name.",
  "University of Maryland Charles Regional Medical Center", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", "210035",
  "CIVISTA MEDICAL CENTER INC (210035, La Plata), PART A PROVIDER - HOSPITAL",
  "HAND-READ BRIDGE: no MD enrolment carries the string; the one enrolled hospital in La Plata is CIVISTA MEDICAL CENTER INC, which is UM Charles Regional Medical Center under its former name (general knowledge, not on any document read). LOW.",
  "University of Maryland Shore Regional Health", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", NA,
  "SHORE HEALTH SYSTEM INC (210037, Easton); CHESTER RIVER HOSPITAL CENTER dba UNIVERSITY OF MARYLAND SHORE MEDICAL CENTER AT CHESTERTOWN (210030)",
  "SYSTEM PARENT (the Sanford/Avera footing): 'University of Maryland Shore Regional Health' is the UM Medical System's Eastern Shore hospital system (general knowledge), whose enrolled hospitals are the two legal entities recorded. The string names neither, so no CCN; LOW. md_year1_awardees.csv already types 'Chester River Health System Inc (UM Shore Regional)' a hospital.",
  "University of Maryland Upper Chesapeake Health", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", NA,
  "UPPER CHESAPEAKE MEDICAL CENTER INC dba UNIVERSITY OF MARYLAND UPPER CHESAPEAKE MEDICAL CENTER (210049, Bel Air; and 214022, Aberdeen)",
  "SYSTEM PARENT (the Sanford/Avera footing): 'University of Maryland Upper Chesapeake Health' is the UM Medical System's Harford/Cecil hospital system (general knowledge); its enrolled legal entity holds two hospital CCNs, so none is on the row; LOW.",
  "Meritus Health Foundation", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", NA,
  "MERITUS MEDICAL CENTER INC (210001, Hagerstown), the parent system's hospital",
  "§10.2 FOUNDATION RULE: a foundation whose own name names its parent health system (Meritus Health) is HOSPITAL_OR_SYSTEM and takes the DIRECT row. The foundation is not itself enrolled, so no CCN; the parent's hospital is recorded. LOW. The award funds simulation for Meritus School of Osteopathic Medicine students and the clinical workforce; §0.3a, the activity does not decide it.",
  "CalvertHealth Medical Group", "PHYSICIAN_PRACTICE", "STATE_SOURCE", "MEDIUM", NA, NA,
  "A medical group (the form is in the string): CalvertHealth's physician group, not the enrolled hospital CALVERTHEALTH MEDICAL CENTER INC, which has its own line. Not a hospital.",
  "Choptank Community Health System, Inc.", "FQHC_OR_RHC", "ORG_WEBSITE", "MEDIUM", NA, NA,
  "An FQHC: md_year1_awardees.csv's Choptank row was verified on www.choptankhealth.org (session 49, ORG_WEBSITE). 'Health System' in the name is not a hospital; no MD hospital enrolment carries it.",
  "Susquehanna Workforce Network, Inc.", "OTHER", "GENERAL_KNOWLEDGE", "LOW", NA, NA,
  "DETERMINED FORM: the local workforce development board for Cecil and Harford counties (general knowledge; the regional-workforce-board precedent, session 49). Not a hospital.")

mdl_raw <- function(path = MDL_ARCHIVE) readr::read_file(here::here(path))

#' One row per printed table line, from raw HTML (archive or live)
mdl_parse <- function(raw = mdl_raw()) {
  h <- xml2::read_html(raw)
  tabs <- rvest::html_elements(h, "table")
  out <- lapply(seq_along(tabs), function(i) {
    rows <- rvest::html_elements(tabs[[i]], "tr")
    cells <- lapply(rows, function(r) stringr::str_squish(rvest::html_text2(rvest::html_elements(r, "td, th"))))
    cells <- cells[vapply(cells, length, integer(1)) >= 2L]
    hdr <- cells[[1]]
    if (!identical(hdr[1:2], c("Grantee", "Award Amount"))) return(NULL)
    body <- cells[-1]
    tibble::tibble(table = i,
                   awardee = vapply(body, `[`, character(1), 1),
                   amount = as.numeric(gsub("[$,]", "", vapply(body, `[`, character(1), 2))),
                   jurisdictions = vapply(body, `[`, character(1), 3),
                   occupations = vapply(body, `[`, character(1), 4),
                   use_of_funding = vapply(body, `[`, character(1), 5))
  })
  d <- dplyr::bind_rows(out)
  if (!nrow(d)) return(d)
  d$table <- match(d$table, sort(unique(d$table)))
  d
}

mdl_text <- function(path) {
  t <- rvest::html_text2(xml2::read_html(here::here(path)))
  stringr::str_squish(gsub("’", "'", t, fixed = TRUE))
}

mdl_assert_source <- function(d = mdl_parse()) {
  if (nrow(d) != 38L || length(unique(d$awardee)) != 34L || anyNA(d$amount)) {
    stop("[MD Labor] the roster is no longer 38 priced lines / 34 organisations.", call. = FALSE)
  }
  if (abs(sum(d$amount) - MDL_TOTAL) > 0.005) {
    stop("[MD Labor] the 38 lines no longer sum to $13,965,196.", call. = FALSE)
  }
  by <- d %>% dplyr::group_by(table) %>% dplyr::summarise(n = dplyr::n(), s = sum(amount))
  if (!identical(by$n, MDL_TABLES$lines) || any(abs(by$s - MDL_TABLES$sum) > 0.005)) {
    stop("[MD Labor] a table's line count or sum moved.", call. = FALSE)
  }
  t <- mdl_text(MDL_ARCHIVE)
  need <- c(paste0(MDL_TABLES$heading, " Grantee"),
            "In October 2026, MD Labor awarded a total of $16.4 million to 39 organizations",
            "Pathways to Health Careers is designed for immediate impact")
  miss <- need[!vapply(need, function(s) grepl(s, t, fixed = TRUE), logical(1))]
  if (length(miss)) stop("[MD Labor] the page no longer says: ", paste(sQuote(miss), collapse = "; "), call. = FALSE)
  # §0.2: the footer prints the allotment.
  rhtp_assert_footer_text_tier(t, MDL_STATE, "STATE_ALLOTMENT", label = "MD Labor roster footer")
  # MPI 10-26: what $16.4M is.
  p <- stringr::str_squish(paste(rhtp_pdf_text(here::here(MDL_POLICY)), collapse = " "))
  if (!grepl("Immediate Impact Fund ($3,700,000); and Transformation Fund ($16,400,000)", p, fixed = TRUE) ||
      !grepl("With the RHTP Transformation Fund, MD Labor launched the Maryland RHTP: Rural Incentives for", p, fixed = TRUE)) {
    stop("[MD Labor] MPI 10-26 no longer names the two streams.", call. = FALSE)
  }
  # The $16.4M is a Tier 2 fund size: the roster sits under it, never equals it.
  rise <- sum(d$amount[d$table %in% 3:4]); path <- sum(d$amount[d$table %in% 1:2])
  if (!(rise < MDL_TF_SIZE && path < MDL_IIF_SIZE)) {
    stop("[MD Labor] a funding stream's awards now exceed its size: re-read MPI 10-26.", call. = FALSE)
  }
  if (!(MDL_ANNOUNCED > MDL_NOA_DATE)) stop("[MD Labor] §6.2 date test.", call. = FALSE)
  invisible(TRUE)
}

mdl_assert_federal <- function() {
  f <- jsonlite::fromJSON(here::here(MDL_HOSP_FED))
  for (cc in stats::na.omit(MDL_TYPES$ccn)) {
    if (!cc %in% f$CCN) stop("[MD Labor] CCN ", cc, " is not in the MD hospital file.", call. = FALSE)
  }
  ex <- c(`210019` = "TIDALHEALTH PENINSULA REGIONAL INC", `210005` = "FREDERICK HEALTH HOSPITAL INC",
          `210039` = "CALVERTHEALTH MEDICAL CENTER INC", `210035` = "CIVISTA MEDICAL CENTER INC")
  for (k in names(ex)) {
    if (!any(f$CCN == k & f$`ORGANIZATION NAME` == ex[[k]])) {
      stop("[MD Labor] ", k, " is no longer ", ex[[k]], ".", call. = FALSE)
    }
  }
  invisible(TRUE)
}

mdl_rows <- function(d = mdl_parse()) {
  cls <- rhtp_classify_recipient_type(d$awardee, MDL_STATE)
  ty <- MDL_TYPES[match(d$awardee, MDL_TYPES$awardee), ]
  hand <- !is.na(ty$awardee)
  fb <- !hand & cls$rule == "FALLBACK"
  if (any(!hand & cls$recipient_type == "HOSPITAL_OR_SYSTEM")) {
    stop("[MD Labor] the classifier calls ", paste(d$awardee[!hand & cls$recipient_type == "HOSPITAL_OR_SYSTEM"], collapse = "; "),
         " a hospital and no hand-read typing covers it. Read it.", call. = FALSE)
  }
  rt <- ifelse(hand, ty$recipient_type, cls$recipient_type)
  why <- ifelse(hand, ty$why, ifelse(fb,
    "The page states no form and no CMS MD hospital enrolment carries the name (§8's standing fallback, RECIPIENT_TYPE_INFERRED).",
    paste0("The form is read from the string itself (", cls$recipient_type_basis, "); no CMS MD hospital enrolment carries it.")))
  hosp <- rt == "HOSPITAL_OR_SYSTEM"
  tb <- MDL_TABLES[match(d$table, MDL_TABLES$table), ]
  conf <- ifelse(hand, ty$confidence, ifelse(fb, "LOW", rhtp_confidence_ceiling(cls$determination_confidence)))
  tibble::tibble(
    state = MDL_STATE,
    row_no = seq_len(nrow(d)),
    awardee = d$awardee,
    amount = d$amount,
    recipient_type = rt,
    distributed_to_hospital = ifelse(hosp, "Yes", "No"),
    note = paste0("MD Labor RHTP workforce award, '", tb$heading, "'. Jurisdictions: ",
                  d$jurisdictions, ". Occupations: ", d$occupations, "."),
    recipient_confirmed = "Yes",
    amount_confirmed = "Yes",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = MDL_TITLE,
    state_source_url = MDL_URL,
    validation_source_type = "AGENCY_PRESS_RELEASE",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03cf_md_labor_awardees.R",
    ccn = ifelse(hand, ty$ccn, NA_character_),
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    recipient_type_source = paste0("TYPED (session 104, ", ifelse(hand, "HAND-READ", ifelse(fb, "FALLBACK", "CLASSIFIER")),
                                   "): ", why),
    determination_confidence = rhtp_confidence_ceiling(conf, ifelse(hand, ty$ccn, NA_character_)),
    flag_reason = ifelse(fb, "RECIPIENT_TYPE_INFERRED", NA_character_),
    award_pool = paste0("MD Labor ", sub(":.*", "", tb$heading), " -- ", tb$fund),
    budget_period = "Budget Period 1",
    flow_type = ifelse(hosp, "DIRECT", "NON_HOSPITAL"),
    hospital_benefiting = ifelse(hosp, "Yes", "Unclear"),
    hospital_attribution = ifelse(hosp, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = paste0("§10.2 ", ifelse(hosp, "DIRECT", "NON_HOSPITAL"), ": ", why,
                                 ifelse(hosp, " §0.3a: the recipient is a hospital whatever the activity.", "")),
    amount_basis = paste0("The line's 'Award Amount' on MD Labor's page, exact. Subawarded by MD Labor from its ",
                          tb$fund, "; the fund's size is Tier 2 and never an award. The page's '$16.4 million to 39 ",
                          "organizations' is the Transformation Fund's size (MPI 10-26), not the roster's total ($13,965,196)."),
    basis_type = ifelse(hand, ty$basis_type, ifelse(fb, NA_character_, "STATE_SOURCE")),
    announcement_date = MDL_ANNOUNCED,
    source_archive_path = MDL_ARCHIVE,
    cms_enrolment_record = ifelse(hand & !is.na(ty$enrolment),
                                  paste0("CMS MD Hospital Enrollments: ", ty$enrolment, " (", MDL_HOSP_FED, ")"),
                                  NA_character_),
    use_of_funding = d$use_of_funding)
}

mdl_assert_rows <- function(a) {
  h <- a[a$distributed_to_hospital == "Yes", ]
  if (nrow(h) != 9L || abs(sum(h$amount) - 3574030) > 0.005) {
    stop("[MD Labor] hospital rows are no longer 9 / $3,574,030.", call. = FALSE)
  }
  if (any(h$recipient_type != "HOSPITAL_OR_SYSTEM") || any(h$flow_type != "DIRECT")) {
    stop("[MD Labor] a Yes row is not a DIRECT hospital row.", call. = FALSE)
  }
  rhtp_assert_high_has_ccn(a, "MD Labor")
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital", "determination_confidence",
                "hospital_attribution", "basis_type", "flag_reason", "hospital_benefiting")) {
    bad <- setdiff(stats::na.omit(unique(a[[col]])), rhtp_vocabulary(col))
    if (length(bad)) stop("[MD Labor] ", col, " outside §8: ", paste(bad, collapse = ", "), call. = FALSE)
  }
  if (!all(a$validation_source_type %in% rhtp_vocabulary("source_doc_type"))) {
    stop("[MD Labor] validation_source_type outside §8.", call. = FALSE)
  }
  unused <- setdiff(MDL_TYPES$awardee, a$awardee)
  if (length(unused)) stop("[MD Labor] hand typings match no line: ", paste(unused, collapse = "; "), call. = FALSE)
  invisible(TRUE)
}

#' The probe half, run from R/03bg's MD probe: the live roster's lines against
#' the archive's. Returns a finding string, or NULL. Reads into memory only.
md_labor_live_finding <- function(raw) {
  key <- function(d) paste(d$table, d$awardee, sprintf("%.2f", d$amount))
  live <- tryCatch(mdl_parse(raw), error = function(e) NULL)
  if (is.null(live) || !nrow(live)) {
    return("MD LABOR RHTP ROSTER: the live page yields no Grantee | Award Amount table. Read it (§0.4).")
  }
  arch <- mdl_parse()
  add <- setdiff(key(live), key(arch)); gone <- setdiff(key(arch), key(live))
  if (!length(add) && !length(gone)) return(NULL)
  paste0("MD LABOR RHTP ROSTER CHANGED: ", length(live$awardee), " lines live against 38 archived. ",
         if (length(add)) paste0("New: ", paste(add, collapse = "; "), ". ") else "",
         if (length(gone)) paste0("Gone: ", paste(gone, collapse = "; "), ". ") else "",
         "Re-archive the page after READING it, update R/03cf and --build.")
}

mdl_validate <- function() {
  d <- mdl_parse()
  mdl_assert_source(d)
  mdl_assert_federal()
  a <- mdl_rows(d)
  mdl_assert_rows(a)
  message("[MD Labor] all assertions pass: 38 lines, $13,965,196; 9 hospital lines, $3,574,030.")
  invisible(a)
}

mdl_build <- function() {
  a <- mdl_validate()
  readr::write_csv(a, MDL_CSV, na = "")
  message("[MD Labor] wrote ", nrow(a), " rows to ", MDL_CSV, ".")
  invisible(a)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) mdl_validate()
  if ("--build" %in% args) mdl_build()
  if ("--report" %in% args) print(as.data.frame(mdl_rows()[, c("awardee", "amount", "recipient_type", "distributed_to_hospital")]))
  if (!length(args)) message("Usage: --validate | --build | --report")
}
