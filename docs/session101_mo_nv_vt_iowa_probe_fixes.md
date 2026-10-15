# Session 101 (2026-10-15): MO, NV, VT extractions; WV and HI rulings; Iowa probe and Routine; probe fixes

This session started from `main` at `d9970b9`, after session 100 (`claude/pensive-cori-hbu29i`) merged. No Year 2 work was done; Iowa's Year 2 award window is recorded as a watch date only.

## Hospital partition, before and after

The three buckets are never added together.

| Bucket | Before (session 100) | After (session 101) | Change |
|---|---|---|---|
| NAMED_HOSPITAL | 1,331 rows / $1,225,134,515.58 / 32 states | **1,336 rows / $1,309,664,382.63 / 32 states** | +5 rows / +$84,529,867.05 |
| POOL_NAMED_HOSPITALS | 2 rows / $30,806,856.12 (NE, CT) | **4 rows / $51,084,910.43** (NE, CT, NV) | +2 rows / +$20,278,054.31 |
| POOL_UNNAMED_HOSPITALS | 4 rows / $69,323,109.17 (IL, RI, NE) | **5 rows / $69,323,109.17** (+ HI at $0) | +1 row / $0 |

Where the NAMED_HOSPITAL change comes from:

| State | Rows | Dollars | What |
|---|---:|---:|---|
| MO | 0 | +$34,646,479.34 | The 20 SMRP hospital rows are now priced |
| NV | +2 | +$49,169,395.71 | Priced from the BP1 report, plus 2 new hospital rows (Banner Churchill RHIT; Mt. Grant FLEX-25) |
| VT | +2 | +$713,992.00 | Brattleboro Retreat, two agreements |
| WV | +1 | $0 | Vandalia Health, owner ruling |

**Nevada's figure is reported with and without the two SOURCE_SUSPECT rows:**

| | NV NAMED_HOSPITAL | National NAMED_HOSPITAL |
|---|---|---|
| As published (with the SOURCE_SUSPECT rows) | 46 rows / $49,169,395.71 | 1,336 / $1,309,664,382.63 |
| Without the SOURCE_SUSPECT rows (FLEX-28 $997,361.00; FLEX-36 $2,458,060.00) | 44 rows / $45,713,974.71 | 1,334 / $1,306,208,961.63 |

NV POOL_NAMED_HOSPITALS is 2 rows / $20,278,054.31 (NRHPF) either way.

**Rural cut (`R/03ar`):**
- Now 268 rows / $282,660,793.99. It was 267 / $267,502,638.43.
- Washoe Barton's SOURCE_SUSPECT van ($2,458,060.00, CCN 291306, a CAH) is inside it. Without it: 267 / $280,202,733.99.

**Subtractable slices added this session, all LOW:**
- Banner Churchill: a hand-read enrolment bridge, $145,428.23.
- NRHPF: owner ruling, $20,278,054.31 (POOL_NAMED).
- Vandalia Health: GENERAL_KNOWLEDGE, $0.
- HAH: owner instruction, $0 (POOL_UNNAMED).

## Task 1: Missouri (extracted)

**The gate passed. The page states AWARDED amounts.** DSS's SMRP page (served 2026-10-15, Last-Modified 2026-10-13) reads:
- "has awarded approximately $35 million in Strategic Minor Renovations Program funding"
- "Missouri is awarding grants to 20 projects"
- "A full list of awardees and allocation is below", over a two-column table headed **"RHTP | Awarded Amount"**.

The verb is "has awarded" and the column is "Awarded Amount". Nothing on the page calls them maximums, requests or ceilings.

- **The 20 rows were rewritten from the table, not patched.**
  - The sum is asserted to the cent: **$34,646,479.34**. The page prints no total.
  - Every amount is asserted row by row against the page.
  - Salem Memorial District Hospital is $1,700,599.50. That is consistent with the congressman's "$1.7M" on CMS's page, which was never used.
- **MO file:** 22 rows, all priced, $41,879,139.77. Hospital: 20 / $34,646,479.34. Six of the 20 are CAHs on their CCNs; they carry $12,149,876.33 into the rural cut.
- **Archived** under `data/evidence/MO/`: `2026-10-15_dss_smrp_awardees_priced.html`, `2026-10-15_dss_rural_health.html` and `2026-10-15_dss_bid_proposals.html`. The prior copies are kept as `smrp_awardees_unpriced`, `program_page_s54` and `bids_prior`. The probe is re-based and logged UNCHANGED live on all four pages.
- **IFB DSS26015-02: CLOSED, OUTCOME UNKNOWN** (`MO_DSS26015_STATUS`).
  - It is on the 09-01 bid table (kept as `bids_prior`) and absent from the 10-15 table.
  - The bid check is now an award watch. It fires if DSS26015 reappears on the bid table, if award wording appears there, or if the programme page puts DSS26015 beside award wording.
  - MissouriBUYS is a JavaScript application and was not read (UNKNOWN).
- **Not extracted:** Kids Win Missouri ($1.46M, Child Care Works) and the MU Sinclair School of Nursing CNM contract were the 10-14 name trip. Both are non-hospital, and the brief did not include them. They are in the re-based programme page.

## Task 2: Nevada (extracted, PROVISIONAL)

**Source.** NVHA's "RHTP Subrecipient Report for BP1": 24 pages, PDF created 2026-10-12, Last-Modified 2026-10-13. The live copy on 10-15 is byte-identical to session 100's archive (sha256 `34c74ae6…`). Archived as `data/evidence/NV/2026-10-13_nv_rhtp_subrecipient_report_bp1.pdf`.

**How it was read.**
- This project's run reader gets x right only for the first run on a line for this producer, so columns could not be cut from it.
- The table was therefore parsed once from poppler's `pdftotext -bbox` word boxes (`nv_bp1_parse_bbox()`, CLI `--parse-bp1`) into the committed `data/reference/nv_bp1_subrecipient_report.csv`.
- **All 10 sections reconcile to their own printed TOTALS rows, both columns, to the cent:** 157 lines, $175,245,033.86 awarded.
- `nv_assert_bp1()` re-checks the CSV against the PDF with the project's own reader: every figure and every applicant's words. No test and no Routine needs poppler.
- Service area and project description were **not** committed. Word centres each header over its column, so a header's x is not the column edge, and the first cut produced wrong text.

**The crosswalk (hand-read, `NV_BP1_CROSSWALK`, each entry pinned to its awardee string):**
- **146 report lines price one page row each.** Duplicate names (Nevada Health Centers ×5, GBC ×5, UNR ×6, Mt. Grant ×3, Ely Shoshone ×2, Washoe Barton DBA ×2) were paired on the report's project text, never on order.
- **One line covers two page rows.** WRRAP_RR-15 (NRHPF) is behind rows 26 and 45. It is priced once, on row 26.
- **11 lines have no page row** and are rows 157–167:
  - Health Communities Coalition (RISHN)
  - Mt. Grant transportation, $172,622
  - West Wendover Ambulance
  - Convergence (new primary-care practice)
  - NV Medicaid ×2
  - DCFS
  - Veterans (NDVS)
  - Corrections (NDOC)
  - PFT ×2
- **9 page rows have no line:** Tonopah Dental ×2, "93 X 95 NV" (already withdrawn), and **six R+R hospital rows**: WBR, Incline Village Foundation, NNRH, Carson Valley, Humboldt and Grover C. Dils. All six hospitals are among the 14 in NRHPF's line. They stay unpriced, and nothing is imputed (§6.2).

**Flags.**
- Every priced row carries **PROVISIONAL_SOURCE** and `amount_confirmed = No`.
- The two defects are carried as published and flagged **SOURCE_SUSPECT**:
  - **FLEX-36, Washoe Barton Medical Clinic NEMT van:** requested $245,800.00, awarded $2,458,060.00, ten times the request. NVHA's own FLEX TOTALS row includes it.
  - **FLEX-28, Northeastern Nevada Regional Hospital:** requested $103,725,086.00, awarded $997,361.00. The request exceeds the whole FLEX pool.
- Both flag codes were added to `vocabularies.csv` on your instruction. **PROVISIONAL_SOURCE overlaps AMOUNT_PRELIMINARY** (Alaska). The note records the difference: it is a document-level caveat, not a per-recipient one. If you want one code, collapse it to AMOUNT_PRELIMINARY.

**NRHPF, $20,278,054.31 (owner ruling).**
- Coding: PASS_THROUGH_DESIGNATED, POOL_NAMED_HOSPITALS, LOW, intermediary NRHPF.
- **The report names all 14 hospitals** in the line's service-area cell: "All Rural Hospitals: Banner Churchill Community Hospital, Battle Mountain General Hospital, … William Bee Ririe Hospital". That is the POOL_NAMED condition.
- **The vulnerability is stated on the row.** The report's verb is "NRHP will organize the RHT recruitment, retention and training projects of all 14 rural hospitals". "Organize" does not by itself show money paid to the hospitals, and the award is 9× the $2,263,499.00 request.

**Typings on CMS NV enrolment** (`federal_records/2026-09-25/cms_hosp_enrollments_NV.json`, 78 records):

| Recipient | Result |
|---|---|
| Banner Churchill (RHIT-01, row 104, $145,428.23) | **Typed:** HOSPITAL_OR_SYSTEM on CCN 291313, BANNER CHURCHILL COMMUNITY HOSPITAL (CAH, Fallon). Hand-read LEGAL_NAME_TRUNCATED bridge, LOW, through R/03bj. It enters the rural cut |
| Intermountain ("IHC Health Services, Inc. dba Intermountain Health") | **No NV enrolment** carries IHC or Intermountain. Not typed on enrolment. Row 31 (R+R, $1,781,742.18) stays HOSPITAL_OR_SYSTEM on session 49's general-knowledge answer; row 105 (RHIT, $24,506.00) stays on §8's fallback |
| Renown ("Renown Health" / "Renown Health Foundation") | **No enrolled legal entity is named "Renown Health".** Renown Regional Medical Center (290001) and Renown South Meadows (290049) are separate urban bodies, and a prefix is never a match (§2). Row 70 (A+T, $616,903.00) stays HOSPITAL_OR_SYSTEM (session 49); row 112 (RHIT, $985,700.00) stays on §8's fallback |

All three open points are queued as `NV_BP1_FOLLOWUPS`, together with:
- NRHP's other two lines: RHOAP-18 $3,772,261.00 and RHIT-19 $398,000.00, still IN_KIND.
- RWP-03's co-applicant "+ Banner Churchill Health" ($531,469.16), a §6.2 multi-recipient field.

**Watch.** The NV probe is re-based to the 10-15 roster page, which differs from 09-24 only by the BP1 link. It now also checks the BP1 PDF by digest (a revised report trips). Live run: UNCHANGED on roster, nofos and bp1_report.

**NV file:** 167 rows, 157 priced, $175,245,033.86.

## Task 3: Vermont (extracted)

- **The 10-08 update:** "Updated as of October 8, 2026". 175 rows; the table's total row prints $131,057,627.27.
- **Diff against the archived 10-02 list,** keyed on initiative + activity + amount: **9 new agreements, $3,637,773.36.** None was removed, re-priced or re-filed.
- **Brattleboro Retreat** ($525,000 facility upgrades; $188,992 transformation) is typed a hospital on its CMS enrolment through the existing VT_TYPES entry. **VT hospital: 51 / $44,866,699.26 → 53 / $45,580,691.26.**
- **Two typings added,** neither a hospital: the CHC Rutland ", Inc." re-spelling (FQHC, federal record) and Pediatric Medicine, PLC (a practice).
- Northeast Kingdom Human Services and S&A Healthcare PLC dba New England Wellness Group stay on §8's fallback ($0 hospital effect).
- `VT_PAGE_ROWS` = 175 and `VT_UPDATED_TXT` were bumped. The archive is `recheck/2026-10-15/VT/`, which re-bases the probe (UNCHANGED live).

## Task 4: small rulings

**WV:** Vandalia Health is HOSPITAL_OR_SYSTEM, DIRECT, NAMED_HOSPITAL, LOW, GENERAL_KNOWLEDGE, no CCN, $0. WV hospital rows 11 → 12, dollars unchanged. `WV_VANDALIA_SYSTEM_PARENT` is RESOLVED.

**HI:** new file `hi_year1_awardees.csv` (`R/03cd`), read from SHPDA's archived page (2026-10-14).

| Row | Notice of Award | Coding |
|---|---|---|
| Healthcare Association of Hawaii | 9/3 | §10.2 association row: PASS_THROUGH_DESIGNATED, POOL_UNNAMED_HOSPITALS, LOW, $0. Basis: "readiness funding … primarily for rural hospitals … and administration of approved Rural Value-Based Innovation funding". "Primarily" is not "only", which is why it is LOW |
| Physicians of Southwest Washington, LLC | 9/11 | OTHER (a physician-led IPA / MSO, Vancouver, Washington, by general knowledge), NON_HOSPITAL |
| Hawaii Primary Care Association | 8/28 | The FQHC association, NON_HOSPITAL. **Included although the brief named only two:** it is the page's third Notice and moves no hospital figure. RCJ's $17M for it remains unverified |

- **The amounts are in HANDS, which is 403 to this environment: UNKNOWN, not $0.**
- Hawaii moves INVESTIGATED_NO_PROBE → **EXTRACTED**. The survey is now **40 / 6 / 1 / 3**.
- **Hawaii still has no probe and no Routine.**

## Task 5: Iowa probe and Routine

**The probe** is `Rscript R/03z_ia_year1_awardees.R --probe`; baselines are taken with `--fetch-probe` into `data/evidence/IA/probe/`. It reads six pages:

| Page | Fires on |
|---|---|
| `programme` | `ia_assert_award_index()` against the LIVE page (the eleven notices still linked), plus any new media link on it |
| `noia_index` | A new NOIA line. No name tripwire: the index names nobody, and its archive yields 2 names, below the baseline guard (found on the first run) |
| `council` | A new meeting in the Council's list |
| `council_0827` | The 2026-08-27 meeting's document links changing (a re-posted deck) |
| `hhs_news`, `gov_news` | A new headline matching Rural Health Transformation, Healthy Hometowns or RHTP. This is a **headline-link diff, not a sentence diff**: the sentence diff failed in testing for Alabama's session-84 reason (no full stops on a press index) |

Plus the name tripwire on `programme`, `council` and `council_0827`. Live run: UNCHANGED on all six. Fixture tests cover each counterfactual.

**The Routine:**
- Runner `session_01G4rHWTZoi37zKiNtBJw3kn` (`env_01RnpqJ1D6wFAaRMvFu43oV3`, claude-sonnet-5, auto, `main` as source and outcome, no seed).
- Routine `trig_01ECTghY5iHNh5RvWGLMfqBY`, **Thursday 15:20Z**.
- Prompt `v4/IA.txt`, derived from a new `v3/IA.txt` (AL's prompt with state, runner and script changed). It is byte-identical to the text sent to `create_trigger`. `--check` passes for 40 states.
- Registered in `config/routines.csv` with `logging_since 2026-10-15T15:21:00Z`. **The 10-15 15:20Z firing ran against `main` before this branch merged and is deliberately not counted; it can log nothing, since `main`'s R/03z has no `--probe`.**
- **The first counted firing is Thu 2026-10-22 15:20Z. Merge before then.**

**The ~9 hospitals in the 2026-08-27 Council deck.** The deck has no NOIA behind these names, and nothing was extracted.

How the deck presents them:
- They sit under "Overview of Year 1", beside "Contracts Awarded: 269 +7 amendments" and "Obligated Funds as of 8/24/2026" (Centers of Excellence $3,249,637; Combat Cancer Health Hubs $33,100,310).
- That is separate from the deck's "Still to Come… Projected Year 2" section.
- **The deck presents each as an award, not a plan.** It is a Council briefing deck, not an award document, prints no per-recipient amount, and no Notice of Intent to Award for these names is on the programme page's awardee index.

| Hospital | Where in the deck | Award or plan |
|---|---|---|
| Cass County Memorial Hospital | Centers of Excellence | Award (Year 1 overview) |
| Grinnell Regional Medical Center | Centers of Excellence | Award |
| Mahaska County Hospital | Centers of Excellence | Award |
| St Anthony Regional Hospital | Centers of Excellence | Award |
| Van Buren County Hospital | Centers of Excellence | Award |
| Mercy Des Moines | Cancer Hub and Spoke, Hub | Award |
| Unity Point Des Moines | Cancer Hub and Spoke, Hub | Award |
| Jennie Edmundson Hospital | Cancer Hub and Spoke, Hub (already a CoE row in our file) | Award |
| Mercy North Iowa | Cancer Hub and Spoke, Hub | Award |

- The deck's other ten CoE names are already in `ia_year1_awardees.csv`; "Compass Memorial Healthcare" is Marengo Memorial's trading name.
- The hubs' **spokes** (about 24 hospitals) are network members, not recipients (§0.3).

**Mary Greeley / UnityPoint Rural Residency NOIA (PHTHORC27001, 09-25): NOT RHTP on its face.**
- The NOIA carries no CMS footer and no RHTP or Healthy Hometowns wording; every Healthy Hometowns notice carries the CMS footer.
- HHS's funding-opportunities page files the RFP under **"Other Opportunities"**, not "Healthy Hometowns Funding Opportunities".
- The RFP itself is image-only and was not read. A test pins all of this.
- Treat it as non-RHTP unless an Iowa document says otherwise.

**Year 2, recorded only:** `IA_YEAR2_AWARD_WINDOW` = 2026-10-15 to 2026-11-20 (deck: "Award Announcement for most procurements listed above between October 15 – November 20, 2026", pending CMS approval of the Year 2 budget).

## Task 6: Indiana coverage

R/03bi's probe now reads five pages. Baselines are archived byte for byte (all were credential-free) under `data/evidence/recheck/2026-10-15/IN/`, via `--fetch-probe`.

| Page | Fires on |
|---|---|
| IDOA Award Recommendations register | A new RHTP letter, keyed on the decoded file path |
| GROW home page (the newsletter source) | A new newsletter-issue link |
| October 2026 newsletter | A named Meds-to-Beds hospital |
| Meds-to-Beds initiative page | A named Meds-to-Beds hospital |

- **The trip is any named Meds-to-Beds hospital:** a hospital-shaped name the archive lacks, in a Meds-to-Beds item. The name tripwire also runs on the three subject pages.
- The reducing archiver re-spaced cells and left hrefs encoded, which made the first run trip on transport alone. That is why the baselines are byte-for-byte.
- Live run: UNCHANGED on all five. The IDOA register and the initiative page are byte-identical to session 100's copies.

## Task 7: probe fixes

All three fixes are central, in `rhtp_probe_run()` and a shared fetch helper, so every probe has them. Fixture tests: `tests/testthat/test_utils_probe_session101.R`.

| | Fix | Mechanism |
|---|---|---|
| (a) | Every finding is reported before a name tripwire throws | Inside a probe run, `rhtp_assert_no_new_organisations()` records a trip and continues. Every watched page is diffed. A returned `findings` vector (MO, WI, now IA and IN) is logged TRIPWIRE. One error carrying every message is raised at the end. **Outside a probe run nothing changes** |
| (b) | A failed page fetch logs ERROR for that page and the probe continues | `rhtp_probe_get()`: an ACCESS failure (HTTP status, empty reply, timeout, firewall) records ERROR for that page and reads the archived bytes, so every other check still runs. Wired into `rhtp_watch_pages()` and the 20 bespoke fetch loops (ME CA CT NM LA KY NY NC AR MS DE ID OH SC TX MO WI VT WV NE; WY records ERROR on its existing UNREACHABLE path). A non-access error, or any error outside a probe run (`--fetch`), throws as before |
| (c) | An evidence-guard refusal logs ERROR | Logged as page `(evidence guard)` before it is raised. `rhtp_probe_verdict()` now classifies "EVIDENCE GUARD REFUSAL" as ERROR, which is what `nw_sweep()` reads |

The Iowa probe's first live run showed (a) working: all six pages were logged before the (then mis-configured) name tripwire raised.

**KY and CA re-based after reading their diffs:**

| Page | What changed | Copy |
|---|---|---|
| KY `rch` | FHKY's Hub Lead RFA round 2 (10-13): eligible classes; portal "in mid-November"; deadline 2026-12-18; anticipated award notification 2027-01-29. Tier 2, nobody named | 2026-10-15; the 10-12 copy stays, R/03by reads it |
| KY `funding` | The menu gained "Reports and Documents", read with KY's own reducer; nothing else | 2026-10-15 |
| CA `calrht` | One document link, "CMS RHT Program Obligated Funds (October 8, 2026)", CMS's report already parsed by R/00c | 2026-10-15 |

Live KY and CA probes are UNCHANGED.

## Other files changed

- `CLAUDE.md`: Deliverable 1 (MO, NV, VT, WV, + HI) and the partition block, asserted by `test_claude_md_status_table.R`.
- Re-pinned figures: `test_03ap`, `test_03bj` and `test_03ar` (each with a session-101 layer subtracted first), `test_state_union`, `test_03k`, `test_00b`.
- Rebuilt: `R/03k` and `R/00b`. The rebuild also picked up committed CMS newsroom data for NE, IA and LA.
- Rebuilt: `R/03bh` (HI disposition text) and `R/03ar`.

## Suite

Full suite (`Rscript tests/run_tests.R`, 2026-10-15, after the last code change): **0 failed, 1 expected skip** (the CMS first-run branch). The first full run found three failures, all fixed: HI was missing from `R/03aw`'s Year 1 status table; IN's probe baselines sat inside `data/evidence/IN/`, whose manifest test lists every entry (moved to `recheck/2026-10-15/IN/`); and R/03cd's comment named a disposition file, which the prose-rule test reads as a writer.
