# Session 10 — the Georgia roster, the live trigger list, and §8 settled

**Date:** 2026-08-28 · **RCJ quota spent:** 0 · **Network calls:** 2
(`greathealth.georgia.gov`, `www.medicaid.gov`)

Three tasks, all of which had been blocked on an egress allowlist entry or on an
open decision. All three are closed.

---

## 1. Georgia's 87 AHEAD hospitals are named

`greathealth.georgia.gov` was allowlisted. The roster both DCH award
announcements link to is archived at

    data/evidence/GA/2026-08-28_value_based_care_hospital_list.html
    data/evidence/GA/ga_value_based_care_hospital_list.manifest.txt

`rhtp_ga_ahead_roster()` parses the 87 names out of the committed archive —
parsed, never transcribed, the same posture as the §7.1 CMS allotment table —
and `ga_expand_ahead_cohorts()` replaces each aggregate cohort row with one row
per named hospital, inheriting the cohort's coding.

Georgia goes from **54 award actions to 139**. Every one of the 87 is
`recipient_confirmed = Yes`. **The reconciliation is untouched:** $197,148,327
awarded, 9.92% residual, because the expansion changes no initiative pool.

### The page says "Completed Applications", and is still an award source

Read alone, `Hospitals With Completed Applications` is an eligibility list, and
§0.3 would forbid coding it `Yes`. It is not read alone:

> **Phase 3 (2026-07-23):** "Eighty rural hospitals have completed the
> application to participate in the AHEAD model and **have been awarded
> $750,000** to support pre-implementation activities. **The list of 80 awarded
> hospitals is available here.**"

> **Phase 4 (2026-08-27):** "These awards follow the 80 rural hospital awards
> announced in Phase 3 and **complete the planned group of 87 hospitals**
> identified in Year 1. The full list of hospitals is available here."

Both "here" links resolve to this exact url. The award action, the count and the
per-hospital figure come from the announcements; the page supplies only the
names. **Neither document supports the coding on its own, and every hospital row
cites both.**

Independent closure: the table parses to exactly 87, which is the group DCH says
it completed.

### Which 80 carry the $750,000 is an inference, and is flagged

DCH states the figure for the Phase 3 eighty and **never restates it in Phase
4**. The roster does not label phases. The split is derived from list order:

| Rows | Order | Phase | Amount |
|---|---|---|---|
| 1–80 | exact alphabetical | 3 | $750,000, `amount_confirmed = Yes` |
| 81–87 | appended, out of order | 4 | none, `PHASE_ATTRIBUTION_INFERRED` |

That is the shape a page updated in place takes when 7 names are added to an
80-name list. The parser **derives** the break and **refuses if the leading
alphabetical run is not exactly 80**, so a re-sorted page fails loudly instead of
attributing $750,000 to a hospital DCH never named a figure for.

`archive.org` is not allowlisted, so the July snapshot — which would settle the
split as fact rather than inference — could not be retrieved.

**What does not depend on the inference:** that all 87 are awarded hospitals.

### $65.25M was the wrong number, and $60,000,000 is the right one

The pre-session figure assumed 87 × $750,000. DCH states $750,000 for **eighty**
hospitals. The confirmed, named, hospital-directed Georgia figure is

    80 × $750,000 = $60,000,000

which closes on the stated Initiative 1 pool **to the dollar**. The other seven
hospitals are awarded and named; their per-hospital amount is simply not
published, and §6.2 forbids dividing the pool to invent it.

### Designations

The page states CAH and RRC are CMS designations. "Rural" (34) and "In 126
Rural/Partial Rural Counties" (5) are Georgia's own classifications, so
`rural_designation` takes `CAH` (30) / `RRC` (18) / `NONE` (39) and the state's
raw language is kept in `rural_designation_raw` (§8: never discard it).

---

## 2. Stage 00 has run against the live CMS page

**Eight states have announced: AK, AL, GA, ND, OH, PA, SD, WV.**

| State | Date | Headline figure |
|---|---|---:|
| PA | 2026-08-19 | $35,000,000 |
| SD | 2026-08-19 | $90,000,000 |
| ND | 2026-08-20 | *(no figure stated)* |
| WV | 2026-08-20 | $4,200,000 |
| AL | 2026-08-24 | $144,000,000 |
| AK | 2026-08-25 | $160,000,000 |
| OH | 2026-08-26 | $3,150,000 |
| GA | 2026-08-27 | $93,300,000 |

These are **discovery** values (§0.1) and the column is never summed (§0.2) — the
page mixes Tier 1 allotments with Tier 3 subaward announcements.

### The user agent, and why honesty is the fix

Akamai fronts `medicaid.gov` and returns **403 to any user agent carrying no
contact URL** — including to a spoofed browser UA, which is also refused. The
`+url` form is the well-behaved-crawler convention and is what gets through:

    AHA-RHTP-Tracker/0.1 (+https://www.aha.org; contact: AHA Data and Policy; R httr2)

Verified against `medicaid.gov` and `cms.gov`.

### The blind spot the fixtures could not have caught

The live page **is** a table, but its header row is marked up with `<td>`, not
`<th>`. `html_table()` therefore named the columns `X1..X5`, every synonym lookup
missed, the table scored 0, and the parser fell through to the link-list shape.

**That fallback did not fail. It succeeded with less:**

| | LINK_LIST (before) | TABLE (after) |
|---|---|---|
| states | regex on the headline | the page's own State column |
| dates | **none at all** | the page's own Date column |
| amount | mined from the headline | mined from the headline |
| national rows | dropped by luck | excluded deliberately |

Every refusal in that parser guards against parsing the **wrong** thing. This was
the other kind: parsing the right thing less well, and saying nothing.
`cms_press_promote_header()` promotes such a row, and **only when doing so
resolves strictly more columns**, so it can never make a working parse worse.

### The national rows

Reaching the table shape surfaced two rows the link-list shape had been dropping
by accident: CMS lists its own national announcements — the $50bn programme
launch and the all-50-states award — in the same table with `State = "All"`.
Those are Tier 1 (§0.2) and this is the *state* trigger list, so they are now
excluded deliberately with the count reported. A genuinely unmappable state still
stops the parse.

### One unarranged closure

CMS announces **$93.3M for Georgia on 2026-08-27**. DCH's own Phase 4
announcement the same day totals **$93,330,827**. Two publishers, one figure. It
remains a discovery source either way — the corroboration is a check, not a
source.

The Routine (`trig_01EozMStALcrUp75s32qFnJ3`, Mondays and Thursdays 13:00 UTC)
now points at `main` rather than the merged Session 9 branch.

---

## 3. The §8 `recipient_type` question is settled

Florida and Georgia had two answers to one question: **what does
`recipient_type` hold when the recipient is NAMED but its organisational form is
not determinable from the source?**

| | Florida | Georgia |
|---|---|---|
| `recipient_type` | `UNCLASSIFIED` (not a §8 value) | `NONPROFIT_CBO` |
| confidence | — | `LOW` |
| flag | — | `RECIPIENT_TYPE_INFERRED` |

**Georgia's convention is adopted.** Florida's five rows — three Nuvita Health,
Empowerq Health Care, North Florida Rural Health Corp — are back-fitted.

The placeholder is not a finding. Nobody downstream may read `NONPROFIT_CBO` on a
flagged row as "this recipient is a nonprofit"; the flag is what carries that.

### `PHYSICIAN_PRACTICE` was a different question

Florida's eight `PHYSICIAN_PRACTICE` rows are **not** undetermined — a pediatrics
group, a fetal medicine practice and a primary care clinic are all determinable,
and none of the other twelve §8 values is true of one:

- `NONPROFIT_CBO` asserts a form the source contradicts (these are ordinarily
  for-profit) and destroys the practice/hospital distinction Stage 5 needs.
- `VENDOR_OR_CONTRACTOR` makes a provider receiving a grant look like a supplier
  to the state.

So `PHYSICIAN_PRACTICE` was **added to §8 deliberately**. All eight are already
`distributed_to_hospital = No`, so no total moves. This is the one §2 "do not
invent codes mid-session" exception, taken as an explicit decision.

### Florida is ingested

`R/03e_fl_year1_awardees.R` reads the owner's workbook, applies the back-fit
**and nothing else**, and writes `data/reference/fl_year1_awardees.csv` as the
source of record; the workbook at the repo root is a render of it, as with 03c.

- The owner's original upload is preserved at
  `data/raw/owner_uploads/FL_year1_awardees_original.xlsx` with a SHA-256
  manifest. It is the ingest source and cannot be regenerated — re-ingesting the
  rendered copy would fold a render back on itself.
- `recipient_type_source` carries the owner's value on **every** row, so the
  back-fit is auditable and reversible.
- `determination_confidence` is set on the five judged rows only. Florida's
  workbook has no confidence column, and inventing 76 would be this pipeline
  asserting what the owner never did.
- Escaped awardee names (`Quintero &amp; Kontopoulos`) are unescaped — a
  transcription fix, not a re-coding.

### The two states union

    220 rows (FL 81 + GA 139), zero recipient_type values outside §8

| `recipient_type` | FL | GA |
|---|---:|---:|
| `HOSPITAL_OR_SYSTEM` | 15 | 106 |
| `UNIVERSITY_OR_AHC` | 19 | 7 |
| `FQHC_OR_RHC` | 18 | 0 |
| `NONPROFIT_CBO` | 14 | 4 |
| `PHYSICIAN_PRACTICE` | 8 | 0 |
| `VENDOR_OR_CONTRACTOR` | 5 | 3 |
| `STATE_AGENCY` | 0 | 11 |
| `NOT_YET_NAMED` | 0 | 4 |
| `LOCAL_GOVT_OR_PUBLIC_HEALTH` | 2 | 0 |
| `EMS_OR_PSAP` | 0 | 2 |
| `AHEC` | 0 | 1 |
| `HOSPITAL_AFFILIATED_ENTITY` | 0 | 1 |

That union is asserted from both sides, so neither state can drift out of the
schema without a test failing.

---

## Tests

**728 assertions — 727 passing, 1 self-skipping** (was 627).

The skip is the stage 00 first-run branch, which no longer applies now that
`cms_state_announcements.csv` exists; the test skips itself with that reason.

| File | Assertions |
|---|---:|
| `test_00_cms_press_monitor.R` | 70 |
| `test_01_retrieve_rcj.R` | 44 |
| `test_02_normalize.R` | 276 |
| `test_03_state_registry.R` | 70 |
| `test_03b_budget_narratives.R` | 90 |
| `test_03c_cms_abstracts.R` | 40 |
| `test_03d_ga_great_health.R` | 99 |
| `test_03e_fl_year1_awardees.R` | 39 |

---

## What this leaves open

1. **The §7.3 registry is still the hard gate** (§13.12) and Stage 4 still waits
   on it.
2. **48 state health-department hosts** are still blocked; §7A.2 needs fifty.
   Oklahoma next. `web.archive.org` is worth adding too — it would have settled
   Georgia's 80/7 split as fact.
3. **The AHA Annual Survey / CMS Provider of Services extracts** are now the next
   binding constraint for Stage 5, not a distant one: Georgia's 87 named
   hospitals carry addresses and CMS designations and are ready to match, but
   `determination_confidence` cannot reach `HIGH` without a CCN match.
4. **`DE Verify.xlsx` is still unread by any stage** — the §9.11 premise-test
   evidence, still carrying the pre-§0.3a coding.
5. **`qa_assertions.R`** is still unbuilt and is now the only stage with no file.
