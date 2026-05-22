# engram-session-start.ps1
# Import-only sync at session start — pulls teammates' latest memories.
# No export here (nothing new yet). Export happens at Stop.
#
# Runs via the Claude Code SessionStart hook (global settings.json).

$configPath = [System.IO.Path]::Combine($env:USERPROFILE, ".claude", "engram-sync-config.json")
if (-not (Test-Path -LiteralPath $configPath)) { exit 0 }

$config   = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$owner    = $config.owner
$projects = $config.projects

# Resolve Drive path the same way session-end does — via detect-environment.ps1
$detectScript = [System.IO.Path]::Combine(
    $env:USERPROFILE, ".claude", "skills", "engram-drive", "scripts", "detect-environment.ps1")
if (-not (Test-Path -LiteralPath $detectScript)) { exit 0 }
. $detectScript -RunDetection:$false
$base = Resolve-DrivePath $config.base_relative

# Guards
if (-not $base -or -not (Test-Path -LiteralPath $base)) { exit 0 }
if (-not (Get-Command engram -ErrorAction SilentlyContinue)) { exit 0 }
if (-not $projects -or $projects.Count -eq 0) { exit 0 }

# ── DETECT MODE ───────────────────────────────────────────────────────────────

$cwd     = (Get-Location).Path
$cwdLeaf = Split-Path $cwd -Leaf

$isKnownProject = $projects -contains $cwdLeaf

if ($isKnownProject) {
    $activeProjects = @($cwdLeaf)
} else {
    # Multi-project or non-Odoo workspace — import all known projects from Drive
    $activeProjects = $projects | Where-Object {
        Test-Path -LiteralPath ([System.IO.Path]::Combine($base, $_))
    }
}

if (-not $activeProjects -or $activeProjects.Count -eq 0) { exit 0 }

# ── IMPORT ONLY ───────────────────────────────────────────────────────────────

foreach ($project in $activeProjects) {
    $projectPath = [System.IO.Path]::Combine($base, $project)
    if (-not (Test-Path -LiteralPath $projectPath)) { continue }

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
