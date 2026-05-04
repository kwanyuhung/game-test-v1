# autotest.ps1 - Watch project files and auto-run Godot test on changes
# Usage: .\autotest.ps1            (watch mode - runs forever)
#        .\autotest.ps1 -OneShot   (single run and exit)
param([switch]$OneShot)
$PROJECT = "C:\Users\user\Documents\game-test"
$GODOT = "C:\Users\user\Downloads\Godot462\Godot_v4.6.2-stable_win64.exe"
$BOT_TOKEN = "8661389914:AAHt0UDFntFdbnFwnhoxIN58N2hxC0mK3rk"
$CHAT_ID = "1718058079"
$extensions = @(".gd", ".tscn", ".godot")

function Send-Telegram([string]$text) {
    if ([string]::IsNullOrEmpty($text)) { return }
    $escaped = $text -replace "`n", "%0A"
    python3 -c @"
import urllib.request, json
data = json.dumps({'chat_id': '$CHAT_ID', 'text': '$escaped', 'parse_mode': 'Markdown'}).encode()
req = urllib.request.Request('https://api.telegram.org/bot$BOT_TOKEN/sendMessage', data=data, headers={'Content-Type': 'application/json'})
with urllib.request.urlopen(req, timeout=10) as r: pass
"@
}

function Test-Godot($proj, $godot) {
    $errLog = "$env:TEMP\gd_err_$PID.log"
    $proc = Start-Process $godot -ArgumentList '--path',$proj,'--headless','--quit-after','8' -PassThru -RedirectStandardError $errLog -WindowStyle Hidden
    $ok = $proc.WaitForExit(25000)
    $exit = $proc.ExitCode
    $err = if (Test-Path $errLog) { Get-Content $errLog -Raw } else ""
    Remove-Item $errLog -EA SilentlyContinue
    $scriptErrs = ($err -split "`n" | Where-Object { $_ -match "SCRIPT ERROR" })
    return @{ok=($ok -and $exit -eq 0); err=$err; scriptErrs=$scriptErrs}
}

function Get-ScriptChanges($proj, $since) {
    $files = @()
    Get-ChildItem -Path $proj -Recurse -File | Where-Object { $extensions -contains $_.Extension } | ForEach-Object {
        if ($_.LastWriteTime -gt $since) { $files += $_.FullName.Replace("$proj\", "") }
    }
    return $files
}

$lastRun = Get-Date
$failCount = 0

if ($OneShot) {
    Write-Host "Running single test..." -ForegroundColor Cyan
    $r = Test-Godot $PROJECT $GODOT
    if ($r.ok) {
        Write-Host "PASSED" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "FAILED" -ForegroundColor Red
        $r.scriptErrs | Select-Object -First 5 | ForEach-Object { Write-Host $_ }
        exit 1
    }
}

Write-Host "Watching $PROJECT for .gd/.tscn changes..." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop.`n" -ForegroundColor Gray

while ($true) {
    Start-Sleep -Seconds 2
    $changed = Get-ScriptChanges $PROJECT $lastRun
    if ($changed.Count -eq 0) { continue }
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Detected $($changed.Count) file(s) changed" -ForegroundColor Yellow
    $changed | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    
    $lastRun = Get-Date
    $r = Test-Godot $PROJECT $GODOT
    
    if ($r.ok) {
        Write-Host "  PASSED" -ForegroundColor Green
        $failCount = 0
    } else {
        $failCount++
        Write-Host "  FAILED (x$failCount)" -ForegroundColor Red
        $r.scriptErrs | Select-Object -First 3 | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
        $summary = ($r.scriptErrs | Select-Object -First 3) -join "%0A"
        Send-Telegram "❌ *AutoTest Failed* (x$failCount)%0A$summary"
        if ($failCount -ge 3) {
            Write-Host "  3 consecutive failures - pausing..." -ForegroundColor Red
            Start-Sleep -Seconds 10
        }
    }
}
