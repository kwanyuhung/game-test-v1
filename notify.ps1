# notify.ps1 - Send Telegram notifications
# Usage: .\notify.ps1 "Your message here"
param([string]$Message, [string]$Token="8661389914:AAHt0UDFntFdbnFwnhoxIN58N2hxC0mK3rk", [string]$ChatId="1718058079")
$url = "https://api.telegram.org/bot$Token/sendMessage"
$body = @{chat_id=$ChatId; text=$Message; parse_mode="Markdown"}
try {
    $r = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json" -TimeoutSec 10
    Write-Host "Telegram sent OK" -ForegroundColor Green
} catch {
    Write-Host "Telegram failed: $_" -ForegroundColor Red
}
