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

# GRUB pe stick, pentru instalatorul Calamares (fără internet). Cele două variante se exclud
# reciproc la instalare, așa că le descărcăm separat, cu tot cu dependențe, în pool-ul ISO-ului.
mkdir -p config/packages.binary
for flavor in "grub-pc" "grub-efi-amd64 grub-efi-amd64-signed shim-signed"; do
  d="$(mktemp -d)" && mkdir -p "$d/partial"
  apt-get install -y -q --download-only -o Dir::Cache::archives="$d" $flavor efibootmgr os-prober >/dev/null
  cp "$d"/*.deb config/packages.binary/
done
echo "::notice::GRUB pe stick: $(ls config/packages.binary | wc -l) pachete"

# la orice eroare, ultimele linii din jurnal apar pe pagina build-ului
trap 'tail -n 40 lb.log 2>/dev/null | sed "s/^/::error::/"' ERR
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
check "GRUB pe stick (pool)"        "[ -n \"$(find binary/pool -name 'grub-pc_*.deb')\" ] && [ -n \"$(find binary/pool -name 'grub-efi-amd64_*.deb')\" ]"
check "Plasma"                      "[ -x chroot/usr/bin/plasmashell ]"
grep -h "nu s-a instalat" lb.log | sed "s/^/::warning::/" || true
[ "$fail" = 0 ] || exit 1

mkdir -p "$src/out" && mv ./*.iso "$src/out/"
echo "::notice::ISO: $(ls "$src/out") — $(du -h "$src"/out/*.iso | cut -f1)"
# containerul rulează ca root; pașii următori din GitHub rulează ca alt utilizator
chmod -R a+rwX "$src/out"
