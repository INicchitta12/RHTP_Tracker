# test_03cg_il_rhtp_probe.R -------------------------------------------------
# Illinois's watch (session 106). Reads committed evidence off disk only -- no
# network, no quota. Each tripwire is DRIVEN with a planted change, and the
# archive against itself must be quiet.

library(testthat)

source(here::here("R", "03cg_il_rhtp_probe.R"))

il_arch <- function(k) {
  f <- c(IL_PROBE_PAGES$file, IL_PROBE_RAW$file)[
    match(k, c(IL_PROBE_PAGES$key, IL_PROBE_RAW$key))]
  here::here(f)
}
il_html <- function(k) paste(readLines(il_arch(k), warn = FALSE,
                                       encoding = "UTF-8"), collapse = "\n")
hfs_txt <- rhtp_watch_reduce(il_arch("hfs_rhtp"), IL_HFS_SCOPE)

test_that("every baseline is archived, listed in the manifest and credential-free", {
  man <- readLines(here::here(IL_PROBE_DIR, "MANIFEST.txt"))
  for (k in c(IL_PROBE_PAGES$key, IL_PROBE_RAW$key)) {
    f <- il_arch(k)
    expect_true(file.exists(f), info = k)
    sha <- digest::digest(file = f, algo = "sha256")
    expect_true(any(startsWith(man, paste0(sha, "  ", basename(f)))), info = k)
    raw <- readBin(f, "raw", file.size(f))
    expect_length(grepRaw(paste0(IL_CREDENTIAL_RE, "|accessToken"), raw), 0L)
  }
})

test_that("the HFS scope reads the article, not the mega-menu", {
  expect_match(hfs_txt, "awarded Illinois $193.4 million", fixed = TRUE)
  expect_match(hfs_txt, "Hospital Planning Grant Methodology", fixed = TRUE)
  expect_false(grepl("Medicaid Technical Assistance Center", hfs_txt, fixed = TRUE))
  expect_gte(length(rhtp_organisation_names(hfs_txt)), 3L)
  expect_true(any(grepl("RHTPHospitalPlngGrantMethodology",
                        il_links(il_arch("hfs_rhtp"), IL_HFS_SCOPE))))
})

test_that("the archive against itself is quiet", {
  expect_length(il_hfs_findings(il_arch("hfs_rhtp"), il_arch("hfs_rhtp"),
                                hfs_txt, hfs_txt), 0L)
  expect_length(il_gov_findings(il_arch("gov_press"), il_arch("gov_press"),
                                il_arch("gov_sitemap"), il_arch("gov_sitemap")), 0L)
  expect_silent(rhtp_assert_no_new_organisations(
    live = hfs_txt, archived = hfs_txt, state = "IL", page = "hfs_rhtp"))
  expect_gt(length(il_sitemap_slugs(il_arch("gov_sitemap"))), 1000L)
  expect_gte(length(il_press_headlines(il_arch("gov_press"))), 10L)
})

test_that("a Planning Grant roster LINK on the HFS page trips", {
  html <- sub("Hospital Planning Grant Methodology (pdf)</a>",
              paste0("Hospital Planning Grant Methodology (pdf)</a> ",
                     "<a href=\"/content/dam/soi/en/web/hfs/info/fedresctr/",
                     "RHTPPlanningGrantAwardees.pdf\">Planning Grant Awardees</a>"),
              il_html("hfs_rhtp"), fixed = TRUE)
  expect_false(identical(html, il_html("hfs_rhtp")))
  live_txt <- rhtp_watch_reduce(html, IL_HFS_SCOPE)
  f <- il_hfs_findings(html, il_arch("hfs_rhtp"), live_txt, hfs_txt)
  expect_true(any(grepl("NEW LINK", f) & grepl("RHTPPlanningGrantAwardees", f)))
})

test_that("a planning-grant award sentence and a new figure trip", {
  live <- paste(hfs_txt, "Planning grants have been awarded to 88 hospitals",
                "totaling $25,520,000.")
  f <- il_hfs_findings(il_arch("hfs_rhtp"), il_arch("hfs_rhtp"), live, hfs_txt)
  expect_true(any(grepl("NEW award sentence", f)))
  expect_true(any(grepl("NEW currency figure", f) & grepl("25,520,000", f)))
  # the methodology's own eligibility wording is NOT an award sentence
  expect_length(rhtp_watch_new_sentences(
    paste(hfs_txt, "Using these criteria, 97 out of 198 Illinois hospitals are",
          "eligible to apply."), hfs_txt, IL_AWARD_SENTENCE), 0L)
})

test_that("a hospital named on the HFS page trips the name tripwire", {
  live <- paste(hfs_txt, "Recipients include Lawrence County Memorial Hospital.")
  expect_error(rhtp_assert_no_new_organisations(
    live = live, archived = hfs_txt, state = "IL", page = "hfs_rhtp"),
    "Lawrence County Memorial Hospital")
})

test_that("a new RHTP story on the Governor's newsroom trips, an unrelated one does not", {
  sm <- paste(readLines(il_arch("gov_sitemap"), warn = FALSE), collapse = "\n")
  add <- function(slug) sub("</urlset>", paste0(
    "<url><loc>", IL_GOV_HOST, "/", slug, "</loc></url></urlset>"), sm, fixed = TRUE)
  rhtp <- charToRaw(add("gov-pritzker-announces-rural-health-transformation-planning-grants-for-88-hospitals"))
  other <- charToRaw(add("gov-pritzker-announces-new-state-park-trail"))
  f <- il_gov_findings(il_arch("gov_press"), il_arch("gov_press"), rhtp,
                       il_arch("gov_sitemap"))
  expect_true(any(grepl("GOV_SITEMAP", f) & grepl("planning-grants", f)))
  expect_length(il_gov_findings(il_arch("gov_press"), il_arch("gov_press"),
                                other, il_arch("gov_sitemap")), 0L)

  press <- sub("</body>", paste0(
    "<a href=\"/gov-pritzker-rhtp\">Gov. Pritzker Announces Rural Health ",
    "Transformation Planning Grants</a></body>"), il_html("gov_press"), fixed = TRUE)
  f2 <- il_gov_findings(press, il_arch("gov_press"), il_arch("gov_sitemap"),
                        il_arch("gov_sitemap"))
  expect_true(any(grepl("GOV_PRESS: NEW RHTP headline", f2)))
})
