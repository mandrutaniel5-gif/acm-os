#!/usr/bin/env bash
# Pornește ISO-ul în QEMU (1280x800, ca MacBook-ul), îl folosește din tastatură și face capturi.
# Capturile ajung pe ramura „screens”: screens/<tag>/NN-nume.png
set -uo pipefail
tag="$1"; src="$PWD"; shots="$src/shots/$tag"; mkdir -p "$shots"
sudo apt-get update -q >/dev/null && sudo apt-get install -y -q qemu-system-x86 socat imagemagick >/dev/null

mon=/tmp/qmon
sudo qemu-system-x86_64 -enable-kvm -cpu host -m 4096 -smp 2 \
  -cdrom "$(ls out/*.iso)" -boot d \
  -device VGA,edid=on,xres=1280,yres=800 -usb -device usb-tablet \
  -monitor "unix:$mon,server,nowait" -display none -daemonize -pidfile /tmp/qemu.pid

m() { echo "$*" | sudo socat - "UNIX-CONNECT:$mon" >/dev/null; }
shot() { m "screendump /tmp/s.ppm"; sleep 1; sudo convert /tmp/s.ppm "$shots/$1.png" && echo "::notice::captură $1"; }
keys() { for k in "$@"; do m "sendkey $k"; sleep 0.2; done; }
write() {
  local s="$1" c k i
  for ((i = 0; i < ${#s}; i++)); do
    c="${s:i:1}"
    case "$c" in
      ' ') k=spc ;; '-') k=minus ;; '_') k=shift-minus ;; '.') k=dot ;; ',') k=comma ;; '/') k=slash ;;
      '|') k=shift-backslash ;; ';') k=semicolon ;; ':') k=shift-semicolon ;; "'") k=apostrophe ;;
      '"') k=shift-apostrophe ;; '~') k=shift-grave_accent ;; '>') k=shift-dot ;; '<') k=shift-comma ;;
      '=') k=equal ;; '&') k=shift-7 ;; '$') k=shift-4 ;; '*') k=shift-8 ;; '(') k=shift-9 ;; ')') k=shift-0 ;;
      [A-Z]) k="shift-${c,,}" ;;
      *) k="$c" ;;
    esac
    m "sendkey $k"; sleep 0.08
  done
}

sleep 8;  shot 00-meniu-stick; keys ret
sleep 20; shot 01-pornire
sleep 70; shot 02-desktop-prima-vedere
sleep 60; shot 03-desktop
keys alt-f1; sleep 4; shot 04-meniu-aplicatii; keys esc; sleep 2
keys ctrl-spc; sleep 3; write dolphin; sleep 3; shot 05-cautare; keys ret; sleep 8; shot 06-fisiere; keys alt-f4; sleep 2
keys ctrl-alt-t; sleep 6; shot 07-terminal
write "acm-theme ivory";    keys ret; sleep 12; shot 08-tema-ivory
write "acm-theme olive";    keys ret; sleep 12; shot 09-tema-olive
write "acm-theme obsidian"; keys ret; sleep 12; shot 10-tema-obsidian
for pg in aspect baterie actualizari despre; do
  write "clear; setsid -f sh -c 'acm-setari $pg 2>>/tmp/setari.log'"; keys ret; sleep 10; shot "11-setari-$pg"; keys alt-f4; sleep 3
done
write "clear; journalctl --user -b --no-pager | grep -iE 'plasmashell|kwin_|js: |qml|plasmoids' | grep -iE 'error|crash|fail|warn|acm' | tail -32"; keys ret; sleep 4; shot 12-jurnal
write "clear; grep -iE 'error|warn|qml' /tmp/setari.log | tail -12; coredumpctl list --no-pager 2>&1 | tail -4; cat ~/.config/acm/theme; acm-battery info"; keys ret; sleep 4; shot 13-stare
keys alt-f4; sleep 2
sudo kill "$(cat /tmp/qemu.pid)" 2>/dev/null

# urcă pe ramura screens
d="$(mktemp -d)" && cd "$d"
git init -q && git config user.name "ACM CI" && git config user.email "ci@acm-os"
git remote add origin "https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
if git fetch -q origin screens; then git checkout -q -b screens FETCH_HEAD; else git checkout -q --orphan screens; fi
rm -rf "$tag" && cp -r "$shots" "$tag" && git add -A && git commit -qm "capturi $tag" && git push -q origin screens
echo "::notice::capturi: https://github.com/${GITHUB_REPOSITORY}/tree/screens/$tag"
