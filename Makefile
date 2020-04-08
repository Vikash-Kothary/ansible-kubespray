#/bin/make

SHELL ?= /bin/bash
KUBESPRAY_NAME ?= "Ansible Kubespray"
KUBESPRAY_VERSION ?= "v0.1.0"
KUBESPRAY_DESCRIPTION ?= "Production Ready Kubernetes Cluster."
KUBESPRAY_ROOT ?= ${PWD}
CLUSTER ?= local

-include .env
export

%: %-kubespray
	@true

.PHONY: check-<ENV> #: Check if required parameter has been set
check-%:
	@test -n "${$(*)}"

.DEFAULT_GOAL := help-kubespray
.PHONY: help-kubespray #: List all commands
help-kubespray:
	@cd ${KUBESPRAY_ROOT} && awk 'BEGIN {FS = " ?#?: "; print ""${KUBESPRAY_NAME}" "${KUBESPRAY_VERSION}"\n"${KUBESPRAY_DESCRIPTION}"\n\nUsage: make \033[36m<command>\033[0m\n\nCommands:"} /^.PHONY: ?[a-zA-Z_-]/ { printf "  \033[36m%-10s\033[0m %s\n", $$2, $$3 }' $(MAKEFILE_LIST)

.PHONY: init-kubespray
init-kubespray:
	@cd ${KUBESPRAY_ROOT} && \
	if [ ! -d .venv ]; then \
		python3 -m venv .venv; \
		.venv/bin/pip3 install --upgrade pip; \
		.venv/bin/pip3 install -r requirements.txt; \
	fi

.PHONY: new-kubespray
new-kubespray: check-CLUSTER init-kubespray
	@cd ${KUBESPRAY_ROOT} && \
	. .venv/bin/activate && \
	cp -rfp inventory/sample inventory/${CLUSTER} && \
	CONFIG_FILE=inventory/${CLUSTER}/hosts.yml python3 contrib/inventory_builder/inventory.py 127.0.0.1

.PHONY: run-kubespray
run-kubespray: check-CLUSTER init-kubespray
	@cd ${KUBESPRAY_ROOT} && \
	. .venv/bin/activate && \
	ansible-playbook -i `find inventory/${CLUSTER} -type f -name *hosts*` tasks/cluster.yml

.PHONY: mitogen-kubespray
mitogen-kubespray: check-CLUSTER init-kubespray
	@cd ${KUBESPRAY_ROOT} && \
	. .venv/bin/activate && \
	ansible-playbook -i `find inventory/${CLUSTER} -type f -name *hosts*` tasks/mitogen.yaml

.PHONY: clean-kubespray
clean-kubespray:
	@cd ${KUBESPRAY_ROOT} && \
	rm -rf dist/ && \
	rm *.retry

.PHONY: open-kubespray
open-kubespray: check-CLUSTER_HOST check-CLUSTER_PORT
	@open http://${CLUSTER_HOST}:${CLUSTER_PORT}/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/

