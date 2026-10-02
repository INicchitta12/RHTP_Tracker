#!/usr/bin/env Rscript
# 03bt_ok_new_rosters.R --------------------------------------------------------
#
# OKLAHOMA'S THIRD, FOURTH AND FIFTH ROSTERS. Session 85.
#
# The OK Routine tripped on 2026-10-01 18:12Z: "Expanding Care: Doulas
# Program" was on the Funding Recipients page. Read on 10-02, the page carries
# THREE new rosters, not one, each "List of Funding Recipients" with a name
# and an exact amount per line:
#
#   Rural Regional Reorientation (RRR)   20 recipients   $39,578,523.00
#   Expanding Care: Doulas                4 recipients      $647,967.83
#   Chronic Disease Management (CDM)     15 recipients   $15,608,845.22
#
# ONLY DOULAS IS WRITTEN. The owner's standing instruction is to report before
# extracting anything over $10M, and RRR and CDM are both over it. They are
# PARSED and ASSERTED here (count and total), so the day they are approved
# the work is a typing pass and a --build, not a re-read -- but no file
# carries them and nothing in the partition moves for them. `--report` prints
# all three.
#
# A SEPARATE FILE, NOT ROWS APPENDED TO ok_year1_awardees.csv. That file
# carries session 49's ROW-INDEX overlay and R/03bj's, and R/03t's --build
# does not re-apply 49's; it is built from the 2026-08-31 archive, which this
# page's 10-02 copy does not replace. North Carolina SBHC's and Alabama round
# 2's precedent: a second file for a later roster.
#
# DOULAS TYPING (hand-read, each checked against an archived federal file):
#   * Newman Memorial Hospital, $38,525 -- HOSPITAL_OR_SYSTEM. CMS Hospital
#     Enrollments (OK, 2026-09-25): NEWMAN MEMORIAL HOSPITAL, INC, PART A
#     PROVIDER - CRITICAL ACCESS HOSPITAL, CCN 371336, Shattuck. The awardee
#     string is the legal name less ", Inc" (EXACT_LEGAL_NAME, MEDIUM). The
#     activity is a doula workforce programme; §0.3a judges the recipient.
#   * Board of Regents of the University of Oklahoma Health Sciences Center,
#     $5,445.49 -- UNIVERSITY_OR_AHC. The programme named under it is the
#     Oklahoma Breastfeeding Resource Center. OU's hospital is enrolled by a
#     DIFFERENT legal body (OU MEDICINE INC, CCN 370093), so §10.2's
#     enrolled-operator row does not reach the Board of Regents (§2: a name
#     that is a prefix of another body is never matched).
#   * Tulsa Community Foundation, $240,907 -- NONPROFIT_CBO, the source's own
#     words: "fiscal sponsor for Oklahoma Birth Equity Initiative". A
#     community foundation, not a hospital foundation (§10.2: the test is the
#     PARENT, and it has none).
#   * Western Plains Youth and Family Services, $363,090.34 -- §8's standing
#     fallback (no stated form, no federal record searched beyond the hospital
#     file, where it is absent).
#
# §0.2: the page's CMS footer prints $223,476,948.62, OK's ALLOTMENT (Tier 1).
#
# Usage:
#   Rscript R/03bt_ok_new_rosters.R --validate | --build | --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

OKN_STATE    <- "OK"
OKN_URL      <- "https://oklahoma.gov/health/rhtp/rhtp-funding-recipients.html"
OKN_ARCHIVE  <- file.path("data", "evidence", "OK", "new_rosters",
                         "2026-10-02_ok_rhtp_funding_recipients.html")
OKN_SHA256   <- "7aa998ab5f362d880dd73181c643ab4080fe122079b951d9283b131e44e8e056"
OKN_READ     <- as.Date("2026-10-02")
OKN_NOA_DATE <- as.Date("2025-12-29")
OKN_CSV      <- here::here("data", "reference", "ok_year1_doulas_awardees.csv")
OKN_HOSP_FED <- file.path("data", "evidence", "federal_records", "2026-09-25",
                          "cms_hosp_enrollments_OK.json")
OKN_FOOTER   <- "as part of a financial assistance award totaling $223,476,948.62 with 100 percent funded by CMS/HHS"

# Each roster: the heading it sits under, the heading that ends it, and the
# count and total READ on 2026-10-02 (asserted, never assumed).
OKN_ROSTERS <- tibble::tribble(
  ~key,      ~round_name,                       ~start,                                                   ~end,                                  ~n,  ~total,       ~written,
  "rrr",     "Rural Regional Reorientation (RRR) Program", "RRR Program: List of Funding Recipients",     "Expanding Care: Doulas Program",      20L, 39578523.00, FALSE,
  "doulas",  "Expanding Care: Doulas Program",  "Expanding Care: Doulas Program: List of Funding Recipients", "Chronic Disease Management Program", 4L,  647967.83,   TRUE,
  "cdm",     "Chronic Disease Management Program", "Chronic Disease Management Program: List of Funding Recipients", "OSDE's ROOTS Competitive Grant", 15L, 15608845.22, FALSE)

okn_lines <- function() {
  raw <- readr::read_file_raw(here::here(OKN_ARCHIVE))
  if (digest::digest(raw, algo = "sha256", serialize = FALSE) != OKN_SHA256) {
    stop("[OK new rosters] the archive's SHA-256 does not match its manifest.",
         call. = FALSE)
  }
  h <- xml2::read_html(raw)
  t <- rvest::html_text2(rvest::html_element(h, "main"))
  t <- gsub("​", "", t, fixed = TRUE)
  x <- stringr::str_squish(strsplit(t, "\n", fixed = TRUE)[[1]])
  x[nzchar(x)]
}

#' One roster's recipient lines: "Name, $amount" or "Name $amountCounties ..."
okn_parse <- function(key, x = okn_lines()) {
  r <- OKN_ROSTERS[OKN_ROSTERS$key == key, ]
  i <- which(x == r$start)
  if (length(i) != 1L) stop("[OK new rosters] '", r$start, "' heading not found once.",
                            call. = FALSE)
  j <- which(x == r$end); j <- j[j > i][1]
  if (is.na(j)) stop("[OK new rosters] no end heading after '", r$start, "'.", call. = FALSE)
  y <- x[(i + 1):(j - 1)]
  m <- stringr::str_match(y, "^(.+?),?\\s+\\$([0-9][0-9,]*(?:\\.[0-9]{1,2})?)(?:\\s|Counties|$)")
  k <- which(!is.na(m[, 1]))
  tibble::tibble(round = key, line = y[k], awardee = stringr::str_trim(m[k, 2]),
                 amount = as.numeric(gsub(",", "", m[k, 3])),
                 detail = vapply(k, function(z) paste(y[seq(z + 1, min(z + 2, length(y)))],
                                                      collapse = " "), character(1)))
}

okn_assert_source <- function(x = okn_lines()) {
  # The CMS footer sits outside <main>, so it is read off the whole page.
  full <- stringr::str_squish(rvest::html_text2(xml2::read_html(here::here(OKN_ARCHIVE))))
  if (!grepl(OKN_FOOTER, full, fixed = TRUE)) {
    stop("[OK new rosters] the CMS footer is gone from the archive.", call. = FALSE)
  }
  t <- paste(x, collapse = " ")
  for (s in c("This page provides information about funded projects, award amounts, and the organizations selected to receive RHTP funding.")) {
    if (!grepl(s, t, fixed = TRUE)) stop("[OK new rosters] missing: '", s, "'.", call. = FALSE)
  }
  for (k in OKN_ROSTERS$key) {
    r <- OKN_ROSTERS[OKN_ROSTERS$key == k, ]
    p <- okn_parse(k, x)
    if (nrow(p) != r$n || abs(sum(p$amount) - r$total) > 0.005) {
      stop("[OK new rosters] ", k, ": read ", nrow(p), " rows / $",
           format(sum(p$amount), big.mark = ",", nsmall = 2), "; the 10-02 read was ",
           r$n, " / $", format(r$total, big.mark = ",", nsmall = 2), ".", call. = FALSE)
    }
    # A roster figure is never the allotment (§0.2).
    if (any(abs(p$amount - 223476949) < RHTP_FOOTER_ALLOTMENT_MARGIN)) {
      stop("[OK new rosters] an award line equals the allotment.", call. = FALSE)
    }
  }
  if (!(OKN_READ > OKN_NOA_DATE)) stop("[OK new rosters] §6.2 date test.", call. = FALSE)
  invisible(TRUE)
}

OKN_DOULAS_TYPING <- tibble::tribble(
  ~awardee, ~recipient_type, ~basis_type, ~confidence, ~ccn, ~enrol_match, ~why,
  "Board of Regents of the University of Oklahoma Health Sciences Center",
  "UNIVERSITY_OR_AHC", "STATE_SOURCE", "MEDIUM", NA, NA,
  "The awardee is a university's board of regents; the programme named under it is the Oklahoma Breastfeeding Resource Center. OU's hospital is enrolled by a DIFFERENT legal body (CMS OK Hospital Enrollments: OU MEDICINE INC dba OU HEALTH UNIVERSITY OF OKLAHOMA MEDICAL CENTER, CCN 370093), so §10.2's enrolled-operator row does not reach it.",
  "Newman Memorial Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "371336", "EXACT_LEGAL_NAME",
  "§10.2 DIRECT: CMS OK Hospital Enrollments (federal_records/2026-09-25) carry NEWMAN MEMORIAL HOSPITAL, INC, PART A PROVIDER - CRITICAL ACCESS HOSPITAL, CCN 371336, Shattuck -- the awardee's legal name less its corporate suffix. The activity is a doula workforce programme; §0.3a judges the recipient.",
  "Tulsa Community Foundation", "NONPROFIT_CBO", "STATE_SOURCE", "MEDIUM", NA, NA,
  "The source: 'Tulsa Community Foundation is the fiscal sponsor for Oklahoma Birth Equity Initiative (OKBEI)'. A community foundation with no hospital parent (§10.2: the test is the PARENT).",
  "Western Plains Youth and Family Services", NA, NA, NA, NA, NA,
  "No stated form and no CMS hospital enrolment under this name: §8's standing fallback, NOT promoted (§0.4)."
)

okn_assert_federal <- function() {
  e <- jsonlite::fromJSON(here::here(OKN_HOSP_FED))
  nm <- e[["ORGANIZATION NAME"]]
  if (!"371336" %in% e$CCN[nm == "NEWMAN MEMORIAL HOSPITAL, INC"]) {
    stop("[OK new rosters] the archived OK hospital file no longer carries Newman (371336).",
         call. = FALSE)
  }
  if (any(grepl("REGENTS|TULSA COMMUNITY FOUNDATION|WESTERN PLAINS", nm))) {
    stop("[OK new rosters] a non-hospital Doulas awardee now appears in the OK ",
         "hospital enrolment file -- re-type it.", call. = FALSE)
  }
  invisible(TRUE)
}

okn_doulas <- function(p = okn_parse("doulas")) {
  ty <- OKN_DOULAS_TYPING[match(p$awardee, OKN_DOULAS_TYPING$awardee), ]
  if (any(is.na(ty$awardee))) {
    stop("[OK new rosters] no hand-read typing for: ",
         paste(p$awardee[is.na(ty$awardee)], collapse = "; "), call. = FALSE)
  }
  cls <- rhtp_classify_recipient_type(p$awardee, OKN_STATE)
  typed <- !is.na(ty$recipient_type)
  rtype <- ifelse(typed, ty$recipient_type, cls$recipient_type)
  hosp <- rtype == "HOSPITAL_OR_SYSTEM"
  tibble::tibble(
    state = OKN_STATE,
    row_no = seq_len(nrow(p)),
    awardee = p$awardee,
    amount = p$amount,
    recipient_type = rtype,
    distributed_to_hospital = ifelse(hosp, "Yes", "No"),
    note = paste0("Expanding Care: Doulas Program, List of Funding Recipients (OSDH, read ",
                  OKN_READ, "). ", p$detail),
    recipient_confirmed = "Yes",
    amount_confirmed = "Yes",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = "Oklahoma RHTP Funding Recipients -- Expanding Care: Doulas Program, List of Funding Recipients",
    state_source_url = OKN_URL,
    validation_source_type = "NOTICE_OF_AWARD",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03bt_ok_new_rosters.R",
    ccn = ty$ccn,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    recipient_type_source = ifelse(
      typed, paste0("TYPED (session 85, HAND-READ): ", ty$why, " Classifier said ",
                    cls$recipient_type, "/", cls$determination_confidence, "."),
      paste0("rhtp_classify_recipient_type() on the name: ", cls$recipient_type, "/",
             cls$determination_confidence, ". ", ty$why)),
    determination_confidence = ifelse(typed, ty$confidence, cls$determination_confidence),
    flag_reason = ifelse(typed, NA_character_, "RECIPIENT_TYPE_INFERRED"),
    award_pool = "Expanding Care: Doulas Program",
    budget_period = "Budget Period 1",
    flow_type = ifelse(hosp, "DIRECT", "NON_HOSPITAL"),
    hospital_benefiting = ifelse(hosp, "Yes", "Unclear"),
    hospital_attribution = ifelse(hosp, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = paste0("§10.2 ", ifelse(hosp, "DIRECT", "NON_HOSPITAL"), ": ", ty$why),
    amount_basis = "EXACT, as published per recipient by OSDH.",
    round_name = "Expanding Care: Doulas Program",
    round_awards = nrow(p),
    round_amount = NA_real_,
    announcement_date = OKN_READ,
    source_archive_path = OKN_ARCHIVE,
    basis_type = ty$basis_type,
    recipient_subtype = NA_character_,
    cms_enrolment_match = ty$enrol_match,
    cms_enrolment_record = ifelse(
      !is.na(ty$enrol_match),
      paste0("CMS Hospital Enrollments: NEWMAN MEMORIAL HOSPITAL, INC, CCN 371336 (", OKN_HOSP_FED, ")"),
      NA_character_))
}

okn_assert_rows <- function(a) {
  if (nrow(a) != 4L || abs(sum(a$amount) - 647967.83) > 0.005) {
    stop("[OK Doulas] four rows, $647,967.83.", call. = FALSE)
  }
  h <- a[a$distributed_to_hospital == "Yes", ]
  if (nrow(h) != 1L || h$awardee != "Newman Memorial Hospital") {
    stop("[OK Doulas] exactly one hospital row, Newman Memorial.", call. = FALSE)
  }
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "determination_confidence", "hospital_attribution", "basis_type",
                "flag_reason", "cms_enrolment_match")) {
    bad <- setdiff(stats::na.omit(unique(a[[col]])), rhtp_vocabulary(col))
    if (length(bad)) stop("[OK Doulas] ", col, " outside §8: ", paste(bad, collapse = ", "),
                          call. = FALSE)
  }
  invisible(TRUE)
}

okn_validate <- function() {
  x <- okn_lines()
  okn_assert_source(x)
  okn_assert_federal()
  a <- okn_doulas(okn_parse("doulas", x))
  okn_assert_rows(a)
  message("[OK new rosters] all assertions pass. RRR and CDM are parsed and ",
          "NOT written (over the $10M report-first line).")
  invisible(a)
}

okn_build <- function() {
  a <- okn_validate()
  readr::write_csv(a, OKN_CSV, na = "")
  message("[OK Doulas] wrote ", nrow(a), " rows, $",
          format(sum(a$amount), big.mark = ",", nsmall = 2), "; 1 named-hospital row, $",
          format(sum(a$amount[a$distributed_to_hospital == "Yes"]), big.mark = ","), ".")
  invisible(a)
}

okn_report <- function() {
  x <- okn_lines()
  for (k in OKN_ROSTERS$key) {
    p <- okn_parse(k, x)
    cls <- rhtp_classify_recipient_type(p$awardee, OKN_STATE)
    cat(sprintf("\n== %s: %d rows, $%s%s\n", k, nrow(p),
                format(sum(p$amount), big.mark = ",", nsmall = 2),
                if (OKN_ROSTERS$written[OKN_ROSTERS$key == k]) "" else "  [NOT WRITTEN]"))
    print(as.data.frame(tibble::tibble(awardee = p$awardee, amount = p$amount,
                                       name_rule = cls$recipient_type)), row.names = FALSE)
  }
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) okn_validate()
  if ("--build" %in% args) okn_build()
  if ("--report" %in% args) okn_report()
  if (!length(args)) message("Usage: --validate | --build | --report")
}
