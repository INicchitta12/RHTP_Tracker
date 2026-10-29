# Extracted from test_03ap_verification_queue_2.R:676

# prequel ----------------------------------------------------------------------
library(testthat)
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
})
source(here::here("R", "03ap_verification_queue_2.R"))
ANSWERS <- suppressMessages(readr::read_csv(
  here::here(VQ_ANSWERS_CSV), col_types = readr::cols(.default = "c"),
  progress = FALSE))
CHANGES <- suppressMessages(readr::read_csv(
  here::here(VQ_CHANGES_CSV), col_types = readr::cols(.default = "c"),
  progress = FALSE))
ref <- function(f) suppressMessages(readr::read_csv(
  here::here("data/reference", f), col_types = readr::cols(.default = "c"),
  progress = FALSE))
VOCAB <- ref("vocabularies.csv")

# test -------------------------------------------------------------------------
p <- vq_partition()
t <- vq_bucket_totals(p)
named <- t %>% filter(bucket == "NAMED_HOSPITAL")
expect_equal(named$rows, 1835L)
expect_equal(round(named$dollars, 2), 1731421723.08, tolerance = 0)
expect_equal(named$states, 36L)
named$rows <- named$rows - 1L
named$dollars <- named$dollars - 110854
expect_equal(named$rows, 1834L)
expect_equal(round(named$dollars, 2), 1729133683.70, tolerance = 0)
named$rows <- named$rows - 60L
named$dollars <- named$dollars - 82903969.14
named$states <- named$states - 1L
expect_equal(named$rows, 1774L)
expect_equal(round(named$dollars, 2), 1646229714.56, tolerance = 0)
expect_equal(named$states, 35L)
named$rows <- named$rows - 189L
named$dollars <- named$dollars - 206275435.98
named$states <- named$states - 1L
expect_equal(named$rows, 1585L)
expect_equal(round(named$dollars, 2), 1439954278.58, tolerance = 0)
expect_equal(named$states, 34L)
named$rows <- named$rows - 9L
named$dollars <- named$dollars - 7979000
expect_equal(named$rows, 1576L)
expect_equal(round(named$dollars, 2), 1431975278.58, tolerance = 0)
named$rows <- named$rows - 38L
named$dollars <- named$dollars - 5561417.40
named$states <- named$states - 1L
expect_equal(named$rows, 1538L)
expect_equal(round(named$dollars, 2), 1426413861.18, tolerance = 0)
named$rows <- named$rows - 202L
named$dollars <- named$dollars - 119194693.55
named$states <- named$states - 1L
expect_equal(named$rows, 1336L)
expect_equal(round(named$dollars, 2), 1307219167.63, tolerance = 0)
named$dollars <- named$dollars - 1010206 + 3455421
expect_equal(round(named$dollars, 2), 1309664382.63, tolerance = 0)
named$rows <- named$rows - 5L
named$dollars <- named$dollars - 84529867.05
expect_equal(named$rows, 1331L)
expect_equal(named$states, 32L)
expect_equal(round(named$dollars, 2), 1225134515.58, tolerance = 0)
named$rows <- named$rows - 6L
expect_equal(named$rows, 1325L)
expect_equal(named$states, 32L)
expect_equal(round(named$dollars, 2), 1225134515.58, tolerance = 0)
named$rows <- named$rows - 12L
named$dollars <- named$dollars - 8668315.59
expect_equal(named$rows, 1313L)
expect_equal(named$states, 32L)
expect_equal(round(named$dollars, 2), 1216466199.99, tolerance = 0)
named$rows <- named$rows - 5L
named$dollars <- named$dollars - 3124401.49
expect_equal(named$rows, 1308L)
expect_equal(named$states, 32L)
expect_equal(round(named$dollars, 2), 1213341798.50, tolerance = 0)
named$rows <- named$rows - 9L
named$dollars <- named$dollars - 9581283.08
expect_equal(named$rows, 1299L)
expect_equal(named$states, 32L)
expect_equal(round(named$dollars, 2), 1203760515.42, tolerance = 0)
named$rows <- named$rows - 9L
named$dollars <- named$dollars - 6390000
named$states <- named$states - 1L
expect_equal(named$rows, 1290L)
expect_equal(named$states, 31L)
expect_equal(round(named$dollars, 2), 1197370515.42, tolerance = 0)
named$rows <- named$rows - 2L
named$dollars <- named$dollars - 7007000
named$rows <- named$rows - 23L
named$dollars <- named$dollars - 21099804 - 9197657.15 - 8919452
expect_equal(named$rows, 1265L)
expect_equal(round(named$dollars, 2), 1151146602.27, tolerance = 0)
named$rows <- named$rows - 4L
named$dollars <- named$dollars - 1700000 - 38525
named$rows <- named$rows - 23L
named$dollars <- named$dollars - 435000 - 20886572
expect_equal(named$rows, 1238L)
expect_equal(round(named$dollars, 2), 1128086505.27, tolerance = 0)
named$rows <- named$rows - 36L
named$dollars <- named$dollars - 86693159
named$states <- named$states - 1L
expect_equal(named$rows, 1202L)
expect_equal(named$states, 30L)
expect_equal(round(named$dollars, 2), 1041393346.27, tolerance = 0)
named$rows <- named$rows - 1L
named$dollars <- named$dollars - 2414763
expect_equal(named$rows, 1201L)
expect_equal(round(named$dollars, 2), 1038978583.27, tolerance = 0)
named$rows <- named$rows - 15L
named$dollars <- named$dollars - 12643596.75
named$rows <- named$rows - 1L
named$dollars <- named$dollars - 4020144
expect_equal(named$rows, 1185L)
expect_equal(round(named$dollars, 2), 1022314842.52, tolerance = 0)
named$rows <- named$rows - 33L
named$dollars <- named$dollars - 63240239.84
named$states <- named$states - 2L
expect_equal(named$rows, 1152L)
expect_equal(named$states, 28L)
expect_equal(round(named$dollars, 2), 959074602.68, tolerance = 0)
