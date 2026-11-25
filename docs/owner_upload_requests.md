# Owner uploads requested (session 124)

These pages return 403 or 404 to this cloud environment. Please open each in a browser, save it
(PDF: "Save as"; web page: "Save Page As… / Webpage, HTML only" or print to PDF), and drop the file into
`data/raw/owner_uploads/` with the file name shown. The next session archives it with a SHA-256 manifest
and reads it. Nothing here is a source until it is saved and read.

## State RHTP plans (use categories, session 123 Task 7a-e)

| State | Why | URL | Save as |
|---|---|---|---|
| CO | HCPF 403 to the plan document (the programme page itself now reads) | https://hcpf.colorado.gov/rural-health-transformation-program (the "View Colorado's Approved RHTP Application" / project narrative link on that page) | `co_rhtp_project_narrative.pdf` |
| KS | kdhe.ks.gov is Cloudflare-403 on every agent | https://www.kdhe.ks.gov/2361/Rural-Health-Transformation-Program (the RHTP application / project narrative and budget narrative linked there) | `ks_rhtp_project_narrative.pdf`, `ks_rhtp_budget_narrative.pdf` |
| OH | ODH returns 404 for the application path | https://odh.ohio.gov/know-our-programs/rural-health-transformation (the "Ohio's RHT Program Application" link) | `oh_rhtp_application.pdf` |
| NH | every nh.gov host is Akamai-403 | https://www.dhhs.nh.gov/programs-services/health-care/rural-health-transformation-program (the project narrative / application) | `nh_rhtp_project_narrative.pdf` |
| FL | the 111-page application is image-only; a text version would let its "Use of Funds" sections be read | https://ahca.myflorida.com/ (AHCA's RHTP page, any text or Word version of the application) | `fl_rhtp_application_text.pdf` (only if a text version exists) |
| NJ | the application link returned 404 | https://www.nj.gov/health/ (NJDOH's RHTP page, the "Application" link) | `nj_rhtp_application.pdf` |

## Massachusetts (session 124 Task 5a): every mass.gov path is Akamai-403

No reachable route publishes Massachusetts's Year 1 awards. Most likely first:

1. https://www.mass.gov/rural-health-transformation-program-rhtp (the hub; Wayback 2026-10-16) — `ma_rhtp_hub.html`
2. https://www.mass.gov/info-details/key-dates-and-opportunities (Wayback 2026-10-09) — `ma_rhtp_key_dates.html`
3. https://www.mass.gov/info-details/rhtp-newsletters (Wayback 2026-10-09), and every newsletter after July 2026; July is https://www.mass.gov/doc/ma-rhtp-newsletter-july-2026/download — `ma_rhtp_newsletter_<month>.pdf`
4. https://www.mass.gov/info-details/rural-health-transformation-in-massachusetts (Wayback 2026-10-02) — `ma_rhtp_in_massachusetts.html`
5. https://www.mass.gov/rural-health-transformation-program (Wayback 2026-03-21) and https://mass.gov/info-details/about-the-program
6. https://www.mass.gov/info-details/rural-health-transformation-program (no Wayback snapshot)
7. COMMBUYS (https://www.commbuys.com/): search "Rural Health Transformation" with the EOHHS organisation filter; save the award status of the October capital RFA (due 10-26) — `ma_commbuys_rhtp_<bid>.pdf`

Context only, not awards: the Governor's 12-29 release (https://www.mass.gov/news/governor-healey-secures-162-million-to-improve-rural-health-across-massachusetts), the Community Advisory Council release, and the 2026 Medicaid Summit panel deck (https://www.mass.gov/doc/2026-medicaid-summit-panel-4-slide-deck-2-eliza-lake/download).
