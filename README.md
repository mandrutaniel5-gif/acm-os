# ACM OS

Sistem de operare în stil Apple pentru MacBook Pro 13" 2010 (MacBookPro7,1), construit peste Debian 13.

- Design: `docs/2026-11-16-acm-os-design.md`, machete în `design/v2/`
- Instalare: Debian 13 oficial (disc Btrfs), apoi `curl -fsSL https://raw.githubusercontent.com/mandrutaniel5-gif/acm-os/main/install.sh | sudo bash`
- Actualizări: `acm-update check | apply | rollback`. O versiune nouă = un tag `vX.Y.Z` pe `main`.
- Teste: `bash tests/test_common.sh`
