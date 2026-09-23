# Session 54 — Routine cutover; Vermont, Connecticut, West Virginia and Missouri extracted; Louisiana's probe scoped

2026-09-23. Zero RCJ quota.

## 0. The Routine cutover

- Sixteen **v2** Routines now fire into sessions that can push to `main`. New York
  (`trig_01S6HM3Uv5u7WNP1sYgeCvPy`) and South Carolina (`trig_017j3hddVSkzAAKn8esPawmR`) were
  test-fired at 14:07Z and 14:09Z, and both lines are on `main`.
- `config/routines.csv` now registers the v2 trigger ids. `logging_since` is
  `2026-09-23T14:18:00Z`, just after the last v2 Routine was created at 14:17:33Z.
  `probe_coverage.R --check` passes: 0 due firings, all logged.
  - **Before this change the committed suite was already red.** The registry named the old ids, and
    WY's 2026-09-22 21:10Z firing had left no line.
- **Missouri (15:00Z) and California (17:00Z) are the first scheduled v2 firings.** Their results,
  and the deletion of the 16 old Routines, are in §6. The CMS trigger-list Routine
  (`trig_01EozMStALcrUp75s32qFnJ3`) is **not one of the 16**. It was never re-bound and is left
  running.

## 1. Vermont — 111 executed agreements; 27 named-hospital rows, $22,641,819.43

- **The source.** AHS's *RHT Year 1 Awards and Contracts — Updated as of September 18, 2026* has
  112 rows that sum to the table's own printed total, **$87,175,011.33**, to the cent.
- **Executed agreements.** The page calls them *executed agreements*, so every row is
  `NOTICE_OF_AWARD` + `amount_confirmed = Yes`.
- **A partial list.** The page says it is *"a partial and ongoing list"*, so the figure is a floor.
  `R/03at --probe` watches it.
- **Owner decisions:**
  - **Mary Hitchcock Memorial Hospital** (Lebanon NH, CCN 300003) counts as a Vermont hospital row.
    It has 3 rows, $8,820,815.60, each with `facility_state = NH`.
  - **The GMCB inter-agency MOU** ($2,635,000) is out of the award file and recorded in
    `vt_year1_status.csv`. The 111 award rows plus the MOU equal the printed total.
- **Typing used CMS enrolment files, not names.** Hospital, FQHC, SNF and HHA files are archived
  under `data/evidence/federal_records/2026-09-23/`. They caught two traps that general knowledge
  and the name rule would have walked into:
  - **"1248 Hospital Drive Opco LLC" is a nursing home.** CMS enrols it as an SNF, CCN 475019B. §8's
    name rule reads "Hospital" in the street name and returns `HOSPITAL_OR_SYSTEM` at HIGH. That is
    **3 rows, $2,081,510**, kept out of the hospital total.
  - **"Gifford Health Care" is the FQHC** (CCN 471852), **not Gifford Medical Center** (the
    hospital, CCN 471301). That is $510,763.57, kept out.
- **The 27 hospital rows, $22,641,819.43:**

  | Group | Dollars |
  |---|---:|
  | In-state hospitals on a federal record (includes Brattleboro Retreat, a psychiatric hospital, $228,550.93) | $11,346,319.01 |
  | Mary Hitchcock (NH) | $8,820,815.60 |
  | UVM Health Network, two spellings, general knowledge at `LOW` | $2,474,684.82 |

  UVM Health Network is the parent system of UVM Medical Center and CVMC, and is not itself an
  enrolled provider. The classifier's `UNIVERSITY_OR_AHC` reading of it is wrong.
- **Session 53's estimate.** It was ~28 rows / ~$23.2M, by name. The classification is **27 rows /
  $22,641,819.43**.
- **The other 84 rows are non-hospital.** 24 are FQHCs, 30 `OTHER` (nursing facilities, home-health
  agencies, designated mental-health agencies, Kinney Drugs, VSAC), 8 practices, 5 vendors, 1
  college, 1 school district, and 15 on §8's standing fallback (recovery residences and the like).
  Nothing is merged: North Country and NVRH appear under three spellings each.

## 2. Connecticut — four executed agreements, $49.98M, and one unsplit pair

- **The source.** The Governor's 2026-09-16 release, a day before CMS's:
  - Day Kimball Hospital **$20.23M**
  - Sharon Hospital **$13.12M**
  - Hartford HealthCare's Windham Hospital + Charlotte Hungerford Hospital **$12.65M combined**
  - Mathematica **$3.98M** (the TA vendor)
- **Rounding.** Every figure is rounded to $10,000, so each carries `AMOUNT_ROUNDED_IN_SOURCE` and
  `amount_confirmed = No`. The three hospital figures sum to the release's own "$46 million" exactly.
- **The Hartford HealthCare pair is ONE row and is not divided.** Windham (CCN 070021) and CHH
  (CCN 070011) are two separately enrolled hospitals.
  - It is coded `POOL_NAMED_HOSPITALS` + `MULTI_RECIPIENT_FIELD`, Nebraska's code for "hospitals
    named, no per-hospital split".
  - It is Tier 3, like Nebraska's row, so the bucket still does not mix tiers.
  - The row is `DIRECT`, not a pass-through: the hospitals are the grantees.
- **Mathematica** is `VENDOR_OR_CONTRACTOR` / `IN_KIND_BENEFIT`.
- **`R/03ac` no longer asserts that no award file exists.** It asked for that assertion to be deleted
  in the same commit as the extractor. It now asserts that the award file is `R/03au`'s. DSS's own
  pages still name nobody.

## 3. West Virginia — seven awards, $6,444,803; two hospital rows, $1,224,000

- **The source.** Five Governor's releases, 2026-09-04 to 09-22. Session 53's $6,442,803 was an
  addition error; the rows sum to **$6,444,803**.
- **Hospital rows:**
  - **CAMC/Vandalia Health** $612,000, on CMS CCN 510022.
  - **Cabell Huntington Foundation** $612,000, under §10.2's hospital-foundation row (owner decision;
    parent Cabell Huntington Hospital, CCN 510055), at `LOW`.
- **Other rows:**
  - WVU Medicine Center for Nursing Education: `UNIVERSITY_OR_AHC` (owner decision).
  - Ascend WV: `UNIVERSITY_OR_AHC`, "Operated under West Virginia University". Its "$2.4 million" is
    rounded.
  - WVHIN: `OTHER`, `IN_KIND_BENEFIT`.
  - CHANGE, Inc.: `FQHC_OR_RHC`, stated by the release.
  - Spotted Owl: §8's fallback, not promoted.
- **No probe yet.** Each release says more awards are coming.

## 4. Missouri — 20 Strategic Minor Renovations Program hospitals, no amounts

- **The source.** DSS: *"has awarded approximately $35 million … grants to 20 projects … A full
  list of awardees is below"*.
- **The rows.** Twenty `NAMED_HOSPITAL` rows at **$0**, Nevada's and Iowa's shape. Each is typed
  on the CMS Hospital Enrollment file with its CCN cited.
- **Figures deliberately not used:**
  - The congressman's $1.7M for Salem Memorial.
  - $35M ÷ 20.
- **The probe.**
  - The programme page is **re-based** to the 2026-09-23 copy, which is what the name tripwire had
    fired on. The 2026-09-01 copy stays as `program_page_prior`.
  - The SMRP roster is a fifth probe key.
  - `mo_assert_smrp()` fails the day DSS prices a hospital.
- **Unchanged.** The two priced partnerships ($7,232,660.43) and the hub-anchor file are unchanged.
  Only the awards CSV was written, so session 49's hub-anchor overlay is untouched.

## 5. Louisiana's probe ignores LDH's mega-menu

- `la_name_scope()` reads each page from its own doubled heading to the footer's "Surgeon General"
  signature, on both the live copy and the archived copy. This is Delaware's and California's fix.
- The 2026-09-23 halt came from an Office of Public Health programme list inside the menu.
- **The live probe now passes.** Its digest still moves because the menu moved.
- A test drives the retune both ways: it is silent on the archive and still fires on an injected
  recipient.

## Dollars moved (before write-back)

| Bucket | Before | After | Change |
|---|---|---|---|
| `NAMED_HOSPITAL` | 982 rows / $845,170,923.32 / 20 states | **1,033 / $902,386,742.75 / 24** | **+51 rows, +$57,215,819.43** |
| `POOL_NAMED_HOSPITALS` | 1 / $18,156,856.12 | **2 / $30,806,856.12** | **+1 row, +$12,650,000** (CT pair) |
| `POOL_UNNAMED_HOSPITALS` | 1 / $50,008,264 | unchanged | — |

The `NAMED_HOSPITAL` change by state:

| State | Rows | Dollars |
|---|---:|---:|
| VT | 27 | $22,641,819.43 |
| CT | 2 | $33,350,000 |
| WV | 2 | $1,224,000 |
| MO | 20 | $0 |

**Rural cut:** from 164 rows / $171,872,989.39 to **179 / $176,578,205.56**. That adds 9 Vermont
CAH rows and 6 Missouri CAHs at $0.

**Disposition:** 31 `EXTRACTED` / 6 `INVESTIGATED_NO_LIST` / 5 `INVESTIGATED_NO_PROBE` /
8 `QUEUED`. The queue holds AZ, CO, MT, ND, RI, UT, VA and WA: 19 candidates, $1,522,256,789.

## 6. Routine cutover result

(Filled in after the 15:00Z and 17:00Z firings.)
