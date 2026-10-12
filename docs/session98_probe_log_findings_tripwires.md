<!-- Session 98, Task 4: read-only agent findings, kept verbatim as the record behind docs/session98_checkin_ahap_nm_probe_log.md §4. Live reads are of 2026-10-12, not the logged dates. -->

# Probe log TRIPWIRE / ERROR review, 2026-10-07 .. 2026-10-12

Read-only investigation on 2026-10-12. Each state's own `*_probe()` function was
called in memory (sourced, never through `rhtp_probe_run()`, so nothing was logged).
Live pages were compared with their committed archives using `rhtp_watch_reduce()`
and a line-level `html_text2()` diff. All of it was written to the scratch dir only.
No `--probe`, `--fetch`, `--build` or `--apply` was run, and nothing was committed.

**Later lines.** No state below has a later line in the log for the same page. The
one exception is AL: an interactive line at 10-08 15:17Z shows `governor` CHANGED
with no trip. No other firing has gone quiet yet. Each item is therefore judged on
today's live read.

---

## A. Items that change a hospital dollar figure

### OK — 10-08 18:15Z TRIPWIRE: "'Behavioral Health Integration' now appears on the Funding Recipients page" (R/03t; extractor R/03bt)

**Classification: NEW AWARD INFORMATION. Two new rosters and one withdrawal.**

The live `rhtp-funding-recipients.html` was diffed against
`data/evidence/OK/probe_baseline/2026-10-02_ok_rhtp_funding_recipients.html`. The
page's own index now reads "Expanding Care: Community Paramedicine" and
"Behavioral Health Integration" above the RRR, Doulas, CDM, ROOTS and Microgrant
anchors. The page says "Last Modified on Oct 12, 2026".

1. **Behavioral Health Integration – Medications for Opioid and Alcohol Use
   Disorder.** "Behavioral Health Program: List of Funding Recipients". There are 3
   priced awards totalling **$1,228,012.70**, against the $2.8M anticipated in the
   Q2 report:
   - "Oklahoma State University Center for Health Sciences (OSU-CHS) – SPARK Rural Health Addiction Medicine Expansion Program, $137,841.17"
   - "Mercy Health Oklahoma Communities – Virtual Substance Use Recovery Program (vSURP), $90,171.53"
   - "Andor Health, LLC, $1,000,000"
2. **Expanding Care: Community Paramedicine (EMS & Community Paramedicine
   Vehicles).** Recipients are named and **no amounts are given**. The pool is the
   $3.675M in the Q2 report.
   - "Organizations receiving ambulance funding:" has 38 entries. "Town of
     Cheyenne" appears twice.
   - "Organizations receiving Community Paramedicine vehicle funding:" has 13
     entries. Of these, "Four vehicles were funded out of the NOFO funding; Nine
     were funded out of a separate funding opportunity reserved for teams trained
     by RHTP funds."
   - The hospital-shaped recipients are:
     - "Baptist Healthcare of Oklahoma, LLC d/b/a INTEGRIS Miami Hospital"
     - "Newman Memorial Hospital, Inc."
     - "Northeastern Health System"
     - "Purcell Municipal Hospital", which appears in both lists
     - "The Choctaw Nation of Oklahoma", which is on CMS hospital enrolment
       (CCN 370172) under the session 71/87 precedent
3. **Withdrawal.** The RRR roster no longer carries "Keetoowah Economic
   Development Authority, $1,123,500" ("Deploy three telehealth care stations at
   retail pharmacies..."). It is row 10 of `ok_year1_rrr_awardees.csv`, typed
   NONPROFIT_CBO, and it is not a hospital row.

**Provenance.** The page carries the CMS footer ("This publication is supported by
the Centers for Medicare & Medicaid Services ... financial assistance award
totaling $223,..."), which is the OK allotment, Tier 1 context. RHTP is named
throughout. **§6.2 date test:** pass. These are newly posted awards on a page last
modified 2026-10-12, under NOFOs issued after the 2025-12-29 NOA.

**Hospital effect (estimate):**
- **BHI: NAMED_HOSPITAL +1 row / +$90,171.53.** Mercy Health Oklahoma
  Communities, Inc. is already typed HOSPITAL_OR_SYSTEM (LOW, general knowledge)
  on its RRR and CDM rows. OSU-CHS ($137,841.17) is UNIVERSITY_OR_AHC unless a CMS
  OK enrolment matches its legal name, which it is unlikely to; queue it. Andor
  Health, LLC ($1,000,000) is a telehealth company: VENDOR_OR_CONTRACTOR or OTHER.
- **EMS / CP: NAMED_HOSPITAL about +6 rows / $0.** That is INTEGRIS Miami,
  Newman, Northeastern Health System, Purcell ×2 and Choctaw Nation. No amounts
  are published, so the pool is never divided (§6.2).
- **RRR withdrawal.** OK RRR falls from 20 rows / $39,578,523 to 19 /
  $38,455,023. The hospital figure is unchanged at 10 / $21,099,804.

**Proposed action (owner):**
- Extract both rosters with R/03bt into their own files, for example
  `ok_year1_bhi_awardees.csv` and `ok_year1_ems_cp_awardees.csv`.
- Type every row on CMS OK enrolment, and chain R/03bj's overlay.
- Record Keetoowah as withdrawn, either by removing the row and recording the
  withdrawal or by giving it an explicit withdrawn status. Do not leave it silently
  in the file.
- Then re-base the probe (`R/03t --probe-baseline`). Update the Deliverable 1 rows
  and the partition block in the same commit.

---

## B. New award information that does not move a dollar (yet)

### ND — 10-07 09:22Z TRIPWIRE: CAH Workforce Retention "Awarded" (R/03ba)

This line was already read by session 94 (`docs/session94_*` §3) as **awarded with
nobody named**. Today's live read confirms that the section still names nobody:
"Workforce Retention Funding for Critical Access Hospitals and Their Owned and
Operated Clinics – Awarded | 36 Applicants", followed only by "Learn more...".

**However, the probe now trips on a different heading that has not been read:**
"Train In Place – Closed (45 Applicants)" now reads "**Train In Place – Awarded | 45
Applicants**". That section is the RFP and FAQ text only, with no awardee and no
amount. The eligible class is health-care employers and education institutions, so
it is not hospital-only. Train In Place is still **missing from
`ND_KNOWN_AWARDED`**, so the next ND firing will trip again. The other headings
that flipped since the 09-23 archive (Zero-Hour PE, Community Gardens, BH
Promotion, Rightsizing, Mobile Mammography) are already in the known list. The
programme page is reduced-identical to its archive.

- **Classification:** NEW AWARD INFORMATION (stage only; nobody named).
- **Hospital $:** none. When names appear, Workforce Retention is hospital money
  in full (`ND_HOSPITAL_ONLY_ROUNDS`); Train In Place is not.
- **Action:** add "Train In Place" to `ND_KNOWN_AWARDED` with the sentence "Read
  2026-10-12: heading 'Awarded | 45 Applicants'; section names no awardee and
  prints no amount". The name diff stays as the roster catch.

### NH — 10-07 18:12Z TRIPWIRE: FHC no longer says "...Coming Soon" (R/03bm)

**Classification: NEW SOLICITATION.** The CAH and Acute Care Hospital RFA moved
from Coming Soon to **Open**. The new text is: "Critical Access Hospital (CAH) and
Acute Care Hospital Open ... Application Portal Opens Late October 2026 / Initial
Application Deadline (Priority Cohort) November 12, 2026, 5:00 PM ET / Notification
of Award (Initial Cohort) Mid December 2026 / Rolling Application acceptable while
funds are available". Documents include "Download RFA" and "FHC Critical Access
Hospital (CAH) & Acute Care Hospital Appendices".

Also on the page:
- "Home Health and Community Care RFA" is new as Coming Soon ("RFA Expected to be
  Published mid-October").
- The T-TAC RFQ was updated 10/6/2026, adding three Core Areas.
- No subrecipient is named.

- **Hospital $:** none now. This RFA is hospital-only by its title. When FHC
  awards (mid-December), each award is to a named hospital and should be coded
  per award (DIRECT, via FHC as the pass-through administrator).
- **Action:** replace `NH_ANCHORS[1]` with "Notification of Award (Initial
  Cohort) Mid December 2026". Then re-base `fhc` (`R/03bm --fetch --force` for
  fhc) and archive the CAH RFA PDF. Add a dated watch for "mid-December 2026".

---

## C. NOISE (menu, layout, date, non-RHTP)

### NE — 10-07 10:34Z TRIPWIRE: program_page names "RAI Assessment Information Special Health Care Needs State Unit on Aging Olmstead Plan Beatrice State Developmental Center Contact Us Reports" (R/03r)

This is DHHS side-navigation text. The Routine ran from `main` at 10:34Z. Session
94's `NE_NAME_SCOPE` fix ("What you need to know Page Content" to the Medicaid side
nav) merged at 14:55Z (PR #99), after the firing. Run in memory today with that
fix, `ne_probe()` **passes**. No NE line has been written since.

- **Hospital $:** none.
- **Action:** none. It is already fixed by session 94, and the next NE firing
  should be quiet.

### WA — 10-08 10:13Z TRIPWIRE: programme page SUBAWARD footer no longer parses (R/03bc)

Still failing today. HCA rotated the expired RNEP item off the programme page's
news list. The removed text includes "Nursing informational webinar for potential
community partners ... The application cycle will be open from September 10
through October 2" and the footer "Disclaimer: This program is supported by
CMS/HHS through a subaward as part of a financial assistance award of
$181,257,515.06 ... with $3,500,000 and 80 percent funded by CMS/HHS and $914,538
and 20 percent funded by other source(s)." It was replaced by "New webpages for the
Department of Health's RHT Program work ... Advisory Committee / Work with Tribes /
DOH's activities". The rest of the diff is Apple Health and PEBB/SEBB menu wording.

- **Classification:** NOISE. This is a dated item that expired; it is not a
  re-wording and contains no award.
- **Hospital $:** none.
- **Action:**
  - `wa_assert_footers()` should run on the ARCHIVED programme text, not the live
    text. As written it will fail on every firing, and a re-base would make it
    fail on `--validate` as well.
  - **Do not overwrite** `recheck/2026-09-23/WA/hca_rhtp_programme.html`.
    R/03bd's closure assertion ("with $3,500,000 and 80 percent funded by CMS/HHS")
    reads that file.
  - Re-base the probe to a new dated file (for example
    `data/evidence/WA/probe_baseline/2026-10-xx_hca_rhtp_programme.html`) and
    point `WA_PAGES$file` at it.
  - Optionally watch the new DOH RHT pages.

### AL — 10-08 14:42Z TRIPWIRE: 'governor' "1 new sentence" (R/03bs)

**Confirmed explained.** `docs/session84_al_complete_probe_log_review_ms_window.md`
(lines 149–160) records this first firing as a false trip. It was caused by
session 84's own defect: the "sentence" was the Governor's whole page chrome. The
fix, `al_governor_headlines()`, splits the index on dated items and is on the
merged branch (commit 931ef65). The interactive re-probe at 10-08 15:17Z logged
`governor` CHANGED with no trip.

- **Classification:** NOISE.
- **Hospital $:** none.
- **Action:** none.

### KY — 10-08 19:43Z ERROR: HTTP 401 (R/03af)

Today the host answers **200** on the project agent, so the 401 was transient.
The in-memory probe now fails on the **name tripwire** instead:
`'programme' NAMES ... "Updates and Progress Notice of Award Understand Rural
Health in Kentucky Contact Us"`.

The diff is the top menu only: "Our Approved Plan" became "Our Plan, Updates and
Progress", and a "Reports and Documents" link was added. That page
(`/Pages/ReportsandDocuments.aspx`) was read. It holds only the Project Narrative
PDF and "Updates and reports will be posted here as the program moves forward". It
names no recipient.

- **Classification:** ACCESS for the logged line, and NOISE for what the next
  firing will hit.
- **Hospital $:** none.
- **Action:** re-base `programme` (`R/03af --fetch --force`, programme key), or
  add the menu string to KY furniture with the sentence above. Consider adding
  `ReportsandDocuments.aspx` as a watched page.

### VA — 10-09 10:21Z TRIPWIRE: vhcf no longer says "...October 14, 2026, for Provider Productivity" (R/03bb)

The only change on the page is a re-date by one day. The old text was "...by
September 30, 2026, for Provider Interoperability and October 14, 2026, for
Provider Productivity." The new text is the same sentence with **October 15,
2026**. The VHCF news index is reduced-identical to its 10-05 archive, so Provider
Productivity has not been announced.

- **Classification:** NOISE (date).
- **Hospital $:** none yet.
- **Action:** update `VA_ANCHORS$vhcf` to "October 15, 2026" and re-base `vhcf`.
  The vhcf_news index still catches the award post.

### WV — 10-09 11:35Z TRIPWIRE: "West Virginia Awarded $195,825 Federal Grant to Upgrade WIC Clinics with Needle-Free Screening" (R/03av)

The release (dated October 2, 2026) says "a new $195,825 federal infrastructure
grant from the USDA Food and Nutrition Service" for Masimo Pronto devices in
WIC clinics. It does not mention RHTP or CMS in the body; "RHTP" appears only in
the site navigation. The recipient is DH's own Office of Nutrition Services.

- **Classification:** NOISE (non-RHTP; §0.1 wrong programme).
- **Hospital $:** none.
- **Action:** add an exclusion for the slug
  `west-virginia-awarded-195825-federal-grant-upgrade-wic-clinics-needle-free-screening`,
  justified by the USDA FNS sentence above. The check has no exclusion list today,
  so this is a small code change: `known` is `WV_SLUG`, which holds the RHTP
  releases only. Without it, every WV firing trips while the item stays on the
  first page of the index.

### WY — 10-09 21:12Z TRIPWIRE: programme names "Year One Award Approvals View Year One Award Approvals Project and Budget Narratives" (R/03aj)

The "Program News And Updates" block (the 08-11 Advisory Committee meeting notice)
was replaced by a "Year One Award Approvals / View Year One Award Approvals"
button. The button links to Drive file `1jqfbHzZPrX-_xT-uLg3TFXorckp3b3uX`. That
file was downloaded to scratch and is **byte-identical** to the archived
`2026-09-03_wy_advisory_committee_award_approvals_2026-08-11.pdf` (SHA-256
`30aed248…5b372`), which is already extracted. The timeline was retitled "Year
One", and "establishment of Perpetuity" was dropped from one line. The Drive folder
link is unchanged.

- **Classification:** NOISE (a link to a document already extracted).
- **Hospital $:** none.
- **Action:** add "Year One Award Approvals View Year One Award Approvals Project
  and Budget Narratives" to WY furniture, justified by the SHA match above. Then
  re-base `programme`. Committee meets 11-04/05; obligation is end of October.

### NC — 10-10 10:55Z TRIPWIRE: trillium names "NC Rural Health Transformation Program" (R/03ah)

The new text is a "Rural Ready Roundtable" notice: "a quarterly public meeting for
NC ROOTS Hub Region 2. Get updates on the NC Rural Health Transformation Program in
your region ... Monday, October 19, 2026". The "name" is the programme's own name.

The Advisory Board block changed from "Application Process Now Closed" to a heading
"Region 2 Advisory Board Members". In the served HTML that heading has **no names
under it**, and an advisory board is not a recipient in any case.

The five Region 2 RFAs are unchanged, all "Closed - Under Review", with award
notification "September 2026" or "September/October 2026". One of them is "LOCATe
Implementation", for "eligible birthing hospitals", and is worth watching.

- **Classification:** NOISE.
- **Hospital $:** none.
- **Action:** add "NC Rural Health Transformation Program" to
  `NC_NAME_FURNITURE` (trillium), justified by the roundtable sentence. Then
  re-base `trillium`. If Trillium posts the board member list, it is still not an
  award list.

### CA — 10-10 17:08Z TRIPWIRE: funding scope anchor not found (R/03ab)

This was not reproducible today. `ca_probe()` in memory **passes**. The live
`funding` page reduces identically to the 2026-09-02 archive, and the breadcrumb
"California Rural Health Transformation (CalRHT)" is present. The page the Routine
received on 10-10 was probably a transient variant or an error page. The R/03ab
header already records that HCAI serves two legitimate variants.

- **Classification:** NOISE (transient layout) or ACCESS. It cannot be
  reconstructed from here.
- **Hospital $:** none.
- **Action:** none now. Confirm at the next CA firing (Wed or Sat). If it
  recurs, the missing-anchor refusal could be reported as ERROR rather than
  TRIPWIRE.

---

## D. ACCESS

### MS — 10-09 09:41Z TRIPWIRE: "Empty reply from server [medicaid.ms.gov]" (R/03ak)

This still happens today on the project agent, on bare `Mozilla/5.0` and on
curl's default agent. `https://medicaid.ms.gov/...` returns an empty reply (curl
52), while `http://` answers 302 to https. `www.ms.gov` answers 200. It is an
access failure on DOM's host (the `dom_completed` control page), not a statement
about Mississippi. Record it as **UNKNOWN**, not NO.

**Verdict mislabel.** It was logged as TRIPWIRE, not ERROR, because "Empty reply" /
"Server returned nothing" is not among `rhtp_probe_run()`'s access words. That is
worth a one-line fix: add `empty reply|returned nothing` to the ERROR classifier.

The rest of the MS probe never ran, so the other pages were read by hand:
- The **funding** page has new solicitations only. These are the Innovative Pilot
  Program (opens 10/14, already read in session 94) and a new MSDH **Statewide
  HIE/HDU RFP** ("Posted At: October 2, 2026; Due Date: Tuesday, November 3,
  2026", vendor procurement, Tier 2). Closed opportunities (EmPATH, WEI, TAPS,
  HTAM, BRIDGE) moved to a "Closed Funding Opportunities" page.
- The Governor's **newsroom** has no RHTP award after 09-14. The newest item is
  dated October 1, 2026.
- The WEI and EmPATH window (10-14 .. 10-29) is still open.

- **Hospital $:** none.
- **Action:** add the empty-reply wording to the ERROR classifier. Watch DOM's
  host. Consider archiving the new "Closed Funding Opportunities" page and noting
  the HIE/HDU RFP as a solicitation.

### KS — 10-12 08:15Z ERROR: HTTP 403 KDHE (R/03o)

This is the known Cloudflare block of this environment (session 95/96 notes). It
was re-confirmed today: 403 on the project agent.

- **Classification:** ACCESS. KDHE's state is UNKNOWN.
- **Hospital $:** none.
- **Action:** none beyond the standing session-95 item (re-base `program_page`
  from a session KDHE serves).

---

## Summary table

| State | Line | Class | Hospital $ change | Proposed action |
|---|---|---|---|---|
| OK | 10-08 TRIPWIRE | NEW AWARD INFORMATION (BHI 3 priced $1,228,012.70; EMS/CP 38+13 named, no $; Keetoowah RRR $1,123,500 withdrawn) | **Yes: NAMED_HOSPITAL ~+7 rows / +$90,171.53**; OK RRR file −$1,123,500 (non-hospital) | Extract two rosters (R/03bt), type on CMS OK enrolment, record withdrawal, re-base |
| ND | 10-07 TRIPWIRE | NEW AWARD INFORMATION (stage only; Workforce Retention and now Train In Place "Awarded", nobody named) | No | Add "Train In Place" to `ND_KNOWN_AWARDED` |
| NH | 10-07 TRIPWIRE | NEW SOLICITATION (CAH/Acute RFA open; award mid-Dec) | No (future hospital-only round) | New anchor, re-base `fhc`, archive RFA |
| NE | 10-07 TRIPWIRE | NOISE (side nav; fixed session 94) | No | None |
| WA | 10-08 TRIPWIRE | NOISE (expired RNEP item removed) | No | Footer assert on archive; re-base to NEW file (keep 09-23 copy for R/03bd) |
| AL | 10-08 TRIPWIRE | NOISE (explained session 84) | No | None |
| KY | 10-08 ERROR | ACCESS (transient 401); now NOISE menu trip | No | Re-base `programme` or furniture |
| MS | 10-09 TRIPWIRE | ACCESS (empty reply, medicaid.ms.gov) | No | Classify empty reply as ERROR |
| VA | 10-09 TRIPWIRE | NOISE (Oct 14 → Oct 15) | No | New anchor, re-base `vhcf` |
| WV | 10-09 TRIPWIRE | NOISE (USDA FNS WIC grant, non-RHTP) | No | Slug exclusion with USDA sentence |
| WY | 10-09 TRIPWIRE | NOISE (link to already-extracted approvals PDF, SHA match) | No | Furniture + re-base `programme` |
| NC | 10-10 TRIPWIRE | NOISE (programme's own name in a roundtable notice) | No | Furniture + re-base `trillium` |
| CA | 10-10 TRIPWIRE | NOISE/transient (not reproducible; page reduced-identical today) | No | None; confirm next firing |
| KS | 10-12 ERROR | ACCESS (Cloudflare 403) | No | Standing item |
