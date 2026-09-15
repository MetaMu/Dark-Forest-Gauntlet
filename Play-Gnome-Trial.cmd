@echo off
cd /d "%~dp0"
start "Gnome Sprite Trial" "tools\godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0." res://scenes/gnome_sprite_trial.tscn
