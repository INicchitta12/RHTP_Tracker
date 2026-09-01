# test_03w_mo_year1_awardees.R ------------------------------------------------
# Missouri. Reads the committed archive only -- no network, no quota.
#
# THE ONE THING THIS FILE EXISTS TO PIN. Missouri publishes a named,
# 27-organisation, recipient-level roster in which 14 organisations are
# hospitals or health systems, and NOT ONE ROW IS AN AWARD. Everything below
# is arranged so that a future session cannot quietly turn that roster into
# hospital dollars, and so that the day Missouri DOES attach money to it, the
# build fails rather than succeeding with a new meaning.

library(testthat)

source(here::here("R", "03w_mo_year1_awardees.R"))

mo_awards  <- rhtp_mo_year1_awardees()
mo_anchors <- rhtp_mo_hub_anchors()
mo_rec     <- rhtp_mo_reconcile(mo_awards, mo_anchors)


# -- provenance, programme-scoped --------------------------------------------

test_that("provenance is programme-scoped, not the CMS footer", {
  # Session 27's audit applied at the point of extraction. Each sentence has
  # the AWARD ACTION or THE PROGRAMME as its subject.
  doula <- mo_html_text("pr_doula")
  expect_true(grepl("$732,660.43 was awarded to the MDA", doula, fixed = TRUE))
  expect_true(grepl("The investment is part of the RHTP", doula, fixed = TRUE))

  memsa <- mo_html_text("pr_memsa")
  expect_true(grepl(
    "through the Rural Health Transformation Program (RHTP), has announced a partnership",
    memsa, fixed = TRUE))

  expect_equal(mo_assert_rhtp_provenance(), MO_STATED$cms_award_stated)
})

test_that("the CMS footer here is the WEAK form, and is corroborating only", {
  # Its subject is "The Rural Health Transformation Program INFORMATION
  # PROVIDED BY the Missouri Department of Social Services" -- the publication.
  # Nevada is why that cannot stand alone (session 26).
  for (k in c("pr_doula", "pr_memsa", "pr_hub")) {
    one <- mo_html_text(k)
    expect_true(grepl("information provided by the Missouri Department of Social Services is supported by",
                      one, fixed = TRUE), info = k)
    expect_false(grepl("This Rural Health Transformation Program is supported by",
                       one, fixed = TRUE), info = k)
  }
})

test_that("DSS's footer figure and CMS's table agree once rounded", {
  expect_equal(mo_rec$cms_award_stated, 216276817.66)
  expect_equal(mo_rec$cms_allotment, 216276818)
  expect_equal(round(mo_rec$publisher_gap, 2), 0.34)
})

test_that("every Missouri document postdates the Notice of Award", {
  expect_equal(mo_assert_after_noa(), "2025-12-29")
})


# -- the 27 are NOT awards ---------------------------------------------------

test_that("DSS says in its own words that Hub Anchors are not funded", {
  faq <- mo_pdf_text("torch_faq")
  expect_true(grepl("Hub Anchors will not act as the fiscal agent", faq,
                    fixed = TRUE))
  expect_true(grepl("Will Hub Anchors receive funding or compensation?", faq,
                    fixed = TRUE))
  hub <- mo_html_text("pr_hub")
  expect_true(grepl(
    "subject to execution of a Hub Anchor Participation Agreement", hub,
    fixed = TRUE))
  expect_true(mo_assert_anchors_not_awarded())
})

test_that("the roster carries no dollar figure anywhere", {
  roster <- mo_pdf_text("hub_roster")
  expect_false(grepl("\\$\\s?[0-9]", roster))
  expect_false(grepl("(?i)award(ed)?\\b", roster, perl = TRUE))
})

test_that("the file REFUSES the day Missouri prices the Hub Anchor role", {
  # Designed to fail, and the failure is the signal. Fed a roster carrying an
  # amount, mo_assert_anchors_not_awarded() must stop rather than absorb it.
  faked <- paste(mo_pdf_text("hub_roster"),
                 "1 Mosaic Medical Center - Maryville $2,000,000")
  expect_error(mo_assert_anchors_not_awarded(roster = faked),
               "NOW CARRIES A DOLLAR FIGURE")

  # And each of DSS's two disqualifying sentences, removed one at a time.
  expect_error(
    mo_assert_anchors_not_awarded(faq = "no such sentence"),
    "will not act as the fiscal agent")
  expect_error(
    mo_assert_anchors_not_awarded(hub = "no such sentence"),
    "Participation Agreement")
})

test_that("mo_hub_anchors.csv has no amount column, and cannot grow one", {
  # Texas's device, in the schema. A column named `amount` on a 27-row roster
  # of named hospitals invites a sum over a quantity Missouri has never
  # published.
  expect_false("amount" %in% names(mo_anchors))
  expect_false("round_amount" %in% names(mo_anchors))
  expect_false("amount" %in% names(readr::read_csv(
    here::here(MO_HUB_CSV), show_col_types = FALSE, progress = FALSE)))
  expect_error(rhtp_mo_assert(mo_awards,
                              dplyr::mutate(mo_anchors, amount = 1)),
               "grown an amount column")
})

test_that("the roster parses as hubs 1..27 with no gap", {
  expect_equal(nrow(mo_anchors), 27L)
  expect_equal(mo_anchors$hub_number, 1:27)
  expect_equal(dplyr::n_distinct(mo_anchors$organization), 27L)
  expect_true(all(mo_anchors$award_made == "No"))
  expect_true(all(mo_anchors$agreement_executed == "No"))
})

test_that("a truncated roster read is refused, not returned short", {
  short <- mo_pdf_lines("hub_roster")
  short <- short[!grepl("^\\s*17\\s", short)]
  expect_error(mo_parse_hub_anchors(short), "did not parse as hubs 1")
})

test_that("14 anchors are hospitals and 11 carry §8's fallback -- COUNT them", {
  # Nevada's lesson: when the dollar column is empty the ROW COUNT is the
  # load-bearing quantity. Missouri's $0 is not "no hospitals".
  expect_equal(sum(mo_anchors$is_hospital_or_system), 14L)
  expect_equal(sum(mo_anchors$recipient_type == "NONPROFIT_CBO"), 11L)
  expect_true("Taney County Health Department" %in%
                mo_anchors$organization[
                  mo_anchors$recipient_type == "LOCAL_GOVT_OR_PUBLIC_HEALTH"])
})

test_that("nothing was promoted on this pipeline's own knowledge (§0.4)", {
  # Five of the eleven read as hospitals to anyone who knows Missouri. They
  # stay in §8's fallback until the CCN match resolves them.
  fallback <- mo_anchors$organization[
    mo_anchors$recipient_type == "NONPROFIT_CBO"]
  for (nm in c("Ozarks Healthcare", "Golden Valley Memorial Healthcare",
               "Bothwell Regional Health Center", "Hannibal Regional Health Center",
               "Parkland Health Center")) {
    expect_true(nm %in% fallback, info = nm)
  }
})

test_that("the open questions are in the review queue", {
  q <- readr::read_csv(
    here::here("data", "reference", "classification_review_queue.csv"),
    show_col_types = FALSE, progress = FALSE)
  expect_true("MO_ANCHOR_FORM_NOT_STATED" %in% q$question_id)
  expect_true("MO_ANCHOR_IS_NOT_AN_AWARD" %in% q$question_id)
  row <- q[q$question_id == "MO_ANCHOR_FORM_NOT_STATED", ]
  expect_true(grepl("\\$0 in either direction", row$dollar_effect))
})


# -- the two real awards -----------------------------------------------------

test_that("Missouri has awarded two named partnerships, $7,232,660.43", {
  expect_equal(nrow(mo_awards), 2L)
  expect_equal(round(sum(mo_awards$amount), 2), 7232660.43)
  expect_equal(
    mo_awards$amount[mo_awards$awardee == "Missouri Doula Association"],
    732660.43)
})

test_that("MEMSA's figure is rounded AND multi-year, and says so", {
  memsa <- mo_awards[grepl("Emergency Medical", mo_awards$awardee), ]
  expect_equal(memsa$amount, 6500000)
  expect_equal(memsa$amount_confirmed, "No")
  expect_equal(memsa$flag_reason,
               "AMOUNT_ROUNDED_IN_SOURCE;AMOUNT_IS_MULTI_YEAR_TOTAL")
  expect_true(grepl("2027-07-31", memsa$amount_basis))
  # DSS's own wording: "around $6.5M through July 31, 2027".
  expect_true(grepl("around $6.5M through July 31, 2027",
                    mo_html_text("pr_memsa"), fixed = TRUE))
})

test_that("neither award reaches a hospital, and $0 is a published fact", {
  expect_true(all(mo_awards$distributed_to_hospital == "No"))
  part <- rhtp_hospital_dollar_partition(mo_awards)
  expect_equal(nrow(part), 0L)
})


# -- the controls ------------------------------------------------------------

test_that("the roster control fails if DSS's one roster link disappears", {
  links <- mo_links("program_page")
  expect_true(mo_assert_roster_index(links))
  gutted <- dplyr::mutate(
    links, href = gsub(MO_ROSTER_LINK, "something-else", href, fixed = TRUE))
  expect_error(mo_assert_roster_index(gutted), "POSITIVE CONTROL")
})

test_that("the roster control fails if a SECOND roster appears", {
  links <- mo_links("program_page")
  extra <- dplyr::bind_rows(links, tibble::tibble(
    href = "/media/pdf/torch-care-smart-growth-awardees",
    text = "ToRCH Care Smart Growth Award Recipients"))
  expect_error(mo_assert_roster_index(extra), "does not carry")
})

test_that("the control is not fired by DSS's own APPLICATION links", {
  # DSS publishes the Hub Anchor APPLICATION and an invitation-to-apply release
  # under link text that also says "Hub Anchor". A control that fired on those
  # would be widened every time it fired, which is how a tripwire becomes
  # decoration.
  links <- mo_links("program_page")
  expect_true(any(grepl("Hub Anchor Application", links$text, fixed = TRUE)))
  expect_true(mo_assert_roster_index(links))
})

test_that("Missouri's award channel is PROCUREMENT and it has awarded nobody", {
  # Indiana's sixth question, answered by the state rather than inferred.
  page <- mo_html_text("program_page")
  expect_true(grepl("Announce select procurement awardees", page, fixed = TRUE))
  expect_true(grepl("Launch select procurements across pillars", page,
                    fixed = TRUE))
  bids <- mo_html_text("bids")
  expect_true(grepl("IFB # DSS26015-02", bids, fixed = TRUE))
  expect_true(mo_assert_procurement_pending())
})

test_that("the pass-through control: the Children's Trust Fund names nobody", {
  ctf <- mo_html_text("ctf")
  expect_true(grepl("Stay tuned for future", ctf, fixed = TRUE))
  expect_true(mo_assert_ctf_unnamed())
})

test_that("where Missouri's hospital money will be, stated on its own page", {
  # ~$40M anticipated, awards up to $5M, and "Funding is open to hospitals".
  page <- mo_html_text("program_page")
  expect_true(grepl("the total anticipated funding for this phase is nearly $40 million",
                    page, fixed = TRUE))
  expect_true(grepl("Individual awards of up to $5 million", page, fixed = TRUE))
  expect_true(grepl("Funding is open to hospitals", page, fixed = TRUE))
})


# -- §0.1 --------------------------------------------------------------------

test_that("27 of RCJ's 29 Missouri candidates are the governance roster", {
  cands <- mo_rcj_candidates()
  expect_equal(nrow(cands), 29L)
  is_anchor <- cands$awardee_name_clean %in% mo_anchors$organization
  expect_equal(sum(is_anchor), 27L)
  # Every one of them carries an amount of $1 -- which is why no plausibility
  # check on the amount catches this. RCJ publishes a placeholder, not a wrong
  # figure.
  expect_true(all(cands$amount_announced[is_anchor] == 1))
})

test_that("RCJ understates the one exact award it holds", {
  cands <- mo_rcj_candidates()
  mda <- cands[grepl("Doula", cands$awardee_name_clean), ]
  expect_equal(nrow(mda), 1L)
  expect_equal(mda$amount_announced, MO_STATED$rcj_mda_amount)
  expect_lt(mda$amount_announced, MO_STATED$mda_amount)
})

test_that("the disposition covers every candidate, re-derived not typed", {
  dispo <- rhtp_mo_rcj_disposition()
  expect_equal(sum(dispo$rows), nrow(mo_rcj_candidates()))
  expect_true("NOT_AN_AWARD_GOVERNANCE_ROLE" %in% dispo$disposition)
})


# -- the archive -------------------------------------------------------------

test_that("the archive verifies and carries no credential", {
  man <- readLines(file.path(MO_EVIDENCE_DIR, "MANIFEST.txt"), warn = FALSE)
  listed <- stringr::str_match(man, "^([0-9a-f]{64})  (\\S+)  \\(")
  listed <- listed[!is.na(listed[, 1]), , drop = FALSE]
  expect_equal(nrow(listed), nrow(MO_SOURCES))
  expect_false("MANIFEST.txt" %in% listed[, 3])
  for (i in seq_len(nrow(listed))) {
    path <- file.path(MO_EVIDENCE_DIR, listed[i, 3])
    expect_true(file.exists(path), info = listed[i, 3])
    expect_equal(digest::digest(file = path, algo = "sha256"), listed[i, 2],
                 info = listed[i, 3])
  }
  expect_setequal(listed[, 3], MO_SOURCES$file)
})

test_that("the credential guard refuses a body carrying a key", {
  expect_error(
    mo_assert_credential_free(charToRaw("var k='AIzaSyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';"), "x"),
    "google_api_key")
})


# -- the committed files -----------------------------------------------------

test_that("the committed CSVs match a fresh parse", {
  on_disk <- readr::read_csv(here::here(MO_CSV), show_col_types = FALSE,
                             progress = FALSE)
  expect_equal(nrow(on_disk), nrow(mo_awards))
  expect_equal(on_disk$awardee, mo_awards$awardee)
  expect_equal(on_disk$amount, mo_awards$amount)

  hubs <- readr::read_csv(here::here(MO_HUB_CSV), show_col_types = FALSE,
                          progress = FALSE)
  expect_equal(hubs$organization, mo_anchors$organization)
})

test_that("all Missouri assertions pass on the committed archive", {
  expect_true(rhtp_mo_assert(mo_awards, mo_anchors))
})
