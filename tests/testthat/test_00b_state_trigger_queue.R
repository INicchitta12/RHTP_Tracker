# test_00b_state_trigger_queue.R ---------------------------------------------
# The union of the two discovery layers. Reads committed CSVs only -- no
# network, no quota.
#
# WHAT THIS FILE IS DEFENDING. The queue exists because a single discovery
# layer was silently treated as a census for fifteen sessions. The failure did
# not look like a failure: R/00 reported nine states confidently and nothing in
# its output suggested a tenth. So the tests here are about the SHAPE of the
# union rather than its contents -- that it can never be narrower than a
# source it consumes, that it is strictly wider than CMS alone, and that its
# weakest bucket keeps saying so out loud.

library(testthat)

source(here::here("R", "00b_state_trigger_queue.R"))

queue <- rhtp_trigger_queue()
cms_list <- readr::read_csv(here::here(QUEUE_CMS_CSV),
                            show_col_types = FALSE, progress = FALSE)
rcj_survey <- readr::read_csv(here::here(QUEUE_SURVEY_CSV),
                              show_col_types = FALSE, progress = FALSE)


test_that("the queue covers all fifty states, once each", {
  expect_equal(nrow(queue), 50L)
  expect_setequal(queue$state, rhtp_cms_states()$state)
  expect_false(any(duplicated(queue$state)))
  expect_equal(queue$queue_rank, seq_len(nrow(queue)))
})


test_that("the union is a superset of the CMS list", {
  # The property the stage exists for, from the CMS side.
  triggered <- queue$state[queue$trigger_source != "NEITHER"]
  expect_true(all(unique(cms_list$state) %in% triggered))

  # Every CMS state is BOTH or CMS_ONLY, never RCJ_ONLY or NEITHER.
  for (st in unique(cms_list$state)) {
    expect_true(queue$trigger_source[queue$state == st] %in%
                  c("BOTH", "CMS_ONLY"), info = st)
  }
})


test_that("the union is a superset of the RCJ survey", {
  # And from the RCJ side. Either source silently shrinking the other is the
  # failure this file is built around.
  triggered <- queue$state[queue$trigger_source != "NEITHER"]
  rcj_states <- rcj_survey$state[rcj_survey$tier3_candidates > 0]
  expect_true(all(rcj_states %in% triggered))

  for (st in rcj_states) {
    expect_true(queue$trigger_source[queue$state == st] %in%
                  c("BOTH", "RCJ_ONLY"), info = st)
  }
})


test_that("the union is STRICTLY wider than CMS alone", {
  # If this stops holding, the second trigger has stopped contributing and the
  # queue has quietly collapsed back to the list it was built to widen.
  triggered <- sum(queue$trigger_source != "NEITHER")
  expect_gt(triggered, length(unique(cms_list$state)))
  expect_gt(sum(queue$trigger_source == "RCJ_ONLY"), 0L)
})


test_that("every state records WHICH source flagged it", {
  expect_true(all(queue$trigger_source %in% rhtp_vocabulary("trigger_source")))
  expect_true(all(queue$queue_status %in% rhtp_vocabulary("queue_status")))

  # BOTH must carry evidence from both sides; RCJ_ONLY must carry no CMS date.
  both <- queue[queue$trigger_source == "BOTH", ]
  expect_true(all(!is.na(both$cms_announced_date)))
  expect_true(all(both$rcj_tier3_candidates > 0))

  rcj_only <- queue[queue$trigger_source == "RCJ_ONLY", ]
  expect_true(all(is.na(rcj_only$cms_announced_date)))
  expect_true(all(rcj_only$rcj_tier3_candidates > 0))
})


test_that("NEITHER never means the state has awarded nothing", {
  # THE CLAIM THIS FILE MOST NEEDS A READER TO BELIEVE, and the evidence for
  # it is in the repository: Florida sits in the NEITHER bucket with 81
  # extracted awards. If that ever stops being true the warning in R/00b's
  # header has lost its evidence and must be re-examined, not quietly kept.
  neither_extracted <- queue[queue$trigger_source == "NEITHER" &
                               queue$extraction_status == "EXTRACTED", ]
  expect_gt(nrow(neither_extracted), 0L)
  expect_true("FL" %in% neither_extracted$state)
})


test_that("Illinois is queued -- but on a $1 signal, near the bottom", {
  # The honest version of the finding. The union DOES catch Illinois, via a
  # single RCJ record that has nothing to do with the $50,008,264 award: a $1
  # 2025 Medicaid contract. So the union widens the net without making it fine
  # enough to have caught this award on its merits, and overstating that would
  # be the same error in the other direction.
  il <- queue[queue$state == "IL", ]
  expect_equal(il$trigger_source, "RCJ_ONLY")
  expect_equal(il$rcj_tier3_candidates, 1L)
  expect_equal(il$rcj_federal_amount_sum, 1)
  expect_true(is.na(il$cms_announced_date))

  # Illinois is now extracted, so it is out of the QUEUED backlog.
  expect_equal(il$queue_status, "EXTRACTED")
})


test_that("an extracted state is never left sitting in the backlog", {
  extracted <- queue[queue$extraction_status == "EXTRACTED", ]
  expect_gt(nrow(extracted), 0L)
  expect_true(all(extracted$queue_status == "EXTRACTED"))
  expect_false(any(queue$queue_status == "QUEUED" &
                     queue$extraction_status == "EXTRACTED"))
})


test_that("QUEUED is exactly triggered-and-not-yet-extracted", {
  queued <- queue[queue$queue_status == "QUEUED", ]
  expect_gt(nrow(queued), 0L)
  expect_true(all(queued$trigger_source != "NEITHER"))
  expect_true(all(queued$extraction_status == "NOT_EXTRACTED"))
})


test_that("first_queued is set for triggered states and absent otherwise", {
  # It is what makes "which states appeared since we last looked" answerable.
  triggered <- queue[queue$queue_status != "NOT_TRIGGERED", ]
  expect_true(all(!is.na(triggered$first_queued)))
  untriggered <- queue[queue$queue_status == "NOT_TRIGGERED", ]
  expect_true(all(is.na(untriggered$first_queued)))
})


test_that("the committed CSV matches the builder", {
  path <- here::here(QUEUE_CSV)
  expect_true(file.exists(path))
  on_disk <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  expect_equal(nrow(on_disk), 50L)
  expect_equal(on_disk$state, queue$state)
  expect_equal(on_disk$trigger_source, queue$trigger_source)
})


test_that("the assertions pass on the real data", {
  expect_true(rhtp_trigger_queue_assert(queue))
})
