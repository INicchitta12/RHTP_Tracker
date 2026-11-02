# test_08_year1_summary.R -- the Year 1 summary table and workbook
#
# The totals are PINNED to the 2026-11-02 build (session 112, the final Monday
# build; session 111 pinned 2026-10-29, the session 110 dry run was 2026-10-28).
# Session 112: every pin below moved to the committed 2026-11-02 build; the
# change from 2026-10-29 is decomposed by state in its own test.

source(here::here("R", "08_year1_summary.R"))

rows <- ys_rows()
s <- ys_build(rows)
us <- s[s$state == "US", ]
ge <- s[s$state == "US_GE50", ]
st_only <- s[!s$state %in% YS_NATIONAL, ]

test_that("one row per state plus a national row, and the national row is the column sum", {
  expect_equal(nrow(s), 52L)
  expect_equal(utils::tail(s$state, 2), YS_NATIONAL)
  expect_setequal(st_only$state, readr::read_csv(here::here(YS_ALLOT), show_col_types = FALSE)$state)
  st <- st_only
  for (col in c("allotment_usd", "award_total_usd", "hospital_coded_usd", "hospital_best_judgment_usd",
                "hospital_summary_usd", "strict_named_hospital_usd", "strict_pool_named_hospitals_usd",
                "strict_pool_unnamed_hospitals_usd", "layer_source_suspect_usd")) {
    expect_equal(us[[col]], sum(st[[col]]), info = col)
  }
})

test_that("the 2026-11-02 totals are pinned (session 112)", {
  expect_equal(us$allotment_usd, 1e10, tolerance = 1e-9)
  # Session 112: 3,708,434,674.31 -> 4,052,876,537.91 (new and re-priced rosters,
  # incl. Minnesota's 11 MDH sub-recipient awards, $12,453,451, no hospital).
  expect_equal(round(us$published_priced_usd, 2), 4052876537.91, tolerance = 1e-12)
  # Session 112: 4,171,734,402.31 -> 4,512,205,898.91 (+340,471,496.60; by state below).
  expect_equal(round(us$award_total_usd, 2), 4512205898.91, tolerance = 1e-12)
  # Session 112: 1,780,528,970.90 -> 1,821,345,454.64 (+40,816,483.74).
  expect_equal(round(us$hospital_coded_usd, 2), 1821345454.64, tolerance = 1e-12)
  expect_equal(round(us$hospital_best_judgment_usd, 2), 213517084.26, tolerance = 1e-12)
  # Session 112: + MI $5,550,000, + OK $340,608, + TX GHC Hemphill $150,980.39
  # (ruling b), - VT SVMC $518,949 (now CODED on an exact enrolment).
  expect_equal(round(us$hospital_bj_row_usd, 2), 173882084.26, tolerance = 1e-12)
  # GA $6.5M + $15.635M. Session 112 (ruling a): a tie is not a majority, so
  # IN Region 5's $16.7M is NOT; OH's two pools stay NOT (session 111 ruling b).
  expect_equal(round(us$hospital_bj_pool_usd, 2), 22135000)
  # NH FHC's CAH and Acute Care Hospital RFA, "approximately $17.5 million" (ruling a).
  expect_equal(round(us$hospital_bj_component_usd, 2), 17500000)
  expect_equal(round(us$hospital_summary_usd, 2), 2034862538.90, tolerance = 1e-12)
  expect_equal(round(us$strict_named_hospital_usd, 2), 1761827518.82, tolerance = 1e-12)
  # Session 112: + OK's two SSM affiliate lines ($340,608).
  expect_equal(round(us$strict_pool_named_hospitals_usd, 2), 86895779.43)
  # Session 112: + UT's Utah Hospital Association ($9,891,739).
  expect_equal(round(us$strict_pool_unnamed_hospitals_usd, 2), 79214848.17)
  # Session 112: + UHA $9,891,739 and MI $5,550,000.
  expect_equal(round(us$layer_association_ruling_usd, 2), 187258340.60)
  # Session 112: - PA's Guthrie CMS lines ($2,963,577), now on PA's state source.
  expect_equal(round(us$layer_cms_obligation_usd, 2), 19817748.76)
  expect_equal(round(us$strict_rural_cut_usd, 2), 559285398.43)
  expect_equal(us$best_judgment_rows, 631L)   # session 112: 534 -> 631 (MN's 5 default calls incl.)
  expect_equal(us$named_hospital_recipients_no_amount, 269L)
  expect_equal(us$hospital_share_of_awards_pct, 45.1)
  expect_equal(us$hospital_share_of_allotment_pct, 20.3)
})

test_that("the change from the 10-29 build is exactly the session 112 changes, state by state", {
  old <- readr::read_csv(here::here(YS_OUT("2026-10-29")), show_col_types = FALSE)
  d <- function(col) {
    v <- round(s[[col]] - old[[col]][match(s$state, old$state)], 2)
    k <- abs(v) > 0.005 & !s$state %in% YS_NATIONAL
    stats::setNames(v[k], s$state[k])
  }
  # 2,005,223,415.77 -> 2,034,862,538.90 = +29,639,123.13:
  #   CO HCPF 11-02 re-pricing (-6,659,872)
  #   IN GROW Region 5, a tie, NOT_HOSPITAL (ruling a, -16,700,000)
  #   MI 10-01 roster (+12,960,656 coded, +5,550,000 judged)
  #   OK Lung Cancer Screening (+1,532,736) and its SSM lines (+340,608)
  #   PA Selected Projects (+14,597,014.54; Guthrie counted once)
  #   SD register (+2,515,882)
  #   TX Anson corrected (+262,566.30) and GHC Hemphill (ruling b, +150,980.39)
  #   UT, a new state (+5,196,812.90 named, +9,891,739 UHA pool)
  #   VT SVMC judged -> coded (0)
  expect_equal(round(us$hospital_summary_usd - 2005223415.77, 2), 29639123.13)
  expect_equal(d("hospital_summary_usd"),
               c(CO = -6659872, IN = -16700000, MI = 12960656 + 5550000, OK = 1532736 + 340608,
                 PA = 14597014.54, SD = 2515882, TX = round(262566.30 + 150980.39, 2),
                 UT = 5196812.90 + 9891739))
  expect_equal(round(sum(d("hospital_summary_usd")), 2), 29639123.13)
  expect_equal(d("strict_named_hospital_usd"),
               c(CO = -6659872, MI = 12960656, OK = 1532736, PA = 14597014.54, SD = 2515882,
                 TX = 262566.30, UT = 5196812.90))
  expect_equal(round(us$strict_named_hospital_usd - 1731421723.08, 2), 30405795.74)
  expect_equal(d("hospital_bj_pool_usd"), c(IN = -16700000))
  # Awards: 4,171,734,402.31 -> 4,512,205,898.91 = +340,471,496.60 (MN a new
  # award state, $12,453,451, no hospital dollar)
  expect_equal(d("award_total_usd"),
               c(CO = -6255842.26, MI = 60422410, MN = 12453451, OK = 5619987.97, PA = 71678990.87,
                 SD = 281000, TX = 5133.96, UT = 193095906.92, VT = 1581381.14, WV = 1589077))
  expect_equal(round(us$award_total_usd - 4171734402.31, 2), 340471496.60)
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
  # Session 112: TX's Anson Hospital District ($509,936.50) is corrected by
  # HHSC's 10/29 list and leaves the layer; NV's FLEX-28 and FLEX-36 remain.
  expect_equal(round(us$layer_source_suspect_usd, 2), 3455421.00)
  expect_true(all(s$hospital_summary_usd <= s$award_total_usd + 0.01))
})

test_that("no state's award total exceeds its allotment (the NV double count stays fixed)", {
  st <- st_only
  expect_true(all(st$award_total_usd <= st$allotment_usd), info = paste(st$state[st$award_total_usd > st$allotment_usd], collapse = ","))
  expect_equal(st$pool_level_usd[st$state == "NV"], 0)
  expect_equal(st$pool_level_usd[st$state == "LA"], 10736208)
})

test_that("the committed 2026-11-02 build is what the builder produces", {
  f <- here::here(YS_OUT("2026-11-02"))
  expect_true(file.exists(f))
  committed <- readr::read_csv(f, show_col_types = FALSE)
  expect_equal(committed$state, s$state)
  expect_equal(names(committed), names(s))
  expect_equal(round(committed$hospital_summary_usd, 2), round(s$hospital_summary_usd, 2))
  expect_equal(round(committed$award_total_usd, 2), round(s$award_total_usd, 2))
  expect_true(file.exists(here::here(YS_XLSX("2026-11-02"))))
})

test_that("the workbook has the five sheets, and every Detail column is defined", {
  x <- here::here(YS_XLSX("2026-11-02"))
  expect_equal(openxlsx::getSheetNames(x), c("Overview", "Detail", "Definitions", "Notes and caveats", "Sources"))
  expect_setequal(YS_DEFINITIONS$column, names(s))
  dt <- openxlsx::read.xlsx(x, "Detail")
  expect_equal(nrow(dt), 52L)
  expect_equal(names(dt), names(s))
  expect_setequal(openxlsx::read.xlsx(x, "Sources")$state, st_only$state)
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

ov_x <- here::here(YS_XLSX("2026-11-02"))
ov <- openxlsx::read.xlsx(ov_x, "Overview", check.names = FALSE, sep.names = " ")
so <- s[order(match(s$state, YS_NATIONAL, nomatch = 0L), s$state_name), ]
# the n/m test reads STATE-SOURCED awards (CMS obligation-report files removed)
ss_tab <- ys_state_source_table(rows, NULL, NULL, sc_state_files())
ss_award <- function(t) {
  v <- ss_tab$award_total_usd[match(t$state, ss_tab$state)]
  v[t$state == "US"] <- sum(ss_tab$award_total_usd)
  v[t$state == "US_GE50"] <- t$award_total_usd[t$state == "US_GE50"]
  v
}
meaningful <- ss_award(so) / so$allotment_usd >= 0.5

test_that("Overview has the ten plainly labelled columns, national row last", {
  expect_equal(names(ov), c("State", "Year 1 status", "FY2026 allotment", "Awards published",
                            "% of allotment awarded", "Hospital $ (best estimate)", "Hospital % of awards",
                            "Hospital % of allotment", "Strict named-hospital $", "Hospitals named, no amount"))
  expect_equal(nrow(ov), 52L)
  # Session 112: Overview shows the subset row under a short label; Detail and
  # the CSV keep the full state_name.
  expect_equal(ov$State, ys_overview_state_label(so))
  expect_equal(ov$State[1:51], so$state_name[1:51])
  expect_equal(ov$State[51], "National (50 states)")
  expect_equal(ov$State[52], "23 states \u226550% published*")
  expect_equal(so$state_name[52], "States with \u226550% published, state award sources (n = 23)")
  expect_equal(openxlsx::read.xlsx(ov_x, "Detail")$state_name[52],
               "States with \u226550% published, state award sources (n = 23)")
})

test_that("Overview figures are the Detail figures, unchanged", {
  expect_equal(ov[["FY2026 allotment"]], so$allotment_usd)
  expect_equal(ov[["Awards published"]], so$award_total_usd)
  expect_equal(ov[["Hospital $ (best estimate)"]], so$hospital_summary_usd)
  expect_equal(ov[["Strict named-hospital $"]], so$strict_named_hospital_usd)
  expect_equal(ov[["Hospitals named, no amount"]][1:51], so$named_hospital_recipients_no_amount[1:51])
  # fractions round to the CSV's one-decimal percentages
  expect_equal(round(100 * ov[["% of allotment awarded"]][1:51], 1), so$award_share_of_allotment_pct[1:51])
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
  dm <- ss_award(s) / s$allotment_usd >= 0.5
  expect_true(all(dt$hospital_share_of_awards_pct[!dm] == "n/m"))
  expect_false(any(is.na(ov[["Hospital % of allotment"]])))
})

test_that("the state rows' n/m test is state-sourced: only Rhode Island moves (owner decision, session 111b)", {
  all_src <- so$award_total_usd / so$allotment_usd >= 0.5
  expect_equal(so$state[all_src != meaningful], "RI")
  expect_equal(ov[["Hospital % of awards"]][ov$State == "Rhode Island"], "n/m")
  dt <- openxlsx::read.xlsx(ov_x, "Detail")
  expect_equal(dt$hospital_share_of_awards_pct[dt$state == "RI"], "n/m")
  # 28 states read n/m before; 29 in session 111b; session 112: PA and UT pass
  # 50% on state sources, so 27, plus the national row
  expect_equal(sum(!meaningful[!so$state %in% YS_NATIONAL]), 27L)
  expect_false(meaningful[so$state == "US"])
  expect_true(meaningful[so$state == "US_GE50"])
  # the CSV keeps the computed value; the figure itself did not move
  expect_equal(s$hospital_share_of_awards_pct[s$state == "RI"], 20.1)
  # states with CMS lines that are meaningful keep a share; today there are none
  # (session 112: PA carries no CMS lines now, and is meaningful on its own source)
  expect_false(any(meaningful[so$state %in% c("NE", "RI")]))
  expect_true(meaningful[so$state == "PA"])
})

test_that("each state carries one defined plain-language status label", {
  st <- ov[["Year 1 status"]][1:50]
  expect_true(is.na(ov[["Year 1 status"]][52]))
  expect_true(all(st %in% YS_STATUS_LABELS$label))
  lab <- stats::setNames(st, so$state[1:50])
  # Session 112: + ID, UT, VT, WY (R/03aw)
  expect_equal(sort(names(lab)[lab == "Complete"]), c("AL", "AR", "FL", "GA", "ID", "UT", "VT", "WY"))
  expect_equal(unname(lab["RI"]), "CMS obligation report only")
  expect_equal(sort(names(lab)[lab == "Awards published, not priced"]), c("HI", "IA", "KY", "NC", "TN"))
  # Session 112: UT (extracted, COMPLETE) and MN (extracted, PARTIAL) leave this list.
  expect_equal(sort(names(lab)[lab == "No awards published yet"]), c("AZ", "MA", "ND", "NM", "WI"))
  expect_equal(unname(lab["MN"]), "Partial: awarding continues")
  expect_equal(ov[["Year 1 status"]][51], "8 Complete of 50")
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
                   all(c(52, 53) %in% o$rows), logical(1))
  expect_true(any(bold))
})

test_that("the second national row: states with >=50% published on state award sources, pinned (owner decisions, session 111b)", {
  cms_states <- sort(unique(rows$state[rows$validation_source_type %in% "CMS_OBLIGATION_REPORT"]))
  # Session 112: PA_CMS is gone (Guthrie is on PA's own Selected Projects list).
  expect_equal(cms_states, c("NE", "RI"))
  expect_setequal(ys_cms_obligation_files(rows), c("NE_CMS", "RI"))
  # each state's "% published" is computed on its state-sourced awards only
  ss <- ys_state_source_table(rows, NULL, NULL, sc_state_files())
  sh <- function(t, x) t$award_total_usd[t$state == x] / t$allotment_usd[t$state == x]
  expect_equal(ss$award_total_usd[ss$state == "NE"], st_only$award_total_usd[st_only$state == "NE"] - 3977841.10, tolerance = 1e-9)
  # Session 112: PA has no CMS lines, so its state-sourced total is its full total.
  expect_equal(ss$award_total_usd[ss$state == "PA"], st_only$award_total_usd[st_only$state == "PA"], tolerance = 1e-9)
  expect_equal(ss$award_total_usd[ss$state == "RI"], 0)
  expect_true(sh(st_only, "RI") >= 0.5)   # over the line on CMS lines alone ...
  expect_true(sh(ss, "RI") < 0.5)         # ... and out on state-sourced awards
  expect_equal(sum(ss$layer_cms_obligation_usd), 0)
  m <- ss[ss$award_total_usd / ss$allotment_usd >= 0.5, ]
  expect_false("RI" %in% m$state)
  # Session 112: + PA (60.4%, Selected Projects) and UT (98.6%, a new state): 23.
  expect_equal(nrow(m), 23L)
  expect_equal(sort(m$state), c("AK", "AL", "AR", "CA", "CO", "FL", "GA", "ID", "IN", "MD", "MI", "MS",
                                "NJ", "NV", "OH", "OR", "PA", "SC", "SD", "TX", "UT", "VT", "WY"))
  expect_equal(ge$layer_cms_obligation_usd, 0)
  # members carry no CMS rows today, so their state-sourced rows equal their full rows
  expect_equal(as.data.frame(m[, names(s)]), as.data.frame(st_only[match(m$state, st_only$state), names(s)]),
               ignore_attr = TRUE)
  for (col in names(s)[vapply(s, is.numeric, logical(1))]) {
    if (grepl("_pct$", col)) next
    expect_equal(ge[[col]], sum(m[[col]]), info = col)
  }
  # RI out: -$156,169,931 allotment, -$78,727,110.44 awards, -$15,839,907.67 hospital (HARI, unnamed pool)
  # Session 112 (n = 23): 4,284,392,337 / 3,362,841,950.78 / 1,557,146,269.69 /
  # 1,451,104,633.38 at n = 21 moved with PA and UT joining and the members'
  # own session 112 changes.
  expect_equal(round(ge$allotment_usd, 2), 4673429957)
  expect_equal(round(ge$award_total_usd, 2), 3728812818.21, tolerance = 1e-12)
  expect_equal(round(ge$hospital_summary_usd, 2), 1612024736.82, tolerance = 1e-12)
  expect_equal(round(ge$strict_named_hospital_usd, 2), 1507090381.12, tolerance = 1e-12)
  expect_equal(ge$hospital_share_of_awards_pct, 43.2)
  expect_equal(ge$hospital_share_of_allotment_pct, 34.5)
  # a subset of the national row, never more
  for (col in c("allotment_usd", "award_total_usd", "hospital_summary_usd", "strict_named_hospital_usd")) {
    expect_true(ge[[col]] <= us[[col]], info = col)
  }
  # Overview shows its six figures and leaves the rest blank
  g <- ov[52, ]
  expect_equal(g[["FY2026 allotment"]], ge$allotment_usd)
  expect_equal(g[["Awards published"]], ge$award_total_usd)
  expect_equal(g[["Hospital $ (best estimate)"]], ge$hospital_summary_usd)
  expect_equal(round(100 * as.numeric(g[["Hospital % of awards"]]), 1), 43.2)
  expect_equal(round(100 * g[["Hospital % of allotment"]], 1), 34.5)
  expect_equal(g[["Strict named-hospital $"]], ge$strict_named_hospital_usd)
  expect_true(is.na(g[["% of allotment awarded"]]))
  expect_true(is.na(g[["Hospitals named, no amount"]]))
  # the national row keeps n/m
  expect_equal(ov[["Hospital % of awards"]][51], "n/m")
  dt <- openxlsx::read.xlsx(ov_x, "Detail")
  expect_equal(dt$state[52], "US_GE50")
  expect_equal(round(100 * as.numeric(dt$hospital_share_of_awards_pct[52]), 1), 43.2)
})

test_that("the subset drops CMS files, refuses a mixed file, and refuses a CMS dollar", {
  bad <- rows
  i <- which(bad$file_key == "AK")[1]
  bad$validation_source_type[i] <- "CMS_OBLIGATION_REPORT"
  expect_error(ys_cms_obligation_files(bad), "mix CMS obligation lines")
  # a member state that gains a CMS-only file keeps its state-sourced row: the CMS
  # file is dropped before the subset is built
  ak <- rows[rows$file_key == "AK", ][1, ]
  ak$file_key <- "AK_CMS_TEST"; ak$validation_source_type <- "CMS_OBLIGATION_REPORT"; ak$amount <- 1e6
  extra <- dplyr::bind_rows(rows, ak)
  expect_true("AK_CMS_TEST" %in% ys_cms_obligation_files(extra))
  ss2 <- ys_state_source_table(extra, NULL, NULL, sc_state_files())
  expect_equal(ss2$award_total_usd[ss2$state == "AK"], st_only$award_total_usd[st_only$state == "AK"])
})

test_that("Notes open with How to read this and carry the n/m and coverage notes", {
  n <- openxlsx::read.xlsx(ov_x, "Notes and caveats")$note
  expect_match(n[1], "^HOW TO READ THIS")
  expect_true(any(grepl(YS_NM_NOTE, n, fixed = TRUE)))
  expect_true(any(grepl("Shown only where the state's STATE-SOURCED awards published are at least 50% of its allotment", n, fixed = TRUE) &
                    grepl("Rhode Island, whose only rows are CMS lines, reads n/m", n, fixed = TRUE)))
  expect_true(any(grepl("The national hospital share of awards is reported only for states where most of the money is published (see the second national row).", n, fixed = TRUE)))
  expect_true(any(grepl("rests on state award sources only", n, fixed = TRUE) &
                    grepl("computed on its state-sourced awards alone", n, fixed = TRUE) &
                    grepl("Rhode Island 0.0% state-sourced (50.4% with CMS lines; does not qualify)", n, fixed = TRUE)))
  expect_true(any(grepl("State shares are not comparable to one another", n, fixed = TRUE)))
})

test_that("Delaware's confidential source is flagged, and no figure rests on it", {
  de <- s[s$state == "DE", ]
  expect_match(de$confidential_source_flag, "^CITED IN STATUS NOTES")
  expect_false(any(rows$confidential_hit))
  others <- s[!s$state %in% c("DE", YS_NATIONAL), ]
  expect_true(all(others$confidential_source_flag == ""))
})

test_that("Ohio's pools are NOT and Indiana Region 5 is NOT (a tie), on typed members", {
  pools <- readr::read_csv(here::here(YS_POOLS), show_col_types = FALSE)
  p <- function(id) pools[pools$pool_id == id, ]
  expect_equal(p("OH_CIN_HUBS")$call, "NOT_HOSPITAL"); expect_equal(p("OH_CIN_HUBS")$hospital_members, 3)
  expect_equal(p("OH_MATERNAL")$call, "NOT_HOSPITAL"); expect_equal(p("OH_MATERNAL")$hospital_members, 2)
  expect_equal(p("GA_P2_CONNECTING_TO_CARE")$call, "HOSPITAL")
  expect_equal(p("GA_P4_TRANSFORMING")$call, "HOSPITAL")
  # Session 112 (owner ruling a): a tie is not a majority. Region 5 is 8 of 16,
  # so NOT_HOSPITAL, and no pool is exempt from the strict-majority rule.
  expect_equal(p("IN_GROW_REGION_5")$call, "NOT_HOSPITAL"); expect_equal(p("IN_GROW_REGION_5")$hospital_members, 8)
  expect_equal(p("IN_GROW_REGION_5")$members, 16)
  expect_true(all((pools$hospital_members * 2 > pools$members) == (pools$call == "HOSPITAL")))
})
