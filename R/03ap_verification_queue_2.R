# 03ap_verification_queue_2.R -------------------------------------------------
# Session 49. INGEST OF THE RETURNED VERIFICATION QUEUE, AND THE THREE POLICY
# CHANGES THAT CAME BACK WITH IT.
#
# `data/reference/verification_queue_2.xlsx` is the consolidated queue -- 399
# rows over 500 committed award rows, 382 organisations, 31 questions, 21
# states -- returned with `verified_type`, `verified_by`, `verified_date` and
# `basis` filled on every row. THE WORKBOOK IS READ-ONLY. Nothing in this file
# writes to it, and a test asserts its SHA-256 has not moved.
#
# THE THREE POLICY CHANGES, AND WHY EACH IS A POLICY AND NOT A ROW EDIT.
#
# 1. §8 GAINS `OTHER`. Thirty-five answers name a form §8 does not carry and
#    that is not a hospital -- a retail pharmacy, a PACE organisation, a
#    non-emergency medical transport company, a workforce investment board, a
#    nursing home, a midwifery practice. §8's standing fallback (NONPROFIT_CBO
#    + LOW + RECIPIENT_TYPE_INFERRED) says the form is UNDETERMINED, and on
#    these rows it is determined and simply outside the list. That is session
#    39's `MANAGED_CARE_ORGANIZATION` condition exactly -- the source states a
#    form §8 does not carry -- and it is answered the same way, by adding a
#    code with its own note rather than by widening an existing one. Like the
#    MCO code it can only keep dollars OUT of the hospital total.
#
# 2. §10.2 GAINS THE HOSPITAL-FOUNDATION ROW. A foundation or affiliated arm of
#    a NAMED hospital or health system is `HOSPITAL_OR_SYSTEM`. This runs
#    ACROSS EVERY COMMITTED STATE FILE and not only the queue, because a
#    foundation nobody queued is the same organisation as one somebody did --
#    Sky Lakes Foundation, the two MercyOne foundations and Incline Village
#    Community Hospital Foundation are all outside the queue's answered set and
#    all inside this rule.
#
#    THE RULE'S LIMIT IS THE WORD *NAMED*, AND IT IS LOAD-BEARING. It reaches a
#    foundation whose own name carries the hospital's -- Sky Lakes, MercyOne
#    North Iowa, Incline Village Community Hospital, St. Bernards, Citizen's
#    Foundation (Citizens Health). It does NOT reach a foundation of an
#    ASSOCIATION of hospitals (Nevada Rural Hospital Partners Foundation, New
#    Hampshire's Foundation for Healthy Communities): those are §10.2's
#    association row, whose test is what the source says the money DOES, and
#    they keep the flow that row gave them. Without that limit the rule would
#    move $66,547,394 of New Hampshire pass-through money into the hospital
#    total on this file's authority, which is the §0.3 failure the project
#    exists to avoid.
#
# 3. GENERAL KNOWLEDGE IS AN ADMISSIBLE BASIS, AND `basis_type` RECORDS WHICH
#    KIND EACH ANSWER IS. §0.4 says a determination without a captured,
#    archived, quotable source is not a determination. That rule was written
#    about the AWARD -- did this recipient receive this money -- and 306 of the
#    399 answers here are about something else: what KIND of organisation the
#    recipient is, which the state's award document does not say and was never
#    going to. Left unamended, §0.4 would read every one of those answers as a
#    violation. `basis_type` is what keeps the two apart, in the data, per row.
#
# THE GUARDRAILS THIS FILE ENFORCES RATHER THAN RELIES ON.
#
#   * MISSOURI'S HUB ANCHORS AND MAINE'S INVITED COHORT NEVER ENTER A HOSPITAL
#     BUCKET. Their types are updated -- the question asked WAS their form --
#     but `mo_hub_anchors.csv` and `me_rhef_cohort.csv` carry no `amount`, no
#     `flow_type` and no `distributed_to_hospital`, are not in `STATE_FILES`,
#     and cannot reach `rhtp_hospital_dollar_partition()` at all. An assertion
#     drives that rather than trusting it.
#   * ANSWERING A `_FLOW` ROW DOES NOT SETTLE ITS FLOW. Four queue rows ask a
#     §10.2 flow question (AR_ARHP_CONSORTIUM_FLOW, MI_MHA_FLOW,
#     ME_UNE_HOSPITAL_TO_HOME_FLOW, NV_INCLINE_VILLAGE_FOUNDATION_FLOW). The
#     answers retype the recipient and nothing more; the flow stays where its
#     own source put it.
#   * THE FLOW TEST IS RE-RUN ON EVERY RE-TYPED ROW -- WITH ONE NAMED
#     EXCEPTION. Salina Regional Health Center's flow was settled in session
#     31, deliberately, by reading what KDHE says the money does, and it stays
#     `IN_KIND_BENEFIT`. See `VQ_FLOW_SETTLED` for why the three rows that look
#     identical to it are NOT treated the same way, and for what it costs.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only -- never |>. No setwd(); all
# paths through here::here(). Contains no network calls.

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(readr)
  library(readxl)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

VQ_WORKBOOK     <- "data/reference/verification_queue_2.xlsx"
VQ_WORKBOOK_SHA <- "3479966eb99bf4dec57051919ab5c44f9ec3a57c9ee22788b1048bcd70e4e0af"
VQ_ANSWERS_CSV  <- "data/reference/verification_queue_2_answers.csv"
VQ_CHANGES_CSV  <- "data/reference/verification_queue_2_changes.csv"
VQ_SHEET        <- "Verification queue"

# The queue's own name for a Florida recipient differs from the committed file's
# by one character: the workbook prints "Empower Health Care" and
# `fl_year1_awardees.csv` has "Empowerq Health Care". ONE ENTRY, HAND-READ, and
# visible here rather than resolved by a fuzzy matcher (§2 forbids that). The
# dollars ($3,204,031.91) and the row count (1) agree on both sides, which is
# what makes the identification safe to make at all.
VQ_NAME_FIXES <- tibble::tribble(
  ~state, ~queue_name,           ~file_name,
  "FL",   "Empower Health Care", "Empowerq Health Care"
)

# -- policy 2: the hospital-foundation row, applied across every state file ----
#
# HAND-READ, ONE ENTRY PER ORGANISATION, WITH THE REASON IN THE ROW. This is a
# list and not a pattern on purpose: `\bfoundation\b` matches 57 rows across
# the committed files and only 9 of them are the arm of a named hospital. The
# other 48 are tribal corporations (Southcentral, Tlingit & Haida), conversion
# foundations (Superior Health), professional-association foundations (MPhA,
# Pharmacy Foundation of Oregon), an FQHC (Cahaba Medical Care Foundation) and
# a hospice's foundation (Talbot). A pattern would take all of them.
VQ_FOUNDATION_OVERRIDES <- tibble::tribble(
  ~state, ~file_name,                                       ~parent_hospital,                          ~why,
  "OR",   "Sky Lakes Foundation (DBA Healthy Klamath)",     "Sky Lakes Medical Center",                "the foundation arm of Sky Lakes Medical Center (Klamath Falls); the DBA is a programme name, not a second organisation",
  "IA",   "MercyOne Genesis Foundation",                    "MercyOne Genesis",                        "the fundraising foundation of MercyOne Genesis, whose own name carries the hospital's",
  "IA",   "MercyOne North Iowa Foundation",                 "MercyOne North Iowa Medical Center",      "the fundraising foundation of MercyOne North Iowa Medical Center (Mason City)",
  "IA",   "MercyOneNorth Iowa Foundation",                  "MercyOne North Iowa Medical Center",      "the same foundation as the row above; Iowa's roster omits a space, and BOTH SPELLINGS ARE KEPT (§2) -- they are two award actions, not one",
  "NV",   "Incline Village Community Hospital Foundation",  "Incline Village Community Hospital",      "the fundraising foundation of Incline Village Community Hospital, a critical access hospital; its name carries the hospital's in full",
  "AR",   "St. Bernards Development Foundation",            "St. Bernards Medical Center",             "the development arm of St. Bernards Healthcare, Jonesboro; the verifier reached the same answer independently",
  "KS",   "Citizen’s Foundation (Citizens Health)",    "Citizens Health (Citizens Medical Center)", "the fundraising arm of Citizens Medical Center, Colby; the parent is NAMED in the awardee string itself"
)

# THE FOUNDATIONS THIS ROW DELIBERATELY DOES NOT REACH, recorded because a
# later session will otherwise re-derive the question and may answer it
# differently. Each is a real foundation with a real hospital connection and
# none is the arm of a NAMED hospital or health system.
VQ_FOUNDATION_REFUSALS <- tibble::tribble(
  ~state, ~file_name,                                    ~why_not,
  "NH",   "Foundation for Healthy Communities (FHC)",    "the foundation of the state HOSPITAL ASSOCIATION, not of a named hospital. It is §10.2's association row and its flow is settled: its eligible class is 'primary care, critical access hospitals, EMS, behavioral health, oral health, and community-based organizations' -- hospitals AMONG OTHERS (§0.3). Moving it would put $66,547,394 into the hospital total on this file's authority.",
  "NV",   "Nevada Rural Hospital Partners Foundation",   "the foundation of an ASSOCIATION of hospitals, not of one named hospital. §10.2's association row already governs it and Nevada's own source put it at IN_KIND_BENEFIT. $0 either way -- Nevada publishes no per-recipient amount.",
  "KS",   "Citizens Foundation",                         "a SECOND, shorter Kansas spelling whose string names no hospital. The verifier answered it NONPROFIT_CBO and said so in the basis: 'Most likely the foundation of Citizens Health (Colby) ... Not confirmed.' Merging it with Citizen's Foundation (Citizens Health) is the fuzzy hospital match §2 forbids, so the two spellings classify differently and $146,476 stays out. North Carolina's two spellings of UNC, in a state that prices its rows.",
  "MS",   "Winston County Medical Foundation",           "NOT IN THE QUEUE AND NOT VERIFIED. Four Mississippi rows, $3,785,455. The name is foundation-shaped and names a COUNTY, not a hospital, and no source in hand says whose arm it is. Promoting it on this pipeline's own knowledge is the §0.4 failure. Queued as MS_FOUNDATION_PARENT_NOT_STATED.",
  "MI",   "Superior Health Foundation",                  "a health CONVERSION foundation that makes grants across the Upper Peninsula; it has no hospital parent. Verified NONPROFIT_CBO.",
  "MD",   "Talbot Hospice Foundation Inc",               "a HOSPICE's foundation. A hospice is not a hospital, so the parent fails the rule's test before the foundation half is reached. Verified OTHER.",
  "WY",   "William H. and Carrie Gottsche Foundation",   "runs the Gottsche rehabilitation and wellness center; the parent is the foundation itself and is not a hospital. Verified NONPROFIT_CBO.",
  "AL",   "Cahaba Medical Care Foundation",              "an FQHC that is incorporated as a foundation. Already typed FQHC_OR_RHC from its federal designation, which is a STRONGER statement than this rule makes."
)

# -- the flow exception, and what it costs ------------------------------------
#
# FOUR RE-TYPED ROWS CARRY `IN_KIND_BENEFIT` TODAY AND ALL FOUR HAVE THE SAME
# GENERATED `determination_basis`: "the recipient is not a hospital and keeps
# the funds, and the source names hospitals among the parties the funded work
# serves." THE FIRST HALF OF THAT SENTENCE IS EXACTLY WHAT THE VERIFICATION
# OVERTURNS, so on three of them the in-kind coding is a CONSEQUENCE of the
# wrong type rather than a reading of the source, and the flow test is re-run.
#
# SALINA REGIONAL IS THE FOURTH AND IS DIFFERENT, because session 31 read it
# individually. Tightening `RHTP_PASS_THROUGH_MARKERS` into a money-movement
# test moved exactly two committed rows, and Salina ($932,310, "infrastructure
# to rural hospitals") was one of them -- a deliberate, recorded judgement
# about where the DOLLAR goes, not a fallback. It stays IN_KIND_BENEFIT.
#
# THE DISTINCTION IS REAL AND IT IS ALSO THIN, AND SAYING SO IS THE POINT: four
# rows share one basis sentence and three move while one does not. The three
# are queued as VQ_INKIND_AFTER_RETYPE so a human can align them either way
# with the sources in hand.
VQ_FLOW_SETTLED <- tibble::tribble(
  ~state, ~file_name,                      ~why,
  "KS",   "Salina Regional Health Center", "flow settled in session 31 by reading KDHE's own words ('infrastructure to rural hospitals'); one of the two rows the money-movement marker moved, and the only one of the four in-kind rows here that was individually re-read"
)


#' Read the returned workbook. READ-ONLY.
vq_read_workbook <- function(path = here::here(VQ_WORKBOOK)) {
  if (!file.exists(path)) {
    stop("The returned verification workbook is not on disk: ", path,
         call. = FALSE)
  }
  suppressMessages(readxl::read_excel(path, sheet = VQ_SHEET,
                                      col_types = "text"))
}


#' Which kind of evidence an answer rests on
#'
#' Three values, derived from the basis TEXT and the row's own state source URL:
#'
#'   STATE_SOURCE       the basis says the STATE'S OWN DOCUMENT states the form
#'                      -- "Alaska's own project organization type is Pharmacy",
#'                      "Listed in Maryland's Pillar 2 award offers", "OHA's own
#'                      organization type is Behavioral Health Clinic".
#'   ORG_WEBSITE        the basis cites a URL that is NOT the state award
#'                      source -- the organisation's own site, its 990, its
#'                      association's directory.
#'   GENERAL_KNOWLEDGE  everything else: a bare assertion, or an assertion with
#'                      the AWARD's URL appended.
#'
#' THE STATE AWARD URL ALONE IS NOT `STATE_SOURCE`, AND THAT IS THE WHOLE
#' DESIGN. 238 of the 399 bases carry a URL whose host is the row's own state
#' source, and on nearly all of them that URL locates the AWARD and says
#' nothing about the recipient's FORM -- which is why the row was in the queue.
#' Calling those STATE_SOURCE would assert the state stated something it did
#' not, which is the §0.4 failure in the column built to prevent it. The
#' workbook's own annotation says the same thing in words on 143 rows: "[Org
#' type from general knowledge; URL is the award source.]"
vq_basis_type <- function(basis, state_source_url) {
  stopifnot(length(basis) == length(state_source_url))
  host <- function(u) {
    stringr::str_remove(
      stringr::str_to_lower(stringr::str_extract(u, "(?<=://)[^/]+")), "^www\\."
    )
  }
  basis <- ifelse(is.na(basis), "", basis)
  urls <- stringr::str_extract_all(basis, "https?://[^\\s\\)\\]]+")
  src  <- host(state_source_url)

  cites_non_state <- vapply(seq_along(basis), function(i) {
    u <- urls[[i]]
    length(u) > 0 && any(!(host(u) %in% src[i]))
  }, logical(1))

  dplyr::case_when(
    # The verifier saying so outright wins over everything else. INERT ON ALL
    # 399 RETURNED ROWS -- measured, not assumed: no basis carrying the
    # annotation also carries a non-state URL, so this branch changes nothing
    # today. It is here because the annotation is the verifier's own statement
    # about their own basis, and a rule that could override it would be
    # deriving basis_type from the wrong thing.
    stringr::str_detect(basis, stringr::regex("general knowledge",
                                              ignore_case = TRUE)) ~ "GENERAL_KNOWLEDGE",
    stringr::str_detect(basis, RHTP_STATE_SOURCE_LANGUAGE) ~ "STATE_SOURCE",
    cites_non_state                                               ~ "ORG_WEBSITE",
    TRUE                                                          ~ "GENERAL_KNOWLEDGE"
  )
}

# The phrasings in which a verifier said the STATE'S OWN document carries the
# form. Deliberately narrow: each one names the publisher and the field. A
# looser rule would sweep in the 238 rows that merely cite the award URL.
RHTP_STATE_SOURCE_LANGUAGE <- stringr::regex(
  paste(c(
    "listed in [A-Z]",
    "award offers",
    "own (project )?organi[sz]ation type",
    "’s own organi", "'s own organi",
    "Pillar [0-9]",
    "names the awardee only",
    "the (notice|roster|release|award list) (says|states|names|publishes|prints)"
  ), collapse = "|"),
  ignore_case = TRUE
)


#' The answers, with basis_type derived and the queue's own keys kept
vq_answers <- function(raw = vq_read_workbook()) {
  raw %>%
    dplyr::mutate(
      classifier_type = stringr::str_trim(
        stringr::str_extract(classifier_assigned, "^[^/]+")),
      classifier_conf = stringr::str_trim(
        stringr::str_extract(classifier_assigned, "[^/]+$")),
      basis_type = vq_basis_type(basis, source_url)
    ) %>%
    dplyr::left_join(VQ_NAME_FIXES, by = c("state", "recipient_name" = "queue_name")) %>%
    dplyr::mutate(
      match_name = dplyr::coalesce(file_name, recipient_name),
      name_fixed = !is.na(file_name)
    ) %>%
    dplyr::select(-file_name)
}


# -- mapping an answer onto the award rows it covers ---------------------------

VQ_NAME_COL <- function(d) if ("awardee" %in% names(d)) "awardee" else "organization"
VQ_CONF_COL <- function(d) {
  if ("determination_confidence" %in% names(d)) "determination_confidence"
  else "recipient_type_confidence"
}

#' Confidence a verified answer supports
#'
#' §7 reserves HIGH for a CCN match, which nothing in this pass has. An answer
#' resting on the state's own document or on the organisation's own website is
#' MEDIUM -- "identity inferred from a source without a CCN match". AN ANSWER
#' RESTING ON GENERAL KNOWLEDGE STAYS LOW, and that is the point of admitting
#' it at all: the code is now determined, the confidence says what it is worth,
#' and Stage 5's CCN match is still what raises it.
vq_confidence <- function(basis_type) {
  dplyr::if_else(basis_type == "GENERAL_KNOWLEDGE", "LOW", "MEDIUM")
}


#' Build the row-level change plan. WRITES NOTHING.
#'
#' One row per (file, row index) that moves, with its old and new values, the
#' reason it moved, and the evidence class behind it.
vq_plan <- function(answers = vq_answers()) {

  files <- sort(unique(answers$source_file))
  tables <- stats::setNames(
    lapply(files, function(f) suppressMessages(
      readr::read_csv(here::here("data/reference", f),
                      col_types = readr::cols(.default = "c"),
                      progress = FALSE))),
    files)

  # -- (a) the queue's own answers --------------------------------------------
  from_queue <- purrr::map_dfr(seq_len(nrow(answers)), function(i) {
    a <- answers[i, ]
    if (identical(a$verified_type, "UNKNOWN")) return(NULL)  # see vq_report()
    d <- tables[[a$source_file]]
    nm <- VQ_NAME_COL(d); cf <- VQ_CONF_COL(d)
    idx <- which(d[[nm]] == a$match_name &
                   d$recipient_type == a$classifier_type &
                   d[[cf]] == a$classifier_conf)
    if (!length(idx)) return(NULL)
    tibble::tibble(
      file = a$source_file, row = idx, state = a$state, name = a$match_name,
      new_type = a$verified_type, basis_type = a$basis_type,
      verified_by = a$verified_by, basis = a$basis,
      rule = "VERIFICATION_ANSWER", queue_code = a$queue_code
    )
  })

  # -- (b) policy 2, which reaches rows no queue row covers --------------------
  fnd_files <- c(OR = "or_year1_awardees.csv", IA = "ia_year1_awardees.csv",
                 NV = "nv_year1_awardees.csv", AR = "ar_year1_awardees.csv",
                 KS = "ks_year1_awardees.csv")
  for (f in setdiff(unname(fnd_files), names(tables))) {
    tables[[f]] <- suppressMessages(readr::read_csv(
      here::here("data/reference", f),
      col_types = readr::cols(.default = "c"), progress = FALSE))
  }
  from_policy2 <- purrr::map_dfr(seq_len(nrow(VQ_FOUNDATION_OVERRIDES)), function(i) {
    o <- VQ_FOUNDATION_OVERRIDES[i, ]
    f <- fnd_files[[o$state]]
    d <- tables[[f]]
    idx <- which(d[["awardee"]] == o$file_name)
    if (!length(idx)) {
      stop("VQ_FOUNDATION_OVERRIDES names a recipient no committed row carries: ",
           o$state, " / ", o$file_name, call. = FALSE)
    }
    tibble::tibble(
      file = f, row = idx, state = o$state, name = o$file_name,
      new_type = "HOSPITAL_OR_SYSTEM", basis_type = "GENERAL_KNOWLEDGE",
      verified_by = "policy 2 (§10.2 hospital-foundation row)",
      basis = paste0("§10.2, hospital foundations and affiliated arms: ",
                     o$why, ". Parent: ", o$parent_hospital, "."),
      rule = "POLICY_2_HOSPITAL_FOUNDATION", queue_code = NA_character_
    )
  })

  plan <- dplyr::bind_rows(from_queue, from_policy2)

  # Policy 2 wins where both reach a row: it is the standing rule, the queue
  # answer is one reviewer's reading of the same organisation, and on every
  # overlapping row here the two agree anyway (St. Bernards, Citizen's
  # Foundation) except Incline Village, where the queue answered the FLOW
  # question's recipient and policy 2 answers the typing question.
  plan <- plan %>%
    dplyr::arrange(file, row, dplyr::desc(rule == "POLICY_2_HOSPITAL_FOUNDATION")) %>%
    dplyr::distinct(file, row, .keep_all = TRUE)

  # -- (c) old values, and the flow decision ----------------------------------
  plan <- purrr::pmap_dfr(plan, function(...) {
    p <- tibble::tibble(...)
    d <- tables[[p$file]]
    cf <- VQ_CONF_COL(d)
    has <- function(x) x %in% names(d)
    old_type <- d$recipient_type[p$row]
    old_conf <- d[[cf]][p$row]
    old_flow <- if (has("flow_type")) d$flow_type[p$row] else NA_character_
    old_dth  <- if (has("distributed_to_hospital")) d$distributed_to_hospital[p$row] else NA_character_
    old_attr <- if (has("hospital_attribution")) d$hospital_attribution[p$row] else NA_character_
    amount   <- if (has("amount")) suppressWarnings(as.numeric(d$amount[p$row])) else NA_real_

    settled <- any(VQ_FLOW_SETTLED$state == p$state &
                     VQ_FLOW_SETTLED$file_name == p$name)

    # THE FLOW TEST IS RE-RUN ONLY WHERE THE RE-TYPE CAN CHANGE ITS ANSWER --
    # that is, across the HOSPITAL_OR_SYSTEM boundary. §10.2's DIRECT row is
    # the one branch keyed on recipient identity; every other branch reads the
    # description, which this pass did not change, so re-running them could
    # only overwrite a state extractor's source-read with the same answer or a
    # worse one.
    crosses <- xor(identical(old_type, "HOSPITAL_OR_SYSTEM"),
                   identical(p$new_type, "HOSPITAL_OR_SYSTEM"))
    new_flow <- old_flow; new_dth <- old_dth; new_attr <- old_attr
    flow_note <- "flow unchanged: the re-type does not cross §10.2's DIRECT test"

    if (crosses && !settled && has("flow_type")) {
      fl <- rhtp_classify_flow(
        p$new_type,
        if (has("note")) d$note[p$row] else "",
        award_made = FALSE
      )
      new_flow <- fl$flow_type
      new_dth  <- fl$distributed_to_hospital
      new_attr <- if (is.na(old_attr)) old_attr else
        rhtp_hospital_attribution(new_flow, new_dth, p$new_type, NA_character_)
      flow_note <- "flow re-run: §10.2 re-applied because the re-type crosses the DIRECT test"
    } else if (crosses && settled) {
      flow_note <- paste0("FLOW HELD: ", VQ_FLOW_SETTLED$why[
        VQ_FLOW_SETTLED$state == p$state & VQ_FLOW_SETTLED$file_name == p$name])
    }

    p %>% dplyr::mutate(
      old_type = old_type, old_conf = old_conf,
      new_conf = vq_confidence(p$basis_type),
      old_flow = old_flow, new_flow = new_flow,
      old_dth = old_dth, new_dth = new_dth,
      old_attr = old_attr, new_attr = new_attr,
      amount = amount, flow_settled_held = settled, flow_note = flow_note
    )
  })

  plan %>%
    dplyr::mutate(
      type_changed = old_type != new_type,
      flow_changed = !is.na(old_flow) & !is.na(new_flow) & old_flow != new_flow,
      bucket_before = vq_bucket(old_flow, old_dth, old_type, old_attr),
      bucket_after  = vq_bucket(new_flow, new_dth, new_type, new_attr)
    ) %>%
    dplyr::arrange(state, file, row)
}

# The partition's own bucket rule, tolerant of the non-award files (which carry
# no flow and no distributed_to_hospital at all, and therefore no bucket).
vq_bucket <- function(flow, dth, rtype, attr) {
  purrr::pmap_chr(list(flow, dth, rtype, attr), function(f, d, r, a) {
    if (is.na(d)) return("NO_BUCKET")
    tryCatch(rhtp_hospital_attribution(f, d, r, a), error = function(e) "NO_BUCKET")
  })
}


# -- the union, before and after ----------------------------------------------

VQ_STATE_FILES <- function() {
  tf <- readLines(here::here("tests/testthat/test_state_union.R"), warn = FALSE)
  i0 <- grep("^STATE_FILES <- c\\(", tf)
  i1 <- i0 - 1L + which(trimws(tf[i0:length(tf)]) == ")")[1]
  eval(parse(text = paste(tf[i0:i1], collapse = "\n")))
}

#' The committed union, in the columns the partition reads
vq_union_for_partition <- function(files = VQ_STATE_FILES()) {
  purrr::map_dfr(unname(files), function(f) {
    d <- suppressMessages(readr::read_csv(here::here(f),
                                          col_types = readr::cols(.default = "c"),
                                          progress = FALSE))
    tibble::tibble(
      state = d$state,
      amount = d$amount,
      distributed_to_hospital = d$distributed_to_hospital,
      recipient_type = d$recipient_type,
      flow_type = if ("flow_type" %in% names(d)) d$flow_type else NA_character_,
      hospital_attribution = if ("hospital_attribution" %in% names(d))
        d$hospital_attribution else NA_character_
    )
  })
}

#' The three buckets over the committed union
vq_partition <- function(files = VQ_STATE_FILES()) {
  rhtp_hospital_dollar_partition(vq_union_for_partition(files))
}

vq_bucket_totals <- function(part) {
  part %>%
    dplyr::group_by(bucket) %>%
    dplyr::summarise(rows = sum(rows), dollars = sum(dollars),
                     states = dplyr::n(), .groups = "drop")
}


# -- the Iowa Centers of Excellence question ----------------------------------

#' Is Iowa's $50,000,000 Centers of Excellence pool hospital-only after this?
#'
#' PHTHORC26008 holds TEN award actions. Eight were already
#' `HOSPITAL_OR_SYSTEM`; two carried §8's standing fallback -- Manning Regional
#' Health Care Center and SIOUX CENTER HEALTH -- and both verify as hospitals.
#'
#' WHAT THAT IS AND IS NOT. It makes the pool's recipient set hospital-only,
#' which is a statement about WHO. It attaches NO dollar to anybody: Iowa
#' publishes no per-recipient amount, and the $50,000,000 is a TIER 2 figure
#' from that notice's CMS footer (`ia_notice_footers.csv`). Dividing it ten ways
#' gives $5,000,000, which is nobody's published figure (§6.2), and adding it to
#' a Tier 3 total is §0.2. The finding is a ROW COUNT and a class, exactly as
#' Nevada's rule requires for a state that prices nobody.
vq_iowa_centers_of_excellence <- function(plan = vq_plan()) {
  ia <- suppressMessages(readr::read_csv(
    here::here("data/reference/ia_year1_awardees.csv"),
    col_types = readr::cols(.default = "c"), progress = FALSE))
  coe <- which(ia$award_pool == "PHTHORC26008")
  moved <- plan %>% dplyr::filter(file == "ia_year1_awardees.csv", row %in% coe)
  after <- ia$recipient_type[coe]
  after[match(moved$row, coe)] <- moved$new_type
  foot <- suppressMessages(readr::read_csv(
    here::here("data/reference/ia_notice_footers.csv"),
    col_types = readr::cols(.default = "c"), progress = FALSE))
  tibble::tibble(
    pool = "PHTHORC26008",
    programme = "Centers of Excellence",
    rows = length(coe),
    hospitals_before = sum(ia$recipient_type[coe] == "HOSPITAL_OR_SYSTEM"),
    hospitals_after = sum(after == "HOSPITAL_OR_SYSTEM"),
    hospital_only = all(after == "HOSPITAL_OR_SYSTEM"),
    tier2_pool_amount = foot$footer_amount[foot$rfp == "PHTHORC26008"],
    tier = foot$footer_tier[foot$rfp == "PHTHORC26008"]
  )
}


# -- writing it back ----------------------------------------------------------

#' Apply the committed verification overlay to ONE state table
#'
#' THIS IS THE FUNCTION THAT KEEPS THE STATE FILES REPRODUCIBLE. Every state
#' extractor rebuilds its CSV from its archived source, and ten tests assert
#' that the rebuild equals the committed file -- which is the invariant that
#' makes every figure in this repository checkable. A verification written
#' straight onto the CSV would break it silently: the next `--build` would wipe
#' 305 answers and no test would say so.
#'
#' So the verification is an OVERLAY, applied after the build, from a committed
#' file (`verification_queue_2_changes.csv`) derived from a committed,
#' SHA-256-pinned workbook. The claim the tests make becomes "the committed CSV
#' is the builder's output WITH the committed overlay applied", which is still
#' a complete reproduction from committed inputs and is now an explicit
#' dependency rather than a silent one.
#'
#' `vq_apply()` calls this, so the two can never drift.
#'
#' @param built A freshly-built state table.
#' @param file The state file's basename, as it appears in the changes CSV.
#' @param plan Defaults to the committed overlay; pass a plan to apply a fresh
#'   one.
vq_overlay <- function(built, file, plan = vq_changes()) {
  pf <- plan %>% dplyr::filter(.data$file == !!file)
  if (!nrow(pf)) return(built)
  d <- built
  cf <- VQ_CONF_COL(d)
  has <- function(x) x %in% names(d)

  if (!"basis_type" %in% names(d)) d$basis_type <- NA_character_
  if (!"verified_by" %in% names(d)) d$verified_by <- NA_character_
  if (!"verified_basis" %in% names(d)) d$verified_basis <- NA_character_

  for (i in seq_len(nrow(pf))) {
    r <- as.integer(pf$row[i])
    d$recipient_type[r] <- pf$new_type[i]
    d[[cf]][r] <- pf$new_conf[i]
    d$basis_type[r] <- pf$basis_type[i]
    d$verified_by[r] <- pf$verified_by[i]
    d$verified_basis[r] <- pf$basis[i]

    if (has("is_hospital_or_system")) {
      d$is_hospital_or_system[r] <-
        if (identical(pf$new_type[i], "HOSPITAL_OR_SYSTEM")) "Yes" else "No"
    }
    # `recipient_type_source` IS DELIBERATELY NOT TOUCHED. Each state file
    # already means something by it, and on Florida it means the OWNER'S
    # ORIGINAL §8 CODE -- session 10's back-fit preserved "UNCLASSIFIED" there
    # precisely so the change stays auditable and reversible, and a test reads
    # it as a bare code. Writing this session's prose into it would destroy
    # that record and change the column from a code to a sentence, one state at
    # a time. The verification's provenance goes in `basis_type` /
    # `verified_by` / `verified_basis`, which are this session's columns.
    if (has("flow_type") && !is.na(pf$new_flow[i])) d$flow_type[r] <- pf$new_flow[i]
    if (has("distributed_to_hospital") && !is.na(pf$new_dth[i]))
      d$distributed_to_hospital[r] <- pf$new_dth[i]
    if (has("hospital_benefiting") && identical(pf$new_dth[i], "Yes"))
      d$hospital_benefiting[r] <- "Yes"
    if (has("hospital_attribution") && !is.na(pf$new_attr[i]))
      d$hospital_attribution[r] <- pf$new_attr[i]

    # §8's standing fallback flag is a claim that the form is UNDETERMINED. It
    # is now determined, so the flag comes off -- its own note in
    # vocabularies.csv forbids leaving it on a recipient whose form is stated.
    if (has("flag_reason")) {
      fr <- d$flag_reason[r]
      if (!is.na(fr)) {
        fr <- paste(setdiff(stringr::str_split(fr, ";")[[1]],
                            "RECIPIENT_TYPE_INFERRED"), collapse = ";")
        d$flag_reason[r] <- if (nzchar(fr)) fr else NA_character_
      }
    }
    if (has("determination_basis")) {
      prior <- d$determination_basis[r]
      # IDEMPOTENT. The overlay is written for a freshly built table, but it is
      # also applied to the committed one by `--apply` and by the tests, and a
      # basis sentence prepended twice is a diff nobody asked for.
      if (!is.na(prior) &&
          startsWith(prior, "RECIPIENT TYPE VERIFIED (session 49)")) next
      d$determination_basis[r] <- paste0(
        "RECIPIENT TYPE VERIFIED (session 49): ", pf$new_type[i],
        ". Basis (", pf$basis_type[i], ", ", pf$verified_by[i], "): ",
        pf$basis[i], " ", pf$flow_note[i], ".",
        if (!is.na(prior) && nzchar(prior))
          paste0(" PRIOR BASIS, kept because the flow half of it may still ",
                 "hold and §2.1 says a correction shows what moved: ", prior)
        else "")
    }
  }
  d
}

#' The committed overlay
vq_changes <- function() {
  suppressMessages(readr::read_csv(here::here(VQ_CHANGES_CSV),
                                   col_types = readr::cols(.default = "c"),
                                   progress = FALSE))
}


#' Apply the plan to the committed state files.
vq_apply <- function(plan = vq_plan()) {
  changed_files <- character(0)
  for (f in sort(unique(plan$file))) {
    path <- here::here("data/reference", f)
    # `trim_ws = FALSE` BECAUSE THE DEFAULT IS NOT ROUND-TRIP SAFE. readr trims
    # leading and trailing whitespace on READ, so writing the same table back
    # silently rewrites every cell that had a trailing space. Wyoming has 49 of
    # them in `note` -- a cosmetic edit to rows this session never planned to
    # touch, which is the churn sessions 23-25 kept catching in the diff.
    d <- suppressMessages(readr::read_csv(path,
                                          col_types = readr::cols(.default = "c"),
                                          trim_ws = FALSE,
                                          progress = FALSE))
    d <- vq_overlay(d, f, plan)
    readr::write_csv(d, path, na = "")
    changed_files <- c(changed_files, f)
  }
  changed_files
}


# -- the report ---------------------------------------------------------------

vq_fmt <- function(x) formatC(x, format = "f", digits = 2, big.mark = ",")

vq_report <- function(plan = vq_plan(), answers = vq_answers()) {
  moved_in  <- plan %>% dplyr::filter(bucket_before == "NOT_HOSPITAL",
                                      bucket_after  != "NOT_HOSPITAL",
                                      bucket_after  != "NO_BUCKET")
  moved_out <- plan %>% dplyr::filter(bucket_before != "NOT_HOSPITAL",
                                      bucket_before != "NO_BUCKET",
                                      bucket_after  == "NOT_HOSPITAL")

  cat("\n================ VERIFICATION QUEUE 2 -- WHAT MOVES ================\n")
  cat("queue rows answered      : ", nrow(answers), "\n", sep = "")
  cat("award rows in the plan   : ", nrow(plan), "  (",
      sum(plan$rule == "VERIFICATION_ANSWER"), " from answers, ",
      sum(plan$rule == "POLICY_2_HOSPITAL_FOUNDATION"), " from policy 2)\n", sep = "")
  cat("recipient_type changed   : ", sum(plan$type_changed), "\n", sep = "")
  cat("flow_type changed        : ", sum(plan$flow_changed, na.rm = TRUE), "\n", sep = "")

  cat("\n-- INTO a hospital bucket --------------------------------------\n")
  cat("rows: ", nrow(moved_in), "   dollars: ", vq_fmt(sum(moved_in$amount, na.rm = TRUE)),
      "   (", sum(is.na(moved_in$amount)), " rows carry no amount at all)\n", sep = "")
  print(as.data.frame(moved_in %>% dplyr::count(bucket_after, name = "rows")), row.names = FALSE)

  cat("\n-- OUT of a hospital bucket ------------------------------------\n")
  cat("rows: ", nrow(moved_out), "   dollars: ", vq_fmt(sum(moved_out$amount, na.rm = TRUE)), "\n", sep = "")
  if (nrow(moved_out)) print(as.data.frame(moved_out %>%
    dplyr::select(state, name, old_type, new_type, amount)), row.names = FALSE)

  by <- function(d, col) d %>% dplyr::group_by(.k = .data[[col]]) %>%
    dplyr::summarise(rows = dplyr::n(),
                     dollars = sum(amount, na.rm = TRUE),
                     unpriced = sum(is.na(amount)), .groups = "drop") %>%
    dplyr::arrange(dplyr::desc(dollars)) %>%
    dplyr::rename(!!col := .k)

  cat("\n-- BY STATE (net into hospital buckets) ------------------------\n")
  net <- dplyr::bind_rows(moved_in %>% dplyr::mutate(amount = amount),
                          moved_out %>% dplyr::mutate(amount = -amount))
  print(as.data.frame(by(net, "state")), row.names = FALSE)

  cat("\n-- BY VERIFIER -------------------------------------------------\n")
  print(as.data.frame(by(net, "verified_by")), row.names = FALSE)

  cat("\n-- BY basis_type -----------------------------------------------\n")
  print(as.data.frame(by(net, "basis_type")), row.names = FALSE)

  cat("\n-- basis_type over ALL 399 answers -----------------------------\n")
  print(as.data.frame(answers %>% dplyr::count(basis_type, verified_by)), row.names = FALSE)

  cat("\n-- IOWA: CENTERS OF EXCELLENCE ---------------------------------\n")
  print(as.data.frame(vq_iowa_centers_of_excellence(plan)), row.names = FALSE)

  cat("\n-- FLOW HELD (the named exception) -----------------------------\n")
  held <- plan %>% dplyr::filter(flow_settled_held)
  print(as.data.frame(held %>% dplyr::select(state, name, old_flow, new_flow, amount)), row.names = FALSE)
  cat("\n-- the three rows that look like it and were NOT held -----------\n")
  ik <- plan %>% dplyr::filter(old_flow == "IN_KIND_BENEFIT", !flow_settled_held,
                               flow_changed)
  print(as.data.frame(ik %>% dplyr::select(state, name, old_flow, new_flow, amount)), row.names = FALSE)

  cat("\n-- GUARDRAILS --------------------------------------------------\n")
  nb <- plan %>% dplyr::filter(file %in% c("mo_hub_anchors.csv", "me_rhef_cohort.csv"))
  cat("Missouri hub anchors + Maine invited cohort: ", nrow(nb),
      " rows re-typed, buckets reached: ",
      paste(unique(nb$bucket_after), collapse = ", "), "\n", sep = "")
  fl <- answers %>% dplyr::filter(stringr::str_detect(queue_code, "_FLOW$"))
  cat("_FLOW queue rows answered: ", nrow(fl),
      " -- flow changed on any? ",
      any(plan$flow_changed[plan$queue_code %in% fl$queue_code], na.rm = TRUE), "\n", sep = "")
  invisible(list(moved_in = moved_in, moved_out = moved_out, plan = plan))
}

vq_totals_report <- function() {
  p <- vq_partition()
  cat("\n-- THE THREE BUCKETS -------------------------------------------\n")
  print(as.data.frame(vq_bucket_totals(p)), row.names = FALSE)
  cat("\nNAMED_HOSPITAL by state:\n")
  print(as.data.frame(p %>% dplyr::filter(bucket == "NAMED_HOSPITAL") %>%
                        dplyr::arrange(dplyr::desc(dollars))), row.names = FALSE)
  invisible(p)
}


if (identical(environment(), globalenv()) &&
    !is.null(args <- commandArgs(trailingOnly = TRUE)) && length(args)) {
  if ("--report" %in% args) { vq_report(); vq_totals_report() }
  if ("--apply"  %in% args) {
    pl <- vq_plan()
    readr::write_csv(vq_answers() %>%
      dplyr::select(queue_row, state, recipient_name, match_name, queue_code,
                    queue_source, direction, dollars_at_stake, award_rows,
                    classifier_assigned, current_coding, verified_type,
                    verified_by, verified_date, basis, basis_type),
      here::here(VQ_ANSWERS_CSV), na = "")
    readr::write_csv(pl, here::here(VQ_CHANGES_CSV), na = "")
    cat("applied to: ", paste(vq_apply(pl), collapse = ", "), "\n")
  }
  if ("--totals" %in% args) vq_totals_report()
}
