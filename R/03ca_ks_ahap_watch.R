# 03ca_ks_ahap_watch.R ---------------------------------------------------------
#
# KANSAS: THE ANCHOR HOSPITAL ADVANCEMENT PROGRAM (AHAP) WATCH (session 98).
#
# Session 96 read the Care Collaborative's AHAP page and extracted nothing
# (docs/session96_*.md §3). AHAP is RHTP-funded as Tier 2 plan lines (KDHE ->
# CCA -> AHAP, LLC, a joint venture of Kansas' urban not-for-profit health
# systems), it pays no hospital on any document read, and it names two of its
# ten anchor hospitals only as remote-monitoring pilot sites:
#   "Implementation planning continues at AHAP pilot sites Newman Regional
#    Health and Labette Health"
# The page says ten rural hospitals "have been designated as anchor hospitals
# eligible for support services and programs" and does not list them.
# Designation as eligible is §6.1 mode 3 and §0.3: it is not an award.
#
# WHAT THIS WATCH EXISTS TO CATCH, and the only two things that would make AHAP
# readable under §10.2:
#   (a) a published list of the ten designated anchor hospitals;
#   (b) any contract or announcement naming anchor hospitals for the rural
#       residency line ($2,138,590 in Table 11.F.5, $2,236,590 in the text;
#       "KUMC and anchor hospitals" are the narrative's contracted parties).
# Neither is an award by itself. (a) is a roster to READ; (b) is the one AHAP
# line that could become money to a hospital.
#
# THREE CHECKS, ALL AS DIFFS AGAINST THE COMMITTED ARCHIVE (§2.3):
#   1. the NAME tripwire on the page's content region. The two pilot sites are
#      `known` (containment), so they never trip; any other new name does.
#   2. two PHRASE tripwires, new sentences only: KSA_ROSTER_PATTERN for (a),
#      KSA_RESIDENCY_PATTERN for (b). They catch a roster announced in words a
#      name pattern cannot see ("Hays, Salina and Pratt are anchor sites").
#   3. the "AHAP Media Fact Deck" link. Its href is the relative string
#      "ruralhealthkansas.com/about", which resolves to nothing. A deck could
#      carry the roster, so ANY change to that href trips: if the page
#      republishes the deck, a human archives and reads it. Nothing here
#      "fixes" the link; the page has not republished it (live, 2026-10-12).
#
# THE CONTENT REGION IS `#main-content`, AND ITS ABSENCE REFUSES. The site's
# header menu is outside it and moves on its own: between 10-07 and 10-12 it
# gained "Ambient Listening Technology", which the whole-page reduction reads
# as a new organisation. Reading the menu would make this tripwire fire on the
# site's navigation (session 95's KDHE lesson). If the Divi theme drops
# `#main-content`, this stops rather than falling back to <body>.
#
# THIS FILE NEVER WRITES FROM A PROBE. R/03o's ks_probe() calls ksa_probe();
# re-basing is `Rscript R/03ca_ks_ahap_watch.R --fetch [--force]`, a human act
# after reading what moved (§2.2), followed by updating KSA_FILE.

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))

KSA_URL <- "https://ruralhealthkansas.com/anchor-hospital-advancement-program/"
KSA_DIR <- file.path("data", "evidence", "KS", "ahap")
KSA_FILE <- "2026-10-07_rhk_ahap_program_page.html"
KSA_USER_AGENT <- paste("RHTP-Tracker/0.1 (AHA Data & Policy research;",
                        "+https://www.aha.org)")
KSA_SCOPE <- "#main-content"

# The two anchor hospitals the page already names, as RPM pilot sites. Matched
# by containment, so "Newman Regional Health and Labette Health" (one run in the
# reduced text) and either name alone are both quiet. A site list, not awards.
KSA_KNOWN <- c("Newman Regional Health", "Labette Health")

# (a) a roster of the anchor hospitals, however it is announced.
KSA_ROSTER_PATTERN <- paste0(
  "\\banchor (hospital|site|location|facilit|member)[a-z]*\\b[^.]{0,120}",
  "\\b(are|include[sd]?|including|named|selected|designated|announced|",
  "list(ed)?|consist)\\b|",
  "\\b(are|include[sd]?|including|named|selected|designated|announced)\\b",
  "[^.]{0,40}\\bas (an? )?anchor (hospital|site)|",
  "\\blist of (the )?(10 |ten )?(rural |designated |AHAP )*anchor|",
  "\\b(10|ten) (designated |rural )*anchor (hospital|site)s? (are|include)")

# (b) the residency line contracted, awarded or sited at named hospitals.
KSA_RESIDENCY_PATTERN <- paste0(
  "residen(cy|cies|ts?)\\b[^.]{0,200}\\b(contract(ed|s)?|agreements?|",
  "award(ed|s)?|partner(s|ing|ship)?|affiliat[a-z]*|sponsor[a-z]*|",
  "host(ed|ing|s)?|sites?|hospitals?|accredit[a-z]*|fund(ed|ing)?)\\b|",
  "\\b(contract(ed|s)?|agreements?|award(ed|s)?|partner(s|ing|ship)?|",
  "sponsor[a-z]*|host(ed|ing|s)?)\\b[^.]{0,200}residen(cy|cies|ts?)\\b")

# The broken deck link as archived. Any other href, or its removal, is read.
KSA_DECK_TEXT <- "AHAP Media Fact Deck"
KSA_DECK_HREF <- "ruralhealthkansas.com/about"

ksa_path <- function(file = KSA_FILE) here::here(KSA_DIR, file)

ksa_archived_raw <- function() {
  p <- ksa_path()
  readBin(p, "raw", file.size(p))
}

#' The content region's reduced text. Refuses when the region is missing.
ksa_text <- function(raw, label = "live") {
  h <- xml2::read_html(raw)
  if (inherits(rvest::html_element(h, KSA_SCOPE), "xml_missing")) {
    stop("[KS] the AHAP page (", label, ") has no '", KSA_SCOPE, "' region. ",
         "The theme has moved; re-read the page and re-anchor the scope ",
         "rather than reading the site menu (§2.3).", call. = FALSE)
  }
  rhtp_watch_reduce(raw, scope = KSA_SCOPE)
}

#' The href(s) of the Media Fact Deck link. character(0) when it is gone.
ksa_deck_hrefs <- function(raw) {
  a <- xml2::xml_find_all(xml2::read_html(raw), "//a")
  txt <- stringr::str_squish(xml2::xml_text(a))
  unique(xml2::xml_attr(a, "href")[grepl(KSA_DECK_TEXT, txt, fixed = TRUE)])
}

ksa_assert_deck <- function(live_raw) {
  h <- ksa_deck_hrefs(live_raw)
  if (!identical(h, KSA_DECK_HREF)) {
    stop("[KS] 'ahap' THE \"", KSA_DECK_TEXT, "\" LINK HAS MOVED: href now ",
         if (length(h)) paste0("\"", rhtp_watch_quote(h), "\"", collapse = ", ")
         else "ABSENT",
         " (archived: the broken relative \"", KSA_DECK_HREF, "\"). If the ",
         "page has republished the deck, archive it and read it for the ten ",
         "anchor hospitals and the residency sites. THAT IS THE SIGNAL.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' All three AHAP checks, live against archive. Raises on any trip.
#'
#' @return a one-row tibble, key "ahap", content_changed.
ksa_check <- function(live_raw, arch_raw = ksa_archived_raw()) {
  live <- ksa_text(live_raw, "live")
  arch <- ksa_text(arch_raw, "archived")

  rhtp_assert_no_new_organisations(live, arch, state = "KS", page = "ahap",
                                   known = KSA_KNOWN)
  rhtp_watch_forbid_new(
    live, arch, KSA_ROSTER_PATTERN, "KS", "ahap",
    paste("AHAP may have listed its ten designated anchor hospitals. Read the",
          "page: a designation is not an award (§0.3, §6.1 mode 3), but the",
          "roster is what any later AHAP award will be read against."))
  rhtp_watch_forbid_new(
    live, arch, KSA_RESIDENCY_PATTERN, "KS", "ahap",
    paste("The rural residency line may be contracted to named anchor",
          "hospitals -- the one AHAP line that could be money to a hospital.",
          "Read it under §10.2 before coding anything."))
  ksa_assert_deck(live_raw)

  tibble::tibble(key = "ahap",
                 content_changed = digest::digest(live) != digest::digest(arch))
}

#' The probe half, called from R/03o's ks_probe(). Reads; never writes.
ksa_probe <- function() {
  ksa_check(rhtp_watch_fetch(KSA_URL, KSA_USER_AGENT))
}

#' Re-base: the deliberate act (§2.2). Writes a dated archive; a human then
#' points KSA_FILE at it.
ksa_fetch <- function(force = FALSE,
                      date = format(Sys.Date(), "%Y-%m-%d")) {
  dest <- file.path(KSA_DIR, paste0(date, "_rhk_ahap_program_page.html"))
  if (file.exists(here::here(dest)) && !force) {
    stop("[KS] ", dest, " exists; use --force.", call. = FALSE)
  }
  rhtp_watch_archive(KSA_URL, dest, KSA_USER_AGENT)
  message("[KS] archived ", dest, ". Point KSA_FILE at it after reading the ",
          "diff.")
  invisible(dest)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) {
    ksa_fetch(force = "--force" %in% args)
  } else if ("--validate" %in% args) {
    ksa_check(ksa_archived_raw())
    message("[KS] AHAP archive is self-consistent: scope found, deck href ",
            "as recorded, two known pilot sites.")
  } else {
    message("Usage: Rscript R/03ca_ks_ahap_watch.R [--fetch [--force] | ",
            "--validate]. The live check runs inside R/03o --probe.")
  }
}
