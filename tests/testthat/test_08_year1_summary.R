# test_08_year1_summary.R -- the Year 1 summary table (session 110 dry run)
#
# The totals are PINNED to the 2026-10-28 data. The Monday 2026-11-02 session
# re-runs R/08 after its sweep and re-pins them here in the same commit.

source(here::here("R", "08_year1_summary.R"))

rows <- ys_rows()
s <- ys_build(rows)
us <- s[s$state == "US", ]

test_that("one row per state plus a national row, and the national row is the column sum", {
  expect_equal(nrow(s), 51L)
  expect_setequal(s$state[s$state != "US"], readr::read_csv(here::here(YS_ALLOT), show_col_types = FALSE)$state)
  st <- s[s$state != "US", ]
  for (col in c("allotment_usd", "award_total_usd", "hospital_coded_usd", "hospital_best_judgment_usd",
                "hospital_summary_usd", "strict_named_hospital_usd", "strict_pool_named_hospitals_usd",
                "strict_pool_unnamed_hospitals_usd", "layer_source_suspect_usd")) {
    expect_equal(us[[col]], sum(st[[col]]), info = col)
  }
})

test_that("the dry-run totals (2026-10-28) are pinned", {
  expect_equal(us$allotment_usd, 1e10)
  expect_equal(round(us$published_priced_usd, 2), 3708434674.31, tolerance = 1e-12)
  expect_equal(round(us$award_total_usd, 2), 4171467402.31, tolerance = 1e-12)
  expect_equal(round(us$hospital_coded_usd, 2), 1778001785.52, tolerance = 1e-12)
  expect_equal(round(us$hospital_best_judgment_usd, 2), 324560024.25, tolerance = 1e-12)
  expect_equal(round(us$hospital_bj_pool_usd, 2), 83835000)
  expect_equal(round(us$hospital_summary_usd, 2), 2102561809.77, tolerance = 1e-12)
  expect_equal(round(us$strict_named_hospital_usd, 2), 1729244537.70, tolerance = 1e-12)
  expect_equal(round(us$strict_pool_named_hospitals_usd, 2), 86555171.43)
  expect_equal(round(us$strict_pool_unnamed_hospitals_usd, 2), 69323109.17)
  expect_equal(us$best_judgment_rows, 536L)
  expect_equal(us$hospital_share_of_awards_pct, 50.4)
  expect_equal(us$hospital_share_of_allotment_pct, 21.0)
})

test_that("the summary figure reconciles to the strict partition, dollar for dollar", {
  pools <- readr::read_csv(here::here(YS_POOLS), show_col_types = FALSE)
  r <- rows %>% dplyr::mutate(suspect = ys_has(flag_reason, "SOURCE_SUSPECT"),
                              amt = dplyr::coalesce(amount, 0))
  ok <- r[!r$suspect, ]
  bj_up   <- sum(ok$amt[ok$basis == "BEST_JUDGMENT" & ok$call == "HOSPITAL" & ok$distributed_to_hospital != "Yes"])
  bj_down <- sum(ok$amt[ok$basis == "BEST_JUDGMENT" & ok$call == "NOT_HOSPITAL" & ok$distributed_to_hospital == "Yes"])
  strict3 <- us$strict_named_hospital_usd + us$strict_pool_named_hospitals_usd + us$strict_pool_unnamed_hospitals_usd
  expect_equal(us$hospital_summary_usd,
               strict3 + bj_up + sum(pools$pool_usd[pools$call == "HOSPITAL"]) - bj_down)
  # The only strict-Yes dollars a judgment called NOT_HOSPITAL: Ketchikan.
  expect_equal(bj_down, 350000)
})

test_that("SOURCE_SUSPECT stays out of every hospital figure (owner ruling, session 102)", {
  expect_equal(round(us$layer_source_suspect_usd, 2), 3965357.50)
  expect_true(all(s$hospital_summary_usd <= s$award_total_usd + 0.01))
})

test_that("no state's award total exceeds its allotment (the NV double count stays fixed)", {
  st <- s[s$state != "US", ]
  expect_true(all(st$award_total_usd <= st$allotment_usd), info = paste(st$state[st$award_total_usd > st$allotment_usd], collapse = ","))
  expect_equal(st$pool_level_usd[st$state == "NV"], 0)
  expect_equal(st$pool_level_usd[st$state == "LA"], 10736208)
})

test_that("the committed dry run is what the builder produces", {
  f <- here::here(YS_OUT("2026-10-28"))
  expect_true(file.exists(f))
  committed <- readr::read_csv(f, show_col_types = FALSE)
  expect_equal(committed$state, s$state)
  expect_equal(round(committed$hospital_summary_usd, 2), round(s$hospital_summary_usd, 2))
  expect_equal(round(committed$award_total_usd, 2), round(s$award_total_usd, 2))
})
