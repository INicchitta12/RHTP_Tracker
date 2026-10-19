# test_03ce_tx_rts_awardees.R -------------------------------------------------
# Session 103. Texas: HHSC's weekly Rural Texas Strong "Intent to Award" list,
# typed on CMS's TX enrolment files.

suppressWarnings(suppressMessages(source(here::here("R", "03ce_tx_rts_awardees.R"))))

tx <- tx_rts_awardees()
committed <- readr::read_csv(TRT_CSV, show_col_types = FALSE,
                             col_types = readr::cols(ccn = "c", .default = readr::col_guess()))

test_that("the 10/14 list is read whole and the release reconciles to the cent", {
  expect_silent(tx_rts_assert_list())
  expect_silent(tx_rts_assert_reconciles())
  expect_silent(tx_rts_assert_release())
  expect_equal(nrow(tx), 312L)
  expect_equal(round(sum(tx$amount), 2), 137234879.62)
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
  expect_equal(nrow(h), 201L)
  expect_equal(round(sum(h$amount), 2), 117571194.73)
  low <- h[h$determination_confidence == "LOW", ]
  expect_equal(nrow(low), 80L)
  expect_equal(round(sum(low$amount), 2), 54468593.79)
  expect_true(all(h$hospital_attribution == "NAMED_HOSPITAL"))
  expect_false(any(tx$determination_confidence == "HIGH"))
})

test_that("districts with no enrolment are not hospital rows (Hardeman precedent)", {
  dn <- tx[tx$awardee %in% TX_RTS_DISTRICTS_NOT_ENROLLED$awardee, ]
  expect_equal(nrow(dn), 6L)
  expect_true(all(dn$distributed_to_hospital == "No"))
  expect_true(all(dn$recipient_type == "LOCAL_GOVT_OR_PUBLIC_HEALTH"))
  expect_true(any(grepl("HARDEMAN COUNTY MEMORIAL HOSP", dn$determination_basis)))
})

test_that("every BP1 district corresponds to exactly one Initiative 1 line", {
  expect_silent(tx_rts_assert_bp1(tx))
  m <- tx[tx$awardee == "Memorial Hospital", ]
  expect_equal(m$ccn, "451386")
  expect_match(m$determination_basis, "BY ELIMINATION")
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
