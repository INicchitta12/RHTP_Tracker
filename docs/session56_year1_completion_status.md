# Session 56 — which states have finished Year 1 awarding

2026-09-23. Zero RCJ quota, no network calls. Everything below is read from the
committed award files and the committed evidence archive.
`R/03aw_year1_completion_status.R` builds both tables;
`data/reference/year1_completion_status.csv` and
`data/reference/year1_complete_hospital_share.csv` are the outputs.

## 1. The rule

`year1_status` is a reading of a source. It is not a percentage threshold.

- **COMPLETE**: a state or CMS source says in its own words that Year 1 awarding
  is complete, **and** no initiative is recorded as unawarded.
- **PARTIAL**: a source says more awards are coming, **or** the repository
  records an initiative with no published award.
- **UNKNOWN**: neither.

The allotment percentage is a coverage signal only. It divides a Tier 3 figure
by a Tier 1 figure and never adds them (§0.2). Alaska is at 87.9% and is still
PARTIAL. Georgia's per-recipient column is 41.5% and Georgia is COMPLETE.

Two percentage columns are reported:
- **`pct_priced`**: `sum(amount)`, what the state prices to a recipient.
- **`pct_incl_pool_level`**: adds Tier 3 round totals announced without a
  per-recipient split, counted once per pool. Examples are Nevada's $87.4M,
  South Dakota's two rounds, and Georgia's per-initiative pools.
  - New Hampshire's CDFA "up to $40 million a year" is a ceiling and is **not** added.
  - Oregon's range row is not added. OHA's own "so far ... about $175.3 million" is 88.9%.

## 2. The 31 states

| State | Allotment | Priced | % | Incl. pool-level | % | Source calls it complete | Initiative unawarded | year1_status |
|---|---:|---:|---:|---:|---:|---|---|---|
| GA | $218,862,170 | $90,765,080 | 41.5% | $197,148,327 | 90.1% | Yes | No | **COMPLETE** |
| FL | $209,938,195 | $188,201,256 | 89.6% | $188,201,256 | 89.6% | Yes | No | **COMPLETE** |
| AK | $272,174,856 | $239,186,195 | 87.9% | $239,186,195 | 87.9% | No | Yes | **PARTIAL** |
| OR | $197,271,578 | $140,994,009 | 71.5% | $167,694,009 | 85.0% | No | Yes | **PARTIAL** |
| WY | $205,004,743 | $173,859,752 | 84.8% | $174,126,752 | 84.9% | No | Yes | **PARTIAL** |
| SC | $200,030,252 | $167,299,901 | 83.6% | $167,299,901 | 83.6% | No | Yes | **PARTIAL** |
| AR | $208,779,396 | $149,177,618 | 71.5% | $149,177,618 | 71.5% | No | Yes | **PARTIAL** |
| AL | $203,404,327 | $143,745,821 | 70.7% | $143,745,821 | 70.7% | No | Yes | **PARTIAL** |
| MS | $205,907,220 | $104,115,147 | 50.6% | $104,115,147 | 50.6% | No | Yes | **PARTIAL** |
| NV | $179,931,608 | $0 | 0.0% | $87,400,000 | 48.6% | No | Yes | **PARTIAL** |
| MD | $168,180,838 | $78,625,071 | 46.8% | $78,625,071 | 46.8% | No | Yes | **PARTIAL** |
| KS | $221,898,008 | $96,027,147 | 43.3% | $96,027,147 | 43.3% | No | Yes | **PARTIAL** |
| VT | $195,053,740 | $84,540,011 | 43.3% | $84,540,011 | 43.3% | No | Yes | **PARTIAL** |
| MI | $173,128,201 | $69,883,392 | 40.4% | $69,883,392 | 40.4% | No | Yes | **PARTIAL** |
| NY | $212,058,208 | $76,190,022 | 35.9% | $76,190,022 | 35.9% | No | Yes | **PARTIAL** |
| NH | $204,016,550 | $66,547,394 | 32.6% | $66,547,394 | 32.6% | No | Yes | **PARTIAL** |
| CT | $154,249,106 | $49,980,000 | 32.4% | $49,980,000 | 32.4% | No | Yes | **PARTIAL** |
| IL | $193,418,216 | $50,008,264 | 25.9% | $50,008,264 | 25.9% | No | Yes | **PARTIAL** |
| PA | $193,294,054 | $42,198,310 | 21.8% | $42,198,310 | 21.8% | No | Yes | **PARTIAL** |
| NE | $218,529,075 | $36,137,615 | 16.5% | $36,137,615 | 16.5% | No | Yes | **PARTIAL** |
| ME | $190,008,051 | $12,000,000 | 6.3% | $12,000,000 | 6.3% | No | Yes | **PARTIAL** |
| OH | $202,030,262 | $10,000,000 | 4.9% | $10,000,000 | 4.9% | No | Yes | **PARTIAL** |
| NC | $213,008,356 | $0 | 0.0% | $10,000,000 | 4.7% | No | Yes | **PARTIAL** |
| MO | $216,276,818 | $7,232,660 | 3.3% | $7,232,660 | 3.3% | No | Yes | **PARTIAL** |
| WV | $199,476,099 | $6,444,803 | 3.2% | $6,444,803 | 3.2% | No | Yes | **PARTIAL** |
| OK | $223,476,949 | $3,572,121 | 1.6% | $4,172,121 | 1.9% | No | Yes | **PARTIAL** |
| IN | $206,927,897 | $860,088 | 0.4% | $860,088 | 0.4% | No | Yes | **PARTIAL** |
| DE | $157,394,964 | $0 | 0.0% | $0 | 0.0% | No | Yes | **PARTIAL** |
| IA | $209,040,064 | $0 | 0.0% | $0 | 0.0% | No | Yes | **PARTIAL** |
| ID | $185,974,368 | $0 | 0.0% | $0 | 0.0% | No | Yes | **PARTIAL** |
| SD | $189,477,607 | $5,618,367 | 3.0% | $127,118,367 | 67.1% | No | Unknown | **UNKNOWN** |

**Two COMPLETE, twenty-eight PARTIAL, one UNKNOWN.** Each row's evidence
sentence and archived file are in `year1_completion_status.csv`.

- **Florida.** The Governor's 2026-08-11 release says: *"With this latest round
  of awards, AHCA has awarded the full scope of Florida's RHTP funding."* AHCA's
  page says: *"Year 1 RHTP Sub-awardees have been awarded."*
  - The $21.7M between the published $188.2M and the allotment is earlier
    monitoring and support procurements. The release says those were awarded
    "earlier this year". They have no published recipient list, but they are
    awarded, not outstanding.
- **Georgia.** DCH (2026-08-27) says Phase 4 *"complete[s] the initial Year 1
  award cycle."* CMS's release the same day says the same thing, independently.
- **Michigan is PARTIAL.** MDHHS's *"all RHTP Subrecipients"* describes the
  roster, not the round. The same page advertises *"additional RHTP GFOs"*.
- **South Dakota is UNKNOWN.** It has two unnamed rounds and 13 administrative
  contracts. No source says Year 1 is complete. No source names a Year 1
  initiative still to come; both releases speak only of "future funding cycles".
- **Iowa is PARTIAL, but that rests on dated evidence.** The latest archived
  statement is *"As we continue awarding funds"* (2026-06-18). Iowa prices no
  recipient, so it has no percentage.

## 3. Hospital share in the two COMPLETE states

| State | Published | Named-hospital $ | Floor | Ceiling | Floor as % of allotment |
|---|---:|---:|---:|---:|---:|
| FL | $188,201,256 | $49,345,213 (15 rows) | **26.2%** | 29.6% | 23.5% |
| GA | $197,148,327 | $90,277,580 (125 rows) | **45.8%** | 57.0% | 41.2% |

**Florida.** The ceiling adds $6,331,220 of priced rows coded `Unclear`.

**Georgia's share is still bounded, even though its round is complete.**
- Two pools name hospitals and publish no per-hospital split:
  - Phase 2 Rural Stabilization, $6.5M. It names 17 hospitals and one state agency.
  - Phase 4 AHEAD, $15,635,000. It names 7 hospitals plus the readiness assessments.
- The ceiling counts both pools whole, $22,135,000. That is an upper bound, not
  an estimate: each pool also holds a non-hospital recipient.
- Two unpriced `Unclear` rows are noted and not added: the Type 2 ambulances,
  which are in-kind, and nursing care improvements.

Neither state has a CCN match (blocker 5), so every hospital row sits at
`MEDIUM` or below.
