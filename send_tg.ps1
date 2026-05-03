$body = @{chat_id='1718058079'; text='Test from PowerShell'; parse_mode='Markdown'}
$url = 'https://api.telegram.org/bot8661389914:AAHt0UDFntFdbnFwnhoxIN58N2hxC0mK3rk/sendMessage'
try {
    $r = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 10
    Write-Host "TG result:" $r.ok
} catch {
    Write-Host "TG error:" $_.Exception.Message
}
