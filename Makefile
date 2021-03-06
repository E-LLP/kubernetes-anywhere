
SHELL=/bin/bash
.SHELLFLAGS="-O" "extglob" "-o" "errexit" "-o" "pipefail" "-o" "nounset" "-c"

.PHONY: config echo-config


# sorry windows and non amd64
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	OS = linux
endif
ifeq ($(UNAME_S),Darwin)
	OS = darwin
endif

CONF_TOOL_VERSION = 4.6
KCONFIG_FILES = $(shell find . -name 'Kconfig')

default:
	$(MAKE) config

.tmp/conf:
	mkdir -p .tmp; curl -sSL --fail -o "$@" \
		"https://storage.googleapis.com/public-mikedanese-k8s/kconfig/$(CONF_TOOL_VERSION)/$(OS)/conf"; \
	chmod +x "$@"

.tmp/mconf:
	mkdir -p .tmp; curl -sSL --fail -o "$@" \
		"https://storage.googleapis.com/public-mikedanese-k8s/kconfig/$(CONF_TOOL_VERSION)/$(OS)/mconf"; \
	chmod +x "$@"

config: .tmp/conf
	CONFIG_="" .tmp/conf Kconfig

menuconfig: .tmp/mconf
	CONFIG_="" .tmp/mconf Kconfig

.config: .tmp/conf $(KCONFIG_FILES)
	$(MAKE) config

.config.json: .config
	util/config_to_json $< > $@

echo-config: .config.json
	cat $<

deploy destroy: .config.json
	$(MAKE) do WHAT=$@

do:
	( cd "phase1/$$(jq -r '.phase1.cloud_provider' .config.json)"; ./do $(WHAT) )

clean:
	rm -rf .tmp
	rm -rf phase3/.tmp
	rm -rf phase1/gce/out

fmt:
	for f in $$(find . -name '*.jsonnet'); do jsonnet fmt -i -n 2 $${f}; done;
	# for f in $$(find . -name '*.json'); do jq -S '.' "$${f}" | ex -sc "wq!$${f}" /dev/stdin; done;
