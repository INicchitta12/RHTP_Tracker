# test_03ai_ar_year1_awardees.R -----------------------------------------------
# ARKANSAS: EXTRACTED in session 40. 31 organisations, 37 priced award actions,
# $149,177,618.45, and a SECOND publisher at a FINER GRAIN. Committed files
# only -- no network.
#
# THE TESTS THAT CARRY THE WEIGHT ARE THE ONES GUARDING THE WAYS THIS
# EXTRACTION COULD BE WRONG, AND NOT ONE OF THEM IS A CRASH.
#
#  (1) THE LINE MODEL RETURNS A PLAUSIBLE-LOOKING WRONG ANSWER. The three
#      amount columns are painted at one y, so `rhtp_pdf_lines()` yields
#      "$2,571,095.00$0.00$2,571,095.00". A session that "simplified" the
#      parser back to the line model would not crash -- it would extract
#      nothing and report an empty state. Tested by reproducing the merge.
#  (2) THE `Total:` ROW IS PAINTED LIKE AN AWARD ROW. Read as a recipient it
#      gives 32 organisations and DOUBLE the money, and the number still looks
#      like a total because it is one. Tested by driving that mistake.
#  (3) THRIVE AND PACT CAN BE SWAPPED AND BOTH READINGS LOOK FINE. $55.7M and
#      $93.6M are both plausible Arkansas figures. Tested three ways, because
#      the reconciliation on all three columns is the only thing that tells
#      them apart.
#  (4) ONE OF THE FIFTY PROJECT AMOUNTS IS PAINTED AS TWO NODES, so the
#      obvious regex finds 49 and drops $1,455,689.00 IN SILENCE -- the sums
#      simply miss by that much and nothing points at the row.
#  (5) SEVEN ORGANISATIONS ARE SPELLED DIFFERENTLY BY THE TWO PUBLISHERS and
#      one pair CLASSIFIES DIFFERENTLY, worth $301,400. A fuzzy merge here
#      changes a DOLLAR, not just a label.
#  (6) FOUR OF THE SIX LARGEST AWARDS IN THE STATE READ AS HOSPITALS AND NONE
#      IS TYPED BY THE SOURCE. Promoting them is the §0.4 failure, and it
#      would move $100.7M.

library(testthat)

source(here::here("R", "03ai_ar_year1_awardees.R"))

skip_without_archive <- function() {
  if (!file.exists(ar_path("roster")) || !file.exists(ar_path("governor"))) {
    skip("the AR evidence archive is not on disk")
  }
}


# -- (1) the run model, and why this file needs it ---------------------------

test_that("the LINE model welds the three amount columns into one string", {
  skip_without_archive()
  L <- rhtp_pdf_lines(ar_path("roster"))
  welded <- L$text[stringr::str_detect(L$text, "^\\$[0-9,]+\\.[0-9]{2}\\$")]
  expect_gt(length(welded), 20L)
  # Arkansas's first award row, as the line model returns it.
  expect_true("$2,571,095.00$0.00$2,571,095.00" %in% welded)
  # And no line in the whole document is a single clean amount cell, so there
  # is no way to read the columns from the line model at all.
  expect_true(ar_assert_line_model_merges())
})

test_that("the RUN model separates them at the producer's own boundaries", {
  skip_without_archive()
  r <- ar_runs("roster")
  r$t <- trimws(r$text)
  cells <- r[stringr::str_detect(r$t, AR_AMOUNT_CELL_RE), ]
  # 31 award rows + the Total row, three cells each.
  expect_equal(nrow(cells), (AR_ORG_COUNT + 1L) * 3L)
  expect_true(all(!stringr::str_detect(cells$t, "\\$.*\\$")))
})

test_that("nothing in the parse thresholds a gap or reads a column boundary", {
  skip_without_archive()
  # The three amounts of a row are the three RUNS of its line. If this parser
  # were keyed on x against a fixed boundary it would break on Arkansas's own
  # geometry: the amount runs sit between x=297 and x=359 while the HEADER
  # runs sit at 292, 372 and 451, so no single x threshold separates the body
  # columns and the header at once.
  r <- ar_runs("roster")
  r$t <- trimws(r$text)
  amt <- r[stringr::str_detect(r$t, AR_AMOUNT_CELL_RE), ]
  hdr <- r[r$t %in% c("THRIVE", "PACT"), ]
  expect_true(max(amt$x) < max(hdr$x))
  expect_true(min(amt$x) > min(hdr$x))
})


# -- (2) the Total row is not a recipient ------------------------------------

test_that("the `Total:` row is split off and is the reconciliation target", {
  skip_without_archive()
  parts <- ar_roster_parts()
  expect_equal(nrow(parts$awards), AR_ORG_COUNT)
  expect_equal(nrow(parts$total), 1L)
  expect_match(parts$total$label, "^Total:?$")
  expect_false(any(stringr::str_detect(parts$awards$label, "^Total")))
  expect_equal(parts$total$total, AR_TOTAL_YR1)
})

test_that("reading the Total row as a recipient doubles the money", {
  # The mistake, driven rather than described. 32 rows and $298,355,236.90 --
  # against a $208,779,396 allotment, so it would also breach the §6.2
  # allotment ceiling, which is the only reason it would be caught at all.
  skip_without_archive()
  all_rows <- ar_roster()
  expect_equal(nrow(all_rows), AR_ORG_COUNT + 1L)
  expect_equal(round(sum(all_rows$total), 2), round(2 * AR_TOTAL_YR1, 2))
  expect_gt(sum(all_rows$total), AR_ALLOTMENT)
})


# -- (3) which column is THRIVE and which is PACT ----------------------------

test_that("the header names the columns in the order the PDF paints them", {
  skip_without_archive()
  r <- ar_runs("roster")
  r$t <- trimws(r$text)
  hdr <- r$t[seq_len(4)]
  expect_equal(hdr, AR_COLUMNS)
  expect_true(all(diff(r$x[seq_len(4)]) > 0))
})

test_that("ARKANSAS'S OWN TOTAL HEADER NAMES PACT FIRST -- the trap", {
  skip_without_archive()
  # The total column is labelled "YR1 PACT/THRIVE Total" while the columns
  # beside it run THRIVE then PACT. A reader taking the total column's LABEL
  # as the column order inverts the two, and both inversions reconcile at the
  # row level because a + b = b + a.
  expect_true(AR_TOTAL_HEADER_NAMES_PACT_FIRST %in% AR_COLUMNS)
  expect_match(AR_TOTAL_HEADER_NAMES_PACT_FIRST, "PACT/THRIVE")
  a <- ar_roster_parts()$awards
  expect_true(all(abs(a$pact + a$thrive - a$total) < 0.005))
})

test_that("the COLUMN TOTALS are what tell THRIVE from PACT", {
  skip_without_archive()
  a <- ar_roster_parts()$awards
  expect_equal(round(sum(a$thrive), 2), AR_TOTAL_THRIVE)
  expect_equal(round(sum(a$pact), 2), AR_TOTAL_PACT)
  # And the swap does NOT reconcile, which is the whole point: the row
  # identity survives an inversion and the column totals do not.
  expect_false(abs(sum(a$pact) - AR_TOTAL_THRIVE) < 0.005)
  expect_true(ar_assert_reconciles())
})

test_that("the Governor names each initiative's total separately -- the third reading", {
  skip_without_archive()
  gov <- ar_html_text("governor")
  expect_true(grepl(AR_GOV_THRIVE_QUOTE, gov, fixed = TRUE))
  expect_true(grepl(AR_GOV_PACT_QUOTE, gov, fixed = TRUE))
  expect_true(grepl(AR_GOV_HEADLINE_QUOTE, gov, fixed = TRUE))
  # $55.7M against THRIVE and $93.6M against PACT, rounding the award list's
  # two column totals -- a SECOND publisher pinning the column assignment.
  expect_equal(round(AR_TOTAL_THRIVE / 1e6, 1), 55.7)
  expect_equal(round(AR_TOTAL_PACT / 1e6, 1), 93.5)
})


# -- (4) two publishers, two grains, reconciling to the cent -----------------

test_that("the Governor's release names exactly 50 priced projects, 25 and 25", {
  skip_without_archive()
  p <- ar_projects()
  expect_equal(nrow(p), AR_PROJECT_COUNT)
  expect_equal(sort(as.integer(table(p$pool))), c(25L, 25L))
  expect_true(all(!is.na(p$amount)))
  expect_true(all(p$amount > 0))
  expect_true(grepl("The 50 project awards", ar_html_text("governor"),
                    fixed = TRUE))
})

test_that("the 50 projects reconcile to the award list on all three figures", {
  skip_without_archive()
  p <- ar_projects_joined()
  expect_equal(round(sum(p$amount[p$pool == "THRIVE"]), 2), AR_TOTAL_THRIVE)
  expect_equal(round(sum(p$amount[p$pool == "PACT"]), 2), AR_TOTAL_PACT)
  expect_equal(round(sum(p$amount), 2), AR_TOTAL_YR1)
  expect_true(ar_assert_projects_reconcile())
})

test_that("the naive amount pattern DROPS ONE OF THE FIFTY, in silence", {
  skip_without_archive()
  nodes <- ar_html_nodes("governor")
  flat <- stringr::str_squish(paste(nodes, collapse = " "))
  naive <- stringr::str_count(flat, AR_NAIVE_AMOUNT_RE)
  # 49 of 50: one amount is painted as "$" and "1,455,689.00" in two nodes.
  expect_equal(naive, AR_PROJECT_COUNT - 1L)
  # The consequence, stated in dollars: the sums would miss by exactly that
  # amount and nothing would point at the row.
  p <- ar_projects()
  expect_equal(round(sum(p$amount) - AR_SPLIT_NODE_AMOUNT, 2),
               round(AR_TOTAL_YR1 - AR_SPLIT_NODE_AMOUNT, 2))
  expect_true(ar_assert_split_amount_node())
})

test_that("the tolerant pattern recovers the split-node amount", {
  skip_without_archive()
  p <- ar_projects()
  arhp <- p$amount[p$awardee_as_published == AR_SPLIT_NODE_ORG]
  expect_true(any(abs(arhp - AR_SPLIT_NODE_AMOUNT) < 0.005))
})


# -- (5) seven spellings, and one that classifies differently ----------------

test_that("the spelling map is a FIXED hand-read table, not a matcher", {
  expect_type(AR_RELEASE_SPELLINGS, "character")
  expect_true(length(AR_RELEASE_SPELLINGS) >= 7L)
  expect_true(all(nzchar(names(AR_RELEASE_SPELLINGS))))
  # Every key is a literal, so nothing here can match a name it was not
  # written for (§2 forbids a machine auto-resolving a hospital name).
  expect_false(any(stringr::str_detect(names(AR_RELEASE_SPELLINGS),
                                       "[\\[\\]\\(\\)\\*\\+\\?\\^\\$\\|]")))
})

test_that("after the map the two publishers name the SAME 31 organisations", {
  skip_without_archive()
  p <- ar_projects_joined()
  listed <- ar_roster_parts()$awards$label
  expect_equal(sort(unique(p$awardee)), sort(listed))
  expect_true(ar_assert_release_spellings())
})

test_that("every recorded spelling still occurs in the release", {
  skip_without_archive()
  p <- ar_projects()
  expect_true(all(names(AR_RELEASE_SPELLINGS) %in% p$awardee_as_published))
})

test_that("the two publishers use DIFFERENT APOSTROPHES, which is why the join needs a map", {
  skip_without_archive()
  # The award list prints U+0027 and the release prints U+2019, so the join
  # fails on every apostrophe-bearing name for a reason invisible in either
  # document. Session 34's curly-apostrophe finding, load-bearing here.
  listed <- ar_roster_parts()$awards$label
  expect_true(any(stringr::str_detect(listed, "'")))
  expect_false(any(stringr::str_detect(listed, "’")))
  pub <- ar_projects()$awardee_as_published
  expect_true(any(stringr::str_detect(pub, "’")))
  expect_false(any(stringr::str_detect(pub, "'")))
})

test_that("THE TWO SPELLINGS OF ONE ORGANISATION CLASSIFY DIFFERENTLY, worth $301,400", {
  skip_without_archive()
  cls <- rhtp_classify_recipient_type(unname(AR_TWO_SPELLINGS), AR_STATE)
  fl <- rhtp_classify_flow(cls$recipient_type, rep(NA_character_, 2L))
  expect_equal(cls$recipient_type[1], "HOSPITAL_OR_SYSTEM")
  expect_equal(fl$distributed_to_hospital[1], "Yes")
  expect_equal(fl$distributed_to_hospital[2], "No")
  expect_true(ar_assert_two_spellings_classify_differently())

  # And the dollar it moves. North Carolina's UNC divergence moved a CODING at
  # $0; Arkansas's moves $301,400 of named-hospital money.
  rows <- ar_award_rows()
  ach <- rows[rows$awardee == AR_TWO_SPELLINGS[["award_list"]], ]
  expect_equal(nrow(ach), 1L)
  expect_equal(round(sum(ach$amount), 2), 301400.00)
  expect_equal(ach$distributed_to_hospital, "Yes")
})

test_that("the award rows carry the AWARD LIST's spelling, not the release's", {
  skip_without_archive()
  rows <- ar_award_rows()
  expect_true(AR_TWO_SPELLINGS[["award_list"]] %in% rows$awardee)
  expect_false(AR_TWO_SPELLINGS[["release"]] %in% rows$awardee)
  # And the projects file records BOTH, so neither machine answer is lost.
  proj <- ar_project_rows()
  expect_true(all(c("awardee", "awardee_as_published",
                    "recipient_type_from_release_spelling") %in% names(proj)))
  expect_equal(sum(proj$spelling_differs), 10L)
})


# -- (6) the hospital figure, and what was NOT promoted ----------------------

test_that("the award file is 37 rows and sums to Arkansas's published total", {
  skip_without_archive()
  rows <- ar_award_rows()
  expect_equal(nrow(rows), AR_ACTION_COUNT)
  expect_equal(dplyr::n_distinct(rows$awardee), AR_ORG_COUNT)
  expect_equal(round(sum(rows$amount), 2), AR_TOTAL_YR1)
  # Six organisations hold an award under BOTH initiatives, which is why 31
  # organisations are 37 award actions.
  expect_equal(AR_ACTION_COUNT - AR_ORG_COUNT, 6L)
})

test_that("summing organisation_award_total down the column double-counts", {
  skip_without_archive()
  rows <- ar_award_rows()
  naive <- sum(rows$organisation_award_total)
  expect_gt(naive, AR_TOTAL_YR1)
  # Georgia's trap, in dollars: $250,274,844.36 for a state that awarded
  # $149,177,618.45 -- and above the allotment, so it is at least loud.
  expect_equal(round(naive, 2), 250274844.36)
  expect_gt(naive, AR_ALLOTMENT)
  expect_true(ar_assert_organisation_total_not_summable(rows))
  r <- ar_reconcile(rows)
  expect_equal(round(r$value[r$quantity == "sum(amount)"], 2), AR_TOTAL_YR1)
})

test_that("the named-hospital floor is 9 rows / $21,792,687.96", {
  skip_without_archive()
  rows <- ar_award_rows()
  part <- rhtp_hospital_dollar_partition(rows)
  named <- part[part$bucket == "NAMED_HOSPITAL", ]
  expect_equal(named$rows, 9L)
  expect_equal(round(named$dollars, 2), 21792687.96)
  # No pooled bucket: Arkansas awards no pass-through this file can resolve.
  expect_false("POOL_NAMED_HOSPITALS" %in% part$bucket)
  expect_false("POOL_UNNAMED_HOSPITALS" %in% part$bucket)
})

test_that("NOTHING WAS PROMOTED, and these are the five names that invite it", {
  skip_without_archive()
  rows <- ar_award_rows()
  for (nm in AR_NOT_PROMOTED) {
    got <- rows[rows$awardee == nm, ]
    expect_gt(nrow(got), 0L)
    expect_true(all(got$distributed_to_hospital == "No"), info = nm)
    expect_true(all(got$recipient_type == "NONPROFIT_CBO"), info = nm)
    expect_true(all(got$determination_confidence == "LOW"), info = nm)
    expect_true(all(grepl("RECIPIENT_TYPE_INFERRED", got$flag_reason)),
                info = nm)
  }
  expect_true(ar_assert_nothing_promoted(rows))
})

test_that("promoting the five would move $89,106,022 -- driven, not described", {
  skip_without_archive()
  rows <- ar_award_rows()
  hit <- rows$awardee %in% AR_NOT_PROMOTED
  moved <- sum(rows$amount[hit])
  expect_equal(round(moved, 2), 89106021.91)
  # Four of the six largest awards in the state are inside that set.
  by_org <- rows %>%
    dplyr::distinct(.data$awardee, .data$organisation_award_total) %>%
    dplyr::arrange(dplyr::desc(.data$organisation_award_total))
  expect_equal(sum(by_org$awardee[1:6] %in% AR_NOT_PROMOTED), 5L)
})

test_that("the unstated-form question is 16 organisations / $100,723,693.49, one-directional", {
  skip_without_archive()
  rows <- ar_award_rows()
  fb <- rows[rows$recipient_type == "NONPROFIT_CBO" &
               rows$determination_confidence == "LOW", ]
  orgs <- dplyr::distinct(fb, .data$awardee, .data$organisation_award_total)
  expect_equal(nrow(orgs), 16L)
  expect_equal(nrow(fb), 21L)
  expect_equal(round(sum(orgs$organisation_award_total), 2), 100723693.49)
  expect_true(all(fb$distributed_to_hospital == "No"))
  # A genuine floor and a genuine ceiling, as Oklahoma's and Michigan's are.
  expect_equal(round(21792687.96 + 100723693.49, 2), 122516381.45)
  expect_true(ar_assert_form_not_stated_queued(rows))
})

test_that("both Arkansas questions are in the review queue and OPEN", {
  q <- readr::read_csv(
    here::here("data", "reference", "classification_review_queue.csv"),
    show_col_types = FALSE, progress = FALSE)
  ar <- q[q$state == "AR", ]
  expect_equal(nrow(ar), 2L)
  expect_setequal(ar$question_id,
                  c("AR_RECIPIENT_FORM_NOT_STATED", "AR_ARHP_CONSORTIUM_FLOW"))
  expect_true(all(ar$queue_status == "OPEN"))
  expect_true(all(nzchar(ar$dollar_effect)))
  expect_true(all(nzchar(ar$why_it_is_open)))
  # The consortium question is a FLOW question, not §8 typing, and its row
  # says so -- which is what keeps it from being folded into the other.
  arhp <- ar[ar$question_id == "AR_ARHP_CONSORTIUM_FLOW", ]
  expect_true(grepl("10.2", arhp$question, fixed = TRUE))
  expect_true(grepl("18,833,521", arhp$dollar_effect, fixed = TRUE))
})

test_that("the consortium row is flagged and in NEITHER bucket", {
  skip_without_archive()
  rows <- ar_award_rows()
  got <- rows[rows$awardee == AR_CONSORTIUM, ]
  expect_equal(nrow(got), 2L)
  expect_true(all(grepl("FLOW_UNRESOLVED_HOSPITAL_AFFILIATED",
                        got$flag_reason)))
  expect_true(all(got$distributed_to_hospital == "No"))
  expect_equal(round(sum(got$amount), 2), 18833521.00)
  expect_true(all(grepl("HOSPITAL CONSORTIUM", got$note, fixed = TRUE)))
})


# -- the descriptions, and the measurement that they move no dollar ----------

test_that("reading the project descriptions moves 11 rows and NO dollar", {
  skip_without_archive()
  p <- ar_projects_joined()
  cls <- rhtp_classify_recipient_type(p$awardee, AR_STATE)
  f_na <- rhtp_classify_flow(cls$recipient_type, rep(NA_character_, nrow(p)))
  f_d  <- rhtp_classify_flow(cls$recipient_type, p$project_description)
  changed <- f_na$flow_type != f_d$flow_type
  expect_equal(sum(changed), 11L)
  # Every one of the eleven moves NON_HOSPITAL -> IN_KIND_BENEFIT, which §10.2
  # keeps OUT of a hospital total by construction.
  expect_true(all(f_na$flow_type[changed] == "NON_HOSPITAL"))
  expect_true(all(f_d$flow_type[changed] == "IN_KIND_BENEFIT"))
  expect_equal(sum(p$amount[f_na$distributed_to_hospital == "Yes"]),
               sum(p$amount[f_d$distributed_to_hospital == "Yes"]))
})

test_that("the projects file records the flow reading WITH the descriptions", {
  skip_without_archive()
  proj <- ar_project_rows()
  expect_equal(nrow(proj), AR_PROJECT_COUNT)
  expect_true(any(proj$flow_type == "IN_KIND_BENEFIT"))
  expect_true(any(proj$hospital_benefiting == "Yes"))
  expect_true(all(nzchar(proj$project_description)))
  expect_equal(proj$validation_source_type[1], "GOVERNOR_PRESS_RELEASE")
  # And it says in every row that it is the same money as the award file.
  expect_true(all(grepl("NEVER ADD THE TWO FILES", proj$note, fixed = TRUE)))
})


# -- §6.2 provenance ---------------------------------------------------------

test_that("each NOFO ties ITS OWN initiative to RHTP, by agency and authority", {
  skip_without_archive()
  expect_true(ar_assert_programme_provenance())
})

test_that("the CMS footer is the WEAK form and its amount is THE ALLOTMENT", {
  skip_without_archive()
  expect_match(AR_FOOTER_SUBJECT, "^This project is supported by")
  expect_equal(AR_FOOTER_AMOUNT, 208779396.02)
  # §0.2's machine rule: declared STATE_ALLOTMENT, and it collides with the
  # §7.1 anchor, which is the only thing that makes a Tier 1 reading knowable.
  expect_true(abs(AR_FOOTER_AMOUNT - AR_ALLOTMENT) <=
                RHTP_FOOTER_ALLOTMENT_MARGIN)
  expect_true(rhtp_assert_footer_not_allotment(
    AR_FOOTER_AMOUNT, "AR", "STATE_ALLOTMENT", label = "the AR footer"))
  # Declared a POOL it is REFUSED, which is the half of session 37's rule that
  # would have caught a careless reading of this state.
  expect_error(
    rhtp_assert_footer_not_allotment(AR_FOOTER_AMOUNT, "AR", "SOLICITATION",
                                     label = "the AR footer"),
    "almost certainly Tier 1")
  expect_true(ar_assert_footer_is_the_allotment())
})

test_that("THE FOOTER SITS ON TWO INITIATIVES THAT HAVE AWARDED NOTHING", {
  skip_without_archive()
  # Session 26's Nevada lesson, measured on Arkansas's own estate rather than
  # cited: a check keyed on "does this page carry the CMS footer" answers YES
  # for RISE and HEART, which have named nobody.
  for (k in c("rise", "heart")) {
    expect_true(grepl(AR_FOOTER_SUBJECT, ar_html_text(k), fixed = TRUE),
                info = k)
  }
})

test_that("the AWARD LIST ITSELF carries no CMS footer at all", {
  skip_without_archive()
  txt <- ar_pdf_flat("roster")
  expect_false(grepl("Centers for Medicare", txt, fixed = TRUE))
  expect_false(grepl("Rural Health Transformation", txt, fixed = TRUE))
  expect_false(grepl("RHTP", txt, fixed = TRUE))
  expect_true(ar_assert_roster_has_no_footer())
  # So the footer could not have carried this state's provenance even if it
  # were the strong form -- Maine's shape.
})

test_that("the footer is NON-STRICT, and strict is available", {
  skip_without_archive()
  expect_true(ar_assert_footer_is_the_allotment(strict = TRUE))
  # Kansas's demotion: a re-post that dropped the boilerplate reports and
  # returns NA rather than hard-failing the state.
  expect_true(is.function(ar_assert_footer_is_the_allotment))
})

test_that("every Arkansas RHTP date postdates the 2025-12-29 Notice of Award", {
  skip_without_archive()
  expect_true(all(as.Date(AR_INITIATIVES$nofo_open) > AR_NOA_DATE))
  expect_true(all(as.Date(AR_INITIATIVES$nofo_close) > AR_NOA_DATE))
  expect_true(AR_ANNOUNCE_DATE > AR_NOA_DATE)
  expect_true(ar_assert_after_noa())
})


# -- positive controls -------------------------------------------------------

test_that("the home page's award-list link is the positive control", {
  skip_without_archive()
  home <- ar_html_text("home")
  expect_equal(stringr::str_count(home, stringr::fixed(AR_ROSTER_LINK_TEXT)),
               1L)
  expect_true(ar_assert_award_index())
})

test_that("a SECOND award-list link fails the build", {
  skip_without_archive()
  # Driven: the day RISE AR or HEART publishes a roster, this file must be
  # REWRITTEN and not patched, because its 37 rows are two initiatives of four.
  # Injected INSIDE the body: content after </html> is discarded by the
  # parser, so appending to the end of the file proves nothing.
  faked <- stringr::str_replace(
    ar_read_text("home"), stringr::fixed("</body>"),
    paste0("<p>", AR_ROSTER_LINK_TEXT, " for HEART</p></body>"))
  expect_error(ar_assert_award_index(html = faked), "SECOND roster")
})

test_that("losing the award-list link also fails, in the other direction", {
  skip_without_archive()
  gone <- stringr::str_replace_all(ar_read_text("home"),
                                   stringr::fixed(AR_ROSTER_LINK_TEXT),
                                   "Download the county map")
  expect_error(ar_assert_award_index(html = gone), "positive control")
})

test_that("ALL FOUR initiative pages read the same, awarded or not", {
  skip_without_archive()
  for (k in c("thrive", "pact", "rise", "heart")) {
    expect_true(grepl(AR_INITIATIVE_BOILERPLATE, ar_html_text(k), fixed = TRUE),
                info = k)
  }
  expect_true(ar_assert_initiative_pages_cannot_tell())
  # THRIVE and PACT carry that forward-looking sentence and have awarded
  # $149,177,618.45 between them, which is why the probe does not read these
  # pages for award status.
  expect_equal(round(sum(AR_INITIATIVES$awarded_total, na.rm = TRUE), 2),
               AR_TOTAL_YR1)
})

test_that("RISE AR and HEART have closed, name nobody, and publish no award date", {
  skip_without_archive()
  pending <- AR_INITIATIVES[!AR_INITIATIVES$awarded, ]
  expect_equal(nrow(pending), 2L)
  expect_setequal(pending$pool, c("RISE AR", "HEART"))
  expect_true(all(as.Date(pending$nofo_close) < Sys.Date()))
  for (k in c("rise", "heart")) {
    txt <- ar_html_text(k)
    for (m in c("Notice of Intent to Award", "grant recipients are",
                "has been awarded")) {
      expect_false(grepl(m, txt, fixed = TRUE), info = paste(k, m))
    }
  }
  expect_true(ar_assert_two_initiatives_remain())
})

test_that("what dates the wait is CMS's obligation deadline, from the NOFOs", {
  skip_without_archive()
  expect_equal(AR_OBLIGATION_DATE, as.Date("2026-10-30"))
  for (k in c("nofo_rise", "nofo_heart")) {
    sq <- stringr::str_remove_all(ar_pdf_flat(k), "[^A-Za-z0-9]")
    expect_true(grepl(stringr::str_remove_all(AR_OBLIGATION_QUOTE,
                                              "[^A-Za-z0-9]"), sq,
                      fixed = TRUE), info = k)
  }
})

test_that("the eligible class is HOSPITALS AMONG OTHERS -- recorded before RISE/HEART land", {
  skip_without_archive()
  expect_true(ar_assert_eligible_class())
  # New Hampshire's FHC class, not Illinois's ICAHN class, so §0.3 governs any
  # Arkansas pass-through when RISE and HEART award.
  sq <- stringr::str_remove_all(ar_pdf_flat("nofo_thrive"), "[^A-Za-z0-9]")
  expect_true(grepl(stringr::str_remove_all(AR_ELIGIBLE_CLASS_QUOTE,
                                            "[^A-Za-z0-9]"), sq, fixed = TRUE))
})

test_that("this is a PARTIAL YEAR and Arkansas says so itself", {
  skip_without_archive()
  expect_lt(AR_TOTAL_YR1, AR_ALLOTMENT)
  expect_equal(round(100 * AR_TOTAL_YR1 / AR_ALLOTMENT, 1), 71.5)
  expect_true(grepl("the $209 million the state expects to award by this fall",
                    ar_html_text("governor"), fixed = TRUE))
  expect_true(ar_assert_partial_year())
})


# -- the digest mechanism, synthesised offline -------------------------------

test_that("the WordPress render-timestamp token moves the FILE digest and not the CONTENT digest", {
  skip_without_archive()
  # THE EIGHTH ROTATING-DIGEST MECHANISM IN THIS PROJECT, and the one that most
  # sharply repeats session 34's California lesson: the token is derived from
  # the RENDER TIMESTAMP, so two fetches inside one cache window are
  # GUARANTEED byte-identical and two across windows are GUARANTEED to differ
  # -- at exactly the same byte length, because it is a fixed 13 hex
  # characters. A back-to-back pair cannot see it and a byte-count check
  # cannot either.
  live <- ar_read_text("home")
  expect_true(grepl("wp_block_styles_on_demand_placeholder", live, fixed = TRUE))
  rolled <- stringr::str_replace(
    live, "wp_block_styles_on_demand_placeholder:[0-9a-f]{13}",
    "wp_block_styles_on_demand_placeholder:6a99ffffffff0")
  expect_equal(nchar(rolled), nchar(live))                      # same length
  expect_false(identical(digest::digest(rolled, algo = "sha256"),
                         digest::digest(live, algo = "sha256"))) # file MOVES
  expect_equal(ar_content_digest("home", rolled),
               ar_content_digest("home", live))                  # content SAME
})

test_that("the reduction discards <style> bodies, which is what absorbs it", {
  skip_without_archive()
  red <- ar_html_text("home")
  expect_false(grepl("wp_block_styles_on_demand_placeholder", red, fixed = TRUE))
  expect_false(grepl("wp-block-library-inline-css", red, fixed = TRUE))
  # And the reduction still carries the thing the control reads.
  expect_true(grepl(AR_ROSTER_LINK_TEXT, red, fixed = TRUE))
})


# -- the committed artifacts -------------------------------------------------

test_that("the four committed CSVs are on disk and are what this file builds", {
  expect_true(file.exists(AR_OUT_CSV))
  expect_true(file.exists(AR_PROJECTS_CSV))
  expect_true(file.exists(AR_STATUS_CSV))
  expect_true(file.exists(AR_DISPOSITION_CSV))
  a <- readr::read_csv(AR_OUT_CSV, show_col_types = FALSE, progress = FALSE)
  expect_equal(nrow(a), AR_ACTION_COUNT)
  expect_equal(round(sum(a$amount), 2), AR_TOTAL_YR1)
  p <- readr::read_csv(AR_PROJECTS_CSV, show_col_types = FALSE, progress = FALSE)
  expect_equal(nrow(p), AR_PROJECT_COUNT)
  expect_equal(round(sum(p$amount), 2), AR_TOTAL_YR1)
})

test_that("the status table has FOUR initiatives and NO `amount` column", {
  st <- readr::read_csv(AR_STATUS_CSV, show_col_types = FALSE, progress = FALSE)
  expect_equal(nrow(st), 4L)
  expect_false("amount" %in% names(st))
  expect_true("initiative_awarded_total" %in% names(st))
  expect_equal(sum(st$stage == "AWARDED_ROSTER_PUBLISHED"), 2L)
  expect_equal(sum(st$stage == "CLOSED_NO_AWARD_DATE_PUBLISHED"), 2L)
  expect_true(all(st$award_date_published == "No"))
})

test_that("Arkansas holds ZERO RCJ Tier 3 candidates, and that is about RCJ", {
  d <- readr::read_csv(AR_DISPOSITION_CSV, show_col_types = FALSE,
                       progress = FALSE)
  expect_equal(nrow(d), 1L)
  expect_equal(d$rcj_rows, 0L)
  expect_equal(d$disposition, "NOT_IN_THE_AGGREGATOR_AT_ALL")
  expect_true(grepl("NEITHER", d$evidence, fixed = TRUE))
  expect_true(grepl("DISCOVERY LAYER", d$evidence, fixed = TRUE))
})

test_that("Arkansas reads EXTRACTED in both rebuilt survey tables", {
  s <- readr::read_csv(here::here("data", "reference", "rcj_state_survey.csv"),
                       show_col_types = FALSE, progress = FALSE)
  q <- readr::read_csv(here::here("data", "reference",
                                  "state_trigger_queue.csv"),
                       show_col_types = FALSE, progress = FALSE)
  expect_equal(s$extraction_status[s$state == "AR"], "EXTRACTED")
  expect_equal(q$extraction_status[q$state == "AR"], "EXTRACTED")
  # And it is still `NEITHER` on both discovery layers, which is the finding:
  # Florida's shape a third time.
  expect_equal(s$survey_status[s$state == "AR"], "NEITHER")
  expect_equal(q$trigger_source[q$state == "AR"], "NEITHER")
  expect_equal(s$tier3_candidates[s$state == "AR"], 0L)
})

test_that("the evidence manifest lists every archived file and verifies", {
  skip_without_archive()
  man <- file.path(AR_EVIDENCE_DIR, "MANIFEST.txt")
  expect_true(file.exists(man))
  txt <- readLines(man, warn = FALSE)
  listed <- stringr::str_match(txt, "^(\\S+\\.(?:pdf|html))\\s+\\d+\\s+([0-9a-f]{64})$")
  listed <- listed[!is.na(listed[, 1]), , drop = FALSE]
  expect_equal(nrow(listed), nrow(AR_SOURCES))
  expect_false("MANIFEST.txt" %in% listed[, 2])
  for (i in seq_len(nrow(listed))) {
    f <- file.path(AR_EVIDENCE_DIR, listed[i, 2])
    expect_true(file.exists(f), info = listed[i, 2])
    expect_equal(digest::digest(file = f, algo = "sha256"), listed[i, 3],
                 info = listed[i, 2])
  }
  # And the on-disk set equals the listed set (session 15's manifest defect).
  on_disk <- setdiff(list.files(AR_EVIDENCE_DIR), "MANIFEST.txt")
  expect_setequal(on_disk, listed[, 2])
})

test_that("every award row carries a non-empty, non-contradictory basis", {
  skip_without_archive()
  rows <- ar_award_rows()
  expect_true(all(nzchar(rows$determination_basis)))
  expect_true(all(nzchar(rows$amount_basis)))
  expect_true(all(nzchar(rows$recipient_type_source)))
  # No row claims §10.2 DIRECT while coding something else (session 31's
  # Oregon/Nevada repair, as an invariant).
  wrong <- grepl("DIRECT", rows$determination_basis, fixed = TRUE) &
    rows$flow_type != "DIRECT"
  expect_equal(sum(wrong), 0L)
})

test_that("every row is an INTENT and no amount is confirmed", {
  skip_without_archive()
  rows <- ar_award_rows()
  expect_true(all(rows$validation_source_type == "NOTICE_OF_INTENT_TO_AWARD"))
  expect_true(all(rows$amount_confirmed == "No"))
  expect_true(all(rows$recipient_confirmed == "Yes"))
  # AMOUNT_PRELIMINARY is §8's existing code for exactly this -- no new code
  # was invented for Arkansas (§2).
  expect_true(all(grepl("AMOUNT_PRELIMINARY", rows$flag_reason)))
  expect_true("AMOUNT_PRELIMINARY" %in%
                rhtp_vocabulary()$allowed_value[
                  rhtp_vocabulary()$column_name == "flag_reason"])
  # Arkansas's own words, which is why.
  expect_true(grepl(AR_NOT_FINAL_QUOTE, ar_html_text("governor"), fixed = TRUE))
})

test_that("every categorical value is inside §8", {
  skip_without_archive()
  rows <- ar_award_rows()
  vocab <- rhtp_vocabulary()
  # `validation_source_type` is validated against §8's `source_doc_type`
  # vocabulary, which is the list §7 draws its source-strength ordering from.
  vocab_col <- c(validation_source_type = "source_doc_type")
  for (col in c("recipient_type", "distributed_to_hospital",
                "recipient_confirmed", "amount_confirmed",
                "validation_source_type", "flow_type",
                "hospital_attribution", "determination_confidence")) {
    key <- if (col %in% names(vocab_col)) vocab_col[[col]] else col
    allowed <- vocab$allowed_value[vocab$column_name == key]
    got <- unique(stats::na.omit(rows[[col]]))
    expect_true(all(got %in% allowed),
                info = paste(col, ":", paste(setdiff(got, allowed),
                                             collapse = ", ")))
  }
  for (fr in unique(unlist(strsplit(rows$flag_reason, ";")))) {
    expect_true(fr %in% vocab$allowed_value[vocab$column_name == "flag_reason"],
                info = fr)
  }
})
