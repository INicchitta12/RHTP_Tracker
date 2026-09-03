#!/usr/bin/env Rscript
# 02c_state_attribution_sweep.R ----------------------------------------------
#
# §0.1 FAILURE MODE 6 -- THE RECORD IS FILED UNDER THE WRONG STATE.
#
# Every §0.1 defect this project had recorded before Wyoming is a defect IN a
# record: the wrong programme, the wrong tier, the wrong kind of action, the
# wrong grain, the wrong section. Wyoming's is a defect in WHICH STATE THE
# RECORD IS. Five of RCJ's 29 Wyoming records are UTAH'S documents -- including
# "Utah RHTP Cooperative Agreement Award: $195.7 million for Year 1", UTAH'S OWN
# ALLOTMENT, carried as an `UNASSIGNED` WYOMING row at $195,700,000 against
# Wyoming's $205,004,743.
#
# It was harmless in Wyoming ONLY because none of the five is Tier 3. This file
# is what says whether it is harmless anywhere else, and it is a MEASUREMENT
# rather than an assumption: it reads the committed record table and asks, of
# every record, whether the only US state it names is a state OTHER than the one
# RCJ filed it under.
#
# HOW IT DECIDES, AND WHY IT IS DELIBERATELY BLUNT.
#   * Longest-match state names, so "West Virginia" is never read as "Virginia"
#     (session 14's lesson, one layer down).
#   * A record is FLAGGED only when a foreign state is named and the record's
#     OWN state is named NOWHERE in its title, description, awardee or
#     solicitation number. A document that names both is ordinary -- a state
#     comparing itself to a neighbour, a multi-state vendor, a national
#     programme -- and is not evidence of misfiling.
#   * Constructions where a state NAME is not a state are excluded by an
#     explicit, visible list (`WY_NOT_A_STATE`): "Washington County",
#     "Washington, D.C.", "Kansas City", "New York Life", "Indiana University"
#     and so on. THE LIST IS HAND-READ AND SHORT ON PURPOSE. A longer one would
#     start suppressing real findings, and the output of this file is meant to
#     be READ, not trusted (§0.4).
#
# WHAT IT IS NOT. It is not a filter and nothing downstream consumes it. No
# record is re-stated, re-tiered or moved. It answers one question -- is any
# EXTRACTED state's candidate set contaminated by another state's records? --
# and the answer is written to
# `data/reference/rcj_state_attribution_sweep.csv` for a human.
#
# Usage:
#   Rscript R/02c_state_attribution_sweep.R --build
#   Rscript R/02c_state_attribution_sweep.R --report

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))

SWEEP_OUT_CSV <- here::here("data", "reference",
                            "rcj_state_attribution_sweep.csv")

# Constructions in which a US state NAME is not a reference to that state.
# Hand-read, visible, and deliberately short: every entry suppresses a real
# match, so a long list would start hiding findings.
SWEEP_NOT_A_STATE <- c(
  "Washington, D.C.", "Washington D.C.", "Washington DC",
  "Washington University", "George Washington",
  "Kansas City", "New York Life", "Indiana University",
  "Virginia Beach", "Jefferson City"
)

# A COUNTY IS NOT A STATE, and this is the exclusion that actually matters.
# Alabama, Pennsylvania, Florida, Ohio, Oregon and a dozen others have a
# Washington County; Pennsylvania and West Virginia have a Wyoming County;
# Indiana, Iowa and Kansas have a Washington and a Jefferson. Without this, the
# sweep's ONLY Tier 3 findings are counties, which would make it look as though
# every extracted state's candidate set were contaminated when none is.
# Generated from the §7.1 vocabulary rather than typed, so it cannot go stale.
sweep_county_forms <- function() {
  nm <- rhtp_cms_states()$state_name
  as.vector(outer(nm, c(" County", " Parish", " Township", " City"), paste0))
}

#' The states each record NAMES, longest match first
#'
#' Longest match first is the whole of the correctness here: "…Across West
#' Virginia" contains "Virginia", and a first-match reader files West Virginia's
#' documents under VA (session 14 met exactly this in the CMS newsroom).
sweep_states_named <- function(text) {
  vocab <- rhtp_cms_states()
  names_by_len <- vocab$state_name[order(nchar(vocab$state_name),
                                         decreasing = TRUE)]
  codes <- vocab$state[order(nchar(vocab$state_name), decreasing = TRUE)]

  # HOISTED OUT OF THE LOOP DELIBERATELY. `sweep_county_forms()` reads the §7.1
  # vocabulary off disk, and this runs over 5,056 records: computing it inside
  # the closure re-read the CSV five thousand times (session 24's lesson --
  # measure the hot spot, do not reason about it).
  exclusions <- c(SWEEP_NOT_A_STATE, sweep_county_forms())

  vapply(text, function(s) {
    if (is.na(s) || !nzchar(s)) return("")
    for (ex in exclusions) {
      s <- gsub(ex, " ", s, fixed = TRUE)
    }
    hits <- character(0)
    for (i in seq_along(names_by_len)) {
      pat <- paste0("\\b", names_by_len[i], "\\b")
      if (grepl(pat, s)) {
        hits <- c(hits, codes[i])
        s <- gsub(pat, " ", s)          # consume it, so the longer name wins
      }
    }
    paste(sort(unique(hits)), collapse = ";")
  }, character(1), USE.NAMES = FALSE)
}

# -- THE HAND-READ VERDICTS ---------------------------------------------------
#
# The sweep FLAGS; a human READS. Every flagged record was opened and coded here
# by hand, and the codes are the point of the file:
#
#   MISFILED                   the record is another state's, whole. Wyoming's
#                              five Utah documents, North Dakota's two Arkansas
#                              ones, Washington's Florida one, Utah's Oklahoma
#                              one, Missouri's Michigan one.
#   MULTI_STATE_DIGEST         a national round-up naming several states and
#                              filed under each. Not misfiled; not a subaward
#                              either.
#   NAME_CONTAINS_A_STATE_NAME the state name is inside the RECIPIENT'S OWN
#                              legal name -- "Providence Health & Services-
#                              Washington", a real ALASKA awardee.
#   COUNTY_WITHOUT_THE_WORD    a bare county name in a county list: Alabama's
#                              "(Clarke, Washington)". The generic
#                              "<State> County" exclusion cannot reach it.
#   STREET_ADDRESS             "905 Washington Street".
#   ETHNONYM                   "Alaska Native".
#
# EVERY TIER 3 FLAG IS A FALSE POSITIVE, AND THAT IS THE FINDING. Tier 3 is the
# only tier an extractor reads, so the wrong-state defect has not reached a
# single award file in this repository -- measured across all 5,056 committed
# records, not assumed.
SWEEP_VERDICTS <- tibble::tribble(
  ~record_id,                             ~verdict,
  "61cff8c5-8e30-4956-8883-1ccc1f549c05", "NAME_CONTAINS_A_STATE_NAME",
  "9781d248-f79e-4037-ae40-2f7370be6861", "NAME_CONTAINS_A_STATE_NAME",
  "d4e5b73d-8f1d-4a1c-977c-0e5ddd63b4f4", "NAME_CONTAINS_A_STATE_NAME",
  "433cfe02-58ef-4e84-afe1-31289cd5cc41", "COUNTY_WITHOUT_THE_WORD",
  "dbd1a5b3-faca-4655-b6ba-4ce72ec0e0ba", "COUNTY_WITHOUT_THE_WORD",
  "7805f79e-f93c-43c5-be6f-1d5e12dfbda9", "COUNTY_WITHOUT_THE_WORD",
  "f9428b95-815a-4150-8b4e-d17063d101f3", "COUNTY_WITHOUT_THE_WORD",
  "2cb57b93-01af-444d-a5f4-944b367bb6af", "ETHNONYM",
  "af2cdc8b-c03b-422d-8c0e-3e7e6d6b722c", "COUNTY_WITHOUT_THE_WORD",
  "ea68853d-ffc2-409b-abc2-8b622925a03f", "COUNTY_WITHOUT_THE_WORD",
  "a9ac0be5-58de-42b2-8006-12f1f8e88204", "MULTI_STATE_DIGEST",
  "d5b4606f-fa5b-4efa-8362-443a520e64b2", "MISFILED",
  "b93cc474-010a-447d-85ad-c8bfef3e5b6c", "MISFILED",
  "80a88042-37ac-4207-b2ff-ab33a7dfe710", "MISFILED",
  "79801c3b-106a-4d7f-a54a-4f2380163c44", "STREET_ADDRESS",
  "f4cf50c6-8804-4f96-8ec1-380a0883420d", "MISFILED",
  "29d2148e-f719-45f0-9055-7a8f7628c668", "MISFILED",
  "0d0c37db-7b0d-47c8-8c85-bc531077f40a", "MULTI_STATE_DIGEST",
  "c98bc19b-4c9f-40b9-a0e7-dca0004dbf7e", "MISFILED",
  "08c60046-77e0-478f-b307-3fc08d8feaf2", "MISFILED",
  "58e871aa-51aa-46bf-9c8c-27269a330832", "MISFILED",
  "3e70da1b-5839-44f5-b815-bf645fe11402", "MISFILED",
  "1d474172-7a1f-4c6c-9d49-caf6aecb96b1", "MISFILED"
)

# The hand-read note behind the verdicts that move something.
SWEEP_NOTES <- c(
  MISFILED = paste(
    "Another state's document, filed under this one. Read the source_doc_title",
    "and the description together: the title's state prefix is RCJ's filing and",
    "the description names the state the document is actually about."),
  MULTI_STATE_DIGEST = paste(
    "A national RHTP round-up naming several states, filed under each. Not a",
    "misfiling and not a subaward."),
  NAME_CONTAINS_A_STATE_NAME = paste(
    "The state name is inside the RECIPIENT'S OWN legal name -- Providence",
    "Health & Services-Washington is a real Alaska awardee and is in",
    "ak_year1_awardees.csv. A flag, not a finding."),
  COUNTY_WITHOUT_THE_WORD = paste(
    "A bare county name in a county list -- Alabama's \"(Clarke, Washington)\".",
    "The generic \"<State> County\" exclusion cannot reach it, and widening the",
    "rule to bare county names would start suppressing real findings."),
  STREET_ADDRESS = "A street address -- \"905 Washington Street\".",
  ETHNONYM = "\"Alaska Native\" in a Census tribal-consultation handbook."
)

sweep_records <- function() {
  rt <- readRDS(here::here("data", "interim", "stage2_record_table.rds"))
  rt %>%
    dplyr::filter(is.na(.data$superseded_by) | .data$superseded_by == "",
                  !is.na(.data$state), .data$state %in% rhtp_cms_states()$state)
}

#' Every record whose only named state is NOT the state RCJ filed it under
sweep_build <- function() {
  rec <- sweep_records()
  blob <- paste(dplyr::coalesce(rec$source_doc_title, ""),
                dplyr::coalesce(rec$program_description, ""),
                dplyr::coalesce(rec$awardee_name_raw, ""),
                dplyr::coalesce(rec$solicitation_number, ""))
  named <- sweep_states_named(blob)

  own_named <- purrr::map2_lgl(named, rec$state, function(n, st) {
    st %in% strsplit(n, ";")[[1]]
  })
  foreign <- purrr::map2_chr(named, rec$state, function(n, st) {
    paste(setdiff(strsplit(n, ";")[[1]], c("", st)), collapse = ";")
  })

  flagged <- !own_named & nzchar(foreign)

  out <- tibble::tibble(
    filed_under = rec$state,
    foreign_states_named = foreign,
    award_tier = rec$award_tier,
    amount_announced = rec$amount_announced,
    awardee_name_clean = rec$awardee_name_clean,
    source_doc_title = rec$source_doc_title,
    record_id = rec$record_id,
    misattributed = flagged
  )
  out <- out[out$misattributed, , drop = FALSE]
  out$verdict <- SWEEP_VERDICTS$verdict[match(out$record_id, SWEEP_VERDICTS$record_id)]
  unread <- out$record_id[is.na(out$verdict)]
  if (length(unread)) {
    stop("[SWEEP] ", length(unread), " flagged record(s) have no hand-read ",
         "verdict: ", paste(unread, collapse = ", "), ". The sweep FLAGS and a ",
         "HUMAN READS -- open each one and add it to SWEEP_VERDICTS rather ",
         "than widening the exclusion list until the output is empty.",
         call. = FALSE)
  }
  stale <- setdiff(SWEEP_VERDICTS$record_id, out$record_id)
  if (length(stale)) {
    stop("[SWEEP] ", length(stale), " hand-read verdict(s) no longer match a ",
         "flagged record: ", paste(stale, collapse = ", "), ". The corpus has ",
         "moved; re-read before deleting anything.", call. = FALSE)
  }
  out$note <- unname(SWEEP_NOTES[out$verdict])
  out %>%
    dplyr::arrange(.data$verdict, .data$filed_under,
                   dplyr::desc(.data$award_tier), .data$source_doc_title)
}

#' Per state: how many records, how many misfiled, and how many of THOSE are
#' Tier 3 -- because Tier 3 is the only tier an extractor reads.
sweep_by_state <- function(flagged = sweep_build()) {
  rec <- sweep_records()
  totals <- rec %>%
    dplyr::count(state, name = "rcj_records") %>%
    dplyr::left_join(rec %>% dplyr::filter(.data$award_tier == "SUBAWARD") %>%
                       dplyr::count(state, name = "tier3_candidates"),
                     by = "state")
  f <- flagged %>%
    dplyr::group_by(state = .data$filed_under) %>%
    dplyr::summarise(
      misattributed = dplyr::n(),
      misattributed_tier3 = sum(.data$award_tier == "SUBAWARD"),
      foreign_states = paste(sort(unique(unlist(
        strsplit(.data$foreign_states_named, ";")))), collapse = ";"),
      .groups = "drop")
  totals %>%
    dplyr::left_join(f, by = "state") %>%
    dplyr::mutate(
      tier3_candidates = dplyr::coalesce(.data$tier3_candidates, 0L),
      misattributed = dplyr::coalesce(.data$misattributed, 0L),
      misattributed_tier3 = dplyr::coalesce(.data$misattributed_tier3, 0L),
      foreign_states = dplyr::coalesce(.data$foreign_states, "")) %>%
    dplyr::arrange(dplyr::desc(.data$misattributed))
}

sweep_write <- function() {
  flagged <- sweep_build()
  readr::write_csv(flagged, SWEEP_OUT_CSV, na = "")
  message("[SWEEP] wrote ", SWEEP_OUT_CSV, " (", nrow(flagged), " rows)")
  invisible(flagged)
}

#' THE FINDING: THE DEFECT IS REAL IN FIVE STATES AND HAS REACHED NO AWARD FILE
#'
#' Designed to fail if either half stops being true.
SWEEP_MISFILED_STATES <- c("MO", "ND", "UT", "WA", "WY")
sweep_assert <- function(flagged = sweep_build()) {
  mis <- flagged[flagged$verdict == "MISFILED", , drop = FALSE]
  if (any(mis$award_tier == "SUBAWARD")) {
    stop("[SWEEP] a MISFILED record is now Tier 3. Until now the wrong-state ",
         "defect had never reached the tier an extractor reads, and that is ",
         "the whole finding. Read every one before touching a state file.",
         call. = FALSE)
  }
  got <- sort(unique(mis$filed_under))
  if (!identical(got, SWEEP_MISFILED_STATES)) {
    stop("[SWEEP] the misfiled set is now ", paste(got, collapse = ", "),
         ", not ", paste(SWEEP_MISFILED_STATES, collapse = ", "), ".",
         call. = FALSE)
  }
  invisible(mis)
}

sweep_report <- function() {
  flagged <- sweep_build()
  per <- sweep_by_state(flagged)
  rec <- sweep_records()
  cat("\n§0.1 FAILURE MODE 6 -- THE RECORD IS FILED UNDER THE WRONG STATE\n")
  cat(strrep("-", 78), "\n")
  cat(sprintf("  %d of %d committed RCJ records name a US state OTHER than the one\n",
              nrow(flagged), nrow(rec)))
  cat("  they are filed under, and name their own state NOWHERE. Each was read\n")
  cat("  by hand:\n\n")
  v <- flagged %>% dplyr::count(.data$verdict, name = "n") %>%
    dplyr::arrange(dplyr::desc(.data$n))
  for (i in seq_len(nrow(v))) {
    t3 <- sum(flagged$verdict == v$verdict[i] & flagged$award_tier == "SUBAWARD")
    cat(sprintf("    %-28s %2d  (%d Tier 3)\n", v$verdict[i], v$n[i], t3))
  }

  mis <- flagged[flagged$verdict == "MISFILED", ]
  cat(sprintf("\n  %d RECORDS ARE ANOTHER STATE'S, IN %d STATES:\n", nrow(mis),
              dplyr::n_distinct(mis$filed_under)))
  for (i in seq_len(nrow(mis))) {
    cat(sprintf("    %-3s <- %-3s  %-12s %s\n", mis$filed_under[i],
                mis$foreign_states_named[i], mis$award_tier[i],
                substr(mis$source_doc_title[i], 1, 78)))
  }
  cat("\n  WYOMING IS THE LARGEST AND UTAH IS ITS MIRROR: Wyoming's set holds\n")
  cat("  five UTAH documents (one of them Utah's own $195.7M allotment) and\n")
  cat("  Utah's holds an OKLAHOMA one.\n")

  cat("\n  AND NOT ONE MISFILED RECORD IS TIER 3.\n")
  cat("  Tier 3 is the only tier an extractor reads, so the wrong-state defect\n")
  cat("  has NOT reached a single award file in this repository. That is a\n")
  cat("  measurement of the corpus as pulled on 2026-08-27, and never a\n")
  cat("  property of the aggregator (§0.1).\n")

  t3 <- flagged[flagged$award_tier == "SUBAWARD", ]
  cat(sprintf("\n  THE %d TIER 3 FLAGS ARE ALL FALSE POSITIVES, AND EACH IS LEGIBLE:\n",
              nrow(t3)))
  for (i in seq_len(nrow(t3))) {
    cat(sprintf("    %-3s <- %-3s  %-27s %s\n", t3$filed_under[i],
                t3$foreign_states_named[i], t3$verdict[i],
                substr(dplyr::coalesce(t3$awardee_name_clean[i], ""), 1, 40)))
  }
  cat("\n  Which is why this file FLAGS and a human READS. Widening the\n")
  cat("  exclusion list until the output is empty would suppress the ten real\n")
  cat("  ones along with the eight false (§0.4).\n")
  invisible(list(flagged = flagged, per_state = per))
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--build" %in% args) {
    sweep_write()
  } else if ("--report" %in% args) {
    sweep_report()
  } else {
    cat("usage: Rscript R/02c_state_attribution_sweep.R [--build | --report]\n")
  }
}
