#!/usr/bin/env bash
# Construiește ISO-ul ACM OS. Rulează ca root într-un container debian:trixie (vezi .github/workflows/iso.yml).
set -euo pipefail
src="$(cd "$(dirname "$0")/.." && pwd)"
ver="$(cat "$src/VERSION")"

apt-get update -q && apt-get install -y -q live-build git ca-certificates librsvg2-bin
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
  --bootappend-live "boot=live components quiet splash locales=ro_RO.UTF-8 keyboard-layouts=ro timezone=Europe/Bucharest hostname=acm-os user-fullname=ACM"

cp -r "$src/iso/config/." config/

# Meniul de pe stick: sigiliul ACM în loc de casca Debian, „ACM OS” în loc de „Live system”
mkdir -p config/bootloaders
for b in isolinux grub-pc; do
  if [ -d "/usr/share/live/build/bootloaders/$b" ]; then cp -r "/usr/share/live/build/bootloaders/$b" config/bootloaders/; fi
done
seal="$(sed -E "s/<svg [^>]*viewBox/<svg x=\"255\" y=\"40\" width=\"130\" height=\"130\" viewBox/" "$src/design/sigiliu-pe-fundal-inchis.svg")"
cat > /tmp/splash.svg <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="640" height="480" viewBox="0 0 640 480">
<rect width="640" height="480" fill="#0b0b0c"/>
$seal
<text x="320" y="205" fill="#BD9A6A" font-family="sans-serif" font-size="13" text-anchor="middle" letter-spacing="5">FLAWLESS EXECUTION</text>
</svg>
SVG
rsvg-convert -w 640 -h 480 /tmp/splash.svg -o /tmp/splash.png
find config/bootloaders -name "splash.svg*" -exec cp /tmp/splash.svg {} \;
find config/bootloaders -name "splash.png" -exec cp /tmp/splash.png {} \;
grep -rlE "Live system|Debian GNU/Linux" config/bootloaders | xargs -r sed -i \
  -e "s|Live system (fail-safe mode)|ACM OS (mod sigur)|g" -e "s|Live system|ACM OS|g" -e "s|Debian GNU/Linux|ACM OS|g" || true
echo "::notice::meniu stick: $(find config/bootloaders -name "splash*" | wc -l) imagini înlocuite"

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
# neverificat încă pe aparat: doar avertisment (fără el, instalarea cere internet)
if eval "[ -n \"$(find binary/pool -name 'grub-pc_*.deb')\" ] && [ -n \"$(find binary/pool -name 'grub-efi-amd64_*.deb')\" ]"; then echo "::notice::OK: GRUB pe stick"; else echo "::warning::GRUB nu e pe stick: instalarea va cere internet"; fi
check "Plasma"                      "[ -x chroot/usr/bin/plasmashell ]"
grep -h "nu s-a instalat" lb.log | sed "s/^/::warning::/" || true
[ "$fail" = 0 ] || exit 1

mkdir -p "$src/out" && mv ./*.iso "$src/out/"
echo "::notice::ISO: $(ls "$src/out") — $(du -h "$src"/out/*.iso | cut -f1)"
# containerul rulează ca root; pașii următori din GitHub rulează ca alt utilizator
chmod -R a+rwX "$src/out"
