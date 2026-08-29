# test_03o_ks_year1_awardees.R -----------------------------------------------
# Kansas Year 1. Reads committed archives only -- no network, no quota.
#
# WHAT THIS FILE IS DEFENDING.
#
#   1. THE TEXAS CHECK. Kansas's awards are RHTP because KDHE's own award
#      document says they are 100 percent CMS/HHS funded. If that sentence ever
#      leaves the document, this file's whole claim goes with it, and the
#      failure must be loud. Texas is the reason: 53 real, executed,
#      recipient-level hospital awards that were state appropriation money.
#
#   2. THE POSITIVE CONTROL. "The other four Kansas programmes have published
#      no roster" is only a finding if KDHE demonstrably publishes rosters in a
#      recognisable form. Two links off the programme page are that control,
#      and they are asserted present -- and a THIRD award link is asserted
#      absent, because that would mean this file has gone stale.
#
#   3. THE PDF PARSE. Kansas is the first state in this project whose awards
#      are only in PDFs, parsed by R/utils_pdf_text.R through each font's own
#      ToUnicode CMap. Two ways that goes wrong quietly: a wrapped recipient
#      name published as "Citizens Foundat ion", and a pool split that puts an
#      award in the wrong programme.
#
#   4. THE FLOOR. Kansas's hospital figure is smaller than its uncertainty, and
#      a future change to the shared classifier could move dollars across that
#      line without anything noticing.

library(testthat)

source(here::here("R", "03o_ks_year1_awardees.R"))

ks_awards <- rhtp_ks_year1_awardees()
ks_rec    <- rhtp_ks_reconcile(ks_awards)
ks_links  <- ks_program_page_text()


# -- the Texas check ---------------------------------------------------------

test_that("KDHE's own award document says CMS funds these awards", {
  stated <- ks_assert_rhtp_funded()
  expect_equal(stated, 221890007.82)

  one <- ks_join_lines(ks_document_text("reh_cap_rpgp"))
  expect_true(grepl("100 percent funded by CMS/HHS", one, fixed = TRUE))
  expect_true(grepl("Centers for Medicare & Medicaid Services", one, fixed = TRUE))
})

test_that("the solicitations postdate Kansas's CMS Notice of Award", {
  # Session 19's cheapest version of the funding-source test. KDHE's RPGP /
  # REH CAP applicant webinar is 6 March 2026; the NOA is 2025-12-29. Texas's
  # HHS0015180 went the other way -- released 2025-03-24, closed 2025-04-24,
  # nine months BEFORE its state had the money.
  noa <- rhtp_read_noa_dates()
  expect_equal(as.character(noa$noa_date[noa$state == "KS"]), "2025-12-29")

  expect_true(any(grepl("RPGP-REH-CAP-Webinar-March-6-2026", ks_links$href)))
})

test_that("Kansas is not caught by the extended §6.2 provenance filter", {
  # The sweep is the other half of this session's work; Kansas is the state it
  # was pointed at next. If a Kansas candidate ever trips the state-programme
  # or predates-NOA test, this extraction needs re-reading before it is used.
  sweep <- readr::read_csv(
    here::here("data/reference/provenance_sweep_by_state.csv"),
    show_col_types = FALSE, progress = FALSE)
  expect_equal(sweep$caught_total[sweep$state == "KS"], 0)
})


# -- the positive control ----------------------------------------------------

test_that("both award documents are still linked from the programme page", {
  expect_true(ks_assert_award_index(ks_links))
  for (marker in KS_AWARD_LINK_MARKERS) {
    expect_true(any(grepl(marker, ks_links$text)))
  }
})

test_that("the control fails loudly if an award link disappears", {
  gutted <- ks_links %>% dplyr::filter(!grepl("REH CAP", text))
  expect_error(ks_assert_award_index(gutted), "POSITIVE CONTROL")
})

test_that("the control fails if Kansas publishes a THIRD award document", {
  extra <- dplyr::bind_rows(
    ks_links,
    tibble::tibble(href = "/DocumentCenter/View/99999",
                   text = "Emerging Technology Award Winners (PDF)"))
  expect_error(ks_assert_award_index(extra), "does not carry")
})

test_that("the four unawarded programmes are on the page, without a roster", {
  # Named on the programme page -- so their absence from the award set is
  # "not awarded yet", not "not looked for".
  page <- paste(ks_links$text, collapse = " | ")
  for (prog in c("Emerging Technology", "Interfacility Transport")) {
    expect_true(grepl(prog, page), info = prog)
  }
  award_shaped <- ks_links %>%
    dplyr::filter(grepl(KS_AWARD_LINK_SHAPE, text))
  expect_equal(nrow(award_shaped), 2L)
})


# -- the parse ---------------------------------------------------------------

test_that("46 award actions across three pools, matching KDHE's documents", {
  expect_equal(nrow(ks_awards), 46L)
  by_pool <- ks_rec$by_pool
  expect_equal(by_pool$n[by_pool$award_pool == "REH_CAP"], 17L)
  expect_equal(by_pool$n[by_pool$award_pool == "RPGP"], 22L)
  expect_equal(by_pool$n[by_pool$award_pool == "CHW_AFIM"], 7L)
  expect_equal(by_pool$total[by_pool$award_pool == "REH_CAP"], 29097937)
  expect_equal(by_pool$total[by_pool$award_pool == "RPGP"], 49915410)
  expect_equal(by_pool$total[by_pool$award_pool == "CHW_AFIM"], 1007152)
  expect_equal(ks_rec$awards_total, 80020499)
})

test_that("the CHW+AFIM pool is the partial list, and it is the small one", {
  chw <- ks_awards %>% dplyr::filter(award_pool == "CHW_AFIM")
  expect_equal(sum(chw$amount), 1007152)
  # Four of the seven are $150,000, and two are hospital districts.
  expect_equal(sum(chw$amount == 150000), 4L)
  expect_true(any(grepl("Hospital District No\\. 6 of Harper County",
                        chw$awardee)))
  expect_true(any(grepl("Hospital District No\\. 1 of Dickinson County",
                        chw$awardee)))
  # It is 1.3% of what Kansas has published.
  expect_lt(sum(chw$amount) / ks_rec$awards_total, 0.02)
})

test_that("a wrapped recipient name is repaired, and only in a name-safe way", {
  # "Citizens Foundat" / "ion: $146,476" is how KDHE's PDF breaks it. Joined
  # with a space it would be published as "Citizens Foundat ion".
  expect_true("Citizens Foundation" %in% ks_awards$awardee)
  expect_false(any(grepl("Foundat ion", ks_awards$awardee)))

  expect_equal(ks_join_lines(c("Citizens Foundat", "ion: $146,476")),
               "Citizens Foundation: $146,476")
  # A capital after a letter is a new word, not a wrap.
  expect_equal(ks_join_lines(c("Memorial Health", "System: $150,000")),
               "Memorial Health System: $150,000")
  # A comma ends the line: still a space.
  expect_equal(ks_join_lines(c("Hutchinson Regional Medical Center,",
                               "Inc: $150,000")),
               "Hutchinson Regional Medical Center, Inc: $150,000")
})

test_that("Greeley County holds TWO awards, one in each pool", {
  # This is the row RCJ dropped: an aggregator that de-duplicates on the
  # recipient loses the second award and nothing about its output looks wrong.
  g <- ks_awards %>% dplyr::filter(grepl("Greeley County Health", awardee))
  expect_equal(nrow(g), 2L)
  expect_setequal(g$award_pool, c("REH_CAP", "RPGP"))
  expect_setequal(g$amount, c(458286, 1541906))
})

test_that("the pool split is positional and refuses if the headings move", {
  # Both pools are in ONE document, so the split is by position against the
  # RPGP heading -- it cannot key on the recipient, because Greeley is in both.
  expect_error(
    ks_parse_reh_cap_rpgp(c("Awardees are: • Someone: $1")),
    "both pool headings"
  )
})

test_that("the description passed to the classifier is KDHE's, not ours", {
  # An earlier draft passed the POOL NAME as the description, and because the
  # REH CAP pool is called "Rural Emergency Hospital Conversion ...", every
  # unrecognised recipient in it came out IN_KIND_BENEFIT -- the in-kind rule
  # firing on a string this file had written itself (§0.3a).
  reh <- ks_parse_reh_cap_rpgp() %>% dplyr::filter(award_pool == "REH_CAP")
  expect_true(all(nzchar(reh$description)))
  expect_false(any(grepl("Transformative Capital Investment Grant Program",
                         reh$description)))
  expect_true(any(grepl("critical access hospital", reh$description)))

  # And the wrap repair runs on descriptions only.
  expect_equal(ks_repair_wrap("o dual - purpose OR endosuites"),
               "dual-purpose OR endosuites")
})


# -- the two publishers ------------------------------------------------------

test_that("KDHE and CMS disagree about Kansas's award, and it is reported", {
  expect_equal(ks_rec$cms_award_stated, 221890007.82)
  expect_equal(ks_rec$cms_allotment, 221898008)
  expect_equal(round(ks_rec$publisher_gap, 2), 8000.18)
})


# -- the floor ---------------------------------------------------------------

test_that("the hospital figure is a floor, and the uncertainty is larger", {
  part <- rhtp_hospital_dollar_partition(ks_awards)
  expect_equal(part$bucket, "NAMED_HOSPITAL")
  expect_equal(part$dollars, 35721277)
  expect_equal(part$rows, 21L)

  inferred <- ks_awards %>%
    dplyr::filter(determination_confidence == "LOW",
                  flag_reason == "RECIPIENT_TYPE_INFERRED")
  expect_equal(nrow(inferred), 22L)
  expect_equal(sum(inferred$amount), 39249763)
  expect_gt(sum(inferred$amount), part$dollars)
})

test_that("nothing was promoted on this pipeline's own knowledge", {
  # The four that read most obviously as hospitals are still coded to §8's
  # standing answer. If a future session promotes them it must do so with a
  # source, and this test is where it will have to say so.
  for (nm in c("Stormont Vail Health", "AdventHealth Ottawa",
               "Labette Health", "South Central Kansas Health")) {
    row <- ks_awards %>% dplyr::filter(awardee == nm)
    expect_equal(nrow(row), 1L, info = nm)
    expect_equal(row$recipient_type, "NONPROFIT_CBO", info = nm)
    expect_equal(row$determination_confidence, "LOW", info = nm)
  }
})

test_that("the open question is in the review queue with its dollars", {
  queue <- readr::read_csv(
    here::here("data/reference/classification_review_queue.csv"),
    show_col_types = FALSE, progress = FALSE)
  row <- queue %>% dplyr::filter(question_id == KS_FORM_NOT_STATED_QUESTION)
  expect_equal(nrow(row), 1L)
  expect_equal(row$state, "KS")
  expect_equal(row$queue_status, "OPEN")
  expect_true(grepl("39,249,763", row$dollar_effect))
})


# -- RCJ, as a signal and not a source ---------------------------------------

test_that("RCJ holds 45 of the 46, and every amount it holds is right", {
  gap <- rhtp_ks_rcj_gap(ks_awards)
  skip_if(is.null(gap), "no committed record table")

  expect_equal(gap$state_rows, 46L)
  expect_equal(gap$rcj_rows, 45L)
  expect_true(gap$amounts_agree)
  expect_equal(nrow(gap$missing), 1L)
  expect_true(grepl("Greeley County Health", gap$missing$awardee))
  expect_equal(gap$missing$amount, 458286)
})


# -- provenance --------------------------------------------------------------

test_that("the archive verifies and carries no credential", {
  for (dir in c(KS_EVIDENCE_DIR, KS_NARRATIVE_DIR)) {
    man <- file.path(dir, "MANIFEST.txt")
    expect_true(file.exists(man))
    lines <- grep("^[0-9a-f]{64}  ", readLines(man), value = TRUE)
    expect_gt(length(lines), 0)
    for (ln in lines) {
      f <- file.path(dir, sub("^[0-9a-f]{64}  ([^ ]+).*$", "\\1", ln))
      expect_true(file.exists(f), info = f)
      expect_equal(digest::digest(file = f, algo = "sha256"),
                   sub("^([0-9a-f]{64}).*$", "\\1", ln))
    }
    # Session 15: a manifest cannot record its own digest.
    expect_false(any(grepl("MANIFEST.txt", lines, fixed = TRUE)))
  }
})

test_that("the Google Maps key KDHE embeds is not in the archive", {
  # The guard caught it on the first fetch; a hand check would have had to
  # know that `id=\"GoogleMapsKey\"` was a thing to look for.
  html <- paste(readLines(ks_archive_path("program_page"), warn = FALSE),
                collapse = "\n")
  expect_false(grepl("AIza[A-Za-z0-9_-]{30,}", html))
  expect_false(grepl("GoogleMapsKey", html, fixed = TRUE))
})

test_that("the credential stripper removes the node and keeps the links", {
  page <- charToRaw(paste0(
    '<html><body><input id="GoogleMapsKey" value="AIza',
    strrep("a", 35), '" />',
    '<a href="/x">REH CAP and RPGP Award Winners (PDF)</a></body></html>'))
  out <- rawToChar(ks_strip_credentials(page))
  expect_false(grepl("AIza", out))
  expect_true(grepl("REH CAP and RPGP Award Winners", out))
})


# -- assertions --------------------------------------------------------------

test_that("all Kansas assertions pass on the committed archive", {
  expect_true(rhtp_ks_assert(ks_awards))
})

test_that("the committed CSV matches a fresh parse", {
  on_disk <- readr::read_csv(here::here(KS_CSV), show_col_types = FALSE,
                             progress = FALSE)
  expect_equal(nrow(on_disk), nrow(ks_awards))
  expect_equal(sum(on_disk$amount), sum(ks_awards$amount))
  expect_equal(on_disk$awardee, ks_awards$awardee)
})
