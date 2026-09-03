# Session 41 — every Routine id verified live, the last three zero-signal
# states worked, and the 50-state disposition

**Date:** 2026-09-03. **RCJ quota: 2 calls** (two document proxies read as a
discovery aid for Massachusetts, whose own estate is unreachable — §0.1, never
evidence). ~40 fetches across `health.wyo.gov`, `drive.google.com`,
`engage.hawaii.gov`, `health.hawaii.gov`, `rhtp.hawaii.gov`,
`governor.hawaii.gov`, `hands.ehawaii.gov`, `www.mass.gov`, `cms.gov` and
`medicaid.gov`. **Nothing was extracted — this is the report the tasks asked
for.** Stage 00 was run live and its output committed.

---

## 1. Task 1 — every Routine id in CLAUDE.md against the live schedule

`CLAUDE.md` names **thirteen** Routine ids. `list_triggers` returns
**thirteen** enabled Routines, and every id matches one of them. No id in the
file is absent from the schedule, no Routine on the schedule is absent from
the file, and `docs/` carries the same thirteen and no others.

| State / job | Routine id | Cron (UTC) | Documented as | Last recorded run |
|---|---|---|---|---|
| CMS trigger list | `trig_01EozMStALcrUp75s32qFnJ3` | `0 13 * * 1,4` | Mon/Thu 13:00 | SUCCEEDED 2026-09-03 13:07 |
| Alaska | `trig_01U4RxGWMH8yg37UKupHqTki` | `0 14 * * 1` | Mon 14:00 | none yet (next 09-07) |
| Missouri | `trig_01RyGxdGNv6rrF8t6bT5fQdK` | `0 15 * * 3` | Wed 15:00 | SUCCEEDED 2026-09-02 15:17 |
| Wisconsin | `trig_01PEixRDWkHzpet4krJtye3b` | `0 14 * * 2,5` | Tue/Fri 14:00 | none yet (next 09-04) |
| Maine | `trig_01ALmis3jAgiLXVb6ZDLCj8Y` | `20 16 * * 2,5` | Tue/Fri 16:20 | none yet (next 09-04) |
| California | `trig_013vujTBLopT2gSmNwWJ94ig` | `0 17 * * 3,6` | Wed/Sat 17:00 | none yet (next 09-05) |
| Connecticut | `trig_01DRHN1x1WfzPjC3dpgay8s2` | `40 15 * * 1,4` | Mon/Thu 15:40 | SUCCEEDED 2026-09-03 15:40 |
| New Mexico | `trig_01DbiFhMJhaZXzYB4gi5JpwX` | `40 18 * * 2` | Tue 18:40 | none yet (next 09-08) |
| Louisiana | `trig_01BqyRZ4d8S8EvKdtCN9nmX5` | `50 12 * * 3,6` | Wed/Sat 12:50 | none yet (next 09-05) |
| New York | `trig_01G2ZijwemE2YgbAuiBirKs2` | `10 11 * * 0,3` | Sun/Wed 11:10 | none yet (next 09-06) |
| Kentucky | `trig_01FqfAJvnMzz811goNzNZYqi` | `30 19 * * 1,4` | Mon/Thu 19:30 | none yet (next 09-03 19:30) |
| North Carolina | `trig_01SepuwJWXSkqpNQ9WgJkxMb` | `50 10 * * 6` | Sat 10:50 | none yet (next 09-05) |
| **Arkansas** | **`trig_01Sw1CDPqYQKXFq4WEVRHH2a`** | `20 20 * * 0,4` | Thu/Sun 20:20 | none yet (next 09-03 20:20) |

**The task's premise — that the Arkansas id was written from a draft and never
created — is not borne out by the live schedule.** `trig_01Sw1CDPqYQKXFq4WEVRHH2a`
exists, is enabled, was created at **2026-09-03T15:28:11Z**, carries the full
Arkansas probe prompt (it refuses to act if `ar_probe` is absent from `main`,
and PR #41 has merged, so it will act), and its first firing is tonight at
20:20 UTC. It has simply never fired yet, which is what "no last recorded run"
means for it and for eight others created since their last scheduled slot.
**Every cron matches the days and times CLAUDE.md states**, including the
two with server-anchored minutes (Wisconsin, Alaska).

## 2. Stage 00 — the CMS trigger list, run live: 9 states → 12

`Rscript R/00_cms_press_monitor.R --run` against the live newsroom and
medicaid.gov. Three states have announced since 2026-08-28:

| State | Date | Headline figure | medicaid.gov |
|---|---|---:|---|
| **AR** | 2026-08-31 | $149.3M | carries it |
| **HI** | 2026-09-01 | $58M | carries it |
| **IN** | 2026-09-03 | $120M | **lagging** |

Arkansas's figure is the $149,177,618.45 this repository extracted in session
40, rounded as the Governor rounds it. Indiana's $120M is the GROW Regional
Grants pool (session 24's "where the hospital money will be"), announced the
day this ran — `R/03s`'s `in_assert_regional_not_awarded()` is the tripwire
and should now be run against the live page. **And the medicaid.gov lag
session 15 could not size has been sized**: Virginia was `CMS_NEWSROOM`-only
on 2026-08-28 and reads `BOTH` on 2026-09-03, so the secondary catches up
within six days. Five test pins on the nine-state list were re-based.

## 3. Task 2 — Hawaii, Massachusetts, Wyoming

All three hold RCJ records and **zero Tier 3 candidates** (HI 25 records,
MA 7, WY 29). `/api/v1/activity` supplied a real state URL for every one of
them — the eighth time that endpoint found the route where `/awards` could
not.

### 3.1 WYOMING — awarded, and the roster is in a Drive folder

**This is the third zero-signal state with a published, named, priced award
list** (after Florida, North Carolina and Arkansas — four of sixteen now), and
it is published in a place no hunt through a state site would look:
`health.wyo.gov`'s RHTP page carries one link, *"View Documents In Google
Drive"*, to folder `1A1fOg0WLERH2y0EJROAZhdw8TGLIrBcm`, which holds four
subfolders. Two matter.

**"Statewide Award Notice and Narratives" holds CMS's OWN Notice of Award** —
`RHTCMS332082-01-02`, action type **Revision (Budget)**, Federal Award Date
**05/14/2026**, budget period **12/29/2025 – 10/30/2026**, period of
performance to 10/30/2030, **$205,004,742.95**, matching the §7.1 anchor's
$205,004,743 to the dollar. Wyoming is the **fifth** state to publish it
(NV, CA, CT, KY, WY), and it carries California's two-dates trap at **+136
days** — the remarks say *"This Notice of Award approves the revised budget
and lifting of restriction … per your request dated 04/09/2026"*, and the
committee minutes say *"Wyoming executed its formal agreement with CMS on
May 14, 2026"*. Session 36's decision to pin the date test to the budget
period holds a fifth time. Beside it sit the revised budget and project
narratives of 2026-05-08 (four initiatives, $205,004,742: Access to
Emergency Medical Care $110,866,565 / Rural Workforce Supply $56,630,670 /
Health Technology Transformation $12,856,333 / Make Wyoming Healthy Again
$22,783,382 / admin $1,867,792).

**"RHT Advisory Committee" holds the award list.** The Rural Health
Transformation Advisory Committee — a statutory body under W.S. 35-25-703
that *"must formally approve all individual expenditures over $500,000"* and
elected to approve every award regardless — met for the first time on
**2026-08-11** and its *"Award Approvals - 8.11.26"* document is a named,
priced, scored list across six initiatives, with the minutes recording each
vote. **Its budget summary reconciles to the allotment to the dollar**:

| Initiative | Approved | Named recipients |
|---|---:|---|
| 1.1 Critical Access Hospital – Basic | **$48,200,174** | **18 hospitals** approved (15 unconditional at $36,131,489 recommended, 3 conditional on a sustainability plan, plus $6,568,685 of excess swing-bed requests); **3 denied** as late (Torrington, Washakie, Platte County — all Banner) |
| 1.2 EMS regionalization | $23,260,000 | 11 lead agencies (7 × $2,200,000; Uinta $1,960,000; Campbell County Health $1,700,000; Shoshoni $2,200,000 and Johnson County EMS $2,000,000 contingent) — several are hospitals |
| Fiscal-agent pool (EMS sustainability / labor & delivery, ~50/50) | $17,612,195 | nobody named — the unallocated remainder, swept to one or more fiscal agents |
| 2.1 / 2.3 Workforce (Wyoming Innovation Partnership, sole-source fiscal agent) | $35,424,820 + $3,193,440 | one administrator; individual and institutional grants downstream |
| 2.2 Physician GME | $17,712,410 | University of Utah $9,255,398; University of Wyoming $6,263,043.10; Cheyenne Regional Medical Center $2,193,968.90 |
| 3.1 Technology adoption challenge | $12,652,243 | 10 projects incl. Johnson County Hospital District $4,751,700, Evanston Regional $2,602,426, Powell Valley $65,000 + $687,302 |
| 3.2 / 3.3 / 3.4 statewide RFPs | $3,493,440 / $828,808 / $2,075,168 | authorised to procure; nobody named |
| 4.1 Integrated primary care | $30,465,504.74 | 8 FQHC / tribal clinics (class stated: *"FQHC or a Tribally-run 638 clinic"*) |
| 4.2 Clinically-integrated care coordination | $3,218,160 | 25 county allocations to 5 entities (incl. Sheridan Memorial Hospital, Sheridan County, $150,660) + 2 tribal sole-source |
| 4.3 Exercise & diet; policy support; admin | $4,181,087 / $819,500 / $1,867,792 | RFP / UW / WDH |
| **Total** | **$205,004,742** | |

The eighteen 1.1 rows' *"Approved funding"* column sums to **$48,200,174**,
which is the summary's own figure for 1.1 to the dollar; the eleven 1.2 rows
sum to $23,260,000 likewise; the three GME rows to $17,712,410.00. **The
eligible class of 1.1 is Critical Access Hospitals only** — Illinois's class,
not New Hampshire's — so every 1.1 dollar is a hospital dollar once the
recipient is named, and all eighteen are.

**Four things an extractor must get right, recorded now so they are not
re-derived:**

1. **It needs session 32's RUN model.** Two 1.1 rows and four 1.2 rows are
   painted with the recipient name in a separate run: the line model reads
   `83-032725126$2,500,000.00…` with no name, and the names — *"North
   Lincoln County Hospital District dba Star Valley"*, *"South Big Horn
   County Hospital District, DBA as Thre[e Rivers]"* — float, truncated, at
   the table's end. A line-model extractor publishes **16 named hospitals
   and orphans $5,156,000**, silently. Arkansas's `ar_assert_line_model_merges()`
   is the template.
2. **Every row is a committee APPROVAL, not an executed agreement.** The
   minutes give the *"Year 1 Obligation Deadline: End of October 2026
   (executed contracts/agreements)"*; three 1.1 awards and two 1.2 awards
   are *"conditional"*; all GME awards are *"contingent on CMS expense
   allowability"*. That is `NOTICE_OF_INTENT_TO_AWARD` + `amount_confirmed =
   No` (Maryland's offers, Oregon's intents), and a recipient-side
   corroboration exists only in third-party news (Sheridan Media, 2026-08-27:
   Johnson County Healthcare Center's CEO told its board it *"was awarded
   $4.7 million"*).
3. **The two state documents disagree on one figure and §8 says pin both.**
   The approvals table prints University of Utah **$9,255,398.00** and the
   three GME rows sum exactly to $17,712,410.00 on that figure; the minutes
   print **$9,225,398**. The table is arithmetically the right one; the
   minutes transpose.
4. **§0.3a will fire on 1.2.** EMS regionalization awards are led by
   hospitals (Cody Regional Health, Sheridan Memorial, Memorial Hospital of
   Converse County, Crook County Medical Services District, Star Valley
   Health, Campbell County Health) for an EMS activity — judge the recipient.

**§6.2.** The strong programme-scoped footer — *"Wyoming's Rural Health
Transformation Program is supported by … $205,004,742.95"* — sits on the
programme page, the public notice and the Submittable portal, and its figure
is the **allotment**, Tier 1 (§0.2). The date test passes with room:
applications opened **2026-07-01** (WDH release), approvals **2026-08-11**,
against a 12/29/2025 budget period start and a 05/14/2026 agreement.

**§0.1 — a defect this project had not recorded: RCJ files another STATE's
documents under Wyoming.** Five of RCJ's 29 Wyoming documents are Utah's —
*"Utah RHTP Cooperative Agreement Award: $195.7 million for Year 1"*, the
PATH 1.4 Community Care Hubs RFGA, the SPRINT Consortium application, the
Utah Semantic Data Model RFGA, the Utah stakeholder meeting — and the
$195,700,000 is Utah's allotment ($195,743,566) sitting in the record table as
an `UNASSIGNED` Wyoming row. Wrong PROGRAMME (Texas), wrong TIER (Oklahoma),
wrong ACTION (Missouri), wrong ORGANISATION grain (Michigan) — **and now wrong
STATE.** RCJ's six Wyoming *opportunities* are the initiative budgets
(1.1 $66,749,544; 1.2 $44,117,021; 2.2 $17,712,410; 3.1 $6,458,917; 4.2
$2,989,078), correctly `SOLICITATION`. RCJ holds **none** of the 2026-08-11
awards.

**Hosts.** `health.wyo.gov` and `wyomed.org` answer **200 to the project's
honest agent and 403 to a bare `Mozilla/5.0`** — session 10's medicaid.gov
answer, and the inverse of Michigan's. `wyrhtp.submittable.com` reads *"There
are presently no open calls for submissions"* — the twelve RFAs are closed.
The Drive folder is readable through `embeddedfolderview` and `uc?export=download`.

**What Wyoming is, on this pipeline's rules, before extraction: 18 named
Critical Access Hospitals / $48,200,174 in one initiative whose class is
hospitals only, plus hospital-led rows in EMS, GME, technology and care
coordination that must be typed per recipient, plus ~$59M of fiscal-agent and
RFP money that names nobody.** Nothing is summed until it is extracted.

### 3.2 HAWAII — awarded at lead-agency level; the award system is unreadable

Hawaii publishes on **four hosts**: `engage.hawaii.gov/rhtp` (the plan and
the redacted application), `health.hawaii.gov/shpda` (SHPDA leads Initiatives
1 and 6), `rhtp.hawaii.gov` (a landing page launched by the Governor's
2026-09-01 release) and the Governor's newsroom. The programme is six
initiatives, $188,892,440; every page's footer carries **$188,892,439.75**,
the allotment (§0.2).

**What has been awarded.**

- **CMS's 2026-09-01 release and the Governor's same-day release**: *"$45
  million for the University of Hawaiʻi John A. Burns School of Medicine to
  administer workforce development programs through … HOME RUN"* and *"$13
  million for the Hawaiʻi Department of Health to acquire new ambulances for
  each county and upgrade emergency communications"*. These are **lead-agency
  allocations** — a state university and the state's own health department
  as administering bodies (§6.1) — not subawards, and neither names a
  hospital. It is Virginia's $122M shape (§0.2): a tranche, announced by
  CMS, inside the allotment. Stage 00 now carries it.
- **SHPDA's own page names ONE award to a non-state entity**: under RVBI's
  *"Statewide Federally Qualified Health Center ('FQHC') Infrastructure,
  Analytics, Readiness Funding, and Transformation Support"* it prints
  **"(Notice of Award on 8/28 to Hawaii Primary Care Association)"**, and
  under the two hospital-facing items *"(RFI released on 8/19)"* and *"(RFI
  released on 8/20)"*. The recipient is the FQHC association — the eligible
  class is stated and contains no hospital, so it is Maine's UNE / Missouri's
  MEMSA coding, `NON_HOSPITAL`. **Its amount is on no readable primary
  source**: SHPDA's page links the Hawaii Awards & Notices Data System
  (HANDS) for the notice itself, and `hands.ehawaii.gov` answers **403 to
  three agents** from this environment and a JavaScript loading screen from a
  second egress — **UNREADABLE / UNKNOWN (§0.4)**, Maine's CGI Advantage a
  fifth time. A search snippet gives it as SHPDA2610, $17 million; that is
  not a source and is not asserted.
- `rhtp.hawaii.gov/funding-opportunities` routes **every non-state-entity
  opportunity to HANDS** and the HOME RUN *education award* to a JABSOM
  REDCap survey — awards to **individuals**.

**Where the hospital money will be:** RVBI's *"Statewide Hospital
Infrastructure, Analytics, Readiness Funding, and Transformation Support"*
(RFI 2026-08-19) and RHIN's $45M fund whose eligible applicants are *"rural
hospitals, independent provider practices, and FQHCs"* — hospitals AMONG
OTHERS, New Hampshire's class. Neither has awarded.

**§0.1.** RCJ's one Hawaii `/awards` record — *"Hawaii State Department of
Health, $12,000,000"*, `UNASSIGNED`, flagged — is a line from an AHEAD
document, and **17 of its 25 Hawaii documents are Med-QUEST hospital
global-budget / AHEAD material**, not RHTP at all. The aggregator has the
wrong programme for most of the state.

**Disposition:** awarded (two lead-agency allocations, one association
notice of award), **no recipient-level roster**, award channel unreadable.
Hawaii contributes 0 rows and $0 to every bucket.

### 3.3 MASSACHUSETTS — the state's whole estate is unreachable, and every route that answers is a negative

**`www.mass.gov` answers 403 to four agents** — the project's honest agent,
the RFC crawler convention, bare `Mozilla/5.0` and a full Chrome UA — with
**`robots.txt` itself 403**, a body reading *"Not allowed | Mass Gov"* and an
Akamai `x-reference-error` header. That is New Hampshire's estate-wide
shape, not Michigan's host denylist (a bare agent is refused too, so §3's
exception would not help and was not reached for). The Wayback availability
API reports a **2026-08-06 snapshot** of the RHTP page, and `web.archive.org`
still resets the TLS handshake — blocker 7 unchanged, and for the first time
it costs a state something concrete.

**What can be read says the state has awarded nothing yet.** RCJ's proxy
copies of two mass.gov pages (discovery only, §0.1; 2 API calls): the
newsletters page lists **one** newsletter (July 2026, published 2026-07-21),
and *"Rural Health Transformation in Massachusetts"* describes seven
initiatives and a Community Advisory Council with no award, no RFR and no
recipient. The state's own *"Key Dates"* page — reachable only as a search
snippet — gives *"Summer 2026: … procurements begin via COMMBUYS"* and
*"Fall 2026: all year one RHTP funds subject to procurement are contracted"*.
The Athol Daily News (2026-08-03) reports the 35-member council seated and a
member saying *"The state has not yet told council members what the next
steps will be."* **COMMBUYS**, the award channel, is a stateful application
(`publicBids.sdo` 404) — UNREADABLE. The Massachusetts Health & Hospital
Association's site is reachable and its search returns no RHTP item, so no
§7 route exists today.

**§0.1.** Seven RCJ records, zero Tier 3, no `/awards` row — correct.

**Disposition:** a negative whose state estate is **UNKNOWN**, with the
state's own timeline dating awards to **fall 2026**. Massachusetts
contributes 0 rows and $0 to every bucket.

## 4. Task 3 — the 50-state disposition

From `state_trigger_queue.csv` (allotments from the §7.1 anchor; total
$10,000,000,003, CMS's own $3 of rounding):

| Group | States | Allotment | Which |
|---|---:|---:|---|
| **EXTRACTED** | 21 | **$4,311,042,814** | AK AL AR FL GA IA IL IN KS MD ME MI MO NC NE NH NV OK OR PA SD |
| **INVESTIGATED_NO_LIST** | 8 | **$1,717,700,768** | CA CT KY LA NM NY TX WI |
| **Zero-signal, worked (sessions 39, 41), table still `NOT_EXTRACTED`** | 7 | **$1,303,162,979** | HI MA MN NJ SC TN **WY** |
| **RCJ low-candidate queue, never investigated** | 14 | **$2,668,093,442** | AZ CO DE ID MS MT ND OH RI UT VA VT WA WV — 34 candidates between them, the largest five |

**The zero-signal set is exhausted**: all twelve `trigger_source = NEITHER`
states have now been opened. Four of the sixteen states that carried no RCJ
Tier 3 candidate at the time they were opened (FL, NC, AR, and now WY) had a
published roster — a quarter of a group the discovery layers said held
nothing.

**Why the seven read `NOT_EXTRACTED` in the table and not
`INVESTIGATED_NO_LIST`, and why that was not changed here.** `R/03k`'s
definition of `INVESTIGATED_NO_LIST` is that *"each state here has a
committed evidence archive and a probe carrying a tripwire that re-opens it
the day the state publishes"*. SC, MN, TN and NJ (session 39) have neither;
HI and MA now have an evidence archive and no probe; **and WY is not a
negative at all** — it has a roster and belongs in `EXTRACTED` once
`R/03aj` exists. Coding the seven with a status their own definition
excludes would be the false claim the code exists to prevent, so the table
is unchanged and this report carries the distinction. Within the seven:

| State | Allotment | What it has published | What it needs |
|---|---:|---|---|
| **WY** | $205,004,743 | **A named, priced award list** (2026-08-11) | an extractor, run model, then a watch |
| HI | $188,892,440 | two lead-agency allocations + one association NOA, amount unreadable | a watch on SHPDA's page (the RVBI hospital RFI) |
| SC | $200,030,252 | awarded by email; no roster, no amounts, no count | a watch (session 39) |
| MN | $193,090,618 | a formula allocation, 70% to hospitals, nothing awarded | a watch (§0.3 trap) |
| TN | $206,888,882 | solicitation stage; award portal unreadable | nothing soon |
| MA | $162,005,238 | nothing; estate unreachable; awards due fall 2026 | nothing soon; re-test the estate |
| NJ | $147,250,806 | nothing | nothing soon |

**After stage 00, the survey and queue were rebuilt from `R/03k` / `R/00b`
(never hand-edited), and the CMS side of the union moved three states**:
Hawaii `NEITHER` → **`CMS_ONLY`, `QUEUED` (rank 15)**, Arkansas `NEITHER` →
`CMS_ONLY` (already `EXTRACTED`), Indiana `RCJ_ONLY` → `BOTH`, and Virginia's
`cms_source` reads `BOTH`. So the table above describes the states as they
stood when opened; on the rebuilt table `trigger_source = NEITHER` is ten
states (FL, NC, KY, NY, MA, MN, NJ, SC, TN, WY) and Hawaii now sits in the
queue on CMS's say-so — which is correct, and is why it needs the watch
described above rather than a re-investigation.

## 5. What moved in the repository

- `data/reference/rcj_state_survey.csv` and `state_trigger_queue.csv` —
  rebuilt (4 and 23 rows changed), as above.

- `data/reference/cms_state_announcements.csv` 9 → 12 states, with the
  topic index, manifest and three archived releases (stage 00, committed).
- `data/evidence/WY/` — nine files: the programme page, the public notice,
  the applications-opened release, the Submittable portal, the CMS NOA, the
  revised budget narrative, and the committee's agenda, minutes and **award
  approvals**, with a SHA-256 manifest.
- `data/evidence/HI/` — six files: the plan, SHPDA's page, both
  `rhtp.hawaii.gov` pages, the Governor's release and the steering deck.
- `tests/testthat/test_00_cms_press_monitor.R` — five pins re-based from nine
  states to twelve.
- `tests/testthat/test_03ai_ar_year1_awardees.R` — the `trigger_source =
  NEITHER` pin re-based to `CMS_ONLY`: CMS announced Arkansas on 2026-08-31,
  after session 40 extracted it on a state that neither layer had flagged.
  RCJ still holds zero candidates for it. The full suite passes with 1
  self-skip.
- **No reference CSV, no classifier, no vocabulary and no state file changed.
  No hospital dollar moved anywhere.**
