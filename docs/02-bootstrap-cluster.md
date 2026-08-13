# Week 2 — Cluster (Cilium, then the rest via Flux)

Goal: a Ready node, Hubble, a Gateway, `nvidia.com/gpu: 1`, and a passing CUDA smoke job.

## 1. Cilium in the ten-minute window

Talos was installed with `cluster.network.cni.name: none` and kube-proxy disabled. Until a CNI is running, the node stays NotReady and Talos will eventually reboot to retry.

```bash
export TALOSCONFIG=$PWD/talos/generated/talosconfig
export KUBECONFIG=$PWD/kubeconfig
./hack/bootstrap-cilium.sh
talosctl health
kubectl get nodes -o wide
```

The script applies Gateway API CRDs, then Helm-installs Cilium with the same values Flux will later adopt (`infra/cilium/values-bootstrap.yaml`):

- kube-proxy replacement
- KubePrism `localhost:7445`
- Talos-safe cgroup mounts and capability set (no `SYS_MODULE`)
- Gateway API, Hubble, L2 announcements

## 2. Device plugin (can wait for Flux)

If you want GPU before GitOps:

```bash
kubectl apply -f infra/namespaces.yaml
kubectl apply -f infra/configs/runtimeclass-nvidia.yaml
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
helm upgrade --install nvidia-device-plugin nvdp/nvidia-device-plugin \
  --namespace nvidia \
  --version 0.17.1 \
  --set runtimeClassName=nvidia \
  --set gfd.enabled=true \
  --set nfd.enabled=true
```

Otherwise skip this — Flux installs the same HelmRelease in week 2.

```bash
kubectl describe node | grep -A2 'nvidia.com/gpu'
kubectl apply -f hack/gpu-smoke.yaml
kubectl -n inference wait --for=condition=complete job/gpu-smoke --timeout=180s
kubectl -n inference logs job/gpu-smoke
```

You want `nvidia.com/gpu: 1` and `Test PASSED` in the job logs.

## 3. Edit the LAN IP pool

`apps/platform/cilium-l2/l2.yaml` ships with `192.168.1.50–59`. Change it to your `LB_IP_POOL` before Flux applies platform, or the Gateway will claim addresses that are not yours.

## 4. Do not install these

- Longhorn or Rook — one node, two NVMe. Distributed block storage teaches the wrong lesson here.
- NVIDIA GPU Operator **drivers** — already on the host via extensions.
- Ollama — week 3 is vLLM. Two runtimes on one 3090 is a scheduling lesson you do not need yet.

Continue to [03-gitops.md](03-gitops.md).
