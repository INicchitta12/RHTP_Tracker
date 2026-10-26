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
  # two unpriced hospital rows ($0). Session 61: + New Jersey, 35 rows /
  # $35,275,076 (none rural: no NJ awardee is a CAH or REH). Session 63: +
  # Indiana's 44 UNPRICED GROW hospital rows ($0). Session 64: + NV 15
  # unpriced, NE 6 / $1,825,002.28 (Initiative 5.3), SD 5 / $716,800 (Rural
  # Strong) -- 1,140 rows / $940,203,621.03 / 28 states. Session 69: +
  # Arkansas round 2 (RISE AR / HEART), 12 rows / $18,870,981.65, none with a
  # recorded rural designation -- 1,152 / $959,074,602.68.
  # Session 71: + 33 rows / $63,240,239.84 on CMS hospital enrolments (R/03bj).
  # Session 73: + UMMS, 1 row / $4,020,144, on its own stated form (R/03bk).
  # Session 74: + Vermont's 2026-09-25 update, 15 rows / $12,643,596.75.
  # Session 75: + Alaska's 2026-09-28 snapshot, net +1 row / +$2,414,763.
  # Session 82: + Colorado, 36 rows / $86,693,159.
  # Session 83: + National Jewish Health (MI, 1 row / $435,000, R/03bj on
  # CCN 060107), Alabama round 2 (R/03bq, 21 rows / $20,886,572) and NC's
  # SBHC roster (R/03br, FirstHealth 1 row / $0), no new state:
  # 1,261 / $1,149,408,077.27 / 31.
  # Sessions 85-86: + WV Minnie Hamilton, OK Doulas, RRR and CDM, and SD's
  # 2026-10-02 register: 1,288 / $1,190,363,515.42 / 31.
  # Session 87: + SD's Sanford Health and Avera Health, typed system parents
  # on the owner's resolution (2 / $7,007,000, LOW, no CCN); no new state:
  # 1,290 / $1,197,370,515.42 / 31.
  # Session 92: + Virginia's VHCF Provider Interoperability round (R/03bx),
  # 9 rows / $6,390,000 (4 lines / $690,000 on exact CMS VA records; Valley
  # Health, Ballad and Sentara, 4 system-parent lines / $5,700,000 LOW), a 32nd state (VA had
  # no NAMED_HOSPITAL row before): 1,299 / $1,203,760,515.42 / 32.
  # Session 94: + Vermont's 2026-10-02 update (R/03at), 9 rows / $9,581,283.08,
  # no new state: 1,308 / $1,213,341,798.50 / 32. Subtracted first.
  # Session 98: + CMS obligation-report rows (R/03cb), 5 / $3,124,401.49:
  # 1,313 / $1,216,466,199.99 / 32.
  # Session 99: + 12 rows / $8,668,315.59: 1,325 / $1,225,134,515.58 / 32.
  # Session 100: + WV's six 09-30 hospitals at $0: 1,331 / same / 32.
  # Session 101: MO SMRP priced, NV BP1 priced (+2 rows), VT 10-08 (+2 rows),
  # WV Vandalia (+1 row, $0): 1,336 / $1,309,664,382.63 / 32.
  # Session 102: + NV Intermountain/Renown system parents (2 / $1,010,206.00);
  # the published cut leaves out NV's 2 SOURCE_SUSPECT rows ($3,455,421.00):
  # 1,336 / $1,307,219,167.63 / 32.
  # Session 103: + TX's Rural Texas Strong list (201 / $117,571,194.73) and
  # OK's SSM St. Anthony Shawnee (1 / $1,623,498.82): 1,538 /
  # $1,426,413,861.18 / 33. Session 104: + 7 TX, + 9 MD Labor, + 22 OH:
  # 1,576 / $1,431,975,278.58 / 34. Session 107: + 2 WV, + 7 VA VHCF
  # Productivity: 1,585 / $1,439,954,278.58 / 34. Session 108: + 48 ID, + 76 TX,
  # + 31 VT, + 30 MS r2, + 5 OH, - 1 NY: 1,774 / $1,646,229,714.56 / 35.
  expect_equal(nrow(rows), 1774L)
  expect_equal(round(sum(rows$amount, na.rm = TRUE), 2), 1646229714.56,
               tolerance = 0)
  expect_equal(nrow(rows[rows$state != "TX", ]), 1490L)   # session 108: + 48 ID, + 31 VT, + 30 MS r2, + 5 OH, - 1 NY; session 107: + 2 WV, + 7 VA; session 104: + 9 MD, + 22 OH
  expect_true(all(rows$rural_class %in% RC_CLASSES))
  expect_silent(rc_assert(rows))
})

test_that("the rural figure is 268 rows / $282,660,793.99, from three classes of source only", {
  # 207 -> 209 in session 71 at the SAME dollars: Nevada's Carson Valley Health
  # and Washoe Barton Medical Clinic rows (unpriced) now carry CCN 291306,
  # which CMS enrols as a CRITICAL ACCESS HOSPITAL, read off the provider-type
  # field like every other federal-record row. None of the academic health
  # centres is a CAH or REH.
  r <- rows[rows$counts_as_rural, ]
  # Session 51's 151 / $157,997,116.60, plus 13 NY and KS rows CMS enrols as
  # a CAH or REH by the CCN each row records (session 52).
  # Session 54: + 15 rows CMS enrols as a CAH -- 9 Vermont rows
  # ($4,705,216.17) and 6 of Missouri's unpriced SMRP hospitals ($0).
  # Session 59: + Macon Hospital, Inc (TN), which CMS enrols as a CAH (CCN
  # 441305) -- on a hand-read BRIDGE, and unpriced ($0).
  # Session 64: + 3 Nebraska 5.3 rows ($554,850.55) and 3 South Dakota Rural
  # Strong rows ($323,300) that CMS enrols as a CAH by the row's own CCN.
  # Session 74: + 5 Vermont rows CMS enrols as a CAH (North Country,
  # Springfield, Copley, Porter, and Gifford Medical on a hand-read BRIDGE to
  # CCN 471301), $4,036,124.92.
  # Session 82: + 26 Colorado lines CMS enrols as a CAH by the line's own
  # CCN, $64,069,474.
  # Sessions 85-86: + 16 rows CMS enrols as a CAH by the row's own CCN -- WV
  # Minnie Hamilton x3 ($1,700,000), OK x7 ($8,376,713: Newman x2, Fairview x2,
  # McCurtain, Texas County, Cimarron) and SD x6 ($7,661,103). Huron Regional
  # carries no CCN and does not count.
  # Session 94: + 4 Vermont CAH rows by cited CCN (NVRH 471303, Grace Cottage
  # 471300 twice incl. the LOW Family Health bridge, Gifford Medical Center
  # 471301), +$4,074,310.60.
  # Session 98: + CHI Health St Marys x2 (NE, CMS obligation lines), CAH by
  # its cited CCN 281342, +$40,824.49.
  # Session 99: + Chase County Community Hospital (NE CMS line, CAH by its
  # cited CCN 281351, $87,732.10) and OK EMS/CP's Newman Memorial (CAH,
  # CCN 371336, $0). The three SD bridges (Monument 430077, Avera Heart
  # 430095, Prairie Lakes 430005A) are not CAHs and do not count.
  # Session 100: + 3 WV CAHs at $0 by their enrolment's provider type
  # (Preston 511312, Plateau 511317, Broaddus 511300). Webster 511301 enrols
  # as PART A PROVIDER - HOSPITAL and does not count.
  # Session 101: + NV's Banner Churchill RHIT row (CCN 291313, a CAH, owner-
  # approved bridge, $145,428.23); MO's six CAH rows now carry their SMRP
  # prices ($12,149,876.33) and NV's two CCN 291306 rows their BP1 figures
  # (Washoe Barton $2,458,060.00 -- SOURCE_SUSPECT -- and Carson Valley
  # $404,791.00): 268 / $282,660,793.99.
  # Session 102: Washoe Barton's FLEX-36 van is SOURCE_SUSPECT and the
  # published cut leaves it out (owner ruling): 267 / $280,202,733.99.
  # Session 103: + 140 TX rows whose CCN CMS enrols as a CAH
  # ($86,441,859.53); SSM St. Anthony Shawnee (370149) is not a CAH:
  # 407 / $366,644,593.52. Session 104: 410 / $367,023,056.72. Session 107:
  # + VA's Bath County Community Hospital (CAH 491300, $40,000): 411 / $367,063,056.72.
  # Session 108: + ID 42 ($79,078,939.69), + TX 43 ($42,184,742.57), + VT 14
  # ($10,055,239.34), + MS r2 8 ($2,276,055.92), by CAH/REH CCN: 518 / $500,658,034.24.
  expect_equal(nrow(r), 518L)
  expect_equal(sum(r$state == "TX"), 185L)
  expect_equal(sum(r$state == "ID"), 42L)
  expect_equal(round(sum(r$amount[r$state == "TX"], na.rm = TRUE), 2), 129005065.30)
  expect_equal(sum(r$state == "OK"), 8L)
  expect_equal(sum(r$state == "WV"), 6L)
  expect_equal(sum(r$state == "SD"), 9L)
  expect_equal(sum(r$state == "CO"), 26L)
  expect_equal(sum(r$state == "NV"), 2L)
  expect_equal(sum(r$state == "TN"), 1L)
  expect_equal(sum(r$state == "VA"), 1L)
  expect_equal(round(sum(r$amount, na.rm = TRUE), 2), 500658034.24, tolerance = 0)
  expect_equal(round(sum(r$amount[r$state != "TX"], na.rm = TRUE), 2), 371652968.94, tolerance = 0)  # OH Pomerene is $0
  expect_equal(round(sum(r$amount[r$state == "MO"], na.rm = TRUE), 2), 12149876.33)
  expect_equal(sum(r$state %in% c("NY", "KS")), 13L)
  expect_equal(sum(r$state == "VT"), 32L)
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
  # Session 63: + 21 Indiana GROW rows CMS enrols as a CAH ($0, unpriced).
  expect_equal(sum(by$rural_rows), 518L)   # session 108: + 42 ID, + 43 TX, + 14 VT, + 8 MS r2; session 107: + VA Bath County (CAH); session 104: + 3 TX CAH county bridges (Hardeman x2, Stonewall), - TX Memorial Hospital (no CCN), + OH Pomerene ($0); session 103: + 140 TX; session 102: - NV Washoe Barton (SOURCE_SUSPECT); session 101: + NV Banner Churchill RHIT; session 100: + 3 WV CAHs; session 99: + 2 (Chase County, OK Newman); session 82: + 26 CO; session 94: + 4 VT; session 98: + 2 NE
  # ccn is character: session 54's Vermont CCNs include "47Z300".
  committed <- readr::read_csv(here::here(RC_ROWS_CSV), show_col_types = FALSE,
                               progress = FALSE,
                               col_types = readr::cols(ccn = "c"))
  expect_equal(nrow(committed), 1774L)   # session 108: + 189 (ID TX VT MS r2 OH, - NY); session 107: + 2 WV, + 7 VA VHCF PP; session 104: + 7 TX, + 9 MD Labor, + 22 OH; session 103: + 201 TX, + 1 OK; session 101: + 5 (NV 2, VT 2, WV 1); session 100: + 6 WV; session 99: + 12; session 98: + 5 CMS obligation rows; session 82: + 36 CO; session 83: + 23; session 87: + 2 SD; session 92: + 9 VA; session 94: + 9 VT
  expect_equal(committed$rural_class, rows$rural_class)
})
