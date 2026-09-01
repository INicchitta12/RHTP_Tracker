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
#   1. WHAT FUNDS IT -- REWIRED IN SESSION 28, AND THIS IS THE IMPORTANT PART
#      OF THIS FILE'S HISTORY. Until then the only thing tying these 46 awards
#      to RHTP in code was the award PDF's footer, "This PRESENTATION is
#      supported by the Centers for Medicare & Medicaid Services (CMS) ... as
#      part of a financial assistance award totaling $221,890,007.82". Session
#      27's audit found that Kansas was the one state where that was
#      load-bearing -- 98.7% of its dollars -- and that the footer is the WEAK
#      grammatical form: its subject is the slide deck, not the grants. The
#      award document contains ZERO occurrences of "RHTP" and zero of "Rural
#      Health Transformation". Nevada is where that stopped being pedantic
#      (session 26): the same footer sat on a deck describing two STATE-funded
#      programmes worth $15.8M and $60M.
#
#      Provenance now runs through `ks_assert_rhtp_provenance()`, on two
#      INDEPENDENT, PROGRAMME-SCOPED sources that were already committed here
#      and simply unread:
#
#        - KDHE's PROGRAMME PAGE, whose sentences take the GRANTS as their
#          subject: the RPGP and REH/CAP recipients are awarded "through the
#          Kansas Rural Health Transformation Program (RHTP)", and CHW+AFIM is
#          "an initiative within" it. The page also states each pool's scale
#          independently of the award PDFs -- 39 organizations / $79.1 million,
#          and seven / $1,007,152.
#        - The KANSAS RHT PLAN YEAR 1 BUDGET NARRATIVE, registered in
#          KS_SOURCES as `budget_rev2` since session 20 and never opened. It
#          places all three awarded pools inside the plan's own initiative
#          structure and carries NO CMS footer at all, because the document is
#          the plan.
#
#      The footer still runs and now corroborates the AMOUNT only. NO KANSAS
#      DOLLAR MOVED when this changed, and none was ever in doubt.
#   2. WHEN. Session 19's cheapest version of the test is release date against
#      the state's CMS Notice of Award, 2025-12-29 -- and Kansas was the only
#      one of the five footer states with no assertion for it. There is one
#      now, and it reads from KDHE's own Year One Timeline ("Dec. 29, 2025 -
#      Notice of Award") rather than from a typed constant, cross-checked
#      against `cms_state_noa_dates.csv`. KDHE's RPGP / REH CAP applicant
#      webinar is dated 6 March 2026 and the awards followed it; the CHW+AFIM
#      RFA slides are March 2026 too. Both solicitations opened after Kansas
#      had the money, which is the opposite of Texas's HHS0015180 (released
#      2025-03-24, closed 2025-04-24).
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
# ONE FIGURE WAS NOT RECONCILED AND NOW LARGELY IS -- BY READING, NOT BY
# ADJUSTING. Session 20 recorded that "two publishers disagree about Kansas's
# award": KDHE's award document says $221,890,007.82 and CMS's own table says
# $221,898,008, a gap of $8,000.18. Wiring the provenance above meant reading
# KDHE's OTHER TWO publications for the first time, and both say
# $221,898,007.82 -- CMS's figure to the cent. So KDHE and CMS agree; the
# AWARD SLIDE DECK ALONE transposes 898 as 890. Nothing is corrected (§8): the
# deck still says what it says, all three figures are on the reconciliation,
# and the assertion now pins the deck's $8,000.18 AND the $0.18 everywhere
# else. No award amount is affected in either reading.

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
  # THE SAME FIGURE ON KDHE'S OTHER TWO PUBLICATIONS, both read for the first
  # time in session 28 while wiring the provenance below. The programme page's
  # footer and the budget narrative's Table 1 both say $221,898,007.82, which
  # is CMS's own table to the cent once rounded. So KDHE and CMS DO NOT
  # disagree: two of KDHE's three publications and CMS all agree, and the award
  # slide deck alone carries a transposed digit (890 for 898). That is
  # reported, not corrected -- the deck still says what it says (§8) and no
  # award amount is affected either way.
  kdhe_award_page      = 221898007.82,
  kdhe_award_narrative = 221898007.82,
  # CMS's own table, parsed in session 5.
  cms_allotment    = 221898008,
  # Kansas's own Notice of Award date, published on KDHE's Year One Timeline
  # and matching cms_state_noa_dates.csv exactly.
  noa_date         = "2025-12-29",
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

# KANSAS'S PROVENANCE, AND WHY IT IS NOT THE FOOTER ANY MORE.
#
# Session 27 audited every state that used the CMS financial-assistance footer
# as its §6.2 check and found the axis nobody had recorded: the footer's
# grammatical SUBJECT. "This Rural Health Transformation Program is supported
# by CMS" is a claim about the programme; "This PRESENTATION is supported by
# CMS" is a claim about the paper, and Nevada is where the difference was
# measured -- NVHA's workforce deck carries that footer on every page while
# describing GME ("Source: State General Fund") and SHARP (an SB5
# appropriation) beside one RHTP programme.
#
# KANSAS WAS THE ONE LOAD-BEARING CASE. Its REH CAP / RPGP award PDF opens
# "This presentation is supported by", contains ZERO occurrences of "RHTP" and
# zero of "Rural Health Transformation", and `ks_assert_rhtp_funded()` read
# that string and nothing else -- for 39 of 46 rows, $79,013,347, 98.7% of
# Kansas's dollars and 98.4% of its named-hospital floor.
#
# NO KANSAS DOLLAR WAS EVER IN DOUBT. Two independent, PROGRAMME-SCOPED
# sources were already in the committed archive and simply unread, and they are
# what the strings below assert:
#
#   1. THE PROGRAMME PAGE says the awards are RHTP with the grants as the
#      sentence's subject -- "the recipients of the RPGP and REH/CAP grants
#      through the Kansas Rural Health Transformation Program (RHTP)" and
#      "CHW+AFIM, an initiative within the Rural Health Transformation Program
#      (RHTP)" -- and states each pool's count and total independently of the
#      award PDFs.
#   2. THE YEAR 1 BUDGET NARRATIVE (registered as `budget_rev2` since session
#      20, never opened) places all three pools inside the RHT Plan's own
#      initiative structure. It carries no CMS footer at all; it does not need
#      one, because the document IS the plan.
#
# The footer still runs, and now corroborates the AMOUNT only. A KDHE re-post
# that dropped the deck's boilerplate can no longer hard-fail Kansas for no
# reason -- and, the direction that matters more, a future state whose ONLY
# evidence is a "this publication" footer does not pass the test Kansas passes.
KS_PROVENANCE <- list(
  page = c(
    reh_cap_rpgp_programme = paste(
      "grants through the Kansas Rural Health Transformation Program (RHTP)"),
    reh_cap_rpgp_scale     = paste(
      "$79.1 million is being awarded to 39 organizations"),
    chw_afim_programme     = paste(
      "an initiative within the Rural Health Transformation Program (RHTP)"),
    chw_afim_scale         = paste(
      "$1,007,152 was awarded to seven rural healthcare organizations"),
    cms_award_total        = "$221,898,007.82"
  ),
  narrative = c(
    plan_title      = "Kansas RHT Plan Year 1 Budget Narrative",
    initiative_1_p1 = paste(
      "Program 1: Accountable Food Is Medicine and Community Health Worker",
      "(CHW) Deployment Program (A-FIM)"),
    initiative_2_p1 = "Program 1: Regional Partnership Grant Program (RPGP)",
    initiative_2_p2 = paste(
      "REH Conversion/Transformative Capital Investment Grant Program"),
    initiative_1_yr1 = "$25,291,240.16",
    initiative_2_yr1 = "$97,263,092.46",
    cms_award_total  = "$221,898,007.82"
  ),
  # KDHE's own Year One Timeline, which is where the date test now reads from.
  noa_line = "Dec. 29, 2025 - Notice of Award"
)

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

#' The CMS financial-assistance footer on the award document -- CORROBORATING
#'
#' KEPT, AND DELIBERATELY NO LONGER THE PROVENANCE. Session 27's audit found
#' this footer load-bearing for 98.7% of Kansas's dollars, and found it to be
#' the WEAK grammatical form: its subject is "This presentation", so it is a
#' claim about the slide deck and not about the grants printed on it. Nevada is
#' where that distinction stopped being pedantic -- NVHA's workforce deck
#' carries the identical footer while describing two STATE-funded programmes
#' worth $15.8M and $60M beside one RHTP one (session 26).
#'
#' The award document also contains ZERO occurrences of "RHTP" and zero of
#' "Rural Health Transformation": read alone it never names the programme its
#' awards belong to. So provenance now runs through
#' `ks_assert_rhtp_provenance()`, which requires two independent
#' PROGRAMME-SCOPED sources, and this function's job shrinks to corroborating
#' the AMOUNT and reporting what the footer says. A KDHE re-post that dropped
#' the deck's footer no longer hard-fails Kansas for no reason; it returns NA
#' and the caller says so.
ks_assert_rhtp_funded <- function(text = NULL, strict = TRUE) {
  if (is.null(text)) text <- ks_document_text("reh_cap_rpgp")
  one <- ks_join_lines(text)

  missing <- character(0)
  if (!stringr::str_detect(
    one, "Centers for Medicare & Medicaid Services \\(CMS\\)")) {
    missing <- c(missing, "the CMS funder line")
  }
  if (!stringr::str_detect(one, "100 percent funded by CMS/HHS")) {
    missing <- c(missing, "the 100 percent CMS/HHS line")
  }
  stated <- stringr::str_match(
    one, "financial assistance award totaling \\$([0-9][0-9,]*\\.[0-9]{2})")[, 2]
  if (is.na(stated)) missing <- c(missing, "the stated award total")

  if (length(missing) > 0) {
    msg <- paste0(
      "[KS] the award document no longer carries ",
      paste(missing, collapse = ", "), ". This is the CORROBORATING check, ",
      "not the provenance one: Kansas's RHTP status rests on ",
      "ks_assert_program_page_provenance() and ",
      "ks_assert_narrative_places_pools(), which are programme-scoped and ",
      "unaffected. Re-read the document before changing anything."
    )
    if (strict) stop(msg, call. = FALSE) else message(msg)
    return(invisible(NA_real_))
  }
  invisible(as.numeric(gsub(",", "", stated)))
}


# -- provenance: the two INDEPENDENT, PROGRAMME-SCOPED sources ---------------

#' The programme page as running prose, not as a link list
#'
#' `ks_program_page_text()` returns anchors, which is what the positive control
#' needs. The provenance sentences are in the body copy, so they need the text.
ks_program_page_prose <- function() {
  path <- ks_archive_path("program_page")
  if (!file.exists(path)) {
    stop("[KS] the programme page is not archived. Run --fetch.", call. = FALSE)
  }
  doc <- xml2::read_html(path)
  xml2::xml_remove(xml2::xml_find_all(doc, "//script | //style"))
  stringr::str_squish(xml2::xml_text(doc))
}

#' SOURCE 1. KDHE's programme page says the awards are RHTP, in so many words
#'
#' The subject of each sentence below is the GRANTS. That is the whole
#' difference from the footer: "This presentation is supported by CMS" is a
#' claim about a PDF; "the recipients of the RPGP and REH/CAP grants THROUGH
#' THE KANSAS RURAL HEALTH TRANSFORMATION PROGRAM (RHTP)" is a claim about the
#' award actions this file carries.
#'
#' The page also publishes the two pools' COUNTS AND TOTALS independently of
#' the award PDFs -- 39 organizations / $79.1 million, and seven organizations
#' / $1,007,152 -- so a parse that drifted from the documents fails here as
#' well as in the reconciliation.
ks_assert_program_page_provenance <- function(prose = NULL) {
  if (is.null(prose)) prose <- ks_program_page_prose()

  for (nm in names(KS_PROVENANCE$page)) {
    if (!stringr::str_detect(prose, stringr::fixed(KS_PROVENANCE$page[[nm]]))) {
      stop(
        "[KS] the programme page no longer carries '", nm, "':\n  ",
        KS_PROVENANCE$page[[nm]], "\n",
        "THIS IS KANSAS'S PROVENANCE, not a nicety. Without it the only ",
        "thing tying 39 awards and $79,013,347 to RHTP is a footer whose ",
        "subject is 'This presentation' (session 27's audit). Re-read the ",
        "page; do not widen this assertion.",
        call. = FALSE
      )
    }
  }
  invisible(TRUE)
}

#' SOURCE 2. The Kansas RHT Plan's own budget narrative places the three pools
#'
#' Registered as `budget_rev2` in `KS_SOURCES` since session 20 and never
#' opened until now. It is programme-scoped by construction -- it is the SF-424A
#' expenditure plan FOR the RHT Plan, its every page is headed "Kansas RHT Plan
#' Year 1 Budget Narrative", and it carries no CMS footer at all -- and it puts
#' each awarded pool inside the plan's own initiative structure:
#'
#'   Initiative 1, Programme 1  Accountable Food Is Medicine + CHW (A-FIM)
#'   Initiative 2, Programme 1  Regional Partnership Grant Program (RPGP)
#'   Initiative 2, Programme 2  REH Conversion/Transformative Capital (REH-CAP)
#'
#' It is INDEPENDENT of source 1: a different document, a different publisher
#' surface, a different year (July 2026 vs the August award announcements), and
#' written before the awards were made rather than after.
#'
#' THE AMOUNTS HERE ARE PLAN FIGURES AND ARE NOT ASSERTED AGAINST THE AWARDS.
#' The plan budgets RPGP at $49,969,410.72 and REH-CAP at $31,279,891.30; KDHE
#' awarded $49,915,410 and $29,097,937. A plan is not an award (§0.3), so what
#' is asserted is the initiative-level Year 1 totals the plan states about
#' itself -- nothing is reconciled across the two universes.
ks_narrative_text <- function() {
  path <- ks_archive_path("budget_rev2")
  if (!file.exists(path)) {
    stop("[KS] the Year 1 budget narrative is not archived. Run --fetch.",
         call. = FALSE)
  }
  stringr::str_squish(paste(rhtp_pdf_text(path), collapse = " "))
}

ks_assert_narrative_places_pools <- function(prose = NULL) {
  if (is.null(prose)) prose <- ks_narrative_text()

  for (nm in names(KS_PROVENANCE$narrative)) {
    if (!stringr::str_detect(
      prose, stringr::fixed(KS_PROVENANCE$narrative[[nm]]))) {
      stop(
        "[KS] the Year 1 budget narrative no longer carries '", nm, "':\n  ",
        KS_PROVENANCE$narrative[[nm]], "\n",
        "That document is Kansas's SECOND independent, programme-scoped ",
        "provenance source. Re-read it; do not widen this assertion.",
        call. = FALSE
      )
    }
  }
  invisible(TRUE)
}

#' The date test, read from Kansas's own page rather than typed
#'
#' The audit noted Kansas was the only one of the five footer states with no
#' `*_assert_after_noa()`: its 6 March 2026 webinar date lived in a comment.
#' KDHE publishes its own Year One Timeline, whose first line is
#' "Dec. 29, 2025 - Notice of Award" -- the state saying its own NOA date, and
#' `cms_state_noa_dates.csv`'s anchor exactly. Both solicitations postdate it,
#' which is the opposite of Texas's HHS0015180 (closed 2025-04-24, eight months
#' before its state had the money).
ks_assert_after_noa <- function(prose = NULL, links = NULL) {
  if (is.null(prose)) prose <- ks_program_page_prose()
  if (is.null(links)) links <- ks_program_page_text()

  if (!stringr::str_detect(prose, stringr::fixed(KS_PROVENANCE$noa_line))) {
    stop("[KS] the programme page no longer states its own Notice of Award ",
         "date ('", KS_PROVENANCE$noa_line, "').", call. = FALSE)
  }
  noa <- rhtp_read_noa_dates()
  anchor <- as.character(noa$noa_date[noa$state == "KS"])
  if (!identical(anchor, KS_STATED$noa_date)) {
    stop("[KS] cms_state_noa_dates.csv says ", anchor, " and this file ",
         "expects ", KS_STATED$noa_date, ".", call. = FALSE)
  }
  # The RPGP / REH CAP applicant webinar, dated in KDHE's own filename.
  if (!any(stringr::str_detect(links$href, "RPGP-REH-CAP-Webinar-March-6-2026"))) {
    stop("[KS] the 6 March 2026 RPGP/REH CAP applicant webinar is no longer ",
         "linked. It is what dates the solicitations after the NOA.",
         call. = FALSE)
  }
  invisible(anchor)
}

#' Kansas's provenance, in the order the audit asks for it
#'
#' The two programme-scoped sources are the gate. The footer runs afterwards
#' and CORROBORATES THE AMOUNT ONLY; it cannot on its own establish that these
#' awards are RHTP, and after session 27 it is no longer asked to.
ks_assert_rhtp_provenance <- function() {
  ks_assert_program_page_provenance()
  ks_assert_narrative_places_pools()
  ks_assert_after_noa()

  footer <- ks_assert_rhtp_funded(strict = FALSE)
  list(
    program_page      = TRUE,
    budget_narrative  = TRUE,
    after_noa         = TRUE,
    footer_stated     = footer
  )
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
    kdhe_award_page      = KS_STATED$kdhe_award_page,
    kdhe_award_narrative = KS_STATED$kdhe_award_narrative,
    cms_allotment  = ks_allot,
    # THE $8,000.18 IS THE AWARD DECK'S ALONE. Session 20 recorded it as "two
    # publishers disagree about Kansas's award"; session 28 read KDHE's other
    # two publications and both say $221,898,007.82, which is CMS's table to
    # the cent. Kept as `deck_gap` -- named for the one document it belongs to
    # -- and reported beside a gap of $0.18 against KDHE's other two.
    deck_gap       = ks_allot - KS_STATED$cms_award_stated,
    publisher_gap  = ks_allot - KS_STATED$kdhe_award_page,
    share_of_allotment = sum(awards$amount) / ks_allot
  )
}


# -- assertions --------------------------------------------------------------

rhtp_ks_assert <- function(awards = NULL) {
  if (is.null(awards)) awards <- rhtp_ks_year1_awardees()

  # 1. The Texas check. Run first, because if it fails nothing below matters.
  #    Since session 28 this is TWO INDEPENDENT PROGRAMME-SCOPED SOURCES plus
  #    the date test; the slide-deck footer corroborates the amount afterwards
  #    and is no longer what establishes that these awards are RHTP.
  prov <- ks_assert_rhtp_provenance()
  stopifnot(identical(prov$footer_stated, KS_STATED$cms_award_stated))

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

  # 5. THE $8,000.18 BELONGS TO ONE DOCUMENT, NOT TO KDHE. Session 20 pinned
  #    it as "two publishers disagree"; wiring the provenance meant reading
  #    KDHE's other two publications, and the programme page's footer and the
  #    budget narrative's Table 1 BOTH say $221,898,007.82 -- CMS's own table
  #    to the cent. So the award slide deck is the outlier, by a transposed
  #    digit, and both facts are pinned: the deck's gap and its absence
  #    everywhere else. Nothing is corrected (§8).
  stopifnot(abs(rec$deck_gap - 8000.18) < 0.005)
  stopifnot(abs(rec$publisher_gap - 0.18) < 0.005)
  stopifnot(identical(rec$kdhe_award_page, rec$kdhe_award_narrative))

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
  message("PROVENANCE (§6.2, programme-scoped -- NOT the footer):")
  message("  KDHE programme page : the RPGP/REH CAP grants are awarded ",
          "'through the Kansas")
  message("                        Rural Health Transformation Program ",
          "(RHTP)'; CHW+AFIM is")
  message("                        'an initiative within' it. 39 orgs / ",
          "$79.1M and 7 / $1,007,152.")
  message("  RHT Plan narrative  : all three pools sit inside the plan's own ",
          "initiative")
  message("                        structure (I1 P1, I2 P1, I2 P2). No CMS ",
          "footer; none needed.")
  message("  Date test           : KDHE's own timeline says 'Dec. 29, 2025 - ",
          "Notice of Award';")
  message("                        both solicitations postdate it.")
  message("  Award-deck footer   : CORROBORATING ONLY. Its subject is ",
          "'This presentation',")
  message("                        and the document never names RHTP ",
          "(session 27's audit).")
  message("")
  message("CMS award, on the award DECK      : $",
          format(rec$cms_award_stated, big.mark = ",", nsmall = 2,
                 scientific = FALSE),
          "   (out by $", format(rec$deck_gap, nsmall = 2), ")")
  message("CMS award, on KDHE's page + plan  : $",
          format(rec$kdhe_award_page, big.mark = ",", nsmall = 2,
                 scientific = FALSE))
  message("CMS award, as CMS states it       : $",
          format(rec$cms_allotment, big.mark = ",", scientific = FALSE),
          "   (gap $", format(rec$publisher_gap, nsmall = 2), ")")
  message("  -> KDHE and CMS AGREE. The deck alone transposes 898 as 890.")
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
