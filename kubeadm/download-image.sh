#!/usr/bin/env bash
# Download the Debian 12 cloud image for the kubeadm lab. Idempotent.

source "$(dirname "$0")/lib.sh"

if sudo test -f "${BASE_IMAGE}"; then
  ok "Base image already present at ${BASE_IMAGE}"
  exit 0
fi

log "Downloading Debian 12 generic cloud image (~700MB)..."
log "  URL : ${DEBIAN_IMAGE_URL}"
log "  Dest: ${BASE_IMAGE}"

TMP_IMAGE="/tmp/kubeadm-debian12-base.qcow2.$$"
trap 'rm -f "${TMP_IMAGE}"' EXIT

curl -fL --progress-bar -o "${TMP_IMAGE}" "${DEBIAN_IMAGE_URL}"

log "Moving into libvirt storage pool..."
sudo mv "${TMP_IMAGE}" "${BASE_IMAGE}"
sudo chown qemu:qemu "${BASE_IMAGE}" 2>/dev/null || sudo chown root:libvirtd "${BASE_IMAGE}"
sudo chmod 0644 "${BASE_IMAGE}"

ok "Base image ready"
