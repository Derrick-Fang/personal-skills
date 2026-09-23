#!/usr/bin/env bash
# Network resource audit — auto-collect steps 1-8 (steps 9-10 need a peer machine).
# Usage: ./check-network.sh [iface]   # iface defaults to the primary default-route interface
set -u
say() { printf '\n========== %s ==========\n' "$*"; }
run() { echo "+ $*"; "$@" 2>&1 | head -40; }

OS=$(uname -s)
IFACE="${1:-}"

if [ "$OS" = Darwin ]; then
  [ -z "$IFACE" ] && IFACE=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
  say "1. Interfaces";      run networksetup -listallhardwareports
  say "2. NIC hardware";    system_profiler SPNetworkDataType SPEthernetDataType SPThunderboltDataType 2>/dev/null | grep -E 'Hardware|Device|Type|BSD|Speed' | head -40
  say "3. Link speed ($IFACE)"; ifconfig "$IFACE" | grep -E 'media|status'
  say "4. Bond/LACP";       ifconfig bond0 2>/dev/null || echo "N/A (no bond)"
  say "5. RDMA";            echo "N/A on macOS"
  say "6. NIC PCIe";        system_profiler SPPCIDataType 2>/dev/null | head -30 || echo "N/A (Apple Silicon)"
  say "7. NUMA";            echo "Apple Silicon = single UMA domain"; sysctl -n hw.memsize hw.ncpu
  say "8. GPU-NIC topo";    echo "N/A (no NVIDIA discrete GPU)"
else
  [ -z "$IFACE" ] && IFACE=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
  say "1. Interfaces";      run ip -br link; run ip -br addr
  say "2. NIC hardware";    run lspci; echo "--- filtered:"; lspci | grep -Ei 'Ethernet|InfiniBand|Network'
  say "3. Link speed ($IFACE)"; ethtool "$IFACE" 2>&1 | grep -E 'Speed|Duplex|Link detected'
  say "4. Bond/LACP"
  for b in /proc/net/bonding/*; do [ -f "$b" ] && { echo "--- $b"; grep -E 'Mode|Slave Interface|MII Status' "$b"; }; done
  say "5. RDMA";            run rdma link; ibv_devinfo 2>&1 | grep -E 'hca_id|transport|state|phys_state|rate|active_mtu' | head -30
  say "6. NIC PCIe"
  lspci | grep -Ei 'Ethernet|InfiniBand|Network' | awk '{print $1}' | while read -r p; do
    echo "--- $p"; lspci -vv -s "$p" 2>/dev/null | grep -E 'LnkCap:|LnkSta:' | head -4; done
  say "7. NUMA";            run numactl -H
  for i in /sys/class/net/*/device/numa_node; do echo "$i: $(cat "$i")"; done
  say "8. GPU-NIC topo";    command -v nvidia-smi >/dev/null && run nvidia-smi topo -m || echo "N/A (no nvidia-smi)"
fi

cat <<'EOF'

========== 9-10. Measured bandwidth (manual, needs a peer) ==========
  peer:    iperf3 -s
  here:    iperf3 -c <peer> -P 8 -t 10   ;   iperf3 -c <peer> -R -P 8
  RDMA:    ib_write_bw -d <dev>          (server) / ib_write_bw -d <dev> <peer> (client)
  NCCL:    mpirun -np <N> ... all_reduce_perf -b 8 -e 1G -f 2 -g 1   # watch busbw

Now draw the resource map: CPU/NUMA -> PCIe switch -> GPU/NIC -> fabric -> remote,
and label every edge with theoretical AND measured GB/s.
EOF
