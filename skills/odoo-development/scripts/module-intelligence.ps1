#!/usr/bin/env pwsh
<#
.SYNOPSIS
Module Intelligence Report: analyze Odoo module structure
Produces 10-step analysis: manifest, models, views, controllers, data, tests, security, wizards, cron, qweb

.PARAMETER ProjectDir
Project root directory (defaults to current)
#>

param([string]$ProjectDir = (Get-Location))

Push-Location $ProjectDir
try {
    # Step 1: Validate module
    if (-not (Test-Path '__manifest__.py')) {
        Write-Host "❌ Not an Odoo module (missing __manifest__.py)" -ForegroundColor Red
        exit 1
    }

    Write-Host "Module Intelligence Report" -ForegroundColor Cyan
    Write-Host "===========================" -ForegroundColor Cyan
    Write-Host ""

    # Step 1: Manifest
    Write-Host "1️⃣  Manifest:" -ForegroundColor Yellow
    $manifest = Get-Content __manifest__.py
    $name = [regex]::Match($manifest, "['""]name['""]:\s*['""]([^'""]+)['""]").Groups[1].Value
    $version = [regex]::Match($manifest, "['""]version['""]:\s*['""]([^'""]+)['""]").Groups[1].Value
    Write-Host "   Name: $name"
    Write-Host "   Version: $version"
    Write-Host ""

    # Step 2: Models
    Write-Host "2️⃣  Models:" -ForegroundColor Yellow
    $models = Get-ChildItem -Path "models" -Filter "*.py" -ErrorAction SilentlyContinue | Measure-Object
    Write-Host "   Count: $($models.Count)"
    Write-Host ""

    # Step 3: Views
    Write-Host "3️⃣  Views:" -ForegroundColor Yellow
    $views = Get-ChildItem -Path "views" -Filter "*.xml" -ErrorAction SilentlyContinue | Measure-Object
    Write-Host "   Count: $($views.Count)"
    Write-Host ""

    # Step 4: Controllers
    Write-Host "4️⃣  Controllers:" -ForegroundColor Yellow
    $controllers = Get-ChildItem -Path "controllers" -Filter "*.py" -ErrorAction SilentlyContinue | Measure-Object
    Write-Host "   Count: $($controllers.Count)"
    Write-Host ""

    # Step 5: Data
    Write-Host "5️⃣  Data Files:" -ForegroundColor Yellow
    $data = Get-ChildItem -Path "data" -Filter "*.xml" -ErrorAction SilentlyContinue | Measure-Object
    Write-Host "   Count: $($data.Count)"
    Write-Host ""

    # Step 6: Tests
    Write-Host "6️⃣  Tests:" -ForegroundColor Yellow
    $tests = Get-ChildItem -Path "tests" -Filter "*.py" -ErrorAction SilentlyContinue | Measure-Object
    Write-Host "   Count: $($tests.Count)"
    Write-Host ""

    # Step 7: Security
    Write-Host "7️⃣  Security:" -ForegroundColor Yellow
    if (Test-Path "security/ir.model.access.csv") {
        Write-Host "   ACL: ✅ Defined"
    } else {
        Write-Host "   ACL: ❌ Missing"
    }
    if (Test-Path "security/ir_rule.xml") {
        Write-Host "   Rules: ✅ Defined"
    } else {
        Write-Host "   Rules: ⚠️  None"
    }
    Write-Host ""

    # Step 8: Wizards
    Write-Host "8️⃣  Wizards:" -ForegroundColor Yellow
    $wizards = Get-ChildItem -Path "wizard" -Filter "*.py" -ErrorAction SilentlyContinue | Measure-Object
    Write-Host "   Count: $($wizards.Count)"
    Write-Host ""

    # Step 9: Cron
    Write-Host "9️⃣  Automated Actions (Cron):" -ForegroundColor Yellow
    $cron = Select-String -Path "data/*.xml" -Pattern "ir.cron" -ErrorAction SilentlyContinue | Measure-Object
    Write-Host "   Count: $($cron.Count)"
    Write-Host ""

    # Step 10: Templates
    Write-Host "🔟 Templates (QWeb/OWL):" -ForegroundColor Yellow
    $templates = Get-ChildItem -Path "static" -Filter "*.xml" -Recurse -ErrorAction SilentlyContinue | Measure-Object
    Write-Host "   Count: $($templates.Count)"
    Write-Host ""

    Write-Host "✅ Module analysis complete" -ForegroundColor Green

    exit 0
} finally {
    Pop-Location
}
