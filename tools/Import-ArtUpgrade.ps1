$ErrorActionPreference = 'Stop'
$stage = Join-Path $PSScriptRoot '../artifacts/art-upgrade'
$dest = Join-Path $PSScriptRoot '../assets/vendor/polyhaven-forest'
New-Item -ItemType Directory -Force $dest | Out-Null
$rows = @()
foreach ($id in @('forest_leaves_02','rock_boulder_dry','bark_brown_02','cobblestone_floor_04')) {
    $metadata = Join-Path $stage "$id.json"
    if (!(Test-Path $metadata)) { Invoke-WebRequest "https://api.polyhaven.com/files/$id" -OutFile $metadata }
    $data = Get-Content $metadata -Raw | ConvertFrom-Json
    foreach ($map in @('diff','nor_gl','rough')) {
        $channel = $data.$map
        if (!$channel -and $map -eq 'diff') { $channel = $data.Diffuse }
        $entry = $channel.'1k'.jpg
        if (!$entry) { $entry = $channel.'1k'.png }
        if (!$entry) { throw "Missing 1k $map for $id" }
        $name = [IO.Path]::GetFileName(([uri]$entry.url).AbsolutePath)
        $file = Join-Path $dest $name
        if (!(Test-Path $file)) { Invoke-WebRequest $entry.url -OutFile $file }
        if ((Get-Item $file).Length -ne $entry.size) { throw "Size mismatch $name" }
        if ((Get-FileHash $file -Algorithm MD5).Hash.ToLower() -ne $entry.md5) { throw "Provider checksum mismatch $name" }
        $rows += @{file=$name;asset=$id;map=$map;source=$entry.url;page="https://polyhaven.com/a/$id";license='CC0-1.0';sha256=(Get-FileHash $file -Algorithm SHA256).Hash.ToLower();bytes=$entry.size}
    }
}
@{provider='Poly Haven';license='CC0-1.0';license_url='https://polyhaven.com/license';resolution='1k';files=$rows} | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $dest 'receipt.json')
'Poly Haven assets: CC0 1.0 Universal. https://polyhaven.com/license and https://creativecommons.org/publicdomain/zero/1.0/ . See receipt.json for individual source URLs and integrity hashes.' | Set-Content (Join-Path $dest 'LICENSE.txt')
$archive = Join-Path $stage 'fantasy_props_megakitstandard.zip'
$source = 'https://opengameart.org/sites/default/files/fantasy_props_megakitstandard.zip'
if (!(Test-Path $archive)) { Invoke-WebRequest $source -OutFile $archive }
$zip = [IO.Compression.ZipFile]::OpenRead($archive)
try {
    foreach ($entry in $zip.Entries) {
        if ($entry.FullName -match '(^[/\\]|(^|[/\\])\.\.([/\\]|$)|:)') { throw 'Unsafe archive entry' }
    }
} finally { $zip.Dispose() }
if (!(Test-Path (Join-Path $stage 'fantasy-props'))) { Expand-Archive -LiteralPath $archive -DestinationPath (Join-Path $stage 'fantasy-props') }
@{source=$source;page='https://opengameart.org/content/fantasy-props-megakit';author='Quaternius';license='CC0-1.0';sha256=(Get-FileHash $archive -Algorithm SHA256).Hash.ToLower()} | ConvertTo-Json | Set-Content (Join-Path $stage 'fantasy-props-source.json')
Write-Output 'Verified 12 Poly Haven texture maps and staged Quaternius Fantasy Props Standard.'
