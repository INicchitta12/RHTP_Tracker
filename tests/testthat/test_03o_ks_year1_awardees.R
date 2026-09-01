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

test_that("the award document's footer is the WEAK form, and names no programme", {
  # Session 27's audit, pinned so the reason Kansas needed rewiring cannot be
  # lost. The footer's grammatical SUBJECT is the slide deck; the document
  # never names the programme its awards belong to at all.
  one <- ks_join_lines(ks_document_text("reh_cap_rpgp"))
  expect_true(grepl("This presentation is supported by", one, fixed = TRUE))
  expect_false(grepl("This Rural Health Transformation Program", one,
                     fixed = TRUE))
  expect_equal(length(gregexpr("RHTP", one, fixed = TRUE)[[1]]
                      [gregexpr("RHTP", one, fixed = TRUE)[[1]] > 0]), 0L)
  expect_equal(
    length(gregexpr("Rural Health Transformation", one, fixed = TRUE)[[1]]
           [gregexpr("Rural Health Transformation", one, fixed = TRUE)[[1]] > 0]),
    0L)
})

test_that("the footer no longer STOPS Kansas -- it corroborates the amount", {
  # The direction that matters: a KDHE re-post dropping the deck's boilerplate
  # must not hard-fail a state whose provenance is established twice over
  # elsewhere. Fed a document with no footer, the corroborating call returns NA
  # with a message rather than throwing.
  expect_error(ks_assert_rhtp_funded("no footer here"))
  expect_message(
    got <- ks_assert_rhtp_funded("no footer here", strict = FALSE),
    "CORROBORATING check")
  expect_true(is.na(got))
})


# -- provenance: the two independent, PROGRAMME-SCOPED sources ---------------

test_that("KDHE's programme page says the GRANTS are RHTP, not the paper", {
  prose <- ks_program_page_prose()
  expect_true(grepl(
    "grants through the Kansas Rural Health Transformation Program (RHTP)",
    prose, fixed = TRUE))
  expect_true(grepl(
    "an initiative within the Rural Health Transformation Program (RHTP)",
    prose, fixed = TRUE))
  expect_true(ks_assert_program_page_provenance(prose))
})

test_that("the programme page states each pool's scale independently", {
  # 39 organizations / $79.1 million and seven / $1,007,152, published on the
  # page rather than in the award PDFs -- so a parse that drifted from the
  # documents fails here too.
  prose <- ks_program_page_prose()
  expect_true(grepl("$79.1 million is being awarded to 39 organizations",
                    prose, fixed = TRUE))
  expect_true(grepl("$1,007,152 was awarded to seven rural healthcare organizations",
                    prose, fixed = TRUE))
  expect_equal(nrow(ks_awards[ks_awards$award_pool != "CHW_AFIM", ]), 39L)
  expect_equal(nrow(ks_awards[ks_awards$award_pool == "CHW_AFIM", ]), 7L)
})

test_that("the programme-page check fails loudly if a sentence goes", {
  gutted <- sub("grants through the Kansas Rural Health Transformation Program",
                "grants through the programme", ks_program_page_prose(),
                fixed = TRUE)
  expect_error(ks_assert_program_page_provenance(gutted),
               "KANSAS'S PROVENANCE")
})

test_that("the RHT Plan narrative places all three awarded pools", {
  # `budget_rev2` has been registered in KS_SOURCES since session 20 and was
  # never opened. It is programme-scoped by construction and carries NO CMS
  # footer at all -- it does not need one, because the document IS the plan.
  narr <- ks_narrative_text()
  expect_true(grepl("Kansas RHT Plan Year 1 Budget Narrative", narr,
                    fixed = TRUE))
  expect_false(grepl("is supported by the Centers", narr, fixed = TRUE))
  expect_true(grepl("Program 1: Regional Partnership Grant Program (RPGP)",
                    narr, fixed = TRUE))
  expect_true(grepl(
    "REH Conversion/Transformative Capital Investment Grant Program",
    narr, fixed = TRUE))
  expect_true(grepl(paste("Program 1: Accountable Food Is Medicine and",
                          "Community Health Worker (CHW) Deployment Program",
                          "(A-FIM)"), narr, fixed = TRUE))
  expect_true(ks_assert_narrative_places_pools(narr))
})

test_that("the narrative's PLAN figures are not asserted against the AWARDS", {
  # A plan is not an award (§0.3). The plan budgets RPGP at $49,969,410.72 and
  # REH-CAP at $31,279,891.30; KDHE awarded $49,915,410 and $29,097,937.
  # Nothing reconciles the two universes, and this pins that they differ so a
  # later session does not "close" the gap by moving an award figure.
  narr <- ks_narrative_text()
  expect_true(grepl("$49,969,410.72", narr, fixed = TRUE))
  expect_true(grepl("$31,279,891.30", narr, fixed = TRUE))
  by_pool <- rhtp_ks_reconcile(ks_awards)$by_pool
  expect_equal(by_pool$total[by_pool$award_pool == "RPGP"], 49915410)
  expect_equal(by_pool$total[by_pool$award_pool == "REH_CAP"], 29097937)
})

test_that("the narrative check fails loudly if a pool leaves the plan", {
  gutted <- sub("Program 1: Regional Partnership Grant Program (RPGP)",
                "Program 1: Something Else", ks_narrative_text(), fixed = TRUE)
  expect_error(ks_assert_narrative_places_pools(gutted),
               "SECOND independent, programme-scoped")
})

test_that("provenance runs on the two programme-scoped sources, footer last", {
  prov <- ks_assert_rhtp_provenance()
  expect_true(prov$program_page)
  expect_true(prov$budget_narrative)
  expect_true(prov$after_noa)
  expect_equal(prov$footer_stated, 221890007.82)
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

test_that("the date test is ASSERTED now, from KDHE's own timeline", {
  # Session 27's audit: Kansas was the only one of the five footer states with
  # no *_assert_after_noa(). Its 6 March 2026 webinar date lived in a comment.
  # The anchor is read from KDHE's own Year One Timeline, not typed.
  prose <- ks_program_page_prose()
  expect_true(grepl("Dec. 29, 2025 - Notice of Award", prose, fixed = TRUE))
  expect_equal(ks_assert_after_noa(prose, ks_links), "2025-12-29")
})

test_that("the date test fails if KDHE's timeline stops stating the NOA", {
  gutted <- sub("Dec. 29, 2025 - Notice of Award", "Notice of Award",
                ks_program_page_prose(), fixed = TRUE)
  expect_error(ks_assert_after_noa(gutted, ks_links),
               "no longer states its own Notice of Award")
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

test_that("the $8,000.18 is the award DECK's alone -- KDHE and CMS agree", {
  # Session 20 recorded this as "two publishers disagree about Kansas's
  # award". Wiring the provenance meant reading KDHE's other two
  # publications, and both say $221,898,007.82 -- CMS's own table to the cent.
  # So the deck transposes 898 as 890 and nothing else does. Nothing is
  # corrected (§8); all three figures are pinned.
  expect_equal(ks_rec$cms_award_stated, 221890007.82)
  expect_equal(ks_rec$kdhe_award_page, 221898007.82)
  expect_equal(ks_rec$kdhe_award_narrative, 221898007.82)
  expect_equal(ks_rec$cms_allotment, 221898008)
  expect_equal(round(ks_rec$deck_gap, 2), 8000.18)
  expect_equal(round(ks_rec$publisher_gap, 2), 0.18)

  # And the two figures are read out of the documents, not carried in a list.
  expect_true(grepl("$221,898,007.82", ks_program_page_prose(), fixed = TRUE))
  expect_true(grepl("$221,898,007.82", ks_narrative_text(), fixed = TRUE))
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
  expect_equal(nrow(inferred), 23L)
  expect_equal(sum(inferred$amount), 40182073)
  expect_gt(sum(inferred$amount), part$dollars)
})

test_that("Salina is the 23rd form-not-stated row, and it cost no hospital dollar", {
  # SESSION 31. Tightening RHTP_PASS_THROUGH_MARKERS to money-movement
  # language re-coded this row IN_KIND_BENEFIT -- KDHE says AstraHealth Kansas
  # provides "back-office and clinical infrastructure TO RURAL HOSPITALS",
  # which is a service the recipient delivers, not a dollar it passes on. The
  # row carries ONE flag slot, and it was spent on ELIGIBILITY_NOT_RECEIPT; the
  # question KDHE's silence actually raises -- what form is Salina Regional
  # Health Center? -- could not surface behind it.
  #
  # THE DISCLOSURE GREW AND THE FIGURE DID NOT MOVE. Salina reads like a
  # hospital and was absent from the queue that exists to ask exactly that,
  # while the named-hospital floor is 21 rows / $35,721,277 before and after.
  salina <- ks_awards %>% dplyr::filter(grepl("^Salina Regional", awardee))
  expect_equal(nrow(salina), 1L)
  expect_equal(salina$flow_type, "IN_KIND_BENEFIT")
  expect_equal(salina$distributed_to_hospital, "No")
  expect_equal(salina$flag_reason, "RECIPIENT_TYPE_INFERRED")
  expect_equal(salina$amount, 932310)

  part <- rhtp_hospital_dollar_partition(ks_awards)
  expect_equal(part$bucket, "NAMED_HOSPITAL")
  expect_equal(part$dollars, 35721277)
  expect_equal(part$rows, 21L)
  # 23 - 22 = 1 row, and the whole of the delta is Salina's own amount.
  expect_equal(40182073 - 39249763, 932310)
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
  expect_true(grepl("40,182,073", row$dollar_effect))
  expect_true(grepl("23 rows", row$dollar_effect))
  # The queue row has to SAY why it grew, or the next reader reconciles it
  # against session 20's 22/$39,249,763 and cannot.
  expect_true(grepl("Salina Regional Health Center", row$dollar_effect,
                    fixed = TRUE))
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
