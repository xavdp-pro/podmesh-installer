# AI-First Headless Bare-Metal Appliance Provisioning Protocol — `podmesh-installer` (v2.3.0)

> **Core Directive for Autonomous AI Agents**:
> `podmesh-installer` is architected so that an AI agent can provision a bare-metal or virtualized Debian 13 (Trixie) appliance **100% headlessly via Unix Domain Socket JSON IPC (`/tmp/podmesh-installer.sock`)**, without needing a graphical display or the Flutter UI (`podmesh_installer_ui`).
> The graphical Flutter UI is strictly an optional client of the same Unix socket daemon (`backend/podmesh_installerd.py`).

---

## 1. Operational Invariants for AI Agents (`LAW.md`)

1. **Explicit Disk Verification**: Always run `SCAN_DISKS` first and verify target block device paths, models, and sizes before issuing `START_INSTALL`. Never guess `/dev/sda` or `/dev/nvme0n1`.
2. **Canonical Btrfs Subvolume Layout**:
   - `@root` ➔ `/` (`zstd:3`)
   - `@var_shaper` ➔ `/var/run/shaper` (`zstd:1`)
   - `@meshfs_cas` ➔ `/var/lib/meshfs/cas` (`zstd:3`)
   - `@pmbs_backups` ➔ `/var/lib/pmbs/snapshots` (`zstd:6`)
3. **Dual-EFI Redundancy**: When `raid_profile` is `RAID1`, `RAID5`, or `RAID6`, the 1024 MB FAT32 EFI System Partition and 2048 MB `/boot` partition are mirrored across all selected disks so the node boots even if the primary drive fails.
4. **Rule 38 Bounded Retry ($k \le 2$)**: If disk scanning or installation encounters an error (`"status": "ERROR"`), halt immediately and report the exact daemon log entries.

---

## 2. Starting the Headless Installer Daemon

On the live installer environment (or target qualification VM):

```bash
python3 backend/podmesh_installerd.py &
```

Wait for the Unix socket `/tmp/podmesh-installer.sock` to appear:

```bash
for i in $(seq 1 20); do
  [ -S /tmp/podmesh-installer.sock ] && break
  sleep 0.2
done
```

---

## 3. AI-Driven JSON IPC Protocol (`/tmp/podmesh-installer.sock`)

The daemon accepts newline-delimited JSON commands (`{"command": "...", ...}\n`) over `/tmp/podmesh-installer.sock` and responds with a single-line JSON object.

### 3.1 Helper Function for AI Agents (Python / Bash)

```bash
installer_rpc() {
  python3 -c '
import socket, sys, json
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect("/tmp/podmesh-installer.sock")
s.sendall((sys.argv[1] + "\n").encode("utf-8"))
resp = b""
while not resp.endswith(b"\n"):
    chunk = s.recv(4096)
    if not chunk: break
    resp += chunk
print(resp.decode("utf-8").strip())
' "$1"
}
```

### 3.2 Step 1 — Scan Available Hardware Disks (`SCAN_DISKS`)

```bash
installer_rpc '{"command": "SCAN_DISKS"}' | jq .
```

Example JSON response:

```json
{
  "status": "ok",
  "data": [
    {
      "name": "vda",
      "path": "/dev/vda",
      "size_bytes": 21474836480,
      "size_gb": 20.0,
      "model": "VirtIO/QEMU Disk",
      "transport": "virtio",
      "rotational": false
    },
    {
      "name": "vdb",
      "path": "/dev/vdb",
      "size_bytes": 21474836480,
      "size_gb": 20.0,
      "model": "VirtIO/QEMU Disk",
      "transport": "virtio",
      "rotational": false
    }
  ]
}
```

### 3.3 Step 2 — Launch Non-Interactive Installation (`START_INSTALL`)

```bash
installer_rpc '{
  "command": "START_INSTALL",
  "config": {
    "selected_disks": ["/dev/vda", "/dev/vdb"],
    "raid_profile": "RAID1",
    "hostname": "podmesh-node-01",
    "cluster_role": "MASTER",
    "wireguard_join_key": "wg-join-key-placeholder"
  }
}' | jq .
```

### 3.4 Step 3 — Poll Progress Until `SUCCESS` (`GET_STATE`)

```bash
while true; do
  STATE="$(installer_rpc '{"command": "GET_STATE"}')"
  STATUS="$(echo "$STATE" | jq -r '.data.status')"
  PCT="$(echo "$STATE" | jq -r '.data.progress_percent')"
  STEP="$(echo "$STATE" | jq -r '.data.current_step')"
  echo "[${PCT}%] ${STATUS}: ${STEP}"
  if [ "$STATUS" = "SUCCESS" ]; then
    echo "$STATE" | jq .
    break
  elif [ "$STATUS" = "ERROR" ]; then
    echo "$STATE" | jq . >&2
    exit 1
  fi
  sleep 1
done
```

---

## 4. Automated QEMU/SPICE Pre-Production Qualification

Before running on physical iron, AI agents can execute the full end-to-end automated QEMU/SPICE verification harness:

```bash
python3 qemu-spice-test/qemu_spice_harness.py
```
