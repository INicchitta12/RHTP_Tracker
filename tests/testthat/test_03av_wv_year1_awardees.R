# test_03av_wv_year1_awardees.R ----------------------------------------------
# Session 54. West Virginia's seven named awards, $6,444,803.

suppressWarnings(suppressMessages(source(here::here("R", "03av_wv_year1_awardees.R"))))
wv <- wv_year1_awardees()

test_that("seven awards, $6,444,803, each quoted verbatim from its release", {
  expect_equal(nrow(wv), 7L)
  expect_equal(sum(wv$amount), 6444803)
  expect_silent(wv_assert_sources())
})

test_that("CAMC/Vandalia and the Cabell Huntington Foundation are the two hospital rows", {
  h <- wv[wv$distributed_to_hospital == "Yes", ]
  expect_setequal(h$awardee, c("CAMC/Vandalia Health", "Cabell Huntington Foundation"))
  expect_equal(sum(h$amount), 1224000)
  expect_true(all(h$recipient_type == "HOSPITAL_OR_SYSTEM"))
  # The foundation rests on §10.2's named-parent row, a reading -> LOW.
  expect_equal(h$determination_confidence[h$awardee == "Cabell Huntington Foundation"], "LOW")
})

test_that("the WVU nursing school is UNIVERSITY_OR_AHC and not a hospital dollar", {
  n <- wv[wv$awardee == "WVU Medicine Center for Nursing Education", ]
  expect_equal(n$recipient_type, "UNIVERSITY_OR_AHC")
  expect_equal(n$distributed_to_hospital, "No")
})

test_that("Ascend WV's '$2.4 million' is flagged rounded; Spotted Owl is not promoted", {
  a <- wv[wv$awardee == "Ascend WV", ]
  expect_equal(a$flag_reason, "AMOUNT_ROUNDED_IN_SOURCE")
  s <- wv[wv$awardee == "Spotted Owl Healthcare Organization", ]
  expect_equal(s$flag_reason, "RECIPIENT_TYPE_INFERRED")
  expect_equal(s$distributed_to_hospital, "No")
})

test_that("the committed CSV matches a fresh build", {
  d <- readr::read_csv(WV_CSV, show_col_types = FALSE)
  expect_equal(d$awardee, wv$awardee)
  expect_equal(d$amount, wv$amount)
})


# -- session 55: the probe ---------------------------------------------------

wv_news_arch <- here::here(WV_PROBE_DIR, "2026-09-23_wv_news_index.html")

test_that("the news index reads 30 articles and all five award releases", {
  a <- wv_news_articles(wv_news_arch)
  expect_equal(nrow(a), 30L)
  expect_true(all(unname(WV_SLUG) %in% a$slug))
})

test_that("on the archive, 'award' matches EXACTLY the five recorded releases", {
  # The tripwire's premise, measured: no funding-OPPORTUNITY release says
  # "award", so the word separates Tier 3 from Tier 2 on this index today.
  a <- wv_news_articles(wv_news_arch)
  hit <- a$slug[grepl("award", paste(a$headline, a$slug), ignore.case = TRUE)]
  expect_setequal(hit, unname(WV_SLUG))
  expect_silent(wv_assert_no_new_award_release(wv_news_arch))
})

test_that("a sixth award release TRIPS, by headline", {
  raw <- paste(readLines(wv_news_arch, warn = FALSE, encoding = "UTF-8"),
               collapse = "\n")
  fake <- paste0('<a href="/article/governor-morrisey-announces-award-mercy-hospital" ',
                 'title="Read article: Governor Morrisey Announces $1 Million Award ',
                 'to Example Rural Hospital">Full Story</a>')
  raw <- sub("</body>", paste0(fake, "</body>"), raw, fixed = TRUE)
  expect_error(wv_assert_no_new_award_release(charToRaw(raw)),
               "NEW AWARD RELEASE")
})

test_that("a reader that finds nothing is refused, not read as silence", {
  expect_error(wv_assert_no_new_award_release(charToRaw("<html><main></main></html>")),
               "the reader, not West Virginia")
})

test_that("both name-diffed pages have a real baseline and are silent on themselves", {
  for (k in WV_PROBE_PAGES$key[WV_PROBE_PAGES$name_diff]) {
    t <- wv_page_text(here::here(WV_PROBE_DIR,
                                 WV_PROBE_PAGES$file[WV_PROBE_PAGES$key == k]))
    expect_gte(length(rhtp_organisation_names(t)), 3L)
    expect_silent(rhtp_assert_no_new_organisations(t, t, "WV", k))
  }
})
