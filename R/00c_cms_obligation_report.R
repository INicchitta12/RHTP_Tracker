#!/usr/bin/env Rscript
# 00c_cms_obligation_report.R -------------------------------------------------
#
# CMS's RHTP OBLIGATED FUNDS REPORT, PARSED (session 97).
#
# WHAT THE DOCUMENT IS. "RHTP Obligated Funds Report", 105 pages, created
# 2026-10-08, posted on medicaid.gov's RHTP resources page that day
# (Last-Modified 2026-10-08T20:19:39Z). One section per state: the state's
# "Total Budget Period 1 Award", its "Total Funds Put to Work (as of
# 7/31/2026)", and then initiative -> CMS category -> bullet, each bullet a
# dollar figure and a phrase. Its own cover: "state submitted information in
# the Year 1 RHTP Annual Report as of July 31, 2026 ... obligated funds to state
# agencies, contractors and vendors, community partners, hospitals and
# facilities, etc. ... not a full view of state progress".
#
# WHAT ITS NUMBERS ARE (§0.2). "Funds put to work" is OBLIGATION BY ACTIVITY,
# self-reported by the state. A bullet is Tier 2 (a state's committed
# activity line) unless the bullet NAMES A RECIPIENT, when it is Tier 3 --
# and even then it is an obligation to a first-tier entity, not a confirmed
# subaward, and no line here is ever added to an award file or to any of the
# three hospital buckets. BP1 award is Tier 1 and lives in the state table
# only. See CLAUDE.md §10 standing rules (session 97).
#
# PARSE, NEVER TRANSCRIBE. Every figure here is read from the committed PDF by
# the repo's own reader (`R/utils_pdf_text.R`, `rhtp_pdf_lines()`), which
# gives each line its x position. The layout is regular: x~210 headers
# (initiative and category, both "Name ($amount)", initiative names wrap),
# x~285 bullets ("§ $amount for ..."), x~306 the text of a bullet whose "§"
# was painted on its own, x~360 bullet continuations and "No information
# provided" notes, x>1000 the page footer.
#
# DEFECTS IN THE SOURCE ARE LOGGED, NEVER FIXED. `obl_checks()` writes every
# reconciliation (bullets -> category, categories -> initiative, initiatives
# -> state total) to cms_obligations_bp1_checks.csv with EXACT / ROUNDING
# (under $1) / FAIL. Known source defects, read by a human:
#   * Hawaii's bullets repeat other figures (Arizona's $12,660,101,
#     $5,260,552, $717,102; $22,848,000 and $18,496,000 over and over). Every
#     HI bullet carries amount_usable = FALSE; HI's category totals stand.
#   * Header typos are parsed as printed: "($$2,221,629.22)", "Behavioral
#     Health $11,800,000)" (no "("), "Initiative1:", a bullet "$ $721,866.58".
#   * 14 state headers wrap the BP1 award onto a second line; South Dakota's
#     first line ends in a bare "$".
#   * Ligature damage: the font maps "ff" to "W" ("EWiciency", "staW",
#     "oWice"). description_raw keeps it; description_clean repairs it.
#
# Usage:
#   Rscript R/00c_cms_obligation_report.R --validate   # assertions vs archive
#   Rscript R/00c_cms_obligation_report.R --build      # write the CSVs
#   Rscript R/00c_cms_obligation_report.R --report     # human summary

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr); library(tidyr)
})
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_pdf_text.R"))

OBL_DIR        <- file.path("data", "raw", "cms", "obligations", "2026-07-31")
OBL_PDF        <- file.path(OBL_DIR, "RHTP-Obligated-Funds-10082026.pdf")
OBL_SHA256     <- "abee94e70a09eb2c6b1e9298c3123ab158b5ac8db0c39112479abb3532f15cbe"
OBL_PUBLIC_URL <- paste0("https://www.medicaid.gov/resources-for-states/rural-health/",
                         "rhtp-resources/RHTP-Obligated-Funds-10082026.pdf")
OBL_AS_OF      <- as.Date("2026-07-31")
OBL_REPORT     <- as.Date("2026-10-08")
OBL_N_STATES   <- 50L
# The 14 states whose "Total Budget Period 1 Award:" carries its figure on the
# NEXT line. Pinned: a 15th means the layout moved and the parse must be read.
OBL_WRAPPED    <- c("CT", "MA", "MS", "NC", "ND", "NH", "NJ", "NM", "PA", "RI",
                    "SC", "SD", "WA", "WV")
OBL_BARE_DOLLAR <- "SD"
# The figures CMS printed against Hawaii's bullets that belong elsewhere.
OBL_HI_REPEATED <- c(12660101, 5260552, 717102)

OBL_STATE_CSV  <- here::here("data", "reference", "cms_obligations_bp1_state.csv")
OBL_LINES_CSV  <- here::here("data", "reference", "cms_obligations_bp1_lines.csv")
OBL_HEAD_CSV   <- here::here("data", "reference", "cms_obligations_bp1_headers.csv")
OBL_CHECK_CSV  <- here::here("data", "reference", "cms_obligations_bp1_checks.csv")
OBL_RECON_CSV  <- here::here("data", "reference", "cms_obligations_bp1_allotment_reconciliation.csv")

# A bullet amount, a header amount. "$ $721,866.58" and "($$2,221,629.22)"
# are printed by CMS and parsed as printed.
OBL_AMT        <- "\\$\\s*\\$?\\s*([0-9][0-9,]*(?:\\.[0-9]+)?)"
# A bullet's leading figure. Four bullets (LA, RI, VT x2) print no "$" at all.
OBL_BUL_AMT    <- "^(?:\\$\\s*)*([0-9][0-9,]*(?:\\.[0-9]+)?)"
OBL_MERGED_SPLIT <- "(?<=[.;])\\s+(?=\\$\\s*[0-9][0-9,]*(?:\\.[0-9]+)?\\s+(?:in grant funds\\s+)?for\\s)"
OBL_HEAD_TAIL  <- "\\(?\\s*\\$\\s*\\$?\\s*([0-9][0-9,]*(?:\\.[0-9]+)?)\\s*\\)\\s*$"

obl_num <- function(x) as.numeric(gsub(",", "", x))

#' The ligature repair, for description_clean ONLY
#'
#' The report's font maps the "ff" ligature to "W": "staW", "eWorts",
#' "oWice", "EWiciency", "JeWerson". The repair replaces a W that follows a
#' lower-case letter (and precedes a lower-case letter or a word end), or that
#' follows a word-initial capital and precedes a lower-case letter. That
#' leaves every real capital W in the document alone -- CHW, RDW, NEW, IOWA,
#' GROW, WWAMI, and "PoWER", which is followed by a capital. "ﬁ"/"ﬂ" are real
#' Unicode ligatures and are decomposed.
obl_clean_text <- function(x) {
  x %>%
    stringr::str_replace_all("(?<=[a-z])W(?=[a-z]|\\b)", "ff") %>%
    stringr::str_replace_all("(?<=\\b[A-Z])W(?=[a-z])", "ff") %>%
    stringr::str_replace_all("ﬁ", "fi") %>%
    stringr::str_replace_all("ﬂ", "fl") %>%
    stringr::str_squish()
}

obl_assert_archive <- function() {
  path <- here::here(OBL_PDF)
  if (!file.exists(path)) stop("[CMS obligations] archive missing: ", OBL_PDF, call. = FALSE)
  got <- digest::digest(file = path, algo = "sha256")
  if (!identical(got, OBL_SHA256)) {
    stop("[CMS obligations] ", OBL_PDF, " SHA-256 is ", got, ", expected ",
         OBL_SHA256, ". The archive moved; read it before re-pinning.", call. = FALSE)
  }
  invisible(TRUE)
}

#' Lines of the committed PDF, page furniture removed
obl_raw_lines <- function() {
  obl_assert_archive()
  rhtp_pdf_lines(here::here(OBL_PDF)) %>%
    tibble::as_tibble() %>%
    dplyr::filter(page > 1L, x < 1000,
                  !stringr::str_detect(text, "^(State-reported data|Data submitted by State) as of")) %>%
    dplyr::mutate(text = stringr::str_squish(text))
}

obl_state_codes <- function() {
  readr::read_csv(here::here("data", "reference", "cms_fy2026_allotments.csv"),
                  show_col_types = FALSE, progress = FALSE) %>%
    dplyr::transmute(state, state_name)
}

#' Walk the lines into states, headers, bullets and notes
#'
#' @return A list of tibbles: `states`, `headers`, `bullets`, `notes`.
obl_parse <- function(lines = obl_raw_lines()) {
  codes <- obl_state_codes()
  n <- nrow(lines)
  states <- list(); headers <- list(); bullets <- list(); notes <- list()
  st <- NA_character_; ini <- NA_character_; ini_amt <- NA_real_
  cat_name <- NA_character_; cat_amt <- NA_real_
  ini_seq <- 0L; cat_seq <- 0L; bul_seq <- 0L
  buf <- character(0); buf_page <- NA_integer_
  i <- 1L
  while (i <= n) {
    tx <- lines$text[i]; xx <- lines$x[i]; pg <- lines$page[i]

    m <- stringr::str_match(tx, "^(.+?) Total Budget Period 1 Award:\\s*(.*)$")
    if (!is.na(m[1, 1])) {
      nm <- stringr::str_replace_all(m[1, 2], "[’']", "")
      code <- codes$state[stringr::str_replace_all(codes$state_name, "'", "") == nm]
      if (length(code) != 1L) stop("[CMS obligations] unknown state header: ", tx, call. = FALSE)
      tail <- m[1, 3]; wrapped <- FALSE; bare <- identical(stringr::str_trim(tail), "$")
      if (!stringr::str_detect(tail, "[0-9]")) {
        i <- i + 1L; tail <- lines$text[i]; wrapped <- TRUE
      }
      award <- obl_num(stringr::str_match(tail, OBL_AMT)[1, 2])
      i <- i + 1L
      fp <- stringr::str_match(lines$text[i],
                               paste0("^Total Funds Put to Work: ", OBL_AMT,
                                      " \\(as of ([0-9/]+)\\)$"))
      if (is.na(fp[1, 1])) stop("[CMS obligations] no funds-put-to-work line for ", code, call. = FALSE)
      st <- code; ini <- NA_character_; ini_amt <- NA_real_
      cat_name <- NA_character_; cat_amt <- NA_real_
      ini_seq <- 0L; cat_seq <- 0L; bul_seq <- 0L
      states[[length(states) + 1L]] <- tibble::tibble(
        state = code, state_name_printed = m[1, 2], page = pg,
        bp1_award = award, funds_put_to_work = obl_num(fp[1, 2]),
        as_of_printed = fp[1, 3], header_wrapped = wrapped, header_bare_dollar = bare)
      i <- i + 1L
      next
    }

    if (stringr::str_detect(tx, "^No information provided")) {
      notes[[length(notes) + 1L]] <- tibble::tibble(state = st, page = pg, note = tx)
      i <- i + 1L
      next
    }

    # MISSISSIPPI prints its $0 Initiative 3 and then a bare "$0" on its own
    # line. A bare amount with no header open is logged and skipped.
    if (!length(buf) && xx < 295 && stringr::str_detect(tx, "^\\$[0-9][0-9,.]*$")) {
      notes[[length(notes) + 1L]] <- tibble::tibble(state = st, page = pg,
                                                    note = paste0("STRAY_AMOUNT_LINE: ", tx))
      i <- i + 1L
      next
    }

    # MISSOURI prints one bullet at the continuation indent with no marker.
    # A line indented past the header column that opens with an amount, and
    # that no bullet above has absorbed, is that bullet.
    unmarked <- !length(buf) && xx > 295 && stringr::str_detect(tx, OBL_BUL_AMT)
    if (stringr::str_detect(tx, "^§") || unmarked) {
      if (length(buf)) stop("[CMS obligations] a bullet opened inside an unterminated header in ",
                            st, ": ", paste(buf, collapse = " "), call. = FALSE)
      body <- stringr::str_trim(stringr::str_remove(tx, "^§"))
      j <- i + 1L
      while (j <= n && lines$x[j] > 295 && lines$x[j] < 1000 &&
             !stringr::str_detect(lines$text[j], "^(§|No information provided)")) {
        body <- stringr::str_trim(paste(body, lines$text[j]))
        j <- j + 1L
      }
      # IOWA prints two items in one bullet: "... pulmonary diagnostics.
      # $2,375,828.92 for other diagnostic and imaging equipment ...". A
      # sentence that opens with its own "$X for" is its own bullet.
      pieces <- stringr::str_split(body, OBL_MERGED_SPLIT)[[1]]
      for (pc in pieces) {
        bul_seq <- bul_seq + 1L
        amt <- stringr::str_match(pc, OBL_BUL_AMT)[1, 2]
        bullets[[length(bullets) + 1L]] <- tibble::tibble(
          state = st, page = pg, initiative_seq = ini_seq, initiative = ini,
          initiative_total = ini_amt,
          category_seq = if (is.na(cat_name)) NA_integer_ else cat_seq, category = cat_name,
          category_total = cat_amt, bullet_seq = bul_seq,
          amount = obl_num(amt), description_raw = pc, marker_missing = unmarked,
          split_from_merged = length(pieces) > 1L)
      }
      i <- j
      next
    }

    if (xx > 295) stop("[CMS obligations] unexpected indented line in ", st, ": ", tx, call. = FALSE)

    # A header: accumulate x~210 lines until one ends in an amount.
    buf <- c(buf, tx); if (is.na(buf_page)) buf_page <- pg
    joined <- paste(buf, collapse = " ")
    hm <- stringr::str_match(joined, OBL_HEAD_TAIL)
    if (!is.na(hm[1, 1])) {
      name <- stringr::str_trim(stringr::str_remove(joined, OBL_HEAD_TAIL))
      amt <- obl_num(hm[1, 2])
      is_ini <- stringr::str_detect(name, "^(Initiative\\s*[0-9]+|Program Operations)")
      if (is_ini) {
        ini_seq <- ini_seq + 1L; ini <- name; ini_amt <- amt
        cat_name <- NA_character_; cat_amt <- NA_real_
      } else {
        cat_seq <- cat_seq + 1L; cat_name <- name; cat_amt <- amt
      }
      headers[[length(headers) + 1L]] <- tibble::tibble(
        state = st, page = buf_page, level = if (is_ini) "INITIATIVE" else "CATEGORY",
        initiative_seq = ini_seq, initiative = ini, category_seq = if (is_ini) NA_integer_ else cat_seq,
        name = name, amount = amt, printed = joined, lines_wrapped = length(buf))
      buf <- character(0); buf_page <- NA_integer_
    } else if (length(buf) > 4L) {
      stop("[CMS obligations] unterminated header in ", st, ": ", joined, call. = FALSE)
    }
    i <- i + 1L
  }
  if (length(buf)) stop("[CMS obligations] trailing unterminated header: ",
                        paste(buf, collapse = " "), call. = FALSE)
  list(states = dplyr::bind_rows(states), headers = dplyr::bind_rows(headers),
       bullets = dplyr::bind_rows(bullets), notes = dplyr::bind_rows(notes))
}

# -- Named organisations ----------------------------------------------------
#
# A bullet names a recipient when its phrase reads "$X for <Organisation> to
# ..." (Nebraska, Pennsylvania, Rhode Island, Ohio and others). The rule is a
# SHAPE plus a TEST, never a name list:
#   1. Take the phrase after "$X (in grant funds) for (the)", dropping a
#      leading "Payment to" / "Funds paid to" / "Funds to".
#   2. Cut it at the first lower-case word that is not a connector (of, the,
#      and, for, at, in, on, &): organisation names are title case,
#      activities are not. "Lehigh Valley Hospital's Pocono and Schuylkill
#      campuses" stops before "campuses"; "RIDOH direct costs" before
#      "direct".
#   3. Split on commas and "and", except inside PROTECTED phrases that carry
#      their own "and" or comma ("Health and Human Services", "Behavioral
#      Healthcare, Developmental Disabilities & Hospitals", ", Inc").
#   4. Keep a part that carries an organisation token, is an acronym (RIDOH,
#      HARI, CTC-RI) or joins two capitalised names with "&" (Alvarez &
#      Marsal) -- and that does NOT read as a programme ("... Program",
#      "Pilot", "Plan", "Grant", "Initiative", "Assessment") unless it also
#      carries a strong organisation token (Department, University,
#      Hospital, Association, LLC, Inc, Tribe).
# A human read every result; `OBL_NAME_VERDICTS` records where the read
# disagreed with the rule, line by line, with the reason. That table is the
# only hand input, and it never touches an amount.
OBL_ORG_TOKENS <- paste0(
  "\\b(Hospital|Hospitals|Health|Healthcare|HealthCare|Medical|Clinic|Center|Centre|",
  "LLC|LLP|PLLC|Inc|Incorporated|Corp|Corporation|Company|",
  "University|College|Department|Dept|District|Association|Foundation|",
  "Authority|County|City|Township|Tribe|Nation|Pharmacies|Pharmacy|Partners|",
  "Ministries|Services|System|Systems|Group|Institute|Consortium|Collaborative|",
  "Alliance|Society|Agency|Board|Cooperative|League|Commission|Office|Coalition)\\b")
OBL_STRONG_ORG <- paste0(
  "\\b(Department|Dept|University|Hospital|Association|LLC|LLP|Inc|Corp|Tribe|",
  "Authority|Commission|Board of|League)\\b")
OBL_PROGRAMME_WORDS <- paste0(
  "\\b(Program|Programs|Programming|Pilot|Plan|Grant|Grants|Initiative|",
  "Assessment|Expansion|Development|Exchange|Model|Modules|Courses|Fund|",
  "Network|Test|Hub Lead|Data Center|Waiver)\\b")
OBL_CONNECTORS <- c("of", "the", "and", "for", "at", "in", "on", "&", "de", "y")
OBL_PROTECT <- c(
  "Health and Human Services", "Children and Youth", "Labor and Training",
  "Behavioral Healthcare, Developmental Disabilities & Hospitals",
  "Center for Behavioral Health and Discovery House",
  "Cities and Towns", "Nutrition and Fitness")
# Acronyms the documents use for THINGS, not organisations.
OBL_GENERIC_ACRONYMS <- c("AHEAD", "AI", "API", "CAH", "CHW", "CHWs", "EHR", "EMR",
                          "EMS", "HIE", "HIT", "IDD", "IT", "RHT", "RHTP", "SUD", "TA")
# Single-word or lower-token vendor names Rhode Island's lines name as
# contractors ("Guidesoft contracted staff", "Guidesoft and Uncommon
# Solutions to provide contracted support"). No token rule reaches them.
OBL_KNOWN_RECIPIENTS <- c("Guidesoft", "Uncommon Solutions")

obl_named_orgs_one <- function(d) {
  body <- stringr::str_match(d, paste0(OBL_BUL_AMT, "\\s+(?:in grant funds\\s+)?for\\s+(.*)$"))[1, 3]
  if (is.na(body)) return(list(named = NA_character_, other = 0L))
  body <- stringr::str_remove(body, "^(?:(?:Payment|Payments|Funds paid|Funds distributed|Funds)\\s+to\\s+)")
  body <- stringr::str_remove(body, "^the\\s+")
  words <- stringr::str_split(body, "\\s+")[[1]]
  keep <- character(0)
  for (w in words) {
    bare <- stringr::str_remove_all(w, "^[(\u201c\"]+|[),.;:\u201d\"]+$")
    if (w %in% c("-", "\u2013")) { keep <- c(keep, w); next }
    lower <- stringr::str_detect(bare, "^[a-z]") && !(bare %in% OBL_CONNECTORS)
    if (lower) break
    keep <- c(keep, w)
    if (stringr::str_detect(w, "[.:;]$") && !stringr::str_detect(w, "^(Inc|Dept|St|Co|Corp)\\.$")) break
  }
  seg <- stringr::str_trim(paste(keep, collapse = " "))
  seg <- stringr::str_remove(seg, "[.:;,]+$")
  seg <- stringr::str_remove(seg, "\\s+(?:and|for|the|of|to|in|at|on|&)$")
  seg <- stringr::str_remove(seg, "\\s*[-\u2013]\\s*[Pp]ayments?$")
  seg <- stringr::str_remove(seg, "\\s*[-\u2013]$")
  other <- 0L
  om <- stringr::str_match(body, "\\b([0-9]+)\\s+other\\s+organi[sz]ations?")
  if (!is.na(om[1, 1])) {
    other <- as.integer(om[1, 2])
    seg <- stringr::str_trim(stringr::str_remove(seg, ",?\\s*(?:and\\s+)?[0-9]+$"))
  }
  if (!nzchar(seg) || !stringr::str_detect(seg, "^[A-Z]")) return(list(named = NA_character_, other = other))
  for (k in seq_along(OBL_PROTECT)) seg <- stringr::str_replace_all(seg, stringr::fixed(OBL_PROTECT[k]), paste0("\u00a4", k, "\u00a4"))
  seg <- stringr::str_replace_all(seg, ",\\s*(Inc|LLC|INC)\\b", " \\1")
  parts <- stringr::str_split(seg, ",\\s*(?:and\\s+)?|\\s+and\\s+")[[1]] %>% stringr::str_trim()
  for (k in seq_along(OBL_PROTECT)) parts <- stringr::str_replace_all(parts, paste0("\u00a4", k, "\u00a4"), OBL_PROTECT[k])
  parts <- stringr::str_remove(parts, "^(?:the|The)\\s+(?=[A-Z])")
  ok <- nzchar(parts) & stringr::str_detect(parts, "^[A-Z]") &
    !(parts %in% OBL_GENERIC_ACRONYMS) &
    (stringr::str_detect(parts, OBL_ORG_TOKENS) |
       stringr::str_detect(parts, "^[A-Z][A-Za-z]*[A-Z](-[A-Z]+)?$") |
       stringr::str_detect(parts, "^[A-Z][a-z]+( [A-Z][a-z]+)* & [A-Z][a-z]+$") |
       parts %in% OBL_KNOWN_RECIPIENTS) &
    (!stringr::str_detect(parts, OBL_PROGRAMME_WORDS) | stringr::str_detect(parts, OBL_STRONG_ORG))
  parts <- unique(parts[ok])
  list(named = if (length(parts)) paste(parts, collapse = "; ") else NA_character_, other = other)
}

#' Extract named organisations from cleaned bullet descriptions
#'
#' @return A list with `named_orgs` (character, "; "-joined, NA when none)
#'   and `n_unnamed_others` (the "and N other organizations" count).
obl_named_orgs <- function(desc) {
  res <- lapply(desc, obl_named_orgs_one)
  list(named_orgs = vapply(res, `[[`, character(1), "named"),
       n_unnamed_others = vapply(res, `[[`, integer(1), "other"))
}

# -- The human read: where it disagreed with the rule ------------------------
# Every bullet the rule named, and every bullet whose phrase after "for" opens
# with a capital, was read (session 97). These rows are where the read
# disagreed. `named_orgs = NA` means the bullet names a programme or an
# activity, not a recipient. Amounts are never touched here.
OBL_NAME_VERDICTS <- tibble::tribble(
  ~line_id,        ~named_orgs,                                   ~reason,
  "AK-002-02-02",  NA,                                            "AHEAD is a CMS model; a feasibility assessment",
  "GA-001-01-01",  NA,                                            "AHEAD is a CMS model",
  "CA-003-07-13",  NA,                                            "a centre the line creates, not a named recipient",
  "CO-003-05-08",  NA,                                            "CHW/clinician training: an activity",
  "CT-003-07-10",  NA,                                            "health information exchange: an activity",
  "GA-002-11-15",  NA,                                            "CME modules: an activity",
  "GA-004-20-31",  NA,                                            "AHEC training programmes: a class of entity, none named",
  "KS-002-08-19",  NA,                                            "AHAP is a programme (session 96: run by AHAP, LLC, not named here)",
  "KS-002-10-21",  NA,                                            "AHAP is a programme",
  "KS-003-14-32",  NA,                                            "K-12 courses: an activity",
  "KY-004-09-14",  NA,                                            "Rooted in Health is a programme",
  "KY-004-10-15",  NA,                                            "Rooted in Health is a programme",
  "KY-006-16-24",  NA,                                            "AHEC support: a class of entity, none named",
  "ME-001-01-04",  NA,                                            "CHW: an activity",
  "ME-001-02-07",  NA,                                            "Population Health initiative: a programme",
  "ME-003-10-24",  "Medical Care Development (MCD)",              "named 'to serve as Subrecipient'; 'Development' read as a programme word by the rule",
  "MN-004-06-08",  NA,                                            "EMS treatment-in-place: a programme",
  "ND-001-01-01",  NA,                                            "CAH workforce retention: a class of hospital, none named",
  "ND-002-03-10",  "North Dakota State University (NDSU)",        "NDSU Extension runs the programme",
  "ND-002-04-13",  "North Dakota State University (NDSU)",        "NDSU Extension runs the programme",
  "OK-004-15-35",  "Oklahoma Health Care Authority (OHCA)",       "the state Medicaid agency; PACE is its programme",
  "PA-001-02-02",  NA,                                            "RRS1 is a programme strand; no recipient named",
  "PA-004-14-24",  "The Guidance Center",                         "full name as printed",
  "PA-005-16-31",  "Lehigh Valley Hospital - Pocono; Lehigh Valley Hospital - Schuylkill", "printed \"Lehigh Valley Hospital's Pocono and Schuylkill campuses\"",
  "PA-005-17-36",  "Center for Behavioral Health; Discovery House Comprehensive Treatment Centers", "two operators; sites Farrell, Cranberry Township, New Castle, Duncansville",
  "PA-005-18-39",  "Comprehensive Treatment Centers (Farrell, Cranberry Township, New Castle, Duncansville)", "four sites printed as one recipient group",
  "PA-004-14-21",  "Comprehensive Treatment Centers (Lewistown, Clearfield, Watsontown)", "three sites printed as one recipient group",
  "PA-005-19-58",  "Nulton Diagnostic and Treatment Center",      "full name as printed",
  "PA-005-18-47",  "St. Luke's Hospital Carbon Campus",           "the rule lost the possessive",
  "PA-005-20-59",  "The Guthrie Clinic",                          "the Pulse Center Pilot is the Guthrie Clinic's",
  "PA-005-21-60",  "The Guthrie Clinic",                          "the Pulse Center Pilot is the Guthrie Clinic's",
  "PA-003-08-13",  "Lutheran Home at Kane",                       "no organisation token",
  "PA-004-14-20",  "LIFE Lawrence, Armstrong, and Butler Counties", "a PACE (LIFE) programme operator, printed as one",
  "PA-005-16-34",  "Gaughn's Drug Store",                         "no organisation token",
  "PA-005-18-50",  "Gaughn's Drug Store",                         "no organisation token",
  "PA-005-16-35",  "Columbia, Montour, Snyder, and Union (CMSU) Counties", "a four-county joinder, printed as one",
  "PA-005-18-40",  "Cornerstone Care",                            "an FQHC's sites, printed possessive",
  "RI-001-02-04",  "Rhode Island League of Cities and Towns (RILCT)", "full name as printed",
  "RI-009-45-99",  "Narragansett Indian Tribe (NIT)",             "printed 'Tribe'; the initiative's own recipient",
  "SD-005-06-06",  NA,                                            "an unnamed 'Maternal Health Hub grant recipient'",
  "TX-002-02-02",  "Department of State Health Services (DSHS)",  "programme staff of the agency",
  "VT-001-02-03",  NA,                                            "Mental Health and SUD Urgent Care: a programme",
  "VT-001-02-04",  NA,                                            "Mental Health and SUD Urgent Care: a programme",
  "VT-001-03-05",  NA,                                            "nursing-home dialysis and ventilators: an activity",
  "WI-003-10-34",  "Division of Medicaid Services (DMS)",         "an internal indirect-cost line",
  "NE-002-10-20",  "Facilitate Co",                               "no organisation token the rule recognises",
  "NE-003-15-51",  "United Way of Western Nebraska",              "no organisation token",
  "NE-003-15-53",  "CDW Government",                              "a vendor; no organisation token",
  "NE-005-29-130", "Avel eCare",                                  "printed 'the Avel ECare'",
  "NE-008-41-154", "Learfield Communications",                    "printed 'Payment to Learfield Communications'",
  "NE-008-41-156", "Covendis",                                    "printed 'Funds paid to Covendis'",
  "NE-002-12-30",  "Carl T Curtis H Ed Ctr; East Central District Health Department", "abbreviated name, no token the rule reads",
  "NE-002-13-36",  "Carl T Curtis H Ed Ctr; Douglas County Health Department", "abbreviated name, no token the rule reads",
  "NE-004-24-109", "Caringwire; Morrill County Community Hospital; Niobrara Valley Hospital Corp", "Caringwire has no token",
  "NE-004-27-123", "CHI Health St Marys; Vetter Senior Living",  "Vetter has no token; the line is MULTI-recipient",
  "NE-006-38-146", "Lincoln Il Al LLC; Edgewood Vista, Grand Island", "Edgewood Vista has no token",
  "KS-003-14-34",  "Kansas Hospital Association (KHA)",           "printed 'central Kansas Hospital Association (KHA) support'",
  "PA-005-16-28",  "St. Luke's Carbon; St. Luke's Monroe; Geisinger St. Luke's; Washington County Hospital (WCH)", "four hospitals printed after 'across'; MULTI-recipient",
  "PA-005-18-37",  "Bucktail Medical Center",                     "OTHERS UNSTATED: 'across rural hospitals, including ... at Bucktail Medical Center'",
  "PA-005-18-44",  "Robert Packer Hospital; Wyoming County Healthcare Center (WCHC)", "two hospitals printed after 'at'; MULTI-recipient",
  "TN-005-09-09",  "TennCare",                                    "the state Medicaid agency",
  "TN-007-15-16",  "TennCare",                                    "the state Medicaid agency",
  "TN-009-18-19",  "Carahsoft",                                   "a vendor",
  "VA-005-09-16",  "Virginia DMAS",                               "the state Medicaid agency"
)

obl_apply_name_verdicts <- function(lines) {
  v <- OBL_NAME_VERDICTS
  miss <- setdiff(v$line_id, lines$line_id)
  if (length(miss)) stop("[CMS obligations] name verdicts for lines that do not exist: ",
                         paste(miss, collapse = ", "), call. = FALSE)
  if (anyDuplicated(v$line_id)) stop("[CMS obligations] duplicate name verdict", call. = FALSE)
  idx <- match(lines$line_id, v$line_id)
  hit <- !is.na(idx)
  lines$named_orgs_rule <- lines$named_orgs
  lines$named_orgs[hit] <- v$named_orgs[idx[hit]]
  # A verdict that says OTHERS UNSTATED makes the line multi-recipient with an
  # unknown count of unnamed others; -1 records "some, count not printed".
  unst <- hit & stringr::str_detect(dplyr::coalesce(v$reason[idx], ""), "^OTHERS UNSTATED")
  lines$n_unnamed_others[unst] <- -1L
  lines$name_basis <- dplyr::case_when(hit ~ paste0("HAND_READ: ", v$reason[idx]),
                                       !is.na(lines$named_orgs) ~ "RULE",
                                       TRUE ~ NA_character_)
  lines
}

#' The bullet table, with clean text, named organisations and tier
obl_lines_table <- function(p = obl_parse()) {
  b <- p$bullets %>%
    dplyr::mutate(description_clean = obl_clean_text(description_raw))
  no <- obl_named_orgs(b$description_clean)
  b <- b %>%
    dplyr::mutate(named_orgs = no$named_orgs, n_unnamed_others = no$n_unnamed_others) %>%
    dplyr::group_by(state) %>%
    dplyr::mutate(line_id = sprintf("%s-%03d-%02d-%02d", state, initiative_seq,
                                    dplyr::coalesce(category_seq, 0L), bullet_seq)) %>%
    dplyr::ungroup() %>%
    obl_apply_name_verdicts()
  b %>%
    dplyr::mutate(
      # A Hawaii bullet's figure is not usable: CMS printed other states' and
      # other lines' figures against it. Its category total stands.
      amount_usable = state != "HI",
      flag = dplyr::case_when(
        state == "HI" ~ "HI_BULLET_AMOUNTS_REPEATED_FROM_OTHER_LINES",
        is.na(amount) ~ "BULLET_HAS_NO_AMOUNT",
        marker_missing ~ "BULLET_PRINTED_WITHOUT_MARKER",
        split_from_merged ~ "BULLET_SPLIT_FROM_TWO_ITEMS_PRINTED_AS_ONE",
        !stringr::str_detect(description_raw, "^\\$") ~ "BULLET_AMOUNT_PRINTED_WITHOUT_DOLLAR_SIGN",
        TRUE ~ NA_character_),
      tier = dplyr::if_else(!is.na(named_orgs), "SUBAWARD", "SOLICITATION"),
      as_of = OBL_AS_OF, report_date = OBL_REPORT, budget_period = 1L
    ) %>%
    dplyr::select(line_id, state, page, initiative, initiative_total, category,
                  category_total, amount, amount_usable, description_raw,
                  description_clean, named_orgs, n_unnamed_others, name_basis, tier, flag,
                  as_of, report_date, budget_period)
}

obl_state_table <- function(p = obl_parse()) {
  p$states %>%
    dplyr::transmute(state, bp1_award, funds_put_to_work,
                     share_put_to_work = round(funds_put_to_work / bp1_award, 4),
                     as_of = OBL_AS_OF, report_date = OBL_REPORT, budget_period = 1L,
                     header_wrapped, header_bare_dollar,
                     tier_bp1_award = "STATE_ALLOTMENT",
                     tier_funds_put_to_work = "OBLIGATION_BY_ACTIVITY_NOT_AN_AWARD_TOTAL") %>%
    dplyr::arrange(state)
}

#' Every reconciliation the document implies, logged, never fixed
obl_checks <- function(p = obl_parse()) {
  status <- function(d) dplyr::case_when(is.na(d) ~ "NOT_COMPUTABLE",
                                         abs(d) < 0.005 ~ "EXACT",
                                         abs(d) < 1 ~ "ROUNDING",
                                         TRUE ~ "FAIL")
  b <- p$bullets; h <- p$headers
  cats <- h %>% dplyr::filter(level == "CATEGORY")
  inis <- h %>% dplyr::filter(level == "INITIATIVE")

  c1 <- cats %>%
    dplyr::left_join(b %>% dplyr::group_by(state, initiative_seq, category_seq) %>%
                       dplyr::summarise(computed = sum(amount), n_bullets = dplyr::n(), .groups = "drop"),
                     by = c("state", "initiative_seq", "category_seq")) %>%
    dplyr::transmute(state, check = "BULLETS_TO_CATEGORY", initiative, name,
                     stated = amount, computed = dplyr::coalesce(computed, 0), n_parts = dplyr::coalesce(n_bullets, 0L))
  # Illinois and Ohio print bullets directly under an initiative with no CMS
  # category header. Those initiatives reconcile bullets -> initiative.
  ncat <- cats %>% dplyr::count(state, initiative_seq, name = "n_cat")
  nocat_sum <- b %>% dplyr::filter(is.na(category)) %>%
    dplyr::group_by(state, initiative_seq) %>%
    dplyr::summarise(computed_b = sum(amount), n_b = dplyr::n(), .groups = "drop")
  c2 <- inis %>%
    dplyr::left_join(cats %>% dplyr::group_by(state, initiative_seq) %>%
                       dplyr::summarise(computed = sum(amount), .groups = "drop"),
                     by = c("state", "initiative_seq")) %>%
    dplyr::left_join(ncat, by = c("state", "initiative_seq")) %>%
    dplyr::left_join(nocat_sum, by = c("state", "initiative_seq")) %>%
    dplyr::transmute(state,
                     check = dplyr::if_else(is.na(n_cat) & !is.na(n_b),
                                            "BULLETS_TO_INITIATIVE_NO_CATEGORY",
                                            "CATEGORIES_TO_INITIATIVE"),
                     initiative = name, name, stated = amount,
                     computed = dplyr::coalesce(computed, 0) + dplyr::coalesce(computed_b, 0),
                     n_parts = dplyr::coalesce(n_cat, 0L) + dplyr::coalesce(n_b, 0L))
  c3 <- p$states %>%
    dplyr::left_join(inis %>% dplyr::group_by(state) %>%
                       dplyr::summarise(computed = sum(amount), n_ini = dplyr::n(), .groups = "drop"),
                     by = "state") %>%
    dplyr::transmute(state, check = "INITIATIVES_TO_STATE_TOTAL", initiative = NA_character_,
                     name = "Total Funds Put to Work", stated = funds_put_to_work,
                     computed = dplyr::coalesce(computed, 0), n_parts = dplyr::coalesce(n_ini, 0L))
  out <- dplyr::bind_rows(c1, c2, c3) %>%
    dplyr::mutate(diff = round(computed - stated, 2), status = status(diff),
                  note = dplyr::case_when(
                    state == "HI" & check == "BULLETS_TO_CATEGORY" & status == "FAIL" ~
                      "HI bullets repeat other lines' figures; the category total stands",
                    TRUE ~ NA_character_))
  out %>% dplyr::arrange(state, check)
}

#' Task 2: BP1 award against the FY2026 allotment table, to the cent
obl_allotment_reconciliation <- function(st = obl_state_table()) {
  readr::read_csv(here::here("data", "reference", "cms_fy2026_allotments.csv"),
                  show_col_types = FALSE, progress = FALSE) %>%
    dplyr::select(state, state_name, fy2026_allotment) %>%
    dplyr::left_join(st %>% dplyr::select(state, bp1_award), by = "state") %>%
    dplyr::mutate(diff_bp1_minus_fy2026 = round(bp1_award - fy2026_allotment, 2),
                  # Half-up, as the published allotments round: R's round()
                  # takes Florida's $209,938,194.50 to the EVEN dollar, 194.
                  rounds_to_fy2026 = floor(bp1_award + 0.5) == fy2026_allotment,
                  note = dplyr::case_when(
                    rounds_to_fy2026 ~ "BP1 award rounds to the published FY2026 allotment",
                    TRUE ~ "BP1 award differs from the published FY2026 allotment beyond rounding")) %>%
    dplyr::arrange(dplyr::desc(abs(diff_bp1_minus_fy2026)))
}

# The CMS category names the document uses. A header outside this set means
# the walk swallowed a bullet or a stray line into a header.
OBL_CATEGORIES <- paste0(
  "^(Appropriate Care Availability|Behavioral Health|Capital Expenditures and ",
  "Infrastructure|Consumer Tech Solutions|Fostering Collaboration|Innovative Care|",
  "IT Advances|Prevention and Chronic Disease|Prevention of Chronic Disease|",
  "Provider Payments|Training and Technical Assistance|Workforce|",
  "Program Administrati(on|ve) Expenses?( for .+)?)$")

obl_assert <- function(p = obl_parse()) {
  bad <- p$headers %>% dplyr::filter(level == "CATEGORY", !stringr::str_detect(name, OBL_CATEGORIES))
  if (nrow(bad)) stop("[CMS obligations] category header(s) outside the CMS set: ",
                      paste(bad$state, bad$name, collapse = " | "), call. = FALSE)
  st <- p$states
  if (nrow(st) != OBL_N_STATES || dplyr::n_distinct(st$state) != OBL_N_STATES) {
    stop("[CMS obligations] expected ", OBL_N_STATES, " states, parsed ", nrow(st), call. = FALSE)
  }
  wrapped <- sort(st$state[st$header_wrapped])
  if (!identical(wrapped, sort(OBL_WRAPPED))) {
    stop("[CMS obligations] wrapped BP1 headers are ", paste(wrapped, collapse = " "),
         "; expected ", paste(sort(OBL_WRAPPED), collapse = " "), call. = FALSE)
  }
  if (!identical(st$state[st$header_bare_dollar], OBL_BARE_DOLLAR)) {
    stop("[CMS obligations] the bare-\"$\" header is no longer SD alone", call. = FALSE)
  }
  if (any(st$as_of_printed != "7/31/2026")) stop("[CMS obligations] an as-of date is not 7/31/2026", call. = FALSE)
  if (any(is.na(st$bp1_award)) || any(is.na(st$funds_put_to_work))) {
    stop("[CMS obligations] a state total failed to parse", call. = FALSE)
  }
  if (any(is.na(p$bullets$amount))) {
    stop("[CMS obligations] ", sum(is.na(p$bullets$amount)), " bullet(s) without an amount", call. = FALSE)
  }
  hi <- p$bullets %>% dplyr::filter(state == "HI")
  if (!all(OBL_HI_REPEATED %in% hi$amount)) {
    stop("[CMS obligations] Hawaii no longer prints the repeated Arizona figures; re-read it", call. = FALSE)
  }
  if (any(p$states$funds_put_to_work > p$states$bp1_award + 0.005)) {
    stop("[CMS obligations] a state's funds put to work exceed its BP1 award", call. = FALSE)
  }
  invisible(TRUE)
}

obl_build <- function() {
  p <- obl_parse()
  obl_assert(p)
  st <- obl_state_table(p)
  readr::write_csv(st, OBL_STATE_CSV, na = "")
  readr::write_csv(obl_lines_table(p), OBL_LINES_CSV, na = "")
  readr::write_csv(p$headers %>% dplyr::select(-printed), OBL_HEAD_CSV, na = "")
  readr::write_csv(obl_checks(p), OBL_CHECK_CSV, na = "")
  readr::write_csv(obl_allotment_reconciliation(st), OBL_RECON_CSV, na = "")
  message("[CMS obligations] wrote ", basename(OBL_STATE_CSV), ", ", basename(OBL_LINES_CSV),
          ", ", basename(OBL_HEAD_CSV), ", ", basename(OBL_CHECK_CSV), ", ", basename(OBL_RECON_CSV))
  invisible(p)
}

obl_report <- function() {
  st <- readr::read_csv(OBL_STATE_CSV, show_col_types = FALSE)
  ck <- readr::read_csv(OBL_CHECK_CSV, show_col_types = FALSE)
  ln <- readr::read_csv(OBL_LINES_CSV, show_col_types = FALSE)
  message(sprintf("States %d | BP1 awards $%s | put to work $%s | bullets %d (%d name a recipient)",
                  nrow(st), format(sum(st$bp1_award), big.mark = ",", nsmall = 2, scientific = FALSE),
                  format(sum(st$funds_put_to_work), big.mark = ",", nsmall = 2, scientific = FALSE),
                  nrow(ln), sum(ln$tier == "SUBAWARD")))
  print(ck %>% dplyr::count(check, status), n = Inf)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) { obl_assert(); message("[CMS obligations] assertions pass.") }
  if ("--build" %in% args) obl_build()
  if ("--report" %in% args) obl_report()
  if (!length(args)) message("Usage: --validate | --build | --report")
}
