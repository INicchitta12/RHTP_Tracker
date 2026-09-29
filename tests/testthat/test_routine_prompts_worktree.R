# The v4 Routine prompts (session 79): every firing works in a separate
# worktree, so the runner's primary checkout -- and the CLAUDE.md a cold resume
# re-reads from it -- never changes. Zero network, zero quota.

source(here::here("R", "routine_prompts_worktree.R"))

test_that("the committed v4 prompts are exactly what the v3 sources derive", {
  p <- rp_all()
  expect_length(p, nrow(readr::read_csv(here::here("config", "routines.csv"),
                                        col_types = readr::cols(.default = "c"))))
  for (st in names(p)) {
    f <- file.path(RP_DIR, "v4", paste0(st, ".txt"))
    expect_true(file.exists(f), info = st)
    expect_identical(rp_read(f), p[[st]], info = st)
  }
})

test_that("no v4 prompt moves the primary checkout", {
  p <- rp_all()
  r <- readr::read_csv(here::here("config", "routines.csv"),
                       col_types = readr::cols(.default = "c"))
  for (st in names(p)) {
    x <- p[[st]]
    expect_false(grepl("checkout -B main", x, fixed = TRUE), info = st)
    expect_false(grepl("cd to the repository", x, fixed = TRUE), info = st)
    expect_true(grepl("git worktree add --detach /root/rhtp_work origin/main",
                      x, fixed = TRUE), info = st)
    expect_true(grepl("START EVERY SHELL COMMAND", x, fixed = TRUE), info = st)
    expect_true(grepl("git push origin HEAD:main", x, fixed = TRUE), info = st)
    # the Routine still runs its own script
    expect_true(grepl(r$script[r$state == st], x, fixed = TRUE), info = st)
  }
})

test_that("a drifted v3 prompt is refused, not half-edited", {
  v3 <- rp_read(file.path(RP_DIR, "v3", "CA.txt"))
  expect_error(rp_derive("CA", sub("1. Clean, current checkout.", "1. Other.",
                                   v3, fixed = TRUE)), "step 1 not found")
  expect_error(rp_derive("CA", gsub("git checkout -B main origin/main", "x",
                                    v3, fixed = TRUE)), "lacks its checkout")
})

test_that("a runner move replaces every mention of the old session", {
  v3 <- rp_read(file.path(RP_DIR, "v3", "CA.txt"))
  old <- stringr::str_extract(v3, "session_\\w+")
  mv <- tibble::tibble(state = "CA", old_runner = old,
                       new_runner = "session_TESTNEWRUNNER")
  x <- rp_derive("CA", v3, mv)
  expect_false(grepl(old, x, fixed = TRUE))
  expect_gte(stringr::str_count(x, "session_TESTNEWRUNNER"), 3)
})
