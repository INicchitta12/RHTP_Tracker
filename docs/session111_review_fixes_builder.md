# Session 111 — owner review of summary calls, fixes, the deliverable builder (2026-10-29)

**Result.** The best estimate of Year 1 RHTP dollars reaching hospitals is
**$2,005,223,415.77** (48.1% of $4.17B in published awards; 20.1% of the
$10B allotment). That is **−$97,338,394** against the 10-28 dry run, and every
dollar of the change is one of the owner's rulings below. The strict partition
is **NAMED_HOSPITAL 1,835 / $1,731,421,723.08 / 36 states** (+$2,177,185.38),
POOL_NAMED 8 / $86,555,171.43 and POOL_UNNAMED 5 / $69,323,109.17 (both
unchanged). The three strict buckets are never added to one another.

`R/08_year1_summary.R --build` now writes
`data/reference/year1_summary_2026-10-29.csv` and
`output/year1_summary_2026-10-29.xlsx` (Summary, Definitions, Notes and
caveats, Sources). The totals are pinned in `tests/testthat/test_08_year1_summary.R`.

## 1. Strict partition and best estimate

| Measure | 10-28 dry run | 10-29 | Change | Why |
|---|---:|---:|---:|---|
| Strict NAMED_HOSPITAL | $1,729,244,537.70 (1,835) | $1,731,421,723.08 (1,835) | +$2,177,185.38 | TX Burleson in (+$2,527,185.38, ruling e); AK Ketchikan out (−$350,000, ruling f) |
| Strict POOL_NAMED | $86,555,171.43 | $86,555,171.43 | 0 | |
| Strict POOL_UNNAMED | $69,323,109.17 | $69,323,109.17 | 0 | |
| Award total (published) | $4,171,467,402.31 | $4,171,734,402.31 | +$267,000 | WY's two "No bidders" 4.2 lines are pool-level money (see 2(i)) |
| Hospital, CODED | $1,778,001,785.52 | $1,780,528,970.90 | +$2,527,185.38 | Burleson moves from BEST_JUDGMENT to CODED |
| Hospital, BEST_JUDGMENT | $324,560,024.25 | $224,694,444.87 | −$99,865,579.38 | below |
| — rows | $240,725,024.25 | $168,359,444.87 | −$72,365,579.38 | NH FHC −$66,547,394; MS Delta −$3,291,000; Burleson −$2,527,185.38 (now CODED) |
| — pools | $83,835,000 | $38,835,000 | −$45,000,000 | OH −$61,700,000; IN Region 5 +$16,700,000 |
| — components | — | $17,500,000 | +$17,500,000 | NH FHC's CAH and Acute Care Hospital RFA |
| **Hospital, best estimate** | **$2,102,561,809.77** | **$2,005,223,415.77** | **−$97,338,394.00** | |
| Share of awards / of allotment | 50.4% / 21.0% | 48.1% / 20.1% | | |

The identity in `test_08` holds to the cent: best estimate = NAMED + POOL_NAMED
+ POOL_UNNAMED + best-judgment HOSPITAL on strict non-Yes rows + HOSPITAL
pools + HOSPITAL components − best-judgment NOT on strict-Yes rows. The last
term is now **$0**, because Ketchikan was the only strict-Yes row a judgment
called NOT, and it is strict No now.

Layers inside the best estimate (they overlap; never add them):

| Layer | $ |
|---|---:|
| Intents (not executed) | $737,578,902.24 |
| Association / network ruling | $171,816,601.60 |
| CMS obligation report ("obligated, per CMS") | $22,781,325.76 |
| Academic health centres | $65,107,273.31 |
| General knowledge (form) | $237,380,398.25 |
| LOW confidence | $430,533,135.95 |
| Strict rural cut / of which CAH by CCN | $549,250,719.56 / $397,130,545.99 |
| SOURCE_SUSPECT, excluded | $3,965,357.50 |

269 named hospital recipients carry no published amount, so the hospital share
is understated wherever that count is above zero.

## 2. Task 1 — the owner's review (through R/07; no hand edits)

**(a) NH Foundation for Healthy Communities, $66,547,394.** The award row is
now NOT_HOSPITAL. The separately priced component is HOSPITAL, through a new
mechanism (`SC_COMPONENTS` in R/07, `data/reference/summary_call_components.csv`).
The source, quoted: *"FHC anticipates awarding approximately $17.5 million
through this RFA."* (FHC CAH and Acute Care Hospital RFA, 2026-OCT-1,
`data/evidence/NH/rfa/2026-10-12_fhc_cah_acute_care_hospital_rfa_2026-10-01.pdf`).
NH's best estimate is **$17,500,000** (was $66,547,394). Three caveats, all
printed with the call:
- "approximately" is the RFA's own word;
- it is an anticipated award, due "Mid December 2026", so nothing in it is awarded yet;
- partner organisations may lead an application, so the RFA is not hospitals-only.

The component is never added to the award total, because the $66.5M row already carries it.

**(b) Pools called on their typed members.** `sc_pool_call()` now computes
every pool's call: HOSPITAL only on a strict majority of the named members
whose strict row is Yes. Nothing is typed by hand.

| Pool | $ | Named members | Typed hospitals | Call |
|---|---:|---:|---:|---|
| OH CINs and Innovation Hubs | $31,400,000 | 7 | 3 | NOT_HOSPITAL (was HOSPITAL) |
| OH Maternal Care | $30,300,000 | 6 | 2 | NOT_HOSPITAL (was HOSPITAL) |
| GA Connecting to Care (Phase 2) | $6,500,000 | 18 | 17 | HOSPITAL |
| GA Transforming (Phase 4) | $15,635,000 | 8 | 7 | HOSPITAL |
| GA Strengthening the Continuum (Phase 4) | $6,209,688 | 6 | 1 | NOT_HOSPITAL (unchanged) |

Ohio moves because its two networks (Ohio High Value Network, Ohio State
Health Network) are typed Unclear, so they do not count as hospitals. Session
110 counted them as hospitals under the standing network ruling. The two
networks' own rows carry no dollars and keep their HOSPITAL row calls.

**(c) MS Delta Health Transformation Council** (round 1 $3,000,000 and round 2
$291,000): NOT_HOSPITAL.

**(d) IN GROW Region 5 ($16,700,000; 8 of 16 typed hospitals).**
- **Indiana names no lead applicant.** Each Regional Coalition files one
  application. The region page, the Region 5 press release and the Letter of
  Intent all name none.
- **The tie is broken on a stated proxy.** The first Primary Subrecipient to
  sign Region 5's Letter of Intent is **Sullivan County Community Hospital**
  (CEO Michelle Franklin, confirmation 5/12/26). Its CEO is also Region 5's
  "Rural Hospital Staff" committee member. The call is HOSPITAL.
- **Source:** the Letter of Intent is archived at
  `data/evidence/recheck/2026-10-29/IN/grow_region_5_letter_of_intent.pdf`
  (SHA-256 in its MANIFEST).
- **Weakness:** this rests on signature order, not on a lead designation.
  Reversing it is −$16.7M (one row in `SC_POOL_TIEBREAKS`).

**(e) TX St. Joseph Health Burleson ($2,527,185.38)** is HOSPITAL and is now
in the strict file. It is typed on CMS TX enrolment as BURLESON ST JOSEPH
HEALTH CENTER OF CALDWELL TEXAS, dba CHI ST JOSEPH HEALTH BURLESON HOSPITAL
(CAH 451305, Caldwell, Burleson County). It is a hand-read bridge, LOW, and it
enters the rural cut.
- **Why the extractor missed it.** R/03ce's county test runs only on lines the
  NAME classifier already calls a hospital. "St. Joseph Health Burleson"
  carries no hospital word, so it fell to §8's standing fallback. The exact
  match failed because the enrolled DBA adds "CHI" and "Hospital".
- **The guard.** `tx_rts_assert_no_contained_miss()` now stops the build on
  any fallback line where every word of the name appears in the name or DBA of
  an enrolled hospital in the county HHSC prints for that line.
- **Re-run on all non-hospital TX lines.** Strict containment finds Burleson
  only. A looser screen (one shared distinctive word with a hospital in the
  same county) finds 29 more. All of them share only a town or county word
  (cities, a nursing home, dialysis, pharmacies, the CHRISTUS Trinity Clinic
  physician-group lines already ruled) except one possible operator miss.
- **For the owner:** *GHC Hemphill Operations, LLC* ($150,980.39, Hemphill
  County, the line HHSC re-attributed from Winnie Stowell). Hemphill County's
  only enrolled hospital is HEMPHILL COUNTY HOSPITAL (671301, a Rural Emergency
  Hospital). No document read says GHC operates it, so it is not bridged.

**(f) AK City of Ketchikan ($350,000).**
- The summary call is NOT_HOSPITAL, now CODED.
- In the strict file, `AK_KETCHIKAN_ALL_TYPES_TICKED` is RESOLVED at (b):
  LOCAL_GOVT_OR_PUBLIC_HEALTH / NON_HOSPITAL / No.
- It is applied by `AK_OWNER_RULINGS` in R/03h, keyed on App ID BP1-IA-100 at
  the end of `rhtp_ak_build()`, so every rebuild carries it.
- `R/03h --apply-rulings` patched the committed row (one line changed).
- AK NAMED_HOSPITAL is now 44 / $69,466,743.96.

**(g)** Every other call on `summary_calls_for_review.csv` stands as written.

**(h) Spot-check of the 25 largest default (name-screen) NOT_HOSPITAL rows.**
**No flips.** 390 rows / $188,924,764 use the default. The top 25 by hand:
- **AR:** Heartland Whole Health $8.42M (Walton-funded whole-health nonprofit).
- **CO:**
  - Porch Light Health (addiction treatment);
  - Carina Health Network (a health-centre network);
  - Colorado Whole Blood Coalition;
  - Denver Recovery Group;
  - Colorado Behavioral Healthcare Council (the CMHC association).
- **NV:** Nevada Medicaid x3 (state agency).
- **OK:**
  - CREOKS (CMHC);
  - Cancer Centers of Southwest Oklahoma;
  - Midwest Wellness and Wound Care.
- **VT:**
  - Vermont Foundation of Recovery;
  - Cathedral Square (senior housing);
  - Vermont Alliances for Recovery Residences;
  - Northeast Kingdom Human Services (a designated agency).
- **NE:** Lutheran Family Service.
- **OH:** Ohio Pharmacists Association.
- **CA:**
  - North Edge;
  - Healthy Rural California;
  - Health Alliance of Northern California (an FQHC consortium);
  - Reach Out West End.
- **ID:** Shine Dental; the Rural Respiratory Therapy Education Consortium.
- **WV:** Ascension Recovery Services (an addiction-treatment company, not
  Ascension Health).

Three are uncertain rather than clearly non-hospital. None is flipped, because
no record read shows hospital ownership:
- **Cancer Centers of Southwest Oklahoma** ($3.91M) may be a hospital joint
  venture.
- **Colorado Whole Blood Coalition** ($5.05M) supplies blood to hospitals and
  EMS, which is in-kind at most.
- **North Edge** ($2.0M) is unidentified.

**(i) R/03aw's Nevada double count is fixed in R/03aw** (`y1_file_figures()`):
- **The rule.** A round figure is no longer added when the priced rows of the
  same pool carry that same figure and already reach it.
- **Nevada:** 243.5M → $175,245,033.86, which is 97.4% of its $179,931,608
  allotment.
- **The test is stricter than session 110's `ys_pool_overlap()`**, which is
  removed. The old test dropped Wyoming's $267,000: two unpriced "No bidders"
  lines inside a 4.2 pool whose total ($3,218,160) is $2,951,160 priced plus
  those $267,000. They stay in, and that is the +$267,000 in the award total.
- **No other state moved** in `year1_completion_status.csv`, and no state's
  award total exceeds its allotment.

## 3. Task 2 — check-in and coverage

- **The 10-29 14:30Z check-in** (`trig_014ALqpHqrs3SYKQRvN7HFA4`) had not
  fired when this was written (CHECKIN_PLACEHOLDER).
- **Coverage from 10-26.** 29 Routine firings fell due and 28 left a line. The
  29th, CMS 10-26 13:00Z, is explained in `config/probe_gaps_explained.csv`.
  `probe_coverage.R --check` reads: 277 due since the logging fix, all logged
  except 7 explained misses.
- **Trips since 10-26 that nobody has read** (out of scope here; listed for
  the next session):
  - ND: "Suicide Intervention – Healthcare Systems Initiative" is headed
    Awarded (10-28).
  - NEWSROOM TX: "Governor Abbott Announces $8 Million In Rural Texas Strong
    Grants".
  - NEWSROOM DE: a physician-workforce release.
  - VA `ways_to_apply`: the session-110 re-base is not on `main` yet.
  - CA `updates` scope anchor; OH ODH lists; NH FHC key dates; menu trips on
    CO, WA, WI, CT, HI, KY and NM.
  - MS `dom_completed` SSL errors and a KDHE 403 (both our access).

## 4. Runners

RUNNERS_PLACEHOLDER

## 5. Task 3 — the deliverable builder

`R/08 --build` writes the CSV and the workbook from the same table:
- **Summary.** 50 states and a national row. Every requested column is there:
  - allotment, award total and share;
  - best estimate and its shares;
  - the three strict buckets (never summed);
  - CODED and BEST_JUDGMENT (split into rows, pools and components);
  - intents (hospital layer and all-recipient award intents);
  - the association ruling, the CMS obligation layer, AHC, general knowledge
    and LOW;
  - the strict rural cut and CAH-by-CCN;
  - named hospital recipients with no amount;
  - completion status;
  - the confidential-source flag.
- **Definitions.** One plain-language line per column. The builder refuses a
  column without one.
- **Notes and caveats.** Each of the owner's seven caveats, with today's
  figures, plus "layers overlap" and "no state is comparable without its
  rows".
- **Sources.** One row per state with its award files, source documents, URLs,
  archive paths, the status-table evidence and the evidence directory.

openxlsx 4.2.9 lists drawing parts it never writes, which strict readers
refuse. `ys_strip_dangling_rels()` removes those relationships after the save,
and a test checks it.

**Delaware's confidential source** is taken to be `DE Verify.xlsx` (the
owner-supplied verification file at the repository root, rows sourced "API
call" and "FDC qc"). It is the only Delaware material not published by the
state. Every column of every award row and status row is scanned for it.
- **Award rows citing it: none.** Delaware's award figures rest on DHSS and
  Governor releases.
- **Status rows citing it: five,** all in `de_year1_status.csv`: the diabetes
  pilot, Thomas Jefferson University, Delaware Health Force, the value-based
  care row and DHIN. None of them carries a figure.
- **How it is flagged.** Delaware's Summary row and Sources row are flagged
  and shaded, and the Notes sheet says flagged material must not leave the
  team.
- **If the owner means another source,** add it to `YS_CONFIDENTIAL_SOURCES`.

## 6. Methodological vulnerabilities

1. **The best estimate still adds the strict buckets.** Publish it beside the
   strict figures, never instead of them.
2. **NH's $17.5M is an RFA's anticipated awarding**, not an award. It is the
   weakest dollar figure in the best estimate per dollar.
3. **IN Region 5's $16.7M rests on Letter of Intent signature order.**
4. **The association/network layer is $171.8M**, chiefly ICAHN $50.0M, WSHA
   $42.0M, NRHP $24.4M, NHVN $18.2M and HARI $15.8M. A hostile reader will
   call it a waived pass-through rule. It subtracts in one column.
5. **Intents are $737.6M of the $2.0B.**

## 7. Monday 11-02

1. Run the sweep and re-apply each rebuilt file's overlays.
2. Run `R/07 --apply`, then `R/08 --build`.
3. Re-pin `test_08`, and point its "committed build" test at the new date.
4. A TX rebuild now stops on a contained-name miss. Read the line, then add a
   bridge or an override.
