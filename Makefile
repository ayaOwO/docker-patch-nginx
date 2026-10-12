IMAGE ?= nginx:1.25-bookworm-echo
BUILD_IMAGE ?= nginx:1.25-bookworm-echo
BASELINE_IMAGE ?= nginx:1.25-bookworm
VEX ?= nginx.vex.json

.PHONY: image test reports

image:
	docker build -t "$(BUILD_IMAGE)" --file build/Dockerfile build

reports:
	trivy image "$(BASELINE_IMAGE)" > baseline-trivy.txt
	grype "$(BASELINE_IMAGE)" > baseline-grype.txt
	$(MAKE) image
	trivy image --vex "$(VEX)" "$(IMAGE)" > after-trivy.txt
	grype --vex "$(VEX)" "$(IMAGE)" > after-grype.txt
