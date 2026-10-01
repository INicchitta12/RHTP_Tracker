#!/usr/bin/env Rscript
# 03bo_co_year1_awardees.R ---------------------------------------------------
#
# COLORADO -- 92 PRICED AWARD LINES, $170,210,575.26, AND A STATE RELEASE THAT
# SAYS $169,587,181. Session 82.
#
# HCPF's "About our RHTP Awardees" page (hcpf.colorado.gov/RHTP-awardees),
# linked from the RHTP programme page, lists "the organizations selected to
# receive funding" as 92 lines of the shape "<name> - $<amount>". It prints no
# total and carries no CMS footer. HCPF's 2026-09-28 release says Colorado "is
# directing $169,587,181 in Rural Health Transformation Program (RHTP) grants"
# and that "91 applicants and approximately 250 projects were selected"; CMS's
# release the same day repeats "$169.6 million" and "91 grantees".
#
# THE ROSTER AND THE RELEASE DO NOT RECONCILE, AND THIS FILE DOES NOT PRETEND
# THEY DO.
#   * DOLLARS. The 92 lines sum to $170,210,575.26, $623,394.26 above the
#     release. One line -- Rocky Mountain Youth Medical & Nursing Consultants,
#     Inc. dba Every Child Pediatrics, $623,395.26, the only line with cents --
#     is within $1.00 of that gap.
#   * COUNT. 92 lines against "91 applicants". Banner Health Foundation is
#     printed twice ($385,871 and $243,271), so the page carries 91 DISTINCT
#     strings; Epifluence (4 lines, two legal forms), Paragon (2), Salida
#     Hospital District (2), Lutheran Hospital Association of the San Luis
#     Valley (2, one per hospital) and Valley-Wide (2) repeat an organisation
#     under different strings.
#   Two readings survive. (H1) "91 applicants" counts distinct strings and the
#   release total predates or omits a line. (H2) the Every Child line was added
#   after the release, which explains the dollar gap to $1.00 AND makes the
#   pre-addition line count 91. H2 fits both numbers; it is still an inference
#   from arithmetic, not a statement by HCPF, so NEITHER IS PUBLISHED AS A
#   FINDING (§0.4) and NO ROW IS DROPPED. The file carries every line the
#   state's own roster prints. The status table states both totals, and the
#   question is queued (CO_ROSTER_VS_RELEASE_TOTAL).
#
# GRAIN. One row per printed LINE. Lines repeating one organisation are not
# merged (the page prices them separately, §6.1 mode 4), and the parenthetical
# on the two San Luis Valley lines is the SITE (§0.3a's awardee-field
# corollary): the recipient is the association, the site is the hospital.
#
# TYPING IS ON CMS'S OWN ENROLMENT FILES, NOT THE NAME SCREEN. The CO Hospital,
# FQHC and RHC Enrollment files are archived under
# data/evidence/federal_records/2026-10-01/. A line whose recipient string
# (either half of a "dba", parenthetical stripped) equals an ORGANIZATION NAME
# or DBA there -- after case, punctuation, a leading THE and a trailing
# INC/LLC/PC are set aside -- is typed from that record at MEDIUM. A HOSPITAL
# record wins over the same legal entity's provider-based RHC records, because
# the RHC is the hospital's. Everything else is HAND-READ below.
#
# §10.2 ON HOSPITAL DISTRICTS AND FOUNDATIONS, NOT THE WORD "HOSPITAL".
#   * A Colorado hospital or health-service district is a special district, a
#     local government. It is a hospital here ONLY where CMS enrols the
#     district (or its exact dba) as a hospital: Haxtun, Huerfano, Keefe,
#     Kiowa, Kremmling, Prowers, Rangely, Salida, Southeast Colorado, St.
#     Vincent, Upper San Juan, Eastern Rio Blanco -- and, by hand-read bridge,
#     Delta County Memorial, East Phillips, Kit Carson and Yuma.
#   * THREE DISTRICTS ARE NOT HOSPITALS, AND A NAME SCREEN CALLS ALL THREE
#     HOSPITALS. Walsh Hospital District holds only an RHC enrolment (WALSH
#     HOSPITAL DISTRICT HEALTHCARE CENTER, 063874). West Custer County Hospital
#     District holds no enrolment at all; the Westcliffe clinic is enrolled
#     under SALIDA HOSPITAL DISTRICT (RHC 063422). Lake Fork Health Services
#     District is an RHC (exact record). All three are NON_HOSPITAL, $0 of
#     hospital money, and the two hospital districts are queued
#     (CO_HOSPITAL_DISTRICT_NO_HOSPITAL_ENROLMENT) so Stage 5 re-reads them.
#   * Ute Pass Regional Health Services District holds no enrolment. A special
#     district, not a hospital.
#   * Telluride Regional Medical Center holds no hospital or RHC enrolment.
#     "Medical Center" is a name, not an enrolment: §8's standing fallback,
#     queued, NOT promoted.
#   * Banner Health Foundation (2 lines) -- §10.2's hospital-foundation row:
#     the foundation of a NAMED system, Banner Health, which CMS enrols in
#     Colorado (BANNER HEALTH, CCN 060126). The parent tie is read from the
#     name, so GENERAL_KNOWLEDGE / LOW, subtractable.
#   * Valley Citizens' Foundation for Health Care Inc. is NOT a foundation row:
#     it is the exact enrolled legal name of Rio Grande Hospital (CCN 061301),
#     typed from the enrolment like any other hospital.
#   * Eastern Plains Healthcare Consortium, Colorado Community Health Network
#     and Colorado Community Managed Care Network (Carina) are networks the
#     source does not describe. Nothing on HCPF's page says any of their money
#     is administered to hospitals, so §10.2's association row is not reached:
#     §8's standing fallback, queued, $0 of hospital money (§0.3).
#
# §0.2: the programme page's footer prints $200,105,604.17, 100% CMS --
# Colorado's ALLOTMENT ($200,105,604, §7.1) -- and the release's prints the
# same. A Tier 1 footer on a Tier 3 announcement.
#
# THE WATCH. `--probe` reads the awardee page and the programme page LIVE and
# never writes to data/evidence/ (§2.2). It TRIPS if the roster's line count or
# total moves (HCPF says "approximately 250 projects" and may append), and both
# pages are name-diffed (§2.3). R/03az's Routine delegates its --probe here,
# because the dated anchor it watched is gone: the state awarded.
#
# Usage:
#   Rscript R/03bo_co_year1_awardees.R --fetch     # archive the four sources
#   Rscript R/03bo_co_year1_awardees.R --validate  # assertions, offline
#   Rscript R/03bo_co_year1_awardees.R --build     # write co_year1_awardees.csv + status
#   Rscript R/03bo_co_year1_awardees.R --probe     # LIVE, READ-ONLY
#   Rscript R/03bo_co_year1_awardees.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))
source(here::here("R", "utils_page_watch.R"))

CO_STATE        <- "CO"
CO_ALLOTMENT    <- 200105604             # cms_fy2026_allotments.csv (§7.1)
CO_NOA_DATE     <- as.Date("2025-12-29")
CO_ANNOUNCED    <- as.Date("2026-09-28")
CO_LINES        <- 92L
CO_ROSTER_TOTAL <- 170210575.26
CO_RELEASE_TOTAL <- 169587181
CO_AW_DIR       <- file.path("data", "evidence", "CO")
CO_FEDERAL      <- file.path("data", "evidence", "federal_records", "2026-10-01")
CO_CSV          <- here::here("data", "reference", "co_year1_awardees.csv")
CO_STATUS_CSV   <- here::here("data", "reference", "co_year1_status.csv")
CO_AW_AGENT     <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                          "+https://www.aha.org)")
CO_ROSTER_URL   <- "https://hcpf.colorado.gov/RHTP-awardees"

CO_SOURCES <- tibble::tribble(
  ~key, ~url, ~file,
  "awardees", CO_ROSTER_URL,
  file.path(CO_AW_DIR, "2026-10-01_hcpf_rhtp_awardees.html"),
  "programme", "https://hcpf.colorado.gov/rural-health-transformation-program",
  file.path(CO_AW_DIR, "2026-10-01_hcpf_rhtp_programme.html"),
  "release", "https://hcpf.colorado.gov/press-release/colorado-awards-rural-healthcare-providers",
  file.path(CO_AW_DIR, "2026-10-01_hcpf_release_2026-09-28.html"),
  "cms_release", paste0("https://www.cms.gov/newsroom/press-releases/",
                        "trump-administration-announces-169-million-expand-",
                        "specialty-care-strengthen-emergency-services-bring"),
  file.path(CO_AW_DIR, "2026-10-01_cms_release_co_2026-09-28.html"))

# -- the roster ----------------------------------------------------------------

#' The 92 lines under "Our Awardees", from the archived page (or raw live bytes)
co_parse_roster <- function(src = here::here(CO_SOURCES$file[1])) {
  h <- xml2::read_html(src)
  li <- xml2::xml_find_all(
    h, "//h2[normalize-space()='Our Awardees']/following-sibling::ul[1]/li")
  if (!length(li)) {
    stop("[CO] no list follows the 'Our Awardees' heading. The page, not ",
         "Colorado's awards, has changed shape: re-read it (§0.4).", call. = FALSE)
  }
  t <- stringr::str_squish(rvest::html_text2(li))
  m <- stringr::str_match(t, "^(.*\\S)\\s+-\\s+\\$([0-9,]+(?:\\.[0-9]{2})?)$")
  if (anyNA(m[, 1])) {
    stop("[CO] lines not of the shape '<name> - $<amount>': ",
         paste(rhtp_watch_quote(t[is.na(m[, 1])]), collapse = " | "), call. = FALSE)
  }
  d <- tibble::tibble(line = t, awardee_raw = m[, 2],
                      amount = as.numeric(gsub(",", "", m[, 3])))
  # The SITE is the parenthetical on a line whose recipient is a multi-hospital
  # association; elsewhere a parenthetical is an acronym, a dba or a partner
  # note, and it stays in the awardee string as the state printed it.
  site <- stringr::str_match(d$awardee_raw, "\\((Regional Medical Center|Conejos County Hospital)\\)$")[, 2]
  d$site <- site
  d$awardee <- d$awardee_raw
  d
}

co_assert_roster <- function(d = co_parse_roster()) {
  if (nrow(d) != CO_LINES) {
    stop("[CO] the roster parses to ", nrow(d), " lines, not 92.", call. = FALSE)
  }
  if (abs(sum(d$amount) - CO_ROSTER_TOTAL) > 0.005) {
    stop("[CO] the roster sums to $", format(sum(d$amount), nsmall = 2,
                                              big.mark = ","),
         ", not $170,210,575.26.", call. = FALSE)
  }
  if (length(unique(d$awardee)) != 91L) {
    stop("[CO] the roster carries ", length(unique(d$awardee)), " distinct ",
         "strings, not 91 (Banner Health Foundation twice).", call. = FALSE)
  }
  gap <- sum(d$amount) - CO_RELEASE_TOTAL
  ec <- d$amount[grepl("Every Child Pediatrics", d$awardee, fixed = TRUE)]
  if (abs(gap - 623394.26) > 0.005 || length(ec) != 1L || abs(ec - gap - 1) > 0.005) {
    stop("[CO] the roster-vs-release gap is no longer $623,394.26 against the ",
         "Every Child line's $623,395.26. Re-read both before restating it.",
         call. = FALSE)
  }
  if (sum(!is.na(d$site)) != 2L) stop("[CO] expected two SITE lines.", call. = FALSE)
  raw <- paste(readLines(here::here(CO_SOURCES$file[1]), warn = FALSE), collapse = " ")
  for (p in c("Centers for Medicare", "financial assistance award", "Total")) {
    if (grepl(p, raw, fixed = TRUE)) {
      stop("[CO] the awardee page now contains '", p, "'. It carried none on ",
           "2026-10-01; a total or a footer changes what this file can claim.",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}

co_assert_releases <- function() {
  r <- rhtp_watch_reduce(here::here(CO_SOURCES$file[3]))
  rhtp_watch_require(r, c(
    "Colorado is directing $169,587,181 in Rural Health Transformation Program (RHTP) grants",
    "91 applicants and approximately 250 projects were selected to receive RHTP funding",
    "A complete list of Colorado Rural Health Transformation Program awardees"),
    CO_STATE, "HCPF's 2026-09-28 release")
  c <- rhtp_watch_reduce(here::here(CO_SOURCES$file[4]))
  rhtp_watch_require(c, c("91 grantees", "$169.6 million"), CO_STATE,
                     "CMS's 2026-09-28 release")
  p <- rhtp_watch_reduce(here::here(CO_SOURCES$file[2]))
  rhtp_watch_require(p, "RHTP Awardees", CO_STATE, "the programme page")
  # §0.2: both HCPF footers carry the ALLOTMENT. HCPF's wording ("Colorado's
  # award totals $X ... and is 100% funded by CMS") is not the "financial
  # assistance award totaling" form rhtp_footer_parse() reads, so the sentence
  # is required verbatim and its figure goes through the tier rule by hand.
  foot <- "Colorado’s award totals $200,105,604.17 for the first year of the program"
  rhtp_watch_require(gsub("'", "’", r), c(foot, "100% funded by CMS"),
                     CO_STATE, "HCPF release footer")
  # The programme page states the same figure in its body, not a footer.
  rhtp_watch_require(p, "Colorado was awarded $200,105,604.17 in budget year one.",
                     CO_STATE, "the programme page")
  rhtp_assert_footer_not_allotment(200105604.17, CO_STATE, "STATE_ALLOTMENT",
                                   label = "CO HCPF footer")
  if (!(CO_ANNOUNCED > CO_NOA_DATE)) stop("[CO] date test.", call. = FALSE)
  invisible(TRUE)
}

# -- typing --------------------------------------------------------------------

co_norm <- function(x) {
  x <- toupper(x)
  x <- gsub("[.,'’/&()-]", " ", x)
  x <- stringr::str_squish(gsub("[^A-Z0-9 ]", "", x))
  x <- sub("^THE ", "", x)
  sub(" (INC|INCORPORATED|LLC|PLLC|PC)$", "", x)
}

co_halves <- function(a) {
  a <- sub("\\s*\\([^)]*\\)$", "", a)
  parts <- stringr::str_split(a, stringr::regex(",?\\s+(dba|d/b/a)\\s+", ignore_case = TRUE))[[1]]
  unique(co_norm(c(a, parts)))
}

co_federal <- function() {
  rd <- function(f, k) {
    j <- jsonlite::fromJSON(here::here(CO_FEDERAL, f))
    tibble::tibble(kind = k, ccn = j$CCN, org = j$`ORGANIZATION NAME`,
                   dba = j$`DOING BUSINESS AS NAME`, city = j$CITY)
  }
  dplyr::bind_rows(rd("cms_hosp_enrollments_CO.json", "HOSPITAL"),
                   rd("cms_fqhc_enrollments_CO.json", "FQHC"),
                   rd("cms_rhc_enrollments_CO.json", "RHC"))
}

co_federal_match <- function(awardee, f = co_federal()) {
  h <- co_halves(awardee)
  f[co_norm(f$org) %in% h | co_norm(dplyr::coalesce(f$dba, "")) %in% h, ]
}

# Hand-read decisions. Everything else is a federal-record match, a determined
# form the classifier reads from the state's own string, or §8's fallback.
CO_OVERRIDES <- tibble::tribble(
  ~awardee, ~recipient_type, ~basis_type, ~confidence, ~ccn, ~why,
  "Banner Health Foundation", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", NA,
  "§10.2 HOSPITAL-FOUNDATION ROW: the foundation of a NAMED health system, Banner Health, which CMS CO Hospital Enrollment carries as BANNER HEALTH (CCN 060126, Fort Collins) and which operates North Colorado Medical Center and Sterling Regional MedCenter. The parent tie is read from the name, so LOW and subtractable. Two lines, priced separately, not merged.",
  "Board of Trustees of Lincoln Community Hospital d/b/a Lincoln Health", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "061306",
  "HAND-READ BRIDGE: CMS CO Hospital Enrollment carries LINCOLN COMMUNITY HOSPITAL dba LINCOLN HEALTH HOSPITAL (CAH, CCN 061306, Hugo). The awardee is that hospital's board of trustees; the string is not the enrolled name, so LOW.",
  "Delta County Memorial Hospital District", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "060071",
  "HAND-READ BRIDGE: CMS CO Hospital Enrollment carries DELTA COUNTY MEMORIAL HOSPITAL (CCN 060071, Delta). The awardee adds 'District'; the enrolled name is a prefix of it, which §2 forbids a machine resolving, so LOW.",
  "East Phillips County Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "061305",
  "HAND-READ BRIDGE (LEGAL_NAME_TRUNCATED): CMS CO Hospital Enrollment carries EAST PHILLIPS COUNTY HOSPITAL DISTRICT dba MELISSA MEMORIAL HOSPITAL (CAH, CCN 061305, Holyoke). The awardee string drops 'District', so LOW.",
  "Kit Carson County Health Service District", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "061313",
  "HAND-READ BRIDGE: CMS CO Hospital Enrollment carries KIT CARSON COUNTY HEALTH SERVICES DISTRICT dba KIT CARSON COUNTY MEMORIAL HOSPITAL (CAH, CCN 061313, Burlington). 'Service' against 'Services', so LOW.",
  "Yuma Hospital District dba Yuma District Hospital and Clinics", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "061315",
  "HAND-READ BRIDGE: CMS CO Hospital Enrollment carries YUMA DISTRICT HOSPITAL (CAH, CCN 061315). The dba adds 'and Clinics', so LOW.",
  "Walsh Hospital District", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "GENERAL_KNOWLEDGE", "LOW", NA,
  "A HOSPITAL DISTRICT THAT IS NOT A HOSPITAL (§10.2, §0.4): no CMS CO Hospital Enrollment record. Its only federal record is an RHC, WALSH HOSPITAL DISTRICT HEALTHCARE CENTER dba WALSH MEDICAL CLINIC (063874). A Colorado special district is a local government; the name is not an enrolment. Queued.",
  "West Custer County Hospital District", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "GENERAL_KNOWLEDGE", "LOW", NA,
  "A HOSPITAL DISTRICT THAT IS NOT A HOSPITAL (§10.2, §0.4): no CMS CO enrolment of any kind under this name. The Westcliffe clinic in its territory is enrolled under SALIDA HOSPITAL DISTRICT as CUSTER COUNTY HEALTH CENTER (RHC 063422). A special district, not a hospital. Queued.",
  "Ute Pass Regional Health Services District", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "GENERAL_KNOWLEDGE", "LOW", NA,
  "A Colorado health-services special district with no CMS hospital, FQHC or RHC enrolment. A local government; not a hospital on any record.",
  "Cheyenne County dba Plains to Peaks RETAC", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM", NA,
  "A county government, stated in the state's own string, acting as fiscal agent for a Regional Emergency Medical and Trauma Advisory Council.",
  "County of Logan", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM", NA,
  "A county government; the form is in the state's own string.",
  "City of Yuma, Colorado, operating the City of Yuma Ambulance Service", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM", NA,
  "A municipal government operating an ambulance service, both stated in the state's own string. Not Yuma District Hospital, a different recipient on this roster.",
  "Upper Arkansas Council of Governments", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM", NA,
  "A regional council of governments; the form is in the state's own string.",
  "Delta County Ambulance District", "EMS_OR_PSAP", "STATE_SOURCE", "MEDIUM", NA,
  "An ambulance district; the form is in the state's own string. Not Delta County Memorial Hospital District, a different recipient on this roster.",
  "Western Regional EMS Council Inc, DBA WRETAC", "EMS_OR_PSAP", "STATE_SOURCE", "MEDIUM", NA,
  "A regional EMS and trauma advisory council; EMS is in the state's own string.",
  "Fort Lewis Mesa Fire Protection District", "EMS_OR_PSAP", "STATE_SOURCE", "MEDIUM", NA,
  "A fire protection district; the form is in the state's own string.",
  "Red White & Blue Fire Protection District", "EMS_OR_PSAP", "STATE_SOURCE", "MEDIUM", NA,
  "A fire protection district; the form is in the state's own string.",
  "Event Medical Solutions Unlimited, LLC dba EMS Unlimited", "EMS_OR_PSAP", "STATE_SOURCE", "MEDIUM", NA,
  "A private EMS company; 'EMS' is in the state's own dba.",
  "Colorado Mountain College (CMC)", "UNIVERSITY_OR_AHC", "STATE_SOURCE", "MEDIUM", NA,
  "A public college; the form is in the state's own string.",
  "Telluride Regional Medical Center", "NONPROFIT_CBO", NA, "LOW", NA,
  "'MEDICAL CENTER' IS A NAME, NOT AN ENROLMENT: no CMS CO Hospital, FQHC or RHC Enrollment record under this name. §8's standing fallback, NOT promoted (§0.4). Queued.",
  "Four Corners Ob/Gyn", "PHYSICIAN_PRACTICE", "STATE_SOURCE", "MEDIUM", NA,
  "An obstetrics and gynaecology practice; the specialty is the state's own string and no institutional enrolment exists under it.",
  "La Plata Family Medicine Associates P.C.", "PHYSICIAN_PRACTICE", "STATE_SOURCE", "MEDIUM", NA,
  "A professional corporation of family physicians; 'P.C.' and 'Family Medicine Associates' are the state's own string.",
  "Midvalley Family Practice PC", "PHYSICIAN_PRACTICE", "STATE_SOURCE", "MEDIUM", NA,
  "A professional corporation family practice; the form is in the state's own string.",
  "Pediatrics of Steamboat Springs, P.C.", "PHYSICIAN_PRACTICE", "STATE_SOURCE", "MEDIUM", NA,
  "A professional corporation pediatric practice; the form is in the state's own string.",
  "Epifluence Health PLLC", "PHYSICIAN_PRACTICE", "STATE_SOURCE", "LOW", NA,
  "A professional limited liability company (PLLC is a licensed-professional form in the state's own string). A DIFFERENT LEGAL FORM from the three 'Epifluence LLC' lines; not merged with them (§2).",
  "Rocky Mountain Youth Medical & Nursing Consultants, Inc. dba Every Child Pediatrics", "PHYSICIAN_PRACTICE", "GENERAL_KNOWLEDGE", "LOW", NA,
  "A pediatric practice by its dba. THE ONLY LINE WITH CENTS, AND WITHIN $1.00 OF THE ROSTER-VS-RELEASE GAP ($623,394.26); see the header. Kept, never dropped on arithmetic.",
  "Pediatric Partners of the Southwest", "PHYSICIAN_PRACTICE", "GENERAL_KNOWLEDGE", "LOW", NA,
  "A pediatric group practice by name; no institutional enrolment under it."
)

# The two San Luis Valley lines name their SITE in brackets. Each site is one
# of the association's two enrolled hospitals, read by hand from the CO
# Hospital Enrollment file (DBA and city), and checked against it per row.
CO_SITE_CCN <- c(
  "Regional Medical Center" = "060008",   # SLV HEALTH REGIONAL MEDICAL CENTER, Alamosa
  "Conejos County Hospital" = "061308")   # SAN LUIS VALLEY HEALTH (CAH), La Jara

co_year1_awardees <- function(d = co_parse_roster()) {
  f <- co_federal()
  cls <- rhtp_classify_recipient_type(d$awardee, CO_STATE)
  out <- vector("list", nrow(d))
  for (i in seq_len(nrow(d))) {
    a <- d$awardee[i]
    ccn_i <- NA_character_
    hit <- co_federal_match(a, f)
    ov <- CO_OVERRIDES[CO_OVERRIDES$awardee == a, ]
    if (nrow(ov)) {
      rt <- ov$recipient_type; bt <- ov$basis_type; cf <- ov$confidence
      why <- ov$why; how <- "HAND-READ"; ccn_i <- ov$ccn
    } else if (nrow(hit)) {
      k <- if ("HOSPITAL" %in% hit$kind) "HOSPITAL" else
        if ("FQHC" %in% hit$kind) "FQHC" else "RHC"
      hk <- hit[hit$kind == k, ]
      rt <- if (k == "HOSPITAL") "HOSPITAL_OR_SYSTEM" else "FQHC_OR_RHC"
      bt <- "ORG_WEBSITE"; cf <- "MEDIUM"; how <- "FEDERAL RECORD"
      six <- sort(unique(hk$ccn[grepl("^[0-9]{6}$", hk$ccn) |
                                  grepl("^[0-9]{5}$", hk$ccn)]))
      six <- sprintf("%06d", as.integer(six))
      if (k == "HOSPITAL" && !is.na(d$site[i])) {
        at <- CO_SITE_CCN[[d$site[i]]]
        if (!at %in% sprintf("%06d", suppressWarnings(as.integer(hk$ccn)))) {
          stop("[CO] site CCN ", at, " is not among the enrolment's CCNs for '",
               a, "'.", call. = FALSE)
        }
        six <- at
      }
      one <- k == "HOSPITAL" && length(six) == 1L
      ccn_i <- if (one) six else NA_character_
      why <- paste0("EXACT federal record: CMS CO ",
                    c(HOSPITAL = "Hospital", FQHC = "FQHC", RHC = "RHC")[[k]],
                    " Enrollment carries this string (or its dba) as an ORGANIZATION NAME or DBA ",
                    ifelse(one, paste0("at CCN ", six),
                           paste0("at CCNs ", paste(six, collapse = "/"))),
                    ifelse(k == "HOSPITAL" && any(hit$kind != "HOSPITAL"),
                           "; its RHC/FQHC records are the same legal entity's", ""), ".")
    } else if (cls$recipient_type[i] == "HOSPITAL_OR_SYSTEM") {
      stop("[CO] the classifier calls '", a, "' a hospital and no federal record ",
           "or hand-read decision covers it. Read it.", call. = FALSE)
    } else if (cls$recipient_type[i] %in% c("UNIVERSITY_OR_AHC", "EMS_OR_PSAP",
                                            "FQHC_OR_RHC", "LOCAL_GOVT_OR_PUBLIC_HEALTH",
                                            "SCHOOL_OR_DISTRICT", "TRIBAL_ORG") &&
               cls$determination_confidence[i] != "LOW") {
      rt <- cls$recipient_type[i]; bt <- "STATE_SOURCE"
      cf <- cls$determination_confidence[i]; how <- "CLASSIFIER"
      why <- "The form is in the state's own string, and the shared classifier's name rule reads it."
    } else {
      rt <- "NONPROFIT_CBO"; bt <- NA_character_; cf <- "LOW"; how <- "FALLBACK"
      why <- "The source states no form and no CMS CO Hospital, FQHC or RHC enrolment carries the string (§8's standing fallback, RECIPIENT_TYPE_INFERRED); queued as CO_RECIPIENT_FORM_NOT_STATED."
    }
    hosp <- rt == "HOSPITAL_OR_SYSTEM"
    if (hosp) {
      flow <- "DIRECT"; dth <- "Yes"
    } else if (rt %in% c("FQHC_OR_RHC", "PHYSICIAN_PRACTICE", "LOCAL_GOVT_OR_PUBLIC_HEALTH",
                         "EMS_OR_PSAP", "UNIVERSITY_OR_AHC", "NONPROFIT_CBO")) {
      flow <- "NON_HOSPITAL"; dth <- "No"
    } else {
      stop("[CO] no flow rule for ", rt, " ('", a, "').", call. = FALSE)
    }
    fallback <- how == "FALLBACK" || (how == "HAND-READ" && rt == "NONPROFIT_CBO")
    out[[i]] <- tibble::tibble(
      recipient_type = rt, distributed_to_hospital = dth, flow_type = flow,
      basis_type = bt, determination_confidence = cf, typing = how, why = why,
      ccn = ccn_i, classifier = paste0(cls$recipient_type[i], "/",
                                      cls$determination_confidence[i]),
      fallback = fallback)
  }
  t <- dplyr::bind_rows(out)
  hosp <- t$recipient_type == "HOSPITAL_OR_SYSTEM"
  tibble::tibble(
    state = CO_STATE,
    row_no = seq_len(nrow(d)),
    awardee = d$awardee,
    amount = d$amount,
    recipient_type = t$recipient_type,
    distributed_to_hospital = t$distributed_to_hospital,
    note = paste0("HCPF RHTP award line, announced 2026-09-28 ('organizations ",
                  "selected to receive funding').",
                  ifelse(is.na(d$site), "", paste0(" SITE (not the recipient): ", d$site, "."))),
    recipient_confirmed = "Yes",
    amount_confirmed = "Yes",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = "HCPF, About our RHTP Awardees (Our Awardees), read 2026-10-01",
    state_source_url = CO_ROSTER_URL,
    validation_source_type = "AGENCY_PRESS_RELEASE",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03bo_co_year1_awardees.R",
    ccn = t$ccn,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    award_pool = "Colorado RHTP subrecipient grants, round announced 2026-09-28",
    site = d$site,
    recipient_type_source = paste0("TYPED (session 82, ", t$typing, "): ", t$why,
                                   " Classifier said ", t$classifier, "."),
    determination_confidence = t$determination_confidence,
    flag_reason = ifelse(t$fallback, "RECIPIENT_TYPE_INFERRED", NA_character_),
    budget_period = "Budget Period 1",
    flow_type = t$flow_type,
    hospital_benefiting = ifelse(hosp, "Yes", "Unclear"),
    hospital_attribution = ifelse(hosp, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = paste0("§10.2 ", t$flow_type, ": ", t$why,
                                 ifelse(hosp, " §0.3a: the recipient is a hospital whatever the activity.", "")),
    amount_basis = paste0("The line's own amount on HCPF's awardee page, exact. ",
                          "THE PAGE PRINTS NO TOTAL: its 92 lines sum to $170,210,575.26, ",
                          "against HCPF's release figure of $169,587,181 ($623,394.26 apart). ",
                          "Neither is adjusted here; see co_year1_status.csv."),
    basis_type = t$basis_type,
    round_amount = NA_real_,
    announcement_date = CO_ANNOUNCED,
    source_archive_path = CO_SOURCES$file[1])
}

co_assert_typing <- function(a = co_year1_awardees()) {
  h <- a[a$distributed_to_hospital == "Yes", ]
  if (any(h$recipient_type != "HOSPITAL_OR_SYSTEM") || any(h$flow_type != "DIRECT")) {
    stop("[CO] a Yes row is not a DIRECT hospital row.", call. = FALSE)
  }
  if (any(h$determination_confidence == "HIGH")) {
    stop("[CO] HIGH needs a CCN match in Stage 5 (§7).", call. = FALSE)
  }
  not_h <- c("Walsh Hospital District", "West Custer County Hospital District",
             "Lake Fork Health Services District", "Telluride Regional Medical Center",
             "Ute Pass Regional Health Services District")
  if (any(a$distributed_to_hospital[a$awardee %in% not_h] != "No")) {
    stop("[CO] a district or 'medical center' with no hospital enrolment came ",
         "out a hospital. The name is not the enrolment (§0.4).", call. = FALSE)
  }
  if (!all(a$distributed_to_hospital[a$awardee == "Banner Health Foundation"] == "Yes")) {
    stop("[CO] Banner Health Foundation is §10.2's hospital-foundation row.", call. = FALSE)
  }
  if (any(!a$recipient_type %in% rhtp_vocabulary("recipient_type"))) {
    stop("[CO] a recipient_type outside §8.", call. = FALSE)
  }
  invisible(TRUE)
}

co_status_table <- function(a = co_year1_awardees()) {
  h <- a[a$distributed_to_hospital == "Yes", ]
  tibble::tribble(
    ~state, ~channel, ~stage, ~publishes_roster, ~note,
    CO_STATE, "HCPF 'About our RHTP Awardees' page, linked from the RHTP programme page",
    "AWARDED_ROSTER_PUBLISHED", "Yes",
    paste0("92 priced lines, 91 distinct strings, NO TOTAL PRINTED: the lines sum to $170,210,575.26. ",
           nrow(h), " named-hospital lines, $", format(sum(h$amount), big.mark = ","),
           ", typed on CMS CO enrolment files. 'Approximately 250 projects' are behind these lines; the page prices organisations, not projects."),
    CO_STATE, "HCPF release, 2026-09-28 (and CMS's the same day)", "TOTAL_CONFLICTS_WITH_ROSTER", "No",
    paste0("HCPF: '$169,587,181' and '91 applicants'. CMS: '$169.6 million', '91 grantees'. ",
           "The roster is $623,394.26 higher. The Every Child Pediatrics line, $623,395.26, ",
           "is within $1.00 of the gap; a line added after the release would explain both the ",
           "dollars and the 92-vs-91 count. That is ARITHMETIC, NOT A STATEMENT BY HCPF: no ",
           "state total is published from this file until HCPF reconciles it (queued ",
           "CO_ROSTER_VS_RELEASE_TOTAL)."),
    CO_STATE, "Year 1 coverage", "PARTIAL_OR_UNSTATED", "n/a",
    paste0("The round is $169.6M of a $200,105,604 allotment; CMS calls it 'one part of the ",
           "larger overall funding amount'. HCPF's earlier Colorado Rural Health Center ",
           "technical-assistance contract is not on this page and is not in this file.")
  )
}

# -- the watch -----------------------------------------------------------------

CO_PROBE_PAGES <- tibble::tribble(
  ~key, ~url, ~file, ~name_diff,
  "awardees", CO_ROSTER_URL, CO_SOURCES$file[1], TRUE,
  "programme", CO_SOURCES$url[2], CO_SOURCES$file[2], TRUE)

#' TRIPWIRE: the roster's line count or total moved
co_assert_roster_unchanged <- function(raw) {
  d <- co_parse_roster(raw)
  if (nrow(d) != CO_LINES || abs(sum(d$amount) - CO_ROSTER_TOTAL) > 0.005) {
    stop("[CO] THE AWARDEE ROSTER MOVED: ", nrow(d), " lines, $",
         format(sum(d$amount), nsmall = 2, big.mark = ","), " (recorded: 92 lines, ",
         "$170,210,575.26). Diff it against data/evidence/CO/ on name AND amount, ",
         "then --fetch --force and rebuild (§2.2).", call. = FALSE)
  }
  invisible(d)
}

co_awardee_probe <- function() {
  w <- rhtp_watch_pages(CO_PROBE_PAGES, CO_AW_AGENT)
  co_assert_roster_unchanged(w$raw$awardees)
  rhtp_assert_no_new_organisations_across(live = w$live, archived = w$arch,
                                          state = CO_STATE)
  message("[CO] ", paste0(w$changed$key, ": ",
                          ifelse(w$changed$changed, "CHANGED", "UNCHANGED"),
                          collapse = "; "), " -- roster unchanged (92 lines).")
  invisible(w$changed)
}

co_fetch <- function() {
  for (i in seq_len(nrow(CO_SOURCES))) {
    rhtp_watch_archive(CO_SOURCES$url[i], CO_SOURCES$file[i], CO_AW_AGENT)
  }
  message("[CO] archived ", nrow(CO_SOURCES), " sources under ", CO_AW_DIR)
}

co_validate <- function() {
  d <- co_parse_roster()
  co_assert_roster(d)
  co_assert_releases()
  a <- co_year1_awardees(d)
  co_assert_typing(a)
  message("[CO] all assertions pass.")
  invisible(a)
}

co_build <- function() {
  a <- co_validate()
  readr::write_csv(a, CO_CSV, na = "")
  readr::write_csv(co_status_table(a), CO_STATUS_CSV, na = "")
  h <- a[a$distributed_to_hospital == "Yes", ]
  message(sprintf("[CO] wrote %d award lines; %d named-hospital lines, $%s.",
                  nrow(a), nrow(h), format(sum(h$amount), big.mark = ",")))
}

co_report <- function() {
  a <- co_year1_awardees()
  print(a %>% dplyr::count(recipient_type, distributed_to_hospital,
                           determination_confidence, wt = amount, name = "dollars"),
        n = 50)
  h <- a[a$distributed_to_hospital == "Yes", ]
  cat(sprintf("\n%d lines, $%s; %d named-hospital lines, $%s (%.1f%%); LOW $%s.\n",
              nrow(a), format(sum(a$amount), nsmall = 2, big.mark = ","), nrow(h),
              format(sum(h$amount), big.mark = ","), 100 * sum(h$amount) / sum(a$amount),
              format(sum(h$amount[h$determination_confidence == "LOW"]), big.mark = ",")))
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) co_fetch()
  if ("--validate" %in% args) co_validate()
  if ("--build" %in% args) co_build()
  if ("--probe" %in% args) rhtp_probe_run("CO", co_awardee_probe())
  if ("--report" %in% args) co_report()
  if (!length(args)) message("Usage: --fetch | --validate | --build | --probe | --report")
}
