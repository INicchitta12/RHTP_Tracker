# Session 13 — South Dakota's rounds read, ADECA searched, the monitor re-run

**Date:** 2026-08-28
**Quota:** zero RCJ calls. Network: `news.sd.gov` (4), `doh.sd.gov` (6),
`open.sd.gov` (4, via `R/03i --probe`), `adeca.alabama.gov` (7),
`www.medicaid.gov` (1).

Three hosts were opened for this session and each was asked one question. Two
of the three answers are negative, and the negatives are the findings.

---

## 1. South Dakota: the rounds are announced, the recipients are not published

**The premise this session started from was wrong.** Session 12 recorded
`news.sd.gov` as *"the single largest unextracted block of named recipients
this project knows about"* — 110 named recipients and $121.5M behind two
pages. The host was allowlisted. Both pages were fetched.

**Neither release names a single recipient.**

| | Announced | Article | Grants | Total | Named |
|---|---|---|---:|---:|---:|
| Rural Strong project grants | 2026-07-23 | `KB0046839` | 28 | $31,500,000 | **0** |
| Technology and data grants | 2026-08-19 | `KB0047023` | 82 | $90,000,000 | **0** |
| | | | **110** | **$121,500,000** | **0** |

No list, no table, no attachment, no linked roster. Each release publishes a
count, a total, and a description of the funded themes. That is all.

The error in session 11's inference is worth naming precisely, because it is a
cheap one to repeat: the reasoning ran *"the state announced 82 organizations,
so the announcement lists 82 organizations."* It does not. A count is not a
list, and the only way to know which a document is, is to read it.

### Getting the documents at all

`news.sd.gov` is a ServiceNow portal. The URL DOH links to —
`news?id=news_kb_article_view&sys_id=…` — serves a 972KB Angular shell that
renders the body client-side, so it cannot be archived as text. The portal's
`sp/page` API returns the page skeleton and the widget that holds the article
returns `invalid_token` without a session CSRF token.

`kb_view.do?sysparm_article=KB…` is the same article rendered server-side,
needs no cookie or token, and is the permalink form the article's own *Copy
Permalink* control emits. So the rows **cite** the portal URL (what a reviewer
will open) and the fetcher **reads** the `kb_view` URL. Both are recorded in
the manifest.

### Every other reachable route, checked and negative

| Host | Reachable | Result |
|---|---|---|
| `news.sd.gov` | yes | both releases fetched — neither names anyone |
| `doh.sd.gov` | yes | press index, RHT project page, RHT resources & FAQs, press search on "awarded" — no roster |
| `open.sd.gov` | yes | re-probed via `R/03i --probe`; **unchanged from session 12** |
| `ruralhealthtransformation.sd.gov` | **no** (CONNECT refused) | named as the resource site in both releases |

The OpenSD re-probe matters more than it looks. The July release states that
the Rural Strong contracts *"will be publicly available on OpenSD"* once
finalised. Five weeks later:

```
RHT number series (all agencies)     13 rows   $5,618,367
'Rural Strong' in the description     0 rows           $0
'Rural Health Transformation'         5 rows   $1,436,166
DOH grants, no filter               463 rows  $39,411,509
```

Identical to session 12. The contracts have not posted.

The May 2026 programme-management release (`KB0046486`) *does* name three
consultants — and all three are already in `sd_rht_contracts.csv` (North Star
Solutions $1,462,802, Business Concepts & Applications, Black Hills Special
Services). No new named recipient came out of it. One discrepancy worth a
reviewer's eye: the release describes BCA's as *"a two-year contract … $500,000"*
while OpenSD records contract 26RHT00003 at $250,000. The portal figure is the
one extracted, because it is the executed contract.

### What was built: `R/03j_sd_year1_announcements.R`

Two **aggregate award actions**, not 110 recipients, in Florida's leading-19
schema:

- `recipient_confirmed = No`
- `recipient_type = NOT_YET_NAMED`
- `flag_reason = RECIPIENT_NAMES_NOT_CAPTURED`
- `determination_confidence = LOW`

This is exactly the coding Georgia's two AHEAD cohorts carried for a session,
until `greathealth.georgia.gov` was allowlisted and the 87 names were parsed
out of the archived roster. The class and the count are confirmed; the names
are not captured; nothing is imputed.

**`distributed_to_hospital` is `Unclear` on both rows, and that is a decision,
not a default.** The Rural Strong release says the grants support projects
*"across 20 health systems"*. That reads as a hospital class and is not one —
it does not say a health system received money, and §0.3 is the rule that
stops the difference being papered over. The $90M release describes an
explicitly mixed recipient set: healthcare providers, Regional Innovation
Centers, aging-services organizations, academic and technology partners. Coding
either round `Yes` would be eligibility-is-not-receipt on a document that never
names a recipient at all.

**`amount` is empty on both rows.** The published figure is a *round* total,
not a recipient's award. Put $31,500,000 in `amount` and the row reads as one
organisation's grant the moment it leaves this file, and a naive sum looks
authoritative. The totals live in `round_amount`; `amount_basis` is
`NOT_PUBLISHED`; `rhtp_sd_year1_reconcile()` sums distinct rounds. This is
Georgia's rule (§6.2) and `R/03d` holds the same trap open.

### The tripwire, which is the point of the file

A negative finding that nobody re-checks decays into a stale assumption.
`rhtp_sd_year1_parse()` **refuses to archive or build** if either release ever
gains a recipient roster — a table, a run of list items, or a run of
organisation-shaped names — or if a stated figure stops matching the recorded
one. Re-running `--fetch --force` will hard-fail on the day South Dakota
publishes the names, which is precisely the day this file's framing becomes
wrong.

All four branches are tested by feeding the parser a real roster and requiring
failure. Measured margins on the live documents:

| Check | Live value | Threshold |
|---|---:|---:|
| tables | 0, 0 | 0 |
| list items | 0, 4 | 8 |
| organisation-shaped names | 2, 3 | 6 |

**The prose branch matches within sentence fragments, never across them.** A
pattern allowed to span a full stop swallows *"Avera St. Mary's Hospital.
Sanford Health"* into a single match. That **undercounts** a roster — the one
direction this check must never fail in — and on a 12-name test list the naive
pattern returned 9 matches instead of 12. Splitting on sentence terminators
first fixes it.

### Archiving

Only the `<article id="article">` element is archived, on the §7.1 / CMS
precedent: the ServiceNow chrome embeds a per-session CSRF token (`g_ck`) and a
guest user id, which are session state and not ours to commit. A test asserts
no archived file contains that token shape.

**The manifest carries both digests, and now says plainly that the full-page
one is not reproducible.** Two fetches minutes apart produced *identical*
article digests and *different* full-page digests, because the token is fresh
on every request. That is the evidence for archiving the article rather than
the page, and a reader who tried to verify the page digest and failed would
otherwise have every reason to distrust the archive. The article digests are
over the exact bytes written (`writeBin` — the session 12 correction) and a
test re-hashes both files on disk.

### South Dakota was missing from the union test

Session 12's notes said *"all six states union … asserted every run by
`tests/testthat/test_state_union.R`"*. The test named **five**: FL, GA, PA, AL,
AK. South Dakota was never added and nothing checked — the same class of gap
the union test exists to close, one file later.

Both SD files are now in it, deliberately as two entries:
`sd_rht_contracts.csv` (13 executed administrative contracts, named vendors)
and `sd_year1_awardees.csv` (two announced rounds, no names). They are two
kinds of document at two levels of certainty and **must never be summed
together**; every row of the second says so in its own
`determination_basis`.

### South Dakota's position, whole

| | Grants | Amount | Share of CMS award |
|---|---:|---:|---:|
| Rural Strong (2026-07-23) | 28 | $31,500,000 | 16.6% |
| Technology and data (2026-08-19) | 82 | $90,000,000 | 47.5% |
| **Announced, recipients NOT published** | **110** | **$121,500,000** | **64.1%** |
| Named recipients captured from these releases | 0 | $0 | 0% |
| Administrative contracts on `open.sd.gov` | 13 | $5,618,367 | 2.97% |
| CMS Year 1 award | — | $189,477,607.26 | 100% |

**South Dakota's confirmed hospital dollars remain $0**, and now for a reason
that is documented at primary-source level rather than inferred.

---

## 2. Alabama: ADECA publishes no award file, so the rounding stands

`adeca.alabama.gov` was allowlisted to close the $254,179 gap between the 138
amounts the governor's release prints ($143,745,821) and its own headline of
*"more than $144 million"* — the source's rounding of 45 amounts into millions.

**It does not close it.**

- ADECA's own post of 2026-08-24 (post id 22417) is a **verbatim mirror** of
  the governor's release. Compared amount by amount against the archived
  governor's copy, no figure appears in one and not the other, and ADECA's body
  carries the same 46 million-form amounts. Same prose, same rounding.
- The ARHTP programme page (`/alruralhealth/`) links four documents: the
  project narrative, the rural-counties list, the launch timeline, and a
  workshop memo. None is an award list.
- The WordPress REST media library was enumerated — searches on `rhtp`,
  `rural health`, `award` and `grant`, plus every upload since 2026-06-01.
  There is no awarded-projects PDF, xlsx or csv.

ADECA's page points to **`alabamarhtp.com`** for programme resources, and that
host is still refused at CONNECT (apex and `www` alike). It remains the likely
location of the exact figures. **The ask should be `alabamarhtp.com`, not
ADECA** — that is the correction this session makes to session 12's blocker
list, which named them together as if either would do.

**The 45 `AMOUNT_ROUNDED_IN_SOURCE` flags stay, unchanged.** They are correct:
Alabama published those amounts rounded and no reachable state source publishes
them otherwise. Replacing them with reconstructed figures would be this
pipeline asserting a precision the state has not. `--validate` is unchanged:
138 grants, $143,745,821, 60 hospital rows, $66,133,019.

---

## 3. The CMS press monitor: no state has announced since 2026-08-28

`Rscript R/00_cms_press_monitor.R --run --force` against the live
`medicaid.gov` RHTP resources page.

**Eight states, unchanged: AK, AL, GA, ND, OH, PA, SD, WV.** No new state, no
changed figure; `cms_state_announcements.csv` is untouched and only the fetch
manifest and the run log move. Two national (`State = "All"`) rows were
excluded as before — Tier 1 programme announcements, not state awards (§0.2).

**One thing worth flagging, because the monitor cannot see it.** The archived
CMS South Dakota release carries a *"Related Releases"* rail naming a Virginia
announcement dated **2026-08-28** — *"$122 Million to Expand Healthcare Access,
Workforce and Innovation Across Virginia"*. Virginia is **not** on the
medicaid.gov resources page the monitor parses. So either the page lags
cms.gov's newsroom, or it lists a different set. That is a coverage question
about the monitor's single source, and it is unresolved: nothing was changed on
the strength of a headline in a sidebar. Worth one session's attention, because
a trigger list that lags is a trigger list that misses states.

---

## Tests

**1,077 assertions, all passing** (was 997); one self-skip, the stage 00
first-run branch, unchanged. `Rscript tests/run_tests.R`, zero quota.

New: `tests/testthat/test_03j_sd_year1_announcements.R` — 50 assertions
covering the archives, the manifest digests verifying against the bytes on
disk, the absence of a session token, all four tripwire branches driven by real
rosters, the measured margins, and the three ways a reviewer could turn these
rows into a hospital dollar.

---

## What the next session should ask for

1. **`ruralhealthtransformation.sd.gov`** — the resource site both South Dakota
   releases name, and the only remaining candidate for 110 recipient names and
   $121.5M. This replaces `news.sd.gov` at the top of the queue, which is now
   answered.
2. **`alabamarhtp.com`** — ADECA's resource site, and the likely home of the
   exact ARHTP figures. `adeca.alabama.gov` is answered and can come off the
   list.
3. **`web.archive.org` + apex `archive.org`** — unchanged since session 11 and
   still the only route to Georgia's July roster snapshot. Not re-tested this
   session.

Everything else in session 12's "next session" list still stands: the §7.3
registry verification is still the hard gate on Stage 4, and the AHA Annual
Survey / CMS Provider of Services extracts are still the binding constraint on
Stage 5, with 200 hospital recipients waiting on a CCN match.
