$ErrorActionPreference = 'Stop'
$framework = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319'
& (Join-Path $framework 'csc.exe') /nologo /target:exe ("/out:$PSScriptRoot\bin\Tests.exe") "$PSScriptRoot\PowerService.cs" "$PSScriptRoot\Tests.cs"
if ($LASTEXITCODE -ne 0) { throw 'Test compilation failed.' }
& "$PSScriptRoot\bin\Tests.exe"
if ($LASTEXITCODE -ne 0) { throw 'Tests failed.' }
