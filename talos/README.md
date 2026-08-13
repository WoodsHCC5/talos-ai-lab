# Talos machine config

This directory is **not** reconciled by Flux. Talos is the OS. You apply it with `talosctl`.

## Files

| Path | What it does |
| --- | --- |
| `factory/schematic.yaml` | Image Factory customization: NVIDIA production kernel modules + container toolkit |
| `patches/cluster.yaml` | CNI none, kube-proxy off, schedule on the control plane |
| `patches/nvidia-modules.yaml` | Load `nvidia`, `nvidia_uvm`, `nvidia_drm`, `nvidia_modeset` |
| `patches/volumes.yaml` | User volumes `local-path` and `models` on the two HDDs |
| `generate.sh` | `talosctl gen config` into `generated/` (gitignored) |

The NVIDIA container toolkit extension already registers the `nvidia` containerd runtime. Kubernetes workloads opt in with `runtimeClassName: nvidia`. We do **not** make NVIDIA the default CRI runtime, so CoreDNS and etcd never accidentally pull in GPU libraries.

## Generate

```bash
cp lab.env.example lab.env   # from repo root, then edit
make talos-config
```

`generated/` contains secrets. Do not commit it.

## Apply after install

```bash
source lab.env
talosctl apply-config -n "$CONTROL_PLANE_IP" --file talos/generated/controlplane.yaml
```

To patch a running node instead of regenerating:

```bash
talosctl -n "$CONTROL_PLANE_IP" patch mc --patch @talos/patches/nvidia-modules.yaml
```
