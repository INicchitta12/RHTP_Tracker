#!/usr/bin/env Rscript
# 03bi_in_grow_regional_awardees.R -------------------------------------------
#
# INDIANA'S GROW REGIONAL GRANTS -- 186 RECIPIENT ROWS, 178 DISTINCT NAMES,
# EIGHT REGIONS, AND NOT ONE PER-ORGANISATION AMOUNT.
#
# Indiana's hospital-facing RHTP vehicle awarded on 2026-09-03. Eight IDOH
# releases, one per region, each say "Gov. Mike Braun announced today that
# the <region> Indiana region (Region N) has been awarded $X million in Growing
# Rural Opportunities for Well-being (GROW) initiative grants". The GROW
# Regional Grants page then says "nearly 200 subrecipients have been selected"
# and prints one "Grant Recipient Organizations" table per region: 186 rows,
# 178 distinct names. NOBODY IS PRICED. This is Iowa's and Nevada's shape at
# region grain, so:
#
#   * `amount` is EMPTY on every row. The partition therefore reports named-
#     hospital ROWS with $0 of dollars, and both halves are true at once. READ
#     THE ROW COUNT.
#   * the region's published figure sits in `round_amount` and is NEVER divided
#     (§6.2). It repeats on every row of its region, so summing the column
#     gives a figure Indiana never published (Georgia's trap, Nevada's device);
#     `ig_reconcile()` sums distinct (region, round_amount) pairs and refuses
#     the column sum.
#   * the region figures are ROUNDED in source ("$12.6 million"), and sum to
#     $112.4M. The Surplus Award Summary adds $16,249,593.22 = Regional
#     Surplus $8,724,000 + Statewide Surplus $7,525,593.22, attached to no
#     recipient; it lives in the status table and never in `round_amount`.
#
# §6.2 PROVENANCE. Every release carries the CMS financial-assistance footer,
# and its figure is $206,927,896.80 -- INDIANA'S ALLOTMENT, Tier 1 (§0.2). It
# is declared STATE_ALLOTMENT and tier-checked, and it carries no provenance
# weight. The provenance is programme-scoped prose on both documents: the
# releases' "supported by the Indiana Rural Health Transformation Program
# (RHTP), administered by the Indiana Department of Health", and the page's
# "The GROW (Growing Rural Opportunities for Well-being) initiative brings the
# federal RHTP program to the state level". The date test passes (2026-09-03
# against the 2025-12-29 NOA).
#
# §7 / §10.2: THE PASS-THROUGH QUESTION IS ANSWERED BY INDIANA, NOT BY US. The
# page's own FAQ: "If your organization's project is submitted as part of the
# regional application and approved, you will be awarded funding from the
# Indiana Department of Health through a subgrant contractual agreement" and
# "Primary subrecipients will be prohibited from awarding funds granted by the
# State to other subrecipients via sub-awards/sub-grants." Every listed
# organisation is a DIRECT subrecipient of IDOH, and none may pass money on --
# so the coalitions, foundations and councils in these tables are NOT pass-
# throughs, and no row is PASS_THROUGH_*. The eight "Regional Grant
# Coordinators" are state hires and are not recipients.
#
# TYPING -- ON CMS'S INDIANA ENROLMENT FILES, NOT ON NAMES (New Jersey's
# pattern, R/03bf). The Hospital, FQHC and RHC Enrollment files are archived
# under data/evidence/federal_records/2026-09-24/. A recipient string equal to
# an ORGANIZATION NAME or DBA there (after case, punctuation, a leading THE and
# a trailing INC are set aside) is typed from that record at ORG_WEBSITE /
# MEDIUM. A hospital corporation that also enrols its own RHCs (HOSPITAL+RHC)
# is a hospital. Everything else is a hand-read decision in IG_OVERRIDES, the
# shared classifier where the form is in the state's own string, or §8's
# standing fallback. What the reading found:
#
#   * The name rule MISSES Franciscan Health Rensselaer, Indiana University
#     Health Inc (three regions) and Ascension St. Vincent Jennings -- all exact
#     CMS hospital records -- and misses Union Health Inc. and St. Elizabeth
#     Dearborn, which are hand-read BRIDGES (LOW, queued).
#   * "Parkview Huntington" IS NOT A HOSPITAL. The recipient is "Parkview
#     Huntington Family Young Men's Christian Association", and the page's own
#     link is huntingtony.org. Parkview Huntington Hospital is CMS's Huntington
#     Memorial Hospital, Inc. (CCN 150091) and is NOT on this roster. §0.3a's
#     second half: read the recipient.
#   * Cummins Behavioral Health Systems is reached by the name rule on "Health
#     Systems" and is a community mental health centre with no hospital record:
#     overridden to §8's fallback.
#   * THREE COMMUNITY MENTAL HEALTH CENTRE CORPORATIONS HOLD A PSYCHIATRIC
#     HOSPITAL CCN IN THEIR OWN NAME -- Northeastern Center (154050), Hamilton
#     Center, Inc. (154009, which also holds FQHC CCNs) and INcompass
#     Healthcare (DBA of "Community Mental Health Center Inc.", 154011). The
#     federal record types them HOSPITAL_OR_SYSTEM and this file follows it,
#     queued as IN_GROW_CMHC_HOLDS_HOSPITAL_CCN so a reader can subtract them
#     (South Carolina's Acadia shape).
#   * Region 8's "Ascension St. Vincent" is not enrolled under that string; the
#     page's own hyperlink is Ascension St. Vincent Evansville (CMS: St Marys
#     Health Inc, CCN 150100). A bridge, LOW. RCJ calls the same row "St.
#     Mary's" -- CMS's legal name, not the state's.
#   * Region 8's "Good Samaritan Hospital" matches CMS's Vincennes hospital
#     (CCN 150042) exactly, while the page's link points at TriHealth's Good
#     Samaritan Hospital in CINCINNATI. Recorded, not corrected: both are
#     hospitals and the typing does not depend on it.
#
# OBSERVATIONS, NOT CORRECTIONS (§8). Region 3's release reads "Gov. Mike
# Braum". Regions 3 and 5 are both titled "West-Central Indiana Region". The
# page prints "Well County Council on Aging" (Wells) and "LifsSpring, Inc."
# beside "Lifespring Inc." Every string is kept as published.
#
# Usage:
#   Rscript R/03bi_in_grow_regional_awardees.R --validate  # assertions, offline
#   Rscript R/03bi_in_grow_regional_awardees.R --build     # writes the two CSVs
#   Rscript R/03bi_in_grow_regional_awardees.R --probe     # LIVE, READ-ONLY
#   Rscript R/03bi_in_grow_regional_awardees.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_pdf_text.R"))
source(here::here("R", "utils_recipient_classification.R"))
source(here::here("R", "utils_page_watch.R"))

IG_STATE      <- "IN"
IG_ANNOUNCED  <- as.Date("2026-09-03")
IG_RECHECK    <- file.path("data", "evidence", "recheck", "2026-09-24", "IN")
IG_PAGE       <- file.path(IG_RECHECK, "grow_regional_grants_page.html")
IG_SOURCES    <- file.path(IG_RECHECK, "SOURCES.txt")
IG_RELEASE    <- function(r) file.path(IG_RECHECK,
                                       sprintf("idoh_region_%d_press_release.pdf", r))
IG_FEDERAL    <- file.path("data", "evidence", "federal_records", "2026-09-24")
IG_PAGE_URL   <- "https://www.in.gov/grow-rural-health/regional-grants/"
IG_CSV        <- here::here("data", "reference", "in_grow_regional_awardees.csv")
IG_STATUS_CSV <- here::here("data", "reference", "in_grow_regional_status.csv")
IG_USER_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                        "+https://www.aha.org)")

# What the sources say, pinned so a moved page fails rather than drifts.
IG_ROWS_EXPECTED     <- 186L
IG_DISTINCT_EXPECTED <- 178L
IG_REGION_ROWS <- c(`1` = 26L, `2` = 29L, `3` = 23L, `4` = 24L, `5` = 16L,
                    `6` = 32L, `7` = 22L, `8` = 14L)
IG_REGION_MILLIONS <- c(`1` = 12.6, `2` = 20.7, `3` = 9.7, `4` = 15.2,
                        `5` = 16.7, `6` = 13.0, `7` = 13.1, `8` = 11.4)
IG_REGION_TOTAL      <- 112400000
IG_SURPLUS_TOTAL     <- 16249593.22
IG_SURPLUS_REGIONAL  <- 8724000
IG_SURPLUS_STATEWIDE <- 7525593.22
IG_FOOTER_ALLOTMENT  <- 206927896.80

IG_PAGE_SENTENCES <- c(
  selected = "nearly 200 subrecipients have been selected",
  programme = "The GROW (Growing Rural Opportunities for Well-being) initiative brings the federal RHTP program to the state level",
  direct = "you will be awarded funding from the Indiana Department of Health through a subgrant contractual agreement",
  no_subaward = "Primary subrecipients will be prohibited from awarding funds granted by the State to other subrecipients via sub-awards/sub-grants")

IG_RELEASE_SENTENCES <- c(
  "supported by the Indiana Rural Health Transformation Program (RHTP), administered by the Indiana Department of Health",
  "About $120 million, or 60% of that funding, was earmarked for the regional grants")

# -- the archive -------------------------------------------------------------

#' The nine files session 61 archived must still be the bytes it hashed.
ig_assert_archive <- function() {
  s <- utils::read.delim(here::here(IG_SOURCES), comment.char = "#",
                         header = FALSE, stringsAsFactors = FALSE)
  names(s)[c(1, 6)] <- c("file", "sha256")
  for (i in seq_len(nrow(s))) {
    got <- digest::digest(file = here::here(IG_RECHECK, s$file[i]), algo = "sha256")
    if (!identical(got, s$sha256[i])) {
      stop("[IN-GROW] ", s$file[i], " no longer matches its SOURCES.txt digest.",
           call. = FALSE)
    }
  }
  invisible(nrow(s))
}

# -- the page ----------------------------------------------------------------

ig_read_html <- function(raw = here::here(IG_PAGE)) xml2::read_html(raw)

#' One row per cell of each region's "Grant Recipient Organizations" table,
#' in the page's own reading order. Empty spacer cells are dropped; nothing
#' else is. The state's own hyperlink is kept (query string dropped) because it
#' is sometimes the only thing that identifies the recipient.
ig_parse_page <- function(raw = here::here(IG_PAGE)) {
  h <- ig_read_html(raw)
  out <- list()
  for (r in seq_len(8)) {
    div <- rvest::html_element(h, paste0("div#Region_", r))
    if (inherits(div, "xml_missing")) {
      stop("[IN-GROW] the page has no Region_", r, " panel.", call. = FALSE)
    }
    pill <- stringr::str_squish(rvest::html_text2(
      rvest::html_element(div, "span.green-pill")))
    heads <- stringr::str_squish(rvest::html_text2(rvest::html_elements(div, "h3")))
    if (!any(grepl("^Grant Recipient Organizations", heads))) {
      stop("[IN-GROW] Region ", r, " has no 'Grant Recipient Organizations' ",
           "heading.", call. = FALSE)
    }
    tabs <- rvest::html_elements(div, "table")
    if (length(tabs) != 1L) {
      stop("[IN-GROW] Region ", r, " carries ", length(tabs), " tables, not one.",
           call. = FALSE)
    }
    tds <- rvest::html_elements(tabs, "td")
    txt <- stringr::str_squish(gsub(" ", " ", rvest::html_text2(tds)))
    href <- vapply(tds, function(td) {
      v <- rvest::html_attr(rvest::html_element(td, "a"), "href")
      if (is.na(v)) NA_character_ else sub("[?#].*$", "", v)
    }, character(1))
    keep <- nzchar(txt)
    out[[r]] <- tibble::tibble(
      region = r, region_figure_as_published = pill,
      row_in_region = seq_len(sum(keep)), awardee = txt[keep],
      recipient_url = href[keep])
  }
  d <- dplyr::bind_rows(out)
  d$round_amount <- as.numeric(stringr::str_match(
    d$region_figure_as_published, "^\\$([0-9.]+) Million Awarded to Region")[, 2]) * 1e6
  d
}

ig_page_text <- function(raw = here::here(IG_PAGE)) rhtp_watch_reduce(raw)

#' Surplus Award Summary -- read, never typed.
ig_parse_surplus <- function(text = ig_page_text()) {
  grab <- function(label) {
    m <- stringr::str_match(text, paste0(label, ":\\s*\\$([0-9,]+(?:\\.[0-9]{2})?)"))[, 2]
    as.numeric(gsub(",", "", m))
  }
  c(total = grab("Total Surplus Funds Awarded"),
    regional = grab("Regional Surplus"),
    statewide = grab("Statewide Surplus"))
}

# -- the releases ------------------------------------------------------------

ig_release_text <- function(r) {
  stringr::str_squish(paste(rhtp_pdf_text(here::here(IG_RELEASE(r))), collapse = " "))
}

ig_parse_releases <- function() {
  dplyr::bind_rows(lapply(seq_len(8), function(r) {
    t <- ig_release_text(r)
    m <- stringr::str_match(t, paste0("\\(Region ", r, "\\) has been awarded \\$([0-9.]+) million"))
    tibble::tibble(
      region = r,
      label = stringr::str_match(t, "Transform Rural Healthcare in (.+?) Indiana Region")[, 2],
      date_as_published = stringr::str_match(t, "(Sept\\. [0-9]+, 2026)")[, 2],
      governor_as_published = stringr::str_match(t, "(Gov\\. Mike Bra[a-z]+) announced")[, 2],
      release_millions = as.numeric(m[, 2]),
      text = t)
  }))
}

# -- assertions --------------------------------------------------------------

ig_assert_roster <- function(d = ig_parse_page()) {
  if (nrow(d) != IG_ROWS_EXPECTED) {
    stop("[IN-GROW] the page parses to ", nrow(d), " recipient rows, not ",
         IG_ROWS_EXPECTED, ".", call. = FALSE)
  }
  if (length(unique(d$awardee)) != IG_DISTINCT_EXPECTED) {
    stop("[IN-GROW] ", length(unique(d$awardee)), " distinct names, not ",
         IG_DISTINCT_EXPECTED, ".", call. = FALSE)
  }
  n <- table(factor(d$region, levels = 1:8))
  if (!identical(as.integer(n), unname(IG_REGION_ROWS))) {
    stop("[IN-GROW] region row counts are ", paste(n, collapse = "/"),
         "; expected ", paste(IG_REGION_ROWS, collapse = "/"), ".", call. = FALSE)
  }
  # NO PER-ORGANISATION AMOUNT: the day a figure appears in a recipient cell,
  # `amount` stops being honestly empty and this file must be REWRITTEN.
  if (any(grepl("\\$|[0-9]{1,3},[0-9]{3}", d$awardee))) {
    stop("[IN-GROW] a recipient cell now carries a figure: ",
         paste(d$awardee[grepl("\\$|[0-9]{1,3},[0-9]{3}", d$awardee)], collapse = "; "),
         ". This file's empty `amount` column is only honest while Indiana ",
         "publishes none. REWRITE the file.", call. = FALSE)
  }
  got <- tapply(d$round_amount, d$region, unique)
  if (!isTRUE(all.equal(as.numeric(got), unname(IG_REGION_MILLIONS) * 1e6))) {
    stop("[IN-GROW] the page's region figures moved: ",
         paste(got / 1e6, collapse = "/"), ".", call. = FALSE)
  }
  invisible(TRUE)
}

ig_assert_page_sentences <- function(text = ig_page_text()) {
  rhtp_watch_require(text, IG_PAGE_SENTENCES, IG_STATE, "GROW Regional Grants page")
  s <- ig_parse_surplus(text)
  if (!isTRUE(all.equal(unname(s), c(IG_SURPLUS_TOTAL, IG_SURPLUS_REGIONAL,
                                     IG_SURPLUS_STATEWIDE)))) {
    stop("[IN-GROW] the Surplus Award Summary now reads ",
         paste(s, collapse = " / "), ".", call. = FALSE)
  }
  if (abs(s[["regional"]] + s[["statewide"]] - s[["total"]]) > 0.005) {
    stop("[IN-GROW] the surplus components no longer sum to its total.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' The eight releases: one per region, each naming its figure, each dated after
#' the NOA, and the page's figure equal to the release's.
ig_assert_releases <- function(rel = ig_parse_releases(), d = ig_parse_page()) {
  if (anyNA(rel$release_millions) ||
      !isTRUE(all.equal(rel$release_millions, unname(IG_REGION_MILLIONS)))) {
    stop("[IN-GROW] the releases' region figures are ",
         paste(rel$release_millions, collapse = "/"), ".", call. = FALSE)
  }
  if (abs(sum(rel$release_millions) * 1e6 - IG_REGION_TOTAL) > 1) {
    stop("[IN-GROW] the region figures no longer sum to $112.4M.", call. = FALSE)
  }
  page <- tapply(d$round_amount, d$region, unique) / 1e6
  if (!isTRUE(all.equal(as.numeric(page), rel$release_millions))) {
    stop("[IN-GROW] the page and the releases disagree on a region figure.",
         call. = FALSE)
  }
  noa <- readr::read_csv(here::here("data", "reference", "cms_state_noa_dates.csv"),
                         show_col_types = FALSE, progress = FALSE)
  noa <- as.Date(noa$noa_date[noa$state == IG_STATE])
  dates <- as.Date(rel$date_as_published, format = "Sept. %d, %Y")
  if (anyNA(dates) || !all(dates == IG_ANNOUNCED) || !all(dates > noa)) {
    stop("[IN-GROW] date test: releases dated ",
         paste(rel$date_as_published, collapse = ", "), " against NOA ", noa, ".",
         call. = FALSE)
  }
  for (r in seq_len(8)) {
    rhtp_watch_require(rel$text[r], IG_RELEASE_SENTENCES, IG_STATE,
                       paste0("Region ", r, " release"))
    # §0.2: the footer is the ALLOTMENT. Declared Tier 1 and checked; it is
    # context, never provenance and never a figure on a row.
    rhtp_assert_footer_text_tier(rel$text[r], IG_STATE, "STATE_ALLOTMENT",
                                 label = paste0("IDOH Region ", r, " release footer"))
    if (!grepl("$206,927,896.80", rel$text[r], fixed = TRUE)) {
      stop("[IN-GROW] Region ", r, "'s footer no longer prints $206,927,896.80.",
           call. = FALSE)
    }
    if (grepl("Grant Recipient|subrecipients have been selected", rel$text[r])) {
      stop("[IN-GROW] Region ", r, "'s release now names recipients; read it.",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' The observations, pinned so a corrected source is noticed rather than
#' silently absorbed.
ig_assert_observations <- function(rel = ig_parse_releases()) {
  if (!identical(rel$label[c(3, 5)], c("West-Central", "West-Central"))) {
    stop("[IN-GROW] Regions 3 and 5 are no longer both titled 'West-Central'.",
         call. = FALSE)
  }
  if (!identical(rel$governor_as_published[3], "Gov. Mike Braum") ||
      !all(rel$governor_as_published[-3] == "Gov. Mike Braun")) {
    stop("[IN-GROW] the Governor's spelling in the releases has changed.",
         call. = FALSE)
  }
  invisible(TRUE)
}

# -- typing ------------------------------------------------------------------

ig_norm <- function(x) {
  x <- toupper(x)
  x <- gsub("[^A-Z0-9 ]", "", gsub("[.,'’/&-]", "", x))
  x <- stringr::str_squish(x)
  x <- sub("^THE ", "", x)
  sub(" INC$", "", x)
}

ig_federal <- function() {
  rd <- function(f) jsonlite::fromJSON(here::here(IG_FEDERAL, f))
  h <- rd("cms_hosp_enrollments_IN.json")
  q <- rd("cms_fqhc_enrollments_IN.json")
  r <- rd("cms_rhc_enrollments_IN.json")
  tb <- function(kind, x) tibble::tibble(kind = kind, ccn = x$CCN,
                                         org = x$`ORGANIZATION NAME`,
                                         dba = x$`DOING BUSINESS AS NAME`,
                                         city = x$CITY)
  dplyr::bind_rows(tb("HOSPITAL", h), tb("FQHC", q), tb("RHC", r))
}

ig_federal_match <- function(awardee, f = ig_federal()) {
  a <- ig_norm(awardee)
  halves <- unique(c(a, stringr::str_split(a, " DBA ")[[1]]))
  f[ig_norm(f$org) %in% halves | ig_norm(f$dba) %in% halves, ]
}

# Community mental health centre corporations that hold a psychiatric hospital
# CCN in their own name. Typed on the record; queued so a reader can subtract.
IG_CMHC_WITH_HOSPITAL_CCN <- c("Northeastern Center", "Hamilton Center, Inc.",
                               "INcompass Healthcare")

# The hand-read decisions. Everything else keeps the federal record, the
# classifier where the form is in the string, or §8's standing fallback.
IG_OVERRIDES <- tibble::tribble(
  ~awardee, ~recipient_type, ~basis_type, ~confidence, ~ccn, ~why,
  "Goshen Health System", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", "150026",
  "HAND-READ BRIDGE: CMS IN Hospital Enrollment carries no record under this string; Goshen Health's hospital is GOSHEN HOSPITAL ASSOCIATION INC dba GOSHEN GENERAL HOSPITAL (CCN 150026), and the page links goshenhealth.com. LOW and subtractable; queued as IN_GROW_HOSPITAL_BRIDGES.",
  "Northwest Health Starke Hospital", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", "150102",
  "HAND-READ BRIDGE: CMS enrols KNOX HOSPITAL COMPANY LLC dba NORTHWEST HEALTH-STARKE (CCN 150102, Knox); the state's string adds 'Hospital' and drops the hyphen, and the page links nwhealthstarke.com. LOW; queued as IN_GROW_HOSPITAL_BRIDGES.",
  "Union Health Inc.", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", NA_character_,
  "HAND-READ BRIDGE: no CMS record under 'Union Health'; CMS enrols UNION HOSPITAL INC (Terre Haute, CCN 150023, and Union Hospital Clinton, 151326, which is ALSO on this roster), and the page links union.health. A system parent, New Jersey's Virtua shape. LOW; queued as IN_GROW_HOSPITAL_BRIDGES.",
  "St. Elizabeth Dearborn", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", "150086",
  "HAND-READ BRIDGE: CMS enrols ST ELIZABETH MEDICAL CENTER, INC dba ST. ELIZABETH DEARBORN HOSPITAL (CCN 150086, Lawrenceburg); the state's string drops 'Hospital'. The page links stelizabeth.com/dearborn. LOW; queued as IN_GROW_HOSPITAL_BRIDGES.",
  "Ascension St. Vincent", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", "150100",
  "HAND-READ BRIDGE: 'Ascension St. Vincent' is a system brand, not an enrolled name. The page's OWN hyperlink for this Region 8 row is the Ascension St. Vincent Evansville location, which CMS enrols as ST MARYS HEALTH INC dba ASCENSION ST. VINCENT EVANSVILLE (CCN 150100). RCJ carries this row as \"St. Mary's\" -- CMS's legal name, not the state's. LOW; queued as IN_GROW_HOSPITAL_BRIDGES.",
  "Franciscan Health Foundation", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", NA_character_,
  "§10.2 HOSPITAL-FOUNDATION ROW (session 49): the foundation of a NAMED health system -- Franciscan Health, which CMS enrols as seven Indiana hospital corporations named FRANCISCAN HEALTH ... (Franciscan Health Crawfordsville, 150022, is in this same Region 3). The parent is a reading, so LOW; queued as IN_GROW_HOSPITAL_BRIDGES.",
  "Cummins Behavioral Health Systems, Inc.", "NONPROFIT_CBO", NA_character_, "LOW", NA_character_,
  "OVERRIDE of the classifier's HOSPITAL_OR_SYSTEM, which reads 'Health Systems' as a hospital system. CMS IN Hospital, FQHC and RHC Enrollment carry no record under this name; it is a community mental health centre on general knowledge (session 61). Left on §8's standing fallback, never promoted.",
  "Parkview Huntington Family Young Men's Christian Association", "NONPROFIT_CBO", NA_character_, "LOW", NA_character_,
  "NOT PARKVIEW HUNTINGTON HOSPITAL (§0.3a, read the recipient): the recipient is a YMCA, the page's own link is huntingtony.org, and the hospital -- HUNTINGTON MEMORIAL HOSPITAL, INC. dba PARKVIEW HUNTINGTON HOSPITAL, CCN 150091 -- is not on this roster. §8's standing fallback.",
  "Wayne County Auditor", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM", NA_character_,
  "A county government office; the form is in the state's own string.",
  "Monticello Fire Department", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM", NA_character_,
  "A municipal fire department; the form is in the state's own string, and the page links monticelloin.gov.",
  "Randolph Eastern School Building Corporation", "SCHOOL_OR_DISTRICT", "STATE_SOURCE", "MEDIUM", NA_character_,
  "A school corporation's building corporation; the page links resc.k12.in.us.",
  "Perry Central Community School", "SCHOOL_OR_DISTRICT", "STATE_SOURCE", "MEDIUM", NA_character_,
  "A public school corporation; the form is in the state's own string (pccs.k12.in.us).",
  "Ivy Tech Community Colleges-Henry County", "UNIVERSITY_OR_AHC", "STATE_SOURCE", "MEDIUM", NA_character_,
  "A campus of Indiana's public community college; the form is in the state's own string.",
  "Phoenix Paramedic Solutions LLC", "EMS_OR_PSAP", "STATE_SOURCE", "MEDIUM", NA_character_,
  "A paramedic service; the form is in the state's own string. The classifier's EMS rule does not reach 'Paramedic'."
)

ig_year1_awardees <- function(d = ig_parse_page()) {
  f <- ig_federal()
  cls <- rhtp_classify_recipient_type(d$awardee, IG_STATE)
  direct_basis <- rhtp_classify_flow("HOSPITAL_OR_SYSTEM", NA_character_)$flow_basis
  out <- vector("list", nrow(d))
  for (i in seq_len(nrow(d))) {
    a <- d$awardee[i]
    ccn_i <- NA_character_
    hit <- ig_federal_match(a, f)
    kinds <- sort(unique(hit$kind))
    ov <- IG_OVERRIDES[IG_OVERRIDES$awardee == a, ]
    if (nrow(ov)) {
      rt <- ov$recipient_type; bt <- ov$basis_type; cf <- ov$confidence
      why <- ov$why; how <- "HAND-READ"; ccn_i <- ov$ccn
    } else if (nrow(hit) && ("HOSPITAL" %in% kinds) &&
               (all(kinds %in% c("HOSPITAL", "RHC")) || a %in% IG_CMHC_WITH_HOSPITAL_CCN)) {
      # A hospital corporation enrols its provider-based RHCs under its own
      # name; that is still a hospital. The one HOSPITAL+FQHC case (Hamilton
      # Center) is a named CMHC decision, not a rule.
      rt <- "HOSPITAL_OR_SYSTEM"; bt <- "ORG_WEBSITE"; cf <- "MEDIUM"
      how <- "FEDERAL RECORD"
      six <- sort(unique(hit$ccn[hit$kind == "HOSPITAL" & grepl("^[0-9]{6}$", hit$ccn)]))
      if (length(six) == 1L) ccn_i <- six
      why <- paste0("EXACT federal record: CMS IN Hospital Enrollment carries this string as an ",
                    "ORGANIZATION NAME or DBA (normalised for case, punctuation, a leading THE and a ",
                    "trailing INC) at ",
                    ifelse(length(six) == 1L, paste0("CCN ", six),
                           paste0("CCNs ", paste(six, collapse = "/"))),
                    ifelse("RHC" %in% kinds, "; its provider-based RHCs enrol under the same name", ""),
                    ifelse("FQHC" %in% kinds, "; it ALSO holds FQHC CCNs under the same name", ""),
                    ".",
                    ifelse(a %in% IG_CMHC_WITH_HOSPITAL_CCN,
                           " A COMMUNITY MENTAL HEALTH CENTRE CORPORATION HOLDING A PSYCHIATRIC HOSPITAL CCN: typed on the record, queued as IN_GROW_CMHC_HOLDS_HOSPITAL_CCN so a reader can subtract it.",
                           ""))
    } else if (nrow(hit) && all(kinds %in% c("FQHC", "RHC"))) {
      rt <- "FQHC_OR_RHC"; bt <- "ORG_WEBSITE"; cf <- "MEDIUM"; how <- "FEDERAL RECORD"
      why <- paste0("EXACT federal record: CMS IN ", paste(kinds, collapse = "/"),
                    " Enrollment carries this string as an ORGANIZATION NAME or DBA.")
    } else if (nrow(hit)) {
      stop("[IN-GROW] '", a, "' matches federal kinds ", paste(kinds, collapse = "+"),
           " and no named decision covers it. Read it.", call. = FALSE)
    } else if (cls$recipient_type[i] %in% c("UNIVERSITY_OR_AHC", "EMS_OR_PSAP", "AHEC",
                                             "LOCAL_GOVT_OR_PUBLIC_HEALTH", "FQHC_OR_RHC")) {
      rt <- cls$recipient_type[i]; bt <- "STATE_SOURCE"
      cf <- cls$determination_confidence[i]; how <- "CLASSIFIER"
      why <- "The form is in the state's own string, and the shared classifier's name rule reads it."
    } else if (cls$recipient_type[i] == "HOSPITAL_OR_SYSTEM") {
      stop("[IN-GROW] the classifier calls '", a, "' a hospital and no federal record ",
           "or hand-read decision covers it. Read it.", call. = FALSE)
    } else {
      rt <- "NONPROFIT_CBO"; bt <- NA_character_; cf <- "LOW"; how <- "FALLBACK"
      why <- "The source states no form (§8's standing fallback, RECIPIENT_TYPE_INFERRED); queued as IN_GROW_RECIPIENT_FORM_NOT_STATED."
    }
    hosp <- rt == "HOSPITAL_OR_SYSTEM"
    if (hosp) {
      flow <- "DIRECT"; dth <- "Yes"; fbasis <- direct_basis
    } else {
      fl <- rhtp_classify_flow(rt, NA_character_)
      flow <- fl$flow_type; dth <- fl$distributed_to_hospital; fbasis <- fl$flow_basis
    }
    fallback <- rt == "NONPROFIT_CBO" && cf == "LOW" && is.na(bt)
    out[[i]] <- tibble::tibble(
      recipient_type = rt, distributed_to_hospital = dth, flow_type = flow,
      basis_type = bt, determination_confidence = cf, typing = how, why = why,
      ccn = ccn_i, classifier = paste0(cls$recipient_type[i], "/",
                                       cls$determination_confidence[i]),
      fallback = fallback, flow_basis = fbasis)
  }
  t <- dplyr::bind_rows(out)
  hosp <- t$recipient_type == "HOSPITAL_OR_SYSTEM"
  tibble::tibble(
    state = IG_STATE,
    row_no = seq_len(nrow(d)),
    awardee = d$awardee,
    amount = NA_real_,
    recipient_type = t$recipient_type,
    distributed_to_hospital = t$distributed_to_hospital,
    note = paste0("GROW Regional Grants, Region ", d$region, " (", d$region_figure_as_published,
                  "), selected subrecipient announced 2026-09-03. INDIANA PUBLISHES NO ",
                  "PER-ORGANISATION AMOUNT: the region figure is in round_amount and is never divided (§6.2)."),
    recipient_confirmed = "Yes",
    amount_confirmed = "No",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = "GROW Regional Grants -- Grant Recipient Organizations (IDOH, in.gov/grow-rural-health/regional-grants), with the eight IDOH Region press releases of 2026-09-03",
    state_source_url = IG_PAGE_URL,
    validation_source_type = "AGENCY_PRESS_RELEASE",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03bi_in_grow_regional_awardees.R",
    ccn = t$ccn,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    region = d$region,
    row_in_region = d$row_in_region,
    award_pool = paste0("GROW Regional Grants -- Region ", d$region),
    recipient_url = d$recipient_url,
    recipient_type_source = paste0("TYPED (session 63, ", t$typing, "): ", t$why,
                                   " Classifier said ", t$classifier, "."),
    determination_confidence = t$determination_confidence,
    flag_reason = ifelse(t$fallback, "RECIPIENT_TYPE_INFERRED", NA_character_),
    budget_period = "Budget Period 1",
    flow_type = t$flow_type,
    hospital_benefiting = ifelse(hosp, "Yes", "No"),
    hospital_attribution = ifelse(hosp, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = paste0(t$flow_basis, " ", t$why,
                                 ifelse(hosp, " §0.3a: the recipient is a hospital whatever the activity.",
                                        " Not a pass-through: IDOH's FAQ awards every listed organisation directly and prohibits it from sub-awarding.")),
    amount_basis = "Indiana publishes NO per-organisation amount. The region's figure, rounded in source to $0.1M, is in round_amount; it repeats on every row of its region and is never divided or summed down the column (§6.2).",
    basis_type = t$basis_type,
    round_amount = d$round_amount,
    announcement_date = IG_ANNOUNCED,
    source_archive_path = IG_PAGE)
}

ig_assert_typing <- function(a = ig_year1_awardees()) {
  if (any(!is.na(a$amount))) {
    stop("[IN-GROW] a row carries an amount; Indiana prices nobody.", call. = FALSE)
  }
  if (any(!a$recipient_type %in% rhtp_vocabulary("recipient_type"))) {
    stop("[IN-GROW] a recipient_type outside §8.", call. = FALSE)
  }
  if (any(grepl("PASS_THROUGH", a$flow_type))) {
    stop("[IN-GROW] a PASS_THROUGH row: IDOH's FAQ prohibits primary ",
         "subrecipients from sub-awarding.", call. = FALSE)
  }
  h <- a[a$distributed_to_hospital == "Yes", ]
  if (any(h$recipient_type != "HOSPITAL_OR_SYSTEM") ||
      any(h$determination_confidence == "HIGH")) {
    stop("[IN-GROW] a Yes row that is not a MEDIUM/LOW hospital.", call. = FALSE)
  }
  yk <- a$awardee[grepl("Young Men's Christian|YMCA", a$awardee)]
  if (any(a$distributed_to_hospital[a$awardee %in% yk] != "No")) {
    stop("[IN-GROW] a YMCA row is coded hospital-bound.", call. = FALSE)
  }
  if (a$distributed_to_hospital[a$awardee == "Cummins Behavioral Health Systems, Inc."] != "No") {
    stop("[IN-GROW] Cummins is a CMHC with no hospital record.", call. = FALSE)
  }
  invisible(TRUE)
}

#' GEORGIA'S TRAP: round_amount repeats per row. Sum DISTINCT (region, figure).
ig_reconcile <- function(a = ig_year1_awardees()) {
  regions <- dplyr::distinct(a, .data$region, .data$round_amount)
  if (nrow(regions) != 8L) {
    stop("[IN-GROW] ", nrow(regions), " distinct region figures, not 8.", call. = FALSE)
  }
  total <- sum(regions$round_amount)
  if (abs(total - IG_REGION_TOTAL) > 1) {
    stop("[IN-GROW] the region figures sum to $", format(total, big.mark = ","),
         ", not $112,400,000.", call. = FALSE)
  }
  naive <- sum(a$round_amount)
  if (naive <= total) {
    stop("[IN-GROW] summing round_amount down the column no longer overstates ",
         "the total; the repeat-per-row design changed.", call. = FALSE)
  }
  list(regions = regions, total = total, naive_column_sum = naive)
}

#' The column sum is a number Indiana never published, and this refuses it.
ig_assert_round_amount_not_summed <- function(figure, a = ig_year1_awardees()) {
  r <- ig_reconcile(a)
  if (isTRUE(all.equal(figure, r$naive_column_sum))) {
    stop("[IN-GROW] $", format(figure, big.mark = ","), " is round_amount summed ",
         "down the column. Each region's figure repeats on every row of that ",
         "region; the regions total $", format(r$total, big.mark = ","),
         ". Use ig_reconcile().", call. = FALSE)
  }
  invisible(TRUE)
}

ig_status_table <- function(d = ig_parse_page(), a = ig_year1_awardees(d),
                            rel = ig_parse_releases()) {
  per <- a %>% dplyr::group_by(region) %>%
    dplyr::summarise(recipient_rows = dplyr::n(),
                     distinct_names = dplyr::n_distinct(awardee),
                     named_hospital_rows = sum(distributed_to_hospital == "Yes"),
                     .groups = "drop")
  s <- ig_parse_surplus()
  reg <- tibble::tibble(
    state = IG_STATE,
    channel = paste0("GROW Regional Grants -- Region ", rel$region,
                     " (release title: '", rel$label, " Indiana Region')"),
    stage = "AWARDED_ROSTER_PUBLISHED",
    publishes_roster = "Yes -- names only, no per-organisation amount",
    region_figure_as_published = paste0("$", rel$release_millions, " million"),
    region_figure_dollars = rel$release_millions * 1e6) %>%
    dplyr::bind_cols(per[, -1]) %>%
    dplyr::mutate(note = paste0(
      "IDOH release of 2026-09-03 (", basename(IG_RELEASE(rel$region)),
      "). Figure rounded in source. Its CMS footer prints $206,927,896.80, the ALLOTMENT (Tier 1, §0.2).",
      ifelse(rel$region == 3, " OBSERVATION: the release reads 'Gov. Mike Braum'; kept as published.", ""),
      ifelse(rel$region %in% c(3, 5), " OBSERVATION: Regions 3 and 5 are BOTH titled 'West-Central'.", "")))
  extra <- tibble::tribble(
    ~state, ~channel, ~stage, ~publishes_roster, ~region_figure_as_published, ~region_figure_dollars, ~note,
    IG_STATE, "Surplus Award Summary -- Regional Surplus", "AWARDED_NO_RECIPIENT_NAMED", "No",
    "$8,724,000", s[["regional"]],
    "Awarded after the initial regional round and attached to no recipient on the page. Never in round_amount.",
    IG_STATE, "Surplus Award Summary -- Statewide Surplus", "AWARDED_NO_RECIPIENT_NAMED", "No",
    "$7,525,593.22", s[["statewide"]],
    "Statewide projects; no recipient named. With the regional surplus it is the page's 'Total Surplus Funds Awarded: $16,249,593.22'.")
  dplyr::bind_rows(reg, extra)
}

ig_validate <- function() {
  ig_assert_archive()
  d <- ig_parse_page()
  ig_assert_roster(d)
  ig_assert_page_sentences()
  rel <- ig_parse_releases()
  ig_assert_releases(rel, d)
  ig_assert_observations(rel)
  a <- ig_year1_awardees(d)
  ig_assert_typing(a)
  ig_reconcile(a)
  ig_assert_queued(a)
  message("[IN-GROW] all assertions pass.")
  invisible(a)
}

ig_build <- function() {
  a <- ig_validate()
  readr::write_csv(a, IG_CSV, na = "")
  readr::write_csv(ig_status_table(a = a), IG_STATUS_CSV, na = "")
  p <- rhtp_hospital_dollar_partition(a)
  message(sprintf("[IN-GROW] wrote %d rows; partition: %s.", nrow(a),
                  paste0(p$bucket, " ", p$rows, " rows / $", p$dollars, collapse = "; ")))
}

ig_report <- function() {
  a <- ig_year1_awardees()
  print(a %>% dplyr::count(recipient_type, distributed_to_hospital, determination_confidence))
  print(rhtp_hospital_dollar_partition(a))
  r <- ig_reconcile(a)
  cat(sprintf("\nRegions total $%s (never divided); naive column sum $%s is refused.\n",
              format(r$total, big.mark = ","), format(r$naive_column_sum, big.mark = ",")))
}

# -- the review queue ---------------------------------------------------------

IG_QUEUE_IDS <- c("IN_GROW_HOSPITAL_BRIDGES", "IN_GROW_CMHC_HOLDS_HOSPITAL_CCN",
                  "IN_GROW_RECIPIENT_FORM_NOT_STATED")

#' The three open questions, derived from the build so their counts cannot
#' drift from the file. Appended to classification_review_queue.csv once, by
#' hand (the queue is shared; nothing here rewrites it).
ig_queue_rows <- function(a = ig_year1_awardees()) {
  low <- a[a$distributed_to_hospital == "Yes" & a$determination_confidence == "LOW", ]
  cm  <- a[a$awardee %in% IG_CMHC_WITH_HOSPITAL_CCN, ]
  fb  <- a[!is.na(a$flag_reason) & a$flag_reason == "RECIPIENT_TYPE_INFERRED", ]
  hosp <- sum(a$distributed_to_hospital == "Yes")
  tibble::tibble(
    question_id = IG_QUEUE_IDS,
    state = IG_STATE,
    row_key = c(
      paste0("in_grow_regional_awardees.csv :: ", nrow(low), " rows at LOW: ",
             paste(unique(low$awardee), collapse = "; ")),
      paste0("in_grow_regional_awardees.csv :: ", nrow(cm), " rows: ",
             paste(unique(cm$awardee), collapse = "; ")),
      paste0("in_grow_regional_awardees.csv :: ", nrow(fb),
             " rows with flag_reason = RECIPIENT_TYPE_INFERRED")),
    opened_session = 63,
    opened_date = as.Date("2026-09-24"),
    queue_status = "OPEN",
    question = c(
      "Are the six GROW recipients typed HOSPITAL_OR_SYSTEM on a hand-read bridge (no exact CMS IN enrolment record under the state's string) hospitals for spec 10.2's DIRECT row?",
      "Is a community mental health centre corporation that holds a psychiatric hospital CCN in its own name a HOSPITAL_OR_SYSTEM recipient?",
      "Which of the GROW recipients whose form the page never states are hospitals under spec 8?"),
    options = c(
      "HOSPITAL_OR_SYSTEM at LOW (current) | NONPROFIT_CBO fallback",
      "HOSPITAL_OR_SYSTEM at MEDIUM on the federal record (current) | OTHER (a CMHC, form stated) | NONPROFIT_CBO fallback",
      "NONPROFIT_CBO (current) | OTHER | FQHC_OR_RHC | HOSPITAL_OR_SYSTEM"),
    why_it_is_open = c(
      "Goshen Health System (Goshen Hospital Association dba Goshen General Hospital, 150026), Northwest Health Starke Hospital (Knox Hospital Company dba Northwest Health-Starke, 150102), Union Health Inc. (a system parent over Union Hospital Inc), St. Elizabeth Dearborn (dba St. Elizabeth Dearborn Hospital, 150086), Region 8's 'Ascension St. Vincent' (the page's own link is the Evansville hospital, St Marys Health Inc, 150100) and Franciscan Health Foundation (spec 10.2's foundation row, parent Franciscan Health). Each tie is a reading, not a record.",
      "CMS IN Hospital Enrollment carries Northeastern Center (154050), Hamilton Center, Inc. (154009; it also holds FQHC CCNs) and Community Mental Health Center Inc. dba INcompass Healthcare (154011) as psychiatric hospitals under the state's own string. Mississippi typed CMHCs OTHER, but none of those held a hospital CCN; South Carolina typed psychiatric hospitals as hospitals and queued Acadia's mixed estate. Typed on the record and queued so a reader can subtract.",
      "The GROW page prints names and hyperlinks only. Every organisation matching a CMS IN Hospital, FQHC or RHC record was typed from it; these match none and read as councils on aging, YMCAs, transit, food, community foundations, CMHCs and community nonprofits. Nothing was promoted (spec 0.4)."),
    dollar_effect = c(
      paste0("$0 -- Indiana prices nobody. Moves the named-hospital ROW count: ",
             nrow(low), " of ", hosp, " rows."),
      paste0("$0 -- Indiana prices nobody. Moves the named-hospital ROW count: ",
             nrow(cm), " of ", hosp, " rows."),
      "$0 either way, ONE-DIRECTIONAL: every row is already distributed_to_hospital = No."),
    evidence_path = paste0(IG_PAGE, "; ", IG_FEDERAL, "/"),
    source_url = IG_PAGE_URL,
    resolved_by = NA_character_, resolved_date = NA_character_, resolution = NA_character_)
}

ig_assert_queued <- function(a = ig_year1_awardees()) {
  q <- readr::read_csv(here::here("data", "reference", "classification_review_queue.csv"),
                       show_col_types = FALSE, progress = FALSE)
  miss <- setdiff(IG_QUEUE_IDS, q$question_id)
  if (length(miss)) {
    stop("[IN-GROW] not in the review queue: ", paste(miss, collapse = ", "),
         call. = FALSE)
  }
  exp <- ig_queue_rows(a)
  got <- q[match(IG_QUEUE_IDS, q$question_id), ]
  if (!identical(got$row_key, exp$row_key)) {
    stop("[IN-GROW] the queued row keys no longer match the build.", call. = FALSE)
  }
  invisible(TRUE)
}

# -- the watch ---------------------------------------------------------------

IG_PROBE_PAGES <- tibble::tribble(
  ~key, ~url, ~file, ~name_diff,
  "grow_regional", IG_PAGE_URL, IG_PAGE, TRUE)

#' THE TRIPWIRES, against the LIVE bytes. (1) A figure inside a recipient table,
#' or a recipient table that moved -- either means `ig_year1_awardees()` must
#' be REWRITTEN, not patched. (2) A NEW sentence on the page carrying a dollar
#' figure, which the archive does not carry (a per-organisation amount would
#' arrive as one).
ig_assert_watch <- function(raw_live, arch_text = ig_page_text(),
                            live_text = rhtp_watch_reduce(raw_live)) {
  d <- tryCatch(ig_parse_page(raw_live), error = function(e) e)
  if (inherits(d, "error")) {
    stop("[IN-GROW] the live page no longer parses as eight recipient tables: ",
         rhtp_watch_quote(conditionMessage(d)), " Read it.", call. = FALSE)
  }
  if (any(grepl("\\$|[0-9]{1,3},[0-9]{3}", d$awardee))) {
    stop("[IN-GROW] A PER-ORGANISATION FIGURE NOW APPEARS IN A RECIPIENT TABLE. ",
         "`amount` in in_grow_regional_awardees.csv is empty because Indiana ",
         "published none; REWRITE the file.", call. = FALSE)
  }
  base <- ig_parse_page()
  if (!identical(d$awardee, base$awardee) || !identical(d$region, base$region) ||
      !identical(d$round_amount, base$round_amount)) {
    stop("[IN-GROW] the recipient tables or region figures moved (",
         nrow(base), " -> ", nrow(d), " rows). Re-archive by hand and rebuild.",
         call. = FALSE)
  }
  rhtp_watch_forbid_new(live_text, arch_text, "\\$\\s?[0-9][0-9,]*(\\.[0-9]+)?",
                        IG_STATE, "GROW Regional Grants page",
                        "A new dollar figure on the page may be a per-organisation amount.")
  invisible(TRUE)
}

ig_probe <- function() {
  w <- rhtp_watch_pages(IG_PROBE_PAGES, IG_USER_AGENT)
  ig_assert_watch(w$raw$grow_regional, w$arch_all$grow_regional,
                  w$live_all$grow_regional)
  rhtp_assert_no_new_organisations_across(live = w$live, archived = w$arch,
                                          state = IG_STATE)
  message("[IN-GROW] ", paste0(w$changed$key, ": ",
                               ifelse(w$changed$changed, "CHANGED", "UNCHANGED"),
                               collapse = "; "), " -- no per-organisation amount.")
  invisible(w$changed)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) ig_validate()
  if ("--build" %in% args) ig_build()
  if ("--probe" %in% args) rhtp_probe_run("IN", ig_probe())
  if ("--report" %in% args) ig_report()
  if (!length(args)) message("Usage: --validate | --build | --probe | --report")
}
