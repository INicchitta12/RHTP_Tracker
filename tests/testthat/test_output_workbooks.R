# test_output_workbooks.R -- session 116f, Task 6
#
# Every workbook in output/ opens in openpyxl in NORMAL mode (not read-only),
# which is what fails on a dangling part reference: openxlsx 4.2.9 lists
# drawing parts in a sheet's relationships without writing them, and openpyxl
# then raises KeyError "There is no item named 'xl/drawings/drawing1.xml'".
# Every writer of output/ now calls rhtp_xlsx_strip_dangling_rels().

test_that("every workbook in output/ opens in openpyxl (normal mode)", {
  py <- Sys.which("python3")
  skip_if(!nzchar(py), "python3 not available")
  ok <- system2(py, c("-I", "-c", shQuote("import openpyxl")), stdout = FALSE, stderr = FALSE) == 0
  skip_if(!ok, "openpyxl not available")
  books <- list.files(here::here("output"), "\\.xlsx$", full.names = TRUE)
  expect_gt(length(books), 0L)
  code <- "import sys, openpyxl\nwb = openpyxl.load_workbook(sys.argv[1])\nprint(len(wb.sheetnames))"
  for (b in books) {
    out <- suppressWarnings(system2(py, c("-I", "-c", shQuote(code), shQuote(b)), stdout = TRUE, stderr = TRUE))
    expect_null(attr(out, "status"), info = paste(basename(b), paste(out, collapse = " ")))
  }
})

test_that("the 2026-11-11 verified vendor list is rebuilt from the spend layer", {
  x <- here::here("output", "verified_vendor_list_2026-11-11.xlsx")
  expect_true(file.exists(x))
  expect_equal(openxlsx::getSheetNames(x),
               c("Verified list", "By category", "Pass-through and hospital", "Re-categorised in 116f", "By firm",
                 "Leads (not verified)", "Unnamed contractor money", "Planned (not awarded)", "Dropped", "Method"))
  v <- openxlsx::read.xlsx(x, "Verified list", startRow = 4, check.names = FALSE, sep.names = " ")
  m <- readr::read_csv(here::here("config/spend_category_cases.csv"), show_col_types = FALSE)
  vendor_cases <- m$case_id[m$spend_category %in% c("CONSULTANT", "DATA_TECH_VENDOR", "ADMINISTRATOR", "NON_PROVIDER_INTERMEDIARY")]
  expect_setequal(v$`Case ID`, vendor_cases)
  expect_true(all(v$`Spend category` %in% c("CONSULTANT", "DATA_TECH_VENDOR", "ADMINISTRATOR", "NON_PROVIDER_INTERMEDIARY")))
})
