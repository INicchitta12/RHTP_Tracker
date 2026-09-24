# test_probe_coverage.R ------------------------------------------------------
# A scheduled probe that leaves no line in logs/probe_results.csv FAILS.
#
# WHY THIS FILE EXISTS (session 52). New York's Routine fired five times after
# its roster went public on 2026-09-04, every run read SUCCEEDED, and not one
# verdict reached `main`: every line committed before session 52 was written by
# an interactive session. These tests drive the check in both directions on
# synthetic logs, and then run it on the committed log up to its own newest
# line, so the suite fails the day a registered Routine stops publishing.

library(testthat)

source(here::here("R", "probe_coverage.R"))

reg <- function(state = "NY", trig = "trig_TEST", cron = "10 11 * * 0,3",
                since = "2026-09-20T00:00:00Z") {
  tibble::tibble(state = state, trigger_id = trig, cron_utc = cron,
                 script = "R/03ag_ny_year1_probe.R", cadence = "x",
                 logging_since = as.POSIXct(since, format = "%Y-%m-%dT%H:%M:%SZ",
                                            tz = "UTC"))
}
lg <- function(state, at, origin) {
  tibble::tibble(state = state,
                 probed_at = as.POSIXct(at, tz = "UTC"),
                 verdict = "UNCHANGED", origin = origin)
}
t0 <- as.POSIXct("2026-09-24 00:00", tz = "UTC")


test_that("the cron reader is narrow and refuses what it does not parse", {
  f <- rhtp_cron_firings("10 11 * * 0,3", as.POSIXct("2026-09-20", tz = "UTC"),
                         as.POSIXct("2026-09-24", tz = "UTC"))
  # Sunday 20th and Wednesday 23rd, 11:10 UTC.
  expect_equal(format(f, "%Y-%m-%d %H:%M"), c("2026-09-20 11:10",
                                              "2026-09-23 11:10"))
  expect_error(rhtp_parse_cron("*/5 * * * *"), "not of the form")
  expect_error(rhtp_parse_cron("0 13 1 * *"), "not of the form")
})

test_that("a firing with NO log line fails, by state, time and trigger", {
  expect_error(
    rhtp_assert_probe_coverage(t0, reg(), lg("NY", "2026-09-20 11:12", "trig_TEST")),
    "NY 2026-09-23 11:10Z \\(trig_TEST\\)")
})

test_that("every due firing logged by its own Routine passes", {
  l <- rbind(lg("NY", "2026-09-20 11:12", "trig_TEST"),
             lg("NY", "2026-09-23 11:19", "trig_TEST"))
  cov <- rhtp_assert_probe_coverage(t0, reg(), l)
  expect_equal(nrow(cov), 2L)
  expect_true(all(cov$logged))
})

test_that("an INTERACTIVE run does not cover a Routine firing that left nothing", {
  # Alaska's 9/21 14:00 Routine run left nothing and a session's 16:37 probe
  # sat inside its window; without the origin column the check passed.
  l <- rbind(lg("NY", "2026-09-20 11:12", "trig_TEST"),
             lg("NY", "2026-09-23 13:00", "interactive"))
  expect_error(rhtp_assert_probe_coverage(t0, reg(), l), "2026-09-23 11:10Z")
})

test_that("another Routine's line does not cover this one", {
  l <- rbind(lg("NY", "2026-09-20 11:12", "trig_TEST"),
             lg("NY", "2026-09-23 11:15", "trig_OTHER"))
  expect_error(rhtp_assert_probe_coverage(t0, reg(), l), "2026-09-23")
})

test_that("a line with no origin at all is accepted as legacy", {
  # Main's pre-session-52 logger writes five columns; a Routine running that
  # code still published its verdict, and that is what the check asks.
  l <- rbind(lg("NY", "2026-09-20 11:12", NA_character_),
             lg("NY", "2026-09-23 11:15", NA_character_))
  expect_silent(rhtp_assert_probe_coverage(t0, reg(), l))
})

test_that("a line outside the grace window does not count", {
  l <- rbind(lg("NY", "2026-09-20 11:12", "trig_TEST"),
             lg("NY", "2026-09-23 18:00", "trig_TEST"))   # 6h50m late
  expect_error(rhtp_assert_probe_coverage(t0, reg(), l), "2026-09-23")
})

test_that("a firing still inside its grace window is neither passed nor failed", {
  l <- lg("NY", "2026-09-20 11:12", "trig_TEST")
  cov <- rhtp_probe_coverage(as.POSIXct("2026-09-23 12:00", tz = "UTC"),
                             reg(), l)
  expect_equal(nrow(cov), 1L)   # only the 20th is due
})

test_that("firings before logging_since are not asserted", {
  cov <- rhtp_probe_coverage(t0, reg(since = "2026-09-23T12:00:00Z"),
                             lg("NY", "2026-09-01 00:00", "trig_TEST")[0, ])
  expect_equal(nrow(cov), 0L)
})


# -- the committed registry and log -------------------------------------------

test_that("config/routines.csv names every Routine, each with a probe that logs", {
  r <- rhtp_read_routines()
  expect_true(rhtp_assert_routines_registry(r))
  # Every state file that runs a Routine is here, KS included (session 52).
  expect_true(all(c("NY", "KS", "SC", "MS", "WY") %in% r$state))
  expect_false(anyDuplicated(r$trigger_id) > 0)
})

test_that("the committed log carries the origin column", {
  l <- rhtp_read_probe_log()
  expect_true("origin" %in% names(l))
  # Every line written before session 52 is interactive, and says so.
  expect_true(all(l$origin[l$probed_at < as.POSIXct("2026-09-22 19:30",
                                                     tz = "UTC")] %in%
                    c("interactive", NA)))
})

test_that("every registered firing due before the log's newest line left a line", {
  # THE ASSERTION ON THE REAL DATA. Deterministic: it checks only up to the
  # newest line anybody committed, so it cannot fail because the clock moved,
  # only because a Routine that fired did not publish.
  expect_silent(rhtp_assert_probe_coverage(rhtp_probe_coverage_as_of_log()))
})

test_that("the counterfactual: the pre-fix Routines fail this check", {
  # Run from 9/20 on the committed log: the Routine firings that happened
  # before the fix are named, which is the finding this file was written for.
  r <- rhtp_read_routines()
  r$logging_since[] <- as.POSIXct("2026-09-20", tz = "UTC")
  expect_error(
    rhtp_assert_probe_coverage(as.POSIXct("2026-09-22 19:00", tz = "UTC"),
                               routines = r),
    "NY 2026-09-20 11:10Z")
})

test_that("an explained gap is a committed diagnosis, never a blanket pass (session 65)", {
  g <- rhtp_read_probe_gaps()
  # WA's 2026-09-24 10:10Z firing is the first explained miss, and it is still
  # a miss: the coverage table reports it NOT logged.
  expect_true(any(g$state == "WA" &
                    format(g$scheduled, "%Y-%m-%dT%H:%M") == "2026-09-24T10:10"))
  cov <- rhtp_assert_probe_coverage(rhtp_probe_coverage_as_of_log())
  wa <- cov[cov$state == "WA" &
              format(cov$scheduled, "%Y-%m-%dT%H:%M") == "2026-09-24T10:10", ]
  expect_false(wa$logged)
  expect_true(wa$explained)
  # a row that explains a firing which DID leave a line is refused
  tf <- tempfile(fileext = ".csv")
  readr::write_csv(tibble::tibble(
    state = "SC", scheduled_utc = "2026-09-24T08:30Z",
    trigger_id = "trig_017j3hddVSkzAAKn8esPawmR", cause = "x", evidence = "y"), tf)
  expect_error(rhtp_assert_probe_coverage(rhtp_probe_coverage_as_of_log(),
                                           explained = rhtp_read_probe_gaps(tf)),
               "not missed firings")
  # a row with no evidence is refused
  readr::write_csv(tibble::tibble(
    state = "WA", scheduled_utc = "2026-09-24T10:10Z",
    trigger_id = "trig_01XkZWESmQbqfq58cKuQ84i9", cause = "503", evidence = ""), tf)
  expect_error(rhtp_read_probe_gaps(tf), "cause AND evidence")
})
