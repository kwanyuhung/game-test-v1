$PROJECT = "C:\Users\user\Documents\game-test"
$GODOT = "C:\Users\user\Downloads\Godot462\Godot_v4.6.2-stable_win64.exe"
Write-Host "Testing Godot headless run..."
$errLog = "$env:TEMP\gdtest.log"
$proc = Start-Process $GODOT -ArgumentList '--path',$PROJECT,'--headless','--quit-after','8' -PassThru -RedirectStandardError $errLog -WindowStyle Hidden
$ok = $proc.WaitForExit(25000)
if (Test-Path $errLog) {
    $err = Get-Content $errLog -Raw
} else {
    $err = ""
}
Remove-Item $errLog -EA SilentlyContinue
if ($ok) {
    Write-Host "Exit code: $($proc.ExitCode) - Test PASSED" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Exit code: TIMEOUT/FAIL" -ForegroundColor Red
    $errs = ($err -split "`n" | Where-Object { $_ -match "SCRIPT ERROR|ERROR:" } | Select-Object -First 10)
    $errs | ForEach-Object { Write-Host $_ }
    exit 1
}
