# Wisconsin -- the negative, and the controls that make it evidence.
#
# Wisconsin is at SOLICITATION stage with its award window open THIS MONTH, so
# every assertion here is a tripwire whose failure is the signal. These run
# offline against the committed archive.

source(here::here("R", "03y_wi_year1_probe.R"))

test_that("no Wisconsin award file exists, deliberately", {
  expect_false(file.exists(here::here(WI_AWARDS_CSV)))
  expect_silent(wi_assert_no_award_file())
})

test_that("the status table has no amount column, and cannot acquire one", {
  status <- rhtp_wi_year1_status()
  expect_false(any(c("amount", "round_amount", "amount_announced") %in%
                     names(status)))
  # Texas's device: the pool ceilings are the state's own words, in a text
  # column, so no sum over this table can produce a Wisconsin hospital dollar.
  expect_true("stated_pool" %in% names(status))
  expect_type(status$stated_pool, "character")
})

test_that("every DHS opportunity is closed and unawarded, in DHS's own words", {
  expect_silent(wi_assert_no_award_roster())
  txt <- wi_html_text("dhs_rhtp")
  expect_equal(stringr::str_count(txt, stringr::fixed(WI_CLOSED_MARKER)),
               WI_CLOSED_EXPECTED)
})

test_that("the tripwire fires when an opportunity stops being closed", {
  txt <- wi_html_text("dhs_rhtp")
  awarded <- stringr::str_replace(txt, stringr::fixed(WI_CLOSED_MARKER),
                                  "awardees announced")
  expect_error(wi_assert_no_award_roster(program_body = awarded),
               "READ THE PAGE")
})

test_that("the tripwire fires when DHS stops speaking in the future tense", {
  txt <- wi_html_text("dhs_rhtp")
  past <- stringr::str_replace(
    txt, stringr::fixed(WI_FUTURE_AWARD_MARKERS[["tech"]]),
    "DHS awarded $61 million in the first round of funding")
  expect_error(wi_assert_no_award_roster(program_body = past), "FUTURE")
})

test_that("the positive control fires -- DHS labels its list unawarded", {
  # Without this, "Wisconsin has published no roster" is indistinguishable
  # from "we did not find the page where it publishes one".
  sol <- wi_html_text("dhs_solicit")
  expect_true(stringr::str_detect(sol, stringr::fixed(WI_SOLICIT_UNAWARDED)))
  expect_error(
    wi_assert_no_award_roster(solicit_body = "no such label here"),
    "positive control")
})

test_that("DHS dated what has not happened: award announcements are September", {
  expect_equal(wi_assert_award_announcements_pending(),
               WI_AWARD_ANNOUNCEMENT_N)
})

test_that("the council deck's TEXT carries none of RCJ's 16 amounts", {
  # THE §0.1 FINDING. RCJ files all 16 priced Wisconsin rows under this deck.
  deck <- wi_deck_text()
  amts <- wi_rcj_priced_amounts()
  expect_equal(length(amts), WI_STATED$wtcs_colleges_n)
  for (a in amts) {
    expect_false(
      stringr::str_detect(deck, stringr::fixed(
        format(a, big.mark = ",", scientific = FALSE))),
      info = paste("deck unexpectedly carries", a))
  }
  # and the decoder demonstrably works on this file, so the absence above is a
  # fact about the document and not about the reader.
  expect_true(stringr::str_detect(deck, stringr::fixed("$203,670,005.21")))
})

test_that("the tripwire fires if the deck ever carries one of those amounts", {
  deck <- paste(wi_deck_text(), "Northwood Technical College 3,199,618")
  expect_error(wi_assert_wtcs_allocation_is_formula(deck = deck),
               "must be re-read")
})

test_that("the deck says the 16 figures are a FORMULA allocation", {
  deck <- wi_deck_text()
  for (m in WI_WTCS_FORMULA_MARKERS) {
    expect_true(stringr::str_detect(deck, stringr::fixed(m)), info = m)
  }
})

test_that("RCJ's 16 bare region names are the 16 WTCS college districts", {
  expect_equal(length(wi_assert_wtcs_names_are_colleges()),
               WI_STATED$wtcs_colleges_n)
})

test_that("the WTCS mapping fails loudly if a name stops matching", {
  roster <- stringr::str_remove_all(wi_html_text("wtcs_colleges"),
                                    stringr::fixed("Blackhawk"))
  expect_error(wi_assert_wtcs_names_are_colleges(roster = roster),
               "do not appear on the WTCS college roster")
})

test_that("THE NEGATIVE CONTROL: an award list on an RHTP page that is not RHTP", {
  # DWD's "Successful WIG Healthcare Awards" is linked from the RHTP-funded
  # WIG: HEART page and is the Governor's 2021 ARPA programme. This is the
  # test that stops a future session reading it as Wisconsin's RHTP roster.
  expect_silent(wi_assert_wig_is_not_rhtp())
  txt <- wi_wig_text()
  expect_equal(stringr::str_count(txt, "RHTP|Rural Health Transformation"), 0L)
  expect_true(stringr::str_detect(txt, stringr::fixed(WI_WIG_MARKERS[["arpa"]])))
})

test_that("the negative control fails if DWD folds RHTP into it", {
  txt <- paste(wi_wig_text(), "This is an RHTP award.")
  expect_error(wi_assert_wig_is_not_rhtp(body = txt), "negative control")
})

test_that("§0.3: DPI publishes 213 ELIGIBLE districts and 20 FUTURE awards", {
  expect_silent(wi_assert_dpi_eligibility_not_receipt())
  txt <- wi_html_text("dpi_rhtp")
  expect_true(stringr::str_detect(txt, "213 rural LEAs meet these eligibility"))
  # future tense, and no awardee anywhere
  expect_true(stringr::str_detect(txt, "will receive competitive grants"))
})

test_that("§0.3: the $61M pool's eligible class is closed and pre-identified", {
  expect_silent(wi_assert_tech_eligibility_pre_identified())
  txt <- wi_html_text("dhs_rhtp")
  expect_true(stringr::str_detect(txt, stringr::fixed(
    "Only organizations named in the application are eligible")))
  # It is worth $61M and it is ELIGIBILITY. Nothing in this repo may read it
  # as receipt.
  expect_true(stringr::str_detect(txt, stringr::fixed(
    WI_FUTURE_AWARD_MARKERS[["tech"]])))
})

test_that("§6.2 passes on programme-scoped evidence, footer non-strict", {
  expect_silent(wi_assert_program_page_provenance())
  expect_true(isTRUE(wi_assert_footer_corroborates(strict = FALSE)))
})

test_that("the footer is DEMOTED: losing it does not hard-fail Wisconsin", {
  # Session 28's Kansas demotion. A DHS re-post that dropped the boilerplate
  # must not fail the state, because the footer was never the provenance.
  expect_message(
    res <- wi_assert_footer_corroborates(strict = FALSE,
                                         body = "a page with no footer at all"),
    "only ever corroborating")
  expect_true(is.na(res))
  # and strict still throws, so the demotion is a choice at the call site and
  # not a weakening of the check itself
  expect_error(
    wi_assert_footer_corroborates(strict = TRUE,
                                  body = "a page with no footer at all"),
    "no longer carries")
})

test_that("Wisconsin's allotment is the CMS anchor's, not this file's", {
  allot <- rhtp_load_allotments()
  wi <- allot$fy2026_allotment[allot$state == "WI"]
  expect_equal(wi, WI_STATED$cms_allotment_anchor)
  expect_lt(abs(WI_STATED$cms_allotment_stated - wi), 1)
})

test_that("every solicitation post-dates the 2025-12-29 Notice of Award", {
  dates <- wi_assert_after_noa()
  expect_true(all(dates > as.Date(WI_STATED$noa_date)))
})

test_that("every RCJ Wisconsin Tier 3 candidate is accounted for, and none survives", {
  cands <- wi_rcj_candidates()
  dispo <- rhtp_wi_rcj_disposition(cands)
  expect_equal(sum(dispo$rows), nrow(cands))
  expect_equal(nrow(cands), 19L)
  expect_equal(dispo$rows[dispo$disposition ==
                            "RHTP_BUT_A_FORMULA_ALLOCATION_NOT_A_SUBAWARD"], 16L)
  expect_equal(dispo$rows[dispo$disposition ==
                            "TIER_2_BUDGET_LINE_NOT_A_SUBAWARD"], 3L)
  # not one is an RHTP subaward
  expect_false(any(stringr::str_detect(dispo$disposition, "^RHTP_AWARD")))
})

test_that("the disposition sums close on the survey's own figure", {
  dispo <- rhtp_wi_rcj_disposition()
  expect_equal(sum(dispo$rcj_amount_sum), 100139403)
  expect_equal(dispo$rcj_amount_sum[dispo$rows == 16L], 22139403)
  expect_equal(dispo$rcj_amount_sum[dispo$rows == 3L], 78000000)
})

test_that("the disposition count is derived, not typed", {
  fake <- wi_rcj_candidates()[1:5, ]
  dispo <- rhtp_wi_rcj_disposition(fake)
  expect_equal(sum(dispo$rows), 5L)
})

test_that("the unreadable path is recorded as UNKNOWN, never as a negative", {
  status <- rhtp_wi_year1_status()
  row <- status[status$stage == "UNREADABLE", ]
  expect_equal(nrow(row), 1L)
  expect_equal(row$publishes_roster, "UNKNOWN")
  expect_true(stringr::str_detect(row$evidence, "UNREADABLE, NOT NEGATIVE"))
  # all four agents recorded, so the next session re-runs rather than re-decides
  expect_equal(length(WI_UNREADABLE_AGENTS), 4L)
  expect_true(stringr::str_detect(row$evidence, "PER-PATH refusal"))
})

test_that("no status row claims a roster", {
  status <- rhtp_wi_year1_status()
  expect_false(any(status$publishes_roster == "Yes"))
})

test_that("the archive verifies and the manifest does not list itself", {
  man <- file.path(WI_EVIDENCE_DIR, "MANIFEST.txt")
  expect_true(file.exists(man))
  lines <- readLines(man, warn = FALSE)
  expect_false(any(stringr::str_detect(lines, "^MANIFEST\\.txt")))
  listed <- lines[stringr::str_detect(lines, "^\\S+\\s+\\d+\\s+[0-9a-f]{64}$")]
  expect_equal(length(listed), nrow(WI_SOURCES))
  for (l in listed) {
    parts <- strsplit(stringr::str_squish(l), " ")[[1]]
    path <- file.path(WI_EVIDENCE_DIR, parts[1])
    expect_true(file.exists(path), info = parts[1])
    expect_equal(digest::digest(file = path, algo = "sha256"), parts[3],
                 info = parts[1])
  }
})


# -- the live probe (session 31) ---------------------------------------------
# Offline throughout: these drive the probe's PARTS against the committed
# archive and against synthesised bodies. The probe itself makes network calls
# and is never invoked here.

test_that("the probe watches the three sources that can answer the question", {
  # And only those. DPI, DWD, WORH and WTCS are context and controls: they
  # cannot change whether Wisconsin has awarded, and probing them weekly would
  # spend requests on a question they do not hold.
  expect_setequal(WI_PROBE_KEYS, c("dhs_rhtp", "dhs_solicit", "dhs_deck_0723"))
  expect_true(all(WI_PROBE_KEYS %in% WI_SOURCES$key))
  expect_equal(unname(vapply(WI_PROBE_KEYS, wi_probe_kind, character(1))),
               c("html", "html", "pdf"))
})

test_that("the content digest ignores what the Akamai beacon rotates", {
  # WHY THIS IS A CONTENT DIGEST AND NOT A FILE DIGEST, DRIVEN RATHER THAN
  # ASSERTED. www.dhs.wisconsin.gov injects a Boomerang RUM beacon carrying a
  # per-request nonce into every HTML response -- ak.rid, ak.t, a fresh ak.ak
  # signature, an edge hostname, the client port. Two fetches two seconds apart
  # are 169,310 and 169,311 bytes and differ on eighteen lines, all inside that
  # one <script>.
  #
  # This is the THIRD mechanism for one failure and they are three different
  # things: Nevada rotates a widget in the page's CONTENT, Missouri an
  # Incapsula cache-buster in a script SRC, Wisconsin a beacon in a script
  # BODY. A file digest is not a change detector on a modern state host.
  held <- readBin(wi_path("dhs_rhtp"), "raw", file.size(wi_path("dhs_rhtp")))
  base <- wi_content_digest(held, "html")

  beacon <- function(rid, t, port) {
    paste0('<script>!function(){var i={"ak.rid":"', rid, '","ak.t":"', t,
           '","ak.cport":', port, ',"ak.ak":"', rid, t, '=="};}();</script>')
  }
  a <- charToRaw(paste0(rawToChar(held), beacon("16129e", "1788284422", 32768)))
  b <- charToRaw(paste0(rawToChar(held), beacon("165fc5", "1788284424", 32769)))

  # The file digests differ -- the failure the probe has to survive ...
  expect_false(identical(digest::digest(a, algo = "sha256"),
                         digest::digest(b, algo = "sha256")))
  # ... and the content digests do not.
  expect_equal(wi_content_digest(a, "html")$sha, wi_content_digest(b, "html")$sha)
  expect_equal(wi_content_digest(a, "html")$sha, base$sha)
})

test_that("the probe and the assertions read the SAME reduction", {
  # Missouri's rule (session 29): a probe that reduces differently from the
  # assertions it feeds drifts away from them silently, and the drift shows up
  # as a tripwire that has quietly stopped firing. `wi_reduce_html()` is the
  # one definition, and `wi_html_text()` is the key-based wrapper over it.
  held <- readBin(wi_path("dhs_rhtp"), "raw", file.size(wi_path("dhs_rhtp")))
  expect_identical(wi_reduce_html(held), wi_html_text("dhs_rhtp"))
  expect_identical(wi_content_digest(held, "html")$text, wi_html_text("dhs_rhtp"))
})

test_that("the probe's tripwires run against supplied bodies, not the archive", {
  # SESSION 25'S INDIANA LESSON AS CODE. --validate reads the committed copy
  # and passes trivially, so it can only answer "had Wisconsin awarded on the
  # day the archive was taken?". Each tripwire takes a body override so the
  # probe can hand it what the server just served -- and each must FAIL on a
  # body where Wisconsin has moved, or the probe is decoration.
  prog <- wi_html_text("dhs_rhtp")
  sol  <- wi_html_text("dhs_solicit")
  deck <- wi_deck_text()

  # Today's bytes: all three hold.
  expect_true(wi_assert_no_award_roster(program_body = prog, solicit_body = sol))
  expect_true(wi_assert_tech_eligibility_pre_identified(body = prog))
  expect_equal(wi_assert_award_announcements_pending(deck = deck),
               WI_AWARD_ANNOUNCEMENT_N)

  # An opportunity that has awarded: one "application period now closed" marker
  # replaced by a roster heading.
  awarded <- sub(WI_CLOSED_MARKER, "awarded projects and recipients", prog,
                 fixed = TRUE)
  expect_error(wi_assert_no_award_roster(program_body = awarded,
                                         solicit_body = sol), "markers")

  # The solicitations index no longer calling itself unawarded.
  expect_error(wi_assert_no_award_roster(
    program_body = prog,
    solicit_body = sub(WI_SOLICIT_UNAWARDED, "recent awards", sol, fixed = TRUE)),
    "unawarded")

  # The $61M pool losing the sentence that keeps it ELIGIBILITY and not receipt.
  expect_error(wi_assert_tech_eligibility_pre_identified(
    body = sub(WI_TECH_ELIGIBILITY, "All rural organizations may apply", prog,
               fixed = TRUE)), "pre-identified")

  # The September window moving.
  expect_error(wi_assert_award_announcements_pending(
    deck = gsub(WI_AWARD_ANNOUNCEMENT_MARKER, "Awards announced", deck,
                fixed = TRUE)), "markers")
})

test_that("the 403 path is REPORTED, never asserted", {
  # The one thing about Wisconsin this repository records as UNKNOWN rather
  # than as a negative (§0.4), and its slug is "...fund-ALLOCATIONS" -- the url
  # most likely to carry a Rural Technology Transformation roster. A per-path
  # refusal on an otherwise fully readable host may simply be a page withdrawn
  # and later restored, so a 200 here is a NEW SOURCE TO READ and must not be
  # a build failure.
  expect_true(is.function(wi_probe_unreadable))
  body <- paste(deparse(wi_probe_unreadable), collapse = " ")
  expect_true(grepl("NOW READABLE", body, fixed = TRUE))
  expect_false(grepl("stop(", body, fixed = TRUE))
  expect_equal(WI_UNREADABLE_STATUS, 403L)
  expect_length(WI_UNREADABLE_AGENTS, 4L)
})

