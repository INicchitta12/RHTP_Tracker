<!-- Session 98, Task 4: read-only agent findings, kept verbatim as the record behind docs/session98_checkin_ahap_nm_probe_log.md §4. Live reads are of 2026-10-12, not the logged dates. -->

# CHANGED probe lines, 2026-10-07 .. 10-12: what moved

**Read-only investigation, run 2026-10-12.** Each live page was fetched into memory with the state script's own
agent and `_get` function. It was reduced with the script's own reducer, plus a line-preserving variant of
`rhtp_watch_reduce()`, and diffed against the archived file the script names. Nothing was written under `data/`,
`logs/`, `R/` or `tests/`. No `--probe`, `--fetch`, `--build` or `--apply` was run. Nothing was committed. Scratch
copies are in `scratchpad/task4b/`: `ak_live.xlsx`, `sd_live.rds`, `de_programme_live.html` and
`ct_recovery_centers.pdf`.

**Caveat on timing.** Every diff below is **today's live page against the archive**. It is not the exact bytes
the Routine saw on the logged date. Where the two could differ, the entry says so. No later line in the log
reads UNCHANGED for any of these pages; NY and LA logged CHANGED again on 10-11 and 10-10. Except for AL, no
`docs/session9x_*.md` explains any of these lines. Session 84 §2 lists most of these keys only generically, as
"CHANGED with no recorded explanation".

## Items that change a hospital dollar figure (read these first)

| State / page | Class | Hospital effect (estimate) |
|---|---|---|
| **SD** (3 open.sd.gov searches, 10-08) | **NEW AWARD INFORMATION** | **+3 NAMED_HOSPITAL rows / +$7,789,960** (SD contracts 14 / $16,643,252 → 17 / $24,433,212) |
| **AK** (all, 10-12) | **NEW AWARD INFORMATION** | **0 new rows; +$446,104.96** on 3 existing hospital rows (AK 45 / $69,370,639 → 45 / $69,816,743.96) |

If both are extracted as estimated, NAMED_HOSPITAL moves from 1,308 / $1,213,341,798.50 to about
**1,311 / $1,221,577,863**. The state count stays at 32. The POOL buckets do not move.

---

## South Dakota: `R/03i` (open.sd.gov register), 10-08: NEW AWARD INFORMATION

The register now holds more RHT contracts than the file. The RHT number series reads **53 contracts /
$37,039,799**, against the 10-02 archive and `sd_rht_contracts.csv` at **41 / $26,836,144**. **12 contract
numbers are new, worth $10,203,655.** No existing contract was removed or re-priced.

**4 new contracts are "Implementation of a Rural Strong Grant as a part of the federal Rural Health
Transformation Program".** All begin 2026-08-01, agency 09 - HEALTH:

| Contract | Awardee (as printed, truncated at 30 chars) | Amount | CMS SD hospital enrolment (archived 09-24) |
|---|---|---:|---|
| 27RHT00048 | MONUMENT HEALTH RAPID CITY HOS | $6,361,000 | CCN 430077, "MONUMENT HEALTH RAPID CITY HOSPITAL INC" (truncation bridge) |
| 27RHT00051 | AVERA HEART HOSPITAL OF SD LLC | $1,297,500 | CCN 430095, legal "HEART HOSPITAL OF SOUTH DAKOTA LLC", DBA "AVERA HEART HOSPITAL OF SOUTH DAKOTA" (DBA bridge, LOW) |
| 27RHT00049 | RUSHMORE AMBULATORY SURGERY CE | $900,000 | not a hospital (ambulatory surgery centre) |
| 27RHT00027 | KRISTIN R TEIGEN PL, ABDN DENT | $485,550 | dental practice |

**8 new contracts carry no Rural Strong label.** Their placement is unknown, so the `SD_PLACEMENT` rule applies:
cap them at the $90M round and never add them on top of it.

| Contract | Awardee | Amount | Begin | Description |
|---|---|---:|---|---|
| 27RHT00043 | PRAIRIE LAKES HEALTH CARE SYST | $131,460 | 07-01 | chronic disease management. CMS CCN 430005A, "PRAIRIE LAKES HEALTH CARE SYSTEM INC" (hospital) |
| 27RHT00052 | SD URBAN INDIAN HEALTH | $194,685 | 07-01 | chronic disease management |
| 27RHT00053 | HIGHLAND HILLS LLC | $459,017 | 02-20 | western SD Regional Innovation Center |
| 27RHT00042 | UROLOGY SPECIALISTS | $134,442 | 02-20 | EHR, SD HIE, clinical technology |
| 27RHT00044 | LAKESIDE PAIN CENTER PROF LLC | $119,230 | 02-20 | EHR and cyber security |
| 27RHT00046 | THREE RIVERS MENTAL HEALTH & | $64,281 | 02-20 | EHR replacement |
| 27RHT00054 | CENTER FOR FAMILY MEDICINE | $37,840 | 02-20 | equipment and training |
| 27RHT00050 | NORTHERN HILLS TRAINING CENTER | $18,650 | 02-20 | equipment |

- **Provenance.** These are RHT-series numbers, and the Rural Strong rows name RHTP in their own description.
  Every begin date is after 2025-12-29, so the §6.2 date test passes.
- **Round check.** The description search finds 18 Rural Strong contracts, $25,012,010, which is still inside
  the announced $31.5M / 28 grants. Never add them on top of the round.
- **Hospital effect.** +3 rows / +$7,789,960 (Monument, Avera Heart, Prairie Lakes), if each is typed on its CMS
  enrolment. At least Avera Heart is a hand bridge (LOW). The other nine are not hospitals.
- **Proposed owner action:**
  1. Run `R/03i --fetch --force` (it writes new dated files, so older archives are kept).
  2. Run `--build` to extend `sd_rht_contracts.csv` to 53 rows.
  3. Type the 3 hospital rows on the CMS SD enrolment, with `cms_enrolment_match` set to a bridge where needed.
  4. Update CLAUDE.md Deliverable 1 and the partition block in the same commit.

## Alaska: `R/03h` (rolling award notice), 10-12: NEW AWARD INFORMATION

The live notice reads **254 rows / $248,976,547.51**, against the 09-28 archive and the reference file at
**249 / $242,620,741.15**. No App ID was withdrawn.

**+5 award actions ($4,843,430.79), all with `notification_date` 2026-10-09.** None is hospital-shaped:

| App ID | Awardee | Amount |
|---|---|---:|
| BP1-IA-030 | Alaska Municipal League | $3,151,600 |
| BP1-INT-28 | Division of Behavioral Health (DOH), a state agency | $704,880 |
| BP1-IA-246 | Orca Labs, LLC (vendor) | $658,631.50 |
| BP1-IA-354 | Yukon Koyukuk Elder Assisted Living Consortium | $318,319.30 |
| BP1-IA-148 | Girdwood Health Clinic Inc (the state ticks FQHC/clinic) | $10,000 |

**19 amounts were revised, a net change of +$1,512,375.57.** The largest:
- Dept of Education and Early Development: +$1,750,000
- YKHC BP1-IA-359 (a non-hospital row): −$584,280
- PeaceHealth Ketchikan: +$449,699.34
- Ophthalmic Associates: −$93,524

**Hospital rows: +$446,104.96, on existing rows only.**
- PeaceHealth Ketchikan BP1-IA-254: +$449,699.34
- YKHC BP1-IA-362: +$14,168.51
- Providence Health & Services–Washington BP1-IA-266: −$17,762.89

AK hospital goes from 45 / $69,370,639 to **45 / $69,816,743.96**.

**Provenance.** The source is Alaska's own RHTP Notice of Intent to Award, and every action is post-NOA. Amounts
remain `AMOUNT_PRELIMINARY`.

**Proposed owner action.** Follow the standard rolling refresh:
1. Move the current file to `AK_PRIOR_FILE`.
2. Re-date `AK_AWARDS_FILE` and run `--fetch --force`.
3. Run `--build`, then `R/03bj --apply` (the session-49 overlay is keyed by App ID since session 75).
4. Leave `AK_CMS_ANCHOR_FILE` alone.
5. Update Deliverable 1 for AK: 254 rows, $248,976,548, hospital 45 / $69,816,744.

---

## New solicitations (no hospital dollar effect)

### Delaware programme (`R/03al`), 10-12: NEW SOLICITATION

The DHSS RHTP page gained one sentence under "Telehealth and remote patient monitoring" (Year 1 Budget
$5,000,000.00):

> "Request for proposals are now available here, and submission is required by 11:59 p.m. EDT October 5. An
> information session is scheduled for September 30 at 4 p.m. EDT ... Applicants selected for second-round
> consideration will be notified on or before October 12. Potential applicants may contact
> CatalystFund@ChooseDelaware.com ..."

- This is Tier 2. The page says the funds "will be competitively awarded to vendors", so it is not hospital money.
- **Hospital effect: none.**
- **Action:**
  - Re-base `programme` with `R/03al --fetch --force` after reading.
  - Optionally note the Catalyst Fund channel (ChooseDelaware) as the place where the telehealth vendor awards will
    surface.
- `de_assert_pool_is_a_budget_not_a_round` still passed, because the log line is CHANGED, not TRIPWIRE.

---

## Noise

### Missouri bids (`R/03w`), 10-07: NOISE, but read the forward warning

What the 10-07 run saw cannot be reconstructed. `mo_assert_procurement_pending()` passed, so the ToRCH Care row
was still on the page that day.

**Today, 10-12, `IFB # DSS26015-02 ToRCH Care Smart Growth and Service Line Modifications (Horizon-2)` is GONE
from the DSS bid table.** The only new row is "Single Feasible Source for Youth Mentorship, Career Readiness, and
Academic Scholarship" (10-08, non-RHTP). The programme page is unchanged, and still reads "Aug - Sept 2026
Announce select procurement awardees".

- **The next MO firing (Wed 10-14 15:00Z) will TRIPWIRE.** `MO_OPEN_SOLICITATION` will be absent.
- Removal from an open-bids table is not an award. Whether DSS26015 was awarded is **UNKNOWN**: DSS awards post
  on MissouriBuys, which was not read here.
- **Hospital effect: none now.** If DSS26015 awards, it is up to ~$40M of hospital-facing money, at up to $5M per
  award.
- **Action:**
  - Before or at the 10-14 trip, look for the DSS26015 award (MissouriBuys, DSS news).
  - Don't loosen the assertion. Rewrite it as an award watch once the outcome is known.

### Louisiana programme and funding (`R/03ae`), 10-07 and 10-10: NOISE (LDH mega-menu)

The body region (`LA_NAME_SCOPE`) is **byte-identical** to the archive on both pages. Only the navigation menu
moved:
- **programme:** "Eastern Louisiana Mental Health System ~~(ELMS)~~ (ELMHS)"
- **funding:** OPH bureau list reshuffled. Examples: "Office of Health & Nutrition", "Beach Monitoring Program",
  "Molluscan Shellfish Program", "Office of State Health Care Facilities ... Central Louisiana State Hospital
  (Pineville)".

- **Hospital effect: none.**
- **Action:** none on evidence. Optionally, a code change could take `la_content_digest()` over the scoped body,
  so menu edits stop logging CHANGED. Re-basing alone will not stop the recurrences.

### New York press_index and scr (`R/03ag`), 10-07 and 10-11: NOISE

- **press_index.** Two new headlines, both non-RHTP:
  - "New York State Health Commissioner Receives COVID and Influenza Seasonal Immunizations ..." (10-09)
  - "Governor Hochul Declares State Disaster Emergency in Response to Ongoing Measles Outbreak" (10-05)

  The footer also changed: "Revised: September 2026" → "October 2026". The three RHTP-ish lines on the page
  ($76M RCHI release, the funding opportunity, the $48.3M Loan Repayment) are all already in the archive.
- **scr.** Only the Contract Reporter's live counters moved: 40/188/806 → 0/152/772.
- **Hospital effect: none.**
- **Action:**
  - press_index: none needed. Re-basing is optional and only quiets the line until the next release.
  - scr: will log CHANGED on every firing. Consider dropping digits from its digest, or accept the line.

### South Carolina programme (`R/03ao`), 10-08: NOISE (non-RHTP)

One word was added: an "FAQs" link (`2026-2027 FAQ Act 301 Capital Expenditure Infrastructure Grant.pdf`) under
"Act 301 Capital Expenditure Infrastructure Funding Opportunity for FY 2026 - 2027". That section was already in
the archive.
- It names a state Act and carries no RHTP or CMS language. Its provenance is unverified, but it is not an RHTP
  solicitation on its face.
- **Hospital effect: none.**
- **Action:** re-base `programme` with `--fetch --force` after reading. Optionally record Act 301 Capital as a
  state programme in `non_rhtp_state_programs.csv` if an owner confirms the funding.

### Wisconsin dhs_rhtp and dhs_solicit (`R/03y`), 10-09: NOISE

- **dhs_rhtp.** One new block: "Federal funding statement: This program is supported by CMS ... financial
  assistance award totaling $203,670,005.21 with 100 percent funded by CMS/HHS."
  - This is **Tier 1**: it collides with the §7.1 anchor of $203,670,005. It is not a pool.
  - The rest of the change is menu: "American Rescue Plan Act Funding for Wisconsin" removed, "Vital Statistics"
    added.
- **dhs_solicit.** The archive (09-01) had an empty table. Live now lists 7 RFAs. Four are not in
  `WI_NAME_FURNITURE`, and none is RHTP:

  | RFA | Funding source (from the RFA page) |
  |---|---|
  | Projects for Assistance in Transition from Homelessness (PATH) | SAMHSA PATH, $850,000 |
  | Parent Peer Professional Led Workforce Development | Community Mental Health Services Block Grant, $1,695,000 |
  | Family Centered Treatment-Recovery Implementation | Opioid Settlement Funds, $500,000 |
  | Reproductive Health and Family Planning Grants | page states no source; no RHTP mention |

- **Hospital effect: none.**
- **Action:**
  - Re-base `dhs_rhtp` and `dhs_solicit` with `R/03y --fetch --force`.
  - If the name tripwire ever reads these titles, add the four as `furniture`, each with its funding-source
    sentence above as justification. The Reproductive Health one should cite "no RHTP mention; Title X-type
    family planning", or be re-read first.

### Maine rhef, doe and programme (`R/03aa`), 10-09: NOISE

| Page | What moved |
|---|---|
| rhef | Footer link "Hospital Price Transparency (DDPC) (RPC)" added |
| doe | DOE mega-menu: "EnGINE Learning Platform", "Dirigo Schools of Distinction" and "Green Schools Program" added; "Measure What Matters" and "RREV" removed |
| programme | Advisory Committee meeting "October 7 from 12-1pm / link to be provided" → "12-12:30pm" plus a Zoom URL; the same footer link; "Maine RHTP Project Narrative" split into "Y2 Project Narrative" and "Y1 Project Narrative" (the Y2 narrative was already noted in session 94 as furniture, a plan, not an award) |

- **Hospital effect: none.**
- **Action:** re-base all three with `R/03aa --fetch --force`. The 10-07 Advisory Committee may have a new deck;
  read it if one is posted.

### Tennessee news (`R/03ay`), 10-10: NOISE (non-RHTP)

- **New headlines:**
  - "Tennessee Department of Health Announces Fall 2026 Application Cycle for Tennessee State Loan Repayment
    Program" (10-09). The release has no RHTP or CMS mention; it is TSLRP, 10-12 to 12-12.
  - "Annual Rabies Bait Drop ..." (10-06).
- **Rolled off:** the March naloxone item.
- **Hospital effect: none.**
- **Action:** none needed; optionally re-base `news`.

### New Jersey doh_news (`R/03bf`), 10-10: NOISE (non-RHTP)

- **New headlines:** "ICYMI: New Jersey Expands NJ FamilyCare-Approved Doula Trainings to 29 Programs", plus its
  Spanish twin (10-08). The release has no RHTP mention; it is NJ FamilyCare (Medicaid).
- **Hospital effect: none.**
- **Action:** none; optionally re-base.

### Connecticut dmhas_rfps (`R/03ac`), 10-12: NOISE (non-RHTP)

- **What changed:**
  - New row: "Opioid Services Unit/Community Services Division Recovery Centers" (deadline 2026-12-18). Its RFP PDF
    says it is "to be funded by the Opioid Settlement"; Funding Source: Opioid Settlement Funds; 3 awards at
    $1,247,611 each.
  - "Connecticut Homeless to Housing Services" gained "Addendum 2".
- **The REST Center row is unchanged:** the RFP plus "Addendum 1". There is no outcome link, so
  `ct_assert_rest_unawarded` holds.
- **Hospital effect: none.**
- **Action:** re-base `dmhas_rfps` with `R/03ac --fetch --force` after reading. The REST watch stays as is.

### Alabama governor (interactive, 10-08 15:17Z): EXPLAINED

`docs/session84_al_complete_probe_log_review_ms_window.md` explains this line, under "Check-in 10-08 15:15Z":
- The 10-08 14:42Z Routine TRIPWIRE was false: page chrome read as one sentence.
- `al_governor_headlines()` was fixed, and the interactive re-probe read "governor CHANGED, no trip".
- The baseline was deliberately not re-based.
- The only ARHTP headline on the index is the archived 10-01 "$55 Million" one.

**Action:** none.
