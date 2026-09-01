# Michigan Year 1 -- R/03v_mi_year1_awardees.R (session 27)
#
# Michigan is the first state file in this repository whose publisher calls its
# own roster COMPLETE, the first extracted from a host that refuses every
# honest user-agent, and the first where 139 priced awards yield ONE named
# hospital. Each of those is pinned here.

source(here::here("R", "03v_mi_year1_awardees.R"))

mi_recs <- rhtp_mi_year1_awardees()


# -- the archive --------------------------------------------------------------

test_that("every archived source is present and re-hashes to its manifest digest", {
  manifest <- file.path(MI_EVIDENCE_DIR, "MANIFEST.txt")
  expect_true(file.exists(manifest))
  lines <- readLines(manifest, warn = FALSE)

  for (i in seq_len(nrow(MI_SOURCES))) {
    path <- file.path(MI_EVIDENCE_DIR, MI_SOURCES$file[i])
    expect_true(file.exists(path), info = MI_SOURCES$key[i])
    got <- digest::digest(file = path, algo = "sha256")
    # The manifest is written from the bytes the server sent, via writeBin(),
    # so re-hashing the file on disk must reproduce the digest exactly. This
    # is the check that would have caught session 12's trailing-newline defect.
    expect_true(any(grepl(got, lines, fixed = TRUE)), info = MI_SOURCES$file[i])
  }
  # A manifest cannot record its own digest (session 15), so it must not list
  # itself, and the listed set must equal the on-disk set.
  expect_false(any(grepl("MANIFEST.txt", lines, fixed = TRUE)))
  on_disk <- setdiff(basename(list.files(MI_EVIDENCE_DIR)), "MANIFEST.txt")
  expect_setequal(on_disk, MI_SOURCES$file)
})

test_that("the anonymous user-agent is scoped to michigan.gov and nowhere else", {
  # The documented exception must stay an exception. michigan.gov refuses every
  # identifying agent -- the project's own, the RFC crawler convention, and a
  # Chrome UA with the tracker token appended -- and its robots.txt is 403 too,
  # so no crawler policy is being declined. mha.org and cms.gov take the
  # honest agent, and mi_agent_for() refuses to mix the two up in either
  # direction.
  for (key in MI_SOURCES$key) {
    agent <- mi_agent_for(key)
    url   <- mi_source(key, "url")
    if (startsWith(url, MI_BASE)) {
      expect_identical(agent, MI_MICHIGAN_GOV_USER_AGENT, info = key)
    } else {
      expect_identical(agent, MI_USER_AGENT, info = key)
      expect_true(grepl("aha.org", agent, fixed = TRUE), info = key)
    }
  }
  # And it cannot spread: a source row that asks for the anonymous agent on
  # another host is refused rather than served.
  local({
    saved <- MI_SOURCES
    on.exit(assign("MI_SOURCES", saved, envir = globalenv()), add = TRUE)
    MI_SOURCES <<- dplyr::mutate(
      saved, url = ifelse(.data$key == "roster",
                          "https://example.gov/roster", .data$url))
    expect_error(mi_agent_for("roster"), "scoped to www.michigan.gov")
  })
  # ...and the reverse: a michigan.gov source that asked for the honest agent
  # would be fetched with something that host answers 403.
  local({
    saved <- MI_SOURCES
    on.exit(assign("MI_SOURCES", saved, envir = globalenv()), add = TRUE)
    MI_SOURCES <<- dplyr::mutate(
      saved, agent = ifelse(.data$key == "roster", "HONEST", .data$agent))
    expect_error(mi_agent_for("roster"), "HTTP 403")
  })
})


# -- the roster ---------------------------------------------------------------

test_that("the roster is 139 award actions and $69,883,392", {
  expect_equal(nrow(mi_recs), 139L)
  expect_equal(sum(mi_recs$amount), 69883392)
  expect_equal(dplyr::n_distinct(mi_recs$awardee), 122L)
  # Michigan publishes an amount on EVERY row. An empty one here is a parse
  # failure, not a finding -- Nevada is the state where it is a finding.
  expect_false(any(is.na(mi_recs$amount)))
  expect_true(all(mi_recs$amount > 0))
})

test_that("the five initiative sections are the roster's, read from the DOM", {
  expect_true(mi_assert_roster_sections(mi_recs))
  expect_setequal(unique(mi_recs$initiative), MI_SECTIONS)
  by_init <- table(mi_recs$initiative)
  expect_equal(as.integer(by_init[["Interoperability in Action Initiative"]]), 20L)
  expect_equal(as.integer(
    by_init[["Transforming Rural Health Through Partnerships Initiative"]]), 71L)
  expect_equal(as.integer(by_init[["Workforce for Wellness Initiative"]]), 19L)
  expect_equal(as.integer(by_init[["Care Closer to Home Initiative"]]), 16L)
  expect_equal(as.integer(by_init[["Tribal Government"]]), 13L)
})

test_that("the section mapping survives a reordering of the accordion", {
  # The mapping is read from DOCUMENT ORDER, not table order, and this is why
  # it had to be: two sections share a first awardee. "Benzie-Leelanau
  # District Health Department" opens BOTH the Partnerships and the Workforce
  # tables, so a mapping that located the first cell in the page text would
  # find the wrong table and silently relabel 19 rows.
  first_cells <- mi_recs %>%
    dplyr::group_by(.data$initiative) %>%
    dplyr::slice(1) %>%
    dplyr::pull(.data$awardee)
  expect_true(anyDuplicated(first_cells) > 0 ||
                sum(mi_recs$awardee == "Benzie-Leelanau District Health Department") > 1)
  expect_equal(
    sum(mi_recs$awardee == "Benzie-Leelanau District Health Department"), 2L)
  expect_setequal(
    mi_recs$initiative[mi_recs$awardee == "Benzie-Leelanau District Health Department"],
    c("Transforming Rural Health Through Partnerships Initiative",
      "Workforce for Wellness Initiative"))
})

test_that("session 10's <td> header defect is caught on all five tables", {
  expect_true(mi_assert_header_promoted(mi_recs))
  # MDHHS marks EVERY roster header row up with <td>. Without promotion the
  # parser reads five organisations called "Subrecipient Organization" for an
  # amount of "Award Amount*" -- so this is load-bearing, not cosmetic.
  expect_false(any(mi_recs$awardee == "Subrecipient Organization"))
  # And promotion may only ever make the parse better: it fires when the
  # candidate row resolves STRICTLY MORE columns (session 10's own rule).
  good <- tibble::tibble(`Subrecipient Organization` = "X",
                         `Award Amount*` = "$1", Fund = "F")
  expect_identical(mi_promote_header(good), good)
  blind <- tibble::tibble(X1 = c("Subrecipient Organization", "X"),
                          X2 = c("Award Amount*", "$1"),
                          X3 = c("Fund", "F"))
  expect_equal(nrow(mi_promote_header(blind)), 1L)
  expect_equal(mi_promote_header(blind)[[1]], "X")
})

test_that("an amount that is not a plain dollar figure is refused, not coerced", {
  expect_equal(mi_parse_amount(c("$1,663,636", "$76,923")), c(1663636, 76923))
  expect_equal(mi_parse_amount("$100,000.50"), 100000.50)
  for (bad in c("$403,000 - $778,000", "TBD", "$1,000,000*", "1000000")) {
    expect_error(mi_parse_amount(bad), "not plain dollar figures")
  }
})


# -- §6.2, with the footer downgraded ----------------------------------------

test_that("provenance rests on three programme-scoped sentences, not the footer", {
  expect_true(mi_assert_rhtp_funded())
  roster <- mi_html_text("roster")
  # THE POINT OF SESSION 27'S AUDIT, pinned: Michigan's footer carries the WEAK
  # subject. "This PROJECT is supported by" is a statement about the paper, the
  # form Nevada disproved and the form Kansas's REH CAP/RPGP document relies on
  # entirely. It corroborates the AMOUNT and nothing else.
  expect_true(grepl("This project is supported by", roster, fixed = TRUE))
  expect_false(grepl("This Rural Health Transformation Program is supported by",
                     roster, fixed = TRUE))
  # The three sentences that DO carry the programme.
  expect_true(grepl(MI_ROSTER_PROGRAM_SENTENCE, roster, fixed = TRUE))
  expect_true(grepl(MI_PROGRAM_PAGE_SENTENCE, mi_html_text("program"), fixed = TRUE))
  expect_true(grepl(MI_RELEASE_SENTENCE, mi_html_text("award_release"), fixed = TRUE))
  # The footer's figure rounds to the §7.1 anchor to the dollar.
  expect_equal(round(MI_STATED$cms_footer_amount), rhtp_mi_allotment())
  expect_equal(rhtp_mi_allotment(), 173128201)
})

test_that("the date half: everything Michigan did came after its Notice of Award", {
  expect_true(mi_assert_after_noa())
  noa <- rhtp_mi_noa_date()
  expect_equal(noa, as.Date("2025-12-29"))
  expect_gt(MI_STATED$noa_announced, noa)       # announced the very next day
  expect_gt(MI_STATED$workforce_gfo_date, noa)
  expect_gt(MI_STATED$roster_as_of, noa)
})

test_that("the §6.2 negative control is opioid settlement money and says so", {
  expect_true(mi_assert_non_rhtp_control())
  txt <- mi_html_text("prevention")
  expect_true(grepl(MI_NON_RHTP_SENTENCE, txt, fixed = TRUE))
  # Nothing in it is RHTP, and that absence is the finding. Eight of RCJ's 31
  # Michigan candidates are this release's recipients.
  expect_false(grepl("Rural Health Transformation", txt, fixed = TRUE))
  expect_false(grepl("RHTP", txt, fixed = TRUE))
  expect_false(grepl("rural", txt, ignore.case = TRUE))
})

test_that("the negative control fails loudly if MDHHS ever adds RHTP to it", {
  # A negative nobody re-checks decays into an assumption. Feed the assertion
  # a release that DOES mention RHTP and require a refusal.
  local({
    saved <- get("mi_html_text", envir = globalenv())
    on.exit(assign("mi_html_text", saved, envir = globalenv()), add = TRUE)
    mi_html_text <<- function(key) {
      if (key == "prevention") {
        return(paste(MI_NON_RHTP_SENTENCE,
                     "This is part of the Rural Health Transformation Program."))
      }
      saved(key)
    }
    expect_error(mi_assert_non_rhtp_control(), "now mentions")
  })
  # And if the opioid sentence goes, the disposition has lost its evidence.
  local({
    saved <- get("mi_html_text", envir = globalenv())
    on.exit(assign("mi_html_text", saved, envir = globalenv()), add = TRUE)
    mi_html_text <<- function(key) {
      if (key == "prevention") return("MDHHS awarded twelve organizations.")
      saved(key)
    }
    expect_error(mi_assert_non_rhtp_control(), "opioid settlement")
  })
})


# -- the positive control: MDHHS claims the roster is COMPLETE ---------------

test_that("the completeness claim is on the page, and its loss is a hard stop", {
  expect_true(mi_assert_completeness_claim())
  expect_true(grepl(MI_COMPLETENESS_SENTENCE, mi_html_text("program"), fixed = TRUE))
  # No other state file here can say this. It is what makes $69,883,392 a
  # TOTAL rather than a floor, so it is checked every run rather than assumed.
  local({
    saved <- get("mi_html_text", envir = globalenv())
    on.exit(assign("mi_html_text", saved, envir = globalenv()), add = TRUE)
    mi_html_text <<- function(key) {
      if (key == "program") return("MDHHS runs the RHT Program.")
      saved(key)
    }
    expect_error(mi_assert_completeness_claim(), "featuring ALL RHTP")
  })
})

test_that("every row is an award notice with an amount MDHHS has not finalised", {
  expect_true(all(mi_recs$recipient_confirmed == "Yes"))
  # MDHHS: "Award amount is contingent upon review by CMS for final approval."
  # §9.3 splits the two questions -- Oregon's and Maryland's posture, except
  # that here the contingency is FEDERAL review of a state award rather than a
  # state negotiation with the recipient.
  expect_true(all(mi_recs$amount_confirmed == "No"))
  expect_true(all(mi_recs$validation_source_type == "NOTICE_OF_AWARD"))
  expect_true(grepl(MI_CONTINGENCY_SENTENCE, mi_html_text("roster"), fixed = TRUE))
})


# -- §8 / §10.2 ---------------------------------------------------------------

test_that("the Michigan Health & Hospital Association is not typed as a hospital", {
  expect_true(mi_assert_mha_not_a_hospital(mi_recs))
  mha <- mi_recs[mi_recs$awardee == "Michigan Health and Hospital Association (MHA)", ]
  expect_equal(nrow(mha), 2L)
  expect_true(all(mha$recipient_type == "HOSPITAL_AFFILIATED_ENTITY"))
  expect_true(all(mha$flow_type == "PASS_THROUGH_UNRESOLVED"))
  expect_true(all(mha$distributed_to_hospital == "Unclear"))
  expect_true(all(mha$hospital_attribution == "NOT_HOSPITAL"))
  expect_true(all(mha$flag_reason == "FLOW_UNRESOLVED_HOSPITAL_AFFILIATED"))
  # THE TRAP, STATED AS A NUMBER: the §8 name rule reaches the "Hospital"
  # token and would return HOSPITAL_OR_SYSTEM -> DIRECT -> Yes, publishing
  # $8,625,000 as direct hospital dollars on a name match. Nevada met the same
  # trap twice in session 26 with two hospital foundations.
  by_name <- rhtp_classify_recipient_type(
    "Michigan Health and Hospital Association (MHA)", "MI")
  expect_equal(by_name$recipient_type, "HOSPITAL_OR_SYSTEM")
  expect_equal(sum(mha$amount), 8625000)
})

test_that("MHA's own page corroborates MDHHS's two rows to the dollar", {
  # Two publishers, one figure, nothing arranged: MDHHS lists $2,625,000 +
  # $6,000,000 and MHA's own RHTP page states its award in its own footer.
  expect_true(grepl("financial assistance award totaling $8.625 million",
                    mi_html_text("mha"), fixed = TRUE))
  expect_equal(MI_STATED$mha_own_footer, 8625000)
})

test_that("the tribal section is typed from the state's own column, not from names", {
  expect_true(mi_assert_tribal_from_source(mi_recs))
  trib <- mi_recs[mi_recs$award_pool == "Tribal Government", ]
  expect_equal(nrow(trib), 13L)
  expect_true(all(trib$recipient_type == "TRIBAL_ORG"))
  expect_true(all(trib$determination_confidence == "HIGH"))
  # AND THIS IS WHY IT IS READ: the §8 NAME rule reaches only nine of the
  # thirteen. Bay Mills, Hannahville, Keweenaw Bay and Little Traverse Bay
  # would otherwise take §8's fallback while the state has plainly said what
  # they are. Alaska's and Oregon's rule -- the state classifies its own
  # awardee and that outranks a reading of the name.
  by_name <- rhtp_classify_recipient_type(trib$awardee, "MI")
  expect_equal(sum(by_name$recipient_type == "TRIBAL_ORG"), 9L)
  for (nm in c("Bay Mills Indian Community", "Hannahville Indian Community",
               "Keweenaw Bay Indian Community",
               "Little Traverse Bay Bands of Odawa Indians")) {
    expect_equal(mi_recs$recipient_type[mi_recs$awardee == nm], "TRIBAL_ORG",
                 info = nm)
  }
})

test_that("§0.3a: a parenthetical project does not type the recipient", {
  # MDHHS annotates two rows with the PROJECT rather than the form --
  # "MyMichigan Health (EMS - Chronic Disease)" -- and the §8 activity token
  # would type the RECIPIENT as EMS_OR_PSAP off it. That is §0.3a's error:
  # judge the recipient, never the activity. Nothing was promoted either --
  # the row takes §8's fallback and goes to the review queue.
  row <- mi_recs[mi_recs$awardee == "MyMichigan Health (EMS - Chronic Disease)", ]
  expect_equal(nrow(row), 1L)
  expect_equal(row$recipient_type, "NONPROFIT_CBO")
  expect_equal(row$determination_confidence, "LOW")
  expect_equal(row$flag_reason, "RECIPIENT_TYPE_INFERRED")
  by_name <- rhtp_classify_recipient_type(
    "MyMichigan Health (EMS - Chronic Disease)", "MI")
  expect_equal(by_name$recipient_type, "EMS_OR_PSAP")
  # An override that matches nothing is a stale claim, not a no-op.
  for (nm in MI_RECIPIENT_TYPE_OVERRIDES$awardee) {
    expect_true(nm %in% mi_recs$awardee, info = nm)
  }
})

test_that("Michigan's health departments all type the same way", {
  # Maryland's session-21 defect, one administrative tier down and eleven rows
  # wide: MDHHS awards eleven multi-county health departments and before
  # session 27 the same body landed in three different places depending on how
  # it was spelt. All are local public health bodies and none is a hospital,
  # so this moves $0 and removes a false uncertainty.
  hd <- mi_recs[grepl("Health Department|Community Health Agency|^Public Health",
                      mi_recs$awardee), ]
  expect_gte(nrow(hd), 20L)
  expect_true(all(hd$recipient_type == "LOCAL_GOVT_OR_PUBLIC_HEALTH"))
  expect_true(all(hd$distributed_to_hospital == "No"))
  # And the negatives: an ALLIANCE or ASSOCIATION of health departments is not
  # one, and a state department of health is not a local body.
  expect_equal(rhtp_classify_recipient_type(
    "Northern Michigan Public Health Alliance (NMPHA)", "MI")$recipient_type,
    "NONPROFIT_CBO")
  expect_equal(rhtp_classify_recipient_type(
    "Michigan Association of Local Public Health (MALPH)", "MI")$recipient_type,
    "NONPROFIT_CBO")
  expect_equal(rhtp_classify_recipient_type(
    "Oklahoma State Department of Health", "OK")$recipient_type, "STATE_AGENCY")
})

test_that("every categorical is inside §8's controlled vocabulary", {
  expect_true(mi_assert_vocabulary(mi_recs))
})


# -- the hospital figure ------------------------------------------------------

test_that("139 priced awards yield ONE named-hospital award action", {
  expect_true(mi_assert_hospital_shape(mi_recs))
  parts <- rhtp_hospital_dollar_partition(mi_recs)
  named <- parts[parts$bucket == "NAMED_HOSPITAL", ]
  expect_equal(named$rows, 1L)
  expect_equal(named$dollars, 76924)
  # NOT Nevada's shape. Nevada publishes a named roster with NO amounts, so its
  # 20 hospital rows carry $0; Michigan publishes an amount on every row and
  # almost none of it reaches a named hospital. The two zeros mean opposite
  # things and must never be summarised together.
  expect_false(any(is.na(mi_recs$amount)))
  expect_false(any(parts$bucket == "POOL_UNNAMED_HOSPITALS"))
  expect_false(any(parts$bucket == "POOL_NAMED_HOSPITALS"))
})

test_that("the unstated-form question is queued, and is ONE-DIRECTIONAL", {
  expect_true(mi_assert_form_not_stated_queued(mi_recs))
  soft <- mi_recs[mi_recs$determination_confidence == "LOW" &
                    !is.na(mi_recs$flag_reason) &
                    mi_recs$flag_reason == "RECIPIENT_TYPE_INFERRED", ]
  expect_equal(nrow(soft), 84L)
  expect_equal(sum(soft$amount), 39836422)
  # Oklahoma's shape: every fallback row is already `No`, so resolving any can
  # only RAISE Michigan's hospital figure and never lower it. The floor is
  # $76,924 and the ceiling is $39,913,346.
  expect_true(all(soft$distributed_to_hospital == "No"))
  expect_equal(sum(soft$amount) + 76924, 39913346)
  # NOTHING WAS PROMOTED (§0.4). The names a reviewer reaches for first must
  # still be sitting on the fallback.
  for (nm in c("MyMichigan Health (EMS - Chronic Disease)",
               "MyMichigan Health Services", "Sterling Area Health Center",
               "Alcona Health Center", "Thunder Bay Community Health Service")) {
    expect_true(nm %in% soft$awardee, info = nm)
  }
})

test_that("both Michigan review-queue questions are open and state their effect", {
  queue <- readr::read_csv(
    here::here("data", "reference", "classification_review_queue.csv"),
    show_col_types = FALSE)
  mi <- queue[queue$state == "MI", ]
  expect_equal(nrow(mi), 2L)
  expect_true(all(mi$queue_status == "OPEN"))
  expect_setequal(mi$question_id,
                  c("MI_RECIPIENT_FORM_NOT_STATED", "MI_MHA_FLOW"))
  # The MHA question moves $8,625,000 and is NOT the open GHA_RECIPIENT_TYPE
  # question, which is about §8 typing and is worth $0 either way.
  mha <- mi[mi$question_id == "MI_MHA_FLOW", ]
  expect_true(grepl("8,625,000", mha$dollar_effect, fixed = TRUE))
  form <- mi[mi$question_id == "MI_RECIPIENT_FORM_NOT_STATED", ]
  expect_true(grepl("39,836,422", form$dollar_effect, fixed = TRUE))
  expect_true(grepl("One-directional", form$dollar_effect, fixed = TRUE))
})


# -- §0.1: RCJ ---------------------------------------------------------------

test_that("RCJ's 31 candidates decompose exactly, and the count is re-derived", {
  expect_true(!is.null(mi_assert_rcj_disposition(mi_recs)))
  cand <- mi_rcj_candidates()
  expect_equal(nrow(cand), 31L)
  expect_equal(sum(cand$group == "SUBRECIPIENTS_AWARD"), 14L)
  expect_equal(sum(cand$group == "BUDGET_NARRATIVE"), 9L)
  expect_equal(sum(cand$group == "OPIOID_SETTLEMENT"), 8L)
  expect_equal(sum(cand$group == "UNCLASSIFIED"), 0L)
})

test_that("RCJ DEFLATES Michigan: one row per organisation, not per award", {
  cand <- mi_rcj_candidates()
  real <- cand[cand$group == "SUBRECIPIENTS_AWARD", ]
  roster_for <- mi_recs %>%
    dplyr::filter(.data$awardee %in% real$awardee) %>%
    dplyr::group_by(.data$awardee) %>%
    dplyr::summarise(roster = sum(.data$amount), n = dplyr::n(), .groups = "drop")
  expect_equal(sum(real$rcj_amount), 19484032)
  expect_equal(sum(roster_for$roster), 27317365)
  expect_equal(sum(roster_for$roster) - sum(real$rcj_amount), 7833333)
  # Kansas's Greeley County defect at five times the scale: five organisations
  # hold more than one MDHHS award and RCJ kept one of each.
  expect_equal(sum(roster_for$n > 1L), 4L)
  mcrh <- roster_for[roster_for$awardee == "Michigan Center for Rural Health (MCRH)", ]
  expect_equal(mcrh$n, 5L)
  expect_equal(mcrh$roster, 7275000)
  expect_equal(real$rcj_amount[real$awardee == mcrh$awardee], 3000000)
  # EVERY §0.1 defect before Michigan's inflated. This one deflates.
  expect_gt(sum(roster_for$roster), sum(real$rcj_amount))
})

test_that("the opioid-settlement candidates are not roster rows", {
  cand <- mi_rcj_candidates()
  op <- cand[cand$group == "OPIOID_SETTLEMENT", ]
  expect_equal(sum(op$rcj_amount), 2214846)
  # None matches a roster row on name AND amount. One name collides -- Child
  # and Family Charities holds a real $208,333 RHTP award and a separate
  # $232,925 opioid-settlement grant -- which is exactly why the check is on
  # the PAIR and not the name.
  pairs <- paste(mi_recs$awardee, mi_recs$amount)
  expect_false(any(paste(op$awardee, op$rcj_amount) %in% pairs))
  expect_true("Child and Family Charities" %in% mi_recs$awardee)
})

test_that("the §6.2 registry catches all eight, with no false positives", {
  reg <- readr::read_csv(
    here::here("data", "reference", "non_rhtp_state_programs.csv"),
    show_col_types = FALSE)
  row <- reg[reg$program_id == "MI-SUD-PREVENTION-2026", ]
  expect_equal(nrow(row), 1L)
  expect_equal(row$disposition, "NOT_RHTP_STATE_PROGRAM")
  expect_equal(row$match_scope, "source")
  sweep <- readr::read_csv(
    here::here("data", "reference", "provenance_sweep_by_state.csv"),
    show_col_types = FALSE)
  mi <- sweep[sweep$state == "MI", ]
  expect_equal(mi$caught_total, 8L)
  expect_equal(mi$caught_state_program, 8L)
  # And none of the caught rows is one this file publishes.
  flagged <- readr::read_csv(
    here::here("data", "reference", "provenance_sweep_flagged_rows.csv"),
    show_col_types = FALSE)
  caught <- flagged[flagged$state == "MI", ]
  expect_equal(nrow(caught), 8L)
  expect_true(all(caught$registry_program == "MI-SUD-PREVENTION-2026"))
  # NO FALSE POSITIVES: not one caught row is a Michigan award this file
  # publishes, matched on the (name, amount) PAIR because one name legitimately
  # appears on both lists.
  pairs <- paste(mi_recs$awardee, mi_recs$amount)
  expect_false(any(paste(caught$awardee_name_raw,
                         caught$amount_announced) %in% pairs))
})


# -- reconciliation -----------------------------------------------------------

test_that("nothing is divided, invented, or double-counted", {
  expect_equal(mi_assert_reconciliation(mi_recs), 69883392)
  # round_amount stays EMPTY. Michigan publishes no pool totals on the roster,
  # so there is nothing for it to carry -- and populating it would import
  # Georgia's and Nevada's double-counting trap into a file that does not have
  # it.
  expect_true(all(is.na(mi_recs$round_amount)))
  expect_true(sum(mi_recs$amount) < rhtp_mi_allotment())
  expect_equal(round(100 * sum(mi_recs$amount) / rhtp_mi_allotment(), 1), 40.4)
})

test_that("the committed CSV matches what the parser produces", {
  csv <- readr::read_csv(here::here("data", "reference", "mi_year1_awardees.csv"),
                         show_col_types = FALSE)
  expect_equal(nrow(csv), nrow(mi_recs))
  expect_equal(sum(csv$amount), sum(mi_recs$amount))
  expect_equal(sort(csv$awardee), sort(mi_recs$awardee))
})
