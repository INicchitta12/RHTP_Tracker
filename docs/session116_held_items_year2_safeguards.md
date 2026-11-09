# Session 116 — Held items, Year 2 safeguards, runners (2026-11-09)

Branch `claude/sweet-euler-3eku7i`, started from `main` at `054146e` (session 115, PR #122, merged).

## Hospital figures, before and after

| Figure | Before (session 115, 11-09) | After (session 116, 11-09) | Change |
|---|---:|---:|---:|
| Hospital best estimate (summary layer) | $2,075,115,137.63 | $2,075,115,137.63 | $0 |
| Strict NAMED_HOSPITAL | 1,954 / $1,797,619,954.62 / 37 | 1,958 / $1,797,619,954.62 / 37 | +4 rows, $0 |
| POOL_NAMED_HOSPITALS | 10 / $86,895,779.43 | unchanged | 0 |
| POOL_UNNAMED_HOSPITALS | 6 / $79,214,848.17 | unchanged | 0 |
| Award total | $4,559,997,148.39 | unchanged | 0 |
| Named hospital recipients with no amount | 297 | 301 | +4 (IA) |
| Rural cut | $566,590,756.19 | unchanged | 0 (the IA rows carry no CCN on the row) |

The only row movement is Iowa's four Round 2 hospital intents, all at $0. `year1_summary_2026-11-09.csv` and
`output/year1_summary_2026-11-09.xlsx` are rebuilt; `test_08` is re-pinned (IA +4 rows, no dollar change).

## Task 1 — Owner rulings on session 115's held items

**(a) NC "List of projects – Year 1": a plan, not awards.** `R/03cr_nc_year1_budget_plan.R` writes
`data/reference/nc_year1_budget_plan.csv`: 134 lines, $213,008,356.47 as printed, which is NC's allotment to the cent.
- It has the shape of `ks_ebp_participants.csv`. It has no `amount` column: the figure is the printed text in
  `budgeted_amount_text`. Every row has `award_made = No`. The file is never in STATE_FILES.
- The script asserts the page's own words: "Budget amounts shown are subject to change based on program progress and
  needs".
- Each line is typed **for reference only**, on CMS NC enrolment where an exact legal name matches, and on the §8
  classifier or a hand note otherwise. Hospital-shaped lines:
  - UNC Health: 9 lines, $21,528,215.99. Typed as an AHC system string under ruling (a), LOW.
  - Cumberland County Hospital System, Inc.: $300,000, exact legal name, CCNs 340028/342014.
  - FirstHealth of the Carolinas: $250,000, CCNs 340115/341303.
  - Total $22,078,215.99, budgeted.
- Each of UNC Health's eight "ROOTS Hub Lead" lines carries a `pass_through_note`. The core-funding line carries the
  owner's note: "held for a §10.2 pass-through ruling WHEN AWARDED".

**(b) IA Combat Cancer Health Hubs Round 2 NOIA (COMPADM26008, 2026-08-12), extracted.** `R/03cs` writes
`ia_combat_cancer_r2_awardees.csv`, a new file in STATE_FILES (`IA_CC_R2`) and in R/03aw.
- It holds four hospital intents at $0: Methodist Jennie Edmundson (160047), MercyOne North Iowa Medical Center
  (160064), UnityPoint Health – Des Moines (160082) and MercyOne Des Moines Medical Center (160083).
- Each is typed on the legal name Iowa prints before "DBA", which is the exact enrolled ORGANIZATION NAME (punctuation
  aside). They are MEDIUM, ORG_WEBSITE, with the CCN in the basis.
- Each carries a CODED HOSPITAL summary call.
- The footer, "approximately $209,040,063.71", is asserted as Iowa's allotment. A test proves the footer is refused as
  a round total.
- It is a separate file, so R/03z's eleven-notice invariants do not move.

**(c) CA probe re-based on the `/calrht/` pages.** The four probe pages are archived 2026-11-09. The old copies stay on
disk and in the manifest.
- **Diffs read:**
  - HCAI's 11-07 redesign: titles now read "… Program (CalRHT)", and a feedback-survey block was added.
  - The award sentence is re-set as "$233.6 million Awarded to California for Federal Fiscal Year 2026".
  - The funding page's FM-OB "Coming Soon!" labels became a webinar link.
  - The updates page gained a "part of the state's $233.6 million total CalRHT award" clause.
  - The roster is unchanged: 108 / $138,464,043.97.
- **Footer.** A new shared `rhtp_footer_class()` (utils_config) classifies a footer figure as `ALLOTMENT`,
  `ALLOTMENT_PLUS_YEAR2_INITIAL` (the allotment plus exactly $100,000,000) or `OTHER`.
  - `rhtp_assert_footer_not_allotment()` now refuses the cumulative figure as a SOLICITATION too.
  - CA's footer check accepts $333,639,308.46 only as BP1 + BP2, and stops on any other figure.
  - Fixture tests cover both paths.
- **Anchor and pin.** The name-scope anchor allows "Program" and the survey block. The programme page now ends at
  "Footer Column 1 Bold Links".

**(d) LA 11-05 Advisory Council "Budget Period 1 Data Report on Awards".** It is recorded in `la_year1_status.csv` only.
- A new `bp1_report_2026_11_05` column holds the line for each of the eight competitive programmes: received,
  requested, awarded, obligated and recipient types.
- One summary row (stage `REPORTED_COUNTS_NO_NAMES`) records:
  - $107,823,428 obligated competitively.
  - 69 hospital-type awards, named nowhere.
  - $69,375,858 of "other agreements" whose vendors are named; none is a hospital.
- Every figure is asserted against the deck. No amount column and no bucket: this is the treatment the Credit Bank
  breakdown gets (§7).
- New facts from the deck:
  - The Credit Bank now reports 59 awards and $13,385,937 obligated, against 53 / $12,701,996 in September.
  - The deck footer prints $308,374,447.57, which is the allotment plus $100M.

## Task 2 — Runners

**CA moved.**
- New runner `session_01Y1P5eSjLX9Hv4Pk8vjKXvj`, Routine `trig_012VpnHG4hW6pg4sjeFhk2BC`, same cron (`0 17 * * 3,6`).
- The old `trig_01JEYQK9ZNMVpe27H19DFjzX` is disabled and chained in `routines.csv`.
- The prompt matches the old one apart from the runner id:
  - After the id substitution the diff is empty (3 occurrences).
  - `routine_prompts_worktree.R --check` matches for 43 states.
- The new runner's first firing is Wed 11-11 17:00Z. Coverage passes: 368 due, all logged except 7 explained.

**NY's old Routine deleted.** `trig_012g3adVBX9KEgDt9XiVi2tU` was confirmed disabled before deletion, and is recorded in
`old_deleted` as `@2026-11-09`.

**Runner context** (`get_session` `used_tokens`):
- MN `session_01YMHRbw9ToET8yfpwSqg5bu`: 652,461. Unchanged since 11-06, its last firing.
- DE `session_018HApZfEPxtnu1hSndHkwQy`: 608,387. Read after its 11-09 11:42Z firing; it has auto-compacted before
  (`after_boundary` set).
- Neither is above the 700k line. MN is the one to move next.

## Task 3 — Probe log since 11-09

Twelve lines on `main` dated 11-09 (to CT's 15:42Z firing). **None moves a hospital dollar, and nothing over $25M is
held.**

| State | Line | Read |
|---|---|---|
| CA | TRIPWIRE (interactive 14:14Z) | The redesign's re-set award sentence. Fixed by the re-base (Task 1c). |
| CO | TRIPWIRE `programme` | Not a recipient: "Upcoming Events Grantee Kickoff Meetings: November 12, 2026 … Invitations will be sent directly to grantees". An events heading welded to "Rural Healthcare Providers". Trips until a human re-bases. |
| CT | CHANGED `opm`, `dss_press`, `dmhas_rfps` | OPM bid-list dates rolled; two DSS waiver notices (11-03); DMHAS RFP addenda. Noise. |
| DE | CHANGED `programme` | Stale 09-03 baseline (read in session 115). |
| KS | ERROR | KDHE 403 (our access). |
| AK, CMS ×2 | UNCHANGED | |

No priced state-source Year 1 roster appeared, so nothing was extracted under the pre-approval. HI (18:30Z) and KY
(19:30Z) fire after this write-up; NEWSROOM's 16:50Z line is read below if it arrived before the suite finished.

## Task 4 — Rebuild

Figures moved (IA row counts only), so the chain re-ran:
1. `R/03aw --build`.
2. `R/03ar --build`, re-pinned to 1,958 rows.
3. `R/07 --apply`.
4. `R/08 --build`.

The partition-history chains in `test_03ap` and `test_03bj` back the four IA rows out before session 115's step.
CLAUDE.md's Deliverable 1 gains an `IA CC R2` row, and the partition block reads 1,958 (internal 1,960).

## Task 5 — Year 2 safeguards (no Year 2 extraction)

**(a) `budget_period`.**
- `config/budget_period_registry.csv` lists all 70 award files and 27 status tables, each at period 1.
- `rhtp_budget_period_stamp()` writes an integer `budget_period` and keeps any text the builder wrote in
  `budget_period_text`. It is run by `R/07_summary_calls.R --apply`, which stays the LAST overlay.
- The stamp changed 96 files. A cell-by-cell check against HEAD found no other cell moved.
- **Refusals:**
  - The stamp refuses a file that is not registered, so a Year 2 roster can never default to 1.
  - It refuses a file registered 1 whose builder text names a later period.
- **Readers:** `rhtp_year1_only()` filters R/08, R/03aw and R/03ar. It refuses a table without the column.
- **Partition:** `rhtp_hospital_dollar_partition()` drops any period-2 row.
- **Builder comparisons:** `rhtp_strip_summary_calls()` undoes the stamp, so committed-vs-built comparisons still hold.

**(b) FY2027 and the signals.**
- `data/reference/cms_fy2027_allotments.csv` is empty, with FY2026's shape (`fy2027_*` column names).
- `rhtp_load_fy2027_allotments()` enforces the following:
  - the exact columns;
  - all 50 states at once;
  - CMS URLs only;
  - a refusal of a copied FY2026 table.
- The FY2026 file's SHA-256 is pinned in a test.
- `data/reference/year2_signals.csv` holds six signals, each quoted from an archive and asserted. Every row is
  `enters_total = No`.
  - LA's deck sentence on the BP2 award.
  - The LA footer ($308.4M).
  - NCDHHS: "All states will receive an initial $100 million award".
  - The CA footer ($333.6M).
  - **The MN footer ($293,090,618.14).** Session 115 called this a "$100M publisher defect". It is the same
    allotment + $100M pattern.
  - MT: "CMS will notify states about their Year 2 awards later in November". This is new: on 10-30 CMS told states
    that Year 2 is delayed.

**(c) Probes: a new verdict, `YEAR2`.**
- **What never trips:** "Year 2", "Budget Period 2", "BP2", "second budget period" and "FY2027" never trip as Year 1
  awards in the shared tripwires:
  - `rhtp_watch_forbid()`
  - `rhtp_watch_forbid_new()`
  - the name tripwire.
- **What logs YEAR2:** award language or a newly named organisation in a Year 2 context logs `YEAR2`. It is held:
  logged, not thrown, so the run still publishes.
- **Tests:**
  - Kansas's Year 2 RPGP/CAP solicitation text (KDHE, as rendered 10-07) does not trip.
  - Iowa's Year 2 award-window sentence logs YEAR2, not TRIPWIRE.
  - A Year 1 roster still trips.
- **Limit:** a state probe's own bespoke phrase checks do not use the shared helpers. A Year 2 sentence that trips one
  still logs TRIPWIRE. Read it as not a Year 1 award.

**(d) The CMS monitor.**
- **National events:** a release naming no single state is now one row in `data/reference/cms_national_events.csv`.
  The file is seeded with the six existing national releases.
  - A NEW Year 2 national release logs exactly one `YEAR2` row on page `national_year2`.
  - A multi-state Year 2 headline is a national event. It is no longer a refusal that would stop the run.
- **Volume:** the announcements sanity ceiling is $10B per budget period the list spans (BP2 from 2026-10-31). A
  Year 2 wave of state releases therefore cannot fail the assertion and block the monitor's own commit. A $19B
  Year-1-only list still fails.

**Finding while seeding.** CMS's 10-22 Alaska release ("… for Rural Alaskans") names no state the newsroom parser
recognises, so the newsroom side files it as national. The medicaid.gov row still carries it as AK, so no state row is
lost.

## Suite

See the commit that records the run.

## Next

- **Merge before Wed 11-11 09:20Z** (ND). Never Mon/Thu 13:00–14:00Z. CA's new runner first fires Wed 11-11 17:00Z,
  and needs `routines.csv` and the re-based CA baselines on `main`.
- **Delete by hand:** `claude/festive-cori-sm3p3c` (session 115).
- **Delete `trig_01JEYQK9ZNMVpe27H19DFjzX`** (old CA) once the new id logs on `main`.
- **Move MN** (652,461) next.
- **Re-base CO `programme`** after reading: grantee kickoff and events block, no recipient.
- **Year 2:** when CMS publishes FY2027 figures, fill `cms_fy2027_allotments.csv` (all 50, CMS URLs), register any Year 2
  file at period 2, and keep Year 2 out of every Year 1 table. Nothing is extracted until the owner lifts the hold.
