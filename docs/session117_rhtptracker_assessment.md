# rhtptracker.com as a lead source (session 117, 2026-11-16)

**Recommendation: option (2).** Read it weekly as a lead check, the way RCJ is used. It may point us to an
official document. It is never the source of a figure, a recipient, a date or a tier (§0.1). It is not wired in
this session. Raw captures (not committed; third-party pages) were read on 2026-11-16 from this environment.

## Who runs it
- **Moodr Health**, a private company. Its Terms of Use say: *"RHTP Tracker is an independent Moodr Health product.
  It is not operated by CMS or another government agency."* The footer says: *"An independent public tracker, not an
  official CMS or government site."*
- Contacts: privacy@moodrhealth.com; rhtp@moodrhealth.com (corrections). A sales booking link and a lead-generation
  "scan" tool sit beside the tracker. `/api-docs` is restricted to admin accounts from Moodr Health, M&S Consulting
  or Daymade.
- `/terms`, `/privacy` and `/about` are 404. The live pages are `/terms-of-use` and `/privacy-policy`, both effective
  2026-07-27.

## Terms of Use and robots.txt
- Internal research use is permitted: *"You may use public Tracker pages and reasonable API access for research,
  planning, and internal analysis. Do not disrupt the service, evade rate limits, misrepresent Tracker data as
  official government guidance..."*
- The terms say *"Official issuing-agency material always controls"*. They grant no right to republish, which fits
  this project's internal-only scope (§8.1).
- robots.txt allows `/` for every agent. It disallows `/api/`, `/reports/`, `/auth/` and a few others. **A lead
  check must stay off `/api/`.**

## Methodology
- `/guides/platform-reference` is a glossary, not a methodology. It contradicts the site's own guides on
  "closing soon" (7 days in one, 14 in the other).
- There is no stated update schedule ("Sources checked on a schedule"); pages print "Last verified" with the
  day's date. It uses an RCJ-style "completeness score".
- Its data comes from state pages and portals, some email bulletins, and CMS's obligation report (10-14 edition).
- **There is no tier field.** It shows the federal award, the obligated amount, open-opportunity dollars and
  "who's funded" on separate lines and does not sum them. That is better than RCJ's single amount field, but nothing
  on a record states which tier a number is.
- Summaries are machine-generated and not labelled as such. Some are page navigation text, and quotes are cut
  mid-sentence (RCJ's §6 defect).

## Readability
- State and opportunity pages are rendered on the server and read over plain HTTP with the project's honest
  agent; no JavaScript is needed.
- `/states/IA|LA|MA/awards` are 404 (it has no roster for those states). `/documents?state=` ignores the state
  filter. `/sitemap.xml` lists about 607 opportunity pages, so the sitemap is the natural thing to diff.

## Five states compared against our files

| State | What it has that we lack (official link, status from here) | What it gets wrong |
|---|---|---|
| **MA** | **EOHHS RHTP Rural Partner Application, COMMBUYS bid BD-27-1039-EHS01-EHS01-134186** (posted 10-06, due 10-26): `https://www.commbuys.com/bso/external/bidDetail.sda?docId=BD-27-1039-EHS01-EHS01-134186&external=true&parentUrl=close` (200). Its RFA names eligible clinics: an eligibility list (§0.3), not recipients. **MassTech/MeHI Rural Digital Health Sandbox NOFO 2027-MeHI-02** (due 12-07, up to $475K): `https://mehi.masstech.org/sites/default/files/2026-11/2027-MeHI-02%20Rural%20Health%20Sandbox%20Grant%20NOFO%20Final_11_10_2026.pdf` (200). | No roster. |
| **IA** | RFP **COMPADM26007** Cardiovascular Health Hub (due 11-17): `https://www.iowagrants.gov/viewStorefrontOpportunity.do?OIDString=1787171894547` (200). RFP **PHTHOET26001** EMS System Assessment: `https://bidopportunities.iowa.gov/Home/BidInfo?bidId=a50cf278-24d7-4e5c-adde-a7c9921f4e28` (200). Neither is in the repo. | No roster at all (our IA file holds 264 rows). The $80.19M School-based Services ceiling is shown as an "opportunity budget". |
| **TX** | Nothing at roster level. **But its pointer led to HHSC's own page, which now links `rhtp-award-recipients.xlsx` "Updated 11/13/2026" and `bdgt-prd1-notice-award.pdf` (both 200).** Our newest roster is 10/29, and our probe's link pattern (`list-award-recipients`) no longer matches HHSC's new file name, which is why the 11-13 TX trip read "NO award-recipient list". | "$680.6M across 445 awards" is our 10/29 list's multi-year `total_award_amount` ($680,588,520.61), not the Year 1 subset ($224,596,379), and the rows are intents, not awards (§0.2, mode 2 and 3). It shows the roster "Checked Nov 6" while HHSC had posted 11/13. HHSC's estimated schedule appears as four "Upcoming RFAs" at "$425K–$725K", a figure not on HHSC's page. |
| **LA** | ORHTS Monthly Webinars, Aug and Oct (`https://ldh.la.gov/assets/docs/Secretary/RHTP/ORHTS-Monthly-Webinar_October-2026.pdf`, `...-August-2026.pdf`): **403** from here. `Rural-Eligibility-Definition-Methodology.pdf` (200). | The "RTCF Cohort 2" card carries the amount ("Up to $30M") and quotes of the Clinician Credit Bank NOFO, a different programme's document (mode 1). No roster. |
| **NH** | FHC's **Rural Primary Care Transformation RFA** (`https://healthynh.org/wp-content/uploads/2026/10/Rural-Primary-Care-Transformation-RFA-FINAL-102826.pdf`, 200) and **GO-NORTH T-TAC RFQ** (`https://healthynh.org/wp-content/uploads/2026/11/FHC-GO-NORTH-RH-T-TAC-RFQ-OCTOBER-2026.pdf`, 200). Neither is archived. Its FHC roster ($66,547,394) matches ours and cites the Governor & Council agenda of 2026-03-16 via a Wayback capture: 403 from here, direct and Wayback alike. | — |

Elsewhere: CMS's obligation report is filed under "California" (mode 6, the wrong state), and CMS's 2025-12-29
release is dated Jun/Jul 2026.

## Why option (2)
1. The terms permit internal research use, and the pages read over plain HTTP, so (3) does not apply.
2. Its figures show the same defects as RCJ's §6.1 modes: wrong tier or stage, multi-year totals, intents called
   awards, the wrong document attached, the wrong state, invented dates. It also has no rosters for IA, LA or MA.
   **Nothing it says may enter a figure.**
3. It still points to official documents on channels our probes miss: COMMBUYS, MassTech, IowaGrants, FHC uploads
   and email bulletins. Most of those are reachable from here. **For Massachusetts, which is `INVESTIGATED_NO_PROBE`
   because mass.gov is 403, it surfaced the first readable state-side RHTP documents.**

## If it is adopted (not built)
- **A weekly diff of `/sitemap.xml` and the 50 `/states/<st>` pages.** Read-only, honest agent, nothing under
  `/api/`, and no archive of its pages in `data/evidence/`: it is not a source.
- **A changed page is a lead.** Open the official link it cites, and archive and extract that document under the
  standing rules.
- **The tracker's own fields are never copied.** Any figure it states is re-derived from the official document,
  RCJ's rule (§0.1).
- **The first action needs no build:** write the Massachusetts probe on the COMMBUYS bid and the MassTech NOFO,
  which would move MA off `INVESTIGATED_NO_PROBE`.
