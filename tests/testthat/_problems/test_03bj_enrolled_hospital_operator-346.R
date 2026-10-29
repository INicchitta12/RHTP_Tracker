# Extracted from test_03bj_enrolled_hospital_operator.R:346

# prequel ----------------------------------------------------------------------
library(testthat)
suppressMessages(source(here::here("R", "03bj_enrolled_hospital_operator.R")))
suppressMessages(source(here::here("R", "03ap_verification_queue_2.R")))
tabs <- eh_read_committed(unname(VQ_ALL_STATE_CSVS()))
eff  <- eh_effect(tabs)
sw   <- eh_sweep(tabs)

# test -------------------------------------------------------------------------
tot <- vq_bucket_totals(vq_partition())
n <- tot[tot$bucket == "NAMED_HOSPITAL", ]
expect_equal(n$rows, 1835L)
expect_equal(round(n$dollars, 2), 1731421723.08)
expect_equal(n$states, 36L)
n$rows <- n$rows - 1L
n$dollars <- n$dollars - 110854
expect_equal(n$rows, 1834L)
expect_equal(round(n$dollars, 2), 1729133683.70)
n$rows <- n$rows - 60L
n$dollars <- n$dollars - 82903969.14
n$states <- n$states - 1L
expect_equal(n$rows, 1774L)
expect_equal(round(n$dollars, 2), 1646229714.56)
expect_equal(n$states, 35L)
n$rows <- n$rows - 189L
n$dollars <- n$dollars - 206275435.98
n$states <- n$states - 1L
expect_equal(n$rows, 1585L)
expect_equal(round(n$dollars, 2), 1439954278.58)
expect_equal(n$states, 34L)
n$rows <- n$rows - 9L
n$dollars <- n$dollars - 7979000
expect_equal(n$rows, 1576L)
expect_equal(round(n$dollars, 2), 1431975278.58, tolerance = 0)
n$rows <- n$rows - 38L
n$dollars <- n$dollars - 5561417.40
n$states <- n$states - 1L
expect_equal(n$rows, 1538L)
expect_equal(round(n$dollars, 2), 1426413861.18)
n$rows <- n$rows - 202L
n$dollars <- n$dollars - 119194693.55
n$states <- n$states - 1L
expect_equal(n$rows, 1336L)
expect_equal(round(n$dollars, 2), 1307219167.63)
n$dollars <- n$dollars - 1010206 + 3455421
expect_equal(round(n$dollars, 2), 1309664382.63)
n$rows <- n$rows - 5L
n$dollars <- n$dollars - 84529867.05
expect_equal(n$rows, 1331L)
expect_equal(round(n$dollars, 2), 1225134515.58)
