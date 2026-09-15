$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$stage=Join-Path $root 'artifacts/power-fx-v3'
$dest=Join-Path $root 'assets/vendor/power-fx'
New-Item -ItemType Directory -Force $dest | Out-Null
$archive=Join-Path $stage 'kenney-particles.zip'
$zip=[IO.Compression.ZipFile]::OpenRead($archive)
$rows=@()
try {
 $license=$zip.Entries | Where-Object { $_.FullName -match 'License.txt$' } | Select-Object -First 1
 if(!$license){throw 'Missing Kenney license'}
 $reader=[IO.StreamReader]::new($license.Open())
 try{$text=$reader.ReadToEnd()}finally{$reader.Dispose()}
 if($text -notmatch 'CC0'){throw 'Unexpected license'}
 $text | Set-Content (Join-Path $dest 'KENNEY-LICENSE.txt')
 foreach($name in @('flame_01','smoke_01','spark_05','light_02','scorch_01','trace_01')) {
  $entry=$zip.GetEntry("PNG (Transparent)/$name.png")
  if(!$entry){throw "Missing selected texture $name"}
  $file=Join-Path $dest "$name.png"
  $inputStream=$entry.Open();$outputStream=[IO.File]::Create($file)
  try{$inputStream.CopyTo($outputStream)}finally{$inputStream.Dispose();$outputStream.Dispose()}
  $rows+=@{file="$name.png";source="https://kenney.nl/assets/particle-pack";archive_sha256=(Get-FileHash $archive -Algorithm SHA256).Hash.ToLower();entry=$entry.FullName;license='CC0-1.0';sha256=(Get-FileHash $file -Algorithm SHA256).Hash.ToLower()}
 }
}finally{$zip.Dispose()}
$tree=Get-Content (Join-Path $stage 'rpicster-tree.json') -Raw | ConvertFrom-Json
$base="https://raw.githubusercontent.com/RPicster/Godot-particle-and-vfx-textures/$($tree.sha)"
Invoke-WebRequest "$base/LICENSE" -OutFile (Join-Path $dest 'RPICSTER-LICENSE.txt')
if((Get-Content (Join-Path $dest 'RPICSTER-LICENSE.txt') -Raw) -notmatch 'CC0'){throw 'Unexpected RPicster license'}
foreach($name in @('effect_1','spotlight_1','spotlight_6')) {
 $url="$base/textures/256/alpha/$name.png"
 $file=Join-Path $dest "$name.png"
 Invoke-WebRequest $url -OutFile $file
 $rows+=@{file="$name.png";source=$url;commit=$tree.sha;license='CC0-1.0';sha256=(Get-FileHash $file -Algorithm SHA256).Hash.ToLower()}
}
@{license='CC0-1.0';description='Selected original CC0 alpha textures for game-native power effects';files=$rows} | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $dest 'receipt.json')
'CC0 1.0 assets from Kenney and Raffaele Picca. Original licenses: KENNEY-LICENSE.txt and RPICSTER-LICENSE.txt. Exact sources and SHA-256 hashes: receipt.json.' | Set-Content (Join-Path $dest 'LICENSE.txt')
Write-Output 'IMPORTED 9 CC0 POWER TEXTURES'
