# Session 110 — summary calls on every award row (2026-10-28)

**Purpose.** The Year 1 summary table (due Mon 2026-11-02) may carry no unknown
or unclear hospital status. Every award row now has a two-valued call. The
strict coding is unchanged apart from the three Task 1 rulings.

## 1. Owner review list (lead item)

`data/reference/summary_calls_for_review.csv` holds 148 records, sorted by
dollars. Each record carries the state, the recipient, the amount, the strict
status, the call, the rationale, the strongest counter-argument and a
`listed_because` column:

- **102 `OVER_1M`**: every BEST_JUDGMENT call over $1,000,000 (88 award rows
  and 14 shared pools). 26 are called HOSPITAL ($319,264,556) and 76 are called
  NOT_HOSPITAL ($333,825,536).
- **43 `STRICT_UNCLEAR`**: the remaining strict-Unclear rows under $1M or with
  no amount, so every Unclear system and university string is on the list.
- **3 `OWNER_NAMED`**: AK Ketchikan ($350,000), CA FM/OB Fresno ($289,039) and
  LA's 48 unnamed RCCB awards (no amount on the row).

The calls that move the most money into the hospital figure. Each one is a
judgment the strict file does not make:

| State | Recipient | Amount | Strict | Call | Strongest counter |
|---|---|---:|---|---|---|
| NH | Foundation for Healthy Communities (NHHA's foundation) | $66,547,394 | Unclear | HOSPITAL | The eligible class includes primary care, EMS, behavioral and oral health and CBOs (§0.3). The CAH RFA is about $17.5M of the total. No subrecipient is named. |
| WA | Washington State Hospital Association | $42,000,000 | Unclear | HOSPITAL | HCA's deck does not say the money is paid to hospitals rather than spent by WSHA on their behalf. |
| OH | CIN/Hub shared pool (7 named members; 5 are hospitals or hospital networks) | $31,400,000 | no bucket | HOSPITAL | OACHC and the Child & Family Health Collaborative are members, and no split is published. |
| OH | Maternal-care shared pool (6 named members; 4 are hospitals or networks) | $30,300,000 | no bucket | HOSPITAL | CMS: "hospital networks and health centers"; OACHC and OHI are members. |
| OH | ODH's 22 named hospitals | $30,300,000 | Yes (POOL_NAMED) | HOSPITAL | No split; the figure is rounded. |
| NV | Nevada Rural Hospital Partners Foundation | $20,278,054 | Yes (POOL_NAMED) | HOSPITAL | No split; some lines buy services. |
| NE | Nebraska High Value Network | $18,156,856 | Yes (POOL_NAMED) | HOSPITAL | No split; the network may keep some for administration. |
| GA | Transforming pool (7 hospitals + AHEAD assessments) | $15,635,000 | no bucket | HOSPITAL | The assessments inside it pay an assessor. |
| CT | Hartford HealthCare pair | $12,650,000 | Yes (POOL_NAMED) | HOSPITAL | No split. |
| MI | MHA (2 rows) | $8,625,000 | Unclear | HOSPITAL | MDHHS never says the money reaches member hospitals. |
| GA | Connecting to Care pool (17 hospitals + DBHDD) | $6,500,000 | no bucket | HOSPITAL | DBHDD's mobile dental award sits inside it. |
| SC | Acadia Healthcare Co. | $5,565,253 | Yes (queued) | HOSPITAL | Two outpatient centres are in its SC estate. |
| WA | The Rural Collaborative | $5,430,000 | No (in-kind) | HOSPITAL | HCA describes a service to 30 hospitals, not payments to them. |
| MS | Delta Health Transformation Council (2 rows) | $3,291,000 | No (form unknown) | HOSPITAL | No record establishes the affiliation with Delta Health System. |
| TX | St. Joseph Health Burleson | $2,527,185 | No (form unknown) | HOSPITAL | None of substance: CMS enrols it (CAH 451305). R/03ce missed the bridge, so it is a candidate for the strict file. |
| ID | Hospital Network of Idaho (3) + The Hospital Cooperative | $3,833,321 | Unclear | HOSPITAL | DHW's list says nothing about where the money goes (session 109 ruling b). |

The large NOT_HOSPITAL calls the owner may want to reverse:

| State | Recipient | Amount | Why it might be hospital money |
|---|---|---:|---|
| WY | Wyoming Innovation Partnership (2) | $38,618,260 | Individual workforce support may reach hospital employees. |
| IN | GROW regions 1–8 (pools; hospitals 3–9 of 14–32 members each) | $112,400,000 | Region 5 is a tie, 8 of 16. A tie is not a majority, so it is called NOT_HOSPITAL. |
| ID | Public Consulting Group (ladder-payment TPA) | $14,520,000 | If the ladder payments go to hospitals, PCG is a pass-through. |
| ME | University of New England | $12,000,000 | Hospitals may benefit in kind. |
| AR | Heartland Whole Health | $8,420,000 | The form is undetermined (default rule). |
| NV | Lyon County (MIH/CP) | $4,289,351 | The county owns South Lyon Medical Center. |
| NY | Care Compass, Chautauqua, Fort Drum, Southern Tier (RCHI leads) | $8,171,287 | RCHI required a hospital partner, and several of these networks may be made up of hospitals. |
| CO | West Custer County Hospital District; Eastern Plains Healthcare Consortium | $2,472,176 | One is a hospital district; the other may be a consortium of CAHs. |
| AK | City of Ketchikan (below $1M; the only strict-Yes row called NOT) | $350,000 | Alaska ticked "Hospital (all types)", and the City owns the facility. |

### Best-judgment hospital dollars by state

| State | BJ rows | BJ pools | BJ total | CODED | Summary hospital $ | Share of awards |
|---|---:|---:|---:|---:|---:|---:|
| NH | $66,547,394 | — | $66,547,394 | $0 | $66,547,394 | 100.0% |
| OH | $30,300,000 | $61,700,000 | $92,000,000 | $0 | $92,000,000 | 88.5% |
| WA | $47,430,000 | — | $47,430,000 | $9,740,000 | $57,170,000 | 66.1% |
| NV | $24,448,315 | — | $24,448,315 | $46,724,181 | $71,172,496 | 40.6% |
| GA | — | $22,135,000 | $22,135,000 | $90,277,580 | $112,412,580 | 57.0% |
| NE | $18,210,471 | — | $18,210,471 | $18,409,437 | $36,619,908 | 80.2% |
| CT | $12,650,000 | — | $12,650,000 | $33,350,000 | $46,000,000 | 92.0% |
| MI | $8,625,000 | — | $8,625,000 | $2,694,121 | $11,319,121 | 11.2% |
| SC | $5,565,253 | — | $5,565,253 | $110,420,462 | $115,985,715 | 69.3% |
| AR | $5,068,862 | — | $5,068,862 | $123,268,100 | $128,336,962 | 63.0% |
| AL | $3,913,694 | — | $3,913,694 | $100,521,165 | $104,434,859 | 52.6% |
| ID | $3,833,321 | — | $3,833,321 | $85,389,816 | $89,223,137 | 56.5% |
| MS | $3,291,000 | — | $3,291,000 | $91,885,201 | $95,176,201 | 69.6% |
| NJ | $3,150,255 | — | $3,150,255 | $32,124,821 | $35,275,076 | 42.5% |
| TX | $2,527,185 | — | $2,527,185 | $189,124,105 | $191,651,290 | 85.3% |
| VT | $2,517,797 | — | $2,517,797 | $72,995,996 | $75,513,793 | 42.5% |
| NY | $1,500,000 | — | $1,500,000 | $45,858,791 | $47,358,791 | 62.2% |
| VA | $1,000,000 | — | $1,000,000 | $11,031,000 | $12,031,000 | 52.2% |
| KS | $146,476 | — | $146,476 | $62,416,473 | $62,562,949 | 65.2% |
| **US** | **$240,725,024** | **$83,835,000** | **$324,560,024** | **$1,778,001,786** | **$2,102,561,810** | **50.4%** |

$106,771,032.78 of the BJ HOSPITAL row dollars were already strict-Yes. They
are shared awards (CT, NE, NV, OH and the VA pair) and queued Yes rows (Acadia,
Virtua, UAMS round 2, Greene County, SVH). The **net addition over the strict
partition is $217,438,991.47**: $133,953,991.47 on strict-No or strict-Unclear
rows, plus $83,835,000 in pools, minus Ketchikan's $350,000.

## 2. Task 1 rulings (strict files)

- **(a) Academic strings.** A string naming the health SYSTEM is
  `HOSPITAL_OR_SYSTEM`, `ACADEMIC_HEALTH_CENTER`, LOW, GENERAL_KNOWLEDGE, with
  no CCN on the row. Two rows changed: *UC San Diego Health* (CA, +$498,854;
  `R/03cl`) and *UVA Health* (VA VHCF Provider Productivity, +$62,000;
  `R/03ch`). School, campus, department and programme strings stay
  non-hospital and were not re-typed: SCRHC–UC San Diego ($6,213,882), UAB
  Montgomery, OHSU Casey Eye, the ORPRN and Oregon ECHO strings, the Oregon
  Perinatal Collaborative, Michigan's MEDIC, and the two UVA programmes
  ($884,000, `R/03bx`). `CA_UCSD_STRINGS_NO_ENROLLED_ENTITY` and
  `AHC_STRING_NAMES_NO_ENROLLED_ENTITY` are RESOLVED.
- **(b) Providence Medical Foundation** is `PHYSICIAN_PRACTICE`, NON_HOSPITAL,
  −$450,000. The rule is now in the §7/§10.2 foundation block of all three
  documents, kept byte-identical: a California medical foundation (HSC
  1206(l)) operates clinics, and the foundation row covers fundraising
  foundations only. `CA_PROVIDENCE_MEDICAL_FOUNDATION_FORM` is RESOLVED. The
  summary layer applies the same reasoning to Pacific Central Coast Health
  Centers and Avera at Home (both NOT_HOSPITAL).
- **(c) VA `ways_to_apply`.** Read live on 10-28. Exactly three RFA Status
  cells moved Open → Closed: Earn to Learn (Virginia Works), Career Pipelines
  (VDOE) and Food is Medicine (VHH Foundation). No partner was added and nobody
  was named. The page is re-based to `2026-10-28_rhtva_ways_to_apply.html`,
  and the live probe reads UNCHANGED.

**Strict partition (published):** NAMED_HOSPITAL 1,834 → **1,835 /
$1,729,244,537.70** / 36 states (+$110,854). POOL_NAMED 8 / $86,555,171.43
and POOL_UNNAMED 5 / $69,323,109.17 are unchanged. The internal figure,
including SOURCE_SUSPECT, is 1,838 / $1,733,209,895.20. The rural cut is
unchanged (UVA Health is a Part A hospital, not rural).

## 3. The summary-call layer (Task 2)

- `R/utils_summary_calls.R`: `rhtp_summary_calls()` is the one function that
  computes the columns, and `rhtp_assert_summary_calls()` enforces the
  invariants. The call is only HOSPITAL or NOT_HOSPITAL. BEST_JUDGMENT needs a
  rationale. A CODED call must equal the strict determination.
- `R/07_summary_calls.R --apply` writes `summary_hospital_call`,
  `summary_call_basis` and `summary_call_rationale` onto all **61** award
  files. Every other byte of each file is unchanged: all 61 files round-trip
  byte-identically, which was checked before writing.
- **Result: 3,866 CODED and 536 BEST_JUDGMENT rows.** The BEST_JUDGMENT rows
  split 54 HOSPITAL and 482 NOT_HOSPITAL. There are also 14 pool-level calls
  (`summary_call_pools.csv`).
- **What forces BEST_JUDGMENT:**
  - Unclear or missing `distributed_to_hospital`
  - `PASS_THROUGH_UNRESOLVED`
  - `NOT_YET_NAMED`
  - `RECIPIENT_TYPE_INFERRED`
  - a shared award (`MULTI_RECIPIENT_FIELD` or POOL_NAMED)
  - a row named by an OPEN queue question
- **Three kinds of judgment:**
  - **Written** (`SC_JUDGMENTS`): 121 entries, each with a counter, which
    cover 146 rows.
  - **Shared pools** (`SC_POOLS`): GA's 3 mixed pools, OH's 2 shared
    sub-pools, IN GROW's 8 regions and NC's SBHC pool. Each is called on its
    majority member and counted once and whole. Every member row must carry no
    amount.
  - **The default**: a form-unstated row coded No whose name carries no
    hospital marker and matches no CMS hospital enrolment in its state is
    called NOT_HOSPITAL (390 rows). A marker or an enrolment hit refuses the
    default.
- **Every OPEN queue question is accounted for.** 26 of the 31 are mapped and
  5 are exempt as not about hospital status (MO anchors, ME cohort, TX BP1 floor, CO
  roster total, SD CCBHC count). A new OPEN question fails `--validate`.
- **Excluded on purpose.**
  - South Dakota's $31.5M Rural Strong round is called HOSPITAL at $0, because
    its contracts are already priced rows.
  - LA's 48 unnamed RCCB awards, OR's tribal and LPHA aggregates, and MT's 75
    EMS awards carry calls at $0.
  - Iowa's RFP pools are Tier 2 and are never added.

## 4. Year 1 summary table (Task 4, dry run)

`R/08_year1_summary.R --build` writes `data/reference/year1_summary_2026-10-28.csv`:
one row per state and a national row. The totals are pinned in
`tests/testthat/test_08_year1_summary.R`.

National dry run:

| Measure | Value |
|---|---:|
| Allotment (FY2026) | $10,000,000,000 |
| Award total (priced $3,708,434,674.31 + pool-level $463,032,728) | $4,171,467,402.31 (41.7% of allotment) |
| Hospital, CODED | $1,778,001,785.52 |
| Hospital, BEST_JUDGMENT (rows $240,725,024.25 + pools $83,835,000) | $324,560,024.25 |
| **Hospital, summary** | **$2,102,561,809.77 — 50.4% of awards, 21.0% of allotment** |
| Strict NAMED / POOL_NAMED / POOL_UNNAMED | $1,729,244,537.70 / $86,555,171.43 / $69,323,109.17 |
| Layers inside the summary figure (overlapping; never add) | AHC $65.1M · GENERAL_KNOWLEDGE $303.9M · LOW $500.5M · intents $737.6M · CMS obligation $22.8M |
| SOURCE_SUSPECT, left out (session 102) | $3,965,357.50 |
| Completion | 4 COMPLETE of 50 (AL, AR, FL, GA) |

The test proves this identity:

> summary = NAMED + POOL_NAMED + POOL_UNNAMED + BJ-HOSPITAL on strict non-Yes rows + HOSPITAL pools − BJ-NOT on strict-Yes rows

**The denominator uses R/03aw's per-file rule over all 61 files.** R/03aw's
own list leaves out seven files: MS_R2, MD_LABOR, VA_VHCF, NE_CMS, PA_CMS, RI
and IN_GROW. R/08 adds Ohio's shared pools, which no file carries. It also
nets out one defect: **R/03aw counts Nevada's WRRAP and Flex round figures on
top of the BP1-priced lines in the same pools**, which puts NV at $243.5M
against a $179.9M allotment. R/08 subtracts a round figure when its pool's
priced rows already reach it (`ys_pool_overlap()`). Louisiana's 48-award
figure is kept, because its five priced rows are other money.
`year1_completion_status.csv` is unchanged. **Owner call:** fix R/03aw too?

## 5. Methodological vulnerabilities (read before using the figure)

1. **The summary figure adds the three strict buckets.** The strict rule never
   adds them, and `rhtp_hospital_total()` still refuses to. The summary
   figure is the owner's single-call view, built from a different column.
   Publish it beside the strict figures, never instead of them.
2. **The association calls are $108.5M of the $217.4M net addition:** NH FHC
   $66.5M and WSHA $42M (MHA adds $8.6M). They rest on the owner's standing
   ruling, not on any source sentence showing money reaching hospitals. FHC's
   own eligible class is mixed. A hostile reader will say the pass-through
   rule was waived. The answer is that these are BEST_JUDGMENT and subtract
   as one column.
3. **Ohio's $61.7M of shared pools are counted whole on a majority call.**
   Health centres share both pools. CMS's own release says "hospital networks
   and health centers".
4. **Intents are 35% of the summary figure** ($737.6M). TX, CA, AR, OR and AK
   are mostly intents.
5. **The default rule (390 rows) has only been checked against CMS
   hospital enrolment and a name marker.** A hospital-owned entity with a
   neutral name (a clinic company, an affiliate) would be missed. The counter
   on every default row says so.

## 6. Monday 11-02

1. Run the sweep. Re-apply each rebuilt file's overlays.
2. Run `Rscript R/07_summary_calls.R --apply`. If it stops on a row, write a
   judgment (`--missing` lists them all).
3. Run `Rscript R/08_year1_summary.R --build`, then re-pin `test_08` in the
   same commit.
4. Owner decisions, all optional:
   - the review list;
   - TX Burleson into the strict file;
   - fixing R/03aw's NV double count;
   - IN GROW Region 5's tie.
