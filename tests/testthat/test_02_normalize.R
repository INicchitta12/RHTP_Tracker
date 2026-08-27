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
