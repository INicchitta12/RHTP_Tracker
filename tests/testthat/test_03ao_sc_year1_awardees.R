# test_03ao_sc_year1_awardees.R ------------------------------------------------
#
# SOUTH CAROLINA. The tests that carry the weight here are the PARSE tests,
# because South Carolina's award list is the first document in this repository
# that publishes NO TOTAL OF ANY KIND -- no grand total, no subtotal, no Total
# row. Every other priced state could catch a dropped row by reconciling to a
# figure the publisher printed; here the sum of the rows IS the only total, so
# reconciling to it is circular and something else has to do that job.
#
# Three things do, and each is tested: the per-project 1..n numbering, CMS's
# independent count of 228 grants, and the y-band assembly refusing to emit a
# row with an empty name.

library(testthat)
suppressPackageStartupMessages({
  library(dplyr)
  library(here)
})

source(here::here("R", "03ao_sc_year1_awardees.R"))

skip_if_no_archive <- function() {
  testthat::skip_if_not(sc_have_archive(),
                        "data/evidence/SC is not present")
}


# -- the parse ---------------------------------------------------------------

test_that("the award list parses to 228 rows summing to $167,299,900.69", {
  skip_if_no_archive()
  d <- sc_parse_award_list()
  expect_equal(nrow(d), 228L)
  expect_equal(sum(d$amount), 167299900.69, tolerance = 1e-8)
  expect_equal(dplyr::n_distinct(d$initiative), 4L)
  expect_equal(dplyr::n_distinct(d$project), 8L)
  expect_equal(dplyr::n_distinct(d$awardee), 130L)
  expect_true(all(nzchar(d$awardee)))
  expect_true(all(d$amount > 0))
})

test_that("CMS independently states the same count, which is the corroboration", {
  skip_if_no_archive()
  cms <- sc_html_text("cms_release")
  expect_true(grepl("will support 228 grants", cms, fixed = TRUE))
  expect_equal(SC_CMS_GRANTS, nrow(sc_parse_award_list()))
  # And the headline rounds to the sum.
  expect_equal(round(sum(sc_parse_award_list()$amount) / 1e6), 167)
})

test_that("the awards are MADE, not intended, and the document is checked for it", {
  skip_if_no_archive()
  expect_silent(sc_assert_awards_are_made())
  txt <- paste(rhtp_pdf_text(sc_path("award_list")), collapse = " ")
  # §8's strongest source type rests on the ABSENCE of hedging language, so
  # the absence is tested rather than the title.
  for (tok in c("intent", "anticipated", "pending", "contingent",
                "subject to")) {
    expect_false(grepl(tok, txt, ignore.case = TRUE), info = tok)
  }
  aw <- sc_year1_awardees()
  expect_true(all(aw$validation_source_type == "NOTICE_OF_AWARD"))
  expect_true(all(aw$amount_confirmed == "Yes"))
  expect_true(all(aw$recipient_confirmed == "Yes"))
  # And NOTICE_OF_AWARD is in the controlled vocabulary (§8's source_doc_type).
  expect_true("NOTICE_OF_AWARD" %in% rhtp_vocabulary("source_doc_type"))
})


test_that("the document publishes no total of its own, which is why the numbering matters", {
  skip_if_no_archive()
  txt <- paste(rhtp_pdf_text(sc_path("award_list")), collapse = " ")
  # "Total Funding Amount" is a COLUMN HEADER, not a total. Nothing else in
  # the document is.
  expect_true(grepl("Total Funding Amount", txt, fixed = TRUE))
  expect_false(grepl("Total:", txt, fixed = TRUE))
  expect_false(grepl("Grand Total", txt, fixed = TRUE))
  expect_false(grepl("167,299,900", txt, fixed = TRUE))
})


# -- DEFECT 1: the malformed row number --------------------------------------

test_that("South Carolina prints one row number as 'I2', and the row is real", {
  skip_if_no_archive()
  d <- sc_parse_award_list()
  bad <- d[d$row_label == "I2", ]
  expect_equal(nrow(bad), 1L)
  expect_equal(bad$awardee, "Rebound Behavioral Health")
  expect_equal(bad$amount, 120000)
  expect_equal(bad$project, "Healthcare Workforce")
})

test_that("a parser keying on ^[0-9]+$ in the number column loses that row and $120,000", {
  skip_if_no_archive()
  runs <- sc_runs()
  # The counterfactual, driven: anchor rows on the NUMBER column instead of
  # the amount column, exactly as a first draft would.
  num <- runs[runs$x >= SC_NUM_X[1] & runs$x < SC_NUM_X[2] &
              grepl("^[0-9]+$", runs$t) &
              !grepl("^South Carolina Rural", runs$t) &
              runs$y > 90, ]
  # 228 real rows plus nothing; the "I2" row is simply absent from it.
  d <- sc_parse_award_list(runs)
  expect_lt(nrow(num), nrow(d))
  expect_equal(nrow(d) - nrow(num), 1L)
  # And the money that vanishes is exactly the recorded row's.
  expect_equal(sum(d$amount) - sum(d$amount[d$row_label != "I2"]), 120000)
})

test_that("the numbering check is what would catch a dropped row, per project", {
  skip_if_no_archive()
  d <- sc_parse_award_list()
  expect_silent(sc_assert_row_numbering(d))
  # Drop a row in the middle of the largest project and the check must fail.
  fe <- which(d$project == "Facility Enhancements")
  expect_error(sc_assert_row_numbering(d[-fe[45], ]),
               "does not number 1\\.\\.")
  # A NEW malformed label is refused rather than absorbed by a looser regex.
  d2 <- d; d2$row_label[fe[3]] <- "l3"
  expect_error(sc_assert_row_numbering(d2), "neither a number nor the one")
  # And the recorded defect DISAPPEARING is also a re-read, not a silent pass.
  d3 <- d; d3$row_label[d3$row_label == "I2"] <- "2"
  expect_error(sc_assert_row_numbering(d3), "is GONE from the award list")
})


# -- DEFECT 2: the hyphen, the spacing, and the three spellings ---------------

test_that("the spacing of every run boundary is measured from the PDF's own /Widths", {
  skip_if_no_archive()
  r <- sc_assert_no_positioning_space()
  expect_equal(r$space_units, 203)
  expect_gte(r$boundaries, 40L)
  # BOTH populations occur, or the measurement is not discriminating.
  expect_gt(r$n_unspaced, 0L)
  expect_gt(r$n_spaced, 0L)
  # AND THE SEPARATION IS THE POINT: the worst unspaced residual must sit far
  # below a space. It is kerning -- the /Widths array does not carry the
  # producer's pair adjustments -- and it is bounded at about a fifth of a
  # space.
  expect_lt(r$worst_unspaced, r$space_units / 2)
  expect_gt(r$closest_spaced, r$space_units / 2)
  expect_gt(r$closest_spaced - r$worst_unspaced, 100)
})

test_that("South Carolina spells one organisation three ways and none is merged", {
  skip_if_no_archive()
  d <- sc_parse_award_list()
  forms <- sc_assert_two_spellings(d)
  expect_equal(forms$rows[forms$form == "hyphen_no_space"], 17L)
  expect_equal(forms$rows[forms$form == "hyphen_space"], 1L)
  expect_equal(forms$rows[forms$form == "no_hyphen"], 1L)
  # The two that differ by ONE SPACE are both present, verbatim.
  expect_true("Prisma Health- Upstate (Anderson)" %in% d$awardee)
  expect_true("Prisma Health-Upstate (Oconee)" %in% d$awardee)
  # The same thing with the hyphen and the space swapped.
  expect_true(SC_AIKEN_SPACED %in% d$awardee)
  expect_true(SC_AIKEN_HYPHEN %in% d$awardee)
  # A FOURTH form must fail rather than be absorbed. The mutation keeps the
  # row COUNT at 19 on purpose, so it is the form check that fires and not the
  # count check standing in front of it.
  d2 <- d
  i <- which(d2$awardee == "Prisma Health-Upstate (Laurens)")[1]
  d2$awardee[i] <- "Prisma Health -Upstate (Laurens)"
  expect_error(sc_assert_two_spellings(d2), "spellings have moved")
  # And losing a row is caught too, by the count.
  expect_error(sc_assert_two_spellings(d[-i, ]), "expected 19 Prisma Health")
})

test_that("pasting runs with a separator would invent a space South Carolina did not print", {
  skip_if_no_archive()
  runs <- sc_runs()
  prisma <- runs[runs$page == 1 & abs(runs$y - 271.26) < 0.01 &
                 runs$x >= 96 & runs$x < 450, ]
  prisma <- prisma[order(prisma$x), ]
  # As painted: three CONTENT runs and no space run between them. (There is a
  # fourth run at the far right -- the producer's own padding space before the
  # amount column -- which trims away and is why the blank runs are kept in
  # the paste rather than filtered out of it.)
  expect_equal(trimws(prisma$text)[nzchar(trimws(prisma$text))],
               c("Prisma Health", "-", "Upstate (Oconee, Lee, and Laurens)"))
  expect_equal(trimws(paste(prisma$text, collapse = "")),
               "Prisma Health-Upstate (Oconee, Lee, and Laurens)")
  # The naive repair -- paste with a space -- invents a name the state never
  # printed, and would silently turn 130 awardee strings into fewer.
  expect_false(paste(trimws(prisma$text), collapse = " ") %in%
                 sc_parse_award_list()$awardee)
})

test_that("a run boundary that carries a real space keeps it", {
  skip_if_no_archive()
  runs <- sc_runs()
  self <- runs[runs$page == 7 & abs(runs$y - 200.58) < 0.01 &
               runs$x >= 96 & runs$x < 450, ]
  self <- self[order(self$x), ]
  # Three runs here too -- and the middle one IS a space.
  expect_true(any(self$text == " "))
  expect_equal(trimws(paste(self$text, collapse = "")),
               "Self Regional Healthcare (Lakelands Region)")
})


# -- DEFECT 3: the interleaved wrapped rows -----------------------------------

test_that("33 rows wrap their name and the line model cannot assemble them", {
  skip_if_no_archive()
  d <- sc_parse_award_list()
  expect_equal(sum(d$name_lines > 1L), 33L)
  expect_silent(sc_assert_line_model_cannot_read_this(d = d))
  # The producer paints a wrapped row's number and amount at the MIDPOINT of
  # the two name lines, giving four interleaved line ids.
  runs <- sc_runs()
  p8 <- runs[runs$page == 8 & runs$y > 450 & runs$y < 475 & nzchar(trimws(runs$text)), ]
  expect_true(dplyr::n_distinct(p8$line) >= 4L)
})

test_that("a wrapped name is assembled whole, not truncated to its first line", {
  skip_if_no_archive()
  d <- sc_parse_award_list()
  expect_true("McLeod Health on behalf of McLeod Health Dillon (MHD)" %in%
                d$awardee)
  expect_true("Medical University Hospital Authority (MUSC Health, Orangeburg)" %in%
                d$awardee)
  # The end-of-line hyphen must NOT gain a space across the wrap.
  expect_true(any(grepl("(Tri-County Community Mental Health Center)",
                        d$awardee, fixed = TRUE)))
  expect_false(any(grepl("(Tri- County", d$awardee, fixed = TRUE)))
})


# -- rows are not organisations ----------------------------------------------

test_that("228 award actions are 130 awardee strings and fewer organisations", {
  skip_if_no_archive()
  top <- sc_assert_rows_are_not_organisations()
  expect_equal(top$awardee[1], "Newberry County Memorial Hospital")
  expect_equal(top$rows[1], 12L)
  expect_equal(top$projects[1], 4L)
  expect_equal(top$rows[top$awardee == "Self Regional Healthcare (Lakelands Region)"], 11L)
  expect_equal(top$rows[top$awardee == "Hampton Regional Medical Center"], 10L)
  # And 130 is an UPPER BOUND: several bodies are spelled more than one way.
  d <- sc_parse_award_list()
  expect_true("Allendale County Hospital" %in% d$awardee)
  expect_true("Allendale County Hospital (ACH)" %in% d$awardee)
})


# -- §6.2 and the controls ----------------------------------------------------

test_that("the award list carries NO CMS footer at all", {
  skip_if_no_archive()
  txt <- paste(rhtp_pdf_text(sc_path("award_list")), collapse = " ")
  for (tok in c("Centers for Medicare", "financial assistance",
                "funded by CMS", "CMS")) {
    expect_false(grepl(tok, txt, fixed = TRUE), info = tok)
  }
  # What IS there is the programme's own name, on every page.
  expect_true(grepl("Rural Health Transformation", txt, fixed = TRUE))
  expect_silent(sc_assert_no_cms_footer())
})

test_that("the provenance is structural: the list's sections ARE the state's initiatives", {
  skip_if_no_archive()
  d <- sc_parse_award_list()
  expect_setequal(unique(d$initiative), SC_INITIATIVES)
  page <- sc_html_text("programme")
  for (ini in SC_INITIATIVES) {
    expect_true(grepl(ini, page, ignore.case = TRUE), info = ini)
  }
  # And the FIFTH initiative the page names is exactly the one absent.
  expect_true(grepl(SC_FIFTH_INITIATIVE, page, fixed = TRUE))
  expect_false(any(grepl(SC_FIFTH_INITIATIVE, d$initiative, fixed = TRUE)))
  expect_silent(sc_assert_provenance())
})

test_that("the date test passes with room", {
  expect_true(SC_APPLICATION_DUE > SC_NOA_DATE)
  expect_true(SC_ANTICIPATED_NOA_DATE > SC_NOA_DATE)
  expect_true(as.Date(SC_LIST_POSTED) > SC_ANTICIPATED_NOA_DATE)
  # And BOTH control programmes are disposed of by the same test.
  expect_true(SC_RMUA_AWARD_DATE < SC_NOA_DATE)
  expect_true(SC_BHCS_AWARD_DATE < SC_NOA_DATE)
})

test_that("both negative controls are real named rosters that are NOT RHTP", {
  skip_if_no_archive()
  rmua <- sc_html_text("rmua_control")
  expect_true(grepl("SCDHHS Awards $48.2 Million", rmua, fixed = TRUE))
  expect_true(grepl("Rural and Medically Underserved", rmua, fixed = TRUE))
  bhcs <- sc_html_text("bhcs_control")
  # THE ONE CARRYING HOSPITAL MONEY, on the RHTP page itself.
  expect_true(grepl("Grants to 13 South Carolina Hospitals", bhcs,
                    fixed = TRUE))
  expect_silent(sc_assert_controls())
})

test_that("the positive control fails in both directions", {
  skip_if_no_archive()
  expect_silent(sc_assert_award_index())
  page <- sc_html_text("programme")
  # A SECOND award list is the Tech Catalyst Fund landing, and must fail.
  faked <- paste(page, "SC RHTP Year 2 Award List")
  expect_error(sc_assert_award_index(body = charToRaw(faked)),
               "now carries 2 RHTP award lists")
})

test_that("the year is partial and the Tech Catalyst Fund is why", {
  skip_if_no_archive()
  expect_silent(sc_assert_tech_catalyst_pending())
  d <- sc_year1_awardees()
  expect_equal(sc_allotment() - sum(d$amount), 32730351.31, tolerance = 1e-6)
  st <- sc_status_table()
  expect_equal(st$stage[st$channel == "Tech Catalyst Fund"], "NOT_YET_OPENED")
})


# -- §8 / §10.2 ---------------------------------------------------------------

test_that("every recipient_type is reproducible from the NAME alone", {
  skip_if_no_archive()
  expect_silent(sc_assert_typed_from_the_name())
  # THE PROJECT NAME IS KEPT OUT ON PRINCIPLE, AND HERE IT IS MEASURED THAT IT
  # WOULD COST NOTHING EITHER WAY. Arkansas's project descriptions moved
  # eleven rows between flow codes and not one dollar (session 40); South
  # Carolina's eight project names are so generic -- "Facility Enhancements",
  # "Mobile Crisis Response" -- that they move NOTHING AT ALL, not even a flow
  # code. So the exclusion is §0.3a applied as a rule rather than as a repair,
  # and this test records which of the two it is.
  d <- sc_parse_award_list()
  aw <- sc_year1_awardees(d)
  with_project <- rhtp_classify_flow(aw$recipient_type, d$project,
                                     award_made = TRUE)
  expect_identical(with_project$flow_type, aw$flow_type)
  expect_identical(with_project$distributed_to_hospital,
                   aw$distributed_to_hospital)
  # Not one of the eight project names carries a hospital token, which is WHY.
  expect_false(any(grepl("hospital", unique(d$project), ignore.case = TRUE)))
})

test_that("nothing was promoted, and the refusal runs both ways", {
  skip_if_no_archive()
  aw <- sc_year1_awardees()
  expect_silent(sc_assert_nothing_promoted(aw))
  fb <- aw[which(aw$flag_reason == "RECIPIENT_TYPE_INFERRED"), ]
  expect_equal(nrow(fb), 150L)
  expect_true(all(fb$distributed_to_hospital == "No"))
  # UPWARD: the hospital systems this file did not promote.
  for (nm in c("Self Regional Healthcare (Lakelands Region)", "McLeod Health",
               "AnMed", "Tidelands Health")) {
    expect_true(all(aw$flag_reason[aw$awardee == nm] ==
                      "RECIPIENT_TYPE_INFERRED"), info = nm)
    expect_true(all(aw$distributed_to_hospital[aw$awardee == nm] == "No"),
                info = nm)
  }
  # DOWNWARD: SCDBHDD is the state's own department and is not re-typed either.
  scd <- aw[grepl("^SCDBHDD", aw$awardee), ]
  expect_equal(nrow(scd), 19L)
  expect_true(all(scd$flag_reason == "RECIPIENT_TYPE_INFERRED"))
})

test_that("promoting the fallback is priced rather than done", {
  skip_if_no_archive()
  aw <- sc_year1_awardees()
  fb <- aw[which(aw$flag_reason == "RECIPIENT_TYPE_INFERRED"), ]
  floor_d <- sum(aw$amount[aw$distributed_to_hospital == "Yes"])
  expect_equal(floor_d, 56587137.77, tolerance = 1e-6)
  expect_equal(sum(fb$amount), 92759791.23, tolerance = 1e-6)
  # THE COUNTERFACTUAL, DRIVEN: promoting every fallback row moves this much.
  expect_equal(floor_d + sum(fb$amount), 149346929.00, tolerance = 1e-6)
  # And the uncertainty EXCEEDS the floor, which is the sentence published.
  expect_gt(sum(fb$amount), floor_d)
})

test_that("the two MUSC spellings classify opposite ways and neither is repaired", {
  skip_if_no_archive()
  r <- sc_assert_musc_two_spellings()
  expect_equal(r$distributed_to_hospital, c("Yes", "No"))
  expect_equal(r$dollars[2], 3345533, tolerance = 1e-6)
  aw <- sc_year1_awardees()
  expect_true(all(aw$recipient_type[aw$awardee == SC_MUSC_UNIVERSITY] ==
                    "UNIVERSITY_OR_AHC"))
  expect_true(all(aw$recipient_type[aw$awardee == SC_MUSC_HOSPITAL_AUTHORITY] ==
                    "HOSPITAL_OR_SYSTEM"))
})

test_that("the unstated-form question is flagged in South Carolina's own files", {
  skip_if_no_archive()
  expect_silent(sc_assert_form_not_stated_flagged())
  st <- sc_status_table()
  row <- st[st$channel == SC_FORM_NOT_STATED_QUESTION, ]
  expect_equal(nrow(row), 1L)
  expect_equal(row$stage, "OPEN_QUESTION")
  expect_true(grepl("ONE-DIRECTIONAL", row$note, fixed = TRUE))
  # SESSION 47 KEPT IT OUT OF THE SHARED QUEUE while a verification pass ran in
  # a separate workbook, and session 50 answered it directly instead -- so it
  # STILL is not a `SC_RECIPIENT_FORM_NOT_STATED` row there. What South
  # Carolina does now have in the shared queue is the ONE judgement session 50
  # made rather than the question session 47 deferred: Acadia Healthcare Co.,
  # a hospital company awarded over a mixed estate. This test therefore pins
  # the narrower claim it was always making -- the deferred QUESTION did not
  # migrate -- rather than a blanket absence that is no longer true.
  q <- readr::read_csv(here::here("data/reference/classification_review_queue.csv"),
                       show_col_types = FALSE, progress = FALSE)
  expect_false(SC_FORM_NOT_STATED_QUESTION %in% q$question_id)
  sc_rows <- q[q$state == "SC", ]
  expect_equal(nrow(sc_rows), 1L)
  expect_equal(sc_rows$question_id, "SC_ACADIA_PARENT_SCOPE")
})


# -- the written artifacts ----------------------------------------------------

test_that("the status table has NO amount column", {
  st <- sc_status_table()
  expect_false("amount" %in% names(st))
  expect_false("round_amount" %in% names(st))
})

test_that("the RCJ candidate count is DERIVED, never typed", {
  skip_if_no_archive()
  n <- sc_rcj_candidate_count()
  rec <- readRDS(here::here("data/interim/stage2_record_table.rds"))
  expect_equal(n, sum(rec$state == "SC" & rec$award_tier == "SUBAWARD",
                      na.rm = TRUE))
  expect_equal(n, 0L)
  # South Carolina holds RCJ records; it holds no Tier 3 CANDIDATES. The
  # difference is what makes the zero a fact about the discovery layer.
  expect_gt(sum(rec$state == "SC", na.rm = TRUE), 0L)
})

test_that("--build writes what the report reads", {
  skip_if_no_archive()
  expect_true(file.exists(here::here("data/reference/sc_year1_awardees.csv")))
  csv <- readr::read_csv(here::here("data/reference/sc_year1_awardees.csv"),
                         show_col_types = FALSE, progress = FALSE)
  expect_equal(nrow(csv), 228L)
  expect_equal(sum(csv$amount), 167299900.69, tolerance = 1e-8)
  expect_true(all(is.na(csv$round_amount)))
})
