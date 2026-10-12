# test_03by_ky_rch_awardees.R ------------------------------------------------
# Session 94. Kentucky's first named Tier 3 recipient: Lake Cumberland District
# Health Department, RCH Hub Lead, 2026-10-05. No amount; "up to $10 million"
# over five years is a REGIONAL CEILING held as text only.

suppressWarnings(suppressMessages(source(here::here("R", "03by_ky_rch_awardees.R"))))

d <- kyr_awardees()

test_that("two named rows, no amount, local health departments, not hospitals", {
  # Session 99: Purchase District Health Department (2026-10-07) is row 2,
  # found by R/03af's name tripwire on FHKY's RCH page.
  expect_equal(nrow(d), 2L)
  expect_equal(d$awardee, c("Lake Cumberland District Health Department",
                            "Purchase District Health Department"))
  expect_true(all(is.na(d$amount)))
  expect_true(all(d$recipient_type == "LOCAL_GOVT_OR_PUBLIC_HEALTH"))
  expect_true(all(d$distributed_to_hospital == "No"))
  expect_true(all(d$hospital_attribution == "NOT_HOSPITAL"))
  expect_true(all(d$amount_confirmed == "No"))
  expect_true(all(d$determination_confidence == "MEDIUM"))
})

test_that("the $10 million is a CEILING, held as text and in no numeric column", {
  expect_true(all(grepl("ceiling", d$amount_ceiling_text, ignore.case = TRUE)))
  num <- vapply(d, is.numeric, logical(1))
  vals <- unlist(d[num])
  expect_false(any(!is.na(vals) & vals == 1e7))
  expect_true(all(grepl("CEILING", d$amount_basis, fixed = TRUE)))
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
