# Session 28 — Kansas's provenance wired, and Missouri's roster is not an award list

Zero RCJ quota. ~20 requests to `dss.mo.gov`, `content.govdelivery.com` and
`ctf4kids.org`, throttled per §9.5. No Kansas fetch at all — everything Kansas
needed was already committed.

---

## 1. Kansas: the audit's one load-bearing case, closed by reading

Session 27 audited every state that used the CMS financial-assistance footer as
its §6.2 provenance test and found **Kansas the only load-bearing case**. Its
REH CAP / RPGP award PDF opens *"This **presentation** is supported by the
Centers for Medicare & Medicaid Services (CMS) … as part of a financial
assistance award totaling $221,890,007.82"*, and `ks_assert_rhtp_funded()` read
that string and nothing else — for **39 of 46 rows, $79,013,347, 98.7% of
Kansas's dollars and 98.4% of its named-hospital floor**.

Two things are now measured rather than asserted about that document:

```
"This presentation is supported by"        1 occurrence
"This Rural Health Transformation Program" 0
"Rural Health Transformation"              0
"RHTP"                                     0
```

**The award document never names the programme its awards belong to.** That is
the weak grammatical form the audit named — a claim about the paper, not about
the grants — and Nevada is where the difference stopped being pedantic: NVHA's
workforce deck carries the identical footer while describing two STATE-funded
programmes worth $15.8M and $60M beside one RHTP one (session 26).

### The two independent, programme-scoped sources, both already committed

**1. KDHE's programme page.** Its sentences take the GRANTS as their subject:

> "KDHE today announced the recipients of the Regional Partnerships Grant
> Program (RPGP) and Rural Emergency Hospital Conversion/Transformative Capital
> Investment Program (REH/CAP) grants **through the Kansas Rural Health
> Transformation Program (RHTP)**. In total, **$79.1 million is being awarded to
> 39 organizations**…"

> "…the recipients of the Community Health Worker + Accountable Food is Medicine
> Grant Program (CHW+AFIM), **an initiative within the Rural Health
> Transformation Program (RHTP)**. In total, **$1,007,152 was awarded to seven
> rural healthcare organizations**…"

Both pool scales are published **on the page, independently of the award PDFs**,
so a parse that drifted from the documents now fails here as well as in the
reconciliation. 39 = REH CAP 17 + RPGP 22, and 7 = CHW+AFIM, asserted.

**2. The Kansas RHT Plan Year 1 Budget Narrative** — registered in `KS_SOURCES`
as `budget_rev2` since session 20 and **never opened**. It is programme-scoped
by construction: it is the SF-424A expenditure plan *for* the RHT Plan, every
page is headed "Kansas RHT Plan Year 1 Budget Narrative", and it places all
three awarded pools inside the plan's own initiative structure —

| | Initiative | Programme |
|---|---|---|
| A-FIM + CHW | 1 (Expand Primary and Secondary Prevention) | Program 1 |
| RPGP | 2 (Secure Local Access to Primary Care) | Program 1 |
| REH-CAP | 2 | Program 2 |

**It carries no CMS footer at all**, and does not need one: the document is the
plan. Its Initiative Year-1 totals ($25,291,240.16 and $97,263,092.46) were
already in `KS_STATED` and had never been asserted; they are now.

**The plan's amounts are deliberately NOT reconciled against the awards.** It
budgets RPGP at $49,969,410.72 and REH-CAP at $31,279,891.30; KDHE awarded
$49,915,410 and $29,097,937. A plan is not an award (§0.3), and a test pins that
they differ so a later session does not "close" the gap by moving an award
figure.

### The date test, asserted for the first time

The audit noted Kansas was the only one of the five footer states with no
`*_assert_after_noa()` — its 6 March 2026 webinar date lived in a **comment**.
`ks_assert_after_noa()` now reads KDHE's own Year One Timeline —
**"Dec. 29, 2025 - Notice of Award"** — cross-checks it against
`cms_state_noa_dates.csv`, and requires the 6 March 2026 applicant webinar to
still be linked.

### The footer is kept, and demoted

`ks_assert_rhtp_funded()` gains `strict =` and, called non-strictly by
`ks_assert_rhtp_provenance()`, returns `NA` with a message instead of throwing.
Both directions matter: a KDHE re-post that dropped the deck's boilerplate can
no longer hard-fail Kansas for no reason, **and a future state whose only
evidence is a "this publication" footer does not pass the test Kansas passes
today.**

### The $8,000.18 belongs to one document, not to KDHE

Session 20 recorded it as *"two publishers disagree about Kansas's award"*.
Reading KDHE's other two publications for the first time closed it:

```
award slide deck   $221,890,007.82   out by $8,000.18
programme page     $221,898,007.82
RHT Plan Table 1   $221,898,007.82
CMS's own table    $221,898,008      gap $0.18
```

**KDHE and CMS agree. The award deck alone transposes 898 as 890.** Nothing is
corrected (§8) — the deck still says what it says — and the assertion now pins
the deck's gap AND its absence everywhere else.

### Nothing moved

`ks_year1_awardees.csv` rebuilds **byte-identical** (sha256 unchanged): 46 rows,
$80,020,499, 21 named hospitals, $35,721,277. The xlsx differs only in
`dcterms:created` and was reverted.

---

## 2. Missouri: a named 27-organisation roster, and not one row is an award

Missouri led the queue after Michigan — 29 Tier 3 candidates, 29 distinct
awardees, a $216,276,818 allotment, no CMS release, never investigated.

**The route in was `/api/v1/activity` again** — Oregon's, Oklahoma's and
Nevada's lesson a fourth time. `state_source_url` is NA on all 29 Missouri Tier
3 records; `stage2_state_sources.rds` held nine real URLs including
`mydss.mo.gov/mhd/rural-health` (which 301s to `dss.mo.gov`).

### What DSS publishes

**Twenty-seven named organisations, one per ToRCH Care Hub, chosen competitively
from 41 applications, announced 2026-07-17 — and NOT ONE IS AN AWARD.** They are
Hub **Anchors**: organisations selected to *convene* a hub. DSS attaches no
dollar figure to the role anywhere, and answers the question in its own FAQ:

> **Q36. Will Hub Anchors receive funding or compensation?**
> "Hub Anchors will **not act as the fiscal agent**. … The State will fund
> additional staff to support implementation via the Healthier Communities
> Together entity."

and the release adds that participation is *"subject to execution of a Hub
Anchor Participation Agreement"* — an agreement not executed. **Fourteen of the
27 are hospitals or health systems by name**, so coding the roster as receipt
would be §0.3's exact failure at the scale of a whole state: fourteen named
hospitals, `distributed_to_hospital = Yes`, and **no money behind any of them**.

The roster is kept — in **its own file**, `mo_hub_anchors.csv`, which has **no
`amount` column at all** and an assertion refusing one (Texas's device). It is a
real and quotable finding about which organisations lead Missouri's RHTP; it is
not a hospital dollar, and it is deliberately **not** in `test_state_union.R`.

### What Missouri has actually awarded: two partnerships, $7,232,660.43

| Recipient | Amount | Note |
|---|---:|---|
| Missouri Doula Association | **$732,660.43** | exact; "was awarded to the MDA", 2026-07-20 |
| Missouri EMS Association (MEMSA) | **~$6,500,000** | "around $6.5M **through July 31, 2027**", 2026-07-24 |

**Neither reaches a hospital.** MDA trains doulas and perinatal community health
workers, with hospitals named as *partners* the workforce is integrated into —
§10.2's in-kind test, not receipt. MEMSA re-grants to **rural EMS agencies** at
up to $250,000 (agency) or $500,000 (regional system) and has named none of
them; the eligible class is stated and it is not hospitals, so unlike Illinois's
ICAHN pool there is nothing unresolved about where those dollars go.
**Missouri's named-hospital dollars are $0.**

MEMSA's figure carries `AMOUNT_ROUNDED_IN_SOURCE;AMOUNT_IS_MULTI_YEAR_TOTAL` —
it is approximate *and* runs past Budget Period 1, which ends 2026-10-30.
Indiana's precedent: the figure is kept, because it is one of only two Missouri
has published, and both caveats are flagged.

### §6.2 with the footer downgraded — the audit applied to a new state

Every DSS release and the FAQ carry a CMS footer, and it is the **weak** form:
*"The Rural Health Transformation Program **information provided by** the
Missouri Department of Social Services is supported by … $216,276,817.66"*. Its
subject is the publication. So it corroborates the **amount** — $216,276,817.66
against the §7.1 anchor's $216,276,818, a $0.34 gap — and three
**programme-scoped** sentences carry the provenance, each asserted:

1. *"$732,660.43 **was awarded to the MDA** … The investment **is part of the
   RHTP**"* — the award action itself.
2. *"DSS, **through the Rural Health Transformation Program (RHTP)**, has
   announced a partnership … Administered by DSS on behalf of CMS"*.
3. *"DSS has selected Hub Anchor organizations to help lead implementation of
   **Missouri's Rural Health Transformation Program (RHTP)**"*.

And the date test: every document is dated July 2026, **seven months after**
Missouri's 2025-12-29 Notice of Award.

### The controls, in two parts, because Missouri has two award channels

- **DSS publishes a roster in a recognisable form when it has one** — the Hub
  Anchor PDF hangs off a "View Organizations" link. Exactly one such link
  exists; a second means a pool this file does not carry.
  The control deliberately does **not** fire on DSS's Hub Anchor *application*
  packet or its invitation-to-apply release, both of which carry "Hub Anchor" in
  their link text: a control that fired on those would be widened every time it
  fired, which is how a tripwire becomes decoration.
- **Indiana's sixth question, answered by the state rather than inferred.**
  DSS's own RHTP timeline reads *"Aug - Sept 2026 Announce select procurement
  awardees"*, so Missouri's awards are coming through **procurement**.
  `dss.mo.gov/bids` is archived: it carries live solicitations — **IFB
  DSS26015-02 closed 2026-09-01, the day this ran** — and no awards, which is
  what makes the absence a finding.
- **The pass-through control**: the Children's Trust Fund administers $588,000/yr
  of RHTP home-visiting money and its funding page reads *"Stay tuned for
  future"*.

### §0.1 — a mechanism this project had not recorded

**RCJ's 29 Missouri Tier 3 candidates are the 27 Hub Anchors, each at $1, plus
MEMSA and MDA.** So **93% of Missouri's candidate set is a governance-role
selection presented as awards, complete with hospital names.**

| | Texas | Oregon | Indiana | Oklahoma | Michigan | **Missouri** |
|---|---|---|---|---|---|---|
| What RCJ got wrong | the PROGRAMME | the RECIPIENT CLASS | an INVENTED label | the TIER | one row per ORGANISATION | **the KIND OF ACTION** |

And it is the one an amount check cannot see: RCJ publishes **$1**, a
placeholder, not a wrong figure. It also **understates the one exact award it
holds** — $732,000 against DSS's $732,660.43.

### The unstated-form question, a seventh time — and worth $0

DSS publishes an organisation name per hub and nothing about its form. 14 of 27
classify as hospitals on the recipient's own name; **11 fall to §8's standing
fallback**, and five of those read as hospitals to anyone who knows Missouri —
Ozarks Healthcare, Golden Valley Memorial Healthcare, Bothwell Regional Health
Center, Hannibal Regional Health Center, Parkland Health Center. **Nothing was
promoted (§0.4).** It is worth **$0 in either direction**, because there are no
amounts: the question moves a **COUNT** — 14 of 27 today, an honest ceiling of
25 — which is Nevada's shape. Queued as `MO_ANCHOR_FORM_NOT_STATED`, with
`MO_ANCHOR_IS_NOT_AN_AWARD` beside it recording the roster decision itself.

### One host is unreachable, and is recorded as unreachable

`memsa.org/rht-funding/` — where MEMSA's own sub-awardee list would be — answers
**HTTP 202 with an `sgcaptcha` redirect** to every client tried. So this file
cannot say whether MEMSA has named its EMS sub-awardees. It says it does not
know, which is a different claim (§0.4) and is recorded in the manifest.

### Where Missouri's hospital money will be

The **ToRCH Care Smart Growth and Service Line Modification IFB (DSS26015)** —
*"nearly $40 million"* anticipated across Program Years 1 and 2, **individual
awards of up to $5 million**, and *"Funding is open to hospitals"*. Horizon-2
(DSS26015-02) closed 2026-09-01. `mo_assert_procurement_pending()` is **designed
to fail** the day DSS announces those awardees.

---

## 3. The three buckets, across sixteen states

Re-derived from the seventeen committed state files rather than carried forward.

```
                          ROWS       DOLLARS   STATES
NAMED_HOSPITAL        :    417   388,327,247       12
POOL_NAMED_HOSPITALS  :      1    18,156,856        1   NE — the Nebraska High
                                                        Value Network
POOL_UNNAMED_HOSPITALS:      1    50,008,264        1   IL — ICAHN
```

**None may be added to another**, and a fourth quantity sits outside all three:
`FLOW_UNRESOLVED_HOSPITAL_AFFILIATED`, **$8,625,000 across 3 rows** — Michigan's
two MHA awards and Nevada's Incline Village Community Hospital Foundation (which
carries no amount).

**Missouri contributes 0 rows to every bucket**, and its 27-organisation roster
with 14 named hospitals sits outside all four by construction. That is the
session's shape in one line: a state can publish more named hospitals than
Nevada and still contribute nothing a dollar column can hold.

---

## 4. Tests

**3,032 assertions across 32 files, all passing, 1 self-skip** (was 2,889 across
31). `test_03w_mo_year1_awardees.R` is new — 101 assertions, including the two
that matter most: the roster parser refuses a truncated read (hubs must be
1..27 with no gap), and `mo_assert_anchors_not_awarded()` is driven to failure
three ways — a roster carrying a dollar figure, and each of DSS's two
disqualifying sentences removed in turn. `rhtp_mo_assert()` is also driven to
failure with an `amount` column added to the roster.

`test_03o_ks_year1_awardees.R` gains eleven tests: the footer's weak form and
its zero mentions of the programme, the footer's new non-strict behaviour, both
programme-scoped sources and their gutted-input refusals, the plan-vs-award
amounts that are deliberately not reconciled, the date test and its refusal,
and the three award figures.

`test_state_union.R` now combines **seventeen** files across sixteen states.
