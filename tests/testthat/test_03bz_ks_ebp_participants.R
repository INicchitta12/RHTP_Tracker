# test_03bz_ks_ebp_participants.R --------------------------------------------
# Kansas's EBP Program (session 95): 94 participating hospitals that are an
# ENROLMENT list, not awards, and the KS probe's two session-95 changes (the
# name tripwire scoped past KDHE's new menu; the EBP payment-list watch).

library(testthat)

suppressMessages(source(here::here("R", "03bz_ks_ebp_participants.R")))

test_that("the archive verifies against its manifest", {
  man <- here::here(KSE_DIR, "MANIFEST.txt")
  lines <- grep("^[0-9a-f]{64}  ", readLines(man), value = TRUE)
  files <- sub("^[0-9a-f]{64}  ([^ ]+).*$", "\\1", lines)
  expect_setequal(files, KSE_SOURCES$file)
  for (i in seq_along(lines)) {
    expect_equal(digest::digest(file = here::here(KSE_DIR, files[i]), algo = "sha256"),
                 sub("^([0-9a-f]{64}).*$", "\\1", lines[i]), info = files[i])
  }
  expect_false(any(grepl("MANIFEST.txt", lines, fixed = TRUE)))
  html <- paste(readLines(kse_path("page"), warn = FALSE), collapse = "\n")
  expect_false(grepl("et_frontend_nonce|AIza[0-9A-Za-z_-]{20,}", html))
})

test_that("every sentence the conclusion rests on is in its archived document", {
  expect_true(kse_assert())
})

test_that("the participants file is 94 hospitals, NOT awards, with no amount", {
  x <- readr::read_csv(KSE_CSV, show_col_types = FALSE)
  expect_equal(nrow(x), 94L)
  expect_false(anyDuplicated(x$organization) > 0)
  expect_false(any(c("amount", "round_amount") %in% names(x)))
  expect_true(all(x$award_made == "No"))
  expect_true(all(x$payment_confirmed == "No"))
  expect_true(all(x$intermediary_name == "UKHS Care Collaborative Association"))
  expect_true(all(grepl("NOT MET", x$flow_test, fixed = TRUE)))
  expect_setequal(x$organization, kse_hospitals())
  # A non-award file never enters the hospital union.
  union_src <- paste(readLines(here::here("tests", "testthat",
                                          "test_state_union.R")), collapse = "\n")
  expect_false(grepl("ks_ebp_participants", union_src, fixed = TRUE))
})

test_that("the payment-list tripwire fires on a payment list and not on routine links", {
  links <- kse_page_links(kse_path("page"))
  expect_true(kse_assert_no_payment_list(links, kse_text("page")))
  # A re-dated participant list or FAQ is routine.
  routine <- c(links, paste0(KSE_UP, "2026/10/EBP-Program-Participating-Hospitals-10.15.2026.xlsx"),
               paste0(KSE_UP, "2026/10/10.20.2026-EBP-Administrative-FAQs.docx"))
  expect_true(kse_assert_no_payment_list(routine, "nothing"))
  # A new document of any other kind is the signal.
  expect_error(kse_assert_no_payment_list(
    c(links, paste0(KSE_UP, "2026/11/EBP-Infrastructure-Payments-Issued.xlsx")), "x"),
    "THAT IS THE SIGNAL")
  expect_error(kse_assert_no_payment_list(
    links, "The following hospitals have received infrastructure payments."),
    "THAT IS THE SIGNAL")
  expect_error(kse_assert_no_payment_list(
    links, "Year 1 payments have been issued to 80 hospitals."),
    "THAT IS THE SIGNAL")
  # And the archived page's own payment wording ("To receive ...") does not.
  expect_true(kse_assert_no_payment_list(
    links, "To receive a Year 1 infrastructure payment, a provider must submit"))
})

test_that("the KS name tripwire reads the content region, and still fires on a recipient", {
  suppressMessages(source(here::here("R", "03o_ks_year1_awardees.R")))
  arch <- ks_page_lines(readBin(ks_archive_path("program_page"), "raw",
                                file.size(ks_archive_path("program_page"))))
  a <- ks_name_scope(arch, "program_page")
  expect_lt(nchar(a), nchar(arch))
  # KDHE's new mega-menu, appended after the content: ignored.
  menu <- paste(arch, "Quick Links", "About KDHE", "Office of the Secretary",
                "Division of Environment", "Kansas Clean Diesel Program",
                sep = "\n")
  expect_no_error(rhtp_assert_no_new_organisations_across(
    live = list(program_page = ks_name_scope(menu, "program_page")),
    archived = list(program_page = a), state = "KS",
    furniture = KS_NAME_FURNITURE))
  # The three read content names: ignored, exactly.
  read <- sub("Latest News", paste("Latest News", "Year 2 Regional Partnership Grant Program",
                                   "The Kansas Health Institute (KHI) and partners",
                                   sep = "\n"), a)
  expect_no_error(rhtp_assert_no_new_organisations_across(
    live = list(program_page = read), archived = list(program_page = a),
    state = "KS", furniture = KS_NAME_FURNITURE))
  # A real recipient fires, and furniture is exact-match, not containment.
  hot <- sub("Latest News", "Latest News\nKDHE awarded Smith County Memorial Hospital.", a)
  expect_error(rhtp_assert_no_new_organisations_across(
    live = list(program_page = hot), archived = list(program_page = a),
    state = "KS", furniture = KS_NAME_FURNITURE), "Smith County Memorial Hospital")
  longer <- sub("Latest News", "Latest News\nThe Kansas Health Institute Foundation Inc.", a)
  expect_error(rhtp_assert_no_new_organisations_across(
    live = list(program_page = longer), archived = list(program_page = a),
    state = "KS", furniture = KS_NAME_FURNITURE), "THAT IS THE SIGNAL")
  # A moved anchor is refused, not read past.
  expect_error(ks_name_scope(gsub("Quick Links", "Useful Links", arch), "program_page"),
               "SCOPE end anchor")
  expect_error(ks_name_scope(gsub("Open RHTP Funding Opportunities", "Funding", arch),
                             "program_page"), "SCOPE anchor")
})
