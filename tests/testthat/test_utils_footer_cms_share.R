# test_utils_footer_cms_share.R ----------------------------------------------
# §0.2's CMS-share parser, added session 44 for Mississippi.
#
# THE ONE THING THAT MUST NOT HAPPEN IS A SILENT ACCEPTANCE. A footer whose
# headline is the allotment PLUS a non-federal match does not collide with the
# §7.1 anchor, so the tier check accepts it as a Tier 2 pool -- and that is
# wrong in the direction that inflates a pool figure to the size of a state.
# These tests drive that case, and they also drive the case that matters just
# as much: the parser must be INERT on the 100%-federal form, which is every
# other footer in this repository.

library(testthat)

source(here::here("R", "utils_config.R"))

MS_FOOTER_TEXT <- paste(
  "This project is supported by the Centers for Medicare & Medicaid Services",
  "(CMS) of the U.S. Department of Health and Human Services (HHS) as part of",
  "a financial assistance award totaling $205,990,180.16, with 99.96% funded",
  "by CMS/HHS ($205,907,220.16) and 0.04% funded by non-government sources",
  "($82,960). The contents are those of the author(s).")

HUNDRED_PCT <- paste(
  "This program is supported by the Centers for Medicare & Medicaid Services",
  "(CMS) as part of a financial assistance award totaling $190,008,051.09",
  "with 100 percent funded by CMS/HHS.")


# -- Mississippi, the case the parser exists for -----------------------------

test_that("the CMS share is parsed out of a partial-federal footer", {
  f <- rhtp_footer_parse(MS_FOOTER_TEXT)
  expect_equal(nrow(f), 1L)
  expect_equal(f$headline_amount, 205990180.16)
  expect_equal(f$cms_pct, 99.96)
  expect_equal(f$cms_amount, 205907220.16)
  expect_equal(f$nonfederal_amount, 82960)
  expect_false(f$fully_federal)
  # THE FIGURE TO TIER-CHECK IS THE CMS SHARE, NEVER THE HEADLINE.
  expect_equal(f$tier_amount, 205907220.16)
})

test_that("the footer's own three numbers close on each other", {
  f <- rhtp_footer_parse(MS_FOOTER_TEXT)
  # headline - CMS share == the printed match, TO THE CENT. This is what makes
  # the CMS share a stated figure rather than a reading of ours.
  expect_equal(f$headline_amount - f$cms_amount, f$nonfederal_amount)
})

test_that("the headline is REFUSED as the allotment and ACCEPTED as a pool", {
  a <- tibble::tibble(state = "MS", fy2026_allotment = 205907220)
  # Refused -- correctly, it is not the allotment.
  expect_error(
    rhtp_assert_footer_not_allotment(205990180.16, "MS", "STATE_ALLOTMENT",
                                     allotments = a),
    "declared STATE_ALLOTMENT")
  # ACCEPTED as a pool, WHICH IS WRONG, and that is the defect being pinned:
  # $82,960 is eight times the margin, so nothing in the arithmetic catches it.
  expect_true(rhtp_assert_footer_not_allotment(205990180.16, "MS",
                                               "SOLICITATION", allotments = a))
})

test_that("the CMS share tiers correctly in both directions", {
  a <- tibble::tibble(state = "MS", fy2026_allotment = 205907220)
  expect_true(rhtp_assert_footer_not_allotment(205907220.16, "MS",
                                               "STATE_ALLOTMENT",
                                               allotments = a))
  expect_error(
    rhtp_assert_footer_not_allotment(205907220.16, "MS", "SOLICITATION",
                                     allotments = a),
    "almost certainly Tier 1")
})

test_that("the text wrapper reads the share, so a caller cannot pick wrong", {
  a <- tibble::tibble(state = "MS", fy2026_allotment = 205907220)
  expect_true(rhtp_assert_footer_text_tier(MS_FOOTER_TEXT, "MS",
                                           "STATE_ALLOTMENT", allotments = a))
  expect_error(
    rhtp_assert_footer_text_tier(MS_FOOTER_TEXT, "MS", "SOLICITATION",
                                 allotments = a),
    "almost certainly Tier 1")
})

test_that("the margin is NOT widened to swallow the match", {
  # If a future session widens RHTP_FOOTER_ALLOTMENT_MARGIN to make
  # Mississippi's headline pass, this fails. $82,960 is ONE STATE'S match
  # amount; the next state's will differ, so widening buys nothing.
  expect_equal(RHTP_FOOTER_ALLOTMENT_MARGIN, 10000)
  expect_gt(205990180.16 - 205907220, 8 * RHTP_FOOTER_ALLOTMENT_MARGIN)
})


# -- inertness on the 100% form, which is every other footer here ------------

test_that("a 100%-federal footer returns its headline unchanged", {
  f <- rhtp_footer_parse(HUNDRED_PCT)
  expect_equal(nrow(f), 1L)
  expect_true(f$fully_federal)
  expect_equal(f$cms_pct, 100)
  expect_true(is.na(f$cms_amount))
  expect_equal(f$tier_amount, f$headline_amount)
  expect_equal(f$tier_amount, 190008051.09)
})

test_that("every phrasing in the committed corpus still parses", {
  # The eighteen shapes measured across data/evidence and data/raw before the
  # parser was written. All are 100 percent, so tier_amount is the headline on
  # every one; a phrasing that stops parsing would silently return zero rows.
  shapes <- c(
    "award totaling $1,000.00 with 100 percent funded by CMS/HHS",
    "award totaling $1,000.00 with 100% funded by CMS HHS",
    "award totaling $1,000.00, with 100% funded by CMS/HHS",
    "award totaling $1,000.00 with 100 percent funded by CMS/US HHS",
    "award totaling $1,000.00, with 100% funding provided by CMS/HHS",
    "award totaling $1,000.00, with 100 percent of funding provided by CMS/HHS",
    "award totaling approximately $1,000.00 with 100 percent funded by CMS/HHS",
    "award totaling $1,000.00 with 100% of the award funded by CMS/HHS",
    "award totaling $1,000.00 with 100 percent funding by CMS/HHS",
    "award totaling $1,000.00 with 100 percent of funding by CMS/HHS",
    "award totaling $1,000.00 (100% federally funded) by CMS",
    paste("award totaling $1,000.00 with 100 percent funded by CMS/HHS,",
          "pending approval of revised budget"))
  for (s in shapes) {
    f <- rhtp_footer_parse(s)
    expect_equal(nrow(f), 1L, info = s)
    expect_equal(f$tier_amount, 1000, info = s)
    expect_true(f$fully_federal, info = s)
  }
})

test_that("no footer at all is zero rows, not an error", {
  expect_equal(nrow(rhtp_footer_parse("a page with no footer on it")), 0L)
  expect_equal(nrow(rhtp_footer_parse(character(0))), 0L)
  expect_error(rhtp_footer_cms_share("nothing here"), "no CMS financial")
})


# -- the refusal to compute --------------------------------------------------

test_that("a partial share with NO dollar figure returns NA, never a product", {
  # §0.4: headline x percentage is a number no publisher printed, and a
  # percentage rounded to two places cannot reproduce a cent-exact allotment.
  txt <- paste("award totaling $205,990,180.16 with 99.96 percent funded by",
               "CMS/HHS and the remainder by other sources.")
  f <- rhtp_footer_parse(txt)
  expect_equal(nrow(f), 1L)
  expect_false(f$fully_federal)
  expect_true(is.na(f$cms_amount))
  expect_true(is.na(f$tier_amount))
  expect_true(is.na(suppressMessages(rhtp_footer_cms_share(txt))))
  # And the tier check does not run -- NA, not TRUE (§0.4).
  a <- tibble::tibble(state = "MS", fy2026_allotment = 205907220)
  expect_true(is.na(suppressMessages(
    rhtp_assert_footer_text_tier(txt, "MS", "STATE_ALLOTMENT",
                                 allotments = a))))
})


# -- two footers on one page (New Hampshire's shape) -------------------------

test_that("two footers on one page are parsed separately", {
  two <- paste(
    "This program is supported by CMS as part of a financial assistance award",
    "totaling $204,016,550.20 with 100 percent funded by CMS/HHS.",
    "This project is supported by CMS as part of a financial assistance award",
    "totaling $66,547,394.00 with 100 percent funded by CMS/HHS.")
  f <- rhtp_footer_parse(two)
  expect_equal(nrow(f), 2L)
  expect_equal(f$tier_amount, c(204016550.20, 66547394.00))
  expect_equal(rhtp_footer_cms_share(two, which = 2L), 66547394.00)
  expect_error(rhtp_footer_cms_share(two, which = 3L), "carries 2")
})


# -- session 59: Washington's SUBAWARD_OF form -------------------------------

WA_SUBAWARD_FOOTER <- paste(
  "Disclaimer: This program is supported by CMS/HHS through a subaward as part",
  "of a financial assistance award of $181,257,515.06 to the Washington State",
  "Health Care Authority with $3,500,000 and 80 percent funded by CMS/HHS and",
  "$914,538 and 20 percent funded by other source(s). The contents are those of",
  "the author(s).")

test_that("Washington's subaward footer parses, where it returned zero rows", {
  f <- rhtp_footer_parse(WA_SUBAWARD_FOOTER)
  expect_equal(nrow(f), 1L)
  expect_equal(f$form, "SUBAWARD_OF")
  expect_true(f$subaward)
  # The HEADLINE is the award to the state -- Washington's allotment.
  expect_equal(f$headline_amount, 181257515.06)
  expect_equal(f$tier_amount, 181257515.06)
  # The percentages describe the SUBAWARD, so they are NOT in cms_*.
  expect_true(is.na(f$cms_pct))
  expect_true(is.na(f$cms_amount))
  expect_true(is.na(f$fully_federal))
  expect_equal(f$subaward_cms_amount, 3500000)
  expect_equal(f$subaward_cms_pct, 80)
  expect_equal(f$subaward_nonfederal_amount, 914538)
})

test_that("its headline tier-checks as the allotment, and never as a pool", {
  a <- tibble::tibble(state = "WA", fy2026_allotment = 181257515)
  expect_true(rhtp_assert_footer_text_tier(WA_SUBAWARD_FOOTER, "WA",
                                           "STATE_ALLOTMENT", allotments = a))
  expect_error(rhtp_assert_footer_text_tier(WA_SUBAWARD_FOOTER, "WA",
                                            "SOLICITATION", allotments = a),
               "almost certainly Tier 1")
})

test_that("both footers on Washington's archived programme page parse, in order", {
  f <- rhtp_footer_parse(paste(readLines(here::here(
    "data/evidence/recheck/2026-09-23/WA/hca_rhtp_programme.html"),
    warn = FALSE), collapse = " "))
  expect_equal(f$form, c("SUBAWARD_OF", "TOTALING"))
  expect_equal(f$headline_amount, c(181257515.06, 181257515.06))
})

test_that("the TOTALING form now reports whether it is a subaward, and nothing else moved", {
  wi <- paste("supported by CMS through a subaward as part of a financial",
              "assistance award made to the State of Wisconsin Department of",
              "Health Services totaling $203,670,005.21 with 100 percent funded",
              "by CMS/HHS.")
  f <- rhtp_footer_parse(wi)
  expect_equal(f$form, "TOTALING")
  expect_true(f$subaward)
  expect_equal(f$tier_amount, 203670005.21)
  expect_false(rhtp_footer_parse(HUNDRED_PCT)$subaward)
  expect_equal(rhtp_footer_parse(MS_FOOTER_TEXT)$tier_amount, 205907220.16)
})

test_that("the subaward pattern does not reach a stray 'award of $'", {
  expect_equal(nrow(rhtp_footer_parse(
    "The foundation received an award of $50,000 to the county with thanks.")), 0L)
})
