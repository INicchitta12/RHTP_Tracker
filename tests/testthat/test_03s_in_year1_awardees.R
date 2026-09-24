# test_03s_in_year1_awardees.R ------------------------------------------------
# Indiana Year 1. Reads committed archives only -- no network, no quota.
#
# WHAT THIS FILE IS DEFENDING.
#
#   1. §0.1 AT ITS WORST RATIO IN THE PROJECT. Six of RCJ's 37 Indiana Tier 3
#      candidates are RHTP award rows; thirty are unrelated state procurement,
#      and RCJ reaches them by APPENDING an RHTP label the documents do not
#      carry -- "Indiana Negotiated Bid 26-87613 For Hydraulic Trail Trailer
#      Purchase RHTP 2026 Award Announcement" is a trailer. An extractor built
#      from the candidate list would have published ~$147M of 988 crisis
#      lines, disability determination, a tobacco quitline and a fuel cost
#      analysis as Indiana's RHTP subawards. The disposition arithmetic is
#      derived from the record table on every run and must close at 37.
#
#   2. THE PROVENANCE IS NOT ON THE AWARD DOCUMENT. Two of the five
#      solicitations (26-87556 Preceptor Registry, 26-87667 ACO Feasibility)
#      say "RHTP" nowhere in their IDOA title or their award letter. They are
#      RHTP because their SCOPE OF WORK carries the CMS financial-assistance
#      footer. Keyed on the award letter alone both would be dropped -- so the
#      footer is asserted on all five, against the §7.1 allotment.
#
#   3. THE POSITIVE CONTROL, AND ITS RATIO. IDOA's register is a GENERAL
#      procurement register -- 456 award recommendations covering road salt and
#      dumpsters, of which four are RHTP. That ratio is the whole reason "IDOA
#      published an award recommendation" is not evidence of RHTP, and it is
#      asserted in both directions: the register must stay large and general,
#      and a fifth RHTP row is a failure because Indiana would have awarded
#      something this file does not carry.
#
#   4. §0.3 ON THE REGIONAL GRANTS PAGE, WHICH IS THE BIGGEST TRAP THIS
#      PROJECT HAS MET. Fifteen tables of named people against named hospitals
#      that are ADVISORY COMMITTEE MEMBERS, and an eight-row per-region dollar
#      table that is a CAPITAL EXPENDITURE CEILING. Neither may enter the award
#      rows. And the programme itself -- $120M/yr across eight coalitions --
#      had not awarded when this file was built; the day it does, Indiana
#      becomes a major hospital-dollar state and this file is incomplete.
#
#   5. THE PROPOSER LIST INSIDE THE ONE DOCUMENT THAT NAMES AN AMOUNT. The
#      2026-08-21 letter lists SEVEN proposers and selects ONE. Deloitte is on
#      it as an UNSUCCESSFUL proposer and is separately a genuine awardee on a
#      DIFFERENT solicitation -- the two must never merge.
#
#   6. NOT ONE RECIPIENT IS A HOSPITAL, and every row is a PRELIMINARY
#      recommendation rather than an executed award. Both are findings about
#      Indiana, so both are pinned rather than assumed.

library(testthat)

source(here::here("R", "03s_in_year1_awardees.R"))

IN_TEST_AWARDS <- in_build_awards()


# -- the award table ----------------------------------------------------------

test_that("Indiana publishes seven award actions across five solicitations", {
  expect_equal(nrow(IN_TEST_AWARDS), 7L)
  expect_equal(dplyr::n_distinct(IN_TEST_AWARDS$awardee), 7L)
  expect_equal(dplyr::n_distinct(IN_TEST_AWARDS$solicitation_number), 5L)
  expect_setequal(IN_TEST_AWARDS$solicitation_number,
                  c("26-87448", "26-87448", "26-87448", "26-87449",
                    "26-87450", "26-87556", "26-87667"))
})

test_that("NOT ONE Indiana recipient is a hospital, and no dollar reaches one", {
  expect_true(all(IN_TEST_AWARDS$distributed_to_hospital == "No"))
  expect_true(all(IN_TEST_AWARDS$hospital_attribution == "NOT_HOSPITAL"))
  expect_false(any(IN_TEST_AWARDS$recipient_type == "HOSPITAL_OR_SYSTEM"))
  expect_silent(in_assert_no_hospital_dollars())

  # And the partition agrees: Indiana contributes nothing to either bucket.
  part <- rhtp_hospital_dollar_partition(IN_TEST_AWARDS)
  expect_true(all(part$dollars == 0) || nrow(part) == 0L)
})

test_that("exactly one amount is published, and it is a FIVE-YEAR figure", {
  priced <- IN_TEST_AWARDS[!is.na(IN_TEST_AWARDS$amount), ]
  expect_equal(nrow(priced), 1L)
  expect_equal(priced$awardee, "Laurel Health Advisors LLC")
  expect_equal(priced$amount, 860088)
  expect_equal(priced$amount_basis, "5-year contract value")
  expect_true(grepl("AMOUNT_IS_MULTI_YEAR_TOTAL", priced$flag_reason))

  # The other six are EMPTY, not zero: a zero would sum as a published figure.
  unpriced <- IN_TEST_AWARDS[is.na(IN_TEST_AWARDS$amount), ]
  expect_equal(nrow(unpriced), 6L)
  expect_true(all(grepl("AMOUNT_MISSING", unpriced$flag_reason)))
  expect_equal(sum(IN_TEST_AWARDS$amount, na.rm = TRUE), 860088)
})

test_that("every row is preliminary, not executed", {
  expect_true(all(IN_TEST_AWARDS$validation_source_type ==
                    "NOTICE_OF_INTENT_TO_AWARD"))
  expect_true(all(IN_TEST_AWARDS$amount_confirmed == "No"))
  expect_true(all(IN_TEST_AWARDS$recipient_confirmed == "Yes"))
  expect_silent(in_assert_not_executed())
})

test_that("the file unions on Florida's leading columns with §8 values only", {
  leading <- c("state", "row_no", "awardee", "amount", "recipient_type",
               "distributed_to_hospital", "note", "recipient_confirmed",
               "amount_confirmed", "fiscal_year", "source_document_title",
               "state_source_url", "validation_source_type",
               "extraction_method", "validator", "ccn", "aha_id",
               "rural_designation", "reviewer")
  expect_equal(names(IN_TEST_AWARDS)[seq_along(leading)], leading)

  # The column is `validation_source_type` in Florida's schema and the
  # vocabulary that governs it is keyed `source_doc_type` (§8) -- so the pair
  # is mapped explicitly rather than assumed to share a name.
  vocab_for <- c(recipient_type = "recipient_type",
                 distributed_to_hospital = "distributed_to_hospital",
                 flow_type = "flow_type",
                 hospital_attribution = "hospital_attribution",
                 validation_source_type = "source_doc_type",
                 determination_confidence = "determination_confidence",
                 recipient_confirmed = "recipient_confirmed",
                 amount_confirmed = "amount_confirmed",
                 hospital_benefiting = "hospital_benefiting",
                 extraction_method = "extraction_method")
  for (col in names(vocab_for)) {
    allowed <- rhtp_vocabulary(vocab_for[[col]])
    expect_true(all(IN_TEST_AWARDS[[col]] %in% allowed),
                info = paste(col, "has a value outside §8"))
  }
  # Every flag code is in the vocabulary, including the one added this session.
  flags <- unique(unlist(strsplit(IN_TEST_AWARDS$flag_reason, ";")))
  expect_true(all(flags %in% rhtp_vocabulary("flag_reason")))
  expect_true("AMOUNT_IS_MULTI_YEAR_TOTAL" %in% rhtp_vocabulary("flag_reason"))
})


# -- §6.2 provenance ----------------------------------------------------------

test_that("all five solicitations carry the CMS footer matching §7.1", {
  expect_silent(in_assert_rhtp_funded())
  a <- readr::read_csv(IN_ALLOTMENT_SOURCE, show_col_types = FALSE,
                       progress = FALSE)
  expect_equal(in_allotment(), a$fy2026_allotment[a$state == "IN"])
  # The footer's own total rounds to the anchor.
  expect_equal(round(as.numeric(gsub("[$,]", "", IN_RHTP_FOOTER_AMOUNT))),
               in_allotment())
})

test_that("the two RFPs whose TITLES never say RHTP are RHTP by their scope", {
  for (k in c("scope_87556", "scope_87667")) {
    txt <- in_docx_text(k)
    expect_true(grepl(IN_RHTP_FOOTER_AMOUNT, txt, fixed = TRUE))
    expect_true(grepl("Rural Health Transformation", txt, fixed = TRUE))
  }
  # And their award letters do NOT -- which is why the scope had to be read.
  for (k in c("award_87556", "award_87667")) {
    expect_false(grepl("Rural Health Transformation", in_award_text(k),
                       fixed = TRUE))
  }
})

test_that("the state states its own NOA date and every award postdates it", {
  expect_silent(in_assert_after_noa())
  expect_equal(format(in_noa_date(), "%Y-%m-%d"), "2025-12-29")
  expect_true(all(IN_TEST_AWARDS$award_date > in_noa_date()))
})

test_that("the §6.2 negative control is a trailer and carries no RHTP", {
  expect_silent(in_assert_non_rhtp_control())
  txt <- in_award_text("control_87613")
  expect_true(grepl("Hydraulic", txt, fixed = TRUE))
  expect_false(grepl("Rural Health Transformation", txt, fixed = TRUE))
  # RCJ labelled it RHTP on the 08-27 pull -- the §0.1 finding -- and the
  # 2026-09-24 pull WITHDREW that record. It is a finding about 08-27.
  cands <- in_rcj_candidates()
  expect_false(any(grepl("Trail Trailer Purchase RHTP", cands$source_doc_title)))
  all_rt <- rhtp_record_table_live(include_withdrawn = TRUE)
  tr <- all_rt[all_rt$state == "IN" &
                 grepl("Trail Trailer Purchase RHTP", all_rt$source_doc_title), ]
  expect_gt(nrow(tr), 0L)
  expect_true(all(tr$change_status == "WITHDRAWN"))
})


# -- the positive control -----------------------------------------------------

test_that("IDOA's register is large, general, and carries all five RFPs", {
  expect_silent(in_assert_award_register())
  reg <- in_register_rows()
  expect_gte(nrow(reg), 400L)
  for (r in IN_POOLS$rfp) {
    expect_true(any(grepl(r, reg$event, fixed = TRUE)), info = r)
  }
  # RHTP is a rounding error on it, which is the point.
  expect_lt(sum(grepl("RHTP", reg$event)) / nrow(reg), 0.05)
})

test_that("a fifth RHTP row on the register fails the control", {
  # Positive control on the control: feed it a register that has gained one.
  reg <- in_register_rows()
  faked <- rbind(reg,
                 data.frame(award_date = "09/01/2026",
                            event = "RFP 26-99999 RHTP Rural Hospital Grants",
                            url = "/x.zip", stringsAsFactors = FALSE))
  rhtp_rows <- sum(grepl("RHTP", faked$event))
  expect_gt(rhtp_rows, 4L)
})


# -- §0.3, the two traps ------------------------------------------------------

test_that("Regional Grants HAS awarded (2026-09-03), and is extracted in R/03bi", {
  expect_silent(in_assert_regional_awarded())
  expect_false(exists("in_assert_regional_not_awarded"))
  # WHY THE OLD NEGATIVE WAS RETIRED: the re-read page still carries every
  # pre-award sentence it keyed on, BESIDE the new roster, so it could not
  # fail. A negative keyed on a sentence being present cannot see an award
  # being added.
  now <- in_html_text_raw_path(IN_REGIONAL_RECHECK)
  expect_true(grepl(IN_REGIONAL_LAUNCH_SENTENCE, now, fixed = TRUE))
  expect_true(grepl("RFF Applications submitted July 1", now, fixed = TRUE))
  expect_true(grepl("nearly 200 subrecipients have been selected", now, fixed = TRUE))
  # The seven vendors and the regional roster never merge.
  g <- readr::read_csv(IN_GROW_REGIONAL_CSV, show_col_types = FALSE)
  expect_equal(nrow(g), 186L)
  expect_false(any(IN_TEST_AWARDS$awardee %in% g$awardee))
})

test_that("committee hospitals are named on the page and in NO award row", {
  expect_silent(in_assert_committee_not_recipients())
  txt <- in_html_text("grow_regional")
  for (h in IN_COMMITTEE_ONLY_HOSPITALS) {
    expect_true(grepl(h, txt, fixed = TRUE), info = h)
    expect_false(any(grepl(h, IN_TEST_AWARDS$awardee, fixed = TRUE)), info = h)
  }
  # The per-region dollars are a CEILING, and the page still labels them so.
  expect_true(grepl("Maximum Capital Expenditures", txt, fixed = TRUE))
})

test_that("the seven proposers are applicants and only one was selected", {
  expect_silent(in_assert_proposers_not_awarded())
  let <- in_award_text("award_87449_let")
  expect_true(grepl("The evaluation team received seven", let, fixed = TRUE))
  # Deloitte is an unsuccessful proposer HERE and an awardee ELSEWHERE.
  expect_true(grepl("Deloitte", let, fixed = TRUE))
  d <- IN_TEST_AWARDS[grepl("Deloitte", IN_TEST_AWARDS$awardee), ]
  expect_equal(nrow(d), 1L)
  expect_equal(d$solicitation_number, "26-87667")
})


# -- §0.1, the disposition ----------------------------------------------------

test_that("the RCJ disposition closes at 214 on the 2026-09-24 pull and is derived", {
  expect_silent(in_assert_rcj_disposition())
  disp <- in_rcj_disposition()
  expect_equal(sum(disp$rcj_rows), nrow(in_rcj_candidates()))
  expect_equal(sum(disp$rcj_rows), 214L)
  n <- stats::setNames(disp$rcj_rows, disp$group)
  expect_equal(unname(n["GROW Regional Grants recipients"]), 185L)
  expect_equal(unname(n["GROW region totals carried as awardees"]), 2L)
  expect_equal(disp$rcj_rows[disp$disposition == "RHTP_SUBAWARD"], 7L)
  expect_equal(sum(disp$rcj_rows[disp$disposition == "NOT_RHTP_STATE_PROCUREMENT"]), 19L)
  expect_equal(disp$rcj_rows[disp$disposition == "RHTP_BUT_NOT_A_SUBAWARD"], 1L)
  expect_false(anyNA(disp$disposition))
  expect_silent(rhtp_assert_disposition_prose(disp, "IN"))
})

test_that("the groups COVER the live set: an unread candidate cannot be absorbed", {
  cands <- in_rcj_candidates()
  expect_equal(length(in_rcj_groups(cands)), nrow(cands))
  # Every GROW candidate lands on a row of in_grow_regional_awardees.csv, by
  # exact (region, name) or the ONE hand-read rename -- and a new spelling fails.
  j <- in_rcj_grow_join(cands)
  expect_true(all(j$rcj$in_file))
  expect_equal(sum(j$rcj$page_name != j$rcj$awardee_name_clean), 1L)
  expect_equal(j$page_rows_not_in_rcj$awardee,
               "Putnam County Emergency Medical Services (EMS) - Mobile Integrated Health (MIH) Program")
  expect_true(all(j$rcj$amount_announced == 1))
  bad <- cands
  bad$awardee_name_clean[bad$awardee_name_clean == "Woodlawn Hospital"] <- "Woodlawn Hosp."
  expect_false(all(in_rcj_grow_join(bad)$rcj$in_file))
})

test_that("RCJ now holds Concourse and still misses Deloitte", {
  cands <- in_rcj_candidates()
  expect_false(any(grepl("Deloitte", cands$awardee_name_clean, ignore.case = TRUE)))
  expect_true(any(grepl("Concourse", cands$awardee_name_clean, ignore.case = TRUE)))
  # The file publishes both, and keeps Concourse's amount EMPTY: RCJ's
  # $809,500 is on no archived state document (§0.1).
  expect_true(any(grepl("Deloitte", IN_TEST_AWARDS$awardee)))
  expect_true(is.na(IN_TEST_AWARDS$amount[grepl("Concourse", IN_TEST_AWARDS$awardee)]))
})

test_that("the region totals RCJ carries as awardees are the page's own figures", {
  cands <- in_rcj_candidates()
  reg <- cands[in_rcj_groups(cands) == "GROW region totals carried as awardees", ]
  expect_setequal(reg$amount_announced, c(15200000, 13000000))
})

test_that("Indiana Community Connect is a BUDGET LINE, not an award", {
  cands <- in_rcj_candidates()
  icc <- cands[grepl("Indiana Community Connect", cands$awardee_name_clean), ]
  expect_equal(nrow(icc), 1L)
  # RCJ's figure is not even the narrative's figure.
  expect_equal(icc$amount_announced, 3300000)
  # And it is not in the award file: it is a programme name, not a recipient.
  expect_false(any(grepl("Community Connect", IN_TEST_AWARDS$awardee)))
})


# -- the classifier override --------------------------------------------------

test_that("the vendor typing diverges from the classifier and is recorded", {
  expect_silent(in_assert_vendor_override())
  expect_true(all(IN_TEST_AWARDS$recipient_type == "VENDOR_OR_CONTRACTOR"))
  # Every row records what the shared classifier said, so it is reversible.
  expect_true(all(grepl("Shared classifier returned",
                        IN_TEST_AWARDS$recipient_type_source)))
  # The divergence is real for most rows.
  expect_gt(sum(grepl("returned NONPROFIT_CBO",
                      IN_TEST_AWARDS$recipient_type_source)), 0L)
  # And it is queued for a human, at $0.
  expect_silent(in_assert_vendor_question_queued())
})

test_that("every published awardee is named in its own award document", {
  expect_silent(in_assert_recipients_in_source())
})


# -- the committed artifacts --------------------------------------------------

test_that("the committed CSV matches what the builder produces", {
  skip_if_not(file.exists(IN_OUTPUT_CSV))
  committed <- readr::read_csv(IN_OUTPUT_CSV, show_col_types = FALSE,
                               progress = FALSE)
  expect_equal(nrow(committed), nrow(IN_TEST_AWARDS))
  expect_equal(committed$awardee, IN_TEST_AWARDS$awardee)
  expect_equal(sum(committed$amount, na.rm = TRUE), 860088)
})

test_that("the evidence manifest lists every archived file but itself", {
  path <- file.path(IN_EVIDENCE_DIR, "MANIFEST.txt")
  skip_if_not(file.exists(path))
  man <- readLines(path, warn = FALSE)
  listed <- sub("^[0-9a-f]{64}  ", "", man[grepl("^[0-9a-f]{64}  ", man)])
  listed <- sub("  \\(.*$", "", listed)
  on_disk <- setdiff(list.files(IN_EVIDENCE_DIR), "MANIFEST.txt")
  expect_setequal(listed, on_disk)
  expect_false("MANIFEST.txt" %in% listed)
})
