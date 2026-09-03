# test_03ak_ms_year1_probe.R -------------------------------------------------
# Mississippi: selection COMPLETE, announcement PROMISED, nobody named -- and
# the first CMS footer here that is not 100% federal. Committed files only.
#
# The tests that carry the weight are the footer pair (Mississippi's headline
# is ACCEPTED as a Tier 2 pool by the shared rule and is not one) and the
# roster tripwire, because this state has publicly said it is about to publish
# the thing the tripwire watches for.

library(testthat)

source(here::here("R", "03ak_ms_year1_probe.R"))

skip_without_archive <- function() {
  if (!ms_have_archive()) skip("the MS evidence archive is not on disk")
}
as_raw_html <- function(txt) charToRaw(enc2utf8(txt))


test_that("Mississippi names no sub-award recipient", {
  skip_without_archive()
  expect_true(ms_assert_no_roster())
  expect_length(ms_award_language(ms_html_text("funding")), 0L)
})

test_that("the roster tripwire fires on every award phrase", {
  skip_without_archive()
  for (p in MS_AWARD_POSTED) {
    expect_error(
      ms_assert_no_roster(bodies = list(
        funding = as_raw_html(paste("<html><body>", p, "</body></html>")),
        home = as_raw_html("<html></html>"),
        gov_newsroom = as_raw_html("<html></html>"))),
      "award language has appeared", info = p)
  }
})

test_that("the tripwire does NOT fire on the page's own language", {
  skip_without_archive()
  # "selected applicants" and "sub-award execution" are already on the live
  # page. A tripwire that fires every run stops being read (session 29).
  txt <- stringr::str_to_lower(ms_html_text("funding"))
  expect_true(stringr::str_detect(txt, "selected applicants"))
  expect_true(stringr::str_detect(txt, "sub-award execution"))
  expect_length(ms_award_language(txt), 0L)
})

test_that("selection is complete and the announcement is promised", {
  skip_without_archive()
  expect_true(ms_assert_selection_complete_unnamed())
  expect_error(
    ms_assert_selection_complete_unnamed(
      body = as_raw_html("<html><body>nothing here</body></html>")),
    "no longer says")
})


# -- §0.2, the reason this file exists ---------------------------------------

test_that("the footer is NOT 100% federal and carries two figures", {
  skip_without_archive()
  f <- ms_assert_footer_is_not_fully_federal()
  expect_false(f$fully_federal)
  expect_equal(f$cms_pct, 99.96)
  expect_equal(f$headline_amount, MS_FOOTER_HEADLINE)
  expect_equal(f$cms_amount, MS_FOOTER_CMS_SHARE)
  expect_equal(f$nonfederal_amount, MS_FOOTER_NONFEDERAL)
})

test_that("the CMS share is the allotment and the headline is not", {
  skip_without_archive()
  expect_true(ms_assert_footer_cms_share_is_the_allotment())
  expect_lt(abs(MS_FOOTER_CMS_SHARE - MS_ALLOTMENT), 1)
  expect_gt(MS_FOOTER_HEADLINE - MS_ALLOTMENT,
            8 * RHTP_FOOTER_ALLOTMENT_MARGIN)
})

test_that("the footer's own arithmetic closes to the cent", {
  skip_without_archive()
  f <- rhtp_footer_parse(ms_html_text("funding"))
  expect_equal(f$headline_amount - f$cms_amount, f$nonfederal_amount)
})

test_that("a 100% restatement would break the finding loudly", {
  skip_without_archive()
  faked <- paste("<html><body>as part of a financial assistance award",
                 "totaling $205,990,180.16 with 100 percent funded by",
                 "CMS/HHS.</body></html>")
  expect_error(ms_assert_footer_is_not_fully_federal(as_raw_html(faked)),
               "now 100% federal")
})


# -- the controls ------------------------------------------------------------

test_that("the Governor's newsroom is a working award channel", {
  skip_without_archive()
  ctl <- ms_assert_governor_channel_control()
  expect_gte(ctl$announcements, 3L)
})

test_that("an RHTP AWARD item on the newsroom stops the build", {
  skip_without_archive()
  # The control needs its OWN announcements to survive, or it fails for the
  # other reason -- so the fake carries four announcement lines, three of
  # them ordinary and one an RHTP award.
  faked <- paste0("<html><body><p>Gov. Reeves Announces One</p>\n",
                  "<p>Gov. Reeves Announces Two</p>\n",
                  "<p>Gov. Reeves Announces Three</p>\n",
                  "<p>Gov. Reeves Announces Rural Health Transformation ",
                  "Program Sub-Award Recipients</p></body></html>")
  expect_error(ms_assert_governor_channel_control(as_raw_html(faked)),
               "reads as an AWARD")
})

test_that("DOM's one RHTP award predates the NOA, and DOM publishes awards", {
  skip_without_archive()
  ctl <- ms_assert_dom_consultant_predates_noa()
  expect_gte(ctl$intents, 5L)
  expect_equal(ctl$days_before_noa, 138L)
  expect_lt(MS_CONSULTANT_AWARDED, MS_NOA_DATE)
})

test_that("the §6.2 sweep already caught the consultant row", {
  # Machine and hand agreeing from two directions, session 20 and session 44.
  f <- readr::read_csv(here::here("data", "reference",
                                  "provenance_sweep_flagged_rows.csv"),
                       show_col_types = FALSE, progress = FALSE)
  horne <- f[f$state == "MS", ]
  expect_equal(nrow(horne), 1L)
  expect_true(any(grepl("Horne", horne$awardee_name_raw, ignore.case = TRUE)))
  expect_true(any(grepl("PREDATES_NOA", horne$new_flags)))
})


# -- the tables --------------------------------------------------------------

test_that("the status table has no amount column and no award file exists", {
  st <- ms_status_table()
  expect_false("amount" %in% names(st))
  expect_gte(nrow(st), 8L)
  expect_false(file.exists(here::here("data", "reference",
                                      "ms_year1_awardees.csv")))
})

test_that("the disposition covers all three candidates and refuses a fourth", {
  d <- ms_disposition()
  expect_equal(sum(d$rcj_rows), 3L)
  expect_true(all(grepl("NOT_", d$disposition)))
})

test_that("Mississippi contributes no row and no dollar to any bucket", {
  st <- ms_status_table()
  expect_true(all(st$publishes_roster != "Yes"))
})
