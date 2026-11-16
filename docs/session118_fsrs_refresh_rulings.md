# Session 118 (2026-11-16): FSRS refresh (incl. Alabama), held rulings, SC consultant obligations, runners

**Branch:** `claude/eloquent-fermi-5w6php`, from `main` after PR #128 (session 117).

## Report first

### Hospital and vendor figures, before (session 117's 11-16 build) and after (this session's 11-16 build)

| Figure | Before | After | Change |
|---|---:|---:|---:|
| Awards published (national) | $6,194,112,121.67 | $6,404,664,055.52 | +$210,551,933.85 |
| Hospital best estimate | $2,470,690,310.59 | $2,533,593,302.39 | +$62,902,991.80 |
| Strict NAMED_HOSPITAL | 2,199 / $2,167,733,246.58 / 42 states | 2,268 / $2,204,266,238.38 / 42 states | +69 / +$36,532,991.80 |
| POOL_NAMED_HOSPITALS | 10 / $86,895,779.43 | 11 / $96,565,779.43 | +$9,670,000 (WA) |
| POOL_UNNAMED_HOSPITALS | 6 / $79,214,848.17 | unchanged | — |
| Hospital % of awards (national) | 39.9% | 39.6% | |
| ≥50% subset row | n = 32; $2,129,504,777.63; 41.2% of awards; 33.1% of allotment | n = 35 (+MN, NM, WA); $2,317,774,646.43; 41.6%; 33.0% | +$188,269,868.80 |
| Rural cut | 754 / $671,551,567.78 | 793 / $696,097,519.78 | +39 / +$24,545,952.00 |

The internal figure with SOURCE_SUSPECT rows back in is NAMED_HOSPITAL 2,269 / $2,206,724,298.38 (never published alone).

**Verified vendor figures did not move:** award $167,506,827.60 (PUBLIC $42,750,000; NON_PUBLIC $124,756,827.60), intent $48,233,747.84, contract maximum $25,965,898, obligation $2,205,500. Amount types are never added. Verified list: 39 cases; 183 drops (+8: HD72–HD79).

### Change by state (hospital best estimate, largest first)

| State | Awards | Best estimate | Strict named | Why |
|---|---:|---:|---:|---|
| MN | +$66,242,385.00 | +$48,682,860.00 | +$48,682,860.00 | 78 new FSRS rows; 42 hospital rows (CAH direct allocations), $18.4M of them on address bridges (under the $25M hold line) |
| IN | $0 | +$16,700,000.00 | $0 | GROW Region 5 now 7 typed hospitals of 13 members, a strict majority: HOSPITAL (ruling d) |
| CT | −$7,962,649.68 | −$13,116,917.00 | −$13,116,917.00 | Vassar Health's FSRS $13,116,917 is CT row 2, Sharon Hospital ($13.12M rounded): counted twice since session 116c, now paired (independent check D6) |
| WA | +$9,670,000.00 | +$9,670,000.00 | $0 (+$9.67M POOL_NAMED) | HCA's 28-hospital pool (ruling c) |
| NE | +$9,827,430.86 | +$2,048,392.80 | +$2,048,392.80 | the 21 held extras applied (ruling a) less Alegent Creighton (same amount on roster) and two Memorial pairs found by the independent check |
| VT | −$2,000,000.00 | −$2,000,000.00 | −$2,000,000.00 | VT_FSRS's Grace Cottage $2,000,000 = VT roster row 41; held (published-roster rule + CCN guard) |
| TN | +$2,662,479.49 | +$643,500.00 | +$643,500.00 | FSRS pricing; the 10-31 HART filings are Year 2, held |
| OK | +$3,029,325.97 | +$275,156.00 | +$275,156.00 | Northeastern Health System ambulance priced ($311,750); INTEGRIS Miami's $36,594 was Baptist's microgrant (D9), unpriced |
| NM | +$130,778,396.21 | $0 | $0 | Accenture LLP $128,979,618.21 (ASO, VENDOR_OR_CONTRACTOR) and EPCOG; the 11-03 hub filings are Year 2, held |
| NC, DE, WV, AL, KY | small / $0 | $0 | $0 | NC two UNC contracts and a YMCA; DE and WV duplicates paired; AL paired only; KY Martin County at $0 |

### Alabama's pairing
- 171 FSRS subawards, $197,899,829, the state's first filing.
- 97 pair exactly ($71,382,445.00) and 70 pair at another amount ($122,233,901.64), after 40 hand-read crosswalk entries (legal name ↔ DBA on the roster). Roster rows: round 1, 75 EXACT, 57 DIFFERS, 1 NOT_FOUND, 5 with no filing; round 2, 22 EXACT, 12 DIFFERS. `fsrs_amount` and `fsrs_match` are on every paired row; no AL dollar moved.
- Held (published-roster rule): 4 subawards, $4,283,482.12 — HH Health System–Marshall $2,809,729.12 (extra, a programme the roster does not list for it), Saint Vincent's Blount $839,753, Geneva County HCA $391,000 and Niel C. Rasmussen, MD $243,000 (no exact roster name).
- AL stays at 97.6% of its allotment ($198,539,348 of $203,404,327).

### Independent check (separate agent, had not seen the apply)
Found and FIXED before the final push:
1. **Budget period.** 44 rows dated after 2026-10-30 had been written as Year 1 (TN 10-31 HART round, NM 11-03 hubs, IL Morris 11-02): $13,536,661.77, $7,144,265.87 hospital. R/09b now holds every FSRS action dated after Budget Period 1 as `BUDGET_PERIOD_2_HELD` (Year 2 is safeguards only).
2. **Duplicates (12 pairs), now in `config/fsrs_subaward_pairings.csv`.** New this session: OK Creoks $4,000,000 (= OK RRR row 4), Pafford's three July microgrants re-priced onto an EMS/CP row ($194,151.86), Oologah-Talala, LifeNet. Older: **CT Vassar/Sharon Hospital $13,116,917 (hospital, counted twice since 116c)**, NE Memorial Health Care Systems $339,998.92 and Memorial Community Hospital $152,195, OK INTEGRIS Miami $36,594, DE Southbridge/Henrietta Johnson $1,290,549, WV WVU Research Corp/Ascend WV $2,399,990, OK Wonderfully Made/Works Wonderfully $50,000. Hospital money removed: $13,645,704.92.
3. **CCN.** The FSRS typing now prefers a hospital's own CCN over its swing-bed or psychiatric-unit CCN (24Z380 → 241380).
- **Allotment:** no state over. Closest: HI 99.98% ($31,270 of headroom, all FSRS rows), UT 98.65%.
- **Spot check (15 new hospital rows):** 9 PASS; the 6 FAILs were all post-10-30 dates, now held.
- **Left for the owner (UNSURE):** CT DMHAS $4,000,000 and SDE $617,985 second actions (increment or revised total?), CT's negative actions held while positives are written (DEEP −$1,219,235); MN University of Minnesota two $997,498 subawards; OK SWOSU $99,997.96 vs roster $54,997.96; KS DCF/KCDD $1,460,000. MN Pipestone County Medical Center ($1,697,594, typed not-hospital; CMS 241374 one block off) and Murray County (Slayton) may be hospitals: not promoted.

### The rulings
- **(a) Completed-state FSRS hold.** `completion_basis` on `year1_completion_status.csv` (PUBLISHED_ROSTER: AL AR FL GA ID UT VT WY; FULL_OBLIGATION: NE SD WV). Published-roster states hold every unpaired FSRS row (extra or new); full-obligation states apply extras under the pairing and duplicate checks with an allotment cap (`fsrs_allotment_cap()`). Rule in CLAUDE.md §7. NE's 21: 20 applied ($9,607,995.15; hospital Antelope Memorial $1,571,000, St. Mary's Community $729,610, Box Butte General $239,976.72 = $2,540,586.72), Alegent Creighton $711,629.63 held (same amount as a roster row). Caveat: UT's and VT's own COMPLETE sentences are obligation statements; the owner's classification is applied as given.
- **(b) Tennessee.** `R/03cv_tn_multiyear_roster.R` → `tn_multiyear_awards_or_requests.csv`: 138 five-year "Amount Awarded or Requested" lines, $422,241,081.71, a NON-AWARD file (never in STATE_FILES, no amount column, not registered for a budget period). Year 1 split searched (release, Project Grants page live 11-16, RHTP FAQ): none published. Reference typing on CMS TN enrolment: 19 hospital lines / $79,977,648.91 (five-year), system parents (Covenant $24.4M, Ballad, Methodist Le Bonheur) not typed.
- **(c) Washington.** One POOL_NAMED_HOSPITALS row at $9,670,000 ("Estimated amount", AMOUNT_PRELIMINARY + AMOUNT_ROUNDED_IN_SOURCE) and 28 hospital rows at $0 on CMS WA enrolment (17 exact, 11 LOW bridges; Skagit Regional Health holds two CCNs, none on the row). WA stays PARTIAL.
- **(d) Indiana GROW.** CONFIRMED a state removal, not a page error: the 11-16 page re-publishes every region table in a new order, region figures unchanged, no name added, the ten missing at scattered positions (Region 2 rows 5, 11, 13, 14, 21–23; Region 5 rows 1, 13, 16). File 186 → 176 rows; hospital rows 44 → 42 (Hamilton Center, Bluffton Health System). Region 5 → HOSPITAL (+$16.7M best estimate). **Counter-evidence, recorded on the status table:** Indiana's own FFATA filings still carry current subawards to five of the ten ($695,228.48), including West Central Indiana EDD ($176,080.16, Region 5): with it, Region 5 is a 7-of-14 tie (NOT_HOSPITAL).
- **(e) Kentucky.** Martin County Health Department, Big Sandy RCH Hub Lead, row 3 at $0, LOCAL_GOVT, on FHKY's page (archived 11-16); R/03af's RCH page re-based.
- **(f) Vermont.** `VT_MOUS` (GMCB $2,635,000, DVHA $402,500) excluded by legal-column prefix and amount; an unknown MOU-shaped row stops the build. Tested on the archived 11-12 list (242 rows; 240 award rows equal the committed file).

### Task 3: South Carolina consultant obligations
`data/reference/contracts/sc_contracts.csv` from "SC RHTP Year 1 Annual Report" (archived 11-16; obligations as of 7/31/2026), source type `STATE_REPORT` (new vocabulary code), amount type obligation:

| First-tier entity | Obligation | Purpose (Use of Funds) | V1–V9 |
|---|---:|---|---|
| Milliman, Inc. | $10,000,000.00 | rate methodology for community paramedics | V1 FAIL (HD73) |
| SCRA | $5,025,452.32 | pass-through to Tech Catalyst Fund subrecipients | V1 FAIL (HD75) |
| BCG | $5,000,000.00 | comprehensive rural health assessment | V1 FAIL (HD72) |
| BDO Government Services | $3,990,000.00 | TA and compliance monitoring | V1 FAIL (HD74) |
| Slalom | $2,079,813.31 | transition plan, dual population | V1 FAIL (HD76) |
| SCDHHS | $569,133.31 | state agency operations | not a vendor |

Every firm passes V2–V5, V7, V8; V6 cannot be shown (no FSRS record); all fail V1, because an annual report to CMS is not an admissible source class (session 116e's HD29 Colorado precedent). **No verified vendor dollar moved.** The report itself says "no subaward agreements executed as of 7/31/2026". Admitting annual reports under V1 would add $26,095,265.63 of consultant obligations: an owner call.

**Also read under V1–V9 (new FSRS out-of-state ≥ $1M):** NM ACCENTURE LLP $128,979,618.21 — HD77, V4: "ASO support … fund administration, contract and subaward administration … payment preparation" does not say whether the money is Accenture's fee or subaward money it disburses; **owner ruling needed**. AL Ivy Creek Healthcare (HD78, a hospital), IN American College of Lifestyle Medicine (HD79, the purpose text is another organisation's project).

### Task 4: runners and Routines
- MO → `session_01Y1P5eQqPMWAuDb6cFQsPyv`, Routine `trig_012sTvWV1mD7EMnP2kLjci6r` (Wed 15:00Z); NEWSROOM → `session_01Y1P5eQF191xgxPjtLJryoJ`, `trig_018XcygicsAyLfgdhgjE7uDU` (Mon/Thu 16:50Z). Prompts identical to the committed v4 apart from the runner id (3 occurrences each, checked by back-substitution). Old ids disabled and chained.
- CMS and MN successors have not fired. A one-shot check-in (`trig_01SdoPUKsfxnhsEkPE8nhkNt`, Fri 11-20 19:40Z) deletes the old CMS, MN, MO and NEWSROOM ids once each successor has logged on main.
- Runners above 600k (`used_tokens`, 11-16 17:45Z): MO 690,141 (moved), IN 636,823, SC 636,457, MT 630,182, LA 628,710, DE 624,338, KS 613,912, NC 600,412. NEWSROOM read 232,889 (auto-compacted since session 117's 676,717; moved anyway as asked). Next: CT 597,053, ID 587,409.

### Task 5: rhtptracker.com LEAD check
`R/03cw_rhtptracker_leads.R`: diffs the sitemap (719 URLs) and the 36 `/states/<ST>/awards` pages' official (.gov/.us) links against the archive `data/evidence/leads/rhtptracker/2026-11-16/` (third-party baseline, PROVENANCE.txt). A new page or link logs a **LEAD** row (new verdict, logged never raised) carrying the state, the page and the official link; every currency figure is stripped. Never reads /api/, /reports/, /auth/. Own runner `session_01Y1P5eSuHK9r2bFBwV49Bs8`, Routine `trig_01FsufuT9voRgAhvSzYQpUMk` (Fri 20:23Z, first 11-20), registered in `config/routines.csv`. Dry run today: UNCHANGED.

### Task 6: probe log since 11-16
Nothing moves a dollar. TRIPWIRE: CO `programme` (BY1 documents, kickoff block; re-based session 117 after this run), CT `programme`/`documents` (menu), NEWSROOM DE (physician workforce, known since session 102), ID (Governor's 10-28 release points to the extracted "as of Oct. 16" list, docid 37915; it says "$186 million", the list prints $180.7M incl. $22.9M of MOA/MOU), TX (the $87M/$8M releases, lists already extracted through 11/12). YEAR2: CMS national Year 2 awards (held). ERROR: KS KDHE 403. No VENDOR or LEAD rows. Unexplained CHANGED: NEWSROOM indices (AZ, FL, IA, MN, MT, NE, NJ, NV, UT, MD) and DE `programme` — headline-level, read, nothing new priced.

### Not done / for next session
- **`vendor_flags.csv` is session 116b's snapshot** and was never rebuilt after FSRS became an award source; `R/09 --build` now stops (Guidehouse NM override sees an award-file row and an FSRS row; four new out-of-state FSRS subrecipients unread: Ivy Creek, Evergreen Nephrology, AndorHealth spelling, ACLM). Not rebuilt this session.
- Owner questions: Accenture NM ($129.0M); SC annual reports under V1 ($26.1M); IN GROW's five removed members with live FFATA subawards (Region 5 tie risk); the UNSURE list above; MN Pipestone/Murray typing.
- CT FSRS amendment semantics (second actions and negative actions).

## Calls made under the standing rules (owner away; each can be reversed)
1. **IN GROW (ruling d) applied despite the FFATA conflict.** The removal is the latest state source and was confirmed as the state's own edit. The five FFATA subawards to removed members ($695,228.48) stay held, and the conflict is recorded on `in_grow_regional_status.csv`. If the owner prefers the FFATA reading, re-adding West Central Indiana EDD makes Region 5 a 7-of-14 tie (NOT_HOSPITAL, −$16.7M best estimate).
2. **Accenture NM ($128,979,618.21) is held out of verified vendor totals (HD77).** It is still an FSRS award row in `nm_fsrs_awardees.csv`, typed VENDOR_OR_CONTRACTOR / NON_HOSPITAL, so it counts in NM's awards published. That is why NM now clears 50% and enters the ≥50% subset row.
3. **Every FSRS action dated after 2026-10-30 is held as Year 2.** This applies the session-116 safeguards rule to FSRS. It removed TN's 10-31 HART round, NM's 11-03 hub contracts (Gila Regional, Nor-Lea, Cibola: hospital rows) and IL Morris Hospital from Year 1.
4. **Duplicate pairings with a gap.** CT Vassar/Sharon ($3,083; CT prints $13.12M rounded), DE Southbridge/Henrietta Johnson ($549; rounded $1.29M), NE Memorial Community ($79.61), NE Memorial Health Care ($1.00), WV WVU Research Corp/Ascend WV ($10; the checker said "probably"; same initiative). Each max_diff is recorded in `config/fsrs_subaward_pairings.csv`.
5. **Owner classification of COMPLETE bases applied as given**, although UT's and VT's own COMPLETE sentences are obligation statements.
6. **KY Martin County's `announcement_date` is the read date (2026-11-16)**: FHKY's page prints none.
7. **Vermont was not re-based to the 11-12 list.** Only the extractor fix and a fixture test were done. The 11-12 list's award rows equal the committed file, so nothing would move; the VT probe now counts award rows, so the MOU alone reads CHANGED, not TRIPWIRE.
8. **`vendor_flags.csv` was not rebuilt** (116b snapshot). The four unread out-of-state FSRS subrecipients and the Guidehouse override are recorded for next session.
9. **The new vocabulary code `STATE_REPORT`** was added on the owner's Task 3 wording. It is used only in contract files.
10. **MN rows on address bridges ($18.4M hospital) were written**: under the $25M hold line, and on session 116c's MN precedent.

## Suite
Full suite after the last change: see the merge commit message.
