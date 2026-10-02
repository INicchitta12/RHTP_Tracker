# Session 85 — the six unread trips, the unexplained CHANGED pages, Alabama in the COMPLETE outputs

2026-10-02. Two owner tasks. Owner rule in force: **report before extracting anything over $10M.**

## 1. The six unread trips (log 09-28 .. 10-02)

| State | What fired | Read | Action |
|---|---|---|---|
| ND | 4 opportunities headed "Awarded" (09-30) | Live page 10-02 now has **six** "Awarded" headings (Behavioral Health Promotion Community Grants joined). No awardee is named on the funding page, the programme page or the HHS newsroom. Rightsizing (FQHCs and CAHs) is a $40,000 TA award with Eide Bailly as the preferred vendor, 41 applicants. | Nothing to extract. The five are recorded in `ND_KNOWN_AWARDED` with the reason; the name diff on both pages catches a roster. Interactive probe: quiet. |
| WV | Two Governor's releases (2026-09-30) | Both read and archived (`data/evidence/WV/2026-10-02_*`). | **Extracted, 7 rows** (below). |
| DE | "Governor Meyer Awards Nearly $23 Million to FQHCs Through RHTP" (09-24) | RHTP: yes (CMS footer, $157,394,963.86, Tier 1). Westside Family Healthcare $11.3M, La Red Health Center $10.1M, Henrietta Johnson Medical Center $1.29M = $22.69M, all rounded. All three are FQHCs in the release's own words. **No hospital.** The money matches DHSS's "Value-based care transformation" line ($24,322,042.48, "rural health care providers and FQHCs"), leaving about $1.63M of that line. | **Held: over $10M.** Archived (`data/evidence/DE/2026-10-02_de_fqhc_award_release.html`). The NEWSROOM baseline is NOT re-based, so the sweep keeps flagging it until the file is written. |
| OK | "Expanding Care: Doulas Program" on Funding Recipients (10-01) | The page carries **three** new rosters: RRR 20 / $39,578,523; Doulas 4 / $647,967.83; Chronic Disease Management 15 / $15,608,845.22. | **Doulas extracted** (`R/03bt`). RRR and CDM are parsed and asserted, but **held: over $10M**. |
| CT | `opm` names 5 new orgs, logged **ERROR** | The five come from OPM RFP #26OPM0202AA (a State Police / DOC staffing study, 9/28/26), posted above the RHTP NOFO on OPM's shared RFP index. Not RHTP. | Furniture added. **Root cause fixed**: see below. |
| NH | FHC T-TAC sentence (09-30) | T-TAC is an RFQ for TA consultants: "The T-TAC is not a grant program or funding track". It names nobody. The sentence was already in the 09-28 baseline. FHC moved the block to the top, which shifted the sentence boundary the diff keys on. Both anchors still hold. | Re-based to `2026-10-02_*` (the 09-28 files are kept). |

Also read: **WI 10-02 14:10Z** ("2026 Intoxicated Driver Program Supplemental Funding"). This is a state OWI appropriation (Wis. Stat. § 20.435(5)(hy)), and its page has no RHTP mention. Added as furniture.

### Why CT logged ERROR

`rhtp_probe_run()` classed a failure as ERROR on an unanchored, case-insensitive
`HTTP|refused|timed out|timeout|resolve|connect`. The organisation string "Department of Correction The State of
**Connect**icut" matched. "HTTP" had the same latent defect: any tripwire quoting an `https://` URL would match.
The test is now `rhtp_probe_verdict()`:
1. A message carrying "THAT IS THE SIGNAL" is always a TRIPWIRE.
2. Otherwise a message is ERROR only on bounded access words (`HTTP 403`, `timed out`, `could not resolve`,
   `connection`, `failed to connect`, `SSL`).

`test_utils_probe_log.R` drives both directions. Only the two CT lines were ever misfiled (`grep ERROR`). The
next CT probe (interactive) then tripped on site chrome: portal.ct.gov's footer prints "Mast: (Full)" or "(Half)"
depending on the serving node. Both variants are now furniture, and a test proves a real awardee still fires.

## 2. West Virginia: 7 new rows

| Awardee | Rows | $ | Type | Hospital |
|---|---:|---:|---|---|
| Community Care of West Virginia | 4 | 1,103,614 (exact; "more than $1.1 million") | FQHC_OR_RHC (release + CMS FQHC enrolment; no hospital enrolment) | No |
| Minnie Hamilton Health Care Center | 3 | 1,700,000 priced ("$1.7 million", rounded) + 2 unpriced | HOSPITAL_OR_SYSTEM: CMS Hospital Enrollments, MINNIE HAMILTON HEALTH CARE CENTER INC dba MINNIE HAMILTON HEALTH SYSTEM, **CAH, CCN 511303**. Exact legal name, MEDIUM. | Yes, DIRECT |

- **Minnie Hamilton.** The same legal entity also enrols an FQHC (CCN 511871). The name "Health Care Center" is
  therefore not a form, and the enrolment decides (§10.2 enrolled-operator row). The release states no contrary
  form ("Per the hospital"), so the session-72 precedence rule does not apply.
- **The unpriced remainder.** The release's "More Than $4 Million" covers three projects and prices one. The
  remainder of more than $2.3M (drone shared-service, AI documentation) is **not divided** (§6.2).
- **File totals.** WV is now 14 rows, 12 priced, $9,248,417. Hospital: 5 rows / $2,924,000.

## 3. Oklahoma: Doulas extracted, RRR and CDM held

`R/03bt_ok_new_rosters.R` reads the page from a separate snapshot (`data/evidence/OK/new_rosters/`, with its own
manifest). It writes `ok_year1_doulas_awardees.csv` as a separate file, so the session-49 row-index overlay on
`ok_year1_awardees.csv` is untouched.

**Doulas:**
- Newman Memorial Hospital, $38,525. CMS CAH CCN 371336, EXACT_LEGAL_NAME. The one hospital row.
- OU Health Sciences Center Board of Regents, $5,445.49. UNIVERSITY_OR_AHC: OU's hospital is enrolled by OU
  MEDICINE INC, a different legal body.
- Tulsa Community Foundation, $240,907. A fiscal sponsor.
- Western Plains Youth and Family Services, $363,090.34. §8 fallback.

**RRR and CDM (for the owner's decision).**
- RRR, $39,578,523:
  - 6 rows / $12,827,791 match a CMS OK hospital enrolment by exact legal name, among them SSM Health Care of
    Oklahoma, McCurtain Memorial, Newman, Memorial Hospital of Texas County and Stillwater.
  - The name rule calls 7 rows / $11.1M hospitals.
  - Several more need a hand-read bridge: Mercy Health Oklahoma Communities, Fairview Regional, Lindsay Municipal
    Hospital Authority, Ascension St. John Jane Phillips.
- CDM, $15,608,845.22:
  - 2 rows / $1,676,857 match exactly: Jackson County Memorial Hospital Authority, and Choctaw Nation.
  - **Choctaw Nation is a tribal hospital enrolment**, which raises the precedence question.
  - Likely hospital rows: Fairview, Wagoner Community Hospital, Cimarron Memorial, and possibly Mercy.
- **A name-rule false positive to watch.** Central Oklahoma Family Medical Center reads "Medical Center" and is
  likely an FQHC.
- These are screens, not codings.
- `OK_PENDING_OPPORTUNITIES` drops Doulas and **keeps RRR and CDM**, so the OK probe keeps tripping until they are
  written.

## 4. The unexplained CHANGED pages

- **SD (3 portal searches): a real change, held.**
  - The RHT series went from 26 to **39 contracts**, $9,223,177 → **$25,816,902**. That is 13 new, +$16,593,725,
    all DOH.
  - Rural Strong grants: Sanford Health $5,442,000; Mobridge Regional Hospital $2,704,989 + $175,000; Fall River
    Health Services $2,699,907; Avera Health $1,565,000; Huron Regional Medical Center $1,258,349; Bowdle Hospital
    $418,563.
  - Other contracts: Avera McKennan $1,585,212 (Maternal Health Hub); Community Healthcare Assoc $349,047; Avera at
    Home $175,000; Huron Clinic Foundation $80,431; Faulkton Area Medical Center $77,432; Black Hills Works $62,795.
  - **Over $10M: not extracted.** The SD portal's organisation tripwire did not fire, because contract rows are
    not page names.
- **ME (4 pages).** The probe compared **file** digests, against the standing rule:
  - `rhef`'s reduced text was identical to the archive, so every CHANGED line since 09-22 was transport noise.
  - `programme` added the 09-02 Advisory deck, which was read: RHEF is still "11 hospitals were invited" and EMR is
    "currently reviewing". It also lists the next meeting, 10-07.
  - `mcd` reworded its "coming soon" blocks.
  - `doe` dropped a side-nav item, which re-welded a name (furniture).
  - The probe now uses a content digest.
- **Newsroom (AZ governor, AZ ahcccs, MT dphhs, NJ doh, MD governor).** All ordinary news flow: ARPA university
  funding, a jobs link, vaccine directives, seven non-health MD releases. AHCCCS had no new link text. Nothing is
  RHTP.

## 5. Alabama in the COMPLETE outputs

`R/03aw` now carries the two subtractable slices of NAMED_HOSPITAL for every COMPLETE state, by the partition's own
row rule. A row in both slices is counted once.

| | AL | AR | GA | FL |
|---|---:|---:|---:|---:|
| NAMED_HOSPITAL | 91 / $104,434,859 | 34 / $128,336,962 | 126 / $90,277,580 | 15 / $49,345,213 |
| ACADEMIC_HEALTH_CENTER | 10 / $18,308,866 | 4 / $17,060,066 | 1 / $0 | 0 |
| GENERAL_KNOWLEDGE | 4 / $3,913,694 | 5 / $19,690,889 | 0 | 0 |
| Floor (% of published) | 52.6 | 63.0 | 45.8 | 26.2 |
| Floor excl. both | **41.4** | 44.9 | 45.8 | 26.2 |

**Notice of intent: Alabama is NOT one.**
- Both Governor's releases say "were awarded" and "was awarded".
- ADECA's manual refers only to "the applicable subaward agreement".
- None of the three ADECA/ARHTP pages carries intent language.
- No AL row is `NOTICE_OF_INTENT_TO_AWARD`.

The stage field now says this explicitly. Arkansas is the COMPLETE state whose rows are intents. Neither state has
an executed agreement on the record.

OK's status row now counts the Doulas file and says RRR and CDM are published but not extracted, so its 2.2%
understates publication. WV's row is now 14 / $9,248,417.
