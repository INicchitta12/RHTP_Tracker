# test_03an_oh_year1_awardees.R ----------------------------------------------
# Ohio: ONE named, PRICED award, to a university. Committed files only.
#
# THE TEST THAT CARRIES THE WEIGHT IS THE FOOTER ONE. Ohio's CMS footer prints
# $10,000,000 -- the SUBAWARD, not the allotment and not a pool -- which is a
# position §0.2 had not met, and one the tier check cannot classify because
# the §7.1 anchor is the only external number it has. That limit is pinned
# here rather than papered over.

library(testthat)

source(here::here("R", "03an_oh_year1_awardees.R"))

skip_without_archive <- function() {
  if (!oh_have_archive()) skip("the OH evidence archive is not on disk")
}
as_raw_html <- function(txt) charToRaw(enc2utf8(txt))


test_that("the release names Ohio University at $10,000,000", {
  skip_without_archive()
  expect_true(oh_assert_the_award())
  d <- oh_year1_awardees()
  expect_equal(d$awardee, "Ohio University")
  expect_equal(d$amount, 10000000)
  expect_equal(d$amount_confirmed, "Yes")
})


# -- §0.2: a footer whose figure is the SUBAWARD -----------------------------

test_that("the footer prints the subaward, not the allotment or a pool", {
  skip_without_archive()
  f <- rhtp_footer_parse(oh_html_text("release"))
  expect_equal(nrow(f), 1L)
  expect_true(f$fully_federal)
  expect_equal(f$tier_amount, OH_AWARD)
  expect_equal(f$tier_amount, 10000000)
  # Neither the allotment ...
  expect_gt(abs(OH_AWARD - OH_ALLOTMENT), RHTP_FOOTER_ALLOTMENT_MARGIN)
  # ... nor anything the tier check can distinguish from a pool.
  expect_true(oh_assert_footer_is_the_subaward())
})

test_that("the tier check ACCEPTS it as a pool, which is the pinned limit", {
  a <- tibble::tibble(state = "OH", fy2026_allotment = OH_ALLOTMENT)
  # Correct on the only question it can ask ...
  expect_error(
    rhtp_assert_footer_not_allotment(OH_AWARD, "OH", "STATE_ALLOTMENT",
                                     allotments = a),
    "declared STATE_ALLOTMENT")
  # ... and silent on the one that matters here. What says Tier 3 is the
  # DOCUMENT: one recipient, one figure, one headline.
  expect_true(rhtp_assert_footer_not_allotment(OH_AWARD, "OH", "SOLICITATION",
                                               allotments = a))
})


# -- the coding --------------------------------------------------------------

test_that("a university is NON_HOSPITAL and Ohio has no hospital bucket", {
  d <- oh_year1_awardees()
  expect_equal(d$recipient_type, "UNIVERSITY_OR_AHC")
  expect_equal(d$flow_type, "NON_HOSPITAL")
  expect_equal(d$distributed_to_hospital, "No")
  expect_true(oh_assert_contributes_no_bucket())
  expect_equal(nrow(rhtp_hospital_dollar_partition(d)), 0L)
})

test_that("the counterfactual is priced at eight figures", {
  # One wrong recipient_type and a state with no hospital dollars acquires
  # $10,000,000 of them. This is why a one-row file is in the union test.
  d <- oh_year1_awardees()
  d$recipient_type <- "HOSPITAL_OR_SYSTEM"
  d$flow_type <- "DIRECT"
  d$distributed_to_hospital <- "Yes"
  d$hospital_attribution <- "NAMED_HOSPITAL"
  part <- rhtp_hospital_dollar_partition(d)
  expect_equal(part$dollars, 10000000)
})

test_that("the classifier agrees WITHOUT an override", {
  # The contrast with Delaware, stated as a test rather than as a comment.
  cls <- rhtp_classify_recipient_type("Ohio University", "OH")
  expect_equal(cls$recipient_type, "UNIVERSITY_OR_AHC")
  expect_equal(cls$determination_confidence, "MEDIUM")  # §7 ceiling, session 88
  expect_equal(oh_year1_awardees()$recipient_type, cls$recipient_type)
})


# -- the partial year --------------------------------------------------------

test_that("Ohio says more is coming, so the file is a PARTIAL year", {
  skip_without_archive()
  expect_true(oh_assert_more_to_come())
  faked <- gsub("Additional contracts will be awarded", "All contracts awarded",
                oh_html_text("release"), fixed = TRUE)
  expect_error(
    oh_assert_more_to_come(as_raw_html(paste0("<html><body>", faked,
                                              "</body></html>"))),
    "no longer says")
  # $192,030,262 of the allotment is in no public roster.
  expect_equal(OH_ALLOTMENT - OH_AWARD, 192030262)
})

test_that("ODH names nobody, and naming somebody stops the build", {
  skip_without_archive()
  expect_true(oh_assert_odh_names_nobody())
  expect_error(
    oh_assert_odh_names_nobody(
      as_raw_html("<html><body>Ohio University was awarded</body></html>")),
    "now names Ohio University")
})

test_that("the award postdates the Notice of Award", {
  expect_gt(oh_assert_after_noa(), 150L)
})

test_that("RCJ is RIGHT about Ohio, which is rare enough to pin", {
  d <- oh_disposition()
  expect_equal(sum(d$rcj_rows), 1L)
  expect_equal(d$disposition, "REAL_AWARD_CARRIED_CORRECTLY")
})

test_that("the status table has no amount column", {
  st <- oh_status_table()
  expect_false("amount" %in% names(st))
  expect_true(any(st$stage == "UNREADABLE"))
})


# -- session 63: the disposition after the 2026-09-24 pull -------------------

test_that("the OH disposition covers the live candidates and its prose agrees", {
  skip_if_not(file.exists(here::here("data", "interim",
                                     "stage2_record_table.rds")))
  rt <- rhtp_record_table_live()
  live <- sum(rt$state == "OH" & rt$award_tier == "SUBAWARD")
  d <- oh_disposition()
  expect_equal(sum(d$rcj_rows), live)
  expect_silent(rhtp_assert_disposition_prose(d, "OH"))
  committed <- readr::read_csv(OH_DISPO_CSV, show_col_types = FALSE)
  expect_equal(committed$rcj_rows, d$rcj_rows)
  expect_equal(committed[[ncol(committed)]], d[[ncol(d)]])
})


# -- session 104: ODH's child pages ------------------------------------------

test_that("session 104: 22 hospitals at $0, one $30.3M pool, OPA non-hospital", {
  expect_true(oh_assert_s104_sources())
  d <- oh_all_rows()
  expect_true(oh_assert_s104_rows(d))
  part <- rhtp_hospital_dollar_partition(d)
  expect_equal(part$rows[part$bucket == "NAMED_HOSPITAL"], 22L)
  expect_equal(part$dollars[part$bucket == "NAMED_HOSPITAL"], 0)
  expect_equal(part$dollars[part$bucket == "POOL_NAMED_HOSPITALS"], 30300000)
  pool <- d[d$hospital_attribution == "POOL_NAMED_HOSPITALS", ]
  expect_match(pool$determination_basis, OH_POOL_SENTENCE, fixed = TRUE)
  # The shared sub-pools never become rows.
  expect_false(any(d$amount %in% c(92e6, 31.4e6)))
  opa <- d[d$awardee == "Ohio Pharmacists Association", ]
  expect_equal(opa$amount, 2000000)
  expect_equal(opa$distributed_to_hospital, "No")
  # "Memorial Hospital" answers two enrolled entities: a hospital, no CCN.
  mh <- d[d$awardee == "Memorial Hospital", ]
  expect_true(is.na(mh$ccn))
  committed <- readr::read_csv(OH_CSV, show_col_types = FALSE)
  expect_equal(committed$awardee, d$awardee)
})

test_that("session 104: the probe reads the child pages and trips on a new name", {
  f <- lapply(c(hospitals = "hospitals", pharmacy = "pharmacy"), function(k)
    readBin(here::here(OH_S104_DIR, OH_S104_PAGES$file[OH_S104_PAGES$key == k]), "raw", 1e6))
  r <- oh_probe_s104(f)
  expect_false(any(r$cmp$changed))
  expect_length(r$findings, 0L)
  x <- rawToChar(f$hospitals)
  x <- sub("The funded projects haven\u2019t been announced yet.", "Riverbend Rural Hospital: $900,000.", x, fixed = TRUE)
  f$hospitals <- charToRaw(x)
  expect_error(oh_probe_s104(f), "Riverbend Rural Hospital")
})


# -- session 105: the owner ruling on the pool (CLAUDE.md §7) ----------------
# The shared-with-non-hospitals test applies to each SEPARATELY PRICED
# COMPONENT of an announcement, not to its headline. A component is a pool
# only when the source prices it for named hospitals alone.

test_that("session 105: the $30.3M pool rests on a component priced for the 22 hospitals alone", {
  d <- oh_all_rows()
  pool <- d[d$hospital_attribution %in% "POOL_NAMED_HOSPITALS", ]
  expect_equal(nrow(pool), 1L)
  expect_equal(pool$amount, OH_HOSP_POOL)
  expect_match(pool$award_pool, "22 rural hospitals", fixed = TRUE)
  expect_match(pool$determination_basis, "confirmed session 105", fixed = TRUE)
  # Every recipient the pool names is itself a hospital row.
  expect_equal(nrow(OH_22), 22L)
  expect_true(all(d$recipient_type[d$awardee %in% OH_22$awardee] == "HOSPITAL_OR_SYSTEM"))
  # The headline and the two shared components are in no bucket. The maternal
  # component is ALSO $30.3M, so it is excluded by its pool, not its amount.
  expect_false(any(d$amount %in% c(92e6, 31.4e6)))
  expect_false(any(grepl("Maternal|Clinically Integrated|Innovation Hub|\\$92", d$award_pool)))
  expect_false(any(d$hospital_attribution[grepl("Maternal|Hub", d$award_pool)] %in%
                     c("NAMED_HOSPITAL", "POOL_NAMED_HOSPITALS", "POOL_UNNAMED_HOSPITALS")))
})

test_that("session 105: a component the source shares with non-hospitals stops the build", {
  f <- here::here(OH_S104_DIR, OH_S104_PAGES$file[OH_S104_PAGES$key == "hospitals"])
  x <- rawToChar(readBin(f, "raw", file.size(f)))
  expect_true(oh_assert_s104_sources(charToRaw(x)))
  shared <- sub("one-time direct payments to 22 rural hospitals.",
                "one-time direct payments to 22 rural hospitals and health centers.", x, fixed = TRUE)
  expect_false(identical(shared, x))
  expect_error(oh_assert_s104_sources(charToRaw(shared)), "no longer says")
})

test_that("session 105: CLAUDE.md §7 carries the per-component pool rule", {
  md <- readLines(here::here("CLAUDE.md"), warn = FALSE)
  expect_true(any(grepl("^#### A pool is judged per priced component, never by its headline \\(session 105\\)", md)))
})
