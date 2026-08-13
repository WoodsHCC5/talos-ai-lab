#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/versions.env"

RESP="$(curl -fsS -X POST --data-binary @"${ROOT}/talos/factory/schematic.yaml" \
  https://factory.talos.dev/schematics)"
ID="$(echo "$RESP" | jq -r .id)"

cat <<EOF
schematic id:  ${ID}
iso:           https://factory.talos.dev/image/${ID}/${TALOS_VERSION}/metal-amd64.iso
installer:     factory.talos.dev/installer/${ID}:${TALOS_VERSION}
factory ui:    https://factory.talos.dev/?arch=amd64&platform=metal&target=metal&version=${TALOS_VERSION}

Write the ID down. generate.sh will POST the same schematic and get the same ID.
EOF
