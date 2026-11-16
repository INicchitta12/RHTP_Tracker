# Session 117 (2026-11-16): FSRS follow-ups, Year 2 gap, runners, probe log, rhtptracker.com, vendor follow-ups

**Branch:** `claude/stoic-davinci-62ocjv`. **Setup:** session 117a (`claude/tender-pasteur-yphp1f`) failed its full suite (111 failures). Its WV row (Cabell Huntington, +1 / +$1,544,313) was never re-pinned in five partition tests or in `R/03ar`. Its 11-13 completed-states workbook did not open in openpyxl. The CMS Routine's 11-12 miss was unexplained. All three were fixed; the suite then passed (0 failures, 21m55s) and the branch merged as [INicchitta12/RHTP_Tracker#127](https://github.com/INicchitta12/RHTP_Tracker/pull/127) at 15:33Z.

## Report first

### Hospital and vendor figures, before (11-13 build, after 117a) and after (11-16 build)

| Figure | 11-13 | 11-16 | Change |
|---|---:|---:|---:|
| Awards published (national) | $6,206,479,685.27 | $6,194,112,121.67 | −$12,367,563.60 |
| Hospital best estimate | $2,474,926,623.89 | $2,470,690,310.59 | −$4,236,313.30 |
| Strict NAMED_HOSPITAL | 2,205 / $2,171,969,559.88 | 2,199 / $2,167,733,246.58 | −6 / −$4,236,313.30 |
| POOL_NAMED / POOL_UNNAMED | $86,895,779.43 / $79,214,848.17 | unchanged | — |
| Hospital % of awards (national) | 39.9% | 39.9% | — |
| ≥50% subset row (n = 32) | $2,133,741,090.93; 41.2% of awards; 33.2% of allotment | $2,129,504,777.63; 41.2%; 33.1% | −$4,236,313.30 |
| Rural cut | 757 / $673,247,294.36 | 754 / $671,551,567.78 | −3 / −$1,695,726.58 |

**Two things moved the figures:**
- **Texas: the 11/12 list** (posted 11/13). Five lines are withdrawn: Yoakum Community Hospital ×2, LLano Regional, Sol 2 Soul and Brookshire Brothers. Hospital rows go from 286 / $191,913,856.31 to 283 / $190,218,129.73.
- **Nebraska: FSRS extras held.** Session 117a made NE COMPLETE. The standing 116d rule holds FSRS extras in COMPLETE states, so `R/09b` now holds 21 NE FSRS rows ($10,319,625). Three of them are hospital rows, $2,540,586.72: Antelope Memorial, St. Mary's Community and Box Butte General. **Owner question:** NE's COMPLETE rests on "fully obligated", which makes its roster a floor rather than a complete roster. Should the extras-hold apply to full-obligation states (NE, SD, WV), or only to states whose roster is claimed complete (VT, UT)?

**Verified vendor figures did not move.** Award $167,506,827.60, split $42,750,000 PUBLIC (NC's Trillium and Vaya) and $124,756,827.60 NON_PUBLIC. Intent $48,233,747.84. Contract maximum $25,965,898. Obligation $2,205,500. Amount types are never added.

**Unnamed contractor money (CMS 10-14 edition):**
- **Headline, CONTRACTOR_ONLY:** $116,332,666.43 on 41 lines.
- **MIXED:** $32,613,736.29 on 4 lines (NH $20.4M, KS $9.2M, MO $2.0M, KY $1.1M). Each line carries its quote in `cms_unnamed_contractor_lines.csv`.

### FSRS Routine (Task 0a)
- **One firing since Tue 11-10 21:17Z:** 11-10 21:18Z. The next is Tue 11-17 21:17Z.
- **That run tripped on new filings in 11 states:** AL 49 ($62.7M), IL 1, IN 9 ($24.3M), MN 90 ($85.0M), NC 3, NM 6 ($141.0M), OK 19, OR 7, SD 6, TN 66 and VT 9.
- **Re-read live today:** 493 new reports, $566,671,045, in 13 states. AK, CT, OK, SD, IN and AL have grown since the 11-10 run.
- **Alabama is the one new filer** among the 19 non-filing states: 171 subawards, $197,899,829.
- **Nothing was archived or applied.** The filings are recorded in `fsrs_new_filings_2026-11-16.csv` (`applied = FALSE`).
- **Applying them is a next-session job, with the independent duplicate check that session 116d needed.** That check found 30 duplicates in 691 new rows. AL ($197.9M) is a COMPLETE state whose roster already covers most of it, and NM's $141.0M mirrors last time's state-agency pattern.

### OHSU Office of Rural Health (Task 0b)
- **What FSRS says.** The whole purpose text is *"RHTP - OFFICE OF RURAL HEALTH (ORH) GRANT"*: subaward 62245-0, 2026-08-24, $46,864,923.88, filed by OHA. It does not say where the money goes.
- **What OHA says.**
  - The 2026-05-07 OHA bulletin (`data/evidence/OR/2026-05-07_oha_transformation_fund_bulletin.html`): *"The Oregon Health Authority (OHA), in partnership with the Rural Health Transformation Program (RHTP) and the Office of Rural Health (ORH), is announcing funding for rural hospitals and Rural Health Clinics (RHCs) across Oregon."*
  - The 04-10 release: *"Each rural hospital can receive direct grants, with a total of $35 million … Each rural health clinic can receive direct grants, with a total of $10 million … OHA also plans to partner with the Oregon Office of Rural Health … technical assistance"*.
- **The eligible class is MIXED** (hospitals and RHCs), so the **summary call is NOT_HOSPITAL**. It is not the ICAHN rule.
- **No row is added and the strict OHSU rows are unchanged.**
- **Overlap warning.** The OR file already carries that Transformation Fund: 35 hospitals at $34,998,000 and 99 RHCs at $9,900,000, $44,898,000 in all. The ORH grant exceeds that by $1,966,923.88, about the size of a TA line. So the $46.9M is very likely the money paying those rows. That reading rests on value alone, the fragile kind of evidence (§0.2). Adding the $46.9M as a pool would count roughly $35M of hospital money twice. FSRS keeps it as `fsrs_amount` on OR#244 (MATCHED_PRICED_DIFFERS), and it enters no figure.

### Utah's held FSRS extras, $39.6M (Task 0c)
- **They overlap the roster; they are not new money.** Both sit with state agencies, and Utah is COMPLETE with its roster at $193,095,907 against a $195,743,566 allotment. Adding $39.6M would put Utah about $37M over its allotment.
- **$26,500,000 filed under "UTAH DEPARTMENT OF AGRICULTURE".** The record's own description is *"RHTP AGREEMENT WITH UETN FOR LIFT INITIATIVE TELEHEALTH"*. This is the roster's UETN line, *LIFT 5.1 Telehealth Consortium*, at exactly $26,500,000, filed under the wrong UEI.
- **$13,085,562 to USBE.** It is subaward 251693879, the same number the roster prices at $3,188,804 (*PATH 1.2 Gold Medal Schools*, 07-10), re-filed on 09-03 at a new amount. FSRS has no amendment field, and the record is in `fsrs_amendment_uncertain.csv`. It is either a restatement or a later-period amount; either way it is the same agreement.

### rhtptracker.com (Task 6): recommend option (2), a weekly lead check, never a figure source
- **Who runs it:** Moodr Health, a private company: *"not operated by CMS or another government agency"*.
- **Terms of use:** internal research use is permitted. robots.txt bars `/api/`.
- **Readability:** pages read over plain HTTP.
- **Accuracy:** the same defects as RCJ. Texas's $680.6M multi-year total is shown as awards; Louisiana carries a wrong-programme quote; CMS's report is filed under California. It has no rosters for IA, LA or MA.
- **Worth having for leads.** It surfaced the first readable Massachusetts RHTP documents (the COMMBUYS bid BD-27-1039-EHS01-EHS01-134186 and MassTech's NOFO 2027-MeHI-02), two Iowa RFPs and two NH FHC RFA/RFQ PDFs.
- **Its pointer led to HHSC's 11/13 Texas list**, which the TX probe had missed. Full assessment: `docs/session117_rhtptracker_assessment.md`.

## Task 0 (other items)
- **(d) Held pools re-tested** against the live 11-16 filings, without archiving them: `fsrs_pool_retest_2026-11-16.csv`.
  - **No pool reconciles within 1%, so nothing was swapped.**
  - IN GROW regions: +1.6% to +65.4% (Region 1 is the closest).
  - OK CHW: −95.7%. SD CCBHC: −24.5%. NC SBHC: −40%.
  - State pools: IN −93.2%, OH −89.0%, OR +73.9%, SD −68.5%, WA +40.6%.
- **(e) Workbooks.**
  - Every workbook in `output/` opens in openpyxl in normal mode, and `test_output_workbooks.R` checks them all.
  - **117a's `completed_states_2026-11-13.xlsx` did not open, because of dangling drawing relationships.** It is repaired, and `R/08b` now strips them on every write.
  - `rhtp_xlsx_strip_dangling_rels()` now normalises its path. A relative path had deleted the workbook, because `zip::zip()` resolves it against its temporary root.
- **(f) Unnamed contractor money is split CONTRACTOR_ONLY / MIXED, each line with its quote.** CONTRACTOR_ONLY is now the first line of the vendor list's "Unnamed contractor money" sheet. It also leads the Year 1 workbook's note, with MIXED shown beside it and never added to it.

## Year 2 gap
- **CMS published all 50 FY2027 awards on 2026-11-09** (*"Trump Administration Announces $10 Billion in Second Year …"*, table "FY 2027 Award"). `R/03cu_cms_fy2027_allotments.R` archives the release, strips the Mapbox token by name and keeps both digests. It parses the table into `cms_fy2027_allotments.csv`. The 50 rows sum to $10,000,000,001, the $10 billion plus $1 of publisher rounding, which is asserted, not adjusted. The file is Tier 1, Budget Period 2, and enters no Year 1 figure.
- **`rhtp_footer_class()` now recognises BP1 + FY2027 (`ALLOTMENT_PLUS_FY2027`)**, and `rhtp_assert_footer_not_allotment()` refuses that figure as a pool. Footers met this session:
  - MT $473,250,028.01 and WV $401,557,453;
  - CA $464,745,131.25 and AL $402,683,127.94;
  - NC ROOTS $429,832,929.77 and IN GROW $415,836,487.99.

  CA is recorded in `year2_signals.csv`, quoted from its archive.
- **Task 1: every bespoke phrase check is routed through the Year 2 rule.**
  - **Centrally.** `rhtp_probe_run()` re-reads every bespoke TRIPWIRE. Where every string it quotes is a Year 2 string, the row logs YEAR2 and is not raised. Name trips and ERROR rows are untouched, and mixed quotes stay TRIPWIRE. This covers every probe.
  - **At source.** `rhtp_year2_screen()` filters candidates before a finding is built, in three probes:
    - **TX** (`R/03ce`, called by `R/03n`): list links and labels;
    - **OK** (`R/03t`): Funding Recipients dropdown programmes, legislative reports and the LifeCare recipients text;
    - **MS** (`R/03ak`): Governor's newsroom headlines.
  - **Fixtures.** `tests/testthat/test_year2_bespoke_routing.R` tests the central check, TX, OK and MS, each with a Year 1 control that still trips.
  - **TX's list watch was also blind.** HHSC moved to the stable name `rhtp-award-recipients.xlsx`, which the old pattern did not match, so the 11-13 trip read "NO award-recipient list". It now matches, and compares the "(Updated …)" label.
- **The CMS Routine's misses.**
  - **11-12:** `R/00 --run` writes `cms_national_events.csv` (since session 116), which was outside the Routine's write set, so the run declined to publish. Explained in `probe_gaps_explained.csv`.
  - **11-16:** this firing blocked on the 11-12 gap.
  - **Fixed:** the national Year 2 events were collected interactively, and the new CMS Routine's write set includes the file.

## Task 2: runners and Routines
- **MN moved to new runner `session_01Y1P5eQtSecgVMEWU1YbYUZ`.**
  - New Routine `trig_01HoMz12EJy5235Sqfipm8mM`, same cron `10 18 * * 5`.
  - The old Routine `trig_018tLxX82fNyKgxw5JkRw5PV` is disabled and chained in `routines.csv`.
  - The prompt is identical to the committed one apart from the runner id (3 occurrences), checked by substituting the old id back and diffing.
- **CMS moved to new runner `session_01Y1P5eQVuq4b7kgGCqRYjws`**, because it was the runner nearest the 784k compaction line (710,778).
  - New Routine `trig_01CwTmWX2sdYLPNtEBgRJcUd`, same cron `0 13 * * 1,4`.
  - The old Routine `trig_01LUqkDnDGErLj9N8SJUDb1C` is disabled and chained.
  - The prompt differs only in the runner id and in edit 6 of `R/routine_prompts_worktree.R`, which adds `cms_national_events.csv` to the write set in all 4 places.
  - `--check` matches all 44 prompts.
- **California's old Routine `trig_01JEYQK9ZNMVpe27H19DFjzX` is deleted**, because its successor logged on `main` on 11-14. It is recorded in `old_deleted`.
- **Runners above 600k** (`get_session` `used_tokens`, read before the moves):

  | Runner | Tokens | Status |
  |---|---:|---|
  | CMS | 710,778 | moved |
  | MO | 690,141 | |
  | NEWSROOM | 676,717 | |
  | MN | 670,367 | moved |
  | IN | 636,823 | |
  | SC | 636,457 | |
  | MT | 630,182 | |
  | LA | 628,710 | |
  | DE | 624,338 | |
  | KS | 613,912 | |
  | NC | 600,412 | |

  Next highest: ID 587,409, CT 573,440, CO 567,279. **Move MO and NEWSROOM next.** Both are under 700k, so no firing is at risk this week.

## Task 3: Colorado re-based
**What changed on the programme page:**
- a grantee kickoff notice for 11-12 (*"Invitations will be sent directly to grantees, this is not an open meeting"*);
- the Advisory Committee and stakeholder meetings moved to 11-16 and 11-17;
- *"Colorado's BY2 Documents Coming soon!"*;
- the sidebar link renamed *"Colorado Annual Report through 7.31.26"*.

**Outcome:**
- **No recipient is named.** The page is re-based to `recheck/2026-11-16/CO/`, and the live probe reads UNCHANGED.
- **The renamed link points at a new file**, but its First-Tier Entities tab carries the same four entities and obligations as `co_contracts.csv`. The register watch keeps the old URL, which is still served; re-point it if that URL dies.

## Task 4: probe log since 11-09 (311 lines: 73 TRIPWIRE, 3 YEAR2, 119 CHANGED, 4 ERROR)

**Moves a dollar:**
- **TX: the 11/12 list is extracted** (above).
- **NE:** the FSRS hold, a consequence of 117a's COMPLETE (above).
- **FSRS:** new filings, reported and not applied (above).

**Held for the owner (each over the line, or needing a ruling):**
- **TN: "$422 Million … 138 Projects".** The amounts are *"Amount Awarded or Requested"* totals *"over the next five years"*, about twice the $206M allotment, and give no Year 1 split. About 23–25 hospital lines carry $117.5M–$135.6M. **Held:** a multi-year roster.
- **WA: HCA's "rht-obligated-funds.pdf" (11-05).** *"Twenty-eight hospitals were approved through a competitive bid process"* for maternal, emergency and specialty services, $9.67M. Every amount is labelled "Estimated amount" and there is no split. It would be a POOL_NAMED candidate if estimates were accepted. Also: 45 provider-technology recipients ($17.02M, shared with non-hospitals), plus mobile crisis, CCBHC and OTP lists. **Held:** an estimated obligation summary, not an award document.
- **IN GROW: the regional page dropped 10 member names** (7 in Region 2, 3 in Region 5) and added none; the region amounts are unchanged.
  - Region 5 would go from 8 of 16 typed hospitals (a tie, NOT_HOSPITAL) to 7 of 13, a strict majority. The summary call would flip to **HOSPITAL (+$16.7M best estimate)**.
  - **Held:** removing members on a disappearance alone needs a ruling.
- **KY: Martin County Health Department is the Big Sandy RCH Hub Lead** (named on healthy-ky.org/rch; a local health department, no amount). Not added; $0 either way.
- **SC: "SC RHTP Annual Report – Year 1"** (CMS annual-report workbook, as of 7/31). First-tier obligations: BCG $5,000,000, Milliman $10,000,000, BDO $3,990,000, Slalom $2,079,813.31, SCRA $5,025,452.32 and SCDHHS $569,133.31. It states *"no subaward agreements executed as of 7/31/2026"*. These are contract-layer leads; SC has no contract file yet.

**Read, nothing new priced:**
- **VT:** the 11-12 update adds one row, *"MOU with DVHA to support regional transformation managers"* ($402,500). It is an inter-agency MOU, excluded like the GMCB MOU. R/03at's `vt_is_mou()` and the page pins will break on the next re-fetch until it learns the DVHA MOU.
- **WY:** "Year One Award Summaries" is the same Drive folder; all 4 files are byte-identical. Furniture.
- **CA:** the roster is unchanged at 108 rows / $138,464,043.97. The footer is now BP1 + FY2027 (above).
- **AL:** the subrecipient kickoff FAQ names nobody.
- **IA:** a rescinded RFP (colorectal screening) and a rescinded Rural Residency RFP. The four Healthy Hometowns NOIAs are still unposted. The Year 2 release is held.
- **LA:** *"All RHTP Budget Year 1 award notifications have been completed as of October 30, 2026. Contract execution will be completed in November 2026."* The parser anchor needs re-basing.
- **MO:** Digital Backbone and workforce solicitations. The 11-12 release names two SMRP hospitals already priced.
- **ND:** three rounds marked "Awarded" (5, 8 and 13 applicants), nobody named.
- **NE:** the Year 2 release ($219.2M) is held, and Catalyst Fund cohort 1 is a solicitation.
- **IN IDOA:** the MOCC letter is a renamed link to a known letter. It covers three vendor recommendations totalling $41,690,776 (five-year maximum), known since session 100.
- **Year 2 signals (YEAR2 rows):** MT ("CMS will notify states about their Year 2 awards later in November") and NV (Year 2 applicant guide).
- **Menu or furniture noise to re-base after reading:** CT, HI, ME, NM, SC, WA, WI, MS (Innovative Pilot Q&A) and NH (FHC CAH RFA dates, known).
- **ERROR (our access, not the state):** KS KDHE 403 (11-09, 11-16); MS `dom_completed` SSL chain (11-10, 11-13).

## Task 7: vendor-category follow-ups (no hospital figure changed; the partition is identical to the cent before and after `R/07 --apply`)
- **(a) `out_of_state` is now TRUE / NOT_SHOWN.** 3,182 award rows and 237 contract rows now read NOT_SHOWN (every former FALSE). Updated: spec §8.1, CLAUDE.md §7, the Year 1 workbook definitions, and the vendor list's "Out of state (V6)" column.
- **(b) The source label beats the dictionary.** The new rule 4c reads `config/spend_category_source_labels.csv`. Colorado HealthTech Solutions moves from DATA_TECH_VENDOR to CONSULTANT on Colorado's *"Other Consulting"*, and the dictionary class TECH_VENDOR is recorded in the basis. It is a lead, not a verified case, so no verified total moved.
- **(c) PUBLIC / NON_PUBLIC split.** The Vendor spending sheet carries `vendor_public_<type>_usd` and `vendor_non_public_<type>_usd`. The vendor list has a "Public vs non-public" sheet and splits "By category". NC's Trillium and Vaya ($42,750,000) are PUBLIC. NC's other two hub leads, Impact Health and Access East, are private nonprofits and sit under NON_PUBLIC; the owner's 116f ruling marks only Trillium and Vaya public.
- **(d) UKHS Care Collaborative is confirmed PROVIDER_PASS_THROUGH on all five lines** (VV002–VV006): the $37,849,250 incentive line plus four subawards totalling $49,295,576. No change.

## Task 8: completed-states table
- **`output/completed_states_2026-11-16.{xlsx,html}`** covers 11 states.
- **n/m:** West Virginia, whose state-sourced awards are 36.6% of its allotment.
- **Dagger (under 90% published):** FL, ID, NE, SD, WV and WY, each with the owner's footnote verbatim.
- **WA and NC stay PARTIAL.**
- **Total row:** allotment $2,230,243,286; awards $1,841,482,439.80 (82.6%); best estimate $752,622,490.26 (40.9% of awards); strict $695,077,021.55.
- Pinned in `test_08b_completed_states_table.R`.

## Files
- **New:**
  - `R/03cu_cms_fy2027_allotments.R`
  - `data/raw/cms/2026-11-16/`
  - `config/spend_category_source_labels.csv`
  - `fsrs_new_filings_2026-11-16.csv` and `fsrs_pool_retest_2026-11-16.csv`
  - `recheck/2026-11-16/{TX,CO,CA}/`
  - `test_year2_bespoke_routing.R` and `test_08b_completed_states_table.R`
  - `docs/session117_rhtptracker_assessment.md`
- **Rebuilt:**
  - `year1_summary_2026-11-16.{csv,xlsx}`
  - `year1_vendor_summary_2026-11-16.csv`
  - `verified_vendor_list_2026-11-16.xlsx`
  - `completed_states_2026-11-16.{xlsx,html}`

## Next session
- **Merge timing.** Merge before Tue 11-17 21:17Z (FSRS) and never Mon/Thu 13:00–14:00Z. CMS's new Routine first fires Thu 11-19 13:00Z and MN's on Fri 11-20 18:10Z. Delete each old id once its successor logs on `main`.
- **FSRS 11-16 filings.** Archive (`R/09a --fetch` to a new dated directory), plan, have an independent duplicate check, then apply.
- **Owner questions:**
  - NE extras-hold for full-obligation COMPLETE states;
  - the TN five-year roster;
  - WA's 28-hospital estimated pool;
  - IN GROW member removals (Region 5);
  - KY Martin County HD;
  - SC consultants as a contract file.
- **Extractor fixes and re-bases:** VT `vt_is_mou()` (DVHA MOU); LA anchor; WY furniture.
- **Runners:** move MO and NEWSROOM.
