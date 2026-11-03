# Session 113: owner-supplied third-party analyses are CONTEXT ONLY. A file
# carrying "CONTEXT ONLY" in its manifest may not be read by any script.

test_that("no script reads a context-only owner upload", {
  dir <- here::here("data", "raw", "owner_uploads")
  mans <- list.files(dir, pattern = "\\.manifest\\.txt$", full.names = TRUE)
  ctx <- mans[vapply(mans, function(m) any(grepl("CONTEXT ONLY", readLines(m, warn = FALSE))),
                     logical(1))]
  files <- sub("\\.manifest\\.txt$", "", basename(ctx))
  expect_true("nrha_rhtp_year1_obligated_fund_analysis_thru_2026-07-31.pdf" %in% files)
  src <- unlist(lapply(list.files(here::here("R"), pattern = "\\.R$", full.names = TRUE),
                       readLines, warn = FALSE))
  for (f in files) {
    expect_false(any(grepl(tools::file_path_sans_ext(f), src, fixed = TRUE)), info = f)
    expect_false(any(grepl("nrha", src, ignore.case = TRUE)), info = f)
  }
})
