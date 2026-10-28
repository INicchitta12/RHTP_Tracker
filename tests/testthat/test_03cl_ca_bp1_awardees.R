# California -- HCAI's "Recommended Subrecipients for CalRHT Budget Period 1"
# (2026-10-21), extracted session 109 as INTENTS (R/03cl).

source(here::here("R", "03cl_ca_bp1_awardees.R"))

d <- car_read()
a <- ca_bp1_awardees(d)
committed <- readr::read_csv(here::here(CAR_OUT), show_col_types = FALSE)

test_that("the roster reads as recorded: 108 rows, $138,464,043.97, five grant tables", {
  expect_silent(car_assert_roster(d))
  expect_equal(nrow(d), 108L)
  expect_equal(round(sum(d$amount), 2), 138464043.97)
  by <- tapply(d$amount, d$award_pool, length)
  expect_equal(as.integer(by[CAR_GRANTS$award_pool]), CAR_GRANTS$rows)
})

test_that("the prose total is NOT reconciled and NOT forced (owner instruction)", {
  expect_equal(round(CAR_PROSE - sum(d$amount), 2), 28255956.03)
  # Row counts equal HCAI's stated grant counts by initiative; dollars do not.
  n <- table(d$initiative)
  expect_equal(as.integer(n[c("Transformative Care Model", "Workforce Development", "Technology and Tools")]),
               c(34L, 65L, 9L))
  expect_true(all(grepl("UNRECONCILED, NOT FORCED", a$amount_basis, fixed = TRUE)))
  expect_true(all(grepl("gap $28,255,956.03", a$amount_basis, fixed = TRUE)))
  # Nothing imputed: every amount is the printed one.
  expect_equal(a$amount, d$amount)
})

test_that("every row is an INTENT", {
  expect_true(all(a$validation_source_type == "NOTICE_OF_INTENT_TO_AWARD"))
  expect_true(all(a$amount_confirmed == "No"))
  expect_true(all(grepl("AMOUNT_PRELIMINARY", a$flag_reason, fixed = TRUE)))
  # A page that stops calling the list tentative fails the build.
  expect_true(all(vapply(CAR_TENTATIVE, function(x)
    grepl(x, stringr::str_squish(rvest::html_text2(car_html(CAR_FILE))), fixed = TRUE), logical(1))))
})

test_that("the hospital figure, and what subtracts from it", {
  h <- a[a$hospital_attribution == "NAMED_HOSPITAL", ]
  # Session 110 (owner rulings a, b): + UC San Diego Health ($498,854, AHC),
  # - Providence Medical Foundation ($450,000): 59 / $82,852,823.14.
  expect_equal(nrow(h), 59L)
  expect_equal(round(sum(h$amount), 2), 82852823.14)
  expect_true(all(h$recipient_type == "HOSPITAL_OR_SYSTEM" & h$flow_type == "DIRECT"))
  expect_false(any(a$determination_confidence == "HIGH"))
  expect_false(any(a$distributed_to_hospital == "Unclear"))
  # System parents and hospital foundations: LOW, GENERAL_KNOWLEDGE, no CCN.
  gk <- h[h$basis_type %in% "GENERAL_KNOWLEDGE", ]
  expect_setequal(gk$awardee, c("Adventist Health System/West", "NorthBay Healthcare Corporation",
                                "Banner Health Foundation", "UC San Diego Health",
                                "Sierra Nevada Memorial Hospital Foundation"))
  expect_equal(round(sum(gk$amount), 2), 4419904.53)
  expect_true(all(is.na(gk$ccn)) && all(gk$determination_confidence == "LOW"))
  expect_equal(round(sum(h$amount[h$determination_confidence == "LOW"]), 2), 20142121.19)
  expect_equal(h$recipient_subtype[h$awardee == "UC San Diego Health"], "ACADEMIC_HEALTH_CENTER")
  # Transformative Payments: eleven named hospitals, all hospital rows.
  tp <- a[a$award_pool == "Transformative Payments", ]
  expect_equal(nrow(tp), 11L)
  expect_true(all(tp$hospital_attribution == "NAMED_HOSPITAL"))
})

test_that("hand reads that keep dollars OUT of the hospital figure", {
  # Session 110 (owner ruling a): the campus and collaborative strings stay
  # non-hospital; only 'UC San Diego Health' (the health system) is a hospital row.
  u <- a[grepl("San Diego", a$awardee) & a$recipient_type == "UNIVERSITY_OR_AHC", ]
  expect_equal(nrow(u), 2L)
  expect_true(all(u$distributed_to_hospital == "No"))
  # Session 110 (owner ruling b): a California medical foundation operates clinics.
  p <- a[a$awardee == "Providence Medical Foundation", ]
  expect_equal(p$recipient_type, "PHYSICIAN_PRACTICE")
  expect_equal(p$distributed_to_hospital, "No")
  # An MCO is never a hospital type.
  expect_equal(a$recipient_type[a$awardee == "Inland Empire Health Plan"], "MANAGED_CARE_ORGANIZATION")
  # FQHC/RHC records win over a hospital-shaped name (SAC Health System,
  # Sequoia Family Medical Center), and an FQHC foundation is not a hospital's.
  for (x in c("SAC Health System", "Sequoia Family Medical Center", "San Benito Health Foundation")) {
    expect_equal(a$recipient_type[a$awardee == x], "FQHC_OR_RHC", info = x)
  }
  # The FM-OB Fresno row names a programme, not an organisation.
  f <- a[grepl("^Maternal Child Health Fellowship", a$awardee), ]
  expect_equal(f$distributed_to_hospital, "No")
  expect_match(f$flag_reason, "RECIPIENT_TYPE_INFERRED", fixed = TRUE)
})

test_that("CCNs are the DBA's own record, and a two-entity match is hand-read", {
  ccn <- function(x) unique(a$ccn[a$awardee == x])
  expect_equal(ccn("Mercy Medical Center Mt. Shasta"), "051319")   # Dignity Health DBA
  expect_equal(ccn("St. Elizabeth Community Hospital"), "050042")  # Dignity Health DBA
  expect_equal(ccn("Adventist Health Sonora"), "050335")
  expect_equal(ccn("Good Samaritan Hospital, LP"), "050257")       # Bakersfield, not San Jose
  expect_true(is.na(ccn("Mercy Medical Center – Northern California Maternity Collaborative")))
})

test_that("the committed file is what the builder produces", {
  expect_equal(committed$awardee, a$awardee)
  expect_equal(round(committed$amount, 2), round(a$amount, 2))
  expect_equal(committed$distributed_to_hospital, a$distributed_to_hospital)
  expect_equal(committed$hospital_attribution, a$hospital_attribution)
  expect_equal(unique(committed$validator), "R/03cl_ca_bp1_awardees.R")
  expect_silent(car_assert_typing(a))
})
