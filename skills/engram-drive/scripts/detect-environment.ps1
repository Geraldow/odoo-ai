# detect-environment.ps1
# Scans the system for: Google Drive mount point, Odoo project repos,
# and git contributors per project.
# Output: JSON to stdout — consumed by /engram-drive setup
#
# IMPORTABLE: dot-source this file to use Resolve-DrivePath in other scripts:
#   . "$PSScriptRoot\detect-environment.ps1" -RunDetection $false

param(
    [string]$WorkspacePath = "",
    [bool]$RunDetection = $true
)

# ── SHARED UTILITY: Resolve-DrivePath ────────────────────────────────────────
# Converts base_relative (e.g. "[1] Geraldo/.../engram-sync") to absolute path.
# Windows: scans drive letters for "My Drive". macOS: ~/Library/CloudStorage.
# Returns $null if Google Drive is not mounted.

function Resolve-DrivePath {
    param([string]$BaseRelative)

    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        $myDrivePath = $null
        foreach ($letter in 65..90 | ForEach-Object { [char]$_ }) {
            $candidate = "${letter}:\My Drive"
            if ([System.IO.Directory]::Exists($candidate)) {
                $myDrivePath = $candidate
                break
            }
        }
        if (-not $myDrivePath) { return $null }
        return [System.IO.Path]::Combine($myDrivePath, $BaseRelative)
    } else {
        $cloudStorage = [System.IO.Path]::Combine($env:HOME, "Library", "CloudStorage")
        try {
            $gdDirs = [System.IO.Directory]::GetDirectories($cloudStorage, "GoogleDrive-*")
        } catch { return $null }
        if (-not $gdDirs -or $gdDirs.Count -eq 0) { return $null }
        return [System.IO.Path]::Combine($gdDirs[0], "My Drive", $BaseRelative)
    }
}

if (-not $RunDetection) { return }

$result = @{
    drive_found   = $false
    drive_letter  = ""
    drive_root    = ""
    sync_base     = ""
    odoo_projects = @()
    contributors  = @{}
    errors        = @()
}

# ── 1. FIND GOOGLE DRIVE MOUNT POINT ─────────────────────────────────────────

# Check if Google Drive for Desktop process is running
$gdProcess = Get-Process -Name "GoogleDriveFS", "googledrivesync" -ErrorAction SilentlyContinue |
             Select-Object -First 1

if (-not $gdProcess) {
    $result.errors += "Google Drive is not running. Install it from drive.google.com/drive/download"
}

# Scan all drive letters A–Z to find where Google Drive is mounted
$driveRoot = $null
foreach ($letter in 65..90 | ForEach-Object { [char]$_ }) {
    $root = "${letter}:\"
    if (-not [System.IO.Directory]::Exists($root)) { continue }

    # Google Drive for Desktop mounts user files under "My Drive"
    $myDrive = [System.IO.Path]::Combine($root, "My Drive")
    if ([System.IO.Directory]::Exists($myDrive)) {
        $driveRoot = $root.TrimEnd('\')
        $driveBase = $myDrive
        break
    }

    # Older Google Drive Backup & Sync mounts directly at root
    $legacyMarker = [System.IO.Path]::Combine($root, "Google Drive")
    if ([System.IO.Directory]::Exists($legacyMarker)) {
        $driveRoot = $root.TrimEnd('\')
        $driveBase = $root
        break
    }
}

if ($driveRoot) {
    $result.drive_found  = $true
    $result.drive_letter = $driveRoot.Substring(0, 1)
    $result.drive_root   = $driveRoot

    # Prefer base_relative from config; fall back to legacy default
    $configPath = [System.IO.Path]::Combine($env:USERPROFILE, ".claude", "engram-sync-config.json")
    if ([System.IO.File]::Exists($configPath)) {
        try {
            $cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
            $resolved = Resolve-DrivePath $cfg.base_relative
            $result.sync_base = if ($resolved) { $resolved } else { [System.IO.Path]::Combine($driveBase, "Engram", "engram-sync") }
        } catch {
            $result.sync_base = [System.IO.Path]::Combine($driveBase, "Engram", "engram-sync")
        }
    } else {
        $result.sync_base = [System.IO.Path]::Combine($driveBase, "Engram", "engram-sync")
    }
} else {
    $result.errors += "Google Drive not found on any drive letter (A: through Z: scanned)."
}

# ── 2. FIND ODOO PROJECT REPOSITORIES ────────────────────────────────────────

# Look in common workspace locations, or use the path passed as argument
$searchRoots = @()
if ($WorkspacePath -and [System.IO.Directory]::Exists($WorkspacePath)) {
    $searchRoots += $WorkspacePath
} else {
    # Prefer workspace_path from config; fallback to env var or SystemDrive pattern
    $cfgWs = $null
    $configPath2 = [System.IO.Path]::Combine($env:USERPROFILE, ".claude", "engram-sync-config.json")
    if ([System.IO.File]::Exists($configPath2)) {
        try { $cfgWs = (Get-Content -LiteralPath $configPath2 -Raw | ConvertFrom-Json).workspace_path } catch {}
    }
    $sysDev = [System.IO.Path]::Combine($env:SystemDrive, "Development", "Odoo", "18")
    $candidates = @(
        $(if ($env:ODOO_WORKSPACE) { $env:ODOO_WORKSPACE } else { $null }),
        $cfgWs,
        $sysDev,
        [System.IO.Path]::Combine($env:SystemDrive, "Development", "Odoo"),
        [System.IO.Path]::Combine($env:USERPROFILE, "Projects"),
        [System.IO.Path]::Combine($env:USERPROFILE, "Development")
    ) | Where-Object { $_ }
    foreach ($c in $candidates) {
        if ([System.IO.Directory]::Exists($c)) { $searchRoots += $c; break }
    }
}

$odooProjects = @()
foreach ($root in $searchRoots) {
    # An Odoo project repo has: a .git folder + at least one __manifest__.py inside
    foreach ($dir in [System.IO.Directory]::GetDirectories($root)) {
        $gitDir = [System.IO.Path]::Combine($dir, ".git")
        if (-not [System.IO.Directory]::Exists($gitDir)) { continue }

        $manifests = [System.IO.Directory]::GetFiles(
            $dir, "__manifest__.py", [System.IO.SearchOption]::AllDirectories)
        if ($manifests.Count -eq 0) { continue }

        $projectName = [System.IO.Path]::GetFileName($dir)
        $odooProjects += $projectName

        # Collect unique git contributors for this project
        $projectContributors = @{}
        try {
            $logOutput = & git -C $dir log --format="%ae`t%an" --all 2>$null
            foreach ($line in ($logOutput | Sort-Object -Unique)) {
                $parts = $line -split "`t", 2
                if ($parts.Count -eq 2 -and $parts[0] -match "@") {
                    $email = $parts[0].Trim()
                    $name  = $parts[1].Trim()
                    if (-not $projectContributors.ContainsKey($email)) {
                        $projectContributors[$email] = $name
                    }
                }
            }
        } catch {}
        $result.contributors[$projectName] = $projectContributors
    }
}
$result.odoo_projects = $odooProjects

# ── OUTPUT JSON ───────────────────────────────────────────────────────────────
$result | ConvertTo-Json -Depth 5
