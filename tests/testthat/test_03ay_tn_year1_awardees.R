# test_03ay_tn_year1_awardees.R ---------------------------------------------
# Tennessee, session 59. 53 named HART awards, no amounts, two hospitals.
# The weight is on the two things that go wrong in opposite directions: coding
# the STATE'S LABEL instead of the recipient (which drops both hospitals), and
# reading a number into a file whose publisher printed none.

library(testthat)
source(here::here("R", "03ay_tn_year1_awardees.R"))

r <- tn_read_roster()
d <- tn_year1_awardees(r)
committed <- readr::read_csv(TN_CSV, show_col_types = FALSE, progress = FALSE)

test_that("the roster is 53 recipients in 44 counties and the release says so", {
  expect_equal(nrow(r), 53L)
  expect_silent(tn_assert_roster(r))
  expect_silent(tn_assert_release())
})

test_that("NO row carries an amount -- Nevada's and Iowa's shape", {
  expect_true(all(is.na(d$amount)))
  expect_true(all(is.na(d$round_amount)))
  expect_true(all(d$flag_reason == "AMOUNT_MISSING"))
  expect_true(all(d$amount_confirmed == "No"))
})

test_that("two named-hospital rows and $0 -- READ THE ROW COUNT", {
  h <- d[d$distributed_to_hospital == "Yes", ]
  expect_setequal(h$awardee, c("Macon Hospital, Inc",
                               "Cookeville Regional Medical Center Foundation"))
  expect_true(all(h$recipient_type == "HOSPITAL_OR_SYSTEM"))
  expect_true(all(h$flow_type == "DIRECT"))
  expect_true(all(h$hospital_attribution == "NAMED_HOSPITAL"))
  # Both rest on a reading (a bridge; a foundation's parent), so LOW.
  expect_true(all(h$determination_confidence == "LOW"))
  expect_true(all(h$basis_type == "GENERAL_KNOWLEDGE"))
  expect_equal(sum(h$amount, na.rm = TRUE), 0)
})

test_that("§0.3a: coding the STATE'S LABEL would lose both hospitals", {
  # TDH files Macon among its 31 governments and the Foundation among its 22
  # nonprofits. A reader who coded the label would type them
  # LOCAL_GOVT_OR_PUBLIC_HEALTH and NONPROFIT_CBO -- and Tennessee would have
  # no hospital row at all.
  h <- d[d$distributed_to_hospital == "Yes", ]
  expect_equal(h$tdh_class[h$awardee == "Macon Hospital, Inc"], "GOVERNMENT")
  expect_equal(h$tdh_class[h$awardee == "Cookeville Regional Medical Center Foundation"],
               "NONPROFIT")
  label_coded <- ifelse(d$tdh_class == "GOVERNMENT",
                        "LOCAL_GOVT_OR_PUBLIC_HEALTH", "NONPROFIT_CBO")
  expect_equal(sum(label_coded == "HOSPITAL_OR_SYSTEM"), 0L)
})

test_that("the typing reproduces TDH's own 31/22 split exactly", {
  expect_silent(tn_assert_split(r))
  expect_equal(sum(d$tdh_class == "GOVERNMENT"), 31L)
  expect_equal(sum(d$tdh_class == "NONPROFIT"), 22L)
  # And a mistyped row breaks it.
  bad <- r; bad$awardee[bad$awardee == "Town of Whiteville"] <- "Whiteville Friends"
  expect_error(tn_assert_split(bad), "31/22")
})

test_that("the classifier's misses are recorded, not repaired in the shared rule", {
  miss <- c("Cleveland City Schools", "Hawkins County Schools",
            "Lauderdale County Schools", "Town of Ashland City",
            "Obion County Public Library", "Jefferson County Mayor",
            "Loudon County Economic Development Agency")
  cls <- rhtp_classify_recipient_type(miss, "TN")
  expect_true(all(cls$recipient_type == "NONPROFIT_CBO"))
  typed <- d$recipient_type[match(miss, d$awardee)]
  expect_true(all(typed %in% c("SCHOOL_OR_DISTRICT", "LOCAL_GOVT_OR_PUBLIC_HEALTH")))
  expect_true(all(grepl("Classifier said NONPROFIT_CBO",
                        d$recipient_type_source[match(miss, d$awardee)])))
})

test_that("the federal records the two hospital rows rest on are archived", {
  expect_silent(tn_assert_federal_records())
  h <- d[d$distributed_to_hospital == "Yes", ]
  expect_match(h$determination_basis[h$awardee == "Macon Hospital, Inc"],
               "CCN 441305.*HAND-READ BRIDGE|HAND-READ BRIDGE.*CCN 441305")
  expect_match(h$determination_basis[grepl("Cookeville", h$awardee)],
               "CCN 440059")
})

test_that("a dollar figure appearing in the roster refuses the build", {
  bad <- r; bad$project[1] <- "$250,000"
  expect_error(tn_assert_roster(bad), "dollar figure")
})

test_that("the committed file is what the builder writes", {
  expect_equal(nrow(committed), 53L)
  expect_equal(committed$awardee, d$awardee)
  expect_equal(committed$recipient_type, d$recipient_type)
  expect_equal(committed$distributed_to_hospital, d$distributed_to_hospital)
})

test_that("all 53 are RCJ-invisible: the only pull predates the roster", {
  dispo <- readr::read_csv(TN_DISPO_CSV, show_col_types = FALSE)
  expect_equal(dispo$disposition[1], "NO_TIER_3")
  expect_match(dispo$note[1], "predates")
  rt <- rhtp_record_table_live()
  expect_equal(sum(rt$state == "TN" & rt$award_tier == "SUBAWARD"), 0L)
  expect_true(max(as.Date(rt$last_seen[rt$state == "TN"])) < TN_ANNOUNCED)
})

test_that("RAMP is recorded as STATE money and never as a row", {
  st <- readr::read_csv(TN_STATUS_CSV, show_col_types = FALSE)
  expect_match(st$note[grepl("RAMP", st$channel)], "TennCare Shared Savings")
  expect_false(any(grepl("RAMP|Rural Healthcare Access Modernization", d$note)))
})

# -- the probe, driven offline ------------------------------------------------

arch <- function(k) here::here(TN_PROBE_PAGES$file[TN_PROBE_PAGES$key == k])
news_raw <- readBin(arch("news"), "raw", file.info(arch("news"))$size)
rhtp_raw <- readBin(arch("rhtp"), "raw", file.info(arch("rhtp"))$size)
ramp_txt <- rhtp_watch_reduce(arch("ramp"))

test_that("the archived pages pass their own tripwires", {
  expect_silent(tn_assert_watch(news_raw, rhtp_raw, ramp_txt))
  expect_true(all(TN_KNOWN_RHTP_HEADLINES[1:2] %in% tn_news_headlines(news_raw)))
})

test_that("a new RHTP recipients headline trips, and says RAMP is not RHTP", {
  html <- rawToChar(news_raw)
  hot <- sub("</body>", paste0(
    '<a href="/health/news/2026/10/1/x.html">Tennessee Department of Health ',
    'Announces 2nd Recipients of Rural Health Transformation Program Grants</a></body>'),
    html, fixed = TRUE)
  expect_error(tn_assert_watch(charToRaw(hot), rhtp_raw, ramp_txt),
               "NEW RHTP AWARD RELEASE.*STATE money")
})

test_that("the programme page gaining an award workbook link trips", {
  html <- sub("</body>", '<a href="/content/dam/tn/health/xlsx/2026-RHTP-RAMP-Grant-Awards.xlsx">x</a></body>',
              rawToChar(rhtp_raw), fixed = TRUE)
  expect_error(tn_assert_watch(news_raw, charToRaw(html), ramp_txt),
               "links an award document")
})

test_that("RAMP losing its funding sentence trips -- the control is gone", {
  expect_error(tn_assert_watch(news_raw, rhtp_raw,
                               gsub("TennCare Shared Savings", "federal RHTP", ramp_txt)),
               "NO LONGER SAYS")
})

test_that("the probe's news reader failing is our reader, not Tennessee", {
  expect_error(tn_assert_watch(charToRaw("<html><body></body></html>"),
                               rhtp_raw, ramp_txt), "our reader")
})
