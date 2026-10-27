# PodMesh Bare-Metal Appliance Installer (`podmesh-installer`) — Invariant Law

Status: Binding Architectural Invariants, v2.3.0 (2026-10-27).
Scope: All backend daemon pipelines, storage partitioning plans, Flutter UI wizards, and QEMU/SPICE harnesses in `podmesh-installer`.

## Core Invariants

### LAW-1: Explicit Target Disk Verification
1. Block device discovery (`SCAN_DISKS`) MUST query hardware attributes (`NAME`, `SIZE`, `TYPE`, `MODEL`, `TRAN`, `ROTA`) via `lsblk -J -b` and restrict candidate targets strictly to whole block devices (`type == "disk"`).
2. Destructive partitioning and formatting phases (`PARTITIONING`, `FORMATTING`) MUST NEVER execute automatically on daemon startup; they require an explicit `START_INSTALL` command specifying the verified target disk list and RAID profile (`SINGLE`, `RAID0`, `RAID1`, `RAID5`, `RAID6`).

### LAW-2: EFI Dual-Mirror Redundancy & Boot Survival
1. Every multi-disk installation MUST provision a dedicated 1024 MiB FAT32 EFI System Partition (ESP) and a 2048 MiB `/boot` partition across the selected target disks.
2. GRUB EFI bootloaders MUST be installed and mirrored across all participating boot disks so that the physical failure of any single primary drive never prevents the node from booting into the surviving Btrfs mirror.

### LAW-3: Canonical Btrfs Subvolume & Compression Layout
Every PodMesh appliance pool MUST enforce the canonical Btrfs subvolume topology with tuned `zstd` compression levels:

| Subvolume | Mountpoint | Compression | Purpose |
| --- | --- | --- | --- |
| `@root` | `/` | `zstd:3` | Immutable/rollback-capable Debian 13 (Trixie) root filesystem |
| `@var_shaper` | `/var/run/shaper` | `zstd:1` | Low-latency FUnit IPC state and runtime metadata |
| `@meshfs_cas` | `/var/lib/meshfs/cas` | `zstd:3` | Content-Addressable Storage (4 MiB SHA-256 chunks) |
| `@pmbs_backups` | `/var/lib/pmbs/snapshots` | `zstd:6` | High-density deduplicated PMBS backup manifests and chunks |

### LAW-4: SPICE/QMP Deterministic Automation & Zero Image Bloat in Git
1. Any change to the installer UI or backend state machine MUST be verifiable inside the isolated QEMU/KVM + SPICE (`:5930`) + QMP (`qemu-monitor.sock`) two-disk harness before bare-metal promotion.
2. Ephemeral virtual disk images (`*.qcow2`, `*.raw`, `*.img`), live ISO builds (`*.iso`), and Flutter compilation directories (`build/`, `.dart_tool/`) MUST NEVER be committed to Git.

### LAW-5: Zero Open Public TCP Ports (`GEM-001`)
1. The installed appliance rootfs MUST NOT expose unauthenticated TCP services on public interfaces.
2. Node enrollment uses outbound/encrypted WireGuard peering and local `AF_UNIX` sockets under `/var/run/shaper`.
