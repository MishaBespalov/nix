# Shared definitions for KTHW lab scripts.
# Sourced by download-image.sh, provision.sh, destroy.sh.
# shellcheck shell=bash

set -euo pipefail

# --- Paths -------------------------------------------------------------------

KTHW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIBVIRT_IMG_DIR="/var/lib/libvirt/images"
BASE_IMAGE="${LIBVIRT_IMG_DIR}/kthw-debian12-base.qcow2"

# Official Debian 12 generic cloud image (amd64).
# 'generic' supports multiple datasources (NoCloud, EC2, etc.) — we use NoCloud.
DEBIAN_IMAGE_URL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"

LIBVIRT_NET="kthw"
LIBVIRT_CONN="qemu:///system"

SSH_KEY_PATH="${HOME}/.ssh/kthw_ed25519"
SSH_PUB_PATH="${SSH_KEY_PATH}.pub"

# --- Machine table -----------------------------------------------------------
# Format: NAME IP MAC RAM_MB VCPU DISK_GB
# IPs/MACs MUST match network.xml's static DHCP reservations.

MACHINES=(
  "jumpbox  10.0.0.1  52:54:00:11:00:01  1024  1  10"
  "server-0 10.0.0.2  52:54:00:11:00:02  2048  2  15"
  "server-1 10.0.0.3  52:54:00:11:00:03  2048  2  15"
  "server-2 10.0.0.4  52:54:00:11:00:04  2048  2  15"
  "node-0   10.0.0.5  52:54:00:11:00:05  2560  2  20"
  "node-1   10.0.0.6  52:54:00:11:00:06  2560  2  20"
  "lb-0     10.0.0.7  52:54:00:11:00:07  512   1  5"
)

# --- Helpers -----------------------------------------------------------------

err()  { printf '\033[31m[err]\033[0m  %s\n' "$*" >&2; }
log()  { printf '\033[36m[..]\033[0m   %s\n' "$*"; }
ok()   { printf '\033[32m[ok]\033[0m   %s\n' "$*"; }
warn() { printf '\033[33m[!!]\033[0m   %s\n' "$*"; }

ensure_ssh_key() {
  if [[ ! -f "${SSH_KEY_PATH}" ]]; then
    log "Generating dedicated SSH keypair: ${SSH_KEY_PATH}"
    ssh-keygen -t ed25519 -N '' -C "kthw-lab" -f "${SSH_KEY_PATH}"
    ok  "SSH key created"
  fi
}
