# Week 1 — Boot Talos

Goal: a Talos node with NVIDIA modules loaded and two user volumes mounted. Kubernetes exists but has no CNI yet.

## 1. Laptop tools

Install `talosctl` **matching** `TALOS_VERSION` in `versions.env` (currently v1.13.8), plus `kubectl`, `helm`, `jq`, `curl`, and `python3`.

```bash
curl -sL https://talos.dev/install | sh
talosctl version --client
```

## 2. Fill in lab.env

```bash
cp lab.env.example lab.env
```

You will not know the models-disk serial until step 5. You **do** need `CONTROL_PLANE_IP` (the address the box will have after install — set a DHCP reservation) and `INSTALL_DISK` (the NVMe Talos should own, usually `/dev/nvme0n1`).

## 3. Build the Factory ISO

```bash
make schematic
```

That POSTs `talos/factory/schematic.yaml` (NVIDIA production kernel modules + container toolkit) and prints an ISO URL. Flash it to a USB stick. The schematic is content-addressable — the same YAML always produces the same ID.

Do not use a vanilla Talos ISO. The GPU operator cannot load unsigned modules onto Talos.

## 4. Boot the ISO

Boot the USB. Talos comes up in **maintenance mode**. From the laptop:

```bash
source lab.env
talosctl --insecure -n "$CONTROL_PLANE_IP" get disks -o yaml
talosctl --insecure -n "$CONTROL_PLANE_IP" get pcidevices | grep -i nvidia
```

Put the **non-install** NVMe serial into `DISK_SERIAL_MODELS`. Confirm `INSTALL_DISK` is the other NVMe — that disk gets Talos, EPHEMERAL (capped at 1 TB), and `local-path`.

## 5. Generate and apply machine config

```bash
make talos-config
export TALOSCONFIG=$PWD/talos/generated/talosconfig
talosctl apply-config --insecure -n "$CONTROL_PLANE_IP" \
  --file talos/generated/controlplane.yaml
```

The node installs Talos onto `INSTALL_DISK` and reboots into the configured system. This takes a few minutes.

## 6. Bootstrap etcd

Single node, so this node is the only control plane.

```bash
talosctl bootstrap -n "$CONTROL_PLANE_IP"
talosctl kubeconfig .
export KUBECONFIG=$PWD/kubeconfig
```

`talosctl health` will **fail** until Cilium is installed. The dashboard sits at “retrying error: node not ready”. That is expected. You have about **ten minutes** to run week 2’s Cilium bootstrap. Go to [02-bootstrap-cluster.md](02-bootstrap-cluster.md) now.

## 7. After Cilium is up, confirm GPU + volumes

```bash
talosctl -n "$CONTROL_PLANE_IP" read /proc/modules | grep nvidia
talosctl -n "$CONTROL_PLANE_IP" read /proc/driver/nvidia/version
talosctl -n "$CONTROL_PLANE_IP" get extensions
talosctl -n "$CONTROL_PLANE_IP" get volumestatus
talosctl -n "$CONTROL_PLANE_IP" get mountstatus
```

You want `u-local-path` and `u-models` in phase `ready`, mounted at `/var/mnt/local-path` and `/var/mnt/models`.

## Upgrade later

The installer image is `factory.talos.dev/installer/<schematic-id>:<talos-version>`. Bump the tag, keep the same schematic, `talosctl upgrade`. Bump NVIDIA extensions only via a new schematic if Sidero publishes new production drivers for that Talos release — they are version-locked.
