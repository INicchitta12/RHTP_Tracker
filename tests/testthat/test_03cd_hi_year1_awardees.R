# test_03cd_hi_year1_awardees.R ------------------------------------------------
# Session 101. Hawaii: SHPDA's page names three RVBI Notices of Award and no
# amount; HANDS, where the amounts are, is 403 here.

suppressWarnings(suppressMessages(source(here::here("R", "03cd_hi_year1_awardees.R"))))

hi <- hi_year1_awardees()

test_that("three Notices of Award, no amount, and the page still says so", {
  expect_silent(hi_assert_sources())
  expect_equal(nrow(hi), 3L)
  expect_true(all(is.na(hi$amount)))
  expect_setequal(hi$awardee, names(HI_NOA_PHRASE))
  expect_true(all(grepl("HANDS", hi$amount_basis, fixed = TRUE)))
})

test_that("HAH is the association rule's pool at $0; PSW and HPCA are not hospitals", {
  hah <- hi[hi$awardee == "Healthcare Association of Hawaii", ]
  expect_equal(hah$flow_type, "PASS_THROUGH_DESIGNATED")
  expect_equal(hah$hospital_attribution, "POOL_UNNAMED_HOSPITALS")
  expect_equal(hah$intermediary_name, "Healthcare Association of Hawaii")
  expect_equal(hah$determination_confidence, "LOW")
  psw <- hi[hi$awardee == "Physicians of Southwest Washington, LLC", ]
  expect_equal(psw$recipient_type, "OTHER")
  expect_match(psw$recipient_type_source, "Determined form:")
  expect_equal(psw$distributed_to_hospital, "No")
  hp <- hi[hi$awardee == "Hawaii Primary Care Association", ]
  expect_equal(hp$distributed_to_hospital, "No")
  p <- rhtp_hospital_dollar_partition(hi)
  expect_equal(p$bucket, "POOL_UNNAMED_HOSPITALS")
  expect_equal(p$rows, 1L)
  expect_equal(p$dollars, 0)
})

test_that("the committed CSV matches a fresh build", {
  d <- readr::read_csv(HI_CSV, show_col_types = FALSE)
  expect_equal(d$awardee, hi$awardee)
  expect_equal(d$hospital_attribution, hi$hospital_attribution)
})

# -- the watch (session 102) ---------------------------------------------------

hi_arch_text <- function(k) {
  rhtp_watch_reduce(here::here(HI_PROBE_PAGES$file[HI_PROBE_PAGES$key == k]))
}

test_that("every probe baseline is archived, and each subject page is quiet against itself", {
  for (f in HI_PROBE_PAGES$file) expect_true(file.exists(here::here(f)), info = f)
  expect_identical(HI_PROBE_PAGES$file[HI_PROBE_PAGES$key == "shpda"], HI_PAGE)
  for (k in c("shpda", "rhtp_home", "rhtp_funding")) {
    t <- hi_arch_text(k)
    expect_length(hi_subject_findings(k, t, t), 0L)
  }
  expect_length(hi_noa_annotations(hi_arch_text("shpda")), 3L)
})

test_that("a NEW Notice of Award, a vanished one, and an amount outside HANDS each trip", {
  a <- hi_arch_text("shpda")
  new_noa <- sub("Link to Hawaii Awards",
                 paste("Rural Hospital EHR Upgrades (Notice of Award on 10/20 to",
                       "Kauai Veterans Memorial Hospital) Link to Hawaii Awards"),
                 a, fixed = TRUE)
  f <- hi_subject_findings("shpda", new_noa, a)
  expect_true(any(grepl("NEW Notice of Award", f)))
  expect_true(any(grepl("Kauai Veterans", f)))

  gone <- sub("(Notice of Award on 9/11 to Physicians of Southwest Washington, LLC)",
              "", a, fixed = TRUE)
  expect_true(any(grepl("GONE", hi_subject_findings("shpda", gone, a))))

  priced <- sub("(Notice of Award on 9/3 to Healthcare Association of Hawaii)",
                "(Notice of Award on 9/3 to Healthcare Association of Hawaii, $6,250,000)",
                a, fixed = TRUE)
  f <- hi_subject_findings("shpda", priced, a)
  expect_true(any(grepl("OUTSIDE HANDS", f)))
  expect_true(any(grepl("6,250,000", f, fixed = TRUE)))
})

test_that("an award sentence on rhtp.hawaii.gov trips; the Stevens footer does not", {
  a <- hi_arch_text("rhtp_funding")
  expect_match(a, "$188,892,439.75", fixed = TRUE)
  live <- paste(a, "The State has awarded funds to the following organizations.",
                "Award recipients are listed below.")
  f <- hi_subject_findings("rhtp_funding", live, a)
  expect_true(any(grepl("NEW award sentence", f)))
})

test_that("the newsroom diffs fire on a NEW RHTP headline only", {
  for (k in c("gov_news", "doh_news")) {
    f <- here::here(HI_PROBE_PAGES$file[HI_PROBE_PAGES$key == k])
    raw <- paste(readLines(f, warn = FALSE), collapse = "\n")
    expect_gt(length(hi_news_headlines(raw)), 2L)
    expect_length(hi_new_rhtp_headlines(raw, f), 0L)
    href <- if (k == "gov_news") "https://governor.hawaii.gov/newsroom/x/" else
      "https://health.hawaii.gov/news/newsroom/x/"
    add <- function(title) sub("</body>", paste0("<a href='", href, "'>", title,
                                                 "</a></body>"), raw, fixed = TRUE)
    expect_length(hi_new_rhtp_headlines(
      add("DLNR News Release – Trail closure on Kauai for maintenance"), f), 0L)
    expect_length(hi_new_rhtp_headlines(
      add("Governor Green announces Rural Health Transformation awards to hospitals"), f), 1L)
  }
})

test_that("the name tripwire runs on the subject pages and fires on a new organisation", {
  pages <- HI_PROBE_PAGES[HI_PROBE_PAGES$name_diff, ]
  expect_setequal(pages$key, c("shpda", "rhtp_home", "rhtp_funding"))
  a <- hi_arch_text("rhtp_home")
  live <- paste(a, "Funding has been provided to Molokai General Hospital and",
                "Hana Health Clinic Incorporated.")
  expect_error(rhtp_assert_no_new_organisations_across(
    live = list(rhtp_home = live), archived = list(rhtp_home = a), state = "HI"))
})
