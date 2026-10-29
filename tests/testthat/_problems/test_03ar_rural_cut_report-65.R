# Extracted from test_03ar_rural_cut_report.R:65

# prequel ----------------------------------------------------------------------
source(here::here("R", "03ar_rural_cut_report.R"))
rows <- rc_rows()

# test -------------------------------------------------------------------------
expect_equal(nrow(rows), 1835L)
expect_equal(round(sum(rows$amount, na.rm = TRUE), 2), 1731421723.08,
               tolerance = 0)
expect_equal(nrow(rows[rows$state != "TX", ]), 1551L)
