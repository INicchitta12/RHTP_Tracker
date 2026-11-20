# Session 121 (2026-11-20): Wisconsin, South Dakota, the Year 1 date rule, Northeastern, the footer rule, Friday checks

**Branch:** `claude/optimistic-babbage-73xt1n`, from `main` at `05c5d69` (session 120 merged as #130). Three
parallel worktree agents did Wisconsin (Task 2), the VT/LA/ND housekeeping (Task 5) and the probe-log reads
(Task 7); each branch was merged here. Wisconsin's own write-up: `docs/session121_wi_extraction.md`.

## Report first

### Hospital figures, before (session 120's 11-19 build) and after (`year1_summary_2026-11-20`)

| Figure | Before (11-19) | After (11-20) | Change |
|---|---:|---:|---:|
| Awards published (national) | $6,332,705,161.06 | $6,527,744,046.56 | +$195,038,885.50 |
| Hospital best estimate | $2,535,780,971.39 | $2,604,660,516.91 | +$68,879,545.52 |
| Strict NAMED_HOSPITAL | 2,285 / $2,223,153,907.38 / 42 | 2,369 / $2,292,033,452.90 / 43 | +84 rows / +$68,879,545.52 |
| POOL_NAMED / POOL_UNNAMED | $96,565,779.43 / $79,214,848.17 | unchanged | — |
| Hospital % of awards (national) | 40.0% | 39.9% | |
| ≥50% subset row | n = 34; awards $5,419,098,005.52; best $2,304,419,031.43; 42.5% / 33.9% | n = 36 (+WI, +WV); awards $5,680,840,339.91; best $2,390,507,803.43; 42.1% / 33.2% | +$86,088,772 best |
| Rural cut (strict) | $702,766,673.78 | $735,967,275.17 | +$33,200,601.39 |

**By state (hospital best estimate = strict here; every move is a CODED row):**
- **WI** +$149,331,290 awards, **+$32,216,238 hospital** (39 rows). DHS's six award tables, extracted as INTENTS
  (owner ruling). LOW 13 / $9,167,667, of which 9 rows / $6,424,244 are health-system parents typed on general
  knowledge. State agencies 5 / $21,083,727, non-hospital.
- **SD** +$309,230 awards (the register's contracts sit inside SD's announced round pools, which were already in the
  award total), **+$25,994,573 hospital** (16 rows), Monument Health $12,915,000 among them (owner ruling).
- **WV** +$41,526,741 awards, **+$9,945,786 hospital**. The state's Year 1 Released Awards roster (67 awards,
  $108,261,312.68; latest list governs) and the 11-16/11-19 releases (WVU Hospitals $3,000,000, CCN 510001; the WVU
  system parent $4,526,918, LOW/GENERAL_KNOWLEDGE).
- **ND** +$1,157,470 awards, +$524,116 hospital: nine FSRS filings (11-20 archive), five CAHs on exact CMS enrolment.
- **TN** +$2,664,155 awards, +$148,832 hospital: 45 HART filings now Year 1 (date rule); Macon Hospital $72,727.27
  and Cookeville Regional Medical Center Foundation $76,105.13.
- **OK** +$50,000 awards and hospital: Mercy Hospital Oklahoma Communities (Johnston) re-priced $50,000 → $100,000.
- **IN** $0: Meds-to-Beds 20 hospital rows and GROW's Parkview Goshen are named at $0 (rows, not dollars).

### Verified vendor figures (`verified_vendor_list_2026-11-20.xlsx`)

| Amount type | Before | After |
|---|---:|---:|
| award | 25 cases / $219,275,291.11 on the list | 26 / **$251,281,669.26** (+$32,006,378.15, Northeastern) |
| intent | $48,233,747.84 | unchanged |
| contract maximum | $25,965,898.00 | unchanged |
| obligation | $30,181,665.63 | unchanged |
| administers | $128,979,618.21 (NM Accenture, never added) | unchanged |

Verified cases 46 → 47. The live URL check was re-run (`VV_AS_OF` 2026-11-20). Session 120's award figure of
$167,506,827.60 is the vendor-dollar total after the pass-through tab is split off; the +$32,006,378.15 lands on the
same award line.

### The Year 1 date-rule moves (Task 1a)

Owner ruling: a state source dated on or before 2026-10-30 decides Year 1; the FSRS action date decides only where no
state source gives a date. `config/year1_state_source_dates.csv`, enforced in `R/09b` (`fsrs_state_dates()`), pinned
in `test_09b_year1_state_dates.R`, written into CLAUDE.md §7. 84 FSRS filings had been held as Year 2.

| State | Moved | Source | Where the money lands |
|---|---:|---|---|
| TN | 45 HART | TDH 2026-09-03 release "initial recipients ... awards to 53 innovative projects" + the HART workbook (29 exact names, 16 hand-read crosswalk entries, county checked) | prices 43 HART roster rows held at $0 |
| SD | 22 | 19 on SD's completion statement (owner ruling, below), 3 on register begin dates (07-01 x2, 08-20) | paired to their register rows by contract number; no new row |

Still held (17): **NM** four Healthy Horizons hubs (HCA "selected"; a selection is not an execution or start);
**IL** Morris Hospital (no state date); **TN** 12 (the End Zone round, VUMC teleconsultation, fetal/infant, and
Parsons-Decatur County Higher Education Foundation, which matches no HART roster entity).

### South Dakota (Task 1b)

- Register 11-19 (+58) and 11-20 (+1, Watertown School District CHW/CHR training, $43,200, ADMIN): **122 contracts /
  $90,790,630**; hospital 40 / $52,943,667.
- Pools: Rural Strong 19, UNPLACED 72 (never on top of the $90M round), **CCBHC 10 (new pool, inside R/03bw's
  2026-09-24 round; R/03aw nets them out of that round)**, ADMIN 21.
- **Monument Health 27RHT00112, $12,915,000.** The first pass HELD it, as the owner's instruction required: the
  detail page has no contract image and no execution date. The 02-20 begin date predates the round's 08-19 award, the
  contract carries an FY27 number, it was first posted after 11-02, and its FFATA date is 11-02. **Owner ruling, same
  day: Year 1 on SD's own completion statement** (Governor/DOH KB0047476, 2026-11-10): *"In Year One, South Dakota
  committed every dollar of its $189.5 million Rural Health Transformation award by the federal deadline, through 234
  agreements ..."*. Released, typed on its 10-12 contract's hand bridge (CCN 430077, LOW) and paired to its FSRS
  filing. The basis sentence is on all 34 contracts first seen 11-19 with a 02-20 begin date, and the FSRS side
  carries a new date kind, `OBLIGATED_BY_DEADLINE`. The allotment cap is kept: SD's priced rows are far under it.
- Read and recorded: the register re-spelt 27RHT00008's vendor (`ACTIVE GENERATION` → `...GENERATIONS`; the prior
  string is carried) and moved Huron 27RHT00092's begin date 06-01 → 02-01. A register begin date is an editable field.

### Wisconsin (Task 2)

138 rows / $149,331,289.71 as INTENTS (`R/03cx`, `wi_year1_awardees.csv`). The five competitive tables match DHS's
printed figures exactly ($69,957,931 = "$69.9 million"). The implementation partners sum to $79,373,358.71 against
DHS's prose $79,373,358.70; the one-cent gap is recorded, not adjusted. Hospital 39 / $32,216,238. State agencies
DATCP, DPI, WDVA, DWD and OCI are STATE_AGENCY. The UW and WTCS systems are universities. Every row carries a summary
call and a spend category. The WI probe now watches the four award tables; live UNCHANGED. Judgment calls are in
`docs/session121_wi_extraction.md` (Ascension Wisconsin as a parent; Fond du Lac County on its psychiatric-hospital
enrolment, the Murray County precedent; Wood County not bridged).

### Northeastern University (Task 3)

**ADMINISTRATOR (case VV071, ADMINISTERS_PROGRAM), $32,006,378.15, not out of state.** FSRS COM-27-0811 purpose text:
*"Northeastern University's Roux Institute ... and the State of Maine Department of Health and Human Services will
partner in planning and implementing the State of Maine's Rural Health Transformation Program (RHTP). Specifically,
the Provider will assist the Department with Initiative 5 of the RHTP: 'Sustainable Rural Health Ecosystems.'"*
- V1–V8 pass. V9 is the owner's ruling (Portland campus; the Jefferson precedent): HD80 now drops only the
  OUT_OF_STATE_VENDOR category.
- An independent check (a separate agent) returned KEEP. Its doubt is recorded: "assist the Department with
  Initiative 5" alone reads advisory (CONSULTANT); no source shows a pass-through share. Owner ruling: stays
  ADMINISTRATOR.

### The footer rule (Task 4)

`rhtp_footer_check()` / `rhtp_assert_footer_check()` (`R/utils_config.R`): the printed figures are compared against
FY2026, FY2027 and their sum, and the verdict is taken on the CMS share. A share matching none is REFUSED. A partial
percentage with no printed CMS dollars is REFUSED and never multiplied. The margin is unchanged ($10,000). Readings go
in `config/footer_refusals_read.csv` (REFUSED_READ, still never a source).
- **Mississippi fixture:** the headline $410,584,410.13 = FY2026 + FY2027 to $0.13; the printed CMS share
  $410,420,176.37 matches none → REFUSED, read and recorded. The MS probe no longer trips on it.
- The CA, LA and MN "+$100M initial award" footers match none of the three and are recorded as read.
- CA's probe accepts FY2026 + FY2027. ND, CT and AR footers now print FY2026 + FY2027 and pass.
- Tests: `test_utils_footer_rule.R`; CA fixtures updated.

## Task 5: housekeeping (merged from its worktree)

- **VT:** the only change is the excluded DVHA MOU ($402,500); the 240 agreements / $179,117,448 are unchanged. The
  probe is re-based to the 11-12 list, with a validation that stops if that list's agreements ever differ from the
  build list's. Live UNCHANGED.
- **LA:** the parser is rewritten for LDH's three stage sentences (Year 1 award notifications completed as of 10-30;
  contract execution November 2026; Year 2 announcements January 2027). Any change or named recipient trips. Live
  UNCHANGED on all four pages.
- **ND:** Suicide Intervention (5), Childcare (8) and NEMT (13) are recorded "Awarded, nobody named" in
  `ND_AWARDED_ROUNDS` (no amount column). The name tripwire stays on (a test proves a named recipient trips). Live
  UNCHANGED.

## Task 6: Friday checks and Routines

- **Runners above 650k:** IN 777,221 and ID 693,502, moved to new runners. IN is
  `trig_01Rk8bnWZfCRJnU4bCM7UKXu` / `session_01Y1P5eTc6z51DbYZRra6fmz`; ID is `trig_01KmQzvRYiidaCiro8AcacXg` /
  `session_01Y1P5eR5GXc1nta4hcD1tvV`. Same crons; the old ids are disabled and chained; v4 prompts regenerated
  (`--check` passes).
- **600k–650k:** VT 633,766, OK 629,002, VA 628,882, DE 624,338, CT 620,947, KS 613,912, NC 600,412.
- MT / SC / LA old-Routine deletions, the 19:40Z CMS/MN/MO/NEWSROOM check and the 20:23Z rhtptracker.com LEAD run:
  see the addendum at the end (written after each ran, or a scheduled check-in where it had not).

## Task 7: probe log since session 120 (11-19 13:27Z → 11-20 16:21Z, 151 lines) and FSRS

**Moves a dollar:** WV (Year 1 roster, +$9.95M hospital), SD and WI (above), ND FSRS (+$524k), OK (+$50k), TN (date
rule). **Year 2, held:** WV $202M, IA $216M, NV BP2 NOFOs, DE $160.3M / ID $183M / TX $281M newsroom headlines,
OK's BP2 fragment index (logs YEAR2).

| State | Verdict | Read |
|---|---|---|
| WV | TRIPWIRE x6 | The Year 1 Released Awards roster (67, $108,261,312.68) was extracted, and the 11-16/11-19 releases too. The $202M release is Year 2. The Greenbrier L&D release names no recipient. The Office of Economic Development's $3M is state money. Probe re-based. |
| IN | TRIPWIRE x5 | GROW 186→171 printed rows. Applied on the session 119 FSRS rule: three kept, three dropped, Parkview Goshen added. Meds-to-Beds 20 hospitals at $0 (`R/03cz`, names model-read from an image, CONFIRM). The IDOA MOCC letter is contract maxima, a recommendation: read only. |
| IA | TRIPWIRE x5, YEAR2 | Four non-RHTP notices. The 11-16 Council names no recipient. $216M Year 2. Re-based. |
| OK | ERROR x30 | Our access: the fragment index moved (BP1/BP2 dropdowns). Re-pointed. Mercy Johnston re-priced. |
| NEWSROOM | TRIPWIRE x2 | TX $87M/$8M/$78M and DE physician workforce: already read (sessions 112, 102). Re-based; live 22 UNCHANGED. |
| CT, AL, KY | TRIPWIRE/CHANGED | Menus, kickoff recordings, AmeriCorps RFA, footer FY2026+FY2027. Re-based. |
| AR, ME, NV | CHANGED/TRIPWIRE | Footer runs and Tier 2 / BP2 titles went to furniture (AR's and ME's archives are extraction sources, so no re-base). |
| MS | TRIPWIRE | The footer (Task 4). Fixed by the rule. `dom_completed` SSL is our access. |
| WI, SD | TRIPWIRE/CHANGED | Extracted (Tasks 1b, 2). |
| NM | TRIPWIRE | **Left tripping on purpose.** HCA migrated its site: the RHT URL redirects to pre-procurement text without the six stages or the ASO line, and `/news/` is 404. Re-pointing would silently disable the Accenture/ASO watch, so the probe needs a rewrite. The migrated pages are archived under `recheck/2026-11-20/NM`. |
| VA | CHANGED | **Unread (our access):** `ruralhealthtransformationva.virginia.gov` began failing TLS at about 17:25Z. |

**FSRS:** the 11-20 USAspending pull (+56 filings) is archived under `data/raw/usaspending/2026-11-20/`.
- **AK:** 38 pair exactly, 1 differs, 4 held as unreviewed candidates, 1 held same-amount-on-roster.
- **ID:** 1 pairs exactly.
- **ND:** 9 new rows (5 CAHs). An independent duplicate check (a separate agent) found no duplicates and confirmed
  every hospital typing on exact legal name and street address.
- **OR:** 2 held (a state pool may contain them).
- No new post-10-30 filing.
- **VENDOR lines (11-20, read):** AK Providence Health & Services–Washington x2 ($772,500; $1,086,793) and Mat-Su
  Valley Medical Center LLC ($5,000,000). Each is a hospital operator with an out-of-state registered address; all
  pair to AK roster rows.

## Task 8: rebuild

R/09b --apply → R/09c --build/--live → R/07 --apply → R/03aw --build → R/03ar --build (re-stated to 2,369 /
$2,292,033,452.90 / 43) → R/08 --build → R/09c --xlsx → R/08b --build 2026-11-20. Outputs:
- `output/year1_summary_2026-11-20.xlsx`
- `output/verified_vendor_list_2026-11-20.xlsx`
- `output/completed_states_2026-11-20.{xlsx,html}`

Fixes found in the rebuild:
- 13 SD pairings re-keyed to the post-Monument row numbers.
- VV071's independent check moved to the round-1 file.
- VV054 (Unite USA) reaches WV's "Unite Us" roster row through a hand alias in the spend layer.

## Calls made under the standing rules (each reversible)

1. TN HART hand crosswalk (16 entries, county checked); Parsons-Decatur Foundation not mapped to "City of Parsons".
2. NM hubs and IL Morris kept as Year 2 (no executed or started date).
3. SD CCBHC as a new pool inside R/03bw's round (each detail page names the programme).
4. SD doula workforce (GPTLHB) and Watertown SD CHW/CHR training as ADMIN (the session 64 doula precedent).
5. Avera McKennan Hospital and Bennett County Hospital not bridged (Huron's precedent); Winner, Vermillion, Marshall
   County and Monument bridged LOW.
6. The ALLOTMENT_PLUS_YEAR2_INITIAL class is kept in `rhtp_footer_class()` for archived documents; the new rule
   refuses those footers and records them as read.
7. WV and OK: latest list governs. Indiana Meds-to-Beds names read from an image (CONFIRM).
8. NM probe left tripping rather than re-pointed onto a page that has lost its watch lines.

## Open for the owner

- **NM:** HCA's site migration; the probe needs a rewrite before the ASO announcement (due 11-30) can be seen.
- **Indiana Meds-to-Beds:** confirm the 20 names against a text source when IDOH publishes one.
- **WV:** the existing CAMC $612k FSRS filing DIFFERS-pairs onto rows 31–33 rather than row 2 (pre-existing).
- **WI:** Fond du Lac County on its psychiatric-hospital enrolment ($118,914; Ketchikan is the counter-reading).
