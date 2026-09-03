# 00b_state_trigger_queue.R --------------------------------------------------
# The state queue -> data/reference/state_trigger_queue.csv
#
# A state enters the queue if EITHER discovery layer flags it, and the file
# records WHICH one did.
#
# WHY THIS IS A SEPARATE STAGE. R/00 answers "which states has CMS announced?"
# and it answers it well. The defect was never in R/00; it was in treating
# R/00's answer as the list of states worth looking at. CMS issues a press
# release when CMS decides to, and Illinois -- $50,008,264 to ICAHN, executed
# 2026-07-31, a quarter of its allotment -- got no release and therefore no
# attention through fifteen sessions of state hunting.
#
# So R/00 keeps its job and this file does the union. That split matters for a
# practical reason as well as a conceptual one: R/00 runs live twice a week on
# a Routine and fetches two hosts; this stage touches no network at all and
# reads two committed CSVs, so it can be re-run at any time, by anyone,
# offline, and it cannot break the monitor it consumes.
#
# NEITHER SOURCE IS A CENSUS, AND THE FILE SAYS SO ON EVERY ROW. That is the
# whole lesson and it survives only if it is written where somebody reading a
# row will meet it:
#
#   * CMS announces when CMS chooses to. Nine states. Illinois is not one.
#   * RCJ is a commercial aggregator (§0.1) whose coverage is complete in some
#     states and absent in others.
#
# WHAT THE UNION ACTUALLY DOES FOR ILLINOIS, STATED HONESTLY. It queues it --
# but not for the right reason, and the distinction is worth keeping. Illinois
# has exactly ONE surviving RCJ Tier 3 candidate: `MyOwnDoctor, LLC` at $1, a
# 2025 Medicaid preventive-care contract that is not RHTP at all. That is
# enough to put Illinois in the queue as RCJ_ONLY, which is a real improvement
# over a CMS-only list that omitted it entirely. But it ranks Illinois near the
# BOTTOM of the queue on a $1 signal, and the $50,008,264 ICAHN award is
# invisible to both layers. So the union widens the net; it does not make the
# net fine enough to have caught this award on its merits.
#
# FLORIDA IS THE UNMIXED CASE, and it is why the NEITHER bucket carries a
# warning rather than a conclusion: no CMS release, no surviving RCJ Tier 3
# candidate, and 81 extracted awards sitting in this repository already.
# `queue_status = NOT_TRIGGERED` therefore means "no discovery layer flagged
# this state", and it NEVER means "this state has awarded nothing". An
# assertion requires at least one EXTRACTED state to remain in that bucket, so
# the sentence cannot quietly rot into a claim of completeness.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only -- never |>. No setwd(); all
# paths go through here::here(). No network calls, no quota.
#
# CLI:
#   Rscript R/00b_state_trigger_queue.R --build     # write the queue
#   Rscript R/00b_state_trigger_queue.R --validate  # assertions, no writes
#   Rscript R/00b_state_trigger_queue.R --status    # what the queue says

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))

QUEUE_CSV        <- "data/reference/state_trigger_queue.csv"
QUEUE_CMS_CSV    <- "data/reference/cms_state_announcements.csv"
QUEUE_SURVEY_CSV <- "data/reference/rcj_state_survey.csv"


# -- Build -------------------------------------------------------------------

#' Union the two discovery layers into one queue
#'
#' @param prior_path Existing queue, for carrying `first_queued` forward.
rhtp_trigger_queue <- function(prior_path = QUEUE_CSV) {
  for (f in c(QUEUE_CMS_CSV, QUEUE_SURVEY_CSV)) {
    if (!file.exists(here::here(f))) {
      stop(
        "Missing '", f, "'.\n",
        "  CMS list : Rscript R/00_cms_press_monitor.R --run\n",
        "  RCJ survey: Rscript R/03k_rcj_state_survey.R --build",
        call. = FALSE
      )
    }
  }

  cms <- readr::read_csv(here::here(QUEUE_CMS_CSV), show_col_types = FALSE,
                         progress = FALSE) %>%
    dplyr::transmute(
      state,
      cms_announced_date = as.character(date),
      cms_release_url    = url,
      cms_source         = source
    ) %>%
    dplyr::distinct(state, .keep_all = TRUE) %>%
    dplyr::mutate(in_cms = TRUE)

  survey <- readr::read_csv(here::here(QUEUE_SURVEY_CSV),
                            show_col_types = FALSE, progress = FALSE) %>%
    dplyr::select(state, state_name, rcj_tier3_candidates = tier3_candidates,
                  rcj_distinct_awardees = distinct_awardees,
                  rcj_federal_amount_sum, extraction_status,
                  cms_fy2026_allotment)

  queue <- survey %>%
    dplyr::left_join(cms, by = "state") %>%
    dplyr::mutate(
      in_cms = dplyr::coalesce(in_cms, FALSE),
      in_rcj = rcj_tier3_candidates > 0,

      trigger_source = dplyr::case_when(
        in_cms &  in_rcj ~ "BOTH",
        in_cms & !in_rcj ~ "CMS_ONLY",
        !in_cms & in_rcj ~ "RCJ_ONLY",
        TRUE             ~ "NEITHER"
      ),

      # EXTRACTED wins over the trigger state: a state this project has
      # already extracted is not waiting in a queue, however it was found --
      # and two of the eight were found by neither layer.
      queue_status = dplyr::case_when(
        extraction_status == "EXTRACTED" ~ "EXTRACTED",
        # A state that has been worked and publishes no list leaves the queue
        # too -- there is no work available on it today. It is NOT EXTRACTED
        # (no award file exists) and it is NOT QUEUED (looking again today
        # returns the same negative). Its own probe re-opens it. Session 19,
        # Texas.
        extraction_status == "INVESTIGATED_NO_LIST" ~ "INVESTIGATED_NO_LIST",
        # Worked, written down, and NOT re-checkable: no probe exists, so
        # nothing re-opens the state on its own. It leaves QUEUED because
        # re-investigating it would repeat work already done, and it is
        # deliberately NOT INVESTIGATED_NO_LIST, which promises a tripwire
        # these six do not have. Session 43.
        extraction_status == "INVESTIGATED_NO_PROBE" ~ "INVESTIGATED_NO_PROBE",
        trigger_source == "NEITHER"      ~ "NOT_TRIGGERED",
        TRUE                             ~ "QUEUED"
      )
    )

  # `first_queued` is the date a state first entered the queue, carried
  # forward across runs. Without it the file can only ever say what is true
  # today, and "which states appeared since we last looked" -- the actual
  # question a trigger list exists to answer -- becomes unanswerable.
  first_queued <- if (file.exists(here::here(prior_path))) {
    readr::read_csv(here::here(prior_path), show_col_types = FALSE,
                    progress = FALSE) %>%
      dplyr::select(state, prior_first_queued = first_queued)
  } else {
    tibble::tibble(state = character(), prior_first_queued = character())
  }

  queue %>%
    dplyr::left_join(first_queued, by = "state") %>%
    dplyr::mutate(
      first_queued = dplyr::if_else(
        queue_status == "NOT_TRIGGERED",
        NA_character_,
        dplyr::coalesce(as.character(prior_first_queued),
                        as.character(Sys.Date()))
      )
    ) %>%
    dplyr::arrange(
      match(queue_status, c("QUEUED", "EXTRACTED", "NOT_TRIGGERED")),
      dplyr::desc(rcj_tier3_candidates),
      state
    ) %>%
    dplyr::mutate(queue_rank = dplyr::row_number()) %>%
    dplyr::select(
      queue_rank, state, state_name, trigger_source, queue_status,
      rcj_tier3_candidates, rcj_distinct_awardees, rcj_federal_amount_sum,
      cms_announced_date, cms_source, cms_release_url,
      cms_fy2026_allotment, extraction_status, first_queued
    )
}


# -- Assertions --------------------------------------------------------------

rhtp_trigger_queue_assert <- function(queue = NULL) {
  if (is.null(queue)) queue <- rhtp_trigger_queue()

  states <- rhtp_cms_states()
  stopifnot(nrow(queue) == 50L)
  stopifnot(setequal(queue$state, states$state))
  stopifnot(!any(duplicated(queue$state)))
  stopifnot(all(queue$trigger_source %in%
                  rhtp_vocabulary("trigger_source")))
  stopifnot(all(queue$queue_status %in% rhtp_vocabulary("queue_status")))
  stopifnot(identical(queue$queue_rank, seq_len(nrow(queue))))

  # -- THE UNION IS A SUPERSET OF EACH SOURCE -------------------------------
  # The property the whole stage exists for. If either input could name a
  # state the queue does not, the union would be narrower than a source it is
  # supposed to widen -- and that is precisely the failure R/00 had.
  cms <- readr::read_csv(here::here(QUEUE_CMS_CSV), show_col_types = FALSE,
                         progress = FALSE)
  survey <- readr::read_csv(here::here(QUEUE_SURVEY_CSV),
                            show_col_types = FALSE, progress = FALSE)

  triggered <- queue$state[queue$trigger_source != "NEITHER"]

  missing_cms <- setdiff(unique(cms$state), triggered)
  if (length(missing_cms) > 0) {
    stop("States CMS announced that the queue does not carry: ",
         paste(missing_cms, collapse = ", "), call. = FALSE)
  }

  rcj_states <- survey$state[survey$tier3_candidates > 0]
  missing_rcj <- setdiff(rcj_states, triggered)
  if (length(missing_rcj) > 0) {
    stop("States with RCJ Tier 3 candidates that the queue does not carry: ",
         paste(missing_rcj, collapse = ", "), call. = FALSE)
  }

  # -- THE UNION IS STRICTLY WIDER THAN CMS ALONE ---------------------------
  # If this ever stops being true, either RCJ has gone silent or somebody has
  # quietly reduced the union back to one source. Both are worth failing on.
  if (length(triggered) <= length(unique(cms$state))) {
    stop(
      "The union (", length(triggered), " states) is no wider than the CMS ",
      "list alone (", length(unique(cms$state)), "). The second trigger is ",
      "contributing nothing -- check R/03k's survey before trusting this.",
      call. = FALSE
    )
  }

  # -- NOT_TRIGGERED DOES NOT MEAN "NO AWARDS" ------------------------------
  # Pinned as an assertion rather than a comment, because it is the single
  # claim this file most needs a reader to believe, and the evidence for it is
  # sitting in the repository: Illinois and Florida are both extracted states
  # that NEITHER discovery layer flags.
  untriggered_but_extracted <- queue %>%
    dplyr::filter(trigger_source == "NEITHER",
                  extraction_status == "EXTRACTED")

  if (nrow(untriggered_but_extracted) == 0) {
    stop(
      "No extracted state sits in the NEITHER bucket any more. That bucket's ",
      "whole warning -- that neither discovery layer is a census -- rested on ",
      "Illinois and Florida being in it. Re-check before relaxing the ",
      "warning in this file's header.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}


# -- Report ------------------------------------------------------------------

rhtp_trigger_queue_status <- function(queue = NULL) {
  if (is.null(queue)) queue <- rhtp_trigger_queue()

  message("")
  message("STATE TRIGGER QUEUE -- union of CMS announcements and RCJ Tier 3")
  message(strrep("-", 78))
  print(as.data.frame(queue %>% dplyr::count(trigger_source, queue_status)),
        row.names = FALSE)
  message("")
  message("QUEUED, in priority order:")
  print(
    as.data.frame(
      queue %>%
        dplyr::filter(queue_status == "QUEUED") %>%
        dplyr::select(queue_rank, state, trigger_source,
                      rcj_tier3_candidates, rcj_distinct_awardees,
                      cms_announced_date)
    ),
    row.names = FALSE
  )
  message("")
  message("NOT_TRIGGERED but ALREADY EXTRACTED -- neither layer found these:")
  print(
    as.data.frame(
      queue %>%
        dplyr::filter(trigger_source == "NEITHER",
                      extraction_status == "EXTRACTED") %>%
        dplyr::select(state, state_name, trigger_source, extraction_status)
    ),
    row.names = FALSE
  )
  message("")
  message("Read that last block as the file's warning, not as trivia: those")
  message("states were EXTRACTED and NEITHER discovery layer flagged them.")
  message("NOT_TRIGGERED means nothing flagged the state. It never means the")
  message("state has awarded nothing.")
  message("")
  message("And note Illinois: queued RCJ_ONLY on a $1 non-RHTP record, near")
  message("the bottom. The union caught it; the union did not catch its $50M.")

  invisible(queue)
}


rhtp_trigger_queue_write <- function() {
  queue <- rhtp_trigger_queue()
  rhtp_trigger_queue_assert(queue)
  readr::write_csv(queue, here::here(QUEUE_CSV), na = "")

  message("[queue] wrote 50 states -> ", QUEUE_CSV)
  message("[queue]   ", sum(queue$trigger_source == "BOTH"), " BOTH  ",
          sum(queue$trigger_source == "CMS_ONLY"), " CMS_ONLY  ",
          sum(queue$trigger_source == "RCJ_ONLY"), " RCJ_ONLY  ",
          sum(queue$trigger_source == "NEITHER"), " NEITHER")
  message("[queue]   ", sum(queue$queue_status == "QUEUED"),
          " queued for investigation")

  invisible(queue)
}


# -- CLI ---------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--build" %in% args) {
    q <- rhtp_trigger_queue_write()
    rhtp_trigger_queue_status(q)
  } else if ("--validate" %in% args) {
    rhtp_trigger_queue_assert()
    message("[queue] all assertions pass.")
  } else if ("--status" %in% args) {
    rhtp_trigger_queue_status()
  } else {
    message("Usage: Rscript R/00b_state_trigger_queue.R [--build | --validate | --status]")
  }
}
