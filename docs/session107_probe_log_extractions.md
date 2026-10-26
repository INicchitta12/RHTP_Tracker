# Session 107 — probe log since 10-20, two extractions, five held rosters

2026-10-26. Branch `claude/probe-log-roster-extractions-b2q8h5`.
- **`main` did not carry session 106.** `claude/admiring-goodall-2sf0vu` was unmerged at session start, and it was the no-merge window (Mon 13:00–14:00Z), so this branch merged it in rather than `main` taking it. Merging this branch therefore lands sessions 106 and 107 together.
- No Year 2 work was done. No CMS release read this session announces FY2027 amounts: WY and GA say each state "has committed its full" Year 1 funding, and AK's release "completes Alaska's Year 1 RHTP funding cycle".

## Hospital partition, before and after

The three buckets are never added together.

| Bucket | Before (session 106) | After (session 107) | Moved by |
|---|---|---|---|
| NAMED_HOSPITAL | 1,576 / $1,431,975,278.58 / 34 states | **1,585 / $1,439,954,278.58 / 34** | +2 WV (WVU Health System, $3,400,000); +7 VA VHCF Productivity ($4,579,000) |
| POOL_NAMED_HOSPITALS | 7 / $85,555,171.43 | **8 / $86,555,171.43** | +1 VA (VCU Health pair, $1,000,000) |
| POOL_UNNAMED_HOSPITALS | 5 / $69,323,109.17 | 5 / $69,323,109.17 | — |

- **Internal figure.** With SOURCE_SUSPECT rows included, NAMED_HOSPITAL is 1,587 / $1,443,409,699.58. Never publish it alone.
- **Rural cut.** 410 / $367,023,056.72 becomes **411 / $367,063,056.72**. The added row is Bath County Community Hospital, CAH 491300, $40,000.
- **Subtractable.** Of the +$7,979,000 added to NAMED_HOSPITAL, **$6,400,000 is system parents typed on general knowledge** (LOW, GENERAL_KNOWLEDGE, no CCN): WVU Health System $3.4M, plus Ballad, Sentara and Valley Health $1M each. Only $1,579,000 rests on exact CMS enrolment records (Bath County, Buchanan General ×2, Carilion Medical Center).

## Task 1: small items

| Item | Done |
|---|---|
| **RI probe** | `R/03ci_ri_press_probe.R` (new). Details below. |
| **MT re-base** | `R/03bl` Grants page re-based to `2026-10-26_mt_rhtp_grants.html` after reading the diff: only the CIH block moved. "Date Awarded: Oct. 13, 2026 · Amount: $3.63 million", class "EMS to administer CIH programs", nobody named. The CIH block is now an anchor, so a roster replacing it or its removal trips. The name tripwire is unchanged. Live probe: Grants UNCHANGED. |
| **MT old Routine** | `trig_01YJFwwSQ1pEQEScfUfGzgSD` **deleted**, after the new id `trig_013NBAwSZ2Rh4hhbjtLZtYA6` logged on `main` (10-23 17:42Z, commit `adf2296`). Recorded in `routines.csv` `old_deleted` (`@2026-10-26`). |
| **MS DMH-RHTP-2027-001** | Added to `ms_status_table()` / `ms_year1_status.csv` as `CLOSED_NO_AWARD_DATE_PUBLISHED`. It is a Tier 2 vendor solicitation (advertised 09-29, closed 10-14, no award), never an award figure. |

**RI probe, what it reads and why.**
- **Pages.** The portal's all-agency RSS feed (`www.ri.gov/rss/1/pressrelease.rss`) and the `/press/` index.
- **Why the feed.** It holds the latest 50 items, spanning 09-17 to 10-26, so a weekly probe cannot miss one. The index shows only 10 items, and on 10-26 all ten were State Police arrest logs.
- **Trips.**
  - Any feed item about rural health, RHTP or EOHHS awards.
  - Any new agency in the index's agency list. This is the organisation-name check, and it runs through the shared `rhtp_assert_no_new_organisations_across()` as well as its own set diff. EOHHS and the Governor do not post on the portal today.
  - The empty-baseline rule: the probe refuses to pass if the archive yields fewer than 20 items or 5 agencies.
- **Caveat.** RIDOH's own portal entry says its news moved to `health.ri.gov`, which is 403 here, so RIDOH items on the feed are legacy.
- **Evidence and tests.** Baselines are in `data/evidence/RI/probe/` with a manifest. `test_03ci` plants an RHTP item and a new agency (both trip), checks the archive against itself is quiet, and checks the empty baseline refuses. The live probe reads UNCHANGED on both pages.
- **Routine.** `trig_01WXYStckEw4tjE1Er77BV94`, "RHTP probe: RI (weekly Tue)", cron `50 19 * * 2`.
  - Runner: its own, `session_013dHQxtacanDM2n79ZnRczD`, configured as IL's runner is (environment, sonnet-5, auto, `main` as source and outcome).
  - Prompt: `v3/RI.txt` is IL's prompt with four substitutions. `v4/RI.txt` was generated, and `--check` reads "v4 matches derived for 43 states". The stored prompt is that file verbatim.
  - Registered in `routines.csv`, `logging_since 2026-10-26T14:05:16Z`.
  - **First firing: Tue 10-27 19:50Z.** `main` has no `R/03ci` until this branch merges.

## Task 2: probe log since 10-20, by state

Every firing since 10-20 logged except CMS 10-22 and 10-26, both explained below. Below, "read" means fetched live and diffed against the archive this session; the CHANGED-only pages were diffed by a read-only agent and spot-checked.

### Lead: findings that move hospital dollars

| State | What fired | Finding | Disposition |
|---|---|---|---|
| **WV** | 10-23 TRIPWIRE, new award release | 10-19 "More Than $3.4 Million … to West Virginia United Health": CCG "more than $2.5 million" plus MSCF $900,000, both to West Virginia United (WVU) Health System. | **EXTRACTED** (Task 3, below) |
| **VA** | 10-20 and 10-23 TRIPWIRE, VHCF anchor gone | VHCF awarded Provider Productivity on 10-16: 23 lines, $8,644,000. `/rural-health/` now says "$23 million to 31 organizations". | **EXTRACTED** (Task 3) |
| **TX** | 10-23 UNCHANGED, correctly | HHSC's 10/23 list was posted at **19:10Z** (Last-Modified), after the 13:22Z firing. 441 lines (129 "Added Oct. 23"), $87,248,124 new Year 1; about 69 hospital-shaped lines / about $59.2M; 159 contracts executed. It adds a **County** column, so the old reader refused it. | **HELD (> $10M).** Archived at `recheck/2026-10-26/TX/`. `R/03ce`'s reader now tolerates the column; it is inert on the 10/14 list and validates. CMS's 10-22 "$8M to 28 providers" is a subset of this list. |
| **VT** | 10-20 TRIPWIRE ("Updated as of October 8" gone) | The 10-23 update moves the page total from $131,057,627 to **$180,171,067**: +76 keyed rows / $55.5M and −14 / $6.4M, so the 14 dropped rows need re-keying. About **$33M** goes to hospital-shaped recipients, including University of Vermont Health $8.3M, Brattleboro Memorial $4.2M, Northwestern $3.3M and Copley $3.1M. | **HELD (> $10M).** Archived at `recheck/2026-10-26/VT/`. |
| **ID** | 10-20 CHANGED only. The list was posted after that run; the Tue 10-27 firing should trip. | DHW's funding page (updated 10-21) links "See the list of awardees as of Oct. 16": `Idaho-RHTP_List of Awardees dated 10192026.xlsx`. 114 rows, all priced, **$180,701,814** (Subrecipient $125.4M, Contractor $32.4M, MOA/MOU $22.9M). About **50 hospital-shaped rows / about $90.6M** by name only (Bingham Memorial, Gritman, Steele Memorial, Benewah, Syringa, St. Luke's and others). WebLink needs a session cookie. | **HELD (> $10M).** Archived at `recheck/2026-10-26/ID/`. |
| **MS** | 10-23 gov_newsroom CHANGED **with no trip (probe defect)** | Governor 10-21: **60 awards, $32,606,496.32**, and the 60 lines reconcile to the cent. This is the WEI and EmPATH tranche. About 28 hospital-shaped lines / about **$22.2M**, including three EmPATH units: Merit Health Central $4.5M, Memorial Hospital at Gulfport $4,496,000, UMMC Greenwood $4,320,032. | **HELD (> $10M).** Archived at `recheck/2026-10-26/MS/`. **The MS newsroom check missed an RHTP award headline:** fix before the next firing. |
| **NY** | 10-21 and 10-25 TRIPWIRE, roster header changed | DOH re-published RCHI at **project grain**: 107 lines, 6 columns (Type = Planning or Implementation, Fund Amount, Summary), with the same $76,190,022. Every lead's total reconciles to the committed 56-row file. The one exception: **Glens Falls Hospital ($1,500,000, now coded hospital DIRECT) is now listed as "Glens Falls Hospital/ Hudson Headwaters"**, a hospital–FQHC pair. | **HELD: needs a ruling.** Keep $1.5M as a hospital row, or take it out of every bucket as a multi-recipient field shared with a non-hospital. Archived at `recheck/2026-10-26/NY/`. The probe trips until R/03ag's header check is updated. |
| **OH** | 10-21 TRIPWIRE ("haven't been announced yet" gone) | ODH now **names** the CIN/Hub recipients (7: Ohio High Value Network, OSU Health Network, UH Health System, Beavercreek Medical Center/Kettering, Mercy Health–St. Rita's, OACHC, Child & Family Health Collaborative) and the maternal-care recipients (6). It still prices only the pools, $31.4M and $30.3M, which are shared with non-hospitals. There is still no per-hospital split of the $30.3M direct payments. | **Not extracted.** No new priced roster, and under §7 (session 105) the shared components enter no bucket. Adding the 13 named recipients at $0 is an owner call. The probe's hard-coded sentence check will trip every firing until R/03an is updated. |

### Read, no hospital dollar

- **IA (10-22):** two notices on the NOIA index.
  - A **Notice of Delay**: the NOIAs for COMPADM26005 (Co-Location), COMPADM26006 (Maternal Hub and Spoke), PHTHOET27001 (MIH) and PHTHOET27002 (High-Risk OB/Neonatal Transport) are "delayed until on or around November 2, 2026". This is a dated watch.
  - The colorectal-screening RFP PHTHOCC27705 is rescinded.
- **IN (10-23):**
  - IDOA's RFP 26-87448 recommendation letter (Medical Operations Coordination Center): Patient Flow Innovations $26,362,844, Collaborative Fusion $3,698,932, Communicare $11,629,000. These are five-year *maximum* values for vendors, "to begin contract negotiations". Not extracted.
  - `grow_regional` and `init6`: contact and newsletter changes only.
- **SD (10-22):** the register changed only by an amendment to Business Concepts & Apps (DSS project management), $250,000 to $531,000. That is a vendor, so $0 of hospital money.
- **OK (10-22):** new Tier 2 items only: OMES Community Paramedicine consulting RFP (due 11-18), OSU Tech Co-Op enrolment (12-1), OHCA EHR RFI and HIE/EHR assistance, and a link to OSDE's ROOTS school-grant recipients.
- **VA `vhha_foundation` (live today):** vhhafoundation.org redirects to `vhha.com/foundation/`. The new page names no awardee and drops "Awards announced by October 30, 2026". This is a site migration, not an award. Repointing the URL and anchor is an owner call; until then R/03bb trips on it.
- **MT (10-20, 10-23):** the CIH block, re-based (Task 1).
- **NH (10-21):** FHC's CAH RFA key dates (portal "Late October", priority deadline 11-12, initial-cohort award "Mid December"). Tier 2, already the recorded watch.
- **CA (10-24):** the `calrht` scope anchor was not found, so HCAI's layout moved. Needs a re-anchor.
- **KY (10-22):** `rch` names a staff position ("Deputy Director of Collective Impact"). Furniture, not a recipient.
- **WI (10-20, 10-23):** a breadcrumb run on `dhs_rhtp`; Title V, asthma and family-planning RFAs on `dhs_solicit`. State and federal programmes, not RHTP.
- **Pre-merge trips** (`main` lacked session 106, so these are already handled on this branch): MS `funding`/`home`, WY `programme` (both firings), CT `programme`, and the IL 10-21 ERROR (`R/03cg` missing on `main`).
- **KS (10-26):** ERROR, KDHE 403. This is our access, not the state (§0.4).
- **CHANGED with no award signal** (diffed): DE `programme` (Catalyst Fund second-round notice, nobody named), CO, MO, NE, SC, NJ, TN, AL `governor`, WA `bids`, NC `trillium`, LA ×3, NM ×2, ME ×2 (a language menu), ID `about`, and the 10-22 NEWSROOM state indexes. None names a recipient or prices an award.

### CMS: two missed firings, explained; the releases collected

- **Cause.** On 10-22 and 10-26 the runner's suite failed `test_00_cms_press_monitor.R:675`, which holds every newsroom-only row to 21 days.
  - NC's 2026-09-30 $20M release has **never appeared on medicaid.gov**, even though medicaid.gov carries NC's 09-14 and 10-07 releases. So this is an omission, not a lag.
  - 10-26 also named two coverage gaps caused by the pre-merge `main`.
  - Neither run committed anything.
- **Fix.**
  - `config/cms_medicaid_gov_omissions.csv` records the omission, with archived evidence at `recheck/2026-10-26/CMS/`. The check exempts listed rows only, so a new straggler still fails.
  - Both misses are in `probe_gaps_explained.csv`. No line was back-filled.
- **Collected.** An interactive `R/00 --run` at 14:08Z, after the window, collected the releases the runner discarded: AK $249M, GA $219M, FL $193.7M, WY $205M, MS $32M, MD $16.4M, TX $8M.
- **Coverage.** "249 due firing(s) since the logging fix; all logged except 6 EXPLAINED miss(es)."

### Runners above 650k

SD **751,763**, WA **676,618**, VA **664,020**. All are idle. SD is above the 700k level at which earlier sessions moved runners. Not moved (not in the brief).

## Task 3: extractions (pre-approved, under $10M of hospital money, no new ruling)

**WV (`R/03av`, key `wvu`): 2 rows, $3,400,000, both hospital.**
- The recipient is typed a **system parent** (HOSPITAL_OR_SYSTEM, LOW, GENERAL_KNOWLEDGE, no CCN), on the Vandalia, Sanford/Avera and Guthrie rulings.
- No CMS WV enrolment carries its legal name. "WEST VIRGINIA UNIVERSITY HEALTH SYSTEM" is only the DBA of Weirton Medical Center Inc (CCN 510023), a different legal body, so it is not bridged.
- **The CCG award is printed only as "more than $2.5 million"**, so the row carries the published floor, $2,500,000, flagged AMOUNT_ROUNDED_IN_SOURCE. The figure understates and never overstates. If the owner prefers a floor to be unpriced, that row moves to $0.
- WV is now 28 rows / $18,804,875; hospital 14 rows / $6,324,000.

**VA VHCF Provider Productivity (`R/03ch`, new; it sources `R/03bx`'s typing): 23 lines, $8,644,000.**
- **Exact CMS records:** Bath County Community Hospital (CAH 491300, $40,000), Buchanan General ×2 ($539,000), Carilion Medical Center ($1M).
- **System parents** on the session-93 acceptance: Ballad, Sentara and Valley Health, $1M each.
- **VCU Health, Community Memorial & Tappahannock Hospitals ($1M):** one POOL_NAMED row, Connecticut's Hartford-pair shape. The two hospitals are enrolled separately (CCN 490098, 490084) and share one figure, which is never divided.
- **"UVA Health" ($62k):** UNIVERSITY_OR_AHC / NON_HOSPITAL, joining the AHC_STRING queue.
- **Other recipients:** FQHCs on their FQHC enrolment; community services boards are LOCAL_GOVT on the release's own heading.
- **Registration.** Registered in `STATE_FILES` (`VA_VHCF_PP`) and in Deliverable 1. `test_03ch` covers it.
- **Probe.** R/03bb's VHCF anchor moves to the next-cycle sentence ("We anticipate that the next funding cycle will open in Spring 2027."). The `vhcf` and `vhcf_news` pages are re-based to 2026-10-26 after reading; the old copies stay.

## Owner decisions this session leaves open

1. **Held rosters, each over $10M of hospital money.** In descending order of hospital dollars:
   - ID, about $90.6M on 114 rows. It is the first Idaho roster, and it has Contractor and MOA rows that need tiering.
   - TX 10/23, about $59.2M.
   - VT 10-23, about $33M.
   - MS 10-21, about $22.2M.

   Each is archived under `data/evidence/recheck/2026-10-26/<ST>/`.
2. **NY Glens Falls pair** ($1.5M): hospital DIRECT, or a hospital–FQHC multi-recipient field in no bucket.
3. **OH**: add the 13 newly named CIN/Hub and maternal recipients at $0, or report only. R/03an's "haven't been announced" check needs replacing either way.
4. **Probe fixes this session did not make:**
   - VA `vhha_foundation` URL and anchor (vhha.com).
   - CA `calrht` re-anchor.
   - NY header check.
   - **MS gov_newsroom missed an award headline.**
   - KY `rch` furniture.
   - WI breadcrumb furniture.
5. **Runners:** move SD (751,763), and consider WA and VA.

## Merge timing

- **Merge before Tue 10-27 12:40Z**, ID's next firing. The firings after it are VT, VA, MT, WI, ME, NV, NM and **RI 19:50Z (first firing)**.
- RI's first firing needs `R/03ci` on `main`. Until it merges, `main` also lacks session 106 (IL, MT, WY, MS, CT).
- **Never merge Mon/Thu 13:00–14:00Z.** This branch carries CMS-monitor output: `cms_state_announcements.csv`, `cms_newsroom_topic_index.csv`, `logs/cms_press_manifest.csv` and `data/raw/cms/2026-10-26/`. Merge it **well before Thu 10-29 13:00Z**, or the CMS runner's rebase will conflict as it did on 10-19.

## Suite

`Rscript tests/run_tests.R`: **0 failed, 1 expected skip** (the CMS monitor's first-run branch).

It took three runs to get there:
- **Run 1: 80 failures.** The session-by-session partition pins in `test_03ap`, `test_03bj` and `test_state_union` needed a session-107 step: 9 rows / $7,979,000 NAMED and the $1M VA pair. Separately, `ri_probe()` called `rhtp_watch_fetch()` in its own body, which breaks the rule that a probe never reaches a `_fetch` writer, read textually; the fetch now sits in a helper, `ri_live()`.
- **Run 2: 8 failures.** The WV test's row counts and the rural cut's non-TX count were still pinned to the old file, and WV's RCJ disposition needed a rebuild (`R/03bh --build`; only the WV file moved).
- **Run 3: clean.**
