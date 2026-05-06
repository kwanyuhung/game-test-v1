$body = @{
    model = "MiniMax-M2.7"
    messages = @(@{role="user";content="Hi"})
    max_tokens = 10
} | ConvertTo-Json -Compress

$headers = @{
    "Authorization" = "Bearer sk-cp-3QmEoQrpDqd8LT_L-QV5uFG8yoW9ffbhoPoWvYQY8nGpWB2VZrAaAtFhm7fICctswC7loofTPNB7_y-fQ6QkPD7Qp4m0T1RoJTQzc-sV76YXUObHKXVUSio"
    "Content-Type" = "application/json"
}

try {
    $resp = Invoke-WebRequest -Uri "https://api.minimaxi.com/anthropic/v1/messages" -Method Post -Headers $headers -Body $body -TimeoutSec 10
    Write-Host "Status:" $resp.StatusCode
    Write-Host "Body:" $resp.Content
} catch {
    Write-Host "Error:" $_.Exception.Message
    Write-Host "Response:" $_.Exception.Response.StatusCode
}
