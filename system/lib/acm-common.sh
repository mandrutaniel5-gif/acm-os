# Funcții comune ACM OS. Se încarcă cu `source`.

ACM_DIR="${ACM_DIR:-/opt/acm-os}"
ACM_STATE="${ACM_STATE:-/var/lib/acm}"

# /opt/acm-os e al lui root. Rulat cu sudo, git îl compară cu utilizatorul care a dat sudo
# și refuză repository-ul („dubious ownership”). Îl declarăm sigur pentru toate comenzile git.
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0="$ACM_DIR"

say()  { printf '\033[1;33m▸\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;31m!\033[0m %s\n' "$*" >&2; }

need_root() {
  [ "$(id -u)" -eq 0 ] || { warn "Rulează cu sudo."; exit 1; }
}

# version_gt A B -> adevărat dacă A > B (ex: 1.10.0 > 1.9.2)
version_gt() {
  [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n1)" = "$1" ]
}

# Cea mai nouă versiune dintr-o listă de taguri "vX.Y.Z" (câte unul pe linie, pe stdin).
latest_tag_version() {
  grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sed 's/^v//' | sort -V | tail -n1
}

installed_version() {
  sed -n 's/^VERSION=//p' "${ACM_RELEASE:-/etc/acm-release}" 2>/dev/null
}

# Primul utilizator normal (UID 1000+), cel care folosește laptopul.
main_user() {
  awk -F: '$3>=1000 && $3<60000 {print $1; exit}' "${ACM_PASSWD:-/etc/passwd}"
}

# Adaugă contrib/non-free la liniile Debian dintr-un sources.list clasic (stdin -> stdout).
enable_nonfree_list() {
  sed -E '/^deb(-src)? /{/ non-free( |$)/!s/ main( .*)?$/ main contrib non-free non-free-firmware/}'
}

# La fel pentru formatul deb822 (debian.sources).
enable_nonfree_deb822() {
  sed -E 's/^Components:.*$/Components: main contrib non-free non-free-firmware/'
}
