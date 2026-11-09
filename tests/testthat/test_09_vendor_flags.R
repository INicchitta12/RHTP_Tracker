# test_09_vendor_flags.R -------------------------------------------------------
# Session 116b: the vendor / consultant / insurer / out-of-state detection layer.
#
# Pins: the dictionary schema and class list; the hospital exclusion (nothing
# in the dictionary or the flag file is a hospital or health system); the
# $1M "Top cases" ranking; amount types never mixed; leads labelled; and that
# NO HOSPITAL FIGURE CHANGED -- this layer only reads.

library(testthat)

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))
suppressMessages(source(here::here("R", "09_vendor_flags.R")))

dict <- vf_dictionary()
flags <- vf_read_flags()
union <- vf_award_union()
hosp_rows <- union[vf_is_hospital_row(union), , drop = FALSE]

test_that("the dictionary schema is pinned", {
  expect_identical(names(dict), c("pattern", "canonical_name", "parent_company",
                                  "entity_class", "hq_state", "basis", "notes"))
  expect_false(any(dict$pattern == "" | dict$canonical_name == "" |
                     dict$parent_company == "" | dict$basis == ""))
  expect_true(all(grepl("^[A-Z]{2}$|^UNKNOWN$", dict$hq_state)))
  # Every basis says what KIND of evidence the headquarters call rests on.
  expect_true(all(grepl("^(GENERAL_KNOWLEDGE|SOURCE_ADDRESS|STATE_SOURCE|NONE):", dict$basis)))
  # Every pattern compiles.
  for (p in dict$pattern) {
    expect_silent(stringr::str_detect("x", stringr::regex(p, ignore_case = TRUE)))
  }
})

test_that("the class list is exactly the five classes, and each is used", {
  expect_identical(VF_CLASSES, c("CONSULTING_BIG", "CONSULTING_OTHER", "TECH_VENDOR",
                                 "INSURER_MCO", "OUT_OF_STATE_ORG"))
  expect_setequal(unique(dict$entity_class), VF_CLASSES)
  expect_true(all(flags$entity_class %in% VF_CLASSES))
  # The firms the brief names are in the classes it names.
  big <- c("Deloitte", "McKinsey", "Ernst & Young", "Boston Consulting Group", "Bain",
           "KPMG", "PwC", "Accenture", "Guidehouse")
  for (b in big) {
    expect_true(any(grepl(b, dict$canonical_name[dict$entity_class == "CONSULTING_BIG"],
                          fixed = TRUE)), info = b)
  }
})

test_that("no hospital or health system is in the dictionary", {
  # (1) No dictionary pattern matches any award-file row coded or called a
  # hospital, in any state.
  for (i in seq_len(nrow(dict))) {
    hit <- stringr::str_detect(dplyr::coalesce(hosp_rows$recipient, ""),
                               stringr::regex(dict$pattern[i], ignore_case = TRUE))
    expect_false(any(hit), info = paste(dict$canonical_name[i], ":",
                                        paste(head(hosp_rows$recipient[hit], 3), collapse = "; ")))
  }
  # (2) No canonical name reads as a hospital.
  expect_false(any(stringr::str_detect(dict$canonical_name, VF_HOSPITAL_NAME)))
  # (3) The traps written into the dictionary stay closed.
  m <- vf_match(c("METRO KNOXVILLE HMA, LLC", "University of North Carolina Hospitals",
                  "InterHab (StationMD)"), dict)
  expect_false(any(m$matched))
})

test_that("no hospital or health system is in the flag file", {
  expect_false(any(stringr::str_detect(flags$recipient, VF_HOSPITAL_NAME)))
  expect_false(any(stringr::str_detect(flags$canonical_name, VF_HOSPITAL_NAME)))
  # No flagged (state, recipient) is a hospital row of the award files.
  expect_length(intersect(paste(flags$state, flags$recipient),
                          paste(hosp_rows$state, hosp_rows$recipient)), 0L)
  # Every reviewed USAspending exclusion is still read as a reason, not a flag.
  expect_false(any(flags$recipient %in% VF_FSRS_REVIEWED_EXCLUSIONS$subawardee_name))
})

test_that("the flag file holds its own vocabulary and never mixes amount types", {
  expect_identical(names(flags), VF_FLAG_COLUMNS)
  expect_true(vf_assert_flags(flags))
  expect_true(all(flags$amount_type %in% VF_AMOUNT_TYPES))
  expect_true(all(flags$role %in% VF_ROLES))
  # "By firm" never totals across amount types: one row per firm x type x role.
  bf <- vf_by_firm(flags)
  expect_false(anyDuplicated(bf[, c("parent_company", "amount_type", "role")]) > 0)
  expect_true(all(c("amount_type", "role") %in% names(bf)))
  # An OUT_OF_STATE_ORG row is out of state.
  expect_true(all(flags$out_of_state[flags$entity_class == "OUT_OF_STATE_ORG"]))
  # A multi-recipient field is never divided.
  m <- flags[grepl("MULTI-RECIPIENT", flags$notes), ]
  expect_true(nrow(m) > 0)
  expect_true(all(is.na(m$amount) & m$amount_type == "unpriced"))
})

test_that("leads are labelled, LOW, never ranked and never totalled", {
  leads <- flags[flags$is_lead, ]
  expect_true(all(leads$source_type == "RCJ_LEAD"))
  expect_true(all(leads$confidence == "LOW"))
  expect_true(all(grepl("^LEAD ONLY", leads$notes)))
  top <- vf_top_cases(flags)
  expect_true(all(is.na(top$rank[top$label != ""])))
  expect_true(all(grepl("^LEAD", top$label[is.na(top$rank)])))
  expect_false(any(vf_by_class(flags)$rows > table(flags$entity_class[!flags$is_lead])[vf_by_class(flags)$entity_class]))
  # The RCJ dispositions that say "not RHTP" keep a lead out entirely.
  expect_false(any(flags$state == "TX" & flags$parent_company %in% c("Molina Healthcare", "UnitedHealth Group")))
  expect_false(any(flags$state == "CO" & flags$source_type == "RCJ_LEAD"))
})

test_that("Top cases is every non-lead case of $1M or more, ranked by amount", {
  top <- vf_top_cases(flags)
  ranked <- top[!is.na(top$rank), ]
  expect_true(all(ranked$amount >= 1e6))
  expect_identical(ranked$rank, seq_len(nrow(ranked)))
  expect_false(is.unsorted(rev(ranked$amount)))
  # Nothing of $1M or more is left out: recompute the cases independently.
  cases <- flags %>% dplyr::filter(!is_lead, !is.na(amount)) %>%
    dplyr::group_by(state, canonical_name, amount_type, source_type) %>%
    dplyr::summarise(amount = sum(amount), .groups = "drop") %>%
    dplyr::filter(amount >= 1e6)
  expect_equal(nrow(cases), nrow(ranked))
})

test_that("de-duplication keeps one row and both citations", {
  # Alaska's Moda intent is on the AK award file AND on Alaska's FFATA report.
  moda <- flags[flags$state == "AK" & flags$parent_company == "Moda", ]
  expect_equal(nrow(moda), 1L)
  expect_match(moda$also_cited_in, "USASPENDING_FSRS")
  # Rhode Island's Alvarez & Marsal lines are counted once, not from both the RI
  # file and the raw CMS lines.
  am <- flags[flags$state == "RI" & flags$parent_company == "Alvarez & Marsal", ]
  expect_equal(round(sum(am$amount), 2), 4515000)
  # Utah's Comagine FAST 4.1: the executed $6M survives, the $2M intent is cited.
  ut <- flags[flags$state == "UT" & flags$canonical_name == "Comagine Health", ]
  expect_true(6e6 %in% ut$amount)
  expect_match(ut$also_cited_in[ut$amount == 6e6], "FAST 4.1")
})

test_that("every flag cites a source and the hand rows match their archives", {
  expect_true(all(!is.na(flags$source_url) & nzchar(flags$source_url)))
  expect_true(all(!is.na(flags$archive_path) & nzchar(flags$archive_path)))
  skip_if(!nzchar(Sys.which("pdftotext")), "pdftotext not installed")
  expect_true(vf_validate_hand_rows())
})

test_that("Delaware's confidential source is not used", {
  src <- paste(readLines(here::here("R", "09_vendor_flags.R")), collapse = "\n")
  src <- sub("VF_NOTES <- c\\(.*", "", src)   # the Notes text names it to say so
  expect_false(grepl("DE Verify", src, fixed = TRUE))
  expect_false(any(grepl("DE Verify", flags$archive_path, fixed = TRUE)))
})

test_that("the USAspending archive is what the flags were built from", {
  cv <- readr::read_csv(here::here(USA_COVERAGE_CSV), show_col_types = FALSE, progress = FALSE)
  expect_equal(nrow(cv), 50L)
  expect_equal(sum(cv$reports_subawards), 31L)
  expect_equal(sum(cv$subaward_rows), 2025L)
  expect_true(file.exists(file.path(USA_RAW_DIR(), USA_ZIP)))
  expect_true(file.exists(paste0(file.path(USA_RAW_DIR(), USA_ZIP), ".manifest.txt")))
})

test_that("NO HOSPITAL FIGURE CHANGED: the partition is session 116's", {
  sf <- vf_state_files()
  u <- dplyr::bind_rows(lapply(names(sf), function(k) {
    d <- readr::read_csv(here::here(sf[[k]]), show_col_types = FALSE, progress = FALSE)
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
  p <- rhtp_hospital_dollar_partition(u) %>%
    dplyr::group_by(bucket) %>%
    dplyr::summarise(rows = sum(rows), dollars = round(sum(dollars), 2), .groups = "drop")
  pin <- tibble::tribble(
    ~bucket, ~rows, ~dollars,
    # Session 116c/d moved it (R/09b, FSRS as an award source); R/09 still moves nothing.
    "NAMED_HOSPITAL", 2204L, 2170425246.88,
    "POOL_NAMED_HOSPITALS", 10L, 86895779.43,
    "POOL_UNNAMED_HOSPITALS", 6L, 79214848.17)
  for (i in seq_len(nrow(pin))) {
    r <- p[p$bucket == pin$bucket[i], ]
    expect_equal(r$rows, pin$rows[i], label = pin$bucket[i])
    expect_equal(r$dollars, pin$dollars[i], label = pin$bucket[i])
  }
  # And the layer writes only its own files.
  src <- paste(readLines(here::here("R", "09_vendor_flags.R")), collapse = "\n")
  writes <- stringr::str_match_all(src, "write_csv\\([^,]+, here::here\\(([A-Z_]+)\\)")[[1]][, 2]
  expect_setequal(writes, c("VF_FLAGS_CSV", "VF_UNNAMED_CSV"))
})
