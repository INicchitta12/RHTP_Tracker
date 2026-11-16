# test_08_year1_summary.R -- the Year 1 summary table and workbook
#
# The totals are PINNED to the 2026-11-09 build, re-pinned 2026-11-11 by session
# 116f (the vendor layer; hospital columns unchanged to the cent) (session 116c, FSRS/FFATA
# subawards as an award source; before it, session 115, after WV's 10-30
# CAMC release; session 114 pinned 2026-11-04, after the OK CHW and MO Smart
# Growth owner rulings; session 112 pinned 2026-11-02, the final
# Monday build; session 111 pinned 2026-10-29; the session 110 dry run was
# 2026-10-28). The change from the pre-FSRS 2026-11-09 build
# (year1_summary_2026-11-09_pre_fsrs.csv) is decomposed by state in its own test.

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

test_that("the 2026-11-09 totals are pinned (session 116c)", {
  expect_equal(us$allotment_usd, 1e10, tolerance = 1e-9)
  # Session 114: 4,052,876,537.91 -> 4,092,277,358.46 (+ MO Smart Growth
  # contingent roster, 25 rows, $39,400,820.55).
  # Session 115: + WV CAMC $3,930,266 -> 4,096,207,624.46.
  # Session 116c: FSRS priced $0 rows and added 684 new rows -> 5,735,713,681.34.
  expect_equal(round(us$published_priced_usd, 2), 5752690161.34, tolerance = 1e-12)
  # Session 114: 4,512,205,898.91 -> 4,556,066,882.39 (+ MO $39,400,820.55,
  # + OK CHW Expansion pool $4,460,162.93, on no row).
  # Session 115: + WV CAMC $3,930,266.
  # Session 116c: 4,559,997,148.39 -> 6,189,503,205.27 (FSRS).
  # Session 117a: + WV's 11-10 release, $16,976,480 (every US pin below moves
  # by exactly that release: + $1,544,313 Cabell Huntington Hospital).
  expect_equal(round(us$award_total_usd, 2), 6206479685.27, tolerance = 1e-12)
  # Session 114: + MO's 14 hospital rows, $31,862,169.80.
  # Session 115: + WV CAMC's three hospital rows, $3,930,266.
  # Session 116c: + FSRS strict named dollars (+$360,669,892.98).
  expect_equal(round(us$hospital_coded_usd, 2), 2231487495.70, tolerance = 1e-12)
  # Session 116c: + VHHA Foundation $27,201,764 (association ruling, now priced).
  expect_equal(round(us$hospital_best_judgment_usd, 2), 243439128.19, tolerance = 1e-12)
  expect_equal(round(us$hospital_bj_row_usd, 2), 174615089.26, tolerance = 1e-12)
  # GA $6.5M + $15.635M; session 114 + OK CHW Expansion $4,460,162.93 (29 of
  # 48 typed hospitals, a strict majority; owner ruling). IN Region 5 (a tie)
  # and OH's two pools stay NOT.
  expect_equal(round(us$hospital_bj_pool_usd, 2), 26595162.93)
  # NH FHC's CAH and Acute Care Hospital RFA, "approximately $17.5 million" (ruling a).
  # Session 116d (ruling a): + VHHA Foundation RPM $14,837,326 and GME $9,891,550.
  expect_equal(round(us$hospital_bj_component_usd, 2), 42228876)
  expect_equal(round(us$hospital_summary_usd, 2), 2474926623.89, tolerance = 1e-12)
  expect_equal(round(us$strict_named_hospital_usd, 2), 2171969559.88, tolerance = 1e-12)
  expect_equal(round(us$strict_pool_named_hospitals_usd, 2), 86895779.43)
  expect_equal(round(us$strict_pool_unnamed_hospitals_usd, 2), 79214848.17)
  expect_equal(round(us$layer_association_ruling_usd, 2), 187258340.60)
  expect_equal(round(us$layer_cms_obligation_usd, 2), 19817748.76)
  # Session 114: + MO's four CAHs (Hermann, Mercy Perry, Scotland, Washington
  # County), $7,305,357.76.
  # Session 116c: FSRS rows typed on CMS enrolment -> 673,247,294.36.
  expect_equal(round(us$strict_rural_cut_usd, 2), 673247294.36)
  # session 114: 631 -> 639 (OK CHW 3, MO SG 5); session 115: -1 (CA Legacy MD
  # Medical Group now CODED as PHYSICIAN_PRACTICE).
  # Session 116c: + 220 (FSRS new rows judged NOT_HOSPITAL by class, and others).
  expect_equal(us$best_judgment_rows, 841L)  # session 117a: + 2 ROAM WV rows (default)
  # + 29 OK CHW (session 114); - AVEM Health Partners (session 115, owner ruling a).
  # Session 116 (same-date rebuild): + 4 IA Combat Cancer Round 2 intents at $0.
  # Session 116c: 301 -> 219, FSRS priced Iowa's and others' $0 hospital rows.
  expect_equal(us$named_hospital_recipients_no_amount, 218L)
  expect_equal(us$hospital_share_of_awards_pct, 39.9)
  expect_equal(us$hospital_share_of_allotment_pct, 24.7)
})

test_that("the change from the pre-FSRS 11-09 build is exactly the session 116c FSRS changes, state by state", {
  old <- readr::read_csv(here::here("data/reference/year1_summary_2026-11-09_pre_fsrs.csv"), show_col_types = FALSE)
  d <- function(col) {
    v <- round(s[[col]] - old[[col]][match(s$state, old$state)], 2)
    k <- abs(v) > 0.005 & !s$state %in% YS_NATIONAL
    stats::setNames(v[k], s$state[k])
  }
  # Session 117a: WV's 11-10 release adds $1,544,313 on top of the FSRS change.
  expect_equal(round(us$hospital_summary_usd - 2075115137.63, 2), 398267173.26 + 1544313)
  expect_equal(d("hospital_summary_usd"),
               c(CT = 15005890, DE = 3291276, IA = 163815846.2, IL = 53821674.53, KS = 1950110, KY = 4348529,
                 ME = 258193, MN = 68840377, NC = 14550000, ND = 8751588.75, NE = 12987780.26, NV = 997361,
                 OK = 136594, TN = 16699481.52, VA = 24728876, VT = 2000000, WV = 6083596 + 1544313))
  # strict moves in the same states less VA (its $24.7M are the VHHA components,
  # a best-judgment figure) and IA by $733,005 less (Sanford Medical Center, a
  # best-judgment HOSPITAL call on a row typed non-hospital; ruling f)
  ds <- d("strict_named_hospital_usd")
  expect_equal(ds[["IA"]], 163082841.2)
  expect_equal(ds[names(ds) != "IA"], d("hospital_summary_usd")[!names(d("hospital_summary_usd")) %in% c("VA", "IA")])
  expect_equal(d("hospital_bj_pool_usd"), stats::setNames(numeric(0), character(0)))
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
  # Session 116d (ruling e): NV FLEX-28 cleared; FLEX-36 remains.
  expect_equal(round(us$layer_source_suspect_usd, 2), 2458060.00)
  expect_true(all(s$hospital_summary_usd <= s$award_total_usd + 0.01))
})

test_that("no state's award total exceeds its allotment (the NV double count stays fixed)", {
  st <- st_only
  expect_true(all(st$award_total_usd <= st$allotment_usd), info = paste(st$state[st$award_total_usd > st$allotment_usd], collapse = ","))
  expect_equal(st$pool_level_usd[st$state == "NV"], 0)
  expect_equal(st$pool_level_usd[st$state == "LA"], 10736208)
})

test_that("the committed 2026-11-13 build is what the builder produces (session 117a)", {
  f <- here::here(YS_OUT("2026-11-13"))
  expect_true(file.exists(f))
  committed <- readr::read_csv(f, show_col_types = FALSE)
  expect_equal(committed$state, s$state)
  expect_equal(names(committed), names(s))
  expect_equal(round(committed$hospital_summary_usd, 2), round(s$hospital_summary_usd, 2))
  expect_equal(round(committed$award_total_usd, 2), round(s$award_total_usd, 2))
  expect_true(file.exists(here::here(YS_XLSX("2026-11-13"))))
})

# SESSION 116f: the vendor layer re-pinned the build to 2026-11-11. The hospital
# columns must be unchanged to the cent: the whole 11-11 summary CSV equals the
# 11-09 one, every column and every row.
test_that("the 2026-11-11 hospital columns equal the 2026-11-09 build to the cent (session 116f)", {
  a <- readr::read_csv(here::here(YS_OUT("2026-11-09")), show_col_types = FALSE)
  b <- readr::read_csv(here::here(YS_OUT("2026-11-11")), show_col_types = FALSE)
  expect_equal(names(a), names(b))
  expect_equal(a$state, b$state)
  for (col in grep("hospital|strict_|award_total|allotment", names(a), value = TRUE)) {
    if (is.numeric(a[[col]])) expect_equal(round(b[[col]], 2), round(a[[col]], 2), info = col) else
      expect_identical(b[[col]], a[[col]], info = col)
  }
  expect_identical(as.data.frame(b), as.data.frame(a))
})

test_that("the Vendor spending table: verified only, never across types, national pins (session 116f)", {
  vt <- readr::read_csv(here::here(YS_VENDOR_OUT("2026-11-11")), show_col_types = FALSE)
  expect_equal(nrow(vt), 51L)
  expect_equal(utils::tail(vt$state, 1), "US")
  usv <- vt[vt$state == "US", ]
  st <- vt[vt$state != "US", ]
  for (col in grep("_usd$|_rows$", names(vt), value = TRUE)) expect_equal(usv[[col]], sum(st[[col]]), info = col)
  expect_equal(round(usv$vendor_total_award_usd, 2), 167506827.60)
  expect_equal(round(usv$vendor_total_intent_usd, 2), 48233747.84)
  expect_equal(round(usv$vendor_total_contract_maximum_usd, 2), 25965898)
  expect_equal(round(usv$vendor_total_obligation_usd, 2), 2205500)
  expect_equal(usv$vendor_verified_rows, 34L)
  # the hospital columns on this sheet are Detail's, unchanged
  expect_equal(round(usv$hospital_summary_usd, 2), 2473382310.89)
  # within a type the categories add to the total
  for (tn in c("award", "intent", "contract_maximum", "obligation")) {
    parts <- grep(paste0("^vendor_(consultant|data_tech_vendor|administrator|non_provider_intermediary)_", tn, "_usd$"),
                  names(vt), value = TRUE)
    expect_equal(rowSums(vt[, parts]), vt[[paste0("vendor_total_", tn, "_usd")]], info = tn)
  }
  expect_true(all(vt$vendor_out_of_state_award_usd <= vt$vendor_total_award_usd))
})

test_that("the workbook has the six sheets, and every Detail column is defined", {
  x <- here::here(YS_XLSX("2026-11-13"))
  expect_equal(openxlsx::getSheetNames(x), c("Overview", "Detail", "Vendor spending", "Definitions", "Notes and caveats", "Sources"))
  expect_setequal(YS_DEFINITIONS$column, names(s))
  dt <- openxlsx::read.xlsx(x, "Detail")
  expect_equal(nrow(dt), 52L)
  expect_equal(names(dt), names(s))
  # Session 116c: a national FSRS row heads the Sources sheet.
  src <- openxlsx::read.xlsx(x, "Sources")$state
  expect_equal(src[1], "FSRS (all states)")
  expect_setequal(src[-1], st_only$state)
  df <- openxlsx::read.xlsx(x, "Definitions")
  expect_setequal(df$term[df$sheet == "Overview"], YS_OVERVIEW_DEFINITIONS$column)
  expect_setequal(df$term[df$sheet == "Year 1 status label"], YS_STATUS_LABELS$label)
  expect_setequal(df$term[df$sheet == "Detail"], names(s))
  expect_setequal(df$term[df$sheet == "Vendor spending"], YS_VENDOR_DEFINITIONS$column)
  # No dangling part references (openxlsx 4.2.9 lists drawings it never writes).
  tmp <- tempfile(); utils::unzip(x, exdir = tmp)
  for (f in list.files(file.path(tmp, "xl/worksheets/_rels"), full.names = TRUE)) {
    expect_false(grepl("drawing", paste(readLines(f, warn = FALSE), collapse = "")), info = f)
  }
})

# -- session 111b: presentation only. Every cell below is checked against
# ys_build(), so a figure that moved would fail here, not just look different.

ov_x <- here::here(YS_XLSX("2026-11-13"))
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
  expect_equal(ov$State[52], "32 states \u226550% published*")
  expect_equal(so$state_name[52], "States with \u226550% published, state award sources (n = 32)")
  expect_equal(openxlsx::read.xlsx(ov_x, "Detail")$state_name[52],
               "States with \u226550% published, state award sources (n = 32)")
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
  expect_equal(ov[["Hospital % of awards"]][ov$State == "Wisconsin"], "n/m")
  # Session 116d (owner ruling b): the national share prints.
  expect_equal(round(100 * as.numeric(ov[["Hospital % of awards"]][ov$State == "National (50 states)"]), 1), 39.9)  # session 117a: 40.0 -> 39.9 (WV awards +$17.0M, hospital +$1.5M)
  dt <- openxlsx::read.xlsx(ov_x, "Detail")
  dm <- ss_award(s) / s$allotment_usd >= 0.5
  expect_true(all(dt$hospital_share_of_awards_pct[!dm] == "n/m"))
  expect_false(any(is.na(ov[["Hospital % of allotment"]])))
})

test_that("the state rows' n/m test is state-sourced: only Rhode Island moves (owner decision, session 111b)", {
  all_src <- so$award_total_usd / so$allotment_usd >= 0.5
  # Session 116c: RI (24.2% state-sourced, 74.6% with CMS lines) and the
  # national row (n/m by owner decision) are the only two that differ.
  expect_equal(so$state[all_src != meaningful], "RI")
  expect_equal(ov[["Hospital % of awards"]][ov$State == "Rhode Island"], "n/m")
  dt <- openxlsx::read.xlsx(ov_x, "Detail")
  expect_equal(dt$hospital_share_of_awards_pct[dt$state == "RI"], "n/m")
  # 28 states read n/m before; 29 in session 111b; session 112: PA and UT pass
  # 50% on state sources, so 27, plus the national row
  # Session 116c (FSRS): 18.
  expect_equal(sum(!meaningful[!so$state %in% YS_NATIONAL]), 18L)
  expect_true(meaningful[so$state == "US"])
  expect_true(meaningful[so$state == "US_GE50"])
  # the CSV keeps the computed value; the figure itself did not move
  expect_equal(s$hospital_share_of_awards_pct[s$state == "RI"], 13.6)
  # states with CMS lines that are meaningful keep a share; today there are none
  # (session 112: PA carries no CMS lines now, and is meaningful on its own source)
  # Session 116c: NE is meaningful on state sources (57.8%); RI is not.
  expect_true(meaningful[so$state == "NE"])
  expect_false(meaningful[so$state == "RI"])
  expect_true(meaningful[so$state == "PA"])
})

test_that("each state carries one defined plain-language status label", {
  st <- ov[["Year 1 status"]][1:50]
  expect_true(is.na(ov[["Year 1 status"]][52]))
  expect_true(all(st %in% YS_STATUS_LABELS$label))
  lab <- stats::setNames(st, so$state[1:50])
  # Session 112: + ID, UT, VT, WY (R/03aw)
  # Session 117a: + NE, SD, WV.
  expect_equal(sort(names(lab)[lab == "Complete"]), c("AL", "AR", "FL", "GA", "ID", "NE", "SD", "UT", "VT", "WV", "WY"))
  # Session 116c: RI's FSRS rows are state-sourced awards; FSRS priced HI, IA,
  # KY, NC and TN, and gave AZ, ND and NM their first award rows.
  expect_equal(unname(lab["RI"]), "Partial: awarding continues")
  expect_equal(sort(names(lab)[lab == "Awards published, not priced"]), character(0))
  # Session 112: UT (extracted, COMPLETE) and MN (extracted, PARTIAL) leave this list.
  expect_equal(sort(names(lab)[lab == "No awards published yet"]), c("MA", "WI"))
  expect_equal(unname(lab["MN"]), "Partial: awarding continues")
  expect_equal(ov[["Year 1 status"]][51], "11 Complete of 50")
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
  # Session 116c: RI's FSRS rows are state-sourced ($37,724,386.79): 24.2%.
  expect_equal(round(ss$award_total_usd[ss$state == "RI"], 2), 37724386.79)
  expect_true(sh(st_only, "RI") >= 0.5)   # over the line on CMS lines alone ...
  expect_true(sh(ss, "RI") < 0.5)         # ... and out on state-sourced awards
  expect_equal(sum(ss$layer_cms_obligation_usd), 0)
  m <- ss[ss$award_total_usd / ss$allotment_usd >= 0.5, ]
  expect_false("RI" %in% m$state)
  # Session 112: + PA (60.4%, Selected Projects) and UT (98.6%, a new state): 23.
  # Session 116c (FSRS): + CT DE HI IA IL KS NE OK VA: 32.
  expect_equal(nrow(m), 32L)
  expect_equal(sort(m$state), c("AK", "AL", "AR", "CA", "CO", "CT", "DE", "FL", "GA", "HI", "IA", "ID", "IL",
                                "IN", "KS", "MD", "MI", "MS", "NE", "NJ", "NV", "OH", "OK", "OR", "PA", "SC",
                                "SD", "TX", "UT", "VA", "VT", "WY"))
  expect_equal(ge$layer_cms_obligation_usd, 0)
  # members other than NE carry no CMS rows, so their state-sourced rows equal their full rows
  m2 <- m[m$state != "NE", ]
  expect_equal(as.data.frame(m2[, names(s)]), as.data.frame(st_only[match(m2$state, st_only$state), names(s)]),
               ignore_attr = TRUE)
  for (col in names(s)[vapply(s, is.numeric, logical(1))]) {
    if (grepl("_pct$", col)) next
    expect_equal(ge[[col]], sum(m[[col]]), info = col)
  }
  # RI out: -$156,169,931 allotment, -$78,727,110.44 awards, -$15,839,907.67 hospital (HARI, unnamed pool)
  # Session 112 (n = 23): 4,284,392,337 / 3,362,841,950.78 / 1,557,146,269.69 /
  # 1,451,104,633.38 at n = 21 moved with PA and UT joining and the members'
  # own session 112 changes.
  # Session 116c (n = 32).
  expect_equal(round(ge$allotment_usd, 2), 6429873667)
  expect_equal(round(ge$award_total_usd, 2), 5178076351.93, tolerance = 1e-12)
  expect_equal(round(ge$hospital_summary_usd, 2), 2133741090.93, tolerance = 1e-12)
  expect_equal(round(ge$strict_named_hospital_usd, 2), 1916528872.09, tolerance = 1e-12)
  expect_equal(ge$hospital_share_of_awards_pct, 41.2)
  expect_equal(ge$hospital_share_of_allotment_pct, 33.2)
  # a subset of the national row, never more
  for (col in c("allotment_usd", "award_total_usd", "hospital_summary_usd", "strict_named_hospital_usd")) {
    expect_true(ge[[col]] <= us[[col]], info = col)
  }
  # Overview shows its six figures and leaves the rest blank
  g <- ov[52, ]
  expect_equal(g[["FY2026 allotment"]], ge$allotment_usd)
  expect_equal(g[["Awards published"]], ge$award_total_usd)
  expect_equal(g[["Hospital $ (best estimate)"]], ge$hospital_summary_usd)
  expect_equal(round(100 * as.numeric(g[["Hospital % of awards"]]), 1), 41.2)
  expect_equal(round(100 * g[["Hospital % of allotment"]], 1), 33.2)
  expect_equal(g[["Strict named-hospital $"]], ge$strict_named_hospital_usd)
  expect_true(is.na(g[["% of allotment awarded"]]))
  expect_true(is.na(g[["Hospitals named, no amount"]]))
  # Session 116d (owner ruling b): the national row prints its share.
  expect_false(ov[["Hospital % of awards"]][51] == "n/m")
  dt <- openxlsx::read.xlsx(ov_x, "Detail")
  expect_equal(dt$state[52], "US_GE50")
  expect_equal(round(100 * as.numeric(dt$hospital_share_of_awards_pct[52]), 1), 41.2)
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
  expect_true(any(grepl("The same test applies to the national row", n, fixed = TRUE)))
  expect_true(any(grepl("FSRS / FFATA SUBAWARDS", n, fixed = TRUE) & grepl("19 states had filed no FFATA subaward", n, fixed = TRUE) &
                    grepl("procurement contracts", n, fixed = TRUE)))
  expect_true(any(grepl("rests on state award sources only", n, fixed = TRUE) &
                    grepl("computed on its state-sourced awards alone", n, fixed = TRUE) &
                    grepl("Rhode Island 24.2% state-sourced (74.6% with CMS lines; does not qualify)", n, fixed = TRUE)))
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

test_that("session 114: the Notes INTENTS line lists the states from the data", {
  line <- ys_notes(s, "2026-11-09", rows)$note
  line <- line[startsWith(line, "INTENTS ARE NOT EXECUTED AWARDS.")]
  expect_length(line, 1L)
  k <- st_only[st_only$layer_intent_usd > 0, ]
  expect_true(all(vapply(k$state_name, function(n) grepl(n, line, fixed = TRUE), TRUE)))
  expect_match(line, paste0("; ", nrow(k), " states\\)"))
  expect_true(grepl("Missouri", line, fixed = TRUE))
  # Largest first.
  pos <- vapply(k$state_name[order(-k$layer_intent_usd)], function(n) regexpr(n, line, fixed = TRUE), 1L)
  expect_false(is.unsorted(pos))
  expect_false(grepl("and others", line, fixed = TRUE))
})
