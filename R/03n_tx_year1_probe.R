# 03n_tx_year1_probe.R -------------------------------------------------------
#
# TEXAS — Rural Health Transformation Program, Year 1 (FY2026).
#
# THERE IS NO TEXAS AWARD FILE, AND THAT IS WHAT THIS FILE RECORDS.
#
# Texas led the remaining queue by every measure `state_trigger_queue.csv`
# carries: rank 1, 68 RCJ Tier 3 candidates across 67 distinct awardees, and
# the largest FY2026 allotment in the country at $281,319,361. It has no CMS
# press release, so it is `RCJ_ONLY` and no session before this one had looked
# at it.
#
# Two negatives came out of looking, and the second one is the finding.
#
# 1. HHSC HAS NOT PUBLISHED A RECIPIENT-LEVEL RHTP AWARD LIST. Texas is at
#    solicitation and negotiation stage. HHSC's own programme page prints a
#    timeline whose Notice-of-Award dates have passed (Initiative 1 Part 1
#    2026-06-19, Part 2 2026-07-15, Initiative 4 Round 1 2026-07-17,
#    Initiative 6 Part 1 2026-07-21) and publishes no roster against any of
#    them. Its Rural Texas Strong Initiative 4 Round 2 solicitation was still
#    OPEN on the day this ran, closing 2026-08-26. Texas's fiscal year begins
#    September 1 and every initiative's programme period starts in or after
#    September 2026.
#
# 2. RCJ'S 68 TIER 3 CANDIDATES ARE NOT RHTP AWARDS. NOT ONE OF THEM. This is
#    §0.1's warned-of defect -- "non-RHTP records in the RHTP feed" -- at a
#    scale nothing in this project has met before, and it is the reason the
#    disqualification is done here in code against archived state sources
#    rather than asserted in a document nobody can re-check:
#
#      53 rows  Two HHSC Notices of Award, HHS0015180 (Rural Hospital Debt
#               Reduction, 21 hospitals at $250,000) and HHS0015677 (Rural
#               Hospital Improvement, 33 hospitals at $350,000). Both are
#               STATE-APPROPRIATED. HHSC says so on its own Rural Hospital
#               Financial Assistance page, under the heading "88th Texas
#               Legislature, Regular Session, 2023": "The 88th Texas
#               Legislature appropriated $50 million to HHSC for the 2024-2025
#               biennium to establish grant programs for rural hospitals ...
#               House Bill 1 ... Article II Rider 88 appropriated the grant
#               funding." Both RFAs were RELEASED IN MARCH 2025 and closed in
#               April 2025 -- before OBBBA created RHTP, and nine months before
#               CMS issued Texas its Notice of Award on 2025-12-29. Money the
#               state did not have cannot have funded a grant it had already
#               closed applications for.
#       9 rows  Medicaid managed care. Five ATLIS incentive payments (Molina,
#               Superior, UnitedHealthcare Community Plan, Community First,
#               Wellpoint) and four suggested Intergovernmental Transfers.
#       6 rows  Line items lifted out of the Budget Period 1 narrative, not
#               awards: two DSHS AMBUS interagency contracts at $20,000,000,
#               two DSHS BRFSS oversampling contracts at $115,875, a Deloitte
#               grants-management support contract at $1,750,000, and
#               "80 Rural Hospital Districts with a publicly owned and operated
#               hospital" at $250,000,000 -- a CLASS, not a recipient, whose own
#               description reads "Estimated 80 direct awards averaging
#               $3,125,000 each". That is North Dakota's "15 selected CAHs" at
#               a thousand times the size (§0.3, session 11).
#
#    THE 53 ARE THE DANGEROUS ONES, because they are real, executed,
#    recipient-level awards to named rural Texas hospitals, published by the
#    right agency in the right format, and they are simply a different
#    programme. Nothing on the RCJ record says so. An extractor written from
#    the candidate list alone would have produced a clean, plausible, fully
#    sourced TX_year1_awardees.xlsx carrying $16,800,000 of state money as
#    RHTP -- the single most defensible-looking wrong answer this project could
#    publish. It is also §0.1's whole argument in one state: the aggregator was
#    right that Texas has hospital-level award documents and wrong about what
#    they fund, and only the state source can tell the difference.
#
# WHY THERE IS NO TX_year1_awardees.xlsx. Because there is nothing in it. A
# one-row or 53-row Texas file would add a state to Deliverable 1 and subtract
# from its defensibility. Virginia's session 15 is the precedent: the host was
# opened, the question was answered "no", and no extractor was built.
#
# WHAT THIS FILE DOES INSTEAD. It archives the ten state sources that establish
# both negatives, writes `data/reference/tx_year1_status.csv` (one row per
# initiative, per what HHSC publishes) and `tx_rcj_candidate_disposition.csv`
# (one row per disqualified RCJ candidate group, with the sentence that
# disqualifies it), and carries a TRIPWIRE that hard-fails the day HHSC posts
# an award list -- because a negative nobody re-checks decays into a stale
# assumption (session 13's rule, and South Dakota is still living under it).
#
# Usage:
#   Rscript R/03n_tx_year1_probe.R --fetch      # archive 10 sources + SHA-256
#   Rscript R/03n_tx_year1_probe.R --validate   # assertions + tripwire, offline
#   Rscript R/03n_tx_year1_probe.R --build      # writes the two status CSVs
#   Rscript R/03n_tx_year1_probe.R --probe      # LIVE: has an award list appeared?

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(tibble)
  library(purrr)
  library(readr)
})

source(here::here("R", "utils_config.R"))

TX_STATE         <- "TX"
TX_FISCAL_YEAR   <- "FY2026 (Year 1)"
TX_EVIDENCE_DIR  <- here::here("data", "evidence", "TX")
TX_MANIFEST      <- file.path(TX_EVIDENCE_DIR, "MANIFEST.txt")
TX_STATUS_CSV    <- here::here("data", "reference", "tx_year1_status.csv")
TX_DISPOSITION_CSV <- here::here("data", "reference",
                                 "tx_rcj_candidate_disposition.csv")

# The §9.5 posture: identify honestly, throttle, and never re-fetch a cached
# document. `+url` is the well-behaved-crawler convention that got this project
# through Akamai on medicaid.gov (session 10); it is used everywhere since.
TX_USER_AGENT      <- paste0(
  "AHA-RHTP-Tracker/1.0 (American Hospital Association, Data & Policy; ",
  "research use; +https://www.aha.org)"
)
TX_HOST_THROTTLE_S <- 2

# Texas's CMS FY2026 allotment, from the §7.1 anchor. Asserted against
# cms_fy2026_allotments.csv rather than restated, so the two cannot drift.
TX_CMS_ALLOTMENT <- 281319361


# -- The sources -------------------------------------------------------------
#
# Ten documents, in three groups. `role` says what each one is FOR, because a
# reader six months from now needs to know which document carries which half of
# the finding.
#
#   PROGRAMME   HHSC's RHTP page. The timeline, the six initiatives, and no
#               roster.
#   SOLICITATION  The four Rural Texas Strong RFA detail pages. Each is checked
#               for an "Awarded Grant Information" section and each lacks one.
#   DISQUALIFY  The documents that establish the 53 rows are state money: the
#               two 2025 RFA detail pages (which DO carry an Awarded Grant
#               Information section -- they are the positive control for the
#               check above), the two Notices of Award RCJ actually scraped,
#               and HHSC's Rural Hospital Financial Assistance page, which
#               names the appropriation.
TX_SOURCES <- tibble::tribble(
  ~key,            ~role,          ~file,                                ~url,
  "programme",     "PROGRAMME",    "2026-08-29_pfd_rhtp_programme.html",
  "https://pfd.hhs.texas.gov/rural-health-transformation-program",

  "rfa_index",     "PROGRAMME",    "2026-08-29_hhsc_rfa_index.html",
  "https://resources.hhs.texas.gov/rfa",

  "rts_init1p2",   "SOLICITATION", "2026-08-29_rfa_hhs0017223_init1_part2.html",
  "https://resources.hhs.texas.gov/rfa/hhs0017223",

  "rts_init4r1",   "SOLICITATION", "2026-08-29_rfa_hhs0017212_init4_round1.html",
  "https://resources.hhs.texas.gov/rfa/hhs0017212",

  "rts_init4r2",   "SOLICITATION", "2026-08-29_rfa_hhs0017618_init4_round2.html",
  "https://resources.hhs.texas.gov/rfa/hhs0017618",

  "rts_init6p1",   "SOLICITATION", "2026-08-29_rfa_hhs0017220_init6_part1.html",
  "https://resources.hhs.texas.gov/rfa/hhs0017220",

  "state_debt_rfa", "DISQUALIFY",  "2026-08-29_rfa_hhs0015180_debt_reduction.html",
  "https://resources.hhs.texas.gov/rfa/hhs0015180",

  "state_impr_rfa", "DISQUALIFY",  "2026-08-29_rfa_hhs0015677_improvement.html",
  "https://resources.hhs.texas.gov/rfa/hhs0015677",

  "state_debt_noa", "DISQUALIFY",  "2026-08-29_hhs0015180_grants_awarded.pdf",
  "https://resources.hhs.texas.gov/sites/default/files/documents/hhs0015180_grants_awarded.pdf",

  "state_impr_noa", "DISQUALIFY",  "2026-08-29_hhs0015677_grants_awarded.pdf",
  "https://resources.hhs.texas.gov/sites/default/files/documents/hhs0015677_grants_awarded.pdf",

  "state_rhf_page", "DISQUALIFY",  "2026-08-29_hhsc_rural_hospital_financial_assistance.html",
  "https://www.hhs.texas.gov/providers/medicaid-business-resources/medicaid-supplemental-payment-directed-payment-programs/rural-hospital-finance/rural-hospital-financial-assistance"
)


# -- fetch -------------------------------------------------------------------

#' Refuse to archive anything carrying a credential
#'
#' Session 16 caught a Mapbox token inside `<main>` on hfs.illinois.gov and
#' session 17 caught a Google Maps key inside a `<script src>` on
#' oregon.gov -- a form a pattern anchored on `api_key=` walks straight past.
#' Both were caught by the automated guard on the fetch, not by the hand check
#' that ran once. All eleven Texas sources are clean, which is WHY they are
#' archived whole; this asserts it on every fetch rather than trusting a check
#' run by hand today. It matches token SHAPE, not any literal value, so a
#' rotated credential is caught too. NULs are stripped first, because a PDF is
#' binary and a guard that throws on the binary sources is a guard somebody
#' writes an exception around.
tx_assert_credential_free <- function(body, label) {
  txt <- rawToChar(body[body != as.raw(0L)])
  Encoding(txt) <- "UTF-8"

  shapes <- c(
    mapbox_or_stripe = "[ps]k\\.ey[A-Za-z0-9_.-]{10,}",
    google_api       = "AIza[0-9A-Za-z_-]{20,}",
    generic_api_key  = "(?i)api[_-]?key[\"']?\\s*[:=]\\s*[\"'][A-Za-z0-9_.-]{16,}[\"']",
    bearer           = "(?i)bearer\\s+[A-Za-z0-9._-]{25,}",
    aws_key          = "AKIA[A-Z0-9]{12,}"
  )
  for (nm in names(shapes)) {
    if (stringr::str_detect(txt, shapes[[nm]])) {
      stop("[TX] refusing to archive ", label, ": it carries a ", nm,
           "-shaped credential, which is the publisher's to publish and not ",
           "ours to redistribute (§7.1, sessions 14/16/17).", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' Archive the eleven Texas sources verbatim, with a SHA-256 manifest
#'
#' `writeBin()` of the exact bytes the server sent, so re-hashing the file on
#' disk reproduces the manifest (session 12's off-by-one: `writeLines()` appends
#' a newline and leaves every archived file one byte longer than what was
#' hashed). The manifest EXCLUDES ITSELF -- session 15's defect, where a
#' manifest listing its own digest was stale the instant it was written and the
#' verification test passed on absence.
tx_fetch_sources <- function(force = FALSE) {
  dir.create(TX_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)

  entries <- purrr::map_dfr(seq_len(nrow(TX_SOURCES)), function(i) {
    src  <- TX_SOURCES[i, ]
    dest <- file.path(TX_EVIDENCE_DIR, src$file)

    if (file.exists(dest) && !force) {
      # §9.5: a re-run must never re-fetch an unchanged document. A state
      # government site is not a resource to poll.
      message("[TX] cached, not re-fetched: ", src$file)
    } else {
      if (i > 1L) Sys.sleep(TX_HOST_THROTTLE_S)
      message("[TX] fetching ", src$url)
      resp <- httr::GET(src$url, httr::user_agent(TX_USER_AGENT),
                        httr::timeout(120))
      if (httr::status_code(resp) != 200L) {
        stop("[TX] HTTP ", httr::status_code(resp), " for ", src$url,
             call. = FALSE)
      }
      body <- httr::content(resp, as = "raw")
      tx_assert_credential_free(body, src$file)
      writeBin(body, dest)
    }

    tibble::tibble(
      key    = src$key,
      role   = src$role,
      file   = src$file,
      url    = src$url,
      bytes  = file.info(dest)$size,
      sha256 = digest::digest(file = dest, algo = "sha256"),
      fetched_utc = format(Sys.time(), tz = "UTC", "%Y-%m-%dT%H:%M:%SZ")
    )
  })

  tx_write_manifest(entries)
  entries
}

tx_write_manifest <- function(entries) {
  lines <- c(
    "Texas RHTP (Rural Texas Strong) -- archived state sources",
    "",
    "Every file is the bytes the server sent, unreduced: no Texas source in",
    "this set carries a third-party credential, which is asserted on each",
    "fetch by tx_assert_credential_free() rather than checked once by hand.",
    "So each sha256 below re-computes from the file on disk exactly.",
    "",
    "MANIFEST.txt is deliberately absent from its own listing (session 15).",
    "",
    sprintf("%-14s %-13s %10s  %s  %s", "KEY", "ROLE", "BYTES", "SHA-256",
            "FILE"),
    sprintf("%-14s %-13s %10d  %s  %s", entries$key, entries$role,
            entries$bytes, entries$sha256, entries$file)
  )
  writeLines(lines, TX_MANIFEST)
  invisible(TX_MANIFEST)
}

#' Read an archived source back, as text
tx_read_archive <- function(key) {
  src <- TX_SOURCES[TX_SOURCES$key == key, ]
  if (nrow(src) != 1L) stop("[TX] unknown source key: ", key, call. = FALSE)
  path <- file.path(TX_EVIDENCE_DIR, src$file)
  if (!file.exists(path)) {
    stop("[TX] not archived yet: ", src$file,
         " -- run `Rscript R/03n_tx_year1_probe.R --fetch` first.", call. = FALSE)
  }
  raw <- readBin(path, "raw", file.info(path)$size)
  txt <- rawToChar(raw[raw != as.raw(0L)])
  Encoding(txt) <- "UTF-8"
  txt
}


# -- the tripwire ------------------------------------------------------------
#
# WHY A NEGATIVE NEEDS A TRIPWIRE. Session 13 wrote one for South Dakota and it
# is still the right shape: a negative nobody re-checks decays into a stale
# assumption, and this project has been burnt by exactly that (session 11 read
# South Dakota's grant COUNT as a grant LIST and it stood for two sessions).
# The Texas negative is a statement about four HHSC solicitation pages on one
# day. HHSC posts an award roster by adding an "Awarded Grant Information"
# section to the RFA detail page -- that is precisely how HHS0015180 and
# HHS0015677 publish theirs, which is why those two are archived here as the
# POSITIVE CONTROL. The check is therefore not a guess about HHSC's format; it
# is the format HHSC demonstrably uses, tested against two live examples of it
# in the same archive.
#
# The tripwire FAILS THE BUILD, it does not warn. A warning in a log nobody
# reads is how a negative goes stale.

TX_AWARDED_SECTION <- "Awarded Grant Information"

#' Does an archived RFA detail page publish an award roster?
tx_has_awarded_section <- function(key) {
  stringr::str_detect(tx_read_archive(key), stringr::fixed(TX_AWARDED_SECTION))
}

#' Parse one archived HHSC RFA detail page
#'
#' PARSED, NEVER TRANSCRIBED (the §7.1 posture). Every field below is read out
#' of the committed archive, so the status table cannot drift from the document
#' and a re-run on the same bytes reproduces it exactly. `refuse` rather than
#' guess: a page whose labels do not resolve fails here instead of contributing
#' an empty row to a status file that reads as "HHSC published nothing".
tx_parse_rfa_page <- function(key) {
  txt <- tx_read_archive(key)
  flat <- stringr::str_replace_all(txt, "<[^>]+>", "\n")
  flat <- stringr::str_replace_all(flat, "&amp;", "&")
  lines <- stringr::str_trim(stringr::str_split(flat, "\n")[[1]])
  lines <- lines[nzchar(lines)]

  # HHSC marks up each field as a label element followed by its value, so the
  # value is the next non-empty line after the label.
  field <- function(label) {
    i <- which(lines == label)
    if (!length(i)) {
      stop("[TX] ", key, ": no '", label, "' field on the archived page. ",
           "HHSC's layout has changed -- re-derive tx_parse_rfa_page() ",
           "against the current format rather than letting a blank row ",
           "read as 'nothing published'.", call. = FALSE)
    }
    # HHSC renders some fields as `label` / `:` / `value` on three lines and
    # others as `label` / `: value` on two, so the colon is skipped rather
    # than assumed away. Getting this wrong does not throw -- it returns "" --
    # which is why the empty result is refused below: a status file with a
    # blank Release Date column reads as a fact about HHSC.
    val <- ""
    for (j in seq(i[[1]] + 1L, min(i[[1]] + 4L, length(lines)))) {
      cand <- stringr::str_trim(stringr::str_remove(lines[[j]], "^:\\s*"))
      if (nzchar(cand)) { val <- cand; break }
    }
    if (!nzchar(val)) {
      stop("[TX] ", key, ": the '", label, "' field parsed EMPTY. An empty ",
           "field in a status table reads as a statement about HHSC; ",
           "re-derive the parse instead.", call. = FALSE)
    }
    val
  }

  tibble::tibble(
    key                = key,
    procurement_number = field("Procurement Number"),
    procurement_name   = field("Procurement Name"),
    program_name       = field("Program Name"),
    release_date       = field("Release Date"),
    submission_deadline = field("Submission Deadline"),
    has_award_roster   = tx_has_awarded_section(key)
  )
}

#' The four Rural Texas Strong solicitations, and what each one publishes
tx_solicitation_state <- function() {
  keys <- TX_SOURCES$key[TX_SOURCES$role == "SOLICITATION"]
  purrr::map_dfr(keys, tx_parse_rfa_page)
}

#' The two 2025 state-programme solicitations -- the positive control
tx_state_programme_state <- function() {
  keys <- c("state_debt_rfa", "state_impr_rfa")
  purrr::map_dfr(keys, tx_parse_rfa_page)
}

#' Hard-fail the day Texas publishes an RHTP award list
#'
#' Three branches, each one a way the negative could stop being true:
#'
#'  1. A Rural Texas Strong RFA page gains an "Awarded Grant Information"
#'     section. That is HHSC posting the roster, in HHSC's own format.
#'  2. The two state-programme pages LOSE theirs. Then the check above is
#'     measuring nothing and its silence means nothing -- the positive control
#'     is what makes branch 1 evidence rather than an assumption.
#'  3. The RHTP programme page starts naming recipients. Checked by counting
#'     award-verb sentences that also carry an organisation-shaped name; the
#'     page today describes initiatives and eligibility and names no awardee.
#'
#' Branch 2 is the one worth arguing for. Without it, a site redesign that
#' renamed the section would silently turn every future run green.
#' Every branch takes its evidence as an argument, defaulting to the archive.
#' A tripwire whose failure branches cannot be exercised is a tripwire nobody
#' knows works, and every branch here is positive-controlled in the tests by
#' feeding it the condition rather than by mocking the reader out from under it.
tx_assert_no_award_list <- function(sol   = tx_solicitation_state(),
                                    ctrl  = tx_state_programme_state(),
                                    named = tx_programme_named_recipients()) {
  if (any(sol$has_award_roster)) {
    stop(
      "[TX] TRIPWIRE: a Rural Texas Strong solicitation now carries an '",
      TX_AWARDED_SECTION, "' section (",
      paste(sol$procurement_number[sol$has_award_roster], collapse = ", "),
      ").\n",
      "Texas has published its RHTP award roster. This file's negative is out ",
      "of date: extract the roster and replace this probe with a real ",
      "R/03n_tx_year1_awardees.R.",
      call. = FALSE
    )
  }

  missing <- ctrl$procurement_number[!ctrl$has_award_roster]
  if (length(missing)) {
    stop(
      "[TX] TRIPWIRE: the positive control failed. '", TX_AWARDED_SECTION,
      "' is no longer present on ", paste(missing, collapse = ", "), ".\n",
      "HHSC publishes rosters by adding that section to an RFA page, so if it ",
      "is gone from the two pages that demonstrably HAVE a roster, then the ",
      "check on the Rural Texas Strong pages is measuring nothing and its ",
      "silence is not evidence. Re-derive the check against HHSC's current ",
      "format before trusting another run.",
      call. = FALSE
    )
  }

  if (length(named)) {
    stop(
      "[TX] TRIPWIRE: the RHTP programme page now appears to name award ",
      "recipients: ", paste(utils::head(named, 5), collapse = " | "), "\n",
      "Read the page before trusting this file's negative again.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}

#' Organisation-shaped names sitting next to an award verb on the programme page
#'
#' Session 13's rule, and for its reason: the match may NEVER cross a sentence
#' boundary. A pattern allowed to span sentences reads "... will be awarded in
#' September. Titus Regional Medical Center is an eligible applicant" as an
#' award TO Titus, which is a false alarm; the same looseness in the other
#' direction swallows two roster entries into one match and undercounts.
#'
#' SO THE TEXT IS SPLIT INTO SENTENCES FIRST, AND THE ABBREVIATION LIST IS THE
#' WHOLE DIFFICULTY. Splitting naively on ". " breaks "St. Mary's Hospital" in
#' half and would make a REAL roster entry invisible -- a false negative in a
#' tripwire, which is the one failure that matters here. The exceptions below
#' are the abbreviations that actually occur in US hospital names and addresses;
#' the list is short and explicit because a silent heuristic is what this is
#' replacing.
TX_SENTENCE_ABBREVIATIONS <- c("St", "Ste", "Dr", "Mt", "Ft", "Inc", "Co",
                               "Corp", "Ltd", "No", "Ave", "Rd", "Blvd", "Jr",
                               "Sr", "U.S", "Univ", "Dept")

tx_sentences <- function(txt) {
  guard <- paste0("(?<!\\b", TX_SENTENCE_ABBREVIATIONS, ")", collapse = "")
  parts <- stringr::str_split(txt, paste0(guard, "\\.\\s+(?=[A-Z])"))[[1]]
  stringr::str_trim(parts[nzchar(stringr::str_trim(parts))])
}

# Case-insensitive on the VERB only -- a page may open a sentence with
# "Awarded to ..." -- and deliberately case-SENSITIVE on the name, because
# initial capitals are most of what makes a string organisation-shaped.
TX_AWARD_VERBS <- paste0(
  "(?i:awarded to|awarded|will receive|has received|received a grant|",
  "grant(?:s|ed)? to|recipients? (?:are|include)|selected)"
)

TX_ORG_SUFFIX <- paste0(
  "(?:Hospital|Hospitals|Medical Center|Health System|Healthcare|",
  "Hospital District|Clinic|University|College|Foundation|Association|",
  "Health Network|Health District)"
)

tx_programme_named_recipients <- function(txt = tx_read_archive("programme")) {
  txt <- stringr::str_replace_all(txt, "<[^>]+>", " ")
  txt <- stringr::str_replace_all(txt, "&[a-z]+;|&#[0-9]+;", " ")
  txt <- stringr::str_replace_all(txt, "\\s+", " ")

  pattern <- paste0(
    TX_AWARD_VERBS, ".{0,80}?",
    # The curly apostrophe is deliberate: state pages publish "St. Mary\u2019s",
    # and a name class carrying only the straight quote drops exactly the
    # hospitals whose names have one -- a false negative in a tripwire.
    "\\b([A-Z][A-Za-z'\u2019&.-]*(?: [A-Z][A-Za-z'\u2019&.-]*){0,4} ",
    TX_ORG_SUFFIX, ")\\b"
  )

  hits <- purrr::map(tx_sentences(txt), function(sentence) {
    m <- stringr::str_match_all(sentence, pattern)[[1]]
    if (!length(m)) character(0) else m[, 2]
  })
  unique(unlist(hits))
}


# -- the two status tables ---------------------------------------------------

#' What HHSC publishes, per Rural Texas Strong solicitation
#'
#' NOT an award file, and the column names say so: `award_roster_published`,
#' `recipients_named`, and an `amount` column that DOES NOT EXIST. There is no
#' figure in this file that a sum could turn into a Texas hospital total,
#' which is deliberate -- §0.3, and South Dakota's rule (session 13): a state
#' that has published a count and no list gets a row saying exactly that, with
#' the amount column absent rather than empty.
tx_build_status <- function() {
  sol <- tx_solicitation_state()

  sol %>%
    dplyr::transmute(
      state                  = TX_STATE,
      fiscal_year            = TX_FISCAL_YEAR,
      procurement_number,
      procurement_name,
      program_name,
      release_date,
      submission_deadline,
      award_roster_published = dplyr::if_else(has_award_roster, "Yes", "No"),
      recipients_named       = 0L,
      award_tier             = "SOLICITATION",
      rhtp_award_confirmed   = "Unclear",
      recipient_confirmed    = "No",
      amount_confirmed       = "No",
      distributed_to_hospital = "Unclear",
      hospital_attribution   = "NOT_HOSPITAL",
      determination_confidence = "LOW",
      validation_source_type = "PROCUREMENT_PORTAL_POSTING",
      flag_reason            = "RECIPIENT_NOT_NAMED",
      state_source_url       = TX_SOURCES$url[match(key, TX_SOURCES$key)],
      source_archive_path    = file.path("data/evidence/TX",
                                         TX_SOURCES$file[match(key, TX_SOURCES$key)]),
      determination_basis = paste0(
        "HHSC solicitation ", procurement_number, ", archived ",
        "2026-08-29. The page carries no '", TX_AWARDED_SECTION, "' section, ",
        "which is the section HHSC uses to publish a roster (see ",
        "tx_rcj_candidate_disposition.csv for the two 2025 pages that have ",
        "one). Texas is at solicitation stage: no recipient is named and no ",
        "amount is attributable. §0.3 -- eligibility is not receipt."
      ),
      extraction_method      = "PARSED_FROM_ARCHIVED_HTML",
      validator              = "R/03n_tx_year1_probe.R",
      as_of                  = "2026-08-29"
    )
}

#' Why each RCJ Texas Tier 3 candidate group is NOT an RHTP award
#'
#' §0.4 in table form: one row per group, the count, the disqualifying fact,
#' and the state document that carries it. The point of writing it down is that
#' the next session's survey will put Texas back at the top of the queue on the
#' same 68 candidates, and re-deriving this from scratch is how a project
#' eventually gets it wrong once.
tx_build_disposition <- function() {
  ctrl <- tx_state_programme_state()
  stopifnot(all(ctrl$has_award_roster))

  tibble::tribble(
    ~group, ~rcj_rows, ~rcj_source_document, ~disposition, ~why, ~state_source_key,
    "HHS0015180 Rural Hospital Debt Reduction", 21L,
    "TX - 2026 - HHSC PCS Grant Awards - HHS0015180",
    "NOT_RHTP_STATE_APPROPRIATION",
    paste0("A real, executed, recipient-level HHSC award list -- 21 rural ",
           "Texas hospitals at $250,000 each -- funded by STATE money. HHSC: ",
           "'The 88th Texas Legislature appropriated $50 million to HHSC for ",
           "the 2024-2025 biennium to establish grant programs for rural ",
           "hospitals ... House Bill 1 ... Article II Rider 88 appropriated ",
           "the grant funding.' The RFA was released 2025-03-24 and closed ",
           "2025-04-24 -- before OBBBA created RHTP, and nine months before ",
           "CMS issued Texas its RHTP Notice of Award on 2025-12-29."),
    "state_rhf_page",

    "HHS0015677 Rural Hospital Improvement", 32L,
    "TX - 2026 - HHSC PCS Grant Awards - HHS0015677",
    "NOT_RHTP_STATE_APPROPRIATION",
    paste0("The same appropriation and the same page: 33 rural Texas ",
           "hospitals at $350,000 each, RFA released 2025-03-11, closed ",
           "2025-04-09. RCJ captured 32 of the 33 rows, which is a second, ",
           "smaller §0.1 defect sitting inside the first."),
    "state_rhf_page",

    "ATLIS incentive payments to Medicaid MCOs", 5L,
    "TX - 2025 - ATLIS Incentive Payments for Medicaid Managed Care Organizations",
    "NOT_RHTP_MEDICAID",
    paste0("Molina, Superior Health Plan, UnitedHealthcare Community Plan, ",
           "Community First and Wellpoint. Medicaid managed care incentive ",
           "payments, not RHTP, and not to hospitals."),
    NA_character_,

    "Suggested Intergovernmental Transfers", 4L,
    "TX - 2025 - Suggested Intergovernmental Transfer (IGT)",
    "NOT_RHTP_MEDICAID",
    paste0("Medicaid IGT figures. Not an RHTP award action in any tier."),
    NA_character_,

    "Budget Period 1 narrative line items", 5L,
    "TX - 2026 - Rural Texas Strong Program (RHTP)",
    "RHTP_BUT_NOT_A_SUBAWARD",
    paste0("Genuinely RHTP, and genuinely not Tier 3 award actions: two DSHS ",
           "AMBUS interagency contracts at $20,000,000, two DSHS BRFSS ",
           "oversampling contracts at $115,875, and Deloitte grants-management ",
           "support at $1,750,000. Planned state-agency and vendor spend read ",
           "out of the budget narrative. Every one is NON_HOSPITAL on its ",
           "recipient (§0.3a) whatever its status."),
    "programme",

    "'80 Rural Hospital Districts' pool", 1L,
    "TX - 2026 - Texas RHTP", "RHTP_BUT_A_CLASS_NOT_A_RECIPIENT",
    paste0("$250,000,000 against an awardee named '80 Rural Hospital ",
           "Districts with a publicly owned and operated hospital', whose own ",
           "RCJ description reads 'Estimated 80 direct awards averaging ",
           "$3,125,000 each'. A CLASS and an ESTIMATE, not a recipient and not ",
           "an award -- North Dakota's '15 selected CAHs' (session 11) at a ",
           "thousand times the size. §0.3: eligibility is not receipt, and a ",
           "plan is not an award action."),
    "programme"
  ) %>%
    dplyr::mutate(
      state = TX_STATE,
      state_source_url = TX_SOURCES$url[match(state_source_key, TX_SOURCES$key)],
      source_archive_path = dplyr::if_else(
        is.na(state_source_key), NA_character_,
        file.path("data/evidence/TX",
                  TX_SOURCES$file[match(state_source_key, TX_SOURCES$key)])
      ),
      as_of = "2026-08-29"
    ) %>%
    dplyr::select(state, group, rcj_rows, rcj_source_document, disposition,
                  why, state_source_url, source_archive_path, as_of)
}


# -- assertions --------------------------------------------------------------

#' Every Texas assertion, offline
#'
#' The important one is `tx_assert_candidates_accounted()`. Everything else
#' here guards a value; that one guards the SHAPE of the finding.
tx_validate <- function() {
  tx_assert_no_award_list()
  tx_assert_candidates_accounted()
  tx_assert_allotment_matches_anchor()
  tx_assert_vocabulary()
  tx_assert_archive_verifies()
  invisible(TRUE)
}

#' Every RCJ Texas Tier 3 candidate is disposed of, and the count is DERIVED
#'
#' Not "68" typed into an assertion. The number is recomputed from the
#' committed Stage 2 record table on every run, so the day a re-pull changes
#' Texas's candidate count this fails and someone has to look at the new rows
#' rather than at a stale constant that still says 68. That is the difference
#' between a finding and a claim: §0.1 says the candidate list is where to
#' LOOK, and a disposition table that silently stops covering it has stopped
#' being a disposition.
tx_assert_candidates_accounted <- function(actual = tx_rcj_candidate_count(),
                                           disp = tx_build_disposition()) {
  if (sum(disp$rcj_rows) != actual) {
    stop(
      "[TX] the disposition table covers ", sum(disp$rcj_rows), " RCJ Tier 3 ",
      "candidates but the record table holds ", actual, ".\n",
      "Texas's candidate set has changed since this negative was established. ",
      "Read the rows that moved -- do not adjust the table to match.",
      call. = FALSE
    )
  }

  # And not one of them survives as an RHTP subaward.
  if (any(disp$disposition == "RHTP_SUBAWARD")) {
    stop("[TX] a candidate is now disposed as an RHTP subaward. Build a real ",
         "extractor; this probe is a negative and can no longer describe ",
         "Texas.", call. = FALSE)
  }
  invisible(TRUE)
}

#' How many Tier 3 candidates does the committed record table hold for Texas?
tx_rcj_candidate_count <- function() {
  path <- here::here("data", "interim", "stage2_record_table.rds")
  if (!file.exists(path)) {
    stop("[TX] stage2_record_table.rds is missing; run R/02_normalize.R.",
         call. = FALSE)
  }
  rt <- readRDS(path)
  sum(rt$state == "TX" & rt$award_tier == "SUBAWARD", na.rm = TRUE)
}

#' Texas's allotment agrees with the §7.1 CMS anchor
#'
#' §0.2a: a Tier 1 figure comes from CMS, never from a state page and never
#' from a constant in a state file. This is why TX_CMS_ALLOTMENT is asserted
#' rather than used.
tx_assert_allotment_matches_anchor <- function() {
  anchor <- readr::read_csv(
    here::here("data", "reference", "cms_fy2026_allotments.csv"),
    show_col_types = FALSE, progress = FALSE
  )
  amt_col <- intersect(c("fy2026_allotment", "allotment", "amount"),
                       names(anchor))[[1]]
  tx <- anchor[[amt_col]][anchor$state == "TX"]
  stopifnot(length(tx) == 1L)
  if (!isTRUE(all.equal(as.numeric(tx), TX_CMS_ALLOTMENT))) {
    stop("[TX] allotment drift: this file says ", TX_CMS_ALLOTMENT,
         " and the §7.1 CMS anchor says ", tx, ". The anchor wins (§0.2a).",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Every categorical value in the status table is in §8
tx_assert_vocabulary <- function() {
  status <- tx_build_status()
  checks <- list(
    award_tier               = "award_tier",
    rhtp_award_confirmed     = "rhtp_award_confirmed",
    recipient_confirmed      = "recipient_confirmed",
    amount_confirmed         = "amount_confirmed",
    distributed_to_hospital  = "distributed_to_hospital",
    hospital_attribution     = "hospital_attribution",
    determination_confidence = "determination_confidence",
    validation_source_type   = "source_doc_type",
    flag_reason              = "flag_reason"
  )
  for (col in names(checks)) {
    bad <- setdiff(unique(status[[col]]), rhtp_vocabulary(checks[[col]]))
    if (length(bad)) {
      stop("[TX] ", col, " outside §8: ", paste(bad, collapse = ", "),
           call. = FALSE)
    }
  }

  # THE ONE COLUMN THAT MUST NOT EXIST. Texas has published no per-recipient
  # figure, so there is nothing for an `amount` column to hold and no sum over
  # this file can produce a Texas hospital dollar. Georgia's device (§6.2),
  # applied to a state with no recipients at all.
  if ("amount" %in% names(status)) {
    stop("[TX] tx_year1_status.csv must have NO `amount` column: Texas has ",
         "named no recipient and published no per-recipient figure, and an ",
         "amount column here would eventually be summed.", call. = FALSE)
  }
  invisible(TRUE)
}

#' Every archived file re-hashes to its manifest entry, and the manifest lists
#' exactly what is on disk
#'
#' Session 15's pair of defects: a manifest that listed itself (stale the
#' instant it was written) and a verification that passed on ABSENCE, so a file
#' that silently stopped being listed was indistinguishable from one that
#' verified. Both are checked here.
tx_assert_archive_verifies <- function() {
  if (!file.exists(TX_MANIFEST)) {
    stop("[TX] no MANIFEST.txt -- run --fetch first.", call. = FALSE)
  }
  lines  <- readLines(TX_MANIFEST, warn = FALSE)
  listed <- stringr::str_match(lines, "([0-9a-f]{64})\\s+(\\S+)$")
  listed <- listed[!is.na(listed[, 1]), , drop = FALSE]

  if (basename(TX_MANIFEST) %in% listed[, 3]) {
    stop("[TX] MANIFEST.txt lists itself. Its own digest is stale the instant ",
         "the file is written (session 15).", call. = FALSE)
  }

  on_disk <- setdiff(list.files(TX_EVIDENCE_DIR), basename(TX_MANIFEST))
  if (!setequal(on_disk, listed[, 3])) {
    stop("[TX] the manifest and the archive directory disagree.\n",
         "  listed not on disk: ",
         paste(setdiff(listed[, 3], on_disk), collapse = ", "), "\n",
         "  on disk not listed: ",
         paste(setdiff(on_disk, listed[, 3]), collapse = ", "),
         call. = FALSE)
  }

  for (i in seq_len(nrow(listed))) {
    path <- file.path(TX_EVIDENCE_DIR, listed[i, 3])
    got  <- digest::digest(file = path, algo = "sha256")
    if (!identical(got, listed[i, 2])) {
      stop("[TX] digest mismatch for ", listed[i, 3], call. = FALSE)
    }
  }
  invisible(TRUE)
}


# -- build -------------------------------------------------------------------

tx_build <- function() {
  tx_validate()

  status <- tx_build_status()
  disp   <- tx_build_disposition()

  readr::write_csv(status, TX_STATUS_CSV, na = "")
  readr::write_csv(disp, TX_DISPOSITION_CSV, na = "")

  message("[TX] wrote ", nrow(status), " solicitation rows -> ", TX_STATUS_CSV)
  message("[TX] wrote ", nrow(disp), " disposition rows (",
          sum(disp$rcj_rows), " RCJ candidates, none an RHTP subaward) -> ",
          TX_DISPOSITION_CSV)
  message("[TX] NO TX_year1_awardees.xlsx was written, and that is the finding.")
  invisible(list(status = status, disposition = disp))
}

tx_report <- function() {
  sol  <- tx_solicitation_state()
  ctrl <- tx_state_programme_state()
  disp <- tx_build_disposition()

  cat("\nTEXAS -- Rural Health Transformation Program, Year 1\n")
  cat("CMS FY2026 allotment: $",
      formatC(TX_CMS_ALLOTMENT, format = "d", big.mark = ","),
      "  (largest in the country)\n\n", sep = "")

  cat("Rural Texas Strong solicitations, and what each publishes:\n")
  print(as.data.frame(sol[, c("procurement_number", "release_date",
                              "submission_deadline", "has_award_roster")]),
        row.names = FALSE)
  cat("\nPositive control -- the two STATE-funded programmes, same site,",
      "same format:\n")
  print(as.data.frame(ctrl[, c("procurement_number", "procurement_name",
                               "has_award_roster")]), row.names = FALSE)

  cat("\nRCJ Tier 3 candidates, disposed:\n")
  print(as.data.frame(disp[, c("group", "rcj_rows", "disposition")]),
        row.names = FALSE)
  cat("\n  total ", sum(disp$rcj_rows),
      " candidates; RHTP subawards among them: 0\n\n", sep = "")
  invisible(TRUE)
}


# -- probe (live) ------------------------------------------------------------

#' Re-fetch and re-check: has Texas published an award list yet?
#'
#' The only entry point here that touches the network after --fetch. It exists
#' because this negative is dated, and the honest way to keep it honest is to
#' re-run the same check against the live pages rather than to re-read a
#' document from August.
tx_probe <- function() {
  tx_fetch_sources(force = TRUE)
  tx_validate()
  message("[TX] probe: still no RHTP award roster on any Rural Texas Strong ",
          "solicitation, and the positive control still fires.")
  tx_report()
}


# -- CLI ---------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args)    tx_fetch_sources(force = "--force" %in% args)
  if ("--validate" %in% args) { tx_validate(); message("[TX] all assertions pass.") }
  if ("--build" %in% args)    tx_build()
  if ("--report" %in% args)   tx_report()
  if ("--probe" %in% args)    tx_probe()
  if (!length(intersect(args, c("--fetch", "--validate", "--build",
                                "--report", "--probe")))) {
    cat("usage: Rscript R/03n_tx_year1_probe.R",
        "[--fetch [--force] | --validate | --build | --report | --probe]\n")
  }
}
