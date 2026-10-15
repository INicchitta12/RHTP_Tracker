# test_03cd_hi_year1_awardees.R ------------------------------------------------
# Session 101. Hawaii: SHPDA's page names three RVBI Notices of Award and no
# amount; HANDS, where the amounts are, is 403 here.

suppressWarnings(suppressMessages(source(here::here("R", "03cd_hi_year1_awardees.R"))))

hi <- hi_year1_awardees()

test_that("three Notices of Award, no amount, and the page still says so", {
  expect_silent(hi_assert_sources())
  expect_equal(nrow(hi), 3L)
  expect_true(all(is.na(hi$amount)))
  expect_setequal(hi$awardee, names(HI_NOA_PHRASE))
  expect_true(all(grepl("HANDS", hi$amount_basis, fixed = TRUE)))
})

test_that("HAH is the association rule's pool at $0; PSW and HPCA are not hospitals", {
  hah <- hi[hi$awardee == "Healthcare Association of Hawaii", ]
  expect_equal(hah$flow_type, "PASS_THROUGH_DESIGNATED")
  expect_equal(hah$hospital_attribution, "POOL_UNNAMED_HOSPITALS")
  expect_equal(hah$intermediary_name, "Healthcare Association of Hawaii")
  expect_equal(hah$determination_confidence, "LOW")
  psw <- hi[hi$awardee == "Physicians of Southwest Washington, LLC", ]
  expect_equal(psw$recipient_type, "OTHER")
  expect_match(psw$recipient_type_source, "Determined form:")
  expect_equal(psw$distributed_to_hospital, "No")
  hp <- hi[hi$awardee == "Hawaii Primary Care Association", ]
  expect_equal(hp$distributed_to_hospital, "No")
  p <- rhtp_hospital_dollar_partition(hi)
  expect_equal(p$bucket, "POOL_UNNAMED_HOSPITALS")
  expect_equal(p$rows, 1L)
  expect_equal(p$dollars, 0)
})

test_that("the committed CSV matches a fresh build", {
  d <- readr::read_csv(HI_CSV, show_col_types = FALSE)
  expect_equal(d$awardee, hi$awardee)
  expect_equal(d$hospital_attribution, hi$hospital_attribution)
})
