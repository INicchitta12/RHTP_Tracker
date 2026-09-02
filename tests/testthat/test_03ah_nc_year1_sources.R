# test_03ah_nc_year1_sources.R ------------------------------------------------
# North Carolina: NOT a negative. Two published rosters, 44 named recipients,
# EXTRACTED in session 38. Committed files only -- no network.
#
# THE TESTS THAT CARRY THE WEIGHT ARE THE ONES GUARDING THE THREE WAYS THIS
# EXTRACTION COULD BE WRONG, and none of them is a parse error. (1) The only
# currency figure beside the five Hub Leads is the WHOLE STATE ALLOTMENT, so a
# careless `round_amount` publishes $213,008,356.47 as five hub awards.
# (2) The MIH pool's $10,000,000 is repeated per row, so summing the column
# gives $390,000,000. (3) The Region 4 Hub Lead appears under two spellings
# that CLASSIFY DIFFERENTLY -- one of them into a named-hospital row -- so a
# tidy-up of the names changes a coding and not merely a count.

library(testthat)

source(here::here("R", "03ah_nc_year1_sources.R"))

skip_without_archive <- function() {
  if (!nc_have_archive()) skip("the NC evidence archive is not on disk")
}

as_raw_html <- function(txt) charToRaw(enc2utf8(txt))


# -- what North Carolina has published ---------------------------------------

test_that("the 39-recipient MIH roster is published and is a POOL figure", {
  skip_without_archive()
  expect_true(nc_assert_mih_roster())
  txt <- stringr::str_replace_all(nc_html_text("pr_mih"), "\\s+", " ")
  expect_true(grepl("$10 million to 39 local EMS agencies", txt, fixed = TRUE))
  expect_true(grepl("The Mobile Integrated Health grant recipients include:",
                    txt, fixed = TRUE))
})

test_that("the roster window is bounded by the roster, not a character count", {
  # THE DEFECT THIS PINS, AND IT FIRED WHILE THE FILE WAS BEING WRITTEN. A
  # fixed-width window ran past the last name into the Stevens Amendment
  # footer, so the "no dollar figure inside the roster" check tripped on the
  # $213,008,356.47 ALLOTMENT -- the very figure 0.2 says must never be read
  # as this round's money -- and it would have tripped on every run.
  skip_without_archive()
  txt <- stringr::str_replace_all(nc_html_text("pr_mih"), "\\s+", " ")
  roster <- stringr::str_extract(
    txt,
    "The Mobile Integrated Health grant recipients include:.*?For more information")
  expect_false(is.na(roster))
  expect_false(grepl("$", roster, fixed = TRUE))
  expect_true(grepl("213,008,356.47", txt, fixed = TRUE))   # it IS on the page
  expect_true(grepl("Yancey County EMS", roster, fixed = TRUE))
})

test_that("Cape Fear Valley is the one hospital-affiliated MIH recipient", {
  skip_without_archive()
  roster <- stringr::str_extract(
    stringr::str_replace_all(nc_html_text("pr_mih"), "\\s+", " "),
    "The Mobile Integrated Health grant recipients include:.*?For more information")
  expect_true(grepl("Cape Fear Valley", roster, fixed = TRUE))

  # THE SPLIT, COUNTED RATHER THAN EYEBALLED. 39 recipients: 37 named
  # "<X> County EMS", one "Clay County" with the suffix dropped (the source's
  # own inconsistency, kept as published per 8), and Cape Fear Valley Mobile
  # Integrated Health -- a health system's MIH programme and the ONLY
  # hospital-affiliated recipient, hence the only 10.2 judgement in the set.
  parts <- stringr::str_extract_all(
    roster,
    "[A-Z][A-Za-z. ]+?(County EMS|County|Mobile Integrated Health \\(MIH\\))")[[1]]
  expect_length(parts, 39L)
  expect_equal(sum(grepl("County EMS$", parts)), 37L)
  expect_setequal(parts[!grepl("County EMS$", parts)],
                  c("Cape Fear Valley Mobile Integrated Health (MIH)",
                    "Clay County"))
})

test_that("a dollar figure appearing inside the roster stops the build", {
  skip_without_archive()
  raw <- readBin(nc_path("pr_mih"), "raw", file.size(nc_path("pr_mih")))
  faked <- sub("Alamance County EMS", "Alamance County EMS $250,000",
               rawToChar(raw), fixed = TRUE)
  expect_error(nc_assert_mih_roster(body = charToRaw(faked)),
               "dollar figure has appeared INSIDE")
})

test_that("the five Hub Leads are named and are FIDUCIARY leads", {
  skip_without_archive()
  expect_true(nc_assert_hub_leads())
  pr <- stringr::str_replace_all(nc_html_text("pr_roots"), "\\s+", " ")
  expect_true(grepl("The NC ROOTS Hub Lead awardees include", pr, fixed = TRUE))
  for (n in NC_HUB_LEADS) expect_true(grepl(n, pr, fixed = TRUE), info = n)
  expect_length(NC_HUB_LEADS, 5L)
})

test_that("losing 'fiduciary' stops the build -- it is what separates NC from MO", {
  # Missouri's Hub Anchors are a governance roster whose own FAQ says they
  # are NOT the fiscal agent, and they contribute $0 and no row. North
  # Carolina's are "programmatic and fiduciary leads". One word decides
  # whether these five are recipients at all.
  skip_without_archive()
  raw <- readBin(nc_path("pr_roots"), "raw", file.size(nc_path("pr_roots")))
  gutted <- gsub("programmatic and fiduciary leads", "conveners",
                 rawToChar(raw), fixed = TRUE)
  expect_error(nc_assert_hub_leads(bodies = list(pr_roots = charToRaw(gutted))),
               "programmatic and fiduciary")
})

test_that("UNC appears under TWO spellings across two documents", {
  # The fuzzy match 2 forbids a machine resolving. Recorded, not merged.
  skip_without_archive()
  pr <- nc_html_text("pr_roots")
  page <- nc_html_text("roots_page")
  expect_true(grepl("University of North Carolina Hospitals", pr, fixed = TRUE))
  expect_true(grepl("UNC Health", page, fixed = TRUE))
})


# -- 0.2: the only figure beside five awardees is the allotment --------------

test_that("the ROOTS page carries the ALLOTMENT and nothing else", {
  skip_without_archive()
  figures <- nc_assert_roots_page_has_no_pool()
  expect_equal(figures, "$213,008,356.47")
})

test_that("that figure is refused as a pool, and the MIH pool is not", {
  skip_without_archive()
  expect_true(nc_assert_footer_is_the_allotment())
  expect_error(
    rhtp_assert_footer_not_allotment(NC_FOOTER, "NC", "SOLICITATION"),
    "almost certainly Tier 1")
  expect_true(
    rhtp_assert_footer_not_allotment(NC_MIH_POOL, "NC", "SOLICITATION"))
})

test_that("per-hub amounts appearing turns this into an extraction", {
  skip_without_archive()
  raw <- readBin(nc_path("roots_page"), "raw", file.size(nc_path("roots_page")))
  faked <- sub("Impact Health", "Impact Health $18,000,000",
               rawToChar(raw), fixed = TRUE)
  expect_error(nc_assert_roots_page_has_no_pool(body = charToRaw(faked)),
               "currency figures other than the allotment")
})


# -- the controls ------------------------------------------------------------

test_that("two opportunities are closed with no roster, both dates passed", {
  skip_without_archive()
  expect_true(nc_assert_positive_control())
  st <- nc_status_table()
  closed <- st[st$stage == "CLOSED_UNAWARDED", ]
  expect_equal(nrow(closed), 2L)
  expect_true(all(closed$publishes_roster == "No"))
})

test_that("the SECOND TIER awarding stops the build -- that is where the money is", {
  skip_without_archive()
  raw <- readBin(nc_path("trillium"), "raw", file.size(nc_path("trillium")))
  faked <- sub("</body>", "Region 2 awarded these organizations</body>",
               rawToChar(raw), fixed = TRUE)
  expect_error(
    nc_assert_positive_control(bodies = list(trillium = charToRaw(faked))),
    "SECOND TIER may have awarded")
})


# -- the deferral is deliberate ----------------------------------------------

test_that("the award file exists and North Carolina is extracted", {
  expect_true(nc_assert_extracted())
  expect_true(file.exists(NC_AWARDEES_CSV))
})

test_that("the status table records the rosters WITHOUT an amount column", {
  st <- nc_status_table()
  expect_false("amount" %in% names(st))
  expect_equal(nrow(st), 6L)
  awarded <- st[st$stage == "AWARDED_ROSTER_PUBLISHED", ]
  expect_equal(nrow(awarded), 2L)
  expect_equal(sum(awarded$named_recipients), 44L)
  expect_setequal(awarded$named_recipients, c(39L, 5L))
})

test_that("North Carolina reads EXTRACTED, never INVESTIGATED_NO_LIST", {
  # It has published rosters, so INVESTIGATED_NO_LIST would be a FALSE claim
  # about the state -- the one thing that code must never become. Session 37
  # left it NOT_EXTRACTED, which was true then; session 38 extracted it.
  for (f in c("rcj_state_survey.csv", "state_trigger_queue.csv")) {
    path <- here::here("data", "reference", f)
    skip_if_not(file.exists(path), paste(f, "is not on disk"))
    d <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
    col <- if ("extraction_status" %in% names(d)) "extraction_status" else
      "queue_status"
    expect_false(identical(d[[col]][d$state == "NC"], "INVESTIGATED_NO_LIST"))
    expect_equal(d[[col]][d$state == "NC"], "EXTRACTED")
  }
})


# -- the digest mechanism ----------------------------------------------------

test_that("Dynatrace's per-request rpid moves the FILE digest, not content", {
  skip_without_archive()
  raw <- readBin(nc_path("roots_page"), "raw", file.size(nc_path("roots_page")))
  txt <- rawToChar(raw)
  expect_true(grepl("ruxitagentjs", txt, fixed = TRUE))
  rolled <- sub("rpid=-?[0-9]+", "rpid=123456789", txt)
  expect_false(identical(rolled, txt))
  expect_false(identical(digest::digest(charToRaw(rolled), serialize = FALSE),
                         digest::digest(raw, serialize = FALSE)))
  # It is a script-TAG ATTRIBUTE, so the reduction absorbs it free.
  expect_identical(nc_reduce_html(charToRaw(rolled)), nc_reduce_html(raw))
})


# -- the extraction ----------------------------------------------------------

test_that("both rosters parse to the counts NCDHHS states", {
  skip_without_archive()
  mih <- nc_mih_roster()
  expect_equal(nrow(mih), 39L)
  expect_equal(length(unique(mih$awardee)), 39L)
  expect_true(all(nzchar(mih$awardee)))
  # The two the header calls out, both present and both as PUBLISHED (§8).
  expect_true("Cape Fear Valley Mobile Integrated Health (MIH)" %in% mih$awardee)
  expect_true("Clay County" %in% mih$awardee)
  expect_false("Clay County EMS" %in% mih$awardee)

  roots <- nc_hub_lead_roster()
  expect_equal(nrow(roots), 5L)
  # NC_HUB_LEADS holds the SUBSTRINGS nc_assert_hub_leads() looks for; the
  # roster prints "Access East, Inc." in full, and §8 keeps the state's own
  # language.
  expect_true(all(vapply(NC_HUB_LEADS,
                         function(n) any(startsWith(roots$awardee, n)),
                         logical(1))))
  expect_true("Access East, Inc." %in% roots$awardee)
  # FIVE ORGANISATIONS, SIX REGIONS. Trillium holds two, so a row count is
  # neither a region count nor an organisation count.
  expect_equal(roots$hub_region[roots$awardee == "Trillium Health Resources"],
               "Region 2 and 5")
})

test_that("a dollar figure inside either roster stops the build", {
  # THE ONE THING THAT WOULD MAKE THE EMPTY `amount` COLUMN A LIE. If NCDHHS
  # starts publishing per-recipient amounts, this file must be REWRITTEN, not
  # patched -- so the parser refuses rather than quietly carrying on.
  skip_without_archive()
  raw <- nc_raw("pr_mih")
  faked <- sub("<li data-list-item-id", "<li>$250,000</li><li data-list-item-id",
               rawToChar(raw), fixed = TRUE)
  expect_error(nc_mih_roster(body = charToRaw(faked)),
               "dollar figure has appeared INSIDE")
})

test_that("a 40th MIH recipient stops the build rather than updating a count", {
  skip_without_archive()
  raw <- nc_raw("pr_mih")
  # Inserted INSIDE the roster's own <ul>, not at the document's first </ul>
  # -- which is a navigation menu and would leave the roster untouched.
  faked <- sub("recipients include:&nbsp;</p><ul>",
               "recipients include:&nbsp;</p><ul><li>Wake County EMS</li>",
               rawToChar(raw), fixed = TRUE)
  expect_false(identical(faked, rawToChar(raw)))
  expect_error(nc_mih_roster(body = charToRaw(faked)),
               "document to re-read, not a count to update")
})

test_that("amount is empty on all 44 rows and no bucket is populated", {
  # THE PAIRING ASSERTION, IN THE SHAPE NORTH CAROLINA'S DATA ACTUALLY TAKES.
  skip_without_archive()
  rows <- nc_award_rows()
  expect_equal(nrow(rows), 44L)
  expect_true(all(is.na(rows$amount)))
  expect_equal(sum(rows$amount, na.rm = TRUE), 0)

  part <- rhtp_hospital_dollar_partition(rows)
  expect_equal(nrow(part), 0L)
  expect_true(is.list(nc_assert_row_count_is_the_finding(rows)))
})

test_that("a divided pool or a promoted row trips the pairing assertion", {
  # THE TWO WAYS THE MISTAKE IS ACTUALLY MADE, in the order it is made in:
  # first somebody spreads the $10,000,000 over 39 rows, then somebody
  # promotes Cape Fear Valley into a hospital bucket.
  skip_without_archive()
  rows <- nc_award_rows()

  divided <- rows
  divided$amount <- divided$round_amount / divided$round_awards
  expect_error(nc_assert_row_count_is_the_finding(divided),
               "came from this pipeline and not from North Carolina")

  promoted <- rows
  k <- which(promoted$awardee == "Cape Fear Valley Mobile Integrated Health (MIH)")
  promoted$recipient_type[k]          <- "HOSPITAL_OR_SYSTEM"
  promoted$flow_type[k]               <- "DIRECT"
  promoted$distributed_to_hospital[k] <- "Yes"
  promoted$hospital_attribution[k]    <- "NAMED_HOSPITAL"
  expect_error(nc_assert_row_count_is_the_finding(promoted),
               "hospital bucket")
  expect_error(nc_assert_form_not_stated_queued(promoted),
               "promoted off §8's standing fallback")
})

test_that("the ROOTS rows carry NO round_amount -- the allotment is refused", {
  # §0.2 WRITTEN INTO THE DATA. Five named awardees, and the only currency
  # figure on either ROOTS document is the $213,008,356.47 STATE ALLOTMENT.
  skip_without_archive()
  rows <- nc_award_rows()
  hub <- rows[rows$award_pool == NC_POOL_ROOTS, ]
  expect_true(all(is.na(hub$round_amount)))
  expect_true(nc_assert_hub_leads_unresolved(rows))

  filled <- rows
  filled$round_amount[filled$award_pool == NC_POOL_ROOTS] <- NC_FOOTER
  expect_error(nc_assert_hub_leads_unresolved(filled),
               "whole state award as five hub awards")
})

test_that("round_amount must never be summed down the column", {
  # GEORGIA'S TRAP, NEVADA'S DEVICE. $10,000,000 repeated 39 times.
  skip_without_archive()
  rec <- nc_reconcile()
  expect_equal(rec$published, 10000000)
  expect_equal(rec$naive_wrong_total, 390000000)
  expect_gt(rec$naive_wrong_total, rec$published)
})

test_that("the five Hub Leads are Unclear, in neither bucket, with a basis", {
  # NEW HAMPSHIRE'S FHC ANSWER, NOT ILLINOIS'S ICAHN ANSWER -- hospitals among
  # others is §0.3, and coding it Yes would put an unpriced regional
  # pass-through into a hospital bucket on this pipeline's authority.
  skip_without_archive()
  hub <- nc_award_rows() %>% dplyr::filter(award_pool == NC_POOL_ROOTS)
  expect_true(all(hub$flow_type == "PASS_THROUGH_UNRESOLVED"))
  expect_true(all(hub$distributed_to_hospital == "Unclear"))
  expect_true(all(hub$hospital_attribution == "NOT_HOSPITAL"))
  expect_true(all(nzchar(hub$determination_basis)))
  expect_false(any(startsWith(hub$determination_basis, "§10.2 DIRECT")))
  expect_true(all(grepl("hospitals AMONG OTHERS", hub$determination_basis,
                        fixed = TRUE)))
  expect_true(all(nzchar(hub$intermediary_name)))
})

test_that("the two spellings of the Region 4 Hub Lead classify DIFFERENTLY", {
  # THE FINDING, ASSERTED RATHER THAN REPAIRED. A fuzzy merge here changes a
  # CODING, not just a count: one spelling is a named-hospital row.
  skip_without_archive()
  cls <- rhtp_classify_recipient_type(
    c("University of North Carolina Hospitals", "UNC Health"), "NC")
  expect_equal(cls$recipient_type[1], "HOSPITAL_OR_SYSTEM")
  expect_equal(cls$recipient_type[2], "NONPROFIT_CBO")
  expect_false(identical(cls$recipient_type[1], cls$recipient_type[2]))

  flow <- rhtp_classify_flow(cls$recipient_type, c(NA_character_, NA_character_))
  expect_equal(flow$distributed_to_hospital, c("Yes", "No"))

  # And NEITHER machine answer is what the file uses: NCDHHS's own page states
  # the form, and §8's code for an academic health centre is UNIVERSITY_OR_AHC
  # (Oregon's OHSU precedent), which can only keep dollars OUT.
  rows <- nc_award_rows()
  k <- which(rows$awardee == "University of North Carolina Hospitals")
  expect_equal(rows$recipient_type[k], "UNIVERSITY_OR_AHC")
  expect_equal(rows$distributed_to_hospital[k], "Unclear")
  expect_true(is.character(nc_assert_unc_two_spellings()))
})

test_that("37 of the 39 MIH rows agree with NCDHHS's own class sentence", {
  # The agreement is what makes the TWO queued rows stand out rather than
  # being two of thirty-nine unknowns.
  skip_without_archive()
  rows <- nc_award_rows()
  mih <- rows[rows$award_pool == NC_POOL_MIH, ]
  expect_equal(sum(mih$recipient_type == "EMS_OR_PSAP"), 37L)
  expect_equal(sum(mih$recipient_type == "NONPROFIT_CBO"), 2L)
  expect_true(all(mih$distributed_to_hospital == "No"))
  expect_true(nc_assert_form_not_stated_queued(rows))
})

test_that("nothing was promoted, and both questions are in the review queue", {
  skip_without_archive()
  rows <- nc_award_rows()
  for (nm in NC_QUEUED_FORM_ROWS) {
    k <- which(rows$awardee == nm)
    expect_equal(rows$recipient_type[k], "NONPROFIT_CBO")
    expect_equal(rows$determination_confidence[k], "LOW")
    expect_true(grepl("RECIPIENT_TYPE_INFERRED", rows$flag_reason[k]))
  }
  q <- readr::read_csv(NC_REVIEW_QUEUE, show_col_types = FALSE,
                       progress = FALSE)
  expect_true("NC_MIH_FORM_NOT_STATED" %in% q$question_id)
  expect_true("NC_HUB_LEAD_FORM_NOT_IN_VOCABULARY" %in% q$question_id)
  # Both are worth $0, because North Carolina prices nobody.
  nc_q <- q[q$state == "NC", ]
  expect_true(all(grepl("\\$0", nc_q$dollar_effect)))
})

test_that("§8 now carries MANAGED_CARE_ORGANIZATION, and it is in the vocabulary", {
  # SESSION 39. The code was added deliberately, on session 10's
  # PHYSICIAN_PRACTICE footing, for a condition none of the codes before it was
  # added for: THE SOURCE STATES A FORM §8 DOES NOT CARRY. It must be a real
  # vocabulary value with real notes, not a string an extractor invented (§2).
  expect_true("MANAGED_CARE_ORGANIZATION" %in%
                rhtp_vocabulary("recipient_type"))
  v <- readr::read_csv(here::here("data/reference/vocabularies.csv"),
                       show_col_types = FALSE, progress = FALSE)
  note <- v$notes[v$column_name == "recipient_type" &
                    v$allowed_value == "MANAGED_CARE_ORGANIZATION"]
  expect_equal(length(note), 1L)
  expect_true(nzchar(note))
  # The note has to carry the three things that stop it being reached for
  # wrongly: why it is not the standing fallback, why it is not
  # VENDOR_OR_CONTRACTOR / STATE_AGENCY, and that it is never a hospital type.
  expect_true(grepl("RECIPIENT_TYPE_INFERRED", note, fixed = TRUE))
  expect_true(grepl("VENDOR_OR_CONTRACTOR", note, fixed = TRUE))
  expect_true(grepl("STATE_AGENCY", note, fixed = TRUE))
  expect_true(grepl("NOT a hospital type", note, fixed = TRUE))
})

test_that("the two Hub Leads NCDHHS calls an MCO are typed from the source", {
  # Session 38 left all three of these on §8's standing fallback because §8 had
  # no code for the form the state stated. Session 39 added one, so the two the
  # state actually calls a Managed Care Organization are now typed from
  # NCDHHS's own sentence -- and using the fallback here would assert the form
  # is UNDETERMINED when the state has stated it outright, which is exactly
  # what RECIPIENT_TYPE_INFERRED's own note forbids.
  skip_without_archive()
  rows <- nc_award_rows()
  for (nm in c("Trillium Health Resources", "Vaya Health")) {
    k <- which(rows$awardee == nm)
    expect_equal(rows$recipient_type[k], "MANAGED_CARE_ORGANIZATION")
    expect_true(grepl("Managed Care Organization (MCO)",
                      rows$recipient_type_source[k], fixed = TRUE))
    # The state's word is the basis, so the row is NOT flagged as inferred.
    expect_false(grepl("RECIPIENT_TYPE_INFERRED", rows$flag_reason[k]))
    # AND THE RETYPING MOVED NO HOSPITAL QUANTITY. Both stay §10.2's
    # unresolved pass-through, in neither bucket, worth $0 and 0 rows.
    expect_equal(rows$flow_type[k], "PASS_THROUGH_UNRESOLVED")
    expect_equal(rows$distributed_to_hospital[k], "Unclear")
    expect_true(is.na(rows$amount[k]))
  }
})

test_that("ACCESS EAST IS NOT AN MCO AND THE NEW CODE WAS NOT WIDENED TO IT", {
  # THE HALF THAT MATTERS MORE. NCDHHS states this recipient's form too -- "a
  # comprehensive care management provider" -- and that is a different thing
  # from a Managed Care Organization in North Carolina's own Medicaid
  # vocabulary. Widening a code on the day it is added, to a form its source
  # does not state, is §0.4's failure in miniature. So this row keeps §8's
  # standing fallback and the question stays open.
  skip_without_archive()
  rows <- nc_award_rows()
  k <- which(rows$awardee == "Access East, Inc.")
  expect_equal(rows$recipient_type[k], "NONPROFIT_CBO")
  expect_true(grepl("§8 CARRIES NO CODE FOR THAT FORM",
                    rows$recipient_type_source[k], fixed = TRUE))
  expect_true(grepl("RECIPIENT_TYPE_INFERRED", rows$flag_reason[k]))
  # POSITIVE CONTROL: the archive must still NOT call it a Managed Care
  # Organization. If NCDHHS ever restates its form, this test fails and the
  # coding is re-decided from the document rather than drifting into the code
  # its two neighbours carry.
  html <- readLines(nc_path("roots_page"),
                    warn = FALSE, encoding = "UTF-8")
  txt <- paste(html, collapse = " ")
  i <- regexpr("comprehensive care management provider", txt, fixed = TRUE)
  expect_true(i > 0)
  # The window spans NCDHHS's whole Access East entry, from its own heading
  # through the sentence that states its form. "Managed Care Organization"
  # appears twice on this page -- for Trillium and for Vaya -- and NOT here.
  expect_false(grepl("Managed Care Organization",
                     substr(txt, i - 600, i + 600), fixed = TRUE))
  expect_equal(length(gregexpr("Managed Care Organization (MCO)",
                               txt, fixed = TRUE)[[1]]), 2L)
})

test_that("Impact Health and UNC keep the codes §8 already carried", {
  # Impact Health's form IS in §8, so it is typed from the source and is NOT
  # flagged as inferred -- the distinction the flag exists to draw.
  skip_without_archive()
  rows <- nc_award_rows()
  k <- which(rows$awardee == "Impact Health")
  expect_equal(rows$recipient_type[k], "NONPROFIT_CBO")
  expect_true(grepl("501(c)3", rows$recipient_type_source[k], fixed = TRUE))
  expect_false(grepl("RECIPIENT_TYPE_INFERRED", rows$flag_reason[k]))
  k <- which(rows$awardee == "University of North Carolina Hospitals")
  expect_equal(rows$recipient_type[k], "UNIVERSITY_OR_AHC")
})

test_that("EXACTLY ONE Hub Lead is still on the fallback, and it is queued", {
  # The queue row went from THREE recipients to ONE, not to zero. A session
  # that closed it entirely would have swept Access East into a code its
  # source does not support.
  skip_without_archive()
  rows <- nc_award_rows()
  hub <- rows[grepl("ROOTS", rows$award_pool), ]
  expect_equal(sum(grepl("RECIPIENT_TYPE_INFERRED", hub$flag_reason)), 1L)
  expect_equal(hub$awardee[grepl("RECIPIENT_TYPE_INFERRED", hub$flag_reason)],
               "Access East, Inc.")
  q <- readr::read_csv(NC_REVIEW_QUEUE, show_col_types = FALSE,
                       progress = FALSE)
  r <- q[q$question_id == "NC_HUB_LEAD_FORM_NOT_IN_VOCABULARY", ]
  expect_equal(nrow(r), 1L)
  expect_equal(r$row_key, "Access East, Inc.")
  expect_equal(r$queue_status, "OPEN")
  # And it still moves nothing, which is what made the addition safe.
  expect_true(grepl("\\$0", r$dollar_effect))
})

test_that("NORTH CAROLINA STILL CONTRIBUTES NOTHING TO ANY HOSPITAL BUCKET", {
  # THE INVARIANT THE WHOLE RETYPING HAD TO PRESERVE. An MCO is not a hospital
  # type, so §8 gaining a code must not have moved a dollar or a row.
  skip_without_archive()
  rows <- nc_award_rows()
  part <- rhtp_hospital_dollar_partition(rows)
  expect_equal(nrow(part), 0L)
  expect_true(all(is.na(rows$amount)))
})

test_that("every categorical value is inside §8 and every row cites a source", {
  skip_without_archive()
  rows <- nc_award_rows()
  expect_true(nc_assert_vocabulary(rows))
  expect_true(all(nzchar(rows$state_source_url)))
  expect_true(all(nzchar(rows$source_document_title)))
  expect_true(all(file.exists(here::here(rows$source_archive_path))))
  expect_true(all(rows$recipient_confirmed == "Yes"))
  expect_true(all(rows$amount_confirmed == "No"))
})

test_that("the committed CSV is what the builder produces", {
  skip_without_archive()
  skip_if_not(file.exists(NC_AWARDEES_CSV))
  on_disk <- readr::read_csv(NC_AWARDEES_CSV, show_col_types = FALSE,
                             progress = FALSE)
  built <- nc_award_rows()
  expect_equal(nrow(on_disk), nrow(built))
  expect_equal(names(on_disk), names(built))
  expect_equal(on_disk$awardee, built$awardee)
  expect_equal(on_disk$recipient_type, built$recipient_type)
  expect_equal(on_disk$flow_type, built$flow_type)
})
