#!/usr/bin/env python3
"""
qemu_spice_harness.py: Banc d'essai automatisé QEMU / KVM avec pilote SPICE
Permet :
1. De lancer une VM de test Debian 13 avec deux disques virtuels (pour tester le RAID 1 / RAID 0)
2. D'activer le serveur d'affichage SPICE avec support de l'agent invité (spice-vdagent)
3. De piloter la VM par clavier / souris via le moniteur QEMU (sendkey, screendump, etc.)
"""

import os
import sys
import time
import subprocess
import socket

VM_DIR = os.environ.get("PODMESH_INSTALLER_VM_DIR", os.path.dirname(os.path.abspath(__file__)))
DISK_A = os.path.join(VM_DIR, "disk_a.qcow2")
DISK_B = os.path.join(VM_DIR, "disk_b.qcow2")
SPICE_PORT = 5930
MONITOR_SOCKET = os.path.join(VM_DIR, "qemu-monitor.sock")

def create_virtual_disks():
    os.makedirs(VM_DIR, exist_ok=True)
    for disk in [DISK_A, DISK_B]:
        if not os.path.exists(disk):
            print(f"[QEMU] Création du disque virtuel {disk} (20 Go)...")
            subprocess.run(["qemu-img", "create", "-f", "qcow2", disk, "20G"], check=True)

def send_monitor_command(cmd):
    if not os.path.exists(MONITOR_SOCKET):
        print(f"[MONITOR] Socket introuvable : {MONITOR_SOCKET}")
        return None
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect(MONITOR_SOCKET)
    time.sleep(0.1)
    s.recv(1024)
    s.sendall((cmd + "\n").encode("utf-8"))
    time.sleep(0.2)
    resp = s.recv(4096).decode("utf-8")
    s.close()
    return resp

def launch_vm(iso_path=None):
    create_virtual_disks()
    if os.path.exists(MONITOR_SOCKET):
        os.remove(MONITOR_SOCKET)

    # Détecte si KVM est accessible sans sudo, sinon bascule sur TCG accéléré
    use_kvm = os.access("/dev/kvm", os.R_OK | os.W_OK)
    accel = ["-enable-kvm", "-cpu", "host"] if use_kvm else ["-accel", "tcg", "-cpu", "qemu64"]

    cmd = [
        "qemu-system-x86_64",
        *accel,
        "-m", "2048",
        "-smp", "2",
        "-drive", f"file={DISK_A},if=virtio,format=qcow2",
        "-drive", f"file={DISK_B},if=virtio,format=qcow2",
        "-vga", "qxl",
        "-spice", f"port={SPICE_PORT},disable-ticketing=on",
        "-device", "virtio-serial-pci",
        "-device", "virtserialport,chardev=spicechannel0,name=com.redhat.spice.0",
        "-chardev", "spicevmc,id=spicechannel0,name=vdagent",
        "-qmp", f"unix:{MONITOR_SOCKET},server,nowait",
        "-daemonize"
    ]
    if iso_path and os.path.exists(iso_path):
        cmd.extend(["-cdrom", iso_path, "-boot", "d"])

    print(f"[QEMU] Lancement VM avec SPICE sur port {SPICE_PORT}...")
    subprocess.run(cmd, check=True)
    print(f"[QEMU] VM active. Connectez-vous avec: spicy -h localhost -p {SPICE_PORT}")

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "launch":
        iso = sys.argv[2] if len(sys.argv) > 2 else None
        launch_vm(iso)
    elif len(sys.argv) > 1 and sys.argv[1] == "cmd":
        command = " ".join(sys.argv[2:])
        print(send_monitor_command(command))
    else:
        print("Usage: python3 qemu_spice_harness.py [launch [iso_path] | cmd <qemu_command>]")
