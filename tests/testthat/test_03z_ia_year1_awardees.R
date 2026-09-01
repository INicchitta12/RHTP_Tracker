# test_03z_ia_year1_awardees.R ------------------------------------------------
# Iowa -- Healthy Hometowns. Reads committed archives only; no network, no
# quota.
#
# WHAT THIS FILE IS REALLY GUARDING. Iowa is the state that could not be
# extracted until the run model landed: its notices set a recipient and a county
# as two cells at one y, and the old line model returned
# "Adair County Memorial Hospital Greenfield". A mangled recipient name is the
# one thing §0.4 will not have, so the tests below are weighted towards the
# PARSE -- the columns, the wrapped cells, and the two independent readings that
# say the parse is right.

library(testthat)

source(here::here("R", "03z_ia_year1_awardees.R"))

IA_CSV <- here::here("data/reference/ia_year1_awardees.csv")

skip_without_archive <- function() {
  skip_if_not(file.exists(ia_path("phthorc26008")),
              "Iowa evidence not archived")
}


# -- the parse ----------------------------------------------------------------

test_that("the Adair County case is two cells, not one welded name", {
  skip_without_archive()
  r <- ia_roster("phthorc26009_feb")
  # THE CASE THIS WHOLE SESSION EXISTS FOR. Before the run model these two were
  # one string with the county welded onto the organisation.
  expect_true("Adair County Memorial Hospital" %in% r$awardee)
  expect_equal(r$col2[r$awardee == "Adair County Memorial Hospital"], "Greenfield")
  # And nothing anywhere carries the merged form.
  expect_false(any(grepl("Hospital Greenfield", r$awardee, fixed = TRUE)))
})

test_that("a county vocabulary would NOT have separated these columns", {
  skip_without_archive()
  r <- ia_roster("phthorc26009_feb")
  # The second column mixes counties with CITIES -- Greenfield is the seat of
  # Adair County -- which is why the split had to come from the geometry and
  # could never have come from a list of Iowa county names.
  expect_true("Greenfield" %in% r$col2)
  expect_true("Winneshiek" %in% r$col2)
})

test_that("every notice parses, and none parses to nothing", {
  skip_without_archive()
  for (k in IA_NOTICES$key) {
    d <- ia_roster(k)
    expect_gt(nrow(d), 0L)
    expect_true(all(nzchar(d$awardee)), info = k)
  }
})

test_that("a wrapped cell comes back whole", {
  skip_without_archive()
  r <- ia_roster("phthorc26010")
  # "Cass County Memorial" / "Hospital DBA Cass Health" is set on two lines.
  expect_true("Cass County Memorial Hospital DBA Cass Health" %in% r$awardee)
  # "Adair County Memorial" / "Hospital" likewise.
  expect_true("Adair County Memorial Hospital" %in% r$awardee)
})

test_that("runs within a line join with nothing and wrapped lines with a space", {
  skip_without_archive()
  # Iowa splits "Veterans" into two runs at one y; joined with a space that
  # would read "Ve terans".
  expect_true("Veterans Memorial Hospital" %in% ia_roster("phthorc26012")$awardee)
  # And 18885 sets "Iowa Specialty Hospital", "-" and "Clarion" as three runs
  # at one y.
  expect_true(any(grepl("Iowa Specialty Hospital",
                        ia_roster("phthorc26011")$awardee, fixed = TRUE)))
})

test_that("the header row is dropped from every table", {
  skip_without_archive()
  for (k in IA_NOTICES$key) {
    d <- ia_roster(k)
    expect_false(any(d$awardee %in% IA_HEADER_LABELS), info = k)
  }
})

test_that("a page number never becomes a recipient or a column", {
  skip_without_archive()
  for (k in c("phthorc26011", "phthorc26012")) {
    d <- ia_roster(k)
    expect_false(any(grepl("^[0-9]{1,2}$", d$awardee)), info = k)
  }
})


# -- the external checks ------------------------------------------------------

test_that("RCJ reads the same ten names out of the Centers of Excellence notice", {
  skip_without_archive()
  skip_if_not(file.exists(here::here("data/interim/stage2_record_table.rds")))
  # THE ONLY INDEPENDENT READING THIS PROJECT HAS OF AN IOWA NOTICE. A
  # commercial aggregator that never saw this parser produced the same ten
  # names, and one of RCJ's Best and Brightest names is a cell the notice WRAPS.
  expect_silent(ia_assert_rcj_names_match())
})

test_that("the 2026-06-18 release re-publishes one whole notice's roster", {
  skip_without_archive()
  expect_silent(ia_assert_second_publishers())
})


# -- §6.2 and §0.2 ------------------------------------------------------------

test_that("the notices never name the programme, which is why the page must", {
  skip_without_archive()
  h <- ia_assert_notices_name_no_programme()
  expect_equal(sum(h$rhtp + h$rht + h$hh), 0L)
  expect_silent(ia_assert_programme_provenance())
})

test_that("every notice postdates the 2025-12-29 Notice of Award", {
  skip_without_archive()
  expect_silent(ia_assert_notices_postdate_noa())
  expect_true(all(as.Date(IA_NOTICES$notice_date) > IA_NOA_DATE))
})

test_that("the footer's amount is TWO tiers and the eleven are never summed", {
  skip_without_archive()
  expect_setequal(unique(IA_NOTICES$footer_tier),
                  c("SOLICITATION", "STATE_ALLOTMENT"))
  expect_equal(sum(IA_NOTICES$footer_tier == "STATE_ALLOTMENT"), 3L)
  expect_true(all(abs(
    IA_NOTICES$footer_amount[IA_NOTICES$footer_tier == "STATE_ALLOTMENT"] -
      IA_ALLOTMENT) < 0.005))
  # The trap, pinned open: the only number in each document, added up, is four
  # times what Iowa was awarded.
  expect_gt(sum(IA_NOTICES$footer_amount), IA_ALLOTMENT * 4)
  expect_silent(ia_assert_footers_not_summable())
})

test_that("no footer figure reaches the award file", {
  skip_if_not(file.exists(IA_CSV))
  rows <- readr::read_csv(IA_CSV, show_col_types = FALSE, progress = FALSE)
  expect_false("round_amount" %in% names(rows))
  expect_true(all(is.na(rows$amount)))
})

test_that("the footer table states each figure's tier and is not an amount column", {
  skip_without_archive()
  f <- ia_footer_table()
  expect_equal(nrow(f), 11L)
  expect_true(all(nzchar(f$note)))
  expect_true(all(grepl("TIER [12]", f$note)))
})


# -- the controls -------------------------------------------------------------

test_that("the awardee index is present and holds exactly eleven notices", {
  skip_without_archive()
  expect_silent(ia_assert_award_index())
  expect_equal(length(IA_AWARDEE_MEDIA_IDS), 11L)
})

test_that("the re-issue supersedes, and adds exactly Marengo Memorial", {
  skip_without_archive()
  added <- ia_assert_supersession()
  expect_equal(added, "Marengo Memorial Hospital")
  expect_equal(nrow(ia_roster("phthorc26009_feb")),
               nrow(ia_roster("phthorc26009_jan")) + 1L)
})

test_that("the superseded notice contributes no row", {
  skip_without_archive()
  rows <- ia_award_rows()
  expect_silent(ia_assert_superseded_excluded(rows))
  expect_equal(nrow(IA_OPERATIVE()), 10L)
})

test_that("the name repair is ONE entry and is sourced to Iowa's own notice", {
  skip_without_archive()
  expect_equal(length(IA_NAME_FROM_SUPERSEDED), 1L)
  # The replacement string is the January notice's own text, not this
  # pipeline's: it must appear in that notice's roster verbatim.
  expect_true(unname(IA_NAME_FROM_SUPERSEDED[1]) %in%
                ia_roster("phthorc26009_jan")$awardee)
  rows <- ia_award_rows()
  repaired <- rows[grepl("RECIPIENT_NAME_FROM_SUPERSEDED_NOTICE",
                         rows$flag_reason), ]
  expect_equal(nrow(repaired), 1L)
  expect_true(grepl("SUPERSEDED", repaired$note[1]))
})

test_that("a dollar figure inside a roster fails the build", {
  skip_without_archive()
  expect_silent(ia_assert_no_per_recipient_amounts())
})


# -- the file -----------------------------------------------------------------

test_that("Iowa's zero dollars is not zero hospitals", {
  skip_if_not(file.exists(IA_CSV))
  rows <- readr::read_csv(IA_CSV, show_col_types = FALSE, progress = FALSE)
  part <- rhtp_hospital_dollar_partition(rows)
  named <- part[part$bucket == "NAMED_HOSPITAL", ]
  # READ THE ROW COUNT. Both of these are true and reporting only the second
  # reports the opposite of what Iowa has published.
  expect_gt(named$rows[1], 100L)
  expect_equal(named$dollars[1], 0)
  expect_silent(ia_assert_zero_dollars_is_not_zero_hospitals(rows))
})

test_that("the committed file is 264 award actions across ten RFPs", {
  skip_if_not(file.exists(IA_CSV))
  rows <- readr::read_csv(IA_CSV, show_col_types = FALSE, progress = FALSE)
  expect_equal(nrow(rows), 264L)
  expect_equal(dplyr::n_distinct(rows$award_pool), 10L)
  expect_true(all(rows$state == "IA"))
  expect_true(all(rows$validation_source_type == "NOTICE_OF_INTENT_TO_AWARD"))
  # They are INTENTS, so no amount is confirmed -- and there is no amount.
  expect_true(all(rows$amount_confirmed == "No"))
  expect_true(all(rows$recipient_confirmed == "Yes"))
})

test_that("every row carries a non-empty determination_basis", {
  skip_if_not(file.exists(IA_CSV))
  rows <- readr::read_csv(IA_CSV, show_col_types = FALSE, progress = FALSE)
  expect_true(all(nzchar(trimws(rows$determination_basis))))
  expect_true(all(nzchar(trimws(rows$amount_basis))))
})

test_that("every categorical value is inside §8", {
  skip_if_not(file.exists(IA_CSV))
  rows <- readr::read_csv(IA_CSV, show_col_types = FALSE, progress = FALSE)
  for (col in c("recipient_type", "distributed_to_hospital", "flow_type",
                "hospital_attribution", "determination_confidence",
                "recipient_confirmed", "amount_confirmed")) {
    allowed <- rhtp_vocabulary(col)
    expect_true(all(rows[[col]] %in% allowed), info = col)
  }
  # `validation_source_type` is checked against §8's source_doc_type, which is
  # the vocabulary it draws from.
  expect_true(all(rows$validation_source_type %in%
                    rhtp_vocabulary("source_doc_type")))
})

test_that("the disposition covers every RCJ Iowa candidate", {
  skip_if_not(file.exists(here::here("data/interim/stage2_record_table.rds")))
  d <- ia_disposition()
  expect_equal(sum(d$rcj_rows), nrow(ia_rcj_candidates()))
  expect_true(all(nzchar(d$evidence)))
})
