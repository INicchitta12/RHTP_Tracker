# test_03aj_wy_year1_awardees.R ----------------------------------------------
# Wyoming. Reads committed evidence off disk only -- no network, no quota.
#
# WEIGHTED TOWARDS THE TWO THINGS THAT COULD GO WRONG IN OPPOSITE DIRECTIONS.
#   (a) THE RUN MODEL. Six rows carry the recipient name in a separate painted
#       run, so a line-model read of Initiative 1.1 gives SIXTEEN hospitals and
#       $43,044,174 and orphans $5,156,000 IN SILENCE. The tests below DRIVE
#       that mistake rather than describing it.
#   (b) THE APPLICANT ROSTER. The same document names FIFTY-SIX applicants it
#       did not award, FORTY of them under Initiative 3.1 requesting $38,794,342
#       and mostly NAMED WYOMING HOSPITALS. The tests feed the file a faked
#       award and require it to refuse.

library(testthat)

source(here::here("R", "03aj_wy_year1_awardees.R"))

wy_rows <- wy_award_rows()


test_that("the archive matches its own manifest", {
  out <- wy_verify_manifest()
  expect_true(all(out$ok))
  expect_gte(nrow(out), 9L)
})


test_that("the ELEVENTH digest mechanism is absorbed, and it is TEXT-BORNE", {
  # health.wyo.gov's programme page plants a Gravity Forms ANTI-SPAM HONEYPOT
  # whose FIELD LABEL is drawn at random per render, and that label is in the
  # RENDERED WORDS rather than in an attribute or a script body -- so
  # tag-stripping, which absorbed every earlier mechanism this project has met,
  # does not reach it. The FIRST live probe reported the page CHANGED on that
  # one word out of 951, with nothing about Wyoming's programme changed.
  form <- paste("<p>contact us</p><label>Email</label>",
                "<span>This field is for validation purposes and should be",
                "left unchanged.</span>")
  other <- stringr::str_replace(form, ">Email<", ">Name<")
  expect_false(identical(form, other))
  expect_identical(wy_html_text(form), wy_html_text(other))
  expect_true(stringr::str_detect(wy_html_text(form), "<HONEYPOT>"))
  # and it does not eat ordinary text
  plain <- "<p>Wyoming approved $48,200,174 for Critical Access Hospitals.</p>"
  expect_equal(wy_html_text(plain),
               "Wyoming approved $48,200,174 for Critical Access Hospitals.")
})

test_that("the archived programme page still carries the honeypot sentence", {
  # If it goes, the normalisation is dead code and the probe is comparing
  # something else. Read the page before deleting either.
  raw <- paste(readLines(wy_path("programme"), warn = FALSE, encoding = "UTF-8"),
               collapse = "\n")
  expect_true(stringr::str_detect(
    raw,
    stringr::fixed("This field is for validation purposes and should be left unchanged")))
  expect_true(stringr::str_detect(wy_text("programme"), "<HONEYPOT>"))
})


# -- (a) THE RUN MODEL -------------------------------------------------------

test_that("six visual rows are painted as two runs, and the reader keeps them", {
  runs <- wy_runs()
  for (i in seq_len(nrow(WY_SPLIT_NAME_ROWS))) {
    r <- WY_SPLIT_NAME_ROWS[i, ]
    here_runs <- runs[runs$page == r$page & runs$yk == r$yk, ]
    expect_gt(dplyr::n_distinct(here_runs$line), 1L)
    # the run model still puts the name and the money on ONE visual row
    txt <- paste0(here_runs$text[order(here_runs$x)], collapse = "")
    expect_true(stringr::str_detect(txt, stringr::fixed(r$name_fragment)))
    expect_true(stringr::str_detect(txt, "\\$[0-9]"))
  }
})

test_that("the LINE MODEL loses two Initiative 1.1 rows, worth $5,156,000", {
  lines <- rhtp_pdf_lines(wy_path("approvals"))
  named <- lines[lines$page == 2L & lines$x < 300 &
                   stringr::str_detect(lines$text, "\\$[0-9]") &
                   !stringr::str_starts(lines$text, "Total"), ]
  orphan <- lines[lines$page == 2L & lines$x >= 300 &
                    stringr::str_detect(lines$text, "^[0-9]{2}-[0-9]{7}"), ]
  expect_equal(nrow(named), 19L)     # 21 applicants, less the 2 split rows
  expect_equal(nrow(orphan), 2L)
  # THE MISTAKE, DRIVEN. A name-keyed line read of 1.1 recovers 16 of the 18
  # approved hospitals and $43,044,174 -- and nothing about that output looks
  # wrong, because the two lost rows still exist with no name on them.
  src <- wy_source_rows()
  cah <- src[src$table_key == "cah", ]
  split <- cah[cah$y %in% c(1037L, 1121L), ]
  expect_equal(nrow(split), 2L)
  expect_equal(sum(split$approved_amount), WY_LINE_MODEL_LOSS)
  expect_equal(WY_CAH_APPROVED - WY_LINE_MODEL_LOSS, 43044174)
  expect_equal(sum(!is.na(cah$approved_amount)) - 2L, 16L)
})

test_that("wy_assert_line_model_splits_names() passes and prices the loss", {
  got <- wy_assert_line_model_splits_names()
  expect_equal(got$loss, WY_LINE_MODEL_LOSS)
  expect_equal(got$recovered_rows, 19L)
})

test_that("the line model also welds the name to the EIN", {
  # Even the rows it DOES recover need the run model to separate the two.
  lines <- rhtp_pdf_lines(wy_path("approvals"))
  p2 <- lines[lines$page == 2L & lines$x < 300, ]
  expect_true(any(stringr::str_detect(p2$text,
                                      "Hospital[^ ]*[0-9]{2}-[0-9]{7}")))
})


# -- the reconciliation ------------------------------------------------------

test_that("every table closes against its own total, the summary and §7.1", {
  got <- wy_assert_reconciles()
  expect_equal(nrow(got$per_initiative), 6L)
  expect_equal(got$summary_total, WY_SUMMARY_TOTAL)
  expect_lte(abs(WY_ALLOTMENT - got$summary_total), 1)
})

test_that("the six initiative totals are the published figures", {
  init <- wy_initiative_approved()
  want <- c(
    "1.1 Critical Access Hospital - Basic"        = 48200174,
    "1.2 EMS Regionalization"                     = 23260000,
    "2.2 Physician GME"                           = 17712410,
    "3.1 Technology Adoption Challenge"           = 12652243,
    "4.1 Integrated Primary Care"                 = 30465504.74,
    "4.2 Clinically-Integrated Care Coordination" = 3218160)
  for (nm in names(want)) {
    expect_equal(init$approved[init$initiative == nm], unname(want[[nm]]),
                 info = nm)
  }
})

test_that("the file's own totals hold", {
  expect_equal(nrow(wy_rows), 77L)
  expect_equal(sum(wy_rows$amount, na.rm = TRUE), 173859751.74)
  expect_equal(sum(wy_rows$award_source == "APPROVALS_TABLE"), 75L)
  expect_equal(sum(wy_rows$award_source == "MINUTES_MOTION"), 2L)
  rec <- wy_reconcile(wy_rows)
  expect_equal(rec$unnamed_total, WY_NAMES_NOBODY)
  expect_lte(abs(rec$grand_total - WY_SUMMARY_TOTAL), 1)
})

test_that("the designated administrator is `Unclear` -- FHC's answer, not ICAHN's", {
  # $38,618,260, Wyoming's largest single recipient, and it is in the award file
  # because the motion calls WIP the "master fiscal agent" -- MISSOURI'S HUB
  # ANCHORS ARE THE PRECEDENT THAT DECIDES IT, and they are out of Missouri's
  # award file because DSS said its anchors "will not act as the fiscal agent".
  expect_silent(wy_assert_administrator_is_unresolved(wy_rows))
  admin <- wy_rows[wy_rows$award_source == "MINUTES_MOTION", ]
  expect_equal(nrow(admin), 2L)
  expect_equal(sum(admin$amount), WY_ADMINISTRATOR_TOTAL)
  expect_true(all(admin$flow_type == "PASS_THROUGH_UNRESOLVED"))
  expect_true(all(admin$distributed_to_hospital == "Unclear"))
  expect_true(all(admin$hospital_attribution == "NOT_HOSPITAL"))
  # NEITHER bucket: coding it ICAHN's way would move $38,618,260
  part <- rhtp_hospital_dollar_partition(wy_rows)
  expect_false(any(part$bucket %in% c("POOL_NAMED_HOSPITALS",
                                      "POOL_UNNAMED_HOSPITALS")))
  # TWO Wyoming documents name it, which is why it is an award row at all
  expect_true(stringr::str_detect(
    wy_text("minutes"),
    stringr::fixed("sole-source a master fiscal agent contract with the Wyoming Innovation Partnership (WIP)")))
  expect_true(stringr::str_detect(
    wy_text("approvals"), stringr::fixed("Sole-source contract with WIP")))
  # and the sentence that makes it Unclear rather than Yes
  expect_true(stringr::str_detect(
    wy_text("minutes"),
    stringr::fixed("statewide individual and institutional workforce/nursing grants")))
})

test_that("`round_amount` must never be summed", {
  got <- wy_assert_round_amount_not_summable(wy_rows)
  expect_gt(got$naive, got$correct * 5)      # it over-states by an order
})


# -- §6.2 --------------------------------------------------------------------

test_that("the CMS footer is the STRONG form and its figure IS the allotment", {
  expect_silent(wy_assert_footer_is_the_allotment())
  # §0.2 / session 37: the machine rule REFUSES a SOLICITATION declaration
  # within $10,000 of the anchor. Wyoming's footer is $205,004,742.95 against a
  # $205,004,743 anchor -- five cents apart.
  expect_error(
    rhtp_assert_footer_not_allotment(WY_NOA_AMOUNT, WY_STATE, "SOLICITATION",
                                     label = "a faked Tier 2 declaration"),
    "§0.2")
})

test_that("CMS's own Notice of Award is here and is a Revision (Budget)", {
  expect_silent(wy_assert_noa())
})

test_that("the date test is keyed on the BUDGET PERIOD, not the Federal Award Date", {
  expect_silent(wy_assert_after_noa())
  expect_equal(as.integer(WY_NOA_FEDERAL_DATE - WY_NOA_DATE), 136L)
  # Session 36's pin, a fifth time: keying on the later field would read a
  # 2026-08-11 approval as being only 89 days after the award instead of 225,
  # and every state NOA so far that is a revision carries a wider gap than the
  # last. The minutes give the later date from the other side.
  expect_true(stringr::str_detect(
    wy_text("minutes"),
    stringr::fixed("Wyoming executed its formal agreement with CMS on May 14, 2026")))
})


# -- the recipient typing ----------------------------------------------------

test_that("1.1's form is STATED by Wyoming, and §8's name rule alone misses three", {
  cah <- wy_rows[wy_rows$award_pool == "1.1 Critical Access Hospital - Basic", ]
  expect_equal(nrow(cah), 18L)
  expect_true(all(cah$recipient_type == "HOSPITAL_OR_SYSTEM"))
  expect_true(all(cah$distributed_to_hospital == "Yes"))
  # THE THREE THE NAME RULE MISSES, DRIVEN.
  missed <- c("Powell Valley Health Care Inc", "Cody Regional Health",
              "Crook County Medical Services District")
  naive <- rhtp_classify_recipient_type(missed, WY_STATE)
  expect_true(all(naive$recipient_type == "NONPROFIT_CBO"))
  expect_equal(sum(cah$amount[cah$awardee %in% missed]), 7525331)
  # and the source that settles it is still in the document
  expect_silent(wy_assert_eligible_classes())
})

test_that("1.2's hospitals are joined on the EIN and never on the name", {
  ems <- wy_rows[wy_rows$award_pool == "1.2 EMS Regionalization", ]
  expect_equal(nrow(ems), 11L)
  hosp <- ems[ems$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(hosp), 5L)
  expect_equal(sum(hosp$amount), 11000000)
  # four of the five carry an EIN Wyoming itself lists in the 1.1 hospital
  # table; the fifth (Sheridan) is a hospital on its NAME, under a DIFFERENT EIN
  src <- wy_source_rows()
  cah_eins <- unique(stats::na.omit(src$ein[src$table_key == "cah"]))
  expect_equal(sum(hosp$ein %in% cah_eins), 4L)
  expect_equal(hosp$awardee[!hosp$ein %in% cah_eins], "Sheridan Memorial Hospital")
  eins <- wy_assert_sheridan_two_eins()
  expect_false(identical(unname(eins[["cah"]]), unname(eins[["ems"]])))
})

test_that("4.1's class is stated by WDH's own disqualification", {
  pc <- wy_rows[wy_rows$award_pool == "4.1 Integrated Primary Care", ]
  expect_equal(nrow(pc), 8L)
  expect_true(all(pc$recipient_type == "FQHC_OR_RHC"))
  expect_true(all(pc$distributed_to_hospital == "No"))
  expect_true(stringr::str_detect(wy_text("approvals"),
                                  stringr::fixed(WY_PRIMARY_CARE_CLASS)))
})

test_that("the two rows that name nobody carry no amount, and the classifier would err", {
  expect_silent(wy_assert_unnamed_rows_have_no_amount(wy_rows))
  # DRIVE IT: handed the sentence, the shared classifier returns a determined
  # TRIBAL_ORG at HIGH confidence -- §6.1's programme-name-as-awardee hazard.
  naive <- rhtp_classify_recipient_type(WY_NO_BIDDERS, WY_STATE)
  expect_equal(naive$recipient_type, "TRIBAL_ORG")
  expect_equal(naive$determination_confidence, "HIGH")
  un <- wy_rows[wy_rows$awardee == WY_NO_BIDDERS, ]
  expect_true(all(is.na(un$amount)))
  expect_equal(sum(un$round_amount), 267000)
})


# -- (b) THE APPLICANT ROSTER ------------------------------------------------

test_that("the 56 unawarded applicants are out of the award file", {
  got <- wy_assert_denied_not_awarded(wy_rows)
  expect_equal(got$unawarded, WY_UNAWARDED_TOTAL)
  expect_equal(got$tech_requested, WY_TECH_UNAWARDED_REQUESTED)
})

test_that("reading Initiative 3.1's table as a roster is $38.8M of §0.3", {
  src <- wy_source_rows()
  tech <- src[src$table_key == "tech", ]
  expect_equal(nrow(tech), 50L)
  expect_equal(sum(!is.na(tech$approved_amount)), 10L)
  unaw <- tech[is.na(tech$approved_amount), ]
  expect_equal(nrow(unaw), 40L)
  # and they are mostly NAMED WYOMING HOSPITALS
  hospitalish <- unaw$awardee[stringr::str_detect(
    unaw$awardee, "Hospital|Memorial|Health Care|Medical")]
  expect_gte(length(hospitalish), 20L)
  expect_true("Sheridan Memorial Hospital" %in% unaw$awardee)
  expect_true("Ivinson Memorial Hospital" %in% unaw$awardee)
  # AND THE SAME ORGANISATION APPEARS ON BOTH SIDES, WHICH IS WHY THE CHECK
  # CANNOT BE A NAME CHECK. Riverton Memorial Hospital dba SageWest Health and
  # Memorial Hospital of Laramie County each hold an awarded 3.1 row AND
  # unawarded ones -- one applicant, several applications. The guard is on the
  # ROW, and the award file carries exactly the ten rows with an approved
  # amount.
  awarded_31 <- wy_rows$awardee[wy_rows$award_pool == WY_TECH$initiative]
  expect_equal(length(awarded_31), 10L)
  both <- intersect(awarded_31, unaw$awardee)
  expect_gt(length(both), 0L)
  expect_gte(sum(tech$awardee %in% both & !is.na(tech$approved_amount)),
             length(both))
})

test_that("the three Banner late submissions stay out, by (table, name) pair", {
  # The pair and not the name: Memorial Hospital of Converse County is AWARDED
  # under 1.1 and 1.2 while being turned down under 2.2 and 3.1.
  src <- wy_source_rows()
  banner <- src[src$table_key == "cah" & src$ein == "94-2545356", ]
  expect_equal(nrow(banner), 3L)
  expect_true(all(is.na(banner$approved_amount)))
  expect_equal(intersect(
    wy_rows$awardee[wy_rows$award_pool == "1.1 Critical Access Hospital - Basic"],
    banner$awardee), character(0))
  converse <- "Memorial Hospital of Converse County"
  expect_true(converse %in% wy_rows$awardee)
  # turned down THREE times -- once under 2.2 and twice under 3.1
  expect_equal(sum(src$awardee == converse & is.na(src$approved_amount)), 3L)
  expect_equal(sort(unique(src$table_key[src$awardee == converse &
                                           is.na(src$approved_amount)])),
               c("gme", "tech"))
})

test_that("the two 18s are not the same 18", {
  expect_silent(wy_assert_two_different_eighteens())
  n <- wy_text("narrative")
  block <- stringr::str_match(
    n, "Critical Access Hospital \\(18 Total\\)(.*?)Rural Health Transformation in Wyoming")[, 2]
  for (nm in WY_ELIGIBLE_NOT_APPROVED) {
    expect_true(stringr::str_detect(block, stringr::fixed(nm)), info = nm)
  }
  cah <- wy_rows$awardee[wy_rows$award_pool == "1.1 Critical Access Hospital - Basic"]
  for (nm in WY_APPROVED_NOT_ELIGIBLE) {
    expect_true(any(stringr::str_detect(cah, stringr::fixed(nm))), info = nm)
  }
})


# -- the minutes -------------------------------------------------------------

test_that("the minutes corroborate five figures and DISAGREE on one", {
  got <- wy_assert_minutes_corroborate()
  expect_equal(got$table, 9255398.00)
  expect_equal(got$minutes, 9225398)
  # the TABLE's figure is what sums to the total both documents state
  expect_equal(got$table_sum, 17712410)
  expect_equal(got$minutes_sum, 17682410)
  expect_false(isTRUE(all.equal(got$minutes_sum, got$table_sum)))
})

test_that("every row is an intent, and the deadline is in the future of it", {
  expect_equal(nrow(wy_rows), 77L)
  expect_silent(wy_assert_intent_not_award(wy_rows))
  expect_true(all(wy_rows$validation_source_type == "NOTICE_OF_INTENT_TO_AWARD"))
  expect_true(all(wy_rows$amount_confirmed == "No"))
  expect_true(all(stringr::str_detect(wy_rows$flag_reason, "AMOUNT_PRELIMINARY")))
  # NO NEW VOCABULARY CODE WAS INVENTED (§2)
  allowed <- rhtp_vocabulary("flag_reason")
  codes <- unique(unlist(strsplit(wy_rows$flag_reason, ";")))
  expect_equal(setdiff(codes, allowed), character(0))
})


# -- §0.4 --------------------------------------------------------------------

test_that("nothing was promoted, and the counterfactual is priced", {
  got <- wy_assert_nothing_promoted(wy_rows)
  expect_equal(got$fallback_rows, WY_FORM_NOT_STATED_ROWS)
  expect_equal(got$fallback_dollars, WY_FORM_NOT_STATED_DOLLARS)
  part <- rhtp_hospital_dollar_partition(wy_rows)
  named <- part[part$bucket == "NAMED_HOSPITAL" & part$state == "WY", ]
  expect_equal(named$rows, WY_NAMED_HOSPITAL_ROWS)
  expect_equal(named$dollars, WY_NAMED_HOSPITAL_DOLLARS)
  # PRICE THE COUNTERFACTUAL. Promoting "Powell Valley Health Care" in
  # Initiative 3.1 on the strength of "Powell Valley Health Care Inc" in
  # Initiative 1.1 -- the fuzzy match §2 forbids a machine making -- would add
  # $752,302 and two rows.
  pv <- wy_rows[wy_rows$awardee == "Powell Valley Health Care", ]
  expect_equal(nrow(pv), 2L)
  expect_equal(sum(pv$amount), 752302)
  expect_true(all(pv$distributed_to_hospital == "No"))
  # and Campbell County Health's EMS award is the other refusal, $1,700,000
  cc <- wy_rows[stringr::str_starts(wy_rows$awardee, "Campbell County Health"), ]
  expect_equal(nrow(cc), 1L)
  expect_equal(cc$amount, 1700000)
  expect_equal(cc$distributed_to_hospital, "No")
})

test_that("both Wyoming questions are in the review queue", {
  expect_silent(wy_assert_form_not_stated_queued())
  q <- readr::read_csv(
    here::here("data", "reference", "classification_review_queue.csv"),
    show_col_types = FALSE, progress = FALSE)
  wy <- q[q$question_id %in% WY_QUEUE_KEYS, ]
  expect_equal(nrow(wy), 2L)
  expect_true(all(wy$state == "WY"))
  expect_true(all(wy$queue_status == "OPEN"))
})


# -- the controls and the status table ---------------------------------------

test_that("the controls hold", {
  expect_silent(wy_assert_controls())
  st <- wy_status_table()
  expect_equal(nrow(st), 15L)
  expect_false("amount" %in% names(st))
  expect_equal(sum(st$stage == "APPROVED_ROSTER_PUBLISHED"), 6L)
  expect_equal(sum(st$stage == "APPROVED_TO_NAMED_ADMINISTRATOR_NO_SUBRECIPIENT"), 2L)
  expect_equal(sum(st$initiative_approved_award[
    st$stage == "APPROVED_AT_POOL_LEVEL_NO_ROSTER"]), WY_NAMES_NOBODY)
  expect_equal(sum(st$initiative_approved_award[
    st$stage == "APPROVED_TO_NAMED_ADMINISTRATOR_NO_SUBRECIPIENT"]),
    WY_ADMINISTRATOR_TOTAL)
})

test_that("Wyoming carries ZERO Tier 3 candidates and FIVE Utah records", {
  disp <- wy_rcj_disposition()
  expect_equal(nrow(disp), 3L)
  expect_true("WRONG_STATE_UTAH_FILED_UNDER_WYOMING" %in% disp$disposition_code)
  expect_equal(disp$records[disp$disposition_code ==
                              "WRONG_STATE_UTAH_FILED_UNDER_WYOMING"], 5L)
  expect_equal(disp$records[disp$disposition_code ==
                              "NO_TIER_3_CANDIDATE_AT_ALL"], 29L)
})

test_that("all assertions pass together", {
  expect_silent(wy_assert_all())
})
