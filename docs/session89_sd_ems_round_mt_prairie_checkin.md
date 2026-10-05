# Session 89 — SD's $7.2M EMS round, MT Prairie County closed, branch check

2026-10-05. Four owner tasks.

## 1. Branches on `main`

- `claude/brave-clarke-aecd2i` (session 88) is on `main` (PR #92, merge `37ca01f`).
- `claude/compassionate-heisenberg-6609c9` (session 84 check-ins, 10-02 and 10-04) was NOT on `main`: two
  commits, `CLAUDE.md` + `docs/session84_*` only, merging cleanly. It is merged into
  `claude/bold-lamport-qzu37s` and reaches `main` with this branch.
- The full suite was run on `origin/main` (`37ca01f`) in a detached worktree; the result is in the session
  report.

## 2. South Dakota's $7.2M EMS round — READ, NO ROSTER

Sources read live 2026-10-05 (not archived; nothing was extracted):

- **CMS, 2026-10-02** (archived by the CMS Routine at
  `data/raw/cms/2026-10-05/newsroom/releases/trump-administration-announces-7-2-million-expand-ambulance-based-telemedicine-upgrade-emergency.html`):
  *"deliver $7.2 million to 25 projects led by local ambulance services, hospitals, community organizations,
  education partners, and statewide EMS support organizations."* Names no project or recipient.
- **Governor, 2026-10-03** (`news.sd.gov` sys_id `94f44f08973fc3507fc1b480f053afe7`, read through
  `kb_view.do?sys_kb_id=`): *"approximately $7.2 million in Rural Health Transformation (RHT) funding for 25
  projects"*, part of the *"Enhancing Sustainable Emergency Medical Services initiative"*. Names nobody.
  "Approximately" makes the round figure ROUNDED in the state's own source.
- **DOH RHT programme page, RHT Resources & FAQs, EMS & Trauma page**: link lists read. No award list. The
  09-15 Funding Forecast shows the EMS initiative as RFP **26-09RHT-023**, OPEN at that date.
- **open.sd.gov**: the RHT number series returns **41 contracts / $26,836,144**, identical to
  `sd_rht_contracts.csv`. A description search on "Emergency Medical" returns nothing; "Ambulance" returns only
  Avel eCare's annual telehealth contract (2024–2026, $937,500 each year), which predates the NOA and is not
  RHT-numbered.

**Tier and coding, if it is ever named:** Tier 3 (subawards to 25 projects). The CMS sentence lists
hospitals among lead types, which is §0.3 eligibility, not receipt. Nothing is coded until a roster names
recipients.

**§0.1 trap, recorded so it is not extracted:** DOH's *Regional Services Designation Grant Fund
Distribution* page (`/healthcare-professionals/ems-trauma/ems-sustainability-assessment/regional-services-designation-grant-fund-distribution/`)
is a named, priced EMS award roster: Round 1, 39 organisations, $1,668,809.91; Round 2, 64 organisations,
$5,839,975.00 ($7.51M total, close to the RHT round's $7.2M). It is **state money**: an EMS Interim Committee
programme, the page reads *"Content last updated: August 4, 2025"* (before the 2025-12-29 NOA, so it fails
the §6.2 date test), and it never mentions Rural Health Transformation. It includes Avera Health and Bowdle
Healthcare Center. These are not RHTP awards.

**Also unread for extraction:** the Governor's 2026-09-24 CCBHC release (*"12 ... grants totaling more than
$13 million"*) names the 13-member cohort, including Avera Behavioral Health, and publishes no per-grant
amount. 13 cohort members against 12 grants means the roster is not one row per grant.

## 3. `MT_PRAIRIE_COUNTY_AMBULANCE_OPERATOR` — RESOLVED (a), NON_HOSPITAL

Owner decision: being in the same county does not establish that Prairie County Hospital District
(CCN 271309) operates Prairie County Ambulance Service. The row stays `EMS_OR_PSAP` / `NON_HOSPITAL` /
`No`, $340,000 (rounded). $0 moved. The queue row is `RESOLVED`. `R/03bv` notes and its test say so, and
`mt_year1_awardees.csv` was rebuilt; only the row's notes text changed.

## 4. The 10-08 check-in

The session-84 check-in Routine `trig_01DpSc…` fires 2026-10-08 15:15Z. It deletes MO's
`trig_0183VrPsZUMmc3dMneainqXm` and SC's `trig_01R1pZjkPkQZWD3vctiAJQ44` once their new ids have logged, and
checks AL's first firing (`trig_01NtbC312pu2u8d7uePQXEty`, Thu 10-08 14:40Z). The result is reported to the
owner when it fires.
