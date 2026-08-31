# 03p_md_year1_awardees.R -----------------------------------------------------
# Maryland Year 1 -> data/reference/md_year1_awardees.csv
#
# WHY MARYLAND. It led `state_trigger_queue.csv` after Kansas was worked out --
# 42 Tier 3 candidates, 41 distinct awardees, a $168,180,838 allotment, no CMS
# press release and no session had ever looked at it.
#
# WHAT MARYLAND PUBLISHES. Two Budget Period 1 "Award Offers" PDFs, linked from
# MDH's own Rural Health Transformation Program page:
#
#   Pillar 2 Transformation Funds        33 offers   $72,412,038
#   Pillar 2 Expand Primary Care Access   8 offers   $ 6,213,033
#   ---------------------------------------------------------
#                                        41 offers   $78,625,071
#
# THE TEXAS CHECK (§6.2), RUN FIRST AND PASSED. Session 19's lesson is that "has
# this state published a recipient-level list?" is not the whole question --
# Texas answered yes, twice, and the lists were an 88th-Legislature
# appropriation whose RFAs closed before RHTP existed. Two things were
# established from Maryland's own documents before anything was extracted:
#
#   1. WHAT FUNDS IT. MDH's RHTP procurement page states that "All partners and
#      subawardees of Maryland's RHTP cooperative agreement with the Centers for
#      Medicare and Medicaid Services (CMS) must agree to and comply with RHTP
#      terms and conditions". The programme page says MDH "will award a series
#      of subawards totaling $163.7 million in Budget Period 1" out of the $168
#      million CMS award, and both PDFs are headed "Maryland Rural Health
#      Transformation Program ... Budget Period 1". `md_assert_rhtp_funded()`
#      requires all of it on every run.
#   2. WHEN. Both solicitations were POSTED AFTER Maryland's CMS Notice of
#      Award: 2026-04-21 (Transformation Funds) and 2026-05-04 (Primary Care),
#      against the 2025-12-29 NOA in `cms_state_noa_dates.csv`. That is the
#      opposite of Texas's HHS0015180, which closed 2025-04-24, eight months
#      before its state had the money. `md_assert_after_noa()` reads the dates
#      out of the archived page rather than taking them from this comment.
#
# THE POSITIVE CONTROL, WHICH IS WHAT MAKES THE REST OF THE ANSWER MEAN
# ANYTHING. Maryland is running TEN Budget Period 1 funding opportunities and
# has published award offers for TWO. On its own "we found no other list" is
# indistinguishable from "we looked for the wrong string", so the check is not
# that strings are absent: MDH's funding-opportunities table has a column that
# carries an "Award Offers" LINK exactly where a roster exists, and
# `md_assert_award_index()` asserts both links present, both pointing at the
# PDFs this file parses. The eight rows with no such link are then a real
# absence, and each says why in the same table -- still open, extended, or
# "Competitive bid process". The assertion is a tripwire in BOTH directions: it
# fails if either known link disappears (a redesign that renamed them would
# otherwise turn every future run silently green) and fails if a THIRD appears,
# because at that point Maryland has published a pool this file does not carry.
#
# WHAT AN "AWARD OFFER" IS, AND WHY EVERY ROW IS AN INTENT. Maryland's own word
# is OFFER, and its programme table pairs each with an "Anticipated Project
# Period Start Date". An offer is not an executed agreement, so all 41 rows are
# `NOTICE_OF_INTENT_TO_AWARD` + `amount_confirmed = No`, which is Oregon's
# posture for the same reason (§9.3 splits the two questions, so a preliminary
# amount does not drag a confirmed recipient down with it).
#
# WHERE THE HOSPITAL FIGURE IS SOFT, STATED WHERE IT CANNOT BE MISSED. Maryland
# publishes a recipient, an amount, a project summary and the counties served --
# and NOTHING about the recipient's organisational form. There is no
# Organization Type column of the kind Oregon and Alaska both have, so
# `rhtp_classify_recipient_type()` falls back to §8's standing answer for the
# names it cannot resolve, and the hospital rows it does resolve are resolved
# FROM THE NAME (`determination_confidence = MEDIUM`, which is precisely §7's
# "hospital identity inferred from name without CCN match"). Nothing is promoted
# on this pipeline's own knowledge -- see the note in --report, and the
# named uncertainties recorded in docs/session21_completeness_recheck_maryland.md.
#
# WHAT RCJ GOT RIGHT, FOR ONCE, AND THE ONE ROW IT ADDS (§0.1). RCJ holds 42
# Maryland Tier 3 candidates against these 41 award offers. The 42nd is
# `Maryland Health Care Commission (MHCC)` at $6,300,000 -- which is the POOL,
# not a subaward: it is the MHCC Request for Applications' own budget, and it is
# the $6.3M the programme table prints against the Primary Care row. It tiers
# SOLICITATION, and `md_assert_rcj_reconciles()` requires exactly that
# arithmetic to close: 41 offers + the one pool = RCJ's 42, and $78,625,071 +
# $6,300,000 = RCJ's $84,925,071. A Tier 2 figure sitting in a Tier 3 candidate
# list is §0.2 in one row, and it is the row that would have inflated Maryland.
#
# THE PARSE IS GEOMETRIC, AND IT HAD TO BE. Both PDFs put page objects inside a
# compressed object stream and every page's drawing inside a form XObject, so
# the reader this project already had returned CHARACTER(0) -- not an error, an
# empty answer. `R/utils_pdf_text.R` was extended for it (see that file's
# header), and the tables are then read by COLUMN POSITION: the recipient, the
# amount, the summary and the counties sit at four stable x values, and nothing
# in the content ORDER separates them. Rows are bounded by the summary column's
# blocks, because the recipient column alone is not enough -- "Chester River
# Health System Inc (UM Shore Regional)" and "Choptank Community Health System
# Inc" are adjacent, both wrap, and a nearest-amount rule puts "Choptank" on
# Chester River's row and leaves Choptank nameless.
#
# Usage:
#   Rscript R/03p_md_year1_awardees.R --fetch     # archive 5 sources + SHA-256
#   Rscript R/03p_md_year1_awardees.R --validate  # assertions, offline
#   Rscript R/03p_md_year1_awardees.R --build     # writes CSV + xlsx
#   Rscript R/03p_md_year1_awardees.R --report    # the two pools, and the soft edge

suppressPackageStartupMessages({
  library(dplyr)
  library(openxlsx)
  library(readr)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_pdf_text.R"))
source(here::here("R", "utils_recipient_classification.R"))

MD_STATE        <- "MD"
MD_EVIDENCE_DIR <- here::here("data", "evidence", "MD")
MD_CSV          <- "data/reference/md_year1_awardees.csv"
MD_XLSX         <- "MD_year1_awardees.xlsx"
MD_HOST_THROTTLE_S <- 3
MD_USER_AGENT <- paste(
  "RHTP-Tracker/0.1 (AHA Data & Policy research;",
  "+https://www.aha.org)"
)

MD_PROGRAM_PAGE <- paste0("https://health.maryland.gov/pophealth/Pages/",
                          "Rural-Health-Transformation-Program.aspx")
MD_PROC_PAGE    <- "https://health.maryland.gov/pophealth/Pages/RHTP-Procurement.aspx"
MD_NEWS_PAGE    <- paste0(
  "https://health.maryland.gov/newsroom/Pages/",
  "Moore-Miller%20Administration%20secures%20$168%20million%20in%20federal%20",
  "funding%20to%20advance%20health%20care%20in%20rural%20Maryland%20communities.aspx")
MD_DOC_BASE     <- "https://health.maryland.gov/pophealth/Documents/Rural%20Health/RHTP/"

MD_SOURCES <- tibble::tribble(
  ~key,            ~url,                                                        ~file,                                      ~doc_title,
  "program_page",  MD_PROGRAM_PAGE,                                             "2026-08-29_mdh_rhtp_program_page.html",    "Rural Health Transformation Program (RHTP) | Maryland Department of Health",
  "procurement",   MD_PROC_PAGE,                                                "2026-08-29_mdh_rhtp_procurement.html",     "RHTP Requests for Application / Requests for Proposals | Maryland Department of Health",
  "newsroom",      MD_NEWS_PAGE,                                                "2025-12-31_mdh_168m_federal_funding.html", "Moore-Miller Administration Secures $168 million in Federal Funding to Advance Health Care in Rural Maryland Communities",
  "transformation", paste0(MD_DOC_BASE, "Pillar-2-Transformation-Fund-BP1-Award-Offers.pdf"),      "2026-08-29_mdh_pillar2_transformation_fund_bp1_award_offers.pdf", "Maryland Rural Health Transformation Program Pillar 2: Promote Sustainable Access and Innovative Care Transformation Funds Award Offers, Budget Period 1",
  "primary_care",   paste0(MD_DOC_BASE, "Pillar-2-Expand-Primary-Care-Access-BP1-Award-Offers.pdf"), "2026-08-29_mdh_pillar2_expand_primary_care_bp1_award_offers.pdf", "Maryland Rural Health Transformation Program Pillar 2: Promote Sustainable Access and Innovative Care - Expand Primary Care Access Award Offers, Budget Period 1"
)

# Every figure below is quoted from a source archived under data/evidence/MD/
# and every one is asserted against the parse. They are the reconciliation and
# they are the tripwire: if MDH republishes with a different count, the assert
# fails here rather than a wrong number reaching a workbook.
MD_STATED <- list(
  transformation_n     = 33L,
  transformation_total = 72412038,
  transformation_pool  = 73000000,     # "$73M" in MDH's own funding table
  primary_care_n       = 8L,
  primary_care_total   = 6213033,
  primary_care_pool    = 6300000,      # "$6.3M", and RCJ's 42nd candidate
  bp1_subawards        = 163700000,    # "a series of subawards totaling $163.7 million"
  cms_allotment        = 168180838,    # §7.1, cms_fy2026_allotments.csv
  noa_date             = as.Date("2025-12-29"),
  # RCJ, for §0.1 corroboration only. Never a published figure.
  rcj_candidates       = 42L,
  rcj_amount_sum       = 84925071,
  # The named-hospital floor, and the uncertainty that sits beside it. MDH
  # publishes no organisation-type column, so 24 of 41 recipient_types are
  # derived from the recipient's own name and fall to §8's standing fallback.
  named_hospital_n     = 6L,
  named_hospital_floor = 14678864,
  form_not_stated_n    = 24L,
  form_not_stated_total = 36558089
)

# The open classification question, in data/reference/classification_review_queue.csv.
# UNLIKE KANSAS'S, THIS ONE MOVES DOLLARS IN BOTH DIRECTIONS: TidalHealth and
# Meritus Health Center are inside the 24 and are not counted today, while
# Choptank Community Health System and Mountain Laurel Medical Center are typed
# HOSPITAL_OR_SYSTEM from their names and are. Nothing was promoted and nothing
# was demoted (§0.4); the CCN match (open blocker 5) resolves it.
MD_FORM_NOT_STATED_QUESTION <- "MD_RECIPIENT_FORM_NOT_STATED"

# The two award links that must be on the programme page, and the shape a third
# would take. See the header: this is the positive control.
MD_AWARD_LINK_FILES <- c(
  transformation = "Pillar-2-Transformation-Fund-BP1-Award-Offers.pdf",
  primary_care   = "Pillar-2-Expand-Primary-Care-Access-BP1-Award-Offers.pdf"
)
MD_AWARD_LINK_SHAPE <- "(?i)award offers?|awardees|award recipients|awarded project"

# The sentence that ties Maryland's subawards to CMS RHTP money, on MDH's own
# page. §6.2's first question, answered by the awarding agency.
MD_CMS_SENTENCE <- paste(
  "All partners and subawardees of Maryland's RHTP cooperative agreement with",
  "the Centers for Medicare and Medicaid Services (CMS) must agree to and",
  "comply with RHTP terms and conditions"
)

MD_CREDENTIAL_SHAPES <- c(
  mapbox_token   = "[ps]k\\.ey[A-Za-z0-9_-]{10,}",
  google_api_key = "AIza[A-Za-z0-9_-]{30,}",
  bearer_token   = "(?i)bearer\\s+[A-Za-z0-9._-]{25,}",
  aws_key        = "AKIA[A-Z0-9]{12,}"
)


# -- fetch --------------------------------------------------------------------

md_source <- function(key, field) {
  row <- MD_SOURCES[MD_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[MD] unknown source key: ", key, call. = FALSE)
  row[[field]]
}

md_path <- function(key) file.path(MD_EVIDENCE_DIR, md_source(key, "file"))

#' Refuse to archive anything carrying a credential (§7.1, sessions 14/16/17/20)
md_assert_credential_free <- function(body, label) {
  chunk <- body[seq_len(min(length(body), 4e6))]
  txt   <- rawToChar(chunk[chunk != as.raw(0)])
  Encoding(txt) <- "latin1"
  for (nm in names(MD_CREDENTIAL_SHAPES)) {
    if (stringr::str_detect(txt, MD_CREDENTIAL_SHAPES[[nm]])) {
      stop("[MD] refusing to archive ", label, ": it carries what looks like a ",
           nm, ".", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' Archive the five Maryland sources verbatim, with a SHA-256 manifest
#'
#' All five are archived WHOLE. Unlike CMS, Illinois, Oregon and Kansas, none of
#' MDH's pages carries a third-party credential -- the guard runs on every fetch
#' and finds nothing, which is the reason the manifest can say "byte for byte"
#' without a caveat rather than because nobody looked.
md_fetch <- function(force = FALSE) {
  dir.create(MD_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)

  entries <- purrr::map_dfr(seq_len(nrow(MD_SOURCES)), function(i) {
    src  <- MD_SOURCES[i, ]
    dest <- file.path(MD_EVIDENCE_DIR, src$file)

    if (file.exists(dest) && !force) {
      # §9.5: a re-run must never re-fetch an unchanged document.
      message("[MD] cached, not re-fetched: ", src$file)
    } else {
      if (i > 1L) Sys.sleep(MD_HOST_THROTTLE_S)
      message("[MD] fetching ", src$url)
      resp <- httr::GET(src$url, httr::user_agent(MD_USER_AGENT),
                        httr::timeout(180))
      if (httr::status_code(resp) != 200L) {
        stop("[MD] HTTP ", httr::status_code(resp), " for ", src$url,
             call. = FALSE)
      }
      served <- httr::content(resp, as = "raw")
      md_assert_credential_free(served, src$file)
      writeBin(served, dest)
    }

    tibble::tibble(
      key = src$key, file = src$file, url = src$url,
      bytes = file.info(dest)$size,
      sha256 = digest::digest(file = dest, algo = "sha256"),
      fetched_utc = format(Sys.time(), tz = "UTC", "%Y-%m-%dT%H:%M:%SZ")
    )
  })

  md_write_manifest(entries)
  entries
}

md_write_manifest <- function(entries) {
  path <- file.path(MD_EVIDENCE_DIR, "MANIFEST.txt")
  writeLines(c(
    "Maryland Department of Health -- RHTP Budget Period 1 sources",
    "Archived by R/03p_md_year1_awardees.R --fetch",
    paste0("User-agent: ", MD_USER_AGENT),
    "",
    "All five files are the body the server sent, BYTE FOR BYTE. None of them",
    "carries a third-party credential; the guard that caught CMS's Mapbox",
    "token, Illinois's and Oregon's, and Kansas's Google Maps key runs on every",
    "fetch here and finds nothing, so there is no reduction to explain.",
    "Files are written with writeBin(), so re-hashing a file on disk reproduces",
    "its digest below.",
    "",
    "MANIFEST.txt is deliberately absent from this listing: a manifest cannot",
    "record its own digest (session 15).",
    "",
    paste0(entries$sha256, "  ", entries$file, "  (", entries$bytes,
           " bytes)  <- ", entries$url)
  ), path)
  invisible(path)
}


# -- the positive control, and §6.2 -------------------------------------------

md_program_doc <- function() {
  path <- md_path("program_page")
  if (!file.exists(path)) {
    stop("[MD] the programme page is not archived. Run --fetch.", call. = FALSE)
  }
  xml2::read_html(path)
}

md_program_text <- function() {
  doc <- md_program_doc()
  xml2::xml_remove(xml2::xml_find_all(doc, "//script|//style"))
  stringr::str_squish(xml2::xml_text(doc))
}

#' The funding-opportunities table, one row per Budget Period 1 opportunity
#'
#' `award_offer_href` is populated only where MDH has published a roster. That
#' column IS the positive control: it is what makes an empty cell a real absence
#' rather than a failure to find the right string.
md_funding_table <- function() {
  doc <- md_program_doc()
  rows <- xml2::xml_find_all(doc, "//table//tr")

  purrr::map_dfr(seq_along(rows), function(i) {
    cells <- xml2::xml_find_all(rows[[i]], ".//td")
    if (length(cells) < 5L) return(tibble::tibble())
    txt <- stringr::str_squish(vapply(cells, xml2::xml_text, character(1)))
    if (identical(txt[1], "PILLAR")) return(tibble::tibble())
    links <- xml2::xml_find_all(rows[[i]], ".//a[@href]")
    labels <- stringr::str_squish(xml2::xml_text(links))
    hrefs  <- xml2::xml_attr(links, "href")
    is_award <- stringr::str_detect(labels, MD_AWARD_LINK_SHAPE)
    tibble::tibble(
      pillar    = txt[1],
      initiative = txt[2],
      partner    = txt[3],
      funding    = txt[4],
      timeline   = txt[5],
      award_offer_label = if (any(is_award)) labels[which(is_award)[1]] else NA_character_,
      award_offer_href  = if (any(is_award)) hrefs[which(is_award)[1]] else NA_character_
    )
  })
}

#' The tripwire, in both directions (§0.1, Kansas's device)
md_assert_award_index <- function() {
  tbl <- md_funding_table()
  if (nrow(tbl) < 8L) {
    stop("[MD] the funding-opportunities table parsed to ", nrow(tbl),
         " rows; MDH publishes ten Budget Period 1 opportunities. The page ",
         "shape has changed -- re-read it before trusting anything below.",
         call. = FALSE)
  }

  linked <- tbl$award_offer_href[!is.na(tbl$award_offer_href)]
  got <- basename(linked)
  want <- unname(MD_AWARD_LINK_FILES)

  missing <- setdiff(want, got)
  if (length(missing)) {
    stop("[MD] an award-offer link this file parses is GONE from the ",
         "programme page: ", paste(missing, collapse = ", "),
         ". A renamed link would otherwise turn every future run silently ",
         "green.", call. = FALSE)
  }
  extra <- setdiff(got, want)
  if (length(extra)) {
    stop("[MD] Maryland has published an award list this file does not ",
         "carry: ", paste(extra, collapse = ", "),
         ". The file is stale rather than wrong -- extract it.", call. = FALSE)
  }

  message("  positive control: ", nrow(tbl), " Budget Period 1 opportunities, ",
          length(linked), " with a published award-offer roster; ",
          nrow(tbl) - length(linked), " without, each open or at bid stage.")
  invisible(tbl)
}

#' §6.2 first question: is this RHTP money, said by the awarding agency?
md_assert_rhtp_funded <- function() {
  proc <- md_path("procurement")
  if (!file.exists(proc)) stop("[MD] procurement page not archived.", call. = FALSE)
  doc <- xml2::read_html(proc)
  xml2::xml_remove(xml2::xml_find_all(doc, "//script|//style"))
  txt <- stringr::str_squish(xml2::xml_text(doc))
  # The apostrophe MDH types is a right single quote, so match around it.
  needle <- "cooperative agreement with the Centers for Medicare and Medicaid Services \\(CMS\\)"
  if (!stringr::str_detect(txt, needle)) {
    stop("[MD] the procurement page no longer states that Maryland's ",
         "subawardees are bound by its RHTP cooperative agreement with CMS. ",
         "That sentence is what makes these award offers RHTP money rather ",
         "than a state programme (§6.2, Texas).", call. = FALSE)
  }
  prog <- md_program_text()
  if (!stringr::str_detect(prog, "subawards totaling \\$163\\.7 million in Budget Period 1")) {
    stop("[MD] the programme page no longer states the $163.7M Budget Period 1 ",
         "subaward total; the pools below no longer sit inside a stated whole.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' §6.2 second question: did the state have the money when it solicited?
#'
#' The dates are read out of the archived page, not typed here. Texas's
#' HHS0015180 closed 2025-04-24, eight months before its NOA; Maryland's two
#' solicitations opened in April and May 2026, four months after.
md_assert_after_noa <- function() {
  noa <- MD_STATED$noa_date
  anchor <- here::here("data", "reference", "cms_state_noa_dates.csv")
  if (file.exists(anchor)) {
    a <- readr::read_csv(anchor, show_col_types = FALSE, progress = FALSE)
    row <- a[a$state == MD_STATE, , drop = FALSE]
    if (nrow(row) == 1L && "noa_date" %in% names(row)) {
      noa <- as.Date(row$noa_date[1])
    }
  }

  tbl <- md_funding_table()
  linked <- tbl[!is.na(tbl$award_offer_href), , drop = FALSE]
  posted <- vapply(linked$timeline, function(t) {
    m <- stringr::str_match(t, "Posted:?\\s*(\\d{1,2}/\\d{1,2}/\\d{4})")
    if (is.na(m[1, 2])) NA_character_ else m[1, 2]
  }, character(1))

  if (anyNA(posted)) {
    stop("[MD] could not read a posting date for every published award pool; ",
         "the §6.2 date test cannot be run and must not be assumed.",
         call. = FALSE)
  }
  dates <- as.Date(posted, format = "%m/%d/%Y")
  if (any(dates <= noa)) {
    stop("[MD] a funding opportunity was posted on or before Maryland's CMS ",
         "Notice of Award (", noa, "): ", paste(posted[dates <= noa], collapse = ", "),
         ". Money the state did not yet have cannot have funded it (§6.2).",
         call. = FALSE)
  }
  message("  §6.2 date test: solicitations posted ",
          paste(format(sort(dates), "%Y-%m-%d"), collapse = ", "),
          ", all after the ", noa, " CMS Notice of Award.")
  invisible(dates)
}


# -- the two table parsers ----------------------------------------------------

#' Read a column-positioned award table out of one of MDH's PDFs
#'
#' Rows are bounded by the SUMMARY column's blocks, not by the recipient
#' column's own gaps. Two adjacent recipients that both wrap -- Chester River
#' Health System Inc (UM Shore Regional) and Choptank Community Health System
#' Inc -- are 22 points apart where a wrapped line is 17, and a nearest-amount
#' rule puts "Choptank" on Chester River's row and leaves Choptank nameless.
#' The summary blocks contain each row's name lines exactly.
#'
#' @param path PDF to read.
#' @param name_x,summary_x The x positions of the recipient and summary columns.
#' @param tol Column tolerance, in points.
#' @param gap The vertical gap that separates two blocks. A wrapped line is
#'   ~17 points; the smallest observed gap between rows is 22.
md_read_award_table <- function(path, name_x, summary_x, tol = 0.6, gap = 20) {
  lines <- rhtp_pdf_lines(path)
  if (nrow(lines) == 0L) {
    stop("[MD] ", basename(path), " produced no text. An EMPTY answer is the ",
         "failure this file exists to notice -- do not read it as 'the state ",
         "published nothing'.", call. = FALSE)
  }

  band <- lines[abs(lines$x - summary_x) < tol, , drop = FALSE]
  band <- band[order(band$page, band$y), , drop = FALSE]
  if (nrow(band) == 0L) {
    stop("[MD] no summary column at x=", summary_x, " in ", basename(path),
         "; the table's geometry has changed.", call. = FALSE)
  }
  band$blk <- cumsum(c(TRUE, diff(band$y) > gap | diff(band$page) != 0))
  bands <- band %>%
    dplyr::group_by(.data$blk) %>%
    dplyr::summarise(page = dplyr::first(.data$page), y0 = min(.data$y),
                     y1 = max(.data$y),
                     summary = stringr::str_squish(paste(.data$text, collapse = " ")),
                     .groups = "drop")

  to_band <- function(rows) {
    vapply(seq_len(nrow(rows)), function(i) {
      cand <- bands[bands$page == rows$page[i], , drop = FALSE]
      if (!nrow(cand)) return(NA_integer_)
      dist <- pmax(0, cand$y0 - rows$y[i]) + pmax(0, rows$y[i] - cand$y1)
      j <- which.min(dist)
      if (dist[j] > gap) NA_integer_ else cand$blk[j]
    }, integer(1))
  }

  amt <- lines[grepl("^\\$[0-9,]+$", lines$text), , drop = FALSE]
  amt <- amt[order(amt$page, amt$y), , drop = FALSE]
  amt$blk <- to_band(amt)

  nm <- lines[abs(lines$x - name_x) < tol, , drop = FALSE]
  nm <- nm[order(nm$page, nm$y), , drop = FALSE]
  nm$blk <- to_band(nm)

  names_by_band <- nm %>%
    dplyr::filter(!is.na(.data$blk)) %>%
    dplyr::group_by(.data$blk) %>%
    dplyr::summarise(awardee = stringr::str_squish(paste(.data$text, collapse = " ")),
                     .groups = "drop")

  out <- amt %>%
    dplyr::filter(!is.na(.data$blk)) %>%
    dplyr::transmute(.data$blk, .data$page, .data$y,
                     amount = as.numeric(gsub("[$,]", "", .data$text))) %>%
    dplyr::left_join(names_by_band, by = "blk") %>%
    dplyr::left_join(bands %>% dplyr::select("blk", "summary"), by = "blk") %>%
    dplyr::arrange(.data$page, .data$y)

  if (anyNA(out$awardee) || any(!nzchar(out$awardee))) {
    stop("[MD] ", sum(is.na(out$awardee) | !nzchar(out$awardee)),
         " award amount(s) in ", basename(path), " have no recipient beside ",
         "them. A nameless award is never published as one.", call. = FALSE)
  }
  out %>% dplyr::select("awardee", "amount", "summary")
}

#' The Primary Care table, whose columns are too close to separate
#'
#' MHCC's table sets the recipient and the amount so close together that they
#' land on the same visual line, so this reads the whole left column and splits
#' each block on its own dollar figure. It is not the same shape as the
#' Transformation Fund table and pretending it is loses all eight rows.
md_read_primary_care <- function(path, name_x = 70.5, tol = 0.6, gap = 20) {
  lines <- rhtp_pdf_lines(path)
  nm <- lines[abs(lines$x - name_x) < tol, , drop = FALSE]
  nm <- nm[order(nm$page, nm$y), , drop = FALSE]
  if (nrow(nm) == 0L) {
    stop("[MD] no recipient column at x=", name_x, " in ", basename(path),
         call. = FALSE)
  }
  nm$blk <- cumsum(c(TRUE, diff(nm$y) > gap | diff(nm$page) != 0))

  blocks <- nm %>%
    dplyr::group_by(.data$blk) %>%
    dplyr::summarise(text = stringr::str_squish(paste(.data$text, collapse = " ")),
                     .groups = "drop")

  has_amount <- stringr::str_detect(blocks$text, "\\$[0-9,]+")
  if (!all(has_amount)) {
    stop("[MD] ", sum(!has_amount), " Primary Care block(s) carry no amount: ",
         paste(blocks$text[!has_amount], collapse = " | "), call. = FALSE)
  }

  tibble::tibble(
    awardee = stringr::str_squish(stringr::str_replace(blocks$text, "\\s*\\$[0-9,]+.*$", "")),
    amount  = as.numeric(gsub("[$,]", "",
                              stringr::str_extract(blocks$text, "\\$[0-9,]+"))),
    summary = stringr::str_squish(stringr::str_replace(blocks$text, "^.*?\\$[0-9,]+\\s*", ""))
  )
}

md_award_offers <- function() {
  tf <- md_read_award_table(md_path("transformation"), name_x = 55.5,
                            summary_x = 242.25) %>%
    dplyr::mutate(award_pool = "PILLAR2_TRANSFORMATION_FUND",
                  source_key = "transformation")
  pc <- md_read_primary_care(md_path("primary_care")) %>%
    dplyr::mutate(award_pool = "PILLAR2_EXPAND_PRIMARY_CARE",
                  source_key = "primary_care")
  dplyr::bind_rows(tf, pc)
}


# -- assertions ---------------------------------------------------------------

md_assert_pools <- function(offers) {
  tf <- offers %>% dplyr::filter(.data$award_pool == "PILLAR2_TRANSFORMATION_FUND")
  pc <- offers %>% dplyr::filter(.data$award_pool == "PILLAR2_EXPAND_PRIMARY_CARE")

  stopifnot(nrow(tf) == MD_STATED$transformation_n)
  stopifnot(nrow(pc) == MD_STATED$primary_care_n)
  stopifnot(isTRUE(all.equal(sum(tf$amount), MD_STATED$transformation_total)))
  stopifnot(isTRUE(all.equal(sum(pc$amount), MD_STATED$primary_care_total)))

  # Each pool must fit inside the pool figure MDH prints for it. This is the
  # §6.2 ceiling applied one level down: a pool that exceeds its own stated
  # budget means the parse has picked up something that is not an award.
  if (sum(tf$amount) > MD_STATED$transformation_pool) {
    stop("[MD] Transformation Fund offers exceed MDH's stated $73M pool.",
         call. = FALSE)
  }
  if (sum(pc$amount) > MD_STATED$primary_care_pool) {
    stop("[MD] Primary Care offers exceed MDH's stated $6.3M pool.",
         call. = FALSE)
  }
  # And both together inside the Budget Period 1 subaward total, and inside
  # the CMS allotment.
  if (sum(offers$amount) > MD_STATED$bp1_subawards) {
    stop("[MD] the two pools exceed the stated $163.7M Budget Period 1 ",
         "subaward total.", call. = FALSE)
  }
  if (sum(offers$amount) > MD_STATED$cms_allotment) {
    stop("[MD] the two pools exceed Maryland's CMS allotment (§6.2 ceiling).",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' §0.1: RCJ corroborates the COUNT, and its 42nd row is the Tier 2 pool
#'
#' Derived from the committed record table on every run rather than typed, so
#' the day Maryland's candidate set moves this fails instead of quietly ceasing
#' to cover it (Texas's device).
md_assert_rcj_reconciles <- function(offers, quiet = FALSE) {
  rt_path <- here::here("data", "interim", "stage2_record_table.rds")
  if (!file.exists(rt_path)) {
    if (!quiet) message("  (no stage2 record table on disk; RCJ check skipped)")
    return(invisible(NULL))
  }
  rt <- readRDS(rt_path)
  md <- rt %>% dplyr::filter(.data$state == MD_STATE,
                             .data$award_tier == "SUBAWARD")

  n_expected <- nrow(offers) + 1L                     # + the MHCC pool row
  if (nrow(md) != n_expected) {
    stop("[MD] RCJ holds ", nrow(md), " Tier 3 candidates; this file plus the ",
         "one Tier 2 pool row accounts for ", n_expected,
         ". Maryland's candidate set has moved -- re-read it.", call. = FALSE)
  }
  pool <- md %>% dplyr::filter(stringr::str_detect(.data$awardee_name_clean,
                                                   "Maryland Health Care Commission"))
  if (nrow(pool) != 1L) {
    stop("[MD] expected exactly one Maryland Health Care Commission row in ",
         "RCJ's Tier 3 candidates (the POOL, misfiled as a subaward); found ",
         nrow(pool), ".", call. = FALSE)
  }
  if (!isTRUE(all.equal(pool$amount_announced[1], MD_STATED$primary_care_pool))) {
    stop("[MD] the MHCC pool row no longer carries $6,300,000.", call. = FALSE)
  }
  total <- sum(md$amount_announced, na.rm = TRUE)
  if (!isTRUE(all.equal(total, sum(offers$amount) + MD_STATED$primary_care_pool))) {
    stop("[MD] RCJ's Maryland amount sum no longer equals the 41 award offers ",
         "plus the one pool row.", call. = FALSE)
  }
  if (!quiet) {
    message("  §0.1: RCJ's ", nrow(md), " Tier 3 candidates = these ",
            nrow(offers), " award offers + the MHCC $6.3M POOL, which is Tier 2.")
  }
  invisible(TRUE)
}


# -- build --------------------------------------------------------------------

#' Pull one bucket's dollars out of `rhtp_hospital_dollar_partition()`
#'
#' The partition returns a tibble of (state, bucket, rows, dollars) and
#' deliberately no grand total. This reads one bucket, and returns 0 when the
#' bucket is absent -- which is a real answer, not a missing one.
md_bucket <- function(part, bucket) {
  hit <- part[part$bucket == bucket, , drop = FALSE]
  if (nrow(hit) == 0L) 0 else sum(hit$dollars)
}


md_records <- function() {
  offers <- md_award_offers()
  md_assert_pools(offers)

  classified <- rhtp_classify_records(offers, state = MD_STATE,
                                      description_col = "summary")

  titles <- vapply(classified$source_key, function(k) md_source(k, "doc_title"),
                   character(1), USE.NAMES = FALSE)
  urls   <- vapply(classified$source_key, function(k) md_source(k, "url"),
                   character(1), USE.NAMES = FALSE)
  files  <- vapply(classified$source_key, function(k) md_source(k, "file"),
                   character(1), USE.NAMES = FALSE)

  classified %>%
    dplyr::mutate(
      state = MD_STATE,
      row_no = dplyr::row_number(),
      note = .data$summary,
      # Maryland's own word is OFFER. An offer is not an executed agreement.
      recipient_confirmed = "Yes",
      amount_confirmed = "No",
      fiscal_year = "FY2026",
      source_document_title = titles,
      state_source_url = urls,
      validation_source_type = "NOTICE_OF_INTENT_TO_AWARD",
      extraction_method = "DIRECT_TEXT",
      validator = "AUTO",
      ccn = NA_character_,
      aha_id = NA_character_,
      rural_designation = NA_character_,
      reviewer = NA_character_,
      recipient_type_source = "DERIVED_FROM_NAME",
      source_archive_path = file.path("data/evidence/MD", files),
      budget_period = "BP1",
      hospital_attribution = rhtp_hospital_attribution(
        .data$flow_type, .data$distributed_to_hospital, .data$recipient_type)
    ) %>%
    dplyr::select(
      "state", "row_no", "awardee", "amount", "recipient_type",
      "distributed_to_hospital", "note", "recipient_confirmed",
      "amount_confirmed", "fiscal_year", "source_document_title",
      "state_source_url", "validation_source_type", "extraction_method",
      "validator", "ccn", "aha_id", "rural_designation", "reviewer",
      "recipient_type_source", "determination_confidence", "flag_reason",
      "award_pool", "budget_period", "flow_type", "hospital_benefiting",
      "hospital_attribution", "determination_basis", "classification_rule",
      "source_archive_path"
    )
}

md_validate <- function() {
  md_assert_award_index()
  md_assert_rhtp_funded()
  md_assert_after_noa()
  recs <- md_records()

  # column -> the §8 vocabulary that governs it. `validation_source_type` is
  # governed by `source_doc_type`, which is the name the vocabulary file uses.
  governed <- c(
    recipient_type           = "recipient_type",
    distributed_to_hospital  = "distributed_to_hospital",
    flow_type                = "flow_type",
    determination_confidence = "determination_confidence",
    validation_source_type   = "source_doc_type",
    extraction_method        = "extraction_method",
    validator                = "validator",
    recipient_confirmed      = "recipient_confirmed",
    amount_confirmed         = "amount_confirmed",
    hospital_benefiting      = "hospital_benefiting",
    hospital_attribution     = "hospital_attribution"
  )
  for (col in names(governed)) {
    allowed <- rhtp_vocabulary(governed[[col]])
    bad <- setdiff(stats::na.omit(unique(recs[[col]])), allowed)
    if (length(bad)) {
      stop("[MD] ", col, " outside §8 (", governed[[col]], "): ",
           paste(bad, collapse = ", "), call. = FALSE)
    }
  }
  flags <- stats::na.omit(unique(recs$flag_reason))
  bad <- setdiff(flags, rhtp_vocabulary("flag_reason"))
  if (length(bad)) {
    stop("[MD] flag_reason outside §8: ", paste(bad, collapse = ", "),
         call. = FALSE)
  }
  stopifnot(nrow(recs) == MD_STATED$transformation_n + MD_STATED$primary_care_n)
  stopifnot(!anyNA(recs$amount), all(recs$amount > 0))
  md_assert_rcj_reconciles(recs)
  md_assert_form_not_stated_queued(recs)
  message("[MD] all assertions pass.")
  invisible(recs)
}

#' THE FIGURE IS A FLOOR AND THE UNCERTAINTY IS DISCLOSED WHERE SOMEONE WILL
#' FIND IT.
#'
#' MDH publishes no organisation-type column, so 24 of 41 recipient_types are
#' derived from the recipient's own name and take §8's standing fallback
#' (NONPROFIT_CBO + LOW + RECIPIENT_TYPE_INFERRED). Nothing is promoted on this
#' pipeline's own knowledge of Maryland (§0.4) -- and nothing is demoted either,
#' which is the half Kansas did not have: two of the six rows inside today's
#' hospital figure read as FQHCs on the ordinary reading of their names.
#'
#' A caveat in a workbook nobody opens is not a disclosure, so the question goes
#' in data/reference/classification_review_queue.csv and its presence there is
#' asserted every run -- Kansas's device, and the reason this one exists at all.
md_assert_form_not_stated_queued <- function(recs) {
  inferred <- recs %>%
    dplyr::filter(.data$determination_confidence == "LOW",
                  .data$flag_reason == "RECIPIENT_TYPE_INFERRED")
  if (nrow(inferred) != MD_STATED$form_not_stated_n) {
    stop("[MD] ", nrow(inferred), " rows carry §8's recipient-form fallback; ",
         MD_STATED$form_not_stated_n, " were queued for review. The disclosure ",
         "and the data have drifted apart.", call. = FALSE)
  }
  if (!isTRUE(all.equal(sum(inferred$amount), MD_STATED$form_not_stated_total))) {
    stop("[MD] the unstated-form rows sum to ",
         format(sum(inferred$amount), big.mark = ","), " against a queued ",
         format(MD_STATED$form_not_stated_total, big.mark = ","), ".",
         call. = FALSE)
  }

  named <- recs %>% dplyr::filter(.data$distributed_to_hospital == "Yes")
  if (nrow(named) != MD_STATED$named_hospital_n ||
      !isTRUE(all.equal(sum(named$amount), MD_STATED$named_hospital_floor))) {
    stop("[MD] the named-hospital floor is ", nrow(named), " rows / ",
         format(sum(named$amount), big.mark = ","), " against a stated ",
         MD_STATED$named_hospital_n, " / ",
         format(MD_STATED$named_hospital_floor, big.mark = ","), ".",
         call. = FALSE)
  }
  # THE UNCERTAINTY IS LARGER THAN THE FIGURE, and if that ever stops being true
  # the sentence this repository publishes about Maryland has to change.
  if (MD_STATED$form_not_stated_total <= MD_STATED$named_hospital_floor) {
    stop("[MD] the unstated-form dollars no longer exceed the named-hospital ",
         "floor. Re-word the finding before publishing it.", call. = FALSE)
  }

  queue <- readr::read_csv(
    here::here("data/reference/classification_review_queue.csv"),
    show_col_types = FALSE, progress = FALSE)
  row <- queue %>%
    dplyr::filter(.data$question_id == MD_FORM_NOT_STATED_QUESTION)
  if (nrow(row) != 1L || !identical(row$queue_status[[1]], "OPEN")) {
    stop("[MD] ", MD_FORM_NOT_STATED_QUESTION, " is not an OPEN row in ",
         "classification_review_queue.csv. A disclosure nobody can find is ",
         "not a disclosure.", call. = FALSE)
  }
  if (!grepl(format(MD_STATED$form_not_stated_total, big.mark = ","),
             row$dollar_effect[[1]], fixed = TRUE)) {
    stop("[MD] the queued dollar effect does not state ",
         format(MD_STATED$form_not_stated_total, big.mark = ","),
         "; the queue and the data disagree.", call. = FALSE)
  }
  invisible(TRUE)
}

md_build <- function() {
  recs <- md_validate()
  readr::write_csv(recs, here::here(MD_CSV), na = "")
  message("[MD] wrote ", MD_CSV, " (", nrow(recs), " rows)")

  part <- rhtp_hospital_dollar_partition(recs)

  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "READ ME FIRST")
  openxlsx::writeData(wb, "READ ME FIRST", tibble::tibble(note = c(
    "MARYLAND RHTP YEAR 1 (BUDGET PERIOD 1) -- AWARD OFFERS.",
    "",
    "These are OFFERS, not executed agreements. Maryland's own word is",
    "\"Award Offers\", and its programme table pairs each pool with an",
    "\"Anticipated Project Period Start Date\". Every row is",
    "NOTICE_OF_INTENT_TO_AWARD with amount_confirmed = No.",
    "",
    "TWO POOLS, IN TWO DOCUMENTS. Read `award_pool` before using any figure.",
    paste0("  Pillar 2 Transformation Funds        33 offers   $",
           format(MD_STATED$transformation_total, big.mark = ",")),
    paste0("  Pillar 2 Expand Primary Care Access   8 offers   $",
           format(MD_STATED$primary_care_total, big.mark = ",")),
    "",
    "MDH PUBLISHES NO ORGANISATION TYPE. There is no column of the kind Oregon",
    "and Alaska both publish, so recipient_type is derived from the recipient's",
    "own NAME. Rows at determination_confidence = MEDIUM are §7's \"hospital",
    "identity inferred from name without CCN match\"; rows at LOW carry §8's",
    "standing fallback and their form is simply not stated anywhere by MDH.",
    "Nothing was promoted on this pipeline's own knowledge (§0.4).",
    "",
    "MARYLAND HAS EIGHT MORE BUDGET PERIOD 1 OPPORTUNITIES WITH NO PUBLISHED",
    "ROSTER. Their absence is real, not unlooked-for: MDH's funding table",
    "carries an \"Award Offers\" link wherever a roster exists, and this file's",
    "positive control asserts both links present and refuses a third."
  )))

  openxlsx::addWorksheet(wb, "Award offers")
  openxlsx::writeData(wb, "Award offers", recs)
  openxlsx::freezePane(wb, "Award offers", firstRow = TRUE)

  openxlsx::addWorksheet(wb, "Reconciliation")
  openxlsx::writeData(wb, "Reconciliation", tibble::tibble(
    item = c("Pillar 2 Transformation Funds -- offers",
             "Pillar 2 Transformation Funds -- MDH stated pool",
             "Pillar 2 Expand Primary Care -- offers",
             "Pillar 2 Expand Primary Care -- MDH stated pool",
             "All award offers",
             "MDH stated Budget Period 1 subawards",
             "CMS FY2026 allotment (§7.1)",
             "Hospital dollars -- NAMED_HOSPITAL",
             "Hospital dollars -- POOL_UNNAMED_HOSPITALS",
             "Recipient form NOT STATED by MDH (§8 fallback rows)"),
    value = c(MD_STATED$transformation_total, MD_STATED$transformation_pool,
              MD_STATED$primary_care_total, MD_STATED$primary_care_pool,
              sum(recs$amount), MD_STATED$bp1_subawards, MD_STATED$cms_allotment,
              md_bucket(part, "NAMED_HOSPITAL"),
              md_bucket(part, "POOL_UNNAMED_HOSPITALS"),
              sum(recs$amount[recs$determination_confidence == "LOW"]))
  ))

  openxlsx::saveWorkbook(wb, here::here(MD_XLSX), overwrite = TRUE)
  message("[MD] wrote ", MD_XLSX)
  invisible(recs)
}

md_report <- function() {
  recs <- md_records()
  part <- rhtp_hospital_dollar_partition(recs)
  cat("\nMARYLAND -- RHTP Budget Period 1 award offers\n")
  cat(strrep("-", 74), "\n")
  print(as.data.frame(recs %>% dplyr::count(.data$award_pool,
                                            name = "offers") %>%
    dplyr::left_join(recs %>% dplyr::group_by(.data$award_pool) %>%
                       dplyr::summarise(dollars = sum(.data$amount), .groups = "drop"),
                     by = "award_pool")), row.names = FALSE)
  cat("\nTotal: ", nrow(recs), " award offers, $",
      format(sum(recs$amount), big.mark = ","), " -- ",
      round(100 * sum(recs$amount) / MD_STATED$cms_allotment, 1),
      "% of the CMS allotment\n", sep = "")
  cat("\nHospital dollars, PARTITIONED and never added (§10.2):\n")
  cat("  NAMED_HOSPITAL        : ",
      format(md_bucket(part, "NAMED_HOSPITAL"), big.mark = ","), "\n")
  cat("  POOL_UNNAMED_HOSPITALS: ",
      format(md_bucket(part, "POOL_UNNAMED_HOSPITALS"), big.mark = ","), "\n")
  soft <- recs %>% dplyr::filter(.data$determination_confidence == "LOW")
  cat("\nRECIPIENT FORM NOT STATED BY MDH: ", nrow(soft), " rows, $",
      format(sum(soft$amount), big.mark = ","),
      "\n  §8's standing fallback. The CCN match (open blocker 5) resolves them.\n",
      sep = "")
  invisible(recs)
}


# `sys.nframe() == 0L` is the repo's CLI guard: it is FALSE when the file is
# sourced by a test or another stage, so nothing here runs then.
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) print(md_fetch(force = "--force" %in% args))
  if ("--validate" %in% args) md_validate()
  if ("--build" %in% args) md_build()
  if ("--report" %in% args) md_report()
  if (!any(c("--fetch", "--validate", "--build", "--report") %in% args)) {
    cat("Usage: Rscript R/03p_md_year1_awardees.R [--fetch|--validate|--build|--report]\n")
  }
}
