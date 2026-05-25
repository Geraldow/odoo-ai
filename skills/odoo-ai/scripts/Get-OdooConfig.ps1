#Requires -Version 7.0
<#
.SYNOPSIS
    Loads odoo-ai local configuration and returns a $cfg PSCustomObject.
.DESCRIPTION
    Dot-source this file from any odoo-ai script to get $cfg in the caller's scope.
    4-layer fallback:
      L1: config.local.yaml at skill root (machine-specific, gitignored)
      L2: $env:ODOO_ENTERPRISE_PATH (CI / Docker environments)
      L3: Known path candidates (auto-detect)
      L4: Community-only mode (sets $cfg.CommunityOnly = $true)

    Usage:
      . "$PSScriptRoot/Get-OdooConfig.ps1"
      Grep $cfg.EnterprisePath -recurse -pattern "field_name"

.OUTPUTS
    $cfg [PSCustomObject] in the caller's scope with:
      EnterprisePath  — path to Enterprise source root, or $null
      CommunityPath   — path to Community source root, or $null
      ProjectsRoot    — root containing 18\, 19\ project folders
      OdooBinPaths    — ordered list of odoo-bin binary candidates
      DockerPort      — default 18069
      CommunityOnly   — $true when Enterprise not available
      Contributor     — PSCustomObject {Name, Email, Github, Role}
      DriveEngramPath — Google Drive engram sync folder, or $null
      Source          — where config was loaded from
#>

Set-StrictMode -Version Latest

# ─── Path resolution ─────────────────────────────────────────────────────────
$_skillRoot = Split-Path $PSScriptRoot -Parent
$_configFile = Join-Path $_skillRoot "config.local.yaml"

# ─── Minimal inline YAML parser (shallow key extraction, no external module) ──
function _ParseYamlShallow {
    param([string]$content)
    $map = @{}
    $section = ""
    $odoo_bin_list = [System.Collections.Generic.List[string]]::new()

    foreach ($line in ($content -split "`n")) {
        $line = $line.TrimEnd()
        if ($line -match '^(\w[\w_]*):\s*$') {
            $section = $matches[1]
            continue
        }
        if ($section -and $line -match '^\s{2}(\w[\w_]*):\s*"?([^"#]*)"?\s*(?:#.*)?$') {
            $key = $matches[1]; $val = $matches[2].Trim().Trim('"')
            $map["$section.$key"] = $val
            continue
        }
        # odoo_bin list items
        if ($section -eq "paths" -and $line -match '^\s{4}-\s*"?([^"#]+)"?\s*$') {
            $odoo_bin_list.Add($matches[1].Trim().Trim('"'))
        }
    }
    if ($odoo_bin_list.Count -gt 0) { $map["paths.odoo_bin"] = $odoo_bin_list.ToArray() }
    return $map
}

# ─── L3 candidate paths (auto-detect) ────────────────────────────────────────
$_defaultOdooRoot = Join-Path "C:\" "Development\Odoo"
$_defaultEnterpriseRoot = Join-Path $_defaultOdooRoot "Enterprise"
$_defaultCommunityRoot = Join-Path $_defaultOdooRoot "Community"
$_defaultOdoo18Bin = Join-Path $_defaultOdooRoot "18\odoo-bin"
$_defaultOdoo19Bin = Join-Path $_defaultOdooRoot "19\odoo-bin"

$_enterpriseCandidates = @(
    $_defaultEnterpriseRoot,
    "C:\Odoo\Enterprise",
    "D:\Development\Odoo\Enterprise",
    "$env:USERPROFILE\Odoo\Enterprise",
    "$env:USERPROFILE\Development\Odoo\Enterprise"
)
$_communityCandidates = @(
    $_defaultCommunityRoot,
    "C:\Odoo\Community",
    "D:\Development\Odoo\Community",
    "$env:USERPROFILE\Odoo\Community",
    "$env:USERPROFILE\Development\Odoo\Community"
)
$_projectsCandidates = @(
    $_defaultOdooRoot,
    "C:\Odoo\Projects",
    "D:\Development\Odoo",
    "$env:USERPROFILE\Odoo",
    "$env:USERPROFILE\Development\Odoo"
)
$_odooBinCandidates = @(
    $_defaultOdoo18Bin,
    $_defaultOdoo19Bin,
    "C:\Odoo\18\odoo-bin",
    "C:\Odoo\19\odoo-bin"
) + @((Get-Command odoo-bin -ErrorAction SilentlyContinue)?.Source | Where-Object { $_ })

# ─── Initialize defaults ──────────────────────────────────────────────────────
$cfg = [PSCustomObject]@{
    EnterprisePath  = $null
    CommunityPath   = $null
    ProjectsRoot    = $null
    OdooBinPaths    = @()
    DockerPort      = 18069
    CommunityOnly   = $false
    Contributor     = [PSCustomObject]@{
        Name   = ""
        Email  = ""
        Github = ""
        Role   = ""
    }
    DriveEngramPath = $null
    Source          = "community-only"
}

# ─── L1: config.local.yaml ───────────────────────────────────────────────────
if (Test-Path $_configFile) {
    $_yaml = Get-Content $_configFile -Raw
    $_map  = _ParseYamlShallow $_yaml

    if ($_map["paths.enterprise"]) { $cfg.EnterprisePath  = $_map["paths.enterprise"] }
    if ($_map["paths.community"])  { $cfg.CommunityPath   = $_map["paths.community"]  }
    if ($_map["paths.projects"])   { $cfg.ProjectsRoot    = $_map["paths.projects"]   }
    if ($_map["paths.odoo_bin"])   { $cfg.OdooBinPaths    = $_map["paths.odoo_bin"]   }
    if ($_map["docker.port"])      { $cfg.DockerPort      = [int]$_map["docker.port"] }
    if ($_map["contributor.name"])  { $cfg.Contributor.Name   = $_map["contributor.name"]   }
    if ($_map["contributor.email"]) { $cfg.Contributor.Email  = $_map["contributor.email"]  }
    if ($_map["contributor.github"]){ $cfg.Contributor.Github = $_map["contributor.github"] }
    if ($_map["contributor.role"])  { $cfg.Contributor.Role   = $_map["contributor.role"]   }
    if ($_map["engram.drive_path"]) { $cfg.DriveEngramPath    = $_map["engram.drive_path"]  }

    $cfg.Source = "config.local.yaml"
}

# ─── L2: environment variables (override config.local.yaml if set) ────────────
if ($env:ODOO_ENTERPRISE_PATH -and (Test-Path $env:ODOO_ENTERPRISE_PATH)) {
    $cfg.EnterprisePath = $env:ODOO_ENTERPRISE_PATH
    if ($cfg.Source -eq "community-only") { $cfg.Source = "env" }
}
if ($env:ODOO_COMMUNITY_PATH -and (Test-Path $env:ODOO_COMMUNITY_PATH)) {
    $cfg.CommunityPath = $env:ODOO_COMMUNITY_PATH
}
if ($env:ODOO_PROJECTS_ROOT -and (Test-Path $env:ODOO_PROJECTS_ROOT)) {
    $cfg.ProjectsRoot = $env:ODOO_PROJECTS_ROOT
}

# ─── L3: Auto-detect if not yet resolved ─────────────────────────────────────
$_autoDetected = $false

if (-not $cfg.EnterprisePath) {
    foreach ($p in $_enterpriseCandidates) {
        if ($p -and (Test-Path $p)) { $cfg.EnterprisePath = $p; $_autoDetected = $true; break }
    }
}
if (-not $cfg.CommunityPath) {
    foreach ($p in $_communityCandidates) {
        if ($p -and (Test-Path $p)) { $cfg.CommunityPath = $p; break }
    }
}
if (-not $cfg.ProjectsRoot) {
    foreach ($p in $_projectsCandidates) {
        if ($p -and (Test-Path $p)) { $cfg.ProjectsRoot = $p; break }
    }
}
if (-not $cfg.OdooBinPaths -or $cfg.OdooBinPaths.Count -eq 0) {
    $cfg.OdooBinPaths = @($_odooBinCandidates | Where-Object { $_ -and (Test-Path $_) })
}

if ($_autoDetected -and $cfg.Source -eq "community-only") {
    $cfg.Source = "auto-detected"
    Write-Host "[odoo-config] auto-detected Enterprise path: $($cfg.EnterprisePath)" -ForegroundColor Cyan
}

# ─── L4: Community-only fallback ─────────────────────────────────────────────
if (-not $cfg.EnterprisePath) {
    $cfg.CommunityOnly = $true
    $cfg.Source        = "community-only"
    Write-Warning "[odoo-config] Enterprise source not found. Running in Community-only mode."
    Write-Warning "             Run setup-contributor.ps1 to configure paths, or create config.local.yaml."
}

# ─── Clean up local helpers (don't pollute caller scope) ─────────────────────
Remove-Variable _skillRoot, _configFile, _defaultOdooRoot, _defaultEnterpriseRoot, `
    _defaultCommunityRoot, _defaultOdoo18Bin, _defaultOdoo19Bin, `
    _enterpriseCandidates, _communityCandidates, _projectsCandidates, `
    _odooBinCandidates, _autoDetected -ErrorAction SilentlyContinue
Remove-Item function:_ParseYamlShallow -ErrorAction SilentlyContinue
