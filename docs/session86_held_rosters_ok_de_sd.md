# Session 86 — the four held rosters (OK RRR, OK CDM, DE FQHCs, SD), and the stale figures behind them

2026-10-02. Owner tasks:
1. Extract the four rosters session 85 held over the $10M report-first line.
2. Run the full suite and report clean.

## 1. Hospital dollar effect, per state

| State | Before | After | Change |
|---|---:|---:|---:|
| OK (all four files) | 28 / $1,392,027.66 | 44 / $31,689,488.81 | **+16 / +$30,297,461.15** |
| SD contracts | 5 / $716,800 | 12 / $9,636,252 | **+7 / +$8,919,452** |
| DE (both files) | 4 / $0 | 4 / $0 | **0** (the three FQHCs are not hospitals) |
| **NAMED_HOSPITAL, national** | 1,265 / $1,151,146,602.27 | 1,288 / $1,190,363,515.42 | +23 / +$39,216,913.15 |

The pool buckets did not move. The state count is still 31, because OK and SD were already in it.

## 2. Oklahoma RRR and CDM (`R/03bt`)

Each roster has its own file: `ok_year1_rrr_awardees.csv` and `ok_year1_cdm_awardees.csv`. Every row is hand-typed
in `OKN_RRR_CDM_TYPING` against two archived CMS files: OK Hospital Enrollments (2026-09-25) and OK FQHC
Enrollments (fetched this session to `federal_records/2026-10-02/`). Nothing is left to the name rule.

**RRR: 20 rows, $39,578,523. 10 hospital rows, $21,099,804.**
- Exact legal name (MEDIUM): Jackson County Memorial Hospital Authority, McCurtain Memorial Medical Management,
  Memorial Hospital of Texas County Authority, Newman Memorial Hospital, SSM Health Care of Oklahoma and Stillwater
  Medical Center Authority.
- LOW, as the owner instructed (4 rows, $8,272,013):
  - Ascension St. John Jane Phillips is a trading name of JANE PHILLIPS MEMORIAL MEDICAL CENTER INC, CCN 370018.
  - Fairview is the DBA of FAIRVIEW REGIONAL MEDICAL CENTER AUTHORITY, CCN 371329.
  - Lindsay: the enrolled LINDSAY MUNICIPAL HOSPITAL is the awardee less "Authority". This is recorded as
    LEGAL_NAME_TRUNCATED, and the row says the bridge runs in reverse.
  - Mercy Health Oklahoma Communities has no enrolment at all, so it has no CCN.
- **SSM's enrolled hospitals are urban (St Anthony OKC / Midwest City).** The award text says "seven rural
  hospitals". That is R/03ar's rural cut to report; the row is not re-coded.
- Not hospitals:
  - South Central Medical and Resource Center is an FQHC (exact match on the FQHC file).
  - OPQIC is IN_KIND_BENEFIT: it trains 24 rural birthing hospitals, so the training reaches hospitals and the
    dollars do not.
  - Southwestern Oklahoma State University is NON_HOSPITAL. Its "robotic-assisted surgery at a local hospital"
    names no hospital. Queued as `OK_RRR_SWOSU_LOCAL_HOSPITAL`.

**CDM: 15 rows, $15,608,845.22. 6 hospital rows, $9,197,657.15.**
- **Choctaw Nation of Oklahoma ($360,552) is typed HOSPITAL_OR_SYSTEM, MEDIUM.** OSDH's entry states no form. CMS
  enrols CHOCTAW NATION OF OKLAHOMA as the hospital legal entity for CCN 370172. The session-72 precedence rule
  therefore lets the enrolment decide: the AltaPointe shape, not Alaska's. It is also queued
  (`OK_CDM_CHOCTAW_TRIBAL_HOSPITAL_ENROLMENT`), because a tribal government is a new shape for that rule.
- **Central Oklahoma Family Medical Center is an FQHC:** CENTRAL OKLAHOMA FAMILY MEDICAL CENTER INC, exact, at 16
  FQHC sites, with no hospital enrolment. The name rule calls it a hospital, and a test pins that counterfactual.
- LOW (3 rows, $5,108,475.41):
  - Cimarron: DBA + RHC of CIMARRON MEMORIAL HOSPITAL AND NURSING HOME, CCN 371307.
  - Fairview: DBA.
  - Mercy: no enrolment.
- Exact (MEDIUM): Jackson County and Wagoner Hospital Authority.
- Not hospitals: Comanche Nation (TRIBAL_ORG; OSDH's text says "rural tribal members") and Wyandotte Nation
  (TRIBAL_ORG, GENERAL_KNOWLEDGE). The rest are on §8's fallback.

**The OK probe.**
- `OK_PENDING_OPPORTUNITIES` drops RRR and CDM; two opportunities remain.
- The probe baseline is re-based to 2026-10-02 (`--probe-baseline`). Before re-basing, the live recipients page
  was checked: its reduced text is identical to the archived 10-02 copy, and it names nobody new. That copy was
  read in session 85 and its five rosters are now all extracted.
- The interactive probe logged a TRIPWIRE (the 75 names), then UNCHANGED after the re-base. Both lines are in
  `logs/probe_results.csv`.

## 3. Delaware FQHCs (`R/03bu`)

**Rows.**
- Westside Family Healthcare: $11,300,000.
- La Red Health Center: $10,100,000.
- Henrietta Johnson Medical Center: $1,290,000.
- All three are flagged `AMOUNT_ROUNDED_IN_SOURCE`. They total $22,690,000, and the release's own headline says
  "nearly $23 million".

**Typing.**
- **The form is stated by the state** ("Delaware's three Federally Qualified Health Centers"), so the rows are
  FQHC_OR_RHC on STATE_SOURCE at MEDIUM.
- CMS's DE FQHC file agrees. Henrietta Johnson enrols as SOUTHBRIDGE MEDICAL ADVISORY COUNCIL INC dba HENRIETTA
  JOHNSON MEDICAL CENTER.
- None of the three is on the DE hospital file.

**What the release does not say.**
- The release names no initiative. Session 85's match to DHSS's "Value-based care transformation" line
  ($24,322,042.48) is a note only; nothing is subtracted from it.

**Footer and newsroom.**
- The footer prints $157,394,963.86 and is asserted as Tier 1.
- NEWSROOM DE is re-based to `2026-10-02_de_news.html`. Its only hot headline was this release.

## 4. South Dakota: are the new contracts inside the $121.5M?

The register moved again after session 85's morning read. It now holds 41 contracts / $26,836,144, so **15 are
new, +$17,612,967** (session 85 counted 13 / +$16,593,725). DSU ($999,242) and the State Veterans Home ($20,000)
posted later the same day.

| Pool | New | $ new | Relation to the announced $121.5M |
|---|---:|---:|---|
| Rural Strong (register's own words) | 6 | 14,088,808 | **Inside** the $31.5M round. The pool is now 14 of 28, $15,967,960 ≤ $31.5M (asserted) |
| UNPLACED (no round stated) | 8 | 3,175,112 | **Never added.** May sit inside the $90M Technology and data round; capped at its 82 grants / $90M; RS + UNPLACED ≤ $121.5M (asserted) |
| Administrative | 1 (CHAS training platform) | 349,047 | Outside both rounds, like USD's and SDSU's platforms (session 64) |

**Why the eight are UNPLACED rather than placed in a round.**
- Each was read and placed by hand (`SD_PLACEMENT`, with the reason).
- DSU's "Digital Regional Innovation Center" matches the $90M release's wording ("Regional Innovation Centers").
  Huron Clinic Foundation's "equipment" may match "digital equipment upgrades".
- A theme is not a statement of the round, so neither is counted inside the $90M.

**What the build now refuses.**
- A future non-Rural-Strong contract with no hand placement.
- An UNPLACED pool beyond the $90M round's bounds.

**SD's hospital rows.**
- +4 Rural Strong ($7,081,808): Huron Regional, Bowdle, Mobridge and Fall River (CMS record).
- +3 unplaced ($1,837,644): Faulkton, Mobridge and Avera McKennan Milbank (CMS record, CCN 431326).
- **Sanford Health ($5,442,000) and Avera Health ($1,565,000)** are system parents with no SD enrolment under those
  strings. They stay on §8's fallback and are queued as `SD_SYSTEM_PARENTS_FORM_NOT_STATED`: +$7,007,000 if the
  owner types them.
- Huron Regional is HIGH on the name rule with no CCN. Bennett County and Community Memorial (Burke) already carry
  the same pattern; Stage 5 will settle it.

**The "on top" defect this exposed in `R/03aw`.**
- `published_incl_pool_level` added SD's priced contracts to both round totals, which counted the Rural Strong
  contracts twice: $1,879,152 before today, and it would have been $15,967,960 after.
- It now nets in-round (RS) and UNPLACED contracts out of the pool-inclusive figure. SD reads $129,193,072, which
  is administrative + $121.5M.
- `R/03j`'s reconciliation shows the UNPLACED line beside the $90M round.

## 5. The stale figures from session 85 (main was red)

Running the affected tests showed three failures already on `main` before any session-86 change:
- **`test_03bj`.** Session 85's WV Minnie Hamilton and OK Doulas Newman rows were typed on CMS enrolment by their
  own extractors, with no `EH_APPLY` verdict and no session-71 tag. The partition pin was also still session 83's
  1,261.
  - All 18 enrolment-typed rows (session 85's 4 and session 86's 14) now carry verdicts.
  - `R/03av --build` and `R/03bt --build` chain the overlay. Numbers are written in full: `as.character(500000)`
    had written WV's $500,000 as `5e+05` on the first attempt.
  - `R/03bj --apply` round-trips every other state file byte-identically.
- **`test_03bh`.** WV's committed disposition still read "1 of 7 rows" against a 14-row file. It was rebuilt along
  with SD's.
- **`test_03ap`.** This partition pin was updated in session 85 (1,265) and now reads 1,288.

## 6. Files

- New: `R/03bu_de_fqhc_awardees.R`, `data/reference/{ok_year1_rrr,ok_year1_cdm,de_year1_fqhc}_awardees.csv`, and
  `federal_records/2026-10-02/` (OK FQHC, OK RHC, DE FQHC + MANIFEST).
- New archives:
  - SD register 2026-10-02: series + two description searches + 15 detail pages, with the manifest block appended.
  - OK probe baseline 2026-10-02.
  - NEWSROOM `2026-10-02_de_news.html`.
- Review queue: three questions appended, CRLF, with only additions in the diff.
- **`test_03ar` (rural cut).** This was also still pinned at session 83's 1,261. It is re-stated at 1,288. Rural
  rows rise 240 → 256 / $263,299,771.23, all 16 critical access hospitals by their own CCN: WV Minnie Hamilton ×3,
  OK ×7 (Newman ×2, Fairview ×2, McCurtain, Texas County, Cimarron) and SD ×6. Huron Regional has no CCN and does
  not count.
