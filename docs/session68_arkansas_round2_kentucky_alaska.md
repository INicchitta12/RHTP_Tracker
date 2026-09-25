# Session 68: Arkansas round 2 read, Kentucky's CHANGED pages, Alaska's runner

Date 2026-09-25. Zero RCJ quota. Nothing extracted, re-coded or re-based.

## 1. Arkansas: the tripwire was real

The AR Routine's 2026-09-24 20:22Z TRIPWIRE ("RISE AR and HEART Project Impact")
marks DF&A publishing its **second Year 1 round**. The home page now carries a
second "Download the List of Organization and Award amounts" link, a RISE/HEART
county map, and a link to the Governor's 2026-09-24 release.

**The list** (`ada_Year-1-Award-totals.pdf`, Last-Modified 2026-09-24 17:58Z),
with columns Organization | RISE AR | HEART | Totals:

| | |
|---|---:|
| Organisations | 38 |
| Organisation x initiative actions | 43 |
| RISE AR | $27,213,468.74 |
| HEART | $27,471,600.10 |
| Total (its own `Total:` row) | **$54,685,068.84** |

Every row closes (RISE + HEART = Total) and the rows sum to the Total row to the
cent. It is round 1's producer: the three amount columns weld under
`rhtp_pdf_lines()`, so the run model is required. Round 1 already asserts this.

**The Governor's release** says "$54.6 million", "$27.4 million ... 30 projects
through ... HEART" and "$27.2 million for 24 projects through ... RISE AR", and
that the round "**completes the distribution of the $208 million awarded to
Arkansas this year**".
- HEART: 30 priced projects, sum $27,471,600.10, which **equals the list to the cent**.
- RISE AR: the prose prices only **23** amounts, sum $27,009,948.74, which is
  **$203,520.00 short** of the list's RISE column against its own "24 projects".
  **UNRESOLVED.** Either one project is described without its figure, or a
  figure is missing. Read the release before extracting, and do not close the
  gap by arithmetic.

**Both rounds together**: $149,177,618.45 + $54,685,068.84 = **$203,862,687.29,
97.6%** of the $208,779,396 allotment. The remaining $4,916,708.71 is
consistent with administration, but no source here says so.

**Hospital sizing is a preliminary reading. Nothing was coded.** Nine
organisations read as hospitals by name or by session 49's verification, with
roughly 12 actions and **$18,870,981.65** between them: Arkansas Surgical
Hospital $473,000; Baptist Health $418,883; Conway Regional Health System
$761,440; Jefferson Hospital Association $1,030,000; Mississippi County Hospital
System $4,402,000; North Arkansas Regional Medical Center $1,629,128; St. Bernards
Development Foundation $4,799,074 (§10.2 foundation row); White County Medical
Center $300,926.15; White River Health System $5,056,530.50.

Still open:
- Arkansas Rural Health Partnership, $2,048,665. This is `AR_ARHP_CONSORTIUM_FLOW` again.
- North Arkansas Rural Health Consortium, $1,000,000.
- CARTI, $1,000,000.
- UAMS, $5,068,862. On the OHSU/UNC precedent this is `UNIVERSITY_OR_AHC`.

The list names none of these as a hospital. Every form above is this session's
reading, and the extraction must type from sources (§0.4).

Archived at `data/evidence/recheck/2026-09-25/AR/` with SHA-256 manifest.
The credential guard found nothing.

## 2. Kentucky: routine edits, no roster

- `funding`: the only difference is **one zero-width space** in the heading.
- `rch`: FHKY changes from "primary partner" to "**convening partner**". Three
  staff rows become "<ADD> FHKY Liaison". A news item links FHKY's 2026-09-08
  release, which describes Hub Lead Organizations for Big Sandy, Lake Cumberland
  and Purchase **and names none**. The Governor link is the 2025-12-29 allotment
  release (Tier 1).
- Both award-notification dates (2026-07-10, 2026-08-26) have still passed with
  no roster. "Convening partner" is Missouri's Hub Anchor vocabulary, so when
  Hub Leads are named, check whether FHKY is a fiscal agent at all.

## 3. PR #70

`claude/awesome-heisenberg-prcy1y` was already merged to `main` as `2ad0fc3`
(PR #70). The branch has no unmerged commits, so there was nothing to open.

## 4. Alaska

`trig_015xk6QMPZNSY7GhC6muGdpN` has **not fired yet**. It is enabled, and its
first run is **2026-09-28 14:07Z**. Today is Friday 2026-09-25. The old
`trig_018fYZk2Dd9sui3WqmDMefwS` is disabled and kept. Its prompt carries the
exactly-one-enabled check, which the new runner will pass.
