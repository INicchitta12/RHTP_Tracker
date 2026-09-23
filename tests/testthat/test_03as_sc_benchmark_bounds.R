# test_03as_sc_benchmark_bounds.R --------------------------------------------
# Session 52. South Carolina against the agency benchmark (~50% of awards,
# ~60% of dollars): each named reading COMPUTED, none adopted, and no
# classification changed by this file. Session 53 re-pinned it after the
# Greenwood Pediatrics row was re-typed under §0.3a (+$145,000).

source(here::here("R", "03as_sc_benchmark_bounds.R"))

b <- sc_bounds()
pct <- function(v) b$dollar_share_pct[b$variant == v]

test_that("the as-typed figures are session 50's plus session 53's one row", {
  d <- sc_rows()
  expect_equal(nrow(d), 228L)
  expect_equal(sum(d$hospital), 114L)
  expect_equal(round(sum(d$amount[d$hospital]), 2), 115985714.95)
  expect_equal(pct("session 50's typing"), 69.3)
  expect_equal(b$award_share_pct[b$variant == "session 50's typing"], 50.0)
})

test_that("1: rural-only on source-backed evidence is FAR below 60, and mostly untestable", {
  expect_equal(pct("source-backed rural rows only"), 4.1)
  unrec <- pct("coverage: NOT_RECORDED (no source either way)")
  ord <- pct("coverage: CMS ordinary hospital by CCN (rural status not recorded)")
  expect_equal(unrec + ord, 94.1)
  expect_equal(pct("what 60% would require"), 86.5)
})

test_that("2: psychiatric rows are found by CMS CCN, and their exclusion lands at 64.8", {
  d <- sc_rows()
  expect_setequal(d$awardee[d$psych],
                  c("The Carolina Center for Behavioral Health",
                    "Acadia Healthcare Co.", "Rebound Behavioral Health"))
  expect_equal(pct("all three psychiatric/behavioural rows"), 64.8)
  expect_equal(round(69.3 - pct("all three psychiatric/behavioural rows"), 1), 4.5)
})

test_that("3: the grain moves COUNTS, not DOLLARS", {
  org <- b[b$variant == "Prisma and Self Regional collapsed to one organisation each", ]
  base <- b[b$variant == "session 50's typing", ]
  expect_equal(org$hospital_dollars, base$hospital_dollars)
  expect_equal(org$dollar_share_pct, base$dollar_share_pct)
  expect_lt(org$award_share_pct, base$award_share_pct)
  split <- b[b$variant == "multi-site rows split into one award per named site", ]
  expect_equal(split$all_awards, 233L)
  expect_equal(split$dollar_share_pct, base$dollar_share_pct)
})

test_that("no testable reading reaches 60; the combination leaves 3.1 points", {
  testable <- b[b$reading %in% c("2 psychiatric excluded", "3 multi-site",
                                 "2+3 combined"), ]
  expect_true(all(testable$dollar_share_pct > 60))
  expect_equal(pct("psychiatric excluded AND the four site rows treated as non-hospital"), 63.1)
})

test_that("the committed bounds table matches a fresh computation", {
  c <- readr::read_csv(SC_BOUNDS_CSV, show_col_types = FALSE, progress = FALSE)
  expect_equal(c$dollar_share_pct, b$dollar_share_pct)
  expect_equal(c$variant, b$variant)
})
