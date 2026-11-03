#!/usr/bin/env Rscript
# 00e_cms_obligation_report_v2.R ----------------------------------------------
#
# CMS's RHTP OBLIGATED FUNDS REPORT, SECOND EDITION (session 113), and its
# DIFF against the first.
#
# WHAT IT IS. "RHTP-Obligated-Funds-20261014.pdf", 105 pages, created
# 2026-10-19T23:29Z in Microsoft Word, Last-Modified 2026-10-19T23:33Z. Same
# data as the 10-08 edition (as of 2026-07-31, Year 1 Annual Report). CMS
# swapped it into the SAME media entity on the medicaid.gov resources page,
# and the old URL now 301s to it. Manifest beside the PDF.
#
# NEVER OVERWRITE THE 10-08 FILES. R/00c still writes cms_obligations_bp1_*.csv
# from the 10-08 edition, and R/00d and R/03cb read them (R/03cb's rows carry
# 10-08 line ids). This file writes its own dated set, suffix "_20261014":
#   cms_obligations_bp1_{state,lines,headers,checks}_20261014.csv
# and the diff, cms_obligations_bp1_diff_10082026_20261014.csv.
#
# HOW IT PARSES (§0.4, parse never transcribe). The repo's own reader
# (`rhtp_pdf_lines()`) cannot read this file: the Word fonts' ToUnicode maps
# come out as glyph soup ("MNMOMPM", "QRSTJKTL..."). Poppler reads it. So, as
# for Nevada's BP1 report (R/03u --parse-bp1), poppler is a ONE-TIME step:
# `--extract-lines` runs `pdftotext -bbox-layout` and writes the line records
# (page, x, y, text) to data/interim/cms_obligations_20261014_pdf_lines.csv,
# which is COMMITTED and is the parse source from then on. Nothing else here
# needs poppler; --validate and --build run from the CSV.
#
# The lines are then handed to R/00c's own walker, `obl_parse()`, unchanged.
# The Word layout is R/00c's layout at another scale: headers x 50.5,
# bullets x 68.5, continuations and notes x 86.5, against R/00c's 210 / 285 /
# 360. One linear map (x' = 210 + (x - 50.5) * 150/36) puts all three on
# R/00c's columns exactly, the bullet glyph "▪" is read as R/00c's "§", and the
# page footer (the state name in capitals, and "State-reported data as of")
# is dropped before the walk. Every R/00c assertion that is a statement about
# the DATA (50 states, the CMS category set, no amountless bullet, Hawaii's
# repeated figures, put-to-work <= award, as-of 7/31/2026) is run on this
# edition too. The two that are statements about the 10-08 TYPESETTING (which
# headers wrap, SD's bare "$") are re-pinned here for this edition.
#
# Usage:
#   Rscript R/00e_cms_obligation_report_v2.R --extract-lines   # ONE-TIME, needs poppler
#   Rscript R/00e_cms_obligation_report_v2.R --validate
#   Rscript R/00e_cms_obligation_report_v2.R --build           # v2 CSVs + the diff
#   Rscript R/00e_cms_obligation_report_v2.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr); library(tidyr)
})
source(here::here("R", "00c_cms_obligation_report.R"))

OBL2_PDF     <- file.path(OBL_DIR, "RHTP-Obligated-Funds-20261014.pdf")
OBL2_SHA256  <- "05e6f0a9c488aeed94766d1ba73581b72faeb5676cdc9e22e8fb76a0a27dbbcf"
OBL2_STAMP   <- "20261014"
OBL2_REPORT  <- as.Date("2026-10-14")   # CMS's own file stamp; posted 2026-10-19
OBL2_LINES_SRC <- here::here("data", "interim", "cms_obligations_20261014_pdf_lines.csv")

obl2_csv <- function(kind) here::here("data", "reference",
                                      paste0("cms_obligations_bp1_", kind, "_", OBL2_STAMP, ".csv"))
OBL2_DIFF_CSV <- here::here("data", "reference", "cms_obligations_bp1_diff_10082026_20261014.csv")

# Typesetting pins for THIS edition (R/00c pins the 10-08 edition's).
OBL2_WRAPPED      <- OBL_WRAPPED       # the same 14 as 10-08
OBL2_BARE_DOLLAR  <- OBL_BARE_DOLLAR   # SD, as 10-08

obl2_assert_archive <- function() {
  path <- here::here(OBL2_PDF)
  if (!file.exists(path)) stop("[CMS obligations v2] archive missing: ", OBL2_PDF, call. = FALSE)
  got <- digest::digest(file = path, algo = "sha256")
  if (!identical(got, OBL2_SHA256)) {
    stop("[CMS obligations v2] ", OBL2_PDF, " SHA-256 is ", got, ", expected ", OBL2_SHA256,
         ". The archive moved; read it before re-pinning.", call. = FALSE)
  }
  invisible(TRUE)
}

#' ONE-TIME: poppler line boxes -> the committed line CSV
obl2_extract_lines <- function() {
  obl2_assert_archive()
  if (!nzchar(Sys.which("pdftotext"))) {
    stop("[CMS obligations v2] --extract-lines needs poppler's pdftotext; the committed ",
         basename(OBL2_LINES_SRC), " is the parse source otherwise.", call. = FALSE)
  }
  html <- tempfile(fileext = ".html")
  on.exit(unlink(html), add = TRUE)
  rc <- system2("pdftotext", c("-bbox-layout", shQuote(here::here(OBL2_PDF)), shQuote(html)))
  if (!identical(as.integer(rc), 0L)) stop("[CMS obligations v2] pdftotext failed.", call. = FALSE)
  doc <- xml2::read_html(html)
  out <- purrr::imap_dfr(xml2::xml_find_all(doc, "//page"), function(p, i) {
    ln <- xml2::xml_find_all(p, ".//line")
    tibble::tibble(
      page = i,
      x = as.numeric(xml2::xml_attr(ln, "xmin")),
      y = as.numeric(xml2::xml_attr(ln, "ymin")),
      text = vapply(ln, function(l) paste(xml2::xml_text(xml2::xml_find_all(l, ".//word")),
                                          collapse = " "), character(1)))
  })
  readr::write_csv(out, OBL2_LINES_SRC, na = "")
  message("[CMS obligations v2] wrote ", nrow(out), " lines to ", basename(OBL2_LINES_SRC),
          " (sha256 ", digest::digest(file = OBL2_LINES_SRC, algo = "sha256"), ")")
  invisible(out)
}

#' Poppler's line order is not reading order, and it paints some bullet
#' glyphs as a line of their own ("▪" at x 68.5) beside the bullet's text
#' (x 86.5, the same baseline to within a point). Sort by page, then y, then
#' x, and join each lone glyph to the text on its baseline. A lone glyph
#' with no text on its baseline is refused: that is a reading we have not
#' looked at.
obl2_join_lone_bullets <- function(l) {
  l <- l %>% dplyr::arrange(page, y, x)
  lone <- which(l$text == "\u25aa")
  drop <- integer(0)
  for (i in lone) {
    cand <- which(l$page == l$page[i] & abs(l$y - l$y[i]) < 1.5 & l$x > l$x[i] &
                    l$text != "\u25aa")
    if (length(cand) != 1L) {
      stop("[CMS obligations v2] a lone bullet glyph on page ", l$page[i], " y ", l$y[i],
           " has ", length(cand), " text lines on its baseline", call. = FALSE)
    }
    l$text[i] <- paste("\u25aa", l$text[cand])
    drop <- c(drop, cand)
  }
  if (length(drop)) l <- l[-drop, , drop = FALSE]
  l %>% dplyr::arrange(page, y, x)
}

#' The committed line records, mapped onto R/00c's columns
obl2_raw_lines <- function() {
  if (!file.exists(OBL2_LINES_SRC)) {
    stop("[CMS obligations v2] ", basename(OBL2_LINES_SRC), " missing; run --extract-lines.", call. = FALSE)
  }
  unq <- function(x) stringr::str_replace_all(x, "[\u2019']", "")
  caps <- unq(toupper(obl_state_codes()$state_name))
  readr::read_csv(OBL2_LINES_SRC, show_col_types = FALSE, progress = FALSE,
                  col_types = readr::cols(page = "i", x = "d", y = "d", text = "c")) %>%
    dplyr::mutate(text = stringr::str_squish(text)) %>%
    obl2_join_lone_bullets() %>%
    dplyr::filter(page > 1L,
                  !(toupper(unq(text)) %in% caps & x > 200 & y > 700),   # the centred state-name footer
                  !stringr::str_detect(text, "^(State-reported data|Data submitted by State) as of")) %>%
    dplyr::mutate(x = 210 + (x - 50.5) * 150 / 36,
                  text = stringr::str_replace(text, "^▪\\s*", "§ ")) %>%
    dplyr::select(page, x, text)
}

#' This edition's description cleaning: R/00c's, plus the Word characters
obl2_clean_text <- function(x) {
  x %>%
    stringr::str_replace_all("[‐‑]", "-") %>%      # (non-breaking) hyphen
    stringr::str_replace_all("￼", " ") %>%               # object replacement char
    obl_clean_text()
}

#' Run R/00c's tables with this edition's dates
obl2_with_edition <- function(expr) {
  old <- list(OBL_REPORT = OBL_REPORT, OBL_WRAPPED = OBL_WRAPPED,
              OBL_BARE_DOLLAR = OBL_BARE_DOLLAR, obl_clean_text = obl_clean_text)
  env <- globalenv()
  assign("OBL_REPORT", OBL2_REPORT, envir = env)
  assign("OBL_WRAPPED", OBL2_WRAPPED, envir = env)
  assign("OBL_BARE_DOLLAR", OBL2_BARE_DOLLAR, envir = env)
  on.exit(for (k in names(old)) assign(k, old[[k]], envir = env), add = TRUE)
  force(expr)
}

obl2_parse <- function() {
  obl2_assert_archive()
  obl_parse(obl2_raw_lines())
}

obl2_lines_table <- function(p) {
  obl2_with_edition({
    ln <- obl_lines_table(p)
    ln$description_clean <- obl2_clean_text(ln$description_raw)
    ln
  })
}

obl2_assert <- function(p = obl2_parse()) obl2_with_edition(obl_assert(p))

# -- The diff ----------------------------------------------------------------
#
# Four levels. STATE on bp1_award and funds_put_to_work. INITIATIVE and
# CATEGORY on (state, sequence, name, amount). LINE on (state, initiative,
# category, amount, normalised description), as a MULTISET -- a line is
# identified by what it says, never by its line_id, because a removed bullet
# renumbers every bullet after it. Description normalisation erases the
# typesetting differences only (ligatures, hyphens, spacing, case).
#
# The 10-08 edition's font ALSO maps a second ligature to "h" ("Ehiciency",
# "ahordability", "ehorts"), which R/00c's W-repair does not reach. R/00c is
# left as it is (its output is the 10-08 record); the three spellings are
# repaired here, in the diff key only. R/00c's reader also drops the space at
# some line joins ("physicalactivity"), so the key keeps letters and digits
# alone: two lines differing only in spacing, punctuation, glyphs or case are
# the same line.
obl2_norm_desc <- function(x) {
  x %>% obl2_clean_text() %>%
    stringr::str_replace_all("(?i)(e|a)h(icien|ord|ort)", "\\1ff\\2") %>%
    tolower() %>%
    stringr::str_replace_all("[^a-z0-9]", "")
}

obl2_diff <- function(v1 = obl_parse(), v2 = obl2_parse()) {
  key_num <- function(x) sprintf("%.2f", x)
  s1 <- v1$states %>% dplyr::select(state, bp1_award, funds_put_to_work)
  s2 <- v2$states %>% dplyr::select(state, bp1_award, funds_put_to_work)
  sd <- dplyr::full_join(s1, s2, by = "state", suffix = c("_10082026", "_20261014")) %>%
    tidyr::pivot_longer(-state, names_to = c("field", ".value"),
                        names_pattern = "(.*)_(10082026|20261014)") %>%
    dplyr::filter(is.na(`10082026`) | is.na(`20261014`) | abs(`10082026` - `20261014`) > 0.005) %>%
    dplyr::transmute(level = "STATE", state, initiative = NA_character_, category = NA_character_,
                     change = "FIGURE_CHANGED", field,
                     amount_10082026 = `10082026`, amount_20261014 = `20261014`,
                     description = NA_character_)

  hk <- function(h) h %>% dplyr::mutate(k = paste(state, level, initiative_seq,
                                                  dplyr::coalesce(category_seq, 0L),
                                                  obl2_norm_desc(name), key_num(amount)))
  h1 <- hk(v1$headers); h2 <- hk(v2$headers)
  hd <- dplyr::bind_rows(
    h1 %>% dplyr::filter(!k %in% h2$k) %>% dplyr::mutate(change = "ONLY_IN_10082026"),
    h2 %>% dplyr::filter(!k %in% h1$k) %>% dplyr::mutate(change = "ONLY_IN_20261014")) %>%
    dplyr::transmute(level, state, initiative, category = dplyr::if_else(level == "CATEGORY", name, NA_character_),
                     change, field = "header",
                     amount_10082026 = dplyr::if_else(change == "ONLY_IN_10082026", amount, NA_real_),
                     amount_20261014 = dplyr::if_else(change == "ONLY_IN_20261014", amount, NA_real_),
                     description = name)

  bk <- function(b) b %>%
    dplyr::mutate(k = paste(state, obl2_norm_desc(dplyr::coalesce(initiative, "")),
                            obl2_norm_desc(dplyr::coalesce(category, "")),
                            key_num(amount), obl2_norm_desc(description_raw))) %>%
    dplyr::group_by(k) %>% dplyr::mutate(occ = dplyr::row_number()) %>% dplyr::ungroup() %>%
    dplyr::mutate(kk = paste(k, occ))
  b1 <- bk(v1$bullets); b2 <- bk(v2$bullets)
  bd <- dplyr::bind_rows(
    b1 %>% dplyr::filter(!kk %in% b2$kk) %>% dplyr::mutate(change = "ONLY_IN_10082026"),
    b2 %>% dplyr::filter(!kk %in% b1$kk) %>% dplyr::mutate(change = "ONLY_IN_20261014")) %>%
    dplyr::transmute(level = "LINE", state, initiative, category, change, field = "bullet",
                     amount_10082026 = dplyr::if_else(change == "ONLY_IN_10082026", amount, NA_real_),
                     amount_20261014 = dplyr::if_else(change == "ONLY_IN_20261014", amount, NA_real_),
                     description = obl2_clean_text(description_raw))

  dplyr::bind_rows(sd, hd, bd) %>%
    dplyr::arrange(factor(level, c("STATE", "INITIATIVE", "CATEGORY", "LINE")), state, change)
}

obl2_build <- function() {
  p <- obl2_parse()
  obl2_assert(p)
  st <- obl2_with_edition(obl_state_table(p))
  readr::write_csv(st, obl2_csv("state"), na = "")
  readr::write_csv(obl2_lines_table(p), obl2_csv("lines"), na = "")
  readr::write_csv(p$headers %>% dplyr::select(-printed), obl2_csv("headers"), na = "")
  readr::write_csv(obl2_with_edition(obl_checks(p)), obl2_csv("checks"), na = "")
  d <- obl2_diff(v2 = p)
  readr::write_csv(d, OBL2_DIFF_CSV, na = "")
  message("[CMS obligations v2] wrote the four _", OBL2_STAMP, " tables and ",
          basename(OBL2_DIFF_CSV), " (", nrow(d), " differences)")
  invisible(p)
}

obl2_report <- function() {
  d <- readr::read_csv(OBL2_DIFF_CSV, show_col_types = FALSE)
  message("[CMS obligations v2] differences 10-08 -> 10-14 by level and kind:")
  print(d %>% dplyr::count(level, state, change), n = Inf)
  ck1 <- readr::read_csv(OBL_CHECK_CSV, show_col_types = FALSE)
  ck2 <- readr::read_csv(obl2_csv("checks"), show_col_types = FALSE)
  nk <- function(ck) ck %>% dplyr::mutate(ki = obl2_norm_desc(dplyr::coalesce(initiative, "")),
                                          kn = obl2_norm_desc(name))
  moved <- dplyr::full_join(nk(ck1) %>% dplyr::select(state, check, ki, kn, name, s1 = status),
                            nk(ck2) %>% dplyr::select(state, check, ki, kn, s2 = status),
                            by = c("state", "check", "ki", "kn")) %>%
    dplyr::select(-ki, -kn) %>%
    dplyr::filter(is.na(s1) | is.na(s2) | s1 != s2)
  message("[CMS obligations v2] reconciliation checks whose status moved: ", nrow(moved))
  if (nrow(moved)) print(moved, n = Inf)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--extract-lines" %in% args) obl2_extract_lines()
  if ("--validate" %in% args) { obl2_assert(); message("[CMS obligations v2] assertions pass.") }
  if ("--build" %in% args) obl2_build()
  if ("--report" %in% args) obl2_report()
  if (!length(args)) message("Usage: --extract-lines | --validate | --build | --report")
}
