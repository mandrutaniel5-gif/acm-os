# ACM OS — document de design

*16 noiembrie 2026 · design aprobat vizual (machete în `design/v2/`)*

## 1. Ce e și de ce

ACM OS e un sistem de operare premium, în stil Apple, făcut pentru **un singur calculator**: MacBook Pro-ul de 13" din 2010 al utilizatorului. Laptopul nu trebuie aruncat, ci trebuie să meargă bine și să fie îmbunătățit în continuare.

Ce își dorește utilizatorul, în cuvintele lui:
- să arate premium, în stil Apple, și să fie **super rapid și fluid**;
- să-l instaleze **o singură dată**, apoi reparațiile și noutățile să vină ca **actualizări, ca la Windows**, publicate împreună cu Claude, fără ISO-uri și reinstalări;
- **Chrome** preinstalat;
- **toate driverele** să meargă (acum nu merg boxele și nici încărcarea bateriei);
- pornire cât mai aproape de instant;
- **Claude Code** preinstalat și cât mai conectat din start;
- un **Doctor baterie** în Setări → Avansat, cu confirmare la pornire și **KILL SWITCH vizibil permanent**, care încearcă în cicluri tot mai lungi să readucă la viață bateria descărcată adânc;
- trei teme, **Ivory, Obsidian și Olive**, care se schimbă din Setări.

## 2. Hardware-ul țintă

| Componentă | Ce e | Ce înseamnă pentru noi |
|---|---|---|
| Model | MacBook Pro 13" mid-2010, A1278, MacBookPro7,1 | |
| Procesor | Intel Core 2 Duo P8600, 2,40 GHz, 2 nuclee | Nu are SSE4.2, POPCNT sau AVX. Merge doar software x86-64 „de bază” (v1). **Chrome, Node și Claude Code trebuie verificate pe aparat.** |
| Memorie | 4 GB DDR3 1066 | Plăcuțele de 4GB cu 8 cipuri ale utilizatorului nu sunt compatibile. Folosim zram în loc de swap pe disc. |
| Grafică | NVIDIA GeForce 320M, integrată (MCP89) | Driverul `nouveau`, OpenGL 3.3. Driverul proprietar 340 e abandonat. Efectele de sticlă se folosesc cu măsură. |
| Wi-Fi | Broadcom BCM4322 | Driver `broadcom-sta` (wl). Alternativă: `b43` cu firmware. |
| Sunet | Cirrus Logic CS4206 (HDA) | `snd-hda-intel`, eventual cu o opțiune de model. Se testează. |
| Trackpad | Apple multitouch (bcm5974) | libinput: tap-to-click, scroll natural, gesturi. |
| Ventilator, senzori | SMC Apple | `applesmc` pentru temperaturi și `mbpfan` pentru controlul ventilatorului. |
| Disc | SSD pe adaptor, SATA II | Btrfs, cu snapshot-uri. |
| Pornire | Firmware EFI Mac | Pornire în mod legacy/BIOS, ca acum la Windows (cel mai sigur cu placa NVIDIA). EFI rămâne opțiune de testat. |
| Baterie | A1322, Li-ion cu 3 celule în serie, nu se încarcă acum | Vezi §8. |

## 3. Obiective, ce nu facem, ce nu trebuie să se întâmple

**Obiective (v1):**
1. Sistemul se instalează o dată de pe stick USB și tot hardware-ul de mai sus merge.
2. Actualizările vin prin Setări → Actualizări. Înainte de fiecare actualizare se face automat un snapshot, deci orice actualizare se poate anula.
3. Cele trei teme din machete, schimbabile din Setări → Aspect, plus schimbare automată zi/noapte.
4. Bara de meniu cu sigiliul ACM, dock, coloana de widget-uri (oră și vreme, baterie, proiecte, sistem), căutare cu Ctrl+Space.
5. Pornire în ~10–15 s până la desktop. Închiderea capacului pune laptopul în somn, din care revine sub o secundă.
6. Chrome și Claude Code preinstalate. Claude se conectează dintr-un singur clic la prima pornire.
7. Doctorul de baterie, cu limitele de siguranță din §8.

**Ce nu facem:**
- Să rulăm Xcode sau simulatorul iOS local. Aparatul nu poate.
- Să suportăm alte calculatoare. ACM OS e croit pe acest MacBook.
- Să ocolim cipul de protecție al bateriei sau să forțăm încărcarea.
- ACM Studio (publicare iOS) nu intră în v1. Vine ca **actualizare** după v1 (vezi §10).

**Ce nu trebuie să se întâmple (eșec chiar dacă „merge”):**
- O actualizare care lasă laptopul nepornibil, fără cale de întoarcere.
- Parola sau contul (Claude, GitHub) ajunse în fișiere publice.
- Un sistem frumos, dar care se mișcă greu. Dacă un efect încetinește, îl scoatem.
- Doctorul de baterie care încălzește o baterie periculoasă sau rulează fără limite.

## 4. Abordări luate în calcul (pentru actualizări)

| Abordare | Avantaje | Dezavantaje | Decizie |
|---|---|---|---|
| ISO nou la fiecare versiune | Simplu | Reinstalare de fiecare dată, exact ce nu vrea utilizatorul | ✗ |
| Sistem „imagine” înlocuit complet (de tip OSTree / bootc) | Foarte sigur, atomic | Actualizări de gigabytes, greu pe aparat de 2010 | ✗ |
| **Pachete Debian proprii + depozit apt + snapshot Btrfs înainte de fiecare update** | Actualizări mici, ca la Windows, anulare din meniul de pornire | Trebuie disciplină la împachetare | **✓ ales** |

## 5. Arhitectura

### 5.1 Bază
- **Debian 13 (trixie) stabil, amd64.** E stabil, are actualizări de securitate mult timp și suportă bine procesoarele vechi.
- **Desktop: KDE Plasma 6, puternic personalizat.** E singurul desktop care are deja tot ce cer machetele: meniu global în bara de sus, dock, widget-uri pe desktop (QML), căutare (KRunner), teme globale schimbabile și module proprii în Setări. GNOME și Xfce ar fi cerut mult cod propriu sau ar fi ieșit mai puțin fluide.
- Sesiunea X11 sau Wayland se alege în faza 1, după care merge mai fluid pe 320M. Plecăm de la X11.
- `zram` pentru memorie, `preload` dezactivat, servicii minime, autologin.

### 5.2 Pornire rapidă
- GRUB cu timeout 0. Ținând **Shift** apare meniul cu versiunile anterioare (snapshot-uri, prin `grub-btrfs`).
- Plymouth cu tema din `design/0-pornire.png`.
- Autologin direct în Plasma. Ținta e ≤ 15 s de la GRUB la desktop, măsurat cu `systemd-analyze`.
- Somn la închiderea capacului (suspend-to-RAM, verificat pe aparat).

### 5.3 Repository-ul ACM OS
Totul stă într-un repository Git, `acm-os`, pe GitHub-ul utilizatorului:

```
acm-os/
  packages/
    acm-os-base/        meta-pachet: drivere, Chrome, Claude Code, aplicații, setări de sistem
    acm-theme/          cele 3 teme, iconițe, sigiliu, fundaluri, Plymouth, decorații ferestre
    acm-widgets/        widget-urile (QML)
    acm-settings/       module în Setări: Aspect, Actualizări, Avansat
    acm-update/         serviciul și interfața de actualizare
    acm-doctor-baterie/ doctorul de baterie + kill switch
  iso/                  rețeta live-build pentru stick-ul de instalare
  .github/workflows/    construiește pachetele și ISO-ul, publică depozitul apt
  docs/
```

### 5.4 Cum ajunge o actualizare pe laptop
1. Lucrăm împreună (Claude pe PC-ul cu Windows) în `acm-os` și creștem versiunea.
2. `git push` + tag `v1.x`. **GitHub Actions** construiește pachetele `.deb`, le semnează cu cheia GPG a proiectului (păstrată doar ca secret în GitHub) și publică depozitul apt pe **GitHub Pages**.
3. Pe laptop, `acm-update` verifică zilnic (și la cerere). Afișează în Setări → Actualizări ce e nou, ca în macheta din `design/A-ivory.png`.
4. La „Instalează”: **snapshot Btrfs** → `apt full-upgrade` (pachetele ACM, plus actualizările Debian și Chrome) → snapshot după → cere repornire doar dacă e nevoie.
5. Dacă ceva nu merge: Setări → Actualizări → „Revino la versiunea anterioară”, sau Shift la pornire → alegi snapshot-ul.

### 5.5 Instalarea inițială
- ISO făcut cu `live-build` în GitHub Actions. Pe PC nu e Linux, așa că totul se construiește în cloud.
- Se scrie pe stick cu balenaEtcher (e deja instalat pe PC).
- Installer-ul Calamares, cu tema ACM, cu partiționare Btrfs gata configurată.

### 5.6 Testare
- Ce nu ține de hardware (teme, widget-uri, actualizări) se testează într-o mașină virtuală în CI înainte de publicare.
- Ce ține de hardware se testează pe laptop. **Decizia mea:** ACM OS pornește cu **SSH activ doar în rețeaua de acasă și doar cu cheia PC-ului tău**. Așa pot verifica și repara de pe PC fără să-ți cer să rulezi comenzi. Se poate opri din Setări.

## 6. Interfața (după machetele aprobate)

| Element | Implementare |
|---|---|
| Bara de meniu | Panou Plasma sus, meniu global, sigiliul ACM în colț (meniul „Despre / Setări / Repornire / Oprire”), Wi-Fi, sunet, baterie, căutare, ceas în română |
| Dock | Panou Plasma jos, plutitor, cu iconițele ACM: Fișiere, Chrome, VS Code, Terminal, ACM Studio (după v1), Muzică, Actualizări, Setări, Coș |
| Ferestre | Decorații cu „semafor” (roșu/galben/verde) la stânga, colțuri rotunjite, umbră |
| Widget-uri | 4 plasmoizi QML: Oră și vreme (Oradea, Open-Meteo, fără cont), Baterie (inel auriu), Proiecte (repository-urile git din `~/Proiecte`, ultima activitate), Sistem (timp de pornire, memorie, versiune ACM OS) |
| Căutare | KRunner cu tema ACM, **Ctrl+Space**, plus acțiuni proprii („Caută actualizări”, „Doctor baterie”) |
| Teme | 3 teme globale Plasma: **Ivory, Obsidian, Olive** (culori, fundal cu sigiliu, iconițe, cursor). Accent: auriu implicit, plus 4 alternative |
| Setări → Aspect | Modul propriu: cele 3 teme cu previzualizare, „Schimbă automat” (Ivory ziua, Obsidian seara), accent, widget-uri on/off, sticlă on/off, animații Oprite / Rapide / Line |
| Schimbare automată | Plasma din Debian 13 nu are schimbare zi/noapte inclusă, așa că o face un serviciu mic din `acm-settings` (după răsărit și apus în Oradea) |
| Font | Inter pentru interfață, JetBrains Mono pentru terminal |
| Limbă | Română, ora României |

Fidelitate: Setările Plasma nu vor fi identice pixel cu pixel cu macheta, dar vor folosi aceleași culori, aceleași grupări și aceleași comenzi.

## 7. Claude Code
- Preinstalat la nivel de sistem, cu scurtătură în dock, în căutare și în terminal.
- Instalare prin installer-ul oficial. Dacă binarul nu pornește pe procesorul fără SSE4.2, folosim varianta npm cu Node (se verifică în faza 1).
- **Contul nu e pus în sistem dinainte**, pentru că depozitul cu actualizări e public. La prima pornire apare fereastra „Conectează Claude”: un clic deschide Chrome, utilizatorul confirmă, gata. Autentificarea rămâne doar pe laptop.
- Repository-ul `acm-os` e clonat în `~/Proiecte/acm-os`, ca să se poată lucra la sistem și direct de pe MacBook.

## 8. Doctorul de baterie

### 8.1 Ce poate și ce nu poate face
Încărcarea e controlată de **cipul de protecție din baterie (BMS)** și de **SMC-ul Mac-ului**, nu de sistemul de operare. Software-ul **nu poate da tensiune** bateriei. Ce poate face:
- să citească: prezența bateriei, tensiunea, curentul, starea, capacitatea, numărul de cicluri (`/sys/class/power_supply/BAT0`) și temperaturile (`applesmc`);
- să ghideze resetarea SMC;
- să organizeze cicluri de așteptare la încărcător, tot mai lungi, și să vadă dacă bateria „se trezește”;
- **dacă SMC-ul acestui model permite** (cheile de oprire a încărcării, de tip `CH0B`/`CH0C`, verificate în faza 1): să oprească încărcarea din program. Altfel, oprirea înseamnă un mesaj mare: „Scoate încărcătorul acum”.

### 8.2 Cum arată
- **Setări → Avansat** (ultima intrare din listă) → „Doctor baterie”.
- Apăsare → fereastră de confirmare cu regulile de siguranță. Pe lângă confirmare, utilizatorul bifează că laptopul stă pe o suprafață tare și neinflamabilă și că bateria nu e umflată (trackpad-ul nu e ridicat, carcasa stă drept).
- Cât rulează: **buton KILL SWITCH roșu vizibil permanent în bara de meniu**, plus în fereastra doctorului. Un clic oprește tot instant.

### 8.3 Procedura
1. **Verificare inițială**: bateria e detectată? Încărcătorul e conectat? Se citesc valorile de pornire.
2. **Reset SMC ghidat**: pași pe ecran, iar laptopul se oprește. La repornire doctorul continuă singur de unde a rămas.
3. **Cicluri**: ciclul *n* durează 15 min, apoi 30, 60, 120 și 240 min (maxim). Măsurătoare la fiecare 30 s.
4. **După fiecare ciclu se compară cu ciclul anterior**: crește tensiunea? Apare curent de încărcare? Raportează bateria starea „Charging”?
   - progres → ciclul următor, mai lung;
   - încărcare normală → „Bateria a revenit”, iar doctorul se oprește și lasă încărcarea normală;
   - fără progres după 3 cicluri → „Bateria nu răspunde”, cu recomandarea de înlocuire (A1322).
5. Toate măsurătorile se salvează într-un jurnal, cu grafic în fereastra doctorului.

### 8.4 Oprire automată (pe lângă kill switch)
Doctorul oprește totul și afișează motivul dacă:
- temperatura bateriei trece de **45 °C**, sau crește cu peste **1 °C pe minut**;
- tensiunea pe celulă (tensiunea totală / 3) e sub **2,0 V** la început: aceasta e „celulă moartă” și **nu se încearcă deloc**;
- tensiunea rămâne sub **2,5 V pe celulă** după al doilea ciclu;
- tensiunea scade în timp ce încărcătorul e conectat;
- bateria raportează eroare permanentă sau senzorii nu mai pot fi citiți;
- încărcătorul e scos (procedura se pune pe pauză).

**Decizia mea:** ciclurile de peste o oră cer o confirmare „Sunt lângă laptop”. Procedura nu rulează nesupravegheată peste noapte.

## 9. Ce decide cel care construiește
- Valorile exacte pentru opțiunea driverului de sunet, pentru gesturi și pentru ventilator (după testele pe aparat).
- X11 sau Wayland (după fluiditate).
- Detaliile de pixel ale temelor, în limita machetelor.

## 10. Etape
1. **Recunoaștere hardware**: stick live Debian pe MacBook, script care strânge totul (dispozitive, senzori, baterie, SMC, CPU) și testează Wi-Fi, sunet, somn, Chrome, Claude Code.
2. **Baza**: Debian, drivere, Btrfs + snapshot-uri, pornire rapidă, ISO + installer.
3. **Actualizări**: repository, CI, depozit apt, `acm-update`. **De aici încolo totul vine ca actualizare.**
4. **Interfața**: teme, bară, dock, widget-uri, căutare, Setări → Aspect, Plymouth.
5. **Claude Code** + prima pornire.
6. **Doctorul de baterie.**
7. *(după v1)* ACM Studio, livrat ca actualizare.

## 11. Decizii care țin de utilizator
- [ ] **Windows de pe SSD se șterge complet?** (Implicit: da, ACM OS ia tot SSD-ul.)
- [ ] **Cont GitHub** pentru `acm-os` (necesar pentru actualizări). Pe PC nu e instalat `gh`. Îl instalăm și te loghezi o dată.
- [ ] Stick USB de minim 8 GB pentru instalare și pentru testul din etapa 1.

## 12. Modificări după aprobare (16 nov. 2026)

- **Fără etapa 1 (teste hardware)**, la cererea utilizatorului. Se pleacă de la setările cunoscute pentru MacBookPro7,1. Ce nu merge se repară prin actualizări.
- **Fără ISO propriu.** Pe PC nu există Linux sau WSL. Instalarea se face cu **Debian 13 oficial** (Calamares, disc Btrfs), apoi `install.sh` transformă sistemul în ACM OS.
- **Actualizările vin prin git, nu prin pachete apt proprii.** `/opt/acm-os` e o clonă a repository-ului. `acm-update apply` face snapshot, trece pe ultimul tag `vX.Y.Z`, rulează `acm-apply` (idempotent), apoi `apt full-upgrade` și încă un snapshot. Se păstrează: actualizări mici, anulare (`acm-update rollback`, prin `snapper undochange`) și Debian și Chrome actualizate în același pas. Nu e nevoie de CI pentru pachete.
- SSH de pe PC: amânat (PC-ul nu are încă o cheie SSH). Vine ca actualizare.
- v0.1.0 = baza (drivere, Chrome, Claude Code, limbă, pornire rapidă, actualizări). Temele, widget-urile, Setările ACM și doctorul de baterie vin ca actualizări 0.2+.
- **0.2.0 (aspect ACM):** temele globale Plasma `com.acm.ivory/obsidian/olive` (generate cu `tools/gen-themes.js`), fundaluri, ecran de pornire Plymouth, valori implicite în `/etc/xdg`, comanda `acm-theme`, aplicarea automată la login (`acm-session`) și branding (Despre sistem, os-release, instalator). Widget-urile sunt deocamdată cele standard Plasma (ceas, baterie, memorie). Widget-urile proprii, „Setări → Aspect” și schimbarea automată zi/noapte vin mai târziu.
- **ISO-ul** se construiește doar la taguri `iso-*`, nu la fiecare actualizare `v*`.
