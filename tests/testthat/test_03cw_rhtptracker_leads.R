# test_03cw_rhtptracker_leads.R -- the rhtptracker.com LEAD check (session 118)
library(testthat)
suppressMessages(source(here::here("R", "03cw_rhtptracker_leads.R")))

test_that("LEAD is a probe verdict, and the baseline verifies", {
  expect_true("LEAD" %in% RHTP_PROBE_VERDICTS)
  expect_true(rtl_validate())
})

test_that("a lead never carries a figure", {
  m <- rtl_lead_msg("TN", "https://www.rhtptracker.com/opportunities/x",
                    rtl_strip_money("Tennessee $422 Million in grants, $1,250,000 each (Tennessee)"),
                    "https://www.tn.gov/health/rural/grants")
  expect_false(grepl("\\$[0-9]", m))
  expect_match(m, "[amount removed]", fixed = TRUE)
  expect_match(m, "https://www.tn.gov/health/rural/grants", fixed = TRUE)
})

test_that("the state is read from the URL or the title, and robots.txt paths are refused", {
  expect_equal(rtl_state_of("https://www.rhtptracker.com/states/MO/awards"), "MO")
  expect_equal(rtl_state_of("https://www.rhtptracker.com/opportunities/page-x", "Rapid Response (Kentucky)"), "KY")
  expect_equal(rtl_state_of("https://www.rhtptracker.com/opportunities/page-x", "No state"), "UNKNOWN")
  expect_error(rtl_get("https://www.rhtptracker.com/api/states"), "disallowed")
})

test_that("only .gov / .us links count as official", {
  h <- charToRaw('<html><body><a href="https://www.chfs.ky.gov/a.pdf">a</a><a href="https://cal.com/x">b</a><a href="https://dhhs.ne.us/c">c</a><a href="/rel">d</a></body></html>')
  expect_setequal(rtl_official_links(h), c("https://www.chfs.ky.gov/a.pdf", "https://dhhs.ne.us/c"))
})
