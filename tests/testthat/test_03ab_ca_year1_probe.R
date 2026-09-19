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


# -- the Rural Health Policy Council: governance, and a compounding trap -------
#
# Added session 36, when the scheduled watch reported the CalRHT programme page
# CHANGED for the first time. The change was ONE navigation link to a council
# that was already linked from the archived page — so nothing about California's
# awards moved — but the council is a NAMED ROSTER on the CalRHT estate, which
# is the shape this project has been caught by three times (Missouri's Hub
# Anchors, Connecticut's leadership team, Indiana's committee members).

test_that("the RHPC pages are archived and carry a roster of PEOPLE", {
  expect_silent(ca_assert_rhpc_is_governance())
  expect_true(file.exists(ca_path("rhpc")))
  expect_true(file.exists(ca_path("rhpc_members")))
  expect_true(stringr::str_detect(ca_html_text("rhpc_members"),
                                  stringr::fixed("Meet the RHPC Members")))
})

test_that("neither RHPC page carries roster-of-recipients language", {
  # Measured, not assumed: zero matches on both live pages on 2026-09-09.
  for (k in c("rhpc", "rhpc_members")) {
    txt <- ca_html_text(k)
    for (p in CA_RHPC_AWARD_POSTED) {
      expect_false(stringr::str_detect(txt, stringr::regex(p, ignore_case = TRUE)),
                   info = paste(k, p))
    }
  }
})

test_that("the RHPC tripwire fires on each award phrase, on each page", {
  r <- ca_html_text("rhpc"); m <- ca_html_text("rhpc_members")
  for (phrase in c("have been awarded", "list of awardees", "grant recipients")) {
    expect_error(ca_assert_rhpc_is_governance(rhpc = paste(r, phrase),
                                              members = m),
                 "award language has appeared", info = phrase)
    expect_error(ca_assert_rhpc_is_governance(rhpc = r,
                                              members = paste(m, phrase)),
                 "award language has appeared", info = phrase)
  }
})

test_that("the phrase set excludes words that occur in ordinary bio prose", {
  # A tripwire that cries wolf gets ignored, and the next CHANGED — which may
  # be the award roster — gets ignored with it (Missouri's Incapsula lesson).
  expect_false("subrecipient" %in% CA_RHPC_AWARD_POSTED)
  expect_false("awardees" %in% CA_RHPC_AWARD_POSTED)
})

test_that("FOUR RHPC members are hospital executives, and every employer is on the SRHRP page", {
  # THE COMPOUNDING TRAP. These hospitals are named on the CalRHT estate (as
  # council-member employers) AND on HCAI's own SRHRP page (as seismic
  # awardees or as eligible hospitals). Two independent wrong reasons pointing
  # at the same hospitals: a cross-reference would read as corroboration and
  # not one of them is an RHTP award.
  members <- ca_html_text("rhpc_members")
  for (i in seq_len(nrow(CA_RHPC_HOSPITAL_EMPLOYERS))) {
    r <- CA_RHPC_HOSPITAL_EMPLOYERS[i, ]
    expect_true(stringr::str_detect(members, stringr::fixed(r$employer)),
                info = r$employer)
    expect_true(stringr::str_detect(members, stringr::fixed(r$member)),
                info = r$member)
    expect_equal(ca_srhrp_position(r$srhrp_name), r$srhrp_page,
                 info = r$srhrp_name)
  }
  expect_equal(nrow(CA_RHPC_HOSPITAL_EMPLOYERS), 4L)
})

test_that("the SESSION 48 pair is NOT in RCJ's eleven, which is what widens the trap", {
  # Session 45's two employers overlap RCJ's candidate list, so a session
  # working from the aggregator matches them. Session 48's two do NOT -- and
  # they are on the state's own page anyway, one of them as a NAMED, PRICED
  # AWARD RCJ does not carry. So avoiding the aggregator does not avoid the
  # trap, which is the half worth testing.
  cands <- ca_rcj_candidates()$awardee_name_clean
  s45 <- CA_RHPC_HOSPITAL_EMPLOYERS[CA_RHPC_HOSPITAL_EMPLOYERS$since_session == 45L, ]
  s48 <- CA_RHPC_HOSPITAL_EMPLOYERS[CA_RHPC_HOSPITAL_EMPLOYERS$since_session == 48L, ]
  expect_equal(nrow(s45), 2L)
  expect_equal(nrow(s48), 2L)
  expect_true(all(s45$in_rcj_candidates))
  expect_false(any(s48$in_rcj_candidates))

  # the roster spells them with a hyphen and without "and Rural Health Clinic";
  # match on the distinctive stem so the two spellings meet
  expect_true(any(stringr::str_detect(cands, "Community Memorial Hospital")))
  expect_true(any(stringr::str_detect(cands, "Plumas District Hospital")))
  # and RCJ genuinely does not carry either session-48 employer
  expect_false(any(stringr::str_detect(cands, "Adventist")))
  expect_false(any(stringr::str_detect(cands, "Marshall")))

  # Adventist Health Reedley is one of the five HCAI names AND prices
  srhrp <- ca_html_text("srhrp")
  expect_true(grepl("Adventist Health Reedley (Sierra Kings Health Care District) - $1,325,000",
                    srhrp, fixed = TRUE))
})

test_that("ca_srhrp_position separates an AWARD from an ELIGIBILITY row", {
  # §0.3 made mechanical. Both blocks are on one page and the eligible table
  # is the largest §0.3 table in this project.
  expect_equal(ca_srhrp_position("Mountains Community Hospital"),
               "AWARDED_AND_PRICED")
  expect_equal(ca_srhrp_position("Marshall Medical Center"),
               "ELIGIBLE_TABLE_ONLY")
  expect_true(is.na(ca_srhrp_position("Nowhere General Hospital")))
  # and it refuses rather than guessing if HCAI drops the awarded block
  gutted <- stringr::str_remove(ca_html_text("srhrp"),
                                stringr::fixed("have been awarded, including grants for:"))
  expect_error(ca_srhrp_position("Marshall Medical Center", srhrp = gutted),
               "no longer carries its awarded-grants block")
})

test_that("an employer moving into the awarded block stops the build", {
  # THE COUNTERFACTUAL THAT MATTERS: Marshall Medical Center is eligible and
  # nothing more today. If HCAI awarded it, the note's meaning changes from
  # §0.3 to §0.1 -- and that must fail rather than quietly stay true.
  srhrp <- ca_html_text("srhrp")
  promoted <- stringr::str_replace(
    srhrp,
    stringr::fixed("have been awarded, including grants for:"),
    "have been awarded, including grants for: Marshall Medical Center - $1 For testing.")
  expect_error(
    ca_assert_rhpc_is_governance(srhrp = promoted),
    "now reads AWARDED_AND_PRICED on the SRHRP page")
})

test_that("losing any pinned hospital stops the build", {
  m <- ca_html_text("rhpc_members")
  for (h in CA_RHPC_HOSPITAL_EMPLOYERS$employer) {
    stripped <- stringr::str_remove_all(m, stringr::fixed(h))
    expect_error(ca_assert_rhpc_is_governance(rhpc = ca_html_text("rhpc"),
                                              members = stripped),
                 "no longer on the RHPC roster", info = h)
  }
})

test_that("the council GREW, and the member count is derived rather than typed", {
  # Session 45 typed "seventeen" into the status row, the manifest and this
  # file's prose. Session 48's firing found NINETEEN and all three were wrong
  # at once, with nothing pointing at them -- session 46's lesson recurring in
  # the function session 45 wrote.
  expect_equal(ca_rhpc_member_count(), 19L)

  # it reads HCAI's own markup, one <h3 class="wp-block-heading"> per member
  raw <- readBin(ca_path("rhpc_members"), "raw",
                 file.size(ca_path("rhpc_members")))
  expect_equal(
    length(gregexpr('<h3 class="wp-block-heading"', rawToChar(raw),
                    fixed = TRUE)[[1]]),
    ca_rhpc_member_count())

  # both new members are on the roster, with their employers
  members <- ca_html_text("rhpc_members")
  expect_true(grepl("Dr. Raul Ayala", members, fixed = TRUE))
  expect_true(grepl("Martin Entwistle", members, fixed = TRUE))
  expect_true(grepl("Adventist Health", members, fixed = TRUE))
  expect_true(grepl("Marshall Medical Center", members, fixed = TRUE))

  # and nobody was removed: session 45's seventeen are all still there
  for (n in c("Ana Acton", "Joy Dockter", "Kirk Fermin", "Hernando Garzon",
              "Orvin Hanson", "Virginia Q. Hedrick", "Haady Lashkari",
              "Lori Link", "Rita Nguyen", "Jeffrey Norris", "Tim Rine",
              "Colleen Rodriguez", "James F. Schlund", "Monica Soni",
              "Dan Southard", "Colleen Townsend", "Ryan Witz")) {
    expect_true(grepl(n, members, fixed = TRUE), info = n)
  }

  # the count refuses to return a number smaller than the pinned employers
  expect_error(ca_rhpc_member_count(raw = charToRaw("<html>nothing</html>")),
               "fewer than the 4 hospital employers")
})

test_that("no typed member count survives in the source or the artifacts", {
  lines <- readLines(here::here("R", "03ab_ca_year1_probe.R"), warn = FALSE)
  # "seventeen" may survive as HISTORY -- in a comment, or in a string that
  # says outright that the count MOVED -- but never as a live count.
  for (m in grep("[Ss]eventeen", lines, value = TRUE)) {
    expect_true(grepl("^\\s*#", m) || grepl("MOVED|moved", m), info = m)
  }
  status <- readr::read_csv(here::here("data/reference/ca_year1_status.csv"),
                            show_col_types = FALSE)
  rhpc <- status[grepl("RHPC", status[[2]]), ]
  expect_equal(nrow(rhpc), 1L)
  one <- paste(unlist(rhpc), collapse = " ")
  expect_true(grepl("19 named individuals", one, fixed = TRUE))
  expect_false(grepl("Seventeen named", one, fixed = TRUE))
  # and the session number that session 46 corrected in the manifest was still
  # wrong here: the RHPC was added in session 45, not 36
  expect_true(grepl("Added session 45", one, fixed = TRUE))
  expect_false(grepl("Added session 36", one, fixed = TRUE))
})

test_that("the FOURTH global-menu move is a list re-population, not a rename", {
  # 09-12 renamed a nav label (+12 on every page); 09-16 swapped one Data
  # Resources item (-6); 09-19 replaced the whole Featured Visualizations
  # list (-69). Three firings, three nav edits, same mechanism -- which is why
  # the nav is re-baselined rather than reduced away.
  added <- c("Prescription Drugs Introduced to Market",
             "Wholesale Acquisition Cost (WAC) Increase Report Data - Cumulative",
             "Post Coronary Artery Bypass Graft (CABG) Readmissions and Complications")
  dropped <- c("Inpatient Mortality Indicators",
               "California Postoperative Sepsis Outcomes for Inpatient Elective Surgeries")
  for (key in CA_PROBE_KEYS) {
    txt <- ca_reduce_html(readBin(ca_path(key), "raw", file.size(ca_path(key))))
    for (a in added)   expect_true(grepl(a, txt, fixed = TRUE), info = paste(key, a))
    for (d in dropped) expect_false(grepl(d, txt, fixed = TRUE), info = paste(key, d))
  }
  # the SRHRP control moved by the SAME -69 and by nothing else: its awarded
  # block and its 102-row eligible table are untouched
  srhrp <- ca_html_text("srhrp")
  expect_equal(length(gregexpr("[0-9]{5} - [A-Z]", srhrp)[[1]]), 102L)
  expect_equal(length(gregexpr("For MTCAP|For SPC|For MTCAPs", srhrp)[[1]]) > 0, TRUE)
})

test_that("the RHPC is in the assert wrapper, so it runs every validate", {
  expect_silent(rhtp_ca_assert())
  body <- paste(deparse(rhtp_ca_assert), collapse = " ")
  expect_true(grepl("ca_assert_rhpc_is_governance", body, fixed = TRUE))
})


test_that("the status table gains the RHPC row and still has no amount column", {
  status <- rhtp_ca_year1_status()
  expect_equal(nrow(status), 7L)
  expect_false(any(c("amount", "round_amount", "amount_announced") %in%
                     names(status)))
  row <- status[stringr::str_detect(status$channel, "Rural Health Policy Council"), ]
  expect_equal(nrow(row), 1L)
  expect_equal(row$stage, "GOVERNANCE_ONLY")
  expect_equal(row$publishes_roster, "No")
})


test_that("the RHPC pages are watched LIVE, not only offline", {
  # Session 25's Indiana lesson: --validate reads the committed copy and can
  # only answer "was this true when the archive was taken?". The probe is what
  # answers "is it true now", so the governance tripwire belongs in both.
  expect_true(all(c("rhpc", "rhpc_members") %in% CA_PROBE_KEYS))
  expect_true(all(CA_PROBE_KEYS %in% CA_SOURCES$key))
  body <- paste(deparse(ca_probe), collapse = " ")
  expect_true(grepl("ca_assert_rhpc_is_governance", body, fixed = TRUE))
})

# -- session 46: the third digest mechanism, and why the nav stays in ---------

test_that("the THIRD mechanism moves every watched page at once, and it is the nav", {
  # Measured 2026-09-12, on the watch's fourth firing. HCAI renamed a label in
  # its SITE-WIDE navigation menu -- 'Reproductive Health Care Access
  # Initiative' -> 'Reproductive Health and Gender Affirming Care Programs' --
  # so all five probed pages AND the SRHRP control reported CHANGED in one run,
  # each by EXACTLY +12 characters of reduced text. Nothing about RHTP moved.
  #
  # The two mechanisms above are per-render noise a reduction can absorb. This
  # one is a REAL, PERSISTENT content change on every page of the estate, so it
  # cannot be absorbed -- only re-baselined.
  old_label <- "Reproductive Health Care Access Initiative"
  new_label <- "Reproductive Health and Gender Affirming Care Programs"
  expect_equal(nchar(new_label) - nchar(old_label), 12L)

  for (key in CA_PROBE_KEYS) {
    raw <- readBin(ca_path(key), "raw", file.size(ca_path(key)))
    # every watched page carries the renamed label, because the menu is global
    expect_true(grepl(new_label, ca_reduce_html(raw), fixed = TRUE),
                info = key)
    # and rolling it back moves the CONTENT digest, not just the bytes: this is
    # the mechanism reporting CHANGED, reproduced offline
    rolled <- charToRaw(gsub(new_label, old_label, rawToChar(raw), fixed = TRUE))
    expect_false(identical(ca_content_digest(raw), ca_content_digest(rolled)),
                 info = key)
    expect_equal(nchar(ca_reduce_html(raw)) - nchar(ca_reduce_html(rolled)), 12L,
                 info = key)
  }
})

test_that("the reduction KEEPS the navigation, so an award link in it is catchable", {
  # THE DECISION, NOT AN ACCIDENT. Discarding the global menu would silence the
  # mechanism above for good -- and would also silence a new 'CalRHT Awardees'
  # menu item, which is the first place an award page would be linked from. So
  # the noise is paid for on the baseline side and the nav stays in scope.
  raw <- readBin(ca_path("calrht"), "raw", file.size(ca_path("calrht")))
  txt <- ca_reduce_html(raw)

  # menu items from elsewhere on HCAI's estate survive the reduction
  expect_true(grepl("Hospital Fair Billing", txt, fixed = TRUE))
  expect_true(grepl("CalRx Program", txt, fixed = TRUE))

  # and an award link planted in the menu reaches the tripwire
  planted <- charToRaw(sub("Hospital Fair Billing",
                           "CalRHT Awardees have been awarded",
                           rawToChar(raw), fixed = TRUE))
  expect_false(identical(ca_content_digest(raw), ca_content_digest(planted)))
  expect_error(ca_assert_rhpc_is_governance(rhpc = ca_reduce_html(planted)),
               regexp = "awarded|award")
})

test_that("the MANIFEST's standing claims are derived, never typed", {
  # Session 45 found this manifest still asserting session 34's RETRACTED claim
  # that a file digest was the change test, because ca_write_manifest() was
  # corrected and --fetch was never re-run. Two more typed values had gone the
  # same way by session 46: a character count and an archive date.
  man <- readLines(file.path(CA_EVIDENCE_DIR, "MANIFEST.txt"), warn = FALSE)
  one <- paste(man, collapse = "\n")

  # the governance pages were added in session 45, not 36
  expect_true(any(grepl("ADDED SESSION 45", man, fixed = TRUE)))
  expect_false(any(grepl("ADDED SESSION 36", man, fixed = TRUE)))

  # the character count matches the archive it describes, whatever it is today
  calrht <- readBin(ca_path("calrht"), "raw", file.size(ca_path("calrht")))
  expect_true(grepl(paste0("reduces to ",
                           format(nchar(ca_reduce_html(calrht)), big.mark = ",")),
                    one, fixed = TRUE))

  # no single archive date is claimed for a set of files refreshed on many days
  expect_false(grepl("This archive was taken", one, fixed = TRUE))
  expect_true(grepl("bytes were last refreshed", one, fixed = TRUE))

  # and the retracted session-34 claim has not come back
  expect_false(grepl("digests are STABLE", one, fixed = TRUE))
  expect_true(grepl("FILE DIGESTS ARE NOT A CHANGE TEST", one, fixed = TRUE))

  # the third mechanism is written down where the next reader will meet it
  expect_true(grepl("Gender Affirming", one, fixed = TRUE))
  expect_true(grepl("NOT REDUCED AWAY", one, fixed = TRUE))
})

# -- session 47: two NOA revisions, and the drift that is the finding --------

test_that("BOTH Notice of Award revisions are archived and both pass", {
  # Alaska's rule and Iowa's: a document's movement is only measurable against
  # the one it moved from, so -01-02 is KEPT rather than replaced by -01-04.
  expect_setequal(CA_NOA_REVISIONS$key, c("cms_noa", "cms_noa_r04"))
  for (k in CA_NOA_REVISIONS$key) {
    expect_true(file.exists(ca_path(k)), info = k)
    expect_silent(ca_assert_noa_is_cms_award(key = k))
  }
  expect_silent(ca_assert_noa_revisions())
})

test_that("the two revisions agree on every invariant and differ on the rest", {
  # THE POINT: what a revision may move is paperwork; what it may not move is
  # the award. Read out of both PDFs rather than asserted from the table.
  r02 <- ca_pdf_text("cms_noa")
  r04 <- ca_pdf_text("cms_noa_r04")

  for (nm in names(CA_NOA_INVARIANT)) {
    expect_true(stringr::str_detect(r02, stringr::fixed(CA_NOA_INVARIANT[[nm]])),
                info = paste("r02", nm))
    expect_true(stringr::str_detect(r04, stringr::fixed(CA_NOA_INVARIANT[[nm]])),
                info = paste("r04", nm))
  }
  # the amount and the budget period are identical TO THE CENT and TO THE DAY
  expect_true(stringr::str_detect(r04, stringr::fixed("$233,639,308.47")))
  expect_true(stringr::str_detect(r04, stringr::fixed("12/29/2025")))
  expect_true(stringr::str_detect(r04, stringr::fixed("10/30/2026")))

  # and the per-revision fields are genuinely different documents
  expect_true(stringr::str_detect(r02, stringr::fixed("RHTCMS332078-01-02")))
  expect_false(stringr::str_detect(r02, stringr::fixed("RHTCMS332078-01-04")))
  expect_true(stringr::str_detect(r04, stringr::fixed("RHTCMS332078-01-04")))
  expect_false(stringr::str_detect(r04, stringr::fixed("RHTCMS332078-01-02")))
  expect_false(stringr::str_detect(r04, stringr::fixed("03/31/2026")))
})

test_that("the later revision moves NO money and says so itself", {
  # Its own Remarks field is what makes this a paperwork change rather than a
  # finding about California's award.
  r04 <- ca_pdf_text("cms_noa_r04")
  expect_true(stringr::str_detect(r04, stringr::fixed(
    "approves the key personnel change")))
  expect_true(stringr::str_detect(r04, stringr::fixed(
    "All other terms and conditions remain in effect")))
  # "Revision (NoA Other)" is a THIRD action type: every other NOA in this
  # repository reads "New" or "Revision (Budget)".
  expect_true(stringr::str_detect(r04, stringr::fixed("Revision (NoA Other)")))
  expect_false(stringr::str_detect(r04, stringr::fixed("Revision (Budget)")))

  # 95.5% of the award sits in CONTRACTUAL, and that is a budget line naming
  # nobody -- not a roster, not a pool anyone has been awarded (§0.2, §0.3).
  expect_true(stringr::str_detect(r04, stringr::fixed("$223,227,780.00")))
  expect_true(stringr::str_detect(r04, stringr::fixed("$227,464,825.47")))
  # the approved budget closes on the award total
  expect_equal(227464825.47 + 6174483.00, 233639308.47)
})

test_that("SESSION 36'S DATE PIN IS NOW MEASURED TWICE ON ONE STATE", {
  # Session 36 pinned the anchor to the budget period start and argued from
  # THREE states' revised documents that "the error grows with every
  # revision". California is the same award, twice, and the gap grew.
  gaps <- ca_assert_noa_revisions()
  expect_equal(gaps, c(92L, 242L))
  # wider than Connecticut's +206, which was the widest on record
  expect_gt(max(gaps), 206L)
  # and the anchor itself has NOT moved
  expect_equal(ca_noa_anchor(), "2025-12-29")
})

test_that("a revision that moved the amount or the budget period would FAIL", {
  # The counterfactual, driven: the invariants are what separate a paperwork
  # revision from a finding about the award.
  r04 <- ca_pdf_text("cms_noa_r04")
  moved_amount <- stringr::str_replace_all(
    r04, stringr::fixed("$233,639,308.47"), "$199,000,000.00")
  expect_error(ca_assert_noa_is_cms_award(noa = moved_amount, key = "cms_noa_r04"),
               regexp = "amount")
  moved_period <- stringr::str_replace_all(
    r04, stringr::fixed("12/29/2025"), "08/28/2026")
  expect_error(ca_assert_noa_is_cms_award(noa = moved_period, key = "cms_noa_r04"),
               regexp = "budget_start")
  # and a key that is not an archived revision is refused rather than guessed
  expect_error(ca_assert_noa_is_cms_award(key = "cms_noa_r05"),
               regexp = "unknown Notice of Award revision")
})

test_that("the programme page's own NOA label is what watches for revision 05", {
  # THE WATCH DID NOT CATCH -01-04 BY DESIGN -- it caught it by luck, in a
  # reduced-text diff nobody was required to read, because a PDF has no
  # ca_reduce_html() reduction and cms_noa is not in CA_PROBE_KEYS.
  expect_false("cms_noa" %in% CA_PROBE_KEYS)
  expect_false("cms_noa_r04" %in% CA_PROBE_KEYS)

  calrht <- ca_html_text("calrht")
  expect_equal(stringr::str_squish(ca_assert_noa_label_current(calrht = calrht)),
               "August 28, 2026")

  # a label naming a revision this repository does not hold STOPS THE BUILD
  future <- stringr::str_replace(
    calrht, stringr::fixed("CalRHT Notice of Award (August 28, 2026)"),
    "CalRHT Notice of Award (December 1, 2026)")
  expect_error(ca_assert_noa_label_current(calrht = future),
               regexp = "issued a revision nobody has read")

  # and losing the label entirely is also a failure, not a pass: it is the
  # only thing watching CMS's own document
  gone <- stringr::str_replace_all(
    calrht, stringr::fixed("CalRHT Notice of Award (August 28, 2026)"), "")
  expect_error(ca_assert_noa_label_current(calrht = gone),
               regexp = "no longer carries a dated")
})

test_that("the global menu moved a SECOND time, so the mechanism recurs", {
  # 2026-09-12 renamed a nav label (+12 chars on every page); 2026-09-16
  # swapped a Data Resources item (-6 on every page). Same mechanism, second
  # firing -- which is why the nav is not reduced away by reflex.
  old_item <- "Financial Health of California Hospitals"
  new_item <- "Inpatient Hospital Costs by Region"
  expect_equal(nchar(new_item) - nchar(old_item), -6L)

  for (key in CA_PROBE_KEYS) {
    txt <- ca_reduce_html(readBin(ca_path(key), "raw", file.size(ca_path(key))))
    expect_true(grepl(new_item, txt, fixed = TRUE), info = key)
    expect_false(grepl(old_item, txt, fixed = TRUE), info = key)
  }
})
