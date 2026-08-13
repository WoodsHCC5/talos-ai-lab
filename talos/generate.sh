#!/usr/bin/env bash
# Generate Talos machine config into talos/generated/ (gitignored).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -f lab.env ]]; then
  echo "missing lab.env — cp lab.env.example lab.env and edit it" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source lab.env
# shellcheck disable=SC1091
source versions.env
set +a

: "${CLUSTER_NAME:?}"
: "${CONTROL_PLANE_IP:?}"
: "${TALOS_VERSION:?}"
: "${KUBERNETES_VERSION:?}"
: "${INSTALL_DISK:?}"
: "${DISK_SERIAL_LOCAL_PATH:?}"
: "${DISK_SERIAL_MODELS:?}"

if [[ "$DISK_SERIAL_LOCAL_PATH" == REPLACE_* || "$DISK_SERIAL_MODELS" == REPLACE_* ]]; then
  echo "Set DISK_SERIAL_LOCAL_PATH and DISK_SERIAL_MODELS in lab.env first." >&2
  echo "  talosctl -n $CONTROL_PLANE_IP get disks -o yaml" >&2
  exit 1
fi

# Resolve schematic ID (content-addressable, safe to re-POST).
SCHEMATIC_ID="$(
  curl -fsS -X POST --data-binary @"${ROOT}/talos/factory/schematic.yaml" \
    https://factory.talos.dev/schematics | jq -r .id
)"
INSTALLER="factory.talos.dev/installer/${SCHEMATIC_ID}:${TALOS_VERSION}"

WORKDIR="${ROOT}/talos/generated"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

# Substitute volume serials into a generated patch (no gettext required).
python3 - "${ROOT}/talos/patches/volumes.yaml" "${WORKDIR}/volumes.yaml" <<'PY'
import os, sys
src, dst = sys.argv[1], sys.argv[2]
text = open(src).read()
for key in ("DISK_SERIAL_LOCAL_PATH", "DISK_SERIAL_MODELS"):
    text = text.replace("${" + key + "}", os.environ[key])
open(dst, "w").write(text)
PY

talosctl gen config \
  "$CLUSTER_NAME" \
  "https://${CONTROL_PLANE_IP}:6443" \
  --output-dir "$WORKDIR" \
  --talos-version "$TALOS_VERSION" \
  --kubernetes-version "$KUBERNETES_VERSION" \
  --install-disk "$INSTALL_DISK" \
  --install-image "$INSTALLER" \
  --config-patch @"${ROOT}/talos/patches/cluster.yaml" \
  --config-patch @"${ROOT}/talos/patches/nvidia-modules.yaml" \
  --config-patch @"${WORKDIR}/volumes.yaml"

# Point talosctl at this cluster from here on.
export TALOSCONFIG="${WORKDIR}/talosconfig"
talosctl config endpoint "$CONTROL_PLANE_IP"
talosctl config node "$CONTROL_PLANE_IP"

cat <<EOF

Generated $WORKDIR
  schematic:  $SCHEMATIC_ID
  installer:  $INSTALLER
  endpoint:   https://${CONTROL_PLANE_IP}:6443

Next:
  export TALOSCONFIG=$WORKDIR/talosconfig
  # after you boot the Factory ISO and the node is in maintenance mode:
  talosctl apply-config --insecure -n $CONTROL_PLANE_IP --file $WORKDIR/controlplane.yaml
EOF
