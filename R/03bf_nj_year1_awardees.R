#!/usr/bin/env Rscript
# 03bf_nj_year1_awardees.R ---------------------------------------------------
#
# NEW JERSEY -- 103 PRICED AWARDS, $83,060,837, SIX GRANT CATEGORIES, AND THE
# STATE THAT PUBLISHED ONLY THROUGH NEWSROOMS.
#
# Governor Sherrill announced "the first round of grant awards through New
# Jersey's Rural Health Transformation Program (NJRHT), investing $83 million"
# on 2026-07-31: "Today's awards represent the first year of investments that
# will fund 103 projects. A summary of grant awards can be found here." DOH's
# own copy of the release links that summary directly --
# njrht-funding-allocations-2026.pdf, "Rural Health Transformation Program
# Funding Allocations -- July 31, 2026", 13 pages, six sections, columns
# Applicant Name | Award Amount | Activities. It prints NO TOTAL. The 103 rows
# sum to $83,060,837, which the release's "$83 million" and "103 projects"
# corroborate from outside the arithmetic (South Carolina's footing). Nothing
# here saw it for 55 days: no CMS release, no probe, not linked from the
# programme page, and RCJ held none of it at the 08-27 pull (session 60).
#
# THE HOSPITAL ROWS ARE TYPED ON CMS'S OWN ENROLMENT FILES, NOT ON NAMES. The
# NJ Hospital and FQHC Enrollment files are archived under
# data/evidence/federal_records/2026-09-24/. A recipient string that equals an
# ORGANIZATION NAME or DBA there -- after case, punctuation, a leading "THE"
# and a trailing "INC" are set aside, and nothing else -- is typed from that
# record at ORG_WEBSITE/MEDIUM (session 50's footing). That settles 11 of the
# 12 hospital organisations and ONE THAT A NAME READING GETS WRONG:
#
#   * "AtlantiCare Health Services, Inc." ($1,946,655, two rows) is NOT the
#     hospital. CMS carries it under THREE FQHC CCNs (311872, 311949, 311008),
#     and the hospital is AtlantiCare Regional Medical Center (CCN 310064).
#     Vermont's Gifford Health Care shape (session 54). Session 60's "~37
#     hospital rows" counted these two; the federal record makes it 35.
#   * "Virtua Health Inc." (five rows, $3,150,255) is the ONE HAND-READ
#     BRIDGE: CMS enrols Virtua's hospitals under four subsidiaries, every one
#     named "VIRTUA ...", and none under the parent's name. HOSPITAL_OR_SYSTEM
#     (a health system is §8's system half) at GENERAL_KNOWLEDGE/LOW, named so
#     a reader can subtract it.
#
# §0.3a: CODE THE RECIPIENT, AND THE AWARDEE FIELD IS NOT ALWAYS ONLY THE
# AWARDEE. Building Rural Hospital Capacity prints the SITE in brackets at the
# head of the Activities cell -- AHS Hospital Corp. [Hackettstown Medical
# Center] and [Newton Medical Center]; AtlantiCare Regional Medical Center [City
# Campus] and [Mainland Campus]; Inspira Medical Centers, Inc. [Elmer],
# [Mannington], [Vineland]. The recipient is the corporation and the site goes
# in `site`; each bracketed row is its OWN award action and is not merged. And
# every hospital row is DIRECT whatever the activity -- a Mobile Integrated
# Health programme, a doula service, a CHW team -- because Beebe's school-based
# health centre is the worked example (§0.3a, §10.2).
#
# §10.2's ASSOCIATION ROW: "Health Research and Educational Trust of NJ/NJHA"
# ($898,854) is the state hospital association's research affiliate, and its
# activity is "streamlining real-time clinical decision support systems and
# tools in rural hospitals" -- tools reach hospitals, dollars do not (Georgia's
# GHA carts): IN_KIND_BENEFIT, No, hospital_benefiting = Yes.
#
# §6.2: the release's own sentence ties the awards to RHTP, the date test
# passes (2026-07-31 against the 2025-12-29 NOA), and NEITHER the PDF nor any
# release carries a CMS financial-assistance footer -- "Centers for Medicare",
# "financial assistance" and "CMS" occur ZERO times in the roster (Arkansas's
# and South Carolina's shape). The provenance is the Governor's sentence plus
# DOH linking the PDF as the summary of those awards.
#
# A PARTIAL YEAR, SAID BY NEW JERSEY: DOH administers "approximately $95
# million in competitive grant funding" and this is "the first round". About
# $12M of DOH's competitive money, and all of DHS's lead-agency share, is in
# no public roster.
#
# Usage:
#   Rscript R/03bf_nj_year1_awardees.R --validate  # assertions, offline
#   Rscript R/03bf_nj_year1_awardees.R --build     # writes the three NJ CSVs
#   Rscript R/03bf_nj_year1_awardees.R --fetch     # archive the probe baselines
#   Rscript R/03bf_nj_year1_awardees.R --probe     # LIVE, READ-ONLY
#   Rscript R/03bf_nj_year1_awardees.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_pdf_text.R"))
source(here::here("R", "utils_recipient_classification.R"))
source(here::here("R", "utils_page_watch.R"))

NJ_STATE     <- "NJ"
NJ_ALLOTMENT <- 147250806            # cms_fy2026_allotments.csv (§7.1)
NJ_NOA_DATE  <- as.Date("2025-12-29")
NJ_ANNOUNCED <- as.Date("2026-07-31")
NJ_TOTAL     <- 83060837
NJ_RECHECK   <- file.path("data", "evidence", "recheck", "2026-09-24", "NJ")
NJ_PDF       <- file.path(NJ_RECHECK, "njrht_funding_allocations_2026-07-31.pdf")
NJ_GOV       <- file.path(NJ_RECHECK, "governor_release_2026-07-31_first_round_awards.html")
NJ_DOH       <- file.path(NJ_RECHECK, "doh_release_2026-07-31_icymi_first_round_awards.html")
NJ_DERIVED   <- file.path(NJ_RECHECK, "DERIVED_njrht_allocations_parsed_rows.csv")
NJ_FEDERAL   <- file.path("data", "evidence", "federal_records", "2026-09-24")
NJ_DIR       <- file.path("data", "evidence", "NJ")
NJ_PDF_URL   <- "https://nj.gov/rural-health-transformation/documents/njrht-funding-allocations-2026.pdf"
NJ_CSV        <- here::here("data", "reference", "nj_year1_awardees.csv")
NJ_STATUS_CSV <- here::here("data", "reference", "nj_year1_status.csv")
NJ_DISPO_CSV  <- here::here("data", "reference", "nj_rcj_candidate_disposition.csv")
NJ_USER_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                        "+https://www.aha.org)")

NJ_SECTIONS <- c(
  "Advancing Access to Care, EMS, and Dispatch Capability in Rural New Jersey" = 7L,
  "Advancing Technology, Prevention, and Workforce Capacity in Rural New Jersey" = 54L,
  "Building Rural Hospital Capacity" = 13L,
  "Community Health Workers in Rural New Jersey" = 8L,
  "Doula Integration in Rural New Jersey" = 5L,
  "Improving Chronic Disease Outcomes" = 16L)

# -- the roster ------------------------------------------------------------

#' Parse the PDF on the LINE model. Names are painted in the left column
#' (x < 50), the amount on its own line (or at the end of a one-line name),
#' and activities to the right. Rows are ANCHORED ON THE AMOUNT (South
#' Carolina's lesson): a name is whatever the left column accumulated since
#' the previous amount. Section headings are matched against the six known
#' titles, so a seventh fails the section-count assertion rather than being
#' read as a recipient.
nj_parse_roster <- function(path = here::here(NJ_PDF)) {
  l <- rhtp_pdf_lines(path)
  l$text <- stringr::str_squish(l$text)
  starts <- substr(names(NJ_SECTIONS), 1, 20)
  rows <- list(); sec <- NA_character_; head_buf <- NULL
  name_buf <- character(); cur <- 0L
  for (i in seq_len(nrow(l))) {
    t <- l$text[i]; x <- l$x[i]
    if (!nzchar(t) || grepl("^[0-9]+$", t)) next
    if (t %in% c("Rural Health Transformation Program",
                 "Funding Allocations – July 31, 2026")) next
    if (!is.null(head_buf)) {
      if (t == "Grant information") {
        sec <- paste(head_buf, collapse = " "); head_buf <- NULL
      } else head_buf <- c(head_buf, t)
      next
    }
    if (any(startsWith(t, starts))) { head_buf <- t; next }
    if (grepl("^Applicant Name Award Amount Activit", t)) next
    if (x < 50 || grepl("^\\$[0-9,]+$", t)) {
      m <- stringr::str_match(t, "^(.*?)\\s*\\$([0-9,]+)$")
      if (!is.na(m[1, 1])) {
        if (nzchar(m[1, 2])) name_buf <- c(name_buf, m[1, 2])
        cur <- cur + 1L
        rows[[cur]] <- list(section = sec,
                            awardee = paste(name_buf, collapse = " "),
                            amount = as.numeric(gsub(",", "", m[1, 3])),
                            activity = character())
        name_buf <- character()
      } else {
        name_buf <- c(name_buf, t)
      }
    } else {
      if (cur == 0L) stop("[NJ] an Activities line precedes the first award.",
                          call. = FALSE)
      rows[[cur]]$activity <- c(rows[[cur]]$activity, t)
    }
  }
  if (length(name_buf)) {
    stop("[NJ] a name with no amount at the end of the roster: ",
         paste(name_buf, collapse = " "), call. = FALSE)
  }
  d <- dplyr::bind_rows(lapply(rows, function(r) tibble::tibble(
    section = r$section, awardee = r$awardee, amount = r$amount,
    activity = paste(r$activity, collapse = " "))))
  d$site <- stringr::str_match(d$activity, "^\\[([^]]+)\\]")[, 2]
  d
}

# -- assertions ------------------------------------------------------------

nj_assert_roster <- function(d = nj_parse_roster()) {
  if (nrow(d) != 103L) {
    stop("[NJ] the roster parses to ", nrow(d), " rows, not the release's 103 ",
         "projects.", call. = FALSE)
  }
  if (abs(sum(d$amount) - NJ_TOTAL) > 0.005) {
    stop("[NJ] the roster sums to $", format(sum(d$amount), big.mark = ","),
         ", not $83,060,837. The PDF prints no total; this figure is the ",
         "session-60 parse, corroborated by the release's '$83 million'.",
         call. = FALSE)
  }
  n <- table(factor(d$section, levels = names(NJ_SECTIONS)))
  if (anyNA(d$section) || !identical(as.integer(n), unname(NJ_SECTIONS))) {
    stop("[NJ] the section counts are ", paste(n, collapse = "/"),
         "; expected ", paste(NJ_SECTIONS, collapse = "/"), ".", call. = FALSE)
  }
  if (any(!nzchar(d$awardee)) || any(!nzchar(d$activity))) {
    stop("[NJ] a row has an empty name or activity.", call. = FALSE)
  }
  sites <- stats::na.omit(d$site)
  if (!setequal(sites, c("Hackettstown Medical Center", "Newton Medical Center",
                         "City Campus", "Mainland Campus", "Elmer",
                         "Mannington", "Vineland"))) {
    stop("[NJ] the bracketed sites are now ", paste(sites, collapse = ", "),
         ". Read them: §0.3a's awardee-field corollary.", call. = FALSE)
  }
  # The parse must agree with session 60's committed DERIVED rows, which were
  # read independently of this function. Two readings of one PDF.
  dv <- utils::read.csv(here::here(NJ_DERIVED), comment.char = "#",
                        stringsAsFactors = FALSE)
  if (!identical(dv$applicant_name, d$awardee) ||
      !isTRUE(all.equal(as.numeric(dv$award_amount), d$amount))) {
    stop("[NJ] this parse and session 60's DERIVED rows disagree.", call. = FALSE)
  }
  pdf_text <- paste(rhtp_pdf_lines(here::here(NJ_PDF))$text, collapse = " ")
  for (p in c("Centers for Medicare", "financial assistance", "CMS", "Total")) {
    if (grepl(p, pdf_text, fixed = TRUE)) {
      stop("[NJ] the roster now contains '", p, "'. It carried none on ",
           "2026-09-24; re-read it (a total or a footer changes what this ",
           "file can claim).", call. = FALSE)
    }
  }
  invisible(TRUE)
}

nj_assert_releases <- function() {
  g <- rhtp_watch_reduce(here::here(NJ_GOV))
  rhtp_watch_require(g, c(
    "announced the first round of grant awards through New Jersey's Rural Health Transformation Program (NJRHT), investing $83 million",
    "Today's awards represent the first year of investments that will fund 103 projects",
    "the Department of Health administering approximately $95 million in competitive grant funding",
    "New Jersey received more than $147 million from the Centers for Medicare & Medicaid Services (CMS)"),
    NJ_STATE, "the Governor's 2026-07-31 release")
  raw <- paste(readLines(here::here(NJ_DOH), warn = FALSE), collapse = "\n")
  if (!grepl("njrht-funding-allocations-2026.pdf", raw, fixed = TRUE)) {
    stop("[NJ] DOH's copy of the release no longer links the allocations ",
         "PDF; that link is what makes the PDF the summary of these awards.",
         call. = FALSE)
  }
  if (!(NJ_ANNOUNCED > NJ_NOA_DATE)) stop("[NJ] date test.", call. = FALSE)
  invisible(TRUE)
}

# -- typing ----------------------------------------------------------------

nj_norm <- function(x) {
  x <- toupper(x)
  x <- gsub("[^A-Z0-9 ]", "", gsub("[.,'’/&-]", "", x))
  x <- stringr::str_squish(x)
  x <- sub("^THE ", "", x)
  sub(" INC$", "", x)
}

nj_federal <- function() {
  h <- jsonlite::fromJSON(here::here(NJ_FEDERAL, "cms_hosp_enrollments_NJ.json"))
  q <- jsonlite::fromJSON(here::here(NJ_FEDERAL, "cms_fqhc_enrollments_NJ.json"))
  dplyr::bind_rows(
    tibble::tibble(kind = "HOSPITAL", ccn = h$CCN, org = h$`ORGANIZATION NAME`,
                   dba = h$`DOING BUSINESS AS NAME`, city = h$CITY),
    tibble::tibble(kind = "FQHC", ccn = q$CCN, org = q$`ORGANIZATION NAME`,
                   dba = q$`DOING BUSINESS AS NAME`, city = q$CITY))
}

#' EXACT federal record for an awardee string (after nj_norm), or none.
nj_federal_match <- function(awardee, f = nj_federal()) {
  a <- nj_norm(awardee)
  # "X DBA Y" -- either half may be the enrolled name (CompleteCare).
  halves <- unique(c(a, stringr::str_split(a, " DBA ")[[1]]))
  hit <- f[nj_norm(f$org) %in% halves | nj_norm(f$dba) %in% halves, ]
  hit
}

# The hand-read decisions. Everything else keeps the classifier's answer when
# it is a determined type, or §8's standing fallback, and is queued.
NJ_OVERRIDES <- tibble::tribble(
  ~awardee, ~recipient_type, ~basis_type, ~confidence, ~why,
  "Virtua Health Inc.", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW",
  "HAND-READ BRIDGE: CMS NJ Hospital Enrollment carries no record under 'Virtua Health Inc.'; it enrols Virtua's hospitals under four subsidiaries, every one named VIRTUA ... (Willingboro 310061, Our Lady of Lourdes 310029, West Jersey Health System 310022, Memorial Hospital Burlington County 310057). The parent of an enrolled hospital system is §8's HOSPITAL_OR_SYSTEM; the tie is a reading, so LOW and subtractable.",
  "Gloucester County", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM",
  "A New Jersey county government; the form is in the state's own string.",
  "Warren County", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM",
  "A New Jersey county government; the form is in the state's own string.",
  "Burlington County", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM",
  "A New Jersey county government; the form is in the state's own string.",
  "Cumberland County", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM",
  "A New Jersey county government; the form is in the state's own string.",
  "Hunterdon County", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM",
  "A New Jersey county government -- NOT Hunterdon Medical Center, a different recipient on this same roster.",
  "Mercer County", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM",
  "A New Jersey county government; the form is in the state's own string.",
  "Ocean County", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM",
  "A New Jersey county government; the form is in the state's own string.",
  "Salem County", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM",
  "A New Jersey county government; the form is in the state's own string.",
  "Sussex County", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM",
  "A New Jersey county government; the form is in the state's own string.",
  "Allamuchy-Green First Aid Squad", "EMS_OR_PSAP", "STATE_SOURCE", "MEDIUM",
  "A volunteer first aid (EMS) squad; the form is in the state's own string. The classifier's EMS rule does not reach 'First Aid Squad'.",
  "Rutgers Biomedical and Health Sciences", "UNIVERSITY_OR_AHC", "STATE_SOURCE", "MEDIUM",
  "Rutgers University's academic health sciences division; the university is in the state's own string.",
  "Center for Health Equity a Public Health Institute Inc.", "NONPROFIT_CBO", "STATE_SOURCE", "MEDIUM",
  "The state's own string states the form: 'a Public Health Institute Inc.' -- a nonprofit public health institute. The largest single row ($21,748,500); not a hospital on any reading.",
  "Bridgeway Behavioral Health Services A NJ Nonprofit Corporation", "NONPROFIT_CBO", "STATE_SOURCE", "MEDIUM",
  "The state's own string states the form: 'A NJ Nonprofit Corporation'.",
  "New Jersey Chapter, American Academy of Pediatrics", "NONPROFIT_CBO", "GENERAL_KNOWLEDGE", "LOW",
  "OVERRIDE of the classifier's PHYSICIAN_PRACTICE, which reads 'Pediatrics' as a practice: this is the state chapter of a professional medical society. Left on §8's standing fallback and queued; $0 hospital effect either way."
)

# §10.2's association row -- read, not inferred from the name.
NJ_ASSOCIATION <- "Health Research and Educational Trust of NJ/NJHA"

nj_year1_awardees <- function(d = nj_parse_roster()) {
  f <- nj_federal()
  cls <- rhtp_classify_recipient_type(d$awardee, NJ_STATE)
  out <- vector("list", nrow(d))
  for (i in seq_len(nrow(d))) {
    a <- d$awardee[i]
    ccn_i <- NA_character_
    hit <- nj_federal_match(a, f)
    ov <- NJ_OVERRIDES[NJ_OVERRIDES$awardee == a, ]
    if (nrow(ov)) {
      rt <- ov$recipient_type; bt <- ov$basis_type; cf <- ov$confidence
      why <- ov$why; how <- "HAND-READ"
    } else if (nrow(hit) && length(unique(hit$kind)) == 1L) {
      k <- hit$kind[1]
      rt <- if (k == "HOSPITAL") "HOSPITAL_OR_SYSTEM" else "FQHC_OR_RHC"
      bt <- "ORG_WEBSITE"; cf <- "MEDIUM"; how <- "FEDERAL RECORD"
      # One CCN is cited only where it is the facility: a single-hospital
      # corporation, or a bracketed SITE whose own DBA carries the site name.
      # Otherwise the corporation's CCNs are listed as "CCNs" and none is put
      # in `ccn` -- the rural cut must not read Morristown for Hackettstown.
      six <- sort(unique(hit$ccn[grepl("^[0-9]{6}$", hit$ccn)]))
      if (k == "HOSPITAL" && !is.na(d$site[i])) {
        at <- hit$ccn[grepl("^[0-9]{6}$", hit$ccn) &
                        grepl(toupper(d$site[i]), toupper(hit$dba), fixed = TRUE)]
        if (length(unique(at)) == 1L) six <- unique(at)
      }
      one <- k == "HOSPITAL" && length(six) == 1L
      ccn_i <- if (one) six else NA_character_
      why <- paste0("EXACT federal record: CMS NJ ",
                    ifelse(k == "HOSPITAL", "Hospital", "FQHC"),
                    " Enrollment carries this string as an ORGANIZATION NAME or DBA ",
                    "(normalised for case, punctuation, a leading THE and a trailing INC) ",
                    ifelse(one, paste0("at CCN ", six),
                           paste0("at CCNs ", paste(sort(unique(hit$ccn)), collapse = "/"))),
                    ".")
    } else if (nrow(hit)) {
      stop("[NJ] '", a, "' matches both a hospital and an FQHC record.",
           call. = FALSE)
    } else if (cls$recipient_type[i] %in% c("UNIVERSITY_OR_AHC", "EMS_OR_PSAP") ||
               (cls$recipient_type[i] == "FQHC_OR_RHC")) {
      rt <- cls$recipient_type[i]; bt <- "STATE_SOURCE"
      cf <- cls$determination_confidence[i]; how <- "CLASSIFIER"
      why <- "The form is in the state's own string, and the shared classifier's name rule reads it."
    } else if (cls$recipient_type[i] == "HOSPITAL_OR_SYSTEM") {
      stop("[NJ] the classifier calls '", a, "' a hospital and no federal record ",
           "or hand-read decision covers it. Read it.", call. = FALSE)
    } else {
      rt <- "NONPROFIT_CBO"; bt <- NA_character_; cf <- "LOW"; how <- "FALLBACK"
      why <- "The source states no form (§8's standing fallback, RECIPIENT_TYPE_INFERRED); queued as NJ_RECIPIENT_FORM_NOT_STATED."
    }
    hosp <- rt == "HOSPITAL_OR_SYSTEM"
    if (hosp) {
      flow <- "DIRECT"; dth <- "Yes"
    } else {
      # "pre-hospital" / "prehospital" names an EMS SETTING, not a hospital;
      # left in, the in-kind rule reads Atlantic Ambulance's whole-blood
      # programme as a benefit to hospitals. Stripped for the flow test only.
      fl <- rhtp_classify_flow(
        rt, gsub("pre-? ?hospital", "field", d$activity[i], ignore.case = TRUE))
      flow <- fl$flow_type; dth <- fl$distributed_to_hospital
    }
    if (a == NJ_ASSOCIATION) {
      rt <- "NONPROFIT_CBO"; flow <- "IN_KIND_BENEFIT"; dth <- "No"
      bt <- "GENERAL_KNOWLEDGE"; cf <- "LOW"; how <- "HAND-READ"
      why <- paste0("§10.2 ASSOCIATION ROW, IN-KIND HALF: the New Jersey Hospital ",
                    "Association's research and education affiliate. Its activity is ",
                    "'streamlining real-time clinical decision support systems and tools ",
                    "in rural hospitals' -- tools reach hospitals, dollars do not ",
                    "(Georgia's GHA carts).")
    }
    if (dth == "Yes" && !hosp) {
      stop("[NJ] '", a, "' came out Yes without being a hospital. No NJ row is ",
           "a designated pass-through; read it.", call. = FALSE)
    }
    fallback <- how == "FALLBACK" ||
      (how == "HAND-READ" && rt == "NONPROFIT_CBO" && cf == "LOW" && a != NJ_ASSOCIATION)
    out[[i]] <- tibble::tibble(
      recipient_type = rt, distributed_to_hospital = dth, flow_type = flow,
      basis_type = bt, determination_confidence = cf, typing = how,
      why = why, ccn = ccn_i, classifier = paste0(cls$recipient_type[i], "/",
                                     cls$determination_confidence[i]),
      fallback = fallback)
  }
  t <- dplyr::bind_rows(out)
  hosp <- t$recipient_type == "HOSPITAL_OR_SYSTEM"
  tibble::tibble(
    state = NJ_STATE,
    row_no = seq_len(nrow(d)),
    awardee = d$awardee,
    amount = d$amount,
    recipient_type = t$recipient_type,
    distributed_to_hospital = t$distributed_to_hospital,
    note = paste0("NJRHT first-round award, 2026-07-31. ", d$section,
                  ifelse(is.na(d$site), "", paste0(". SITE (not the recipient): ", d$site)),
                  "."),
    recipient_confirmed = "Yes",
    amount_confirmed = "Yes",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = "Rural Health Transformation Program Funding Allocations – July 31, 2026 (NJ DOH/DHS)",
    state_source_url = NJ_PDF_URL,
    validation_source_type = "GOVERNOR_PRESS_RELEASE",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03bf_nj_year1_awardees.R",
    ccn = t$ccn,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    award_pool = d$section,
    site = d$site,
    activity_raw = d$activity,
    recipient_type_source = paste0("TYPED (session 61, ", t$typing, "): ", t$why,
                                   " Classifier said ", t$classifier, "."),
    determination_confidence = t$determination_confidence,
    flag_reason = ifelse(t$fallback, "RECIPIENT_TYPE_INFERRED", NA_character_),
    budget_period = "Budget Period 1",
    flow_type = t$flow_type,
    hospital_benefiting = ifelse(hosp | t$flow_type == "IN_KIND_BENEFIT", "Yes", "No"),
    hospital_attribution = ifelse(hosp, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = paste0("§10.2 ", t$flow_type, ": ", t$why,
                                 ifelse(hosp, " §0.3a: the recipient is a hospital whatever the activity.", "")),
    amount_basis = "Award Amount column of the state's allocations PDF, exact to the dollar. The PDF prints no total; the 103 rows sum to $83,060,837 against the Governor's '$83 million' and '103 projects'.",
    basis_type = t$basis_type,
    round_amount = NA_real_,
    announcement_date = NJ_ANNOUNCED,
    source_archive_path = NJ_PDF)
}

nj_assert_typing <- function(a = nj_year1_awardees()) {
  h <- a[a$distributed_to_hospital == "Yes", ]
  if (nrow(h) != 35L) {
    stop("[NJ] ", nrow(h), " named-hospital rows, not 35.", call. = FALSE)
  }
  ahs <- a$awardee == "AtlantiCare Health Services, Inc."
  if (!all(a$recipient_type[ahs] == "FQHC_OR_RHC")) {
    stop("[NJ] AtlantiCare Health Services is no longer typed from CMS's FQHC ",
         "file. It is NOT the hospital (AtlantiCare Regional Medical Center).",
         call. = FALSE)
  }
  if (any(h$determination_confidence == "HIGH")) {
    stop("[NJ] HIGH needs a CCN match in Stage 5 (§7).", call. = FALSE)
  }
  low <- h[h$determination_confidence == "LOW", ]
  if (!identical(unique(low$awardee), "Virtua Health Inc.")) {
    stop("[NJ] the only LOW hospital bridge should be Virtua Health Inc.",
         call. = FALSE)
  }
  if (any(!a$recipient_type %in% rhtp_vocabulary("recipient_type"))) {
    stop("[NJ] a recipient_type outside §8.", call. = FALSE)
  }
  invisible(TRUE)
}

nj_status_table <- function() {
  tibble::tribble(
    ~state, ~channel, ~stage, ~publishes_roster, ~note,
    NJ_STATE, "Governor + DOH + DHS newsrooms, 2026-07-31, and the linked allocations PDF",
    "AWARDED_ROSTER_PUBLISHED", "Yes",
    "103 priced awards, six categories, $83,060,837 (sum of the rows; the PDF prints no total). 'The first round'. DOH administers ~$95M of competitive funding, so ~$12M of it, plus DHS's lead-agency share, is in no public roster: a PARTIAL year.",
    NJ_STATE, "nj.gov/rural-health-transformation (programme page, launched 2026-08-21)",
    "DOES_NOT_LINK_THE_AWARDS", "No",
    "On 2026-09-24 it reads 'Subrecipient grants awarded -- In progress' and links no roster; the PDF sits under its /documents/ path but is reachable only from the DOH newsroom item. Tennessee's shape.",
    NJ_STATE, "DOH Office of Rural Health page", "STALE", "No",
    "Still says New Jersey 'applied for' the funding (session 39, re-read session 60).",
    NJ_STATE, "DOH Notice of Grant Opportunity index (healthapps.nj.gov)", "INDEX_ONLY", "No",
    "Where a second-round NGO would appear; it names no award."
  )
}

nj_rcj_disposition <- function() {
  rt <- readRDS(here::here("data", "interim", "stage2_record_table.rds"))
  t <- rt[rt$state == NJ_STATE, ]
  aw <- jsonlite::fromJSON(here::here("data", "raw", "rcj", "2026-09-24", "awards.json"))
  aw <- if (is.data.frame(aw)) aw else aw$data
  n24 <- sum(aw$state == NJ_STATE, na.rm = TRUE)
  tibble::tribble(
    ~state, ~group, ~records, ~disposition, ~note,
    NJ_STATE, "RCJ New Jersey records, pull 2026-08-27 (stage 2 record table)", nrow(t),
    "NO_TIER_3", paste0(sum(t$award_tier == "SUBAWARD", na.rm = TRUE),
                        " SUBAWARD records. The 08-27 pull predates nothing: the roster was public from 2026-07-31 and RCJ had not caught it."),
    NJ_STATE, "RCJ New Jersey /awards rows, pull 2026-09-24 (raw)", n24,
    "PARTIAL_COVERAGE", "Session 60 read 11 of the 103 awards here. A discovery signal only (§0.1); every row in nj_year1_awardees.csv is built from the state PDF."
  )
}

nj_validate <- function() {
  d <- nj_parse_roster()
  nj_assert_roster(d)
  nj_assert_releases()
  a <- nj_year1_awardees(d)
  nj_assert_typing(a)
  message("[NJ] all assertions pass.")
  invisible(a)
}

nj_build <- function() {
  a <- nj_validate()
  readr::write_csv(a, NJ_CSV, na = "")
  readr::write_csv(nj_status_table(), NJ_STATUS_CSV, na = "")
  readr::write_csv(nj_rcj_disposition(), NJ_DISPO_CSV, na = "")
  h <- a[a$distributed_to_hospital == "Yes", ]
  message(sprintf("[NJ] wrote 103 award rows; %d named-hospital rows, $%s.",
                  nrow(h), format(sum(h$amount), big.mark = ",")))
}

nj_report <- function() {
  a <- nj_year1_awardees()
  print(a %>% dplyr::count(recipient_type, distributed_to_hospital,
                           wt = amount, name = "dollars"))
  h <- a[a$distributed_to_hospital == "Yes", ]
  cat(sprintf("\n%d award actions, $%s; %d named-hospital rows, $%s (%.1f%%); LOW bridge $%s.\n",
              nrow(a), format(sum(a$amount), big.mark = ","), nrow(h),
              format(sum(h$amount), big.mark = ","), 100 * sum(h$amount) / sum(a$amount),
              format(sum(h$amount[h$determination_confidence == "LOW"]), big.mark = ",")))
  fb <- a[!is.na(a$flag_reason), ]
  cat(sprintf("Unstated form (queued): %d rows, $%s, all No.\n", nrow(fb),
              format(sum(fb$amount), big.mark = ",")))
}

# -- the watch -------------------------------------------------------------

NJ_PROBE_PAGES <- tibble::tribble(
  ~key, ~url, ~file, ~name_diff,
  "rhtp", "https://www.nj.gov/rural-health-transformation/",
  "data/evidence/NJ/2026-09-24_njrht_programme.html", TRUE,
  "doh_news", "https://www.nj.gov/health/news/2026/approved/news_archive.shtml",
  "data/evidence/NJ/2026-09-24_doh_news_archive_2026.html", FALSE)

NJ_KNOWN_RHTP_HEADLINES <- c(
  "New Jersey Rural Health Transformation Program Launches New Website and Announces Year Two Outlook Webinar",
  "ICYMI: New Jersey Awards First Round of Rural Health Transformation Grants")

nj_fetch <- function() {
  for (i in seq_len(nrow(NJ_PROBE_PAGES))) {
    rhtp_watch_archive(NJ_PROBE_PAGES$url[i], NJ_PROBE_PAGES$file[i], NJ_USER_AGENT)
  }
  message("[NJ] archived ", nrow(NJ_PROBE_PAGES), " baselines under ", NJ_DIR)
}

nj_news_headlines <- function(raw) {
  h <- xml2::read_html(raw)
  a <- rvest::html_elements(h, "a[href*='/health/news/2026/']")
  x <- stringr::str_squish(rvest::html_text2(a))
  unique(x[nzchar(x)])
}

#' THE TRIPWIRES. (1) A new RHTP headline on DOH's news archive saying award /
#' grant / recipient is the second round. (2) The programme page linking a
#' document -- it links none today, and a roster link there is new.
nj_assert_watch <- function(raw_news, raw_rhtp) {
  hl <- nj_news_headlines(raw_news)
  if (length(hl) < 20L) {
    stop("[NJ] the DOH news archive yields ", length(hl), " headlines; our ",
         "reader, not New Jersey, has changed (§0.4).", call. = FALSE)
  }
  rhtp <- hl[grepl("Rural Health Transformation|\\bRHT\\b|NJRHT", hl)]
  new <- setdiff(rhtp, NJ_KNOWN_RHTP_HEADLINES)
  hot <- new[grepl("award|grant|recipient|fund", new, ignore.case = TRUE)]
  if (length(hot)) {
    stop("[NJ] NEW RHTP AWARD RELEASE ON DOH'S NEWS ARCHIVE: ",
         paste0("'", rhtp_watch_quote(hot), "'", collapse = "; "),
         ". The 2026-07-31 roster was 'the first round'. Archive the release ",
         "and its roster and extend nj_year1_awardees.csv.", call. = FALSE)
  }
  h <- xml2::read_html(raw_rhtp)
  hrefs <- rvest::html_attr(rvest::html_elements(h, "a"), "href")
  docs <- hrefs[!is.na(hrefs) & grepl("\\.pdf|\\.xlsx|/documents/", hrefs,
                                      ignore.case = TRUE)]
  if (length(docs)) {
    stop("[NJ] the NJRHT programme page now links a document: ",
         paste(rhtp_watch_quote(docs), collapse = ", "), ". Read it.",
         call. = FALSE)
  }
  invisible(new)
}

nj_probe <- function() {
  w <- rhtp_watch_pages(NJ_PROBE_PAGES, NJ_USER_AGENT)
  nj_assert_watch(w$raw$doh_news, w$raw$rhtp)
  rhtp_assert_no_new_organisations_across(live = w$live, archived = w$arch,
                                          state = NJ_STATE)
  message("[NJ] ", paste0(w$changed$key, ": ",
                          ifelse(w$changed$changed, "CHANGED", "UNCHANGED"),
                          collapse = "; "), " -- no new RHTP award release.")
  invisible(w$changed)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) nj_fetch()
  if ("--validate" %in% args) nj_validate()
  if ("--build" %in% args) nj_build()
  if ("--probe" %in% args) rhtp_probe_run("NJ", nj_probe())
  if ("--report" %in% args) nj_report()
  if (!length(args)) message("Usage: --fetch | --validate | --build | --probe | --report")
}
