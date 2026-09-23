RHTP Tracker -- scheduled probe for {STATE} ({NAME}); runner session {RUNNER}. Unattended; no human is watching this run. This session is bound to https://github.com/INicchitta12/RHTP_Tracker with push access to main, and exists only to run this Routine. Read CLAUDE.md sections 2.2 and 2.3 before acting.

YOUR ONLY PERMITTED WRITE TO THE REPOSITORY IS APPENDING TO logs/probe_results.csv ON main. Never edit code, any known/furniture list, any archive under data/evidence/, config/, or CLAUDE.md. Never run --fetch or --build. Never force-push. Never push any branch other than main.

1. Clean, current checkout. cd to the repository (the directory containing R/utils_config.R; if none exists, git clone https://github.com/INicchitta12/RHTP_Tracker && cd RHTP_Tracker). Then:
   git fetch origin main
   If git status --porcelain prints anything: if the ONLY entry is logs/probe_results.csv, run git checkout -- logs/probe_results.csv; otherwise report the files and STOP.
   git checkout -B main origin/main

2. Find THIS Routine's trigger id, which the log line must carry (the coverage check matches on it). This session is {RUNNER} and exists only for this Routine. Load the Claude_Code_Remote tools with ToolSearch if needed, call list_triggers (limit 50; if the result is saved to a file, read it with python or jq), and take the ENABLED Routine whose persistent_session_id is {RUNNER}. There must be exactly one; its id starts with trig_. If you cannot find exactly one, report what you found and STOP without running the probe.
   Then run the probe:
   RHTP_PROBE_ORIGIN=<that trig_ id> Rscript {SCRIPT} --probe
   A non-zero exit is a TRIPWIRE or ERROR. That is the signal this Routine exists to deliver, not a failure for you to fix.

3. PUBLISH THE VERDICT. THIS STEP IS THE DELIVERABLE: a verdict that does not reach main did not happen (CLAUDE.md 0.5).
   a. git status --porcelain must show exactly one line, for logs/probe_results.csv. If anything else changed, commit nothing and report exactly which files moved.
   b. git add logs/probe_results.csv && git commit -m "probe log: {STATE} $(date -u +%Y-%m-%dT%H:%MZ) (Routine <that trig_ id>)"
   c. GUARD, before every push attempt: git fetch origin main, then git diff --name-only origin/main HEAD must print exactly logs/probe_results.csv and nothing else. If it prints anything else, do NOT push; report it.
   d. git push origin HEAD:main. If rejected because main moved: git pull --rebase origin main (the file is append-only and carries merge=union), repeat the guard in (c), and push again. Retry up to 4 times, waiting 2, 4, 8 and 16 seconds.
   e. If the push still fails, say so plainly with the git error text. Never claim the verdict was recorded when it was not.

4. Run: Rscript R/probe_coverage.R --check. Report its output verbatim.

5. Reply in five lines or fewer: the verdict per page (from the lines you appended), any tripwire message verbatim, the pushed commit sha (or why the push failed), and the coverage-check result.
