# test_02_normalize.R ----------------------------------------------------------
# Stage 2 unit tests. Read from disk only -- no network calls, zero API quota,
# safe to run on every session start.
#
# The fixtures are Delaware's 15 Stage 0 award records and 30 document records,
# committed at data/raw/rcj/2026-08-27/_stage0_exploratory/. Every observed RCJ
# defect the spec names has a test here pinned to the actual record that
# exhibits it, so a regression names the row it broke.

library(testthat)

source(here::here("R", "02_normalize.R"))

de_awards <- jsonlite::fromJSON(
  here::here("data", "raw", "rcj", "2026-08-27", "_stage0_exploratory",
             "DE_awards.json"),
  simplifyVector = FALSE
)$data

de_documents <- jsonlite::fromJSON(
  here::here("data", "raw", "rcj", "2026-08-27", "_stage0_exploratory",
             "DE_documents.json"),
  simplifyVector = FALSE
)$data

de_classified <- rhtp_normalize_awards(de_awards) %>%
  rhtp_classify() %>%
  rhtp_mark_collisions() %>%
  rhtp_finalize_flags()

de_docs_classified <- rhtp_normalize_documents(de_documents) %>%
  rhtp_classify() %>%
  rhtp_mark_collisions() %>%
  rhtp_finalize_flags()

by_awardee <- function(tbl, pattern) {
  tbl %>% dplyr::filter(stringr::str_detect(awardee_name_clean, pattern))
}


# -- §7.1 The state vocabulary ---------------------------------------------

test_that("the state vocabulary is 50 rows and comes from CMS, not RCJ", {
  states <- rhtp_cms_states()

  expect_equal(nrow(states), 50)
  expect_true("WY" %in% states$state)   # absent from RCJ /states
  expect_false("US" %in% states$state)  # RCJ's pseudo-state
  expect_false("RC" %in% states$state)  # RCJ's junk code
})

test_that("junk state codes are quarantined, never mapped", {
  valid <- rhtp_cms_states()$state

  expect_equal(rhtp_flag_state_code("RC", valid), "JUNK_STATE_CODE")
  expect_equal(rhtp_flag_state_code("US", valid), "JUNK_STATE_CODE")
  expect_equal(rhtp_flag_state_code(NA_character_, valid), "JUNK_STATE_CODE")
  expect_true(is.na(rhtp_flag_state_code("WY", valid)))
  expect_true(is.na(rhtp_flag_state_code("DE", valid)))

  expect_equal(rhtp_qa_status("JUNK_STATE_CODE"), "QUARANTINED")
})


# -- §6.1 The named-recipient test -----------------------------------------

test_that("a populated awardeeName is not a named recipient", {
  # The two live Delaware pool rows the spec names. The first is both a pool
  # and the state agency; the agency test runs first, so it fails that way.
  # What matters is that neither reaches SUBAWARD.
  pool <- rhtp_named_recipient_test(
    "Delaware DHSS / Mobile Health Hubs Grantee Pool", "Delaware"
  )
  expect_equal(pool$result, "FAIL_STATE_AGENCY")
  expect_true(startsWith(pool$result, "FAIL_"))

  initiative <- rhtp_named_recipient_test(
    "School-Based Health Centers Expansion Initiative", "Delaware"
  )
  expect_equal(initiative$result, "FAIL_PROGRAM_NAME")

  # A pool with no agency name in it still fails on the pool pattern alone.
  bare_pool <- rhtp_named_recipient_test("Mobile Health Hubs Grantee Pool",
                                         "Delaware")
  expect_equal(bare_pool$result, "FAIL_PROGRAM_NAME")
})

test_that("the administering state agency is not a recipient", {
  agency <- rhtp_named_recipient_test(
    "Delaware Department of Health and Social Services", "Delaware"
  )
  expect_equal(agency$result, "FAIL_STATE_AGENCY")

  division <- rhtp_named_recipient_test("Delaware Division of Public Health",
                                        "Delaware")
  expect_equal(division$result, "FAIL_STATE_AGENCY")

  governor <- rhtp_named_recipient_test(
    "Executive Office of the Governor of Delaware", "Delaware"
  )
  expect_equal(governor$result, "FAIL_STATE_AGENCY")
})

test_that("agency patterns are anchored to the record's own state", {
  # The identical string must not fail on a Georgia record.
  expect_equal(
    rhtp_named_recipient_test("Delaware Division of Public Health",
                              "Georgia")$result,
    "PASS"
  )
})

test_that("an empty awardeeName fails rather than passing silently", {
  expect_equal(rhtp_named_recipient_test(NA_character_, "Delaware")$result,
               "FAIL_EMPTY")
  expect_equal(rhtp_named_recipient_test("   ", "Delaware")$result,
               "FAIL_EMPTY")
})

test_that("§6.1 'do not over-filter': real non-hospital entities still pass", {
  # The spec's own example. A legitimate non-hospital recipient belongs in
  # Tier 3 as a No, not quarantined out of the table.
  housing <- rhtp_named_recipient_test("Delaware State Housing Authority",
                                       "Delaware")
  expect_equal(housing$result, "PASS")

  fqhc <- rhtp_named_recipient_test("La Red Health Center, Inc.", "Delaware")
  expect_equal(fqhc$result, "PASS")
})

test_that("a legal-entity suffix overrides a programme-name match", {
  # Live cases: `program` and `expansion` are also how real institutions are
  # named. All three of these are genuine recipients.
  expect_equal(
    rhtp_named_recipient_test("Rural Health Medical Program Inc.",
                              "Alabama")$result,
    "PASS"
  )
  expect_equal(
    rhtp_named_recipient_test(
      "University of Nevada, Reno General Surgery Residency Program",
      "Nevada")$result,
    "PASS"
  )
  expect_equal(
    rhtp_named_recipient_test(
      "Dignity Health Dominican Hospital Internal Medicine Resident Training Expansion Program",
      "California")$result,
    "PASS"
  )
})

test_that("an explicit unresolved marker beats the entity override", {
  # Contains `hospitals`, and still names nobody.
  expect_equal(
    rhtp_named_recipient_test(
      "16 Strategically Located Rural Hospitals (unnamed, subrecipient group)",
      "Kansas")$result,
    "FAIL_PROGRAM_NAME"
  )
  # Contains `clinics`, and still names nobody.
  expect_equal(
    rhtp_named_recipient_test("Various Rural Health Clinics", "Texas")$result,
    "FAIL_PROGRAM_NAME"
  )
})

test_that("the state-agency test wins over an entity override", {
  # `Authority` must not rescue the administering agency.
  expect_equal(
    rhtp_named_recipient_test("Oklahoma Department of Education (OSDE) - School-based health services",
                              "Oklahoma")$result,
    "FAIL_STATE_AGENCY"
  )
})


# -- §6.1 Tier assignment --------------------------------------------------

test_that("an unassignable record is UNASSIGNED, never SUBAWARD", {
  tier <- rhtp_assign_tier("awards", named_recipient_test = "FAIL_PROGRAM_NAME",
                           amount = 20e6)
  expect_equal(tier$award_tier, "UNASSIGNED")
  expect_false(tier$award_tier == "SUBAWARD")
  expect_true(nzchar(tier$tier_basis))

  empty <- rhtp_assign_tier("awards", named_recipient_test = "FAIL_EMPTY")
  expect_equal(empty$award_tier, "UNASSIGNED")

  agency <- rhtp_assign_tier("awards", named_recipient_test = "FAIL_STATE_AGENCY",
                             amount = 10e6)
  expect_equal(agency$award_tier, "UNASSIGNED")
})

test_that("no Delaware fixture row is ever tiered SUBAWARD on a failed test", {
  failed <- de_classified %>%
    dplyr::filter(named_recipient_test != "PASS")

  expect_gt(nrow(failed), 0)
  expect_true(all(failed$award_tier == "UNASSIGNED"))
})

test_that("rule 1 tiers a solicitation type without needing an amount", {
  expect_equal(rhtp_assign_tier("opportunities", rcj_type = "RFA")$award_tier,
               "SOLICITATION")
  expect_equal(rhtp_assign_tier("opportunities", rcj_type = "NOFO")$award_tier,
               "SOLICITATION")
  expect_equal(rhtp_assign_tier("documents", rcj_type = "APPLICATION")$award_tier,
               "SOLICITATION")
})

test_that("rule 3 matches a rounded state allotment when the anchor exists", {
  # Missouri FY2026, $216.0M as announced against a hypothetical exact figure.
  tier <- rhtp_assign_tier("documents", named_recipient_test = "NOT_APPLICABLE",
                           amount = 216000000, allotment = 215957000)
  expect_equal(tier$award_tier, "STATE_ALLOTMENT")

  # An award a long way off the allotment must not be swept into Tier 1.
  not_tier1 <- rhtp_assign_tier("documents",
                                named_recipient_test = "NOT_APPLICABLE",
                                amount = 750000, allotment = 215957000)
  expect_equal(not_tier1$award_tier, "UNASSIGNED")
})

test_that("without the CMS anchor rule 3 is skipped and says so", {
  tier <- rhtp_assign_tier("documents", named_recipient_test = "NOT_APPLICABLE",
                           amount = 216000000, allotment = NA_real_)
  expect_equal(tier$award_tier, "UNASSIGNED")
  expect_match(tier$tier_basis, "no CMS allotment anchor")
})

test_that("the Delaware State Housing Authority row is Tier 3 and clean", {
  # The spec's explicit do-not-over-filter case: a genuine named recipient
  # that is not a hospital.
  row <- by_awardee(de_classified, "State Housing Authority")

  expect_equal(nrow(row), 1)
  expect_equal(row$award_tier, "SUBAWARD")
  expect_equal(row$qa_status, "PASS")
  expect_true(is.na(row$flag_reason))
})


# -- §6.2 Junk filters -----------------------------------------------------

test_that("HRSA-sourced records are quarantined as PROVENANCE_MISMATCH", {
  # The four Delaware rows tracing to a HRSA Rural Health Grants fact sheet:
  # real rural health awards, wrong federal programme.
  hrsa <- de_classified %>%
    dplyr::filter(stringr::str_detect(source_doc_title, "HRSA"))

  expect_equal(nrow(hrsa), 4)
  expect_true(all(stringr::str_detect(hrsa$flag_reason, "PROVENANCE_MISMATCH")))
  expect_true(all(hrsa$qa_status == "QUARANTINED"))
})

test_that("a hospital-shaped HRSA recipient is still quarantined", {
  # La Red Health Center is a real FQHC and passes the named-recipient test.
  # The money is HRSA's, so the row must not reach a published RHTP figure.
  la_red <- by_awardee(de_classified, "La Red")

  expect_equal(la_red$named_recipient_test, "PASS")
  expect_equal(la_red$award_tier, "SUBAWARD")
  expect_equal(la_red$qa_status, "QUARANTINED")
  expect_match(la_red$flag_reason, "PROVENANCE_MISMATCH")
})

test_that("other non-RHTP federal programmes are caught too", {
  expect_equal(rhtp_flag_provenance("USDA Rural Development Community Facilities Loan"),
               "PROVENANCE_MISMATCH")
  expect_equal(rhtp_flag_provenance("FCC Rural Health Care Program - Healthcare Connect Fund"),
               "PROVENANCE_MISMATCH")
  expect_equal(rhtp_flag_provenance("Medicare Rural Hospital Flexibility (Flex) Program"),
               "PROVENANCE_MISMATCH")
  expect_true(is.na(rhtp_flag_provenance("GA - 2026 - Notice of Intent to Award")))
})

test_that("federalAmount 1 is caught where a zero-test would miss it", {
  ones <- de_classified %>% dplyr::filter(amount_announced == 1)

  expect_equal(nrow(ones), 4)
  expect_true(all(stringr::str_detect(ones$flag_reason, "AMOUNT_IMPLAUSIBLE_LOW")))

  expect_equal(rhtp_flag_amount(1, "SUBAWARD"), "AMOUNT_IMPLAUSIBLE_LOW")
  expect_equal(rhtp_flag_amount(0, "SUBAWARD"), "AMOUNT_IMPLAUSIBLE_LOW")
  expect_equal(rhtp_flag_amount(999, "SUBAWARD"), "AMOUNT_IMPLAUSIBLE_LOW")
  expect_true(is.na(rhtp_flag_amount(1000, "SUBAWARD")))
})

test_that("unit errors and over-allotment amounts are flagged", {
  expect_equal(rhtp_flag_amount(50e9, "SUBAWARD"), "AMOUNT_IMPLAUSIBLE_HIGH")

  over <- rhtp_flag_amount(300e6, "SUBAWARD", allotment = 216e6)
  expect_true("AMOUNT_EXCEEDS_STATE_ALLOTMENT" %in% over)

  # Tier 1 is allowed to equal the allotment.
  expect_true(is.na(rhtp_flag_amount(216e6, "STATE_ALLOTMENT", allotment = 216e6)))
})

test_that("a missing amount is a defect on an award and normal elsewhere", {
  expect_equal(rhtp_flag_amount(NA_real_, "SUBAWARD", amount_expected = TRUE),
               "AMOUNT_MISSING")
  expect_true(is.na(rhtp_flag_amount(NA_real_, "SOLICITATION",
                                     amount_expected = FALSE)))
})

test_that("page chrome captured as a title is flagged", {
  expect_equal(rhtp_flag_title_junk("Here's how you know. Resources"),
               "PAGE_CHROME_TITLE")
  expect_equal(rhtp_flag_title_junk("Press Alt+1 for screen-reader mode"),
               "PAGE_CHROME_TITLE")
  expect_equal(rhtp_flag_title_junk("Browse.aspx"), "PAGE_CHROME_TITLE")
  expect_equal(rhtp_flag_title_junk("DE - 2028 - portal"), "PAGE_CHROME_TITLE")
  expect_true(is.na(rhtp_flag_title_junk(
    "GA - 2026 - Notice of Intent to Award: Dual Track Remote Critical Care"
  )))
})

test_that("self-declared non-RHTP records are quarantined", {
  expect_equal(
    rhtp_flag_self_declared("This document does not relate to the RHTP."),
    "NON_RHTP_SELF_DECLARED"
  )
  expect_equal(
    rhtp_flag_self_declared("Perkins CTE Career and Technical Education plan"),
    "NON_RHTP_SELF_DECLARED"
  )
  expect_true(is.na(rhtp_flag_self_declared(
    "Rural Health Transformation Program award to a critical access hospital."
  )))
})

test_that("event-schedule bleed is caught on the live Delaware record", {
  # Eight keyDates carrying a Dolly Parton library statement, four Attorney
  # General items, a hunting season, and a firearms arrest.
  meyer <- de_docs_classified %>%
    dplyr::filter(stringr::str_detect(source_doc_title, "Four New School-Based"))

  expect_equal(nrow(meyer), 1)
  expect_equal(length(meyer$event_texts[[1]]), 8)
  expect_match(meyer$flag_reason, "EVENT_SCHEDULE_BLEED")
})

test_that("a genuine schedule is not flagged as bleed", {
  # Nine federal award and budget-period dates on Delaware's notice of award.
  noa <- de_docs_classified %>%
    dplyr::filter(stringr::str_detect(source_doc_title, "Notice of Award for Delaware"))

  expect_equal(nrow(noa), 1)
  expect_false(stringr::str_detect(dplyr::coalesce(noa$flag_reason, ""),
                                   "EVENT_SCHEDULE_BLEED"))
})

test_that("the bleed test ignores RCJ's own echo of the schedule", {
  # highlights ends with a literal "Event schedule:" block repeating every
  # keyDates entry, which would otherwise make overlap 100% by construction.
  parent <- paste(
    "Governor Meyer Announces Funding for School-Based Health Centers",
    "Delaware is funding four new centers in Sussex County.",
    "\nEvent schedule:\n- Statement from Delaware Libraries on Dolly Parton",
    sep = " "
  )
  stripped <- rhtp_strip_event_schedule(parent)

  expect_false(stringr::str_detect(stripped, "Dolly Parton"))
  expect_true(stringr::str_detect(stripped, "Sussex County"))
})

test_that("bleed needs at least three entries to judge", {
  expect_true(is.na(rhtp_flag_event_bleed(c("boiler replacement",
                                            "latrine renovation"),
                                          "rural hospital award")))
})


# -- §6.3 Hashing, dedup, change detection ---------------------------------

test_that("the hash is stable and sensitive to a substantive change", {
  base <- tibble::tibble(state = "DE", amount_announced = 250000,
                         awardee_name_raw = "La Red Health Center, Inc.")
  changed <- base %>% dplyr::mutate(amount_announced = 260000)

  expect_equal(rhtp_record_hash(base), rhtp_record_hash(base))
  expect_false(identical(rhtp_record_hash(base), rhtp_record_hash(changed)))
})

test_that("a derived field does not make a record read as changed", {
  # rules_version is not in RHTP_HASH_FIELDS, so bumping it must not fire
  # change detection across every row in the table.
  expect_false("rules_version" %in% RHTP_HASH_FIELDS)
  expect_false("award_tier" %in% RHTP_HASH_FIELDS)
  expect_false("flag_reason" %in% RHTP_HASH_FIELDS)
})

test_that("the Delaware duplicate $10M rows collide and are not merged", {
  dupes <- de_classified %>%
    dplyr::filter(stringr::str_detect(dplyr::coalesce(flag_reason, ""),
                                      "CONTENT_DUPLICATE"))

  expect_gt(nrow(dupes), 1)
  expect_true(all(dupes$amount_announced == 10e6))
  # Not merged: every colliding row is still present.
  expect_equal(nrow(de_classified), length(de_awards))
})

test_that("a uniform grant programme is not a content duplicate", {
  # 99 Oregon awards of exactly $100,000 to 99 distinct named providers.
  uniform <- tibble::tibble(
    source_endpoint = "awards",
    state = "OR",
    amount_announced = 100000,
    activity_type_raw = "AWARD",
    awardee_name_clean = paste("Provider", 1:99),
    named_recipient_test = "PASS",
    solicitation_number = NA_character_
  ) %>%
    dplyr::mutate(dedup_key = purrr::pmap_chr(
      list(source_endpoint, state, amount_announced, activity_type_raw),
      rhtp_dedup_key
    )) %>%
    rhtp_mark_collisions()

  expect_true(all(is.na(uniform$collision_flags)))
})

test_that("a repeated awardee at the same amount still collides", {
  repeated <- tibble::tibble(
    source_endpoint = "awards",
    state = "AK",
    amount_announced = 100000,
    activity_type_raw = "Health Care Access",
    awardee_name_clean = c("Same Provider", "Same Provider"),
    named_recipient_test = "PASS",
    solicitation_number = NA_character_
  ) %>%
    dplyr::mutate(dedup_key = purrr::pmap_chr(
      list(source_endpoint, state, amount_announced, activity_type_raw),
      rhtp_dedup_key
    )) %>%
    rhtp_mark_collisions()

  expect_true(all(repeated$collision_flags == "CONTENT_DUPLICATE"))
})

test_that("the dedup key separates endpoints", {
  award_key <- rhtp_dedup_key("awards", "MO", 216e6, "OTHER")
  doc_key   <- rhtp_dedup_key("documents", "MO", 216e6, "OTHER")

  expect_false(identical(award_key, doc_key))
})

test_that("state solicitation numbers are extracted for the re-opening trap", {
  expect_equal(
    rhtp_extract_solicitation_number("RHT-AFA-04-28-2026-MSC3 Amendment 2"),
    "RHT-AFA-04-28-2026-MSC3"
  )
  expect_equal(
    rhtp_extract_solicitation_number("WV - 2026 - RHT-AFA-06-12-2026-CCG County Community Grant"),
    "RHT-AFA-06-12-2026-CCG"
  )
  expect_true(is.na(rhtp_extract_solicitation_number("Notice of Award")))
})

test_that("a first run marks everything NEW and dates it", {
  current <- tibble::tibble(
    record_id = c("a", "b"),
    rcj_record_hash = c("h1", "h2")
  )

  out <- rhtp_apply_change_detection(current, NULL, as.Date("2026-08-27"))

  expect_equal(nrow(out), 2)
  expect_true(all(out$change_status == "NEW"))
  expect_true(all(out$first_seen == "2026-08-27"))
  expect_true(all(is.na(out$superseded_by)))
})

test_that("a changed record keeps its prior version and inherits first_seen", {
  prior <- rhtp_apply_change_detection(
    tibble::tibble(record_id = c("a", "b"), rcj_record_hash = c("h1", "h2")),
    NULL, as.Date("2026-08-27")
  )

  current <- tibble::tibble(
    record_id = c("a", "b", "c"),
    rcj_record_hash = c("h1", "h2_CHANGED", "h3")
  )

  out <- rhtp_apply_change_detection(current, prior, as.Date("2026-09-03"))

  # Nothing is overwritten: both versions of b are present.
  expect_equal(sum(out$record_id == "b"), 2)

  old_b <- out %>% dplyr::filter(record_id == "b", rcj_record_hash == "h2")
  new_b <- out %>% dplyr::filter(record_id == "b",
                                 rcj_record_hash == "h2_CHANGED")

  expect_false(is.na(old_b$superseded_by))
  expect_equal(old_b$superseded_by, new_b$row_uid)
  expect_equal(new_b$change_status, "CHANGED")
  # The record was first seen in the earlier pull, not this one.
  expect_equal(new_b$first_seen, "2026-08-27")
  expect_equal(new_b$last_seen, "2026-09-03")

  # An unchanged record refreshes last_seen without a second version.
  a <- out %>% dplyr::filter(record_id == "a")
  expect_equal(nrow(a), 1)
  expect_equal(a$change_status, "UNCHANGED")
  expect_equal(a$last_seen, "2026-09-03")

  expect_equal(out %>% dplyr::filter(record_id == "c") %>% dplyr::pull(change_status),
               "NEW")
})

test_that("a record that vanishes from the feed is marked, never deleted", {
  prior <- rhtp_apply_change_detection(
    tibble::tibble(record_id = c("a", "b"), rcj_record_hash = c("h1", "h2")),
    NULL, as.Date("2026-08-27")
  )

  out <- rhtp_apply_change_detection(
    tibble::tibble(record_id = "a", rcj_record_hash = "h1"),
    prior, as.Date("2026-09-03")
  )

  b <- out %>% dplyr::filter(record_id == "b")
  expect_equal(nrow(b), 1)
  expect_equal(b$change_status, "WITHDRAWN")
})


# -- Vocabulary conformance (§8, §13.6) ------------------------------------

test_that("every categorical value Stage 2 emits is in the vocabulary", {
  vocab <- readr::read_csv(
    here::here("data", "reference", "vocabularies.csv"),
    show_col_types = FALSE, progress = FALSE
  )

  allowed <- function(column) {
    vocab %>% dplyr::filter(column_name == column) %>% dplyr::pull(allowed_value)
  }

  expect_true(all(de_classified$award_tier %in% allowed("award_tier")))
  expect_true(all(de_classified$qa_status %in% allowed("qa_status")))
  expect_true(all(de_classified$named_recipient_test %in%
                    allowed("named_recipient_test")))
  expect_true(all(de_classified$source_endpoint %in% allowed("source_endpoint")))

  emitted_flags <- de_classified$flag_reason %>%
    purrr::map(rhtp_flag_vector) %>%
    unlist() %>%
    unique()
  expect_true(all(emitted_flags %in% allowed("flag_reason")))
})

test_that("qa_status follows from the flag set", {
  expect_equal(rhtp_qa_status(NA_character_), "PASS")
  expect_equal(rhtp_qa_status("AMOUNT_IMPLAUSIBLE_LOW"), "FLAGGED")
  expect_equal(rhtp_qa_status("AMOUNT_IMPLAUSIBLE_LOW;PROVENANCE_MISMATCH"),
               "QUARANTINED")
})

test_that("flags collapse and split round-trip", {
  collapsed <- rhtp_collapse_flags(c("B_FLAG", "A_FLAG", "A_FLAG", NA))
  expect_equal(collapsed, "A_FLAG;B_FLAG")
  expect_equal(rhtp_flag_vector(collapsed), c("A_FLAG", "B_FLAG"))
  expect_equal(rhtp_flag_vector(NA_character_), character())
})


# -- Guards ----------------------------------------------------------------

test_that("the Stage 0 exploratory directory cannot be normalized", {
  expect_error(rhtp_pull_dir("2026-08-27/_stage0_exploratory"),
               "double-count Delaware")
})

test_that("the manifest schema is pinned", {
  expect_error(
    rhtp_append_normalize_manifest(tibble::tibble(pull_date = "2026-08-27")),
    "missing"
  )
})


# -- Normalization fidelity ------------------------------------------------

test_that("normalizing loses no records and keeps raw values verbatim", {
  expect_equal(nrow(de_classified), length(de_awards))
  expect_equal(nrow(rhtp_normalize_documents(de_documents)), length(de_documents))

  # activity_type_raw is never discarded (§8), and activity_type stays NA
  # because the CMS allowable-use crosswalk is not a Stage 2 job.
  expect_true(all(is.na(de_classified$activity_type)))
  expect_equal(
    sort(dplyr::coalesce(de_classified$activity_type_raw, "")),
    sort(purrr::map_chr(de_awards,
                        ~ dplyr::coalesce(as.character(.x$activityType), "")))
  )

  # The en dash and curly apostrophe in the live Delaware awardee names
  # survive into awardee_name_raw.
  expect_true(any(stringr::str_detect(de_classified$awardee_name_raw, "–")))
  expect_true(any(stringr::str_detect(de_classified$awardee_name_raw, "’")))
})

test_that("fiscal years from both endpoints normalize to the same shape", {
  expect_equal(rhtp_normalize_fiscal_year("FY2026"), "FY2026")
  expect_equal(rhtp_normalize_fiscal_year("2026"), "FY2026")
  expect_true(is.na(rhtp_normalize_fiscal_year(NA)))
})


# -- §6.4 Tier 3 candidate mining from /documents --------------------------

test_that("a dollar figure is found in both renderings states publish", {
  expect_true(rhtp_has_money("Awarded $52,000,000 to four hospitals"))
  expect_true(rhtp_has_money("a $11.5M notice of award"))
  expect_true(rhtp_has_money("$900K for remote critical care"))
  # The live §6.4 example carries no dollar sign at all.
  expect_true(rhtp_has_money(
    "Parrish Medical Center Awarded More Than 52 Million in Grants"
  ))

  # A bare year is not money, which is what a naive \\d+ pattern would call it.
  expect_false(rhtp_has_money("DE - 2028 - portal"))
  expect_false(rhtp_has_money("Budget period 1 opens October 1"))
  expect_false(rhtp_has_money(NA_character_))
  expect_false(rhtp_has_money(""))
})

test_that("organisation names are extracted out of running prose", {
  spans <- rhtp_extract_org_candidates(
    "FL - 2026 - Parrish Medical Center Awarded More Than 52 Million in Grants"
  )
  expect_true("Parrish Medical Center" %in% spans)

  expect_true("Tennessee Hospital Association" %in% rhtp_extract_org_candidates(
    "TN - 2026 - Tennessee Hospital Association RHTP Compliance Requirements"
  ))
  expect_true(any(stringr::str_detect(
    rhtp_extract_org_candidates("Grant to University of Nevada, Reno"),
    "University of Nevada"
  )))

  # Nothing entity-shaped in the text at all.
  expect_length(rhtp_extract_org_candidates("Budget period 1 opens soon"), 0)
  expect_length(rhtp_extract_org_candidates(NA_character_), 0)
})

test_that("the §6.1 legal-entity test is the arbiter, not the finder", {
  expect_true(rhtp_legal_entity_test("Parrish Medical Center"))
  expect_true(rhtp_legal_entity_test("Rural Health Medical Program Inc."))
  expect_true(rhtp_legal_entity_test("University of Nevada, Reno"))

  # An explicit statement that the recipient is unresolved beats the marker,
  # exactly as it does inside the §6.1 named-recipient test.
  expect_false(rhtp_legal_entity_test(
    "16 Strategically Located Rural Hospitals (unnamed, subrecipient group)"
  ))
  expect_false(rhtp_legal_entity_test("Various Rural Health Clinics"))
  expect_false(rhtp_legal_entity_test("Mobile Health Hubs Grantee Pool"))
  expect_false(rhtp_legal_entity_test(NA_character_))
})

mining_fixture <- function(...) {
  base <- rhtp_record_skeleton(1) %>%
    dplyr::mutate(
      source_endpoint = "documents",
      state = "FL",
      state_name = "Florida",
      source_doc_category = "REFERENCE",
      qa_status = "PASS",
      award_tier = "UNASSIGNED"
    )
  base %>% dplyr::mutate(...)
}

test_that("the live §6.4 example is mined", {
  records <- mining_fixture(
    record_id = "doc-fl-1",
    source_doc_id = "doc-fl-1",
    source_doc_title = paste(
      "FL - 2026 - Parrish Medical Center Awarded More Than 52 Million in",
      "Grants to Promote Rural Health Workforce Development"
    )
  )

  mined <- rhtp_mine_document_candidates(records)

  expect_equal(nrow(mined), 1)
  expect_equal(mined$state, "FL")
  expect_equal(mined$mined_org_name, "Parrish Medical Center")
  expect_match(mined$mining_basis, "never")
})

test_that("a document /awards already parsed is not mined again", {
  records <- dplyr::bind_rows(
    mining_fixture(
      record_id = "doc-1", source_doc_id = "doc-1",
      source_doc_title = "GA - 2026 - Grady Memorial Hospital Awarded $2,000,000"
    ),
    rhtp_record_skeleton(1) %>%
      dplyr::mutate(
        record_id = "award-1", source_endpoint = "awards", state = "GA",
        source_doc_id = "doc-1", qa_status = "PASS", award_tier = "SUBAWARD"
      )
  )

  expect_equal(nrow(rhtp_mine_document_candidates(records)), 0)
})

test_that("only AWARD_ANNOUNCEMENT and REFERENCE are in the mining pool", {
  for (category in c("APPLICATION", "GUIDANCE", "DATA", "STRATEGY")) {
    records <- mining_fixture(
      record_id = "d", source_doc_id = "d", source_doc_category = category,
      source_doc_title = "Parrish Medical Center Awarded $52,000,000"
    )
    expect_equal(nrow(rhtp_mine_document_candidates(records)), 0,
                 info = category)
  }

  for (category in c("AWARD_ANNOUNCEMENT", "REFERENCE")) {
    records <- mining_fixture(
      record_id = "d", source_doc_id = "d", source_doc_category = category,
      source_doc_title = "Parrish Medical Center Awarded $52,000,000"
    )
    expect_equal(nrow(rhtp_mine_document_candidates(records)), 1,
                 info = category)
  }
})

test_that("a quarantined record is not made minable by naming a hospital", {
  # A HRSA fact sheet or a junk state code is out of the RHTP universe
  # entirely; containing a hospital's name does not bring it back in.
  records <- mining_fixture(
    record_id = "d", source_doc_id = "d", qa_status = "QUARANTINED",
    source_doc_title = "Parrish Medical Center Awarded $52,000,000"
  )
  expect_equal(nrow(rhtp_mine_document_candidates(records)), 0)
})

test_that("all four §6.4 conditions are required, not any of them", {
  # No money.
  expect_equal(nrow(rhtp_mine_document_candidates(mining_fixture(
    record_id = "d", source_doc_id = "d",
    source_doc_title = "Parrish Medical Center Opens New Wing"
  ))), 0)

  # No named organisation.
  expect_equal(nrow(rhtp_mine_document_candidates(mining_fixture(
    record_id = "d", source_doc_id = "d",
    source_doc_title = "State announces $52,000,000 in rural funding"
  ))), 0)

  # A pool is not a named organisation, however entity-shaped the words.
  expect_equal(nrow(rhtp_mine_document_candidates(mining_fixture(
    record_id = "d", source_doc_id = "d",
    source_doc_title = "Various Rural Health Clinics share $52,000,000"
  ))), 0)
})

test_that("mining never promotes anything to SUBAWARD (§6.4, §13.18)", {
  records <- mining_fixture(
    record_id = "doc-fl-1", source_doc_id = "doc-fl-1",
    source_doc_title = "Parrish Medical Center Awarded $52,000,000"
  )

  mined <- rhtp_mine_document_candidates(records)

  expect_equal(nrow(mined), 1)
  # The candidate table carries no tier column at all, and the record it
  # points at is still UNASSIGNED. The whole premise of §6.4 is that RCJ's
  # extraction of this text failed, so a second automated extraction of the
  # same text has earned no more trust than the first.
  expect_false("award_tier" %in% names(mined))
  expect_equal(
    records$award_tier[records$record_id == mined$record_id], "UNASSIGNED"
  )
})

test_that("an empty record table mines to an empty, correctly-shaped table", {
  mined <- rhtp_mine_document_candidates(rhtp_record_skeleton(0))
  expect_equal(nrow(mined), 0)
  expect_true(all(c("record_id", "state", "mined_org_name", "mining_basis")
                  %in% names(mined)))
})

test_that("coverage separates 'no data' from 'source failed to extract'", {
  records <- dplyr::bind_rows(
    # GA: RCJ parsed awards AND candidates remain.
    rhtp_record_skeleton(1) %>% dplyr::mutate(
      record_id = "a1", source_endpoint = "awards", state = "GA",
      award_tier = "SUBAWARD", qa_status = "PASS"
    ),
    # NE: parsed, nothing left over.
    rhtp_record_skeleton(1) %>% dplyr::mutate(
      record_id = "a2", source_endpoint = "awards", state = "NE",
      award_tier = "SUBAWARD", qa_status = "PASS"
    )
  )

  candidates <- tibble::tibble(state = c("GA", "FL"))

  coverage <- rhtp_mining_coverage(records, candidates)

  expect_equal(nrow(coverage), 50)
  status <- function(st) coverage$coverage_status[coverage$state == st]

  expect_equal(status("GA"), "PARSED_PLUS_CANDIDATES")
  expect_equal(status("NE"), "PARSED")
  # Florida: RCJ produced no award record, but award-shaped data exists. That
  # is a materially different message than "no data" (§4.1, §11).
  expect_equal(status("FL"), "UNPARSED_DATA_EXISTS")
  expect_equal(status("WY"), "NO_RCJ_DATA")
})


# -- §7.1 The CMS allotment anchor, as Stage 2 sees it ---------------------

test_that("Stage 2 reads the anchor from the CMS file, not the registry", {
  skip_if_not(file.exists(rhtp_path("cms_allotments")),
              "cms_fy2026_allotments.csv not built yet")

  allotments <- rhtp_load_allotments()

  expect_equal(nrow(allotments), 50)
  expect_setequal(names(allotments), c("state", "fy2026_allotment"))
  expect_equal(allotments$fy2026_allotment[allotments$state == "MO"],
               216276818)
})

test_that("tier rule 3 fires on a rounded state announcement", {
  # Missouri publishes $216.0M against a true allotment of $216,276,818: the
  # rounding §6.1 rule 3's tolerance exists for.
  assigned <- rhtp_assign_tier(
    source_endpoint = "documents", rcj_type = "ANNOUNCEMENT",
    named_recipient_test = "NOT_APPLICABLE",
    amount = 216000000, allotment = 216276818
  )
  expect_equal(assigned$award_tier, "STATE_ALLOTMENT")
})

test_that("a named recipient still beats the allotment match", {
  # Rule 2 precedes rule 3. A subaward that happens to equal the state's
  # allotment is still a subaward -- Tier 3 must never be drained into Tier 1.
  assigned <- rhtp_assign_tier(
    source_endpoint = "awards", rcj_type = NA_character_,
    named_recipient_test = "PASS",
    amount = 216276818, allotment = 216276818
  )
  expect_equal(assigned$award_tier, "SUBAWARD")
})

test_that("without the anchor, rule 3 says so instead of silently passing", {
  assigned <- rhtp_assign_tier(
    source_endpoint = "documents", rcj_type = "ANNOUNCEMENT",
    named_recipient_test = "NOT_APPLICABLE",
    amount = 216000000, allotment = NA_real_
  )
  expect_equal(assigned$award_tier, "UNASSIGNED")
  expect_match(assigned$tier_basis, "Rule 3 was skipped")
})


# -- Change detection re-derives, it does not freeze (§13.10) --------------

test_that("an unchanged record picks up this build's classification", {
  prior <- rhtp_apply_change_detection(
    tibble::tibble(record_id = "a", rcj_record_hash = "h1",
                   award_tier = "UNASSIGNED", rules_version = "0.0.1"),
    NULL, as.Date("2026-08-27")
  )

  # Same payload, so the hash is unchanged -- but the reference data the
  # classifier reads has since landed, and the tier moved.
  current <- tibble::tibble(record_id = "a", rcj_record_hash = "h1",
                            award_tier = "STATE_ALLOTMENT",
                            rules_version = "0.1.0")

  out <- rhtp_apply_change_detection(current, prior, as.Date("2026-09-03"))

  expect_equal(nrow(out), 1)
  expect_equal(out$change_status, "UNCHANGED")
  # Not superseded: the DATA did not change, only our reading of it (§6.3).
  expect_true(is.na(out$superseded_by))
  # But the stored row must not freeze the prior build's rules generation,
  # or §13.10 fails silently on a table mixing rule versions.
  expect_equal(out$award_tier, "STATE_ALLOTMENT")
  expect_equal(out$rules_version, "0.1.0")
  expect_equal(out$first_seen, "2026-08-27")
  expect_equal(out$last_seen, "2026-09-03")

  moved <- attr(out, "reclassified")
  expect_equal(nrow(moved), 1)
  expect_equal(moved$prior_award_tier, "UNASSIGNED")
  expect_equal(moved$award_tier, "STATE_ALLOTMENT")
})

test_that("a superseded historical row keeps the tier it was published with", {
  prior <- rhtp_apply_change_detection(
    tibble::tibble(record_id = "a", rcj_record_hash = "h1",
                   award_tier = "UNASSIGNED", rules_version = "0.0.1"),
    NULL, as.Date("2026-08-27")
  )

  current <- tibble::tibble(record_id = "a", rcj_record_hash = "h2",
                            award_tier = "SUBAWARD", rules_version = "0.1.0")

  out <- rhtp_apply_change_detection(current, prior, as.Date("2026-09-03"))

  old_row <- out %>% dplyr::filter(rcj_record_hash == "h1")
  expect_equal(nrow(old_row), 1)
  expect_false(is.na(old_row$superseded_by))
  expect_equal(old_row$award_tier, "UNASSIGNED")
  expect_equal(old_row$rules_version, "0.0.1")
})


# -- §0.2a Tier 1 corroboration --------------------------------------------

tier1_fixture <- function(...) {
  rhtp_record_skeleton(1) %>%
    dplyr::mutate(award_tier = "STATE_ALLOTMENT", source_endpoint = "documents",
                  ...)
}

fixture_allotments <- tibble::tibble(
  state = c("MO", "TX", "NE"),
  fy2026_allotment = c(216276818, 281319361, 218529075)
)

test_that("an exact restatement of the CMS figure reads EXACT", {
  out <- rhtp_corroborate_state_allotments(
    tier1_fixture(record_id = "a", state = "TX", amount_announced = 281319361),
    fixture_allotments
  )
  expect_equal(out$tier1_agreement, "EXACT")
  expect_equal(out$delta, 0)
})

test_that("a rounded restatement reads ROUNDED, not EXACT", {
  # Missouri publishes $216.0M against a true $216,276,818. Rule 3 matched it,
  # and it is still not the number to publish (§0.2a).
  out <- rhtp_corroborate_state_allotments(
    tier1_fixture(record_id = "a", state = "MO", amount_announced = 216000000),
    fixture_allotments
  )
  expect_equal(out$tier1_agreement, "ROUNDED")
  expect_equal(out$delta, 216000000 - 216276818)
})

test_that("a record beyond rule 3's tolerance is reported as a rule-3 defect", {
  out <- rhtp_corroborate_state_allotments(
    tier1_fixture(record_id = "a", state = "NE", amount_announced = 100000),
    fixture_allotments
  )
  # Never silently dropped: reaching Tier 1 from here means rule 3 fired on
  # something it should not have.
  expect_equal(out$tier1_agreement, "DISAGREES")
})

test_that("a Tier 1 record with no amount is reported, not skipped", {
  out <- rhtp_corroborate_state_allotments(
    tier1_fixture(record_id = "a", state = "MO", amount_announced = NA_real_),
    fixture_allotments
  )
  expect_equal(out$tier1_agreement, "NO_AMOUNT")
})

test_that("only Tier 1 records are corroborated", {
  records <- dplyr::bind_rows(
    tier1_fixture(record_id = "a", state = "TX", amount_announced = 281319361),
    rhtp_record_skeleton(1) %>% dplyr::mutate(
      record_id = "b", state = "TX", award_tier = "SUBAWARD",
      amount_announced = 281319361, source_endpoint = "awards"
    )
  )
  out <- rhtp_corroborate_state_allotments(records, fixture_allotments)
  expect_equal(nrow(out), 1)
  expect_equal(out$record_id, "a")
})

test_that("with no anchor on disk the check returns empty, never a pass", {
  out <- rhtp_corroborate_state_allotments(
    tier1_fixture(record_id = "a", state = "TX", amount_announced = 1),
    tibble::tibble(state = character(), fy2026_allotment = numeric())
  )
  expect_equal(nrow(out), 0)
})

test_that("the state roll-up keeps states with no Tier 1 record", {
  corroboration <- rhtp_corroborate_state_allotments(
    dplyr::bind_rows(
      tier1_fixture(record_id = "a", state = "TX", amount_announced = 281319361),
      tier1_fixture(record_id = "b", state = "MO", amount_announced = 216000000)
    ),
    fixture_allotments
  )

  summary_tbl <- rhtp_tier1_state_summary(corroboration)

  expect_equal(nrow(summary_tbl), 50)
  status <- function(st) summary_tbl$rcj_tier1_status[summary_tbl$state == st]

  expect_equal(status("TX"), "CMS_FIGURE_RESTATED")
  # Missouri's only record is rounded: publishing Tier 1 from RCJ would give
  # Missouri a wrong figure. That is the §0.2a case.
  expect_equal(status("MO"), "ROUNDED_ONLY")
  # A state with no Tier 1 record at all is kept and named, not dropped.
  expect_equal(status("WY"), "NO_RCJ_TIER1_RECORD")
  expect_equal(summary_tbl$n_tier1_records[summary_tbl$state == "WY"], 0)
})

test_that("the live table's Tier 1 records all sit inside rule 3's tolerance", {
  skip_if_not(file.exists(rhtp_path("interim", "stage2_record_table.rds")),
              "no Stage 2 output on disk")
  skip_if_not(file.exists(rhtp_path("cms_allotments")),
              "no CMS anchor on disk")

  live <- readRDS(rhtp_path("interim", "stage2_record_table.rds")) %>%
    dplyr::filter(is.na(superseded_by))
  out <- rhtp_corroborate_state_allotments(live)

  # DISAGREES or NO_AMOUNT here would mean a record reached Tier 1 by a route
  # rule 3 did not sanction.
  expect_equal(sum(out$tier1_agreement %in% c("DISAGREES", "NO_AMOUNT")), 0)
  expect_true(nrow(out) > 0)
})


# -- §6.2 Multi-recipient awardeeName fields --------------------------------

test_that("the New Hampshire three-MCO row splits on semicolons", {
  out <- rhtp_split_recipient_field(paste0(
    "AmeriHealth Caritas New Hampshire Inc.; ",
    "Boston Medical Center Health Plan, Inc. d/b/a WellSense Health Plan; ",
    "Granite State Health Plan Inc. d/b/a New Hampshire Healthy Families"
  ))

  expect_true(out$is_multi)
  expect_equal(out$delimiter, "SEMICOLON")
  expect_length(out$fragments, 3)
  expect_equal(out$fragments[1], "AmeriHealth Caritas New Hampshire Inc.")
  # The comma inside "Boston Medical Center Health Plan, Inc." is punctuation
  # inside one name and must not split it further.
  expect_match(out$fragments[2], "^Boston Medical Center Health Plan, Inc\\.")
})

test_that("the Delaware three-recipient row splits on commas", {
  out <- rhtp_split_recipient_field(
    "University of Delaware, Beebe Healthcare, Deloitte Consulting LLP"
  )

  expect_true(out$is_multi)
  expect_equal(out$delimiter, "COMMA")
  expect_equal(out$fragments,
               c("University of Delaware", "Beebe Healthcare",
                 "Deloitte Consulting LLP"))
})

test_that("a corporate suffix after a comma is not a second recipient", {
  for (name in c("The Arc of Madison County, Inc.",
                 "New Mexico Premier Health, LLC",
                 "Cañoncito Band of Navajo Health Center, Inc.",
                 "A Better Way Services, Inc.")) {
    expect_false(rhtp_split_recipient_field(name)$is_multi, info = name)
  }
})

test_that("a US state name after a comma is a qualifier, not a recipient", {
  # Live Kansas row. Splitting it would invent "Kansas" as an awardee.
  out <- rhtp_split_recipient_field(
    "Hospital District No. 1 of Dickinson County, Kansas, DBA Memorial Health System"
  )
  expect_false(out$is_multi)
})

test_that("an alias after a comma is the same recipient renamed", {
  # Live Pennsylvania row: one hospital under three names.
  out <- rhtp_split_recipient_field(paste0(
    "St. Luke's Hospital of Bethlehem, Pennsylvania dba St. Luke's Hospital - ",
    "Lehighton Campus, formerly Blue Mountain Hospital"
  ))
  expect_false(out$is_multi)
})

test_that("containment does NOT collapse an explicit semicolon enumeration", {
  # Oregon's hundred-clinic row lists a clinic and its named sites side by
  # side. They are distinct recipients at distinct addresses, and collapsing
  # them would delete real awardees.
  out <- rhtp_split_recipient_field(paste0(
    "Evergreen Family Medicine; Evergreen Family Medicine - Sutherlin; ",
    "Evergreen Family Medicine South"
  ))
  expect_true(out$is_multi)
  expect_length(out$fragments, 3)
})

test_that("a conjunction inside one organisation name is not a delimiter", {
  # §6.2 lists ` and ` and ` & ` as delimiters, but they are common inside a
  # single name where a top-level `;` or `,` is not. Three live rows.
  for (name in c("Oregon Health & Science University",
                 "Memorial Community Hospital and Health System",
                 "Alaska Hospital & Healthcare Association")) {
    expect_false(rhtp_split_recipient_field(name)$is_multi, info = name)
  }
})

test_that("a conjunction splits two genuinely named recipients", {
  # The §0.3a hospitals. Neither carries a corporate suffix, and a
  # precision-first guard would have dropped both -- which is exactly how a
  # hospital vanishes from Deliverable 1.
  out <- rhtp_split_recipient_field("Beebe Healthcare and TidalHealth")
  expect_true(out$is_multi)
  expect_equal(out$delimiter, "CONJUNCTION")
  expect_equal(out$fragments, c("Beebe Healthcare", "TidalHealth"))
})

test_that("punctuation beats a conjunction when both are present", {
  # Splitting the `&` as well would shred the first name into "Oregon Health"
  # and "Science University".
  out <- rhtp_split_recipient_field(paste0(
    "Oregon Health & Science University, ",
    "Oregon Health & Science University - Department of Neurology"
  ))
  expect_false(out$is_multi)
})

test_that("the §0.3a hospitals pass the §6.1 legal-entity test", {
  # All three were coded hospital = no in the Delaware review. If they fail
  # the entity test, every §6.2 split and §6.4 mining pass that would have
  # surfaced them is rejected before a human ever sees them.
  for (name in c("Beebe Healthcare", "TidalHealth",
                 "Nemours Children's Health")) {
    expect_true(rhtp_legal_entity_test(name), info = name)
  }
  # And a bare "Oregon Health" still must not, or the ` & ` in "Oregon Health
  # & Science University" reads as a delimiter.
  expect_false(rhtp_legal_entity_test("Oregon Health"))
})

test_that("a comma inside parentheses does not split", {
  out <- rhtp_split_recipient_field(
    "16 Strategically Located Rural Hospitals (unnamed, subrecipient group)"
  )
  expect_false(out$is_multi)
})

test_that("a single name is never multi-recipient", {
  for (name in c("Delaware State Housing Authority", "Parrish Medical Center",
                 NA_character_, "")) {
    expect_false(rhtp_split_recipient_field(name)$is_multi,
                 info = as.character(name))
  }
})

test_that("the amount is carried whole and never divided (§6.2)", {
  records <- rhtp_record_skeleton(1) %>%
    dplyr::mutate(
      record_id = "nh-1", source_endpoint = "awards", state = "NH",
      award_tier = "SUBAWARD", qa_status = "PASS",
      amount_announced = 1898965390,
      awardee_name_raw = paste0(
        "AmeriHealth Caritas New Hampshire Inc.; ",
        "Boston Medical Center Health Plan, Inc.; ",
        "Granite State Health Plan Inc."
      )
    )

  out <- rhtp_multi_recipient_candidates(records)

  expect_equal(nrow(out), 3)
  # Every fragment carries the FIELD total, undivided...
  expect_true(all(out$amount_announced_field_total == 1898965390))
  # ...and there is no per-recipient amount column for anything to sum.
  expect_false(any(stringr::str_detect(names(out), "^amount_announced$")))
  expect_match(out$amount_note[1], "Never divide")
  expect_equal(out$n_recipients, rep(3L, 3))
  expect_equal(out$recipient_index, 1:3)
})

test_that("the parent record keeps its tier — §6.2 flags, it does not reassign", {
  records <- rhtp_record_skeleton(1) %>%
    dplyr::mutate(
      record_id = "nh-1", source_endpoint = "awards", state = "NH",
      award_tier = "SUBAWARD", qa_status = "PASS",
      amount_announced = 1898965390,
      awardee_name_raw = "A Hospital Inc.; B Medical Center; C Clinic"
    )

  out <- rhtp_multi_recipient_candidates(records)

  expect_equal(nrow(out), 3)
  expect_true(all(out$award_tier == "SUBAWARD"))
  expect_equal(records$award_tier, "SUBAWARD")
})

test_that("quarantined and non-award records are never split", {
  quarantined <- rhtp_record_skeleton(1) %>% dplyr::mutate(
    record_id = "q", source_endpoint = "awards", state = "NH",
    qa_status = "QUARANTINED", award_tier = "SUBAWARD",
    awardee_name_raw = "A Hospital Inc.; B Medical Center"
  )
  expect_equal(nrow(rhtp_multi_recipient_candidates(quarantined)), 0)

  document <- rhtp_record_skeleton(1) %>% dplyr::mutate(
    record_id = "d", source_endpoint = "documents", state = "NH",
    qa_status = "PASS", award_tier = "UNASSIGNED",
    awardee_name_raw = "A Hospital Inc.; B Medical Center"
  )
  expect_equal(nrow(rhtp_multi_recipient_candidates(document)), 0)
})

test_that("an empty record table splits to an empty, correctly-shaped table", {
  out <- rhtp_multi_recipient_candidates(rhtp_record_skeleton(0))
  expect_equal(nrow(out), 0)
  expect_true(all(c("recipient_name", "n_recipients",
                    "amount_announced_field_total", "amount_note")
                  %in% names(out)))
})


# -- §6.4 coverage naming, §5.2 run_type -----------------------------------

test_that("a state RCJ surfaced nothing for is NO_RCJ_DATA, not NO_DATA", {
  # A classified table with no award rows in it -- rhtp_mining_coverage() is
  # only ever handed post-rhtp_classify() output, which carries award_tier.
  no_awards <- rhtp_record_skeleton(1) %>%
    dplyr::mutate(record_id = "d", source_endpoint = "documents", state = "WY",
                  award_tier = "UNASSIGNED", qa_status = "PASS")

  coverage <- rhtp_mining_coverage(
    no_awards,
    tibble::tibble(state = character())
  )

  expect_equal(nrow(coverage), 50)
  # The old label read as "this state has no data", i.e. as a claim about the
  # state. It is a claim about RCJ's coverage. Every one of these states holds
  # a $147M-$281M CMS allotment.
  expect_true(all(coverage$coverage_status == "NO_RCJ_DATA"))
  expect_false(any(coverage$coverage_status == "NO_DATA"))
})

test_that("the two run_type vocabularies cannot drift apart", {
  # Stage 2 redeclares the list rather than sourcing Stage 1, whose CLI block
  # would fire on a shared --run flag. This is the guard on that duplication.
  stage1 <- new.env()
  source(here::here("R", "01_retrieve_rcj.R"), local = stage1)
  expect_equal(stage1$RHTP_RUN_TYPES, RHTP_NORMALIZE_RUN_TYPES)
})

test_that("run_type is pinned in both manifest schemas (§5.2, §13.20)", {
  expect_true("run_type" %in% RHTP_NORMALIZE_MANIFEST_COLUMNS)

  stage1 <- new.env()
  source(here::here("R", "01_retrieve_rcj.R"), local = stage1)
  expect_true("run_type" %in% stage1$RHTP_MANIFEST_COLUMNS)
})

test_that("an unknown run_type is refused, not written", {
  expect_error(
    rhtp_normalize_pull(pull_date = "2026-08-27", write = FALSE,
                        run_type = "LIVE"),
    "must be exactly one of"
  )
  # And an abbreviation is refused too. match.arg() would have accepted "PROD"
  # as "PRODUCTION" and written the misspelling to the audit log.
  expect_error(
    rhtp_check_run_type("PROD", RHTP_NORMALIZE_RUN_TYPES),
    "must be exactly one of"
  )
  expect_equal(rhtp_check_run_type("DEV", RHTP_NORMALIZE_RUN_TYPES), "DEV")
})

test_that("both committed manifests carry a valid run_type on every row", {
  for (path in c(here::here("logs", "pull_manifest.csv"),
                 here::here("logs", "normalize_manifest.csv"))) {
    skip_if_not(file.exists(path), path)
    manifest <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
    expect_true("run_type" %in% names(manifest), info = basename(path))
    expect_true(all(manifest$run_type %in% RHTP_NORMALIZE_RUN_TYPES),
                info = basename(path))
  }
})
