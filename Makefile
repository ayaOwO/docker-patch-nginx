BUILD_IMAGE ?= nginx:1.25-bookworm-echo
BASELINE_IMAGE ?= nginx:1.25-bookworm
VEX ?= nginx.vex.json

.PHONY: package image reports test

package:
	docker build --file build/Dockerfile --target package --output type=local,dest=dist .

image: package
	docker build -t "$(BUILD_IMAGE)" --file Containerfile .

reports:
	trivy image "$(BASELINE_IMAGE)" > baseline-trivy.txt
	grype "$(BASELINE_IMAGE)" > baseline-grype.txt
	$(MAKE) image
	trivy image --vex "$(VEX)" "$(BUILD_IMAGE)" > after-trivy.txt
	grype --vex "$(VEX)" "$(BUILD_IMAGE)" > after-grype.txt

test:
	BUILD_IMAGE="$(BUILD_IMAGE)" BASELINE_IMAGE="$(BASELINE_IMAGE)" docker compose -f test/compose.yaml up --build --exit-code-from pytest
