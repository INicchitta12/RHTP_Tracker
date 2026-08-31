# 03k_rcj_state_survey.R -----------------------------------------------------
# A 50-state RCJ coverage survey -> data/reference/rcj_state_survey.csv
#
# WHY THIS FILE EXISTS. Every state hunt this project has run -- sessions 9
# through 15, seven states extracted -- started from
# `data/reference/cms_state_announcements.csv`, the stage 00 trigger list. That
# list is the union of two CMS sources and it holds nine states. It is a
# TRIGGER LIST, NOT A CENSUS: it can only ever name a state that CMS chose to
# write a press release about, and CMS does not write one for every state that
# awards money.
#
# Illinois is the proof. It executed three grant agreements with the Illinois
# Critical Access Hospital Network on 2026-07-31 -- $50,008,264, a quarter of
# its FY2026 allotment -- and CMS issued no press release. So Illinois never
# entered the queue, and no session has ever looked at it. The gap was not in
# the states we searched; it was in the list of states we thought to search.
#
# This file is the second lens. It asks the committed RCJ pull the same
# question of ALL FIFTY states at once: where does RCJ hold award-shaped
# records that survived the §6.1 tier rules and the §6.2 junk filters? A state
# with Tier 3 candidates has, on RCJ's reading, awarded money to somebody --
# whether or not CMS announced it.
#
# §0.1 GOVERNS EVERY NUMBER IN THE OUTPUT. RCJ is a discovery layer. These
# counts say WHERE TO LOOK and nothing else. In particular:
#
#   * `rcj_federal_amount_sum` IS NOT A DOLLAR FIGURE. It is the sum of an
#     unvalidated aggregator field over records nobody has tied to a state
#     primary source. It is in the file so that a state holding one $1 record
#     can be told apart from a state holding $160M of them -- a coverage
#     signal, at the same grain as the count beside it. It must never be
#     published, summed across states, or compared to an allotment.
#     rhtp_survey_assert() re-states that; the column NAME says it too.
#   * A candidate count is not an award count and a state's absence is not
#     evidence it awarded nothing. Illinois is exactly that case: it has ONE
#     Tier 3 candidate, a $1 2025 Medicaid contract that is not RHTP at all,
#     and it awarded $50M. RCJ missing a state is the failure mode this survey
#     shares with the CMS list, which is why the two are unioned (R/00b) and
#     never substituted for one another.
#
# WHAT COUNTS AS A CANDIDATE. Tier 3 (`SUBAWARD`) records that the §6.2 filters
# did not quarantine -- i.e. `qa_status` of PASS or FLAGGED. FLAGGED is
# deliberately included and this is the single most consequential choice in the
# file. Alaska's 159 Tier 3 records are ALL flagged, every one of them
# `SOURCE_DOCUMENT_UNRESOLVED`, which means "this /awards record carried no
# sourceDocument.id" -- a provenance gap, not junk. Session 12 extracted all
# 161 of those awards from the state's own workbook and they are real. A
# PASS-only survey would report Alaska as having zero candidates and would have
# hidden the fourth-largest state in the file. QUARANTINED records are excluded
# and counted separately, because that is what the junk filters are for.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only -- never |>. No setwd(); all
# paths go through here::here(). Contains no network calls and spends no quota.
#
# CLI:
#   Rscript R/03k_rcj_state_survey.R --validate  # assertions only, no writes
#   Rscript R/03k_rcj_state_survey.R --build     # assert, then write the CSV
#   Rscript R/03k_rcj_state_survey.R --report    # the ranked table, to console

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))
# For rhtp_read_endpoint(), rhtp_pluck_chr() and rhtp_load_allotments(). The
# survey must read the landing zone through exactly the readers Stage 2 uses,
# or the cross-check compares two different readings of the same file.
source(here::here("R", "02_normalize.R"))

SURVEY_RECORD_TABLE <- "data/interim/stage2_record_table.rds"
SURVEY_CSV          <- "data/reference/rcj_state_survey.csv"
SURVEY_CMS_LIST     <- "data/reference/cms_state_announcements.csv"

# The states whose recipient-level awards this project has already extracted.
# Kept here rather than derived by globbing data/reference/, because a glob
# would silently start reporting a state as extracted the moment somebody
# committed a stub file for it.
SURVEY_EXTRACTED_STATES <- c("AK", "AL", "FL", "GA", "IL", "IN", "KS", "MD",
                             "NE", "NV", "OK", "OR", "PA", "SD")

# The states that HAVE been worked and publish no recipient-level list.
#
# WHY THIS IS NOT THE SAME AS NOT_EXTRACTED. Texas is the case that forced it.
# It led this queue on every measure the file carries -- rank 1, 68 Tier 3
# candidates, the largest allotment in the country -- was investigated against
# its own sources in session 19, and turned out to be at solicitation stage
# with all 68 candidates disqualified. Left as NOT_EXTRACTED it would rank 1
# again on the next run and be re-investigated from scratch, which is how a
# project eventually gets a completed negative wrong. Each state here has a
# committed evidence archive and a probe carrying a tripwire that re-opens it
# the day the state publishes (R/03n for Texas), so this is a re-checkable
# finding and not an assumption.
#
# IT IS NEVER A CLAIM THAT THE STATE AWARDED NOTHING (§0.1, §0.3).
SURVEY_INVESTIGATED_NO_LIST_STATES <- c("TX")


# -- Inputs ------------------------------------------------------------------

#' Load the committed Stage 2 record table, with a provenance guard
#'
#' The record table is the §6.1/§6.2 product of `data/raw/rcj/`, built by
#' `Rscript R/02_normalize.R --run` and committed. This survey reads it rather
#' than re-deriving the tiering, so that the survey and the rest of the
#' pipeline can never disagree about which records are Tier 3.
#'
#' The guard is the point: a record table describes exactly one pull, and if
#' that pull is not on disk then the survey is describing raw data this
#' repository does not have. That is the §0.5 failure -- a derived artifact
#' outliving its source -- and it fails loudly here instead of silently
#' producing a survey nobody can reproduce.
rhtp_survey_record_table <- function(path = SURVEY_RECORD_TABLE) {
  full <- here::here(path)

  if (!file.exists(full)) {
    stop(
      "No Stage 2 record table at '", path, "'.\n",
      "Build it first: Rscript R/02_normalize.R --run",
      call. = FALSE
    )
  }

  records <- readRDS(full)

  # WHICH PULL DOES THIS TABLE DESCRIBE? `pull_date` is the column that is
  # supposed to say, and on the currently committed table it is NA on all
  # 5,152 rows -- a dplyr data-masking self-assignment in
  # rhtp_normalize_pull() that resolved to the skeleton's own empty column.
  # That is fixed at the source in R/02_normalize.R, but the fix only takes
  # effect on the next Stage 2 run, and re-running Stage 2 to satisfy a survey
  # would rewrite committed artifacts for a reason unrelated to their content.
  #
  # So the resolution falls back to `last_seen`, which change detection sets
  # from the same argument and which IS populated. The fallback is NOT
  # silent -- it reports which column answered, because a survey that quietly
  # guessed its own provenance would be the exact defect it is guarding
  # against.
  pull_dates <- unique(as.character(records$pull_date))
  pull_dates <- pull_dates[!is.na(pull_dates)]
  pull_date_basis <- "pull_date"

  if (length(pull_dates) == 0) {
    pull_dates <- unique(as.character(records$last_seen))
    pull_dates <- pull_dates[!is.na(pull_dates)]
    pull_date_basis <- "last_seen (pull_date column empty)"
  }

  if (length(pull_dates) == 0) {
    stop(
      "The record table carries neither a pull_date nor a last_seen, so the ",
      "survey cannot establish which pull it describes and cannot cross-check ",
      "it against data/raw/rcj/. Rebuild Stage 2: Rscript R/02_normalize.R --run",
      call. = FALSE
    )
  }

  for (pd in pull_dates) {
    dir <- rhtp_path("raw_rcj", pd)
    if (!dir.exists(dir)) {
      stop(
        "The record table describes the ", pd, " pull, but ",
        "data/raw/rcj/", pd, "/ is not on disk.\n",
        "The survey would be describing raw data this repository does not ",
        "have (§0.5). Restore the pull or rebuild Stage 2.",
        call. = FALSE
      )
    }
  }

  attr(records, "pull_dates") <- pull_dates
  attr(records, "pull_date_basis") <- pull_date_basis
  records
}


#' Raw /awards record count per state, straight from the landing zone
#'
#' The cross-check. `rhtp_survey_record_table()` reads a DERIVED artifact; this
#' reads `data/raw/rcj/<pull>/awards.json` itself. If normalization ever drops
#' a state's records on the floor -- a parse failure, a truncated read, a
#' filter that catches more than it should -- the survey would report that
#' state as quiet and nothing else in the pipeline would notice. Comparing the
#' two makes the loss visible.
#'
#' Only /awards is cross-checked, because Tier 3 comes only from /awards: rule
#' 2 requires a populated `awardeeName` and no other endpoint's normalizer sets
#' one. rhtp_survey_assert() verifies that claim against the data rather than
#' trusting this comment.
rhtp_survey_raw_award_counts <- function(pull_date) {
  read <- rhtp_read_endpoint(pull_date, "awards")

  states <- purrr::map_chr(read$records, function(r) {
    rhtp_pluck_chr(r, "state")
  })

  tibble::tibble(state = states) %>%
    dplyr::filter(!is.na(state), nzchar(state)) %>%
    dplyr::count(state, name = "rcj_awards_records_raw")
}


#' The CMS trigger list, as a lookup
rhtp_survey_cms_list <- function(path = SURVEY_CMS_LIST) {
  full <- here::here(path)

  if (!file.exists(full)) {
    stop(
      "No CMS announcement list at '", path, "'.\n",
      "Build it first: Rscript R/00_cms_press_monitor.R --run",
      call. = FALSE
    )
  }

  readr::read_csv(full, show_col_types = FALSE, progress = FALSE) %>%
    dplyr::transmute(
      state,
      cms_announced_date = as.character(date),
      cms_source         = source,
      cms_release_url    = url
    ) %>%
    dplyr::distinct(state, .keep_all = TRUE)
}


# -- The survey --------------------------------------------------------------

#' Build the 50-state RCJ coverage survey
#'
#' One row per state in the §7.1 fifty, including the states holding nothing --
#' a survey that dropped its zeroes would be a list of findings rather than a
#' map of coverage, and the zeroes are half of what it is for.
#'
#' @param records Optional pre-loaded record table, for testing.
#' @return A tibble, ranked by tier3_candidates descending.
rhtp_rcj_state_survey <- function(records = NULL) {
  if (is.null(records)) {
    records <- rhtp_survey_record_table()
  }

  states     <- rhtp_cms_states()
  allotments <- rhtp_load_allotments()
  cms_list   <- rhtp_survey_cms_list()

  tier3 <- records %>%
    dplyr::filter(award_tier == "SUBAWARD")

  # PASS + FLAGGED. See the header: FLAGGED is included on purpose, and
  # Alaska's 159 SOURCE_DOCUMENT_UNRESOLVED rows are why.
  candidates <- tier3 %>%
    dplyr::filter(qa_status %in% c("PASS", "FLAGGED"))

  per_state <- candidates %>%
    dplyr::group_by(state) %>%
    dplyr::summarise(
      tier3_candidates = dplyr::n(),
      tier3_pass       = sum(qa_status == "PASS"),
      tier3_flagged    = sum(qa_status == "FLAGGED"),
      distinct_awardees = dplyr::n_distinct(
        awardee_name_clean[!is.na(awardee_name_clean) &
                             nzchar(awardee_name_clean)]
      ),
      # NOT A DOLLAR FIGURE (§0.1). A coverage signal at the same grain as the
      # count beside it. `federalAmount` is what /awards calls this field and
      # rhtp_normalize_awards() maps it to amount_announced unchanged.
      rcj_federal_amount_sum = sum(amount_announced, na.rm = TRUE),
      rcj_amount_max         = suppressWarnings(
        max(amount_announced, na.rm = TRUE)
      ),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      rcj_amount_max = dplyr::if_else(is.finite(rcj_amount_max),
                                      rcj_amount_max, NA_real_)
    )

  quarantined <- tier3 %>%
    dplyr::filter(qa_status == "QUARANTINED") %>%
    dplyr::count(state, name = "tier3_quarantined")

  pull_dates <- attr(records, "pull_dates")
  if (is.null(pull_dates)) pull_dates <- character()

  raw_counts <- purrr::map_dfr(pull_dates, rhtp_survey_raw_award_counts)

  raw_counts <- if (nrow(raw_counts) == 0) {
    tibble::tibble(state = character(), rcj_awards_records_raw = integer())
  } else {
    raw_counts %>%
      dplyr::group_by(state) %>%
      dplyr::summarise(rcj_awards_records_raw = sum(rcj_awards_records_raw),
                       .groups = "drop")
  }

  survey <- states %>%
    dplyr::select(state, state_name) %>%
    dplyr::left_join(per_state, by = "state") %>%
    dplyr::left_join(quarantined, by = "state") %>%
    dplyr::left_join(raw_counts, by = "state") %>%
    dplyr::left_join(cms_list, by = "state") %>%
    dplyr::left_join(
      allotments %>%
        dplyr::select(state, cms_fy2026_allotment = fy2026_allotment),
      by = "state"
    ) %>%
    dplyr::mutate(
      dplyr::across(
        c(tier3_candidates, tier3_pass, tier3_flagged, tier3_quarantined,
          distinct_awardees, rcj_awards_records_raw),
        ~ dplyr::coalesce(as.integer(.x), 0L)
      ),
      rcj_federal_amount_sum = dplyr::coalesce(rcj_federal_amount_sum, 0),
      in_cms_announcements = dplyr::if_else(is.na(cms_announced_date),
                                            "No", "Yes"),
      extraction_status = dplyr::case_when(
        state %in% SURVEY_EXTRACTED_STATES            ~ "EXTRACTED",
        state %in% SURVEY_INVESTIGATED_NO_LIST_STATES ~ "INVESTIGATED_NO_LIST",
        TRUE                                          ~ "NOT_EXTRACTED"
      ),

      # The four-way split this file exists to produce. RCJ_ONLY is the answer
      # to the question that was asked: a state RCJ says has awarded to a named
      # recipient, that CMS never announced, and that therefore no session has
      # ever looked at.
      survey_status = dplyr::case_when(
        tier3_candidates > 0 & in_cms_announcements == "Yes" ~ "RCJ_AND_CMS",
        tier3_candidates > 0 & in_cms_announcements == "No"  ~ "RCJ_ONLY",
        tier3_candidates == 0 & in_cms_announcements == "Yes" ~ "CMS_ONLY",
        TRUE ~ "NEITHER"
      ),

      # The flag the task asks for, kept as its own column so a reader
      # filtering the file does not have to know which survey_status values
      # imply "nobody has looked at this". A state already extracted is not
      # uninvestigated even if it is RCJ_ONLY.
      investigate = dplyr::if_else(
        survey_status == "RCJ_ONLY" & extraction_status == "NOT_EXTRACTED",
        "Yes", "No"
      )
    ) %>%
    dplyr::arrange(
      dplyr::desc(tier3_candidates),
      dplyr::desc(rcj_federal_amount_sum),
      state
    ) %>%
    dplyr::mutate(rank = dplyr::row_number()) %>%
    dplyr::select(
      rank, state, state_name,
      tier3_candidates, tier3_pass, tier3_flagged, tier3_quarantined,
      distinct_awardees,
      rcj_federal_amount_sum, rcj_amount_max,
      rcj_awards_records_raw,
      in_cms_announcements, cms_announced_date, cms_source, cms_release_url,
      cms_fy2026_allotment,
      extraction_status, survey_status, investigate
    )

  survey
}


# -- Assertions --------------------------------------------------------------

#' Assert the survey's structure and the claims its header makes
rhtp_survey_assert <- function(survey = NULL, records = NULL) {
  if (is.null(records)) records <- rhtp_survey_record_table()
  if (is.null(survey))  survey  <- rhtp_rcj_state_survey(records)

  states <- rhtp_cms_states()

  # -- All fifty, no more, no fewer -----------------------------------------
  stopifnot(nrow(survey) == 50L)
  stopifnot(setequal(survey$state, states$state))
  stopifnot(!any(duplicated(survey$state)))

  # -- Tier 3 comes only from /awards ---------------------------------------
  # The header claims it; this checks it. If a future normalizer starts
  # populating awardee_name_raw on /documents, the raw cross-check below stops
  # being a complete comparison and this fails rather than going quiet.
  t3_endpoints <- unique(records$source_endpoint[records$award_tier == "SUBAWARD"])
  if (!identical(sort(t3_endpoints), "awards")) {
    stop(
      "Tier 3 records now come from endpoints other than /awards (",
      paste(sort(t3_endpoints), collapse = ", "), "). The raw cross-check in ",
      "rhtp_survey_raw_award_counts() only reads awards.json and is no longer ",
      "complete. Widen it before trusting this survey.",
      call. = FALSE
    )
  }

  # -- Nothing lost between raw and normalized ------------------------------
  # Candidates + quarantined must never exceed what the landing zone holds.
  # This is the check that catches a state going quiet because normalization
  # dropped it, rather than because the state awarded nothing.
  over <- survey %>%
    dplyr::filter(tier3_candidates + tier3_quarantined > rcj_awards_records_raw)

  if (nrow(over) > 0) {
    stop(
      "More Tier 3 records than raw /awards records for: ",
      paste(over$state, collapse = ", "),
      ". The record table and data/raw/rcj/ disagree.",
      call. = FALSE
    )
  }

  # -- Controlled vocabularies (§5) -----------------------------------------
  stopifnot(all(survey$in_cms_announcements %in% c("Yes", "No")))
  stopifnot(all(survey$investigate %in% c("Yes", "No")))
  stopifnot(all(survey$extraction_status %in%
                  rhtp_vocabulary("extraction_status")))
  stopifnot(all(survey$survey_status %in%
                  rhtp_vocabulary("survey_status")))

  # -- Ranking -------------------------------------------------------------
  stopifnot(identical(survey$rank, seq_len(nrow(survey))))
  stopifnot(!is.unsorted(rev(survey$tier3_candidates)))

  # -- Internal arithmetic --------------------------------------------------
  stopifnot(all(survey$tier3_pass + survey$tier3_flagged ==
                  survey$tier3_candidates))
  stopifnot(all(survey$distinct_awardees <= survey$tier3_candidates))

  # -- §0.1: the amount column is never treated as a total ------------------
  # There is deliberately no national total anywhere in this file or its
  # report. Asserting the absence of a number is awkward, so what is asserted
  # instead is that the column is named so that summing it reads as wrong, and
  # that no row's sum has been silently compared to that state's allotment.
  stopifnot("rcj_federal_amount_sum" %in% names(survey))
  stopifnot(!any(stringr::str_detect(names(survey), "^total_|_total$")))

  # -- The CMS list is a subset of the union, never the whole of it ---------
  cms_states <- survey$state[survey$in_cms_announcements == "Yes"]
  stopifnot(length(cms_states) >= 1L)

  invisible(TRUE)
}


# -- Report ------------------------------------------------------------------

#' Print the survey the way a reader needs to see it
rhtp_survey_report <- function(survey = NULL) {
  if (is.null(survey)) survey <- rhtp_rcj_state_survey()

  active <- survey %>% dplyr::filter(tier3_candidates > 0)
  new    <- survey %>% dplyr::filter(investigate == "Yes")

  message("")
  message("RCJ 50-STATE COVERAGE SURVEY (§0.1 discovery signal, not findings)")
  message(strrep("-", 78))
  message("States with Tier 3 candidates : ", nrow(active), " of 50")
  message("States in the CMS trigger list: ",
          sum(survey$in_cms_announcements == "Yes"), " of 50")
  message("Union of the two              : ",
          sum(survey$tier3_candidates > 0 | survey$in_cms_announcements == "Yes"),
          " of 50")
  message("NOT investigated (RCJ_ONLY)   : ", nrow(new))
  message("")

  print(
    active %>%
      dplyr::select(rank, state, tier3_candidates, distinct_awardees,
                    rcj_federal_amount_sum, in_cms_announcements,
                    extraction_status, survey_status, investigate) %>%
      as.data.frame(),
    row.names = FALSE
  )

  message("")
  message("FLAGGED -- Tier 3 candidates, no CMS release, never investigated:")
  message(strrep("-", 78))
  print(
    new %>%
      dplyr::select(state, state_name, tier3_candidates, distinct_awardees,
                    rcj_federal_amount_sum, cms_fy2026_allotment) %>%
      as.data.frame(),
    row.names = FALSE
  )
  message("")
  message("Reminder (§0.1): rcj_federal_amount_sum is an UNVALIDATED aggregator")
  message("field. It ranks states by how much RCJ thinks is there. It is not a")
  message("dollar figure and must not be published or summed across states.")

  invisible(survey)
}


# -- Write -------------------------------------------------------------------

rhtp_survey_write <- function() {
  records <- rhtp_survey_record_table()
  survey  <- rhtp_rcj_state_survey(records)
  rhtp_survey_assert(survey, records)

  readr::write_csv(survey, here::here(SURVEY_CSV), na = "")

  message("[survey] wrote ", nrow(survey), " states -> ", SURVEY_CSV)
  message("[survey]   ", sum(survey$tier3_candidates > 0),
          " states hold Tier 3 candidates")
  message("[survey]   ", sum(survey$investigate == "Yes"),
          " flagged: candidates, no CMS release, never investigated")

  invisible(survey)
}


# --- CLI --------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--build" %in% args) {
    s <- rhtp_survey_write()
    rhtp_survey_report(s)
  } else if ("--validate" %in% args) {
    rhtp_survey_assert()
    message("[survey] all assertions pass.")
  } else if ("--report" %in% args) {
    rhtp_survey_report()
  } else {
    message("Usage: Rscript R/03k_rcj_state_survey.R [--validate | --build | --report]")
  }
}
