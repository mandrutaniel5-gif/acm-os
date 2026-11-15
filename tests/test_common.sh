#!/usr/bin/env bash
# Teste pentru system/lib/acm-common.sh. Rulare: bash tests/test_common.sh
set -u
cd "$(dirname "$0")/.."
source system/lib/acm-common.sh

fails=0; n=0
check() { n=$((n+1)); if [ "$2" = "$3" ]; then :; else fails=$((fails+1)); echo "FAIL: $1 -> '$2' (așteptat '$3')"; fi; }
yes_no() { if "$@"; then echo yes; else echo no; fi; }

check "1.10.0 > 1.9.2"   "$(yes_no version_gt 1.10.0 1.9.2)" yes
check "1.0.0 > 1.0.0"    "$(yes_no version_gt 1.0.0 1.0.0)"  no
check "0.9.0 > 1.0.0"    "$(yes_no version_gt 0.9.0 1.0.0)"  no

check "ultimul tag" "$(printf 'v0.1.0\nv0.10.0\nv0.2.0\nnu-e-tag\nv1.0.0-rc\n' | latest_tag_version)" 0.10.0
check "fără taguri" "$(printf 'main\n' | latest_tag_version)" ""

tmp=$(mktemp -d)
printf 'VERSION=0.3.1\nNAME="ACM OS"\n' > "$tmp/rel"
check "versiune instalată" "$(ACM_RELEASE=$tmp/rel installed_version)" 0.3.1
check "fără release" "$(ACM_RELEASE=$tmp/nu-exista installed_version)" ""

printf 'root:x:0:0::/root:/bin/bash\nnobody:x:65534:65534::/:/usr/sbin/nologin\nandrei:x:1000:1000::/home/andrei:/bin/bash\n' > "$tmp/passwd"
check "utilizator principal" "$(ACM_PASSWD=$tmp/passwd main_user)" andrei

check "sources.list" \
  "$(printf 'deb http://deb.debian.org/debian trixie main\n# deb x main\n' | enable_nonfree_list)" \
  "$(printf 'deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware\n# deb x main')"
check "sources.list deja complet" \
  "$(printf 'deb http://d/debian trixie main contrib non-free non-free-firmware\n' | enable_nonfree_list)" \
  "deb http://d/debian trixie main contrib non-free non-free-firmware"
check "deb822" \
  "$(printf 'Types: deb\nComponents: main non-free-firmware\n' | enable_nonfree_deb822)" \
  "$(printf 'Types: deb\nComponents: main contrib non-free non-free-firmware')"

rm -rf "$tmp"
echo "$n teste, $fails eșecuri"
[ "$fails" -eq 0 ]
