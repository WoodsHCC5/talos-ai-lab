#!/usr/bin/env bash
# In-cluster secrets. Nothing here is committed.
set -euo pipefail

kubectl -n kagent create secret generic kagent-local \
  --from-literal=OPENAI_API_KEY="${LITELLM_KEY:-sk-lab}" \
  --dry-run=client -o yaml | kubectl apply -f -

if [[ -n "${HF_TOKEN:-}" ]]; then
  kubectl -n inference create secret generic huggingface \
    --from-literal=token="$HF_TOKEN" \
    --dry-run=client -o yaml | kubectl apply -f -
  echo "huggingface token applied in inference/"
else
  echo "HF_TOKEN unset — gated models will fail to pull. Public AWQ checkpoints are fine."
fi

echo "kagent-local secret applied."
