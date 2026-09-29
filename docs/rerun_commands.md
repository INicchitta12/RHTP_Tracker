# Re-running what exists — every CLI entry point

Moved out of `CLAUDE.md` §10 in session 77 (verbatim below). `CLAUDE.md` §10
keeps the pattern; this is the full list.


```
Rscript tests/run_tests.R                        # 5,3xx assertions, zero quota
Rscript R/02_normalize.R --run                   # newest pull on disk (logged PRODUCTION)
Rscript R/02_normalize.R --run --dev             # an iteration, logged DEV (§5.2)
Rscript R/02_normalize.R --run --date=2026-08-27 # a specific pull
Rscript R/03_state_registry.R --allotments       # §7.1, one call to cms.gov
Rscript R/03_state_registry.R --worksheet        # §7.2, offline
Rscript R/03_state_registry.R --validate         # §7.3, once the registry lands
Rscript R/03b_budget_narratives.R --validate     # §7A parse + assert, no writes
Rscript R/03b_budget_narratives.R --build        # §7A.4 gate, writes data/interim/
Rscript R/03c_cms_abstracts.R --validate         # §4.1 assertions, offline
Rscript R/03c_cms_abstracts.R --build            # renders abstract_named_organizations.xlsx
Rscript R/03d_ga_great_health.R --fetch          # GA: the 2 signed NOAs -> data/evidence/GA/
Rscript R/03d_ga_great_health.R --validate       # GA assertions + reconciliation, offline
Rscript R/03d_ga_great_health.R --build          # writes GA csv + GA_year1_awardees.xlsx
Rscript R/03e_fl_year1_awardees.R --ingest       # owner's FL workbook -> committed CSV
Rscript R/03e_fl_year1_awardees.R --validate     # FL §8 vocabulary assertions, offline
Rscript R/03e_fl_year1_awardees.R --build        # renders FL_year1_awardees.xlsx
Rscript R/03f_pa_year1_awardees.R --fetch        # PA: archive both sources + SHA-256
Rscript R/03f_pa_year1_awardees.R --validate     # PA assertions + reconciliation, offline
Rscript R/03f_pa_year1_awardees.R --build        # writes PA csv + PA_year1_awardees.xlsx
Rscript R/03g_al_year1_awardees.R --fetch        # AL: archive the governor's release
Rscript R/03g_al_year1_awardees.R --validate     # AL assertions, offline
Rscript R/03g_al_year1_awardees.R --build        # writes AL csv + AL_year1_awardees.xlsx
Rscript R/03h_ak_year1_awardees.R --probe        # LIVE: has the rolling notice grown?
Rscript R/03h_ak_year1_awardees.R --fetch        # AK: archive the DOH xlsx + the control
Rscript R/03h_ak_year1_awardees.R --validate     # AK assertions + the 142/19 split, offline
Rscript R/03h_ak_year1_awardees.R --build        # writes AK csv + AK_year1_awardees.xlsx
Rscript R/03i_sd_rht_contracts.R --probe         # LIVE: is the announced round posted yet?
Rscript R/03i_sd_rht_contracts.R --fetch         # SD: archive the search + 13 detail pages
Rscript R/03i_sd_rht_contracts.R --validate      # SD assertions, offline
Rscript R/03i_sd_rht_contracts.R --build         # writes SD csv + SD_rht_contracts.xlsx
Rscript R/03j_sd_year1_announcements.R --fetch    # SD: archive both news.sd.gov releases
Rscript R/03j_sd_year1_announcements.R --validate # SD rounds + the roster tripwire, offline
Rscript R/03j_sd_year1_announcements.R --build    # writes SD y1 csv + SD_year1_awardees.xlsx
Rscript R/00_cms_press_monitor.R --status        # what the CMS trigger list says
Rscript R/00_cms_press_monitor.R --run           # live; BOTH sources, unioned
Rscript R/00_cms_press_monitor.R --run --newsroom # the primary alone (cms.gov)
Rscript R/00_cms_press_monitor.R --run --medicaid # the secondary alone
Rscript R/00_cms_press_monitor.R --run --force   # re-fetch AND re-learn every topic
Rscript R/00_cms_press_monitor.R --parse         # re-parse committed archives, no network
Rscript R/03k_rcj_state_survey.R --build        # 50-state RCJ survey, offline
Rscript R/03k_rcj_state_survey.R --report       # the ranked table + the flagged states
Rscript R/03l_il_year1_awardees.R --fetch       # IL: archive ICAHN + the two HFS sources
Rscript R/03l_il_year1_awardees.R --validate    # IL assertions + reconciliation, offline
Rscript R/03l_il_year1_awardees.R --build       # writes IL csv + IL_year1_awardees.xlsx
Rscript R/00b_state_trigger_queue.R --build     # the CMS + RCJ union, offline
Rscript R/00b_state_trigger_queue.R --status    # what the queue says
Rscript R/03m_or_year1_awardees.R --fetch       # OR: archive 5 OHA sources + SHA-256
Rscript R/03m_or_year1_awardees.R --validate    # OR assertions + reconciliation, offline
Rscript R/03m_or_year1_awardees.R --build       # writes OR csv + OR_year1_awardees.xlsx
Rscript R/03n_tx_year1_probe.R --fetch          # TX: archive 11 HHSC sources + SHA-256
Rscript R/03n_tx_year1_probe.R --validate       # TX assertions + the tripwire, offline
Rscript R/03n_tx_year1_probe.R --build          # writes the two TX status CSVs (NO xlsx)
Rscript R/03n_tx_year1_probe.R --report         # the negative, with its positive control
Rscript R/03n_tx_year1_probe.R --probe          # LIVE, READ-ONLY: has a roster appeared?
Rscript R/02b_provenance_sweep.R --noa-dates    # the §6.2 NOA anchor, from the committed archive
Rscript R/02b_provenance_sweep.R --build        # the 50-state sweep, offline
Rscript R/02b_provenance_sweep.R --validate     # sweep assertions incl. the false-positive check
Rscript R/02b_provenance_sweep.R --report       # 73 rows in 6 states, and the date-test bound
Rscript R/03o_ks_year1_awardees.R --fetch       # KS: archive 4 KDHE sources + SHA-256
Rscript R/03o_ks_year1_awardees.R --validate    # KS assertions + the positive control, offline
Rscript R/03o_ks_year1_awardees.R --build       # writes KS csv + KS_year1_awardees.xlsx
Rscript R/03o_ks_year1_awardees.R --report      # the three pools, and why the figure is a floor
Rscript R/03p_md_year1_awardees.R --fetch       # MD: archive 5 MDH sources + SHA-256
Rscript R/03p_md_year1_awardees.R --validate    # MD assertions + the positive control, offline
Rscript R/03p_md_year1_awardees.R --build       # writes MD csv + MD_year1_awardees.xlsx
Rscript R/03p_md_year1_awardees.R --report      # the two pools, and where the figure is soft
Rscript R/03q_state_completeness_recheck.R --fetch    # 24 pages across 7 states + SHA-256
Rscript R/03q_state_completeness_recheck.R --validate # the two positives and five negatives
Rscript R/03q_state_completeness_recheck.R --build    # writes state_completeness_recheck.csv
Rscript R/03q_state_completeness_recheck.R --report   # the table, with each control stated
Rscript R/03r_ne_year1_awardees.R --fetch        # NE: archive 6 sources + SHA-256
Rscript R/03r_ne_year1_awardees.R --validate    # NE assertions + both controls, offline
Rscript R/03r_ne_year1_awardees.R --build       # writes NE csv + disposition + NE xlsx
Rscript R/03r_ne_year1_awardees.R --report      # the 3 pools, and where the figure is soft
Rscript R/03s_in_year1_awardees.R --fetch        # IN: archive 19 sources + SHA-256
Rscript R/03s_in_year1_awardees.R --validate    # IN assertions + both controls, offline
Rscript R/03s_in_year1_awardees.R --build       # writes IN csv + disposition + IN xlsx
Rscript R/03s_in_year1_awardees.R --report      # 7 vendors, 0 hospitals, and the 30 non-RHTP
Rscript R/03t_ok_year1_awardees.R --fetch        # OK: archive 8 sources + SHA-256
Rscript R/03t_ok_year1_awardees.R --validate    # OK assertions + both controls, offline
Rscript R/03t_ok_year1_awardees.R --build       # writes OK csv + disposition + OK xlsx
Rscript R/03t_ok_year1_awardees.R --report      # the 2 pools, and the §7A comparison
Rscript R/03u_nv_year1_awardees.R --fetch        # NV: archive 11 sources + SHA-256
Rscript R/03u_nv_year1_awardees.R --validate    # NV assertions + both controls, offline
Rscript R/03u_nv_year1_awardees.R --build       # writes NV csv + disposition + NV xlsx
Rscript R/03u_nv_year1_awardees.R --report      # 72 named awards, NO amounts, and the GME negative
Rscript R/03v_mi_year1_awardees.R --fetch        # MI: archive 7 sources + SHA-256 (see §3 on the UA)
Rscript R/03v_mi_year1_awardees.R --validate    # MI assertions + both controls, offline
Rscript R/03v_mi_year1_awardees.R --build       # writes MI csv + disposition + MI xlsx
Rscript R/03v_mi_year1_awardees.R --report      # 139 awards, ONE named hospital, and RCJ's deflation
Rscript R/03w_mo_year1_awardees.R --fetch        # MO: archive 8 sources + SHA-256
Rscript R/03w_mo_year1_awardees.R --validate    # MO assertions + all four controls, offline
Rscript R/03w_mo_year1_awardees.R --build       # writes MO csv + hub anchors + disposition + xlsx
Rscript R/03w_mo_year1_awardees.R --probe       # LIVE: has the ToRCH Care IFB awarded yet?
Rscript R/03w_mo_year1_awardees.R --report      # 2 awards, $0 to hospitals, and the 27 NON-awards
Rscript R/03x_nh_year1_awardees.R --fetch       # NH: archive FHC + CDFA + SHA-256
Rscript R/03x_nh_year1_awardees.R --validate    # NH assertions + the positive control, offline
Rscript R/03x_nh_year1_awardees.R --build       # writes NH csv + status + disposition
Rscript R/03x_nh_year1_awardees.R --report      # 2 administrators, 0 subrecipients, 0 hospitals
Rscript R/03y_wi_year1_probe.R --probe          # LIVE: has Wisconsin announced its September awards?
Rscript R/03y_wi_year1_probe.R --fetch          # WI: archive 9 sources incl. BOTH controls
Rscript R/03y_wi_year1_probe.R --validate       # WI assertions + the tripwires, offline
Rscript R/03y_wi_year1_probe.R --build          # writes the two WI status CSVs (NO award file)
Rscript R/03y_wi_year1_probe.R --report         # the negative, and the $61M eligible class
Rscript R/03z_ia_year1_awardees.R --fetch      # IA: archive the 11 notices + 3 sources
Rscript R/03z_ia_year1_awardees.R --validate   # IA assertions + both controls, offline
Rscript R/03z_ia_year1_awardees.R --build      # writes IA csv + footers + disposition
Rscript R/03z_ia_year1_awardees.R --report     # 264 actions, 152 named hospitals, $0
Rscript R/03aa_me_year1_awardees.R --fetch    # ME: archive 13 sources + SHA-256
Rscript R/03aa_me_year1_awardees.R --validate # ME assertions + both controls, offline
Rscript R/03aa_me_year1_awardees.R --build    # writes ME csv + cohort + status + dispo + xlsx
Rscript R/03aa_me_year1_awardees.R --probe    # LIVE: has Maine awarded yet?
Rscript R/03aa_me_year1_awardees.R --report   # 1 award, 11 INVITED hospitals, $0
Rscript R/03ab_ca_year1_probe.R --fetch       # CA: archive 10 sources + SHA-256
Rscript R/03ab_ca_year1_probe.R --validate    # CA assertions + BOTH controls, offline
Rscript R/03ab_ca_year1_probe.R --build       # writes the two CA status CSVs (NO award file)
Rscript R/03ab_ca_year1_probe.R --probe       # LIVE: has California awarded yet?
Rscript R/03ab_ca_year1_probe.R --report      # the negative, and the $111.3M due NOW
Rscript R/03ac_ct_year1_probe.R --fetch      # CT: archive 10 sources + SHA-256
Rscript R/03ac_ct_year1_probe.R --validate   # CT assertions + BOTH controls, offline
Rscript R/03ac_ct_year1_probe.R --build      # writes the two CT status CSVs (NO award file)
Rscript R/03ac_ct_year1_probe.R --probe      # LIVE: has Connecticut awarded yet?
Rscript R/03ac_ct_year1_probe.R --report     # the negative, and the award date that PASSED
Rscript R/03ad_nm_year1_probe.R --fetch      # NM: archive 9 sources + SHA-256
Rscript R/03ad_nm_year1_probe.R --validate   # NM assertions + BOTH controls, offline
Rscript R/03ad_nm_year1_probe.R --build      # writes the two NM status CSVs (NO award file)
Rscript R/03ad_nm_year1_probe.R --probe      # LIVE: has New Mexico awarded yet?
Rscript R/03ad_nm_year1_probe.R --report     # the negative, and the three stacked defects
Rscript R/03ae_la_year1_probe.R --fetch      # LA: archive 8 sources + SHA-256
Rscript R/03ae_la_year1_probe.R --validate   # LA assertions + both controls, offline
Rscript R/03ae_la_year1_probe.R --build      # writes the two LA status CSVs (NO award file)
Rscript R/03ae_la_year1_probe.R --probe      # LIVE: has Louisiana awarded yet?
Rscript R/03ae_la_year1_probe.R --report     # the negative, and SEVEN windows that closed
Rscript R/03af_ky_year1_probe.R --fetch      # KY: archive 7 sources + SHA-256
Rscript R/03af_ky_year1_probe.R --validate   # KY assertions + the control, offline
Rscript R/03af_ky_year1_probe.R --build      # writes the two KY status CSVs (NO award file)
Rscript R/03af_ky_year1_probe.R --probe      # LIVE: has Kentucky awarded yet?
Rscript R/03af_ky_year1_probe.R --report     # the negative, and TWO dates that PASSED
Rscript R/03ag_ny_year1_probe.R --fetch      # NY: archive 5 sources + SHA-256
Rscript R/03ag_ny_year1_probe.R --validate   # NY assertions + BOTH controls, offline
Rscript R/03ag_ny_year1_probe.R --build      # writes the two NY status CSVs (NO award file)
Rscript R/03ag_ny_year1_probe.R --probe      # LIVE: has New York named a grantee?
Rscript R/03ag_ny_year1_probe.R --report     # the negative, and a CONTRACT START that passed
Rscript R/03ah_nc_year1_sources.R --fetch    # NC: archive 7 sources + SHA-256
Rscript R/03ah_nc_year1_sources.R --probe    # LIVE: has the SECOND TIER awarded?
Rscript R/03ah_nc_year1_sources.R --validate # NC assertions incl. the pairing guard
Rscript R/03ah_nc_year1_sources.R --build    # writes nc status + the 44 award rows
Rscript R/03ah_nc_year1_sources.R --report   # 44 named, $0, and NO bucket at all
Rscript R/03ai_ar_year1_awardees.R --fetch    # AR: archive 14 sources + SHA-256 (10s throttle)
Rscript R/03ai_ar_year1_awardees.R --validate # AR assertions + BOTH controls, offline
Rscript R/03ai_ar_year1_awardees.R --build    # writes awardees + projects + status + dispo
Rscript R/03ai_ar_year1_awardees.R --probe    # LIVE: has RISE AR or HEART awarded?
Rscript R/03ai_ar_year1_awardees.R --report   # 31 orgs / 37 actions / 50 projects, $149.2M
Rscript R/03aj_wy_year1_awardees.R --fetch     # WY: verify the 9 archived files vs MANIFEST
Rscript R/03aj_wy_year1_awardees.R --validate  # WY assertions incl. the run-model guard
Rscript R/03aj_wy_year1_awardees.R --build     # writes awardees + status + disposition
Rscript R/03aj_wy_year1_awardees.R --probe     # LIVE: has Wyoming executed anything?
Rscript R/03aj_wy_year1_awardees.R --report    # 75 actions, 31 named hospitals, $72.7M
Rscript R/03ak_ms_year1_awardees.R --fetch     # MS: archive 6 sources incl. THE ROSTER
Rscript R/03ak_ms_year1_awardees.R --validate  # MS assertions + the two odd-shape rows
Rscript R/03ak_ms_year1_awardees.R --build     # writes ms csv + status + disposition
Rscript R/03ak_ms_year1_awardees.R --probe     # LIVE: has the NEXT tranche announced?
Rscript R/03ak_ms_year1_awardees.R --report    # 167 awards, 68 named hospitals, $47.5M
Rscript R/03ae_la_year1_probe.R --probe      # LIVE: have the September windows closed?
Rscript R/03ad_nm_year1_probe.R --probe      # LIVE: has a per-hub amount appeared?
cat logs/probe_results.csv                   # every probe's verdict, COMMITTED
Rscript R/03al_de_year1_awardees.R --fetch     # DE: archive 3 sources + SHA-256
Rscript R/03al_de_year1_awardees.R --validate  # DE assertions incl. the classifier exposure
Rscript R/03al_de_year1_awardees.R --build     # writes de csv + status + dispo + DE xlsx
Rscript R/03al_de_year1_awardees.R --probe     # LIVE: has Delaware priced anybody?
Rscript R/03al_de_year1_awardees.R --report    # 4 actions, 3 orgs, $0, 4 hospital ROWS
Rscript R/03am_id_year1_awardees.R --fetch     # ID: archive 2 sources + SHA-256
Rscript R/03am_id_year1_awardees.R --validate  # ID assertions, offline
Rscript R/03am_id_year1_awardees.R --build     # writes id csv + status + disposition
Rscript R/03am_id_year1_awardees.R --probe     # LIVE: a second "Awardee:" line?
Rscript R/03am_id_year1_awardees.R --report    # one named awardee, no amount, no bucket
Rscript R/03an_oh_year1_awardees.R --fetch     # OH: archive 3 sources incl. the TIER CONTRAST
Rscript R/03an_oh_year1_awardees.R --validate  # OH assertions incl. the footer limit
Rscript R/03an_oh_year1_awardees.R --build     # writes oh csv + status + disposition
Rscript R/03an_oh_year1_awardees.R --probe     # LIVE: a second Ohio award?
Rscript R/03an_oh_year1_awardees.R --report    # $10M to a UNIVERSITY; the SUBAWARD footer
Rscript R/03ao_sc_year1_awardees.R --fetch     # SC: archive the ROSTER + 4 more
Rscript R/03ao_sc_year1_awardees.R --validate  # SC assertions incl. the spacing PROOF
Rscript R/03ao_sc_year1_awardees.R --build     # writes sc csv + status + disposition
Rscript R/03ao_sc_year1_awardees.R --probe     # LIVE: has the Tech Catalyst Fund awarded?
Rscript R/03ao_sc_year1_awardees.R --report    # 228 awards, 55 named hospitals, $56.6M
Rscript R/03ap_verification_queue_2.R --report  # what the returned queue moves, BEFORE writing
Rscript R/03ap_verification_queue_2.R --apply   # answers + plan + the 22 state files
Rscript R/03ap_verification_queue_2.R --totals  # the three buckets
Rscript R/03aq_unstated_form_typing.R --report    # MS+SC typing, BEFORE writing
Rscript R/03aq_unstated_form_typing.R --apply     # changes CSV + the two files
Rscript R/03aq_unstated_form_typing.R --benchmark # SC against the agency figure
Rscript R/03ar_rural_cut_report.R --build        # the rural cut, from committed files only
Rscript R/03ar_rural_cut_report.R --report       # 151 rows / $158.0M rural; 692 rows the gap
Rscript R/02c_state_attribution_sweep.R --build  # §0.1 mode 6 — the wrong-state sweep
Rscript R/02c_state_attribution_sweep.R --report # 10 misfiled in 5 states, NONE Tier 3
```

Stage 2 is idempotent against the same pull. Stage 3's `--allotments` reuses the
committed archive unless `--force` is passed. Stage 2.5 picks up any
`<ST>_initiative_table.xlsx` at the repo root or under
`data/reference/initiative_tables/`, so a new state's extraction needs no code
change. Stage 3c renders from `data/reference/abstract_named_organizations.csv`
— edit the CSV, never the workbook.
