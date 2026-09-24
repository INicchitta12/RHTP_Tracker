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
  #
  # SESSION 62: Florida LEFT the bucket -- the 2026-09-24 pull carries 80
  # Florida Tier 3 candidates, so it is RCJ_ONLY now -- and the evidence is
  # carried by ILLINOIS ($50,008,264 to ICAHN, zero candidates) and WYOMING
  # (77 award actions, zero candidates).
  #
  # Session 67: the CMS half of trigger_source is rebuilt from the live CMS
  # list, which the CMS Routine grows. A CMS release for IL, WY or FL moves
  # that state's code (NEITHER -> CMS_ONLY, RCJ_ONLY -> BOTH) and that is
  # the monitor working, not a regression. So each pin applies only while
  # CMS has not announced the state; the RCJ half, from a committed pull,
  # is still pinned.
  cms_states <- unique(cms_list$state)
  expect_gt(nrow(neither_extracted), 0L)
  for (st in setdiff(c("IL", "WY"), cms_states)) {
    expect_true(st %in% neither_extracted$state, info = st)
  }
  expect_equal(queue$trigger_source[queue$state == "FL"],
               if ("FL" %in% cms_states) "BOTH" else "RCJ_ONLY")
})


test_that("Illinois is queued -- but on a $1 signal, near the bottom", {
  # The honest version of the finding. The union DOES catch Illinois, via a
  # single RCJ record that has nothing to do with the $50,008,264 award: a $1
  # 2025 Medicaid contract. So the union widens the net without making it fine
  # enough to have caught this award on its merits, and overstating that would
  # be the same error in the other direction.
  #
  # SESSION 62: RCJ withdrew that $1 row on the 2026-09-24 pull, so the union
  # no longer catches Illinois at all -- NEITHER, with $50,008,264 extracted.
  il <- queue[queue$state == "IL", ]
  expect_equal(il$rcj_tier3_candidates, 0L)
  # Session 67: conditional on the live CMS list (see above).
  if ("IL" %in% cms_list$state) {
    expect_equal(il$trigger_source, "CMS_ONLY")
  } else {
    expect_equal(il$trigger_source, "NEITHER")
    expect_true(is.na(il$cms_announced_date))
  }

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
  # Session 66: the builder reads cms_state_announcements.csv, which the CMS
  # Routine rewrites and commits; the Routine may not rebuild this file. So a
  # state CMS announces between rebuilds makes the committed queue lag the
  # builder by exactly one CMS flag -- RCJ_ONLY -> BOTH or NEITHER -> CMS_ONLY.
  # Pinning equality made every new announcement a suite failure, and the
  # Routine (which runs the suite before committing) then refused to record
  # it. That lag is expected and is reported; any OTHER mismatch is still a
  # hand edit or a builder change and still fails.
  lag_ok <- (on_disk$trigger_source == "RCJ_ONLY" & queue$trigger_source == "BOTH") |
    (on_disk$trigger_source == "NEITHER" & queue$trigger_source == "CMS_ONLY")
  same <- on_disk$trigger_source == queue$trigger_source
  expect_true(all(same | lag_ok))
  if (any(lag_ok)) {
    message("state_trigger_queue.csv lags the CMS list for: ",
            paste(on_disk$state[lag_ok], collapse = ", "),
            " -- rebuild with Rscript R/00b_state_trigger_queue.R --build")
  }
})


test_that("the assertions pass on the real data", {
  expect_true(rhtp_trigger_queue_assert(queue))
})


test_that("INVESTIGATED_NO_PROBE carries through to the queue and leaves QUEUED", {
  # Session 43. The worked-but-unprobed states must not read QUEUED (which
  # would send a future session to re-investigate them from scratch) and must
  # not read NOT_TRIGGERED (which describes the discovery layers, not the work
  # done). The carry-through is what makes the survey's finding visible here.
  # SESSION 47: five, not six. South Carolina left the bucket because the
  # STATE PUBLISHED -- SCDHHS's Year 1 Award List, 2026-09-15 -- so it reads
  # EXTRACTED here now. Nothing had to be retracted, which is the whole point
  # of the weaker code: it described what this repository had done, not what
  # South Carolina had.
  # SESSION 59: four. Tennessee left the same way -- TDH named 53 HART
  # recipients on 2026-09-03.
  # SESSION 61: three. New Jersey left the same way -- its 2026-07-31
  # allocations PDF, found in session 60 and extracted in session 61.
  three <- c("HI", "MA", "MN")
  got <- queue$queue_status[match(three, queue$state)]
  expect_true(all(got == "INVESTIGATED_NO_PROBE"),
              info = paste(three, got, collapse = "; "))
  expect_equal(queue$queue_status[queue$state == "SC"], "EXTRACTED")
  expect_equal(queue$queue_status[queue$state == "TN"], "EXTRACTED")
  expect_equal(queue$queue_status[queue$state == "NJ"], "EXTRACTED")
  expect_true(all(queue$queue_status %in% rhtp_vocabulary("queue_status")))
})


test_that("the QUEUED bucket is exactly the TEN low-candidate states left", {
  # Every state sits in a bucket that says what was done to it, and QUEUED
  # means "nobody has built a file for this" rather than "nobody has looked".
  # An eleventh state appearing here, or one of these ten leaving without an
  # extraction or a probe behind it, is a change worth stopping on.
  #
  # SESSION 43 LEFT FOURTEEN HERE AND SESSION 44 WORKED FOUR OF THEM OUT --
  # Delaware, Idaho and Ohio to EXTRACTED (award file, archive, probe) and
  # Mississippi to INVESTIGATED_NO_LIST (archive, probe, Routine). That is
  # the only route out of this bucket: session 43 deliberately refused to move
  # them on the strength of a reporting pass.
  # Session 54: VT and WV left by EXTRACTION, so the ten are eight --
  # 24 - 5 = 19 candidates, $1,916,786,628 - $394,529,839 = $1,522,256,789.
  # Session 59: CO and ND left for INVESTIGATED_NO_LIST THROUGH THE WORK --
  # archive, probe with tripwires, Routine -- so six remain: 19 - 4 - 1 = 14
  # candidates, $1,522,256,789 - $200,105,604 - $198,936,970 = $1,123,214,215.
  # Session 60: VA and WA left by EXTRACTION -- 14 - 1 - 2 = 11 candidates,
  # $1,123,214,215 - $189,544,888 - $181,257,515 = $752,411,812.
  four <- c("MT", "UT", "AZ", "RI")
  expect_setequal(queue$state[queue$queue_status == "QUEUED"], four)
  # Session 62 (2026-09-24 pull): 11 -> 6 candidates -- AZ's three webinar
  # rows are now QUARANTINED by Stage 2 on PROVENANCE_PREDATES_NOA and RCJ
  # withdrew RI's three opioid rows (one new RI row). The four states and
  # their allotments are unchanged.
  expect_equal(sum(queue$rcj_tier3_candidates[queue$queue_status == "QUEUED"]),
               6L)
  expect_equal(sum(queue$cms_fy2026_allotment[queue$queue_status == "QUEUED"]),
               752411812)
  expect_equal(queue$queue_status[match(c("CO", "ND"), queue$state)],
               c("INVESTIGATED_NO_LIST", "INVESTIGATED_NO_LIST"))
  expect_setequal(queue$state[queue$queue_status == "EXTRACTED" &
                              queue$state %in% c("DE", "ID", "OH")],
                  c("DE", "ID", "OH"))
})
