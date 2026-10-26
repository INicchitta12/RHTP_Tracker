# Session 105 (2026-10-19): the Ohio ruling, probe housekeeping, CO/DE/NH leads, the probe log, the pre-10-30 watch list

**Start.** The session started from `main` at `d96a5c4`, which is PR #108 (`claude/festive-bell-9r9vf7`, session 104), with full history (`git fetch --unshallow`). No Year 2 work was done. No CMS release since 10-16 announces FY2027 amounts.

**Session 104's suite.** Its doc records no result, so the suite was re-run on a clean detached worktree of `d96a5c4`. Result: see "Suite" at the end.

## Hospital partition: unchanged

Published figures, with `SOURCE_SUSPECT` rows left out. The buckets are never added together.

| Bucket | Rows | Dollars | States |
|---|---:|---:|---|
| NAMED_HOSPITAL | 1,576 | $1,431,975,278.58 | 34 |
| POOL_NAMED_HOSPITALS | 7 | $85,555,171.43 | NE, CT, NV, OH |
| POOL_UNNAMED_HOSPITALS | 5 | $69,323,109.17 | IL, RI, NE, HI |

The internal figure (with SOURCE_SUSPECT) is still 1,578 / $1,435,430,699.58. The rural cut is still 410 / $367,023,056.72. `test_claude_md_status_table.R` asserts these against the files.

## Task 0: the Ohio pool row stays (owner ruling)

- **The row stays.** ODH's *"$30.3 million in one-time direct payments to 22 rural hospitals"* prices that component for the 22 hospitals alone. It remains one `POOL_NAMED_HOSPITALS` row at $30,300,000, never divided (§6.2).
- **The rule, now in CLAUDE.md §7** ("A pool is judged per priced component, never by its headline (session 105)"):
  - The shared-with-non-hospitals test applies to each separately priced component of an announcement, not to its headline total.
  - A component is a pool only when the source prices it for named hospitals alone.
  - Ohio's other $61.7M ($31.4M CINs/Hubs and $30.3M maternal care) names non-hospitals and stays out of every bucket.
  - The 22 hospital rows at $0 stay either way.
- **Code.** The `R/03an` header comment records the ruling. The pool row's `determination_basis` now says "confirmed session 105". This is a one-cell text change in `oh_year1_awardees.csv`; no amount or code moved.
- **Tests** (`test_03an_oh_year1_awardees.R`):
  - The pool row rests on the hospital-only component, and every recipient it names is a `HOSPITAL_OR_SYSTEM` row.
  - No row carries the $92M, the $31.4M, or the maternal component. The maternal check goes by `award_pool`, because that component is also $30.3M.
  - Counterfactual: rewriting the ODH sentence to "22 rural hospitals and health centers" makes `oh_assert_s104_sources()` refuse. That function now takes the hospitals page body as an argument so the test can do this.
  - CLAUDE.md §7 carries the rule's heading.

## Task 1: the session-104 probe proposals (approved)

I read every page's diff word by word, live against its archive, before re-basing it. After each change, a live interactive probe logged UNCHANGED (`logs/probe_results.csv`, 2026-10-19 16:02Z–16:10Z).

| State | Change | Diff read | Live probe |
|---|---|---|---|
| TX (`R/03n`) | Re-based the six probe pages (deleted the six files, then ran `--fetch`, which re-fetches only missing files) | Every page gains a "Close" menu token, and "Request for Application:" becomes "Open Enrollment:". Nothing else. The BP1 report still names 33 districts. The only weekly list linked is still `10-15-2026-list-award-recipients.xlsx`. | UNCHANGED (6) |
| NC (`R/03ah`) | Added `trillium` furniture "NC Rural Health Transformation Program". Re-based all five probe pages. The manifest notes the re-base. | All five pages: a "Report an Accessibility Issue" link and menu items dropped. `roots_page` and `opportunities` add a "Rural Health Workforce Transformation" side-nav entry. `opportunities` moves the Rural Health Innovation Fund to current. `trillium`: a Region 2 "Rural Ready Roundtable" notice (the name trip), and the Advisory Board text re-worded. The five Trillium regional RFAs are untouched ("Closed - Under Review"). Both rosters (39 MIH, 5 Hub Leads) are unchanged. | UNCHANGED (5) |
| AR (`R/03ai`) | New `AR_NAME_FURNITURE` (the menu run) on `home2`, `rise`, `heart`. Re-based `home2` (recheck/2026-09-25/AR/, manifest digest updated with the prior digest kept) and `resources`, `rise`, `heart`. | The only change on all four pages is a new "Resource Library" menu item. Both award-list links are present. | UNCHANGED (4) |
| CO (`R/03bo`, run by `R/03az`) | New `CO_NAME_FURNITURE` for `programme` (two sidebar runs). Re-based `programme` (`rhtp_watch_archive`, appended manifest line). | Sidebar only: "Colorado's Approved Documents" becomes "BY1 Documents", plus the new "Colorado Annual Report as of 6.31.26" link (read under Task 2). The `awardees` roster is word-for-word identical (92 lines). | UNCHANGED (2) |
| CA (`R/03ab`) | Installed session 104's tested scope anchor: `California Rural Health Transformation \(CalRHT\) (?:CalRHT Grant Funding Opportunities\|Rural Health Transformation Program \(RHTP\))`. Re-based `funding`, `calrht`, `newsroom`. | All three pages: the stale "Planned Service Outage … (10/16/26)" banner. `funding`: the Train-the-Trainer section and the "template superseded" label. `newsroom`: HCAI non-RHTP releases. | UNCHANGED (3) |

**CA's Train-the-Trainer section was read in full; it is not an award.**
- What it says: "In partnership with University of California, Irvine (UCI) Office of Medical Education, the CalRHT Program will develop, prepare, and deliver two Train-the-Trainer (TTT) programs" (IHOPE geriatric behavioural health; Maternal Behavioral Health).
- It carries no amount and no award language.
- UCI is a university, so the hospital effect is $0 even if this turns out to be a contract.
- With the new anchor, the tripwire did fire on "University of California | Office of Medical Education | CalRHT Program | Maternal Behavioral Health". Re-basing put those names into the baseline.

**Overlay caution, recorded.** I ran `R/03ah --build` once to prove that the re-based NC archive reproduces the file. It rewrote all 45 lines of `nc_year1_awardees.csv`, because a rebuild drops sessions 49 and 71's overlays (CLAUDE.md, "Overlays"). I reverted it; nothing was committed from it. `--validate` passes on the re-based archive.

## Task 2: leads (extract nothing). Hospital effect: $0 in all three states.

Files are saved outside the repo, in `/tmp/claude-0/-home-user-RHTP-Tracker/3202c098-9448-52b5-9e09-7b83586a7739/scratchpad/task2/` (CO and DE), each with a SHA-256 and the fetch time in its `NOTES.txt`. They are not archived as evidence.

**Colorado: no new recipient.**
- **The document.** "Colorado Annual Report as of 6.31.26": `https://hcpf.colorado.gov/sites/hcpf/files/Colorado%20Annual%20Report%20as%20of%206.31.26.xlsx` (HTTP 200, 1,879,322 bytes).
- **What it is.** CMS's "RHT Program Annual Report" workbook, filled in by the state. Its README: *"The purpose of this workbook is to facilitate the State's annual reporting requirements as a recipient of RHT Program grant funds."*
  - It is the state's own report as of mid-2026.
  - A dollar on its First-Tier Entities tab is an OBLIGATION to a first-tier entity, not a subaward.
  - Under session 97's rule, it is a lead and never an award row.
- **First-Tier Entities (4):**

  | Entity | Role | Obligated | Disbursed |
  |---|---|---:|---:|
  | CDPHE | state agency | $13,825,396 | $0 |
  | Colorado Rural Health Center | technical-assistance provider | $749,506 | $53,506 |
  | HealthTech Solutions, LLC | consulting | $1,880,900 | $186,310 |
  | HCPF | state agency | $2,381,379.17 | $524,134.73 |

- **Other tabs.**
  - Use of Funds: 15 obligation lines, summing to $18,837,181.
  - Downstream Reporting: names 0 entities.
- **Against our file.** None of the four names is in `co_year1_awardees.csv`, and none is a hospital. The report names no grantee from the 92-line roster.
- **Plan language.** "Colorado will award more than 80 percent of its RHTP funding through grants to rural health providers."

**Delaware: nobody named.**
- **The DHSS page still says:** "Applicants selected for second-round consideration will be notified on or before October 12."
- **The Catalyst Fund page** (`choosedelaware.com/why-delaware/innovation/catalyst-fund/`) shows the RFP is for a programme OPERATOR of the "Delaware Rural Health Challenge" accelerator, not for awardees:
  - "Second-Round Notification: On or before October 12, 2026; Operator Under Contract By: November 1, 2026; All Program Funds Disbursed By: September 30, 2027."
  - "Catalyst Fund dollars are paid directly to selected startup companies."
- **Who could receive money:** an operator and startups, both vendors. No hospital can be a recipient.
- **Footer.** It prints $157,394,963.86 at 100 percent: the allotment, Tier 1.
- **No selection is published.** Checked: news.delaware.gov (HTTP 200, no firewall page; its only RHTP items are the already-read 09-24 FQHC and 10-14 physician-workforce releases). DPP's press index redirects to /error/.

**New Hampshire: still HTTP 403, so I stopped.** Every request used the project agent.
- 403: `gonorth.nh.gov/`, `www.gonorth.nh.gov/`, `gonorth.nh.gov/rural-health-transformation`, `www.governor.nh.gov/` (reached by a 301 from `governor.nh.gov/`), `www.governor.nh.gov/news-and-media`, `fstems.dos.nh.gov/`, `www.nh.gov/safety/divisions/fstems/`, and the dhhs.nh.gov RHTP page.
- The Laconia transcript was not used. It stays a lead, not a source.

## Task 3: the probe log since 2026-10-19, and coverage

**Nothing in the log moves a hospital dollar.**

| State | Line(s) | Reading |
|---|---|---|
| KS 08:13Z | ERROR (HTTP 403, KDHE) | Access, as recorded since session 95. Not a statement about Kansas. |
| CO 09:11Z | CHANGED + TRIPWIRE `programme` | Sidebar furniture, plus the Annual Report link (Task 2). Fixed and re-based in Task 1. |
| DE 11:42Z | `programme` CHANGED | Read in session 104: DHSS menu deletions, plus the Catalyst Fund RFP link (Task 2: an operator RFP, nobody named). Not re-based (not in the approved list). |
| ME 13:51Z | UNCHANGED (interactive) | Session 104's re-base check. |
| AK 14:14Z | UNCHANGED | — |
| CT 15:42Z | CHANGED `opm`, `programme`, `dmhas_rfps`; TRIPWIRE `programme` | NOISE, read live 10-19. `programme`: a stray "-->" (an HTML comment leak) is welded onto the menu run, and that is the name trip. `opm`: the CTsource bid link for OPM's State Police / DOC **staffing-study RFP** changed (bid 145966 → 146239); that RFP is not RHTP. `dmhas_rfps`: a new **Opioid Services Unit "Recovery Centers"** RFP (deadline 2026-12-18; opioid money, §6.2) and a Homeless to Housing "Addendum 2". No RHTP award. |
| TX, NC, AR, CO, CA 16:02Z–16:10Z | UNCHANGED (interactive) | Task 1. |
| NEWSROOM 16:53Z (merged from `main` after write-up) | TRIPWIRE DE, TX, MD; CHANGED on 14 index pages | **Already handled, nothing new:** TX "Recipients of $78 Million in Rural Texas Strong Grants" (extracted session 103), MD "$16.4 Million … Workforce Awards" (extracted session 104), DE "… Strengthen Physician Workforce" (10-14, read session 102: students as recipients, no hospital). These are stale NEWSROOM baselines. A re-base after reading is proposed, not done. |

**Hawaii.** The first firing (`trig_017PbAESTaaMfYZ3nKcS3j1m`) ran at 18:35Z and its line is on `main` (`5c74dd7`) under that Routine's own origin. Four pages read UNCHANGED (`shpda`, `rhtp_home`, `rhtp_funding`, `doh_news`). `gov_news` read CHANGED with no finding: the probe's RHTP-headline check passed, and a live headline diff at 18:52Z showed no new RHTP item. Coverage on `main` after the line: "193 due firing(s) since the logging fix; all logged except 4 EXPLAINED miss(es)". CMS 10-19 13:00Z falls due at 19:00Z and is already explained.

**Coverage.** `Rscript R/probe_coverage.R --check`: "192 due firing(s) since the logging fix; all logged except 4 EXPLAINED miss(es)". A fifth explained miss, CMS 10-19, is added below; it was not yet due when the check ran.

**Standing trips that hide real ones.** These three are not new today, but each trips on the same already-read noise at every firing. A real change on one of them would arrive as one more TRIPWIRE in a column that is always red. They are proposed, not done; each is an owner call, because none was on the approved list.
- **WY `programme`.** Trips every firing since 10-09 on "Year One Award Approvals View Year One Award Approvals Project and Budget Narratives". Session 98 read it: a link to the already-extracted approvals PDF, SHA match. Session 98 proposed furniture plus a re-base.
- **MS `funding` and `home` (10-16).** 17 and 2 names. These are the Innovative Pilot Program links ("Apply for the Pilot Program Grant | Download the Innovative Pilot Program NOFO | …") against a pre-October baseline.
- **CT `programme`.** The "-->" run.

**MS access.** `dom_completed` (DOM Completed Procurements, `medicaid.ms.gov/resources/procurement/completed-procurements/`) returned HTTP 404 on 10-16. On 10-19, `/resources/procurement/` is also 404. The home page is 200 but carries no procurement link, so the site looks redesigned. Logged as ERROR, which is correct: this is our access, not Mississippi.

### Runner context

Read 2026-10-19 ~16:30Z from `get_session` (`context_usage.used_tokens`), for all 41 RHTP Routines. Every trigger id in `config/routines.csv` is enabled, and no two Routines share a runner.

- **No runner is above 700k.**
- **Four sit between 600k and 700k:** MT 677,649, AK 639,297 (compacted), CMS 620,404 and TN 618,837 (compacted). MT is the one to move first.
- **Next band:** NE 568,933, NM 565,067, ND 558,108 and OH 551,077.
- **Hawaii's runner** (`session_01BddosbdNKAgH1S8vFpXvFt`) is idle at 0 tokens.

**CMS 10-19 13:00Z is a real miss, now explained.**
- The runner reported SUCCEEDED, but no line reached `main`.
- **Cause:** PR #106 (session 103) merged at 13:32:38Z, in the middle of the run (13:00–13:48Z). Session 103's interactive CMS run had rewritten the same three files: `cms_newsroom_topic_index.csv`, `cms_state_announcements.csv` and `logs/cms_press_manifest.csv`. The runner's `git pull --rebase` conflicted on them, and it aborted, which was correct.
- **Recorded** in `config/probe_gaps_explained.csv`. No line was back-filled (§2.2a).
- It was not yet "due" under the six-hour grace when the check ran, which is why `--check` was still clean. It would have failed after 19:00Z.
- **The lesson:** merging a branch that carries an interactive CMS run while the CMS Routine is mid-firing (Mon/Thu 13:00–~13:50Z) orphans that firing. Merge outside that window.

**CA's runner is marked need_input/BLOCKED** on the old scope anchor, which has failed since 10-10 per its own summary. Task 1's anchor fixes it once this branch is on `main`.

## Task 4: the pre-10-30 watch list

Next firings are given in UTC, from `config/routines.csv`, counting from 10-19 16:30Z.

| Event (window) | Probe and what it reads | Routine firings before 10-31 | Will a Routine see it? |
|---|---|---|---|
| **AR**: round 1 and 2 intents obligating (by 10-30) | `R/03ai`: the home page's award-list link count (a third list trips), and the initiative pages | Sun/Thu 20:20: 10-22, 10-25, 10-29 | **Only if AR posts a new list.** DF&A publishes no obligation or execution status. Intents becoming obligations is **not visible** to any Routine. |
| **NY**: RCHI contracts (start 2026-09-01 passed; the obligation deadline is 10-30) | `R/03ag`: programme, RCHI roster, press index, Contract Reporter (counters only; UNREADABLE for content) | Sun/Wed 11:10: 10-21, 10-25, 10-28 | **Roster or press changes: yes. Contract execution: not visible.** No NY source we can read publishes it. |
| **WY**: Year 1 obligation deadline "End of October 2026 (executed contracts/agreements)"; committee meets 11-04/05 | `R/03aj`: programme page and Drive-folder documents | Tue/Fri 21:10: 10-20, 10-23, 10-27, 10-30 | **Yes in principle, but masked.** The probe trips every firing on the known approvals link, so a real change reads as the same TRIPWIRE. The committee's own record of execution comes after 10-31. |
| **LA**: "CEA / contract completion Current – October 30th"; Notices of Intent sent privately 10-02; denials "by October 16" | `R/03ae`: programme, funding, legislative-reports pages | Wed/Sat 12:50: 10-21, 10-24, 10-28, **10-31** | **Not visible unless LDH posts it.** Notices go to applicants privately. Only the 10-31 firing falls after the deadline. SR 198's report (due 10-15) is still unposted, and `leg_reports` would see it. |
| **MS**: WEI and EmPATH "next 30 to 45 days" from 09-14 = 10-14 .. **10-29**; EHR Replacement opens 10-21 (Tier 2); Innovative Pilot awardees "January 2027" | `R/03ak`: funding, home, Governor's newsroom, release; `dom_completed` is **404** | Tue/Fri 09:40: 10-20, 10-23, 10-27, 10-30 | **Partly.** The Governor's newsroom (the channel MS used before) is read. DOM's procurement page, where intent-to-award notices were posted, is unreadable. The funding and home pages trip on stale links every firing (masked). |
| **TX**: HHSC's weekly Rural Texas Strong lists | `R/03n`: trips on a new `list-award-recipients.xlsx` link; BP1 report count | Fri 13:20: 10-23, 10-30 | **Yes.** Two firings. A list posted Fri after 13:20 waits a week; 10-30's list is the last seen before 10-31. |
| **VA**: VHCF Provider Productivity awards ("October 2026") | `R/03bb`: `vhcf_news` (VHCF news index) and the VHHA Foundation page | Tue/Fri 10:20: 10-20, 10-23, 10-27, 10-30 | **Yes.** |
| CA: remaining CalRHT notices "by late October 2026" (private, Submittable) | `R/03ab` | Wed/Sat 17:00: 10-21, 10-24, 10-28, 10-31 | Only if HCAI posts a roster. |
| KY: Big Sandy RCH Hub Lead | `R/03af` (FHKY page) | Mon/Thu 19:30: 10-19, 10-22, 10-26, 10-29 | Yes. |
| NH: FHC CAH RFA opens "late October" (Tier 2) | `R/03bm` | Wed 18:10: 10-21, 10-28 | Yes (FHC's own site is readable; nh.gov is not). |
| DE: Catalyst Fund operator "Under Contract By: November 1" | NEWSROOM DE / `R/03al` programme | Mon 11:40: 10-26 | An operator (a vendor). $0 hospital either way. |
| CMS: new state releases; obligation-report refresh (after 11/30) | `R/00` | Mon/Thu 13:00: 10-22, 10-26, 10-29 | Yes. |
| **All states**: end of BP1 2026-10-30; re-check the session-97 hunt list (CA IN IA HI NC NH IL RI VA CT MO KY MD) | none | — | **No Routine does this sweep.** IL and RI have no probe at all; MD is read only through NEWSROOM. It needs an interactive session on or after 10-30. |

**Events no Routine will see before 10-31.** These need a human or an interactive session:
- AR intents obligating.
- NY contract execution.
- LA CEA completion, unless it is posted.
- WY execution: masked by the standing trip, and the committee's record falls after the window.
- MS: DOM's intent-to-award channel (404).
- The cross-state BP1-deadline roster sweep, including IL and RI.

## Queue

No item opened or resolved. The Ohio pool question was never a queue row; it was resolved by the owner ruling above.

## Vulnerabilities to state when using these figures

1. **Ohio.** The $30.3M is a rounded, announced pool whose per-hospital projects "haven't been announced yet". It is now a ruling, not a reading, but the figure is still a pool, not 22 awards.
2. **Colorado.** The state's own report obligates $18.8M to four first-tier entities, none of them grantees from the 92-line roster. Read the roster ($170.2M) and the report as different instruments: an RFA award roster, and obligations self-reported as of mid-2026. Never net one against the other.
3. **Re-based baselines.** A re-base makes today's bytes the reference. Each re-base here followed a full word-level diff, and none touched a roster's names or amounts.

## Suite

- **Session 104 on `main` (`d96a5c4`, clean detached worktree):** 0 failed, 1 expected skip (`test_00_cms_press_monitor.R:188`, the first-run branch).
- **This branch, first run:** 3 failures, all in one `test_03ah` test, "Dynatrace's per-request rpid moves the FILE digest". It read `roots_page`, and the re-based capture was served **without** the Dynatrace beacon (ncdhhs.gov, 10-19), so the test lost its sample. It now pins the same mechanism on the un-rebased `programme` capture, which still carries the beacon. The assertions are unchanged and nothing was loosened.
- **This branch, after the fix:** 0 failed, 1 expected skip (the same skip).
