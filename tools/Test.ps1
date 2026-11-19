$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$engine = Join-Path $PSScriptRoot 'godot\Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $engine)) {
    throw 'Extract the standard Godot 4.7.2 Windows download into tools/godot first.'
}
$result = & $engine --headless --path $projectRoot --script tests/regression.gd 2>&1
$engineExit = $LASTEXITCODE
$result | Write-Output
if ($engineExit -ne 0 -or ($result -join "`n") -notmatch 'RESULT: 34 checks, 0 failures' -or ($result -join "`n") -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)') {
    throw 'Godot regression checks failed. See the output above.'
}
$realmResult = & $engine --headless --path $projectRoot --script tests/realm_regression.gd 2>&1
$realmExit = $LASTEXITCODE
$realmResult | Write-Output
if ($realmExit -ne 0 -or ($realmResult -join "`n") -notmatch 'REALM RESULT: 25 checks, 0 failures' -or ($realmResult -join "`n") -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)') {
    throw 'Realm regression checks failed. See the output above.'
}
$powerResult = & $engine --headless --path $projectRoot --script tests/power_regression.gd 2>&1
$powerExit = $LASTEXITCODE
$powerResult | Write-Output
if ($powerExit -ne 0 -or ($powerResult -join "`n") -notmatch 'POWER RESULT: 24 checks, 0 failures' -or ($powerResult -join "`n") -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)') {
    throw 'Power and animation regression checks failed. See the output above.'
}
$vfxResult = & $engine --headless --path $projectRoot --script tests/vfx_regression.gd --fixed-fps 60 2>&1
$vfxExit = $LASTEXITCODE
$vfxResult | Write-Output
if ($vfxExit -ne 0 -or ($vfxResult -join "`n") -notmatch 'VFX RESULT: 20 checks, 0 failures' -or ($vfxResult -join "`n") -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)') {
    throw 'Power effect lifecycle checks failed. See the output above.'
}
# Exercise repeated scene transitions in the production renderer. Godot's dummy
# renderer reports a material-lifetime error here that does not occur in OpenGL.
$keyboardResult = & $engine --path $projectRoot --script tests/keyboard_party_regression.gd --fixed-fps 60 --position -2000,-2000 2>&1
$keyboardExit = $LASTEXITCODE
$keyboardResult | Write-Output
if ($keyboardExit -ne 0 -or ($keyboardResult -join "`n") -notmatch 'KEYBOARD RESULT: 30 checks, 0 failures' -or ($keyboardResult -join "`n") -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)') {
    throw 'Shared keyboard party checks failed.'
}
$levelResult = & $engine --path $projectRoot --script tests/level_two_regression.gd --fixed-fps 60 --position -2000,-2000 2>&1
$levelExit = $LASTEXITCODE
$levelResult | Write-Output
if ($levelExit -ne 0 -or ($levelResult -join "`n") -notmatch 'LEVEL TWO RESULT: 23 checks, 0 failures' -or ($levelResult -join "`n") -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)') {
    throw 'Level two combat and navigation checks failed.'
}
$campaignResult = & $engine --path $projectRoot --script tests/campaign_regression.gd --fixed-fps 60 --position -2000,-2000 2>&1
$campaignExit = $LASTEXITCODE
$campaignResult | Write-Output
if ($campaignExit -ne 0 -or ($campaignResult -join "`n") -notmatch 'CAMPAIGN RESULT: 15 checks, 0 failures' -or ($campaignResult -join "`n") -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)') {
    throw 'Pear transition and victory celebration checks failed.'
}
$studioResult = & $engine --path $projectRoot --script tests/studio_vfx_regression.gd --fixed-fps 60 --position -2000,-2000 2>&1
$studioExit = $LASTEXITCODE
$studioResult | Write-Output
if ($studioExit -ne 0 -or ($studioResult -join "`n") -notmatch 'STUDIO VFX RESULT: 12 checks, 0 failures' -or ($studioResult -join "`n") -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)') {
    throw 'Studio particle placement, timing and crystal checks failed.'
}
$rootlingResult = & $engine --path $projectRoot --script tests/rootling_animation_regression.gd --fixed-fps 60 --position -2000,-2000 --quit-after 1200 2>&1
$rootlingExit = $LASTEXITCODE
$rootlingResult | Write-Output
if ($rootlingExit -ne 0 -or ($rootlingResult -join "`n") -notmatch 'ROOTLING ANIMATION RESULT: 17 checks, 0 failures' -or ($rootlingResult -join "`n") -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)') {
    throw 'Atlas Rootling animation checks failed.'
}

$rigResult = & $engine --path $projectRoot --script tests/rig_regression.gd --fixed-fps 60 --position -2000,-2000 --quit-after 1200 2>&1
$rigExit = $LASTEXITCODE
$rigResult | Write-Output
if ($rigExit -ne 0 -or ($rigResult -join "`n") -notmatch 'RIG RESULT: 57 checks, 0 failures' -or ($rigResult -join "`n") -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)') {
    throw '3D character and enemy rig checks failed.'
}
# Ember snapshots require the real renderer to bake the current skin pose.
$emberResult = & $engine --path $projectRoot --script tests/ember_regression.gd --fixed-fps 60 --position -2000,-2000 --quit-after 1200 2>&1
$emberExit = $LASTEXITCODE
$emberResult | Write-Output
if ($emberExit -ne 0 -or ($emberResult -join "`n") -notmatch 'EMBER RESULT: 8 checks, 0 failures' -or ($emberResult -join "`n") -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)') {
    throw 'Ember pose snapshots, flame wake and cleanup checks failed.'
}

$ironbarkResult = & $engine --path $projectRoot --script tests/ironbark_regression.gd --fixed-fps 60 --position -2000,-2000 --quit-after 1200 2>&1
$ironbarkExit = $LASTEXITCODE
$ironbarkResult | Write-Output
if ($ironbarkExit -ne 0 -or ($ironbarkResult -join "`n") -notmatch 'IRONBARK RESULT: 10 checks, 0 failures' -or ($ironbarkResult -join "`n") -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)') {
    throw 'Ironbark streak, leaf, piercing-impact and cleanup checks failed.'
}

$remainingResult = & $engine --path $projectRoot --script tests/remaining_power_regression.gd --fixed-fps 60 --position -2000,-2000 --quit-after 1200 2>&1
$remainingExit = $LASTEXITCODE
$remainingResult | Write-Output
if ($remainingExit -ne 0 -or ($remainingResult -join "`n") -notmatch 'REMAINING POWERS RESULT: 17 checks, 0 failures' -or ($remainingResult -join "`n") -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)') {
    throw 'Spore growth, Sanctuary healing and status-lifetime checks failed.'
}

$overlapResult = & $engine --path $projectRoot --script tests/all_power_smoke.gd --fixed-fps 60 --position -2000,-2000 --quit-after 1800 2>&1
$overlapExit = $LASTEXITCODE
$overlapResult | Write-Output
if ($overlapExit -ne 0 -or ($overlapResult -join "`n") -notmatch 'cleanup=true; failures=0' -or ($overlapResult -join "`n") -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)') {
    throw 'Repeated four-player power overlap and cleanup checks failed.'
}

$uiResult = & $engine --path $projectRoot --script tests/ui_regression.gd --fixed-fps 60 --position -2000,-2000 --quit-after 1200 2>&1
$uiExit = $LASTEXITCODE
$uiResult | Write-Output
if ($uiExit -ne 0 -or ($uiResult -join "`n") -notmatch 'UI RESULT: 24 checks, 0 failures' -or ($uiResult -join "`n") -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)') {
    throw 'Gnomish menu navigation, transparency and responsive layout checks failed.'
}

$mixamoResult = & $engine --path $projectRoot --script tests/mixamo_regression.gd --fixed-fps 60 --position -2000,-2000 --quit-after 1200 2>&1
$mixamoExit = $LASTEXITCODE
$mixamoResult | Write-Output
if ($mixamoExit -ne 0 -or ($mixamoResult -join "`n") -notmatch 'MIXAMO RESULT: 56 checks, 0 failures' -or ($mixamoResult -join "`n") -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)') {
    throw 'Mixamo loops, smooth playback, casting and grip checks failed.'
}


$castResult = & $engine --path $projectRoot --script tests/cast_sync_regression.gd --fixed-fps 60 --position -2000,-2000 --quit-after 1800 2>&1
$castExit = $LASTEXITCODE
$castResult | Write-Output
if ($castExit -ne 0 -or ($castResult -join "`n") -notmatch 'CAST SYNC RESULT: 60 checks, 0 failures' -or ($castResult -join "`n") -match '(SCRIPT ERROR|SHADER ERROR|ERROR:)') {
    throw 'Casting animation, release timing, interruption and lighting checks failed.'
}
