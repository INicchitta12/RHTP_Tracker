#!/usr/bin/env Rscript
# 03ba_nd_year1_probe.R ------------------------------------------------------
#
# NORTH DAKOTA -- A WATCH, NOT AN EXTRACTION (session 59). ND HHS runs 25 RHTP
# funding opportunities from one page, each headed with its own status:
#
#   "Zero-Hour Physical Education (PE) Initiative – Closed (23 Applicants)"
#   ...
#   "Expand Rural Health Care Rotations – Awarded | 24 Applicants"
#
# On 2026-09-23, 24 read "Closed" and ONE reads "Awarded" -- naming nobody
# (session 55). 769 applicants between them. Several classes are hospitals
# outright ("Hospital-Based Wellness Equipment", "Workforce Retention Funding
# for Critical Access Hospitals ...", "Rightsizing ... Critical Access
# Hospitals"), so an awardee list here is likely to carry hospital money.
#
# WEEKLY, because North Dakota publishes no award date (the Zero-Hour PE
# estimate of ~early August has passed and nothing replaced it) -- North
# Carolina's and New Mexico's footing.
#
# THE TRIPWIRE IS THE HEADING, which is the cheapest one this project has had:
# a second "– Awarded" is the state telling us, in its own markup, that it has
# awarded. The one already Awarded is recorded here by name, so it cannot trip.
# A heading that disappears, a new opportunity, or a count change is CHANGED
# (the digest), not a tripwire. Fewer than 20 headings means our READER broke,
# never that North Dakota withdrew anything (§0.4).
#
# Both pages are name-diffed (§2.3): an awardee named in a FAQ answer or in a
# new "Awardees" paragraph fires even if the heading does not move.
#
# Usage: Rscript R/03ba_nd_year1_probe.R --fetch | --validate | --probe

suppressPackageStartupMessages({ library(dplyr); library(stringr) })
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))

ND_STATE <- "ND"
ND_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                   "+https://www.aha.org)")
ND_DIR <- file.path("data", "evidence", "recheck", "2026-09-23", "ND")
# SESSION 99: the FUNDING page is re-based to a NEW dated file, after reading
# the diff against the 09-23 archive: seven headings flipped "Closed (N
# Applicants)" -> "Awarded | N Applicants" (Zero-Hour PE, Community Gardens,
# BH Promotion, Train In Place, Workforce Retention, Rightsizing, Mobile
# Mammography) and nothing else moved; no section names an awardee. The 09-23
# copy is NOT overwritten: R/03bh's Rightsizing disposition cites it.
ND_BASE_DIR <- file.path("data", "evidence", "ND", "probe_baseline")
ND_PAGES <- tibble::tribble(
  ~key, ~url, ~file, ~name_diff,
  "programme", "https://www.hhs.nd.gov/rural-health-transformation",
  # SESSION 121: re-based after reading the diff against the 09-23 archive.
  # The ONLY change is the CMS footer: $198,936,969.55 -> $405,316,596.31
  # (FY2026 + FY2027) and "North Dakota Department of Health and Human
  # Services (ND HHS)" -> "North Dakota Health and Human Services" -- the
  # agency's own name, which the name tripwire read as a new organisation on
  # 2026-11-20. Not a recipient. The 09-23 copy stays (R/03bh cites ND_DIR).
  file.path(ND_BASE_DIR, "2026-11-20_hhs_rhtp_programme.html"), TRUE,
  "funding", "https://www.hhs.nd.gov/rural-health-transformation/funding",
  # SESSION 121: re-based to a NEW dated file after reading the diff against
  # the 10-12 baseline. Three headings went "Closed (N Applicants)" ->
  # "Awarded | N Applicants" (Suicide Intervention 7 -> 5, Childcare 9 -> 8,
  # NEMT 13), a "Sample Service Commitment Agreement" link was removed, and
  # the CMS footer now prints $405,316,596.31 -- FY2026 ($198,936,970) plus
  # FY2027 ($206,379,627), to the dollar: ALLOTMENT_PLUS_FY2027, a Year 2
  # signal only. No section names an awardee or prints an amount. The 10-12
  # copy stays archived.
  file.path(ND_BASE_DIR, "2026-11-20_hhs_rhtp_funding.html"), TRUE)

# SESSION 85: five more headings read "Awarded" on 2026-10-02 (four tripped the
# Routine on 09-30; Behavioral Health Promotion followed). READ: none of the
# funding page, the programme page or the HHS newsroom names an awardee for
# any of them. Rightsizing (FQHCs and CAHs) is a $40,000 technical-assistance
# award delivered through ND HHS's preferred vendor, Eide Bailly. Recorded so
# the heading tripwire is quiet; the name diff on both pages is what catches
# the roster when North Dakota publishes one.
ND_KNOWN_AWARDED <- c(
  "Expand Rural Health Care Rotations",
  "Zero-Hour Physical Education (PE) Initiative",
  "Community Gardens Project",
  "Behavioral Health Promotion Community Grants",
  "Rightsizing Health Care Delivery Systems for the Future: Rural Federally Qualified Health Centers and Critical Access Hospitals",
  "Mobile Mammography Unit Acquisition Funding Opportunity",
  # SESSION 94, READ 2026-10-07: the 10-07 09:22Z Routine TRIPWIRE. The
  # heading reads "... – Awarded | 36 Applicants"; the section names NO
  # awardee and prints no amount. Recorded here so the heading tripwire is
  # quiet; the name diff on both pages still catches the roster.
  "Workforce Retention Funding for Critical Access Hospitals and Their Owned and Operated Clinics",
  # SESSION 99, read 2026-10-12: heading "Train In Place – Awarded | 45
  # Applicants"; the section names no awardee and prints no amount (RFP and
  # FAQ text only). Its eligible class is health-care employers and education
  # institutions, NOT hospitals only, so it is not in ND_HOSPITAL_ONLY_ROUNDS.
  "Train In Place",
  # SESSION 120, read 2026-11-19 (Routine TRIPWIRE 11-18 09:21Z): three headings
  # went "Closed" -> "Awarded | N Applicants" (5, 8 and 13). No section names an
  # awardee or prints an amount (RFP, TA and FAQ text only). NEMT's eligible
  # class is "hospitals, clinics, federally qualified health centers, ... tribally
  # run 638 health facilities", not hospitals only; Childcare's centre "would have
  # to be located on the hospital campus" but the class is not stated to be
  # hospitals only, so neither is in ND_HOSPITAL_ONLY_ROUNDS. The name diff on
  # both pages still catches a roster.
  "Suicide Intervention \u2013 Healthcare Systems Initiative",
  "Childcare for the Rural Health Workforce",
  "Non-Emergency Medical Transportation Acquisition",
  # SESSION 124, read 2026-11-25 (Routine TRIPWIRE 11-25 09:22Z): twelve more
  # headings went to "Awarded | N Applicants". No section names an awardee or
  # prints an amount (RFP, TA and FAQ text only; every 'awardee' on the page is
  # FAQ text). Hospital-Based Wellness Equipment is NOT hospitals only: its FAQ
  # admits "non-federally operated IHS facilities and tribally run 638 health"
  # centres. (The log printed "Con<zero-width space>necting": rhtp_watch_quote()
  # breaks "connect" so the log never reads it as an access error.)
  "Community-Based Walking Program",
  "School-Based Wellness Equipment",
  "Hospital-Based Wellness Equipment",
  "Technology as an Extender",
  "Rural Health Clinical Equipment",
  "Rural Ambulance Modernization",
  "Clinics without Walls: Telehealth Infrastructure",
  "Clinics without Walls: Remote Patient Monitoring",
  "Coordinating and Connecting Care",
  "Electronic Medical Record Enhancement",
  "Harnessing Artificial Intelligence Innovation",
  "Self-Serve Dispensing Kiosks in Pharmacies")

# SESSION 121: THE SAME ROUNDS AS A RECORD, so "Awarded, nobody named" is a
# statement in the file and not only a comment. One row per round North Dakota
# heads "Awarded"; `named` is how many recipients any ND surface names for it
# (0 on every row). Applicant counts are as the heading printed them when read.
# NO AMOUNT COLUMN, EVER: a heading prints none, and this is a status record.
# A round that later names recipients is EXTRACTED (and leaves this table's
# 'nobody named' reading); it is never patched here.
ND_AWARDED_ROUNDS <- tibble::tribble(
  ~round,                                                                                                   ~applicants, ~read,        ~session, ~named, ~hospitals_only,
  "Expand Rural Health Care Rotations",                                                                     24L,         "2026-09-23", 55L,      0L,     FALSE,
  "Zero-Hour Physical Education (PE) Initiative",                                                           NA_integer_, "2026-10-02", 85L,      0L,     FALSE,
  "Community Gardens Project",                                                                              NA_integer_, "2026-10-02", 85L,      0L,     FALSE,
  "Behavioral Health Promotion Community Grants",                                                           NA_integer_, "2026-10-02", 85L,      0L,     FALSE,
  "Rightsizing Health Care Delivery Systems for the Future: Rural Federally Qualified Health Centers and Critical Access Hospitals", NA_integer_, "2026-10-02", 85L, 0L, FALSE,
  "Mobile Mammography Unit Acquisition Funding Opportunity",                                                NA_integer_, "2026-10-02", 85L,      0L,     FALSE,
  "Workforce Retention Funding for Critical Access Hospitals and Their Owned and Operated Clinics",         36L,         "2026-10-07", 94L,      0L,     TRUE,
  "Train In Place",                                                                                         45L,         "2026-10-12", 99L,      0L,     FALSE,
  "Suicide Intervention \u2013 Healthcare Systems Initiative",                                              5L,          "2026-11-19", 120L,     0L,     FALSE,
  "Childcare for the Rural Health Workforce",                                                               8L,          "2026-11-19", 120L,     0L,     FALSE,
  "Non-Emergency Medical Transportation Acquisition",                                                       13L,         "2026-11-19", 120L,     0L,     FALSE,
  "Community-Based Walking Program", 30L, "2026-11-25", 124L, 0L, FALSE,
  "School-Based Wellness Equipment", 60L, "2026-11-25", 124L, 0L, FALSE,
  "Hospital-Based Wellness Equipment", 38L, "2026-11-25", 124L, 0L, FALSE,
  "Technology as an Extender", 45L, "2026-11-25", 124L, 0L, FALSE,
  "Rural Health Clinical Equipment", 38L, "2026-11-25", 124L, 0L, FALSE,
  "Rural Ambulance Modernization", 82L, "2026-11-25", 124L, 0L, FALSE,
  "Clinics without Walls: Telehealth Infrastructure", 17L, "2026-11-25", 124L, 0L, FALSE,
  "Clinics without Walls: Remote Patient Monitoring", 18L, "2026-11-25", 124L, 0L, FALSE,
  "Coordinating and Connecting Care", 10L, "2026-11-25", 124L, 0L, FALSE,
  "Electronic Medical Record Enhancement", 12L, "2026-11-25", 124L, 0L, FALSE,
  "Harnessing Artificial Intelligence Innovation", 11L, "2026-11-25", 124L, 0L, FALSE,
  "Self-Serve Dispensing Kiosks in Pharmacies", 5L, "2026-11-25", 124L, 0L, FALSE) %>%
  dplyr::mutate(status = "AWARDED_NOBODY_NAMED")

# THE ROUNDS WHOSE ELIGIBLE CLASS IS HOSPITALS ONLY (session 94, owner). When
# North Dakota names recipients for these, EVERY recipient is a critical
# access hospital or a clinic it owns and operates, so the round is hospital
# money in full -- ICAHN's hospitals-only class (§7), except that here each
# hospital is the DIRECT recipient. The extractor written then still types
# each named row on its CMS enrolment (an owned clinic is the hospital's own
# legal entity only where the enrolment says so); this records the class so
# nobody re-derives it from the heading.
ND_HOSPITAL_ONLY_ROUNDS <- c(
  "Workforce Retention Funding for Critical Access Hospitals and Their Owned and Operated Clinics")

#' Every opportunity heading on the funding page, split into name and status
nd_headings <- function(raw) {
  h <- xml2::read_html(raw)
  x <- stringr::str_squish(rvest::html_text2(rvest::html_elements(h, "h2")))
  m <- stringr::str_match(x, "^(.*\\S)\\s+[–-]\\s+(Closed|Awarded|Open|Coming Soon|Forthcoming|Reopened|Cancelled)\\b(.*)$")
  tibble::tibble(heading = x, name = m[, 2], status = m[, 3]) %>%
    dplyr::filter(!is.na(.data$status))
}

nd_assert_headings <- function(raw) {
  hd <- nd_headings(raw)
  if (nrow(hd) < 20L) {
    stop("[ND] the funding page yields ", nrow(hd), " status headings; the ",
         "2026-09-23 archive has 25. That is our READER, not North Dakota ",
         "(§0.4) -- re-read the page's markup.", call. = FALSE)
  }
  awarded <- hd$name[hd$status == "Awarded"]
  new <- setdiff(awarded, ND_KNOWN_AWARDED)
  if (length(new)) {
    stop("[ND] NEW OPPORTUNITY HEADED 'AWARDED': ",
         paste0("'", rhtp_watch_quote(new), "'", collapse = "; "),
         ". THAT IS THE SIGNAL. North Dakota marks an award in the heading; ",
         "read the section for an awardee list and extract it.", call. = FALSE)
  }
  invisible(hd)
}

#' SESSION 121: the record and the quiet-list are one list, the hospitals-only
#' class is the same in both places, every row reads "nobody named", and the
#' applicant counts agree with the archived headings.
nd_assert_awarded_record <- function(hd) {
  r <- ND_AWARDED_ROUNDS
  if (!setequal(r$round, ND_KNOWN_AWARDED) || anyDuplicated(r$round)) {
    stop("[ND] ND_AWARDED_ROUNDS and ND_KNOWN_AWARDED disagree: a round read ",
         "as Awarded must be recorded in both.", call. = FALSE)
  }
  if (!setequal(r$round[r$hospitals_only], ND_HOSPITAL_ONLY_ROUNDS)) {
    stop("[ND] the hospitals-only class differs between ND_AWARDED_ROUNDS and ",
         "ND_HOSPITAL_ONLY_ROUNDS.", call. = FALSE)
  }
  if (any(r$named != 0L) || any(r$status != "AWARDED_NOBODY_NAMED") ||
      any(grepl("amount", names(r)))) {
    stop("[ND] ND_AWARDED_ROUNDS records 'Awarded, nobody named' and no amount; ",
         "a round that names recipients is EXTRACTED, not patched here.", call. = FALSE)
  }
  n <- suppressWarnings(as.integer(stringr::str_match(hd$heading, "\\|\\s*([0-9]+) Applicants")[, 2]))
  live <- tibble::tibble(round = hd$name, n = n)[hd$status == "Awarded", ]
  chk <- dplyr::inner_join(r, live, by = "round") %>%
    dplyr::filter(!is.na(.data$applicants), !is.na(.data$n), .data$applicants != .data$n)
  if (nrow(chk)) {
    stop("[ND] an Awarded heading's applicant count moved: ",
         paste0(chk$round, " (", chk$applicants, " -> ", chk$n, ")", collapse = "; "),
         ". Re-read the section.", call. = FALSE)
  }
  invisible(TRUE)
}

nd_validate <- function() {
  hd <- nd_assert_headings(here::here(ND_PAGES$file[ND_PAGES$key == "funding"]))
  nd_assert_awarded_record(hd)
  stopifnot(nrow(hd) == 25L, sum(hd$status == "Awarded") == 11L,
            all(hd$name[hd$status == "Awarded"] %in% ND_KNOWN_AWARDED))
  message("[ND] the archive carries 25 opportunities, eleven Awarded (all in ",
          "ND_AWARDED_ROUNDS), nobody named.")
  invisible(TRUE)
}

nd_probe <- function() {
  w <- rhtp_watch_pages(ND_PAGES, ND_AGENT)
  nd_assert_headings(w$raw$funding)
  rhtp_assert_no_new_organisations_across(live = w$live, archived = w$arch,
                                          state = ND_STATE)
  message("[ND] ", paste0(w$changed$key, ": ",
                          ifelse(w$changed$changed, "CHANGED", "UNCHANGED"),
                          collapse = "; "), " -- no Awarded heading beyond the ",
          length(ND_KNOWN_AWARDED), " already read; nobody named.")
  invisible(w$changed)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) {
    # A re-base is a NEW dated file: only a page whose baseline file does not
    # exist yet is fetched, and an existing baseline is never rewritten.
    todo <- ND_PAGES[!file.exists(here::here(ND_PAGES$file)), ]
    if (!nrow(todo)) stop("[ND] every baseline exists; a re-base is a NEW dated file.", call. = FALSE)
    dir.create(here::here(ND_BASE_DIR), recursive = TRUE, showWarnings = FALSE)
    for (i in seq_len(nrow(todo))) rhtp_watch_archive(todo$url[i], todo$file[i], ND_AGENT)
  }
  if ("--validate" %in% args) nd_validate()
  if ("--probe" %in% args) rhtp_probe_run("ND", nd_probe())
  if (!length(args)) message("Usage: --validate | --probe")
}
