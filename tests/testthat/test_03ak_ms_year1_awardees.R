# test_03ak_ms_year1_awardees.R ----------------------------------------------
# Mississippi: 167 awards ANNOUNCED, named and priced -- and the first CMS
# footer here that is not 100% federal. Committed files only.
#
# Session 44 wrote this file against a state that had said it was about to
# publish. On 2026-09-14 it did, so the tests that watched for silence are
# replaced by tests that read the roster. The ones carrying the weight now are
# the PARSE tests: Mississippi prints 167 awards as numbered prose and two of
# the rows break the ordinary shape in DIFFERENT ways, only one of which any
# total can see. The footer pair stays, because the headline is still ACCEPTED
# as a Tier 2 pool by the shared rule and is still not one.

library(testthat)

source(here::here("R", "03ak_ms_year1_awardees.R"))

skip_without_archive <- function() {
  if (!ms_have_archive()) skip("the MS evidence archive is not on disk")
}
as_raw_html <- function(txt) charToRaw(enc2utf8(txt))


test_that("the NEXT tranche has not been announced", {
  skip_without_archive()
  expect_true(ms_assert_remaining_tranches())
})

test_that("the tranche tripwire fires on award language for WEI or EmPATH", {
  skip_without_archive()
  # The 167 are RECORDED, so what is watched now is the second tranche the
  # release itself dates: Workforce Expansion and Psychiatric Emergency
  # Services, "announced in the next 30 to 45 days".
  for (p in c("Workforce Expansion Initiative awardees are",
              "EmPATH units selected for award",
              "Psychiatric Emergency Services award recipients")) {
    expect_error(
      ms_assert_remaining_tranches(bodies = list(
        funding = as_raw_html(paste("<html><body>", p, "</body></html>")),
        home = as_raw_html("<html></html>"),
        gov_newsroom = as_raw_html("<html></html>"))),
      "AWARD language", info = p)
  }
})

test_that("the tranche tripwire does NOT fire on the 167 already recorded", {
  skip_without_archive()
  # A tripwire that fires every run stops being read (session 29). The
  # Governor's own 167-award headline is on the watched newsroom page, and it
  # must not re-fire: it is the finding, not a new one.
  expect_true(ms_assert_remaining_tranches())
  expect_match(ms_html_text("gov_newsroom"), "Announces 167 Rural Health")
})

test_that("the announcement is on the channel Mississippi itself named", {
  skip_without_archive()
  expect_true(ms_assert_announcement_on_channel())
  expect_error(
    ms_assert_announcement_on_channel(
      body = as_raw_html("<html><body>nothing here</body></html>")),
    "no longer carries the 167-award announcement")
})


# -- THE ROSTER --------------------------------------------------------------

test_that("167 awards parse, in three pools of 97 / 43 / 27", {
  skip_without_archive()
  d <- ms_parse_release()
  expect_equal(nrow(d), 167L)
  expect_equal(as.integer(table(d$pool)[MS_POOLS$pool]), MS_POOLS$n)
  expect_true(ms_assert_reconciles(d))
})

test_that("the 167 sum to $104,115,146.80 against a stated $104,115,146", {
  skip_without_archive()
  d <- ms_parse_release()
  # The $0.80 is TRUNCATION, not a discrepancy: nine rows carry cents and
  # those cents sum to $3.80. Rounding would have given $104,115,147.
  expect_equal(sum(d$amount), 104115146.80)
  expect_equal(sum(d$amount) - MS_RELEASE_TOTAL, 0.80)
  expect_equal(sum(d$amount %% 1), 3.80)
  expect_equal(sum(round(d$amount %% 1, 2) > 0), 9L)
})

test_that("A ' - ' SPLIT DROPS ROW 23 AND $2,500,000, AND THE TOTAL CATCHES IT", {
  skip_without_archive()
  # The first odd shape: "Lee County-" with no space before the hyphen, so the
  # row carries two separators where its siblings carry three. Driven in the
  # order a reader makes the mistake.
  lines <- stringr::str_split(ms_html_text("release"), "\n")[[1]]
  numbered <- grep("^\\d+\\. ", lines, value = TRUE)
  naive <- numbered[stringr::str_count(numbered, stringr::fixed(" - ")) == 3L]
  expect_equal(length(naive), 165L)      # 167 minus the two odd shapes
  dropped <- setdiff(numbered, naive)
  expect_true(any(grepl("Lee County-", dropped, fixed = TRUE)))
  # And what dropping it costs.
  d <- ms_parse_release()
  odd <- d[d$awardee == "North Mississippi Medical Center, Inc.", ]
  expect_equal(odd$amount, 2500000)
  expect_equal(sum(d$amount) - odd$amount, 101615146.80)
})

test_that("A ' - ' SPLIT MIS-NAMES ROW 30 AND NO TOTAL EVER NOTICES", {
  skip_without_archive()
  # The second odd shape, and the sharper one: the ORGANISATION'S legal name
  # contains " - ", so a left-to-right split reads the awardee as "Northeast
  # Mental Health" and the COUNTY as "Mental Retardation Commission d.b.a.
  # LIFECORE Health Group". The MONEY is untouched, so the row count is still
  # 167 and every total still reconciles to the cent.
  d <- ms_parse_release()
  odd <- d[d$pool == "Rural Capital Project Care Gap Closure (RCGC)" &
             grepl("LIFECORE", d$awardee), ]
  expect_equal(nrow(odd), 1L)
  expect_equal(odd$county, "Monroe County")
  expect_equal(odd$amount, 27600)
  expect_match(odd$awardee, "^Northeast Mental Health - Mental Retardation")
  # What the naive split would have produced, and why no arithmetic sees it.
  parts <- stringr::str_split(odd$awardee, stringr::fixed(" - "))[[1]]
  expect_equal(parts[1], "Northeast Mental Health")
  expect_match(parts[2], "^Mental Retardation Commission")
  expect_false(grepl("County", parts[2]))
})

test_that("LIFECORE holds TWO awards under TWO spellings, and they are NOT merged", {
  skip_without_archive()
  d <- ms_parse_release()
  lc <- d[grepl("LIFECORE", d$awardee), ]
  expect_equal(nrow(lc), 2L)
  expect_equal(sort(lc$amount), c(27600, 30610))
  expect_equal(dplyr::n_distinct(lc$awardee), 2L)   # §2 forbids merging them
})

test_that("a full-word 'County' anchor silently drops Lafayette Co.", {
  skip_without_archive()
  d <- ms_parse_release()
  abbrev <- d[grepl("Co\\.$", d$county), ]
  expect_equal(nrow(abbrev), 1L)
  expect_equal(abbrev$county, "Lafayette Co.")
  expect_equal(abbrev$amount, 300000)
  expect_true(ms_assert_odd_shape_rows(d))
})

test_that("an unparseable numbered line is REFUSED, not skipped", {
  skip_without_archive()
  # Dropping it is exactly how row 23 would cost $2,500,000 in silence.
  # The headings must land on their own LINES after reduction, as they do on
  # the real page, or the parser refuses for the other reason.
  expect_error(
    ms_parse_release(body = as_raw_html(paste0(
      "<html><body>\n", MS_POOLS$heading[1],
      "\n1. Something With No County And No Amount\n",
      MS_POOLS$heading[2], "\n", MS_POOLS$heading[3],
      "\nNotice of Funding Opportunities\n</body></html>"))),
    "did not parse")
})

test_that("the three section headings are required, and in order", {
  skip_without_archive()
  expect_error(
    ms_parse_release(body = as_raw_html("<html><body>no headings</body></html>")),
    "section headings")
})


# -- the award file ----------------------------------------------------------

test_that("the award file carries 68 named-hospital rows and $47,454,812.18", {
  skip_without_archive()
  d <- ms_year1_awardees()
  part <- rhtp_hospital_dollar_partition(d)
  expect_equal(part$bucket, "NAMED_HOSPITAL")
  expect_equal(part$rows, 68L)
  expect_equal(round(part$dollars, 2), 47454812.18)
})

test_that("NOTHING WAS PROMOTED and the uncertainty is one-directional", {
  skip_without_archive()
  d <- ms_year1_awardees()
  fb <- d[d$flag_reason == "RECIPIENT_TYPE_INFERRED" & !is.na(d$flag_reason), ]
  expect_equal(nrow(fb), 96L)
  expect_true(all(fb$distributed_to_hospital == "No"))
  expect_true(all(fb$recipient_type == "NONPROFIT_CBO"))
  expect_true(all(fb$determination_confidence == "LOW"))
  expect_equal(round(sum(fb$amount), 2), 56022017.62)
  expect_true(ms_assert_nothing_promoted(d))
  expect_true(ms_assert_form_not_stated_queued(d))
})

test_that("the BUILD still has 96 fallback rows and the COMMITTED FILE has 2", {
  skip_without_archive()
  # THE TWO ARE BOTH TRUE AND THEY ARE NOT THE SAME CLAIM. The builder's output
  # is what the Governor's release alone supports: 96 rows whose form the state
  # never states. The committed CSV is that output WITH session 50's typing
  # overlay on it, which determined 94 of them from federal enrolment records
  # and REFUSED two. Reading either number as the other is the mistake this
  # test exists to make hard.
  expect_equal(sum(ms_year1_awardees()$flag_reason == "RECIPIENT_TYPE_INFERRED",
                   na.rm = TRUE), 96L)
  csv <- readr::read_csv(here::here("data/reference/ms_year1_awardees.csv"),
                         show_col_types = FALSE, progress = FALSE,
                         na = character())
  open <- csv$flag_reason != "NA" &
    grepl("RECIPIENT_TYPE_INFERRED", csv$flag_reason)
  expect_equal(sum(open), 2L)
  expect_setequal(csv$awardee[open],
                  c("CAMHP Foundation",
                    "Delta Health Transformation Council, Inc."))
  # And Mississippi's named-hospital figure moved with it: 68 rows /
  # $47,454,812.18 in the build, 84 / $68,898,204.67 committed.
  expect_equal(sum(csv$hospital_attribution == "NAMED_HOSPITAL"), 84L)
  expect_equal(round(sum(as.numeric(
    csv$amount[csv$hospital_attribution == "NAMED_HOSPITAL"])), 2),
    68898204.67)
})

test_that("the descriptions do NOT decide recipient_type (§0.3a)", {
  skip_without_archive()
  # A description describes an ACTIVITY; §0.3a judges the RECIPIENT. Arkansas
  # established this in session 40. The check: every recipient_type must be
  # reproducible from the NAME alone.
  d <- ms_year1_awardees()
  from_name <- purrr::map_chr(
    d$awardee, ~ rhtp_classify_recipient_type(.x, MS_STATE)$recipient_type)
  expect_equal(d$recipient_type, from_name)
})

test_that("one row per AWARD ACTION, not per organisation", {
  skip_without_archive()
  d <- ms_year1_awardees()
  expect_equal(nrow(d), 167L)
  expect_lt(dplyr::n_distinct(d$awardee), nrow(d))
  expect_equal(dplyr::n_distinct(d$awardee), 103L)
  # Memorial Health System alone holds twelve.
  expect_equal(sum(d$awardee == "Memorial Health System"), 12L)
})

test_that("§6.2 passes on the CMS SHARE, never the headline", {
  skip_without_archive()
  got <- ms_assert_release_provenance()
  expect_equal(got$cms_share, MS_FOOTER_CMS_SHARE)
  expect_true(MS_RELEASE_DATE > MS_NOA_DATE)
})

test_that("the status table still has NO amount column", {
  skip_without_archive()
  expect_false("amount" %in% names(ms_status_table()))
})

test_that("selection is complete and the announcement is promised", {
  skip_without_archive()
  expect_true(ms_assert_selection_complete_unnamed())
  expect_error(
    ms_assert_selection_complete_unnamed(
      body = as_raw_html("<html><body>nothing here</body></html>")),
    "no longer says")
})


# -- §0.2, the reason this file exists ---------------------------------------

test_that("the footer is NOT 100% federal and carries two figures", {
  skip_without_archive()
  f <- ms_assert_footer_is_not_fully_federal()
  expect_false(f$fully_federal)
  expect_equal(f$cms_pct, 99.96)
  expect_equal(f$headline_amount, MS_FOOTER_HEADLINE)
  expect_equal(f$cms_amount, MS_FOOTER_CMS_SHARE)
  expect_equal(f$nonfederal_amount, MS_FOOTER_NONFEDERAL)
})

test_that("the CMS share is the allotment and the headline is not", {
  skip_without_archive()
  expect_true(ms_assert_footer_cms_share_is_the_allotment())
  expect_lt(abs(MS_FOOTER_CMS_SHARE - MS_ALLOTMENT), 1)
  expect_gt(MS_FOOTER_HEADLINE - MS_ALLOTMENT,
            8 * RHTP_FOOTER_ALLOTMENT_MARGIN)
})

test_that("the footer's own arithmetic closes to the cent", {
  skip_without_archive()
  f <- rhtp_footer_parse(ms_html_text("funding"))
  expect_equal(f$headline_amount - f$cms_amount, f$nonfederal_amount)
})

test_that("a 100% restatement would break the finding loudly", {
  skip_without_archive()
  faked <- paste("<html><body>as part of a financial assistance award",
                 "totaling $205,990,180.16 with 100 percent funded by",
                 "CMS/HHS.</body></html>")
  expect_error(ms_assert_footer_is_not_fully_federal(as_raw_html(faked)),
               "now 100% federal")
})


# -- the controls ------------------------------------------------------------

test_that("THE RETIRED CHANNEL CONTROL, and why it halted the Routine", {
  skip_without_archive()
  # It counted "announce"-shaped headlines and required at least three, on the
  # reasoning that a channel demonstrably carrying award announcements is what
  # made Mississippi's RHTP silence Mississippi's rather than our reading.
  #
  # It halted for TWO reasons at once. The newsroom is a "Load More" page
  # whose static HTML carries only its first few items, and by 2026-09-21
  # exactly ONE of them matched "announce" -- so it failed on ordinary
  # pagination, on a threshold that was never measuring what it meant to. And
  # underneath that, the thing it guarded had already happened: the one
  # matching headline WAS Mississippi's own RHTP award announcement, which its
  # second half would have caught had the first half not stopped first.
  txt <- ms_html_text("gov_newsroom")
  lines <- stringr::str_split(txt, "\n")[[1]]
  announce <- lines[grepl("announce", lines, ignore.case = TRUE)]
  expect_lt(length(announce), 3L)
  expect_true(any(grepl("167 Rural Health Transformation", announce)))
})

test_that("the retired control now delegates to the one that names a headline", {
  skip_without_archive()
  # A count of headlines was the wrong instrument either way. What replaced it
  # asserts the ONE headline this file actually depends on, by name, and a
  # name cannot drift with pagination.
  expect_true(suppressWarnings(ms_assert_governor_channel_control()))
  expect_error(
    suppressWarnings(ms_assert_governor_channel_control(
      as_raw_html("<html><body>nothing</body></html>"))),
    "no longer carries the 167-award announcement")
})

test_that("DOM's one RHTP award predates the NOA, and DOM publishes awards", {
  skip_without_archive()
  ctl <- ms_assert_dom_consultant_predates_noa()
  expect_gte(ctl$intents, 5L)
  expect_equal(ctl$days_before_noa, 138L)
  expect_lt(MS_CONSULTANT_AWARDED, MS_NOA_DATE)
})

test_that("the §6.2 sweep already caught the consultant row", {
  # Machine and hand agreeing from two directions, session 20 and session 44.
  f <- readr::read_csv(here::here("data", "reference",
                                  "provenance_sweep_flagged_rows.csv"),
                       show_col_types = FALSE, progress = FALSE)
  horne <- f[f$state == "MS", ]
  expect_equal(nrow(horne), 1L)
  expect_true(any(grepl("Horne", horne$awardee_name_raw, ignore.case = TRUE)))
  expect_true(any(grepl("PREDATES_NOA", horne$new_flags)))
})


# -- the tables --------------------------------------------------------------

test_that("the status table has no amount column AND the award file now exists", {
  st <- ms_status_table()
  # The status table still carries no amount column -- the per-recipient money
  # lives in ms_year1_awardees.csv, and two files claiming one figure is the
  # hazard Texas's device and Arkansas's project file both guard against.
  expect_false("amount" %in% names(st))
  expect_gte(nrow(st), 8L)
  # And the award file is no longer asserted ABSENT. Session 44 required its
  # absence, correctly, of a state that had named nobody; requiring it now
  # would be requiring Mississippi not to have published.
  expect_true(file.exists(here::here("data", "reference",
                                     "ms_year1_awardees.csv")))
  expect_equal(sum(st$stage == "AWARDED_ROSTER_PUBLISHED"), 3L)
})

test_that("the disposition covers every live candidate, re-derived", {
  skip_without_archive()
  # Three rows on the 2026-08-27 pull, none an award. On the 2026-09-24 pull
  # RCJ carries the Governor's roster, so the groups are a reconciliation.
  cands <- ms_rcj_candidates()
  d <- ms_disposition(cands)
  expect_equal(sum(d$rcj_rows), nrow(cands))
  expect_equal(nrow(cands), 173L)
  g <- stats::setNames(d$rcj_rows, d$disposition)
  expect_equal(g[["RHTP_SUBAWARD_IN_FILE"]], 161L)
  expect_equal(g[["RHTP_SUBAWARD_IN_FILE_UNDER_A_CORRUPTED_NAME"]], 6L)
  expect_equal(g[["RHTP_AWARD_DUPLICATED_ACROSS_DOCUMENTS"]], 4L)
  expect_equal(g[["NOT_A_SUBAWARD_PREDATES_NOA"]], 1L)
  expect_equal(g[["NOT_RHTP_STATE_PROCUREMENT"]], 1L)
  # QIPP was WITHDRAWN by RCJ; its row stays so the audit trail closes.
  expect_equal(g[["NOT_RHTP_MEDICAID_AND_A_DOCUMENT_TITLE"]], 0L)
  expect_silent(rhtp_assert_disposition_prose(d, "MS"))
})

test_that("RCJ holds all 167 awards and prices every one correctly", {
  skip_without_archive()
  m <- ms_rcj_match()
  expect_equal(attr(m, "roster_rows_held"), 167L)
  expect_equal(attr(m, "roster_rows"), 167L)
  # Every candidate carrying a roster name is matched at the roster's figure:
  # nothing is left unmatched but the two procurement notices.
  expect_equal(sort(m$awardee_name_raw[is.na(m$match)]),
               c("Horne LLP", "Premier Healthcare Solutions, Inc"))
  # The LIFECORE truncation is the aggregator making this file's own guarded
  # parse defect -- and it is matched only through the hand-read map (§2).
  expect_true("Northeast Mental Health" %in% names(MS_RCJ_NAME_REPAIRS))
})

test_that("a candidate no group describes stops the build", {
  skip_without_archive()
  cands <- ms_rcj_candidates()
  extra <- cands[1, ]
  extra$record_id <- "synthetic"
  extra$awardee_name_raw <- "An Organisation Nobody Has Read"
  extra$amount_announced <- 12345
  expect_error(ms_disposition(dplyr::bind_rows(cands, extra)),
               "fit no group")
})

test_that("Mississippi now contributes 68 rows and $47.5M, and that is new", {
  skip_without_archive()
  # Session 44's version of this test asserted the opposite -- no row and no
  # dollar in any bucket -- and was right about a state that had named nobody.
  d <- ms_year1_awardees()
  part <- rhtp_hospital_dollar_partition(d)
  expect_equal(part$rows, 68L)
  expect_gt(part$dollars, 47e6)
  # THE YEAR IS PARTIAL, and Mississippi dates the rest itself.
  st <- ms_status_table()
  expect_equal(sum(st$stage == "CLOSED_AWARD_DATE_PUBLISHED_PENDING"), 2L)
  expect_lt(sum(d$amount), MS_ALLOTMENT)
})
