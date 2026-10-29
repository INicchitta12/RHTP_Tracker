# Extracted from test_03bj_enrolled_hospital_operator.R:319

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
