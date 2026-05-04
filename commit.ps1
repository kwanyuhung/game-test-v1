$PROJECT = "C:\Users\user\Documents\game-test"
$GODOT = "C:\Users\user\Downloads\Godot462\Godot_v4.6.2-stable_win64.exe"
$BOT_TOKEN = "8661389914:AAHt0UDFntFdbnFwnhoxIN58N2hxC0mK3rk"
$CHAT_ID = "1718058079"

function Send-Telegram([string]$text) {
    $url = "https://api.telegram.org/bot$BOT_TOKEN/sendMessage"
    $body = @{chat_id=$CHAT_ID; text=$text; parse_mode="Markdown"}
    try { Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json" -TimeoutSec 10 | Out-Null } catch {}
}

# Test first
Write-Host "Testing..." -ForegroundColor Cyan
$errLog = "$env:TEMP\gdqc.log"
$proc = Start-Process $GODOT -ArgumentList '--path',$PROJECT,'--headless','--quit-after','8' -PassThru -RedirectStandardError $errLog -WindowStyle Hidden
$ok = $proc.WaitForExit(25000)
if (Test-Path $errLog) {
    $err = Get-Content $errLog -Raw
} else {
    $err = ""
}
Remove-Item $errLog -EA SilentlyContinue

if (-not $ok) {
    $errs = ($err -split "`n" | Where-Object { $_ -match "SCRIPT ERROR" } | Select-Object -First 5)
    Write-Host "TEST FAILED - not committing" -ForegroundColor Red
    $errs | ForEach-Object { Write-Host $_ }
    Send-Telegram "❌ *Commit Blocked* - test failed%0A`n$($errs -join '%0A')"
    exit 1
}

$msg = "Phase 2: Ground floor food street + full 10-floor data-driven layout"
git -C $PROJECT add -A
git -C $PROJECT commit -m $msg
git -C $PROJECT push
$st = git -C $PROJECT diff --staged --stat
Send-Telegram "📦 *AutoCommit*%0A*$(($msg -replace '[*_`]',''))*%0A%0A$st"
Write-Host "Done!" -ForegroundColor Green
