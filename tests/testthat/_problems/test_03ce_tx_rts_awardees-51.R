# Extracted from test_03ce_tx_rts_awardees.R:51

# prequel ----------------------------------------------------------------------
suppressWarnings(suppressMessages(source(here::here("R", "03ce_tx_rts_awardees.R"))))
tx <- tx_rts_awardees()
committed <- readr::read_csv(TRT_CSV, show_col_types = FALSE,
                             col_types = readr::cols(ccn = "c", .default = readr::col_guess()))

# test -------------------------------------------------------------------------
h <- tx[tx$distributed_to_hospital == "Yes", ]
expect_equal(nrow(h), 285L)
expect_equal(round(sum(h$amount), 2), 189634041.13)
low <- h[h$determination_confidence == "LOW", ]
expect_equal(nrow(low), 90L)
expect_equal(round(sum(low$amount), 2), 58965817.23)
