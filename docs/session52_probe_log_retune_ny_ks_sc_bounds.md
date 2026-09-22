# Session 52: the probe log, the retuned tripwires, New York and Kansas extracted, South Carolina bounded

Run 2026-09-22. No RCJ quota was used. Network calls went to health.ny.gov, kdhe.ks.gov and data.cms.gov (CMS enrolment slices), plus the live probes.

## Task 1: why Routine verdicts never reached the log

**Measured.** All 58 lines committed to `logs/probe_results.csv` before this session came from interactive sessions (46, 47, 48 and 51). **None of the Routine firings on 9/21 and 9/22 is in it** (AK, CT, KY, MS, ME, WI, NM), and none of New York's five firings after its roster went public on 9/4 is either.

**Three causes, in layers.**
1. **§0.5, not the logger.** `rhtp_probe_log()` appends the line correctly, but in the Routine's own throwaway container. Nothing committed or pushed it. The persistent-session Routine (ME/CA) says as much in its own summary: *"One-row probe log appends to main only; not committed to branch per session constraint."*
2. **The fresh-session Routines have no repository to push to.** Every trigger's `session_request.config` reads `"sources": []` and `"outcomes": []`. A prompt cannot grant write access. **Tested, not assumed.** New York's prompt was rewritten to commit and push the log to `main`, and the trigger was fired on demand (session `cse_01FdExt63noTVWHV6Ryq2psC`, 19:33Z). It finished, and **no commit reached any branch.** Its transcript is not readable from this session, so the exact git error is not recorded here.
3. **For New York specifically, the phrase list missed the roster anyway.** `NY_AWARD_POSTED` has "list of awardees" and "awardees are" but not "Awardees List", which is the link text DOH used. That is §2.3's lesson again: the name tripwire (session 48) is what caught it on 9/22.

**What was fixed here.**
- **`origin` column on the log.** A Routine sets `RHTP_PROBE_ORIGIN=<trigger id>`; everything else writes `interactive`. Without it, an interactive probe run later the same day *covers* a Routine firing that left nothing. Alaska's lost 9/21 14:00 run was masked exactly that way by a 16:37 session line. All 58 old lines are tagged `interactive`, which is what they are.
- **`config/routines.csv`**: the committed registry of all 16 Routines (15 existing, plus Kansas), with the cron each trigger actually carries and `logging_since`.
- **`R/probe_coverage.R`**: `rhtp_assert_probe_coverage()` fails, naming state, time and trigger, for any scheduled firing with no line from that Routine within 6 hours. `--check` runs it live. The suite runs it deterministically, up to the log's own newest line, so **it will turn red the first time a registered Routine fires without publishing and anyone then logs anything.** That is intended.
- **Counterfactual, driven in a test:** run from 9/20 on the committed log, it names 7 lost firings: AK 9/21, WI 9/22, CT 9/21, KY 9/21, NY 9/20, AR 9/20, MS 9/22.
- `.gitattributes`: `logs/probe_results.csv merge=union`, so concurrent appends rebase cleanly.

**What is NOT fixed, and needs the owner.** Routines still cannot publish. New York's prompt carries the push instruction (it reports the push failure if it recurs); the other 14 prompts were **left unchanged**, because copying an instruction that cannot succeed adds nothing. The options:
- (a) Re-bind each Routine to one persistent "probe runner" session created with this repository as its source and an outcome branch. `create_session` supports `source_url` + `outcome_branch`, and `create_trigger` supports `persistent_session_id`.
- (b) Decide which branch unattended runs may push to: `main` directly (restricted to the one log file, which the prompt already checks), or a `probe-log` branch that a human merges.

**Until one of those is done, no Routine's silence is evidence**, and the coverage check says so by name.

## Task 2: the seven halting probes, retuned

The live name tripwire was run on every wired page, with the throw suppressed so every page was read (the real tripwire stops at the first). New names by page:

| State | Page | What was new | Fix |
|---|---|---|---|
| WI | dhs_solicit | 3 solicitation titles (CDC DPP; "Opioid Settlement Funds"; QTT stipends) | `furniture` |
| ME | programme | two document links run together | `furniture` |
| CA | funding, calrht | HCAI mega-menu ("Latest News", a data link) | **scope** to breadcrumb → footer |
| KY | rch | FHKY liaisons, a news headline about FHKY, a rewritten CMS footer | `furniture` |
| NC | trillium | two advisory-board headings | `furniture` |
| DE | release | the NEWS FEED sidebar, ~40 other agencies' headlines, rotating daily | **scope** to "Flag Status" → subscription footer |
| DE | programme | DHSS mega-menu reshuffle | **scope** to breadcrumb → "Quick Links" |
| ID | funding, about | every opportunity re-labelled "CLOSED <date>:"; a task-force meeting notice | **`CLOSED` break token** + `furniture` |

**Two mechanisms were added, deliberately different from `known`.**
- **`furniture` is matched EXACTLY.** `known` matches by containment, because it records a recipient and an over-joined run is the safe direction. Furniture is the opposite claim: a string a human read and judged *not* a recipient. By containment, "Rural Health Transformation Fund" would swallow "Rural Health Transformation Fund Hospital Authority". A test drives both behaviours.
- **`rhtp_name_scope(text, from, to)`** keeps a page's content region, on the live and the archived copy alike. It **refuses** if an anchor is missing, or if the scope keeps under 5% of the page (what an anchor that moved into the menu looks like). A feed that rotates daily cannot be listed; it can be cut away.
- **`CLOSED` joins `RHTP_ORG_NAME_BREAK_TOKENS`** on Louisiana's footing. It is upper case only, measured against Idaho's two snapshots.

Every furniture string carries the sentence that justifies it, in its state file. A test appends a real recipient ("Pikeville Medical Center") to every retuned page's archived text and requires it still fires. **All seven probes then ran live end to end and logged `CHANGED` with no tripwire.** The suffix list was not widened.

## Task 3: New York extracted

`R/03ag` was rewritten from a negative probe into an extractor, as its own header said it must be. Roster: DOH's *Rural Community Health Integration Awardees List*, archived at `data/evidence/NY/2026-09-22_ny_rchi_awardees_list.html`.
- **56 lead-applicant rows, 55 names (Ellenville twice), $76,190,022.00**: RCHI's allocation, exact to the cent. The Governor (9/4) says "90 awards to 56 organizations", so a row is a **lead's total**, not an award. The $22.7M planning / $53.5M implementation split is published only in aggregate. The provenance and date tests pass on the release: the CMS footer, "federal Rural Health Transformation Program", and 2026-09-04 > 2025-12-29.
- **§7's third class, applied one award at a time.** Hospital lead: `DIRECT`/`Yes`. Non-hospital lead: `PASS_THROUGH_UNRESOLVED`/`Unclear`, in no bucket, because the roster names no partner hospital.

| | Rows | Dollars |
|---|---:|---:|
| Hospital leads (`NAMED_HOSPITAL`) | 35 | $47,358,790.79 |
| …of which hand-read bridges (`GENERAL_KNOWLEDGE`/LOW, subtractable) | 9 | $13,961,712.00 |
| Non-hospital leads (Unclear, neither bucket) | 21 | $28,831,231.21 |

- **Typing is against CMS's own NY enrolment slices** (hospital, FQHC, RHC), archived under `data/evidence/federal_records/2026-09-22/`. 25 hospitals (26 rows) and 6 FQHCs are exact `ORGANIZATION NAME`/DBA matches, with the CCN recorded (`ORG_WEBSITE`/MEDIUM). Nine hospitals and one FQHC are bridges, each explained: Bassett, where CMS misspells its own DBA; F.F. Thompson → "Frederick Ferris Thompson"; Mohawk Valley Health System → MVHS INC dba Wynn Hospital; and others. Twelve are refused.
- **Two stem traps were refused by name.** "Mohawk Valley" also matches the NYS Office of Mental Health's *Mohawk Valley Psychiatric Center*. "Southern Tier Health Care System" is not the Southern Tier Community Health Center Network FQHC.
- Westfield Memorial is enrolled as a **Rural Emergency Hospital**, and eight rows are CAHs.
- **A defect found by the new test:** the roster-sum check used `all.equal()`, whose relative tolerance lets a $1 change on $76M through. It is now exact to the cent.
- New York moved `INVESTIGATED_NO_LIST` → `EXTRACTED` in both rebuilt survey tables. The rebuild also carried in session 51's CMS monitor rows (MO 9/22, NM 9/21, CT and SC now `BOTH`), which had not been propagated.

## Task 4: Kansas's fourth pool, and a reader that could not read it

**Diagnosed before building.** KDHE's Emerging Technology PDF (created 2026-09-18) returned **zero lines**: an empty answer, not an error. Two reasons, both confirmed in the decompressed content stream:
1. **The producer paints every string with the `'` operator** (`(CommonSpirit Kansas)'`). The reader recognised only letter operators, so every string stayed pending and was never painted.
2. **The streams carry `%` comments,** one containing `NoClip(18436)`, which a comment-blind scanner reads as a string.

**Fix, in `R/utils_pdf_text.R`:**
- comments are skipped to the end of line;
- `'` and `"` move by the text leading `TL` (now tracked) and paint;
- `TL` never occurs in KDHE's file, so its pen stays at the `Tm` position.

**Proved** by reading all 78 committed PDFs before and after. **77 are identical.** The 78th, Kentucky's CMS NOA attachment B, uses `'` with `TL` set (407 times). The old reader had been welding each such line onto the one above; the change is a correction. Kentucky's status files rebuild unchanged.

**Extraction.** 14 awards, **$16,006,648** (KDHE: "$16 million … 14 eligible providers"), appended to `ks_year1_awardees.csv` as pool `EMERGING_TECH`. **Rows 1–46 are byte-identical** to the committed file after session 49's overlay is re-applied. That overlay is keyed by row index, and an assertion pins that the new pool is appended.
- **7 hospital rows / $10,176,973** in `NAMED_HOSPITAL`: 5 exact CMS matches, plus Rice County HD #1 and Grisell Memorial as LOW bridges.
- **Attica Hospital District #1 ($532,045) is held OUT.** Its name says "Hospital District", but CMS enrols no Attica hospital under any provider type; the only Attica record is an RHC of Harper County's district **No. 6**. KDHE's own description is about nursing-home capacity. An assertion keeps the refusal honest.
- Via Christi Village Hays is a CMS-enrolled **SNF** (`OTHER`). Genesis Family Health is an FQHC in KDHE's own words.

**Kansas now has a probe and a Routine**: `trig_01JkvfXqqNaLXuf8xFja5nNR`, Mondays 08:10 UTC, first firing 2026-09-28. It ran live and reports UNCHANGED. The programme page was re-based to a 2026-09-22 snapshot; the 2026-08-29 copy is kept and never re-fetched.

**A hazard met and reversed.** Running `R/03ap --apply` after rebuilding one state re-derived its plan from the already-overlaid files and shrank `verification_queue_2_changes.csv` from 487 rows to 31. The plan was restored from git and applied to Kansas alone. Re-apply that overlay with `vq_apply(<plan filtered to the file>)`, **never** a bare `--apply` after a partial rebuild.

## Task 5: South Carolina against the benchmark

The benchmark is SC Medicaid's statement as recorded in session 47: about 240 awards, about $170M, about 50% of awards and about 60% of dollars to hospitals. Every figure below is reproduced by `R/03as_sc_benchmark_bounds.R` into `data/reference/sc_benchmark_bounds.csv`. **No classification was changed.**

| Reading | Awards % | Dollars % | Gap to 60 (pts) |
|---|---:|---:|---:|
| As typed (113/228; $115.84M/$167.30M) | 49.6 | 69.2 | +9.2 |
| On the benchmark's own denominators (240 / $170M) | 47.1 | 68.1 | +8.1 |
| **1. Rural-only: source-backed rural rows** | 2.2 | **4.1** | −55.9 |
| 1. Hospital dollars with rural status unrecorded (share of hospital $) | | 60.6 | |
| 1. Hospital dollars on a CMS ordinary-hospital CCN (rural not recorded) | | 33.5 | |
| 1. Rural share of hospital $ that 60% would require | | 86.7 | |
| **2. Psychiatric excluded: Carolina Center + Rebound** | 48.7 | 68.0 | +8.0 |
| 2. Acadia alone | 49.1 | 65.9 | +5.9 |
| **2. All three (CMS 4xxx psychiatric CCNs, $7,610,253)** | 48.2 | **64.7** | +4.7 |
| **3. Prisma + Self Regional collapsed to one organisation each** | 24.8 of orgs | **69.2 (unchanged)** | +9.2 |
| 3. …and the organisation coded wholesale | 24.8 | 69.3 | +9.3 |
| 3. Prisma site lists split, one award per site (+5) | 50.6 of 233 | 69.2 | +9.2 |
| 3. Self Regional's three non-hospital-site rows treated as its pediatrics row is | 48.2 | 67.6 | +7.6 |
| 2 + 3 combined (the most the testable readings can do) | 46.9 | **63.1** | +3.1 |

**Reading 1, rural-only.** It **cannot be tested** on committed evidence. Only 5 SC hospital rows (Edgefield CAH, $6.87M) carry a source-backed rural designation, and rural status is unrecorded either way for **94.1% of SC hospital dollars**. On the evidence in hand it gives 4.1%. It lands at ~60% only if 86.7% of SC's hospital dollars are rural. It is **the only reading that could close the gap**, and it is neither confirmed nor excluded.

**Reading 2, psychiatric excluded.** Identified by the CMS CCN each row cites, never by name. The full effect is **4.5 points** (Acadia 3.3, the other two 1.2), landing at **64.7%**, not 60.

**Reading 3, multi-site.** **Confirmed: the grain moves counts, not dollars.** Collapsing Prisma (19 rows) and Self Regional (20 rows) leaves the dollar share at 69.2% exactly. It drops the count share to 24.8% of organisations, *away* from ~50%. The agency's own "~240 awards" is above our 228 rows, so **it does not count at organisation grain**; splitting Prisma's site lists gives 233, toward it. Dollars move only if a system's named non-hospital *site* is treated as a non-hospital award (−1.6 points).

**An inconsistency inside this repository, recorded and not corrected.** Self Regional's "(Greenwood Pediatrics)" row is `PHYSICIAN_PRACTICE`/`No`. Its "(Imaging Center)", "(Montgomery Center)" and "(Optimum Life Rehabilitation Center)" rows, the same shape, are `HOSPITAL_OR_SYSTEM`. That is $2,735,000.

**Verdict.** **No testable reading lands at ~60%.** The two testable ones combined leave SC at 63.1%, 3.1 points over. More than one reading narrows the gap; **none closes it except rural-only counting, which the evidence here cannot test.** So the figures are **reconcilable only if the agency's "hospital" excludes at least $15.46M of what this file codes hospital**: non-rural hospitals being the one candidate large enough, or psychiatric plus non-hospital sites plus about $5.1M more on some criterion not named.

**The single question to the agency:** *"Which of the 228 rows on the SC RHTP Year 1 Award List does your ~60% count as awards to hospitals?"* The row list settles all three readings at once, and the ~240 vs 228 count difference with them.

## Totals after this session

| | Rows | Dollars | States |
|---|---:|---:|---:|
| `NAMED_HOSPITAL` | **981** | **$845,025,923.32** | **20** |
| …source-backed rural (rural cut) | 164 | $171,872,989.39 | |
| `POOL_NAMED_HOSPITALS` | 1 | $18,156,856.12 | NE |
| `POOL_UNNAMED_HOSPITALS` | 1 | $50,008,264.00 | IL |

`NAMED_HOSPITAL` moved +42 rows and +$57,535,763.79: New York's 35 rows / $47,358,790.79 and Kansas's 7 rows / $10,176,973.
