SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c

LAB_ENV ?= lab.env

.PHONY: help env-check schematic talos-config disks gpu-check flux-check unsuspend-inference unsuspend-agents

help:
	@echo "Targets:"
	@echo "  make env-check              # lab.env exists and has no REPLACE_ placeholders"
	@echo "  make schematic              # POST factory schematic, print ID + ISO URL"
	@echo "  make talos-config           # talos/generate.sh → talos/generated/"
	@echo "  make disks                  # talosctl get disks (needs CONTROL_PLANE_IP)"
	@echo "  make gpu-check              # modules, nvidia version, nvidia.com/gpu capacity"
	@echo "  make flux-check             # flux get kustomizations,all"
	@echo "  make unsuspend-inference    # flip clusters/lab/apps-inference.yaml"
	@echo "  make unsuspend-agents       # flip clusters/lab/apps-agents.yaml"

env-check:
	@test -f "$(LAB_ENV)" || { echo "missing $(LAB_ENV) — cp lab.env.example lab.env"; exit 1; }
	@if grep -E 'REPLACE_|REPLACE_ME' "$(LAB_ENV)" >/dev/null; then \
		echo "$(LAB_ENV) still contains REPLACE_ placeholders:"; \
		grep -nE 'REPLACE_|REPLACE_ME' "$(LAB_ENV)"; \
		exit 1; \
	fi
	@echo "$(LAB_ENV) looks filled in."

schematic:
	@./hack/factory-schematic.sh

talos-config: env-check
	@./talos/generate.sh

disks:
	@set -a; source "$(LAB_ENV)"; set +a; \
	talosctl -n "$$CONTROL_PLANE_IP" get disks -o yaml

gpu-check:
	@set -a; source "$(LAB_ENV)"; set +a; \
	echo "== modules =="; \
	talosctl -n "$$CONTROL_PLANE_IP" read /proc/modules | grep -E '^nvidia' || true; \
	echo "== nvidia version =="; \
	talosctl -n "$$CONTROL_PLANE_IP" read /proc/driver/nvidia/version || true; \
	echo "== node capacity =="; \
	kubectl get node -o json | jq '.items[].status.capacity | {cpu, memory, "nvidia.com/gpu"}'

flux-check:
	@flux get kustomizations -A
	@echo
	@flux get helmreleases -A

unsuspend-inference:
	@sed -i 's/suspend: true/suspend: false/' clusters/lab/apps-inference.yaml
	@echo "Unsuspended inference. Commit and push, or: flux reconcile ks flux-system --with-source"
	@echo "vLLM is replicas: 0 until the freeze diagnostic is over. Set it back to 1 in apps/inference/vllm/deployment.yaml after BIOS 7B96v14."

unsuspend-agents:
	@sed -i 's/suspend: true/suspend: false/' clusters/lab/apps-agents.yaml
	@sed -i 's/suspend: true/suspend: false/' clusters/lab/apps-agents-workloads.yaml
	@echo "Unsuspended agents + workloads. Commit and push, or: flux reconcile ks flux-system --with-source"
