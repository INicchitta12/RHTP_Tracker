# test_utils_footer_rule.R -----------------------------------------------------
# SESSION 121, OWNER RULING (§0.2): a state page footer is a CHECK, never a
# source. Its printed dollar figures are compared against the state's FY2026
# allotment, its FY2027 award and their sum; the verdict is taken on the CMS
# share. A CMS share matching none is REFUSED (re-read the document, never
# widen the margin), and a federal amount is never derived by multiplying a
# printed percentage by a headline.

suppressPackageStartupMessages(library(testthat))
source(here::here("R", "utils_config.R"))

no_read <- tibble::tibble(state = character(), printed_cms_share = numeric(), reading = character())
foot <- function(headline, pct = "100 percent", cms = NULL, non = NULL) {
  paste0("This project is supported by the Centers for Medicare & Medicaid Services (CMS) of the U.S. ",
         "Department of Health and Human Services (HHS) as part of a financial assistance award totaling ",
         headline, ", with ", pct, " funded by CMS/HHS",
         if (!is.null(cms)) paste0(" (", cms, ")") else "",
         if (!is.null(non)) paste0(" and 0.04% funded by non-government sources (", non, ")") else "", ".")
}

# The live Mississippi sentence, 2026-11-20 (mississippirhtp.com/funding/).
MS_FIXTURE <- paste(
  "Department of Health and Human Services (HHS) as part of a financial assistance award totaling",
  "$410,584,410.13, with 99.96% funded by CMS/HHS ($410,420,176.37) and 0.04% funded by",
  "non-government sources ($164,233.76).")

test_that("Mississippi: the headline is FY2026 + FY2027, the printed CMS share matches none -> REFUSED", {
  f <- rhtp_footer_check(MS_FIXTURE, "MS", refusals = no_read)
  expect_equal(nrow(f), 1L)
  expect_equal(f$headline_anchor, "ALLOTMENT_PLUS_FY2027")
  expect_true(is.na(f$cms_share_anchor))
  expect_equal(f$cms_share, 410420176.37)
  expect_equal(f$verdict, "REFUSED")
  expect_match(f$refusal_reason, "MATCHES_NONE")
  expect_error(rhtp_footer_check(MS_FIXTURE, "MS", refusals = no_read) %>%
                 {if (any(.$verdict == "REFUSED")) stop("refused") else .}, "refused")
})

test_that("the recorded reading quiets Mississippi's refusal without making it a source", {
  f <- rhtp_footer_check(MS_FIXTURE, "MS")
  expect_equal(f$verdict, "REFUSED_READ")
  expect_silent(rhtp_assert_footer_check(MS_FIXTURE, "MS"))
  r <- rhtp_footer_refusals_read()
  expect_true(all(c("MS", "CA", "LA", "MN") %in% r$state))
})

test_that("an unread refusal stops, and the message forbids widening and multiplying", {
  bad <- foot("$410,584,410.13", "99.95%", "$410,380,000.00", "$204,410.13")   # not the recorded reading
  expect_error(rhtp_assert_footer_check(bad, "MS", label = "fixture"),
               "re-read the document.*Never widen the margin; never multiply a percentage",
               fixed = FALSE)
})

test_that("a partial share with no printed CMS dollar figure is refused, never computed", {
  f <- rhtp_footer_check(foot("$410,584,410.13", "99.96%"), "MS", refusals = no_read)
  expect_true(is.na(f$cms_share))
  expect_equal(f$verdict, "REFUSED")
  expect_match(f$refusal_reason, "NO_PRINTED_CMS_FIGURE")
  # 410,584,410.13 x 99.96% is not a figure anybody printed, and it is nowhere in the result
  expect_false(any(abs(unlist(f[sapply(f, is.numeric)]) - 410584410.13 * 0.9996) < 1, na.rm = TRUE))
})

test_that("the three anchors: FY2026, FY2027, and their sum (100% federal footers)", {
  a26 <- 205907220; a27 <- 204677190
  expect_equal(rhtp_footer_check(foot("$205,907,220.16"), "MS", refusals = no_read)$verdict, "ALLOTMENT")
  expect_equal(rhtp_footer_check(foot("$204,677,190.00"), "MS", refusals = no_read)$verdict, "FY2027_AWARD")
  expect_equal(rhtp_footer_check(foot("$410,584,410.13"), "MS", refusals = no_read)$verdict, "ALLOTMENT_PLUS_FY2027")
  expect_equal(rhtp_footer_check(foot("$473,250,028.01"), "MT", refusals = no_read)$verdict, "ALLOTMENT_PLUS_FY2027")
  # the $100M initial-award footers match none of the three
  expect_equal(rhtp_footer_check(foot("$333,639,308.46"), "CA", refusals = no_read)$verdict, "REFUSED")
  expect_equal(rhtp_footer_check(foot("$333,639,308.46"), "CA")$verdict, "REFUSED_READ")
  # the margin is not widened: $82,960 off the sum is refused
  expect_equal(rhtp_footer_check(foot("$410,667,370.13"), "MS", refusals = no_read)$verdict, "REFUSED")
  expect_equal(RHTP_FOOTER_ALLOTMENT_MARGIN, 10000)
})

test_that("the shared new-sentence watch treats an anchored footer as a check, not an award sentence", {
  source(here::here("R", "utils_page_watch.R"))
  arch <- "Program page. Montana has awarded its EMS grants."
  mt_footer <- paste("Department of Health and Human Services (HHS) as part of a financial assistance award",
                     "totaling $473,250,028.01 with 100 percent funded by CMS/HHS.")
  expect_true(rhtp_watch_forbid_new(paste(arch, mt_footer), arch, "\\baward", "MT", "home", "why"))
  # a footer matching no anchor still stops, as the rule requires
  bad <- sub("$473,250,028.01", "$12,345,678.00", mt_footer, fixed = TRUE)
  expect_error(rhtp_watch_forbid_new(paste(arch, bad), arch, "\\baward", "MT", "home", "why"), "footer REFUSED")
  # and a real award sentence still trips
  expect_error(rhtp_watch_forbid_new(paste(arch, "The state awarded $2 million to Glendive Medical Center."),
                                     arch, "\\baward", "MT", "home", "why"), "NEW SENTENCE")
})
