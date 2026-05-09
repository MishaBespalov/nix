# Shared definitions for kubeadm lab scripts.
# Sourced by download-image.sh, provision.sh, bootstrap.sh, destroy.sh.
# shellcheck shell=bash

set -euo pipefail

# --- Paths -------------------------------------------------------------------

KUBEADM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIBVIRT_IMG_DIR="/var/lib/libvirt/images"
BASE_IMAGE="${LIBVIRT_IMG_DIR}/kubeadm-debian12-base.qcow2"

# Same Debian 12 generic cloud image as kthw — kept separate to decouple labs.
DEBIAN_IMAGE_URL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"

LIBVIRT_NET="kubeadm"
LIBVIRT_CONN="qemu:///system"

SSH_KEY_PATH="${HOME}/.ssh/kubeadm_ed25519"
SSH_PUB_PATH="${SSH_KEY_PATH}.pub"

# --- Cluster constants -------------------------------------------------------

K8S_VERSION="1.32"               # apt repo channel (pkgs.k8s.io/...:v1.32)
K8S_FULL_VERSION="v1.32.0"       # kubeadm --kubernetes-version
KUBE_VIP_VERSION="v0.8.7"
CALICO_VERSION="v3.28.2"

CONTROL_PLANE_VIP="10.0.1.10"
CONTROL_PLANE_ENDPOINT="${CONTROL_PLANE_VIP}:6443"
POD_CIDR="10.244.0.0/16"
SERVICE_CIDR="10.96.0.0/12"

# --- Machine table -----------------------------------------------------------
# Format: NAME IP MAC RAM_MB VCPU DISK_GB ROLE
# IPs/MACs MUST match network.xml's static DHCP reservations.
# ROLE ∈ {cp, worker} — drives bootstrap.sh.

MACHINES=(
  "cp-0 10.0.1.11 52:54:00:22:00:11 2560 2 20 cp"
  "cp-1 10.0.1.12 52:54:00:22:00:12 2560 2 20 cp"
  "cp-2 10.0.1.13 52:54:00:22:00:13 2560 2 20 cp"
  "wk-0 10.0.1.21 52:54:00:22:00:21 3072 2 25 worker"
  "wk-1 10.0.1.22 52:54:00:22:00:22 3072 2 25 worker"
)

# --- Helpers -----------------------------------------------------------------

err()  { printf '\033[31m[err]\033[0m  %s\n' "$*" >&2; }
log()  { printf '\033[36m[..]\033[0m   %s\n' "$*"; }
ok()   { printf '\033[32m[ok]\033[0m   %s\n' "$*"; }
warn() { printf '\033[33m[!!]\033[0m   %s\n' "$*"; }

ensure_ssh_key() {
  if [[ ! -f "${SSH_KEY_PATH}" ]]; then
    log "Generating dedicated SSH keypair: ${SSH_KEY_PATH}"
    ssh-keygen -t ed25519 -N '' -C "kubeadm-lab" -f "${SSH_KEY_PATH}"
    ok  "SSH key created"
  fi
}

# Run a command on a remote VM as root via the lab's ssh-config.
ssh_root() {
  local host="$1"; shift
  ssh -F "${KUBEADM_DIR}/ssh-config" "root@${host}" "$@"
}
