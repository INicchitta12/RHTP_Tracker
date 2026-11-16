# R/03cu_cms_fy2027_allotments.R -- CMS's FY2027 (Year 2) awards, all 50 states
# (session 117).
#
# OWNER RULE (session 116, Year 2 safeguards): cms_fy2027_allotments.csv stays
# empty until CMS publishes EVERY state's FY2027 figure, and is then filled all
# 50 rows at once, PARSED from the archived CMS page, never transcribed.
#
# CMS did so on 2026-11-09: the press release "Trump Administration Announces
# $10 Billion in Second Year of Rural Health Transformation Awards to All 50
# States" carries a table headed "Year 2 Rural Health Transformation Awards"
# with columns "State" and "FY 2027 Award", one row per state. This file
# archives that page under data/raw/cms/<fetch date>/ with a SHA-256 manifest,
# parses the table from the archive, and writes the reference file.
#
# WHAT THE FIGURE IS. Tier 1: a CMS award to a state (§0.2), Budget Period 2.
# It is never added to a Year 1 figure, never compared with a Year 1 award
# total, and nothing in this file extracts any Year 2 subaward (Year 2 is held:
# safeguards only). cms_fy2026_allotments.csv is untouched (its digest is
# pinned in test_year2_safeguards.R).
#
# THE TOTAL. The 50 rows sum to $10,000,000,001, one dollar above the release's
# "$10 billion": per-state rounding by the publisher, recorded and asserted,
# never adjusted (§0.2: a figure that disagrees is a document to re-read).
#
#   Rscript R/03cu_cms_fy2027_allotments.R --fetch      # archive the release (deliberate act)
#   Rscript R/03cu_cms_fy2027_allotments.R --build      # parse the archive -> cms_fy2027_allotments.csv
#   Rscript R/03cu_cms_fy2027_allotments.R --validate   # parse == committed file; loader holds

source(here::here("R", "utils_config.R"))
suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(tibble)
})

FY27_URL <- paste0("https://www.cms.gov/newsroom/press-releases/",
                   "trump-administration-announces-10-billion-second-year-rural-health-transformation-awards-all-50")
FY27_FACTSHEET_URL <- "https://www.cms.gov/newsroom/fact-sheets/rural-health-transformation-program-year-2-awards"
FY27_FETCHED <- "2026-11-16"
FY27_DIR <- file.path("data", "raw", "cms", FY27_FETCHED)
FY27_FILE <- file.path(FY27_DIR, "cms_fy2027_award_table.html")
FY27_FACTSHEET_FILE <- file.path(FY27_DIR, "cms_rhtp_year2_awards_fact_sheet.html")
FY27_MANIFEST <- file.path(FY27_DIR, "cms_fy2027_award_table.manifest.txt")
FY27_RELEASE_DATE <- "2026-11-09"
FY27_STATED_TOTAL <- 10e9
FY27_ROUNDING_USD <- 1          # the table sums to $10,000,000,001
FY27_HEADING <- "Year 2 Rural Health Transformation Awards"
FY27_COLUMN <- "FY 2027 Award"

fy27_agent <- function() rhtp_config()$api$user_agent

#' Archive the release and the fact sheet (the deliberate act, §2.2)
fy27_fetch <- function(force = FALSE) {
  dir.create(here::here(FY27_DIR), recursive = TRUE, showWarnings = FALSE)
  got <- list(); raw_sha <- list()
  for (x in list(c(FY27_URL, FY27_FILE), c(FY27_FACTSHEET_URL, FY27_FACTSHEET_FILE))) {
    path <- here::here(x[2])
    if (file.exists(path) && !force) { got[[x[2]]] <- readBin(path, "raw", file.size(path)); next }
    r <- httr::GET(x[1], httr::user_agent(fy27_agent()), httr::timeout(60))
    if (httr::status_code(r) != 200L) stop("[FY2027] HTTP ", httr::status_code(r), " for ", x[1], call. = FALSE)
    body <- httr::content(r, as = "raw")
    raw_sha[[x[2]]] <- digest::digest(body, algo = "sha256", serialize = FALSE)
    txt <- rawToChar(body)
    # cms.gov pages carry the site's public Mapbox token in Drupal settings
    # (§7.1, the 2026-08-27 allotment table and SC's 09-17 release likewise).
    # Strip it BY NAME and record both digests; refuse any other key.
    txt <- gsub('"mapboxToken":"pk\\.[A-Za-z0-9._-]+"', '"mapboxToken":"STRIPPED"', txt, perl = TRUE)
    body <- charToRaw(txt)
    if (grepl("pk\\.eyJ|AIza[0-9A-Za-z_-]{30,}", txt, perl = TRUE)) {
      stop("[FY2027] refusing to archive ", x[1], ": it carries a credential-shaped string.", call. = FALSE)
    }
    writeBin(body, path)
    got[[x[2]]] <- body
  }
  man <- paste0(
    "source_url: ", FY27_URL, "\n",
    "fact_sheet_url: ", FY27_FACTSHEET_URL, "\n",
    "release_date: ", FY27_RELEASE_DATE, "\n",
    "fetched: ", FY27_FETCHED, "\n",
    "user_agent: ", fy27_agent(), "\n",
    "release_raw_sha256 (as served, before stripping the Mapbox token): ", raw_sha[[FY27_FILE]] %||% "unchanged since first fetch", "\n",
    "fact_sheet_raw_sha256: ", raw_sha[[FY27_FACTSHEET_FILE]] %||% "unchanged since first fetch", "\n",
    "release_sha256: ", digest::digest(file = here::here(FY27_FILE), algo = "sha256"), "\n",
    "fact_sheet_sha256: ", digest::digest(file = here::here(FY27_FACTSHEET_FILE), algo = "sha256"), "\n",
    "note: Tier 1 (CMS award to a state), Budget Period 2. Parsed by R/03cu, never transcribed.\n")
  writeLines(man, here::here(FY27_MANIFEST), sep = "")
  message("[FY2027] archived ", FY27_FILE, " and ", FY27_FACTSHEET_FILE)
  invisible(got)
}

#' Parse the table from the archived release
fy27_parse <- function(path = here::here(FY27_FILE)) {
  h <- xml2::read_html(path)
  txt <- stringr::str_squish(xml2::xml_text(h))
  if (!grepl(FY27_HEADING, txt, fixed = TRUE)) {
    stop("[FY2027] the archived release no longer carries '", FY27_HEADING, "'.", call. = FALSE)
  }
  tabs <- xml2::xml_find_all(h, "//table")
  hit <- Filter(function(t) grepl(FY27_COLUMN, xml2::xml_text(t), fixed = TRUE), tabs)
  if (length(hit) != 1L) stop("[FY2027] expected ONE table with a '", FY27_COLUMN, "' column; found ",
                              length(hit), ".", call. = FALSE)
  rows <- xml2::xml_find_all(hit[[1]], ".//tr")
  cells <- lapply(rows, function(r) stringr::str_squish(xml2::xml_text(xml2::xml_find_all(r, "./td|./th"))))
  cells <- Filter(function(x) length(x) == 2L && grepl("^\\$[0-9,]+$", x[2]), cells)
  d <- tibble::tibble(state_name = vapply(cells, `[`, "", 1), published = vapply(cells, `[`, "", 2))
  st <- rhtp_cms_states()
  d$state <- st$state[match(d$state_name, st$state_name)]
  if (anyNA(d$state)) stop("[FY2027] unrecognised state name(s): ",
                           paste(d$state_name[is.na(d$state)], collapse = ", "), call. = FALSE)
  d$fy2027_allotment <- as.numeric(gsub("[$,]", "", d$published))
  if (nrow(d) != 50L || anyDuplicated(d$state)) {
    stop("[FY2027] parsed ", nrow(d), " rows; a filled table is all 50 states, once each.", call. = FALSE)
  }
  tot <- sum(d$fy2027_allotment)
  if (abs(tot - FY27_STATED_TOTAL) != FY27_ROUNDING_USD) {
    stop("[FY2027] the 50 rows sum to $", format(tot, big.mark = ",", scientific = FALSE),
         "; recorded as $10 billion + $", FY27_ROUNDING_USD, " of publisher rounding. Re-read the release.",
         call. = FALSE)
  }
  d %>% dplyr::arrange(state) %>%
    dplyr::transmute(state, state_name, fy2027_allotment = format(fy2027_allotment, scientific = FALSE, trim = TRUE),
                     fy2027_allotment_published = published, source_url = FY27_URL, source_fetched = FY27_FETCHED)
}

fy27_build <- function() {
  d <- fy27_parse()
  readr::write_csv(d, here::here(RHTP_FY2027_ALLOTMENTS))
  rhtp_load_fy2027_allotments()
  message("[FY2027] wrote ", RHTP_FY2027_ALLOTMENTS, ": 50 states, $",
          format(sum(as.numeric(d$fy2027_allotment)), big.mark = ",", scientific = FALSE))
  invisible(d)
}

fy27_validate <- function() {
  a <- rhtp_load_fy2027_allotments()
  p <- fy27_parse()
  if (!identical(as.data.frame(a), as.data.frame(p %>% dplyr::mutate(dplyr::across(dplyr::everything(), as.character))))) {
    stop("[FY2027] the committed file differs from a parse of the archive.", call. = FALSE)
  }
  man <- readLines(here::here(FY27_MANIFEST))
  want <- sub("^release_sha256: ", "", grep("^release_sha256: ", man, value = TRUE))
  if (!identical(want, digest::digest(file = here::here(FY27_FILE), algo = "sha256"))) {
    stop("[FY2027] the archived release no longer matches its manifest digest.", call. = FALSE)
  }
  message("[FY2027] valid: 50 states parsed from the archive, digest matches.")
  invisible(TRUE)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) fy27_fetch(force = "--force" %in% args)
  if ("--build" %in% args) fy27_build()
  if ("--validate" %in% args) fy27_validate()
  if (!length(intersect(args, c("--fetch", "--build", "--validate")))) {
    cat("Usage: Rscript R/03cu_cms_fy2027_allotments.R [--fetch [--force]] [--build] [--validate]\n")
  }
}
