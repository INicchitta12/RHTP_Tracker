# Session 123 (2026-11-24): RHTP use-of-funds categories on every Year 1 award

Owner direction (11-24): classify every Year 1 award, hospital and non-hospital, by the RHTP activity it
funds, using CMS's own use-of-funds categories, wherever the evidence allows. "Not stated" is acceptable;
a guess is not.

## Results

**No total moved.** `year1_summary_2026-11-24.csv` and `year1_vendor_summary_2026-11-24.csv` are
byte-identical to the 11-23 files: awards $6,529,984,965.77; hospital best estimate $2,604,985,516.91;
strict NAMED_HOSPITAL $2,292,358,452.90. The completed-states table is unchanged apart from its date.
After R/09b, R/07 and R/11 were re-applied, every award file is byte-identical to its committed state.
`test_11` pins all of this.

### Coverage: award dollars (pool-level money included) and award rows classified, by basis

| Basis | Confidence | Rows | Row share | Award $ | $ share | of which hospital $ |
|---|---|---:|---:|---:|---:|---:|
| AWARD_SOURCE | HIGH | 70 | 1.2% | $80,804,742 | 1.2% | $19,817,749 |
| INITIATIVE_CROSSWALK | MEDIUM | 4,546 | 77.4% | $4,964,745,255 | 76.0% | $2,040,951,350 |
| PURPOSE_TEXT | LOW | 356 | 6.1% | $299,463,786 | 4.6% | $135,333,224 |
| NOT_STATED | — | 904 | 15.4% | $1,184,971,182 | 18.1% | $408,883,195 |
| **Classified** | | **4,972** | **84.6%** | **$5,345,013,783** | **81.9%** | |

Almost everything that is classified rests on the state's own plan (MEDIUM). No state award document
prints a CMS letter. The 70 AWARD_SOURCE rows are RI's and NE's CMS obligation-report lines (the owner
admitted them as award rows in session 98), where CMS prints a category heading over each line.

### Hospital and non-hospital dollars by use group

Hospital and non-hospital follow the R/07 summary call. "Share" means the share of CLASSIFIED dollars,
with NOT_STATED left out and MULTIPLE counted as classified.

| Use group | Rows | Award $ | Share | Hospital $ | Hosp share | Non-hospital $ | Non-hosp share |
|---|---:|---:|---:|---:|---:|---:|---:|
| Prevention and chronic disease (A) | 281 | $201,248,669 | 3.8% | $142,392,932 | 6.5% | $58,855,736 | 1.9% |
| Direct provider payments (B) | 9 | $20,421,806 | 0.4% | $0 | 0.0% | $20,421,806 | 0.6% |
| Health IT and technology (C, D, F) | 292 | $507,189,466 | 9.5% | $160,799,091 | 7.3% | $346,390,374 | 11.0% |
| Workforce (E) | 703 | $712,249,572 | 13.3% | $158,456,480 | 7.2% | $553,793,092 | 17.6% |
| Service lines and care availability (G) | 41 | $47,581,366 | 0.9% | $25,495,653 | 1.2% | $22,085,713 | 0.7% |
| Behavioral health (H) | 191 | $108,475,278 | 2.0% | $26,087,746 | 1.2% | $82,387,532 | 2.6% |
| Care delivery and payment transformation (I) | 152 | $137,872,959 | 2.6% | $99,291,448 | 4.5% | $38,581,511 | 1.2% |
| Capital and infrastructure (J) | 382 | $377,317,611 | 7.1% | $304,331,421 | 13.9% | $72,986,190 | 2.3% |
| Partnerships and regional networks (K) | 38 | $6,864,598 | 0.1% | $941,713 | 0.0% | $5,922,885 | 0.2% |
| Multiple | 2,883 | $3,225,792,459 | 60.4% | $1,278,305,838 | 58.2% | $1,947,486,621 | 61.8% |
| Not stated | 904 | $1,184,971,182 | — | $408,883,195 | — | $776,087,987 | — |
| **Total (awards published)** | **5,876** | **$6,529,984,966** | | **$2,604,985,517** | | **$3,924,999,449** | |

**MULTIPLE is the largest single answer, at 60% of classified dollars, and that reflects the source.**
State plans tie each initiative to three to eight CMS letters across groups ("Use of Funds B, C, D, F, G,
H"). Award documents rarely point to one. Splitting an award's dollars across its letters would invent a
split no state published, which the rule forbids.

**What the single-group figures support:** capital (J) is a much larger share of hospital money (13.9%)
than of non-hospital money (2.3%). Workforce (E) and health IT run the other way. Read these as shares of
the ~40% of dollars that resolve to a single group, not of all money.

### States with the most NOT_STATED dollars, and why

| State | NOT_STATED $ | Classified | Why |
|---|---:|---:|---|
| FL | $168,877,241 | 10.3% | The 111-page application is image-only. OCR shows its "Use of Funds" sections are prose with no letters, and the award list carries no initiative per row. 25 rows were coded from award-list purpose text. AHCA's annual report to CMS has a "Use of Funds Category" column, but only admin lines are filled so far; re-check later editions. |
| CO | $163,954,733 | 0.0% | Every hcpf.colorado.gov path returns 403 (CloudFront), including the project narrative. UNREADABLE, not "no categories". The round spans ten initiatives, so a readable plan would still give MULTIPLE for the round. |
| MN | $145,292,386 | 7.7% | All 141 FFATA descriptions in MN_FSRS are the 93.798 programme boilerplate. |
| KS | $102,838,271 | 45.2% | kdhe.ks.gov is 403 for the application, narratives and RFAs, so KS is purpose text only. The FSRS rows cite KDHE programme numbers (4.1, 5.2, …) and would crosswalk once the narrative is readable. |
| OH | $93,000,000 | 11.4% | ODH returned 404 on every path, home page included (our access, not the state). ODH's $30.3M direct payments to 22 hospitals state no activity, and the two R/07 pools ($61.7M) inherit NOT_STATED. |
| KY | $87,530,516 | 13.6% | All 41 FFATA descriptions read "KENTUCKY RURAL HEALTH TRANSFORMATION PLAN". 15 rows link through the state's Executed Contract Tracker. The Foundation for a Healthy Kentucky row ($50.49M) linked only by arithmetic and was dropped (below). |
| NH | $66,547,394 | 0.0% | **Not researched.** The NH file carries no activity field, so it produced no brief. Every nh.gov host is 403 in any case (§13). |
| GA | $54,640,747 | 72.3% | Georgia initiative residuals and Phase 1 pool money with no initiative label. |
| OR | $49,898,000 | 70.2% | The Transformation Fund ($35.0M to hospitals, $9.9M to RHCs) is "system stability" funding tied to no plan initiative. |
| RI | $39,624,596 | 66.0% | RI_FSRS boilerplate ($37.7M) and programme-administration lines (no CMS letter). |

ND ($17.1M, boilerplate FFATA), MT_FSRS ($22.1M, description "RHGT"), TX_FSRS ($20.3M, "RTS INITIATIVES"),
NM's Accenture ASO ($129.0M) and the DE fiscal-oversight lines are also NOT_STATED. Programme
administration is not a CMS use of funds. Accenture is already held out of every figure.

### Independent check (Task 5)

A separate agent that had not seen the coding re-derived 40 rows from archives alone. The sample was 10
AWARD_SOURCE, 15 INITIATIVE_CROSSWALK and 15 PURPOSE_TEXT rows, 18 of them hospital rows.

| Basis | n | Same group | Same letters | Same basis |
|---|---:|---:|---:|---:|
| AWARD_SOURCE | 10 | 10 | 10 | 10 |
| INITIATIVE_CROSSWALK | 15 | 14 | 12 | 14 |
| PURPOSE_TEXT | 15 | 13 | 9 | 13 |
| **All** | **40** | **37 (92.5%)** | **31 (77.5%)** | **37** |

The 18 hospital rows agreed 18 of 18 at group level. Resolutions are in
`config/use_category_independent_check.csv`:
- **Fixed: NJ-C34**, A;H → A. Serious mental illness is the population served; the activity is
  metabolic-disease prevention.
- **Kept: WI row 5** (E). The award is project 1 of Initiative 1, and the project's own name, "Rural
  Workforce Grants", points to E.
- **Kept: KS row 34** (MULTIPLE). The description names CCBHC/MAT (H) and workforce expansion (E), and no
  text makes either dominant.
- **Kept: MS BRIDGE letter** (J for printed G). This follows the name rule below; the group is the same.
- Six other rows agree on the group and differ on letters. For example, the checker reached IA row 1 by
  the RFP crosswalk where we used purpose text, and MN's ECHO award is the union of two initiatives in
  ours and one in theirs.

The checker also noted that CMS's obligation report puts single categories on three crosswalked
programmes: WA TRC = I, OK LifeCare = I, MS Care Gap Closure = J. We did not use the report for states
whose award rows come from their own sources. This is recorded as a possible upgrade if the owner wants
the CMS report treated as award-level evidence for every state.

## Calls I made under the standing rules (noted, not held)

1. **AWARD_SOURCE is the award document, not the solicitation.** A round's own NOFO/RFA that prints
   letters counts as plan evidence (INITIATIVE_CROSSWALK, MEDIUM), not HIGH.
2. **RI and NE CMS obligation-report rows are AWARD_SOURCE.** Their award rows ARE the CMS report lines
   (owner ruling, session 98), and the report prints a category heading over each line. Two headings do
   not match their own line text (RIHCA "workforce development" under I; RIDE career-tech under G).
   They are recorded as printed.
3. **The printed category NAME governs a mismatched letter.** MS's BRIDGE table prints
   "G. Capital Expenditures and Infrastructure", so it is recorded as J (MS-X01, MS-X04). TX prints
   "B. Workforce" for Initiatives 1 and 4, so it is recorded as E. OK Initiative 5 (workforce) prints
   "F, G, K" with no E, and that is recorded as printed, since there is no mismatch there.
4. **KY-X17 dropped.** The Foundation for a Healthy Kentucky ($50.49M) was linked to Rural Community Hubs
   only because its amount equals its RCH contracts less one $405,000 line. Arithmetic is not evidence of
   an activity.
5. **OCR and transcription are admitted, and flagged.** MS (Use of Funds tables are images), MI (an
   image-only narrative), KY (an unreadable text layer) and HI (Appendix A, transcribed cell by cell
   beside the page renders) rest on machine- or hand-read text. Each has a `PROVENANCE`/MANIFEST note, and
   the quotes were checked against page images. If OCR is not acceptable, these fall to NOT_STATED: MS
   $136.7M, MI ~$153M, HI ~$184M and KY's 15 rows.
6. **Within one group with no pointer, `use_category_primary` is the first letter in NOFO order.** Only the
   group is reported anywhere. UT LIFT 5.1 is an example: the evidence supports the group, and C is just
   the first letter.
7. **`row` locators.** Where the activity is printed only in the award document (FL's award list, WI's
   implementation partners, KY's contract tracker, SD, WV), the rule keys on `row_no|awardee`. The
   awardee there is only a locator; the quote is the source's activity text. `test_11` excludes these
   rules from the recipient-scramble test by name.
8. **Workforce descriptions are coded E** even where no source states the NOFO's 5-year service
   commitment (DE, NC, WV, MD, NJ).

## Weak points and likely challenges

- **MEDIUM is plan-level.** A crosswalk says the state PLANNED this initiative to use these letters, not
  that this award was spent on them. `test_11` and the sheet keep the three evidence classes separable.
- **The cap table invites misreading.** IA's published J awards are 58% of its allotment (the Best and
  Brightest Equipment NOIA, $121.8M with FSRS pricing), NV's are 32% (Flex Fund J) and TX's 24%
  (Initiative 6). The table is labelled "published awards only, not the state's budget" and must never be
  read as a state over the 20% cap: caps apply to the budget-period award, published awards can cover
  more than one period, and an award with J among other letters is not all capital. Before any external
  use, IA's figure needs reading against its budget narrative.
- **NC SUPTR FSRS filing** describes "ONE-TIME MHBG FUNDING" (Mental Health Block Grant wording) on a
  93.798 subaward. It is a §6.2 provenance lead, not resolved here.
- **Quote checking.** Quotes are machine-verified (`rhtp_use_quote_found()`). Table cells joined by " | "
  must each be found within 3,000 characters of the longest one. Tags are stripped only from HTML: in
  PDF text a stray "<28 days" … ">9%" swallowed pages (NY, PA, WV), which the agents found.

## What was built

- `data/reference/rhtp_use_categories.csv`: the NOFO's letters A–K, quoted from the archived NOFO
  (`data/evidence/cms/nofo/`, SHA-256), with groups and caps (B 15%, J 20%, F EMR replacement 5%).
  `vocabularies.csv` gains four columns' codes.
- `R/utils_use_category.R` (`rhtp_use_category()`, the one writer) and `R/11_use_categories.R`
  (`--apply` LAST, `--validate`, `--report`). Rules: `config/initiative_use_crosswalk.csv` (461) and
  `config/use_category_cases.csv` (249).
- Plan archives: `data/evidence/use_categories/<ST>/` (47 state folders; CO holds only an empty manifest, nothing readable; GA cites pages archived elsewhere), with MANIFEST.txt and text
  companions. Per-state research notes: `docs/session123_use_category_notes/`.
- R/08: a "By use category" sheet (national, coverage by basis, coverage by state, by state, and B/J
  against the caps), a Definitions section, 11 hospital-by-group columns on Detail, and
  `year1_use_categories_<date>.csv`. R/09c: a "Use group (primary)" column on the verified list and the
  pass-through tab.
- `tests/testthat/test_11_use_categories.R`; `test_08` re-pinned to 11-24 (seven sheets).

## Next

- KS, CO and OH plan documents once their hosts serve this environment (403/404 today). KS's FSRS rows
  already carry programme numbers.
- NH: build a brief from FHC's GO-NORTH page if the owner wants it tried. nh.gov stays 403.
- NJ's application (404 today; no Wayback). The owner may hold a copy.
- Owner question: should CMS's obligation-report category headings be used as AWARD_SOURCE for states
  whose award rows come from their own sources (WA TRC, OK LifeCare, MS Care Gap Closure)?
