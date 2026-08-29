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
    Write-Host "  gundo        - Cofa commita (nie rusza plików)"
    Write-Host ""
    Write-Host " RATUNEK & BŁĘDY:" -ForegroundColor Cyan
    Write-Host "  loglast 50   - Kopiuje ostatnie 50 linii z terminala"
    Write-Host "  npmnuke      - Resetuje cache NPM i node_modules"
    Write-Host ""
    Write-Host " NARZĘDZIA DLA CHATGPT:" -ForegroundColor Cyan
    Write-Host "  filec plik   - Kopiuje plik z nagłówkiem"
    Write-Host "  tree2        - Kopiuje drzewo plików (2 poziomy)"
    Write-Host "  runc `"cmd`"   - Uruchamia cmd i kopiuje wynik"
    Write-Host "  ctxadd `"...`" - Dopisuje notatkę do CONTEXT.md"
    Write-Host "  scratch `"...`"- Żółta karteczka w prompcie"
    Write-Host ""
    Write-Host " BAZA WIEDZY (Ściągi):" -ForegroundColor Cyan
    Write-Host "  cheat vps    - Ściąga komend dla VPS (git, npm, itp)"
    Write-Host "  zapamietaj   - Zapisz długą komendę pod nazwą"
    Write-Host "  przypomnij   - Uruchom zapisaną komendę"
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
    }
    return $theme
}

# --- 5. Inteligentny Znak Zachęty (Prompt) ----------------

# Etap 7: Scratchpad
$global:VibeScratchpad = ""
function scratch {
    param([string]$Text)
    if ($Text -eq "clear") {
        $global:VibeScratchpad = ""
        Write-Host "Scratchpad wyczyszczony." -ForegroundColor Green
    } elseif ($Text) {
        $global:VibeScratchpad = $Text
        Write-Host "Zapisano w scratchpadzie." -ForegroundColor Green
    } else {
        Write-Host "Użycie: scratch `"notatka`" lub scratch clear"
    }
}

function prompt {
    $err = $LASTEXITCODE
    $theme = Get-VoidTheme -ThemeName $global:VoidConfig.Theme
    
    Write-Host ""
    
    # --- Health Checks (Offline Radar) ---
    if ($global:VoidConfig.EnableOfflineRadar) {
        try {
            if (-not [System.Net.NetworkInformation.NetworkInterface]::GetIsNetworkAvailable()) {
                Write-Host $theme.MsgOffline -BackgroundColor Red -ForegroundColor White
            }
        } catch {}
    }

    # --- Zegar Asystent ---
    $now = Get-Date
    $hour = $now.Hour
    $day = $now.DayOfWeek
    
    $greeting = ""
    if ($day -eq [System.DayOfWeek]::Friday -and $hour -ge 16) { $greeting = $theme.GreetingFriday }
    elseif ($hour -ge 5 -and $hour -lt 10) { $greeting = $theme.GreetingMorning }
    elseif ($hour -ge 10 -and $hour -lt 18) { $greeting = $theme.GreetingDay }
    elseif ($hour -ge 18 -and $hour -lt 23) { $greeting = $theme.GreetingEvening }
    else { $greeting = $theme.GreetingNight }

    # Górna belka
    Write-Host "╭─[ " -NoNewline -ForegroundColor $theme.ColorBracket
    Write-Host "$greeting, $($now.ToString('HH:mm'))" -NoNewline -ForegroundColor $theme.ColorText
    Write-Host " ]" -NoNewline -ForegroundColor $theme.ColorBracket
    
    # --- Sensory (Stack) ---
    $stack = @()
    $hasNodeModules = Test-Path "node_modules"
    
    if (Test-Path "package.json") { 
        $stack += $theme.PrefixNode
        if (-not $hasNodeModules) { $stack += $theme.PrefixNodeMissing }
    }
    if (Test-Path "docker-compose.yml") { $stack += $theme.PrefixDocker }
    if ((Test-Path "main.py") -or (Test-Path "requirements.txt")) { $stack += $theme.PrefixPython }
    
    if ($stack.Count -gt 0) {
        Write-Host "──[ " -NoNewline -ForegroundColor $theme.ColorBracket
        Write-Host ($stack -join " | ") -NoNewline -ForegroundColor $theme.ColorText
        Write-Host " ]" -NoNewline -ForegroundColor $theme.ColorBracket
    }

    # Pokaż gałąź GIT
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $gitBranch = git branch --show-current 2>$null
        if ($gitBranch) {
            $gitStatus = git status --porcelain 2>$null
            if ($gitStatus) {
                Write-Host "──[ " -NoNewline -ForegroundColor $theme.ColorBracket
                Write-Host ($theme.MsgGitDirty -f $gitBranch) -NoNewline -ForegroundColor $theme.ColorGitDirty
                Write-Host " ]" -NoNewline -ForegroundColor $theme.ColorBracket
            } else {
                Write-Host "──[ " -NoNewline -ForegroundColor $theme.ColorBracket
                Write-Host "git: $gitBranch" -NoNewline -ForegroundColor $theme.ColorGitClean
                Write-Host " ]" -NoNewline -ForegroundColor $theme.ColorBracket
            }
        }
    }
    
    # --- Strażnik Zombiaków ---
    if ($global:VoidConfig.EnableZombieScanner) {
        $nodeProcs = @(Get-Process node -ErrorAction SilentlyContinue)
        if ($nodeProcs.Count -gt 0) {
            Write-Host "──[ " -NoNewline -ForegroundColor $theme.ColorBracket
            Write-Host ($theme.MsgZombie -f $nodeProcs.Count) -NoNewline -ForegroundColor $theme.ColorText
            Write-Host " ]" -NoNewline -ForegroundColor $theme.ColorBracket
        }
    }
    
    Write-Host ""
    
    # Ścieżka
    Write-Host "├─> " -NoNewline -ForegroundColor $theme.ColorBracket
    Write-Host (Get-Location).Path -NoNewline -ForegroundColor $theme.ColorPath
    
    # --- Ostatnia notatka CONTEXT.md ---
    if (Test-Path ".\CONTEXT.md") {
        $lastLine = Get-Content ".\CONTEXT.md" -Tail 10 -ErrorAction SilentlyContinue | Where-Object { $_.Trim() -ne "" } | Select-Object -Last 1
        if ($lastLine) { Write-Host "  📝 $lastLine" -NoNewline -ForegroundColor DarkGray }
    }
    Write-Host ""
    
    # --- Podgląd Schowka ---
    try {
        $clip = Get-Clipboard -ErrorAction SilentlyContinue
        if ($clip -is [string] -and $clip.Trim().Length -gt 5) {
            $clipText = $clip.Trim() -replace "`r", "" -replace "`n", " "
            if ($clipText.Length -gt 35) { $clipText = $clipText.Substring(0, 35) + "..." }
            Write-Host "│   📋 W schowku: `"$clipText`"" -ForegroundColor DarkGray
        }
    } catch {}
    
    # --- Scratchpad ---
    if ($global:VibeScratchpad) {
        Write-Host "│   📌 $($global:VibeScratchpad)" -ForegroundColor Yellow
    }

    # Dolna belka
    Write-Host "╰─" -NoNewline -ForegroundColor $theme.ColorBracket
    if ($err -eq 0 -or $err -eq $null) {
        Write-Host $theme.SymbolOk -NoNewline -ForegroundColor $theme.ColorSuccess
    } else {
        Write-Host $theme.SymbolErr -NoNewline -ForegroundColor $theme.ColorError
    }
    
    Write-Host $theme.PromptChar -NoNewline -ForegroundColor $theme.PromptCharColor
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
