# test_claude_md_status_table.R -----------------------------------------------
# CLAUDE.md §10's "Deliverable 1" table and "Hospital partition" block must
# match the committed state files. Reads CLAUDE.md and committed CSVs off disk
# only -- no network, no quota.
#
# WHY THIS FILE EXISTS (session 78). Session 77 rebuilt §10 and found the old
# Deliverable 1 table stale on FOUR states (KS $52.2M vs $62,416,473; MD $23.7M
# vs $27,681,260; GA 108 vs 126 hospital rows; SC 113 vs 114) and MISSING FIVE
# files entirely (NJ, NY, WA, VA, IN GROW). Nobody noticed, because the one
# figure people check -- the NAMED_HOSPITAL partition total -- was right. A
# correct headline over wrong rows is the failure: the rows are what a reader
# quotes by state. So every row is checked, and the file SET is checked, and
# the headline is checked last rather than instead.
#
# The file list is NOT restated here. It is read out of test_state_union.R's
# STATE_FILES, so a thirty-ninth file added there fails this test until the
# table carries it -- which is exactly the omission session 77 found.
#
# WHEN THIS FAILS: re-derive the table from the files and edit CLAUDE.md by
# patch (§2.1). Never loosen a comparison to make it pass.

library(testthat)

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

# -- STATE_FILES, parsed from the union test rather than copied ---------------
union_exprs <- parse(here::here("tests", "testthat", "test_state_union.R"),
                     keep.source = FALSE)
sf_expr <- Filter(function(e) {
  is.call(e) && identical(e[[1]], as.name("<-")) &&
    identical(e[[2]], as.name("STATE_FILES"))
}, as.list(union_exprs))
stopifnot(length(sf_expr) == 1L)
STATE_FILES <- eval(sf_expr[[1]][[3]], envir = baseenv())

# The table labels a few files in prose; everything else is its STATE_FILES key.
TABLE_LABEL_TO_KEY <- c(
  "AR r1" = "AR", "AR r2" = "AR_R2",
  "AL r1" = "AL", "AL r2" = "AL_R2", "NC SBHC" = "NC_SBHC", "OK Doulas" = "OK_DOULAS",
  "OK RRR" = "OK_RRR", "OK CDM" = "OK_CDM", "DE FQHC" = "DE_FQHC",
  "SD contracts" = "SD_CONTRACTS", "SD rounds" = "SD_ANNOUNCEMENTS",
  "SD CCBHC" = "SD_CCBHC", "VA VHCF" = "VA_VHCF",
  "IN GROW" = "IN_GROW"
)

# The hospital cell's bucket prefixes. An unprefixed "N / $X" is NAMED_HOSPITAL,
# per the table's own header note.
CELL_BUCKET <- c(POOL_NAMED = "POOL_NAMED_HOSPITALS",
                 POOL_UNNAMED = "POOL_UNNAMED_HOSPITALS")

claude_md <- readLines(here::here("CLAUDE.md"), encoding = "UTF-8", warn = FALSE)

section_lines <- function(heading_regex) {
  start <- grep(heading_regex, claude_md)
  stopifnot(length(start) == 1L)
  nxt <- grep("^#{1,3} ", claude_md)
  end <- min(c(nxt[nxt > start], length(claude_md) + 1L)) - 1L
  claude_md[(start + 1L):end]
}

dollars <- function(x) as.numeric(gsub("[$,]", "", x))

# -- the Deliverable 1 table ---------------------------------------------------
parse_deliverable_table <- function() {
  body <- section_lines("^### Deliverable 1: state award files")
  rows <- grep("^\\| ", body, value = TRUE)
  rows <- rows[!grepl("^\\| File \\|", rows)]
  cells <- lapply(strsplit(rows, "\\|"), function(r) trimws(r[-1]))
  tibble::tibble(
    label    = vapply(cells, `[`, "", 1),
    rows     = as.integer(gsub(",", "", vapply(cells, `[`, "", 2))),
    priced   = as.integer(gsub(",", "", vapply(cells, `[`, "", 3))),
    sum_cell = vapply(cells, `[`, "", 4),
    hosp     = vapply(cells, `[`, "", 5)
  ) %>%
    dplyr::mutate(key = dplyr::coalesce(
      unname(TABLE_LABEL_TO_KEY[label]), label))
}

# "20 / $104,397,118 (intents)" -> NAMED_HOSPITAL 20 / 104397118. Parentheticals
# are prose (MHA's $8.625M, WSHA's $42M) and are dropped before any figure is
# read, so a dollar a sentence mentions is never taken for a bucket.
parse_hospital_cell <- function(cell) {
  stripped <- gsub("\\([^)]*\\)", "", cell)
  m <- stringr::str_match_all(
    stripped, "(?:(POOL_NAMED|POOL_UNNAMED)\\s+)?(\\d[\\d,]*) / (\\$[\\d,.]+)")[[1]]
  if (!nrow(m)) {
    # Only a bare "0" (or "0 (...)") may carry no bucket figure at all.
    if (!grepl("^\\s*0\\s*$", stripped)) {
      stop("unparseable Hospital cell: ", cell, call. = FALSE)
    }
    return(tibble::tibble(bucket = character(0), rows = integer(0),
                          dollars = numeric(0)))
  }
  tibble::tibble(
    bucket  = ifelse(is.na(m[, 2]) | m[, 2] == "", "NAMED_HOSPITAL",
                     unname(CELL_BUCKET[m[, 2]])),
    rows    = as.integer(gsub(",", "", m[, 3])),
    dollars = dollars(m[, 4])
  )
}

# -- what the committed files say ----------------------------------------------
file_figures <- function(key) {
  d <- readr::read_csv(here::here(STATE_FILES[[key]]), show_col_types = FALSE,
                       progress = FALSE)
  amt <- suppressWarnings(as.numeric(d$amount))
  # Older files (FL, GA, PA, AL, AK, SD, IL) predate `flow_type`; the
  # partition reads recipient_type for them, as the union test does.
  if (!"flow_type" %in% names(d)) d$flow_type <- NA_character_
  parts <- rhtp_hospital_dollar_partition(d) %>%
    dplyr::group_by(bucket) %>%
    dplyr::summarise(rows = sum(rows), dollars = sum(dollars), .groups = "drop")
  list(rows = nrow(d), priced = sum(!is.na(amt)),
       sum_amount = sum(amt, na.rm = TRUE), parts = parts)
}

table_d1 <- parse_deliverable_table()


test_that("the Deliverable 1 table lists every STATE_FILES file, once, and nothing else", {
  expect_equal(sum(duplicated(table_d1$key)), 0L)
  missing <- setdiff(names(STATE_FILES), table_d1$key)
  expect(length(missing) == 0L,
         paste("files committed but MISSING from the CLAUDE.md table:",
               paste(missing, collapse = ", ")))
  extra <- setdiff(table_d1$key, names(STATE_FILES))
  expect(length(extra) == 0L,
         paste("CLAUDE.md table rows naming NO file in STATE_FILES:",
               paste(extra, collapse = ", ")))
})

test_that("every Deliverable 1 row matches its committed file", {
  problems <- character(0)
  say <- function(key, what, table_val, file_val) {
    problems <<- c(problems, sprintf("%s %s: CLAUDE.md says %s, file says %s",
                                     key, what, table_val, file_val))
  }

  for (i in seq_len(nrow(table_d1))) {
    r <- table_d1[i, ]
    if (!r$key %in% names(STATE_FILES)) next
    f <- file_figures(r$key)

    if (!identical(r$rows, as.integer(f$rows))) say(r$key, "Rows", r$rows, f$rows)
    if (!identical(r$priced, as.integer(f$priced))) {
      say(r$key, "Priced", r$priced, f$priced)
    }

    # sum(amount): the first dollar figure, to the dollar; an em dash means
    # nothing is priced. A parenthetical ("published $175.3M") is prose.
    sum_txt <- gsub("\\([^)]*\\)", "", r$sum_cell)
    sum_fig <- stringr::str_extract(sum_txt, "\\$[\\d,.]+")
    if (is.na(sum_fig)) {
      if (!grepl("^\\s*—\\s*$", sum_txt)) {
        say(r$key, "sum(amount)", r$sum_cell, "an unreadable cell")
      } else if (f$priced != 0L) {
        say(r$key, "sum(amount)", "—", sprintf("%d priced rows", f$priced))
      }
    } else if (dollars(sum_fig) != round(f$sum_amount)) {
      say(r$key, "sum(amount)", sum_fig,
          format(round(f$sum_amount), big.mark = ",", scientific = FALSE))
    }

    # Hospital: every bucket the cell names must match, and every bucket the
    # file has rows in must be named -- except that an unmentioned
    # NAMED_HOSPITAL is only allowed when the file has none.
    cell <- tryCatch(parse_hospital_cell(r$hosp), error = function(e) {
      say(r$key, "Hospital", r$hosp, conditionMessage(e)); NULL
    })
    if (is.null(cell)) next
    for (b in union(cell$bucket, f$parts$bucket)) {
      tv <- cell[cell$bucket == b, ]
      fv <- f$parts[f$parts$bucket == b, ]
      t_rows <- if (nrow(tv)) tv$rows else 0L
      f_rows <- if (nrow(fv)) fv$rows else 0L
      t_dol  <- if (nrow(tv)) tv$dollars else 0
      f_dol  <- if (nrow(fv)) round(fv$dollars) else 0
      if (t_rows != f_rows || t_dol != f_dol) {
        say(r$key, paste("Hospital", b),
            sprintf("%d / $%s", t_rows, format(t_dol, big.mark = ",", scientific = FALSE)),
            sprintf("%d / $%s", f_rows, format(f_dol, big.mark = ",", scientific = FALSE)))
      }
    }
  }

  expect(length(problems) == 0L,
         paste(c("CLAUDE.md Deliverable 1 has drifted from the files:",
                 problems), collapse = "\n  "))
})

test_that("the Hospital partition block matches the union of the committed files", {
  u <- dplyr::bind_rows(lapply(names(STATE_FILES), function(k) {
    d <- readr::read_csv(here::here(STATE_FILES[[k]]), show_col_types = FALSE,
                         progress = FALSE)
    opt <- function(col) if (col %in% names(d)) as.character(d[[col]]) else NA_character_
    tibble::tibble(
      state = as.character(d$state),
      amount = suppressWarnings(as.numeric(d$amount)),
      distributed_to_hospital = as.character(d$distributed_to_hospital),
      recipient_type = as.character(d$recipient_type),
      flow_type = opt("flow_type"),
      hospital_attribution = opt("hospital_attribution"),
      flag_reason = opt("flag_reason")
    )
  }))
  parts <- rhtp_hospital_dollar_partition(u)

  body <- section_lines("^### Hospital partition")
  lines <- grep("^(NAMED|POOL)_", body, value = TRUE)
  m <- stringr::str_match(
    lines, "^(\\S+)\\s+(\\d[\\d,]*) rows?\\s+(\\$[\\d,.]+)(?:\\s+(\\d+) states)?")
  expect_false(any(is.na(m[, 1])), label = "an unparseable partition line")

  # Every bucket the files produce must be in the block, and vice versa.
  expect_setequal(m[, 2], unique(parts$bucket))

  for (i in seq_len(nrow(m))) {
    b <- m[i, 2]
    p <- parts[parts$bucket == b, ]
    expect_equal(as.integer(gsub(",", "", m[i, 3])), sum(p$rows), label = paste(b, "rows"))
    expect_equal(dollars(m[i, 4]), round(sum(p$dollars), 2), label = paste(b, "dollars"))
    if (!is.na(m[i, 5])) {
      expect_equal(as.integer(m[i, 5]), sum(p$rows > 0 & !is.na(p$state)),
                   label = paste(b, "states"))
    }
  }
})

test_that("the parser reads the shapes the table uses, and refuses prose it cannot", {
  x <- parse_hospital_cell("4 / $2,259,121 (a TOTAL; MHA $8.625M in no bucket)")
  expect_equal(x$bucket, "NAMED_HOSPITAL")
  expect_equal(x$dollars, 2259121)

  x <- parse_hospital_cell("2 / $33,350,000 + POOL_NAMED 1 / $12,650,000")
  expect_equal(x$bucket, c("NAMED_HOSPITAL", "POOL_NAMED_HOSPITALS"))
  expect_equal(x$rows, c(2L, 1L))

  expect_equal(parse_hospital_cell("POOL_UNNAMED 1 / $50,008,264")$bucket,
               "POOL_UNNAMED_HOSPITALS")
  expect_equal(nrow(parse_hospital_cell("0 (FHC Unclear)")), 0L)
  expect_error(parse_hospital_cell("about $52.2M"), "unparseable")
})
