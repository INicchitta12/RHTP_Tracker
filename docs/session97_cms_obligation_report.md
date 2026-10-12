# Session 97: CMS's RHTP Obligated Funds Report

**Date:** 2026-10-12. **Source:** CMS, "RHTP Obligated Funds Report". The data are
as of 2026-07-31 and the report is dated 2026-10-08. It is archived at
`data/raw/cms/obligations/2026-07-31/RHTP-Obligated-Funds-10082026.pdf`.

**Scripts:** `R/00c_cms_obligation_report.R` (parse) and
`R/00d_cms_obligation_analysis.R` (matching and report layers). The test file
is `tests/testthat/test_00c_cms_obligation_report.R`.

**No partition figure moved.** No award row was added and no state file was
changed. NAMED_HOSPITAL stays at 1,308 rows / $1,213,341,798.50 across 32 states.

---

## 1. Hospital effects

Nothing below is in a bucket. Every figure is a CMS-reported obligation (state
self-report as of 7/31), not a state-published award.

### (a) Single-recipient lines naming a hospital or hospital association: 32 lines, $28,230,693

These are all in NE, PA and RI. The detail is in
`data/reference/cms_obligation_hospital_decision_lists.csv`, list
`A_SINGLE_RECIPIENT`.

| State | Recipient | Lines | CMS $ | Signal | In our files? |
|---|---|---:|---:|---|---|
| RI | Hospital Association of Rhode Island (HARI) | 2 | 15,839,907.67 | association by name | **NEW**. RI has no award file |
| NE | Nebraska Hospital Association | 1 | 3,474,937.50 | association by name | **NEW** |
| PA | The Guthrie Clinic (Pulse Center Pilot) | 2 | 2,963,577.00 | name only; no PA enrolment match | **NEW** |
| PA | Corry Memorial Hospital | 1 | 1,000,000.00 | enrolment candidate (CCN 391308) | fuzzy match; **same $1,000,000** |
| PA | Chan Soon Shiong Medical Center at Windber | 1 | 985,100.00 | enrolment DBA exact (CCN 390112) | fuzzy match; **same $985,100** |
| NE | Antelope Memorial Hospital | 3 | 952,638.05 | enrolment exact (281326) | matched; ours $1,063,854.46 |
| NE | CHI Health Schuyler | 8 | 947,424.90 | enrolment DBA exact (281323) | matched; ours $711,629.63 |
| PA | WellSpan Waynesboro Hospital | 2 | 881,989.00 | enrolment DBA exact (390138) | matched; **AGREES** |
| NE | Regional West Medical Center | 1 | 254,347.00 | enrolment exact (280061) | matched; ours $830,015.14 |
| PA | St. Luke's Hospital Carbon Campus | 1 | 190,000.00 | enrolment exact (390335) | matched; ours $996,519. CMS also lists it on a 4-hospital line, see (b) |
| NE | Mayo Clinic | 1 | 120,000.00 | name only; not an NE enrolment | **NEW** |
| PA | Lehigh Valley Hospital – Pocono | 1 | 107,664.00 | enrolment exact | matched. With the (b) line below, it reconciles to the cent |
| NE | Chase County Community Hospital | 1 | 87,732.10 | enrolment exact | matched; ours $195,523.20 |
| NE | Winnebago Tribe of Nebraska | 1 | 53,615.09 | enrolment exact (280059) | fuzzy match; same amount |
| NE | CHI Health Plainview | 1 | 46,137.25 | enrolment DBA exact | matched; ours $355,311.03 |
| NE | CHI Health St Marys | 2 | 40,824.49 | enrolment DBA exact (281342) | **NEW** |
| NE | Providence Medical Center | 2 | 29,250.71 | enrolment exact | matched; ours $311,698.70 |

**What this means for the hospital total.** $5,535,898 of list (a) names
organisations already in our files: $3,497,183 matched exactly and $2,038,715 as
fuzzy candidates (the PA rows, Winnebago and the NE hospitals). The other
$22,694,795 is organisations that are new to us:

- **HARI, $15.84M.** The money is "to assess needs for a rural hospital at home
  program" and "help rural-serving hospitals adopt". As written, the
  association performs the work. That reads as `IN_KIND_BENEFIT` under §10.2's
  GHA/AHHA negatives unless RI shows funds administered to hospitals.
- **NHA, $3.47M**, "to support Critical Access Hospitals evaluating and
  transitioning to the Rural Emergency Hospital model". It is the same open
  question: services or flow-through.
- **Guthrie, $2.96M.** The Guthrie Clinic is the system parent, so it would
  need the system-parent treatment (LOW, GENERAL_KNOWLEDGE).
- **CHI Health St Marys, $40,824.**
- **Mayo Clinic, $120,000.** An out-of-state system providing a service. The
  `NAMED_HOSPITAL` test is doubtful.

**The NE amount disagreements are not errors.** CMS reports obligation by CMS
category as of 7/31. Our NE rows are Notice-of-Award totals, and each NE
hospital also appears on multi-recipient lines. The two are not comparable row
for row.

### (b) Multi-recipient lines that include a hospital: 32 lines, $58,135,729, cannot be split

These are NE (25 lines, $28.28M), PA (4) and RI (3, $18.62M). The detail is in
list `B_MULTI_RECIPIENT_UNSPLITTABLE`.

The largest lines are:
- **RI-011-55-127, $17,749,120.55**: CTC-RI, HARI, OHIC and RIHCA, "to provide
  implementation support and strategic planning for value based" payment.
- **NE-004-21-86, $9,832,975.98**: Box Butte General Hospital, Genoa Community
  Hospital "and 4 other organizations".
- **PA-005-16-28, $3,518,649**: St. Luke's Carbon, St. Luke's Monroe, Geisinger
  St. Luke's and Washington County Hospital.
- **PA-005-18-44, $2,879,750**: Robert Packer Hospital and Wyoming County
  Healthcare Center.
- **NE-004-27-119, $2,614,429.89**: Box Butte, Genoa "and 4 other organizations".
- **PA-005-16-31, $1,886,092**: Lehigh Valley Hospital Pocono and Schuylkill.
  Add the $107,664 Pocono line from (a) and the total is $1,993,756. That equals
  our two LVH rows ($996,328 + $997,428) to the cent.
- **PA-005-18-37, $2,949,686**: "across rural hospitals, including … at Bucktail
  Medical Center". The count of other hospitals is not printed
  (`n_unnamed_others = -1`).

§6.2 forbids dividing any of these lines.

### Hospital-purpose layer (leads only)

The detail is in `cms_obligation_hospital_purpose.csv`. These lines designate
hospitals but name no recipient. They are never added to any bucket (§0.3,
§0.3a).

| Designation | Lines | CMS $ |
|---|---:|---:|
| `DESIGNATES_HOSPITALS` (phrase test) | 23 | $228,227,995 |
| `DESIGNATES_HOSPITALS_BY_PROGRAMME` (IA Hometown Connections equipment/capital; WA Initiative 1 technology) | 18 | $122,230,484 |
| `MENTIONS_HOSPITALS` (weaker; shown for completeness) | 24 | $175,708,844 |

The largest leads are:
- **CA:** $35,000,000 for "Transformative Payments for Strategically Located Hospitals".
- **OK:** $33,862,084 "for building joint resiliency for rural hospitals through a
  rural-focused provider collaborative".
- **GA:** $22,000,000 + $4,000,000 for robotic surgical equipment. This **equals
  GA Phase 4 I5's $26,000,000, priced to 13 named hospitals already in
  `ga_great_health_awards.csv`**, so it is not new money.
- **CT:** $20,372,236 for rural hospital infrastructure, plus $6.1M, $4.3M and
  $5.3M for hospital transformation and TA.
- **IL:** $14,000,000 "for hospitals to provide evidence-based chronic disease
  prevention programming", plus $2.5M of hospital-transformation TA. ICAHN's
  $50.0M is a separate line in our file.
- **NH:** $14.45M (CAH strategies) and $1.89M (payment approaches).
- **WA:** $41,993,047 of Initiative 1 technology. It sits beside WSHA's $42M, which
  is Unclear (`WA_WSHA_FLOW`).
- **ND:** $4.6M + $0.6M of CAH workforce retention. This matches the
  hospital-only round recorded in `ND_HOSPITAL_ONLY_ROUNDS`.

**Iowa: the equipment categories cannot be tied to our 264 actions.**
- **What CMS reports.** Iowa reports $120,587,682 under Initiative 1 "Hometown
  Connections" Appropriate Care Availability plus Capital Expenditures. It is
  itemised by equipment type: robotic surgical systems $39.1M, MRI $24.4M +
  $5.3M, PET/CT $12.5M, CT $7.75M + $5.78M, minor renovations $10.7M, a linear
  accelerator and hyperbaric chamber $5.99M, and more.
- **What Iowa's notices give.** The equipment Notices of Intent to Award
  (PHTHORC26009, PHTHORC26011) list only organisation and county: 80 actions, 78
  of them hospitals. No equipment type and no amount is given per recipient.
- **The tie is pool-level only.** CMS's ~$120.6M against 80 named actions is an
  average of about $1.5M an action. That is a ratio, not a figure to publish.
  PHTHORC26009's own footer pool is $66,002,161.80 (Tier 2). PHTHORC26011's
  footer is the state allotment (Tier 1, `ia_notice_footers.csv`).

---

## 2. Task 1: archive and parse

**Provenance.** The owner's upload (`6294b62`) was moved with `git mv`. The public
copy is on **medicaid.gov**, not cms.gov:
- **medicaid.gov:** `…/rhtp-resources/RHTP-Obligated-Funds-10082026.pdf`, HTTP 200,
  Last-Modified 2026-10-08T20:19:39Z.
- **cms.gov:** `/files/document/rhtp-obligated-funds-10082026.pdf` returned 404.
- **SHA-256 is identical:** `abee94e7…2f15cbe`, 1,065,285 bytes.

The manifest sits beside the PDF. The 10-08 archive of the resources page
(13:25Z) predates the posting. The live page links the report as "RHTP
Obligated Funds Report".

**Parse.** The parse uses the repo's own reader (`rhtp_pdf_lines()`), keyed on x
position: headers at 210, bullets at 285 (or 306 after a bare "§"), and
continuations at 360. A human read every layout quirk, and each one is handled
explicitly and logged:
- **14 wrapped BP1 headers:** CT MA MS NC ND NH NJ NM PA RI SC SD WA WV. SD has the
  bare "$". All three are asserted.
- **MS:** a stray "$0" line after Initiative 3 (`STRAY_AMOUNT_LINE`).
- **MO:** one bullet printed with no "§" marker.
- **IA:** two items printed as one bullet, split.
- **LA, RI and VT ×2:** four bullets with no "$".
- **Header typos:** "($$2,221,629.22)", "Behavioral Health $11,800,000)",
  "Initiative1:" and "$ $721,866.58".
- **IL and OH:** bullets directly under an initiative with no CMS category. These
  are reconciled bullets→initiative, and all 12 are EXACT.

**Outputs**:
- `cms_obligations_bp1_state.csv`: 50 states. BP1 awards total $9,995,000,000.00;
  funds put to work total $4,000,699,613.09 (40.0%).
- `cms_obligations_bp1_lines.csv`: 1,403 bullets, with `description_raw` and
  `description_clean`. The ligature repair is "ff"→"W" ("staW", "EWiciency",
  "oWice"), plus ﬁ/ﬂ. It leaves real capitals alone: CHW, RDW, IOWA, PoWER.
  - `named_orgs` comes from a shape rule plus `OBL_NAME_VERDICTS`, 64
    hand-read lines that each carry a reason and never touch an amount.
  - `tier` is `SUBAWARD` where a recipient is named (348 lines) and
    `SOLICITATION` otherwise.
- `cms_obligations_bp1_headers.csv` and `cms_obligations_bp1_checks.csv`.

**Reconciliation (logged, not fixed).**

| Check | EXACT | ROUNDING (<$1) | FAIL |
|---|---:|---:|---:|
| Bullets → category | 608 | 21 | 40 |
| Bullets → initiative (no category; IL, OH) | 12 | 0 | 0 |
| Categories → initiative | 251 | 12 | 9 |
| Initiatives → state total | 41 | 4 | 5 |

The FAILs are source defects, each read against the raw text:
- **HI:** 16 categories in Initiatives 2 and 3, whose bullets repeat AZ's
  $12,660,101, $5,260,552 and $717,102, plus $22,848,000 and $18,496,000. Every
  HI bullet is `amount_usable = FALSE`, and HI's category totals stand.
- **CT Program Operations:** $13,408,358 stated against categories of $6.4M.
- **GA:** initiatives sum $851,000 short of its 100% total.
- **MT:** $11.37M short at the state level, and admin bullets of $11.9M under a
  $1.99M category.
- **MO:** $21,985,000 printed under both Fostering Collaboration and Admin.
- **ND:** Workforce and Admin amounts are swapped.
- **IA Initiative 2:** a capital category reads $54.97M against bullets of $5.47M,
  a $49.5M typo.
- **Smaller:** OR, NE, NV, NC, TN, VT, WA and WI each have one or two mismatches.
- **Cent-level:** RI has three ($1, $19.99, $221.59).
- **DE:** −$48,794.90.

---

## 3. Task 2: allotment reconciliation

`cms_obligations_bp1_allotment_reconciliation.csv` sets the BP1 award against
`cms_fy2026_allotments.csv`. The FY2026 table is not modified; `bp1_award`
lives only in the obligation tables.

- **BP1 sum:** $9,995,000,000.00. **FY2026 sum:** $10,000,000,003. **Difference:**
  −$5,000,003.00.
- **49 states** round half-up to the published allotment. Florida is one of them:
  its $209,938,194.50 → $209,938,195. R's `round()` would have sent it to the
  even dollar and shown a false $1 difference.
- **Oregon is the one real difference: BP1 $192,271,577.67 against FY2026
  $197,271,578, which is −$5,000,000.33.** Nothing in the repository explains it.
  No OR source carries either figure. The $5M accounts for the whole
  $9.995B / $10.0B gap. The rest is cents of rounding, plus the +$3 already in the
  FY2026 table.
- **Next:** read Oregon's NOA or revised budget for a $5M restriction or
  reduction. Until then, any OR share computed on $197.3M is about 2.6% too low
  on a BP1 basis.

---

## 4. Task 3: the tier rule, and the ~100% states

**The rule** (CLAUDE.md §10, standing rules). "Funds put to work" is
obligation by activity, self-reported:
- A bullet is **Tier 2**.
- A bullet that names a recipient is **Tier 3**, and it is an obligation to a
  first-tier entity, not a confirmed subaward.
- The state's BP1 award is **Tier 1**.
- None of it is summed with an award file or with any hospital bucket. None of
  it enters `STATE_FILES`.

**The six states at or near 100%.** A background agent compared CMS lines
against each state's budget documents:
- **Already archived:** IN and CT narratives, and GA's NOA revision.
- **Fetched and archived for this session**, under `data/evidence/recheck/2026-10-12/`
  with a MANIFEST: the MD 2026-04-17 webinar and the HI application.

| State | CMS put to work | Verdict | Evidence |
|---|---:|---|---|
| **HI** | $188.9M (100%) | **Full budget to intermediaries** | The application says "we anticipate that all subrecipients will be Hawai'i State agencies". The leads are SHPDA, UH JABSOM ($45M), DOH (RICA) and DHS (Respite). The only known end award is HPCA's, whose amount is only in HANDS, which returns 403 |
| **MD** | $167.2M (99.4%) | **Full budget to intermediaries** | The webinar's pillar totals match CMS. "Known Subrecipients" are state agencies plus CRISP ($10.5M). The programme page says "MDH will award a series of subawards totaling $163.7 million". Published end awards are 41 offers, $78.6M |
| **NH** | $204.0M (100%) | **Full budget to intermediaries (thin)** | Five hub contracts: FHC $66.5M (primary), CDFA (primary, "up to $40M a year"), USNH, CCSNH and CBHA (secondary sources). Every bullet is plan language. The narrative is 403 |
| **CT** | $151.8M (98.4%) | **Full budget to intermediaries** | DSS narrative: Contractual/Subrecipient is $151.5M (98.2%), held by ten sister agencies plus DSS's $85.6M. Published end awards are $49.98M |
| **GA** | $218.9M (100%) | **Partial** | The NOA revision lifts the restriction on $218.86M, with Contractual at $216.3M (98.8%). Published pools are $197.1M; 126 hospital rows total $90.3M |
| **IN** | $202.5M (97.9%) | **Partial** | GROW's $122.1M went to 186 named end recipients (unpriced). The rest sits with readiness subrecipients, vendors and the CHE GME Board |

**Advocacy caution.** In four of these six states, "100% put to work" does not
mean 100% reached providers. It means the BP1 budget is committed to state
agencies, hubs or contractors. CMS's own cover says the report "is not a full
view of state progress". Any "states have obligated $4.0B" line must carry that
caveat. Opposing stakeholders will read it the other way: as money committed
but not yet reaching hospitals.

---

## 5. Task 4: name validation

`cms_obligation_name_matches.csv` has one row per (state, organisation): 171
organisations across 13 states.

| | Count |
|---|---:|
| `MATCHED_EXACT` | 37 |
| of which the amount `AGREES` | 11 (PA ×7, NE ×3, OH Ohio University $10M) |
| of which `AMOUNT_DISAGREES` | 8 (NE hospitals and 2 PA campuses; see §1) |
| of which only on multi-recipient lines | 18 |
| `CANDIDATE_FUZZY` (never auto-resolved, §2) | 18 |
| `NEW` | 116 |

- **Where the NEW names are.** Most are in RI (22 organisations; RI has no award
  file), NE (64) and PA (12).
- **New CMS enrolment files.** The screen used CMS enrolment, and seven files were
  fetched for it: Hospital (RI, ND, WI) and FQHC (NE, PA, RI, OH). They are in
  `data/evidence/federal_records/2026-10-12/` with a MANIFEST.
- **State agencies that hold hospital enrolments are not hospital recipients.**
  Texas DSHS and HHSC match because they run the state hospitals. They, and
  universities matched only by "contains", get no hospital signal (§10.2).

---

## 6. Task 6: completed states and the roster-hunting list

**Completed states are consistent with their award dates.**
- **FL** reports $1.83M (0.9%). Its final round is dated 2026-08-11
  (`year1_completion_status.csv`).
- **AL** reports $5.41M (2.7%), all program administration. Its rounds are dated
  08-24 and 10-01.
- **AR** reports $6.16M (2.9%), all administration. Its rounds are dated 08-27
  and 09-24, are intents, and obligate by 10-30.

All three made their awards after 7/31, so near-zero is what the report should
show.

**GA reports 100% although Phase 4 ($30.3M priced, including the $26M robotics)
was announced on 08-27.** GA reported its committed budget, not executed
subawards. This is consistent with the NOA revision, and it means a GA figure
from this report is a budget figure.

**Roster-hunting list.** `cms_obligation_gap_by_state.csv` ranks states by CMS
obligated minus our published Tier 3. "Our published Tier 3" is the larger of
`sum(amount)` and the completion table's pool-inclusive figure. The gap is a
ranking device, not a finding.

| Rank | State | CMS obligated | Ours | Gap |
|---:|---|---:|---:|---:|
| 1 | CA | $219.1M | $0 | $219.1M |
| 2 | IN | $202.5M | $0.9M | $201.6M (GROW is unpriced) |
| 3 | IA | $191.8M | $0 | $191.8M (264 unpriced) |
| 4 | HI | $188.9M | $0 | $188.9M |
| 5 | NC | $167.7M | $11.3M | $156.5M |
| 6 | NH | $204.0M | $66.5M | $137.5M |
| 7 | IL | $165.2M | $50.0M | $115.2M |
| 8 | RI | $114.2M | $0 | $114.2M |
| 9 | VA | $126.6M | $14.4M | $112.2M |
| 10 | CT | $151.8M | $50.0M | $101.8M |
| 11 | MO | $106.3M | $7.2M | $99.1M |
| 12 | KY | $98.3M | $0 | $98.3M |
| 13 | MD | $167.2M | $78.6M | $88.6M |

**How to read the list.**
- **The likely-roster states.** RI (149 named lines, no award file), NC, MO and
  KY are where a roster plausibly exists.
- **Budgets held by intermediaries.** CA, HI, NH, MD and CT are largely that
  (§4), so their gap is mostly not unpublished awards.
- **States below zero.** NY and WV (CMS $0), and VT, SC, CO, WY, FL, AL, AR and AK,
  report less obligation than we have published. That is because they awarded
  after 7/31, or their awards are intents.

---

## 7. Task 7: refresh watch

The report is public, and its page is the medicaid.gov resources page that
`R/00_cms_press_monitor.R` already archives. On every PRODUCTION `--run`, the
monitor now logs a second row, `page = obligation_report`:
- It reads `CHANGED` when the page links a report file other than
  `RHTP-Obligated-Funds-10082026.pdf`.
- From **2026-12-07** it carries the note "No refreshed obligation report yet".

CMS says it will refresh "following the submission of the November 30, 2026
Quarterly Report" and then quarterly. A new report is archived by hand under
`data/raw/cms/obligations/<as-of>/` and parsed with R/00c. The monitor never
writes it. The CMS Routine runs from `main`, so the watch is live only once this
branch merges.

---

## 8. Open questions for the owner

1. **List (a) and list (b), §1.** HARI ($15.84M) and NHA ($3.47M) need a §10.2
   flow call: association-administered or in-kind. Should CHI Health St Marys
   ($40,824), Guthrie ($2.96M, system parent) and Mayo Clinic ($120k) enter any
   file? Nothing was added.
2. **Oregon's −$5,000,000.33 BP1 difference.** Read its NOA or revised budget.
3. **Rhode Island.** RI has 149 named CMS lines and no award file. Does it publish
   a roster (EOHHS)? It is rank 8, and its named recipients include HARI and BIHS.
4. **The "funds put to work" caveat** for any external use (§4).
