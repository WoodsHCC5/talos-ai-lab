# Week 3 — Inference

Goal: an OpenAI-compatible API on the LAN, one model on the 3090, a chat UI.

## 1. Unsuspend

```bash
make unsuspend-inference
git add clusters/lab/apps-inference.yaml
git commit -m "unsuspend inference"
git push
```

Flux will create:

- `inference/vllm` — exclusive `nvidia.com/gpu: 1`, hostPath `/var/mnt/models`
- `inference/litellm` — front door, model name `lab`
- `webui/open-webui` — talks only to LiteLLM

## 2. First model is 7B on purpose

`Qwen/Qwen2.5-7B-Instruct-AWQ` fits easily, downloads fast, and proves the wiring. A 32B that OOMs on day one teaches you nothing.

```bash
kubectl -n inference logs -f deploy/vllm
# wait for "Application startup complete"
curl -sS http://llm.lab.home.arpa/v1/models \
  -H 'Authorization: Bearer sk-lab'
```

If you do not have DNS yet:

```bash
kubectl -n inference port-forward svc/litellm 4000:4000
curl -sS http://127.0.0.1:4000/v1/chat/completions \
  -H 'Authorization: Bearer sk-lab' \
  -H 'Content-Type: application/json' \
  -d '{"model":"lab","messages":[{"role":"user","content":"ping"}]}'
```

Open WebUI: `http://chat.lab.home.arpa` or `kubectl -n webui port-forward svc/open-webui 8080:8080`.

## 3. Promote to 32B

When 7B is healthy, edit **both** files so the names stay aligned:

- `apps/inference/vllm/deployment.yaml` `--model` → `Qwen/Qwen2.5-32B-Instruct-AWQ` (or Qwen3-32B AWQ)
- `apps/inference/litellm/deployment.yaml` `model:` string under `lab`

Keep `--max-model-len` at 8192 and `--gpu-memory-utilization` at 0.90 until you have watched VRAM. A 32B that barely fits with no KV cache is a worse agent model than a slightly smaller quant that can hold a tool-using conversation.

Gated Hugging Face repos: `HF_TOKEN=hf_... ./hack/create-secrets.sh`.

## 4. Rules for the 3090

- One pod with `nvidia.com/gpu: 1`. vLLM uses `Recreate` so a rolling update cannot double-book the card.
- Embeddings and rerankers stay on CPU. You have 36 threads.
- Do not install Ollama next to this Deployment.
- Time-slicing is a later lab. Enable it in the device-plugin HelmRelease only after you can explain why vLLM hates sharing.

## 5. What you should see in Grafana

GPU utilization, VRAM, token latency (LiteLLM / vLLM logs), and pod restarts. If VRAM sits at 23.9/24 GiB and the pod is crash-looping, drop `max-model-len` or the model size. Do not raise `gpu-memory-utilization` above 0.95.
