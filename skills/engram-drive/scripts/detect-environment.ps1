# detect-environment.ps1
# Scans the system for: Google Drive mount point, Odoo project repos,
# and git contributors per project.
# Output: JSON to stdout — consumed by /engram-drive setup

param(
    [string]$WorkspacePath = ""
)

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
    $result.sync_base    = [System.IO.Path]::Combine($driveBase, "Engram", "engram-sync")
} else {
    $result.errors += "Google Drive not found on any drive letter (A: through Z: scanned)."
}

# ── 2. FIND ODOO PROJECT REPOSITORIES ────────────────────────────────────────

# Look in common workspace locations, or use the path passed as argument
$searchRoots = @()
if ($WorkspacePath -and [System.IO.Directory]::Exists($WorkspacePath)) {
    $searchRoots += $WorkspacePath
} else {
    $candidates = @(
        "C:\Development\Odoo\Community\18\Projects\Work",
        "C:\Development\Odoo",
        "$env:USERPROFILE\Projects",
        "$env:USERPROFILE\Development"
    )
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
