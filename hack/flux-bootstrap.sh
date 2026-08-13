#!/usr/bin/env bash
# Bootstrap Flux against the public GitHub repo that contains this tree.
# Requires: flux CLI, a GitHub PAT with repo scope in GITHUB_TOKEN,
# and lab.env with GITHUB_OWNER / GITHUB_REPO / GITHUB_BRANCH.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -f "${ROOT}/lab.env" ]]; then
  echo "missing lab.env" >&2
  exit 1
fi
set -a
# shellcheck disable=SC1091
source "${ROOT}/lab.env"
set +a

: "${GITHUB_OWNER:?set GITHUB_OWNER in lab.env}"
: "${GITHUB_REPO:?}"
: "${GITHUB_BRANCH:=main}"

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "export GITHUB_TOKEN=... (repo scope) before running" >&2
  exit 1
fi

flux bootstrap github \
  --owner="$GITHUB_OWNER" \
  --repository="$GITHUB_REPO" \
  --branch="$GITHUB_BRANCH" \
  --path=clusters/lab \
  --personal \
  --private=false \
  --token-auth
