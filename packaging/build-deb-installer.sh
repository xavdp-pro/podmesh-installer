#!/usr/bin/env bash
# =============================================================================
# PodMesh Bare-Metal Installer Daemon v2.4.1 — Debian 13 (Trixie) Package Builder
# Hardened under Claude Fable 5.1 & GPT-6 Astra Counter-Reviews:
#  - Enforces 0755 on ./ and OS directories
#  - Debian 13 usrmerge systemd unit (/usr/lib/systemd/system/podmesh-installerd.service)
#  - Headless Unix Domain Socket JSON IPC (/tmp/podmesh-installer.sock)
#  - Reproducible SHA-256 build via SOURCE_DATE_EPOCH
# =============================================================================
set -euo pipefail
umask 0022

PKG_NAME="podmesh-installer"
PKG_VERSION="2.4.1"
PKG_ARCH="all"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$(mktemp -d /tmp/build-${PKG_NAME}.XXXXXX)"
DIST_DIR="${ROOT_DIR}/dist"

echo "=== [Installer] Packaging Debian 13 (Trixie): ${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}.deb ==="

trap 'rm -rf "${BUILD_DIR}"' EXIT

chmod 0755 "${BUILD_DIR}"
mkdir -p -m 0755 "${BUILD_DIR}/DEBIAN"
mkdir -p -m 0755 "${BUILD_DIR}/usr" "${BUILD_DIR}/usr/sbin" "${BUILD_DIR}/usr/share" \
  "${BUILD_DIR}/usr/share/podmesh-installer" "${BUILD_DIR}/usr/lib" \
  "${BUILD_DIR}/usr/lib/systemd" "${BUILD_DIR}/usr/lib/systemd/system"
mkdir -p "${DIST_DIR}"

install -m 0755 "${ROOT_DIR}/backend/podmesh_installerd.py" "${BUILD_DIR}/usr/sbin/podmesh-installerd"
install -m 0755 "${ROOT_DIR}/backend/meshfs_p2p_engine.py" "${BUILD_DIR}/usr/share/podmesh-installer/meshfs_p2p_engine.py"
install -m 0755 "${ROOT_DIR}/backend/meshfs_pool_orchestrator.py" "${BUILD_DIR}/usr/share/podmesh-installer/meshfs_pool_orchestrator.py"

cat << 'EOF' > "${BUILD_DIR}/usr/lib/systemd/system/podmesh-installerd.service"
[Unit]
Description=PodMesh Bare-Metal Appliance Installer Daemon (AI-First Unix Socket IPC v2.4.1)
After=local-fs.target

[Service]
Type=simple
User=root
Group=root
UMask=0077
ExecStart=/usr/bin/python3 /usr/sbin/podmesh-installerd
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF
chmod 0644 "${BUILD_DIR}/usr/lib/systemd/system/podmesh-installerd.service"

INSTALLED_SIZE="$(du -sk "${BUILD_DIR}" | awk '{print $1}')"

cat << EOF > "${BUILD_DIR}/DEBIAN/control"
Package: ${PKG_NAME}
Version: ${PKG_VERSION}
Section: admin
Priority: optional
Architecture: ${PKG_ARCH}
Installed-Size: ${INSTALLED_SIZE}
Depends: python3, util-linux, btrfs-progs, systemd
Recommends: wireguard-tools, dosfstools, grub-efi-amd64-bin
Maintainer: Xavier DP <xavier@xavdp.pro>
Homepage: https://podmesh.xavdp.pro
Description: PodMesh Bare-Metal Appliance Installer Daemon (v2.4.1)
 Autonomous headless-capable Debian 13 (Trixie) bare-metal installer daemon
 controlled via AF_UNIX JSON IPC (/tmp/podmesh-installer.sock). Provisions
 redundant GPT/EFI boot partitions, Btrfs RAID pools (@root, @var_shaper,
 @meshfs_cas, @pmbs_backups), and WireGuard mesh bootstrap.
EOF
chmod 0644 "${BUILD_DIR}/DEBIAN/control"

cat << 'EOF' > "${BUILD_DIR}/DEBIAN/postinst"
#!/usr/bin/env bash
set -euo pipefail
if [ "${1:-}" = "configure" ]; then
    if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
        systemctl daemon-reload 2>/dev/null || true
        systemctl enable --now podmesh-installerd.service 2>/dev/null || true
    fi
fi
exit 0
EOF
chmod 0755 "${BUILD_DIR}/DEBIAN/postinst"

cat << 'EOF' > "${BUILD_DIR}/DEBIAN/prerm"
#!/usr/bin/env bash
set -e
if [ "${1:-}" = "remove" ]; then
    if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
        systemctl stop podmesh-installerd.service 2>/dev/null || true
        systemctl disable podmesh-installerd.service 2>/dev/null || true
    fi
    rm -f /tmp/podmesh-installer.sock 2>/dev/null || true
fi
exit 0
EOF
chmod 0755 "${BUILD_DIR}/DEBIAN/prerm"

cat << 'EOF' > "${BUILD_DIR}/DEBIAN/postrm"
#!/usr/bin/env bash
set -e
if [ "${1:-}" = "remove" ] || [ "${1:-}" = "purge" ]; then
    if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
        systemctl daemon-reload 2>/dev/null || true
    fi
fi
exit 0
EOF
chmod 0755 "${BUILD_DIR}/DEBIAN/postrm"

find "${BUILD_DIR}" -type d -exec chmod 0755 {} +

if git -C "${ROOT_DIR}" rev-parse HEAD >/dev/null 2>&1; then
    export SOURCE_DATE_EPOCH="$(git -C "${ROOT_DIR}" log -1 --format=%ct)"
else
    export SOURCE_DATE_EPOCH="1793100000"
fi
find "${BUILD_DIR}" -exec touch -h -d "@${SOURCE_DATE_EPOCH}" {} +

DEB_OUT="${DIST_DIR}/${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}.deb"
dpkg-deb --root-owner-group -Zxz --build "${BUILD_DIR}" "${DEB_OUT}"

ROOT_PERM="$(dpkg-deb -c "${DEB_OUT}" | awk '$6 == "./" {print $1}')"
if [ "${ROOT_PERM}" != "drwxr-xr-x" ]; then
    echo "FATAL [Invariant Breach]: ${DEB_OUT} root dir is ${ROOT_PERM}" >&2
    exit 1
fi

sha256sum "${DEB_OUT}" > "${DIST_DIR}/SHA256SUMS"
echo "[Installer] Debian 13 package built & verified: ${DEB_OUT}"
cat "${DIST_DIR}/SHA256SUMS"
