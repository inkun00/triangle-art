# Export Triangle Art to Web (HTML5/WASM)
$ErrorActionPreference = "Stop"

$GodotExe = "C:\Users\user\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"

if (-not (Test-Path $GodotExe)) {
    Write-Error "Godot Console executable not found at: $GodotExe"
    exit 1
}

$BuildDir = "build\web"
if (-not (Test-Path $BuildDir)) {
    New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null
}

Write-Host "Exporting Triangle Art for Web (Release)..." -ForegroundColor Cyan
& $GodotExe --headless --export-release "Web" "build/web/index.html"
$exitCode = $LASTEXITCODE

if ($exitCode -eq 0 -and (Test-Path "build\web\index.html")) {
    Write-Host "`nWeb export succeeded! Output located in: $BuildDir" -ForegroundColor Green
} else {
    Write-Host "`nWeb export failed with exit code $exitCode" -ForegroundColor Red
}

exit $exitCode
