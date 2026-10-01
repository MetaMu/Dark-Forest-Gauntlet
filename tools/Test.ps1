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
