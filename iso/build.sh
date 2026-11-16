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
lb build 2>&1 | tee lb.log

# Verificări. Liniile ::notice::/::error:: devin adnotări vizibile pe pagina build-ului.
fail=0
check() { if eval "$2"; then echo "::notice::OK: $1"; else echo "::error::LIPSEȘTE: $1"; fail=1; fi; }
check "ISO generat"                 "ls ./*.iso >/dev/null 2>&1"
check "ACM OS în /opt/acm-os"       "[ -f chroot/etc/acm-release ]"
check "driver Wi-Fi wl compilat"    "ls chroot/lib/modules/*/updates/dkms/wl.ko* >/dev/null 2>&1"
check "Google Chrome"               "[ -x chroot/opt/google/chrome/chrome ]"
check "instalator Calamares"        "[ -x chroot/usr/bin/calamares ]"
check "GRUB pe stick (pool)"        "ls binary/pool/main/g/grub2/grub-pc_*.deb binary/pool/main/g/grub2/grub-efi-amd64_*.deb >/dev/null 2>&1"
check "Plasma"                      "[ -x chroot/usr/bin/plasmashell ]"
grep -h "nu s-a instalat" lb.log | sed "s/^/::warning::/" || true
[ "$fail" = 0 ] || exit 1

mkdir -p "$src/out" && mv ./*.iso "$src/out/"
echo "::notice::ISO: $(ls "$src/out") — $(du -h "$src"/out/*.iso | cut -f1)"
# containerul rulează ca root; pașii următori din GitHub rulează ca alt utilizator
chmod -R a+rwX "$src/out"
