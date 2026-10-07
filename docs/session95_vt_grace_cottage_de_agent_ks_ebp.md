# Session 95: Grace Cottage resolved, Delaware's agent exception, Kansas EBP

Run 2026-10-07. Zero RCJ quota. The session had three owner tasks.

## 1. `VT_S94_GRACE_COTTAGE_FAMILY_HEALTH_BRIDGE`: RESOLVED, $0 moved

- **Decision.** The owner accepted "Grace Cottage Family Health and Hospital" (one row, Workforce Development /
  mentorship, **$347,098.83** in the file) as `HOSPITAL_OR_SYSTEM`, LOW, `basis_type = GENERAL_KNOWLEDGE`.
  - It is a hand bridge to Grace Cottage's enrolled critical access hospital, **CCN 471300** (CARLOS G OTIS
    HEALTH CARE CENTER INC).
  - Session 94's notes printed the amount as $347,098.80. The CSV holds .83.
- **Where the CCN is recorded.** The CCN is in `determination_basis`, as instructed. It is not in the `ccn`
  column, because a value there means a confirmed match (§7).
- **What changed.**
  - `R/03at`'s typing text was edited, and `--build` changed one line of `vt_year1_awardees.csv`.
  - The queue row was edited byte-wise, CRLF, 1/1.
- **Figures.** VT stays at 51 / $44,866,699.26, and the LOW slice at $8,319,753.09.

## 2. news.delaware.gov: the second agent exception

- **What it does.** `RHTP_DE_NEWS_USER_AGENT` is a full Chrome UA. It is used on that exact hostname only,
  through `rhtp_agent_for_url()` in `R/utils_config.R`.
- **Wired into:**
  - `rhtp_watch_fetch()`, which covers every watch probe and the newsroom sweep
  - `R/03al`'s `de_get()`
  - the sweep's unreadable re-test
- **Hosts that keep the honest agent:** dhss.delaware.gov, delaware.gov, and lookalike hosts.
- **Refusals (`rhtp_assert_agent_scope()`), in both directions:**
  - the browser agent off its host
  - the honest agent on news.delaware.gov
- **Tests (`test_utils_agent_scope.R`).** The suite drives both refusals and checks every `DE_SOURCES` row and
  every `NW_PAGES` row. It fails if a Chrome/Safari string appears in any file in `R/` other than
  `utils_config.R`.
- **What weakens the case (measured 10-07).** These are alternating fetches of the 07-29 release, 4s apart:

  | Agent | Served | Rejected |
  |---|---:|---:|
  | Project | 7 of 8 | 1 of 8 |
  | Chrome | 5 of 8 | 3 of 8 |

  - The newsroom index, three rounds: the project agent was rejected once and Chrome once.
  - The first live run through the new code was rejected twice, then served on the 45s retry.
  - **Conclusion.** Today the block is not keyed on the agent. The exception is in place as decided. The retry
    is what gets through, and it stays.

## 3. Kansas

### The 10-05 name trip: KDHE's new site menu

- **The problem.** KDHE's Cloudflare front (CivicPlus) answers this container 403 on every agent. That includes a
  local headless Chromium through Playwright.
- **How the page was read.** It was rendered by r.jina.ai (headless Chromium), on the owner's instruction to
  confirm with a browser read. The markdown is archived at
  `recheck/2026-10-07/KS/2026-10-07_kdhe_rhtp_program_page_browser_render.md`. It is not a baseline.
- **What the render shows.** Running R/03o's own tripwire on the rendered HTML gives 177 "new" names:
  - **174 are KDHE's department-wide mega-menu.** It starts at "About KDHE": Office of the Secretary, Division of
    Environment, Kansas Clean Diesel Program and so on. The archived 09-22 copy has none of it. The header menu
    and breadcrumbs changed too, so this is a site redesign.
  - **"Regional Partnership Grant Program" and "Transformative Capital Investment Grant Program"** are the new
    Year 2 RPGP ($44M) and CAP ($11M) solicitations. They are open until 11-13 and "Funding amount is pending
    CMS approval". They are Tier 2 and name nobody.
  - **"The Kansas Health Institute"** appears in a technical-assistance box. It is not an award. It was not in
    the 10-05 trip (176), so it appeared after that.
- **Controls.** The award-index control and the provenance sentences both pass on the rendered page. No fourth
  award link was added.
- **Fix.** `KS_NAME_SCOPE` cuts the page to "Open RHTP Funding Opportunities" … "Quick Links" on both copies.
  `KS_NAME_FURNITURE` holds the three read names, matched exactly. A test proves the page still fires on a real
  recipient, and on a longer name containing a furniture string.
- **Not done.** The baseline was not re-based, because KDHE is 403 from here.

### Evidence-Based Practice Program: not in any award file; 94 enrolled hospitals

- **In the files before this session.** EBP appears only as Tier 2 budget lines. The Year 1 narrative (Rev 2,
  Table 12.E.4) has an EBP Infrastructure Assistance Fund of $22,000,000 and EBP Provider Incentive Payments of
  $11,000,000. "KDHE will sub-award CCA to administer". The RCJ disposition already covers the CCA lines. No KS
  award file carries EBP.
- **The list.** The Care Collaborative's page (ruralhealthkansas.com) says "A complete list of hte rual
  hospitals participating in the EBP Program is available here". It links "EBP Program Participating Hospitals
  (9/18/2026)" with **94** names, and a clinic list of 212. KHA counted 289 enrolled on 08-07.
- **§10.2 pass-through test:**
  1. **An intermediary receives the funds: yes.** KDHE sub-awards CCA.
  2. **Hospitals are named, and the hospital stream is hospitals only: yes.** It has its own agreement, its own
     list, and an eligibility rule of KDHE-licensed rural hospitals, CAHs and REHs.
  3. **The award has been made: not shown.**
     - Agreement §2: "$100,000 **upon** Hospital's submission of the signed and completed Attestation Form". The
       admin FAQ allows the form as late as 2027-10-01.
     - Agreement §3: "$50,000 by November 30, 2026, following confirmation of" Q3 2026 reporting.
     - Agreement §6: payments are "fully contingent" on RHT funds reaching CCA.
     - The admin FAQ: "The Care Collaborative will post on its website a list of providers that have
       **received** infrastructure payments and incentive payments."
- **Coding.** The 94 are an ENROLMENT list, the shape of Maine's and Missouri's rosters. `R/03bz` writes
  `ks_ebp_participants.csv`:
  - It is a non-award file, never in `STATE_FILES`.
  - It has no amount column, and every row has `award_made = No`.
  - The rows are not typed. "Ascension Medical Group via Christi, PA Wichita - Wellington" is on the hospital list.
- **Formula ceiling.** 94 × ($100,000 + $50,000) = $14,100,000. That is a ceiling, recorded only as text.
- **Correction to the brief.** Year 1 pays one $50,000 incentive for one quarter. It is not "up to $50,000 per
  quarter". Later years are undefined (Agreement §5).
- **Watch.** `R/03o --probe` (the KS Routine) now also reads the EBP page live. It trips on either:
  - a linked document that is not a participant list, a FAQ or an agreement
  - wording such as "have received … payments"

  A re-dated participant list is logged CHANGED, not TRIPWIRE.
- **Owner question.** `KS_EBP_ENROLMENT_NOT_AWARD` has three options:
  - (a) enrolment, $0, as coded
  - (b) priced at the formula: up to +94 rows / +$9.4M
  - (c) award rows at $0
- **Year 1 completion status.** The KS note now says EBP is enrolled, not paid.

## Figures

The partition is unchanged: NAMED_HOSPITAL 1,308 / $1,213,341,798.50 / 32 states.
