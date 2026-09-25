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
  # Session 72: resolved at option (a) -- the state's stated form stands.
  expect_equal(q$queue_status[q$question_id == "ENROLLED_HOSPITAL_STATE_STATED_OTHER_FORM"], "RESOLVED")
  expect_match(q$resolution[q$question_id == "ENROLLED_HOSPITAL_STATE_STATED_OTHER_FORM"],
               "^Option \\(a\\)")
  expect_equal(q$queue_status[q$question_id == "AHC_ENROLLED_HOSPITAL_OPERATOR"], "RESOLVED")
})

test_that("session 72: each held row RECORDS its CMS enrolment and is not re-typed by it", {
  for (i in seq_len(nrow(EH_HOLD))) {
    d <- tabs[[EH_HOLD$file[i]]]
    k <- which(d$awardee == EH_HOLD$awardee[i] & d$recipient_type != "HOSPITAL_OR_SYSTEM")
    expect_gte(length(k), 1L)
    rec <- d$cms_enrolment_record[k]
    expect_true(all(grepl(paste0("CCN ", EH_HOLD$ccn[i]), rec, fixed = TRUE)), info = EH_HOLD$awardee[i])
    expect_true(all(grepl("RECORDED, NOT APPLIED", rec, fixed = TRUE)), info = EH_HOLD$awardee[i])
    expect_true(all(grepl("federal_records/", rec, fixed = TRUE)), info = EH_HOLD$awardee[i])
    # 'match' and 'ccn' mean re-typed on the enrolment; neither is set here.
    expect_true(all(is.na(d$cms_enrolment_match[k])), info = EH_HOLD$awardee[i])
    expect_true(all(is.na(d$ccn[k])), info = EH_HOLD$awardee[i])
    expect_true(all(d$distributed_to_hospital[k] == "No"), info = EH_HOLD$awardee[i])
    expect_true(all(grepl(EH_HOLD_TAG, d$determination_basis[k], fixed = TRUE)),
                info = EH_HOLD$awardee[i])
  }
  ak <- tabs[["ak_year1_awardees.csv"]]
  expect_equal(sum(grepl(EH_HOLD_TAG, ak$determination_basis, fixed = TRUE)), 4L)
  or <- tabs[["or_year1_awardees.csv"]]
  expect_equal(sum(grepl(EH_HOLD_TAG, or$determination_basis, fixed = TRUE)), 6L)
  # the state's own 'Hospital' projects for BBAHC/ANTHC are untouched
  expect_false(any(grepl(EH_HOLD_TAG, ak$determination_basis[ak$recipient_type == "HOSPITAL_OR_SYSTEM"],
                         fixed = TRUE)))
})

test_that("a held CCN that disagrees with the sweep fails the build", {
  bad <- sw
  k <- which(bad$awardee == EH_HOLD$awardee[1] & bad$file == EH_HOLD$file[1])
  bad$ccn[k] <- "999999"
  expect_error(eh_assert_read(bad), "EH_HOLD CCN")
})

test_that("session 72: AltaPointe is owner-accepted on its enrolment, reasoning on each row", {
  al <- tabs[["al_year1_awardees.csv"]]
  k <- which(al$awardee %in% c("AltaPointe Health Systems", "AltaPointe Health Systems Inc."))
  expect_length(k, 3L)
  expect_true(all(al$recipient_type[k] == "HOSPITAL_OR_SYSTEM"))
  expect_true(all(al$ccn[k] == "014014"))
  expect_equal(sum(as.numeric(al$amount[k])), 3602968)
  expect_true(all(grepl("OWNER-ACCEPTED (session 72)", al$determination_basis[k], fixed = TRUE)))
  q <- readr::read_csv(here::here("data/reference/classification_review_queue.csv"),
                       col_types = readr::cols(.default = "c"), show_col_types = FALSE)
  expect_equal(q$queue_status[q$question_id == "ALTAPOINTE_ENROLLED_OPERATOR"], "RESOLVED")
})

test_that("session 72: UMMS matches NO CMS hospital enrolment on its own legal name", {
  md <- jsonlite::fromJSON(here::here("data/evidence/federal_records/2026-09-25/cms_hosp_enrollments_MD.json"))
  expect_equal(nrow(md), 57L)
  names_all <- toupper(c(md[["ORGANIZATION NAME"]], md[["DOING BUSINESS AS NAME"]]))
  expect_false(any(grepl("MARYLAND MEDICAL SYSTEM", names_all, fixed = TRUE)))
  # its hospitals enrol as separate legal bodies
  expect_true("UNIVERSITY OF MARYLAND MEDICAL CENTER, LLC" %in% md[["ORGANIZATION NAME"]])
  expect_false(any(sw$awardee == "University of Maryland Medical System"))
  mdr <- tabs[["md_year1_awardees.csv"]]
  # Session 73 typed it HOSPITAL_OR_SYSTEM on its OWN stated form (R/03bk),
  # never on an enrolment: ccn stays empty and 03bj's sweep still misses it.
  u <- mdr[mdr$awardee == "University of Maryland Medical System", ]
  expect_equal(u$recipient_type, "HOSPITAL_OR_SYSTEM")
  expect_true(is.na(u$ccn) || !nzchar(u$ccn))
  q <- readr::read_csv(here::here("data/reference/classification_review_queue.csv"),
                       col_types = readr::cols(.default = "c"), show_col_types = FALSE)
  r <- q[q$question_id == "AHC_STRING_NAMES_NO_ENROLLED_ENTITY", ]
  expect_equal(r$queue_status, "OPEN")
  expect_match(r$why_it_is_open, "UMMS CHECKED AGAINST ITS OWN LEGAL NAME", fixed = TRUE)
})

test_that("the overlay is idempotent on the committed files", {
  for (f in EH_FILES()) {
    d <- eh_read_raw(f)
    expect_identical(s71_overlay(d, f, empty = eh_empty_token(d)), d, info = f)
  }
})

test_that("the partition: NAMED_HOSPITAL 1,186 / $1,026,334,986.52 / 30; pools unmoved", {
  tot <- vq_bucket_totals(vq_partition())
  n <- tot[tot$bucket == "NAMED_HOSPITAL", ]
  # Session 73: + UMMS (R/03bk), 1 row / $4,020,144, on its own stated form.
  expect_equal(n$rows, 1186L)
  expect_equal(round(n$dollars, 2), 1026334986.52)
  n$dollars <- n$dollars - 4020144
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
