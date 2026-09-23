# test_03ar_rural_cut_report.R ------------------------------------------------
# Session 51. The rural cut of NAMED_HOSPITAL is a REPORT: the tests that carry
# its weight are the ones that fail if it starts inferring, or starts writing.

source(here::here("R", "03ar_rural_cut_report.R"))

rows <- rc_rows()

test_that("every NAMED_HOSPITAL row lands in exactly one class, and the partition is intact", {
  # Session 52: + New York's 35 hospital-lead rows and Kansas's 7 Emerging
  # Technology hospitals. Session 53: + Self Regional Healthcare (Greenwood
  # Pediatrics), $145,000 (§0.3a). Session 54: + VT 27, CT 2, WV 2 and MO's
  # 20 unpriced SMRP hospitals (+51 rows / +$57,215,819.43). Session 59: +TN's
  # two unpriced hospital rows ($0).
  expect_equal(nrow(rows), 1035L)
  expect_equal(round(sum(rows$amount, na.rm = TRUE), 2), 902386742.75,
               tolerance = 0)
  expect_true(all(rows$rural_class %in% RC_CLASSES))
  expect_silent(rc_assert(rows))
})

test_that("the rural figure is 180 rows / $176,578,205.56, from three classes of source only", {
  r <- rows[rows$counts_as_rural, ]
  # Session 51's 151 / $157,997,116.60, plus 13 NY and KS rows CMS enrols as
  # a CAH or REH by the CCN each row records (session 52).
  # Session 54: + 15 rows CMS enrols as a CAH -- 9 Vermont rows
  # ($4,705,216.17) and 6 of Missouri's unpriced SMRP hospitals ($0).
  # Session 59: + Macon Hospital, Inc (TN), which CMS enrols as a CAH (CCN
  # 441305) -- on a hand-read BRIDGE, and unpriced ($0).
  expect_equal(nrow(r), 180L)
  expect_equal(sum(r$state == "TN"), 1L)
  expect_equal(round(sum(r$amount, na.rm = TRUE), 2), 176578205.56, tolerance = 0)
  expect_equal(sum(r$state %in% c("NY", "KS")), 13L)
  expect_equal(sum(r$state == "VT"), 9L)
  expect_equal(sum(r$state == "MO"), 6L)
  expect_setequal(unique(r$rural_class), c("STATE_SOURCE_RURAL", "FEDERAL_RECORD_CCN"))
  # NOTHING the verifiers knew from general knowledge counts.
  expect_false(any(rows$counts_as_rural[rows$rural_class == "GENERAL_KNOWLEDGE_ONLY"]))
})

test_that("Delaware's recorded 'rural' is the SCHOOL's county, and it does not count", {
  de <- rows[rows$state == "DE", ]
  expect_equal(nrow(de), 4L)
  expect_true(all(de$rural_class == "SITE_NOT_RECIPIENT"))
  expect_false(any(de$counts_as_rural))
})

test_that("Florida's two URBAN hospitals are recorded as NOT rural", {
  fl <- rows[rows$rural_class == "STATE_SOURCE_NOT_RURAL", ]
  expect_equal(nrow(fl), 2L)
  expect_true(all(fl$state == "FL"))
  expect_false(any(fl$counts_as_rural))
})

test_that("a federal record is read by its OWN provider-type field, not by prose", {
  # Session 50's basis calls Progressive Health of Houston a 'critical access
  # hospital operator'. CMS enrols it as a RURAL EMERGENCY HOSPITAL -- rural,
  # not a CAH -- and Webster General as an ordinary hospital.
  ph <- rows[rows$awardee == "Progressive Health of Houston", ]
  expect_true(all(grepl("RURAL EMERGENCY HOSPITAL", ph$designation)))
  expect_true(all(ph$counts_as_rural))
  wb <- rows[rows$awardee == "Webster Healthcare Services, Inc.", ]
  expect_equal(nrow(wb), 1L)
  expect_match(wb$designation, "PART A PROVIDER - HOSPITAL$")
  expect_false(wb$counts_as_rural)
})

test_that("no rural status is inferred from a pool title or a state name", {
  # Mississippi's pool is called the Rural TECHNOLOGY Grant and Iowa's round
  # the Best and Brightest - RURAL Healthcare Workforce Recruitment. Neither
  # makes a recipient rural.
  expect_false(any(rows$counts_as_rural[rows$state == "IA"]))
  ms <- rows[rows$state == "MS", ]
  expect_true(all(ms$rural_class[!ms$counts_as_rural] %in%
                    c("NOT_RECORDED", "FEDERAL_RECORD_CCN")))
})

test_that("the committed report tables match a fresh computation, and no state file moved", {
  by <- readr::read_csv(here::here(RC_STATE_CSV), show_col_types = FALSE,
                        progress = FALSE)
  fresh <- rc_by_state(rows)
  expect_equal(nrow(by), nrow(fresh))
  expect_equal(sum(by$rural_rows), 180L)
  # ccn is character: session 54's Vermont CCNs include "47Z300".
  committed <- readr::read_csv(here::here(RC_ROWS_CSV), show_col_types = FALSE,
                               progress = FALSE,
                               col_types = readr::cols(ccn = "c"))
  expect_equal(nrow(committed), 1035L)
  expect_equal(committed$rural_class, rows$rural_class)
})
