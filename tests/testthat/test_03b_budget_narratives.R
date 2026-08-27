# test_03b_budget_narratives.R -----------------------------------------------
# Stage 2.5 unit tests. Read from disk only -- no network calls, zero API
# quota, safe to run on every session start.
#
# The fixtures are the two committed reference extractions. They are shaped
# differently on purpose (§7A.1), so most of what is worth testing here is
# whether the parser survives the difference: right sheet, right columns, right
# grain, on both, without either being hardcoded.

library(testthat)

source(here::here("R", "03b_budget_narratives.R"))

de_path <- here::here("DE_initiative_table.xlsx")
ok_path <- here::here("OK_initiative_table.xlsx")

de <- rhtp_parse_narrative_workbook(de_path)
ok <- rhtp_parse_narrative_workbook(ok_path)

allotments <- rhtp_load_cms_allotments()


# -- §7A.1 Format detection across two unlike workbooks --------------------

test_that("each workbook resolves to its own initiative sheet", {
  expect_equal(attr(de, "rhtp_format")$sheet, "Initiatives (Y1)")
  expect_equal(attr(ok, "rhtp_format")$sheet, "Fund uses (28)")
})

test_that("a reconciliation or summary sheet never outscores the real table", {
  de_scores <- rhtp_narrative_pick_sheet(de_path)$all_scores
  ok_scores <- rhtp_narrative_pick_sheet(ok_path)$all_scores

  expect_gt(de_scores[["Initiatives (Y1)"]], de_scores[["Reconciliation"]])
  expect_gt(de_scores[["Initiatives (Y1)"]], de_scores[["Named subrecipients"]])
  expect_gt(ok_scores[["Fund uses (28)"]], ok_scores[["By initiative"]])
})

test_that("grain is detected per workbook and never mixed within a state", {
  expect_equal(unique(de$initiative_grain), "INITIATIVE")
  expect_equal(unique(ok$initiative_grain), "FUND_USE")
  expect_true(all(unique(de$initiative_grain) %in% rhtp_vocabulary("initiative_grain")))
  expect_true(all(unique(ok$initiative_grain) %in% rhtp_vocabulary("initiative_grain")))
})

test_that("Oklahoma's `initiative` column is the grouping, not the row's name", {
  # The trap: `initiative` looks like the obvious name column, but in the OK
  # workbook it is the six-way grouping. Mapping it to initiative_name would
  # collapse 28 fund uses onto 6 names and silently lose 22 rows' identity.
  mapping <- attr(ok, "rhtp_format")$mapping

  expect_equal(unname(mapping[["initiative_name"]]), "fund_use")
  expect_equal(unname(mapping[["initiative_group"]]), "initiative")
  expect_equal(dplyr::n_distinct(ok$initiative_name), 29)
  expect_equal(dplyr::n_distinct(ok$initiative_group), 6)
})

test_that("the two workbooks are read through different amount columns", {
  expect_equal(unname(attr(de, "rhtp_format")$mapping[["initiative_budget"]]), "amount_y1")
  expect_equal(unname(attr(ok, "rhtp_format")$mapping[["initiative_budget"]]), "amount_bp1")
})

test_that("every parsed table lands in the full §7A.3 canonical schema", {
  expect_equal(names(de), RHTP_INITIATIVE_SCHEMA)
  expect_equal(names(ok), RHTP_INITIATIVE_SCHEMA)
})

test_that("row counts and figures survive the parse exactly", {
  expect_equal(nrow(de), 14)
  expect_equal(nrow(ok), 29)
  expect_equal(sum(de$initiative_budget), 133082267.48)
  expect_equal(sum(ok$initiative_budget), 204900000)
  # The largest line in each state, pinned: §0.1b turns on both.
  expect_equal(max(de$initiative_budget), 42500000)   # Delaware Medical School
  expect_equal(max(ok$initiative_budget), 43100000)   # Provider Collaborative Network
})

test_that("column resolution claims each column only once", {
  resolved <- rhtp_narrative_resolve_columns(
    c("state", "initiative", "fund_use", "amount_bp1", "lead_agency")
  )
  expect_equal(length(unique(unname(resolved$mapping))), length(resolved$mapping))
})


# -- Refusing rather than guessing -----------------------------------------

write_fixture <- function(sheets) {
  path <- withr::local_tempfile(fileext = ".xlsx", .local_envir = parent.frame())
  wb <- openxlsx::createWorkbook()
  for (nm in names(sheets)) {
    openxlsx::addWorksheet(wb, nm)
    openxlsx::writeData(wb, nm, sheets[[nm]])
  }
  openxlsx::saveWorkbook(wb, path, overwrite = TRUE)
  path
}

test_that("two equally-scoring sheets are refused, not guessed between", {
  twin <- tibble::tibble(
    state = "ZZ", initiative_name = c("A", "B"), initiative_budget = c(1, 2)
  )
  path <- write_fixture(list(`Sheet A` = twin, `Sheet B` = twin))

  expect_error(rhtp_narrative_pick_sheet(path), "Ambiguous initiative table")
})

test_that("a workbook with no initiative table errors with the sheet scores", {
  path <- write_fixture(list(
    Notes = tibble::tibble(comment = c("hello", "world")),
    Totals = tibble::tibble(label = "grand total", value = "not a number")
  ))

  expect_error(rhtp_narrative_pick_sheet(path), "No sheet in")
})

test_that("a sheet whose amount column is text does not qualify", {
  path <- write_fixture(list(
    Money = tibble::tibble(
      initiative_name = c("A", "B"), initiative_budget = c("$1,000", "$2,000")
    )
  ))

  expect_error(rhtp_narrative_pick_sheet(path), "No sheet in")
})

test_that("a workbook mixing two states is refused", {
  path <- write_fixture(list(
    Initiatives = tibble::tibble(
      state = c("DE", "OK"),
      initiative_name = c("A", "B"),
      initiative_budget = c(1, 2)
    )
  ))

  expect_error(rhtp_parse_narrative_workbook(path), "mixes 2 state codes")
})


# -- §7A.3 recipient_status ------------------------------------------------

test_that("a workbook's own recipient_status column always wins", {
  from_sheet <- readxl::read_excel(de_path, sheet = "Initiatives (Y1)")
  expect_equal(de$recipient_status, from_sheet$recipient_status)
})

test_that("the derivation reproduces Delaware's hand coding on every row", {
  from_sheet <- readxl::read_excel(de_path, sheet = "Initiatives (Y1)")
  derived <- rhtp_derive_recipient_status(from_sheet$named_recipient_or_contractor)

  expect_equal(derived, from_sheet$recipient_status)
})

test_that("Oklahoma derives NAMED on all 28 fund uses (§7A.5)", {
  # §7A.5: "Oklahoma names a Lead Agency for all 28 fund uses."
  expect_equal(unique(ok$recipient_status), "NAMED")
})

test_that("Delaware names a recipient for 4 of its 15 initiatives (§7A.5)", {
  expect_equal(sum(de$recipient_status %in% c("NAMED", "NAMED + TBD")), 4)
})

test_that("a quoted award-programme label is not read as a recipient", {
  # The §6.1 PROGRAM_NAME_AS_AWARDEE error, in the Stage 2.5 setting.
  expect_equal(
    rhtp_derive_recipient_status(
      "'Health System Training Program Awards' $18.51M - recipients TBD"
    ),
    "TBD"
  )
  expect_equal(
    rhtp_derive_recipient_status("'5 Subrecipient Awards, Contractors TBD'"),
    "TBD"
  )
})

test_that("the derivation errs toward TBD rather than inventing a recipient", {
  expect_equal(rhtp_derive_recipient_status("Contractor TBD"), "TBD")
  expect_equal(rhtp_derive_recipient_status("Technology vendor(s) TBD"), "TBD")
  expect_equal(rhtp_derive_recipient_status(NA_character_), "TBD")
  # A single-token organisation is under-claimed on purpose (§0.3).
  expect_equal(rhtp_derive_recipient_status("CareerTech"), "TBD")
})

test_that("lowercase connectors do not break a proper name", {
  expect_equal(rhtp_derive_recipient_status("University of Oklahoma (OU)"), "NAMED")
  expect_equal(
    rhtp_derive_recipient_status("Delaware Division of Libraries ($1.05M); Contractors TBD"),
    "NAMED + TBD"
  )
})


# -- Version and provenance ------------------------------------------------

test_that("a version token is read where one exists and left NA otherwise", {
  expect_equal(unique(de$budget_narrative_version), "Revised 1.30.26")
  expect_equal(unique(ok$budget_narrative_version), "Updated 03.10.26")
  expect_true(is.na(rhtp_derive_narrative_version("some_document.pdf")))
  expect_true(is.na(rhtp_derive_narrative_version(NA_character_)))
})

test_that("the state's own activity language is retained, and CMS categories are not invented", {
  # §7A.3: keep activity_type_raw, never discard it. The CMS allowable-use
  # crosswalk does not exist in this repo yet, so activity_type stays NA rather
  # than being guessed.
  expect_true(all(is.na(ok$activity_type)))
  expect_true(all(is.na(de$activity_type)))
  expect_equal(dplyr::n_distinct(ok$activity_type_raw), 6)
})

test_that("page_reference is carried as an explicit gap, not dropped", {
  # Neither reference workbook records one. §7A.3 wants it, so the column has
  # to exist and be visibly empty rather than silently absent.
  expect_true("page_reference" %in% names(de))
  expect_true(all(is.na(de$page_reference)))
})


# -- §8 and §10.2 assertions -----------------------------------------------

test_that("both reference states pass the §8 categorical checks", {
  expect_silent(rhtp_assert_initiative_categoricals(dplyr::bind_rows(de, ok)))
})

test_that("a flow_type outside the §8 vocabulary is refused", {
  bad <- de
  bad$flow_type[1] <- "PASS_THROUGH"
  expect_error(rhtp_assert_initiative_categoricals(bad), "flow_type outside")
})

test_that("a has_hospital_recipient = Yes row with no evidence is refused", {
  bad <- ok
  yes <- which(bad$has_hospital_recipient == "Yes")[1]
  bad$evidence_from_document[yes] <- NA_character_
  expect_error(rhtp_assert_initiative_categoricals(bad), "no ")
})

test_that("both reference states are internally consistent with §10.2", {
  expect_silent(rhtp_assert_flow_consistency(dplyr::bind_rows(de, ok)))
})

test_that("a flow_type contradicting has_hospital_recipient is refused", {
  # §10.2: PASS_THROUGH_UNRESOLVED is Unclear and may never be imputed to Yes.
  bad <- de
  row <- which(bad$flow_type == "PASS_THROUGH_UNRESOLVED")[1]
  bad$has_hospital_recipient[row] <- "Yes"

  expect_error(rhtp_assert_flow_consistency(bad), "contradicts")
})

test_that("mixed grain within one state is refused", {
  bad <- ok
  bad$initiative_grain[1] <- "INITIATIVE"
  expect_error(rhtp_assert_initiative_categoricals(bad), "mixed initiative_grain")
})


# -- §7A.4 The reconciliation gate -----------------------------------------

stated <- tibble::tibble(
  state = c("DE", "OK"),
  narrative_stated_total = c(
    rhtp_narrative_stated_total(de_path),
    rhtp_narrative_stated_total(ok_path)
  )
)

recon <- rhtp_reconcile_narratives(dplyr::bind_rows(de, ok), stated, allotments)
recon_de <- recon %>% dplyr::filter(state == "DE")
recon_ok <- recon %>% dplyr::filter(state == "OK")

test_that("a stated narrative total is read only where the document states one", {
  # Delaware: "Budget narrative TOTAL". Oklahoma states the award and the
  # allocated sum separately and states no grand total -- "Subtotal Direct" and
  # "Sum of BP1 fund-use allocations" must not be mistaken for one, or Oklahoma
  # would be misread as TOTAL_INCLUSIVE.
  expect_equal(stated$narrative_stated_total[stated$state == "DE"], 157394963.86)
  expect_true(is.na(stated$narrative_stated_total[stated$state == "OK"]))
})

test_that("the two §7A.4 structures are each recognised", {
  expect_equal(recon_de$reconciliation_structure, "TOTAL_INCLUSIVE")
  expect_equal(recon_ok$reconciliation_structure, "ALLOCATED_ONLY")
})

test_that("Oklahoma reconciles at 91.7%, which §7A.4 says is not a failure", {
  expect_equal(round(100 * recon_ok$reconciliation_pct, 1), 91.7)
  expect_equal(recon_ok$reconciliation_status, "RECONCILED")
  expect_true(recon_ok$publishable)
})

test_that("the gate catches Delaware's truncated extraction on its own", {
  # The committed extraction stops at Initiative 12. Its narrative total is
  # exact to $0.14 -- so a gate keyed on the STATED total would pass it. Keying
  # on what was actually captured is what makes the check work.
  expect_equal(round(100 * recon_de$reconciliation_pct, 1), 84.6)
  expect_equal(recon_de$reconciliation_status, "VARIANCE")
  expect_false(recon_de$publishable)
})

test_that("Delaware reconciles once initiatives 13-15 are added", {
  # $10,105,200 of contractual spending, per the workbook's own reconciliation
  # sheet. The remaining shortfall is state admin ($1,079,227.17) and indirect
  # ($13,128,269.21), which sit outside the initiative lines.
  completed <- dplyr::bind_rows(
    de,
    de[1, ] %>% dplyr::mutate(
      initiative_id = "DE-901", initiative_budget = 10105200
    )
  )

  filled <- rhtp_reconcile_narratives(completed, stated, allotments) %>%
    dplyr::filter(state == "DE")

  expect_equal(round(100 * filled$reconciliation_pct, 1), 91.0)
  expect_equal(filled$reconciliation_status, "RECONCILED")
  expect_true(filled$publishable)
})

test_that("the unreconciled remainder is exactly the missing lines plus admin and indirect", {
  expect_equal(
    round(recon_de$unreconciled_remainder, 2),
    round(10105200 + 1079227.17 + 13128269.21, 2)
  )
})

test_that("a state allocating more than its allotment is FAILED, not VARIANCE", {
  over <- ok %>% dplyr::mutate(initiative_budget = initiative_budget * 2)
  result <- rhtp_reconcile_narratives(over, stated, allotments) %>%
    dplyr::filter(state == "OK")

  expect_equal(result$reconciliation_status, "FAILED")
  expect_false(result$publishable)
})

test_that("a 60% parse goes to review, per §7A.4", {
  # "Reconciling at 91.7% is not a failure; reconciling at 60% is."
  thin <- ok %>% dplyr::mutate(initiative_budget = initiative_budget * 0.6)
  result <- rhtp_reconcile_narratives(thin, stated, allotments) %>%
    dplyr::filter(state == "OK")

  expect_equal(result$reconciliation_status, "VARIANCE")
  expect_false(result$publishable)
})

test_that("the 85% floor is the boundary §7A.4 sets", {
  target <- allotments$fy2026_allotment[allotments$state == "OK"]

  at_floor <- ok[1, ] %>% dplyr::mutate(initiative_budget = target * 0.85)
  just_under <- ok[1, ] %>% dplyr::mutate(initiative_budget = target * 0.8499)

  expect_equal(
    (rhtp_reconcile_narratives(at_floor, stated, allotments) %>%
       dplyr::filter(state == "OK"))$reconciliation_status,
    "RECONCILED"
  )
  expect_equal(
    (rhtp_reconcile_narratives(just_under, stated, allotments) %>%
       dplyr::filter(state == "OK"))$reconciliation_status,
    "VARIANCE"
  )
})

test_that("the 48 states with no narrative are NO_NARRATIVE, never zero spending", {
  # §6.4's lesson restated for Stage 2.5: absence in our extraction is a
  # statement about the extraction, not about the state.
  none <- recon %>% dplyr::filter(reconciliation_status == "NO_NARRATIVE")

  expect_equal(nrow(none), 48)
  expect_true(all(none$captured_total == 0))
  expect_true(all(is.na(none$reconciliation_structure)))
  expect_false(any(none$publishable))
  expect_equal(nrow(recon), 50)
})


# -- §0.1b The variance the gate is meant to preserve ----------------------

test_that("the parser reproduces the §0.1b hospital-directed shares", {
  # Oklahoma 48.7%, Delaware 15.7%. These are the headline numbers of §0.1b and
  # they come out of the parse rather than being carried over by hand.
  expect_equal(round(100 * recon_ok$hospital_directed_pct, 1), 48.7)
  expect_equal(round(100 * recon_de$hospital_directed_pct, 1), 15.7)
  expect_equal(round(100 * recon_ok$unclear_pct, 1), 17.1)
  expect_equal(round(100 * recon_de$unclear_pct, 1), 24.5)
})

test_that("no initiative budget is ever divided across recipients (§7A.5)", {
  # The single most damaging thing this project could do. There is no
  # per-recipient amount column for a sum to get wrong, and the budgets that
  # come out equal the budgets that went in.
  expect_false(any(stringr::str_detect(RHTP_INITIATIVE_SCHEMA, "per_recipient|recipient_amount")))

  from_sheet <- readxl::read_excel(de_path, sheet = "Initiatives (Y1)")
  expect_equal(sort(de$initiative_budget), sort(from_sheet$amount_y1))
})
