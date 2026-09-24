# Session 59 — Tennessee extracted, Washington's footer parsed, five states on Routines, Nuvita re-typed

2026-09-23. Zero RCJ quota.

## 1. Tennessee — 53 named HART awards, no amounts, two hospital rows

**Source.** TDH's 2026-09-03 release, *"Tennessee Department of Health Announces 1st
Recipients of Rural Health Transformation Program Grants"*, and the workbook it links,
`2026-RHTP-HART-Grant-Awards-FINAL.xlsx` (sheet "Sept. 2, 2026"). Both were archived by
session 55 under `data/evidence/recheck/2026-09-23/TN/`.

- **53 recipients in 44 counties.** Each row has a recipient, its counties and a project
  name. **No row has an amount.** This is the same shape as Nevada and Iowa.
- **§6.2 checks pass.**
  - The release ties the awards to RHTP: *"initial recipients of funding through the Rural
    Health Transformation Program"*.
  - The award date (2026-09-03) is after the Notice of Award (2025-12-29).
  - The release's CMS footer prints $206,888,882.11, which is Tennessee's **allotment**
    (Tier 1). The footer is declared `STATE_ALLOTMENT` and passes the tier check.
- **This is a partial year.** TDH calls these the *"initial"* recipients, all under one
  priority (HART). `year1_completion_status.csv` records Tennessee as `PARTIAL`.

### Coding the recipient, not the state's label (§0.3a)

TDH describes the 53 recipients as *"County and municipal governments … 58 percent (31)
… community-based nonprofit organizations … the remaining 42 percent (22)"*. Both
hospitals fall inside those labels, so coding the labels would give Tennessee no hospital
row. A test demonstrates this.

| Recipient | TDH's label | Code | Evidence |
|---|---|---|---|
| **Macon Hospital, Inc** | one of the 31 governments | `HOSPITAL_OR_SYSTEM`, `DIRECT`, `LOW` | CMS Hospital Enrollment lists MACON COUNTY GENERAL HOSPITAL INC, dba MACON COMMUNITY HOSPITAL, in Lafayette (Macon County), CCN **441305**, a critical access hospital. It is the only hospital enrolled in Macon County. The state's name for it does not match CMS's, so the link is a **hand-read bridge** and is rated LOW. |
| **Cookeville Regional Medical Center Foundation** | one of the 22 nonprofits | `HOSPITAL_OR_SYSTEM`, `DIRECT`, `LOW` | §10.2's hospital-foundation row. The foundation carries the full name of its parent hospital: COOKEVILLE REGIONAL MEDICAL CENTER, CCN **440059**. The parent link is a reading, so it is rated LOW. West Virginia's Cabell Huntington Foundation was coded the same way. |

- **The HART projects are community wellness infrastructure** (for example, *"Macon Healthy
  Living and Child Development Project"* and *"Community Wellness Loop"*). That is the
  activity. §0.3a judges the recipient, and both recipients are hospitals.
- **Why Macon must be one of TDH's 31 governments.** The other 30 governments are 15
  cities, 4 towns, 5 county governments or mayors, 4 school systems, 1 library and 1
  economic development agency. Macon Hospital is the only name left, which fits a county
  general hospital.
- **The other 51 rows are typed from TDH's own split.** This file's typing reproduces
  31/22 exactly, and a test fails if it stops doing so.
- **The shared classifier misses 10 of the governments.** It returns
  `NONPROFIT_CBO`/LOW for 3 of the 4 school systems (it gets "Board of Education"), all 4
  "Town of" names, a library, a county mayor and an economic development agency. Its answer is kept in `recipient_type_source`. The classifier was **not**
  widened, because a change to a shared rule needs its own byte-identical rebuild of every
  state.
- **The Free Medical Clinic of Oak Ridge** is in neither CMS's FQHC file nor its RHC file.
  It is coded as one of TDH's nonprofits.

### Effect on the totals

| Bucket | Before | After |
|---|---|---|
| `NAMED_HOSPITAL` | 1,033 rows / $902,386,742.75 / 24 states | **1,035 rows / $902,386,742.75 / 25 states** |

- Tennessee adds rows, not dollars.
- The rural cut counts Macon as rural because CMS enrols it as a CAH. That rests on the bridge.

### A §0.1 trap on the same website: RAMP

TDH's **Rural Healthcare Access Modernization Program** looks like RHTP money and is not:

- It is linked from the RHTP page and run by the same State Office of Rural Health.
- It is *"funded through TennCare Shared Savings"*: $104.4M the General Assembly approved
  in the FY27 budget *"to complement"* RHTP. That is **state money**.
- Goal 1 is $100M of rural capital projects, which is likely to go to hospitals.
- Goal 2 is *"RHTP Competitive Grant Extension"*.

So RAMP's awards will carry RHTP's name while being paid from state money. RAMP is recorded
in `tn_year1_status.csv` as the negative control. The probe raises a tripwire if the RAMP
page stops saying *"funded through TennCare Shared Savings"*.

### How Tennessee escaped both discovery layers

1. **RCJ could not have had the roster.** The only national pull is 2026-08-27, seven days
   before TDH published. RCJ held 82 Tennessee records and zero at Tier 3.
   - 8 records concern HART: 4 `SOLICITATION`, 4 `UNASSIGNED`. One of these is RFA
     #34320-18526, filed under *"TN - 2024 - …"*. That year prefix is aggregator metadata,
     not a date (§2).
   - This is a gap in pull cadence (no pull since 08-27), not an RCJ defect.
2. **CMS never published a Tennessee release.** The committed newsroom topic index runs to
   2026-09-22 and has no Tennessee item. CMS put out state releases for 23 states, and
   Tennessee is not one of them.
   - The TDH release quotes Dr. Oz (*"These first grant awards…"*), but that quote appears
     only on TDH's own page.
   - Stage 00 reads CMS, so it had nothing to read.
3. **Our own status code meant nobody was watching.** Tennessee had been
   `INVESTIGATED_NO_PROBE` since session 43. That code's own note warns that *"the finding
   goes stale by construction"*, and it did, for 20 days.
4. **A programme-page probe would not have caught it either.** On 2026-09-23 the RHTP page
   at `tn.gov/health/rural` still links only the 2026-05-15 opportunity release. The
   workbook is reachable **only from the newsroom item**.
   - Session 39 recorded the Caspio partner portal as Tennessee's award channel. That
     portal is unreadable to us.
   - The roster was actually published on the TDH newsroom, the channel session 39 had used
     as its positive control.
   - Session 55 found the roster through a web search it was running for other states
     (RI/UT).
   - The new probe watches the newsroom for that reason.

**What this shows:** a state that gets no CMS release, has nothing new in RCJ since the last
pull, and has no probe is visible to nothing in this repository. Three states still have that
combination: MA, MN and NJ. (Hawaii is also `INVESTIGATED_NO_PROBE`, but CMS did publish a
release for it on 2026-09-01.)

### Files

- `R/03ay_tn_year1_awardees.R` (`--fetch`, `--validate`, `--build`, `--probe`, `--report`)
- `tn_year1_awardees.csv` (53 rows)
- `tn_year1_status.csv` (4 rows)
- `tn_rcj_candidate_disposition.csv`
- CMS enrolment slices for Tennessee: `federal_records/2026-09-23/cms_{hosp,fqhc,rhc}_enrollments_TN.json`
- Probe baselines: `data/evidence/TN/`. Scripts were stripped before writing, because
  tn.gov pages embed a Coveo search `accessToken`.

**The session-55 recheck copy of the release still contains that Coveo token**, which is
anonymous and expiring. It was left in place so the manifest's digest still closes; the
owner decides whether to scrub it.

**Disposition.** Tennessee moves `INVESTIGATED_NO_PROBE` → `EXTRACTED`. It is the second
state to leave that bucket because the state itself published (South Carolina was the
first).

## 2. Washington's footer parser

`rhtp_footer_parse()` returned zero rows on HCA's RNEP disclaimer:

> *"…through a subaward as part of a financial assistance award **of $181,257,515.06** to
> the Washington State Health Care Authority **with $3,500,000 and 80 percent funded by
> CMS/HHS and $914,538 and 20 percent funded by other source(s)**."*

**Why it failed.** The footer says "of", not "totaling", and puts the dollar figure before
the percentage. Every earlier pattern expected the reverse.

**The new `SUBAWARD_OF` form:**

- The sentence carries three figures at three tiers:
  - `headline_amount` = the award to the state ($181,257,515.06, Tier 1). This is also
    `tier_amount`.
  - `subaward_cms_amount` = the subaward's federal share ($3,500,000, Tier 3), with
    `subaward_cms_pct` = 80.
  - `subaward_nonfederal_amount` = the subaward's match ($914,538).
- The percentages describe the **subaward**, not the headline, so `cms_pct` and
  `cms_amount` are left NA. Putting them there would break Mississippi's identity
  (headline − CMS share = match) in a way that would look like a publisher error.
- The subaward's total is **not** computed. $4,414,538 is a number nobody printed (§0.4).

**New columns on every row:** `form` (`TOTALING` / `SUBAWARD_OF`) and `subaward`. Wisconsin's
DWD and DPI pages now read `subaward = TRUE` on their existing `TOTALING` footers.

**Inertness check.**

- Old and new parsers were run over every committed HTML, TXT and JSON file containing
  "funded by" (133 files).
- All **224** existing footer rows are identical.
- Exactly **one** new row appears, Washington's.
- The Washington probe requires both of its footers to parse and to tier-check as the
  allotment.

## 3. Five Routines

| State | Routine | Cron (UTC) | Runner | Why this cadence |
|---|---|---|---|---|
| CO | `trig_01P9oihsxYj8Ksv5hSmKy6a4` | Mon/Thu 09:10 | `session_01KbB6uHdvUYpSK7CJLWXagJ` | HCPF: award announcements *"by the end of September 2026"* |
| VA | `trig_01QU6u3VFCJY1xWCrjmFeLcp` | Tue/Fri 10:20 | `session_01PpttA6mXz6hjiDrGHFRae6` | VHCF Notice of Awards by 9/30 and 10/14; VHHA Foundation by 10/30 |
| ND | `trig_01DUE8JsjXhHGDndT2N26Phf` | Wed 09:20 | `session_012ZNdeAk4RSvJkZBSk7rnRN` | no published date |
| WA | `trig_01XkZWESmQbqfq58cKuQ84i9` | Thu 10:10 | `session_01D79su1xyoLgUT5Uvpf6A6G` | no published date for any of the ~$58.1M |
| TN | `trig_01Ad384uvudquMnQXVHokXTX` | Sat 09:30 | `session_01KW4ksJMDj846hb5Py2uFyY` | "initial" recipients; no next-tranche date |

**How each Routine is set up.** Each is bound to its own runner session: repository source,
`outcome_branch = main`, `claude-sonnet-5`. This copies West Virginia's setup and prompt,
including the push guard. Every prompt **gates on its probe being on `main`**, so a firing
before the merge writes nothing.

**Merge before the first firings.** CO and WA first fire 2026-09-24 at 09:10 and 10:10 UTC.
If this branch has not merged by then, the coverage check will correctly name those firings
as unlogged. `logging_since` is 2026-09-23T19:45:14Z. All five were run once interactively
and logged UNCHANGED.

**`R/utils_page_watch.R` is new and shared.** It does the fetch, reduce and digest steps, and
never writes anything. The four new state files keep only their pages and their own
tripwires:

- **CO:** the dated sentence must stay; any new award sentence fires, but HCPF's existing
  *"has awarded a contract to the Colorado Rural Health Center"* does not; any
  RHTP item on the Governor's press index fires.
- **ND:** fires when a second opportunity heading changes to "– Awarded". Fewer than 20
  headings means our reader broke, not that ND withdrew anything.
- **VA:** both administrators' award-date sentences must stay; new award language fires.
- **WA:** both footers must parse; the bids page fires on "apparent successful bidder" or on
  new RHT or rural-health lines.

Every page that has a baseline of 3 or more names is also name-diffed (§2.3). A message
that quotes a programme called "Connecting Care" has the word broken, so the log records a
**tripwire**, not an access error.

**Virginia's RHT site sends an incomplete certificate chain.** It serves its leaf
certificate without the DigiCert intermediate. The intermediate was fetched from the
certificate's own AIA URL, checked against DigiCert Global Root G2, and committed at
`config/certs/` with a README. It is added to the normal CA bundle. Certificate
verification is never turned off.

**Survey dispositions.**

- **CO and ND** move to `INVESTIGATED_NO_LIST`. Both are now archived, worked and probed.
- **VA and WA stay `QUEUED`.** Each has unextracted first-tier work:
  - Virginia: 11 named partners with no per-partner amounts.
  - Washington: priced first-tier subrecipients.
- **Final split: `EXTRACTED` 32 · `INVESTIGATED_NO_LIST` 8 → 10 · `INVESTIGATED_NO_PROBE` 4
  · `QUEUED` 6** (AZ, MT, RI, UT, VA, WA).

## 4. Nuvita Health: `VENDOR_OR_CONTRACTOR` → `OTHER`

- Changed on the owner's instruction, following session 49's rule: a company that
  **receives a grant** does not supply the state.
- `verified_basis` now states the determined form, as `OTHER` requires.
- `R/03ax --apply` rewrote rows 9, 18 and 33; `fl_ceiling_resolution.csv` was rebuilt.
- `distributed_to_hospital` stays `No`, so **no figure moves**.
- Rebuild order is unchanged: `R/03e --ingest`, then the 03ap overlay, then
  `R/03ax --apply`.
