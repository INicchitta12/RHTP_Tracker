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

test_that("the 2026-09-24 roster parses to 155 award actions across SEVEN sections", {
  skip_if_no_archive()
  a <- nv_roster_awards()
  expect_equal(nrow(a), 155L)
  expect_equal(nrow(a), NV_STATED$roster_rows)
  counts <- table(a$award_pool)
  expect_equal(as.integer(counts[c("FLEX_FUND", "WRRAP_RECRUITMENT_RETENTION",
                                   "WRRAP_APPRENTICESHIP_TRAINING",
                                   "WRRAP_RURAL_MEDICAL_RESIDENCY", "RHIT",
                                   "RHOAP", "TRIBAL")]),
               c(39L, 26L, 20L, 4L, 24L, 36L, 6L))
  expect_equal(unique(a$section), NV_ROSTER_SECTIONS)
  expect_true(all(nzchar(a$awardee)))
})

test_that("the FROZEN 2026-08-31 snapshot still parses to its 72 across three", {
  skip_if_no_archive()
  p <- nv_roster_awards(nv_roster_tables("roster_prior"), NV_PRIOR_ROSTER_SECTIONS)
  expect_equal(nrow(p), NV_STATED$prior_roster_rows)
  expect_equal(as.integer(table(p$award_pool)[c("FLEX_FUND",
    "WRRAP_RECRUITMENT_RETENTION", "WRRAP_APPRENTICESHIP_TRAINING")]),
    c(25L, 27L, 20L))
  # --fetch --force must never overwrite it with today's bytes.
  expect_true("roster_prior" %in% NV_FROZEN_KEYS)
  expect_false("roster" %in% NV_FROZEN_KEYS)
})

test_that("each table is named by its OWN heading, read off the page", {
  skip_if_no_archive()
  expect_equal(names(nv_roster_tables()), NV_ROSTER_SECTIONS)
  expect_equal(names(nv_roster_tables("roster_prior")), NV_PRIOR_ROSTER_SECTIONS)
  # A page whose sections come back in a different order is refused, not
  # silently re-labelled.
  tabs <- nv_roster_tables()
  names(tabs)[1:2] <- names(tabs)[2:1]
  expect_error(nv_roster_awards(tabs), "sections are now")
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

test_that("the roster parser refuses an EIGHTH table", {
  skip_if_no_archive()
  faked <- nv_roster_tables()
  expect_error(nv_roster_awards(c(faked, faked[1])), "does not carry")
})


# -- row order: session 49's overlay is keyed on it ---------------------------

test_that("rows 1..72 are the 2026-08-31 rows IN THAT ORDER; new rows follow", {
  skip_if_no_archive()
  recs <- nv_records()
  prior <- nv_roster_awards(nv_roster_tables("roster_prior"),
                            NV_PRIOR_ROSTER_SECTIONS)
  expect_equal(recs$awardee[1:72], prior$awardee)
  expect_true(all(recs$listed_from[1:72] == "2026-08-31"))
  expect_true(all(recs$listed_from[73:156] == "2026-09-24"))
  expect_equal(nrow(recs), 156L)
})

test_that("every overlaid row index still holds the recipient the overlay names", {
  skip_if_no_archive()
  ch <- readr::read_csv(here::here("data/reference/verification_queue_2_changes.csv"),
                        col_types = readr::cols(.default = "c"))
  ch <- ch[ch$file == "nv_year1_awardees.csv", ]
  expect_equal(nrow(ch), 23L)
  recs <- nv_records()
  expect_equal(recs$awardee[as.integer(ch$row)], ch$name)
  expect_true(nv_assert_overlay_rows_aligned(recs))
  # and the check FIRES on a shifted file -- the failure it exists for
  shifted <- recs[c(2:nrow(recs), 1), ]
  expect_error(nv_assert_overlay_rows_aligned(shifted), "Row order has")
  # session 50's overlay does not touch Nevada at all
  uf <- readr::read_csv(here::here("data/reference/unstated_form_typing_changes.csv"),
                        col_types = readr::cols(.default = "c"))
  expect_false("nv_year1_awardees.csv" %in% uf$file)
})

test_that("'93 X 95 NV' left the page and is KEPT at row 48 as Unclear", {
  skip_if_no_archive()
  recs <- nv_records()
  w <- recs[recs$withdrawn, ]
  expect_equal(nrow(w), 1L)
  expect_equal(w$row_no, 48L)
  expect_equal(w$awardee, "93 X 95 NV")
  expect_equal(w$recipient_confirmed, "Unclear")
  expect_match(w$note, "ABSENT FROM THE 2026-09-24")
  expect_match(w$source_archive_path, "2026-08-31_nv_rht_funded_projects_bp1")
  expect_true(is.na(w$amount))
  # the matcher refuses a SECOND disappearance rather than dropping it quietly
  cur <- nv_roster_awards()
  expect_error(nv_ordered_awards(current = cur[cur$awardee != "Carlin Volunteer Fire Dept.", ]),
               "no longer carries")
})


# -- the records --------------------------------------------------------------

test_that("Nevada is 156 rows and `amount` is empty on every one of them", {
  skip_if_no_archive()
  recs <- nv_records()
  expect_equal(nrow(recs), 156L)
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

test_that("the Rural Medical Residency pool NOW NAMES four recipients, none priced", {
  # Session 26's aggregate row said NVHA named nobody for the $4.8M. The
  # 2026-09-24 page names four, all University of Nevada, Reno, and the
  # aggregate row is gone rather than left making a claim that is now false.
  skip_if_no_archive()
  recs <- nv_records()
  res <- recs[recs$award_pool == "WRRAP_RURAL_MEDICAL_RESIDENCY", ]
  expect_equal(nrow(res), 4L)
  expect_true(all(is.na(res$amount)))
  expect_true(all(res$round_amount == NV_STATED$wrrap_residency))
  expect_true(all(res$recipient_type == "UNIVERSITY_OR_AHC"))
  expect_true(all(res$recipient_confirmed == "Yes"))
  expect_false("Recipients not named by NVHA" %in% recs$awardee)
  expect_false(any(recs$recipient_type == "NOT_YET_NAMED"))
})

test_that("pools with NO published round total carry an empty round_amount", {
  skip_if_no_archive()
  recs <- nv_records()
  unpriced <- recs$award_pool %in% c("RHIT", "RHOAP", "TRIBAL") |
    (recs$award_pool == "FLEX_FUND" & recs$listed_from == "2026-09-24")
  expect_equal(sum(unpriced), 24L + 36L + 6L + 14L)
  expect_true(all(is.na(recs$round_amount[unpriced])))
  expect_true(all(!is.na(recs$round_amount[!unpriced])))
  # The June $36M stays on the 25 first-round Flex rows only.
  first <- recs[recs$award_pool == "FLEX_FUND" & recs$listed_from == "2026-08-31", ]
  expect_equal(nrow(first), 25L)
  expect_true(all(first$round_amount == 36000000))
  expect_true(all(recs$round_id[recs$award_pool == "FLEX_FUND" &
                                recs$listed_from == "2026-09-24"] == "FLEX-ADDED"))
})

test_that("the local overrides fix the two misreads and move no dollar", {
  skip_if_no_archive()
  recs <- nv_records()
  nrhp <- recs[recs$awardee == "Nevada Rural Hospital Partners", ]
  expect_equal(nrow(nrhp), 1L)
  # The name rule would read 'Hospital' and return a NAMED hospital.
  expect_equal(rhtp_classify_recipient_type("Nevada Rural Hospital Partners",
                                            "NV")$recipient_type,
               "HOSPITAL_OR_SYSTEM")
  expect_equal(nrhp$recipient_type, "HOSPITAL_AFFILIATED_ENTITY")
  expect_equal(nrhp$hospital_attribution, "NOT_HOSPITAL")
  nshe <- recs[grepl("^NSHE", recs$awardee), ]
  expect_equal(nrow(nshe), 12L)
  expect_true(all(nshe$recipient_type == "UNIVERSITY_OR_AHC"))
  # §0.3a: "Tribal Program" is the ACTIVITY's name, not the recipient's form.
  expect_equal(rhtp_classify_recipient_type("NSHE, UNR Reno Extension Tribal Program",
                                            "NV")$recipient_type, "TRIBAL_ORG")
  expect_equal(nshe$recipient_type[nshe$awardee == "NSHE, UNR Reno Extension Tribal Program"],
               "UNIVERSITY_OR_AHC")
  expect_true(all(is.na(c(nrhp$amount, nshe$amount))))
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
  expect_equal(hit$row_no, 30L)
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

test_that("the four PUBLISHED round totals sum to Nevada's announced $87,400,000", {
  skip_if_no_archive()
  rec <- nv_reconcile(nv_records())
  expect_equal(rec$total, NV_STATED$announced_total)
  expect_equal(nrow(rec$pools), nrow(NV_POOLS) + 1L)
  expect_setequal(rec$unpriced_rounds, c("FLEX-ADDED", "RHIT", "RHOAP", "TRIBAL"))
})

test_that("GEORGIA'S TRAP IS PINNED OPEN: summing round_amount is wrong", {
  # `round_amount` repeats its pool's total on every row of the pool. The wrong
  # sum must STAY visibly wrong, or the trap closes quietly and someone
  # publishes $2.06bn for a state that announced $87.4M.
  skip_if_no_archive()
  recs <- nv_records()
  rec <- nv_reconcile(recs)
  expect_equal(sum(recs$round_amount, na.rm = TRUE), 2077300000)
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
source(here::here("R", "03ap_verification_queue_2.R"))
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

test_that("NVHA publishes rosters in a recognisable form, for exactly seven pools", {
  skip_if_no_archive()
  expect_true(nv_assert_award_index())
  # A section count that moves is refused -- NVHA added to a published roster.
  tabs <- nv_roster_tables()
  tabs[[5]] <- tabs[[5]][-1, ]
  expect_error(nv_assert_award_index(tables = tabs), "section counts have moved")
})

test_that("three of session 26's six pending opportunities AWARDED; three still pending", {
  # DESIGNED TO FAIL the day a pending one names a recipient, or an awarded
  # one's roster disappears.
  skip_if_no_archive()
  expect_true(nv_assert_pending_not_awarded())
  expect_equal(length(NV_PENDING_OPPORTUNITIES), 3L)
  expect_equal(NV_AWARDED_SINCE_0831$section,
               c("Rural Health Innovation and Technology Fund",
                 "Rural Health Outcomes Accelerator Program", "Tribal"))
  roster <- nv_html_text("roster")
  # The RHIT roster names the Nevada Department of Corrections as a RECIPIENT;
  # that must not read as the Correctional opportunity having awarded.
  expect_true(grepl("Nevada Department of Corrections", roster, fixed = TRUE))
  expect_silent(nv_assert_pending_not_awarded(text = roster))
  expect_error(nv_assert_pending_not_awarded(
    text = paste(roster, "Rural Veterans Health Transformation Show")),
    "records as pending")
  expect_error(nv_assert_pending_not_awarded(
    sections = setdiff(NV_ROSTER_SECTIONS, "Tribal")), "no longer a section")
  # on the 2026-08-31 page none of the three awarded sections existed
  expect_error(nv_assert_pending_not_awarded(
    text = nv_html_text("roster_prior"),
    sections = names(nv_roster_tables("roster_prior"))), "no longer a section")
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


# -- §0.1: RCJ's candidates (34 on 08-27, 42 on 09-24) ------------------------

test_that("every live candidate is dispositioned, and the arithmetic closes", {
  skip_if_no_archive()
  expect_true(nv_assert_candidate_disposition())
  cand <- nv_classify_candidates()
  expect_equal(nrow(cand), NV_STATED$rcj_candidates)
  expect_false(any(is.na(cand$disposition)))
  d <- nv_disposition_table()
  expect_equal(sum(d$rcj_rows), nrow(cand))
  expect_equal(sum(d$rcj_amount_sum), sum(cand$amount_announced, na.rm = TRUE))
  # the groups cover the LIVE set, read directly rather than through the builder
  rt <- rhtp_record_table_live()
  expect_equal(sum(d$rcj_rows),
               sum(rt$state == "NV" & rt$award_tier == "SUBAWARD"))
  expect_equal(sum(d$rcj_rows), 42L)
  expect_silent(rhtp_assert_disposition_prose(d, "NV"))
  # the committed CSV is what the builder writes
  committed_d <- readr::read_csv(NV_DISPOSITION_CSV, show_col_types = FALSE)
  expect_equal(committed_d$rcj_rows, d$rcj_rows)
  expect_equal(committed_d$disposition, d$disposition)
})

test_that("the eight 2026-09-24 additions: three Tier 2 lines and five unresolved contractors", {
  skip_if_no_archive()
  cand <- nv_classify_candidates()
  t2 <- cand[cand$disposition == "TIER_2_BUDGET_LINE_NOT_A_SUBAWARD", ]
  expect_setequal(t2$awardee_name_clean,
                  c("Nevada Rural Health System Flex Fund", "Presidential Fitness Test",
                    "Rural Health Innovation and Technology (RHIT)"))
  ven <- cand[cand$disposition == "AGGREGATOR_PLACEHOLDER_OR_UNRESOLVED", ]
  expect_equal(nrow(ven), 5L)
  expect_true(all(grepl("CMS Programmatic Annual Report", ven$source_doc_title)))
  # none of the eight is in the award file
  recs <- nv_records()
  expect_false(any(tolower(c(t2$awardee_name_clean, ven$awardee_name_clean)) %in%
                     tolower(recs$awardee)))
  # the stakeholder deck is what makes the two initiative lines Tier 2
  deck <- paste(rhtp_pdf_text(here::here("data/evidence/recheck/2026-09-24/NV/2026-02_nv_rht_stakeholder_meetings_02.26.pdf")),
                collapse = " ")
  expect_match(deck, "Funding: \\$26,989,741\\*")
  expect_match(deck, "\\$1,298,985\\*")
  expect_match(deck, "Pending approval of revised budget")
})

test_that("the award file now carries every award action on the 09-24 page", {
  skip_if_no_archive()
  live <- nv_live_roster_sections()
  expect_equal(nrow(live), 7L)
  expect_equal(sum(live$awards), 155L)
  recs <- nv_records()
  expect_equal(sum(!recs$withdrawn), 155L)
  d <- nv_disposition_table()
  expect_match(d$why[d$disposition == "RHTP_SUBAWARD_IN_FILE"],
               "Session 64 extracted all of them")
  # none of RCJ's five annual-report contractors is in the file, even now
  cand <- nv_classify_candidates()
  ven <- cand$awardee_name_clean[cand$disposition == "AGGREGATOR_PLACEHOLDER_OR_UNRESOLVED"]
  expect_false(any(tolower(ven) %in% tolower(recs$awardee)))
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
  expect_equal(inf$candidates, 42L)
  expect_equal(round(inf$face_value, 2), 131643055 + 68288726 + 1935762.9)
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
  # SESSION 49 ANSWERED IT. The question is RESOLVED and carries its
  # resolution; the invariant is that the row stays FINDABLE and says
  # something, not that it stays unanswered forever.
  expect_equal(row$queue_status, "RESOLVED")
  expect_true(nzchar(row$resolution))
  # It moved a COUNT and not a dollar, exactly as the row said it would.
  expect_true(grepl("27 of 73", row$resolution, fixed = TRUE))
  expect_true(grepl("$0 in either direction", row$dollar_effect, fixed = TRUE))
})

test_that("nothing was promoted: the soft set is still on §8's fallback", {
  skip_if_no_archive()
  recs <- nv_records()
  soft_all <- recs[grepl("RECIPIENT_TYPE_INFERRED", recs$flag_reason), ]
  # 23 on the 2026-08-31 rows (pre-overlay) + 34 on the 2026-09-24 rows.
  expect_equal(sum(soft_all$listed_from == "2026-09-24"), 34L)
  soft <- soft_all[soft_all$listed_from == "2026-08-31", ]
  expect_equal(nrow(soft), 23L)
  expect_true(all(soft$recipient_type == "NONPROFIT_CBO"))
  expect_true(all(soft$determination_confidence == "LOW"))
  # Names a reader would expect to see promoted, deliberately not promoted.
  for (nm in c("Renown Health", "Carson Valley Health", "Intermountain Health")) {
    expect_true(nm %in% soft$awardee, info = nm)
  }
})


# -- the committed CSV --------------------------------------------------------

# SESSION 49: THE COMMITTED CSV IS THE BUILDER'S OUTPUT *PLUS THE COMMITTED
# VERIFICATION OVERLAY*, and that is the honest form of this claim now. The
# verification queue re-typed rows in this file; writing those onto the CSV
# without saying so here would mean the next `--build` silently wiped them and
# no test complained. `vq_overlay()` reads
# `data/reference/verification_queue_2_changes.csv`, which is itself derived
# from a committed, SHA-256-pinned workbook, so the CSV is still fully
# reproducible from committed inputs -- the dependency is now explicit.
test_that("the committed CSV matches what the parser produces", {
  skip_if_no_archive()
  skip_if_not(file.exists(NV_OUT_CSV), "nv_year1_awardees.csv not built yet")
  on_disk <- readr::read_csv(NV_OUT_CSV, show_col_types = FALSE, progress = FALSE)
  built <- vq_overlay(nv_records(), "nv_year1_awardees.csv") %>%
    dplyr::select(dplyr::all_of(c(NV_COLUMN_ORDER, "basis_type",
                                  "verified_by", "verified_basis")))
  expect_equal(nrow(on_disk), nrow(built))
  expect_equal(names(on_disk), c(NV_COLUMN_ORDER, "basis_type",
                                 "verified_by", "verified_basis"))
  expect_equal(on_disk$awardee, built$awardee)
  expect_true(all(is.na(on_disk$amount)))
})

test_that("validate passes end to end", {
  skip_if_no_archive()
  expect_silent(suppressMessages(nv_validate()))
})


# -- §7: the mandatory basis exists at all (session 31) ----------------------

test_that("determination_basis is present and non-empty on every Nevada row", {
  # FINDING 2 OF THE SESSION 30 ELIGIBILITY SWEEP, AND NEVADA'S HALF OF IT WAS
  # NOT A WRONG SENTENCE BUT NO SENTENCE. §7 makes `determination_basis`
  # mandatory; Nevada computed both halves -- `classifier_basis` from the
  # recipient's name and `flow_basis` from §10.2 -- surfaced only the first as
  # `recipient_type_source`, and dropped the flow half on the floor. The sweep
  # found the two PASS_THROUGH rows with no stated basis, which is the field's
  # whole purpose failing on exactly the rows a reviewer comes back to.
  recs <- readr::read_csv(NV_OUT_CSV, show_col_types = FALSE, progress = FALSE)
  expect_true("determination_basis" %in% names(recs))
  expect_equal(nrow(recs), 156L)
  expect_false(any(is.na(recs$determination_basis) |
                     trimws(recs$determination_basis) == ""))

  # The two rows the sweep named, each now stating the reason it actually
  # carries.
  # SESSION 49 MOVED INCLINE VILLAGE, AND NOT BY ANSWERING ITS QUEUE ROW.
  # NV_INCLINE_VILLAGE_FOUNDATION_FLOW came back NONPROFIT_CBO, which settles
  # nothing about a flow. What moved it is §10.2's NEW hospital-foundation
  # row: it is the fundraising foundation of Incline Village Community
  # Hospital -- a NAMED hospital, in its own name -- so it is
  # HOSPITAL_OR_SYSTEM, and a re-type across that boundary re-runs §10.2's
  # DIRECT test by construction. Nevada prices nobody, so it moves a ROW and
  # $0. The PRIOR basis sentence is kept beside the new one (§2.1).
  incline <- recs[recs$awardee == "Incline Village Community Hospital Foundation", ]
  expect_equal(nrow(incline), 1L)
  expect_equal(incline$recipient_type, "HOSPITAL_OR_SYSTEM")
  expect_equal(incline$flow_type, "DIRECT")
  expect_true(is.na(incline$amount))
  expect_true(grepl("hospital-affiliated", incline$determination_basis))
  expect_true(grepl("PASS_THROUGH_UNRESOLVED", incline$determination_basis,
                    fixed = TRUE))

  # Session 31 re-coded nothing here; SESSION 49 did, and the count says so:
  # 20 named-hospital award actions -> 27 of 73, all of them at $0, because
  # NVHA publishes no per-recipient amount at all (Nevada's rule). SESSION 64
  # added 15 more on the 2026-09-24 rows -- 42 of 156, still $0.
  expect_equal(sum(recs$distributed_to_hospital == "Yes"), 42L)
  expect_equal(sum(recs$distributed_to_hospital[1:72] == "Yes"), 27L)
  expect_equal(sum(recs$hospital_attribution == "NAMED_HOSPITAL"), 42L)
  expect_true(all(is.na(recs$amount)))
})



# -- the probe (session 64) -------------------------------------------------

test_that("the probe's baseline is the 2026-09-24 archive, and it is silent on it", {
  skip_if_no_archive()
  expect_equal(NV_PROBE_PAGES$file[NV_PROBE_PAGES$key == "roster"],
               file.path("data/evidence/NV", nv_source("roster", "file")))
  arch <- lapply(stats::setNames(NV_PROBE_PAGES$file, NV_PROBE_PAGES$key),
                 function(f) rhtp_watch_reduce(here::here(f)))
  expect_silent(rhtp_assert_no_new_organisations_across(arch, arch, state = "NV"))
  # the live-page tripwires, fed the archive's own bytes, pass
  raw <- readBin(nv_path("roster"), "raw", file.info(nv_path("roster"))$size)
  expect_true(nv_assert_award_index(tables = nv_roster_tables(raw = raw),
                                    text = nv_html_text(raw = raw)))
})

test_that("THE COUNTERFACTUAL: against the 08-31 baseline, today's page FIRES", {
  # Session 63 expected exactly this: a probe baselined on the 2026-08-31 page
  # trips on the 2026-09-24 page. It must, or the name tripwire is not reading.
  skip_if_no_archive()
  old <- rhtp_watch_reduce(nv_path("roster_prior"))
  new <- rhtp_watch_reduce(nv_path("roster"))
  expect_error(rhtp_assert_no_new_organisations(new, old, state = "NV",
                                                page = "roster"),
               "ORGANISATION")
  # and the section-count tripwire fires on the old page's tables
  expect_error(nv_assert_award_index(tables = nv_roster_tables("roster_prior"),
                                     text = nv_html_text("roster_prior")))
})

test_that("--probe is wired through rhtp_probe_run and runs the name tripwire", {
  src <- paste(readLines(here::here("R", "03u_nv_year1_awardees.R")), collapse = "\n")
  expect_true(grepl('rhtp_probe_run("NV", nv_probe())', src, fixed = TRUE))
  expect_true(grepl("rhtp_assert_no_new_organisations_across", src, fixed = TRUE))
})
