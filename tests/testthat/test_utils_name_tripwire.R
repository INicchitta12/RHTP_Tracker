# test_utils_name_tripwire.R -------------------------------------------------
# The name-based tripwire: what a watched page NAMES, diffed against the
# committed archive.
#
# WHY THIS FILE EXISTS, AND IT IS A DATED FAILURE RATHER THAN A HYPOTHETICAL.
# On 2026-09-21 New Mexico's HCA page said "HCA has selected six Regional Hub
# Organizations to lead Healthy Horizons" and named Cibola General Hospital,
# the Regents of the University of New Mexico, Eastern Plains Council of
# Governments, Gila Regional Medical Center and Nor-Lea Hospital District.
# `NM_AWARD_POSTED` held ten award phrases and NOT ONE MATCHED, so the tripwire
# whose whole job was to fire the day New Mexico named a recipient sat quiet
# while New Mexico named six.
#
# The defect is not that the list was short. A marker list is built from the
# phrasings a state has ALREADY used, so it cannot contain the one it uses
# NEXT. These tests hold the second signal that does not depend on phrasing:
# the page named somebody it had not named before.
#
# THE TESTS THAT CARRY THE WEIGHT ARE THE ONES THAT COULD PASS FOR THE WRONG
# REASON. A tripwire that fires on everything is useless and a tripwire that
# fires on nothing is worse, so both directions are driven here on REAL
# committed archives -- Louisiana's two snapshots of one page (a change that
# named nobody, which must stay silent) and New Mexico's two (a change that
# named six, which must fire).

library(testthat)

source(here::here("R", "utils_config.R"))


# -- extraction --------------------------------------------------------------

test_that("the six names New Mexico's phrase list missed are all extracted", {
  hca <- paste(
    "HCA has selected six Regional Hub Organizations to lead Healthy Horizons",
    "across New Mexico, with more than $74 million in regional funding.",
    "Region 1: Cibola General Hospital / Gallup Community Health.",
    "Region 2: The Regents of the University of New Mexico.",
    "Region 4: Eastern Plains Council of Governments.",
    "Region 5: Gila Regional Medical Center.",
    "Region 6: Nor-Lea Hospital District.")
  got <- rhtp_organisation_names(hca)

  for (nm in c("Cibola General Hospital", "Gallup Community Health",
               "Gila Regional Medical Center", "Nor-Lea Hospital District")) {
    expect_true(any(grepl(nm, got, fixed = TRUE)), info = nm)
  }
  # These two are the reason connectors are allowed INSIDE a name. Without
  # them the run breaks at "of" and the Regents become "The Regents", which
  # still diffs but tells a human less than it could.
  expect_true(any(grepl("University of New Mexico", got, fixed = TRUE)))
  expect_true(any(grepl("Council of Governments", got, fixed = TRUE)))
})

test_that("NM_AWARD_POSTED's ten phrases really do miss that sentence", {
  # The counterfactual, driven rather than asserted from the session note: if
  # any of these matched, the name tripwire would be belt-and-braces instead
  # of the thing that closes a real gap.
  hca <- paste("HCA has selected six Regional Hub Organizations to lead",
               "Healthy Horizons across New Mexico.")
  phrases <- c("has been awarded", "have been awarded", "awardees are",
               "selected for award", "notice of intent to award",
               "list of awardees", "award recipients", "funding recipients",
               "successful applicant", "selected organizations")
  hit <- phrases[purrr::map_lgl(phrases, ~ stringr::str_detect(
    hca, stringr::regex(.x, ignore_case = TRUE)))]
  expect_identical(hit, character(0))
})

test_that("a single capitalised word is not an organisation", {
  # "Region", "September", "Hospital" alone are not names. Requiring a space
  # is what keeps the diff from reporting every capitalised noun on a page.
  expect_identical(rhtp_organisation_names("Hospital. Health. Center."),
                   character(0))
  expect_identical(rhtp_organisation_names(""), character(0))
  expect_identical(rhtp_organisation_names(character(0)), character(0))
})

test_that("a run needs an organisation token, not merely capitals", {
  expect_identical(
    rhtp_organisation_names("The Governor announced New Funding Tuesday."),
    character(0))
})


# -- the diff ----------------------------------------------------------------

test_that("a page diffed against itself yields nothing", {
  txt <- paste("Cibola General Hospital and Gila Regional Medical Center are",
               "listed by the New Mexico Health Care Authority.")
  expect_identical(rhtp_new_organisation_names(txt, txt), character(0))
})

test_that("chrome present in both copies cancels, which is what lets the
           suffix list be broad", {
  chrome <- paste("New Mexico Health Care Authority. Medical Assistance",
                  "Division. Behavioral Health Services Division.")
  expect_identical(rhtp_new_organisation_names(chrome, chrome), character(0))
  # ... and the same chrome does not hide a real name added beside it.
  # `grepl` rather than `%in%` ON PURPOSE: the name comes back AS PRINTED,
  # trailing full stop and all, while the COMPARISON strips it. Reporting the
  # printed form is what lets a human find the sentence on the page.
  got <- rhtp_new_organisation_names(
    paste(chrome, "Gila Regional Medical Center."), chrome)
  expect_true(any(grepl("Gila Regional Medical Center", got, fixed = TRUE)))
})

test_that("a known name is suppressed whether the run truncated or over-joined", {
  before <- "The New Mexico Health Care Authority runs the programme."
  after  <- paste(before, "Gila Regional Medical Center Region 6.")
  expect_true(length(rhtp_new_organisation_names(after, before)) > 0L)
  # Containment BOTH ways: the run may carry a trailing "Region" the human's
  # note does not, and a human may write a fuller name than the run captured.
  expect_identical(
    rhtp_new_organisation_names(after, before,
                                known = "Gila Regional Medical Center"),
    character(0))
  expect_identical(
    rhtp_new_organisation_names(
      after, before,
      known = "Gila Regional Medical Center Region 6 of New Mexico"),
    character(0))
})

test_that("the curly apostrophe does not make an old name look new", {
  # Session 40: Arkansas's award list prints U+0027 and the Governor's release
  # prints U+2019, and nine names failed to join for a reason neither document
  # shows. Here that would be nine false tripwires.
  straight <- "St. Mary's Regional Medical Center is listed."
  curly    <- "St. Mary’s Regional Medical Center is listed."
  expect_identical(rhtp_new_organisation_names(curly, straight), character(0))
})

test_that("a zero-width space does not make an old name look new", {
  # Session 34: HCAI's WDRR heading carries one and it broke an assertion with
  # nothing to point at.
  plain <- "Gila Regional Medical Center is listed."
  zwsp  <- "Gila​ Regional Medical Center is listed."
  expect_identical(rhtp_new_organisation_names(zwsp, plain), character(0))
})

test_that("a date moving is not a name appearing", {
  # LOUISIANA, and this is measured rather than reasoned about -- see the real
  # -archive test below. The reduction flattens a table cell boundary to a
  # space, so the announcement window welds onto the programme name beside it.
  old <- paste("Mid to late August Rural Medicaid Alternative Payment Model",
               "Program Application Submission Deadline.")
  new <- paste("End of September Rural Medicaid Alternative Payment Model",
               "Program Application Submission Deadline.")
  expect_identical(rhtp_new_organisation_names(new, old), character(0))
})


# -- the assertion -----------------------------------------------------------

test_that("the assertion is silent when nothing new is named", {
  txt <- paste("The New Mexico Health Care Authority, the Medical Assistance",
               "Division, the Behavioral Health Services Division and the",
               "Rural Health Data Hub are named by the Primary Care Council.")
  expect_silent(rhtp_assert_no_new_organisations(txt, txt, "NM", "programme"))
})

test_that("the assertion throws, names the page, and prints the names", {
  before <- paste("The New Mexico Health Care Authority, the Medical",
                  "Assistance Division, the Rural Health Data Hub and the",
                  "Primary Care Council are listed.")
  after  <- paste(before, "Nor-Lea Hospital District has been selected.")
  expect_error(
    rhtp_assert_no_new_organisations(after, before, "NM", "programme"),
    "Nor-Lea Hospital District")
  expect_error(
    rhtp_assert_no_new_organisations(after, before, "NM", "programme"),
    "programme")
  # It must say the firing is the SIGNAL. A tripwire a future session reads as
  # a defect gets patched away, which is how the thing it watches goes quiet.
  expect_error(
    rhtp_assert_no_new_organisations(after, before, "NM", "programme"),
    "THE SIGNAL, NOT A DEFECT")
})

test_that("AN EMPTY BASELINE IS REFUSED, and that is the guard that keeps
           this check honest", {
  # A diff against nothing either fires on everything or -- if the live side
  # is empty too -- PASSES SILENTLY FOREVER while wearing a green verdict.
  # The second is precisely the shape of failure this function exists to end,
  # and it is a statement about our reading reported as one about the state
  # (§0.4). Missouri found it for real: `hub_roster` is a PDF, and handed to
  # an HTML reader it yields 450 characters of PDF header.
  expect_error(
    rhtp_assert_no_new_organisations("Gila Regional Medical Center opened.",
                                     "%PDF-1.6 stream endstream",
                                     "MO", "hub_roster"),
    "NO BASELINE")
  expect_error(
    rhtp_assert_no_new_organisations("", "", "MO", "hub_roster"),
    "NO BASELINE")
  # And it says whose fault it is not.
  expect_error(
    rhtp_assert_no_new_organisations("", "", "MO", "hub_roster"),
    "never about the state")
})

test_that("the multi-page form refuses an unnamed list and a missing baseline", {
  txt <- paste("The New Mexico Health Care Authority, the Medical Assistance",
               "Division, the Rural Health Data Hub and the Primary Care",
               "Council are listed.")
  expect_error(
    rhtp_assert_no_new_organisations_across(
      live = list(txt), archived = list(programme = txt), state = "NM"),
    "NAMED list")
  expect_error(
    rhtp_assert_no_new_organisations_across(
      live = list(programme = txt), archived = list(news = txt), state = "NM"),
    "no archived copy")
  expect_silent(
    rhtp_assert_no_new_organisations_across(
      live = list(programme = txt), archived = list(programme = txt),
      state = "NM"))
})


# -- the real archives, which is where this stops being a unit test ----------

test_that("LOUISIANA: a re-dating that named nobody stays silent", {
  # LDH re-dated all SEVEN announcement windows between 2026-09-02 and
  # 2026-09-21 and named NOBODY. The content digest moved, correctly. The name
  # tripwire must not fire -- a probe that halts on a date is session 46's
  # stale dated anchor in a new costume.
  d <- rhtp_path("evidence", "LA")
  old_f <- file.path(
    d, "2026-09-02_la_ldh_rhtp_programme_SEVEN_WINDOWS_PASSED_SUPERSEDED.html")
  new_f <- file.path(
    d, "2026-09-21_la_ldh_rhtp_programme_SEVEN_WINDOWS_RE_DATED.html")
  skip_if_not(file.exists(old_f) && file.exists(new_f))
  suppressMessages(source(here::here("R", "03ae_la_year1_probe.R")))

  rd <- function(p) la_reduce_html(readBin(p, "raw", file.size(p)))
  old <- rd(old_f); new <- rd(new_f)

  expect_false(identical(old, new))          # the page DID change
  expect_gt(length(rhtp_organisation_names(old)), 50L)
  expect_identical(rhtp_new_organisation_names(new, old), character(0))
  expect_identical(rhtp_new_organisation_names(old, new), character(0))
  expect_silent(rhtp_assert_no_new_organisations(new, old, "LA", "programme"))
})

test_that("NEW MEXICO: the six hubs fire against the archive that predates them", {
  # THE COUNTERFACTUAL, ON REAL COMMITTED BYTES. Session 35 archived HCA's
  # page; session 46 fetched it again and the hubs were on it. This is what
  # the name tripwire would have said on the day the phrase list said nothing.
  cur <- rhtp_path("evidence", "NM",
                   "2026-09-21_nm_hca_rht_programme_SIX_HUBS_SELECTED.html")
  skip_if_not(file.exists(cur))
  suppressMessages(source(here::here("R", "03ad_nm_year1_probe.R")))

  tmp <- tempfile(fileext = ".html")
  on.exit(unlink(tmp), add = TRUE)
  ok <- tryCatch(
    system2("git",
            c("show",
              "967ee21:data/evidence/NM/2026-09-02_nm_hca_rht_programme.html"),
            stdout = tmp, stderr = FALSE) == 0L,
    error = function(e) FALSE)
  skip_if(!isTRUE(ok) || !file.exists(tmp) || file.size(tmp) < 1000,
          "the session-35 NM archive is not reachable from git here")

  # nm_reduce_html() takes RAW -- it strips NUL bytes before decoding.
  prior <- nm_reduce_html(readBin(tmp, "raw", file.size(tmp)))
  live  <- nm_html_text("programme")

  new_names <- rhtp_new_organisation_names(live, prior)
  hit <- function(x) any(grepl(x, new_names, fixed = TRUE))
  expect_true(hit("Cibola General Hospital"))
  expect_true(hit("Gallup Community Health"))
  expect_true(hit("University of New Mexico"))
  expect_true(hit("Eastern Plains Council of Governments"))
  expect_true(hit("Gila Regional Medical Center"))
  expect_true(hit("Nor-Lea Hospital District"))

  # And with the six recorded as this file records them, it goes quiet again.
  expect_identical(
    rhtp_new_organisation_names(live, prior, known = NM_KNOWN_ORGANISATIONS),
    character(0))
})

test_that("every wired probe's watched pages have a real baseline TODAY", {
  # The check that stops a page being silently unwatched. Archive against
  # itself must be silent AND the baseline must clear the floor -- a page
  # yielding no names is one this tripwire cannot see at all, whatever its
  # verdict says.
  spec <- list(
    CA = list("R/03ab_ca_year1_probe.R", "ca_html_text",
              c("funding", "calrht")),
    CT = list("R/03ac_ct_year1_probe.R", "ct_html_text",
              c("programme", "documents", "opm")),
    NM = list("R/03ad_nm_year1_probe.R", "nm_html_text",
              c("programme", "news")),
    KY = list("R/03af_ky_year1_probe.R", "ky_html_text",
              c("funding", "programme", "rch")),
    NY = list("R/03ag_ny_year1_probe.R", "ny_html_text", c("programme")),
    NC = list("R/03ah_nc_year1_sources.R", "nc_html_text",
              c("roots_page", "opportunities", "trillium")),
    MS = list("R/03ak_ms_year1_awardees.R", "ms_html_text",
              c("funding", "home")),
    DE = list("R/03al_de_year1_awardees.R", "de_html_text",
              c("release", "programme")),
    ID = list("R/03am_id_year1_awardees.R", "id_html_text",
              c("funding", "about")),
    OH = list("R/03an_oh_year1_awardees.R", "oh_html_text",
              c("release", "odh")),
    SC = list("R/03ao_sc_year1_awardees.R", "sc_html_text", c("programme")),
    WI = list("R/03y_wi_year1_probe.R", "wi_html_text",
              c("dhs_rhtp", "dhs_solicit")))

  for (st in names(spec)) {
    f <- spec[[st]][[1]]; fn <- spec[[st]][[2]]; keys <- spec[[st]][[3]]
    skip_if_not(file.exists(here::here(f)), f)
    suppressWarnings(suppressMessages(source(here::here(f))))
    rd <- get(fn)
    for (k in keys) {
      txt <- rd(k)
      expect_gte(length(rhtp_organisation_names(txt)), 3L,
                 label = paste(st, k, "baseline"))
      expect_silent(rhtp_assert_no_new_organisations(txt, txt, st, k))
    }
  }
})

test_that("every probe that offers --probe also runs the name tripwire", {
  # The rule made checkable, the way session 46 made `rhtp_probe_run()` one:
  # a twentieth state file cannot quietly ship a probe with only a phrase
  # list. Alaska and South Dakota are the two recorded exemptions and they say
  # why in their own source.
  exempt <- c("03h_ak_year1_awardees.R", "03i_sd_rht_contracts.R")
  files <- list.files(here::here("R"), pattern = "\\.R$", full.names = TRUE)
  offenders <- character(0)
  for (f in files) {
    src <- paste(readLines(f, warn = FALSE), collapse = "\n")
    if (!grepl('"--probe" %in% args', src, fixed = TRUE)) next
    if (basename(f) %in% exempt) next
    if (!grepl("rhtp_assert_no_new_organisations", src, fixed = TRUE)) {
      offenders <- c(offenders, basename(f))
    }
  }
  expect_identical(offenders, character(0))
})


# -- session 52: furniture is EXACT, scope is anchored, CLOSED breaks a run ---

test_that("a furniture entry quiets exactly its own string and nothing longer", {
  arch <- "Kentucky Hospital Association and Pikeville County Board of Health."
  live <- paste(arch, "Rural Health Transformation Fund.",
                "Rural Health Transformation Fund Hospital Authority.")
  # As `known`, containment would swallow the longer one -- the reason
  # furniture is a separate, exact list.
  expect_length(rhtp_new_organisation_names(
    live, arch, known = "Rural Health Transformation Fund"), 0L)
  got <- rhtp_new_organisation_names(
    live, arch, furniture = "Rural Health Transformation Fund")
  expect_identical(sub("[.]$", "", got),
                   "Rural Health Transformation Fund Hospital Authority")
})

test_that("the multi-page form passes furniture per page", {
  arch <- list(a = "Alpha County Board of Health. Beta Medical Center. Gamma Health System.",
               b = "Alpha County Board of Health. Beta Medical Center. Gamma Health System.")
  live <- list(a = paste(arch$a, "Advisory Board Members."),
               b = paste(arch$b, "Advisory Board Members."))
  expect_error(rhtp_assert_no_new_organisations_across(
    live, arch, "XX", furniture = list(a = "Advisory Board Members")),
    "'b' NAMES 1")
  expect_silent(rhtp_assert_no_new_organisations_across(
    live, arch, "XX", furniture = "Advisory Board Members"))
})

test_that("a STATUS LABEL breaks a run, as a date does (Idaho, session 52)", {
  arch <- "Posted 8/18/26: Healthcare Infrastructure Support FAQ. Alpha Medical Center. Beta Health System."
  live <- paste("CLOSED 9/18/26: Healthcare Infrastructure Support CLOSED 9/17/26:",
                "Alpha Medical Center. Beta Health System.")
  expect_false(any(grepl("CLOSED", rhtp_organisation_names(live))))
  # Upper case only: a real name carrying the word in title case still joins.
  expect_true(any(grepl("Closed Loop Health System",
                        rhtp_organisation_names("The Closed Loop Health System."))))
})

test_that("a name-tripwire SCOPE refuses a missing anchor and a scope that keeps nothing", {
  txt <- paste(c("MENU", "Latest News Something Health System",
                 "Flag Status", "Beebe Healthcare awarded", "Keep up to date by receiving",
                 rep("footer", 3)), collapse = "\n")
  s <- rhtp_name_scope(txt, "^Flag Status", "^Keep up to date")
  expect_false(grepl("Latest News", s))
  expect_true(grepl("Beebe Healthcare", s))
  expect_error(rhtp_name_scope(txt, "^NO SUCH ANCHOR"), "was not found")
  expect_error(rhtp_name_scope(txt, "^Flag Status", "^NO END"), "end anchor")
  expect_error(rhtp_name_scope(txt, "^Flag Status", "^Beebe", min_keep = 0.5),
               "keeps")
})

test_that("each retuned probe is silent on today's archive AND still fires on a recipient", {
  # The retune must not have bought quiet with blindness: for every page
  # session 52 gave a furniture list or a scope, a real recipient appended to
  # the archived text is still reported.
  inject <- "Pikeville Medical Center"
  spec <- list(
    WI = list("R/03y_wi_year1_probe.R", function() list(dhs_solicit = wi_html_text("dhs_solicit")),
              function() WI_NAME_FURNITURE),
    ME = list("R/03aa_me_year1_awardees.R", function() list(programme = me_html_text("programme")),
              function() ME_NAME_FURNITURE),
    KY = list("R/03af_ky_year1_probe.R", function() list(rch = ky_html_text("rch")),
              function() KY_NAME_FURNITURE),
    NC = list("R/03ah_nc_year1_sources.R", function() list(trillium = nc_html_text("trillium")),
              function() NC_NAME_FURNITURE),
    ID = list("R/03am_id_year1_awardees.R",
              function() list(funding = id_html_text("funding"), about = id_html_text("about")),
              function() ID_NAME_FURNITURE),
    CA = list("R/03ab_ca_year1_probe.R",
              function() list(funding = ca_name_scope(ca_html_text("funding"), "funding"),
                              calrht = ca_name_scope(ca_html_text("calrht"), "calrht")),
              function() list()),
    DE = list("R/03al_de_year1_awardees.R",
              function() list(release = de_name_scope(de_html_text("release"), "release"),
                              programme = de_name_scope(de_html_text("programme"), "programme")),
              function() list()))
  for (st in names(spec)) {
    f <- spec[[st]][[1]]
    suppressWarnings(suppressMessages(source(here::here(f))))
    pages <- spec[[st]][[2]]()
    fu <- spec[[st]][[3]]()
    for (k in names(pages)) {
      arch <- pages[[k]]
      furn <- if (k %in% names(fu)) fu[[k]] else character(0)
      expect_gte(length(rhtp_organisation_names(arch)), 3L,
                 label = paste(st, k, "baseline after scope"))
      expect_length(rhtp_new_organisation_names(arch, arch, furniture = furn), 0L)
      live <- paste0(arch, "\n", inject, " has been awarded.\n")
      expect_true(inject %in% rhtp_new_organisation_names(live, arch, furniture = furn),
                  label = paste(st, k, "still fires on a recipient"))
      # And every furniture string is exact: appending one quiets nothing else.
      for (x in furn) {
        expect_length(rhtp_new_organisation_names(paste0(arch, "\n", x, "\n"),
                                                  arch, furniture = furn), 0L)
      }
    }
  }
})

test_that("Delaware's scope drops the NEWS FEED and keeps the four awards", {
  suppressWarnings(suppressMessages(source(here::here("R", "03al_de_year1_awardees.R"))))
  full <- de_html_text("release")
  s <- de_name_scope(full, "release")
  expect_true(grepl("NEWS FEED", full, fixed = TRUE))
  expect_false(grepl("NEWS FEED", s, fixed = TRUE))
  for (nm in c("Nemours Children's Health", "TidalHealth", "Beebe Healthcare")) {
    expect_true(grepl(nm, s, fixed = TRUE), label = nm)
  }
})
