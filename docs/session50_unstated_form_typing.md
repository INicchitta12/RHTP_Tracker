# Session 50 — the unstated-form question is answered for Mississippi and South Carolina

**Date:** 2026-09-22 · **Quota:** zero RCJ calls. Network: three CMS enrolment
files, the ProPublica/IRS nonprofit API, one CMS provider dataset query and two
fetches of `winstonmedical.org`.

Four tasks, and they are not independent: task 2's organisation is inside task
4's set, and task 1 moves nothing at all. **Read the dollar table in §6 before
quoting any figure from this session.**

---

## 1. Task 1 — `VQ_INKIND_AFTER_RETYPE`: option (a), and the sources say why

Session 49 re-typed four rows that carried `IN_KIND_BENEFIT`, re-ran the flow
test on three and held the fourth. All four shared one generated basis sentence
— *"the recipient is not a hospital and keeps the funds"* — whose first half the
verification overturns, so session 49 called the distinction **real and also
thin** and queued it.

**The four KDHE and MDH award paragraphs were read. The distinction is not
thin; it is in the grammar of the source.**

| row | the source's own sentence | subject |
|---|---|---|
| **Stormont Vail Health**, $5,465,969 | *"**Stormont Vail HealthCare proposes** PrairieLINK, a regional clinically integrated network and shared services infrastructure…"* | the awardee |
| **Greeley County Health Services**, $1,541,906 | *"**Greeley County Health Services will develop** the Western Kansas Shared Services Group…"* | the awardee |
| **Meritus Health Center**, $3,583,406 | MDH's Pillar 2 table heads its first column **"Lead Organization"**; the summary is a precision medicine clinic, five primary-care recruitments and *"the All-In-Health Model"* | the awardee |
| **Salina Regional Health Center**, $932,310 | *"**Five founding providers will form AstraHealth Kansas**, a shared services organization providing benchmarked clinical data, analytics dashboards and legal/governance infrastructure **to** rural hospitals across Kansas."* | **not the awardee** |

On the three that moved, the hospital receives money for work it performs, which
is §10.2's `DIRECT` row on recipient identity. **Salina's paragraph is the only
one of the four in which the awardee is not the subject of the sentence**: the
money capitalises a **new, separate organisation** of which Salina is one of five
founders, and what reaches rural hospitals is a *service*. That is session 31's
money-movement test, and it now rests on the source's own grammar rather than on
session 31's authority alone.

**Resolved (a). $10,591,281 stays in; $932,310 stays out; net $0.**

---

## 2. Task 2 — Winston County Medical Foundation, and the rule it needed was not §10.2's

Session 49 refused to promote it because *"the name states a COUNTY, not a
hospital, and no source in hand says whose arm it is"*. Two federal publishers
now say, and they say something stronger than the rule was asking for.

- **CMS Hospital Enrollments (2026-07-31)** carries `ORGANIZATION NAME` =
  **`WINSTON COUNTY MEDICAL FOUNDATION`**, Louisville MS, against **CCN 250027**
  — the state's published awardee string *is* the hospital's legal name.
- **The IRS Business Master File** gives the same body as
  **"Winston County Medical Foundation Dba Winston Medical Center"**, and its
  Form 990 checks *"operated one or more hospital facilities"* (Schedule H).
- CMS's provider dataset lists **Winston Medical Center**, 17550 East Main
  Street, Louisville MS, *Acute Care Hospitals*, *Voluntary non-profit –
  Private*; the foundation's registered address is 17570 East Main Street, the
  same campus.

**So §10.2's hospital-foundation row is not reached at all. The foundation is
not the arm of a hospital — it is the hospital's own legal name**, and the
answer is ordinary §8 typing. `HOSPITAL_OR_SYSTEM`, `MEDIUM`, `basis_type =
ORG_WEBSITE`. **Four rows, +$3,785,455.49**, including the row that carried
`IN_KIND_BENEFIT`, whose flow re-ran to `DIRECT` because the re-type crosses
§10.2's `DIRECT` test.

---

## 3. Task 3 — Iowa's Centers of Excellence pool, recorded with its tier on it

`PHTHORC26008` holds **ten award actions** and session 49 established that every
one of the ten recipients is a hospital. Iowa publishes **no per-hospital
split**, which is `POOL_NAMED_HOSPITALS`'s condition word for word (§8,
Nebraska's code, session 23). Row 265 of `ia_year1_awardees.csv` records it:

```
awardee : Centers of Excellence (PHTHORC26008) -- POOL ROW: the ten named
          hospitals above, with NO per-hospital split
amount  : 50,000,000        amount_confirmed : No
flag    : AMOUNT_IS_POOL_NOT_AWARD   hospital_attribution : POOL_NAMED_HOSPITALS
```

**The concern, stated rather than buried.** The $50,000,000 is the notice's own
CMS footer, which `ia_notice_footers.csv` records as **`SOLICITATION` — Tier
2** — the pool the RFP was advertised at, in the notice's own word
*"approximately"*, and not an award total. Nebraska's $18,156,856 in the same
bucket is a **Tier 3** award amount from a signed notice of award, so the bucket
now holds two figures of different tiers. **And the ten award actions are still
in `NAMED_HOSPITAL` at $0**, so the same ten awards appear in two buckets: a
reader adding the *row counts* counts the Centers of Excellence twice. The
buckets are never added — `rhtp_hospital_total()` refuses — which is what keeps
this legible rather than double counting, and the awardee string says **POOL
ROW** in capitals for the same reason. Queued as `IA_COE_POOL_IS_TIER_2` with
all three options priced.

**`AMOUNT_IS_POOL_NOT_AWARD` was added to `vocabularies.csv`** with full notes,
on the footing sessions 12, 17, 19, 26, 39 and 49 established: a condition no
existing code covers. It is not `AMOUNT_PRELIMINARY` (which says a
per-recipient figure is not final — here there never was one), not
`AMOUNT_RANGE_IN_SOURCE` (which has bounds), not `AMOUNT_ROUNDED_IN_SOURCE`
(which is a rounded award). **A row carrying it must also carry a pool
attribution**, and `ia_assert_no_amount_column_effect()` enforces that.

That assertion was **narrowed, and the narrowing is the point**: it used to
require `amount` to be `NA` on every row, which was honest while the file held
nothing but award actions. It now asks the sharper question — is `amount`
populated on any row that is *not* the pool row? — so "Iowa prices nobody" is
still asserted on all 264 award actions.

---

## 4. Task 4 — 246 rows typed directly, under session 49's three policies

`R/03aq_unstated_form_typing.R`. **169 of the 173 organisations across the two
states are typed; four are refused.**

### 4.1 The evidence is mostly a federal record, not general knowledge

Session 49's queue pass was 306 `GENERAL_KNOWLEDGE` answers of 399, because a
verifier answering by hand has their own knowledge and the organisation's
website. This pass leans on three machine-readable federal enrolment files,
which are a second publisher in §0.4's sense:

| source | what it settles |
|---|---|
| **CMS Hospital Enrollments** | legal `ORGANIZATION NAME` **and** DBA, against a CCN |
| **CMS FQHC Enrollments** | every FQHC site, by operator |
| **CMS Rural Health Clinic Enrollments** | every RHC, by operator |
| **IRS Business Master File / Form 990** | 501(c)(3) status, NTEE, Schedule H |

An exact match of the state's published awardee string to an `ORGANIZATION NAME`
or DBA is `ORG_WEBSITE` → `MEDIUM`. **70 of the 74 rows that move into
`NAMED_HOSPITAL`, worth $71,354,639.67, rest on one of those records.**

### 4.2 The four that do not, named so a reader can subtract them

| organisation | $ | why it is a judgement and not a record |
|---|---:|---|
| **Ochsner MS** (MS) | 3,000,000 | a shorthand no federal record carries; Ochsner Rush Medical Center is in Lauderdale County and so is the award |
| **Webster Healthcare Services, Inc.** (MS) | 500,000 | CMS says `WEBSTER HEALTH SERVICES INC` dba Webster General Hospital — **one word different**; the award's county is Webster and CMS lists no other hospital operator in it |
| **Southwest Mississippi Regional Center** (MS) | 277,077 | **a real rival**: the Department of Mental Health's regional centre is in Lincoln County, the medical center in **Pike**, and the award's county is Pike |
| **Acadia Healthcare Co.** (SC) | 5,565,253 | see §4.4 |

All four are `GENERAL_KNOWLEDGE` → `LOW`. §2 forbids a **machine** resolving a
fuzzy hospital match; each of these is hand-read and visible in `UF_TYPES$why`,
which is the shape Arkansas's `AR_RELEASE_SPELLINGS` established.

### 4.3 What each state got

| | MS | SC |
|---|---:|---:|
| `FQHC_OR_RHC` | 23 | 30 |
| `HOSPITAL_OR_SYSTEM` | 16 | 58 |
| `OTHER` (a determined form §8 does not carry) | 27 | 14 |
| `PHYSICIAN_PRACTICE` | 25 | 14 |
| `NONPROFIT_CBO` (determined, not the fallback) | 3 | 11 |
| `STATE_AGENCY` | — | 19 |
| `LOCAL_GOVT_OR_PUBLIC_HEALTH` | — | 1 |
| **rows typed** | **94** | **147** |
| **rows left on the fallback** | **2** | **3** |

**South Carolina's nineteen SCDBHDD rows are typed `STATE_AGENCY`.** Session 47
deliberately left them on the fallback because §8's name rule does not reach an
acronym; typing them directly is what this pass is for, and it moves **$0** —
they were already `distributed_to_hospital = No`.

**Mississippi's five regional community mental health centres are `OTHER`**, with
the form stated: a CMHC is not a hospital and is not the awarding agency, so
`STATE_AGENCY` would make a recipient look like the grantor.

**Two stem traps are refused by name.** *Singing River Services* is the Region 14
community mental health centre, not **Singing River Health System** (a different
county). *George Regional Health and Rehab* is a skilled nursing facility, not
**George Regional Hospital**, which is not an awardee here at all.

### 4.4 Acadia Healthcare Co. — typed and queued in the same breath

**The largest single judgement in this pass, at $5,565,253.** Acadia is a
hospital operator: CMS carries `HHC SOUTH CAROLINA INC` dba **Lighthouse
Behavioral Health Hospital**, Conway SC, CCN 424002, `SUBGROUP - PSYCHIATRIC =
Y`. But the awardee string is the **corporate parent**, whose South Carolina
estate *also* includes Ridgeland Comprehensive Treatment Center and South
Carolina Comprehensive Treatment Center — both outpatient opioid treatment
programmes, both separately awarded here, both typed `OTHER`. No source
publishes a split and §6.2 forbids inventing one.

§0.3a codes the **recipient** and the recipient is a hospital company, so it is
typed `HOSPITAL_OR_SYSTEM` at `LOW` **and** queued as `SC_ACADIA_PARENT_SCOPE`,
with the arithmetic both ways in the queue row.

### 4.5 Four organisations are refused, and the largest is the one that matters

| | $ | why not |
|---|---:|---|
| **Delta Health Transformation Council, Inc.** (MS) | 3,000,000 | no federal enrolment or IRS record carries it, and it shares a stem with **both** Delta Health System (the Greenville hospital) and Delta Health Center (the FQHC) — a stem match could type it either way and neither would be a determination |
| **CAMHP Foundation** (MS) | 250,000 | no Mississippi entry in the IRS BMF; typing it on the word *Foundation* alone would be §10.2's rule applied with no parent |
| **Community Initiatives Inc.** (SC, 2 rows) | 295,000 | a generic corporate name nothing resolves |
| **Graceful Health Solutions, LLC** (SC) | 454,320 | ditto |

They keep §8's standing fallback **and** `RECIPIENT_TYPE_INFERRED`, because that
flag's own note says it means the form is undetermined and on these five rows it
still is. Queued as `UF_FORM_NOT_DETERMINABLE`.

---

## 5. South Carolina against the agency benchmark — re-run, and the two halves disagree

The benchmark (SC Medicaid agency, recorded in session 47 and **not committed to
any data file**): *~240 awards, ~$170M, about half of awards to hospitals, about
60% of dollars to hospitals.*

| | floor (session 47) | **typed now** | typed less Acadia | benchmark | ceiling (session 47) |
|---|---:|---:|---:|---:|---:|
| **% of awards** | 24.1% | **49.6%** | 49.1% | ~50% | 89.9% |
| **% of dollars** | 33.8% | **69.2%** | 65.9% | ~60% | 89.3% |

**The award-count half lands on the benchmark almost exactly** — 113 of 228
against ~50% — which session 47 could only bracket between 24.1% and 89.9%.

**The dollar half overshoots by about nine points and is reported overshooting.**
Three readings are available and **none is adopted**, because adopting one would
be adjusting a classification toward a figure: the benchmark may count only
*rural* hospitals, where this typing counts every hospital the state awarded;
it may exclude the two psychiatric hospitals ($2,045,000) and Acadia
($5,565,253), which together are 4.5 points; or it may treat Prisma Health's and
Self Regional's non-hospital sites separately, which no published source lets
this project do. **No row was typed to reach the benchmark and none was adjusted
away from it**, and a test fails if a later session quietly does.

Both figures still sit inside session 47's floor-to-ceiling range, which is what
says the extraction was sound all along.

---

## 6. What moved

| | before | after |
|---|---:|---:|
| `NAMED_HOSPITAL` | 865 rows / $706,793,190 / 19 states | **939 / $787,490,160 / 19** |
| `POOL_NAMED_HOSPITALS` | 1 row / $18,156,856 / 1 state | **2 / $68,156,856 / 2** |
| `POOL_UNNAMED_HOSPITALS` | 1 row / $50,008,264 | unchanged |

**+74 rows and +$80,696,969.67 into `NAMED_HOSPITAL`, and nothing out** — the
pass is one-directional by construction, because every open row was
`distributed_to_hospital = No`.

| state | rows | dollars |
|---|---:|---:|
| **SC** | 58 | $59,253,577.18 |
| **MS** | 16 | $21,443,392.49 |

By evidence class: **$71,354,639.67 on a federal record** (`ORG_WEBSITE`,
`MEDIUM`) and **$9,342,330.00 on general knowledge** (`LOW`) — the four rows in
§4.2.

**South Carolina becomes the largest named-hospital state in this repository**,
ahead of Arkansas: 55 rows / $56,587,138 → **113 / $115,840,715**. Mississippi
goes 68 / $47,454,812 → **84 / $68,898,205**, fifth.

**No state's published total moved.** Mississippi still sums to
$104,115,146.80 and South Carolina to $167,299,900.69. This pass re-**types**;
it re-prices nothing.

---

## 7. How it is written back, and what a later session must remember

**The typing is an OVERLAY, exactly as session 49's verification is**, and for
the same reason: every state extractor rebuilds its CSV from its archived source,
so a determination written straight onto the CSV is wiped by the next `--build`
and nothing says so.

```
Rscript R/03aq_unstated_form_typing.R --report     # what moves, BEFORE writing
Rscript R/03aq_unstated_form_typing.R --apply      # changes CSV + the two files
Rscript R/03aq_unstated_form_typing.R --benchmark  # the SC comparison
```

**AFTER ANY `--build` ON MISSISSIPPI OR SOUTH CAROLINA, RUN `--apply`** — or call
`uf_overlay(built, "<file>.csv")` inside whatever you are doing. Iowa needs
`R/03ap_verification_queue_2.R --apply` as before; its pool row is built by
`ia_award_rows()` and survives a rebuild on its own.

**`uf_read()` uses `na = character()` and `uf_apply()` writes `na = "NA"`,
because both files spell "empty" as the literal string `NA`.** A plain
read-then-write rewrites 167 and 228 rows in six columns this pass never planned
to touch — the churn sessions 23–25 kept catching in the diff. The committed
diff is now confined to the columns that actually changed.
