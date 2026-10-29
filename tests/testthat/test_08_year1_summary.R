# test_08_year1_summary.R -- the Year 1 summary table and workbook
#
# The totals are PINNED to the 2026-10-29 build (session 111; the session 110
# dry run was 2026-10-28). The Monday 2026-11-02 session re-runs R/08 after its
# sweep and re-pins them here in the same commit.

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

test_that("the 2026-10-29 totals are pinned (session 111)", {
  expect_equal(us$allotment_usd, 1e10, tolerance = 1e-9)
  expect_equal(round(us$published_priced_usd, 2), 3708434674.31, tolerance = 1e-12)
  # +$267,000 against the 10-28 dry run: Wyoming's two "No bidders" 4.2 lines
  # are pool-level money that session 110's ys_pool_overlap() dropped.
  expect_equal(round(us$award_total_usd, 2), 4171734402.31, tolerance = 1e-12)
  # +$2,527,185.38: TX St. Joseph Health Burleson is now CODED (ruling e).
  expect_equal(round(us$hospital_coded_usd, 2), 1780528970.90, tolerance = 1e-12)
  expect_equal(round(us$hospital_best_judgment_usd, 2), 224694444.87, tolerance = 1e-12)
  expect_equal(round(us$hospital_bj_row_usd, 2), 168359444.87, tolerance = 1e-12)
  # GA $6.5M + $15.635M and IN Region 5 $16.7M; OH's two pools are now NOT (ruling b).
  expect_equal(round(us$hospital_bj_pool_usd, 2), 38835000)
  # NH FHC's CAH and Acute Care Hospital RFA, "approximately $17.5 million" (ruling a).
  expect_equal(round(us$hospital_bj_component_usd, 2), 17500000)
  expect_equal(round(us$hospital_summary_usd, 2), 2005223415.77, tolerance = 1e-12)
  expect_equal(round(us$strict_named_hospital_usd, 2), 1731421723.08, tolerance = 1e-12)
  expect_equal(round(us$strict_pool_named_hospitals_usd, 2), 86555171.43)
  expect_equal(round(us$strict_pool_unnamed_hospitals_usd, 2), 69323109.17)
  expect_equal(round(us$layer_association_ruling_usd, 2), 171816601.60)
  expect_equal(round(us$layer_cms_obligation_usd, 2), 22781325.76)
  expect_equal(round(us$strict_rural_cut_usd, 2), 549250719.56)
  expect_equal(us$best_judgment_rows, 534L)
  expect_equal(us$named_hospital_recipients_no_amount, 269L)
  expect_equal(us$hospital_share_of_awards_pct, 48.1)
  expect_equal(us$hospital_share_of_allotment_pct, 20.1)
})

test_that("the change from the 10-28 dry run is exactly the session 111 rulings", {
  # 2,102,561,809.77 -> 2,005,223,415.77 = -97,338,394.00:
  #   NH FHC row NOT_HOSPITAL (-66,547,394) + its RFA component (+17,500,000)
  #   OH's two shared pools NOT_HOSPITAL on typed members (-61,700,000)
  #   MS Delta Health Transformation Council, 2 rows (-3,291,000)
  #   IN GROW Region 5 tie broken on the lead (+16,700,000)
  #   TX Burleson BJ -> CODED and AK Ketchikan BJ NOT -> CODED NOT: 0
  expect_equal(round(us$hospital_summary_usd - 2102561809.77, 2),
               -66547394 + 17500000 - 61700000 - 3291000 + 16700000)
})

test_that("the summary figure reconciles to the strict partition, dollar for dollar", {
  pools <- readr::read_csv(here::here(YS_POOLS), show_col_types = FALSE)
  r <- rows %>% dplyr::mutate(suspect = ys_has(flag_reason, "SOURCE_SUSPECT"),
                              amt = dplyr::coalesce(amount, 0))
  ok <- r[!r$suspect, ]
  bj_up   <- sum(ok$amt[ok$basis == "BEST_JUDGMENT" & ok$call == "HOSPITAL" & ok$distributed_to_hospital != "Yes"])
  bj_down <- sum(ok$amt[ok$basis == "BEST_JUDGMENT" & ok$call == "NOT_HOSPITAL" & ok$distributed_to_hospital == "Yes"])
  strict3 <- us$strict_named_hospital_usd + us$strict_pool_named_hospitals_usd + us$strict_pool_unnamed_hospitals_usd
  comps <- readr::read_csv(here::here(YS_COMPONENTS), show_col_types = FALSE)
  expect_equal(us$hospital_summary_usd,
               strict3 + bj_up + sum(pools$pool_usd[pools$call == "HOSPITAL"]) +
                 sum(comps$component_usd[comps$call == "HOSPITAL"]) - bj_down)
  # Session 111: Ketchikan is strict No now (ruling f), so no strict-Yes dollar
  # is called NOT_HOSPITAL by a judgment.
  expect_equal(bj_down, 0)
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

test_that("the committed 2026-10-29 build is what the builder produces", {
  f <- here::here(YS_OUT("2026-10-29"))
  expect_true(file.exists(f))
  committed <- readr::read_csv(f, show_col_types = FALSE)
  expect_equal(committed$state, s$state)
  expect_equal(names(committed), names(s))
  expect_equal(round(committed$hospital_summary_usd, 2), round(s$hospital_summary_usd, 2))
  expect_equal(round(committed$award_total_usd, 2), round(s$award_total_usd, 2))
  expect_true(file.exists(here::here(YS_XLSX("2026-10-29"))))
})

test_that("the workbook has the four sheets, and every Summary column is defined", {
  x <- here::here(YS_XLSX("2026-10-29"))
  expect_equal(openxlsx::getSheetNames(x), c("Summary", "Definitions", "Notes and caveats", "Sources"))
  expect_setequal(YS_DEFINITIONS$column, names(s))
  sm <- openxlsx::read.xlsx(x, "Summary")
  expect_equal(nrow(sm), 51L)
  expect_setequal(openxlsx::read.xlsx(x, "Sources")$state, s$state[s$state != "US"])
  # No dangling part references (openxlsx 4.2.9 lists drawings it never writes).
  tmp <- tempfile(); utils::unzip(x, exdir = tmp)
  for (f in list.files(file.path(tmp, "xl/worksheets/_rels"), full.names = TRUE)) {
    expect_false(grepl("drawing", paste(readLines(f, warn = FALSE), collapse = "")), info = f)
  }
})

test_that("Delaware's confidential source is flagged, and no figure rests on it", {
  de <- s[s$state == "DE", ]
  expect_match(de$confidential_source_flag, "^CITED IN STATUS NOTES")
  expect_false(any(rows$confidential_hit))
  others <- s[!s$state %in% c("DE", "US"), ]
  expect_true(all(others$confidential_source_flag == ""))
})

test_that("Ohio's pools are NOT and Indiana Region 5 is HOSPITAL, on typed members", {
  pools <- readr::read_csv(here::here(YS_POOLS), show_col_types = FALSE)
  p <- function(id) pools[pools$pool_id == id, ]
  expect_equal(p("OH_CIN_HUBS")$call, "NOT_HOSPITAL"); expect_equal(p("OH_CIN_HUBS")$hospital_members, 3)
  expect_equal(p("OH_MATERNAL")$call, "NOT_HOSPITAL"); expect_equal(p("OH_MATERNAL")$hospital_members, 2)
  expect_equal(p("GA_P2_CONNECTING_TO_CARE")$call, "HOSPITAL")
  expect_equal(p("GA_P4_TRANSFORMING")$call, "HOSPITAL")
  expect_equal(p("IN_GROW_REGION_5")$call, "HOSPITAL"); expect_equal(p("IN_GROW_REGION_5")$hospital_members, 8)
  expect_true(all((pools$hospital_members * 2 > pools$members) == (pools$call == "HOSPITAL") |
                    pools$hospital_members * 2 == pools$members))
})
