# test_year2_safeguards.R ------------------------------------------------------
# Session 116 (owner ruling: the Year 2 hold is lifted for SAFEGUARDS only; no
# Year 2 extraction). (a) budget_period on every award file and status table,
# Year 1 figures filter on it; (b) an empty FY2027 allotment table and the
# state-reported Year 2 signals; (c) probes: Year 2 language never trips as a
# Year 1 award, a Year 2 roster logs YEAR2 and is held; (d) the CMS monitor logs
# a national Year 2 release as one event and cannot block its own commit on
# volume.

library(testthat)
suppressMessages({
  source(here::here("R", "utils_config.R"))
  source(here::here("R", "utils_page_watch.R"))
  source(here::here("R", "utils_recipient_classification.R"))
})

state_files <- function() {
  tf <- readLines(here::here("tests/testthat/test_state_union.R"))
  i0 <- grep("^STATE_FILES <- c\\(", tf)
  i1 <- i0 + which(grepl("^\\)", tf[(i0 + 1):length(tf)]))[1]
  eval(parse(text = tf[i0:i1]))
  STATE_FILES
}

# -- (a) budget_period ----------------------------------------------------------

test_that("every award file and status table is registered and carries an integer budget_period", {
  reg <- rhtp_budget_period_registry()
  sf <- unname(state_files())
  status <- file.path("data", "reference",
                      list.files(here::here("data", "reference"), "_status\\.csv$"))
  expect_setequal(reg$file, c(sf, status))
  expect_true(all(reg$budget_period == 1L))   # every existing row is Year 1
  for (i in seq_len(nrow(reg))) {
    d <- readr::read_csv(here::here(reg$file[i]), col_types = readr::cols(.default = "c"),
                         progress = FALSE)
    expect_true("budget_period" %in% names(d), info = reg$file[i])
    expect_true(all(d$budget_period == as.character(reg$budget_period[i])),
                info = paste(reg$file[i], "has a row without its budget_period"))
  }
})

test_that("Year 1 readers refuse a table without budget_period and keep only period 1", {
  d <- tibble::tibble(amount = c(1, 2, 4), budget_period = c("1", "1", "2"))
  expect_equal(sum(rhtp_year1_only(d, "fixture")$amount), 3)
  expect_error(rhtp_year1_only(d[, "amount"], "fixture"), "no budget_period")
  expect_error(rhtp_year1_only(tibble::tibble(amount = 1, budget_period = "BP1"), "fixture"),
               "no integer")
  # The partition drops a period-2 row and a builder's unstamped Year 2 text.
  rec <- tibble::tibble(amount = c(100, 50, 25), distributed_to_hospital = "Yes",
                        flow_type = "DIRECT", recipient_type = "HOSPITAL_OR_SYSTEM",
                        hospital_attribution = "NAMED_HOSPITAL",
                        budget_period = c("1", "2", "Budget Period 2"))
  p <- rhtp_hospital_dollar_partition(rec)
  expect_equal(p$dollars[p$bucket == "NAMED_HOSPITAL"], 100)
})

test_that("the stamp refuses a Year 2 builder text in a file registered 1", {
  f <- tempfile(fileext = ".csv")
  readr::write_csv(tibble::tibble(a = 1, budget_period = "Budget Period 2"), f)
  expect_error(rhtp_budget_period_stamp(f, 1L), "later-period")
})

# -- (b) FY2027 allotments and Year 2 signals -------------------------------------

test_that("cms_fy2027_allotments.csv is empty, FY2026-shaped, and its loader holds", {
  a <- rhtp_load_fy2027_allotments()
  expect_equal(nrow(a), 0L)
  f26 <- names(readr::read_csv(here::here("data/reference/cms_fy2026_allotments.csv"),
                               n_max = 0, show_col_types = FALSE))
  expect_equal(sub("fy2027", "fy2026", RHTP_FY2027_COLUMNS), f26)
  # FY2026 is never edited for Year 2.
  expect_equal(digest::digest(file = here::here("data/reference/cms_fy2026_allotments.csv"),
                              algo = "sha256"),
               "8cb3948aeadea68e7480ebc6cec8e55c24d3cca19d81409817baa92d53b6bbfc")
  # A copied FY2026 table, or a state-sourced row, is refused.
  f26d <- readr::read_csv(here::here("data/reference/cms_fy2026_allotments.csv"),
                          show_col_types = FALSE)
  tmp <- tempfile(fileext = ".csv")
  readr::write_csv(tibble::tibble(state = f26d$state, state_name = f26d$state_name,
                                  fy2027_allotment = f26d$fy2026_allotment,
                                  fy2027_allotment_published = "x",
                                  source_url = "https://www.cms.gov/x", source_fetched = "2026-11-09"), tmp)
  expect_error(rhtp_load_fy2027_allotments(tmp), "copied")
  readr::write_csv(tibble::tibble(state = "LA", state_name = "Louisiana",
                                  fy2027_allotment = 1e8, fy2027_allotment_published = "$100 million",
                                  source_url = "https://ldh.la.gov/x", source_fetched = "2026-11-09"), tmp)
  expect_error(rhtp_load_fy2027_allotments(tmp), "all 50 states")
})

test_that("every Year 2 signal is quoted from its archive and enters no total", {
  s <- readr::read_csv(here::here("data/reference/year2_signals.csv"), show_col_types = FALSE)
  expect_true(all(s$enters_total == "No"))
  expect_false(any(c("amount", "hospital_attribution") %in% names(s)))
  for (i in seq_len(nrow(s))) {
    p <- here::here(s$source_archive_path[i])
    expect_true(file.exists(p), info = s$signal_id[i])
    txt <- if (grepl("\\.pdf$", p)) {
      if (!exists("rhtp_pdf_text")) source(here::here("R", "utils_pdf_text.R"))
      paste(rhtp_pdf_text(p), collapse = " ")
    } else rhtp_watch_reduce(p)
    sq <- function(x) gsub("[\\s’']+", "", x, perl = TRUE)
    # The project PDF reader drops the "A" of "Award" on LA's slide; compare the
    # quote's tail there.
    q <- if (s$signal_id[i] == "LA_DECK_BP2_NOA") "for $100 million to cover state" else s$quote[i]
    expect_true(grepl(sq(q), sq(txt), fixed = TRUE), info = s$signal_id[i])
  }
  # The three footer signals are each the allotment plus exactly $100M.
  ft <- s[s$source_type == "FOOTER", ]
  for (i in seq_len(nrow(ft))) {
    expect_equal(rhtp_footer_class(as.numeric(gsub("[$,]", "", ft$figure_text[i])), ft$state[i]),
                 "ALLOTMENT_PLUS_YEAR2_INITIAL", info = ft$signal_id[i])
  }
})

# -- (c) probes ------------------------------------------------------------------

# Kansas's KDHE page as rendered 2026-10-07 (recheck/2026-10-07/KS/), and
# Iowa's 2026-08-27 Council deck line on its Year 2 award window.
KS_Y2 <- paste(
  "Year 2 Regional Partnership Grant Program Funding amount is pending CMS approval",
  "of the Year 2 Budget. Year 2 Request for Application Year 2 RPGP Application",
  "Instructions Year 2 RPGP Application Portal Year 2 Transformative Capital",
  "Investment Grant Program Funding amount is pending CMS approval of the Year 2",
  "Budget. Kansas Rural Health Transformation Plan Year 2 Budget Under Review.")
IA_Y2 <- paste(
  "Year 2: Award Announcement for most procurements listed above between October 15",
  "- November 20, 2026, pending CMS approval of the Year 2 budget.")
AWARD_RX <- c("\\baward(ed|s)?\\b", "\\bawardees?\\b", "\\bintent to award\\b",
              "\\brecipients?\\b")

test_that("Kansas's Year 2 solicitations and Iowa's Year 2 window never trip as Year 1 awards", {
  base <- "The Kansas Department of Health and Environment administers the programme."
  # The phrase list: no Year 1 TRIPWIRE. (Iowa's window says "Award".)
  expect_true(rhtp_watch_forbid(paste(base, KS_Y2), AWARD_RX, "KS", "fixture"))
  expect_error(rhtp_watch_forbid(paste(base, IA_Y2), AWARD_RX, "IA", "fixture"),
               RHTP_YEAR2_SIGNATURE, fixed = TRUE)
  msg <- tryCatch(rhtp_watch_forbid(paste(base, IA_Y2), AWARD_RX, "IA", "fixture"),
                  error = conditionMessage)
  expect_equal(rhtp_probe_verdict(msg), "YEAR2")
  # The sentence diff: new Year 2 sentences are YEAR2, never TRIPWIRE.
  msg <- tryCatch(rhtp_watch_forbid_new(paste(base, KS_Y2), base, "(?i)grant|application",
                                        "KS", "fixture", "why"), error = conditionMessage)
  expect_equal(rhtp_probe_verdict(msg), "YEAR2")
  # The same award language outside a Year 2 sentence is still a Year 1 TRIPWIRE.
  y1 <- "The Regional Partnership Grant Program awardees are Hays Medical Center and Salina Regional Health Center."
  msg <- tryCatch(rhtp_watch_forbid(paste(base, y1), AWARD_RX, "KS", "fixture"),
                  error = conditionMessage)
  expect_equal(rhtp_probe_verdict(msg), "TRIPWIRE")
})

test_that("a Year 2 roster trips as YEAR2 and is held; a Year 1 roster still trips", {
  arch <- paste("Kansas Department of Health and Environment.",
                "Hays Medical Center. Salina Regional Health Center. Wichita State University.")
  y2 <- paste(arch, "Year 2 Regional Partnership Grant Program awardees:",
              "Newton Medical Center, Citizens Medical Center and Pratt Regional Medical Center.")
  msg <- tryCatch(rhtp_assert_no_new_organisations(y2, arch, "KS", "fixture"),
                  error = conditionMessage)
  expect_equal(rhtp_probe_verdict(msg), "YEAR2")
  y1 <- paste(arch, "The 2026 awardees include Newton Medical Center.")
  msg <- tryCatch(rhtp_assert_no_new_organisations(y1, arch, "KS", "fixture"),
                  error = conditionMessage)
  expect_equal(rhtp_probe_verdict(msg), "TRIPWIRE")
  # Inside rhtp_probe_run(): one YEAR2 row, and the run is NOT thrown (held).
  log <- tempfile(fileext = ".csv")
  ev <- tempfile(); dir.create(ev)
  res <- rhtp_probe_run("KS", {
    rhtp_assert_no_new_organisations(y2, arch, "KS", "programme")
    list(rows = tibble::tibble(verdict = "CHANGED", page = "programme"))
  }, path = log, evidence_root = ev)
  got <- readr::read_csv(log, show_col_types = FALSE)
  expect_true("YEAR2" %in% got$verdict)
  expect_false("TRIPWIRE" %in% got$verdict)
  expect_true(all(got$verdict %in% RHTP_PROBE_VERDICTS))
})

# -- (d) the CMS monitor ---------------------------------------------------------

test_that("a national Year 2 release is ONE national event and ONE YEAR2 row", {
  suppressMessages(source(here::here("R", "00_cms_press_monitor.R")))
  nat <- tibble::tibble(
    date = as.Date("2026-11-20"),
    title = "CMS Announces Year 2 Rural Health Transformation Program Awards to All 50 States",
    url = "https://www.cms.gov/newsroom/press-releases/fixture-year-2", source = "CMS_NEWSROOM",
    first_seen = "2026-11-20")
  ev <- rhtp_cms_national_events(dplyr::bind_rows(nat, nat))
  expect_equal(nrow(ev), 1L)
  expect_equal(ev$event_type, "YEAR2_NATIONAL")
  p <- tempfile(fileext = ".csv")
  new <- rhtp_cms_national_events_write(ev, p)
  expect_equal(nrow(new), 1L)
  expect_equal(nrow(rhtp_cms_national_events_write(ev, p)), 0L)  # second run: not new
  res <- list(delta = list(new_states = character(0), new_rows = tibble::tibble(),
                           changed_rows = tibble::tibble(), national_new = new))
  v <- rhtp_cms_press_verdict(res)
  expect_equal(sum(v$verdict == "YEAR2"), 1L)
  expect_true(all(v$verdict %in% RHTP_PROBE_VERDICTS))
  # A multi-state Year 2 headline is national, not refused.
  expect_true(is.na(cms_newsroom_state("Year 2 Awards for Virginia and Kansas")))
  expect_error(cms_newsroom_state("Awards for Ohio and Kansas"), "more than one state")
  # The committed events file carries the 2025-12-29 all-50-states award as NATIONAL.
  committed <- readr::read_csv(here::here(CMS_NATIONAL_EVENTS_CSV), show_col_types = FALSE)
  expect_true(any(grepl("All 50 States", committed$title)))
  expect_true(all(committed$event_type %in% c("NATIONAL", "YEAR2_NATIONAL")))
})

test_that("a Year 2 wave of state releases cannot block the monitor's commit on volume", {
  suppressMessages(source(here::here("R", "00_cms_press_monitor.R")))
  st <- rhtp_cms_states()$state
  y1 <- tibble::tibble(state = st, date = as.Date("2026-09-01"), amount = 1.9e8,
                       title = paste("Year 1", st), source = "CMS_NEWSROOM")
  wave <- tibble::tibble(state = st, date = as.Date("2026-11-05"), amount = 1.9e8,
                         title = paste("Year 2", st), source = "CMS_NEWSROOM")
  expect_true(rhtp_cms_press_assert(dplyr::bind_rows(y1, wave)))   # $19B over two periods
  expect_error(rhtp_cms_press_assert(dplyr::bind_rows(y1, y1 %>% dplyr::mutate(title = paste(title, "x")))),
               "more than the entire")                               # $19B in Year 1 alone
})
