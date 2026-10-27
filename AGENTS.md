# Agents: Working in `podmesh-installer`

> **🤖 AI-First Installation & Configuration Mandate**:
> Bare-metal and VM appliance provisioning via `podmesh-installer` is 100% AI-First and headless-capable over the Unix Domain Socket JSON IPC (`/tmp/podmesh-installer.sock`), without requiring the graphical Flutter UI.
> 👉 **Autonomous AI Agents: Read [`AI_INSTALL_AND_CONFIG.md`](AI_INSTALL_AND_CONFIG.md) first for deterministic headless disk scanning, GPT/EFI/Btrfs RAID partitioning, and installation protocols.**

`podmesh-installer` follows the SHAPER PHOENIX public/private repository split for human–AI tandems.

Dialogue with the operator may be in French; **all canonical documentation, commit messages, and new code comments in this repository MUST be written in English (`en-US`)**.

## Repository Split

| Where | What belongs there | What never goes there |
| --- | --- | --- |
| **`xavdp-pro/podmesh-installer`** (this repository, public) | Backend installer daemon (`backend/podmesh_installerd.py`), MeshFS P2P CAS orchestrators (`backend/meshfs_*.py`), Flutter Linux UI source (`podmesh_installer_ui/lib/`, `linux/`, `pubspec.yaml`), QEMU/SPICE automation harness (`qemu-spice-test/qemu_spice_harness.py`), and canonical governance (`INTENT.md`, `LAW.md`, `LINEAGE.md`, `AGENTS.md`, `README.md`, `DEDICATION.md`, `LICENSE`) | Virtual disk images (`*.qcow2`), ISO images (`*.iso`), Flutter `build/` and `.dart_tool/` directories, laboratory qualification narratives, or secrets |
| **`xavdp-pro/podmesh-installer-lab`** (private companion) | Validation reports (`RAPPORT_VALIDATION_INSTALLATEUR_FLUTTER_SPICE.md`), Council Review architectural synthesis (`COUNCIL_REVIEW_SYNTHESIS_BARE_METAL_INSTALLER.md`), SPICE screendump telemetry, and bare-metal qualification logs | Live WireGuard private keys, production credentials, or multi-gigabyte disk images |
| **The Vault** | Production WireGuard enrollment keys, signing keys, and hardware BMC/IPMI credentials | — |

## Mandatory Tandem Rules

1. **Never Commit Disk Images or Build Directories**: Always verify `git status` before committing to ensure `*.qcow2`, `*.iso`, `build/`, and `.dart_tool/` remain untracked.
2. **Preserve Partitioning & Subvolume Invariants (`LAW.md`)**: Keep the canonical Btrfs subvolume layout (`@root`, `@var_shaper`, `@meshfs_cas`, `@pmbs_backups`) and redundant EFI boot design intact across both the Python backend and Flutter UI.
3. **Test in QEMU/SPICE First**: Validate any installer flow change using `qemu-spice-test/qemu_spice_harness.py` before bare-metal execution, and record the resulting evidence in `xavdp-pro/podmesh-installer-lab`.
