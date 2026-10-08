#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Validates every Bicep root, unreferenced shared module, and .bicepparam file under a tree.
.DESCRIPTION
  Builds each main.bicep (which also compiles referenced modules), any module not referenced
  by another .bicep file, and each params/*.bicepparam into builds/env.<env>.json. Compiled
  ARM templates are discarded, so no stray .json files are written next to sources.
  Diagnostics are de-duplicated, paths are made relative, and doc links are stripped so the
  output stays compact. Exits 1 on any error.
.EXAMPLE
  ./validate-bicep.ps1 [root-path]   # root-path defaults to ./bicep if present, else .
#>
param([string]$Target)

$ErrorActionPreference = 'Stop'
$env:AZURE_BICEP_CHECK_VERSION = 'false'

if (-not $Target) { $Target = if (Test-Path 'bicep' -PathType Container) { 'bicep' } else { '.' } }
$Target = (Resolve-Path $Target).Path
$cwd = (Get-Location).Path.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
$useBicep = [bool](Get-Command bicep -ErrorAction SilentlyContinue)

$script:failed = 0
$script:diagnostics = [System.Collections.Generic.List[string]]::new()

function Invoke-Build([string[]]$BicepArgs, [string[]]$AzArgs) {
    $ErrorActionPreference = 'Continue'
    $output = if ($useBicep) { & bicep @BicepArgs 2>&1 } else { & az bicep @AzArgs 2>&1 }
    if ($LASTEXITCODE -ne 0) { $script:failed++ }
    # Only stderr carries diagnostics; stdout is the compiled ARM template and is discarded.
    foreach ($line in $output | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }) {
        $text = "$line" -replace '^(WARNING|ERROR): ', '' -replace '\s*\[https://aka\.ms/[^\]]+\]$', ''
        $text = [regex]::Replace($text, [regex]::Escape($cwd), '', 'IgnoreCase')
        if ($text.Trim() -and $text -ne 'System.Management.Automation.RemoteException') { $script:diagnostics.Add($text.Trim()) }
    }
}

$isHidden = { param($p) $p.Substring($Target.Length) -match '[\\/]\.[^\\/]+[\\/]' }
$bicepFiles = Get-ChildItem $Target -Recurse -File -Filter *.bicep | Where-Object { -not (& $isHidden $_.FullName) }
$roots = $bicepFiles | Where-Object { $_.Name -eq 'main.bicep' -and $_.FullName -notmatch '[\\/]modules[\\/]' }
$modules = $bicepFiles | Where-Object { $_.FullName -match '[\\/]modules[\\/]' }
$allContent = @{}; $bicepFiles | ForEach-Object { $allContent[$_.FullName] = Get-Content $_.FullName -Raw }
$orphans = $modules | Where-Object {
    $name = $_.Name; $self = $_.FullName
    -not ($allContent.Keys | Where-Object { $_ -ne $self -and $allContent[$_] -match [regex]::Escape($name) })
}

foreach ($f in @($roots) + @($orphans)) {
    Invoke-Build @('build', $f.FullName, '--stdout') @('build', '--file', $f.FullName, '--stdout')
}

$paramFiles = Get-ChildItem $Target -Recurse -File -Filter *.bicepparam |
    Where-Object { $_.Directory.Name -eq 'params' -and -not (& $isHidden $_.FullName) }
foreach ($pf in $paramFiles) {
    $builds = Join-Path $pf.Directory.Parent.FullName 'builds'
    New-Item -ItemType Directory -Force $builds | Out-Null
    $envName = $pf.BaseName -replace '^env\.', ''
    $out = Join-Path $builds "env.$envName.json"
    Invoke-Build @('build-params', $pf.FullName, '--outfile', $out) @('build-params', '--file', $pf.FullName, '--outfile', $out)
}

$unique = $script:diagnostics | Sort-Object -Unique
$errors = @($unique | Where-Object { $_ -match ': Error ' -or $_ -notmatch ': Warning ' })
$warnings = @($unique | Where-Object { $_ -match ': Warning ' })
$errors + $warnings | ForEach-Object { Write-Output $_ }

$summary = "roots=$(@($roots).Count) orphan-modules=$(@($orphans).Count) params=$(@($paramFiles).Count) errors=$($errors.Count) warnings=$($warnings.Count)"
if ($script:failed -gt 0) { Write-Output "FAIL $summary"; exit 1 }
Write-Output "PASS $summary"
