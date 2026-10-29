# Extracted from test_03bj_enrolled_hospital_operator.R:400

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
n$rows <- n$rows - 6L
expect_equal(n$rows, 1325L)
expect_equal(round(n$dollars, 2), 1225134515.58)
expect_equal(n$states, 32L)
n$rows <- n$rows - 12L
n$dollars <- n$dollars - 8668315.59
expect_equal(n$rows, 1313L)
expect_equal(round(n$dollars, 2), 1216466199.99)
expect_equal(n$states, 32L)
n$rows <- n$rows - 5L
n$dollars <- n$dollars - 3124401.49
expect_equal(n$rows, 1308L)
expect_equal(round(n$dollars, 2), 1213341798.50)
n$rows <- n$rows - 9L
n$dollars <- n$dollars - 9581283.08
expect_equal(n$rows, 1299L)
expect_equal(round(n$dollars, 2), 1203760515.42)
n$rows <- n$rows - 9L
n$dollars <- n$dollars - 6390000
n$states <- n$states - 1L
expect_equal(n$rows, 1290L)
expect_equal(round(n$dollars, 2), 1197370515.42)
expect_equal(n$states, 31L)
n$rows <- n$rows - 2L
n$dollars <- n$dollars - 7007000
n$rows <- n$rows - 23L
n$dollars <- n$dollars - 21099804 - 9197657.15 - 8919452
n$rows <- n$rows - 4L
n$dollars <- n$dollars - 1700000 - 38525
expect_equal(n$rows, 1261L)
expect_equal(round(n$dollars, 2), 1149408077.27)
n$rows <- n$rows - 23L
n$dollars <- n$dollars - 435000 - 20886572
n$rows <- n$rows - 36L
n$dollars <- n$dollars - 86693159
n$states <- n$states - 1L
expect_equal(n$rows, 1202L)
expect_equal(round(n$dollars, 2), 1041393346.27)
n$dollars <- n$dollars - 2414763
n$dollars <- n$dollars - 12643596.75
n$dollars <- n$dollars - 4020144
expect_equal(n$states, 30L)
expect_equal(round(tot$dollars[tot$bucket == "POOL_NAMED_HOSPITALS"] - 1000000 - 30300000 -
                       4170261 - 20278054.31, 2), 30806856.12)
expect_equal(round(tot$dollars[tot$bucket == "POOL_UNNAMED_HOSPITALS"] - 19314845.17, 2),
               50008264)
expect_equal(round(n$dollars - 53539221.31, 2), 968775621.21)
