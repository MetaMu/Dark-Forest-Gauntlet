$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$engine = Join-Path $PSScriptRoot 'godot\Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $engine)) {
    throw 'Extract the standard Godot 4.7.2 Windows download into tools/godot first.'
}
$result = & $engine --headless --path $projectRoot --script tests/regression.gd 2>&1
$engineExit = $LASTEXITCODE
$result | Write-Output
if ($engineExit -ne 0 -or ($result -join "`n") -notmatch 'RESULT: 34 checks, 0 failures') {
    throw 'Godot regression checks failed. See the output above.'
}
