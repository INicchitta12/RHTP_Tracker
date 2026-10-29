# Extracted from test_03ap_verification_queue_2.R:774

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
p <- vq_partition() %>% filter(bucket == "NAMED_HOSPITAL") %>%
    arrange(desc(dollars))
expect_equal(round(p$dollars[p$state == "AR"] - 18870981.65 - 17060066, 2),
               92405913.87, tolerance = 0)
expect_gt(p$dollars[p$state == "AR"] - 18870981.65 - 17060066,
            p$dollars[p$state == "GA"])
expect_equal(p$state[[1]], "TX")
expect_equal(round(p$dollars[[1]], 2), 189124104.63)
