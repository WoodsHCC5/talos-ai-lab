#!/usr/bin/env bash
# Install Cilium during the Talos bootstrap window (~10 minutes after
# `talosctl bootstrap` while the node is "not ready" because CNI is none).
#
# After this script, Flux's HelmRelease named "cilium" in kube-system will
# adopt the same release.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/versions.env"

echo "Applying Gateway API CRDs ${GATEWAY_API_VERSION}..."
kubectl apply --server-side -f \
  "https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API_VERSION}/standard-install.yaml"

helm repo add cilium https://helm.cilium.io/ >/dev/null
helm repo update cilium >/dev/null

echo "Installing Cilium ${CILIUM_VERSION} (kube-proxy replacement + Gateway API + Hubble + L2)..."
helm upgrade --install cilium cilium/cilium \
  --version "${CILIUM_VERSION}" \
  --namespace kube-system \
  --wait \
  --timeout 10m \
  --values "${ROOT}/infra/cilium/values-bootstrap.yaml"

echo
echo "Cilium installed. Next:"
echo "  kubectl -n kube-system get pods"
echo "  talosctl health"
echo "  kubectl apply -f hack/gpu-smoke.yaml   # after device plugin is up"
