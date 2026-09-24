# Session 61: New Jersey extracted, Indiana's regions read, seven Routines, the newsroom sweep

2026-09-24. **RCJ quota: 0 calls.**

## 1. New Jersey: `R/03bf_nj_year1_awardees.R` → `nj_year1_awardees.csv` (103 rows)

**Source.** *"Rural Health Transformation Program Funding Allocations – July 31, 2026"*
(`data/evidence/recheck/2026-09-24/NJ/njrht_funding_allocations_2026-07-31.pdf`, archived in
session 60). DOH's copy of the Governor's release links it as *"A summary of grant awards"*.

**Parse.** Line model, anchored on the Award Amount (South Carolina's lesson). It gives 103 rows
and **$83,060,837** in six sections (7 / 54 / 13 / 8 / 5 / 16).

- The PDF prints **no total and no CMS footer**. The words "Total", "Centers for Medicare",
  "financial assistance" and "CMS" occur zero times in it.
- The sum is corroborated from outside the arithmetic. The Governor's release says *"investing
  $83 million"* and *"will fund 103 projects"*.
- The parse agrees row for row with session 60's independent DERIVED parse.

**Typing is on CMS's own enrolment files, not on names.** The NJ Hospital and FQHC Enrollment
files are archived at `data/evidence/federal_records/2026-09-24/`.

- A recipient string that equals an ORGANIZATION NAME or DBA there is typed from that record at
  `ORG_WEBSITE`/`MEDIUM`. The match allows only these normalisations: case, punctuation, a
  leading "THE" and a trailing "INC".
- This covers 11 of the 12 hospital organisations.

| | Rows | $ |
|---|---:|---:|
| Named-hospital rows (all `DIRECT`, §0.3a) | **35** | **$35,275,076** (42.5%) |
| — on an exact CMS hospital record | 30 | $32,124,821 |
| — **Virtua Health Inc.**, hand-read bridge, `GENERAL_KNOWLEDGE`/LOW | 5 | $3,150,255 |
| FQHC (CMS FQHC file, or classifier on the state's string) | 10 | $4,680,331 |
| Unstated form, §8 fallback, queued, all `No` | 35 | $11,964,249 |

**Findings.**

- **AtlantiCare Health Services, Inc. is the FQHC, not the hospital.** CMS enrols it under three
  FQHC CCNs (311872, 311949, 311008). The hospital is AtlantiCare Regional Medical Center (CCN
  310064). This is Vermont's Gifford shape. Session 60's "~37 hospital rows" counted these two
  rows ($1,946,655); the federal record makes the count 35.
- **Virtua Health Inc.** has no CMS record under its own name. Its hospitals are enrolled under
  four subsidiaries, and every one is named VIRTUA. It is typed as a system at LOW and queued as
  `NJ_VIRTUA_PARENT_BRIDGE` so it can be subtracted.
- **Sites are not recipients (§0.3a corollary).** Building Rural Hospital Capacity prints the
  site in brackets at the head of the Activities cell: AHS [Hackettstown] and [Newton],
  AtlantiCare [City Campus] and [Mainland Campus], Inspira [Elmer], [Mannington] and
  [Vineland]. The site goes in `site`, and each row stays its own award action.
  - A single CCN is cited only where it is the facility, e.g. Hackettstown 310115 and Newton
    310028.
  - A multi-hospital corporation with no site cites its CCNs as a list, so the rural cut cannot
    read Morristown for Hackettstown.
- **NJHA's research affiliate** (Health Research and Educational Trust, $898,854) is
  `IN_KIND_BENEFIT`. Its funded activity is decision-support tools *"in rural hospitals"*: tools
  reach hospitals, dollars do not. This is Georgia's GHA precedent.
- **"Pre-hospital" is not a hospital.** The in-kind rule read Atlantic Ambulance's whole-blood
  programme as a hospital benefit. The token is stripped for the flow test only.
- **No NJ hospital row carries a rural designation.** No NJ awardee is enrolled as a CAH or REH.
  The rural cut records 23 rows as `FEDERAL_RECORD_CCN` (non-rural) and 12 as `NOT_RECORDED`.
- **Partial year.** DOH administers *"approximately $95 million in competitive grant funding"*
  and this is *"the first round"*.
  - `year1_completion_status.csv` reads NJ as `PARTIAL`.

**Other outputs.** The probe (`--probe`) watches the programme page, with a name diff and a trip
on any document link, and DOH's news archive, which trips on a new RHTP award headline. It ran
live: UNCHANGED.

**Totals moved.**

- `NAMED_HOSPITAL`: **1,035 / $902,386,742.75 / 25 → 1,070 / $937,661,818.75 / 26**.
- The pool buckets are unchanged.
- Survey split: **34/8/4/4 → 35/8/3/4**. NJ is the third state to leave `INVESTIGATED_NO_PROBE`
  because the state published a roster. Both tables were rebuilt from `R/03k`.

## 2. Indiana's GROW Regional Grants: all eight regions have awarded (read, NOT extracted)

**There are eight releases, not two.** They are all dated **2026-09-03** and all linked from
`in.gov/grow-rural-health/regional-grants/`. They are archived under
`data/evidence/recheck/2026-09-24/IN/` with a SOURCES.txt.

| Region | Release title | Awarded |
|---|---|---:|
| 1 | Northwest | $12.6M |
| 2 | Northeast | $20.7M |
| 3 | West-Central | $9.7M |
| 4 | East-Central | **$15.2M** |
| 5 | West-Central (sic; a second "West-Central") | $16.7M |
| 6 | Southeast | **$13.0M** |
| 7 | South-Central | $13.1M |
| 8 | Southwest | $11.4M |
| | **Sum of region figures** | **$112.4M** |

- The GROW page adds a **Surplus Award Summary of $16,249,593.22**: *"Regional Surplus:
  $8,724,000"* and *"Statewide Surplus: $7,525,593.22"*. The region figures plus the regional
  surplus come to $121.1M, against the release's *"About $120 million … earmarked for the
  regional grants"*.
- **The releases name no recipient.** Each one's only exact figure is the CMS footer,
  $206,927,896.80, which is the **allotment** (§0.2).
- **The GROW page names them.** It has one "Grant Recipient Organizations" table per region:
  **186 rows, 178 distinct names**, against *"nearly 200 subrecipients have been selected"*.
  **No per-organisation amount is published anywhere.** This is Iowa's and Nevada's shape at
  region grain. The parse is saved as `DERIVED_grow_regional_recipients.csv` and is not a
  state file.
- **About 30–40 recipients are hospitals or systems.**
  - The name rule reaches 31 of them. One of the 31, Cummins Behavioral Health Systems, is
    wrong: it is a community mental health centre.
  - The rule misses Franciscan Health Rensselaer, Parkview Huntington, Indiana University
    Health Inc (three regions), Union Health Inc., Ascension St. Vincent (Jennings, Vanderburgh)
    and St. Elizabeth Dearborn.
  - This is the largest named-hospital roster since Iowa. Extracting it needs the CMS IN
    enrolment files, which is Nevada's footing.
- **What extraction must respect.**
  - `amount` stays empty on every row. The region figure goes in `round_amount` and is never
    divided (§6.2).
  - The eligible class includes coalitions and pass-through-shaped regional structures. Any
    "Regional Grant Coordinator" or hub recipient is §7's pass-through question.
  - Region 3's release misspells the Governor ("Gov. Mike Braum"), and two regions are both
    called "West-Central". Both are recorded, not corrected.
- **Indiana has no Routine and no probe for this page.** The newsroom sweep does not cover
  Indiana, which has a CMS release. **Build `R/03s --probe` on this page next.**

## 3. Seven Routines, each on its own pushing runner (the TN pattern)

Registered in `config/routines.csv`:

| State | Trigger | Cron (UTC) | Script | Gate |
|---|---|---|---|---|
| DE | `trig_01RB9PBF3nqSifh14FHmdKCb` | Mon 11:40 | R/03al | on main |
| ID | `trig_013y1xkMRKbEs1uHGY2MaoJx` | Tue 12:40 | R/03am | on main |
| OH | `trig_011zGFcAQj1a7MAREdXE4aD2` | Wed 13:40 | R/03an | on main |
| SD | `trig_01KnvNUxLstaNqbvVWSshPcm` | Thu 12:20 | R/03i | on main |
| TX | `trig_014qMqhzF59uszwLjSJEC5qg` | Fri 13:20 | R/03n | on main |
| NJ | `trig_01UPrPJ31h2G3aLBc68QyB12` | Sat 12:10 | R/03bf | **needs this branch on main** |
| NEWSROOM | `trig_01PFM6vKqJWHtik1CcZ7ZemA` | Mon/Thu 16:50 | R/03bg | **needs this branch on main** |

**The newsroom sweep first fires today, 2026-09-24 at 16:50Z.** If this branch has not merged by
then, the Routine stops at its gate and writes nothing. `R/probe_coverage.R --check` will then
correctly name that firing as a gap.

## 4. The newsroom sweep: `R/03bg_newsroom_sweep.R`

The sweep covers the 18 no-release states. It reads **21 newsroom indexes across 14 states**,
each compared with a committed baseline under `data/evidence/newsroom_sweep/`.

**The tripwire.** It fires on a **new** headline, one absent from the baseline, that pairs RHTP
language with award language.

- RHTP language is "Rural Health Transformation", RHT(P), NJRHT, Healthy Hometowns, Rural Texas
  Strong, GO-NORTH, or "rural health grant/fund/award".
- Newsroom churn never trips it, because only new headlines are read.
- **Positive control:** New Jersey's own *"ICYMI: New Jersey Awards First Round of Rural Health
  Transformation Grants"* fires when it is removed from the baseline. Tennessee's headline
  matches too.

**Four states are recorded as UNREADABLE and re-tested on every run:**

- MA: mass.gov returns 403.
- MD: governor.maryland.gov and health.maryland.gov both return 403 today.
- NH: nh.gov returns 403.
- IL: the Governor's press host is refused at CONNECT by this environment's proxy.

A 200 from any of them fails the run, because an unwatched readable newsroom is the gap this
file closes.

**Other properties.**

- Each state runs inside its own `rhtp_probe_run()`, so one state's ERROR does not stop the
  others. Lines are logged as state `NEWSROOM`, page `<ST>:<key>`.
- It is exempt from §2.3's name tripwire, and `test_utils_name_tripwire.R` records why: every
  page it reads is a press index.
- It ran live: 14 states, no tripwire, no access error.

**It is a net, not a watch.** It sees headlines, not rosters. New Jersey's programme page still
links nothing, and this sweep would have caught New Jersey on day one only through DOH's news
item.

## 5. Not done, deliberately: Stage 2 on the 09-24 pull

`R/02c` (the wrong-state sweep) reads `stage2_record_table.rds`. That means it can measure the
09-24 pull only **after** Stage 2 has normalised it.

A Stage 2 re-run rebuilds the record table from which about twenty `*_rcj_candidate_disposition`
builders re-derive their counts, and they are designed to fail when those counts move. That is
the session-sized job session 60 described. **Order for that session:**

1. Run `R/02_normalize.R --run --date=2026-09-24`.
2. Immediately run `R/02c --build`, before anything reads the table. Wallowa Memorial is the
   first Tier 3 mode-6 case.
3. Re-read each disposition that fails, one at a time.
