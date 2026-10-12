<!-- Session 98, Task 4: read-only agent findings, kept verbatim as the record behind docs/session98_checkin_ahap_nm_probe_log.md §4. Live reads are of 2026-10-12, not the logged dates. -->

# Task 4c: NEWSROOM sweep (10-08 CHANGED) and CMS monitor (10-08 NC, 10-12 IA/LA)

Read-only. Live pages were fetched into memory with the repo's agent (`NW_USER_AGENT`) and reducer (`rhtp_watch_reduce()`, `nw_headlines()` loaded from `R/03bg` without running it). Each page was diffed against the archive file `NW_PAGES` names. Live copies are in `scratchpad/task4c/`, and the raw diff log is `scratchpad/task4c/nw_diff.txt`. No tracked file was written, and `git status` is clean.

## Headline: no item changes a hospital dollar figure

Nothing below moves any cell of the Deliverable 1 table or the partition block. No release or newsroom item names a hospital recipient with an amount that our files lack.

Two items carry new Tier 3 information, but they name no recipients and have no hospital recipient:

- **NC (CMS 10-07 and NCDHHS 10-07):** $17M of behavioral-health awards, including $4M to three unnamed LME/MCOs.
- **LA (CMS 10-09):** up to $20M to colleges and $5M for career pathways. Both are new to our files and unnamed. The release's $12.7M to 53 providers is already carried.

One item is a process gap and is not a figure. **AZ AHCCCS** published a new RHTP solicitation item, and the newsroom tripwire is structurally blind to it (see AZ).

The probe log has **no NEWSROOM lines after 2026-10-08T16:52Z** (10-09 through 10-12 are empty; the sweep fires on Mon/Thu). The last lines on each page are the 10-08 lines listed here.

---

## Task B: CMS monitor

### NC: CMS 2026-10-07, "More Than $17 Million for New Mental Health Clinics, Mobile Crisis Teams, and Expanded Addiction Treatment in North Carolina"
(Archived by the Routine at `data/raw/cms/2026-10-08/newsroom/releases/...17-million...html`. The state counterpart is NCDHHS's 2026-10-07 release, read live.)

- CMS: *"$4 million for three new mental health clinics; $3 million to expand access to medications for opioid use disorder through stationary medication units in five counties; and $4 million to send mobile crisis teams to six additional counties ... An additional $6.7 million ..."* No recipient is named.
- NCDHHS: *"NCDHHS has awarded $4 million to three Local Management Entities/Managed Care Organizations (LME/MCOs) for Certified Community Behavioral Health Clinics"*. Neither publisher names the three. It also lists $3M MOUD ("Zing Satellite Technology", five counties), $4M MORES teams, $3M Coordinated Specialty Care (FEP), $2.9M Rural Crisis Partnerships, and $800,000/yr to expand NC MATTERS (*"a federally funded collaboration among NCDHHS, UNC, and Duke"*; the recipient is not stated).
- **Classification: NEW AWARD INFORMATION.** It is Tier 3 for the $4M CCBHC line ("has awarded") and plan or Tier 2 for the rest. No line names a recipient.
- **Hospital figure: no change.** The CCBHC recipients are LME/MCOs, which code as `MANAGED_CARE_ORGANIZATION` and are never a hospital type. For NC MATTERS, UNC/Duke involvement is a collaboration, not a stated recipient (§0.3: participation is not receipt). NC stays at 2 / $0 and NC SBHC at 1 / $0.
- None of these six channels is in `nc_year1_status.csv`. Our NC files carry MIH, ROOTS Hub Leads, the Diabetes Prevention Program, SBHC and the Innovation Fund.
- **Proposed action:** add these six behavioral-health channels to `nc_year1_status.csv` as status rows with no amount column: CCBHC as AWARDED, with three unnamed LME/MCOs, and the others as announced. Archive the NCDHHS release. Extract only when the three LME/MCOs are named. That would add MCO rows and $0 to the hospital figure. Separately, NC's 10-10 TRIPWIRE on `trillium` is unread (out of scope here).

### IA: CMS 2026-10-09, "$209 Million to Expand Advanced Medical Care, Maternal Telehealth, and Cancer Prevention Across Rural Iowa"
- The $209M is **Tier 1**. CMS says *"Today's announcement highlights the overall funding amount awarded to Iowa for fiscal year 2026"* and *"Iowa has committed its full $209 million"*. The allotment anchor is $209,040,064.
- Other text: *"seven major medical equipment installations supporting 44 advanced procedures"* and *"health information exchange tools connecting more than 100 facilities"*. These are counts with no names and no amounts.
- The only hospitals named appear in congressional quotes: *"Mahaska Health in Oskaloosa"*, *"a new CT scanner at Washington County Hospital"* (Miller-Meeks) and Wayne County (Nunn). All are **already in `ia_year1_awardees.csv`** (rows 51/52/137, 102/181, 103/157/160) as unpriced intents.
- **Classification: NOISE** (an allotment restatement, plus recipients we already carry).
- **Hospital figure: no change.** IA stays at 218 / $0. A congressman's quote is not a source that could price a row.
- **Proposed action:** none beyond the CMS row already written. Do not let the $209M enter any Tier 3 figure.

### LA: CMS 2026-10-09, "$37.7 Million to Train and Recruit More Rural Healthcare Workers Across Louisiana"
- Quote: *"up to $20 million to connect Louisiana's public universities and community and technical colleges with rural healthcare providers ... $12.7 million to help 53 rural providers recruit and retain physicians, nurses ... The additional $5 million will create healthcare career pathways across 39 campuses"*. CMS also says *"Today's announcement is one part of the larger overall funding amount awarded to Louisiana"*.
- **The $12.7M to 53 providers is the Rural Clinician Credit Bank**, which is already carried. `la_year1_status.csv` gives *"$12,701,996 awarded across 53 awards as of 8/28/26"*, and `la_year1_awardees.csv` has 5 named rows plus 1 NOT_YET_NAMED row for 48. CMS adds no names.
- **The "up to $20M" universities/colleges line and the "$5M across 39 campuses" line are new to our files.** They match LDH's plan items "New education/training pathways" and "Grow Your Own" on the archived 10-05 programme page. Neither is a channel in `la_year1_status.csv`. "Up to" makes the $20M a ceiling, and no recipient or institution is named.
- **Classification: NEW AWARD INFORMATION** (unnamed). The $12.7M is a duplicate of a carried figure.
- **Hospital figure: no change.** LA stays at 1 / $1,500,000. The new lines' recipients are colleges and universities or high-school pathways, so they would not be hospital rows even once named. The RCCB count already sits outside every bucket (§7, "a count of hospital awards with no names").
- **Proposed action:** add two status rows to `la_year1_status.csv` (education/training pathways at "up to $20M", Grow Your Own at $5M / 39 campuses), with no amount column and the CMS release as evidence. Look for an LDH, Board of Regents or LCTCS announcement that names the institutions. No extraction now.

---

## Task A: NEWSROOM sweep pages (10-08T16:51Z CHANGED)

For every page, the repo's tripwire rule (a new headline matching NW_RHTP and NW_AWARD) finds **no hot headline**.

### AZ
- **AZ:ahcccs: NEW SOLICITATION** (the only RHTP item in the sweep). This is a new item dated 09/25/2026: *"RHTP Funding Opportunities Now Available: AOEO Provider Retention & Wellbeing Microgrant & Transition to Practice ... AOEO has officially released two Request for Grant Applications (RFGAs) for the Provider Retention & Well-Being Microgrant and Transition to Practice Program."*
  - The item page's footer reads *"financial assistance award totaling $166,988,956 with 100 percent funded by CMS/HHS"*. That equals AZ's allotment to the dollar, so it is Tier 1 and is not a pool figure.
  - No awards or recipients. Hospital figure: no change. AZ has no award file and is QUEUED.
  - **Tripwire gap:** the sweep never saw this item. On AHCCCS the headline is plain text, and only "Read more..." is an `<a>`, so `nw_headlines()` (anchor text only) reports 0 new headlines. The item would have matched NW_RHTP+NW_AWARD ("RHTP ... Funding") had it been an anchor. AZ:ahcccs has logged CHANGED on 10-01, 10-05 and 10-08 for this item.
  - **Proposed action:** re-base `AZ:ahcccs` after a human reads the item. Owner decision: should AHCCCS headlines be read from the reduced text (or the item-title elements) rather than anchors, so that a future AZ award item can trip? Optionally record the AOEO RFGAs as AZ solicitations.
- **AZ:governor: NOISE.** New headlines: "Statewide Effort to Secure United States Space Academy", "ARPA Allocation to Preserve Funding for Arizona's Public Universities". **Action:** re-base.

### DE
- **DE:news: NOISE.** There are 21 new headlines of rotating news, for example *"Delaware awards $7.1 million to strengthen early literacy instruction"* (education), an ACA refund notice, and a Sandoz settlement. The only RHTP text on the page is the known 09-24 *"Governor Meyer Awards Nearly $23 Million to FQHCs Through Rural Health Transformation Program"*, which is already extracted (`R/03bu`). **Action:** re-base.

### FL
- **FL:governor: NOISE.** 17 new headlines. The two health-adjacent ones are *"Appoints Three to the Lower Florida Keys Hospital District"* (board appointments) and *"Results of Florida's Medicaid Integrity Initiative"*. Neither is RHTP. **Action:** re-base.

### IA
- **IA:governor: NOISE.** 10 new headlines (harvest/diesel proclamations, MEGA steel mill, disaster proclamations). None is RHTP. The CMS IA release (above) is not mirrored here. **Action:** re-base.

### ID
- **ID:governor: NOISE.** 4 new headlines (revenue, harvest EO, jobs, forest management). **Action:** re-base.

### MD
- **MD:governor: NOISE.** 10 new headlines. The one with a rural angle is *"Governor Moore and Maryland Higher Education Commission Secure $2.38 Million Federal Grant to Connect Rural Students Directly to Careers"*, an MHEC higher-education grant that the headline does not tie to RHTP. Others: a $60M victim-services investment, Anduril, McLaren. **Action:** re-base. Optionally open the MHEC item to confirm its funder.

### MT
- **MT:dphhs: NOISE.** The only new anchor is "Work4DPHHS.com". The reduced text is identical in length (401/401). This is page furniture. **Action:** re-base.

### NE
- **NE:governor: NOISE.** 10 new headlines (economic report, diesel EO, emergency declaration, Governor's Summit, Czech president). **Action:** re-base.

### NJ
- **NJ:doh: NOISE.** 6 new headlines (doula trainings, mosquito precautions, vaccine directives, each in English and Spanish). The RHTP snippets on the page are the same 2 as in the archive. **Action:** re-base.

### NV
- **NV:governor: NOISE.** 7 new headlines (red-dyed diesel, Amperesand, school funding, Digital States 'A'). **Action:** re-base.

### TX
- **TX:governor: NOISE.** 8 new headlines, including *"Over $20 Million In Career Training Grants Across Texas"* (TWC skills grants, not RHTP) and *"Dedicates The Dr. Ron A. McMurry MediPlex"* (a facility dedication). **Action:** re-base.
- **TX:hhsc: NOISE.** 2 new headlines (Early Childhood Intervention, Fentanyl Poisoning Awareness Month). **Action:** re-base.

### UT
- **UT:governor: NOISE.** 6 new headlines (disaster declaration, AI executive order, schedule, Read-a-Thon, a parole board appointment, *"Governor's Award for Excellence"* for state employees). **Action:** re-base.
- **UT:dhhs: NOISE.** 2 new headlines (a kratom/"cat's claw" overdose warning, EN/ES). **Action:** re-base.

---

## Summary table

| Item | Class | Hospital $ change | Proposed action |
|---|---|---|---|
| NC CMS + NCDHHS $17M behavioral health | NEW AWARD INFORMATION (unnamed; $4M to 3 LME/MCOs) | none (MCOs; NC MATTERS recipient unstated) | add 6 status rows; archive the NCDHHS release; extract when the MCOs are named |
| IA CMS $209M | NOISE (Tier 1; named hospitals already carried) | none | none |
| LA CMS $37.7M | NEW AWARD INFORMATION (unnamed; $12.7M = RCCB already carried; up to $20M + $5M new) | none | add 2 status rows; look for an LDH/Regents/LCTCS roster |
| AZ:ahcccs AOEO RFGAs | NEW SOLICITATION (footer = Tier 1 allotment) | none | re-base; owner: tripwire reads anchors only, so AHCCCS headlines are invisible |
| Other 14 pages | NOISE | none | re-base after reading |
