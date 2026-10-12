BUILD_IMAGE ?= nginx:1.25-bookworm-echo
BASELINE_IMAGE ?= nginx:1.25-bookworm
VEX ?= nginx.vex.json

.PHONY: image reports

image:
	docker build -t "$(BUILD_IMAGE)" --file build/Dockerfile build

reports:
	trivy image "$(BASELINE_IMAGE)" > baseline-trivy.txt
	grype "$(BASELINE_IMAGE)" > baseline-grype.txt
	$(MAKE) image
	trivy image --vex "$(VEX)" "$(BUILD_IMAGE)" > after-trivy.txt
	grype --vex "$(VEX)" "$(BUILD_IMAGE)" > after-grype.txt
