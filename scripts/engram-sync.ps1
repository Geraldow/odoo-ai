# engram-sync.ps1
# Smart engram sync — detects workspace mode and syncs accordingly.
# Detects whether the agent was opened in a single-project folder or a
# multi-project workspace root, then syncs only what's relevant.
#
# Single-project:  Work/aeca/   → sync aeca only
# Multi-project:   Work/        → sync all projects in config
#
# Called automatically by the Claude Stop hook (global settings.json).

$configPath = [System.IO.Path]::Combine($env:USERPROFILE, ".claude", "engram-sync-config.json")
if (-not (Test-Path -LiteralPath $configPath)) { exit 0 }

$config   = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$base     = $config.base
$owner    = $config.owner
$projects = $config.projects

# Guards
if (-not (Test-Path -LiteralPath $base)) { exit 0 }
if (-not (Get-Command engram -ErrorAction SilentlyContinue)) { exit 0 }
if (-not $projects -or $projects.Count -eq 0) { exit 0 }

# ── DETECT MODE ───────────────────────────────────────────────────────────────

$cwd      = (Get-Location).Path
$cwdLeaf  = Split-Path $cwd -Leaf

$isKnownProject = $projects -contains $cwdLeaf

if ($isKnownProject) {
    # Single-project: CWD folder name matches a known project (e.g. Work/aeca/)
    $activeProjects = @($cwdLeaf)
} else {
    # Multi-project or root workspace: sync all projects that have a Drive folder
    $activeProjects = $projects | Where-Object {
        Test-Path -LiteralPath ([System.IO.Path]::Combine($base, $_))
    }
}

if (-not $activeProjects -or $activeProjects.Count -eq 0) {
    # Non-Odoo session: notify the user instead of syncing silently
    $msg = @{ systemMessage = "engram-drive: sesión fuera de proyecto Odoo conocido. Ejecuta /engram-drive sync si deseas compartir estas memorias con el equipo." } | ConvertTo-Json -Compress
    Write-Output $msg
    exit 0
}

# ── SYNC ──────────────────────────────────────────────────────────────────────

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

    # IMPORT — read from each teammate who has already synced
    $teammates = [System.IO.Directory]::GetDirectories($projectPath) |
        ForEach-Object { Split-Path $_ -Leaf } |
        Where-Object { $_ -ne $owner -and $_ -notmatch '^\.' }

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
