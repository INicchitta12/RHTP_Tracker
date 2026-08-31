# 03d_ga_great_health.R -----------------------------------------------------
# Georgia GREAT Health Program (Georgia's RHTP) -> Year 1 awardee table.
#
# Deliverable 1 for Georgia, in the schema of FL_year1_awardees.xlsx so the two
# states union without a reshape. Georgia is the second complete Deliverable 1
# dataset and the first assembled inside the repo rather than handed over as a
# finished workbook.
#
# SOURCES. Four DCH announcement pages, all archived verbatim with SHA-256
# under data/evidence/GA/ (§0.4, §0.5):
#
#   Phase 1  2026-06-08   $12,730,000   5 named awardees
#   Phase 2  2026-07-16   $30,600,000   26 organizations, initiatives 2-5
#   Phase 3  2026-07-23   $60,487,500   80 AHEAD hospitals at $750,000 + 1
#   Phase 4  2026-08-27   $93,330,827   all five initiatives, Year 1 complete
#
# They are AGENCY_PRESS_RELEASE under §8. Per §9.2 that supports a `Yes` only
# for a recipient the document NAMES, which is the whole of what is coded here.
#
# THE ONE THING TO UNDERSTAND ABOUT THIS STATE'S DATA. Georgia publishes an
# amount per INITIATIVE and then lists the awardees inside that initiative
# without splitting it. So `initiative_amount` is populated on every row and
# `amount` is populated on only the few rows where DCH states a recipient-level
# figure. §6.2 forbids dividing a pooled amount, and nothing here divides one:
# there is no per-fragment amount column for a sum to get wrong, exactly as in
# the §6.2 multi-recipient split. `amount_confirmed = No` on the pooled rows is
# the vocabulary's expected case -- "no recipient-level figure is published, not
# that verification failed" -- and is the same posture DE and OK sit in.
#
# Because of that, SUMMING `amount` DOES NOT GIVE GEORGIA'S TOTAL. Summing
# `initiative_amount` over distinct (phase, initiative) does.
# rhtp_ga_reconcile() is the function that does it correctly and it is what the
# Reconciliation sheet is built from; rhtp_ga_assert() hard-fails if anyone
# reaches the wrong total.
#
# THE 87 AHEAD HOSPITALS ARE 87 NAMED ROWS. Phase 3 awards 80 rural hospitals
# $750,000 each and Phase 4 adds 7, completing a planned Year 1 group of 87.
# Both announcements link the roster at
# greathealth.georgia.gov/value-based-care-hospital-list; that host was
# allowlisted on 2026-08-28 and the page is now archived under data/evidence/GA/
# with a SHA-256 manifest. rhtp_ga_ahead_roster() parses the 87 names out of the
# committed archive -- parsed, never transcribed, the same posture as the §7.1
# CMS allotment table -- and ga_expand_ahead_cohorts() replaces each aggregate
# cohort row with one row per named hospital, inheriting the cohort's coding.
#
# THE PAGE'S HEADING SAYS "COMPLETED APPLICATIONS", AND IT IS STILL AN AWARD
# SOURCE. Read alone it would be an eligibility list, and §0.3 would forbid
# coding it Yes. It is not read alone: DCH's Phase 3 announcement calls this
# exact url "the list of 80 awarded hospitals" and Phase 4 calls it the full
# list of the 87. The award, the count and the per-hospital figure come from the
# announcements; the page supplies only the names, and every hospital row cites
# both documents.
#
# WHICH 80 OF THE 87 CARRY THE $750,000 IS INFERRED. DCH states the figure for
# the Phase 3 eighty and does not restate it for the Phase 4 seven, and the
# roster does not label phases. The split is derived from list order: rows 1-80
# are in exact alphabetical order and row 81 breaks it, leaving exactly 7 rows
# appended at the end. The parser derives that break and REFUSES if the leading
# run is not 80, so a re-sorted page fails loudly instead of mis-attributing an
# amount. The seven carry flag_reason PHASE_ATTRIBUTION_INFERRED and no amount
# (§6.2 -- the amount is never divided). What does not depend on the inference:
# that all 87 are awarded hospitals.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only -- never |>. No setwd(); all
# paths go through here::here(). --validate and --build make NO network calls:
# they read nothing off the wire and re-run offline against the committed
# archives. Only --fetch touches the network, and only to archive the two signed
# notices of award (see rhtp_ga_noa_fetch()).
#
# CLI:
#   Rscript R/03d_ga_great_health.R --fetch      # the 2 signed NOAs -> data/evidence/GA/
#   Rscript R/03d_ga_great_health.R --validate   # assertions only, no writes
#   Rscript R/03d_ga_great_health.R --build      # assertions, then write CSV + xlsx

suppressPackageStartupMessages({
  library(dplyr)
  library(openxlsx)
  library(purrr)
  library(readr)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_pdf_text.R"))

# --- source documents ------------------------------------------------------

ga_source_url <- c(
  p1 = "https://dch.georgia.gov/announcement/2026-06-08/georgia-awards-first-great-health-program-subgrantees",
  p2 = "https://dch.georgia.gov/announcement/2026-07-16/georgia-issues-30-million-phase-2-great-health-awards-advance-rural",
  p3 = "https://dch.georgia.gov/announcement/2026-07-23/georgia-reaches-103-million-total-awards-date-expand-rural-healthcare",
  p4 = "https://dch.georgia.gov/announcement/2026-08-27/georgia-reaches-major-milestone-all-year-1-great-health-awards-fully"
)

ga_source_title <- c(
  p1 = "Georgia Awards First GREAT Health Program Subgrantees",
  p2 = "Georgia Issues $30 Million in Phase 2 GREAT Health Awards to Advance Rural Healthcare Transformation",
  p3 = "Georgia Reaches $103 Million in Total Awards to Date to Expand Rural Healthcare through GREAT Health Transformation",
  p4 = "Georgia Reaches Major Milestone with All Year 1 GREAT Health Awards Fully Committed"
)

ga_source_archive <- c(
  p1 = "data/evidence/GA/2026-06-08_great_health_phase1_first_subgrantees.html",
  p2 = "data/evidence/GA/2026-07-16_great_health_phase2_awards.html",
  p3 = "data/evidence/GA/2026-07-23_great_health_phase3_awards.html",
  p4 = "data/evidence/GA/2026-08-27_great_health_phase4_awards.html"
)

ga_phase_date <- c(
  p1 = "2026-06-08", p2 = "2026-07-16", p3 = "2026-07-23", p4 = "2026-08-27"
)

# Georgia's FY2026 CMS award, stated in the footnote of all four announcements.
GA_CMS_YEAR1_AWARD <- 218862169.63

# The Phase 2 page's own headline count of recipient organizations. The names
# printed on that page enumerate to 28 award actions across 27 distinct
# organizations (DBHDD is awarded under both Initiative 2 and Initiative 3), so
# DCH's count is one short of what its own page lists. The discrepancy is left
# standing and reported on the Reconciliation sheet rather than resolved by
# dropping a name: every organization coded here is printed on the page, and
# guessing which of the 27 DCH did not mean to count would be an invention.
GA_PHASE2_STATED_ORG_COUNT <- 26

# Georgia's Year 1 total, as the sum of its twelve initiative pools. Pinned so
# that naming the hospitals inside a pool is provably a reclassification: the
# figure below is what session 9 published and what session 22 must still get.
GA_YEAR1_AWARDED <- 197148327

# The dollars on rows whose own awardee is a named hospital. 80 AHEAD hospitals
# at $750,000 ($60,000,000) plus the 21 award actions on the two signed notices
# of award ($30,277,580). Not a total of what reached Georgia's hospitals: the
# pooled initiatives that DCH never split are outside it in both directions.
GA_NAMED_HOSPITAL_DOLLARS <- 90277580

# The five GREAT Health initiatives, as DCH names them.
ga_initiative_name <- c(
  "1" = "Transforming for a Sustainable Health System in Rural Georgia",
  "2" = "Strengthening the Continuum of Care in Rural Georgia",
  "3" = "Connecting to Care to Improve Healthcare Access in Rural Georgia",
  "4" = "Growing a Highly Skilled Healthcare Workforce in Rural Georgia",
  "5" = "Leveraging Technology for Healthcare Innovations in Rural Georgia"
)

# --- the AHEAD hospital roster ---------------------------------------------
#
# The 87 named hospitals, parsed out of the committed archive of the DCH-linked
# roster. Offline and deterministic: this file still makes no network call.

GA_AHEAD_ROSTER_URL <- "https://greathealth.georgia.gov/value-based-care-hospital-list"
GA_AHEAD_ROSTER_ARCHIVE <-
  "data/evidence/GA/2026-08-28_value_based_care_hospital_list.html"

# Stated by DCH in the Phase 3 announcement, for the Phase 3 eighty only.
GA_AHEAD_PER_HOSPITAL_AMOUNT <- 750000
GA_AHEAD_PHASE3_COUNT <- 80L
GA_AHEAD_YEAR1_COUNT <- 87L

# Resolved by synonym rather than by position, so a column rename on the state
# page is not a code change (the R/03b and R/00 posture).
ga_roster_synonyms <- list(
  hospital_name   = c("hospital name", "hospital", "name", "facility",
                      "facility name", "hospital/facility"),
  address         = c("address", "street address", "street"),
  city_state_zip  = c("city/state/zip", "city state zip", "city/state",
                      "city, state, zip", "city", "location"),
  designation     = c("designation", "designations", "type",
                      "rural designation", "hospital designation")
)

ga_resolve_roster_column <- function(headers, key) {
  norm <- headers %>%
    stringr::str_to_lower() %>%
    stringr::str_squish()
  hit <- which(norm %in% ga_roster_synonyms[[key]])
  if (length(hit) != 1L) {
    stop("[GA] roster column `", key, "` resolved to ", length(hit),
         " columns (headers seen: ", paste(headers, collapse = " | "),
         "). Refusing to guess.", call. = FALSE)
  }
  hit
}

# The length of the leading run that is in alphabetical order. This is what the
# Phase 3 / Phase 4 split is derived from -- see the header note and the archive
# manifest. Returned rather than assumed so the caller can refuse on it.
ga_alphabetical_prefix <- function(x) {
  key <- stringr::str_to_upper(stringr::str_squish(x))
  n <- 1L
  while (n < length(key) && key[[n + 1L]] >= key[[n]]) {
    n <- n + 1L
  }
  n
}

rhtp_ga_ahead_roster <- function(path = GA_AHEAD_ROSTER_ARCHIVE) {
  full <- here::here(path)
  if (!file.exists(full)) {
    stop("[GA] the AHEAD roster archive is missing: ", path,
         ". Re-archive ", GA_AHEAD_ROSTER_URL, " before building.", call. = FALSE)
  }

  tables <- xml2::read_html(full) %>% rvest::html_elements("table")
  if (length(tables) != 1L) {
    stop("[GA] the roster page holds ", length(tables),
         " tables; exactly one is expected. Refusing to guess which is the ",
         "hospital list.", call. = FALSE)
  }
  raw <- rvest::html_table(tables[[1]])

  idx <- vapply(names(ga_roster_synonyms),
                function(k) ga_resolve_roster_column(names(raw), k),
                integer(1))

  roster <- tibble::tibble(
    hospital_name   = stringr::str_squish(raw[[idx[["hospital_name"]]]]),
    address         = stringr::str_squish(raw[[idx[["address"]]]]),
    city_state_zip  = stringr::str_squish(raw[[idx[["city_state_zip"]]]]),
    designation_raw = stringr::str_squish(raw[[idx[["designation"]]]])
  ) %>%
    dplyr::filter(nzchar(.data$hospital_name))

  if (nrow(roster) != GA_AHEAD_YEAR1_COUNT) {
    stop("[GA] the roster parses to ", nrow(roster), " hospitals; DCH states a ",
         "planned Year 1 group of ", GA_AHEAD_YEAR1_COUNT, ".", call. = FALSE)
  }
  if (dplyr::n_distinct(roster$hospital_name) != GA_AHEAD_YEAR1_COUNT) {
    stop("[GA] the roster repeats a hospital name; ",
         dplyr::n_distinct(roster$hospital_name), " are distinct.", call. = FALSE)
  }

  run <- ga_alphabetical_prefix(roster$hospital_name)
  if (run != GA_AHEAD_PHASE3_COUNT) {
    stop("[GA] the roster's leading alphabetical run is ", run,
         " hospitals, not ", GA_AHEAD_PHASE3_COUNT, ". The Phase 3 / Phase 4 ",
         "split is derived from that break, so a re-sorted or re-ordered page ",
         "must be re-read by a human rather than split on a stale assumption.",
         call. = FALSE)
  }

  roster %>%
    dplyr::mutate(
      list_position = dplyr::row_number(),
      phase = dplyr::if_else(
        .data$list_position <= GA_AHEAD_PHASE3_COUNT, "3", "4"),
      # The page states that CAH and RRC are CMS designations. "Rural" and
      # "In 126 Rural/Partial Rural Counties" are Georgia's own classifications
      # and are not CMS designations, so they are NONE in the §8 vocabulary and
      # kept verbatim in rural_designation_raw (§8: never discard raw language).
      rural_designation = dplyr::case_when(
        .data$designation_raw == "CAH" ~ "CAH",
        .data$designation_raw == "RRC" ~ "RRC",
        TRUE ~ "NONE"
      )
    )
}

# --- the two signed Notices of Award ---------------------------------------
#
# THE TWO AGGREGATE ROWS BELOW WERE NEVER THE WHOLE STORY, AND THE REASON THEY
# SURVIVED FOUR SESSIONS IS THAT NOBODY READ THE CHILD PAGE.  DCH's Phase 4
# announcement states "13 hospitals" for surgical robotics and "eight hospitals"
# for telepods, and names none of them; those two sentences are what the
# RECIPIENT_NAMES_NOT_CAPTURED rows record.  Session 21's completeness re-check
# then read greathealth.georgia.gov/find-funding-opportunities -- a page no
# earlier session had opened -- and found a signed NOTICE OF AWARD for each
# strategy, naming every recipient and its amount.
#
# THIS IS NOT NEW MONEY, AND SAYING SO IS THE POINT.  Both strategies already
# sit inside Georgia's $197,148,327 at POOL level: Initiative 5's $37,500,000
# and Initiative 3's $10,378,639 are counted by rhtp_ga_reconcile(), which sums
# distinct (phase, initiative) pools and never sums `amount`.  What changes is
# that $30,277,580 moves from "a pool DCH says went to hospitals" to
# "twenty-one award actions with a hospital's name on each".  An assertion
# below pins the state total at $197,148,327 across the change.
#
# SOURCE STRENGTH GOES UP, NOT DOWN.  Every other Georgia row rests on an
# AGENCY_PRESS_RELEASE, which under §9.2 supports a `Yes` only for a recipient
# the document names.  These twenty-one rest on a NOTICE_OF_AWARD -- DCH's own
# words, "has awarded a grant agreement to the successful applicants listed
# below" -- which is the strongest source type in §8.  So these rows carry their
# own validation_source_type, their own url and their own archive path,
# overriding the phase defaults every other row inherits.
#
# THE NAMES AND THE AMOUNTS ARE PARSED, NEVER TRANSCRIBED (§7.1's posture).
# ga_noa_award_table() reads the committed PDF through the repository's own
# reader and rebuilds the table from the page's own GEOMETRY: an award row is
# anchored on its GREAT-###### application number, and the applicant name is
# whatever sits in the name column within that row's vertical band.  DCH wraps
# long names across two lines ("Hospital Authority of Stephens" / "County") and
# on one telepod row puts both name lines at the SAME y as each other and a
# different y from the amount, so a reader keyed on line order alone attaches
# "County" to the next hospital.  Banding on the anchor's y is what survives
# that.
#
# WHY determination_confidence IS MEDIUM HERE AND HIGH ON THE 87 AHEAD ROWS.
# §7 reserves HIGH for a named hospital recipient WITH A CCN MATCH, and this
# repository has no CCN source yet (open blocker 5).  These twenty-one are
# "primary source, hospital identity inferred from name without CCN match",
# which is §7's MEDIUM exactly, and is the coding session 21 gave Maryland's
# six named hospitals.  The 87 AHEAD rows were hand-coded HIGH in session 10,
# before that reading was settled; they are left alone rather than re-coded as
# a side effect of this change (§2.1), and the divergence is reported on the
# Reconciliation sheet so it is visible rather than buried.
#
# ONE NAME THE SHARED CLASSIFIER WOULD NOT RECOGNISE.  Of the twenty distinct
# names, rhtp_classify_recipient_type() types nineteen HOSPITAL_OR_SYSTEM from
# the name alone and falls through on "Atrium Health Navicent Baldwin".  It is
# typed HOSPITAL_OR_SYSTEM here on DCH's own statement of the class -- the
# announcement says the award went to hospitals and the NOA's heading is
# "SUCCESSFUL APPLICANT" under a hospitals-only strategy -- not on this
# pipeline's knowledge of Georgia (§0.4).  Georgia is hand-coded throughout and
# does not call the shared classifier; the check was run as a cross-check only.
#
# DCH ALSO NAMES ITS UNSUCCESSFUL APPLICANTS, WITH REASONS -- five on the
# robotics notice, two on the telepods notice.  They are not awards and nothing
# here codes them.  Their COUNT is asserted, because getting it right requires
# the successful/unsuccessful section split to be right, which is the same
# thing the twenty-one depend on.

GA_NOA_DIR <- "data/evidence/GA"

# The award-row anchor.  One per award action, and DCH prints it in its own
# column, so it is a far better row key than the amount (which repeats) or the
# name (which wraps, and which repeats -- Miller County Hospital holds two
# telepod awards).
GA_NOA_APP_ID <- "GREAT-[0-9]{6}"

# Column and row tolerances, in PDF points.  The name column is identified by
# the x of the first body line in the section rather than by a literal, so a
# re-typeset document does not need a code change; 1pt is tight enough to
# exclude the page footer, which sits ~2.4pt to the right of it.  3pt of
# vertical slack is what the telepods notice needs: one row's amount is painted
# 1.2pt above its own name lines.
GA_NOA_NAME_X_TOL <- 1.0
GA_NOA_ROW_Y_TOL <- 3.0

GA_NOA_SOURCES <- tibble::tribble(
  ~key, ~strategy, ~file, ~url, ~title,
  ~recheck_sha256, ~stated_actions, ~stated_total, ~stated_unsuccessful,

  "robots",
  "Workforce Retention Technology (surgical robotics)",
  "ga_noa_workforce_retention_technology_signed.pdf",
  paste0("https://greathealth.georgia.gov/document/document/",
         "notice-award-workforce-retention-technology-surgical-robotssigned/download"),
  paste0("Notice of Award -- Initiative 5: Leveraging Technology in Support of ",
         "Healthcare Innovations in Rural Georgia; Strategy: Workforce ",
         "Retention Technology (Surgical Robots)"),
  "f080a773368b90526d6382797aae9ca504fb1642345560c6464eceb874350dad",
  13L, 26000000, 5L,

  "telepods",
  "Care to Consumer Point-of-Care Telepods",
  "ga_noa_point_of_care_telepods_signed.pdf",
  paste0("https://greathealth.georgia.gov/document/document/",
         "notice-award-point-care-telepodssigned-0/download"),
  paste0("Notice of Award -- Initiative 3: Connecting to Care to Improve ",
         "Healthcare Access; Strategy: Point-of-Care Telepods"),
  "49ba971bd4a98502ee1e440d4db9b3a4175dfa758e2bf3b3b47265d40d5af844",
  8L, 4277580, 2L
) %>%
  dplyr::mutate(path = file.path(GA_NOA_DIR, .data$file))

# strategy -> notice-of-award key. The strategy string is what the aggregate
# template row and the notice have in common.
GA_NOA_STRATEGY_KEY <- stats::setNames(GA_NOA_SOURCES$key, GA_NOA_SOURCES$strategy)

GA_NOA_USER_AGENT <-
  "RHTP-Tracker/0.1 (AHA Data & Policy research; +https://www.aha.org)"

#' Fetch the two signed Notices of Award into Georgia's own evidence directory.
#'
#' The bytes are ALSO in session 21's completeness re-check archive, which says
#' of itself that it is not an extraction source.  Rather than copy them across
#' -- which would move a file and call it provenance -- they are fetched again,
#' and the digest of what comes back is asserted EQUAL to the digest session 21
#' recorded on 2026-08-29.  That closes two things at once: Georgia's own
#' archive is a primary fetch with its own date, and the document demonstrably
#' has not changed between the re-check that found it and the extraction that
#' reads it.  A mismatch is a hard failure, because a silently edited notice of
#' award is exactly the thing this project must not extract from unnoticed.
#'
#' This is the only function in this file that touches the network.
rhtp_ga_noa_fetch <- function(force = FALSE) {
  dir.create(here::here(GA_NOA_DIR), recursive = TRUE, showWarnings = FALSE)

  entries <- purrr::map_dfr(seq_len(nrow(GA_NOA_SOURCES)), function(i) {
    src <- GA_NOA_SOURCES[i, ]
    dest <- here::here(src$path)

    if (file.exists(dest) && !force) {
      message("[GA] cached: ", src$file)
    } else {
      Sys.sleep(2)
      message("[GA] fetching ", src$url)
      resp <- httr::GET(src$url, httr::user_agent(GA_NOA_USER_AGENT),
                        httr::timeout(180))
      if (httr::status_code(resp) != 200L) {
        stop("[GA] HTTP ", httr::status_code(resp), " for ", src$url,
             call. = FALSE)
      }
      body <- httr::content(resp, as = "raw")
      if (!identical(rawToChar(body[seq_len(5)]), "%PDF-")) {
        stop("[GA] ", src$url, " did not return a PDF.", call. = FALSE)
      }
      writeBin(body, dest)
    }

    got <- digest::digest(file = dest, algo = "sha256")
    if (!identical(got, src$recheck_sha256)) {
      stop("[GA] ", src$file, " hashes ", got, " but session 21's re-check ",
           "recorded ", src$recheck_sha256, " on 2026-08-29. DCH has changed ",
           "the notice of award; re-read it before extracting from it.",
           call. = FALSE)
    }

    tibble::tibble(
      key = src$key, file = src$file, url = src$url,
      bytes = file.info(dest)$size, sha256 = got,
      matches_recheck_2026_08_29 = TRUE,
      fetched_utc = format(Sys.time(), tz = "UTC", "%Y-%m-%dT%H:%M:%SZ")
    )
  })

  ga_noa_write_manifest(entries)
  entries
}

ga_noa_write_manifest <- function(entries) {
  path <- here::here(GA_NOA_DIR, "ga_notices_of_award.manifest.txt")
  lines <- c(
    "RHTP tracker archive (spec 0.4 / 0.5): Georgia GREAT Health signed NOTICES",
    "OF AWARD -- the 21 named hospital award actions behind Phase 4's two",
    "'names not captured' aggregate rows.",
    "",
    paste0("fetched_utc     : ", entries$fetched_utc[[1]]),
    "state           : GA",
    "host            : greathealth.georgia.gov",
    "http_status     : 200",
    "source_doc_type : NOTICE_OF_AWARD (spec 8's strongest source type)",
    "found_via       : greathealth.georgia.gov/find-funding-opportunities, read",
    "                  for the first time by R/03q's completeness re-check",
    "                  (session 21). No earlier session opened that page.",
    "",
    "EVERY DIGEST BELOW IS ASSERTED EQUAL TO THE ONE R/03q RECORDED ON",
    "2026-08-29 (data/evidence/recheck/2026-08-29/GA/MANIFEST.txt). These are",
    "fresh fetches, not copies: Georgia's archive is primary, AND the document",
    "is proved unchanged between the re-check that found it and the extraction",
    "that reads it. rhtp_ga_noa_fetch() hard-fails on a mismatch.",
    "",
    "FILES",
    ""
  )
  for (i in seq_len(nrow(entries))) {
    src <- GA_NOA_SOURCES[GA_NOA_SOURCES$key == entries$key[[i]], ]
    lines <- c(lines,
      paste0("  file    : ", entries$file[[i]]),
      paste0("  title   : ", src$title),
      paste0("  url     : ", entries$url[[i]]),
      paste0("  bytes   : ", entries$bytes[[i]]),
      paste0("  sha256  : ", entries$sha256[[i]]),
      paste0("  rows    : ", src$stated_actions, " successful applicants, ",
             format(src$stated_total, big.mark = ","), " total; ",
             src$stated_unsuccessful, " unsuccessful applicants with reasons"),
      "  columns : SUCCESSFUL APPLICANT | AWARD AMOUNT | GREAT Grant Application #",
      ""
    )
  }
  lines <- c(lines,
    "WHAT IS AND IS NOT EXTRACTED FROM THESE FILES",
    "",
    "  Extracted: the 21 successful award actions -- name, amount, application",
    "  number -- into ga_great_health_awards.csv, replacing the two aggregate",
    "  rows that read 'names not captured'.",
    "",
    "  NOT extracted: the 7 unsuccessful applicants DCH names, with its reasons",
    "  for each. They are not award actions and nothing here codes them. Their",
    "  COUNT is asserted (5 and 2), because the successful/unsuccessful section",
    "  split has to be right for the 21 to be right.",
    "",
    "MANIFEST.txt cannot record its own digest (session 15), and this file is",
    "not listed above for the same reason."
  )
  writeLines(lines, path)
  invisible(path)
}

#' Split a notice of award into its successful and unsuccessful sections.
#'
#' Ordered by (page, descending y), which is the document's own reading order,
#' and cut at the two column headers. "SUCCESSFUL APPLICANT" is anchored to the
#' start of the line so that "UNSUCCESSFUL APPLICANT" -- which contains it as a
#' substring -- cannot open the section it closes.
ga_noa_section <- function(lines, section = c("successful", "unsuccessful")) {
  section <- match.arg(section)
  ln <- lines %>%
    dplyr::mutate(.paint_order = dplyr::row_number()) %>%
    dplyr::arrange(.data$page, dplyr::desc(.data$y), .data$.paint_order)

  opens  <- which(stringr::str_detect(ln$text, "^\\s*SUCCESSFUL\\s+APPLICANT"))
  closes <- which(stringr::str_detect(ln$text, "UNSUCCESSFUL\\s*APPLICANT"))
  if (length(opens) != 1L || length(closes) != 1L || closes <= opens) {
    stop("[GA] a notice of award does not have exactly one SUCCESSFUL header ",
         "followed by one UNSUCCESSFUL header (found ", length(opens), " and ",
         length(closes), "). Re-read the document before trusting a parse.",
         call. = FALSE)
  }
  if (identical(section, "successful")) {
    ln[(opens + 1L):(closes - 1L), ]
  } else {
    ln[(closes + 1L):nrow(ln), ]
  }
}

#' Rebuild the successful-applicant table from the page's geometry.
ga_noa_award_table <- function(path) {
  sec <- ga_noa_section(rhtp_pdf_lines(here::here(path)), "successful")

  # The name column is wherever the section's first body line starts. DCH puts
  # the applicant name there on every row; the amount and the application
  # number are either on that same line or in their own columns to the right.
  name_x <- sec$x[[1]]
  in_name_col <- abs(sec$x - name_x) <= GA_NOA_NAME_X_TOL
  anchors <- which(stringr::str_detect(sec$text, GA_NOA_APP_ID))
  if (!length(anchors)) {
    stop("[GA] no GREAT application numbers in the successful section of ",
         path, ".", call. = FALSE)
  }

  purrr::map_dfr(seq_along(anchors), function(i) {
    a <- anchors[[i]]
    page <- sec$page[[a]]
    # The band runs from this row's anchor down to the next anchor ON THE SAME
    # PAGE. Bounding by page matters: the last row of page 1 is followed, in
    # document order, by the first row of page 2, whose y is far HIGHER.
    below <- anchors[anchors > a & sec$page[anchors] == page]
    floor_y <- if (length(below)) {
      sec$y[[below[[1]]]] + GA_NOA_ROW_Y_TOL
    } else {
      -Inf
    }
    band <- in_name_col & sec$page == page &
      sec$y <= sec$y[[a]] + GA_NOA_ROW_Y_TOL & sec$y > floor_y
    if (!any(band)) {
      stop("[GA] no applicant name in the name column for ",
           stringr::str_extract(sec$text[[a]], GA_NOA_APP_ID), " in ", path,
           call. = FALSE)
    }

    awardee <- sec$text[band] %>%
      # Where the name shares a line with the amount, the name is what precedes
      # the dollar sign. Nothing in a Georgia hospital's name contains one.
      stringr::str_remove("\\$.*$") %>%
      stringr::str_remove(paste0(GA_NOA_APP_ID, ".*$")) %>%
      paste(collapse = " ") %>%
      stringr::str_squish()
    amount <- stringr::str_match(
      sec$text[[a]], "\\$\\s*([0-9][0-9,]*\\.[0-9]{2})")[, 2]
    if (is.na(amount)) {
      stop("[GA] no award amount on the row for ",
           stringr::str_extract(sec$text[[a]], GA_NOA_APP_ID), " in ", path,
           call. = FALSE)
    }

    tibble::tibble(
      application_id = stringr::str_extract(sec$text[[a]], GA_NOA_APP_ID),
      awardee = awardee,
      amount = as.numeric(stringr::str_remove_all(amount, ","))
    )
  })
}

#' Count the unsuccessful applicants a notice names. Never coded -- asserted.
ga_noa_unsuccessful_count <- function(path) {
  sec <- ga_noa_section(rhtp_pdf_lines(here::here(path)), "unsuccessful")
  length(stringr::str_subset(sec$text, GA_NOA_APP_ID))
}

#' The 21 award actions, with the source each came from, checked against what
#' DCH's own Phase 4 announcement says the strategy awarded.
rhtp_ga_noa_awards <- function() {
  purrr::map_dfr(seq_len(nrow(GA_NOA_SOURCES)), function(i) {
    src <- GA_NOA_SOURCES[i, ]
    if (!file.exists(here::here(src$path))) {
      stop("[GA] the signed notice of award is missing: ", src$path,
           ". Run `Rscript R/03d_ga_great_health.R --fetch` first; without it ",
           "the ", src$stated_actions, " ", src$strategy,
           " hospitals have no evidence behind them.", call. = FALSE)
    }
    tab <- ga_noa_award_table(src$path)
    if (nrow(tab) != src$stated_actions) {
      stop("[GA] ", src$file, " parses to ", nrow(tab), " award actions; DCH's ",
           "Phase 4 announcement states ", src$stated_actions, ".", call. = FALSE)
    }
    if (abs(sum(tab$amount) - src$stated_total) > 0.005) {
      stop("[GA] ", src$file, " sums to ",
           format(sum(tab$amount), big.mark = ","), " against ",
           format(src$stated_total, big.mark = ","), ".", call. = FALSE)
    }
    tab %>% dplyr::mutate(key = src$key, strategy = src$strategy)
  })
}

# --- the record table ------------------------------------------------------
#
# One row per award action as DCH describes it. Kept in this file rather than a
# hand-edited CSV so that every change to a coding decision shows up as a diff
# a reviewer can read (§2.1). The CSV is a render of this, never the reverse.

# --- expanding the AHEAD cohorts into named hospitals ----------------------
#
# The two cohort rows in the table below stay as the readable statement of the
# coding decision (§2.1: a coding change should show up as a diff). They are
# TEMPLATES: ga_expand_ahead_cohorts() replaces each one, in place, with one row
# per named hospital that inherits the cohort's recipient_type, flow_type,
# distributed_to_hospital, hospital_benefiting and confidence, and overrides
# only what the roster settles -- the name, the count, the designation, and
# whether an amount is stated for that phase.

ga_ahead_rows <- function(template, roster) {
  ph <- template$phase[[1]]
  hs <- roster %>% dplyr::filter(.data$phase == ph)
  if (!nrow(hs)) {
    stop("[GA] no roster hospitals for phase ", ph, ".", call. = FALSE)
  }

  # DCH states $750,000 per hospital for the Phase 3 eighty, and does not
  # restate a per-hospital figure in Phase 4. Nothing is divided either way.
  stated <- identical(ph, "3")

  note <- if (stated) {
    paste0(
      "One of the 80 rural hospitals DCH states were each awarded $750,000 for ",
      "AHEAD Model pre-implementation. The award action, the count and the ",
      "per-hospital figure are stated in the DCH 2026-07-23 announcement; the ",
      "name is read from the roster that announcement links to as 'the list of ",
      "80 awarded hospitals', archived at ", GA_AHEAD_ROSTER_ARCHIVE, ". ",
      "80 x $750,000 = $60,000,000 closes on the stated Initiative 1 pool."
    )
  } else {
    paste0(
      "One of the 7 rural hospitals DCH added in Phase 4 to complete the ",
      "planned Year 1 group of 87. Phase 4 does not restate the $750,000 ",
      "per-hospital figure, so no amount is carried (§6.2 -- the amount is ",
      "never divided). The roster, archived at ", GA_AHEAD_ROSTER_ARCHIVE,
      ", does not label phases: this hospital is attributed to Phase 4 because ",
      "it falls outside the roster's leading 80-row alphabetical block. That ",
      "attribution is an inference, flagged PHASE_ATTRIBUTION_INFERRED; that ",
      "the hospital is an awarded member of the 87 is not."
    )
  }

  template[rep(1L, nrow(hs)), ] %>%
    dplyr::mutate(
      awardee = hs$hospital_name,
      recipient_count = 1L,
      recipient_confirmed = "Yes",
      amount = if (stated) GA_AHEAD_PER_HOSPITAL_AMOUNT else NA_real_,
      amount_basis = if (stated) "STATED_PER_RECIPIENT" else "NOT_PUBLISHED",
      amount_confirmed = if (stated) "Yes" else "No",
      rural_designation = hs$rural_designation,
      rural_designation_raw = hs$designation_raw,
      recipient_names_source_url = GA_AHEAD_ROSTER_URL,
      flag_reason = if (stated) NA_character_ else "PHASE_ATTRIBUTION_INFERRED",
      note = note
    )
}

ga_expand_ahead_cohorts <- function(records, roster = rhtp_ga_ahead_roster()) {
  at <- which(stringr::str_detect(
    records$awardee, "AHEAD Model pre-implementation cohort"))
  if (length(at) != 2L) {
    stop("[GA] expected 2 AHEAD cohort template rows, found ", length(at), ".",
         call. = FALSE)
  }

  pieces <- list()
  prev <- 0L
  for (i in at) {
    if (i > prev + 1L) {
      pieces <- append(pieces, list(records[(prev + 1L):(i - 1L), ]))
    }
    pieces <- append(pieces, list(ga_ahead_rows(records[i, ], roster)))
    prev <- i
  }
  if (prev < nrow(records)) {
    pieces <- append(pieces, list(records[(prev + 1L):nrow(records), ]))
  }
  dplyr::bind_rows(pieces)
}

# --- expanding the two NOA cohorts into named hospitals --------------------
#
# The same device as ga_expand_ahead_cohorts(), for the same reason: the
# aggregate row stays in the tribble as the readable statement of what DCH's
# press release says, and is replaced in place by one row per named recipient
# that INHERITS the cohort's coding and overrides only what the notice of award
# settles -- the name, the amount, the count, the source document, and the two
# confirmation flags.
#
# Nothing here divides a pool (§6.2). DCH states an amount per recipient on the
# notice, so `amount` is that stated figure and `amount_basis` is
# STATED_PER_RECIPIENT, exactly as on the 80 AHEAD rows.

ga_noa_rows <- function(template, awards) {
  key <- template$noa_key[[1]]
  hs <- awards %>% dplyr::filter(.data$key == !!key)
  if (!nrow(hs)) {
    stop("[GA] no notice-of-award rows for cohort '", key, "'.", call. = FALSE)
  }
  src <- GA_NOA_SOURCES[GA_NOA_SOURCES$key == key, ]

  template[rep(1L, nrow(hs)), ] %>%
    dplyr::mutate(
      awardee = hs$awardee,
      application_id = hs$application_id,
      recipient_count = 1L,
      recipient_confirmed = "Yes",
      amount = hs$amount,
      amount_basis = "STATED_PER_RECIPIENT",
      amount_confirmed = "Yes",
      # §7: HIGH needs a CCN match and this repository has no CCN source yet
      # (open blocker 5). A named hospital on a primary source without one is
      # MEDIUM -- Maryland's coding, session 21.
      determination_confidence = "MEDIUM",
      flag_reason = NA_character_,
      recipient_names_source_url = src$url,
      source_title_override = src$title,
      source_url_override = src$url,
      source_archive_override = src$path,
      validation_source_type_override = "NOTICE_OF_AWARD",
      extraction_method_override = "DIRECT_TEXT",
      validator_override = "AUTO",
      note = paste0(
        "Named on DCH's SIGNED NOTICE OF AWARD for ", src$strategy,
        " (application ", hs$application_id, "), archived at ", src$path,
        ". DCH: 'The Georgia Department of Community Health has awarded a ",
        "grant agreement to the successful applicants listed below.' The award ",
        "and the strategy are stated in the DCH 2026-08-27 announcement, which ",
        "gives the count (", src$stated_actions, ") and names nobody; the ",
        "notice supplies the name and the recipient-level amount. The ",
        format(src$stated_actions), " actions sum to ",
        format(src$stated_total, big.mark = ","),
        ", inside the stated Initiative ", template$initiative_number[[1]],
        " pool. This is a pool-to-named reclassification: no dollar enters ",
        "Georgia's total that was not already in it."
      )
    )
}

ga_expand_noa_cohorts <- function(records, awards = rhtp_ga_noa_awards()) {
  at <- which(!is.na(records$noa_key))
  if (length(at) != nrow(GA_NOA_SOURCES)) {
    stop("[GA] expected ", nrow(GA_NOA_SOURCES), " notice-of-award cohort ",
         "template rows, found ", length(at), ".", call. = FALSE)
  }

  pieces <- list()
  prev <- 0L
  for (i in at) {
    if (i > prev + 1L) {
      pieces <- append(pieces, list(records[(prev + 1L):(i - 1L), ]))
    }
    pieces <- append(pieces, list(ga_noa_rows(records[i, ], awards)))
    prev <- i
  }
  if (prev < nrow(records)) {
    pieces <- append(pieces, list(records[(prev + 1L):nrow(records), ]))
  }
  dplyr::bind_rows(pieces)
}

rhtp_ga_records <- function() {
  tibble::tribble(
    ~phase, ~initiative_number, ~initiative_amount, ~awardee, ~recipient_count,
    ~amount, ~amount_basis, ~recipient_type, ~flow_type, ~distributed_to_hospital,
    ~hospital_benefiting, ~determination_confidence, ~recipient_confirmed,
    ~amount_confirmed, ~strategy, ~note, ~flag_reason,

    # -- Phase 1 (2026-06-08), $12,730,000 across five strategies ------------
    # The page does not map these to the numbered initiatives, so
    # initiative_number is NA rather than inferred. It states one pooled total
    # for all five, so initiative_amount carries the phase total and is
    # deduplicated on (phase, initiative) in the reconciliation.
    "1", NA_character_, 12730000, "Georgia Department of Public Health", 1L,
    NA_real_, "NOT_PUBLISHED", "STATE_AGENCY", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Public Health Investments: Georgia Newborn Screening Program",
    "Expands newborn screening at the Waycross laboratory. Recipient is the state health agency; the benefit is to rural families, not to a hospital (§10.2 judges the recipient).",
    NA_character_,

    "1", NA_character_, 12730000, "Side by Side", 1L,
    NA_real_, "NOT_PUBLISHED", "NONPROFIT_CBO", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Support for Acquired Brain Injury (ABI) Survivors",
    "Community-based brain injury program; funds the first rural ABI clubhouse.",
    NA_character_,

    "1", NA_character_, 12730000, "University System of Georgia", 1L,
    NA_real_, "NOT_PUBLISHED", "UNIVERSITY_OR_AHC", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Nursing Care Improvements",
    "Nurse Summer Camps to build the nursing pipeline.",
    NA_character_,

    "1", NA_character_, 12730000, "Georgia Statewide AHEC Network", 1L,
    NA_real_, "NOT_PUBLISHED", "AHEC", "NON_HOSPITAL", "No",
    "Yes", "HIGH", "Yes", "No",
    "Area Health Education Center (AHEC) Training & Housing",
    "Short-term housing for students in rural placements and Digital Health Navigator training. Rural sites host the placements, so hospitals benefit without receiving funds.",
    NA_character_,

    "1", NA_character_, 12730000, "Sharecare", 1L,
    NA_real_, "NOT_PUBLISHED", "VENDOR_OR_CONTRACTOR", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Consumer Engagement Enhancements",
    "Consumer wellness platform. A vendor receives the money and consumers use the product.",
    NA_character_,

    # -- Phase 2 (2026-07-16), Initiative 2, $4.6M --------------------------
    "2", "2", 4600000, "Georgia Health Information Network (GaHIN)", 1L,
    NA_real_, "NOT_PUBLISHED", "VENDOR_OR_CONTRACTOR", "NON_HOSPITAL", "No",
    "Yes", "MEDIUM", "Yes", "No",
    "Care coordination and cross-sector connection",
    "Statewide nonprofit health information exchange. Coded VENDOR_OR_CONTRACTOR for consistency with FL's CommunityHealth IT, which is the same kind of entity; recipient_type is inferred from the name and not stated by DCH.",
    NA_character_,

    "2", "2", 4600000, "Morehouse School of Medicine", 1L,
    NA_real_, "NOT_PUBLISHED", "UNIVERSITY_OR_AHC", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Care coordination and cross-sector connection", NA_character_, NA_character_,

    "2", "2", 4600000, "Georgia State University", 1L,
    NA_real_, "NOT_PUBLISHED", "UNIVERSITY_OR_AHC", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Care coordination and cross-sector connection", NA_character_, NA_character_,

    "2", "2", 4600000,
    "Georgia Department of Behavioral Health and Developmental Disabilities (DBHDD)", 1L,
    NA_real_, "NOT_PUBLISHED", "STATE_AGENCY", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Care coordination and cross-sector connection",
    "Transportation-to-treatment for people in mental health crisis.",
    NA_character_,

    "2", "2", 4600000, "Georgia Department of Education", 1L,
    NA_real_, "NOT_PUBLISHED", "STATE_AGENCY", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "School-based health infrastructure development",
    "§0.3a's worked contrast, in Georgia: school-based health infrastructure awarded to the Department of Education is NON_HOSPITAL because of the recipient, not the setting. Delaware's school-based health centre awarded to Beebe Healthcare is DIRECT.",
    NA_character_,

    # -- Phase 2, Initiative 3, $6.5M ---------------------------------------
    # 17 Rural Stabilization Grants to named rural hospitals, plus DBHDD.
    "2", "3", 6500000, "Appling Healthcare", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Clinch County Hospital Authority", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Colquitt Regional Medical Center", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Crisp Regional Hospital", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Dodge County Hospital", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Donalsonville Hospital, Inc.", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Effingham Hospital, Inc.", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Elbert Memorial Hospital", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000,
    "Hospital Authority of Jefferson County and the City of Louisville", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant",
    "Name contains ' and ' but is a single hospital authority, not two recipients -- the §6.2 delimiter split would be wrong here.",
    NA_character_,

    "2", "3", 6500000, "Jasper Health Services, Inc.", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Liberty Regional Medical Center", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Memorial Hospital and Manor", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant",
    "Name contains ' and ' but is one hospital (Bainbridge); not a §6.2 split.",
    NA_character_,

    "2", "3", 6500000, "Miller County Hospital", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Monroe County Hospital", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Putnam General Hospital", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "South Georgia Medical Center, Inc.", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000, "Wills Memorial Hospital", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "MEDIUM", "Yes", "No",
    "Rural Stabilization Grant", NA_character_, NA_character_,

    "2", "3", 6500000,
    "Georgia Department of Behavioral Health and Developmental Disabilities (DBHDD)", 1L,
    NA_real_, "NOT_PUBLISHED", "STATE_AGENCY", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Mobile dental clinic",
    "DBHDD's second Phase 2 award; it also appears under Initiative 2. Two award actions, one organization.",
    NA_character_,

    # -- Phase 2, Initiative 4, $12.5M --------------------------------------
    "2", "4", 12500000, "Georgia Board of Health Care Workforce", 1L,
    NA_real_, "NOT_PUBLISHED", "STATE_AGENCY", "NON_HOSPITAL", "No",
    "Yes", "HIGH", "Yes", "No",
    "Graduate medical education expansion",
    "GME expansion places residents in rural hospitals, which benefit without receiving the award.",
    NA_character_,

    "2", "4", 12500000, "University System of Georgia", 1L,
    NA_real_, "NOT_PUBLISHED", "UNIVERSITY_OR_AHC", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Nursing education pathways and simulation-based clinical training",
    NA_character_, NA_character_,

    "2", "4", 12500000, "Alzheimer's Association", 1L,
    NA_real_, "NOT_PUBLISHED", "NONPROFIT_CBO", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Dementia care workforce development", NA_character_, NA_character_,

    # -- Phase 2, Initiative 5, $7M -----------------------------------------
    "2", "5", 7000000,
    "Georgia Cyber Innovation & Training Center at Augusta University", 1L,
    NA_real_, "NOT_PUBLISHED", "UNIVERSITY_OR_AHC", "IN_KIND_BENEFIT", "No",
    "Yes", "HIGH", "Yes", "No",
    "Cybersecurity enhancements for rural hospitals",
    "The source says the funding supports cybersecurity enhancements FOR rural hospitals. The university receives the money and hospitals receive the service: §10.2's in-kind test, met on its own terms. These dollars must never enter a funds-distributed-to-hospitals total.",
    NA_character_,

    "2", "5", 7000000, "Georgia Association of Emergency Medical Services", 1L,
    NA_real_, "NOT_PUBLISHED", "EMS_OR_PSAP", "NON_HOSPITAL", "No",
    "Yes", "HIGH", "Yes", "No",
    "EMS Treat-versus-Transport model",
    "Aims to reduce unnecessary emergency department utilisation; the benefit to hospitals is indirect.",
    NA_character_,

    # -- Phase 3 (2026-07-23), Initiative 1, $60M ---------------------------
    "3", "1", 60000000,
    "80 rural hospitals (AHEAD Model pre-implementation cohort) - names not captured", 80L,
    60000000, "STATED_PER_RECIPIENT", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "HIGH", "No", "Yes",
    "AHEAD Model pre-implementation funding",
    "TEMPLATE ROW -- ga_expand_ahead_cohorts() replaces this with the 80 named hospitals from the archived roster. DCH states 80 rural hospitals each awarded $750,000; 80 x $750,000 = $60,000,000, which closes on the stated initiative total independently.",
    NA_character_,

    # -- Phase 3, Initiative 4, $487,500 ------------------------------------
    "3", "4", 487500, "Georgia Board of Health Care Workforce", 1L,
    487500, "SOLE_RECIPIENT_OF_INITIATIVE", "STATE_AGENCY", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "Yes",
    "GA-CARE nurse educator education awards",
    "Sole named recipient of the initiative, in collaboration with the University System of Georgia, so the initiative total is this recipient's amount.",
    NA_character_,

    # -- Phase 4 (2026-08-27), Initiative 1, $15,635,000 --------------------
    "4", "1", 15635000,
    "7 additional rural hospitals (AHEAD Model pre-implementation cohort) - names not captured", 7L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "HIGH", "No", "No",
    "AHEAD Model pre-implementation funding",
    "TEMPLATE ROW -- ga_expand_ahead_cohorts() replaces this with the 7 named hospitals the roster carries outside its leading alphabetical block. Completes the planned Year 1 group of 87. Phase 4 does not restate the $750,000 per-hospital figure, so no amount is carried: 7 x $750,000 = $5,250,000 would leave $10,385,000 for the readiness assessments below, but DCH states neither figure and neither is entered (§6.2 -- the amount is never divided).",
    NA_character_,

    "4", "1", 15635000,
    "AHEAD readiness assessments for all 87 hospitals - provider not named", NA_integer_,
    NA_real_, "NOT_PUBLISHED", "NOT_YET_NAMED", "IN_KIND_BENEFIT", "No",
    "Yes", "MEDIUM", "No", "No",
    "Personalized AHEAD readiness assessments",
    "DCH funded assessments of all 87 hospitals but names no provider. The hospitals are assessed, not paid, so this is in-kind and never enters a distributed-to-hospitals total.",
    NA_character_,

    # -- Phase 4, Initiative 2, $6,209,688 ----------------------------------
    "4", "2", 6209688, "Georgia Health Care Association", 1L,
    NA_real_, "NOT_PUBLISHED", "NONPROFIT_CBO", "NON_HOSPITAL", "No",
    "No", "MEDIUM", "Yes", "No",
    "Regional Nursing Home Transportation Enhancement",
    "Long-term care trade association; the beneficiaries are nursing facility residents, not hospitals.",
    NA_character_,

    "4", "2", 6209688,
    "Type 2 ambulances - rural hospitals eligible to apply, not yet awarded", NA_integer_,
    NA_real_, "NOT_PUBLISHED", "NOT_YET_NAMED", "PASS_THROUGH_UNRESOLVED", "Unclear",
    "Yes", "LOW", "No", "No",
    "Type 2 ambulance procurement",
    "DCH completed the procurement and says select rural hospitals 'will be eligible to apply for soon'. §0.3 exactly: eligibility is not receipt. Unclear, and it must not be imputed to Yes.",
    "ELIGIBILITY_NOT_RECEIPT",

    "4", "2", 6209688,
    "Planning and actuarial development, Nutrition and Weight Management eligibility category - recipient not named", NA_integer_,
    NA_real_, "NOT_PUBLISHED", "NOT_YET_NAMED", "NON_HOSPITAL", "No",
    "No", "MEDIUM", "No", "No",
    "Planning for Healthy Babies demonstration",
    "Actuarial and planning work on a proposed Medicaid eligibility category. No recipient named.",
    NA_character_,

    "4", "2", 6209688, "Emory University", 1L,
    NA_real_, "NOT_PUBLISHED", "UNIVERSITY_OR_AHC", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Building Bridges (School-Based Health Care Services Infrastructure)",
    "The second §0.3a case in this file. School-based health infrastructure again, and again NON_HOSPITAL because Emory University is the recipient. Had DCH awarded it to a hospital system, as Delaware did to Beebe Healthcare, it would be DIRECT.",
    NA_character_,

    "4", "2", 6209688, "Behavioral Pediatric Resource Center", 1L,
    NA_real_, "NOT_PUBLISHED", "NONPROFIT_CBO", "NON_HOSPITAL", "No",
    "No", "LOW", "Yes", "No",
    "Rural Provider Nutrition Training for Autism Spectrum Disorder",
    "recipient_type inferred from the name and not stated by DCH; confidence LOW pending verification of the entity's form.",
    "RECIPIENT_TYPE_INFERRED",

    "4", "2", 6209688, "Georgia Department of Public Health", 1L,
    NA_real_, "NOT_PUBLISHED", "STATE_AGENCY", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Newborn Screening Investments (added funding)",
    "An addition to the Phase 1 award to the same agency.",
    NA_character_,

    # -- Phase 4, Initiative 3, $10,378,639 ---------------------------------
    "4", "3", 10378639,
    "8 hospitals (Care to Consumer Point-of-Care Telepods, 12 telepods) - names not captured", 8L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "HIGH", "No", "No",
    "Care to Consumer Point-of-Care Telepods",
    "DCH states grants to eight hospitals for 12 telepods but names none of them. The class is confirmed; the names are not published on this page.",
    "RECIPIENT_NAMES_NOT_CAPTURED",

    "4", "3", 10378639, "Georgia Hospital Association", 1L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_AFFILIATED_ENTITY", "IN_KIND_BENEFIT", "No",
    "Yes", "HIGH", "Yes", "No",
    "Strengthening Perinatal Systems of Care",
    "GHA receives the grant and supplies obstetrical emergency carts to hospitals. Equipment reaches hospitals, dollars do not: §10.2 in-kind, hospital_benefiting = Yes.",
    NA_character_,

    "4", "3", 10378639, "Georgia Department of Public Health", 1L,
    NA_real_, "NOT_PUBLISHED", "STATE_AGENCY", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Public Health Telehealth Infrastructure",
    "Telehealth technology for rural public health sites, not hospitals.",
    NA_character_,

    "4", "3", 10378639,
    "Georgia Department of Behavioral Health and Developmental Disabilities (DBHDD)", 1L,
    NA_real_, "NOT_PUBLISHED", "STATE_AGENCY", "NON_HOSPITAL", "No",
    "Yes", "HIGH", "Yes", "No",
    "Rural Telepsychiatry (Project ECHO pediatric model)",
    "Trains rural providers; hospitals among the trained, but the award is to the agency.",
    NA_character_,

    "4", "3", 10378639, "Georgia Department of Public Health", 1L,
    NA_real_, "NOT_PUBLISHED", "STATE_AGENCY", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "PEACE for Moms (Perinatal Psychiatry, Education, Access and Community Engagement)",
    "DPH's second Initiative 3 award action.",
    NA_character_,

    # -- Phase 4, Initiative 4, $23,607,500 ---------------------------------
    "4", "4", 23607500, "Georgia Emergency Medical Services Association", 1L,
    NA_real_, "NOT_PUBLISHED", "EMS_OR_PSAP", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Emergency Services Education and Training Awards",
    "EMT and paramedic certification for rural students.",
    NA_character_,

    "4", "4", 23607500,
    "Nursing Care Improvements (clinical faculty orientation and training) - recipient not named", NA_integer_,
    NA_real_, "NOT_PUBLISHED", "NOT_YET_NAMED", "PASS_THROUGH_UNRESOLVED", "Unclear",
    "No", "LOW", "No", "No",
    "Nursing Care Improvements (added funding)",
    "Phase 4 adds funding to Nursing Care Improvements without naming a recipient. Phase 1 awarded that strategy to the University System of Georgia, but carrying that across phases would be an imputation, so it is not made (§0.3).",
    "RECIPIENT_NOT_NAMED",

    "4", "4", 23607500, "Georgia Board of Health Care Workforce", 1L,
    NA_real_, "NOT_PUBLISHED", "STATE_AGENCY", "NON_HOSPITAL", "No",
    "Yes", "HIGH", "Yes", "No",
    "Rural Provider Workforce and Graduate Medical Education Enhancements",
    "Rural hospitals host the GME placements this expands.",
    NA_character_,

    "4", "4", 23607500,
    "University System of Georgia and Georgia Board of Health Care Workforce (GA-CARE partnership)", 2L,
    NA_real_, "NOT_PUBLISHED", "UNIVERSITY_OR_AHC", "NON_HOSPITAL", "No",
    "No", "MEDIUM", "Yes", "No",
    "GA-CARE nursing faculty recruitment and development",
    "DCH describes one award to a two-party partnership. §6.2: the row names both and the amount is not divided between them. recipient_type follows the lead party.",
    "MULTI_RECIPIENT_FIELD",

    # -- Phase 4, Initiative 5, $37,500,000 ---------------------------------
    "4", "5", 37500000,
    "13 hospitals (Workforce Retention Technology, surgical robotics) - names not captured", 13L,
    NA_real_, "NOT_PUBLISHED", "HOSPITAL_OR_SYSTEM", "DIRECT", "Yes",
    "Yes", "HIGH", "No", "No",
    "Workforce Retention Technology (surgical robotics)",
    "DCH, with the Georgia Board of Health Care Workforce, awarded 13 hospitals grants to purchase surgical robotics. Hospitals are the named class of recipient; individual names are not published on this page.",
    "RECIPIENT_NAMES_NOT_CAPTURED",

    "4", "5", 37500000, "Equifax", 1L,
    NA_real_, "NOT_PUBLISHED", "VENDOR_OR_CONTRACTOR", "NON_HOSPITAL", "No",
    "No", "HIGH", "Yes", "No",
    "Eligibility System Enhancements",
    "Reduces Medicaid eligibility determination delays. A vendor receives the money.",
    NA_character_
  ) %>%
    # Columns the roster settles for the AHEAD hospitals and nothing else.
    dplyr::mutate(
      rural_designation = NA_character_,
      rural_designation_raw = NA_character_,
      recipient_names_source_url = NA_character_,
      # DCH's own row key on the notices of award. Its own column rather than
      # a phrase inside determination_basis, because it is what a re-check
      # joins on -- and joining a roster on a hospital NAME is how a re-check
      # starts reporting a state as short because a name was re-typed.
      application_id = NA_character_,
      # The two Phase 4 cohorts DCH counted and did not name. Keyed on
      # `strategy` rather than on the aggregate row's awardee text, so that the
      # link between a template row and its notice of award survives someone
      # rewording the placeholder (§2.1: the coding must be the thing that is
      # hard to change by accident, not the prose beside it).
      noa_key = unname(GA_NOA_STRATEGY_KEY[.data$strategy]),
      # Populated only where a row's source is NOT the phase announcement every
      # other row inherits. NA everywhere else, and coalesced below.
      source_title_override = NA_character_,
      source_url_override = NA_character_,
      source_archive_override = NA_character_,
      validation_source_type_override = NA_character_,
      extraction_method_override = NA_character_,
      validator_override = NA_character_
    ) %>%
    ga_expand_ahead_cohorts() %>%
    ga_expand_noa_cohorts() %>%
    dplyr::mutate(
      state = "GA",
      phase_key = paste0("p", .data$phase),
      phase_date = unname(ga_phase_date[.data$phase_key]),
      initiative = dplyr::if_else(
        is.na(.data$initiative_number),
        NA_character_,
        unname(ga_initiative_name[.data$initiative_number])
      ),
      fiscal_year = "FY2026 (Year 1)",
      source_document_title = dplyr::coalesce(
        .data$source_title_override, unname(ga_source_title[.data$phase_key])),
      state_source_url = dplyr::coalesce(
        .data$source_url_override, unname(ga_source_url[.data$phase_key])),
      source_archive_path = dplyr::coalesce(
        .data$source_archive_override, unname(ga_source_archive[.data$phase_key])),
      validation_source_type = dplyr::coalesce(
        .data$validation_source_type_override, "AGENCY_PRESS_RELEASE"),
      extraction_method = dplyr::coalesce(
        .data$extraction_method_override, "MODEL_ASSISTED"),
      validator = dplyr::coalesce(.data$validator_override, "AI-assisted - CONFIRM"),
      ccn = NA_real_, aha_id = NA_real_, reviewer = NA_character_,
      determination_basis = paste0(
        "DCH ", .data$phase_date, " announcement, GREAT Health Phase ", .data$phase,
        dplyr::if_else(is.na(.data$initiative_number), "",
                       paste0(", Initiative ", .data$initiative_number)),
        ". ", dplyr::coalesce(.data$note, "Recipient named in the source; no recipient-level amount published.")
      )
    ) %>%
    dplyr::select(-"phase_key") %>%
    dplyr::mutate(row_no = dplyr::row_number()) %>%
    dplyr::select(
      # FL_year1_awardees.xlsx column order, so the two states union unchanged
      "state", "row_no", "awardee", "amount", "recipient_type",
      "distributed_to_hospital", "note", "recipient_confirmed", "amount_confirmed",
      "fiscal_year", "source_document_title", "state_source_url",
      "validation_source_type", "extraction_method", "validator",
      "ccn", "aha_id", "rural_designation", "reviewer",
      # Georgia-specific, appended
      "phase", "phase_date", "initiative_number", "initiative", "initiative_amount",
      "strategy", "recipient_count", "amount_basis", "flow_type",
      "hospital_benefiting", "determination_confidence", "determination_basis",
      "source_archive_path", "flag_reason",
      "rural_designation_raw", "recipient_names_source_url", "application_id"
    )
}

# --- reconciliation --------------------------------------------------------
#
# The only correct way to total Georgia. `amount` is recipient-level and mostly
# absent; the state's money is stated per initiative, so the total is the sum of
# distinct (phase, initiative) initiative_amount values.

rhtp_ga_reconcile <- function(records = rhtp_ga_records()) {
  by_initiative <- records %>%
    dplyr::distinct(.data$phase, .data$initiative_number, .data$initiative_amount) %>%
    dplyr::arrange(.data$phase, .data$initiative_number)

  awarded <- sum(by_initiative$initiative_amount)

  p2_distinct <- records %>%
    dplyr::filter(.data$phase == "2") %>%
    dplyr::distinct(.data$awardee) %>%
    nrow()

  tibble::tibble(
    line = c(
      "Georgia CMS FY2026 award",
      "GREAT Health Year 1 awarded (sum of initiative pools)",
      "Residual (administrative and programme costs)",
      "Residual as % of the CMS award",
      "Award actions in this table",
      "Distinct named organizations",
      "Hospital recipients - award actions",
      "Hospital recipients - hospitals covered",
      "Phase 2 distinct organizations enumerated",
      "Phase 2 distinct organizations per DCH",
      "Named-hospital dollars (rows whose own awardee is a hospital)",
      "  of which: 80 AHEAD hospitals at a stated $750,000",
      "  of which: 21 award actions on the two signed Notices of Award",
      "Unsuccessful applicants DCH names and this file does not code"
    ),
    value = c(
      GA_CMS_YEAR1_AWARD,
      awarded,
      GA_CMS_YEAR1_AWARD - awarded,
      round(100 * (GA_CMS_YEAR1_AWARD - awarded) / GA_CMS_YEAR1_AWARD, 2),
      nrow(records),
      records %>%
        dplyr::filter(.data$recipient_count == 1L) %>%
        dplyr::distinct(.data$awardee) %>%
        nrow(),
      records %>% dplyr::filter(.data$distributed_to_hospital == "Yes") %>% nrow(),
      records %>%
        dplyr::filter(.data$distributed_to_hospital == "Yes") %>%
        dplyr::pull("recipient_count") %>%
        sum(na.rm = TRUE),
      p2_distinct,
      GA_PHASE2_STATED_ORG_COUNT,
      sum(records$amount[records$distributed_to_hospital == "Yes"], na.rm = TRUE),
      GA_AHEAD_PHASE3_COUNT * GA_AHEAD_PER_HOSPITAL_AMOUNT,
      sum(GA_NOA_SOURCES$stated_total),
      sum(GA_NOA_SOURCES$stated_unsuccessful)
    ),
    note = c(
      "Stated in the footnote of all four DCH announcements",
      paste0("Phases 1-4; ", nrow(by_initiative), " initiative pools"),
      "DCH: 'less than 10% of Year 1's funding is dedicated to administrative costs'",
      "Independent closure on the DCH statement above",
      "One row per award action as DCH describes it",
      "Aggregate rows (multi-recipient cohorts) excluded from the count",
      "distributed_to_hospital = Yes",
      "87 AHEAD hospitals + 21 notice-of-award hospitals, every one named",
      "Names actually listed on the Phase 2 page (28 award actions; DBHDD twice)",
      "UNRECONCILED, off by one. The names on the page are what is coded.",
      paste0("NOT a total of what reached Georgia hospitals: the initiative ",
             "pools DCH never split sit outside it, in both directions"),
      "Session 10. Hand-coded HIGH, before §7's CCN rule was settled",
      paste0("Session 22, from the signed notices. MEDIUM per §7 -- named ",
             "hospital, primary source, no CCN match yet (blocker 5)"),
      paste0("5 on the robotics notice, 2 on the telepods notice, each with ",
             "DCH's reason. Not award actions; the count is asserted only")
    )
  )
}

# --- assertions ------------------------------------------------------------

rhtp_ga_assert <- function(records = rhtp_ga_records()) {
  fail <- function(...) stop("[GA] ", ..., call. = FALSE)

  # 1. Every categorical column validates against the §8 controlled vocabulary.
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "recipient_confirmed", "amount_confirmed", "extraction_method",
                "rural_designation", "validation_source_type")) {
    # validation_source_type draws on the §8 `source_doc_type` vocabulary; it
    # went unchecked while every Georgia row was an AGENCY_PRESS_RELEASE, and
    # the notices of award are the first rows that are not.
    allowed <- rhtp_vocabulary(
      if (identical(col, "validation_source_type")) "source_doc_type" else col)
    seen <- stats::na.omit(unique(records[[col]]))
    bad <- setdiff(seen, allowed)
    if (length(bad)) {
      fail("`", col, "` carries values outside the vocabulary: ",
           paste(bad, collapse = ", "))
    }
  }

  # 2. The initiative pools reconcile to the phase totals DCH published.
  #    Phases 1 and 2 are stated to $0.1M in the source, so they are compared at
  #    that precision; phases 3 and 4 are stated to the dollar.
  stated <- c("1" = 12730000, "2" = 30600000, "3" = 60487500, "4" = 93330827)
  got <- records %>%
    dplyr::distinct(.data$phase, .data$initiative_number, .data$initiative_amount) %>%
    dplyr::group_by(.data$phase) %>%
    dplyr::summarise(total = sum(.data$initiative_amount), .groups = "drop")
  for (i in seq_len(nrow(got))) {
    ph <- got$phase[i]
    if (abs(got$total[i] - stated[[ph]]) > 1) {
      fail("Phase ", ph, " initiative pools sum to ", format(got$total[i], big.mark = ","),
           " against a stated ", format(stated[[ph]], big.mark = ","))
    }
  }

  # 3. The awarded total leaves a residual under 10% of the CMS award, which is
  #    the independent check on DCH's own administrative-cost statement.
  awarded <- sum(got$total)
  residual_pct <- 100 * (GA_CMS_YEAR1_AWARD - awarded) / GA_CMS_YEAR1_AWARD
  if (residual_pct < 0 || residual_pct >= 10) {
    fail("Residual after Year 1 awards is ", round(residual_pct, 2),
         "% of the CMS award; DCH states administrative costs are under 10%.")
  }

  # 4. Georgia's CMS figure matches the §7.1 anchor. Tier 1 comes from CMS,
  #    never from a state press release (§0.2a) -- this is the cross-check.
  anchor <- readr::read_csv(
    here::here("data", "reference", "cms_fy2026_allotments.csv"),
    show_col_types = FALSE
  )
  ga_anchor <- anchor %>%
    dplyr::filter(dplyr::if_any(dplyr::everything(),
                                ~ .x %in% c("GA", "Georgia"))) %>%
    dplyr::select(dplyr::where(is.numeric)) %>%
    unlist() %>%
    unname()
  ga_anchor <- ga_anchor[ga_anchor > 1e6]
  if (length(ga_anchor) != 1 || abs(ga_anchor[1] - GA_CMS_YEAR1_AWARD) > 1) {
    fail("Georgia's CMS FY2026 allotment in the §7.1 anchor is ",
         paste(format(ga_anchor, big.mark = ","), collapse = "/"),
         " but the DCH announcements state ",
         format(GA_CMS_YEAR1_AWARD, big.mark = ","), ".")
  }

  # 5. NO AMOUNT IS EVER DIVIDED (§6.2). A row may only carry an `amount` when
  #    the state stated a recipient-level figure -- never a share of a pool.
  divided <- records %>%
    dplyr::filter(!is.na(.data$amount), .data$amount_basis == "NOT_PUBLISHED")
  if (nrow(divided)) {
    fail(nrow(divided), " row(s) carry an amount with amount_basis NOT_PUBLISHED. ",
         "A pooled initiative amount must never be split across its recipients.")
  }
  if (any(!is.na(records$amount) & records$amount_confirmed != "Yes")) {
    fail("A row carries an amount without amount_confirmed = Yes.")
  }

  # 6. Eligibility is never receipt (§0.3): no PASS_THROUGH_UNRESOLVED row may
  #    be coded Yes.
  imputed <- records %>%
    dplyr::filter(.data$flow_type == "PASS_THROUGH_UNRESOLVED",
                  .data$distributed_to_hospital == "Yes")
  if (nrow(imputed)) {
    fail(nrow(imputed), " unresolved pass-through row(s) coded Yes. §0.3 forbids it.")
  }

  # 7. IN_KIND_BENEFIT never counts as distribution, and always flags the
  #    benefit (§10.2).
  in_kind <- records %>% dplyr::filter(.data$flow_type == "IN_KIND_BENEFIT")
  if (any(in_kind$distributed_to_hospital != "No") ||
      any(in_kind$hospital_benefiting != "Yes")) {
    fail("An IN_KIND_BENEFIT row is not coded No / hospital_benefiting = Yes.")
  }

  # 8. Every row is evidence-backed: an archived local copy, and a mandatory
  #    free-text determination_basis (§0.4, §10.2).
  missing_archive <- records$source_archive_path %>%
    unique() %>%
    purrr::discard(~ file.exists(here::here(.x)))
  if (length(missing_archive)) {
    fail("Archived source missing from disk: ", paste(missing_archive, collapse = ", "))
  }
  if (!file.exists(here::here(GA_AHEAD_ROSTER_ARCHIVE))) {
    fail("The AHEAD roster archive is missing: ", GA_AHEAD_ROSTER_ARCHIVE,
         ". The 87 hospital names have no evidence behind them without it.")
  }
  if (any(is.na(records$determination_basis) |
          !nzchar(records$determination_basis))) {
    fail("determination_basis is mandatory and is empty on at least one row.")
  }

  # 9. The 87-hospital AHEAD group is accounted for exactly once, across the two
  #    phases that announce it, and is now 87 NAMED rows rather than 2 cohorts.
  #    Keyed on `strategy` rather than on the awardee text, because the awardee
  #    is a hospital name once ga_expand_ahead_cohorts() has run.
  ahead <- records %>%
    dplyr::filter(.data$strategy == "AHEAD Model pre-implementation funding")
  if (nrow(ahead) != GA_AHEAD_YEAR1_COUNT ||
      sum(ahead$recipient_count, na.rm = TRUE) != GA_AHEAD_YEAR1_COUNT) {
    fail("The AHEAD group is ", nrow(ahead), " rows covering ",
         sum(ahead$recipient_count, na.rm = TRUE), " hospitals; DCH states a ",
         "planned Year 1 group of ", GA_AHEAD_YEAR1_COUNT, ".")
  }
  if (dplyr::n_distinct(ahead$awardee) != GA_AHEAD_YEAR1_COUNT) {
    fail("The AHEAD group names ", dplyr::n_distinct(ahead$awardee),
         " distinct hospitals; a name is repeated.")
  }
  if (any(ahead$recipient_confirmed != "Yes")) {
    fail("An AHEAD hospital row is not recipient_confirmed = Yes, although the ",
         "roster names every one of them.")
  }

  # 9a. The phase split, and the money that rests on it. Exactly 80 hospitals
  #     carry the stated $750,000 and they close on the stated $60M pool to the
  #     dollar; the other 7 carry no amount and are flagged as inferred.
  stated <- ahead %>% dplyr::filter(!is.na(.data$amount))
  if (nrow(stated) != GA_AHEAD_PHASE3_COUNT ||
      any(stated$amount != GA_AHEAD_PER_HOSPITAL_AMOUNT) ||
      any(stated$phase != "3")) {
    fail(nrow(stated), " AHEAD hospitals carry a stated amount; DCH states the ",
         "$750,000 figure for the ", GA_AHEAD_PHASE3_COUNT, " Phase 3 hospitals only.")
  }
  if (sum(stated$amount) != 60000000) {
    fail("The Phase 3 AHEAD hospitals sum to ",
         format(sum(stated$amount), big.mark = ","),
         " against a stated Initiative 1 pool of 60,000,000.")
  }
  inferred <- ahead %>% dplyr::filter(is.na(.data$amount))
  if (nrow(inferred) != GA_AHEAD_YEAR1_COUNT - GA_AHEAD_PHASE3_COUNT ||
      any(inferred$flag_reason != "PHASE_ATTRIBUTION_INFERRED")) {
    fail("The Phase 4 AHEAD hospitals must carry no amount and the ",
         "PHASE_ATTRIBUTION_INFERRED flag; ", nrow(inferred), " row(s) do not.")
  }

  # 10. The enumerated Phase 2 organization count is pinned. It does not match
  #     DCH's own headline of 26 and is not expected to -- the point of pinning
  #     it is that if a later edit changes the enumeration, the change is
  #     deliberate and visible rather than quietly closing a gap that is real.
  p2 <- records %>% dplyr::filter(.data$phase == "2")
  if (nrow(p2) != 28L || dplyr::n_distinct(p2$awardee) != 27L) {
    fail("Phase 2 enumerates ", nrow(p2), " award actions across ",
         dplyr::n_distinct(p2$awardee), " organizations; the page as read gives ",
         "28 and 27 (against DCH's stated ", GA_PHASE2_STATED_ORG_COUNT, ").")
  }

  # 11. THE TWENTY-ONE NAMED HOSPITALS, AND THE INVARIANT THAT MAKES THE CHANGE
  #     SAFE: Georgia's total does not move. Every dollar on these rows was
  #     already inside the Initiative 3 and Initiative 5 pools, so this is a
  #     reclassification from pooled to named and nothing else. Pinned as a
  #     literal, because "the total is unchanged" is the claim a reader of this
  #     file most needs to be able to check without recomputing it.
  if (abs(awarded - GA_YEAR1_AWARDED) > 1) {
    fail("Year 1 awarded is ", format(awarded, big.mark = ","),
         " but Georgia's published total is ",
         format(GA_YEAR1_AWARDED, big.mark = ","),
         ". Naming the hospitals inside a pool must never change the total.")
  }

  noa <- records %>%
    dplyr::filter(.data$validation_source_type == "NOTICE_OF_AWARD")
  if (nrow(noa) != sum(GA_NOA_SOURCES$stated_actions)) {
    fail(nrow(noa), " rows cite a notice of award; the two signed notices name ",
         sum(GA_NOA_SOURCES$stated_actions), " award actions.")
  }
  if (any(records$flag_reason %in% "RECIPIENT_NAMES_NOT_CAPTURED")) {
    fail("A RECIPIENT_NAMES_NOT_CAPTURED row survives. Both Phase 4 cohorts ",
         "are named on signed notices of award and neither aggregate row ",
         "should remain.")
  }
  for (i in seq_len(nrow(GA_NOA_SOURCES))) {
    src <- GA_NOA_SOURCES[i, ]
    got <- noa %>% dplyr::filter(.data$strategy == src$strategy)
    if (nrow(got) != src$stated_actions ||
        abs(sum(got$amount) - src$stated_total) > 0.005) {
      fail(src$strategy, " is ", nrow(got), " rows summing to ",
           format(sum(got$amount), big.mark = ","), "; the notice of award ",
           "names ", src$stated_actions, " summing to ",
           format(src$stated_total, big.mark = ","), ".")
    }
    # The named awards must fit inside the initiative pool they are named from.
    # If they ever exceed it, either the pool figure or the parse is wrong, and
    # publishing either would overstate what Georgia awarded.
    pool <- unique(got$initiative_amount)
    if (length(pool) != 1L || sum(got$amount) > pool) {
      fail(src$strategy, " sums to ", format(sum(got$amount), big.mark = ","),
           " against an initiative pool of ",
           paste(format(pool, big.mark = ","), collapse = "/"), ".")
    }
    if (!file.exists(here::here(src$path))) {
      fail("The signed notice of award is missing: ", src$path)
    }
    if (!identical(digest::digest(file = here::here(src$path), algo = "sha256"),
                   src$recheck_sha256)) {
      fail(src$file, " on disk does not hash to the digest session 21 recorded ",
           "on 2026-08-29. Re-fetch it and re-read it before extracting.")
    }
    # DCH names its unsuccessful applicants too. Nothing codes them; the count
    # is asserted because the successful/unsuccessful split has to be right for
    # the successful rows to be right.
    n_unsuccessful <- ga_noa_unsuccessful_count(src$path)
    if (n_unsuccessful != src$stated_unsuccessful) {
      fail(src$file, " names ", n_unsuccessful, " unsuccessful applicants; ",
           src$stated_unsuccessful, " were read on 2026-08-29.")
    }
  }
  if (any(noa$recipient_confirmed != "Yes") ||
      any(noa$amount_confirmed != "Yes") ||
      any(noa$amount_basis != "STATED_PER_RECIPIENT") ||
      any(!is.na(noa$flag_reason))) {
    fail("A notice-of-award row is not a confirmed, per-recipient, unflagged ",
         "award. The notice names the recipient and states its amount.")
  }
  if (any(noa$determination_confidence != "MEDIUM")) {
    fail("A notice-of-award row is not MEDIUM. §7 reserves HIGH for a CCN ",
         "match and this repository has no CCN source yet (blocker 5).")
  }
  if (any(noa$recipient_type != "HOSPITAL_OR_SYSTEM") ||
      any(noa$flow_type != "DIRECT") ||
      any(noa$distributed_to_hospital != "Yes")) {
    fail("A notice-of-award row is not a direct award to a hospital.")
  }

  # 11a. The named-hospital figure this change exists to move. $60,000,000 was
  #      the 80 AHEAD hospitals alone; the notices add $30,277,580 that was
  #      already inside the pools.
  named <- sum(records$amount[records$distributed_to_hospital == "Yes"],
               na.rm = TRUE)
  if (abs(named - GA_NAMED_HOSPITAL_DOLLARS) > 1) {
    fail("Named-hospital dollars are ", format(named, big.mark = ","),
         " against an expected ",
         format(GA_NAMED_HOSPITAL_DOLLARS, big.mark = ","), ".")
  }

  invisible(TRUE)
}

# --- build -----------------------------------------------------------------

rhtp_ga_write <- function() {
  records <- rhtp_ga_records()
  rhtp_ga_assert(records)

  csv_path <- here::here("data", "reference", "ga_great_health_awards.csv")
  readr::write_csv(records, csv_path, na = "")

  hospitals <- records %>%
    dplyr::filter(.data$distributed_to_hospital == "Yes") %>%
    dplyr::select("phase", "initiative_number", "awardee", "recipient_count",
                  "amount", "recipient_confirmed", "flag_reason")

  by_type <- records %>%
    dplyr::count(.data$recipient_type, name = "award_actions") %>%
    dplyr::arrange(dplyr::desc(.data$award_actions))

  by_phase <- records %>%
    dplyr::distinct(.data$phase, .data$phase_date, .data$initiative_number,
                    .data$initiative, .data$initiative_amount) %>%
    dplyr::arrange(.data$phase, .data$initiative_number)

  wb <- openxlsx::createWorkbook()
  hdr <- openxlsx::createStyle(textDecoration = "bold", halign = "left")
  money <- openxlsx::createStyle(numFmt = "#,##0")

  add <- function(name, df, money_cols = character()) {
    openxlsx::addWorksheet(wb, name)
    openxlsx::writeData(wb, name, df, headerStyle = hdr)
    for (mc in intersect(money_cols, names(df))) {
      openxlsx::addStyle(wb, name, money, rows = 2:(nrow(df) + 1),
                         cols = which(names(df) == mc), gridExpand = TRUE)
    }
    openxlsx::freezePane(wb, name, firstActiveRow = 2)
    openxlsx::setColWidths(wb, name, cols = seq_along(df), widths = "auto")
  }

  add(paste0("Awardees (", nrow(records), ")"), records,
      c("amount", "initiative_amount"))
  add("Reconciliation", rhtp_ga_reconcile(records), "value")
  add("By phase and initiative", by_phase, "initiative_amount")
  add("By recipient type", by_type)
  add(paste0("Hospitals (", nrow(hospitals), ")"), hospitals, "amount")

  xlsx_path <- here::here("GA_year1_awardees.xlsx")
  openxlsx::saveWorkbook(wb, xlsx_path, overwrite = TRUE)

  message("[GA] wrote ", nrow(records), " award actions")
  message("[GA]   ", csv_path)
  message("[GA]   ", xlsx_path)
  invisible(list(csv = csv_path, xlsx = xlsx_path, records = records))
}

# --- CLI -------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) {
    print(rhtp_ga_noa_fetch(force = "--force" %in% args))
  } else if ("--build" %in% args) {
    rhtp_ga_write()
  } else if ("--validate" %in% args) {
    rhtp_ga_assert()
    recs <- rhtp_ga_records()
    message("[GA] ", nrow(recs), " award actions; all assertions pass.")
    print(rhtp_ga_reconcile(recs), n = Inf)
  } else {
    message("Usage: Rscript R/03d_ga_great_health.R [--fetch | --validate | --build]")
  }
}
