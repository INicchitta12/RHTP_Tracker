# 03o_ks_year1_awardees.R -----------------------------------------------------
# Kansas Year 1 -> data/reference/ks_year1_awardees.csv
#
# WHY KANSAS. It led `state_trigger_queue.csv` after Texas was worked out --
# 54 Tier 3 candidates, 50 distinct awardees, a $221,898,008 allotment and no
# CMS press release, so no session had ever looked at it.
#
# WHAT KANSAS PUBLISHES, AND IT IS MORE THAN THE PARTIAL LIST. The seven-award
# Community Health Worker + Accountable Food is Medicine list ($1,007,152,
# including hospital districts at $150,000 each) is real and is one of THREE
# award pools KDHE has published. The other two are in a single document,
# linked from the same page and roughly eighty times larger:
#
#   REH CAP  17 awardees  $29,097,937   Rural Emergency Hospital Conversion /
#                                       Transformative Capital Investment
#   RPGP     22 awardees  $49,915,410   Regional Partnerships Grant Program
#   CHW+AFIM  7 awardees   $1,007,152
#   --------------------------------
#            46 awardees  $80,020,499
#
# THE TEXAS CHECK, RUN FIRST AND PASSED. Session 19's lesson is that "has this
# state published a recipient-level list?" is not the whole question: Texas
# answered yes, twice over, with hospital names and dollar figures, and the
# lists were a state appropriation whose RFAs closed before RHTP existed. So
# before anything was extracted here, two things were established from Kansas's
# own documents:
#
#   1. WHAT FUNDS IT. The award document's own footer states it is "supported
#      by the Centers for Medicare & Medicaid Services (CMS) ... as part of a
#      financial assistance award totaling $221,890,007.82 with 100 percent
#      funded by CMS/HHS". That is RHTP money, said by the awarding agency on
#      the award document. `ks_assert_rhtp_funded()` requires it on every run.
#   2. WHEN. Session 19's cheapest version of the test is release date against
#      the state's CMS Notice of Award, 2025-12-29. KDHE's own RPGP / REH CAP
#      applicant webinar is dated 6 March 2026 and the awards followed it; the
#      CHW+AFIM RFA slides are March 2026 too. Both solicitations opened after
#      Kansas had the money, which is the opposite of Texas's HHS0015180
#      (released 2025-03-24, closed 2025-04-24).
#
# THE POSITIVE CONTROL, WHICH IS WHAT MAKES THE REST OF THE ANSWER MEAN
# ANYTHING. Kansas is still running four more Year 1 programmes -- Emerging
# Technology ($9.5M, applications due 10 July 2026), Interfacility Transport,
# the Evidence-Based Practice programme, and the KHA Healthworks revenue and
# credentialing projects (RFP due 4 August 2026). None of them has a published
# awardee list. On its own, "we found no list" is indistinguishable from "we
# looked for the wrong string" -- so the check is not that the strings are
# absent, it is that KDHE demonstrably publishes a roster IN A RECOGNISABLE
# FORM when it has awarded: two links off the same programme page, one reading
# "Award Winners (PDF)" and one "Award Winners and Project Descriptions". Both
# are asserted PRESENT on the archived page, which is the control; the four
# programmes with no such link are then a real absence, and each has an open or
# just-closed application deadline that says why.
#
# AND THE CONTROL IS A TRIPWIRE IN BOTH DIRECTIONS. `ks_assert_award_index()`
# fails if either known award link disappears (a site redesign that renamed
# them would otherwise turn every future run silently green) and fails if a
# THIRD award-shaped link appears, because at that point Kansas has published a
# pool this file does not carry and the file is stale rather than wrong.
#
# WHAT RCJ GOT WRONG, WHICH IS §0.1 AGAIN AND SMALLER. RCJ holds 45 of the 46
# awards and every amount it holds matches the state document exactly. The one
# it dropped is GREELEY COUNTY HEALTH SERVICES' $458,286 REH CAP award: Greeley
# appears TWICE in the document, once in each pool, and RCJ kept only the
# $1,541,906 RPGP row. Texas's 32-of-33 in a state that is otherwise clean --
# an aggregator that de-duplicates on the recipient loses the second award, and
# nothing about the output looks wrong.
#
# ONE FIGURE IS NOT RECONCILED, DELIBERATELY. KDHE's award document states the
# CMS award as $221,890,007.82; `cms_fy2026_allotments.csv`, parsed from CMS's
# own table, has Kansas at $221,898,008. The two differ by $8,000.18. Both are
# quoted from their publishers and neither is adjusted (§8) -- it is on the
# reconciliation sheet and it is asserted, so a future session meets it rather
# than rediscovering it.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_pdf_text.R"))
# For rhtp_load_allotments() -- the §7.1 CMS anchor, read through the same
# reader Stage 2 uses so the two cannot disagree about Kansas's allotment.
source(here::here("R", "02_normalize.R"))
source(here::here("R", "utils_recipient_classification.R"))

KS_EVIDENCE_DIR   <- here::here("data", "evidence", "KS")
KS_NARRATIVE_DIR  <- here::here("data", "evidence", "budget_narratives", "KS")
KS_CSV            <- "data/reference/ks_year1_awardees.csv"
KS_XLSX           <- "KS_year1_awardees.xlsx"
KS_HOST_THROTTLE_S <- 3
KS_USER_AGENT <- paste(
  "RHTP-Tracker/0.1 (AHA Data & Policy research;",
  "+https://www.aha.org)"
)

KS_PROGRAM_PAGE <- "https://www.kdhe.ks.gov/2361/Rural-Health-Transformation-Program"

KS_SOURCES <- tibble::tribble(
  ~key,          ~url,                                                        ~file,                                              ~dir,              ~reduce,             ~doc_title,
  "program_page", KS_PROGRAM_PAGE,                                            "2026-08-29_kdhe_rhtp_program_page.html",           "KS",             "STRIP_CREDENTIALS", "Rural Health Transformation Program | KDHE",
  "reh_cap_rpgp", "https://www.kdhe.ks.gov/DocumentCenter/View/58981/REH-CAP-and-RPGP-Award-Winners-PDF", "2026-08-29_kdhe_reh_cap_and_rpgp_award_winners.pdf", "KS", "NONE", "REH CAP and RPGP Award Winners",
  "chw_afim",     "https://www.kdhe.ks.gov/DocumentCenter/View/60037/CHW-AFIM-Project-Descriptions",      "2026-08-29_kdhe_chw_afim_project_descriptions.pdf",  "KS", "NONE", "Kansas RHTP Community Health Worker (CHW) + Accountable Food is Medicine (AFIM) Awarded Project Descriptions",
  "budget_rev2",  "https://www.kdhe.ks.gov/DocumentCenter/View/60171",         "2026-07_ks_rht_plan_budget_narrative_revision_2.pdf", "NARRATIVE",   "NONE", "Kansas RHT Plan Year 1 Budget Narrative Revision 2: July 2026"
)

# Every figure below is quoted from a source archived under data/evidence/KS/
# or data/evidence/budget_narratives/KS/, and every one is asserted against the
# parse. They are the reconciliation and they are the tripwire: if KDHE
# republishes with a different count, the assert fails here rather than a wrong
# number reaching a workbook.
KS_STATED <- list(
  reh_cap_n        = 17L,
  reh_cap_total    = 29097937,
  rpgp_n           = 22L,
  rpgp_total       = 49915410,
  chw_afim_n       = 7L,
  chw_afim_total   = 1007152,
  # KDHE's own statement of the CMS award, on the award document's footer.
  cms_award_stated = 221890007.82,
  # CMS's own table, parsed in session 5. The two disagree by $8,000.18.
  cms_allotment    = 221898008,
  # Budget Narrative Revision 2, Table 7 and Table 3: the Year 1 pools the
  # awarded pools sit inside. REH CAP and RPGP are two of Initiative 2's six
  # programmes; CHW+AFIM is Programme 1 of Initiative 1.
  initiative_2_yr1 = "97,263,092.46",
  initiative_1_yr1 = "25,291,240.16",
  # THE FLOOR AND THE UNCERTAINTY. 21 rows classify as named hospitals on the
  # recipient's own name; 22 more are named recipients whose ORGANISATIONAL
  # FORM KDHE nowhere states, and they carry more money than the confirmed
  # figure does. See KS_FORM_NOT_STATED below.
  named_hospital_floor = 35721277,
  form_not_stated_n     = 22L,
  form_not_stated_total = 39249763
)

# WHY KANSAS'S HOSPITAL FIGURE IS A FLOOR, STATED WHERE IT CANNOT BE MISSED.
# KDHE publishes a recipient and an amount and nothing about the recipient's
# form -- no organisation-type column of the kind Oregon and Alaska both have,
# and no "critical access hospital" label except inside a few project
# narratives, where it describes the project rather than the awardee. So
# `rhtp_classify_recipient_type()` falls back to §8's standing answer,
# NONPROFIT_CBO + LOW + RECIPIENT_TYPE_INFERRED, for 22 of the 46 rows.
#
# NOTHING IS OVERRIDDEN HERE, AND THAT IS DELIBERATE. Several of the 22 read
# as hospitals to anyone who knows Kansas -- Stormont Vail Health, AdventHealth
# Ottawa, Labette Health, South Central Kansas Health ("Kansas' first REH", in
# KDHE's own words about the project) -- and several plainly are not: Special
# Olympics Kansas, InterHab, the Kansas Council on Developmental Disabilities.
# Promoting the first group on this pipeline's own knowledge would be exactly
# the §0.4 failure the project exists to avoid, and it would inflate the one
# number AHA will be asked to defend. The resolution is the CCN match (open
# blocker 5, the AHA Annual Survey / CMS Provider of Services extracts), and
# until it lands the 22 sit in data/reference/classification_review_queue.csv
# with their dollars stated.
KS_FORM_NOT_STATED_QUESTION <- "KS_RECIPIENT_FORM_NOT_STATED"

# The two award links that must be on the programme page, and the shape a third
# one would take. See the header: this is the positive control.
KS_AWARD_LINK_MARKERS <- c(
  reh_cap_rpgp = "REH CAP and RPGP Award Winners",
  chw_afim     = "CHW \\+ AFIM Award Winners and Project Descriptions"
)
KS_AWARD_LINK_SHAPE <- "Award Winners|Awarded Project|Awardees|Award Recipients"


# -- fetch -------------------------------------------------------------------

ks_source <- function(key, field) {
  row <- KS_SOURCES[KS_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[KS] unknown source key: ", key, call. = FALSE)
  row[[field]]
}

ks_dir <- function(which) if (identical(which, "NARRATIVE")) KS_NARRATIVE_DIR else KS_EVIDENCE_DIR

ks_archive_path <- function(key) {
  file.path(ks_dir(ks_source(key, "dir")), ks_source(key, "file"))
}

#' Archive the four Kansas sources verbatim, with SHA-256 manifests
#'
#' Bytes go out through `writeBin()` and the digest is of the body the server
#' sent, so re-hashing a file on disk reproduces the manifest (session 12's
#' `writeLines()` off-by-one, kept fixed).
#'
#' THREE OF THE FOUR ARE ARCHIVED WHOLE. The programme page is not, and the
#' guard is why: KDHE's CivicPlus template carries a Google Maps key in a
#' hidden input, `<input id="GoogleMapsKey" value="AIza...">`. That is Kansas's
#' to publish and not ours to redistribute -- the same call §7.1 made for CMS's
#' Mapbox token, session 16 made for Illinois's, and session 17 made for
#' Oregon's. The credential-bearing NODE is removed by name (Illinois's remedy,
#' because no container choice excludes it: the links this file parses run the
#' length of the page), the result is asserted credential-free AFTER reducing,
#' and the full page's digest as served goes in the manifest so provenance
#' still closes.
#'
#' The guard found it on the first fetch. A hand check would have had to know
#' that `id="GoogleMapsKey"` was a thing to look for.
ks_fetch_sources <- function(force = FALSE) {
  dir.create(KS_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  dir.create(KS_NARRATIVE_DIR, recursive = TRUE, showWarnings = FALSE)

  entries <- purrr::map_dfr(seq_len(nrow(KS_SOURCES)), function(i) {
    src  <- KS_SOURCES[i, ]
    dest <- file.path(ks_dir(src$dir), src$file)

    if (file.exists(dest) && !force) {
      # §9.5: a re-run must never re-fetch an unchanged document.
      message("[KS] cached, not re-fetched: ", src$file)
    } else {
      if (i > 1L) Sys.sleep(KS_HOST_THROTTLE_S)
      message("[KS] fetching ", src$url)
      resp <- httr::GET(src$url, httr::user_agent(KS_USER_AGENT),
                        httr::timeout(180))
      if (httr::status_code(resp) != 200L) {
        stop("[KS] HTTP ", httr::status_code(resp), " for ", src$url,
             call. = FALSE)
      }
      served <- httr::content(resp, as = "raw")
      body <- if (identical(src$reduce, "STRIP_CREDENTIALS")) {
        ks_strip_credentials(served)
      } else {
        served
      }
      # Asserted AFTER the reduction, so a reduction that fails to remove the
      # credential is caught rather than trusted.
      ks_assert_credential_free(body, src$file)
      writeBin(body, dest)
      attr(dest, "full_sha256") <- digest::digest(served, algo = "sha256",
                                                  serialize = FALSE)
    }

    tibble::tibble(
      key = src$key, file = src$file, dir = src$dir, url = src$url,
      reduce = src$reduce,
      bytes = file.info(dest)$size,
      sha256 = digest::digest(file = dest, algo = "sha256"),
      full_sha256 = attr(dest, "full_sha256") %||% NA_character_,
      fetched_utc = format(Sys.time(), tz = "UTC", "%Y-%m-%dT%H:%M:%SZ")
    )
  })

  ks_write_manifest(entries %>% dplyr::filter(dir == "KS"), KS_EVIDENCE_DIR)
  ks_write_manifest(entries %>% dplyr::filter(dir == "NARRATIVE"),
                    KS_NARRATIVE_DIR)
  entries
}

#' Remove every node whose attributes carry a credential
#'
#' Node-targeted rather than container-targeted, which is Illinois's remedy: on
#' KDHE the key is in a hidden input in the page chrome, but the links this
#' file reads are spread the length of the document, so there is no `<main>` to
#' retreat to. Matching on token SHAPE means a rotated key is removed too.
ks_strip_credentials <- function(body) {
  doc <- xml2::read_html(rawToChar(body))
  shapes <- paste(KS_CREDENTIAL_SHAPES, collapse = "|")

  nodes <- xml2::xml_find_all(doc, "//*[@*]")
  for (node in nodes) {
    attrs <- xml2::xml_attrs(node)
    if (length(attrs) && any(stringr::str_detect(attrs, shapes))) {
      xml2::xml_remove(node)
    }
  }
  charToRaw(as.character(doc))
}

KS_CREDENTIAL_SHAPES <- c(
  mapbox_token   = "[ps]k\\.ey[A-Za-z0-9_-]{10,}",
  google_api_key = "AIza[A-Za-z0-9_-]{30,}",
  bearer_token   = "(?i)bearer\\s+[A-Za-z0-9._-]{25,}",
  aws_key        = "AKIA[A-Z0-9]{12,}"
)

#' Refuse to archive anything carrying a credential (§7.1, sessions 14/16/17)
ks_assert_credential_free <- function(body, label) {
  chunk <- body[seq_len(min(length(body), 4e6))]
  txt   <- rawToChar(chunk[chunk != as.raw(0)])
  Encoding(txt) <- "latin1"

  patterns <- KS_CREDENTIAL_SHAPES
  for (nm in names(patterns)) {
    if (stringr::str_detect(txt, patterns[[nm]])) {
      stop("[KS] refusing to archive ", label, ": it carries what looks like a ",
           nm, ".", call. = FALSE)
    }
  }
  invisible(TRUE)
}

ks_write_manifest <- function(entries, dir) {
  if (nrow(entries) == 0L) return(invisible(NULL))
  path <- file.path(dir, "MANIFEST.txt")
  writeLines(c(
    "Kansas Department of Health and Environment -- RHTP Year 1 sources",
    "Archived by R/03o_ks_year1_awardees.R --fetch",
    paste0("User-agent: ", KS_USER_AGENT),
    "",
    "The two award PDFs and the budget narrative are the body the server sent,",
    "byte for byte. THE PROGRAMME PAGE IS A REDUCTION: KDHE's CivicPlus",
    "template carries a Google Maps API key in a hidden input, which is",
    "Kansas's to publish and not ours to redistribute (§7.1's posture, as",
    "applied to CMS, Illinois and Oregon). The credential-bearing node is",
    "removed by name and the full page's digest as served is recorded below, so",
    "provenance still closes; the reduction removes nothing this repo parses.",
    "Files are written with writeBin(), so re-hashing a file on disk reproduces",
    "its digest below.",
    "",
    "MANIFEST.txt is deliberately absent from this listing: a manifest cannot",
    "record its own digest (session 15).",
    "",
    paste0(entries$sha256, "  ", entries$file, "  (", entries$bytes,
           " bytes, reduce=", entries$reduce, ")  <- ", entries$url,
           ifelse(is.na(entries$full_sha256), "",
                  paste0("\n    full page as served: ", entries$full_sha256)))
  ), path)
  invisible(path)
}


# -- the positive control ----------------------------------------------------

ks_program_page_text <- function() {
  path <- ks_archive_path("program_page")
  if (!file.exists(path)) {
    stop("[KS] the programme page is not archived. Run --fetch.", call. = FALSE)
  }
  doc <- xml2::read_html(path)
  tibble::tibble(
    href = xml2::xml_attr(xml2::xml_find_all(doc, "//a"), "href"),
    text = stringr::str_squish(
      xml2::xml_text(xml2::xml_find_all(doc, "//a")))
  ) %>%
    dplyr::filter(!is.na(text), nzchar(text))
}

#' The control: KDHE publishes a roster in a recognisable form when it awards
#'
#' Both known award documents must still be linked from the programme page, and
#' no THIRD award-shaped link may have appeared. The first half stops a site
#' redesign from turning a negative silently green; the second half stops this
#' file quietly ceasing to cover Kansas.
ks_assert_award_index <- function(links = NULL) {
  if (is.null(links)) links <- ks_program_page_text()

  for (nm in names(KS_AWARD_LINK_MARKERS)) {
    if (!any(stringr::str_detect(links$text, KS_AWARD_LINK_MARKERS[[nm]]))) {
      stop(
        "[KS] the programme page no longer links '", nm, "'.\n",
        "That link is this file's POSITIVE CONTROL: it is what makes 'the ",
        "other four programmes have published no roster' a finding rather ",
        "than a failed search. Re-read the page before trusting any negative.",
        call. = FALSE
      )
    }
  }

  award_shaped <- links %>%
    dplyr::filter(stringr::str_detect(text, KS_AWARD_LINK_SHAPE))
  known <- paste(KS_AWARD_LINK_MARKERS, collapse = "|")
  unknown <- award_shaped %>%
    dplyr::filter(!stringr::str_detect(text, known))

  if (nrow(unknown) > 0) {
    stop(
      "[KS] the programme page links an award document this file does not ",
      "carry:\n",
      paste0("  ", unknown$text, "  -> ", unknown$href, collapse = "\n"),
      "\nKansas has published a pool beyond REH CAP, RPGP and CHW+AFIM. ",
      "Extract it; do not widen this assertion.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}


# -- parse -------------------------------------------------------------------

#' Join PDF lines back into running text without losing a wrapped word
#'
#' KDHE wraps mid-word -- "Citizens Foundat" / "ion: $146,476" -- so joining
#' every line with a space produces "Citizens Foundat ion", which would then be
#' the recipient name written into a published file. Lines are joined WITHOUT a
#' separator when the previous ends in a letter and the next begins with a
#' lowercase letter, which is the shape of a mid-word wrap and not the shape of
#' a sentence boundary; every other pair keeps its space.
ks_join_lines <- function(lines) {
  if (length(lines) == 0L) return("")
  out <- lines[1]
  for (i in seq_along(lines)[-1]) {
    prev <- out
    nxt  <- lines[i]
    mid_word <- stringr::str_detect(prev, "[A-Za-z]$") &&
      stringr::str_detect(nxt, "^[a-z]")
    out <- paste0(prev, if (mid_word) "" else " ", nxt)
  }
  stringr::str_squish(out)
}

ks_document_text <- function(key) {
  path <- ks_archive_path(key)
  if (!file.exists(path)) {
    stop("[KS] '", key, "' is not archived. Run --fetch.", call. = FALSE)
  }
  rhtp_pdf_text(path)
}

#' The award pattern KDHE uses in both documents: "• <recipient>: $<amount>"
KS_AWARD_RX <- "•\\s*(.{3,140}?):\\s*\\$([0-9][0-9,]*(?:\\.[0-9]+)?)"

#' Parse the REH CAP + RPGP award winners document
#'
#' One document, TWO POOLS, each introduced by its own heading. The pool is
#' assigned by position relative to the RPGP heading rather than by anything
#' about the awardee, because Greeley County Health Services appears in both and
#' any recipient-keyed split would have to choose one.
ks_parse_reh_cap_rpgp <- function(text = NULL) {
  if (is.null(text)) text <- ks_document_text("reh_cap_rpgp")
  one <- ks_join_lines(text)

  rpgp_head <- stringr::str_locate(
    one, "The 2026 Regional Partnerships Grant Program \\(RPGP\\) Awardees are")
  reh_head <- stringr::str_locate(
    one, "The 2026 Rural Emergency Hospital Conversion and Transformative")

  if (any(is.na(rpgp_head)) || any(is.na(reh_head))) {
    stop("[KS] the award document no longer carries both pool headings. ",
         "Re-read it; the pool split below is positional.", call. = FALSE)
  }
  if (reh_head[1, "start"] >= rpgp_head[1, "start"]) {
    stop("[KS] the two pool headings have swapped order in the document. ",
         "The positional split would mis-assign every row.", call. = FALSE)
  }

  m   <- stringr::str_match_all(one, KS_AWARD_RX)[[1]]
  loc <- stringr::str_locate_all(one, KS_AWARD_RX)[[1]]

  tibble::tibble(
    award_pool = ifelse(loc[, "start"] > rpgp_head[1, "start"], "RPGP", "REH_CAP"),
    awardee    = stringr::str_squish(m[, 2]),
    amount     = as.numeric(gsub(",", "", m[, 3])),
    description = ks_award_descriptions(one, loc)
  )
}


#' KDHE's own paragraph about each award
#'
#' Everything between one award's amount and the next award's bullet. This is
#' what goes to `rhtp_classify_flow()`, and the choice matters: an earlier
#' draft passed the POOL's name instead, and because the REH CAP pool is called
#' "Rural Emergency Hospital Conversion ...", every unrecognised recipient in
#' it came out `IN_KIND_BENEFIT` -- the §6.2 in-kind rule firing on the pool's
#' own title. That is §0.3a exactly: the coding was reading the activity, and
#' the activity was one this file had written itself.
ks_award_descriptions <- function(one, loc) {
  n <- nrow(loc)
  vapply(seq_len(n), function(i) {
    from <- loc[i, "end"] + 1L
    to   <- if (i < n) loc[i + 1L, "start"] - 1L else nchar(one)
    if (to < from) return("")
    ks_repair_wrap(substr(one, from, to))
  }, character(1))
}

#' Undo the PDF's line-wrap artefacts in a description
#'
#' KDHE's PDF breaks hyphenated words across lines, so the extractor emits
#' "dual - purpose" and "hub - and - spoke". Applied to DESCRIPTIONS ONLY --
#' never to a recipient name, which is published and where §8 says keep the
#' source's language. No recipient name in either document carries the
#' artefact, and an assertion holds that.
ks_repair_wrap <- function(x) {
  x <- stringr::str_remove(x, "^\\s*\\d*\\s*o\\s+")   # leading page no. + sub-bullet
  x <- stringr::str_replace_all(x, "(?<=[A-Za-z0-9]) - (?=[a-z0-9])", "-")
  stringr::str_squish(x)
}

#' Parse the CHW + AFIM awarded project descriptions
ks_parse_chw_afim <- function(text = NULL) {
  if (is.null(text)) text <- ks_document_text("chw_afim")
  one <- ks_join_lines(text)

  m   <- stringr::str_match_all(one, KS_AWARD_RX)[[1]]
  loc <- stringr::str_locate_all(one, KS_AWARD_RX)[[1]]

  tibble::tibble(
    award_pool = "CHW_AFIM",
    awardee    = stringr::str_squish(m[, 2]),
    amount     = as.numeric(gsub(",", "", m[, 3])),
    description = ks_award_descriptions(one, loc)
  )
}

#' KDHE's own statement of what funds these awards -- the Texas check
#'
#' The award document's footer names CMS/HHS and the award total. If it ever
#' stops doing so, this file has lost the evidence that Kansas's awards are
#' RHTP at all, and that is a hard stop rather than a warning.
ks_assert_rhtp_funded <- function(text = NULL) {
  if (is.null(text)) text <- ks_document_text("reh_cap_rpgp")
  one <- ks_join_lines(text)

  if (!stringr::str_detect(
    one, "Centers for Medicare & Medicaid Services \\(CMS\\)")) {
    stop("[KS] the award document no longer names CMS as the funder.",
         call. = FALSE)
  }
  if (!stringr::str_detect(one, "100 percent funded by CMS/HHS")) {
    stop("[KS] the award document no longer states 100 percent CMS/HHS ",
         "funding. Without it these awards are not established as RHTP ",
         "money -- which is exactly what Texas's HHSC awards looked like ",
         "until somebody read the funding source (§0.1, session 19).",
         call. = FALSE)
  }
  stated <- stringr::str_match(
    one, "financial assistance award totaling \\$([0-9][0-9,]*\\.[0-9]{2})")[, 2]
  if (is.na(stated)) {
    stop("[KS] the award document no longer states the CMS award total.",
         call. = FALSE)
  }
  invisible(as.numeric(gsub(",", "", stated)))
}


# -- assemble ----------------------------------------------------------------

#' The 46 Kansas Year 1 award actions, in the §8 union schema
rhtp_ks_year1_awardees <- function() {
  awards <- dplyr::bind_rows(ks_parse_reh_cap_rpgp(), ks_parse_chw_afim())

  pool_meta <- tibble::tribble(
    ~award_pool, ~source_document_title,                                  ~source_key,
    "REH_CAP",   "REH CAP and RPGP Award Winners",                        "reh_cap_rpgp",
    "RPGP",      "REH CAP and RPGP Award Winners",                        "reh_cap_rpgp",
    "CHW_AFIM",  paste("Kansas RHTP Community Health Worker (CHW) +",
                       "Accountable Food is Medicine (AFIM) Awarded",
                       "Project Descriptions"),                           "chw_afim"
  )

  out <- awards %>%
    dplyr::left_join(pool_meta, by = "award_pool") %>%
    dplyr::mutate(state = "KS")

  out <- rhtp_classify_records(out, state = "KS", description_col = "description")

  out %>%
    dplyr::mutate(
      row_no                 = dplyr::row_number(),
      note                   = paste0(
        "KDHE ", award_pool, " award. ", determination_basis),
      recipient_confirmed    = "Yes",
      # KDHE publishes these as awards, not as intents: the document is headed
      # "Awardees are" and prints a figure per recipient. Nothing in it calls
      # the amounts estimates, offers or subject to negotiation, which is the
      # language Oregon's seven pools all carry.
      amount_confirmed       = "Yes",
      fiscal_year            = "FY2026",
      state_source_url       = KS_PROGRAM_PAGE,
      validation_source_type = "NOTICE_OF_AWARD",
      extraction_method      = "DIRECT_TEXT",
      validator              = "AUTO",
      ccn                    = NA_character_,
      aha_id                 = NA_character_,
      rural_designation      = NA_character_,
      reviewer               = NA_character_,
      source_archive_path    = file.path(
        "data/evidence/KS", purrr::map_chr(source_key, ~ ks_source(.x, "file"))),
      hospital_attribution   = rhtp_hospital_attribution(
        flow_type, distributed_to_hospital, recipient_type)
    ) %>%
    dplyr::select(
      state, row_no, awardee, amount, recipient_type,
      distributed_to_hospital, note, recipient_confirmed, amount_confirmed,
      fiscal_year, source_document_title, state_source_url,
      validation_source_type, extraction_method, validator, ccn, aha_id,
      rural_designation, reviewer,
      # Kansas's own columns, after the leading 19.
      award_pool, flow_type, hospital_benefiting, hospital_attribution,
      determination_confidence, determination_basis, classification_rule,
      flag_reason, source_archive_path
    )
}


# -- reconciliation ----------------------------------------------------------

rhtp_ks_reconcile <- function(awards = NULL) {
  if (is.null(awards)) awards <- rhtp_ks_year1_awardees()

  by_pool <- awards %>%
    dplyr::group_by(award_pool) %>%
    dplyr::summarise(n = dplyr::n(), total = sum(amount), .groups = "drop")

  allotments <- rhtp_load_allotments()
  ks_allot <- allotments$fy2026_allotment[allotments$state == "KS"]

  list(
    by_pool        = by_pool,
    awards_n       = nrow(awards),
    awards_total   = sum(awards$amount),
    cms_award_stated = KS_STATED$cms_award_stated,
    cms_allotment  = ks_allot,
    publisher_gap  = ks_allot - KS_STATED$cms_award_stated,
    share_of_allotment = sum(awards$amount) / ks_allot
  )
}


# -- assertions --------------------------------------------------------------

rhtp_ks_assert <- function(awards = NULL) {
  if (is.null(awards)) awards <- rhtp_ks_year1_awardees()

  # 1. The Texas check. Run first, because if it fails nothing below matters.
  stated <- ks_assert_rhtp_funded()
  stopifnot(identical(stated, KS_STATED$cms_award_stated))

  # 2. The positive control.
  ks_assert_award_index()

  # 3. Counts and totals, against KDHE's own documents.
  rec <- rhtp_ks_reconcile(awards)
  pool <- stats::setNames(rec$by_pool$n, rec$by_pool$award_pool)
  tot  <- stats::setNames(rec$by_pool$total, rec$by_pool$award_pool)

  stopifnot(pool[["REH_CAP"]]  == KS_STATED$reh_cap_n)
  stopifnot(pool[["RPGP"]]     == KS_STATED$rpgp_n)
  stopifnot(pool[["CHW_AFIM"]] == KS_STATED$chw_afim_n)
  stopifnot(tot[["REH_CAP"]]   == KS_STATED$reh_cap_total)
  stopifnot(tot[["RPGP"]]      == KS_STATED$rpgp_total)
  stopifnot(tot[["CHW_AFIM"]]  == KS_STATED$chw_afim_total)
  stopifnot(rec$awards_n == 46L)
  stopifnot(rec$awards_total == KS_STATED$reh_cap_total +
              KS_STATED$rpgp_total + KS_STATED$chw_afim_total)

  # 4. No award exceeds the state allotment, and none is implausible (§6.2).
  stopifnot(all(awards$amount > 0))
  stopifnot(all(awards$amount < rec$cms_allotment))

  # 5. THE TWO PUBLISHERS DISAGREE, AND THAT IS PINNED RATHER THAN CLOSED.
  #    KDHE says $221,890,007.82; CMS's own table says $221,898,008.
  stopifnot(abs(rec$publisher_gap - 8000.18) < 0.005)

  # 6. Greeley County Health Services holds TWO awards, one per pool. This is
  #    the row RCJ dropped, and a parser that de-duplicated on the recipient
  #    would drop it here too.
  greeley <- awards %>%
    dplyr::filter(stringr::str_detect(awardee, "Greeley County Health"))
  stopifnot(nrow(greeley) == 2L)
  stopifnot(setequal(greeley$award_pool, c("REH_CAP", "RPGP")))
  stopifnot(setequal(greeley$amount, c(458286, 1541906)))

  # 7. No recipient name carries a mid-word wrap. "Citizens Foundat ion" is
  #    what an unguarded line join produces, and it would be published.
  stopifnot(!any(stringr::str_detect(awards$awardee, "Foundat ion")))
  stopifnot(!any(stringr::str_detect(awards$awardee, "[a-z] [a-z]{1,3}$")))

  # 8. THE FLOOR AND WHAT IS UNDER IT. Both are asserted, so a future change to
  #    the shared classifier that silently moves Kansas dollars into or out of
  #    the hospital total fails here.
  partition <- rhtp_hospital_dollar_partition(awards)
  named <- partition$dollars[partition$bucket == "NAMED_HOSPITAL"]
  stopifnot(length(named) == 1L, named == KS_STATED$named_hospital_floor)
  stopifnot(!"POOL_UNNAMED_HOSPITALS" %in% partition$bucket)

  inferred <- awards %>%
    dplyr::filter(determination_confidence == "LOW",
                  flag_reason == "RECIPIENT_TYPE_INFERRED")
  stopifnot(nrow(inferred) == KS_STATED$form_not_stated_n)
  stopifnot(sum(inferred$amount) == KS_STATED$form_not_stated_total)

  # And the queue actually carries the question, because a disclosure nobody
  # can find is not a disclosure.
  queue <- readr::read_csv(
    here::here("data/reference/classification_review_queue.csv"),
    show_col_types = FALSE, progress = FALSE)
  stopifnot(KS_FORM_NOT_STATED_QUESTION %in% queue$question_id)

  # 9. Vocabulary (§8).
  for (col in c("recipient_type", "distributed_to_hospital", "flow_type",
                "determination_confidence", "extraction_method", "validator",
                "recipient_confirmed", "amount_confirmed",
                "hospital_attribution")) {
    vals <- unique(stats::na.omit(awards[[col]]))
    bad  <- setdiff(vals, rhtp_vocabulary(col))
    if (length(bad)) {
      stop("[KS] ", col, " outside §8: ", paste(bad, collapse = ", "),
           call. = FALSE)
    }
  }
  # validation_source_type is checked against `source_doc_type`, which is
  # where §8 keeps the document-strength ordering (Oregon's convention).
  bad <- setdiff(unique(stats::na.omit(awards$validation_source_type)),
                 rhtp_vocabulary("source_doc_type"))
  if (length(bad)) {
    stop("[KS] validation_source_type outside §8: ",
         paste(bad, collapse = ", "), call. = FALSE)
  }

  flags <- unique(stats::na.omit(awards$flag_reason))
  bad <- setdiff(flags, rhtp_vocabulary("flag_reason"))
  if (length(bad)) {
    stop("[KS] flag_reason outside the vocabulary: ",
         paste(bad, collapse = ", "), call. = FALSE)
  }

  # 10. The archive verifies: every digest in the manifest re-computes.
  for (dir in c(KS_EVIDENCE_DIR, KS_NARRATIVE_DIR)) {
    man <- file.path(dir, "MANIFEST.txt")
    if (!file.exists(man)) next
    for (ln in grep("^[0-9a-f]{64}  ", readLines(man), value = TRUE)) {
      p <- file.path(dir, sub("^[0-9a-f]{64}  ([^ ]+).*$", "\\1", ln))
      d <- sub("^([0-9a-f]{64}).*$", "\\1", ln)
      if (file.exists(p)) {
        stopifnot(identical(digest::digest(file = p, algo = "sha256"), d))
      }
    }
  }

  invisible(TRUE)
}

#' What RCJ holds against what Kansas published -- §0.1, reported not trusted
rhtp_ks_rcj_gap <- function(awards = NULL) {
  if (is.null(awards)) awards <- rhtp_ks_year1_awardees()

  rt_path <- here::here("data/interim/stage2_record_table.rds")
  if (!file.exists(rt_path)) return(NULL)

  rcj <- readRDS(rt_path) %>%
    dplyr::filter(state == "KS", award_tier == "SUBAWARD",
                  stringr::str_detect(dplyr::coalesce(source_doc_title, ""),
                                      "RPGP|CHW"))

  list(
    state_rows = nrow(awards),
    rcj_rows   = nrow(rcj),
    missing    = awards %>%
      dplyr::filter(!amount %in% rcj$amount_announced) %>%
      dplyr::select(awardee, amount, award_pool),
    amounts_agree = all(rcj$amount_announced %in% awards$amount)
  )
}


# -- write -------------------------------------------------------------------

rhtp_ks_write <- function() {
  awards <- rhtp_ks_year1_awardees()
  rhtp_ks_assert(awards)

  readr::write_csv(awards, here::here(KS_CSV), na = "")
  message("[KS] wrote ", nrow(awards), " award actions -> ", KS_CSV)

  rec <- rhtp_ks_reconcile(awards)
  gap <- rhtp_ks_rcj_gap(awards)

  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "Read me first")
  openxlsx::writeData(wb, "Read me first", tibble::tibble(
    `Read this before using any figure` = c(
      paste0("Kansas Year 1: 46 award actions, $",
             format(rec$awards_total, big.mark = ",", scientific = FALSE),
             ", across THREE pools KDHE published in TWO documents."),
      "",
      "READ `award_pool` BEFORE USING ANY FIGURE. REH CAP is capital and",
      "conversion money to hospitals; RPGP is regional partnership money whose",
      "recipients include colleges, behavioural health centres and disability",
      "organisations; CHW+AFIM is a $1,007,152 community health worker pool.",
      "",
      "GREELEY COUNTY HEALTH SERVICES HOLDS TWO AWARDS, one in each of the",
      "first two pools ($458,286 and $1,541,906). They are two award actions",
      "and must not be merged.",
      "",
      "THE TWO PUBLISHERS DISAGREE ABOUT KANSAS'S CMS AWARD. KDHE's award",
      "document states $221,890,007.82; CMS's own allotment table states",
      "$221,898,008. The $8,000.18 gap is reported, not resolved (§8).",
      "",
      "KANSAS HAS NOT FINISHED AWARDING. Four more Year 1 programmes --",
      "Emerging Technology ($9.5M), Interfacility Transport, Evidence-Based",
      "Practice, and the KHA Healthworks revenue and credentialing projects --",
      "had no published awardee list when this was extracted. Their",
      "application deadlines (10 July and 4 August 2026) are why.",
      "",
      paste0("THE HOSPITAL FIGURE IS A FLOOR: $",
             format(KS_STATED$named_hospital_floor, big.mark = ",",
                    scientific = FALSE),
             " across 21 named hospitals."),
      paste0("A FURTHER ", KS_STATED$form_not_stated_n, " ROWS, $",
             format(KS_STATED$form_not_stated_total, big.mark = ",",
                    scientific = FALSE),
             ", ARE NAMED RECIPIENTS WHOSE FORM KDHE"),
      "NOWHERE STATES -- more money than the confirmed figure. They are coded",
      "NONPROFIT_CBO + LOW + RECIPIENT_TYPE_INFERRED (§8's standing answer) and",
      "queued as KS_RECIPIENT_FORM_NOT_STATED. Nothing was promoted on this",
      "pipeline's own knowledge; the CCN match resolves them.",
      "",
      paste0("RCJ HOLDS ", gap$rcj_rows, " OF THESE ", gap$state_rows,
             " AWARDS. Every amount it holds matches the state"),
      "document exactly; the one it dropped is Greeley County's REH CAP award,",
      "because Greeley appears twice and RCJ kept one row (§0.1)."
    )
  ))
  openxlsx::addWorksheet(wb, "Awards")
  openxlsx::writeData(wb, "Awards", awards)
  openxlsx::addWorksheet(wb, "Reconciliation")
  openxlsx::writeData(wb, "Reconciliation", rec$by_pool)
  openxlsx::saveWorkbook(wb, here::here(KS_XLSX), overwrite = TRUE)
  message("[KS] wrote ", KS_XLSX)

  invisible(awards)
}


rhtp_ks_report <- function() {
  awards <- rhtp_ks_year1_awardees()
  rec    <- rhtp_ks_reconcile(awards)
  gap    <- rhtp_ks_rcj_gap(awards)

  message("")
  message("=== Kansas Year 1 ===")
  print(as.data.frame(rec$by_pool), row.names = FALSE)
  message("Total: ", rec$awards_n, " award actions, $",
          format(rec$awards_total, big.mark = ",", scientific = FALSE),
          "  (", round(100 * rec$share_of_allotment, 1),
          "% of the CMS allotment)")
  message("")
  message("CMS award, as KDHE states it : $",
          format(rec$cms_award_stated, big.mark = ",", nsmall = 2,
                 scientific = FALSE))
  message("CMS award, as CMS states it  : $",
          format(rec$cms_allotment, big.mark = ",", scientific = FALSE),
          "   (gap $", format(rec$publisher_gap, nsmall = 2), ", reported)")
  message("")
  message("Hospital dollars (A FLOOR -- read the next line):")
  print(rhtp_hospital_dollar_partition(awards))
  inferred <- awards %>%
    dplyr::filter(determination_confidence == "LOW",
                  flag_reason == "RECIPIENT_TYPE_INFERRED")
  message("Named recipients whose FORM KDHE does not state: ", nrow(inferred),
          " rows, $",
          format(sum(inferred$amount), big.mark = ",", scientific = FALSE),
          " -- more than the figure above. Queued as ",
          KS_FORM_NOT_STATED_QUESTION, ".")
  message("")
  message("RCJ holds ", gap$rcj_rows, " of ", gap$state_rows,
          " awards; amounts agree: ", gap$amounts_agree)
  if (nrow(gap$missing)) {
    message("RCJ dropped:")
    print(as.data.frame(gap$missing), row.names = FALSE)
  }
  invisible(awards)
}


# --- CLI --------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) {
    e <- ks_fetch_sources(force = "--force" %in% args)
    print(as.data.frame(e[, c("file", "bytes", "sha256")]))
  } else if ("--validate" %in% args) {
    rhtp_ks_assert()
    message("[KS] all assertions pass.")
  } else if ("--build" %in% args) {
    rhtp_ks_write()
    rhtp_ks_report()
  } else if ("--report" %in% args) {
    rhtp_ks_report()
  } else {
    message("Usage: Rscript R/03o_ks_year1_awardees.R ",
            "[--fetch [--force] | --validate | --build | --report]")
  }
}
