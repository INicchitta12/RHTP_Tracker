# test_00_cms_press_monitor.R ------------------------------------------------
# The CMS trigger-list parser. Fixture-driven, no network calls, zero API quota.
#
# medicaid.gov is not on the environment allowlist, so this parser has never
# seen the real page (see the egress note in R/00_cms_press_monitor.R). That
# makes these tests the whole of its assurance, and they are written for the
# failure that actually matters: NOT that the parser reads one known table, but
# that it REFUSES every shape it does not understand rather than writing a CSV
# that reads as "no state has announced an award".

library(testthat)

source(here::here("R", "00_cms_press_monitor.R"))

fixture <- function(name) {
  paste(readLines(here::here("tests", "fixtures", "cms_press", name),
                  warn = FALSE), collapse = "\n")
}


# -- The tabular shape -------------------------------------------------------

test_that("the tabular shape parses to state, date, amount, title and URL", {
  out <- rhtp_parse_cms_press_html(fixture("table_shape.html"))

  expect_equal(attr(out, "cms_press_shape"), "TABLE")
  expect_equal(nrow(out), 4)
  expect_equal(out$state, c("DE", "FL", "GA", "OK"))
  expect_setequal(
    names(out),
    c("state", "date", "amount", "title", "url", "source_url", "first_seen")
  )
})

test_that("a navigation table is not mistaken for the announcement table", {
  # table_shape.html leads with a two-column site-navigation table. It has no
  # resolvable `state` column, so it scores -1 and the announcement table wins.
  # Picking by position would have taken the wrong one.
  out <- rhtp_parse_cms_press_html(fixture("table_shape.html"))
  expect_false(any(out$state == "Home"))
  expect_equal(nrow(out), 4)
})

test_that("state names and two-letter codes both resolve to the 7.1 fifty", {
  out <- rhtp_parse_cms_press_html(fixture("table_shape.html"))
  # 'Georgia', 'Florida', 'Oklahoma' by name; 'DE' by code.
  expect_true(all(out$state %in% rhtp_cms_states()$state))
  expect_true("DE" %in% out$state)
})

test_that("all four date formats on the fixture parse", {
  out <- rhtp_parse_cms_press_html(fixture("table_shape.html"))
  expect_false(any(is.na(out$date)))
  expect_equal(out$date[out$state == "GA"], as.Date("2025-12-29"))  # December 29, 2025
  expect_equal(out$date[out$state == "DE"], as.Date("2026-01-30"))  # 2026-01-30
  expect_equal(out$date[out$state == "OK"], as.Date("2026-02-14"))  # 02/14/2026
})

test_that("amounts parse from both literal and scaled currency strings", {
  out <- rhtp_parse_cms_press_html(fixture("table_shape.html"))
  expect_equal(out$amount[out$state == "FL"], 209000000)
  expect_equal(out$amount[out$state == "OK"], 223476949)
  # "$157.4 million" -- the scaled form
  expect_equal(out$amount[out$state == "DE"], 157400000)
  # "$218,862,169.63" rounds to the cent, not to a whole dollar
  expect_equal(out$amount[out$state == "GA"], 218862169.63, tolerance = 1e-6)
})

test_that("relative hrefs are absolutised and absolute ones left alone", {
  out <- rhtp_parse_cms_press_html(fixture("table_shape.html"))
  expect_true(all(startsWith(out$url, "https://www.medicaid.gov/")))
  expect_equal(out$url[out$state == "FL"], "https://www.medicaid.gov/newsroom/fl-rhtp")
})


# -- The link-list shape -----------------------------------------------------

test_that("a link list is parsed when the page carries no announcement table", {
  out <- rhtp_parse_cms_press_html(fixture("link_list_shape.html"))

  expect_equal(attr(out, "cms_press_shape"), "LINK_LIST")
  expect_equal(out$state, c("FL", "GA", "NE"))
  expect_equal(out$date[out$state == "GA"], as.Date("2026-07-16"))
  expect_equal(out$amount[out$state == "GA"], 30600000)
  expect_equal(out$amount[out$state == "FL"], 188201256)
})

test_that("a link list row with no amount is NA, never zero", {
  # Nebraska's fixture link states no figure. A zero would be a claim that CMS
  # announced nothing -- exactly the Nebraska $100,000 error in reverse
  # (CLAUDE.md 0.2a), so the absence must stay an absence.
  out <- rhtp_parse_cms_press_html(fixture("link_list_shape.html"))
  expect_true(is.na(out$amount[out$state == "NE"]))
})

test_that("links that name no state are ignored", {
  # The fixture carries an 'About this page' link.
  out <- rhtp_parse_cms_press_html(fixture("link_list_shape.html"))
  expect_equal(nrow(out), 3)
  expect_false(any(grepl("About", out$title)))
})


# -- Refusals: the point of the parser ---------------------------------------

test_that("two equally-scoring tables are refused, not resolved by position", {
  expect_error(
    rhtp_parse_cms_press_html(fixture("ambiguous_shape.html")),
    "score equally"
  )
})

test_that("a state outside the 7.1 fifty stops the parse", {
  # A dropped row is a state nobody collects, which is silent and unrecoverable.
  # Stopping is loud and recoverable.
  expect_error(
    rhtp_parse_cms_press_html(fixture("unknown_state.html")),
    "Puerto Rico"
  )
})

test_that("a page with neither shape is refused rather than parsed as empty", {
  expect_error(
    rhtp_parse_cms_press_html(fixture("no_table.html")),
    "No announcement table and no state-named links"
  )
})


# -- Assertions --------------------------------------------------------------

test_that("a zero-row parse fails the assertions", {
  empty <- rhtp_parse_cms_press_html(fixture("table_shape.html"))[0, ]
  expect_error(rhtp_cms_press_assert(empty), "Parsed zero announcements")
})

test_that("the fixture parse passes the assertions", {
  expect_true(rhtp_cms_press_assert(
    rhtp_parse_cms_press_html(fixture("table_shape.html"))
  ))
})

test_that("a future-dated announcement fails the assertions", {
  out <- rhtp_parse_cms_press_html(fixture("table_shape.html"))
  out$date[1] <- Sys.Date() + 30
  expect_error(rhtp_cms_press_assert(out), "dated in the future")
})

test_that("amounts totalling more than the whole programme fail the tier guard", {
  # 0.2: this page mixes CMS-to-state allotments (Tier 1) with state subaward
  # announcements (Tier 3). Summing the column blends them, and the guard is
  # what makes that unmissable to whoever adds a total to this stage next.
  out <- rhtp_parse_cms_press_html(fixture("table_shape.html"))
  out$amount <- rep(3e9, nrow(out))
  expect_error(rhtp_cms_press_assert(out), "Tier 1 and Tier 3")
})


# -- Amount parsing in isolation ---------------------------------------------

test_that("cms_press_parse_amount handles the forms a CMS page uses", {
  expect_equal(cms_press_parse_amount("$1,234,567"), 1234567)
  expect_equal(cms_press_parse_amount("$100 million"), 1e8)
  expect_equal(cms_press_parse_amount("$1.2 billion"), 1.2e9)
  expect_equal(cms_press_parse_amount("$218,862,169.63"), 218862169.63,
               tolerance = 1e-6)
})

test_that("cms_press_parse_amount returns NA, never 0, for a non-figure", {
  expect_true(is.na(cms_press_parse_amount("N/A")))
  expect_true(is.na(cms_press_parse_amount("")))
  expect_true(is.na(cms_press_parse_amount("Not yet announced")))
})


# -- Change detection --------------------------------------------------------

test_that("the first run reports every state as new", {
  withr::with_tempdir({
    out <- rhtp_parse_cms_press_html(fixture("table_shape.html"))
    # No committed CSV in a temp dir, but the delta reads via here::here(), so
    # exercise the first-run branch directly against a path that cannot exist.
    expect_true(is.character(out$state))
  })

  out <- rhtp_parse_cms_press_html(fixture("table_shape.html"))
  csv <- here::here(CMS_PRESS_CSV)
  skip_if(file.exists(csv),
          "cms_state_announcements.csv exists; the first-run branch no longer applies")

  delta <- rhtp_cms_press_delta(out)
  expect_true(delta$first_run)
  expect_setequal(delta$new_states, c("DE", "FL", "GA", "OK"))
})


# -- Wiring ------------------------------------------------------------------

# Conventions are a property of the CODE, not of the prose describing it: this
# file's own header says "never |>" and "No setwd()", so a naive grep over the
# whole source fails on the documentation of the rule it is checking.
monitor_code <- function() {
  readLines(here::here("R", "00_cms_press_monitor.R"), warn = FALSE) %>%
    stringr::str_remove("#.*$") %>%
    stringr::str_subset("\\S")
}

test_that("the monitor spends no RCJ quota", {
  expect_false(any(grepl("rhtp_api_key|rhtp_auth_headers|rhtp_endpoint_url",
                         monitor_code())))
})

test_that("the monitor uses %>% and never the native pipe (CLAUDE.md 3)", {
  expect_false(any(grepl("|>", monitor_code(), fixed = TRUE)))
})

test_that("the monitor never calls setwd (CLAUDE.md 3)", {
  expect_false(any(grepl("setwd(", monitor_code(), fixed = TRUE)))
})
