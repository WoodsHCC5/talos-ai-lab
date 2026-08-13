# Hardware

This lab assumes one box:

| Piece | Why it matters |
| --- | --- |
| i9-10980XE, 18c/36t | Plenty for Cilium, Prometheus, embeddings, agent loops |
| 256 GB RAM | Cluster services, agent sandboxes, and model load headroom |
| RTX 3090, 24 GB | One resident 7B–32B AWQ model. No MIG. No time-slicing in week 1–3. |
| NVMe 1, ~4 TB | Talos install (SYSTEM / STATE / EPHEMERAL) + user volume `local-path` |
| NVMe 2, ~4 TB | User volume `models` → vLLM download cache |

Both data disks are NVMe. You do **not** need a third drive. etcd and containerd can live on NVMe 1; that was only a problem when the install disk was a spinning HDD.

## Disk layout

Talos EPHEMERAL will swallow the whole install disk unless you cap it. The machine config does this:

| Volume | Where | Size |
| --- | --- | --- |
| SYSTEM / STATE | NVMe 1 (`INSTALL_DISK`) | Talos-managed, small |
| EPHEMERAL | leftover of NVMe 1, **capped at 1 TB** | etcd WAL is not here, but containerd and kubelet are |
| `local-path` (`/var/mnt/local-path`) | rest of NVMe 1 (~3 TB) | Postgres, Prometheus, Qdrant, Open WebUI PVCs |
| `models` (`/var/mnt/models`) | all of NVMe 2 (~4 TB) | Hugging Face / vLLM weight cache |

Select NVMe 2 by **serial**, not `/dev/nvme1n1`. Two identical NVMe devices can swap names across reboots.

## Power and PCIe

- PSU **850 W+**, two solid 8-pin (or 12-pin + adapters) to the 3090.
- The 10980XE is PCIe 3.0. The 3090 is PCIe 4.0. Two NVMe drives plus the GPU fit in the lane budget. Inference is almost never lane-bound.
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

Set `INSTALL_DISK` to the NVMe you want Talos on (usually `/dev/nvme0n1`). Copy the **other** NVMe’s `serial` into `DISK_SERIAL_MODELS`. `local-path` uses `system_disk` and does not need its own serial.

## LAN addresses

Pick a DHCP-reserved or unused range for Cilium L2 announcements (`LB_IP_POOL`). You need at least two addresses. Put the first one in `/etc/hosts` on the laptop as `lab.home.arpa`, `chat.lab.home.arpa`, `llm.lab.home.arpa`.
