@echo off
cd /d "%~dp0"
start "Gnome battle rigs" "tools\godot\Godot_v4.7.2-stable_win64.exe" --path . res://scenes/rig_showcase.tscn
