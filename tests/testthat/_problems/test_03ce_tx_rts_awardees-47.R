# Extracted from test_03ce_tx_rts_awardees.R:47

# prequel ----------------------------------------------------------------------
suppressWarnings(suppressMessages(source(here::here("R", "03ce_tx_rts_awardees.R"))))
tx <- tx_rts_awardees()
committed <- readr::read_csv(TRT_CSV, show_col_types = FALSE,
                             col_types = readr::cols(ccn = "c", .default = readr::col_guess()))

# test -------------------------------------------------------------------------
h <- tx[tx$distributed_to_hospital == "Yes", ]
expect_equal(nrow(h), 285L)
