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

| CVE ID         | Severity | Component      | Fix method                                                                                                                                                                                                | Evidence                                                                                                                                                    |
|----------------|----------|----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
| CVE-2025-27363 | High     | `libfreetype6` | **Version bump**: updated from `2.12.1+dfsg-5` to the fixed version `2.12.1+dfsg-5+deb12u4`, which is installed in the rebuilt runtime.                                                                   | [Baseline finding](baseline-grype.txt), [runtime build](Containerfile), [after report](after-grype.txt)                                                     |
| CVE-2023-44487 | High     | NGINX HTTP/2   | **Backport**: apply upstream commit `6ceef192e7af1c507826ac38a2d43f08bf265fb9`, adapted to 1.25.0. It limits new streams per event-loop iteration and closes connections after excessive refused streams. | [Source patch](build/patches/CVE-2023-44487.patch), [patch application](build/Dockerfile), [VEX statement](nginx.vex.json), [after report](after-grype.txt) |

For the nginx backport I saved the source changes (using `git format-patch`)
and applied that patch during the build with `git apply`

I create a **vex document** for the **backport patch CVE** and used it in the after reports

## Build instructions

From the repository root, with Docker/BuildKit and GNU Make installed:

```sh
make package  # Export dist/nginx.deb.
make image    # Build the package and nginx:1.25-bookworm-echo.
make test     # Compare baseline and rebuilt NGINX responses; run after make image.
make reports  # Regenerate baseline and after reports; requires Trivy and Grype.
```

The package targets `amd64`. Report generation uses `nginx:1.25-bookworm` as
its baseline and applies `nginx.vex.json` to the rebuilt image's scans.

```sh
docker run --rm -p 8080:80 nginx:1.25-bookworm-echo
```

# Testing

The tests send requests to 2 nginx contaiters with the same config
The test verifies the config loaded properly and the nginx follows the requests as expected

### They only test:

* Forwarding requsets
* route redirect
* max body size in post request
* Handling of malformed requsets

### Among other features they do not test:

* Attempt to exploit the CVE which I backported
* load balance with multiple instances
* HTTPS TLS
* Query strings

## Image size: original vs. new

Measured from local `amd64` images using `docker image inspect`:
Since I didn't make any substantial effort to reduce the image size.
I suspect the size difference is because of missing features in the nginx build

| Image                           | Size in bytes |   Size in MiB |
|---------------------------------|--------------:|--------------:|
| Original: `nginx:1.25-bookworm` |   273,738,794 |        261.06 |
| New: `nginx:1.25-bookworm-echo` |   181,076,466 |        172.69 |
| Reduction                       |    92,662,328 | 88.37 (33.9%) |

## Scan results

| Findings  | [Trivy baseline](baseline-trivy.txt) | [Trivy after](after-trivy.txt) | [Grype baseline](baseline-grype.txt) | [Grype after](after-grype.txt) |
|-----------|-------------------------------------:|-------------------------------:|-------------------------------------:|-------------------------------:|
| Critical  |                                   20 |                              4 |                                   47 |                              7 |
| High      |                                  183 |                             54 |                                  260 |                             59 |
| Total     |                                  802 |                            248 |                                  767 |                            242 |
| Reduction |                                      |                          69.1% |                                      |                          68.4% |

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
- `make test` starts the baseline and rebuilt NGINX images with the same custom configuration, an echo backend,
  and a pytest container (build the rebuilt image first with `make image`). Six tests compare response status,
  body, and Content-Type, Content-Length, Location, and Allow headers for GET `/`, GET `/test`, a redirect and
  its destination, POST at and above the 64 KiB body limit, and a malformed HTTP request. Any mismatch exits non-zero.

## Residual risk assessment

The saved after reports still contain 4 critical and 54 high Trivy findings,
and 7 critical and 59 high Grype findings. These vary from "fixed" to "will not fix"
While I have updated to the latest versions with apt some packages still have upstream fixes

For "fixed" I'll update.

For "will not fix" I'll backport patches.

For "fix deffered" packages I'll remove the packages

## Surprises and what I would do differently

- At first I thought I had fixed a CVE by update, but a later check showed the dependency was actually removed instead.
  This happened because I didn't enable an nginx feature in the build.
- How many CVEs were fixed by updating to newer version. Same base, same app
- Run the maintaned [nginx test suite](https://github.com/nginx/nginx-tests) to verify compatibility instead of my own
  tests
- The image isn't one to one with the original, needs more research to verify the similarity of the two (compare to
  official dockerfile)

I used ChatGPT sol 6.1 to help me with research on Debian packaging and writing both the Makefile and this README
