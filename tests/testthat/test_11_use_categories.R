# test_11_use_categories.R -- the RHTP use-category layer (session 123, owner direction 11-24)
#
# Every award row carries the seven use_* columns, written by ONE function
# (rhtp_use_category(), via R/11 --apply). These tests hold the layer to the
# owner's rules: the vocabulary is the NOFO's; a row is classified from its
# ACTIVITY, never from its recipient; every classified row has a quote and an
# archive; the groups sum to awards published; and no hospital, award or
# vendor total moved.

suppressMessages(source(here::here("R", "08_year1_summary.R")))

files <- uc_state_files()
rules <- rhtp_use_rules()
groups <- rhtp_use_groups()
vocab <- readr::read_csv(here::here("data/reference/vocabularies.csv"), col_types = readr::cols(.default = "c"),
                         progress = FALSE)
voc <- function(col) vocab$allowed_value[vocab$column_name == col]

test_that("the vocabulary is the NOFO's eleven letters, grouped as the owner directed", {
  cats <- readr::read_csv(here::here(RHTP_USE_CATEGORIES_CSV), col_types = readr::cols(.default = "c"), progress = FALSE)
  expect_identical(cats$letter, LETTERS[1:11])
  expect_identical(unname(groups[c("C", "D", "F")]), rep("HEALTH_IT_TECHNOLOGY", 3))
  expect_equal(length(unique(groups)), 9L)
  expect_setequal(voc("use_category_primary"), c(LETTERS[1:11], "MULTIPLE", "NOT_STATED"))
  expect_setequal(voc("use_group_primary"), names(RHTP_USE_GROUP_LABELS))
  expect_setequal(voc("use_category_basis"), RHTP_USE_BASES)
  expect_setequal(voc("use_category_confidence"), c("HIGH", "MEDIUM", "LOW"))
  expect_identical(cats$cap_pct[cats$letter %in% c("B", "J", "F")], c("15", "5", "20"))
  # every NOFO quote is in the archived NOFO text
  txt <- rhtp_use_text("data/evidence/cms/nofo/2026-11-24_cms_rht_nofo_in_appendix1.txt")
  for (i in seq_len(nrow(cats))) {
    expect_true(grepl(rhtp_use_norm(cats$nofo_text[i]), txt, fixed = TRUE), info = cats$letter[i])
    if (nzchar(cats$cap_quote[i] %||% "") && !is.na(cats$cap_quote[i])) {
      expect_true(grepl(rhtp_use_norm(cats$cap_quote[i]), txt, fixed = TRUE), info = cats$letter[i])
    }
  }
  expect_identical(RHTP_USE_COLUMNS, RHTP_USE_STRIP_COLUMNS)
})

test_that("every rule is an activity match, quoted verbatim, on an archived source", {
  expect_true(all(rules$match_field %in% names(RHTP_USE_MATCH_FIELDS)))
  forbidden <- c("awardee", "recipient_type", "recipient_subtype", "flow_type", "distributed_to_hospital",
                 "hospital_attribution", "summary_hospital_call", "spend_category", "intermediary_name", "ccn",
                 "determination_basis", "awardee_legal_name", "entity_type_raw", "organization_type_raw",
                 "provider_type", "recipient_class")
  expect_false(any(names(RHTP_USE_MATCH_FIELDS) %in% forbidden))
  expect_true(all(file.exists(here::here(rules$archive_path))))
  expect_true(all(file.exists(here::here(rules$quote_text_path))))
  # rhtp_use_rules() refuses a quote it cannot find; re-check here explicitly
  for (i in seq_len(nrow(rules))) {
    expect_true(rhtp_use_quote_found(rules$quote[i], rules$quote_text_path[i]), info = rules$rule_id[i])
  }
})

test_that("committed columns equal the computed layer, and every rule reaches a row", {
  expect_silent(uc_validate(files))
})

cols <- uc_compute(files, rules)
all_rows <- dplyr::bind_rows(lapply(names(files), function(k) {
  d <- uc_read(files[[k]])
  tibble::tibble(file_key = k, budget_period = d$budget_period, amount = d$amount,
                 summary_hospital_call = d$summary_hospital_call) %>% dplyr::bind_cols(cols[[k]])
}))

test_that("every column holds only vocabulary values, consistently", {
  r <- all_rows
  expect_true(all(r$use_category_primary %in% voc("use_category_primary")))
  expect_true(all(r$use_group_primary %in% voc("use_group_primary")))
  expect_true(all(r$use_category_basis %in% RHTP_USE_BASES))
  lt <- r$use_category_primary %in% LETTERS[1:11]
  expect_identical(r$use_group_primary[lt], unname(groups[r$use_category_primary[lt]]))
  expect_true(all(r$use_group_primary[r$use_category_primary == "MULTIPLE"] == "MULTIPLE"))
  ns <- r$use_category_basis == "NOT_STATED"
  expect_true(all(r$use_category_primary[ns] == "NOT_STATED"))
  expect_true(all(r$use_category_primary[!ns] != "NOT_STATED"))
  expect_identical(r$use_category_confidence[!ns], unname(RHTP_USE_CONFIDENCE[r$use_category_basis[!ns]]))
  expect_true(all(r$use_category_confidence[ns] == "" & r$use_category_quote[ns] == "" &
                    r$use_category_source[ns] == "" & r$use_categories_all[ns] == ""))
  # MULTIPLE only where the letters span more than one group and nothing points to one
  m <- r$use_category_primary == "MULTIPLE"
  expect_true(all(vapply(strsplit(r$use_categories_all[m], ";"), function(l) length(unique(groups[l])) > 1, TRUE)))
  # primary is always among the letters
  expect_true(all(mapply(function(p, a) p %in% strsplit(a, ";")[[1]], r$use_category_primary[lt], r$use_categories_all[lt])))
  # C, D, F only is never MULTIPLE
  cdf <- vapply(strsplit(r$use_categories_all, ";"), function(l) length(l) > 0 && all(l %in% c("C", "D", "F")), TRUE)
  expect_true(all(r$use_group_primary[cdf] == "HEALTH_IT_TECHNOLOGY"))
})

test_that("every classified row has a quote and an archive path that exists", {
  r <- all_rows %>% dplyr::filter(use_category_basis != "NOT_STATED")
  expect_true(all(nzchar(r$use_category_quote)))
  expect_true(all(nzchar(r$use_category_source)))
  paths <- unique(trimws(unlist(strsplit(r$use_category_source, " ; ", fixed = TRUE))))
  expect_true(all(file.exists(here::here(paths))), info = paste(paths[!file.exists(here::here(paths))], collapse = ", "))
})

test_that("no row is classified from its recipient: scrambling every recipient field moves nothing", {
  row_rules <- rules$rule_id[rules$match_field == "row"]
  set.seed(123)
  recip <- c("awardee", "recipient_type", "recipient_subtype", "flow_type", "distributed_to_hospital",
             "hospital_attribution", "summary_hospital_call", "summary_call_basis", "spend_category", "vendor_role",
             "intermediary_name", "ccn", "determination_basis", "determination_confidence", "basis_type",
             "cms_enrolment_record", "cms_enrolment_match")
  for (k in names(files)) {
    d <- uc_read(files[[k]])
    if (nrow(d) < 2) next
    x <- d
    for (cc in intersect(recip, names(x))) x[[cc]] <- sample(x[[cc]])
    a <- cols[[k]]
    b <- rhtp_use_category(x, k, rules, groups)
    keep <- !a$use_rule_id %in% row_rules   # the `row` locator keys on the awardee by design
    expect_identical(b[keep, RHTP_USE_COLUMNS], a[keep, RHTP_USE_COLUMNS], info = k)
  }
})

s <- ys_build()
u <- ys_use_build(s)

test_that("the groups sum to awards published, and HOSPITAL to the hospital figure", {
  n <- u$national
  tot <- n[n$use_group_primary == "TOTAL", ]
  body <- n[n$use_group_primary != "TOTAL", ]
  us <- s[s$state == "US", ]
  expect_equal(sum(body$award_usd), us$award_total_usd, tolerance = 0)
  expect_equal(round(sum(body$award_usd), 2), round(us$award_total_usd, 2))
  expect_equal(round(sum(body$hospital_usd), 2), round(us$hospital_summary_usd, 2))
  expect_equal(sum(body$rows), us$award_rows)
  expect_equal(round(body$hospital_usd + body$not_hospital_usd, 2), round(body$award_usd, 2))
  expect_identical(body$use_group_primary, names(RHTP_USE_GROUP_LABELS))
  # state by state (ys_use_items() asserts it too)
  bs <- u$by_state
  gcols <- paste0(tolower(names(RHTP_USE_GROUP_LABELS)), "_usd")
  expect_equal(round(rowSums(bs[, gcols]), 2), round(bs$award_total_usd, 2))
  cs <- u$coverage_state
  expect_equal(round(cs$award_source_usd + cs$crosswalk_usd + cs$purpose_text_usd + cs$not_stated_usd, 2),
               round(cs$award_usd, 2))
  expect_equal(round(sum(u$basis$award_usd), 2), round(us$award_total_usd, 2))
})

test_that("the cap table never calls a state over a cap: it is labelled published awards only", {
  expect_true(all(u$caps$b_cap_pct == 0.15) && all(u$caps$j_cap_pct == 0.20))
  d <- YS_USE_DEFINITIONS$definition[grepl("^b_primary", YS_USE_DEFINITIONS$column)]
  expect_true(grepl("PUBLISHED AWARDS ONLY, NOT THE STATE'S BUDGET", d, fixed = TRUE))
  expect_true(all(u$caps$b_primary_usd <= u$caps$b_any_usd + 0.005))
  expect_true(all(u$caps$j_primary_usd <= u$caps$j_any_usd + 0.005))
})

test_that("Detail's hospital-by-group columns sum to the hospital best estimate", {
  de <- ys_detail_use(ys_detail(s, ys_rows()), u)
  hc <- paste0("hospital_", tolower(names(RHTP_USE_GROUP_LABELS)), "_usd")
  x <- de[de$state != "US_GE50", ]
  expect_equal(round(rowSums(x[, hc]), 2), round(x$hospital_summary_usd, 2))
})

# -- Task 6: no total moved. The 2026-11-24 build equals the 2026-11-23 build. ----

test_that("the 2026-11-24 Year 1 table equals the 2026-11-23 table to the cent (session 123)", {
  a <- readr::read_csv(here::here(YS_OUT("2026-11-23")), show_col_types = FALSE)
  b <- readr::read_csv(here::here(YS_OUT("2026-11-24")), show_col_types = FALSE)
  expect_identical(as.data.frame(b), as.data.frame(a))
  us <- b[b$state == "US", ]
  expect_equal(round(us$award_total_usd, 2), 6529984965.77)
  expect_equal(round(us$hospital_summary_usd, 2), 2604985516.91)
  expect_equal(round(us$strict_named_hospital_usd, 2), 2292358452.90)
  va <- readr::read_csv(here::here(YS_VENDOR_OUT("2026-11-23")), show_col_types = FALSE)
  vb <- readr::read_csv(here::here(YS_VENDOR_OUT("2026-11-24")), show_col_types = FALSE)
  expect_identical(as.data.frame(vb), as.data.frame(va))
})

test_that("the committed use-category CSV is what the builder produces", {
  f <- here::here(YS_USE_OUT("2026-11-24"))
  expect_true(file.exists(f))
  committed <- readr::read_csv(f, col_types = readr::cols(.default = "c"), progress = FALSE, na = character())
  built <- ys_use_csv(u) %>% dplyr::mutate(value = dplyr::coalesce(value, ""))
  expect_equal(nrow(committed), nrow(built))
  nat <- committed %>% dplyr::filter(section == "national_by_group", measure %in% c("award_usd", "hospital_usd"))
  bn <- built %>% dplyr::filter(section == "national_by_group", measure %in% c("award_usd", "hospital_usd"))
  expect_equal(round(as.numeric(nat$value), 2), round(as.numeric(bn$value), 2))
})

test_that("the verified vendor list carries the use group of every case's award row", {
  sp <- rhtp_spend_rows(sc_state_files())
  v <- sp %>% dplyr::filter(kind == "award", nzchar(dplyr::coalesce(vendor_case_id, "")))
  expect_true(all(v$use_group_primary %in% names(RHTP_USE_GROUP_LABELS)))
  x <- here::here("output", "verified_vendor_list_2026-11-24.xlsx")
  expect_true(file.exists(x))
  vl <- openxlsx::read.xlsx(x, "Verified list", startRow = 4, check.names = FALSE, sep.names = " ")
  expect_true("Use group (primary)" %in% names(vl))
  expect_false(any(is.na(vl$`Use group (primary)`)))
})
