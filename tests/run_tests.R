# run_tests.R ----------------------------------------------------------------
# Zero-quota test runner. Safe to run at the start of every session.
#
#   Rscript tests/run_tests.R
#
# Sourcing a stage script never spends quota -- a pull happens only via the
# explicit --run flag on R/01_retrieve_rcj.R.

suppressPackageStartupMessages(library(testthat))

results <- testthat::test_dir(
  here::here("tests", "testthat"),
  reporter = "summary",
  stop_on_failure = TRUE
)
