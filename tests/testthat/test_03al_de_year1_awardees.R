# test_03al_de_year1_awardees.R ----------------------------------------------
# Delaware: FOUR award actions, THREE organisations, NO amounts, and the
# spec's own §0.3a worked example arriving as real data. Committed files only.
#
# THE TEST THAT CARRIES THE WEIGHT IS THE CLASSIFIER ONE. §8's name rule
# returns NONPROFIT_CBO at LOW for all three Delaware recipients, so left to
# the machine this state has NO hospital rows -- §0.3a's own defect reproduced
# in code. The override comes from the spec; these tests pin both halves so
# that a future change to either meets a failure rather than a silent flip.

library(testthat)

source(here::here("R", "03al_de_year1_awardees.R"))

skip_without_archive <- function() {
  if (!de_have_archive()) skip("the DE evidence archive is not on disk")
}
as_raw_html <- function(txt) charToRaw(enc2utf8(txt))


# -- §0.3a, measured ---------------------------------------------------------

test_that("§8's name rule misses ALL THREE Delaware recipients", {
  got <- de_assert_classifier_needs_the_override()
  expect_equal(unname(got), rep("NONPROFIT_CBO", 3L))
  expect_setequal(names(got), c("Nemours Children's Health", "TidalHealth",
                                "Beebe Healthcare"))
})

test_that("the counterfactual is priced: no override means NO hospital rows", {
  # What the file would report if a session trusted the classifier.
  d <- de_year1_awardees()
  naive <- d
  naive$recipient_type <- vapply(
    naive$awardee,
    function(n) rhtp_classify_recipient_type(n, "DE")$recipient_type,
    character(1))
  naive$distributed_to_hospital <- "No"
  naive$flow_type <- "NON_HOSPITAL"
  naive$hospital_attribution <- "NOT_HOSPITAL"
  expect_equal(nrow(rhtp_hospital_dollar_partition(naive)), 0L)
  # And with the override, four named-hospital rows.
  part <- rhtp_hospital_dollar_partition(d)
  expect_equal(part$bucket, "NAMED_HOSPITAL")
  expect_equal(part$rows, 4L)
  expect_equal(part$dollars, 0)
})

test_that("the same organisation classifies differently under two spellings", {
  # NC's UNC finding for the third time, and here it decides whether the
  # state has any hospital rows at all.
  expect_equal(rhtp_classify_recipient_type("Beebe Healthcare",
                                            "DE")$recipient_type,
               "NONPROFIT_CBO")
  expect_equal(rhtp_classify_recipient_type("Beebe Medical Center",
                                            "DE")$recipient_type,
               "HOSPITAL_OR_SYSTEM")
})

test_that("every row keeps the machine's answer for audit", {
  d <- de_year1_awardees()
  expect_true(all(grepl("shared classifier returns", d$recipient_type_source)))
  expect_true(all(grepl("OVERRIDDEN", d$recipient_type_source)))
  expect_true(all(d$determination_confidence == "MEDIUM"))
})


# -- the release -------------------------------------------------------------

test_that("the release names four awards and calls them awards", {
  skip_without_archive()
  expect_true(de_assert_four_awards())
})

test_that("a fifth award breaks the build rather than being ignored", {
  skip_without_archive()
  # The article region ends AT the CMS footer, so the injection has to go
  # before it or de_article_text() slices it straight off again.
  faked <- sub("This project is supported by",
               "Bayhealth - Milford Middle School This project is supported by",
               de_article_text(), fixed = TRUE)
  expect_error(
    de_assert_four_awards(as_raw_html(paste0("<html><body>", faked,
                                             "</body></html>"))),
    "occurs 5 times")
})

test_that("losing the word 'awards' breaks the build", {
  skip_without_archive()
  faked <- gsub("announced awards to establish four new school-based",
                "announced plans to establish four new school-based",
                de_article_text(), fixed = TRUE)
  expect_error(
    de_assert_four_awards(as_raw_html(paste0("<html><body>", faked,
                                             "</body></html>"))),
    "no longer says DHSS 'announced awards'")
})


# -- the amounts, which do not exist -----------------------------------------

test_that("Delaware prices nobody and the only figure is the allotment", {
  skip_without_archive()
  expect_true(de_assert_no_per_recipient_amount())
  d <- de_year1_awardees()
  expect_true(all(is.na(d$amount)))
  expect_true(all(is.na(d$round_amount)))
})

test_that("an amount appearing forces a REWRITE rather than passing", {
  skip_without_archive()
  faked <- sub("This project is supported by",
               "Each award is $48,750. This project is supported by",
               de_article_text(), fixed = TRUE)
  expect_error(
    de_assert_no_per_recipient_amount(as_raw_html(paste0("<html><body>", faked,
                                                         "</body></html>"))),
    "must be REWRITTEN")
})

test_that("the derived per-recipient figure is refused by the guard", {
  d <- de_year1_awardees()
  d$amount <- DE_SBHC_YEAR1_BUDGET / 4
  expect_error(de_assert_row_count_is_the_finding(d), "now carries an amount")
})

test_that("§0.2: the footer is Tier 1 and is refused as a pool", {
  skip_without_archive()
  expect_true(de_assert_footer_is_the_allotment())
  expect_lt(abs(DE_FOOTER - DE_ALLOTMENT), 1)
})

test_that("the $195,000 is a budget line and stays out of the award file", {
  skip_without_archive()
  expect_true(de_assert_pool_is_a_budget_not_a_round())
  d <- de_year1_awardees()
  expect_false(any(d$round_amount %in% DE_SBHC_YEAR1_BUDGET, na.rm = TRUE))
  expect_true(grepl("BUDGET LINE", d$amount_basis[1]))
})

test_that("the fifteen live budgets match the §7A table parsed in session 8", {
  # A PDF read in February and a page read in September, agreeing to the cent,
  # arranged by nobody.
  skip_without_archive()
  txt <- de_html_text("programme")
  live <- as.numeric(gsub(",", "", stringr::str_match_all(
    txt, "Year 1 Budget: \\$([0-9,]+\\.[0-9]{2})")[[1]][, 2]))
  expect_equal(length(live), 15L)
  init <- readr::read_csv(here::here("data", "interim", "initiatives.csv"),
                          show_col_types = FALSE, progress = FALSE)
  tbl <- init$initiative_budget[init$state == "DE" &
                                init$initiative_no_source >= 1]
  expect_equal(sort(round(live, 2)), sort(round(tbl, 2)))
  expect_equal(sum(live), 141655467.48)
})


# -- the coding --------------------------------------------------------------

test_that("all four rows are DIRECT / Yes -- §10.2's own worked example", {
  d <- de_year1_awardees()
  expect_true(all(d$flow_type == "DIRECT"))
  expect_true(all(d$distributed_to_hospital == "Yes"))
  expect_true(all(d$recipient_type == "HOSPITAL_OR_SYSTEM"))
  expect_true(all(d$hospital_attribution == "NAMED_HOSPITAL"))
  # NOT NON_HOSPITAL, which is the coding §0.3a exists to prevent.
  expect_false(any(d$flow_type == "NON_HOSPITAL"))
})

test_that("the awardee field is split from the site", {
  d <- de_year1_awardees()
  expect_false(any(grepl("Middle School", d$awardee)))
  expect_true(all(grepl("Middle School", d$award_site)))
  expect_true(all(grepl("Middle School", d$awardee_as_published)))
})

test_that("four rows, three organisations -- both counts stated", {
  d <- de_year1_awardees()
  expect_equal(nrow(d), 4L)
  expect_equal(length(unique(d$awardee)), 3L)
  expect_equal(sum(d$awardee == "Beebe Healthcare"), 2L)
  expect_true(de_assert_row_count_is_the_finding(d))
})

test_that("the award postdates the Notice of Award", {
  expect_gt(de_assert_after_noa(), 200L)
})

test_that("the disposition covers all six candidates", {
  d <- de_disposition()
  expect_equal(sum(d$rcj_rows), 6L)
  expect_true(any(grepl("PLACEHOLDER", d$disposition)))
})

test_that("the status table has no amount column", {
  st <- de_status_table()
  expect_false("amount" %in% names(st))
  expect_true("year1_budget" %in% names(st))
  expect_equal(nrow(st), 16L)
})
