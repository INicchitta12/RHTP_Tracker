# Session 33 — Maine names eleven hospitals and awards none of them

**Date:** 2026-09-02
**Quota:** zero RCJ calls. ~20 requests across `www.maine.gov`, `www1.maine.gov`,
`mainedoenews.net`, `www.mcd.org` and `mevss.hostams.com`, throttled per §9.5.
**Files:** `R/03aa_me_year1_awardees.R`, `tests/testthat/test_03aa_me_year1_awardees.R`,
`data/evidence/ME/` (13 sources + manifest), four reference CSVs,
`ME_year1_awardees.xlsx`.

---

## 1. The headline

Maine led the RCJ_ONLY queue at 12 Tier 3 candidates, and **eleven of the twelve
are named Maine rural hospitals**. No state has reached the top of that queue
looking more like a hospital extraction.

It is not one, and Maine says so in its own words.

| | |
|---|---:|
| CMS FY2026 allotment | $190,008,051 |
| Announced across five channels | $101,000,000 (53.2%) |
| **Award actions evidenced to a named recipient and a figure** | **1, $12,000,000** |
| **Named-hospital award rows** | **0** |
| **Named-hospital dollars** | **$0** |
| **Named hospitals that are NOT recipients** | **11** |

## 2. The eleven, and why they are not awards

DHHS's 2026-07-31 release is headed *"Maine DHHS **Releases** $30 Million to
Strengthen Rural Hospital Resiliency"*. Its sub-headline is the whole finding:

> Eleven rural hospitals **invited to receive** funding and technical assistance
> to strengthen long-term financial sustainability

DHHS *"has identified and invited 11 rural hospitals to participate in the
initiative based on an analysis of hospital financial data publicly available
from the Maine Health Data Organization."* **They did not apply.** The $30M is
published in two phases — approximately $3M *"will be distributed among
participating hospitals"* for staff time, and approximately $27M *"will be
available to support **approved** hospital-identified efficiency projects"* —
and DHHS divides neither.

**The load-bearing evidence is the State's own advisory deck, five days later.**
The RHTP Advisory Committee's 2026-08-05 status update says, of the Rural
Hospital Efficiency Fund:

> **Eligible hospitals to participate in this cohort identified.**
> **Award amount and approved budget will be confirmed after start of
> participation in the HE Cohort**

against a three-milestone timeline reading **July** *Communicate approach to
eligible hospitals* → **September** *HE Cohort begins* → **Fall / Winter**
*Funding approved and provided*. This session ran on 2026-09-02.

So the eleven live in **`me_rhef_cohort.csv`**, which

- has **no `amount` column**, and `me_assert_cohort_no_amount()` refuses one;
- is **not** in `test_state_union.R`;
- carries `award_made = No`, `amount_published = No`, `agreement_executed = No`
  on every row.

`me_assert_cohort_not_awarded()` is **designed to fail** the day DHHS confirms
an amount, at which point the file must be **rewritten, not patched** — exactly
as `mo_assert_anchors_not_awarded()` is for Missouri's Hub Anchors.

**Slide 15 of the deck is titled "RHEF Year 1 Cohort Mapped" and is image-only.**
Its text layer holds the title, the footer and the page number and **none of the
eleven names**. That is said rather than glossed (§0.4), and asserted.

## 3. The pairing, inverted

Nevada (session 26) and Iowa (session 32) publish **named hospitals with no
amounts**, so the danger is reporting `dollars = 0` without `rows = 20` or
`rows = 152`. `nv_assert_zero_dollars_is_not_zero_hospitals()` and its Iowa twin
exist for that.

**Maine is the opposite case and needs the opposite guard.** It has eleven named
hospitals and **zero** hospital award rows, and the mistake is *counting* them.
`me_assert_named_hospitals_are_not_recipients()` asserts **both halves at once**:
that `rhtp_hospital_dollar_partition()` returns **no bucket at all** for Maine,
and that eleven named hospitals nevertheless exist in this repository, in a file
that is not an award file. A reader who sees "$0 hospital dollars" and concludes
Maine named no hospitals is as wrong as one who counts the eleven.

## 4. Maine's one award action

**The University of New England's Shaw Institute for Public and Planetary
Health, $12,000,000**, announced by DHHS on 2026-07-31 — **on the DHHS blog, not
the news index**, which is why `me_assert_award_index()` covers both channels. A
hunt that read only `/dhhs/news` would have missed Maine's only priced award.

It is `UNIVERSITY_OR_AHC`, `NON_HOSPITAL`, `distributed_to_hospital = No`, and
**that coding turns on the eligible class**, which is New Hampshire's question
from session 29 answered the other way:

> UNE will provide this support by **establishing subrecipient agreements with
> organizations in Maine's Public Health Districts and with each Tribal Health
> Center**.

The class is *stated* and contains no hospital — Missouri's MEMSA coding — where
New Hampshire's FHC named *"critical access hospitals"* among others and is
therefore `Unclear`. `amount_confirmed = No`: DHHS's word is **"allocated"**,
and this post's CMS footer, **uniquely among Maine's three**, adds *"pending
approval of revised budget"*.

The "Hospital to Home" programme UNE will manage is a **programme name, not a
recipient** (§0.3a). Whether it makes the row `IN_KIND_BENEFIT` is queued as
`ME_UNE_HOSPITAL_TO_HOME_FLOW`, worth $0 either way.

## 5. Every other channel is pre-award, and each has a date

| Channel | Pool | Stage |
|---|---:|---|
| EMR Modernization (via MCD Global Health) | $30.0M | applications closed 8/14; **"Provider contracts executed" FALL**; ~70 eligible orgs / ~330 sites |
| APM Transition | $28.5M | applications due late August; **"Payments issued" SEPT/OCT**; 58 eligible orgs |
| Rural Hospital Efficiency Fund | $30.0M | cohort invited; **funding approved FALL/WINTER** |
| Healthcare Careers Exploration (Maine DOE) | $0.5M | **"Award Announcement: August 31, 2026" — TWO DAYS BEFORE THIS RAN**, no roster published |
| UNE Population Health Partnership | $12.0M | partner named; **no subrecipient named** |

Maine DOE's is the most overdue negative in the file and the first thing to
re-probe. The EMR channel's pre-award state is stated by **two publishers**:
DHHS's release (*"expected to receive an award"*, future tense) and MCD Global
Health's own partner page (*"APPLICATIONS CLOSED 8/14"*, *"COMING SOON"*).

## 6. §6.2, and a measurement from the other direction

All four DHHS RHTP pages carry *"**This program** is supported by the Centers
for Medicare & Medicaid Services … as part of a financial assistance award
totaling **$190,008,051.09**"*, which rounds to the §7.1 anchor's $190,008,051
exactly. Its grammatical subject **names no programme** — session 30's Wisconsin
weak form — so it corroborates the **amount** and is non-strict.

**Maine supplies the measurement from the other side, and it is new.** The Maine
DOE funding opportunity carries **no CMS footer at all** — not the sentence, not
the amount, not "Centers for Medicare" — and is unambiguously RHTP, because it
says so in its own words:

> Funding for this opportunity is made available through Maine's **federal Rural
> Health Transformation Program award**, administered by the Maine Department of
> Health and Human Services.

So on Maine's own estate the footer is **neither necessary nor sufficient**. What
is present on every RHTP document is a **programme-scoped sentence**; three of
them, from **three publishers** (DHHS's release, DHHS's blog, Maine DOE), carry
the provenance and each is asserted every run.

The date test passes independently: the Governor's own 2025-12-29 statement is
archived and carries its date, which matches `cms_state_noa_dates.csv`, and every
other source is dated 2026.

## 7. The controls

**THE POSITIVE CONTROL IS THE LARGEST THIS PROJECT HAS USED.** Maine's published
RFP archive holds **1,406 solicitations, 1,362 of them carrying a named awarded
vendor**, DHHS among the issuing departments (*"Substance Use Peer Navigators —
Awarded — Maine Access Points"*). Maine publishes awarded vendors in a
recognisable, machine-readable form at scale, so **"no RHTP award row" is a
statement about Maine and not about our reading**. Not one row is RHTP, and
`me_assert_procurement_control()` fails the day one appears.

**THE NEGATIVE CONTROL IS INSIDE THE POSITIVE ONE.** Three rows down the same
column: *"**Small Rural Hospital Improvement Program (SHIP)** Facilitation and
Project Management"* — awarded, named vendor, DHHS, **"Rural Hospital" in its
title**, and **HRSA-funded rather than RHTP**. It is exactly what a title-keyed
reader would take (§6.2's federal branch), and losing it removes the control
rather than passing quietly.

**And reading that archive exposed a parsing defect worth recording.** The page
carries **two tables whose column orders differ** — the first is headed
`Title | RFP # | …`, the second `RFP # | RFP Title | …`. A positional reader that
resolved columns once for the page reads 1,158 titles as solicitation numbers,
finds no RHTP row, **and finds no negative control either** — which is how this
was caught. `me_procurement_rows()` resolves columns **by synonym against each
table's own header** (session 10's rule) and **refuses** a table whose header it
cannot resolve, rather than reading it positionally. Three tests pin it.

## 8. §0.1 — Missouri's defect a second time, and worse

RCJ's twelve Maine candidates:

| Group | Rows | Disposition |
|---|---:|---|
| The Rural Hospital Efficiency Fund cohort | **11** | `RHTP_COHORT_INVITED_NOT_AWARDED` |
| University of New England | 1 | `RHTP_AWARD_CARRIED_CORRECTLY` |
| Anything else | 0 | — |

**The names are exactly right.** RCJ's eleven match DHHS's roster **name for
name**, once an en dash is normalised — the only independent reading this file
has of the cohort parse, and asserted (Iowa's device). **What is wrong is the
KIND OF ACTION**: RCJ carries all eleven as Tier 3 awards **at $1 each**.

That is **Missouri's defect a second time** — the wrong kind of action, published
as a placeholder rather than a wrong figure, so no amount check can see it — and
it is worse here. In Missouri 14 of 27 roster rows were hospitals; **in Maine
eleven of eleven are**. An extractor built from this candidate list would have
published eleven named Maine rural hospitals as RHTP recipients on the strength
of a $1 figure.

The one candidate RCJ prices is the one real award, and it prices it **exactly**:
$12,000,000 against DHHS's *"$12 million"*.

**The §6.2 sweep catches zero Maine rows and all twelve are undatable** — RCJ
carries no date for any of them — so the sweep's clean line is a statement about
the registry's coverage, not about Maine (Nebraska's lesson, session 23).

## 9. What is UNKNOWN, and recorded as UNKNOWN

Maine's 2026 solicitations route through the **CGI Advantage Vendor Self Service
portal** (`mevss.hostams.com`), which answers HTTP 200 but is a stateful
JavaScript application this environment cannot search, and the published RFP
archive's most recent parsed posting is **2025-10-08**. So whether a 2026 RHTP
contract has been executed through procurement is **UNKNOWN to this repository**
— a statement about our access and never about Maine (§0.4). It is the one
`me_year1_status.csv` row reading `UNREADABLE` / `UNKNOWN`.

`www.maine.gov` answers the project's **honest agent** with HTTP 200 on every
host used here, so §3's michigan.gov exception is not reached and must not be.
Page digests are **stable** — two fetches three seconds apart returned the same
SHA-256 — so unlike Nevada, Missouri and Wisconsin a **file digest** is a usable
change test, and `--probe` uses it directly.

## 10. Where Maine goes next

`R/03aa_me_year1_awardees.R --probe` re-fetches the four watched pages and runs
the award tripwires **against the live bytes** (session 25's Indiana lesson as
code). It ran live this session and reports **UNCHANGED** on all four.

Four things will move, and three of them are overdue or imminent:

1. **Maine DOE's Healthcare Careers Exploration awards** — announcement date
   **2026-08-31, already passed**. Up to four awards of $125,000.
2. **The Rural Hospital Efficiency Fund cohort begins in SEPTEMBER**, with
   funding approved Fall/Winter. When DHHS confirms amounts, the eleven become
   award rows and `me_rhef_cohort.csv` must be **rewritten**.
3. **EMR provider contracts execute in the Fall** (~70 organisations, ~330
   sites) — and that is Maine's hospital money: Critical Access Hospitals and
   general hospitals with a dedicated ED are the first eligible class named.
4. **APM payments issue September/October** (58 organisations, $28.5M).
