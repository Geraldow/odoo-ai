#!/usr/bin/env pwsh
<#
.SYNOPSIS
Detect Odoo version and edition from __manifest__.py
Returns: version, edition (Community/Enterprise), module name

.PARAMETER ProjectDir
Project root directory (defaults to current)
#>

param([string]$ProjectDir = (Get-Location))

Push-Location $ProjectDir
try {
    # Find __manifest__.py
    $manifest = Get-ChildItem -Name '__manifest__.py' -ErrorAction SilentlyContinue
    if (-not $manifest) {
        Write-Host "❌ No __manifest__.py found" -ForegroundColor Red
        exit 1
    }

    Write-Host "Odoo Version Detection" -ForegroundColor Cyan
    Write-Host "=====================" -ForegroundColor Cyan

    # Read manifest
    $content = Get-Content $manifest -Raw

    # Extract version — handles both single and double quotes
    $version = [regex]::Match($content, "['""]version['""\s*]:\s*['""](\d+)").Groups[1].Value
    if (-not $version) {
        $version = [regex]::Match($content, "version['""\s]*:\s*['""](\d+)").Groups[1].Value
    }

    # Extract name — handles both quote styles
    $name = [regex]::Match($content, "['""]name['""]:\s*['""]([^'""]+)['""]").Groups[1].Value

    # Detect edition from license — handles both quote styles
    if ($content -match "['""]license['""]:\s*['""]OEEL-1['""]") {
        $edition = "Enterprise"
    } else {
        $edition = "Community"
    }

    Write-Host "Module: $name"
    Write-Host "Version: Odoo $version"
    Write-Host "Edition: $edition"

    exit 0
} finally {
    Pop-Location
}
