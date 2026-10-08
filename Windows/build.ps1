$ErrorActionPreference = 'Stop'
$project = $PSScriptRoot
$outDir = Join-Path $project 'bin'
[IO.Directory]::CreateDirectory($outDir) | Out-Null
$framework = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319'
$references = @('System.dll','System.Core.dll','System.Xml.dll','System.Drawing.dll','System.Windows.Forms.dll','WPF\WindowsBase.dll','WPF\PresentationCore.dll','WPF\PresentationFramework.dll','System.Xaml.dll') | ForEach-Object { '/reference:' + (Join-Path $framework $_) }
& (Join-Path $framework 'csc.exe') /nologo /target:winexe /platform:x64 /optimize+ /main:StayAwake.Program ("/out:$outDir\WindowsStayAwake.exe") ("/win32icon:$project\Assets\AppIcon.ico") ("/resource:$project\MainWindow.xaml,MainWindow.xaml") ("/resource:$project\Assets\CoffeeMark.png,CoffeeMark.png") ("/resource:$project\Assets\AppIcon.ico,AppIcon.ico") $references "$project\AssemblyInfo.cs" "$project\App.cs" "$project\PowerService.cs" "$project\Strings.cs"
if ($LASTEXITCODE -ne 0) { throw 'Compilation failed.' }
Write-Host "Built $outDir\WindowsStayAwake.exe"
