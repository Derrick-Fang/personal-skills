---
name: network-resource-audit
description: Audit a machine's real network resources — interfaces, NIC hardware, link speed, bonding, RDMA, PCIe topology, NUMA affinity, and GPU-NIC topology — then draw a labeled network resource map with theoretical bandwidth on every edge. Works on Linux and macOS. Use when the user gets a new server, wants to check / audit / 检查 network resources / 网络资源 / 网卡 / RDMA / NCCL topology of a machine, wants to diagnose whether network bandwidth is a bottleneck, or asks to draw a server network topology / bandwidth map (服务器网络资源图).
---

# Network Resource Audit

Fixed checklist for any new machine. Run every step, record results, and finish by drawing a **network resource map** with *theoretical* bandwidth on each edge.

Commands are given for **Linux** (primary) and **macOS** (equivalent, where available). If a capability doesn't exist on the OS (e.g. RDMA on macOS), state "N/A" explicitly rather than skipping silently.

## Step 1 — Network interfaces

```bash
# Linux
ip -br link
ip -br addr
# macOS
networksetup -listallhardwareports
ifconfig -a | grep -E '^[a-z]|flags|status'
```

Record: interface names, state (UP/DOWN), IP. Note inactive/down interfaces too.

## Step 2 — NIC hardware

```bash
# Linux
lspci | grep -Ei 'Ethernet|InfiniBand|Network'
# macOS
system_profiler SPNetworkDataType | grep -E 'Hardware Port|Device|BSD Device|Type'
system_profiler SPEthernetDataType 2>/dev/null
# Thunderbolt / USB NICs on macOS
system_profiler SPThunderboltDataType SPUSBDataType
```

Record: vendor/model (e.g. Mellanox CX-6, Intel E810), count of ports. Match each PCI NIC to its interface (`ls /sys/class/net/<iface>/device` on Linux).

## Step 3 — Actual link speed

```bash
# Linux
ethtool <iface>            # look at "Speed:", "Duplex", "Link detected"
# macOS
ifconfig <iface> | grep media
networksetup -getMedia <iface> 2>/dev/null
```

Record negotiated speed per interface. A 100G-capable NIC negotiating at 25G is a finding, not a detail — check cable/QSFP/switch port config.

## Step 4 — Bond / LACP

```bash
# Linux
ls /proc/net/bonding/ 2>/dev/null
cat /proc/net/bonding/<bond>     # mode (802.3ad / active-backup), slaves, MII status
# macOS — bonds are created via Virtual Interface; usually N/A on servers
ifconfig bond0 2>/dev/null
```

Record: bonding mode, member interfaces, all members UP. For 802.3ad confirm the switch side is LACP-configured.

## Step 5 — RDMA / InfiniBand

```bash
# Linux
rdma link                       # state ACTIVE, physical_state LINK_UP
ibv_devinfo                     # GID table, port speed, active_mtu
ibstat 2>/dev/null | grep -E 'Rate|State'
# RoCE: check which netdev maps to which RDMA device
ls /sys/class/infiniband/*/ports/*/gid_attrs/ndevs/
# macOS: N/A
```

Record: RDMA device ↔ netdev mapping, port rate, RoCE version if Ethernet-based.

## Step 6 — NIC PCIe capability vs negotiated

```bash
# Linux
lspci -vv -s <NIC-PCI-ID> | grep -E 'LnkCap|LnkSta'
#   LnkCap: Port #0, Speed 16GT/s, Width x16   <- theoretical
#   LnkSta: Speed 16GT/s, Width x16            <- actual (downgrade = problem)
# macOS (built-in only, usually N/A)
system_profiler SPPCIDataType 2>/dev/null
```

Common downgrades: x16 card in x8 slot, Gen4 card in Gen3 slot, electrical/thermal lane reduction. Compute theoretical BW: Gen3 x16 ≈ 15.75 GB/s, Gen4 x16 ≈ 31.5 GB/s, Gen5 x16 ≈ 63 GB/s.

## Step 7 — NUMA affinity

```bash
# Linux
numactl -H
cat /sys/class/net/<iface>/device/numa_node
lscpu | grep -i numa
# macOS: single NUMA domain on Apple Silicon (UMA), N/A
sysctl -n hw.physicalcpu hw.ncpu
```

Rule of thumb: a NIC on NUMA node N should serve GPU/processes on node N. Cross-NUMA traffic pays the inter-socket (UPI/Infinity Fabric) penalty.

## Step 8 — GPU-NIC topology

```bash
# Linux + NVIDIA
nvidia-smi topo -m
#   Look at GPU↔NIC column: PIX/PXB (same PCIe switch, best),
#   NODE (same NUMA), SYS (cross-socket, worst)
nvidia-smi -q | grep -E 'Gpu|Product|PCI' 
# macOS: no NVIDIA discrete GPUs, N/A
```

For each GPU, note the best NIC (PIX/NODE) — NCCL should pick it automatically, but verify with `NCCL_DEBUG=INFO` logs.

## Final deliverable — network resource map

Always end by drawing the map: CPUs/NUMA at top, PCIe switches, GPUs and NICs below, network fabric, remote side. Label **every edge with theoretical bandwidth**:

```
                    ┌──────── CPU 0 ────────┐
                    │                       │
               PCIe Switch             PCIe Switch
              /    |    \                  |
           GPU0  GPU1  NIC0              GPU2...
                       │
                     100G
                       │
                   Switch
                       │
                     100G
                       │
                      NIC
                       │
                  Remote GPU

PCIe Gen4 x16    31.5 GB/s   (LnkCap x16 16GT/s, LnkSta matches ✓)
NIC              100 Gb/s = 12.5 GB/s
```

## Reporting rules

1. **Never skip silently** — mark each step OK / finding / N/A(OS).
2. **Flag mismatches**: negotiated < capable speed; PCIe LnkSta < LnkCap; GPU↔NIC = SYS when a NODE/PIX path exists.
3. **One number per edge** in the map, with units (GB/s vs Gb/s — convert explicitly, 8 Gb/s ≈ 1 GB/s).
4. End with a short bottleneck statement: "the slowest edge on the GPU→remote-GPU path is X at Y GB/s".
