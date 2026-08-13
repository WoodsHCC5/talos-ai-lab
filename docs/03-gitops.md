# Week 2 continued — Flux

Goal: this git repo is the source of truth. After this page, you stop running `helm upgrade` by hand.

## 1. Publish the repo

If this tree is not already on GitHub:

```bash
# from a machine with gh auth
gh repo create talos-ai-lab --public --source=. --remote=origin --push
```

Put `GITHUB_OWNER`, `GITHUB_REPO`, and `GITHUB_BRANCH` in `lab.env`.

## 2. Bootstrap Flux

Needs a GitHub PAT in `GITHUB_TOKEN` with `repo` scope.

```bash
export GITHUB_TOKEN=ghp_...
./hack/flux-bootstrap.sh
```

Flux commits its controllers into `clusters/lab/flux-system/` and starts reconciling `./clusters/lab`.

That path lists:

| Kustomization | Path | When |
| --- | --- | --- |
| `infra` | `infra/` | immediately |
| `apps-platform` | `apps/platform/` | after infra is ready |
| `apps-inference` | `apps/inference/` | **suspended** |
| `apps-agents` | `apps/agents/` | **suspended** |

## 3. Watch it converge

```bash
make flux-check
flux get sources all
kubectl get helmrelease -A
```

`infra` brings up:

- Gateway API CRDs (already applied at bootstrap; Flux keeps them)
- Cilium HelmRelease (adopts the bootstrap release)
- NVIDIA device plugin + RuntimeClass
- local-path provisioner on `/var/mnt/local-path`
- cert-manager

`apps-platform` then brings up:

- lab CA + ClusterIssuer
- Cilium L2 pool + announcement policy
- shared Gateway `lab` in `kube-system`
- kube-prometheus-stack (7-day retention, no Alertmanager)
- Postgres, Redis, Qdrant

## 4. The habit

Every later change is:

1. Edit YAML.
2. Commit.
3. `git push` (or `flux reconcile ks flux-system --with-source`).
4. If it is wrong, `git revert`.

Do not “just helm install one more thing.” If you did it by hand during bootstrap, make the repo match before you walk away.

## 5. Unsuspend later

```bash
make unsuspend-inference   # week 3
make unsuspend-agents      # week 4
git add clusters/lab && git commit -m "unsuspend inference" && git push
```
