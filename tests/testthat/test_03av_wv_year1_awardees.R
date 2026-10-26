# test_03av_wv_year1_awardees.R ----------------------------------------------
# Session 54. West Virginia's seven named awards, $6,444,803.

suppressWarnings(suppressMessages(source(here::here("R", "03av_wv_year1_awardees.R"))))
wv <- wv_year1_awardees()

test_that("twenty-eight rows, nineteen priced, $18,804,875, each quoted verbatim from its release", {
  # Session 103: + five rows from the 10-13/10-14 releases ($6,156,458).
  # Session 107: + two WVU Health System rows from the 10-19 release ($3,400,000).
  expect_equal(nrow(wv), 28L)
  expect_equal(sum(!is.na(wv$amount)), 19L)
  expect_equal(sum(wv$amount, na.rm = TRUE), 18804875)
  expect_silent(wv_assert_sources())
})

test_that("CAMC/Vandalia, Cabell Huntington Foundation, Minnie Hamilton, the six 09-30 hospitals and Vandalia Health are the hospital rows", {
  h <- wv[wv$distributed_to_hospital == "Yes", ]
  expect_setequal(unique(h$awardee), c("CAMC/Vandalia Health", "Cabell Huntington Foundation",
                                       "Minnie Hamilton Health Care Center",
                                       WV_INV_ENROL$awardee, "Vandalia Health",
                                       "West Virginia United (WVU) Health System"))
  expect_equal(nrow(h), 14L)   # session 107: + 2 WVU Health System (system parent, LOW)
  expect_equal(sum(h$amount, na.rm = TRUE), 6324000)
  expect_true(all(h$determination_confidence[h$awardee == "West Virginia United (WVU) Health System"] == "LOW"))
  expect_true(all(h$recipient_type == "HOSPITAL_OR_SYSTEM"))
  # The foundation rests on §10.2's named-parent row, a reading -> LOW.
  expect_equal(h$determination_confidence[h$awardee == "Cabell Huntington Foundation"], "LOW")
})

test_that("the WVU nursing school is UNIVERSITY_OR_AHC and not a hospital dollar", {
  n <- wv[wv$awardee == "WVU Medicine Center for Nursing Education", ]
  expect_equal(n$recipient_type, "UNIVERSITY_OR_AHC")
  expect_equal(n$distributed_to_hospital, "No")
})

test_that("Ascend WV's '$2.4 million' is flagged rounded; Spotted Owl is not promoted", {
  a <- wv[wv$awardee == "Ascend WV", ]
  expect_equal(a$flag_reason, "AMOUNT_ROUNDED_IN_SOURCE")
  s <- wv[wv$awardee == "Spotted Owl Healthcare Organization", ]
  expect_equal(s$flag_reason, "RECIPIENT_TYPE_INFERRED")
  expect_equal(s$distributed_to_hospital, "No")
})

test_that("session 85: Minnie Hamilton is typed on its CAH enrolment, CCWV on its FQHC one", {
  m <- wv[wv$awardee == "Minnie Hamilton Health Care Center", ]
  expect_equal(nrow(m), 3L)
  expect_true(all(m$ccn == "511303"))
  expect_true(all(m$cms_enrolment_match == "EXACT_LEGAL_NAME"))
  expect_true(all(m$determination_confidence == "MEDIUM"))
  # One project priced, rounded; two unpriced and never divided (§6.2).
  expect_equal(sum(!is.na(m$amount)), 1L)
  expect_equal(m$flag_reason[!is.na(m$amount)], "AMOUNT_ROUNDED_IN_SOURCE")
  expect_true(all(m$flag_reason[is.na(m$amount)] == "AMOUNT_MISSING"))
  # The enrolment cited is in the archived federal file.
  e <- jsonlite::fromJSON(here::here("data", "evidence", "federal_records",
                                     "2026-09-23", "cms_hosp_enrollments_WV.json"))
  k <- e[["CCN"]] == "511303"
  expect_equal(e[["ORGANIZATION NAME"]][k], "MINNIE HAMILTON HEALTH CARE CENTER INC")
  expect_match(e[["PROVIDER TYPE TEXT"]][k], "CRITICAL ACCESS HOSPITAL")
  c4 <- wv[wv$awardee == "Community Care of West Virginia", ]
  expect_equal(sum(c4$amount), 1103614)
  expect_true(all(c4$recipient_type == "FQHC_OR_RHC" & c4$distributed_to_hospital == "No"))
  expect_false(any(grepl("COMMUNITY CARE OF WEST VIRGINIA", e[["ORGANIZATION NAME"]])))
})

test_that("the committed CSV matches a fresh build", {
  d <- readr::read_csv(WV_CSV, show_col_types = FALSE)
  expect_equal(d$awardee, wv$awardee)
  expect_equal(d$amount, wv$amount)
})


# -- session 55: the probe ---------------------------------------------------

wv_news_arch <- here::here(WV_PROBE_DIR, "2026-09-23_wv_news_index.html")

# The 09-23 baseline predates session 85's two releases, so it carries the
# FIRST FIVE slugs; the later two are known so the live index stays quiet.
wv_slugs_0923 <- unname(WV_SLUG[c("hp", "asc", "hin", "nurs", "chg")])

test_that("the news index reads 30 articles and all five award releases", {
  a <- wv_news_articles(wv_news_arch)
  expect_equal(nrow(a), 30L)
  expect_true(all(wv_slugs_0923 %in% a$slug))
})

test_that("on the archive, 'award' matches EXACTLY the five recorded releases", {
  # The tripwire's premise, measured: no funding-OPPORTUNITY release says
  # "award", so the word separates Tier 3 from Tier 2 on this index today.
  a <- wv_news_articles(wv_news_arch)
  hit <- a$slug[grepl("award", paste(a$headline, a$slug), ignore.case = TRUE)]
  expect_setequal(hit, wv_slugs_0923)
  expect_silent(wv_assert_no_new_award_release(wv_news_arch))
})

test_that("a sixth award release TRIPS, by headline", {
  raw <- paste(readLines(wv_news_arch, warn = FALSE, encoding = "UTF-8"),
               collapse = "\n")
  fake <- paste0('<a href="/article/governor-morrisey-announces-award-mercy-hospital" ',
                 'title="Read article: Governor Morrisey Announces $1 Million Award ',
                 'to Example Rural Hospital">Full Story</a>')
  raw <- sub("</body>", paste0(fake, "</body>"), raw, fixed = TRUE)
  expect_error(wv_assert_no_new_award_release(charToRaw(raw)),
               "NEW AWARD RELEASE")
})

test_that("a reader that finds nothing is refused, not read as silence", {
  expect_error(wv_assert_no_new_award_release(charToRaw("<html><main></main></html>")),
               "the reader, not West Virginia")
})

test_that("both name-diffed pages have a real baseline and are silent on themselves", {
  for (k in WV_PROBE_PAGES$key[WV_PROBE_PAGES$name_diff]) {
    t <- wv_page_text(here::here(WV_PROBE_DIR,
                                 WV_PROBE_PAGES$file[WV_PROBE_PAGES$key == k]))
    expect_gte(length(rhtp_organisation_names(t)), 3L)
    expect_silent(rhtp_assert_no_new_organisations(t, t, "WV", k))
  }
})


# -- session 99: the release the old tripwire missed --------------------------
# -- session 100: and extracted ------------------------------------------------

test_that("an RHTP headline trips whatever its verb; the 09-30 release is now KNOWN", {
  arch <- here::here(WV_PROBE_DIR, "2026-10-12_wv_news_index.html")
  a <- wv_news_articles(arch)
  inv <- WV_SLUG[["inv"]]
  expect_true(inv %in% a$slug)
  # It says "Investments", not "Award" -- the old test could not see it.
  expect_false(grepl("award", paste(a$headline[a$slug == inv], inv), ignore.case = TRUE))
  expect_silent(wv_assert_no_new_award_release(arch))
  # Nothing is held unextracted any more.
  expect_equal(nrow(WV_READ_UNEXTRACTED), 0L)
  # Without its WV_SLUG entry, the widened test trips on it.
  held <- WV_SLUG
  WV_SLUG <<- WV_SLUG[names(WV_SLUG) != "inv"]
  on.exit(WV_SLUG <<- held)
  expect_error(wv_assert_no_new_award_release(arch), "NEW AWARD RELEASE")
  # The USDA WIC grant is excluded with its sentence, never silently.
  expect_true(all(nzchar(WV_NOT_RHTP$why)))
})

test_that("session 100: seven 09-30 rows, none priced, six hospitals typed on CMS WV enrolment", {
  r <- wv[wv$state_source_url == paste0(WV_URL, WV_SLUG[["inv"]]), ]
  expect_equal(nrow(r), 7L)
  expect_true(all(is.na(r$amount)))
  expect_true(all(grepl("AMOUNT_MISSING", r$flag_reason)))
  e <- jsonlite::fromJSON(here::here(WV_INV_ENROL_FILE))
  for (i in seq_len(nrow(WV_INV_ENROL))) {
    x <- WV_INV_ENROL[i, ]
    row <- r[r$awardee == x$awardee, ]
    expect_equal(nrow(row), 1L)
    expect_equal(row$ccn, x$ccn)
    expect_equal(row$cms_enrolment_match, x$match)
    expect_equal(row$determination_confidence,
                 if (x$match == "EXACT_LEGAL_NAME") "MEDIUM" else "LOW")
    # The CCN is in the archived enrolment file, typed a hospital or CAH.
    k <- e[["CCN"]] == x$ccn
    expect_equal(sum(k), 1L)
    expect_match(e[["PROVIDER TYPE TEXT"]][k], "HOSPITAL")
    expect_true(startsWith(x$cms_org, e[["ORGANIZATION NAME"]][k]))
  }
  # Vandalia Health: a system parent, no enrolment under that name. Session
  # 101's owner ruling types it a hospital at $0, LOW, general knowledge.
  v <- r[r$awardee == "Vandalia Health", ]
  expect_equal(v$distributed_to_hospital, "Yes")
  expect_equal(v$recipient_type, "HOSPITAL_OR_SYSTEM")
  expect_equal(v$flow_type, "DIRECT")
  expect_equal(v$determination_confidence, "LOW")
  expect_equal(v$basis_type, "GENERAL_KNOWLEDGE")
  expect_true(is.na(v$amount) && is.na(v$ccn))
  expect_false(any(e[["ORGANIZATION NAME"]] == "VANDALIA HEALTH"))
})

test_that("session 104: WVU Eye Institute is NON_HOSPITAL and the other four are not hospitals", {
  eye <- wv[wv$awardee == "West Virginia University (WVU) Eye Institute", ]
  expect_equal(eye$amount, 2000026)
  expect_equal(eye$distributed_to_hospital, "No")
  expect_equal(eye$flow_type, "NON_HOSPITAL")
  expect_equal(eye$recipient_type, "UNIVERSITY_OR_AHC")
  expect_equal(eye$hospital_attribution, "NOT_HOSPITAL")
  expect_true(is.na(eye$ccn))
  s103 <- wv[wv$state_source_url %in% paste0(WV_URL, WV_SLUG[c("phg", "pca", "ars")]), ]
  expect_equal(nrow(s103), 4L)
  expect_true(all(s103$distributed_to_hospital == "No"))
  expect_equal(sum(s103$amount), 4156432)
  ars <- wv[grepl("^Ascension Recovery", wv$awardee), ]
  expect_match(ars$flag_reason, "AMOUNT_ROUNDED_IN_SOURCE")
  expect_match(ars$flag_reason, "RECIPIENT_TYPE_INFERRED")
  expect_false(any(grepl("Lauren", wv$awardee)))
})

test_that("session 103: the name check reads the BODY of a new article, not its headline", {
  idx <- function(slugs, heads) charToRaw(paste0("<html><body>", paste0(
    '<a href="/article/', slugs, '" title="Read article: ', heads, '">Full Story</a>',
    collapse = ""), "</body></html>"))
  held <- idx(paste0("old-", 1:3), paste("Old", 1:3))
  live <- idx(c(paste0("old-", 1:3), "x-investment", "y-flu"),
              c("Old 1", "Old 2", "Old 3", "Governor Announces $9 Million Investment", "Flu Shots"))
  bodies <- list(
    "x-investment" = charToRaw("<html><main><p>Governor Morrisey announced a $9,000,000 Rural Health Transformation Program award to Mountaineer Regional Hospital. More follows.</p></main></html>"),
    "y-flu" = charToRaw("<html><main><p>Get a flu shot at the Kanawha County Health Department.</p></main></html>"))
  f <- wv_new_article_findings(live, held, function(slug) bodies[[slug]])
  expect_length(f, 1L)
  expect_match(f, "x-investment")
  expect_match(f, "Mountaineer Regional Hospital")
  # a recorded release is never re-read
  rec <- idx(c(paste0("old-", 1:3), WV_SLUG[["eye"]]), c("Old 1", "Old 2", "Old 3", "Eye"))
  expect_length(wv_new_article_findings(rec, held, function(slug) stop("fetched")), 0L)
})
