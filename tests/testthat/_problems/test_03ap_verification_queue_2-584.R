# Extracted from test_03ap_verification_queue_2.R:584

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
