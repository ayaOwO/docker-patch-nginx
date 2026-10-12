I will fix these CVEs they are the most severe CVEs and are listed as `KEV` by grype,

meaning they were executed in the real word and pose the most danger

The first one was fixed in a **version bump**

The second one is in nginx and will need a **backport patch**

| NAME         | INSTALLED         | FIXED IN              | TYPE | VULNERABILITY  | SEVERITY | EPSS          | RISK       |
|--------------|-------------------|-----------------------|------|----------------|----------|---------------|------------|
| libfreetype6 | 2.12.1+dfsg-5     | 2.12.1+dfsg-5+deb12u4 | deb  | CVE-2025-27363 | High     | 27.8% (98th)  | 81.9 (kev) |
| nginx        | 1.25.5-1~bookworm |                       | deb  | CVE-2023-44487 | High     | 100.0% (99th) | 78.8 (kev) |

Rebuilding the image with the latest package solved the `libfreetype6` CVE and many others


For the nginx backport patch I cherry-picked the commit which fixed the CVE

I create a **vex document** for the **backport patch CVE** and used it in the after reports


I used ChatGPT sol 6.1 to help me understand Debian packaging and write this readme and the makefile
## Scan results (2026-10-12)

| Findings  | [Trivy baseline](baseline-trivy.txt) | [Trivy after](after-trivy.txt) | [Grype baseline](baseline-grype.txt) | [Grype after](after-grype.txt) |
|-----------|-------------------------------------:|-------------------------------:|-------------------------------------:|-------------------------------:|
| Critical  |                                   20 |                              4 |                                   49 |                              9 |
| High      |                                  183 |                             54 |                                  263 |                             62 |
| Total     |                                  802 |                            243 |                                  767 |                            237 |
| Reduction |                                      |                          69.7% |                                      |                          69.1% |

## Build and reports

- `build/Dockerfile` builds nginx 1.25.0 and cherry-picks [upstream commit
  `6ceef19`](https://github.com/nginx/nginx/commit/6ceef192e7af1c507826ac38a2d43f08bf265fb9). It builds the `.deb`,
  installs it into a Debian runtime stage, and checks the nginx configuration. Package metadata is in `build/control`;
  the local patch file is not used by this build.
- `make image` builds the complete image through `build/Dockerfile`, tagged `nginx:1.25-bookworm-echo` by default. It
  does not use the root `Containerfile`.
- `make reports` regenerates the baseline reports, builds the image, and generates the after reports with
  `nginx.vex.json` applied.
