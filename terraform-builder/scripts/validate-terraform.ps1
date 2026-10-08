#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Validates every Terraform root (directory containing main.tf) under a tree.
.DESCRIPTION
  Runs `terraform init -backend=false` and `terraform validate -json` per root. Init output is
  shown only on failure; diagnostics are printed one per line as <path>:<line>: <severity>: <message>.
  Provider plugins are cached across roots (TF_PLUGIN_CACHE_DIR) to avoid repeat downloads.
  Exits 1 on any error.
.EXAMPLE
  ./validate-terraform.ps1 [root-path]   # root-path defaults to ./terraform if present, else .
#>
param([string]$Target)

$ErrorActionPreference = 'Stop'
$env:TF_IN_AUTOMATION = '1'
if (-not $env:TF_PLUGIN_CACHE_DIR) {
    $env:TF_PLUGIN_CACHE_DIR = Join-Path $HOME '.terraform.d/plugin-cache'
}
New-Item -ItemType Directory -Force $env:TF_PLUGIN_CACHE_DIR | Out-Null

if (-not $Target) { $Target = if (Test-Path 'terraform' -PathType Container) { 'terraform' } else { '.' } }
$Target = (Resolve-Path $Target).Path
$cwd = (Get-Location).Path.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar

$isHidden = { param($p) $p.Substring($Target.Length) -match '[\\/]\.[^\\/]+[\\/]' }
$roots = if (Test-Path (Join-Path $Target 'main.tf')) { @(Get-Item $Target) } else {
    Get-ChildItem $Target -Recurse -Depth 4 -File -Filter main.tf |
        Where-Object { -not (& $isHidden $_.FullName) } | ForEach-Object { $_.Directory } | Sort-Object FullName
}
if (-not $roots) { Write-Output "FAIL no main.tf found under $Target"; exit 1 }

$failed = 0; $errorCount = 0; $warningCount = 0
foreach ($root in $roots) {
    $rel = [regex]::Replace($root.FullName, '^' + [regex]::Escape($cwd), '', 'IgnoreCase') -replace '\\', '/'
    $ErrorActionPreference = 'Continue'
    $init = & terraform "-chdir=$($root.FullName)" init -backend=false -input=false -no-color 2>&1
    $initExit = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($initExit -ne 0) {
        $failed++; $errorCount++
        Write-Output "${rel}: init failed"
        $init | ForEach-Object { "$_" } | Where-Object { $_.Trim() -and $_ -ne 'System.Management.Automation.RemoteException' } |
            Select-Object -Last 15 | ForEach-Object { "  $_" }
        continue
    }

    $ErrorActionPreference = 'Continue'
    $json = (& terraform "-chdir=$($root.FullName)" validate -json -no-color 2>$null) -join "`n"
    $ErrorActionPreference = 'Stop'
    $result = $json | ConvertFrom-Json
    if (-not $result.valid) { $failed++ }
    foreach ($d in $result.diagnostics) {
        if ($d.severity -eq 'error') { $errorCount++ } else { $warningCount++ }
        $where = if ($d.range) { "$rel/$($d.range.filename):$($d.range.start.line)" } else { $rel }
        $detail = if ($d.detail) { " - " + ($d.detail -replace '\s+', ' ') } else { '' }
        Write-Output "${where}: $($d.severity): $($d.summary)$detail"
    }
}

$summary = "roots=$(@($roots).Count) errors=$errorCount warnings=$warningCount"
if ($failed -gt 0) { Write-Output "FAIL $summary"; exit 1 }
Write-Output "PASS $summary"
