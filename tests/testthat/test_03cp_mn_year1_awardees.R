# Minnesota -- MDH's "RHTP Sub-Recipient Awardees" (nine PDFs dated
# 09/17/2026, linked from the RHTP grants page, Last Updated 10/27/2026),
# extracted session 112 as AWARDS (R/03cp), and R/03bn's watch re-based on it.

source(here::here("R", "03cp_mn_year1_awardees.R"))
source(here::here("R", "03bn_mn_year1_probe.R"))

a <- mn_year1_awardees()
committed <- readr::read_csv(here::here(MNA_OUT), show_col_types = FALSE,
                             col_types = readr::cols(ccn = "c", .default = readr::col_guess()))

test_that("the archive is the manifest's bytes and the page links exactly the nine PDFs", {
  expect_silent(mna_assert_archive())
  expect_true(grepl(MNA_AWARDED_SENTENCE, mna_page_text(), fixed = TRUE))
})

test_that("every amount in every PDF matches the file to the cent", {
  expect_silent(mna_assert_pdfs())
  expect_equal(nrow(a), 11L)
  expect_equal(length(unique(a$awardee)), 10L)
  expect_equal(round(sum(a$amount), 2), 12453451.00)
  # One line per PDF is $3,070,335 -- MMA's $165,007 and OEMS's $9,218,109
  # grant-funds line are the difference to MDH's "$12.5 million".
  first <- MN_AWARDS[!duplicated(MN_AWARDS$key), ]
  expect_equal(round(sum(first$amount), 2), 3070335.00)
  expect_equal(round(sum(a$amount) - sum(first$amount), 2), 165007 + 9218109)
  expect_equal(sum(a$amount[a$awardee == "Minnesota Office of EMS"]), 281000 + 9218109)
})

test_that("a mis-keyed amount is refused, not passed", {
  bad <- MN_AWARDS
  bad$amount[bad$awardee == "Stratis Health"] <- 883372
  MN_AWARDS_SAVED <- MN_AWARDS
  assign("MN_AWARDS", bad, envir = globalenv())
  on.exit(assign("MN_AWARDS", MN_AWARDS_SAVED, envir = globalenv()))
  expect_error(mna_assert_pdfs(), "stratis.pdf prints")
})

test_that("the CMS footer is the allotment (Tier 1), never a pool or a row", {
  expect_silent(rhtp_assert_footer_not_allotment(193090618.14, "MN", "STATE_ALLOTMENT"))
  expect_error(rhtp_assert_footer_not_allotment(193090618.14, "MN", "SOLICITATION"))
  expect_false(any(abs(a$amount - 193090618.14) < 1))
})

test_that("every row is an AWARD on MDH's own roster", {
  expect_true(all(a$validation_source_type == "NOTICE_OF_AWARD"))
  expect_true(all(a$amount_confirmed == "Yes"))
  expect_true(all(a$recipient_confirmed == "Yes"))
  expect_true(all(a$announcement_date == as.Date("2026-09-17")))
  expect_true(all(file.exists(here::here(a$source_archive_path))))
})

test_that("no row is a hospital row; the two employer pass-throughs are Unclear (§0.3)", {
  expect_silent(mna_assert_typing(a))
  expect_true(all(a$hospital_attribution == "NOT_HOSPITAL"))
  expect_false(any(a$distributed_to_hospital == "Yes"))
  un <- a[a$distributed_to_hospital == "Unclear", ]
  expect_setequal(un$awardee, c("Minnesota Community Health Worker Alliance", "HealthForce MN"))
  expect_true(all(un$flow_type == "PASS_THROUGH_UNRESOLVED"))
  expect_true(all(nzchar(un$determination_basis)))
  st <- a$awardee[a$recipient_type == "STATE_AGENCY"]
  expect_setequal(unique(st), c("Minnesota Office of EMS", "Minnesota Management and Budget"))
  expect_false(any(a$determination_confidence == "HIGH"))
  expect_true(all(a$determination_confidence[grepl("RECIPIENT_TYPE_INFERRED", dplyr::coalesce(a$flag_reason, ""))] == "LOW"))
})

test_that("the committed file is the build", {
  expect_equal(nrow(committed), nrow(a))
  expect_equal(committed$awardee, a$awardee)
  expect_equal(round(committed$amount, 2), round(a$amount, 2))
  expect_equal(committed$recipient_type, a$recipient_type)
  expect_equal(committed$distributed_to_hospital, a$distributed_to_hospital)
  expect_equal(names(committed), names(a))
})

# -- R/03bn: the watch, re-based on the 2026-11-02 archive -------------------------

mn_arch <- lapply(stats::setNames(MN_PAGES$file, MN_PAGES$key),
                  function(f) rhtp_watch_reduce(here::here(f)))

test_that("the re-based watch passes on its own archive", {
  expect_equal(MN_PAGES$file[MN_PAGES$key == "grants"],
               file.path("data", "evidence", "MN", "2026-11-02_mdh_rhtp_grants.html"))
  expect_silent(suppressMessages(mn_validate()))
})

test_that("the watch trips when the direct-allocation announcement lands", {
  live <- mn_arch
  live$grants <- sub(MN_PENDING_SENTENCE, "were announced on November 9", live$grants, fixed = TRUE)
  expect_error(mn_assert_watch(live, mn_arch), "coming days")
})

test_that("the watch trips on a tenth awardee PDF", {
  live <- mn_arch
  live$grants <- sub("RHTP Evaluation (PDF)",
                     "RHTP Evaluation (PDF) Rural Hospital Direct Allocation Awardees (PDF)",
                     live$grants, fixed = TRUE)
  expect_error(mn_assert_watch(live, mn_arch), "nine RHTP Sub-Recipient")
})

test_that("the watch still trips on a NEW award sentence (the phrase diff is intact)", {
  live <- mn_arch
  live$grants <- paste(live$grants,
                       "MDH has selected 94 hospitals as grantees of the direct allocation.")
  expect_error(mn_assert_watch(live, mn_arch))
})
