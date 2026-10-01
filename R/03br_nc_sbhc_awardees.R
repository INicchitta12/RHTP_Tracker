#!/usr/bin/env Rscript
# 03br_nc_sbhc_awardees.R -----------------------------------------------------
#
# NORTH CAROLINA'S THIRD ROSTER -- FIVE SCHOOL-BASED HEALTH CENTER AWARDEES,
# $1,250,000, AND NO PER-RECIPIENT SPLIT. Session 83.
#
# Governor Stein and NCDHHS's 2026-09-14 release: "$1.25 million in federal
# funding through the North Carolina Rural Health Transformation Program ...
# Five organizations will receive funding: the Appalachian District Health
# Department, Blue Ridge Community Health Services, First Health of the
# Carolinas, Mountain Community Health Partnership, and Wilson County Health
# Department." It then calls them "the awardees". Archived session 82 under
# data/evidence/recheck/2026-10-01/NC/ (MANIFEST.txt carries the SHA-256).
#
# THIS IS THE OPPORTUNITY NC'S STATUS TABLE HELD AS CLOSED_UNAWARDED.
# "Expanding School Health Centers to Rural Areas" -- "Up to $1,250,000 for up
# to five sites; applications due 2026-08-12" -- is the same pool, the same
# five-site ceiling, and the same pre-identified eligible class ("an active
# grant agreement with the NCDHHS Division of Child and Family Well-Being").
# R/03ah's status row now reads AWARDED_ROSTER_PUBLISHED and points here.
#
# POOL SHAPE: NO SPLIT IS INVENTED (§6.2). The $1,250,000 is the round's total
# and NCDHHS publishes no per-organisation figure. `amount` is EMPTY on all
# five rows and the pool sits in `round_amount`, repeated per row and never
# summed down the column -- the MIH round's device (R/03ah). Dividing it by
# five would publish $250,000 per awardee, a figure the state has not.
#
# A SEPARATE FILE, NOT FIVE ROWS APPENDED TO nc_year1_awardees.csv. That file
# carries session 49's overlay keyed on ROW INDEX and R/03bj's overlay, and
# R/03ah's --build rewrites it from source and wipes both; appending would
# mean a rebuild of a file whose 44 rows did not change. IN GROW's and AR
# round 2's precedent: a second file for a second roster, additive with the
# first.
#
# §0.3a, AND THE SETTING IS THE TRAP R/03ah's NOTE NAMED IN ADVANCE. The money
# funds school-based health centres. FirstHealth of the Carolinas -- the
# enrolled legal entity of FirstHealth Moore Regional Hospital (CCN 340115)
# and Montgomery Memorial (341303) -- is a HOSPITAL SYSTEM receiving it, so the
# row is HOSPITAL_OR_SYSTEM / DIRECT / Yes / NAMED_HOSPITAL at $0: READ THE ROW
# COUNT. The release prints "First Health" as two words against CMS's
# "FIRSTHEALTH", so the match is a hand-read bridge at LOW, not an exact one.
# The other four are two county/district health departments (the form is in
# the state's own string) and two FQHCs typed on CMS's NC FQHC enrolment file.
#
# §0.2: the release's footer prints $213,008,356.47, 100% CMS -- North
# Carolina's ALLOTMENT. Tier 1 on a Tier 3 announcement, R/03ah's finding
# again.
#
# Usage:
#   Rscript R/03br_nc_sbhc_awardees.R --validate
#   Rscript R/03br_nc_sbhc_awardees.R --build
#   Rscript R/03br_nc_sbhc_awardees.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

NCS_STATE     <- "NC"
NCS_POOL      <- 1250000                  # "$1.25 million"; "Up to $1,250,000"
NCS_N         <- 5L                       # "Five organizations will receive funding"
NCS_ALLOTMENT <- 213008356                # cms_fy2026_allotments.csv (§7.1)
NCS_NOA_DATE  <- as.Date("2025-12-29")
NCS_ANNOUNCED <- as.Date("2026-09-14")
NCS_URL <- paste0("https://www.ncdhhs.gov/news/press-releases/2026/09/14/",
                  "125-million-ncrhtp-funding-announced-expand-school-based-",
                  "health-centers-north-carolina")
NCS_ARCHIVE <- file.path("data", "evidence", "recheck", "2026-10-01", "NC",
                         "nc_ncdhhs_2026-09-14_sbhc_five_organisations.html")
NCS_SHA256  <- "0c53fb3a0ad52bc796aff63696d0dddc5a9eb2aa534cee04617507c1e1b830a6"
NCS_CSV     <- here::here("data", "reference", "nc_year1_sbhc_awardees.csv")
NCS_TITLE   <- paste0("$1.25 Million in NCRHTP Funding Announced to Expand ",
                      "School-Based Health Centers in North Carolina (2026-09-14)")
NCS_ROSTER_SENTENCE <- paste0(
  "Five organizations will receive funding: the Appalachian District Health ",
  "Department, Blue Ridge Community Health Services, First Health of the ",
  "Carolinas, Mountain Community Health Partnership, and Wilson County Health ",
  "Department.")
NCS_FED <- c(
  hosp = file.path("data", "evidence", "federal_records", "2026-09-25", "cms_hosp_enrollments_NC.json"),
  fqhc = file.path("data", "evidence", "federal_records", "2026-10-01", "cms_fqhc_enrollments_NC.json"),
  rhc  = file.path("data", "evidence", "federal_records", "2026-10-01", "cms_rhc_enrollments_NC.json"))

ncs_text <- function() {
  raw <- readr::read_file_raw(here::here(NCS_ARCHIVE))
  if (digest::digest(raw, algo = "sha256", serialize = FALSE) != NCS_SHA256) {
    stop("[NC SBHC] the archived release's SHA-256 does not match MANIFEST.txt.",
         call. = FALSE)
  }
  stringr::str_squish(gsub(" ", " ", xml2::xml_text(xml2::read_html(rawToChar(raw)))))
}

#' The five names, read out of the release's own roster sentence
ncs_parse <- function(t = ncs_text()) {
  if (!grepl(NCS_ROSTER_SENTENCE, t, fixed = TRUE)) {
    stop("[NC SBHC] the roster sentence is not in the archive verbatim.", call. = FALSE)
  }
  lst <- sub("^Five organizations will receive funding: the ", "", NCS_ROSTER_SENTENCE)
  lst <- sub("\\.$", "", lst)
  nm <- stringr::str_trim(strsplit(sub(", and ", ", ", lst, fixed = TRUE), ",", fixed = TRUE)[[1]])
  nm
}

ncs_assert_source <- function(t = ncs_text()) {
  nm <- ncs_parse(t)
  if (length(nm) != NCS_N || any(!nzchar(nm))) {
    stop("[NC SBHC] expected five names, read ", length(nm), ".", call. = FALSE)
  }
  checks <- c(
    pool = "announced $1.25 million in federal funding through the North Carolina Rural Health Transformation Program",
    awardees = "NCDHHS is ensuring the awardees receive funding quickly",
    class = "Each eligible applicant for this grant was required to have an active grant agreement with the NCDHHS Division of Child and Family Well-Being",
    footer = "as part of a financial assistance award totaling $213,008,356.47 with 100% funded by CMS/HHS")
  for (k in names(checks)) {
    if (!grepl(checks[[k]], t, fixed = TRUE)) {
      stop("[NC SBHC] the '", k, "' sentence is gone from the archive.", call. = FALSE)
    }
  }
  # No per-organisation figure: the only currency figures are the pool, the
  # Year 1 headline and the footer's allotment.
  cur <- unique(tolower(stringr::str_extract_all(
    t, stringr::regex("\\$[0-9][0-9,.]*( million| billion)?", ignore_case = TRUE))[[1]]))
  ok <- c("$1.25 million", "$213 million", "$213,008,356.47", "$50 billion")
  if (length(setdiff(cur, ok))) {
    stop("[NC SBHC] a currency figure the file does not account for: ",
         paste(setdiff(cur, ok), collapse = ", "),
         " -- a per-recipient amount? Then REWRITE the file.", call. = FALSE)
  }
  if (!isTRUE(rhtp_assert_footer_not_allotment(NCS_POOL, NCS_STATE, "SOLICITATION",
                                               label = "NC SBHC round"))) {
    stop("[NC SBHC] the §0.2 rule refuses the $1,250,000 pool.", call. = FALSE)
  }
  if (!(NCS_ANNOUNCED > NCS_NOA_DATE)) stop("[NC SBHC] §6.2 date test.", call. = FALSE)
  invisible(TRUE)
}

ncs_federal <- function() {
  rd <- function(f, k) {
    j <- jsonlite::fromJSON(here::here(f))
    tibble::tibble(kind = k, ccn = as.character(j$CCN), org = j$`ORGANIZATION NAME`,
                   dba = j$`DOING BUSINESS AS NAME`)
  }
  dplyr::bind_rows(rd(NCS_FED[["hosp"]], "HOSPITAL"), rd(NCS_FED[["fqhc"]], "FQHC"),
                   rd(NCS_FED[["rhc"]], "RHC"))
}

# Hand-read typing, one line per awardee, each checked against the archived
# federal files where it cites one.
NCS_TYPING <- tibble::tribble(
  ~awardee, ~recipient_type, ~basis_type, ~confidence, ~ccn, ~fed_kind, ~fed_org, ~why,
  "Appalachian District Health Department", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM", NA, NA, NA,
  "A district health department; the form is in the state's own string.",
  "Blue Ridge Community Health Services", "FQHC_OR_RHC", "ORG_WEBSITE", "MEDIUM", NA, "FQHC",
  "BLUE RIDGE COMMUNITY HEALTH SERVICES, INC.",
  "EXACT federal record: CMS NC FQHC Enrollment carries BLUE RIDGE COMMUNITY HEALTH SERVICES, INC. (Hendersonville and some twenty sites). Not a hospital: no NC hospital enrolment carries the string (BLUE RIDGE HEALTHCARE HOSPITALS INC and MH BLUE RIDGE MEDICAL CENTER, LLLP are different legal bodies).",
  "First Health of the Carolinas", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", NA, "HOSPITAL",
  "FIRSTHEALTH OF THE CAROLINAS INC",
  "HAND-READ BRIDGE: CMS NC Hospital Enrollment carries FIRSTHEALTH OF THE CAROLINAS INC as the legal entity of FIRSTHEALTH MOORE REGIONAL HOSPITAL (CCN 340115, Pinehurst) and FIRSTHEALTH MONTGOMERY MEMORIAL HOSPITAL (CCN 341303, Troy). The release prints 'First Health' as two words, so the string is not the enrolled name and the match is LOW, never machine-resolved (§2). One legal entity, two hospital CCNs: the row's ccn is left for Stage 5.",
  "Mountain Community Health Partnership", "FQHC_OR_RHC", "ORG_WEBSITE", "MEDIUM", NA, "FQHC",
  "MOUNTAIN COMMUNITY HEALTH PARTNERSHIP INCORPORATED",
  "EXACT federal record: CMS NC FQHC Enrollment carries MOUNTAIN COMMUNITY HEALTH PARTNERSHIP INCORPORATED (Bakersville, Burnsville, Spruce Pine).",
  "Wilson County Health Department", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM", NA, NA, NA,
  "A county health department; the form is in the state's own string."
)

ncs_assert_typing_sources <- function(f = ncs_federal()) {
  for (i in which(!is.na(NCS_TYPING$fed_kind))) {
    hit <- f[f$kind == NCS_TYPING$fed_kind[i] & f$org == NCS_TYPING$fed_org[i], ]
    if (!nrow(hit)) stop("[NC SBHC] the archived ", NCS_TYPING$fed_kind[i],
                         " file no longer carries ", NCS_TYPING$fed_org[i], ".",
                         call. = FALSE)
  }
  fh <- f[f$kind == "HOSPITAL" & f$org == "FIRSTHEALTH OF THE CAROLINAS INC" &
            grepl("^[0-9]{6}$", f$ccn), ]
  if (!setequal(fh$ccn, c("340115", "341303"))) {
    stop("[NC SBHC] FirstHealth's hospital CCNs moved: ", paste(fh$ccn, collapse = "/"),
         call. = FALSE)
  }
  invisible(TRUE)
}

ncs_awardees <- function(nm = ncs_parse()) {
  ty <- NCS_TYPING[match(nm, NCS_TYPING$awardee), ]
  if (any(is.na(ty$awardee))) {
    stop("[NC SBHC] no hand-read typing for: ", paste(nm[is.na(ty$awardee)], collapse = "; "),
         call. = FALSE)
  }
  hosp <- ty$recipient_type == "HOSPITAL_OR_SYSTEM"
  pool_note <- paste0(
    "Announced by Governor Stein and NCDHHS on 2026-09-14: '", NCS_ROSTER_SENTENCE,
    "' THE $1,250,000 IS A POOL FIGURE -- NCDHHS publishes no per-recipient amount, ",
    "so `amount` is empty and nothing is divided (§6.2). The award is stated ('the ",
    "awardees'), so the recipient is confirmed and the amount is not.")
  tibble::tibble(
    state = NCS_STATE,
    row_no = seq_along(nm),
    awardee = nm,
    amount = NA_real_,
    recipient_type = ty$recipient_type,
    distributed_to_hospital = ifelse(hosp, "Yes", "No"),
    note = pool_note,
    recipient_confirmed = "Yes",
    amount_confirmed = "No",
    fiscal_year = "2026",
    source_document_title = NCS_TITLE,
    state_source_url = NCS_URL,
    validation_source_type = "GOVERNOR_PRESS_RELEASE",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03br_nc_sbhc_awardees.R",
    ccn = ty$ccn,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    recipient_type_source = paste0("TYPED (session 83, HAND-READ): ", ty$why),
    determination_confidence = ty$confidence,
    flag_reason = "AMOUNT_MISSING",
    award_pool = "Expanding School Health Centers to Rural Areas",
    budget_period = "BP1 (2025-12-29 to 2026-10-30)",
    flow_type = ifelse(hosp, "DIRECT", "NON_HOSPITAL"),
    hospital_benefiting = ifelse(hosp, "Yes", "Unclear"),
    hospital_attribution = ifelse(hosp, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = paste0(
      "§10.2 ", ifelse(hosp, "DIRECT", "NON_HOSPITAL"), ": ", ty$why,
      ifelse(hosp,
             " §0.3a: the money funds a school-based health centre and the RECIPIENT is a hospital system -- Beebe Healthcare's case exactly. NAMED_HOSPITAL at $0: no per-recipient figure is published, so this row adds a named-hospital ROW and no dollar.",
             " §0.3a: judged on the recipient, not the school setting.")),
    amount_basis = paste0("North Carolina publishes NO per-recipient amount. The round's ",
                          "$1,250,000 is a POOL figure carried in `round_amount`, repeated on ",
                          "each of the five rows and never summed down the column."),
    round_name = "Expanding School Health Centers to Rural Areas",
    round_awards = NCS_N,
    round_amount = NCS_POOL,
    announcement_date = NCS_ANNOUNCED,
    source_archive_path = NCS_ARCHIVE,
    basis_type = ty$basis_type)
}

ncs_assert_rows <- function(a) {
  if (nrow(a) != NCS_N) stop("[NC SBHC] five rows.", call. = FALSE)
  if (any(!is.na(a$amount))) stop("[NC SBHC] an amount appeared; none is published.",
                                  call. = FALSE)
  if (sum(a$distributed_to_hospital == "Yes") != 1L ||
      a$awardee[a$distributed_to_hospital == "Yes"] != "First Health of the Carolinas") {
    stop("[NC SBHC] exactly one hospital row, FirstHealth (§0.3a).", call. = FALSE)
  }
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "determination_confidence", "hospital_attribution", "basis_type",
                "flag_reason")) {
    bad <- setdiff(stats::na.omit(unique(a[[col]])), rhtp_vocabulary(col))
    if (length(bad)) stop("[NC SBHC] ", col, " outside §8: ", paste(bad, collapse = ", "),
                          call. = FALSE)
  }
  if (!all(a$validation_source_type %in% rhtp_vocabulary("source_doc_type"))) {
    stop("[NC SBHC] validation_source_type outside §8's source_doc_type.", call. = FALSE)
  }
  invisible(TRUE)
}

ncs_validate <- function() {
  t <- ncs_text()
  ncs_assert_source(t)
  ncs_assert_typing_sources()
  a <- ncs_awardees(ncs_parse(t))
  ncs_assert_rows(a)
  message("[NC SBHC] all assertions pass.")
  invisible(a)
}

ncs_build <- function() {
  a <- ncs_validate()
  readr::write_csv(a, NCS_CSV, na = "")
  message("[NC SBHC] wrote ", nrow(a), " rows, amount EMPTY on every one; ",
          sum(a$distributed_to_hospital == "Yes"), " named-hospital row, $0.")
  invisible(a)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) ncs_validate()
  if ("--build" %in% args) ncs_build()
  if ("--report" %in% args) print(readr::read_csv(NCS_CSV, show_col_types = FALSE) %>%
                                    dplyr::select(awardee, recipient_type,
                                                  distributed_to_hospital,
                                                  determination_confidence, round_amount))
  if (!length(args)) message("Usage: --validate | --build | --report")
}
