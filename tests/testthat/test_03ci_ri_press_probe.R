# test_03ci_ri_press_probe.R -------------------------------------------------
# Rhode Island's portal press watch (session 107). Offline: committed baselines.

library(testthat)
source(here::here("R", "03ci_ri_press_probe.R"))

rss <- ri_archived("rss"); idx <- ri_archived("index")

test_that("the baselines parse: 50 feed items, at least 5 agencies, quiet against themselves", {
  expect_equal(nrow(ri_feed_items(rss)), 50L)
  expect_gte(nrow(ri_agencies(idx)), 5L)
  expect_length(ri_findings(rss, rss, idx, idx), 0L)
})

test_that("a planted RHTP item in the feed is a finding", {
  t <- ri_text(rss)
  t2 <- sub("<item>", paste0("<item><title>EOHHS Announces Rural Health Transformation ",
                             "Program Awards</title><link>http://www.ri.gov/press/view/99999</link>",
                             "<description>Awards to named hospitals.</description>",
                             "<pubDate>Tue, 27 Oct 2026 12:00:00 GMT</pubDate></item><item>"),
            t, fixed = TRUE)
  f <- ri_findings(charToRaw(enc2utf8(t2)), rss, idx, idx)
  expect_length(f, 1L)
  expect_match(f, "Rural Health Transformation", fixed = TRUE)
})

test_that("a new agency on the index is a finding", {
  t <- ri_text(idx)
  t2 <- sub("href=\"/press/?agency_id=26\">Board of Elections</a>",
            "href=\"/press/?agency_id=26\">Board of Elections</a><a href=\"/press/?agency_id=999\">Executive Office of Health and Human Services</a>",
            t, fixed = TRUE)
  f <- ri_findings(rss, rss, charToRaw(enc2utf8(t2)), idx)
  expect_true(any(grepl("Executive Office of Health and Human Services", f, fixed = TRUE)))
})

test_that("an empty archived baseline refuses rather than passes (§2.3)", {
  empty <- charToRaw("<rss><channel></channel></rss>")
  expect_error(ri_findings(rss, empty, idx, idx), "reader has failed")
})

test_that("the probe routes through rhtp_probe_run and runs the shared name tripwire", {
  src <- paste(readLines(here::here("R", "03ci_ri_press_probe.R")), collapse = "\n")
  expect_true(grepl("rhtp_probe_run(RI_STATE, ri_probe())", src, fixed = TRUE))
  expect_true(grepl("rhtp_assert_no_new_organisations_across(", src, fixed = TRUE))
})
