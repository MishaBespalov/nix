#!/usr/bin/env bash
# Bootstrap a 3-cp + 2-worker HA Kubernetes cluster on the kubeadm lab VMs.
#
# Flow:
#   1. Pre-pull kube-vip image on every control-plane node.
#   2. Drop kube-vip static-pod manifest on cp-0.
#   3. kubeadm init on cp-0 (controlPlaneEndpoint = VIP).
#   4. Generate join command + control-plane cert key.
#   5. For cp-1, cp-2: drop kube-vip manifest, kubeadm join --control-plane.
#   6. For wk-0, wk-1: kubeadm join (worker).
#   7. Apply Calico CNI.
#   8. Copy admin.conf back to repo as ./admin.conf for use from the host.
#
# Idempotent: checks /etc/kubernetes/{admin,kubelet}.conf to skip already-joined nodes.

source "$(dirname "$0")/lib.sh"

CONFIG_DIR="${KUBEADM_DIR}/.bootstrap"
mkdir -p "${CONFIG_DIR}"

# --- Preflight ---------------------------------------------------------------

for entry in "${MACHINES[@]}"; do
  read -r name _ _ _ _ _ _ <<< "${entry}"
  if ! ssh_root "${name}" 'test -f /etc/kubeadm-ready' 2>/dev/null; then
    err "[${name}] not reachable or cloud-init not finished — run ./provision.sh first"
    exit 1
  fi
done
ok "All 5 VMs reachable and cloud-init complete"

# --- Templates ---------------------------------------------------------------

render_kube_vip_manifest() {
  # Heredoc is unquoted so ${KUBE_VIP_VERSION} / ${CONTROL_PLANE_VIP} expand.
  # Keep the rest free of $ and backticks (they'd run as command substitutions).
  # Why super-admin.conf and not admin.conf: in k8s 1.29+ kubeadm split these.
  # admin.conf's user (kubernetes-admin) only gets cluster-admin via a CRB
  # created late in kubeadm init. During wait-control-plane, kube-vip with
  # admin.conf gets "leases.coordination.k8s.io forbidden", never claims the
  # VIP, and init times out. super-admin.conf's user is in system:masters
  # (hardcoded cluster-admin) so it works from the first second.
  cat <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: kube-vip
  namespace: kube-system
spec:
  hostNetwork: true
  containers:
  - name: kube-vip
    image: ghcr.io/kube-vip/kube-vip:${KUBE_VIP_VERSION}
    imagePullPolicy: IfNotPresent
    args: ["manager"]
    env:
    - { name: vip_arp,             value: "true" }
    - { name: port,                value: "6443" }
    - { name: vip_interface,       value: "enp1s0" }
    - { name: vip_cidr,            value: "32" }
    - { name: cp_enable,           value: "true" }
    - { name: cp_namespace,        value: "kube-system" }
    - { name: vip_ddns,            value: "false" }
    - { name: svc_enable,          value: "false" }
    - { name: vip_leaderelection,  value: "true" }
    - { name: vip_leaseduration,   value: "5" }
    - { name: vip_renewdeadline,   value: "3" }
    - { name: vip_retryperiod,     value: "1" }
    - { name: address,             value: "${CONTROL_PLANE_VIP}" }
    # kube-vip 0.8 requires a non-empty node identity for leader election
    # ("ID cannot be empty" fatal otherwise). spec.nodeName is the canonical
    # source for static pods; HOSTNAME alone isn't picked up.
    - name: vip_nodename
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
    securityContext:
      capabilities:
        add: [NET_ADMIN, NET_RAW, SYS_TIME]
    volumeMounts:
    # Container-side path is /etc/kubernetes/admin.conf because that is the
    # default of kube-vip's --k8sConfigPath; if we put it elsewhere kube-vip
    # falls back to in-cluster config (which does not exist yet) and dies.
    # Host-side path is super-admin.conf — see comment above the heredoc.
    - { mountPath: /etc/kubernetes/admin.conf, name: kubeconfig }
  hostAliases:
  - { ip: 127.0.0.1, hostnames: [kubernetes] }
  volumes:
  - name: kubeconfig
    hostPath: { path: /etc/kubernetes/super-admin.conf, type: FileOrCreate }
EOF
}

render_kubeadm_config() {
  local advertise_ip="$1"
  cat <<EOF
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: ${advertise_ip}
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///var/run/containerd/containerd.sock
---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: ${K8S_FULL_VERSION}
controlPlaneEndpoint: "${CONTROL_PLANE_ENDPOINT}"
networking:
  podSubnet: ${POD_CIDR}
  serviceSubnet: ${SERVICE_CIDR}
apiServer:
  certSANs:
  - ${CONTROL_PLANE_VIP}
  - 10.0.1.11
  - 10.0.1.12
  - 10.0.1.13
  - cp-0
  - cp-1
  - cp-2
  - kubernetes
  - kubernetes.default
  - kubernetes.default.svc
  - kubernetes.default.svc.cluster.local
EOF
}

# --- Pre-pull kube-vip image on every control-plane node ---------------------

for cp in cp-0 cp-1 cp-2; do
  log "[${cp}] pre-pulling kube-vip image"
  ssh_root "${cp}" "ctr -n k8s.io image pull ghcr.io/kube-vip/kube-vip:${KUBE_VIP_VERSION}" >/dev/null
done
ok "kube-vip image pulled on all control-plane nodes"

# --- Initialize cp-0 ---------------------------------------------------------

if ssh_root cp-0 'test -f /etc/kubernetes/admin.conf' 2>/dev/null; then
  ok "[cp-0] already initialized — skipping kubeadm init"
else
  log "[cp-0] dropping kube-vip static-pod manifest"
  render_kube_vip_manifest > "${CONFIG_DIR}/kube-vip.yaml"
  ssh_root cp-0 'mkdir -p /etc/kubernetes/manifests'
  scp -F "${KUBEADM_DIR}/ssh-config" -q \
    "${CONFIG_DIR}/kube-vip.yaml" "root@cp-0:/etc/kubernetes/manifests/kube-vip.yaml"

  log "[cp-0] writing kubeadm config"
  render_kubeadm_config "10.0.1.11" > "${CONFIG_DIR}/kubeadm-cp-0.yaml"
  scp -F "${KUBEADM_DIR}/ssh-config" -q \
    "${CONFIG_DIR}/kubeadm-cp-0.yaml" "root@cp-0:/root/kubeadm-config.yaml"

  log "[cp-0] kubeadm init (this is the slow step, ~60–90s)"
  # --skip-phases=addon/kube-proxy: Cilium below replaces kube-proxy with its
  # eBPF datapath. Skipping here avoids installing a kube-proxy DaemonSet we
  # would only have to delete and means no iptables KUBE-* chains ever exist.
  ssh_root cp-0 'kubeadm init --skip-phases=addon/kube-proxy --config=/root/kubeadm-config.yaml --upload-certs'
  ok "[cp-0] initialized"
fi

# --- Generate fresh join material -------------------------------------------

log "Generating fresh join token + control-plane cert key"
JOIN_WORKER="$(ssh_root cp-0 'kubeadm token create --ttl 2h --print-join-command' 2>/dev/null | tr -d '\r')"
CERT_KEY="$(ssh_root cp-0 'kubeadm init phase upload-certs --upload-certs 2>/dev/null | tail -n1' | tr -d '\r')"

if [[ -z "${JOIN_WORKER}" || -z "${CERT_KEY}" ]]; then
  err "Failed to capture join token or cert key from cp-0"
  exit 1
fi
ok "Join material ready"

JOIN_CP="${JOIN_WORKER} --control-plane --certificate-key ${CERT_KEY}"

# Pull cp-0's super-admin.conf so we can seed it on cp-1/cp-2 before kube-vip
# starts there. `kubeadm join --control-plane` does NOT generate this file
# (only `kubeadm init` does), and our kube-vip manifest's hostPath points at
# it. Without seeding, kubelet would create an empty file via FileOrCreate
# and kube-vip would crashloop with "no configuration has been provided".
log "Fetching super-admin.conf from cp-0 for joiner seeding"
scp -F "${KUBEADM_DIR}/ssh-config" -q \
  "root@cp-0:/etc/kubernetes/super-admin.conf" "${CONFIG_DIR}/super-admin.conf"
chmod 0600 "${CONFIG_DIR}/super-admin.conf"

# --- Join cp-1 and cp-2 ------------------------------------------------------

for cp in cp-1 cp-2; do
  if ssh_root "${cp}" 'test -f /etc/kubernetes/kubelet.conf' 2>/dev/null; then
    ok "[${cp}] already joined — skipping"
    continue
  fi

  log "[${cp}] seeding super-admin.conf (for kube-vip)"
  ssh_root "${cp}" 'mkdir -p /etc/kubernetes/manifests'
  scp -F "${KUBEADM_DIR}/ssh-config" -q \
    "${CONFIG_DIR}/super-admin.conf" "root@${cp}:/etc/kubernetes/super-admin.conf"
  ssh_root "${cp}" 'chmod 0600 /etc/kubernetes/super-admin.conf'

  log "[${cp}] dropping kube-vip static-pod manifest"
  scp -F "${KUBEADM_DIR}/ssh-config" -q \
    "${CONFIG_DIR}/kube-vip.yaml" "root@${cp}:/etc/kubernetes/manifests/kube-vip.yaml"

  log "[${cp}] kubeadm join --control-plane"
  ssh_root "${cp}" "${JOIN_CP}"
  ok "[${cp}] joined as control-plane"
done

# --- Join workers ------------------------------------------------------------

for wk in wk-0 wk-1; do
  if ssh_root "${wk}" 'test -f /etc/kubernetes/kubelet.conf' 2>/dev/null; then
    ok "[${wk}] already joined — skipping"
    continue
  fi
  log "[${wk}] kubeadm join (worker)"
  ssh_root "${wk}" "${JOIN_WORKER}"
  ok "[${wk}] joined as worker"
done

# --- Pull admin.conf back to host -------------------------------------------

log "Copying admin.conf to ${KUBEADM_DIR}/admin.conf"
scp -F "${KUBEADM_DIR}/ssh-config" -q "root@cp-0:/etc/kubernetes/admin.conf" "${KUBEADM_DIR}/admin.conf"
# Rewrite server URL: admin.conf points at VIP which works from the cluster but
# may also work from the host (libvirt NAT has return route). Keep VIP.
chmod 0600 "${KUBEADM_DIR}/admin.conf"

# --- Install Cilium CNI (kube-proxy replacement, native routing) ------------
# Why these settings:
#   ipam.mode=kubernetes        — use the per-node podCIDR kubeadm allocates
#   kubeProxyReplacement=true   — eBPF replaces kube-proxy entirely (we skipped
#                                 kube-proxy in kubeadm init above)
#   k8sServiceHost/Port         — bootstrap path: Cilium needs to reach the
#                                 apiserver before its own service routing is
#                                 active, so we point it at the VIP directly
#   routingMode=native + autoDirectNodeRoutes=true — all 5 VMs are on one L2
#                                 (10.0.1.0/24) so we don't need encap; Cilium
#                                 installs kernel routes for each node's pod
#                                 CIDR via the node's own IP. Pod packets cross
#                                 the libvirt bridge with their real pod IP.

if ! ssh_root cp-0 'command -v cilium' &>/dev/null; then
  log "Installing cilium-cli ${CILIUM_CLI_VERSION} on cp-0"
  ssh_root cp-0 "set -e; cd /tmp; \
    curl -fsSL --retry 3 -o cilium-cli.tgz \
      'https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-amd64.tar.gz'; \
    tar -xzf cilium-cli.tgz -C /usr/local/bin cilium; \
    rm -f cilium-cli.tgz"
fi

if ssh_root cp-0 'KUBECONFIG=/etc/kubernetes/admin.conf cilium status --wait=false 2>/dev/null | grep -q "Cilium:.*OK"'; then
  ok "Cilium already installed — skipping"
else
  log "Installing Cilium ${CILIUM_VERSION} (kube-proxy replacement, native routing)"
  ssh_root cp-0 "KUBECONFIG=/etc/kubernetes/admin.conf cilium install \
    --version ${CILIUM_VERSION} \
    --set ipam.mode=kubernetes \
    --set kubeProxyReplacement=true \
    --set k8sServiceHost=${CONTROL_PLANE_VIP} \
    --set k8sServicePort=6443 \
    --set routingMode=native \
    --set ipv4NativeRoutingCIDR=${POD_CIDR} \
    --set autoDirectNodeRoutes=true \
    --set ipv4.enabled=true \
    --set ipv6.enabled=false"
  ok "Cilium installed"
fi

log "Waiting for Cilium to report healthy"
ssh_root cp-0 "KUBECONFIG=/etc/kubernetes/admin.conf cilium status --wait" >/dev/null
ok "Cilium healthy"

# --- Wait for nodes Ready ----------------------------------------------------

log "Waiting for all 5 nodes to become Ready (Cilium agents finish init ~30s)"
for i in {1..60}; do
  ready=$(ssh_root cp-0 "kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes --no-headers 2>/dev/null | awk '\$2==\"Ready\"' | wc -l")
  if [[ "${ready}" -eq 5 ]]; then
    ok "All 5 nodes Ready"
    break
  fi
  sleep 3
  if [[ ${i} -eq 60 ]]; then
    warn "Only ${ready}/5 nodes Ready after 3min — investigate with: kubectl get nodes -o wide"
  fi
done

# --- Summary -----------------------------------------------------------------

cat <<EOF

$(ok "Cluster bootstrapped.")

Use from this host:
  export KUBECONFIG=${KUBEADM_DIR}/admin.conf
  kubectl get nodes -o wide
  kubectl get pods -A

Or from cp-0:
  ssh -F ${KUBEADM_DIR}/ssh-config root@cp-0
  kubectl get nodes

VIP: ${CONTROL_PLANE_VIP} (currently held by whichever cp is leader; survives single-node loss)

EOF
