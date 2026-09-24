# test_02b_provenance_sweep.R -------------------------------------------------
# The §6.2 provenance filter's STATE half, and the date test. Reads committed
# artifacts only -- no network, no quota.
#
# WHAT THIS FILE IS DEFENDING, IN ORDER OF HOW BADLY IT WOULD HURT.
#
#   1. THE FILTER QUARANTINES SOMETHING THIS PROJECT HAS PUBLISHED. A
#      provenance filter that deletes real findings while reporting a clean
#      corpus is worse than no filter. Pennsylvania's 66 committed Year 1
#      awards sit behind an RCJ source-document title of "PA - 2025 - ...", and
#      a date test keyed on that prefix takes all of them. Several tests below
#      exist only to keep that from happening.
#
#   2. THE DATE TEST RUNS ON A DATE NOBODY ASSERTED. RCJ publishes no
#      award-action date at all, so every date here is mined out of text, and a
#      miner that accepts a bare year would date a record from a programme
#      name. The refusals are tested as hard as the catches.
#
#   3. THE FILTER SILENTLY STOPS CATCHING. Texas's 53 state-appropriation rows
#      are the case this was built for; if a registry regex or a marker ever
#      stops matching them, that must fail here rather than pass as a clean
#      sweep.

library(testthat)

source(here::here("R", "02b_provenance_sweep.R"))

sweep_records <- rhtp_record_table_live(path = here::here(SWEEP_RECORD_TABLE))
swept         <- rhtp_provenance_sweep(sweep_records)
by_state      <- rhtp_provenance_sweep_by_state(swept)
registry      <- rhtp_read_state_program_registry()
patterns      <- rhtp_read_patterns("non_rhtp_patterns.csv")


# -- The NOA anchor ----------------------------------------------------------

test_that("the NOA date is parsed from the committed archive, not typed in", {
  dates <- rhtp_read_noa_dates()

  expect_equal(nrow(dates), 50)
  expect_equal(unique(as.character(dates$noa_date)), "2025-12-29")
  expect_equal(unique(as.character(dates$statute_date)), "2025-07-04")

  # Re-derive it from the archive rather than from the CSV: this is the test
  # that would fail if somebody hand-edited the anchor.
  rebuilt <- rhtp_build_noa_dates()
  expect_equal(rebuilt$noa_date, dates$noa_date)
  expect_equal(sort(rebuilt$state), sort(dates$state))
})

test_that("the statute floor is earlier than the NOA date, so NOA is stronger", {
  dates <- rhtp_read_noa_dates()
  expect_true(all(dates$statute_date < dates$noa_date))
})


# -- The two-dates trap ------------------------------------------------------
#
# Three states publish CMS's OWN Notice of Award, and that PDF is better
# evidence than a press release -- which is what makes it the trap. Each form
# carries a budget period starting 12/29/2025 AND a later "Federal Award Date"
# that is the date of the latest budget revision. A future session "correcting"
# the anchor from these documents would take the field labelled like the answer
# and quarantine genuine rows. These tests read the archived PDFs and drive the
# counterfactual, so that correction fails here instead of in the data.

source(here::here("R", "utils_pdf_text.R"))

# state -> archived NOA, its budget period, and the Federal Award Date on it.
CMS_NOA_ARCHIVES <- tibble::tribble(
  ~state, ~path,                                                                 ~federal_award_date,
  "NV",   "data/evidence/NV/2026-02-19_nv_cms_notice_of_award_rhtcms332074-01-02.pdf", "02/19/2026",
  "CA",   "data/evidence/CA/2026-03-31_ca_cms_notice_of_award_revised.pdf",            "03/31/2026",
  "CT",   "data/evidence/CT/2026-09-02_ct_cms_notice_of_award.pdf",                    "07/23/2026"
)

noa_pdf_text <- function(path) {
  paste(rhtp_pdf_text(here::here(path)), collapse = " ")
}

test_that("every state NOA in the archive starts its budget period on the anchor", {
  anchor <- unique(rhtp_read_noa_dates()$noa_date)
  expect_equal(as.character(anchor), "2025-12-29")

  for (i in seq_len(nrow(CMS_NOA_ARCHIVES))) {
    row <- CMS_NOA_ARCHIVES[i, ]
    expect_true(file.exists(here::here(row$path)), info = row$state)
    txt <- noa_pdf_text(row$path)

    # The budget period, as the pair CMS prints it. Asserted as a PAIR rather
    # than as a loose "12/29/2025 appears somewhere", because the whole point
    # is which field the date sits in.
    expect_match(txt, "12/29/2025\\s+10/30/2026", info = row$state)
  }
})

test_that("three of three carry a LATER Federal Award Date, and it is a revision", {
  anchor <- unique(rhtp_read_noa_dates()$noa_date)

  for (i in seq_len(nrow(CMS_NOA_ARCHIVES))) {
    row <- CMS_NOA_ARCHIVES[i, ]
    txt <- noa_pdf_text(row$path)

    # The label a future session would grep for, and the value under it.
    expect_true(stringr::str_detect(txt, stringr::fixed("Federal Award Date")),
                info = row$state)
    expect_true(stringr::str_detect(txt, stringr::fixed(row$federal_award_date)),
                info = row$state)

    # It is later than the anchor in every case -- that is the trap, so it is
    # measured rather than assumed.
    fad <- as.Date(row$federal_award_date, format = "%m/%d/%Y")
    expect_gt(as.numeric(fad - anchor), 0)

    # And it is later BECAUSE the form is a re-issue, which is the word that
    # explains the gap. If a state ever publishes an original NOA whose action
    # type is not a revision, this fails and the finding must be re-read.
    expect_true(stringr::str_detect(txt, stringr::fixed("Revision (Budget)")),
                info = row$state)
  }
})

test_that("the gap grows with the revision count, so it is not a fixed offset", {
  # Connecticut is on its second revision (award # ends -01-03) where Nevada
  # and California are on their first (-01-02), and its gap is the widest by a
  # long way. A future session must not "fix" this with a constant offset.
  anchor <- unique(rhtp_read_noa_dates()$noa_date)
  gaps <- as.numeric(
    as.Date(CMS_NOA_ARCHIVES$federal_award_date, format = "%m/%d/%Y") - anchor
  )
  names(gaps) <- CMS_NOA_ARCHIVES$state

  expect_equal(unname(gaps[["NV"]]),  52)
  expect_equal(unname(gaps[["CA"]]),  92)
  expect_equal(unname(gaps[["CT"]]), 206)
  expect_gt(length(unique(gaps)), 1)

  expect_true(stringr::str_detect(noa_pdf_text(CMS_NOA_ARCHIVES$path[3]),
                                  stringr::fixed("RHTCMS332073-01-03")))
})

test_that("keying the date test on the Federal Award Date quarantines real rows", {
  anchor <- unique(rhtp_read_noa_dates()$noa_date)

  # Connecticut's two dated candidates, from the committed sweep.
  ct <- swept %>%
    dplyr::filter(.data$state == "CT", !is.na(.data$action_date))
  expect_equal(nrow(ct), 2)

  # Against the real anchor they are clean: nothing Connecticut has published
  # predates its own award.
  today <- purrr::map_chr(
    ct$action_date, ~ rhtp_flag_provenance_date(.x, anchor)
  )
  expect_true(all(is.na(today)))

  # Against the NOA form's Federal Award Date, BOTH quarantine -- for being
  # seven months "early" relative to their own state's genuine award.
  wrong <- purrr::map_chr(
    ct$action_date,
    ~ rhtp_flag_provenance_date(.x, as.Date("2026-07-23"))
  )
  expect_equal(sum(wrong == "PROVENANCE_PREDATES_NOA", na.rm = TRUE), 2)
})


# -- The refusals ------------------------------------------------------------

test_that("RCJ's title-year prefix is never read as a date", {
  # Pennsylvania's entire Year 1 file sits behind this exact title.
  pa <- rhtp_resolve_action_date(
    "PA",
    "PA - 2025 - Rural Health Selected Projects: Pa RHT Plan (RHTP) Authorized Project Awards"
  )
  expect_true(is.na(pa$action_date[1]))
  expect_equal(pa$action_date_basis[1], "REFUSED_RCJ_YEAR")

  # And therefore no flag.
  expect_true(is.na(rhtp_flag_provenance_date(pa$action_date[1],
                                              as.Date("2025-12-29"))))
})

test_that("the 145 RCJ-2025-titled candidates are not caught by the date test", {
  titled_2025 <- swept %>%
    dplyr::filter(stringr::str_detect(
      dplyr::coalesce(source_doc_title, ""),
      "^[A-Za-z]{2}\\s*-\\s*2025\\s*-"
    ))

  expect_gt(nrow(titled_2025), 100)

  # Every one of them that the date test DID catch must have had a real date
  # in the text or a registry date -- never the prefix.
  caught <- titled_2025 %>% dplyr::filter(!is.na(flag_predates_noa))
  expect_true(all(caught$action_date_basis %in%
                    c("SOURCE_TEXT") |
                    stringr::str_starts(caught$action_date_basis, "REGISTRY")))
})

test_that("Pennsylvania's 66 and Maryland's 33 published rows survive the sweep", {
  pa <- swept %>% dplyr::filter(state == "PA")
  md <- swept %>% dplyr::filter(state == "MD")

  expect_equal(sum(pa$caught), 0)
  expect_equal(sum(md$caught), 0)
  expect_equal(by_state$caught_total[by_state$state == "PA"], 0)
  expect_equal(by_state$caught_total[by_state$state == "MD"], 0)
})

test_that("a fiscal year is a period, not a date, and is refused", {
  r <- rhtp_resolve_action_date(
    "TX",
    "TX - 2025 - Suggested Intergovernmental Transfer (IGT) amounts for the third payment of state fiscal year (SFY) 2025"
  )
  expect_true(is.na(r$action_date[1]))
  expect_equal(r$action_date_basis[1], "REFUSED_FISCAL_YEAR")
})

test_that("two dates in one string is ambiguous and refuses", {
  r <- rhtp_resolve_action_date("XX", "Awards made March 3, 2025 and April 9, 2026")
  expect_true(is.na(r$action_date[1]))
  expect_equal(r$action_date_basis[1], "REFUSED_AMBIGUOUS_DATES")
})


# -- The date miner ----------------------------------------------------------

test_that("a bare year is not a date", {
  expect_length(rhtp_mine_explicit_dates("Rural Health Program 2019 cohort"), 0)
  expect_length(rhtp_mine_explicit_dates("HHS0015180"), 0)
  expect_length(rhtp_mine_explicit_dates("Emergency Contract #8400003450"), 0)
})

test_that("the miner reads the four date forms states actually publish", {
  expect_equal(rhtp_mine_explicit_dates("Public Webinar (November 13, 2025)"),
               as.Date("2025-11-13"))
  expect_equal(rhtp_mine_explicit_dates("Consultant Quotation #20250728"),
               as.Date("2025-07-28"))
  expect_equal(rhtp_mine_explicit_dates("effective 2026-03-01"),
               as.Date("2026-03-01"))
  expect_equal(rhtp_mine_explicit_dates("signed 3/1/2026"),
               as.Date("2026-03-01"))
})

test_that("an impossible month or day cannot masquerade as a compact date", {
  expect_length(rhtp_mine_explicit_dates("contract 20251345"), 0)
  expect_length(rhtp_mine_explicit_dates("contract 20250034"), 0)
})


# -- The date test itself ----------------------------------------------------

test_that("the date test flags only what precedes the NOA, and never NA", {
  noa <- as.Date("2025-12-29")
  expect_equal(rhtp_flag_provenance_date(as.Date("2025-03-24"), noa),
               "PROVENANCE_PREDATES_NOA")
  expect_true(is.na(rhtp_flag_provenance_date(as.Date("2025-12-29"), noa)))
  expect_true(is.na(rhtp_flag_provenance_date(as.Date("2026-06-01"), noa)))
  expect_true(is.na(rhtp_flag_provenance_date(as.Date(NA), noa)))
  expect_true(is.na(rhtp_flag_provenance_date(as.Date("2020-01-01"), as.Date(NA))))
})


# -- The state-programme half ------------------------------------------------

test_that("Texas's 53 state-appropriation rows are caught, by the registry", {
  tx <- swept %>%
    dplyr::filter(state == "TX",
                  stringr::str_detect(source_doc_title, "HHS0015180|HHS0015677"))

  expect_equal(nrow(tx), 53)
  expect_true(all(tx$flag_state_program == "PROVENANCE_STATE_PROGRAM"))
  expect_true(all(tx$state_program_basis == "REGISTRY"))
  expect_true(all(tx$registry_disposition == "NOT_RHTP_STATE_APPROPRIATION"))

  # And by the date test too, on the RFA release dates read off HHSC's page.
  expect_true(all(tx$flag_predates_noa == "PROVENANCE_PREDATES_NOA"))
  expect_equal(sort(unique(as.character(tx$action_date))),
               c("2025-03-11", "2025-03-24"))

  # 21 at $250,000 and 32 at $350,000 -- the $16.8M an extractor written from
  # this candidate list would have published as RHTP.
  expect_equal(sum(tx$amount_announced), 21 * 250000 + 32 * 350000)
})

test_that("the Texas candidates: 53 caught, and the 9 Medicaid rows WITHDRAWN", {
  # 68 candidates / 62 caught on the 2026-08-27 pull. On the 2026-09-24 pull
  # (session 62) RCJ WITHDREW the 5 ATLIS and 4 IGT Medicaid rows the
  # TX-ATLIS-MCO and TX-IGT registry rows existed to catch, and added 26 new
  # candidates. The 53 Rider 88 rows are still caught; everything uncaught is
  # dispositioned by hand in tx_rcj_candidate_disposition.csv, because this
  # filter must not pretend to solve a §0.3 or wrong-programme problem it
  # has no registry row for.
  tx <- swept %>% dplyr::filter(state == "TX")
  expect_equal(nrow(tx), 85)
  expect_equal(sum(tx$caught), 53)
  all_rt <- readRDS(here::here(SWEEP_RECORD_TABLE))
  wd <- all_rt %>% dplyr::filter(state == "TX", award_tier == "SUBAWARD",
                                 change_status == "WITHDRAWN")
  expect_equal(nrow(wd), 9)
})

test_that("appropriation language is NOT an available marker, and that is measured", {
  txt <- paste(dplyr::coalesce(swept$source_doc_title, ""),
               dplyr::coalesce(swept$solicitation_number, ""),
               dplyr::coalesce(swept$program_description, ""))

  expect_equal(sum(stringr::str_detect(txt, "Rider\\s+\\d+")), 0)
  expect_equal(sum(stringr::str_detect(txt, "House Bill|Senate Bill")), 0)
  expect_equal(sum(stringr::str_detect(txt, "General Revenue")), 0)
  expect_equal(sum(stringr::str_detect(txt, "bienni")), 0)

  # `appropriat` matches exactly one row, and it is genuine RHTP. This is the
  # measurement that says a marker set modelled on the federal one cannot reach
  # Texas, and why the registry exists.
  approp <- swept %>% dplyr::filter(stringr::str_detect(
    dplyr::coalesce(program_description, ""), "appropriat"))
  # One row (PA) on 2026-08-27; six on 2026-09-24 (four Alaska, one NJ, the
  # same PA row). NONE is Texas and NONE is caught -- the measurement still
  # says what it said: the word does not reach the state money it would need to.
  expect_equal(nrow(approp), 6)
  expect_true("PA" %in% approp$state)
  expect_false(any(approp$state == "TX"))
  expect_false(any(approp$caught))
})

test_that("the state markers are source-scoped, and the scope is doing work", {
  # Description-scoped, the Medicaid marker also matches a Pennsylvania RHTP
  # award row and Alaska's Year 1 announcement. Source-scoped it matches
  # neither. If somebody widens the scope, this fails.
  pa_row <- swept %>%
    dplyr::filter(state == "PA",
                  stringr::str_detect(dplyr::coalesce(program_description, ""),
                                      "Managed Care|managed care"))
  expect_gt(nrow(pa_row), 0)
  expect_true(all(is.na(pa_row$flag_state_program)))

  ak_row <- swept %>%
    dplyr::filter(state == "AK",
                  stringr::str_detect(dplyr::coalesce(program_description, ""),
                                      "waiver"))
  expect_true(all(is.na(ak_row$flag_state_program)))

  expect_true(all(
    patterns$scope[patterns$flag_reason == "PROVENANCE_STATE_PROGRAM"] == "source"
  ))
})

# SESSION 62: RCJ WITHDREW all three of these states' caught rows on the
# 2026-09-24 pull. They are kept in the record table as WITHDRAWN (§6.3) and
# these tests now sweep THOSE rows, re-labelled live, so the three filters are
# still proven to catch them the day they come back -- rather than silently
# testing an empty set.
withdrawn_t3 <- function(st) {
  readRDS(here::here(SWEEP_RECORD_TABLE)) %>%
    dplyr::filter(state == st, award_tier == "SUBAWARD",
                  change_status == "WITHDRAWN") %>%
    dplyr::mutate(superseded_by = NA_character_, change_status = "UNCHANGED")
}

test_that("Illinois's one candidate is WITHDRAWN, and would still be caught", {
  expect_equal(sum(swept$state == "IL"), 0)
  il <- rhtp_provenance_sweep(withdrawn_t3("IL"))
  expect_equal(nrow(il), 1)
  expect_true(il$caught)
  expect_equal(il$registry_program, "IL-MYOWNDOCTOR-MEDICAID")
  expect_equal(il$amount_announced, 1)

  # And it is NOT the ICAHN award, which is Illinois's real Year 1 finding.
  icahn <- readr::read_csv(here::here("data/reference/il_year1_awardees.csv"),
                           show_col_types = FALSE, progress = FALSE)
  expect_false(any(stringr::str_detect(icahn$awardee, "MyOwnDoctor")))
})

test_that("New Hampshire's $1.9bn row is WITHDRAWN, and two filters still agree on it", {
  expect_equal(sum(swept$caught[swept$state == "NH"]), 0)
  nh <- rhtp_provenance_sweep(withdrawn_t3("NH")) %>% dplyr::filter(caught)
  expect_gte(nrow(nh), 1)
  expect_true(all(nh$flag_state_program == "PROVENANCE_STATE_PROGRAM"))
  big <- nh %>% dplyr::filter(amount_announced == max(amount_announced))
  expect_equal(big$amount_announced, 1898965390)
  expect_match(big$flag_reason, "AMOUNT_EXCEEDS_STATE_ALLOTMENT")
})

test_that("Rhode Island's opioid settlement rows are WITHDRAWN, and still caught", {
  expect_equal(sum(swept$caught[swept$state == "RI"]), 0)
  ri <- rhtp_provenance_sweep(withdrawn_t3("RI")) %>% dplyr::filter(caught)
  expect_equal(nrow(ri), 3)
  expect_true(any(stringr::str_detect(ri$awardee_name_raw, "Hospital")))
})


# -- The sweep as a whole ----------------------------------------------------

test_that("the sweep catches 66 rows in 4 states, and the arithmetic closes", {
  # 101 rows in 9 states through session 61 (history in git: TX 62, CA 11,
  # NV 9, MI 8, NH 3, AZ 3, RI 3, MS 1, IL 1). ON THE 2026-09-24 PULL
  # (session 62) RCJ WITHDREW every candidate five registry rows existed to
  # catch -- California's 11 SRHRP seismic rows, Michigan's 8 opioid-settlement
  # rows, Texas's 9 ATLIS/IGT Medicaid rows, Illinois's MyOwnDoctor row -- and
  # Rhode Island's 3 opioid rows and New Hampshire's 3 Medicaid rows left the
  # candidate set too. The aggregator dropping rows this filter caught is a
  # finding about the aggregator, and the registry keeps those entries
  # (they match nothing today and say so) so a re-appearance is caught.
  expect_equal(sum(swept$caught), 66)
  expect_equal(sum(by_state$caught_total > 0), 4)
  expect_equal(sum(by_state$caught_total), 66)
  expect_setequal(by_state$state[by_state$caught_total > 0],
                  c("TX", "NV", "AZ", "MS"))
})

test_that("California's eleven SRHRP rows are WITHDRAWN, not un-caught", {
  all_rt <- readRDS(here::here(SWEEP_RECORD_TABLE))
  ca_wd <- all_rt %>% dplyr::filter(state == "CA", award_tier == "SUBAWARD",
                                    change_status == "WITHDRAWN")
  expect_equal(nrow(ca_wd), 11)
  expect_equal(sum(ca_wd$amount_announced), 5475000)
  # the registry entry survives and would catch them if they came back
  expect_true("CA-SRHRP-SEISMIC" %in% registry$program_id)
  ca_wd_swept <- rhtp_provenance_sweep(ca_wd %>% dplyr::mutate(
    superseded_by = NA_character_, change_status = "UNCHANGED"))
  expect_true(all(ca_wd_swept$registry_program == "CA-SRHRP-SEISMIC"))
  expect_equal(sum(swept$caught[swept$state == "CA"]), 0)
})

test_that("Nevada's caught rows are the nine GME programmes, and no Nevada RHTP row", {
  nv <- swept %>% dplyr::filter(state == "NV", caught)
  expect_equal(nrow(nv), 9)
  expect_true(all(nv$flag_state_program == "PROVENANCE_STATE_PROGRAM"))
  expect_true(all(nv$registry_program == "NV-GME-ROUNDVIII"))
  expect_true(all(nv$registry_disposition == "NOT_RHTP_STATE_PROGRAM"))
  # They are NOT caught on a date: Round VIII is a 2026 award, well after the
  # 2025-12-29 Notice of Award. What disqualifies them is the funding source.
  expect_true(all(is.na(nv$flag_predates_noa)))
  # And their amounts are the state's own published figures.
  expect_equal(sum(nv$amount_announced), 15755068)
})

test_that("no caught row is a recipient this project has already published", {
  expect_equal(nrow(rhtp_sweep_published_overlap(swept)), 0)
})

test_that("every new flag is in the vocabulary", {
  vocab <- rhtp_vocabulary("flag_reason")
  expect_true("PROVENANCE_STATE_PROGRAM" %in% vocab)
  expect_true("PROVENANCE_PREDATES_NOA" %in% vocab)

  used <- unique(unlist(strsplit(
    swept$new_flags[nzchar(swept$new_flags)], ";")))
  expect_true(all(used %in% vocab))
})

test_that("both new codes quarantine, on the same footing as the federal one", {
  expect_true("PROVENANCE_STATE_PROGRAM" %in% RHTP_QUARANTINE_FLAGS)
  expect_true("PROVENANCE_PREDATES_NOA" %in% RHTP_QUARANTINE_FLAGS)
  expect_equal(rhtp_qa_status("PROVENANCE_STATE_PROGRAM"), "QUARANTINED")
  expect_equal(rhtp_qa_status("PROVENANCE_PREDATES_NOA"), "QUARANTINED")
})

test_that("the date test's coverage bound is reported, not hidden", {
  # The honest headline: RCJ publishes no award-action date, so most
  # candidates cannot be dated at all. A future run that quietly reports a
  # fully dated corpus has started inferring dates.
  expect_equal(sum(!is.na(swept$action_date)) + sum(is.na(swept$action_date)),
               nrow(swept))
  expect_gt(sum(is.na(swept$action_date)), nrow(swept) * 0.5)
  expect_true(all(by_state$datable_rows + by_state$undatable_rows ==
                    by_state$tier3_candidates))
})

test_that("the by-state table covers all 50 states and never over-counts", {
  expect_equal(nrow(by_state), 50)
  expect_equal(nrow(dplyr::distinct(by_state, state)), 50)
  expect_true(all(by_state$caught_total <= by_state$tier3_candidates))
  expect_true(all(by_state$caught_by_registry + by_state$caught_by_text_marker ==
                    by_state$caught_state_program))
})

test_that("the committed sweep outputs match a fresh run", {
  on_disk <- readr::read_csv(here::here(SWEEP_BY_STATE),
                             show_col_types = FALSE, progress = FALSE)
  expect_equal(nrow(on_disk), 50)
  expect_equal(sum(on_disk$caught_total), sum(swept$caught))

  rows <- readr::read_csv(here::here(SWEEP_ROWS),
                          show_col_types = FALSE, progress = FALSE)
  expect_equal(nrow(rows), sum(swept$caught))
})

test_that("the registry carries its evidence, not just its verdict", {
  expect_true(all(nzchar(registry$disqualifying_fact)))
  expect_true(all(nzchar(registry$program_id)))
  expect_false(any(duplicated(registry$program_id)))

  # A registry row with a date must say where the date came from.
  dated <- registry %>% dplyr::filter(!is.na(program_date))
  expect_true(all(nzchar(dated$program_date_basis)))

  # And a row asserting a state appropriation must cite a state source.
  approp <- registry %>%
    dplyr::filter(disposition == "NOT_RHTP_STATE_APPROPRIATION")
  expect_gt(nrow(approp), 0)
  expect_true(all(nzchar(approp$state_source_url)))
  expect_true(all(file.exists(here::here(approp$source_archive_path))))
})

test_that("the assertions run clean on the committed corpus", {
  expect_true(rhtp_provenance_sweep_assert(swept, by_state))
})
