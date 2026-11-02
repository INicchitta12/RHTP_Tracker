# Session 112 — End of Budget Period 1 sweep, final Year 1 table, independent check (2026-11-02)

Deliverable: `output/year1_summary_2026-11-02.xlsx` and `data/reference/year1_summary_2026-11-02.csv`
(R/08, built after every session 112 extraction, every overlay and `R/07 --apply`). The pre-sweep
fallback build (identical to 10-29) is commit `788865d`.

## 1. Headline figures (national row, 2026-11-02)

| Measure | 10-29 build | 11-02 final | Change |
|---|---:|---:|---:|
| Hospital best estimate | $2,005,223,415.77 | $2,034,862,538.90 | +$29,639,123.13 |
| — of which CODED | $1,780,528,970.90 | $1,821,345,454.64 | |
| — of which BEST_JUDGMENT | $224,694,444.87 | $213,517,084.26 | |
| Strict NAMED_HOSPITAL | $1,731,421,723.08 (1,835 / 36) | $1,761,827,518.82 (1,908 / 37) | +$30,405,795.74 |
| POOL_NAMED_HOSPITALS | $86,555,171.43 | $86,895,779.43 | +$340,608 |
| POOL_UNNAMED_HOSPITALS | $69,323,109.17 | $79,214,848.17 | +$9,891,739 |
| Awards published | $4,171,734,402.31 | $4,499,752,447.91 | +$328,018,045.60 |
| % of $10B allotment | 41.7% | 45.0% | |
| Hospital % of awards (national) | 48.1% (n/m on Overview) | 45.2% (n/m on Overview) | |
| Hospital % of allotment | 20.1% | 20.3% | |
| Intents in awards published | — | $1,703,446,788.41 | |
| Intents in hospital best estimate | — | $771,152,504.37 | |
| Strict rural cut | $549,250,719.56 | $559,285,398.43 | |
| Year 1 COMPLETE | 4 (FL GA AR AL) | 8 (+ VT ID WY UT) | |

Subset row (`US_GE50`, state award sources only, ≥50% of allotment published): **n = 23** (was 21; +PA,
+UT). Allotment $4,673,429,957; awards $3,728,812,818.21; hospital best estimate $1,612,024,736.82 =
**43.2% of awards, 34.5% of allotment**; strict named $1,507,090,381.12. Members: AK AL AR CA CO FL GA ID
IN MD MI MS NJ NV OH OR PA SC SD TX UT VT WY. On Overview the row reads "23 states ≥50% published*".

## 2. What moved, by state (hospital best estimate)

| State | Hospital Δ | Strict Δ | Why |
|---|---:|---:|---|
| IN | −$16,700,000 | 0 | Owner ruling (a): GROW Region 5 is an 8–8 tie, and a tie is not a majority (§7) |
| CO | −$6,659,872 | −$6,659,872 | HCPF re-priced 11 lines on the same 92 names (latest list governs); San Luis Valley Health $7,889,561 → $1,556,234, unexplained |
| MI | +$18,510,656 | +$12,960,656 | MDHHS roster as of 10-01 (231 rows, +93/−7); + MHA $4.5M and UP Health Care Solution $1.05M on the association/network judgment |
| UT | +$15,088,551.90 | +$5,196,812.90 | NEW: DHHS RHTP Awardee Announcement (41 intents, $193.1M); UHA recruit-and-retain $9,891,739 POOL_UNNAMED |
| PA | +$14,597,014.54 | +$14,597,014.54 | DHS Selected Projects, 178 authorized projects; Guthrie moved from the CMS obligation file to the state source (counted once) |
| SD | +$2,515,882 | +$2,515,882 | open.sd.gov register 63 contracts (+10, one amendment) |
| OK | +$1,873,344 | +$1,532,736 | Five new /rhtp/ rosters (R/03co): Lung Cancer Screening hospitals; two SSM affiliate pool lines |
| TX | +$413,546.69 | +$262,566.30 | 10/29 list: HHSC corrected the three transposed lines (Anson HD now priced); GHC Hemphill ruling (b) +$150,980.39 |
| VT, WV, ID, WY | 0 | 0 | VT +4 non-hospital agreements; WV +2 non-hospital awards; ID/WY status only |

## 3. Owner rulings applied (Task 2)

- (a) IN GROW Region 5 NOT_HOSPITAL; `SC_POOL_TIEBREAKS` removed; CLAUDE.md §7 "A tie is not a majority".
- (b) TX "GHC Hemphill Operations, LLC" BEST_JUDGMENT HOSPITAL; strict file unchanged.
- (c) NH CAH/Acute Care RFA ($17.5M component) stays HOSPITAL; Notes: awards due mid-December 2026.
- Cosmetics: Overview subset label "<n> states ≥50% published*"; column A sized to state names; Notes lines
  for the subset definition and "National allotment sums to $10,000,000,003 because each state's allotment is
  rounded to the dollar."

## 4. Completion status changes (R/03aw)

| State | Now | Sentence | Archive |
|---|---|---|---|
| VT | COMPLETE | "Vermont has fully obligated its approximately $195 million Year 1 RHT award" (AHS, 10-30) | `recheck/2026-11-02/VT/` |
| ID | COMPLETE | "the State of Idaho completed the awards for $186 million in Year 1 grant funding" (Governor, 10-28) | `recheck/2026-11-02/ID/` |
| WY | COMPLETE | "funding allocations, competitive applications, and awards have been completed for Year 1" (DOH summary 10-23); $30.9M pool-level approvals name nobody | `recheck/2026-11-02/WY/` |
| UT | COMPLETE | "CMS has officially reported that Utah has successfully demonstrated obligation for 100% of its Year 1 RHTP funding" (DHHS page, 10-29); every award row an intent | `recheck/2026-11-02/UT/` |
| NY | PARTIAL | Tier 2 allocations recorded ($30M / $13M / $79.5M; $1M SBHC explains $76.19M vs $77.2M); "fully obligated per DOH spokesperson (Politico Pro, K. Cordero, 10-29-2026); not confirmed on a state source." | `NY/2026-09-22_ny_governor_rchi_awards_release.html` |
| IA | PARTIAL | "fully obligated" (HHS 10-09) recorded; obligation is not award; HHT notices delayed | `recheck/2026-11-02/IA/` |
| LA | PARTIAL | "All RHTP Budget Year 1 award notifications have been completed as of October 30, 2026" — private, no roster, contracts in November | `recheck/2026-11-02/LA/` |

The New York and Vermont test is the same: full obligation stated on a state source → COMPLETE.

## 5. Held items (owner)

1. **MO contingent awards (10-30), $39,400,820.55, 25 rows; 14 hospital rows $31,862,169.80** — over $25M and
   a new condition: "All contingent awards have to be approved by the Centers for Medicare and Medicaid
   Services before a final award can be made" (2 of 25 marked approved). Release says 26 providers, roster lists
   25. Archived `recheck/2026-11-02/MO/`. Ruling needed: code as intents (CA precedent) or a new flag.
2. **UT UHA capital line, $38,300,000** — called NOT_HOSPITAL (hospitals among others: "rural hospitals,
   clinics, and other eligible providers", NH FHC precedent). If ruled HOSPITAL: +$38.3M.
3. **SD 27RHT00055 Avera McKennan Cancer Inst, $1,163,000** — bridged LOW to Avera McKennan (430016) as a unit
   named with its enrolled entity; confirm (WVU Eye is the contrary precedent).
4. **PA University of Pennsylvania, $1,097,821.56** — kept a university (session 110 ruling a); CMS enrols
   Trustees of the University of Pennsylvania as HUP (390111).
5. **UT Moab Valley Healthcare $1,962,200** — exact legal name of CAH 461302's operator, but the line's contact
   is the free clinic.
6. **MI Upper Peninsula Health Care Solution $1,050,000** and MHA (unsuffixed) $1,000,000 — called HOSPITAL on
   the association/network judgment.

## 6. Unextracted leads (read, not extracted)

- KY Executed Contract Tracker (~216 BP1 lines, $129.1M; names no hospital) — `recheck/2026-11-02/KY/`.
- OK unpriced /rhtp/ rosters (CHW Expansion, Rural Residency, School-Based); EMS Centralization's misprinted
  "$3,790.000.00" (Pulsara).
- FL: CMS 10-23 "$193.7 million … to 45 organizations" vs AHCA "Nearly $188 million" and our 81 / $188.2M —
  unreconciled.
- NE Governor 10-29 "awarded more than $177 million" (our files ~$41.7M) names nobody.
- MI "Year 1 Annual Report" linked from the programme page — unread.
- CMS Year 2: no FY2027 amounts announced as of 14:35Z (UT page: "CMS has moved the award announcements for
  Year 2 awards to October 30, 2026"; OR expected its amount "by November 1, 2026").

## 7. Sweep coverage

All 50 states swept. Unreadable (UNKNOWN, not negative): MA (mass.gov 403), RI (EOHHS/RIDOH/Governor 403),
KS (KDHE and Governor 403), MS DOM procurement (SSL chain), NH state hosts (403; FHC/CDFA read), IN Governor
newsroom (JavaScript). Nothing new since 10-23: AL AZ CT DE GA HI IL MD ME MN MT NC NJ NM NV OH OR SC TN VA
WI AR MS ND NH.

## 8. New rows on the review list (`summary_calls_for_review.csv`)

Written judgments added this session (R/07 `SC_JUDGMENTS`): TX GHC Hemphill (HOSPITAL); MI Michigan Health and
Hospital Association (HOSPITAL), Upper Peninsula Health Care Solution (HOSPITAL), Drummond Island Medical Center
(NOT); UT UHA capital row 36 (NOT), UHIN (NOT), 73 Rural Clinical Preceptors (NOT), UPAP/Switchpoint (NOT);
OK two SSM affiliate lines (HOSPITAL). Those over $1M, or strict-Unclear, appear on the review list.
