# test_03cb_cms_obligation_rows.R ---------------------------------------------
# The owner's 2026-10-12 rulings on CMS's obligation report (session 98):
# rows rebuilt from the committed parse must equal the committed files, every
# row must be subtractable by its source type, and the NE/PA dedupe must
# refuse what it exists to refuse. Offline.

library(testthat)

suppressMessages(source(here::here("R", "03cb_cms_obligation_rows.R")))

rd <- function(k) readr::read_csv(OB_OUT[[k]], col_types = readr::cols(.default = "c"),
                                  na = character())

test_that("a rebuild from the committed parse reproduces the committed files", {
  l <- ob_lines()
  np <- ob_ne_pa_rows(l)
  ri <- ob_ri_rows(l)
  fresh <- list(NE = np[np$state == "NE", ], PA = np[np$state == "PA", ], RI = ri)
  for (k in names(fresh)) {
    d <- rd(k)
    expect_equal(nrow(d), nrow(fresh[[k]]), info = k)
    expect_equal(round(sum(as.numeric(d$amount)), 2),
                 round(sum(as.numeric(fresh[[k]]$amount)), 2), info = k)
    expect_setequal(d$cms_line_id, fresh[[k]]$cms_line_id)
  }
})

test_that("the ruled figures, pinned", {
  ne <- rd("NE"); pa <- rd("PA"); ri <- rd("RI")
  expect_equal(nrow(ne), 4L); expect_equal(nrow(pa), 2L); expect_equal(nrow(ri), 104L)
  amt <- function(d, who) round(sum(as.numeric(d$amount[d$awardee == who])), 2)
  expect_equal(amt(ri, "Hospital Association of Rhode Island"), 15839907.67)
  expect_equal(amt(ne, "Nebraska Hospital Association"), 3474937.50)
  expect_equal(amt(pa, "The Guthrie Clinic"), 2963577.00)
  expect_equal(amt(ne, "Mayo Clinic"), 120000)
  expect_equal(amt(ne, "CHI Health St Marys"), 40824.49)
  expect_equal(round(sum(as.numeric(ri$amount)), 2), 78727110.44)

  assoc <- dplyr::bind_rows(ne, ri) %>%
    dplyr::filter(flag_reason == "CMS_OBLIGATION_ASSOCIATION")
  expect_setequal(unique(assoc$awardee),
                  c("Hospital Association of Rhode Island", "Nebraska Hospital Association"))
  expect_true(all(assoc$flow_type == "PASS_THROUGH_DESIGNATED"))
  expect_true(all(assoc$hospital_attribution == "POOL_UNNAMED_HOSPITALS"))
  expect_true(all(assoc$recipient_type == "NONPROFIT_CBO"))
  expect_true(all(nzchar(assoc$intermediary_name)))

  mayo <- ne[ne$awardee == "Mayo Clinic", ]
  expect_equal(mayo$facility_state, "MN")
  expect_equal(mayo$basis_type, "GENERAL_KNOWLEDGE")
  expect_equal(mayo$determination_confidence, "LOW")
  expect_equal(mayo$ccn, "")
  expect_true(all(pa$determination_confidence == "LOW" & pa$ccn == "" &
                    pa$basis_type == "GENERAL_KNOWLEDGE"))
  stm <- ne[ne$awardee == "CHI Health St Marys", ]
  expect_true(all(stm$ccn == "281342" & stm$cms_enrolment_match == "DBA_OF_LEGAL_ENTITY"))

  # RI: no enrolled hospital; one FQHC enrolment; every row screened
  expect_true(all(ri$hospital_attribution %in% c("NOT_HOSPITAL", "POOL_UNNAMED_HOSPITALS")))
  expect_true(all(ri$recipient_type[ri$awardee == "Narragansett Indian Tribe"] == "FQHC_OR_RHC"))
  expect_true(all(nzchar(ri$cms_enrolment_record)))
})

test_that("every row is subtractable: one source type, one as_of, a CMS line id", {
  for (k in names(OB_OUT)) {
    d <- rd(k)
    expect_true(all(d$validation_source_type == "CMS_OBLIGATION_REPORT"), info = k)
    expect_true(all(d$as_of == "2026-07-31"), info = k)
    expect_true(all(grepl("^[A-Z]{2}-\\d{3}-\\d{2}-\\d+$", d$cms_line_id)), info = k)
    expect_false(any(d$determination_confidence == "HIGH"), info = k)
    expect_false(any(duplicated(d$cms_line_id)), info = k)
  }
})

test_that("no RI row comes from a multi-recipient line (§6.2)", {
  l <- ob_lines()
  multi <- l$line_id[l$state == "RI" & !is.na(l$named_orgs) &
                       (lengths(strsplit(l$named_orgs, ";")) > 1L |
                          l$n_unnamed_others != "0")]
  expect_gt(length(multi), 0L)
  expect_length(intersect(rd("RI")$cms_line_id, multi), 0L)
})

test_that("the dedupe refuses an amount match and an unread name overlap", {
  expect_silent(d <- ob_dedupe())
  expect_equal(d$name_match_rows[d$line_id == "NE-004-16-59"], "40")
  # an obligation line priced exactly like an existing NE row
  ex <- ob_existing("NE")
  fake <- tibble::tibble(line_id = "NE-999-99-1", state = "NE", org = "Somebody New",
                         amount = as.numeric(ex$amount[!is.na(suppressWarnings(as.numeric(ex$amount)))][1]))
  expect_error(ob_dedupe(fake), "equals an existing row to the cent")
  # a name nobody has reviewed
  fake2 <- tibble::tibble(line_id = "NE-999-99-2", state = "NE",
                          org = "Antelope Memorial Hospital", amount = 1.23)
  expect_error(ob_dedupe(fake2), "nobody has read")
})
