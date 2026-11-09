# 09b_fsrs_award_source.R ------------------------------------------------------
# Session 116c. FSRS / FFATA FIRST-TIER SUBAWARDS AS AN AWARD SOURCE.
#
# OWNER RULING (2026-11-09). A state's FFATA first-tier subaward report in
# FSRS / SAM.gov, republished by USAspending under Assistance Listing 93.798, is
# an AWARD SOURCE: the state's own federal filing of executed subawards. Source
# type FSRS_FFATA, amount type award, budget_period 1 unless the record shows
# otherwise.
#
# WHAT THIS SCRIPT DOES, IN ORDER
#   1. READS the archive R/09a fetched (data/raw/usaspending/<as_of>/), never the
#      live API.
#   2. AMENDMENT RULE (CLAUDE.md §7, "FSRS subawards: one current amount per
#      subaward"). USAspending carries no amendment field and no "cumulative"
#      flag. A subaward is keyed (prime state, subaward_number, subawardee UEI).
#        * Records under one key that agree on action date, amount AND
#          description are ONE subaward reported more than once (a re-filing):
#          the latest-modified report is kept, the others are
#          REFILING_SUPERSEDED. 9 of 2,025 records (DE 1, SD 7, TN 1).
#        * Records under one key that differ in amount or description are
#          DISTINCT ACTIONS, and each amount is PER-ACTION, never a cumulative
#          restatement. Evidence: subaward numbers are reused as recipient names
#          (Iowa) or master agreements across recipients (KY, OH, NE, IN), and
#          the one key a state roster prices independently -- Vermont's
#          03400-BMH1-RHT04-FY27, Brattleboro Memorial Hospital, $115,000 and
#          $270,250 on the same date -- appears on AHS's executed list as two
#          lines at exactly those amounts (vt_year1_awardees.csv rows 70, 71).
#          Two keys repeat a description with a different amount and no roster
#          says which reading holds (UT 251693879, USBE $3,188,804 then
#          $13,085,562; TN 342027, UNHS $723,048.98 and $45,190.56): both are
#          kept per-action and carried in fsrs_amendment_uncertain.csv. Neither
#          is a hospital.
#   3. DATE TEST (§6.2). A record dated before 2025-12-29 (the NOA) is
#      PREDATES_NOA, quarantined, never written: Montana's eight $30,000
#      area-agency-on-aging lines dated 2023-07-01, described "III,VII,SHIP".
#   4. ALLOTMENT CHECK. Per state: count, total, total / FY2026 allotment. A
#      state whose current FSRS total exceeds its allotment is REFUSED (stop).
#   5. RECONCILES each current subaward to the award files (STATE_FILES):
#        (a) recipient on a PRICED row: the state's amount stands; the row gets
#            fsrs_amount and fsrs_match (EXACT / DIFFERS / NOT_FOUND).
#        (b) recipient on a $0 row only: the row is PRICED from FSRS
#            (validation_source_type = FSRS_FFATA; the original source kept in
#            original_validation_source_type and amount_basis).
#        (c) recipient in no file: a NEW row in data/reference/<st>_fsrs_awardees.csv,
#            typed on CMS Hospital Enrollment (name, then street address).
#      Matching is the normalised name (+ DBA) within the state, or a
#      HAND-REVIEWED entry in config/fsrs_name_crosswalk.csv. No fuzzy match is
#      ever applied by machine: a recipient with a token-overlap candidate in
#      the state's files and no crosswalk entry is HELD_CANDIDATE_UNREVIEWED and
#      written nowhere, because adding it could count one subaward twice.
#   6. --apply writes the overlay onto every award file and the new files.
#      A rebuild of any award file WIPES the overlay: re-run
#      `Rscript R/09b_fsrs_award_source.R --apply` after every --build and the
#      other overlays, and BEFORE `R/07_summary_calls.R --apply` (which stays
#      last).
#
# FSRS CANNOT SHOW STATE PROCUREMENT CONTRACTS (2 CFR 170 App. A), and 19 states
# had filed no FFATA subaward at all when this archive was pulled. Silence is a
# fact about the state's filing, never about its awards (§0.4).
#
# CLI
#   Rscript R/09b_fsrs_award_source.R --validate   # rule, totals, refusals; writes nothing
#   Rscript R/09b_fsrs_award_source.R --plan       # data/reference/fsrs_*.csv (dispositions, totals, reconciliation)
#   Rscript R/09b_fsrs_award_source.R --apply      # overlay + new <st>_fsrs_awardees.csv files
#   Rscript R/09b_fsrs_award_source.R --strip      # remove the overlay (restore $0 rows) -- for a clean re-plan
#   Rscript R/09b_fsrs_award_source.R --report

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))
source(here::here("R", "09a_usaspending_rhtp.R"))

FSRS_AS_OF   <- USA_AS_OF
FSRS_NOA     <- "2025-12-29"
FSRS_BP1_END <- "2026-10-30"
FSRS_SOURCE_TYPE <- "FSRS_FFATA"
FSRS_VALIDATOR <- "R/09b_fsrs_award_source.R"
FSRS_HOLD_USD <- 25e6     # owner: hold a state whose new-ruling hospital dollars exceed this
FSRS_DIFFERS_REPORT_USD <- 1e5

FSRS_CROSSWALK <- "config/fsrs_name_crosswalk.csv"
FSRS_PAIRINGS  <- "config/fsrs_subaward_pairings.csv"
FSRS_OUT <- list(
  records   = "data/reference/fsrs_subaward_records.csv",
  totals    = "data/reference/fsrs_state_totals.csv",
  recon     = "data/reference/fsrs_reconciliation.csv",
  differs   = "data/reference/fsrs_differs_over_100k.csv",
  held      = "data/reference/fsrs_held.csv",
  uncertain = "data/reference/fsrs_amendment_uncertain.csv",
  nonfilers = "data/reference/fsrs_nonfiling_states.csv",
  pools     = "data/reference/fsrs_pool_reconciliation.csv",
  ia_rounds = "data/reference/fsrs_ia_round_check.csv"
)
FSRS_NEW_FILE <- function(st) file.path("data", "reference", paste0(tolower(st), "_fsrs_awardees.csv"))
FSRS_OVERLAY_COLS <- c("fsrs_amount", "fsrs_match", "fsrs_subaward_ids",
                       "original_validation_source_type", "original_amount_basis", "original_flag_reason")

# SESSION 116d, OWNER RULING (e): a SOURCE_SUSPECT amount that FSRS confirms to
# the dollar is cleared. Nevada's FLEX-28 prints $997,361 under "Northern Nevada
# Regional Hospital" (Sparks); FSRS pays exactly $997,361 to PHC-Elko, Inc.,
# the operator of NORTHEASTERN Nevada Regional Hospital (Elko). The amount was
# never the defect; the hospital's name was. Cleared only on an EXACT pair.
FSRS_SUSPECT_CONFIRMED <- tibble::tibble(file_key = "NV", awardee = "Northern Nevada Regional Hospital",
                                         amount = 997361)

# -- 1. the records ------------------------------------------------------------

fsrs_raw <- function(as_of = FSRS_AS_OF) {
  usa_read("sub", as_of) %>%
    dplyr::transmute(
      st = dplyr::if_else(prime_awardee_state_code == "",
                          prime_award_primary_place_of_performance_state_code,
                          prime_awardee_state_code),
      prime_award_fain, prime_awardee_name,
      fsrs_id = subaward_sam_report_id,
      report_ym = sprintf("%s-%02d", subaward_sam_report_year,
                          suppressWarnings(as.integer(subaward_sam_report_month))),
      last_modified = subaward_sam_report_last_modified_date,
      subaward_number, action_date = subaward_action_date,
      amount = as.numeric(subaward_amount),
      uei = subawardee_uei, name = stringr::str_squish(subawardee_name),
      dba = stringr::str_squish(subawardee_dba_name),
      parent = stringr::str_squish(subawardee_parent_name),
      address = stringr::str_squish(subawardee_address_line_1),
      city = stringr::str_squish(subawardee_city_name),
      sub_state = subawardee_state_code, zip = subawardee_zip_code,
      business_types = subawardee_business_types,
      description = stringr::str_squish(subaward_description),
      permalink = usaspending_permalink
    )
}

#' The amendment rule: every record with its disposition
fsrs_dispose <- function(raw = fsrs_raw()) {
  r <- raw %>%
    dplyr::group_by(st, subaward_number, uei, action_date, amount, description) %>%
    dplyr::arrange(dplyr::desc(last_modified), dplyr::desc(fsrs_id), .by_group = TRUE) %>%
    dplyr::mutate(refiling_rank = dplyr::row_number(),
                  kept_id = dplyr::first(fsrs_id)) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(record_status = dplyr::case_when(
      refiling_rank > 1 ~ "REFILING_SUPERSEDED",
      action_date < FSRS_NOA ~ "PREDATES_NOA",
      TRUE ~ "CURRENT"))
  # distinct actions under one key (per-action amounts)
  k <- r %>% dplyr::filter(record_status != "REFILING_SUPERSEDED") %>%
    dplyr::group_by(st, subaward_number, uei) %>%
    dplyr::mutate(actions_under_key = dplyr::n(),
                  same_desc_diff_amount = dplyr::n() > 1 &
                    dplyr::n_distinct(description) < dplyr::n()) %>%
    dplyr::ungroup() %>%
    dplyr::select(fsrs_id, actions_under_key, same_desc_diff_amount)
  r %>% dplyr::left_join(k, by = "fsrs_id") %>%
    dplyr::mutate(actions_under_key = dplyr::coalesce(actions_under_key, 0L),
                  same_desc_diff_amount = dplyr::coalesce(same_desc_diff_amount, FALSE),
                  budget_period = dplyr::if_else(action_date > FSRS_BP1_END, 2L, 1L)) %>%
    dplyr::select(-refiling_rank) %>%
    dplyr::arrange(st, subaward_number, uei, action_date)
}

fsrs_current <- function(rec = fsrs_dispose()) {
  rec %>% dplyr::filter(record_status == "CURRENT")
}

# -- 2. per-state totals against the allotment -----------------------------------

fsrs_state_totals <- function(rec = fsrs_dispose()) {
  allot <- readr::read_csv(here::here("data/reference/cms_fy2026_allotments.csv"),
                           show_col_types = FALSE, progress = FALSE) %>%
    dplyr::transmute(st = state, state_name, allotment = fy2026_allotment)
  cur <- rec %>% dplyr::filter(record_status == "CURRENT")
  t <- cur %>% dplyr::group_by(st) %>%
    dplyr::summarise(subawards = dplyr::n(), fsrs_total = round(sum(amount), 2),
                     recipients = dplyr::n_distinct(uei),
                     last_report_modified = substr(max(last_modified), 1, 10), .groups = "drop")
  drop <- rec %>% dplyr::filter(record_status != "CURRENT") %>% dplyr::group_by(st) %>%
    dplyr::summarise(records_not_current = dplyr::n(),
                     usd_not_current = round(sum(amount), 2), .groups = "drop")
  out <- allot %>% dplyr::left_join(t, by = "st") %>% dplyr::left_join(drop, by = "st") %>%
    dplyr::mutate(subawards = dplyr::coalesce(subawards, 0L),
                  records_not_current = dplyr::coalesce(records_not_current, 0L),
                  files_ffata = subawards > 0,
                  pct_of_allotment = dplyr::if_else(files_ffata, round(100 * fsrs_total / allotment, 1), NA_real_),
                  as_of = FSRS_AS_OF) %>%
    dplyr::arrange(dplyr::desc(dplyr::coalesce(fsrs_total, 0)))
  over <- out %>% dplyr::filter(files_ffata, fsrs_total > allotment)
  if (nrow(over)) {
    stop("[fsrs] REFUSED: FSRS total exceeds the FY2026 allotment in ",
         paste0(over$st, " ($", format(over$fsrs_total, big.mark = ","), " vs $",
                format(over$allotment, big.mark = ","), ")", collapse = "; "),
         ". Re-read the records (re-filings, cumulative restatements) before any is used.",
         call. = FALSE)
  }
  out
}

# -- 3. the award files ------------------------------------------------------------

fsrs_state_files <- function() {
  tf <- readLines(here::here("tests/testthat/test_state_union.R"))
  i0 <- grep("^STATE_FILES <- c\\(", tf)
  i1 <- i0 + which(grepl("^\\)", tf[(i0 + 1):length(tf)]))[1]
  eval(parse(text = paste(tf[i0:i1], collapse = "\n")))
  STATE_FILES
}

fsrs_norm <- function(x) {
  x <- toupper(dplyr::coalesce(x, ""))
  x <- gsub("&", " AND ", x, fixed = TRUE)
  x <- gsub("\\(.*?\\)", " ", x)
  x <- gsub("[^A-Z0-9 ]", " ", x)
  x <- gsub("\\b(INC|LLC|THE|CORP|CORPORATION|CO|LTD|PLLC|PC|PA|INCORPORATED|DBA)\\b", " ", x)
  stringr::str_squish(x)
}

fsrs_read_file <- function(path) {
  readr::read_csv(here::here(path), col_types = readr::cols(.default = "c"),
                  na = c("", "NA"), progress = FALSE)
}

#' Every award row of the given states (the overlay columns removed, so a re-plan
#' sees the files as their builders left them)
fsrs_award_rows <- function(states, files = fsrs_state_files()) {
  keys <- names(files)[!grepl("_FSRS$", names(files))]
  dplyr::bind_rows(lapply(keys, function(k) {
    d <- fsrs_strip_overlay(fsrs_read_file(files[[k]]))
    d <- d[d$state %in% states, , drop = FALSE]
    if (!nrow(d)) return(NULL)
    tibble::tibble(file_key = k, file = files[[k]], state = d$state, row_no = d$row_no,
                   awardee = d$awardee, amount = suppressWarnings(as.numeric(d$amount)),
                   award_pool = if ("award_pool" %in% names(d)) d$award_pool else NA_character_,
                   notice_date = if ("notice_date" %in% names(d)) d$notice_date else NA_character_,
                   round_amount = if ("round_amount" %in% names(d)) suppressWarnings(as.numeric(d$round_amount)) else NA_real_,
                   distributed_to_hospital = d$distributed_to_hospital,
                   validation_source_type = d$validation_source_type)
  })) %>% dplyr::mutate(n = fsrs_norm(awardee), row_id = paste(file_key, row_no, sep = "#"))
}

# -- 4. candidate generator (for the HELD rule only; never matches) ---------------

FSRS_GENERIC_TOKENS <- c("OF", "AND", "COUNTY", "HEALTH", "CENTER", "CENTERS", "SERVICES",
  "HOSPITAL", "MEDICAL", "MEMORIAL", "REGIONAL", "COMMUNITY", "CARE", "SYSTEM",
  "DEPARTMENT", "DISTRICT", "FOR", "RURAL", "NORTH", "SOUTH", "EAST", "WEST", "STATE",
  "UNIVERSITY", "FOUNDATION", "ASSOCIATION", "EMS", "FAMILY", "CLINIC", "HEALTHCARE",
  "CITY", "TOWN", "DEPT", "AT", "IN", "ON", "NEW")
fsrs_tokens <- function(x) setdiff(unique(strsplit(fsrs_norm(x), " ")[[1]]), c("", FSRS_GENERIC_TOKENS))

fsrs_candidates <- function(cur, aw) {
  u <- cur %>% dplyr::distinct(st, uei, name, dba)
  out <- list()
  for (i in seq_len(nrow(u))) {
    a <- aw %>% dplyr::filter(state == u$st[i]) %>% dplyr::distinct(file_key, awardee)
    if (!nrow(a)) next
    t1 <- unique(c(fsrs_tokens(u$name[i]), fsrs_tokens(u$dba[i])))
    if (!length(t1)) next
    ov <- vapply(a$awardee, function(z) length(intersect(t1, fsrs_tokens(z))), 1L)
    den <- vapply(a$awardee, function(z) min(length(t1), max(1L, length(fsrs_tokens(z)))), 1L)
    sc <- ov / den
    k <- which(ov >= 1 & (sc >= 0.99 | (sc >= 0.5 & ov >= 2)))
    if (length(k)) out[[length(out) + 1]] <- tibble::tibble(
      st = u$st[i], uei = u$uei[i], fsrs_name = u$name[i],
      file_key = a$file_key[k], awardee = a$awardee[k], score = round(sc[k], 2))
  }
  dplyr::bind_rows(out)
}

fsrs_crosswalk <- function() {
  x <- readr::read_csv(here::here(FSRS_CROSSWALK), col_types = readr::cols(.default = "c"),
                       na = c("", "NA"), progress = FALSE)
  bad <- setdiff(x$decision, c("MATCH", "NO_MATCH", "HOLD"))
  if (length(bad)) stop("[fsrs] crosswalk decision must be MATCH, NO_MATCH or HOLD: ",
                        paste(bad, collapse = ", "), call. = FALSE)
  if (any(x$decision == "MATCH" & (is.na(x$file_key) | is.na(x$awardee)))) {
    stop("[fsrs] a MATCH crosswalk entry needs file_key and awardee.", call. = FALSE)
  }
  if (any(is.na(x$reviewer))) stop("[fsrs] every crosswalk entry needs a reviewer.", call. = FALSE)
  x
}

# -- 5. Iowa: programme pairing ---------------------------------------------------
# Iowa's 264 rows sit in ten RFP pools, a hospital often in several, and FSRS
# carries one subaward per hospital per programme. The FSRS description names
# the programme and the action date separates the two rounds of the two
# Best and Brightest programmes (first-round notices 2026-01-30 / 02-27; second
# round 2026-06-18). A subaward is paired only to rows in its own pool.
FSRS_IA_FAMILY <- function(desc, action_date) {
  late <- action_date >= "2026-06-18"
  dplyr::case_when(
    grepl("EQUIPMENT", desc) ~ ifelse(late, "PHTHORC26011", "PHTHORC26009"),
    grepl("CENTERS OF EXCELLENCE", desc) ~ "PHTHORC26008",
    grepl("CANCER HUB AND SPOKE|CANCER HUB", desc) ~ "PHTHOCC26756",
    grepl("SCREENI", desc) ~ "PHTHOCC26755",
    grepl("IOWA CANCER SERVICE PROVIDERS", desc) ~ "COMPADM26001",
    grepl("ADVISORY EXPERTISE", desc) ~ "COMPADM26002",
    grepl("RURAL IOWA SERVICE PROVIDERS", desc) ~ "COMPADM26003",
    TRUE ~ ifelse(late, "PHTHORC26012", "PHTHORC26010"))
}

# -- 6. reconciliation ---------------------------------------------------------------

#' One row per current subaward: its status and the award rows it touches; plus the
#' per-row overlay.
fsrs_reconcile <- function(rec = fsrs_dispose(), files = fsrs_state_files()) {
  cur <- fsrs_current(rec)
  states <- sort(unique(cur$st))
  aw <- fsrs_award_rows(states, files)
  xw <- fsrs_crosswalk()
  cand <- fsrs_candidates(cur, aw)
  cur <- cur %>% dplyr::mutate(nn = fsrs_norm(name), nd = fsrs_norm(dba))

  # recipient -> award rows (exact normalised name/DBA, or a reviewed MATCH)
  link <- dplyr::bind_rows(
    cur %>% dplyr::select(fsrs_id, st, nn) %>%
      dplyr::inner_join(aw %>% dplyr::select(state, n, row_id), by = c(st = "state", nn = "n"), relationship = "many-to-many") %>%
      dplyr::transmute(fsrs_id, row_id, how = "EXACT_NAME"),
    cur %>% dplyr::filter(nzchar(nd)) %>% dplyr::select(fsrs_id, st, nd) %>%
      dplyr::inner_join(aw %>% dplyr::select(state, n, row_id), by = c(st = "state", nd = "n"), relationship = "many-to-many") %>%
      dplyr::transmute(fsrs_id, row_id, how = "EXACT_DBA"),
    cur %>% dplyr::select(fsrs_id, st, uei) %>%
      dplyr::inner_join(xw %>% dplyr::filter(decision == "MATCH") %>%
                          dplyr::select(state, subawardee_uei, file_key, awardee),
                        by = c(st = "state", uei = "subawardee_uei"), relationship = "many-to-many") %>%
      dplyr::inner_join(aw %>% dplyr::select(state, file_key, awardee, row_id),
                        by = c(st = "state", "file_key", "awardee"), relationship = "many-to-many") %>%
      dplyr::transmute(fsrs_id, row_id, how = "CROSSWALK")
  ) %>% dplyr::distinct(fsrs_id, row_id, .keep_all = TRUE)
  # SESSION 116d: subaward-level pairings found by the independent check (same
  # amount to the cent, same recipient under another name). A pairing replaces
  # every other link of that subaward.
  pr <- readr::read_csv(here::here(FSRS_PAIRINGS), col_types = readr::cols(.default = "c"), progress = FALSE)
  pl <- pr %>% dplyr::mutate(amt = as.numeric(amount)) %>% dplyr::select(-amount) %>%
    dplyr::inner_join(aw %>% dplyr::select(state, file_key, awardee, row_id, amount),
                      by = c("state", "file_key", "awardee"), relationship = "many-to-many") %>%
    # max_diff: a hand-read rounding gap (TX Moore County $221,976 vs $221,980.30)
    dplyr::filter(abs(amount - amt) < dplyr::coalesce(suppressWarnings(as.numeric(max_diff)), 0.005)) %>%
    dplyr::distinct(fsrs_id, .keep_all = TRUE)
  miss <- setdiff(pr$fsrs_id, pl$fsrs_id)
  if (length(miss)) stop("[fsrs] pairings whose roster row (same awardee, same amount) is not found: ",
                         paste(miss, collapse = ", "), call. = FALSE)
  link <- link %>% dplyr::filter(!fsrs_id %in% pl$fsrs_id) %>%
    dplyr::bind_rows(pl %>% dplyr::transmute(fsrs_id, row_id, how = "PAIRING"))
  # a crosswalk entry naming an awardee that is not in its file is a stale entry
  xm <- xw %>% dplyr::filter(decision == "MATCH") %>%
    dplyr::anti_join(aw, by = c(state = "state", "file_key", "awardee"))
  if (nrow(xm)) stop("[fsrs] crosswalk MATCH entries whose awardee is not in the file: ",
                     paste(xm$state, xm$file_key, xm$awardee, sep = "/", collapse = "; "), call. = FALSE)

  # Iowa: keep only links inside the subaward's own pool
  ia <- cur %>% dplyr::filter(st == "IA") %>%
    dplyr::transmute(fsrs_id, ia_pool = FSRS_IA_FAMILY(description, action_date))
  link_all <- link
  link <- link %>% dplyr::left_join(ia, by = "fsrs_id") %>%
    dplyr::left_join(aw %>% dplyr::select(row_id, award_pool, file_key), by = "row_id") %>%
    dplyr::filter(is.na(ia_pool) | file_key != "IA" | award_pool == ia_pool) %>%
    dplyr::select(fsrs_id, row_id, how)

  # connected components of subawards and rows
  comp <- fsrs_components(link)
  status <- list(); overlay <- list()
  for (cid in unique(comp$comp)) {
    ids <- comp$fsrs_id[comp$comp == cid]; rids <- unique(link$row_id[link$fsrs_id %in% ids])
    S <- cur %>% dplyr::filter(fsrs_id %in% ids) %>% dplyr::arrange(dplyr::desc(amount))
    R <- aw %>% dplyr::filter(row_id %in% rids) %>% dplyr::arrange(file_key, as.integer(row_no))
    P <- R %>% dplyr::filter(!is.na(amount) & amount > 0)
    Z <- R %>% dplyr::filter(is.na(amount) | amount == 0)
    s_left <- S$fsrs_id
    P$paired <- rep(FALSE, nrow(P))
    # (a) exact-amount pairs
    for (i in seq_len(nrow(P))) {
      hit <- S$fsrs_id[S$fsrs_id %in% s_left & abs(S$amount - P$amount[i]) < 0.005]
      if (length(hit)) {
        overlay[[length(overlay) + 1]] <- tibble::tibble(row_id = P$row_id[i], fsrs_amount = P$amount[i],
          fsrs_match = "EXACT", fsrs_subaward_ids = hit[1], priced = FALSE)
        status[[length(status) + 1]] <- tibble::tibble(fsrs_id = hit[1], status = "MATCHED_PRICED_EXACT", row_ids = P$row_id[i])
        s_left <- setdiff(s_left, hit[1]); P$paired[i] <- TRUE
      }
    }
    Prem <- P %>% dplyr::filter(!paired)
    Sl <- S %>% dplyr::filter(fsrs_id %in% s_left)
    if (nrow(Prem)) {
      if (nrow(Sl)) {
        fa <- round(sum(Sl$amount), 2)
        overlay[[length(overlay) + 1]] <- tibble::tibble(row_id = Prem$row_id, fsrs_amount = fa,
          fsrs_match = "DIFFERS", fsrs_subaward_ids = paste(Sl$fsrs_id, collapse = ";"), priced = FALSE)
        status[[length(status) + 1]] <- tibble::tibble(fsrs_id = Sl$fsrs_id, status = "MATCHED_PRICED_DIFFERS",
          row_ids = paste(Prem$row_id, collapse = ";"))
        s_left <- character(0)
      } else {
        overlay[[length(overlay) + 1]] <- tibble::tibble(row_id = Prem$row_id, fsrs_amount = NA_real_,
          fsrs_match = "NOT_FOUND", fsrs_subaward_ids = NA_character_, priced = FALSE)
      }
    }
    Sl <- S %>% dplyr::filter(fsrs_id %in% s_left)
    if (nrow(Sl)) {
      if (!nrow(Z)) {
        status[[length(status) + 1]] <- tibble::tibble(fsrs_id = Sl$fsrs_id,
          status = "HELD_EXTRA_SUBAWARD_RECIPIENT_ON_ROSTER", row_ids = paste(R$row_id, collapse = ";"))
      } else {
        # (b) price $0 rows. One subaward set -> the first $0 row of the recipient
        # (in each Iowa pool, the first row of that hospital in that pool); the
        # sibling $0 rows of the same recipient point at the priced row and stay $0.
        grp <- if (all(R$file_key == "IA")) {
          Sl %>% dplyr::mutate(g = FSRS_IA_FAMILY(description, action_date))
        } else Sl %>% dplyr::mutate(g = "ALL")
        for (g in unique(grp$g)) {
          sg <- grp %>% dplyr::filter(g == !!g)
          zg <- if (g == "ALL") Z else Z %>% dplyr::filter(award_pool == g)
          if (!nrow(zg)) {
            status[[length(status) + 1]] <- tibble::tibble(fsrs_id = sg$fsrs_id,
              status = "HELD_EXTRA_SUBAWARD_RECIPIENT_ON_ROSTER", row_ids = paste(R$row_id, collapse = ";"))
            next
          }
          files_z <- unique(zg$file_key)
          if (length(files_z) > 1) {
            status[[length(status) + 1]] <- tibble::tibble(fsrs_id = sg$fsrs_id,
              status = "HELD_ZERO_ROWS_IN_SEVERAL_FILES", row_ids = paste(zg$row_id, collapse = ";"))
            next
          }
          tot <- round(sum(sg$amount), 2)
          overlay[[length(overlay) + 1]] <- tibble::tibble(row_id = zg$row_id[1], fsrs_amount = tot,
            fsrs_match = "PRICED_FROM_FSRS", fsrs_subaward_ids = paste(sg$fsrs_id, collapse = ";"), priced = TRUE)
          if (nrow(zg) > 1) overlay[[length(overlay) + 1]] <- tibble::tibble(row_id = zg$row_id[-1],
            fsrs_amount = NA_real_, fsrs_match = paste0("FSRS_PRICED_ON_ROW_", zg$row_no[1]),
            fsrs_subaward_ids = paste(sg$fsrs_id, collapse = ";"), priced = FALSE)
          status[[length(status) + 1]] <- tibble::tibble(fsrs_id = sg$fsrs_id, status = "PRICED_ZERO_ROW",
            row_ids = zg$row_id[1])
        }
      }
    }
  }
  st_df <- dplyr::bind_rows(status)
  ov <- dplyr::bind_rows(overlay)
  dupr <- ov %>% dplyr::count(row_id) %>% dplyr::filter(n > 1)
  if (nrow(dupr)) stop("[fsrs] a row received two overlay entries: ", paste(dupr$row_id, collapse = ", "), call. = FALSE)

  # unmatched subawards: NEW_ROW, or HELD where an unreviewed candidate exists
  reviewed <- xw %>% dplyr::distinct(state, subawardee_uei) %>% dplyr::mutate(reviewed = TRUE)
  candu <- cand %>% dplyr::distinct(st, uei) %>% dplyr::mutate(has_candidate = TRUE)
  hold <- xw %>% dplyr::filter(decision == "HOLD") %>% dplyr::distinct(state, subawardee_uei) %>%
    dplyr::mutate(hold = TRUE)
  un <- cur %>% dplyr::filter(!fsrs_id %in% link$fsrs_id) %>%
    dplyr::left_join(candu, by = c("st", "uei")) %>%
    dplyr::left_join(reviewed, by = c(st = "state", uei = "subawardee_uei")) %>%
    dplyr::left_join(hold, by = c(st = "state", uei = "subawardee_uei")) %>%
    dplyr::mutate(status = dplyr::case_when(
                    fsrs_id %in% link_all$fsrs_id ~ "HELD_EXTRA_SUBAWARD_RECIPIENT_ON_ROSTER",
                    dplyr::coalesce(hold, FALSE) ~ "HELD_REVIEWED_AMBIGUOUS",
                    dplyr::coalesce(has_candidate, FALSE) & !dplyr::coalesce(reviewed, FALSE) ~ "HELD_CANDIDATE_UNREVIEWED",
                    TRUE ~ "NEW_ROW")) %>%
    dplyr::left_join(link_all %>% dplyr::group_by(fsrs_id) %>%
                       dplyr::summarise(row_ids = paste(unique(row_id), collapse = ";"), .groups = "drop"),
                     by = "fsrs_id") %>%
    dplyr::select(fsrs_id, status, row_ids)
  st_df <- dplyr::bind_rows(st_df, un)
  if (anyDuplicated(st_df$fsrs_id)) stop("[fsrs] a subaward received two statuses.", call. = FALSE)
  if (!setequal(st_df$fsrs_id, cur$fsrs_id)) stop("[fsrs] a current subaward has no status.", call. = FALSE)
  recon <- cur %>% dplyr::select(-nn, -nd) %>% dplyr::left_join(st_df, by = "fsrs_id") %>%
    dplyr::left_join(cand %>% dplyr::group_by(st, uei) %>%
                       dplyr::summarise(candidates = paste(unique(paste0(file_key, ": ", awardee)), collapse = " | "),
                                        .groups = "drop"), by = c("st", "uei"))
  list(recon = recon, overlay = ov, aw = aw, candidates = cand)
}

fsrs_components <- function(link) {
  if (!nrow(link)) return(tibble::tibble(fsrs_id = character(0), comp = integer(0)))
  ids <- unique(link$fsrs_id); comp <- stats::setNames(seq_along(ids), ids)
  repeat {
    changed <- FALSE
    m <- link %>% dplyr::mutate(c = comp[fsrs_id]) %>% dplyr::group_by(row_id) %>%
      dplyr::mutate(cm = min(c)) %>% dplyr::ungroup()
    for (i in seq_len(nrow(m))) {
      if (comp[m$fsrs_id[i]] > m$cm[i]) {
        old <- comp[m$fsrs_id[i]]; comp[comp == old] <- m$cm[i]; changed <- TRUE
      }
    }
    if (!changed) break
  }
  tibble::tibble(fsrs_id = names(comp), comp = unname(comp))
}

# -- 7. typing a new row ----------------------------------------------------------

fsrs_enrolment <- function(states) {
  fs <- list.files(here::here("data/evidence/federal_records"),
                   "^cms_hosp_enrollments_[A-Z]{2}\\.json$", recursive = TRUE, full.names = TRUE)
  st <- sub("^cms_hosp_enrollments_([A-Z]{2})\\.json$", "\\1", basename(fs))
  fs <- fs[st %in% states]; st <- st[st %in% states]
  latest <- tapply(fs, st, function(x) sort(x, decreasing = TRUE)[1])
  dplyr::bind_rows(lapply(names(latest), function(s) {
    j <- jsonlite::fromJSON(latest[[s]])
    tibble::tibble(state = s, file = sub(paste0(here::here(), "/"), "", latest[[s]]),
                   org = j$`ORGANIZATION NAME`, dba = dplyr::coalesce(j$`DOING BUSINESS AS NAME`, ""),
                   ccn = stringr::str_pad(j$CCN, 6, pad = "0"), type = j$`PROVIDER TYPE TEXT`,
                   address = toupper(stringr::str_squish(j$`ADDRESS LINE 1`)),
                   city = toupper(stringr::str_squish(j$CITY)))
  })) %>% dplyr::mutate(n_org = fsrs_norm(org), n_dba = fsrs_norm(dba), n_addr = fsrs_addr(address))
}

fsrs_addr <- function(x) {
  x <- toupper(dplyr::coalesce(x, ""))
  x <- gsub("[^A-Z0-9 ]", " ", x)
  x <- gsub("\\b(STREET)\\b", "ST", x); x <- gsub("\\b(AVENUE)\\b", "AVE", x)
  x <- gsub("\\b(ROAD)\\b", "RD", x); x <- gsub("\\b(DRIVE)\\b", "DR", x)
  x <- gsub("\\b(BOULEVARD)\\b", "BLVD", x); x <- gsub("\\b(HIGHWAY)\\b", "HWY", x)
  x <- gsub("\\bNORTH\\b", "N", x); x <- gsub("\\bSOUTH\\b", "S", x)
  x <- gsub("\\bEAST\\b", "E", x); x <- gsub("\\bWEST\\b", "W", x)
  stringr::str_squish(x)
}

#' Type the NEW rows: CMS enrolment by exact name (MEDIUM) or exact street address
#' and city (LOW, a bridge); otherwise the shared classifier on the name, and for
#' its fallback the subrecipient's SAM business types as carried on the state's
#' own FFATA report (STATE_SOURCE, MEDIUM).
fsrs_type_new <- function(new) {
  enr <- fsrs_enrolment(unique(new$st))
  out <- list()
  for (s in unique(new$st)) {
    d <- new %>% dplyr::filter(st == s)
    cls <- rhtp_classify_records(d %>% dplyr::mutate(awardee = name, .desc = description), s, ".desc")
    e <- enr %>% dplyr::filter(state == s)
    for (i in seq_len(nrow(d))) {
      n <- fsrs_norm(d$name[i]); nd <- fsrs_norm(d$dba[i]); ad <- fsrs_addr(d$address[i])
      hit_name <- e %>% dplyr::filter(n_org == n | n_dba == n | (nzchar(nd) & (n_org == nd | n_dba == nd)))
      hit_addr <- if (nrow(hit_name)) hit_name[0, ] else
        e %>% dplyr::filter(nzchar(ad), n_addr == ad, city == toupper(d$city[i]))
      bt <- dplyr::coalesce(d$business_types[i], "")
      r <- list(recipient_type = cls$recipient_type[i],
                determination_confidence = cls$determination_confidence[i],
                flow_type = cls$flow_type[i], distributed_to_hospital = cls$distributed_to_hospital[i],
                hospital_benefiting = cls$hospital_benefiting[i], flag_reason = cls$flag_reason[i],
                determination_basis = cls$determination_basis[i],
                basis_type = "STATE_SOURCE", ccn = NA_character_, cms_enrolment_record = NA_character_,
                recipient_type_source = paste0("CLASSIFIER (", cls$classification_rule[i], ") on the FSRS name"),
                typing = "CLASSIFIER", sam_hospital_unenrolled = FALSE)
      state_body <- grepl("STATE GOVERNMENT", bt) &&
        !grepl("HOSPITAL|MEDICAL CENTER|HEALTH SYSTEM", toupper(d$name[i]))
      univ <- grepl("UNIVERSITY|COLLEGE", toupper(d$name[i]))
      r$hold_state_operator <- FALSE; r$recipient_subtype <- NA_character_
      if ((nrow(hit_name) || nrow(hit_addr)) && state_body && !univ) {
        # A state agency that holds a hospital enrolment (Texas DSHS runs the
        # state psychiatric hospitals) is not typed a hospital on that
        # enrolment by machine: that is a new ruling, held.
        r$hold_state_operator <- TRUE
        hit_name <- hit_name[0, ]; hit_addr <- hit_addr[0, ]
      }
      if (identical(r$recipient_type, "HOSPITAL_OR_SYSTEM") && !nrow(hit_name) && !nrow(hit_addr)) {
        # The owner's ruling types new rows ON CMS ENROLMENT. A hospital-shaped
        # name with no enrolment by name or address is not a hospital row
        # (the classifier read "Health Care Authority" as a hospital authority).
        r$recipient_type <- "NONPROFIT_CBO"; r$determination_confidence <- "LOW"
        r$flow_type <- "NON_HOSPITAL"; r$distributed_to_hospital <- "No"; r$hospital_benefiting <- "No"
        r$flag_reason <- "RECIPIENT_TYPE_INFERRED"
        r$determination_basis <- "The FSRS name reads as a hospital but no archived CMS Hospital Enrollment record carries it by name or street address; §8 standing fallback (session 116c: new rows are typed on CMS enrolment)."
        r$sam_hospital_unenrolled <- TRUE
        cls$classification_rule[i] <- "FALLBACK"
      }
      if (nrow(hit_name) || nrow(hit_addr)) {
        h <- if (nrow(hit_name)) hit_name[1, ] else hit_addr[1, ]
        how <- if (nrow(hit_name)) "EXACT" else "ADDRESS"
        recd <- sprintf("%s%s (%s, %s), %s", h$org, ifelse(nzchar(h$dba), paste0(" dba ", h$dba), ""),
                        h$ccn, h$city, h$type)
        r$recipient_type <- "HOSPITAL_OR_SYSTEM"; r$flow_type <- "DIRECT"
        r$distributed_to_hospital <- "Yes"; r$hospital_benefiting <- "Yes"
        r$flag_reason <- NA_character_; r$ccn <- h$ccn; r$cms_enrolment_record <- recd
        r$basis_type <- "ORG_WEBSITE"
        r$determination_confidence <- if (how == "EXACT") "MEDIUM" else "LOW"
        r$typing <- paste0("CMS_", how)
        if (univ) r$recipient_subtype <- "ACADEMIC_HEALTH_CENTER"
        r$recipient_type_source <- paste0("TYPED (session 116c, ", how, "): CMS ", s,
          " Hospital Enrollment (", h$file, ") ", if (how == "EXACT")
            "carries the FSRS subrecipient name as an ORGANIZATION NAME or DBA" else
            "carries the FSRS subrecipient's street address and city (a BRIDGE: the name differs)",
          ": ", recd, ".")
        r$determination_basis <- paste0("§10.2 DIRECT: ", r$recipient_type_source,
          " §0.3a: the recipient is a hospital whatever the activity.")
      } else if (identical(cls$classification_rule[i], "FALLBACK") || r$recipient_type == "NONPROFIT_CBO") {
        m <- fsrs_type_from_sam(bt, d$name[i])
        if (!is.na(m)) {
          r$recipient_type <- m; r$flag_reason <- NA_character_
          r$determination_confidence <- "MEDIUM"
          fl <- rhtp_classify_flow(m, d$description[i])
          r$flow_type <- fl$flow_type; r$distributed_to_hospital <- fl$distributed_to_hospital
          r$hospital_benefiting <- fl$hospital_benefiting
          r$typing <- "SAM_BUSINESS_TYPES"
          r$recipient_type_source <- paste0("TYPED (session 116c, SAM): the subrecipient's SAM business types ",
            "as carried on the state's own FFATA report: '", bt, "'.")
          r$determination_basis <- paste(r$recipient_type_source, fl$flow_basis)
        }
        if (grepl("\\bHOSPITAL\\b", bt) && r$recipient_type != "HOSPITAL_OR_SYSTEM") {
          r$sam_hospital_unenrolled <- TRUE
          r$determination_basis <- paste0(r$determination_basis, " SAM lists HOSPITAL among its business ",
            "types but no archived CMS ", s, " Hospital Enrollment record carries this name or street address, ",
            "so it is not a hospital row (Hardeman precedent, session 103); held for a ruling in ",
            "fsrs_held.csv.")
        }
      } else if (grepl("\\bHOSPITAL\\b", bt) && r$recipient_type != "HOSPITAL_OR_SYSTEM") {
        r$sam_hospital_unenrolled <- TRUE
      }
      r$determination_confidence <- rhtp_confidence_ceiling(r$determination_confidence, r$ccn)
      out[[length(out) + 1]] <- dplyr::bind_cols(d[i, ], tibble::as_tibble(r))
    }
  }
  dplyr::bind_rows(out)
}

#' SAM business types -> §8, for a recipient the name classifier could not type.
#' HOSPITAL alone never types a row (it needs a CMS enrolment).
fsrs_type_from_sam <- function(bt, name) {
  b <- toupper(bt); n <- toupper(name)
  dplyr::case_when(
    grepl("INDIAN TRIBE|TRIBAL GOVERNMENT|TRIBALLY OWNED|ALASKAN NATIVE", b) ~ "TRIBAL_ORG",
    grepl("SCHOOL DISTRICT", b) ~ "SCHOOL_OR_DISTRICT",
    grepl("HIGHER LEARNING|LAND GRANT|EDUCATIONAL INSTITUTION|COMMUNITY COLLEGE", b) |
      grepl("UNIVERSITY|COLLEGE", n) ~ "UNIVERSITY_OR_AHC",
    grepl("US STATE GOVERNMENT|U.S. STATE GOVERNMENT", b) ~ "STATE_AGENCY",
    grepl("COUNTY|CITY|MUNICIPALITY|TOWNSHIP|US LOCAL GOVERNMENT|U.S. LOCAL GOVERNMENT|LOCAL GOVERNMENT OWNED|COUNCIL OF GOVERNMENTS|PLANNING COMMISSION|SPECIAL DISTRICT", b) &
      !grepl("\\bHOSPITAL\\b", b) ~ "LOCAL_GOVT_OR_PUBLIC_HEALTH",
    TRUE ~ NA_character_)
}

# -- 8. the plan --------------------------------------------------------------------

fsrs_plan <- function() {
  rec <- fsrs_dispose()
  tot <- fsrs_state_totals(rec)
  rc <- fsrs_reconcile(rec)
  rc <- fsrs_pool_guard(rc)
  # SESSION 116d, OWNER RULING (d): an extra subaward to a recipient already on
  # a roster, in a programme the roster does not list, is written as an
  # FSRS_FFATA row (EXTRA_ROW), under the same holds as a new row, and Iowa's
  # are checked against each RFP's published total (fsrs_ia_round_check()).
  rc$recon <- rc$recon %>% dplyr::mutate(status = dplyr::if_else(
    status == "HELD_EXTRA_SUBAWARD_RECIPIENT_ON_ROSTER", "EXTRA_ROW", status))
  new <- rc$recon %>% dplyr::filter(status %in% c("NEW_ROW", "EXTRA_ROW"))
  typed <- fsrs_type_new(fsrs_fill_business_types(new, rec))
  # The owner's hold: hospital dollars on rows that need a NEW ruling (address
  # bridges), per state, above FSRS_HOLD_USD.
  # A NEW row in a state whose files still carry a pool-level figure that names
  # nobody may be money already inside that pool, so it is held: South
  # Dakota's two rounds, Ohio's two shared pools, Oregon's and Washington's
  # unnamed pools, and Indiana's eight GROW regions ($112.4M, against an FSRS
  # total of $100.7M). A row larger than the state's pool figure cannot be
  # inside it and is written.
  wr <- c("NEW_ROW", "EXTRA_ROW")
  typed <- typed %>% dplyr::mutate(status = dplyr::case_when(
    status %in% wr & st %in% names(FSRS_POOL_LEVEL_STATES) &
      amount <= FSRS_POOL_LEVEL_STATES[st] ~ "HELD_STATE_POOL_MAY_CONTAIN",
    status %in% wr & st %in% FSRS_COMPLETE_ROSTER_STATES ~ "HELD_STATE_ROSTER_IS_COMPLETE",
    # An EXTRA subaward in a state whose Year 1 is COMPLETE (R/03aw): the
    # roster already covers that recipient's Year 1 money, so a second FSRS
    # line is most likely the same money at another grain (Utah's UDAF $26.5M
    # and USBE $13.1M would put Utah over its allotment).
    status == "EXTRA_ROW" & st %in% fsrs_complete_states() ~ "HELD_EXTRA_STATE_YEAR1_COMPLETE",
    TRUE ~ status))
  typed <- fsrs_type_extra_from_roster(typed, rc$aw)
  typed <- fsrs_ia_round_check(typed, rc)
  # SESSION 116d (independent check 2d): a new or extra row whose NON-ROUND
  # amount equals, to the cent, an award row already in the same state is held:
  # it is most likely that row under another name. Round amounts ($750,000
  # districts) repeat legitimately and are left to the hand pairings.
  ra <- rc$aw %>% dplyr::filter(!is.na(amount), amount > 0) %>% dplyr::select(state, amount)
  same <- vapply(seq_len(nrow(typed)), function(i) {
    a <- typed$amount[i]
    typed$status[i] %in% c("NEW_ROW", "EXTRA_ROW") && abs(a - round(a, -2)) > 0.005 &&
      any(ra$state == typed$st[i] & abs(ra$amount - a) < 0.005)
  }, logical(1))
  typed$status[same] <- "HELD_SAME_AMOUNT_ON_ROSTER"
  bridge <- typed %>% dplyr::filter(typing == "CMS_ADDRESS") %>% dplyr::group_by(st) %>%
    dplyr::summarise(bridge_usd = sum(amount), .groups = "drop")
  held_states <- bridge$st[bridge$bridge_usd > FSRS_HOLD_USD]
  typed <- typed %>% dplyr::mutate(
    status = dplyr::if_else(typing == "CMS_ADDRESS" & st %in% held_states, "HELD_RULING_OVER_25M", status))
  rc$recon <- rc$recon %>% dplyr::rows_update(typed %>% dplyr::select(fsrs_id, status), by = "fsrs_id")
  list(records = rec, totals = tot, recon = rc$recon, overlay = rc$overlay, aw = rc$aw,
       typed = typed, candidates = rc$candidates, held_states = held_states)
}

# A $0 row that is a member of a pool already counted at pool level is NOT
# priced: pricing it would count the same money twice (once in the pool figure,
# once on the row). That is (i) every member of a summary-call pool
# (R/07 SC_POOLS: IN GROW's eight regions, OK CHW, NC SBHC, GA, OH), and
# (ii) a row carrying a round figure whose FSRS-priced rows would not reach it
# (R/03aw adds a round figure on top of its priced rows unless they reach it:
# SD CCBHC, 7 of 13 at $8.1M against "more than $13 million"). NC's Mobile
# Integrated Health pool is priced: its 36 FSRS lines ($10.22M) reach the $10M
# round figure, so R/03aw drops the round figure and nothing is counted twice.
# A state whose own published subrecipient report already covers its Year 1
# money: a recipient FSRS names and the report does not is almost certainly on
# the report under another name (Nevada: NVHA's BP1 Subrecipient Report, 157
# lines, $175.2M of $179.9M; two FSRS "new" recipients were Mesa View and
# Northeastern Nevada under their operators' names). New rows there are held.
FSRS_COMPLETE_ROSTER_STATES <- c("NV")
FSRS_POOL_LEVEL_STATES <- c(IN = 112400000, OH = 61700000, OR = 26700000, SD = 101182906, WA = 19410000)
FSRS_POOL_FILES <- c("IN_GROW", "OK_CHW", "NC_SBHC", "GA", "OH")
fsrs_pool_guard <- function(rc) {
  ov <- rc$overlay %>% dplyr::left_join(rc$aw %>% dplyr::select(row_id, file_key, award_pool, round_amount, amount),
                                        by = "row_id")
  pool_tot <- rc$aw %>% dplyr::filter(!is.na(round_amount)) %>%
    dplyr::left_join(ov %>% dplyr::filter(priced) %>% dplyr::select(row_id, new_amt = fsrs_amount), by = "row_id") %>%
    dplyr::group_by(file_key, award_pool, round_amount) %>%
    dplyr::summarise(after = sum(dplyr::coalesce(amount, new_amt, 0)), .groups = "drop")
  ov <- ov %>% dplyr::left_join(pool_tot %>% dplyr::select(file_key, award_pool, after),
                                by = c("file_key", "award_pool")) %>%
    dplyr::mutate(block = priced & (file_key %in% FSRS_POOL_FILES |
                                      (!is.na(round_amount) & dplyr::coalesce(after, 0) < round_amount - 0.005)))
  blocked <- ov$fsrs_subaward_ids[ov$block]
  ov <- ov %>% dplyr::mutate(fsrs_match = dplyr::if_else(block, "FSRS_POOL_MEMBER_NOT_PRICED", fsrs_match),
                             priced = priced & !block)
  # siblings that pointed at a blocked row keep their pointer text; harmless
  ids <- unlist(strsplit(blocked, ";"))
  rc$recon <- rc$recon %>% dplyr::mutate(status = dplyr::if_else(fsrs_id %in% ids, "HELD_POOL_MEMBER_COUNTED_AT_POOL_LEVEL", status))
  rc$overlay <- ov %>% dplyr::select(row_id, fsrs_amount, fsrs_match, fsrs_subaward_ids, priced)
  rc
}

fsrs_complete_states <- function() {
  d <- readr::read_csv(here::here("data/reference/year1_completion_status.csv"), show_col_types = FALSE)
  d$state[d$year1_status == "COMPLETE"]
}

#' An EXTRA row is a recipient the roster already types: it takes the typing of
#' its first matched roster row (never a fresh name or SAM reading).
fsrs_type_extra_from_roster <- function(typed, aw) {
  ex <- which(typed$status == "EXTRA_ROW")
  if (!length(ex)) return(typed)
  cols <- c("recipient_type", "distributed_to_hospital", "flow_type", "hospital_benefiting",
            "determination_confidence", "basis_type", "ccn", "recipient_subtype", "flag_reason")
  for (i in ex) {
    rid <- strsplit(typed$row_ids[i], ";")[[1]][1]
    a <- aw[aw$row_id == rid, ]
    f <- fsrs_read_file(a$file[1]); r <- f[f$row_no == a$row_no[1], ]
    for (c in cols) typed[[c]][i] <- if (c %in% names(r)) r[[c]][1] else NA_character_
    if (identical(typed$recipient_type[i], "HOSPITAL_OR_SYSTEM") && identical(typed$distributed_to_hospital[i], "Yes"))
      typed$flow_type[i] <- "DIRECT"
    typed$typing[i] <- "ROSTER_ROW"; typed$sam_hospital_unenrolled[i] <- FALSE; typed$hold_state_operator[i] <- FALSE
    typed$cms_enrolment_record[i] <- NA_character_
    typed$recipient_type_source[i] <- paste0("TYPED (session 116d, ruling d): as the roster row ", rid,
                                             " ('", a$awardee[1], "'), the same recipient.")
    typed$determination_basis[i] <- paste0(typed$recipient_type_source[i], " Roster basis: ",
                                           dplyr::coalesce(if ("determination_basis" %in% names(r)) r$determination_basis[1] else NA_character_, ""))
  }
  typed
}

#' A record whose SAM business types are blank takes them from another record of
#' the same UEI (OHCA files some reports with the field empty).
fsrs_fill_business_types <- function(new, rec) {
  bt <- rec %>% dplyr::filter(!is.na(business_types), nzchar(business_types)) %>%
    dplyr::group_by(uei) %>% dplyr::summarise(bt_fill = dplyr::first(business_types), .groups = "drop")
  new %>% dplyr::left_join(bt, by = "uei") %>%
    dplyr::mutate(business_types = dplyr::if_else(is.na(business_types) | !nzchar(business_types),
                                                  bt_fill, business_types)) %>%
    dplyr::select(-bt_fill)
}

#' OWNER RULING (d): no Iowa RFP may exceed its PUBLISHED total. The total is
#' the notice footer where the footer is that RFP's Tier 2 pool
#' (ia_notice_footers.csv, footer_tier SOLICITATION); the three June notices
#' print the allotment and publish no round total, so they are checked against
#' nothing narrower. Roster rows priced from FSRS plus extra rows in the pool
#' must not pass the total: extras that would are held; a roster that already
#' does stops the build.
fsrs_ia_round_check <- function(typed, rc) {
  ft <- readr::read_csv(here::here("data/reference/ia_notice_footers.csv"), show_col_types = FALSE) %>%
    dplyr::filter(footer_tier == "SOLICITATION") %>% dplyr::distinct(rfp, footer_amount)
  pr <- rc$overlay %>% dplyr::filter(priced) %>%
    dplyr::inner_join(rc$aw %>% dplyr::filter(file_key == "IA") %>% dplyr::select(row_id, award_pool), by = "row_id") %>%
    dplyr::group_by(award_pool) %>% dplyr::summarise(roster = sum(fsrs_amount), .groups = "drop")
  ex <- typed %>% dplyr::filter(st == "IA", status == "EXTRA_ROW") %>%
    dplyr::mutate(pool = FSRS_IA_FAMILY(description, action_date))
  chk <- ft %>% dplyr::left_join(pr, by = c(rfp = "award_pool")) %>%
    dplyr::left_join(ex %>% dplyr::group_by(pool) %>% dplyr::summarise(extra = sum(amount), .groups = "drop"),
                     by = c(rfp = "pool")) %>%
    dplyr::mutate(roster = dplyr::coalesce(roster, 0), extra = dplyr::coalesce(extra, 0))
  bad <- chk %>% dplyr::filter(roster > footer_amount + 0.005)
  if (nrow(bad)) stop("[fsrs] Iowa roster rows priced from FSRS exceed the published total of ",
                      paste(bad$rfp, collapse = ", "), call. = FALSE)
  over <- chk$rfp[chk$roster + chk$extra > chk$footer_amount + 0.005]
  FSRS_IA_ROUND_CHECK <<- chk %>% dplyr::mutate(held = rfp %in% over)
  typed %>% dplyr::mutate(status = dplyr::if_else(
    st == "IA" & status == "EXTRA_ROW" & FSRS_IA_FAMILY(description, action_date) %in% over,
    "HELD_IA_ROUND_TOTAL_EXCEEDED", status))
}
FSRS_IA_ROUND_CHECK <- NULL

#' OWNER RULING (c): a pool counted at pool level is swapped for its members'
#' FSRS amounts only where the members sum to the pool within 1%. Reported here.
fsrs_pool_reconciliation <- function(p) {
  rd <- function(f) fsrs_read_file(f)
  g <- rd("data/reference/in_grow_regional_awardees.csv")
  mem <- p$overlay %>% dplyr::filter(fsrs_match == "FSRS_POOL_MEMBER_NOT_PRICED") %>%
    dplyr::left_join(p$aw %>% dplyr::select(row_id, file_key, award_pool, round_amount), by = "row_id")
  a <- mem %>% dplyr::group_by(file_key, pool = award_pool) %>%
    dplyr::summarise(pool_usd = dplyr::first(round_amount), members_with_fsrs = dplyr::n(),
                     fsrs_usd = sum(fsrs_amount, na.rm = TRUE), .groups = "drop")
  okchw <- 4460162.93
  a$pool_usd[a$file_key == "OK_CHW"] <- okchw
  st_pool <- tibble::tibble(file_key = paste0(names(FSRS_POOL_LEVEL_STATES), " (state)"),
                            pool = "pool-level figures naming no recipient (R/08 pool_level_usd)",
                            pool_usd = unname(FSRS_POOL_LEVEL_STATES))
  held <- p$recon %>% dplyr::filter(status == "HELD_STATE_POOL_MAY_CONTAIN") %>%
    dplyr::group_by(st) %>% dplyr::summarise(members_with_fsrs = dplyr::n(), fsrs_usd = sum(amount), .groups = "drop") %>%
    dplyr::mutate(file_key = paste0(st, " (state)"))
  b <- st_pool %>% dplyr::left_join(held %>% dplyr::select(-st), by = "file_key")
  dplyr::bind_rows(a, b) %>%
    dplyr::mutate(gap_usd = round(fsrs_usd - pool_usd, 2), gap_pct = round(100 * gap_usd / pool_usd, 1),
                  decision = dplyr::if_else(!is.na(gap_pct) & abs(gap_pct) <= 1, "SWAP", "HOLD"),
                  as_of = FSRS_AS_OF)
}

fsrs_write_plan <- function(p = fsrs_plan()) {
  readr::write_csv(p$records %>% dplyr::select(-kept_id), here::here(FSRS_OUT$records), na = "")
  readr::write_csv(p$totals, here::here(FSRS_OUT$totals), na = "")
  rc <- p$recon %>% dplyr::left_join(p$typed %>% dplyr::select(fsrs_id, new_recipient_type = recipient_type,
                                                              new_typing = typing, new_ccn = ccn,
                                                              sam_hospital_unenrolled),
                                     by = "fsrs_id") %>%
    dplyr::select(st, fsrs_id, status, row_ids, uei, name, dba, address, city, sub_state, amount, action_date,
                  subaward_number, new_recipient_type, new_typing, new_ccn, sam_hospital_unenrolled,
                  business_types, candidates, description, permalink)
  readr::write_csv(rc, here::here(FSRS_OUT$recon), na = "")
  readr::write_csv(fsrs_differs(p), here::here(FSRS_OUT$differs), na = "")
  readr::write_csv(fsrs_held(p), here::here(FSRS_OUT$held), na = "")
  readr::write_csv(p$records %>% dplyr::filter(same_desc_diff_amount) %>%
                     dplyr::select(st, subaward_number, uei, name, action_date, amount, description, fsrs_id),
                   here::here(FSRS_OUT$uncertain), na = "")
  readr::write_csv(fsrs_nonfilers(p$totals), here::here(FSRS_OUT$nonfilers), na = "")
  pr <- fsrs_pool_reconciliation(p)
  if (any(pr$decision == "SWAP")) stop("[fsrs] a pool reconciles within 1%: implement its swap before writing.", call. = FALSE)
  readr::write_csv(pr, here::here(FSRS_OUT$pools), na = "")
  readr::write_csv(FSRS_IA_ROUND_CHECK, here::here(FSRS_OUT$ia_rounds), na = "")
  message("[fsrs] wrote the plan: ", paste(unlist(FSRS_OUT), collapse = ", "))
  invisible(p)
}

fsrs_differs <- function(p) {
  ov <- p$overlay %>% dplyr::filter(fsrs_match == "DIFFERS") %>%
    dplyr::left_join(p$aw %>% dplyr::select(row_id, state, file_key, row_no, awardee, amount), by = "row_id")
  ov %>% dplyr::group_by(state, file_key, awardee, fsrs_subaward_ids) %>%
    dplyr::summarise(state_rows = dplyr::n(), state_amount = sum(amount), fsrs_amount = dplyr::first(fsrs_amount),
                     .groups = "drop") %>%
    dplyr::mutate(difference = round(fsrs_amount - state_amount, 2)) %>%
    dplyr::filter(abs(difference) > FSRS_DIFFERS_REPORT_USD) %>%
    dplyr::arrange(dplyr::desc(abs(difference)))
}

fsrs_held <- function(p) {
  h1 <- p$recon %>% dplyr::filter(grepl("^HELD", status)) %>%
    dplyr::transmute(st, fsrs_id, status, name, amount, detail = dplyr::coalesce(candidates, row_ids))
  h2 <- p$typed %>% dplyr::filter(sam_hospital_unenrolled, status %in% c("NEW_ROW", "EXTRA_ROW")) %>%
    dplyr::transmute(st, fsrs_id, status = "WRITTEN_NOT_HOSPITAL_SAM_LISTS_HOSPITAL", name, amount,
                     detail = paste0("Typed ", recipient_type, "; SAM business types '", business_types,
                                     "'; no CMS enrolment by name or address. A hospital ruling would move ",
                                     "this amount into the hospital figures."))
  h4 <- p$typed %>% dplyr::filter(hold_state_operator, status %in% c("NEW_ROW", "EXTRA_ROW")) %>%
    dplyr::transmute(st, fsrs_id, status = "WRITTEN_NOT_HOSPITAL_STATE_BODY_HOLDS_HOSPITAL_ENROLMENT", name, amount,
                     detail = paste0("Typed ", recipient_type, ". A state body that holds a CMS hospital enrolment ",
                                     "(it operates state hospitals); typing the subaward a hospital on that enrolment ",
                                     "needs a ruling."))
  h3 <- p$records %>% dplyr::filter(record_status == "PREDATES_NOA") %>%
    dplyr::transmute(st, fsrs_id, status = "PREDATES_NOA", name, amount,
                     detail = paste0("action date ", action_date, " before the NOA (2025-12-29); description '",
                                     description, "'. §6.2 date test: quarantined, never written."))
  dplyr::bind_rows(h1, h2, h4, h3) %>% dplyr::arrange(status, st, dplyr::desc(amount))
}

fsrs_nonfilers <- function(tot) {
  tot %>% dplyr::filter(!files_ffata) %>%
    dplyr::transmute(state = st, state_name, ffata_subawards_filed = 0L,
                     as_of = FSRS_AS_OF,
                     fact = paste0("No FFATA first-tier subaward under Assistance Listing 93.798 (prime FAIN on ",
                                   "USAspending) was on USAspending as of ", FSRS_AS_OF, "."),
                     note = paste("A statement about the state's FFATA filing only, never about its awards (§0.4).",
                                  "FFATA reporting is due by the end of the month after the subaward is made",
                                  "(2 CFR 170 App. A); procurement contracts are never reportable."))
}

# -- 9. apply ---------------------------------------------------------------------

fsrs_strip_overlay <- function(d) {
  if (!"fsrs_match" %in% names(d)) return(d)
  if ("original_flag_reason" %in% names(d)) {
    cf <- !is.na(d$original_flag_reason)
    d$flag_reason[cf] <- d$original_flag_reason[cf]
    d$note[cf] <- sub(" \\[Session 116d, owner ruling e:.*\\]$", "", d$note[cf])
  }
  pr <- !is.na(d$fsrs_match) & d$fsrs_match == "PRICED_FROM_FSRS"
  if (any(pr)) {
    d$amount[pr] <- NA_character_
    d$validation_source_type[pr] <- d$original_validation_source_type[pr]
    if ("amount_basis" %in% names(d)) d$amount_basis[pr] <- d$original_amount_basis[pr]
    if ("amount_confirmed" %in% names(d) && "original_amount_confirmed" %in% names(d)) {
      d$amount_confirmed[pr] <- d$original_amount_confirmed[pr]
    }
  }
  d[, setdiff(names(d), c(FSRS_OVERLAY_COLS, "original_amount_confirmed")), drop = FALSE]
}

fsrs_apply <- function(p = fsrs_plan(), files = fsrs_state_files()) {
  fsrs_write_plan(p)
  keys <- names(files)[!grepl("_FSRS$", names(files))]
  ov <- p$overlay %>% tidyr::separate(row_id, c("file_key", "row_no"), sep = "#", remove = FALSE)
  for (k in keys) {
    d0 <- fsrs_read_file(files[[k]])
    d <- fsrs_strip_overlay(d0)
    st <- unique(d$state)
    o <- ov %>% dplyr::filter(file_key == k)
    if (!any(st %in% p$totals$st[p$totals$files_ffata]) && !nrow(o)) {
      if (!identical(names(d), names(d0))) readr::write_csv(d, here::here(files[[k]]), na = "")
      next
    }
    d$fsrs_amount <- NA_character_; d$fsrs_match <- NA_character_; d$fsrs_subaward_ids <- NA_character_
    d$original_validation_source_type <- NA_character_; d$original_amount_basis <- NA_character_
    d$original_amount_confirmed <- NA_character_
    i <- match(o$row_no, d$row_no)
    if (anyNA(i)) stop("[fsrs] overlay rows not found in ", k, call. = FALSE)
    d$fsrs_amount[i] <- ifelse(is.na(o$fsrs_amount), NA_character_, format(o$fsrs_amount, scientific = FALSE, trim = TRUE, nsmall = 0))
    d$fsrs_match[i] <- o$fsrs_match; d$fsrs_subaward_ids[i] <- o$fsrs_subaward_ids
    pr <- i[o$priced]
    if (length(pr)) {
      d$original_validation_source_type[pr] <- d$validation_source_type[pr]
      d$original_amount_basis[pr] <- if ("amount_basis" %in% names(d)) d$amount_basis[pr] else NA_character_
      d$original_amount_confirmed[pr] <- if ("amount_confirmed" %in% names(d)) d$amount_confirmed[pr] else NA_character_
      d$amount[pr] <- d$fsrs_amount[pr]
      d$validation_source_type[pr] <- FSRS_SOURCE_TYPE
      if ("amount_confirmed" %in% names(d)) d$amount_confirmed[pr] <- "Yes"
      ab <- paste0("PRICED FROM FSRS (session 116c, owner ruling 2026-11-09): the state's own FFATA first-tier ",
                   "subaward report (USAspending, ALN 93.798, archive ", FSRS_AS_OF, "), subaward report id(s) ",
                   d$fsrs_subaward_ids[pr], "; executed subaward, amount as filed. The recipient and the award ",
                   "come from the original source (", d$original_validation_source_type[pr], "), kept in ",
                   "original_validation_source_type and original_amount_basis.")
      if ("amount_basis" %in% names(d)) d$amount_basis[pr] <- ab else d$amount_basis <- replace(rep(NA_character_, nrow(d)), pr, ab)
    }
    d$original_flag_reason <- NA_character_
    sc <- FSRS_SUSPECT_CONFIRMED[FSRS_SUSPECT_CONFIRMED$file_key == k, ]
    for (j in seq_len(nrow(sc))) {
      w <- which(d$awardee == sc$awardee[j] & abs(suppressWarnings(as.numeric(d$amount)) - sc$amount[j]) < 0.005 &
                   d$fsrs_match %in% "EXACT")
      if (length(w) != 1L) stop("[fsrs] ruling (e): ", sc$awardee[j], " is not one EXACT FSRS pair in ", k, call. = FALSE)
      d$original_flag_reason[w] <- d$flag_reason[w]
      fr <- gsub("(^|;)SOURCE_SUSPECT(;|$)", "\\1", d$flag_reason[w])
      fr <- gsub(";+$|^;+", "", gsub(";;+", ";", fr))
      d$flag_reason[w] <- if (nzchar(fr)) fr else NA_character_
      d$note[w] <- paste0(d$note[w], " [Session 116d, owner ruling e: SOURCE_SUSPECT cleared. FSRS pays exactly $",
                          format(sc$amount[j], big.mark = ","), " to PHC-Elko, Inc., which operates Northeastern Nevada ",
                          "Regional Hospital (Elko); the BP1 report's 'Northern Nevada' is the name defect, not the amount.]")
    }
    # NOT_FOUND only means something where the state files FFATA at all
    readr::write_csv(d, here::here(files[[k]]), na = "")
  }
  fsrs_write_new_files(p)
  invisible(p)
}

fsrs_new_rows <- function(p) {
  t <- p$typed %>% dplyr::filter(status %in% c("NEW_ROW", "EXTRA_ROW")) %>% dplyr::arrange(st, dplyr::desc(amount), name)
  t %>% dplyr::group_by(st) %>% dplyr::mutate(row_no = as.character(dplyr::row_number())) %>% dplyr::ungroup() %>%
    dplyr::transmute(
      state = st, row_no, awardee = name, amount = format(amount, scientific = FALSE, trim = TRUE),
      recipient_type, distributed_to_hospital,
      note = paste0("FFATA first-tier subaward filed by ", prime_awardee_name, " under ", prime_award_fain,
                    " (subaward ", subaward_number, ", action date ", action_date, "). Recipient in no award file ",
                    "of this state (session 116c, case c)", ifelse(status == "EXTRA_ROW",
                    paste0(" in this programme; the recipient is on ", row_ids, " for another programme (session 116d, ruling d)"), ""),
                    ". Description as filed: '", stringr::str_trunc(description, 400), "'."),
      recipient_confirmed = "Yes", amount_confirmed = "Yes", fiscal_year = "FY2026 (Year 1)",
      source_document_title = paste0(prime_awardee_name, ", FFATA first-tier subaward report (SAM.gov/FSRS) under ",
                                     prime_award_fain, ", as republished by USAspending (ALN 93.798), subaward report ", fsrs_id),
      state_source_url = permalink, validation_source_type = FSRS_SOURCE_TYPE,
      extraction_method = "DIRECT_TEXT", validator = FSRS_VALIDATOR, ccn = ccn, aha_id = NA_character_,
      rural_designation = NA_character_, reviewer = NA_character_,
      recipient_type_source, determination_confidence, flag_reason,
      award_pool = paste0("FSRS ", prime_award_fain),
      budget_period = as.character(budget_period), flow_type, hospital_benefiting,
      hospital_attribution = rhtp_hospital_attribution(flow_type, distributed_to_hospital, recipient_type, NA_character_),
      intermediary_name = NA_character_, determination_basis,
      amount_basis = paste0("The subaward amount the state filed, per action (session 116c amendment rule: re-filings ",
                            "collapsed, distinct actions kept). An EXECUTED first-tier subaward."),
      basis_type, recipient_subtype, cms_enrolment_record,
      source_archive_path = file.path("data/raw/usaspending", FSRS_AS_OF, USA_ZIP),
      announcement_date = action_date,
      fsrs_subaward_id = fsrs_id, fsrs_subaward_number = subaward_number, fsrs_uei = uei,
      fsrs_address = paste(address, city, sub_state, zip, sep = ", "),
      fsrs_business_types = business_types, fsrs_typing = typing,
      fsrs_sam_hospital_unenrolled = as.character(sam_hospital_unenrolled))
}

fsrs_write_new_files <- function(p) {
  nr <- fsrs_new_rows(p)
  old <- list.files(here::here("data/reference"), "^[a-z]{2}_fsrs_awardees\\.csv$", full.names = TRUE)
  for (f in old) if (!toupper(substr(basename(f), 1, 2)) %in% nr$state) file.remove(f)
  for (s in unique(nr$state)) {
    readr::write_csv(nr %>% dplyr::filter(state == s), here::here(FSRS_NEW_FILE(s)), na = "")
  }
  message("[fsrs] wrote ", nrow(nr), " new rows in ", dplyr::n_distinct(nr$state), " files")
}

fsrs_strip_all <- function(files = fsrs_state_files()) {
  for (k in names(files)[!grepl("_FSRS$", names(files))]) {
    d0 <- fsrs_read_file(files[[k]]); d <- fsrs_strip_overlay(d0)
    if (!identical(d, d0)) readr::write_csv(d, here::here(files[[k]]), na = "")
  }
}

# -- 10. validate / report -------------------------------------------------------

fsrs_validate <- function() {
  rec <- fsrs_dispose()
  stopifnot(nrow(rec) == USA_EXPECT$sub_rows,
            sum(rec$record_status == "REFILING_SUPERSEDED") == 9L,
            sum(rec$record_status == "PREDATES_NOA") == 8L)
  tot <- fsrs_state_totals(rec)   # refuses a state over its allotment
  stopifnot(sum(tot$files_ffata) == USA_EXPECT$sub_states, sum(!tot$files_ffata) == 19L)
  message("[fsrs] amendment rule, date test and allotment check pass: ",
          sum(rec$record_status == "CURRENT"), " current subawards, $",
          format(round(sum(rec$amount[rec$record_status == "CURRENT"]), 2), big.mark = ",", nsmall = 2))
  invisible(TRUE)
}

fsrs_report <- function() {
  r <- readr::read_csv(here::here(FSRS_OUT$recon), show_col_types = FALSE, progress = FALSE)
  print(r %>% dplyr::count(status, wt = NULL) %>% dplyr::left_join(
    r %>% dplyr::group_by(status) %>% dplyr::summarise(usd = sum(amount)), by = "status"))
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) fsrs_validate()
  if ("--plan" %in% args) fsrs_write_plan()
  if ("--apply" %in% args) fsrs_apply()
  if ("--strip" %in% args) fsrs_strip_all()
  if ("--report" %in% args) fsrs_report()
}
