# test_03by_ky_rch_awardees.R ------------------------------------------------
# Session 94. Kentucky's first named Tier 3 recipient: Lake Cumberland District
# Health Department, RCH Hub Lead, 2026-10-05. No amount; "up to $10 million"
# over five years is a REGIONAL CEILING held as text only.

suppressWarnings(suppressMessages(source(here::here("R", "03by_ky_rch_awardees.R"))))

d <- kyr_awardees()

test_that("one named row, no amount, a local health department, not a hospital", {
  expect_equal(nrow(d), 1L)
  expect_equal(d$awardee, "Lake Cumberland District Health Department")
  expect_true(is.na(d$amount))
  expect_equal(d$recipient_type, "LOCAL_GOVT_OR_PUBLIC_HEALTH")
  expect_equal(d$distributed_to_hospital, "No")
  expect_equal(d$hospital_attribution, "NOT_HOSPITAL")
  expect_equal(d$amount_confirmed, "No")
  expect_equal(d$determination_confidence, "MEDIUM")
})

test_that("the $10 million is a CEILING, held as text and in no numeric column", {
  expect_true(grepl("ceiling", d$amount_ceiling_text, ignore.case = TRUE))
  num <- vapply(d, is.numeric, logical(1))
  vals <- unlist(d[num])
  expect_false(any(!is.na(vals) & vals == 1e7))
  expect_true(grepl("CEILING", d$amount_basis, fixed = TRUE))
})

test_that("both archived sources say what the row rests on", {
  expect_silent(kyr_assert_sources())
})

test_that("the committed CSV matches a fresh build", {
  c <- readr::read_csv(KYR_CSV, show_col_types = FALSE)
  expect_equal(c$awardee, d$awardee)
  expect_equal(c$recipient_type, d$recipient_type)
  expect_true(all(is.na(c$amount)))
})
