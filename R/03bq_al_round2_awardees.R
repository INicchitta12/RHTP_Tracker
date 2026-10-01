#!/usr/bin/env Rscript
# 03bq_al_round2_awardees.R ---------------------------------------------------
#
# ALABAMA ROUND 2 -- 34 GRANTS, "NEARLY $55 MILLION", AND A RELEASE THAT SAYS
# IT "ROUND[S] OUT YEAR ONE" WHILE ONE OF ELEVEN INITIATIVES HAS NO AWARD.
# Session 83.
#
# Governor Ivey's 2026-10-01 release announces "the awarding of 34 grants
# totaling nearly $55 million ... as part of the second round of Alabama Rural
# Health Transformation Program (ARHTP) funding for 2026", and prints every
# recipient, amount, purpose and county list in the body of the page. Archived
# session 82 under data/evidence/recheck/2026-10-01/AL/ (MANIFEST.txt carries
# the SHA-256); this script reads only that archive.
#
# A SEPARATE FILE FROM ROUND 1, ON ARKANSAS'S PRECEDENT. al_year1_awardees.csv
# is round 1 (138 grants, 2026-08-24) and carries session 49's overlay keyed on
# ROW INDEX; appending 34 rows to it would put that overlay at risk on the next
# rebuild. The two files ARE additive -- two rounds, different awards, one
# Year 1 -- exactly as ar_year1_awardees.csv and ar_year1_round2_awardees.csv
# are. Repeat recipients (UAB, USA, Infirmary, Cahaba, Greene County, and
# others in round 1) are NOT merged across rounds: each row is one grant.
#
# THE PAGE SHAPE. Every block is a <p>. An initiative heading is a <p> whose
# whole text is one bolded name ending "Initiative". An award is a <p> opening
# with the bolded recipient, a dash and the amount. TWO TRAPS:
#   * The University of Alabama's Treat-in-Place grant is followed by a bare
#     <p> ("The project will also establish a physician-consultation
#     demonstration ...") that names NO recipient and NO amount. It is a
#     CONTINUATION of that grant's description, not a 35th grant. Round 1's
#     continuation paragraphs WERE grants ("A second grant for $176,980");
#     this one is not, and a parser reusing round 1's rule would either invent
#     a nameless award or drop a sentence. It is appended to the preceding
#     row's description and the parse refuses a continuation carrying a "$".
#   * Two names are bolded in two pieces ("Sylacauga Healthcare Authority" +
#     "DBA Coosa Valley Medical Center") and one carries the dash inside the
#     bold ("The University of Alabama –"). The bolded pieces are joined and
#     a trailing dash stripped.
#
# 13 OF THE 34 AMOUNTS ARE ROUNDED in the source ("$1.45 million"). They are
# recorded as published and flagged AMOUNT_ROUNDED_IN_SOURCE, never
# reconstructed -- round 1's rule (R/03g). The release's own figures therefore
# sum to $54,793,527 against "nearly $55 million"; the gap is reported,
# not closed.
#
# TYPING IS ON CMS'S OWN AL ENROLMENT FILES, AS COLORADO'S WAS (R/03bo). The AL
# Hospital (federal_records/2026-09-25), FQHC and RHC (2026-10-01) Enrollment
# files are archived. A recipient whose string -- or either half of a "DBA" --
# equals an enrolled ORGANIZATION NAME or DBA after case, punctuation, a
# leading THE and corporate suffixes (INC, LLC, CORP, CORPORATION) are set
# aside is typed from that record at MEDIUM. Everything else is HAND-READ in
# AL2_OVERRIDES with its reason. Notably:
#   * UAB and the University of South Alabama are left UNIVERSITY_OR_AHC here
#     and re-typed by R/03bj's EH_APPLY (EXACT_LEGAL_NAME, CCNs 010033 and
#     010087, recipient_subtype ACADEMIC_HEALTH_CENTER), exactly as their
#     round-1 rows were, so the AHC rows stay subtractable. --build chains it.
#   * The University of Alabama (Tuscaloosa) is NOT UAB (§10.2: a different
#     legal body with a similar name). UNIVERSITY_OR_AHC, $0 of hospital money.
#   * Greene County Health System (4 grants, $3,913,694) holds NO enrolment
#     under that name; CMS enrols GREENE COUNTY HOSPITAL & NURSING HOME (dba
#     GREENE COUNTY HOSPITAL, CCN 010051, Eutaw). The bridge is general
#     knowledge, so HOSPITAL_OR_SYSTEM at LOW (GENERAL_KNOWLEDGE, subtractable)
#     and queued as AL_R2_GREENE_COUNTY_HEALTH_SYSTEM_BRIDGE.
#   * Infirmary Health System Inc. holds no enrolment either (its hospitals
#     enrol as MOBILE INFIRMARY ASSOCIATION and others), but the same publisher
#     states its form: round 1's release calls it "This nonprofit health
#     system". STATE_SOURCE, MEDIUM.
#
# §0.2: the release's CMS footer prints $203,404,326.54, 100% CMS -- Alabama's
# ALLOTMENT (§7.1, $203,404,327). A Tier 1 footer on a Tier 3 announcement.
#
# Usage:
#   Rscript R/03bq_al_round2_awardees.R --validate  # parse + assert, no writes
#   Rscript R/03bq_al_round2_awardees.R --build     # write the CSV (+ R/03bj overlay)
#   Rscript R/03bq_al_round2_awardees.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

AL2_STATE      <- "AL"
AL2_ALLOTMENT  <- 203404327               # cms_fy2026_allotments.csv (§7.1)
AL2_FOOTER     <- 203404326.54            # the release's CMS footer (Tier 1)
AL2_NOA_DATE   <- as.Date("2025-12-29")
AL2_ANNOUNCED  <- as.Date("2026-10-01")
AL2_GRANTS     <- 34L                     # "the awarding of 34 grants"
AL2_HEADLINE   <- 55000000                # "nearly $55 million"
AL2_INITIATIVES <- c("Maternal and Fetal Health Initiative",
                     "EMS Trauma and Stroke Initiative",
                     "EMS Treat-in-Place Initiative",
                     "Simulation Training Initiative",
                     "Cancer Digital Regionalization Initiative",
                     "Rural Health Initiative",
                     "Rural Workforce Initiative")
AL2_URL <- paste0("https://governor.alabama.gov/newsroom/2026/10/governor-ivey-",
                  "announces-additional-alabama-rural-health-transformation-",
                  "program-grants-totaling-nearly-55-million/")
AL2_ARCHIVE <- file.path("data", "evidence", "recheck", "2026-10-01", "AL",
                         "al_governor_2026-10-01_round2_34_grants.html")
AL2_SHA256  <- "caa366d956cf7691fc6ca9e7cd49091ed294e685f0fab54ced1c7d9f48bb88d1"
AL2_CSV     <- here::here("data", "reference", "al_year1_round2_awardees.csv")
AL2_FED_HOSP <- file.path("data", "evidence", "federal_records", "2026-09-25",
                          "cms_hosp_enrollments_AL.json")
AL2_FED_FQHC <- file.path("data", "evidence", "federal_records", "2026-10-01",
                          "cms_fqhc_enrollments_AL.json")
AL2_FED_RHC  <- file.path("data", "evidence", "federal_records", "2026-10-01",
                          "cms_rhc_enrollments_AL.json")
AL2_TITLE <- paste0("Governor Ivey Announces Additional Alabama Rural Health ",
                    "Transformation Program Grants Totaling Nearly $55 Million")

# -- parse ---------------------------------------------------------------------

al2_squish <- function(x) stringr::str_squish(gsub("\u00a0", " ", x))

#' "$1.45 million" -> 1,450,000 ROUNDED; "$308,694" -> exact
al2_amount <- function(text) {
  m <- stringr::str_match(text, "\\$([0-9][0-9,]*(?:\\.[0-9]+)?)(\\s*million)?")
  if (is.na(m[1, 1])) return(list(amount = NA_real_, rounded = NA))
  v <- as.numeric(gsub(",", "", m[1, 2]))
  r <- !is.na(m[1, 3])
  list(amount = if (r) round(v * 1e6) else v, rounded = r)
}

#' The 34 grants, in document order, from the archived release
al2_parse <- function(src = here::here(AL2_ARCHIVE)) {
  raw <- readr::read_file_raw(src)
  if (digest::digest(raw, algo = "sha256", serialize = FALSE) != AL2_SHA256) {
    stop("[AL2] the archived release's SHA-256 does not match MANIFEST.txt.",
         call. = FALSE)
  }
  doc <- xml2::read_html(rawToChar(raw))
  anchor <- xml2::xml_find_all(doc, "//p[contains(., 'Below are the healthcare providers')]")
  if (length(anchor) != 1L) stop("[AL2] expected one list anchor, found ",
                                 length(anchor), ".", call. = FALSE)
  blocks <- xml2::xml_find_all(anchor, "following::p")
  initiative <- NA_character_
  rows <- list()
  closed <- FALSE
  for (b in blocks) {
    text <- al2_squish(xml2::xml_text(b))
    if (!nzchar(text)) next
    if (grepl("^#+$", text)) { closed <- TRUE; break }
    strong <- al2_squish(xml2::xml_text(xml2::xml_find_all(b, ".//strong|.//b")))
    strong <- strong[nzchar(strong)]
    if (length(strong) == 1L && identical(strong, text) && grepl("Initiative$", text)) {
      initiative <- text
      next
    }
    if (length(strong)) {
      name <- al2_squish(paste(strong, collapse = " "))
      name <- al2_squish(sub("[\\s\u2013\u2014-]+$", "", name, perl = TRUE))
      if (is.na(initiative)) stop("[AL2] an award before any initiative heading: ",
                                  name, call. = FALSE)
      if (!startsWith(text, name) && !startsWith(gsub("\\s*[\u2013\u2014-]\\s*", " ", text),
                                                 gsub("\\s*[\u2013\u2014-]\\s*", " ", name))) {
        stop("[AL2] the bolded name is not the start of its paragraph: ", name,
             call. = FALSE)
      }
      a <- al2_amount(text)
      if (is.na(a$amount)) stop("[AL2] no amount for ", name, call. = FALSE)
      rows[[length(rows) + 1L]] <- tibble::tibble(
        initiative_raw = initiative, awardee = name, amount = a$amount,
        amount_rounded = a$rounded, project_description = text)
      next
    }
    # A bare paragraph inside the list: a CONTINUATION of the previous grant's
    # description. It may carry neither a name nor an amount.
    if (!length(rows)) stop("[AL2] a bare paragraph before any award: ",
                            substr(text, 1, 80), call. = FALSE)
    if (grepl("\\$", text)) {
      stop("[AL2] a bare paragraph carries a dollar figure -- a nameless award ",
           "(round 1's 'A second grant' shape?). Read it: ", substr(text, 1, 120),
           call. = FALSE)
    }
    k <- length(rows)
    rows[[k]]$project_description <- paste(rows[[k]]$project_description, text)
    rows[[k]]$continuation <- text
  }
  if (!closed) stop("[AL2] the closing '###' was never reached.", call. = FALSE)
  out <- dplyr::bind_rows(rows)
  if (!"continuation" %in% names(out)) out$continuation <- NA_character_
  out
}

al2_counties <- function(desc) {
  m <- stringr::str_match(desc, "\\(([^()]*)\\)\\.?(\\s+The project will also.*)?$")
  ifelse(is.na(m[, 2]), "", al2_squish(m[, 2]))
}

al2_assert_parse <- function(d = al2_parse()) {
  if (nrow(d) != AL2_GRANTS) {
    stop("[AL2] parsed ", nrow(d), " grants; the release states ", AL2_GRANTS, ".",
         call. = FALSE)
  }
  if (!setequal(unique(d$initiative_raw), AL2_INITIATIVES)) {
    stop("[AL2] initiative headings changed: ",
         paste(unique(d$initiative_raw), collapse = "; "), call. = FALSE)
  }
  if (sum(!is.na(d$continuation)) != 1L ||
      d$awardee[!is.na(d$continuation)] != "The University of Alabama") {
    stop("[AL2] expected exactly one continuation paragraph, on The University ",
         "of Alabama's Treat-in-Place grant.", call. = FALSE)
  }
  if (any(d$amount <= 0)) stop("[AL2] a non-positive amount.", call. = FALSE)
  s <- sum(d$amount)
  # "nearly $55 million": at or under the headline, and within 1% of it --
  # 25 rounded figures cannot move the sum further than that.
  if (s > AL2_HEADLINE || s < 0.99 * AL2_HEADLINE) {
    stop("[AL2] the 34 grants sum to ", format(s, big.mark = ","),
         "; 'nearly $55 million' says otherwise. A missed or duplicated grant?",
         call. = FALSE)
  }
  r1 <- readr::read_csv(here::here("data", "reference", "al_year1_awardees.csv"),
                        col_types = readr::cols(.default = "c"), progress = FALSE)
  if (s + sum(as.numeric(r1$amount)) > AL2_ALLOTMENT) {
    stop("[AL2] rounds 1 + 2 exceed Alabama's allotment (§6.2 ceiling).", call. = FALSE)
  }
  if (any(grepl("Initiative$", d$awardee))) {
    stop("[AL2] an initiative heading captured as a recipient.", call. = FALSE)
  }
  # §0.2: the footer prints the ALLOTMENT; the round is Tier 3.
  t <- al2_squish(xml2::xml_text(xml2::read_html(here::here(AL2_ARCHIVE))))
  if (!grepl("financial assistance award totaling $203,404,326.54 with 100 percent funded by CMS/HHS",
             t, fixed = TRUE)) {
    stop("[AL2] the CMS footer no longer prints the allotment.", call. = FALSE)
  }
  if (!grepl("The grants announced today round out year one of funding for the program.",
             t, fixed = TRUE)) {
    stop("[AL2] the 'round out year one' sentence R/03aw cites is gone.", call. = FALSE)
  }
  if (!(AL2_ANNOUNCED > AL2_NOA_DATE)) stop("[AL2] §6.2 date test.", call. = FALSE)
  invisible(TRUE)
}

# -- typing --------------------------------------------------------------------

al2_norm <- function(x) {
  x <- toupper(gsub("[\u2019']", "", x))
  x <- gsub("&", " AND ", x, fixed = TRUE)
  x <- stringr::str_squish(gsub("[^A-Z0-9 ]", " ", x))
  x <- sub("^THE ", "", x)
  stringr::str_squish(gsub("\\b(INC|INCORPORATED|LLC|CORP|CORPORATION)\\b", " ", x))
}

al2_halves <- function(a) {
  parts <- stringr::str_split(a, stringr::regex("\\s+(dba|d/b/a)\\s+", ignore_case = TRUE))[[1]]
  unique(al2_norm(c(a, parts)))
}

al2_federal <- function() {
  rd <- function(f, k) {
    j <- jsonlite::fromJSON(here::here(f))
    tibble::tibble(kind = k, ccn = as.character(j$CCN), org = j$`ORGANIZATION NAME`,
                   dba = j$`DOING BUSINESS AS NAME`, city = j$CITY)
  }
  dplyr::bind_rows(rd(AL2_FED_HOSP, "HOSPITAL"), rd(AL2_FED_FQHC, "FQHC"),
                   rd(AL2_FED_RHC, "RHC"))
}

al2_federal_match <- function(awardee, f = al2_federal()) {
  h <- al2_halves(awardee)
  f[al2_norm(f$org) %in% h | al2_norm(dplyr::coalesce(f$dba, "")) %in% h, ]
}

# Hand-read decisions. Everything else is a federal-record match or a form the
# shared classifier reads from the state's own string at better than LOW.
AL2_OVERRIDES <- tibble::tribble(
  ~awardee, ~recipient_type, ~basis_type, ~confidence, ~ccn, ~why,
  "The University of Alabama at Birmingham", "UNIVERSITY_OR_AHC", "STATE_SOURCE", "MEDIUM", NA,
  "LEFT FOR R/03bj: CMS AL Hospital Enrollment carries UNIVERSITY OF ALABAMA AT BIRMINGHAM (dba UNIVERSITY OF ALABAMA HOSPITAL, CCN 010033) as the legal entity, so §10.2's enrolled-hospital-operator rule re-types these rows HOSPITAL_OR_SYSTEM / ACADEMIC_HEALTH_CENTER through EH_APPLY, exactly as round 1's three UAB rows were.",
  "University of South Alabama", "UNIVERSITY_OR_AHC", "STATE_SOURCE", "MEDIUM", NA,
  "LEFT FOR R/03bj: CMS AL Hospital Enrollment carries UNIVERSITY OF SOUTH ALABAMA (CCN 010087; also 013301) as the legal entity; EH_APPLY re-types these rows HOSPITAL_OR_SYSTEM / ACADEMIC_HEALTH_CENTER, as round 1's were.",
  "The University of Alabama", "UNIVERSITY_OR_AHC", "STATE_SOURCE", "MEDIUM", NA,
  "The University of Alabama (Tuscaloosa) is NOT the University of Alabama at Birmingham: a different legal body with a similar name, and a name that is only a prefix of an enrolled name is never matched by machine (§10.2, §2). No CMS AL hospital enrolment carries this string.",
  "Greene County Health System", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", NA,
  "HAND-READ BRIDGE (GENERAL_KNOWLEDGE): no CMS AL Hospital, FQHC or RHC Enrollment carries 'Greene County Health System'. CMS enrols GREENE COUNTY HOSPITAL & NURSING HOME (dba GREENE COUNTY HOSPITAL, CCN 010051, Eutaw), and its RHC (GREENE COUNTY HOSPITAL PHYSICIANS' CLINIC); Greene County Health System is that Eutaw operator's trading name, read from general knowledge, not from the release. LOW and subtractable; queued as AL_R2_GREENE_COUNTY_HEALTH_SYSTEM_BRIDGE.",
  "Infirmary Health System Inc.", "HOSPITAL_OR_SYSTEM", "STATE_SOURCE", "MEDIUM", NA,
  "THE SAME PUBLISHER STATES THE FORM: Governor Ivey's 2026-08-24 release introduces this recipient as 'This nonprofit health system based in Mobile and Baldwin counties' (data/evidence/AL/2026-08-24_governor_ivey_first_arhtp_grants.html). No CMS AL enrolment carries the parent's name; its hospitals enrol as MOBILE INFIRMARY ASSOCIATION (CCN 010113) and others.",
  "The Alabama School of Healthcare Sciences", "SCHOOL_OR_DISTRICT", "STATE_SOURCE", "MEDIUM", NA,
  "The release states the form: 'the statewide residential high school in Demopolis'.",
  "Oneonta Fire and Rescue Service", "EMS_OR_PSAP", "STATE_SOURCE", "MEDIUM", NA,
  "A fire and rescue service; the form is in the state's own string, and the grant is an EMS Treat-in-Place programme.",
  "Piedmont Emergency Rescue Squad Inc.", "EMS_OR_PSAP", "STATE_SOURCE", "MEDIUM", NA,
  "An emergency rescue squad; the form is in the state's own string.",
  "South Central Alabama Mental Health Board Inc.", "NONPROFIT_CBO", NA, "LOW", NA,
  "The release states no form and no CMS AL Hospital, FQHC or RHC enrolment carries the string. Alabama's '310 boards' are public corporations, but this pipeline does not read a form off a name (§0.4): §8's standing fallback, queued as AL_R2_RECIPIENT_FORM_NOT_STATED. $0 of hospital money either way."
)

al2_awardees <- function(d = al2_parse()) {
  f <- al2_federal()
  cls <- rhtp_classify_recipient_type(d$awardee, AL2_STATE)
  out <- vector("list", nrow(d))
  for (i in seq_len(nrow(d))) {
    a <- d$awardee[i]
    ccn_i <- NA_character_
    hit <- al2_federal_match(a, f)
    ov <- AL2_OVERRIDES[AL2_OVERRIDES$awardee == a, ]
    if (nrow(ov)) {
      rt <- ov$recipient_type; bt <- ov$basis_type; cf <- ov$confidence
      why <- ov$why; how <- "HAND-READ"; ccn_i <- ov$ccn
    } else if (nrow(hit)) {
      k <- if ("HOSPITAL" %in% hit$kind) "HOSPITAL" else
        if ("FQHC" %in% hit$kind) "FQHC" else "RHC"
      hk <- hit[hit$kind == k, ]
      rt <- if (k == "HOSPITAL") "HOSPITAL_OR_SYSTEM" else "FQHC_OR_RHC"
      bt <- "ORG_WEBSITE"; cf <- "MEDIUM"; how <- "FEDERAL RECORD"
      six <- sort(unique(sprintf("%06d", suppressWarnings(as.integer(
        hk$ccn[grepl("^[0-9]{5,6}$", hk$ccn)])))))
      one <- k == "HOSPITAL" && length(six) == 1L
      ccn_i <- if (one) six else NA_character_
      rec <- hk %>% dplyr::distinct(org, dba) %>% dplyr::slice(1)
      why <- paste0("EXACT federal record: CMS AL ",
                    c(HOSPITAL = "Hospital", FQHC = "FQHC", RHC = "RHC")[[k]],
                    " Enrollment carries this string (or a half of its DBA) as ",
                    rec$org, if (!is.na(rec$dba) && nzchar(rec$dba)) paste0(" dba ", rec$dba) else "",
                    if (k == "HOSPITAL") paste0(", ", if (one) "CCN " else "CCNs ",
                                                paste(six, collapse = "/")) else "",
                    if (k == "HOSPITAL" && !one) " (one legal entity, more than one hospital CCN; the row's ccn is left for Stage 5)" else "",
                    ".")
    } else if (cls$recipient_type[i] == "HOSPITAL_OR_SYSTEM") {
      stop("[AL2] the classifier calls '", a, "' a hospital and no federal ",
           "record or hand-read decision covers it. Read it.", call. = FALSE)
    } else if (cls$recipient_type[i] %in% c("UNIVERSITY_OR_AHC", "EMS_OR_PSAP",
                                            "FQHC_OR_RHC", "LOCAL_GOVT_OR_PUBLIC_HEALTH",
                                            "SCHOOL_OR_DISTRICT", "TRIBAL_ORG") &&
               cls$determination_confidence[i] != "LOW") {
      rt <- cls$recipient_type[i]; bt <- "STATE_SOURCE"
      cf <- "MEDIUM"; how <- "CLASSIFIER"
      why <- "The form is in the state's own string, and the shared classifier's name rule reads it."
    } else {
      stop("[AL2] '", a, "' has no federal record, no hand-read decision and no ",
           "determined form. Read it and add it to AL2_OVERRIDES.", call. = FALSE)
    }
    hosp <- rt == "HOSPITAL_OR_SYSTEM"
    out[[i]] <- tibble::tibble(
      recipient_type = rt, basis_type = bt, determination_confidence = cf,
      typing = how, why = why, ccn = ccn_i,
      classifier = paste0(cls$recipient_type[i], "/", cls$determination_confidence[i]),
      fallback = how == "HAND-READ" && rt == "NONPROFIT_CBO")
  }
  t <- dplyr::bind_rows(out)
  hosp <- t$recipient_type == "HOSPITAL_OR_SYSTEM"
  tibble::tibble(
    state = AL2_STATE,
    row_no = seq_len(nrow(d)),
    awardee = d$awardee,
    amount = d$amount,
    recipient_type = t$recipient_type,
    distributed_to_hospital = ifelse(hosp, "Yes", "No"),
    note = paste0(d$initiative_raw, " | ARHTP round 2, announced 2026-10-01"),
    recipient_confirmed = "Yes",
    amount_confirmed = "Yes",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = AL2_TITLE,
    state_source_url = AL2_URL,
    validation_source_type = "GOVERNOR_PRESS_RELEASE",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03bq_al_round2_awardees.R",
    ccn = t$ccn,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    recipient_type_source = paste0("TYPED (session 83, ", t$typing, "): ", t$why,
                                   " Classifier said ", t$classifier, "."),
    determination_confidence = t$determination_confidence,
    flag_reason = dplyr::case_when(
      t$fallback & d$amount_rounded ~ "RECIPIENT_TYPE_INFERRED;AMOUNT_ROUNDED_IN_SOURCE",
      t$fallback ~ "RECIPIENT_TYPE_INFERRED",
      d$amount_rounded ~ "AMOUNT_ROUNDED_IN_SOURCE",
      TRUE ~ NA_character_),
    award_pool = paste0("ARHTP round 2 (2026-10-01): ", d$initiative_raw),
    budget_period = "Budget Period 1",
    flow_type = ifelse(hosp, "DIRECT", "NON_HOSPITAL"),
    hospital_benefiting = ifelse(hosp, "Yes", "Unclear"),
    hospital_attribution = ifelse(hosp, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = paste0(
      "§10.2 ", ifelse(hosp, "DIRECT", "NON_HOSPITAL"), ": ", t$why,
      ifelse(hosp, " §0.3a: the recipient is a hospital whatever the activity.",
             " The named recipient is not a hospital on any record read (§0.3a: judged on the recipient, not the activity)."),
      " Source: Governor Ivey's 2026-10-01 release, which states 'the awarding of 34 grants' and names this recipient, amount, initiative and counties.",
      ifelse(d$amount_rounded, " The release publishes this amount rounded to millions; it is recorded as published and is not exact to the dollar.", "")),
    amount_basis = ifelse(d$amount_rounded,
                          "PER_AWARD_ACTION; ROUNDED_TO_MILLIONS in the source, recorded as published",
                          "PER_AWARD_ACTION; exact as published"),
    basis_type = t$basis_type,
    round_amount = NA_real_,
    announcement_date = AL2_ANNOUNCED,
    disbursement_status = "AWARDED",
    initiative_raw = d$initiative_raw,
    activity_type_raw = d$initiative_raw,
    counties_served = al2_counties(d$project_description),
    project_description = d$project_description,
    source_archive_path = AL2_ARCHIVE)
}

al2_assert_typing <- function(a) {
  h <- a[a$distributed_to_hospital == "Yes", ]
  if (any(h$recipient_type != "HOSPITAL_OR_SYSTEM") || any(h$flow_type != "DIRECT")) {
    stop("[AL2] a Yes row is not a DIRECT hospital row.", call. = FALSE)
  }
  if (any(a$determination_confidence == "HIGH")) {
    stop("[AL2] HIGH needs Stage 5's CCN match (§7).", call. = FALSE)
  }
  if (any(a$distributed_to_hospital[a$awardee == "The University of Alabama"] != "No")) {
    stop("[AL2] The University of Alabama is not UAB (§10.2).", call. = FALSE)
  }
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "determination_confidence", "hospital_attribution", "basis_type")) {
    v <- stats::na.omit(unique(a[[col]]))
    bad <- setdiff(v, rhtp_vocabulary(col))
    if (length(bad)) stop("[AL2] ", col, " outside §8: ", paste(bad, collapse = ", "),
                          call. = FALSE)
  }
  fr <- unlist(strsplit(stats::na.omit(a$flag_reason), ";", fixed = TRUE))
  if (length(setdiff(fr, rhtp_vocabulary("flag_reason")))) {
    stop("[AL2] flag_reason outside §8.", call. = FALSE)
  }
  if (any(!nzchar(a$determination_basis))) stop("[AL2] §7 basis.", call. = FALSE)
  invisible(TRUE)
}

al2_validate <- function() {
  d <- al2_parse()
  al2_assert_parse(d)
  a <- al2_awardees(d)
  al2_assert_typing(a)
  message("[AL2] all assertions pass.")
  invisible(a)
}

#' Build, then R/03bj's enrolled-hospital overlay (UAB and USA), as AR's does
al2_build <- function() {
  a <- al2_validate()
  s71 <- new.env()
  suppressMessages(source(here::here("R", "03bj_enrolled_hospital_operator.R"),
                          local = s71))
  a <- s71$s71_overlay(a %>% dplyr::mutate(dplyr::across(dplyr::everything(), as.character)),
                       "al_year1_round2_awardees.csv")
  readr::write_csv(a, AL2_CSV, na = "")
  a$amount <- as.numeric(a$amount)
  h <- a[a$distributed_to_hospital == "Yes", ]
  message(sprintf("[AL2] wrote %d grants, $%s; %d named-hospital rows, $%s.",
                  nrow(a), format(sum(a$amount), big.mark = ","), nrow(h),
                  format(sum(h$amount), big.mark = ",")))
  invisible(a)
}

al2_report <- function() {
  a <- readr::read_csv(AL2_CSV, show_col_types = FALSE)
  print(a %>% dplyr::count(recipient_type, distributed_to_hospital,
                           determination_confidence, wt = amount, name = "dollars"),
        n = 50)
  h <- a[a$distributed_to_hospital == "Yes", ]
  cat(sprintf("\n%d grants, $%s (headline 'nearly $55 million'); %d rounded in source.\n",
              nrow(a), format(sum(a$amount), big.mark = ","),
              sum(grepl("AMOUNT_ROUNDED_IN_SOURCE", a$flag_reason))))
  cat(sprintf("%d named-hospital rows, $%s; of which ACADEMIC_HEALTH_CENTER $%s and LOW $%s.\n",
              nrow(h), format(sum(h$amount), big.mark = ","),
              format(sum(h$amount[h$recipient_subtype %in% "ACADEMIC_HEALTH_CENTER"]), big.mark = ","),
              format(sum(h$amount[h$determination_confidence == "LOW"]), big.mark = ",")))
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) al2_validate()
  if ("--build" %in% args) al2_build()
  if ("--report" %in% args) al2_report()
  if (!length(args)) message("Usage: --validate | --build | --report")
}
