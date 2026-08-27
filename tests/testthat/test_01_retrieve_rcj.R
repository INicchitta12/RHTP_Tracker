# test_01_retrieve_rcj.R ------------------------------------------------------
# Stage 1 unit tests. Pure functions only -- these make no network calls and
# cost zero API quota, so they can run on every session start.
#
# The centrepiece is rhtp_page_plan(). It encodes the §5.2 requirement that a
# page count is computed from the response envelope and never from the limit
# this client requested, because RCJ silently downgrades an over-max limit to
# its own maximum while returning HTTP 200. That trap is live on /documents
# and /opportunities today.

library(testthat)

source(here::here("R", "01_retrieve_rcj.R"))


# -- The live §5.2 trap ----------------------------------------------------

test_that("a silently downgraded limit does not cause a short read", {
  # The exact live case: /documents?limit=500 returns HTTP 200 serving 100 rows
  # and echoing pagination.limit: 100, against a corpus of 3,092.
  plan <- rhtp_page_plan(
    requested_limit = 500,
    served_limit    = 100,
    total           = 3092,
    pages_reported  = 31
  )

  expect_equal(plan$pages_needed, 31)
  expect_true(plan$limit_downgraded)
  expect_false(plan$pages_mismatch)

  # The bug this guards against: trusting the requested limit yields 7 pages,
  # which would read 700 of 3,092 records and report success.
  expect_false(plan$pages_needed == ceiling(3092 / 500))
})

test_that("the downgrade flag is off when the server honours the request", {
  # /awards genuinely serves limit=500.
  plan <- rhtp_page_plan(
    requested_limit = 500,
    served_limit    = 500,
    total           = 1429,
    pages_reported  = 3
  )

  expect_equal(plan$pages_needed, 3)
  expect_false(plan$limit_downgraded)
  expect_false(plan$pages_mismatch)
})

test_that("measured Session 2 totals reproduce the documented page counts", {
  # docs/stage1_pagination_test.md §1, all three endpoints.
  expect_equal(rhtp_page_plan(500, 500, 1429, 3)$pages_needed, 3)
  expect_equal(rhtp_page_plan(100, 100, 3092, 31)$pages_needed, 31)
  expect_equal(rhtp_page_plan(100, 100, 631, 7)$pages_needed, 7)
})


# -- Arithmetic edges ------------------------------------------------------

test_that("an exact multiple does not produce a trailing empty page", {
  plan <- rhtp_page_plan(100, 100, 300, 3)
  expect_equal(plan$pages_needed, 3)
})

test_that("an empty collection walks zero pages", {
  plan <- rhtp_page_plan(100, 100, 0, 0)
  expect_equal(plan$pages_needed, 0)
})

test_that("a single partial page walks one page", {
  plan <- rhtp_page_plan(500, 500, 15, 1)
  expect_equal(plan$pages_needed, 1)
})


# -- Disagreement between the server's page count and the arithmetic -------

test_that("a disagreeing pagination.pages is flagged and the larger is walked", {
  # Under-walking loses records silently; over-walking costs one call that
  # returns nothing. Always prefer the larger.
  plan <- rhtp_page_plan(
    requested_limit = 100,
    served_limit    = 100,
    total           = 3092,
    pages_reported  = 25
  )

  expect_true(plan$pages_mismatch)
  expect_equal(plan$pages_needed, 31)
})

test_that("a server page count larger than the arithmetic is also honoured", {
  plan <- rhtp_page_plan(100, 100, 300, 5)

  expect_true(plan$pages_mismatch)
  expect_equal(plan$pages_needed, 5)
})

test_that("a missing pagination.pages is recorded as NA, not a mismatch", {
  plan <- rhtp_page_plan(100, 100, 250, NULL)

  expect_equal(plan$pages_needed, 3)
  expect_false(plan$pages_mismatch)
  expect_true(is.na(plan$pages_reported))
})


# -- Refusing to guess -----------------------------------------------------

test_that("an unusable served limit is an error, never a guess", {
  # Guessing here is precisely how a silent short read happens.
  expect_error(rhtp_page_plan(100, NULL, 3092, 31), "pagination.limit")
  expect_error(rhtp_page_plan(100, NA, 3092, 31), "pagination.limit")
  expect_error(rhtp_page_plan(100, 0, 3092, 31), "pagination.limit")
})

test_that("a missing total is an error, since exhaustiveness cannot be asserted", {
  expect_error(rhtp_page_plan(100, 100, NULL, 31), "pagination.total")
  expect_error(rhtp_page_plan(100, 100, NA, 31), "pagination.total")
})


# -- Credential safety -----------------------------------------------------

test_that("the API key never survives into a manifest params string", {
  withr_key <- Sys.getenv("RCJ_API_KEY", unset = "")
  Sys.setenv(RCJ_API_KEY = "rhtp_pretend_secret_value_0123456789")
  on.exit(
    if (nzchar(withr_key)) {
      Sys.setenv(RCJ_API_KEY = withr_key)
    } else {
      Sys.unsetenv("RCJ_API_KEY")
    },
    add = TRUE
  )

  params <- rhtp_format_params(list(
    page = 1, limit = 100, token = "rhtp_pretend_secret_value_0123456789"
  ))

  expect_false(grepl("rhtp_pretend_secret_value_0123456789", params, fixed = TRUE))
  expect_true(grepl("REDACTED", params))
  expect_true(grepl("page=1", params, fixed = TRUE))
})

test_that("an empty query renders as an empty params string", {
  expect_equal(rhtp_format_params(list()), "")
})


# -- Handler / envelope pairing --------------------------------------------

test_that("a handler refuses an endpoint whose envelope it does not own", {
  # /activity is a hasMore envelope; sending it to the pagination handler is
  # exactly how a short read gets introduced.
  expect_error(rhtp_fetch_paginated("activity"), "envelope")

  # /awards is a pagination envelope.
  expect_error(rhtp_fetch_hasmore("awards"), "envelope")
})

test_that("an unknown endpoint is rejected before any request is built", {
  expect_error(rhtp_fetch_paginated("not_a_real_endpoint"), "Unknown endpoint")
  expect_error(rhtp_fetch_complete("not_a_real_endpoint"), "Unknown endpoint")
})

test_that("/states is routed to the complete-set handler, not the paginated one", {
  # §4 and config both had /states under the {data, pagination} envelope. A
  # live call returns {data, count} with no pagination object. Sending it to
  # the paginated handler is what surfaced the error.
  expect_equal(rhtp_config()$endpoints$states$envelope, "complete")
  expect_error(rhtp_fetch_paginated("states"), "envelope")
  expect_error(rhtp_fetch_complete("awards"), "envelope")
})


# -- Config wiring ---------------------------------------------------------

test_that("config carries the Branch A settings this stage depends on", {
  cfg <- rhtp_config()

  expect_equal(cfg$endpoints$awards$max_limit, 500)
  expect_equal(cfg$endpoints$documents$max_limit, 100)
  expect_equal(cfg$endpoints$opportunities$max_limit, 100)
  expect_equal(cfg$endpoints$activity$envelope, "hasmore")

  # The /activity walk has no `total` to bound it, so a ceiling must exist.
  expect_true(is.numeric(cfg$pull$activity_max_pages))
  expect_gt(cfg$pull$activity_max_pages, 0)

  # Throttle must stay under the documented 60/min, which no header reports.
  expect_lt(cfg$quota$throttle_requests_per_minute, 60)
})

test_that("the session is in a UTF-8 locale", {
  # Cloud sessions default to C/POSIX, where readLines() and stringr break on
  # multibyte input -- including config.yml and RCJ record titles.
  expect_true(isTRUE(l10n_info()$`UTF-8`))
})
