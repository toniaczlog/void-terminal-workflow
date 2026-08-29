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

Write-Host "Profil załadowany. Log sesji: $LogFile" -ForegroundColor DarkGray
Write-Host "Skróty: loglast / runc / tree2 / filec / ctx / gs / gl" -ForegroundColor DarkGray
