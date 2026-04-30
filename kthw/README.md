# Kubernetes The Hard Way — Local VM Lab

Bring-up infrastructure for [KTHW v1.32](https://github.com/kelseyhightower/kubernetes-the-hard-way),
adapted for **x86_64 NixOS host** with **HA topology** (3 controllers + 2 workers + LB).

## Topology

| Role         | Hostname   | IP        | RAM    | vCPU | Disk |
|--------------|------------|-----------|--------|------|------|
| Jumpbox      | `jumpbox`  | 10.0.0.1  | 1 GB   | 1    | 10 GB |
| Controller 0 | `server-0` | 10.0.0.2  | 2 GB   | 2    | 15 GB |
| Controller 1 | `server-1` | 10.0.0.3  | 2 GB   | 2    | 15 GB |
| Controller 2 | `server-2` | 10.0.0.4  | 2 GB   | 2    | 15 GB |
| Worker 0     | `node-0`   | 10.0.0.5  | 2.5 GB | 2    | 20 GB |
| Worker 1     | `node-1`   | 10.0.0.6  | 2.5 GB | 2    | 20 GB |
| Load balancer| `lb-0`     | 10.0.0.7  | 512 MB | 1    | 5 GB  |

Total: ~12.5 GB RAM, ~100 GB disk (overlays grow lazily).

Network: dedicated libvirt network `kthw` on **10.0.0.0/24**, gateway 10.0.0.254
(NAT to host LAN). DNS suffix `.kubernetes.local` is auto-resolved between VMs
via libvirt's dnsmasq.

Base OS: **Debian 12 (bookworm) cloud image**, x86_64. KTHW v1.32 docs assume
Debian, so commands work verbatim — only swap `arm64` → `amd64` in the binary
download URLs.

## Bring-up

```bash
cd ~/nixos-dotfiles/kthw

./download-image.sh   # ~700MB, one-time
./provision.sh        # ~2–3 min, idempotent
```

Connect to the jumpbox:

```bash
ssh -F ~/nixos-dotfiles/kthw/ssh-config jumpbox
```

(or add `Include /home/misha/nixos-dotfiles/kthw/ssh-config` to `~/.ssh/config`).

## Tear-down

```bash
./destroy.sh             # destroys VMs, network, base image
./destroy.sh --keep-base # keep the cached Debian image
```

## Files

- `network.xml`             — libvirt network with static MAC→IP→hostname reservations
- `cloud-init/user-data.tmpl` — first-boot config (user `misha`, SSH key, base packages)
- `cloud-init/meta-data.tmpl` — first-boot meta (hostname, instance-id)
- `lib.sh`                   — shared bash (machine table, helpers)
- `download-image.sh`        — fetches Debian 12 cloud image
- `provision.sh`             — defines network, builds overlays + seeds, virt-install
- `destroy.sh`               — full teardown
- `ssh-config`               — SSH config snippet for the lab

## Mapping KTHW v1.32 docs onto this lab

KTHW v1.32 assumes a **single control-plane node** named `server` and ARM64
hardware. Diffs to apply when reading the tutorial:

| KTHW v1.32 says            | This lab uses                                 |
|-----------------------------|-----------------------------------------------|
| `arm64` in download URLs    | `amd64`                                       |
| Single host `server`        | Three hosts `server-0`, `server-1`, `server-2`; you'll need to extend etcd to a 3-node cluster, run kube-apiserver on all three, and point workers + kubectl at `lb-0` instead of `server` |
| `machines.txt` with 4 lines | 7 lines — see `network.xml` for IP scheme     |
| No load balancer            | `lb-0` runs HAProxy in front of the 3 apiservers (you configure it during chapter 08-ish) |

The HA extensions are the **point of doing this** — the v1.32 tutorial gives
you the modern Debian-based bring-up steps, and you layer on production-grade
patterns (etcd quorum, apiserver fleet, LB) yourself.

## Troubleshooting

- **VM stuck booting**: `virsh -c qemu:///system console kthw-<name>` (Ctrl+] to exit).
- **SSH refused**: cloud-init is still running. `provision.sh` waits up to 3 min;
  if it gives up, check `virsh console`.
- **IP conflicts** (e.g., Firezone VPN routes 10.0.0.0/24): edit `network.xml`
  to a different /24 (e.g., `192.168.130.0/24`), update IPs in `lib.sh` and
  `ssh-config`, then `./destroy.sh && ./provision.sh`.
- **Disk full**: overlays grow; check `sudo du -sh /var/lib/libvirt/images/kthw-*`.
- **Want a clean slate for one VM only**: `virsh undefine kthw-server-0 --remove-all-storage`,
  then re-run `./provision.sh` (it'll recreate just that one).
