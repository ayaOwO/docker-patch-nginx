# nginx docker image patching

I will fix these CVEs they are the most severe CVEs and are listed as `KEV` by grype,

meaning they were executed in the real word and pose the most danger

The first one was fixed in a **version bump**

The second one is in nginx and will need a **backport patch**

| NAME         | INSTALLED         | FIXED IN              | TYPE | VULNERABILITY  | SEVERITY | EPSS          | RISK       |
|--------------|-------------------|-----------------------|------|----------------|----------|---------------|------------|
| libfreetype6 | 2.12.1+dfsg-5     | 2.12.1+dfsg-5+deb12u4 | deb  | CVE-2025-27363 | High     | 27.8% (98th)  | 81.9 (kev) |
| nginx        | 1.25.5-1~bookworm |                       | deb  | CVE-2023-44487 | High     | 100.0% (99th) | 78.8 (kev) |

Rebuilding the image with the latest package solved the `libfreetype6-CVE-2025-27363` CVE and many others

| CVE ID         | Severity | Component      | Fix method                                                                                                                                                                                                     | Evidence                                                                                                                                                    |
|----------------|----------|----------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
| CVE-2025-27363 | High     | `libfreetype6` | **Remove**: the original image contains `2.12.1+dfsg-5`; FreeType is absent from the rebuilt runtime. The baseline lists `2.12.1+dfsg-5+deb12u4` as a fixed version, but this final image does not install it. | [Baseline finding](baseline-grype.txt), [runtime build](Containerfile), [after report](after-grype.txt)                                                     |
| CVE-2023-44487 | High     | NGINX HTTP/2   | **Backport**: apply upstream commit `6ceef192e7af1c507826ac38a2d43f08bf265fb9`, adapted to 1.25.0. It limits new streams per event-loop iteration and closes connections after excessive refused streams.      | [Source patch](build/patches/CVE-2023-44487.patch), [patch application](build/Dockerfile), [VEX statement](nginx.vex.json), [after report](after-grype.txt) |

For the nginx backport I saved the source changes (using `git format-patch)
and applied that patch during the build with `git apply`

I create a **vex document** for the **backport patch CVE** and used it in the after reports

## Build instructions

From the repository root, with Docker/BuildKit and GNU Make installed:

```sh
make package  # Export dist/nginx.deb.
make image    # Build the package and nginx:1.25-bookworm-echo.
make reports  # Regenerate baseline and after reports; requires Trivy and Grype.
```

The package targets `amd64`. Report generation uses `nginx:1.25-bookworm` as
its baseline and applies `nginx.vex.json` to the rebuilt image's scans.

```sh
docker run --rm -p 8080:80 nginx:1.25-bookworm-echo
```

## Image size: original vs. new

Measured from local `amd64` images using `docker image inspect`:
Since I didn't make any substantial effort to reduce the image size.
I suspect the size difference is because of missing features in the nginx build

| Image                           | Size in bytes |   Size in MiB |
|---------------------------------|--------------:|--------------:|
| Original: `nginx:1.25-bookworm` |   273,738,794 |        261.06 |
| New: `nginx:1.25-bookworm-echo` |   181,076,466 |        172.69 |
| Reduction                       |    92,662,328 | 88.37 (33.9%) |

## FreeType verification

Direct inspection confirmed that the original image has `libfreetype6`
`2.12.1+dfsg-5` installed, including `libfreetype.so.6` and
`libfreetype.so.6.18.3`. In the rebuilt image, `dpkg-query -s libfreetype6`
reports that the package is not installed, and a filename search under
`/usr`, `/lib`, and `/opt` finds no FreeType files. Thus the final image
addresses this CVE by omitting the dependency, rather than installing its
fixed version. This clarifies the version-bump description above.

## Scan results

| Findings  | [Trivy baseline](baseline-trivy.txt) | [Trivy after](after-trivy.txt) | [Grype baseline](baseline-grype.txt) | [Grype after](after-grype.txt) |
|-----------|-------------------------------------:|-------------------------------:|-------------------------------------:|-------------------------------:|
| Critical  |                                   20 |                              4 |                                   49 |                              9 |
| High      |                                  183 |                             54 |                                  263 |                             62 |
| Total     |                                  802 |                            243 |                                  767 |                            237 |
| Reduction |                                      |                          69.7% |                                      |                          69.1% |

~Counts are scanner findings, including the same CVE against multiple packages, rather than unique CVEs. ~

- `build/Dockerfile` builds nginx 1.25.0 and applies `build/patches/CVE-2023-44487.patch`,
  adapted from [upstream commit
  `6ceef19`](https://github.com/nginx/nginx/commit/6ceef192e7af1c507826ac38a2d43f08bf265fb9). It builds `nginx.deb`.
  Package metadata is in `build/control`.
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

## Residual risk assessment

The saved after reports still contain 4 critical and 54 high Trivy findings,
and 9 critical and 62 high Grype findings. These vary from "fixed" to "will not fix"
While I have updated to the latest versions with apt some packages still have upstream fixes

For "fixed" I'll update.

For "will not fix" I'll backport patches.

For "fix deffered" packages I'll remove the packages

## Surprises and what I would do differently

- How many CVEs were fixed by "just" updating to newer version. Same base, same app, different dependencies
- How much smaller my image was from the original
- Run the maintaned [nginx test suite](https://github.com/nginx/nginx-tests) to verify compatibility instead of my own
  tests

I used ChatGPT sol 6.1 to help me with research on Debian packaging and writing both the Makefile and this README
