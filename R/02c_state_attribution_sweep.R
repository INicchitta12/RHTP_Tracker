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
  "1d474172-7a1f-4c6c-9d49-caf6aecb96b1", "MISFILED",
  # -- session 62, the 2026-09-24 pull. Every one opened and read. ----------
  # Wallowa Memorial Hospital is in Wallowa County, OREGON (the description
  # says "Eastern Oregon"). THE FIRST MISFILED TIER 3 RECORD.
  "4e3c2e97-6e50-4994-94e9-1caf781dc997", "MISFILED",
  "4babf0af-75fc-46dc-a44d-d8731f5520ae", "MISFILED",
  # South Dakota's $31.5M Rural Strong round, as an AWARDEE row, inside a
  # multi-state digest filed under Michigan. The second misfiled Tier 3 record,
  # and a pool rather than a recipient besides.
  "42b92bd8-03bc-459c-8e58-9a920022d44d", "MISFILED",
  # The same digest's document row: a round-up of many states.
  "05646180-67a2-4c3e-a3fb-23804b4ea2c0", "MULTI_STATE_DIGEST",
  # "South Dakota NOFO ..." filed under Michigan.
  "9b9a08dc-3ae8-4fdc-99c7-dcf1aa249d45", "MISFILED",
  # Governor Tate Reeves's MISSISSIPPI 167-award release, filed under Arkansas.
  "0b2d4ebd-6740-43d3-881d-870b5fa3b571", "MISFILED",
  # CMS's GEORGIA $93.3M release, filed under Arkansas.
  "8dfc67c9-12d7-466a-8751-8a08a2b23bf4", "MISFILED",
  # Senator Cotton on ARKANSAS's $150M, filed under Maine.
  "a5fd66ae-ead2-4851-ba22-86f45f695837", "MISFILED",
  # UTAH DHHS's Rural Health Connect newsletter, filed under North Dakota.
  "ec44a9cd-5c62-440e-a5be-55c456970599", "MISFILED",
  # "RFP 27-87793" is an INDIANA IDOA number (IDOA's 26-/27-nnnnn series);
  # RCJ's machine summary calls it "Florida's RFP". The record is Indiana's
  # and correctly filed; the SUMMARY names the wrong state (§6).
  "23c4c487-118d-4cfd-8bcd-a8ca794efacc", "SUMMARY_NAMES_WRONG_STATE"
)

# A DOCUMENT THAT IS WHOLLY ANOTHER STATE'S, read by hand. Every live record
# filed under `state` with this `source_doc_title` is that state's, INCLUDING
# the ones that name no state at all -- and those are exactly the ones a
# state-name sweep cannot see. Three of Wallowa's four Tier 3 rows ("Wallowa
# Memorial Hospital", "... - Rural Health Clinics", "... and Medical Clinics")
# name NO state, so without this list the sweep would report one misfiled
# Tier 3 award where there are four (session 62). Explicit rather than a rule,
# because a MULTI_STATE_DIGEST also carries records of the state it is filed
# under, and a rule keyed on "a MISFILED record came from this document" would
# drag those in.
# VERDICTS RETIRED BY THE CORPUS, not by a reader. Kept, with the reason,
# because deleting a verdict erases the evidence it once carried. On the
# 2026-09-24 pull RCJ RE-FILED four records it had misfiled -- three of
# Wyoming's five Utah documents and the Oklahoma-derived Utah webinars page
# are now filed under UTAH -- and withdrew Alaska's three Providence rows.
# The aggregator correcting itself is a finding too: session 42's Wyoming
# count (five) is now two.
SWEEP_RETIRED_VERDICTS <- tibble::tribble(
  ~record_id,                             ~verdict_was,                ~retired_because,
  "61cff8c5-8e30-4956-8883-1ccc1f549c05", "NAME_CONTAINS_A_STATE_NAME", "WITHDRAWN on 2026-09-24",
  "9781d248-f79e-4037-ae40-2f7370be6861", "NAME_CONTAINS_A_STATE_NAME", "WITHDRAWN on 2026-09-24",
  "d4e5b73d-8f1d-4a1c-977c-0e5ddd63b4f4", "NAME_CONTAINS_A_STATE_NAME", "WITHDRAWN on 2026-09-24",
  "08c60046-77e0-478f-b307-3fc08d8feaf2", "MISFILED", "RCJ re-filed WY -> UT on 2026-09-24",
  "c98bc19b-4c9f-40b9-a0e7-dca0004dbf7e", "MISFILED", "RCJ re-filed WY -> UT on 2026-09-24",
  "1d474172-7a1f-4c6c-9d49-caf6aecb96b1", "MISFILED", "RCJ re-filed WY -> UT on 2026-09-24",
  "f4cf50c6-8804-4f96-8ec1-380a0883420d", "MISFILED", "RCJ re-titled it a Utah document on 2026-09-24; no longer names only another state"
)

SWEEP_MISFILED_DOCUMENTS <- tibble::tribble(
  ~state, ~source_doc_title, ~actual_state,
  "NM", paste("NM - 2026 - Wallowa Memorial Hospital and Medical Clinics",
              "awarded over $5.4 million in federal RHT Funds"), "OR"
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
  ETHNONYM = "\"Alaska Native\" in a Census tribal-consultation handbook.",
  SUMMARY_NAMES_WRONG_STATE = paste(
    "The record is correctly filed; RCJ's MACHINE-GENERATED description names",
    "another state (§6: a summary field is never evidence)."),
  MISFILED_SAME_DOCUMENT = paste(
    "Names no state itself; its source document is hand-read as wholly",
    "another state's (SWEEP_MISFILED_DOCUMENTS). Invisible to the name test.")
)

sweep_records <- function() {
  rt <- rhtp_record_table_live()
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

  # Siblings of a hand-read wholly-foreign document that the name test missed.
  doc_key <- paste(rec$state, rec$source_doc_title, sep = "\r")
  in_doc <- doc_key %in% paste(SWEEP_MISFILED_DOCUMENTS$state,
                               SWEEP_MISFILED_DOCUMENTS$source_doc_title,
                               sep = "\r")
  if (!all(paste(SWEEP_MISFILED_DOCUMENTS$state,
                 SWEEP_MISFILED_DOCUMENTS$source_doc_title, sep = "\r") %in%
           doc_key)) {
    stop("[SWEEP] a SWEEP_MISFILED_DOCUMENTS entry matches no live record; ",
         "the corpus has moved -- re-read it.", call. = FALSE)
  }
  sib <- in_doc & !(rec$record_id %in% out$record_id)
  if (any(sib)) {
    act <- SWEEP_MISFILED_DOCUMENTS$actual_state[match(
      doc_key[sib], paste(SWEEP_MISFILED_DOCUMENTS$state,
                          SWEEP_MISFILED_DOCUMENTS$source_doc_title, sep = "\r"))]
    out <- dplyr::bind_rows(out, tibble::tibble(
      filed_under = rec$state[sib],
      foreign_states_named = act,
      award_tier = rec$award_tier[sib],
      amount_announced = rec$amount_announced[sib],
      awardee_name_clean = rec$awardee_name_clean[sib],
      source_doc_title = rec$source_doc_title[sib],
      record_id = rec$record_id[sib],
      misattributed = TRUE,
      verdict = "MISFILED_SAME_DOCUMENT"))
  }
  unread <- out$record_id[is.na(out$verdict)]
  if (length(unread)) {
    stop("[SWEEP] ", length(unread), " flagged record(s) have no hand-read ",
         "verdict: ", paste(unread, collapse = ", "), ". The sweep FLAGS and a ",
         "HUMAN READS -- open each one and add it to SWEEP_VERDICTS rather ",
         "than widening the exclusion list until the output is empty.",
         call. = FALSE)
  }
  back <- intersect(SWEEP_RETIRED_VERDICTS$record_id, out$record_id)
  if (length(back)) {
    stop("[SWEEP] retired verdict(s) are flagged again: ",
         paste(back, collapse = ", "), ". Re-read and move them back.",
         call. = FALSE)
  }
  stale <- setdiff(setdiff(SWEEP_VERDICTS$record_id,
                           SWEEP_RETIRED_VERDICTS$record_id), out$record_id)
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
SWEEP_MISFILED_STATES <- c("AR", "ME", "MI", "MO", "ND", "NM", "WA", "WY")

# SESSION 62: THE WRONG-STATE DEFECT HAS REACHED TIER 3, and these are the
# records that carry it. Sessions 42-61 asserted there were NONE; the 09-24
# pull breaks that, which is the event that assertion existed to catch. It is
# now PINNED BY RECORD rather than asserted empty: a sixth misfiled Tier 3
# record fails the build, and so does one of these leaving. Four are Oregon's
# Wallowa Memorial Hospital under NEW MEXICO; one is SOUTH DAKOTA's $31.5M
# Rural Strong round under MICHIGAN. Neither NM (no award file; a negative)
# nor MI (built from MDHHS's roster, not RCJ) has consumed any of them, and
# each state's RCJ disposition now names them.
SWEEP_MISFILED_TIER3 <- c(
  "4e3c2e97-6e50-4994-94e9-1caf781dc997",  # NM <- OR, Wallowa County HCD
  "2622ee3b-8cfd-43be-acfc-2d57e98b9449",  # NM <- OR, Wallowa Memorial MRI
  "6a645ede-3fd1-456c-896a-12db2877106c",  # NM <- OR, Wallowa RHCs
  "a4539590-daf9-4fd8-b3d0-740884605147",  # NM <- OR, Wallowa $5,464,316
  "42b92bd8-03bc-459c-8e58-9a920022d44d"   # MI <- SD, Rural Strong $31.5M
)
sweep_assert <- function(flagged = sweep_build()) {
  mis <- flagged[flagged$verdict %in% c("MISFILED", "MISFILED_SAME_DOCUMENT"), ,
                 drop = FALSE]
  t3 <- sort(mis$record_id[mis$award_tier == "SUBAWARD"])
  if (!identical(t3, sort(SWEEP_MISFILED_TIER3))) {
    stop("[SWEEP] the misfiled Tier 3 set moved: now ",
         paste(t3, collapse = ", "), ". Tier 3 is the tier an extractor ",
         "reads. Read every one, and check the filed state's disposition, ",
         "before touching a state file.", call. = FALSE)
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

  mis <- flagged[flagged$verdict %in% c("MISFILED", "MISFILED_SAME_DOCUMENT"), ]
  cat(sprintf("\n  %d RECORDS ARE ANOTHER STATE'S, IN %d STATES:\n", nrow(mis),
              dplyr::n_distinct(mis$filed_under)))
  for (i in seq_len(nrow(mis))) {
    cat(sprintf("    %-3s <- %-3s  %-12s %s\n", mis$filed_under[i],
                mis$foreign_states_named[i], mis$award_tier[i],
                substr(mis$source_doc_title[i], 1, 78)))
  }
  t3m <- mis[mis$award_tier == "SUBAWARD", ]
  cat(sprintf("\n  %d OF THEM ARE TIER 3 -- THE FIRST TIME THE DEFECT HAS REACHED THE\n",
              nrow(t3m)))
  cat("  TIER AN EXTRACTOR READS (session 62, the 2026-09-24 pull). Four are\n")
  cat("  Oregon's Wallowa Memorial under New Mexico, THREE OF WHICH NAME NO STATE\n")
  cat("  AT ALL and are caught only through SWEEP_MISFILED_DOCUMENTS; one is\n")
  cat("  South Dakota's Rural Strong round under Michigan. No award file here\n")
  cat("  consumed any of them: New Mexico has no award file, and Michigan's is\n")
  cat("  built from MDHHS's roster.\n")
  cat(sprintf("\n  RCJ ALSO CORRECTED ITSELF: %d earlier verdicts were retired by the\n",
              nrow(SWEEP_RETIRED_VERDICTS)))
  cat("  corpus (four re-filed to Utah, three Alaska rows withdrawn).\n")

  t3 <- flagged[flagged$award_tier == "SUBAWARD" &
                  !flagged$verdict %in% c("MISFILED", "MISFILED_SAME_DOCUMENT"), ]
  cat(sprintf("\n  THE OTHER %d TIER 3 FLAGS ARE FALSE POSITIVES, EACH LEGIBLE:\n",
              nrow(t3)))
  for (i in seq_len(nrow(t3))) {
    cat(sprintf("    %-3s <- %-3s  %-27s %s\n", t3$filed_under[i],
                t3$foreign_states_named[i], t3$verdict[i],
                substr(dplyr::coalesce(t3$awardee_name_clean[i], ""), 1, 40)))
  }
  cat("\n  Which is why this file FLAGS and a human READS (§0.4).\n")
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
