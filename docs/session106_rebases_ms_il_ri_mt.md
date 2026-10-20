# Session 106 — probe re-bases, MS path, IL probe, RI access, MT runner

2026-10-20. Branch `claude/admiring-goodall-2sf0vu`, started from `main` at `7d9bb9e`, full history. `main`
already carried session 105 except one doc commit (`3a79daa`, on `claude/pensive-mccarthy-24u7gb`), which
this branch merged first. No Year 2 work was done. No CMS release read this session announces FY2027 amounts.

**No figure moved.** No state award file changed, so the hospital partition is unchanged (below).

## Task 1: Hawaii's first firing

Logged under its own Routine id. `trig_017PbAESTaaMfYZ3nKcS3j1m` ran at 2026-10-19T18:35:09Z and appended
five lines on `main`: `shpda`, `rhtp_home`, `rhtp_funding` and `doh_news` read UNCHANGED, and `gov_news`
read CHANGED with no finding. Coverage reads "203 due firing(s) since the logging fix; all logged except 5
EXPLAINED miss(es)". No gap entry is needed.

## Task 2: re-bases (owner-approved), each read before it was taken

| State | What changed (read 10-20) | What was done | Live probe |
|---|---|---|---|
| WY `programme` | The 08-11 meeting notice is gone. A "Year One Award Approvals" button now links Drive file `1jqfbHzZPrX-_xT-uLg3TFXorckp3b3uX`. That file is the approvals PDF R/03aj extracts: the live bytes are 195,009 bytes with SHA-256 `30aed248…c5b372`, identical. The timeline gains a "Year One" heading and drops two clauses. No recipient is named. | `WY_NAME_FURNITURE` holds the one button label (exact match). New `WY_KNOWN_DRIVE_TARGETS` plus `wy_drive_link_findings()`: **a Drive link nobody has read is a TRIPWIRE finding**, whatever its label. The page is re-based in place, and MANIFEST records the prior digest. | UNCHANGED (all 4) |
| MS `funding`, `home` | `funding` adds the Innovative Pilot (opens 10-14), EHR Replacement (opens 10-21) and MSDH HIE/HDU RFP (OpenGov, due 11-03) opportunities. WEI, EmPATH, the EMS Capacity RFP and the three awarded programmes moved to a separate **Closed Funding Opportunities** page. `home` was re-laid out. Neither page names a recipient. The "selection process is complete" sentence and the 99.96% / 0.04% footer are unchanged. | Both pages re-based in place, with MANIFEST noting the prior digests. **The closed page is now a probe source (`closed`)**, and `ms_assert_remaining_tranches()` reads it. | UNCHANGED (`funding`, `home`, `closed`, `release`) |
| CT `programme` | A stray `-->` after the breadcrumb ends the run one word early. That shorter run was the 10-19 trip. It was present on 5 of 5 fetches. | Both breadcrumb variants are added to `CT_NAME_FURNITURE$programme`, so neither the leak nor its repair trips. Re-based to a new dated file; the 09-02 copy stays on disk. | UNCHANGED |
| CT `opm` | The CTsource bid link inside the same OPM staffing-study RFP block moved (145966 → 146239). The RHTP NOFO block is unchanged. | Re-based to a new dated file; the 10-07 copy stays. | UNCHANGED |
| CT `dmhas_rfps` | Two new RFPs, **neither RHTP**. Recovery Centers: $3,742,834, "Funding Source: Opioid Settlement Funds", due 12-18. RISE (Regional Infectious Services for Enhancement): $1,000,000, "Substance Use State and Federal funding", no RHTP mention, due 12-10. Homeless to Housing also gained Addenda 2–3. The REST row is unchanged and links no outcome. | Re-based to a new dated file; the 10-05 copy stays. | UNCHANGED (all 6) |

**The WY fixture tests** (`test_03aj`, five new blocks):
- The known label is the exact run the 10-09..10-20 firings reported, and with the furniture it is silent.
- A new hospital name on the page still trips.
- A re-worded button ("Executed Agreements") still trips.
- A new Drive link (`file/d/…` or `uc?id=…`) is a finding.
- Changed timeline text still moves the content digest.

CT has its own test: the breadcrumb is quiet in both directions, and a word welded into it fires.

**The Governor's MS newsroom** is a rolling index, not a re-base target. It read CHANGED: the new headlines are appointments, a bond rating upgrade and a tower demolition. There is no RHTP headline.

## Task 3: Mississippi Medicaid's procurement page

**There is no new path. medicaid.ms.gov is in a vendor outage, not a redesign.**
- Every path serves one "Mississippi Division of Medicaid | Temporary Site" placeholder at HTTP 404: `/`, `/resources/procurement/completed-procurements/`, `/resources/procurement/`, `/procurement/`, `/rural-health-transformation-program/` and `/wp-json/`. The placeholder text reads "regular website is currently down due to a temporary outage affecting our web-hosting vendor".
- Its home page links only portals and phone numbers.
- `sitemap.xml` and `robots.txt` return 404.

**What changed in R/03ak.**
- `ms_get()` now names the placeholder. `dom_completed` logs ERROR "DOM WEBSITE OUTAGE … 'Temporary Site' placeholder (HTTP 404)" instead of a bare 404.
- The day the placeholder goes but the path still 404s, the log will read differently, and that is the signal the page has actually moved.
- The 09-03 capture stays the archive.

**Watches until 10-29 (the WEI/EmPATH window):**
- The Governor's newsroom, unchanged.
- The `closed` page (new, Task 2).
- The funding page's award-language tripwire.

**DFA's statewide bid search was checked as an alternative and is not a substitute.** It is `ms.gov/dfa/contract_bid_search`, a DataTables POST API that is readable with the project agent.
- Its Keyword and Agency filters return 0 rows.
- It holds only two closed DOM items (EQRO, appeals administrator).
- WEI and EmPATH are grants awarded through mississippirhtp.com, not procurements.

**One lead, Tier 2, not extracted.** DMH's RFP **DMH-RHTP-2027-001**, "Veterans and First Responders Telehealth", MAGIC object 3150007058. It was advertised 2026-09-29 and closed 10-14, with no award. It is a vendor procurement.

## Task 4: Illinois probe (`R/03cg_il_rhtp_probe.R`, new)

**What the Hospital Planning Grant document is.** HFS's RHTP page links the "Hospital Planning Grant Methodology" (Appendix A; PDF CreationDate 2026-05-20). It was already linked on the 08-28 archive.
- It is an **eligibility** list. "97 out of 198 Illinois hospitals are eligible to apply" (all 55 CAHs, all 74 hospitals in HRSA-rural ZIP codes, 23 others), and the document names all 97 with CCN.
- The pool is "$28,191,393.00 … allocated equally among eligible hospitals. If all 97 eligible hospitals apply, this will result in an award amount of approximately $290,000 per hospital."
- That makes it Tier 2 plus a hypothetical, and **eligibility is not receipt (§0.3)**. Nothing is extracted. A roster of recipients, when HFS posts one, is hospital money by construction: primary grantees must be general short-term acute hospitals.

**What it watches.**

| Page | Read as | Trips on |
|---|---|---|
| `hfs_rhtp` | HFS's RHTP page, scoped to its content column (`div.container.aem-GridColumn--default--9`). `<main>` carries the mega-menu, whose runs read as names. | A **new link** in the content (HFS publishes every RHTP document there), a new award sentence (including "planning grant … award/recipient/grantee"), a new currency figure, and the name tripwire. |
| `hfs_stakeholder` | Director's Stakeholders News index | CHANGED only. HFS has no press index of its own: `/info/media.html` links only this page. Its releases go to illinois.gov's news search, which is a JavaScript client over a key-gated Elastic API returning no URLs and placeholder dates, so it is not read. |
| `gov_press` | Prezly newsroom, Press Releases category | A new headline matching RHTP / HFS / planning grant / rural hospital / critical access / ICAHN. |
| `gov_sitemap` | The same newsroom's `sitemap.xml`: every story, 1,584 URLs on 10-20 | A new story **slug** on those topics. The category page shows 12 stories; the sitemap is complete, so a weekly probe cannot miss a release. Compared by slug set, never by bytes. |
| `planning_method` | The methodology PDF, by file digest | CHANGED only. |

**Out of scope.** AmpliFund, which sits behind a login.

**Credentials.** HFS's page embeds a Mapbox public token in a `<map-details api-key=…>` attribute, outside any script. `il_archive_html()` removes any element carrying a credential-shaped attribute before writing. The element has no text or links, so neither the comparison nor the link set changes.

**Evidence and tests.**
- Baselines are in `data/evidence/IL/probe/` with a SHA-256 MANIFEST.
- Two live runs, 15 seconds apart, both read UNCHANGED on all five pages.
- `test_03cg` drives each tripwire with a planted change: a roster PDF link, an award sentence plus a figure, a hospital name, a new RHTP slug, a new RHTP headline. It also checks that the methodology's eligibility wording is *not* an award sentence and that the archive against itself is quiet.

**Routine.** `trig_01B62afWZaQXR4Hooi2gjZmH`, "RHTP probe: IL (weekly Wed)", cron `20 16 * * 3`.
- Its own runner is `session_019BXE1PhDmkn6tNvHS2L8u4`, configured like HI's: `env_01RnpqJ1D6wFAaRMvFu43oV3`, claude-sonnet-5, auto, `main` as source and outcome, no seed.
- The prompt `v3/IL.txt` is HI's prompt with the state, runner, script and commit label changed, and `v4/IL.txt` is derived from it.
- It is registered in `config/routines.csv` with `logging_since 2026-10-20T19:42:15Z`.
- **The first firing is Wed 10-21 16:20Z. Merge before then**: `main` has no R/03cg.

## Task 5: Rhode Island access check

**None of the three channels is readable.** Each was tried with both project agents (`Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; +https://www.aha.org)` and `AHA-RHTP-Tracker/1.0 (…)`), and each got HTTP 403 with a Cloudflare "Just a moment..." challenge.
- **EOHHS:** `/`, `/initiatives/rural-health-transformation-program`, `/rhtp`.
- **Governor:** `governor.ri.gov/`, `/press-releases`.
- **RIDOH:** `health.ri.gov/`, `/news`.

That is UNKNOWN about the state, not NO (§0.4). **CMS's quarterly obligations refresh (expected after 11-30, parsed by R/00c) is Rhode Island's only readable source.** RI stays `QUEUED`. No probe was built.

**Recorded only.** `www.ri.gov/press/` (the state portal's press index) is readable. Its agency list carries RIDOH ("Health, Department of") but not EOHHS or the Governor, and its `?page=` parameter does not paginate. A RIDOH-only watch there is possible; it was not built (owner call).

## Task 6: Montana runner moved

- **Old runner and task.** `session_01GGJ61Ux7s4Zp1nGwTpRJLD` stood at **692,615** tokens at 19:40Z (677,649 at session 105). Its task `trig_01YJFwwSQ1pEQEScfUfGzgSD` is **disabled**, not deleted. Delete it once the new id has logged on `main`.
- **New runner and task.** `session_01GUacKKzVNain2XkWRp7NQk` (same settings) runs `trig_013NBAwSZ2Rh4hhbjtLZtYA6`, with the same name and cron `40 17 * * 2,5`. The next firing is Fri 10-23 17:40Z.
- **Prompt check.** `v4/MT.txt` is regenerated through `runner_moves.csv` (MT row added). It equals the previous `v4/MT.txt` with the runner id swapped in all three places and nothing else: both are 6,478 bytes, and that equality is checked by script. The prompt sent to `create_trigger` is that file verbatim, and the stored prompt it returned matches. `--check`: "v4 matches derived for 42 states".
- **Chain.** `routines.csv` chains MT as `trig_019e…;trig_01YJF…` with `old_logging_since` `2026-09-28T20:19:07Z;2026-09-30T15:31:32Z`.
- **Merge before Fri 10-23 17:40Z**, or the new id's line reads as unregistered.

## Read this session, not extracted

**Montana TRIPWIRE, 10-20 17:42Z (old Routine).** The Grants page gained "FY26 DPHHS Community Integrated Health Pilot Site Grant … Applications Closed: Sept. 15, 2026 · Date Awarded: Oct. 13, 2026 · Amount: $3.63 million". The probe reported this as "Oct. 15", because the sentence split falls across the dates. The money is for "emergency medical services (EMS) to administer Community Integrated Health (CIH) programs".
- **No awardee is named**, and the name tripwire stayed quiet.
- It is an awarded round with nobody named. Hospital effect: $0. EMS agencies are the class; some may be hospital-based, which only names would settle.
- Not re-based: the next firing will trip again until a human takes the re-base, or extracts when names appear.

## Hospital partition (unchanged; asserted by `test_claude_md_status_table.R`)

```
NAMED_HOSPITAL          1,576 rows   $1,431,975,278.58   34 states
POOL_NAMED_HOSPITALS        7 rows      $85,555,171.43
POOL_UNNAMED_HOSPITALS      5 rows      $69,323,109.17
```

These three buckets are never added together. The internal figure, with SOURCE_SUSPECT rows included, is 1,578 / $1,435,430,699.58.

## Merge timing

Merge **before Wed 10-21 16:20Z**. That is IL's first firing, and CA's 17:00Z firing follows it. It also covers the WY firing Fri 10-23 21:10Z, MT Fri 17:40Z and MS Fri 09:40Z.
- WY fires tonight, **Tue 10-20 21:10Z**, from `main` and will trip once more on the approvals label. That trip is read here.
- Never merge Mon/Thu 13:00–14:00Z.
