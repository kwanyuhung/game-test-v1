$errLog = "$env:TEMP\gdtest_err.log"
if (Test-Path $errLog) { Remove-Item $errLog }
$proc = Start-Process -FilePath "C:\Users\user\Downloads\Godot462\Godot_v4.6.2-stable_win64.exe" -ArgumentList '--path', 'C:\Users\user\Documents\game-test', '--headless', '--quit-after', '8' -PassThru -RedirectStandardError $errLog -WindowStyle Hidden
$ok = $proc.WaitForExit(25000)
$exitCode = $proc.ExitCode
Write-Host "Exit: $exitCode"
if (Test-Path $errLog) {
    $c = Get-Content $errLog -Raw
    if ($c -and $c.Length -gt 10) { Write-Host $c }
}
Remove-Item $errLog -EA SilentlyContinue
