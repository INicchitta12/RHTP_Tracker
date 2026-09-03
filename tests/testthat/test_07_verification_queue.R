# =============================================================================
# tests/testthat/test_07_verification_queue.R
#
# The consolidated verification queue is a REPORTING artifact, so what these
# tests protect is the honesty of its figures rather than a parse. Three
# things in particular:
#
#   1. it must not DROP a question -- a consolidation that silently loses one
#      is worse than no consolidation;
#   2. it must not DOUBLE-COUNT a dollar -- Arkansas Rural Health Partnership
#      raises two questions about the same two award rows;
#   3. its `dollars_at_stake` must be what the ANSWER moves, not what the
#      award is worth -- otherwise the sheet sorts a reviewer towards awards
#      whose coding cannot change and away from Iowa's 102 unpriced rows.
#
# It reads only. No fixture, no network, no writes.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
})

source(here::here("R", "07_verification_queue.R"))

vq_raw   <- vq_rows()
vq_queue <- vq_build()

test_that("every assertion the builder carries passes on the committed data", {
  expect_true(vq_assert_committed_figures(vq_raw))
  expect_true(vq_assert_queue_covered(vq_queue))
  expect_true(vq_assert_sweep_complete(vq_raw))
  expect_true(vq_assert_overlap_declared(vq_raw, vq_queue))
  expect_gt(vq_assert_archives_exist(vq_queue), 0)
})

test_that("every OPEN row of the committed review queue reaches the workbook", {
  q <- vq_read(VQ_QUEUE) %>% dplyr::filter(queue_status == "OPEN")
  expect_equal(nrow(q), 19L)
  expect_setequal(
    unique(q$question_id),
    unique(vq_queue$queue_code[vq_queue$queue_source == "COMMITTED_QUEUE"])
  )
})

test_that("a question dropped from the spec fails the coverage assertion", {
  short <- vq_queue %>% dplyr::filter(queue_code != "MI_MHA_FLOW")
  expect_error(vq_assert_queue_covered(short), "MI_MHA_FLOW")
})

test_that("the derived sweep is marked as derived and is not the committed queue", {
  derived <- vq_queue %>% dplyr::filter(queue_source == "DERIVED_FROM_STATE_FILE")
  expect_gt(nrow(derived), 0)
  # Iowa is the largest derived block and the reason the sweep exists: 102
  # award rows on §8's standing fallback, named in CLAUDE.md and never queued.
  ia <- derived %>% dplyr::filter(state == "IA")
  expect_equal(sum(ia$award_rows), 102L)
  expect_true(all(ia$queue_source == "DERIVED_FROM_STATE_FILE"))
  # and it must never claim to be committed
  expect_false(any(derived$queue_code %in%
    (vq_read(VQ_QUEUE) %>% dplyr::filter(queue_status == "OPEN") %>% dplyr::pull(question_id))))
})

test_that("Arkansas Rural Health Partnership is TWO questions and ONE set of dollars", {
  arhp <- vq_queue %>% dplyr::filter(recipient_name == "Arkansas Rural Health Partnership")
  expect_equal(nrow(arhp), 2L)
  expect_setequal(arhp$queue_code,
                  c("AR_RECIPIENT_FORM_NOT_STATED", "AR_ARHP_CONSORTIUM_FLOW"))
  expect_true(any(!is.na(arhp$overlaps_with)))
  expect_equal(unique(arhp$dollars_at_stake), 18833521)

  t <- vq_totals(vq_queue, vq_raw)
  # counted once, not twice: the de-duplicated total is a whole $18,833,521
  # below the naive sum down the column.
  expect_equal(sum(vq_queue$dollars_at_stake) - t$dollars_total, 18833521)
})

test_that("an undeclared overlap fails rather than double-counting", {
  clean <- vq_queue %>% dplyr::mutate(overlaps_with = NA_character_)
  expect_error(vq_assert_overlap_declared(vq_raw, clean), "counted \\s*twice|counted$|twice")
})

test_that("Wyoming's Instaclinic is NOT treated as an overlap -- different pools", {
  # The same organisation under two codes is only a double count when the two
  # codes rest on the SAME award rows. Instaclinic LLC holds awards under
  # Initiative 3.1 AND Initiative 4.2, and those are different dollars.
  inst <- vq_queue %>% dplyr::filter(recipient_name == "Instaclinic LLC")
  expect_equal(nrow(inst), 2L)
  expect_gt(min(inst$dollars_at_stake), 0)
  ids <- vq_raw %>% dplyr::filter(recipient_name == "Instaclinic LLC")
  expect_equal(dplyr::n_distinct(ids$source_row_id), nrow(ids))
})

test_that("dollars_at_stake is what the ANSWER moves, never the award's size", {
  # Illinois's ICAHN is a $50,008,264 award and is ALREADY distributed_to_hospital
  # = Yes, so no answer to its typing question moves a dollar.
  il <- vq_queue %>% dplyr::filter(state == "IL")
  expect_equal(il$award_amount, 50008264)
  expect_equal(il$dollars_at_stake, 0)
  expect_equal(il$direction, "NONE")

  # Maine's University of New England is $12,000,000 and No under both codings.
  une <- vq_queue %>% dplyr::filter(queue_code == "ME_UNE_HOSPITAL_TO_HOME_FLOW")
  expect_equal(une$award_amount, 12000000)
  expect_equal(une$dollars_at_stake, 0)

  expect_true(all(vq_queue$dollars_at_stake[
    vq_queue$direction %in% c("NONE", "ROWS_ONLY")] == 0))
})

test_that("the unpriced states contribute ROWS and never dollars -- read the row count", {
  rows_only <- vq_queue %>% dplyr::filter(direction == "ROWS_ONLY")
  expect_equal(sum(rows_only$dollars_at_stake), 0)
  expect_gt(sum(rows_only$award_rows), 0)
  # Iowa, Nevada, North Carolina, Missouri, Idaho and Maine's cohort
  expect_true(all(c("IA", "NV", "NC", "MO", "ID", "ME") %in% rows_only$state))
})

test_that("Maine's $30M invited cohort is CONTINGENT and outside the range", {
  me <- vq_queue %>% dplyr::filter(queue_code == "ME_RHEF_COHORT_IS_NOT_AN_AWARD")
  expect_equal(nrow(me), 11L)
  expect_equal(sum(me$dollars_at_stake), 0)
  expect_equal(unique(me$contingent_dollars), 30000000)

  t <- vq_totals(vq_queue, vq_raw)
  expect_equal(t$contingent, 30000000)
  # the range must NOT contain it
  expect_lt(t$ceiling - t$floor_if_none, 30000000 + t$dollars_total)
})

test_that("the range is bounded by the repository's OWN partition function", {
  t <- vq_totals(vq_queue, vq_raw)
  expect_gt(t$floor_dollars, 0)
  expect_equal(t$ceiling, t$floor_dollars + t$dollars_up)
  expect_equal(t$floor_if_none, t$floor_dollars - t$dollars_down)
  expect_equal(t$ceiling - t$floor_if_none, t$dollars_up + t$dollars_down)
  # Maryland is the only DOWN direction: two names typed HOSPITAL_OR_SYSTEM
  # from the name alone that read as FQHCs.
  expect_equal(t$dollars_down, 3034792)
  expect_true(all(vq_queue$state[vq_queue$direction == "DOWN"] == "MD"))
})

test_that("the recurring matcher FLAGS and never resolves", {
  rec <- vq_recurring(vq_queue, vq_raw)
  expect_true(all(c("match_tier", "scope", "free_answer") %in% names(rec)))
  expect_setequal(unique(rec$match_tier), c("EXACT", "PREFIX", "BRAND"))
  # both raw spellings survive on every row, so a human judges
  expect_false(any(is.na(rec$open_name)))
  expect_false(any(is.na(rec$resolved_name)))
  # nothing in the queue was re-typed by the match
  expect_true(all(is.na(vq_queue$verified_type)))
})

test_that("TidalHealth is the free answer, cross-state, on an EXACT match", {
  rec <- vq_recurring(vq_queue, vq_raw)
  td <- rec %>% dplyr::filter(open_name == "TidalHealth", match_tier == "EXACT")
  expect_equal(nrow(td), 1L)
  expect_equal(td$open_state, "MD")
  expect_equal(td$resolved_state, "DE")
  expect_equal(td$resolved_type, "HOSPITAL_OR_SYSTEM")
  expect_equal(td$resolved_dth, "Yes")
  expect_equal(td$scope, "CROSS_STATE")
  expect_equal(td$open_dollars, 4911052)
})

test_that("an identical string typed two ways INSIDE one state is caught", {
  rec <- vq_recurring(vq_queue, vq_raw)
  # Wyoming publishes "Bighorn Valley Health Center, Inc. dba One Health" in
  # Initiative 3.1 (fallback) and Initiative 4.1 (FQHC_OR_RHC, stated class).
  bv <- rec %>% dplyr::filter(stringr::str_detect(open_name, "Bighorn Valley"),
                              match_tier == "EXACT")
  expect_equal(nrow(bv), 1L)
  expect_equal(bv$scope, "SAME_STATE")
  expect_equal(bv$resolved_type, "FQHC_OR_RHC")
  # and Powell Valley, which differs only by a corporate suffix
  pv <- rec %>% dplyr::filter(open_name == "Powell Valley Health Care")
  expect_true("EXACT" %in% pv$match_tier)
  expect_true(any(pv$resolved_name == "Powell Valley Health Care Inc"))
})

test_that("a queue row is never its own free answer", {
  rec <- vq_recurring(vq_queue, vq_raw)
  # SIX of the questions here are not about §8's fallback at all -- Georgia's
  # GHA, Indiana's seven vendors, Maine's UNE, Michigan's MHA, Nevada's Incline
  # Village foundation -- so those rows sit in the queue while carrying a
  # DETERMINATE type, and a name-keyed matcher would hand each of them its own
  # coding back as a "free answer". The exclusion is by ROW IDENTITY.
  for (code in c("GHA_RECIPIENT_TYPE", "IN_PROCUREMENT_VENDOR_TYPE",
                 "ME_UNE_HOSPITAL_TO_HOME_FLOW", "MI_MHA_FLOW",
                 "NV_INCLINE_VILLAGE_FOUNDATION_FLOW")) {
    names_in_code <- vq_queue$recipient_name[vq_queue$queue_code == code]
    tautology <- rec %>%
      dplyr::filter(open_code == code, resolved_name %in% names_in_code)
    expect_equal(nrow(tautology), 0L, info = code)
  }
})

test_that("the same name typed two ways in ONE state file is kept, not suppressed", {
  # These are the opposite of a self-match and are the strongest answers here:
  # one organisation, one state file, two rows, two codings. Nebraska's Boone
  # County Health Center and Gothenburg Health are already HOSPITAL_OR_SYSTEM
  # on another row; Wyoming's Bighorn Valley is already FQHC_OR_RHC.
  rec <- vq_recurring(vq_queue, vq_raw)
  same <- rec %>% dplyr::filter(open_state == resolved_state,
                                open_name == resolved_name)
  expect_gte(nrow(same), 6L)
  # every one must actually DIFFER from the open coding, or it answers nothing
  expect_true(all(!stringr::str_detect(same$open_type,
                    stringr::fixed(paste0(same$resolved_type, " / ", same$resolved_conf)))))
  expect_true(all(c("NE", "WY") %in% same$open_state))
})

test_that("the normaliser strips corporate suffixes and nothing else", {
  expect_equal(vq_normalise("Powell Valley Health Care Inc"), "powell valley health care")
  expect_equal(vq_normalise("Collaborative Fusion, Inc"), "collaborative fusion")
  expect_equal(vq_normalise("Children’s Mercy Hospital"), "children s mercy hospital")
  # it must NOT collapse two genuinely different organisations
  expect_false(vq_normalise("Intermountain Health") ==
                 vq_normalise("InterMountain Education Service District"))
  expect_false(vq_normalise("Northern Nevada Regional Hospital") ==
                 vq_normalise("Northeastern Nevada Regional Hospital"))
})

test_that("the four verification columns are empty, and last", {
  expect_equal(tail(names(vq_queue), 4),
               c("verified_type", "verified_by", "verified_date", "basis"))
  for (col in c("verified_type", "verified_by", "verified_date", "basis")) {
    expect_true(all(is.na(vq_queue[[col]])), info = col)
  }
})

test_that("nothing here re-codes a state file", {
  # The builder reads; it has no writer for anything under data/.
  body <- paste(readLines(here::here("R", "07_verification_queue.R")), collapse = "\n")
  expect_false(stringr::str_detect(body, "write_csv|writeLines\\(.*data/|file\\.copy"))
  expect_true(stringr::str_detect(body, "saveWorkbook"))
})
