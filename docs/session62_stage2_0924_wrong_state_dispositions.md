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

<!-- §6 onwards: the state dispositions, written after the four re-reads. -->
