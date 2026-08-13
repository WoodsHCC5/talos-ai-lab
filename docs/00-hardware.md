# Hardware

This lab assumes one box:

| Piece | Why it matters |
| --- | --- |
| i9-10980XE, 18c/36t | Plenty for Cilium, Prometheus, embeddings, agent loops |
| 256 GB RAM | Cluster services + 80–100 GB page cache for HDD-resident models |
| RTX 3090, 24 GB | One resident 7B–32B AWQ model. No MIG. No time-slicing in week 1–3. |
| NVMe 1–2 TB | Talos SYSTEM / STATE / EPHEMERAL (etcd, containerd, kubelet) |
| HDD 1, ~4 TB | User volume `local-path` → PVC data |
| HDD 2, ~4 TB | User volume `models` → vLLM download cache |

## Buy the NVMe

etcd on spinning rust will make the API server feel broken. A used 1 TB NVMe is the one purchase that changes the cluster. Put Talos on it (`INSTALL_DISK` in `lab.env`).

If you refuse: install Talos on HDD 1, accept lag whenever the disks are busy, and still put models on HDD 2.

## Power and PCIe

- PSU **850 W+**, two solid 8-pin (or 12-pin + adapters) to the 3090.
- The 10980XE is PCIe 3.0. The 3090 is PCIe 4.0. Inference is almost never lane-bound. Ignore it.
- Consumer GeForce: CUDA works. NVIDIA AI Enterprise / vGPU / MIG do not. That is fine.

## This is not a desktop

Talos has no GUI, no package manager, no SSH. After install, you sit at a laptop.

If you still need a desktop on this machine, stop and put Proxmox on the metal instead. That is a different architecture and this repo will fight you.

## Disk serials

After the node is in maintenance mode (Factory ISO booted, before `apply-config`):

```bash
source lab.env
talosctl --insecure -n "$CONTROL_PLANE_IP" get disks -o yaml
```

Copy each HDD `serial` into `DISK_SERIAL_LOCAL_PATH` and `DISK_SERIAL_MODELS`. Never select by `/dev/sda`.

## LAN addresses

Pick a DHCP-reserved or unused range for Cilium L2 announcements (`LB_IP_POOL`). You need at least two addresses. Put the first one in `/etc/hosts` on the laptop as `lab.home.arpa`, `chat.lab.home.arpa`, `llm.lab.home.arpa`.
