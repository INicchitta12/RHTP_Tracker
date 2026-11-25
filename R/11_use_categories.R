# R/11_use_categories.R -- RHTP use-of-funds categories on every award row (session 123)
#
# OWNER DIRECTION (2026-11-24): classify every Year 1 award (hospital and
# non-hospital) by the RHTP activity it funds, using CMS's own uses of funds
# (A-K), wherever the evidence allows. "Not stated" is acceptable; a guess is not.
# The rule, the columns and the evidence ladder are in R/utils_use_category.R
# and CLAUDE.md §7 ("Use categories, session 123").
#
# ORDER. This runs LAST of all, after R/09b --apply's FSRS overlay and after
# R/07 --apply (summary calls, budget_period, spend categories). A rebuild of
# any award file drops the seven columns, and --validate (and test_11) fail
# until this is re-run. It writes ONLY the seven use_* columns: no amount,
# no typing, no call and no category of any other layer moves, so no hospital,
# award or vendor total can (test_11 proves it on every file).
#
# Usage:
#   Rscript R/11_use_categories.R --apply      # write the seven columns onto every award file
#   Rscript R/11_use_categories.R --validate   # committed columns == computed; every rule reaches a row
#   Rscript R/11_use_categories.R --report     # coverage by basis and by state

suppressPackageStartupMessages({
  library(dplyr)
})
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_summary_calls.R"))
source(here::here("R", "utils_use_category.R"))

uc_state_files <- function() {
  tf <- readLines(here::here("tests/testthat/test_state_union.R"))
  i0 <- grep("^STATE_FILES <- c\\(", tf)
  i1 <- i0 + which(grepl("^\\)", tf[(i0 + 1):length(tf)]))[1]
  eval(parse(text = tf[i0:i1]))
  STATE_FILES
}

uc_read <- function(p) readr::read_csv(here::here(p), col_types = readr::cols(.default = "c"),
                                       na = character(), progress = FALSE, trim_ws = FALSE)

#' Compute the columns for every file. Refuses a rule that reaches no row.
uc_compute <- function(files = uc_state_files(), rules = rhtp_use_rules()) {
  groups <- rhtp_use_groups()
  bad_keys <- setdiff(unique(rules$file_key), names(files))
  if (length(bad_keys)) stop("[use] rules name file keys that are not in STATE_FILES: ",
                             paste(bad_keys, collapse = ", "), call. = FALSE)
  out <- lapply(names(files), function(k) rhtp_use_category(uc_read(files[[k]]), k, rules, groups))
  names(out) <- names(files)
  # A rule that reaches no row at all is stale (a value retyped, a file rebuilt).
  reach <- unique(unlist(lapply(names(files), function(k) {
    d <- rhtp_use_fields(uc_read(files[[k]]))
    rk <- rules[rules$file_key == k, , drop = FALSE]
    rk$rule_id[vapply(seq_len(nrow(rk)), function(j) {
      f <- rk$match_field[j]; f %in% names(d) && any(d[[f]] == rk$match_value[j])
    }, TRUE)]
  })))
  unused <- setdiff(rules$rule_id, reach)
  if (length(unused)) stop("[use] rules that match no award row: ", paste(unused, collapse = ", "), call. = FALSE)
  out
}

uc_apply <- function(files = uc_state_files()) {
  cols <- uc_compute(files)
  for (k in names(files)) rhtp_use_write(files[[k]], cols[[k]])
  u <- dplyr::bind_rows(cols)
  message("[use] wrote ", length(RHTP_USE_COLUMNS), " columns to ", length(files), " files (",
          nrow(u), " rows): ", paste(names(table(u$use_category_basis)), table(u$use_category_basis),
                                     sep = " ", collapse = ", "))
  invisible(cols)
}

uc_validate <- function(files = uc_state_files()) {
  cols <- uc_compute(files)
  for (k in names(files)) {
    d <- uc_read(files[[k]])
    for (col in RHTP_USE_COLUMNS) {
      if (!col %in% names(d) || !identical(d[[col]], cols[[k]][[col]])) {
        stop("[use] ", k, ": committed ", col, " differs from the computed layer. ",
             "Re-run Rscript R/11_use_categories.R --apply.", call. = FALSE)
      }
    }
  }
  invisible(cols)
}

#' Every Year 1 award row with its use columns and its summary call (reads the
#' committed files; computes nothing).
uc_rows <- function(files = uc_state_files()) {
  dplyr::bind_rows(lapply(names(files), function(k) {
    d <- readr::read_csv(here::here(files[[k]]), col_types = readr::cols(.default = "c"),
                         na = c("", "NA"), progress = FALSE)
    if (!all(RHTP_USE_COLUMNS %in% names(d))) {
      stop("[use] ", files[[k]], " has no use-category columns. Re-run Rscript R/11_use_categories.R --apply.",
           call. = FALSE)
    }
    d <- rhtp_year1_only(d, k)
    col <- function(c) if (c %in% names(d)) d[[c]] else rep(NA_character_, nrow(d))
    tibble::tibble(file_key = k, state = d$state, row_no = d$row_no, awardee = d$awardee,
                   amount = suppressWarnings(as.numeric(d$amount)), flag_reason = col("flag_reason"),
                   call = d$summary_hospital_call,
                   use_category_primary = d$use_category_primary, use_group_primary = d$use_group_primary,
                   use_categories_all = dplyr::coalesce(d$use_categories_all, ""),
                   use_category_basis = d$use_category_basis,
                   use_category_confidence = dplyr::coalesce(d$use_category_confidence, ""),
                   use_category_quote = dplyr::coalesce(d$use_category_quote, ""),
                   use_category_source = dplyr::coalesce(d$use_category_source, ""),
                   use_category_text_method = dplyr::coalesce(d$use_category_text_method, ""))
  }))
}

uc_report <- function() {
  r <- uc_rows() %>% dplyr::filter(!grepl("ADMINISTRATOR_PASS_THROUGH_UNRESOLVED", dplyr::coalesce(flag_reason, "")))
  r$amt <- dplyr::coalesce(r$amount, 0)
  b <- r %>% dplyr::group_by(use_category_basis) %>%
    dplyr::summarise(rows = dplyr::n(), usd = sum(amt), .groups = "drop") %>%
    dplyr::mutate(row_share = round(100 * rows / sum(rows), 1), usd_share = round(100 * usd / sum(usd), 1))
  print(as.data.frame(b), right = FALSE)
  g <- r %>% dplyr::group_by(use_group_primary) %>%
    dplyr::summarise(rows = dplyr::n(), usd = sum(amt), .groups = "drop") %>% dplyr::arrange(dplyr::desc(usd))
  print(as.data.frame(g), right = FALSE)
  invisible(list(basis = b, group = g))
}

# -- SESSION 124 (owner ruling 7a-b): CMS obligation-report headings ---------------
#
# CMS's Obligated Funds Report (10-14 edition, parsed by R/00e into
# cms_obligations_bp1_lines_20261014.csv) prints each state's initiatives with
# CATEGORY headings, which are the NOFO's uses of funds by name. A heading is
# programme-level evidence (basis CMS_REPORT_HEADING, MEDIUM). It is tied to a
# crosswalk rule only two ways, never by a fuzzy match:
#   INITIATIVE  the CMS initiative and the rule's initiative_as_printed are the
#               same name after normalisation (case, "&"/"and", punctuation, a
#               leading "Initiative N:" and a trailing "Initiative" removed),
#               and CMS prints exactly ONE programmatic heading under it;
#   LINE        a hand-reviewed entry (UC_HEADING_LINES) naming one report line
#               whose text names the rule's programme.
UC_HEADING_LINES <- tibble::tribble(
  ~rule_id, ~cms_line_id, ~link_basis,
  "MS-X01", "MS-006-06-06", "hand-reviewed (session 124): the line reads 'for the Rural Capital Care Gap Closure Grant Program', the rule's programme (award_pool 'Rural Capital Project Care Gap Closure (RCGC)')",
  "OK-X18", "OK-003-12-31", "hand-reviewed (session 124): the line reads 'for building joint resiliency for rural hospitals through a rural-focused provider collaborative', the rule's programme (LifeCare's FSRS description 'CREATING JOINT RESILIENCY THROUGH A RURAL-FOCUSED PROVIDER COLLABORATIVE')")
UC_LINES <- "data/reference/cms_obligations_bp1_lines_20261014.csv"
UC_REPORT_PDF <- "data/raw/cms/obligations/2026-07-31/RHTP-Obligated-Funds-20261014.pdf"

uc_heading_norm <- function(x) {
  x <- tolower(gsub("&", " and ", x, fixed = TRUE))
  x <- sub("^\\s*initiative\\s*[0-9]+\\s*:\\s*", "", x)
  x <- gsub("\\binitiative\\b", " ", x)
  gsub("[^a-z0-9]", "", x)
}

uc_headings_build <- function() {
  l <- readr::read_csv(here::here(UC_LINES), col_types = readr::cols(.default = "c"), progress = FALSE) %>%
    dplyr::filter(!is.na(category), category %in% names(RHTP_USE_CMS_HEADING_LETTER))
  x <- readr::read_csv(here::here(RHTP_USE_CROSSWALK), col_types = readr::cols(.default = "c"),
                       na = character(), progress = FALSE)
  one <- l %>% dplyr::group_by(state, initiative) %>%
    dplyr::summarise(k = dplyr::n_distinct(RHTP_USE_CMS_HEADING_LETTER[category]), category = dplyr::first(category),
                     line = dplyr::first(line_id), hquote = dplyr::first(description_clean), .groups = "drop") %>%
    dplyr::filter(k == 1) %>% dplyr::mutate(nn = uc_heading_norm(initiative))
  ini <- x %>% dplyr::mutate(nn = uc_heading_norm(initiative_as_printed)) %>%
    dplyr::inner_join(one, by = c("state", "nn")) %>%
    dplyr::transmute(rule_id = crosswalk_id, state, heading_letter = unname(RHTP_USE_CMS_HEADING_LETTER[category]),
                     heading_as_printed = category, heading_level = "INITIATIVE", cms_initiative = initiative,
                     cms_line_id = line, heading_quote = hquote, heading_archive = UC_REPORT_PDF,
                     quote_text_path = UC_LINES,
                     link_basis = "exact initiative name after normalisation; CMS prints one programmatic heading under it")
  ln <- UC_HEADING_LINES %>% dplyr::inner_join(l %>% dplyr::select(cms_line_id = line_id, state, initiative,
                                                                   category, description_clean), by = "cms_line_id")
  if (nrow(ln) != nrow(UC_HEADING_LINES)) stop("[use] a hand heading line is not in the report.", call. = FALSE)
  ln <- ln %>% dplyr::transmute(rule_id, state, heading_letter = unname(RHTP_USE_CMS_HEADING_LETTER[category]),
                                heading_as_printed = category, heading_level = "LINE", cms_initiative = initiative,
                                cms_line_id, heading_quote = description_clean, heading_archive = UC_REPORT_PDF,
                                quote_text_path = UC_LINES, link_basis)
  h <- dplyr::bind_rows(ln, ini %>% dplyr::filter(!rule_id %in% ln$rule_id)) %>% dplyr::arrange(state, rule_id)
  readr::write_csv(h, here::here(RHTP_USE_CMS_HEADINGS), na = "")
  message("[use] wrote ", nrow(h), " CMS headings (", sum(h$heading_level == "LINE"), " line-level, ",
          sum(h$heading_level == "INITIATIVE"), " initiative-level) to ", RHTP_USE_CMS_HEADINGS)
  invisible(h)
}

if (sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--headings" %in% args) uc_headings_build()
  if ("--apply" %in% args) uc_apply()
  if ("--validate" %in% args) { uc_validate(); message("[use] all assertions pass.") }
  if ("--report" %in% args) uc_report()
  if (!length(intersect(args, c("--apply", "--validate", "--report", "--headings")))) {
    message("Usage: Rscript R/11_use_categories.R --apply | --validate | --report")
  }
}
