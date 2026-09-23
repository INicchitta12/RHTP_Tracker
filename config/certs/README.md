# config/certs

`digicert_global_g2_tls_rsa_sha256_2020_ca1.pem` -- the DigiCert Global G2 TLS
RSA SHA256 2020 CA1 **intermediate**, fetched 2026-09-23 from the AIA URL in the
leaf certificate of `ruralhealthtransformationva.virginia.gov`
(http://cacerts.digicert.com/DigiCertGlobalG2TLSRSASHA2562020CA1-1.crt),
converted DER -> PEM.

WHY IT IS HERE. Virginia's RHT site serves its leaf certificate WITHOUT the
intermediate, so libcurl fails with "unable to get local issuer certificate".
Browsers repair that by chasing the AIA URL; this repository does the same,
once, by hand. Verification is NEVER switched off: `R/03bb_va_year1_probe.R`
appends this one intermediate to the normal CA bundle, and the chain still has
to end at DigiCert Global Root G2 in the system store.

    subject = DigiCert Global G2 TLS RSA SHA256 2020 CA1
    issuer  = DigiCert Global Root G2
    sha256  = C8:02:5F:9F:C6:5F:DF:C9:5B:3C:A8:CC:78:67:B9:A5:87:B5:27:79:73:95:79:17:46:3F:C8:13:D0:B6:25:A9
    expires = 2031-03-29

`openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt <file>` -> OK.
