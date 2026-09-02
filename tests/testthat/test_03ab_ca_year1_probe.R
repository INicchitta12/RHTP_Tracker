# California -- the negative, and the two controls that make it evidence.
#
# California is at SOLICITATION stage with its award window open NOW, so every
# assertion here is a tripwire whose failure is the signal. These run offline
# against the committed archive.
#
# THE WEIGHT OF THIS FILE IS ON ONE THING: California's eleven RCJ candidates
# are ELEVEN NAMED HOSPITALS carrying real amounts on real executed HCAI
# awards, and they are a state cigarette-tax seismic programme. Nothing about
# them looks wrong. So the tests that matter most are the ones that would fail
# if the SRHRP page ever stopped saying what disqualifies it.

source(here::here("R", "03ab_ca_year1_probe.R"))

test_that("no California award file exists, deliberately", {
  expect_false(file.exists(here::here(CA_AWARDS_CSV)))
  expect_silent(ca_assert_no_award_file())
})

test_that("the status table has no amount column, and cannot acquire one", {
  status <- rhtp_ca_year1_status()
  expect_false(any(c("amount", "round_amount", "amount_announced") %in%
                     names(status)))
  # Texas's device: the pool figures are the guides' own words, in a text
  # column, so no sum over this table can produce a California hospital dollar.
  expect_true("stated_pool" %in% names(status))
  expect_type(status$stated_pool, "character")
})


# -- §6.2: CMS's own Notice of Award ------------------------------------------

test_that("California publishes CMS's own Notice of Award, and it checks out", {
  expect_silent(ca_assert_noa_is_cms_award())
  noa <- ca_pdf_text("cms_noa")
  expect_true(stringr::str_detect(noa, stringr::fixed("93.798")))
  expect_true(stringr::str_detect(noa, stringr::fixed("RHTCMS332078-01-02")))
  expect_true(stringr::str_detect(noa, stringr::fixed("$233,639,308.47")))
})

test_that("the NOA's two dates are both present and are not the same claim", {
  noa <- ca_pdf_text("cms_noa")
  # The Federal Award Date is a REVISION date; the budget period start is the
  # project's 2025-12-29 anchor. A date test keyed on the former would read
  # California's award as three months late.
  expect_true(stringr::str_detect(noa, stringr::fixed("03/31/2026")))
  expect_true(stringr::str_detect(noa, stringr::fixed("12/29/2025")))
  expect_true(stringr::str_detect(noa, stringr::fixed("Revision (Budget)")))
  expect_equal(ca_noa_anchor(), "2025-12-29")
})

test_that("the tripwire fires if the NOA stops calling itself a revision", {
  noa <- ca_pdf_text("cms_noa")
  stripped <- stringr::str_replace(noa, stringr::fixed("Revision (Budget)"),
                                   "New")
  expect_error(ca_assert_noa_is_cms_award(noa = stripped),
               "Federal Award Date")
})

test_that("the provenance is programme-scoped, and losing it stops the build", {
  expect_silent(ca_assert_programme_provenance())
  txt <- ca_html_text("calrht")
  gone <- stringr::str_replace(
    txt, stringr::fixed(CA_PROGRAMME_SCOPED[["award"]]), "")
  expect_error(ca_assert_programme_provenance(calrht = gone),
               "programme-scoped")
})

test_that("the CMS footer is the STRONG form and is demoted anyway", {
  txt <- ca_html_text("calrht")
  # Session 27's axis: the subject NAMES the programme, so this is the strong
  # form -- and it is still used for the amount only, because the NOA exists.
  expect_true(stringr::str_detect(txt, stringr::fixed(CA_FOOTER_STRONG)))
  expect_true(stringr::str_detect(txt, stringr::fixed("The CalRHT program")))
  expect_silent(ca_assert_footer_corroborates(strict = FALSE))
})

test_that("a missing footer is reported non-strictly and fatal under --strict", {
  txt  <- ca_html_text("calrht")
  gone <- stringr::str_remove(txt, stringr::fixed(CA_FOOTER_STRONG))
  expect_message(res <- ca_assert_footer_corroborates(strict = FALSE,
                                                      calrht = gone),
                 "Non-strict")
  expect_true(is.na(res))
  expect_error(ca_assert_footer_corroborates(strict = TRUE, calrht = gone),
               "footer")
})

test_that("the one-cent disagreement is pinned in both directions", {
  # CMS's NOA says .47; HCAI's pages say .46; HCAI's FM-OB guide says .47.
  # Three figures, all pinned, none corrected (§8, Kansas's rule).
  expect_true(stringr::str_detect(ca_pdf_text("cms_noa"),
                                  stringr::fixed("$233,639,308.47")))
  expect_true(stringr::str_detect(ca_html_text("calrht"),
                                  stringr::fixed("$233,639,308.46")))
  expect_true(stringr::str_detect(ca_pdf_text("gg_wcap"),
                                  stringr::fixed("$233,639,308.47")))
  expect_equal(round(ca_allotment_anchor()), 233639308)
})


# -- the negative -------------------------------------------------------------

test_that("all four CalRHT opportunities are closed and name nobody", {
  expect_silent(ca_assert_no_award_roster())
  txt <- ca_html_text("funding")
  expect_equal(stringr::str_count(txt, stringr::fixed(CA_CLOSED_MARKER)),
               CA_CLOSED_EXPECTED)
})

test_that("the tripwire fires when a fifth opportunity appears", {
  txt <- ca_html_text("funding")
  more <- paste(txt, "Rural Behavioral Health Grants (Closed)")
  expect_error(ca_assert_no_award_roster(funding = more), "THIS IS THE SIGNAL")
})

test_that("the tripwire fires when an opportunity stops being closed", {
  txt <- ca_html_text("funding")
  awarded <- stringr::str_replace(
    txt, stringr::fixed("Accelerator Partners (Closed)"),
    "Accelerator Partners (Awardees Announced)")
  expect_error(ca_assert_no_award_roster(funding = awarded),
               "THIS IS THE SIGNAL")
})

test_that("the zero-width space in the WDRR heading is handled, not tripped over", {
  # HCAI's markup puts U+200B between "Retention" and "(Closed)". It is
  # invisible in every rendering and diff, so an assertion written from a
  # rendered copy fails with nothing to point at. The reduction strips it.
  raw <- readBin(ca_path("funding"), "raw", file.size(ca_path("funding")))
  bytes <- rawToChar(raw[raw != as.raw(0)])
  Encoding(bytes) <- "UTF-8"
  expect_true(stringr::str_detect(bytes, "​"))
  expect_false(stringr::str_detect(ca_html_text("funding"), "​"))
  expect_true(stringr::str_detect(ca_html_text("funding"),
                                  stringr::fixed(CA_POOL_WDRR_HEADING)))
})

test_that("the curly apostrophe is folded, for the same reason", {
  txt <- ca_html_text("calrht")
  expect_false(stringr::str_detect(txt, "’"))
  expect_true(stringr::str_detect(txt, stringr::fixed("California's approach")))
})

test_that("the awards are due NOW, and the guides say so", {
  expect_silent(ca_assert_award_dates_pending())
  # This is what makes California a negative WITH A DATE rather than one of
  # unknown age: WDRR's window closed two days before the file was built.
  expect_true(stringr::str_detect(ca_pdf_text("gg_wdrr"),
                                  stringr::fixed("to August 31, 2026")))
  expect_true(stringr::str_detect(ca_pdf_text("gg_ehr"),
                                  stringr::fixed("Notify Subrecipients September 2026")))
})

test_that("the tripwire fires when a guide loses its award milestone", {
  accel <- ca_pdf_text("gg_accel")
  gone  <- stringr::str_remove(accel,
                               stringr::fixed(CA_AWARD_MILESTONES[["accel"]]))
  expect_error(ca_assert_award_dates_pending(accel = gone), "award milestone")
})

test_that("the four pools are the guides' own figures", {
  expect_equal(CA_STATED$pool_accel + CA_STATED$pool_wdrr +
                 CA_STATED$pool_ehr + CA_STATED$pool_wcap, 111330000)
  expect_silent(ca_assert_award_dates_pending())
})

test_that("every eligible class is hospitals AMONG OTHERS, not hospitals only", {
  # New Hampshire's fifteenth question. ICAHN is `Yes` because Illinois
  # restricted eligibility to hospitals ONLY; FHC is `Unclear` because its
  # class names hospitals among others. Every CalRHT pool is FHC's shape, so
  # when California awards, no pool here is Illinois's coding.
  expect_silent(ca_assert_eligible_class_not_hospitals_only())
  ehr <- ca_pdf_text("gg_ehr")
  expect_true(stringr::str_detect(ehr, stringr::fixed("Rural Health Clinic (RHC)")))
  expect_true(stringr::str_detect(ehr, stringr::fixed("Health Care District")))
})

test_that("the tripwire fires if a pool becomes hospitals-only", {
  ehr  <- ca_pdf_text("gg_ehr")
  only <- stringr::str_remove(
    ehr, stringr::fixed(CA_ELIGIBLE_CLASS_MARKERS[["ehr"]]))
  expect_error(ca_assert_eligible_class_not_hospitals_only(ehr = only),
               "HOSPITALS ONLY")
})


# -- the SRHRP: both controls, on one page ------------------------------------

test_that("the SRHRP is California STATE money, in HCAI's own words", {
  expect_silent(ca_assert_srhrp_is_not_rhtp())
  txt <- ca_html_text("srhrp")
  expect_true(stringr::str_detect(txt, stringr::fixed(
    "California Electronic Cigarette Excise Tax")))
  expect_true(stringr::str_detect(txt, stringr::fixed(
    "Alfred E. Alquist Hospital Facilities Seismic Safety Act")))
})

test_that("the SRHRP page mentions RHTP zero times, and the absence is asserted", {
  txt <- ca_html_text("srhrp")
  expect_equal(stringr::str_count(txt, stringr::fixed("RHTP")), 0L)
  expect_equal(stringr::str_count(txt, stringr::fixed(
    "Rural Health Transformation")), 0L)
  expect_equal(stringr::str_count(txt, stringr::fixed("federal")), 0L)
})

test_that("the tripwire fires the day the SRHRP page mentions RHTP", {
  # If it ever does, either HCAI has begun funding seismic work with RHTP money
  # or two pages have been merged -- and the eleven candidates must be re-read
  # rather than left disposed of by a stale assertion.
  txt   <- ca_html_text("srhrp")
  mixed <- paste(txt, "This program is also supported in part by RHTP.")
  expect_error(ca_assert_srhrp_is_not_rhtp(srhrp = mixed),
               "THIS IS THE SIGNAL")
})

test_that("the tripwire fires if the SRHRP stops naming its funding source", {
  txt  <- ca_html_text("srhrp")
  gone <- stringr::str_remove(
    txt, stringr::fixed(CA_SRHRP_STATE_FUNDED[["tax"]]))
  expect_error(ca_assert_srhrp_is_not_rhtp(srhrp = gone),
               "disposes of all eleven")
})

test_that("the SRHRP is the POSITIVE control: HCAI does publish rosters", {
  # Without this, "CalRHT has published no roster" is indistinguishable from
  # "we are reading the wrong page".
  expect_silent(ca_assert_srhrp_is_award_control())
  txt <- ca_html_text("srhrp")
  expect_true(stringr::str_detect(txt, stringr::fixed(
    "grants (totaling $17.2 million) have been awarded")))
  expect_true(stringr::str_detect(txt, stringr::fixed("$3,525,000")))
})

test_that("losing the positive control stops the build", {
  txt  <- ca_html_text("srhrp")
  gone <- stringr::str_remove(
    txt, stringr::fixed(CA_SRHRP_AWARD_CONTROL[["awarded"]]))
  expect_error(ca_assert_srhrp_is_award_control(srhrp = gone),
               "means nothing")
})

test_that("102 named hospitals on the SRHRP page are ELIGIBLE, not recipients", {
  rows <- ca_assert_srhrp_eligibility_not_receipt()
  expect_length(rows, 102L)
  expect_true(all(stringr::str_detect(rows, "^\\d{5,}")))
  # §0.3's largest head count in this project, and it sits directly beneath
  # real awards on the same page.
  expect_true(stringr::str_detect(ca_html_text("srhrp"),
                                  stringr::fixed("SRHRP Eligible Hospitals")))
})

test_that("the row count is not the hospital count, and the reader knows it", {
  # The table has 105 <tr> rows: one header and TWO ENTIRELY BLANK spacer rows.
  # A reader that counted rows would report 104 hospitals. Each kept row must
  # open with HCAI's own facility id, so the blanks fall out for lack of
  # identity rather than by a threshold.
  p <- ca_path("srhrp")
  txt <- rawToChar(readBin(p, "raw", file.size(p)))
  Encoding(txt) <- "UTF-8"
  tab <- stringr::str_extract(txt, "(?s)<table.*?</table>")
  expect_equal(length(stringr::str_extract_all(tab, "(?s)<tr.*?</tr>")[[1]]),
               105L)
  expect_length(ca_srhrp_eligible_rows(), 102L)
})

test_that("the count moving is a signal, not something to shrug at", {
  expect_error(
    ca_assert_srhrp_eligibility_not_receipt(rows = character(90)),
    "do not let the count drift into a roster")
})

test_that("HCAI's newsroom is the channel control and names no RHTP award", {
  expect_silent(ca_assert_newsroom_control())
  news <- ca_html_text("newsroom")
  expect_equal(stringr::str_count(news, stringr::fixed("CalRHT")), 0L)
  expect_true(stringr::str_detect(news, stringr::fixed("Awards Scholarships")))
})

test_that("the newsroom tripwire fires the day CalRHT appears there", {
  news  <- ca_html_text("newsroom")
  added <- paste(news, "HCAI Announces CalRHT Accelerator Partner Awards")
  expect_error(ca_assert_newsroom_control(news = added), "THIS IS THE SIGNAL")
})


# -- §0.1: the candidate set --------------------------------------------------

test_that("all eleven RCJ candidates are SRHRP, and eleven are named hospitals", {
  cands <- ca_rcj_candidates()
  expect_equal(nrow(cands), 11L)
  prov <- paste(cands$source_doc_title, cands$solicitation_number)
  expect_true(all(stringr::str_detect(prov,
                                      stringr::fixed(CA_SRHRP_SOURCE_MARKER))))
  dispo <- rhtp_ca_rcj_disposition(cands)
  expect_equal(nrow(dispo), 1L)
  expect_equal(dispo$rows[1], 11L)
  expect_equal(dispo$named_hospital_rows[1], 11L)
  expect_equal(dispo$rcj_amount_sum[1], 5475000)
  expect_equal(dispo$disposition[1], "NOT_RHTP_STATE_PROGRAM")
})

test_that("the disposition refuses a candidate it does not cover", {
  cands <- ca_rcj_candidates()
  cands$source_doc_title[1] <- "CA - 2026 - CalRHT Accelerator Partner Awards"
  cands$solicitation_number[1] <- NA_character_
  expect_error(rhtp_ca_rcj_disposition(cands), "are NOT from")
})

test_that("the counts are derived from the record table, never typed", {
  cands <- ca_rcj_candidates()
  dispo <- rhtp_ca_rcj_disposition(cands)
  expect_equal(dispo$rows[1], nrow(cands))
  expect_equal(dispo$distinct_awardees[1],
               dplyr::n_distinct(cands$awardee_name_clean))
})

test_that("RCJ carries components, not grants -- so the row count is not the award count", {
  # George L Mee Memorial Hospital appears twice at $500,000 and $280,000,
  # which is HCAI's own published $780,000 grant split into its line items.
  cands <- ca_rcj_candidates()
  mee <- cands$amount_announced[
    stringr::str_detect(cands$awardee_name_clean,
                        stringr::fixed("George L Mee"))]
  expect_length(mee, 2L)
  expect_equal(sum(mee), 780000)
  expect_true(stringr::str_detect(ca_html_text("srhrp"),
                                  stringr::fixed("$780,000")))
})

test_that("the §6.2 registry catches all eleven, and by two filters", {
  swept <- readr::read_csv(
    here::here("data", "reference", "provenance_sweep_by_state.csv"),
    show_col_types = FALSE)
  ca <- swept[swept$state == "CA", ]
  expect_equal(ca$tier3_candidates, 11L)
  expect_equal(ca$caught_by_registry, 11L)
  # And the date test reaches them independently: the registry row supplies a
  # programme date (HCAI's own 2025-02-19 SRHRP webinar) for rows RCJ carries
  # no date for at all. New Hampshire's pattern -- two §6.2 filters, one row.
  expect_equal(ca$caught_predates_noa, 11L)
  expect_equal(ca$caught_amount, 5475000)
})

test_that("California reads INVESTIGATED_NO_LIST, so it cannot rank 1 again", {
  s <- readr::read_csv(
    here::here("data", "reference", "rcj_state_survey.csv"),
    show_col_types = FALSE)
  expect_equal(s$extraction_status[s$state == "CA"], "INVESTIGATED_NO_LIST")
  # And the CSV is BUILT from R/03k's constant rather than hand-edited, so the
  # constant is what a rebuild would read. Checked by reading the source rather
  # than by sourcing a build script into the test session.
  src <- readLines(here::here("R", "03k_rcj_state_survey.R"), warn = FALSE)
  decl <- grep("^SURVEY_INVESTIGATED_NO_LIST_STATES <-", src, value = TRUE)
  expect_length(decl, 1L)
  expect_true(grepl('"CA"', decl, fixed = TRUE))
})

test_that("the change test is a CONTENT digest, and it absorbs both mechanisms", {
  # hcai.ca.gov carries NO per-request nonce -- two fetches seconds apart are
  # byte-identical -- and a file digest STILL fails, for two reasons neither of
  # which this project had met. Measuring twice in quick succession is not a
  # stability test; that is the lesson, and it cost this file a wrong claim.
  raw <- readBin(ca_path("calrht"), "raw", file.size(ca_path("calrht")))

  # (1) A CACHE VARIANT: the same page served with or without a ~15 KB
  # ElasticPress autosuggest asset block.
  variant <- charToRaw(sub(
    "</head>",
    paste0("<script id=\"elasticpress-autosuggest-js-extra\">",
           "var epas = {\"query\":\"...\"};</script></head>"),
    rawToChar(raw), fixed = TRUE))
  expect_false(identical(digest::digest(raw, algo = "sha256", serialize = FALSE),
                         digest::digest(variant, algo = "sha256",
                                        serialize = FALSE)))
  expect_equal(ca_content_digest(raw), ca_content_digest(variant))

  # (2) RANDOMISED EMAIL OBFUSCATION: WordPress antispambot() re-rolls which
  # characters of a mailto address become HTML entities on every render. SAME
  # LENGTH, different bytes, identical rendered text -- so even a byte-count
  # check passes it.
  news <- rawToChar(readBin(ca_path("newsroom"), "raw",
                            file.size(ca_path("newsroom"))))
  expect_true(grepl("mailto:", news, fixed = TRUE))
  rerolled <- charToRaw(sub("mailto:H&#067;AIPre&#115;s&#064;",
                            "mailto:&#072;&#067;AIPress&#064;", news,
                            fixed = TRUE))
  expect_equal(ca_content_digest(charToRaw(news)), ca_content_digest(rerolled))
})

test_that("the probe and the assertions read the SAME reduction", {
  # Missouri's rule (session 29): a probe that reduces differently from the
  # tripwires it feeds drifts away from them silently, and the drift shows up
  # as a tripwire that stops firing.
  raw <- readBin(ca_path("funding"), "raw", file.size(ca_path("funding")))
  expect_equal(ca_content_digest(raw),
               digest::digest(ca_html_text("funding"), algo = "sha256",
                              serialize = FALSE))
})

test_that("--validate passes end to end, offline", {
  expect_silent(rhtp_ca_assert())
})
