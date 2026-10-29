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

test_that("the workbook has the five sheets, and every Detail column is defined", {
  x <- here::here(YS_XLSX("2026-10-29"))
  expect_equal(openxlsx::getSheetNames(x), c("Overview", "Detail", "Definitions", "Notes and caveats", "Sources"))
  expect_setequal(YS_DEFINITIONS$column, names(s))
  dt <- openxlsx::read.xlsx(x, "Detail")
  expect_equal(nrow(dt), 51L)
  expect_equal(names(dt), names(s))
  expect_setequal(openxlsx::read.xlsx(x, "Sources")$state, s$state[s$state != "US"])
  df <- openxlsx::read.xlsx(x, "Definitions")
  expect_setequal(df$term[df$sheet == "Overview"], YS_OVERVIEW_DEFINITIONS$column)
  expect_setequal(df$term[df$sheet == "Year 1 status label"], YS_STATUS_LABELS$label)
  expect_setequal(df$term[df$sheet == "Detail"], names(s))
  # No dangling part references (openxlsx 4.2.9 lists drawings it never writes).
  tmp <- tempfile(); utils::unzip(x, exdir = tmp)
  for (f in list.files(file.path(tmp, "xl/worksheets/_rels"), full.names = TRUE)) {
    expect_false(grepl("drawing", paste(readLines(f, warn = FALSE), collapse = "")), info = f)
  }
})

# -- session 111b: presentation only. Every cell below is checked against
# ys_build(), so a figure that moved would fail here, not just look different.

ov_x <- here::here(YS_XLSX("2026-10-29"))
ov <- openxlsx::read.xlsx(ov_x, "Overview", check.names = FALSE, sep.names = " ")
so <- s[order(s$state == "US", s$state_name), ]
meaningful <- so$award_total_usd / so$allotment_usd >= 0.5

test_that("Overview has the ten plainly labelled columns, national row last", {
  expect_equal(names(ov), c("State", "Year 1 status", "FY2026 allotment", "Awards published",
                            "% of allotment awarded", "Hospital $ (best estimate)", "Hospital % of awards",
                            "Hospital % of allotment", "Strict named-hospital $", "Hospitals named, no amount"))
  expect_equal(nrow(ov), 51L)
  expect_equal(ov$State, so$state_name)
  expect_equal(ov$State[51], "National (50 states)")
})

test_that("Overview figures are the Detail figures, unchanged", {
  expect_equal(ov[["FY2026 allotment"]], so$allotment_usd)
  expect_equal(ov[["Awards published"]], so$award_total_usd)
  expect_equal(ov[["Hospital $ (best estimate)"]], so$hospital_summary_usd)
  expect_equal(ov[["Strict named-hospital $"]], so$strict_named_hospital_usd)
  expect_equal(ov[["Hospitals named, no amount"]], so$named_hospital_recipients_no_amount)
  # fractions round to the CSV's one-decimal percentages
  expect_equal(round(100 * ov[["% of allotment awarded"]], 1), so$award_share_of_allotment_pct)
  expect_equal(round(100 * ov[["Hospital % of allotment"]], 1), so$hospital_share_of_allotment_pct)
  ha <- ov[["Hospital % of awards"]]
  expect_equal(round(100 * as.numeric(ha[meaningful]), 1), so$hospital_share_of_awards_pct[meaningful])
})

test_that("Hospital % of awards is n/m below 50% of the allotment, in Overview and Detail", {
  expect_true(all(ov[["Hospital % of awards"]][!meaningful] == "n/m"))
  expect_false(any(ov[["Hospital % of awards"]][meaningful] == "n/m"))
  expect_equal(ov[["Hospital % of awards"]][ov$State == "Illinois"], "n/m")
  expect_equal(ov[["Hospital % of awards"]][ov$State == "National (50 states)"], "n/m")
  dt <- openxlsx::read.xlsx(ov_x, "Detail")
  dm <- s$award_total_usd / s$allotment_usd >= 0.5
  expect_true(all(dt$hospital_share_of_awards_pct[!dm] == "n/m"))
  expect_false(any(is.na(ov[["Hospital % of allotment"]])))
})

test_that("each state carries one defined plain-language status label", {
  st <- ov[["Year 1 status"]][1:50]
  expect_true(all(st %in% YS_STATUS_LABELS$label))
  lab <- stats::setNames(st, so$state[1:50])
  expect_equal(sort(names(lab)[lab == "Complete"]), c("AL", "AR", "FL", "GA"))
  expect_equal(unname(lab["RI"]), "CMS obligation report only")
  expect_equal(sort(names(lab)[lab == "Awards published, not priced"]), c("HI", "IA", "KY", "NC", "TN"))
  expect_equal(sort(names(lab)[lab == "No awards published yet"]), c("AZ", "MA", "MN", "ND", "NM", "UT", "WI"))
  expect_equal(ov[["Year 1 status"]][51], "4 Complete of 50")
})

test_that("currency and percentage formats, frozen panes, widths and the bold national row", {
  wb <- openxlsx::loadWorkbook(ov_x)
  fmts <- vapply(wb$styleObjects, function(o) {
    paste(o$sheet, if (is.null(o$style$numFmt)) "" else o$style$numFmt$formatCode)
  }, character(1))
  for (sh in c("Overview", "Detail")) {
    expect_true(any(fmts == paste(sh, "$#,##0")), info = sh)
    expect_true(any(fmts == paste(sh, "0.0%")), info = sh)
  }
  tmp <- tempfile(); utils::unzip(ov_x, exdir = tmp)
  for (i in 1:2) {
    xml <- paste(readLines(file.path(tmp, "xl/worksheets", paste0("sheet", i, ".xml")), warn = FALSE), collapse = "")
    expect_match(xml, '<pane ySplit="1" xSplit="1" topLeftCell="B2"[^>]*state="frozen"', info = as.character(i))
    w <- as.numeric(regmatches(xml, gregexpr('(?<=width=")[0-9.]+', xml, perl = TRUE))[[1]])
    sh <- c("Overview", "Detail")[i]
    d <- openxlsx::read.xlsx(ov_x, sh, colNames = FALSE)
    # every header and every formatted cell fits its column (or wraps, at the 60 cap)
    need <- vapply(seq_along(d), function(j) {
      v <- d[[j]][-1]; num <- suppressWarnings(as.numeric(v))
      txt <- ifelse(is.na(num), v, paste0("$", formatC(num, format = "f", digits = 0, big.mark = ",")))
      max(nchar(d[[j]][1]), nchar(txt[!is.na(txt)]))
    }, numeric(1))
    expect_equal(length(w), ncol(d), info = sh)
    expect_true(all(w >= pmin(need, 60)), info = sh)
  }
  bold <- vapply(wb$styleObjects, function(o) o$sheet == "Overview" && identical(o$style$fontDecoration, "BOLD") &&
                   52 %in% o$rows, logical(1))
  expect_true(any(bold))
})

test_that("Notes open with How to read this and carry the n/m and coverage notes", {
  n <- openxlsx::read.xlsx(ov_x, "Notes and caveats")$note
  expect_match(n[1], "^HOW TO READ THIS")
  expect_true(any(grepl(YS_NM_NOTE, n, fixed = TRUE)))
  expect_true(any(grepl("State shares are not comparable to one another", n, fixed = TRUE)))
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
