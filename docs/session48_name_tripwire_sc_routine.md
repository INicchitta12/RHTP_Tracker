# Session 48 — the tripwires learn to read names, and South Carolina gets its probe

**Date:** 2026-09-21. **Quota:** zero RCJ calls. **Network:** four fetches to
`scdhhs.gov` (the live South Carolina probe) and nothing else.

Three tasks, and the first is a repair to a defect session 46 found and
reported but did not fix.

---

## 1. The name-based tripwire

### 1.1 What went wrong, and why lengthening the list would not have fixed it

Session 46 recorded this and it is worth restating exactly, because the
correction turns on the precise shape of the failure:

> **NEW MEXICO: SIX REGIONAL HUBS ARE SELECTED AND NAMED, THREE OF THEM
> HOSPITALS — AND THE TRIPWIRE DID NOT FIRE.**

HCA's sentence is

> *"HCA has **selected six Regional Hub Organizations** to lead Healthy
> Horizons ... with more than $74 million in regional funding"*

and it names Cibola General Hospital, Gallup Community Health, the Regents of
the University of New Mexico, Eastern Plains Council of Governments, **Gila
Regional Medical Center** and **Nor-Lea Hospital District**.

`NM_AWARD_POSTED` held ten phrases. **Not one matches that sentence**, and
this session drives that as a test rather than repeating session 46's finding
on trust:

```
phrases <- c("has been awarded", "have been awarded", "awardees are",
             "selected for award", "notice of intent to award",
             "list of awardees", "award recipients", "funding recipients",
             "successful applicant", "selected organizations")
#  -> character(0)
```

*"selected organizations"* is not *"selected six Regional Hub Organizations"*.

**The defect is not that the list was too short.** A marker list is assembled
from the phrasings a state has **already** used, so it cannot contain the one
the state uses **next**. Adding *"selected six"* buys one more past tense and
leaves the future exactly as uncovered. Session 46's own fix — pinning the verb
with its object left open — helps and is the same kind of fix: still a guess
about wording.

### 1.2 The question that does not depend on wording

`rhtp_assert_no_new_organisations()` (`R/utils_config.R`) asks:

> **Does this page NAME an organisation the committed archive does not?**

A roster announced in any words at all adds names. That is the property being
exploited, and it is why the check is phrasing-independent.

**It is a SECOND SIGNAL. Every phrase list stays.** The phrase lists catch the
case a name diff cannot see: a state that announces awards while naming
**nobody** — South Dakota's two rounds (110 recipients, no roster) and South
Carolina's own MB# 26-026 (*"Applicants should check their email"*). Neither
adds a name, and both are award announcements.

### 1.3 Three properties that make it work, and one that makes it honest

**THE BASELINE IS THE COMMITTED ARCHIVE, NOT A CONSTANT.** Chrome, navigation,
staff lists, the agency's own name — all in both copies, so all cancel. That is
what lets the suffix list be broad. South Dakota's organisation-name tripwire
(session 13) counts names against a **threshold**, so every false positive
spends part of a fixed budget and the pattern had to be narrow. A diff has no
budget to spend: anything stably present costs nothing at all.

**IT INHERITS THE REDUCTION.** It runs on the same reduced text the content
digest is taken over, so the eleven rotating-token mechanisms this project has
measured — Complianz's randomly drawn URL, `antispambot()`'s re-rolled
entities, Wyoming's per-render honeypot label — are stripped before a name is
looked for. Handed raw HTML it would report script bodies as organisations,
which is why it takes TEXT and says so.

**RE-BASING IT IS A DELIBERATE ACT.** `--fetch --force`, after a human has read
what changed. The probe never writes (§2.2).

**AND IT REFUSES TO PASS ON AN EMPTY BASELINE.** If the archived copy yields no
organisation-shaped names, the extractor has failed, and a diff against nothing
either fires on everything or — when the live side is empty too — **passes
silently forever while wearing a green verdict**. That second case is precisely
the failure this function exists to end, and it would be a statement about our
reading reported as one about the state (§0.4).

### 1.4 What the guards caught, on the first run and in the tests

**MISSOURI'S HUB ANCHOR ROSTER IS A PDF.** Handed to `mo_html_text()` it
returns 450 characters of PDF header:

```
%PDF-1.6 %âãÏÓ 280 0 obj <> endobj 300 0 obj <>/Filter/FlateDecode/ID[...
```

The empty-baseline guard refused it. Pointed at Missouri's own reader
(`mo_content_digest(..., "pdf")`, which the probe's LIVE side was already
using) the roster yields **30 names** — Mosaic Medical Center, Heartland
Regional, Harrison County Community Hospital, Cameron Regional, Golden Valley
Memorial, Citizens Memorial — so a **twenty-eighth Hub Anchor** now fires.
Missouri is also the state where this matters most: `mo_assert_anchors_not_
awarded()` watches the roster's **money**, not its **membership**.

**TWO DEFECTS IN THE READER, BOTH FOUND BY ITS OWN TESTS, BOTH FALSE-POSITIVE
GENERATORS.**

*A trailing full stop.* The comparison normaliser kept one, to preserve
*"Inc."*. So a name ending a sentence carried a period its mid-sentence form
did not, and **the last organisation on a page read as new the moment the page
gained a sentence after it**. Stripped now; *"Inc."* and *"Inc"* collapsing to
one comparison key is the correct trade, and the **reported** string is
untouched.

*A zero-width character.* It is not in the name-token class, so the run
**breaks** there: `"Gila​Regional Medical Center"` comes out as
*"Regional Medical Center"* — a different string, which then reads as new.
Session 34 met the same character in HCAI's WDRR heading, where it broke an
assertion with nothing to point at. **Normalising afterwards cannot repair
it**, because by then the first word is gone, so zero-width characters are
stripped **before extraction**.

**A DATE IS NOT A NAME, AND LOUISIANA IS THE MEASUREMENT.** LDH's programme
page prints an announcement window in the cell beside each programme's name,
and the reduction flattens that cell boundary to a space. LDH re-dated all
seven windows between 2026-09-02 and 2026-09-21 **without naming anybody**, and
the first version of this check reported three new organisations:

```
"End of September Rural Medicaid Alternative Payment Model Program ..."
"End of September Regional Care Conveners and Navigation Networks ..."
"End of September Rural Health Transformation Program"
```

whose only new words are the month. Breaking a run on a calendar token drops
all three. **Both archived snapshots are committed, so this is a measurement**,
and the pair is now a test: the content digest **MOVED** and the name tripwire
is **silent in both directions**. That is the discrimination the whole thing is
for.

### 1.5 The counterfactual, on real committed bytes

Session 35 archived HCA's page; session 46 fetched it again and the hubs were
on it. Both are in git. Run against each other:

```
=== WHAT THE NAME TRIPWIRE WOULD HAVE SAID ON 2026-09-21 ===
[1] "Cibola General Hospital"
[2] "Gallup Community Health Region"
[3] "The Regents of the University of New Mexico Region"
[4] "Eastern Plains Council of Governments Region"
[5] "Gila Regional Medical Center Region"
[6] "Nor-Lea Hospital District The Regional Hubs"
[7] "Project ECHO"
[8] "Rural Health Data Hub Administrator"

=== what the phrase list DID say ===
character(0)
```

The trailing *"Region"* on four of them is the run swallowing the next list
item's label, and it is the **safe** direction: an over-joined string is not in
the archive either, so it fires, and the name stays legible to the human
reading the message. `NM_KNOWN_ORGANISATIONS` now records all eight with the
sentence that justifies them, and today's probe is silent again.

### 1.6 Where it is wired, and where it deliberately is not

**EIGHTEEN probes, SUBJECT PAGES ONLY** — the pages where a roster would
appear. Controls and press indexes are excluded: they move for reasons that are
not the state awarding, and a tripwire that halts on those is session 46's
stale dated anchor in a new costume.

**Two recorded exemptions.** Alaska's rolling xlsx roster is diffed by the
extraction itself, award by award. South Dakota's portal already carries its
own organisation-name tripwire (session 13). Both are named in the test that
enforces the rule.

**All 39 wired pages are silent against today's archives**, with baselines from
7 names (CT documents) to 257 (NM news).

`test_utils_name_tripwire.R` — 93 assertions. The ones carrying the weight are
the two real-archive tests (Louisiana silent, New Mexico firing on all six) and
the one that reads the source of every file in `R/` and requires any file
offering `--probe` to run the name tripwire, so a twenty-first state file
cannot quietly ship with only a phrase list.

---

## 2. South Carolina is on a Routine

It was the only EXTRACTED state with a working `--probe` and no schedule.

**`trig_01UdVg36W1aWGTDKs3jfHtfV`, THURSDAYS 08:30 UTC**, first firing
2026-09-24.

**Weekly, and the reason is the project's own rule.** Twice-weekly is earned by
a state that has published an award date — Wisconsin's *"Award announcements:
September"*, Connecticut's 2026-08-17, Mississippi's 30-to-45 days. South
Carolina publishes none: SCDHHS says only that the Tech Catalyst Fund's
opportunities *"will be announced through a future stage of SCDHHS' RHTP
implementation."* That is North Carolina's footing (session 38) and New
Mexico's (session 36).

**08:30 UTC because the fifteen Routines already running occupy a continuous
band from 09:40 to 21:10.**

**What it watches:** the fifth of five initiatives, the **Tech Catalyst Fund**,
**$32,730,351**, administered through the **South Carolina Research Authority**
— §7's designated pass-through route, Illinois/ICAHN's precedent — which has
named nobody. Plus a corrected award list (South Carolina prints one row number
as `I2` and spells Prisma Health three ways, and `sc_assert_row_numbering()`
and `sc_assert_two_spellings()` pin both on purpose, so a tidy-up fails the
build), and both §0.1 negative controls, which live on the RHTP page itself.

**It ran live first**, with the new name tripwire inside it, and reports
UNCHANGED on all four pages — which is the wiring validated end to end against
a live host rather than against a fixture.

> The Routine stores **no MCP connectors**. That is correct here — it runs
> `Rscript` against the checkout and needs none — and it matches the fifteen
> Routines already running.

---

## 3. The totals, re-derived

Computed from the **28 committed reference files** that `test_state_union.R`
combines, through `rhtp_hospital_dollar_partition()`. Nothing was re-coded and
no figure moved; this reproduces sessions 46 and 47 from the files rather than
carrying the numbers forward.

```
                 bucket rows        dollars states
         NAMED_HOSPITAL  747 599,533,408.65     18
   POOL_NAMED_HOSPITALS    1  18,156,856.12      1   NE -- Nebraska High Value Network
 POOL_UNNAMED_HOSPITALS    1  50,008,264.00      1   IL -- ICAHN
```

**The three buckets must never be added** (§8). `rhtp_hospital_total()` still
refuses.

`NAMED_HOSPITAL`, by state:

```
 GA 125 rows  90,277,580.00      NE  41 rows   6,990,996.01
 WY  31       72,661,323.90      OK  20        1,079,506.22
 AL  60       66,133,019.00      MI   1           76,924.00
 AK  43       62,396,425.47      DE   4                0.00
 SC  55       56,587,137.77      IA 152                0.00
 OR  49       50,188,530.68      NV  20                0.00
 FL  15       49,345,213.46
 MS  68       47,454,812.18
 KS  21       35,721,277.00
 PA  27       24,149,111.00
 AR   9       21,792,687.96
 MD   6       14,678,864.00
```

**ALASKA, after the 244-action refresh: 43 named-hospital rows,
$62,396,425.47**, across **16 distinct awardee strings**. Fourth largest
single-state contribution, behind Georgia, Wyoming and Alabama. Its file’s `sum(amount)` is $239,186,194.73 over 244 award actions.

**READ THE ROW COUNT, NOT ONLY THE DOLLARS.** Three states contribute rows and
no dollars — **Iowa 152, Nevada 20, Delaware 4** — because their publishers
name recipients and price none of them. Read down the dollar column alone and
the largest single block of named hospitals in this repository is invisible.

**A row is an AWARD ACTION, not an organisation.** Georgia's 125 rows are 105
distinct awardee strings; Alaska's 43 are 16. The deliverable table's "108
named hospitals" for Georgia is a third quantity again. None of the three is
wrong and no two are the same claim (§8).

Every Alaska row remains `amount_confirmed = No` — they are notices of
**intent** to award, and the file is stale by construction: DOH overwrites one
url weekly.
