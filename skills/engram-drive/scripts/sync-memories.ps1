# sync-memories.ps1
# Exports your engram memories to your Google Drive folder, then imports
# teammates' memories from their folders — for every project in config.
# Config (~/.claude/engram-sync-config.json) is created by /engram-drive setup.

$configPath = [System.IO.Path]::Combine($env:USERPROFILE, ".claude", "engram-sync-config.json")

if (-not [System.IO.File]::Exists($configPath)) {
    Write-Warning "Config not found at $configPath. Run /engram-drive setup to create it."
    exit 1
}

$config = Get-Content -Raw $configPath | ConvertFrom-Json

$owner    = $config.owner
$base     = $config.base
$projects = $config.projects
$team     = $config.team | ForEach-Object { $_.name }

if (-not [System.IO.Directory]::Exists($base)) {
    Write-Warning "Google Drive is not mounted or base path '$base' does not exist."
    exit 0
}

if (-not (Get-Command engram -ErrorAction SilentlyContinue)) {
    Write-Warning "engram not found in PATH. Install it with: claude plugin install engram"
    exit 0
}

# Fall back to auto-discovery if config has no explicit project list
if (-not $projects -or $projects.Count -eq 0) {
    $projects = [System.IO.Directory]::GetDirectories($base) |
        ForEach-Object { [System.IO.Path]::GetFileName($_) } |
        Where-Object { $_ -notmatch '^\.' }
}

foreach ($project in $projects) {
    $projectPath = [System.IO.Path]::Combine($base, $project)
    if (-not [System.IO.Directory]::Exists($projectPath)) { continue }

    # EXPORT — write only to your own subfolder
    $ownerDir = [System.IO.Path]::Combine($projectPath, $owner)
    if ([System.IO.Directory]::Exists($ownerDir)) {
        Push-Location -LiteralPath $ownerDir
        try { engram sync --project $project 2>$null }
        finally { Pop-Location }
    }

    # Discover teammates from the project folder structure
    $teammates = [System.IO.Directory]::GetDirectories($projectPath) |
        ForEach-Object { [System.IO.Path]::GetFileName($_) } |
        Where-Object { $_ -ne $owner -and $_ -notmatch '^\.' }

    # IMPORT — read from each teammate who has already synced
    foreach ($tm in $teammates) {
        $tmDir    = [System.IO.Path]::Combine($projectPath, $tm)
        $manifest = [System.IO.Path]::Combine($tmDir, ".engram", "manifest.json")
        if ([System.IO.File]::Exists($manifest)) {
            Push-Location -LiteralPath $tmDir
            try { engram sync --import --project $project 2>$null }
            finally { Pop-Location }
        }
    }
}
