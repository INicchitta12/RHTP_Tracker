# Session 116e: the verified consultant / intermediary / out-of-state vendor list

**Date:** 2026-11-10. **Branch:** `claude/tender-johnson-mwx1u5`, cut from `main` at `090b9a8`.
**Scope:** a read-only layer for AHA colleagues. **No award row, summary call, bucket or hospital figure moved**
(the partition stays pinned in `test_09_vendor_flags.R`). Internal only.

## Deliverable

- **Workbook:** `output/verified_vendor_list_2026-11-10.xlsx`. Tabs: Verified list, Pass-through to providers, By firm, Unnamed contractor money, Planned (not awarded), Dropped, Method.
- **Code:** `R/09c_verified_vendor_list.R` (`--build`, `--live`, `--xlsx`, `--report`).
- **Hand inputs:**
  - `config/verified_vendor_cases.csv`: 56 cases written up.
  - `config/verified_vendor_hand_drops.csv`: 70 drops made by hand.
  - `config/verified_vendor_independent_check{,_r2}.csv`: the two independent rounds.
- **Outputs:** `data/reference/verified_vendor_{list,pass_through,dropped,unnamed_lines,planned}.csv` and `verified_vendor_live_check_2026-11-10.csv`.
- **New archives:** `data/evidence/vendor_verified/2026-11-10/`. MS DFA's BDO notice of intent (no amount), and the NM and DE location documents for V9 (`MANIFEST_v9.txt`).

## Owner rulings applied (second pass, same session)

1. **Idaho: the RHTP tie is the publication.**
   - DHW's "Funding Opportunities for Rural Health Transformation" page lists the awardee sheet under "Closed and awarded funding opportunities". The page is archived at `data/evidence/ID/2026-10-26_id_rhtp_funding_opportunities.html`, with its SHA-256 in `MANIFEST.txt`, and links `docid=37915`.
   - That page is the V2 basis. R/09c checks that the page names Rural Health Transformation, that it links the sheet, and its hash.
   - The five contractor cases return: PCG, BDO, Guidehouse, Deloitte and 22nd Century.
   - PCG is INTERMEDIARY only.
   - Co Magine Health ($1,998,975.94) stays dropped. Round 1 failed it on V4 ("Idaho Diabetes Prevention and Management" is a solicitation name). No ruling answered that, and a DROP in either round removes a case.
2. **INTERMEDIARY split by where the money goes, read from the quote.**
   - The three types are PASS_THROUGH_TO_PROVIDERS, ADMINISTERS_ONLY and NON_PROVIDER_RECIPIENTS.
   - These cases move to the new "Pass-through to providers" tab:
     - every PASS_THROUGH_TO_PROVIDERS case;
     - every case the tracker already counts as hospital money, meaning a strict bucket or a HOSPITAL summary call on the same recipient and amount, or a HOSPITAL summary-call component. Examples are NHVN, UHA's $9.89M, and VHHA Foundation's RPM and GME.
   - Round 2 re-typed two cases from PASS_THROUGH_TO_PROVIDERS to ADMINISTERS_ONLY, because neither quote says money is paid on: VHHA Foundation Food is Medicine ($2,472,888) and the Nebraska Health Care Foundation ALF grant programme ($2,000,919.44). Both stay on the main list.
3. **V9 locations.**
   - **Thomas Jefferson University ($1,599,955) is dropped.** The Governor's 2026-06-02 release says Delaware will "establish a regional campus of Sidney Kimmel Medical College". Jefferson's own page puts the first two years "at the University of Delaware's Main Campus in Newark, DE".
   - **Guidehouse NM keeps both categories.** HCA's CRHSI Q&A (answer 101) says "HCA does not require the CRHSI Contractor to maintain a New Mexico-based office, locate a minimum percentage of FTEs in New Mexico, or provide routine on-site presence", and no source places the center in New Mexico.

## Result

- **Main list: 39 cases.** Award $219,275,291 (25 cases); contract maximum $25,965,898 (6); intent $48,233,748 (7); obligation $2,205,500 (1).
- **Pass-through to providers: 13 cases.** Award $109,700,301 (7); intent $61,337,524 (6).
- **Drops recorded: 175.** 70 by hand, 4 by the independent check, and 101 by the machine sweep of the session-116b flags.

Main list by category (types never added):

| Category | award | intent | contract maximum | obligation |
|---|---:|---:|---:|---:|
| CONSULTANT | $33,668,808 (7) | $1,668,126 (1) | $25,965,898 (6) | $2,205,500 (1) |
| INTERMEDIARY: ADMINISTERS_ONLY | $96,036,376 (8) | $42,618,260 (4) | n/a | n/a |
| INTERMEDIARY: NON_PROVIDER_RECIPIENTS | $85,191,126 (7) | n/a | n/a | n/a |
| OUT_OF_STATE_VENDOR | $24,479,755 (4) | $3,947,362 (2) | n/a | n/a |

Guidehouse NM ($20.1M) is both CONSULTANT and OUT_OF_STATE_VENDOR, so the rows overlap and are never summed.

### Top cases on the main list, in plain language

1. **Wyoming Innovation Partnership, WY, $35.4M + $3.2M intent (administers).** "master fiscal agent ... to administer statewide individual and institutional workforce/nursing grants".
2. **NC ROOTS Hub Leads, NC, award (administer).** Trillium $28.5M and Vaya $14.25M (both PUBLIC), plus Access East and Impact Health at $14.25M each.
3. **UKHS Care Collaborative Association, KS, four awards (non-provider recipients).** $23.8M, $15.6M, $5.4M and $4.5M, passed on by subaward to KUMC and HealthWorks KHA Foundation. Its fifth line, $37.8M of incentive payments to participating providers, is on the pass-through tab.
4. **Guidehouse, NM, $20.1M award (consultant; McLean, VA).** It will run New Mexico's Center for Rural Health Sustainability & Innovation.
5. **Invest Nebraska, $20.0M award (non-provider).** The Catalyst Fund for "health technology startups".
6. **Public Consulting Group, ID, $14.52M award (administers).** "Third Party Administrator for Ladder Payment Program".
7. **Virginia Innovation Partnership Corp., $9.9M (non-provider).** Grants to early-stage technology companies.
8. **Foundation for a Healthy Kentucky, $9.1M contract (consultant).** "consulting, analytics, and decision support". The figure matches CMS's unnamed line KY-001-02-03.
9. **Delaware Prosperity Partnership, $6.0M (catalyst funds) and Delaware Community Foundation, $5.8M (administers).**
10. **Big firms.**
    - Ernst & Young, KY: $5.2M contract.
    - McKinsey, VT: $5.1M award.
    - Idaho: Guidehouse $1.76M, BDO $1.99M, Deloitte $1.29M and 22nd Century $2.0M awards.

## Unnamed contractor money (CMS lines that name no firm)

There are 45 lines in 24 states, **$148,946,402.72 obligated**, none of it attributed to a firm. The largest:
- SC $25.9M
- NH $20.4M
- KY $14.3M
- OK $11.0M
- MS $10.0M
- ME $9.6M
- AK $9.2M
- KS $9.2M
- CA $8.5M

## Drops: the large ones and why

- **V1, no admissible source:**
  - NH FHC $66.5M.
  - IL ICAHN $50.0M (its own release only).
  - WA WSHA $42M (a deck).
  - WV KPMG ~$8M (press only).
  - CO HealthTech Solutions (an annual report).
  - CT Mathematica (a Governor release).
- **V4, the quote does not show the category:**
  - KY FHKY $50.5M FSRS and $29.2M lines.
  - OK LifeCare $33.9M.
  - NV NRHPF $20.3M.
  - IL associations $44M.
  - RI HARI and CTC-RI.
  - ME MCD.
  - UT HK Consulting $11M (a software build).
  - Programme-name-only FSRS lines.
  - Independent check: VSAC $9.06M, UNC/UT $1.48M, Safetech $1.17M and Co Magine ID $2.0M.
- **V7, a state agency:** AZ OEO $46.9M, UT UETN $47.4M, HI SHPDA $25M, WV Jobs Investment Trust $18.8M, VA VFHY $11.1M.
- **V9, the money funds the vendor's own in-state operations:** VT Kinney Drugs, IN Spirit EMS, AK Fond of You, DE Thomas Jefferson University.
- **V6, no FSRS address:** national firms keep their CONSULTANT case without an out-of-state label (EY, McKinsey, Bailit, RTI, the Idaho contractors).

## Independent checks

**Round 1 (all 57 original cases).**
- 48 kept and 9 dropped; 406 of 417 applicable test results PASS (97.4%).
- No amount, name, UEI, address or SHA-256 mismatch.

**Round 2 (the 39 changed cases plus Jefferson).** Changed means the Idaho cases, every INTERMEDIARY case (new type field), Guidehouse's V9 evidence and Invest Nebraska's longer quote.
- 39 kept; Jefferson DROP (V9), agreeing with the hand drop.
- Intermediary type agreed except VV016 and VV019, which were re-typed ADMINISTERS_ONLY as above.
- **Combination rule.** A round-1 DROP stands unless an owner ruling answered it (`VV_R1_SUPERSEDED`: the five Idaho contractors). So VSAC and Co Magine, which round 2 kept, stay dropped.

**Round-2 notes kept for readers:**
- **Comagine UT FAST 4.1:** the $2.0M intent and FSRS's $6.0M executed agreement for the same initiative are unreconciled.
- **WY WIP:** a committee approval (intent), and WIP's legal form is not shown in the archive.
- **Comagine ID:** keeps OUT_OF_STATE_VENDOR because no archived source places it in Idaho, although the verifier believes it has an Idaho presence. This is a risk.
- **UKHS Care Collaborative:** treated as an association, not a health system; FSRS shows no parent.
- **Hospital money overlap:** if this list and the hospital figures are ever combined, NHVN, UHA $9.89M and VHHA's RPM/GME are already counted as hospital money. That is why they are on the pass-through tab.

## Method notes and limits

- **V7 state agency.** FSRS "STATE GOVERNMENT" (other than a state university) or STATE_AGENCY in this repo's award files.
- **UEI and address.** Only from the same FSRS record, the same identifier, or an equal normalised legal name.
- **Live check.** All 52 listed sources are live today and serve their archived bytes, apart from the Vermont page and the Utah doc. Both changed after archiving, but each case's name, amount and quote are still on the live page.
- **Coverage.** FFATA excludes procurement and 19 states file no subawards, so most consulting contracts are invisible. The web search for big-firm contracts was brief, and state portals were not searched directly.
