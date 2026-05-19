# engram-session-end.ps1
# Export your memories to Drive + import teammates' latest memories at session end.
# Called automatically by the Claude Stop hook (global settings.json).
#
# Discovers projects dynamically by scanning Drive for dirs containing project.json.
# Falls back to legacy sync (no project.json) for pre-existing project folders.
#
# Single-project:  cwd leaf matches a project folder → sync that project only
# Multi-project:   cwd is workspace root or unknown  → sync all discovered projects

$configPath = [System.IO.Path]::Combine($env:USERPROFILE, ".claude", "engram-sync-config.json")
if (-not (Test-Path -LiteralPath $configPath)) { exit 0 }

$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$owner  = $config.owner

# ── RESOLVE DRIVE PATH ────────────────────────────────────────────────────────

$detectScript = [System.IO.Path]::Combine(
    $env:USERPROFILE, ".claude", "skills", "engram-drive", "scripts", "detect-environment.ps1")

if (-not (Test-Path -LiteralPath $detectScript)) { exit 0 }

. $detectScript -RunDetection:$false

$base = Resolve-DrivePath $config.base_relative
if (-not $base -or -not (Test-Path -LiteralPath $base)) { exit 0 }

# ── GUARD: engram in PATH ─────────────────────────────────────────────────────

if (-not (Get-Command engram -ErrorAction SilentlyContinue)) { exit 0 }

# ── DISCOVER PROJECTS ─────────────────────────────────────────────────────────
# A project folder is any direct child of $base that contains a project.json
# OR any direct child that has owner's subfolder (legacy — no project.json).

$allProjectDirs = [System.IO.Directory]::GetDirectories($base) |
    Where-Object { -not (Split-Path $_ -Leaf).StartsWith('.') }

$discovered = @()
foreach ($dir in $allProjectDirs) {
    $projectName  = Split-Path $dir -Leaf
    $projectJson  = [System.IO.Path]::Combine($dir, "project.json")
    $ownerSubdir  = [System.IO.Path]::Combine($dir, $owner)

    if (Test-Path -LiteralPath $projectJson) {
        $discovered += @{ Name = $projectName; Path = $dir; HasConfig = $true }
    } elseif (Test-Path -LiteralPath $ownerSubdir) {
        $discovered += @{ Name = $projectName; Path = $dir; HasConfig = $false }
    }
}

if ($discovered.Count -eq 0) { exit 0 }

# ── DETECT ACTIVE SCOPE ───────────────────────────────────────────────────────

$cwdLeaf        = Split-Path (Get-Location).Path -Leaf
$matchedProject = $discovered | Where-Object { $_.Name -eq $cwdLeaf } | Select-Object -First 1

$activeProjects = if ($matchedProject) { @($matchedProject) } else { $discovered }

# ── EXPORT + IMPORT ───────────────────────────────────────────────────────────

foreach ($proj in $activeProjects) {
    $projectPath = $proj.Path
    $projectName = $proj.Name

    # Read project.json if present — check auto_sync and membership
    if ($proj.HasConfig) {
        try {
            $pjson    = Get-Content -LiteralPath ([System.IO.Path]::Combine($projectPath, "project.json")) -Raw | ConvertFrom-Json
            $members  = $pjson.members | ForEach-Object { $_.name }
            $autoSync = if ($null -ne $pjson.auto_sync) { $pjson.auto_sync } else { $true }

            if (-not $autoSync) { continue }
            if ($owner -notin $members) { continue }  # owner not in this project

            $teammates = $members | Where-Object { $_ -ne $owner }
        } catch {
            $teammates = @()  # corrupt project.json → legacy fallback
        }
    } else {
        # Legacy: derive teammates from subfolders
        $teammates = [System.IO.Directory]::GetDirectories($projectPath) |
            ForEach-Object { Split-Path $_ -Leaf } |
            Where-Object { $_ -ne $owner -and -not $_.StartsWith('.') }
    }

    # EXPORT — write only to your own subfolder (always first)
    $ownerDir = [System.IO.Path]::Combine($projectPath, $owner)
    if (Test-Path -LiteralPath $ownerDir) {
        Push-Location -LiteralPath $ownerDir
        try { engram sync --project $projectName 2>$null }
        finally { Pop-Location }
    }

    # IMPORT — read from each teammate who has already synced
    foreach ($tm in $teammates) {
        $manifest = [System.IO.Path]::Combine($projectPath, $tm, ".engram", "manifest.json")
        if (Test-Path -LiteralPath $manifest) {
            $tmDir = [System.IO.Path]::Combine($projectPath, $tm)
            Push-Location -LiteralPath $tmDir
            try { engram sync --import --project $projectName 2>$null }
            finally { Pop-Location }
        }
    }
}
