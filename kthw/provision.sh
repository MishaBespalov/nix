#!/usr/bin/env bash
# Provision the full KTHW lab: network + 7 VMs.
# Idempotent: re-running skips work that's already done.

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
  log "Defining libvirt network '${LIBVIRT_NET}' on 10.0.0.0/24"
  virsh -c "${LIBVIRT_CONN}" net-define "${KTHW_DIR}/network.xml"
  virsh -c "${LIBVIRT_CONN}" net-autostart "${LIBVIRT_NET}"
fi

if ! virsh -c "${LIBVIRT_CONN}" net-info "${LIBVIRT_NET}" | grep -q 'Active:.*yes'; then
  log "Starting network '${LIBVIRT_NET}'"
  virsh -c "${LIBVIRT_CONN}" net-start "${LIBVIRT_NET}"
fi
ok "Network active"

# --- Per-VM bring-up ---------------------------------------------------------

for entry in "${MACHINES[@]}"; do
  read -r name ip mac ram vcpu disk <<< "${entry}"
  vm="kthw-${name}"

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
    "${KTHW_DIR}/cloud-init/user-data.tmpl" > "${workdir}/user-data"
  sed -e "s|@HOSTNAME@|${name}|g" \
    "${KTHW_DIR}/cloud-init/meta-data.tmpl" > "${workdir}/meta-data"
  seed="${LIBVIRT_IMG_DIR}/${vm}-seed.iso"
  sudo cloud-localds "${seed}" "${workdir}/user-data" "${workdir}/meta-data"
  rm -rf "${workdir}"

  log "[${name}] virt-install (ip=${ip}, mac=${mac}, ram=${ram}M, vcpu=${vcpu})"
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

log "Waiting for SSH on each VM (cloud-init takes ~60–90s on first boot)..."
for entry in "${MACHINES[@]}"; do
  read -r name ip _ _ _ _ <<< "${entry}"
  for i in {1..60}; do
    if ssh -F "${KTHW_DIR}/ssh-config" \
         -o ConnectTimeout=2 -o BatchMode=yes \
         "${name}" 'test -f /etc/kthw-ready' 2>/dev/null; then
      ok "[${name}] ready (${ip})"
      break
    fi
    sleep 3
    if [[ ${i} -eq 60 ]]; then
      warn "[${name}] still not ready after 3min — check 'virsh console kthw-${name}'"
    fi
  done
done

cat <<EOF

$(ok "Lab is up. Summary:")

  jumpbox    10.0.0.1
  server-0   10.0.0.2   (control plane)
  server-1   10.0.0.3   (control plane)
  server-2   10.0.0.4   (control plane)
  node-0     10.0.0.5   (worker)
  node-1     10.0.0.6   (worker)
  lb-0       10.0.0.7   (load balancer)

Connect:
  ssh -F ${KTHW_DIR}/ssh-config jumpbox

Then start KTHW v1.32 from chapter 04.
EOF
