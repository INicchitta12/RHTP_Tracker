# Extracted from test_03ap_verification_queue_2.R:610

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
