# PodMesh Bare-Metal Appliance Installer (`podmesh-installer`) — Intent

Status: Canonical Design Intent, v2.4.1 (2026-10-27).
Owner: Xavier de Poorter. Prepared under the SHAPER PHOENIX canonical structure.

## Purpose

`podmesh-installer` is the autonomous Bare-Metal Debian 13 ("Trixie") Appliance Installer for PodMesh and SHAPER OS sovereign hosts. It combines:

1. **A Native Flutter Linux Graphical Wizard (`podmesh_installer_ui/`)**: Provides an ergonomic 4-step dark-mode appliance setup interface for human operators and SPICE-connected remote consoles.
2. **A Privileged Python Backend Daemon (`backend/podmesh_installerd.py`)**: Exposes a newline-delimited JSON IPC control plane over a local Unix Domain Socket (`/tmp/podmesh-installer.sock` / `/run/podmesh-installer.sock`), managing hardware block device discovery (`lsblk`), canonical GPT/EFI/Btrfs RAID partitioning plans, Debian 13 rootfs deployment, and out-of-the-box WireGuard + Functional Unit (`FUnit`) socket bootstrap.
3. **MeshFS Peer-to-Peer CAS Pool Bootstrap (`backend/meshfs_p2p_engine.py`, `backend/meshfs_pool_orchestrator.py`)**: Initializes replicated 4 MiB BLAKE3 content-addressable storage volumes across multi-node clusters.
4. **A Deterministic QEMU/KVM + SPICE + QMP Automation Harness (`qemu-spice-test/qemu_spice_harness.py`)**: Enables human-agent tandems to spin up multi-disk virtual appliances (`disk_a.qcow2`, `disk_b.qcow2`), inspect live graphical frames via SPICE (`:5930` / QXL), and drive keyboard/mouse/monitor interactions deterministically via QMP Unix sockets without touching production hardware.

## Architectural Objectives

- **Turnkey Sovereign Appliance Provisioning**: Transform raw bare-metal NVMe/SATA/SAS servers into hardened Debian 13 (Linux 6.12+) PodMesh nodes in a single deterministic pass.
- **Zero Public Attack Surface (`GEM-001`)**: Deploy the base operating system with zero public WAN listening TCP ports; cluster membership and control plane communications operate over encrypted WireGuard interfaces and `AF_UNIX` sockets (`/var/run/shaper`).
- **Dual-Mode Operation (Human GUI + Autonomous Agent IPC)**: Both the Flutter graphical wizard and autonomous AI testing harnesses consume the exact same JSON state machine (`GET_STATE`, `SCAN_DISKS`, `START_INSTALL`).
