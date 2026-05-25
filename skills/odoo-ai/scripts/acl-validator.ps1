#Requires -Version 7.0
<#
.SYNOPSIS
    Validates that all models.Model classes in a module have entries in ir.model.access.csv.
.PARAMETER ModulePath
    Path to the Odoo module directory. Defaults to current directory.
.OUTPUTS
    Exit 0 — All models have ACL coverage
    Exit 1 — One or more models missing from ir.model.access.csv
    Exit 3 — Environment error (no models/ dir, no ACL file found)
#>
param(
    [string]$ModulePath = "."
)

Set-StrictMode -Version Latest

$modelsDir = Join-Path $ModulePath "models"
$aclFile   = Join-Path $ModulePath "security" "ir.model.access.csv"

Write-Host ""
Write-Host "ACL Validator — $ModulePath"
Write-Host "─────────────────────────────────────────"

# Check models directory
if (-not (Test-Path $modelsDir)) {
    Write-Host "⚠️  No models/ directory found — nothing to validate."
    exit 0
}

# Check ACL file
$aclExists = Test-Path $aclFile
if (-not $aclExists) {
    Write-Host "🚫 CRITICAL: security/ir.model.access.csv not found."
    Write-Host "   RULES.md R4 requires ACL for every models.Model class."
    exit 1
}

# Read ACL file content
$aclContent = Get-Content $aclFile -Raw

# Scan Python files for models.Model classes
$pythonFiles = Get-ChildItem -Path $modelsDir -Filter "*.py" -Recurse
$foundModels  = [System.Collections.Generic.List[string]]::new()

foreach ($file in $pythonFiles) {
    $content = Get-Content $file.FullName -Raw

    # Find class definitions inheriting models.Model (not Abstract or Transient)
    $matches = [regex]::Matches($content, 'class\s+\w+\s*\(\s*models\.Model\s*\)')
    if ($matches.Count -eq 0) { continue }

    # Extract _name values near each class
    $classPositions = $matches | ForEach-Object { $_.Index }
    foreach ($pos in $classPositions) {
        # Search _name in next 500 chars after class definition
        $snippet = $content.Substring($pos, [Math]::Min(500, $content.Length - $pos))
        if ($snippet -match "_name\s*=\s*['""]([a-z][a-z0-9_.]+)['""]") {
            $modelName = $matches[1]
            if (-not $foundModels.Contains($modelName)) {
                $foundModels.Add($modelName)
            }
        }
    }
}

if ($foundModels.Count -eq 0) {
    Write-Host "✅ No models.Model classes found — nothing to validate."
    exit 0
}

# Check each model against ACL
$missing = [System.Collections.Generic.List[string]]::new()
foreach ($model in $foundModels) {
    # ACL CSV uses model name with dots replaced by underscores as the model field
    $modelDotted = $model
    if ($aclContent -notmatch [regex]::Escape($modelDotted)) {
        $missing.Add($model)
    }
}

if ($missing.Count -eq 0) {
    Write-Host "✅ ACL OK: all $($foundModels.Count) model(s) covered."
    Write-Host ""
    $foundModels | ForEach-Object { Write-Host "   ✅ $_" }
    exit 0
} else {
    Write-Host "🚫 ACL MISSING — RULES.md R4 violation:"
    Write-Host ""
    $missing | ForEach-Object { Write-Host "   ❌ Missing ACL: $_" }
    Write-Host ""
    $covered = $foundModels | Where-Object { $missing -notcontains $_ }
    $covered | ForEach-Object { Write-Host "   ✅ Covered:     $_" }
    Write-Host ""
    Write-Host "Add entries to: security/ir.model.access.csv"
    exit 1
}
