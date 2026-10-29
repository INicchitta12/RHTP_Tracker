# Session 111c (2026-10-29): California, our calls against CHA's

**Bottom line.** CHA's informal coding of HCAI's BP1 roster and ours disagree
on **three rows and nothing else**. The hospital gap ($1,156,348.24) is
Providence Medical Foundation and Community Health Partners. The CAH gap
($620,000) is Banner Health Foundation. Every other line matches on recipient,
amount, hospital call and CAH flag. CHA's "Rural Hospital" figure uses a
different definition and is not compared. No award row, summary call or
figure moved.

## What was done

- `RHTP awards_10.23.26_.xlsx` (repo root, uploaded in `b8da792`) moved to
  `data/evidence/CA/validation/RHTP_awards_10.23.26_.xlsx`. The space was
  dropped from the name and the bytes are unchanged (SHA-256 `1024e009…24cbd`).
  `PROVENANCE.txt` sits beside it: *"CHA informal analysis of HCAI's
  recommended-funding list (10-23); owner-supplied 10-29; not an official
  accounting; internal use only."*
- `R/03cm_ca_cha_reconciliation.R` (new; `--build`, `--report`) writes
  `data/reference/ca_cha_reconciliation.csv`.
- `tests/testthat/test_03cm_ca_cha_reconciliation.R` pins both
  reconciliations to their rows.

## Matching

All 108 CHA lines match our 108 `ca_year1_awardees.csv` rows one to one, on
programme plus amount to the cent. In 23 lines, programme and amount are shared
with other lines (Transformative Payments at $3,863,636 and $2,563,636, WDRR at
$1,000,000, EHR at $2,000,000). Inside those ties the exact normalised name
decides. One pair is matched by elimination: Oak Valley District Hospital
(CHA) and Oak Valley Hospital District (ours), EHR, $2,000,000. The script stops
on any match that is not 1:1.

Eight lines carry a different name string for the same recipient. None changes
a call:

| Row | CHA | Ours |
|---:|---|---|
| 9, 69 | Northern Inyo Hospital | Northern Inyo Healthcare District |
| 15 | Sierra Nevada Memorial Hospital | Sierra Nevada Memorial Hospital Foundation |
| 21 | Arrowhead Regional Medical Center | San Bernardino County, Arrowhead Regional Medical Center |
| 66 | Trinity Hospital | Mountain Communities Healthcare District (CAH 051315) |
| 70, 104 | Oak Valley District Hospital | Oak Valley Hospital District |
| 83 | Hazel Hawkins Memorial Hospital | San Benito Hospital District |

Our strings are HCAI's. CHA appears to have renamed some recipients to their
facility. CHA's notes on rows 9, 66 and 83 say the award "was to the District,
not just the hospital". We already code those rows as hospitals on the
district's CAH enrolment.

## Reconciliation

| Measure | Ours | CHA | Gap | Made by |
|---|---:|---:|---:|---|
| All lines | $138,464,043.97 | $138,464,043.97 | $0 | — |
| Hospital | $82,852,823.14 | $84,009,171.38 | $1,156,348.24 | Community Health Partners $706,348.24; Providence Medical Foundation $450,000 |
| CAH | $46,065,499.94 | $46,685,499.94 | $620,000 | Banner Health Foundation $620,000 |
| Rural Hospital | — | $63,879,556.38 | not comparable | — |

Both gaps reconcile exactly. No offsetting differences sit underneath them: the
row lists contain only those three rows.

### The three rows, and why ours stand

- **Providence Medical Foundation ($450,000, WDRR).** CHA: *"the medical group
  affiliated with Providence Hospitals."* That describes a physician group. Our
  `PHYSICIAN_PRACTICE` / `NON_HOSPITAL` call rests on owner ruling (b) from
  session 110. A California medical foundation (H&SC §1206(l)) operates clinics;
  it is not a hospital's fundraising arm (CLAUDE.md §7). CHA's own note
  supports our call, not theirs.
- **Community Health Partners ($706,348.24, Accelerator).** CHA: *"the
  physician group affiliated with Community Health Systems."* That is the same
  shape: a physician group, not an enrolled hospital. CHA counts it because the
  group's affiliated hospitals are rural. That is a parent-system argument
  applied to a physician group. Our rule promotes a system parent or a
  hospital's own fundraising foundation, never a physician group (§7, §0.3a:
  the recipient decides). Ours stays NOT_HOSPITAL. This is the more arguable of
  the two calls: if an opposing reader treats physician-group affiliates as
  hospital-system money, both rows move together (+$1,156,348.24).
- **Banner Health Foundation ($620,000, WDRR).** Both readers call it a
  hospital. Only the CAH flag differs. CHA marks it CAH *"because Banner Lassen
  is rural."* Ours types the row on general knowledge as a hospital system's
  foundation serving Lassen County (Banner Lassen Medical Center, CAH 051320),
  with **no CCN on the row**. R/08's CAH figure counts only rows that carry a
  13xx CCN. The row's dollars go to the Banner foundation, not to the CAH's
  enrolled entity, so attributing them to the CAH would be an inference. The
  project's CAH figure is a floor by design (R/08 says so).

### Rural Hospital is a different measure

CHA's $63,879,556.38 reproduces to the cent as the sum of its hospital lines
(`Non-hospital = 0`) flagged `State Rural = Yes`. That is California's **state**
rural designation. It includes non-CAH hospitals such as Adventist Health
Sonora, Sutter Coast and Lompoc Valley ($17.1M of our hospital rows are
state-rural but not CAH). It also includes Community Health Partners.

This project holds no California state rural designation (`rural_designation`
is empty on all 108 rows). Its rural measures are the CMS CAH cut (R/08) and
R/03ar's source-backed rural cut. Comparing $63.9M with either would compare
two definitions, not two codings, so the CSV records it with
`comparable = NO` and no figure of ours.

## Other differences found

None beyond the three rows. Notes worth keeping, none of which changes a call:

- CHA flags uncertainty on rows where we agree with its call: Mercy Medical
  Center – Northern California Maternity Collaborative ("a little uncertain"),
  Arrowhead ("not sure if this one is just for the hospital"), San Benito
  district, and the Southern California Rural Health Collaborative – UCSD ("not
  sure … but think no"). On that last row we also code non-hospital (session
  110 ruling a).
- CHA's sheet gives no per-line source, and its "ID" column is not a CCN. It is
  a second reader's coding and is never evidence for a row (§0.1, §0.4).

## For use

The CA hospital figure is $82,852,823.14 (59 rows, intents). It survives an
independent line-by-line check by the state hospital association. The whole
disagreement is $1.16M (1.4% of CHA's figure) on two physician-group rows,
where CHA's own notes describe the recipients as medical groups. If a reader
prefers CHA's treatment, the upper reading is $84,009,171.38. Both figures
remain HCAI's "tentative" list. They are intents, and the $28,255,956.03 gap
against HCAI's "$166.72 million" is still unreconciled.

Suite: `Rscript tests/run_tests.R` passes with 0 failures. Its two warnings are the existing `cms_enrolment_match` column warnings in `test_03bj` and are unrelated to this session.
