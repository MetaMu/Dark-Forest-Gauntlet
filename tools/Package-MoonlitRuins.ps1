param([switch]$PowerFX,[switch]$KeyboardCoop,[switch]$MagicSequence,[switch]$LevelTwo,[switch]$Celebration,[switch]$StudioVFX,[switch]$DynamicMaria)
if($DynamicMaria){$StudioVFX=$true}
if($StudioVFX){$Celebration=$true}
if($Celebration){$LevelTwo=$true}
if($LevelTwo){$MagicSequence=$true}
if($MagicSequence){$KeyboardCoop=$true}
if($KeyboardCoop){$PowerFX=$true}
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$folder=Join-Path $projectRoot $(if($LevelTwo){'builds/Level-Two-Playtest'}elseif($MagicSequence){'builds/Magic-Sequence-Playtest'}elseif($KeyboardCoop){'builds/Keyboard-Coop-Playtest'}elseif($PowerFX){'builds/Power-FX-v3-Playtest'}else{'builds/Moonlit-Ruins-Playtest'})
if($Celebration){$folder=Join-Path $projectRoot 'builds/Celebration-Playtest'}
if($StudioVFX){$folder=Join-Path $projectRoot 'builds/Studio-VFX-Playtest'}
if($DynamicMaria){$folder=Join-Path $projectRoot 'builds/Dynamic-Maria-Playtest'}
New-Item -ItemType Directory -Force $folder | Out-Null
$engine=Join-Path $PSScriptRoot 'godot/Godot_v4.7.2-stable_win64_console.exe'
$log=Join-Path $projectRoot $(if($LevelTwo){'artifacts/level-two/export.log'}elseif($MagicSequence){'artifacts/magic-sequence/export.log'}elseif($KeyboardCoop){'artifacts/keyboard-coop/export.log'}elseif($PowerFX){'artifacts/power-fx-v3/export.log'}else{'artifacts/art-upgrade/export.log'})
if($StudioVFX){$log=Join-Path $projectRoot 'artifacts/studio-vfx/export.log'}
if($DynamicMaria){$log=Join-Path $projectRoot 'artifacts/maria-dynamic-50/export.log'}
& $engine --headless --path $projectRoot --export-pack 'Windows Playtest' (Join-Path $folder 'DarkForestGauntlet.pck') *> $log
if($LASTEXITCODE -ne 0){throw 'PCK export failed'}
if((Get-Content -LiteralPath $log -Raw) -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)'){throw 'PCK export engine errors'}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'godot/Godot_v4.7.2-stable_win64.exe') -Destination (Join-Path $folder 'DarkForestGauntlet.exe')
foreach($name in @('GODOT-LICENSE.txt','GODOT-THIRD-PARTY-NOTICES.json','KENNEY-IMPACT-LICENSE.txt','KENNEY-NATURE-LICENSE.txt')) {
 Copy-Item -LiteralPath (Join-Path $projectRoot "builds/Forest-Playtest/$name") -Destination $folder
}
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/vendor/quaternius-fantasy/LICENSE.txt') -Destination (Join-Path $folder 'QUATERNIUS-LICENSE.txt')
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/vendor/polyhaven-forest/LICENSE.txt') -Destination (Join-Path $folder 'POLYHAVEN-LICENSE.txt')
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/environment/moonlit-ruins/receipt.json') -Destination (Join-Path $folder 'ART-RECEIPT.json')
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/vendor/polyhaven-forest/receipt.json') -Destination (Join-Path $folder 'TEXTURE-RECEIPT.json')
Copy-Item -LiteralPath (Join-Path $projectRoot 'artifacts/art-upgrade/sanctum.png') -Destination (Join-Path $folder 'PREVIEW.png')
if($PowerFX){
 foreach($name in @('KENNEY-LICENSE.txt','RPICSTER-LICENSE.txt','receipt.json')){
  Copy-Item -LiteralPath (Join-Path $projectRoot "assets/vendor/power-fx/$name") -Destination (Join-Path $folder "POWER-FX-$name")
 }
 Copy-Item -LiteralPath (Join-Path $projectRoot 'artifacts/power-fx-v3/power-fx-v3-preview.png') -Destination (Join-Path $folder 'PREVIEW.png')
}
@'
@echo off
cd /d "%~dp0"
start "Dark Forest Gauntlet" "DarkForestGauntlet.exe" --main-pack "DarkForestGauntlet.pck"
'@ | Set-Content (Join-Path $folder 'Play.cmd')
@'
DARK FOREST GAUNTLET - MOONLIT RUINS ART PLAYTEST

Extract the entire ZIP into a folder, then double-click Play.cmd.
Keep the executable and PCK together. Windows x64; no editor installation needed.

WASD: move | Space: attack | Shift: realm power | Hold E: revive
Enter: begin | 1-4 / Q: select gnome before starting | Esc: pause
Gamepad: Start joins, Y begins, X attacks, B uses power, A revives.

This art pass adds Blender-built ruins, twisted trees, bark creatures, 3D
equipment, free CC0 fantasy props, scanned textures and revised lighting.
The gnomes retain their existing 2D stepped puppet animation.
Gameplay rules and powers are unchanged from Combat v2.

This portable playtest uses the bundled Godot editor-runtime executable
with an exported data pack. It is not a release-template distribution.
Third-party licenses and asset receipts are included.
'@ | Set-Content (Join-Path $folder 'README.txt')
if($PowerFX){
 @'
DARK FOREST GAUNTLET - POWER FX v3 PLAYTEST

Extract the entire ZIP, then double-click Play.cmd to play.
Double-click Watch-Powers.cmd for an automatic four-character showcase.
Close the showcase window to exit it, then launch Play.cmd for normal play.
Keep the executable and PCK together. Windows x64; no editor installation needed.

WASD: move | Space: attack | Shift: realm power | Hold E: revive
Enter: begin | 1-4 / Q: select gnome before starting | Esc: pause
Gamepad: Start joins, Y begins, X attacks, B uses power, A revives.

Ember Hollow: flame trail, afterimages and an explosive landing.
Ironbark: three piercing arrows with tapered trails and splinter impacts.
Spore Grove: violet pulse and roots attached to actually snared targets.
Light Realm: golden Sanctuary pattern, rising light and ally healing halos.
All four classes retain their previous damage, range and cooldown values.

The showcase stages four real characters with automatic casts and durable
review targets. It does not require controllers and is not a balance test.
The gnomes retain their 2D stepped puppet animation in the 3D Moonlit Ruins.

This portable playtest uses the bundled Godot editor-runtime executable
with an exported data pack. It is not a release-template distribution.
CC0 textures: Kenney Particle Pack and RPicster VFX texture library.
Third-party licenses and asset receipts are included.
'@ | Set-Content (Join-Path $folder 'README.txt')
 @'
@echo off
cd /d "%~dp0"
start "Four Realm Powers" "DarkForestGauntlet.exe" --main-pack "DarkForestGauntlet.pck" --script res://scripts/power_showcase.gd --fixed-fps 60 -- --demo
'@ | Set-Content (Join-Path $folder 'Watch-Powers.cmd')
}
$process=Start-Process -FilePath (Join-Path $folder 'DarkForestGauntlet.exe') -WorkingDirectory $folder -ArgumentList @('--main-pack','DarkForestGauntlet.pck','--position','-2000,-2000','--quit-after','120','--log-file','standalone-smoke.log') -WindowStyle Hidden -PassThru -Wait
if($process.ExitCode -ne 0){throw 'Standalone smoke failed'}
if((Get-Content (Join-Path $folder 'standalone-smoke.log') -Raw) -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)'){throw 'Standalone engine errors'}
if($PowerFX){
 $demo=Start-Process -FilePath (Join-Path $folder 'DarkForestGauntlet.exe') -WorkingDirectory $folder -ArgumentList @('--main-pack','DarkForestGauntlet.pck','--script','res://scripts/power_showcase.gd','--fixed-fps','60','--position','-2000,-2000','--quit-after','400','--log-file','showcase-smoke.log','--','--demo') -WindowStyle Hidden -PassThru -Wait
 if($demo.ExitCode -ne 0 -or (Get-Content (Join-Path $folder 'showcase-smoke.log') -Raw) -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)'){throw 'Standalone showcase failed'}
}
if($KeyboardCoop){
 @'
@echo off
cd /d "%~dp0"
start "Keyboard Co-op" "DarkForestGauntlet.exe" --main-pack "DarkForestGauntlet.pck" -- --keyboard-party
'@ | Set-Content (Join-Path $folder 'Play-Keyboard-Coop.cmd')
 @'
DARK FOREST GAUNTLET - TWO-PLAYER KEYBOARD CO-OP

Extract the entire ZIP, then open Play-Keyboard-Coop.cmd.
Each person owns two gnomes. Click the four slots to change team lineups,
then press Enter. Choosing an occupied class swaps the two slots.

                 PLAYER 1          PLAYER 2
Move             WASD              Arrow keys
Attack           F                 J
Realm power      G                 K
Switch gnome     Q                 L
Hold to revive   E                 U

Esc pauses. Choose KEYBOARD CONTROLS to reassign keys; changes save.
The active gnome has a large P1/P2 arrow marker. The + gnome follows,
avoids nearby enemies and uses basic attacks. Only you spend its power.
Switching preserves health and cooldowns. If your gnome falls, control
passes to your living partner. Stand close and hold revive for 2 seconds.

Play.cmd also offers the original solo/controller mode. Watch-Powers.cmd
runs the automatic effects preview. Close a window before opening another.

Windows x64 with OpenGL 3.3. Runtime included. This playtest uses Godot's
editor-runtime executable plus a data pack, not a release-template export.
The Moonlit Ruins and all four updated realm powers are included.
CC0 assets, original licenses and hash receipts accompany this build.

Keyboard hardware can limit simultaneous keys. Test movement plus attack
together on your keyboard and reassign a binding if presses are missed.
'@ | Set-Content (Join-Path $folder 'README.txt')
 Copy-Item -LiteralPath (Join-Path $projectRoot 'artifacts/keyboard-coop/switched.png') -Destination (Join-Path $folder 'PREVIEW.png')
 $coop=Start-Process -FilePath (Join-Path $folder 'DarkForestGauntlet.exe') -WorkingDirectory $folder -ArgumentList @('--main-pack','DarkForestGauntlet.pck','--position','-2000,-2000','--quit-after','120','--log-file','keyboard-smoke.log','--','--keyboard-party') -WindowStyle Hidden -PassThru -Wait
 if($coop.ExitCode -ne 0 -or (Get-Content (Join-Path $folder 'keyboard-smoke.log') -Raw) -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)'){throw 'Packaged keyboard mode failed'}
}
if($MagicSequence){
 Copy-Item -LiteralPath (Join-Path $projectRoot 'artifacts/magic-sequence/magic-sequence-preview.png') -Destination (Join-Path $folder 'PREVIEW.png')
 Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/MAGIC_SEQUENCE.md') -Destination (Join-Path $folder 'MAGIC-SEQUENCE-NOTES.md')
 Add-Content (Join-Path $folder 'README.txt') "`nMAGIC SEQUENCE UPDATE: Tower Defense-inspired cores, arcs, impact stars and timed spell lights are included. Watch-Powers.cmd demonstrates all four powers."
}
if($LevelTwo){
 @'
@echo off
cd /d "%~dp0"
start "Level Two - Bellcap Cistern" "DarkForestGauntlet.exe" --main-pack "DarkForestGauntlet.pck" "res://scenes/bellcap_cistern.tscn" -- --keyboard-party
'@ | Set-Content (Join-Path $folder 'Play-Level-Two.cmd')
 Copy-Item -LiteralPath (Join-Path $projectRoot 'artifacts/level-two/mortar-warning.png') -Destination (Join-Path $folder 'PREVIEW.png')
 Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/LEVEL_TWO.md') -Destination $folder
 Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/LEVEL_TWO_FLOOR_PLAN.svg') -Destination $folder
 Copy-Item -LiteralPath (Join-Path $projectRoot 'artifacts/level-two/LEVEL_TWO_FLOOR_PLAN.png') -Destination $folder
 $controls=Get-Content (Join-Path $folder 'README.txt') -Raw
 @'
DARK FOREST GAUNTLET - LEVEL TWO: THE BELLCAP CISTERN

Extract the entire ZIP, then double-click Play-Level-Two.cmd for level two
with two-player keyboard teams. Press Enter to begin.
Play.cmd starts the campaign in solo/controller mode. You can select level
two from the lobby, or continue after escaping level one.

Explore a new cistern layout with canals, bridges and flanking routes.
Destroy three Cistern Anchors, defeat the enemies, collect the pear, and
bring every surviving gnome through the north exit.
Mortarcaps mark your position in orange, then drop damaging spore pools.
Move out of the circle or interrupt the caster with roots or stagger.
Ironroot Guards hit harder and take more punishment. The first anchor's
destruction brings reinforcements. See LEVEL_TWO.md and the floor-plan PNG.

'@ + $controls | Set-Content (Join-Path $folder 'README.txt')
 $level=Start-Process -FilePath (Join-Path $folder 'DarkForestGauntlet.exe') -WorkingDirectory $folder -ArgumentList @('--main-pack','DarkForestGauntlet.pck','res://scenes/bellcap_cistern.tscn','--position','-2000,-2000','--quit-after','180','--log-file','level-two-smoke.log','--','--keyboard-party') -WindowStyle Hidden -PassThru -Wait
 if($level.ExitCode -ne 0 -or (Get-Content (Join-Path $folder 'level-two-smoke.log') -Raw) -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)'){throw 'Packaged level two failed'}
}
$files=Get-ChildItem -LiteralPath $folder -File | Where-Object Name -ne 'manifest.json'
if($Celebration){
 Copy-Item -LiteralPath (Join-Path $projectRoot 'artifacts/celebration/preview.png') -Destination (Join-Path $folder 'PREVIEW.png')
 Copy-Item -LiteralPath (Join-Path $projectRoot 'artifacts/celebration/Maria-Victory-Loop.gif') -Destination $folder
 Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/characters/maria/source-receipt.json') -Destination (Join-Path $folder 'MARIA-ART-RECEIPT.json')
 Add-Content (Join-Path $folder 'README.txt') "`nCAMPAIGN UPDATE: Eat level one's Golden Pear to begin level two immediately. Classes, keyboard teams and active gnomes carry over. Escape level two for Maria's animated victory scroll. Maria-Victory-Loop.gif previews the seamless celebration."
 $files=Get-ChildItem -LiteralPath $folder -File | Where-Object Name -ne 'manifest.json'
}
if($StudioVFX){
 Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/STUDIO_VFX_UPDATE.md') -Destination $folder
 Copy-Item -LiteralPath (Join-Path $projectRoot 'artifacts/studio-vfx/studio-vfx-preview.png') -Destination (Join-Path $folder 'PREVIEW.png')
 Copy-Item -LiteralPath (Join-Path $projectRoot 'artifacts/studio-vfx/Studio-Powers-Preview.gif') -Destination $folder
 Copy-Item -LiteralPath (Join-Path $projectRoot 'artifacts/maria-jump-50/Maria-3D-Jump-50-Frame.gif') -Destination $folder
 $previousReadme=Get-Content (Join-Path $folder 'README.txt') -Raw
 ("STUDIO MAGIC UPDATE - SEPTEMBER 14, 2026`nFixed projectile sparks, new faceted crystal wakes and Spore crystals.`nOpen Watch-Powers.cmd to inspect all four updated powers.`nSee STUDIO_VFX_UPDATE.md for credits and verification.`n`n"+$previousReadme) | Set-Content (Join-Path $folder 'README.txt')
 $probeLog=Join-Path $projectRoot 'artifacts/studio-vfx/packaged-regression.log'
 & $engine --main-pack (Join-Path $folder 'DarkForestGauntlet.pck') --script (Join-Path $projectRoot 'tests/studio_vfx_regression.gd') --fixed-fps 60 --position -2000,-2000 --quit-after 300 *> $probeLog
 if($LASTEXITCODE -ne 0 -or (Get-Content $probeLog -Raw) -notmatch 'STUDIO VFX RESULT: 12 checks, 0 failures' -or (Get-Content $probeLog -Raw) -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)'){throw 'Packaged Studio VFX regression failed'}
 Copy-Item -LiteralPath $probeLog -Destination (Join-Path $folder 'studio-vfx-verification.log')
 $files=Get-ChildItem -LiteralPath $folder -File | Where-Object Name -ne 'manifest.json'
}
if($DynamicMaria){
 Copy-Item -LiteralPath (Join-Path $projectRoot 'artifacts/celebration/preview.png') -Destination (Join-Path $folder 'PREVIEW.png')
 Copy-Item -LiteralPath (Join-Path $projectRoot 'artifacts/maria-dynamic-50/Maria-Dynamic-50-Pose-Celebration.gif') -Destination (Join-Path $folder 'Maria-Victory-Loop.gif')
 Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/MARIA_DYNAMIC_CELEBRATION.md') -Destination $folder
 $oldReadme=Get-Content (Join-Path $folder 'README.txt') -Raw
 ("MARIA'S NEW VICTORY CELEBRATION`nBeat level two to see all 50 generated stop-motion poses on the victory scroll.`nThis replaces the previous five-pose animation. Both levels and repaired Studio effects are included.`n`n"+$oldReadme) | Set-Content (Join-Path $folder 'README.txt')
 $campaignLog=Join-Path $projectRoot 'artifacts/maria-dynamic-50/packaged-campaign.log'
 & $engine --main-pack (Join-Path $folder 'DarkForestGauntlet.pck') --script (Join-Path $projectRoot 'tests/campaign_regression.gd') --fixed-fps 60 --position -2000,-2000 --quit-after 1800 *> $campaignLog
 if($LASTEXITCODE -ne 0 -or (Get-Content $campaignLog -Raw) -notmatch 'CAMPAIGN RESULT: 15 checks, 0 failures' -or (Get-Content $campaignLog -Raw) -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)'){throw 'Packaged Maria campaign checks failed'}
 Copy-Item -LiteralPath $campaignLog -Destination (Join-Path $folder 'maria-campaign-verification.log')
 $files=Get-ChildItem -LiteralPath $folder -File | Where-Object Name -ne 'manifest.json'
}
$manifest=@($files | ForEach-Object { @{file=$_.Name;bytes=$_.Length;sha256=(Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower()} })
$manifest | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $folder 'manifest.json')
$archive=Join-Path $projectRoot $(if($LevelTwo){'builds/Dark-Forest-Gauntlet-Level-Two.zip'}elseif($MagicSequence){'builds/Dark-Forest-Gauntlet-Magic-Sequence.zip'}elseif($KeyboardCoop){'builds/Dark-Forest-Gauntlet-Keyboard-Coop.zip'}elseif($PowerFX){'builds/Dark-Forest-Gauntlet-Power-FX-v3.zip'}else{'builds/Dark-Forest-Gauntlet-Moonlit-Ruins.zip'})
if($Celebration){$archive=Join-Path $projectRoot 'builds/Dark-Forest-Gauntlet-Celebration.zip'}
if($StudioVFX){$archive=Join-Path $projectRoot 'builds/Dark-Forest-Gauntlet-Studio-VFX.zip'}
if($DynamicMaria){$archive=Join-Path $projectRoot 'builds/Dark-Forest-Gauntlet-Dynamic-Maria.zip'}
Compress-Archive -Path (Join-Path $folder '*') -DestinationPath $archive -Force
$zip=[IO.Compression.ZipFile]::OpenRead($archive)
try {
 foreach($row in $manifest){
  $entry=$zip.GetEntry($row.file)
  if(!$entry -or $entry.Length -ne $row.bytes){throw "Archive entry mismatch: $($row.file)"}
  $stream=$entry.Open()
  try {$sha=[Security.Cryptography.SHA256]::Create();$hash=[Convert]::ToHexString($sha.ComputeHash($stream)).ToLower()} finally {$stream.Dispose();$sha.Dispose()}
  if($hash -ne $row.sha256){throw "Archive hash mismatch: $($row.file)"}
 }
} finally {$zip.Dispose()}
Write-Output "PACKAGED AND VERIFIED: $archive"
