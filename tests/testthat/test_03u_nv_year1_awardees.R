# test_03u_nv_year1_awardees.R ------------------------------------------------
# Nevada. Offline against the committed archive; no network, no quota.
#
# The things worth testing here are not the arithmetic. They are:
#   * that `amount` STAYS EMPTY. Nevada publishes a named roster with no
#     figures on it, so every downstream instinct -- fill it, divide the round
#     total, drop the rows -- is a defect, and the file's whole design rests on
#     the column being empty and sum()ing to zero.
#   * that "$0 of hospital dollars" can never be read as "no hospitals". The
#     partition reports Nevada as rows = 20, dollars = 0, and only one of those
#     is a number.
#   * that the GME awards stay OUT. Seventeen of RCJ's 34 candidates are
#     $15,755,068 of Nevada STATE GENERAL FUND money, and the CMS
#     financial-assistance footer is on the document that says so.
#   * that the header-promotion and the pool-total repeat cannot silently
#     misbehave -- both are devices that fail plausibly rather than loudly.

library(testthat)

source(here::here("R", "03u_nv_year1_awardees.R"))

skip_if_no_archive <- function() {
  skip_if_not(file.exists(nv_path("roster")),
              "Nevada's evidence archive is not on disk")
}


# -- the archive --------------------------------------------------------------

test_that("every archived source verifies against the manifest", {
  skip_if_no_archive()
  man <- readLines(file.path(NV_EVIDENCE_DIR, "MANIFEST.txt"), warn = FALSE)
  for (i in seq_len(nrow(NV_SOURCES))) {
    f <- NV_SOURCES$file[i]
    path <- file.path(NV_EVIDENCE_DIR, f)
    expect_true(file.exists(path), info = f)
    digest_now <- digest::digest(file = path, algo = "sha256")
    expect_true(any(grepl(digest_now, man, fixed = TRUE)), info = f)
  }
})

test_that("the manifest does not list itself", {
  skip_if_no_archive()
  man <- readLines(file.path(NV_EVIDENCE_DIR, "MANIFEST.txt"), warn = FALSE)
  expect_false(any(grepl("MANIFEST.txt", man, fixed = TRUE)))
})

test_that("no two archived files share a digest", {
  # Session 25's rule: two paths onto one page must not sit in the evidence
  # directory under two names, implying two corroborating documents.
  skip_if_no_archive()
  files <- file.path(NV_EVIDENCE_DIR, NV_SOURCES$file)
  digests <- vapply(files, function(f) digest::digest(file = f, algo = "sha256"),
                    character(1))
  expect_equal(length(unique(digests)), length(digests))
})


# -- the roster ---------------------------------------------------------------

test_that("the roster parses to 72 award actions across three pools", {
  skip_if_no_archive()
  a <- nv_roster_awards()
  expect_equal(nrow(a), NV_STATED$roster_rows)
  expect_equal(sum(a$award_pool == "FLEX_FUND"), NV_STATED$flex_rows)
  expect_equal(sum(a$award_pool == "WRRAP_RECRUITMENT_RETENTION"),
               NV_STATED$wrrap_rr_rows)
  expect_equal(sum(a$award_pool == "WRRAP_APPRENTICESHIP_TRAINING"),
               NV_STATED$wrrap_at_rows)
  expect_true(all(nzchar(a$awardee)))
})

test_that("the Flex table's <td> header is promoted, and 'Subrecipient' is not an awardee", {
  # SESSION 10'S DEFECT. NVHA marks the Flex table's header row up with <td>,
  # so html_table() calls the columns X1..X3 and keeps the header as row 1 --
  # while the two WRRAP tables on the SAME PAGE use <th>. Unpromoted, Nevada
  # reports 26 Flex awards, one of them to an organisation called
  # "Subrecipient".
  skip_if_no_archive()
  a <- nv_roster_awards()
  expect_false("Subrecipient" %in% a$awardee)
  expect_false("Applicant" %in% a$awardee)
  tabs <- nv_roster_tables()
  for (tb in tabs) {
    expect_true(any(grepl("subrecipient|applicant", tolower(names(tb)))))
  }
})

test_that("header promotion NEVER makes a working parse worse", {
  # The conditional is the whole safety of the device: promoting a real data
  # row would delete an award. Feed it a table whose header already resolves
  # and require it untouched.
  good <- tibble::tibble(Subrecipient = c("A Hospital", "B Clinic"),
                         Project = c("p", "q"),
                         `Service Area` = c("x", "y"))
  expect_identical(nv_promote_header(good), good)
})

test_that("a recipient with two projects is kept as two rows, not de-duplicated", {
  skip_if_no_archive()
  a <- nv_roster_awards()
  wb <- a[a$awardee == "Washoe Barton Medical Clinic DBA Carson Valley Health" &
            a$award_pool == "FLEX_FUND", ]
  expect_equal(nrow(wb), 2L)
  expect_equal(length(unique(wb$project_description)), 2L)
})

test_that("the roster parser refuses a page that starts carrying amounts", {
  # The file's design premise. If NVHA ever publishes per-recipient figures the
  # right response is to rewrite this file, not to keep an empty column.
  skip_if_no_archive()
  faked <- nv_roster_tables()
  faked[[1]]$Project[1] <- paste0(faked[[1]]$Project[1], ": $250,000")
  expect_error(nv_roster_awards(faked), "publishing per-recipient amounts")
})

test_that("the roster parser refuses a fourth table", {
  skip_if_no_archive()
  faked <- nv_roster_tables()
  expect_error(nv_roster_awards(c(faked, faked[1])), "does not carry")
})


# -- the records --------------------------------------------------------------

test_that("Nevada is 73 rows and `amount` is empty on every one of them", {
  skip_if_no_archive()
  recs <- nv_records()
  expect_equal(nrow(recs), NV_STATED$total_rows)
  expect_true(all(is.na(recs$amount)))
  expect_equal(sum(recs$amount, na.rm = TRUE), 0)
})

test_that("every categorical value is inside §8", {
  skip_if_no_archive()
  expect_true(nv_assert_vocabulary(nv_records()))
})

test_that("AMOUNT_MISSING is on every row, because it is true of every row", {
  skip_if_no_archive()
  recs <- nv_records()
  expect_true(all(grepl("AMOUNT_MISSING", recs$flag_reason)))
})

test_that("only the two WRRAP workforce pools carry the pool-conflict flag", {
  skip_if_no_archive()
  recs <- nv_records()
  flagged <- grepl("POOL_AMOUNT_CONFLICTS_ACROSS_SOURCES", recs$flag_reason)
  expect_setequal(unique(recs$award_pool[flagged]),
                  c("WRRAP_RECRUITMENT_RETENTION", "WRRAP_APPRENTICESHIP_TRAINING"))
  # The Flex Fund's $36M is corroborated by two documents and is NOT in dispute.
  expect_false(any(flagged & recs$award_pool == "FLEX_FUND"))
})

test_that("the Rural Medical Residency row names nobody and carries no amount", {
  skip_if_no_archive()
  recs <- nv_records()
  res <- recs[recs$award_pool == "WRRAP_RURAL_MEDICAL_RESIDENCY", ]
  expect_equal(nrow(res), 1L)
  expect_true(is.na(res$amount))
  expect_equal(res$round_amount, NV_STATED$wrrap_residency)
  expect_equal(res$recipient_type, "NOT_YET_NAMED")
  expect_equal(res$recipient_confirmed, "No")
  expect_true(grepl("RECIPIENT_NOT_NAMED", res$flag_reason))
  expect_equal(res$distributed_to_hospital, "Unclear")
})


# -- the hospital figure, which is a COUNT ------------------------------------

test_that("Nevada has named-hospital ROWS and $0 of named-hospital DOLLARS", {
  # THE MISREADING THIS FILE EXISTS TO PREVENT. Both halves are true; only one
  # is a number, and quoting the number alone reports the opposite of what NVHA
  # published.
  skip_if_no_archive()
  recs <- nv_records()
  got <- nv_assert_zero_dollars_is_not_zero_hospitals(recs)
  expect_gt(got$rows, 0L)
  expect_equal(got$dollars, 0)

  part <- rhtp_hospital_dollar_partition(recs)
  expect_equal(part$bucket, "NAMED_HOSPITAL")
  expect_equal(part$dollars, 0)
  expect_equal(part$rows, sum(recs$hospital_attribution == "NAMED_HOSPITAL"))
})

test_that("rhtp_hospital_total() still refuses, with Nevada in the union", {
  skip_if_no_archive()
  expect_error(rhtp_hospital_total(nv_records()), "no single hospital total")
})

test_that("the two hospital FOUNDATIONS are not counted as hospitals", {
  # §10.2's inflation trap: both carry "Hospital" in their published names and
  # the name rule reaches both. Neither is a hospital.
  skip_if_no_archive()
  recs <- nv_records()
  for (nm in c("Nevada Rural Hospital Partners Foundation",
               "Incline Village Community Hospital Foundation")) {
    rows <- recs[recs$awardee == nm, ]
    expect_gt(nrow(rows), 0L)
    expect_true(all(rows$recipient_type == "HOSPITAL_AFFILIATED_ENTITY"), info = nm)
    expect_false(any(rows$hospital_attribution == "NAMED_HOSPITAL"), info = nm)
  }
})

test_that("Nevada carries the project's first FLOW_UNRESOLVED_HOSPITAL_AFFILIATED row", {
  # Session 19 added the code and recorded that zero committed rows carried it.
  skip_if_no_archive()
  recs <- nv_records()
  hit <- recs[grepl("FLOW_UNRESOLVED_HOSPITAL_AFFILIATED", recs$flag_reason), ]
  expect_equal(nrow(hit), 1L)
  expect_equal(hit$awardee, "Incline Village Community Hospital Foundation")
  expect_equal(hit$flow_type, "PASS_THROUGH_UNRESOLVED")
  expect_equal(hit$distributed_to_hospital, "Unclear")
})

test_that("same-entity name variants are recorded and NOT merged (§2)", {
  skip_if_no_archive()
  expect_true(nv_assert_name_variants_unresolved(nv_records()))
  recs <- nv_records()
  # The pair four characters apart, in one state, both in Elko.
  expect_true("Northern Nevada Regional Hospital" %in% recs$awardee)
  expect_true("Northeastern Nevada Regional Hospital" %in% recs$awardee)
})


# -- reconciliation -----------------------------------------------------------

test_that("the four pools sum to Nevada's announced $87,400,000", {
  skip_if_no_archive()
  rec <- nv_reconcile(nv_records())
  expect_equal(rec$total, NV_STATED$announced_total)
  expect_equal(nrow(rec$pools), nrow(NV_POOLS))
})

test_that("GEORGIA'S TRAP IS PINNED OPEN: summing round_amount is wrong", {
  # `round_amount` repeats its pool's total on every row of the pool. The wrong
  # sum must STAY visibly wrong, or the trap closes quietly and someone
  # publishes $2.06bn for a state that announced $87.4M.
  skip_if_no_archive()
  recs <- nv_records()
  rec <- nv_reconcile(recs)
  expect_equal(sum(recs$round_amount), 2062900000)
  expect_gt(rec$naive_column_sum, rec$total * 20)
})


# -- §6.2 ---------------------------------------------------------------------

test_that("CMS's own Notice of Award matches BOTH anchors", {
  skip_if_no_archive()
  expect_true(nv_assert_cms_notice_of_award())
  expect_equal(round(NV_CMS_AWARD_AMOUNT), rhtp_nv_allotment())
  expect_equal(rhtp_nv_noa_date(), NV_NOA_DATE)
})

test_that("every awarded RFA closed AFTER the 2025-12-29 Notice of Award", {
  skip_if_no_archive()
  expect_true(nv_assert_rfas_postdate_noa())
})

test_that("THE CMS FOOTER IS NOT A PROVENANCE TEST, and the document proves it", {
  # One publication, the CMS financial-assistance footer on every page, three
  # programmes described, two of them state-funded.
  skip_if_no_archive()
  expect_true(nv_assert_footer_is_not_provenance())
  wf <- nv_pdf_flat("workforce")
  expect_true(grepl("financial assistance award totaling $179,931,608.42", wf,
                    fixed = TRUE))
  expect_true(grepl("Source: State General Fund", wf, fixed = TRUE))
  expect_true(grepl("SB5 one-time bill appropriation", wf, fixed = TRUE))
})

test_that("the GME release is STATE money and none of it is in the file", {
  skip_if_no_archive()
  recs <- nv_records()
  expect_true(nv_assert_gme_is_state_money(recs))
  # Its own nine amounts close on its own stated total.
  expect_equal(sum(NV_GME_AWARDS$amount), NV_GME_TOTAL)
  expect_equal(nrow(NV_GME_AWARDS), NV_GME_PROGRAMMES)
  # And not one of the nine is an awardee here.
  expect_equal(intersect(tolower(recs$awardee), tolower(NV_GME_AWARDS$awardee)),
               character(0))
})

test_that("a leaked GME recipient is REFUSED", {
  # The assertion above is only evidence that today's file is clean. This
  # reproduces the failure it exists to catch.
  skip_if_no_archive()
  recs <- nv_records()
  faked <- dplyr::bind_rows(
    recs, recs[1, ] %>% dplyr::mutate(awardee = NV_GME_AWARDS$awardee[1]))
  expect_error(nv_assert_gme_is_state_money(faked), "leaked into the RHTP")
})

test_that("the non-RHTP registry entry catches Nevada GME and nothing else", {
  skip_if_no_archive()
  # The registry reader and matcher live in the normalize stage, which is where
  # the sweep calls them from; sourcing it here keeps this test checking the
  # SAME code path the sweep uses rather than a copy of it.
  source(here::here("R", "02_normalize.R"), local = TRUE)
  reg <- rhtp_read_state_program_registry()
  row <- reg[reg$program_id == "NV-GME-ROUNDVIII", ]
  expect_equal(nrow(row), 1L)
  expect_equal(row$disposition, "NOT_RHTP_STATE_PROGRAM")

  cand <- nv_classify_candidates()
  prov <- paste(dplyr::coalesce(cand$source_doc_title, ""),
                dplyr::coalesce(cand$solicitation_number, ""))
  caught <- vapply(prov, function(t) {
    !is.na(rhtp_match_state_program("NV", t, reg)$flag[1])
  }, logical(1))
  # Every row it catches is one the extractor independently calls state money.
  expect_true(all(cand$disposition[caught] == "NOT_RHTP_STATE_PROGRAM"))
  expect_gt(sum(caught), 0L)

  # AND IT MUST NOT MATCH GENUINE NEVADA RHTP TEXT. NVHA's own WRRAP release
  # funds "a new statewide Rural Graduate Medical Education Consortium", which
  # is why the bare phrase is not the key.
  expect_true(is.na(rhtp_match_state_program(
    "NV", "a new statewide Rural Graduate Medical Education Consortium",
    reg)$flag[1]))
})


# -- positive controls --------------------------------------------------------

test_that("NVHA publishes rosters in a recognisable form, for exactly three pools", {
  skip_if_no_archive()
  expect_true(nv_assert_award_index())
})

test_that("the six closed opportunities with no roster are still unawarded", {
  # DESIGNED TO FAIL the day one of them names a recipient.
  skip_if_no_archive()
  expect_true(nv_assert_pending_not_awarded())
  expect_equal(length(NV_PENDING_OPPORTUNITIES), 6L)
})

test_that("the Flex round total is tied to THIS roster by NVHA itself", {
  skip_if_no_archive()
  expect_true(nv_assert_flex_round())
})

test_that("both sides of the WRRAP pool conflict are asserted", {
  skip_if_no_archive()
  expect_true(nv_assert_wrrap_rounds())
  # The combined figure survives the conflict, and that is what may be quoted.
  expect_lt(abs(NV_WRRAP_COMBINED_DECK - NV_WRRAP_COMBINED_PRESS), 200000)
  expect_equal(NV_WRRAP_COMBINED_PRESS, 46600000)
})

test_that("a SECOND document corroborates that no per-recipient amount exists", {
  skip_if_no_archive()
  expect_true(nv_assert_no_per_recipient_amounts())
})


# -- §0.1: RCJ's 34 candidates -------------------------------------------------

test_that("all 34 candidates are dispositioned, and the arithmetic closes", {
  skip_if_no_archive()
  expect_true(nv_assert_candidate_disposition())
  cand <- nv_classify_candidates()
  expect_equal(nrow(cand), NV_STATED$rcj_candidates)
  expect_false(any(is.na(cand$disposition)))
  d <- nv_disposition_table()
  expect_equal(sum(d$rcj_rows), nrow(cand))
  expect_equal(sum(d$rcj_amount_sum), sum(cand$amount_announced, na.rm = TRUE))
})

test_that("the Rural Medical Residency POOL rows are Tier 2, not GME state money", {
  # ORDERING. NVHA's own RHTP pool is called "Rural Medical Residency", so a
  # specialty regex written for the GME awards matches the pool total too --
  # which would file $9.6M of Tier 2 RHTP money as state money.
  skip_if_no_archive()
  cand <- nv_classify_candidates()
  res <- cand[grepl("^Rural Medical Residency", cand$awardee_name_clean), ]
  expect_equal(nrow(res), 2L)
  expect_true(all(res$disposition == "RHTP_BUT_NOT_A_SUBAWARD"))
  expect_true(all(res$amount_announced == NV_STATED$wrrap_residency))
})

test_that("seventeen candidates are STATE money and seven are the pool totals", {
  skip_if_no_archive()
  cand <- nv_classify_candidates()
  expect_equal(sum(cand$disposition == "NOT_RHTP_STATE_PROGRAM"), 17L)
  expect_equal(sum(cand$disposition == "RHTP_BUT_NOT_A_SUBAWARD"), 7L)
  expect_equal(sum(cand$disposition == "RHTP_SUBAWARD_IN_FILE"), 10L)
})

test_that("the ten real candidates are IN the file, and all carry $1", {
  skip_if_no_archive()
  cand <- nv_classify_candidates()
  recs <- nv_records()
  real <- cand[cand$disposition == "RHTP_SUBAWARD_IN_FILE", ]
  expect_equal(setdiff(tolower(real$awardee_name_clean), tolower(recs$awardee)),
               character(0))
  # A PLACEHOLDER, NOT AN AMOUNT: RCJ mined them from a deck with no figures.
  expect_true(all(real$amount_announced == 1))
})

test_that("§0.1: the candidate list at face value is mostly not Nevada RHTP subawards", {
  skip_if_no_archive()
  inf <- nv_candidate_inflation()
  expect_equal(inf$candidates, 34L)
  expect_equal(inf$face_value, 131643055)
  expect_gt(inf$state_money, 28000000)
  expect_equal(inf$real_award_amount, 10)
  # RCJ holds ten of Nevada's seventy-two published award actions.
  expect_equal(inf$real_awards, 10L)
  expect_lt(inf$rcj_coverage_pct, 15)
})


# -- the review queue ---------------------------------------------------------

test_that("NV_RECIPIENT_FORM_NOT_STATED is queued, with its $0 dollar effect", {
  skip_if_no_archive()
  expect_true(nv_assert_form_not_stated_queued(nv_records()))
  q <- readr::read_csv(
    here::here("data", "reference", "classification_review_queue.csv"),
    show_col_types = FALSE, progress = FALSE)
  row <- q[q$question_id == "NV_RECIPIENT_FORM_NOT_STATED", ]
  expect_equal(nrow(row), 1L)
  expect_equal(row$queue_status, "OPEN")
  expect_true(grepl("$0 in either direction", row$dollar_effect, fixed = TRUE))
})

test_that("nothing was promoted: the soft set is still on §8's fallback", {
  skip_if_no_archive()
  recs <- nv_records()
  soft <- recs[grepl("RECIPIENT_TYPE_INFERRED", recs$flag_reason), ]
  expect_equal(nrow(soft), 23L)
  expect_true(all(soft$recipient_type == "NONPROFIT_CBO"))
  expect_true(all(soft$determination_confidence == "LOW"))
  # Names a reader would expect to see promoted, deliberately not promoted.
  for (nm in c("Renown Health", "Carson Valley Health", "Intermountain Health")) {
    expect_true(nm %in% soft$awardee, info = nm)
  }
})


# -- the committed CSV --------------------------------------------------------

test_that("the committed CSV matches what the parser produces", {
  skip_if_no_archive()
  skip_if_not(file.exists(NV_OUT_CSV), "nv_year1_awardees.csv not built yet")
  on_disk <- readr::read_csv(NV_OUT_CSV, show_col_types = FALSE, progress = FALSE)
  built <- nv_records() %>% dplyr::select(dplyr::all_of(NV_COLUMN_ORDER))
  expect_equal(nrow(on_disk), nrow(built))
  expect_equal(names(on_disk), NV_COLUMN_ORDER)
  expect_equal(on_disk$awardee, built$awardee)
  expect_true(all(is.na(on_disk$amount)))
})

test_that("validate passes end to end", {
  skip_if_no_archive()
  expect_silent(suppressMessages(nv_validate()))
})
