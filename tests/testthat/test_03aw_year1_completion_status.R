# Tests for R/03aw_year1_completion_status.R -- which states have FINISHED
# Year 1 awarding, and the hospital share where they have.

source(here::here("R", "03aw_year1_completion_status.R"))

status <- y1_build_status()
share  <- y1_hospital_share(status)

test_that("every EXTRACTED state has exactly one status row, and no other state does", {
  survey <- readr::read_csv(here::here("data", "reference", "rcj_state_survey.csv"),
                            show_col_types = FALSE)
  expect_setequal(status$state, survey$state[survey$extraction_status == "EXTRACTED"])
  expect_equal(anyDuplicated(status$state), 0L)
  expect_true(all(status$year1_status %in% Y1_STATUS_CODES))
})

test_that("COMPLETE rests on a statement AND no recorded remainder -- never on a percentage", {
  # Session 69: Arkansas is the third, on the Governor's "completes the
  # distribution of the $208 million" and four initiatives all awarded.
  expect_setequal(status$state[status$year1_status == "COMPLETE"],
                  c("AL", "AR", "FL", "GA"))
  bad <- Y1_STATUS
  bad$year1_status[bad$state == "AK"] <- "COMPLETE"   # 87.9% of allotment, rolling
  expect_error(y1_assert_status(bad), "COMPLETE without")
  # Session 90: SD, the last UNKNOWN state, moved to PARTIAL on its CCBHC
  # release ("The next round of funding is anticipated later this fall"). The
  # counterfactual is now an UNKNOWN carrying a recorded remainder.
  bad <- Y1_STATUS
  bad$year1_status[bad$state == "SD"] <- "UNKNOWN"
  expect_error(y1_assert_status(bad), "UNKNOWN where")
  expect_equal(status$year1_status[status$state == "SD"], "PARTIAL")
})

test_that("Alabama's eleventh initiative has no Year 1 money, in ADECA's own words (session 84)", {
  # R/utils_pdf_text.R does not decode the manual's fonts; poppler does.
  skip_if(!nzchar(Sys.which("pdftotext")), "pdftotext not installed")
  pdf <- function(f) paste(system2("pdftotext", c(shQuote(here::here("data/evidence/AL", f)), "-"),
                                   stdout = TRUE), collapse = " ")
  expect_match(gsub("\\s+", " ", pdf("2026-10-02_adeca_arhtp_program_manual_proposed_final_2026-09-08.pdf")),
               "begins program Year 2 / 2027; no Year 1 funding", fixed = TRUE)
  expect_match(gsub("\\s+", " ", pdf("2026-10-02_adeca_arhtp_intro_presentation_2026-06.pdf")),
               "not budgeted in Year 1 of Program", fixed = TRUE)
  expect_equal(status$remaining_unawarded[status$state == "AL"], "No")
})

test_that("Michigan's 'all RHTP Subrecipients' is a roster claim, not a completed round", {
  expect_equal(status$year1_status[status$state == "MI"], "PARTIAL")
  expect_match(status$evidence[status$state == "MI"], "additional RHTP GFOs")
})

test_that("the completeness sentences are in the archived sources", {
  txt <- function(p) paste(readLines(here::here(p), warn = FALSE), collapse = " ")
  expect_match(txt("data/evidence/recheck/2026-08-29/FL/FL_governor_188m_release.html"),
               "awarded the full scope of Florida", fixed = TRUE)
  expect_match(txt("data/evidence/GA/2026-08-27_great_health_phase4_awards.html"),
               "complete the initial Year 1 award cycle", fixed = TRUE)
  expect_match(txt("data/evidence/recheck/2026-09-25/AR/2026-09-24_governor_sanders_54_6_million_awarded.html"),
               "completes the distribution of the $208 million", fixed = TRUE)
})

test_that("Arkansas's two rounds are both counted, and the remainder is not an initiative", {
  ar <- status[status$state == "AR", ]
  expect_equal(ar$published_priced, 203862687.29)
  expect_equal(ar$pct_priced, 97.6)
  expect_equal(ar$rows, 80)
  expect_match(ar$evidence, "ar_year1_allotment_gap.csv", fixed = TRUE)
})

test_that("figures are recomputed from the award files, and Georgia is summed per pool", {
  ga <- status[status$state == "GA", ]
  expect_equal(ga$published_incl_pool_level, 197148327)
  expect_lt(ga$published_priced, ga$published_incl_pool_level)
  fl <- status[status$state == "FL", ]
  expect_equal(round(fl$published_priced), 188201256)
  # New Hampshire's CDFA "up to $40 million" is a ceiling and is not counted.
  nh <- status[status$state == "NH", ]
  expect_equal(nh$pool_level_unpriced, 0)
})

test_that("the hospital share is reported for COMPLETE states only, as a bounded range", {
  expect_setequal(share$state, c("AL", "AR", "FL", "GA"))
  # SESSION 84: Alabama. Community Medicine has no Year 1 money (ADECA
  # Program Manual 10.10), so the Governor's "round out year one" stands.
  expect_equal(share$share_floor_pct[share$state == "AL"], 52.6)
  expect_equal(share$named_hospital_rows[share$state == "AL"], 91)
  expect_equal(share$named_hospital_usd[share$state == "AL"], 104434859)
  # Arkansas: both rounds' NAMED_HOSPITAL rows over both rounds' awards. No
  # priced row is Unclear, so the ceiling equals the floor; the open queue
  # rows (AR_R2_QUEUED_FORM, AR_R2_RECIPIENT_FORM_NOT_STATED) are all `No`
  # and are reported beside this, not inside it.
  # SESSION 71: 54.6% -> 63.0%. UAMS's four rows (+$17,060,066) are
  # HOSPITAL_OR_SYSTEM on its CMS hospital enrolment (CCN 040016), carrying
  # recipient_subtype = ACADEMIC_HEALTH_CENTER so they can be subtracted.
  expect_equal(share$share_floor_pct[share$state == "AR"], 63.0)
  expect_equal(share$named_hospital_rows[share$state == "AR"], 34)
  expect_equal(round(share$named_hospital_usd[share$state == "AR"], 2), 128336961.52)
  expect_true(all(share$share_floor_pct <= share$share_ceiling_pct))
  expect_equal(share$share_floor_pct[share$state == "FL"], 26.2)
  # session 58 settled Florida's five Unclear rows, so its ceiling IS its floor
  expect_equal(share$share_ceiling_pct[share$state == "FL"], 26.2)
  expect_equal(share$unclear_priced_usd[share$state == "FL"], 0)
  expect_equal(share$share_floor_pct[share$state == "GA"], 45.8)
  # SESSION 71: + Emory's $6,209,688 pool (Emory is an enrolled hospital).
  expect_equal(share$mixed_pools_with_unpriced_named_hospitals_usd[share$state == "GA"], 28344688)
  expect_equal(share$share_ceiling_pct[share$state == "GA"], 60.2)
})

test_that("COMPLETE is a statement about the ROUND; the intent status is carried per state (session 70)", {
  # Florida and Georgia publish awards; every Arkansas row is a notice of
  # intent pending a DF&A agreement. Derived from each row's own
  # validation_source_type, never from the state.
  s <- share[order(share$state), ]
  expect_equal(s$intent_rows, c(0, 80, 0, 0))
  expect_equal(s$pct_priced_on_intent, c(0, 100, 0, 0))
  expect_match(s$award_action_stage[s$state == "AL"], "^AWARDED")
  expect_match(s$award_action_stage[s$state == "AR"], "^NOTICE OF INTENT")
  expect_match(s$award_action_stage[s$state == "FL"], "^AWARDED")
  expect_match(s$award_action_stage[s$state == "GA"], "^AWARDED")
  # the same numbers sit in the 31-state table, where a PARTIAL state can
  # also be all-intent (Oregon, Alaska) -- so the field is never read off
  # year1_status.
  expect_equal(status$pct_priced_on_intent[status$state == "AR"], 100)
  expect_equal(status$pct_priced_on_intent[status$state == "OR"], 100)
  # a COMPLETE state added without a stage sentence fails the build
  expect_true(all(share$state %in% names(Y1_AWARD_STAGE)))
})

test_that("session 85: AL's AHC and GENERAL_KNOWLEDGE slices are carried and subtractable", {
  al <- share[share$state == "AL", ]
  expect_equal(al$named_hospital_rows, 91L)
  expect_equal(al$named_hospital_usd, 104434859)
  expect_equal(al$ahc_subtype_usd, 18308866)          # UAB and USA, R/03bj
  expect_equal(al$general_knowledge_usd, 3913694)     # Greene County bridge, LOW
  expect_equal(al$named_hospital_usd_excl_ahc_and_gk, 104434859 - 18308866 - 3913694)
  expect_equal(al$share_floor_excl_ahc_and_gk_pct, 41.4)
  # Every COMPLETE state carries the columns, and removing a slice never
  # raises a share.
  expect_true(all(share$share_floor_excl_ahc_and_gk_pct <= share$share_floor_pct))
  expect_true(all(share$named_hospital_usd_excl_ahc_and_gk <= share$named_hospital_usd))
  # Alabama is AWARDED on the Governor's word and is NOT a notice of intent:
  # no AL row is NOTICE_OF_INTENT_TO_AWARD, and the stage text says so.
  expect_equal(al$intent_rows, 0)
  expect_match(al$award_action_stage, "NOT A NOTICE OF INTENT", fixed = TRUE)
})
