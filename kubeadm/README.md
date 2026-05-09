# Kubeadm HA Lab — Local VM Cluster

A 3-control-plane + 2-worker Kubernetes cluster on libvirt, built with
**kubeadm** and made HA with **kube-vip** (no separate LB VM).

Sibling to `../kthw/`. Fully isolated network + base image so the two labs can
coexist.

## Topology

| Role          | Hostname | IP           | RAM    | vCPU | Disk |
|---------------|----------|--------------|--------|------|------|
| Control plane | `cp-0`   | 10.0.1.11    | 2.5 GB | 2    | 20 GB |
| Control plane | `cp-1`   | 10.0.1.12    | 2.5 GB | 2    | 20 GB |
| Control plane | `cp-2`   | 10.0.1.13    | 2.5 GB | 2    | 20 GB |
| Worker        | `wk-0`   | 10.0.1.21    | 3 GB   | 2    | 25 GB |
| Worker        | `wk-1`   | 10.0.1.22    | 3 GB   | 2    | 25 GB |
| **VIP**       | —        | **10.0.1.10** | —      | —    | —    |

Total: ~13.5 GB RAM, ~110 GB disk (overlays grow lazily).

| Component  | Version       |
|------------|---------------|
| Kubernetes | v1.32.0       |
| containerd | Debian 12 apt |
| kube-vip   | v0.8.7        |
| Calico     | v3.28.2       |
| OS         | Debian 12     |

Network: dedicated libvirt network `kubeadm` on **10.0.1.0/24** (NAT).
The VIP **10.0.1.10** is claimed by whichever control-plane node holds the
kube-vip leader lease — survives loss of any single cp.

## Bring-up (3 commands)

```bash
cd ~/nixos-dotfiles/kubeadm

./download-image.sh   # ~700MB, one-time
./provision.sh        # ~3 min — defines 5 VMs, runs cloud-init
./bootstrap.sh        # ~3 min — kubeadm init, joins, kube-vip, Calico
```

After `bootstrap.sh`, a kubeconfig is written to `./admin.conf`:

```bash
export KUBECONFIG=~/nixos-dotfiles/kubeadm/admin.conf
kubectl get nodes -o wide
kubectl get pods -A
```

## Tear-down

```bash
./destroy.sh             # destroys VMs, network, base image, admin.conf
./destroy.sh --keep-base # keep the cached Debian image
```

## Files

- `network.xml`                  — libvirt network with static MAC→IP→hostname reservations
- `cloud-init/user-data.tmpl`    — first-boot: containerd + kubeadm/kubelet/kubectl + sysctls
- `cloud-init/meta-data.tmpl`    — first-boot meta (hostname, instance-id)
- `lib.sh`                       — shared bash (paths, machine table, versions)
- `download-image.sh`            — fetches Debian 12 cloud image
- `provision.sh`                 — defines network, builds VMs, waits for cloud-init
- `bootstrap.sh`                 — `kubeadm init` on cp-0, joins, kube-vip, Calico
- `destroy.sh`                   — full teardown
- `ssh-config`                   — SSH config snippet for the lab

## What `bootstrap.sh` actually does

1. **Pre-pull** `kube-vip:v0.8.7` on every control-plane node (via `ctr -n k8s.io`).
2. **cp-0**: drop kube-vip static-pod manifest into `/etc/kubernetes/manifests/`,
   then `kubeadm init --config=...` with `controlPlaneEndpoint = 10.0.1.10:6443`.
   kube-vip claims the VIP via ARP as soon as kubelet starts.
3. Generate fresh **join token** (`kubeadm token create --print-join-command`)
   and **control-plane cert key** (`kubeadm init phase upload-certs --upload-certs`).
4. **cp-1, cp-2**: drop kube-vip manifest, `kubeadm join --control-plane --certificate-key …`.
5. **wk-0, wk-1**: `kubeadm join …` (worker form).
6. **Calico**: apply `tigera-operator.yaml`, wait for the `Installation` CRD,
   apply an `Installation` CR with `cidr: 10.244.0.0/16`.
7. Copy `/etc/kubernetes/admin.conf` from cp-0 → `./admin.conf`.
8. Wait for all 5 nodes to be `Ready`.

Everything is **idempotent**:
- Already-initialized cp-0 (`/etc/kubernetes/admin.conf` exists) → skip init.
- Already-joined node (`/etc/kubernetes/kubelet.conf` exists) → skip join.
- `kubectl apply` is naturally idempotent.

So you can safely re-run `./bootstrap.sh` to converge after a partial failure.

## Connecting

SSH directly:

```bash
ssh -F ~/nixos-dotfiles/kubeadm/ssh-config root@cp-0
# or
ssh -F ~/nixos-dotfiles/kubeadm/ssh-config cp-0     # as user 'misha'
```

Or add `Include /home/misha/nixos-dotfiles/kubeadm/ssh-config` to `~/.ssh/config`.

## Verifying HA

The point of 3 control-plane nodes is surviving a single-node failure. Test it:

```bash
# Find the current VIP holder.
for cp in cp-0 cp-1 cp-2; do
  ssh -F ssh-config "root@$cp" "ip -4 addr show enp1s0 | grep 10.0.1.10" \
    && echo "  ↑ $cp holds the VIP"
done

# Kill it. The other two should re-elect within ~5s.
sudo virsh -c qemu:///system destroy kubeadm-cp-0     # hard power-off

# kubectl should still work after a brief blip.
kubectl --kubeconfig=admin.conf get nodes

# Bring it back.
sudo virsh -c qemu:///system start kubeadm-cp-0
```

## Troubleshooting

- **`bootstrap.sh` fails at kubeadm init**: usually the kube-vip image hasn't
  been pulled yet, or interface isn't `enp1s0`. Check
  `ssh root@cp-0 'crictl ps -a; journalctl -u kubelet --no-pager -n 100'`.
- **VIP not pingable after init**: `ssh root@cp-0 'crictl ps | grep kube-vip'`.
  If absent, the static pod failed — check `crictl logs` of the kube-vip container.
- **Workers stuck `NotReady`**: Calico pods crashlooping. `kubectl get pods -n calico-system`.
- **IP conflicts** (e.g., other lab on 10.0.1.0/24): edit `network.xml`, `lib.sh`,
  `ssh-config` to a different /24, then `./destroy.sh && ./provision.sh && ./bootstrap.sh`.
- **Want a clean cluster on the same VMs**: `ssh root@<node> 'kubeadm reset -f'`
  on every node, then re-run `./bootstrap.sh`. Faster than a full destroy.
