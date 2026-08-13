# Week 4 — Agents

Goal: a Kubernetes-native agent (a CRD, not a Python script on your laptop) that can inspect this cluster through MCP tools and a local model.

## 1. Secrets, then unsuspend

```bash
./hack/create-secrets.sh
make unsuspend-agents
git add clusters/lab/apps-agents.yaml
git commit -m "unsuspend agents"
git push
```

Flux installs:

1. `kagent-crds` (includes kmcp)
2. `kagent` HelmRelease, default provider = OpenAI-compatible LiteLLM at `http://litellm.inference.svc.cluster.local:4000/v1`, model `lab`
3. `ModelConfig/local-vllm`
4. `Agent/cluster-guide`

## 2. Confirm the wiring

```bash
kubectl -n kagent get helmrelease
kubectl -n kagent get modelconfig
kubectl -n kagent get remotemcpserver
kubectl -n kagent get agent
kubectl -n kagent port-forward svc/kagent-ui 8080:8080
```

Open http://localhost:8080, pick **cluster-guide**, ask:

> What pods are in the inference namespace, and does any of them request a GPU?

The agent should call `k8s_get_resources` (or similar) and mention vLLM. If it invents names, the model is too small or the tools are not attached — check `kubectl -n kagent describe agent cluster-guide` and the RemoteMCPServer name.

The chart names the tool server `kagent-tool-server`. If your release name differs, edit `apps/agents/first-agent/agent.yaml`.

## 3. What to change next (one thing at a time)

- Add more `toolNames` from the built-in kagent-tools server (Prometheus, Hubble) after you have read what each tool does.
- Point a second `ModelConfig` at a cloud API and compare traces. Keep local `lab` as default.
- Add Qdrant as an MCP server and retrieve from `/var/mnt/models` docs you put there. Embeddings on CPU.
- Langfuse is intentionally not in this repo. It is a good follow-on HelmRelease once you want prompt traces.

## 4. Things this agent must never do

The system prompt already says: no SSH, no second GPU workload, no invented cluster state. Treat that prompt as part of the lab — edit it, commit, watch the agent change. That is the point of agents-as-CRDs.

## 5. Optional: kagent CLI

```bash
curl -sL https://raw.githubusercontent.com/kagent-dev/kagent/refs/heads/main/scripts/get-kagent | bash
kagent dashboard
```

The CLI is a convenience. The CRDs are the source of truth.
