# README — Zestaw do pracy z LLM i terminalem na Windows

Instrukcja dla osoby, która terminal widziała, ale nie czuje się w nim swobodnie.
Nie musisz rozumieć wszystkiego od razu — wystarczy przejść instalację i zacząć
używać jednej rzeczy naraz.

---

## 1. Po co to jest

Kiedy prosisz ChatGPT o pomoc przy projekcie, zwykle dzieje się tak:

- model daje jedną komendę, czekasz, wklejasz, on daje drugą, znowu czekasz —
  prosta rzecz zajmuje dwadzieścia wiadomości
- nie wiesz, czy komenda się udała, bo nie wiesz, co powinno się pojawić na ekranie
- model pisze "dodaj tę linijkę w pliku" i nie wiadomo gdzie dokładnie
- w nowej rozmowie model nie pamięta nic o Twoim projekcie i zaczynasz od zera
- gdy pojawia się błąd, przepisujesz go ręcznie albo zaznaczasz myszką pół ekranu

Ten zestaw usuwa te pięć problemów. Składa się z trzech elementów:

| Plik | Co robi | Gdzie trafia |
|---|---|---|
| `...-chatgpt-prompt.md` | Zmienia sposób, w jaki ChatGPT Ci odpowiada | Ustawienia ChatGPT |
| `...-powershell-profile.ps1` | Dodaje skróty w terminalu i nagrywa sesje | Twój komputer |
| `...-context-template.md` | Pamięć projektu do wklejania modelowi | Katalog projektu |

Elementy działają osobno. Możesz wdrożyć tylko pierwszy i już będzie lepiej.

---

## 2. Słowniczek (jeśli terminal to dla Ciebie nowość)

- **Terminal / Windows Terminal** — okno, w którym wpisuje się komendy tekstem.
  To tylko *okno*. W środku działa program zwany powłoką.
- **PowerShell** — powłoka, czyli język tych komend. To ona rozumie, co piszesz.
- **Profil PowerShell** — plik z ustawieniami, który uruchamia się automatycznie
  przy każdym otwarciu terminala. Tam wkleimy skróty.
- **Schowek** — miejsce, gdzie ląduje to, co kopiujesz przez Ctrl+C.
- **Repo / repozytorium** — katalog Twojego projektu (zwykle z Gitem).

## 🚀 Roadmap (Plany na przyszłość)

- [x] **Faza 1:** Wersja ratunkowa dla programistów (NPM Nuke, File Copier, Git Auto-Save)
- [x] **Faza 2:** Skrypt z "osobowością" i motywami (Interaktywne Demo)
- [x] **Faza 2.5:** Void Project Hub (Zarządzanie ścieżkami projektów i globalny `radar`)
- [x] **Faza 3:** Architektura V3 HUD & Moduły (Podwójny pasek statusu, księżyc, CPU, 12 nowych komend)
- [ ] **Faza 4 (Wkrótce):** Void Web Dashboard (Panel w przeglądarce podłączony do terminala)
- [ ] **Faza 5:** Wsparcie dla WSL2 (Tux radar)

## 🧩 Moduły i Funkcje

### Interfejs HUD (V3)
Terminal posiada teraz podwójny pasek statusu (Górna i Dolna belka). W zależności od wybranego Vibe'u, informują one o aktualnej fazie księżyca, procesorze, odtwarzanej muzyce (w oknie PC), statusie Git i niezapisanym kodzie. W przypadku bycia na gałęzi `main`/`master` zapali się czerwony alarm produkcyjny!

### Void Project Hub (Zarządzanie projektami)
* `vp add [nazwa]` - Dodaje obecny folder do radaru pod wybraną nazwą.
* `vp go [nazwa]` - Natychmiast teleportuje (cd) do projektu i wczytuje Twoje ostatnie zadanie!
* `radar` - Renderuje tablicę pokazującą wszystkie Twoje projekty, wykryty Tech Stack oraz status Gita.

### Mega-Narzędzia AI & Ratunkowe
Wpisz w terminalu `void`, aby zobaczyć pełną pomoc. Oto najważniejsze nowości:
* `wtf` - Kopiuje z promptem dla AI ostatni wyrzucony w konsoli błąd.
* `onboard` - Skanuje strukturę projektu i package.json do jednego Mega-Promptu dla nowej rozmowy.
* `review` - Pakuje obecnego git diff w prompt o Code Review.
* `todo` - Szybki system zarządzania zadaniami w konsoli (`todo add`, `todo done`). Aktywne zadanie wyświetli się na pasku HUD!
* `clean-space` - Czyści projekt z `node_modules` i innych śmieci odzyskując gigabajty miejsca.
* `snapshot` - Wykonuje lekki backup ZIP Twojego projektu z pominięciem śmieci, w ułamku sekundy.
* `qr-link 3000` - Generuje ASCII kod QR z Twoim lokalnym IP do testowania apki na telefonie.
* `brb` - Zablokuj ekran terminala Matrixowym wygaszaczem (Zaraz Wracam).
* `rage-quit` - Wymusza szybki zapis Gita (WIP), rzuca stołem w ASCII i zamyka terminal.

---

## 3. Instalacja

### Krok A — prompt do ChatGPT (2 minuty)

1. Otwórz ChatGPT → kliknij swój awatar → **Settings** → **Personalization**
   → **Custom instructions**.
2. Otwórz plik `2026-08-29-terminal-workflow-chatgpt-prompt.md`.
3. Skopiuj tekst z pierwszego dużego bloku kodu (ten zaczynający się od
   `## ŚRODOWISKO`).
4. Wklej do pola **"How would you like ChatGPT to respond?"**.
5. Zapisz.

Jeśli ChatGPT powie, że tekst jest za długi — skopiuj zamiast tego
**wersję skróconą** z końca tego samego pliku.

Gotowe. Od tej chwili każda nowa rozmowa działa według nowych zasad.
Starych rozmów to nie zmieni — zacznij nową.

### Krok B — profil PowerShell (5 minut)

1. Otwórz Windows Terminal.
2. Wpisz i zatwierdź Enterem:

```powershell
# sprawdza, czy plik profilu już istnieje, i tworzy go, jeśli nie
if (-not (Test-Path $PROFILE)) { New-Item -Path $PROFILE -ItemType File -Force }

# otwiera plik profilu w Notatniku
notepad $PROFILE
```

3. Otworzy się Notatnik — być może pusty, to normalne.
4. Otwórz plik `2026-08-29-terminal-workflow-powershell-profile.ps1`,
   skopiuj **całą** zawartość i wklej na końcu Notatnika.
5. Zapisz (Ctrl+S) i zamknij Notatnik.
6. Wróć do terminala i wpisz:

```powershell
# przeładowuje profil bez zamykania okna
. $PROFILE
```

**Oczekiwany wynik:** na dole pojawią się dwie szare linijki — ścieżka do pliku
z logiem sesji oraz lista skrótów: `loglast / runc / tree2 / filec / ctx / gs / gl`.

**Jeśli błąd** `nie można załadować, ponieważ w tym systemie zablokowano
wykonywanie skryptów` — wpisz raz to:

```powershell
# pozwala uruchamiać własne skrypty (nadal blokuje niepodpisane z internetu)
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Potwierdź literą `T` (lub `Y`) i powtórz `. $PROFILE`.

### Krok C — CONTEXT.md (przy okazji nowego projektu)

1. Wejdź do katalogu projektu.
2. Skopiuj szablon z pliku `2026-08-29-terminal-workflow-context-template.md`
   (blok kodu w środku) do nowego pliku `CONTEXT.md` w katalogu projektu.
3. Wypełnij, co wiesz. Puste pola możesz zostawić — uzupełnią się w praktyce.

Do istniejących, dużych projektów nie wypełniaj tego ręcznie wstecz.
Poproś model: `HANDOFF: przygotuj CONTEXT.md na podstawie tej rozmowy`.

---

## 4. Jak tego używać na co dzień

### 4.1 Słowa-wyzwalacze w ChatGPT

Zaczynasz wiadomość jednym z haseł i wymuszasz konkretny format odpowiedzi:

| Hasło | Co dostajesz |
|---|---|
| `TERMINAL:` | Sam blok komend, bez teorii, plus jak sprawdzić, czy się udało |
| `PLIK:` | Cała zawartość pliku do podmiany, bez komentarzy |
| `SKRYPT:` | Jeden gotowy plik `.ps1` do uruchomienia |
| `STATUS:` | Podsumowanie etapów, co zrobione, co dalej — bez kodu |
| `HANDOFF:` | Streszczenie projektu do wklejenia w innej rozmowie lub innym modelu |
| `WYJAŚNIJ:` | Samo wytłumaczenie, żadnych komend |

Przykład:

```
TERMINAL: zainstaluj Prisma w moim projekcie Next.js i wygeneruj pierwszą migrację
```

Dostaniesz jeden blok ze wszystkimi komendami naraz, każdą z komentarzem `#`,
a pod spodem: co powinno się pojawić na ekranie, jedną komendę weryfikującą
i listę typowych błędów.

### 4.2 Skróty w terminalu

**`runc "komenda"` — uruchom i skopiuj wynik**

```powershell
runc "npm run build"
```

Wynik pokaże się na ekranie **i** wyląduje w schowku. Wklejasz do ChatGPT
przez Ctrl+V. Cudzysłowy są konieczne.

**`loglast` — ostatnie linie z logu sesji**

```powershell
loglast        # ostatnie 60 linii
loglast 200    # ostatnie 200 linii
```

Przydaje się, gdy błąd wystąpił dziesięć komend temu i już go nie widać.
Wszystko, co się działo w tym oknie, jest nagrywane do pliku
`C:\Users\TwojaNazwa\terminal-logs\`. Logi starsze niż 14 dni kasują się same.

**`tree2` — struktura projektu**

```powershell
tree2      # 2 poziomy w głąb
tree2 3    # 3 poziomy
```

Pomija `node_modules`, `.git` i inne śmieci. Wynik ląduje w schowku —
świetny na początek rozmowy, gdy model ma zrozumieć układ projektu.

**`filec ścieżka` — zawartość pliku do schowka**

```powershell
filec .\src\app\page.tsx
```

Kopiuje plik razem z nagłówkiem ze ścieżką, więc model od razu wie, o którym
pliku mowa.

**Drobiazgi:** `gs` = `git status`, `gl` = ostatnie 15 commitów,
`ll` = lista plików, `ctx` = otwórz `CONTEXT.md`.

---

## 5. Przykład pełnej sesji

Załóżmy, że dodajesz logowanie do aplikacji.

**1. Otwierasz terminal w katalogu projektu i dajesz modelowi kontekst:**

```powershell
filec .\CONTEXT.md
```

W ChatGPT: Ctrl+V, Enter. Model wie, na czym pracujesz.

**2. Prosisz o plan:**

```
Chcę dodać logowanie przez e-mail i hasło. Zaproponuj plan etapów.
```

Model zwraca ponumerowany plan, np. 5 etapów.

**3. Ruszasz z pierwszym etapem:**

```
TERMINAL: etap 1
```

Dostajesz jeden blok, np.:

```powershell
# instaluje bibliotekę do obsługi sesji
npm install next-auth

# tworzy katalog na konfigurację
New-Item -ItemType Directory -Path .\src\app\api\auth -Force
```

Pod spodem: **Oczekiwany wynik** (`added 12 packages`),
**Weryfikacja** (`npm list next-auth`), **Jeśli błąd** (np. konflikt wersji).

**4. Wklejasz cały blok do terminala jednym Ctrl+V.** Nic się nie udało?

```powershell
loglast 80
```

Ctrl+V w ChatGPT i piszesz: `to jest błąd, popraw`.

**5. Model chce zmienić plik.** Dzięki promptowi dostajesz całą jego zawartość,
nie fragment. Otwierasz plik, zaznaczasz wszystko (Ctrl+A), wklejasz, zapisujesz.

**6. Koniec pracy — aktualizujesz pamięć projektu:**

```
HANDOFF: zaktualizuj CONTEXT.md na podstawie tej rozmowy. Zwróć cały plik.
```

Wklejasz wynik do `CONTEXT.md`. Następnym razem zaczynasz od punktu 1
i model wie wszystko, mimo że rozmowa jest nowa.

---

## 6. Częste problemy

**„Model dalej odpowiada po staremu"**
Custom instructions działają tylko w nowych rozmowach. Zacznij nową.
Sprawdź też, czy wkleiłeś tekst w pole *"How would you like ChatGPT to respond?"*,
a nie w to o Tobie.

**„Po restarcie terminala skróty zniknęły"**
Profil zapisał się w złym miejscu albo Notatnik dodał rozszerzenie `.txt`.
Sprawdź: `Test-Path $PROFILE` — ma zwrócić `True`.

**„`runc` nie działa"**
Komenda musi być w cudzysłowie: `runc "npm run dev"`, nie `runc npm run dev`.
Uwaga: `runc` nie nadaje się do komend, które działają w nieskończoność
(jak `npm run dev`) — wynik trafi do schowka dopiero po ich zatrzymaniu.

**„Wklejam wiele komend naraz i coś się gubi"**
W Windows Terminal wklejanie wielu linii wykonuje je po kolei automatycznie.
Jeśli któraś zapyta o potwierdzenie, kolejne mogą zostać zjedzone jako odpowiedź.
Przy blokach z pytaniami wklejaj po kawałku.

**„Boję się, że komenda coś skasuje"**
Prompt każe modelowi oznaczać takie komendy jako `# UWAGA:`.
Gdy taką zobaczysz — przeczytaj komentarz, zanim wkleisz. W razie wątpliwości:
`WYJAŚNIJ: co dokładnie robi ta komenda i co się stanie, jeśli ją cofnę`.

---

## 7. Co warto zmienić pod siebie

- **Czas trzymania logów** — w profilu linia z `AddDays(-14)`.
- **Powłoka** — jeśli używasz WSL zamiast PowerShella, zmień sekcję
  `## ŚRODOWISKO` w promptcie; profil PowerShella wtedy nie zadziała.
- **Własne słowa-wyzwalacze** — dopisz je w sekcji `## SŁOWA-WYZWALACZE`
  według tego samego wzoru: hasło, strzałka, opis formatu.

---


---

## 🔮 Void Workflow V4: Pełen Zestaw Vibe-Codera

Narzędzie jest zorganizowane wokół 5 filarów.

### 🧠 Kontekst i Pamięć AI
- **`init-ctx`** - Tworzy pusty plik `CONTEXT.md` gotowy do wypełnienia celami.
- **`ctxadd "Notatka"`** - Szybkie dodawanie nowej linii do pliku pamięci AI z terminala.
- **`onboard`** - Zrzuca całą strukturę plików + `CONTEXT.md` i ładuje do pamięci AI.
- **`ctx-map`** - Skupia się na mapie projektu dla AI (architektura plików bez opisów).

### 🛸 Terminal HUD i Ostrzeżenia
- **Podwójny Pasek:** Na bieżąco śledzi użycie CPU `▃▅▇`, Baterię, Git Branch oraz Czas Wykonywania komend!
- **Alarm Git:** Czerwony migający alarm, jeśli przypadkiem kodujesz wprost na `master` / `main`.
- **Offline Radar & Zombie Scanner:** Wyłapywanie procesów `node` zamulających sprzęt oraz brak łączności z siecią.
- **Faza Księżyca 🌕:** Wyliczana z UNIX Timestamp przy starcie konsoli - dowiadujesz się kiedy pełnia.

### ⚡ Vibe-Coding (AI Skróty)
*Jeżeli zaznaczysz Auto-Otwieranie w Instalatorze, po każdej komendzie terminal sam uruchomi Ci kartę z ChatGPT!*
- **`vibe-review`** - Zbiera zmiany (git diff) i kopiuje z poleceniem zrobienia brutalnego, ostrego Code Review.
- **`explain plik.js`** - Obejmuje cały plik, ładuje do AI z nakazem wytłumaczenia go krok po kroku.
- **`doc-gen folder`** - Przeszukuje kod i tworzy polecenie napisania README do tego modułu.
- **`mock-data "użytkownicy"`** - Skrót, po którym AI generuje 50 rekordów w czystym, gotowym formacie JSON.

### 🚑 Ratunek i Zapis
- **`gsave "Wiadomość"`** - Szybki add, commit, push. **(Dodatkowo sprawdza, czy odhaczyłeś cel w `CONTEXT.md`. Jeśli tak - wystrzeliwuje fajerwerki! 🌟)**
- **`gundo`** - Cofa ostatni, pomyłkowy lokalny commit (soft).
- **`wtf`** - Łapie ostatni potężny, czerwony błąd z terminala, zawija go w elegancki format markdown i prosi AI o solucję.
- **`npmnuke`** - Absolutna opcja nuklearna. Kasuje `node_modules` i locki w 2 sekundy (nawet dla folderów zagnieżdżonych głęboko) i instaluje czystą paczkę.

### 🕹️ Styl Życia
- **`brb`** - Wychodzisz na kawę? Uruchamia spadający kod a'la Matrix, blokując terminal przed wścibskimi.
- **`rage-quit`** - Kiedy masz dość. Zapisuje to co masz komiksem "WIP", po czym wyrzuca na pulpit.
- **`todo`** - Mini lista wprost nad kodem (add, done, rm).
