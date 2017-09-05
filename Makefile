########################################################################
# Makefile, ABr
# Easily build local MiniShift
#
# Originally built for standalone or integrated K8s with OpenShift
# overlayed. OpenShift does not want to integrate with external K8s so
# this idea was put aside in favor of MiniShift.
#
# MiniShift is implemented as an "on-prem" OpenShift. Do not be
# confused by the specific build commands below.

########################################################################
# standard targets
.PHONY: all build clean rebuild init distclean check-env

all: check-env build

build: check-env minishift init

clean: check-env minishift-clean

rebuild: clean build

init: check-env minishift-init

distclean: check-env minishift-distclean
	$(info Clean environment...)
	@find . -name .localdata -type d -exec rm -fR {} \; 2>/dev/null || true

########################################################################
# MiniShift support (think of it as "on-prem OpenShift")
.PHONY: minishift minishift-clean minishift-start minishift-stop minishift-init minishift-distclean

minishift: check-env minishift-start

minishift-clean: check-env minishift-stop

minishift-start: check-env
	$(info Start MiniShift...)
	@./scripts/build-utils.sh minishift start

minishift-stop: check-env
	$(info Stop MiniShift...)
	@./scripts/build-utils.sh minishift stop || true

minishift-init: check-env
	$(info Init MiniShift...)
	@./scripts/build-utils.sh minishift-init

minishift-distclean: check-env minishift-stop
	$(info Clean MiniShift...)
	@./scripts/build-utils.sh minishift delete || true

check-env:
ifndef MAKE_WRAPPER_INVOCATION
	$(error Invoke through ./scripts/make-wrapper.sh)
endif

