@echo off
cd /d "%~dp0"
start "Level Two - Bellcap Cistern" "tools\godot\Godot_v4.7.2-stable_win64.exe" --path "." "res://scenes/bellcap_cistern.tscn" -- --keyboard-party
