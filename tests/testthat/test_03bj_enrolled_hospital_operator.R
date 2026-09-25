# test_03bj_enrolled_hospital_operator.R ---------------------------------------
# Session 71: §10.2 "Academic health centers and enrolled hospital operators",
# and the determined-form check for OTHER. Offline, no quota.
#
# The weight sits on the LIMITS. The rule moves $63,240,239.84 into
# NAMED_HOSPITAL, so the tests that matter are the ones that fail if it reaches
# further than it says: a PREFIX is never matched (University of Alabama is not
# UAB), a row whose STATE source states another form is held, the different
# bodies with similar names stay where they are, and the overlay is idempotent.

library(testthat)
suppressMessages(source(here::here("R", "03bj_enrolled_hospital_operator.R")))
suppressMessages(source(here::here("R", "03ap_verification_queue_2.R")))

tabs <- eh_read_committed(unname(VQ_ALL_STATE_CSVS()))
eff  <- eh_effect(tabs)
sw   <- eh_sweep(tabs)

test_that("every sweep hit carries a hand-read verdict, and no EXACT verdict is stale", {
  expect_silent(eh_assert_read(sw))
  expect_equal(nrow(sw), 39L)
})

test_that("an unread sweep hit fails the build", {
  fake <- dplyr::bind_rows(sw, tibble::tibble(file = "x.csv", row = 1L,
                                              awardee = "Somewhere Hospital",
                                              recipient_type = "NONPROFIT_CBO",
                                              grade = "LEGAL", ccn = "999999",
                                              cms_org = "SOMEWHERE HOSPITAL"))
  expect_error(eh_assert_read(fake), "no hand-read")
})

test_that("33 rows / $63,240,239.84 moved, 25 / $53,539,221.31 of them AHCs", {
  expect_equal(nrow(eff), 33L)
  expect_equal(round(sum(eff$amount, na.rm = TRUE), 2), 63240239.84)
  ahc <- eff[!is.na(eff$subtype) & eff$subtype == "ACADEMIC_HEALTH_CENTER", ]
  expect_equal(nrow(ahc), 25L)
  expect_equal(round(sum(ahc$amount, na.rm = TRUE), 2), 53539221.31)
})

test_that("UAMS: four rows across both Arkansas rounds, CCN 040016, $17,060,066", {
  u <- eff[eff$awardee == "University of Arkansas for Medical Sciences", ]
  expect_equal(nrow(u), 4L)
  expect_true(all(u$ccn == "040016"))
  expect_equal(sum(u$amount), 17060066)
  expect_true(all(u$subtype == "ACADEMIC_HEALTH_CENTER"))
})

test_that("each re-typed row is HOSPITAL_OR_SYSTEM / DIRECT / Yes, with a six-character CCN", {
  for (f in names(tabs)) {
    d <- tabs[[f]]
    if (!"cms_enrolment_match" %in% names(d)) next
    k <- which(!is.na(d$cms_enrolment_match))
    expect_true(all(d$recipient_type[k] == "HOSPITAL_OR_SYSTEM"), info = f)
    expect_true(all(d$flow_type[k] == "DIRECT"), info = f)
    expect_true(all(d$distributed_to_hospital[k] == "Yes"), info = f)
    expect_true(all(nchar(d$ccn[k]) == 6L), info = f)
    conf <- d$determination_confidence[k]
    exact <- d$cms_enrolment_match[k] == "EXACT_LEGAL_NAME"
    expect_true(all(conf[exact] == "MEDIUM"), info = f)
    expect_true(all(conf[!exact] == "LOW"), info = f)
    # HIGH still needs Stage 5's CCN match; nothing here reaches it.
    expect_false(any(conf == "HIGH"), info = f)
    basis <- if ("determination_basis" %in% names(d)) d$determination_basis[k] else d$note[k]
    expect_true(all(grepl(EH_TAG, basis, fixed = TRUE)), info = f)
  }
})

test_that("a PREFIX is never matched: different bodies with similar names are untouched", {
  al <- tabs[["al_year1_awardees.csv"]]
  expect_true(all(al$recipient_type[al$awardee %in% c("The University of Alabama",
                                                       "University of Alabama")] ==
                    "UNIVERSITY_OR_AHC"))
  expect_true(all(al$recipient_type[al$awardee == "UAB Montgomery"] == "UNIVERSITY_OR_AHC"))
  ar <- tabs[["ar_year1_awardees.csv"]]
  expect_equal(ar$recipient_type[ar$awardee == "University of Arkansas"], "UNIVERSITY_OR_AHC")
  md <- tabs[["md_year1_awardees.csv"]]
  expect_equal(md$recipient_type[md$awardee == "Johns Hopkins University"], "UNIVERSITY_OR_AHC")
  sc <- tabs[["sc_year1_awardees.csv"]]
  expect_true(all(sc$recipient_type[sc$awardee == "Medical University of South Carolina"] ==
                    "UNIVERSITY_OR_AHC"))
  expect_false(any(sw$awardee %in% c("University of Alabama", "The University of Alabama",
                                     "University of Arkansas", "UAB Montgomery")))
})

test_that("rows whose STATE source states another form are HELD, not re-coded", {
  held <- sw %>% dplyr::semi_join(EH_HOLD, by = c("file", "awardee"))
  expect_equal(nrow(held), 10L)
  expect_false(any(held$recipient_type == "HOSPITAL_OR_SYSTEM"))
  q <- readr::read_csv(here::here("data/reference/classification_review_queue.csv"),
                       col_types = readr::cols(.default = "c"), show_col_types = FALSE)
  expect_equal(q$queue_status[q$question_id == "ENROLLED_HOSPITAL_STATE_STATED_OTHER_FORM"], "OPEN")
  expect_equal(q$queue_status[q$question_id == "AHC_ENROLLED_HOSPITAL_OPERATOR"], "RESOLVED")
})

test_that("the overlay is idempotent on the committed files", {
  for (f in EH_FILES()) {
    d <- eh_read_raw(f)
    expect_identical(s71_overlay(d, f, empty = eh_empty_token(d)), d, info = f)
  }
})

test_that("the partition: NAMED_HOSPITAL 1,185 / $1,022,314,842.52 / 30; pools unmoved", {
  tot <- vq_bucket_totals(vq_partition())
  n <- tot[tot$bucket == "NAMED_HOSPITAL", ]
  expect_equal(n$rows, 1185L)
  expect_equal(round(n$dollars, 2), 1022314842.52)
  expect_equal(n$states, 30L)
  expect_equal(round(tot$dollars[tot$bucket == "POOL_NAMED_HOSPITALS"], 2), 30806856.12)
  expect_equal(tot$dollars[tot$bucket == "POOL_UNNAMED_HOSPITALS"], 50008264)
  # A reader can subtract the AHC rows without re-coding anything.
  expect_equal(round(n$dollars - 53539221.31, 2), 968775621.21)
})

# -- Task 2 -----------------------------------------------------------------------

test_that("the five session-49 OTHER rows with no stated form are back on §8's fallback", {
  for (i in seq_len(nrow(EH_OTHER_WITHDRAWN))) {
    d <- tabs[[EH_OTHER_WITHDRAWN$file[i]]]
    k <- which(d$awardee == EH_OTHER_WITHDRAWN$awardee[i])
    expect_length(k, 1L)
    expect_equal(d$recipient_type[k], "NONPROFIT_CBO")
    expect_equal(d$determination_confidence[k], "LOW")
    expect_match(d$flag_reason[k], "RECIPIENT_TYPE_INFERRED", fixed = TRUE)
    expect_equal(d$distributed_to_hospital[k], "No")
    # session 49's answer is kept as the audit trail
    expect_false(is.na(d$verified_basis[k]))
  }
})

test_that("every OTHER row in the repository states a determined form", {
  rev <- other_form_review(tabs)
  expect_equal(nrow(rev), 113L)
  expect_silent(other_assert_forms(rev))
  expect_equal(sum(rev$form_source == "session 49 verified basis, form read session 71"), 35L)
})

test_that("OTHER with a bare name, or a basis that disclaims a form, fails", {
  rev <- other_form_review(tabs)
  bare <- rev[1, ]; bare$determined_form <- bare$awardee
  expect_error(other_assert_forms(bare), "state no determined form")
  none <- rev[1, ]; none$determined_form <- NA_character_
  expect_error(other_assert_forms(none), "state no determined form")
  dis <- rev[1, ]; dis$disclaims_form <- TRUE
  expect_error(other_assert_forms(dis), "state no determined form")
})

# -- Task 3 -----------------------------------------------------------------------

test_that("the seven requested states' hospital enrolment files are archived and verify", {
  man <- readLines(here::here("data/evidence/federal_records/2026-09-25/MANIFEST.txt"))
  for (s in c("AL", "OR", "IA", "MD", "WA", "UT", "NC")) {
    f <- here::here("data/evidence/federal_records/2026-09-25",
                    paste0("cms_hosp_enrollments_", s, ".json"))
    expect_true(file.exists(f), info = s)
    line <- grep(paste0("^cms_hosp_enrollments_", s, "\\.json \\|"), man, value = TRUE)
    expect_length(line, 1L)
    expect_equal(trimws(strsplit(line, "|", fixed = TRUE)[[1]][2]),
                 digest::digest(file = f, algo = "sha256"), info = s)
  }
})

test_that("the new codes are in the vocabulary", {
  v <- readr::read_csv(here::here("data/reference/vocabularies.csv"),
                       col_types = readr::cols(.default = "c"), show_col_types = FALSE)
  expect_true("ACADEMIC_HEALTH_CENTER" %in% v$allowed_value[v$column_name == "recipient_subtype"])
  expect_setequal(v$allowed_value[v$column_name == "cms_enrolment_match"],
                  c("EXACT_LEGAL_NAME", "LEGAL_NAME_TRUNCATED", "DBA_OF_LEGAL_ENTITY"))
  for (f in names(tabs)) {
    d <- tabs[[f]]
    if (!"recipient_subtype" %in% names(d)) next
    expect_true(all(stats::na.omit(d$recipient_subtype) == "ACADEMIC_HEALTH_CENTER"), info = f)
    expect_true(all(stats::na.omit(d$cms_enrolment_match) %in%
                      v$allowed_value[v$column_name == "cms_enrolment_match"]), info = f)
  }
})
