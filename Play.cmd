@echo off
cd /d "%~dp0"
if not exist "tools\godot\Godot_v4.7.2-stable_win64.exe" (
  echo Download Godot 4.7.2 from https://godotengine.org/download/windows/
  echo Extract it into tools\godot, or open project.godot in your Godot editor.
  pause
  exit /b 1
)
start "Dark Forest Gauntlet" "tools\godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0."
