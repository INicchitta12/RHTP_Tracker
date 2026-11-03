# Session 113 (2026-11-03): CMS obligation report v2, the monitor, Maine, Oklahoma Q3, NRHA

No hospital figure moved. No award row was added or removed.

## (a) The 10-14 edition of CMS's RHTP Obligated Funds Report

- **Archived** beside the 10-08 file:
  `data/raw/cms/obligations/2026-07-31/RHTP-Obligated-Funds-20261014.pdf`
  (sha256 `05e6f0a9…dbbcf`, 1,035,227 bytes, 105 pages, Word, created
  2026-10-19T23:29Z, Last-Modified 2026-10-19T23:33:11Z). CMS swapped it into the
  **same media entity** (`data-entity-uuid 3a7485dd-…`), and the 10-08 URL now
  answers 301 to it. The data is still as of 2026-07-31.
- **Parsed, not transcribed** by the new `R/00e_cms_obligation_report_v2.R`. The repo's
  own PDF reader cannot decode the Word fonts. Poppler is therefore a one-time step
  (`--extract-lines`, the Nevada BP1 precedent), and its line records are committed at
  `data/interim/cms_obligations_20261014_pdf_lines.csv`. Those lines go through
  R/00c's own walker after one linear x-map and a bullet-glyph swap. Every R/00c data
  assertion passes on the new edition.
- **New dated files** (the 10-08 files are untouched; R/00d and R/03cb still read them):
  `cms_obligations_bp1_{state,lines,headers,checks}_20261014.csv` and
  `cms_obligations_bp1_diff_10082026_20261014.csv`.

### Every change, state, initiative and line level

| Level | Changes |
|---|---|
| State (BP1 award, funds put to work) | **none**, 50 of 50 identical |
| Initiative headers | **none** (once the 10-08 "h"-ligature spellings are normalised: "Ehiciency", "ahordability", "ehorts") |
| Category headers | **none** |
| Lines | **13, all Oregon**, Initiative 5: Tribal, Capital Expenditures and Infrastructure ($2,426,419.42 header, unchanged) |

- **Removed (10-08 only):** 9 bullets, $16,181,322.70. These are the nine bullets of
  the IT Advances category directly above, printed a second time under the capital
  header. R/00c logged this as the OR `BULLETS_TO_CATEGORY` FAIL (+$13,754,903.28).
- **Added (10-14 only):** 4 bullets summing exactly to the header:
  - $1,414,200: minor renovations for clinical and exam capacity.
  - $482,219.42: assisted-living facility NFPA 101 renovations.
  - $450,000: electrical upgrades in behavioral health centres.
  - $80,000: an ADA lift.
- **Reconciliation:** the OR check moves FAIL → EXACT (54 → 53 FAILs). Every other
  check is unchanged.
- **Typesetting only, no content change:** the bullet glyph (§ → ▪), the ligatures,
  non-breaking hyphens, one U+FFFC (Indiana), and the footer text.
- **Downstream effect:**
  - Line ids are identical in every state except Oregon, whose bullets after the block
    renumber.
  - R/00d's hospital-purpose leads (65 / $526,167,324) and its 490 named orgs are
    identical on either edition.
  - The gap table differs only in Oregon's `cms_lines` count.
  - R/03cb's NE/PA/RI lines are identical.
  - **Hawaii's repeated-figure defect is still in the 10-14 edition.**

## (b) Why the monitor "did not flag" the 10-14 file

**It did flag it, every time a run reached `main`.** The verdicts read:

| Run | Page archive linked | Verdict |
|---|---|---|
| 10-15 13:21Z (Routine) | 10082026 | UNCHANGED, correct: the file did not exist yet |
| 10-16 21:36Z (interactive) | 10082026 | UNCHANGED, correct |
| 10-19 23:33Z | | **CMS posted the file** |
| 10-22 13:00Z (Routine) | | no line: suite failed on the NC 21-day omission (`probe_gaps_explained` row 7) |
| 10-26 13:00Z (Routine) | | no line: same cause (row 8) |
| 10-26 14:08Z (interactive, session 107) | **20261014** | **CHANGED**: "NEW CMS obligation report linked" |
| 10-29, 11-02 (Routine) | 20261014 | **CHANGED**, same note |

So the first chance went to a failed suite, and three CHANGED lines then sat unread.
Sessions 107–112 never acted on them. The cause is partly human. The check also had
real holes, which are now closed in `R/00_cms_press_monitor.R`:

1. **The known set was a hand-kept constant.** It is now the archive: a report is
   known once its PDF and manifest are under `data/raw/cms/obligations/`. An
   unarchived report keeps firing with "NOT YET ARCHIVED … linked since the archived
   page of <date> (N days) … repeats every run until the archive holds it". A stale
   flag now looks stale.
2. **A same-name re-post was invisible.** CMS reused the media entity this time and
   could just as well reuse the file name. Each linked report is now HEAD-checked
   (read-only). If its Content-Length differs from the archived file, the verdict is
   CHANGED: "SAME-NAME RE-POST". A HEAD that fails is ERROR (a fact about our access),
   and it never masks a finding.
3. **A page linking no report read UNCHANGED.** It is now CHANGED.

**Fixture tests** (`test_00c`): trimmed copies of the committed 10-16 and 10-26 page
archives (`tests/testthat/fixtures/cms_obligation_watch/`) reproduce three cases:
- the quiet 10-16 run;
- the 11-02 CHANGED note, dated 7 days from 10-26;
- the quiet run once the report is archived.

Further fixtures cover a same-name re-post, a 403 HEAD and an empty link list.

Today's live verdict with the archive in place: **UNCHANGED** (HEAD 200, 1,035,227
bytes, matching the archive).

## (c) Maine: RHEF and EMR have not awarded

Read on 2026-11-03 and archived under `data/evidence/recheck/2026-11-03/ME/`:
- the DHHS programme page;
- MCD's EMR page;
- MCD's September "Emerging Insights" PDF;
- the Year 2 Project Narrative (submitted to CMS 2026-08-28).

**Rural Hospital Efficiency Fund ($30M, 11 hospitals).** DHHS still says
"Participating hospitals will receive individualized technical assistance … followed
by funding for approved projects" (September 2026 to August 2027). The Year 2
narrative calls the 11 a cohort "selected … to receive these investments". No amount
is attached to any hospital and no award is published. `me_rhef_cohort.csv` stays a
non-award file.

**EMR Modernization ($30M).**
- Applications closed 8/14: 55 organisations, $29,453,912 requested, 206 projects.
- MCD's timeline says "Mid-September 2026: Award amounts communicated to
  organizations" and "Fall 2026: Contracts executed with providers". The amounts went
  to applicants privately; nothing is published.
- MCD gives only FORMULA ESTIMATES by class (rural hospital "Estimated $306,000",
  non-rural $204,000, and so on). An estimate per class is not an award (§0.3).

**Not extracted:** there is no priced state roster. The DHHS procurement grant and RFP
archives carry no RHTP item. This is Louisiana's and California's shape, private
notification with no roster.

The ME probe's CHANGED lines on `rhef`, `programme` and `mcd` (10-27 to 11-03)
remain un-re-based. The programme page now links the 9-2 Regional Health Ecosystems
deck and a Year 2 Project Narrative, both Tier 2. MCD's banner advertises a telehealth
vendor RFP (due 12-15) and an AI Hub partner-site call.

## (d) Oklahoma: Q3 Legislative Quarterly Report

**The report.** Posted 10-16 (Last-Modified 13:42Z), 4 pages. It is archived at
`data/evidence/OK/legislative_reports/2026-10-16_ok_rhtp_legislative_quarterly_report_q3.pdf`,
with its own manifest.

**What it is.** Q1 and Q2 had the same shape: per programme, a "Funded Entity", a "Y1
Budget Allocation", a "Current Obligated" figure and a "Spend". The glossary defines
an obligation as "Formally committing to spend funds through a contract or other
signed agreement". The funded entities are first-tier: OHCA, OSDE, OSDH, SWODA,
OUHSC/OSU, LifeCare, Pulsara, the Foundation for a Healthy Oklahoma (OHA), CareerTech
and HWTC. The Q1/Q2 tables are dispositioned as Tier 2 and never extracted (R/03t
header). **The Q3 report names no subrecipient and no new recipient-level amount.**

**Hospital effect: $0. Nothing extracted.** Leads, and checks against our files:

| Q3 says | Our file | Read |
|---|---|---|
| RRR: "awarded 20 recipients a total of $39.6 million"; obligated $41,912,743 | OK RRR 20 / $40,078,522 | consistent at the headline's rounding (SSM St. Anthony added 10-16, Keetoowah withdrawn) |
| CDM: "awarded 15 recipients a total of $15 million"; obligated $12,185,220, "in contracting" | OK CDM 15 / $15,608,845 | consistent; the obligation lags the award roster |
| Doulas: four selected; **obligated $0** | OK Doulas 4 / $647,968 | roster figures are awards not yet contracted |
| BHI: three selected, in contracting; obligated $137,841 | OK BHI 3 / $1,228,013 | $137,841 equals OSU-CHS's line to the dollar |
| Community Paramedicine: "37 ambulance awards and **four** community paramedicine vehicle awards" | OK EMS/CP 37 + **13** vehicle lines | **the vehicle counts disagree**; read the EMS/CP fragment before relying on 13 |
| Lung screening: "Contracted with **nine** hospital sites … eight additional in progress" and, on another page, "**Eight** hospitals subcontracted with OHA"; obligated $2,371,360.66 to FHO (OHA) | OK Lung 11 lines / $1,873,344 + POOL_NAMED $340,608 | the report contradicts itself (8 vs 9); the obligation is the same money at the administrator's grain: **never add it** |
| CHW Expansion: FHO (OHA) obligated $4,460,162.93; "30 hospital and 18 FQHC CHW sites under contract" | not in any award file | **owner lead**: an association-administered pool shared with FQHCs, so §7's per-component rule puts it in no bucket unless the hospital share is priced; the CHW fragment on the Funding Recipients dropdown is unpriced |
| Provider Collaborative: "OSDH: LifeCare" obligated $33,862,084; "LifeCare finalizing subcontracts … first cohort of health systems" | none | **watch**: a large first-tier pool whose subrecipients will be health systems; nobody named |
| Rural Residency: OUHSC/OSU $22,069,267; "feasibility assessments underway with four rural hospitals" | none | unnamed; a count is not a list |
| GYO: CareerTech obligated $177,830; "Five subcontracts executed" | OK GYO 5 / $155,830 | $22,000 is held by CareerTech |

**Probe.** `R/03t --probe` now also reads `oklahoma.gov/rhtp/resources---data.html`.
`ok_leg_findings()` diffs the set of legislative-report PDFs against the archived
2026-11-03 copy. A new report is a finding (TRIPWIRE); a report leaving the page, or a
page with no report links, is a finding too. An archive that yields no report refuses
to run. The live run is quiet (Q1, Q2 and Q3 linked).

## (e) NRHA analysis

**Archived as context only:**
`data/raw/owner_uploads/nrha_rhtp_year1_obligated_fund_analysis_thru_2026-07-31.pdf`.
Its manifest says CONTEXT ONLY, and `test_owner_uploads_context_only.R` fails if any
`R/` script names the file or "nrha". The manifest also records three defects:

- Two state lists do not match their own counts.
- Table B presents Maine's RHEF $30M, EMR $30M and APM $28.5M as "obligated efforts".
  CMS's report has none of the three for Maine as of 7/31; they are announced pools.
- It reads "obligated" as "legally committed via sub-awards", which is not what CMS's
  cover says.

## Owner questions

1. **OK CHW Expansion** ($4,460,162.93 obligated to FHO/OHA, 30 hospitals + 18 FQHCs).
   Extract the CHW fragment's named hospitals at $0, or leave it a lead?
2. **OK EMS/CP vehicle count:** Q3 says four CP vehicle awards and our file carries 13
   vehicle lines. Re-read the fragment?
3. **R/00d / R/03cb on the 10-14 edition:** re-point them, or keep 10-08? The only
   effect is Oregon's lines, which feed no lead and no row.
