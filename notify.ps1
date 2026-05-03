# notify.ps1 - Send Telegram message
# Usage: .\notify.ps1 "Your message"
param([Parameter(Mandatory=$true)][string]$Message)
$TOKEN = "8661389914:AAHt0UDFntFdbnFwnhoxIN58N2hxC0mK3rk"
$CHAT = "1718058079"
$url = "https://api.telegram.org/bot$TOKEN/sendMessage"

python3 -c @"
import urllib.request, json
data = json.dumps({'chat_id': '$CHAT', 'text': '''$Message''', 'parse_mode': 'Markdown'}).encode()
req = urllib.request.Request('$url', data=data, headers={'Content-Type': 'application/json'})
try:
    with urllib.request.urlopen(req, timeout=10) as r:
        print('TG OK')
except Exception as e:
    print('TG Error:', e)
"@
