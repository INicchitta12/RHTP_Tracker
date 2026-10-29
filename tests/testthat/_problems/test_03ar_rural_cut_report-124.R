# Extracted from test_03ar_rural_cut_report.R:124

# prequel ----------------------------------------------------------------------
source(here::here("R", "03ar_rural_cut_report.R"))
rows <- rc_rows()

# test -------------------------------------------------------------------------
r <- rows[rows$counts_as_rural, ]
expect_equal(nrow(r), 549L)
expect_equal(sum(r$state == "CA"), 31L)
expect_equal(round(sum(r$amount[r$state == "CA"], na.rm = TRUE), 2), 46065499.94)
expect_equal(sum(r$state == "TX"), 185L)
