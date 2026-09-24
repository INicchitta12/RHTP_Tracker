# Session 60: the exposed set, a fresh RCJ pull, and Virginia and Washington extracted

2026-09-24. **RCJ quota: 86 calls** (September allowance 2,000 → 1,914).

## 1. MA, MN, NJ, and the states nothing is watching

### What the three states publish today

Evidence is under `data/evidence/recheck/2026-09-24/{NJ,MN,MA,CMS}/`. Each folder has a
`SOURCES.txt` with the URL, UTC time, HTTP status, agent and sha256 for every file.
Scripts were stripped from every page, and a credential grep came back clean.

| State | Verdict | What it is |
|---|---|---|
| **NJ** | **ROSTER PUBLISHED on 2026-07-31, 55 days ago** | See below. |
| **MN** | NEGATIVE | See below. |
| **MA** | UNREADABLE | See below. |

**New Jersey.**

- The roster is *"Rural Health Transformation Program Funding Allocations – July 31, 2026"*
  (`njrht_funding_allocations_2026-07-31.pdf`).
- It has 13 pages in six sections, and its columns are **Applicant Name | Award Amount |
  Activities**.
- It holds **103 rows** totalling **$83,060,837**. That total comes from our parse; the PDF
  prints no total. The parse is saved as `DERIVED_njrht_allocations_parsed_rows.csv` and is
  **not** a state file.
- Governor Sherrill's release of the same day corroborates the count and the figure: *"the
  first round of grant awards … investing $83 million … will fund 103 projects"*.
- About 37 rows (about $37.2M) name hospitals or health systems: AtlantiCare, Inspira,
  Cooper, Virtua, AHS, Hunterdon, Deborah, HMH, St. Luke's Warren, Shore, Capital Health and
  Kennedy.
- The largest single row is Center for Health Equity, $21,748,500.
- **The programme page does not link the roster, and DOH's Office of Rural Health page still
  says the state "applied for" funding.** The roster was published only through newsrooms,
  which is how Tennessee's was published too.
- CMS issued no release for it.

**Minnesota.**

- No award list has been published.
- **One part of the old note was wrong: the 94 eligible hospitals are published.** They are
  Attachment A of the Rural Hospital Notice of Grant Opportunity, which carries one uniform
  cap: *"Hospitals 94 $1,400,000"*. That is eligibility (§0.3).
- RCJ's 10 Tribal rows are a **"Estimated Maximum Award in Budget Period 1"** cap table,
  which is Tier 2.
- MDH has to get CMS's approval of its list of selected entities before it can sign any
  agreement.
- MDH's news index has no RHTP release in 2026.

**Massachusetts.**

- Every mass.gov path is still 403 on all four agents, and so is `robots.txt`.
- COMMBUYS does not recognise *26EHSKWRHTPRFQ*, and its search requires a login.
- web.archive.org still resets the connection.
- RCJ's *"Deloitte Consulting LLP at $1"* is unverified.
- This verdict is a statement about **our access**, not about Massachusetts (§0.4).

### The exposed set

`R/01b_rcj_pull_diff.R` → `rcj_pull_diff_by_state.csv`. **Watched means on a Routine.**
Delaware, Idaho, Ohio, South Dakota and Texas each have a probe that nothing schedules.

- **27 states, $5,259,267,198 of allotment, are on no Routine.** Until today the only RCJ
  read of any of them was the 08-27 pull.
- **18 of the 27 also have no CMS state release on record.** That is exactly Tennessee's
  combination: AZ, DE, FL, IA, ID, IL, MA, MD, MN, MT, NE, NH, NJ, NV, OK, OR, TX, UT.
- New Jersey was in both groups and had published its roster.

### The cheapest way to cover them (proposed, not built)

1. **Put the RCJ pull and `R/01b` diff on a Routine.**
   - A pull costs **about 86 calls**: 1 for states, 6 for awards, 37 for documents, 8 for
     opportunities and 34 for activity.
   - Weekly is about 370 calls a month (19% of quota).
   - Gate each run on `/api/stats`, which is free and needs no key. If document and funding
     counts have not moved, skip the pull.
   - This covers all 50 states in one Routine.
   - It is a **net, not a watch**. RCJ lagged New Jersey's roster by at least four weeks and,
     even now, holds only **11 of its 103 rows**.
2. **Schedule the five probes that already exist** (DE, ID, OH, SD, TX). This needs no new
   code.
3. **Add one newsroom sweep** built on `R/utils_page_watch.R`. It would read the agency
   newsroom index for the 18 no-release states and trip on a new item carrying "Rural Health
   Transformation" together with award or recipient language.
   - Tennessee and New Jersey both published only on newsrooms.
   - This is one Routine and one file.
   - It cannot help Massachusetts, whose site is unreadable.

## 2. The RCJ refresh

**Estimated before running.** `/api/stats` needs no quota and reported documents 3,608 and
funding 701. From that the estimate was 70–90 calls:

- 37 for documents
- 8 for opportunities
- 3–6 for awards
- 20–40 for activity, whose window starts in April and had filled 18 pages by August

**Actual cost.** 86 calls, all exhaustive, none capped. Committed as
`data/raw/rcj/2026-09-24/` (commit `b631cd4`).

| | 08-27 | 09-24 |
|---|---:|---:|
| awards | 1,429 | **2,534** |
| documents | 3,092 | 3,608 |
| opportunities | 631 | 701 |
| activity | 1,787 | 3,335 |

- 1,347 award ids are new and 242 are gone. The gone ids are mostly re-keyed rosters that
  are already extracted.

### What the refresh showed

All of the following are **RCJ leads, not findings (§0.1)**:

- **New Jersey**: 11 award rows. This is the lead that the state source above confirms.
- **Minnesota**: the 10 Tribal cap rows.
- **Indiana**: 186 rows at $1 each under *"Grow Rural Health: Regional Grants"*, plus two
  Governor releases: *"Gov. Braun Awards Grant … East-Central Indiana Region"* ($15.2M) and
  *"… Southeast Indiana Region"* ($13M).
  - **Indiana's $120M Regional Grants have started to award.** Indiana is `EXTRACTED` with
    no Routine and its probe does not exist.
- **Nebraska**: *"RHTP Initiative 5.3 Awards – Intent to Award"*, 12 rows, $5.46M, which is
  a fourth notice. Also *"Mary Lanning Healthcare Successful in RHTP Grant Applications"*.
- **Louisiana**: *"RHTP Updates September 2026"*, which names Ochsner Clinic Foundation
  $1.5M and four others. Louisiana's probe is scheduled and has not fired on this, so the
  document needs locating.
- **Hawaii**: Hawaii Primary Care Association **$17,000,000**. That amount previously lived
  only in HANDS, which we cannot read.
- **§0.1 mode 6, and the first time it hits Tier 3.** Four rows about **Wallowa Memorial
  Hospital**, which is in Wallowa County, **Oregon**, are filed under **New Mexico**. Session
  42's measurement found none of its ten misfiled records at Tier 3; this pull breaks that.
  The title prefix is "NM" as well, so a check on the title would not catch it.
- **Wrong programme, again**:
  - CA: Distressed Hospital Small Grant Program
  - CO: Medicaid Work Requirements APD
  - DE: downtown development districts
  - VT: GMCB FY27 hospital budgets
  - A WV news story filed under ME

### Not done, deliberately

**Stage 2 was not re-run on the new pull.** A re-run is the step with a blast radius:

- About twenty `*_rcj_candidate_disposition.csv` builders re-derive their candidate counts
  from `stage2_record_table.rds`, and they will fail **by design** when those counts move.
- The mode-6 sweep (`R/02c`) has to run first. CLAUDE.md requires that before any further
  extraction, and Wallowa shows why.

Re-normalizing is a session of its own. Until then the survey still reads the 08-27 table,
and `R/01b` is how the new pull gets read.

## 3. Virginia and Washington, extracted

### Washington: `R/03bd_wa_year1_awardees.R` → `wa_year1_awardees.csv` (8 rows)

- The source is slide 9 of HCA's 2026-09-16 deck, *"How the money flows"*, together with
  the "What we're working on" page's *"Sub-awardees:"* lists.
- **$67,020,000 is named, and none of it reaches a hospital bucket.**

| Recipient | $ | Coding |
|---|---:|---|
| Washington State Hospital Association | 42,000,000 | `NONPROFIT_CBO`, **Unclear**, in neither bucket. Queued as `WA_WSHA_FLOW`. |
| The Rural Collaborative | 5,430,000 | `IN_KIND_BENEFIT`: *"working with 30 independent rural hospitals to build capacity"* (Alaska AHHA precedent) |
| Rural Health Redesign Center | 2,140,000 | `IN_KIND_BENEFIT`, sole source |
| UW (WWAMI) / UW (ECHO) / WSU | 5,460,000 / 4,280,000 / 2,570,000 | `UNIVERSITY_OR_AHC`, `NON_HOSPITAL` |
| OSPI | 5,140,000 | `STATE_AGENCY`, `NON_HOSPITAL` |
| 29 Tribes (not named) | — ($19.41M in `round_amount`) | `TRIBAL_ORG`, `NON_HOSPITAL` |

**WSHA is the classifier trap, and the $42M is the question.**

- The name rule types WSHA as `HOSPITAL_OR_SYSTEM`/HIGH. That is overridden (Michigan's MHA
  precedent).
- The deck's only sentence about WSHA is *"is receiving applications from hospitals for
  critical technology infrastructure …"*.
  - The flow classifier reads that as `IN_KIND_BENEFIT`.
  - Hospitals applying reads more like a re-grant.
  - The source says neither.
  - The three options are priced in the queue. Option (a) would put $42M in
    `POOL_UNNAMED_HOSPITALS`, which is larger than ICAHN's pool.

**What is in `wa_year1_status.csv` instead (no amount column):**

- DOH ($31.72M) and DSHS ($14.96M), the programme's two co-administering agencies.
- HCA's five competitive pools, including **1.4, $10.71M, for "36 rural hospitals"**. HCA
  says that bid is "Completed", and no winners have been published. This is the
  hospitals-only pool to watch.

**One cross-check agrees:** the RNEP footer's *"$3,500,000 and 80 percent funded by
CMS/HHS"* matches the deck's line for DOH 5.3, $3.50M.

**The deck's subtotals do not match its own rows.** These are recorded and pinned, not
corrected:

| Subtotal | Printed | Sum of its rows | Gap |
|---|---:|---:|---:|
| Sub-recipient | $47.42M | $47.43M | −$0.01M |
| Interagency | $17.46M | $17.45M | +$0.01M |
| Competitive (slide 9) | $43.56M | $39.54M | +$4.02M |
| Competitive (slide 10) | $39.97M | $39.54M | +$0.43M |

**The deck's footer drops the word "with".** It reads *"…$181,257,515.06 to the Washington
State Health Care Authority 100 percent funded…"*, and `rhtp_footer_parse()` does not
recognise it.

- The parser was not widened, because changing a shared rule needs its own inertness run.
- Instead, the tier check runs on the page's standard footer, and the deck's figure is
  asserted literally.

### Virginia: `R/03be_va_year1_awardees.R` → `va_year1_awardees.csv` (11 rows)

- The source is the Governor's 2026-08-28 release, which lists eleven key implementation
  partners.
- **`amount` is empty on every row.** *"More than $122 million"* is a round-level lower
  bound, so it is recorded in `va_year1_status.csv` and not repeated on each row.
- **The VHHA Foundation is overridden on both counts.**
  - Its type: the classifier says `HOSPITAL_OR_SYSTEM`/HIGH, but it is an association's
    foundation.
  - Its flow: the classifier says `PASS_THROUGH_DESIGNATED`/Yes, but the RPM class is
    hospitals *among* FQHCs, RHCs, free clinics and Tribes (§0.3, New Hampshire's FHC).
- **Six partners are Unclear and five are `NON_HOSPITAL`.** Each is decided on the RFA
  Navigator's target-audience table.
- **One disagreement between the state's documents:**
  - The release names the Northern Shenandoah Valley Regional Commission for Mobile & Hybrid
    Care.
  - Ways to Apply names the "Commonwealth of VA" for it.
- The build fails if:
  - a twelfth bullet appears;
  - any per-partner figure appears (which means rewrite, not patch);
  - the VHHA Foundation's mixed-class sentence disappears.

### Survey and queue

- The split moves **32/8/4/6 → 34/8/4/4**.
- The states still `QUEUED` are **AZ, MT, RI and UT**: 11 candidates and $752,411,812 of
  allotment. Both tables were rebuilt from `R/03k`.

### What moved

**No bucket moved.**

- `NAMED_HOSPITAL` stays at **1,035 rows / $902,386,742.75**.
- It still covers **25 states**. VA and WA add rows to no bucket; `POOL_NAMED_HOSPITALS`
  (2 / $30,806,856.12) and `POOL_UNNAMED_HOSPITALS` (1 / $50,008,264) are unchanged too.
- `WA_WSHA_FLOW` is the only queue row added.
