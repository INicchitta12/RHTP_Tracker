# 03bk_umms_system_form.R ------------------------------------------------------
# Session 73. University of Maryland Medical System (UMMS), Maryland's one
# Transformation Fund row at $4,020,144, re-typed UNIVERSITY_OR_AHC ->
# HOSPITAL_OR_SYSTEM on its OWN STATED FORM (option (c) of the
# AHC_STRING_NAMES_NO_ENROLLED_ENTITY queue row, on the owner's instruction).
#
# WHY IT IS NOT §10.2's ENROLLED-OPERATOR RULE (R/03bj).
#   Session 72 read the complete CMS Maryland Hospital Enrollments file (57
#   records) and found "University of Maryland Medical System" as NO
#   organization name and NO DBA. UMMS's hospitals each enrol as their own
#   legal body (University of Maryland Medical Center, LLC, CCN 210002, and
#   seven more). So the awardee is the system PARENT, and no enrolment matches
#   it. That is recorded on the row; `ccn` stays EMPTY, because a CCN on the row
#   would say the recipient's own legal entity is enrolled, which it is not.
#
# WHY IT IS HOSPITAL_OR_SYSTEM ANYWAY.
#   The name rule typed it UNIVERSITY_OR_AHC off the word "University", which
#   is recognition, not a source (§0.4). UMMS states its own form: "University
#   of Maryland Medical System (UMMS) is an academic private health system ...
#   delivered at our 11 hospitals, including the flagship University of
#   Maryland Medical Center". A hospital SYSTEM is §8's HOSPITAL_OR_SYSTEM, and
#   its flow is §10.2's ordinary DIRECT row; the telehealth project it funds
#   does not decide it (§0.3a). The form rests on a second publisher, so
#   basis_type = ORG_WEBSITE and determination_confidence = MEDIUM (§0.4); a
#   reader can subtract it.
#
#   recipient_subtype = ACADEMIC_HEALTH_CENTER is NOT set: that subtype marks a
#   row re-typed on a CMS enrolment (session 71), and this one is not. The
#   Maryland file carries no such column and none is added.
#
# REBUILD ORDER. R/03p --build -> R/03ap's vq_overlay() -> umms_overlay().
#   `--apply` patches the committed file as raw strings and is idempotent.
#
# Usage:
#   Rscript R/03bk_umms_system_form.R --fetch    # archive UMMS's page (once)
#   Rscript R/03bk_umms_system_form.R --apply    # patch md_year1_awardees.csv
#   Rscript R/03bk_umms_system_form.R --report   # the row and its effect

suppressPackageStartupMessages({
  source(here::here("R", "utils_config.R"))
  source(here::here("R", "utils_recipient_classification.R"))
})

`%>%` <- magrittr::`%>%`

UMMS_FILE    <- "md_year1_awardees.csv"
UMMS_AWARDEE <- "University of Maryland Medical System"
UMMS_AMOUNT  <- 4020144
UMMS_URL     <- "https://www.umms.org/about/member-hospitals"
UMMS_ARCHIVE <- "data/evidence/MD/2026-09-25_umms_member_hospitals.html"
UMMS_ENROL   <- "data/evidence/federal_records/2026-09-25/cms_hosp_enrollments_MD.json"
UMMS_TAG     <- "RECIPIENT TYPE FROM THE SYSTEM'S OWN STATED FORM (session 73)"
UMMS_USER_AGENT <- "AHA-RHTP-Tracker/0.1 (+https://www.aha.org; contact: AHA Data and Policy; R httr2)"

# The sentences the form rests on, asserted against the archive every run.
UMMS_FORM_SENTENCES <- c(
  "University of Maryland Medical System (UMMS) is an academic private health system",
  "delivered at our 11 hospitals, including the flagship University of Maryland Medical Center"
)

# The enrolment structure, read in session 72 from the archived CMS file.
UMMS_ENROLLED_MEMBERS <- tibble::tribble(
  ~legal_body,                                        ~ccn,
  "UNIVERSITY OF MARYLAND MEDICAL CENTER, LLC",       "210002",
  "UNIVERSITY OF MARYLAND ST JOSEPH MEDICAL CENTER LLC", "210063",
  "BALTIMORE WASHINGTON MEDICAL CENTER INC.",          "210043",
  "UPPER CHESAPEAKE MEDICAL CENTER INC",               "210049",
  "MARYLAND GENERAL HOSPITAL INC",                     "210038",
  "JAMES LAWRENCE KERNAN HOSPITAL, INC.",              "210058",
  "DIMENSIONS HEALTH CORPORATION",                     "210003",
  "CHESTER RIVER HOSPITAL CENTER",                     "210030"
)

umms_text <- function(path = here::here(UMMS_ARCHIVE)) {
  h <- rawToChar(readBin(path, "raw", file.info(path)$size))
  Encoding(h) <- "UTF-8"
  h <- gsub("(?is)<(script|style)[^>]*>.*?</\\1>", " ", h, perl = TRUE)
  h <- gsub("<[^>]+>", " ", h, perl = TRUE)
  h <- xml2::xml_text(xml2::read_html(paste0("<p>", h, "</p>")))
  stringr::str_squish(h)
}

umms_fetch <- function(force = FALSE) {
  path <- here::here(UMMS_ARCHIVE)
  if (file.exists(path) && !force) {
    message("[03bk] archive exists; not re-fetched: ", UMMS_ARCHIVE)
    return(invisible(path))
  }
  resp <- httr2::request(UMMS_URL) %>%
    httr2::req_user_agent(UMMS_USER_AGENT) %>%
    httr2::req_perform()
  body <- httr2::resp_body_raw(resp)
  txt <- rawToChar(body)
  if (grepl("pk\\.ey|AIza[0-9A-Za-z_-]{10}", txt, useBytes = TRUE))
    stop("[03bk] page carries a credential-shaped token; not archived", call. = FALSE)
  writeBin(body, path)
  sha <- digest::digest(file = path, algo = "sha256")
  cat(sprintf("%s  %s  (%d bytes)  <- %s  [R/03bk, session 73: UMMS's own statement of its form, byte for byte]\n",
              sha, basename(path), length(body), UMMS_URL),
      file = here::here("data/evidence/MD/MANIFEST.txt"), append = TRUE)
  invisible(path)
}

#' The system states its form, in its own words, in the archived page.
umms_assert_source <- function(txt = umms_text()) {
  miss <- UMMS_FORM_SENTENCES[!vapply(UMMS_FORM_SENTENCES, grepl, logical(1),
                                      x = txt, fixed = TRUE)]
  if (length(miss)) stop("[03bk] UMMS's archived page no longer states: ",
                         paste(miss, collapse = " | "), call. = FALSE)
  invisible(TRUE)
}

#' UMMS's own legal name is on no CMS enrolment; its members' are.
umms_assert_not_enrolled <- function() {
  md <- jsonlite::fromJSON(here::here(UMMS_ENROL))
  nm <- toupper(c(md[["ORGANIZATION NAME"]], md[["DOING BUSINESS AS NAME"]]))
  if (any(grepl("MARYLAND MEDICAL SYSTEM", nm, fixed = TRUE)))
    stop("[03bk] UMMS now appears on a CMS enrolment; R/03bj's rule reaches it ",
         "and this overlay must be retired", call. = FALSE)
  got <- md %>% dplyr::transmute(legal_body = toupper(.data[["ORGANIZATION NAME"]]),
                                 ccn = as.character(.data[["CCN"]]))
  bad <- UMMS_ENROLLED_MEMBERS %>%
    dplyr::anti_join(got, by = c("legal_body", "ccn"))
  if (nrow(bad)) stop("[03bk] enrolled members not found as recorded: ",
                      paste(bad$legal_body, collapse = "; "), call. = FALSE)
  invisible(TRUE)
}

umms_blank <- function(x) is.na(x) | !nzchar(x) | x == "NA"

umms_overlay <- function(d, empty = NA_character_) {
  k <- which(d$awardee == UMMS_AWARDEE)
  if (length(k) != 1L) stop("[03bk] expected one UMMS row, found ", length(k), call. = FALSE)
  if (as.numeric(d$amount[k]) != UMMS_AMOUNT)
    stop("[03bk] UMMS amount is ", d$amount[k], ", expected ", UMMS_AMOUNT, call. = FALSE)
  if (grepl(UMMS_TAG, d$determination_basis[k], fixed = TRUE)) return(d)  # idempotent
  if (d$recipient_type[k] != "UNIVERSITY_OR_AHC")
    stop("[03bk] UMMS is ", d$recipient_type[k], "; expected the name rule's ",
         "UNIVERSITY_OR_AHC", call. = FALSE)
  fl <- rhtp_classify_flow("HOSPITAL_OR_SYSTEM", "")
  stopifnot(fl$flow_type == "DIRECT", fl$distributed_to_hospital == "Yes")
  members <- paste0(UMMS_ENROLLED_MEMBERS$legal_body,
                    " (", UMMS_ENROLLED_MEMBERS$ccn, ")", collapse = "; ")
  prior <- d$determination_basis[k]
  d$recipient_type[k] <- "HOSPITAL_OR_SYSTEM"
  d$determination_confidence[k] <- "MEDIUM"
  d$flow_type[k] <- fl$flow_type
  d$distributed_to_hospital[k] <- fl$distributed_to_hospital
  d$hospital_benefiting[k] <- "Yes"
  d$hospital_attribution[k] <- "NAMED_HOSPITAL"
  d$basis_type[k] <- "ORG_WEBSITE"
  d$verified_by[k] <- "owner instruction, session 73"
  d$verified_basis[k] <- paste0(
    "UMMS's own page (", UMMS_URL, ", archived ", UMMS_ARCHIVE, "): '",
    UMMS_FORM_SENTENCES[1], ", focused on delivering compassionate, high-quality ",
    "care ...' and 'primary and specialty care ", UMMS_FORM_SENTENCES[2], "'.")
  d$determination_basis[k] <- paste0(
    UMMS_TAG, ": HOSPITAL_OR_SYSTEM. The recipient is a hospital SYSTEM on its ",
    "own stated form ('an academic private health system' operating 11 ",
    "hospitals; ORG_WEBSITE, MEDIUM), not a university: the name rule read the ",
    "word 'University', which is recognition (§0.4). §10.2 DIRECT: the ",
    "recipient is a hospital system and MDH's award offer names it and the ",
    "amount; the telehealth project does not decide it (§0.3a). CMS ENROLMENT ",
    "STRUCTURE, RECORDED AND NOT MATCHED: 'University of Maryland Medical ",
    "System' is no ORGANIZATION NAME or DBA in the complete CMS Maryland ",
    "Hospital Enrollments file (", UMMS_ENROL, ", 57 records); its hospitals ",
    "enrol as separate legal bodies -- ", members, ". So ccn is left empty: ",
    "no enrolment is the awardee's own legal entity, and §10.2's ",
    "enrolled-operator rule does not reach it. HIGH still needs Stage 5.",
    if (!umms_blank(prior)) paste0(" PRIOR BASIS: ", prior) else "")
  d
}

umms_read_raw <- function() {
  readr::read_csv(here::here("data/reference", UMMS_FILE),
                  col_types = readr::cols(.default = "c"), na = character(),
                  progress = FALSE, show_col_types = FALSE, trim_ws = FALSE)
}

umms_apply <- function() {
  umms_assert_source()
  umms_assert_not_enrolled()
  d <- umms_read_raw()
  out <- umms_overlay(d, empty = "")
  readr::write_csv(out, here::here("data/reference", UMMS_FILE), na = "")
  invisible(out)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) umms_fetch(force = "--force" %in% args)
  if ("--apply" %in% args) { umms_apply(); cat("Patched:", UMMS_FILE, "\n") }
  if ("--report" %in% args) {
    umms_assert_source(); umms_assert_not_enrolled()
    d <- umms_read_raw()
    r <- d[d$awardee == UMMS_AWARDEE, c("awardee", "amount", "recipient_type",
                                        "flow_type", "distributed_to_hospital",
                                        "hospital_attribution", "basis_type",
                                        "determination_confidence", "ccn")]
    print(as.data.frame(r))
  }
}
