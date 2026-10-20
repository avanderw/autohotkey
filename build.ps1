[CmdletBinding()]
param(
    [string]$AhkPath = "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe",
    [string]$CompilerPath = "$PSScriptRoot\.tools\Ahk2Exe.exe",
    [string]$IsccPath = "$PSScriptRoot\.tools\Inno Setup 6\ISCC.exe",
    [string]$RuntimeLicense = "$env:ProgramFiles\AutoHotkey\license.txt",
    [switch]$TestsOnly,
    [switch]$SkipInstaller
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Push-Location $PSScriptRoot
try {
    if (!(Test-Path $AhkPath)) {
        throw "AutoHotkey v2 x64 not found: $AhkPath. Supply -AhkPath."
    }
    $runtimeVersion = (Get-Item $AhkPath).VersionInfo.ProductVersion
    if ($runtimeVersion -notmatch '^2\.') {
        throw "Use an AutoHotkey v2 executable base, not v1: $runtimeVersion"
    }

    function Invoke-CheckedProcess([string]$Path, [string[]]$Arguments) {
        $stdout = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
        $stderr = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
        try {
            $process = Start-Process -FilePath $Path -ArgumentList $Arguments -PassThru `
                -RedirectStandardOutput $stdout -RedirectStandardError $stderr
            if (!$process.WaitForExit(60000)) {
                $process.Kill()
                $process.WaitForExit()
                throw "Process timed out: $Path $Arguments"
            }
            $process.Refresh()
            Get-Content $stdout, $stderr | Write-Host
            if ($process.ExitCode -ne 0) {
                throw "Process failed with exit code $($process.ExitCode): $Path $Arguments"
            }
        } finally {
            Remove-Item $stdout, $stderr -ErrorAction SilentlyContinue
        }
    }

    Invoke-CheckedProcess $AhkPath @('/ErrorStdOut=UTF-8', '"tests\journal-parse.test.ahk"', '--check')
    Invoke-CheckedProcess $AhkPath @('/ErrorStdOut=UTF-8', '"tests\journal-core.test.ahk"')
    Invoke-CheckedProcess $AhkPath @('/ErrorStdOut=UTF-8', '"tests\journal-app.test.ahk"')
    if ($TestsOnly) {
        Write-Host 'All tests passed.'
        return
    }
    if (!(Test-Path $CompilerPath)) {
        throw "Ahk2Exe not found: $CompilerPath. Download the official compiler and supply -CompilerPath; see README.md."
    }
    if (!(Test-Path $RuntimeLicense)) {
        throw 'Supply -RuntimeLicense with the license distributed with the chosen AutoHotkey runtime.'
    }
    foreach ($required in @('LICENSE', 'ICON-LICENSE.txt', 'check-in.svg', 'check-in.ico')) {
        if (!(Test-Path $required)) {
            throw "Missing required release asset: $required"
        }
    }
    $source = Get-Content 'journal.ahk' -Raw
    $version = [regex]::Match($source, 'appVersion := "([0-9.]+)"').Groups[1].Value
    if (!$version -or $source -notmatch ";@Ahk2Exe-SetVersion $([regex]::Escape($version))\s") {
        throw 'The appVersion and Ahk2Exe version directive must match.'
    }
    New-Item 'dist' -ItemType Directory -Force | Out-Null
    $output = Join-Path $PSScriptRoot 'dist\Self-Check-In.exe'
    if (Test-Path $output) {
        Remove-Item $output
    }
    Invoke-CheckedProcess $CompilerPath @('/in', '"journal.ahk"', '/out', ('"' + $output + '"'),
        '/base', ('"' + $AhkPath + '"'), '/icon', '"check-in.ico"', '/compress', '0', '/silent', 'verbose')
    if (!(Test-Path $output)) {
        throw 'Compiler returned without producing the executable.'
    }
    Invoke-CheckedProcess $output @('--check')
    Invoke-CheckedProcess $AhkPath @('/ErrorStdOut=UTF-8', '"tests\journal-compiled.test.ahk"', ('"' + $output + '"'))
    $manifest = [ordered]@{
        appName = 'Self-Check-In'
        appVersion = $version
        runtimeVersion = $runtimeVersion
        runtimeSha256 = (Get-FileHash $AhkPath -Algorithm SHA256).Hash
        compilerVersion = (Get-Item $CompilerPath).VersionInfo.FileVersion
        compilerSha256 = (Get-FileHash $CompilerPath -Algorithm SHA256).Hash
        architecture = 'x64'
        publisher = 'Andrew van der Westhuizen'
        applicationLicense = 'MIT'
        iconSource = 'https://github.com/lucide-icons/lucide/blob/0.468.0/icons/bell-ring.svg'
        iconLicense = 'ISC'
        iconSha256 = (Get-FileHash 'check-in.ico' -Algorithm SHA256).Hash
        signed = (Get-AuthenticodeSignature $output).Status.ToString()
    }
    $manifest | ConvertTo-Json | Set-Content 'dist\build-info.json' -Encoding UTF8
    Copy-Item $RuntimeLicense 'dist\AutoHotkey-license.txt'
    $packageFiles = @('journal.ahk', 'journal-core.ahk', 'check-in.ico', 'check-in.svg', 'LICENSE', 'ICON-LICENSE.txt', 'README.md', 'THIRD-PARTY.md')
    Copy-Item $packageFiles -Destination 'dist'
    $zip = "dist\Self-Check-In-$version-windows-x64-portable.zip"
    $zipInputs = @($output, 'dist\build-info.json', 'dist\AutoHotkey-license.txt') +
        @($packageFiles | ForEach-Object { Join-Path 'dist' $_ })
    Compress-Archive -Path $zipInputs -DestinationPath $zip -Force
    $artifacts = @($output, $zip)
    if (!$SkipInstaller) {
        if (!(Test-Path $IsccPath)) {
            $IsccPath = "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
        }
        if (!(Test-Path $IsccPath)) {
            $IsccPath = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
        }
        if (!(Test-Path $IsccPath)) {
            throw 'Inno Setup compiler not found. Supply -IsccPath, or use -SkipInstaller for the portable pilot.'
        }
        Invoke-CheckedProcess $IsccPath @('/Qp', "/DAppVersion=$version", '"installer.iss"')
        $artifacts += "dist\Self-Check-In-$version-windows-x64-setup.exe"
    }
    $artifacts | ForEach-Object {
        $hash = Get-FileHash $_ -Algorithm SHA256
        '{0}  {1}' -f $hash.Hash.ToLowerInvariant(), (Split-Path $_ -Leaf)
    } | Set-Content 'dist\SHA256SUMS.txt' -Encoding ASCII
    Write-Host "Built Self-Check-In $version. Artifacts are in dist. Public release gates remain in todo.md."
} finally {
    Pop-Location
}