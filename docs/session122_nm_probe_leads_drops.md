# Session 122 (2026-11-23): New Mexico probe, lead checker, week-over-week drops

Branch `claude/gallant-babbage-tmrhr1`, started from `main` at `bcd248e` (sessions 121 and #132 merged).

## Headline figures (11-20 table → 11-23 table)

| Figure | 2026-11-20 | 2026-11-23 | Change |
|---|---:|---:|---|
| Awards published (US) | $6,527,744,046.56 | $6,529,984,965.77 | +$2,240,919.21 (KS +$780,919.21, MO +$1,460,000) |
| Hospital best estimate (US) | $2,604,660,516.91 | $2,604,985,516.91 | +$325,000 (KS) |
| Strict NAMED_HOSPITAL | 2,369 / $2,292,033,452.90 / 43 | 2,370 / $2,292,358,452.90 / 43 | +1 / +$325,000 (KS Labette) |
| Subset row (≥50% published, n = 36): awards | $5,680,840,339.91 | $5,681,621,259.12 | +$780,919.21 (KS) |
| Subset row: best estimate | $2,390,507,803.43 | $2,390,832,803.43 | +$325,000 (KS) |
| Pools (POOL_NAMED, POOL_UNNAMED) | unchanged | unchanged | — |

By state: **KS** +2 award rows / +$780,919.21 awards, +1 hospital row / +$325,000 (Labette County Medical Center, CCN 170120, MEDIUM, exact legal name); **MO** +1 row / +$1,460,000 awards (Kids Win Missouri, non-hospital, rounded in source). No other state moved.

**Verified vendor figures (spend layer; amount types are never added):** award line **$199,513,205.75** (unchanged; PUBLIC $42,750,000 / NON_PUBLIC $156,763,205.75). Other types: intent $48,233,747.84, contract maximum $25,965,898, obligation $30,181,665.63 (all unchanged). The NM Accenture LLP ASO subaward ($128,979,618.21) stays held out under `ADMINISTRATOR_PASS_THROUGH_UNRESOLVED`. The two new rows are `spend_category = OTHER` (Pulse Transport, LLC; Kids Win Missouri). Neither is a vendor case.

Outputs: `data/reference/year1_summary_2026-11-23.csv`, `output/year1_summary_2026-11-23.xlsx`, `data/reference/year1_vendor_summary_2026-11-23.csv`, `output/verified_vendor_list_2026-11-23.xlsx`, `output/completed_states_2026-11-23.{xlsx,html}`. The rural cut has been re-stated. Labette is CCN 170120, not a CAH, so the rural figure is unchanged.

## Task 1: New Mexico probe rewritten (`R/03ad --probe`)

HCA migrated www.hca.nm.gov (Drupal) on or about 11-20. The old RHT URL 301s to a stale pre-procurement page. `/news/` and `/rht` are 404. None of the 2026 RHT procurements, including the ASO, appears on HCA's RFP or contracts lists. The probe now reads six migrated pages, each archived on 2026-11-23 under `data/evidence/NM/`:

| key | page |
|---|---|
| `programme_v2` | the migrated RHT page (`/get-help/.../rural-health-transformation-program`) |
| `news_rht` | news index filtered to "rural health" (carries the 11-18 Guidehouse and FY2027 releases) |
| `aso_search` | site search, "Administrative Services Organization" |
| `aso_release` | the 04-27 ASO RFP release at its new address |
| `rfp_rht` | RFP list filtered to "Rural Health" (shows Status) |
| `contracts_rht` | contracts list filtered to "Rural Health" (an executed ASO contract would appear here) |

The **ASO watch** (`nm_aso_watch_findings()`) trips TRIPWIRE on any of the following. A watch item is a headline or sentence.
- "Accenture" anywhere on any page.
- A new item with administrator, ASO, third-party administrator or administrative services organization in an RHT context.
- A new item with a dollar figure next to fee, contract maximum, not-to-exceed or pass-through.
- On the news index, a new selection, award or contract item.
- On the two procurement lists, any new or changed RHT listing. This includes a Status change, which is the procurement-stage test.

`nm_v2_marker_findings()` makes a page that loses its marker a finding, not a quiet pass. The name tripwire reads `programme_v2` and `news_rht`, both scoped past HCA's menus. The old assertions still run under `--validate` against the archive they were written for.

Tests in `test_03ad` cover the following.
- The 11-23 fixture.
- Archive against archive is quiet.
- A news item selecting an administrator trips both the watch and the name tripwire.
- Accenture, a fee, a third-party administrator and a pass-through figure each trip.
- A Status change on the RFP list and a new contract each trip.
- Unrelated "Administrative ..." site-search hits do not trip.

**Live run, 14:21Z and again after the final edit: UNCHANGED on all six pages, watch quiet.** HCA has named no administrator, and Accenture appears nowhere. The ASO announcement is still due by 11-30. Accenture stays excluded and flagged.

## Task 2: rhtptracker.com lead checker (`R/03cw`)

**(a) Fix.** Official links are now read from `<main>` only, and the site-wide CMS FY2027 release link is refused even inside `<main>`. A page with no `<main>` yields no links. The state code is now parsed from opportunity addresses (`/opportunities/<channel>-<st>-...`). New tests cover the banner (outside `<main>`, and inside it), a page with no `<main>`, the archived gated VT page, and six address forms.

**(b) Re-run (interactive, read-only):** the run logged 40 LEAD rows. Every row carries a state, and none cites the CMS banner. The sitemap baseline is re-based to 11-23 after reading (`data/evidence/leads/rhtptracker/2026-11-23/`). The awards-link baseline stays at 11-16.

**(c) The 30 awards pages.** All 36 `/states/<ST>/awards` pages are now **access-gated** ("Access to RHTP Tracker is by request") and carry no official link in their body. The cross-check therefore used the official sources those pages cited in the committed 11-16 baseline: 47 links for 22 of the 30 states. FL, IL, MI, NH, NV, OH, SD and VA cited only the CMS banner. Every cited source was already in `data/evidence/` or a committed award file, except the following:

| State | Source | Result |
|---|---|---|
| **KS** | KDHE newsflash 2130 (09-14), Interfacility Transport (IFTp) | **Extracted.** 2 awards, $780,919.21: Pulse Transport, LLC $455,919.21 (EMS) and Labette County Medical Center $325,000 (hospital, CCN 170120). Rows 61–62 of `ks_year1_awardees.csv` (`R/03o`, appended), `AGENCY_PRESS_RELEASE`. |
| **MO** | DSS 10-13, Kids Win Missouri $1.46 million (Child Care Works) | **Extracted.** Row 23 of `mo_year1_awardees.csv`, NONPROFIT_CBO fallback, `AMOUNT_ROUNDED_IN_SOURCE`, non-hospital. Session 101 had read it and left it out. The same page's MU Sinclair School of Nursing CNM **contract** prints no amount, so it is recorded only. |
| KS | KDHE newsflash 2088 (CHW+AFIM) and 2149 (Emerging Technology) | Already extracted from KDHE's award PDFs. |
| WV | Governor, "more $3.4 million ... WVU Health" | Same release as `R/03av`'s `wvu` key (different slug). |
| HI | HANDS contract-awards API | Unreadable (403, known). |
| IN | IDOA RFP 26-87448 and 26-87450 award zips | Vendor procurements, known to `R/03s` / the recheck archive. Not re-opened. |

**Delaware:** news.delaware.gov's FQHC release is already archived. Recorded only.

**(d) Opportunity leads.** 43 new opportunity pages, all Tier 2 or Year 2. None was opened beyond its title, and no figure was taken. By state: AK 1, AL 2, HI 2, ID 3, KS 1, KY 1, LA 1, MA 3, MD 1, ME 6, MO 4, MS 1, NC 3, NH 4, NV 2 (+1), RI 3 (+2), TN 1, WV 1. The three pages beyond the 40-page cap (NV `rhtp-nv-rural-reentry-rhit-2026`, RI `rhtp-ri-apm-incentive-payment-2026`, RI `rhtp-ri-ohic-transformation-grant-fund-2027`) were already in the 11-20 log.

**FSRS pairing note (no dollar effect).** FSRS PO 137116 ($2,145,677, Labette County Medical Center) is KS REH CAP row 8 "Labette Health" $2,145,677 to the dollar. The name matcher pairs it with row 33 (and now row 62) as `DIFFERS`, because "Labette Health" is the DBA. The state amounts stand on all three rows. A crosswalk entry for session 123 would route it to row 8.

## Task 3: the week-over-week drops (no error)

**Vermont: $77.5M → $75.5M best estimate, $181.1M → $179.1M awards.** The whole $2,000,000 is one row. `vt_fsrs_awardees.csv` (11-13) carried FSRS F84BC0AD ($2,000,000, 09-29) to **Carlos G. Otis Health Care Center, Inc.**, Grace Cottage's operator, as a new row. That is VT roster row 41, "Grace Cottage", $2,000,000. Session 118 applied the PUBLISHED_ROSTER completion rule, under which an unpaired FSRS row in a completed roster state is held. The row is now `HELD_NEW_STATE_ROSTER_PUBLISHED_COMPLETE` in `fsrs_held.csv`, and the file count went 2 → 1. **The 11-13 figure counted the $2M twice.**

**Nebraska: $49.6M → $49.1M best estimate, $142.5M → $142.0M awards.** That is −$492,193.92, two duplicate pairs found by session 118's independent check (`config/fsrs_subaward_pairings.csv`, D7 and D8):
- FSRS C03DC0D1, $339,998.92, had priced the 4.4b NHVN member row "Memorial Health Care Systems" from $0. It is the 4.4a Seward award already on NE row 28 at $339,999.92 ($1.00 gap). The row is back to $0.
- FSRS 98CB2278, Memorial Community Hospital Corp, $152,195, was a new `ne_fsrs_awardees.csv` row. It is NE row 22, Blair, $152,274.61, CMS 281359. The row was removed.

**The 11-13 figures counted both twice.**

## Task 4: Washington and North Carolina completion evidence (`R/03aw`)

Both states stay **PARTIAL** with `remaining_unawarded = Yes`. `source_calls_complete` is now **Yes** on each state's obligation sentence. No total moved.
- **NC**, NCDHHS 2026-11-02: *"The state obligated all funds allocated to North Carolina within the first year of the Rural Health Transformation Program."* The remainder is quoted: *"NC ROOTS Hubs will soon begin funding projects..."*, and the Rural Health Innovation Fund awards are "January 2027" (09-30 release).
- **WA**, HCA 11-06 page and bulletin: *"these funds are 100% obligated, which means CMS legally commits to providing all the funding"*. Read as the federal obligation. The remainder is quoted: *"DOH will open a funding opportunity for rural provider incentives in November"*, which is the "Rural workforce incentives $9.89 million" line.

## Task 5: loose ends

- **Indiana Meds-to-Beds.** IDOH's page has no text roster; the 20 sites are an image only. FSRS subaward descriptions ("FEASIBILITY ANALYSIS FOR MEDS-TO-BEDS PROGRAM") confirm **11 of 20** in text, under these legal names: Adams County Memorial Hospital, Bluffton Health System LLC, Community Hospital of Bremen Inc, Daviess County Hospital, Good Samaritan Hospital, Greene County General Hospital, Jackson County Schneck Memorial Hospital, Marion General Hospital Inc, Perry County Memorial Hospital Foundation Inc, The Board of Trustee of Putnam County Hospital, and Union Hospital Inc.
  - **Name differences from our file** (all the same body): "Bluffton Regional Medical Center" vs Bluffton Health System LLC; "Marion Health MGH Campus" vs Marion General Hospital; "Schneck Medical Center" vs Jackson County Schneck Memorial; "Daviess Community Hospital" vs Daviess County Hospital; "Union Hospital Clinton" vs Union Hospital Inc; "Putnam County Hospital" vs its Board of Trustees; "Perry County Memorial Hospital" vs its Foundation. Our row also reads **"Greene County General Hosptial"**, spelled as read off the map, against FSRS's correct spelling.
  - **Not confirmed in text (9):** Northwest Health Starke, Lutheran Kosciusko, Dukes Memorial, Reid Health, Rush Memorial, Margaret Mary, Decatur County Memorial, St. Elizabeth Dearborn, Harrison County.
  - **A finding for session 123:** these 11 FSRS subawards ($885,195 together, Year 1 dates 08-17 to 09-24) are **held**. Seven are `HELD_POOL_MEMBER_COUNTED_AT_POOL_LEVEL` against IN GROW, three are `HELD_ZERO_ROWS_IN_SEVERAL_FILES`, and Daviess is unreviewed. They describe Meds-to-Beds, not GROW. Pricing the MTB rows needs R/09b to route by description (Iowa's pool filter is the model) plus crosswalk entries. That is +$885,195 hospital under the standing FSRS rule; it was not done today.
- **Virginia.** `ruralhealthtransformationva.virginia.gov` reads again through the probe's pinned DigiCert intermediate. Plain curl still fails the chain. The CHANGED logged since 11-17 on `ways_to_apply` was read: RFA Status cells only. Innovation Fund went Open→Closed, Active Kids went Open→Closed, Consumer Technology went TBD→Open, and the "Commonwealth of VA" Mobile & Hybrid line was dropped. Re-based to 11-23. The live probe reads UNCHANGED on all five pages.

## Task 6: probe log since session 121 (11-20 18:00Z → 11-23 14:10Z; 92 Routine lines)

**Nothing moves a hospital or vendor dollar.** By state:

| State | Verdict | Read |
|---|---|---|
| CMS | (missed 11-23) | **The suite failed on main.** `test_utils_probe_log` did not allow the `RHTPTRACKER` state, so the runner correctly published nothing. Fixed; the miss is explained in `probe_gaps_explained.csv`. |
| CA | ERROR ×3, 11-21 | HCAI moved CalRHT **back** to `/rural-health/calrht/`. Re-pointed. The diff is a privacy-breach banner, the survey block removed, and footer $464,745,131.25 = FY2026 + FY2027. Roster 108 / $138,464,043.97 unchanged. Re-based; live UNCHANGED. |
| NY | CHANGED | The Governor's 11-16 release names three implementation partners with **no amounts or dates**: Primary Care Development Corporation ($30M Primary Care initiative), Public Consulting Group, and **Accenture LLP** (cybersecurity, part of the $79.5M Tech/Cyber initiative). These are vendor leads and are not extracted. The 11-09 NYSERDA "$28M to hospitals" item is state money (§0.1). The footer is BP1+BP2. |
| NC | TRIPWIRE | $429,832,929.77 = FY2026 + FY2027 to the cent: a footer, not per-hub amounts. |
| MN | TRIPWIRE | $293,090,618.14 = FY2026 + the $100M Year 2 initial award: a footer. |
| TN | TRIPWIRE | The rolling 15-item index aged out a 2026 solicitation headline. The award release is still listed. The 11-19 "Year-Two" release is Tier 1, Year 2. The pinned headlines need an update. |
| WY | TRIPWIRE + CHANGED | Button relabel ("Year One Award Summaries"), a known Drive folder. `submittable` shows a new open RFA, 1.2 EMS Regionalization (Tier 2). |
| CO | TRIPWIRE | The kickoff block was replaced by "Grantee Open Office Hours". No name. |
| AR | CHANGED ×4 | Footer $416,568,306.28 = FY2026 + FY2027. |
| NJ | CHANGED ×2 | Lt. Governor added to the header; non-RHTP DOH headlines. |
| DE | CHANGED | Typo fix; footer $317,689,484.86 = FY2026 + FY2027. Recorded only. |
| KS | ERROR | KDHE 403 (Cloudflare, our access, known). |
| RHTPTRACKER | LEAD ×63 | The defective 11-20 run (Task 2). |

TN, WY and CO will keep tripping until a human re-bases them. Each was read above.

**No newly COMPLETE state.** NC and WA are obligation statements with known remainders (Task 4). The TN, NY, AR, DE and CA "Year 2" releases are Tier 1.

## Task 7: runners and Routines

Runner context (`used_tokens`, 11-23):

| Runner | Tokens | Action |
|---|---:|---|
| KS | 742,305 | **Moved.** New runner `session_01Y1P5eT6t4n6GobMiJmZHSh`, trigger `trig_01GhNAjbP6KXhhWBZcXEeXNE`, Mon 08:10Z |
| AK | 674,198 | **Moved.** New runner `session_01Y1P5eSDiYkkC5iawecB7wz`, trigger `trig_01XgzzrcTStG67HSYnSmsZgt`, Mon 14:00Z |
| DE | 640,809 | Not moved |
| VT | 633,766 | Not moved |
| OK | 629,002 | Not moved |
| VA | 628,882 | Not moved |
| CT | 620,947 | Not moved |
| NC | 619,798 | Not moved |
| CO | 612,363 | Not moved |

For the two moves, the old ids are **disabled** and chained in `routines.csv`, and the v4 prompts are regenerated (`--check` passes).

Check-ins:
- The 11-26 09:30Z check-in (`trig_0115GYqc1EzHe7RA8D991PWp`: LA, SC, ID deletions) is still scheduled.
- There was none for IN. A new one-shot, `trig_01UizHUBitPdgZ7yoR1PgAyD` at **11-30 15:30Z**, deletes old IN, KS and AK once each successor has logged on main.
- The NV runner reports need_input: its `nofos` tripwire has fired four times without a read. This is for session 123.

## Calls made without a ruling

1. **Kids Win Missouri** extracted, $1.46M, rounded. Session 101 had left it out as non-hospital, but the standing rule covers any priced Year 1 state-source award.
2. **Pulse Transport, LLC** typed EMS_OR_PSAP on KDHE's own description of the recipient's operations (STATE_SOURCE, MEDIUM).
3. **Labette County Medical Center** typed on its exact CMS legal name (MEDIUM, CCN on row). `cms_enrolment_match` is left in the basis, not a column, so §10.2's operator verdicts are not triggered.
4. **The MU Sinclair CNM contract** was not extracted: no amount, and it is a contract.
5. **Meds-to-Beds FSRS pricing** was deferred to session 123 (needs a matcher change).
6. **Re-bases after reading:** VA `ways_to_apply`; CA's four pages; the rhtptracker sitemap baseline.
7. **NC and WA:** `source_calls_complete = Yes` on obligation sentences. Both stay PARTIAL.
