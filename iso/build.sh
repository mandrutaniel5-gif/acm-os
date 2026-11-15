#!/usr/bin/env bash
# Construiește ISO-ul ACM OS. Rulează ca root într-un container debian:trixie (vezi .github/workflows/iso.yml).
set -euo pipefail
src="$(cd "$(dirname "$0")/.." && pwd)"
ver="$(cat "$src/VERSION")"

apt-get update -q && apt-get install -y -q live-build git ca-certificates
work=/tmp/acm-iso && rm -rf "$work" && mkdir -p "$work" && cd "$work"

lb config \
  --distribution trixie \
  --archive-areas "main contrib non-free non-free-firmware" \
  --debian-installer none \
  --bootloaders "syslinux,grub-efi" \
  --binary-images iso-hybrid \
  --chroot-squashfs-compression-type xz \
  --iso-application "ACM OS" \
  --iso-volume "ACM OS $ver" \
  --image-name "acm-os-$ver" \
  --bootappend-live "boot=live components quiet splash locales=ro_RO.UTF-8 keyboard-layouts=ro timezone=Europe/Bucharest"

cp -r "$src/iso/config/." config/
chmod +x config/hooks/normal/*.hook.chroot
lb build
mkdir -p "$src/out" && mv ./*.iso "$src/out/"
ls -la "$src/out"
