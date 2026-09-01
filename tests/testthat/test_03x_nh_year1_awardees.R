# test_03x_nh_year1_awardees.R ------------------------------------------------
# New Hampshire. Reads the committed archive only -- no network, no quota.
#
# THE TWO THINGS THIS FILE EXISTS TO PIN.
#
# 1. NEW HAMPSHIRE HAS NAMED NO SUBRECIPIENT, and its hospital-facing RFA had
#    not been published at all. Everything here is arranged so that the day FHC
#    publishes a roster, the build FAILS rather than quietly continuing to
#    report a two-row administrator file as New Hampshire's position.
#
# 2. FHC IS NOT ICAHN. Both are executed awards to a designated pass-through
#    administrator with no hospital named, and they code DIFFERENTLY, on §10.2's
#    second clause: ICAHN's eligibility was HOSPITALS ONLY (`Yes`), FHC's is
#    hospitals AMONG OTHERS (`Unclear`, §0.3). A future session that "tidies"
#    these two into one coding would publish $66.5M as hospital-bound money on
#    this pipeline's authority.

library(testthat)

source(here::here("R", "03x_nh_year1_awardees.R"))

nh_awards <- rhtp_nh_year1_awardees()
nh_rec    <- rhtp_nh_reconcile(nh_awards)


# -- provenance, programme-scoped, footer demoted -----------------------------

test_that("provenance is programme-scoped, not the CMS footer", {
  # Session 27's audit. Each required sentence has the AWARD ACTION or THE
  # PROGRAMME as its grammatical subject.
  fhc <- nh_html_text("fhc_rhtp")
  expect_true(grepl(NH_PROVENANCE$fhc_award, fhc, fixed = TRUE))
  expect_true(grepl(NH_PROVENANCE$gonorth_is_rhtp, fhc, fixed = TRUE))

  cdfa <- nh_html_text("cdfa_statement")
  expect_true(grepl(NH_PROVENANCE$cdfa_council, cdfa, fixed = TRUE))
  expect_true(grepl(NH_PROVENANCE$cdfa_is_rhtp, cdfa, fixed = TRUE))

  expect_true(nh_assert_rhtp_provenance())
})

test_that("the footer is NON-STRICT and corroborates an AMOUNT only", {
  # Kansas's demotion (session 28). Called non-strictly it returns NA with a
  # message rather than throwing, so a page re-post that drops the boilerplate
  # cannot hard-fail New Hampshire for no reason -- AND a future state whose
  # only evidence is a "this project" footer does not pass the test NH passes.
  expect_true("strict" %in% names(formals(nh_assert_footer_corroborates)))
  expect_true(nh_assert_footer_corroborates(strict = FALSE))

  gutted <- gsub(NH_FOOTER$fhc, "", nh_html_text("fhc_rhtp"), fixed = TRUE)
  expect_message(res <- nh_assert_footer_corroborates(fhc = gutted,
                                                      strict = FALSE))
  expect_true(is.na(res))
  expect_error(nh_assert_footer_corroborates(fhc = gutted, strict = TRUE),
               "CORROBORATION OF AN AMOUNT")
})

test_that("§0.2 in ONE document: two CMS footers, two TIERS", {
  # Virginia's worked example, met a second time. FHC's page carries the
  # STATE's Tier 1 allotment and FHC's OWN Tier 3 award as two footers, both
  # official, both "New Hampshire FY2026", separated only by tier.
  fhc <- nh_html_text("fhc_rhtp")
  expect_true(grepl(NH_FOOTER$allotment, fhc, fixed = TRUE))
  expect_true(grepl(NH_FOOTER$fhc, fixed = TRUE, x = fhc))
  expect_false(NH_STATED$cms_allotment_anchor == NH_STATED$fhc_award_exact)

  # The Tier 1 footer matches the §7.1 anchor to the cent.
  allot <- rhtp_load_allotments()
  expect_equal(allot$fy2026_allotment[allot$state == "NH"],
               NH_STATED$cms_allotment_anchor)
  expect_lt(abs(NH_STATED$cms_allotment_stated -
                  NH_STATED$cms_allotment_anchor), 1)
})

test_that("the date test: the Council acted AFTER the CMS Notice of Award", {
  noa <- rhtp_read_noa_dates()
  expect_equal(as.character(noa$noa_date[noa$state == "NH"]),
               NH_STATED$noa_date)
  expect_gt(as.Date(NH_STATED$council_date), as.Date(NH_STATED$noa_date))
  expect_true(nh_assert_after_noa())
})


# -- the negative, and its controls ------------------------------------------

test_that("NEW HAMPSHIRE HAS NAMED NO SUBRECIPIENT", {
  expect_true(nh_assert_no_roster_yet())
  expect_equal(nh_rec$named_hospitals, 0L)
  expect_equal(nh_rec$hospital_dollars, 0)
  expect_false(any(nh_awards$distributed_to_hospital == "Yes"))
})

test_that("the no-roster assertion FIRES when FHC publishes one", {
  # DESIGNED TO FAIL. Each of these sentences going is New Hampshire changing
  # what it is claiming, and the failure is the signal.
  fhc <- nh_html_text("fhc_rhtp")
  for (nm in names(NH_NO_ROSTER_YET)) {
    hay <- gsub("–|—", "-", fhc)
    gutted <- gsub(NH_NO_ROSTER_YET[[nm]], "", hay, fixed = TRUE)
    expect_error(nh_assert_no_roster_yet(fhc = gutted),
                 "MAY HAVE PUBLISHED A SUBRECIPIENT ROSTER", info = nm)
  }
})

test_that("the positive control: a roster WOULD be recognisable", {
  # Without this, "no roster" is indistinguishable from "we are reading the
  # wrong page". FHC publishes a structured funding-opportunity index with
  # Open, Upcoming and Closed sections; all three must be present.
  expect_true(nh_assert_opportunity_index())
  fhc <- nh_html_text("fhc_rhtp")
  for (section in c("Funding Opportunities - Upcoming",
                    "Funding Opportunities - Closed",
                    "Current Funding Opportunities")) {
    expect_error(
      nh_assert_opportunity_index(
        fhc = gsub(section, "", fhc, fixed = TRUE)),
      "positive control", info = section)
  }
})


# -- FHC is not ICAHN, and the eligible class is why -------------------------

test_that("FHC codes Unclear where ICAHN codes Yes, on §10.2's second clause", {
  fhc_row <- nh_awards[nh_awards$row_no == 1L, ]
  expect_equal(fhc_row$flow_type, "PASS_THROUGH_UNRESOLVED")
  expect_equal(fhc_row$distributed_to_hospital, "Unclear")
  expect_equal(fhc_row$hospital_attribution, "NOT_HOSPITAL")

  # Illinois, for contrast, on the committed file rather than from memory.
  il <- readr::read_csv(here::here("data/reference/il_year1_awardees.csv"),
                        show_col_types = FALSE)
  expect_equal(il$flow_type[1], "PASS_THROUGH_DESIGNATED")
  expect_equal(il$distributed_to_hospital[1], "Yes")

  # The whole difference, in the source's own words.
  expect_true(grepl(NH_ELIGIBLE_CLASS, nh_html_text("fhc_rhtp"), fixed = TRUE))
  expect_true(grepl("critical access hospitals", NH_ELIGIBLE_CLASS))
  expect_true(grepl("community-based organizations", NH_ELIGIBLE_CLASS))
  # Losing that sentence must stop the build, not silently re-code the row.
  expect_error(
    nh_assert_no_roster_yet(
      fhc = gsub(NH_ELIGIBLE_CLASS, "", nh_html_text("fhc_rhtp"),
                 fixed = TRUE)),
    "hospitals AMONG OTHERS")
})

test_that("neither row enters either bucket of the partition", {
  # §0.3: an unresolved pass-through pool is never imputed. Both NH rows are
  # outside NAMED_HOSPITAL, POOL_NAMED_HOSPITALS and POOL_UNNAMED_HOSPITALS.
  expect_true(all(nh_awards$hospital_attribution == "NOT_HOSPITAL"))
  expect_equal(sum(nh_awards$amount[
    nh_awards$distributed_to_hospital == "Yes"], na.rm = TRUE), 0)
})


# -- the amounts -------------------------------------------------------------

test_that("CDFA's ceiling is NOT in `amount` (§6.2)", {
  cdfa <- nh_awards[nh_awards$row_no == 2L, ]
  # "up to $40 million a year" is a programme ceiling, not an award figure.
  expect_true(is.na(cdfa$amount))
  expect_equal(cdfa$round_amount, NH_STATED$cdfa_ceiling)
  expect_equal(cdfa$amount_confirmed, "No")
  # So a sum over `amount` is FHC's award and nothing else.
  expect_equal(nh_rec$awards_total, NH_STATED$fhc_award_exact)
})

test_that("CDFA is NON_HOSPITAL on the class the source itself states", {
  # §0.3a: judge the RECIPIENT, and here the source states the recipient class
  # outright -- rural health clinics, CMHCs, FQHCs and county-run assisted
  # living. Hospitals are not among them.
  cdfa_txt <- nh_html_text("cdfa_statement")
  expect_true(grepl("rural health clinics, community mental health centers, federally qualified health centers and county-run assisted living facilities",
                    cdfa_txt, fixed = TRUE))
  expect_equal(nh_awards$flow_type[2], "NON_HOSPITAL")
  expect_equal(nh_awards$distributed_to_hospital[2], "No")
})


# -- the status table, and the host that is UNREACHABLE ----------------------

test_that("the status table has NO amount column, and an assertion refuses one", {
  status <- rhtp_nh_status()
  expect_false("amount" %in% names(status))
  expect_false("round_amount" %in% names(status))
  expect_true(nrow(status) >= 6L)
})

test_that("nh.gov is recorded as UNREACHABLE, which is not a negative", {
  # §0.4, and it is the same discipline as memsa.org one state over. What the
  # State of New Hampshire publishes on its own sites is UNKNOWN to this
  # repository and must never harden into "New Hampshire published nothing".
  status <- rhtp_nh_status()
  state_row <- status[status$host_reachable == "No", ]
  expect_equal(nrow(state_row), 1L)
  expect_equal(state_row$publishes_roster, "UNKNOWN")
  expect_true(grepl("UNREACHABLE, NOT NEGATIVE", state_row$evidence,
                    fixed = TRUE))

  blocked <- nh_blocked_hosts()
  expect_gte(nrow(blocked), 8L)
  expect_true(all(blocked$http_status == 403L))
  # Four agents were tried, and naming them is what makes the claim checkable
  # rather than asserted -- and what stops §3's michigan.gov exception being
  # reached for on the strength of "a bare agent worked once".
  expect_length(NH_BLOCKED_AGENTS, 4L)
  expect_true(any(grepl("bare Mozilla", NH_BLOCKED_AGENTS)))
  expect_true(all(grepl("nh.gov", blocked$url)))
})


# -- RCJ candidate disposition (§0.1) ----------------------------------------

test_that("the disposition covers every candidate, re-derived not typed", {
  cands <- nh_rcj_candidates()
  dispo <- rhtp_nh_rcj_disposition(cands)
  expect_equal(sum(dispo$rows), nrow(cands))
  expect_true(all(dispo$state == "NH"))
  expect_false(any(is.na(dispo$why)))
})

test_that("RCJ prices ONE Council action at three different amounts", {
  # The tell that the aggregator is pricing DOCUMENTS, not awards. Also §2:
  # three spellings of one organisation, which a machine must not merge.
  cands <- nh_rcj_candidates()
  cdfa <- cands[grepl("Community Development Finance Authority",
                      cands$awardee_name_clean), ]
  expect_gte(nrow(cdfa), 4L)
  priced <- sort(unique(cdfa$amount_announced[cdfa$amount_announced > 1]))
  expect_gte(length(priced), 3L)
  expect_gte(length(unique(cdfa$awardee_name_clean)), 3L)
})

test_that("the $1 placeholder runs through the candidate set (Missouri's tell)", {
  cands <- nh_rcj_candidates()
  expect_gte(sum(cands$amount_announced == 1, na.rm = TRUE), 3L)
  # RCJ publishes a PLACEHOLDER rather than a wrong figure, which is the one
  # defect no amount plausibility check can see.
  dispo <- rhtp_nh_rcj_disposition(cands)
  expect_true(any(grepl("PLACEHOLDER", dispo$disposition)))
})

test_that("the Medicaid rows are NOT RHTP, and §6.2 caught one twice", {
  # The $1,898,965,390 row against a $204,016,550 allotment: flagged by the
  # allotment ceiling in session 5 and independently disposed of by the
  # provenance sweep in session 20. Two §6.2 filters, opposite directions.
  cands <- nh_rcj_candidates()
  mcm <- cands[grepl("AmeriHealth Caritas|WellSense|Healthy Families",
                     cands$awardee_name_clean), ]
  expect_gte(nrow(mcm), 3L)
  expect_true(any(mcm$amount_announced > NH_STATED$cms_allotment_anchor))
  dispo <- rhtp_nh_rcj_disposition(cands)
  expect_true(any(dispo$disposition == "NOT_RHTP_MEDICAID"))
})


# -- the archive -------------------------------------------------------------

test_that("the archive verifies and carries no credential", {
  for (key in NH_SOURCES$key) {
    path <- nh_path(key)
    expect_true(file.exists(path), info = key)
    body <- readBin(path, "raw", file.size(path))
    expect_true(nh_assert_credential_free(body, key), info = key)
  }
  manifest <- file.path(NH_EVIDENCE_DIR, "MANIFEST.txt")
  expect_true(file.exists(manifest))
  txt <- paste(readLines(manifest, warn = FALSE), collapse = "\n")
  # Every archived file's digest must reproduce from the bytes on disk.
  for (i in seq_len(nrow(NH_SOURCES))) {
    p <- file.path(NH_EVIDENCE_DIR, NH_SOURCES$file[i])
    expect_true(grepl(digest::digest(file = p, algo = "sha256"), txt,
                      fixed = TRUE), info = NH_SOURCES$file[i])
  }
  # A manifest cannot record its own digest (session 15).
  expect_false(grepl("MANIFEST.txt", sub("^.*?\n", "", txt), fixed = TRUE))
})

test_that("all New Hampshire assertions pass on the committed archive", {
  expect_true(rhtp_nh_assert())
})
