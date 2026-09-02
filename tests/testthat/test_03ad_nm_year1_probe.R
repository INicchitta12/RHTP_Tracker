# New Mexico -- the negative whose candidate set carries THREE recorded
# false-positive shapes at once.
#
# These run offline against the committed archive. Every assertion in R/03ad is
# a tripwire whose failure is the signal, so the tests are weighted towards
# proving each one actually fires.
#
# THE WEIGHT OF THIS FILE IS ON THE DISPOSITION, because New Mexico is the
# first candidate set where three known defects stack:
#   1. the wrong PROGRAMME  -- a state fund (Texas's, California's)
#   2. the wrong SECTION    -- a future opportunity's title carried on a past
#                              award roster's names (Nebraska's)
#   3. the $1 PLACEHOLDER   -- which is what HIDES the other two, because a row
#                              priced at $1 reads as missing data rather than
#                              as the wrong programme (Missouri's, Maine's)

source(here::here("R", "03ad_nm_year1_probe.R"))

test_that("no New Mexico award file exists, deliberately", {
  expect_false(file.exists(here::here(NM_AWARDS_CSV)))
  expect_silent(nm_assert_no_award_file())
})

test_that("the status table has no amount column, and cannot acquire one", {
  status <- rhtp_nm_year1_status()
  expect_false(any(c("amount", "round_amount", "amount_announced") %in%
                     names(status)))
  expect_true("stated_pool" %in% names(status))
  expect_type(status$stated_pool, "character")
  expect_equal(nrow(status), 8L)
  expect_true(all(status$state == "NM"))
})

test_that("six RHT procurements, and not one publishes a roster", {
  status <- rhtp_nm_year1_status()
  rht <- status[status$stage %in% c("CLOSED_UNAWARDED", "OPEN",
                                    "NOT_YET_SOLICITED"), ]
  expect_equal(nrow(rht), 6L)
  expect_true(all(rht$publishes_roster == "No"))
})


# -- the provenance, and the footer's demotion --------------------------------

test_that("the provenance is programme-scoped, from two publishers", {
  expect_silent(nm_assert_programme_provenance())
  prog <- nm_html_text("programme")
  expect_true(stringr::str_detect(prog, stringr::fixed(
    "Authorized under H.R. 1, Public Law 119-21")))
  # a SECOND, independent programme-scoped sentence on a different page
  f47 <- nm_html_text("fund47")
  expect_true(stringr::str_detect(f47, stringr::fixed(
    "is part of New Mexico's Rural Health Transformation Program")))
})

test_that("losing either provenance sentence stops the build", {
  prog <- nm_html_text("programme"); f47 <- nm_html_text("fund47")
  expect_error(
    nm_assert_programme_provenance(
      programme = stringr::str_remove_all(prog, stringr::fixed(
        "Authorized under H.R. 1, Public Law 119-21")), fund47 = f47),
    "statutory sentence")
  expect_error(
    nm_assert_programme_provenance(
      programme = prog,
      fund47 = stringr::str_remove_all(f47, stringr::fixed(
        "is part of New Mexico's Rural Health Transformation Program"))),
    "part of RHTP")
})

test_that("the CMS footer is the WEAK form and corroborates the amount only", {
  prog <- nm_html_text("programme")
  expect_true(stringr::str_detect(prog, stringr::fixed(
    "This project is supported by the Centers for Medicare & Medicaid Services")))
  expect_silent(nm_assert_footer_corroborates(strict = FALSE))
  expect_equal(round(as.numeric(stringr::str_remove_all(
    NM_STATED$footer_amount, "[$,]"))), nm_allotment_anchor())
})

test_that("the footer is non-strict: it warns rather than throwing", {
  expect_message(res <- nm_assert_footer_corroborates(programme = "nothing"),
                 "WEAK form")
  expect_true(is.na(res))
  expect_error(nm_assert_footer_corroborates(strict = TRUE,
                                             programme = "nothing"),
               "WEAK form")
})


# -- THE AWARD TRIPWIRE -------------------------------------------------------

test_that("no award language is on HCA's RHT page", {
  expect_silent(nm_assert_no_award_roster())
})

test_that("the tripwire fires on each award phrase", {
  prog <- nm_html_text("programme")
  for (phrase in c("have been awarded", "list of awardees",
                   "selected for award", "award recipients")) {
    expect_error(nm_assert_no_award_roster(programme = paste(prog, phrase)),
                 "award language has appeared", info = phrase)
  }
})

test_that("all six procurements and their stage words must stay on the page", {
  prog <- nm_html_text("programme")
  for (m in NM_PENDING_MARKERS) {
    expect_error(
      nm_assert_no_award_roster(
        programme = stringr::str_remove_all(prog, stringr::fixed(m))),
      "no longer carries", info = m)
  }
})

test_that("every published RHTP deadline is on its own source", {
  expect_silent(nm_assert_pending_not_awarded())
  expect_true(stringr::str_detect(nm_html_text("programme"),
                                  stringr::fixed(NM_STATED$rinm_due)))
  expect_true(stringr::str_detect(nm_html_text("horizons"),
                                  stringr::fixed(NM_STATED$horizons_due)))
  expect_true(stringr::str_detect(nm_html_text("fund47"),
                                  stringr::fixed(NM_STATED$innovation_due)))
})

test_that("Healthy Horizons is a HUB model, which is why it is a §0.3 question", {
  h <- nm_html_text("horizons")
  # Missouri's ToRCH shape: hubs coordinate and re-direct, they do not receive
  # for themselves, and their downstream class is providers AMONG OTHERS.
  expect_true(stringr::str_detect(h, stringr::fixed(
    "will select six organizations to manage hub regions")))
  expect_true(stringr::str_detect(h, stringr::fixed(
    "at least 90% of its award to support local projects")))
  expect_error(
    nm_assert_pending_not_awarded(
      programme = nm_html_text("programme"),
      horizons = stringr::str_remove_all(h, stringr::fixed(
        "will select six organizations to manage hub regions")),
      fund47 = nm_html_text("fund47")),
    "hub model")
})


# -- §0.1: the RHCDF is NOT RHTP ----------------------------------------------

test_that("three independent publishers say the RHCDF is state money", {
  expect_silent(nm_assert_rhcdf_is_not_rhtp())
  a <- nm_html_text("award50")
  # the Governor names the funding source in one sentence
  expect_true(stringr::str_detect(a, stringr::fixed(
    "will receive a combined $50 million in state funding")))
  # and dates the appropriation BEFORE the CMS Notice of Award
  expect_true(stringr::str_detect(a, stringr::fixed(
    "additional $50 million during the October 2025 special session")))
  expect_true(as.Date("2025-10-31") < nm_noa_anchor())
})

test_that("HCA's own RHCDF deck never mentions the federal programme", {
  d <- nm_pdf_text("rhcdf_deck")
  # THE STRONGEST FORM OF THE NEGATIVE: this is the document RCJ sourced the
  # seven rows from, and it names neither the programme nor its funder.
  for (p in c("RHTP", "Rural Health Transformation", "CMS", "federal")) {
    expect_false(stringr::str_detect(d, stringr::fixed(p)), info = p)
  }
  expect_true(stringr::str_detect(d, stringr::regex("state\\s*investment")))
})

test_that("the negative fires if the deck starts naming RHTP", {
  d <- nm_pdf_text("rhcdf_deck")
  expect_error(
    nm_assert_rhcdf_is_not_rhtp(award50 = nm_html_text("award50"),
                                deck = paste(d, "RHTP"),
                                rhcdf = nm_html_text("rhcdf")),
    "now mentions")
})

test_that("the RHCDF page names RHTP only in its navigation, and carries no footer", {
  r <- nm_html_text("rhcdf")
  # all three occurrences are the sibling menu item; a FOURTH would be prose
  expect_equal(stringr::str_count(r, stringr::fixed(
    "Rural Health Transformation")), 3L)
  expect_false(stringr::str_detect(r, stringr::fixed(
    "financial assistance award totaling")))
  # its one mention of CMS is a Medicaid 1115 waiver approved 2024-07-25
  expect_true(stringr::str_detect(r, stringr::fixed(
    "1115 Waiver approved by the Centers for Medicare & Medicaid Services on July 25, 2024")))
})

test_that("the negative fires if the RHCDF page gains a CMS footer", {
  r <- nm_html_text("rhcdf")
  expect_error(
    nm_assert_rhcdf_is_not_rhtp(
      award50 = nm_html_text("award50"), deck = nm_pdf_text("rhcdf_deck"),
      rhcdf = paste(r, "financial assistance award totaling")),
    "CMS financial-assistance footer")
})

test_that("the negative fires if RHTP appears in the RHCDF page's prose", {
  r <- nm_html_text("rhcdf")
  expect_error(
    nm_assert_rhcdf_is_not_rhtp(
      award50 = nm_html_text("award50"), deck = nm_pdf_text("rhcdf_deck"),
      rhcdf = paste(r, "Rural Health Transformation")),
    "rather than 3")
})


# -- the controls -------------------------------------------------------------

test_that("the POSITIVE control holds: HCA publishes named rosters", {
  expect_silent(nm_assert_roster_control())
  r <- nm_html_text("rhcdf")
  expect_true(stringr::str_detect(r, stringr::fixed(
    "FY26-27 - Total Funding Recipients: 30")))
})

test_that("the positive control and the §0.1 trap are on ONE news index", {
  # The transferable warning: a state award announcement and an RHTP
  # solicitation, four items apart, reading almost identically.
  n <- nm_html_text("news")
  expect_true(stringr::str_detect(n, stringr::fixed(
    "New Mexico awards $50 million to 41 rural healthcare organizations")))
  expect_true(stringr::str_detect(n, stringr::fixed(
    "NM opens $47 million fund for rural health projects")))
})

test_that("losing either headline stops the build", {
  r <- nm_html_text("rhcdf"); n <- nm_html_text("news")
  for (h in c("New Mexico awards $50 million to 41 rural healthcare organizations",
              "NM opens $47 million fund for rural health projects")) {
    expect_error(
      nm_assert_roster_control(
        rhcdf = r, news = stringr::str_remove_all(n, stringr::fixed(h))),
      "no longer carries both", info = h)
  }
})

test_that("the $50M state roster names hospitals, which is the whole danger", {
  a <- nm_html_text("award50")
  for (h in c("Socorro General Hospital", "Sierra Vista Hospital and Clinics",
              "Holy Cross Medical Center", "Cibola General Hospital")) {
    expect_true(stringr::str_detect(a, stringr::fixed(h)), info = h)
  }
  # California's SRHRP shape: real, executed, named state awards to rural
  # hospitals, from the SAME agency that administers RHTP.
  expect_true(stringr::str_detect(a, stringr::fixed(
    "Rural Health Care Delivery Fund")))
})


# -- the RCJ disposition ------------------------------------------------------

test_that("all seven candidates are RHCDF recipients", {
  cands <- nm_rcj_candidates()
  expect_equal(nrow(cands), 7L)
  dispo <- rhtp_nm_rcj_disposition(cands)
  expect_equal(nrow(dispo), 1L)
  expect_equal(dispo$rows, 7L)
  expect_equal(dispo$disposition, "NOT_RHTP_STATE_PROGRAM")
  expect_equal(dispo$state, "NM")
})

test_that("every candidate is priced at $1 -- Missouri's placeholder", {
  expect_silent(nm_assert_placeholder_amounts())
  cands <- nm_rcj_candidates()
  expect_true(all(cands$amount_announced == 1))
  # so New Mexico's whole survey figure is $7, which is the tell
  dispo <- rhtp_nm_rcj_disposition(cands)
  expect_equal(dispo$rcj_amount_sum, 7)
  survey <- readr::read_csv(
    here::here("data", "reference", "rcj_state_survey.csv"),
    show_col_types = FALSE, progress = FALSE)
  expect_equal(dispo$rcj_amount_sum,
               survey$rcj_federal_amount_sum[survey$state == "NM"])
})

test_that("the placeholder assertion fires if RCJ repairs the amounts", {
  cands <- nm_rcj_candidates()
  cands$amount_announced[1] <- 250000
  expect_error(nm_assert_placeholder_amounts(cands = cands),
               "priced at \\$1")
})

test_that("TWO of the seven are named hospitals, and that is stated", {
  cands <- nm_rcj_candidates()
  dispo <- rhtp_nm_rcj_disposition(cands)
  expect_equal(dispo$named_hospital_rows, 2L)
  hosp <- cands$awardee_name_clean[stringr::str_detect(
    cands$awardee_name_clean, stringr::regex("hospital", ignore_case = TRUE))]
  expect_setequal(stringr::str_squish(hosp),
                  c("Alta Vista Regional Hospital", "Cibola General Hospital"))
})

test_that("every candidate name is on the RHCDF roster, and Gallup is not", {
  # The partial capture is its own tell -- Texas's 32-of-33 and Kansas's
  # Greeley County a third time.
  expect_silent(nm_assert_candidates_are_rhcdf_recipients())
  expect_true(stringr::str_detect(nm_html_text("rhcdf"),
                                  stringr::fixed("Gallup Community Health")))
  cands <- nm_rcj_candidates()
  expect_false(any(stringr::str_detect(cands$awardee_name_clean, "Gallup")))
})

test_that("the roster check fires if a candidate is not on the RHCDF page", {
  cands <- nm_rcj_candidates()
  rogue <- cands[1, ]; rogue$awardee_name_clean <- "Nowhere Regional Medical"
  expect_error(
    nm_assert_candidates_are_rhcdf_recipients(
      rhcdf = nm_html_text("rhcdf"),
      cands = dplyr::bind_rows(cands, rogue)),
    "NOT on the")
})

test_that("the disposition REFUSES a candidate it does not cover", {
  cands <- nm_rcj_candidates()
  rogue <- cands[1, ]
  rogue$source_doc_title <- "NM - 2026 - Something Nobody Has Read"
  expect_error(rhtp_nm_rcj_disposition(dplyr::bind_rows(cands, rogue)),
               "NOT from the RHCDF")
})

test_that("the title is a FUTURE opportunity's and the names are a PAST roster's", {
  # Nebraska's defect (session 23): title from one section, rows from another.
  cands <- nm_rcj_candidates()
  expect_true(all(stringr::str_detect(
    cands$source_doc_title, stringr::fixed("Funding Opportunity for FY27-29"))))
  # while the names are the FY26-27 recipients printed further down the page
  r <- nm_html_text("rhcdf")
  expect_true(stringr::str_detect(r, stringr::fixed(
    "FY26-27 - Total Funding Recipients: 30")))
})


# -- the reduction, and the sixth digest mechanism ----------------------------

test_that("the reduction strips script bodies, absorbing the Complianz re-roll", {
  # hca.nm.gov's Complianz plugin writes a randomly-drawn post URL into a JSON
  # config inside a script body, at VARIABLE length -- so a byte-count check
  # fails here where it would pass California's constant-length antispambot()
  # re-roll. Synthesised so the test is offline.
  a <- charToRaw('<html><script>var c={"url":"/snapchanges/"};</script><p>Currently under evaluation</p></html>')
  b <- charToRaw('<html><script>var c={"url":"/2021/09/10/a-much-longer-post-slug-here/"};</script><p>Currently under evaluation</p></html>')
  expect_false(length(a) == length(b))
  expect_false(identical(digest::digest(a, algo = "sha256"),
                         digest::digest(b, algo = "sha256")))
  expect_identical(nm_content_digest(a), nm_content_digest(b))
})

test_that("the probe and the assertions read the SAME reduction", {
  p <- nm_path("programme")
  body <- readBin(p, "raw", file.size(p))
  expect_identical(nm_html_text("programme"), nm_reduce_html(body))
})


# -- the archive verifies ------------------------------------------------------

test_that("every archived file re-hashes to its manifest digest", {
  man <- readLines(file.path(NM_EVIDENCE_DIR, "MANIFEST.txt"))
  i <- which(man == "file  bytes  sha256")
  expect_length(i, 1L)
  rows <- man[(i + 1L):length(man)]
  expect_gt(length(rows), 0L)
  for (r in rows) {
    parts <- strsplit(r, "  ", fixed = TRUE)[[1]]
    f <- file.path(NM_EVIDENCE_DIR, parts[1])
    expect_true(file.exists(f), info = parts[1])
    expect_equal(digest::digest(file = f, algo = "sha256"),
                 parts[3], info = parts[1])
  }
})

test_that("the manifest does not list itself", {
  man <- readLines(file.path(NM_EVIDENCE_DIR, "MANIFEST.txt"))
  expect_false(any(stringr::str_detect(man, "^MANIFEST\\.txt")))
})

test_that("every source key resolves to a file that exists", {
  for (k in NM_SOURCES$key) expect_true(file.exists(nm_path(k)), info = k)
})

test_that("every probe key is a real source key", {
  expect_true(all(NM_PROBE_KEYS %in% NM_SOURCES$key))
})


# -- the whole assertion set ---------------------------------------------------

test_that("rhtp_nm_assert() passes end to end, offline", {
  expect_silent(rhtp_nm_assert())
})
