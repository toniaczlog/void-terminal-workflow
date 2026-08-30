# =====================================================================
#  Profil PowerShell — logowanie sesji + skróty do pracy z LLM
#  Instalacja:
#    1. notepad $PROFILE      # jeśli plik nie istnieje: New-Item -Path $PROFILE -ItemType File -Force
#    2. wklej całość, zapisz
#    3. . $PROFILE            # przeładowanie bez restartu
# =====================================================================

# --- 1. Automatyczne logowanie każdej sesji -------------------------
# Każde okno terminala zapisuje pełny przebieg do pliku .log.
# Potem wklejasz fragment do modelu zamiast opisywać błąd z pamięci.

$LogDir = "$HOME\terminal-logs"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }

$LogFile = Join-Path $LogDir ("{0}-session.log" -f (Get-Date -Format "yyyy-MM-dd-HHmmss"))
try { Start-Transcript -Path $LogFile -Append | Out-Null } catch { }

# Sprzątanie logów starszych niż 14 dni
Get-ChildItem $LogDir -Filter *.log -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-14) } |
    Remove-Item -Force -ErrorAction SilentlyContinue

# --- 2. Funkcje pomocnicze do przenoszenia danych do modelu ---------

# Ostatnie N linii bieżącego logu prosto do schowka.
# Użycie:  loglast        (domyślnie 60 linii)
#          loglast 200
function loglast {
    param([int]$Lines = 60)
    Stop-Transcript | Out-Null
    Get-Content $LogFile -Tail $Lines | Set-Clipboard
    Start-Transcript -Path $LogFile -Append | Out-Null
    Write-Host "Skopiowano ostatnie $Lines linii do schowka." -ForegroundColor Green
}

# Uruchamia komendę, pokazuje wynik NA EKRANIE i kopiuje go do schowka.
# Użycie:  runc "npm run build"
function runc {
    param([Parameter(Mandatory)][string]$Command)
    $out = Invoke-Expression "$Command 2>&1" | Out-String
    Write-Host $out
    $out | Set-Clipboard
    Write-Host "--- wynik skopiowany do schowka ---" -ForegroundColor Green
}

# Drzewo projektu bez śmieci — do wklejenia jako kontekst dla modelu.
# Użycie:  tree2          (2 poziomy)
#          tree2 3
function tree2 {
    param([int]$Depth = 2)
    $skip = 'node_modules|\.git|\.next|dist|build|\.venv|__pycache__'
    $out = Get-ChildItem -Recurse -Depth $Depth |
        Where-Object { $_.FullName -notmatch $skip } |
        ForEach-Object { $_.FullName.Replace((Get-Location).Path, '.') } |
        Out-String
    Write-Host $out
    $out | Set-Clipboard
    Write-Host "--- drzewo skopiowane do schowka ---" -ForegroundColor Green
}

# Zawartość pliku do schowka razem ze ścieżką w nagłówku.
# Użycie:  filec .\src\app.ts
function filec {
    param([Parameter(Mandatory)][string]$Path)
    $body = "=== $Path ===`n" + (Get-Content $Path -Raw)
    $body | Set-Clipboard
    Write-Host "Skopiowano zawartość $Path do schowka." -ForegroundColor Green
}

# Otwiera / tworzy CONTEXT.md w bieżącym repo.
function ctx { code .\CONTEXT.md 2>$null; if ($LASTEXITCODE) { notepad .\CONTEXT.md } }

# --- 3. Drobne aliasy ----------------------------------------------
Set-Alias g   git
Set-Alias ll  Get-ChildItem
function gs  { git status -sb }
function gl  { git log --oneline -15 }
function ..  { Set-Location .. }

# --- 4. Zestaw narzędzi Vibe-Coder (Etapy 1-6) -----------------------

# Etap 1: NPM Nuke (czyszczenie cache i node_modules)
function npmnuke {
    Write-Host "Czyszczenie projektu zepsutego przez pakiety NPM..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force node_modules -ErrorAction SilentlyContinue
    Remove-Item package-lock.json -ErrorAction SilentlyContinue
    npm cache clean --force
    npm install
    Write-Host "Zakończono. Spróbuj teraz uruchomić projekt." -ForegroundColor Green
}

# Etap 2: Baza komend (cheat, zapamietaj, przypomnij)
function cheat {
    param([string]$Topic)
    if (-not $Topic) {
        Write-Host "Użycie: cheat <vps|git|npm>"
        return
    }
    switch ($Topic.ToLower()) {
        "vps" {
            Write-Host "--- Ściąga: VPS ---" -ForegroundColor Cyan
            Write-Host "Połączenie:  ssh user@12.34.56.78 -i ~/.ssh/klucz"
            Write-Host "Kopiowanie:  scp plik.txt user@12.34.56.78:/katalog"
            Write-Host "Logi PM2:    pm2 logs"
        }
        "git" {
            Write-Host "--- Ściąga: GIT ---" -ForegroundColor Cyan
            Write-Host "Cofnij zm.:  git checkout -- ."
            Write-Host "Cofnij com:  gundo (cofa commita, zostawia pliki)"
            Write-Host "Szybki zap:  gsave 'moj commit'"
        }
        "npm" {
            Write-Host "--- Ściąga: NPM ---" -ForegroundColor Cyan
            Write-Host "Uruchom:     npm run dev"
            Write-Host "Instaluj:    npm install paczka"
            Write-Host "Zresetuj:    npmnuke (nasza funkcja ratunkowa)"
        }
        default { Write-Host "Brak ściągi dla: $Topic" -ForegroundColor Red }
    }
}

$VoidCmdsFile = "$HOME\.void-cmds.json"
function zapamietaj {
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Command)
    $cmds = @{}
    if (Test-Path $VoidCmdsFile) { $cmds = Get-Content $VoidCmdsFile | ConvertFrom-Json -AsHashtable }
    $cmds[$Name] = $Command
    $cmds | ConvertTo-Json | Set-Content $VoidCmdsFile
    Write-Host "Zapamiętano komendę '$Name'. Użyj 'przypomnij $Name'." -ForegroundColor Green
}
function przypomnij {
    param([Parameter(Mandatory)][string]$Name)
    if (-not (Test-Path $VoidCmdsFile)) { Write-Host "Brak zapamiętanych komend." -ForegroundColor Red; return }
    $cmds = Get-Content $VoidCmdsFile | ConvertFrom-Json -AsHashtable
    if ($cmds.Contains($Name)) {
        Write-Host "Wykonuję: $($cmds[$Name])" -ForegroundColor Cyan
        Invoke-Expression $cmds[$Name]
    } else {
        Write-Host "Nie znaleziono komendy o nazwie '$Name'." -ForegroundColor Red
    }
}

# Etap 3: Git Auto-Zapis i Gundo
function gsave {
    param([Parameter(Mandatory)][string]$Message)
    git add .
    git commit -m $Message
    if ($LASTEXITCODE -ne 0) { Write-Host "Brak zmian lub błąd commita." -ForegroundColor Yellow; return }
    git push
    if ($LASTEXITCODE -eq 0) { Write-Host "Sukces! Zmiany na GitHubie." -ForegroundColor Green }
}
function gundo {
    git reset HEAD~1
    Write-Host "Cofnięto ostatni commit, ale zmiany w plikach pozostały bezpieczne na dysku." -ForegroundColor Green
}

# Etap 4: Bezpieczny Deploy
function safedeploy {
    Write-Host "Budowanie aplikacji (npm run build)..." -ForegroundColor Cyan
    $out = npm run build 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
        Write-Host $out
        Write-Host "Build poprawny. Trwa deploy..." -ForegroundColor Green
        # Przykładowy deploy na Vercel (jeśli zainstalowane CLI)
        vercel --prod
    } else {
        Write-Host $out -ForegroundColor Red
        $out | Set-Clipboard
        Write-Host "Build ZAKOŃCZONY BŁĘDEM. Treść błędu skopiowano do schowka! Wklej ją w ChatGPT." -ForegroundColor Yellow
    }
}

# Etap 5: Szybkie notatki kontekstu
function ctxadd {
    param([Parameter(Mandatory)][string]$Note)
    if (Test-Path ".\CONTEXT.md") {
        "`n- $(Get-Date -Format 'yyyy-MM-dd'): $Note" | Add-Content ".\CONTEXT.md"
        Write-Host "Notatka dodana do CONTEXT.md" -ForegroundColor Green
    } else {
        Write-Host "Brak pliku CONTEXT.md w tym folderze." -ForegroundColor Red
    }
}

# Etap 6: System Pomocy terminalowej
function void { pomoc }
function pomoc {
    Write-Host ""
    Write-Host "============ VOID WORKFLOW - SYSTEM POMOCY ============" -ForegroundColor Magenta
    Write-Host " GIT & ZAPISYWANIE:" -ForegroundColor Cyan
    Write-Host "  gsave `"text`" - Szybki commit i push"
    Write-Host "  undo / whoops- Cofa commita (nie rusza plików)"
    Write-Host "  snapshot     - Szybki backup projektu do ZIP"
    Write-Host ""
    Write-Host " RATUNEK & BŁĘDY:" -ForegroundColor Cyan
    Write-Host "  wtf          - Kopiuje ostatni błąd do promptu dla AI"
    Write-Host "  loglast 50   - Kopiuje ostatnie 50 linii z terminala"
    Write-Host "  npmnuke      - Resetuje cache NPM i node_modules"
    Write-Host "  clean-space  - Usuwa gigabajty śmieci (node_modules, dist)"
    Write-Host "  port-kill    - Zabija proces blokujący dany port"
    Write-Host ""
    Write-Host " NARZĘDZIA DLA CHATGPT:" -ForegroundColor Cyan
    Write-Host "  onboard      - Generuje Mega-Prompt ze strukturą projektu"
    Write-Host "  review       - Pobiera zmiany (diff) z promptem code review"
    Write-Host "  filec plik   - Kopiuje plik z nagłówkiem"
    Write-Host "  tree2        - Kopiuje drzewo plików (2 poziomy)"
    Write-Host ""
    Write-Host " VIBE & INNE:" -ForegroundColor Cyan
    Write-Host "  vp           - Void Project Hub (dodawanie i skakanie)"
    Write-Host "  radar        - Sprawdza status gita dla wszystkich projektów"
    Write-Host "  todo         - Menedżer zadań (todo add, todo list, todo done)"
    Write-Host "  brb          - Zablokuj ekran / Matrix screensaver"
    Write-Host "  qr-link 3000 - Wygeneruj kod QR do testów na mobile"
    Write-Host "  mock-server  - Szybki serwer statyczny HTTP"
    Write-Host "  stats        - Statystyki kodu i plików"
    Write-Host "  vibe-check   - Paswyno-agresywny linter"
    Write-Host "  focus        - Tryb ZEN (ukrywa ostrzeżenia)"
    Write-Host "  rage-quit    - Przycisk paniki (Commit + Exit)"
    Write-Host "=======================================================" -ForegroundColor Magenta
    Write-Host ""
}

# --- 5. Cybepunkowy, Artystyczny Znak Zachęty (Prompt) ----------------

# =====================================================================
# SYSTEM MOTYWÓW (THEMES)
# =====================================================================
$global:VoidConfig = @{
    Theme = "Colourblocks" # Opcje: Default, QuestLog, Matrix, Magic, Colourblocks
    EnableZombieScanner = $true
    EnableOfflineRadar = $true
}

function Get-VoidTheme {
    param([string]$ThemeName)
    $theme = @{}
    
    # --- DEFAULT (Asystent) ---
    $theme.ColorBracket = "DarkGray"
    $theme.ColorText = "Cyan"
    $theme.ColorPath = "Cyan"
    $theme.ColorError = "Red"
    $theme.ColorSuccess = "Green"
    $theme.ColorGitDirty = "Red"
    $theme.ColorGitClean = "Yellow"
    
    $theme.PrefixNode = "⚛️ O, projekt w Node!"
    $theme.PrefixNodeMissing = "📦 (Psst, brakuje node_modules - wpisz 'npm install' lub 'npmnuke')"
    $theme.PrefixDocker = "🐳 Widzę Dockera"
    $theme.PrefixPython = "🐍 Pythonowe klimaty"
    $theme.MsgGitDirty = "⚠️ Masz niezapisany kod na branchu '{0}' (zrób 'gsave')"
    $theme.MsgZombie = "🧟 Znalazłem {0} ukryte procesy Node (może zamulać)"
    $theme.MsgOffline = "❌ Houston, odcięło nas od AI! Brak neta."
    $theme.SymbolOk = " ⚡ "
    $theme.SymbolErr = " ✖ "
    $theme.PromptChar = "»"
    $theme.PromptCharColor = "Magenta"
    $theme.GreetingMorning = "🌅 Dzień dobry"
    $theme.GreetingDay = "☕ Środek dnia"
    $theme.GreetingEvening = "🌙 Wieczorne kodowanie"
    $theme.GreetingNight = "🦉 Nocna warta"
    $theme.GreetingFriday = "🎉 Piąteczek! Czas na deploy"
    $theme.LogoLines = @(
        "    __      __  ____    _____  _____  ",
        "    \ \    / / / __ \  |_   _||  __ \ ",
        "     \ \  / / | |  | |   | |  | |  | |",
        "      \ \/ /  | |  | |   | |  | |  | |",
        "       \  /   | |__| |  _| |_ | |__| |",
        "        \/     \____/  |_____||_____/ "
    )
    $theme.LogoColor = "Magenta"

    switch ($ThemeName) {
        "Matrix" {
            $theme.ColorBracket = "DarkGreen"
            $theme.ColorText = "Green"
            $theme.ColorPath = "Green"
            $theme.ColorError = "DarkRed"
            $theme.ColorSuccess = "DarkGreen"
            $theme.ColorGitDirty = "DarkRed"
            $theme.ColorGitClean = "DarkGreen"
            $theme.PrefixNode = "[ MODULE: NODE.JS DETECTED ]"
            $theme.PrefixNodeMissing = "[ ERROR: NODE_MODULES NOT FOUND ]"
            $theme.PrefixDocker = "[ MODULE: DOCKER DETECTED ]"
            $theme.PrefixPython = "[ MODULE: PYTHON DETECTED ]"
            $theme.MsgGitDirty = "[ WARNING: UNCOMMITTED CHANGES ON '{0}' ]"
            $theme.MsgZombie = "[ ZOMBIE PROCESS DETECTED: {0} ]"
            $theme.MsgOffline = "[ CRITICAL: CONNECTION LOST ]"
            $theme.SymbolOk = " OK "
            $theme.SymbolErr = " ERR "
            $theme.PromptChar = ">"
            $theme.PromptCharColor = "Green"
            $theme.GreetingMorning = "WAKE UP NEO"
            $theme.GreetingDay = "SYSTEM ACTIVE"
            $theme.GreetingEvening = "SYSTEM ACTIVE"
            $theme.GreetingNight = "FOLLOW THE WHITE RABBIT"
            $theme.GreetingFriday = "SYSTEM ACTIVE"
            $theme.LogoLines = @(
                "    01010110  01001111  01001001  01000100",
                "    01010110  01001111  01001001  01000100",
                "    V         O         I         D       "
            )
            $theme.LogoColor = "Green"
        }
        "QuestLog" {
            $theme.ColorGitClean = "Cyan"
            $theme.PrefixNode = "📜 Magiczny Zwój Node.js"
            $theme.PrefixNodeMissing = "🎒 (Brakuje składników: node_modules)"
            $theme.PrefixDocker = "⚓ Karczma portowa (Docker)"
            $theme.PrefixPython = "🐉 Smocze Języki (Python)"
            $theme.MsgGitDirty = "⚠️ Twój ekwipunek na '{0}' jest niezapisany (użyj gsave)"
            $theme.MsgZombie = "👾 Ukryte potwory w jaskini: {0}"
            $theme.MsgOffline = "❌ Brak łączności z Gildią (Brak internetu)"
            $theme.SymbolOk = " 🛡️ "
            $theme.SymbolErr = " 💀 "
            $theme.PromptChar = "⚔️"
            $theme.PromptCharColor = "Yellow"
            $theme.GreetingMorning = "🏰 Poranny wypad do lochów"
            $theme.GreetingDay = "🌞 Słońce w zenicie"
            $theme.GreetingEvening = "🏕️ Rozbijanie obozu"
            $theme.GreetingNight = "🦉 Nocna warta"
            $theme.GreetingFriday = "🍻 Piątek w karczmie!"
        }
        "Magic" {
            $theme.ColorText = "Magenta"
            $theme.ColorPath = "DarkMagenta"
            $theme.PrefixNode = "✨ Eliksir Node.js warzy się"
            $theme.PrefixNodeMissing = "🧪 (Brakuje ingrediencji: node_modules. Rzuć npm install!)"
            $theme.PrefixDocker = "🏰 Zaklęty Zamek (Docker)"
            $theme.PrefixPython = "🐍 Język Wężoustych (Python)"
            $theme.MsgGitDirty = "⚠️ Dementorzy wykradną twój kod z '{0}'! (Rzuć gsave)"
            $theme.MsgZombie = "👻 Zjawy w zamku: {0}"
            $theme.MsgOffline = "❌ Wykryto Zaklęcie Wyciszające! Brak łączności."
            $theme.SymbolOk = " 🪄 "
            $theme.SymbolErr = " 💥 "
            $theme.PromptChar = "⚡"
            $theme.PromptCharColor = "Yellow"
            $theme.GreetingMorning = "🚂 Ekspres wyrusza"
            $theme.GreetingDay = "☀️ Słońce nad Hogwartem"
            $theme.GreetingEvening = "🕯️ Wieczór w Wielkiej Sali"
            $theme.GreetingNight = "🌌 Nocne spacery po zamku"
            $theme.GreetingFriday = "🍺 Czas na Kremowe Piwo"
            $theme.LogoLines = @(
                "      *    .  *       .             *   ",
                "   .      _/\_    .      *   .          ",
                "       *  \  / *       .          .     ",
                "   .       \/    V O I D   *            ",
                "      *       .                 *       "
            )
            $theme.LogoColor = "Yellow"
        }
        "Colourblocks" {
            $theme.ColorBracket = "Blue"
            $theme.ColorText = "Magenta"
            $theme.ColorPath = "Cyan"
            $theme.ColorGitClean = "DarkCyan"
            $theme.PrefixNode = "🟣 Purple mówi: To jest Node!"
            $theme.PrefixNodeMissing = "🟦 Blue płacze: Brakuje klocków node_modules!"
            $theme.PrefixDocker = "🔵 Deep Blue widzi Dockera!"
            $theme.PrefixPython = "🟢 Green znalazł Pythona!"
            $theme.MsgGitDirty = "🔴 Red ostrzega: Zbuduj gsave na '{0}'!"
            $theme.MsgZombie = "⬛ Czarne klocki zacinają projekt: {0}"
            $theme.MsgOffline = "🟥 Red krzyczy: Brak Internetu! Klocki się rozpadły!"
            $theme.SymbolOk = " 🟦 "
            $theme.SymbolErr = " 🟥 "
            $theme.PromptChar = "■"
            $theme.PromptCharColor = "Cyan"
            $theme.GreetingMorning = "🟨 Yellow wita dzień!"
            $theme.GreetingDay = "🟧 Orange buduje słońce!"
            $theme.GreetingEvening = "🟪 Violet maluje wieczór"
            $theme.GreetingNight = "🌌 Indigo śpiewa kołysankę"
            $theme.GreetingFriday = "🎉 Wszystkie klocki skaczą!"
            $theme.LogoLines = @(
                "    🟥 🟧 🟨 🟩 🟦 🟪 ⬛",
                "    V  O  I  D",
                "    ⬛ 🟪 🟦 🟩 🟨 🟧 🟥"
            )
            $theme.LogoColor = "White"
        }
        "CSSisAwesome" {
            $theme.ColorBracket = "DarkCyan"
            $theme.ColorText = "Cyan"
            $theme.ColorPath = "Yellow"
            $theme.ColorGitClean = "DarkGray"
            $theme.ColorGitDirty = "DarkRed"
            $theme.RadarHeader = "CSS ALIGNMENT STATUS"
            $theme.RadarClean = "[ CENTERED ]"
            $theme.RadarDirty = "[ !IMPORTANT ]"
            $theme.RadarMissing = "[ OFF-SCREEN ]"
            $theme.PrefixNode = "⚠️ Warning: <div/> not vertically centered"
            $theme.PrefixNodeMissing = "🚫 Margin: -9999px; Modules hidden off-screen"
            $theme.PrefixDocker = "🐳 Floated Docker"
            $theme.PrefixPython = "🐍 Python Snake"
            $theme.MsgGitDirty = "❗ Zastosuj !important, żeby wymusić commita na '{0}'"
            $theme.MsgZombie = "🧟 Z-Index > 9999 processes: {0}"
            $theme.MsgOffline = "❌ Brak neta! (display: none)"
            $theme.SymbolOk = " ✨ "
            $theme.SymbolErr = " 💥 "
            $theme.PromptChar = "#"
            $theme.PromptCharColor = "Cyan"
            $theme.GreetingMorning = "🌅 /* Good morning */"
            $theme.GreetingDay = "☕ /* display: block */"
            $theme.GreetingEvening = "🌙 /* display: none */"
            $theme.GreetingNight = "🦉 /* filter: brightness(0.5) */"
            $theme.GreetingFriday = "🎉 /* Deploy Day */"
        }
        "RetroDOS" {
            $theme.ColorBracket = "DarkGray"
            $theme.ColorText = "Gray"
            $theme.ColorPath = "Gray"
            $theme.ColorError = "DarkRed"
            $theme.ColorGitClean = "DarkGray"
            $theme.ColorGitDirty = "DarkRed"
            $theme.RadarHeader = "DIR COMMAND RESULTS"
            $theme.RadarClean = "[ OK ]"
            $theme.RadarDirty = "[ BAD SECTOR ]"
            $theme.RadarMissing = "[ FILE NOT FOUND ]"
            $theme.PrefixNode = "C:\> FOUND NODE.EXE"
            $theme.PrefixNodeMissing = "C:\> BAD COMMAND OR FILE NAME (node_modules)"
            $theme.PrefixDocker = "C:\> DOCKER.EXE"
            $theme.PrefixPython = "C:\> PYTHON.EXE"
            $theme.MsgGitDirty = "Insert Floppy Disk 2 to save changes on '{0}'"
            $theme.MsgZombie = "Out of memory in 0x00A3F. TSR programs: {0}"
            $theme.MsgOffline = "NO CARRIER."
            $theme.SymbolOk = " OK "
            $theme.SymbolErr = " ERR "
            $theme.PromptChar = ">"
            $theme.PromptCharColor = "Gray"
            $theme.GreetingMorning = "64K RAM SYSTEM. 38911 BASIC BYTES FREE. READY."
            $theme.GreetingDay = "64K RAM SYSTEM. 38911 BASIC BYTES FREE. READY."
            $theme.GreetingEvening = "64K RAM SYSTEM. 38911 BASIC BYTES FREE. READY."
            $theme.GreetingNight = "64K RAM SYSTEM. 38911 BASIC BYTES FREE. READY."
            $theme.GreetingFriday = "64K RAM SYSTEM. 38911 BASIC BYTES FREE. READY."
            $theme.LogoLines = @(
                "    **** COMMODORE 64 BASIC V2 ****",
                "     64K RAM SYSTEM  38911 BYTES FREE",
                "READY."
            )
            $theme.LogoColor = "Gray"
        }
        "FrameworkFatigue" {
            $theme.ColorBracket = "DarkYellow"
            $theme.ColorText = "Yellow"
            $theme.ColorPath = "Yellow"
            $theme.ColorGitClean = "DarkYellow"
            $theme.RadarHeader = "FRAMEWORK DEPRECATION STATUS"
            $theme.RadarClean = "[ UPDATED 5 MINS AGO ]"
            $theme.RadarDirty = "[ SO 2024 ]"
            $theme.RadarMissing = "[ ABANDONWARE ]"
            $theme.PrefixNode = "📦 Another day, another JS framework."
            $theme.PrefixNodeMissing = "🗑️ Your dependencies are 12 hours old. Time to rewrite in Rust."
            $theme.PrefixDocker = "🐳 Containerized sadness"
            $theme.PrefixPython = "🐍 AI snake oil"
            $theme.MsgGitDirty = "Are you still using React on '{0}'? Save it anyway."
            $theme.MsgZombie = "Memory leaks detected from abandoned frameworks: {0}"
            $theme.MsgOffline = "❌ Internet disconnected. Cannot download more RAM."
            $theme.SymbolOk = " 🚀 "
            $theme.SymbolErr = " 💥 "
            $theme.PromptChar = "$"
            $theme.PromptCharColor = "Yellow"
            $theme.GreetingMorning = "Wait, a new JS framework just dropped."
            $theme.GreetingDay = "Compiling 15GB of node_modules..."
            $theme.GreetingEvening = "Time to switch from Vue to Svelte."
            $theme.GreetingNight = "Rewriting the app in HTMX."
            $theme.GreetingFriday = "Don't push on Friday, the new Next.js version breaks everything."
        }
    }
    return $theme
}



# --- 5. Inteligentny Znak Zachęty (Prompt) ----------------

# Etap 8: Void Project Hub (vp, radar)
function vp {
    param([string]$Action, [string]$Name)
    $file = "$HOME\.void-projects.json"
    $db = @{}
    if (Test-Path $file) {
        $json = Get-Content $file -Raw | ConvertFrom-Json
        if ($json) { foreach ($p in $json.psobject.properties) { $db[$p.Name] = $p.Value } }
    }

    if ($Action -eq "add") {
        if (-not $Name) { $Name = (Split-Path -Leaf (Get-Location)) }
        $db[$Name] = (Get-Location).Path
        $db | ConvertTo-Json | Set-Content $file
        Write-Host "Zapisano projekt '$Name'." -ForegroundColor Green
    } elseif ($Action -eq "remove" -or $Action -eq "rm") {
        if ($db.Contains($Name)) {
            $db.Remove($Name)
            $db | ConvertTo-Json | Set-Content $file
            Write-Host "Usunięto projekt '$Name'." -ForegroundColor Yellow
        } else { Write-Host "Brak projektu '$Name'." -ForegroundColor Red }
    } elseif ($Action -eq "go") {
        if ($db.Contains($Name)) {
            Set-Location $db[$Name]
            Write-Host "Teleportacja do: $Name" -ForegroundColor Cyan
            if (Test-Path ".\CONTEXT.md") {
                $lastLine = Get-Content ".\CONTEXT.md" -Tail 1 -ErrorAction SilentlyContinue
                $global:VibeScratchpad = "Ostatnio: $lastLine"
            }
        } else { Write-Host "Nieznany projekt: '$Name'." -ForegroundColor Red }
    } else {
        Write-Host "Użycie: vp <add|remove|go> [nazwa]"
    }
}

function radar {
    $file = "$HOME\.void-projects.json"
    if (-not (Test-Path $file)) { Write-Host "Brak projektów. Dodaj je przez 'vp add <nazwa>'"; return }
    $db = @{}
    $json = Get-Content $file -Raw | ConvertFrom-Json
    if ($json) { foreach ($p in $json.psobject.properties) { $db[$p.Name] = $p.Value } }
    
    $theme = Get-VoidTheme -ThemeName $global:VoidConfig.Theme
    Write-Host "`n ============ $($theme.RadarHeader) ============" -ForegroundColor $theme.ColorBracket
    
    foreach ($key in $db.Keys) {
        $path = $db[$key]
        if (-not (Test-Path $path)) {
            Write-Host " $($theme.RadarMissing) $key -> Brak folderu: $path" -ForegroundColor DarkGray
            continue
        }
        
        $gitStatus = "Clean"
        $originalPath = (Get-Location).Path
        Set-Location $path
        if (Get-Command git -ErrorAction SilentlyContinue) {
            if (Test-Path ".git") {
                $status = git status --porcelain 2>$null
                if ($status) { $gitStatus = "Dirty" }
            } else {
                $gitStatus = "None"
            }
        }
        
        $stack = @()
        if (Test-Path "package.json") { $stack += "Node" }
        if (Test-Path "docker-compose.yml") { $stack += "Docker" }
        if ((Test-Path "main.py") -or (Test-Path "requirements.txt")) { $stack += "Python" }
        $stackStr = if ($stack.Count -gt 0) { "($($stack -join ', '))" } else { "" }

        Set-Location $originalPath

        $label = if ($gitStatus -eq "Dirty") { $theme.RadarDirty } elseif ($gitStatus -eq "Clean") { $theme.RadarClean } else { "[ -- ]" }
        $color = if ($gitStatus -eq "Dirty") { $theme.ColorGitDirty } else { $theme.ColorGitClean }
        
        Write-Host " $label $key $stackStr " -NoNewline -ForegroundColor $color
        Write-Host "-> $path" -ForegroundColor DarkGray
    }
    Write-Host " =====================================================`n" -ForegroundColor $theme.ColorBracket
}

# Etap 9: Narzędzia Vibe-Codera V3
function snapshot {
    $date = Get-Date -Format "yyyyMMdd_HHmmss"
    $zipName = "backup_$date.zip"
    Write-Host "Tworzenie $zipName (pomijam node_modules, .git, .next, dist)..." -ForegroundColor Cyan
    $tempDir = Join-Path $env:TEMP "void_backup_$date"
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    Copy-Item -Path . -Destination $tempDir -Recurse -Exclude "node_modules",".git",".next","dist","__pycache__" -ErrorAction SilentlyContinue
    Compress-Archive -Path "$tempDir\*" -DestinationPath .\$zipName -Force
    Remove-Item -Path $tempDir -Recurse -Force
    Write-Host "✅ Utworzono kopię zapasową: $zipName" -ForegroundColor Green
}

function review {
    $diff = git diff 2>$null
    if (-not $diff) { $diff = git diff HEAD 2>$null }
    if (-not $diff) { Write-Host "Brak zmian do skanowania." -ForegroundColor Yellow; return }
    $promptAI = "Zrób code review poniższych zmian. Wskaż luki w bezpieczeństwie, błędy logiczne i zaproponuj lepsze praktyki:`n`n$diff"
    $promptAI | Set-Clipboard
    Write-Host "✅ Skopiowano zmiany z instrukcją dla AI do schowka!" -ForegroundColor Green
}

function todo {
    param([string]$Action, [string]$Task)
    $file = ".\.todo.json"
    $todos = @()
    if (Test-Path $file) { $todos = Get-Content $file -Raw | ConvertFrom-Json }
    
    if (-not $Action -or $Action -eq "list") {
        Write-Host "`n--- LISTA ZADAŃ ---" -ForegroundColor Cyan
        if ($todos.Count -eq 0) { Write-Host "Brak zadań. Dodaj przez 'todo add `"Zadanie`"'" -ForegroundColor DarkGray }
        for ($i=0; $i -lt $todos.Count; $i++) {
            $status = if ($todos[$i].Done) { "[x]" } else { "[ ]" }
            $color = if ($todos[$i].Done) { "DarkGray" } else { "White" }
            Write-Host "$i. $status $($todos[$i].Text)" -ForegroundColor $color
        }
        Write-Host ""
    } elseif ($Action -eq "add") {
        $todos += [PSCustomObject]@{ Text = $Task; Done = $false }
        $todos | ConvertTo-Json | Set-Content $file
        Write-Host "✅ Dodano zadanie: $Task" -ForegroundColor Green
    } elseif ($Action -eq "done" -or $Action -eq "rm") {
        $idx = [int]$Task
        if ($idx -ge 0 -and $idx -lt $todos.Count) {
            if ($Action -eq "done") {
                $todos[$idx].Done = $true
                Write-Host "✅ Zadanie '$($todos[$idx].Text)' oznaczone jako zrobione." -ForegroundColor Green
            } else {
                Write-Host "🗑️ Usunięto: $($todos[$idx].Text)" -ForegroundColor Yellow
                $todos = $todos | Where-Object { $todos.IndexOf($_) -ne $idx }
            }
            if ($todos.Count -gt 0) { $todos | ConvertTo-Json | Set-Content $file } else { Remove-Item $file -ErrorAction SilentlyContinue }
        }
    }
}

function clean-space {
    Write-Host "🧹 Skanowanie przestrzeni i czyszczenie..." -ForegroundColor Cyan
    $trash = @("node_modules", "dist", ".next", "__pycache__", "build", "coverage")
    foreach ($t in $trash) {
        if (Test-Path $t) {
            Write-Host "Usuwam $t..." -ForegroundColor Yellow
            Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue
        }
    }
    Write-Host "✅ Sprzątanie zakończone." -ForegroundColor Green
}

function focus {
    $global:VoidConfig.EnableOfflineRadar = $false
    $global:VoidConfig.EnableZombieScanner = $false
    Clear-Host
    Write-Host "🧘 Tryb Zen aktywowany. Ostrzeżenia ukryte." -ForegroundColor Cyan
}

function wtf {
    if ($Error.Count -eq 0) { Write-Host "Brak zapisanych błędów." -ForegroundColor Yellow; return }
    $lastErr = $Error[0] | Out-String
    $promptAI = "Moja ostatnia komenda wyrzuciła ten błąd. Wyjaśnij mi to jak pięciolatkowi i podaj komendę, która to naprawi:`n`n$lastErr"
    $promptAI | Set-Clipboard
    Write-Host "✅ Błąd skopiowany z promptem ratunkowym. Wklej do AI!" -ForegroundColor Green
}

function qr-link {
    param([string]$Port = "3000")
    $ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Wi-Fi -ErrorAction SilentlyContinue | Select-Object -First 1 IPAddress).IPAddress
    if (-not $ip) { $ip = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object IPAddress -notmatch '^127\.' | Select-Object -First 1 IPAddress).IPAddress }
    if (-not $ip) { $ip = "localhost" }
    $url = "http://$($ip):$Port"
    Write-Host "Testuj na mobile: $url" -ForegroundColor Cyan
    try {
        $qr = Invoke-RestMethod "https://qrenco.de/$url"
        Write-Host $qr
    } catch {
        Write-Host "Brak internetu, by wygenerować QR." -ForegroundColor Red
    }
}

function onboard {
    $out = "=== Struktura Projektu ===`n"
    $skip = 'node_modules|\.git|\.next|dist|build|\.venv|__pycache__'
    $out += (Get-ChildItem -Recurse -Depth 3 -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch $skip } | ForEach-Object { $_.FullName.Replace((Get-Location).Path, '.') } | Out-String)
    
    if (Test-Path "package.json") { $out += "`n=== package.json ===`n" + (Get-Content "package.json" -Raw) }
    if (Test-Path "README.md") { $out += "`n=== README.md ===`n" + (Get-Content "README.md" -Raw) }
    
    $promptAI = "Oto struktura mojego projektu i podstawowe pliki. Zapoznaj się z nimi, zanim zadam pierwsze pytanie:`n`n$out"
    $promptAI | Set-Clipboard
    Write-Host "✅ Mega-Prompt Inicjalizacyjny skopiowany do schowka!" -ForegroundColor Green
}

function vibe-check {
    $files = Get-ChildItem -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch 'node_modules|\.git|dist' }
    if ($files.Count -eq 0) { Write-Host "Nie masz nawet kodu, ziomek." -ForegroundColor Yellow; return }
    $biggest = $files | Sort-Object Length -Descending | Select-Object -First 1
    Write-Host "🔍 Vibe-Check Linter analizuje twój styl..." -ForegroundColor Cyan
    Start-Sleep -Seconds 1
    if ($biggest.Length -gt 50000) {
        Write-Host "🚩 Plik $($biggest.Name) zajmuje $([math]::Round($biggest.Length / 1KB)) KB. Mam nadzieję, że chociaż Ty wiesz, co tam napisałeś." -ForegroundColor Red
    } else {
        Write-Host "✨ Kod wygląda zaskakująco przyzwoicie." -ForegroundColor Green
    }
}

function mock-server {
    param([string]$Port = "8080")
    if (Get-Command python -ErrorAction SilentlyContinue) {
        Write-Host "🌐 Uruchamiam Python HTTP Server na porcie $Port..." -ForegroundColor Cyan
        python -m http.server $Port
    } elseif (Get-Command npx -ErrorAction SilentlyContinue) {
        Write-Host "🌐 Uruchamiam npx http-server na porcie $Port..." -ForegroundColor Cyan
        npx http-server -p $Port
    } else {
        Write-Host "Brak Pythona lub npx." -ForegroundColor Red
    }
}

function stats {
    Write-Host "📊 Liczenie statystyk kodu (to może chwilę potrwać)..." -ForegroundColor Cyan
    $files = Get-ChildItem -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch 'node_modules|\.git|dist|build|__pycache__' }
    $lines = 0
    foreach ($f in $files) { try { $lines += (Get-Content $f.FullName -ErrorAction SilentlyContinue).Count } catch {} }
    Write-Host "Plików: $($files.Count)" -ForegroundColor White
    Write-Host "Linii kodu: $lines" -ForegroundColor White
}

function rage-quit {
    Write-Host "(╯°□°）╯︵ ┻━┻" -ForegroundColor Red
    git add . 2>$null
    git commit -m "WIP - ratunku" 2>$null
    Exit
}

function brb {
    Clear-Host
    Write-Host "`n`n`n       Z A R A Z   W R A C A M`n" -ForegroundColor Green
    Write-Host "       (Wciśnij Ctrl+C aby odblokować)" -ForegroundColor DarkGreen
    while ($true) { Start-Sleep -Seconds 100 }
}

Set-Alias whoops gundo
Set-Alias undo gundo
function prompt {
    $err = $LASTEXITCODE
    $theme = Get-VoidTheme -ThemeName $global:VoidConfig.Theme
    
    # ---------------------------------------------
    # GROMADZENIE DANYCH DO TOP BARA
    # ---------------------------------------------
    
    # 1. CPU (bardzo szybki call)
    $cpu = 0
    try { $cpu = [math]::Round((Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Measure-Object -Property LoadPercentage -Average).Average) } catch {}
    $cpuBlocks = " "
    if ($cpu -gt 80) { $cpuBlocks = "▃▅▇" } elseif ($cpu -gt 40) { $cpuBlocks = "▃▅ " } else { $cpuBlocks = "▃  " }
    
    # 2. Bateria
    $batStr = ""
    try {
        $bat = (Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue)
        if ($bat) { $batStr = "──[ 🔋 $($bat.EstimatedChargeRemaining)% ]" }
    } catch {}
    
    # 3. Git Status i Branch Protection
    $gitStr = ""
    $branchAlarm = ""
    if ((Get-Command git -ErrorAction SilentlyContinue) -and (Test-Path ".git")) {
        $branch = (git rev-parse --abbrev-ref HEAD 2>$null)
        if ($branch -eq "main" -or $branch -eq "master") {
            $branchAlarm = "──[ 🚨 MAIN ]"
        }
        
        $status = git status --porcelain -b 2>$null
        if ($status) {
            $ahead = 0; $behind = 0
            if ($status[0] -match "ahead (\d+)") { $ahead = $matches[1] }
            if ($status[0] -match "behind (\d+)") { $behind = $matches[1] }
            
            $dirty = if ($status.Count -gt 1) { "⚠️" } else { "✅" }
            $ab = ""
            if ($ahead -gt 0) { $ab += "↑$ahead " }
            if ($behind -gt 0) { $ab += "↓$behind " }
            
            $gitStr = "──[ $dirty $branch $ab]"
        }
    }
    
    # 4. Czas wykonania (Stopwatch)
    $timeStr = ""
    $history = Get-History -Count 1 -ErrorAction SilentlyContinue
    if ($history) {
        $diff = $history.EndExecutionTime - $history.StartExecutionTime
        if ($diff.TotalSeconds -gt 2) {
            $timeStr = "──[ ⏱️ $([math]::Round($diff.TotalSeconds, 1))s ]"
        }
    }
    
    # 5. Spotify (tylko proces)
    $musicStr = ""
    $spotify = Get-Process Spotify -ErrorAction SilentlyContinue | Where-Object MainWindowTitle -ne "" | Select-Object -First 1
    if ($spotify) {
        $title = $spotify.MainWindowTitle
        if ($title.Length -gt 20) { $title = $title.Substring(0,17) + "..." }
        $musicStr = "──[ 🎵 $title ]"
    }

    # ---------------------------------------------
    # GROMADZENIE DANYCH DO BOTTOM BARA
    # ---------------------------------------------
    
    # 1. Faza księżyca
    $knownFullMoon = [datetime]"2024-01-25 17:54:00"
    $daysSince = (Get-Date) - $knownFullMoon
    $cycles = $daysSince.TotalDays / 29.53058770576
    $cyclePos = $cycles - [math]::Truncate($cycles)
    $daysToFull = [math]::Round((1 - $cyclePos) * 29.53)
    $moonIcon = "🌕"
    if ($cyclePos -lt 0.1 -or $cyclePos -gt 0.9) { $moonIcon = "🌕" }
    elseif ($cyclePos -lt 0.4) { $moonIcon = "🌘" }
    elseif ($cyclePos -lt 0.6) { $moonIcon = "🌑" }
    else { $moonIcon = "🌓" }
    if ($daysToFull -eq 29 -or $daysToFull -eq 30) { $daysToFull = 0 }
    
    # 2. Wolne miejsce
    $drive = (Get-Location).Drive.Name
    $spaceStr = ""
    if ($drive) {
        $vol = Get-Volume -DriveLetter $drive -ErrorAction SilentlyContinue
        if ($vol) { $spaceStr = "──[ 💾 Wolne: $([math]::Round($vol.SizeRemaining / 1GB))GB ]" }
    }
    
    # 3. TODO
    $todoStr = ""
    if (Test-Path ".\.todo.json") {
        $tds = Get-Content ".\.todo.json" -Raw | ConvertFrom-Json
        $act = $tds | Where-Object { -not $_.Done } | Select-Object -First 1
        if ($act) { 
            $t = $act.Text
            if ($t.Length -gt 15) { $t = $t.Substring(0,12) + "..." }
            $todoStr = "──[ 🎯 TODO: $t ]"
        }
    }
    
    # 4. Schowek
    $clipStr = ""
    $clip = Get-Clipboard -ErrorAction SilentlyContinue
    if ($clip) {
        $clipStr = "──[ 📋 Tekst ($($clip.Length)) ]"
    }
    
    # 5. Ostatnio edytowany
    $lastMod = ""
    $recent = Get-ChildItem -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($recent) {
        $lastMod = "──[ 📝 Ost: $($recent.Name) ]"
    }
    
    # 6. Tip
    $tips = @("Tip: wpisz 'brb'", "Tip: 'qr-link 3000' to skaner", "Tip: 'wtf' zapyta AI", "Tip: 'onboard' to prompt")
    $tip = $tips[(Get-Date).Second % $tips.Count]

    # ---------------------------------------------
    # RENDEROWANIE
    # ---------------------------------------------
    Write-Host ""
    
    # TOP BAR
    Write-Host "╭─[ 🖥️ CPU: $cpuBlocks $cpu% ]$batStr$musicStr$branchAlarm$gitStr$timeStr─╮" -ForegroundColor $theme.ColorBracket
    
    # MIDDLE
    $path = (Get-Location).Path
    Write-Host "│ 📁 $path " -NoNewline -ForegroundColor $theme.ColorPath
    
    $stack = @()
    if (Test-Path "package.json") { $stack += "⚛️ Node" }
    if (Test-Path "docker-compose.yml") { $stack += "🐳 Docker" }
    if ((Test-Path "main.py") -or (Test-Path "requirements.txt")) { $stack += "🐍 Python" }
    if ($stack.Count -gt 0) {
        Write-Host " ($($stack -join ', '))" -ForegroundColor $theme.ColorBracket
    } else { Write-Host "" }

    # BOTTOM BAR
    Write-Host "╰─[ $moonIcon Pełnia za $daysToFull dni ]$spaceStr$todoStr$clipStr──[ 💡 $tip ]" -ForegroundColor $theme.ColorBracket
    
    # OFFLINE / ZOMBIE / SCHRATCH
    if ($global:VoidConfig.EnableOfflineRadar) {
        try { if (-not [System.Net.NetworkInformation.NetworkInterface]::GetIsNetworkAvailable()) { Write-Host " $($theme.MsgOffline)" -ForegroundColor Red } } catch {}
    }
    if ($global:VoidConfig.EnableZombieScanner) {
        $zombies = @(Get-Process node -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -eq "" })
        if ($zombies.Count -gt 3) { Write-Host " $($theme.MsgZombie -f $zombies.Count)" -ForegroundColor Yellow }
    }
    if ($global:VibeScratchpad) {
        Write-Host " 📌 $($global:VibeScratchpad)" -ForegroundColor Yellow
    }

    # PROMPT CHAR
    $pc = $theme.PromptChar
    if ($err -ne 0) {
        Write-Host " $($theme.SymbolErr)" -NoNewline -ForegroundColor $theme.ColorError
    } else {
        Write-Host " $($theme.SymbolOk)" -NoNewline -ForegroundColor $theme.ColorSuccess
    }
    Write-Host "$pc " -NoNewline -ForegroundColor $theme.PromptCharColor
    
    return " "
}


# --- Animacja Startowa ---
Clear-Host
$startTheme = Get-VoidTheme -ThemeName $global:VoidConfig.Theme
Write-Host ""
foreach ($line in $startTheme.LogoLines) {
    Write-Host $line -ForegroundColor $startTheme.LogoColor
}
Write-Host "                                   by toniaczlog" -ForegroundColor Cyan
Write-Host ""
Write-Host "    Aktywny Motyw: $($global:VoidConfig.Theme). Logowanie włączone." -ForegroundColor DarkGray
Write-Host "    » Wpisz " -NoNewline -ForegroundColor DarkGray
Write-Host "void" -NoNewline -ForegroundColor Cyan
Write-Host ", aby otworzyć pomoc." -ForegroundColor DarkGray
Write-Host ""
