# Session 82: Colorado extracted, Texas recorded as a floor, AL/NC read, six runners moved

2026-10-01. Zero RCJ quota. Interactive probe lines (CO, TX, NC, NEWSROOM:TX, CMS) are in
`logs/probe_results.csv` with origin `interactive`.

## 1. Task 1 — the suite fix and the CMS file

- **The fix had already landed.** Session 80's branch (routines.csv v4 ids, the Indiana GROW date parse) is on
  `main` via PRs #83 and #84. The CMS runner's 10-01 13:00Z decline ran against `dda96da`, before that merge:
  its three failures were the IN GROW date test and the CA/NH coverage gaps, all three fixed on `main` now.
- **A clean suite run on `origin/main` (`56497cf`)**: see §6.
- **The five announcements are now in `cms_state_announcements.csv`**, collected by an interactive
  `R/00_cms_press_monitor.R --run` (32 announcements, 27 states): CO 09-28 ($169M), MT 09-29 ($8.7M), TX 09-28
  ($51M), NC 09-30 ($20M), AL 10-01 ($55M). The monitor flags CO, MT and TX as new states.

## 2. Task 2 — Colorado (`R/03bo_co_year1_awardees.R`)

**Source.** `hcpf.colorado.gov/RHTP-awardees`, "Our Awardees": 92 lines, `<name> - $<amount>`, no total, no CMS
footer. Archived with HCPF's 2026-09-28 release, the programme page and CMS's release under `data/evidence/CO/`.

**The roster does not reconcile to the release, and the file does not force it to.**

| Figure | Source |
|---|---|
| $170,210,575.26, 92 lines, 91 distinct strings | the roster, summed |
| $169,587,181, "91 applicants", "approximately 250 projects" | HCPF release |
| "$169.6 million", "91 grantees" | CMS release |

- The gap is **$623,394.26**.
- The Every Child Pediatrics line is **$623,395.26**, the only line with cents, and is within **$1.00** of the gap.
- Two readings survive:
  - **H1:** "91" counts distinct strings (Banner Health Foundation appears twice), and the release total omits
    something.
  - **H2:** the Every Child line was added after the release. That explains the dollars to $1 and makes the
    line count 91.
- H2 fits both numbers but is arithmetic, not a statement by HCPF. **No line is dropped.** Both totals are in
  `co_year1_status.csv`, and the question is queued (`CO_ROSTER_VS_RELEASE_TOTAL`).

**Typing.** Every line is checked against CMS's CO Hospital, FQHC and RHC Enrollment files
(`data/evidence/federal_records/2026-10-01/`, SHA-256 manifest).

| Result | Lines | Dollars |
|---|---:|---:|
| Hospital, exact enrolled legal name or dba (MEDIUM) | 29 | $72.0M |
| Hospital, hand-read bridge (LOW): Lincoln, Delta County Memorial, East Phillips, Kit Carson, Yuma | 5 | $14.1M |
| Hospital, §10.2 foundation row (LOW, GENERAL_KNOWLEDGE): Banner Health Foundation ×2 | 2 | $629,142 |
| **NAMED_HOSPITAL total** | **36** | **$86,693,159** (50.9%) |
| §8 fallback (NONPROFIT_CBO, LOW), queued | 23 | $37,836,170 |

**§10.2 on districts and foundations, not the name screen.**
- **Three names read as hospitals and are not hospitals on the record:**
  - Walsh Hospital District holds only an RHC enrolment (063874).
  - West Custer County Hospital District holds no enrolment; its Westcliffe clinic is enrolled under Salida
    Hospital District.
  - Telluride Regional Medical Center holds no enrolment.
  - All three are `No` and queued (`CO_HOSPITAL_DISTRICT_NO_HOSPITAL_ENROLMENT`, $1,983,820).
- Lake Fork Health Services District is an RHC (exact match). Ute Pass Regional Health Services District has no
  enrolment.
- Session 81's crude screen found "~38 lines, ~$93.8M". The enrolment check gives 36 lines and $86.7M.
- **Valley Citizens' Foundation for Health Care Inc. is NOT a foundation row.** It is the exact enrolled legal name
  of Rio Grande Hospital (061301).
- **Banner Health Foundation IS a foundation row:** its name names its parent system, Banner Health (060126).
- The two San Luis Valley lines name their SITE in brackets. Each carries its own CCN (060008 Alamosa, 061308
  Conejos).
- Eastern Plains Healthcare Consortium, Colorado Community Health Network and Carina are networks the page does
  not describe. §10.2's association row is not reached, so they stay on the fallback (§0.3).

**Wiring.**
- Survey 37/8/2/3: CO moved to `EXTRACTED`.
- CO was added to `STATE_FILES` (union test), to 03aw (`PARTIAL`, citing CMS's "one part of the larger overall
  funding amount"), and to 03bh's award files. RCJ carries none of the 92 lines.
- The CO Routine (`R/03az --probe`) now delegates to `R/03bo`'s watch: the roster's count and total plus a
  name diff on the two pages. It ran live: UNCHANGED.

## 3. Task 3 — Texas as a known floor (`R/03bp_tx_bp1_floor.R`)

- **The source.** `bdgt-prd-1-ann-rpt.xlsx` is archived as `data/evidence/recheck/2026-10-01/TX/2026-10-01_hhsc_bdgt_prd_1_ann_rpt.xlsx`
  (sha256 `28f49776…`, Last-Modified 2026-09-28T15:33:17Z). Its First-Tier Entities tab lists:
  - HHSC, $6,149,649.67 obligated;
  - DSHS, $22,389,223 obligated;
  - **33 hospital districts and authorities at $750,000 obligated, $0 disbursed**, all "Other Local Government".
- **The floor file.** `tx_bp1_first_tier_floor.csv` records the 33. It is **not an award file**:
  - It is never in `STATE_FILES`, and a test asserts that.
  - It has no `amount`, `recipient_type` or `distributed_to_hospital` column.
  - Its dollar column is `obligated_bp1_report`.
- **The enrolment screen** against CMS TX Hospital Enrollment codes nothing:

  | Result | Districts |
  |---|---:|
  | Exact legal name | 28 |
  | Near name, needs a hand bridge (Coryell, DeWitt, Haskell, Ochiltree) | 4 |
  | No hospital enrolment (Hardeman County Hospital District) | 1 |

- **The watch.** `R/03n --probe` reads the live xlsx into a temp file and trips when the tab names other than
  33 districts. It ran live: UNCHANGED.
- **NEWSROOM.** The NEWSROOM sweep's TX tripwire (HHSC's "$51 Million in First Round" headline) was read. The TX
  `governor` and `hhsc` baselines were re-based with `nw_fetch()`, and both re-probed UNCHANGED. The file names
  keep their 2026-09-24 prefix; the manifest carries the 10-01 date.

## 4. Task 4 — Alabama and North Carolina

**Alabama (Governor, 2026-10-01).**
- **A named, priced roster:** 34 grants across seven initiatives, "nearly $55 million". The release says "the
  grants announced today round out year one of funding". CMS adds that it "completes Alabama's initial Year 1
  award cycle".
- The footer prints $203,404,326.54, 100% CMS: Tier 1.
- Archived under `data/evidence/recheck/2026-10-01/AL/`. **Not extracted this session.**
- About ten recipients read as hospitals by name. Type them on CMS AL enrolment at extraction.
- Several amounts are rounded ("$1.45 million"), so expect `AMOUNT_ROUNDED_IN_SOURCE`, as with round 1.

**North Carolina.**
- **09-30, "$20M" (CMS and Governor Stein).** This is the Rural Health Innovation Fund's **launch**, not awards:
  - Applications close 2026-11-16 and "awards are anticipated to be announced in January 2027".
  - Year 1 eligibility covers primary care, FQHCs, CHCs and safety-net providers.
  - It is Tier 2, with no roster.
- **09-14 SBHC release.** NCDHHS names **five organisations** for $1.25M with no split: Appalachian District Health
  Department, Blue Ridge Community Health Services, First Health of the Carolinas, Mountain Community Health
  Partnership and Wilson County Health Department.
  - This is a third NC roster and is not in `nc_year1_awardees.csv`.
  - It also contradicts 03aw's NC note that School Health Centers "closed unawarded". Fix both at the next NC
    rebuild.
- **The NC probe** tripped twice on new NCDHHS navigation:
  - "Rural Health Workforce Transformation" is a new programme page. It names no awardee, but it does say each
    ROOTS Hub has $5.79M for workforce, a Tier 2 figure.
  - The opportunities page lists the Innovation Fund.
  - All four strings went into `NC_NAME_FURNITURE`, each with its sentence. The retune test now covers
    `roots_page` and `opportunities`. The re-run passed.

## 5. Task 5 — six runners moved

| State | New runner | New trigger | Old trigger (disabled) | Cron |
|---|---|---|---|---|
| NY | `session_018TASKazmjXxjyR3zoSppcu` | `trig_012g3adVBX9KEgDt9XiVi2tU` | `trig_014kvDg8x3JDqdWySvHxrREU` | `10 11 * * 0,3` |
| LA | `session_01Exxx2NUf7qTePutapN8Bhf` | `trig_01NRTUU1Vg3DoQPL1uK2gKBt` | `trig_016GDtAW1DvWCexnRSm4LxK8` | `50 12 * * 3,6` |
| WY | `session_01JzHs9iCFVnm3Ti3JVAADvg` | `trig_01CLqQDvGoWCDoSMtS29FJbQ` | `trig_01F98Jr5do6PXbUzNLBGjzGE` | `10 21 * * 2,5` |
| ME | `session_01CcPJrVH4hi3CTfxNiEB7ja` | `trig_01D21P4pNZXJv9vN7Uv6jmdn` | `trig_01RyrB4uNLd6rdjaD8d9tWBk` | `20 16 * * 2,5` |
| MO | `session_0156VLzXL66vgdyq93sJrMqG` | `trig_01EB2Xxyn1bSy3LcGBEcuZra` | `trig_0183VrPsZUMmc3dMneainqXm` | `0 15 * * 3` |
| SC | `session_017LSdVkRe52xgiVBmZTTwjy` | `trig_01221XxhsPrg8ojwngYSAAFv` | `trig_01R1pZjkPkQZWD3vctiAJQ44` | `30 8 * * 4` |

- **Setup.** Same as session 79: `env_01RnpqJ1D6wFAaRMvFu43oV3`, `claude-sonnet-5`, auto mode, the repository on
  `main` as source and outcome, no seed prompt. The names and crons are unchanged.
- **Prompts.** `R/routine_prompts_worktree.R --write` changed only these six prompts, and only the runner id.
  All six stored prompts are byte-identical to `config/routine_prompts/v4/*.txt`.
- **The cut-over.**
  - The six old ids were disabled, not deleted. Delete them once each new id has put a line on `main`.
  - `routines.csv` chains each old id with its `logging_since`, so the cut-over orphans no firing.
  - No runner has two enabled Routines.
  - `R/probe_coverage.R --check` passes: 55 due firings, 3 explained.
- **Must merge before ME's Fri 10-02 16:20Z firing**, or the new ids read as unregistered on `main`.

## 6. What CO's enrolment file touched elsewhere

- **R/03bj's cross-state sweep found two new hits**, both now in `EH_READ_NOT_APPLIED` and neither applied:
  - **County of Logan (CO) vs COUNTY OF LOGAN, Oakley KS (171326).** A different legal body with the same name.
  - **National Jewish Health (Quitlink), Michigan, $435,000.** CO Hospital Enrollment carries NATIONAL JEWISH
    HEALTH (060107) at its exact legal name.
    - Session 49 typed the row VENDOR_OR_CONTRACTOR "by function", which is §0.3a's error.
    - MDHHS states no form, so §10.2's enrolled-hospital rule reads as APPLY.
    - It is deferred to the owner (`MI_NATIONAL_JEWISH_ENROLLED_HOSPITAL`). No task this session covered Michigan.
- **Rural cut (R/03ar), restated:**

  | | Lines | Dollars |
  |---|---:|---:|
  | Colorado lines CMS enrols as CAHs (by their own CCN) | 26 | $64,069,474 |
  | Total rural cut | 240 | $245,561,955.03 |

  Banner Health Foundation's two lines carry no CCN.

## 7. Suites

- **`origin/main` (`56497cf`), clean worktree: exit 0.** The skips are the standing CMS first-run skip and one
  NM archive-history skip specific to the worktree. Task 1's fix was already on `main`.
- **This branch.** The full runs found three groups of consequences, each fixed:
  - partition ledgers in `test_03ap`, `test_03bj` and `test_03ar`, each gaining a Colorado layer;
  - the 03bj sweep verdicts;
  - the TX manifest location, and the MI queue count.
- **Final full run:** 2 failures, both in `test_03v`'s Michigan queue count, which expected 2 MI questions and
  now finds 3. With that fixed, `test_03v` passes alone (215/215). The run before it had cleared every other
  file. 2 skips: the standing CMS first-run skip and the NM archive-history skip.
