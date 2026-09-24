# Session 62: Stage 2 on the 2026-09-24 pull, the wrong-state sweep, and every disposition re-read

2026-09-24. **RCJ quota: 0 calls.** Task 1 (Indiana's GROW regional extraction) was **not
started**: Task 2 took the session, as the owner allowed.

## 1. One live view of the record table

`stage2_record_table.rds` keeps every version (§6.3). About 30 readers in `R/` counted Tier 3
candidates in three different ways:

- all rows;
- rows with `superseded_by` NA;
- rows with `superseded_by` NA or empty.

On a table built from one pull the three agree, so nothing noticed. From the second pull on
they do not. A CHANGED record would count twice. A WITHDRAWN record keeps `superseded_by` NA,
so it would keep counting after RCJ dropped it.

`rhtp_record_table_live()` (`R/utils_config.R`) returns rows with `superseded_by` NA **and**
`change_status != "WITHDRAWN"`. Every reader now goes through it, and so does Stage 2's own
derived tables. It was committed **before** the re-run, when it was provably inert (0
superseded and 0 withdrawn rows on the 08-27 table).

## 2. Stage 2 on the 2026-09-24 pull

`Rscript R/02_normalize.R --run --date=2026-09-24`, 2 min 13 s.

| | Rows |
|---|---:|
| Record table, all versions | 7,425 |
| NEW | 1,970 |
| CHANGED (prior version kept, superseded) | 300 |
| WITHDRAWN | 280 |
| **Live Tier 3 candidates** | **1,372 → 2,447** |

Where the Tier 3 set moved most:

| State | 08-27 | 09-24 | Withdrawn | New ids | What it is |
|---|---:|---:|---:|---:|---|
| AK | 159 | 248 | 159 | 248 | RCJ **re-keyed** all of Alaska; the new rows carry a source document (227 PASS, was 0) |
| SC | 0 | 227 | 0 | 227 | RCJ now carries South Carolina's roster |
| IN | 38 | 214 | 14 | 190 | see §4 |
| MS | 3 | 173 | 1 | 171 | RCJ now carries Mississippi's roster |
| MI | 31 | 149 | 22 | 140 | see §4 |
| FL | 0 | 80 | 0 | 80 | **Florida is no longer invisible to RCJ** |
| KS | 54 | 93 | 0 | 39 | not re-read (no disposition file; §6) |
| AR | 0 | 33 | 0 | 33 | see §4 |
| SD | 1 | 29 | 0 | 28 | not re-read (§6) |
| CA | 11 | 4 | **11** | 4 | the eleven SRHRP seismic rows are gone |

## 3. The wrong-state sweep (`R/02c`), run immediately after

**The defect has reached Tier 3.** Sessions 42–61 asserted no misfiled record was Tier 3. The
09-24 pull breaks that:

| Filed under | Actually | Tier | Record |
|---|---|---|---|
| NM | OR | SUBAWARD | Wallowa County Health Care District, $1,965,251 |
| NM | OR | SUBAWARD | Wallowa Memorial Hospital (MRI), $964,000 |
| NM | OR | SUBAWARD | Wallowa Memorial Hospital – Rural Health Clinics, $400,000 |
| NM | OR | SUBAWARD | Wallowa Memorial Hospital and Medical Clinics, $5,464,316 |
| MI | SD | SUBAWARD | "South Dakota (Rural Strong grants)", $31,500,000 |

**Three of the four Wallowa rows name no state at all.** Only one says "Eastern Oregon". A test
that asks which state a record names cannot see a record that names none. So the sweep gains
`SWEEP_MISFILED_DOCUMENTS`: a hand-read list of documents that are wholly another state's.
Every live record from such a document is flagged `MISFILED_SAME_DOCUMENT`.

It is a list, not a rule. A multi-state digest also carries records of the state it is filed
under, and a rule keyed on "a misfiled record came from this document" would drag those in.
The Michigan digest is exactly that case.

**No award file consumed any of the five.** New Mexico has no award file (it is a negative).
Michigan's is built from MDHHS's roster, not from RCJ.

`sweep_assert()` no longer asserts the Tier 3 set is empty. It **pins it by record id**: a
sixth misfiled Tier 3 row fails the build, and so does one of these five leaving.

**RCJ also corrected itself.** Seven earlier verdicts no longer match a flagged record:

- three of Wyoming's five Utah documents, and the Oklahoma-derived Utah webinars page, are now
  filed under **Utah**;
- Alaska's three Providence rows were withdrawn.

They are kept in `SWEEP_RETIRED_VERDICTS` with the reason, not deleted. The build refuses if
one is flagged again. Totals: **17 misfiled records in 8 states** (was 10 in 5), 5 of them
Tier 3.

Ten new flags were read by hand. One is not a misfiling: an Indiana IDOA RFP (27-87793) whose
machine summary calls it "Florida's RFP". It is `SUMMARY_NAMES_WRONG_STATE`, which is a
reminder that §6's machine fields are search aids.

## 4. The provenance sweep (`R/02b`) had stopped catching anything

Two defects, both invisible until Stage 2 was re-run:

1. **A column clash.** Stage 2 has written `action_date` since the filter was wired in (session
   20), but the committed table predated that until today. `bind_cols()` renamed the pair and
   the per-state summary crashed.
2. **It excluded its own catch, and every assertion passed.** Stage 2 now quarantines 70 Tier 3
   rows on provenance itself. The sweep read only PASS/FLAGGED rows, so it reported **0 rows
   caught**. It now also reads rows quarantined on a `PROVENANCE_` flag.

After the fix: **66 rows in 4 states** (TX 53, NV 9, AZ 3, MS 1), was 101 in 9.

The rest did not stop being caught. **RCJ withdrew them**:

- California's 11 SRHRP seismic rows;
- Michigan's 8 opioid-settlement rows;
- Texas's 9 ATLIS/IGT Medicaid rows;
- Illinois's MyOwnDoctor row;
- Rhode Island's 3 opioid rows;
- New Hampshire's $1.9bn Medicaid row.

The tests now sweep those withdrawn rows re-labelled live, so each filter is still proven to
catch them if they return. The six registry entries stay; they match nothing today and say so.

## 5. The survey and trigger queue

Rebuilt from `R/03k`'s constants, never hand-edited.

- **Florida leaves `NEITHER`** (80 RCJ candidates; `RCJ_ONLY`).
- **Illinois enters it**: RCJ withdrew its $1 row, so the union no longer catches a state with
  $50,008,264 extracted. The "NEITHER never means nothing was awarded" evidence now rests on
  Illinois and Wyoming.
- The QUEUED four (MT UT AZ RI) hold 6 candidates, not 11. AZ's three webinar rows are now
  Stage-2-quarantined as pre-NOA, and RI's three opioid rows were withdrawn.

## 6. Every state disposition, re-read

Twelve builders failed as designed. **Seven more passed while writing prose their own new
counts contradicted.** Arkansas read "33 Tier 3 candidates ... NOT_IN_THE_AGGREGATOR_AT_ALL";
South Carolina read "227 candidates against 33 RCJ records"; New Jersey read "11 SUBAWARD
records ... NO_TIER_3"; Maine's "Anything else ... NONE" group had quietly absorbed 5 rows.
**A builder that passes is not the same as a builder that tells the truth.**

Every builder below now assigns each candidate to a group by rule and throws on an
unassigned candidate or a moved group count. Texas and Nevada had defaulted an unmatched row
into an existing group; that path is gone. Groups emptied by RCJ keep their history at 0 rows.
Pairing to our award files is exact name + exact amount, or an explicit hand-read
`record_id -> row` entry; nothing is fuzzy-matched (§2).

**No award figure in this repository moved.** Dispositions describe what RCJ carries; award
files are built from state sources and were restored after every `--build`.

| State | 08-27 → 09-24 | What RCJ carries now |
|---|---|---|
| TX | 68 → 85 | Still 0 RHTP subawards. New: HOPES and nurse-violence grants (predate the NOA); Nurse-Family Partnership $133.9M (state + TANF) and Mobile Stroke Unit $3.25M (state) — **read live, not archived** |
| NE | 39 → 52 | **Initiative 5.3 Intent to Award (09-01, 13 awards, $5,549,692.25) is RHTP and not in our file.** RCJ drops Regional West Medical Center ($93,867) |
| OK | 35 → 36 | one more Tier 2 budget line |
| NV | 34 → 42 | 3 budget lines; 5 contractors ($1.94M) from an unarchived CMS report — undecidable |
| IN | 37 → 214 | 185 GROW regional recipients at $1 (184 match the archived page); 2 region pools; 2 undecided |
| MI | 31 → 149 | 131 roster rows per award; SD's row WRONG_STATE. **The live MDHHS roster is 145 rows / $101.3M against our 139 / $69.9M** — Michigan's "total, not a floor" is stale |
| MS | 3 → 173 | all 167 awards to the cent; 4 duplicates |
| SC | 0 → 227 | 227 of 228 to the cent; SC Dept of Corrections ($6,836,679) held UNASSIGNED by Stage 2 |
| AR | 0 → 33 | 31 orgs at org totals; Mercy Fort Smith rounded (−$56,249); BDO GS admin vendor |
| NJ | 0 → 11 | 10 awards; the old builder read the wrong key in awards.json |
| CA | 11 → 4 | SRHRP withdrawn; 4 Distressed Hospital Small Grant rows ($25M, AB 108 state money — read live) |
| NM | 7 → 11 | 7 RHCDF state rows; Wallowa's 4 WRONG_STATE |
| LA | 6 → 12 | **THE NEGATIVE IS STALE.** 5 named Rural Clinician Credit Bank awards match LDH's 09-09 deck, which reports 53 awards / $12,701,996 (read live) |
| WY | no Tier 3 | Utah documents 5 → 2 (RCJ re-filed three) |
| DE | 6 → 12 | 4 SBHC awards re-issued at $1; 7 Downtown Development District rows (state money, read live) |
| ME | 12 → 17 | budget-narrative lines; **Medical Care Development is a named RHTP lead not in our file**, no amount |
| MO | 29 → 30 | RCJ double-carries the MDA award |
| NH | 27 → 26 | Medicaid rows withdrawn; FHC now only at $1 |
| TN | 0 → 1 | one UTHSC plan row; RCJ still holds none of the 53 HART awards |

## 7. Not done, and what is owed

- **Task 1, Indiana GROW regional extraction and probe, not started.** Note that
  `in_assert_regional_not_awarded()` passes only because it reads the 08-31 archive.
- **Evidence read live and not archived** (each disposition records the SHA-256): TX
  HHS0016568 and HHS0016736, CA Distressed Hospital page, DE DSHA release, LA shareholder deck,
  NE 5.3 notice, MI live roster. Archive each via the state's `--fetch` before relying on it.
- **Extractions owed:** Louisiana (53 Credit Bank awards; R/03ae becomes an extractor),
  Nebraska 5.3, Michigan's six new roster rows, Indiana's regions.
- **Registry rows to add to `non_rhtp_state_programs.csv`:** CA Distressed Hospital Small
  Grant Program, DE Downtown Development Districts. Annotate TX-ATLIS-MCO and TX-IGT as
  matching nothing since RCJ withdrew them.
- **Stage 2 tiering:** SC Dept of Corrections and three Michigan roster rows (Harbor Beach,
  both PACE) sit UNASSIGNED while comparable rows are SUBAWARD.
- **Unread new candidates in states with no disposition file:** AK 248 (re-keyed), FL 80,
  KS 39, SD 28, VT 12, MN 10, CO 8, WV 8, GA 5, WA 5.
- `ca_year1_status.csv` prose still says all eleven candidates are SRHRP.

