#Requires -Version 7.0
<#
.SYNOPSIS
    Initializes local odoo-ai contributor configuration for this machine.
.DESCRIPTION
    Detects git and GitHub identity, asks for the contributor role, writes
    config.local.yaml, updates CONTRIBUTING.md, and installs git hooks.
.PARAMETER DryRun
    Shows detected values and planned changes without writing files. Exits 2.
.OUTPUTS
    Exit 0 - Setup complete
    Exit 1 - User cancelled or invalid role
    Exit 2 - Dry run complete
    Exit 3 - Environment error
#>
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest

. "$PSScriptRoot\Get-OdooConfig.ps1"

$skillRoot = Split-Path $PSScriptRoot -Parent
$configFile = Join-Path $skillRoot "config.local.yaml"
$contribFile = Join-Path $skillRoot "plugins\odoo-development-alesco\CONTRIBUTING.md"
$installHooks = Join-Path $PSScriptRoot "git-hooks\install-hooks.ps1"
$defaultOdooRoot = Join-Path "C:\" "Development\Odoo"

function Get-CommandValue {
    param([scriptblock]$Command)
    try {
        $value = & $Command 2>$null
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($value)) {
            return ($value | Select-Object -First 1).ToString().Trim()
        }
    } catch {}
    return ""
}

function Get-FirstExistingPath {
    param([string[]]$Candidates)
    foreach ($candidate in $Candidates) {
        if ($candidate -and (Test-Path $candidate)) { return $candidate }
    }
    return ""
}

function ConvertTo-YamlValue {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return '""' }
    return '"' + ($Value -replace '\\', '\\' -replace '"', '\"') + '"'
}

$gitName = Get-CommandValue { git config user.name }
$gitEmail = Get-CommandValue { git config user.email }
$githubLogin = ""
if (Get-Command gh -ErrorAction SilentlyContinue) {
    $githubLogin = Get-CommandValue { gh api user --jq '.login' }
}

$enterprisePath = if ($cfg.EnterprisePath) { $cfg.EnterprisePath } else {
    Get-FirstExistingPath @(
        (Join-Path $defaultOdooRoot "Enterprise"),
        "C:\Odoo\Enterprise",
        "D:\Development\Odoo\Enterprise",
        "$env:USERPROFILE\Odoo\Enterprise",
        "$env:USERPROFILE\Development\Odoo\Enterprise"
    )
}
$communityPath = if ($cfg.CommunityPath) { $cfg.CommunityPath } else {
    Get-FirstExistingPath @(
        (Join-Path $defaultOdooRoot "Community"),
        "C:\Odoo\Community",
        "D:\Development\Odoo\Community",
        "$env:USERPROFILE\Odoo\Community",
        "$env:USERPROFILE\Development\Odoo\Community"
    )
}
$projectsRoot = if ($cfg.ProjectsRoot) { $cfg.ProjectsRoot } else {
    Get-FirstExistingPath @(
        $defaultOdooRoot,
        "C:\Odoo\Projects",
        "D:\Development\Odoo",
        "$env:USERPROFILE\Odoo",
        "$env:USERPROFILE\Development\Odoo"
    )
}
$odooBinPaths = @($cfg.OdooBinPaths | Where-Object { $_ })
if ($odooBinPaths.Count -eq 0) {
    $odooBinPaths = @(@(
        $(if ($projectsRoot) { Join-Path $projectsRoot "18\odoo-bin" }),
        $(if ($projectsRoot) { Join-Path $projectsRoot "19\odoo-bin" }),
        (Get-Command odoo-bin -ErrorAction SilentlyContinue)?.Source
    ) | Where-Object { $_ -and (Test-Path $_) })
}

Write-Host ""
Write-Host "Odoo AI Contributor Setup"
Write-Host "-----------------------------------------"
Write-Host "git user.name:  $gitName"
Write-Host "git user.email: $gitEmail"
Write-Host "GitHub login:   $githubLogin"
Write-Host "Enterprise:     $enterprisePath"
Write-Host "Community:      $communityPath"
Write-Host "Projects:       $projectsRoot"
Write-Host ""

$role = Read-Host "Cual es tu rol? [developer/lead/reviewer]"
if ($role -notin @("developer", "lead", "reviewer")) {
    Write-Host "ERROR: Rol invalido. Usa developer, lead o reviewer."
    exit 1
}

$yamlLines = [System.Collections.Generic.List[string]]::new()
$yamlLines.Add("# odoo-ai local configuration - machine-specific, gitignored")
$yamlLines.Add("")
$yamlLines.Add("paths:")
$yamlLines.Add("  enterprise: $(ConvertTo-YamlValue $enterprisePath)")
$yamlLines.Add("  community:  $(ConvertTo-YamlValue $communityPath)")
$yamlLines.Add("  projects:   $(ConvertTo-YamlValue $projectsRoot)")
$yamlLines.Add("  odoo_bin:")
if ($odooBinPaths.Count -gt 0) {
    foreach ($path in $odooBinPaths) {
        $yamlLines.Add("    - $(ConvertTo-YamlValue $path)")
    }
} else {
    $yamlLines.Add("    # - ""C:\\Development\\Odoo\\18\\odoo-bin""")
}
$yamlLines.Add("")
$yamlLines.Add("docker:")
$yamlLines.Add("  port: $($cfg.DockerPort)")
$yamlLines.Add("")
$yamlLines.Add("contributor:")
$yamlLines.Add("  name:   $(ConvertTo-YamlValue $gitName)")
$yamlLines.Add("  email:  $(ConvertTo-YamlValue $gitEmail)")
$yamlLines.Add("  github: $(ConvertTo-YamlValue $githubLogin)")
$yamlLines.Add("  role:   $(ConvertTo-YamlValue $role)")
$yamlLines.Add("")
$yamlLines.Add("engram:")
$yamlLines.Add("  drive_path: $(ConvertTo-YamlValue $cfg.DriveEngramPath)")

$contribEntry = @"

### $gitName
- **GitHub**: ``$githubLogin``
- **Email autorizado**: ``$gitEmail``
- **Nombre en git**: ``$gitName``
- **Rol**: $role
"@

Write-Host "Planned config.local.yaml:"
$yamlLines | ForEach-Object { Write-Host "  $_" }
Write-Host ""
Write-Host "Planned CONTRIBUTING.md entry:"
Write-Host $contribEntry

if ($DryRun) {
    Write-Host ""
    Write-Host "[DRY RUN] No files written."
    exit 2
}

if (Test-Path $configFile) {
    Write-Host ""
    Get-Content $configFile | ForEach-Object { Write-Host "  $_" }
    $overwrite = Read-Host "Sobreescribir? [s/n]"
    if ($overwrite -ne "s") {
        Write-Host "Cancelado por el usuario."
        exit 1
    }
}

$yamlLines | Set-Content $configFile -Encoding UTF8
Write-Host "Wrote: $configFile"

if (Test-Path $contribFile) {
    $contribContent = Get-Content $contribFile -Raw
    if ($gitEmail -and $contribContent -match [regex]::Escape($gitEmail)) {
        Write-Host "CONTRIBUTING.md already contains this email. Skipping append."
    } else {
        Copy-Item $contribFile "$contribFile.bak" -Force
        Add-Content $contribFile $contribEntry -Encoding UTF8
        Write-Host "Updated: $contribFile"
    }
} else {
    Write-Host "WARNING: CONTRIBUTING.md not found: $contribFile"
}

if (Test-Path $installHooks) {
    & $installHooks -RepoPath .
    exit $LASTEXITCODE
}

Write-Host "WARNING: install-hooks.ps1 not found: $installHooks"
exit 0
