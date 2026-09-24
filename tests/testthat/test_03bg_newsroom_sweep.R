# test_03bg_newsroom_sweep.R -------------------------------------------------
# The newsroom sweep, offline: the committed baselines only.

library(testthat)
source(here::here("R", "03bg_newsroom_sweep.R"))

read_arch <- function(st, key) {
  f <- NW_PAGES$file[NW_PAGES$state == st & NW_PAGES$key == key]
  paste(readLines(here::here(f), warn = FALSE), collapse = "\n")
}

test_that("the sweep covers exactly the eighteen no-release states", {
  expect_silent(nw_assert_coverage())
  expect_setequal(union(NW_PAGES$state, NW_UNREADABLE$state), NW_STATES)
  expect_equal(length(NW_STATES), 18L)
  expect_setequal(NW_UNREADABLE$state, c("MA", "MD", "NH", "IL"))
})

test_that("every baseline exists and yields enough headlines to have been read", {
  for (i in seq_len(nrow(NW_PAGES))) {
    f <- here::here(NW_PAGES$file[i])
    expect_true(file.exists(f), info = NW_PAGES$file[i])
    expect_gte(length(nw_headlines(paste(readLines(f, warn = FALSE),
                                         collapse = "\n"))), 15L)
  }
})

test_that("POSITIVE CONTROL: New Jersey's own award headline would have fired", {
  arch <- read_arch("NJ", "doh")
  hl <- "ICYMI: New Jersey Awards First Round of Rural Health Transformation Grants"
  expect_true(hl %in% nw_headlines(arch))
  # the baseline as it would have been BEFORE 2026-07-31
  before <- gsub(hl, "An unrelated item about something else entirely", arch, fixed = TRUE)
  expect_equal(nw_new_hot(arch, before, "NJ", "doh"), hl)
  # and against today's baseline it is not new, so it does not fire
  expect_length(nw_new_hot(arch, arch, "NJ", "doh"), 0L)
})

test_that("Tennessee's headline matches, and ordinary newsroom churn does not", {
  tn <- "Tennessee Department of Health Announces 1st Recipients of Rural Health Transformation Program Grants"
  expect_true(grepl(NW_RHTP, tn, ignore.case = TRUE) &&
                grepl(NW_AWARD, tn, ignore.case = TRUE))
  noise <- c("Governor Signs Executive Order on Wildfire Preparedness",
             "Rural Health Transformation Program Launches New Website",
             "State Awards Road Construction Grants to 12 Counties")
  hot <- noise[grepl(NW_RHTP, noise, ignore.case = TRUE) &
                 grepl(NW_AWARD, noise, ignore.case = TRUE)]
  expect_length(hot, 0L)
})

test_that("a page the reader cannot read is an ERROR about access, not a tripwire", {
  e <- tryCatch(nw_new_hot("<html><body><a>x</a></body></html>",
                           read_arch("TX", "hhsc"), "TX", "hhsc"),
                error = function(e) conditionMessage(e))
  expect_match(e, "HTTP 200")
})
