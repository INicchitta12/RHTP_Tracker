# Session 71 — academic health centres are hospitals, OTHER must state a form, 21 enrolment files

## Task 1: `AHC_ENROLLED_HOSPITAL_OPERATOR` resolved as option (b)

**The rule, now in spec §10.2 and its two mirrors** (block "Academic health
centers and enrolled hospital operators", plus one flow-table row; byte-identical
in all three, and the parity test covers it). Where CMS enrols the awardee's
LEGAL ENTITY as a hospital, the recipient is `HOSPITAL_OR_SYSTEM`, the flow is
`DIRECT`/`Yes`, and the CCN goes in the row's `ccn` column.
- The enrolment is a primary federal source. Keeping an awardee at
  `UNIVERSITY_OR_AHC` because the name reads "university" is recognition
  overriding a federal record, which §0.4 forbids.
- The activity does not decide it (§0.3a). Telehealth, training, outreach and
  food-is-medicine are hospital operations when a hospital runs them.
- Winston County's footing (session 50) wins over OHSU's (17) and UNC's (38).

**Three new columns, only on the 14 files the overlay touches.**
- `recipient_subtype = ACADEMIC_HEALTH_CENTER` marks the AHC rows so any figure
  can be reported with them shown separately, or subtracted, without re-coding.
- `cms_enrolment_match` records how the match was made.
- `cms_enrolment_record` names the CMS record and the archived file behind it.

All three codes are in `vocabularies.csv`.

**Matching is exact, never fuzzy.** `R/03bj`'s machine sweep matches the awardee
string, or its entity half (before a comma, parenthesis or spaced dash, or after
" at "), to an enrolled hospital's ORGANIZATION NAME or DBA. A prefix is never
matched by machine. "University of Alabama" is a prefix of "University of
Alabama at Birmingham" and is a different body; the same goes for "University of
Arkansas" and UAMS. Every sweep hit (39) carries a hand-read verdict, and the
build refuses an unread one (the §0.1 mode-6 design). Four hand-read bridges are
named, all at LOW:
- UNC: legal name less "at Chapel Hill".
- Iowa's two spellings of "University of Iowa Health Care": the State University
  of Iowa's hospital DBA.
- Nevada's two Carson Valley / Washoe Barton rows: the DBA, and the legal name
  less "a Nevada nonprofit corporation". Both rows are counted as one bridge.

### What moved

| State | Rows | $ moved into `NAMED_HOSPITAL` | Recipient (CCN) | AHC |
|---|---:|---:|---|---|
| AR | 4 | 17,060,066.00 | UAMS (040016), both rounds | yes |
| AL | 5 | 11,621,700.00 | UAB (010033) 3; University of South Alabama (010087) 2 | yes |
| AL | 3 | 3,602,968.00 | AltaPointe Health Systems (014014) | no |
| WA | 2 | 9,740,000.00 | University of Washington (500008) | yes |
| WY | 1 | 9,255,398.00 | University of Utah (460009), GME, out of state | yes |
| AK | 1 | 4,559,450.53 | Providence Health & Services-Washington (020001) | no |
| OR | 7 | 3,862,057.31 | OHSU (380009) | yes |
| MI | 2 | 2,000,000.00 | Regents of the University of Michigan (230046) | yes |
| LA | 1 | 1,500,000.00 | Ochsner Clinic Foundation (190036) | no |
| OK | 1 | 38,600.00 | Choctaw Nation of Oklahoma (370172) | no |
| GA | 1 | 0 | Emory University (110010) | yes |
| IA | 2 | 0 | University of Iowa Health Care (160058), bridge | yes |
| NC | 1 | 0 | UNC Hospitals (340061), bridge | yes |
| NV | 2 | 0 | Carson Valley Health / Washoe Barton (291306), bridges | no |
| **Total** | **33** | **63,240,239.84** | | |

- AHC rows: **25 / $53,539,221.31**.
- Enrolled non-AHC hospital operators: **8 / $9,701,018.53**.

The owner's instruction covered "any other row where the legal entity matches".
- **AltaPointe.** Session 12's override held these three rows back because "the
  release does not state which entity received the grant". CMS answers that: the
  named entity is itself the enrolled psychiatric-hospital operator.
- **Providence (Alaska) and Ochsner.** Both sat on §8's fallback.
- **Choctaw Nation.** Its `TRIBAL_ORG` was a curated name override.

**National `NAMED_HOSPITAL`: 1,152 / $959,074,602.68 / 28 states → 1,185 /
$1,022,314,842.52 / 30 states** (WA and LA enter). Without the AHC rows it is
1,160 / $968,775,621.21. Neither pool bucket moved.

**Completed states.**
- Arkansas's floor goes from 54.6% to **63.0%** (34 rows / $128,336,961.52).
- Georgia's floor stays 45.8%. Its ceiling rises from 57.0% to **60.2%**, because
  Emory is one of six named members of the $6,209,688 "Strengthening the
  Continuum of Care" pool, which DCH prices only as a whole. The ceiling is still
  STRICT: GHA and DPH hold unpublished shares of that pool.
- Florida is unchanged.
- The rural cut is unchanged at 209 rows / $177,456,356, because none of the
  re-typed rows is a CAH or REH. Its guard is re-stated at 1,185 rows.

### Held, not re-coded: `ENROLLED_HOSPITAL_STATE_STATED_OTHER_FORM` (10 rows, $2,088,858)

Here a STATE primary source states another form, so two primary sources
disagree and neither reading is recognition:
- **Alaska's Organization Type column.**
  - BBAHC $50,000, ANTHC $638,858 and ASNA $500,000: "Tribal Health
    Organization". Session 12's per-project rule applies.
  - Alaska Psychiatric Institute $300,000: "State Agency", and CMS enrols it
    only as a DBA of a different state department.
- **Oregon's Rural Health Clinic table** (session 17's hospital-owned RHCs):
  - Lake Health District.
  - Saint Alphonsus Baker City.
  - Four Providence Oregon hospital and clinic-site rows.

### Not reached: `AHC_STRING_NAMES_NO_ENROLLED_ENTITY`

These awardee strings do not print the enrolled legal entity:
- UAB Montgomery, $2,090,000.
- OHSU Casey Eye Institute, $783,516.
- University of Michigan: MEDIC, $300,000.
- ORPRN and Oregon Perinatal Collaborative strings.
- University of Maryland Medical System, $4,020,144. This is a hospital system,
  not a university, and its enrolled members are separate LLCs.

These are correctly out and not queued, because they are different bodies:
- Johns Hopkins University (the hospital is The Johns Hopkins Hospital).
- Medical University of South Carolina (the hospital is the Medical University
  Hospital Authority).
- University of Alabama.
- University of Arkansas.

## Task 2: session 49's OTHER rows, re-read

Session 49 left **40 OTHER rows (34 organisation strings)** after session 70
withdrew NARHC. Each was read for an actual stated form.

- **35 rows state one** and keep OTHER. Examples: PACE organisation, retail
  pharmacy, NEMT provider, workforce investment board, CCBHC, health-technology
  company, pediatric dental practice. Each form is now recorded explicitly in
  `EH_OTHER_FORMS`.
- **Five do not**, and go to §8's standing fallback (`NONPROFIT_CBO` + LOW +
  `RECIPIENT_TYPE_INFERRED`). Session 49's basis stays in `verified_basis` as the
  audit trail. **$0 moved**: all five were `No` and stay `No`.

| Row | Session 49's basis |
|---|---|
| GA Behavioral Pediatric Resource Center | "Could not identify an organization by this exact name" |
| MI Rudyard Area School Wellness Center ($83,333) | a school SITE; "the operating organization ... was not confirmed" |
| OK Empowerment Solutions ($29,950) | "Could not identify the organization"; the form was inferred from what the grant buys |
| OR Regional Partners | "OHA names no organization" |
| OR School-Based Health Center Planning Grants | "OHA names no organization" |

**The check is replaced, not patched.** `other_assert_forms()` requires every
OTHER row in the repository (113) to carry a determined form:
- 35 from session 49's hand-read table;
- 42 from session 50's `unstated_form_typing_decisions.csv`;
- 36 from the row's own "Determined form" clause (sessions 52–59).

A missing form, a form that repeats the name, or a basis that disclaims a form
fails the build. The table is `data/reference/other_type_form_review.csv`.

## Task 3: 21 hospital enrolment files archived

Archived under `data/evidence/federal_records/2026-09-25/`, with SHA-256s in the
MANIFEST. Source: CMS Hospital Enrollments, the same dataset and filter as the
AR file.
- **The owner's seven:** AL, OR, IA, MD, WA, UT, NC.
- **Fourteen more:** PA, AK, IL, NE, OK, NV, MI, ME, WY, DE, ID, OH, VA, LA. That
  covers every extracted state whose hospital file was not yet archived, so the
  sweep reaches all of them.

`R/03ar`'s enrolment map now includes the states whose rows carry a new CCN.

## Rebuild order and new files

- **`R/03bj_enrolled_hospital_operator.R`**
  - `--report`: the sweep and its verdicts.
  - `--apply`: patches the 14 committed files as raw strings. All 38 state files
    round-trip byte-identically. The apply is idempotent, and the diff is exactly
    the target cells plus three appended columns.
  - `--totals`: the effect by state.
  - `s71_overlay(d, file)` runs after session 49's `vq_overlay()`.
    `R/03ai --build` (both AR rounds) and `R/03u`'s `nv_with_overlay()` call it.
    **For any other touched state, run `R/03bj --apply` after a rebuild.**
- **New reference tables:**
  - `enrolled_hospital_operator_sweep.csv`: 39 hits, each with its verdict.
  - `other_type_form_review.csv`: 113 rows.
