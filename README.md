I will fix these,
They are the most severe CVEs and are listed as `KEV` meaning they were executed in the real word
and pose the most danger
The first one was fixed in a **version bump**
The second one is in nginx and will need a **backport patch**

| NAME         | INSTALLED         | FIXED IN              | TYPE | VULNERABILITY  | SEVERITY | EPSS          | RISK       |
|--------------|-------------------|-----------------------|------|----------------|----------|---------------|------------|
| libfreetype6 | 2.12.1+dfsg-5     | 2.12.1+dfsg-5+deb12u4 | deb  | CVE-2025-27363 | High     | 27.8% (98th)  | 81.9 (kev) |
| nginx        | 1.25.5-1~bookworm |                       | deb  | CVE-2023-44487 | High     | 100.0% (99th) | 78.8 (kev) |

Rebuilding the image with the latest package solved the `libfreetype6` CVE and many others
I used chatgpt sol 6.1 to help me understand debian packaging

For the nginx backport patch I

## Scan results (2026-10-12)

Compared `echo-nginx:latest` (Debian 12.15) with the `nginx:1.25-bookworm` (Debian 12.5) baselines using Trivy and Grype with vulnerability databases from the same day.

| Findings | Trivy baseline | Trivy current | Grype baseline | Grype current |
| --- | ---: | ---: | ---: | ---: |
| Critical | 20 | 4 | 49 | 9 |
| High | 183 | 54 | 263 | 63 |
| Total | 802 | 244 | 767 | 238 |
| Reduction | | 69.6% | | 69.0% |

The reduction comes largely from fewer packages and a newer Debian base. FreeType's `CVE-2025-27363` is no longer reported because `libfreetype6` is absent from this image. nginx's `CVE-2023-44487` remains reported by both scanners, but this build does not enable HTTP/2, so applicability needs review. Both scanners still report critical `perl-base` findings, with `5.36.0-7+deb12u4` listed as the fixed version.

Counts represent package/vulnerability findings, not unique CVEs. Trivy's baseline summary reports 802 findings, while its table contains 801 recoverable entries. These scans do not establish complete coverage of PCRE2 and zlib embedded in the custom nginx binary.

See the [full overview](cve-overview.md), [Trivy diff](diff-trivy.json), and [Grype diff](diff-grype.json).
