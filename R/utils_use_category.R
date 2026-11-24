# R/utils_use_category.R -- RHTP use-of-funds categories (session 123)
#
# OWNER DIRECTION (2026-11-24). Classify every Year 1 award, hospital and
# non-hospital alike, by the RHTP ACTIVITY it funds, using CMS's own uses of
# funds (the NOFO's letters A-K, Section 71401 of Public Law 119-21), wherever
# the evidence allows. "Not stated" is an acceptable answer; a guess is not.
#
# THE RULE: READ THE ACTIVITY, NEVER THE RECIPIENT. This is the mirror of
# §0.3a, which reads the recipient and never the activity. A row is matched
# only on ACTIVITY fields (RHTP_USE_MATCH_FIELDS): a round, initiative,
# programme label or the award's own description. The recipient's name, type,
# flow, hospital call and spend category are never read, and a test scrambles
# them and requires the output not to move. The `row` locator (`<row_no>|
# <awardee>`) finds one row whose activity is printed only in the archived award
# source; the awardee there is a key, never evidence, and the quote must come
# from the source.
#
# THE SEVEN COLUMNS, written onto every award row by rhtp_use_category() (via
# R/11_use_categories.R --apply, after R/09b's overlays and R/07):
#   use_category_primary     A-K | MULTIPLE | NOT_STATED
#   use_group_primary        the owner group of that letter | MULTIPLE | NOT_STATED
#   use_categories_all       every letter the evidence supports, ";" in NOFO order
#   use_category_basis       AWARD_SOURCE | INITIATIVE_CROSSWALK | PURPOSE_TEXT | NOT_STATED
#   use_category_confidence  HIGH | MEDIUM | LOW (empty when NOT_STATED)
#   use_category_quote       the sentence or label relied on (and the pointer, if any)
#   use_category_source      the archive path(s)
#
# EVIDENCE, STRONGEST FIRST (the first that applies wins; within a basis, the
# most specific match wins; two rules at the same basis and specificity that
# disagree stop the build):
#   1 AWARD_SOURCE (HIGH)          config/use_category_cases.csv: the award document
#                                  states the CMS letter for the award or its round
#   2 INITIATIVE_CROSSWALK (MEDIUM) config/initiative_use_crosswalk.csv: the award's
#                                  initiative/round, tied to letters by the state's plan
#   3 PURPOSE_TEXT (LOW)           config/use_category_cases.csv: the award's own
#                                  description, hand-read, one call per description
#   4 NOT_STATED
#
# PRIMARY. One group in the evidence -> that group is primary. Several groups:
# the letter the award's OWN text points to (primary_letter + primary_quote),
# else MULTIPLE. C, D and F share a group, so C;F is HEALTH_IT_TECHNOLOGY, never
# MULTIPLE. Where the evidence spans letters inside one group and nothing points
# to one, use_category_primary carries the FIRST of them in NOFO order: the
# group is what is evidenced, and every report reads the group. An award's
# dollars are NEVER divided across categories.
#
# Every rule carries a verbatim quote, an archive path that exists, and a text
# file in which the quote appears (whitespace collapsed, tags stripped); the
# loader refuses a rule that fails any of these. No fuzzy matching anywhere.

RHTP_USE_COLUMNS <- c("use_category_primary", "use_group_primary", "use_categories_all",
                      "use_category_basis", "use_category_confidence", "use_category_quote",
                      "use_category_source")
RHTP_USE_CATEGORIES_CSV <- "data/reference/rhtp_use_categories.csv"
RHTP_USE_CASES <- "config/use_category_cases.csv"
RHTP_USE_CROSSWALK <- "config/initiative_use_crosswalk.csv"
RHTP_USE_LETTERS <- LETTERS[1:11]
RHTP_USE_BASES <- c("AWARD_SOURCE", "INITIATIVE_CROSSWALK", "PURPOSE_TEXT", "NOT_STATED")
RHTP_USE_CONFIDENCE <- c(AWARD_SOURCE = "HIGH", INITIATIVE_CROSSWALK = "MEDIUM", PURPOSE_TEXT = "LOW")
RHTP_USE_PLAN_SOURCE_TYPES <- c("CMS_ABSTRACT", "BUDGET_NARRATIVE", "PROJECT_NARRATIVE",
                                "STATE_SOLICITATION", "STATE_PROGRAM_PAGE", "CMS_ANNOUNCEMENT")
# Owner-facing labels (owner direction 11-24), in report order.
RHTP_USE_GROUP_LABELS <- c(
  PREVENTION_CHRONIC_DISEASE = "Prevention and chronic disease",
  DIRECT_PROVIDER_PAYMENTS = "Direct provider payments",
  HEALTH_IT_TECHNOLOGY = "Health IT and technology",
  WORKFORCE = "Workforce",
  SERVICE_LINES_CARE_AVAILABILITY = "Service lines and care availability",
  BEHAVIORAL_HEALTH = "Behavioral health",
  CARE_DELIVERY_PAYMENT_TRANSFORMATION = "Care delivery and payment transformation",
  CAPITAL_INFRASTRUCTURE = "Capital and infrastructure",
  PARTNERSHIPS_REGIONAL_NETWORKS = "Partnerships and regional networks",
  MULTIPLE = "Multiple",
  NOT_STATED = "Not stated")

# ACTIVITY fields only, ranked by specificity (1 = one row). The recipient's
# name, type, flow, call and category are not here and can never be matched.
RHTP_USE_MATCH_FIELDS <- c(
  row = 1L,
  fsrs_description = 2L, project_description = 2L, project_summary = 2L, description = 2L,
  use_of_funding = 2L, project_title = 2L, activity = 2L, activity_raw = 2L,
  activity_type_raw = 3L, initiative_raw = 3L, initiative = 3L, sub_initiative = 3L,
  grow_initiative = 3L, initiative_fund_use = 3L, strategy = 3L, project = 3L,
  project_type = 3L, category = 3L,
  round_name = 4L, funding_opportunity = 4L, solicitation_number = 4L, list_section = 4L,
  section = 4L, award_pool = 4L, source_document_title = 4L)

rhtp_use_groups <- function() {
  g <- readr::read_csv(here::here(RHTP_USE_CATEGORIES_CSV), col_types = readr::cols(.default = "c"),
                       progress = FALSE)
  stopifnot(identical(g$letter, RHTP_USE_LETTERS), all(g$use_group %in% names(RHTP_USE_GROUP_LABELS)))
  stats::setNames(g$use_group, g$letter)
}

#' The derived activity fields: the FFATA description quoted in a FSRS row's
#' note, and the one-row locator.
rhtp_use_fields <- function(d) {
  d <- as.data.frame(d, stringsAsFactors = FALSE)
  note <- if ("note" %in% names(d)) dplyr::coalesce(d$note, "") else rep("", nrow(d))
  m <- regmatches(note, regexec("Description as filed: '(.*?)'\\.( |$)", note))
  d$fsrs_description <- vapply(m, function(x) if (length(x) > 1) x[2] else "", "")
  d$row <- paste(dplyr::coalesce(d$row_no, ""), dplyr::coalesce(d$awardee, ""), sep = "|")
  d
}

#' Whitespace-collapsed, tag-stripped text for the quote check.
rhtp_use_norm <- function(x) {
  x <- gsub("<[^>]*>", " ", x)
  x <- gsub("&nbsp;|&#160;", " ", x)
  x <- gsub("&amp;", "&", x, fixed = FALSE)
  x <- gsub("[‘’‚′]", "'", x)
  x <- gsub("[“”„″]", "\"", x)
  x <- gsub("[‐-―−]", "-", x)
  x <- gsub("[­​‌‍﻿]", "", x)
  x <- gsub(" ", " ", x)
  gsub("\\s+", " ", trimws(x))
}

rhtp_use_text_cache <- new.env(parent = emptyenv())
rhtp_use_text <- function(path) {
  if (!exists(path, envir = rhtp_use_text_cache, inherits = FALSE)) {
    raw <- readBin(here::here(path), "raw", file.info(here::here(path))$size)
    txt <- iconv(rawToChar(raw[raw != as.raw(0)]), "UTF-8", "UTF-8", sub = " ")
    assign(path, rhtp_use_norm(txt), envir = rhtp_use_text_cache)
  }
  get(path, envir = rhtp_use_text_cache)
}

rhtp_use_split <- function(x) {
  v <- trimws(unlist(strsplit(dplyr::coalesce(x, ""), ";", fixed = TRUE)))
  RHTP_USE_LETTERS[RHTP_USE_LETTERS %in% v[nzchar(v)]]
}

#' Every rule, validated. Refuses a rule that fails any evidence check.
rhtp_use_rules <- function(check_quotes = TRUE) {
  rd <- function(p) readr::read_csv(here::here(p), col_types = readr::cols(.default = "c"),
                                    na = character(), progress = FALSE)
  x <- rd(RHTP_USE_CROSSWALK)
  c <- rd(RHTP_USE_CASES)
  need_x <- c("crosswalk_id", "state", "file_key", "match_field", "match_value", "initiative_as_printed",
              "letters", "primary_letter", "primary_quote", "primary_source", "plan_document",
              "plan_source_type", "link_basis", "archive_path", "quote_text_path", "quote", "note")
  need_c <- c("case_id", "state", "file_key", "match_field", "match_value", "basis", "letters",
              "primary_letter", "primary_quote", "primary_source", "archive_path", "quote_text_path",
              "quote", "note")
  if (!identical(names(x), need_x)) stop("[use] ", RHTP_USE_CROSSWALK, " columns differ from the schema.", call. = FALSE)
  if (!identical(names(c), need_c)) stop("[use] ", RHTP_USE_CASES, " columns differ from the schema.", call. = FALSE)
  if (any(!x$plan_source_type %in% RHTP_USE_PLAN_SOURCE_TYPES)) {
    stop("[use] crosswalk plan_source_type outside the vocabulary: ",
         paste(unique(x$plan_source_type[!x$plan_source_type %in% RHTP_USE_PLAN_SOURCE_TYPES]), collapse = ", "), call. = FALSE)
  }
  if (any(!nzchar(x$link_basis))) stop("[use] a crosswalk row has no link_basis.", call. = FALSE)
  if (any(!c$basis %in% c("AWARD_SOURCE", "PURPOSE_TEXT"))) {
    stop("[use] a case's basis is not AWARD_SOURCE or PURPOSE_TEXT.", call. = FALSE)
  }
  r <- dplyr::bind_rows(
    x %>% dplyr::transmute(rule_id = crosswalk_id, state, file_key, match_field, match_value,
                           basis = "INITIATIVE_CROSSWALK", letters, primary_letter, primary_quote,
                           primary_source, archive_path, quote_text_path, quote),
    c %>% dplyr::transmute(rule_id = case_id, state, file_key, match_field, match_value, basis, letters,
                           primary_letter, primary_quote, primary_source, archive_path, quote_text_path, quote))
  bad <- function(cond, what) if (any(cond)) stop("[use] ", what, ": ",
                                                  paste(r$rule_id[cond], collapse = ", "), call. = FALSE)
  bad(duplicated(r$rule_id), "duplicate rule ids")
  bad(!r$match_field %in% names(RHTP_USE_MATCH_FIELDS), "match_field is not an activity field")
  bad(!nzchar(r$match_value), "empty match_value")
  lt <- lapply(r$letters, rhtp_use_split)
  raw_lt <- lapply(r$letters, function(s) trimws(unlist(strsplit(s, ";", fixed = TRUE))))
  bad(vapply(seq_along(lt), function(i) !length(lt[[i]]) || length(lt[[i]]) != length(raw_lt[[i]]), TRUE),
      "letters empty or outside A-K")
  bad(nzchar(r$primary_letter) & !mapply(function(p, l) p %in% l, r$primary_letter, lt),
      "primary_letter is not among the rule's letters")
  bad(nzchar(r$primary_letter) & (!nzchar(r$primary_quote) | !nzchar(r$primary_source)),
      "primary_letter with no primary_quote / primary_source")
  bad(!nzchar(r$quote) | !nzchar(r$archive_path) | !nzchar(r$quote_text_path), "no quote or no archive path")
  bad(!file.exists(here::here(r$archive_path)), "archive_path does not exist")
  bad(!file.exists(here::here(r$quote_text_path)), "quote_text_path does not exist")
  ps <- nzchar(r$primary_source)
  bad(ps & !vapply(strsplit(r$primary_source, " ; ", fixed = TRUE),
                   function(p) all(file.exists(here::here(trimws(p)))), TRUE), "primary_source does not exist")
  key <- paste(r$file_key, r$match_field, r$match_value, r$basis, sep = "\r")
  bad(duplicated(key) | duplicated(key, fromLast = TRUE), "two rules share file + field + value + basis")
  if (check_quotes) {
    miss <- !vapply(seq_len(nrow(r)), function(i) {
      grepl(rhtp_use_norm(r$quote[i]), rhtp_use_text(r$quote_text_path[i]), fixed = TRUE)
    }, TRUE)
    bad(miss, "quote not found verbatim in its quote_text_path")
  }
  r$letters_v <- lt
  r$spec <- unname(RHTP_USE_MATCH_FIELDS[r$match_field])
  r$rank <- match(r$basis, RHTP_USE_BASES)
  r
}

#' THE ONE FUNCTION THAT WRITES THE SEVEN COLUMNS. `d` is an award file (all
#' columns character); `file_key` its STATE_FILES key. Returns one row per row
#' of `d`, plus the matched rule id (rule_id, not written to the file).
rhtp_use_category <- function(d, file_key, rules = rhtp_use_rules(), groups = rhtp_use_groups()) {
  d <- rhtp_use_fields(d)
  rk <- rules[rules$file_key == file_key, , drop = FALSE]
  n <- nrow(d)
  hit <- rep(NA_integer_, n)
  if (nrow(rk)) {
    cand <- lapply(seq_len(nrow(rk)), function(j) {
      f <- rk$match_field[j]
      if (!f %in% names(d)) return(integer(0))
      which(!is.na(d[[f]]) & d[[f]] == rk$match_value[j])
    })
    for (i in seq_len(n)) {
      js <- which(vapply(cand, function(w) i %in% w, TRUE))
      if (!length(js)) next
      js <- js[order(rk$rank[js], rk$spec[js])]
      top <- js[rk$rank[js] == rk$rank[js[1]] & rk$spec[js] == rk$spec[js[1]]]
      if (length(top) > 1) {
        sig <- unique(paste(rk$letters[top], rk$primary_letter[top]))
        if (length(sig) > 1) stop("[use] ", file_key, " row ", d$row_no[i], ": rules ",
                                  paste(rk$rule_id[top], collapse = ", "),
                                  " match at the same basis and specificity and disagree.", call. = FALSE)
      }
      hit[i] <- top[1]
    }
  }
  out <- tibble::tibble(use_category_primary = rep("NOT_STATED", n), use_group_primary = "NOT_STATED",
                        use_categories_all = "", use_category_basis = "NOT_STATED",
                        use_category_confidence = "", use_category_quote = "", use_category_source = "",
                        use_rule_id = "")
  for (i in which(!is.na(hit))) {
    r <- rk[hit[i], ]
    lt <- r$letters_v[[1]]
    gp <- unique(unname(groups[lt]))
    prim <- if (nzchar(r$primary_letter)) r$primary_letter else if (length(gp) == 1) lt[1] else "MULTIPLE"
    out$use_category_primary[i] <- prim
    out$use_group_primary[i] <- if (prim == "MULTIPLE") "MULTIPLE" else unname(groups[[prim]])
    out$use_categories_all[i] <- paste(lt, collapse = ";")
    out$use_category_basis[i] <- r$basis
    out$use_category_confidence[i] <- RHTP_USE_CONFIDENCE[[r$basis]]
    out$use_category_quote[i] <- if (nzchar(r$primary_letter)) {
      paste0(r$quote, " || Primary ", r$primary_letter, ": ", r$primary_quote)
    } else r$quote
    out$use_category_source[i] <- if (nzchar(r$primary_source) && r$primary_source != r$archive_path) {
      paste(r$archive_path, r$primary_source, sep = " ; ")
    } else r$archive_path
    out$use_rule_id[i] <- r$rule_id
  }
  out
}

#' Write the seven columns onto a file read with rhtp_summary_read().
rhtp_use_write <- function(path, cols) {
  d <- readr::read_csv(here::here(path), col_types = readr::cols(.default = "c"), na = character(),
                       progress = FALSE, trim_ws = FALSE)
  if (nrow(d) != nrow(cols)) stop("[use] row count changed: ", path, call. = FALSE)
  for (col in RHTP_USE_COLUMNS) d[[col]] <- cols[[col]]
  readr::write_csv(d, here::here(path), na = "")
  invisible(d)
}

# -- pool-level money: the round's category ------------------------------------
#
# R/08's award total adds pool-level amounts that sit on no priced row
# (R/03aw's y1_file_figures(), plus the summary-call pools outside the files).
# Each is itemised here by its pool and given ITS ROUND's category: the rules
# are evaluated on a synthetic row carrying only the fields that are CONSTANT
# across the pool's member rows (the round's own labels), so a row-level
# description can never classify a pool. No round category -> NOT_STATED.

rhtp_use_const_row <- function(d) {
  keep <- vapply(names(d), function(cn) length(unique(d[[cn]])) == 1, TRUE)
  keep[c("row_no", "awardee", "row", "fsrs_description")] <- FALSE
  one <- d[1, , drop = FALSE]
  for (cn in names(d)[!keep[names(d)] %in% TRUE]) one[[cn]] <- NA_character_
  one
}

#' One row per pool-level item, by state, with its round's category and its
#' hospital call (HOSPITAL only where a summary-call pool with call HOSPITAL is
#' the same money, as R/08 counts it).
rhtp_use_pool_items <- function(files, rules = rhtp_use_rules(check_quotes = FALSE),
                                groups = rhtp_use_groups()) {
  # R/03aw's pool exclusion list, read from its source so the two cannot drift.
  y1 <- new.env()
  aw <- readLines(here::here("R", "03aw_year1_completion_status.R"))
  eval(parse(text = grep("^Y1_POOL_EXCLUDED <- ", aw, value = TRUE)), envir = y1)
  pools <- readr::read_csv(here::here("data/reference/summary_call_pools.csv"),
                           col_types = readr::cols(.default = "c"), progress = FALSE, na = c("", "NA"))
  items <- list()
  for (k in names(files)) {
    p <- files[[k]]
    d0 <- readr::read_csv(here::here(p), col_types = readr::cols(.default = "c"), na = character(),
                          progress = FALSE, trim_ws = FALSE)
    d0 <- rhtp_year1_only(d0, p)
    if (!nrow(d0)) next
    st <- unique(d0$state)[1]
    amt <- suppressWarnings(as.numeric(d0$amount))
    na0 <- function(x) { x[!nzchar(x)] <- NA; x }
    it <- NULL
    if (st == "GA" && k == "GA") {
      key <- paste(d0$phase, d0$initiative, sep = "\r")
      ia <- suppressWarnings(as.numeric(na0(d0$initiative_amount)))
      it <- tibble::tibble(key = key, ia = ia, amt = amt) %>% dplyr::group_by(key) %>%
        dplyr::summarise(usd = dplyr::first(ia) - sum(amt, na.rm = TRUE), .groups = "drop") %>%
        dplyr::filter(abs(usd) > 0.004)
      mem <- function(kk) key == kk
    } else if ("round_amount" %in% names(d0) && !(st %in% y1$Y1_POOL_EXCLUDED)) {
      r <- suppressWarnings(as.numeric(na0(d0$round_amount)))
      pk <- if ("award_pool" %in% names(d0)) d0$award_pool else d0$source_document_title
      kx <- is.na(amt) & !is.na(r)
      pl <- dplyr::distinct(tibble::tibble(key = pk[kx], usd = r[kx]))
      covered <- vapply(seq_len(nrow(pl)), function(i) {
        inp <- pk %in% pl$key[i] & !is.na(amt)
        any(!is.na(r[inp]) & abs(r[inp] - pl$usd[i]) < 0.005) && sum(amt[inp]) >= pl$usd[i]
      }, logical(1))
      it <- pl[!covered, , drop = FALSE]
      mem <- function(kk) pk == kk
    }
    if (!(st == "GA" && k == "GA") && "pool_amount" %in% names(d0)) {
      pa <- suppressWarnings(as.numeric(na0(d0$pool_amount)))
      kx <- is.na(amt) & !is.na(pa)
      it2 <- dplyr::distinct(tibble::tibble(key = d0$award_pool[kx], usd = pa[kx]))
      if (nrow(it2)) {
        if (!is.null(it) && nrow(it)) {
          m1 <- mem; pk2 <- d0$award_pool; ks1 <- it$key
          mem <- function(kk) if (kk %in% ks1) m1(kk) else pk2 == kk
          it <- dplyr::bind_rows(it, it2)
        } else {
          pk2 <- d0$award_pool; it <- it2; mem <- function(kk) pk2 == kk
        }
      }
    }
    if (st == "SD" && "round_id" %in% names(d0)) {
      inside <- sum(amt[d0$round_id %in% c("RS", "UNPLACED", "CCBHC")], na.rm = TRUE)
      # Priced rows inside a round counted whole elsewhere are netted out of the
      # pool-level figure (R/03aw). Each is netted at ITS OWN row's category, so
      # the round's money ends up, in total, at the round's category.
      ins <- which(d0$round_id %in% c("RS", "UNPLACED", "CCBHC") & !is.na(amt))
      if (length(ins)) items[[paste0(k, "_inside")]] <- tibble::tibble(
        state = st, file_key = k,
        pool_key = paste0("netted: priced row ", d0$row_no[ins], " inside a round counted whole (R/03aw)"),
        usd = -amt[ins], members = lapply(ins, function(j) seq_len(nrow(d0)) == j), d = list(d0),
        row_level = TRUE)
    }
    if (is.null(it) || !nrow(it)) next
    items[[k]] <- tibble::tibble(state = st, file_key = k, pool_key = it$key, usd = it$usd,
                                 members = lapply(it$key, mem), d = list(d0))
  }
  items <- dplyr::bind_rows(items)
  # The summary-call pools: in-file ones lend their call to the item that is the
  # same money; the others are items of their own.
  y7 <- new.env()
  src <- readLines(here::here("R", "07_summary_calls.R"))
  i0 <- grep("^sc_pool_members <- function", src); i1 <- i0 + which(src[(i0 + 1):length(src)] == "}")[1]
  eval(parse(text = src[i0:i1]), envir = y7)
  if (!"row_level" %in% names(items)) items$row_level <- NA
  items$call <- "NOT_HOSPITAL"; items$pool_id <- ""
  extra <- list()
  for (i in seq_len(nrow(pools))) {
    pl <- pools[i, ]
    d0 <- readr::read_csv(here::here(files[[pl$file_key]]), col_types = readr::cols(.default = "c"),
                          na = character(), progress = FALSE, trim_ws = FALSE)
    d0 <- rhtp_year1_only(d0, pl$file_key)
    m <- y7$sc_pool_members(pl, d0)
    if (identical(pl$in_file_round_figures, "TRUE")) {
      j <- which(items$file_key == pl$file_key & vapply(items$members, function(x) identical(x, m), TRUE))
      if (length(j) != 1) stop("[use] summary pool ", pl$pool_id, " matches ", length(j), " pool-level items.", call. = FALSE)
      if (abs(items$usd[j] - as.numeric(pl$pool_usd)) > 0.005) {
        stop("[use] summary pool ", pl$pool_id, " is $", pl$pool_usd, " but its pool-level item is $", items$usd[j], call. = FALSE)
      }
      items$call[j] <- pl$call; items$pool_id[j] <- pl$pool_id
    } else {
      extra[[pl$pool_id]] <- tibble::tibble(state = pl$state, file_key = pl$file_key, pool_key = pl$pool_name,
                                            usd = as.numeric(pl$pool_usd), members = list(m), d = list(d0),
                                            call = pl$call, pool_id = pl$pool_id)
    }
  }
  items <- dplyr::bind_rows(items, dplyr::bind_rows(extra))
  cats <- lapply(seq_len(nrow(items)), function(i) {
    dd <- items$d[[i]][items$members[[i]], , drop = FALSE]
    if (!nrow(dd)) return(rhtp_use_category(items$d[[i]][0, ], items$file_key[i], rules, groups))
    if (isTRUE(items$row_level[i])) return(rhtp_use_category(dd, items$file_key[i], rules, groups))
    one <- rhtp_use_const_row(rhtp_use_fields(dd))
    rhtp_use_category(one[, setdiff(names(one), c("fsrs_description", "row")), drop = FALSE],
                      items$file_key[i], rules, groups)
  })
  cats <- dplyr::bind_rows(lapply(cats, function(x) if (nrow(x)) x[1, ] else
    tibble::tibble(use_category_primary = "NOT_STATED", use_group_primary = "NOT_STATED", use_categories_all = "",
                   use_category_basis = "NOT_STATED", use_category_confidence = "", use_category_quote = "",
                   use_category_source = "", use_rule_id = "")))
  dplyr::bind_cols(items %>% dplyr::select(state, file_key, pool_key, pool_id, usd, call), cats)
}
