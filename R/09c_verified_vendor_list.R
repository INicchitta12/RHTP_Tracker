# 09c_verified_vendor_list.R ----------------------------------------------------
# Session 116e: the VERIFIED consultant / intermediary / out-of-state vendor list.
#
# PURPOSE. A list for AHA colleagues of large RHTP sums (>= $1M) going to
# consultants, intermediaries and out-of-state vendors, each one re-verified
# against the archived primary source. A case that fails any test is DROPPED,
# never caveated. Internal only.
#
# THIS LAYER ONLY READS. It changes no award row, summary call, bucket or
# hospital figure. It writes:
#   data/reference/verified_vendor_list.csv           passing cases
#   data/reference/verified_vendor_dropped.csv        every drop, with its test
#   data/reference/verified_vendor_unnamed_lines.csv  CMS lines naming no firm
#   data/reference/verified_vendor_planned.csv        budget-plan lines (NOT awards)
#   data/reference/verified_vendor_live_check_<date>.csv   (--live)
#   output/verified_vendor_list_<date>.xlsx           (--xlsx)
#
# INPUTS WRITTEN BY HAND (each row read against its source by a person):
#   config/verified_vendor_cases.csv       the candidate cases claimed to pass
#   config/verified_vendor_hand_drops.csv  candidates a person dropped, with the test
# The machine then re-checks every claimed case field by field against the
# ARCHIVED BYTES and drops any that fail. It never promotes a hand drop.
#
# THE TESTS (the brief's V1-V9; the "Method" tab writes them out plainly)
#   V1 source class in {FSRS_FFATA, STATE_AWARD_LIST, STATE_CONTRACT_REGISTER,
#      CMS_OBLIGATION_REPORT}. Press, RCJ, plans, annual reports fail.
#   V2 the document itself says Rural Health Transformation / RHTP / 93.798.
#   V3 the amount is printed in the source exactly; one amount type per case.
#   V4 the purpose quote is found verbatim in the source (segments joined by
#      " [...] " are each found); the category is a hand judgment on that quote.
#   V5 the recipient name as printed is found in the source; UEI only from an
#      FSRS record linked by the same record, an identical identifier, or an
#      equal normalised legal name in the same prime state.
#   V6 OUT_OF_STATE_VENDOR needs that FSRS record, with a state code that is not
#      the awarding state. Otherwise the category is removed.
#   V7 >= $1,000,000; not a hospital or health system; not a state agency of the
#      awarding state (FSRS 'STATE GOVERNMENT' that is not a state institution of
#      higher learning, or STATE_AGENCY in this repository's award file).
#   V8 the archive's SHA-256 is computed and must appear in its manifest; the
#      URL's live status is recorded by --live.
#   V9 hand: an out-of-state organisation whose source says the money funds its
#      own in-state operations is dropped (config/verified_vendor_hand_drops.csv).
#
# CLI
#   Rscript R/09c_verified_vendor_list.R --build    # checks + the four CSVs
#   Rscript R/09c_verified_vendor_list.R --live     # live status of every source URL
#   Rscript R/09c_verified_vendor_list.R --xlsx     # the deliverable
#   Rscript R/09c_verified_vendor_list.R --report

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
  library(tidyr)
  library(purrr)
})

source(here::here("R", "09_vendor_flags.R"))

VV_AS_OF <- "2026-11-10"
VV_CASES <- "config/verified_vendor_cases.csv"
VV_HAND_DROPS <- "config/verified_vendor_hand_drops.csv"
# Task 4: a separate agent that had not seen the case-building re-opened every
# archive and re-checked V1-V9 for every passing case. Any DROP removes the case.
VV_INDEPENDENT <- "config/verified_vendor_independent_check.csv"
# Round 2 (session 116e, after the owner's rulings): re-checks the changed cases
# only. Its verdict replaces round 1's for every case it covers.
VV_INDEPENDENT_R2 <- "config/verified_vendor_independent_check_r2.csv"
# Round-1 drops answered by the owner's Idaho ruling (V2 tie; PCG's CONSULTANT
# label removed). VV039's round-1 V4 failure was not answered by any ruling, so
# it is not here and stays dropped.
VV_R1_SUPERSEDED <- c("VV032", "VV033", "VV034", "VV035", "VV036")
VV_INTERMEDIARY_TYPES <- c("PASS_THROUGH_TO_PROVIDERS", "ADMINISTERS_ONLY", "NON_PROVIDER_RECIPIENTS")
VV_PASS_THROUGH_CSV <- "data/reference/verified_vendor_pass_through.csv"
VV_LIST_CSV <- "data/reference/verified_vendor_list.csv"
VV_DROPPED_CSV <- "data/reference/verified_vendor_dropped.csv"
VV_UNNAMED_CSV <- "data/reference/verified_vendor_unnamed_lines.csv"
VV_PLANNED_CSV <- "data/reference/verified_vendor_planned.csv"
VV_LIVE_CSV <- function(as_of = VV_AS_OF) paste0("data/reference/verified_vendor_live_check_", as_of, ".csv")
VV_XLSX <- function(as_of = VV_AS_OF) here::here("output", paste0("verified_vendor_list_", as_of, ".xlsx"))
VV_FLOOR <- 1e6
VV_CATEGORIES <- c("CONSULTANT", "INTERMEDIARY", "OUT_OF_STATE_VENDOR")
VV_AMOUNT_TYPES <- c("award", "intent", "obligation", "contract maximum")
VV_ADMISSIBLE <- c("FSRS_FFATA", "STATE_AWARD_LIST", "STATE_CONTRACT_REGISTER", "CMS_OBLIGATION_REPORT")
VV_TIE_RX <- regex("RURAL HEALTH TRANSFORMATION|\\bRHTP\\b|\\bRHT PROGRAM|93\\.798", ignore_case = TRUE)

# -- sources -------------------------------------------------------------------------

VV_SOURCES <- tibble::tribble(
  ~source_id, ~source_class, ~kind, ~title, ~url, ~archive_path, ~manifest,
  "S_FSRS", "FSRS_FFATA", "fsrs",
  "State's FFATA first-tier subaward report (SAM.gov), via USAspending custom download for Assistance Listing 93.798",
  NA_character_, "data/raw/usaspending/2026-11-09/usaspending_rhtp_93798_prime_and_subawards.zip",
  "data/raw/usaspending/2026-11-09/usaspending_rhtp_93798_prime_and_subawards.zip.manifest.txt",
  "S_KY_TRACKER", "STATE_CONTRACT_REGISTER", "pdf",
  "Kentucky Rural Health Transformation Executed Contracts by Contract Start Date (tracker dated 2026-09-08)",
  "https://ruralhealthplan.ky.gov/Documents/KyRHT_Executed_Contract_Tracker_2026.09.08.pdf",
  "data/evidence/recheck/2026-11-02/KY/2026-11-02_KyRHT_Executed_Contract_Tracker_2026.09.08.pdf",
  "data/evidence/recheck/2026-11-02/KY/MANIFEST.txt",
  "S_UT_GDOC", "STATE_AWARD_LIST", "txt",
  "Utah DHHS, RHTP Awardee Announcement (Google Doc linked from DHHS; intents: DHHS 'is preparing to formally announce')",
  "https://docs.google.com/document/d/1IDrbHOZTIIzUEtvlQXfC7RHPO0dhJktxW0Lkm52mt1M/",
  "data/evidence/recheck/2026-11-02/UT/2026-11-02_ut_dhhs_rhtp_awardee_announcement_gdoc.txt",
  "data/evidence/recheck/2026-11-02/UT/MANIFEST.txt",
  "S_VT_LIST", "STATE_AWARD_LIST", "html",
  "Vermont AHS, RHT Year 1 Awards and Contracts (executed agreements, list of 10-30)",
  "https://healthcarereform.vermont.gov/rht-year-1-executed-agreements-and-contracts",
  "data/evidence/recheck/2026-11-02/VT/2026-11-02_vt_year1_awards_FULLY_OBLIGATED_10-30.html",
  "data/evidence/recheck/2026-11-02/VT/MANIFEST.txt",
  "S_ID_LIST", "STATE_AWARD_LIST", "xlsx",
  "Idaho DHW, RHTP list of awardees as of Oct. 16 (dated 10-19-2026)",
  "https://publicdocuments.dhw.idaho.gov/WebLink/ElectronicFile.aspx?docid=37915",
  "data/evidence/recheck/2026-10-26/ID/id_rhtp_list_of_awardees_dated_2026-10-19.xlsx",
  "data/evidence/recheck/2026-10-26/ID/MANIFEST.txt",
  "S_AK_NOTICE", "STATE_AWARD_LIST", "xlsx",
  "Alaska DOH, RHTP Awards Notice 2026 (sheet 'Notice of Intent to Award', 10-12 file)",
  "https://health.alaska.gov/media/tcvker5a/ak_rhtp_awardsnotice_2026.xlsx",
  "data/evidence/AK/2026-10-12_ak_rhtp_awardsnotice_2026.xlsx",
  "data/evidence/AK/ak_rhtp_year1_awards.manifest.txt",
  "S_NE_NOA44B", "STATE_AWARD_LIST", "pdf",
  "Nebraska DHHS, RHTP Initiative 4.4b Awards (public notice of award, 06/10/2026)",
  "https://dhhs.ne.gov/Documents/RHTP-Public-Notice-of-Award-4.4b.pdf",
  "data/evidence/NE/2026-08-31_ne_dhhs_public_notice_of_award_4.4b.pdf",
  "data/evidence/NE/MANIFEST.txt",
  "S_WY_MIN", "STATE_AWARD_LIST", "pdf",
  "Wyoming RHT Advisory Committee minutes, 2026-08-11 (award approvals)",
  "https://drive.google.com/uc?export=download&id=1rx0ZDfGkPK2lG4L-W6aie9eXzU1t5pv2",
  "data/evidence/WY/2026-09-03_wy_advisory_committee_minutes_2026-08-11.pdf",
  "data/evidence/WY/MANIFEST.txt",
  "S_CMS_OBL", "CMS_OBLIGATION_REPORT", "pdf",
  "CMS, RHTP Obligated Funds Report (10-14 edition; obligations as of 2026-07-31)",
  "https://www.medicaid.gov/resources-for-states/rural-health/rhtp-resources/RHTP-Obligated-Funds-20261014.pdf",
  "data/raw/cms/obligations/2026-07-31/RHTP-Obligated-Funds-20261014.pdf",
  "data/raw/cms/obligations/2026-07-31/RHTP-Obligated-Funds-20261014.pdf.manifest.txt",
  # A TIE source (owner ruling, session 116e): Idaho's awardee xlsx carries no
  # programme name of its own; its RHTP tie is its publication on DHW's RHTP
  # funding page under "Closed and awarded funding opportunities". The page
  # must link the xlsx (link_key) or V2 fails.
  "S_ID_PAGE", "STATE_RHTP_PAGE", "html",
  "Idaho DHW, Funding Opportunities for Rural Health Transformation ('Closed and awarded funding opportunities' links the awardee list)",
  "https://healthandwelfare.idaho.gov/providers/rural-health-transformation-program-grant/funding-opportunities-rural-health",
  "data/evidence/ID/2026-10-26_id_rhtp_funding_opportunities.html",
  "data/evidence/ID/MANIFEST.txt"
)
VV_SOURCES$link_key <- dplyr::if_else(VV_SOURCES$source_id == "S_ID_LIST", "docid=37915", NA_character_)

# -- text helpers ------------------------------------------------------------------------

vv_norm_tokens <- function(x) {
  x <- toupper(x)
  # zero-width characters become SPACES: the WY minutes put U+200B between words
  x <- gsub("[​‌‍﻿]", " ", x)
  x <- gsub("[‘’“”–—]", " ", x)
  x <- gsub("&", " AND ", x, fixed = TRUE)
  x <- gsub("[^A-Z0-9.]+", " ", x)
  x <- gsub("(?<![0-9])\\.|\\.(?![0-9])", " ", x, perl = TRUE)
  t <- strsplit(stringr::str_squish(x), " ", fixed = TRUE)[[1]]
  t[t != ""]
}

#' Is `needle` (tokens) a subsequence of `hay` (tokens) with at most `gap`
#' foreign tokens between consecutive matches? gap = 0 means contiguous.
vv_find_seq <- function(needle, hay, gap = 0L) {
  if (length(needle) == 0) return(FALSE)
  starts <- which(hay == needle[1])
  for (s in starts) {
    pos <- s; ok <- TRUE
    for (k in seq_along(needle)[-1]) {
      lim <- min(length(hay), pos + 1L + gap)
      if (pos + 1L > length(hay)) { ok <- FALSE; break }
      hit <- which(hay[(pos + 1L):lim] == needle[k])
      if (length(hit) == 0) { ok <- FALSE; break }
      pos <- pos + hit[1]
    }
    if (ok) return(TRUE)
  }
  FALSE
}

vv_html_text <- function(path) {
  t <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = " ")
  t <- gsub("<script.*?</script>|<style.*?</style>", " ", t, perl = TRUE)
  t <- gsub("<[^>]+>", " ", t)
  ents <- c("&amp;" = "&", "&nbsp;" = " ", "&#x27;" = "'", "&#39;" = "'", "&rsquo;" = "'",
            "&lsquo;" = "'", "&ldquo;" = '"', "&rdquo;" = '"', "&quot;" = '"', "&ndash;" = "-",
            "&mdash;" = "-")
  for (e in names(ents)) t <- gsub(e, ents[[e]], t, fixed = TRUE)
  t
}

vv_pdf_text <- function(path) {
  out <- system2("pdftotext", c("-layout", shQuote(path), "-"), stdout = TRUE, stderr = FALSE)
  if (length(out) == 0) stop("[vv] pdftotext returned nothing for ", path, call. = FALSE)
  paste(out, collapse = "\n")
}

vv_xlsx_text <- function(path) {
  sh <- readxl::excel_sheets(path)
  paste(c(sh, unlist(lapply(sh, function(s) {
    d <- suppressMessages(readxl::read_excel(path, s, col_names = FALSE, col_types = "text"))
    apply(d, 1, function(r) paste(stats::na.omit(r), collapse = " | "))
  }))), collapse = "\n")
}

vv_source_text <- local({
  cache <- list()
  function(source_id) {
    if (!is.null(cache[[source_id]])) return(cache[[source_id]])
    s <- VV_SOURCES[VV_SOURCES$source_id == source_id, ]
    p <- here::here(s$archive_path)
    txt <- switch(s$kind, html = vv_html_text(p), pdf = vv_pdf_text(p), xlsx = vv_xlsx_text(p),
                  txt = paste(readLines(p, warn = FALSE, encoding = "UTF-8"), collapse = "\n"),
                  stop("[vv] no text reader for ", s$kind))
    cache[[source_id]] <<- txt
    txt
  }
})

vv_numbers <- function(txt) {
  n <- stringr::str_extract_all(txt, "[0-9][0-9,]*(\\.[0-9]+)?")[[1]]
  suppressWarnings(as.numeric(gsub(",", "", n)))
}

vv_norm_name <- function(x) {
  x <- toupper(x)
  x <- gsub("[^A-Z0-9 ]", " ", gsub("&", " AND ", x, fixed = TRUE))
  x <- stringr::str_squish(x)
  x <- gsub("^THE ", "", x)
  x <- gsub("( (INC|INCORPORATED|LLC|LLP|LP|CORP|CORPORATION|CO|COMPANY|LTD|PC|PLLC))+$", "", x)
  gsub(" ", "", x)
}

vv_sha_ok <- function(source_id) {
  s <- VV_SOURCES[VV_SOURCES$source_id == source_id, ]
  sha <- digest::digest(file = here::here(s$archive_path), algo = "sha256")
  man <- paste(readLines(here::here(s$manifest), warn = FALSE), collapse = "\n")
  list(sha = sha, ok = grepl(sha, man, fixed = TRUE))
}

# -- inputs --------------------------------------------------------------------------------

vv_cases <- function() readr::read_csv(here::here(VV_CASES), col_types = readr::cols(.default = "c"),
                                       na = "", progress = FALSE) %>%
  dplyr::mutate(amount = as.numeric(amount))
vv_hand_drops <- function() readr::read_csv(here::here(VV_HAND_DROPS), col_types = readr::cols(.default = "c"),
                                            na = "", progress = FALSE) %>%
  dplyr::mutate(amount = as.numeric(amount))

vv_fsrs <- function() {
  s <- usa_read("sub")
  tibble::tibble(
    prime_state = dplyr::if_else(s$prime_awardee_state_code == "",
                                 s$prime_award_primary_place_of_performance_state_code,
                                 s$prime_awardee_state_code),
    subaward_number = s$subaward_number, subaward_amount = as.numeric(s$subaward_amount),
    subawardee_name = s$subawardee_name, subawardee_uei = s$subawardee_uei,
    subawardee_parent_name = s$subawardee_parent_name,
    subawardee_address = s$subawardee_address_line_1, subawardee_city = s$subawardee_city_name,
    subawardee_state = s$subawardee_state_code,
    business_types = s$subawardee_business_types, description = s$subaward_description,
    cfda = s$prime_award_cfda_numbers_and_titles, action_date = s$subaward_action_date,
    sam_modified = s$subaward_sam_report_last_modified_date,
    permalink = s$usaspending_permalink)
}

vv_award_union_types <- function() {
  sf <- vf_state_files()
  purrr::map_dfr(names(sf), function(k) {
    d <- readr::read_csv(here::here(sf[[k]]), col_types = readr::cols(.default = "c"), progress = FALSE)
    tibble::tibble(state = d$state, name_key = vv_norm_name(d$awardee), recipient_type = d$recipient_type)
  }) %>% dplyr::distinct()
}

# -- the checks -----------------------------------------------------------------------------

vv_link_fsrs <- function(case, fsrs) {
  st <- fsrs[fsrs$prime_state == case$state, ]
  link <- dplyr::coalesce(case$fsrs_link, "")
  hit <- st[0, ]
  if (link == "SAME_RECORD") {
    hit <- st[st$subaward_number == case$fsrs_subaward_number &
                vv_norm_name(st$subawardee_name) == vv_norm_name(case$recipient_as_printed), ]
  } else if (link == "ID_OR_NAME") {
    hit <- st[st$subaward_number == case$fsrs_subaward_number, ]
    if (nrow(hit) == 0) hit <- st[vv_norm_name(st$subawardee_name) == vv_norm_name(case$recipient_as_printed), ]
  } else if (link == "NAME") {
    hit <- st[vv_norm_name(st$subawardee_name) == vv_norm_name(case$recipient_as_printed), ]
  }
  if (nrow(hit) > 0 && dplyr::n_distinct(hit$subawardee_uei) > 1)
    stop("[vv] ", case$case_id, ": the FSRS link resolves to more than one UEI", call. = FALSE)
  hit
}

# Is a case money this tracker already counts as HOSPITAL money? A strict bucket
# or a HOSPITAL summary call on the award-file row of the same recipient at the
# same amount, or a HOSPITAL component in summary_call_components.csv.
vv_hospital_money <- function(checked) {
  sf <- vf_state_files()
  u <- purrr::map_dfr(names(sf), function(k) {
    d <- readr::read_csv(here::here(sf[[k]]), col_types = readr::cols(.default = "c"), progress = FALSE)
    o <- function(c) if (c %in% names(d)) d[[c]] else rep(NA_character_, nrow(d))
    tibble::tibble(file_key = k, state = d$state, key = vv_norm_name(d$awardee),
                   amt = suppressWarnings(as.numeric(d$amount)),
                   ha = o("hospital_attribution"), sc = o("summary_hospital_call"))
  })
  comp <- readr::read_csv(here::here("data/reference/summary_call_components.csv"),
                          col_types = readr::cols(.default = "c"), progress = FALSE)
  purrr::map_dfr(seq_len(nrow(checked)), function(i) {
    c <- checked[i, ]; k <- vv_norm_name(c$recipient_as_printed)
    hit <- u %>% dplyr::filter(state == c$state, startsWith(key, k) | startsWith(k, key),
                               !is.na(amt), abs(amt - c$amount) < 0.01,
                               ha %in% c("NAMED_HOSPITAL", "POOL_NAMED_HOSPITALS", "POOL_UNNAMED_HOSPITALS") |
                                 sc %in% "HOSPITAL")
    ch <- comp %>% dplyr::filter(state == c$state, startsWith(vv_norm_name(awardee), k),
                                 abs(as.numeric(component_usd) - c$amount) < 0.01, call == "HOSPITAL")
    why <- c(if (nrow(hit) > 0) paste0(hit$file_key, " award file: hospital_attribution ", hit$ha,
                                       ", summary call ", hit$sc),
             if (nrow(ch) > 0) paste0("summary-call component ", ch$component_id, " called HOSPITAL"))
    tibble::tibble(case_id = c$case_id,
                   hospital_money = if (length(why) == 0) NA_character_ else paste(unique(why), collapse = "; "))
  })
}

vv_check_case <- function(case, fsrs, types) {
  src <- VV_SOURCES[VV_SOURCES$source_id == case$source_id, ]
  if (nrow(src) != 1) stop("[vv] ", case$case_id, ": unknown source ", case$source_id, call. = FALSE)
  fails <- character(0)
  cats <- strsplit(case$categories, ";", fixed = TRUE)[[1]]
  if (!all(cats %in% VV_CATEGORIES)) stop("[vv] ", case$case_id, ": bad category", call. = FALSE)
  if (!case$amount_type %in% VV_AMOUNT_TYPES) stop("[vv] ", case$case_id, ": bad amount_type", call. = FALSE)
  itype <- dplyr::coalesce(case$intermediary_type, "")
  if (("INTERMEDIARY" %in% cats) != (itype %in% VV_INTERMEDIARY_TYPES))
    stop("[vv] ", case$case_id, ": INTERMEDIARY needs exactly one intermediary_type, and only INTERMEDIARY may carry one", call. = FALSE)
  cat_drops <- character(0)

  # V1
  if (!src$source_class %in% VV_ADMISSIBLE) fails <- c(fails, "V1: source class not admissible")

  # source text for V2-V5
  link <- vv_link_fsrs(case, fsrs)
  if (src$kind == "fsrs") {
    if (nrow(link) != 1) stop("[vv] ", case$case_id, ": FSRS record not found exactly once", call. = FALSE)
    doc_txt <- paste(link$subawardee_name, link$description)
    tie_txt <- link$cfda
    amounts <- link$subaward_amount
    gap <- 0L
  } else {
    doc_txt <- vv_source_text(case$source_id)
    tie_txt <- doc_txt
    amounts <- vv_numbers(doc_txt)
    gap <- if (src$kind == "pdf") 40L else 0L
  }
  hay <- vv_norm_tokens(doc_txt)

  # V2 (with a separate tie source where the owner ruled one: it must say RHTP
  # AND link the case's own document)
  tie_id <- dplyr::coalesce(case$tie_source_id, "")
  if (tie_id != "") {
    ts <- VV_SOURCES[VV_SOURCES$source_id == tie_id, ]
    if (nrow(ts) != 1) stop("[vv] ", case$case_id, ": unknown tie source ", tie_id, call. = FALSE)
    tie_txt <- vv_source_text(tie_id)
    raw <- paste(readLines(here::here(ts$archive_path), warn = FALSE), collapse = " ")
    if (is.na(src$link_key) || !grepl(src$link_key, raw, fixed = TRUE))
      fails <- c(fails, "V2: the tie page does not link the case's document")
    if (!vv_sha_ok(tie_id)$ok) fails <- c(fails, "V8: tie source SHA-256 not in its manifest")
  }
  if (!stringr::str_detect(tie_txt, VV_TIE_RX)) fails <- c(fails, "V2: the document does not tie the money to RHTP")
  # V3
  if (is.na(case$amount) || !any(abs(amounts - case$amount) < 0.005, na.rm = TRUE))
    fails <- c(fails, "V3: amount not printed in the source")
  # V4
  segs <- strsplit(case$purpose_quote, " [...] ", fixed = TRUE)[[1]]
  seg_ok <- vapply(segs, function(q) vv_find_seq(vv_norm_tokens(q), hay, gap), logical(1))
  if (!all(seg_ok)) fails <- c(fails, "V4: purpose quote not found verbatim in the source")
  # V5
  if (!vv_find_seq(vv_norm_tokens(case$recipient_as_printed), hay, gap))
    fails <- c(fails, "V5: recipient name as printed not found in the source")
  uei <- if (nrow(link) > 0) link$subawardee_uei[1] else NA_character_
  parent <- NA_character_
  if (nrow(link) > 0) {
    p <- link$subawardee_parent_name[1]
    if (!is.na(p) && p != "" && !grepl("STATE OF|DEPARTMENT|AUTHORITY|DIVISION|^NA$", p, ignore.case = TRUE)) parent <- p
  }
  # V6
  addr_state <- if (nrow(link) > 0) link$subawardee_state[1] else NA_character_
  addr <- if (nrow(link) > 0) paste0(link$subawardee_city[1], ", ", link$subawardee_state[1]) else NA_character_
  if ("OUT_OF_STATE_VENDOR" %in% cats) {
    if (is.na(addr_state) || addr_state == case$state) {
      cats <- setdiff(cats, "OUT_OF_STATE_VENDOR")
      cat_drops <- c(cat_drops, "V6: no linked FSRS address outside the awarding state; OUT_OF_STATE_VENDOR removed")
    }
  }
  if (length(cats) == 0) fails <- c(fails, "V6: no category survives")
  # V7
  bt <- if (nrow(link) > 0) link$business_types[1] else NA_character_
  ty <- types$recipient_type[types$state == case$state & types$name_key == vv_norm_name(case$recipient_as_printed)]
  if (is.na(case$amount) || case$amount < VV_FLOOR) fails <- c(fails, "V7: under $1,000,000")
  hosp_name <- stringr::str_detect(case$recipient_as_printed, VF_HOSPITAL_NAME) &
    !stringr::str_detect(case$recipient_as_printed, regex("ASSOCIATION|NETWORK|RESEARCH AND EDUCATION|COOPERATIVE|PARTNERS", ignore_case = TRUE))
  if (isTRUE(grepl("HOSPITAL", bt, ignore.case = TRUE)) || "HOSPITAL_OR_SYSTEM" %in% ty || hosp_name)
    fails <- c(fails, "V7: a hospital or health system")
  state_agency <- (isTRUE(grepl("STATE GOVERNMENT", bt)) && !isTRUE(grepl("INSTITUTION OF HIGHER", bt))) ||
    "STATE_AGENCY" %in% ty
  if (state_agency) fails <- c(fails, "V7: a state agency of the awarding state")
  public <- isTRUE(grepl("LOCAL GOVERNMENT|STATE CONTROLLED INSTITUTION OF HIGHER", bt)) ||
    "LOCAL_GOVT_OR_PUBLIC_HEALTH" %in% ty
  public_basis <- dplyr::case_when(
    isTRUE(grepl("LOCAL GOVERNMENT", bt)) ~ paste0("FSRS business type: ", bt),
    isTRUE(grepl("STATE CONTROLLED INSTITUTION OF HIGHER", bt)) ~ paste0("FSRS business type: ", bt),
    "LOCAL_GOVT_OR_PUBLIC_HEALTH" %in% ty ~ "award file recipient_type LOCAL_GOVT_OR_PUBLIC_HEALTH",
    TRUE ~ NA_character_)
  # V8
  sh <- vv_sha_ok(case$source_id)
  if (!sh$ok) fails <- c(fails, "V8: archive SHA-256 not in its manifest")

  url <- if (src$kind == "fsrs") link$permalink[1] else src$url
  tibble::tibble(
    case_id = case$case_id, state = case$state, recipient_as_printed = case$recipient_as_printed,
    uei = uei, parent = parent,
    parent_basis = dplyr::if_else(is.na(parent), NA_character_, "FSRS subawardee_parent_name (from SAM)"),
    categories = paste(cats, collapse = ";"), public = public, public_basis = public_basis,
    amount = case$amount, amount_type = case$amount_type, purpose_quote = case$purpose_quote,
    source_class = src$source_class, source_title = src$title, source_url = url,
    archive_path = src$archive_path,
    archive_member = if (src$kind == "fsrs") paste0("Assistance_Subawards CSV, subaward_number '", link$subaward_number[1], "'") else NA_character_,
    archive_sha256 = sh$sha,
    source_date = if (src$kind == "fsrs") paste0("action ", link$action_date[1], "; SAM report modified ", substr(link$sam_modified[1], 1, 10)) else NA_character_,
    fsrs_address = addr, fsrs_business_types = bt,
    notes = case$notes,
    passed = length(fails) == 0,
    failed_tests = paste(fails, collapse = " | "),
    category_drops = paste(cat_drops, collapse = " | "),
    intermediary_type = dplyr::na_if(dplyr::coalesce(case$intermediary_type, ""), ""),
    tie_source = if (tie_id == "") NA_character_ else paste0(VV_SOURCES$title[VV_SOURCES$source_id == tie_id], " (",
                                                             VV_SOURCES$archive_path[VV_SOURCES$source_id == tie_id], ")"),
    v9_basis = dplyr::na_if(dplyr::coalesce(case$v9_basis, ""), "")
  )
}

vv_firm_key <- function(x) {
  k <- vv_norm_name(x)
  dplyr::case_when(
    grepl("^COMAGINE|^COMAGINEHEALTH", k) ~ "COMAGINE HEALTH",
    grepl("^GUIDEHOUSE", k) ~ "GUIDEHOUSE",
    grepl("UKHSCARECOLLABORATIVE", k) ~ "UKHS CARE COLLABORATIVE ASSOCIATION",
    grepl("^UTAHHOSPITALASSOCIATION", k) ~ "UTAH HOSPITAL ASSOCIATION",
    grepl("^VIRGINIAHEALTHCAREFOUNDATION", k) ~ "VIRGINIA HEALTH CARE FOUNDATION",
    grepl("^VIRGINIAHOSPITALRESEARCH", k) ~ "VIRGINIA HOSPITAL RESEARCH AND EDUCATION FOUNDATION (VHHA FOUNDATION)",
    grepl("^WYOMINGINNOVATIONPARTNERSHIP", k) ~ "WYOMING INNOVATION PARTNERSHIP",
    TRUE ~ toupper(stringr::str_squish(gsub("\\^", "", x))))
}

# -- the other tabs ---------------------------------------------------------------------------

vv_unnamed_lines <- function(verified) {
  l <- vf_cms_lines() %>%
    dplyr::filter(is.na(named_orgs) | named_orgs == "") %>%
    dplyr::mutate(amount = as.numeric(amount)) %>%
    dplyr::filter(stringr::str_detect(description_clean, VF_UNNAMED_RX),
                  !stringr::str_detect(description_clean, VF_UNNAMED_NOT_RX), amount > 0)
  same <- purrr::map_chr(seq_len(nrow(l)), function(i) {
    h <- verified %>% dplyr::filter(state == l$state[i], abs(amount - l$amount[i]) < 0.01)
    if (nrow(h) == 0) "" else paste0("Same state and amount as verified case ", paste(h$case_id, collapse = ", "),
                                     " (", paste(h$recipient_as_printed, collapse = ", "),
                                     "); a match of figures, not a statement by CMS")
  })
  l %>% dplyr::transmute(state, line_id, amount_obligated = amount, quote = description_clean,
                         initiative, as_of, same_figure_as_verified_case = same,
                         source = "CMS RHTP Obligated Funds Report, 10-14 edition",
                         archive_path = VF_CMS_PDF) %>%
    dplyr::arrange(state, dplyr::desc(amount_obligated))
}

vv_planned <- function() {
  vf <- readr::read_csv(here::here(VF_FLAGS_CSV), col_types = readr::cols(.default = "c"), progress = FALSE)
  a <- vf %>% dplyr::filter(source_type == "BUDGET_NARRATIVE") %>%
    dplyr::transmute(state, recipient, amount = as.numeric(amount),
                     amount_type = dplyr::if_else(is.na(amount), "plan (unpriced or shared)", "plan"),
                     purpose_quote, source = "State RHTP budget narrative", source_url, archive_path,
                     notes, from = paste0("vendor_flags.csv ", flag_id))
  nc <- readr::read_csv(here::here("data/reference/nc_year1_budget_plan.csv"),
                        col_types = readr::cols(.default = "c"), progress = FALSE)
  nc_amt <- as.numeric(gsub("[$,]", "", nc$budgeted_amount_text))
  dict_hit <- vf_match(nc$organization, vf_dictionary())$matched
  b <- nc[(dict_hit | grepl("vendor|contractor|consult", paste(nc$contract_title, nc$program_title), ignore.case = TRUE)) &
            nc_amt >= VV_FLOOR, ] %>%
    dplyr::transmute(state, recipient = organization, amount = as.numeric(gsub("[$,]", "", budgeted_amount_text)),
                     amount_type = "plan", purpose_quote = description,
                     source = source_document_title, source_url, archive_path = source_archive_path,
                     notes = paste0(contract_title, " (", workstream, "). 'Budgeted Amount' on NCDHHS's Year 1 project list; owner ruling session 116: a budget plan, not an award."),
                     from = paste0("nc_year1_budget_plan.csv row ", nc$row_no[dict_hit | grepl("vendor|contractor|consult", paste(nc$contract_title, nc$program_title), ignore.case = TRUE)][nc_amt[dict_hit | grepl("vendor|contractor|consult", paste(nc$contract_title, nc$program_title), ignore.case = TRUE)] >= VV_FLOOR]))
  dplyr::bind_rows(a, b) %>%
    dplyr::mutate(label = "PLANNED - NOT AWARDED. A budget line; never added to any verified figure.") %>%
    dplyr::arrange(dplyr::desc(amount))
}

# Every session-116b flag row gets a disposition: a verified case, a hand drop,
# or a machine drop with its test. A >= $1M sourced row nobody read stops the build.
vv_flag_dispositions <- function(checked, hand) {
  vf <- readr::read_csv(here::here(VF_FLAGS_CSV), col_types = readr::cols(.default = "c"), progress = FALSE) %>%
    dplyr::mutate(amount = as.numeric(amount), is_lead = is_lead == "TRUE")
  key <- function(st, nm) paste(st, vv_norm_name(nm))
  out <- purrr::map_dfr(seq_len(nrow(vf)), function(i) {
    r <- vf[i, ]
    nk <- substr(vv_norm_name(r$canonical_name), 1, 6)
    hc <- checked %>% dplyr::filter(state == r$state, !is.na(r$amount), abs(amount - r$amount) < 0.01,
                                    substr(vv_norm_name(recipient_as_printed), 1, 6) == nk |
                                      substr(vv_norm_name(recipient_as_printed), 1, 6) == substr(vv_norm_name(r$recipient), 1, 6))
    hd <- hand %>% dplyr::filter(state == r$state,
                                 (!is.na(amount) & !is.na(r$amount) & abs(amount - r$amount) < 0.01) |
                                   stringr::str_detect(vv_norm_name(recipient_as_printed), stringr::fixed(substr(vv_norm_name(r$canonical_name), 1, 8))))
    disp <- dplyr::case_when(
      nrow(hc) > 0 ~ paste0("CASE ", paste(hc$case_id, collapse = ",")),
      r$is_lead ~ "MACHINE DROP V1: an RCJ lead, not a primary source",
      r$source_type == "BUDGET_NARRATIVE" ~ "MOVED TO 'Planned (not awarded)' (V1: a budget plan is not an award)",
      r$source_type == "STATE_ANNUAL_REPORT" & nrow(hd) > 0 ~ paste0("HAND DROP ", paste(hd$drop_id, collapse = ",")),
      is.na(r$amount) ~ "MACHINE DROP V3: unpriced (a joint or unpublished amount)",
      !is.na(r$amount) & r$amount < VV_FLOOR ~ "MACHINE DROP V7: under $1,000,000",
      nrow(hd) > 0 ~ paste0("HAND DROP ", paste(hd$drop_id, collapse = ",")),
      TRUE ~ "UNREAD")
    tibble::tibble(flag_id = r$flag_id, state = r$state, recipient = r$recipient, amount = r$amount,
                   amount_type = r$amount_type, source_type = r$source_type, disposition = disp)
  })
  unread <- out %>% dplyr::filter(disposition == "UNREAD")
  if (nrow(unread) > 0)
    stop("[vv] session-116b flags with no disposition: ",
         paste(unread$flag_id, unread$state, unread$recipient, collapse = "; "), call. = FALSE)
  out
}

# The widened sweep: every FSRS subaward >= $1M to a non-hospital whose address
# is outside the awarding state must be a case or a hand drop.
vv_fsrs_oos_sweep <- function(fsrs, checked, hand) {
  oos <- fsrs %>%
    dplyr::filter(subaward_amount >= VV_FLOOR, subawardee_state != prime_state,
                  !grepl("HOSPITAL", business_types, ignore.case = TRUE),
                  !stringr::str_detect(subawardee_name, VF_HOSPITAL_NAME))
  miss <- oos %>% dplyr::filter(!purrr::map2_lgl(prime_state, subaward_amount, function(st, a)
    any(checked$state == st & abs(checked$amount - a) < 0.01) |
      any(hand$state == st & !is.na(hand$amount) & abs(hand$amount - a) < 0.01)))
  if (nrow(miss) > 0)
    stop("[vv] out-of-state FSRS subawards >= $1M nobody read: ",
         paste(miss$prime_state, miss$subawardee_name, miss$subaward_amount, collapse = "; "), call. = FALSE)
  invisible(oos)
}

# -- build ----------------------------------------------------------------------------------------

vv_build <- function(write = TRUE) {
  cases <- vv_cases()
  if (anyDuplicated(cases$case_id)) stop("[vv] duplicate case_id", call. = FALSE)
  hand <- vv_hand_drops()
  fsrs <- vv_fsrs()
  types <- vv_award_union_types()
  checked <- purrr::map_dfr(seq_len(nrow(cases)), function(i) vv_check_case(cases[i, ], fsrs, types))
  live_path <- here::here(VV_LIVE_CSV())
  if (file.exists(live_path)) {
    live <- readr::read_csv(live_path, col_types = readr::cols(.default = "c"), progress = FALSE)
    checked <- checked %>% dplyr::left_join(live %>% dplyr::select(case_id, live_status, live_checked_utc), by = "case_id")
  } else {
    checked$live_status <- NA_character_; checked$live_checked_utc <- NA_character_
  }
  ind_drops <- checked[0, ]
  if (file.exists(here::here(VV_INDEPENDENT))) {
    ind <- readr::read_csv(here::here(VV_INDEPENDENT), col_types = readr::cols(.default = "c"), progress = FALSE)
    miss <- setdiff(checked$case_id[checked$passed], ind$case_id)
    if (length(miss) > 0) stop("[vv] the independent check does not cover: ", paste(miss, collapse = ", "), call. = FALSE)
    if (file.exists(here::here(VV_INDEPENDENT_R2))) {
      r2 <- readr::read_csv(here::here(VV_INDEPENDENT_R2), col_types = readr::cols(.default = "c"), progress = FALSE)
      # A round-1 DROP stands unless an owner ruling answered its reason
      # (VV_R1_SUPERSEDED). Elsewhere a DROP in EITHER round drops the case:
      # two verifiers disagreeing is not a pass.
      r2 <- r2 %>% dplyr::filter(case_id %in% checked$case_id)
      r1_drop <- ind$case_id[ind$verdict == "DROP" & !ind$case_id %in% VV_R1_SUPERSEDED]
      ind <- dplyr::bind_rows(
        ind %>% dplyr::filter(!case_id %in% r2$case_id | case_id %in% r1_drop) %>% dplyr::mutate(round = "1"),
        r2 %>% dplyr::filter(!case_id %in% r1_drop) %>% dplyr::mutate(round = "2"))
    } else {
      ind$round <- "1"
    }
    ind <- ind %>% dplyr::filter(case_id %in% checked$case_id)
    dd <- ind %>% dplyr::filter(verdict == "DROP")
    ind_drops <- checked %>% dplyr::filter(case_id %in% dd$case_id) %>%
      dplyr::left_join(dd %>% dplyr::select(case_id, ind_reason = reason, dplyr::starts_with("V")), by = "case_id")
    checked$passed[checked$case_id %in% dd$case_id] <- FALSE
    checked$independent_check <- dplyr::if_else(checked$case_id %in% ind$case_id[ind$verdict == "KEEP"],
                                                paste0("KEEP (round ", ind$round[match(checked$case_id, ind$case_id)], ")"),
                                                NA_character_)
  } else {
    checked$independent_check <- NA_character_
  }
  hm <- vv_hospital_money(checked)
  checked <- checked %>% dplyr::left_join(hm, by = "case_id")
  verified_all <- checked %>% dplyr::filter(passed) %>%
    dplyr::mutate(firm = vv_firm_key(recipient_as_printed)) %>%
    dplyr::arrange(dplyr::desc(amount))
  pass_through <- verified_all %>%
    dplyr::filter(!is.na(hospital_money) | intermediary_type %in% "PASS_THROUGH_TO_PROVIDERS") %>%
    dplyr::mutate(why_here = dplyr::case_when(
      !is.na(hospital_money) ~ paste0("Counted as hospital money by this tracker: ", hospital_money),
      TRUE ~ "PASS_THROUGH_TO_PROVIDERS: the quote says the money is paid on to care providers"))
  verified <- checked %>% dplyr::filter(passed, !case_id %in% pass_through$case_id) %>%
    dplyr::mutate(firm = vv_firm_key(recipient_as_printed)) %>%
    dplyr::arrange(dplyr::desc(amount))
  ind_dropped <- if (nrow(ind_drops) == 0) NULL else ind_drops %>%
    dplyr::mutate(ft = purrr::pmap_chr(dplyr::select(ind_drops, dplyr::matches("^V[0-9]$")), function(...) {
      x <- c(...); paste(names(x)[x %in% "FAIL"], collapse = ",") })) %>%
    dplyr::transmute(drop_id = case_id, state, recipient_as_printed, categories_considered = categories,
                     amount, amount_type, source_pointer = paste(source_title, dplyr::coalesce(archive_member, "")),
                     failed_test = ft, reason = ind_reason, by = "independent check (Task 4, latest round)")
  machine_drops <- checked %>% dplyr::filter(!passed, !case_id %in% ind_drops$case_id) %>%
    dplyr::transmute(drop_id = case_id, state, recipient_as_printed, categories_considered = categories,
                     amount, amount_type, source_pointer = paste(source_title, archive_member),
                     failed_test = sub(":.*", "", failed_tests), reason = failed_tests, by = "machine (R/09c)")
  cat_drops <- checked %>% dplyr::filter(passed | case_id %in% ind_drops$case_id, category_drops != "") %>%
    dplyr::transmute(drop_id = paste0(case_id, "-cat"), state, recipient_as_printed,
                     categories_considered = "OUT_OF_STATE_VENDOR", amount, amount_type,
                     source_pointer = source_title, failed_test = "V6",
                     reason = paste0(category_drops, "; the case itself passes as ", categories),
                     by = "machine (R/09c)")
  flags <- vv_flag_dispositions(checked, hand)
  vv_fsrs_oos_sweep(fsrs, checked, hand)
  dropped <- dplyr::bind_rows(
    hand %>% dplyr::mutate(by = "hand (config/verified_vendor_hand_drops.csv)"),
    machine_drops, ind_dropped, cat_drops,
    flags %>% dplyr::filter(grepl("^MACHINE DROP", disposition)) %>%
      dplyr::transmute(drop_id = flag_id, state, recipient_as_printed = recipient,
                       categories_considered = "(session 116b flag)", amount, amount_type,
                       source_pointer = paste0("vendor_flags.csv ", flag_id, " (", source_type, ")"),
                       failed_test = stringr::str_extract(disposition, "V[0-9]"),
                       reason = sub("^MACHINE DROP V[0-9]: ", "", disposition),
                       by = "machine (R/09c, 116b flag sweep)"))
  unnamed <- vv_unnamed_lines(verified)
  planned <- vv_planned()
  if (write) {
    readr::write_csv(verified, here::here(VV_LIST_CSV), na = "")
    readr::write_csv(pass_through, here::here(VV_PASS_THROUGH_CSV), na = "")
    readr::write_csv(dropped, here::here(VV_DROPPED_CSV), na = "")
    readr::write_csv(unnamed, here::here(VV_UNNAMED_CSV), na = "")
    readr::write_csv(planned, here::here(VV_PLANNED_CSV), na = "")
  }
  invisible(list(verified = verified, pass_through = pass_through, dropped = dropped, unnamed = unnamed, planned = planned,
                 flags = flags, checked = checked))
}

# -- live check -------------------------------------------------------------------------------------

vv_live <- function(as_of = VV_AS_OF) {
  cases <- vv_cases()
  fsrs <- vv_fsrs()
  now <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  # A fresh handle per URL keeps a host's session cookie (Idaho's WebLink
  # redirects through a cookie check). The live bytes are compared with the
  # archive: "LIVE, same bytes" or "LIVE, bytes differ" (a page that moved on,
  # or a wrapper page). A 200 alone is not reported as the document.
  # A fresh handle per URL keeps a host's session cookie. The live bytes are
  # compared with the archive. Where they differ, each case's amount, quote and
  # name are re-tested against the LIVE text; a 200 that serves an HTML wrapper
  # in place of an archived PDF/xlsx is reported as NOT CONFIRMED.
  fetch_live <- function(url, archive_path, kind) {
    h <- httr::handle(sub("^(https?://[^/]+).*", "\\1", url))
    r <- tryCatch(httr::GET(url, handle = h, httr::user_agent(USA_AGENT), httr::timeout(60)),
                  error = function(e) NULL)
    if (is.null(r)) return(list(status = "NOT REACHED (connection error)", text = NULL))
    code <- httr::status_code(r)
    if (code != 200) return(list(status = paste0("NOT LIVE (HTTP ", code, ")"), text = NULL))
    raw <- httr::content(r, "raw")
    ct <- httr::headers(r)[["content-type"]] %||% "?"
    if (kind %in% c("pdf", "xlsx") && grepl("html", ct)) {
      # Idaho's WebLink sets a session cookie on the first answer and serves the
      # file to the second request on the same handle.
      r2 <- tryCatch(httr::GET(url, handle = h, httr::user_agent(USA_AGENT), httr::timeout(60)),
                     error = function(e) NULL)
      if (!is.null(r2) && httr::status_code(r2) == 200) {
        raw <- httr::content(r2, "raw"); ct <- httr::headers(r2)[["content-type"]] %||% "?"
      }
    }
    same <- identical(digest::digest(raw, algo = "sha256", serialize = FALSE),
                      digest::digest(file = here::here(archive_path), algo = "sha256"))
    if (same) return(list(status = paste0("LIVE (HTTP 200; same bytes as the archive)"), text = NULL))
    if (kind %in% c("pdf", "xlsx") && grepl("html", ct))
      return(list(status = paste0("NOT CONFIRMED (HTTP 200 but a ", length(raw),
                                  "-byte HTML page, not the archived ", kind, ")"), text = NULL))
    tf <- tempfile(fileext = paste0(".", kind)); writeBin(raw, tf)
    txt <- tryCatch(switch(kind, html = vv_html_text(tf), pdf = vv_pdf_text(tf), xlsx = vv_xlsx_text(tf),
                           txt = paste(readLines(tf, warn = FALSE, encoding = "UTF-8"), collapse = "\n")),
                    error = function(e) NULL)
    list(status = "LIVE (HTTP 200; bytes differ from the archive", text = txt)
  }
  recheck <- function(case, kind, txt) {
    if (is.null(txt)) return("")
    hay <- vv_norm_tokens(txt); gap <- if (kind == "pdf") 40L else 0L
    segs <- strsplit(case$purpose_quote, " [...] ", fixed = TRUE)[[1]]
    ok_q <- all(vapply(segs, function(q) vv_find_seq(vv_norm_tokens(q), hay, gap), logical(1)))
    ok_n <- vv_find_seq(vv_norm_tokens(case$recipient_as_printed), hay, gap)
    ok_a <- any(abs(vv_numbers(txt) - case$amount) < 0.005, na.rm = TRUE)
    if (ok_q && ok_n && ok_a) "; this case's name, amount and quote are all still on the live page)"
    else paste0("; NOT all still on the live page: name ", ok_n, ", amount ", ok_a, ", quote ", ok_q, ")")
  }
  sub_status <- function(permalink, number) {
    aid <- sub(".*/award/([^/]+)/?$", "\\1", permalink)
    for (pg in 1:20) {
      r <- tryCatch(httr::POST("https://api.usaspending.gov/api/v2/subawards/", httr::user_agent(USA_AGENT),
                               httr::timeout(60), encode = "json",
                               body = list(award_id = aid, limit = 100, page = pg)), error = function(e) NULL)
      if (is.null(r) || httr::status_code(r) != 200) return(paste0("NOT REACHED (USAspending API ", if (is.null(r)) "error" else httr::status_code(r), ")"))
      j <- httr::content(r, "parsed")
      nums <- vapply(j$results, function(x) as.character(x$subaward_number %||% ""), character(1))
      if (number %in% nums) return(paste0("LIVE (subaward listed under ", aid, " on the USAspending API)"))
      if (!isTRUE(j$page_metadata$hasNext)) break
    }
    paste0("NOT LIVE (subaward not listed under ", aid, ")")
  }
  srcs <- VV_SOURCES[!is.na(VV_SOURCES$url), ]
  # The Google Doc's human URL serves an HTML editor; its archived bytes are the
  # txt export, so the export is what is compared.
  check_url <- dplyr::if_else(srcs$source_id == "S_UT_GDOC", paste0(srcs$url, "export?format=txt"), srcs$url)
  live <- setNames(purrr::pmap(list(check_url, srcs$archive_path, srcs$kind), fetch_live), srcs$source_id)
  out <- purrr::map_dfr(seq_len(nrow(cases)), function(i) {
    c <- cases[i, ]
    src <- VV_SOURCES[VV_SOURCES$source_id == c$source_id, ]
    if (src$kind == "fsrs") {
      l <- vv_link_fsrs(c, fsrs)
      st <- sub_status(l$permalink[1], l$subaward_number[1]); u <- l$permalink[1]
    } else {
      u <- src$url; lv <- live[[src$source_id]]
      st <- paste0(lv$status, recheck(c, src$kind, lv$text))
    }
    tibble::tibble(case_id = c$case_id, source_url = u, live_status = st, live_checked_utc = now)
  })
  readr::write_csv(out, here::here(VV_LIVE_CSV(as_of)), na = "")
  out
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# -- xlsx ----------------------------------------------------------------------------------------------

VV_METHOD <- c(
  "What this list is",
  "Large Rural Health Transformation Program (RHTP) sums going to consultants, intermediaries and out-of-state vendors, each one checked against the archived primary source. Internal use only. It is a set of verified examples, not a census of vendor spending.",
  "",
  "Categories (hospitals and health systems are never listed)",
  "CONSULTANT: consulting, advisory or professional services (planning, analysis, evaluation, project management, implementation support, staff augmentation). The category follows from the purpose quote, so a foundation paid for 'consulting, analytics, and decision support' is listed as a CONSULTANT case.",
  "INTERMEDIARY: an entity paid to administer, re-grant or pass money to others: grant administrators, third-party administrators, fiscal agents, hub leads (including MCOs acting as hub leads). PUBLIC marks a local government or public university, from the FSRS business type or this repository's award file.",
  "OUT_OF_STATE_VENDOR: a non-hospital organisation whose registered address (from the state's own FSRS filing) is outside the awarding state.",
  "INTERMEDIARY is split by where the money goes, read from the purpose quote: PASS_THROUGH_TO_PROVIDERS (the quote says the money is paid on to hospitals, clinics, FQHCs or other care providers); ADMINISTERS_ONLY (fiscal agent, third-party administrator, award management, with no statement that it passes to providers); NON_PROVIDER_RECIPIENTS (the money goes on to companies, startups, a university or an association foundation).",
  "The main list keeps CONSULTANT, ADMINISTERS_ONLY, NON_PROVIDER_RECIPIENTS and OUT_OF_STATE_VENDOR. Every PASS_THROUGH_TO_PROVIDERS case, and every case this tracker already counts as hospital money (a strict hospital bucket or a HOSPITAL summary call on the same recipient and amount), is on the 'Pass-through to providers' tab instead.",
  "",
  "The nine tests. A case that fails any test is dropped, not caveated.",
  "V1 Primary source: a state award list, executed contract or contract register, the state's FSRS/FFATA filing, or CMS's obligation report. Press releases, RCJ, annual reports and budget plans fail. Budget plans appear only on the 'Planned (not awarded)' tab.",
  "V2 RHTP tie: the document itself says Rural Health Transformation, RHTP, or Assistance Listing 93.798. Owner ruling: Idaho's awardee sheet is tied by its publication on DHW's Rural Health Transformation funding page under 'Closed and awarded funding opportunities' (archived; the page must link the sheet), the same source this tracker's Idaho hospital rows rest on.",
  "V3 Amount: exactly as printed, with one amount type: award (executed), intent (announced, not executed), obligation (CMS's report of the state's self-reported obligation), or contract maximum (an executed contract's amount). Types are never added together.",
  "V4 Purpose: a verbatim quote from the same source saying what the money is for, and the category must follow from it. A programme name or initiative number alone fails. Segments joined by [...] are each verbatim.",
  "V5 Identity: the recipient's name as printed. UEI only where the state's FSRS filing carries the same record, the same identifier, or the same legal name. Parent company only where a registry or the source states it (none did).",
  "V6 Out-of-state: the FSRS registered address is outside the awarding state. General knowledge alone fails; the category is then removed, and the case survives only if another category passes.",
  "V7 Threshold and scope: $1,000,000 or more; not a hospital or health system; not a state agency of the awarding state (FSRS 'state government', other than a state university, or a state agency in this repository's award files).",
  "V8 Archived: the source is in the repository and its SHA-256 matches the manifest written when it was fetched. Whether the URL is still live on the check date is recorded separately.",
  "V9 Not delivering in-state care: an out-of-state organisation whose source, or its own documents, says the money funds its own operations inside the state (stores, campus, in-state staff) is dropped from OUT_OF_STATE_VENDOR. Checked against the location documents for Guidehouse (New Mexico's center: HCA does not require an in-state office; kept) and Thomas Jefferson University (a Delaware campus in Newark; dropped).",
  "",
  "How it was checked",
  "1. Candidates were collected from the session-116b flag file, every FSRS subaward of $1M or more, every award file and contract register in the repository, the 10-14 CMS obligation report, state budget narratives, and a web search for RHTP contracts naming the large consulting firms.",
  "2. A person read each candidate against its source and either wrote it up as a case (config/verified_vendor_cases.csv) or dropped it with the failed test (config/verified_vendor_hand_drops.csv).",
  "3. R/09c_verified_vendor_list.R re-reads every archived source and re-checks each case field by field: the amount, the quote, the name, the RHTP tie, the FSRS address and business type, and the SHA-256. Any failure drops the case.",
  "4. A separate agent that had not seen steps 1-3 re-opened every archived source and re-checked V1-V9 for every passing case (see the session note for the agreement rate).",
  "",
  "Limits",
  "FFATA excludes procurement contracts (2 CFR 170), and 19 states file no FFATA subawards at all, so most state consulting contracts are invisible here. The 'Unnamed contractor money' tab shows CMS obligation lines for contractors that name no firm; those totals are never attributed to a firm. Intents and obligations are not awards. Figures by firm are split by amount type and never summed across types."
)

vv_xlsx <- function(as_of = VV_AS_OF) {
  b <- vv_build(write = FALSE)
  v <- b$verified
  if (any(is.na(v$live_status))) stop("[vv] run --live before --xlsx", call. = FALSE)
  tab1 <- v %>% dplyr::transmute(
    Rank = dplyr::row_number(), State = state, `Recipient (as printed)` = recipient_as_printed,
    UEI = uei, `Parent (verified)` = parent, Categories = gsub(";", ", ", categories),
    `Intermediary type` = intermediary_type,
    PUBLIC = dplyr::if_else(public, "PUBLIC", ""), Amount = amount, `Amount type` = amount_type,
    `Purpose (verbatim quote)` = purpose_quote, `Source title` = source_title, `Source class` = source_class,
    URL = source_url, `Archive path` = archive_path, `Archive record` = archive_member,
    `Archive SHA-256` = archive_sha256, `Source date` = source_date,
    `FSRS registered address` = fsrs_address, `Live check` = live_status, `Live check (UTC)` = live_checked_utc,
    `Independent check` = independent_check, `RHTP tie page (V2)` = tie_source, `V9 location check` = v9_basis,
    Notes = notes, `Case ID` = case_id)
  by_firm <- v %>% dplyr::group_by(Firm = firm, `Amount type` = amount_type) %>%
    dplyr::summarise(Cases = dplyr::n(), Total = sum(amount), States = paste(sort(unique(state)), collapse = " "),
                     Categories = paste(sort(unique(unlist(strsplit(categories, ";")))), collapse = ", "),
                     `Case IDs` = paste(case_id, collapse = ", "), .groups = "drop") %>%
    dplyr::arrange(Firm, `Amount type`)
  firm_order <- by_firm %>% dplyr::group_by(Firm) %>% dplyr::summarise(m = max(Total)) %>% dplyr::arrange(dplyr::desc(m))
  by_firm <- by_firm %>% dplyr::mutate(Firm = factor(Firm, firm_order$Firm)) %>% dplyr::arrange(Firm, dplyr::desc(Total)) %>%
    dplyr::mutate(Firm = as.character(Firm))
  un_lines <- b$unnamed
  un_state <- un_lines %>% dplyr::group_by(State = state) %>%
    dplyr::summarise(Lines = dplyr::n(), `Obligated, no firm named` = sum(amount_obligated), .groups = "drop") %>%
    dplyr::arrange(dplyr::desc(`Obligated, no firm named`))
  planned <- b$planned
  dropped <- b$dropped %>% dplyr::arrange(failed_test, dplyr::desc(amount))

  wb <- openxlsx::createWorkbook()
  hs <- openxlsx::createStyle(textDecoration = "bold", fgFill = "#DCE6F1", wrapText = TRUE, valign = "top")
  money <- openxlsx::createStyle(numFmt = "$#,##0.00")
  wrap <- openxlsx::createStyle(wrapText = TRUE, valign = "top")
  add <- function(name, df, money_cols = character(0), note = NULL, widths = NULL) {
    openxlsx::addWorksheet(wb, name)
    r0 <- 1
    if (!is.null(note)) { openxlsx::writeData(wb, name, note, startRow = 1); r0 <- length(note) + 2 }
    openxlsx::writeData(wb, name, df, startRow = r0, headerStyle = hs)
    for (mc in money_cols) openxlsx::addStyle(wb, name, money, rows = (r0 + 1):(r0 + max(1, nrow(df))),
                                             cols = which(names(df) == mc), gridExpand = TRUE)
    openxlsx::freezePane(wb, name, firstActiveRow = r0 + 1)
    openxlsx::setColWidths(wb, name, cols = seq_along(df), widths = widths %||% "auto")
  }
  add("Verified list", tab1, "Amount",
      note = c(paste0("Verified list, ", as_of, ". ", nrow(tab1), " cases passed V1-V9. Ranked by amount; amount types differ (award, intent, obligation, contract maximum) and are never added together."),
               "Internal use only. See 'Method'."),
      widths = c(6, 6, 40, 15, 14, 34, 26, 9, 16, 15, 80, 50, 22, 50, 50, 30, 20, 26, 22, 40, 20, 16, 50, 50, 60, 8))
  pt <- b$pass_through %>% dplyr::transmute(
    State = state, `Recipient (as printed)` = recipient_as_printed, UEI = uei,
    `Intermediary type` = intermediary_type, Amount = amount, `Amount type` = amount_type,
    `Why it is on this tab` = why_here, `Purpose (verbatim quote)` = purpose_quote,
    `Source title` = source_title, URL = source_url, `Archive path` = archive_path,
    `Archive record` = archive_member, `Live check` = live_status,
    `Independent check` = independent_check, `Case ID` = case_id)
  add("Pass-through to providers", pt, "Amount",
      note = c(paste0("Verified intermediary cases whose money reaches care providers. ", nrow(pt),
                      " cases passed V1-V9. They are NOT on the main list: either the purpose quote says the money is paid on to hospitals, clinics, FQHCs or other care providers, or this tracker already counts the money as hospital money (a strict hospital bucket or a HOSPITAL summary call)."),
               "Amount types differ and are never added together."),
      widths = c(6, 40, 15, 26, 16, 15, 60, 80, 50, 50, 50, 30, 40, 16, 8))
  add("By firm", by_firm, "Total",
      note = "Verified cases only, grouped by firm and amount type. A firm's rows of different types are never added.",
      widths = c(48, 16, 7, 18, 14, 34, 30))
  add("Unnamed contractor money", un_state, "Obligated, no firm named",
      note = c("CMS RHTP Obligated Funds Report (10-14 edition, as of 2026-07-31): obligation lines for contractors, consultants or administrators that NAME NO FIRM. Totals by state; never attributed to any firm.",
               "Line-level quotes are in the second table below."),
      widths = c(10, 8, 22))
  openxlsx::writeData(wb, "Unnamed contractor money",
                      un_lines %>% dplyr::transmute(State = state, `Line ID` = line_id, Obligated = amount_obligated,
                                                    `Quote (CMS's words)` = quote,
                                                    `Same figure as a verified case` = same_figure_as_verified_case),
                      startRow = nrow(un_state) + 6, headerStyle = hs)
  openxlsx::addStyle(wb, "Unnamed contractor money", money, rows = (nrow(un_state) + 7):(nrow(un_state) + 7 + nrow(un_lines)),
                     cols = 3, gridExpand = TRUE)
  openxlsx::setColWidths(wb, "Unnamed contractor money", cols = 1:5, widths = c(10, 16, 22, 110, 60))
  add("Planned (not awarded)", planned %>% dplyr::transmute(State = state, Recipient = recipient, Amount = amount,
                                                           `Amount type` = amount_type, `Purpose (quote)` = purpose_quote,
                                                           Source = source, URL = source_url, `Archive path` = archive_path,
                                                           Notes = notes, Label = label),
      "Amount", note = "PLANNED, NOT AWARDED. Budget-plan lines naming a firm. These fail V1 and are NOT part of the verified list. Never add them to it.",
      widths = c(6, 36, 16, 22, 80, 40, 40, 40, 70, 40))
  add("Dropped", dropped %>% dplyr::transmute(ID = drop_id, State = state, Recipient = recipient_as_printed,
                                            `Category considered` = categories_considered, Amount = amount,
                                            `Amount type` = amount_type, `Source` = source_pointer,
                                            `Failed test` = failed_test, Reason = reason, `Dropped by` = by),
      "Amount", note = "Every candidate that failed a test, with the test and the reason. A row ending '-cat' is a category removed from a case that still passes.",
      widths = c(10, 6, 44, 24, 16, 16, 50, 9, 90, 30))
  method <- VV_METHOD
  if (file.exists(here::here(VV_INDEPENDENT))) {
    ind <- readr::read_csv(here::here(VV_INDEPENDENT), col_types = readr::cols(.default = "c"), progress = FALSE)
    fld <- ind %>% dplyr::select(dplyr::matches("^V[0-9]$")) %>% as.matrix()
    if (file.exists(here::here(VV_INDEPENDENT_R2))) {
      r2 <- readr::read_csv(here::here(VV_INDEPENDENT_R2), col_types = readr::cols(.default = "c"), progress = FALSE)
      f2 <- r2 %>% dplyr::select(dplyr::matches("^V[0-9]$")) %>% as.matrix()
      method <- c(method, "", "Independent check, round 2 (the changed cases, after the owner's rulings)",
                  paste0(nrow(r2), " cases re-checked; ", sum(r2$verdict == "KEEP"), " kept and ", sum(r2$verdict == "DROP"),
                         " dropped. Test-level agreement: ", sum(f2 %in% "PASS"), " PASS of ", sum(!is.na(f2)),
                         " applicable results. Intermediary type agreed on ", sum(grepl("^AGREE", r2$intermediary_type_check)),
                         " of ", sum(!is.na(r2$intermediary_type_check) & r2$intermediary_type_check != "NA"), " intermediary cases."))
    }
    method <- c(method, "", "Independent check, round 1 (all 57 original cases)",
                paste0(nrow(ind), " cases re-checked; ", sum(ind$verdict == "KEEP"), " kept and ",
                       sum(ind$verdict == "DROP"), " dropped: case-level agreement ",
                       sprintf("%.1f%%", 100 * mean(ind$verdict == "KEEP")), ". Test-level agreement: ", sum(fld %in% "PASS"), " PASS of ", sum(!is.na(fld)),
                       " applicable test results (", sprintf("%.1f%%", 100 * mean(fld[!is.na(fld)] == "PASS")), ").",
                       " Every case it dropped is on the 'Dropped' tab with its reason."))
  }
  openxlsx::addWorksheet(wb, "Method")
  openxlsx::writeData(wb, "Method", tibble::tibble(Method = method), headerStyle = hs)
  openxlsx::addStyle(wb, "Method", wrap, rows = 2:(length(method) + 1), cols = 1)
  openxlsx::setColWidths(wb, "Method", cols = 1, widths = 150)
  openxlsx::saveWorkbook(wb, VV_XLSX(as_of), overwrite = TRUE)
  invisible(VV_XLSX(as_of))
}

vv_report <- function() {
  b <- vv_build(write = FALSE)
  v <- b$verified
  cat("Verified cases:", nrow(v), "\n")
  print(v %>% dplyr::select(case_id, state, recipient_as_printed, categories, amount, amount_type), n = 100, width = 200)
  cat("\nBy amount type:\n")
  print(v %>% dplyr::count(amount_type, wt = amount, name = "total") %>% dplyr::left_join(v %>% dplyr::count(amount_type), by = "amount_type"))
  cat("\nDropped:", nrow(b$dropped), "\n")
  print(b$dropped %>% dplyr::count(failed_test, by))
  cat("\nUnnamed contractor lines:", nrow(b$unnamed), " total obligated $", format(sum(b$unnamed$amount_obligated), big.mark = ","), "\n")
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--build" %in% args) { b <- vv_build(); cat("[vv] verified", nrow(b$verified), "dropped", nrow(b$dropped), "\n") }
  if ("--live" %in% args) print(vv_live())
  if ("--xlsx" %in% args) cat("[vv] wrote", vv_xlsx(), "\n")
  if ("--report" %in% args) vv_report()
}
