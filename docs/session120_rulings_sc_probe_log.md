# Session 120 (2026-11-19): owner rulings, South Carolina's "new names", probe log, FSRS 11-19, rebuild

**Branch:** `claude/nifty-thompson-j7a6p8`, from `main` at `0082e57` (session 119 merged). Work started 14:16Z,
after the Thursday 13:00–14:00Z CMS window.

## Report first

### Hospital figures, before (session 119's 11-16 build) and after (`year1_summary_2026-11-19`)

| Figure | Before (11-16) | After (11-19) | Change |
|---|---:|---:|---:|
| Awards published (national) | $6,272,900,204.35 | $6,332,705,161.06 | +$59,804,956.71 |
| Hospital best estimate | $2,518,590,896.39 | $2,535,780,971.39 | +$17,190,075.00 |
| Strict NAMED_HOSPITAL | 2,270 / $2,205,963,832.38 / 42 | 2,285 / $2,223,153,907.38 / 42 | +15 rows / +$17,190,075.00 |
| POOL_NAMED / POOL_UNNAMED | $96,565,779.43 / $79,214,848.17 | unchanged | — |
| Hospital % of awards (national) | 40.2% | 40.0% | the denominator rose faster |
| ≥50% subset row (n = 34) | awards $5,417,675,376.52; best $2,302,772,240.43; 42.5% / 33.8% | awards $5,419,098,005.52; best $2,304,419,031.43; 42.5% / 33.9% | MN only |
| Rural cut (strict) | 794 / $697,795,113.78 | 803 / $702,766,673.78 | +$4,971,560 (ME CAHs, Murray, Graceville) |

**By state:**
- **ME** +$58,293,137.15 awards, +$15,543,284 hospital (strict). 38 new FSRS rows from the 11-19 archive.
  Twelve are hospitals, among them MaineHealth $8,831,846, Central Maine Healthcare $1,684,880 and MaineGeneral
  $452,992 (hand bridge, LOW). Northeastern University's $32,006,378.15 is non-hospital (see Vendor).
- **MN** +$422,629 awards, +$1,646,791 strict.
  - Murray County: $1,610,332, ruling (a). It was already in the award total as a non-hospital row.
  - Graceville Health Center, CAH 241321: $36,459, new.
  - Family Services Collaborative: $386,170, non-hospital.
- **OH** +$1,000,000 awards: the Ohio Rural Health Association, IN_KIND_BENEFIT, non-hospital.
- **NC** +$44,000 awards: Rowan and Wilkes County MIH lines re-priced on the newer FSRS record. Non-hospital.
- **TN** +$45,190.56 awards: Helping Hands Clinic, non-hospital.

### Verified vendor figures (`verified_vendor_list_2026-11-19.xlsx`)

Every amount type is unchanged in total: award $167,506,827.60, intent $48,233,747.84, contract maximum
$25,965,898.00, obligation $30,181,665.63, administers $128,979,618.21 (NM Accenture, never added). The one move is
the PUBLIC split (ruling b): SCRA's $5,025,452.32 obligation went NON_PUBLIC → **PUBLIC**. Obligation is now
PUBLIC $5,025,452.32 / NON_PUBLIC $25,156,213.31. 46 verified cases (unchanged).

### South Carolina (Task 2): no new organisation, nothing to extract

The SC runner's three "new organisations" (11-12, again 11-19) are **Behavioral Health Services Manual**,
**Medicaid Managed Care Organizations** and **Managed Care Initiatives**: SCDHHS rewrote its site-wide Managed Care
mega-menu (Healthy Connections Prime, Carve-in, Member/Provider toolkits out; Phase I/II pages in). The same menu
diff is on both control pages. The award list PDF is byte-unchanged. The one content change on the programme page is
an **"Annual Reporting: SC RHTP Annual Report - Year 1"** link, byte-identical (SHA-256 `44d00283…`) to the copy
session 118/119 already archived and used for `sc_contracts.csv`, plus an RMUA FAQ link. Re-based (programme and both
controls, `2026-11-19_*`); `--validate` passes. The SC runner had flagged it `need_input` for three weeks.

### Held (each needs a ruling, and each is at or above $25M hospital-shaped)

1. **Wisconsin: DHS's first award tables** (pages "Last revised November 18, 2026").
   - **Rows:** 138 rows / $149,330,290.71 across six tables. Implementation partners: 16 rows / $79,373,358.71,
     mostly state agencies and the UW/WTCS systems. Competitive grants: $69,957,931, matching DHS's "$69.9 million
     in grants for Budget Year 1".
   - **Hospital-shaped:** about 33 rows / ~$25.4M on a name cut (not typed). Examples: Mile Bluff $3.22M, Bellin
     Gundersen $1.70M, St. Croix Regional $1.57M, Cumberland Memorial $1.52M, ThedaCare, Marshfield Clinic Health
     System, Mayo Clinic Health System, Ascension Wisconsin, Door County Memorial Hospital Foundation.
   - **Why held:** DHS calls every amount "the obligated awards and ... subject to CMS review". That is the MO
     Smart Growth shape, which was held in session 112 and extracted as intents in session 114. Also, state
     agencies among the implementation partners are MN's open question.
   - **Archived:** `data/evidence/recheck/2026-11-19/WI/`, with the parsed tables as
     `..._PARSED_NOT_AN_AWARD_FILE.csv` and a manifest.
   - **Probe:** WI's probe keeps tripping until a ruling: extract into a new award file (intents), or record WI's
     tables as obligations.
2. **South Dakota: the open.sd.gov RHT register.** It went from 63 / $41,291,166 to **121 / $90,747,430**
   (+58 contracts, +$49,456,264).
   - **Rows:** 10 CCBHC grants ($11,257,786) that price R/03bw's unpriced cohort; 34 technology/EHR contracts
     begun 2026-02-20, probably the $90M round; chronic disease, doula, maternal hub and one Rural Strong grant.
   - **Hospital-shaped:** about $26.0M. Monument Health Rapid City $12,915,000 ("across the Monument system"),
     Mobridge $3.5M, Community Memorial (Redfield) $2,885,740, Pioneer Memorial $2,338,186, Coteau des Prairies
     $1,642,926 and others.
   - **Why held:** the period conflicts. Five of these contracts (Redfield $2,885,740, Coteau $1,642,926, Bennett
     County $222,402, Horizon $1,151,259, West River HV $623,651) appear in FSRS at the same amounts with action
     dates 11-04/11-06. Under session 118's rule those are Year 2, and they are HELD there. The register prints a
     2026-02-20 begin date. Which governs is a new ruling: the state's contract register or the FFATA action date.
   - **Archived:** `R/03i --fetch` wrote `2026-11-19_open_sd_contract_search_*.html` and 58 detail pages.
     `SD_SEARCH_ARCHIVES` is NOT advanced, so the probe keeps tripping until extraction.
3. **ME Northeastern University, $32,006,378.15** (FSRS COM-27-0811, 2026-10-28).
   - The purpose text is "NORTHEASTERN UNIVERSITY'S ROUX INSTITUTE ... WILL PARTNER IN PLANNING AND IMPLEMENTING
     ... INITIATIVE 5". The Roux Institute is Northeastern's Portland, Maine campus (general knowledge, not
     archived).
   - Recorded as hand drop **HD80** (V9, the Jefferson DE shape) so `R/09c` builds. The row stays in
     `me_fsrs_awardees.csv` as UNIVERSITY_OR_AHC, non-hospital.
   - **Owner question:** should a $32.0M university implementation partner be a CONSULTANT/ADMINISTRATOR case?
     It needs a location document first.

## Task 1: owner rulings

- **(a) MN Murray County: done.** It is a `FSRS_HAND_TYPING` entry in `R/09b` on UEI VHBBM8QCCG63.
  - CMS MN enrolment: COUNTY OF MURRAY dba Murray County Memorial Hospital, CAH **241319**, organisation type
    GOVERNMENT. HOSPITAL_OR_SYSTEM / DIRECT / LOW, with the CCN and the enrolment record on both rows ($1,535,332 +
    $75,000).
  - The basis cites the Texas hospital-district bridges and records the Ketchikan counter-argument. It is reversible
    by CCN.
- **(b) SCRA PUBLIC: done.** `config/spend_category_cases.csv` VV065 `vendor_public = TRUE`. It stays
  NON_PROVIDER_INTERMEDIARY in the vendor totals, under PUBLIC.
- **(c) KS DCF/KCDD: kept** as session 119 made it. Nothing changed.
- **(d) NM Accenture: the flag stays.** `R/03ad` now runs `nm_aso_findings()` on every probe. It trips when HCA's ASO
  line stops reading "Selection complete announcement will be made by November 30, 2026", or when the page names
  Accenture.
  - HCA's programme page was re-based to 11-19. Every procurement now reads "Selection complete" with a date: CRHSI
    11-20, ASO 11-30, Rooted and Data Hub 12-18, Innovation Fund 12-30. The Stakeholder Advisory Committee reads
    "underway" (12-11). Nobody is named and no amount is printed.
  - The footer prints FY2026 + FY2027 ($422,529,376.25, ALLOTMENT_PLUS_FY2027), which `nm_assert_footer_corroborates()`
    now classes.
  - **News:** HCA's 11-18 release "State selects Guidehouse to establish and operate Center for Rural Health
    Sustainability & Innovation" names partners Hospital Services Corporation and Plexos Group, with **no amount**.
    Guidehouse is already in NM FSRS ($20,100,772.81) and on the verified list, so nothing moves. The news index was
    re-based. The 11-18 Year 2 release ("another $211.04 million") is Year 2 context only.
  - The live probe is quiet (`rhcdf` CHANGED: menu).

## Task 3: probe log since session 119 (11-16 20:00Z → 11-19 13:27Z, 113 lines)

**Moves a dollar:** FSRS (below), OH ORHA (+$1M award, non-hospital). **Held:** WI and SD, as above.

| State | Verdict | Read |
|---|---|---|
| OH 11-18 | TRIPWIRE `hospitals` | One new block: "Training and Technical Assistance Vendor ... $1,000,000 for a rural hospital training and technical assistance vendor. Ohio Rural Health Association". **Extracted** (row 39, IN_KIND_BENEFIT, NOT_HOSPITAL, `hospital_benefiting = Yes`, §7 GHA precedent). The 22, CIN/Hub and maternal lists are unchanged; the page now sums to $93.0M against its "$92,000,000" total (recorded). Hospitals page re-based; the probe now also watches the ORHA block. |
| WI 11-17 | TRIPWIRE `dhs_solicit`, CHANGED `dhs_rhtp` | **AWARD TABLES, HELD** (above). The Reentry Navigation RFA in the trip is Tier 2 / non-RHTP. |
| SD 11-19 | CHANGED ×3 | **+58 contracts, HELD** (above). |
| NM 11-17 | TRIPWIRE | Stage change only (Task 1d). |
| MO 11-18 | TRIPWIRE ×2, YEAR2 | DSS rebuilt its RHTP page. The "Announce select procurement awardees" timeline row went in the redesign, with no award text and no DSS26015 award. The 31-name trip is menu labels. Smart Growth is unchanged (no CMS approval stated). DSS 11-06 says "$75 million in direct awards to 36 unique rural providers", consistent with SMRP $34.6M + Smart Growth $39.4M. Year 2: "$218 million" (11-10). New Tier 2: Digital Backbone/Ambient AI (awards 2027-01-15), RPM (2027-02-12). Nothing extracted. |
| NE 11-18 | TRIPWIRE | A Catalyst Fund menu item welded onto "Timeline and RFA Awardees", plus Year 2 news ($219.2M; Year 1 "fully obligated"; footer $437,776,850.43 = FY2026 + FY2027). The four Awardees notices are unchanged. |
| ND 11-18 | TRIPWIRE | Three headings "Awarded" (Suicide Intervention 5 applicants, Childcare 8, NEMT 13). Nobody is named, no amount. Added to `ND_KNOWN_AWARDED` with the eligible classes (neither is hospitals-only); live probe quiet. |
| VT 11-17 | TRIPWIRE | "Updated as of November 12, 2026". The only row change is the DVHA MOU ($402,500), already excluded (`VT_MOUS`). The 240 agreements / $179,117,448 are identical. **Not re-based**: VT keeps tripping until `VT_UPDATED_TXT` and the archive move. |
| CA 11-18 | TRIPWIRE + CHANGED ×4 | Footer only: $464,745,131.25 = FY2026 + FY2027. The roster is unchanged (108 rows); no executed-agreement marking. Not re-based. |
| WA 11-19 | TRIPWIRE | Link labels. The 11-06 "Year 1 funds 100% obligated" PDF is byte-identical to `recheck/2026-11-13/WA/`. DOH rural provider incentive opportunity is Tier 2. |
| CO, ID, WY, ME, WI | TRIPWIRE | Furniture or Tier 2: CO office-hours events; ID Vendor-Subawardee Resources page (Deloitte PMO; a county subgrant map, DocView 38097, unread); WY "Year One Award Summaries" (same four files) and the open EMS Regionalization RFA; ME UNE CHW RFA. |
| NV 11-17 | TRIPWIRE, YEAR2 | NOFO page is now Budget Period 2 (CBHT WRRAP 12-10, RHIT/FLEX 12-15). Held as Year 2. |
| MS 11-17 | TRIPWIRE, CHANGED ×3, ERROR | Innovative Pilot Q&A/FAQ links; Rural GME Expansion Grant opens 11-24 (Tier 2); no RHTP newsroom headline since 10-21; `dom_completed` SSL (our access). **The footer now prints $410,584,410.13 with "99.96% ... ($410,420,176.37)"**: FY2026 + FY2027, and the "CMS share" is not the federal amount (headline minus a doubled $82,960 match). §0.2's "parse the CMS share" rule fails on this footer. Recorded for a rule update, not patched. |
| LA 11-18 | TRIPWIRE | The block now reads "All RHTP Budget Year 1 award notifications have been completed as of October 30, 2026. Contract execution will be completed in November 2026. RHTP Budget Year 2 anticipated funding announcements - January 2027." The linked deck is byte-identical to `recheck/2026-11-09/LA/`. The parser anchor needs rewriting (not done). |
| NH 11-18 | TRIPWIRE | FHC CAH RFA key dates (award mid-December) and the Primary Care RFA ("Late October/Early November"); nobody named. |
| MT 11-17 | TRIPWIRE | Footer $473,250,028.01 = FY2026 + FY2027 (`ALLOTMENT_PLUS_FY2027`); "Now in its second year". No names. |
| KY 11-16 20:18Z | TRIPWIRE ×2 | Same content session 119 re-based at 19:35 (ran before that commit landed); 20:22Z UNCHANGED. |
| HI, IL, NY, RI, VA | CHANGED | Menu or rotation. NY's Governor 11-16 release prices pools only and names PCDC, **Public Consulting Group** and **Accenture LLP** as implementation partners (vendor leads, no amounts). NY's 11-09 "$28 Million Awarded to New York Hospitals" is NYSERDA (state money, §0.1). VA: VIPC Innovation Fund closed, VFHY Consumer Technology open (Tier 2). |
| FSRS 11-17 | UNCHANGED | The Routine saw no new filings on Tuesday; the 11-19 interactive probe found 56 (below). |
| CMS 11-19 | UNCHANGED | — |

**YEAR2:** MO (11-10 $218M), NV (BP2 NOFOs), NE/NM/CA/MT/MS footers of FY2026 + FY2027. **VENDOR:** IN Cartwheel
Health Services ($637,824, held as a GROW-region filing) and ME Northeastern University (HD80). **LEAD:** none (the
RHTPTRACKER Routine first fires 11-20).

**My error, recorded:** the interactive FSRS probe at 14:18Z logged an `ERROR (evidence guard)` line. That was my SC
re-base writing `data/evidence/SC/` while the probe ran, not the probe writing. The guard worked as designed. The
line stays (the log is append-only); its TRIPWIRE and VENDOR lines from the same run are valid.

## Task 4: FSRS 11-19 archive

The Tuesday Routine logged UNCHANGED. USAspending added **56 filings ($74.1M)** afterwards, found by the interactive
probe.
- **Archived:** `data/raw/usaspending/2026-11-19/` (2,574 subawards, 32 states, $3,458,872,557.59; `USA_EXPECT`
  updated).
- **Applied** through `R/09b --plan/--apply` with the standing pairing, re-filing, negative-amount and duplicate
  checks:
  - **New rows:** ME 38, MN 2, TN 1.
  - **Year 2 holds:** SD's 8 filings (action 11-04/06, $7,498,780) are held as BUDGET_PERIOD_2.
  - **Other holds:** IN 3 GROW-pool members plus Cartwheel; NC Lenoir County (unreviewed candidate).
  - **Matched to existing rows:** TX Muenster HD ($750,000) and ME UNE ($5,000,000) matched priced rows; the
    state amounts stand.
- **MaineGeneral Medical Center** was typed NONPROFIT_CBO by the classifier, because CMS's legal name has no space.
  It is hand-bridged (`FSRS_HAND_TYPING`, DCJGSC4LY1W4): same street address, SAM business type HOSPITAL, CCN
  recorded as CMS prints it, `200039A` (the Prairie Lakes `430005A` precedent; the rural cut refuses a CCN not in
  the enrolment file).
- **Independent duplicate check** (a separate reader, new rows only): **no disagreement** on any of the 41.
  - Six ME recipients have earlier FSRS rows under other subaward numbers (school-administration agreements and a
    peer-support contract). Those are separate actions.
  - The seven RHEF-cohort hospitals in the new rows come from a different (APM) round, and the cohort file is a
    non-award file.
  - Typing matches CMS enrolment on legal name, DBA or address for every hospital row.
  - Noted outside scope: UNE OFI-27-351 ($5M, 10-21) repeats OFI-25-351 ($5M, 06-10) by description. It may be an
    SFY re-filing; no dollar moves because ME row 1 keeps the state's $12M.

## Task 5: rebuild

`R/09b --apply` → `R/07 --apply` → `R/03ar --build` (re-stated to 2,285 / $2,223,153,907.38) → `R/08 --build` →
`R/09c --build --xlsx` → `R/08b --build 2026-11-19 2026-11-19`.

Outputs:
- `data/reference/year1_summary_2026-11-19.csv`
- `output/year1_summary_2026-11-19.xlsx`
- `output/verified_vendor_list_2026-11-19.xlsx`
- `output/completed_states_2026-11-19.{xlsx,html}`

The live vendor URL check was not re-run (`VV_AS_OF` stays 11-16). Pins moved to 11-19: `test_08`, `test_08b`,
`test_output_workbooks`, and CLAUDE.md's partition block and status table.

**Runners above 650k** (`used_tokens`): MT 733,466, SC 703,223 and LA 658,875 were moved to new runners. All three
are on the same environment, model and crons. Old ids are disabled and chained in `routines.csv`;
`runner_moves.csv` and v4 prompts are regenerated (`--check` passes).

| State | New runner | New Routine | First firing |
|---|---|---|---|
| MT | `session_01Y1P5eR8aCxJsteAQQgbbuj` | `trig_01FwfCtRE6GoEX7tUJ1pjYrm` | Fri 11-20 17:40Z |
| SC | `session_01Y1P5eSWPfPKdjkpLZ9CNr3` | `trig_01CKuELN3FRJZQr9ss3Wvfr2` | Thu 11-26 08:30Z |
| LA | `session_01Y1P5ePzNKEBjbNk7ZcVR2Z` | `trig_01T7QtHJswhFqEtfyFJAzUw2` | Sat 11-21 12:50Z |

Also checked: IN 636,823, DE 624,338, KS 613,912, NC 600,412 (not moved). **Merge before Fri 11-20 17:40Z.**

## Calls made under the standing rules (each reversible)

1. **WI and SD held** rather than extracted. Each sits at about $25–26M hospital-shaped and carries a question only
   the owner can settle: WI's "obligated ... subject to CMS review" plus state-agency partners; SD's register begin
   date vs FSRS action date. Both rosters are archived.
2. **FSRS applied although the Routine said UNCHANGED.** The filings existed by 11-19, and the task's intent is a
   current file.
3. **MaineGeneral hand bridge** (LOW, same address).
4. **Northeastern HD80** (V9 on general knowledge, pending an archived location document).
5. **ORHA as IN_KIND_BENEFIT**, not PASS_THROUGH: no sentence moves money to hospitals.
6. **VT and CA not re-based** (noise, read); LA's parser not rewritten; MS footer rule recorded only.

## Open for the owner

- **WI tables:** extract as intents (a new `R/03c?` file typed on CMS WI enrolment), or record as obligations? Are
  the state agencies and UW/WTCS implementation partners award rows (the MN question)?
- **SD +58:** which date governs Year 1 vs Year 2, the state register's begin date or the FFATA action date? Then
  extract (R/03i `SD_PLACEMENT` for 57 contracts, enrolment bridges, the CCBHC pricing for R/03bw).
- **ME Northeastern/Roux Institute** $32.0M: a vendor case?
- **§0.2 rule for FY2026 + FY2027 footers** with a non-federal match (MS): parse which figure?
