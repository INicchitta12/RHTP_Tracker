# Extracted from test_03ar_rural_cut_report.R:188

# prequel ----------------------------------------------------------------------
source(here::here("R", "03ar_rural_cut_report.R"))
rows <- rc_rows()

# test -------------------------------------------------------------------------
by <- readr::read_csv(here::here(RC_STATE_CSV), show_col_types = FALSE,
                        progress = FALSE)
fresh <- rc_by_state(rows)
expect_equal(nrow(by), nrow(fresh))
expect_equal(sum(by$rural_rows), 549L)
