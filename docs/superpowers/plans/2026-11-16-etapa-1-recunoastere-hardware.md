# Etapa 1 — Recunoaștere hardware: plan de implementare

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Un script care, rulat pe MacBook dintr-un stick live Debian 13, strânge tot ce trebuie să știm despre hardware și testează lucrurile riscante (Wi-Fi, sunet, somn, Chrome, Claude Code, cheile SMC pentru baterie). Raportul ajunge pe PC fără stick suplimentar.

**Architecture:** `recon/lib.sh` conține funcții pure care primesc date și dau verdicte (testate pe Windows în Git Bash, cu fixture-uri). `recon/acm-recon.sh` colectează, apelează lib-ul și scrie `summary.txt` și o arhivă. Toate căile de sistem trec prin `$ACM_ROOT` (implicit gol), ca să poată fi testate pe fixture-uri. Livrarea: PC-ul servește scriptul prin HTTP în rețeaua locală. MacBook-ul îl rulează, apoi servește raportul pe portul 8765, iar PC-ul îl descarcă.

**Tech Stack:** Bash 5, coreutils, `timeout`, `rtcwake`, `alsa-utils`, `curl`, Python 3 (`http.server`) pe ambele capete, PowerShell pe PC.

**Spec:** `docs/2026-11-16-acm-os-design.md` (§2 hardware, §7 Claude Code, §8.1 baterie, §10 etapa 1)

## Global Constraints

- Țintă: Debian 13 (trixie) amd64, imagine live oficială, MacBook Pro 13" mid-2010 (MacBookPro7,1).
- Procesorul e x86-64-v1 (fără SSE4.2, POPCNT, AVX). Se raportează explicit ce software merge.
- Scriptul **doar citește** SMC și bateria. Nicio scriere în SMC, nicio comandă de încărcare.
- Pragurile bateriei (§8.4): sub **2,0 V/celulă** = `DEAD_CELL`, nu se încearcă; sub **2,5 V/celulă** = `DEEP_DISCHARGE`; 3 celule în serie.
- Fără secrete în repo sau în raport (fără tokenuri, parole, chei).
- Raportul se transmite doar în rețeaua locală, niciodată la un serviciu extern.
- Textul afișat utilizatorului e în română.

## Review Focus

1. **Bateria lipsește din sistem** (nu există `BAT0`, situația probabilă acum): scriptul continuă și raportează `battery=ABSENT`, fără să se oprească.
2. **Live-ul nu are internet** (Wi-Fi fără driver, fără cablu): testele Chrome și Claude apar ca `SKIP (fără rețea)`, nu ca `FAIL`.
3. **`applesmc` nu se încarcă**: secțiunea SMC apare `SKIP`, iar restul raportului e complet.
4. **Laptopul nu revine din somn**: tot raportul e scris și servit *înainte* de testul de somn. Testul e ultimul și cere confirmare.
5. **Rulare a doua oară sau fără root**: fără root scriptul refuză cu un mesaj clar. A doua rulare scrie într-un director nou, cu ora în nume, și nu suprascrie.

---

## Fișiere

```
ACM OS/                         (repository git, rădăcina proiectului)
  .gitignore
  README.md
  design/  docs/               (existente)
  recon/
    lib.sh                      funcții pure: verdicte din date
    acm-recon.sh                colectare + teste live + raport
    serve-pc.ps1                PC: servește recon/ pe portul 8000
    fetch-report.ps1            PC: descarcă raportul de la MacBook
    tests/
      run.sh                    rulează toate testele
      test_lib.sh
      test_recon_dry.sh
      fixtures/mbp71/           un arbore sys/proc fals (MacBookPro7,1)
  docs/hardware-findings.md     (Task 5)
```

---

### Task 1: Repository și fixture-uri

**Files:**
- Create: `.gitignore`, `README.md`, `recon/tests/run.sh`, `recon/tests/fixtures/mbp71/**`

**Interfaces:**
- Produces: fixture-ul `recon/tests/fixtures/mbp71/` cu:
  - `proc/cpuinfo`: un procesor cu `model name : Intel(R) Core(TM)2 Duo CPU P8600 @ 2.40GHz` și `flags : fpu ... sse sse2 ssse3 sse4_1 lm ...` (fără `sse4_2`, `popcnt`, `avx`);
  - `sys/class/dmi/id/product_name` = `MacBookPro7,1`;
  - `sys/class/power_supply/ADP1/online` = `1`;
  - fără `BAT0` (varianta implicită). Varianta `mbp71-bat/` are `BAT0/voltage_now` = `5400000` (µV), `status` = `Not charging`, `present` = `1`;
  - `sys/devices/platform/applesmc.768/`: `key_count` = `3` și, pentru indicii 0–2, numele cheilor `TB0T`, `CH0B`, `BNum`, printr-un fișier `keys.txt` (vezi Task 2).
- Produces: `recon/tests/run.sh` rulează fiecare `test_*.sh` și iese cu cod ≠0 la orice eșec.

- [ ] **Step 1:** `git init` în `C:\Users\HP\Desktop\ACM OS`. `.gitignore`: `*.tar.gz`, `reports/`, `*.png` din `design/` rămân în repo (nu se ignoră).
- [ ] **Step 2:** Creează fixture-urile de mai sus și `run.sh`.
- [ ] **Step 3:** Rulează `bash recon/tests/run.sh`. Rezultat așteptat: `0 teste, 0 eșecuri` și cod 0.
- [ ] **Step 4:** Commit: `chore: repository ACM OS + fixture MacBookPro7,1`

---

### Task 2: Verdicte în `lib.sh`

**Files:**
- Create: `recon/lib.sh`, `recon/tests/test_lib.sh`

**Interfaces:**
- Produces (toate citesc din `$ACM_ROOT` și scriu un singur cuvânt pe stdout):
  - `cpu_level` → `v1` | `v2` | `v3`. `v2` cere `sse4_2 popcnt`, `v3` cere și `avx2`.
  - `battery_state` → `ABSENT` | `DEAD_CELL` | `DEEP_DISCHARGE` | `LOW` | `OK`. Celula = `voltage_now / 3`. `< 2.0V` → `DEAD_CELL`, `< 2.5V` → `DEEP_DISCHARGE`, `< 3.3V` → `LOW`.
  - `smc_keys` → numele tuturor cheilor, câte unul pe linie. Pe sistemul real se citesc prin `key_at_index` (scrii indexul, citești `key_at_index_name`). În fixture se citesc din `keys.txt`. Funcția alege sursa după existența lui `keys.txt`.
  - `smc_charge_control` → `YES` dacă există `CH0B` sau `CH0C`, altfel `NO`. `SKIP` dacă `applesmc.768` lipsește.

- [ ] **Step 1: Teste**
```bash
ACM_ROOT=$F/mbp71      assert_eq "$(cpu_level)" v1
ACM_ROOT=$F/mbp71      assert_eq "$(battery_state)" ABSENT
ACM_ROOT=$F/mbp71-bat  assert_eq "$(battery_state)" DEAD_CELL     # 5.4V/3 = 1.8V
# varianta voltage_now=7200000 (2.4V/celulă)  -> DEEP_DISCHARGE
# varianta voltage_now=12300000 (4.1V/celulă) -> OK
ACM_ROOT=$F/mbp71      assert_eq "$(smc_charge_control)" YES
ACM_ROOT=$F/empty      assert_eq "$(smc_charge_control)" SKIP
```
Variantele de tensiune se fac în teste prin copierea fixture-ului într-un director temporar și rescrierea lui `voltage_now`.
- [ ] **Step 2:** `bash recon/tests/run.sh`. Rezultat așteptat: FAIL (`cpu_level: command not found`).
- [ ] **Step 3:** Implementează funcțiile în `recon/lib.sh`. Aritmetica se face în µV, cu numere întregi.
- [ ] **Step 4:** `bash recon/tests/run.sh`. Rezultat așteptat: toate trec.
- [ ] **Step 5:** Commit: `feat(recon): verdicte procesor, baterie, SMC`

---

### Task 3: `acm-recon.sh`, colectare și teste live

**Files:**
- Create: `recon/acm-recon.sh`, `recon/tests/test_recon_dry.sh`

**Interfaces:**
- Consumes: funcțiile din Task 2.
- Produces: `acm-recon.sh [--dry]`. Scrie `$OUT=/root/acm-recon-<YYYYmmdd-HHMMSS>/` (în modul `--dry`: `$ACM_OUT`). Conținut:
  - `summary.txt`: câte o linie `cheie=valoare` pentru `model`, `cpu_level`, `battery`, `smc_charge_control`, `wifi`, `audio`, `network`, `chrome`, `claude`, `suspend`;
  - `raw/`: `lspci -nnk`, `lsusb`, `dmesg`, `lscpu`, `/proc/asound/card*/codec#*`, tot `power_supply/*`, toate valorile SMC (nume, tip, date), `ip a`, `rfkill list`, `journalctl -b` (ultimele 2000 de linii);
  - `acm-recon-<stamp>.tar.gz` din tot ce e mai sus.
- Valorile testelor live: `PASS` | `FAIL (<motiv scurt>)` | `SKIP (<motiv>)`.

Testele live, în această ordine, fiecare cu `timeout`:
1. **network**: `curl -sI https://deb.debian.org` în 10 s.
2. **wifi**: driverul legat de dispozitivul Broadcom din `lspci -k`. `PASS` dacă apare o interfață `wl*`, altfel `FAIL (<driver sau 'niciun driver'>)`.
3. **audio**: `speaker-test -t sine -f 440 -l 1` cu volumul la 60%, apoi întrebarea „Ai auzit un sunet? [d/n]”.
4. **chrome**: doar cu rețea. Descarcă `.deb`-ul stabil oficial în `/tmp`, instalează cu `apt-get install -y ./…`, apoi rulează `google-chrome --headless=new --dump-dom about:blank`. `PASS` dacă iese cu 0. Dacă moare cu `SIGILL`, motivul e `instrucțiune neacceptată`.
5. **claude**: doar cu rețea. Rulează installer-ul oficial ca utilizator `user` din live, apoi `claude --version`. La `SIGILL` sau eroare, încearcă varianta npm cu `nodejs` din Debian și raportează `PASS (npm)` sau `FAIL`. **Nu se face login.**
6. Scrie `summary.txt` și arhiva, apoi pornește `python3 -m http.server 8765` în `$OUT` și afișează mare IP-ul și portul.
7. **suspend**: întreabă „Testăm somnul? Ecranul se stinge 20 s. [d/n]”. La `d`: `rtcwake -m mem -s 20`. După revenire întreabă dacă merg ecranul și Wi-Fi-ul, apoi actualizează `summary.txt` și arhiva.

- [ ] **Step 1: Test** `test_recon_dry.sh`: `ACM_ROOT=$F/mbp71 ACM_OUT=$tmp bash recon/acm-recon.sh --dry` → `summary.txt` conține `model=MacBookPro7,1`, `cpu_level=v1`, `battery=ABSENT`, `smc_charge_control=YES`. În `--dry`, toate testele live sunt `SKIP (dry)`. Codul de ieșire e 0.
- [ ] **Step 2: Test:** fără root și fără `--dry`, scriptul iese cu 1 și afișează `Rulează cu sudo`.
- [ ] **Step 3:** Rulează testele. Rezultat așteptat: FAIL.
- [ ] **Step 4:** Implementează. Fiecare test live rulează într-o funcție separată (`t_network`, `t_wifi`, `t_audio`, `t_chrome`, `t_claude`, `t_suspend`), care scrie doar în `summary.txt`. Un test care pică nu oprește scriptul. Fără `set -e`, folosește `set -u`.
- [ ] **Step 5:** Rulează testele. Rezultat așteptat: trec. Rulează și `bash -n recon/acm-recon.sh`.
- [ ] **Step 6:** Commit: `feat(recon): colectare + teste live + raport`

---

### Task 4: Livrarea între PC și MacBook

**Files:**
- Create: `recon/serve-pc.ps1`, `recon/fetch-report.ps1`

**Interfaces:**
- `serve-pc.ps1`: afișează IP-ul LAN al PC-ului și comanda de rulat pe MacBook (`curl -s http://<IP>:8000/acm-recon.sh -o r.sh && curl -s http://<IP>:8000/lib.sh -o lib.sh && sudo bash r.sh`), apoi pornește `python -m http.server 8000 --bind <IP>` în `recon/`. Dacă Windows Firewall blochează portul, afișează regula de adăugat (`New-NetFirewallRule` pentru portul 8000, doar profilul Private) și o adaugă **doar după confirmarea utilizatorului**.
- `fetch-report.ps1 -Ip <ip-macbook>`: descarcă `summary.txt` și arhiva în `reports/<stamp>/` și afișează `summary.txt`.

- [ ] **Step 1:** Implementează ambele scripturi.
- [ ] **Step 2:** Verificare locală: rulează `serve-pc.ps1`, apoi din altă fereastră `curl http://<IP>:8000/acm-recon.sh`. Trebuie să primești scriptul. Oprește serverul.
- [ ] **Step 3:** Verificare `fetch-report.ps1` cu un `python -m http.server 8765` pornit local, într-un director cu un `summary.txt` de probă.
- [ ] **Step 4:** Commit: `feat(recon): livrare PC <-> MacBook în rețeaua locală`

---

### Task 5: Rularea pe MacBook și concluziile

Acest task îl face utilizatorul pe MacBook, ghidat pas cu pas. Verificarea e raportul primit.

- [ ] **Step 1:** Utilizatorul descarcă imaginea **Debian 13 live amd64 KDE** de pe debian.org, verifică SHA256 și o scrie pe stick cu balenaEtcher.
- [ ] **Step 2:** MacBook-ul e conectat la router **prin cablu de rețea** (dacă se poate; Wi-Fi-ul poate să nu meargă din live). Pornește ținând **Option (⌥)** și alege stick-ul („EFI Boot”; dacă ecranul rămâne negru, intrarea „Windows” de pe stick, adică modul legacy).
- [ ] **Step 3:** Pe PC: `recon/serve-pc.ps1`. Pe MacBook, în Konsole: comanda afișată. Se răspunde la întrebările despre sunet și somn.
- [ ] **Step 4:** Pe PC: `recon/fetch-report.ps1 -Ip <IP afișat pe MacBook>`.
- [ ] **Step 5:** Scrie `docs/hardware-findings.md`: tabelul din §2 al specificației, cu coloana „Confirmat pe aparat” completată din raport, plus deciziile care urmează din el (driver Wi-Fi, opțiunea pentru sunet, EFI sau legacy, Chrome/Claude nativ sau alternativă, dacă doctorul poate opri încărcarea).
- [ ] **Step 6:** Actualizează §2 și §9 din specificație cu ce s-a confirmat. Commit: `docs: rezultate recunoaștere hardware MacBookPro7,1`

**După Task 5:** se scrie planul pentru etapa 2 (baza: Debian, drivere, Btrfs, pornire rapidă, ISO), pe baza `hardware-findings.md`.
