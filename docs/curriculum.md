# Curriculum

A month on this box, in the order the repo is structured.

## Week 1 — Talos

Factory image, machineconfig in git, `talosctl` as the only shell, recover from a bad patch, read `pcidevices` and volume status.

**Done when:** NVIDIA modules are loaded, `u-local-path` and `u-models` are mounted, `talosctl bootstrap` has run.

## Week 2 — Cluster

Cilium in the 10-minute window, Gateway API, Hubble, Flux bootstrap, local-path, cert-manager, Prometheus. Break a NetworkPolicy on purpose. Watch Flux revert a manual `kubectl edit` after you put the YAML back.

**Done when:** `kubectl get node` is Ready, `nvidia.com/gpu: 1`, `hack/gpu-smoke.yaml` prints `Test PASSED`, Grafana loads.

## Week 3 — Inference

Unsuspend `apps-inference`. One 7B AWQ, then one 32B. LiteLLM as the only URL clients know. Open WebUI for humans.

**Done when:** `POST /v1/chat/completions` against LiteLLM returns tokens from the 3090, and you have watched VRAM during a long prompt.

## Week 4 — Agents

Unsuspend `apps-agents`. `Agent/cluster-guide` answers a question from live cluster state. Edit the system prompt, commit, see the change.

**Done when:** you can explain, with a `kubectl get`, the difference between a ModelConfig, a RemoteMCPServer, and an Agent.

## After that, pick one lane

- **vcluster** on this same node — a second API server, same GPU.
- **Kueue** — queued jobs instead of a always-on vLLM Deployment.
- **Time-slicing** the 3090 — only after exclusive vLLM is boring.
- **A second machine** — real worker / control-plane split. Then Longhorn becomes a conversation.
- **Langfuse + evals** — treat prompts like code.

Do not install the CNCF landscape. The repo is small so you can read every file.
