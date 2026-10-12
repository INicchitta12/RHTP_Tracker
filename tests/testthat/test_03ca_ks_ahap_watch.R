# test_03ca_ks_ahap_watch.R ----------------------------------------------------
# Kansas's AHAP watch (session 98): the Care Collaborative's Anchor Hospital
# Advancement Program page, run inside R/03o's probe. Every trip is shown
# FIRING on a fixture that adds a NEW hospital name to the archived page, and
# the archive itself, the two known pilot sites and a site-menu change are all
# shown SILENT. Offline: fixtures are the committed archive, edited in memory.

library(testthat)

suppressMessages(source(here::here("R", "03ca_ks_ahap_watch.R")))

arch_raw <- ksa_archived_raw()
arch_html <- rawToChar(arch_raw)

# Insert a paragraph at the END of the #main-content region (before the footer
# that follows it), or any HTML before </header>, and hand back raw bytes.
with_content <- function(html_snippet) {
  h <- xml2::read_html(arch_raw)
  mc <- xml2::xml_find_first(h, "//*[@id='main-content']")
  frag <- xml2::xml_find_first(xml2::read_html(
    paste0("<div>", html_snippet, "</div>")), "//body/div")
  xml2::xml_add_child(mc, frag)
  charToRaw(as.character(h))
}

test_that("the archive verifies against its manifest and is a real baseline", {
  man <- readLines(here::here(KSA_DIR, "MANIFEST.txt"))
  line <- grep(KSA_FILE, man, fixed = TRUE, value = TRUE)
  expect_length(line, 1L)
  expect_equal(digest::digest(file = ksa_path(), algo = "sha256"),
               sub("^([0-9a-f]{64}).*$", "\\1", line))
  expect_match(line, KSA_URL, fixed = TRUE)
  txt <- ksa_text(arch_raw)
  expect_gte(length(rhtp_organisation_names(txt)), 3L)
  # what session 96 read, still on the baseline
  expect_match(txt, "10 rural hospitals have been designated as anchor hospitals eligible", fixed = TRUE)
  expect_match(txt, "AHAP pilot sites Newman Regional Health and Labette Health", fixed = TRUE)
  expect_identical(ksa_deck_hrefs(arch_raw), KSA_DECK_HREF)
})

test_that("archive against itself is silent and reports no change", {
  r <- ksa_check(arch_raw, arch_raw)
  expect_identical(r$key, "ahap")
  expect_false(r$content_changed)
})

test_that("the two pilot sites are known: naming them again does not trip", {
  live <- with_content(paste(
    "<p>RPM went live at Newman Regional Health in September.</p>",
    "<p>Labette Health completed BioButton onboarding.</p>"))
  expect_silent(r <- ksa_check(live, arch_raw))
  expect_true(r$content_changed)
})

test_that("a site-menu change outside #main-content is silent", {
  # The live page gained "Ambient Listening Technology" in its menu between
  # 10-07 and 10-12; whole-page reduction reads that as a new organisation.
  menu <- sub("ACO Preparedness Program", paste(
    "ACO Preparedness Program</a></li><li><a href='#'>Ambient Listening",
    "Technology</a></li><li><a href='#'>Hays Medical Center"),
    arch_html, fixed = TRUE)
  expect_false(identical(menu, arch_html))
  expect_silent(ksa_check(charToRaw(menu), arch_raw))
})

test_that("NAME trip: any new hospital in the content region fires", {
  live <- with_content(
    "<p>Hays Medical Center joined the AHAP governing body.</p>")
  expect_error(ksa_check(live, arch_raw), "Hays Medical Center")
})

test_that("(a) ROSTER trip: a list of the anchor hospitals fires", {
  s <- paste("The ten designated anchor hospitals are Hays Medical Center,",
             "Salina Regional Health Center and Pratt Regional Medical",
             "Center.")
  live <- with_content(paste0("<p>", s, "</p>"))
  expect_error(ksa_check(live, arch_raw), "Salina Regional Health Center")
  # and the phrase half catches it on its own, names or no names
  live_txt <- ksa_text(live); arch_txt <- ksa_text(arch_raw)
  expect_length(rhtp_watch_new_sentences(live_txt, arch_txt,
                                         KSA_ROSTER_PATTERN), 1L)
  # with every name in it recorded as known, the ROSTER trip still fires
  kn <- c(KSA_KNOWN, "Hays Medical Center", "Salina Regional Health Center",
          "Pratt Regional Medical Center")
  expect_silent(rhtp_assert_no_new_organisations(live_txt, arch_txt, "KS",
                                                  "ahap", known = kn))
  expect_error(
    rhtp_watch_forbid_new(live_txt, arch_txt, KSA_ROSTER_PATTERN, "KS",
                          "ahap", "x"),
    "NEW SENTENCE")
})

test_that("(a) ROSTER trip: a town-only list with no organisation shape fires", {
  live <- with_content(paste(
    "<p>Hays, Salina and Pratt have been selected as anchor sites.</p>"))
  expect_error(ksa_check(live, arch_raw), "NEW SENTENCE")
})

test_that("(b) RESIDENCY trip: a residency contract naming a hospital fires", {
  s <- paste("AHAP executed a rural residency agreement with KUMC and",
             "Coffeyville Regional Medical Center for family medicine.")
  live <- with_content(paste0("<p>", s, "</p>"))
  expect_error(ksa_check(live, arch_raw), "Coffeyville Regional Medical Center")
  live_txt <- ksa_text(live); arch_txt <- ksa_text(arch_raw)
  expect_length(rhtp_watch_new_sentences(live_txt, arch_txt,
                                         KSA_RESIDENCY_PATTERN), 1L)
  # known-name-proof: with the hospital recorded as known, the phrase fires
  expect_error(
    rhtp_watch_forbid_new(live_txt, arch_txt, KSA_RESIDENCY_PATTERN, "KS",
                          "ahap", "x"),
    "Coffeyville")
})

test_that("the residency and roster patterns are silent on the baseline's own sentences", {
  t <- ksa_text(arch_raw)
  expect_length(rhtp_watch_new_sentences(t, t, KSA_ROSTER_PATTERN), 0L)
  expect_length(rhtp_watch_new_sentences(t, t, KSA_RESIDENCY_PATTERN), 0L)
  # ... and the baseline does carry sentences each would match, so a re-word
  # of one of them is read rather than missed
  sp <- unlist(strsplit(t, "(?<=[.!?])\\s+", perl = TRUE))
  expect_true(any(grepl(KSA_RESIDENCY_PATTERN, sp, ignore.case = TRUE, perl = TRUE)))
})

test_that("DECK trip: a republished Media Fact Deck fires; the broken link is quiet", {
  moved <- sub('href="ruralhealthkansas.com/about"',
               'href="https://ruralhealthkansas.com/wp-content/uploads/2026/10/AHAP-Media-Fact-Deck.pdf"',
               arch_html, fixed = TRUE)
  expect_false(identical(moved, arch_html))
  expect_error(ksa_check(charToRaw(moved), arch_raw), "Media Fact Deck")
})

test_that("a theme without #main-content refuses rather than reading the menu", {
  gone <- gsub('id="main-content"', 'id="moved-content"', arch_html, fixed = TRUE)
  expect_error(ksa_check(charToRaw(gone), arch_raw), "no '#main-content' region")
})

test_that("R/03o's probe runs the AHAP watch, before KDHE, and never writes", {
  src <- readLines(here::here("R", "03o_ks_year1_awardees.R"))
  body <- paste(src, collapse = "\n")
  expect_match(body, "ks_probe_ahap <- function()", fixed = TRUE)
  probe <- sub("^.*\nks_probe <- function\\(\\) \\{", "", body)
  expect_lt(regexpr("ks_probe_ahap()", probe, fixed = TRUE),
            regexpr("ks_get_live(k)", probe, fixed = TRUE))
  ahap_src <- paste(readLines(here::here("R", "03ca_ks_ahap_watch.R")),
                    collapse = "\n")
  probe_fn <- sub("\nksa_fetch <- function.*$", "",
                  sub("^.*\nksa_probe <- function", "", ahap_src))
  expect_false(grepl("rhtp_watch_archive|ksa_fetch|writeBin|write_html", probe_fn))
})
