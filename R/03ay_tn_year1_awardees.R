#!/usr/bin/env Rscript
# 03ay_tn_year1_awardees.R ---------------------------------------------------
#
# TENNESSEE -- 53 NAMED HART AWARDS, NO AMOUNTS, AND TWO OF THEM ARE HOSPITALS.
#
# The Tennessee Department of Health announced on 2026-09-03 "the initial
# recipients of funding through the Rural Health Transformation Program (RHTP),
# providing awards to 53 innovative projects", and linked a workbook,
# 2026-RHTP-HART-Grant-Awards-FINAL.xlsx, naming all 53 with their counties and
# projects. NEITHER DOCUMENT PRINTS A DOLLAR FIGURE FOR ANY RECIPIENT. Nevada's
# and Iowa's shape: 53 award actions, `amount` empty on every one, and two
# named-hospital rows worth $0. READ THE ROW COUNT.
#
# CODE THE RECIPIENT, NOT THE STATE'S LABEL (§0.3a). TDH describes the 53 as
# "County and municipal governments ... 58 percent (31) ... community-based
# nonprofit organizations ... the remaining 42 percent (22)". Both labels are
# TRUE of both hospital rows and neither is the answer §8 needs:
#
#   * "Macon Hospital, Inc" is one of TDH's 31 GOVERNMENTS -- it is the only
#     name left once the 30 cities, towns, counties, school systems, the library
#     and the development agency are counted -- and it is a HOSPITAL. CMS's
#     Hospital Enrollment file (archived, federal_records/2026-09-23) carries
#     MACON COUNTY GENERAL HOSPITAL INC, dba MACON COMMUNITY HOSPITAL, Lafayette
#     (the seat of Macon County), CCN 441305 -- a critical access hospital's
#     number. The state's string is NOT that record's name, so this is a
#     HAND-READ BRIDGE (one hospital corporation in the county the award names)
#     and it is priced LOW so a reader can subtract it.
#   * "Cookeville Regional Medical Center Foundation" is one of TDH's 22
#     NONPROFITS and is §10.2's HOSPITAL-FOUNDATION ROW (session 49): the
#     foundation of a NAMED hospital whose name it carries -- COOKEVILLE
#     REGIONAL MEDICAL CENTER, CCN 440059, the same archived file. HOSPITAL_OR_
#     SYSTEM, DIRECT; the parent tie is a reading, so LOW (West Virginia's
#     Cabell Huntington Foundation, session 54).
#
# Both hospital awards fund community wellness projects ("Macon Healthy Living
# and Child Development Project", "Community Wellness Loop"). That is the
# ACTIVITY; §0.3a judges the RECIPIENT, and the recipient is a hospital.
#
# THE OTHER 51 ARE TYPED FROM TDH'S OWN SPLIT, WHICH THIS FILE REPRODUCES
# EXACTLY: 29 governments (cities, towns, counties, four school systems, a
# library, an economic development agency) and 21 nonprofits, plus the two
# hospitals, give 31 and 22. The shared classifier misses ten of the
# governments (three school systems, four "Town of", a library, a county mayor,
# a development agency -- it calls them NONPROFIT_CBO/LOW); its answer is kept
# on every row in `recipient_type_source` and the classifier is NOT widened
# here (a shared-rule change needs its own byte-identical rebuild of every
# state, §2.1).
#
# §6.2: the release's own sentence ties the awards to RHTP ("initial recipients
# of funding through the Rural Health Transformation Program"), the date test
# passes (2026-09-03 against the 2025-12-29 NOA), and the CMS footer prints
# $206,888,882.11 -- Tennessee's ALLOTMENT (§0.2), declared STATE_ALLOTMENT.
#
# §0.1 NEGATIVE CONTROL ON THE SAME ESTATE: RAMP. TDH's Rural Healthcare Access
# Modernization Program is linked from the RHTP page, run by the same State
# Office of Rural Health, and will award HOSPITAL capital projects -- and it is
# "funded through TennCare Shared Savings", $104.4M the General Assembly
# approved in the FY27 budget "to complement the federal Rural Health
# Transformation Program". Its Goal 2 is "RHTP Competitive Grant Extension",
# so its awards will carry RHTP's name on STATE money. A RAMP roster is never a
# row here.
#
# Usage:
#   Rscript R/03ay_tn_year1_awardees.R --fetch     # archive the probe baselines
#   Rscript R/03ay_tn_year1_awardees.R --validate  # assertions, offline
#   Rscript R/03ay_tn_year1_awardees.R --build     # writes the three TN CSVs
#   Rscript R/03ay_tn_year1_awardees.R --probe     # LIVE, READ-ONLY
#   Rscript R/03ay_tn_year1_awardees.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))
source(here::here("R", "utils_page_watch.R"))

TN_STATE     <- "TN"
TN_ALLOTMENT <- 206888882            # cms_fy2026_allotments.csv (§7.1)
TN_NOA_DATE  <- as.Date("2025-12-29")
TN_ANNOUNCED <- as.Date("2026-09-03")
TN_RECHECK   <- file.path("data", "evidence", "recheck", "2026-09-23", "TN")
TN_RELEASE   <- file.path(TN_RECHECK, "tn_doh_2026-09-03_first_recipients.html")
TN_XLSX      <- file.path(TN_RECHECK, "tn_2026_RHTP_HART_Grant_Awards_FINAL.xlsx")
TN_FEDERAL   <- file.path("data", "evidence", "federal_records", "2026-09-23")
TN_DIR       <- file.path("data", "evidence", "TN")
TN_RELEASE_URL <- paste0("https://www.tn.gov/health/news/2026/9/3/tennessee-",
                         "department-of-health-announces-1st-recipients-of-",
                         "rural-health-transformation-program-grants.html")
TN_XLSX_URL  <- paste0("https://www.tn.gov/content/dam/tn/health/xlsx/",
                       "2026-RHTP-HART-Grant-Awards-FINAL.xlsx")
TN_CSV        <- here::here("data", "reference", "tn_year1_awardees.csv")
TN_STATUS_CSV <- here::here("data", "reference", "tn_year1_status.csv")
TN_DISPO_CSV  <- here::here("data", "reference", "tn_rcj_candidate_disposition.csv")
TN_USER_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                        "+https://www.aha.org)")

# -- the sources -----------------------------------------------------------

tn_release_text <- function() rhtp_watch_reduce(here::here(TN_RELEASE), "article")

tn_read_roster <- function() {
  f <- here::here(TN_XLSX)
  sheets <- readxl::excel_sheets(f)
  if (!identical(sheets, "Sept. 2, 2026")) {
    stop("[TN] the award workbook's sheets are ", paste(sheets, collapse = ", "),
         ", not the single 'Sept. 2, 2026' sheet this parse was written for.",
         call. = FALSE)
  }
  raw <- readxl::read_excel(f, col_names = FALSE, col_types = "text",
                            .name_repair = "minimal")
  hdr <- unname(unlist(raw[2, ]))
  if (!identical(hdr, c("RHTP Award Recipient", "County(ies) of Impact",
                        "Project Name"))) {
    stop("[TN] the workbook's header row is now ", paste(hdr, collapse = " | "),
         ". A new column -- above all an AMOUNT column -- means this file must ",
         "be REWRITTEN, not patched.", call. = FALSE)
  }
  body <- raw[-(1:2), ]
  names(body) <- c("awardee", "county", "project")
  body %>%
    dplyr::filter(!is.na(.data$awardee)) %>%
    dplyr::mutate(dplyr::across(dplyr::everything(), stringr::str_squish))
}

# What TDH's split says each row IS, read against the recipient.
#   GOVT_* are among TDH's 31 "county and municipal governments";
#   NPO_*  are among its 22 "community-based nonprofit organizations".
TN_HOSPITALS <- tibble::tribble(
  ~awardee, ~tdh_class, ~basis_type, ~why,
  "Macon Hospital, Inc", "GOVERNMENT", "GENERAL_KNOWLEDGE",
  "HAND-READ BRIDGE to a federal record: CMS Hospital Enrollment carries MACON COUNTY GENERAL HOSPITAL INC dba MACON COMMUNITY HOSPITAL, 305 W Locust St, Lafayette TN (Macon County, the county this award names), CCN 441305 -- a critical access hospital number -- and no other Macon hospital. The state's string is not that record's name, so the match is a reading and is LOW. TDH counts this recipient among its 31 county and municipal governments, which agrees with a county general hospital. The activity is a community healthy-living project; §0.3a judges the recipient.",
  "Cookeville Regional Medical Center Foundation", "NONPROFIT", "GENERAL_KNOWLEDGE",
  "§10.2 HOSPITAL-FOUNDATION ROW (session 49): the foundation of a NAMED hospital whose full name it carries -- CMS Hospital Enrollment: COOKEVILLE REGIONAL MEDICAL CENTER, 1 Medical Center Blvd, Cookeville (Putnam County, the county this award names), CCN 440059. The parent tie is a reading, not a stated fact, so LOW (Cabell Huntington Foundation, WV, session 54). The activity is a community wellness loop; §0.3a judges the recipient."
)

tn_government_type <- function(a) {
  dplyr::case_when(
    grepl("Schools$|Board of Education$", a) ~ "SCHOOL_OR_DISTRICT",
    TRUE ~ "LOCAL_GOVT_OR_PUBLIC_HEALTH")
}

# The 29 non-hospital governments, by name. Everything else that is not a
# hospital is one of TDH's 22 nonprofits. The split is ASSERTED against TDH's
# own 31/22 in tn_assert_split().
tn_is_government <- function(a) {
  grepl(paste0("^(City of|Town of)|County Government$|County Mayor$|",
               "City Schools$|County Schools$|Board of Education$|",
               "Public Library$|Economic Development Agency$"), a)
}

# -- assertions ------------------------------------------------------------

tn_assert_release <- function(t = tn_release_text()) {
  must <- c(
    "announced the initial recipients of funding through the Rural Health Transformation Program (RHTP), providing awards to 53 innovative projects",
    "The 53 awarded projects are devoted to initiatives in the Healthy Active Rural Tennessee (HART) RHTP priority and expand services across 44 Tennessee counties",
    "County and municipal governments account for 58 percent (31) of award recipients, while community-based nonprofit organizations comprise the remaining 42 percent (22)",
    "Thursday, September 03, 2026")
  rhtp_watch_require(t, must, TN_STATE, "the 2026-09-03 release")
  # §0.2: the footer is the ALLOTMENT, on a Tier 3 announcement.
  rhtp_assert_footer_text_tier(t, TN_STATE, "STATE_ALLOTMENT",
                               label = "TN 2026-09-03 release footer")
  # The only currency on the release is the footer, CMS's "$206 million" and
  # the national "$50 billion". A per-recipient figure is what would make this
  # file wrong.
  money <- stringr::str_extract_all(t, "\\$[0-9][0-9,.]*( (million|billion))?")[[1]]
  if (!setequal(money, c("$206 million", "$50 billion", "$206,888,882.11"))) {
    stop("[TN] the release now carries currency this file does not account ",
         "for: ", paste(money, collapse = ", "), ". Read it.", call. = FALSE)
  }
  if (!(TN_ANNOUNCED > TN_NOA_DATE)) stop("[TN] date test.", call. = FALSE)
  invisible(TRUE)
}

tn_assert_roster <- function(r = tn_read_roster()) {
  if (nrow(r) != 53L) {
    stop("[TN] the workbook names ", nrow(r), " recipients, not the 53 TDH ",
         "announced.", call. = FALSE)
  }
  if (anyDuplicated(r$awardee)) {
    stop("[TN] a recipient appears twice; this file assumes one award per ",
         "recipient.", call. = FALSE)
  }
  counties <- unique(trimws(unlist(strsplit(r$county, ","))))
  if (length(counties) != 44L) {
    stop("[TN] the workbook's counties number ", length(counties),
         ", not the release's 44.", call. = FALSE)
  }
  if (any(grepl("\\$|^[0-9,.]+$", c(r$county, r$project)))) {
    stop("[TN] a dollar figure has appeared in the roster. Rewrite this file.",
         call. = FALSE)
  }
  if (!all(TN_HOSPITALS$awardee %in% r$awardee)) {
    stop("[TN] a hospital row is no longer on the roster.", call. = FALSE)
  }
  invisible(TRUE)
}

tn_assert_split <- function(r = tn_read_roster()) {
  hosp <- r$awardee %in% TN_HOSPITALS$awardee
  gov <- tn_is_government(r$awardee) & !hosp
  govt_hosp <- sum(TN_HOSPITALS$tdh_class == "GOVERNMENT")
  npo_hosp  <- sum(TN_HOSPITALS$tdh_class == "NONPROFIT")
  n_gov <- sum(gov) + govt_hosp
  n_npo <- sum(!gov & !hosp) + npo_hosp
  if (n_gov != 31L || n_npo != 22L) {
    stop("[TN] this file's government/nonprofit split is ", n_gov, "/", n_npo,
         "; TDH's own is 31/22. A typing that does not reproduce the state's ",
         "own count is a typing to re-read.", call. = FALSE)
  }
  invisible(TRUE)
}

tn_assert_federal_records <- function() {
  h <- jsonlite::fromJSON(here::here(TN_FEDERAL, "cms_hosp_enrollments_TN.json"))
  macon <- h[grepl("MACON", h$`ORGANIZATION NAME`) & h$CITY == "LAFAYETTE", ]
  if (!"441305" %in% macon$CCN) {
    stop("[TN] CMS no longer carries Macon County General Hospital at CCN ",
         "441305; the Macon bridge rests on it.", call. = FALSE)
  }
  if (any(grepl("MACON HOSPITAL", h$`ORGANIZATION NAME`))) {
    stop("[TN] CMS now carries 'Macon Hospital' by name -- the bridge can ",
         "become an EXACT record. Re-type the row.", call. = FALSE)
  }
  if (!"440059" %in% h$CCN[h$`ORGANIZATION NAME` == "COOKEVILLE REGIONAL MEDICAL CENTER"]) {
    stop("[TN] CMS no longer carries Cookeville Regional Medical Center at ",
         "CCN 440059.", call. = FALSE)
  }
  q <- jsonlite::fromJSON(here::here(TN_FEDERAL, "cms_fqhc_enrollments_TN.json"))
  if (any(grepl("OAK RIDGE", c(q$`ORGANIZATION NAME`, q$`DOING BUSINESS AS NAME`)) &
          grepl("FREE", c(q$`ORGANIZATION NAME`, q$`DOING BUSINESS AS NAME`)))) {
    stop("[TN] The Free Medical Clinic of Oak Ridge is now an enrolled FQHC.",
         call. = FALSE)
  }
  invisible(TRUE)
}

# -- the award file --------------------------------------------------------

tn_year1_awardees <- function(r = tn_read_roster()) {
  cls <- rhtp_classify_recipient_type(r$awardee, TN_STATE)
  hosp <- r$awardee %in% TN_HOSPITALS$awardee
  gov <- tn_is_government(r$awardee) & !hosp
  h <- TN_HOSPITALS[match(r$awardee, TN_HOSPITALS$awardee), ]
  rtype <- dplyr::case_when(hosp ~ "HOSPITAL_OR_SYSTEM",
                            gov ~ tn_government_type(r$awardee),
                            TRUE ~ "NONPROFIT_CBO")
  tdh_class <- ifelse(hosp, h$tdh_class, ifelse(gov, "GOVERNMENT", "NONPROFIT"))
  why <- dplyr::case_when(
    hosp ~ h$why,
    gov ~ paste0("One of TDH's 31 'county and municipal governments' (the ",
                 "release); typed ", rtype, " from its own name."),
    TRUE ~ paste0("One of TDH's 22 'community-based nonprofit organizations' ",
                  "(the release): this file's partition reproduces TDH's 31/22 ",
                  "exactly, so the form is the state's, not a guess."))
  tibble::tibble(
    state = TN_STATE,
    row_no = seq_len(nrow(r)),
    awardee = r$awardee,
    amount = NA_real_,
    recipient_type = rtype,
    distributed_to_hospital = ifelse(hosp, "Yes", "No"),
    note = paste0("HART award, 'initial recipients' announced 2026-09-03 by TDH. ",
                  "Project: ", r$project, ". County(ies): ", r$county,
                  ". NO AMOUNT PUBLISHED."),
    recipient_confirmed = "Yes",
    amount_confirmed = "No",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = "2026 Healthy Active Rural Tennessee (HART) Grant Awards (TDH, sheet 'Sept. 2, 2026')",
    state_source_url = TN_XLSX_URL,
    validation_source_type = "AGENCY_PRESS_RELEASE",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03ay_tn_year1_awardees.R",
    ccn = NA_character_,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    county = r$county,
    project = r$project,
    tdh_class = tdh_class,
    recipient_type_source = paste0(
      ifelse(hosp, "TYPED (session 59): ", "TYPED FROM TDH'S SPLIT (session 59): "),
      why, " Classifier said ", cls$recipient_type, "/",
      cls$determination_confidence, "."),
    determination_confidence = ifelse(hosp, "LOW", "MEDIUM"),
    flag_reason = "AMOUNT_MISSING",
    award_pool = "Healthy Active Rural Tennessee (HART)",
    budget_period = "Budget Period 1",
    flow_type = ifelse(hosp, "DIRECT", "NON_HOSPITAL"),
    hospital_benefiting = ifelse(hosp, "Yes", "No"),
    hospital_attribution = ifelse(hosp, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = ifelse(
      hosp, paste0("§10.2 DIRECT: ", why),
      paste0("§10.2 NON_HOSPITAL: ", why)),
    amount_basis = paste0("NOT PUBLISHED. TDH's release and workbook name 53 ",
                          "recipients and price none; the release's only ",
                          "award figure is the $206,888,882.11 ALLOTMENT in ",
                          "its CMS footer (§0.2), never divided."),
    basis_type = ifelse(hosp, h$basis_type, "STATE_SOURCE"),
    round_amount = NA_real_,
    announcement_date = TN_ANNOUNCED,
    source_archive_path = TN_XLSX)
}

tn_status_table <- function() {
  tibble::tribble(
    ~state, ~channel, ~stage, ~publishes_roster, ~note,
    TN_STATE, "TDH newsroom: 2026-09-03 release + HART award workbook",
    "AWARDED_ROSTER_PUBLISHED_NO_AMOUNTS", "Yes",
    "53 named recipients, 44 counties, NO per-recipient amount. TDH calls them the 'initial recipients', so this is a PARTIAL year. Two are hospitals (Macon Hospital, Inc; Cookeville Regional Medical Center Foundation).",
    TN_STATE, "tn.gov/health/rural (the RHTP programme page)",
    "DOES_NOT_LINK_THE_AWARDS", "No",
    "On 2026-09-23 the programme page still links only the 2026-05-15 opportunity release; the award workbook is reachable ONLY from the newsroom item. A watch on this page alone would have missed the roster.",
    TN_STATE, "RHTP Partner Portal (Caspio)", "UNREADABLE", "UNKNOWN",
    "A JavaScript application this environment cannot render (session 39). What it lists is a statement about our access, never about Tennessee (§0.4).",
    TN_STATE, "RAMP -- Rural Healthcare Access Modernization Program",
    "AWARDED_BUT_NOT_RHTP_PENDING", "Not yet",
    "§0.1 NEGATIVE CONTROL: $104.4M of TennCare Shared Savings (STATE money, FY27 budget), linked from the RHTP page, run by the same office, Goal 1 $100M rural capital (hospital-shaped) and Goal 2 'RHTP Competitive Grant Extension'. Its awards will carry RHTP's name on state money and are never rows in tn_year1_awardees.csv."
  )
}

tn_rcj_disposition <- function() {
  rt <- rhtp_record_table_live()
  t <- rt[rt$state == TN_STATE, ]
  hart <- grepl("HART|Healthy Active", paste(t$source_doc_title,
                                             t$program_description),
                ignore.case = TRUE)
  tibble::tribble(
    ~state, ~group, ~records, ~disposition, ~note,
    TN_STATE, "All RCJ Tennessee records (pull 2026-08-27)", nrow(t),
    "NO_TIER_3", paste0("Zero SUBAWARD records. The only committed national pull (last_seen ",
                        max(t$last_seen, na.rm = TRUE), ") predates TDH's 2026-09-03 roster by seven days."),
    TN_STATE, "HART records", sum(hart),
    "SOLICITATION_STAGE", paste0(sum(hart & t$award_tier == "SOLICITATION"),
      " SOLICITATION + ", sum(hart & t$award_tier == "UNASSIGNED"),
      " UNASSIGNED: RCJ held RFA #34320-18526 (HART) as an opportunity -- one copy titled 'TN - 2024 - ...', the aggregator's year prefix, never a date (§2).")
  )
}

tn_validate <- function() {
  tn_assert_release()
  r <- tn_read_roster()
  tn_assert_roster(r)
  tn_assert_split(r)
  tn_assert_federal_records()
  d <- tn_year1_awardees(r)
  stopifnot(nrow(d) == 53L, sum(d$distributed_to_hospital == "Yes") == 2L,
            all(is.na(d$amount)))
  message("[TN] all assertions pass.")
  invisible(d)
}

tn_build <- function() {
  d <- tn_validate()
  readr::write_csv(d, TN_CSV, na = "")
  readr::write_csv(tn_status_table(), TN_STATUS_CSV, na = "")
  readr::write_csv(tn_rcj_disposition(), TN_DISPO_CSV, na = "")
  message("[TN] wrote 53 award rows, 2 named-hospital rows, $0.")
}

tn_report <- function() {
  d <- tn_year1_awardees()
  print(table(d$recipient_type))
  cat(sprintf("\n53 award actions; %d named-hospital rows; $0 (TDH prices nobody).\n",
              sum(d$distributed_to_hospital == "Yes")))
}

# -- the watch (session 59) ------------------------------------------------

TN_PROBE_PAGES <- tibble::tribble(
  ~key, ~url, ~file, ~name_diff,
  "rhtp", "https://www.tn.gov/health/rural.html",
  "data/evidence/TN/2026-09-23_tn_rhtp_programme.html", TRUE,
  "news", "https://www.tn.gov/health/news.html",
  "data/evidence/TN/2026-09-23_tn_health_news_index.html", FALSE,
  "ramp", "https://www.tn.gov/health/ramp",
  "data/evidence/TN/2026-09-23_tn_ramp_STATE_PROGRAM.html", FALSE)

# The three RHTP headlines the 2026-09-23 news index carries. A FOURTH that
# says recipients/awards/grants is the next tranche.
TN_KNOWN_RHTP_HEADLINES <- c(
  "Tennessee Department of Health Announces 1st Recipients of Rural Health Transformation Program Grants",
  "Tennessee to Release 1st Grant Funding Opportunity of Rural Health Transformation Program",
  "Statewide Session March 31 to Highlight Tennessee Rural Health Transformation Program Funding Opportunities")

tn_fetch <- function() {
  for (i in seq_len(nrow(TN_PROBE_PAGES))) {
    rhtp_watch_archive(TN_PROBE_PAGES$url[i], TN_PROBE_PAGES$file[i],
                       TN_USER_AGENT)
  }
  message("[TN] archived ", nrow(TN_PROBE_PAGES), " baselines under ", TN_DIR)
}

tn_news_headlines <- function(raw) {
  h <- xml2::read_html(raw)
  a <- rvest::html_elements(h, "a[href*='/health/news/20']")
  x <- stringr::str_squish(rvest::html_text2(a))
  unique(x[nzchar(x) & x != "Read full story"])
}

#' THE TRIPWIRES. (1) A NEW RHTP headline on the news index saying recipients
#' / awards / grants is the next tranche. (2) The programme page gaining a link
#' to an award workbook. (3) RAMP losing its funding sentence -- the control is
#' gone and a RAMP roster could then pass for RHTP.
tn_assert_watch <- function(raw_news, raw_rhtp, ramp_text) {
  hl <- tn_news_headlines(raw_news)
  if (length(hl) < 10L) {
    stop("[TN] the news index yields ", length(hl), " headlines; our reader, ",
         "not Tennessee, has changed (§0.4).", call. = FALSE)
  }
  if (!all(TN_KNOWN_RHTP_HEADLINES[1:2] %in% hl) && length(hl) < 20L) {
    stop("[TN] a recorded RHTP release left a short news index -- re-read it.",
         call. = FALSE)
  }
  rhtp <- hl[grepl("Rural Health Transformation|\\bRHTP\\b", hl)]
  new <- setdiff(rhtp, TN_KNOWN_RHTP_HEADLINES)
  hot <- new[grepl("recipient|award|grants", new, ignore.case = TRUE)]
  if (length(hot)) {
    stop("[TN] NEW RHTP AWARD RELEASE ON THE TDH NEWS INDEX: ",
         paste0("'", rhtp_watch_quote(hot), "'", collapse = "; "),
         ". TDH called the 53 its 'initial recipients'. Archive the release ",
         "and its roster, and extend tn_year1_awardees.csv. If it is a RAMP ",
         "release, it is STATE money and is NOT a row here.", call. = FALSE)
  }
  h <- xml2::read_html(raw_rhtp)
  hrefs <- rvest::html_attr(rvest::html_elements(h, "a"), "href")
  award_links <- hrefs[!is.na(hrefs) & grepl("Grant-Awards|Award", hrefs, ignore.case = TRUE)]
  if (length(award_links)) {
    stop("[TN] the RHTP programme page now links an award document: ",
         paste(rhtp_watch_quote(award_links), collapse = ", "),
         ". Read it.", call. = FALSE)
  }
  rhtp_watch_require(ramp_text, "funded through TennCare Shared Savings",
                     TN_STATE, "ramp (the §0.1 control)")
  invisible(new)
}

tn_probe <- function() {
  w <- rhtp_watch_pages(TN_PROBE_PAGES, TN_USER_AGENT)
  tn_assert_watch(w$raw$news, w$raw$rhtp, w$live_all$ramp)
  rhtp_assert_no_new_organisations_across(live = w$live, archived = w$arch,
                                          state = TN_STATE)
  message("[TN] ", paste0(w$changed$key, ": ",
                          ifelse(w$changed$changed, "CHANGED", "UNCHANGED"),
                          collapse = "; "), " -- no new RHTP award release.")
  invisible(w$changed)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) tn_fetch()
  if ("--validate" %in% args) tn_validate()
  if ("--build" %in% args) tn_build()
  if ("--probe" %in% args) rhtp_probe_run("TN", tn_probe())
  if ("--report" %in% args) tn_report()
  if (!length(args)) message("Usage: --fetch | --validate | --build | --probe | --report")
}
