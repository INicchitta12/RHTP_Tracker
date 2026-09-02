# test_03ah_nc_year1_sources.R ------------------------------------------------
# North Carolina: NOT a negative. Two published rosters, deliberately not
# extracted. Committed files only -- no network.
#
# THE TESTS THAT CARRY THE WEIGHT ARE THE ONES GUARDING THE EXTRACTION THAT
# HAS NOT HAPPENED YET. North Carolina publishes 44 named recipients and NO
# per-recipient dollar, and the only currency figure beside the five Hub Leads
# is the whole state allotment. An extractor built carelessly from these
# documents would publish $213,008,356.47 as five hub awards.

library(testthat)

source(here::here("R", "03ah_nc_year1_sources.R"))

skip_without_archive <- function() {
  if (!nc_have_archive()) skip("the NC evidence archive is not on disk")
}

as_raw_html <- function(txt) charToRaw(enc2utf8(txt))


# -- what North Carolina has published ---------------------------------------

test_that("the 39-recipient MIH roster is published and is a POOL figure", {
  skip_without_archive()
  expect_true(nc_assert_mih_roster())
  txt <- stringr::str_replace_all(nc_html_text("pr_mih"), "\\s+", " ")
  expect_true(grepl("$10 million to 39 local EMS agencies", txt, fixed = TRUE))
  expect_true(grepl("The Mobile Integrated Health grant recipients include:",
                    txt, fixed = TRUE))
})

test_that("the roster window is bounded by the roster, not a character count", {
  # THE DEFECT THIS PINS, AND IT FIRED WHILE THE FILE WAS BEING WRITTEN. A
  # fixed-width window ran past the last name into the Stevens Amendment
  # footer, so the "no dollar figure inside the roster" check tripped on the
  # $213,008,356.47 ALLOTMENT -- the very figure 0.2 says must never be read
  # as this round's money -- and it would have tripped on every run.
  skip_without_archive()
  txt <- stringr::str_replace_all(nc_html_text("pr_mih"), "\\s+", " ")
  roster <- stringr::str_extract(
    txt,
    "The Mobile Integrated Health grant recipients include:.*?For more information")
  expect_false(is.na(roster))
  expect_false(grepl("$", roster, fixed = TRUE))
  expect_true(grepl("213,008,356.47", txt, fixed = TRUE))   # it IS on the page
  expect_true(grepl("Yancey County EMS", roster, fixed = TRUE))
})

test_that("Cape Fear Valley is the one hospital-affiliated MIH recipient", {
  skip_without_archive()
  roster <- stringr::str_extract(
    stringr::str_replace_all(nc_html_text("pr_mih"), "\\s+", " "),
    "The Mobile Integrated Health grant recipients include:.*?For more information")
  expect_true(grepl("Cape Fear Valley", roster, fixed = TRUE))

  # THE SPLIT, COUNTED RATHER THAN EYEBALLED. 39 recipients: 37 named
  # "<X> County EMS", one "Clay County" with the suffix dropped (the source's
  # own inconsistency, kept as published per 8), and Cape Fear Valley Mobile
  # Integrated Health -- a health system's MIH programme and the ONLY
  # hospital-affiliated recipient, hence the only 10.2 judgement in the set.
  parts <- stringr::str_extract_all(
    roster,
    "[A-Z][A-Za-z. ]+?(County EMS|County|Mobile Integrated Health \\(MIH\\))")[[1]]
  expect_length(parts, 39L)
  expect_equal(sum(grepl("County EMS$", parts)), 37L)
  expect_setequal(parts[!grepl("County EMS$", parts)],
                  c("Cape Fear Valley Mobile Integrated Health (MIH)",
                    "Clay County"))
})

test_that("a dollar figure appearing inside the roster stops the build", {
  skip_without_archive()
  raw <- readBin(nc_path("pr_mih"), "raw", file.size(nc_path("pr_mih")))
  faked <- sub("Alamance County EMS", "Alamance County EMS $250,000",
               rawToChar(raw), fixed = TRUE)
  expect_error(nc_assert_mih_roster(body = charToRaw(faked)),
               "dollar figure has appeared INSIDE")
})

test_that("the five Hub Leads are named and are FIDUCIARY leads", {
  skip_without_archive()
  expect_true(nc_assert_hub_leads())
  pr <- stringr::str_replace_all(nc_html_text("pr_roots"), "\\s+", " ")
  expect_true(grepl("The NC ROOTS Hub Lead awardees include", pr, fixed = TRUE))
  for (n in NC_HUB_LEADS) expect_true(grepl(n, pr, fixed = TRUE), info = n)
  expect_length(NC_HUB_LEADS, 5L)
})

test_that("losing 'fiduciary' stops the build -- it is what separates NC from MO", {
  # Missouri's Hub Anchors are a governance roster whose own FAQ says they
  # are NOT the fiscal agent, and they contribute $0 and no row. North
  # Carolina's are "programmatic and fiduciary leads". One word decides
  # whether these five are recipients at all.
  skip_without_archive()
  raw <- readBin(nc_path("pr_roots"), "raw", file.size(nc_path("pr_roots")))
  gutted <- gsub("programmatic and fiduciary leads", "conveners",
                 rawToChar(raw), fixed = TRUE)
  expect_error(nc_assert_hub_leads(bodies = list(pr_roots = charToRaw(gutted))),
               "programmatic and fiduciary")
})

test_that("UNC appears under TWO spellings across two documents", {
  # The fuzzy match 2 forbids a machine resolving. Recorded, not merged.
  skip_without_archive()
  pr <- nc_html_text("pr_roots")
  page <- nc_html_text("roots_page")
  expect_true(grepl("University of North Carolina Hospitals", pr, fixed = TRUE))
  expect_true(grepl("UNC Health", page, fixed = TRUE))
})


# -- 0.2: the only figure beside five awardees is the allotment --------------

test_that("the ROOTS page carries the ALLOTMENT and nothing else", {
  skip_without_archive()
  figures <- nc_assert_roots_page_has_no_pool()
  expect_equal(figures, "$213,008,356.47")
})

test_that("that figure is refused as a pool, and the MIH pool is not", {
  skip_without_archive()
  expect_true(nc_assert_footer_is_the_allotment())
  expect_error(
    rhtp_assert_footer_not_allotment(NC_FOOTER, "NC", "SOLICITATION"),
    "almost certainly Tier 1")
  expect_true(
    rhtp_assert_footer_not_allotment(NC_MIH_POOL, "NC", "SOLICITATION"))
})

test_that("per-hub amounts appearing turns this into an extraction", {
  skip_without_archive()
  raw <- readBin(nc_path("roots_page"), "raw", file.size(nc_path("roots_page")))
  faked <- sub("Impact Health", "Impact Health $18,000,000",
               rawToChar(raw), fixed = TRUE)
  expect_error(nc_assert_roots_page_has_no_pool(body = charToRaw(faked)),
               "currency figures other than the allotment")
})


# -- the controls ------------------------------------------------------------

test_that("two opportunities are closed with no roster, both dates passed", {
  skip_without_archive()
  expect_true(nc_assert_positive_control())
  st <- nc_status_table()
  closed <- st[st$stage == "CLOSED_UNAWARDED", ]
  expect_equal(nrow(closed), 2L)
  expect_true(all(closed$publishes_roster == "No"))
})

test_that("the SECOND TIER awarding stops the build -- that is where the money is", {
  skip_without_archive()
  raw <- readBin(nc_path("trillium"), "raw", file.size(nc_path("trillium")))
  faked <- sub("</body>", "Region 2 awarded these organizations</body>",
               rawToChar(raw), fixed = TRUE)
  expect_error(
    nc_assert_positive_control(bodies = list(trillium = charToRaw(faked))),
    "SECOND TIER may have awarded")
})


# -- the deferral is deliberate ----------------------------------------------

test_that("no award file exists, and creating one trips the guard", {
  expect_true(nc_assert_not_extracted())
  expect_false(file.exists(NC_AWARDEES_CSV))
})

test_that("the status table records the rosters WITHOUT an amount column", {
  st <- nc_status_table()
  expect_false("amount" %in% names(st))
  expect_equal(nrow(st), 6L)
  awarded <- st[st$stage == "AWARDED_ROSTER_PUBLISHED", ]
  expect_equal(nrow(awarded), 2L)
  expect_equal(sum(awarded$named_recipients), 44L)
  expect_setequal(awarded$named_recipients, c(39L, 5L))
})

test_that("North Carolina stays NOT_EXTRACTED, never INVESTIGATED_NO_LIST", {
  # It has published rosters, so INVESTIGATED_NO_LIST would be a FALSE claim
  # about the state -- the one thing that code must never become.
  for (f in c("rcj_state_survey.csv", "state_trigger_queue.csv")) {
    path <- here::here("data", "reference", f)
    skip_if_not(file.exists(path), paste(f, "is not on disk"))
    d <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
    col <- if ("extraction_status" %in% names(d)) "extraction_status" else
      "queue_status"
    expect_false(identical(d[[col]][d$state == "NC"], "INVESTIGATED_NO_LIST"))
  }
})


# -- the digest mechanism ----------------------------------------------------

test_that("Dynatrace's per-request rpid moves the FILE digest, not content", {
  skip_without_archive()
  raw <- readBin(nc_path("roots_page"), "raw", file.size(nc_path("roots_page")))
  txt <- rawToChar(raw)
  expect_true(grepl("ruxitagentjs", txt, fixed = TRUE))
  rolled <- sub("rpid=-?[0-9]+", "rpid=123456789", txt)
  expect_false(identical(rolled, txt))
  expect_false(identical(digest::digest(charToRaw(rolled), serialize = FALSE),
                         digest::digest(raw, serialize = FALSE)))
  # It is a script-TAG ATTRIBUTE, so the reduction absorbs it free.
  expect_identical(nc_reduce_html(charToRaw(rolled)), nc_reduce_html(raw))
})
