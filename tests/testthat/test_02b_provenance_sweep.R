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

sweep_records <- readRDS(here::here(SWEEP_RECORD_TABLE))
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

test_that("all 68 Texas candidates are caught or accounted for", {
  tx <- swept %>% dplyr::filter(state == "TX")
  expect_equal(nrow(tx), 68)
  expect_equal(sum(tx$caught), 62)

  # The 6 not caught are the ones session 19 dispositioned as RHTP but not a
  # Tier 3 subaward -- budget-narrative line items and the "80 Rural Hospital
  # Districts" class. They are a §0.3 problem, not a provenance one, and this
  # filter must not pretend to solve them.
  uncaught <- tx %>% dplyr::filter(!caught)
  expect_true(all(stringr::str_detect(uncaught$source_doc_title, "RHTP|Texas RHTP")))
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
  expect_equal(nrow(approp), 1)
  expect_equal(approp$state, "PA")
  expect_false(approp$caught)
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

test_that("Illinois's only candidate is caught, corroborating session 16 by machine", {
  il <- swept %>% dplyr::filter(state == "IL")
  expect_equal(nrow(il), 1)
  expect_true(il$caught)
  expect_equal(il$registry_program, "IL-MYOWNDOCTOR-MEDICAID")
  expect_equal(il$amount_announced, 1)

  # And it is NOT the ICAHN award, which is Illinois's real Year 1 finding.
  icahn <- readr::read_csv(here::here("data/reference/il_year1_awardees.csv"),
                           show_col_types = FALSE, progress = FALSE)
  expect_false(any(stringr::str_detect(icahn$awardee, "MyOwnDoctor")))
})

test_that("New Hampshire's $1.9bn row is caught, and two filters agree on it", {
  nh <- swept %>% dplyr::filter(state == "NH", caught)
  expect_equal(nrow(nh), 3)
  expect_true(all(nh$flag_state_program == "PROVENANCE_STATE_PROGRAM"))

  # The §6.2 allotment ceiling flagged this row in session 5 as impossible
  # against a $204M allotment; the provenance filter now says what it is.
  big <- nh %>% dplyr::filter(amount_announced == max(amount_announced))
  expect_equal(big$amount_announced, 1898965390)
  expect_match(big$flag_reason, "AMOUNT_EXCEEDS_STATE_ALLOTMENT")
})

test_that("Rhode Island's opioid settlement rows include a named hospital", {
  ri <- swept %>% dplyr::filter(state == "RI", caught)
  expect_equal(nrow(ri), 3)
  expect_true(any(stringr::str_detect(ri$awardee_name_raw, "Hospital")))
})


# -- The sweep as a whole ----------------------------------------------------

test_that("the sweep catches 101 rows in 9 states, and the arithmetic closes", {
  # 73 in 6 states through session 25. NEVADA ADDED 9 IN SESSION 26: the nine
  # GME Grant Round VIII residency awards, $15,755,068 of Nevada STATE GENERAL
  # FUND money that RCJ files under RHTP-titled documents. They are caught by
  # the registry entry NV-GME-ROUNDVIII, keyed on the GME release's own title.
  #
  # THE SWEEP CATCHES 9 OF NEVADA'S 17 SUCH ROWS AND THAT IS A MEASURED LIMIT,
  # NOT A SHORTFALL. The other 8 are filed by RCJ under "Nevada Home Working
  # Together RHTP 2026 Award Announcement" -- the NVHA workforce publication,
  # which IS a genuine RHTP document and carries the CMS financial-assistance
  # footer on every page while describing three programmes of which only one is
  # RHTP. No source-title-keyed rule can honestly reach those 8; they are
  # disposed of by hand in nv_rcj_candidate_disposition.csv. That gap is
  # session 26's §6.2 lesson: the CMS footer covers the PUBLICATION, not every
  # programme described in it.
  #
  # SESSION 27 ADDED MICHIGAN: 82 rows in 7 states -> 90 in 8. All eight are
  # MDHHS's youth substance-use prevention grants, which the release's own
  # sub-headline calls "New opioid settlement-funded grants". Unlike Nevada's,
  # the registry reaches ALL of them -- RCJ carries the release HEADLINE as its
  # source-document title and the first alternative matches it.
  #
  # SESSION 34 ADDED CALIFORNIA: 90 rows in 8 states -> 101 in 9, and it is the
  # largest single-state catch after Texas. All ELEVEN of California's Tier 3
  # candidates are the Small and Rural Hospital Relief Program -- a state
  # cigarette-tax seismic-compliance programme -- and ALL ELEVEN ARE NAMED
  # CALIFORNIA HOSPITALS carrying real amounts on real executed HCAI awards.
  # Texas's defect with Maine's ratio.
  #
  # AND CALIFORNIA IS CAUGHT BY BOTH FILTERS AT ONCE, which no other state's
  # rows are. The registry reaches all eleven on the source-document title, and
  # the DATE test reaches all eleven too -- because the registry row supplies
  # HCAI's own 2025-02-19 SRHRP webinar date for rows RCJ carries NO DATE FOR
  # AT ALL. New Hampshire's pattern (two §6.2 filters, one row) at the scale of
  # a whole state's candidate set.
  expect_equal(sum(swept$caught), 101)
  expect_equal(sum(by_state$caught_total > 0), 9)
  expect_equal(sum(by_state$caught_total), 101)
  expect_setequal(by_state$state[by_state$caught_total > 0],
                  c("TX", "CA", "NV", "MI", "NH", "AZ", "RI", "MS", "IL"))
})

test_that("California's caught rows are all eleven, and both filters reach them", {
  ca <- swept %>% dplyr::filter(state == "CA", caught)
  expect_equal(nrow(ca), 11)
  expect_true(all(ca$flag_state_program == "PROVENANCE_STATE_PROGRAM"))
  expect_true(all(ca$registry_program == "CA-SRHRP-SEISMIC"))
  expect_true(all(ca$registry_disposition == "NOT_RHTP_STATE_PROGRAM"))
  # Unlike Nevada's, these ARE also caught on a date: the SRHRP was soliciting
  # in February 2025, ten months before California's Notice of Award.
  expect_true(all(!is.na(ca$flag_predates_noa)))
  expect_equal(sum(ca$amount_announced), 5475000)
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
