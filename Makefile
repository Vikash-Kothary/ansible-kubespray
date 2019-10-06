#!/usr/bin/make
#@ Kubespray

.DEFAULT_GOAL := help-kubespray
SHELL := /bin/bash

CONTEXT_KUBESPRAY := $(or $(CONTEXT_KUBESPRAY),${PWD})
CLUSTER_NAME := $(or $(CONTEXT_KUBESPRAY),local)

-include ${CONTEXT_KUBESPRAY}/.env
export

#@ Commands:
%: %-kubespray
	@true

#- Check if required parameter has been set
check-%:
	@test -n "${$(*)}"

.PHONY: help-kubespray
#- Show all commands.
help-kubespray:
	@cd ${CONTEXT_KUBESPRAY} && \
	awk '{ if (match(lastLine, /^#- (.*)/)) printf "- %s: %s\n", substr($$1, 0, index($$1, ":")-1), substr(lastLine, RSTART + 3, RLENGTH); else if (match($$0, /^[a-zA-Z\-\_0-9]+:/)) printf "- %s:\n", substr($$1, 0, index($$1, ":")-1); else if (match($$0, /^#@ (.*)/)) printf "%s\n", substr($$0, RSTART + 3, RLENGTH); } { lastLine = $$0 }' $(MAKEFILE_LIST)

.PHONY: init-kubespray
init-kubespray:
	@cd ${CONTEXT_KUBESPRAY} && \
	if [ ! -d .venv ]; then \
		python3 -m venv .venv; \
		.venv/bin/pip3 install --upgrade pip; \
		.venv/bin/pip3 install -r requirements.txt; \
	fi

.PHONY: new-kubespray
new-kubespray: check-CLUSTER_NAME check-CLUSTER_IPS init-kubespray
	@cd ${CONTEXT_KUBESPRAY} && \
	. .venv/bin/activate && \
	cp -rfp inventory/sample inventory/${CLUSTER_NAME} && \
	CONFIG_FILE=inventory/${CLUSTER_NAME}/hosts.yml python3 contrib/inventory_builder/inventory.py ${CLUSTER_IPS[@]}

.PHONY: run-kubespray
run-kubespray: check-CLUSTER_NAME init-kubespray
	@cd ${CONTEXT_KUBESPRAY} && \
	. .venv/bin/activate && \
	ansible-playbook -i inventory/${CLUSTER_NAME}/hosts.yml tasks/cluster.yml

open-kubespray: check-CLUSTER_HOST check-CLUSTER_PORT
	@open http://${CLUSTER_HOST}:${CLUSTER_PORT}/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/

.PHONY: mitogen-kubespray
mitogen-kubespray: init-kubespray
	@cd ${CONTEXT_KUBESPRAY} && \
	. .venv/bin/activate && \
	ansible-playbook -c local tasks/mitogen.yaml -vv

.PHONY: clean-kubespray
clean-kubespray:
	@cd ${CONTEXT_KUBESPRAY} && \
	rm -rf dist/ && \
	rm *.retry
