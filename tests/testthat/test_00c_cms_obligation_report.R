# test_00c_cms_obligation_report.R -------------------------------------------
# CMS's RHTP Obligated Funds Report (session 97): the parse reproduces the
# committed tables, the source defects stay logged rather than fixed, and no
# obligation figure reaches an award file or a hospital bucket.

source(here::here("R", "00c_cms_obligation_report.R"))
source(here::here("R", "00d_cms_obligation_analysis.R"))

ref <- function(f) readr::read_csv(here::here("data", "reference", f),
                                   show_col_types = FALSE, progress = FALSE)

test_that("the archive is the public medicaid.gov copy, byte for byte", {
  expect_silent(obl_assert_archive())
  man <- readLines(here::here(OBL_DIR, "RHTP-Obligated-Funds-10082026.pdf.manifest.txt"))
  expect_true(any(grepl(OBL_SHA256, man, fixed = TRUE)))
  expect_true(any(grepl("IDENTICAL", man, fixed = TRUE)))
  expect_false(file.exists(here::here("RHTP-Obligated-Funds-10082026.pdf")))
})

test_that("a fresh parse reproduces the committed state and line tables", {
  p <- obl_parse()
  expect_silent(obl_assert(p))
  st <- obl_state_table(p)
  committed <- ref("cms_obligations_bp1_state.csv")
  expect_equal(st$state, committed$state)
  expect_equal(st$bp1_award, committed$bp1_award)
  expect_equal(st$funds_put_to_work, committed$funds_put_to_work)
  ln <- obl_lines_table(p)
  cl <- ref("cms_obligations_bp1_lines.csv")
  expect_equal(ln$line_id, cl$line_id)
  expect_equal(ln$amount, cl$amount)
  expect_equal(ln$named_orgs, cl$named_orgs)
})

test_that("50 states, 14 wrapped headers, SD's bare dollar, $9,995,000,000 of BP1", {
  st <- ref("cms_obligations_bp1_state.csv")
  expect_equal(nrow(st), 50L)
  expect_setequal(st$state[st$header_wrapped], OBL_WRAPPED)
  expect_equal(st$state[st$header_bare_dollar], "SD")
  expect_equal(round(sum(st$bp1_award), 2), 9995000000)
  expect_true(all(st$as_of == as.Date("2026-07-31")))
  expect_true(all(st$report_date == as.Date("2026-10-08")))
  expect_true(all(st$budget_period == 1L))
})

test_that("the FY2026 table is untouched and BP1 differs only in Oregon beyond rounding", {
  al <- ref("cms_fy2026_allotments.csv")
  expect_false("bp1_award" %in% names(al))
  expect_equal(sum(al$fy2026_allotment), 10000000003)
  rc <- ref("cms_obligations_bp1_allotment_reconciliation.csv")
  expect_equal(rc$state[!rc$rounds_to_fy2026], "OR")
  expect_equal(rc$diff_bp1_minus_fy2026[rc$state == "OR"], -5000000.33)
})

test_that("Hawaii's bullets are unusable and its category totals stand", {
  ln <- ref("cms_obligations_bp1_lines.csv")
  hi <- ln[ln$state == "HI", ]
  expect_true(all(!hi$amount_usable))
  expect_true(all(OBL_HI_REPEATED %in% hi$amount))
  expect_true(all(ln$amount_usable[ln$state != "HI"]))
})

test_that("reconciliation failures are LOGGED, and known source defects are among them", {
  ck <- ref("cms_obligations_bp1_checks.csv")
  expect_true(all(ck$status %in% c("EXACT", "ROUNDING", "FAIL")))
  fails <- ck[ck$status == "FAIL", ]
  expect_true(any(fails$state == "MT" & fails$check == "INITIATIVES_TO_STATE_TOTAL"))
  expect_true(any(fails$state == "CT" & fails$name == "Program Operations"))
  # Iowa's two-items-in-one bullet is split, so its category reconciles.
  iac <- ck[ck$state == "IA" & ck$name == "Appropriate Care Availability", ]
  expect_true(all(iac$status == "EXACT"))
})

test_that("ligature repair touches description_clean only, never a real capital W", {
  expect_equal(obl_clean_text("EWiciency staW oWice JeWerson eWorts"),
               "Efficiency staff office Jefferson efforts")
  expect_equal(obl_clean_text("CHW RDW NEW IOWA GROW WWAMI PoWER"),
               "CHW RDW NEW IOWA GROW WWAMI PoWER")
  ln <- ref("cms_obligations_bp1_lines.csv")
  expect_true(any(grepl("staW", ln$description_raw)))
  expect_false(any(grepl("\\bstaW\\b", ln$description_clean)))
})

test_that("tier is SUBAWARD only where a recipient is named, SOLICITATION otherwise", {
  ln <- ref("cms_obligations_bp1_lines.csv")
  expect_true(all(ln$tier %in% c("SUBAWARD", "SOLICITATION")))
  expect_equal(ln$tier == "SUBAWARD", !is.na(ln$named_orgs))
  expect_true(all(OBL_NAME_VERDICTS$line_id %in% ln$line_id))
})

test_that("no obligation table is an award file, and the layers never carry a bucket", {
  src <- readLines(here::here("tests", "testthat", "test_state_union.R"))
  # Session 98: the owner ruled on named lines, and R/03cb writes THOSE as award
  # files. They are the only "cms_obligation" paths allowed in STATE_FILES; the
  # report's own tables (lines, matches, leads, decision lists) never are.
  refs <- unlist(stringr::str_extract_all(src, "data/reference/[a-z0-9_]+\\.csv"))
  obl <- unique(refs[grepl("cms_obligation", refs)])
  # Session 112: PA_CMS left STATE_FILES (Guthrie is on PA's own Selected
  # Projects list; pa_cms_obligation_awardees.csv is header-only), so NE's is
  # the only obligation file left in it.
  expect_setequal(obl, "data/reference/ne_cms_obligation_awardees.csv")
  expect_false(any(grepl("cms_obligations?_(bp1|name|hospital|gap)", src)))
  pur <- ref("cms_obligation_hospital_purpose.csv")
  expect_true(all(pur$layer == "LEAD_ONLY_NEVER_IN_A_BUCKET"))
  for (f in c("cms_obligations_bp1_lines.csv", "cms_obligation_name_matches.csv",
              "cms_obligation_hospital_purpose.csv", "cms_obligation_hospital_decision_lists.csv")) {
    x <- ref(f)
    expect_false(any(c("hospital_attribution", "distributed_to_hospital") %in% names(x)), info = f)
  }
})

test_that("the gap table ranks on obligation minus published Tier 3 and says it is a ranking", {
  g <- ref("cms_obligation_gap_by_state.csv")
  expect_equal(nrow(g), 50L)
  expect_equal(g$hunt_rank, seq_len(50))
  expect_true(all(diff(g$gap_cms_obligated_minus_ours) <= 0))
  expect_true(all(grepl("never a dollar finding", g$comparability)))
})

test_that("the CMS monitor flags a new obligation report and a missed refresh", {
  source(here::here("R", "00_cms_press_monitor.R"))
  held <- tibble::tibble(name = "RHTP-Obligated-Funds-10082026.pdf", path = NA_character_, bytes = 1065285)
  expect_equal(rhtp_cms_obligation_verdict("RHTP-Obligated-Funds-10082026.pdf",
                                           as.Date("2026-11-01"), archived = held)$verdict, "UNCHANGED")
  late <- rhtp_cms_obligation_verdict("RHTP-Obligated-Funds-10082026.pdf", as.Date("2026-12-08"),
                                      archived = held)
  expect_match(late$note, "No refreshed obligation report")
  expect_equal(rhtp_cms_obligation_verdict(c("RHTP-Obligated-Funds-10082026.pdf",
                                             "RHTP-Obligated-Funds-12152026.pdf"),
                                           archived = held,
                                           first_linked = function(n) NA_character_)$verdict, "CHANGED")
})

# SESSION 113 FIXTURE: the 10-14 edition. Two trimmed copies of the committed
# resources-page archives (10-16, still linking 10082026; 10-26, linking
# 20261014 in the SAME media entity) are the input; the archive table is
# what this repository held before session 113 archived the new edition.
test_that("session 113: the 10-14 edition is flagged from the page that first links it, until archived", {
  source(here::here("R", "00_cms_press_monitor.R"))
  fx <- here::here("tests", "testthat", "fixtures", "cms_obligation_watch")
  p16 <- file.path(fx, "2026-10-16", "medicaid_rhtp_resources.html")
  p26 <- file.path(fx, "2026-10-26", "medicaid_rhtp_resources.html")
  expect_equal(rhtp_cms_obligation_links(p16), "RHTP-Obligated-Funds-10082026.pdf")
  expect_equal(rhtp_cms_obligation_links(p26), "RHTP-Obligated-Funds-20261014.pdf")
  # Both fixture links carry the one media entity: CMS swapped the file in place.
  uuid <- function(p) stringr::str_match(readLines(p, warn = FALSE), "data-entity-uuid=\"([^\"]+)\"")[, 2]
  expect_identical(uuid(p16), uuid(p26))

  held_s112 <- tibble::tibble(name = "RHTP-Obligated-Funds-10082026.pdf", path = NA_character_,
                              bytes = 1065285)
  fl <- function(n) rhtp_cms_obligation_first_linked(n, root = fx)
  expect_identical(fl("RHTP-Obligated-Funds-20261014.pdf"), "2026-10-26")

  # 10-16: nothing new linked.
  v16 <- rhtp_cms_obligation_verdict(rhtp_cms_obligation_links(p16), as.Date("2026-10-16"),
                                     archived = held_s112, first_linked = fl)
  expect_equal(v16$verdict, "UNCHANGED")
  # 11-02 (the third CHANGED run): fires, says NOT YET ARCHIVED, and dates itself.
  v1102 <- rhtp_cms_obligation_verdict(rhtp_cms_obligation_links(p26), as.Date("2026-11-02"),
                                       archived = held_s112, first_linked = fl)
  expect_equal(v1102$verdict, "CHANGED")
  expect_match(v1102$note, "NOT YET ARCHIVED: RHTP-Obligated-Funds-20261014.pdf")
  expect_match(v1102$note, "linked since the archived page of 2026-10-26 \\(7 days\\)")
  # Once archived (this session), the same page is quiet.
  held_s113 <- dplyr::bind_rows(held_s112, tibble::tibble(
    name = "RHTP-Obligated-Funds-20261014.pdf", path = NA_character_, bytes = 1035227))
  heads_ok <- tibble::tibble(name = "RHTP-Obligated-Funds-20261014.pdf", status = 200L,
                             bytes = 1035227, last_modified = "Mon, 19 Oct 2026 23:33:11 GMT")
  expect_equal(rhtp_cms_obligation_verdict(rhtp_cms_obligation_links(p26), as.Date("2026-11-05"),
                                           archived = held_s113, heads = heads_ok,
                                           first_linked = fl)$verdict, "UNCHANGED")
  # The repository's real archive now holds it.
  expect_true("RHTP-Obligated-Funds-20261014.pdf" %in% rhtp_cms_obligation_archived()$name)
})

test_that("session 113: a same-name re-post, an unreadable HEAD and an empty link list are not UNCHANGED", {
  source(here::here("R", "00_cms_press_monitor.R"))
  held <- tibble::tibble(name = "RHTP-Obligated-Funds-20261014.pdf", path = NA_character_, bytes = 1035227)
  lk <- "RHTP-Obligated-Funds-20261014.pdf"
  repost <- tibble::tibble(name = lk, status = 200L, bytes = 1040000,
                           last_modified = "Mon, 07 Dec 2026 20:00:00 GMT")
  v <- rhtp_cms_obligation_verdict(lk, as.Date("2026-12-08"), archived = held, heads = repost)
  expect_equal(v$verdict, "CHANGED")
  expect_match(v$note, "SAME-NAME RE-POST")
  blocked <- tibble::tibble(name = lk, status = 403L, bytes = NA_real_, last_modified = NA_character_)
  vb <- rhtp_cms_obligation_verdict(lk, archived = held, heads = blocked)
  expect_equal(vb$verdict, "ERROR")
  expect_match(vb$note, "could not be compared")
  none <- rhtp_cms_obligation_verdict(character(0), archived = held)
  expect_equal(none$verdict, "CHANGED")
  expect_match(none$note, "links NO obligation report")
})
