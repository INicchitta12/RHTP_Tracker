#!/usr/bin/env Rscript
# 03z_ia_year1_awardees.R -----------------------------------------------------
#
# IOWA -- RHTP Year 1. Iowa brands the programme HEALTHY HOMETOWNS, and it
# publishes MORE AWARD DOCUMENTS THAN ANY STATE THIS PROJECT HAS MET: its
# programme page carries a "Where to Find Funding Awardees" section linking
# ELEVEN Notices of Intent to Award across NINE RFPs. No other state in this
# repository publishes an awardee index of that shape.
#
# WHAT IOWA PUBLISHES, AND WHAT IT DOES NOT.
#
#   NAMES        every notice names its awardees, mostly Iowa hospitals.
#   AMOUNTS      NOT ONE NOTICE CARRIES A PER-RECIPIENT AMOUNT. Each holds
#                exactly ONE dollar figure and it is in the CMS
#                financial-assistance footer.
#
# That is NEVADA'S SHAPE -- a complete named roster with no money on it -- so
# `amount` is EMPTY on every row, `sum(amount)` is 0, and Iowa contributes
# NAMED-HOSPITAL ROW COUNTS AND $0 OF NAMED-HOSPITAL DOLLARS. Both are true at
# once, and `ia_assert_zero_dollars_is_not_zero_hospitals()` exists to make it
# impossible to report the 0 without the row count (§0.4).
#
# §0.2 INSIDE ONE DOCUMENT SERIES, WHICH IS NEW. The footer's grammatical
# subject is the RFP or the programme -- "This Centers of Excellence is
# supported by...", "This RFP #PHTHORC26012 ... is supported by..." -- which is
# session 27's STRONG form. ITS AMOUNT IS NOT ONE TIER:
#
#   the EIGHT Jan/Feb notices   the RFP's own POOL       (Tier 2)
#   the THREE June-18 notices   IOWA'S STATE ALLOTMENT   (Tier 1)
#
# Iowa's footer practice changed between February and June, in the same
# template, with no other signal. SUMMING THE ELEVEN FOOTER FIGURES GIVES
# $854,852,514.73 AGAINST A $209,040,063.71 ALLOTMENT. So NO FOOTER FIGURE ENTERS
# THE AWARD FILE AT ALL -- not even in `round_amount`, which is where Nevada's
# and South Dakota's pool totals live. They are recorded document by document,
# with the tier each carries, in `ia_notice_footers.csv`, and an assertion
# refuses to let that file be summed. A pool figure this project cannot
# attribute with confidence is not a figure to publish (§0.4).
#
# THE NOTICES NEVER NAME THE PROGRAMME. "RHTP", "Rural Health Transformation"
# and "Healthy Hometowns" occur ZERO times in them -- Kansas's problem, in a
# state whose documents are otherwise the strongest source type available. The
# footer is therefore NON-STRICT here on a second ground beyond session 27's:
# its subject is programme-scoped but its amount is tier-inconsistent. The
# provenance is carried by the PROGRAMME PAGE and by two other publishers.
#
# WHY THIS FILE COULD NOT BE WRITTEN BEFORE SESSION 32. `rhtp_pdf_lines()` broke
# a line only on vertical movement, so Iowa's table cells merged into
# "Adair County Memorial Hospital Greenfield" -- the county welded onto the
# organisation, session 21's "Crisp Regional ospital" one column over. The run
# model added this session is what makes the columns separable, and it separates
# them at Iowa's own producer's boundaries rather than by a threshold.
#
# CLI:
#   --fetch [--force]  archive the 14 sources + SHA-256 manifest
#   --validate         every assertion, offline
#   --build            write the three CSVs
#   --report           the roster, and what Iowa has not published
#
# Sessions: 32.

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(stringr)
  library(purrr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_pdf_text.R"))
source(here::here("R", "utils_recipient_classification.R"))


# -- constants ----------------------------------------------------------------

IA_STATE        <- "IA"
IA_EVIDENCE_DIR <- here::here("data", "evidence", "IA")
IA_OUT_CSV      <- here::here("data", "reference", "ia_year1_awardees.csv")
IA_FOOTERS_CSV  <- here::here("data", "reference", "ia_notice_footers.csv")
IA_DISPOSITION_CSV <- here::here("data", "reference",
                                 "ia_rcj_candidate_disposition.csv")

IA_USER_AGENT <- paste(
  "AHA-RHTP-Tracker/0.1 (+https://www.aha.org;",
  "contact: AHA Data and Policy; R httr2)"
)
IA_HOST_THROTTLE_S <- 2

IA_CREDENTIAL_SHAPES <- c(
  "Mapbox token"    = "\\b[ps]k\\.ey[A-Za-z0-9._-]{20,}",
  "Google API key"  = "\\bAIza[0-9A-Za-z_-]{30,}",
  "AWS access key"  = "\\bAKIA[0-9A-Z]{16}\\b"
)

# -- what IOWA states, so a change in the source fails rather than passes ------

# The §7.1 anchor has Iowa at $209,040,064; the three June footers print
# $209,040,063.71, which is the same award to the cent.
IA_ALLOTMENT      <- 209040063.71
IA_NOA_DATE       <- as.Date("2025-12-29")
IA_BUDGET_PERIOD  <- "BP1 (12/29/2025 - 10/30/2026)"

# The programme page's own words. Each is PROGRAMME-SCOPED, which is what the
# footer is not, and each is asserted every run.
IA_PROGRAMME_QUOTES <- c(
  "Healthy Hometowns is Iowa",
  "Rural Health Transformation Program",
  "Where to Find Funding Awardees"
)
# "In the first year, Iowa was award $209 million." The typo is Iowa's and is
# kept as published (§8).
IA_PROGRAMME_ALLOTMENT_QUOTE <- "In the first year, Iowa was award $209 million"

IA_GOVERNOR_QUOTE <- "Iowa first in the nation to award Rural Health Transformation Program funding"
IA_JUNE_RELEASE_QUOTE <- "funded through the CMS Rural Health Transformation Program"

# The ONE name Iowa's two publications spell differently, notice -> release.
# Recorded, never resolved (§2): the notice is the award document and its
# spelling is what this file carries.
IA_JUNE_RELEASE_SPELLINGS <- list(
  "Mary Greeley Medical Center" = "Mary Greely Medical Center"
)

# The awardee index. Iowa publishes a roster in a recognisable form -- one
# "Notice of Intent to Award" link per awarded RFP, under one heading -- so
# "Iowa has published nothing further" is a claim about Iowa and not about our
# reading. A TWELFTH link is a new roster to read and fails the build.
IA_AWARDEE_SECTION <- "Where to Find Funding Awardees"
IA_AWARDEE_MEDIA_IDS <- c("18093", "18094", "18135", "18136", "18137",
                          "18138", "18139", "18330", "18884", "18885", "18886")


# -- sources ------------------------------------------------------------------
#
# `pool_amount` is the figure in that notice's OWN footer and `footer_tier` says
# what it is. NOTHING downstream sums this column; see ia_write_footers().

IA_NOTICES <- tibble::tribble(
  ~key,        ~media, ~rfp,             ~notice_date, ~programme,
  ~footer_amount,  ~footer_tier,   ~supersedes, ~superseded_by,
  "phthorc26009_jan", "18093", "PHTHORC26009", "2026-01-30",
  "Best and Brightest - Medical Equipment Procurement",
  66002161.80, "SOLICITATION",   NA_character_, "phthorc26009_feb",
  "phthorc26010",     "18094", "PHTHORC26010", "2026-01-30",
  "Best and Brightest - Rural Healthcare Workforce Recruitment",
  12600000.00, "SOLICITATION",   NA_character_, NA_character_,
  "compadm26001",     "18135", "COMPADM26001", "2026-02-05",
  "Combat Cancer Technical Assistance Provider",
  6000000.00,  "SOLICITATION",   NA_character_, NA_character_,
  "phthocc26755",     "18136", "PHTHOCC26755", "2026-02-05",
  "Combat Cancer Prevention and Screening",
  15128000.00, "SOLICITATION",   NA_character_, NA_character_,
  "phthorc26008",     "18137", "PHTHORC26008", "2026-02-05",
  "Centers of Excellence",
  50000000.00, "SOLICITATION",   NA_character_, NA_character_,
  "compadm26003",     "18138", "COMPADM26003", "2026-02-05",
  "Communities of Care Technical Assistance Provider",
  6000000.00,  "SOLICITATION",   NA_character_, NA_character_,
  "compadm26002",     "18139", "COMPADM26002", "2026-02-05",
  "Health Hub Technical Assistance Provider",
  6000000.00,  "SOLICITATION",   NA_character_, NA_character_,
  "phthorc26009_feb", "18330", "PHTHORC26009", "2026-02-27",
  "Best and Brightest - Medical Equipment Procurement (re-issued)",
  66002161.80, "SOLICITATION",   "phthorc26009_jan", NA_character_,
  "phthocc26756",     "18884", "PHTHOCC26756", "2026-06-18",
  "Combat Cancer Health Hub Program",
  209040063.71, "STATE_ALLOTMENT", NA_character_, NA_character_,
  "phthorc26011",     "18885", "PHTHORC26011", "2026-06-18",
  "Best and Brightest - Medical Equipment",
  209040063.71, "STATE_ALLOTMENT", NA_character_, NA_character_,
  "phthorc26012",     "18886", "PHTHORC26012", "2026-06-18",
  "Best and Brightest - Rural Healthcare Workforce Recruitment",
  209040063.71, "STATE_ALLOTMENT", NA_character_, NA_character_
)

IA_MEDIA_BASE <- "https://hhs.iowa.gov/media/%s/download?inline"

IA_SOURCES <- dplyr::bind_rows(
  IA_NOTICES %>%
    dplyr::transmute(
      key = .data$key,
      file = sprintf("%s_ia_noia_%s_%s.pdf", .data$notice_date,
                     tolower(.data$rfp),
                     stringr::str_replace_all(
                       stringr::str_to_lower(stringr::str_sub(.data$programme, 1, 46)),
                       "[^a-z0-9]+", "_")),
      url = sprintf(IA_MEDIA_BASE, .data$media)
    ),
  tibble::tribble(
    ~key, ~file, ~url,
    "programme",
    "2026-09-01_ia_hhs_healthy_hometowns_programme.html",
    paste0("https://hhs.iowa.gov/initiatives/",
           "healthy-hometowns-iowas-rural-health-transformation-plan"),
    "governor",
    "2026-01-30_governor_iowa_first_in_nation_to_award_rhtp.html",
    paste0("https://governor.iowa.gov/press-release/2026-01-30/",
           "iowa-first-nation-award-rural-health-transformation-program-funding"),
    "june_release",
    "2026-06-18_ia_hhs_gme_approval_new_healthy_hometowns_awardees.html",
    paste0("https://hhs.iowa.gov/news-release/2026-06-18/governor-reynolds-and-",
           "iowa-hhs-announce-graduate-medical-education-approval-new-healthy-hometowns")
  )
)


# -- fetch --------------------------------------------------------------------

ia_source <- function(key, field) {
  row <- IA_SOURCES[IA_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[IA] unknown source key: ", key, call. = FALSE)
  row[[field]]
}

ia_path <- function(key) file.path(IA_EVIDENCE_DIR, ia_source(key, "file"))

#' Refuse to archive anything carrying a credential (§7.1, sessions 14/16/17/20)
ia_assert_credential_free <- function(body, label) {
  chunk <- body[seq_len(min(length(body), 4e6))]
  txt <- rawToChar(chunk[chunk != as.raw(0)])
  Encoding(txt) <- "latin1"
  for (nm in names(IA_CREDENTIAL_SHAPES)) {
    if (stringr::str_detect(txt, IA_CREDENTIAL_SHAPES[[nm]])) {
      stop("[IA] refusing to archive ", label, ": it carries what looks like a ",
           nm, ".", call. = FALSE)
    }
  }
  invisible(TRUE)
}

ia_get <- function(url, label) {
  message("[IA] fetching ", url)
  resp <- httr::GET(url, httr::user_agent(IA_USER_AGENT), httr::timeout(300))
  if (httr::status_code(resp) != 200L) {
    stop("[IA] HTTP ", httr::status_code(resp), " for ", url, call. = FALSE)
  }
  served <- httr::content(resp, as = "raw")
  ia_assert_credential_free(served, label)
  served
}

ia_fetch <- function(force = FALSE) {
  dir.create(IA_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  entries <- purrr::map_dfr(seq_len(nrow(IA_SOURCES)), function(i) {
    src <- IA_SOURCES[i, ]
    dest <- file.path(IA_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[IA] cached, not re-fetched: ", src$file)
    } else {
      if (i > 1L) Sys.sleep(IA_HOST_THROTTLE_S)
      writeBin(ia_get(src$url, src$file), dest)
    }
    tibble::tibble(
      key = src$key, file = src$file, url = src$url,
      bytes = file.info(dest)$size,
      sha256 = digest::digest(file = dest, algo = "sha256")
    )
  })
  ia_write_manifest(entries)
  entries
}

ia_write_manifest <- function(entries) {
  path <- file.path(IA_EVIDENCE_DIR, "MANIFEST.txt")
  writeLines(c(
    "Iowa -- RHTP Year 1 (HEALTHY HOMETOWNS): the ELEVEN Notices of Intent to",
    "Award that hhs.iowa.gov's programme page links under \"Where to Find",
    "Funding Awardees\", the programme page itself, and TWO further publishers",
    "of the same claim -- the Governor's 2026-01-30 release and Iowa HHS's",
    "2026-06-18 release.",
    "Archived by R/03z_ia_year1_awardees.R --fetch",
    paste0("User-agent: ", IA_USER_AGENT),
    "",
    "Every file is the body the server sent, BYTE FOR BYTE, written with",
    "writeBin(), so re-hashing a file on disk reproduces its digest below. The",
    "credential guard runs on every fetch here and finds nothing, so there is",
    "no reduction to explain and the documents are whole.",
    "",
    "NOT ONE NOTICE CARRIES A PER-RECIPIENT AMOUNT. Each holds exactly ONE",
    "dollar figure and it is in the CMS financial-assistance footer. That",
    "absence is the finding, not a fetch failure -- Nevada's shape.",
    "",
    "THE FOOTER'S AMOUNT IS NOT ONE TIER, AND THE ELEVEN MUST NEVER BE SUMMED.",
    "The EIGHT Jan/Feb notices carry the RFP's own POOL ($50,000,000 Centers",
    "of Excellence, $66,002,161.80 twice -- the re-issue repeats it --",
    "$15,128,000, $12,600,000, $6,000,000 x3); the THREE June-18 notices carry",
    "IOWA'S STATE ALLOTMENT, $209,040,063.71. Summing the eleven gives",
    "$854,852,514.73 against a $209,040,063.71 allotment. Iowa's",
    "footer practice changed between February and June in the same template",
    "with no other signal. §0.2 inside one document SERIES.",
    "",
    "THE NOTICES NEVER NAME THE PROGRAMME: \"RHTP\", \"Rural Health",
    "Transformation\" and \"Healthy Hometowns\" occur ZERO times in them. The",
    "provenance is the programme page's own sentences and the two other",
    "publishers, not the footer.",
    "",
    "18093 IS SUPERSEDED BY 18330. Both are PHTHORC26009; the 2026-02-27",
    "re-issue is the 2026-01-30 roster PLUS Marengo Memorial Hospital. Counting",
    "both invents a roster Iowa never issued. Both stay archived, because a",
    "re-issued roster's growth is only measurable against the one it grew from.",
    "",
    "18093'S FOOTER PRINTS `$66,002,161.80.00`. The doubled decimal is IOWA'S,",
    "in the source, and is kept as published (§8).",
    "",
    paste0("Fetched: ", Sys.Date()),
    "",
    sprintf("%-72s %10s  %s", "file", "bytes", "sha256"),
    strrep("-", 72 + 12 + 64)
  ), path)
  cat(sprintf("%-72s %10d  %s", entries$file, entries$bytes, entries$sha256),
      file = path, sep = "\n", append = TRUE)
  cat("\n\nSource URLs\n", file = path, append = TRUE)
  cat(sprintf("  %-20s %s", entries$key, entries$url),
      file = path, sep = "\n", append = TRUE)
  invisible(path)
}


# -- reading the archive ------------------------------------------------------

ia_read_text <- function(key) {
  path <- ia_path(key)
  if (!file.exists(path)) {
    stop("[IA] missing archive: ", basename(path),
         " -- run `Rscript R/03z_ia_year1_awardees.R --fetch` first.",
         call. = FALSE)
  }
  txt <- readBin(path, "raw", file.info(path)$size)
  txt <- rawToChar(txt[txt != as.raw(0)])
  Encoding(txt) <- "UTF-8"
  txt
}

ia_html_text <- function(key) {
  doc <- xml2::read_html(ia_read_text(key))
  xml2::xml_remove(xml2::xml_find_all(doc, "//script | //style"))
  stringr::str_squish(xml2::xml_text(doc))
}

ia_pdf_cache <- new.env(parent = emptyenv())

#' Every painted run of one notice, cached -- the run model of session 32
ia_runs <- function(key) {
  if (!exists(key, envir = ia_pdf_cache, inherits = FALSE)) {
    assign(key, rhtp_pdf_runs(ia_path(key)), envir = ia_pdf_cache)
  }
  get(key, envir = ia_pdf_cache, inherits = FALSE)
}

ia_flat <- function(key) {
  stringr::str_squish(paste(rhtp_pdf_lines(ia_path(key))$text, collapse = " "))
}

#' A run's line key: runs sharing one were painted at one vertical position
ia_line_key <- function(r) {
  if (nrow(r) == 0L) return(integer(0))
  cumsum(c(TRUE, r$page[-1] != r$page[-nrow(r)] | r$line[-1] != r$line[-nrow(r)]))
}

ia_line_text <- function(r) {
  trimws(vapply(split(r$text, ia_line_key(r)), paste, character(1), collapse = ""))
}

# The two sentences that bound the roster in EVERY one of the eleven notices.
# The opening anchor tolerates the wrap: 18886 breaks "apparent successful" /
# "bidder(s):" across two lines, so a pattern spanning both words finds nothing.
IA_ROSTER_START <- "bidder\\(s\\)\\s*:"
IA_ROSTER_STOP  <- "^As provided for in the RFP|is supported by the Centers for Medicare"

# A header cell, dropped by EXACT match before the table is banded. 18886 sets
# its header in a different size at a different x from its own body, so it lands
# in the first data row's band; matching the label is what keeps it out.
# "Provider Type 1" is not an exact match for "Provider Type", so no data cell
# is ever reached by this.
IA_HEADER_LABELS <- c("Organization", "County", "Provider Type",
                      "Name of Applicant", "Provider")

#' The runs of one notice's roster: between the two anchors, minus page numbers
#'
#' A line that is nothing but one or two digits is a page number -- 18885 and
#' 18886 both set one inside the roster's vertical span, at an x of its own,
#' and left in it becomes a column.
ia_roster_runs <- function(key) {
  r <- ia_runs(key)
  k <- ia_line_key(r)
  lt <- ia_line_text(r)
  ks <- as.integer(names(lt))
  st <- ks[stringr::str_detect(lt, IA_ROSTER_START)]
  if (!length(st)) {
    stop("[IA] ", key, ": no \"...successful bidder(s):\" line. The notice's ",
         "shape has changed and the roster cannot be located -- an EMPTY ",
         "answer here would read as \"Iowa named nobody\" (§0.4).", call. = FALSE)
  }
  st <- st[1]
  sp <- ks[ks > st & stringr::str_detect(lt, IA_ROSTER_STOP)]
  if (!length(sp)) {
    stop("[IA] ", key, ": no closing boilerplate after the roster.", call. = FALSE)
  }
  b <- r[k > st & k < sp[1] & nzchar(trimws(r$text)), , drop = FALSE]
  bk <- ia_line_key(b)
  page_no <- vapply(split(b$text, bk), function(v)
    stringr::str_detect(trimws(paste(v, collapse = "")), "^[0-9]{1,2}$"), logical(1))
  b <- b[!(bk %in% as.integer(names(page_no)[page_no])), , drop = FALSE]
  b[!(trimws(b$text) %in% IA_HEADER_LABELS), , drop = FALSE]
}

#' The x positions of the table's columns
#'
#' Anchors are the run x values, clustered so that a cell's own internal breaks
#' stay with their column (18886 paints "Community Health Center of Fort Dodge,"
#' at x=77.4 and its "(Clay County)" continuation at 79.3), and then thinned to
#' those carrying a real share of the table's runs. A column with a handful of
#' runs against another column's sixty is not a column: in 18886 that describes
#' the four stray positions left after the page numbers are dropped.
#'
#' NOTHING HERE IS A GAP THRESHOLD ON THE TEXT. The x values come from the
#' producer; `merge_pt` only decides which of ITS positions are one column, and
#' a run that falls outside every anchor still lands in the last column at or
#' before it, so no text is ever dropped.
ia_columns <- function(b, merge_pt = 20, share = 0.25) {
  tb <- table(round(b$x, 1))
  xs <- as.numeric(names(tb)); n <- as.integer(tb)
  o <- order(xs); xs <- xs[o]; n <- n[o]
  grp <- cumsum(c(TRUE, diff(xs) > merge_pt))
  agg <- data.frame(x = as.numeric(tapply(xs, grp, min)),
                    n = as.integer(tapply(n, grp, sum)))
  sort(agg$x[agg$n >= share * max(agg$n)])
}

#' One notice's roster, one row per award action
#'
#' TWO ROW MODELS, AND WHICH ONE APPLIES IS DECIDED BY THE DOCUMENT.
#'
#' A SINGLE-COLUMN notice cannot wrap a cell invisibly: every run on one line
#' belongs to the one column, so a LINE IS A ROW. 18885 sets
#' "Iowa Specialty Hospital", "-" and "Clarion" as three runs at one y, and
#' pasting the line is what puts them back together.
#'
#' A MULTI-COLUMN notice can wrap, and the LAST column is what delimits its
#' rows: it holds one short value per row -- a county, a provider type -- and
#' never wraps in any of the four tables Iowa publishes. Each run is assigned to
#' the row whose last-column value is VERTICALLY NEAREST, which is the midpoint
#' rule and it holds in both alignments Iowa uses: 18094 top-aligns its columns
#' and 18886 centres its second one. It holds because a row that wraps is
#' TALLER, so the midpoint to the next row stays below the wrapped line -- and
#' the invariant below is what checks that rather than assuming it.
# ONE NAME THIS READER CANNOT READ OUT OF ONE NOTICE, AND WHY IT IS A READER
# LIMIT RATHER THAN A FACT ABOUT IOWA.
#
# The 2026-02-27 re-issue of PHTHORC26009 sets "St. Joseph's Mercy Hospital DBA
# MercyOne Centerville Medical Center" across a break BETWEEN "MercyOne" and
# "Centerville" that falls INSIDE one drawn line -- two runs at one y, with no
# space glyph between them. Runs within a line concatenate with nothing, because
# that is how Iowa splits "Ve"/"terans" into "Veterans", so this one comes out
# "MercyOneCenterville Medical Center".
#
# THE GEOMETRY CANNOT DECIDE IT AND THAT IS MEASURED. "Ve" -> "terans" advances
# 14.8 points for two characters; "MercyOne" -> "Centerville" advances 4.9 for
# eight, which is impossible as a real advance -- so the reader's x is not
# tracking a pen movement there and no rule over x can tell the two apart
# without font metrics this reader does not have.
#
# WHAT DECIDES IT IS IOWA. The SAME award, the SAME RFP, in the notice this one
# re-issues, is set on a single line and reads
# "MercyOne Centerville Medical Center". So the space is Iowa's, the loss is
# ours, and taking the January spelling invents nothing -- both strings are the
# State's, one of them is unambiguous, and both documents are archived here.
#
# IT IS ONE ENTRY AND IT STAYS ONE. ia_assert_supersession() compares the two
# rosters AFTER this repair, so a second name that goes the same way fails the
# build instead of being absorbed.
IA_NAME_FROM_SUPERSEDED <- c(
  "St. Joseph's Mercy Hospital DBA MercyOneCenterville Medical Center" =
    "St. Joseph's Mercy Hospital DBA MercyOne Centerville Medical Center"
)

#' One cell's text: runs join with NOTHING, wrapped lines join with a SPACE
#'
#' TWO JOINS, AND THEY ARE NOT THE SAME JOIN. Runs painted at one y are pieces
#' of one drawn line and their separators are already in them -- Iowa splits
#' "Veterans" into "Ve" and "terans" and "Iowa Specialty Hospital" from its
#' "-" and "Clarion" -- so they concatenate with nothing, exactly as the line
#' model does.
#'
#' A CELL THAT WRAPS IS DIFFERENT, and the PHTHORC26009 re-issue is why this is
#' not a matter of taste. Iowa wraps at WORD boundaries and the break itself
#' carries the separation: the January notice sets
#' "MercyOne Centerville Medical Center" on one line, the February re-issue
#' breaks the same name after "MercyOne", and no space glyph is emitted at the
#' break. Joined with nothing that is "MercyOneCenterville Medical Center" -- a
#' mangled recipient name, the defect this whole session exists to remove, one
#' level further in. Joined with a space and squished, both notices give the
#' same name, which is the check that says the rule is right.
#'
#' It is deliberately NOT put in the shared reader: KANSAS WRAPS MID-WORD
#' ("Citizens Foundat" / "ion: $146,476"), so a space at every break is correct
#' for Iowa and wrong for KDHE. It is a fact about this publisher's typography.
ia_cell_text <- function(d) {
  if (nrow(d) == 0L) return("")
  by_line <- vapply(split(d$text, d$lk), paste, character(1), collapse = "")
  stringr::str_squish(paste(by_line, collapse = " "))
}

ia_roster <- function(key) {
  b <- ia_roster_runs(key)
  a <- ia_columns(b)
  nc <- length(a)
  b$col <- pmax(1L, findInterval(round(b$x, 1) + 1e-6, a))
  b <- b[order(b$page, -b$y), , drop = FALSE]

  if (nc == 1L) {
    b$row <- ia_line_key(b)
  } else {
    last <- unique(data.frame(page = b$page[b$col == nc], y = b$y[b$col == nc]))
    last <- last[order(last$page, -last$y), , drop = FALSE]
    last$row <- seq_len(nrow(last))
    b$row <- mapply(function(p, y) {
      cand <- last[last$page == p, , drop = FALSE]
      if (!nrow(cand)) return(NA_integer_)
      cand$row[which.min(abs(cand$y - y))]
    }, b$page, b$y)
  }

  b$lk <- ia_line_key(b)
  cells <- purrr::map_dfr(split(b, b$row), function(d) {
    vals <- vapply(seq_len(nc), function(k) ia_cell_text(d[d$col == k, ]),
                   character(1))
    tibble::tibble(awardee = vals[1],
                   col2 = if (nc >= 2L) vals[2] else NA_character_,
                   col3 = if (nc >= 3L) vals[3] else NA_character_)
  })

  # A bulleted roster (18884) carries its bullet in the text.
  cells$awardee <- trimws(stringr::str_remove(cells$awardee, "^\\s*[•·*-]\\s*"))

  hit <- cells$awardee %in% names(IA_NAME_FROM_SUPERSEDED)
  cells$name_repaired <- hit
  cells$awardee[hit] <- unname(IA_NAME_FROM_SUPERSEDED[cells$awardee[hit]])

  # THE INVARIANT. A wrong row model does not look wrong in the output -- it
  # looks like a recipient with no county, or a county with no recipient. Every
  # row must carry a value in every column the table has.
  empty <- purrr::map_lgl(seq_len(nrow(cells)), function(i)
    !nzchar(cells$awardee[i]) ||
      (nc >= 2L && !nzchar(cells$col2[i])) ||
      (nc >= 3L && !nzchar(cells$col3[i])))
  if (any(empty)) {
    stop("[IA] ", key, ": ", sum(empty), " of ", nrow(cells), " roster rows ",
         "have an empty cell, so the row model has not read this table. A ",
         "nameless award is never published as one.", call. = FALSE)
  }
  if (nrow(cells) == 0L) {
    stop("[IA] ", key, ": the roster parsed to NOTHING. That is the empty ",
         "answer, not a finding about Iowa (§0.4).", call. = FALSE)
  }
  cells$n_columns <- nc
  cells$row_in_notice <- seq_len(nrow(cells))
  cells
}


# -- §6.2 provenance ----------------------------------------------------------
#
# THE NOTICES CANNOT CARRY THIS AND IT IS MEASURED, NOT ASSUMED. Iowa's award
# documents never name the programme their awards belong to, so the provenance
# is three PROGRAMME-SCOPED sentences on the state's own programme page, plus
# two further publishers of the same claim.

#' The notices name no programme -- Kansas's condition, measured on every run
ia_assert_notices_name_no_programme <- function() {
  hits <- purrr::map_dfr(IA_NOTICES$key, function(k) {
    tx <- ia_flat(k)
    tibble::tibble(key = k,
                   rhtp = stringr::str_count(tx, stringr::fixed("RHTP")),
                   rht  = stringr::str_count(tx, stringr::fixed("Rural Health Transformation")),
                   hh   = stringr::str_count(tx, stringr::fixed("Healthy Hometowns")))
  })
  if (any(hits$rhtp + hits$rht + hits$hh > 0L)) {
    named <- hits$key[hits$rhtp + hits$rht + hits$hh > 0L]
    message("[IA] NOTE: ", length(named), " notice(s) now name the programme (",
            paste(named, collapse = ", "), "). That is STRONGER evidence than ",
            "when this file was written, not a failure -- but the finding ",
            "recorded here has changed and the file's §6.2 section must be ",
            "rewritten rather than left standing.")
  }
  invisible(hits)
}

#' The programme page carries the provenance, in Iowa's own words
ia_assert_programme_provenance <- function() {
  tx <- ia_html_text("programme")
  for (q in IA_PROGRAMME_QUOTES) {
    if (!stringr::str_detect(tx, stringr::fixed(q))) {
      stop("[IA] the programme page no longer carries \"", q, "\". Iowa's own ",
           "statement that Healthy Hometowns IS the Rural Health Transformation ",
           "Program is what makes these eleven notices RHTP documents at all ",
           "(§6.2); without it nothing here is sourced.", call. = FALSE)
    }
  }
  if (!stringr::str_detect(tx, stringr::fixed(IA_PROGRAMME_ALLOTMENT_QUOTE))) {
    stop("[IA] the programme page no longer states Iowa's Year 1 allotment.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Two further publishers say the same thing from two other pages
ia_assert_second_publishers <- function() {
  gov <- ia_html_text("governor")
  if (!stringr::str_detect(gov, stringr::fixed(IA_GOVERNOR_QUOTE))) {
    stop("[IA] the Governor's 2026-01-30 release no longer carries its own ",
         "headline. It is the SECOND PUBLISHER of the claim that these are ",
         "RHTP awards (§7).", call. = FALSE)
  }
  jun <- ia_html_text("june_release")
  if (!stringr::str_detect(jun, stringr::fixed(IA_JUNE_RELEASE_QUOTE))) {
    stop("[IA] Iowa HHS's 2026-06-18 release no longer says the June ",
         "initiatives are \"", IA_JUNE_RELEASE_QUOTE, "\".", call. = FALSE)
  }
  # It also re-publishes the Combat Cancer Health Hub roster, so five of the
  # names in this file have two publishers and nothing was arranged.
  #
  # FOUR OF THE FIVE MATCH VERBATIM AND THE FIFTH DOES NOT, BY ONE CHARACTER.
  # The notice writes "Mary Greeley Medical Center" and the release writes
  # "Mary Greely Medical Center" -- two of Iowa's own publications, eight days
  # apart on the same award. NOTHING IS NORMALISED: §2 forbids a machine
  # resolving a near-identical name, and the notice is the award document, so
  # the notice's spelling is what this file carries. The divergence is recorded
  # here so a reader meets it, and a SECOND one fails the build rather than
  # being absorbed into this exception.
  hub <- ia_roster("phthocc26756")$awardee
  seen <- vapply(hub, function(n) {
    alt <- IA_JUNE_RELEASE_SPELLINGS[[n]]
    stringr::str_detect(jun, stringr::fixed(n)) ||
      (!is.null(alt) && stringr::str_detect(jun, stringr::fixed(alt)))
  }, logical(1))
  if (!all(seen)) {
    stop("[IA] the 2026-06-18 release no longer names ", sum(!seen),
         " of the Combat Cancer Health Hub awardees this file carries (",
         paste(hub[!seen], collapse = "; "), "). That release is the ",
         "independent corroboration of one whole notice.", call. = FALSE)
  }
  # And the one recorded divergence must still BE a divergence: if the release
  # is corrected, this exception has to go rather than sit here unexplained.
  for (n in names(IA_JUNE_RELEASE_SPELLINGS)) {
    if (stringr::str_detect(jun, stringr::fixed(n))) {
      stop("[IA] the 2026-06-18 release now spells \"", n, "\" as the notice ",
           "does. The recorded spelling divergence is gone and the note in ",
           "ia_assert_second_publishers() must be removed.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' Every notice postdates Iowa's CMS Notice of Award
ia_assert_notices_postdate_noa <- function() {
  d <- as.Date(IA_NOTICES$notice_date)
  if (any(d <= IA_NOA_DATE)) {
    stop("[IA] ", sum(d <= IA_NOA_DATE), " notice(s) are dated on or before ",
         IA_NOA_DATE, ", so Iowa did not yet have the money (§6.2, Texas).",
         call. = FALSE)
  }
  # And each notice states its own date, so the table above is not a typed
  # constant standing in for the document.
  purrr::walk(seq_len(nrow(IA_NOTICES)), function(i) {
    want <- format(as.Date(IA_NOTICES$notice_date[i]), "%B %-d, %Y")
    tx <- ia_flat(IA_NOTICES$key[i])
    if (!stringr::str_detect(tx, stringr::fixed(want))) {
      stop("[IA] ", IA_NOTICES$key[i], " does not state its own date \"", want,
           "\".", call. = FALSE)
    }
  })
  invisible(TRUE)
}

#' The footer corroborates an AMOUNT and is never the provenance (session 27)
#'
#' NON-STRICT ON TWO GROUNDS, WHICH IS ONE MORE THAN ANY EARLIER STATE. Session
#' 27's axis is the footer's grammatical SUBJECT, and Iowa's is programme-scoped
#' -- "This Centers of Excellence is supported by..." -- which is the strong
#' form. Iowa fails a second test instead: THE AMOUNT IN THAT SLOT IS NOT ONE
#' TIER. Seven notices print the RFP's pool and four print the state allotment,
#' in the same sentence of the same template. A reader cannot take the number
#' without first knowing which, so the footer corroborates only where this file
#' says which tier it is reading.
ia_assert_footer_amounts <- function(strict = FALSE) {
  bad <- purrr::map_dfr(seq_len(nrow(IA_NOTICES)), function(i) {
    row <- IA_NOTICES[i, ]
    tx <- ia_flat(row$key)
    want <- formatC(row$footer_amount, format = "f", digits = 2, big.mark = ",")
    ok <- stringr::str_detect(tx, stringr::fixed(paste0("$", want)))
    tibble::tibble(key = row$key, want = want, ok = ok)
  })
  if (any(!bad$ok)) {
    msg <- paste0("[IA] ", sum(!bad$ok), " notice footer(s) no longer print ",
                  "the amount this file records: ",
                  paste(bad$key[!bad$ok], collapse = ", "), ".")
    if (strict) stop(msg, call. = FALSE)
    message(msg, " Called non-strictly, so this corroborates rather than ",
            "gates -- the provenance is the programme page (§6.2).")
    return(invisible(NA))
  }
  # The three June footers are the STATE ALLOTMENT and must match the §7.1
  # anchor. That is what proves they are not pool figures.
  june <- IA_NOTICES$footer_amount[IA_NOTICES$footer_tier == "STATE_ALLOTMENT"]
  if (!all(abs(june - IA_ALLOTMENT) < 0.005)) {
    stop("[IA] a June notice's footer no longer carries Iowa's allotment.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' The §0.2 refusal, in code: the eleven footers must never be added
#'
#' It is not a hypothetical. The eleven sum to $854,852,514.73 against a $209.0M
#' allotment, so the wrong reading is available to anyone who opens the
#' documents and adds up the only number in each.
ia_assert_footers_not_summable <- function() {
  s <- sum(IA_NOTICES$footer_amount)
  if (s <= IA_ALLOTMENT) {
    stop("[IA] the eleven footer amounts now sum to ", format(s, big.mark = ","),
         ", which no longer exceeds the allotment. This assertion exists to ",
         "pin the §0.2 trap open; if the figures have changed, re-read the ",
         "notices rather than relaxing it.", call. = FALSE)
  }
  tiers <- unique(IA_NOTICES$footer_tier)
  if (length(tiers) < 2L) {
    stop("[IA] the notices' footers now carry ONE tier. The §0.2 finding this ",
         "file reports -- that Iowa's footer changed tier mid-series -- has ",
         "changed and must be rewritten, not patched.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- positive controls --------------------------------------------------------

#' Iowa publishes an awardee index, and it holds exactly these eleven
#'
#' THE CONTROL THAT MAKES THE NEGATIVE MEAN SOMETHING. "Iowa has published no
#' further roster" is a claim about Iowa only because Iowa demonstrably
#' publishes rosters in a recognisable form -- one Notice of Intent to Award
#' link per awarded RFP under one heading. A TWELFTH is a new roster to read,
#' and it fails the build rather than being quietly ignored.
ia_assert_award_index <- function() {
  html <- ia_read_text("programme")
  if (!stringr::str_detect(html, stringr::fixed(IA_AWARDEE_SECTION))) {
    stop("[IA] the programme page no longer carries its \"", IA_AWARDEE_SECTION,
         "\" section -- the awardee index is the positive control and without ",
         "it a negative means nothing.", call. = FALSE)
  }
  ids <- unique(stringr::str_match_all(html, "/media/([0-9]+)/download")[[1]][, 2])
  # The application documents sit in a different section and are not awardee
  # documents; the control is over the ELEVEN this file reads.
  missing <- setdiff(IA_AWARDEE_MEDIA_IDS, ids)
  if (length(missing)) {
    stop("[IA] the programme page no longer links notice(s) ",
         paste(missing, collapse = ", "), ". A roster that disappears is a ",
         "change in what Iowa publishes and must be read, not dropped.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' 18330 supersedes 18093, and counting both invents a roster Iowa never issued
#'
#' It is also the check that caught the one name this reader cannot read out of
#' the re-issue -- see IA_NAME_FROM_SUPERSEDED. The comparison runs on the
#' REPAIRED rosters, so a SECOND such name fails here rather than joining a
#' standing exception.
ia_assert_supersession <- function() {
  jan <- ia_roster("phthorc26009_jan")$awardee
  feb <- ia_roster("phthorc26009_feb")$awardee
  if (!all(jan %in% feb)) {
    stop("[IA] the 2026-02-27 re-issue of PHTHORC26009 no longer contains the ",
         "whole 2026-01-30 roster: ",
         paste(setdiff(jan, feb), collapse = "; "), ". Either it is not a ",
         "superseding re-issue, or this reader has mis-read a name out of it ",
         "-- and a mis-read recipient name is never published (§0.4).",
         call. = FALSE)
  }
  added <- setdiff(feb, jan)
  if (length(added) != 1L || !stringr::str_detect(added, "Marengo Memorial")) {
    stop("[IA] the re-issue's addition is no longer the single Marengo ",
         "Memorial Hospital row this file records; it added: ",
         paste(added, collapse = "; "), ".", call. = FALSE)
  }
  invisible(added)
}

#' NOT ONE notice carries a per-recipient amount, and that is the whole design
#'
#' `amount` is empty on every row because Iowa publishes no figure to put
#' there. THE DAY IOWA PRICES ONE, THIS FILE IS WRONG rather than incomplete --
#' an empty amount column would then be a lie and not a finding -- so the build
#' refuses instead of quietly carrying on.
ia_assert_no_per_recipient_amounts <- function() {
  purrr::walk(IA_NOTICES$key, function(k) {
    b <- ia_roster_runs(k)
    money <- stringr::str_detect(b$text, "\\$\\s?[0-9]")
    if (any(money)) {
      stop("[IA] ", k, ": a dollar figure has appeared INSIDE the roster (",
           paste(trimws(b$text[money]), collapse = " | "), "). Iowa now ",
           "publishes per-recipient amounts and `ia_year1_awardees.csv` must ",
           "be REWRITTEN, not patched -- its empty `amount` column is only ",
           "honest while that column does not exist in the source.",
           call. = FALSE)
    }
  })
  invisible(TRUE)
}

#' Nevada's rule, in Iowa: $0 of named-hospital dollars is not 0 hospitals
ia_assert_zero_dollars_is_not_zero_hospitals <- function(rows = NULL) {
  if (is.null(rows)) rows <- ia_award_rows()
  part <- rhtp_hospital_dollar_partition(rows)
  named <- part[part$bucket == "NAMED_HOSPITAL", , drop = FALSE]
  if (nrow(named) == 0L || named$rows[1] == 0L) {
    stop("[IA] no named-hospital rows. Iowa's notices name Iowa hospitals; a ",
         "zero here is a parse failure, not a finding.", call. = FALSE)
  }
  if (named$dollars[1] != 0) {
    stop("[IA] named-hospital dollars are no longer 0. Iowa publishes NO ",
         "per-recipient amount, so any figure here came from this pipeline ",
         "and not from Iowa (§0.1).", call. = FALSE)
  }
  invisible(named)
}


# -- the award rows -----------------------------------------------------------

IA_OPERATIVE <- function() IA_NOTICES[is.na(IA_NOTICES$superseded_by), ]

IA_NOTE_TAIL <- paste(
  "Published by Iowa HHS as a Notice of Intent to Award, linked from the",
  "\"Where to Find Funding Awardees\" section of its Healthy Hometowns page.",
  "THE NOTICE PUBLISHES NO AMOUNT FOR ANY RECIPIENT: the only dollar figure it",
  "carries is in its CMS financial-assistance footer, whose tier changes",
  "between Iowa's February and June notices (§0.2), so no figure is attributed",
  "to this row and none is divided (§6.2). It is an INTENT, in the notice's own",
  "words: \"this Notice does NOT constitute the formation of a contract ...",
  "The bidder shall not acquire any legal or equitable rights relative to the",
  "contract services until a contract is executed.\""
)

#' Every award action Iowa has published, one row each
ia_award_rows <- function() {
  ops <- IA_OPERATIVE()
  rows <- purrr::map_dfr(seq_len(nrow(ops)), function(i) {
    n <- ops[i, ]
    r <- ia_roster(n$key)
    tibble::tibble(
      awardee = r$awardee,
      county = if (n$key %in% c("phthorc26009_feb")) r$col2 else
        if (n$key == "phthorc26010") r$col3 else NA_character_,
      provider_type = if (n$key == "phthorc26010") r$col2 else
        if (n$key == "phthorc26012") r$col2 else NA_character_,
      award_pool = n$rfp,
      round_name = n$programme,
      notice_date = n$notice_date,
      source_key = n$key,
      name_repaired = r$name_repaired,
      row_in_pool = r$row_in_notice
    )
  })

  # THE SHARED §8/§10.2 CLASSIFIER, ON THE NAME ALONE. Iowa's notices publish a
  # recipient and nothing about its organisational form -- no organisation-type
  # column of the kind Oregon and Alaska both have -- so this is Kansas's,
  # Maryland's, Nebraska's, Oklahoma's, Nevada's, Michigan's and Missouri's
  # shape an EIGHTH time, and every row typed from its own name.
  #
  # `description` is NA on every row and that is a fact about Iowa, not an
  # omission: its notices carry no project description at all, so nothing can
  # move a row off what the name says (§0.3a judges the recipient anyway).
  cls <- rhtp_classify_recipient_type(rows$awardee, IA_STATE)
  rows$recipient_type <- cls$recipient_type
  rows$recipient_type_confidence <- cls$determination_confidence
  rows$recipient_type_basis <- cls$recipient_type_basis

  flow <- rhtp_classify_flow(rows$recipient_type,
                             rep(NA_character_, nrow(rows)))
  rows$flow_type <- flow$flow_type
  rows$distributed_to_hospital <- flow$distributed_to_hospital
  rows$hospital_benefiting <- flow$hospital_benefiting
  rows$flow_basis <- flow$flow_basis

  rows$hospital_attribution <- rhtp_hospital_attribution(
    rows$flow_type, rows$distributed_to_hospital, rows$recipient_type)

  rows$flag_reason <- dplyr::case_when(
    rows$name_repaired ~ "AMOUNT_MISSING;RECIPIENT_NAME_FROM_SUPERSEDED_NOTICE",
    rows$recipient_type_confidence == "LOW" ~ "AMOUNT_MISSING;RECIPIENT_TYPE_INFERRED",
    TRUE ~ "AMOUNT_MISSING"
  )

  out <- tibble::tibble(
    state = IA_STATE,
    row_no = seq_len(nrow(rows)),
    awardee = rows$awardee,
    amount = NA_real_,
    recipient_type = rows$recipient_type,
    distributed_to_hospital = rows$distributed_to_hospital,
    note = paste0(
      dplyr::if_else(is.na(rows$provider_type), "",
                     paste0("Provider type: ", rows$provider_type, ". ")),
      dplyr::if_else(is.na(rows$county), "",
                     paste0("County: ", rows$county, ". ")),
      IA_NOTE_TAIL,
      dplyr::if_else(rows$name_repaired,
                     paste0(" NAME TAKEN FROM THE SUPERSEDED 2026-01-30 NOTICE:",
                            " the 2026-02-27 re-issue sets it across a break",
                            " inside one drawn line that this reader cannot",
                            " rejoin unambiguously; both notices are archived."),
                     "")),
    recipient_confirmed = "Yes",
    amount_confirmed = "No",
    fiscal_year = 2026L,
    source_document_title = paste0(
      "Iowa HHS Notice of Intent to Award, RFP #", rows$award_pool, " ",
      rows$round_name),
    state_source_url = vapply(rows$source_key, function(k)
      ia_source(k, "url"), character(1)),
    validation_source_type = "NOTICE_OF_INTENT_TO_AWARD",
    extraction_method = "PARSED_PDF_RUNS",
    validator = "R/03z_ia_year1_awardees.R",
    ccn = NA_character_,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    recipient_type_source = rows$recipient_type_basis,
    determination_confidence = dplyr::if_else(
      rows$recipient_type_confidence == "HIGH" &
        rows$distributed_to_hospital == "Yes", "MEDIUM",
      rows$recipient_type_confidence),
    flag_reason = rows$flag_reason,
    award_pool = rows$award_pool,
    budget_period = IA_BUDGET_PERIOD,
    flow_type = rows$flow_type,
    hospital_benefiting = rows$hospital_benefiting,
    hospital_attribution = rows$hospital_attribution,
    intermediary_name = NA_character_,
    determination_basis = paste(rows$recipient_type_basis, rows$flow_basis),
    amount_basis = paste(
      "Iowa publishes NO per-recipient amount. The notice's only dollar figure",
      "is its CMS footer, and that footer carries the RFP's pool in Iowa's",
      "Jan/Feb notices and the STATE ALLOTMENT in its June ones, so it is",
      "recorded per document in ia_notice_footers.csv and never attached to a",
      "recipient (§0.2, §6.2)."),
    county = rows$county,
    provider_type = rows$provider_type,
    round_name = rows$round_name,
    notice_date = rows$notice_date,
    source_archive_path = file.path("data/evidence/IA",
                                    vapply(rows$source_key, function(k)
                                      ia_source(k, "file"), character(1))),
    row_in_pool = rows$row_in_pool
  )
  out$determination_confidence[is.na(out$determination_confidence)] <- "LOW"
  out
}

#' The footer figures, per document, with the TIER each carries
#'
#' A SEPARATE FILE, DELIBERATELY, AND IT IS NOT AN AMOUNT COLUMN. These eleven
#' figures are the only dollar amounts in Iowa's award documents and they are
#' not one quantity: seven are an RFP's pool and four are the State's whole
#' Year 1 allotment. Kept beside the award file rather than in it -- Texas's and
#' Missouri's device -- so that nothing in `ia_year1_awardees.csv` can be summed
#' into a Tier-1 figure, and so a reader meets the tier before the number.
ia_footer_table <- function() {
  IA_NOTICES %>%
    dplyr::transmute(
      state = IA_STATE,
      rfp = .data$rfp,
      programme = .data$programme,
      notice_date = .data$notice_date,
      footer_amount = .data$footer_amount,
      footer_tier = .data$footer_tier,
      footer_subject_is_programme_scoped = "Yes",
      superseded_by = .data$superseded_by,
      state_source_url = vapply(.data$key, function(k) ia_source(k, "url"),
                                character(1)),
      source_archive_path = file.path("data/evidence/IA",
                                      vapply(.data$key, function(k)
                                        ia_source(k, "file"), character(1))),
      note = dplyr::if_else(
        .data$footer_tier == "STATE_ALLOTMENT",
        paste("TIER 1. This is Iowa's whole FY2026 CMS allotment, matching the",
              "§7.1 anchor. It is NOT this RFP's pool and must never be read as",
              "one, nor added to any figure in this table."),
        paste("TIER 2. The figure this notice's own footer attaches to this",
              "RFP. NEVER ADD IT TO ANOTHER ROW: four of the eleven notices",
              "carry the state allotment in the same slot, and the eleven sum",
              "to $854,852,514.73 against a $209,040,063.71 allotment (§0.2)."))
    )
}


# -- §0.1: what RCJ holds for Iowa --------------------------------------------
#
# THE NAMES ARE RIGHT AND THE MONEY IS A PLACEHOLDER. RCJ's ten Centers of
# Excellence rows match Iowa's own roster NAME FOR NAME, all ten -- the only
# state in this repository where that is true of a whole document -- and every
# one of its fifteen candidates is priced at $0 or $1. Missouri's placeholder
# mechanism, on a state whose names the aggregator gets exactly right.
#
# AND ITS COVERAGE IS TWO DOCUMENTS OF ELEVEN. A low candidate count is not
# evidence that a state has published little (Michigan's twelfth question):
# Iowa ranked FIRST on the RCJ_ONLY queue with FIFTEEN candidates and publishes
# 264 award actions.

ia_rcj_candidates <- function() {
  rt <- readRDS(here::here("data", "interim", "stage2_record_table.rds"))
  rt %>% dplyr::filter(.data$state == "IA", .data$award_tier == "SUBAWARD")
}

ia_disposition <- function() {
  cand <- ia_rcj_candidates()
  coe <- stringr::str_detect(cand$source_doc_title, "PHTHORC26008")
  n_coe <- sum(coe)
  n_bb  <- sum(!coe)
  roster_coe <- sort(ia_roster("phthorc26008")$awardee)
  matched <- identical(sort(cand$awardee_name_raw[coe]), roster_coe)

  tibble::tribble(
    ~state, ~group, ~rcj_rows, ~disposition, ~evidence,
    IA_STATE,
    "PHTHORC26008 Centers of Excellence -- REAL awards, priced at $0",
    n_coe, "RHTP_SUBAWARD_AMOUNT_IS_A_PLACEHOLDER",
    paste0("All ", n_coe, " match Iowa's own Notice of Intent to Award ",
           "(media 18137) NAME FOR NAME",
           if (matched) "" else " -- BUT THE SETS NO LONGER AGREE",
           ". Every one is carried at an amount of $0, so the aggregator holds ",
           "the right recipients and no money. Iowa publishes no per-recipient ",
           "amount either, so nothing is lost -- but a reader who took RCJ's ",
           "figure would publish $0 as a finding rather than as an absence."),
    IA_STATE,
    "Best and Brightest -- REAL awards, priced at $1",
    n_bb, "RHTP_SUBAWARD_AMOUNT_IS_A_PLACEHOLDER",
    paste0("All ", n_bb, " appear on the PHTHORC26010 roster (media 18094), ",
           "which names 107. Every one is carried at $1 -- Missouri's ",
           "mechanism, the defect no amount check can see, because the ",
           "aggregator publishes a placeholder rather than a wrong figure."),
    IA_STATE,
    "The other NINE notices",
    0L, "NOT_IN_THE_AGGREGATOR_AT_ALL",
    paste0("RCJ holds candidates from TWO of Iowa's ELEVEN notices. The other ",
           "nine -- including all three June ones and every single-recipient ",
           "technical-assistance award -- are absent entirely. Iowa ranked ",
           "FIRST on the RCJ_ONLY queue at 15 candidates and has published 264 ",
           "award actions: a low candidate count is not evidence that a state ",
           "has published little.")
  )
}


# -- assertions ---------------------------------------------------------------

ia_assert_rcj_names_match <- function() {
  cand <- ia_rcj_candidates()
  coe <- cand$awardee_name_raw[stringr::str_detect(cand$source_doc_title,
                                                   "PHTHORC26008")]
  mine <- ia_roster("phthorc26008")$awardee
  if (!identical(sort(coe), sort(mine))) {
    stop("[IA] RCJ's Centers of Excellence names no longer match this file's. ",
         "They are an INDEPENDENT reading of the same document and the only ",
         "external check this project has on the Iowa parse.",
         "\n  RCJ only : ", paste(setdiff(coe, mine), collapse = "; "),
         "\n  ours only: ", paste(setdiff(mine, coe), collapse = "; "),
         call. = FALSE)
  }
  # And the wrapped-cell join has its own external check: RCJ names
  # "Cass County Memorial Hospital DBA Cass Health" in full, and the notice
  # sets it across TWO lines. If the join broke, this name would not be here.
  bb <- cand$awardee_name_raw[!stringr::str_detect(cand$source_doc_title,
                                                   "PHTHORC26008")]
  r94 <- ia_roster("phthorc26010")$awardee
  if (!all(bb %in% r94)) {
    stop("[IA] RCJ names ", sum(!(bb %in% r94)), " Best and Brightest ",
         "recipient(s) this file's PHTHORC26010 roster does not: ",
         paste(setdiff(bb, r94), collapse = "; "),
         ". One of them is a cell the notice WRAPS, so this is the external ",
         "check on the wrapped-cell join.", call. = FALSE)
  }
  invisible(TRUE)
}

ia_assert_no_amount_column_effect <- function(rows = NULL) {
  if (is.null(rows)) rows <- ia_award_rows()
  if (!all(is.na(rows$amount))) {
    stop("[IA] `amount` is populated on ", sum(!is.na(rows$amount)), " row(s). ",
         "Iowa publishes no per-recipient figure, so any number here came from ",
         "this pipeline (§0.1).", call. = FALSE)
  }
  invisible(TRUE)
}

#' The superseded notice is NOT in the file, and the operative one IS
ia_assert_superseded_excluded <- function(rows = NULL) {
  if (is.null(rows)) rows <- ia_award_rows()
  ops <- IA_OPERATIVE()
  if ("phthorc26009_jan" %in% ops$key) {
    stop("[IA] the superseded 2026-01-30 PHTHORC26009 notice is being counted.",
         call. = FALSE)
  }
  n9 <- sum(rows$award_pool == "PHTHORC26009")
  if (n9 != nrow(ia_roster("phthorc26009_feb"))) {
    stop("[IA] PHTHORC26009 contributes ", n9, " rows but its operative ",
         "notice names ", nrow(ia_roster("phthorc26009_feb")), ".", call. = FALSE)
  }
  invisible(TRUE)
}

ia_assert_all <- function(strict_footer = FALSE) {
  ia_assert_programme_provenance()
  ia_assert_second_publishers()
  ia_assert_notices_postdate_noa()
  ia_assert_notices_name_no_programme()
  ia_assert_footer_amounts(strict = strict_footer)
  ia_assert_footers_not_summable()
  ia_assert_award_index()
  ia_assert_supersession()
  ia_assert_no_per_recipient_amounts()
  ia_assert_rcj_names_match()
  rows <- ia_award_rows()
  ia_assert_no_amount_column_effect(rows)
  ia_assert_superseded_excluded(rows)
  ia_assert_zero_dollars_is_not_zero_hospitals(rows)
  invisible(rows)
}


# -- build --------------------------------------------------------------------

ia_build <- function() {
  rows <- ia_assert_all()
  readr::write_csv(rows, IA_OUT_CSV, na = "")
  message("[IA] wrote ", IA_OUT_CSV, " (", nrow(rows), " rows)")

  foot <- ia_footer_table()
  readr::write_csv(foot, IA_FOOTERS_CSV, na = "")
  message("[IA] wrote ", IA_FOOTERS_CSV, " (", nrow(foot), " rows)")

  disp <- ia_disposition()
  readr::write_csv(disp, IA_DISPOSITION_CSV, na = "")
  message("[IA] wrote ", IA_DISPOSITION_CSV, " (", nrow(disp), " rows)")
  invisible(rows)
}

ia_report <- function() {
  rows <- ia_award_rows()
  part <- rhtp_hospital_dollar_partition(rows)
  cat("\nIOWA -- RHTP Year 1 (HEALTHY HOMETOWNS)\n")
  cat(strrep("-", 78), "\n")
  cat(sprintf("  %d award actions across %d RFPs in %d operative notices\n",
              nrow(rows), dplyr::n_distinct(rows$award_pool),
              nrow(IA_OPERATIVE())))
  cat(sprintf("  %d distinct awardees\n", dplyr::n_distinct(rows$awardee)))
  cat("\n  AMOUNTS: none. Iowa publishes NO per-recipient figure anywhere.\n")
  cat(sprintf("  sum(amount) = %d, and that is a fact about Iowa's documents.\n",
              sum(rows$amount, na.rm = TRUE)))
  cat("\n  NAMED HOSPITALS\n")
  for (i in seq_len(nrow(part))) {
    cat(sprintf("    %-24s rows = %3d   dollars = %d\n",
                part$bucket[i], part$rows[i], part$dollars[i]))
  }
  cat("\n  READ THE ROW COUNT. 152 named-hospital award actions and $0 of\n")
  cat("  named-hospital dollars are BOTH true (Nevada's shape).\n")
  cat("\n  BY RFP\n")
  by <- rows %>% dplyr::count(.data$award_pool, .data$round_name)
  for (i in seq_len(nrow(by))) {
    cat(sprintf("    %-14s %3d  %s\n", by$award_pool[i], by$n[i],
                stringr::str_trunc(by$round_name[i], 48)))
  }
  cat("\n  THE ELEVEN FOOTERS ARE NOT ONE TIER AND MUST NEVER BE SUMMED\n")
  f <- ia_footer_table()
  cat(sprintf("    %d notices carry the RFP's POOL; %d carry the $%s STATE ALLOTMENT\n",
              sum(f$footer_tier == "SOLICITATION"),
              sum(f$footer_tier == "STATE_ALLOTMENT"),
              formatC(IA_ALLOTMENT, format = "f", digits = 2, big.mark = ",")))
  cat(sprintf("    summing the eleven gives $%s against a $%s allotment\n",
              formatC(sum(f$footer_amount), format = "f", digits = 2, big.mark = ","),
              formatC(IA_ALLOTMENT, format = "f", digits = 2, big.mark = ",")))
  cat("\n  THE UNSTATED-FORM QUESTION, AN EIGHTH TIME\n")
  fb <- rows[rows$recipient_type == "NONPROFIT_CBO" &
               rows$determination_confidence == "LOW", ]
  cat(sprintf("    %d rows carry §8's standing fallback; worth $0 either way,\n",
              nrow(fb)))
  cat("    because Iowa publishes no amount. The question moves a COUNT.\n")
  invisible(rows)
}


# -- CLI ----------------------------------------------------------------------

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) {
    ia_fetch(force = "--force" %in% args)
  } else if ("--validate" %in% args) {
    ia_assert_all()
    message("[IA] all assertions pass.")
  } else if ("--build" %in% args) {
    ia_build()
  } else if ("--report" %in% args) {
    ia_report()
  } else {
    cat("usage: Rscript R/03z_ia_year1_awardees.R",
        "[--fetch [--force] | --validate | --build | --report]\n")
  }
}
