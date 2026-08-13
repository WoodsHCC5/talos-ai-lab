# talos-ai-lab

A GitOps repo for a **single bare-metal Talos Linux node** that is also a Kubernetes control plane, a GPU worker, and an AI-agent lab.

It is written for this hardware:

| Piece | Role |
| --- | --- |
| Intel Core i9-10980XE (18c/36t) | control plane + embeddings + agents |
| 256 GB RAM | cluster services + huge page cache for model files |
| NVIDIA GeForce RTX 3090 (24 GB) | exclusive vLLM |
| NVMe (buy one if you do not have it) | Talos, etcd, containerd |
| 2× 4 TB HDD | PVCs and model weights |

This is a **server**, not a desktop. Talos has no GUI and no SSH. You operate it from a laptop with `talosctl` and `kubectl`.

## What this repo is

The source of truth for the machine. You do not “set up Kubernetes” by typing helm commands until it works. You change a file, commit, and the cluster converges.

```
laptop (talosctl, kubectl, git)
        │
        ▼
┌──────────────────────────────────────────────┐
│  Talos Linux  (Image Factory + NVIDIA exts)  │
│  single node = control plane + worker        │
│                                              │
│  Cilium (kube-proxy replacement, Hubble,     │
│          Gateway API, L2 announcements)      │
│  NVIDIA RuntimeClass + device plugin         │
│  Flux GitOps                                 │
│                                              │
│  vLLM (GPU)  →  LiteLLM  →  Open WebUI       │
│  kagent + MCP  (agents as CRDs)              │
└──────────────────────────────────────────────┘
```

## Layout

```
talos/                     # machine OS — applied with talosctl, not Flux
  factory/schematic.yaml   # Image Factory: NVIDIA production extensions
  patches/                 # CNI none, GPU modules, user volumes
  generate.sh              # talosctl gen config from lab.env

clusters/lab/              # Flux entrypoint (path used by `flux bootstrap`)
  infra.yaml               # week 2 — always on after bootstrap
  apps-platform.yaml       # week 2 — monitoring + data
  apps-inference.yaml      # week 3 — suspended until you unsuspend
  apps-agents.yaml         # week 4 — suspended until you unsuspend

infra/                     # controllers and cluster-wide config
apps/                      # namespaced workloads
docs/                      # follow these in order
hack/                      # one-shot bootstrap scripts
```

Flux Kustomizations for inference and agents start with `spec.suspend: true`. That is intentional. Week 1 should not require a 32B model.

## Path through the repo

1. Read [docs/00-hardware.md](docs/00-hardware.md) and buy the NVMe if you do not have one.
2. Copy `lab.env.example` → `lab.env` and fill in IPs / disk serials.
3. [docs/01-boot-talos.md](docs/01-boot-talos.md) — Factory ISO, install, GPU modules.
4. [docs/02-bootstrap-cluster.md](docs/02-bootstrap-cluster.md) — Cilium in the 10-minute window, first GPU smoke test.
5. [docs/03-gitops.md](docs/03-gitops.md) — `flux bootstrap` against this repo.
6. [docs/04-inference.md](docs/04-inference.md) — unsuspend vLLM + LiteLLM + Open WebUI.
7. [docs/05-agents.md](docs/05-agents.md) — unsuspend kagent and the first Agent CR.

The longer narrative is in [docs/curriculum.md](docs/curriculum.md).

## What this repo will not do

- Install Proxmox, Longhorn, Rook, or Ollama.
- Time-slice the 3090. vLLM owns the GPU. Time-slicing is a later lab.
- Commit secrets. Examples end in `.example.yaml`; `hack/create-secrets.sh` creates the real ones in-cluster.
- Run a desktop environment on the Talos node.

## Tools on the laptop

```text
talosctl  (same version as TALOS_VERSION)
kubectl
helm
flux
git
jq
```

## License

MIT. See [LICENSE](LICENSE).
