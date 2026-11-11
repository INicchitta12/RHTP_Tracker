# Session 116f: vendor spending as a standing tracked category

**Date:** 2026-11-11. **Branch:** `claude/affectionate-cerf-kuc69o`, cut from `main` at `62d6089`.
**Owner direction:** track consultants, data/tech vendors, programme administrators, non-provider intermediaries and
out-of-state contractors as a standing spending category beside hospital spending.
**No hospital figure moved.** `year1_summary_2026-11-11.csv` is byte-identical to the 11-09 build; the strict
partition is pinned to the cent in `test_10_spend_category.R` and `test_08` (NAMED_HOSPITAL 2,204 / $2,170,425,246.88;
POOL_NAMED $86,895,779.43; POOL_UNNAMED $79,214,848.17; best estimate $2,473,382,310.89).

## Report first

### National vendor totals (VERIFIED only; amount types never added together)

| Category | Award | Intent | Contract maximum | Obligation |
|---|---:|---:|---:|---:|
| ADMINISTRATOR | $93,563,487.64 (7) | $42,618,260.00 (4) | — | — |
| CONSULTANT | $36,777,789.96 (9) | $4,374,402.29 (2) | $24,267,862.00 (5) | $2,205,500.00 (1) |
| NON_PROVIDER_INTERMEDIARY | $35,895,550.00 (3) | — | — | — |
| DATA_TECH_VENDOR | $1,270,000.00 (1) | $1,241,085.55 (1) | $1,698,036.00 (1) | — |
| **Total** | **$167,506,827.60** | **$48,233,747.84** | **$25,965,898.00** | **$2,205,500.00** |

- **Out of state (V6):** award $24,479,755 (4 rows: Guidehouse NM, Comagine ID ×2, Unite Us WV), intent $3,947,362 (2: Moda AK, MapHabit AK).
- **Leads (not verified, context only):** $65.2M award, $18.0M intent, $4.9M obligation and $2.6M contract maximum on award-file rows; $6.3M on contract rows. The largest: FL CommunityHealth IT $43.7M (four lines; 116e dropped it on V4, because Florida prints no purpose); UT HK Consulting $11.0M intent; AK healthEconnect $4.6M; CT Mathematica $4.0M; OK Pulsara $3.8M obligation.
- **Unnamed contractor obligations** (CMS 10-14 edition, context): 45 lines, $148,946,402.72. CONTRACTOR_ONLY is $116,332,666.43 (41 lines). MIXED is $32,613,736.29 (4 lines: NH $20.4M, KS $9.2M, MO $2.0M and KY $1.1M); these also cover state staff or agencies.

### Top 15 verified vendor rows

| # | State | Recipient | Category | Type | Verified $ |
|---:|---|---|---|---|---:|
| 1 | WY | Wyoming Innovation Partnership | ADMINISTRATOR | intent | 35,424,820 |
| 2 | NC | Trillium Health Resources (PUBLIC) | ADMINISTRATOR | award | 28,500,000 |
| 3 | NM | Guidehouse Inc. (out of state) | CONSULTANT | award | 20,100,773 |
| 4 | NE | Invest Nebraska Corporation | NON_PROVIDER_INTERMEDIARY | award | 20,000,000 |
| 5 | ID | Public Consulting Group | ADMINISTRATOR | award | 14,520,000 |
| 6 | NC | Impact Health | ADMINISTRATOR | award | 14,250,000 |
| 7 | NC | Vaya Health (PUBLIC) | ADMINISTRATOR | award | 14,250,000 |
| 8 | NC | Access East, Inc. | ADMINISTRATOR | award | 14,250,000 |
| 9 | VA | Virginia Innovation Partnership Corp. | NON_PROVIDER_INTERMEDIARY | award | 9,891,550 |
| 10 | KY | Foundation for a Healthy Kentucky | CONSULTANT | contract maximum | 9,102,500 |
| 11 | DE | Delaware Prosperity Partnership | NON_PROVIDER_INTERMEDIARY | award | 6,004,000 |
| 12 | DE | Delaware Community Foundation | ADMINISTRATOR | award | 5,792,568 |
| 13 | KY | CDC Foundation | CONSULTANT | contract maximum | 5,599,021 |
| 14 | KY | Ernst & Young US LLP | CONSULTANT | contract maximum | 5,226,424 |
| 15 | VT | McKinsey & Co. | CONSULTANT | award | 5,100,000 |

Trillium's award-file row is $29,578,000. Only the $28,500,000 subaward is a verified case, so only that amount counts.

### States with the most verified vendor dollars

| State | Award | Intent | Contract maximum | Obligation |
|---|---:|---:|---:|---:|
| NC | $71,250,000 | | | |
| WY | | $38,618,260 | | |
| KY | | | $25,965,898 | |
| ID | $24,666,188 | | | |
| NE | $22,000,919 | | | $2,205,500 |
| NM | $20,100,773 | | | |
| DE | $11,796,568 | | | |
| VA | $9,891,550 | | | |
| VT | $6,530,829 | | | |
| UT | | $5,668,126 | | |
| AK | | $3,947,362 | | |
| WV | $1,270,000 | | | |

### Vendor versus hospital, nationally

- **Verified vendor dollars on award rows (award plus intent): $215,740,575.** That is **3.5%** of the $6,189,503,205 in published awards.
- **Hospital best estimate: $2,473,382,311**, or **40.0%** of the same awards.
- The verified vendor figure is about **one-eleventh of the hospital figure**.
- **It is a floor, not an estimate.** Vendor money sits mostly in procurement contracts. 2 CFR 170 keeps those out of FSRS, and most states publish no contract register.
- **Where the ≥50% rule allows a state share, vendor dollars are largest in:**

| State | Vendor share of awards | Hospital share of awards |
|---|---:|---:|
| WY | 22.2% | 48.5% |
| ID | 15.6% | 56.5% |
| NE | 15.4% | 34.8% |
| DE | 11.0% | 3.1% |

- **NC is n/m.** It has the most verified vendor dollars, but its state-sourced awards are under half its allotment.

### Classifications I was unsure of

1. **UKHS Care Collaborative is PROVIDER_PASS_THROUGH on all five lines ($87.1M).** Session 116e had the four smaller lines ($49.3M) as NON_PROVIDER_RECIPIENTS. Their quotes say subawards go to KUMC and HealthWorks KHA Foundation, not to providers directly. I applied the owner's ruling to the entity, so those $49.3M are no longer vendor money. If the ruling was meant for the $37.8M incentive line only, re-call VV003–VV006 in `config/spend_category_cases.csv`.
2. **VHHA Foundation's Food is Medicine award ($2.47M) is now PROVIDER_PASS_THROUGH.** Session 116e listed it on the main list as ADMINISTERS_ONLY. The owner's new rule, that hospital associations never enter vendor categories, moved it.
3. **TEKsystems ($1.70M, KY) is DATA_TECH_VENDOR.** Session 116e listed it as CONSULTANT. Its quote is technology work.
4. **Five 116e cases were labelled only OUT_OF_STATE_VENDOR, so each needed a category.**
   - Moda AK: CONSULTANT (PCMH implementation support).
   - Comagine ID, two cases: CONSULTANT (a quality-improvement organisation).
   - Unite Us WV: DATA_TECH_VENDOR.
   - MapHabit AK: DATA_TECH_VENDOR.
5. **Staff augmentation counts as CONSULTANT.** This covers CDC Foundation, Eight Eleven Group and Go-Hire in KY.
6. **Arkansas Rural Health Partnership and Great Plains Health Alliance (KS) are treated as hospital networks.** That rests on general knowledge. Under the hospital-network rule they can never be vendors.
7. **LifeCare Alliance (OK, $33.9M obligated) is a PROVIDER_PASS_THROUGH lead.** The source says "subcontracts ... first cohort of health systems". 116e dropped it on V4, and it is not verified.
8. **Health information exchanges are DATA_TECH_VENDOR leads.** This covers MiHIN, GaHIN, healthEconnect Alaska, NEHII, Virginia Health Information and WVHIN. They are nonprofit data utilities, not commercial vendors. Delaware's DHIN is typed STATE_AGENCY, so it is OTHER (V7). The first pass missed this, and it is fixed and tested.
9. **CO HealthTech Solutions ($1.88M obligation) is DATA_TECH_VENDOR from the dictionary.** Colorado's own report types it "Other Consulting", so CONSULTANT may be the better call.
10. **`out_of_state = FALSE` means "not shown", not "in state".** National firms with no FSRS address read FALSE: EY, McKinsey, Bailit, RTI, and the Idaho contractors Deloitte, BDO and Guidehouse.
11. **The MIXED split of unnamed CMS lines is a regex.** ME-003-09-20 ($9.6M, "overall project leadership, management, contracting, and oversight of contractors") stays CONTRACTOR_ONLY.
12. **The KY tracker parse does not reconcile.** Its 218 rows sum to $127,182,976.26 against a printed header of $129,140,844, a gap of $1,957,867.74. Every dated line was parsed, so the gap is recorded rather than imputed. Wrapped names are assigned by a proximity rule, and every recipient ≥ $1M was eyeballed.
13. **Contract-row hospital typing is a name rule.** TX's 33 hospital districts are HOSPITAL in `tx_contracts.csv`. Contract rows never count toward the hospital share, but a district without an enrolled hospital would be mis-typed there.

## What was built

| Task | Files |
|---|---|
| 1 Spec | `rhtp-tracker-build-spec.md` §8.1 (new), `CLAUDE.md` §7, `vocabularies.csv` (+`spend_category`, `vendor_role`, `STATE_CONTRACT`) |
| 2 Classify | `R/utils_spend_category.R` (`rhtp_spend_category()`, the one function), run LAST by `R/07 --apply`; `config/spend_category_cases.csv`, `config/spend_category_entities.csv`, +21 dictionary entries; `test_10_spend_category.R` |
| 3 Contracts | `R/10_contract_registers.R`; `data/reference/contracts/{ky,tx,co,ok,ms,cms_obl}_contracts.csv`; `config/contract_registers.csv`; KY/CO/MS probes watch their registers |
| 4 Monitoring | VENDOR verdict + `rhtp_vendor_tripwire()` inside the shared name tripwire; `usa_vendor_flags()` in `R/09a --probe`; `rhtp_unnamed_contractor_lines()` (newest edition, CONTRACTOR_ONLY/MIXED); `test_10b_vendor_monitoring.R` |
| 5 Year 1 table | `R/08`: `year1_vendor_summary_2026-11-11.csv`, "Vendor spending" sheet, Definitions and Notes; `year1_summary_2026-11-11.{csv,xlsx}`; `test_08` re-pinned |
| 6 Vendor list | `output/verified_vendor_list_2026-11-11.xlsx` from the layer; `rhtp_xlsx_strip_dangling_rels()` shared; three workbooks repaired; `test_output_workbooks.R` |

**Every award and contract row has a category.** Award rows: HOSPITAL 2,245; OTHER 3,072; PROVIDER_PASS_THROUGH 17; CONSULTANT 76; DATA_TECH_VENDOR 46; ADMINISTRATOR 11; NON_PROVIDER_INTERMEDIARY 3. Contract rows: 274 across six files. Every 116e case lands on exactly one row.

**Contract registers:**
- **SD, VT and ID have no contract file.** Each register is already an award file, and a second copy would double-count it.
- **TX's register is watched by R/03n**, which already trips on a district count other than 33.
- **OK's register is watched by R/03t's legislative-reports list.**

## Operational notes

- **Overlay order is unchanged:** `R/07 --apply` remains LAST, and now also writes the eight spend columns. A rebuild drops them, and `test_10` fails until `R/07 --apply` is re-run.
- **After `R/10 --build`, run `R/07 --apply`.**
- **A new CMS obligation edition needs no code change.** Once `R/00c`/`R/00e` writes `cms_obligations_bp1_lines_<date>.csv`, `R/08 --build` re-splits it.
- **VENDOR rows in `logs/probe_results.csv` are logged and never raised.** Read them as leads for the contract layer.
- **Runner context:** this session edits `CLAUDE.md` (§7 and §10), so each persistent runner reloads it once more at its next resume, per §2.2a.
