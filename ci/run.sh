#!/usr/bin/env bash
# Rulat de GitHub Actions (.github/workflows/iso.yml). Toată logica stă aici, ca să poată fi
# schimbată fără a atinge fișierul de workflow.
#   tag iso-*  : construiește ISO-ul, face capturi în VM și îl publică
#   tag test-* : construiește ISO-ul și face capturi în VM (fără publicare)
set -euo pipefail
tag="${1:-manual}"
cd "$(dirname "$0")/.."

set -o pipefail
docker run --rm --privileged -v "$PWD:/w" debian:trixie bash /w/iso/build.sh 2>&1 | tee build.log
(cd out && sha256sum ./*.iso | sed 's| \./| |' > SHA256SUMS && cat SHA256SUMS)

bash ci/vm-shots.sh "$tag" || echo "::warning::capturile din VM au avut probleme"

case "$tag" in
  iso-*)
    size=$(stat -c %s out/*.iso)
    files=(out/SHA256SUMS)
    [ "$size" -lt 2147483648 ] && files=(out/*.iso out/SHA256SUMS)
    gh release create "$tag" "${files[@]}" --title "ACM OS ${tag#iso-}" \
      --notes "Pune ISO-ul pe stick cu balenaEtcher, pornește MacBook-ul ținând Option și alege stick-ul." \
      || gh release upload "$tag" "${files[@]}" --clobber
    ;;
esac
