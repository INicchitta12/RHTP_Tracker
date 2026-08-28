# Session 11 — the Wayback attempt, and where six states publish their awards

Zero RCJ quota. Network calls: six to `www.cms.gov` (archived), several to
`web.archive.org` (all refused at TLS), and reachability probes against ten
state hosts (all refused at CONNECT).

---

## 1. The July snapshot could not be retrieved — the 80/7 split stays an inference

`web.archive.org` **is** allowed through the egress policy: the gateway answers
`HTTP/1.1 200 Connection Established` to the CONNECT. What fails is the TLS
handshake immediately after — the peer resets the connection after the Client
Hello, before any certificate is offered.

```
* CONNECT tunnel established, response 200
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* Recv failure: Connection reset by peer
```

Reproduced **24 times over ~15 minutes** and across three independent TLS
stacks — curl (HTTP/2 and forced HTTP/1.1), Python `urllib`, and
`openssl s_client` — so it is not a client, ALPN or fingerprint problem. The
proxy's own `recentRelayFailures` records **no policy denial** for
`web.archive.org`, which is what distinguishes this from a blocked host: the
policy permits it and the connection dies upstream of the policy.

The apex `archive.org` — needed for the `/wayback/available` availability API —
**is** a policy denial, logged as
`connect_rejected: gateway answered 403 to CONNECT`. So the CDX endpoint was
the only route available and it is the one that resets.

**Consequence:** the July snapshot of
`greathealth.georgia.gov/value-based-care-hospital-list` was not retrieved, so
which 80 of the 87 hospitals carry the stated $750,000 is **still an
inference**. `PHASE_ATTRIBUTION_INFERRED` stays on the seven appended rows, and
`rhtp_ga_ahead_roster()` keeps refusing if the leading alphabetical run is not
exactly 80. Nothing about Georgia's coding changed.

**What to ask for:** `web.archive.org` needs to be reachable, not merely
allowed. Add the apex `archive.org` as well — the availability API lives there
and is the cheaper first call. This is worth re-testing in a later session
rather than treated as settled; the failure looks like an upstream condition,
not a permanent one.

---

## 2. The six announced states with no extraction — findings only, nothing built

**None of the ten candidate state hosts is reachable from this session.** Every
one was refused at CONNECT with a policy 403:

```
health.alaska.gov        alabamarhtp.com      adeca.alabama.gov
governor.alabama.gov     www.hhs.nd.gov       odh.ohio.gov
governor.ohio.gov        www.pa.gov           doh.sd.gov      news.sd.gov
```

So no award list was opened and **no extractor was built**, as instructed. What
follows is a locator report, assembled from three sources that *are* readable:
the committed RCJ pull (offline), the six CMS state press releases (fetched and
archived this session), and web search for the URL of record.

**On archiving those six releases.** Only each page's `<main>` element is
committed. GitHub push protection caught a **Mapbox token** in the CMS page
chrome — the same third-party token §7.1 already found on the allotment page,
and the reason only the `<table>` was archived there. The same posture applies
here: the manifest records the article digest *and* the full-page digest as
served, so provenance closes without this repo redistributing someone else's
credential, and the writer refuses to emit a file in which that token shape
survives.

### 2.1 The result in one table

| | Recipient-level list published? | Where | Reachable? |
|---|---|---|---|
| **PA** | **Yes — complete** | `pa.gov` DHS newsroom + Rural Health pages | blocked |
| **AL** | **Yes — complete** | Governor's newsroom, 2026-08 release | blocked |
| **AK** | **Yes — rolling, incomplete** | `health.alaska.gov` awards-notice XLSX | blocked |
| **SD** | **Announced, list not located** | `doh.sd.gov` press releases; contracts to `open.sd.gov` | blocked |
| **OH** | **No** — one named award only | governor's release (Ohio University) | blocked |
| **ND** | **No** — solicitation stage | `hhs.nd.gov` funding opportunities | blocked |

### 2.2 The three states that have published a recipient-level list

**Pennsylvania — the cleanest of the six.** DHS announced **66 authorized
projects** totalling **$42,198,309**, up to $1M per project, as the first
tranche of the state's $193,294,054. RCJ's parse of it holds **66 rows, 66
distinct awardees, $42,198,310** — one row per recipient, one dollar of rounding
against the stated total, and the count matching exactly. That is as strong a
signal as this project gets that the underlying state page is a complete
recipient-level award list.

- Announcement: `https://www.pa.gov/agencies/dhs/newsroom/supporting-rural-health-care`
- Program pages: `https://www.pa.gov/agencies/dhs/programs-services/healthcare/rural-health`
  and `.../rural-health/rhtp-funding-opportunities`
- RCJ document of record: *"PA - 2025 - Rural Health Selected Projects: Pa RHT
  Plan (RHTP) Authorized Project Awards"* (HTML, `AWARD_ANNOUNCEMENT`)
- CMS corroborates a separate $35M tranche within the same $193,294,054.

**Alabama — a complete list behind one governor's release.** Governor Ivey
announced **138 grants** totalling **more than $144 million** across five of
ARHTP's eleven initiatives, with the full list of recipients, amounts and
counties served on the governor's site. RCJ holds **exactly 138 rows**, 94
distinct awardees, **$143,745,821**. The count agrees with CMS's own press
release ("138 grants") and with the state's.

- Award list: `https://governor.alabama.gov/newsroom/2026/08/governor-ivey-announces-first-grants-in-major-new-rural-healthcare-program-totaling-more-than-144-million/`
- Program site: `https://alabamarhtp.com/resources/` (the NOFOs, one per initiative)
- Administering agency: ADECA, `https://adeca.alabama.gov/alruralhealth/`

**Alaska — a real award notice, but the list is still growing.** DOH is
releasing **Notices of Intent to Award on a rolling weekly basis** and
maintaining a spreadsheet of them; it has said it intends to publish a
comprehensive dashboard once all awards are announced.

- **The award notice itself:** `https://health.alaska.gov/media/tcvker5a/ak_rhtp_awardsnotice_2026.xlsx`
- Announcement PDF: `https://health.alaska.gov/media/jtmfo30a/260704_pr_rhtp-award-announcements.pdf`
- Program page: `https://health.alaska.gov/en/education/rural-health-transformation-program/`

RCJ holds **161 rows across 102 distinct awardees, $160,702,462**, against CMS's
**"142 projects"** and **$160 million**. The dollar figures agree to 0.4%; the
counts do not, and **161 ≠ 142 is a discrepancy to resolve at the source, not to
average away.** The likely explanation is that Alaska's sheet carries one line
per activity type and some projects span more than one — several awardees repeat
with different activity types — but that is a hypothesis about the file, and the
file has not been read.

**A caution specific to Alaska.** These are `NOTICE_OF_INTENT_TO_AWARD`, not
`NOTICE_OF_AWARD`. Both are primary under §8 and both can support a `Yes`, but
they are different documents and the distinction belongs in
`validation_source_type` rather than being flattened.

### 2.3 South Dakota — awarded at recipient level, list not located

SD has made two rounds of recipient-level awards and neither list surfaced in a
readable place:

- **$31.5M in Rural Strong grants to 28 projects across 20 health systems**,
  selected from 79 applications (announced 2026-07-23).
- **$90M to 82 rural healthcare organizations**, selected from 144 applications
  requesting $336M (announced 2026-08-19; corroborated by the CMS release
  archived this session).

RCJ has only the **one aggregate row** — `"South Dakota Rural Strong Grants"`,
$31,500,000 — which is a pool name, not a recipient, and would tier
`SOLICITATION` at best. The names exist somewhere; the reporting is consistent
that grant **contracts are posted to the state transparency portal once
finalised**, which makes `open.sd.gov` the most promising route and an unusual
one for this project — a contracts register rather than a press release.

- Press-release index: `https://doh.sd.gov/healthcare-professionals/rural-health/rural-health-transformation-project/rht-press-releases`
- Named releases: `.../press-releases/south-dakota-announces-first-awards-for-rural-health-transformation-grant-program-management/`
- Contracts: `https://open.sd.gov/`
- Solicitation portal: `https://postingboard.esmsolutions.com/3444a404-3818-494f-84c5-2a850acd7779/events`
- A state RHTP site also appears in the RCJ data and has not been examined:
  `https://ruralhealthtransformation.sd.gov`

**SD is the highest-value of the three unresolved states**: 82 + 28 recipient
rows are already awarded, and the only thing missing is a readable list.

### 2.4 Ohio — one named award, everything else still a solicitation

Ohio has named exactly one recipient: **Ohio University, $10,000,000**, to lead
Health Workforce Ohio, via the governor's release. The $3.15M pharmacy
connectivity award CMS announced on 2026-08-26 **names no recipient at all**.
Everything else on `odh.ohio.gov` is a solicitation — DOH59808, DOH61182,
DOH61365, DOH61908, RT27 Competitive — administered through the GMIS grants
portal and `ohiobuys.ohio.gov`.

Ohio's $92M Rural Health Innovation Hubs / CIN pool is the spec's own §0.2
Tier 2 worked example, and it is still Tier 2. **§0.3 applies squarely here:
solicitations naming hospitals as eligible entities are not receipts.**

- Program page: `https://odh.ohio.gov/know-our-programs/rural-health-transformation-program`
- Solicitations: `.../rural-health-transformation-program/solicitation-invitations`
- Named award: `https://governor.ohio.gov/media/news-and-media/governor-dewine-announces-ohios-rural-health-transformation-program-award`

### 2.5 North Dakota — the furthest from a list

ND is at the solicitation stage across the board. The RCJ pull holds **124 ND
documents and 21 distinct funding-opportunity PDFs** under
`hhs.nd.gov/sites/default/files/documents/rhtp/`, with applications collected
through Qualtrics forms. The one RCJ "award" row is
**`"15 selected CAHs"`, $630,000** — a class, not a recipient, and a textbook
`PASS_THROUGH_UNRESOLVED`.

CMS's 2026-08-20 release announces **$1M to launch the Coordinating and
Connecting Care Initiative** and names no recipient either. Publicly described
pipelines — ~20 rural hospital awards of ~$2M each, $3.6M in school and
community grants of $25K–$125K — are **forecast award counts, not awards**.

- Funding page: `https://www.hhs.nd.gov/rural-health-transformation/funding`

### 2.6 What the RCJ signal is and is not

| | RCJ rows | distinct awardees | RCJ sum | state/CMS stated |
|---|---:|---:|---:|---|
| AK | 161 | 102 | $160,702,462 | $160M, 142 projects |
| AL | 138 | 94 | $143,745,821 | >$144M, 138 grants |
| PA | 66 | 66 | $42,198,310 | $42,198,309, 66 projects |
| ND | 1 | 1 | $630,000 | — (`"15 selected CAHs"`) |
| OH | 1 | 1 | $10,000,000 | — (Ohio University) |
| SD | 1 | 1 | $31,500,000 | — (pool name) |

**None of these sums is a finding (§0.1).** They are a coverage signal: where
RCJ's row count lands on the state's own stated count, the underlying state
document is recipient-level and RCJ parsed most of it, which tells us the
extraction is worth building once the host is reachable. Where RCJ has one row,
either the state has published nothing recipient-level (ND, OH) or RCJ missed a
list that exists (SD). The distinction between those two cases came from the CMS
releases and the press, not from RCJ, which is §0.1 working as designed.

---

## 3. Georgia's hospital-directed figure is $60,000,000 everywhere

`$65.25M` no longer appears as a carried figure anywhere in the repo. It assumed
87 × $750,000; DCH states $750,000 for the Phase 3 **eighty** only.

Verified against the data rather than asserted: `ga_great_health_awards.csv`
holds **exactly 80 rows at $750,000**, and **80 × $750,000 = $60,000,000**,
which closes on the stated Initiative 1 pool to the dollar. The 81st row
carrying an amount is Phase 3's $487,500 balance, giving the phase's stated
$60,487,500. `Rscript R/03d_ga_great_health.R --validate` passes on 139 award
actions with the reconciliation unchanged at $197,148,327 and a 9.92% residual.

Corrected in two places, both of which were Session 9 narrative:

- `CLAUDE.md` — the Session 9 summary, with a superseded note pointing at the
  Session 10 correction directly below it.
- `docs/georgia_great_health_year1.md` — the *87 AHEAD hospitals* section, which
  also carried two other claims Session 10 resolved (the host was blocked; the
  cohorts were two aggregate rows). A banner marks all three.

The four remaining occurrences of the string `$65.25M` are the **correction
record itself** — each one states that the figure was wrong and gives
$60,000,000. Deleting those would erase the audit trail the correction exists to
leave, which is the §2.1 failure mode in miniature.

---

## 4. What this session did not do

- **Built no extractor for any of the six states**, as instructed — and could
  not have, since no state host is reachable.
- **Did not treat any RCJ row as validated.** AK, AL and PA have 365 RCJ award
  rows between them and not one of them is a finding until the state document
  behind it is fetched, archived and read.
- **Did not resolve Georgia's 80/7 split.** It remains flagged.

## 5. Next

1. **Allowlist, in this order:** `www.pa.gov` (a complete list, one page, exact
   corroboration), `governor.alabama.gov` (a complete list, one page),
   `health.alaska.gov` (an XLSX award notice, ingests like Florida's workbook),
   then `doh.sd.gov` + `open.sd.gov` (awarded, list not located). `odh.ohio.gov`
   and `www.hhs.nd.gov` are worth having for §7.3 registry verification but have
   no Tier 3 list to extract yet.
2. **Re-test `web.archive.org`,** and ask for the apex `archive.org` too. The
   failure this session was upstream of the policy, so it may simply clear.
3. **PA and AL are Deliverable 1 states 3 and 4** the moment their hosts open —
   both are a single page, both corroborate against a stated count, and PA's
   agrees to the dollar.
