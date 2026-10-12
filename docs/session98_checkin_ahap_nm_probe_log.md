# Session 98 (2026-10-12): Routine check-in, AHAP probe, NM test, probe log since 10-07, CMS obligation rulings

**Branch:** `claude/quirky-johnson-ml0unk`. It merges two unmerged branches first:
session 97 (`gallant-cannon-035zn1`, the CMS obligation report) and the session-84
check-in of 10-08 (`compassionate-heisenberg-6609c9`, MO/SC old ids deleted, AL
governor fix). Neither was on `main`.

**Figures that moved (Task 5 only):**

| Bucket | Before (session 97) | After (session 98) | Change |
|---|---:|---:|---:|
| NAMED_HOSPITAL | 1,308 rows / $1,213,341,798.50 / 32 states | 1,313 / $1,216,466,199.99 / 32 | +5 / +$3,124,401.49 |
| POOL_NAMED_HOSPITALS | 2 / $30,806,856.12 | 2 / $30,806,856.12 | 0 |
| POOL_UNNAMED_HOSPITALS | 1 / $50,008,264.00 (IL) | 4 / $69,323,109.17 (IL, NE, RI) | +3 / +$19,314,845.17 |

All of the change is in rows with `validation_source_type = CMS_OBLIGATION_REPORT`,
and it can be subtracted in one step. The three buckets are never added.

---

## 0. Items from the probe log that would change a hospital figure (decisions for you)

Nothing below was extracted or re-based. Each is a proposal. Detail is in §4.

| State | What | Estimated hospital effect | Proposed action |
|---|---|---|---|
| **SD** | open.sd.gov RHT series is now **53 contracts / $37,039,799**, against 41 / $26,836,144 in the file. 12 new, $10,203,655, none removed. 4 are labelled Rural Strong (18 / $25,012,010 in all, still inside the $31.5M round). | **+3 NAMED_HOSPITAL / +$7,789,960**: Monument Health Rapid City (CCN 430077) $6,361,000; Avera Heart Hospital (CCN 430095, name bridge, LOW) $1,297,500; Prairie Lakes (CCN 430005A) $131,460 | `R/03i --fetch --force`, `--build`, type the 3 on CMS SD enrolment, update Deliverable 1 |
| **AK** | Rolling notice: 254 rows / $248,976,547.51 against 249 / $242,620,741.15. 5 new actions ($4,843,430.79, notified 10-09, none a hospital) and 19 amounts revised (net +$1,512,375.57) | **+$446,104.96, no new rows** (PeaceHealth Ketchikan +$449,699.34; YKHC IA-362 +$14,168.51; Providence −$17,762.89) → AK 45 / $69,816,743.96 | Standard rolling refresh (roll `AK_PRIOR_FILE`), then `R/03bj --apply` |
| **OK** | Funding Recipients page (now redirects to `oklahoma.gov/rhtp/...`, "Last Modified on Oct 12, 2026") carries two new rosters: **Behavioral Health Integration**, 3 priced awards, $1,228,012.70; **EMS & Community Paramedicine Vehicles**, 38 + 13 recipients, no amounts. Keetoowah Economic Development Authority ($1,123,500, not a hospital) has left the RRR roster | **+1 NAMED / +$90,171.53** (Mercy Health Oklahoma Communities, already typed a hospital at LOW); **about +6 NAMED rows at $0** (INTEGRIS Miami, Newman Memorial, Northeastern Health System, Purcell Municipal ×2, Choctaw Nation on CCN 370172). OK RRR would fall to 19 / $38,455,023, hospital unchanged | Extract both rosters with `R/03bt` into their own files, type on CMS OK enrolment, chain `R/03bj`, record the Keetoowah withdrawal explicitly, re-base |

If all three were extracted: NAMED_HOSPITAL about **1,317 rows / $1,224,792,537** (after this session's
rulings), with OK's EMS/CP rows adding rows and $0. These are estimates from live reads, not file builds.

---

## 1. Task 1: Routine check-in (10-08 to 10-12)

**MO, SC and AL each logged under the new Routine ids in `config/routines.csv`.**

| State | New id | First firing under it | Every firing since | Next |
|---|---|---|---|---|
| MO | `trig_01EB2Xxyn1bSy3LcGBEcuZra` (Wed 15:00Z) | 2026-10-07 15:03Z: `bids` CHANGED, `program_page`, `hub_roster`, `smrp_awardees` UNCHANGED | that one | 10-14 |
| SC | `trig_01221XxhsPrg8ojwngYSAAFv` (Thu 08:30Z) | 2026-10-08 08:35Z: `programme` CHANGED, three controls UNCHANGED | that one. The 10-01 line is under the OLD id `trig_01R1pZ…`, inside its `old_logging_since` window | 10-15 |
| AL | `trig_01NtbC312pu2u8d7uePQXEty` (Thu 14:40Z) | 2026-10-08 14:42Z: TRIPWIRE, the false trip session 84 explained and fixed (the governor page's chrome read as one sentence) | that one. An interactive re-probe at 15:17Z logged `governor` CHANGED with no trip | 10-15 |

**The old MO and SC Routines are deleted.** `get_trigger` returns not-found for MO
`trig_0183VrPsZUMmc3dMneainqXm` and SC `trig_01R1pZjkPkQZWD3vctiAJQ44`. The 10-08
check-in (now merged) deleted them after their successors logged. Nothing was
deleted this session. None of the 112 chained `old_trigger_id` values exists
live.

**Live Routine list.** There are 39 enabled recurring Routines, each on its own
runner session. All 39 are registered in `routines.csv` with matching crons, and
every `last_run` is SUCCEEDED. No one-shot check-in is pending.

**Coverage, 10-07 to now.** `Rscript R/probe_coverage.R --check`:
`137 due firing(s) since the logging fix; all logged except 4 EXPLAINED miss(es)`.
Every firing from 10-07 to 10-12 has its line. The 10-12 firings (KS, CO, DE, CMS,
AK, CT) are still inside the grace window but are already logged. **No missed
firing, so nothing was added to `config/probe_gaps_explained.csv`.**

**Runners above 700k** (`external_metadata.context_usage.used_tokens`, of 1,000,000):

| Runner | Routine | used_tokens | Status |
|---|---|---:|---|
| IN GROW | `trig_01UZ5QWh8No7uiRBz9S8T23C` | 754,497 | completed |
| TX | `trig_017U35M4eGiGcnhPMeoKGzFy` | 736,160 | completed |
| WV | `trig_01SfWj74rQ4kdeHcdNckS4Yn` | 731,490 | completed |
| ID | `trig_01HkxVsw4KoGkHpDwBCfve31` | 730,247 | review_ready |
| VT | `trig_01G7gMgmaRvkzdWq49YjZQdq` | 720,258 | review_ready |

Nothing sits between 600k and 700k; the next highest is MT at 518,317. MO, SC and AL
are at 150,065, 125,576 and 149,447. §2.2a says a runner near 700k is moved to a new
session rather than left for its next firing. **These five were not moved this
session: that is your call.** The VA runner (178,021) is `blocked`: its summary asks
for a human read of the VHCF date tripwire (§4, VA).

---

## 2. Task 2: the AHAP probe (`R/03ca_ks_ahap_watch.R`, run inside `R/03o --probe`)

**Baseline.** `data/evidence/KS/ahap/2026-10-07_rhk_ahap_program_page.html`, read
through the Divi theme's `#main-content` region. If that region is missing, the
probe stops; it never falls back to `<body>`.
- **Why the scope is needed.** Between 10-07 and 10-12 the site menu gained
  "Ambient Listening Technology". A whole-page reduction reads that as a new
  organisation.
- **Live read 10-12.** The content region is unchanged and every check passes.
  The deck href is still the broken relative `ruralhealthkansas.com/about`.

**The four checks.** Each is a diff against the archive.

1. **Name tripwire.** It runs on the content region. Newman Regional Health and
   Labette Health are in `KSA_KNOWN`, matched by containment, so they never trip.
2. **(a) Roster phrase.** `KSA_ROSTER_PATTERN` fires on a NEW sentence such as
   "anchor hospitals … are/include/named/selected/designated/list", "list of the
   ten anchor…", or "… selected as anchor sites". It catches a roster announced
   by town name, which the name tripwire cannot see.
3. **(b) Residency phrase.** `KSA_RESIDENCY_PATTERN` fires on a NEW sentence
   joining residency and contract, agreement, award, partner, sponsor, host, site
   or hospital, in either order.
4. **Deck link.** Any change to the "AHAP Media Fact Deck" href trips, including
   its removal. Nothing was "fixed", because the page has not republished the
   deck.

**Wiring.** `ks_probe()` now runs the two Care Collaborative watches (EBP, then
AHAP) before KDHE.
- KDHE answered 403 on the 10-12 Routine firing as well as from here. Run last,
  that refusal stopped the probe before the AHAP and EBP tripwires were reached.
- Their trips still raise. A KDHE refusal is still logged as ERROR.
- **Limitation:** while KDHE refuses, the AHAP page's UNCHANGED verdict is not
  logged, because the probe ends in ERROR. Only a trip is guaranteed to surface.

**Tests (`test_03ca_ks_ahap_watch.R`).** Each fixture adds a NEW hospital to the
archived page. Each trip is shown firing:
- **Name:** Hays Medical Center.
- **(a):** "The ten designated anchor hospitals are Hays Medical Center, Salina…".
  It still fires with every name marked known.
- **(a) by town:** "Hays, Salina and Pratt have been selected as anchor sites".
- **(b):** "rural residency agreement with KUMC and Coffeyville Regional Medical
  Center". It still fires with that hospital known.
- **Deck:** a republished PDF href.

Each of these is shown silent: the archive against itself, the two pilot sites
re-named, and a menu change outside `#main-content`.

**Re-base.** `Rscript R/03ca_ks_ahap_watch.R --fetch [--force]` writes a dated
archive. A human then points `KSA_FILE` at it.

---

## 3. Task 3: NM six-hubs test without git history

`tests/testthat/test_utils_name_tripwire.R` used to read
`967ee21:data/evidence/NM/2026-09-02_nm_hca_rht_programme.html` with `git show`. In
a shallow clone that read fails and the test skipped.

The archive's whole contribution to the comparison is its 25 **normalised**
organisation names, because `rhtp_new_organisation_names()` compares on exactly
those. The test now pins those 25 names (extracted this session; SHA-256 of the
source archive `35e07a95…4abaf4cdcd`) and passes them as `furniture`, which is
matched exactly on the normalised form. That is the same test `archived` applies,
and the two calls were checked to return identical vectors. The test also pins
the eight expected new names exactly.

- There is no `skip_if` and no `git` call.
- The current SIX_HUBS archive is asserted to exist (`expect_true`), not skipped
  on.
- It follows the same pattern as `test_03bk_umms_system_form.R`.

---

## 4. Task 4: the probe log, 2026-10-07 to 2026-10-12

There are 112 lines: 57 UNCHANGED, 41 CHANGED, 12 TRIPWIRE and 2 ERROR.

**How each line was read.** Three read-only agents compared each live page with
its committed archive, using the repo's reducer. Nothing was run through
`rhtp_probe_run()`, nothing was written to `data/evidence/` or `logs/`, and
nothing was re-based or extracted.

**What the findings files hold.** The quotes and per-page actions are kept in:
- `docs/session98_probe_log_findings_tripwires.md`
- `docs/session98_probe_log_findings_changed.md`
- `docs/session98_probe_log_findings_newsroom_cms.md`

**Live reads are not the logged reads.** Every live read is today's page, not the
bytes the Routine saw on its date.

### Changes a hospital dollar figure

These are SD, AK and OK; see §0.

### New award information, no hospital dollars

- **ND (10-07, TRIPWIRE).** CAH Workforce Retention is still "Awarded | 36
  Applicants" with nobody named, which session 94 already read. **"Train In
  Place" now also reads "Awarded | 45 Applicants"**, and it is not in
  `ND_KNOWN_AWARDED`, so the next ND firing will trip again. Proposed: add it, with
  the sentence "Read 2026-10-12: heading 'Awarded | 45 Applicants'; the section
  names no awardee and prints no amount".
- **NC (CMS 10-08, CHANGED).** NCDHHS's 10-07 release says it "has awarded $4
  million to three Local Management Entities/Managed Care Organizations" for
  behavioural health clinics, and names none of them. The recipients are MCOs,
  which are never a hospital type. The release lists five other programmes: $3M
  OTP, $4M mobile crisis, $3M early psychosis, $2.9M crisis partnerships and $800k
  a year for NC MATTERS. Proposed: add status rows; extract when the three are
  named.
- **LA (CMS 10-12, "new states: IA LA").** CMS's $37.7M release has three parts:
  - The Rural Clinician Credit Bank's "$12.7M to 53 providers", already carried.
  - "Up to $20 million" to public universities and colleges. This is a ceiling,
    and nobody is named.
  - "$5 million" for career pathways across 39 campuses, with nobody named.
  Neither new line is hospital money. Proposed: two status rows in
  `la_year1_status.csv`.

### New solicitations

- **NH (10-07, TRIPWIRE).** FHC's CAH and Acute Care Hospital RFA moved from
  "Coming Soon" to **Open**:
  - The portal opens late October and the priority deadline is November 12,
    2026.
  - "Notification of Award (Initial Cohort) Mid December 2026".
  - A Home Health RFA is now "Coming Soon".
  Proposed: replace `NH_ANCHORS[1]` with the mid-December sentence, re-base
  `fhc`, and archive the RFA. Each FHC award will name a hospital and should be
  coded per award.
- **DE (10-12, CHANGED).** The page now carries a Telehealth/RPM RFP: Year 1
  budget $5M, closed 10-05, run through the Catalyst Fund to vendors. Proposed:
  re-base `programme`.
- **AZ (NEWSROOM, `ahcccs`).** "RHTP Funding Opportunities Now Available: AOEO
  Provider Retention & Wellbeing Microgrant & Transition to Practice". The footer
  is $166,988,956, which is AZ's allotment (Tier 1).
  - **Gap:** the sweep reads only link text. AHCCCS headlines are plain text with
    "Read more..." as the link, so a future AZ award item cannot trip.
  - Proposed: read AHCCCS headlines from the page text. **Your decision.**
- **CT (10-12, `dmhas_rfps`).** A Recovery Centers RFP funded by opioid
  settlement money, so not RHTP (§0.1). The REST row is unchanged.

### Noise

| State | Line | What it is | Proposed |
|---|---|---|---|
| NE | 10-07 TRIPWIRE | DHHS side-nav text. The Routine ran before session 94's scope fix reached `main`; the probe passes today | none |
| WA | 10-08 TRIPWIRE | HCA rotated the expired RNEP item, the one carrying the SUBAWARD footer, off the page | Run `wa_assert_footers()` on the ARCHIVED copy. Re-base the probe to a NEW dated file only: R/03bd's closure assertion reads `recheck/2026-09-23/WA/hca_rhtp_programme.html`, which must not be overwritten |
| VA | 10-09 TRIPWIRE | VHCF re-dated Provider Productivity from Oct 14 to **Oct 15**. The VHCF news index is unchanged. The VA runner is `blocked` on this | Update `VA_ANCHORS$vhcf`, re-base `vhcf` |
| WV | 10-09 TRIPWIRE | A USDA FNS WIC grant ($195,825), not RHTP (§0.1 mode 1) | Add a slug exclusion (a small code change; there is no exclusion list today) |
| WY | 10-09 TRIPWIRE | The new "Year One Award Approvals" button links to a PDF byte-identical (SHA-256 `30aed248…5b372`) to the approvals already extracted | Furniture entry, re-base `programme` |
| NC | 10-10 TRIPWIRE | Trillium's "Rural Ready Roundtable" notice names the programme itself | Furniture entry, re-base `trillium` |
| CA | 10-10 TRIPWIRE | The scope anchor was missing on 10-10. It cannot be reproduced: the probe passes and the page matches its archive | none; if it recurs, consider logging a missing anchor as ERROR |
| AL | 10-08 TRIPWIRE + interactive CHANGED | Explained by session 84 (merged here) | none |
| NY | `press_index`, `scr` | Two non-RHTP headlines; `scr`'s live counters change on every run | Scope `scr`'s digest past its counters |
| LA | `programme`, `funding` (10-07, 10-10) | Only LDH's site menu moved; the body is byte-identical | Scope the digest to the body (a re-base will not stop it) |
| MO | `bids` 10-07 | Not reconstructable. **Today IFB DSS26015-02 (ToRCH Care Smart Growth, about $40M aimed at hospitals) is gone from the DSS bid table**, so the 10-14 firing should trip. Award status UNKNOWN: MissouriBuys was not read | Look for the award at that trip |
| SC | `programme` 10-08 | An FAQ link under the Act 301 Capital grant (state money) | Re-base |
| WI | `dhs_rhtp`, `dhs_solicit` | The CMS footer now on `dhs_rhtp` is the Tier 1 allotment ($203,670,005.21). Four non-RHTP RFAs (PATH, MHBG, opioid settlement, family planning) | Furniture entries for the four, re-base |
| ME | `rhef`, `doe`, `programme` | Footer link, DOE menu, a meeting time and Zoom link | Re-base |
| TN, NJ | `news`, `doh_news` | SLRP release; NJ FamilyCare doula release | Re-base |
| NEWSROOM | 15 pages, 10-08 | Rotating headlines, none RHTP (DE early literacy, FL Lower Keys appointments, MD rural students grant, TX career grants, …) | Re-base each after reading |
| CMS | IA, 10-12 | CMS's $209M is "the overall funding amount awarded to Iowa", the FY2026 allotment (Tier 1) | none |

### Access

| State | Line | Today | Proposed |
|---|---|---|---|
| KY | 10-08 ERROR 401 | Transient: the host answers 200 now. **But the next firing will trip on a menu change** ("Our Plan, Updates and Progress"; a Reports and Documents page that names nobody) | Re-base `programme` or add a furniture entry |
| MS | 10-09 logged TRIPWIRE | `medicaid.ms.gov` returns an empty reply on all agents: UNKNOWN, not NO. **It was logged as TRIPWIRE because `rhtp_probe_verdict()` does not recognise "Empty reply"** | Add that wording to the access classifier. By hand, the other MS pages show new solicitations only |
| KS | 10-12 ERROR 403 | KDHE's Cloudflare, as recorded since session 95 | Re-base `program_page` from a host KDHE serves |

---

## 5. Task 5: the owner's CMS obligation-report rulings (`R/03cb_cms_obligation_rows.R`)

**New vocabulary.** Two codes were appended byte-wise to the CRLF
`vocabularies.csv` (`git diff --numstat` 2 0):
- `source_doc_type = CMS_OBLIGATION_REPORT`
- `flag_reason = CMS_OBLIGATION_ASSOCIATION`

Every row carries:
- `as_of = 2026-07-31`
- `cms_line_id`
- `tier = SUBAWARD`
- an `amount_basis` saying the figure is an obligation, not an executed award.

**Dedupe against NE and PA, by name AND amount (`ob_dedupe()`).** The build
refuses an amount that matches an existing row to the cent, and any name overlap
nobody has read.
- **Amount:** no amount matched.
- **Name:** one overlap was found and read. "CHI Health St Marys" is the same
  hospital as `ne_year1_awardees.csv` row 40, "CHI St. Mary's". Both are ST MARYS
  COMMUNITY HOSPITAL, CCN 281342. The awards are different:
  - Row 40 is DHHS's Initiative 4.4b Remote Patient Monitoring Notice of Award,
    $908,475.54.
  - The CMS lines are healthcare-associated infection prevention, $40,824.49.
  - No infection-prevention pool exists in the NE file, so the rows were written.
- **No other overlap.** Guthrie, Mayo and NHA match nothing. Robert Packer
  Hospital, a Guthrie hospital, is a different legal entity on a different award.

**The rows.**

| File | Rows | $ | Hospital |
|---|---:|---:|---|
| `ne_cms_obligation_awardees.csv` | 4 | $3,635,761.99 | NAMED 3 / $160,824.49: Mayo Clinic $120,000 (system, LOW, GENERAL_KNOWLEDGE, no CCN, `facility_state = MN`); CHI Health St Marys $38,239.96 + $2,584.53 (CCN 281342, `DBA_OF_LEGAL_ENTITY`, LOW). POOL_UNNAMED 1 / $3,474,937.50: Nebraska Hospital Association |
| `pa_cms_obligation_awardees.csv` | 2 | $2,963,577.00 | NAMED 2 / $2,963,577.00: The Guthrie Clinic, Pulse Center Pilot (system parent, LOW, GENERAL_KNOWLEDGE, no CCN) |
| `ri_year1_awardees.csv` | 104 | $78,727,110.44 | POOL_UNNAMED 2 / $15,839,907.67: HARI. The other 102 rows are NOT_HOSPITAL |

**Rhode Island in detail.** The file holds all 104 single-recipient RI lines. The
45 multi-recipient lines stay in the leads files and are never divided (§6.2).
Every organisation was screened against CMS RI Hospital and FQHC Enrollments
(archived 10-12).
- **Enrolled:** only the Narragansett Indian Tribe matched, as an FQHC (CCN
  411809, 3 rows, $955,720).
- **No enrolled hospital:** no RI line names an enrolled hospital.
- **BHDDH is a state agency, not a hospital.** The State of Rhode Island holds
  Eleanor Slater Hospital's enrolment (CCN 412001), and session 97's Texas
  DSHS/HHSC rule applies.

| Type | Rows | $ |
|---|---:|---:|
| STATE_AGENCY (RIDOH, RIDE, DLT, BHDDH, EOHHS) | 28 | $38,141,892.83 |
| NONPROFIT_CBO, not hospital (CTC-RI, RIHCA, WARM, Child & Family, BIHS on §8 fallback) | 11 | $18,496,963.87 |
| VENDOR_OR_CONTRACTOR (Alvarez & Marsal, Guidesoft, RDW Group, Chace Ruttenberg & Freedman) | 58 | $4,942,165.42 |
| FQHC_OR_RHC (Narragansett Indian Tribe) | 3 | $955,720.00 |
| UNIVERSITY_OR_AHC (RI College) | 1 | $299,999.00 |
| OTHER (RI League of Cities and Towns: an association of municipal governments) | 1 | $50,461.65 |
| HARI (POOL_UNNAMED) | 2 | $15,839,907.67 |

**Knock-on effects in other layers.**
- **R/03bj.** CHI Health St Marys carries a verdict in `EH_APPLY`
  (`DBA_OF_LEGAL_ENTITY`, LOW). `R/03cb --build` chains 03bj's overlay, as
  `R/03bt` does, so the row carries the session-71 tag. With it, the
  enrolment-typed set is 59 rows / $95,885,249.27 and the sweep has 63 hits.
- **Narragansett.** The FQHC enrolment types the Narragansett rows but sits
  only in `cms_enrolment_record`. `ccn` and `cms_enrolment_match` mean
  "re-typed as a hospital".
- **Rural cut (`R/03ar`, re-stated).** It now covers 1,313 rows. Counted as
  rural: **262 rows / $267,414,906.33**, up from 260 / $267,374,081.84. The
  change is the two CHI Health St Marys rows, a CAH by cited CCN 281342.
- **OTHER rows.** The Rhode Island League of Cities and Towns is the 123rd
  OTHER row, and its basis states its determined form.

**Wiring.** The three files are in `STATE_FILES` (`NE_CMS`, `PA_CMS`, `RI`) and in
Deliverable 1. The union test now pins:
- POOL_UNNAMED states as IL, NE and RI, at $69,323,109.17
- NE NAMED at $14,592,420.31

**What the reader should be told: the vulnerabilities.**
1. **These rows do not meet §7's own `Yes` rule.** That rule names a STATE
   agency or pass-through document. These rows rest on CMS's compilation of each
   state's self-reported obligations as of 7/31, accepted by your ruling.
   - An obligation is not an executed subaward, and the amounts can move.
   - Cite them as "obligated, per CMS", never as "awarded".
   - The source type subtracts them in one step.
2. **HARI and NHA are the most attackable $19.3M in the file.**
   - HARI's lines read "to assess needs for a rural hospital at home program"
     and "help rural-serving hospitals adopt…". NHA's reads "to support Critical
     Access Hospitals evaluating and transitioning to the Rural Emergency
     Hospital model".
   - As written, the association does the work. §10.2's GHA/AHHA negatives code
     that `IN_KIND_BENEFIT` unless a source shows funds administered to
     hospitals, and none read so far shows either way.
   - One fact points the other way: NHA's line sits under CMS's Capital
     Expenditures and Infrastructure category.
   - The `CMS_OBLIGATION_ASSOCIATION` tag exists for that subtraction, and each
     row's basis says so.
3. **Mayo Clinic's $120,000 is an out-of-state system paid to "provide chronic
   disease management services"**, under Training and Technical Assistance.
   - It is coded DIRECT on recipient identity (§0.3a), as you ruled.
   - An opposing reader will call it a service contract. `facility_state = MN`
     lets it be dropped.
4. **The NE infection-prevention lines show a gap in our NE file, not only in
   St Marys.** CMS also reports single-recipient infection-prevention lines to
   Regional West Medical Center ($254,347) and Chase County Community Hospital
   ($87,732.10). Session 97 matched these by NAME and read the amount difference
   as category versus notice. They are in fact a pool our NE file does not carry
   at all. **They were not added (you did not rule on them).** They are a lead.

**Oregon.**
- **The denominator stays the FY2026 allotment, $197,271,578.** A footnote was
  added to the OR row's `evidence` in `year1_completion_status.csv`, via
  `R/03aw`; only that cell moved.
- **What the search found.** No Oregon source gives the CMS report's BP1
  $192,271,577.67, and none explains a $5,000,000.33 difference. Every source
  read gives $197,271,577.67:
  - OHA's CMS footer on four archived pages, 2026-04-10 to 2026-08-28. **Session
    97's "No OR source carries either figure" is wrong**: four archived OR files
    carry $197,271,577.67.
  - OHA's 2026-02-24 webinar: "CMS approved the revised budget on February 18,
    2026, and has partially lifted restrictions on the funds".
  - OHA's June 2026 legislative deck (OLIS 316794): "$197.3M in 2026 for Budget
    Year 1 … unrestricted all funds on March 19, 2026".
  - OHSU's 2026-09-18 RHCC deck: still the $197,271,577.67 footer, "$102.7
    million obligated" as of 7/31, and "October 30: … States may submit a budget
    amendment".
- **Not found:** the Notice of Award itself.
- **Possible explanations.** A post-July NOA amendment or a CMS-side adjustment
  is possible, but no document shows either.
- **Archiving.** The web copies are in this session's scratch directory only.
  Nothing was archived into the repo. Archiving the June deck and the 02-24
  webinar under `data/evidence/OR/` is a candidate.

---

## 6. Suite

`Rscript tests/run_tests.R` on the unshallowed clone, end to end, after every change above.
Result: see §6a, appended after the run.
