# Extracted from test_08_year1_summary.R:103

# prequel ----------------------------------------------------------------------
source(here::here("R", "08_year1_summary.R"))
rows <- ys_rows()
s <- ys_build(rows)
us <- s[s$state == "US", ]
ge <- s[s$state == "US_GE50", ]
st_only <- s[!s$state %in% YS_NATIONAL, ]

# test -------------------------------------------------------------------------
old <- readr::read_csv(here::here("data/reference/year1_summary_2026-11-09_pre_fsrs.csv"), show_col_types = FALSE)
d <- function(col) {
    v <- round(s[[col]] - old[[col]][match(s$state, old$state)], 2)
    k <- abs(v) > 0.005 & !s$state %in% YS_NATIONAL
    stats::setNames(v[k], s$state[k])
  }
expect_equal(round(us$hospital_summary_usd - 2075115137.63, 2),
               round(398267173.26 + 1544313 - 4236313.30 + 62902991.80 - 15002406 + 17190075 + 68879545.52 + 325000, 2))
expect_equal(d("hospital_summary_usd"),
               c(CT = 15005890 - 13116917, DE = 3291276, IA = 163815846.2, IL = 53821674.53,
                 KS = 1950110, KY = 4348529, ME = 258193 + 15543284, MN = 68840377 + 48682860 + 1697594 + 1646791, NC = 14550000,
                 ND = 8751588.75 + 524116.12, NE = 12987780.26 - 2540586.72 + 2048392.80, NV = 997361,
                 OK = 136594 + 275156 + 50000, SD = 25994573, TN = 16699481.52 + 643500 + 148832.40, TX = -1695726.58, VA = 24728876,
                 WA = 9670000, WI = 32216238, WV = 6083596 + 1544313 + 9945786))
