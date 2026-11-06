$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$version = (Get-Content -LiteralPath (Join-Path $repo 'VERSION') -Raw).Trim()
& (Join-Path $PSScriptRoot 'build.ps1')
& (Join-Path $PSScriptRoot 'test.ps1')
$release = Join-Path $repo "dist/windows/$version"
$package = Join-Path $release "MacStayAwake-Windows-v$version"
[IO.Directory]::CreateDirectory($package) | Out-Null
$exeName = "WindowsStayAwake-v$version-win-x64.exe"
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'bin/WindowsStayAwake.exe') -Destination (Join-Path $release $exeName) -Force
Copy-Item -LiteralPath (Join-Path $release $exeName) -Destination $package -Force
foreach ($doc in @('README.md','USER-GUIDE.zh-Hant.md','VALIDATION.md','CHANGELOG.md')) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $doc) -Destination $package -Force
}
$zip = Join-Path $release "MacStayAwake-Windows-v$version-win-x64.zip"
Compress-Archive -LiteralPath $package -DestinationPath $zip -Force
$sourceZip = Join-Path $release "MacStayAwake-Windows-v$version-source.zip"
& git -C $repo archive --format=zip "--output=$sourceZip" HEAD
if ($LASTEXITCODE -ne 0) { throw 'Source archive creation failed.' }
$lines = foreach ($asset in @((Join-Path $release $exeName), $zip, $sourceZip)) {
    $hash = (Get-FileHash -LiteralPath $asset -Algorithm SHA256).Hash.ToLowerInvariant()
    "$hash  $([IO.Path]::GetFileName($asset))"
}
[IO.File]::WriteAllLines((Join-Path $release 'SHA256SUMS.txt'), $lines)
Write-Host "Release files: $release"
