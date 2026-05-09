#!/usr/bin/env bash
# Provision the kubeadm lab: network + 5 VMs (3 cp + 2 worker).
# Idempotent: re-running skips work that's already done.
# After this finishes, run ./bootstrap.sh to form the cluster.

source "$(dirname "$0")/lib.sh"

# --- Preflight ---------------------------------------------------------------

ensure_ssh_key

if ! sudo test -f "${BASE_IMAGE}"; then
  err "Base image not found: ${BASE_IMAGE}"
  err "Run ./download-image.sh first."
  exit 1
fi

SSH_PUBKEY="$(cat "${SSH_PUB_PATH}")"

# --- Network -----------------------------------------------------------------

if virsh -c "${LIBVIRT_CONN}" net-info "${LIBVIRT_NET}" &>/dev/null; then
  ok "libvirt network '${LIBVIRT_NET}' already defined"
else
  log "Defining libvirt network '${LIBVIRT_NET}' on 10.0.1.0/24"
  virsh -c "${LIBVIRT_CONN}" net-define "${KUBEADM_DIR}/network.xml"
  virsh -c "${LIBVIRT_CONN}" net-autostart "${LIBVIRT_NET}"
fi

if ! virsh -c "${LIBVIRT_CONN}" net-info "${LIBVIRT_NET}" | grep -q 'Active:.*yes'; then
  log "Starting network '${LIBVIRT_NET}'"
  virsh -c "${LIBVIRT_CONN}" net-start "${LIBVIRT_NET}"
fi
ok "Network active"

# --- Per-VM bring-up ---------------------------------------------------------

for entry in "${MACHINES[@]}"; do
  read -r name ip mac ram vcpu disk role <<< "${entry}"
  vm="kubeadm-${name}"

  if virsh -c "${LIBVIRT_CONN}" dominfo "${vm}" &>/dev/null; then
    ok "VM '${vm}' already defined — skipping"
    continue
  fi

  log "[${name}] Building overlay disk (${disk}G, backed by base)"
  overlay="${LIBVIRT_IMG_DIR}/${vm}.qcow2"
  sudo qemu-img create -q -f qcow2 -F qcow2 \
    -b "${BASE_IMAGE}" \
    "${overlay}" "${disk}G"

  log "[${name}] Building cloud-init seed ISO"
  workdir="$(mktemp -d)"
  trap 'rm -rf "${workdir}"' RETURN
  sed -e "s|@HOSTNAME@|${name}|g" -e "s|@SSHKEY@|${SSH_PUBKEY}|g" \
    "${KUBEADM_DIR}/cloud-init/user-data.tmpl" > "${workdir}/user-data"
  sed -e "s|@HOSTNAME@|${name}|g" \
    "${KUBEADM_DIR}/cloud-init/meta-data.tmpl" > "${workdir}/meta-data"
  seed="${LIBVIRT_IMG_DIR}/${vm}-seed.iso"
  sudo cloud-localds "${seed}" "${workdir}/user-data" "${workdir}/meta-data"
  rm -rf "${workdir}"

  log "[${name}] virt-install (ip=${ip}, mac=${mac}, ram=${ram}M, vcpu=${vcpu}, role=${role})"
  sudo virt-install \
    --connect "${LIBVIRT_CONN}" \
    --name "${vm}" \
    --memory "${ram}" \
    --vcpus "${vcpu}" \
    --cpu host-passthrough \
    --os-variant debian12 \
    --disk "path=${overlay},format=qcow2,bus=virtio" \
    --disk "path=${seed},device=cdrom" \
    --network "network=${LIBVIRT_NET},mac=${mac},model=virtio" \
    --import \
    --noautoconsole \
    --graphics none \
    --console pty,target_type=serial \
    >/dev/null

  ok "[${name}] defined and booting"
done

# --- Wait for cloud-init to finish on every guest ----------------------------
# First boot is slower than KTHW because user-data installs containerd + the
# kubeadm/kubelet/kubectl trio and pre-pulls control-plane images. Plan ~3 min.

log "Waiting for cloud-init on each VM (containerd + kubeadm install + image pull, ~3 min)..."
fail=0
for entry in "${MACHINES[@]}"; do
  read -r name ip _ _ _ _ _ <<< "${entry}"
  for i in {1..120}; do
    if ssh -F "${KUBEADM_DIR}/ssh-config" \
         -o ConnectTimeout=2 -o BatchMode=yes \
         "${name}" 'test -f /etc/kubeadm-FAILED' 2>/dev/null; then
      err "[${name}] cloud-init INSTALL FAILED — see /var/log/cloud-init-output.log"
      err "  ssh -F ${KUBEADM_DIR}/ssh-config root@${name} 'tail -100 /var/log/cloud-init-output.log'"
      fail=1
      break
    fi
    if ssh -F "${KUBEADM_DIR}/ssh-config" \
         -o ConnectTimeout=2 -o BatchMode=yes \
         "${name}" 'test -f /etc/kubeadm-ready' 2>/dev/null; then
      ok "[${name}] ready (${ip})"
      break
    fi
    sleep 3
    if [[ ${i} -eq 120 ]]; then
      warn "[${name}] still not ready after 6min — check 'virsh console kubeadm-${name}'"
      fail=1
    fi
  done
done

if [[ ${fail} -eq 1 ]]; then
  err "One or more VMs failed cloud-init. Fix the underlying issue, then:"
  err "  ./destroy.sh && ./provision.sh"
  exit 1
fi

cat <<EOF

$(ok "Lab is up. Summary:")

  cp-0    10.0.1.11   (control plane)
  cp-1    10.0.1.12   (control plane)
  cp-2    10.0.1.13   (control plane)
  wk-0    10.0.1.21   (worker)
  wk-1    10.0.1.22   (worker)
  VIP     ${CONTROL_PLANE_VIP}   (kube-vip, claimed during bootstrap)

Next:
  ./bootstrap.sh     # forms the cluster (~3 min)
EOF
