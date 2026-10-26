#!/usr/bin/env Rscript
# 03cj_ms_round2_awardees.R ----------------------------------------------------
#
# MISSISSIPPI -- THE GOVERNOR'S SECOND ROSTER: 60 AWARDS, $32,606,496.32, THE
# WORKFORCE (WEI) AND PSYCHIATRIC EMERGENCY SERVICES (EmPATH) TRANCHE, TYPED ON
# CMS'S MISSISSIPPI ENROLMENT FILES. Session 108.
#
# "Governor Tate Reeves today announced 60 awards totaling $32,606,496.32
# through the Mississippi Rural Health Transformation Program. The awards ...
# follow previously announced first-year awards of more than $104.1 million"
# (2026-10-21). R/03ak's file holds that first roster (167 / $104,115,146.80);
# this is a SEPARATE FILE because R/03ak's rows carry sessions 49 and 50's
# row-index overlays (R/03ap, R/03aq), which a rebuild that appended rows would
# re-key. The two files are never summed by row; each is its own award file.
#
# THE ROSTER. Five headed sections, printed as numbered prose in R/03ak's shape
# "<n>. <organisation> - <county or counties> - $<amount> - <description>":
#   Workforce Recruitment and Sustainable Ecosystem Development   20
#   Secondary Education Medical Career Outreach                    4
#   Preceptor Expansion                                           12
#   Earn While You Learn                                          21
#   Psychiatric Emergency Services                                 3
# The 60 amounts sum to $32,606,496.32, the release's own figure TO THE CENT
# (ms2_assert_roster()). A county field may name several counties ("Lee,
# Monroe, Itawamba and Chickasaw Counties"); the reader takes both forms and a
# numbered line of any other shape is REFUSED, never dropped (R/03ak's rule).
#
# THE AWARDS ARE ANNOUNCED, NOT INTENDED ("today announced 60 awards"), so
# recipient_confirmed and amount_confirmed are Yes, R/03ak's posture.
#
# TIERS (§0.2). The footer is R/03ak's 99.96%/0.04% footer: its CMS share
# ($205,907,220.16) is the ALLOTMENT and is asserted STATE_ALLOTMENT through the
# shared parse; "$205.9 million first-year implementation budget" is the same
# Tier 1 figure. The rows are Tier 3.
#
# TYPING (owner instruction, session 108: "type on CMS enrolment"). In order:
#   1. A hand-read decision below (MS2_HAND), each with its sentence.
#   2. EXACT: the string, or a half split at "d.b.a."/"DBA"/"/", equals an
#      ORGANIZATION NAME or DBA on CMS's MS Hospital, FQHC, RHC, HHA, Hospice or
#      SNF Enrollment (data/evidence/federal_records/2026-09-22/). MEDIUM. Where
#      one legal entity enrols several hospitals, the record whose DBA the
#      string names is the one taken (George County Hospital DBA Greene County
#      Hospital: the REH, CCN 250782).
#   3. The classifier on the name, or §8's standing fallback.
#
# THE THREE EmPATH UNITS (owner instruction: "Type the three EmPATH units to
# their host hospital's enrolment, or Unclear if none matches"). Each is a unit
# "adjacent to the hospital's Emergency Department", so the recipient is the
# hospital named:
#   * Merit Health Central/Jackson MHA, LLC, $4,500,000: the "Merit Health
#     Central" half is the DBA of JACKSON HMA LLC (CCN 250072). EXACT, MEDIUM.
#     The release's "MHA" transposes the enrolled "HMA".
#   * Memorial Hospital at Gulfport, $4,496,000: MEMORIAL HOSPITAL AT GULFPORT
#     (CCN 250019). EXACT, MEDIUM.
#   * University of Mississippi Medical Center Greenwood Hospital, $4,320,032:
#     NO CMS record carries the string. The only enrolled hospital in Greenwood
#     (Leflore County) is GREENWOOD LEFLORE HOSPITAL (CCN 250099), and the
#     string's legal body, STATE OF MISSISSIPPI-UNIVERSITY OF MISSISSIPPI
#     MEDICAL CENTER, is itself CMS-enrolled as a hospital operator (CCN 250001,
#     §10.2's enrolled-operator row). A HAND-READ BRIDGE to the host hospital,
#     LOW, recipient_subtype ACADEMIC_HEALTH_CENTER, subtractable. None of the
#     three is Unclear.
# All three are hospital rows at $13,316,032 together; the Greenwood one is the
# only LOW of the three.
#
# OTHER HAND READS (MS2_HAND):
#   * Baptist Memorial Hospital-Yazoo, Inc. -> BAPTIST MEDICAL CENTER - YAZOO,
#     INC. (CAH 251313): the string says "Hospital" where the enrolled name says
#     "Medical Center". LOW.
#   * Baptist Memorial Hospital-Oktibbeha -> BAPTIST MEMORIAL HOSP OKTIBBEHA
#     COUNTY INC. (250050): a truncation. LOW.
#   * South MS State Hospital -> SOUTH MISSISSIPPI STATE HOSPITAL (254008,
#     Purvis), the Department of Mental Health's psychiatric hospital: "MS" for
#     "Mississippi". LOW.
#   * Memorial Health System -> a SYSTEM PARENT (owner rulings: Vandalia,
#     Sanford/Avera, Guthrie, Ballad/Sentara/Valley): the parent of MEMORIAL
#     HOSPITAL AT GULFPORT (250019); not itself enrolled. LOW, GENERAL_KNOWLEDGE.
#     (R/03ak's two round-1 rows type the same string MEDIUM on the name alone;
#     that file is not re-typed here.)
#   * Magnolia Regional Health Center EMS -> NOT bridged to MAGNOLIA REGIONAL
#     HEALTH CENTER (250009). The string names a hospital's EMS service, a
#     department; the owner's WVU Eye Institute ruling (session 104) added NO
#     department-name rule, so the row is typed on its stated form, EMS_OR_PSAP,
#     NON_HOSPITAL, and queued (MS2_MAGNOLIA_EMS_DEPARTMENT). One-directional,
#     $100,000, if the owner rules a hospital's own EMS is the hospital.
#   * Aaron E. Henry Community Health Services Center, Inc. -> the FQHC
#     enrolled as AARON E HENRY COMMUNITY HEALTH (a truncation). LOW.
#   * Kinder Mind and Jefferson County Nursing Home keep R/03ak's round-1
#     readings (OTHER).
#
# §6.2: announced 2026-10-21, after Mississippi's 2025-12-29 NOA; RHTP in the
# release's own words.
#
# Usage:
#   Rscript R/03cj_ms_round2_awardees.R --validate | --build | --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

MS2_STATE     <- "MS"
MS2_ALLOTMENT <- 205907220
MS2_FOOTER_CMS_SHARE <- 205907220.16
MS2_NOA_DATE  <- as.Date("2025-12-29")
MS2_ANNOUNCED <- as.Date("2026-10-21")
MS2_TOTAL     <- 32606496.32
MS2_N         <- 60L
MS2_URL <- paste0("https://governorreeves.ms.gov/governor-reeves-announces-60-",
                  "rural-health-transformation-program-awards-totaling-32-6-million/")
MS2_FILE <- file.path("data", "evidence", "recheck", "2026-10-26", "MS",
                      "ms_governor_2026-10-21_60_awards_32_6m.html")
MS2_CSV  <- here::here("data", "reference", "ms_round2_awardees.csv")
MS2_TITLE <- paste0("Governor Reeves Announces 60 Rural Health Transformation ",
                    "Program Awards Totaling $32.6 Million (2026-10-21)")
MS2_FED_DIR <- file.path("data", "evidence", "federal_records", "2026-09-22")
MS2_FED <- c(HOSPITAL = "hosp", FQHC = "fqhc", RHC = "rhc", HHA = "hha",
             HOSPICE = "hospice", SNF = "snf")
MS2_SECTIONS <- tibble::tribble(
  ~heading, ~n,
  "Workforce Recruitment and Sustainable Ecosystem Development", 20L,
  "Secondary Education Medical Career Outreach", 4L,
  "Preceptor Expansion", 12L,
  "Earn While You Learn", 21L,
  "Psychiatric Emergency Services", 3L)
MS2_EMPATH <- c("Merit Health Central/Jackson MHA, LLC", "Memorial Hospital at Gulfport",
                "University of Mississippi Medical Center Greenwood Hospital")

# <n>. <organisation> - <county | counties | Co.> - $<amount> - <description>
MS2_ROW_RX <- paste0(
  "^(\\d+)\\.\\s+(.*?)\\s*-\\s*",
  "([A-Za-z ,.'\u2019]+?(?:County|Counties|Co\\.))\\s*-\\s*",
  "\\$([\\d,]+(?:\\.\\d{1,2})?)\\s*-\\s*(.+)$")

ms2_text <- function(path = here::here(MS2_FILE)) {
  h <- xml2::read_html(path)
  xml2::xml_remove(xml2::xml_find_all(h, "//script|//style|//noscript"))
  t <- rvest::html_text2(h)
  t <- gsub("\u00a0", " ", t, fixed = TRUE)
  # The release separates fields with an EM DASH; R/03ak's reduction maps every
  # dash to "-", and so does this.
  t <- gsub("[\u2010-\u2015\u2212]", "-", t)
  l <- stringr::str_squish(strsplit(t, "\n", fixed = TRUE)[[1]])
  l[nzchar(l)]
}

ms2_parse <- function(l = ms2_text()) {
  heads <- match(MS2_SECTIONS$heading, l)
  if (anyNA(heads) || is.unsorted(heads, strictly = TRUE)) {
    stop("[MS r2] the release's five section headings are not where they were: ",
         "re-read it (§0.4).", call. = FALSE)
  }
  num <- grep("^\\d+\\. ", l)
  num <- num[num > heads[1]]
  m <- stringr::str_match(l[num], MS2_ROW_RX)
  if (anyNA(m[, 1])) {
    stop("[MS r2] a numbered award line did not parse and is REFUSED, not dropped: '",
         substr(l[num][is.na(m[, 1])][1], 1, 160), "'.", call. = FALSE)
  }
  tibble::tibble(
    section = MS2_SECTIONS$heading[vapply(num, function(i) max(which(heads < i)), integer(1))],
    row_in_section = as.integer(m[, 2]),
    awardee = stringr::str_squish(m[, 3]),
    county = stringr::str_squish(m[, 4]),
    amount = as.numeric(gsub(",", "", m[, 5])),
    description = stringr::str_squish(m[, 6]))
}

ms2_assert_roster <- function(d = ms2_parse(), l = ms2_text()) {
  if (nrow(d) != MS2_N) stop("[MS r2] ", nrow(d), " awards, not 60.", call. = FALSE)
  if (abs(sum(d$amount) - MS2_TOTAL) > 0.005) {
    stop("[MS r2] the 60 sum to $", format(sum(d$amount), nsmall = 2, big.mark = ","),
         ", not $32,606,496.32.", call. = FALSE)
  }
  per <- table(factor(d$section, levels = MS2_SECTIONS$heading))
  if (!identical(as.integer(per), MS2_SECTIONS$n)) {
    stop("[MS r2] the per-section counts moved: ", paste(per, collapse = "/"), call. = FALSE)
  }
  t <- paste(l, collapse = " ")
  for (p in c("Governor Tate Reeves today announced 60 awards totaling $32,606,496.32 through the Mississippi Rural Health Transformation Program",
              "follow previously announced first-year awards of more than $104.1 million")) {
    if (!grepl(p, t, fixed = TRUE)) stop("[MS r2] the release no longer carries: ", p, call. = FALSE)
  }
  if (!all(MS2_EMPATH %in% d$awardee[d$section == "Psychiatric Emergency Services"])) {
    stop("[MS r2] the three EmPATH units are not the Psychiatric Emergency Services rows.", call. = FALSE)
  }
  # §0.2: the footer's CMS share is the allotment, parsed (never the headline).
  rhtp_assert_footer_text_tier(t, MS2_STATE, "STATE_ALLOTMENT", label = "MS 10-21 release footer")
  refused <- tryCatch({
    rhtp_assert_footer_not_allotment(MS2_FOOTER_CMS_SHARE, MS2_STATE, "SOLICITATION",
                                     label = "MS footer CMS share read as a pool")
    FALSE
  }, error = function(e) TRUE)
  if (!refused) stop("[MS r2] §0.2 no longer refuses the allotment as a pool.", call. = FALSE)
  if (!(MS2_ANNOUNCED > MS2_NOA_DATE)) stop("[MS r2] §6.2 date test.", call. = FALSE)
  invisible(TRUE)
}

# -- typing ---------------------------------------------------------------------

ms2_norm <- function(x) {
  x <- toupper(x)
  x <- gsub("['\u2019]", "", x)
  x <- gsub("[.,/&()\u2013-]", " ", x)
  x <- stringr::str_squish(gsub("[^A-Z0-9 ]", "", x))
  x <- sub("^THE ", "", x)
  sub(" (INC|INCORPORATED|LLC|PLLC|PC|PA|LP|LTD)$", "", x)
}
ms2_halves <- function(a) {
  unique(ms2_norm(c(a, strsplit(a, " d\\.?/?b\\.?/?a\\.? |/| DBA ", perl = TRUE)[[1]])))
}

ms2_federal <- function() {
  dplyr::bind_rows(lapply(names(MS2_FED), function(k) {
    j <- jsonlite::fromJSON(here::here(MS2_FED_DIR, sprintf("cms_%s_enrollments_MS.json", MS2_FED[[k]])))
    tibble::tibble(kind = k, ccn = as.character(j$CCN), org = j$`ORGANIZATION NAME`,
                   dba = j$`DOING BUSINESS AS NAME`, city = j$CITY,
                   ptype = if ("PROVIDER TYPE TEXT" %in% names(j)) j$`PROVIDER TYPE TEXT` else NA_character_)
  }))
}

MS2_PARENT_NOTE <- paste0(
  "SYSTEM PARENT, LOW, GENERAL_KNOWLEDGE (owner rulings: Vandalia, Sanford/Avera, ",
  "Guthrie, Ballad/Sentara/Valley): the parent system of ")
MS2_HAND <- tibble::tribble(
  ~awardee, ~recipient_type, ~basis_type, ~confidence, ~ccn, ~subtype, ~why,
  "University of Mississippi Medical Center Greenwood Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "250099", "ACADEMIC_HEALTH_CENTER",
  paste0("EmPATH UNIT, TYPED TO ITS HOST HOSPITAL (owner instruction, session 108). HAND-READ BRIDGE: ",
         "no CMS MS enrolment carries the string. The only enrolled hospital in Greenwood (Leflore ",
         "County) is GREENWOOD LEFLORE HOSPITAL (CCN 250099, PART A PROVIDER - HOSPITAL), and the ",
         "string's legal body, STATE OF MISSISSIPPI-UNIVERSITY OF MISSISSIPPI MEDICAL CENTER, is itself ",
         "enrolled as a hospital operator (CCN 250001; §10.2's enrolled-operator row). That UMMC ",
         "operates the Greenwood hospital is not on the CMS file, so LOW; recipient_subtype ",
         "ACADEMIC_HEALTH_CENTER so the row subtracts with the AHC rows."),
  "Baptist Memorial Hospital-Yazoo, Inc.", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "251313", NA,
  paste0("HAND-READ BRIDGE: CMS MS Hospital Enrollment carries BAPTIST MEDICAL CENTER - YAZOO, INC. ",
         "(CAH 251313, Yazoo City); the string says 'Hospital' where the enrolled name says 'Medical ",
         "Center'. One legal entity, one CCN. LOW."),
  "Baptist Memorial Hospital-Oktibbeha", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "250050", NA,
  paste0("HAND-READ BRIDGE: CMS MS Hospital Enrollment carries BAPTIST MEMORIAL HOSP OKTIBBEHA ",
         "COUNTY INC. dba BAPTIST MEMORIAL HOSPITAL - OKTIBBHEA COUNTY (250050, Starkville); the ",
         "string truncates it. LOW."),
  "South MS State Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "254008", NA,
  paste0("HAND-READ BRIDGE: CMS MS Hospital Enrollment carries SOUTH MISSISSIPPI STATE HOSPITAL ",
         "(254008, Purvis), the Department of Mental Health's psychiatric hospital; 'MS' for ",
         "'Mississippi'. A state-operated hospital is a hospital (§0.3a judges the recipient). LOW."),
  "Memorial Health System", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", NA, NA,
  paste0(MS2_PARENT_NOTE, "MEMORIAL HOSPITAL AT GULFPORT (CCN 250019), which CMS enrols under its ",
         "own name; Memorial Health System is not itself enrolled, so no CCN. Subtractable by basis_type."),
  "Magnolia Regional Health Center EMS", "EMS_OR_PSAP", "STATE_SOURCE", "MEDIUM", NA, NA,
  paste0("NOT BRIDGED (queued, MS2_MAGNOLIA_EMS_DEPARTMENT): the string names a hospital's EMS ",
         "service, a department of MAGNOLIA REGIONAL HEALTH CENTER (CCN 250009, Corinth). The owner's ",
         "WVU Eye Institute ruling (session 104) added no department-name rule, so the row is typed on ",
         "the form its own name states, EMS. One-directional ($100,000) if the owner rules otherwise."),
  "Aaron E. Henry Community Health Services Center, Inc.", "FQHC_OR_RHC", "ORG_WEBSITE", "LOW", NA, NA,
  paste0("HAND-READ BRIDGE: CMS MS FQHC Enrollment carries AARON E HENRY COMMUNITY HEALTH (Clarksdale ",
         "and others), a truncation of the string. An FQHC, not a hospital. LOW."),
  "Kinder Mind", "OTHER", "GENERAL_KNOWLEDGE", "LOW", NA, NA,
  "R/03ak's round-1 reading of the same string (R/03aq): a behavioral-health provider, a determined form that is not a hospital.",
  "Millsaps Career and Technology Center at Starkville High School", "SCHOOL_OR_DISTRICT", "STATE_SOURCE", "MEDIUM", NA, NA,
  "A career and technology centre at a public high school (the form is in the string). The classifier's VENDOR_OR_CONTRACTOR is wrong about it. Not a hospital.",
  "Jefferson County Nursing Home", "OTHER", "ORG_WEBSITE", "MEDIUM", NA, NA,
  "NURSING FACILITY. CMS MS SNF Enrollment carries JEFFERSON COUNTY NURSING HOME (255164). Not a hospital.")

ms2_type <- function(d = ms2_parse(), f = ms2_federal()) {
  cls <- rhtp_classify_recipient_type(d$awardee, MS2_STATE)
  kinds <- c(HOSPITAL = "HOSPITAL_OR_SYSTEM", FQHC = "FQHC_OR_RHC", RHC = "FQHC_OR_RHC",
             HHA = "OTHER", HOSPICE = "OTHER", SNF = "OTHER")
  out <- lapply(seq_len(nrow(d)), function(i) {
    a <- d$awardee[i]
    hd <- MS2_HAND[MS2_HAND$awardee == a, ]
    if (nrow(hd)) {
      return(tibble::tibble(recipient_type = hd$recipient_type, basis_type = hd$basis_type,
                            determination_confidence = hd$confidence, typing = "HAND-READ",
                            why = hd$why, ccn = hd$ccn, subtype = hd$subtype))
    }
    h <- ms2_halves(a)
    hit <- f[ms2_norm(f$org) %in% h | ms2_norm(dplyr::coalesce(f$dba, "")) %in% h, ]
    if (nrow(hit)) {
      k <- names(kinds)[names(kinds) %in% hit$kind][1]
      hk <- hit[hit$kind == k, ]
      # A DBA half names one record of a multi-hospital entity: take that one.
      dba_hit <- hk[ms2_norm(dplyr::coalesce(hk$dba, "")) %in% setdiff(h, ms2_norm(a)) |
                      ms2_norm(dplyr::coalesce(hk$dba, "")) %in% ms2_norm(a), ]
      if (k == "HOSPITAL" && nrow(dba_hit)) hk <- dba_hit
      six <- sort(unique(hk$ccn[grepl("^[0-9]{6}$", hk$ccn)]))
      if (k == "HOSPITAL" && !length(six)) {
        six <- sort(unique(f$ccn[f$kind == "HOSPITAL" & f$org %in% hk$org & grepl("^[0-9]{6}$", f$ccn)]))
      }
      rec <- paste0(paste(unique(hk$org), collapse = "; "),
                    if (any(nzchar(dplyr::coalesce(hk$dba, ""))))
                      paste0(" dba ", paste(unique(hk$dba[nzchar(dplyr::coalesce(hk$dba, ""))]), collapse = " / ")) else "",
                    " (", paste(six, collapse = "/"), ")")
      return(tibble::tibble(
        recipient_type = kinds[[k]], basis_type = "ORG_WEBSITE", determination_confidence = "MEDIUM",
        typing = "EXACT",
        why = paste0("EXACT federal record: CMS MS ", k, " Enrollment carries this string (or its ",
                     "d.b.a. half) as an ORGANIZATION NAME or DBA: ", rec,
                     if (k == "HOSPITAL") paste0(", ", unique(hk$ptype)[1]) else "", "."),
        ccn = if (k == "HOSPITAL" && length(six) == 1L) six else NA_character_, subtype = NA_character_))
    }
    if (cls$recipient_type[i] == "HOSPITAL_OR_SYSTEM") {
      stop("[MS r2] the classifier calls '", a, "' a hospital and no federal record or ",
           "hand-read decision covers it. Read it.", call. = FALSE)
    }
    fb <- cls$rule[i] == "FALLBACK"
    tibble::tibble(
      recipient_type = cls$recipient_type[i],
      basis_type = if (fb) NA_character_ else "STATE_SOURCE",
      determination_confidence = if (fb) "LOW" else rhtp_confidence_ceiling(cls$determination_confidence[i]),
      typing = if (fb) "FALLBACK" else "CLASSIFIER",
      why = if (fb) "The release states no form and no CMS MS enrolment carries the string (§8's standing fallback, RECIPIENT_TYPE_INFERRED)."
            else paste0("No CMS MS enrolment carries the string; the form is read from the string itself (",
                        cls$recipient_type_basis[i], ")."),
      ccn = NA_character_, subtype = NA_character_)
  })
  t <- dplyr::bind_rows(out)
  t$classifier <- paste0(cls$recipient_type, "/", rhtp_confidence_ceiling(cls$determination_confidence))
  t
}

ms2_awardees <- function(d = ms2_parse(), f = ms2_federal()) {
  t <- ms2_type(d, f)
  hosp <- t$recipient_type == "HOSPITAL_OR_SYSTEM"
  tibble::tibble(
    state = MS2_STATE,
    row_no = seq_len(nrow(d)),
    awardee = d$awardee,
    amount = d$amount,
    recipient_type = t$recipient_type,
    recipient_subtype = t$subtype,
    distributed_to_hospital = ifelse(hosp, "Yes", "No"),
    note = paste0(d$description, " [", d$county, "]"),
    recipient_confirmed = "Yes",
    amount_confirmed = "Yes",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = MS2_TITLE,
    state_source_url = MS2_URL,
    validation_source_type = "GOVERNOR_PRESS_RELEASE",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03cj_ms_round2_awardees.R",
    ccn = t$ccn,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    county = d$county,
    award_pool = d$section,
    row_in_pool = d$row_in_section,
    awardee_as_published = d$awardee,
    recipient_type_source = paste0("TYPED (session 108, ", t$typing, "): ", t$why,
                                   " Classifier said ", t$classifier, "."),
    determination_confidence = rhtp_confidence_ceiling(t$determination_confidence, t$ccn),
    flag_reason = ifelse(t$typing == "FALLBACK", "RECIPIENT_TYPE_INFERRED", NA_character_),
    budget_period = "Budget Period 1",
    flow_type = ifelse(hosp, "DIRECT", "NON_HOSPITAL"),
    hospital_benefiting = ifelse(hosp, "Yes", "Unclear"),
    hospital_attribution = ifelse(hosp, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = paste0("§10.2 ", ifelse(hosp, "DIRECT", "NON_HOSPITAL"), ": ", t$why,
                                 ifelse(hosp, " §0.3a: the recipient is a hospital or health system whatever the activity.", ""),
                                 " ANNOUNCED, not intended: 'today announced 60 awards'."),
    amount_basis = paste0("EXACT, per recipient, as the Governor printed it; the 60 sum to ",
                          "$32,606,496.32, the release's own figure, to the cent. The footer's CMS ",
                          "share ($205,907,220.16) is the ALLOTMENT, Tier 1 (§0.2)."),
    round_amount = MS2_TOTAL,
    announcement_date = MS2_ANNOUNCED,
    source_archive_path = MS2_FILE,
    basis_type = t$basis_type)
}

ms2_assert_typing <- function(a = ms2_awardees()) {
  e <- a[a$awardee %in% MS2_EMPATH, ]
  if (nrow(e) != 3L || any(e$distributed_to_hospital != "Yes") ||
      !setequal(e$ccn, c("250072", "250019", "250099"))) {
    stop("[MS r2] the three EmPATH units must be hospital rows on CCNs 250072, 250019, 250099.",
         call. = FALSE)
  }
  h <- a[a$distributed_to_hospital == "Yes", ]
  if (any(h$recipient_type != "HOSPITAL_OR_SYSTEM") || any(h$flow_type != "DIRECT")) {
    stop("[MS r2] a Yes row is not a DIRECT hospital row.", call. = FALSE)
  }
  unused <- setdiff(MS2_HAND$awardee, a$awardee)
  if (length(unused)) stop("[MS r2] hand reads match no row: ", paste(unused, collapse = "; "), call. = FALSE)
  rhtp_assert_high_has_ccn(a, "MS r2")
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital", "recipient_subtype",
                "determination_confidence", "hospital_attribution", "basis_type")) {
    bad <- setdiff(stats::na.omit(unique(a[[col]])), rhtp_vocabulary(col))
    if (length(bad)) stop("[MS r2] ", col, " outside §8: ", paste(bad, collapse = ", "), call. = FALSE)
  }
  fl <- unlist(strsplit(stats::na.omit(a$flag_reason), ";"))
  if (length(setdiff(fl, rhtp_vocabulary("flag_reason")))) stop("[MS r2] flag_reason outside §8.", call. = FALSE)
  invisible(TRUE)
}

ms2_validate <- function() {
  l <- ms2_text()
  d <- ms2_parse(l)
  ms2_assert_roster(d, l)
  a <- ms2_awardees(d)
  ms2_assert_typing(a)
  message("[MS r2] all assertions pass.")
  invisible(a)
}

ms2_build <- function() {
  a <- ms2_validate()
  readr::write_csv(a, MS2_CSV, na = "NA")
  h <- a[a$distributed_to_hospital == "Yes", ]
  message(sprintf("[MS r2] wrote %d awards, $%s; %d NAMED_HOSPITAL rows, $%s.",
                  nrow(a), formatC(sum(a$amount), format = "f", digits = 2, big.mark = ","),
                  nrow(h), formatC(sum(h$amount), format = "f", digits = 2, big.mark = ",")))
}

ms2_report <- function(a = ms2_awardees()) {
  m <- function(x) paste0("$", formatC(sum(x), format = "f", digits = 2, big.mark = ","))
  h <- a[a$distributed_to_hospital == "Yes", ]
  cat(sprintf("%d awards, %s. NAMED_HOSPITAL %d / %s; LOW %d / %s; GENERAL_KNOWLEDGE %s; AHC %s.\n",
              nrow(a), m(a$amount), nrow(h), m(h$amount), sum(h$determination_confidence == "LOW"),
              m(h$amount[h$determination_confidence == "LOW"]),
              m(h$amount[h$basis_type %in% "GENERAL_KNOWLEDGE"]),
              m(h$amount[h$recipient_subtype %in% "ACADEMIC_HEALTH_CENTER"])))
  print(a %>% dplyr::select(awardee, amount, recipient_type, determination_confidence, ccn), n = 60)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) ms2_validate()
  if ("--build" %in% args) ms2_build()
  if ("--report" %in% args) ms2_report()
  if (!length(args)) message("Usage: --validate | --build | --report")
}
