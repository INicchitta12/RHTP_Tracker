# 03f_pa_year1_awardees.R ----------------------------------------------------
# Pennsylvania Year 1 awardees -> data/reference/pa_year1_awardees.csv (+ render)
#
# WHAT THIS IS. Pennsylvania is the cleanest recipient-level award list this
# project has found (session 11's locator report). DHS publishes 66 authorized
# projects in one HTML table -- recipient, amount, project description, region,
# initiative -- and the table's own amounts sum to $42,198,309.80 against the
# $42,198,309 DHS states in the announcement. The count matches exactly.
#
# TWO DOCUMENTS, AND NEITHER SUPPORTS THE CODING ALONE. This is the Georgia
# arrangement (session 10) exactly, and it needs the same care:
#
#   - The DHS ANNOUNCEMENT (2026-07-23) supplies the award language -- "the
#     first qualified projects to RECEIVE $42 million", "sixty-six projects were
#     AUTHORIZED" -- and the state total. It names no recipient.
#   - The PROGRAM PAGE supplies the 66 names and amounts. Its own heading reads
#     "List of Eligible Projects", and read ALONE that is an eligibility list,
#     which §0.3 forbids coding as receipt.
#
# The announcement links to that page as the list of the projects it just said
# were authorized. So every row cites both, and `recipient_names_source_url`
# records which document supplied the names, exactly as Georgia's rows do.
#
# THE AWARDS ARE AUTHORIZED, NOT YET DISBURSED, AND THAT IS RECORDED. The
# announcement says "Distribution is pending approval of selected projects."
# That makes these NOTICE_OF_INTENT_TO_AWARD, not NOTICE_OF_AWARD -- both are
# primary under §8 and both can support a Yes, but they are different documents
# and flattening them would lose the distinction a reviewer needs. Every row
# carries `amount_confirmed = Yes` (the state published the figure) and
# `disbursement_status = PENDING_APPROVAL`.
#
# CLASSIFICATION IS NOT DONE HERE. recipient_type, flow_type and
# distributed_to_hospital come from R/utils_recipient_classification.R, which
# holds the §8/§10.2 rules for every state so they cannot drift apart.
#
# SESSION 112 (2026-11-02): THE PAGE GREW FROM 66 ROWS TO 178. DHS re-published
# the selected-projects table with a sixth column, 'Funding Opportunity', and
# five sections: Rapid Response Stablization Round 1 (the original 66, name for
# name and cent for cent), Round 2 (71), EHR & HIO (22), FQHC & FQH Look-Alikes
# (4) and Year One Non-Solicitation (15) -- $116,840,877.67 in all. The page
# calls every row an "authorized project"; nothing on it says any section is
# disbursed, and no DHS announcement for the four new sections was readable
# (the newsroom is a JavaScript application). So Round 1 keeps its
# announcement-backed coding (PENDING_APPROVAL) and the new rows rest on the
# page alone: NOTICE_OF_INTENT_TO_AWARD, disbursement_status = AUTHORIZED.
#
# THE PAGE'S HEADER IS STALE: "Total Awarded to Date: $43,000,000" above
# $116.8M of rows. Recorded in the reconciliation, never adopted; no ROW
# contradicts itself, so nothing is SOURCE_SUSPECT (that flag is per row).
#
# THE NEW ROWS ARE TYPED ON CMS PA ENROLMENT (R/03bq's method): an exact
# organisation or DBA string on CMS's PA Hospital or FQHC Enrollments types the
# row MEDIUM; hand-read bridges are LOW; system parents are LOW +
# GENERAL_KNOWLEDGE; a university is not a hospital unless its legal entity is
# enrolled (University of Pennsylvania: the Trustees' entity IS enrolled, CCN
# 390111, and the row is held at UNIVERSITY_OR_AHC for the owner -- see
# PA_NEW_OVERRIDES). The classifier's Round 1 coding is untouched.
#
# THE GUTHRIE CLINIC ($2,963,576.93, Year One Non-Solicitation) is the same
# award as the two CMS obligation lines R/03cb wrote to
# pa_cms_obligation_awardees.csv ($2,963,577.00, the Pulse Center Pilot). The
# state source wins: R/03cb now records those lines as SUPERSEDED and writes no
# PA row, so the award is counted once, here.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only -- never |>. No setwd(); all
# paths go through here::here(). --fetch is the only mode that touches the
# network; everything else reads the committed archive.
#
# CLI:
#   Rscript R/03f_pa_year1_awardees.R --fetch     # archive both sources + SHA-256
#   Rscript R/03f_pa_year1_awardees.R --validate  # parse + assert, no writes
#   Rscript R/03f_pa_year1_awardees.R --build     # assert, write CSV + xlsx

suppressPackageStartupMessages({
  library(dplyr)
  library(openxlsx)
  library(purrr)
  library(readr)
  library(rvest)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

PA_STATE <- "PA"

PA_ANNOUNCEMENT_URL <-
  "https://www.pa.gov/agencies/dhs/newsroom/supporting-rural-health-care"
PA_PROJECTS_URL <- paste0(
  "https://www.pa.gov/agencies/dhs/programs-services/healthcare/rural-health/",
  "rural-health-selected-projects"
)

PA_ANNOUNCEMENT_FILE <- "2026-07-23_dhs_supporting_rural_health_care.html"
PA_PROJECTS_FILE     <- "2026-11-02_dhs_rural_health_selected_projects.html"
# The 2026-08-28 archive Round 1 was first coded from. Kept, and re-parsed by
# rhtp_pa_assert() to prove Round 1 did not move.
PA_PROJECTS_FILE_PRIOR <- "2026-08-28_dhs_rural_health_selected_projects.html"
PA_PROJECTS_SHA256 <- "039a17c1b5d8c87d137e78b64bf6e370f95f38833a479a3f2ae3d0492d437bf9"
PA_MANIFEST_FILE     <- "pa_rhtp_year1_awards.manifest.txt"

PA_EVIDENCE_DIR <- "data/evidence/PA"
PA_CSV  <- "data/reference/pa_year1_awardees.csv"
PA_XLSX <- "PA_year1_awardees.xlsx"

# What DHS itself states, and what this file must reproduce or fail. Held as
# constants so an assertion can name the published figure rather than a literal
# buried in a comparison (§13 asserts against the state's own words).
PA_STATED_PROJECT_COUNT <- 66L           # Round 1, per the announcement
PA_STATED_TRANCHE_TOTAL <- 42198309      # "$42,198,309" (Round 1)
PA_STATED_YEAR1_AWARD   <- 193294053.98  # the CMS award named in the footnote

# Session 112: the 2026-11-02 page, pinned by section. A page that moves any of
# these fails the build and is re-read, never re-pinned blind.
PA_ROUND1 <- "Rapid Response Stablization - Round 1"
PA_SECTIONS <- tibble::tribble(
  ~funding_opportunity,                                                                       ~rows, ~total,
  "Rapid Response Stablization - Round 1",                                                    66L,   42198309.80,
  "Rapid Response Stablization - Round 2",                                                    71L,   25853962.10,
  "EHR & HIO - Modernizing Healthcare Technology and Enabling Interoperability",             22L,    1733579.20,
  "FQHC & FQH Look-Alikes - Modernizing Healthcare Technology and Enabling Interoperability",  4L,    1179232.33,
  "Year One Non-Solicitation",                                                                15L,   45875794.24)
PA_PAGE_ROWS  <- 178L
PA_PAGE_TOTAL <- 116840877.67
# The page's own header. STALE: it contradicts the rows it sits above.
PA_PAGE_HEADER_TOTAL <- 43000000         # "Total Awarded to Date: $43,000,000"

PA_FED_HOSP <- file.path("data", "evidence", "federal_records", "2026-09-25",
                         "cms_hosp_enrollments_PA.json")
PA_FED_FQHC <- file.path("data", "evidence", "federal_records", "2026-10-12",
                         "cms_fqhc_enrollments_PA.json")

# Hand-read decisions for the NEW rows (session 112). Everything else is an
# exact CMS PA enrolment match or the shared classifier's reading of the
# state's own string. Keyed on the exact awardee string.
PA_NEW_OVERRIDES <- tibble::tribble(
  ~awardee, ~recipient_type, ~basis_type, ~confidence, ~ccn, ~why,
  "Guthrie Troy Community Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "391305",
  "HAND-READ ENROLMENT BRIDGE: CMS PA Hospital Enrollments carries TROY COMMUNITY HOSPITAL INCORPORATED, Troy, CCN 391305 (critical access hospital); the state's string prefixes its system name. LOW.",
  "Barnes Kasson Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "391309",
  "HAND-READ ENROLMENT BRIDGE: CMS PA Hospital Enrollments carries BARNES-KASSON COUNTY HOSPITAL, Susquehanna, CCN 391309 (critical access hospital); the state's string drops 'County' and the hyphen. LOW.",
  "Sharon Regional Health System", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", "390211",
  "HAND-READ BRIDGE (GENERAL_KNOWLEDGE): no CMS PA enrolment carries this string; CMS enrols TENOR HEALTH FOUNDATION SHARON, LLC dba SHARON REGIONAL MEDICAL CENTER, Sharon, CCN 390211, and 'Sharon Regional Health System' is that hospital's former system name, read from general knowledge. LOW and subtractable.",
  "St. Luke's Miners Rehabilitation & Nursing Center at Carbon Schuylkill Community Hospital Inc.", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "390183",
  "HAND-READ ENROLMENT BRIDGE: the string names its legal entity, 'Carbon Schuylkill Community Hospital Inc.', which CMS PA Hospital Enrollments carries as THE CARBON-SCHUYLKILL COMMUNITY HOSPITAL, INC. dba ST. LUKE'S MINERS MEMORIAL HOSPITAL, Coaldale, CCN 390183 (the same entity as Round 1's Carbon Schuylkill row). The nursing centre is a unit of that hospital entity; §0.3a, the setting does not decide it. LOW.",
  "Penn State Health", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", NA,
  "SYSTEM PARENT, GENERAL KNOWLEDGE (the SD Sanford/Avera treatment): Penn State Health is the parent system of THE MILTON S HERSHEY MEDICAL CENTER, PENN STATE HEALTH HOLY SPIRIT MEDICAL CENTER and its other hospitals, which enrol under their own legal entities; 'Penn State Health' itself is not on CMS's PA Hospital Enrollments, so no CCN. LOW.",
  "The Guthrie Clinic", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", NA,
  "SYSTEM PARENT, GENERAL KNOWLEDGE (owner ruling 2026-10-12, session 98, carried over from R/03cb): The Guthrie Clinic (Sayre) is the parent system of Robert Packer Hospital, Troy Community Hospital and Guthrie's other hospitals, which enrol under their own legal entities; 'The Guthrie Clinic' is not on CMS's PA Hospital Enrollments, so no CCN. LOW. THE SAME AWARD as CMS obligation lines PA-005-20-59 + PA-005-21-60 ($2,963,577.00, the Pulse Center Pilot), which R/03cb now records as superseded by this row.",
  "The Hospital and Health System Association of Pennsylvania", "NONPROFIT_CBO", "STATE_SOURCE", "MEDIUM", NA,
  "A HOSPITAL ASSOCIATION, NOT A HOSPITAL (the classifier read 'Hospital' in the name; §10.2 association row). The page says 'HAP will conduct a Career Exploration Program ... educating and recruiting rural high school students': the association performs the work and no sentence moves money to member hospitals, so §10.2's association negative applies: NON_HOSPITAL.",
  "University of Pennsylvania", "UNIVERSITY_OR_AHC", "STATE_SOURCE", "MEDIUM", NA,
  "HELD FOR THE OWNER, NOT RE-TYPED: CMS PA Hospital Enrollments carries TRUSTEES OF THE UNIVERSITY OF PENNSYLVANIA dba HOSPITAL OF THE UNIVERSITY OF PENNSYLVANIA, CCN 390111 -- the university's own corporate body. Under §10.2's enrolled-operator rule that could make this an ACADEMIC_HEALTH_CENTER hospital row (LOW, a hand bridge: the string is a truncation of the legal name), but the string names the university, the award is a statewide addiction Bridge Clinic shared with University of Pittsburgh Physicians, and session 110's ruling (a) keeps a school/programme string out. Coded as the university the string names; +$1,097,821.56 to NAMED_HOSPITAL if the owner bridges it.",
  "University of Pittsburgh Physicians", "PHYSICIAN_PRACTICE", "GENERAL_KNOWLEDGE", "LOW", NA,
  "A physician practice plan (UPMC's academic physician group), read from general knowledge; the string names physicians, not the university, and no CMS PA Hospital Enrollment carries it. Not a hospital.",
  "Guthrie Medical Group - Laboratories", "PHYSICIAN_PRACTICE", "GENERAL_KNOWLEDGE", "LOW", NA,
  "A medical group's laboratory (Guthrie's physician group), read from general knowledge; no CMS PA Hospital Enrollment carries it, and a sub-unit string is not the system parent (session 110 ruling a). Not a hospital.",
  "WellSpan Maternal Fetal Medicine - Chambersburg", "PHYSICIAN_PRACTICE", "GENERAL_KNOWLEDGE", "LOW", NA,
  "A WellSpan specialty practice (its description names three WellSpan OB/GYN and MFM practice sites), read from general knowledge; no CMS PA Hospital Enrollment carries it, and a practice string is not the system parent (session 110 ruling a). Not a hospital.",
  "St. Luke's Penn Foundation Psychiatric Associates - Tamaqua", "PHYSICIAN_PRACTICE", "GENERAL_KNOWLEDGE", "LOW", NA,
  "A psychiatric practice ('Psychiatric Associates') of St. Luke's Penn Foundation, read from the string and general knowledge; no CMS PA Hospital Enrollment carries it. Not a hospital.",
  "Penn Highlands Clearfield E.M.S.", "EMS_OR_PSAP", "STATE_SOURCE", "MEDIUM", NA,
  "An EMS service ('E.M.S.' in the state's own string); the award buys 11 non-emergency medical transport vehicles. No CMS PA Hospital Enrollment carries 'Penn Highlands Clearfield', so the hospital-operated-EMS reading (owner ruling c, session 109: Magnolia's EMS on its hospital's CCN) has no enrolment to stand on. Not a hospital row.",
  "WRC Pennsylvania Memorial Home dba McKinley Health Center", "OTHER", "GENERAL_KNOWLEDGE", "LOW", NA,
  "Determined form: a nursing home ('Memorial Home'; McKinley Health Center, Brookville, is a skilled nursing facility), read from the string and general knowledge. 'Memorial' and 'Health Center' are not a hospital here: no CMS PA Hospital or FQHC Enrollment carries either half of the string. Not a hospital.",
  "Peritech Home Health Associates, LLC. dba Angels of Care Pediatrics", "OTHER", "STATE_SOURCE", "MEDIUM", NA,
  "Determined form: a home health agency ('Home Health' in the state's own string). Not a hospital.")

# Name patterns that state a form in the state's own string (new rows only).
PA_NEW_FORM_PATTERNS <- tibble::tribble(
  ~pattern, ~recipient_type, ~form,
  "Physician Group|Physician Services", "PHYSICIAN_PRACTICE", "a physician practice ('Physician Group' / 'Physician Services' in the state's own string)",
  "Fire Department|Fire Company|Ambulance|\\bEMS\\b|Emergency Medical Services", "EMS_OR_PSAP", "a fire, ambulance or EMS service (in the state's own string)",
  "Pharmacy", "OTHER", "a pharmacy ('Pharmacy' in the state's own string)",
  "Nursing", "OTHER", "a nursing home ('Nursing' in the state's own string)")


# -- Fetch and archive -------------------------------------------------------

#' Fetch both Pennsylvania sources and archive them with SHA-256
#'
#' Parses BEFORE writing, so a page redesign fails loudly instead of replacing a
#' good archive with an unparseable one -- the R/00 posture.
rhtp_pa_fetch <- function(force = FALSE) {
  cfg <- rhtp_config()
  dir <- here::here(PA_EVIDENCE_DIR)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)

  get_one <- function(url, file) {
    path <- file.path(dir, file)
    if (file.exists(path) && !force) {
      message("  already archived: ", file, " -- pass --force to re-fetch.")
      return(list(path = path, body = readr::read_file(path), status = NA_integer_))
    }
    resp <- httr2::request(url) %>%
      httr2::req_user_agent(cfg$api$user_agent) %>%
      httr2::req_timeout(cfg$api$timeout_seconds) %>%
      httr2::req_retry(max_tries = 3, backoff = ~ 2^.x) %>%
      httr2::req_perform()

    status <- httr2::resp_status(resp)
    if (status != 200) {
      stop("[PA] ", url, " returned HTTP ", status,
           "; refusing to archive a non-200 body.", call. = FALSE)
    }
    list(path = path, body = httr2::resp_body_string(resp), status = status)
  }

  announcement <- get_one(PA_ANNOUNCEMENT_URL, PA_ANNOUNCEMENT_FILE)
  projects     <- get_one(PA_PROJECTS_URL, PA_PROJECTS_FILE)

  parsed <- rhtp_pa_parse_projects(projects$body)
  if (nrow(parsed) != PA_STATED_PROJECT_COUNT) {
    stop("[PA] the selected-projects table parsed to ", nrow(parsed),
         " rows; DHS states ", PA_STATED_PROJECT_COUNT,
         ". Refusing to archive a parse that does not match the state's own ",
         "count.", call. = FALSE)
  }

  # writeBin, not writeLines. writeLines appends a trailing newline, which makes
  # the archived file one byte longer than the body that was digested -- so the
  # manifest's sha256 would not verify against the file a reader has in hand.
  # Writing the bytes exactly is what makes the digest checkable offline, and a
  # test does check it.
  writeBin(charToRaw(announcement$body), announcement$path)
  writeBin(charToRaw(projects$body), projects$path)

  sha <- function(x) digest::digest(x, algo = "sha256", serialize = FALSE)
  nbytes <- function(x) nchar(x, type = "bytes")

  writeLines(paste0(
    "RHTP tracker archive (spec 0.4 / 0.5): Pennsylvania RHTP Year 1, first\n",
    "tranche of authorized projects.\n\n",
    "fetched_utc     : ", format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), "\n",
    "state           : PA\n",
    "host            : www.pa.gov\n",
    "program         : Pennsylvania Rural Health Transformation Plan (RHTP)\n",
    "cms_year1_award : $193,294,053.98 (stated in the announcement's footnote)\n",
    "tranche_total   : $42,198,309 stated; $42,198,309.80 summed from the table\n",
    "projects        : ", PA_STATED_PROJECT_COUNT, " stated; ", nrow(parsed), " parsed\n\n",
    "FILES\n\n",
    "  file    : ", PA_ANNOUNCEMENT_FILE, "\n",
    "  role    : the AWARD LANGUAGE and the state total. Names no recipient.\n",
    "  title   : Supporting Rural Health Care: Shapiro Administration Announces\n",
    "            $42 Million to Support Technology and Infrastructure\n",
    "            Improvements, Upgrades for Rural Hospitals, Emergency\n",
    "            Medicine, and Health Care Providers\n",
    "  date    : 2026-07-23\n",
    "  url     : ", PA_ANNOUNCEMENT_URL, "\n",
    "  bytes   : ", nbytes(announcement$body), "\n",
    "  sha256  : ", sha(announcement$body), "\n\n",
    "  file    : ", PA_PROJECTS_FILE, "\n",
    "  role    : the 66 RECIPIENT NAMES and AMOUNTS. Supplies no award\n",
    "            language of its own -- its heading reads 'List of Eligible\n",
    "            Projects'.\n",
    "  title   : Rural Health Selected Projects\n",
    "  url     : ", PA_PROJECTS_URL, "\n",
    "  bytes   : ", nbytes(projects$body), "\n",
    "  sha256  : ", sha(projects$body), "\n\n",
    "WHAT THESE DOCUMENTS SUPPORT (spec 9.2, Part A of reviewer-coding-instructions)\n\n",
    "NEITHER DOCUMENT SUPPORTS THE CODING ALONE, and this is the same shape as\n",
    "Georgia's AHEAD roster (session 10). The program page read by itself is an\n",
    "ELIGIBILITY list, and §0.3 forbids coding eligibility as receipt. The\n",
    "announcement read by itself names no recipient. Together the announcement\n",
    "says sixty-six projects were AUTHORIZED to RECEIVE the money and links to\n",
    "this page as the list of them. Every row cites both.\n\n",
    "THESE ARE AUTHORIZATIONS, NOT DISBURSEMENTS. The announcement states\n",
    "'Distribution is pending approval of selected projects.' Rows therefore\n",
    "carry validation_source_type = NOTICE_OF_INTENT_TO_AWARD and\n",
    "disbursement_status = PENDING_APPROVAL. Both intent-to-award and award are\n",
    "primary under §8; the distinction belongs in the row, not flattened away.\n\n",
    "This tranche is the FIRST of Pennsylvania's $193,294,053.98 Year 1 award.\n",
    "$42.2M of $193.3M is 21.8%; the remainder is not yet awarded and no residual\n",
    "may be inferred from it (§0.3).\n"
  ), file.path(dir, PA_MANIFEST_FILE))

  message("  archived 2 Pennsylvania sources to ", PA_EVIDENCE_DIR,
          " (", nrow(parsed), " projects parsed)")
  invisible(dir)
}


# -- Parse -------------------------------------------------------------------

#' Parse the DHS selected-projects table out of archived HTML
#'
#' The page carries exactly one <table>. That is asserted rather than assumed:
#' picking "the first table" on a page that later grows a second one is how a
#' parser silently reads the wrong thing (the session 10 lesson).
rhtp_pa_parse_projects <- function(html) {
  doc <- rvest::read_html(html)
  tables <- rvest::html_elements(doc, "table")

  if (length(tables) != 1L) {
    stop("[PA] expected exactly 1 table on the selected-projects page, found ",
         length(tables), ". Refusing to guess which one holds the awards.",
         call. = FALSE)
  }

  raw <- rvest::html_table(tables[[1]], header = TRUE, trim = TRUE)

  # The 2026-08-28 page had five columns; the 2026-11-02 page adds a sixth,
  # 'Funding Opportunity'. Both shapes are named exactly; nothing is mapped by
  # position. The five-column shape survives only so the prior archive can be
  # re-parsed to prove Round 1 did not move.
  wanted5 <- c("Name", "Total", "Project Description", "Region", "Initiative")
  wanted6 <- c(wanted5, "Funding Opportunity")
  if (identical(names(raw), wanted5)) {
    raw[["Funding Opportunity"]] <- NA_character_
  } else if (!identical(names(raw), wanted6)) {
    stop("[PA] the selected-projects table's columns are ",
         paste(sQuote(names(raw)), collapse = ", "),
         "; expected ", paste(sQuote(wanted6), collapse = ", "),
         ". Refusing to map columns by position.", call. = FALSE)
  }

  raw %>%
    dplyr::rename(
      awardee = "Name",
      amount_raw = "Total",
      project_description = "Project Description",
      region = "Region",
      initiative_raw = "Initiative",
      funding_opportunity = "Funding Opportunity"
    ) %>%
    dplyr::mutate(
      dplyr::across(dplyr::everything(),
                    ~ stringr::str_squish(stringr::str_replace_all(.x, " ", " "))),
      amount = readr::parse_number(.data$amount_raw)
    ) %>%
    dplyr::filter(nzchar(.data$awardee))
}


# -- Typing the new rows on CMS PA enrolment (session 112) -------------------

pa_norm <- function(x) {
  x <- toupper(gsub("[’']", "", x))
  x <- gsub("&", " AND ", x, fixed = TRUE)
  x <- stringr::str_squish(gsub("[^A-Z0-9 ]", " ", x))
  x <- sub("^THE ", "", x)
  stringr::str_squish(gsub("\\b(INC|INCORPORATED|LLC|CORP|CORPORATION)\\b", " ", x))
}

pa_halves <- function(a) {
  parts <- stringr::str_split(a, stringr::regex("\\s+(dba\\.?|d/b/a)\\s+",
                                                ignore_case = TRUE))[[1]]
  unique(pa_norm(c(a, parts)))
}

pa_federal <- function() {
  rd <- function(f, k) {
    j <- jsonlite::fromJSON(here::here(f))
    tibble::tibble(kind = k, ccn = as.character(j$CCN),
                   org = j$`ORGANIZATION NAME`, dba = j$`DOING BUSINESS AS NAME`,
                   city = j$CITY, ptype = j$`PROVIDER TYPE TEXT`)
  }
  dplyr::bind_rows(rd(PA_FED_HOSP, "HOSPITAL"), rd(PA_FED_FQHC, "FQHC"))
}

#' Type one NEW row: hand-read override, then an exact CMS PA enrolment
#' string, then a form the state's own string states, then the classifier --
#' which may not by itself make a hospital.
pa_type_new <- function(awardee, cls_type, cls_conf, f) {
  ov <- PA_NEW_OVERRIDES[PA_NEW_OVERRIDES$awardee == awardee, ]
  if (nrow(ov)) {
    return(tibble::tibble(recipient_type = ov$recipient_type,
                          basis_type = ov$basis_type,
                          determination_confidence = ov$confidence,
                          ccn = ov$ccn, why = ov$why, typing = "HAND-READ",
                          fallback = FALSE, enrolment = NA_character_))
  }
  h <- pa_halves(awardee)
  hit <- f[pa_norm(f$org) %in% h | pa_norm(dplyr::coalesce(f$dba, "")) %in% h, ]
  if (nrow(hit)) {
    k <- if ("HOSPITAL" %in% hit$kind) "HOSPITAL" else "FQHC"
    hk <- hit[hit$kind == k, ]
    six <- sort(unique(hk$ccn[grepl("^[0-9]{6}$", hk$ccn)]))
    one <- k == "HOSPITAL" && length(six) == 1L
    rec <- hk %>% dplyr::distinct(.data$org, .data$dba, .data$city) %>% dplyr::slice(1)
    enrol <- paste0("CMS PA ", c(HOSPITAL = "Hospital", FQHC = "FQHC")[[k]],
                    " Enrollments: ", rec$org,
                    if (!is.na(rec$dba) && nzchar(rec$dba)) paste0(" dba ", rec$dba) else "",
                    ", ", rec$city,
                    if (k == "HOSPITAL") paste0(", CCN ", paste(six, collapse = "/")) else "",
                    "; ", if (k == "HOSPITAL") PA_FED_HOSP else PA_FED_FQHC)
    return(tibble::tibble(
      recipient_type = if (k == "HOSPITAL") "HOSPITAL_OR_SYSTEM" else "FQHC_OR_RHC",
      basis_type = "ORG_WEBSITE", determination_confidence = "MEDIUM",
      ccn = if (one) six else NA_character_,
      why = paste0("EXACT federal record: the state's string (or a half of its ",
                   "DBA) is carried by ", enrol, ".",
                   if (k == "HOSPITAL" && !one) " More than one hospital CCN on the entity; ccn left for Stage 5." else ""),
      typing = "FEDERAL RECORD", fallback = FALSE, enrolment = enrol))
  }
  fp <- PA_NEW_FORM_PATTERNS[vapply(PA_NEW_FORM_PATTERNS$pattern, grepl,
                                    logical(1), x = awardee, ignore.case = TRUE), ]
  if (nrow(fp)) {
    return(tibble::tibble(recipient_type = fp$recipient_type[1],
                          basis_type = "STATE_SOURCE",
                          determination_confidence = "MEDIUM", ccn = NA_character_,
                          why = paste0("Determined form: ", fp$form[1], ". No CMS PA ",
                                       "Hospital or FQHC Enrollment carries the string."),
                          typing = "STATE STRING", fallback = FALSE,
                          enrolment = NA_character_))
  }
  if (cls_type == "HOSPITAL_OR_SYSTEM") {
    stop("[PA] the classifier calls '", awardee, "' a hospital and no CMS PA ",
         "enrolment or hand-read decision covers it. Read it and add it to ",
         "PA_NEW_OVERRIDES.", call. = FALSE)
  }
  tibble::tibble(
    recipient_type = cls_type,
    basis_type = if (cls_conf == "LOW") NA_character_ else "STATE_SOURCE",
    determination_confidence = cls_conf, ccn = NA_character_,
    why = paste0("No CMS PA Hospital or FQHC Enrollment carries the string; the ",
                 "shared classifier's reading (", cls_type, "/", cls_conf, ")",
                 if (cls_conf == "LOW") ": §8's standing fallback, form not stated." else "."),
    typing = "CLASSIFIER", fallback = cls_conf == "LOW" && cls_type == "NONPROFIT_CBO",
    enrolment = NA_character_)
}


#' The Pennsylvania award records, built from the committed archives
rhtp_pa_build <- function() {
  projects_path <- here::here(PA_EVIDENCE_DIR, PA_PROJECTS_FILE)
  if (!file.exists(projects_path)) {
    stop("[PA] the selected-projects archive is missing: ", projects_path,
         ". Run --fetch first.", call. = FALSE)
  }
  raw <- readr::read_file_raw(projects_path)
  if (digest::digest(raw, algo = "sha256", serialize = FALSE) != PA_PROJECTS_SHA256) {
    stop("[PA] the archived selected-projects page's SHA-256 does not match ",
         "PA_PROJECTS_SHA256 (the manifest).", call. = FALSE)
  }

  parsed <- rhtp_pa_parse_projects(rawToChar(raw))
  is_r1 <- parsed$funding_opportunity == PA_ROUND1

  classified <- parsed %>%
    rhtp_classify_records(state = PA_STATE,
                          description_col = "project_description")

  # Round 1: exactly the coding sessions 11-111 published.
  r1 <- classified[is_r1, ] %>%
    dplyr::mutate(
      source_document_title = paste0(
        "Supporting Rural Health Care: Shapiro Administration Announces $42 ",
        "Million to Support Technology and Infrastructure Improvements, ",
        "Upgrades for Rural Hospitals, Emergency Medicine, and Health Care ",
        "Providers"
      ),
      state_source_url = PA_ANNOUNCEMENT_URL,
      ccn = NA_character_,
      recipient_type_source = NA_character_,
      disbursement_status = "PENDING_APPROVAL",
      source_archive_path = file.path(PA_EVIDENCE_DIR, PA_ANNOUNCEMENT_FILE),
      basis_type = NA_character_,
      cms_enrolment_record = NA_character_,
      determination_basis = paste0(
        .data$determination_basis,
        " Source: PA DHS announced 66 authorized projects on 2026-07-23; the ",
        "names and amounts are from the DHS Rural Health Selected Projects ",
        "page it links to. Distribution is pending approval of selected ",
        "projects, so this is an intent to award."
      )
    )

  # The new sections: typed on CMS PA enrolment.
  nw <- classified[!is_r1, ]
  f <- pa_federal()
  t <- purrr::pmap_dfr(list(nw$awardee, nw$recipient_type,
                            nw$determination_confidence),
                       function(a, ct, cc) pa_type_new(a, ct, cc, f))
  hosp <- t$recipient_type == "HOSPITAL_OR_SYSTEM"
  nw <- nw %>%
    dplyr::mutate(
      recipient_type = t$recipient_type,
      determination_confidence = rhtp_confidence_ceiling(t$determination_confidence),
      flow_type = ifelse(hosp, "DIRECT", "NON_HOSPITAL"),
      distributed_to_hospital = ifelse(hosp, "Yes", "No"),
      hospital_benefiting = ifelse(hosp, "Yes", "Unclear"),
      flag_reason = ifelse(t$fallback, "RECIPIENT_TYPE_INFERRED", NA_character_),
      classification_rule = paste0("S112_", gsub(" ", "_", t$typing)),
      source_document_title = paste0("PA DHS, Rural Health Selected Projects ",
                                     "(as archived 2026-11-02): ",
                                     .data$funding_opportunity),
      state_source_url = PA_PROJECTS_URL,
      ccn = t$ccn,
      recipient_type_source = paste0("TYPED (session 112, ", t$typing, "): ", t$why),
      disbursement_status = "AUTHORIZED",
      source_archive_path = file.path(PA_EVIDENCE_DIR, PA_PROJECTS_FILE),
      basis_type = t$basis_type,
      cms_enrolment_record = t$enrolment,
      determination_basis = paste0(
        "§10.2 ", ifelse(hosp, "DIRECT", "NON_HOSPITAL"), ": ", t$why,
        ifelse(hosp, " §0.3a: the recipient is a hospital whatever the activity.",
               " Judged on the recipient, not the activity (§0.3a)."),
        " Source: PA DHS's Rural Health Selected Projects page (archived ",
        "2026-11-02) lists this recipient, amount, region and initiative under ",
        "the funding opportunity '", .data$funding_opportunity, "' among its ",
        "'authorized projects'. No DHS announcement for this section was read; ",
        "the page states no disbursement, so this is an intent to award. The ",
        "page header's 'Total Awarded to Date: $43,000,000' is stale against ",
        "its own rows and is not adopted.")
    )

  dplyr::bind_rows(r1, nw) %>%
    dplyr::mutate(
      state = PA_STATE,
      row_no = dplyr::row_number(),
      note = paste0(.data$initiative_raw, " | ", .data$region, " region"),
      recipient_confirmed = "Yes",
      amount_confirmed = "Yes",
      fiscal_year = "FY2026 (Year 1)",
      validation_source_type = "NOTICE_OF_INTENT_TO_AWARD",
      extraction_method = "MODEL_ASSISTED",
      validator = "AI-assisted - CONFIRM",
      aha_id = NA_character_,
      rural_designation = NA_character_,
      reviewer = NA_character_,
      amount_basis = "PER_RECIPIENT",
      amount_precision = "EXACT_AS_PUBLISHED",
      recipient_names_source_url = PA_PROJECTS_URL,
      activity_type_raw = .data$initiative_raw
    ) %>%
    dplyr::select(
      # -- the FL_year1_awardees schema, in FL's order --------------------
      "state", "row_no", "awardee", "amount", "recipient_type",
      "distributed_to_hospital", "note", "recipient_confirmed",
      "amount_confirmed", "fiscal_year", "source_document_title",
      "state_source_url", "validation_source_type", "extraction_method",
      "validator", "ccn", "aha_id", "rural_designation", "reviewer",
      "recipient_type_source", "determination_confidence", "flag_reason",
      # -- appended, on the Georgia precedent ----------------------------
      "flow_type", "hospital_benefiting", "determination_basis",
      "source_archive_path", "recipient_names_source_url", "amount_basis",
      "amount_precision", "disbursement_status", "classification_rule",
      "activity_type_raw",
      # -- Pennsylvania's own fields -------------------------------------
      "region", "initiative_raw", "project_description",
      # -- session 112 ----------------------------------------------------
      "funding_opportunity", "basis_type", "cms_enrolment_record"
    )
}


rhtp_pa_records <- function(path = PA_CSV) {
  full <- here::here(path)
  if (!file.exists(full)) {
    stop("[PA] ", path, " does not exist. Run --build.", call. = FALSE)
  }
  readr::read_csv(full, show_col_types = FALSE, progress = FALSE)
}


# -- Reconciliation and assertions -------------------------------------------

rhtp_pa_reconcile <- function(records = rhtp_pa_build()) {
  summed <- sum(records$amount)
  r1 <- records[records$funding_opportunity == PA_ROUND1, ]
  yes <- records$distributed_to_hospital == "Yes"
  low <- yes & records$determination_confidence == "LOW"
  gk <- yes & records$basis_type %in% "GENERAL_KNOWLEDGE"
  fmt <- function(x) formatC(x, format = "f", digits = 2, big.mark = ",")
  by_section <- records %>%
    dplyr::group_by(.data$funding_opportunity) %>%
    dplyr::summarise(rows = dplyr::n(), dollars = sum(.data$amount),
                     hosp_rows = sum(.data$distributed_to_hospital == "Yes"),
                     hosp_dollars = sum(.data$amount[.data$distributed_to_hospital == "Yes"]),
                     .groups = "drop")
  dplyr::bind_rows(
    tibble::tribble(
      ~measure,                                  ~value,
      "rows on the 2026-11-02 page",             as.character(nrow(records)),
      "rows summed",                             fmt(summed),
      "page header 'Total Awarded to Date' (STALE, not adopted)", fmt(PA_PAGE_HEADER_TOTAL),
      "rows minus stale header",                 fmt(summed - PA_PAGE_HEADER_TOTAL),
      "Round 1 projects stated by DHS",          as.character(PA_STATED_PROJECT_COUNT),
      "Round 1 projects extracted",              as.character(nrow(r1)),
      "Round 1 tranche stated by DHS",           fmt(PA_STATED_TRANCHE_TOTAL),
      "Round 1 summed from the table",           fmt(sum(r1$amount)),
      "CMS Year 1 award",                        fmt(PA_STATED_YEAR1_AWARD),
      "all rows as a share of Year 1",           paste0(round(100 * summed / PA_STATED_YEAR1_AWARD, 2), "%"),
      "rows distributed_to_hospital = Yes",      as.character(sum(yes)),
      "dollars distributed_to_hospital = Yes",   fmt(sum(records$amount[yes])),
      "  of which LOW (subtractable)",           paste0(sum(low), " / ", fmt(sum(records$amount[low]))),
      "  of which GENERAL_KNOWLEDGE",            paste0(sum(gk), " / ", fmt(sum(records$amount[gk]))),
      "rows distributed_to_hospital = Unclear",  as.character(sum(records$distributed_to_hospital == "Unclear"))
    ),
    tibble::tibble(
      measure = paste0("section: ", by_section$funding_opportunity),
      value = paste0(by_section$rows, " rows / $", fmt(by_section$dollars),
                     "; hospital ", by_section$hosp_rows, " / $",
                     fmt(by_section$hosp_dollars))))
}


rhtp_pa_assert <- function(records = rhtp_pa_build()) {
  if (nrow(records) != PA_PAGE_ROWS) {
    stop("[PA] ", nrow(records), " rows; the 2026-11-02 page carries ",
         PA_PAGE_ROWS, ".", call. = FALSE)
  }
  if (abs(sum(records$amount) - PA_PAGE_TOTAL) > 0.005) {
    stop("[PA] the rows sum to ", format(sum(records$amount), nsmall = 2),
         " against the pinned ", PA_PAGE_TOTAL, ".", call. = FALSE)
  }

  sec <- records %>%
    dplyr::group_by(.data$funding_opportunity) %>%
    dplyr::summarise(rows_got = dplyr::n(), total_got = sum(.data$amount),
                     .groups = "drop") %>%
    dplyr::full_join(PA_SECTIONS, by = "funding_opportunity")
  if (any(is.na(sec$rows) | is.na(sec$rows_got) | sec$rows != sec$rows_got |
          abs(sec$total - sec$total_got) > 0.005)) {
    stop("[PA] a funding-opportunity section moved: ",
         paste(sec$funding_opportunity, collapse = "; "), call. = FALSE)
  }

  # One row per recipient PER SECTION. Bucktail Medical Center is in Round 1
  # ($78,895) and EHR & HIO ($70,000): two awards, both kept.
  key <- paste(records$awardee, records$funding_opportunity, sep = " | ")
  if (anyDuplicated(key)) {
    stop("[PA] a recipient repeats inside one section: ",
         paste(unique(key[duplicated(key)]), collapse = "; "), call. = FALSE)
  }

  # Round 1 is the 66-project tranche DHS announced, to the dollar, and is
  # name-for-name and cent-for-cent the 2026-08-28 archive.
  r1 <- records[records$funding_opportunity == PA_ROUND1, ]
  stopifnot(nrow(r1) == PA_STATED_PROJECT_COUNT)
  if (abs(sum(r1$amount) - PA_STATED_TRANCHE_TOTAL) > 1) {
    stop("[PA] Round 1 sums to ", format(sum(r1$amount), nsmall = 2),
         " against DHS's stated ", PA_STATED_TRANCHE_TOTAL, ".", call. = FALSE)
  }
  prior <- rhtp_pa_parse_projects(readr::read_file(
    here::here(PA_EVIDENCE_DIR, PA_PROJECTS_FILE_PRIOR)))
  if (!identical(prior$awardee, r1$awardee) ||
      !isTRUE(all.equal(prior$amount, r1$amount))) {
    stop("[PA] Round 1 on the 2026-11-02 page differs from the 2026-08-28 ",
         "archive. Read both before re-pinning.", call. = FALSE)
  }

  if (any(records$amount <= 0)) {
    stop("[PA] every project must carry a positive amount.", call. = FALSE)
  }
  # DHS: "up to $1 million was available per project" (Rapid Response), and
  # "$300,000 per program payment" (FQHC & FQHC Look-Alikes).
  rr <- grepl("^Rapid Response", records$funding_opportunity)
  if (any(records$amount[rr] > 1e6)) {
    stop("[PA] a Rapid Response amount above the stated $1,000,000 cap: ",
         paste(records$awardee[rr & records$amount > 1e6], collapse = "; "),
         call. = FALSE)
  }
  fq <- grepl("^FQHC", records$funding_opportunity)
  if (any(records$amount[fq] > 3e5)) {
    stop("[PA] an FQHC amount above the stated $300,000 cap.", call. = FALSE)
  }

  # §0.2 / §6.2: Tier 3 must never exceed the state's Tier 1 allotment.
  if (sum(records$amount) > PA_STATED_YEAR1_AWARD) {
    stop("[PA] the rows exceed the CMS Year 1 award. §6.2 ceiling.",
         call. = FALSE)
  }

  # The stale header is RECORDED, and must still be there to be recorded.
  page <- readr::read_file(here::here(PA_EVIDENCE_DIR, PA_PROJECTS_FILE))
  if (!grepl("Total Awarded to Date:", page, fixed = TRUE) ||
      !grepl("$43,000,000", page, fixed = TRUE)) {
    stop("[PA] the page header 'Total Awarded to Date: $43,000,000' is gone; ",
         "re-read the page.", call. = FALSE)
  }

  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "determination_confidence", "flag_reason", "basis_type")) {
    bad <- setdiff(stats::na.omit(unique(records[[col]])), rhtp_vocabulary(col))
    if (length(bad)) {
      stop("[PA] ", col, " outside §8: ", paste(bad, collapse = ", "),
           call. = FALSE)
    }
  }

  # §10.2: only a hospital recipient may be coded DIRECT/Yes.
  wrong <- records %>%
    dplyr::filter(.data$distributed_to_hospital == "Yes",
                  !.data$recipient_type %in% c("HOSPITAL_OR_SYSTEM",
                                               "HOSPITAL_AFFILIATED_ENTITY"))
  if (nrow(wrong)) {
    stop("[PA] distributed_to_hospital = Yes on a non-hospital recipient: ",
         paste(wrong$awardee, collapse = "; "), call. = FALSE)
  }
  # §7: HIGH needs a CCN; GENERAL_KNOWLEDGE is LOW (§0.4).
  if (any(records$determination_confidence == "HIGH")) {
    stop("[PA] nothing here is HIGH (§7).", call. = FALSE)
  }
  if (any(records$basis_type %in% "GENERAL_KNOWLEDGE" &
          records$determination_confidence != "LOW")) {
    stop("[PA] a GENERAL_KNOWLEDGE row is not LOW (§0.4).", call. = FALSE)
  }
  if (any(records$recipient_type == "OTHER" &
          !grepl("form", records$determination_basis, ignore.case = TRUE))) {
    stop("[PA] an OTHER row does not state its determined form (§8).", call. = FALSE)
  }

  if (any(is.na(records$determination_basis) |
          !nzchar(records$determination_basis))) {
    stop("[PA] determination_basis is mandatory free text (§7).", call. = FALSE)
  }

  invisible(TRUE)
}


# -- Write -------------------------------------------------------------------

rhtp_pa_write <- function() {
  records <- rhtp_pa_build()
  rhtp_pa_assert(records)

  readr::write_csv(records, here::here(PA_CSV), na = "")

  wb <- openxlsx::createWorkbook()
  add <- function(sheet, data) {
    openxlsx::addWorksheet(wb, sheet)
    openxlsx::writeData(wb, sheet, data)
    openxlsx::freezePane(wb, sheet, firstRow = TRUE)
  }
  add("Awardees", records)
  add("Reconciliation", rhtp_pa_reconcile(records))
  openxlsx::saveWorkbook(wb, here::here(PA_XLSX), overwrite = TRUE)

  message("  wrote ", PA_CSV, " and ", PA_XLSX, " (", nrow(records), " rows)")
  invisible(records)
}


# -- CLI ---------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) {
    rhtp_pa_fetch(force = "--force" %in% args)
  } else if ("--build" %in% args) {
    rhtp_pa_write()
    print(rhtp_pa_reconcile(rhtp_pa_records()), n = Inf)
  } else if ("--validate" %in% args) {
    recs <- rhtp_pa_build()
    rhtp_pa_assert(recs)
    print(rhtp_pa_reconcile(recs), n = Inf)
    message("[PA] all assertions passed.")
  } else {
    message("Usage: Rscript R/03f_pa_year1_awardees.R [--fetch|--validate|--build]")
  }
}
