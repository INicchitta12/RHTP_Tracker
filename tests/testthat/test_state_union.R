# test_state_union.R ---------------------------------------------------------
# The extracted states must union. Reads committed CSVs off disk only --
# no network, no quota.
#
# WHY THIS FILE EXISTS. Session 10 found Florida and Georgia had given two
# different answers to one §8 question, and the two states could not be combined
# until that was settled. Nothing caught it until someone tried. This file is
# that attempt, run every time: every extracted state shares the leading 19
# columns and every categorical value in them is inside §8, asserted from all
# sides at once.

library(testthat)

source(here::here("R", "utils_config.R"))

STATE_FILES <- c(
  FL = "data/reference/fl_year1_awardees.csv",
  GA = "data/reference/ga_great_health_awards.csv",
  PA = "data/reference/pa_year1_awardees.csv",
  AL = "data/reference/al_year1_awardees.csv",
  AK = "data/reference/ak_year1_awardees.csv",
  # South Dakota is TWO files, because South Dakota published two different
  # kinds of document and they must not be added together: 13 executed
  # ADMINISTRATIVE contracts with named vendors, and two ANNOUNCED ROUNDS
  # ($121.5M) whose recipients the state has never published. Session 12's
  # notes said "all six states union", but SD was never in this list and
  # nothing checked -- which is the same gap, one file later, that this
  # test exists to close.
  SD_CONTRACTS    = "data/reference/sd_rht_contracts.csv",
  SD_ANNOUNCEMENTS = "data/reference/sd_year1_awardees.csv",
  # Illinois is one row and it is the awkward one: the first
  # PASS_THROUGH_DESIGNATED award in the project. Its $50,008,264 is
  # distributed_to_hospital = Yes and names NO hospital, which is a
  # combination no other state file contains and which the test below existed
  # in a form that would have quietly mis-stated.
  IL = "data/reference/il_year1_awardees.csv",
  # Michigan is the only state file whose roster its own publisher calls
  # COMPLETE -- MDHHS "maintains a dedicated webpage featuring all RHTP
  # Subrecipients" -- and the only one where 139 priced awards yield ONE named
  # hospital. It is in this test because that combination is new: a full,
  # amounts-on-every-row roster whose hospital figure is $76,924 and whose
  # largest recipient is the state HOSPITAL ASSOCIATION at $8,625,000, sitting
  # in neither bucket of the partition.
  MI = "data/reference/mi_year1_awardees.csv",
  # Oregon is the widest state file in the project: 278 award actions across
  # SEVEN pools published in FOUR documents, at three different levels of
  # certainty. It is in this test for the reason the test exists -- a state that
  # mixes 35 named hospitals, 99 named clinics, 103 competitive grants, two
  # ranges, two unpriced projects and two pools that name nobody is the state
  # most likely to give §8 a different answer somewhere, and nothing would catch
  # it until someone tried to combine the file with the others.
  OR = "data/reference/or_year1_awardees.csv",
  # Kansas is the first state whose awards came out of PDFs rather than a page
  # or a workbook, and the first whose recipient forms are almost entirely
  # unstated by the publisher: 22 of its 46 rows carry §8's standing fallback.
  # That makes it the state most likely to put a value outside §8 into the
  # union without anyone noticing.
  KS = "data/reference/ks_year1_awardees.csv",
  # Maryland is the first state whose file was parsed out of PDFs the reader
  # could not open at all before session 21 -- and the first whose recipient
  # types are derived from the recipient's own NAME for every single row,
  # because MDH publishes no organisation-type column. That makes it the state
  # most likely to put a name-derived value outside §8 into the union.
  MD = "data/reference/md_year1_awardees.csv",
  # Nebraska is the first state file to carry a THIRD hospital-attribution
  # bucket (POOL_NAMED_HOSPITALS, §8, session 23) and the first to mix priced
  # award rows with deliberately un-priced ones inside a single pool -- the 21
  # hospitals DHHS names as receiving funding through the Nebraska High Value
  # Network, with no per-hospital split published. Both are exactly the kind of
  # thing that unions fine until someone sums a column.
  NE = "data/reference/ne_year1_awardees.csv",
  # Indiana is the first state whose awards are PROCUREMENT CONTRACTS rather
  # than grants, and the first whose recipients contain NO hospital at all --
  # so it is the state most likely to break an invariant that was only ever
  # true because every prior file had at least one hospital row in it. It is
  # also the first to carry a multi-year contract value in `amount`.
  IN = "data/reference/in_year1_awardees.csv",
  # Oklahoma is the first state file to mix a NAMED-recipient roster and a
  # names-not-published aggregate row IN ONE POOL SET -- 68 microgrants with a
  # recipient and an amount each, and one ROOTS row that names nobody and
  # carries an EMPTY amount. South Dakota has the aggregate shape but nothing
  # else; Georgia had it before its roster was found. A file that holds both at
  # once is the one most likely to let a NOT_YET_NAMED row drift into a total.
  OK = "data/reference/ok_year1_awardees.csv",
  # Nevada is the first state file in which `amount` is EMPTY ON EVERY ROW.
  # NVHA publishes a complete, named, recipient-level roster and no dollar
  # figure against any recipient, so Nevada carries 20 named-hospital award
  # actions and $0 of named-hospital dollars at the same time. Every invariant
  # in this file that was only ever true because each state had at least one
  # priced row is one Nevada can break -- which is exactly why it is here.
  NV = "data/reference/nv_year1_awardees.csv",
  # Missouri is the SMALLEST award file in the project -- two rows -- and it is
  # here for what is NOT in it. DSS publishes a named, 27-organisation,
  # recipient-level roster (the ToRCH Care Hub Anchors, 14 of them hospitals)
  # that is a SELECTION TO A GOVERNANCE ROLE with no money attached, and RCJ
  # carries all 27 as Tier 3 awards at $1 each. Those 27 live in
  # `mo_hub_anchors.csv`, which has no `amount` column at all and is
  # deliberately NOT in this union. A future session that "completes" Missouri
  # by folding the roster in would add 14 named hospitals and $0 to the
  # project's headline, which is §0.3 at the scale of a state.
  MO = "data/reference/mo_year1_awardees.csv",
  # New Hampshire is here for the DISTINCTION it draws against Illinois, which
  # is the one §10.2 turns on. Both are executed awards to a designated
  # pass-through administrator with no hospital named. ICAHN codes `Yes` --
  # eligibility restricted to HOSPITALS ONLY, §10.2's second clause met. FHC
  # codes `Unclear` -- its eligible class is, in its own words, "primary care,
  # critical access hospitals, EMS, behavioral health, oral health, and
  # community-based organizations", i.e. hospitals AMONG OTHERS, which is §0.3
  # exactly. Same shape, same tier, opposite codings, and the eligible class is
  # the whole reason.
  NH = "data/reference/nh_year1_awardees.csv",

  # IOWA IS NEVADA'S SHAPE AND THE LARGEST INSTANCE OF IT. Eleven Notices of
  # Intent to Award, ten of them operative, 264 award actions, every recipient
  # NAMED and NOT ONE PRICED -- so it contributes 152 named-hospital award
  # ACTIONS and $0 of named-hospital dollars, and both are true at once. Read
  # the row count: down the dollar column alone Iowa is invisible.
  IA = "data/reference/ia_year1_awardees.csv",

  # MAINE INVERTS THE PAIRING NEVADA AND IOWA ESTABLISHED, and it is here for
  # that. Those two publish named hospitals with no amounts, so the danger is
  # reporting $0 without the row count. Maine's award file is ONE ROW to a
  # UNIVERSITY -- zero named-hospital rows, zero named-hospital dollars -- while
  # ELEVEN NAMED MAINE RURAL HOSPITALS sit in `me_rhef_cohort.csv`, INVITED by
  # DHHS to a $30M fund whose "award amount and approved budget will be
  # confirmed after start of participation". That file has no `amount` column
  # and is deliberately NOT in this union, exactly as Missouri's Hub Anchors are
  # not. A future session that "completes" Maine by folding the cohort in would
  # add eleven named hospitals and $0 to the project's headline -- §0.3 at the
  # scale of a state, and with a higher hospital ratio than Missouri's.
  ME = "data/reference/me_year1_awardees.csv",

  # NORTH CAROLINA IS HERE FOR A COMBINATION NO OTHER FILE HAS: A COMPLETE,
  # NAMED, 44-RECIPIENT ROSTER THAT CONTRIBUTES NOTHING TO ANY BUCKET. Nevada
  # and Iowa publish named HOSPITALS with no amounts, so they contribute rows
  # and $0. Maine and Missouri keep their named hospitals OUT of the award file
  # entirely, in a separate no-amount file. North Carolina does neither: all 44
  # of its named recipients ARE award rows, all 44 carry an empty `amount`, and
  # every one is either an EMS agency (`No`) or a regional pass-through lead
  # (`Unclear`). It is the state most likely to break an invariant that only
  # ever held because each file had at least one row in some bucket -- and its
  # five PASS_THROUGH_UNRESOLVED rows are what the mandatory-basis check below
  # exists for.
  NC = "data/reference/nc_year1_awardees.csv",

  # ARKANSAS IS HERE BECAUSE IT IS THE FIRST FILE WHOSE AWARDS ARE PUBLISHED
  # AT TWO GRAINS BY TWO PUBLISHERS, and because it carries a column no other
  # file has: `organisation_award_total`, which REPEATS on both rows of the six
  # organisations holding an award under both initiatives. Summing it down the
  # column gives $250,274,844.36 for a state that awarded $149,177,618.45 --
  # Georgia's trap in a new column name, and the kind of thing that unions fine
  # until someone sums it. Its 37 rows are also the largest unstated-form
  # question in the project ($100,723,693.49 on §8's standing fallback), so it
  # is the file most likely to put a name-derived value outside §8 into the
  # union. AND `ar_year1_projects.csv` -- the Governor's 50 priced projects,
  # the SAME $149,177,618.45 at a finer grain -- is deliberately NOT in this
  # union, exactly as Missouri's Hub Anchors and Maine's cohort are not, but
  # for the opposite reason: those two are not awards at all, while Arkansas's
  # is the same money twice. Adding it would double the state.
  AR = "data/reference/ar_year1_awardees.csv",
  # Wyoming is the first state file assembled from SIX recipient-level tables
  # inside ONE document, and the first whose recipient FORM is stated by the
  # publisher for some tables and not others -- 1.1's column is headed
  # "Hospital", 4.1's eligible class is stated in WDH's own disqualification of
  # an ineligible applicant, and 3.1's table publishes neither a form nor an
  # EIN. It is in this union because that mixture is exactly what gives §8 a
  # different answer in two places in one file, and because two of its 75 rows
  # NAME NOBODY and carry no `amount` at all.
  WY = "data/reference/wy_year1_awardees.csv",
  # DELAWARE IS THE SMALLEST FILE IN THIS UNION AND THE ONE MOST LIKELY TO
  # BREAK IT, because it is the only state whose recipient_type is an OVERRIDE
  # of the shared classifier. §8's name rule returns NONPROFIT_CBO at LOW for
  # "Beebe Healthcare", "Nemours Children's Health" and "TidalHealth" -- so
  # left to the machine Delaware's four rows are `No` and the state has no
  # hospital rows at all, which is §0.3a's own defect reproduced in code. The
  # type is taken from spec §0.3a, which names these three organisations, and
  # the machine's answer is preserved on every row in recipient_type_source.
  # It is in this union so that a future change to the shared classifier meets
  # the override rather than silently agreeing or silently disagreeing with it.
  DE = "data/reference/de_year1_awardees.csv",
  # Idaho is one row, no amount, and NO hospital bucket -- the classifier's
  # fallback is the RIGHT answer there because Idaho states no form, which is
  # the exact contrast Delaware needs beside it.
  ID = "data/reference/id_year1_awardees.csv",
  # Ohio is one row and the only single-row PRICED state file. It is here
  # because $10,000,000 to a UNIVERSITY is the largest single misclassification
  # available in any small file: one wrong recipient_type and a state with no
  # hospital dollars acquires eight figures of them.
  OH = "data/reference/oh_year1_awardees.csv"
)

# Florida's schema is the one the others match on. It is the leading block, not
# the whole file: each state appends its own fields after it (Georgia's phases,
# Alabama's counties, Alaska's App IDs, South Dakota's contract numbers and
# round ids), which is the arrangement Georgia established and the reason the
# union is possible at all.
LEADING_COLUMNS <- c(
  "state", "row_no", "awardee", "amount", "recipient_type",
  "distributed_to_hospital", "note", "recipient_confirmed", "amount_confirmed",
  "fiscal_year", "source_document_title", "state_source_url",
  "validation_source_type", "extraction_method", "validator", "ccn", "aha_id",
  "rural_designation", "reviewer"
)

state_tables <- lapply(STATE_FILES, function(f) {
  readr::read_csv(here::here(f), show_col_types = FALSE, progress = FALSE)
})


test_that("every state file exists and is non-empty", {
  for (st in names(STATE_FILES)) {
    expect_true(file.exists(here::here(STATE_FILES[[st]])), info = st)
    expect_gt(nrow(state_tables[[st]]), 0L)
  }
})

test_that("all twenty-six files carry the leading 19 columns, in the same order", {
  for (st in names(state_tables)) {
    expect_equal(names(state_tables[[st]])[1:19], LEADING_COLUMNS, info = st)
  }
})

test_that("the twenty-six files union without a coercion failure", {
  u <- dplyr::bind_rows(lapply(state_tables, function(d) {
    d %>%
      dplyr::select(dplyr::all_of(LEADING_COLUMNS)) %>%
      dplyr::mutate(dplyr::across(dplyr::everything(), as.character))
  }))
  expect_equal(nrow(u), sum(vapply(state_tables, nrow, integer(1))))
  expect_equal(sort(unique(u$state)),
               c("AK", "AL", "AR", "DE", "FL", "GA", "IA", "ID", "IL", "IN",
                 "KS", "MD", "ME", "MI", "MO", "NC", "NE", "NH", "NV", "OH",
                 "OK", "OR", "PA", "SD", "WY"))
})

test_that("no categorical value anywhere in the union is outside §8", {
  # The check that failed for Florida before session 10 back-fitted it. It is
  # cheap and it is the one that stops Stage 5 being handed two vocabularies.
  u <- dplyr::bind_rows(lapply(state_tables, function(d) {
    d %>%
      dplyr::select(dplyr::all_of(LEADING_COLUMNS)) %>%
      dplyr::mutate(dplyr::across(dplyr::everything(), as.character))
  }))
  for (col in c("recipient_type", "distributed_to_hospital",
                "recipient_confirmed", "amount_confirmed",
                "validation_source_type")) {
    allowed <- if (col == "validation_source_type") {
      rhtp_vocabulary("source_doc_type")
    } else {
      rhtp_vocabulary(col)
    }
    bad <- setdiff(as.character(stats::na.omit(unique(u[[col]]))), allowed)
    expect_equal(bad, character(0), info = col)
  }
})

test_that("§10.2 holds across all states at once", {
  # A hospital coding that a single state's own assertions would let through
  # because it never compares itself to the others.
  #
  # THIS TEST USED TO BE WRONG, AND ILLINOIS IS WHAT PROVED IT. Until session
  # 16 it asserted that EVERY distributed_to_hospital = Yes row carries a
  # hospital recipient_type. That held for six states by accident of what had
  # been extracted -- every one of them awarded money to hospitals DIRECTLY --
  # and it encodes an assumption §10.2 never made. §10.2's
  # PASS_THROUGH_DESIGNATED row is Yes precisely BECAUSE the money reaches
  # hospitals through an intermediary that is not itself a hospital. Illinois'
  # ICAHN row is NONPROFIT_CBO and Yes, and it is correctly coded.
  #
  # So the rule is stated properly now: a Yes row is either a hospital
  # recipient (DIRECT) or a designated pass-through that names its
  # intermediary. Nothing else may be Yes.
  for (st in names(state_tables)) {
    d <- state_tables[[st]]
    yes <- d[d$distributed_to_hospital == "Yes", ]
    if (nrow(yes) == 0) next

    flow <- if ("flow_type" %in% names(yes)) yes$flow_type else rep(NA, nrow(yes))
    direct_ok <- yes$recipient_type %in% c("HOSPITAL_OR_SYSTEM",
                                           "HOSPITAL_AFFILIATED_ENTITY")
    pass_ok <- !is.na(flow) & flow == "PASS_THROUGH_DESIGNATED"

    expect_true(all(direct_ok | pass_ok), info = st)

    # A pass-through Yes must say who the intermediary is and must declare
    # itself a pool. Without both, its dollars are indistinguishable from a
    # named hospital's the moment anyone filters on distributed_to_hospital.
    if (any(pass_ok)) {
      pt <- yes[pass_ok, ]
      expect_true(all(nzchar(pt$intermediary_name)), info = st)
      # The invariant is that a pass-through Yes lands in a POOL bucket, never
      # in NAMED_HOSPITAL -- not that there is only one pool bucket. Nebraska
      # added a second in session 23: the Nebraska High Value Network's award
      # IS made and its 21 hospital subrecipients ARE named, but DHHS publishes
      # no per-hospital split, so POOL_UNNAMED_HOSPITALS would assert something
      # false about the document while NAMED_HOSPITAL would assert something
      # false about the money. Both codes keep those dollars separable from a
      # named hospital's, which is all this check exists to guarantee.
      expect_true(all(pt$hospital_attribution %in%
                        c("POOL_UNNAMED_HOSPITALS", "POOL_NAMED_HOSPITALS")),
                  info = st)
    }
  }
})

test_that("named-hospital dollars and pooled dollars never merge", {
  # THE SEPARABILITY INVARIANT, checked across every state at once. This is
  # the check that keeps Illinois' $50,008,264 out of a figure it does not
  # belong in.
  source(here::here("R", "utils_recipient_classification.R"))

  u <- dplyr::bind_rows(lapply(names(state_tables), function(st) {
    d <- state_tables[[st]]
    tibble::tibble(
      state = as.character(d$state),
      amount = suppressWarnings(as.numeric(d$amount)),
      distributed_to_hospital = as.character(d$distributed_to_hospital),
      recipient_type = as.character(d$recipient_type),
      flow_type = if ("flow_type" %in% names(d)) {
        as.character(d$flow_type)
      } else {
        NA_character_
      },
      hospital_attribution = if ("hospital_attribution" %in% names(d)) {
        as.character(d$hospital_attribution)
      } else {
        NA_character_
      }
    )
  }))

  parts <- rhtp_hospital_dollar_partition(u)

  # Both buckets are populated, so the distinction is load-bearing rather
  # than theoretical.
  expect_true("NAMED_HOSPITAL" %in% parts$bucket)
  expect_true("POOL_UNNAMED_HOSPITALS" %in% parts$bucket)

  # Florida carries no flow_type column at all, so its 15 hospital rows are
  # bucketed from recipient_type. An earlier version of the partition dropped
  # them silently; this pins them.
  named <- parts[parts$bucket == "NAMED_HOSPITAL", ]
  expect_true("FL" %in% named$state)
  expect_equal(named$dollars[named$state == "FL"], 49345213)

  # Illinois is the whole of the UNNAMED pooled bucket.
  pooled <- parts[parts$bucket == "POOL_UNNAMED_HOSPITALS", ]
  expect_equal(sort(unique(pooled$state)), "IL")
  expect_equal(sum(pooled$dollars), 50008264)

  # And Illinois contributes NOTHING to the named-hospital figure.
  expect_false("IL" %in% named$state)

  # Nebraska is the whole of the NAMED pooled bucket, and it must stay out of
  # the named-hospital figure for the same reason Illinois does: nobody can say
  # what any one of the Nebraska High Value Network's 21 hospitals received.
  pooled_named <- parts[parts$bucket == "POOL_NAMED_HOSPITALS", ]
  expect_equal(sort(unique(pooled_named$state)), "NE")
  expect_equal(round(sum(pooled_named$dollars), 2), 18156856.12)
  expect_equal(round(named$dollars[named$state == "NE"], 2), 6990996.01)

  # The three buckets are disjoint by construction, so no dollar is in two of
  # them -- which is the property that lets them be reported side by side.
  expect_equal(nrow(parts), length(unique(paste(parts$state, parts$bucket))))

  # The single combined total is not obtainable. Somebody will try.
  expect_error(rhtp_hospital_total(u), "no single hospital total")
})

test_that("every row names a state source and a source document", {
  # §0.4: a determination without a captured, quotable source is not a
  # determination.
  for (st in names(state_tables)) {
    d <- state_tables[[st]]
    expect_true(all(nzchar(d$state_source_url)), info = st)
    expect_true(all(nzchar(d$source_document_title)), info = st)
  }
})

test_that("the states extracted from archives each carry one on disk", {
  # PA, AL, AK and both South Dakota files name an archive path, and the file
  # has to be there, because §0.5 says an uncommitted archive is gone.
  for (st in c("PA", "AL", "AK", "SD_CONTRACTS", "SD_ANNOUNCEMENTS")) {
    d <- state_tables[[st]]
    expect_true("source_archive_path" %in% names(d), info = st)
    for (p in unique(d$source_archive_path)) {
      expect_true(file.exists(here::here(p)), info = paste(st, p))
    }
  }
})


# -- §7: every pass-through row states its reason (session 31) ---------------

test_that("no PASS_THROUGH row anywhere carries an empty or contradictory basis", {
  # THE SESSION 30 ELIGIBILITY SWEEP'S SECOND FINDING, ASSERTED ACROSS EVERY
  # STATE AT ONCE RATHER THAN STATE BY STATE. It found eight bad rows in two
  # files -- six Oregon rows whose basis argued for the coding an override had
  # replaced, and two Nevada rows with no basis at all because the file had no
  # such column. Both are fixed at their sources; this is the guard that stops
  # a ninth appearing in a state nobody thought to check.
  #
  # PASS_THROUGH is the class that matters most for this: it is the bucket a
  # later session revisits to decide whether dollars move into a hospital
  # total, and §7 makes `determination_basis` mandatory so that decision can be
  # made from the row.
  problems <- character(0)
  for (nm in names(STATE_FILES)) {
    d <- readr::read_csv(here::here(STATE_FILES[[nm]]), show_col_types = FALSE,
                         progress = FALSE)
    if (!"flow_type" %in% names(d)) next
    ft <- d$flow_type
    ft[is.na(ft)] <- ""
    pt <- d[grepl("PASS_THROUGH", ft), ]
    if (!nrow(pt)) next
    if (!"determination_basis" %in% names(pt)) {
      problems <- c(problems, paste0(nm, ": ", nrow(pt),
                                     " PASS_THROUGH rows and NO determination_basis column"))
      next
    }
    b <- pt$determination_basis
    b[is.na(b)] <- ""
    if (any(trimws(b) == "")) {
      problems <- c(problems, paste0(nm, ": ", sum(trimws(b) == ""),
                                     " PASS_THROUGH rows with an EMPTY basis"))
    }
    # A basis that LEADS with §10.2's DIRECT row on a row that is not DIRECT.
    # Leading, not containing: a basis may legitimately quote a superseded
    # machine determination behind its own reason (Oregon does), and that is
    # an audit trail rather than a contradiction.
    if (any(startsWith(b, "§10.2 DIRECT"))) {
      problems <- c(problems, paste0(nm, ": a PASS_THROUGH row's basis LEADS ",
                                     "with §10.2 DIRECT"))
    }
  }
  expect_equal(problems, character(0))
})

