# Session 96 (2026-10-07): KS EBP resolved, Delaware agent withdrawn, AHAP read, KS render provenance

Four owner tasks. No state file changed and no partition figure moved.

## 1. `KS_EBP_ENROLMENT_NOT_AWARD`: RESOLVED at (a)

- **Decision (owner).** The 94 hospitals on the Care Collaborative's 09-18 list are enrolled participants. They
  stay in `ks_ebp_participants.csv`, a non-award file, at $0.
- **Why.** Every payment under the hospital participation agreement is contingent: on the attestation, on Q3
  reporting, and on CCA receiving RHT funds. The Care Collaborative's administrative FAQ (09-18; the publisher is
  the Care Collaborative, not KDHE) says it "will post on its website a list of providers that have received
  infrastructure payments and incentive payments".
- **When it reopens.** R/03o's probe trips when that list is posted. Each paid hospital then becomes an award row:
  `PASS_THROUGH_DESIGNATED`, `intermediary_name` = UKHS Care Collaborative Association, typed on CMS KS enrolment.
- The queue row was edited byte-wise (CRLF kept; `git diff --numstat` 1/1).

## 2. news.delaware.gov: browser agent withdrawn

- **Why.** Session 95's own measurement showed the F5 block intermittent for both agents (project 7/8 served,
  Chrome 5/8). The block is not keyed to the agent, and the retry is what cures it.
- **What changed.**
  - `RHTP_DE_NEWS_USER_AGENT`, `rhtp_agent_for_url()`, `rhtp_assert_agent_scope()` and `rhtp_url_host()` are
    removed from `R/utils_config.R`.
  - `rhtp_watch_fetch()`, R/03al's `de_get()` and R/03bg's `nw_retest_unreadable()` send the caller's honest
    agent again.
  - `rhtp_fetch_past_firewall()` is unchanged. A persistent block still logs ERROR "FIREWALL REJECTION".
- **Tests.** `test_utils_agent_scope.R` is rewritten. It fails if any file in `R/` carries a browser agent string
  or the removed helpers. It also checks that the Delaware fetchers use the honest agent and that the retry is
  still wired in. michigan.gov is again the only agent exception (§3).

## 3. The Care Collaborative's Anchor Hospital Advancement Program (AHAP)

Read live on 2026-10-07 with the project agent. Archived at
`data/evidence/KS/ahap/2026-10-07_rhk_ahap_program_page.html` via `rhtp_watch_archive()`, which strips the Divi
nonces. Both digests are in the MANIFEST.

**Is it RHTP-funded? Yes, as a Tier 2 plan.** The page says "Through the Rural Health Transformation Program
(RHTP), AHAP was named as a key program". KDHE's Year 1 Budget Narrative, Revision 2 (July 2026, archived under
`budget_narratives/KS/`), is the primary source:

- **The money path.** Initiative 2, Program 4: "KDHE will sub-award CCA to contract with the Anchor Hospital
  Advancement Program (AHAP), a joint venture formed by Kansas' urban not-for-profit health systems to provide
  specified operational support services for Kansas' rural anchor hospitals". The anchor hospitals are "ten larger
  rural facilities providing specialist services on a regional basis".
- **Year 1 plan lines that run through AHAP:**

  | Line | Amount | Source |
  |---|---:|---|
  | On-demand subject matter experts | $414,000 | Tables 7.F.5 / 10 |
  | AI/EHR implementation and optimization | $9,800,000 | Tables 7.F.5 / 10 |
  | Rural residency programs ("KUMC and anchor hospitals") | $2,138,590 (Table 11.F.5) or $2,236,590 (text) | Initiative 3, Program 1A |
  | AHAP, LLC project management for remote patient monitoring | $150,000 | Table 13.E.5 |

- **Not through AHAP: the BioIntelliSense contract.** "Remote Inpatient/Post-acute Monitoring at anchor hospitals"
  is $7,014,500, a CCA contract with BioIntelliSense. Its $2,000,000 of "participating hospital setup fees" (~$200k
  per facility across 10 sites) is paid to the vendor.
- **The residency figures do not agree.** The table and the text differ by $98,000. Neither is an award.

**Does it name hospitals? Two of ten, as pilot sites only.** The page says 10 rural hospitals "have been designated
as anchor hospitals eligible for support services and programs" and does not list them. The only names are the
RPM pilot sites: "Implementation planning continues at AHAP pilot sites Newman Regional Health and Labette Health".
The "AHAP Media Fact Deck" link is a relative href (`ruralhealthkansas.com/about`), so it resolves to nothing.
The /about page carries no deck and no roster.

**Does it pay hospitals? Not on any document read.** The narrative's flow is CCA → AHAP, which buys and delivers
services: SMEs, vendor AI/EHR tools ("leveraging vendor solutions"), and RPM through BioIntelliSense. "CCA will
distribute funds to AHAP as it secures contractual commitments from anchor hospitals to utilize specified
services". So the hospital benefit is services, not dollars. That is the Georgia Hospital Association carts shape:
`IN_KIND_BENEFIT`, never in a hospital total.

AHAP's recipient form would be hospital-affiliated, because it is a joint venture of health systems. That needs a
§10.2 read when an award document exists. Today none does. The rural residency line names "KUMC and anchor
hospitals" as the contracted parties, and it is the one line that could become money to hospitals. No allocation
is published.

**Coding: nothing extracted.** These are budget lines (§0.3). Designation as "eligible for support services" is
§6.1 mode 3. The two named pilot sites are a site list, not an award. AHAP is not in R/03o's disposition and is not
on any probe. A probe for it is a candidate next step and was not built.

## 4. `recheck/2026-10-07/KS/` is a third-party rendering

`PROVENANCE.txt` in that directory records it:
- It is the markdown that r.jina.ai returned, with its SHA-256.
- KDHE's bytes never reached this repository.
- It is not a baseline and not a validation source (§0.4).
- It supported only the probe-scoping finding.

The file name ("browser_render") is kept so the session-95 references stay valid. R/03o's session-95 comment now
says "third-party rendering".
