# Run Headless Test Suite for Triangle Art
$ErrorActionPreference = "Stop"

$GodotExe = "C:\Users\user\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"

if (-not (Test-Path $GodotExe)) {
    Write-Error "Godot Console executable not found at: $GodotExe"
    exit 1
}

Write-Host "Running Godot Headless Test Runner..." -ForegroundColor Cyan
& $GodotExe --headless --path . "res://tests/test_runner.tscn"
$exitCode = $LASTEXITCODE

if ($exitCode -eq 0) {
    Write-Host "`nAll tests passed successfully!" -ForegroundColor Green
} else {
    Write-Host "`nTests failed with exit code $exitCode" -ForegroundColor Red
}

exit $exitCode
