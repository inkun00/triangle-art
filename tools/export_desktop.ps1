# Export Triangle Art to Windows Desktop
$ErrorActionPreference = "Stop"

$GodotExe = "C:\Users\user\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"

if (-not (Test-Path $GodotExe)) {
    Write-Error "Godot Console executable not found at: $GodotExe"
    exit 1
}

$BuildDir = "build\windows"
if (-not (Test-Path $BuildDir)) {
    New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null
}

Write-Host "Exporting Triangle Art Standalone PCK Package..." -ForegroundColor Cyan
& $GodotExe --headless --export-pack "Windows Desktop" "build/windows/TriangleArt.pck"
$packExit = $LASTEXITCODE

if ($packExit -eq 0 -and (Test-Path "build\windows\TriangleArt.pck")) {
    Write-Host "PCK package generated: $BuildDir\TriangleArt.pck" -ForegroundColor Green

    # Create launcher batch file for instant one-click launch
    $LauncherContent = @"
@echo off
start "" "%~dp0..\..\$((Split-Path $GodotExe -Leaf))" --main-pack "%~dp0TriangleArt.pck"
"@
    Set-Content -Path "$BuildDir\Run_TriangleArt.bat" -Value $LauncherContent

    # Copy Godot executable alongside PCK if desirable for full standalone distribution
    $DestExe = "$BuildDir\TriangleArt.exe"
    if (-not (Test-Path $DestExe)) {
        Copy-Item -Path $GodotExe -Destination $DestExe -Force
        Write-Host "Standalone executable linked: $DestExe" -ForegroundColor Green
    }
    Write-Host "`nWindows Desktop build successfully prepared in: $BuildDir" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nWindows Desktop export failed with code $packExit" -ForegroundColor Red
    exit 1
}
