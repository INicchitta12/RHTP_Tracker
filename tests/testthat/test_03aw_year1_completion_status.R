# Tests for R/03aw_year1_completion_status.R -- which states have FINISHED
# Year 1 awarding, and the hospital share where they have.

source(here::here("R", "03aw_year1_completion_status.R"))

status <- y1_build_status()
share  <- y1_hospital_share(status)

test_that("every EXTRACTED state has exactly one status row, and no other state does", {
  survey <- readr::read_csv(here::here("data", "reference", "rcj_state_survey.csv"),
                            show_col_types = FALSE)
  expect_setequal(status$state, survey$state[survey$extraction_status == "EXTRACTED"])
  expect_equal(anyDuplicated(status$state), 0L)
  expect_true(all(status$year1_status %in% Y1_STATUS_CODES))
})

test_that("COMPLETE rests on a statement AND no recorded remainder -- never on a percentage", {
  expect_setequal(status$state[status$year1_status == "COMPLETE"], c("FL", "GA"))
  bad <- Y1_STATUS
  bad$year1_status[bad$state == "AK"] <- "COMPLETE"   # 87.9% of allotment, rolling
  expect_error(y1_assert_status(bad), "COMPLETE without")
  bad <- Y1_STATUS
  bad$remaining_unawarded[bad$state == "SD"] <- "Yes"
  expect_error(y1_assert_status(bad), "UNKNOWN where")
})

test_that("Michigan's 'all RHTP Subrecipients' is a roster claim, not a completed round", {
  expect_equal(status$year1_status[status$state == "MI"], "PARTIAL")
  expect_match(status$evidence[status$state == "MI"], "additional RHTP GFOs")
})

test_that("the completeness sentences are in the archived sources", {
  txt <- function(p) paste(readLines(here::here(p), warn = FALSE), collapse = " ")
  expect_match(txt("data/evidence/recheck/2026-08-29/FL/FL_governor_188m_release.html"),
               "awarded the full scope of Florida", fixed = TRUE)
  expect_match(txt("data/evidence/GA/2026-08-27_great_health_phase4_awards.html"),
               "complete the initial Year 1 award cycle", fixed = TRUE)
})

test_that("figures are recomputed from the award files, and Georgia is summed per pool", {
  ga <- status[status$state == "GA", ]
  expect_equal(ga$published_incl_pool_level, 197148327)
  expect_lt(ga$published_priced, ga$published_incl_pool_level)
  fl <- status[status$state == "FL", ]
  expect_equal(round(fl$published_priced), 188201256)
  # New Hampshire's CDFA "up to $40 million" is a ceiling and is not counted.
  nh <- status[status$state == "NH", ]
  expect_equal(nh$pool_level_unpriced, 0)
})

test_that("the hospital share is reported for COMPLETE states only, as a bounded range", {
  expect_setequal(share$state, c("FL", "GA"))
  expect_true(all(share$share_floor_pct <= share$share_ceiling_pct))
  expect_equal(share$share_floor_pct[share$state == "FL"], 26.2)
  # session 58 settled Florida's five Unclear rows, so its ceiling IS its floor
  expect_equal(share$share_ceiling_pct[share$state == "FL"], 26.2)
  expect_equal(share$unclear_priced_usd[share$state == "FL"], 0)
  expect_equal(share$share_floor_pct[share$state == "GA"], 45.8)
  expect_equal(share$mixed_pools_with_unpriced_named_hospitals_usd[share$state == "GA"], 22135000)
})
