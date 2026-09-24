# test_03ae_la_year1_probe.R ---------------------------------------------------
# LOUISIANA -- a negative for six solicitations, and since session 64 an
# EXTRACTION for the seventh: the Rural Clinician Credit Bank, 53 awards /
# $12,701,996 as of 8/28/26, five of them named. Reads committed artifacts
# only: no network, no quota.
#
#   0. (session 64) THE RCCB FILE OVERSTATES HOSPITALS. LDH names five
#      awardees and none as a hospital; 20 of 53 awards are "hospital
#      settings" and LDH names none of them. The tests below drive the three
#      ways a hospital dollar could creep in -- a name rule typing
#      "Outpatient Medical Center" a hospital, a hospital-only aggregate that
#      overlaps the named rows, and a round total written into `amount` --
#      and require each to be refused.
#
# WHAT THIS FILE IS DEFENDING, IN ORDER OF HOW BADLY IT WOULD HURT.
#
#   1. THE TRIPWIRES STOP FIRING. Louisiana has SEVEN solicitations whose own
#      published announcement windows have passed, so it is the state in this
#      repository most likely to acquire a roster between sessions. Every
#      award phrase is fed to every watched surface and required to THROW.
#
#   2. THE TIER DEFECT STOPS BEING PROVABLE. All six RCJ candidates are rows
#      of slide 18's table, and the case rests on three things being true at
#      once: the names match the ACTIVITY column, the amounts match the
#      PROJECTED column to the dollar, and the heading says "Projected". If
#      any of those goes, the disposition is an assertion rather than a
#      finding.
#
#   3. THE DROPPED ROW IS FORGOTTEN. RCJ misses Capital Improvement -- the
#      largest row, and the one likeliest to reach a hospital. That is the
#      only reason its $53,910,000 is not the deck's $95,510,000.

library(testthat)

source(here::here("R", "03ae_la_year1_probe.R"))

la_prog  <- la_html_text("programme")
la_fund  <- la_html_text("funding")
la_news  <- la_html_text("news")
la_cat   <- la_html_text("catalyst")
la_deck  <- la_pdf_text("council")
la_cap   <- la_pdf_text("capital_nofo")
la_cyc   <- la_deck_funding_cycle(la_deck)
la_all   <- la_rcj_candidates()
# The slide-18 subset: since the 2026-09-24 pull, six further candidates come
# from other documents and are disposed of separately (session 63).
la_cands <- la_deck_candidates(la_all)


# -- the archive -------------------------------------------------------------

test_that("every archived file verifies against its own manifest digest", {
  man <- readLines(file.path(LA_EVIDENCE_DIR, "MANIFEST.txt"), warn = FALSE)
  rows <- man[stringr::str_detect(man, "^[0-9]{4}-[0-9]{2}-[0-9]{2}_la_.*  [0-9]+  [0-9a-f]{64}$")]
  expect_equal(length(rows), nrow(LA_SOURCES))
  for (r in rows) {
    parts <- stringr::str_split(r, "  ")[[1]]
    p <- file.path(LA_EVIDENCE_DIR, parts[1])
    expect_true(file.exists(p), info = parts[1])
    expect_equal(digest::digest(file = p, algo = "sha256"), parts[3],
                 info = parts[1])
  }
})

test_that("the manifest does not list itself", {
  man <- readLines(file.path(LA_EVIDENCE_DIR, "MANIFEST.txt"), warn = FALSE)
  expect_false(any(stringr::str_detect(man, "MANIFEST\\.txt  [0-9]+  [0-9a-f]{64}")))
})


# -- the user agent, which is session 10's rule and NOT session 27's exception

test_that("the agent identifies this project and a contact URL", {
  expect_match(LA_USER_AGENT, "AHA-RHTP-Tracker", fixed = TRUE)
  expect_match(LA_USER_AGENT, "+https://www.aha.org", fixed = TRUE)
  # The Mozilla prefix is what ldh.la.gov additionally wants.
  expect_match(LA_USER_AGENT, "^Mozilla/5\\.0 \\(compatible;")
})

test_that("an anonymous agent is refused, on any host", {
  # Michigan's lesson as code: a one-host allowance becomes a default the
  # moment nothing refuses it. Bare Mozilla is 403 here in any case.
  expect_error(la_agent_for("https://ldh.la.gov/", "Mozilla/5.0"),
               "does not identify this project")
  expect_error(la_agent_for("https://example.gov/", "Mozilla/5.0"),
               "does not identify this project")
  expect_error(
    la_agent_for("https://ldh.la.gov/",
                 "Mozilla/5.0 (compatible; SomeoneElse/1.0; +https://x.test)"),
    "does not identify this project")
  expect_equal(la_agent_for("https://ldh.la.gov/"), LA_USER_AGENT)
})


# -- SEVEN WINDOWS, AND LDH SLIPPED EVERY ONE ---------------------------------

test_that("LDH publishes an announcement window for each of seven opportunities", {
  # THE INVARIANT, and the only one this control should ever have protected:
  # every Budget Year 1 solicitation carries an announcement date LDH
  # published itself, and the seven match the funding page's seven headings.
  w <- la_parse_windows(la_prog)
  expect_equal(nrow(w), LA_STATED$opportunities)
  expect_equal(
    stringr::str_count(la_fund, stringr::fixed("Strategic Funding Opportunity Title")),
    LA_STATED$opportunities)
  expect_true(all(grepl("^Closed$", w$application, ignore.case = TRUE)))
  expect_true(is.data.frame(la_assert_windows_published(la_prog, la_fund)))
})

test_that("THE WINDOWS AS PUBLISHED TODAY: 6 x End of September, 1 x Mid-September", {
  # Session 36 pinned two literal phrases and their counts. LDH re-dated the
  # block, so the assertion found 0 and 0 and HALTED the Routine -- correctly,
  # and on a constant that was not wrong when it was written. What the page
  # says now is read here instead of asserted from memory.
  w <- la_parse_windows(la_prog)
  expect_equal(sum(w$window == "End of September"), 6L)
  expect_equal(sum(w$window == "Mid-September"), 1L)
  expect_equal(sum(w$window_ends == as.Date("2026-09-30")), 6L)
  expect_equal(sum(w$window_ends == as.Date("2026-09-15")), 1L)
})

test_that("which windows have PASSED is derived, never asserted", {
  # The previous version asserted that ALL SEVEN had passed. That was true
  # when written and is now false: on 2026-09-21 exactly one has. A claim
  # about a state read off a constant rather than off the state's page (§0.4).
  w <- la_assert_windows_published(la_prog, la_fund,
                                   asof = as.Date("2026-09-21"))
  expect_equal(sum(w$passed), 1L)
  expect_equal(w$programme[w$passed],
               "Rural Health Transformation Program (RHTP) Rural Clinician Credit Bank Program")
  # And it moves with the date rather than with an edit.
  expect_equal(sum(la_assert_windows_published(la_prog, la_fund,
                                               asof = as.Date("2026-10-01"))$passed),
               7L)
  expect_equal(sum(la_assert_windows_published(la_prog, la_fund,
                                               asof = as.Date("2026-09-01"))$passed),
               0L)
})

test_that("every window form LDH has used dates correctly", {
  # The four forms across both snapshots. Take the LAST qualifier and the LAST
  # month: "Late July to mid August" ends mid-AUGUST, not late July.
  expect_equal(la_window_deadline("Late July to mid August"), as.Date("2026-08-15"))
  expect_equal(la_window_deadline("Mid to late August"),      as.Date("2026-08-31"))
  expect_equal(la_window_deadline("End of September"),        as.Date("2026-09-30"))
  expect_equal(la_window_deadline("Mid-September"),           as.Date("2026-09-15"))
})

test_that("a window this file cannot date is REFUSED, not guessed at", {
  # §0.4: an unparsed date silently treated as absent is how a slipped
  # deadline reads as an award.
  expect_error(la_window_deadline("soon"), "cannot date the announcement window")
})

test_that("THE SLIP IS MEASURED FROM TWO COMMITTED ARCHIVES", {
  # Not a session note: the 2026-09-02 snapshot carries the July/August
  # windows and the 2026-09-21 one carries the September windows, and both are
  # in data/evidence/LA/. That is why the superseded file is kept.
  sl <- la_assert_windows_slipped()
  expect_equal(nrow(sl), 7L)
  expect_true(all(sl$slipped_days > 0L))
  expect_equal(range(sl$slipped_days), c(30L, 46L))
  expect_true(all(sl$was %in% c("Late July to mid August", "Mid to late August")))
})

test_that("a window moving EARLIER, or not at all, fails rather than passing", {
  expect_error(la_assert_windows_slipped(programme = la_prog, prior = la_prog),
               "identical windows")
})

test_that("a solicitation re-opening is a different finding and fails", {
  reopened <- stringr::str_replace(
    la_prog, "Application Submission Deadline for Year 1 Funds: Closed",
    "Application Submission Deadline for Year 1 Funds: Open")
  expect_error(la_assert_windows_published(reopened, la_fund),
               "no longer read 'Closed'")
})

test_that("a window LDH cannot be dated from is REFUSED, not dropped", {
  # LDH replacing a date with "TBD" is the shape that matters: dropping that
  # row would shrink the seven silently, and seven-against-seven is the whole
  # closure. It fails at the PARSE rather than at the count, which is earlier
  # and therefore better -- the row never reaches a table.
  dropped <- stringr::str_replace(
    la_prog,
    stringr::fixed("Notice of Intent to Contract Announcements: Mid-September"),
    "Notice of Intent to Contract Announcements: TBD")
  expect_error(la_assert_windows_published(dropped, la_fund),
               "could be parsed")
})

test_that("the seven windows must match the seven solicitations", {
  # The other direction: the funding page losing a heading.
  fewer <- stringr::str_replace(
    la_fund, stringr::fixed("Strategic Funding Opportunity Title"), "Removed")
  expect_error(la_assert_windows_published(la_prog, fewer),
               "announcement windows against")
})


# -- THE TRIPWIRE ------------------------------------------------------------

test_that("the award tripwire passes on the committed archive", {
  expect_true(la_assert_no_award_roster(la_prog, la_fund, la_deck))
})

test_that("EVERY award phrase fires on EVERY watched surface", {
  for (phrase in LA_AWARD_POSTED) {
    expect_error(
      la_assert_no_award_roster(paste(la_prog, phrase), la_fund, la_deck),
      "award language has appeared on the programme", info = phrase)
    expect_error(
      la_assert_no_award_roster(la_prog, paste(la_fund, phrase), la_deck),
      "award language has appeared on the funding", info = phrase)
    expect_error(
      la_assert_no_award_roster(la_prog, la_fund, paste(la_deck, phrase)),
      "award language has appeared on the council", info = phrase)
  }
})

test_that("no watched surface already carries an award phrase", {
  # The reason the tripwire is not self-firing, measured rather than assumed.
  for (t in list(la_prog, la_fund, la_deck)) {
    for (phrase in LA_AWARD_POSTED) {
      expect_false(stringr::str_detect(t, stringr::regex(phrase, ignore_case = TRUE)),
                   info = phrase)
    }
  }
})


# -- SLIDE 18: PROJECTED, NOT AWARDED ----------------------------------------

test_that("slide 18 parses to seven rows, 505 applications, $95,510,000", {
  expect_equal(nrow(la_cyc), 7L)
  expect_equal(sum(la_cyc$applications), 505L)
  expect_equal(sum(la_cyc$projected), 95510000)
})

test_that("the parse recovers the first row's name, not the column heading", {
  # The headings and the first row are painted contiguously, so a lazy capture
  # that starts before "Anticipated Announcement" swallows it.
  expect_false(any(stringr::str_detect(la_cyc$activity, "Anticipated")))
  expect_match(la_cyc$activity[1], "Rural Clinician")
})

test_that("the column heading says PROJECTED, which is what makes it Tier 2", {
  expect_true(stringr::str_detect(la_deck, stringr::fixed("ProjectedBY 1 Funding")))
  expect_true(stringr::str_detect(la_deck, stringr::fixed("Anticipated Announcement")))
  expect_true(la_assert_deck_is_projected_not_awarded(la_deck))
})

test_that("505 applications received is not one award made (§0.3)", {
  expect_equal(la_cyc$applications[la_cyc$activity == "Capital Improvement Program"], 160L)
  # And the deck never claims any of them was awarded.
  expect_false(stringr::str_detect(la_deck, stringr::regex("selected for award|has been awarded", ignore_case = TRUE)))
})

test_that("even what Louisiana has promised is by TYPE, not by recipient", {
  expect_true(stringr::str_detect(la_deck, stringr::fixed(LA_STATED$obligated_promise)))
})


# -- §0.1: the six candidates ARE the activity column ------------------------

test_that("Louisiana holds twelve live Tier 3 candidates; six are slide 18's", {
  expect_equal(nrow(la_all), 12L)
  expect_equal(nrow(la_cands), 6L)
  expect_equal(sum(la_cands$amount_announced), 53910000)
})

test_that("not one candidate is a named organisation -- all six are fund uses", {
  expect_setequal(
    sort(la_cands$awardee_name_raw),
    sort(c("Alternative Payment Model", "Care conveners / navigation network",
           "Collaborative Provider Model", "Food is Medicine",
           "Rural Clinician Credit Bank", "Telehealth")))
  # §6.1's PROGRAM_NAME_AS_AWARDEE on six of six -- and the named-recipient
  # test passed every one of them, which is why they tiered SUBAWARD.
  expect_true(all(la_cands$named_recipient_test == "PASS"))
})

test_that("the names match the ACTIVITY column and the amounts the PROJECTED one", {
  expect_true(la_assert_candidates_are_deck_activities(la_cands, la_deck))
})

test_that("RCJ drops the Capital Improvement row, and the gap is exactly it", {
  expect_false(any(stringr::str_detect(la_cands$awardee_name_raw, "(?i)capital")))
  expect_equal(sum(la_cyc$projected) - sum(la_cands$amount_announced), 41600000)
  expect_true(la_assert_capital_row_dropped(la_cands, la_deck))
})

test_that("the dropped row is the largest, and the capital one", {
  cap <- la_cyc[la_cyc$activity == "Capital Improvement Program", ]
  expect_equal(cap$projected, 41600000)
  expect_equal(cap$projected, max(la_cyc$projected))
})

test_that("the disposition covers every live candidate and is re-derived, not typed", {
  d <- rhtp_la_rcj_disposition(la_all)
  expect_equal(d$rows, c(5L, 6L, 1L))
  expect_equal(sum(d$rows), nrow(la_all))
  expect_equal(sum(d$rcj_amount), sum(la_all$amount_announced))
  expect_equal(d$disposition, c("RHTP_SUBAWARD", "RHTP_BUT_NOT_A_SUBAWARD",
                                "RHTP_BUT_NOT_A_SUBAWARD"))
  expect_true(all(file.exists(here::here(d$source_archive_path))))
  expect_true(all(nzchar(d$disqualifying_fact)))
  expect_silent(rhtp_assert_disposition_prose(d, "LA"))
})

test_that("the disposition REFUSES a candidate it does not cover", {
  rogue <- la_all[1, ]
  rogue$record_id <- "rogue"
  rogue$source_doc_title <- "LA - 2026 - Something Nobody Has Read"
  expect_error(rhtp_la_rcj_disposition(dplyr::bind_rows(la_all, rogue)),
               "No group describes them")
})

# -- session 63: LOUISIANA HAS AWARDED ONE SOLICITATION ------------------------

test_that("the five RCCB rows are LDH's named, priced awards, to the dollar", {
  rccb <- la_rows_from(la_all, LA_RCCB_SOURCE_MARKER)
  expect_equal(nrow(rccb), 5L)
  expect_equal(sum(rccb$amount_announced), 1965788)
  p <- here::here(LA_RCCB_ARCHIVE)
  expect_equal(digest::digest(file = p, algo = "sha256"),
               "80d736837e46c0c09298463e2ddb9202d9eb8ffbe511489e5ad2933ca586db39")
  txt <- la_rccb_text()
  expect_true(la_assert_rccb_rows_are_ldh_awards(rccb, txt))
  expect_true(stringr::str_detect(txt, stringr::fixed("Total$1,965,788")))
  # a mispriced row is refused
  bad <- rccb; bad$amount_announced[1] <- bad$amount_announced[1] + 1
  expect_error(la_assert_rccb_rows_are_ldh_awards(bad, txt), "not a named")
})

test_that("LA.IO is the fund's administering state division, not a recipient", {
  rtcf <- la_rows_from(la_all, LA_RTCF_SOURCE_MARKER)
  expect_equal(nrow(rtcf), 1L)
  expect_equal(rtcf$amount_announced, 1)
  expect_true(stringr::str_detect(la_cat, stringr::fixed(
    "managed through Louisiana Innovation (LA.IO), a division of LED")))
})


# -- §6.2 provenance ---------------------------------------------------------

test_that("three publishers carry programme-scoped provenance sentences", {
  expect_true(la_assert_programme_provenance(la_prog, la_news, la_cat, la_deck))
  # LED is the only one of the three that is not LDH.
  expect_true(stringr::str_detect(
    la_cat, stringr::fixed("Supported through the Rural Health Transformation Program")))
})

test_that("the CMS footer corroborates the amount and is DEMOTED (session 27)", {
  expect_true(la_assert_footer_corroborates(strict = TRUE, programme = la_prog))
  expect_equal(round(as.numeric(stringr::str_remove_all(LA_STATED$footer_amount, "[$,]"))),
               la_allotment_anchor())
  # Non-strict returns NA with a message rather than throwing: a page re-post
  # that drops the boilerplate must not hard-fail Louisiana for no reason.
  stripped <- stringr::str_remove_all(la_prog, stringr::fixed(LA_STATED$footer_amount))
  expect_message(r <- la_assert_footer_corroborates(strict = FALSE, programme = stripped))
  expect_true(is.na(r))
  expect_error(la_assert_footer_corroborates(strict = TRUE, programme = stripped),
               "no longer on LDH")
})

test_that("the NOA anchor is the BUDGET PERIOD start, and solicitation postdates it", {
  expect_equal(as.character(la_noa_anchor()), "2025-12-29")
  expect_true(la_assert_after_noa(la_cap))
  expect_gt(as.numeric(as.Date("2026-06-18") - la_noa_anchor()), 0)
})


# -- the controls ------------------------------------------------------------

test_that("the positive control is Louisiana's own stated announcement form", {
  expect_true(la_assert_announcement_control(la_prog, la_fund, la_deck))
  expect_error(
    la_assert_announcement_control(
      stringr::str_remove_all(la_prog, stringr::fixed("IMPORTANT DATES - BUDGET YEAR 1")),
      la_fund, la_deck),
    "no longer carries its 'IMPORTANT DATES'")
})

test_that("the facility registry is an ELIGIBILITY list with no money in it", {
  p <- la_path("facilities")
  txt <- readChar(p, file.size(p), useBytes = TRUE)
  expect_true(la_assert_facilities_are_not_awards(txt))
  # 3,576 facilities, 305 hospitals, and not one dollar figure. California's
  # 102 SRHRP eligible hospitals in machine-readable form, three times over.
  expect_equal(stringr::str_count(txt, stringr::fixed("\"display_type\"")), 3576L)
  expect_equal(
    stringr::str_count(txt, stringr::fixed("\"display_type\":\"Hospital")), 305L)
  expect_false(stringr::str_detect(txt, stringr::fixed("$")))
  expect_false(stringr::str_detect(txt, stringr::fixed("RHTP")))
})

test_that("the facility control fires if money ever appears in it", {
  p <- la_path("facilities")
  txt <- readChar(p, file.size(p), useBytes = TRUE)
  expect_error(la_assert_facilities_are_not_awards(paste0(txt, '{"amount":1}')),
               "now carries")
  expect_error(la_assert_facilities_are_not_awards(paste0(txt, '"award_total"')),
               "now carries")
})


# -- the status table and the absent award file ------------------------------

test_that("the status table has no amount column (the money is in the award file)", {
  expect_true(la_assert_status_has_no_amount())
  cols <- names(readr::read_csv(here::here(LA_STATUS_CSV), n_max = 0,
                                show_col_types = FALSE))
  expect_false(any(c("amount", "round_amount", "amount_announced") %in% cols))
})

test_that("the status table names nine channels; only the RCCB publishes a (partial) roster", {
  st <- readr::read_csv(here::here(LA_STATUS_CSV), show_col_types = FALSE)
  expect_equal(nrow(st), 9L)
  rccb <- st[st$channel == "Rural Clinician Credit Bank", ]
  expect_equal(rccb$stage, "AWARDED_5_OF_53_NAMED")
  expect_equal(rccb$publishes_roster, "Partial -- 5 of 53 awardees named")
  others <- st[st$channel != "Rural Clinician Credit Bank", ]
  expect_true(all(others$publishes_roster %in% c("No", "UNKNOWN")))
  # The Atlas is UNKNOWN, never "No": that is a statement about our access.
  expect_equal(st$publishes_roster[stringr::str_detect(st$channel, "Atlas")],
               "UNKNOWN")
  # THE OTHER SIX ARE STILL UNAWARDED, and whether each window has passed is
  # derived from the page on every build (session 46), never typed.
  six <- st[stringr::str_detect(st$stage, "^CLOSED_AWARD_DATE_"), ]
  expect_equal(nrow(six), 6L)
})

test_that("the status table's RCCB stage is read off the deck, not the window", {
  # The programme page still prints the window and the funding page still
  # says 'under review': the pages LAG the deck, and the stage must follow the
  # deck.
  expect_true(stringr::str_detect(la_fund, stringr::fixed(
    "Rural Clinician Credit Bank, Budget Year 1 Purpose")))
  expect_true(stringr::str_detect(la_fund, stringr::fixed(
    "Applications currently under review")))
  st <- rhtp_la_year1_status()
  expect_equal(st$stage[st$channel == "Rural Clinician Credit Bank"],
               "AWARDED_5_OF_53_NAMED")
})


# -- session 64: THE RURAL CLINICIAN CREDIT BANK AWARD FILE -------------------

la_runs   <- la_rccb_runs()
la_rtxt   <- la_rccb_text()
la_awards <- readr::read_csv(here::here(LA_AWARDS_CSV), show_col_types = FALSE,
                             col_types = readr::cols(.default = "c"))

test_that("the deck closes on itself four ways, and the provenance holds", {
  r <- la_assert_rccb_award(la_rtxt, la_runs, la_fund, la_prog)
  ft <- r$facility[r$facility$facility_type != "Total", ]
  expect_equal(nrow(ft), 6L)
  expect_equal(sum(ft$awards), 53L)
  expect_equal(sum(ft$amount), 12701996)
  hosp <- ft[ft$facility_type %in% LA_RCCB_HOSPITAL_TYPES, ]
  expect_equal(hosp$awards, c(8L, 11L, 1L))
  expect_equal(sum(hosp$amount), 6285515)
  expect_equal(sum(r$parishes$awards), 48L)
  expect_equal(sum(r$parishes$amount), 10736208)
  expect_equal(sum(r$parishes$amount) + sum(r$named$amount), 12701996)
})

test_that("the deck's footer is the Tier 1 ALLOTMENT, not an RCCB figure (§0.2)", {
  expect_true(stringr::str_detect(la_rtxt, stringr::fixed(
    "This project supported by the Centers for Medicare")))
  expect_true(rhtp_assert_footer_not_allotment(208374447.57, "LA",
                                               "STATE_ALLOTMENT"))
  expect_error(rhtp_assert_footer_not_allotment(208374447.57, "LA",
                                                "SOLICITATION"),
               "almost certainly Tier 1")
})

test_that("the round postdates the NOA: application close 6/25/26, as of 8/28/26", {
  expect_true(stringr::str_detect(la_rtxt, stringr::fixed("Application close6/25/26")))
  expect_true(stringr::str_detect(la_rtxt, stringr::fixed("As of 8/28/26")))
  expect_gt(as.numeric(LA_RCCB_STATED$application_close - la_noa_anchor()), 0)
})

test_that("the deck is the one the programme page links as the September 3 webinar", {
  raw <- readChar(la_path("programme"), file.size(la_path("programme")),
                  useBytes = TRUE)
  i <- regexpr("Shareholder-Presentation-09092026.pdf", raw, fixed = TRUE)
  expect_gt(i, 0)
  expect_true(grepl("September 3, 2026", substr(raw, i - 200, i), fixed = TRUE))
  expect_true(stringr::str_detect(la_rtxt, stringr::fixed("September 3")))
})

test_that("a deck that stops saying what the file rests on is refused", {
  for (need in c("Awards made53", "CEAs due for signature9/15/26",
                 "As of 8/28/26", "5 multi-parish awardees")) {
    expect_error(la_assert_rccb_award(
      stringr::str_remove_all(la_rtxt, stringr::fixed(need)), la_runs,
      la_fund, la_prog), "no longer reads", info = need)
  }
  expect_error(la_assert_rccb_award(la_rtxt, la_runs,
    stringr::str_remove_all(la_fund, "Strategic Funding Opportunity Title: Rural Clinician Credit Bank"),
    la_prog), "no longer lists the Rural Clinician Credit Bank")
})

test_that("the five named awardees are read from the DECK's cells and are RCJ's five", {
  nm <- la_rccb_named(la_runs)
  expect_equal(nm$awardee, c("Ochsner Clinic Foundation",
                             "Outpatient Medical Center",
                             "Winnsboro Medical Clinic",
                             "SR Minden, Southern Roots",
                             "LaBorde Therapy Center"))
  expect_equal(nm$amount, c(1500000, 292500, 116288, 45000, 12000))
  expect_equal(nm$parishes, c(8L, 6L, 7L, 4L, 4L))
  rccb <- la_rows_from(la_all, LA_RCCB_SOURCE_MARKER)
  expect_setequal(rccb$awardee_name_clean, nm$awardee)
  expect_equal(sum(rccb$amount_announced), sum(nm$amount))
})

test_that("the award file is five named rows plus ONE unnamed aggregate", {
  expect_true(la_assert_award_file())
  expect_equal(nrow(la_awards), 6L)
  expect_equal(sum(as.numeric(la_awards$amount), na.rm = TRUE), 1965788)
  agg <- la_awards[la_awards$recipient_type == "NOT_YET_NAMED", ]
  expect_equal(nrow(agg), 1L)
  expect_true(is.na(agg$amount))
  expect_equal(as.numeric(agg$round_amount), 10736208)
  expect_equal(agg$round_awards, "48")
  expect_equal(agg$flag_reason, "RECIPIENT_NAMES_NOT_CAPTURED")
  expect_equal(agg$distributed_to_hospital, "Unclear")
  expect_equal(agg$recipient_confirmed, "No")
  expect_true(all(la_awards$amount_confirmed == "No"))
  expect_true(all(la_awards$validation_source_type == "NOTICE_OF_INTENT_TO_AWARD"))
  # every award exactly once: 5 named + 48 unnamed = 53
  expect_equal(nrow(la_awards) - 1L + as.integer(agg$round_awards), 53L)
})

test_that("the file rebuilds from the deck exactly", {
  built <- rhtp_la_year1_awardees(la_runs) %>%
    dplyr::mutate(dplyr::across(dplyr::everything(), as.character))
  expect_equal(names(built), names(la_awards))
  expect_equal(built$awardee, la_awards$awardee)
  expect_equal(built$amount, la_awards$amount)
  expect_equal(built$recipient_type, la_awards$recipient_type)
  expect_equal(built$distributed_to_hospital, la_awards$distributed_to_hospital)
  expect_equal(as.numeric(built$round_amount), as.numeric(la_awards$round_amount))
})

test_that("the file carries the leading 19 columns the state union requires", {
  expect_equal(names(la_awards)[1:19], c(
    "state", "row_no", "awardee", "amount", "recipient_type",
    "distributed_to_hospital", "note", "recipient_confirmed", "amount_confirmed",
    "fiscal_year", "source_document_title", "state_source_url",
    "validation_source_type", "extraction_method", "validator", "ccn", "aha_id",
    "rural_designation", "reviewer"))
})

test_that("OUTPATIENT Medical Center is REFUSED as a hospital, and the refusal is auditable", {
  source(here::here("R", "utils_recipient_classification.R"))
  m <- rhtp_classify_recipient_type("Outpatient Medical Center", state_code = "LA")
  # The machine says hospital on the 'Medical Center' token ...
  expect_equal(m$recipient_type, "HOSPITAL_OR_SYSTEM")
  # ... and the file does not follow it.
  row <- la_awards[la_awards$awardee == "Outpatient Medical Center", ]
  expect_equal(row$recipient_type, "NONPROFIT_CBO")
  expect_equal(row$distributed_to_hospital, "No")
  expect_true(stringr::str_detect(row$recipient_type_source, "REFUSED"))
  expect_true(stringr::str_detect(row$recipient_type_source, "HOSPITAL_OR_SYSTEM"))
  # Priced: following the machine would have put $292,500 into NAMED_HOSPITAL.
  expect_equal(as.numeric(row$amount), 292500)
})

test_that("Louisiana contributes NO row and NO dollar to any hospital bucket", {
  source(here::here("R", "utils_recipient_classification.R"))
  d <- la_awards %>% dplyr::mutate(amount = as.numeric(.data$amount))
  parts <- rhtp_hospital_dollar_partition(d)
  expect_equal(nrow(parts), 0L)
  expect_false(any(la_awards$distributed_to_hospital == "Yes"))
  ref <- list.files(here::here("data", "reference"), pattern = "^la_")
  expect_setequal(ref, c("la_rcj_candidate_disposition.csv",
                         "la_year1_status.csv", "la_year1_awardees.csv"))
})

test_that("the three ways a hospital dollar could creep in are each refused", {
  num <- function(x) suppressWarnings(as.numeric(x))
  # (1) the round total written into `amount` on the aggregate
  a <- la_awards; a$amount[a$recipient_type == "NOT_YET_NAMED"] <- "10736208"
  expect_error(la_assert_award_file(a), "sum\\(amount\\)|EMPTY amount")
  # (2) a hospital-only aggregate beside the named rows (overlap)
  b <- dplyr::bind_rows(la_awards, la_awards[6, ] %>%
         dplyr::mutate(row_no = "7", round_awards = "20",
                       round_amount = "6285515"))
  expect_error(la_assert_award_file(b), "rows")
  # (3) any row coded Yes with no hospital named on it
  c0 <- la_awards; c0$distributed_to_hospital[6] <- "Yes"
  expect_error(la_assert_award_file(c0), "distributed_to_hospital = Yes")
  # and a named row typed a hospital by a name rule is stopped at build
  expect_true(all(la_awards$recipient_type != "HOSPITAL_OR_SYSTEM"))
})

test_that("the hospital-setting figure is the state's words, never a summable column", {
  agg <- la_awards[la_awards$recipient_type == "NOT_YET_NAMED", ]
  expect_true(stringr::str_detect(agg$recipient_class, stringr::fixed("$6,285,515")))
  expect_true(stringr::str_detect(agg$recipient_class, "between 15\\s+and 20"))
  # No column of the award file carries the hospital-setting figure as a number.
  expect_false(any(vapply(la_awards, function(x) any(x %in% "6285515"),
                          logical(1))))
})


# -- the survey reads INVESTIGATED_NO_LIST -----------------------------------

test_that("Louisiana cannot rank first again and be re-investigated", {
  s <- readr::read_csv(here::here("data/reference/rcj_state_survey.csv"),
                       show_col_types = FALSE)
  q <- readr::read_csv(here::here("data/reference/state_trigger_queue.csv"),
                       show_col_types = FALSE)
  # Session 64 extracted the RCCB round, so the survey is expected to move LA
  # to EXTRACTED (R/03k's constants, edited outside this file). Either status
  # keeps Louisiana out of the queue; NOT_EXTRACTED or QUEUED would not.
  expect_true(s$extraction_status[s$state == "LA"] %in%
                c("INVESTIGATED_NO_LIST", "EXTRACTED"))
  expect_true(q$queue_status[q$state == "LA"] %in%
                c("INVESTIGATED_NO_LIST", "EXTRACTED"))
  expect_equal(s$investigate[s$state == "LA"], "No")
})


# -- the content digest, and the SEVENTH mechanism ---------------------------

test_that("the reduction absorbs Cloudflare's per-render email obfuscation", {
  p   <- la_path("programme")
  raw <- readBin(p, "raw", file.size(p))
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "UTF-8"

  # Synthesise the mechanism offline: Cloudflare XOR-encodes the mailto with a
  # random one-byte key on every render, into an href and a data-cfemail
  # ATTRIBUTE, at CONSTANT LENGTH. Re-roll both hex blobs to the same width.
  # The replacement gets a VECTOR of matches, so the rewrite is vectorised and
  # the substitute hex is built with strrep() at exactly the width it replaces.
  reroll <- stringr::str_replace_all(
    txt, "(email-protection#|data-cfemail=\")([0-9a-f]+)",
    function(m) {
      pre <- stringr::str_extract(m, "^(email-protection#|data-cfemail=\")")
      hex <- stringr::str_remove(m, "^(email-protection#|data-cfemail=\")")
      paste0(pre, strrep("5", nchar(hex)))
    })
  expect_false(identical(txt, reroll))

  a <- charToRaw(txt); b <- charToRaw(reroll)
  # Constant length is the point: a byte-count check passes this, as it passes
  # California's antispambot() re-roll.
  expect_equal(length(a), length(b))
  expect_false(identical(digest::digest(a, algo = "sha256"),
                         digest::digest(b, algo = "sha256")))
  # The CONTENT digest does not move, because the obfuscation is attribute-borne
  # and the reduction strips tags (Connecticut's ?v= stamp, structurally).
  expect_equal(la_content_digest(a, "programme"),
               la_content_digest(b, "programme"))
})

test_that("the archived programme page still carries the mechanism", {
  # If Cloudflare's obfuscation ever leaves the page, the note in the manifest
  # is stale and the next session should know before it trusts a file digest.
  expect_true(stringr::str_detect(
    readChar(la_path("programme"), file.size(la_path("programme")), useBytes = TRUE),
    stringr::fixed("/cdn-cgi/l/email-protection")))
})


# -- everything at once ------------------------------------------------------

test_that("the full assertion set runs clean on the committed archive", {
  expect_true(rhtp_la_assert())
  expect_true(la_assert_candidates_are_deck_activities())
  expect_true(la_assert_capital_row_dropped())
  expect_true(la_assert_rccb_rows_are_ldh_awards())
  expect_true(la_assert_award_file())
})
