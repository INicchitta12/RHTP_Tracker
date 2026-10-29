# Extracted from test_03ce_tx_rts_awardees.R:97

# prequel ----------------------------------------------------------------------
suppressWarnings(suppressMessages(source(here::here("R", "03ce_tx_rts_awardees.R"))))
tx <- tx_rts_awardees()
committed <- readr::read_csv(TRT_CSV, show_col_types = FALSE,
                             col_types = readr::cols(ccn = "c", .default = readr::col_guess()))

# test -------------------------------------------------------------------------
s <- tx[grepl("SOURCE_SUSPECT", tx$flag_reason), ]
expect_equal(sort(s$awardee), sort(TRT_SOURCE_SUSPECT$awardee))
expect_true(all(s$amount > s$total_award_amount))
part <- rhtp_hospital_dollar_partition(tx)
expect_equal(round(part$dollars[part$bucket == "NAMED_HOSPITAL"], 2), 189124104.63)
