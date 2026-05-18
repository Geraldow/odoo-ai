#!/usr/bin/env pwsh
<#
.SYNOPSIS
Environment detection: Odoo.sh vs local development
Detects project type by git branch patterns + Docker status

.PARAMETER ProjectDir
Project root directory (defaults to current)
#>

param([string]$ProjectDir = (Get-Location))

$OdooShPatterns = @('st_produccion', 'st_\w+', 'produccion', 'db_produccion', 'db_\w+')

function Test-OdooShEnvironment {
    param([string]$Path)
    Push-Location $Path
    try {
        $null = git rev-parse --git-dir 2>$null
        if ($LASTEXITCODE -ne 0) { return "NOT_GIT_REPO" }

        $branches = git branch -r 2>$null | ForEach-Object { $_.Trim().Split('/')[1] } | Where-Object { $_ }
        foreach ($branch in $branches) {
            foreach ($pattern in $OdooShPatterns) {
                if ($branch -match "^$pattern$") { return "ODOO_SH" }
            }
        }
        return "LOCAL_DEV"
    } finally {
        Pop-Location
    }
}

function Get-DockerStatus {
    docker ps 2>$null
    if ($LASTEXITCODE -eq 0) { return "DOCKER_RUNNING" }
    else { return "DOCKER_NOT_RUNNING" }
}

# ========== MAIN ==========

$env = Test-OdooShEnvironment -Path $ProjectDir

Write-Host "Environment Detection" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

switch ($env) {
    "NOT_GIT_REPO" {
        Write-Host "❌ Not a git repository" -ForegroundColor Red
        exit 1
    }
    "ODOO_SH" {
        Write-Host "✅ Odoo.sh Deployment" -ForegroundColor Green
        exit 0
    }
    "LOCAL_DEV" {
        Write-Host "🖥️  Local Development" -ForegroundColor Yellow
        $docker = Get-DockerStatus
        if ($docker -eq "DOCKER_RUNNING") {
            Write-Host "✅ Docker running"
        } else {
            Write-Host "⚠️  Docker not running → docker-compose up -d"
        }
        exit 0
    }
}
