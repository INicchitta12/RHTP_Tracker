# Session 119 (2026-11-16): Accenture NM, annual-report sources, Indiana GROW, FSRS leftovers, vendor-flags rebuild

**Branch:** `claude/epic-planck-nrg5ky`, from `main` after PR #129 (session 118).

## Report first

### Hospital figures, before (session 118's 11-16 build) and after (this session's 11-16 build)

| Figure | Before | After | Change |
|---|---:|---:|---:|
| Awards published (national) | $6,404,664,055.52 | $6,272,900,204.35 | −$131,763,851.17 |
| Hospital best estimate | $2,533,593,302.39 | $2,518,590,896.39 | −$15,002,406.00 |
| Strict NAMED_HOSPITAL | 2,268 / $2,204,266,238.38 / 42 | 2,270 / $2,205,963,832.38 / 42 | +2 rows / +$1,697,594 |
| POOL_NAMED / POOL_UNNAMED | $96,565,779.43 / $79,214,848.17 | unchanged | — |
| Hospital % of awards (national) | 39.6% | 40.2% | the denominator fell |
| ≥50% subset row | n = 35; awards $5,574,558,778; best $2,317,774,646; 41.6% of awards, 33.0% of allotment | n = 34 (NM out); awards $5,417,675,376.70; best $2,302,772,240.43; 42.5%; 33.8% | NM leaves |
| Rural cut | 793 / $696,097,519.78 | 794 / $697,795,113.78 | +Pipestone (CAH 241374) |

By state: **NM** −$128,979,618.21 awards (Accenture held out; NM falls to 11.9% of allotment and leaves the subset);
**IN** −$16,700,000 best estimate (Region 5 back to a tie); **MN** +$1,697,594 strict (Pipestone CAH);
**KS** −$1,460,000, **CT** −$1,224,235, **OK** −$99,997.96 awards (all non-hospital duplicates or de-obligations).

### Verified vendor figures

| Amount type | Before | After |
|---|---:|---:|
| Award | $167,506,827.60 | $167,506,827.60 |
| Intent | $48,233,747.84 | $48,233,747.84 |
| Contract maximum | $25,965,898.00 | $25,965,898.00 |
| Obligation | $2,205,500.00 | **$30,181,665.63** (+$27,976,165.63: SC $26,095,265.63 + CO $1,880,900) |
| Administers (new type) | — | $128,979,618.21 (NM Accenture; never added to any total) |

Obligation by category: consultant $25,156,213.31 (BCG, Milliman, BDO, Slalom, HealthTech + the existing $2.2M);
non-provider intermediary $5,025,452.32 (SCRA). PUBLIC/NON_PUBLIC: all of the new obligation is NON_PUBLIC (SCRA is
marked NON_PUBLIC; see the open question). Amount types are never added.

### Accenture (Task 1)

- **New Mexico's own record of the agreement.** HCA's RFP 26-630-1000-0019, *ASO Services for Rural and Behavioral
  Health Program Administration* (released 2026-04-30; Service Domain 3 = RHTP), its FAQ, and HCA's RHT programme page
  (read 11-16): *"Administrative Services Organization (ASO) RFP … Selection complete — announcement will be made by
  November 30, 2026."* Archived under `data/evidence/recheck/2026-11-16/NM/` with a manifest. **HCA has not named the
  ASO or published an amount.** The FSRS filing (PSC 27-630-1000-1007, action 2026-10-28) is the only record, and it
  does not cite the RFP: the link is an inference from "ASO". The Sunshine Portal was unreachable from this
  environment (TLS handshake failure / proxy 502): **UNKNOWN, not NO.**
- **(i) Fee / contract maximum: not published.** Bound only: the statute caps administrative expense at 10% of the
  allotment (NM: $21,148,474), shared across all admin. Accenture's $128,979,618.21 is 61% of the allotment, about six
  times that cap.
- **(ii) Pass-through share: not published, but most of it is very likely pass-through.** RFP Appendix F.3 §3.1.10:
  *"The ASO shall process and issue payments to RHTP-funded entities in accordance with executed contracts and HCA
  policies"*. FAQ Q20: *"subawards will primarily, but not exclusively, be administered by primary entities procured
  through an RFP, RFA, or other HCA-approved process."* The ASO may not make funding determinations (§1). To whom it
  pays: RHTP-funded entities under HCA's five initiatives (Healthy Horizons hubs, Rooted in NM, the Innovation Fund,
  Bridge to Resilience/CRHSI, the Data Hub). No payee list is published. **This is an inference from the RFP and the
  cap, not a state statement of the split.**
- **(b) Overlap.** NM's other Year 1 first-tier FSRS filings are Guidehouse (CRHSI operator) $20,100,772.81, UNM
  $2,500,000 + $720,000, and EPCOG $1,798,778. Together that is $25,119,550.81. If Accenture's ASO pays these entities,
  up to that much is counted twice; if it pays the Healthy Horizons hubs, the 11-03 hub filings (Gila Regional
  $2,168,368, Nor-Lea $2,193,450, Cibola $1,976,762.40, UNM $3,913,670.43; Year 2, held) overlap too. NM has no state
  award roster, so no roster row overlaps. **The overlap cannot be measured until HCA publishes the ASO payees.**
- **(c) Done.** The row carries `flag_reason = ADMINISTRATOR_PASS_THROUGH_UNRESOLVED` (new code, vocabulary note), set by
  `R/09b`'s hand typing. `R/08` drops it from every award and hospital figure and shows it in the new column
  `excluded_award_usd`. It therefore leaves the ≥50% test: NM moves from 72.9% to 11.9% of its allotment.
- **(d) Done.** The spend layer has ADMINISTRATOR / MIXED (VV070). The verified list shows it as amount type
  `administers` ("administers $129.0M", the PCG phrasing), with the FSRS quote and **no verified vendor dollars**.
  No state source gives a fee, so there is no fee row.

### Indiana GROW Region 5 (Task 3)

Owner ruling applied in `R/03bi`: the five removed members that hold a live FSRS subaward are reinstated, and the five
without one stay removed. The file goes from 176 to 181 rows; hospital rows 42 → 43 (Bluffton Health System LLC, $0).

Region 5 has 14 members, 7 of them typed hospitals: Harsha Behavioral Center, Putnam County Hospital, Union Health
Inc., St. Vincent Clay Hospital Inc., Union Hospital Clinton, Greene County General Hospital, and Sullivan County
Community Hospital. The other 7 are Cummins Behavioral Health Systems (NONPROFIT_CBO), Indiana Health Centers (FQHC),
Owen County EMS, Sullivan County Ambulance Service, Valley Professionals CHC (FQHC), Putnam County EMS MIH, and **West
Central Indiana Economic Development District (reinstated; FSRS 99913, $176,080.16, action 2026-08-28)**.

That is a tie, and a tie is not a majority, so the call is **NOT_HOSPITAL**. Session 118's +$16.7M is reversed. The
sources are IDOH's 09-24 and 11-16 GROW pages (archived) and Indiana's FSRS filings (archive 2026-11-16).

The other four reinstated members are all Region 2: Bluffton Health System LLC ($20,000), Huntington County Council on
Aging ($266,560.55), Living Well in Wabash County CoA ($50,145.02), and Wells County Council on Aging ($182,442.75).
Region 2 stays NOT_HOSPITAL (6 of 26). Their FSRS dollars stay held: a pool priced at pool level is never priced
member by member.

### FSRS rules decided (Task 4)

1. **A negative FSRS amount is a de-obligation and nets against its subaward** (rule in CLAUDE.md §7; `fsrs_net_deobligations()`).
   - It reduces the earliest written positive action of the same key (state, subaward number, UEI) dated before it.
   - It is listed in `fsrs_held.csv` as `NETTED_DEOBLIGATION`.
   - With no written base it stays held.
   - Connecticut has six: DEEP $7,165,955 − $1,219,235 = $5,946,720, plus five administrative −$625 / −$1,250
     adjustments (DADS, Agriculture, DMHAS, OEC, CT State Community College). Total −$1,224,235.
2. **CT's positive second actions are increments, already written as separate rows**: DMHAS $4,000,000, SDE $617,985
   and DPH $6,100 (116c rule: per action, never cumulative). The reasons: negative actions only make sense as deltas,
   and each second action is smaller than its base, so it cannot be a revised total.
3. **MN, University of Minnesota, 2 × $997,498: two awards.** Different subaward numbers (297179, 298490) and action
   dates (10-01, 10-20). The re-filing rule collapses only an identical key, date, amount and description. Unchanged.
4. **OK SWOSU: paired.** FSRS 3409028582 ($99,997.96) is OSDH's Washita County microgrant (row 66, printed $54,997.96).
   The gap is exactly $45,000 and the last five digits match; the other SWOSU microgrant pairs exactly. The roster
   amount stands (DIFFERS). OK awards −$99,997.96.
   - **New tool:** `config/fsrs_subaward_pairings.csv` gains an optional `row_no`, to pin a pairing when one awardee has
     several rows.
5. **KS DCF/KCDD: paired.** FSRS $1,460,000 to the Kansas Department for Children and Families equals KDHE's RPGP
   award to the Kansas Council on Developmental Disabilities (row 31) to the dollar, under the same prime and inside
   the RPGP window. Read as the council's award filed under its state fiscal agent (my call; reversible). KS awards
   −$1,460,000.
6. **MN Pipestone: promoted.**
   - FSRS files "PIPESTONE COUNTY MED CENTER", 916 5th Ave SW, Pipestone.
   - CMS MN enrolment has PIPESTONE COUNTY MEDICAL CENTER, CAH **241374**, 916 4th Ave SW.
   - That is a hand-read LEGAL_NAME_TRUNCATED bridge, so LOW. Result: HOSPITAL_OR_SYSTEM / DIRECT, +$1,697,594 strict
     and rural.
7. **MN Murray County: HELD (not promoted).**
   - FSRS files "MURRAY COUNTY SLAYTON" at 2500 28th St (the county offices), $1,535,332 + $75,000.
   - The enrolled CAH's legal entity is COUNTY OF MURRAY (dba Murray County Memorial Hospital, CCN 241319,
     2042 Juniper Ave).
   - The county is the hospital's operator, but it is also a general-purpose government, and the generic FSRS
     description does not say the money is the hospital's (the City of Ketchikan precedent).
   - **Owner question:** promoting both rows would add $1,610,332.

### Vendor flags (Task 5)

`R/09 --build` runs again: `vendor_flags.csv` has 196 rows. What changed:
- **Four FSRS subrecipients read.**
  - Ivy Creek is a hospital system (HD78), excluded.
  - Evergreen Nephrology is a physician practice on AL's roster, $891,588, under $1M, excluded.
  - ACLM is HD79 (the purpose text describes another organisation's project), excluded.
  - ANDORHEALTH now matches the dictionary (`\bAndor ?Health\b`).
- **Guidehouse override.** It now points at the NM award-file row: FSRS has been an award source since 116c.
- **New `layer_*` columns.** Each flag now carries the current spend-category layer: `layer_spend_category`,
  `layer_vendor_role`, `layer_vendor_verified`, `layer_vendor_verified_usd`, `layer_vendor_case_id` and `layer_file`.
  The join is on state, recipient string and amount to the cent.
  - 128 of 196 flags join.
  - The unjoined are CMS lines (13), RCJ leads (11), budget lines (12), FSRS-only records (18), and 14 award-file
    flags whose recipient string or amount differs from the row.

`output/verified_vendor_list_2026-11-16.xlsx` was rebuilt:
- 46 verified cases.
- A fresh live check: `verified_vendor_live_check_2026-11-16.csv`, all 63 LIVE.
- The independent check kept all seven new cases.

### Probe log since 11-16 (Task 6)

Session 118 read every line through NEWSROOM 16:55Z. New since then:

| State | Time | Verdict | Read |
|---|---|---|---|
| HI | 18:39Z | TRIPWIRE `shpda` | SHPDA's side menu ("Resources & Publications / Helpful Links / Rural Health / ADA Coordination / Home") welded into one run. The page still names the same three Notices of Award. Added to `HI_NAME_FURNITURE`; the live re-probe is quiet. CHANGED `gov_news`/`doh_news`: no new RHTP headline. |
| KY | 19:35Z | TRIPWIRE `rch` | FHKY's page names the three Hub Leads already in `ky_year1_awardees.csv` (Lake Cumberland, Purchase, Martin County), in a different layout from session 118's capture. Nobody new. Re-based (`2026-11-16b_*`). |
| KY | 19:35Z | TRIPWIRE `funding` | Three Tier 2 RFAs: Rapid Response to Recovery – Transportation Services (due 11-06), Telebehavioral Health Support, and CHW Specialized Certificate FAQ/info-session PDFs. Nobody named. Re-based. The live re-probe is quiet; `chfs_grants` is CHANGED only. |

- **No YEAR2, VENDOR or LEAD line since 11-16** apart from CMS's national Year 2 event, which session 118 read.
- **Nothing in the log moves a hospital or vendor dollar.** No priced state roster or executed contract appeared, so
  nothing was extracted.
- **Context the runners recorded before 11-16, unread here:**
  - MT home page (11-13): a $473,250,028.01 award sentence, the BP1 + BP2 cumulative footer class.
  - NC ROOTS (11-14): $429.8M currency figures.
  - SC programme page (11-12): names 3 new organisations; its runner flagged it for a human.
  - LA: its tripwire persists.

  The SC trip is the one to read first next session.
- **Runners: none above 650k** (`used_tokens`, 11-16 ~20:30Z): IN 636,823, SC 636,457, MT 630,182, LA 628,710,
  DE 624,338, KS 613,912, NC 600,412. None moved. IN and SC come first at the next move.

## Calls made under the standing rules (each reversible)
1. **The Accenture overlap is not measured.** No state payee list exists; the RFP language and the 10% cap are the basis for "mostly pass-through".
2. **KS DCF ↔ KCDD pairing.** Same amount and prime, a plausible fiscal-agent filing. If they are two awards, KS gains $1.46M (non-hospital).
3. **OK SWOSU pairing** on a $45,000 keying gap.
4. **MN Pipestone promoted (LOW); Murray County held.**
5. **CO HealthTech's quote extended** to both Use of Funds lines (CO13 + CO14), so it covers the whole $1,880,900 (independent-check suggestion).
6. **SCRA is NON_PUBLIC and not a state agency under V7** (nothing archived types it as one). Owner question: SCRA is state-chartered (SC Code Title 13 Ch. 17). If the owner rules it a state agency, VV065 drops (−$5,025,452.32 obligation).
7. **TX and CO annual-report contract rows** now carry `validation_source_type = STATE_REPORT` (R/10), as SC's do.
8. **Case IDs VV064–VV070.** VV057 had been used by a dropped 116e case (Jefferson DE), so the new cases start at VV064.
9. **`VV_AS_OF` moved to 2026-11-16** for the live check. The 11-10 live file stays.

## Open for the owner
- MN Murray County (Slayton): promote on the county's enrolment (+$1,610,332 hospital)?
- SCRA under V7 (public research authority = state agency?) and its PUBLIC mark.
- KS DCF/KCDD pairing (above).
- Accenture: re-read when HCA announces the ASO (by 11-30). Split the fee from the pass-through and measure the overlap; then clear the flag.

## Suite
See the merge commit message.
