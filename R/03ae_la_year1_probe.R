# 03ae_la_year1_probe.R --------------------------------------------------------
# LOUISIANA, YEAR 1 -- NO LONGER A NEGATIVE (session 64). ONE OF SEVEN
# SOLICITATIONS HAS AWARDED, AND IT NAMES FIVE OF FIFTY-THREE RECIPIENTS.
#
# LDH's September 3, 2026 stakeholder webinar deck reports the Rural Clinician
# Credit Bank "As of 8/28/26": 53 awards, $12,701,996, CEAs "due for signature
# 9/15/26", 20 of them "Hospital settings" ($6,285,515). It NAMES FIVE -- the
# "Multi-parish awardees", $1,965,788, none of them typed as a hospital -- and
# the other 48 ($10,736,208, LDH's parish table) nowhere. So this file now
# WRITES data/reference/la_year1_awardees.csv: five named rows and ONE
# unnamed aggregate (South Dakota's device, `amount` empty). NO ROW REACHES A
# HOSPITAL BUCKET: no hospital is named, and the hospital-setting count is a
# split of the whole round that LDH does not map onto the named five. See the
# "session 64" section below.
#
# EVERYTHING BELOW THIS BLOCK IS THE NEGATIVE AS IT STOOD FOR THE OTHER SIX
# SOLICITATIONS, AND IT STILL HOLDS FOR THEM: the tripwire, the windows and the
# probe all keep watching.
#
# (the original header follows)
# LOUISIANA, YEAR 1 -- A NEGATIVE, AND THE ONE WHOSE ANNOUNCEMENT WINDOWS HAVE
# ALL CLOSED AT ONCE.
#
# Louisiana led the RCJ_ONLY queue at 6 Tier 3 candidates / 6 distinct awardees
# / $53,910,000, with no CMS press release and a $208,374,448 allotment. It has
# published NO recipient-level RHTP award list.
#
# WHAT IT HAS PUBLISHED IS SEVEN SOLICITATIONS AND SEVEN ANNOUNCEMENT DATES.
# LDH's RHTP page carries an "IMPORTANT DATES - BUDGET YEAR 1" block giving,
# for every one of the seven Budget Year 1 strategic funding opportunities,
# both an application deadline AND a "Notice of Intent to Contract
# Announcements" window:
#
#     Late July to mid August   x3   (Clinician Credit Bank, Telehealth, Capital)
#     Mid to late August        x4   (Collaborative Provider, APM, Care
#                                     Conveners, Food is Medicine)
#
# THIS RAN 2026-09-02, SO ALL SEVEN WINDOWS HAVE CLOSED. Connecticut (session
# 35) was the first negative in this project whose award date had passed, with
# ONE solicitation sixteen days overdue. Louisiana has SEVEN, and the state
# published the dates itself.
#
# THE ADVISORY COUNCIL DECK IS SHARPER STILL, AND IT IS RCJ'S SOURCE. Slide 18
# of the 2026-08-20 deck is a table headed "RHTP Funding Cycle Budget Year 1"
# with four columns -- Activity | # Applications Received | Projected BY 1
# Funding | Anticipated Announcement:
#
#     Rural Clinician Credit Bank          136    $10 million     Mid August
#     Capital Improvement Program          160    $41.60 million  Late August
#     Telehealth                            79    $4.71 million   Late August
#     Collaborative Provider Model          37    $3 million      Early September
#     Alternative Payment Model             31    $30 million     Early September
#     Care conveners / navigation network   25    $3.5 million    Mid September
#     Food is Medicine                      37    $2.7 million    Mid September
#
# 505 APPLICATIONS RECEIVED, NOT ONE AWARD NAMED. That is §0.3 in the state's
# own table: applications received is not awards made.
#
# §0.1 -- OKLAHOMA'S TIER DEFECT, WITH THE STATE'S OWN COLUMN HEADING REFUTING
# IT. All six of RCJ's Louisiana Tier 3 candidates are rows of that table. The
# "awardee" is the ACTIVITY column -- "Alternative Payment Model", "Care
# conveners / navigation network", "Food is Medicine", "Telehealth", "Rural
# Clinician Credit Bank", "Collaborative Provider Model" -- which are fund uses
# and not organisations at all, so this is §6.1's PROGRAM_NAME_AS_AWARDEE on
# SIX OF SIX, and `named_recipient_test` reads PASS on every one. The amount is
# the "PROJECTED BY 1 FUNDING" column, multiplied by a million. Oklahoma's
# Legislative Quarterly Reports defined the column they were mined from
# ("Y1 Budget Allocation: The amount of funds dedicated to the program");
# Louisiana's deck says PROJECTED in the heading.
#
# AND IT DROPS THE LARGEST ROW, WHICH IS THE ONE MOST LIKELY TO REACH A
# HOSPITAL. The Capital Improvement Program -- 160 applications, $41.60
# million, awards of $100,000-$10,000,000 for facility renovation, medical
# equipment and technology infrastructure -- is not among RCJ's six. Its six
# sum to $53,910,000 against the deck's own seven at $95,510,000, so the
# aggregator UNDERSTATES the table it mined by $41,600,000. Michigan deflated
# by carrying one row per organisation; Louisiana deflates by dropping a row.
#
# THE CAPITAL NOFO'S ELIGIBLE CLASS IS HOSPITALS AMONG OTHERS: "Rural Health
# Clinics (RHCs), Federally Qualified Health Centers (FQHCs) or look-alikes,
# Critical Access Hospitals (CAHs), Rural hospitals, Rural EMS providers, Rural
# behavioral health or substance use providers, Independent rural practices".
# New Hampshire's FHC class, NOT Illinois's ICAHN class, so §0.3 governs it
# either way and it is a PASS_THROUGH_* question when it lands.
#
# THE HOST WANTS A Mozilla/5.0 PREFIX, AND THAT IS NOT MICHIGAN'S EXCEPTION.
# ldh.la.gov answers the project's own agent 403 AND bare "Mozilla/5.0" 403,
# while the RFC well-behaved-crawler convention -- "Mozilla/5.0 (compatible;
# AHA-RHTP-Tracker/0.1; +https://www.aha.org)" -- answers 200. That form
# carries our name and our contact URL, so it is session 10's medicaid.gov
# answer and not session 27's michigan.gov exception: IDENTIFYING HONESTLY IS
# STILL THE FIX, and the only thing this host additionally requires is the
# prefix. `robots.txt` is 404 -- genuinely absent, where Michigan's was 403 --
# so no crawler policy exists and none is being declined.
#
# THE SEVENTH DIGEST MECHANISM, AND THE SECOND THAT IS ATTRIBUTE-BORNE.
# ldh.la.gov runs Cloudflare Email Address Obfuscation, which XOR-encodes a
# mailto with a RANDOM ONE-BYTE KEY on every render, into an href and a
# `data-cfemail` attribute. Three fetches gave THREE distinct file digests at
# EXACTLY 169,500 bytes each -- California's antispambot() finding on a
# different platform, and constant-length like California's, so a byte-count
# check passes it. Because it lives in ATTRIBUTES rather than a script body it
# is Connecticut's `?v=` stamp structurally, and the reduction absorbs it for
# free: the reduced text is identical across all three at 21,249 characters.
# `--probe` therefore compares a CONTENT digest, never a file digest.
#
# ONE HOST IS UNREADABLE AND IS RECORDED AS UNREADABLE (§0.4). rhtla.net -- the
# "Rural Health Atlas", Louisiana's second RHTP site -- serves an unrendered
# Vue application whose mustache templates arrive as literal "{{ copy.brand }}"
# text. Maine's CGI Advantage portal and Connecticut's CTsource in a new
# costume. Its one readable data route, /api/facilities, is 3,576 named
# Louisiana facilities including 305 hospitals, with "award", "amount", "$",
# "RHTP" and "fund" occurring ZERO times each: A FACILITY REGISTRY FOR THE
# RURALITY-ELIGIBILITY TOOL, NOT AN AWARD ROSTER. It is archived as the §0.3
# control, because it is the largest machine-readable list of named Louisiana
# hospitals on the programme's own domain and carries no money at all.
#
# WHAT LOUISIANA HAS PROMISED, AND IT IS STILL NOT A ROSTER. The deck's own
# next-steps slide says the "Next Advisory Council meeting agenda [is] to
# include a complete list of obligated funds BY ENTITY TYPE". Even the
# publication Louisiana has committed to is by type, not by recipient.
#
# Usage:
#   --fetch [--force]  archive the 8 sources + SHA-256 manifest
#   --validate         the assertions and both controls, offline
#   --build            write the status + disposition CSVs AND, since session
#                      64, la_year1_awardees.csv (the RCCB round)
#   --probe            LIVE: has Louisiana awarded anything MORE?
#   --report           the negative, and the seven windows that have closed

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(stringr)
  library(purrr)
})

source(here::here("R", "utils_config.R"))

LA_EVIDENCE_DIR <- here::here("data", "evidence", "LA")
LA_STATUS_CSV   <- "data/reference/la_year1_status.csv"
LA_DISPO_CSV    <- "data/reference/la_rcj_candidate_disposition.csv"
LA_AWARDS_CSV   <- "data/reference/la_year1_awardees.csv"   # session 64: the RCCB
LA_HOST_THROTTLE_S <- 3

# THE RFC WELL-BEHAVED-CRAWLER CONVENTION, AND IT IS THE HONEST AGENT.
# ldh.la.gov refuses the project's bare agent (403) and bare "Mozilla/5.0"
# (403) alike, and answers 200 to this form, which carries the tracker's name
# AND its contact URL. Session 10 settled that identifying honestly is the fix
# rather than a workaround; this host merely also wants the Mozilla prefix.
# It is NOT §3's michigan.gov exception -- there the bare agent was the ONLY
# one that worked, and the honest tokens were what got refused.
LA_USER_AGENT <- paste(
  "Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1;",
  "+https://www.aha.org)"
)

LA_SOURCES <- tibble::tribble(
  ~key, ~file, ~url,

  "programme",
  "2026-09-21_la_ldh_rhtp_programme_SEVEN_WINDOWS_RE_DATED.html",
  "https://ldh.la.gov/page/rural-health-transformation-program",

  "funding",
  "2026-09-21_la_ldh_rhtp_funding_opportunities.html",
  "https://ldh.la.gov/page/rhtp-funding-opportunities",

  "news",
  "2026-04-07_la_ldh_governor_establishes_orhts.html",
  "https://ldh.la.gov/news/office-of-rural-health-transformation",

  "council",
  "2026-08-20_la_ldh_rhtp_advisory_council_slides_PROJECTED_FUNDING.pdf",
  paste0("https://ldh.la.gov/assets/docs/Secretary/RHTP/",
         "RHTP-Advisory-Council-Meeting-8.20.2026-Slides.pdf"),

  "capital_nofo",
  "2026-06-18_la_ldh_capital_improvement_NOFO_ROW_RCJ_DROPS.pdf",
  "https://ldh.la.gov/assets/docs/Secretary/RHTP/CapitalNOFO.pdf",

  "catalyst",
  "2026-05-27_la_led_rural_tech_catalyst_fund_SECOND_PUBLISHER.html",
  paste0("https://www.opportunitylouisiana.gov/news/",
         "louisiana-launches-rural-tech-catalyst-fund-to-advance-",
         "rural-health-care-innovation"),

  # THE SUPERSEDED PROGRAMME PAGE, KEPT RATHER THAN OVERWRITTEN. It is the only
  # evidence that LDH ever published the July/August windows, and therefore the
  # only evidence that it SLIPPED them. Alaska's device (session 22): a rolling
  # page's movement is measurable only against the snapshot it moved from.
  # Nothing parses it except la_assert_windows_slipped().
  "programme_prior",
  "2026-09-02_la_ldh_rhtp_programme_SEVEN_WINDOWS_PASSED_SUPERSEDED.html",
  "https://ldh.la.gov/page/rural-health-transformation-program",

  "atlas",
  "2026-09-02_la_rhtla_atlas_landing_UNREADABLE.html",
  "https://rhtla.net/landing",

  "facilities",
  "2026-09-02_la_rhtla_api_facilities_ELIGIBILITY_CONTROL.json",
  "https://rhtla.net/api/facilities"
)

# Every figure Louisiana states, in its own words.
LA_STATED <- list(
  footer_amount   = "$208,374,447.57",
  deck_award      = "Louisiana awarded $208,374,448",
  governor_amount = "supported by more than $208 million in federal funding",
  five_year       = "Estimated $1.4 billion over 5 years",
  capital_range   = "$100,000-$10,000,000",
  opportunities   = 7L,
  obligated_promise = "complete list of obligated funds by entity type"
)

LA_ARCHIVE_DATE <- as.Date("2026-09-02")

LA_CREDENTIAL_SHAPES <- c(
  mapbox_token   = "[ps]k\\.ey[A-Za-z0-9_-]{10,}",
  google_api_key = "AIza[A-Za-z0-9_-]{30,}",
  bearer_token   = "(?i)bearer\\s+[A-Za-z0-9._-]{25,}",
  aws_key        = "AKIA[A-Z0-9]{12,}"
)


# -- the announcement windows, parsed rather than transcribed ----------------
#
# LOUISIANA RE-DATED ALL SEVEN WINDOWS, AND THAT IS THE FINDING THIS CONTROL
# NOW CARRIES (session 46).
#
# Session 36 archived a page whose "IMPORTANT DATES - BUDGET YEAR 1" block read
# "Late July to mid August" x3 and "Mid to late August" x4, and all seven had
# closed. `la_assert_windows_passed()` pinned those two phrases and their
# counts, so when LDH moved the dates the assertion stopped the probe dead --
# 0 and 0 found, Louisiana's Routine halting on every firing from some point
# before 2026-09-21.
#
# The halt was CORRECT and the constant was not wrong: a figure that fails a
# check is a document to re-read, never a check to loosen (§0.2's rule, applied
# to a date instead of a dollar). Re-read, LDH's page now says:
#
#     End of September   x6   (Collaborative Provider, APM, Care Conveners,
#                              Food is Medicine, Telehealth, Capital)
#     Mid-September      x1   (Rural Clinician Credit Bank)
#
# Still seven windows against seven solicitations, still every application
# "Closed", still not one named recipient anywhere on the page. SO THE NEGATIVE
# IS UNCHANGED AND ONLY ITS CLOCK MOVED: Louisiana did not award, it slipped,
# by roughly six weeks.
#
# What changes here is how the control is written, because pinning two literal
# phrases is what broke. The windows are now PARSED out of the block and each
# one's latest date DERIVED, so a further slip re-dates the finding instead of
# halting the Routine -- while a window DISAPPEARING, or the seven ceasing to
# match the seven solicitations, still fails hard. The thing worth protecting
# was never the words "Mid to late August"; it was that every opportunity
# carries a published announcement date, which is what makes this negative a
# dated one rather than an open-ended absence.

LA_WINDOW_MONTHS <- c("January", "February", "March", "April", "May", "June",
                      "July", "August", "September", "October", "November",
                      "December")

# Every form LDH has actually used, and no more: "Late July to mid August",
# "Mid to late August", "End of September", "Mid-September". A window that does
# not match is REFUSED rather than guessed at (§0.4) -- an unparsed date
# silently treated as absent is how a slipped deadline reads as an award.
LA_WINDOW_RX <- paste0(
  "(?:Early|Mid|Late|End|Beginning)",
  "(?:[ -]to[ -](?:early|mid|late|end))?",
  "(?:[ -]of)?[ -]",
  "(?:", paste(LA_WINDOW_MONTHS, collapse = "|"), ")",
  "(?:[ -]to[ -](?:early|mid|late|end)[ -]",
  "(?:", paste(LA_WINDOW_MONTHS, collapse = "|"), "))?")

LA_NOIC_LABEL <- "Notice of Intent to Contract Announcements:"

#' The last date a stated window can mean
#'
#' Takes the LAST qualifier and the LAST month named, which is what a range
#' means: "Late July to mid August" ends mid-August, not late July. Early -> the
#' 10th, Mid -> the 15th, Late and End -> the month's last day. The latest
#' reading is deliberate: this date is used to say a window has PASSED, and
#' claiming that a day early would be this file asserting Louisiana is overdue
#' when it is not.
la_window_deadline <- function(window, year = 2026L) {
  quals  <- stringr::str_extract_all(window,
                                     "(?i)\\b(early|mid|late|end|beginning)\\b")[[1]]
  months <- stringr::str_extract_all(
    window, paste0("(?:", paste(LA_WINDOW_MONTHS, collapse = "|"), ")"))[[1]]
  if (!length(quals) || !length(months)) {
    stop("[LA] cannot date the announcement window '", window,
         "' -- it names no month or no part of one. REFUSING rather than ",
         "guessing: a window this file cannot date is a window it must not ",
         "report as passed or pending.", call. = FALSE)
  }
  qual  <- tolower(utils::tail(quals, 1L))
  month <- match(utils::tail(months, 1L), LA_WINDOW_MONTHS)
  first <- as.Date(sprintf("%d-%02d-01", year, month))
  last  <- seq(first, by = "month", length.out = 2L)[2L] - 1L
  switch(qual,
         "beginning" = first + 9L,
         "early"     = first + 9L,
         "mid"       = first + 14L,
         "late"      = last,
         "end"       = last)
}

#' Parse the "IMPORTANT DATES - BUDGET YEAR 1" block into one row per window
#'
#' PARSED, NEVER TRANSCRIBED (the §7.1 posture), so the status table cannot
#' drift from the page and a slip shows up as data rather than as a halt.
la_parse_windows <- function(programme = NULL) {
  p <- if (is.null(programme)) la_html_text("programme") else programme

  block <- stringr::str_match(
    p, "IMPORTANT DATES - BUDGET YEAR 1(.*?)Notice of Funding Opportunities")
  if (is.na(block[1, 2])) {
    stop("[LA] LDH's programme page no longer carries an 'IMPORTANT DATES - ",
         "BUDGET YEAR 1' block closed by 'Notice of Funding Opportunities'. ",
         "That block is where every announcement date this file reports comes ",
         "from -- re-read the page.", call. = FALSE)
  }
  body <- block[1, 2]

  # Each entry is "<programme> Application Submission Deadline for Year 1
  # Funds: <deadline> Notice of Intent to Contract Announcements: <window>",
  # run together with the next entry's programme name. Splitting on the
  # deadline label gives one chunk per entry, and the window is then anchored
  # at the head of the chunk's tail.
  hits <- stringr::str_match_all(
    body, paste0(LA_NOIC_LABEL, "\\s*(", LA_WINDOW_RX, ")"))[[1]]
  n_labels <- stringr::str_count(body, stringr::fixed(LA_NOIC_LABEL))

  if (nrow(hits) != n_labels) {
    stop("[LA] ", n_labels, " announcement windows are published and only ",
         nrow(hits), " could be parsed. An unparsed window is REFUSED rather ",
         "than dropped (§0.4): dropping it would shrink the seven silently. ",
         "Re-read the block -- LDH has used a date form this file has not ",
         "seen.", call. = FALSE)
  }

  names <- stringr::str_match_all(
    body,
    "([A-Z][^:]*?)\\s*Application Submission Deadline for Year 1 Funds:\\s*(\\w+)")[[1]]
  if (nrow(names) != nrow(hits)) {
    stop("[LA] the block names ", nrow(names), " solicitations against ",
         nrow(hits), " announcement windows. Every opportunity carrying a ",
         "published date is the finding; a mismatch means the block's shape ",
         "has changed -- re-read it.", call. = FALSE)
  }

  tibble::tibble(
    # The chunk before each deadline label carries the PREVIOUS entry's window
    # run together with this entry's name, so strip a leading window.
    programme = stringr::str_squish(stringr::str_remove(
      names[, 2], paste0("^\\s*", LA_WINDOW_RX, "\\s*"))),
    application = stringr::str_squish(names[, 3]),
    window = stringr::str_squish(hits[, 2])) %>%
    dplyr::mutate(
      window_ends = purrr::map_vec(.data$window, la_window_deadline),
      .after = "window")
}


# -- fetch --------------------------------------------------------------------

la_path <- function(key) {
  row <- LA_SOURCES[LA_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[LA] unknown source key: ", key, call. = FALSE)
  file.path(LA_EVIDENCE_DIR, row$file)
}

la_source <- function(key, field) {
  row <- LA_SOURCES[LA_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[LA] unknown source key: ", key, call. = FALSE)
  row[[field]]
}

la_assert_credential_free <- function(body, label) {
  chunk <- body[seq_len(min(length(body), 4e6))]
  txt   <- rawToChar(chunk[chunk != as.raw(0)])
  Encoding(txt) <- "latin1"
  for (nm in names(LA_CREDENTIAL_SHAPES)) {
    if (stringr::str_detect(txt, LA_CREDENTIAL_SHAPES[[nm]])) {
      stop("[LA] refusing to archive ", label, ": it carries what looks like ",
           "a ", nm, ".", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' The agent guard, so the Mozilla prefix cannot quietly become a bare agent
#'
#' §3's michigan.gov lesson as code: a one-host allowance becomes a default
#' the moment nothing refuses it elsewhere. This refuses an agent that does
#' NOT carry the tracker's identity and contact URL, whatever host it is for.
la_agent_for <- function(url, agent = LA_USER_AGENT) {
  if (!stringr::str_detect(agent, stringr::fixed("AHA-RHTP-Tracker")) ||
      !stringr::str_detect(agent, stringr::fixed("+https://www.aha.org"))) {
    stop("[LA] refusing an agent that does not identify this project and a ",
         "contact URL. ldh.la.gov wants the Mozilla/5.0 PREFIX; it does not ",
         "want anonymity, and bare 'Mozilla/5.0' is 403 here anyway. That is ",
         "session 10's rule, not session 27's exception.", call. = FALSE)
  }
  agent
}

la_get <- function(url, label) {
  message("[LA] fetching ", url)
  resp <- httr::GET(url, httr::user_agent(la_agent_for(url)),
                    httr::config(followlocation = TRUE), httr::timeout(240))
  if (httr::status_code(resp) != 200L) {
    stop("[LA] HTTP ", httr::status_code(resp), " for ", url, call. = FALSE)
  }
  served <- httr::content(resp, as = "raw")
  la_assert_credential_free(served, label)
  served
}

la_fetch <- function(force = FALSE) {
  dir.create(LA_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  entries <- purrr::map_dfr(seq_len(nrow(LA_SOURCES)), function(i) {
    src  <- LA_SOURCES[i, ]
    dest <- file.path(LA_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[LA] cached, not re-fetched: ", src$file)
    } else {
      if (i > 1L) Sys.sleep(LA_HOST_THROTTLE_S)
      writeBin(la_get(src$url, src$file), dest)
    }
    tibble::tibble(file = src$file, url = src$url, bytes = file.size(dest),
                   sha256 = digest::digest(file = dest, algo = "sha256"))
  })
  la_write_manifest(entries)
  invisible(entries)
}

la_write_manifest <- function(entries) {
  path <- file.path(LA_EVIDENCE_DIR, "MANIFEST.txt")
  writeLines(c(
    "Louisiana -- Rural Health Transformation Program, Year 1.",
    "Archived by R/03ae_la_year1_probe.R --fetch",
    paste0("User-agent: ", LA_USER_AGENT),
    "",
    "Every file is the body the server sent, BYTE FOR BYTE, written with",
    "writeBin(), so re-hashing a file on disk reproduces its digest below.",
    "The credential guard runs on every fetch and finds nothing, so there is",
    "no reduction to explain.",
    "",
    "THE USER-AGENT, AND WHY IT IS NOT MICHIGAN'S EXCEPTION. ldh.la.gov",
    "answers the project's own agent 403 and bare 'Mozilla/5.0' 403, and",
    "answers 200 to the RFC well-behaved-crawler convention above -- which",
    "carries the tracker's name AND its contact URL. Identifying honestly is",
    "still the fix (session 10, medicaid.gov); this host merely also wants the",
    "Mozilla prefix. Michigan inverts that -- there the identifying tokens are",
    "what get refused. robots.txt here is 404, GENUINELY ABSENT, where",
    "Michigan's is 403: no crawler policy exists and none is being declined.",
    "",
    "LOUISIANA HAS PUBLISHED NO RECIPIENT-LEVEL RHTP AWARD LIST, AND ALL SEVEN",
    "OF ITS OWN ANNOUNCEMENT WINDOWS HAVE CLOSED. LDH's programme page carries",
    "an 'IMPORTANT DATES - BUDGET YEAR 1' block giving a 'Notice of Intent to",
    "Contract Announcements' window for each of the seven Budget Year 1",
    "opportunities: 'Late July to mid August' x3 and 'Mid to late August' x4.",
    "This archive was taken 2026-09-02. Connecticut (session 35) was the first",
    "negative here whose award date had passed, with ONE solicitation sixteen",
    "days overdue; Louisiana has SEVEN, and published the dates itself.",
    "",
    "*_PROJECTED_FUNDING.pdf IS RCJ'S SOURCE AND ITS OWN REFUTATION.",
    "  Slide 18 of the 2026-08-20 Advisory Council deck is a table headed",
    "  'RHTP Funding Cycle Budget Year 1', columns Activity | # Applications",
    "  Received | PROJECTED BY 1 Funding | Anticipated Announcement. All SIX",
    "  RCJ Louisiana Tier 3 candidates are rows of it: the 'awardee' is the",
    "  ACTIVITY column (fund uses, not organisations -- §6.1's",
    "  PROGRAM_NAME_AS_AWARDEE on six of six) and the amount is the PROJECTED",
    "  column times a million. 505 applications received, NOT ONE AWARD NAMED.",
    "  The deck also promises only a 'complete list of obligated funds BY",
    "  ENTITY TYPE' next time -- by type, not by recipient.",
    "",
    "*_ROW_RCJ_DROPS.pdf is the Capital Improvement NOFO -- 160 applications,",
    "  $41.60 million projected, awards of $100,000-$10,000,000, and NOT among",
    "  RCJ's six. Its six sum to $53,910,000 against the deck's seven at",
    "  $95,510,000, so the aggregator understates the table it mined by",
    "  $41,600,000. Its eligible class is HOSPITALS AMONG OTHERS ('Critical",
    "  Access Hospitals (CAHs), Rural hospitals' beside RHCs, FQHCs, EMS,",
    "  behavioral health and independent rural practices) -- New Hampshire's",
    "  FHC class, not Illinois's ICAHN class, so §0.3 governs it either way.",
    "",
    "*_SECOND_PUBLISHER.html is LED's Rural Tech Catalyst Fund release, which",
    "  carries a programme-scoped provenance sentence from a publisher that is",
    "  not LDH: 'Supported through the Rural Health Transformation Program, a",
    "  more than $1 billion federal investment over five years'. It names no",
    "  recipient and no amount ('award' x0, 'recipient' x0).",
    "",
    "*_ELIGIBILITY_CONTROL.json IS A FACILITY REGISTRY, NOT AN AWARD ROSTER,",
    "  AND IT IS THE §0.3 TRAP. rhtla.net/api/facilities is 3,576 named",
    "  Louisiana facilities -- 305 hospitals (170 acute care, 135 specialty),",
    "  859 RHCs, 78 FQHCs -- with addresses, services and coordinates, on the",
    "  RHTP programme's own second domain. 'award', 'amount', '$', 'RHTP' and",
    "  'fund' occur ZERO times each. It is the dataset behind the 'Is my",
    "  location rural?' eligibility tool. California's 102 SRHRP eligible",
    "  hospitals in machine-readable form, and three times the size.",
    "",
    "*_UNREADABLE.html is rhtla.net's landing page and is recorded as UNKNOWN,",
    "  never as a negative (§0.4). It serves an unrendered Vue application:",
    "  its mustache templates arrive as literal '{{ copy.brand }}' text, so",
    "  whether the Atlas surfaces award data behind its parish profiles is a",
    "  statement about OUR ACCESS and not about Louisiana. Maine's CGI",
    "  Advantage portal and Connecticut's CTsource in a new costume.",
    "",
    "THESE FILE DIGESTS ARE NOT A CHANGE TEST, AND THE MECHANISM IS THE",
    "SEVENTH THIS PROJECT HAS MET. ldh.la.gov runs Cloudflare Email Address",
    "Obfuscation, which XOR-encodes a mailto with a RANDOM ONE-BYTE KEY on",
    "every render, into an href and a data-cfemail ATTRIBUTE. Three fetches",
    "gave THREE distinct file digests at EXACTLY 169,500 bytes each -- so it",
    "is California's antispambot() finding on a different platform, and",
    "CONSTANT-LENGTH like California's, which means a byte-count check passes",
    "it. Living in attributes rather than a script body makes it Connecticut's",
    "'?v=' stamp structurally, and the tag-stripping reduction absorbs it for",
    "free: reduced text IDENTICAL across all three at 21,249 characters.",
    "--probe compares a CONTENT digest via la_reduce_html(), never a file one.",
    "",
    "file  bytes  sha256",
    paste(entries$file, entries$bytes, entries$sha256, sep = "  ")
  ), path)
  invisible(path)
}


# -- readers ------------------------------------------------------------------

#' The one HTML reduction, so the probe and the assertions read the same bytes
#'
#' Missouri's rule (session 29). Stripping TAGS -- and with them every
#' attribute -- is what absorbs Cloudflare's per-render email obfuscation.
la_reduce_html <- function(raw) {
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "UTF-8"
  txt <- stringr::str_remove_all(txt, "(?s)<(script|style)[^>]*>.*?</\\1>")
  txt <- stringr::str_replace_all(txt, "<[^>]+>", " ")
  txt <- rhtp_la_unescape(txt)
  txt <- stringr::str_remove_all(txt, "[​‌‍﻿]")
  stringr::str_squish(txt)
}

rhtp_la_unescape <- function(x) {
  x <- stringr::str_replace_all(x, "&nbsp;|&#160;", " ")
  x <- stringr::str_replace_all(x, "&amp;", "&")
  x <- stringr::str_replace_all(x, "&#39;|&rsquo;|&#8217;", "'")
  x <- stringr::str_replace_all(x, "&quot;|&ldquo;|&rdquo;", '"')
  x <- stringr::str_replace_all(x, "&lt;", "<")
  x <- stringr::str_replace_all(x, "&gt;", ">")
  x <- stringr::str_replace_all(x, "&#8211;|&ndash;", "-")
  x <- stringr::str_replace_all(x, "[‘’‛]", "'")
  x <- stringr::str_replace_all(x, "[“”‟]", '"')
  x <- stringr::str_replace_all(x, "[‐‑‒–—]", "-")
  x
}

la_html_text <- function(key, body = NULL) {
  if (is.null(body)) {
    p <- la_path(key)
    body <- readBin(p, "raw", file.size(p))
  }
  la_reduce_html(body)
}

la_pdf_text <- function(key, body = NULL) {
  if (!exists("rhtp_pdf_text")) source(here::here("R", "utils_pdf_text.R"))
  path <- if (is.null(body)) {
    la_path(key)
  } else {
    tmp <- tempfile(fileext = ".pdf"); writeBin(body, tmp); tmp
  }
  stringr::str_squish(paste(rhtp_pdf_text(path), collapse = " "))
}

#' The §7.1 allotment anchor for Louisiana, read rather than typed
la_allotment_anchor <- function() {
  path <- here::here("data", "reference", "cms_fy2026_allotments.csv")
  a <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  v <- a$fy2026_allotment[a$state == "LA"]
  if (length(v) != 1L) {
    stop("[LA] the §7.1 anchor does not carry exactly one LA row.",
         call. = FALSE)
  }
  v
}

#' The §6.2 NOA date anchor for Louisiana, read rather than typed
#'
#' It is the BUDGET PERIOD START (2025-12-29), never a Notice of Award form's
#' later "Federal Award Date" -- see rhtp_build_noa_dates() in
#' R/02b_provenance_sweep.R, which records why that distinction is load-bearing.
la_noa_anchor <- function() {
  path <- here::here("data", "reference", "cms_state_noa_dates.csv")
  if (!file.exists(path)) return(as.Date("2025-12-29"))
  d <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  v <- d$noa_date[d$state == "LA"]
  if (length(v) != 1L) return(as.Date("2025-12-29"))
  as.Date(v)
}

#' Slide 18's funding-cycle table, parsed rather than transcribed
#'
#' The deck's producer paints these cells without separating spaces
#' ("Rural Clinician CreditBank136$10millionMid August"), so the columns are
#' recovered by shape: a name, an application COUNT, a PROJECTED figure in
#' millions, and an announcement window. Returned in document order.
la_deck_funding_cycle <- function(body = NULL) {
  t <- if (is.null(body)) la_pdf_text("council") else body
  # The segment starts AFTER the column headings. Without that the lazy name
  # capture swallows "Anticipated Announcement" into the first row's activity,
  # because the headings and the first row are painted contiguously.
  seg <- stringr::str_extract(
    t, "(?<=Anticipated Announcement).*?(?=Exciting Opportunities)")
  if (is.na(seg)) {
    stop("[LA] slide 18's funding-cycle table is no longer in the Advisory ",
         "Council deck. It is the disposition's whole evidence base.",
         call. = FALSE)
  }
  m <- stringr::str_match_all(
    seg,
    paste0("([A-Z][A-Za-z/ ]*?)\\s*(\\d{2,3})\\s*\\$([0-9.]+)\\s*million",
           "\\s*(Early|Mid|Late)\\s*(July|August|September)")
  )[[1]]
  tibble::tibble(
    activity     = stringr::str_squish(m[, 2]),
    applications = as.integer(m[, 3]),
    projected    = as.numeric(m[, 4]) * 1e6,
    announcement = paste(m[, 5], m[, 6])
  )
}


# -- assertions ---------------------------------------------------------------

#' The provenance, carried by programme-scoped sentences and not by the footer
#'
#' Session 27's audit: LDH's footer is the WEAK form ("This project is
#' supported by"), so it corroborates the AMOUNT and three programme-scoped
#' sentences from THREE publishers carry the provenance.
la_assert_programme_provenance <- function(programme = NULL, news = NULL,
                                           catalyst = NULL, council = NULL) {
  p <- if (is.null(programme)) la_html_text("programme") else programme
  n <- if (is.null(news)) la_html_text("news") else news
  c0 <- if (is.null(catalyst)) la_html_text("catalyst") else catalyst
  d <- if (is.null(council)) la_pdf_text("council") else council

  if (!stringr::str_detect(p, stringr::fixed(
        "The Louisiana Rural Health Transformation Program (RHTP) is a"))) {
    stop("[LA] LDH's RHTP page no longer opens with its programme-scoped ",
         "sentence. The CMS footer alone is the WEAK form (session 27) and ",
         "does not replace it.", call. = FALSE)
  }
  if (!stringr::str_detect(n, stringr::fixed(LA_STATED$governor_amount))) {
    stop("[LA] the Governor's 2026-04-07 release no longer states that RHTP ",
         "is federally funded. That is the second programme-scoped sentence, ",
         "from a second publisher.", call. = FALSE)
  }
  if (!stringr::str_detect(c0, stringr::fixed(
        "Supported through the Rural Health Transformation Program"))) {
    stop("[LA] LED's Rural Tech Catalyst Fund release no longer ties the fund ",
         "to RHTP. That is the third programme-scoped sentence, and the only ",
         "one published by an agency other than LDH.", call. = FALSE)
  }
  if (!stringr::str_detect(d, stringr::fixed(LA_STATED$deck_award))) {
    stop("[LA] the Advisory Council deck no longer states Louisiana's award. ",
         "It is what ties slide 18's table to RHTP.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The CMS footer corroborates the AMOUNT, and is demoted (session 27)
la_assert_footer_corroborates <- function(strict = FALSE, programme = NULL) {
  t <- if (is.null(programme)) la_html_text("programme") else programme
  if (!stringr::str_detect(t, stringr::fixed(LA_STATED$footer_amount))) {
    msg <- paste0("[LA] the CMS financial-assistance footer (",
                  LA_STATED$footer_amount, ") is no longer on LDH's RHTP ",
                  "page. It is the WEAK form and corroborates the amount ",
                  "only; the provenance is carried by three programme-scoped ",
                  "sentences.")
    if (strict) stop(msg, call. = FALSE)
    message(msg); return(invisible(NA))
  }
  cents <- as.numeric(stringr::str_remove_all(LA_STATED$footer_amount, "[$,]"))
  if (round(cents) != la_allotment_anchor()) {
    stop("[LA] the footer amount ", LA_STATED$footer_amount, " no longer ",
         "rounds to the §7.1 anchor ", la_allotment_anchor(), ".",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Everything Louisiana has solicited postdates its Notice of Award
la_assert_after_noa <- function(capital = NULL) {
  t <- if (is.null(capital)) la_pdf_text("capital_nofo") else capital
  if (!stringr::str_detect(t, stringr::fixed("June 18, 2026"))) {
    stop("[LA] the Capital Improvement NOFO no longer carries its own ",
         "publication date. Texas's HHS0015180 closed before its state had ",
         "the money; that ordering is what rules the defect out here.",
         call. = FALSE)
  }
  if (as.Date("2026-06-18") <= la_noa_anchor()) {
    stop("[LA] the Capital Improvement NOFO no longer postdates Louisiana's ",
         "Notice of Award.", call. = FALSE)
  }
  invisible(TRUE)
}

#' THE TRIPWIRE: no WATCHED surface carries award language
#'
#' DESIGNED TO FAIL. Three surfaces at once -- the programme page (which
#' carries the announcement dates), the funding-opportunities page (which
#' carries the seven solicitations) and the Advisory Council deck (which is
#' where Louisiana reports progress to its own Council).
#'
#' SESSION 64: LOUISIANA HAS AWARDED ONE SOLICITATION, AND NOT ON THESE
#' SURFACES. The Rural Clinician Credit Bank's 53 awards were reported in a
#' separate stakeholder deck (LA_RCCB_ARCHIVE), which is now an award source
#' for la_year1_awardees.csv. This tripwire keeps watching the three pages for
#' the OTHER six solicitations -- and for the RCCB's missing 48 names. If it
#' fires, read the page: new names for the RCCB move out of the aggregate row;
#' a roster for another solicitation is a new pool in the award file.
LA_AWARD_POSTED <- c(
  "has been awarded", "have been awarded", "awardees are",
  "selected for award", "list of awardees", "grant recipients",
  "funded organizations", "successful applicant", "notice of award"
)

la_assert_no_award_roster <- function(programme = NULL, funding = NULL,
                                      council = NULL) {
  p <- if (is.null(programme)) la_html_text("programme") else programme
  f <- if (is.null(funding)) la_html_text("funding") else funding
  d <- if (is.null(council)) la_pdf_text("council") else council

  for (nm in c("programme", "funding", "council")) {
    t <- switch(nm, programme = p, funding = f, council = d)
    hit <- LA_AWARD_POSTED[purrr::map_lgl(
      LA_AWARD_POSTED,
      ~ stringr::str_detect(t, stringr::regex(.x, ignore_case = TRUE)))]
    if (length(hit)) {
      stop("[LA] award language has appeared on the ", nm, " surface: ",
           paste(hit, collapse = " | "),
           ". THAT IS THE SIGNAL, NOT A DEFECT. Louisiana may have published ",
           "a recipient-level roster: read it, and rewrite this file as an ",
           "award extractor rather than adjusting this constant.",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' SEVEN OPPORTUNITIES, SEVEN PUBLISHED ANNOUNCEMENT WINDOWS
#'
#' The invariant this control protects, and the only one it ever should have
#' protected: EVERY Louisiana Budget Year 1 solicitation carries an
#' announcement date LDH published itself, and the seven windows match the
#' funding page's seven "Strategic Funding Opportunity Title" headings. That is
#' what makes this negative a dated one rather than an open-ended absence, and
#' it survives LDH re-dating the windows -- which LDH has now done.
#'
#' Which windows have passed is DERIVED against `asof`, never asserted. On
#' 2026-09-21 that is one of seven (Rural Clinician Credit Bank, Mid-September);
#' the other six close on 2026-09-30. A previous version of this function
#' asserted that all seven had passed, which was true when it was written and
#' would now be false -- a claim about a state read off a constant rather than
#' off the state's own page (§0.4).
la_assert_windows_published <- function(programme = NULL, funding = NULL,
                                        asof = Sys.Date()) {
  p <- if (is.null(programme)) la_html_text("programme") else programme
  f <- if (is.null(funding)) la_html_text("funding") else funding

  w <- la_parse_windows(p)
  n_opps <- stringr::str_count(f, stringr::fixed(
    "Strategic Funding Opportunity Title"))

  if (nrow(w) != LA_STATED$opportunities || n_opps != LA_STATED$opportunities) {
    stop("[LA] ", nrow(w), " announcement windows against ", n_opps,
         " solicitations, and this file's finding rests on ",
         LA_STATED$opportunities, " of each. A window that has stopped being ",
         "published is the case to read first: LDH removing a date is what an ",
         "award looks like from here.", call. = FALSE)
  }

  # Every application still closed. If one re-opens, the negative changes shape
  # -- an unawarded solicitation taking applications again is not the same
  # finding as one whose window has merely slipped.
  reopened <- w$programme[!grepl("^Closed$", w$application, ignore.case = TRUE)]
  if (length(reopened)) {
    stop("[LA] these solicitations no longer read 'Closed': ",
         paste(reopened, collapse = "; "),
         ". Re-read the funding page.", call. = FALSE)
  }

  invisible(w %>% dplyr::mutate(passed = .data$window_ends < asof))
}

#' LDH SLIPPED EVERY WINDOW, AND THE SUPERSEDED SNAPSHOT IS WHAT PROVES IT
#'
#' Read out of two committed archives rather than out of a session note: the
#' 2026-09-02 copy carries the July/August windows and the 2026-09-21 copy
#' carries the September ones. Asserting the movement from the documents is
#' what stops "Louisiana slipped" becoming a claim this repository makes on its
#' own authority (§0.4) -- and it is the reason the superseded file is kept
#' rather than overwritten.
la_assert_windows_slipped <- function(programme = NULL, prior = NULL) {
  now_w   <- la_parse_windows(if (is.null(programme)) la_html_text("programme")
                              else programme)
  prior_w <- la_parse_windows(if (is.null(prior)) la_html_text("programme_prior")
                              else prior)

  if (nrow(now_w) != nrow(prior_w)) {
    stop("[LA] the superseded snapshot carries ", nrow(prior_w),
         " windows and the current page ", nrow(now_w),
         ". The slip is only measurable while both name the same seven.",
         call. = FALSE)
  }
  if (!all(now_w$window_ends >= prior_w$window_ends)) {
    stop("[LA] a window has moved EARLIER between the two snapshots. That is ",
         "not a slip and this file does not describe it -- re-read both.",
         call. = FALSE)
  }
  if (all(now_w$window_ends == prior_w$window_ends)) {
    stop("[LA] the two snapshots carry identical windows, so the superseded ",
         "copy is no longer evidence of anything and this assertion is ",
         "claiming a slip that did not happen.", call. = FALSE)
  }
  invisible(tibble::tibble(programme = now_w$programme,
                           was = prior_w$window, was_ends = prior_w$window_ends,
                           now = now_w$window, now_ends = now_w$window_ends,
                           slipped_days = as.integer(now_w$window_ends -
                                                       prior_w$window_ends)))
}

#' The deck's column heading is PROJECTED, and its rows are APPLICATIONS
#'
#' Oklahoma's tier defect with the state's own heading refuting it. Both halves
#' are asserted: that the funding column says "Projected", and that the row
#' counts are applications RECEIVED rather than awards made.
la_assert_deck_is_projected_not_awarded <- function(council = NULL) {
  t <- if (is.null(council)) la_pdf_text("council") else council
  for (k in c("RHTP Funding Cycle Budget Year 1", "ProjectedBY 1 Funding",
              "Applications", "Anticipated Announcement")) {
    if (!stringr::str_detect(t, stringr::fixed(k))) {
      stop("[LA] slide 18 no longer carries '", k, "'. The heading is what ",
           "makes these figures Tier 2 rather than awards.", call. = FALSE)
    }
  }
  cyc <- la_deck_funding_cycle(t)
  if (nrow(cyc) != LA_STATED$opportunities) {
    stop("[LA] slide 18 parsed ", nrow(cyc), " rows, expected ",
         LA_STATED$opportunities, ".", call. = FALSE)
  }
  if (sum(cyc$applications) != 505L) {
    stop("[LA] slide 18's applications no longer total 505 (found ",
         sum(cyc$applications), "). 505 applications and no named award is ",
         "§0.3 in the state's own table.", call. = FALSE)
  }
  if (round(sum(cyc$projected)) != 95510000) {
    stop("[LA] slide 18's projected funding no longer totals $95,510,000 ",
         "(found ", format(sum(cyc$projected), big.mark = ","), ").",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' THE POSITIVE CONTROL: Louisiana publishes announcement dates, so silence
#' is the programme's and not our reading
#'
#' A negative is only a finding if the publisher demonstrably publishes in a
#' recognisable form. Louisiana's control is unusually strong and unusually
#' cheap: it names, for each opportunity, the FORM the announcement will take
#' ("Notice of Intent to Contract") and the WINDOW it will take it in. So
#' "no roster" is measured against Louisiana's own stated intention.
la_assert_announcement_control <- function(programme = NULL, funding = NULL,
                                           council = NULL) {
  p <- if (is.null(programme)) la_html_text("programme") else programme
  f <- if (is.null(funding)) la_html_text("funding") else funding
  d <- if (is.null(council)) la_pdf_text("council") else council

  if (!stringr::str_detect(p, stringr::fixed("IMPORTANT DATES - BUDGET YEAR 1"))) {
    stop("[LA] LDH's programme page no longer carries its 'IMPORTANT DATES' ",
         "block. Without it, 'Louisiana has published no roster' is ",
         "indistinguishable from 'we are reading the wrong page'.",
         call. = FALSE)
  }
  if (!stringr::str_detect(f, stringr::fixed(
        "Notice of Intent to Contract Announcements - Early to Mid-July"))) {
    stop("[LA] the funding page no longer carries the Rural Clinician Credit ",
         "Bank's own announcement window. It is the earliest of the seven and ",
         "the longest overdue.", call. = FALSE)
  }
  # And even what Louisiana has PROMISED is not a roster.
  if (!stringr::str_detect(d, stringr::fixed(LA_STATED$obligated_promise))) {
    stop("[LA] the deck no longer promises a 'complete list of obligated ",
         "funds by entity type'. That sentence is what says the publication ",
         "Louisiana has committed to is BY TYPE, not by recipient.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' THE §0.3 CONTROL: the Atlas facility registry carries no money at all
#'
#' 3,576 named Louisiana facilities including 305 hospitals, on the RHTP
#' programme's own second domain, and not one dollar figure. California's 102
#' SRHRP eligible hospitals in machine-readable form and three times the size.
la_assert_facilities_are_not_awards <- function(body = NULL) {
  p <- la_path("facilities")
  txt <- if (is.null(body)) {
    readChar(p, file.size(p), useBytes = TRUE)
  } else body
  for (k in c("\"award", "\"amount", "RHTP", "$")) {
    if (stringr::str_detect(txt, stringr::fixed(k))) {
      stop("[LA] rhtla.net/api/facilities now carries '", k, "'. It has been ",
           "a FACILITY REGISTRY with no money in it, which is why it is ",
           "archived as the §0.3 control. If it now carries awards, read it: ",
           "it is a recipient-level source and this file must be rewritten.",
           call. = FALSE)
    }
  }
  if (!stringr::str_detect(txt, stringr::fixed("\"display_type\""))) {
    stop("[LA] the facilities registry no longer has its display_type field; ",
         "the control cannot be read.", call. = FALSE)
  }
  invisible(TRUE)
}

# la_assert_no_award_file() WAS RETIRED IN SESSION 64. It asserted that
# la_year1_awardees.csv did not exist, and it said in its own error message
# what to do the day that changed: "write the extractor deliberately and
# delete this assertion in the same commit". Louisiana awarded the Rural
# Clinician Credit Bank, so the file exists; la_assert_award_file() and
# la_assert_status_has_no_amount() (below, in the RCCB section) replace it.

rhtp_la_assert <- function(strict_footer = FALSE) {
  la_assert_programme_provenance()
  la_assert_footer_corroborates(strict = strict_footer)
  la_assert_after_noa()
  la_assert_no_award_roster()
  la_assert_windows_published()
  la_assert_windows_slipped()
  la_assert_deck_is_projected_not_awarded()
  la_assert_announcement_control()
  la_assert_facilities_are_not_awards()
  la_assert_status_has_no_amount()
  la_assert_rccb_award()
  invisible(TRUE)
}


# -- the status table ---------------------------------------------------------

#' What each Louisiana RHTP channel publishes
#'
#' DELIBERATELY NO `amount` COLUMN (Texas's device, and Wisconsin's, Maine's,
#' California's, Connecticut's and New Mexico's after it). Since session 64 the
#' one priced Louisiana round -- the Rural Clinician Credit Bank -- lives in
#' la_year1_awardees.csv; the pool figures here stay the state's own words in
#' `stated_pool`, which cannot be summed by accident, and six of seven are
#' still PROJECTED figures.
rhtp_la_year1_status <- function() {
  # `window_key` is the programme string EXACTLY as LDH's "IMPORTANT DATES"
  # block prints it, and it is what `stage` and `announcement_window` are
  # joined on below. An exact hand-written key rather than a fuzzy name match
  # (§2), visible in the file, on Arkansas's AR_RELEASE_SPELLINGS footing: a
  # key that stops matching fails the build instead of quietly dropping a row.
  # The two non-solicitation rows carry NA and keep their own stage.
  out <- tibble::tribble(
    ~window_key, ~channel, ~administrator, ~stated_pool, ~stage,
    ~announcement_window, ~eligible_class, ~publishes_roster, ~evidence,

    "Rural Health Transformation Program (RHTP) Rural Health Facilities Capital Improvement Program",
    "Rural Health Facilities Capital Improvement Program -- THE POOL TO WATCH",
    "LDH", "$41.60 million projected; awards $100,000-$10,000,000",
    "FROM_PAGE", "FROM_PAGE",
    paste("HOSPITALS AMONG OTHERS. 'Rural Health Clinics (RHCs), Federally",
          "Qualified Health Centers (FQHCs) or look-alikes, Critical Access",
          "Hospitals (CAHs), Rural hospitals, Rural EMS providers, Rural",
          "behavioral health or substance use providers, Independent rural",
          "practices'. New Hampshire's FHC class, NOT Illinois's ICAHN class,",
          "so §0.3 governs it either way."),
    "No",
    paste("160 applications received -- the most of the seven -- and the",
          "largest projected pool. Capital investment in facility renovation,",
          "medical equipment and technology infrastructure, executed through a",
          "Cooperative Endeavor Agreement. RCJ DOES NOT CARRY THIS ROW."),

    "Rural Medicaid Alternative Payment Model Program",
    "Rural Medicaid Alternative Payment Model Program", "LDH",
    "$30 million projected", "FROM_PAGE", "FROM_PAGE",
    paste("Rural providers building infrastructure to participate in",
          "value-based care; population of focus is rural Louisiana Medicaid",
          "members and the providers serving them."),
    "No",
    paste("31 applications. Application deadline 2026-08-07. RCJ's largest",
          "Louisiana candidate at $30,000,000 -- which is this PROJECTED pool."),

    "Rural Health Transformation Program (RHTP) Rural Clinician Credit Bank Program",
    "Rural Clinician Credit Bank", "LDH",
    "$10 million projected", "FROM_PAGE", "FROM_PAGE",
    "Recruitment and retention of talent in rural healthcare settings.",
    "No",
    paste("136 applications. THE LONGEST OVERDUE: the funding page still reads",
          "'Applications currently under review' against an announcement",
          "window of 'Early to Mid-July'."),

    "Rural Health Transformation Program (RHTP) Telehealth Infrastructure for Rural Access Program",
    "Telehealth Infrastructure for Rural Access Program", "LDH",
    "$4.71 million projected", "FROM_PAGE", "FROM_PAGE",
    "Telehealth infrastructure investments across rural Louisiana.",
    "No",
    "79 applications. Application deadline 2026-07-10, shown as 'Closed'.",

    "Regional Care Conveners and Navigation Networks Program",
    "Regional Care Conveners and Navigation Networks Program", "LDH",
    "$3.5 million projected", "FROM_PAGE", "FROM_PAGE",
    paste("Regional conveners aligning providers across acute care,",
          "behavioral health and social services -- Missouri's ToRCH hub",
          "shape, so a PASS_THROUGH_* question when it lands, never a direct",
          "award."),
    "No",
    "25 applications. Application deadline 2026-08-14.",

    "Rural Collaborative Provider Models Program",
    "Rural Collaborative Provider Models Program", "LDH",
    "$3 million projected", "FROM_PAGE", "FROM_PAGE",
    paste("Collaborative provider models extending specialist coverage and",
          "pooling staff across rural FACILITIES -- hospitals among others."),
    "No",
    "37 applications. Application deadline 2026-08-05.",

    "Food is Medicine Program",
    "Food is Medicine Program", "LDH",
    "$2.7 million projected", "FROM_PAGE", "FROM_PAGE",
    paste("Start-up of food-is-medicine programmes 'in collaboration with",
          "health care providers and community-based organizations'."),
    "No",
    "37 applications. Application deadline 2026-08-14.",

    NA_character_,
    "Rural Tech Catalyst Fund", "LED / Louisiana Innovation (LA.IO)",
    "not stated", "ANNOUNCED_NOT_SOLICITED", "not stated",
    paste("'health care providers, entrepreneurs, investors, universities and",
          "technology companies' -- hospitals are not named as a class."),
    "No",
    paste("Launched 2026-05-27 by LED, not LDH. Carries the third and only",
          "non-LDH programme-scoped provenance sentence: 'Supported through",
          "the Rural Health Transformation Program, a more than $1 billion",
          "federal investment over five years'. Names no recipient and no",
          "amount ('award' x0, 'recipient' x0)."),

    NA_character_,
    "Rural Health Atlas (rhtla.net)", "LDH",
    "not applicable", "UNREADABLE", "not applicable",
    "not applicable",
    "UNKNOWN",
    paste("An unrendered Vue application: its mustache templates arrive as",
          "literal '{{ copy.brand }}' text, so whether the Atlas surfaces",
          "award data behind its parish profiles is a statement about OUR",
          "ACCESS, never about Louisiana (§0.4). Maine's CGI Advantage portal",
          "and Connecticut's CTsource in a new costume. Its one readable data",
          "route, /api/facilities, is 3,576 named facilities including 305",
          "hospitals with NO money in it -- the §0.3 control, not a roster.")
  )

  # DERIVED FROM THE PAGE, NOT TRANSCRIBED. `stage` was a hand-typed
  # CLOSED_AWARD_DATE_PASSED on all seven rows until session 46, which was true
  # when it was typed and false the moment LDH re-dated the windows -- a status
  # table asserting a state had passed its own deadline when six of seven had
  # not. Reading both columns off the block makes the table move when the page
  # does.
  w <- la_parse_windows() %>%
    dplyr::mutate(
      announcement_window = .data$window,
      stage = ifelse(.data$window_ends < Sys.Date(),
                     "CLOSED_AWARD_DATE_PASSED", "CLOSED_AWARD_DATE_PENDING"))

  missing <- setdiff(stats::na.omit(out$window_key), w$programme)
  if (length(missing)) {
    stop("[LA] window_key no longer matches LDH's block: ",
         paste(missing, collapse = "; "),
         ". An exact key that stops matching fails here rather than dropping ",
         "the row's date in silence (§2).", call. = FALSE)
  }

  out <- out %>%
    dplyr::rows_update(
      w %>% dplyr::select(window_key = "programme", "stage",
                          "announcement_window"),
      by = "window_key", unmatched = "ignore")

  # SESSION 64: THE RCCB HAS AWARDED, AND ITS STAGE IS READ OFF THE DECK, NOT
  # OFF THE WINDOW. The programme page still prints its "Mid-September"
  # window and the funding page still reads "Applications currently under
  # review", while LDH's own September 3 deck reports 53 awards made as of
  # 8/28/26. The pages lag the deck; the deck is the award source. The stage
  # is only set here while la_assert_rccb_award() holds.
  la_assert_rccb_award()
  rccb <- !is.na(out$window_key) & stringr::str_detect(out$window_key,
                                                       "Clinician Credit Bank")
  out$stage[rccb] <- "AWARDED_5_OF_53_NAMED"
  out$stated_pool[rccb] <- paste(
    "$10 million projected ('Allocation of record $10.00M'); $12,701,996",
    "awarded across 53 awards as of 8/28/26")
  out$publishes_roster[rccb] <- "Partial -- 5 of 53 awardees named"
  out$evidence[rccb] <- paste(
    "136 applications, 70 eligible, 53 awards made, $12,701,996 awarded 'As",
    "of 8/28/26', CEAs 'due for signature 9/15/26' (LDH's September 3, 2026",
    "stakeholder deck). Five 'Multi-parish awardees' are named and priced",
    "($1,965,788) and are rows of la_year1_awardees.csv; the other 48",
    "($10,736,208, LDH's parish table) are named nowhere and are ONE",
    "aggregate row there. 20 of the 53 are 'Hospital settings' ($6,285,515)",
    "and none of those is named. The programme page's window and the funding",
    "page's 'Applications currently under review' LAG the deck.")
  out %>% dplyr::select(-"window_key")
}


# -- RCJ candidate disposition ------------------------------------------------

la_rcj_candidates <- function() {
  rt <- rhtp_record_table_live()
  rt %>% dplyr::filter(.data$state == "LA", .data$award_tier == "SUBAWARD")
}

LA_DECK_SOURCE_MARKER <- "RHTP Advisory Council"
LA_RCCB_SOURCE_MARKER <- "RHTP Updates September 2026"
LA_RTCF_SOURCE_MARKER <- "Rural Tech Catalyst Fund"

# Session 63: the LDH deck that disposes of the five NEW Rural Clinician Credit
# Bank rows on the 2026-09-24 pull. Archived read-only with its own manifest;
# it is NOT in LA_SOURCES, because the probe does not watch it.
LA_RCCB_ARCHIVE <- file.path(
  "data", "evidence", "recheck", "2026-09-24", "LA",
  "2026-09-09_la_ldh_rhtp_stakeholder_webinar_RCCB_53_AWARDS.pdf")
LA_RCCB_URL <- paste0("https://ldh.la.gov/assets/docs/Secretary/RHTP/",
                      "Shareholder-Presentation-09092026.pdf")

la_rows_from <- function(cands, marker) {
  cands[stringr::str_detect(cands$source_doc_title, stringr::fixed(marker)), ,
        drop = FALSE]
}

#' The candidates mined from slide 18 of the 2026-08-20 Advisory Council deck
#'
#' The two deck assertions below were written when every Louisiana candidate
#' came from that table. Since the 2026-09-24 pull six do not, so they read
#' this subset; the disposition's coverage check refuses anything else.
la_deck_candidates <- function(cands = NULL) {
  if (is.null(cands)) cands <- la_rcj_candidates()
  la_rows_from(cands, LA_DECK_SOURCE_MARKER)
}

la_rccb_text <- function() {
  if (!exists("rhtp_pdf_text")) source(here::here("R", "utils_pdf_text.R"))
  stringr::str_squish(paste(rhtp_pdf_text(here::here(LA_RCCB_ARCHIVE)),
                            collapse = " "))
}

#' The five RCCB rows ARE the deck's named multi-parish awardees, to the dollar
#'
#' LDH's 2026-09-09 stakeholder deck names five of its 53 Rural Clinician
#' Credit Bank awards (the "Multi-parish awardees" table) and prices each.
#' The deck's producer welds the parish count onto the name
#' ("Ochsner Clinic Foundation8$1,500,000"), so the match allows it.
la_assert_rccb_rows_are_ldh_awards <- function(cands = NULL, txt = NULL) {
  if (is.null(cands)) cands <- la_rows_from(la_rcj_candidates(),
                                            LA_RCCB_SOURCE_MARKER)
  if (is.null(txt)) txt <- la_rccb_text()
  for (need in c("Awards made53", "Amount awarded$12,701,996",
                 "CEAs due for signature9/15/26")) {
    if (!stringr::str_detect(txt, stringr::fixed(need))) {
      stop("[LA] LDH's 2026-09-09 deck no longer reads '", need, "'.",
           call. = FALSE)
    }
  }
  for (i in seq_len(nrow(cands))) {
    pat <- paste0(stringr::str_replace_all(cands$awardee_name_clean[i],
                                           "([.()$^*+?|\\[\\]\\\\])", "\\\\\\1"),
                  "\\s?\\d{1,2}\\s?\\$",
                  format(cands$amount_announced[i], big.mark = ",",
                         scientific = FALSE))
    if (!stringr::str_detect(txt, pat)) {
      stop("[LA] RCJ's '", cands$awardee_name_clean[i], "' at $",
           format(cands$amount_announced[i], big.mark = ","),
           " is not a named, priced awardee on LDH's 2026-09-09 deck. The ",
           "disposition rests on all five being exactly that.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' Why each of RCJ's Louisiana Tier 3 candidates is, or is not, a subaward
#'
#' The counts and the sums are RE-DERIVED from the record table on every run
#' (Texas's device), and the table REFUSES a live candidate no group
#' describes, so the day Louisiana's candidate set moves the build fails
#' instead of this table quietly ceasing to cover it.
rhtp_la_rcj_disposition <- function(cands = NULL) {
  if (is.null(cands)) cands <- la_rcj_candidates()
  deck <- la_rows_from(cands, LA_DECK_SOURCE_MARKER)
  rccb <- la_rows_from(cands, LA_RCCB_SOURCE_MARKER)
  rtcf <- la_rows_from(cands, LA_RTCF_SOURCE_MARKER)
  covered <- nrow(deck) + nrow(rccb) + nrow(rtcf)
  if (covered != nrow(cands) ||
      anyDuplicated(c(deck$record_id, rccb$record_id, rtcf$record_id))) {
    stop("[LA] ", nrow(cands) - covered, " Louisiana Tier 3 candidate(s) come ",
         "from none of the three documents this disposition covers (slide 18 ",
         "of the Advisory Council deck; LDH's September 2026 update deck; ",
         "LED's Rural Tech Catalyst Fund release). No group describes them. ",
         "Read the new ones before building: ",
         paste(setdiff(unique(cands$source_doc_title),
                       c(deck$source_doc_title, rccb$source_doc_title,
                         rtcf$source_doc_title)), collapse = " | "),
         call. = FALSE)
  }
  money <- function(x) format(sum(x, na.rm = TRUE), big.mark = ",",
                              scientific = FALSE)
  n_all <- nrow(cands)

  tibble::tribble(
    ~group, ~disposition, ~rows, ~rcj_amount, ~mechanism, ~disqualifying_fact,
    ~state_source_url, ~source_archive_path,

    "Rural Clinician Credit Bank -- LDH's five named multi-parish awardees",
    "RHTP_SUBAWARD", nrow(rccb), sum(rccb$amount_announced, na.rm = TRUE),
    paste0(
      "REAL LOUISIANA RHTP AWARDS, AND THE FIRST THIS REPOSITORY HAS SEEN. ",
      nrow(rccb), " of Louisiana's ", n_all, " live Tier 3 candidates, first ",
      "seen on the 2026-09-24 pull, all from LDH's September 3, 2026 ",
      "stakeholder webinar deck, served as Shareholder-Presentation-09092026.pdf (RCJ: 'LA - 2026 - RHTP Updates September 2026', linked ",
      "from the RHTP programme page as 'Webinar Slides'). RCJ's names and ",
      "amounts are LDH's own, to the dollar ($", money(rccb$amount_announced),
      " between them): ", paste(rccb$awardee_name_clean, collapse = "; "),
      ". Stage 2 flags 'SR Minden, Southern Roots' MULTI_RECIPIENT_FIELD; ",
      "LDH prints it as ONE awardee string, so it is one award, not split."),
    paste0(
      "Nothing disqualifies them, and that is the finding. The deck says ",
      "'Rural Clinician Credit Bank Awards -- Year 1 NOFO: $10.0M ",
      "advertised, $12.70M awarded ... As of 8/28/26': 136 applications, 70 ",
      "eligible, 'Awards made 53', 'Amount awarded $12,701,996', 'CEAs due ",
      "for signature 9/15/26'. By facility type it gives 8 small rural ",
      "hospitals ($3,291,553), 11 critical access hospitals ($2,948,962) and ",
      "1 rural emergency hospital ($45,000) -- 'Hospital settings 20 awards ",
      "$6,285,515' -- and NAMES ONLY THESE FIVE, the 'Multi-parish awardees'. ",
      "The other 48 awards, including all 20 hospital awards, are counted and ",
      "unnamed (§0.3: a count is not a list). LOUISIANA IS THEREFORE NO ",
      "LONGER A CLEAN NEGATIVE: it has awarded one of its seven Budget Year ",
      "1 solicitations. EXTRACTED IN SESSION 64 FROM LDH'S OWN DECK, NOT ",
      "FROM THESE ROWS: the five are rows 1-5 of la_year1_awardees.csv, ",
      "read from the deck's own table cells, and the other 48 are ONE ",
      "aggregate row there with an empty amount and LDH's parish-table sum ",
      "($10,736,208) in round_amount. Ochsner Clinic Foundation's $1,500,000 ",
      "is LDH's stated 'Ceiling applied per multi-entity system'; its ",
      "recipient form is not stated by LDH and is NOT typed here (§0.4)."),
    "https://ldh.la.gov/page/rural-health-transformation-program",
    LA_RCCB_ARCHIVE,

    "Slide 18 of the 2026-08-20 Advisory Council deck -- fund uses, PROJECTED",
    "RHTP_BUT_NOT_A_SUBAWARD", nrow(deck), sum(deck$amount_announced, na.rm = TRUE),
    paste0(
      "TIER (Oklahoma's defect), and §6.1's PROGRAM_NAME_AS_AWARDEE on ",
      nrow(deck), " OF ", nrow(deck), ", unchanged since the 2026-08-27 ",
      "pull. All are rows of ONE table -- slide 18 of the 2026-08-20 ",
      "Advisory Council deck, headed 'RHTP Funding Cycle Budget Year 1'. The ",
      "'awardee' is the ACTIVITY column (",
      paste(deck$awardee_name_clean, collapse = "; "), "), which are fund ",
      "uses and not organisations at all -- and `named_recipient_test` reads ",
      "PASS on every one. The amount is the 'Projected BY 1 Funding' column ",
      "times a million. One of them, 'Rural Clinician Credit Bank', is the ",
      "programme whose five named awards sit in the row above: the $",
      money(deck$amount_announced[stringr::str_detect(
        deck$awardee_name_clean, "Credit Bank")]),
      " here is the PROJECTION, against $12,701,996 awarded."),
    paste0(
      "The deck's own column heading reads 'ProjectedBY 1 Funding' against ",
      "'# Applications Received', and its seven rows record 505 APPLICATIONS ",
      "with not one award named. Louisiana says PROJECTED in the heading. ",
      "AND RCJ DROPS THE LARGEST ROW: Capital Improvement, 160 applications ",
      "and $41.60 million, is not among these rows, so they sum to $",
      money(deck$amount_announced), " against the deck's seven at ",
      "$95,510,000 -- the aggregator UNDERSTATES the table it mined by ",
      "$41,600,000, and the row it drops is the CAPITAL one, the likeliest ",
      "to reach a hospital."),
    "https://ldh.la.gov/page/rural-health-transformation-program",
    paste0("data/evidence/LA/2026-08-20_la_ldh_rhtp_advisory_council_slides_",
           "PROJECTED_FUNDING.pdf"),

    "Louisiana Innovation (LA.IO) -- the Rural Tech Catalyst Fund's administrator",
    "RHTP_BUT_NOT_A_SUBAWARD", nrow(rtcf), sum(rtcf$amount_announced, na.rm = TRUE),
    paste0(
      nrow(rtcf), " of Louisiana's ", n_all, " live Tier 3 candidates, first ",
      "seen on the 2026-09-24 pull, from LED's 2026-05-27 launch release, ",
      "priced at $", money(rtcf$amount_announced), " (Missouri's ",
      "placeholder). The 'awardee' is the STATE UNIT THAT RUNS THE FUND, not ",
      "a recipient of it: §6.1's administering agency as awardee."),
    paste0(
      "LED's own release: 'The initiative will be managed through Louisiana ",
      "Innovation (LA.IO), a division of LED' -- a state agency division -- ",
      "and it announces the fund's LAUNCH with applications open; it names ",
      "no award and no recipient."),
    paste0("https://www.opportunitylouisiana.gov/news/louisiana-launches-",
           "rural-tech-catalyst-fund-to-advance-rural-health-care-innovation"),
    paste0("data/evidence/LA/2026-05-27_la_led_rural_tech_catalyst_fund_",
           "SECOND_PUBLISHER.html")
  )
}

#' The six candidates ARE the deck's activity column, asserted rather than said
la_assert_candidates_are_deck_activities <- function(cands = NULL,
                                                     council = NULL) {
  if (is.null(cands)) cands <- la_deck_candidates()
  cyc <- la_deck_funding_cycle(council)

  # LETTERS ONLY, SPACES INCLUDED IN THE STRIP. The deck's producer paints
  # "Food isMedicine" and "Rural Clinician CreditBank" -- two runs on one line
  # separated by pen POSITIONING rather than a space glyph, which session 32
  # measured and which the reader cannot recover without font metrics. So the
  # comparison cannot depend on the deck's word spacing.
  norm <- function(x) tolower(stringr::str_remove_all(x, "[^A-Za-z]"))
  deck <- norm(cyc$activity)
  rcj  <- norm(cands$awardee_name_raw)

  miss <- rcj[!purrr::map_lgl(rcj, function(r) {
    any(purrr::map_lgl(deck, ~ stringr::str_detect(.x, stringr::fixed(r)) ||
                              stringr::str_detect(r, stringr::fixed(.x))))
  })]
  if (length(miss)) {
    stop("[LA] these RCJ candidates no longer match a row of slide 18's ",
         "table: ", paste(miss, collapse = " | "), ". The disposition rests ",
         "on all six being rows of that table.", call. = FALSE)
  }

  # And the amounts are the PROJECTED column, to the dollar.
  for (i in seq_len(nrow(cands))) {
    r <- norm(cands$awardee_name_raw[i])
    j <- which(purrr::map_lgl(deck, ~ stringr::str_detect(.x, stringr::fixed(r)) ||
                                      stringr::str_detect(r, stringr::fixed(.x))))[1]
    if (round(cands$amount_announced[i]) != round(cyc$projected[j])) {
      stop("[LA] candidate '", cands$awardee_name_raw[i], "' carries ",
           format(cands$amount_announced[i], big.mark = ","),
           " against slide 18's ", format(cyc$projected[j], big.mark = ","),
           ". The amounts matching the PROJECTED column is what makes the ",
           "tier defect provable rather than asserted.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' RCJ DROPS THE LARGEST ROW, and it is the capital one
la_assert_capital_row_dropped <- function(cands = NULL, council = NULL) {
  if (is.null(cands)) cands <- la_deck_candidates()
  cyc <- la_deck_funding_cycle(council)

  cap <- cyc[stringr::str_detect(cyc$activity, "Capital"), ]
  if (nrow(cap) != 1L || round(cap$projected) != 41600000) {
    stop("[LA] slide 18 no longer carries exactly one Capital Improvement row ",
         "at $41,600,000.", call. = FALSE)
  }
  if (any(stringr::str_detect(cands$awardee_name_raw, "(?i)capital"))) {
    stop("[LA] RCJ now carries the Capital Improvement row. It has been the ",
         "row the aggregator drops -- the largest of the seven, and the one ",
         "likeliest to reach a hospital. Re-read the disposition: the ",
         "$41,600,000 understatement no longer holds.", call. = FALSE)
  }
  if (round(sum(cyc$projected) - sum(cands$amount_announced, na.rm = TRUE)) !=
      41600000) {
    stop("[LA] the gap between slide 18's seven rows and RCJ's six is no ",
         "longer exactly the Capital Improvement row.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- session 64: THE RURAL CLINICIAN CREDIT BANK AWARD FILE -------------------
#
# LOUISIANA HAS AWARDED ONE OF ITS SEVEN BUDGET YEAR 1 SOLICITATIONS, AND IT
# NAMES FIVE OF FIFTY-THREE RECIPIENTS.
#
# LDH's September 3, 2026 stakeholder webinar deck -- linked from the RHTP
# programme page under "September 3, 2026 ... Webinar Slides", served as
# Shareholder-Presentation-09092026.pdf -- reports the Rural Clinician Credit
# Bank "As of 8/28/26": "Awards made 53", "Amount awarded $12,701,996", "CEAs
# due for signature 9/15/26". It names exactly five awardees, in a table
# headed "Multi-parish awardees", each with a printed amount. The other 48 are
# counted and located (a "Parishes by dollars awarded" table) and NOT NAMED.
#
# THE FILE HOLDS EVERY AWARD EXACTLY ONCE, AND THAT IS WHY IT HAS NO
# HOSPITAL-ONLY AGGREGATE ROW. LDH also splits the 53 by facility type -- 20
# "Hospital settings" awards / $6,285,515 against 33 "Clinic and outpatient
# settings" / $6,416,481 -- but it never says which facility type any of the
# five NAMED awardees is. So a "20 unnamed hospital awards" row would overlap
# the named rows by up to five awards and $1,965,788 in a way nobody can
# resolve from the document. What the document DOES resolve exactly is the
# other partition: its parish table covers the 48 single-home-parish awards and
# sums to $10,736,208, which is $12,701,996 - $1,965,788 TO THE DOLLAR, and
# 48 + 5 = 53. So the file is five named rows plus ONE aggregate row for the 48
# unnamed awards (South Dakota's / Oklahoma ROOTS' device: `amount` empty, the
# figure in `round_amount`). That aggregate is a MIXED class -- between 15 and
# 20 of its 48 are hospital-setting awards, and LDH does not say which -- so it
# is South Dakota's `Unclear`, and it enters NO hospital bucket. The
# hospital-setting figure is carried as the state's own words in the row and in
# la_year1_status.csv, never as a summable column.
#
# EVERY ROW IS PRE-AGREEMENT. LDH's own process is a "Notice of Intent to
# Contract" followed by a Cooperative Endeavor Agreement, and the CEAs were
# "due for signature 9/15/26", after the deck's as-of date. So every row is
# NOTICE_OF_INTENT_TO_AWARD + amount_confirmed = No (Maryland's and Wyoming's
# posture).

LA_RCCB_STATED <- list(
  as_of              = "As of 8/28/26",
  applications       = 136L,
  eligible           = 70L,
  awards             = 53L,
  awarded            = 12701996,
  application_close  = as.Date("2026-06-25"),
  cea_due            = "9/15/26",
  hospital_awards    = 20L,
  hospital_amount    = 6285515,
  clinic_awards      = 33L,
  clinic_amount      = 6416481,
  named_awards       = 5L,
  named_total        = 1965788,
  single_parish      = 48L,
  single_parish_total = 10736208,
  multi_entity_ceiling = 1500000,
  footer_amount      = "$208,374,447.57",
  webinar_date       = as.Date("2026-09-03")
)

LA_RCCB_HOSPITAL_TYPES <- c("Small rural hospital", "Critical access hospital",
                            "Rural emergency hospital")

la_rccb_runs <- function() {
  if (!exists("rhtp_pdf_runs")) source(here::here("R", "utils_pdf_text.R"))
  r <- rhtp_pdf_runs(here::here(LA_RCCB_ARCHIVE))
  r[nzchar(trimws(r$text)), , drop = FALSE]
}

# One painted line of one page, as its runs.
la_rccb_lines <- function(runs, pg) {
  x <- runs[runs$page == pg, , drop = FALSE]
  unname(split(trimws(x$text), x$line))
}

la_money <- function(x) as.numeric(stringr::str_remove_all(x, "[$,]"))

#' The five NAMED awardees, read from their own painted cells (page 10)
la_rccb_named <- function(runs = NULL) {
  if (is.null(runs)) runs <- la_rccb_runs()
  ln <- la_rccb_lines(runs, 10)
  hdr <- which(vapply(ln, function(v) identical(v, c("Awardee", "Parishes", "Award")),
                      logical(1)))
  tot <- which(vapply(ln, function(v) length(v) == 2L && v[1] == "Total",
                      logical(1)))
  tot <- tot[tot > hdr[1]]
  if (length(hdr) != 1L || !length(tot)) {
    stop("[LA] the deck's 'Multi-parish awardees' table is no longer where ",
         "this file reads it (page 10: header 'Awardee | Parishes | Award' ",
         "then a 'Total' line).", call. = FALSE)
  }
  body <- ln[(hdr + 1):(tot[1] - 1)]
  bad <- !vapply(body, function(v) length(v) == 3L &&
                   grepl("^\\d+$", v[2]) && grepl("^\\$[0-9,]+$", v[3]),
                 logical(1))
  if (any(bad)) {
    stop("[LA] a 'Multi-parish awardees' row is not name | parishes | $amount: ",
         paste(vapply(body[bad], paste, character(1), collapse = " | "),
               collapse = " ;; "), call. = FALSE)
  }
  tibble::tibble(
    awardee  = vapply(body, `[`, character(1), 1),
    parishes = as.integer(vapply(body, `[`, character(1), 2)),
    amount   = la_money(vapply(body, `[`, character(1), 3)),
    printed_total = la_money(ln[[tot[1]]][2])
  )
}

#' The facility-type table (page 8): six types and a Total line
la_rccb_facility_types <- function(runs = NULL) {
  if (is.null(runs)) runs <- la_rccb_runs()
  ln <- la_rccb_lines(runs, 8)
  rows <- Filter(function(v) length(v) == 6L && grepl("^\\d+$", v[2]) &&
                   grepl("^\\$[0-9,]+$", v[4]), ln)
  tibble::tibble(
    facility_type = vapply(rows, `[`, character(1), 1),
    awards        = as.integer(vapply(rows, `[`, character(1), 2)),
    amount        = la_money(vapply(rows, `[`, character(1), 4))
  )
}

#' The parish table (page 10): two parish/award/amount triples per line
la_rccb_parishes <- function(runs = NULL) {
  if (is.null(runs)) runs <- la_rccb_runs()
  ln <- la_rccb_lines(runs, 10)
  rows <- Filter(function(v) length(v) == 6L && grepl("^\\d+$", v[2]) &&
                   grepl("^\\$[0-9,]+$", v[3]), ln)
  dplyr::bind_rows(lapply(rows, function(v) tibble::tibble(
    parish = v[c(1, 4)], awards = as.integer(v[c(2, 5)]),
    amount = la_money(v[c(3, 6)]))))
}

#' EVERYTHING THE DECK STATES ABOUT THE RCCB ROUND, CLOSED ON ITSELF
#'
#' Four independent closures, none arranged by this file: the facility table
#' sums to its own Total line; the three hospital types sum to the deck's
#' "Hospital settings" figure and the other three to "Clinic and outpatient
#' settings"; the five named awards sum to the table's own printed Total; and
#' the parish table (the 48 single-home-parish awards) plus the five named
#' multi-parish awards is the whole round, to the dollar. Plus provenance: the
#' deck is LDH's RHTP update, its footer is the Tier 1 allotment (WEAK form,
#' corroborating the amount only, §0.2), the solicitation closed after the NOA,
#' and the RCCB is one of the seven solicitations LDH's funding page carries.
la_assert_rccb_award <- function(txt = NULL, runs = NULL, funding = NULL,
                                 programme = NULL) {
  if (is.null(txt)) txt <- la_rccb_text()
  if (is.null(runs)) runs <- la_rccb_runs()
  if (is.null(funding)) funding <- la_html_text("funding")
  if (is.null(programme)) programme <- la_html_text("programme")
  S <- LA_RCCB_STATED
  money <- function(x) format(x, big.mark = ",", scientific = FALSE, trim = TRUE)

  for (need in c("Rural Health Transformation Program Updates",
                 "Rural Clinician Credit Bank", S$as_of,
                 paste0("Awards made", S$awards),
                 paste0("Amount awarded$", money(S$awarded)),
                 paste0("CEAs due for signature", S$cea_due),
                 "Application close6/25/26",
                 paste0("Ceiling applied per multi-entity system$",
                        money(S$multi_entity_ceiling)),
                 paste0(S$single_parish, " awards with a single home parish"),
                 "5 multi-parish awardees",
                 paste0("financial assistance award totaling ", S$footer_amount))) {
    if (!stringr::str_detect(txt, stringr::fixed(need))) {
      stop("[LA] LDH's September 2026 deck no longer reads '", need, "'. The ",
           "RCCB award file rests on it.", call. = FALSE)
    }
  }

  # PROVENANCE. The footer is "This project supported by" -- session 27's WEAK
  # form -- and its figure IS the allotment, so it is Tier 1 and corroborates
  # nothing about the RCCB except that the deck is LDH's RHTP publication.
  rhtp_assert_footer_not_allotment(la_money(S$footer_amount), "LA",
                                   "STATE_ALLOTMENT",
                                   label = "LDH's September 2026 deck footer")
  if (!stringr::str_detect(funding, stringr::fixed(
        "Strategic Funding Opportunity Title: Rural Clinician Credit Bank"))) {
    stop("[LA] the funding page no longer lists the Rural Clinician Credit Bank ",
         "among its RHTP solicitations. That is what ties the deck's awards to ",
         "one of LDH's seven Budget Year 1 opportunities.", call. = FALSE)
  }
  if (!stringr::str_detect(programme, stringr::fixed("September 3, 2026"))) {
    stop("[LA] the programme page no longer lists the 'September 3, 2026' ",
         "webinar whose slides this file reads.", call. = FALSE)
  }
  if (S$application_close <= la_noa_anchor()) {
    stop("[LA] the RCCB application close no longer postdates the NOA.",
         call. = FALSE)
  }

  ft <- la_rccb_facility_types(runs)
  tot <- ft[ft$facility_type == "Total", ]
  ft  <- ft[ft$facility_type != "Total", ]
  if (nrow(ft) != 6L || nrow(tot) != 1L ||
      sum(ft$awards) != S$awards || sum(ft$amount) != S$awarded ||
      tot$awards != S$awards || tot$amount != S$awarded) {
    stop("[LA] the facility-type table no longer closes on 53 awards / ",
         "$12,701,996.", call. = FALSE)
  }
  hosp <- ft[ft$facility_type %in% LA_RCCB_HOSPITAL_TYPES, ]
  if (nrow(hosp) != 3L || sum(hosp$awards) != S$hospital_awards ||
      sum(hosp$amount) != S$hospital_amount ||
      !stringr::str_detect(txt, stringr::fixed(paste0(
        S$hospital_awards, " awards · $", money(S$hospital_amount))))) {
    stop("[LA] the three hospital facility types no longer sum to the deck's ",
         "'Hospital settings 20 awards $6,285,515'.", call. = FALSE)
  }
  clin <- ft[!ft$facility_type %in% LA_RCCB_HOSPITAL_TYPES, ]
  if (sum(clin$awards) != S$clinic_awards || sum(clin$amount) != S$clinic_amount) {
    stop("[LA] the other three facility types no longer sum to 'Clinic and ",
         "outpatient settings 33 awards $6,416,481'.", call. = FALSE)
  }

  nm <- la_rccb_named(runs)
  if (nrow(nm) != S$named_awards || sum(nm$amount) != S$named_total ||
      nm$printed_total[1] != S$named_total) {
    stop("[LA] the 'Multi-parish awardees' table no longer names five ",
         "awardees summing to its own printed $1,965,788.", call. = FALSE)
  }
  pa <- la_rccb_parishes(runs)
  if (sum(pa$awards) != S$single_parish ||
      sum(pa$amount) != S$single_parish_total) {
    stop("[LA] the parish table no longer carries 48 awards / $10,736,208.",
         call. = FALSE)
  }
  if (S$single_parish + nrow(nm) != S$awards ||
      S$single_parish_total + sum(nm$amount) != S$awarded) {
    stop("[LA] the 48 unnamed single-parish awards plus the five named ",
         "multi-parish awards no longer make the whole round.", call. = FALSE)
  }
  invisible(list(named = nm, facility = ft, parishes = pa))
}

#' The Louisiana award file: five named RCCB awards and ONE unnamed aggregate
rhtp_la_year1_awardees <- function(runs = NULL) {
  if (!exists("rhtp_classify_recipient_type")) {
    source(here::here("R", "utils_recipient_classification.R"))
  }
  if (is.null(runs)) runs <- la_rccb_runs()
  nm <- la_rccb_named(runs)
  S  <- LA_RCCB_STATED
  title <- "Rural Health Transformation Program Updates -- September 2026 (LDH stakeholder webinar, 2026-09-03)"
  desc  <- paste("Rural Clinician Credit Bank: recruitment and retention of",
                 "clinicians in rural healthcare settings")

  machine <- rhtp_classify_recipient_type(nm$awardee, state_code = "LA")

  # "Outpatient Medical Center" hits §8's "Medical Center" token and the
  # classifier answers HOSPITAL_OR_SYSTEM at HIGH. It is REFUSED -- sent to the
  # standing fallback, where an undetermined form belongs (Michigan's
  # parenthesis override, session 27) -- because the name's own first word
  # says OUTPATIENT, LDH's own deck sorts its awards into "Hospital settings"
  # and "Clinic and OUTPATIENT settings", and no source states this
  # recipient's form. Keeping the machine's answer would put $292,500 into
  # NAMED_HOSPITAL on a token the name itself contradicts; refusing it is
  # one-directional and queued. Nothing is PROMOTED here, and nothing is
  # demoted on this pipeline's private knowledge: the reason is on the page.
  refuse <- nm$awardee %in% "Outpatient Medical Center"
  rtype  <- ifelse(refuse, "NONPROFIT_CBO", machine$recipient_type)
  conf   <- ifelse(refuse, "LOW", machine$determination_confidence)
  if (any(rtype %in% c("HOSPITAL_OR_SYSTEM", "HOSPITAL_AFFILIATED_ENTITY"))) {
    stop("[LA] a named RCCB awardee now types as a hospital: ",
         paste(nm$awardee[rtype %in% c("HOSPITAL_OR_SYSTEM",
                                       "HOSPITAL_AFFILIATED_ENTITY")],
               collapse = "; "),
         ". LDH states no awardee's form; re-read before letting a name ",
         "rule move a dollar into NAMED_HOSPITAL.", call. = FALSE)
  }
  flow <- rhtp_classify_flow(rtype, rep(desc, length(rtype)))

  source_note <- ifelse(
    refuse,
    paste0("§8's shared classifier returns '", machine$recipient_type,
           "' at ", machine$determination_confidence, " on the 'Medical ",
           "Center' token. REFUSED and sent to §8's standing fallback: the ",
           "name's own first word is 'Outpatient', LDH's deck groups ",
           "awards into 'Hospital settings' and 'Clinic and outpatient ",
           "settings', and no source states this recipient's form. The ",
           "machine answer is kept here so the refusal is auditable and ",
           "reversible."),
    paste0("§8's shared classifier: '", machine$recipient_type, "' at ",
           machine$determination_confidence, ". LDH names this recipient and ",
           "states nothing about its form."))

  ochsner_note <- paste(
    "LDH's deck prints 'Ceiling applied per multi-entity system $1,500,000'",
    "and this is the only $1,500,000 award, so LDH is describing this",
    "awardee as a MULTI-ENTITY SYSTEM whose request was capped. It does not",
    "say what kind of system, and it is NOT typed as a hospital here (§0.4);",
    "queued.")

  named <- tibble::tibble(
    state = "LA",
    row_no = seq_len(nrow(nm)),
    awardee = nm$awardee,
    amount = nm$amount,
    recipient_type = rtype,
    distributed_to_hospital = flow$distributed_to_hospital,
    note = paste0(
      "Rural Clinician Credit Bank, Year 1. One of LDH's five named ",
      "'Multi-parish awardees' (", nm$parishes, " parishes), $",
      format(nm$amount, big.mark = ",", scientific = FALSE, trim = TRUE),
      ", as of 8/28/26. CEAs were due for signature 9/15/26, so this is an ",
      "award LDH reports as made whose agreement was not yet executed.",
      ifelse(nm$awardee == "Ochsner Clinic Foundation",
             paste0(" ", ochsner_note), ""),
      ifelse(nm$awardee == "SR Minden, Southern Roots",
             paste0(" LDH prints this as ONE awardee string with ONE amount; ",
                    "Stage 2 flags it MULTI_RECIPIENT_FIELD, but it is one ",
                    "award and is not split (§6.2)."), "")),
    recipient_confirmed = "Yes",
    amount_confirmed = "No",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = title,
    state_source_url = LA_RCCB_URL,
    validation_source_type = "NOTICE_OF_INTENT_TO_AWARD",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03ae_la_year1_probe.R",
    ccn = NA_character_, aha_id = NA_character_,
    rural_designation = NA_character_, reviewer = NA_character_,
    awardee_as_published = nm$awardee,
    parishes_served = nm$parishes,
    recipient_type_source = source_note,
    determination_confidence = conf,
    flag_reason = ifelse(rtype == "NONPROFIT_CBO" & conf == "LOW",
                         "RECIPIENT_TYPE_INFERRED", NA_character_),
    award_pool = "Rural Clinician Credit Bank",
    budget_period = "Budget Year 1",
    flow_type = flow$flow_type,
    hospital_benefiting = flow$hospital_benefiting,
    hospital_attribution = "NOT_HOSPITAL",
    intermediary_name = NA_character_,
    determination_basis = paste0(
      "LDH's September 3, 2026 stakeholder deck, slide 'Awards across 28 ",
      "parishes', table 'Multi-parish awardees', names this recipient and ",
      "prints its award; the round is 'Awards made 53 ... Amount awarded ",
      "$12,701,996 ... As of 8/28/26'. recipient_confirmed = Yes, ",
      "amount_confirmed = No because the CEAs were 'due for signature ",
      "9/15/26' (Maryland's offers, Wyoming's approvals). LDH states no ",
      "recipient's organisational form and no facility type for any named ",
      "awardee, so the type is §8's standing fallback and the row is ",
      "distributed_to_hospital = ", flow$distributed_to_hospital,
      "; the uncertainty is one-directional and queued, and nothing is ",
      "promoted on this pipeline's own knowledge (§0.4)."),
    amount_basis = "STATED_PER_RECIPIENT",
    round_awards = NA_integer_,
    round_amount = NA_real_,
    recipient_class = NA_character_,
    as_of_date = as.Date("2026-08-28"),
    announcement_date = S$webinar_date,
    source_archive_path = LA_RCCB_ARCHIVE
  )

  agg <- tibble::tibble(
    state = "LA",
    row_no = nrow(nm) + 1L,
    awardee = paste("48 Rural Clinician Credit Bank awards (single home parish)",
                    "- recipient names not published"),
    amount = NA_real_,
    recipient_type = "NOT_YET_NAMED",
    distributed_to_hospital = "Unclear",
    note = paste(
      "LDH reports 53 RCCB awards and names five. The other 48 are counted in",
      "its 'Parishes by dollars awarded' table (48 awards with a single home",
      "parish, 20 parish lines summing to $10,736,208) and NAMED NOWHERE (§0.3:",
      "a count is not a list). The round's facility split is 20 'Hospital",
      "settings' awards / $6,285,515 (8 small rural hospitals $3,291,553; 11",
      "critical access hospitals $2,948,962; 1 rural emergency hospital",
      "$45,000) and 33 'Clinic and outpatient settings' / $6,416,481 -- but",
      "LDH never says which type any named awardee is, so between 15 and 20",
      "of THESE 48 are hospital-setting awards and the row cannot be split",
      "by class without imputing."),
    recipient_confirmed = "No",
    amount_confirmed = "No",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = title,
    state_source_url = LA_RCCB_URL,
    validation_source_type = "NOTICE_OF_INTENT_TO_AWARD",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03ae_la_year1_probe.R",
    ccn = NA_character_, aha_id = NA_character_,
    rural_designation = NA_character_, reviewer = NA_character_,
    awardee_as_published = NA_character_,
    parishes_served = NA_integer_,
    recipient_type_source = paste(
      "LDH names none of these 48 recipients. It states a facility-type split",
      "for the whole round of 53 and not for these 48."),
    determination_confidence = "LOW",
    flag_reason = "RECIPIENT_NAMES_NOT_CAPTURED",
    award_pool = "Rural Clinician Credit Bank",
    budget_period = "Budget Year 1",
    flow_type = "PASS_THROUGH_UNRESOLVED",
    hospital_benefiting = "Yes",
    hospital_attribution = "NOT_HOSPITAL",
    intermediary_name = NA_character_,
    determination_basis = paste(
      "South Dakota's aggregate-round device, for South Dakota's reason: a",
      "MIXED recipient class with no names. §7 codes a page that 'names no",
      "recipients' Unclear, mechanically. It is NOT Georgia's",
      "surgical-robotics row (a stated all-hospital class coded Yes): LDH's",
      "hospital-setting figure (20 awards / $6,285,515) is a split of the",
      "WHOLE round of 53, the five named multi-parish awardees are inside it",
      "in facility types LDH does not disclose, and a hospital-only aggregate",
      "row would therefore overlap the named rows by up to five awards and",
      "$1,965,788 with no way to resolve it from the document. And it is NOT",
      "POOL_UNNAMED_HOSPITALS: that code is Illinois's executed award to a",
      "pass-through INTERMEDIARY restricted to hospitals, and there is no",
      "intermediary here and no hospitals-only class. This row therefore",
      "enters no hospital bucket; hospital_benefiting = Yes because LDH says",
      "at least 15 of these 48 awards are to hospital settings. 'Facility",
      "type' is LDH's description of the funded facility, which is not",
      "necessarily the legal recipient (§0.3a) -- a second reason not to read",
      "it as a recipient count. `amount` is deliberately EMPTY and the",
      "$10,736,208 is in round_amount, so no sum over `amount` can read it as",
      "a per-recipient figure (§6.2); it is LDH's own parish table summed,",
      "and it equals $12,701,996 - $1,965,788 to the dollar."),
    amount_basis = "ROUND_TOTAL_NOT_PER_RECIPIENT",
    round_awards = S$single_parish,
    round_amount = S$single_parish_total,
    recipient_class = paste(
      "Mixed: of the full round of 53, 20 hospital-setting awards / $6,285,515",
      "and 33 clinic/outpatient-setting / $6,416,481; of these 48, between 15",
      "and 20 are hospital-setting (LDH does not map the named five)."),
    as_of_date = as.Date("2026-08-28"),
    announcement_date = S$webinar_date,
    source_archive_path = LA_RCCB_ARCHIVE
  )

  dplyr::bind_rows(named, agg)
}

#' The award file's own invariants
la_assert_award_file <- function(awards = NULL) {
  if (is.null(awards)) {
    path <- here::here(LA_AWARDS_CSV)
    if (!file.exists(path)) {
      stop("[LA] ", LA_AWARDS_CSV, " is missing. Louisiana has awarded the ",
           "Rural Clinician Credit Bank (session 64); run --build.",
           call. = FALSE)
    }
    awards <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE,
                              col_types = readr::cols(.default = "c"))
  }
  num <- function(x) suppressWarnings(as.numeric(x))
  S <- LA_RCCB_STATED
  if (nrow(awards) != S$named_awards + 1L) {
    stop("[LA] the award file has ", nrow(awards), " rows; it should be five ",
         "named awards and ONE unnamed aggregate. A new row means LDH named ",
         "more of the 48 -- re-read the source, and move those awards out of ",
         "the aggregate rather than adding beside it.", call. = FALSE)
  }
  if (sum(num(awards$amount), na.rm = TRUE) != S$named_total) {
    stop("[LA] sum(amount) is no longer the five named awards' $1,965,788.",
         call. = FALSE)
  }
  agg <- awards[awards$recipient_type == "NOT_YET_NAMED", ]
  if (nrow(agg) != 1L || !is.na(num(agg$amount)) ||
      num(agg$round_amount) != S$single_parish_total ||
      as.integer(agg$round_awards) != S$single_parish) {
    stop("[LA] the unnamed aggregate must be ONE row with an EMPTY amount and ",
         "$10,736,208 / 48 awards in round_amount / round_awards (§6.2).",
         call. = FALSE)
  }
  if (num(agg$round_amount) + sum(num(awards$amount), na.rm = TRUE) !=
      S$awarded) {
    stop("[LA] named amounts plus the aggregate's round_amount no longer ",
         "equal the round's $12,701,996.", call. = FALSE)
  }
  # SESSION 71: LDH still states no recipient's FORM. A Yes is admitted ONLY on
  # a row whose named awardee is the legal entity of a CMS-enrolled hospital,
  # typed by §10.2's enrolled-hospital-operator rule (R/03bj) and carrying the
  # CCN -- Ochsner Clinic Foundation, CCN 190036. Any other Yes still stops the
  # build, and the "20 hospital-setting awards" aggregate stays out of every
  # bucket (session 65).
  enrolled <- if ("cms_enrolment_match" %in% names(awards))
    !is.na(awards$cms_enrolment_match) & nzchar(awards$cms_enrolment_match)
  else rep(FALSE, nrow(awards))
  if (any(awards$distributed_to_hospital == "Yes" & !enrolled)) {
    stop("[LA] a Louisiana row is distributed_to_hospital = Yes. LDH names no ",
         "hospital; a Yes here would be a hospital row with no hospital ",
         "named on it.", call. = FALSE)
  }
  vocab_of <- c(recipient_type = "recipient_type",
                distributed_to_hospital = "distributed_to_hospital",
                flow_type = "flow_type",
                hospital_attribution = "hospital_attribution",
                hospital_benefiting = "hospital_benefiting",
                determination_confidence = "determination_confidence",
                validation_source_type = "source_doc_type",
                extraction_method = "extraction_method",
                recipient_confirmed = "recipient_confirmed",
                amount_confirmed = "amount_confirmed")
  for (col in names(vocab_of)) {
    bad <- setdiff(stats::na.omit(awards[[col]]), rhtp_vocabulary(vocab_of[[col]]))
    if (length(bad)) {
      stop("[LA] ", col, " carries values outside §8: ",
           paste(bad, collapse = ", "), call. = FALSE)
    }
  }
  fl <- unlist(strsplit(stats::na.omit(awards$flag_reason), ";"))
  bad <- setdiff(fl, rhtp_vocabulary("flag_reason"))
  if (length(bad)) {
    stop("[LA] flag_reason carries values outside §8: ",
         paste(bad, collapse = ", "), call. = FALSE)
  }
  if (any(!nzchar(awards$determination_basis))) {
    stop("[LA] every row needs a determination_basis (§7).", call. = FALSE)
  }
  invisible(TRUE)
}

#' The status table stays a STATUS table: no amount column
la_assert_status_has_no_amount <- function() {
  path <- here::here(LA_STATUS_CSV)
  if (file.exists(path)) {
    cols <- names(readr::read_csv(path, n_max = 0, show_col_types = FALSE))
    bad  <- intersect(cols, c("amount", "round_amount", "amount_announced"))
    if (length(bad)) {
      stop("[LA] la_year1_status.csv carries an amount column (",
           paste(bad, collapse = ", "), "). It is a STATUS table; the RCCB ",
           "money lives in la_year1_awardees.csv, and two files claiming one ",
           "figure is how a figure gets counted twice.", call. = FALSE)
    }
  }
  invisible(TRUE)
}


# -- build / report -----------------------------------------------------------

rhtp_la_build <- function() {
  rhtp_la_assert()
  la_assert_candidates_are_deck_activities()
  la_assert_capital_row_dropped()
  la_assert_rccb_rows_are_ldh_awards()

  status <- rhtp_la_year1_status()
  readr::write_csv(status, here::here(LA_STATUS_CSV), na = "")
  message("[LA] wrote ", nrow(status), " channels -> ", LA_STATUS_CSV)

  dispo <- rhtp_la_rcj_disposition()
  rhtp_assert_disposition_prose(dispo, "LA")
  readr::write_csv(dispo, here::here(LA_DISPO_CSV), na = "")
  message("[LA] wrote ", nrow(dispo), " disposition rows -> ", LA_DISPO_CSV)

  awards <- rhtp_la_year1_awardees()
  # SESSION 71: §10.2's enrolled-hospital-operator overlay, so a rebuild does
  # not wipe Ochsner Clinic Foundation's CMS typing (CCN 190036).
  s71 <- new.env()
  suppressMessages(source(here::here("R", "03bj_enrolled_hospital_operator.R"),
                          local = s71))
  awards <- s71$s71_overlay(awards, "la_year1_awardees.csv")
  la_assert_award_file(awards %>% dplyr::mutate(dplyr::across(
    dplyr::everything(), as.character)))
  readr::write_csv(awards, here::here(LA_AWARDS_CSV), na = "")
  message("[LA] wrote ", nrow(awards), " award rows -> ", LA_AWARDS_CSV)
  la_assert_award_file()

  la_assert_status_has_no_amount()
  invisible(list(status = status, disposition = dispo, awards = awards))
}

rhtp_la_report <- function() {
  cyc   <- la_deck_funding_cycle()
  cands <- la_deck_candidates()

  cat("\nLOUISIANA -- RHTP Year 1. ONE OF SEVEN AWARDED (RCCB); SIX STILL PENDING.\n")
  cat(strrep("-", 74), "\n")
  cat("  Allotment (§7.1)        $", format(la_allotment_anchor(), big.mark = ","),
      "\n", sep = "")
  cat("  Recipient-level roster   PARTIAL (session 64). LDH's September 3 deck\n")
  cat("                           reports 53 Rural Clinician Credit Bank awards,\n")
  cat("                           $12,701,996 as of 8/28/26, and NAMES FIVE\n")
  cat("                           ($1,965,788). la_year1_awardees.csv: 5 named\n")
  cat("                           rows + 1 aggregate (48 unnamed, $10,736,208).\n")
  cat("  Hospital settings        20 awards / $6,285,515 -- NONE NAMED, so no\n")
  cat("                           hospital bucket. Named hospital rows: 0.\n\n")

  cat("  LDH's own 'IMPORTANT DATES - BUDGET YEAR 1', and the deck's slide 18:\n\n")
  norm <- function(x) tolower(stringr::str_remove_all(x, "[^A-Za-z]"))
  dollars <- function(x) paste0("$", format(x, big.mark = ",",
                                            scientific = FALSE, trim = TRUE))
  held <- norm(cands$awardee_name_raw)

  cat(sprintf("    %-38s %5s %14s  %s\n",
              "ACTIVITY", "APPS", "PROJECTED BY1", "ANNOUNCEMENT"))
  for (i in seq_len(nrow(cyc))) {
    a <- norm(cyc$activity[i])
    carried <- any(purrr::map_lgl(held, ~ stringr::str_detect(a, stringr::fixed(.x)) ||
                                         stringr::str_detect(.x, stringr::fixed(a))))
    cat(sprintf("    %-38s %5d %14s  %s%s\n",
                substr(cyc$activity[i], 1, 38), cyc$applications[i],
                dollars(cyc$projected[i]), cyc$announcement[i],
                if (carried) "" else "   <- RCJ DROPS THIS"))
  }
  cat(sprintf("    %-38s %5d %14s\n", "TOTAL", sum(cyc$applications),
              dollars(sum(cyc$projected))))

  cat("\n  505 APPLICATIONS RECEIVED, NOT ONE AWARD NAMED (§0.3), and every\n")
  cat("  announcement window above closed before ", as.character(LA_ARCHIVE_DATE),
      ".\n", sep = "")
  cat("\n  §0.1: all SIX slide-18 RCJ candidates are rows of that table -- the ACTIVITY\n")
  cat("  column read as an awardee (§6.1 PROGRAM_NAME_AS_AWARDEE, six of six)\n")
  cat("  and the PROJECTED column read as an amount. They sum to $",
      format(sum(cands$amount_announced, na.rm = TRUE), big.mark = ",",
             scientific = FALSE, trim = TRUE),
      ",\n  understating the deck's own seven rows by $41,600,000.\n", sep = "")
  invisible(TRUE)
}


# -- the live probe -----------------------------------------------------------

#' Missouri's `--probe` shape (session 29): fetch, compare, report, and run the
#' award tripwires against the LIVE bytes rather than the archive.
#'
#' IT COMPARES A CONTENT DIGEST, NEVER A FILE DIGEST. ldh.la.gov runs
#' Cloudflare Email Address Obfuscation, which XOR-encodes a mailto with a
#' random one-byte key on every render into an href and a `data-cfemail`
#' attribute: three fetches, three distinct file digests, EXACTLY 169,500 bytes
#' every time. Constant-length like California's antispambot() re-roll, so a
#' byte-count check passes it; attribute-borne like Connecticut's `?v=` stamp,
#' so the tag-stripping reduction absorbs it for free.
LA_PROBE_KEYS <- c("programme", "funding", "council")

la_content_digest <- function(body, key) {
  if (key == "council") {
    tmp <- tempfile(fileext = ".pdf"); writeBin(body, tmp)
    if (!exists("rhtp_pdf_text")) source(here::here("R", "utils_pdf_text.R"))
    txt <- stringr::str_squish(paste(rhtp_pdf_text(tmp), collapse = " "))
  } else {
    txt <- la_reduce_html(body)
  }
  digest::digest(txt, algo = "sha256")
}

#' The name tripwire reads the PAGE BODY, not LDH's mega-menu (session 54)
#'
#' Every ldh.la.gov page opens with a ~12,000-character navigation menu (For
#' Businesses, For Providers, Health Info & Services, Offices &
#' Administration ...) that LDH edits on its own schedule. On 2026-09-23 the
#' probe halted on two "new organisations" that were an Office of Public
#' Health programme list inside that menu. The body starts where the page
#' prints its own title twice ("Rural Health Transformation Program Rural
#' Health Transformation Program", "RHTP Funding Opportunities RHTP Funding
#' Opportunities") and ends at the footer's "Surgeon General" signature.
LA_NAME_SCOPE <- list(
  programme = c(from = "Rural Health Transformation Program Rural Health Transformation Program The Louisiana",
                to = "Surgeon General Evelyn Griffin"),
  funding   = c(from = "RHTP Funding Opportunities RHTP Funding Opportunities Initiative 1",
                to = "Surgeon General Evelyn Griffin"))

la_name_scope <- function(text, page) {
  a <- LA_NAME_SCOPE[[page]]
  rhtp_name_scope(stringr::str_squish(text), from = a[["from"]], to = a[["to"]],
                  state = "LA", page = page)
}

la_probe <- function(keys = LA_PROBE_KEYS) {
  message("[LA] LIVE probe, ", format(Sys.time(), tz = "UTC"), " UTC")
  live <- list()
  changed <- character(0)
  for (key in keys) {
    body <- la_get(la_source(key, "url"), key)
    p    <- la_path(key)
    was  <- if (file.exists(p)) {
      la_content_digest(readBin(p, "raw", file.size(p)), key)
    } else NA_character_
    now  <- la_content_digest(body, key)
    live[[key]] <- body
    if (!is.na(was) && was != now) changed <- c(changed, key)
    message(sprintf("  %-10s %s  %s", key,
                    if (is.na(was)) "NEW      " else if (was == now) "UNCHANGED" else "CHANGED  ",
                    substr(now, 1, 16)))
    if (key != tail(keys, 1)) Sys.sleep(LA_HOST_THROTTLE_S)
  }

  prog <- if ("programme" %in% keys) la_reduce_html(live$programme) else NULL
  fund <- if ("funding" %in% keys) la_reduce_html(live$funding) else NULL
  deck <- if ("council" %in% keys) {
    tmp <- tempfile(fileext = ".pdf"); writeBin(live$council, tmp)
    if (!exists("rhtp_pdf_text")) source(here::here("R", "utils_pdf_text.R"))
    stringr::str_squish(paste(rhtp_pdf_text(tmp), collapse = " "))
  } else NULL

  la_assert_no_award_roster(programme = prog, funding = fund, council = deck)
  la_assert_windows_published(programme = prog, funding = fund)
  la_assert_deck_is_projected_not_awarded(council = deck)

  # THE NAME TRIPWIRE (§2.3, session 48). The phrase assertions above ask HOW
  # this page is worded; this asks WHOM it names, against the committed
  # archive. New Mexico is why it exists: HCA named six Regional Hubs and not
  # one of its ten award phrases matched. Subject pages only -- a control
  # moves for reasons that are not this state awarding.
  # SCOPED TO THE PAGE BODY (session 54), Delaware's and California's fix.
  # On 2026-09-23 this halted on LDH's site-wide navigation mega-menu -- an
  # Office of Public Health programme list ("Bureau of Sanitarian Services
  # Beach Monitoring Program ... Center for Vital Records") that LDH
  # reshuffled without naming anybody. A known list cannot keep up with a
  # menu, so both copies are read from the page's own doubled heading to the
  # footer's "Surgeon General" signature.
  la_live <- list(programme = prog, funding = fund)
  la_live <- la_live[!vapply(la_live, is.null, logical(1))]
  if (length(la_live)) {
    rhtp_assert_no_new_organisations_across(
      live = stats::setNames(
        purrr::map(names(la_live), function(k) la_name_scope(la_live[[k]], k)),
        names(la_live)),
      archived = stats::setNames(
        purrr::map(names(la_live), function(k) la_name_scope(la_html_text(k), k)),
        names(la_live)),
      state = "LA")
  }

  message("[LA] the award tripwires pass against the LIVE bytes: no watched ",
          "page carries a roster beyond the RCCB deck's five named awards.")
  # WHICH PAGES MOVED, not merely that the tripwires passed. This returned
  # `invisible(TRUE)` until session 46, and `rhtp_probe_log()` cannot tell a
  # success sentinel from a changed flag -- so the watch log recorded Louisiana
  # as CHANGED on a run where nothing had. Its siblings (Maine, California,
  # Connecticut, New Mexico) all return the changed KEYS; this now does too.
  invisible(list(changed = changed))
}


# -- CLI ----------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args)    la_fetch(force = "--force" %in% args)
  if ("--probe" %in% args)    rhtp_probe_run("LA", la_probe())
  if ("--validate" %in% args) {
    rhtp_la_assert()
    la_assert_candidates_are_deck_activities()
    la_assert_capital_row_dropped()
    la_assert_rccb_rows_are_ldh_awards()
    la_assert_award_file()
    message("[LA] all assertions pass.")
  }
  if ("--build" %in% args)    rhtp_la_build()
  if ("--report" %in% args)   rhtp_la_report()
  if (!length(intersect(args, c("--probe", "--fetch", "--validate", "--build",
                                "--report")))) {
    message("Usage: Rscript R/03ae_la_year1_probe.R ",
            "[--probe] [--fetch [--force]] [--validate] [--build] [--report]")
  }
}
