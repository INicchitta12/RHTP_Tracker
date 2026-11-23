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
  h <- charToRaw('<html><body><main><a href="https://www.chfs.ky.gov/a.pdf">a</a><a href="https://cal.com/x">b</a><a href="https://dhhs.ne.us/c">c</a><a href="/rel">d</a></main></body></html>')
  expect_setequal(rtl_official_links(h), c("https://www.chfs.ky.gov/a.pdf", "https://dhhs.ne.us/c"))
})

test_that("session 122: links come from the page BODY only, never the site-wide banner", {
  cms <- RTL_SITEWIDE_LINKS[[1]]
  # The 11-20 shape: the CMS FY2027 release in the news banner, outside <main>,
  # on every page of the site. It must never be reported as a lead's source.
  h <- charToRaw(paste0(
    '<html><body><div data-news-banner="true"><a href="', cms, '">Latest</a></div>',
    '<header><a href="https://www.hhs.gov/x">hhs</a></header>',
    '<main><p>Who Vermont has funded</p><a href="https://humanservices.vermont.gov/rhtp/awards.pdf">VT</a></main>',
    '<footer><a href="https://www.usa.gov/">usa</a></footer></body></html>'))
  expect_identical(rtl_official_links(h), "https://humanservices.vermont.gov/rhtp/awards.pdf")
  # ...even if the site-wide link moves inside <main>.
  h2 <- charToRaw(paste0('<html><body><main><a href="', cms, '">x</a></main></body></html>'))
  expect_length(rtl_official_links(h2), 0L)
  # A page with no <main> yields nothing rather than the whole page's links.
  h3 <- charToRaw(paste0('<html><body><a href="https://www.chfs.ky.gov/a.pdf">a</a></body></html>'))
  expect_length(rtl_official_links(h3), 0L)
  # The archived 11-23 Vermont awards page (access-gated): no official link at all.
  f <- here::here("data/evidence/leads/rhtptracker/2026-11-23/VT_awards_GATED.html")
  if (file.exists(f)) expect_length(rtl_official_links(readBin(f, "raw", file.size(f))), 0L)
})

test_that("session 122: the state is read from an opportunity page's address", {
  u <- "https://www.rhtptracker.com/opportunities/"
  expect_equal(rtl_state_of(paste0(u, "page-al-nofo-for-rural-health-initiative-2026-cc4912")), "AL")
  expect_equal(rtl_state_of(paste0(u, "email-ks-kdhe-announces-two-additional-grant-opportunities-in-second-round-of-rhtp-fundin-2026")), "KS")
  expect_equal(rtl_state_of(paste0(u, "portal-ri-ride-tele-behavioral-health-services-in-rhode-island-schools-2026-a2f1f5")), "RI")
  expect_equal(rtl_state_of(paste0(u, "rhtp-nv-rural-reentry-flex-2026")), "NV")
  expect_equal(rtl_state_of(paste0(u, "nav-va-consumer-tech-for-education-and-lifestyle-change-2026-e9b4b5")), "VA")
  # Not a state code: falls through to the title, then UNKNOWN.
  expect_equal(rtl_state_of(paste0(u, "page-zz-something-2026")), "UNKNOWN")
  expect_equal(rtl_state_of(paste0(u, "page-zz-something-2026"), "Thing (Ohio)"), "OH")
})
