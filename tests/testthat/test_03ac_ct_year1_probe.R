# Connecticut -- the negative whose award date has ALREADY PASSED.
#
# These run offline against the committed archive. Every assertion in R/03ac is
# a tripwire whose failure is the signal, so the tests are weighted towards
# proving each one actually fires when fed a page that has changed.
#
# THE WEIGHT OF THIS FILE IS ON TWO THINGS.
#   1. Connecticut published its own award date -- 2026-08-17 -- and it went by
#      sixteen days before this archive was taken. That is the sharpest date in
#      the project and the reason Connecticut is watched twice a week.
#   2. All seven RCJ candidates are BUDGET-NARRATIVE LINE ITEMS, and two of
#      them are ONE line item carried twice because Connecticut published the
#      narrative twice. That mechanism -- RCJ pricing document REVISIONS as
#      separate awards -- had not been recorded before.

source(here::here("R", "03ac_ct_year1_probe.R"))

test_that("no Connecticut award file exists, deliberately", {
  expect_false(file.exists(here::here(CT_AWARDS_CSV)))
  expect_silent(ct_assert_no_award_file())
})

test_that("the status table has no amount column, and cannot acquire one", {
  status <- rhtp_ct_year1_status()
  expect_false(any(c("amount", "round_amount", "amount_announced") %in%
                     names(status)))
  # Texas's device: the pool figures are the state's own words, in a text
  # column, so no sum over this table can produce a Connecticut hospital dollar.
  expect_true("stated_pool" %in% names(status))
  expect_type(status$stated_pool, "character")
  expect_equal(nrow(status), 6L)
  expect_true(all(status$state == "CT"))
})


# -- §6.2: CMS's own Notice of Award ------------------------------------------

test_that("Connecticut publishes CMS's own Notice of Award, and it checks out", {
  expect_silent(ct_assert_noa_is_cms_award())
  noa <- ct_pdf_text("noa")
  expect_true(stringr::str_detect(noa, stringr::fixed("93.798")))
  expect_true(stringr::str_detect(noa, stringr::fixed("RHTCMS332073-01-03")))
  expect_true(stringr::str_detect(noa, stringr::fixed("$154,249,105.53")))
  expect_true(stringr::str_detect(noa, stringr::fixed("DEPARTMENT OF SOCIAL SERVICES")))
})

test_that("the NOA's two dates are both present and are not the same claim", {
  noa <- ct_pdf_text("noa")
  # The Federal Award Date is a REVISION date SEVEN MONTHS after the award;
  # the budget period start is the project's 2025-12-29 anchor. A date test
  # keyed on the former would quarantine every genuine Connecticut row.
  expect_true(stringr::str_detect(noa, stringr::fixed("07/23/2026")))
  expect_true(stringr::str_detect(noa, stringr::fixed("12/29/2025")))
  expect_true(stringr::str_detect(noa, stringr::fixed("Revision (Budget)")))
  expect_equal(ct_noa_anchor(), as.Date("2025-12-29"))
  # and the gap is larger than California's three months
  expect_gt(as.integer(as.Date("2026-07-23") - ct_noa_anchor()), 180)
})

test_that("the tripwire fires if the NOA stops calling itself a revision", {
  noa <- ct_pdf_text("noa")
  stripped <- stringr::str_replace(noa, stringr::fixed("Revision (Budget)"),
                                   "New")
  expect_error(ct_assert_noa_is_cms_award(noa = stripped),
               "Revision \\(Budget\\)")
})

test_that("the NOA and the DSS leadership release name the same two people", {
  # Two publishers, one federal and one state, nothing arranged.
  noa  <- ct_pdf_text("noa")
  lead <- ct_html_text("leadership")
  for (who in c("Julie Vigil", "Sinclair")) {
    expect_true(stringr::str_detect(noa,  stringr::fixed(who)))
    expect_true(stringr::str_detect(lead, stringr::fixed(who)))
  }
})


# -- the provenance, and the footer's demotion --------------------------------

test_that("the provenance is programme-scoped, and losing it stops the build", {
  expect_silent(ct_assert_programme_provenance())
  prog <- ct_html_text("programme")
  stripped <- stringr::str_remove(
    prog, stringr::fixed("Connecticut received a $154 million federal grant"))
  expect_error(ct_assert_programme_provenance(programme = stripped),
               "programme-scoped")
})

test_that("the CMS footer is the WEAK form and corroborates the amount only", {
  prog <- ct_html_text("programme")
  # session 27's axis: the SUBJECT is "This project", not the programme.
  expect_true(stringr::str_detect(prog, stringr::fixed(
    "This project is supported by the Centers for Medicare & Medicaid Services")))
  expect_silent(ct_assert_footer_corroborates(strict = FALSE))
  # and it matches the §7.1 anchor to the cent
  expect_equal(round(as.numeric(stringr::str_remove_all(
    CT_STATED$footer_amount, "[$,]"))), ct_allotment_anchor())
})

test_that("the footer is non-strict: it warns rather than throwing", {
  # Kansas's demotion (session 28). A DSS re-post that dropped the boilerplate
  # must not hard-fail Connecticut, AND a state whose only evidence is a "this
  # project" footer must not pass the test Connecticut passes.
  stripped <- "nothing here"
  expect_message(res <- ct_assert_footer_corroborates(programme = stripped),
                 "WEAK form")
  expect_true(is.na(res))
  expect_error(ct_assert_footer_corroborates(strict = TRUE,
                                             programme = stripped),
               "WEAK form")
})


# -- THE DATE THAT HAS PASSED -------------------------------------------------

test_that("Connecticut's own award date precedes the archive date", {
  expect_silent(ct_assert_award_date_passed())
  expect_true(CT_AWARD_DATE < CT_ARCHIVE_DATE)
  expect_equal(as.integer(CT_ARCHIVE_DATE - CT_AWARD_DATE), 16L)
})

test_that("OPM publishes the full NOFO timeline, award milestone included", {
  opm <- ct_html_text("opm")
  for (p in c("NOTICE OF FUNDING OPPORTUNITY #26OHS001",
              "Applications Due", "July 7, 2026, 2:00 PM ET",
              "Grant Awards Announced", "August 17, 2026",
              "Once all negotiation is completed and contracts signed, awards will be announced")) {
    expect_true(stringr::str_detect(opm, stringr::fixed(p)), info = p)
  }
})

test_that("the tripwire fires if the NOFO comes down from OPM's page", {
  opm <- ct_html_text("opm")
  stripped <- stringr::str_remove(opm, stringr::fixed("Grant Awards Announced"))
  expect_error(ct_assert_award_date_passed(opm = stripped),
               "award milestone")
})


# -- THE AWARD TRIPWIRE, driven in both directions ----------------------------

test_that("no award language is on any of the three watched surfaces", {
  expect_silent(ct_assert_no_award_roster())
})

test_that("the tripwire fires on each award phrase, on each surface", {
  docs <- ct_html_text("documents")
  prog <- ct_html_text("programme")
  opm  <- ct_html_text("opm")
  for (phrase in c("have been awarded", "list of awardees",
                   "notice of intent to award")) {
    expect_error(
      ct_assert_no_award_roster(documents = paste(docs, phrase),
                               programme = prog, opm = opm),
      "award language has appeared")
    expect_error(
      ct_assert_no_award_roster(documents = docs,
                               programme = paste(prog, phrase), opm = opm),
      "award language has appeared")
    expect_error(
      ct_assert_no_award_roster(documents = docs, programme = prog,
                               opm = paste(opm, phrase)),
      "award language has appeared")
  }
})

test_that("the state's own pre-award sentence is required to stay", {
  prog <- ct_html_text("programme")
  stripped <- stringr::str_remove(prog, stringr::fixed(
    "Parties interested in being subrecipients of RHTP funding are encouraged to check back"))
  expect_error(
    ct_assert_no_award_roster(documents = ct_html_text("documents"),
                             programme = stripped, opm = ct_html_text("opm")),
    "check back")
})

test_that("the DSS Documents page lists eight documents and no roster", {
  docs <- ct_html_text("documents")
  for (d in c("Governor", "Notice of Award",
              "CT Rural Health Transformation Project Narrative",
              "CT Rural Health Transformation Budget Narrative",
              "CT Rural Health Project Summaries", "RHTP Overview Slides")) {
    expect_true(stringr::str_detect(docs, stringr::fixed(d)), info = d)
  }
  # every one is planning or federal-award material, none is a roster
  expect_false(stringr::str_detect(docs, stringr::regex("awardee|recipient list",
                                                        ignore_case = TRUE)))
})


# -- the eligible class -------------------------------------------------------

test_that("the eligible class is HOSPITALS AMONG OTHERS, on both publishers", {
  expect_silent(ct_assert_eligible_class_not_hospitals_only())
  want <- "Hospitals and health systems, federally qualified health centers (FQHCs)"
  expect_true(stringr::str_detect(ct_html_text("opm"), stringr::fixed(want)))
  expect_true(stringr::str_detect(ct_html_text("nofo"), stringr::fixed(want)))
})

test_that("losing the eligible-class sentence stops the build", {
  # It must stop the build rather than silently allow §10.2's second clause to
  # be read as met -- New Hampshire's FHC lesson, session 29.
  opm <- ct_html_text("opm")
  stripped <- stringr::str_remove(opm, stringr::fixed(
    "Hospitals and health systems, federally qualified health centers (FQHCs)"))
  expect_error(
    ct_assert_eligible_class_not_hospitals_only(opm = stripped,
                                                nofo = ct_html_text("nofo")),
    "hospitals AMONG OTHERS")
})


# -- the budget narrative is a PLAN -------------------------------------------

test_that("the budget narrative says in its own words that it is pre-award", {
  expect_silent(ct_assert_budget_narrative_is_tier2())
  b <- ct_pdf_text("budget")
  expect_true(stringr::str_detect(b, stringr::fixed(
    "Personnel salaries will be updated once awarded")))
  expect_true(stringr::str_detect(b, stringr::fixed(
    "Rural Community Mental Health Services Provider(s) TBD")))
})

test_that("RCJ's awardees are the narrative's agencies, contractors and proposals", {
  b <- ct_pdf_text("budget")
  # a state agency, as a SUBRECIPIENT reporting section
  expect_true(stringr::str_detect(b, stringr::fixed(
    "Required reporting information for subrecipient")))
  # a planned contractor, as a budget COLUMN
  expect_true(stringr::str_detect(b, stringr::fixed(
    "Contractor 1 Carelon Behavioral Health, Inc.")))
  # a proposal name, read by RCJ as an awardee (§6.1)
  expect_true(stringr::str_detect(b, stringr::fixed(
    "Proposal: W03-Area Health Education Center (AHEC) Expansion")))
})


# -- the controls -------------------------------------------------------------

test_that("the POSITIVE control holds: OHS names organisations in decisions", {
  expect_silent(ct_assert_channel_control())
  ohs <- ct_html_text("ohs_press")
  expect_true(stringr::str_detect(ohs, stringr::fixed("Waterbury Hospital")))
})

test_that("losing the positive control stops the build", {
  ohs <- ct_html_text("ohs_press")
  # str_remove_ALL: the headline appears twice on the index, and removing only
  # the first leaves the control intact -- which is how this test first passed
  # for the wrong reason.
  stripped <- stringr::str_remove_all(ohs, stringr::fixed("Waterbury Hospital"))
  expect_error(ct_assert_channel_control(ohs_press = stripped),
               "names organisations")
})

test_that("the NEGATIVE control holds: DSS's only RHTP release is governance", {
  expect_silent(ct_assert_leadership_is_not_award())
  lead <- ct_html_text("leadership")
  # it names PEOPLE, and no organisation receives anything
  expect_true(stringr::str_detect(lead, stringr::fixed(
    "announced the formation of the Rural Health Transformation Program leadership team")))
  expect_false(stringr::str_detect(lead, stringr::regex("have been awarded",
                                                        ignore_case = TRUE)))
})

test_that("the negative control fires if DSS's release acquires award language", {
  lead <- ct_html_text("leadership")
  expect_error(
    ct_assert_leadership_is_not_award(
      leadership = paste(lead, "The following have been awarded")),
    "acquired award language")
})

test_that("CTsource is recorded as UNREADABLE, not as a negative", {
  expect_silent(ct_assert_ctsource_unreadable())
  status <- rhtp_ct_year1_status()
  row <- status[stringr::str_detect(status$channel, "CTsource"), ]
  expect_equal(nrow(row), 1L)
  # §0.4: a statement about OUR ACCESS, never about Connecticut
  expect_equal(row$publishes_roster, "UNKNOWN")
  expect_equal(row$stage, "UNREADABLE")
})

test_that("the CTsource row fires if the landing page starts naming RHTP", {
  cts <- ct_html_text("ctsource")
  expect_error(
    ct_assert_ctsource_unreadable(
      ctsource = paste(cts, "Rural Health Transformation")),
    "mentions RHTP")
})


# -- the RCJ disposition ------------------------------------------------------

test_that("all seven candidates come from the budget narrative", {
  cands <- ct_rcj_candidates()
  expect_equal(nrow(cands), 7L)
  dispo <- rhtp_ct_rcj_disposition(cands)
  expect_equal(sum(dispo$rows), 7L)
  expect_true(all(dispo$disposition == "RHTP_BUT_NOT_A_SUBAWARD"))
  expect_true(all(dispo$state == "CT"))
})

test_that("the disposition's arithmetic closes against the survey", {
  cands <- ct_rcj_candidates()
  dispo <- rhtp_ct_rcj_disposition(cands)
  survey <- readr::read_csv(
    here::here("data", "reference", "rcj_state_survey.csv"),
    show_col_types = FALSE, progress = FALSE)
  expect_equal(sum(dispo$rcj_amount_sum),
               survey$rcj_federal_amount_sum[survey$state == "CT"])
  expect_equal(sum(dispo$rcj_amount_sum), 49854129)
})

test_that("RCJ prices ONE line item twice because Connecticut revised it", {
  # The mechanism this session recorded: document REVISIONS carried as separate
  # awards. New Hampshire's CDFA was three spellings at three prices; this is
  # the cleaner case, because the underlying document is provably one line.
  cands <- ct_rcj_candidates()
  carelon <- cands[stringr::str_detect(cands$awardee_name_clean, "Carelon"), ]
  expect_equal(nrow(carelon), 2L)
  expect_equal(dplyr::n_distinct(carelon$awardee_name_clean), 1L)
  expect_true(all(carelon$amount_announced == 3800000))
  # two DIFFERENT source documents, i.e. two revisions of one narrative
  expect_equal(dplyr::n_distinct(carelon$source_doc_title), 2L)

  # and the same mechanism gives DMHAS two DIFFERENT amounts
  dmhas <- cands[stringr::str_detect(cands$awardee_name_clean, "DMHAS"), ]
  expect_equal(nrow(dmhas), 2L)
  expect_equal(sort(dmhas$amount_announced), c(5600000, 5749236))
})

test_that("the disposition REFUSES a candidate it does not cover", {
  cands <- ct_rcj_candidates()
  rogue <- cands[1, ]
  rogue$source_doc_title <- "CT - 2026 - Something Nobody Has Read"
  expect_error(rhtp_ct_rcj_disposition(dplyr::bind_rows(cands, rogue)),
               "NOT from the budget narrative")
})

test_that("the disposition refuses an awardee outside its three groups", {
  cands <- ct_rcj_candidates()
  rogue <- cands[1, ]
  rogue$awardee_name_clean <- "Some Rural Hospital"
  expect_error(rhtp_ct_rcj_disposition(dplyr::bind_rows(cands, rogue)),
               "matches none of the three groups")
})

test_that("NOT ONE Connecticut candidate is a named hospital", {
  # Unlike California (11 of 11) and New Mexico (2 of 7), Connecticut's
  # candidate set contains no hospital at all -- so its $0 is not at risk from
  # a name-keyed read.
  cands <- ct_rcj_candidates()
  expect_false(any(stringr::str_detect(
    cands$awardee_name_clean, stringr::regex("hospital", ignore_case = TRUE))))
})


# -- the reduction, and the fifth digest mechanism ----------------------------

test_that("the reduction discards attributes, so the ?v= stamp cannot reach it", {
  # portal.ct.gov stamps a per-NODE '?v=<timestamp>' on seven static asset
  # URLs. It lives in href/src ATTRIBUTES, and the reduction replaces every tag
  # with a space -- so two responses differing only in that stamp reduce
  # identically. Synthesised here rather than fetched, so the test is offline.
  a <- charToRaw('<html><link href="/x.css?v=20260902015148"><body>Grant Awards Announced</body></html>')
  b <- charToRaw('<html><link href="/x.css?v=20260902015120"><body>Grant Awards Announced</body></html>')
  expect_false(identical(digest::digest(a, algo = "sha256"),
                         digest::digest(b, algo = "sha256")))
  expect_identical(ct_content_digest(a), ct_content_digest(b))
})

test_that("the reduction strips script bodies and zero-width characters", {
  raw <- charToRaw('<html><script>var nonce="abc123";</script><p>Grant​ Awards</p></html>')
  expect_equal(ct_reduce_html(raw), "Grant Awards")
})

test_that("the probe and the assertions read the SAME reduction", {
  # Missouri's rule (session 29): a probe that reduces differently from the
  # tripwires it feeds drifts away from them silently.
  p <- ct_path("programme")
  body <- readBin(p, "raw", file.size(p))
  expect_identical(ct_html_text("programme"), ct_reduce_html(body))
})


# -- the archive verifies ------------------------------------------------------

test_that("every archived file re-hashes to its manifest digest", {
  man <- readLines(file.path(CT_EVIDENCE_DIR, "MANIFEST.txt"))
  i <- which(man == "file  bytes  sha256")
  expect_length(i, 1L)
  rows <- man[(i + 1L):length(man)]
  expect_gt(length(rows), 0L)
  for (r in rows) {
    parts <- strsplit(r, "  ", fixed = TRUE)[[1]]
    f <- file.path(CT_EVIDENCE_DIR, parts[1])
    expect_true(file.exists(f), info = parts[1])
    expect_equal(digest::digest(file = f, algo = "sha256"),
                 parts[3], info = parts[1])
  }
})

test_that("the manifest does not list itself", {
  man <- readLines(file.path(CT_EVIDENCE_DIR, "MANIFEST.txt"))
  expect_false(any(stringr::str_detect(man, "^MANIFEST\\.txt")))
})

test_that("every source key resolves to a file that exists", {
  for (k in CT_SOURCES$key) expect_true(file.exists(ct_path(k)), info = k)
})

test_that("every probe key is a real source key", {
  expect_true(all(CT_PROBE_KEYS %in% CT_SOURCES$key))
})


# -- the whole assertion set ---------------------------------------------------

test_that("rhtp_ct_assert() passes end to end, offline", {
  expect_silent(rhtp_ct_assert())
})
