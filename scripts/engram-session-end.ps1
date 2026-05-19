# engram-session-end.ps1
# Export your memories to Drive + import teammates' latest memories at session end.
# Detects single-project vs multi-project workspace automatically.
#
# Single-project:  Work/conservial/  → sync conservial only
# Multi-project:   Work/             → sync all projects in config
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

$cwd     = (Get-Location).Path
$cwdLeaf = Split-Path $cwd -Leaf

$isKnownProject = $projects -contains $cwdLeaf

if ($isKnownProject) {
    $activeProjects = @($cwdLeaf)
} else {
    $activeProjects = $projects | Where-Object {
        Test-Path -LiteralPath ([System.IO.Path]::Combine($base, $_))
    }
}

if (-not $activeProjects -or $activeProjects.Count -eq 0) {
    # Non-Odoo session: notify instead of syncing silently
    $msg = @{ systemMessage = "engram-drive: sesión fuera de proyecto Odoo conocido. Ejecuta /engram-drive sync si deseas compartir estas memorias con el equipo." } | ConvertTo-Json -Compress
    Write-Output $msg
    exit 0
}

# ── EXPORT + IMPORT ───────────────────────────────────────────────────────────

foreach ($project in $activeProjects) {
    $projectPath = [System.IO.Path]::Combine($base, $project)
    if (-not (Test-Path -LiteralPath $projectPath)) { continue }

    # EXPORT — write only to your own subfolder (always first)
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
