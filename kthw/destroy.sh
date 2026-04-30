#!/usr/bin/env bash
# Tear down the entire KTHW lab. Optional --keep-base preserves the base image
# (saves a re-download on the next ./provision.sh).

source "$(dirname "$0")/lib.sh"

KEEP_BASE=false
[[ "${1:-}" == "--keep-base" ]] && KEEP_BASE=true

# --- Confirm -----------------------------------------------------------------

read -rp "Destroy all 7 KTHW VMs, their disks, and the 'kthw' network? [y/N] " ans
[[ "${ans,,}" == "y" ]] || { warn "Aborted."; exit 1; }

# --- VMs ---------------------------------------------------------------------

for entry in "${MACHINES[@]}"; do
  read -r name _ _ _ _ _ <<< "${entry}"
  vm="kthw-${name}"
  if virsh -c "${LIBVIRT_CONN}" dominfo "${vm}" &>/dev/null; then
    log "[${name}] destroy + undefine"
    virsh -c "${LIBVIRT_CONN}" destroy "${vm}" 2>/dev/null || true
    virsh -c "${LIBVIRT_CONN}" undefine "${vm}" --remove-all-storage --nvram 2>/dev/null || \
      virsh -c "${LIBVIRT_CONN}" undefine "${vm}" --remove-all-storage
    sudo rm -f "${LIBVIRT_IMG_DIR}/${vm}-seed.iso"
    ok  "[${name}] gone"
  fi
done

# --- Network -----------------------------------------------------------------

if virsh -c "${LIBVIRT_CONN}" net-info "${LIBVIRT_NET}" &>/dev/null; then
  log "Removing libvirt network '${LIBVIRT_NET}'"
  virsh -c "${LIBVIRT_CONN}" net-destroy "${LIBVIRT_NET}" 2>/dev/null || true
  virsh -c "${LIBVIRT_CONN}" net-undefine "${LIBVIRT_NET}"
  ok "Network removed"
fi

# --- Base image --------------------------------------------------------------

if ! ${KEEP_BASE} && sudo test -f "${BASE_IMAGE}"; then
  log "Removing base image"
  sudo rm -f "${BASE_IMAGE}"
fi

ok "Lab torn down."
