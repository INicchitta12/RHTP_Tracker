# Session 100 (2026-10-14): probe log, runner checks, West Virginia, hunting-list sweep

Session 99 (PR #103, `claude/inspiring-bell-qt78fl`) merged to `main` at 2026-10-13 13:14Z. This
session started from `main` at `79ea271`. No Year 2 work was done.

**Three owner decisions would move hospital dollars. None is applied.**

| State | What appeared | Hospital effect if extracted (estimate) |
|---|---|---|
| **MO** | The SMRP page now has an "Awarded Amount" column. It prices all 20 hospitals we already carry at $0, and the column sums to **$34,646,479.34**. Re-computed in this session from the live table. | NAMED_HOSPITAL +$34,646,479.34, rows unchanged (20) |
| **NV** | NVHA's "RHTP Subrecipient Report for BP1" (24 pp., 10-13). It gives a "BP1 Amount Awarded" for every subrecipient: $175,245,033.86 in total against the $179,931,608.42 allotment. NVHA flags it preliminary: "may not be final as project budgets continue to be refined for CMS approval". | About 38 of NV's 44 hospital rows priced, about **$48.85M**. It is about $46.39M if the Washoe Barton van source defect is excluded. Flag `AMOUNT_PRELIMINARY` |
| **VT** | The 10-08 update: 175 agreements, $131,057,627.27, up 9 agreements / $3,637,773.36. | +2 rows / +$713,992 (both Brattleboro Retreat) |

The partition below includes none of these figures.

## Task 1: runners and coverage

- **VT and ID logged under their new Routine ids.**
  - VT logged `trig_016RPWQycLeLLJngvFZPQKsj` at 10-13 11:37Z (a TRIPWIRE, read below).
  - ID logged `trig_019dET8MmsxwJAHBnx6dCLqF` at 10-13 12:43Z.
  - Both lines are on `main`. Both firings came before the PR #103 merge (13:14Z). The coverage check still covers them because it reads `routines.csv` from the checkout that runs it, and that file now registers the new ids.
- **IN GROW, TX and WV** first fire on Friday 10-16. Their old ids (`trig_01UZ5Q…`, `trig_017U35…`, `trig_01SfWj…`) stay disabled. Delete each once its successor logs on `main`.
- **Deleted:**
  - VT `trig_01G7gMgmaRvkzdWq49YjZQdq` and ID `trig_01HkxVsw4KoGkHpDwBCfve31`. Both were read first with `get_trigger`: disabled, last fired 10-06.
  - Both are recorded in a new `config/routines.csv` column, `old_deleted` (`<id>@<date>`).
  - The `old_trigger_id` chain is unchanged, because `R/probe_coverage.R` still reads it for pre-cut-over firings.
  - `test_probe_coverage.R` (29) and `test_routine_prompts_worktree.R` (317) pass with the new column.
- **Coverage:** `Rscript R/probe_coverage.R --check` reports 156 due firings, all logged except the 4 explained misses already recorded. Nothing new needed adding to `config/probe_gaps_explained.csv`. VT's 10-13 firing is covered.

## Task 2: probe log since 2026-10-12

Every TRIPWIRE and CHANGED line was read live against its archive. The readers appended `interactive` lines; they are committed with this session.

### Lines that move a hospital dollar

**MO (10-14 15:12Z TRIPWIRE, `program_page` name trip).** The trip itself is two non-hospital awards from 10-13 DSS releases:
- Kids Win Missouri: "$1.46 million through the Rural Health Transformation Program (RHTP) ... to expand its Child Care Works program". A nonprofit.
- The University of Missouri Sinclair School of Nursing CNM contract. The DSS bulletin prints no amount; CMS's release says $879,000. A university sub-unit.

The name trip threw first and hid two other findings:
1. **SMRP is priced** (see the first table). The 10-07 probe logged the page UNCHANGED, so the prices appeared between 10-07 and 10-13; the page reports Last-Modified 10-13 20:26Z. `mo_assert_smrp()` now fails on the live page ("A full list of awardees is below" is gone). The page still says "approximately $35 million". Archived as `recheck/2026-10-14/MO/mo_dss_smrp_awardees_priced_2026-10-14.html`.
2. **IFB DSS26015-02 is still absent from the bid table.** No award, cancellation or amendment was found on DSS `/press`, the RHTP page, the fund-distribution page or a DSS site search. MissouriBUYS is a JavaScript app and was not read. **Status: closed, outcome unknown.**

**NV (10-13 15:12Z TRIPWIRE, `roster`).**
- The trip is the new link "RHTP Subrecipient Report for BP1". Archived as `recheck/2026-10-14/NV/nv_nvha_rhtp_subrecipient_report_bp1.pdf` (sha256 `34c74ae6…`); the opening text and the Washoe Barton line were verified in this session.
- Section totals, as summed by the reader:

  | Section | Awarded |
  |---|---:|
  | RHOAP | $25,140,201.68 |
  | FLEX | $58,231,228.10 |
  | WRRAP R+R | $37,332,720.00 |
  | WRRAP A+T | $13,567,720.49 |
  | Rural Workforce | $4,657,320.16 |
  | RHIT | $24,594,701.62 |
  | Tribal | $8,095,961.77 |
  | Veterans | $1,271,512.04 |
  | Corrections | $976,255.00 |
  | PFT | $1,377,413.00 |

- **Source defects. Record them, never fix them:**
  - Washoe Barton van: requested $245,800.00, awarded $2,458,060.00, which looks like a shifted decimal.
  - Northeastern Nevada Regional Hospital FLEX: requested $103,725,086.00, awarded $997,361.
- **The owner's §10.2 call:** Nevada Rural Hospital Partners Foundation, **$20,278,054.31**. The report says it will "organize the RHT recruitment, retention and training projects of all 14 rural hospitals". "Organize" does not show money administered to hospitals. Our file codes NRHPF `IN_KIND_BENEFIT`. Six of our R+R hospital rows have no line of their own in the report.
- **New hospital line:** Mt. Grant General Hospital, FLEX, $172,622.
- **Candidates to re-type:**
  - Banner Churchill: $145,428.23
  - "IHC Health Services, Inc. dba Intermountain Health": $24,506
  - Renown Health: $985,700 (our file has "Renown Health Foundation")
- **The report's grain differs from `nv_year1_awardees.csv`:** about 157 lines against our 156.

**VT (10-13 11:37Z TRIPWIRE).**
- The page now says "Updated as of October 8, 2026".
- The nine new agreements, keyed on initiative + activity + amount:

  | Recipient | Amount | Activity |
  |---|---:|---|
  | Essex Pediatrics | $184,880.88 | Primary Care data |
  | CHC of the Rutland Region | $251,269.88 | Primary Care data |
  | Gifford Health Care, Inc | $279,916.51 | Primary Care data (typed FQHC in our file) |
  | Pediatric Medicine | $199,526.30 | Primary Care data |
  | Brattleboro Retreat | $525,000 | facility upgrades |
  | New England Wellness Group | $300,000 | facility upgrades |
  | Northeast Kingdom Human Services | $1,488,626 | facility upgrades |
  | Brattleboro Retreat | $188,992 | transformation |
  | NOTCH | $219,561.79 | transformation |

- Nothing was removed.

### New solicitations (Tier 2, no hospital dollars)

- **MS:**
  - Innovative Pilot Program. The 10-08 amendment adds the pool: "$16 million", opens 10/14/2026, due 11/16/2026, "Anticipated Award Announcement January 2027", capped at $2M per entity. Hospitals are eligible among others.
  - EHR Replacement for Small Rural Providers: "$9.5 million", opens 10/21, due 11/23, awards February 2027.
  - MSDH HIE RFP on OpenGov, due 11-03.
  - WEI and EmPATH are on the Closed page with no award posted; the 10-14 to 10-29 window is still open.
  - The 10-13 TRIPWIRE was medicaid.ms.gov's empty reply. It fired before the empty-reply fix reached `main`. Re-run today, it logs ERROR: the host returns an empty reply to every agent (UNKNOWN).
- **KY:**
  - The 10-12 `programme` trip was the menu ("Our Plan, Updates and Progress"). It is quiet since the session 99 re-base.
  - A re-run trips on `rch`: FHKY's RCH Hub Lead RFA round 2 (10-13).
    - Up to 12 awards, one per remaining ADD, each "up to $500,000" for Hub Launch.
    - Letter of intent 11-06; applications due 12-18; "Anticipated notification of awards" 2027-01-29.
    - Eligibility is not limited to hospitals.
  - Archived as `recheck/2026-10-14/KY/ky_fhky_rch_hub_lead_rfa_round2_2026-10-13.pdf`.
  - **The next KY firing will TRIPWIRE on `rch` until it is re-based or furnished.**
- **DE (NEWSROOM sweep, live 10-14):** "Delaware Announces Rural Health Transformation Funding to Strengthen Physician Workforce".
  - Thomas Jefferson University / Sidney Kimmel Medical College: two $70,000 educational awards, $140,000. An executed agreement with a university.
  - About $1.24M budgeted for 61 resident housing and relocation awards, application stage. Bayhealth, Beebe, ChristianaCare, Nemours and TidalHealth are named as GME **training sites, not recipients** (§0.3/§0.3a).
- **VA:**
  - The 10-13 trip was the pre-merge anchor. Live: "October 15, 2026, for Provider Productivity" ($7M to $9M), not yet awarded.
  - `ways_to_apply` shows status churn only, with the partner set unchanged.
- **WI `dhs_solicit` (10-13):** the Reproductive Health and Family Planning RFA. It is state Title X / Provider Type 71 money with no RHTP funding statement. Noise.
- **CT `dmhas_rfps` (10-12):** a Recovery Centers RFP funded by opioid settlement money ($3,742,834). Noise.

### CMS monitor: no Year 2 release

The 10-12 13:44Z line (new states IA, LA) and three later releases (NE 10-13, MO 10-13, DE 10-14) all say "fiscal year 2026":

| Release | Reading |
|---|---|
| IA "$209 Million" | Tier 1 |
| LA "$37.7 Million" | "up to $20M" for colleges as a ceiling; $12.7M is the RCCB already carried at 53 / $12,701,996; $5M for 39 campuses |
| NE "$177 Million" | Unnamed counties and facilities |
| MO | Kids Win and CNM, above |
| DE | Above |

- **No release mentions FY2027.** The medicaid.gov obligation report link is unchanged (`RHTP-Obligated-Funds-10082026.pdf`).
- **Expect the 10-15 CMS run to log CHANGED** (new state NE; new releases for DE and MO). All three were read here.
- **Year 2 mentions, recorded only:** Iowa's 2026-08-27 Council deck gives a Year 2 award-announcement window of "Oct 15 – Nov 20, 2026" (about $144.7M across 5 programmes), pending CMS approval of the Year 2 budget. Nothing was changed for it.

### Noise (re-base proposals)

| State / page | What changed |
|---|---|
| CA `calrht` (10-14) | A link to CMS's Obligated Funds Report, byte-identical to `data/raw/cms/obligations/2026-07-31/` |
| ID `funding` / `about` | A stale archive: "Year 1 funding opportunities are closed ... (Updated 9/22/26)", plus task-force materials |
| ME `rhef` / `doe` / `programme` | Footer and menu links; meeting time |
| NM `news` / `rhcdf` | Menu; two non-RHTP news items |
| NE `program_page` | DHHS menu |
| NY `press_index` | Three non-RHTP items |
| NY `scr` | Live counters that change on every firing, so it needs a reducer change, not a re-base |
| DE `programme` | Catalyst Fund second-round text, already read in session 98 |
| LA `programme` / `funding` / `leg_reports` | LDH's site-wide menu only. The six programmes still read "Notice of Intent to Contract Announcements: October 2, 2026"; denials are due "by October 16". The legislative reports page does not carry SR 198 (newest entry: the LaCHIP report, 08-26). The one-time check is on 10-16 |
| AK (10-12) | The notice session 99 extracted; re-probed UNCHANGED |
| KS (10-12) | ERROR, KDHE 403. The KS runner itself also got 403 this time, so the KS Routine is now blind too |
| NEWSROOM (10-12) | 14 pages of ordinary churn. AZ:ahcccs's 09-25 microgrant solicitation was already known from session 98 |

### Process defects found

1. **A name trip hides the probe's other findings.** MO's name tripwire threw before `mo_assert_smrp()` and the bid check ran. The $34.6M SMRP change surfaced only because a human read the page. **Proposal:** collect every assertion's result and throw once at the end.
2. **A fetch failure stops the whole MS probe** before any mississippirhtp.com check runs. **Proposal:** a per-page ERROR for `dom_completed`, with the rest of the probe continuing.
3. **An evidence-guard refusal is logged as no line and counted as a tripwire.** In `nw_sweep()`, MT's probe was refused because another reader wrote `recheck/2026-10-14/` at the same second. The refusal threw before logging, and the sweep counted it as a TRIPWIRE. A clean re-run gave MT:news UNCHANGED and MT:dphhs CHANGED. **Proposal:** log a guard refusal as ERROR. Do not run probes while evidence is being archived. This session caused it by running both in parallel.
4. **Two subject pages are unwatched:** NC's NCDHHS press index, and IN's IDOA award-recommendation register. Iowa has no probe or Routine at all.

## Task 3: West Virginia (approved, extracted)

**`R/03av` key `inv`:** the 2026-09-30 "More Than $3.2 Million in Rural Health Transformation Investments" release. It says "Today's awards" and names seven recipients. It prices none; "more than $3.2 million" is the only total and is not divided (§6.2).

| Awardee | CCN (CMS WV enrolment, 2026-09-23) | Match | Conf. | Rural cut |
|---|---|---|---|---|
| Stonewall Jackson Memorial Hospital | 510038 ("... HOSPITAL COMPANY") | LEGAL_NAME_TRUNCATED | LOW | no |
| Mon Health Marion Neighborhood Hospital | 510093 | EXACT_LEGAL_NAME | MEDIUM | no |
| Preston Memorial Hospital | 511312 (CAH) | EXACT_LEGAL_NAME | MEDIUM | yes |
| Plateau Medical Center | 511317 (CAH; "CAMC PLATEAU MEDICAL CENTER, INC.") | LEGAL_NAME_TRUNCATED | LOW | yes |
| Webster Memorial Hospital | 511301 (enrols as PART A HOSPITAL) | EXACT_LEGAL_NAME | MEDIUM | no |
| Broaddus Hospital | 511300 (CAH; "BROADDUS HOSPITAL ASSOCIATION INC.") | LEGAL_NAME_TRUNCATED | LOW | yes |
| Vandalia Health | none under that legal name | — | LOW | — |

- **Vandalia Health** is a system parent. Its hospitals enrol as "VANDALIA HEALTH \<hospital\>" DBAs, and a prefix is never a match (§2). It stays on §8's standing fallback. Its award helps "rural hospitals and clinics" fill staffing, which is hospitals among others, so it is coded PASS_THROUGH_UNRESOLVED / Unclear.
  - The system-parent precedent (Sanford/Avera, Valley Health/Ballad/Sentara, Guthrie, Mercy) was an owner ruling each time, so it is queued as `WV_VANDALIA_SYSTEM_PARENT`.
  - Option (b) adds one row at $0.
- **West Virginia's file is now 21 rows, 12 priced, $9,248,417 (unchanged).** Hospital: 5 → **11 rows**, $2,924,000 unchanged. Its status table gains a row for the release.
- **The archived release** was renamed to `2026-10-12_wv_art_32m_rhtp_investments.html` (bytes unchanged; recorded in the manifest). It was re-read live 10-14, and the reduced text is identical. `WV_READ_UNEXTRACTED` is now empty, and the slug is in `WV_SLUG`.
- **Knock-on files:**
  - `R/03bj` EH_APPLY gains six verdicts.
  - The rural cut moves 264 → **267** rows at the same $267,502,638.43.
  - `wv_rcj_candidate_disposition.csv` was rebuilt.
  - The tests were updated.

## Task 4: hunting-list sweep (CA, IN, IA, HI, NC)

Nothing was extracted. Everything new is in `data/evidence/recheck/2026-10-14/` with `MANIFEST.txt`. The CMS obligation lines name no organisation in any of these five states, so every search worked from activity.

| State | What exists, new since our archive | Named | Amounts | Hospital effect (estimate) | Probe covers it? |
|---|---|---|---|---|---|
| **CA** | Nothing new. The funding page is identical; all four pools are "(Closed)"; the notices are private (FAQ byte-identical). The 10-14 trip is the CMS obligation-report link. Traps: the HCAI menu's $300M Distressed Hospital Loan Program and the $38M behavioral health workforce item are state money | 0 | — | none | Yes (`R/03ab`, Wed/Sat). RHPC meets 10-27; notices "by late October" |
| **IN** | Four new IDOA Award Recommendation letters price six vendors already in our IN file without amounts: MOCC (Patient Flow Innovations $26,362,844; Collaborative Fusion $3,698,932; Communicare $11,629,000); Program Evaluator (Public Policy Associates $1,000,000 over 4 yrs); Preceptor Registry (Concourse Tech $809,500 over 5 yrs); ACO Feasibility (Deloitte $150,000). These are multi-year contract maximums, $43,650,276. Trap: Parkview Hospital appears only as an unsuccessful bidder. The October IDOH newsletter: Meds-to-Beds "20 hospitals awarded funding for Budget Period One", none named (§7, no bucket); "10 CKM Centers of Excellence have been identified", names "soon"; IU School of Medicine grant agreement executed (a lead; no state award document) | 0 new recipients | $43.65M of vendor maximums | $0 named. Up to 20 unnamed Meds-to-Beds hospitals; the CKM sites are likely hospitals once named | GROW page yes (`R/03bi`). The IDOA register and the newsletter: **no** |
| **IA** | (1) A new NOIA, PHTHORC27001 Iowa Rural Residency Program (posted 09-25 to 10-09), naming **Mary Greeley Medical Center** and **UnityPoint – Des Moines**, no amounts. RHTP provenance is **not established**: no CMS footer, the RFP is not under Healthy Hometowns, and it may be GME/Medicaid money. A §6.2 question before any extraction. (2) Iowa HHS Council deck, 2026-08-27: "Contracts Awarded: 269 +7 amendments" against our 264. It names 5 more Centers of Excellence hospitals (Cass County Memorial, Grinnell Regional, Mahaska County, St Anthony Regional, Van Buren County), 4 more Cancer Health Hubs (Mercy Des Moines, UnityPoint Des Moines, Jennie Edmundson, Mercy North Iowa) and Converge Health LLC (HIE vendor). No recipient is priced; the deck's obligation figures are Tier 2. (3) The 10-09 HHS release says "fully obligated" and points to a Power BI dashboard, 403 (UNKNOWN). Colorectal RFP PHTHOCC27705 was rescinded 09-25 | About 9 new hospital names (deck) + 2 (NOIA, provenance open) | none | +9 to 11 hospital rows at $0 | **No.** Iowa has no probe and no Routine |
| **HI** | SHPDA's RHTP page now lists **three** RVBI Notices of Award (the RVBI line is $25M): HPCA (8/28, known); **Healthcare Association of Hawaii** (9/3), "Statewide Hospital Infrastructure, Analytics, Readiness Funding, and Transformation Support ... primarily for rural hospitals ... and administration of approved Rural Value-Based Innovation funding"; **Physicians of Southwest Washington, LLC** (9/11), CIN/MSO support. Amounts are only in HANDS, which is 403. engage.hawaii.gov/rhtp/ now returns 404 | 3 (2 new) | 0 of 3 priced | $0 named. HAH needs a §10.2 flow call: an association, with the money "primarily for rural hospitals" plus "administration of approved RVBI funding" | **No.** Hawaii is INVESTIGATED_NO_PROBE |
| **NC** | No new roster. The NCDHHS 10-07 "$17 Million" behavioral-health release is archived for the first time (read in session 98): CCBHC $4M "awarded" to three **unnamed** LME/MCOs; the other five lines are not stated as awarded. Trillium's 10 regional RFAs are all "Closed – Under Review"; award notification was "September/October 2026", and nothing is posted. MDPP awardee unpublished (CMS line $25,000) | 0 | — | $0 (LME/MCOs are MANAGED_CARE_ORGANIZATION) | Partly. `R/03ah` watches 5 pages; the NCDHHS press index is unwatched |

## Hospital partition (re-derived 2026-10-14, after Task 3)

```
NAMED_HOSPITAL          1,331 rows   $1,225,134,515.58   32 states   (+6 rows, $0: WV)
POOL_NAMED_HOSPITALS        2 rows      $30,806,856.12   NE + CT     (unchanged)
POOL_UNNAMED_HOSPITALS      4 rows      $69,323,109.17   IL RI NE    (unchanged)
```

The three buckets are never added together. The rural cut is 267 rows / $267,502,638.43.

## Proposals for the owner (nothing applied)

1. **MO SMRP:** re-base `smrp_awardees` and price the 20 rows (+$34,646,479.34).
   - Add Kids Win Missouri ($1.46M, NON_HOSPITAL) and the University of Missouri CNM contract (no state amount) as award rows.
   - Re-base `program_page`.
   - Rewrite the DSS26015-02 bid check as an award watch.
2. **NV BP1 report:** rewrite `R/03u` to take BP1 amounts from it (`AMOUNT_PRELIMINARY`), keyed on section + applicant + project.
   - Queue four items: the NRHPF $20.28M flow, the two source defects, the three re-types and Mt. Grant.
   - Until the roster is re-based, every NV firing trips on the same link.
3. **VT 10-08:** re-archive and extract (+9 agreements, +2 hospital rows / +$713,992). Set `VT_UPDATED_TXT` and `VT_PAGE_ROWS` to 175.
4. **IA:** extract the deck's named CoE and Cancer Hub recipients at $0 after reading their grain against the NOIAs. Settle the Rural Residency NOIA's provenance first. Build an IA probe and Routine.
5. **HI:** build a probe on the SHPDA page (it would move HI to INVESTIGATED_NO_LIST). Make a §10.2 call on HAH.
6. **IN:** price the six vendor rows from the IDOA letters ($0 hospital). Put the IDOA register and the IDOH newsletter on a probe.
7. **Re-bases, or furniture with a sentence:**
   - CA `calrht`
   - ID `funding` / `about`
   - ME (3 pages)
   - NM (2)
   - NE `program_page`
   - NY `press_index`
   - DE `programme`
   - CT `dmhas_rfps`
   - WI `dhs_solicit` (furniture) and `dhs_rhtp`
   - VA `ways_to_apply`
   - KY `rch` (furniture: "FHKY's RCH Hub Lead RFA R2 lists eligible classes, not recipients")
   - LA's three pages (a content-region digest would be better)
   - MS `funding` (Pilot/EHR/HIE link labels)
   - NEWSROOM's 15 noise pages
8. **Code fixes:** see process defects 1–3. NY `scr`'s counters need stripping in its reducer.
9. **WV:** decide `WV_VANDALIA_SYSTEM_PARENT`.

## Suite

Full suite (`Rscript tests/run_tests.R`, 2026-10-14 after the last code change): 0 failed, 1 expected skip (the CMS first-run branch). The first full run found 10 stale pins in `test_03ap_verification_queue_2.R` (the six WV rows); fixed in the commit that adds the session-100 layer.
