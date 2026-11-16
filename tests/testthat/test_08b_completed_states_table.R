# test_08b_completed_states_table.R -- session 117, Task 8.
#
# The completed-states table (R/08b) pinned on the 2026-11-16 build:
#   * "Hospital % of awards" reads n/m where a state's STATE-SOURCED awards are
#     under 50% of its allotment (today West Virginia), with its footnote;
#   * a dagger marks every state whose awards published are under 90% of its
#     allotment, with the owner's footnote verbatim;
#   * WA and NC stay PARTIAL (held: each still has Year 1 awards to make).

source(here::here("R", "08b_completed_states_table.R"))

tab <- cs_build("2026-11-16")
st <- tab[-nrow(tab), ]
tot <- tab[nrow(tab), ]
plain <- sub(CS_DAGGER, "", st$State, fixed = TRUE)

test_that("eleven COMPLETE states; WA and NC stay PARTIAL", {
  expect_equal(nrow(st), 11L)
  expect_equal(sort(plain), c("Alabama", "Arkansas", "Florida", "Georgia", "Idaho", "Nebraska",
                              "South Dakota", "Utah", "Vermont", "West Virginia", "Wyoming"))
  cs <- readr::read_csv(here::here("data/reference/year1_completion_status.csv"), show_col_types = FALSE)
  expect_false(any(cs$year1_status[cs$state %in% c("WA", "NC")] == "COMPLETE"))
  expect_equal(tot$State, "Total (11 states)")
})

test_that("n/m where state-sourced awards are under 50% of the allotment (today: West Virginia)", {
  expect_equal(plain[st$nm], "West Virginia")
  expect_lt(st$state_sourced_usd[plain == "West Virginia"] / st$`FY2026 allotment`[plain == "West Virginia"], 0.5)
  expect_false(tot$nm)
  x <- here::here("output", "completed_states_2026-11-16.xlsx")
  d <- openxlsx::read.xlsx(x, "Completed states", rows = 1:13, check.names = FALSE, sep.names = " ")
  hc <- d[["Hospital % of awards"]]
  expect_equal(hc[d$State == "West Virginia†"], "n/m")
  expect_false(any(hc[d$State != "West Virginia†"] == "n/m"))
  h <- paste(readLines(here::here("output", "completed_states_2026-11-16.html"), warn = FALSE), collapse = "\n")
  expect_true(grepl("n/m", h, fixed = TRUE))
  expect_true(grepl(CS_NM_NOTE, h, fixed = TRUE))
})

test_that("a dagger marks every state under 90% published, with the footnote verbatim", {
  expect_equal(sort(plain[st$dagger]), c("Florida", "Idaho", "Nebraska", "South Dakota", "West Virginia", "Wyoming"))
  expect_true(all(st$`Awards % of allotment`[st$dagger] < 0.9))
  expect_true(all(st$`Awards % of allotment`[!st$dagger] >= 0.9))
  expect_equal(CS_DAGGER_NOTE, paste("Less than 90% of the state's Year 1 allotment has been published as awards.",
                                     "Hospital figures cover only the published portion and may change as the rest is published."))
  h <- paste(readLines(here::here("output", "completed_states_2026-11-16.html"), warn = FALSE), collapse = "\n")
  expect_true(grepl(CS_DAGGER_NOTE, h, fixed = TRUE))
  x <- here::here("output", "completed_states_2026-11-16.xlsx")
  notes <- openxlsx::read.xlsx(x, "Completed states", colNames = FALSE, skipEmptyRows = FALSE)[[1]]
  expect_true(any(grepl(CS_DAGGER_NOTE, notes, fixed = TRUE)))
})

test_that("the total row is pinned (data 2026-11-16)", {
  expect_equal(tot$`FY2026 allotment`, 2230243286)
  # Session 118: NE's FSRS extras applied (+$9,827,430.86; hospital +$2,048,392.80),
  # VT's Grace Cottage duplicate held (-$2,000,000), WV's Ascend WV pair (-$2,399,990).
  expect_equal(round(tot$`Awards published`, 2), 1846909880.66)
  expect_equal(round(tot$`Hospital $ (best estimate)`, 2), 752670883.06)
  expect_equal(round(tot$`Strict named-hospital $`, 2), 695125414.35)
  expect_equal(round(100 * tot$`Hospital % of awards`, 1), 40.8)
})
