# test_utils_footer_tier.R ----------------------------------------------------
# The §0.2 tier-indistinguishability rule. Reads committed files off disk only
# -- no network, no quota.
#
# THE FINDING THIS PINS. A CMS financial-assistance footer states an amount in
# a fixed sentence, and that sentence is IDENTICAL whether the amount is the
# RFP's pool (Tier 2) or the State's whole allotment (Tier 1). Iowa carries
# both, eight and three, in the same template. Session 27's audit sorted
# footers by grammatical SUBJECT and that answers PROVENANCE; it does not
# answer TIER, and nothing in the grammar does. The only signal available is
# collision with the §7.1 anchor -- a coincidence of value, not a statement by
# the publisher -- so it is checked by machine on every figure, in BOTH
# directions.

library(testthat)

source(here::here("R", "utils_config.R"))

IA_FOOTERS <- here::here("data", "reference", "ia_notice_footers.csv")
ANCHOR <- here::here("data", "reference", "cms_fy2026_allotments.csv")

skip_without_anchor <- function() {
  if (!file.exists(ANCHOR)) skip("the 7.1 allotment anchor is not on disk")
}


# -- the two grammars are one grammar ----------------------------------------

test_that("Iowa's Tier 1 and Tier 2 footers are the SAME sentence", {
  skip_without_anchor()
  skip_if_not(file.exists(IA_FOOTERS), "ia_notice_footers.csv is not on disk")
  f <- readr::read_csv(IA_FOOTERS, show_col_types = FALSE, progress = FALSE)

  # Both tiers are present, which is the whole premise.
  expect_setequal(unique(f$footer_tier), c("SOLICITATION", "STATE_ALLOTMENT"))
  expect_equal(sum(f$footer_tier == "STATE_ALLOTMENT"), 3L)
  expect_equal(sum(f$footer_tier == "SOLICITATION"), 8L)

  # And EVERY row is the strong, programme-scoped form -- so the session 27
  # axis cannot separate them. If this ever stops being true the finding has
  # changed and this file must be rewritten, not relaxed.
  expect_true(all(f$footer_subject_is_programme_scoped == "Yes"))
})


# -- the refusal, both directions --------------------------------------------

test_that("a footer figure that IS the allotment is refused as a pool", {
  skip_without_anchor()
  expect_error(
    rhtp_assert_footer_not_allotment(209040063.71, "IA", "SOLICITATION",
                                     label = "PHTHOCC26756"),
    "almost certainly Tier 1"
  )
  # The error has to name the document and both figures, or a reader cannot
  # act on it.
  err <- tryCatch(
    rhtp_assert_footer_not_allotment(209040063.71, "IA", "SOLICITATION",
                                     label = "PHTHOCC26756"),
    error = function(e) conditionMessage(e))
  expect_match(err, "PHTHOCC26756", fixed = TRUE)
  expect_match(err, "$209,040,063.71", fixed = TRUE)
  expect_match(err, "do NOT widen the margin", fixed = TRUE)
})

test_that("a Tier 1 declaration that stops colliding is ALSO refused", {
  # The half that is easy to leave out. A declared allotment rests entirely on
  # the collision, so losing it is a finding, not a pass.
  skip_without_anchor()
  expect_error(
    rhtp_assert_footer_not_allotment(50000000, "IA", "STATE_ALLOTMENT",
                                     label = "PHTHORC26008"),
    "no longer holds"
  )
})

test_that("a genuine pool figure passes, and so does a genuine allotment", {
  skip_without_anchor()
  expect_true(rhtp_assert_footer_not_allotment(50000000, "IA", "SOLICITATION"))
  expect_true(rhtp_assert_footer_not_allotment(66002161.80, "IA",
                                               "SOLICITATION"))
  expect_true(rhtp_assert_footer_not_allotment(209040063.71, "IA",
                                               "STATE_ALLOTMENT"))
})


# -- the margin is the measured width of publisher rounding -------------------

test_that("the margin covers the rounding this project has actually seen", {
  skip_without_anchor()
  a <- rhtp_footer_allotments()
  ia <- a$fy2026_allotment[a$state == "IA"]
  nh <- a$fy2026_allotment[a$state == "NH"]
  ks <- a$fy2026_allotment[a$state == "KS"]

  # Iowa restates to the dollar; New Hampshire to the cent; Kansas transposes
  # two digits and is still unmistakably the allotment ($8,000.18 out).
  expect_lte(abs(209040063.71 - ia), RHTP_FOOTER_ALLOTMENT_MARGIN)
  expect_lte(abs(204016550.20 - nh), RHTP_FOOTER_ALLOTMENT_MARGIN)
  expect_lte(abs(221890007.82 - ks), RHTP_FOOTER_ALLOTMENT_MARGIN)
  # The $8,000.18 is the gap against the ANCHOR's rounded integer
  # ($221,898,008), not against KDHE's other two publications, which print
  # $221,898,007.82 and are $8,000.00 from the deck. Both gaps are real and
  # they are different figures; this is the one the margin has to cover.
  expect_equal(round(abs(221890007.82 - ks), 2), 8000.18)
  expect_equal(round(abs(221890007.82 - 221898007.82), 2), 8000.00)

  # And it is far below the smallest genuine Tier 2 footer in the repository,
  # so it cannot swallow a real pool.
  f <- readr::read_csv(IA_FOOTERS, show_col_types = FALSE, progress = FALSE)
  smallest_pool <- min(f$footer_amount[f$footer_tier == "SOLICITATION"])
  expect_equal(smallest_pool, 6000000)
  expect_gt(smallest_pool, RHTP_FOOTER_ALLOTMENT_MARGIN * 100)
})


# -- the committed tables agree with the rule --------------------------------

test_that("Iowa's committed footer table passes the shared rule", {
  skip_without_anchor()
  skip_if_not(file.exists(IA_FOOTERS), "ia_notice_footers.csv is not on disk")
  f <- readr::read_csv(IA_FOOTERS, show_col_types = FALSE, progress = FALSE)
  expect_true(rhtp_assert_footer_tiers(f, state = "IA"))
})

test_that("New Hampshire's two hand-coded footers agree with the rule", {
  # §0.2 in one document, the second time after Virginia: FHC's page carries
  # the STATE's allotment and FHC's OWN award in the same boilerplate. The
  # coding was done by hand in session 29; this checks the machine agrees.
  skip_without_anchor()
  nh <- tibble::tibble(
    rfp = c("FHC footer - state allotment", "FHC footer - FHC's own award"),
    footer_amount = c(204016550.20, 66547394),
    footer_tier = c("STATE_ALLOTMENT", "SOLICITATION"))
  expect_true(rhtp_assert_footer_tiers(nh, state = "NH"))

  # And swapping the two declarations must fail, in both directions at once.
  expect_error(rhtp_assert_footer_tiers(
    dplyr::mutate(nh, footer_tier = rev(.data$footer_tier)), state = "NH"))
})


# -- refusing to guess -------------------------------------------------------

test_that("a state with no anchor row returns NA, never TRUE", {
  # 0.4: the check has not passed, it has not RUN. A caller wanting a hard
  # gate tests for TRUE.
  empty <- tibble::tibble(state = character(), fy2026_allotment = numeric())
  expect_message(
    got <- rhtp_assert_footer_not_allotment(1e6, "ZZ", "SOLICITATION",
                                            allotments = empty),
    "could NOT be checked")
  expect_true(is.na(got))
  expect_false(isTRUE(got))
})

test_that("the assertion refuses a tier code outside the two it handles", {
  skip_without_anchor()
  expect_error(
    rhtp_assert_footer_not_allotment(1e6, "IA", "SUBAWARD"), "arg")
  expect_error(
    rhtp_assert_footer_not_allotment(c(1e6, 2e6), "IA", "SOLICITATION"),
    "one numeric")
  expect_error(
    rhtp_assert_footer_not_allotment(NA_real_, "IA", "SOLICITATION"),
    "one numeric")
})

test_that("the table form refuses a frame without the two columns", {
  expect_error(rhtp_assert_footer_tiers(tibble::tibble(x = 1)),
               "footer_amount and footer_tier")
})

test_that("a table with no state at all is refused, not silently skipped", {
  expect_error(
    rhtp_assert_footer_tiers(
      tibble::tibble(footer_amount = 1e6, footer_tier = "SOLICITATION")),
    "needs either a `state` column")
})

test_that("the table form returns FALSE when a row could not be checked", {
  # Refusals throw, so FALSE means only "not checked" (§0.4) -- never "passed".
  empty <- tibble::tibble(state = character(), fy2026_allotment = numeric())
  f <- tibble::tibble(rfp = "x", footer_amount = 1e6,
                      footer_tier = "SOLICITATION")
  expect_message(got <- rhtp_assert_footer_tiers(f, state = "ZZ",
                                                 allotments = empty),
                 "could NOT be checked")
  expect_false(got)
})
