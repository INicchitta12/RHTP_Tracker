# Session 51 — a bucket must not mix tiers; two refusals settled; the rural cut; every probe run live

Run 2026-09-22. Four tasks. **No hospital dollar moved into or out of
`NAMED_HOSPITAL`** (939 rows / $787,490,159.53 / 19 states before and after).
One pool bucket shrank: `POOL_NAMED_HOSPITALS` went 2 rows / $68,156,856.12
→ 1 / $18,156,856.12.

> **A correction to carry forward.** Session 50 recorded `NAMED_HOSPITAL` as
> **$787,490,159.80**. The partition computes **$787,490,159.53**. The $0.27
> slip passed because `expect_equal`'s default tolerance is about $12 at this
> size. The pin in `test_03ap` is now exact (`tolerance = 0`).

---

## Task 1 — `IA_COE_POOL_IS_TIER_2` resolved: option (b)

**What changed.** The Centers of Excellence pool row (row 265 of
`ia_year1_awardees.csv`, $50,000,000) is gone. Iowa is back to 264 award
actions with `amount` empty on every row. Its ten Centers of Excellence award
actions stay in `NAMED_HOSPITAL` at $0, counted once.

**Why.** The $50,000,000 is the notice's own CMS footer, *"approximately
$50,000,000.00"*: the RFP's advertised pool, **Tier 2**. The bucket's other
member, Nebraska's High Value Network ($18,156,856.12), is a **Tier 3** award
off a signed notice. A bucket's figure is the sum of its rows, so the bucket
itself summed two tiers. Labelling the row did not help, because the error
was in the bucket's total, not in anyone adding buckets together. The same ten
awards were also in two buckets by row count.

**Where the figure lives now.** `ia_notice_footers.csv` already recorded it as
`SOLICITATION`. The PHTHORC26008 row's note now adds, as context, that all ten
recipients are hospitals and why the figure is in no bucket.

**Enforced where the sum happens.**
- `rhtp_hospital_dollar_partition()` refuses any **priced** row flagged
  `AMOUNT_IS_POOL_NOT_AWARD`, in every state. An unpriced one moves no dollar
  and passes. Both directions are tested.
- `ia_assert_no_amount_column_effect()` is back to "empty on every row", and
  refuses the pool row returning under either signature (the flag, or
  `POOL_NAMED_HOSPITALS`).
- `AMOUNT_IS_POOL_NOT_AWARD` stays in `vocabularies.csv`, with a note that no
  row carries it and why it was kept.

**Spec.** §0.2 gains a third worked example, *"a bucket must not mix tiers"*
(12 lines inserted, nothing deleted, §2.1).

**How it was rebuilt.** `03z --build`, then `03ap --apply` to put session 49's
overlay back. The only change to Iowa's file is the deleted row.
**`03ap --apply` also rewrote `verification_queue_2_changes.csv` from a
partial plan.** Its plan keys on classifier answers, and those no longer match
the already-verified files. That file was restored from git. **Do not commit
what `03ap --apply` writes to its own changes CSV after a single-state
rebuild.**

## Task 2 — the refused organisations: 2 settled, 2 still refused

**The task's premise needed one correction.** Session 50's four refusals were
not all South Carolina. Two are Mississippi (Delta Health Transformation
Council, $3,000,000; CAMHP Foundation, $250,000). Two are South Carolina
(Community Initiatives Inc., 2 rows / $295,000; Graceful Health Solutions,
LLC, $454,320).

**Sources, all now archived** under `data/evidence/federal_records/2026-09-22/`
with a SHA-256 manifest:
- CMS enrolment files for Mississippi and South Carolina: hospital, FQHC, RHC,
  home health, hospice, SNF.
- NPPES NPI Registry responses.
- Extracts from the IRS Exempt Organizations Business Master File. The full
  files' digests are in the manifest.

Session 50 cited its federal sources by URL and archived none of them.

| Organisation | State | Result | Record |
|---|---|---|---|
| Community Initiatives Inc. | SC | **Settled → `NONPROFIT_CBO`, MEDIUM** (2 rows, $295,000) | IRS EO BMF: EIN 31-1741660, Greenwood SC, 501(c)(3), NTEE P20 (human services), the only organisation of that name in SC. NPPES 1235502808, Greenwood, "Voluntary or Charitable". Two publishers, one city. |
| Graceful Health Solutions, LLC | SC | **Settled → `OTHER`, MEDIUM** ($454,320) | NPPES 1841015161, Spartanburg SC, taxonomy "Clinic/Center, Community Health", enumerated 2024-11-21, the only one in SC. **In no CMS enrolment file**, so it is not an enrolled FQHC or RHC. Determined form stated on the row. |
| Delta Health Transformation Council, Inc. | MS | **Still refused** ($3,000,000) | In none of the six CMS files, NPPES, or the MS BMF. The only Delta Health bodies present are **Delta Health System** (CCN 250082, the Greenville hospital) and **Delta Health Center, Inc.** (the FQHC), which is the choice a stem match would have to make. Its award says "robotic-assisted surgery … [Washington County]", which points at the hospital. That is exactly why it is not used: §0.3a judges the recipient, not the activity. |
| CAMHP Foundation | MS | **Still refused** ($250,000) | No Mississippi record anywhere. The IRS's only "Camhp Foundation" is in Ohio. |

**Hospital dollars moved: $0.** Neither settled organisation is a hospital,
and both rows were already `No`. **South Carolina now has no row left on §8's
standing fallback.** `UF_FORM_NOT_DETERMINABLE` stays OPEN, now Mississippi
only: 2 rows / $3,250,000 (was 5 rows / $3,999,320 in 2 states). One route was
not tried: the Mississippi Secretary of State's business registry, which could
at least show an incorporation date for Delta Health Transformation Council.

## Task 3 — the rural cut of `NAMED_HOSPITAL` (a report; no row re-coded)

`R/03ar_rural_cut_report.R` writes `rural_cut_rows.csv` (one row per
named-hospital row) and `rural_cut_by_state.csv`. Nothing is inferred: not from
a county, not from a pool title ("Rural Technology Grant"), not from a
description, not from general knowledge.

| Evidence class | Rows | Dollars | States | Counts as rural? |
|---|---:|---:|---|---|
| `STATE_SOURCE_RURAL`: the state's award document designates the recipient | 140 | $143,198,174.00 | GA OR WY | **Yes** |
| `FEDERAL_RECORD_CCN`: CMS enrolment by cited CCN, CAH or REH | 11 | $14,798,942.60 | MS SC | **Yes** |
| `FEDERAL_RECORD_CCN`: CMS enrolment, ordinary hospital | 41 | $52,337,017.07 | MS SC | No (not evidence of urban either) |
| `STATE_SOURCE_NOT_RURAL`: Florida's "URBAN hospital serving rural areas" | 2 | $8,048,917.20 | FL | No |
| `SITE_NOT_RECIPIENT`: Delaware's "Sussex County (rural)" is the **schools'** county | 4 | $0 | DE | No |
| `GENERAL_KNOWLEDGE_ONLY`: a verifier's "critical access hospital" | 49 | $6,367,899.53 | IA NE NV WY | No (shown, excluded) |
| `NOT_RECORDED`: the gap | **692** | **$562,739,209.13** | 18 | — |
| **Total** | **939** | **$787,490,159.53** | 19 | **151 rows / $157,997,116.60** |

**How to read it.**
- **About 20% of named-hospital dollars carry a source-backed rural
  designation. About 71% carry none either way.** The gap is 692 rows in 18 of
  19 states. Nine states contribute nothing but gap: AK, AL, AR, KS, MD, MI,
  NC, OK, PA.
- **Georgia's 87** break down as CAH 30 ($22.5M), Georgia's own "Rural" 34
  ($24.0M), "In 126 Rural/Partial Rural Counties" 5 ($3.0M), and **Rural
  Referral Center 18 ($10.5M)**. RRC is a CMS designation that urban-located
  hospitals can hold, so a stricter cut that leaves it out is **133 rows /
  $147,497,116.60**. Georgia's other 38 named-hospital rows (its signed-NOA
  hospitals) carry nothing.
- **Oregon's 35** are OHA's own words: *"The 32 rural hospitals with less than
  or equal to 50 beds … The three rural hospitals with more than 50 beds"*.
  **Wyoming's 18** are its Initiative 1.1 "Critical Access Hospital - Basic"
  table.
- **Delaware is §0.3a applied to rurality.** "Rural Sussex County" describes
  where the school-based health centres sit. Nemours is a Wilmington system,
  so the designation is not about the recipient.
- **The record, not the prose.** Session 50's basis text calls Progressive
  Health of Houston and Webster Healthcare Services "critical access hospital
  operator[s]". CMS enrols Progressive (CCN 250785) as a **Rural Emergency
  Hospital** and Webster (CCN 250020) as an ordinary hospital. Neither is a
  CAH. The `HOSPITAL_OR_SYSTEM` typing is still right, and the report reads the
  enrolment field. The basis text was left alone; four rows' wording is wrong.
- **Closing the gap** needs a CCN per row, which is blocker 5. The CMS
  **Provider of Services** file carries rural/urban status by CCN and is
  reachable from here (`data.cms.gov` dataset `8ba0f9b4-…`). Using it would be
  a new source, which this task deliberately did not use.

## Task 4 — CMS monitor and all 20 probes, run live

**CMS monitor: 21 → 23 states.**
- **NM** (2026-09-21): $74M for the six Healthy Horizons Regional Hubs.
  Already known here; per-hub amounts are still unpublished.
- **MO** (2026-09-22): "more than $45 million", including **"approximately $35
  million to support 20 rural hospital projects"** (the ToRCH Care Smart
  Growth procurement), up to $6.4M behavioral/perinatal, up to $4.2M EMS (437
  trainees). **Neither DSS nor the Governor has published the 20 names.** It
  is a count, not a list (§0.3).

**Probes.**
- **Unchanged, or content changed with every tripwire silent (12):** AK, SD,
  TX, MO (bids page changed), CT (documents page changed), NM, LA, AR, WY, MS
  (home and DOM pages changed), OH, SC.
- **The name tripwire halted eight: WI, ME, CA, KY, NY, NC, DE, ID.** Each was
  read by hand, because a halted probe stops before its later checks run.
  **Only one is a roster, New York.**
  - **WI**: three new solicitation titles on the index, two plainly not RHTP,
    plus a new $10M planning-grant opportunity. No award.
  - **ME**: new document link text. No award.
  - **CA**: site navigation changed, plus a new "CalRHT Notice of Award
    (August 28, 2026)" link, which is CMS's award to the state, not a roster.
  - **KY**: an FHKY news item and regional liaisons. No Hub Lead named.
  - **NC**: Trillium's Region 2 page lists five second-tier RFAs, "Closed -
    Under Review", with award notification **September / September-October
    2026**. The 21 new names are advisory-board members.
  - **DE**: sidebar news. No change to the award.
  - **ID**: opportunities re-labelled CLOSED. Still one awardee.

**Rosters published and not yet in this repository.** Both are archived,
unextracted, under `data/evidence/recheck/2026-09-22/`.

1. **New York: RCHI awardees list.** 56 lead-applicant rows (55 distinct
   names; Ellenville Regional Hospital appears twice) summing to
   **$76,190,022.00**, which is RCHI's allocation to the dollar. The
   Governor's release is dated **2026-09-04** and says **"90 awards to 56
   organizations"**, so the table is one row per **lead applicant**, not per
   award action (Michigan's grain lesson). By name alone the shared classifier
   types 30 rows / $44.3M as hospitals. That is a sizing, not an extraction:
   Adirondack Health and Oneida Health, for example, fall to the fallback.
   **Read §7's third eligible class before coding it.** A hospital lead is
   `DIRECT`; a non-hospital lead needs the partner hospital named in the award
   document.
2. **Kansas: Emerging Technology Award Winners.** 14 awards, **$16,006,648**
   (KDHE: "$16M … 14 eligible providers"); the PDF was created 2026-09-18. At
   least seven recipients are hospitals by name (UKHS Great Bend, Rooks County
   Health Center, Meade Hospital District, Hospital District #1 Rice County,
   NMC Health, Attica Hospital District #1, Grisell Memorial Hospital), and
   CommonSpirit Kansas is a system. **`R/utils_pdf_text.R` returns nothing for
   this file**: its producer paints text with the PDF `'` operator, which the
   reader does not implement. The figures came from reading the content
   streams directly. **Kansas has no probe**, which is why nothing flagged it.
   `ks_assert_award_index()` would refuse this fourth link on a re-fetch.

**Counts announced by CMS with no state roster found this session.**
- CT: "four rural hospital systems", $50M; DSS names none.
- RI: 14 local education agencies, $5.48M.
- VT: 3 nursing homes and 4 partners, plus $9M tuition.
- WV: two awards of about $2.4M each.
- NC: $1.25M, school-based.
- MI: $25M.
- RI, VT and WV are among the ten untouched queued states, and their own
  pages were **not** read this session. The other seven queued states (AZ CO
  MT ND UT VA WA) have no new CMS announcement.

**The process finding matters more than any single state.** New York's roster
was public from **2026-09-04**. The New York Routine fired four times after
that and its last run reads `SUCCEEDED`, yet `logs/probe_results.csv` on `main`
holds no New York line at all. **A Routine's "SUCCEEDED" means the session
ran, not that its verdict reached the repository**, so the one run that
mattered left no trace here, which is exactly what §2.2 was written to prevent.
Two things need fixing:
- Routine verdicts have to land on `main`, or somewhere a human reads.
- Seven of the eight name-tripwire halts are page furniture, and each needs
  its `known` list updated with the sentence that justifies it, not a wider
  suffix list.
