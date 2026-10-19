# Session 102 (2026-10-16): Nevada rulings, Hawaii probe, Friday check-in

Started from `main` at `789e395`, with session 101 (`claude/festive-gauss-ef9zy8`, PR #105) merged. No Year 2 work. CMS has not announced FY2027 amounts, so nothing was archived for that.

## Hospital partition, before and after

The three buckets are never added. **Published** figures leave `SOURCE_SUSPECT` rows out. That is now the default of `rhtp_hospital_dollar_partition()` (owner ruling, Task 1d).

| Bucket | Before (session 101, as committed) | Before, without SOURCE_SUSPECT | **After, published** | After, internal (with SOURCE_SUSPECT) |
|---|---|---|---|---|
| NAMED_HOSPITAL | 1,336 / $1,309,664,382.63 / 32 | 1,334 / $1,306,208,961.63 | **1,336 / $1,307,219,167.63 / 32** | 1,338 / $1,310,674,588.63 |
| POOL_NAMED_HOSPITALS | 4 / $51,084,910.43 | same | **6 / $55,255,171.43** | same |
| POOL_UNNAMED_HOSPITALS | 5 / $69,323,109.17 | same | **5 / $69,323,109.17** | same |

**Nevada:**

| | NAMED_HOSPITAL | POOL_NAMED_HOSPITALS |
|---|---|---|
| Before, with SOURCE_SUSPECT | 46 / $49,169,395.71 | 2 / $20,278,054.31 |
| Before, without | 44 / $45,713,974.71 | 2 / $20,278,054.31 |
| **After, published** | **46 / $46,724,180.71** | **4 / $24,448,315.31** |
| After, internal | 48 / $50,179,601.71 | 4 / $24,448,315.31 |

How the published figures moved:
- **NAMED:** +$1,010,206.00 (Intermountain RHIT-08 $24,506.00, Renown Health Foundation RHIT-22 $985,700.00). The comparable before figure is the without-suspect one: 1,334 → 1,336 rows, $1,306,208,961.63 → $1,307,219,167.63.
- **POOL_NAMED:** +$4,170,261.00 (RHOAP-18 $3,772,261.00, RHIT-19 $398,000.00).
- **Rural cut (`R/03ar`):** 268 / $282,660,793.99 → **267 / $280,202,733.99**. Washoe Barton's FLEX-36 van ($2,458,060.00, CCN 291306) is SOURCE_SUSPECT and leaves the published cut.
- **New subtractable slices, all LOW:**
  - GENERAL_KNOWLEDGE: NV rows 105 and 112, $1,010,206.00.
  - Owner-ruling pool: NV rows 109 and 143, $4,170,261.00.

## Task 1: Nevada rulings (NV_BP1_FOLLOWUPS, RESOLVED)

The rulings are applied in `nv_apply_s102_rulings()` (`R/03u`), after `nv_apply_bp1()`. Each ruling is keyed on a page row and asserted against the awardee string and BP1 line at that row, so a reordered page fails rather than moving a ruling.

**(a) NRHP's RHOAP-18 (row 143, $3,772,261.00) and RHIT-19 (row 109, $398,000.00).** Coded PASS_THROUGH_DESIGNATED, POOL_NAMED_HOSPITALS, LOW. The intermediaries are Nevada Rural Hospital Partners and NRHP Foundation respectively.

**Vulnerability, stated on each row: these lines are weaker than NRHPF's.** NRHPF's R+R line names all 14 hospitals in its own service-area cell. These two lines do not:
- **RHOAP-18:** the service area is "All rural hospitals"; the project is "Support rural hospitals to build capacity to participate in multi-payer alternative payment strategies." No hospital is named.
- **RHIT-19:** the service area is "Lincoln, Lyon, Mineral, Humboldt Counties"; the project is "Cybersecurity for four rural hospitals through a shared CIO model and a pilot program with Grover C. Dils…". One hospital is named. The other three can be identified only by county.

Both lines describe a service NRHP delivers. §10.2's AHHA negative codes that shape IN_KIND_BENEFIT. A reviewer at CMS or an opposing stakeholder would press on that. The $4.17M can be subtracted by its basis text.

**(b) Intermountain and Renown are system parents.**
- Rows 105 (RHIT-08, $24,506.00) and 112 (RHIT-22, $985,700.00) move from §8's fallback / NON_HOSPITAL to HOSPITAL_OR_SYSTEM, DIRECT, NAMED_HOSPITAL. They are LOW, `basis_type = GENERAL_KNOWLEDGE`, with no CCN.
- Rows 31 and 70 were already hospital rows on session 49's general-knowledge answer. They now cite the ruling.
- Neither legal name has a Nevada CMS enrolment (session 101).

**(c) RWP-03 (row 90, $531,469.16).** It stays coded to the recipient NVHA lists, "Board of Regents, NSHE, UNR" (UNIVERSITY_OR_AHC, NON_HOSPITAL). "Banner Churchill Health" is recorded in a new `co_applicant` column with no dollars attributed. This follows the NY RCHI rule: participation is not receipt. It is not a multi-recipient field.

**(d) Published figures exclude SOURCE_SUSPECT rows by default.**
- A new helper, `rhtp_is_source_suspect()` (`R/utils_recipient_classification.R`), identifies the rows.
- `rhtp_hospital_dollar_partition(records, include_source_suspect = FALSE)` drops them by default.
- `R/03ar`'s rural cut drops them too, using the same helper.
- `R/03ap`'s union now carries `flag_reason`, so its partition reads the same rows.
- `nv_bp1_partition()$without` is the published figure and `$with` is the internal one. `R/03u --report` prints both, labelled.
- CLAUDE.md: the partition block, Deliverable 1's NV row and a standing rule were updated.

**(e) PROVISIONAL_SOURCE is collapsed into AMOUNT_PRELIMINARY.** The two definitions state the same condition:
- the source says the amount is not final;
- `amount_confirmed = No`;
- the figure is never dropped or replaced.

The one difference session 101 recorded is where the caveat is printed: a document note versus a column header. AMOUNT_PRELIMINARY already carries a document-level case, Indiana's recommendation letter. So the codes were collapsed:
- All 157 priced NV rows now carry AMOUNT_PRELIMINARY.
- The PROVISIONAL_SOURCE vocabulary row is kept and marked RETIRED, as AMOUNT_IS_POOL_NOT_AWARD was.
- `test_state_union.R` refuses any row carrying it.

**Queue.** `NV_BP1_FOLLOWUPS` is RESOLVED (owner, 2026-10-16). Point (5), NRHPF's award being 9× its request, is recorded only.

## Task 2: Hawaii probe and Routine

**The probe.** `RHTP_PROBE_ORIGIN=… Rscript R/03cd_hi_year1_awardees.R --probe`. It runs read-only through `rhtp_probe_run()` and the shared page watch.

| Page | URL | Trips on |
|---|---|---|
| `shpda` (subject) | health.hawaii.gov/shpda/rural-health-transformation-program/ | A new "(Notice of Award on … to …)" annotation, or one disappearing. A currency figure the archive lacks (an amount outside HANDS). The name tripwire |
| `rhtp_home`, `rhtp_funding` (subject) | rhtp.hawaii.gov, /funding-opportunities | The same three checks, plus a new award sentence ("awarded to", "award recipients", "notice of award", …) |
| `gov_news` | governor.hawaii.gov/newsroom/ | A new headline about RHTP, SHPDA, RVBI/RHIN or a Notice of Award (headline-link diff) |
| `doh_news` | health.hawaii.gov/news/category/newsroom/ | Same |

- **Baselines.** The `shpda` baseline is the extractor's own 2026-10-14 copy, so the probe and the extractor read the same bytes; it is still identical live. The other four were archived with `--fetch-probe` under `data/evidence/HI/probe/`. They were script-stripped, with a manifest recording both digests, and contain no credential-shaped strings.
- **The Stevens Amendment footer on rhtp.hawaii.gov.** It reads $188,892,439.75, which is Tier 1 (the anchor is $188,892,440). It is in the baseline, so it does not trip.
- **HANDS is not probed.** It is 403 here and would only ever log ERROR, which says nothing about the state.
- **Live run** (interactive, 18:59Z): UNCHANGED on all five pages.
- **Fixture tests** (`test_03cd`) cover each counterfactual: a new NOA, a removed NOA, a priced NOA, an award sentence, an RHTP headline versus an unrelated one, and the name tripwire.

**The Routine.**
- Runner: `session_01BddosbdNKAgH1S8vFpXvFt` (`env_01RnpqJ1D6wFAaRMvFu43oV3`, claude-sonnet-5, auto, `main` as source and outcome, no seed).
- Routine: `trig_017PbAESTaaMfYZ3nKcS3j1m`, **Monday 18:30Z** (08:30 HST).
- Prompt: `v4/HI.txt`, derived from a new `v3/HI.txt` (IA's prompt with the state, runner and script changed). The text sent to `create_trigger` is the file byte for byte; `--check` passes for 41 states.
- Registered in `config/routines.csv`, `logging_since 2026-10-16T19:01:00Z`.
- **The first firing is Mon 10-19 18:30Z. Merge before then**: `main`'s R/03cd has no `--probe`.

## Task 3: Friday check-in

### CMS (10-15 13:21Z run): no Year 2 announcement

- **The run logged CHANGED:** "new states: NE; new releases in listed states: 2 (DE MO)". It committed `data/raw/cms/2026-10-15/` (`d9970b9`).
- All three releases say "one part of the larger overall funding amount awarded to <state> for **fiscal year 2026**".
- No release, listing page or the medicaid.gov resources page mentions 2027, Year 2 or Budget Period 2.
- **Live today (read, not archived):** three newer FY2026 releases. They are Montana EMS, **Ohio $92M** ("Coordinate Rural Hospital Networks, Improve Maternal Care…") and **Texas $78M**, and each says "fiscal year 2026". medicaid.gov's resources page shows no FY2027 either. The Monday CMS run will archive them.

### Louisiana (10-16 14:07Z one-time check)

It fired into session 99's session and reported:
- **SR 198's report is not posted.** LDH's legislative-reports list, the RHTP page and LDH news carry nothing.
- The bill page is unchanged; its last action is still "sent to the Secretary of State" on 6/2.
- It is UNKNOWN whether LDH transmitted the report only to the Senate and the Legislative Research Library (R.S. 24:772).
- **The six Oct. 2 programmes.** Every page still reads "Notice of Intent to Contract Announcements: October 2, 2026", and none names a recipient. The Rural Clinician Credit Bank reads "Completed" for both notices and denials, as already archived.
- The check's interactive log line was pushed to `claude/inspiring-bell-qt78fl`, not `main`. It was cherry-picked here.

### New runners and old Routines

IN GROW, TX and WV logged on their new ids on 10-16:
- IN `trig_01KZZ2…` at 09:51Z
- WV `trig_01HATr…` at 11:36Z
- TX `trig_01PMLQ…` at 13:27Z

The old ids were read with `get_trigger` (disabled, last fired 10-09) and then deleted: `trig_01UZ5QWh8No7uiRBz9S8T23C` (IN), `trig_017U35M4eGiGcnhPMeoKGzFy` (TX) and `trig_01SfWj74rQ4kdeHcdNckS4Yn` (WV). Each is recorded in `routines.csv` `old_deleted` as `<id>@2026-10-16`.

### Probe log, 2026-10-14 to 18:12Z 10-16, and coverage

**Coverage check:** "176 due firing(s) since the logging fix; all logged except 4 EXPLAINED miss(es)".

Each CHANGED and TRIPWIRE page was diffed live against its archive with that probe's own reducer, read-only. Four agents did the diffing in parallel; nothing was written to `data/evidence/`. **Nothing was extracted.**

**TRIPWIREs:**

| State, run | Page | What it is |
|---|---|---|
| MO 10-14 | program_page | Read in session 101: Kids Win Missouri and MU Sinclair CNM, both non-hospital |
| CA 10-14 | calrht | Read and re-based in session 101: the link to CMS's obligation report |
| NEWSROOM 10-15 (DE) | news | **Not an award made.** "Delaware Announces RHTP Funding to Strengthen Physician Workforce" (10-14). An agreement with Jefferson's Sidney Kimmel Medical College gives "two $70,000 educational awards" to students. A "$1.24 million" housing and relocation BUDGET covers residents at Bayhealth, Beebe, ChristianaCare, Nemours and TidalHealth, who are training sites, not recipients. "Participating institutions are currently marketing the programs." Tier 2; no hospital money |
| NEWSROOM 10-15 (MD) | governor | **A Tier 3 roster with hospital recipients, not extracted.** "$16.4 million in grant awards" (10-14). Labor's page reads "In October 2026, MD Labor awarded a total of $16.4 million to 39 organizations." Hospital-shaped rows: TidalHealth Peninsula Regional ×3 ($843,816), CalvertHealth Medical Center $300,000, UM Charles RMC $500,000, UM Shore $499,898, UM Upper Chesapeake $499,999, Frederick Health Hospital $430,317, Meritus Health Foundation $500,000. CalvertHealth Medical Group ($492,093) is a physician group. **A first parse found 38 rows / $13,965,196, $2.43M short of the headline: reconcile before extracting** |
| OK 10-15 | funding recipients | **Two things.** The trip itself is a stale list: `OK_PENDING_OPPORTUNITIES` (`R/03t` lines 213–216) still holds BHI and EMS/CP, which session 99 extracted. But the page (Last Modified 10-15) has **gained an RRR row: "SSM St. Anthony Shawnee Cancer Center, $1,623,498.82"**, a named, priced hospital award not in `ok_year1_rrr_awardees.csv`. And **City of Wewoka (Fire Department) was removed from EMS/CP vehicles**, which looks like a withdrawal |
| MS 10-16 | funding, home | **Tier 2 only.** A new "Electronic Health Records (EHR) Replacement for Small Rural Providers Program": $9.5M, applications 10-21 to 11-23, awards February 2027. Eligibility includes hospitals and CAHs, which is eligibility, not receipt (§0.3). The Innovative Pilot documents are posted ($16M, capped at $2M per entity, awards January 2027). **WEI and EmPATH moved to "Closed Funding Opportunities" with no awardee named.** The home page change is layout plus a survey notice |
| WI 10-16 | dhs_rhtp, dhs_solicit | Noise. `dhs_rhtp` is a breadcrumb/menu change ("Last revised October 13, 2026"); all four programmes still read "plans to award". `dhs_solicit`: the four new RFAs are Title V MCH or Title X money with no RHTP wording |

**ERRORs (access, never about the state):**
- **IA 10-15 15:24Z:** the runner fired against `main` before session 101's probe merged. It logged an ERROR line by hand ("no --probe branch").
- **MS `dom_completed` 10-16:** medicaid.ms.gov is down ("Website outage notice … temporary outage affecting our web-hosting vendor").
- **ME ×3 10-16:** maine.gov's CloudFront returns 403 to R/03aa's agent. It serves the project's other honest agent, `Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; +https://www.aha.org)`, consistently. Switching is an owner call under §3. The same run also logged `UNCHANGED,(all)` beside the ERRORs, which contradicts them.

**CHANGED with no trip:**

| State | Page | Reading |
|---|---|---|
| NE 10-14 | program_page | Noise: DHHS Medicaid side menu |
| NY 10-14 | press_index | Noise: measles, flu, breast-cancer items |
| NY 10-14 | scr | Noise: counters |
| LA 10-14 | programme, funding, leg_reports | Noise: LDH mega-menu. No SR 198 |
| SC 10-15 | programme | Noise: a "FAQs" link |
| WA 10-15 | bids | Noise: procurement turnover. No rural-hospital bid winners |
| CMS 10-15 | newsroom+medicaid | Read above (FY2026) |
| AL 10-15 | governor | Noise: hurricane, heritage month and ALDOT headlines |
| CT 10-15 | opm | Noise: CTsource bid link |
| CT 10-15 | dmhas_rfps | A new opioid Recovery Centers RFP (not RHTP-linked) and a housing addendum. **The REST row still shows no award** |
| VA 10-16 | ways_to_apply | **Tier 2 status only:** CareIQ, Career Pipelines, Food is Medicine and Active Kids went TBD → Open; Mobile & Hybrid Care, Community Paramedicine and Innovative Maternal Care went Open → Closed. No recipient |
| **WV 10-16** | **news** | **Unextracted award releases that the probe passed as CHANGED.** Its headline filter wants "award" or "Rural Health Transformation", and these headlines say "$2 Million Investment…" and "$500,000 to Strengthen…". 10-14: WVU Eye Institute **$2,000,026** (Connected Care Grid); Potomac Highlands Guild **$500,000**. 10-13: WV Primary Care Association **$1,656,432** and Monongahela Valley Association of Health Centers (an FQHC) **$500,000** (Provider Productivity Support Fund); Ascension Recovery Services **$1.5M** (Health to Prosperity). Lauren's Wish's $211,700 is ARC money, not RHTP. None is self-evidently a hospital. **The WV probe needs a name check on the news index (§2.3), not a longer phrase list** |
| TX 10-16 | six pages | Noise: a template change ("Request for Application" → "Open Enrollment", plus a "Close" button). No "Awarded Grant Information" |
| NEWSROOM 10-15 | 14 index pages | 13 are routine news; ID:dhw is furniture only. **But TX hhsc and TX governor carried, after the sweep ran, "Gov. Abbott, HHSC Announce Recipients of $78 Million in Rural Texas Strong Grants" (10-15)** |
| MS 10-16 | gov_newsroom | Noise: appointments and tourism |

**Texas's first Rural Texas Strong roster.** It surfaced in the NEWSROOM reading, after the sweep had run.
- HHSC "plans to award $78 million in Rural Texas Strong grants to 216 rural health care providers". The footer reads "The $78,089,434.73 is a portion of the $281,319,360.67 first-year award".
- The xlsx (~283 rows) is headed "Intent to Award status as of 10/8/26. A grant is not considered awarded until a contract has been fully executed". Its "Awarded (Contract Fully Executed)" column reads "No" on the rows read.
- It names hospital districts.
- TX's `INVESTIGATED_NO_LIST` is therefore stale. Extraction is an owner decision. The rows would be intents, like AR r1 and OR.

## Suite

Full suite (`Rscript tests/run_tests.R`, 2026-10-16, after the last code change): **0 failed, 1 expected skip** (the CMS first-run branch). The first full run (after the code changes, before the pins) failed only on figure pins in `test_03ap`, `test_03ar`, `test_03bj`, `test_state_union` and `test_03u`. Each was re-pinned with a session-102 layer restored first, so every older figure is still checked.
