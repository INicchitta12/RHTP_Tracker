# CO — use-of-funds evidence notes (session 123)

## Result: nothing mapped. The single unit is NOT_STATED, and Colorado's plan documents were UNREADABLE today.

- **Brief:** one unit. award_pool "Colorado RHTP subrecipient grants, round announced 2026-09-28": 92 rows, $163,954,733.
  It is one RFA round for the whole programme (HCPF's 2026-06-23 release: "apply for $160 million in funding for
  innovative initiatives"). Neither the award page nor the release prints a CMS category, and no row field carries an
  activity. The award page (`recheck/2026-11-02/CO/2026-11-02_hcpf_rhtp_awardees.html`) lists name and amount only.
- **Plan documents located but UNREADABLE.** On 2026-11-24 every hcpf.colorado.gov path returned HTTP 403
  (CloudFront "Request blocked") to the honest agent, including the awardee page that was archived on 11-02.
  WebFetch also returned 403. Nothing was archived and `use_categories/CO/` is empty. These documents are linked from
  HCPF's RHTP page (archived 2026-11-16):
  - Colorado RHTP Project Narrative: `/sites/hcpf/files/Colorado%20RHTP%20Project%20Narrative_FINAL.approved.pdf`
  - Project Narrative (accessible): `/sites/hcpf/files/Project%20Narrative%20%28acc%29.pdf`
  - Supporting Documents, which search snippets say hold a "Use of Funds Mapping Table" mapping the NOFO uses to the ten
    initiatives: `/sites/hcpf/files/Supporting%20Documents.pdf`
  - RFA Sample Activities, RFA Work Plan, and Overview of BY1 Implementation
- **What would still be needed even if the documents were readable.** The round is one RFA spanning Colorado's ten
  initiatives, and the award rows carry no initiative. Mapping the round would give the union of the ten initiatives'
  letters, which is MULTIPLE. A per-award mapping would need the RFA work plans or initiative selections, which are not
  published per awardee.
- **Next step.** Retry hcpf.colorado.gov from another session or network and archive the three documents above. If
  the Overview of BY1 Implementation assigns awardees to initiatives, map at `row` level.
