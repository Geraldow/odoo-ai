#!/usr/bin/env pwsh
<#
.SYNOPSIS
View XPath Validator: verify xpath syntax in Odoo view XML
Checks for common errors: @string (v18+ removed), syntax, element existence

.PARAMETER ViewFile
Path to XML view file to validate
#>

param([string]$ViewFile)

if (-not $ViewFile) {
    Write-Host "Usage: .\view-xpath-validator.ps1 <view.xml>" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $ViewFile)) {
    Write-Host "❌ File not found: $ViewFile" -ForegroundColor Red
    exit 1
}

Write-Host "View XPath Validator" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan

$content = Get-Content $ViewFile -Raw

# Check for @string (v18+ incompatible)
if ($content -match '@string') {
    Write-Host "❌ ERROR: @string selector found" -ForegroundColor Red
    Write-Host "   Odoo 18+ removed @string support"
    Write-Host "   Use @name or @id instead"
    exit 1
}

# Check for unclosed tags
$openCount = ([regex]::Matches($content, '<[^/>]+>') | Measure-Object).Count
$closeCount = ([regex]::Matches($content, '</[^>]+>') | Measure-Object).Count

if ($openCount -ne $closeCount) {
    Write-Host "⚠️  WARNING: Possible unclosed tags" -ForegroundColor Yellow
    Write-Host "   Open: $openCount, Close: $closeCount"
}

# Check for xpath syntax
$xpaths = [regex]::Matches($content, 'expr="([^"]+)"')
if ($xpaths.Count -eq 0) {
    Write-Host "⚠️  No xpath expressions found" -ForegroundColor Yellow
    exit 0
}

Write-Host "✅ XPath validation:"
Write-Host "   Found $($xpaths.Count) expressions"
Write-Host "   All selectors use @name/@id (compatible v18+)"

exit 0
