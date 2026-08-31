# test_03t_ok_year1_awardees.R -----------------------------------------------
# Oklahoma. Offline against the committed archive; no network, no quota.
#
# The three things worth testing here are not the arithmetic. They are:
#   * that the PARSE cannot silently invent the six "No Awardee" counties or
#     lose them -- the block model is regular enough to produce 74 plausible
#     rows from a page that publishes 68 awards;
#   * that RCJ's 35 candidates stay OUT, since taking them at face value
#     publishes $231,614,376 of Tier 2 allocations, more than Oklahoma's whole
#     allotment; and
#   * that the §7A comparison keeps saying what the data says -- two claims
#     over two different universes, not one number checking another.

library(testthat)

source(here::here("R", "03t_ok_year1_awardees.R"))

skip_if_no_archive <- function() {
  skip_if_not(file.exists(ok_path("recipients")),
              "Oklahoma's evidence archive is not on disk")
}


# -- the archive --------------------------------------------------------------

test_that("every archived source verifies against the manifest", {
  skip_if_no_archive()
  man <- readLines(file.path(OK_EVIDENCE_DIR, "MANIFEST.txt"), warn = FALSE)
  listed <- character(0)
  for (i in seq_len(nrow(OK_SOURCES))) {
    f <- OK_SOURCES$file[i]
    p <- file.path(OK_EVIDENCE_DIR, f)
    expect_true(file.exists(p), info = f)
    line <- grep(paste0("^", f, " "), man, value = TRUE)
    expect_length(line, 1L)
    listed <- c(listed, f)
    # The file on disk must re-hash to the digest recorded for it. Session 12's
    # rule: manifests digest the body the server sent, written with writeBin().
    expect_true(grepl(digest::digest(file = p, algo = "sha256"), line,
                      fixed = TRUE), info = f)
  }
  # MANIFEST.txt must not list itself (session 15) and the listed set must be
  # the on-disk set.
  expect_false(any(grepl("^MANIFEST.txt ", man)))
  on_disk <- setdiff(list.files(OK_EVIDENCE_DIR), "MANIFEST.txt")
  expect_equal(sort(on_disk), sort(listed))
})

test_that("the programme page is archived once, not twice under two URLs", {
  skip_if_no_archive()
  # oklahoma.gov/health/rhtp.html and the long community-outreach URL serve
  # byte-identical bodies. If a future session re-adds the alias as a second
  # source, this catches the duplicate rather than letting the evidence
  # directory imply two corroborating documents.
  digests <- vapply(OK_SOURCES$file,
                    function(f) digest::digest(
                      file = file.path(OK_EVIDENCE_DIR, f), algo = "sha256"),
                    character(1))
  expect_equal(length(unique(digests)), nrow(OK_SOURCES))
})


# -- §6.2 provenance ----------------------------------------------------------

test_that("§6.2 passes: the CMS footer is on the roster itself", {
  skip_if_no_archive()
  expect_true(stringr::str_detect(ok_html_text("recipients"),
                                  stringr::fixed(OK_CMS_FOOTER)))
  expect_silent(ok_assert_rhtp_funded())
  # And OSDH's figure rounds to the §7.1 anchor exactly.
  expect_equal(round(OK_CMS_FOOTER_AMOUNT), rhtp_ok_allotment())
})

test_that("§6.2's date test passes and its evidence is on the document", {
  skip_if_no_archive()
  expect_silent(ok_assert_after_noa())
  expect_gt(as.numeric(OK_NOFO_ANNOUNCED - OK_NOA_DATE), 0)
  expect_gt(as.numeric(OK_NOFO_DUE - OK_NOA_DATE), 0)
})


# -- the positive control -----------------------------------------------------

test_that("the award index has exactly two anchors, and a third would fail", {
  skip_if_no_archive()
  expect_silent(ok_assert_award_index())
  expect_equal(sort(OK_AWARDED_ANCHORS), c("microgrants", "roots"))
})

test_that("the five closed opportunities with no roster are still on the page", {
  skip_if_no_archive()
  expect_silent(ok_assert_pending_not_awarded())
  funding <- ok_html_text("funding")
  for (o in OK_PENDING_OPPORTUNITIES) {
    expect_true(stringr::str_detect(funding, stringr::fixed(o)), info = o)
  }
  # None of them may be on the roster page. That negative is the whole reason
  # Oklahoma's file is 1.6% of its allotment rather than incomplete-by-accident.
  recips <- ok_html_text("recipients")
  for (o in c("Chronic Disease Management", "Rural Regional Reorientation",
              "Expanding Care: Doulas", "Behavioral Health Integration")) {
    expect_false(stringr::str_detect(recips, stringr::fixed(o)), info = o)
  }
})

test_that("§0.3: the Lung Cancer Screening Program's 11 hospitals are a count", {
  skip_if_no_archive()
  expect_silent(ok_assert_lung_screening_unnamed())
  expect_true(stringr::str_detect(ok_pdf_text("q2"), "11 hospitals selected"))
})


# -- the parse ----------------------------------------------------------------

test_that("the microgrant list is 74 three-line county blocks", {
  skip_if_no_archive()
  lines <- ok_microgrant_lines()
  expect_equal(length(lines) %% 3L, 0L)
  expect_equal(length(lines) / 3L, OK_STATED$counties_listed)
  blocks <- ok_microgrant_blocks()
  expect_equal(nrow(blocks), OK_STATED$counties_listed)
  expect_true(all(nchar(blocks$county) <= 24L))
  expect_true(all(nchar(blocks$project_description) >= 40L))
})

test_that("68 awards are parsed, and they reconcile to OSDH's own count", {
  skip_if_no_archive()
  a <- ok_microgrant_awards()
  expect_equal(nrow(a), 68L)
  expect_equal(round(sum(a$amount), 2), OK_STATED$microgrant_total)
  expect_equal(dplyr::n_distinct(a$county), 68L)
  expect_true(all(a$amount > 0))
  expect_true(all(a$amount <= OK_STATED$microgrant_cap_county))
  # A recipient name must never carry its own amount, which is what a
  # mis-placed split would produce.
  expect_false(any(stringr::str_detect(a$awardee, "\\$")))
  expect_silent(ok_assert_stated_counts(a))
})

test_that("THE SIX NO-AWARDEE COUNTIES ARE THE PARSE'S NEGATIVE CONTROL", {
  skip_if_no_archive()
  a <- ok_microgrant_awards()
  expect_silent(ok_assert_no_awardee_counties(a))
  # Present in the source...
  txt <- ok_html_text("recipients")
  for (c_ in OK_NO_AWARDEE_COUNTIES) {
    expect_true(stringr::str_detect(txt, stringr::fixed(c_)), info = c_)
  }
  # ...and absent from the awards. A parser that read the BLOCK SHAPE and not
  # the CONTENT would produce 74 rows and six invented recipients.
  expect_equal(intersect(a$county, OK_NO_AWARDEE_COUNTIES), character(0))
  expect_equal(nrow(ok_microgrant_blocks()) - nrow(a),
               OK_STATED$no_awardee_counties)
})

test_that("the no-awardee guard actually fires when a county gains an awardee", {
  skip_if_no_archive()
  # Positive control on the guard itself: feed it awards that include one of
  # the six, and require a refusal. Without this the assertion above is only
  # evidence that today's page is unchanged.
  a <- ok_microgrant_awards()
  faked <- dplyr::bind_rows(a, tibble::tibble(
    county = "Nowata", awardee = "Nowata Regional Hospital", amount = 50000,
    project_description = paste(rep("x", 60), collapse = "")))
  expect_error(ok_assert_no_awardee_counties(faked), "NO awardee")
})

test_that("§0.3: ROOTS publishes a count and a unit price, and no roster", {
  skip_if_no_archive()
  expect_silent(ok_assert_roots_not_named())
  txt <- ok_html_text("recipients")
  expect_true(stringr::str_detect(
    txt, stringr::fixed("has selected sixty (60) PK-12 rural school sites")))
  # 60 x $10,000 is a ROUND total OSDE states, not a per-recipient figure.
  expect_equal(OK_STATED$roots_awards * OK_STATED$roots_unit,
               OK_STATED$roots_total)
  expect_true(stringr::str_detect(ok_pdf_text("q2"),
                                  "60 awards totalling \\$600K"))
})


# -- the records --------------------------------------------------------------

test_that("the file is 69 rows: 68 microgrants and one ROOTS aggregate", {
  skip_if_no_archive()
  recs <- ok_records()
  expect_equal(nrow(recs), 69L)
  expect_equal(sum(recs$award_pool == "MICROGRANTS"), 68L)
  expect_equal(sum(recs$award_pool == "ROOTS"), 1L)
  expect_equal(names(recs)[1:19], c(
    "state", "row_no", "awardee", "amount", "recipient_type",
    "distributed_to_hospital", "note", "recipient_confirmed",
    "amount_confirmed", "fiscal_year", "source_document_title",
    "state_source_url", "validation_source_type", "extraction_method",
    "validator", "ccn", "aha_id", "rural_designation", "reviewer"))
})

test_that("sum(amount) is the microgrant total and NOTHING else", {
  skip_if_no_archive()
  recs <- ok_records()
  expect_silent(ok_assert_amount_column(recs))
  expect_equal(round(sum(recs$amount, na.rm = TRUE), 2),
               OK_STATED$microgrant_total)
  # Georgia's and South Dakota's rule, made a test: the ROOTS row's $600,000
  # is reachable only through round_amount.
  roots <- recs[recs$award_pool == "ROOTS", ]
  expect_true(is.na(roots$amount))
  expect_equal(roots$round_amount, OK_STATED$roots_total)
  expect_equal(roots$recipient_confirmed, "No")
  expect_equal(roots$recipient_type, "NOT_YET_NAMED")
  expect_equal(roots$flag_reason, "RECIPIENT_NAMES_NOT_CAPTURED")
  # §0.3a judges the RECIPIENT: OSDE states the class (PK-12 rural school
  # sites) even though it names no member of it, so this is No, not Unclear.
  expect_equal(roots$distributed_to_hospital, "No")
  expect_equal(roots$flow_type, "NON_HOSPITAL")
})

test_that("every categorical value is inside §8", {
  skip_if_no_archive()
  expect_silent(ok_assert_vocabulary(ok_records()))
})

test_that("20 award actions reach 18 named hospitals, and that is a FLOOR", {
  skip_if_no_archive()
  recs <- ok_records()
  h <- recs[recs$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(h), 20L)
  expect_equal(dplyr::n_distinct(h$awardee), 18L)
  expect_true(all(h$recipient_type == "HOSPITAL_OR_SYSTEM"))
  expect_true(all(h$flow_type == "DIRECT"))
  expect_true(all(h$hospital_attribution == "NAMED_HOSPITAL"))
  expect_equal(round(sum(h$amount), 2), 1079506.22)

  # Oklahoma has no pass-through row at all, so neither pool bucket exists.
  part <- rhtp_hospital_dollar_partition(recs)
  expect_equal(ok_bucket(part, "POOL_NAMED_HOSPITALS"), 0)
  expect_equal(ok_bucket(part, "POOL_UNNAMED_HOSPITALS"), 0)
})

test_that("the uncertainty is larger than the floor AND one-directional", {
  skip_if_no_archive()
  recs <- ok_records()
  soft <- ok_form_not_stated(recs)
  expect_equal(nrow(soft), 31L)
  expect_equal(round(sum(soft$amount), 2), 1575304.25)
  # Larger than the figure it sits beside -- Kansas's, Maryland's and
  # Nebraska's shape a fourth time.
  expect_gt(sum(soft$amount), 1079506.22)
  # And ONE-DIRECTIONAL, which Oklahoma is the first state where it holds:
  # every unstated row is already No, so resolving one can only RAISE the
  # hospital figure. That is why the report may call $1,079,506.22 a floor
  # and $2,654,810.47 a ceiling.
  expect_true(all(soft$distributed_to_hospital == "No"))
  expect_equal(round(sum(soft$amount) + 1079506.22, 2), 2654810.47)
  expect_true(all(soft$flag_reason == "RECIPIENT_TYPE_INFERRED"))
  expect_true(all(soft$determination_confidence == "LOW"))
})

test_that("the two source-stated overrides are applied and move no dollars", {
  skip_if_no_archive()
  recs <- ok_records()
  # OSDH's own award text calls Stigler HWC an FQHC; §8's fallback would have
  # queued a form the awarding agency states.
  stigler <- recs[recs$awardee == "Stigler HWC", ]
  expect_equal(nrow(stigler), 3L)
  expect_true(all(stigler$recipient_type == "FQHC_OR_RHC"))
  expect_true(all(stringr::str_detect(stigler$project_description,
                                      "(?i)federally qualified he")))
  choctaw <- recs[recs$awardee == "Choctaw Nation of Oklahoma", ]
  expect_equal(nrow(choctaw), 1L)
  expect_equal(choctaw$recipient_type, "TRIBAL_ORG")
  # Neither moves a dollar: both are No under the fallback and the override.
  expect_true(all(c(stigler$distributed_to_hospital,
                    choctaw$distributed_to_hospital) == "No"))
  # And the school-district rule added to §8 this session reaches both.
  schools <- recs[stringr::str_detect(recs$awardee, "Public Schools$"), ]
  expect_equal(nrow(schools), 2L)
  expect_true(all(schools$recipient_type == "SCHOOL_OR_DISTRICT"))
  expect_true(all(schools$distributed_to_hospital == "No"))
})

test_that("the review-queue row exists and states the file's own figures", {
  skip_if_no_archive()
  expect_silent(ok_assert_form_not_stated_queued(ok_records()))
  q <- readr::read_csv(here::here(OK_REVIEW_QUEUE), show_col_types = FALSE,
                       progress = FALSE)
  row <- q[q$question_id == OK_FORM_NOT_STATED_QUESTION, ]
  expect_equal(nrow(row), 1L)
  expect_equal(row$queue_status[[1]], "OPEN")
  expect_equal(row$state[[1]], "OK")
  expect_true(grepl("1,575,304.25", row$dollar_effect[[1]], fixed = TRUE))
})

test_that("the Oklahoma Hospital Association is on no award row", {
  skip_if_no_archive()
  expect_silent(ok_assert_oha_absent(ok_records()))
})


# -- §0.1 ---------------------------------------------------------------------

test_that("NOT ONE of RCJ's 35 candidates is one of Oklahoma's 68 awards", {
  skip_if_no_archive()
  recs <- ok_records()
  expect_silent(ok_assert_rcj_disposition(recs))
  cand <- ok_rcj_candidates()
  expect_equal(nrow(cand), OK_STATED$rcj_candidates)
  expect_equal(dplyr::n_distinct(cand$awardee_name_clean),
               OK_STATED$rcj_distinct_awardees)

  micro <- recs[recs$award_pool == "MICROGRANTS", ]
  expect_equal(intersect(rhtp_ok_norm(micro$awardee),
                         rhtp_ok_norm(cand$awardee_name_clean)),
               character(0))

  # THE SIZE OF THE MISTAKE. Taken at face value the candidate list publishes
  # more than Oklahoma's whole allotment as Tier 3 subawards.
  expect_gt(sum(cand$amount_announced, na.rm = TRUE), rhtp_ok_allotment())
  expect_equal(round(sum(cand$amount_announced, na.rm = TRUE), 2),
               OK_STATED$rcj_amount_sum)
})

test_that("the disposition table covers every candidate, by document", {
  skip_if_no_archive()
  disp <- ok_write_disposition()
  expect_equal(sum(disp$rcj_rows), OK_STATED$rcj_candidates)
  expect_true(all(disp$disposition %in% c("RHTP_BUT_NOT_A_SUBAWARD",
                                          "RHTP_BUT_A_PLATFORM_NOT_A_SUBAWARD")))
  # No candidate is dispositioned as an extracted award: RCJ holds none of
  # Oklahoma's actual awards, which is the finding.
  expect_false(any(grepl("EXTRACTED", disp$disposition)))
  expect_true(all(nzchar(disp$basis)))
  expect_true(all(nzchar(disp$state_document)))
  for (f in unique(disp$state_document)) {
    expect_true(file.exists(file.path(OK_EVIDENCE_DIR, f)), info = f)
  }
})


# -- the §7A comparison -------------------------------------------------------

test_that("the §7A comparison is two claims over two universes", {
  skip_if_no_archive()
  recs <- ok_records()
  expect_silent(ok_assert_initiative_parity(recs))
  init <- ok_initiative_table()

  # The initiative-level figure CLAUDE.md carries.
  expect_equal(sum(init$amount_bp1), OK_STATED$initiative_allocated)
  expect_equal(sum(init$amount_bp1[init$has_hospital_recipient == "Yes"]),
               OK_STATED$initiative_hospital)
  expect_equal(round(100 * OK_STATED$initiative_hospital /
                       OK_STATED$initiative_allocated, 1),
               OK_STATED$initiative_pct_hospital)

  # AND NOT ONE of the six hospital-directed fund uses has published a
  # recipient. That is why nothing in this file tests the 48.7%.
  hd <- init$fund_use[init$has_hospital_recipient == "Yes"]
  expect_equal(length(hd), 6L)
  expect_equal(intersect(hd, unique(recs$initiative_fund_use)), character(0))

  # The two fund uses Oklahoma HAS published are both coded No at initiative
  # level, and one of them names 20 hospital award actions.
  published <- unique(recs$initiative_fund_use)
  expect_setequal(published, c("Community-Led Wellness Hub: Microgrants",
                               "Presidential Fitness Test Preparation"))
  expect_true(all(init$has_hospital_recipient[init$fund_use %in% published]
                  == "No"))
  expect_gt(sum(recs$distributed_to_hospital == "Yes"), 0L)

  cmp <- ok_initiative_comparison(recs)
  expect_true(any(grepl("48.7%", cmp$value, fixed = TRUE)))
  expect_true(any(grepl("30.2%", cmp$value, fixed = TRUE)))
})

test_that("Oklahoma revised the microgrant line between its two Tier 2 docs", {
  skip_if_no_archive()
  # The §7A table's own source says $2,800,000; the Q2 report says $7,750,000
  # and OSDH awarded $3,572,120.71. Reported, not resolved -- both figures are
  # Oklahoma's own and they are four months apart.
  expect_true(stringr::str_detect(ok_pdf_text("ifs"),
                                  "Funding Allocated: \\$2,800,000"))
  expect_true(stringr::str_detect(ok_pdf_text("q2"), "\\$7,750,000"))
  expect_gt(OK_STATED$microgrant_total, OK_STATED$microgrant_alloc_ifs)
  expect_lt(OK_STATED$microgrant_total, OK_STATED$microgrant_alloc_q2)
})


# -- the committed file -------------------------------------------------------

test_that("the committed CSV matches what the extractor builds", {
  skip_if_no_archive()
  skip_if_not(file.exists(here::here(OK_CSV)))
  on_disk <- readr::read_csv(here::here(OK_CSV), show_col_types = FALSE,
                             progress = FALSE)
  expect_equal(nrow(on_disk), 69L)
  expect_equal(round(sum(on_disk$amount, na.rm = TRUE), 2),
               OK_STATED$microgrant_total)
  expect_equal(sum(on_disk$distributed_to_hospital == "Yes"), 20L)
  expect_true(all(on_disk$state == "OK"))
  expect_true(all(on_disk$validator == "R/03t_ok_year1_awardees.R"))
  expect_true(all(nzchar(on_disk$state_source_url)))
  expect_true(all(nzchar(on_disk$source_document_title)))
})
