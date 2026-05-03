# autotest.ps1 - Watch project files and auto-run Godot test on changes
# Usage: .\autotest.ps1            (watch mode - runs forever)
#        .\autotest.ps1 -OneShot   (single run and exit)
param([switch]$OneShot)
$PROJECT = "C:\Users\user\Documents\game-test"
$GODOT = "C:\Users\user\Downloads\Godot462\Godot_v4.6.2-stable_win64.exe"
$extensions = @(".gd", ".tscn", ".godot")

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
        if ($failCount -ge 3) {
            Write-Host "  3 consecutive failures - pausing..." -ForegroundColor Red
            Start-Sleep -Seconds 10
        }
    }
}
