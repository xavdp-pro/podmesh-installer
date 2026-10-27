# PodMesh Bare-Metal Appliance Installer (`podmesh-installer`) — v2.3.0

Autonomous Bare-Metal **Debian 13 ("Trixie") Appliance Installer** for **PodMesh / SHAPER OS**, featuring a native **Flutter Linux GUI wizard**, a **Python Unix-Socket Installer Daemon**, **MeshFS P2P 4 MiB CAS Pool Orchestrators**, and a deterministic **QEMU/KVM + SPICE + QMP automation testbench**.

---

## Architecture Overview

```text
podmesh-installer/
├── backend/
│   ├── podmesh_installerd.py        # AF_UNIX JSON installer daemon (v2.3.0)
│   ├── meshfs_p2p_engine.py         # Peer-to-peer 4 MiB SHA-256 CAS chunk engine
│   └── meshfs_pool_orchestrator.py  # 3-node replicated MeshFS pool bootstrapper
├── podmesh_installer_ui/            # Native Flutter Linux Desktop GUI (v2.3.0+1)
│   ├── lib/main.dart                # 4-step dark-mode appliance installation wizard
│   ├── linux/                       # GTK/C++ Linux runner for Debian 13 Live ISO
│   └── pubspec.yaml
└── qemu-spice-test/
    └── qemu_spice_harness.py        # Dual-disk VirtIO QEMU + SPICE (:5930) + QMP harness
```

---

## Canonical Storage & Partitioning Layout

When `podmesh_installerd.py` executes `plan_partitioning(disks, raid_profile)`, each target disk is formatted with a redundant GPT layout and a Btrfs pool configured with the selected RAID profile (`RAID1` default, `RAID0`, `RAID5`, `RAID6`, or `SINGLE`):

1. **Partition 1 — EFI System Partition (ESP)**: `1024 MiB` FAT32, mirrored across all selected disks for hardware boot failover.
2. **Partition 2 — `/boot`**: `2048 MiB` Btrfs `DUP` / `RAID1`.
3. **Partition 3 — Btrfs MeshFS Appliance Pool**: Remainder of disks, containing four canonical subvolumes:
   - `@root` mounted at `/` (`zstd:3`) — Debian 13 (Linux 6.12) root filesystem.
   - `@var_shaper` mounted at `/var/run/shaper` (`zstd:1`) — SHAPER FUnit Unix Domain Sockets and runtime state.
   - `@meshfs_cas` mounted at `/var/lib/meshfs/cas` (`zstd:3`) — 4 MiB SHA-256 Content-Addressable Storage pool.
   - `@pmbs_backups` mounted at `/var/lib/pmbs/snapshots` (`zstd:6`) — Deduplicated PMBS backup store.

---

## Quick Start

### 1. Run the Backend Installer Daemon
```bash
python3 backend/podmesh_installerd.py
# Listens on /tmp/podmesh-installer.sock
```

You can query or drive the daemon directly via JSON over `AF_UNIX`:
```bash
python3 -c '
import socket, json
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect("/tmp/podmesh-installer.sock")
s.sendall(b"{\"command\": \"GET_STATE\"}\n")
print(json.dumps(json.loads(s.recv(4096)), indent=2))
'
```

### 2. Build and Run the Flutter Linux Wizard
```bash
cd podmesh_installer_ui
flutter pub get
flutter build linux --release
./build/linux/x64/release/bundle/podmesh_installer_ui
```

### 3. Launch the Dual-Disk QEMU/SPICE Automation Harness
```bash
python3 qemu-spice-test/qemu_spice_harness.py launch
# Creates ephemeral 20 GiB disk_a.qcow2 & disk_b.qcow2 (ignored by Git)
# Exposes SPICE display on localhost:5930 and QMP socket at qemu-monitor.sock
```

---

## Governance & Companion Repository

- **Canonical Governance**: See [`INTENT.md`](INTENT.md), [`LAW.md`](LAW.md), [`LINEAGE.md`](LINEAGE.md), and [`AGENTS.md`](AGENTS.md).
- **Private Qualification Lab**: `xavdp-pro/podmesh-installer-lab`
- **License**: Apache-2.0 (see [`LICENSE`](LICENSE) and [`DEDICATION.md`](DEDICATION.md)).
