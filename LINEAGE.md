# Lineage — `podmesh-installer`

## Origin and Formalization

- **Repository**: `xavdp-pro/podmesh-installer`
- **Formalized Version**: `v2.3.0`
- **Formalization Date**: `2026-10-27`
- **Upstream Source**: Formalized from `/home/zaza/Bureau/REMOTE3/CURRENT/PODMESH-INSTALLER-DEBIAN13/` under the **SHAPER PHOENIX** canonical structure.
- **Companion Laboratory Repository**: `xavdp-pro/podmesh-installer-lab` (private validation reports, Flutter/SPICE visual proofs, and Council Review synthesis for bare-metal installer architecture).

## Evolution Milestones

1. **Multi-Agent Council Architectural Synthesis (2026-10-25)**
   - Established the bare-metal appliance doctrine combining Debian 13 (Trixie, Linux 6.12), redundant GPT/EFI boot partitions, Btrfs RAID1/RAID0/RAID5/6 storage pools with dedicated `@root`, `@var_shaper`, `@meshfs_cas`, and `@pmbs_backups` subvolumes, and zero-open-port WireGuard bootstrap (`GEM-001`).
2. **Flutter Linux GUI + Python IPC Daemon + QEMU/SPICE Harness (2026-10-25 — 2026-10-27)**
   - Implemented `backend/podmesh_installerd.py` (`AF_UNIX` JSON daemon), `podmesh_installer_ui/` (4-step Flutter Linux native desktop wizard), `qemu-spice-test/qemu_spice_harness.py` (dual-disk 20 GiB VirtIO QEMU/SPICE/QMP testbench), and MeshFS P2P 4 MiB CAS replication engines (`backend/meshfs_p2p_engine.py`, `backend/meshfs_pool_orchestrator.py`).
3. **SHAPER PHOENIX Canonical Release (`v2.3.0`, 2026-10-27)**
   - Packaged into `xavdp-pro/podmesh-installer` (`v2.3.0` / `2.3.0+1`) with strict `.gitignore` hygiene (excluding `.qcow2`, `.iso`, `build/`, `.dart_tool/`) and paired with `xavdp-pro/podmesh-installer-lab`.
