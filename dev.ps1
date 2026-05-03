# dev.ps1 - Automated dev workflow: test -> commit -> push -> notify
# Usage:   .\dev.ps1              (runs test only)
#          .\dev.ps1 "commit msg" (full: test + commit + push + telegram)
param(
    [string]$CommitMessage = "",
    [switch]$SkipTest,
    [switch]$SkipPush,
    [switch]$SkipTelegram
)
$ErrorActionPreference = "Stop"
$PROJECT = "C:\Users\user\Documents\game-test"
$GODOT = "C:\Users\user\Downloads\Godot462\Godot_v4.6.2-stable_win64.exe"
$BOT_TOKEN = "8661389914:AAHt0UDFntFdbnFwnhoxIN58N2hxC0mK3rk"
$CHAT_ID = "1718058079"

function Send-Telegram([string]$text) {
    if ([string]::IsNullOrEmpty($text)) { return }
    $url = "https://api.telegram.org/bot$BOT_TOKEN/sendMessage"
    $safe = $text -replace "`n", "%0A"
    $body = @{chat_id=$CHAT_ID; text=$safe; parse_mode="Markdown"}
    try {
        Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json" -TimeoutSec 10 | Out-Null
        Write-Host "  [TG] OK" -ForegroundColor DarkCyan
    } catch {
        Write-Host "  [TG] Failed: $_" -ForegroundColor Yellow
    }
}

function Test-Godot($proj, $godot) {
    $errLog = "$env:TEMP\gd_err_$PID.log"
    $proc = Start-Process $godot -ArgumentList '--path',$proj,'--headless','--quit-after','8' -PassThru -RedirectStandardError $errLog -WindowStyle Hidden
    $ok = $proc.WaitForExit(25000)
    Start-Sleep -Milliseconds 500
    $exit = $proc.ExitCode
    $err = ""
    if (Test-Path $errLog) { $err = Get-Content $errLog -Raw }
    Remove-Item $errLog -EA SilentlyContinue
    $errLines = @()
    if (-not [string]::IsNullOrEmpty($err)) {
        $errLines = $err -split "`n" | Where-Object { $_ -match "SCRIPT ERROR" }
    }
    # Pass if: process ran and no SCRIPT ERRORs found (exit 0 or resource-leak exit is OK)
    $passed = $ok -and ($errLines.Count -eq 0)
    return @{ok=$passed; exit=$exit; errLines=$errLines}
}

# Step 1: Test
if (-not $SkipTest) {
    Write-Host "=== Testing ===" -ForegroundColor Cyan
    $r = Test-Godot $PROJECT $GODOT
    if (-not $r.ok) {
        Write-Host "FAILED" -ForegroundColor Red
        $r.errLines | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        if (-not $SkipTelegram) {
            $summary = ($r.errLines | Select-Object -First 3) -join "%0A"
            Send-Telegram "❌ *Test Failed*%0A$summary"
        }
        exit 1
    }
    Write-Host "PASSED" -ForegroundColor Green
}

# Step 2: Git status
$st = git -C $PROJECT status --porcelain
if ($st.Count -eq 0) {
    Write-Host "Nothing to commit." -ForegroundColor Yellow
    exit 0
}
Write-Host "Changed files:"
$st | ForEach-Object { Write-Host "  $_" }

# Step 3: Commit
if ([string]::IsNullOrEmpty($CommitMessage)) {
    Write-Host "No commit message. Run: .\dev.ps1 `"message`"" -ForegroundColor Yellow
    exit 0
}

git -C $PROJECT add -A
git -C $PROJECT commit -m $CommitMessage
Write-Host "Committed: $CommitMessage" -ForegroundColor Green

# Step 4: Push
if (-not $SkipPush) {
    Write-Host "Pushing..." -ForegroundColor Cyan
    git -C $PROJECT push 2>&1 | ForEach-Object { Write-Host "  $_" }
}

# Step 5: Telegram
if (-not $SkipTelegram) {
    $changed = ($st | Measure-Object -Line).Lines
    $files = $st | Select-Object -First 4 | ForEach-Object {
        $_.TrimStart().Substring(0, [Math]::Min(60, $_.TrimStart().Length))
    }
    $filesStr = $files -join "%0A"
    $safeMsg = $CommitMessage -replace '[*_`]', ''
    $msg = "📦 *Committed*%0A*$safeMsg*%0A%0A[$changed files]%0A$filesStr"
    if ($st.Count -gt 4) { $msg += "%0A...+$($st.Count - 4) more" }
    Send-Telegram $msg
}

Write-Host "Done!" -ForegroundColor Green
