#!/usr/bin/env Rscript
# 03bs_al_year2_probe.R ------------------------------------------------------
#
# ALABAMA -- A WATCH ON THE ELEVENTH INITIATIVE (session 84). Alabama's Year 1
# is COMPLETE (R/03aw): two Governor's releases, 172 grants, $198,539,348,
# the second saying the round-2 grants "round out year one of funding". Ten of
# ARHTP's eleven initiatives are funded. The eleventh, COMMUNITY MEDICINE
# (mobile wellness screening and mobile grocery units), is NOT a Year 1
# remainder:
#
#   * ADECA Program Manual (proposed final, 2026-09-08), section 10.10:
#     "$5M over 4 years (begins program Year 2 / 2027; no Year 1 funding)".
#   * ADECA's June 2026 roadshow deck: "The Community Medicine Initiative is
#     not budgeted in Year 1 of Program".
#   * alabamarhtp.com lists ten closed Year 1 NOFOs and none for it.
#
# The revised Project Narrative's "$7.3M for year 1" (Table XIV-J1, Revised
# 4.10.2026) is the earlier document and is internally inconsistent (its Year
# 1 figure exceeds its own 3-year total). All three are archived under
# data/evidence/AL/.
#
# IT IS A SUBAWARD ROUND, NOT A STATE PROCUREMENT, and that is why it is
# watched. Stage 1 of its milestone table reads "Procure mobile wellness
# units", but the same verb opens initiatives ADECA then GRANTED (EMS
# Treat-in-Place, "Procure materials/equipment"; EHR, "Procure infrastructure
# & service contracts"). The narrative's own metric table (XIX-10) settles
# who procures: "Number of mobile wellness units procured ... Quarterly
# reporting FROM SUBAWARDEES". The awardees buy the units with the grant.
# Eligible entities are "community organizations, healthcare providers, and
# local leaders" -- hospitals AMONG OTHERS, so a roster is coded one award at
# a time on the RECIPIENT (§0.3, §0.3a), never on the class.
#
# WEEKLY, because Alabama has published no Year 2 date. Alabama awards through
# the GOVERNOR'S newsroom (both Year 1 rosters were Governor's releases), and
# solicits through alabamarhtp.com's NOFO list.
#
# THE WATCH, READ-ONLY (§2.2):
#   * resources -- the NOFO list. Name-diffed (§2.3). TRIPS if "Year 1
#     initiative application periods are now closed." goes (Year 2 has
#     opened: read which NOFOs) or a NEW sentence speaks of Community
#     Medicine, mobile wellness/grocery units, or awards.
#   * home, adeca -- name-diffed; TRIP on the same new-sentence pattern.
#   * governor -- the Governor's newsroom index, the AWARD channel. NOT
#     name-diffed (an index moves weekly, §2.3); TRIPS on any NEW dated
#     headline about the Rural Health Transformation Program (diffed by
#     headline, not sentence: see al_governor_headlines()). The 10-01 ARHTP
#     headline is in the baseline, so only a new one can fire.
#
# §0.1 CONTROL, RECORDED SO IT IS NOT MISREAD: ADECA's own newsroom is a
# stream of named, priced Governor's grants (CDBG, ARC, Coverdell) that are
# not RHTP. It is not watched; a grant there is not this programme.
#
# Usage: Rscript R/03bs_al_year2_probe.R --fetch | --validate | --probe

suppressPackageStartupMessages({ library(dplyr); library(stringr) })
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))

AL_STATE <- "AL"
AL_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                   "+https://www.aha.org)")
AL_DIR <- file.path("data", "evidence", "AL")
AL_PAGES <- tibble::tribble(
  ~key, ~url, ~file, ~name_diff,
  "resources", "https://alabamarhtp.com/resources/",
  file.path(AL_DIR, "2026-10-02_al_rhtp_resources.html"), TRUE,
  "home", "https://alabamarhtp.com/",
  file.path(AL_DIR, "2026-10-02_al_rhtp_home.html"), TRUE,
  "adeca", "https://adeca.alabama.gov/alruralhealth/",
  file.path(AL_DIR, "2026-10-02_adeca_alruralhealth.html"), TRUE,
  "governor", "https://governor.alabama.gov/newsroom/",
  file.path(AL_DIR, "2026-10-02_governor_newsroom_index.html"), FALSE)

AL_ANCHOR <- "Year 1 initiative application periods are now closed."
AL_WATCH_WORDS <- paste0("\\bcommunity medicine\\b|\\bmobile (wellness|grocery|",
                         "market|screening)\\b|\\baward(s|ed|ee|ees)?\\b|",
                         "\\brecipients?\\b|\\bgrantees?\\b|\\bselected\\b")
AL_GOVERNOR_WORDS <- paste0("\\brural health transformation\\b|\\barhtp\\b|",
                            "\\bcommunity medicine\\b")

# THE GOVERNOR'S INDEX IS DIFFED BY HEADLINE, NOT BY SENTENCE (10-08). The
# index has no full stops between items, so the reduced page is one long
# "sentence": any new headline at all made the whole page a new sentence, and
# it still carried the 10-01 ARHTP headline, so the first Routine firing
# (2026-10-08 14:42Z) tripped on a storm declaration and a flag notice. Each
# item opens with its date ("10.1.2026 Governor Ivey Announces ..."), so the
# page is split there and only an ARHTP item absent from the archive fires.
al_governor_headlines <- function(text) {
  items <- stringr::str_split(text, "(?=\\b\\d{1,2}\\.\\d{1,2}\\.20\\d{2} )")[[1]]
  items <- stringr::str_squish(substr(items, 1, 160))
  items[stringr::str_detect(items, stringr::regex("^\\d{1,2}\\.\\d{1,2}\\.20\\d{2} ")) &
          stringr::str_detect(items, stringr::regex(AL_GOVERNOR_WORDS,
                                                    ignore_case = TRUE))]
}

al_new_governor_headlines <- function(live, arch) {
  setdiff(al_governor_headlines(live), al_governor_headlines(arch))
}

al_assert_watch <- function(live, arch) {
  rhtp_watch_require(live$resources, AL_ANCHOR, AL_STATE, "resources")
  why <- paste("Community Medicine, ARHTP's eleventh initiative, begins in",
               "Year 2 (2027) as a subaward round. Read the page: a NOFO is",
               "Tier 2 and names nobody; an award names recipients, coded one",
               "at a time on the RECIPIENT (§0.3a).")
  for (k in c("resources", "home", "adeca")) {
    rhtp_watch_forbid_new(live[[k]], arch[[k]], AL_WATCH_WORDS, AL_STATE, k,
                          why)
  }
  new_heads <- al_new_governor_headlines(live$governor, arch$governor)
  if (length(new_heads)) {
    stop("[", AL_STATE, "] 'governor' HAS ", length(new_heads), " NEW ARHTP ",
         "HEADLINE(S): ", paste0("\"", rhtp_watch_quote(new_heads), "\"",
                                 collapse = " | "),
         ". A NEW ARHTP headline on the Governor's newsroom, Alabama's award ",
         "channel. Open it and extract any named roster.", call. = FALSE)
  }
  invisible(TRUE)
}

al_fetch <- function() {
  for (i in seq_len(nrow(AL_PAGES))) {
    rhtp_watch_archive(AL_PAGES$url[i], AL_PAGES$file[i], AL_AGENT)
    Sys.sleep(3)
  }
  message("[AL] archived ", nrow(AL_PAGES), " baseline pages to ", AL_DIR, ".")
}

al_validate <- function() {
  arch <- lapply(stats::setNames(AL_PAGES$file, AL_PAGES$key),
                 function(f) rhtp_watch_reduce(here::here(f)))
  al_assert_watch(arch, arch)
  stopifnot(
    grepl(AL_ANCHOR, arch$resources, fixed = TRUE),
    !grepl("Community Medicine", arch$resources, fixed = TRUE),
    str_count(arch$resources, "NOFO For ") == 10L,
    grepl("Rural Health Transformation Program Grants Totaling Nearly $55",
          arch$governor, fixed = TRUE))
  message("[AL] the archive lists ten closed Year 1 NOFOs, none for ",
          "Community Medicine, and carries the Year 1 closure sentence.")
  invisible(TRUE)
}

al_probe <- function() {
  w <- rhtp_watch_pages(AL_PAGES, AL_AGENT)
  al_assert_watch(w$live_all, w$arch_all)
  rhtp_assert_no_new_organisations_across(live = w$live, archived = w$arch,
                                          state = AL_STATE)
  message("[AL] ", paste0(w$changed$key, ": ",
                          ifelse(w$changed$changed, "CHANGED", "UNCHANGED"),
                          collapse = "; "), " -- no Community Medicine NOFO ",
          "or award.")
  invisible(w$changed)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) al_fetch()
  if ("--validate" %in% args) al_validate()
  if ("--probe" %in% args) rhtp_probe_run("AL", al_probe())
  if (!length(args)) message("Usage: --fetch | --validate | --probe")
}
