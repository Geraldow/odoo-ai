#Requires -Version 7.0
<#
.SYNOPSIS
    Runs Odoo tests for a module using odoo-bin.
.PARAMETER Module
    Module technical name. Auto-detected from __manifest__.py if omitted.
.PARAMETER Database
    Target database name (required).
.PARAMETER LogLevel
    Odoo log level. Default: test
.PARAMETER RepoPath
    Path to the module directory. Defaults to current directory.
.PARAMETER OdooBin
    Path to odoo-bin. Auto-detected if omitted.
.OUTPUTS
    Exit 0 — Tests passed (0 failures, 0 errors)
    Exit 1 — Tests failed or module/DB not found
#>
param(
    [string]$Module    = "",
    [Parameter(Mandatory)][string]$Database,
    [string]$LogLevel  = "test",
    [string]$RepoPath  = ".",
    [string]$OdooBin   = ""
)

Set-StrictMode -Version Latest

. "$PSScriptRoot\Get-OdooConfig.ps1"

# Auto-detect module from __manifest__.py
if ([string]::IsNullOrWhiteSpace($Module)) {
    $manifestPath = Join-Path $RepoPath "__manifest__.py"
    if (-not (Test-Path $manifestPath)) {
        Write-Host "ERROR: Module not detected. No __manifest__.py found at: $RepoPath"
        Write-Host "       Pass -Module explicitly."
        exit 1
    }
    $manifestContent = Get-Content $manifestPath -Raw
    if ($manifestContent -match "'name'\s*:\s*'([^']+)'") {
        $Module = $matches[1]
    } elseif ($manifestContent -match '"name"\s*:\s*"([^"]+)"') {
        $Module = $matches[1]
    } else {
        Write-Host "ERROR: Could not extract module name from __manifest__.py"
        exit 1
    }
    # Convert display name to technical name (folder name is more reliable)
    $Module = (Get-Item $RepoPath).Name
}

# Auto-detect odoo-bin
if ([string]::IsNullOrWhiteSpace($OdooBin)) {
    $candidates = @($cfg.OdooBinPaths)
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            $OdooBin = $candidate
            break
        }
    }
    if ([string]::IsNullOrWhiteSpace($OdooBin)) {
        Write-Host "ERROR: odoo-bin not found. Pass -OdooBin explicitly."
        exit 1
    }
}

Write-Host ""
Write-Host "Odoo Test Runner"
Write-Host "─────────────────────────────────────────"
Write-Host "Module:   $Module"
Write-Host "Database: $Database"
Write-Host "Log:      $LogLevel"
Write-Host "odoo-bin: $OdooBin"
Write-Host ""

$cmd = "python `"$OdooBin`" -u $Module --test-enable -d $Database --stop-after-init --log-level=$LogLevel"
Write-Host "Running: $cmd"
Write-Host ""

$result = Invoke-Expression $cmd 2>&1
$result | Write-Host

# Parse results from output
$passed = ($result | Select-String "OK" | Measure-Object).Count
$failed = ($result | Select-String "FAIL|ERROR" | Measure-Object).Count

Write-Host ""
Write-Host "─────────────────────────────────────────"
if ($failed -eq 0) {
    Write-Host "✅ Tests: $passed passed, 0 failed"
    exit 0
} else {
    Write-Host "❌ Tests: $passed passed, $failed failed/errors"
    exit 1
}
