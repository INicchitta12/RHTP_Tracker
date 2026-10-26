# test_03ce_tx_rts_awardees.R -------------------------------------------------
# Session 103. Texas: HHSC's weekly Rural Texas Strong "Intent to Award" list,
# typed on CMS's TX enrolment files. Session 108: the 10/23 list (441 lines,
# a County column, sub-initiatives).

suppressWarnings(suppressMessages(source(here::here("R", "03ce_tx_rts_awardees.R"))))

tx <- tx_rts_awardees()
committed <- readr::read_csv(TRT_CSV, show_col_types = FALSE,
                             col_types = readr::cols(ccn = "c", .default = readr::col_guess()))

test_that("the 10/23 list is read whole and the release reconciles to the cent", {
  expect_silent(tx_rts_assert_list())
  expect_silent(tx_rts_assert_reconciles())
  expect_silent(tx_rts_assert_release())
  expect_equal(nrow(tx), 441L)
  expect_equal(round(sum(tx$amount), 2), 224591245.41)
  expect_equal(sum(tx$list_section == "Added Oct. 23, 2026"), 129L)
  expect_equal(sum(tx$contract_executed == "Yes"), 159L)
  expect_true(all(nzchar(tx$county)))
  # 10/8 list: $129,089,434.73 = the release's $78,089,434.73 + 68 x $750,000.
  prior <- tx_rts_read(here::here(TRT_SOURCES$file[TRT_SOURCES$key == "prior"]))
  expect_equal(round(sum(prior$amount[prior$contract_executed == "No"]), 2), 78089434.73)
  expect_equal(sum(prior$contract_executed == "No"), 216L)
})

test_that("the committed file is what the builder produces", {
  expect_equal(nrow(committed), nrow(tx))
  expect_equal(committed$awardee, tx$awardee)
  expect_equal(round(committed$amount, 2), round(tx$amount, 2))
  expect_equal(committed$distributed_to_hospital, tx$distributed_to_hospital)
})

test_that("intents are preliminary, executed contracts are confirmed", {
  ex <- tx$contract_executed == "Yes"
  expect_true(all(tx$amount_confirmed[ex] == "Yes"))
  expect_true(all(tx$amount_confirmed[!ex] == "No"))
  expect_true(all(grepl("AMOUNT_PRELIMINARY", tx$flag_reason[!ex])))
  expect_true(all(tx$validation_source_type == "NOTICE_OF_INTENT_TO_AWARD"))
})

test_that("the hospital figure and its LOW bridges", {
  h <- tx[tx$distributed_to_hospital == "Yes", ]
  # Session 104: 208 / $119,558,582.13 on the 10/14 list. Session 108, the
  # 10/23 list: 285 / $189,634,041.13 with the one SOURCE_SUSPECT hospital row
  # (Anson Hospital District, $509,936.50), 284 / $189,124,104.63 without it.
  expect_equal(nrow(h), 285L)
  expect_equal(round(sum(h$amount), 2), 189634041.13)
  low <- h[h$determination_confidence == "LOW", ]
  expect_equal(nrow(low), 90L)
  expect_equal(round(sum(low$amount), 2), 58965817.23)
  expect_true(all(h$hospital_attribution == "NAMED_HOSPITAL"))
  expect_false(any(tx$determination_confidence == "HIGH"))
})

test_that("session 104 county test: bridge only where one enrolled hospital sits in the county", {
  expect_silent(tx_rts_assert_county_bridges())
  cb <- tx[tx$awardee %in% setdiff(names(TRT_COUNTY_OF), "Winnie Stowell Hospital District"), ]
  # Session 108: 'UT Health Henderson' is now printed 'Henderson Hospital, LLC',
  # an EXACT record, so six hand-coded county bridges remain.
  expect_equal(nrow(cb), 6L)
  expect_true(all(cb$distributed_to_hospital == "Yes"))
  expect_true(all(cb$determination_confidence == "LOW"))
  expect_equal(sort(unique(cb$ccn)), sort(c("451352", "451318", "450055", "450092", "450698")))
  expect_true(all(grepl("COUNTY-TEST BRIDGE", cb$determination_basis)))
  expect_silent(tx_rts_assert_list_county(tx))
  # Session 108, on the list's own County: Menard County holds no enrolled
  # hospital, so its district stays NON_HOSPITAL.
  ws <- tx[grepl("DISTRICT_NOT_ENROLLED", tx$recipient_type_source), ]
  expect_equal(unique(ws$awardee), "Menard County Hospital District")
  expect_true(all(ws$distributed_to_hospital == "No"))
  expect_true(all(ws$recipient_type == "LOCAL_GOVT_OR_PUBLIC_HEALTH"))
  # Winnie Stowell's line now names GHC Hemphill Operations, LLC.
  expect_false("Winnie Stowell Hospital District" %in% tx$awardee)
  # The two not reached by the county test stay off the hospital rows.
  expect_true(all(tx$distributed_to_hospital[grepl("Principle|Trinity Clinic", tx$awardee)] == "No"))
})

test_that("every BP1 district corresponds to exactly one Initiative 1 line", {
  expect_silent(tx_rts_assert_bp1(tx))
  # Session 108: the list's County ("Moore") places it; one enrolled hospital
  # in Moore County, so a county-test bridge to CAH 451386, LOW.
  m <- tx[tx$awardee == "Memorial Hospital", ]
  expect_equal(m$ccn, "451386")
  expect_equal(m$county, "Moore")
  expect_equal(m$distributed_to_hospital, "Yes")
  expect_equal(m$determination_confidence, "LOW")
  expect_match(m$determination_basis, "COUNTY-TEST BRIDGE ON THE LIST'S OWN COUNTY", fixed = TRUE)
})

test_that("session 108: the three self-contradicting lines are SOURCE_SUSPECT, carried as printed", {
  s <- tx[grepl("SOURCE_SUSPECT", tx$flag_reason), ]
  expect_equal(sort(s$awardee), sort(TRT_SOURCE_SUSPECT$awardee))
  expect_true(all(s$amount > s$total_award_amount))
  part <- rhtp_hospital_dollar_partition(tx)
  expect_equal(round(part$dollars[part$bucket == "NAMED_HOSPITAL"], 2), 189124104.63)
  # The re-priced line is recorded, not silently absorbed.
  expect_equal(nrow(TRT_AMENDED), 1L)
})

test_that("Christus Trinity Clinic is a physician group, not a hospital", {
  ct <- tx[grepl("Trinity Clinic", tx$awardee), ]
  expect_equal(nrow(ct), 13L)
  expect_true(all(ct$recipient_type == "PHYSICIAN_PRACTICE"))
})

test_that("the probe's list watch trips on a new link and not on the extracted one", {
  ok <- paste0('<a href="', TRT_LIST_PATH, '">list</a>')
  expect_null(tx_rts_live_finding(ok)$finding)
  new <- '<a href="/sites/default/files/documents/rural-hlth-prgm/10-22-2026-list-award-recipients.xlsx">x</a>'
  expect_match(tx_rts_live_finding(new)$finding, "RURAL TEXAS STRONG LIST")
  expect_match(tx_rts_live_finding("<p>none</p>")$finding, "NO award-recipient list")
})
