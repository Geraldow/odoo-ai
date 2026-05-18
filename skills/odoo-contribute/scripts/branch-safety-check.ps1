#!/usr/bin/env pwsh
<#
.SYNOPSIS
Branch Safety Protocol: verify current branch and remote branches
Applies Odoo branch safety rules (st_*, st_produccion allowed; produccion/db_* restricted)

.PARAMETER ProjectDir
Project root directory (defaults to current)
#>

param([string]$ProjectDir = (Get-Location))

Push-Location $ProjectDir
try {
    $null = git rev-parse --git-dir 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Not a git repository" -ForegroundColor Red
        exit 1
    }

    $current = git branch --show-current
    $remotes = git branch -r

    Write-Host "Branch Safety Check" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Current: $current"
    Write-Host ""
    Write-Host "Remote branches:"
    Write-Host $remotes

    # Safety rules
    if ($current -match '^(st_|st_produccion)') {
        Write-Host ""
        Write-Host "✅ Branch $current is allowed" -ForegroundColor Green
        exit 0
    }
    elseif ($current -match '^(produccion|db_)') {
        Write-Host ""
        Write-Host "🔒 Branch $current is RESTRICTED" -ForegroundColor Red
        Write-Host "   → push/merge requires authorization"
        exit 1
    }
    else {
        Write-Host ""
        Write-Host "⚠️  Branch $current is unknown" -ForegroundColor Yellow
        Write-Host "   → verify before push"
        exit 0
    }
} finally {
    Pop-Location
}
