# Session 29 — Missouri on a schedule, New Hampshire's opposite coding, memsa closed

**Date:** 2026-09-01
**Quota:** zero RCJ calls. ~20 requests across `dss.mo.gov`,
`content.govdelivery.com`, `memsa.org`, `archive.org`, six `nh.gov` hosts (all
refused), `healthynh.org` and `nhcdfa.org`, throttled per §9.5.

---

## 1. Missouri — a watch on the channel where its hospital money actually is

### Why Missouri needed a schedule, and why it is not Alaska's reason

Alaska's file is stale **by construction**: DOH overwrites one url weekly, so a
snapshot is out of date the moment it is taken. Missouri's is stale **by
appointment**. `mo_year1_awardees.csv` says Missouri has made two RHTP award
actions, $7,232,660.43, and that **not one dollar reaches a hospital**. That is
a true statement about what DSS has published, and Missouri has published the
date on which it is expected to stop being true:

- Its RHTP timeline reads *"Aug - Sept 2026  Announce select procurement
  awardees"*.
- The ToRCH Care Smart Growth IFB (DSS26015) anticipates **nearly $40M**, with
  individual awards up to **$5M**, and *"Funding is open to hospitals"*.
- Horizon-2, **IFB # DSS26015-02**, had its bid opening on **2026-09-01 at
  2pm** — the day this session ran.

The live bid table confirms the last point in DSS's own words: *"IFB #
DSS26015-02 ToRCH Care Smart Growth and Service Line Modifications
(Horizon-2) … August 27, 2026 … September 1, 2026 at 2pm"*, the first date the
pre-proposal teleconference and the second the bid opening.

None of this will appear on the RHTP programme page. It appears on
`dss.mo.gov/bids`. That is **Indiana's sixth question** — is the state's award
channel its procurement system rather than a grants page? — answered by
Missouri itself rather than inferred.

### `--probe`, and the digest that had to be thrown away

`mo_probe()` follows Alaska's shape: fetch, compare, report, **archive
nothing**, exit 0 quietly when nothing moved. It reads three sources — the DSS
bid page, the RHTP programme page, and the Hub Anchor roster PDF. The roster is
not procurement, but it is the other designed-to-fail tripwire and the same
fetch shape, and a schedule that watched procurement and not the roster would
miss the larger event.

**The file digest is useless on this host, and that is measured rather than
assumed.** `dss.mo.gov` sits behind Incapsula, which appends a rotating
cache-buster to a script tag on every page it serves:

```
committed  …_Incapsula_Resource?SWJIYLWA=719d34…&ns=5&cb=922092161
live       …_Incapsula_Resource?SWJIYLWA=719d34…&ns=2&cb=1919101840
```

The committed bid archive is 47,651 bytes and a live fetch is 47,652; they
differ on **one line**. The programme page is identical in length with the same
one line changed. So the whole-file SHA-256 moves on **every** fetch while the
solicitations are untouched, and a probe keyed on it would report CHANGED every
week until somebody stopped reading it.

This is **Nevada's rotating state-symbol widget (session 26) on a new host and
by a different mechanism**: there it was one page's footer, here it is the whole
of `dss.mo.gov`. `mo_content_digest()` strips `//script | //style` and hashes
the squished text — **exactly the reduction `mo_html_text()` already performed**
— so the probe and the assertions read the same bytes and cannot drift apart.
Verified both ways: the file digests differ, the content digests are identical.

### The tripwires run against the LIVE bytes

This is **session 25's Indiana lesson written as code**. `--validate` reads the
committed copy and therefore passes trivially; it can only ever answer "had
Missouri awarded on the day the archive was taken?". `mo_assert_procurement_
pending()` now takes `page` and `bids` overrides — matching the override style
`mo_assert_anchors_not_awarded()` already had — so the probe hands both
assertions what the server just served.

**`MO_AWARD_POSTED` is a set of six specific forms and deliberately not the bare
token `award`.** The bare token `\baward(s|ed)?\b` is **already present** on the
live bid page in its own boilerplate and would fire on every run; every specific
form was tested against the live page and is **absent**. That is the difference
between a detector and a nuisance, and it is measured, not guessed.

| Control | Result |
|---|---|
| live bid page, unmodified | does not fire |
| `Contract awarded to …` | **fires** |
| `Notice of Award posted` | **fires** |
| `Awarded Vendor: …` | **fires** |
| `Bid Tabulation available` | **fires** |
| `Contract Award summary` | **fires** |
| `apparent low bidder` | **fires** |
| DSS26015-02 removed from the bid table | **fires** |
| timeline drops "Announce select procurement awardees" | **fires** |
| a dollar figure on the Hub Anchor roster | **fires** |

DSS's bid table carries three columns today — *Bid ID, Title* / *Issue Date* /
*Closing Date* — and **no award column at all**, so an award posting changes the
table's **shape** as well as its **words**. The content digest catches the
shape; `MO_AWARD_POSTED` catches the words.

**The probe ran live and reports UNCHANGED.** All three sources are
content-identical to the committed archive, DSS26015-02 is still open with no
awardee named, and the roster still carries no dollar figure.
`mo_year1_awardees.csv` and `mo_hub_anchors.csv` **rebuild byte-identical**;
only the disposition CSV changed, by one row (§3 below).

### The Routine

`trig_01RyGxdGNv6rrF8t6bT5fQdK`, **Wednesdays 15:00 UTC**, first fire
2026-09-02, fresh session per fire. Like Alaska's it carries a **branch guard**:
`grep -c "mo_probe" R/03w_mo_year1_awardees.R`, and if that returns 0 it reports
that main still carries the pre-probe version and stops. It also names what each
of the four tripwires means, and states that a tripwire firing is **the signal,
not a defect**.

---

## 2. New Hampshire — Illinois's shape, coded the opposite way

New Hampshire led the queue once Missouri was extracted: 27 Tier 3 candidates,
15 distinct awardees, a $204,016,550 allotment, no CMS press release, never
investigated.

### The route in was `/api/v1/activity` again — the sixth time

`state_source_url` is NA on all 27 NH Tier 3 records.
`stage2_state_sources.rds` held twelve real URLs, among them
`https://www.gonorth.nh.gov/`, `https://www.dhhs.nh.gov/programs-services/
medicaid/rural-health-transformation-program`, and
`https://healthynh.org/initiatives/rural-health-transformation-program`.

### Every `nh.gov` host is refused to this environment

| host | project UA | RFC convention | bare `Mozilla/5.0` | full Chrome |
|---|---|---|---|---|
| `www.gonorth.nh.gov/` | 403 | 403 | 403 | 403 |
| `www.dhhs.nh.gov/…/rural-health-transformation-program` | 403 | 403 | 403 | 403 |
| `www.gonorth.nh.gov/robots.txt` | 403 | 403 | 403 | 403 |
| `www.nh.gov/`, `sos.nh.gov/`, `www.governor.nh.gov/`, `www.das.nh.gov/`, `www.nh.gov/council/` | 403 | — | — | — |

The body is Akamai's *"Access Denied"* with an `errors.edgesuite.net` reference.
`robots.txt` is **itself 403**, so no crawler policy is on offer and none is
being declined. A second, independent transport (WebFetch) returns the same 403.
The agent proxy logs **no policy denial** for `nh.gov` — its only recent relay
failure is `web.archive.org:443` — so this is the origin's own decision.

**§3's michigan.gov exception would not help, and that is the point of
measuring it.** Michigan's Akamai config is a denylist on *identifying* tokens:
bare `Mozilla/5.0` gets 200 there. New Hampshire refuses a bare agent and a full
Chrome UA alike. Recording that is what stops a one-host exception being reached
for a second time on the strength of "a bare agent worked once".

**So what New Hampshire publishes on its own sites is UNKNOWN to this
repository.** `nh_year1_status.csv` carries a row saying exactly that —
`publishes_roster = UNKNOWN`, not "No" — because §0.4 makes "we cannot read the
state's site" a different claim from "the state published nothing".

### §7 is what makes the state readable at all

§7 admits a document from a state agency **or a designated pass-through
administrator**. ICAHN's own release was the first such source in this project
(session 16). Here:

- **The Foundation for Healthy Communities** publishes its own award, its own
  role, the Council date and the CMS footer, on `healthynh.org` (200).
- **CDFA** publishes the **same 2026-03-16 Council action** on `nhcdfa.org`
  (200).

Two publishers, two hosts, nothing arranged.

### What New Hampshire has awarded

GO-NORTH — the Governor's Office of New Opportunities and Rural
Transformational Health, *"established by Executive Order under Governor Kelly
Ayotte, and is funded by the Rural Health Transformation (RHT) Federal
program"* — runs five initiatives through five hubs and a small number of
designated administrators, each approved by the Governor and Executive Council
on **2026-03-16**.

| # | Awardee | `amount` | Coding |
|---|---|---:|---|
| 1 | Foundation for Healthy Communities (FHC) | **$66,547,394** | `PASS_THROUGH_UNRESOLVED` / `Unclear` |
| 2 | NH Community Development Finance Authority (CDFA) | *(empty)* | `NON_HOSPITAL` / `No` |

**CDFA's `amount` is empty deliberately.** Its statement says *"up to $40
million a year"* — a **ceiling on a programme**, not an award figure — so the
figure lives in `round_amount` (South Dakota's device) and no sum over `amount`
can read as a per-recipient award. And CDFA is `NON_HOSPITAL` on the recipient
class **its own statement gives**: *"rural health clinics, community mental
health centers, federally qualified health centers and county-run assisted
living facilities"*. Hospitals are not among them (§0.3a — judge the recipient).

### FHC is not ICAHN, and the eligible class is the entire difference

Both are executed awards to a designated pass-through administrator with no
hospital named. They code opposite ways, on §10.2's second clause:

- **ICAHN → `Yes`.** Illinois restricted eligibility to **hospitals only**.
- **FHC → `Unclear`.** Its class, in its own words, is *"primary care, critical
  access hospitals, EMS, behavioral health, oral health, and community-based
  organizations"* — hospitals **among other eligible entities**, which is §0.3
  exactly. `PASS_THROUGH_UNRESOLVED`, in **neither** bucket of
  `rhtp_hospital_dollar_partition()`.

A session that tidied these into one coding would publish **$66.5M** as
hospital-bound money on this pipeline's authority. `nh_assert_no_roster_yet()`
asserts that sentence is still on the page and fails the build if it goes, and a
test drives the failure.

FHC self-describes as *"the statewide leader and unified voice for New
Hampshire's hospitals and health systems"*, which is §10.2's hospital-body
branch — so it is `NONPROFIT_CBO` on AK's and IL's convention, not
`HOSPITAL_AFFILIATED_ENTITY`.

### New Hampshire has named no subrecipient, and its hospital RFA was unpublished

Every FHC funding opportunity is open, upcoming, or closed without a roster:

- **Critical Access Hospital and Acute Care Hospital** — the one that would name
  hospitals — reads **"Coming Soon"**, RFA *"Expected Published late August"*.
- **Primary Care Access** — *"Notification of Award (initial cohort): Late
  October"*.
- **School-Based Oral Health** — deadline 2026-09-25.
- **Emergency Medical Service** — closed, and no roster published.

**FHC's own *"50-100 active subrecipient awards"* is a planning range for a
portfolio it has not awarded.** A range of future awards is not a roster (§0.3),
and it is carried in the file so the day FHC publishes one there is something to
check the count against.

**The positive control** is FHC's own funding-opportunity index, which carries
*Current*, *Upcoming* and *Closed* sections. Without it, "no roster" is
indistinguishable from "we are reading the wrong page";
`nh_assert_opportunity_index()` requires all three and each is
positive-controlled.

### §6.2, programme-scoped, with the footer non-strict

Two sentences carry the provenance, each with the **award action or the
programme** as its grammatical subject:

- FHC: *"the New Hampshire Executive Council approved $66.5 million in year one
  Rural Health Transformation Program funding to the Foundation for Healthy
  Communities (FHC)"*
- CDFA: *"This investment of up to $40 million a year **in federal Rural Health
  Transformation Program funds** … **was approved by the Governor and Executive
  Council on March 16**"*

The date test passes on CDFA's own words: **2026-03-16** is eleven weeks after
the **2025-12-29** Notice of Award anchor.

**§0.2 in one document, for the second time after Virginia.** FHC's page carries
**two** CMS financial-assistance footers:

| Footer | Tier |
|---|---|
| *"financial assistance award totaling **$204,016,550.20**"* | Tier 1 — the state's allotment, matching the §7.1 anchor **to the cent** |
| *"financial assistance award totaling **$66,547,394**"* | Tier 3 — FHC's own award |

Both official, both "New Hampshire FY2026", only the tier separating them.

Per session 27's audit the footer is **non-strict**:
`nh_assert_footer_corroborates(strict = FALSE)` returns `NA` with a message
rather than throwing, so a page re-post that drops the boilerplate cannot
hard-fail New Hampshire for no reason — **and a future state whose only evidence
is a "this project" footer does not pass the test New Hampshire passes**. It
corroborates the **amount** and nothing else.

### §0.1 — RCJ prices one Council action at three different amounts

| Group | Rows | Disposition |
|---|---:|---|
| Medicaid Care Management | 3 | `NOT_RHTP_MEDICAID` |
| Foundation for Healthy Communities | 2 | `RHTP_AWARD_AMOUNT_UNDERSTATED` |
| CDFA | 5 | `RHTP_AWARD_AMOUNT_IS_A_CEILING` |
| Other GO-NORTH administrators | 16 | `RHTP_ADMINISTRATOR_NO_PRIMARY_AMOUNT` |
| Placeholder / unresolved | 1 | `AGGREGATOR_PLACEHOLDER_OR_UNRESOLVED` |
| | **27** | |

- **The Medicaid rows include the $1,898,965,390 against a $204,016,550
  allotment** that the §6.2 allotment ceiling flagged in session 5 and the
  provenance sweep independently disposed of in session 20 — **two §6.2 filters,
  opposite directions, same row**.
- **CDFA appears five times under three spellings at $43,810,000, $43,800,000
  (twice), $40,000,000 and a $1 placeholder.** Three distinct prices for one
  Council action is the tell that the aggregator is pricing **documents**, not
  awards — and §2 forbids a machine merging the spellings.
- **RCJ's FHC figure is the Council's rounded $66,500,000**, short of FHC's own
  $66,547,394 by $47,394.
- **The 16 administrator rows are a limit on our access, not on New Hampshire.**
  CCSNH, CBHA, USNH and NORC are each plausibly a real Council-approved award;
  none publishes its own figure on a reachable host, and §0.1 forbids publishing
  RCJ's in place of a primary one. They are in the status table, not the award
  file.
- **The $1 placeholder runs through the whole set** — Missouri's mechanism, the
  one defect no amount plausibility check can see.

---

## 3. memsa.org — re-tested, still unreachable, and now closed as a question

`memsa.org/rht-funding/` is where the Missouri EMS Association's own rural EMS
sub-awardee list would be — the ~$6.5M pass-through `mo_year1_awardees.csv`
carries as `PASS_THROUGH_UNRESOLVED`. Session 28 recorded it as unreachable
behind a captcha. Re-tested 2026-09-01: **unchanged**, and characterised three
ways further.

| Probe | Result |
|---|---|
| `/rht-funding/`, project honest agent | **202** + meta-refresh to `/.well-known/sgcaptcha/` |
| same, RFC crawler convention | **202** |
| same, bare `Mozilla/5.0` | **202** |
| same, full Chrome UA | **202** |
| apex `memsa.org/` | **202** |
| `memsa.org/robots.txt` | **202** |
| following the refresh target | **200** — *"Robot Challenge Screen"*, `<noscript>` falls through to a further captcha |
| `archive.org/wayback/available?url=memsa.org/rht-funding/` | **200** — `{"archived_snapshots": {}}` |
| `web.archive.org/web/2026/…` | connection reset (blocker 7, unchanged) |

Three findings, none of which session 28 had:

1. **It is not a user-agent question.** All four agents get 202, so **§3's
   michigan.gov exception would not help** — the measurement that stops a
   one-host exception being reached for a second time.
2. **`robots.txt` is itself 202**, so there is no crawler policy on offer and
   none is being declined; and the gate needs **JavaScript**, not a header.
3. **There is no archive route either, and this is the decisive one.**
   `archive.org`'s availability API — reachable since session 27 — answers 200
   and returns **no snapshots**. The Wayback Machine **holds nothing** for that
   url. So blocker 7 is *not* what stands between this project and MEMSA's
   roster; there is nothing behind it to fetch.

All of it is now in `mo_rcj_candidate_disposition.csv`'s MEMSA row, with the
four agents named so the claim is checkable rather than asserted, and a test
pinning every element. The claim it makes is **UNKNOWN, not NO**: whether MEMSA
has named its sub-awardees is not something this repository knows. And if it
ever answers 200, those sub-awardees are rural EMS agencies — a class DSS states
— and still not hospital dollars.

---

## 4. What moved

- `R/03w_mo_year1_awardees.R` — `mo_probe()`, `mo_content_digest()`,
  `MO_PROBE_KEYS`, `MO_AWARD_POSTED`, the memsa constants, `--probe`, and body
  overrides on `mo_assert_procurement_pending()`.
- `R/03x_nh_year1_awardees.R` — new.
- `data/evidence/NH/` — FHC and CDFA, with a SHA-256 manifest.
- `data/reference/nh_year1_awardees.csv` (2), `nh_year1_status.csv` (6),
  `nh_rcj_candidate_disposition.csv` (5) — new.
- `data/reference/mo_rcj_candidate_disposition.csv` — **one row**, the MEMSA
  `why`. `git diff --numstat` reports 1 insertion, 1 deletion.
- `data/reference/rcj_state_survey.csv`, `state_trigger_queue.csv` — **rebuilt**
  from `SURVEY_EXTRACTED_STATES`, never hand-edited. NH reads `EXTRACTED`;
  **Wisconsin now leads** at 19/19.
- `tests/testthat/test_03x_nh_year1_awardees.R` — new;
  `test_03w_mo_year1_awardees.R` and `test_state_union.R` extended.

**Byte-identity:** `mo_year1_awardees.csv` and `mo_hub_anchors.csv` rebuild
byte-identical. `MO_year1_awardees.xlsx` differed only in `dcterms:created` and
was reverted.

**Tests: 3,151 assertions across 33 files, all passing, 1 self-skipping**
(was 3,032 across 32). `test_03x_nh_year1_awardees.R` is new;
`test_03w_mo_year1_awardees.R` gains the probe and memsa blocks; and
`test_state_union.R` now combines **eighteen** state files, seventeen states —
its expected-state list widened for NH, which is the check that would have
caught the file being added without the invariant being updated.

**The CRLF trap was met a sixth time and did not land.** The Missouri
disposition row was rewritten through the extractor rather than by hand and
`git diff --numstat` reports **1 insertion, 1 deletion**. The 35-line diff on
`state_trigger_queue.csv` was checked before being accepted and is real: New
Hampshire leaving the queue renumbers every rank below it, exactly as Missouri's
extraction did last session.
