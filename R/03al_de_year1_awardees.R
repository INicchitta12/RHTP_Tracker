#!/usr/bin/env Rscript
# 03al_de_year1_awardees.R ---------------------------------------------------
#
# DELAWARE -- FOUR AWARD ACTIONS, THREE ORGANISATIONS, NO PER-RECIPIENT
# AMOUNT, AND §0.3a's OWN WORKED EXAMPLE ARRIVING AS REAL DATA.
#
# DHSS announced on 2026-07-29:
#
#   "The Delaware Department of Health and Social Services (DHSS) today
#    announced AWARDS to establish four new school-based health centers in
#    Sussex County through the state's Rural Health Transformation Program
#    (RHTP). ... The awards include:
#      Nemours Children's Health - Seaford Middle School
#      TidalHealth - Selbyville Middle School
#      Beebe Healthcare - Sussex Central Middle School
#      Beebe Healthcare - Georgetown Middle School"
#
# FOUR AWARD ACTIONS, THREE DISTINCT ORGANISATIONS (Beebe holds two), AND NOT
# ONE DOLLAR FIGURE AGAINST ANY OF THEM. Nevada's, Iowa's and North Carolina's
# shape at the smallest scale this project has met -- so `amount` is EMPTY on
# all four rows and Delaware's named-hospital contribution is FOUR ROWS AND $0.
# READ THE ROW COUNT.
#
# ============================================================================
# THIS IS THE SPEC'S §0.3a WORKED EXAMPLE, AND THE CLASSIFIER STILL FAILS IT
# ============================================================================
#
# §0.3a exists because all eleven hand-verified Delaware records were coded
# `hospital = no`, four of them awards to Beebe Healthcare, TidalHealth and
# Nemours Children's Health. §10.2's `NON_HOSPITAL` row was rewritten (commit
# 9fdc156, reverted by 219d803, re-applied in session 7) so that it judges the
# RECIPIENT and not the activity: "Delaware's school-based health center
# awarded to Beebe Healthcare is DIRECT". Until now that row had no live data
# behind it. It does now, and these are the same three organisations.
#
# AND THE SHARED CLASSIFIER REPRODUCES THE DEFECT. Measured, not assumed --
# `rhtp_classify_recipient_type()` on each name as the state publishes it:
#
#   "Beebe Healthcare"           -> NONPROFIT_CBO  LOW   (§8's fallback)
#   "Nemours Children's Health"  -> NONPROFIT_CBO  LOW   (§8's fallback)
#   "TidalHealth"                -> NONPROFIT_CBO  LOW   (§8's fallback)
#   "Beebe Medical Center"       -> HOSPITAL_OR_SYSTEM  HIGH
#
# NOT ONE of the three carries a token §8's name rule recognises, so left to
# the machine Delaware's four rows are `distributed_to_hospital = No` and the
# state contributes ZERO named-hospital rows -- §0.3a's defect, reproduced by
# code, thirty-seven sessions after it was found by hand. The fourth line is
# the same organisation under the spelling `DE Verify.xlsx` row 8 uses, and it
# classifies the OTHER WAY: North Carolina's two spellings of UNC for the third
# time, and here it decides whether the state has any hospital rows at all.
#
# THE OVERRIDE IS THE SPEC'S, NOT THIS SESSION'S, AND THAT IS THE WHOLE POINT.
# §0.4 forbids promoting a recipient on this pipeline's own knowledge, and
# nothing here does: §0.3a names all three organisations as "hospitals and
# health systems" and states the coding outright -- `HOSPITAL_OR_SYSTEM`,
# `DIRECT`, `distributed_to_hospital = Yes` -- and the reviewer instructions'
# worked-example table codes all three `Yes`. Those are governing documents of
# this project, committed and under version control, written ABOUT THESE EXACT
# RECIPIENTS. The classifier's own answer is preserved on every row in
# `recipient_type_source`, Indiana's convention, so the override is auditable
# and reversible.
#
# `determination_confidence` is MEDIUM and not HIGH, because §7 reserves HIGH
# for a CCN match and blocker 5 is still open.
#
# THE AWARDEE FIELD IS NOT ONLY THE AWARDEE, WHICH IS §0.3a's COROLLARY.
# Delaware packs the recipient and the SITE into one string -- "Beebe
# Healthcare - Georgetown Middle School" -- so the recipient column itself
# reads as a school. `awardee` carries the recipient half; `award_site` carries
# the school; `awardee_as_published` keeps the state's whole string (Arkansas's
# convention of keeping both spellings). A reader who takes the published
# string as the awardee gets a middle school.
#
# ============================================================================
# WHAT IS DELIBERATELY NOT IN THIS FILE
# ============================================================================
#
# THE $195,000 IS A BUDGET LINE, NOT AN ANNOUNCED ROUND, SO `round_amount` IS
# NA. DHSS's programme page prices all fifteen initiatives and gives
# "School-Based Health Centers ... Year 1 Budget: $195,000.00". That is Tier 2
# PLANNING money from the state's own budget narrative, not a round total an
# award announcement published -- Nevada's and North Carolina's `round_amount`
# both came from award announcements, and the release here publishes no round
# figure at all. §0.3 says a plan is not an award, so the figure lives in
# `de_year1_status.csv` labelled as a budget and NEVER in the award file.
# Dividing it four ways would give $48,750 a recipient, which no publisher
# has stated and which this file must make impossible rather than merely
# avoid.
#
# AND THE ONLY CURRENCY FIGURE ON THE RELEASE IS THE ALLOTMENT. "$157,394,963.86
# with 100 percent funded by CMS/HHS" against the §7.1 anchor's $157,394,964 --
# Tier 1 wearing the weak "This project" grammar (session 37's Iowa rule), so
# it is declared STATE_ALLOTMENT and checked. Filling an empty amount column
# with the only number on the page publishes the whole state award as four
# school-based health centres; North Carolina's ROOTS rows exist for the same
# reason.
#
# ONE CLOSURE, UNARRANGED. The fifteen Year 1 budgets on the live programme
# page match the fifteen parsed out of Delaware's budget-narrative PDF in
# session 8 (`data/interim/initiatives.csv`) TO THE CENT, all fifteen, summing
# to $141,655,467.48 both ways -- a document read in February and a page read
# in September agreeing with nobody arranging it.
#
# THE CHANNEL CONTROL IS UNUSUALLY DIRECT: Delaware publishes priced award
# announcements on this exact feed -- "$5 Million in State Arts Grants Heads to
# All Three Delaware Counties", posted the SAME DAY as this release -- so the
# absence of a figure here is Delaware's silence about these awards and not a
# property of the channel.
#
# Usage:
#   Rscript R/03al_de_year1_awardees.R --fetch [--force]
#   Rscript R/03al_de_year1_awardees.R --validate
#   Rscript R/03al_de_year1_awardees.R --build
#   Rscript R/03al_de_year1_awardees.R --probe
#   Rscript R/03al_de_year1_awardees.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
  library(purrr); library(httr); library(digest); library(here); library(rlang)
  library(openxlsx)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

DE_STATE     <- "DE"
DE_ALLOTMENT <- 157394964          # cms_fy2026_allotments.csv (§7.1)
DE_FOOTER    <- 157394963.86       # the release's CMS footer -- Tier 1
DE_SBHC_YEAR1_BUDGET <- 195000     # DHSS programme page, a BUDGET not a round
DE_ANNOUNCED <- as.Date("2026-07-29")
DE_NOA_DATE  <- as.Date("2025-12-29")

DE_EVIDENCE_DIR <- here::here("data", "evidence", "DE")
DE_CSV          <- here::here("data", "reference", "de_year1_awardees.csv")
DE_STATUS_CSV   <- here::here("data", "reference", "de_year1_status.csv")
DE_DISPO_CSV    <- here::here("data", "reference",
                              "de_rcj_candidate_disposition.csv")
DE_XLSX         <- here::here("DE_year1_awardees.xlsx")

DE_USER_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                        "+https://www.aha.org)")

DE_RELEASE_URL <- paste0(
  "https://news.delaware.gov/2026/07/29/governor-meyer-announces-funding-to-",
  "establish-four-new-school-based-health-centers-in-sussex-county/")

DE_SOURCES <- tibble::tribble(
  ~key, ~url, ~file, ~note,
  "release", DE_RELEASE_URL,
  "2026-09-03_de_sbhc_award_release.html",
  paste("THE AWARD SOURCE. DHSS 'today announced awards to establish four new",
        "school-based health centers ... through the state's Rural Health",
        "Transformation Program (RHTP)', naming four and pricing none."),
  "programme",
  "https://dhss.delaware.gov/dph/rural-health-transformation-program/",
  "2026-09-03_de_dhss_rhtp_programme.html",
  paste("DHSS's RHTP page: all FIFTEEN initiatives with Year 1 budgets",
        "(School-Based Health Centers $195,000), and Delaware's own",
        "definition of awarded -- 'once the budget is approved by CMS and a",
        "signed agreement is in place'."),
  "feb_rfps",
  paste0("https://news.delaware.gov/2026/02/09/state-of-delaware-opens-",
         "initial-rfps-to-transform-rural-health-care/"),
  "2026-09-03_de_initial_rfps_release.html",
  paste("The 2026-02-09 release opening the initial RFPs. The same channel at",
        "the SOLICITATION stage, which is what makes the July release's word",
        "'awards' load-bearing.")
)

de_source <- function(key, field) {
  row <- DE_SOURCES[DE_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[DE] unknown source key: ", key, call. = FALSE)
  row[[field]]
}

de_path <- function(key) file.path(DE_EVIDENCE_DIR, de_source(key, "file"))


# -- retrieval ---------------------------------------------------------------

de_get <- function(url, label) {
  resp <- httr::GET(url, httr::user_agent(DE_USER_AGENT),
                    httr::config(followlocation = TRUE), httr::timeout(120))
  if (httr::status_code(resp) != 200L) {
    stop("[DE] ", label, ": HTTP ", httr::status_code(resp), " from ", url,
         call. = FALSE)
  }
  httr::content(resp, as = "raw")
}

de_assert_no_credentials <- function(raw, label) {
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "bytes"
  bad <- c("[ps]k\\.ey[A-Za-z0-9._-]{10,}", "AIza[0-9A-Za-z_-]{30,}")
  for (p in bad) {
    if (grepl(p, txt, useBytes = TRUE, perl = TRUE)) {
      stop("[DE] ", label, " carries a credential-shaped string (", p,
           "); it was NOT written.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

de_fetch <- function(force = FALSE) {
  dir.create(DE_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  entries <- purrr::map_dfr(seq_len(nrow(DE_SOURCES)), function(i) {
    src <- DE_SOURCES[i, ]
    dest <- file.path(DE_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[DE] have ", src$file)
    } else {
      raw <- de_get(src$url, src$key)
      de_assert_no_credentials(raw, src$key)
      writeBin(raw, dest)
      message("[DE] wrote ", src$file, " (", length(raw), " bytes)")
      Sys.sleep(2)
    }
    tibble::tibble(file = src$file, bytes = file.size(dest),
                   sha256 = digest::digest(file = dest, algo = "sha256"))
  })
  de_write_manifest(entries)
  invisible(entries)
}

de_write_manifest <- function(entries) {
  path <- file.path(DE_EVIDENCE_DIR, "MANIFEST.txt")
  entries <- entries[entries$file != "MANIFEST.txt", ]
  writeLines(c(
    "DELAWARE -- RHTP evidence archive",
    "",
    "Fetched 2026-09-03 by R/03al_de_year1_awardees.R --fetch.",
    "Bodies are written with writeBin(), so re-hashing a file on disk",
    "reproduces its digest below.",
    "",
    "THE RELEASE PAGE CARRIES A ROLLING NEWS FEED in its sidebar, so its file",
    "digest moves whenever Delaware publishes anything at all, about any",
    "subject. That is not a token mechanism and it is not noise to be",
    "stripped -- the feed is real content -- so --probe compares a CONTENT",
    "digest of the ARTICLE region rather than of the page.",
    "",
    "file  bytes  sha256",
    paste(entries$file, entries$bytes, entries$sha256, sep = "  ")
  ), path)
  invisible(path)
}


# -- reduction ---------------------------------------------------------------

de_reduce_html <- function(raw) {
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "UTF-8"
  txt <- stringr::str_remove_all(
    txt, stringr::regex("<(script|style|noscript)[^>]*>.*?</\\1>",
                        dotall = TRUE, ignore_case = TRUE))
  txt <- stringr::str_replace_all(txt, "<[^>]+>", " ")
  txt <- stringr::str_replace_all(txt, "&nbsp;|&#160;", " ")
  txt <- stringr::str_replace_all(txt, "&amp;|&#038;", "&")
  txt <- stringr::str_replace_all(txt, "&#8217;|&#39;|&rsquo;|&#8216;", "'")
  txt <- stringr::str_replace_all(txt, "&#8220;|&#8221;|&quot;", "\"")
  txt <- stringr::str_replace_all(txt, "&#8211;|&ndash;|&#8212;|&mdash;", "-")
  txt <- stringr::str_replace_all(txt, "[\u2010-\u2015\u2212]", "-")
  txt <- stringr::str_replace_all(txt, "[ \t\u00a0]+", " ")
  txt <- stringr::str_replace_all(txt, "\\s*\n\\s*", "\n")
  stringr::str_trim(txt)
}

de_html_text <- function(key, body = NULL) {
  raw <- if (is.null(body)) readBin(de_path(key), "raw",
                                    file.size(de_path(key))) else body
  de_reduce_html(raw)
}

#' The ARTICLE, not the page
#'
#' news.delaware.gov renders a rolling site-wide news feed into every release
#' page's sidebar, so the page digest moves whenever Delaware publishes
#' anything about anything. The article itself starts at the "NEW CASTLE -"
#' dateline and ends at the CMS footer; that region is what --probe watches.
de_article_text <- function(body = NULL) {
  txt <- de_html_text("release", body)
  from <- stringr::str_locate(txt, stringr::fixed("NEW CASTLE"))
  to <- stringr::str_locate(txt, stringr::fixed("nor an endorsement, by CMS/HHS"))
  if (any(is.na(from)) || any(is.na(to))) {
    stop("[DE] the release no longer has both its dateline and its CMS ",
         "footer, so the article region cannot be isolated. Read the page.",
         call. = FALSE)
  }
  stringr::str_trim(substr(txt, from[1, "start"], to[1, "end"]))
}

de_content_digest <- function(key, body = NULL) {
  txt <- if (key == "release") de_article_text(body) else de_html_text(key, body)
  digest::digest(txt, algo = "sha256")
}

de_have_archive <- function() {
  all(file.exists(file.path(DE_EVIDENCE_DIR, DE_SOURCES$file)))
}


# -- the four awards ---------------------------------------------------------
#
# IN THE ORDER DELAWARE PRINTS THEM. §8 keeps the source's language and its
# ordering; DE Verify.xlsx lists the same four in a different order and the
# release is the primary source.

DE_AWARDS <- tibble::tribble(
  ~row_no, ~awardee, ~award_site, ~awardee_as_published,
  1L, "Nemours Children's Health", "Seaford Middle School",
  "Nemours Children's Health - Seaford Middle School",
  2L, "TidalHealth", "Selbyville Middle School",
  "TidalHealth - Selbyville Middle School",
  3L, "Beebe Healthcare", "Sussex Central Middle School",
  "Beebe Healthcare - Sussex Central Middle School",
  4L, "Beebe Healthcare", "Georgetown Middle School",
  "Beebe Healthcare - Georgetown Middle School"
)


# -- assertions --------------------------------------------------------------

#' The release names exactly these four awards and calls them awards
de_assert_four_awards <- function(body = NULL) {
  txt <- stringr::str_replace_all(de_article_text(body), "\\s+", " ")
  if (!stringr::str_detect(
        txt, stringr::fixed("announced awards to establish four new school-based"))) {
    stop("[DE] the release no longer says DHSS 'announced awards'. That verb ",
         "is what makes these rows awards rather than a plan (§0.3). Read it.",
         call. = FALSE)
  }
  missing <- DE_AWARDS$awardee_as_published[
    !vapply(DE_AWARDS$awardee_as_published,
            function(w) stringr::str_detect(txt, stringr::fixed(w)),
            logical(1))]
  if (length(missing)) {
    stop("[DE] the release no longer names: ",
         paste(sQuote(missing), collapse = "; "), ".", call. = FALSE)
  }
  # AND IT NAMES NO FIFTH. Measured rather than guessed: "Middle School"
  # (capitalised, i.e. as part of a school's NAME) occurs exactly FOUR times
  # in the article, once per award line. The prose mentions nearby are
  # lower-case -- "only one middle school and one elementary school ... had a
  # school-based health center" -- so they do not count and the tripwire does
  # not fire on them. A fifth award adds a fifth.
  n_sites <- stringr::str_count(txt, "Middle School")
  if (n_sites != 4L) {
    stop("[DE] 'Middle School' now occurs ", n_sites,
         " times in the article where it occurred FOUR times, once per award. ",
         "Delaware may have added an award, or renamed a site. Read the ",
         "release before rebuilding -- DE_AWARDS is a hand-read list of four ",
         "and nothing else updates it.", call. = FALSE)
  }
  invisible(TRUE)
}

#' Delaware prices NOBODY, and the only currency on the page is the ALLOTMENT
#'
#' DESIGNED TO FAIL the day a per-recipient figure appears. `amount` is empty
#' on all four rows and that is only honest while this holds; if DHSS prices
#' these awards, this file must be REWRITTEN rather than patched.
de_assert_no_per_recipient_amount <- function(body = NULL) {
  txt <- de_article_text(body)
  money <- stringr::str_extract_all(txt, "\\$\\s?[0-9][0-9,]*(\\.[0-9]+)?")[[1]]
  money <- stringr::str_remove_all(money, "[\\$ ]")
  vals <- as.numeric(stringr::str_remove_all(money, ","))
  if (length(vals) != 1L) {
    stop("[DE] the release now carries ", length(vals), " currency figures (",
         paste(money, collapse = ", "), ") where it carried exactly ONE -- ",
         "the allotment. If Delaware has priced these awards, ",
         "de_year1_awardees.csv must be REWRITTEN: its empty amount column ",
         "is a finding, and it stops being true the moment a figure exists.",
         call. = FALSE)
  }
  if (abs(vals - DE_FOOTER) > 0.005) {
    stop("[DE] the release's one currency figure is now ", money,
         " and not the CMS footer's ", DE_FOOTER, ".", call. = FALSE)
  }
  invisible(TRUE)
}

#' §0.2: that one figure is Tier 1, and the tier rule is driven both ways
de_assert_footer_is_the_allotment <- function(body = NULL) {
  txt <- de_article_text(body)
  ok <- rhtp_assert_footer_text_tier(
    txt, DE_STATE, "STATE_ALLOTMENT",
    label = "DE release CMS footer")
  if (!isTRUE(ok)) {
    message("[DE] the §0.2 tier check did not run -- see above. That is a gap ",
            "in the anchor, not a pass (§0.4).")
    return(invisible(NA))
  }
  refused <- tryCatch({
    rhtp_assert_footer_not_allotment(
      DE_FOOTER, DE_STATE, "SOLICITATION",
      label = "DE footer read as the school-based health centre pool")
    FALSE
  }, error = function(e) TRUE)
  if (!refused) {
    stop("[DE] the §0.2 rule no longer refuses Delaware's allotment being ",
         "read as a pool. That refusal is what stops $157.4M being published ",
         "as four school-based health centres.", call. = FALSE)
  }
  # The genuine pool is not caught, so the margin still discriminates.
  if (!isTRUE(rhtp_assert_footer_not_allotment(
        DE_SBHC_YEAR1_BUDGET, DE_STATE, "SOLICITATION",
        label = "DE School-Based Health Centers Year 1 budget"))) {
    stop("[DE] the §0.2 rule now refuses Delaware's own $195,000 initiative ",
         "budget, which would make it useless.", call. = FALSE)
  }
  invisible(TRUE)
}

#' §0.3a: the classifier still returns §8's FALLBACK for all three recipients
#'
#' THE LIVE EXPOSURE, ASSERTED RATHER THAN REPAIRED. If someone later widens
#' §8's name rule to reach "Healthcare"/"Health", this fails and they must
#' come and read what that widening costs elsewhere -- the repo has refused a
#' bare `Health` token deliberately since session 12, because it would sweep
#' up AltaPointe Health Systems and CarePath Behavioral Health.
de_assert_classifier_needs_the_override <- function() {
  got <- vapply(unique(DE_AWARDS$awardee), function(n) {
    rhtp_classify_recipient_type(n, DE_STATE)$recipient_type
  }, character(1))
  fallback <- got == "NONPROFIT_CBO"
  if (!all(fallback)) {
    stop("[DE] §8's name rule now types ",
         paste(names(got)[!fallback], collapse = ", "),
         " without the override. That is a change to the shared classifier: ",
         "re-read what it does to every other state before accepting it ",
         "(a bare 'Health' token was refused in session 12 on purpose).",
         call. = FALSE)
  }
  # And the OTHER spelling of the same organisation still classifies the other
  # way, which is what makes this a spelling problem rather than a gap.
  other <- rhtp_classify_recipient_type("Beebe Medical Center",
                                        DE_STATE)$recipient_type
  if (other != "HOSPITAL_OR_SYSTEM") {
    stop("[DE] 'Beebe Medical Center' no longer classifies HOSPITAL_OR_SYSTEM, ",
         "so the two-spellings finding no longer holds.", call. = FALSE)
  }
  invisible(got)
}

#' The $195,000 is a BUDGET on the programme page, and is not in the award file
de_assert_pool_is_a_budget_not_a_round <- function(body = NULL) {
  txt <- stringr::str_replace_all(de_html_text("programme", body), "\\s+", " ")
  want <- paste("School-Based Health Centers Funds will be competitively",
                "awarded to support operation of new school-based health",
                "centers. Year 1 Budget: $195,000.00")
  if (!stringr::str_detect(txt, stringr::fixed(want))) {
    stop("[DE] the programme page no longer carries the School-Based Health ",
         "Centers Year 1 budget in the form this file records. Re-read it.",
         call. = FALSE)
  }
  # Delaware's own definition of awarded, which is why these rows are
  # amount_confirmed = No.
  if (!stringr::str_detect(
        txt, stringr::fixed("once the budget is approved by Centers for"))) {
    stop("[DE] the programme page no longer states Delaware's own definition ",
         "of 'awarded'. That sentence is what amount_confirmed = No rests on.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Delaware publishes priced awards on this very channel
#'
#' THE CONTROL THAT MAKES THE MISSING AMOUNTS MEAN SOMETHING. Without it, "no
#' figure published" is indistinguishable from "this feed does not carry
#' figures".
de_assert_channel_control <- function(body = NULL) {
  txt <- de_html_text("release", body)
  lines <- stringr::str_split(txt, "\n")[[1]]
  priced <- lines[stringr::str_detect(lines, "\\$[0-9]") &
                  stringr::str_detect(
                    lines, stringr::regex("grant|award|fund",
                                          ignore_case = TRUE))]
  if (!length(priced)) {
    stop("[DE] the news feed on this page no longer carries a priced award ",
         "headline. The control that makes Delaware's silence about ITS OWN ",
         "four awards meaningful is gone; re-establish it.", call. = FALSE)
  }
  invisible(length(priced))
}

#' The award postdates the Notice of Award (§6.2's date test)
de_assert_after_noa <- function() {
  if (DE_ANNOUNCED <= DE_NOA_DATE) {
    stop("[DE] the award announcement no longer postdates the CMS Notice of ",
         "Award.", call. = FALSE)
  }
  invisible(as.integer(DE_ANNOUNCED - DE_NOA_DATE))
}

#' Four rows, three organisations, four named-hospital rows, ZERO dollars
#'
#' Nevada's guard: the row count is the only hospital quantity Delaware
#' supports, and a reader who quotes the $0 without it reports the opposite of
#' what Delaware published.
de_assert_row_count_is_the_finding <- function(awards = NULL) {
  d <- if (is.null(awards)) de_year1_awardees() else awards
  stopifnot(nrow(d) == 4L, length(unique(d$awardee)) == 3L)
  if (!all(is.na(d$amount))) {
    stop("[DE] a Delaware row now carries an amount. Delaware published none, ",
         "so either DHSS has priced these awards -- in which case this file ",
         "is REWRITTEN, not patched -- or a figure has been derived, which ",
         "§6.2 forbids ($195,000 / 4 = $48,750 is nobody's published ",
         "figure).", call. = FALSE)
  }
  part <- rhtp_hospital_dollar_partition(d)
  named <- part[part$bucket == "NAMED_HOSPITAL", ]
  if (nrow(named) != 1L || named$rows != 4L || named$dollars != 0) {
    stop("[DE] the partition no longer reports Delaware as 4 named-hospital ",
         "rows and $0. That pairing IS the finding.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- the award file ----------------------------------------------------------

de_year1_awardees <- function() {
  cls <- vapply(DE_AWARDS$awardee, function(n) {
    rhtp_classify_recipient_type(n, DE_STATE)$recipient_type
  }, character(1))

  basis <- paste(
    "§0.3a AND §10.2, ON THE WORKED EXAMPLE THEY WERE WRITTEN FOR. DHSS",
    "'announced awards to establish four new school-based health centers ...",
    "through the state's Rural Health Transformation Program (RHTP)' and",
    "printed this recipient in its own list of awards. The ACTIVITY is a",
    "school-based health centre and the RECIPIENT is a hospital system, and",
    "§10.2's NON_HOSPITAL row says in terms that this combination is DIRECT:",
    "'Nebraska's school kitchen modernization awarded to the Department of",
    "Education is NON_HOSPITAL; Delaware's school-based health center awarded",
    "to Beebe Healthcare is DIRECT.' §8's NAME RULE ALONE MISSES ALL THREE",
    "ORGANISATIONS -- rhtp_classify_recipient_type() returns NONPROFIT_CBO at",
    "LOW for each, and its answer is preserved in recipient_type_source -- so",
    "the type here is taken from the spec's own §0.3a, which names Beebe",
    "Healthcare, TidalHealth and Nemours Children's Health as 'all hospitals",
    "and health systems'. That is a committed governing document of this",
    "project written about these exact recipients, not this pipeline's",
    "private knowledge (§0.4). CONFIDENCE IS MEDIUM, NOT HIGH: §7 reserves",
    "HIGH for a CCN match and blocker 5 is open. AMOUNT IS EMPTY BECAUSE",
    "DELAWARE PUBLISHED NONE -- the release carries exactly one currency",
    "figure and it is the state allotment (§0.2).")

  DE_AWARDS %>%
    dplyr::mutate(
      state = DE_STATE,
      amount = NA_real_,
      recipient_type = "HOSPITAL_OR_SYSTEM",
      distributed_to_hospital = "Yes",
      note = paste0(
        "School-based health centre at ", .data$award_site,
        ", Sussex County. Announced 2026-07-29 by DHSS as one of four awards ",
        "under Delaware's RHTP. NO PER-RECIPIENT AMOUNT PUBLISHED -- read the ",
        "row count, not the dollar column."),
      recipient_confirmed = "Yes",
      amount_confirmed = "No",
      fiscal_year = "FY2026 (Year 1)",
      source_document_title = paste(
        "Governor Meyer Announces Funding to Establish Four New School-Based",
        "Health Centers in Sussex County"),
      state_source_url = DE_RELEASE_URL,
      validation_source_type = "AGENCY_PRESS_RELEASE",
      extraction_method = "DIRECT_TEXT",
      validator = "R/03al_de_year1_awardees.R",
      ccn = NA_character_,
      aha_id = NA_character_,
      rural_designation = "Sussex County (rural)",
      reviewer = NA_character_,
      recipient_type_source = paste0(
        "§8's shared classifier returns '", cls, "' at LOW for this name ",
        "(the standing fallback for a named entity whose form the source does ",
        "not state). OVERRIDDEN to HOSPITAL_OR_SYSTEM on spec §0.3a, which ",
        "names this organisation as a hospital or health system and states ",
        "the coding. The machine answer is kept here so the override is ",
        "auditable and reversible."),
      determination_confidence = "MEDIUM",
      flag_reason = "RECIPIENT_NAMES_NOT_CAPTURED_AMOUNT_NOT_PUBLISHED",
      award_pool = "School-Based Health Centers",
      budget_period = "Budget Period 1",
      flow_type = "DIRECT",
      hospital_benefiting = "Yes",
      hospital_attribution = "NAMED_HOSPITAL",
      intermediary_name = NA_character_,
      determination_basis = basis,
      amount_basis = paste(
        "NOT PUBLISHED. The release names four awards and prices none of",
        "them. The state's own School-Based Health Centers Year 1 budget of",
        "$195,000 is a BUDGET LINE on the programme page, not an announced",
        "round total, so it is not carried here even as round_amount (§0.3:",
        "a plan is not an award); it is in de_year1_status.csv. Dividing it",
        "four ways would give $48,750, which no publisher has stated."),
      round_amount = NA_real_,
      announcement_date = DE_ANNOUNCED,
      source_archive_path = file.path("data", "evidence", "DE",
                                      de_source("release", "file"))) %>%
    dplyr::select(
      dplyr::all_of(c(
        "state", "row_no", "awardee", "amount", "recipient_type",
        "distributed_to_hospital", "note", "recipient_confirmed",
        "amount_confirmed", "fiscal_year", "source_document_title",
        "state_source_url", "validation_source_type", "extraction_method",
        "validator", "ccn", "aha_id", "rural_designation", "reviewer")),
      dplyr::everything())
}


# -- the status table --------------------------------------------------------

de_status_table <- function() {
  tibble::tribble(
    ~state, ~channel, ~stage, ~publishes_roster, ~year1_budget, ~note,
    DE_STATE, "School-Based Health Centers", "AWARDED_ROSTER_PUBLISHED", "Yes",
    195000,
    paste("FOUR award actions to THREE organisations, announced 2026-07-29,",
          "with NO per-recipient amount. The Year 1 budget here is DHSS's",
          "own programme-page figure and is a BUDGET LINE, not a round total",
          "-- it is deliberately NOT in de_year1_awardees.csv (§0.3)."),
    DE_STATE, "Health Hubs", "NO_ROSTER_PUBLISHED", "No", 5483730,
    "Competitive. No recipient named.",
    DE_STATE, "Libraries", "NO_ROSTER_PUBLISHED", "No", 1835000,
    "Competitive, to rural libraries. No recipient named; NON_HOSPITAL class.",
    DE_STATE, "Hope Centers", "NO_ROSTER_PUBLISHED", "No", 26370000,
    "Two new Hope Centers for the rural homeless population. Nobody named.",
    DE_STATE, "Food Is Medicine infrastructure", "NO_ROSTER_PUBLISHED", "No",
    1648000,
    paste("A 2026-07-24 release says the pathway would be 'unveiled at the",
          "Delaware State Fair'. RCJ carries a multi-recipient field naming",
          "University of Delaware, Beebe Healthcare and Deloitte for it; no",
          "state award notice names them, so nothing is coded (§0.4)."),
    DE_STATE, "Continuous glucose monitoring", "NO_ROSTER_PUBLISHED", "No",
    950000,
    paste("The Rural Delaware Diabetes Wellness Pilot. DE Verify.xlsx rows 8",
          "and 9 name Beebe Medical Center and TidalHealth against it from a",
          "contract-status page; no state AWARD notice reachable here names",
          "them, so they are NOT in this file (§0.4). They are §0.3a's",
          "sharper half and blocker 2 owns them."),
    DE_STATE, "Telehealth and remote patient monitoring", "NO_ROSTER_PUBLISHED",
    "No", 5000000, "Vendors. Nobody named.",
    DE_STATE, "Delaware's first 4-year medical school", "NO_ROSTER_PUBLISHED",
    "No", 42500000,
    "The largest single line. Thomas Jefferson University is named in DE Verify.xlsx; no award notice reachable here.",
    DE_STATE, "Support non-physician clinicians", "NO_ROSTER_PUBLISHED", "No",
    1000000, "Tuition awards to individuals. Not organisation-level.",
    DE_STATE, "Support medical residents", "NO_ROSTER_PUBLISHED", "No", 1236495,
    "Awards to individual residents.",
    DE_STATE, "Support medical students", "NO_ROSTER_PUBLISHED", "No", 1100000,
    "Tuition awards to individuals.",
    DE_STATE, "Expand training programs", "NO_ROSTER_PUBLISHED", "No", 20910000,
    paste("§7A codes this Delaware's ONLY hospital-directed initiative and it",
          "has published no recipient."),
    DE_STATE, "Workforce data", "NO_ROSTER_PUBLISHED", "No", 2685200,
    "Vendor-managed. Delaware Health Force is named in DE Verify.xlsx only.",
    DE_STATE, "Value-based care transformation", "NO_ROSTER_PUBLISHED", "No",
    24322042.48,
    paste("DHSS's site says awarded and names NOBODY -- DE Verify.xlsx row 10",
          "records exactly that ('Not identified'). §0.3."),
    DE_STATE, "Real-time insurance verification and prior authorization",
    "NO_ROSTER_PUBLISHED", "No", 6420000,
    "Vendor operation. DHIN is named in DE Verify.xlsx only.",
    DE_STATE, "news.delaware.gov (channel control)",
    "PUBLISHES_PRICED_AWARDS_FOR_OTHER_PROGRAMMES", "Yes - FOR OTHER PROGRAMMES",
    NA_real_,
    paste("THE CONTROL. The same feed carried '$5 Million in State Arts",
          "Grants Heads to All Three Delaware Counties' on the SAME DAY as",
          "the RHTP release. Delaware publishes dollar figures when it has",
          "them, so the absence of one here is about these awards.")
  )
}

de_disposition <- function() {
  rt <- readRDS(here::here("data", "interim", "stage2_record_table.rds"))
  de <- rt %>% dplyr::filter(.data$state == DE_STATE)
  t3 <- de %>% dplyr::filter(.data$award_tier == "SUBAWARD")
  if (nrow(t3) != 6L) {
    stop("[DE] this disposition covers SIX Tier 3 candidates and the record ",
         "table now holds ", nrow(t3), ". Read the new ones before rebuilding.",
         call. = FALSE)
  }
  tibble::tribble(
    ~state, ~group, ~rcj_rows, ~disposition, ~evidence,
    DE_STATE, "School-based health centre awards", 4L,
    "REAL_AWARDS_CARRIED_AT_A_$1_PLACEHOLDER",
    paste0("RCJ carries all four, NAMED EXACTLY AS DELAWARE PRINTS THEM ",
           "(site and all), at an amount of $1 each. Missouri's and Maine's ",
           "placeholder mechanism: the aggregator is RIGHT about the ",
           "recipients and says nothing usable about the money, so no amount ",
           "check can see the defect -- EXCEPT THAT STAGE 2 ALREADY CAUGHT ",
           "IT: all four carry `flag_reason = AMOUNT_IMPLAUSIBLE_LOW` in the ",
           "committed record table, which is the $1 placeholder showing up ",
           "as a plausibility failure four sessions before anyone read the ",
           "release. These four ARE this file's rows, and the amounts come ",
           "from Delaware -- which published none."),
    DE_STATE, "Delaware State Housing Authority", 1L,
    "TIER_2_BUDGET_LINE",
    paste0("$11,500,000, sourced to 'DE - 2025 - Delaware RHTP Executive ",
           "Budget Summary'. A budget-narrative line item, not a subaward ",
           "(Oklahoma's and Connecticut's tier defect). DHSS's programme ",
           "page carries no housing initiative among its fifteen."),
    DE_STATE, "La Red Health Center, Inc.", 1L,
    "NOT_RHTP_FEDERAL_PROVENANCE_ALREADY_QUARANTINED",
    paste0("$250,000, sourced to 'FY 2025: HRSA's Rural Health Grants ",
           "Delaware Fact Sheet'. THE ORIGINAL §6.2 FINDING, from Stage 0: ",
           "a different FEDERAL programme's money on a HRSA document, which ",
           "is why the provenance filter exists at all. It is already ",
           "QUARANTINED in the record table with `PROVENANCE_MISMATCH`, ",
           "which is why the 50-state survey counts FIVE Delaware candidates ",
           "and the record table holds SIX -- the survey counts PASS and ",
           "FLAGGED rows only. This disposition covers all six.")
  )
}


# -- the live probe ----------------------------------------------------------

de_probe <- function() {
  keys <- c("release", "programme")
  live <- purrr::map(keys, function(k) {
    r <- de_get(de_source(k, "url"), k); Sys.sleep(2); r
  })
  names(live) <- keys

  cmp <- purrr::map_dfr(keys, function(k) {
    tibble::tibble(
      key = k,
      archived_content = de_content_digest(k),
      live_content = de_content_digest(k, live[[k]]),
      archived_file = digest::digest(file = de_path(k), algo = "sha256"),
      live_file = digest::digest(live[[k]], algo = "sha256",
                                 serialize = FALSE))
  }) %>%
    dplyr::mutate(content_changed = .data$archived_content != .data$live_content,
                  file_changed = .data$archived_file != .data$live_file)

  de_assert_four_awards(body = live$release)
  de_assert_no_per_recipient_amount(body = live$release)
  de_assert_pool_is_a_budget_not_a_round(body = live$programme)
  de_assert_channel_control(body = live$release)

  message("[DE] live probe ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " UTC")
  purrr::walk(seq_len(nrow(cmp)), function(i) {
    r <- cmp[i, ]
    message(sprintf("  %-10s content %s   file %s", r$key,
                    if (r$content_changed) "CHANGED" else "unchanged",
                    if (r$file_changed) "differs" else "unchanged"))
  })
  if (any(cmp$content_changed)) {
    message("[DE] CONTENT CHANGED on: ",
            paste(cmp$key[cmp$content_changed], collapse = ", "),
            ". Re-fetch and read -- an amount appearing rewrites this file.")
  } else {
    message("[DE] UNCHANGED. Four awards, three organisations, no amounts.")
  }
  invisible(cmp)
}


# -- validate / build / report -----------------------------------------------

de_validate <- function() {
  if (!de_have_archive()) {
    stop("[DE] the evidence archive is incomplete; run --fetch first.",
         call. = FALSE)
  }
  de_assert_four_awards()
  de_assert_no_per_recipient_amount()
  de_assert_footer_is_the_allotment()
  de_assert_classifier_needs_the_override()
  de_assert_pool_is_a_budget_not_a_round()
  de_assert_channel_control()
  de_assert_after_noa()
  de_assert_row_count_is_the_finding()
  message("[DE] all assertions pass.")
  invisible(TRUE)
}

de_build <- function() {
  d <- de_year1_awardees()
  de_assert_row_count_is_the_finding(d)
  readr::write_csv(d, DE_CSV)
  message("[DE] wrote ", DE_CSV, " (", nrow(d), " rows)")

  st <- de_status_table()
  readr::write_csv(st, DE_STATUS_CSV)
  message("[DE] wrote ", DE_STATUS_CSV, " (", nrow(st), " rows)")

  dp <- de_disposition()
  readr::write_csv(dp, DE_DISPO_CSV)
  message("[DE] wrote ", DE_DISPO_CSV, " (", nrow(dp), " rows)")

  de_write_workbook(d, st, dp)
  invisible(list(awards = d, status = st, disposition = dp))
}

de_write_workbook <- function(d, st, dp) {
  wb <- openxlsx::createWorkbook()
  hdr <- openxlsx::createStyle(textDecoration = "bold")
  wrap <- openxlsx::createStyle(wrapText = TRUE, valign = "top")

  add <- function(name, df, widths = "auto") {
    openxlsx::addWorksheet(wb, name)
    openxlsx::writeData(wb, name, df, headerStyle = hdr)
    openxlsx::freezePane(wb, name, firstActiveRow = 2)
    openxlsx::setColWidths(wb, name, cols = seq_along(df), widths = widths)
  }

  # SHEET 1 IS THE WARNING (South Dakota's, Nevada's and Illinois's device).
  warning_sheet <- tibble::tibble(
    READ_THIS_FIRST = c(
      "DELAWARE PUBLISHES NO PER-RECIPIENT AMOUNT. The `amount` column is EMPTY on all four rows and that is the finding, not a gap in this extraction.",
      "",
      "FOUR AWARD ACTIONS. THREE ORGANISATIONS. Beebe Healthcare holds two (Sussex Central and Georgetown Middle Schools). A row count is not an organisation count.",
      "",
      "DELAWARE CONTRIBUTES 4 NAMED-HOSPITAL ROWS AND $0. Both halves are true at once. A reader who quotes the $0 without the row count reports the opposite of what Delaware published.",
      "",
      "DO NOT USE THE $195,000. DHSS's programme page gives 'School-Based Health Centers ... Year 1 Budget: $195,000.00'. That is a BUDGET LINE in the state's plan, not an announced round total, and $195,000 / 4 = $48,750 is a figure no publisher has stated (§0.3, §6.2). It is on the Initiatives sheet, labelled, and deliberately not in the award file.",
      "",
      "DO NOT USE THE $157,394,963.86 EITHER. That is the only currency figure on the award release and it is Delaware's WHOLE CMS ALLOTMENT (§0.2), wearing the weak 'This project is supported by' grammar.",
      "",
      "WHY THESE ARE HOSPITALS. §8's name rule does NOT reach 'Beebe Healthcare', 'Nemours Children's Health' or 'TidalHealth' -- the shared classifier returns NONPROFIT_CBO at LOW for all three, which would make Delaware's hospital contribution zero. The type is taken from spec §0.3a, which names these three organisations and states the coding. The classifier's own answer is preserved on every row in `recipient_type_source`.",
      "",
      "THE AWARDEE IS NOT THE PUBLISHED STRING. Delaware prints 'Beebe Healthcare - Georgetown Middle School'. `awardee` is the recipient half, `award_site` the school, `awardee_as_published` the whole string."))
  add("READ THIS FIRST", warning_sheet, widths = 150)
  openxlsx::addStyle(wb, "READ THIS FIRST", wrap,
                     rows = 2:(nrow(warning_sheet) + 1), cols = 1,
                     gridExpand = TRUE)

  add("Awards", d)
  add("Initiatives", st)
  add("RCJ disposition", dp)

  openxlsx::saveWorkbook(wb, DE_XLSX, overwrite = TRUE)
  message("[DE] wrote ", DE_XLSX)
  invisible(DE_XLSX)
}

de_report <- function() {
  d <- de_year1_awardees()
  cat("\nDELAWARE -- four awards, three organisations, and no amounts\n")
  cat(strrep("=", 66), "\n\n")
  cat("Allotment (§7.1)       : $", format(DE_ALLOTMENT, big.mark = ","),
      "\n", sep = "")
  cat("Award actions          : ", nrow(d), "\n", sep = "")
  cat("Distinct organisations : ", length(unique(d$awardee)), "\n", sep = "")
  cat("sum(amount)            : $0 -- DELAWARE PRICES NOBODY\n")
  cat("Named-hospital rows    : ", sum(d$hospital_attribution ==
                                       "NAMED_HOSPITAL"),
      "   <- THE ONLY HOSPITAL QUANTITY DELAWARE SUPPORTS\n", sep = "")
  cat("\n")
  print(as.data.frame(d[, c("row_no", "awardee", "award_site",
                            "recipient_type", "distributed_to_hospital")]),
        row.names = FALSE)
  cat("\n§0.3a, MEASURED: §8's name rule returns NONPROFIT_CBO/LOW for all\n")
  cat("three organisations. Left to the classifier Delaware has NO hospital\n")
  cat("rows -- the spec's own defect, reproduced in code. The override is\n")
  cat("§0.3a's, and the machine's answer is kept on every row.\n")
  invisible(d)
}


if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) de_fetch(force = "--force" %in% args)
  if ("--validate" %in% args) de_validate()
  if ("--build" %in% args) de_build()
  if ("--probe" %in% args) de_probe()
  if ("--report" %in% args) de_report()
  if (!length(args)) {
    message("Usage: --fetch [--force] | --validate | --build | --probe | --report")
  }
}
