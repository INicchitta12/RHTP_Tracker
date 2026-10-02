# test_03i_sd_rht_contracts.R ------------------------------------------------
# South Dakota's RHTP contracts on the state transparency portal. Reads the
# committed archives and CSV off disk -- no network, no quota.
#
# Session 12 wrote this file as a NEGATIVE: $121.5M announced across two
# rounds, none of it on open.sd.gov, $5.6M of administrative contracts there
# instead. Session 64 found the negative had half-expired: the RHT series now
# carries 8 of the 28 Rural Strong grants. These tests keep the two POOLS apart,
# keep the Rural Strong contracts INSIDE the $31.5M round rather than on top of
# it, and keep the $90M round's absence attached to the file.

library(testthat)

source(here::here("R", "03i_sd_rht_contracts.R"))

records <- rhtp_sd_records()


test_that("every South Dakota assertion passes", {
  expect_true(rhtp_sd_assert(records))
})

test_that("the committed CSV matches a fresh parse of the committed archives", {
  fresh <- rhtp_sd_build()
  expect_equal(nrow(fresh), nrow(records))
  expect_equal(fresh$contract_number, records$contract_number)
  expect_equal(fresh$amount, records$amount)
  expect_equal(fresh$recipient_type, records$recipient_type)
})


# -- What was extracted ------------------------------------------------------

test_that("41 contracts in the RHT series, $26,836,144, in three pools", {
  # Session 86: the 2026-10-02 re-read added 15 contracts, +$17,612,967.
  expect_equal(nrow(records), 41L)
  expect_equal(sum(records$amount), 26836144)
  expect_true(all(grepl("RHT", records$contract_number)))
  rs <- records$round_id %in% "RS"
  un <- records$round_id %in% "UNPLACED"
  expect_equal(sum(rs), 14L)
  expect_equal(sum(records$amount[rs]), 15967960)
  expect_equal(sum(un), 8L)
  expect_equal(sum(records$amount[un]), 3175112)
  expect_equal(sum(!rs & !un), 19L)
  expect_equal(sum(records$amount[!rs & !un]), 7693072)
  expect_setequal(unique(records$award_pool),
                  c(SD_POOL_ADMIN, SD_POOL_RS, SD_POOL_UNPLACED))
})

test_that("the 15 contracts of 2026-10-02: 6 Rural Strong, 8 unplaced, 1 admin", {
  late <- records[records$first_seen_archive == SD_SEARCH_ARCHIVES[3], ]
  expect_equal(nrow(late), 15L)
  expect_equal(sum(late$amount), 17612967)
  expect_equal(sum(late$round_id %in% "RS"), 6L)
  expect_equal(sum(late$amount[late$round_id %in% "RS"]), 14088808)
  expect_equal(sort(late$contract_number[late$round_id %in% "UNPLACED"]),
               sort(SD_PLACEMENT$contract_number[SD_PLACEMENT$pool == "UNPLACED"]))
  expect_equal(late$contract_number[is.na(late$round_id)], "27RHT00029")
})

test_that("none of the 15 is added on top of the $121.5M announced", {
  rs <- records$round_id %in% "RS"
  un <- records$round_id %in% "UNPLACED"
  # Rural Strong inside its round; unplaced capped at the $90M round; the two
  # together inside the $121.5M.
  expect_lte(sum(records$amount[rs]), SD_RS_ROUND_AMOUNT)
  expect_lte(sum(rs), SD_RS_ROUND_GRANTS)
  expect_lte(sum(records$amount[un]), SD_TD_ROUND_AMOUNT)
  expect_lte(sum(un), SD_TD_ROUND_GRANTS)
  expect_lte(sum(records$amount[rs | un]), SD_RS_ROUND_AMOUNT + SD_TD_ROUND_AMOUNT)
  expect_true(all(grepl("in\\s+neither case is it ever added to a round total",
                        records$determination_basis[un])))
  # and the round file carries NO amount, so the union counts each dollar once
  rounds <- readr::read_csv(here::here("data", "reference", "sd_year1_awardees.csv"),
                            show_col_types = FALSE)
  expect_true(all(is.na(rounds$amount)))
  expect_true(all(rounds$distributed_to_hospital != "Yes"))
  # an inflated unplaced pool is refused
  bad <- records
  bad$amount[which(un)[1]] <- 95000000
  expect_error(rhtp_sd_assert(bad), "UNPLACED pool")
})

test_that("a new non-Rural-Strong contract with no hand placement fails the build", {
  saved <- SD_PLACEMENT
  on.exit(SD_PLACEMENT <<- saved)
  SD_PLACEMENT <<- SD_PLACEMENT[SD_PLACEMENT$contract_number != "27RHT00039", ]
  expect_error(rhtp_sd_build(), "no hand placement")
})

test_that("the 13 contracts of 2026-08-28 keep rows 1-13 and their amounts", {
  # Session 12's rows are appended to, never re-ordered.
  first13 <- c("26RHT00002", "26RHT00003", "26RHT00004", "26RHT00006",
               "27RHT00001", "27RHT00005", "27RHT00007", "27RHT00008",
               "27RHT00009", "27RHT00010", "27RHT00011", "27RHT00012",
               "27RHT00013")
  expect_equal(records$contract_number[1:13], first13)
  expect_equal(sum(records$amount[1:13]), 5618367)
  expect_true(all(records$first_seen_archive[1:13] == SD_SEARCH_ARCHIVES[1]))
  expect_true(all(records$first_seen_archive[14:26] == SD_SEARCH_ARCHIVES[2]))
  expect_true(all(records$first_seen_archive[27:41] == SD_SEARCH_ARCHIVES[3]))
})

test_that("the fourteen Rural Strong grants are exactly the register's own read", {
  rs <- records[records$round_id %in% "RS", ]
  expect_setequal(rs$contract_number,
                  c("27RHT00015", "27RHT00016", "27RHT00017", "27RHT00018",
                    "27RHT00022", "27RHT00023", "27RHT00024", "27RHT00025",
                    "27RHT00028", "27RHT00030", "27RHT00031", "27RHT00032",
                    "27RHT00033", "27RHT00034"))
  expect_true(all(grepl(SD_RURAL_STRONG_PATTERN, rs$description, fixed = TRUE)))
  # Seven are posted as GRANTS carrying CFDA 93.798; the University of South
  # Dakota's is posted as a "Contract with State or Local Government Agency"
  # and carries no CFDA block. Its own description still says Rural Strong
  # Grant, which is what the pool keys on.
  grants <- rs[!is.na(rs$cfda_number), ]
  expect_equal(nrow(grants), 13L)
  expect_true(all(as.character(grants$cfda_number) == "93.798"))
  expect_equal(rs$awardee[is.na(rs$cfda_number)], "UNIVERSITY OF SOUTH DAKOTA")
})

test_that("no ADMINISTRATIVE dollar reaches a hospital; 11 RS and 3 unplaced rows do", {
  admin <- records[is.na(records$round_id), ]
  expect_true(all(admin$distributed_to_hospital == "No"))
  hosp <- records[records$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(hosp), 14L)
  expect_equal(sum(hosp$amount), 16643252)
  expect_equal(sum(hosp$round_id == "RS"), 11L)
  expect_equal(sum(hosp$amount[hosp$round_id == "UNPLACED"]), 1837644)
  expect_true(all(hosp$recipient_type == "HOSPITAL_OR_SYSTEM"))
})

test_that("Sanford Health and Avera Health are system parents, typed LOW on general knowledge", {
  # Owner's resolution of SD_SYSTEM_PARENTS_FORM_NOT_STATED (session 87): no SD
  # hospital enrolment carries either string, so no CCN; HOSPITAL_OR_SYSTEM at
  # LOW with basis_type GENERAL_KNOWLEDGE, subtractable from any figure.
  par <- records[records$awardee %in% c("SANFORD HEALTH", "AVERA HEALTH"), ]
  expect_equal(nrow(par), 2L)
  expect_setequal(par$contract_number, c("27RHT00031", "27RHT00034"))
  expect_equal(sum(par$amount), 7007000)
  expect_true(all(par$recipient_type == "HOSPITAL_OR_SYSTEM"))
  expect_true(all(par$distributed_to_hospital == "Yes"))
  expect_true(all(par$flow_type == "DIRECT"))
  expect_true(all(par$determination_confidence == "LOW"))
  expect_true(all(par$basis_type == "GENERAL_KNOWLEDGE"))
  expect_true(all(is.na(par$ccn)))
  expect_true(all(par$round_id == "RS"))
  # Nothing else in the file is general knowledge.
  expect_equal(sum(records$basis_type %in% "GENERAL_KNOWLEDGE"), 2L)
})

test_that("the two Community Memorial Hospitals are two hospitals, not one", {
  # Burke and Redfield, one string, told apart only by the vendor city.
  cmh <- records[records$awardee == "COMMUNITY MEMORIAL HOSPITAL", ]
  expect_equal(nrow(cmh), 2L)
  expect_setequal(toupper(cmh$vendor_city), c("BURKE", "REDFIELD"))
})

test_that("Philip Health Services is a hospital on the FEDERAL RECORD, not its name", {
  philip <- records[records$awardee == "PHILIP HEALTH SERVICES INC", ]
  expect_equal(nrow(philip), 1L)
  expect_equal(philip$classification_rule, "FEDERAL_RECORD")
  expect_equal(as.character(philip$ccn), "431319")
  expect_equal(philip$determination_confidence, "MEDIUM")
  expect_match(philip$recipient_type_source, "CMS Hospital Enrollments")
  # the name alone gives §8's fallback -- the counterfactual
  alone <- rhtp_classify_recipient_type("PHILIP HEALTH SERVICES INC", "SD")
  expect_equal(alone$recipient_type, "NONPROFIT_CBO")
})

test_that("the CMS match is exact and city-keyed, never a stem", {
  cms <- rhtp_sd_cms_hospitals()
  expect_equal(nrow(rhtp_sd_cms_match("PHILIP HEALTH SERVICES", "PHILIP", cms)), 0L)
  expect_equal(nrow(rhtp_sd_cms_match("PHILIP HEALTH SERVICES INC", "PIERRE", cms)), 0L)
  # the two FQHC Rural Strong vendors are NOT re-typed from any CMS file
  fq <- records[records$awardee %in% c("COMPLETE HEALTH CENTER OF BH",
                                       "SD URBAN INDIAN HEALTH"), ]
  expect_true(all(fq$distributed_to_hospital == "No"))
  expect_false(any(fq$classification_rule == "FEDERAL_RECORD"))
})


# -- What was NOT extracted, and why -----------------------------------------

test_that("the reconciliation names the partial round and the absent round", {
  recon <- rhtp_sd_reconcile(records)
  v <- function(m) recon$value[recon$measure == m]
  expect_match(v("Rural Strong grant contracts on the register"), "^14 of the 28")
  expect_match(v("relationship"), "INSIDE the round total")
  expect_match(v("Rural Strong grants not yet on the register"), "NOT computed")
  expect_match(v("Technology/data round announced 2026-08-19"),
               "NO contract on open.sd.gov names this round")
  expect_match(v("RHTP contracts OUTSIDE the RHT series (not extracted)"),
               "27SC091800")
})

test_that("every row says in its own basis how it relates to the rounds", {
  rs <- records$round_id %in% "RS"
  admin <- is.na(records$round_id)
  expect_true(all(grepl("NOT part of", records$determination_basis[admin])))
  expect_true(all(grepl("INSIDE that round total and NEVER in addition",
                        records$determination_basis[rs])))
})

test_that("the Rural Strong contracts sit inside the round, and the file refuses otherwise", {
  rs <- records$round_id %in% "RS"
  expect_lte(sum(records$amount[rs]), SD_RS_ROUND_AMOUNT)
  expect_lte(sum(rs), SD_RS_ROUND_GRANTS)
  bloated <- records
  bloated$amount[which(rs)[1]] <- 40000000
  expect_error(rhtp_sd_assert(bloated), "exceed the round")
})

test_that("an administrative pool that stops being administrative fails loudly", {
  inflated <- records
  inflated$amount[1] <- 90000000
  expect_error(rhtp_sd_assert(inflated), "far beyond the administrative spend")
})

test_that("a row that moves between pools is refused", {
  moved <- records
  moved$round_id[1] <- "RS"
  expect_error(rhtp_sd_assert(moved), "disagree")
})


# -- The detail-page parser --------------------------------------------------

test_that("the two detail-page shapes both parse, and the glossary never bleeds in", {
  # A CONTRACT page carries Solicitation Type and the "* If an image" footer; a
  # GRANT page carries neither, and ends with the portal's CFDA block. Keying
  # the description on the contract footer ran it into the CFDA GLOSSARY text
  # on grant pages -- boilerplate quoted as the state's own description, and fed
  # to the §10.2 flow rules.
  expect_false(any(grepl("Catalog of Federal Domestic Assistance",
                         records$description)))
  expect_true(all(nzchar(records$description)))

  contracts <- records[!is.na(records$solicitation_type), ]
  grants <- records[is.na(records$solicitation_type), ]
  expect_gt(nrow(contracts), 0L)
  expect_gt(nrow(grants), 0L)
})

test_that("the grant pages carry CFDA 93.798, which is RHTP itself", {
  # Independent corroboration that these rows are Rural Health Transformation
  # and not some other DOH programme that happens to share a number series.
  cfda <- stats::na.omit(records$cfda_number)
  expect_gt(length(cfda), 0L)
  expect_true(all(cfda == "93.798"))
})

test_that("descriptions are the full text, not the search table's truncation", {
  # The search table cuts at ~75 characters and ends in "...". Coding from that
  # would quote a truncation as the state's own words.
  expect_false(any(grepl("\\.\\.\\.$", records$description)))
  expect_gt(max(nchar(records$description)), 75L)
})


# -- Evidence ----------------------------------------------------------------

test_that("the search results and every detail page are archived", {
  for (f in c(SD_SEARCH_ARCHIVES, SD_DESC_SEARCHES$file)) {
    expect_true(file.exists(here::here(SD_EVIDENCE_DIR, f)), info = f)
  }
  expect_true(file.exists(here::here(SD_EVIDENCE_DIR, SD_MANIFEST_FILE)))
  for (n in records$contract_number) {
    expect_true(file.exists(here::here(SD_EVIDENCE_DIR, SD_DETAIL_SUBDIR,
                                       paste0(n, ".html"))), info = n)
  }
})

test_that("every file the manifest lists verifies against its archived bytes", {
  manifest <- readLines(here::here(SD_EVIDENCE_DIR, SD_MANIFEST_FILE))
  files <- sub("^\\s*file\\s*:\\s*", "", grep("^\\s*file\\s*:", manifest, value = TRUE))
  shas  <- sub("^\\s*sha256\\s*:\\s*", "", grep("^\\s*sha256\\s*:", manifest, value = TRUE))
  expect_equal(length(files), length(shas))
  for (k in seq_along(files)) {
    actual <- digest::digest(readr::read_file(here::here(SD_EVIDENCE_DIR, files[k])),
                             algo = "sha256", serialize = FALSE)
    expect_equal(actual, shas[k], info = files[k])
  }
  # every search archive and every row's detail page is listed
  expect_true(all(c(SD_SEARCH_ARCHIVES, SD_DESC_SEARCHES$file) %in% files))
  expect_true(all(paste0(SD_DETAIL_SUBDIR, "/", records$contract_number, ".html")
                  %in% files))
})

test_that("the manifest keeps the 2026-08-28 negative AND records the refresh", {
  manifest <- paste(readLines(here::here(SD_EVIDENCE_DIR, SD_MANIFEST_FILE)),
                    collapse = " ")
  expect_true(grepl("NOT SOUTH DAKOTA'S SUBAWARD LIST", manifest))
  expect_true(grepl("REFRESH 2026-09-24", manifest))
  expect_true(grepl("REFRESH 2026-10-02", manifest))
  expect_true(grepl("never to be added", manifest))
})

test_that("the archived CMS enrolment files verify against their manifest", {
  man <- readLines(here::here(SD_FEDERAL_DIR, "MANIFEST.txt"))
  rows <- grep("^cms_.*\\.json \\|", man, value = TRUE)
  expect_equal(length(rows), 3L)
  for (r in rows) {
    parts <- trimws(strsplit(r, "|", fixed = TRUE)[[1]])
    actual <- digest::digest(readr::read_file(here::here(SD_FEDERAL_DIR, parts[1])),
                             algo = "sha256", serialize = FALSE)
    expect_equal(actual, parts[2], info = parts[1])
  }
})


# -- Vocabulary --------------------------------------------------------------

test_that("every categorical column is inside the §8 vocabulary", {
  for (col in c("recipient_type", "distributed_to_hospital", "flow_type",
                "recipient_confirmed", "amount_confirmed", "flag_reason",
                "determination_confidence")) {
    bad <- setdiff(as.character(stats::na.omit(unique(records[[col]]))),
                   rhtp_vocabulary(col))
    expect_equal(bad, character(0), info = col)
  }
})

test_that("the register's own words classify its vendors, not a guess", {
  # Each of the five commercial consultancies of 2026-08-28 was procured
  # through an RFP for services, which is the register's own field saying the
  # state bought services. The settled fallback would have called all five
  # nonprofits. Engineering Solutions Inc (2026-09-24) is typed by the name
  # rule itself.
  vendors <- records[records$recipient_type == "VENDOR_OR_CONTRACTOR", ]
  expect_equal(nrow(vendors), 6L)
  expect_equal(sum(vendors$classification_rule == "OVERRIDE"), 5L)
  expect_false(any(vendors$determination_confidence == "LOW"))
})
