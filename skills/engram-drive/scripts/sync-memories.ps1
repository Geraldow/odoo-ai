# sync-memories.ps1
# Smart engram sync — exports your memories to Google Drive and imports
# teammates' memories, scoped correctly per project.
#
# Detects workspace mode automatically:
#   Single-project:  CWD has __manifest__.py + folder name matches a config project
#                    → syncs only that project
#   Multi-project:   CWD is a workspace root containing multiple project folders
#                    → syncs all projects listed in config
#
# Config: ~/.claude/engram-sync-config.json (created by /engram-drive setup)

$configPath = [System.IO.Path]::Combine($env:USERPROFILE, ".claude", "engram-sync-config.json")

if (-not (Test-Path -LiteralPath $configPath)) {
    Write-Warning "Config not found at $configPath. Run /engram-drive setup to create it."
    exit 1
}

$config   = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$owner    = $config.owner
$base     = $config.base
$projects = $config.projects
$team     = $config.team | ForEach-Object { $_.name }

# Guards
if (-not (Test-Path -LiteralPath $base)) {
    Write-Warning "Google Drive not mounted or base path '$base' does not exist."
    exit 0
}

if (-not (Get-Command engram -ErrorAction SilentlyContinue)) {
    Write-Warning "engram not found. Install with: claude plugin install engram"
    exit 0
}

# Fall back to Drive folder discovery if config has no explicit project list
if (-not $projects -or $projects.Count -eq 0) {
    $projects = [System.IO.Directory]::GetDirectories($base) |
        ForEach-Object { Split-Path $_ -Leaf } |
        Where-Object { $_ -notmatch '^\.' }
}

if (-not $projects -or $projects.Count -eq 0) { exit 0 }

# ── DETECT MODE ───────────────────────────────────────────────────────────────

$cwd     = (Get-Location).Path
$cwdLeaf = Split-Path $cwd -Leaf

$hasManifest    = Test-Path -LiteralPath ([System.IO.Path]::Combine($cwd, "__manifest__.py"))
$isKnownProject = $projects -contains $cwdLeaf

if ($hasManifest -and $isKnownProject) {
    # Single-project mode
    $activeProjects = @($cwdLeaf)
} else {
    # Multi-project or root workspace — sync all projects that have a Drive folder
    $activeProjects = $projects | Where-Object {
        Test-Path -LiteralPath ([System.IO.Path]::Combine($base, $_))
    }
}

if (-not $activeProjects -or $activeProjects.Count -eq 0) { exit 0 }

# ── SYNC LOOP ─────────────────────────────────────────────────────────────────

foreach ($project in $activeProjects) {
    $projectPath = [System.IO.Path]::Combine($base, $project)
    if (-not (Test-Path -LiteralPath $projectPath)) { continue }

    # EXPORT — write only to your own subfolder
    $ownerDir = [System.IO.Path]::Combine($projectPath, $owner)
    if (Test-Path -LiteralPath $ownerDir) {
        Push-Location -LiteralPath $ownerDir
        try { engram sync --project $project 2>$null }
        finally { Pop-Location }
    }

    # Discover teammates from the Drive project folder structure
    $teammates = [System.IO.Directory]::GetDirectories($projectPath) |
        ForEach-Object { Split-Path $_ -Leaf } |
        Where-Object { $_ -ne $owner -and $_ -notmatch '^\.' }

    # IMPORT — read from each teammate who has already synced
    foreach ($tm in $teammates) {
        $manifest = [System.IO.Path]::Combine($projectPath, $tm, ".engram", "manifest.json")
        if (Test-Path -LiteralPath $manifest) {
            $tmDir = [System.IO.Path]::Combine($projectPath, $tm)
            Push-Location -LiteralPath $tmDir
            try { engram sync --import --project $project 2>$null }
            finally { Pop-Location }
        }
    }
}
