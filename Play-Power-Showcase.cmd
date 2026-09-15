@echo off
cd /d "%~dp0"
start "Four Gnome Power Showcase" "tools\godot\Godot_v4.7.2-stable_win64.exe" --path "." --script "scripts/power_showcase.gd" --fixed-fps 60 -- --demo
