# Ideas — Void Terminal Workflow

Lista 20 propozycji rozwoju wygenerowana po analizie całego projektu
(`index.html`, `docs.html`, `powershell-profile.ps1`, `README.md`,
`system-prompt.md`, szablony `context-*.md`, `test.js`).

**Koszt** — szacowany nakład pracy/tokenów w skali 1–10.
1 = jedna linia, 10 = osobna faza projektu.

Data wygenerowania: 2026-09-01

---

## Tabela zbiorcza

| ID | Pomysł | Cel | Koszt |
|---|---|---|---|
| UI-01 | `scroll-mt` na kotwicach sekcji | Fixed navbar zasłania nagłówki po kliknięciu w link kotwicy | 1 |
| UI-02 | Sticky mini-nav w sekcji CONTEXT.md | Skok do konkretnej komendy w sekcji o wysokości ~6400 px | 4 |
| UI-03 | Meta description + OG/Twitter + favicon | Poprawny podgląd linku w mediach społecznościowych | 2 |
| UI-04 | Przycisk „Pobierz .ps1" w generatorze | Gotowy plik zamiast kopiowania 44 KB przez schowek | 2 |
| UI-05 | Aktualizacja `docs.html` o komendy `ctx-*` | Cheatsheet zgodny z faktyczną zawartością profilu | 3 |
| UI-06 | Live-filtr komend na `docs.html` | Znalezienie komendy wśród ~30 pozycji w sekundę | 4 |
| UI-07 | Dostępność (reduced-motion, focus, skip-link) | Obsługa klawiaturą i wyłączenie animacji dla wrażliwych | 3 |
| LOG-01 | Dopisać brakującą funkcję `scratch` | Komenda reklamowana w dokumentacji, ale nieistniejąca w kodzie | 2 |
| LOG-02 | Fallback generatora bez `fetch()` | Generator działa też po otwarciu `index.html` z dysku | 4 |
| LOG-03 | `init-ctx nextjs` / `init-ctx vps` | Wykorzystanie leżących odłogiem szablonów kontekstu | 3 |
| LOG-04 | `radar`: `Push-Location`/`Pop-Location` | Brak ryzyka pozostawienia użytkownika w cudzym katalogu | 2 |
| LOG-05 | `todo rm` po indeksie zamiast `IndexOf` | Poprawne usuwanie przy zdublowanych nazwach zadań | 2 |
| LOG-06 | Komenda `handoff` | Domknięcie pętli pamięci: sesja → podsumowanie → CONTEXT.md | 4 |
| LOG-07 | `void doctor` — audyt środowiska | Wykrycie braków (git, gh, node, code) przed pierwszym błędem | 3 |
| LOG-08 | Naprawa README | Usunięcie odwołań do nieistniejących plików, aktualna roadmapa | 3 |
| OPT-01 | Cache danych HUD (CPU, bateria, dysk) | Odczuwalnie szybszy znak zachęty po każdej komendzie | 5 |
| OPT-02 | `Get-Clipboard` poza prompt | Koniec odczytu schowka po każdej komendzie (koszt + prywatność) | 1 |
| OPT-03 | Landing: lazy xterm + fonty przez `<link>` | Krótszy czas do pierwszego renderu strony głównej | 4 |
| OPT-04 | Porządki w repo | Usunięcie `test.js`, dodanie `.gitignore`, `master` → `main` | 2 |
| OPT-05 | CI: parse + PSScriptAnalyzer | Złamana składnia profilu nie trafia do użytkowników | 4 |

---

## UI

### UI-01 — `scroll-mt` na kotwicach sekcji · koszt 1
Nawigacja jest `fixed` o wysokości `h-16`, a `<html>` ma `scroll-smooth`.
Po kliknięciu `#kontekst`, `#instalacja` czy `#jak-to-dziala` nagłówek sekcji
ląduje pod paskiem nawigacji. Wystarczy `scroll-mt-20` na każdej sekcji z `id`.

### UI-02 — Sticky mini-nav w sekcji CONTEXT.md · koszt 4
Sekcja `#kontekst` ma ~6400 px wysokości i 8 kart. Boczna, przyklejona lista
(`init-ctx`, `ctx`, `ctxadd`, HUD, `ctx-repo`, `gsave`, `ctx-done`, `onboard`)
z podświetlaniem aktywnej pozycji przez `IntersectionObserver` pozwala skoczyć
prosto do interesującej komendy. Na mobile — poziomy pasek scrollowany.

### UI-03 — Meta description + OG/Twitter + favicon · koszt 2
`index.html` i `docs.html` nie mają `<meta name="description">`, tagów Open Graph
ani favikony. Link wrzucony na Discorda, X czy Slacka pokazuje pustą kartę.
Potrzebne: opis, `og:title`, `og:description`, `og:image` (zrzut terminala HUD),
`twitter:card=summary_large_image` oraz favicon SVG z logo terminala.

### UI-04 — Przycisk „Pobierz .ps1" w generatorze · koszt 2
Obecnie jedyna droga to `copyGeneratedScript()` → wklej do Notatnika.
Przy 44 KB skryptu bywa to zawodne (limity schowka, autokorekta edytora).
Dodać przycisk tworzący `Blob` z wygenerowaną treścią i pobierający
`Microsoft.PowerShell_profile.ps1` — nazwa od razu poprawna.

### UI-05 — Aktualizacja `docs.html` o komendy `ctx-*` · koszt 3
Cheatsheet nie zna `ctx-done`, `ctx-repo`, `ctx-map`, `vibe-review`, `explain`,
`doc-gen` ani `mock-data`. Dodatkowo `docs.html` duplikuje konfigurację Tailwinda
i definicję `.glass-card` z `index.html` — przy okazji warto wyciągnąć wspólne
style do jednego pliku `void.css`.

### UI-06 — Live-filtr komend na `docs.html` · koszt 4
Po dodaniu nowych komend cheatsheet urośnie do ~30 pozycji. Pole tekstowe
filtrujące karty po nazwie i opisie (czysty JS, bez zależności) zamienia
przewijanie w wpisanie trzech liter. Bonus: `/` jako skrót do fokusu na polu.

### UI-07 — Dostępność · koszt 3
Trzy braki: animacja `float` i przejścia działają mimo `prefers-reduced-motion`,
linki i przyciski nie mają wyraźnego `focus-visible`, brak „skip to content".
Do tego kontrast `text-gray-500` na `#0f0f17` jest poniżej progu WCAG AA
dla małego tekstu — warto podnieść do `text-gray-400`.

---

## Logic

### LOG-01 — Dopisać brakującą funkcję `scratch` · koszt 2
`docs.html` opisuje `scratch "Zapytać o padding"` i `scratch clear`, landing
wymienia ją w „arsenale", a funkcja `prompt` odczytuje `$global:VibeScratchpad`
i renderuje go jako `📌`. Samej funkcji **nie ma** — obecnie zmienną ustawia
wyłącznie `vp go`. Wpisanie `scratch` kończy się błędem.

```powershell
function scratch {
    param([string]$Note)
    if (-not $Note -or $Note -eq "clear") { $global:VibeScratchpad = $null; return }
    $global:VibeScratchpad = $Note
}
```

### LOG-02 — Fallback generatora bez `fetch()` · koszt 4
`generateScript()` robi `fetch('./powershell-profile.ps1')`. Przy otwarciu strony
protokołem `file://` (czyli tak, jak zrobi to każdy, kto pobrał repo jako ZIP)
przeglądarka blokuje żądanie i użytkownik dostaje `alert` z błędem.
Opcje: osadzić szablon w `<script type="text/plain">`, albo wykryć `file://`
i pokazać komunikat kierujący do wersji online zamiast surowego błędu.

### LOG-03 — `init-ctx nextjs` / `init-ctx vps` · koszt 3
W repo leżą `context-nextjs.md` i `context-vps.md`, do których nic nie sięga.
`init-ctx` z parametrem presetu (`init-ctx`, `init-ctx nextjs`, `init-ctx vps`)
dawałby szablon dopasowany do typu projektu zamiast jednego generycznego.
Presety można trzymać jako here-stringi w profilu, żeby nie wymagać repo obok.

### LOG-04 — `radar`: `Push-Location`/`Pop-Location` · koszt 2
Pętla po projektach robi `Set-Location $path` i ręcznie zapamiętuje
`$originalPath`, ale gałąź `if (-not (Test-Path $path)) { continue }` wychodzi
z iteracji przed przywróceniem. Przy nieistniejącym folderze na liście
użytkownik zostaje w cudzym katalogu. `Push-Location`/`Pop-Location`
w bloku `finally` usuwa problem u źródła.

### LOG-05 — `todo rm` po indeksie zamiast `IndexOf` · koszt 2
`$todos = $todos | Where-Object { $todos.IndexOf($_) -ne $idx }` — `IndexOf`
zwraca pozycję **pierwszego** dopasowania, więc przy dwóch identycznych
zadaniach usuwane jest złe albo oba naraz. Filtr powinien iść po indeksie pętli.

### LOG-06 — Komenda `handoff` · koszt 4
`system-prompt.md` definiuje tag `HANDOFF:`, ale nic go nie automatyzuje.
Komenda `handoff` generowałaby prompt („streść dzisiejszą pracę w 5 punktach"),
a `handoff paste` wklejałaby odpowiedź ze schowka prosto do sekcji
`## Log postępu` w `CONTEXT.md`. To domyka pętlę: sesja → podsumowanie → pamięć.

### LOG-07 — `void doctor` — audyt środowiska · koszt 3
Sprawdza obecność `git`, `gh`, `node`, `code`, wartość `ExecutionPolicy`,
autoryzację `gh auth status` i istnienie `$PROFILE`. Wypisuje tabelę
zielony/czerwony z gotową komendą naprawczą przy każdym braku.
Zamienia „coś nie działa" na konkretną listę do odhaczenia.

### LOG-08 — Naprawa README · koszt 3
README instruuje, by otworzyć `2026-08-29-terminal-workflow-chatgpt-prompt.md`,
`...-powershell-profile.ps1` i `...-context-template.md` — żaden z tych plików
nie istnieje (w repo są `system-prompt.md`, `powershell-profile.ps1`,
`context-template.md`). Roadmapa kończy się na Fazie 3, mimo że V4 jest wdrożone.

---

## Optimization

### OPT-01 — Cache danych HUD · koszt 5
Funkcja `prompt` przy **każdym** znaku zachęty wywołuje:
`Get-CimInstance Win32_Processor`, `Get-CimInstance Win32_Battery`,
`Get-Volume`, `Get-Process Spotify`, `Get-Clipboard`, `Get-ChildItem`
oraz dwa wywołania `git`. Zapytania CIM/WMI to najdroższy element —
potrafią dołożyć kilkaset milisekund do każdej komendy.
Rozwiązanie: cache w zmiennych globalnych ze znacznikiem czasu i odświeżaniem
co ~5 sekund; git zostaje na żywo, bo zmienia się najczęściej.

### OPT-02 — `Get-Clipboard` poza prompt · koszt 1
HUD czyta schowek po każdej komendzie tylko po to, by pokazać jego długość.
Poza kosztem to również odczyt treści, których terminal nie potrzebuje —
a w schowku bywają hasła i tokeny. Wyłączyć domyślnie albo schować
za flagą w `$global:VoidConfig`.

### OPT-03 — Landing: lazy xterm + fonty przez `<link>` · koszt 4
`index.html` ładuje trzy pliki xterm (CSS + lib + addon) zawsze, mimo że demo
terminala jest jednym z wielu elementów strony. Do tego fonty Google są
wciągane przez `@import` wewnątrz `<style>`, co blokuje render.
Poprawki: `<link rel="preconnect">` + `<link rel="stylesheet">` zamiast
`@import`, oraz doładowanie xterm dopiero gdy kontener wejdzie w viewport.

### OPT-04 — Porządki w repo · koszt 2
Trzy drobiazgi: `test.js` to przypadkowo zacommitowany fragment konfiguracji
Tailwinda (29 linii, nic go nie importuje) — do usunięcia; brakuje `.gitignore`
(przy `snapshot` do katalogu trafiają pliki `backup_*.zip`); branch główny
nazywa się `master`, wbrew przyjętej konwencji `main`.

### OPT-05 — CI: parse + PSScriptAnalyzer · koszt 4
Błąd składni w `powershell-profile.ps1` psuje terminal każdemu, kto skopiuje
plik — a wykrywa się go dopiero po wklejeniu. GitHub Actions z krokami
`[Parser]::ParseFile` oraz `Invoke-ScriptAnalyzer` łapie to na pull requeście.
Przy okazji można sprawdzać, czy komendy opisane w `index.html` i `docs.html`
faktycznie istnieją w profilu — dokumentacja rozjeżdżała się z kodem już dwa razy.
