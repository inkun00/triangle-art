@echo off
set "GODOT_EXE=C:\Users\user\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"

if not exist "%GODOT_EXE%" (
    echo [ERROR] Godot executable not found at %GODOT_EXE%
    exit /b 1
)

echo [INFO] Running Godot Headless Test Suite...
"%GODOT_EXE%" --headless --path . "res://tests/test_runner.tscn"
exit /b %ERRORLEVEL%
