I will fix these CVEs they are the most severe CVEs and are listed as `KEV` by grype,

meaning they were executed in the real word and pose the most danger

The first one was fixed in a **version bump**

The second one is in nginx and will need a **backport patch**

| NAME         | INSTALLED         | FIXED IN              | TYPE | VULNERABILITY  | SEVERITY | EPSS          | RISK       |
|--------------|-------------------|-----------------------|------|----------------|----------|---------------|------------|
| libfreetype6 | 2.12.1+dfsg-5     | 2.12.1+dfsg-5+deb12u4 | deb  | CVE-2025-27363 | High     | 27.8% (98th)  | 81.9 (kev) |
| nginx        | 1.25.5-1~bookworm |                       | deb  | CVE-2023-44487 | High     | 100.0% (99th) | 78.8 (kev) |

Rebuilding the image with the latest package solved the `libfreetype6` CVE and many others


For the nginx backport I saved the source changes (using `git format-patch)
and applied that patch during the build with `git apply`

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

- `build/Dockerfile` builds nginx 1.25.0 and applies `build/patches/CVE-2023-44487.patch`,
  adapted from [upstream commit
  `6ceef19`](https://github.com/nginx/nginx/commit/6ceef192e7af1c507826ac38a2d43f08bf265fb9). It builds `nginx.deb`. Package metadata is in `build/control`.
  The Docker build context is the repository root. Dependency version bumps remain in the build files;
  VEX statements remain in `nginx.vex.json`.
- `make package` builds and exports `dist/nginx.deb` through `build/Dockerfile`.
- `make image` builds the package, then uses the root `Containerfile` to install it into a Debian runtime image
  and check the nginx configuration. The image is tagged `nginx:1.25-bookworm-echo` by default.
- `make reports` regenerates the baseline reports, builds the image, and generates the after reports with
  `nginx.vex.json` applied.

- `make test` runs the pytest checks in a test container based on `BUILD_IMAGE` (build it first with `make image`).
  Tests check the package version, nginx configuration, HTTP/2 module, backport diagnostic strings, and HTTP/1.1
  and HTTP/2 response status and body. These checks exercise the custom image only.
## Surprises and what I would do differently
- How many CVEs were fixed by "just" updating to newer version. Same base, same app, different dependencies
- How much smaller my image was from the original
- Run the maintaned [nginx test suite](https://github.com/nginx/nginx-tests) to verify compatibility instead of my own tests

I used ChatGPT sol 6.1 to help me with research on Debian packaging and writing both the Makefile and this README
