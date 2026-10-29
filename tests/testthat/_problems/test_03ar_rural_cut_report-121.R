# Extracted from test_03ar_rural_cut_report.R:121

# prequel ----------------------------------------------------------------------
source(here::here("R", "03ar_rural_cut_report.R"))
rows <- rc_rows()

# test -------------------------------------------------------------------------
r <- rows[rows$counts_as_rural, ]
expect_equal(nrow(r), 549L)
