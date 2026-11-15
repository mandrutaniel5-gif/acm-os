#!/usr/bin/env bash
# Transformă un Debian 13 proaspăt instalat în ACM OS.
# Pe MacBook:  curl -fsSL <adresa>/install.sh | sudo bash
set -uo pipefail

ACM_REPO="${ACM_REPO:-https://github.com/mandrutaniel5-gif/acm-os.git}"
ACM_DIR=/opt/acm-os

[ "$(id -u)" -eq 0 ] || { echo "Rulează cu sudo."; exit 1; }
. /etc/os-release
[ "${VERSION_CODENAME:-}" = trixie ] || echo "! Atenție: ACM OS e făcut pentru Debian 13 (trixie), aici e ${PRETTY_NAME:-necunoscut}."
model="$(cat /sys/class/dmi/id/product_name 2>/dev/null)"
[ "$model" = "MacBookPro7,1" ] || echo "! Atenție: ACM OS e croit pentru MacBookPro7,1, aici e '$model'."

apt-get update -q && apt-get install -y -q git curl ca-certificates

if [ -d "$ACM_DIR/.git" ]; then
  git -C "$ACM_DIR" fetch -q --tags --force origin
else
  git clone -q "$ACM_REPO" "$ACM_DIR"
fi
tag="$(git -C "$ACM_DIR" tag -l 'v*' | sed 's/^v//' | sort -V | tail -n1)"
[ -n "$tag" ] && git -C "$ACM_DIR" checkout -q "v$tag"

"$ACM_DIR/system/bin/acm-apply" || { echo "! Instalarea nu s-a terminat. Rulează din nou aceeași comandă."; exit 1; }

[ -f /etc/snapper/configs/root ] && snapper -c root create --description "ACM OS instalat" >/dev/null
echo
echo "  ACM OS e instalat. Repornește laptopul:  sudo reboot"
