#!/bin/bash
# Cloud environment setup script — build spec §3.3.
#
# Paste this into the Claude Code environment's setup-script field. It runs
# ONCE per environment; the filesystem is then snapshotted and reused, so later
# sessions start with R already installed.
#
# It must exit zero and finish within roughly five minutes or the cache will
# not build — which is why this uses precompiled binaries rather than compiling
# from source.
#
# NETWORK REQUIREMENT (spec §3.2): the environment must use Custom access with
# "also include default list of common package managers" checked, plus:
#   www.ruralcarejourney.com
#   ruralcarejourney.com
#   rhtp.amemobile.net          <- confirmed live alternate API host
#   packagemanager.posit.co
#   cloud.r-project.org
#   archive.ubuntu.com          <- REQUIRED for apt; blocked as of 2026-08-27
#   security.ubuntu.com         <- REQUIRED for apt; blocked as of 2026-08-27
#
# Without the two Ubuntu archive hosts, apt-get returns 403 at the egress proxy
# and R is never installed. This was the observed failure in Session 1.

apt-get update

apt-get install -y --no-install-recommends \
  r-base-dev libcurl4-openssl-dev libssl-dev libxml2-dev || true

cat > /usr/lib/R/etc/Rprofile.site << 'RPROFILE'
options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/latest"))
options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(),
  paste(getRversion(), R.version$platform, R.version$arch, R.version$os)))
RPROFILE

# The HTTPUserAgent option is what makes the Posit package manager serve Linux
# binaries instead of source tarballs. Without it the install compiles from
# scratch and will exceed the time limit.
Rscript -e 'install.packages(c("tidyverse","httr2","jsonlite","openxlsx",
  "janitor","digest","here","yaml","fuzzyjoin","assertr","testthat"))' || true

# If this script times out, trim the list to the core set below and install the
# rest mid-session as needed:
#   tidyverse httr2 jsonlite openxlsx digest here yaml

exit 0
