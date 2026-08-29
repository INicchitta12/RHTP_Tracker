# 02b_provenance_sweep.R ------------------------------------------------------
# The §6.2 provenance filter, extended to STATE-funded programmes, swept across
# every committed RCJ Tier 3 candidate in all 50 states.
#
# WHY THIS FILE EXISTS. §6.2's provenance filter has always tested one thing:
# does the source document tie to a non-RHTP FEDERAL programme -- HRSA, USDA
# Rural Development, FCC/USAC, Flex, SORH? That filter was written from Stage
# 0's Delaware finding (four rows sourced from a HRSA Rural Health Grants fact
# sheet) and it works.
#
# Session 19 found the half it does not cover, and the half is bigger. Texas
# holds 68 Tier 3 candidates. NOT ONE is an RHTP award. Fifty-three are real,
# executed, recipient-level HHSC notices of award naming rural Texas hospitals
# -- 21 at $250,000 under RFA HHS0015180, 32 of 33 at $350,000 under HHS0015677
# -- paid from money the 88th Texas Legislature appropriated in House Bill 1,
# Article II Rider 88. Right agency, right format, right recipients, real
# money, and none of it RHTP. An extractor written from that candidate list
# would have produced a clean, plausible, fully sourced TX_year1_awardees.xlsx
# carrying $16,800,000 of STATE money as RHTP.
#
# The federal filter cannot see them, because nothing about them is federal.
#
# WHAT THIS SWEEP IS FOR. It is a correctness pass over the whole corpus, not a
# Texas fix. Texas is the case that exposed the gap; the question this file
# answers is how many OTHER rows, in how many other states, the extended filter
# catches -- and, just as much, how many it cannot reach and why.
#
# THREE TESTS, AND THE THIRD IS THE ONE THE TASK ASKED FOR.
#
#   1. PROVENANCE_STATE_PROGRAM (registry). A verified row in
#      data/reference/non_rhtp_state_programs.csv matched on the state's own
#      solicitation identifier. Hand-verified against the state document,
#      carrying the disqualifying sentence and the archived evidence.
#
#   2. PROVENANCE_STATE_PROGRAM (text markers). Named non-RHTP state funding
#      streams that brand themselves in a document title -- opioid or tobacco
#      settlement money, Medicaid managed care, intergovernmental transfers.
#      Source-scoped, exactly like the federal markers.
#
#   3. PROVENANCE_PREDATES_NOA. An award action the source dates BEFORE that
#      state's CMS Notice of Award cannot be an RHTP subaward: RHTP money moves
#      CMS -> state -> subrecipient (§0.2), and a state cannot subaward money it
#      has not been given. CMS issued all 50 notices on 2025-12-29.
#
# WHAT THE SWEEP FOUND OUT ABOUT ITS OWN THIRD TEST, WHICH IS THE FINDING.
# RCJ publishes NO award-action date. /awards records carry ten fields and not
# one of them is a date; the record table's date_announced is populated on
# 3,639 rows and on none of the 1,372 Tier 3 ones. So the date test runs on
# dates mined out of the source document's own title, and on the currently
# committed pull it can resolve a date for a small minority of candidates. That
# is a bound on the DATA, not on the rule, and the sweep reports it per state
# rather than reporting a clean corpus it never actually dated.
#
# AND ONE REFUSAL THAT IS WORTH MORE THAN THE CATCHES. RCJ prefixes every
# source-document title with a year -- "TX - 2025 - ...". It reads exactly like
# a date. Keyed on it, this filter would quarantine 145 rows including all 66
# of Pennsylvania's committed Year 1 awards and all 33 of Maryland's Pillar 2
# rows, and it would look like it was working. The prefix is stripped before
# any date is mined and is never used as a date (§0.1).
#
# This sweep READS the committed record table and does NOT rewrite it. The new
# flags are wired into R/02_normalize.R so Stage 2 applies them on its next
# run; rewriting stage2_record_table.rds to publish a sweep would be the change
# session 16 declined to make for the same reason.
#
# THAT THE TWO AGREE IS VERIFIED, NOT ASSERTED IN A COMMENT. Stage 2 was run
# once with the wired-in filters against the committed pull and its output
# compared to this sweep's: Stage 2 flagged 73 Tier 3 records, the sweep caught
# 73, and the record_id sets are identical. The rebuilt interim artifacts were
# then reverted, so the committed record table is unchanged and the next
# Stage 2 run is what applies the filter to it.
#
# THE FALSE-POSITIVE CHECK IS AN ASSERTION, NOT A SPOT CHECK. Every caught row
# is compared against the 879 award rows in the nine committed state files --
# hand-extracted from state primary sources, so independent of RCJ. Overlap is
# zero, and rhtp_provenance_sweep_assert() hard-fails if it ever stops being.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))
# For the filter functions themselves. The sweep must apply exactly the code
# Stage 2 applies, or the two disagree about the same records.
source(here::here("R", "02_normalize.R"))

SWEEP_RECORD_TABLE <- "data/interim/stage2_record_table.rds"
SWEEP_BY_STATE     <- "data/reference/provenance_sweep_by_state.csv"
SWEEP_ROWS         <- "data/reference/provenance_sweep_flagged_rows.csv"
SWEEP_NOA_DATES    <- "data/reference/cms_state_noa_dates.csv"

# The CMS release that awarded all 50 states, as archived by stage 00.
NOA_RELEASE_SLUG <- "cms-announces-50-billion-awards-strengthen-rural-health-all-50-states"
NOA_RELEASE_FILE <- file.path(
  "data/raw/cms/2026-08-28/newsroom/releases",
  paste0(NOA_RELEASE_SLUG, ".html")
)

# Public Law 119-21 created RHTP. Nothing dated before it can be RHTP under any
# state's timeline -- a floor beneath the per-state NOA test, recorded in the
# reference table rather than tested separately, because the NOA date is later
# and therefore strictly stronger.
# The nine committed state award files, named rather than globbed: a glob
# would start treating any newly committed stub as published evidence.
SWEEP_PUBLISHED_STATE_FILES <- c(
  "ga_great_health_awards", "fl_year1_awardees", "pa_year1_awardees",
  "al_year1_awardees", "ak_year1_awardees", "sd_rht_contracts",
  "sd_year1_awardees", "il_year1_awardees", "or_year1_awardees"
)

RHTP_STATUTE_DATE     <- as.Date("2025-07-04")
RHTP_STATUTE_CITATION <- "Public Law 119-21"


# -- The NOA date anchor -----------------------------------------------------

#' Build data/reference/cms_state_noa_dates.csv from the committed archive
#'
#' PARSED, NEVER TRANSCRIBED -- §7.1's posture for the allotment table, for the
#' same reason. The date is read out of the schema.org JSON-LD `datePublished`
#' in stage 00's archived copy of the CMS release that announced the awards, so
#' anybody can re-derive it offline and see where it came from.
#'
#' ONE DATE, FIFTY STATES. The release says "CMS today announced that all 50
#' states will receive awards under the Rural Health Transformation Program".
#' There were not fifty notices on fifty dates; there was one announcement.
#' The table is still written per state, with a `noa_date_basis` recording that
#' all 50 currently derive from that single release, so a state that later
#' proves to have a different date is a data correction and not a code change.
#'
#' AND IT IS CORROBORATED. HHSC's own page states CMS issued Texas its RHTP
#' Notice of Award on 2025-12-29 -- read and archived in session 19, from a
#' different publisher, and matching this release's datePublished exactly.
rhtp_build_noa_dates <- function() {
  archive <- here::here(NOA_RELEASE_FILE)

  if (!file.exists(archive)) {
    stop(
      "The CMS award announcement is not in the archive at '", NOA_RELEASE_FILE,
      "'.\nFetch it: Rscript R/00_cms_press_monitor.R --run",
      call. = FALSE
    )
  }

  html <- paste(readLines(archive, warn = FALSE), collapse = "\n")

  published <- stringr::str_match(
    html, '"datePublished"\\s*:\\s*"((?:19|20)\\d{2}-\\d{2}-\\d{2})'
  )[, 2]

  if (is.na(published)) {
    stop(
      "No schema.org datePublished in the archived CMS award announcement. ",
      "The NOA date must be parsed from the source, never typed in.",
      call. = FALSE
    )
  }

  noa_date <- as.Date(published)

  index <- readr::read_csv(
    here::here("data/reference/cms_newsroom_topic_index.csv"),
    show_col_types = FALSE, progress = FALSE
  )
  row <- index %>% dplyr::filter(.data$slug == NOA_RELEASE_SLUG)

  if (nrow(row) != 1) {
    stop("The CMS award announcement is not in cms_newsroom_topic_index.csv.",
         call. = FALSE)
  }

  # The index's own item_date is an independent reading of the same release,
  # taken from the listing page rather than the article body. If the two ever
  # disagree, the anchor is not safe to build.
  if (as.Date(row$item_date[1]) != noa_date) {
    stop(
      "The archived release's datePublished (", noa_date, ") disagrees with ",
      "the newsroom index's item_date (", row$item_date[1], ").",
      call. = FALSE
    )
  }

  rhtp_cms_states() %>%
    dplyr::mutate(
      noa_date         = noa_date,
      noa_date_basis   = paste0(
        "schema.org datePublished on the CMS release announcing awards to all ",
        "50 states, parsed from the committed stage 00 archive. One ",
        "announcement, fifty states. Corroborated by HHSC, which states CMS ",
        "issued Texas its RHTP Notice of Award on ", noa_date, "."
      ),
      statute_date     = RHTP_STATUTE_DATE,
      statute_citation = RHTP_STATUTE_CITATION,
      source_url       = row$url[1],
      source_archive_path = NOA_RELEASE_FILE,
      source_sha256    = row$full_page_sha256[1],
      notes            = paste0(
        "statute_date is the floor beneath noa_date: ", RHTP_STATUTE_CITATION,
        " created RHTP, so nothing dated before it can be RHTP in any state. ",
        "The operative §6.2 test is noa_date, which is later and therefore ",
        "strictly stronger."
      )
    )
}


rhtp_write_noa_dates <- function() {
  dates <- rhtp_build_noa_dates()
  readr::write_csv(dates, here::here(SWEEP_NOA_DATES), na = "")
  message("[sweep] wrote ", nrow(dates), " states -> ", SWEEP_NOA_DATES)
  message("[sweep]   NOA date: ", unique(as.character(dates$noa_date)),
          "  (statute floor ", RHTP_STATUTE_CITATION, ", ",
          RHTP_STATUTE_DATE, ")")
  invisible(dates)
}


# -- The sweep ---------------------------------------------------------------

#' Apply the extended §6.2 provenance filter to every Tier 3 candidate
#'
#' CANDIDATES ARE PASS + FLAGGED, matching R/03k. Quarantined rows are excluded
#' because they are already out; the question here is what is still IN.
#'
#' The provenance text is the source-document title plus the solicitation
#' number -- the same two fields `rhtp_apply_rules()` builds `.provenance_text`
#' from, and deliberately NOT the description. Description-scoped, the state
#' markers also match a Pennsylvania RHTP award row and Alaska's Year 1
#' announcement; source-scoped they match nothing that is RHTP.
rhtp_provenance_sweep <- function(records = NULL) {
  if (is.null(records)) records <- readRDS(here::here(SWEEP_RECORD_TABLE))

  registry  <- rhtp_read_state_program_registry()
  patterns  <- rhtp_read_patterns("non_rhtp_patterns.csv")
  noa       <- rhtp_read_noa_dates()

  cand <- records %>%
    dplyr::filter(award_tier == "SUBAWARD",
                  qa_status %in% c("PASS", "FLAGGED")) %>%
    dplyr::mutate(
      provenance_text = paste(
        dplyr::coalesce(source_doc_title, ""),
        dplyr::coalesce(solicitation_number, ""),
        sep = " "
      )
    ) %>%
    dplyr::left_join(noa %>% dplyr::select(state, noa_date), by = "state")

  swept <- purrr::pmap_dfr(
    list(cand$state, cand$provenance_text, cand$noa_date),
    function(st, txt, noa_date) {
      hit <- rhtp_match_state_program(st, txt, registry)
      resolved <- rhtp_resolve_action_date(st, txt, hit)

      flag_marker <- rhtp_flag_provenance_state(txt, patterns)
      flag_registry <- hit$flag[1]
      flag_date <- rhtp_flag_provenance_date(resolved$action_date[1], noa_date)

      tibble::tibble(
        registry_program   = hit$program_id[1],
        registry_disposition = hit$disposition[1],
        flag_state_program = dplyr::coalesce(flag_registry, flag_marker),
        state_program_basis = dplyr::case_when(
          !is.na(flag_registry) ~ "REGISTRY",
          !is.na(flag_marker)   ~ "TEXT_MARKER",
          TRUE                  ~ NA_character_
        ),
        action_date        = resolved$action_date[1],
        action_date_basis  = resolved$action_date_basis[1],
        flag_predates_noa  = flag_date
      )
    }
  )

  dplyr::bind_cols(cand, swept) %>%
    dplyr::mutate(
      caught = !is.na(flag_state_program) | !is.na(flag_predates_noa),
      new_flags = purrr::map2_chr(
        flag_state_program, flag_predates_noa,
        function(a, b) paste(stats::na.omit(c(a, b)), collapse = ";")
      )
    )
}


#' Fold the swept rows into one row per state
rhtp_provenance_sweep_by_state <- function(swept = NULL) {
  if (is.null(swept)) swept <- rhtp_provenance_sweep()

  states <- rhtp_cms_states()

  per_state <- swept %>%
    dplyr::group_by(state) %>%
    dplyr::summarise(
      tier3_candidates      = dplyr::n(),
      caught_total          = sum(caught),
      caught_state_program  = sum(!is.na(flag_state_program)),
      caught_by_registry    = sum(state_program_basis == "REGISTRY",
                                  na.rm = TRUE),
      caught_by_text_marker = sum(state_program_basis == "TEXT_MARKER",
                                  na.rm = TRUE),
      caught_predates_noa   = sum(!is.na(flag_predates_noa)),
      # The bound on the date test, reported rather than hidden: how many
      # candidates carry a date the source asserts at all.
      datable_rows          = sum(!is.na(action_date)),
      undatable_rows        = sum(is.na(action_date)),
      refused_rcj_year      = sum(action_date_basis == "REFUSED_RCJ_YEAR"),
      caught_amount         = sum(amount_announced[caught], na.rm = TRUE),
      .groups = "drop"
    )

  states %>%
    dplyr::left_join(per_state, by = "state") %>%
    dplyr::mutate(dplyr::across(
      c(tier3_candidates, caught_total, caught_state_program,
        caught_by_registry, caught_by_text_marker, caught_predates_noa,
        datable_rows, undatable_rows, refused_rcj_year, caught_amount),
      ~ tidyr::replace_na(.x, 0)
    )) %>%
    dplyr::arrange(dplyr::desc(caught_total), dplyr::desc(tier3_candidates),
                   state)
}


#' The flagged rows themselves, one per caught candidate
rhtp_provenance_sweep_rows <- function(swept = NULL) {
  if (is.null(swept)) swept <- rhtp_provenance_sweep()

  swept %>%
    dplyr::filter(caught) %>%
    dplyr::transmute(
      state, record_id, awardee_name_raw, amount_announced,
      source_doc_title, solicitation_number,
      new_flags, state_program_basis, registry_program, registry_disposition,
      action_date, action_date_basis,
      prior_qa_status = qa_status, prior_flag_reason = flag_reason
    ) %>%
    dplyr::arrange(state, dplyr::desc(amount_announced))
}


#' Caught rows whose (state, recipient) already appears in a committed state file
#'
#' The nine committed state award files are hand-extracted from state primary
#' sources, not from RCJ, so they are the independent check on this filter:
#' anything the sweep catches that one of them publishes is a false positive by
#' construction.
rhtp_sweep_published_overlap <- function(swept) {
  norm <- function(x) {
    stringr::str_squish(stringr::str_to_lower(
      stringr::str_remove_all(dplyr::coalesce(x, ""), "[^A-Za-z0-9 ]")
    ))
  }

  published <- purrr::map_dfr(SWEEP_PUBLISHED_STATE_FILES, function(f) {
    path <- here::here("data", "reference", paste0(f, ".csv"))
    if (!file.exists(path)) return(NULL)
    d <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE,
                         col_types = readr::cols(.default = "c"))
    nm <- intersect(c("recipient_name", "awardee_name", "recipient", "awardee"),
                    names(d))
    if (length(nm) == 0 || !"state" %in% names(d)) return(NULL)
    tibble::tibble(published_file = f, state = d[["state"]],
                   published_name = norm(d[[nm[1]]]))
  })

  swept %>%
    dplyr::filter(caught) %>%
    dplyr::mutate(published_name = norm(awardee_name_raw)) %>%
    dplyr::inner_join(published, by = c("state", "published_name")) %>%
    dplyr::filter(nzchar(published_name))
}


# -- Assertions --------------------------------------------------------------

rhtp_provenance_sweep_assert <- function(swept = NULL, by_state = NULL) {
  if (is.null(swept))   swept   <- rhtp_provenance_sweep()
  if (is.null(by_state)) by_state <- rhtp_provenance_sweep_by_state(swept)

  stopifnot(nrow(by_state) == 50)
  stopifnot(all(by_state$caught_total <= by_state$tier3_candidates))
  stopifnot(all(by_state$datable_rows + by_state$undatable_rows ==
                  by_state$tier3_candidates))
  stopifnot(all(by_state$caught_by_registry + by_state$caught_by_text_marker ==
                  by_state$caught_state_program))

  # Every new flag is in the vocabulary. A sweep that invented a code would be
  # §2's "do not invent codes mid-session" happening in an audit file.
  vocab <- rhtp_vocabulary("flag_reason")
  used <- unique(unlist(strsplit(swept$new_flags[nzchar(swept$new_flags)], ";")))
  stopifnot(all(used %in% vocab))

  # THE REFUSAL, ASSERTED. Pennsylvania's 66 committed Year 1 awards and
  # Maryland's 33 Pillar 2 rows sit behind an RCJ title year of 2025. If the
  # date test ever starts reading that prefix as a date, it catches them, and
  # this is the assertion that stops it reaching a report.
  pa_md <- swept %>%
    dplyr::filter(state %in% c("PA", "MD"),
                  stringr::str_detect(source_doc_title, "RHTP|RHT Plan|Pillar"))
  stopifnot(nrow(pa_md) > 0)
  stopifnot(all(is.na(pa_md$flag_predates_noa)))

  # No caught row may be dated on or after its state's NOA. This is the date
  # test's own arithmetic, checked against the table rather than assumed.
  # `swept` already carries noa_date from rhtp_provenance_sweep()'s join;
  # re-joining would silently produce noa_date.x/.y and compare nothing.
  stopifnot("noa_date" %in% names(swept))
  dated <- swept %>% dplyr::filter(!is.na(flag_predates_noa))
  if (nrow(dated) > 0) stopifnot(all(dated$action_date < dated$noa_date))

  # THE FALSE-POSITIVE CHECK, AND IT IS THE ONE THAT MATTERS. A provenance
  # filter that quarantines a row this project has already published against a
  # state primary source is worse than no filter at all: it would delete real
  # findings while reporting that it had cleaned the corpus. So every caught
  # row is checked against the 879 award rows in the nine committed state
  # files, on (state, normalised recipient name). Zero overlap is the required
  # result, not the observed one -- this hard-fails if a catch ever lands on a
  # published recipient, and a human decides which of the two is wrong.
  overlap <- rhtp_sweep_published_overlap(swept)
  if (nrow(overlap) > 0) {
    stop(
      "The sweep caught ", nrow(overlap), " row(s) whose (state, recipient) ",
      "already appears in a committed state award file:\n",
      paste0("  ", overlap$state, " ", overlap$awardee_name_raw,
             "  <- ", overlap$published_file, collapse = "\n"),
      call. = FALSE
    )
  }

  # A registry row that matches nothing is not an error, but it is not allowed
  # to pass silently for one that is still working.
  registry <- rhtp_read_state_program_registry()
  matched <- unique(swept$registry_program[!is.na(swept$registry_program)])
  dead <- setdiff(registry$program_id, matched)
  if (length(dead) > 0) {
    message("[sweep] NOTE: registry rows matching no candidate: ",
            paste(dead, collapse = ", "))
  }

  invisible(TRUE)
}


# -- Report ------------------------------------------------------------------

rhtp_provenance_sweep_report <- function(swept = NULL) {
  if (is.null(swept)) swept <- rhtp_provenance_sweep()
  by_state <- rhtp_provenance_sweep_by_state(swept)

  message("")
  message("=== §6.2 provenance sweep -- all 50 states, committed RCJ pull ===")
  message("Tier 3 candidates swept : ", nrow(swept))
  message("Rows caught             : ", sum(swept$caught),
          "  in ", sum(by_state$caught_total > 0), " states")
  message("  PROVENANCE_STATE_PROGRAM: ",
          sum(!is.na(swept$flag_state_program)),
          "  (registry ", sum(swept$state_program_basis == "REGISTRY",
                              na.rm = TRUE),
          ", text marker ", sum(swept$state_program_basis == "TEXT_MARKER",
                                na.rm = TRUE), ")")
  message("  PROVENANCE_PREDATES_NOA : ", sum(!is.na(swept$flag_predates_noa)))
  # §0.1: this is RCJ's unvalidated `federalAmount`, summed only to size what
  # the filter is keeping out of a Tier 3 total. It is not a dollar finding,
  # and one row dominates it -- New Hampshire's $1,898,965,390 Medicaid Care
  # Management record, which is three managed care organisations in a single
  # awardeeName and which the §6.2 allotment ceiling already flagged in session
  # 5 as impossible against a $204M allotment. That the amount test and the
  # provenance test land on the same row from opposite directions is the
  # closure worth reading; the sum is not.
  caught_amt <- sum(swept$amount_announced[swept$caught], na.rm = TRUE)
  biggest <- max(swept$amount_announced[swept$caught], na.rm = TRUE)
  message("RCJ amount on caught rows: ",
          format(caught_amt, big.mark = ",", scientific = FALSE),
          "  (unvalidated, §0.1; ",
          format(biggest, big.mark = ",", scientific = FALSE),
          " of it is one NH Medicaid row)")
  message("")
  message("-- by state, catches only --")
  print(as.data.frame(
    by_state %>%
      dplyr::filter(caught_total > 0) %>%
      dplyr::select(state, tier3_candidates, caught_total,
                    caught_by_registry, caught_by_text_marker,
                    caught_predates_noa, caught_amount)
  ), row.names = FALSE)

  message("")
  message("-- the bound on the date test --")
  message("Candidates carrying a source-asserted date : ",
          sum(!is.na(swept$action_date)), " of ", nrow(swept))
  message("Undatable                                  : ",
          sum(is.na(swept$action_date)))
  print(as.data.frame(
    swept %>% dplyr::count(action_date_basis, sort = TRUE)
  ), row.names = FALSE)
  message("")
  message("REFUSED_RCJ_YEAR is the safety catch, not a shortfall: those rows ",
          "carry an RCJ title\nyear and nothing else. Read as a date it would ",
          "quarantine all 66 Pennsylvania and\nall 33 Maryland rows this ",
          "project has already published (§0.1).")

  invisible(by_state)
}


# -- Write -------------------------------------------------------------------

rhtp_provenance_sweep_write <- function() {
  swept    <- rhtp_provenance_sweep()
  by_state <- rhtp_provenance_sweep_by_state(swept)
  rhtp_provenance_sweep_assert(swept, by_state)

  readr::write_csv(by_state, here::here(SWEEP_BY_STATE), na = "")
  readr::write_csv(rhtp_provenance_sweep_rows(swept), here::here(SWEEP_ROWS),
                   na = "")

  message("[sweep] wrote 50 states -> ", SWEEP_BY_STATE)
  message("[sweep] wrote ", sum(swept$caught), " flagged rows -> ", SWEEP_ROWS)

  invisible(swept)
}


# --- CLI --------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--noa-dates" %in% args) {
    rhtp_write_noa_dates()
  } else if ("--build" %in% args) {
    s <- rhtp_provenance_sweep_write()
    rhtp_provenance_sweep_report(s)
  } else if ("--validate" %in% args) {
    rhtp_provenance_sweep_assert()
    message("[sweep] all assertions pass.")
  } else if ("--report" %in% args) {
    rhtp_provenance_sweep_report()
  } else {
    message("Usage: Rscript R/02b_provenance_sweep.R ",
            "[--noa-dates | --build | --validate | --report]")
  }
}
