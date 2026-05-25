# update.ps1
# Updates the odoo-ai skill to the latest version from the official repository.
# Run from the odoo-ai directory: powershell -File update.ps1
#
# Note: Community plugins (ahmedlakos, fhidalgo, maingocdoan, peterurban, unclecatvn)
# were archived in v3.0. The skill now ships a self-contained knowledge base.
# Archived plugins remain at: skills/archived/

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "  odoo-ai updater" -ForegroundColor Magenta
Write-Host "  Pulling latest version from upstream." -ForegroundColor DarkGray
Write-Host ""

# ── PREREQUISITES ─────────────────────────────────────────────────────────────

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "  [!!] git not found — install from https://git-scm.com" -ForegroundColor Red
    exit 1
}

# ── PULL LATEST ───────────────────────────────────────────────────────────────

$repoRoot = $PSScriptRoot

Write-Host "  Checking for updates..." -ForegroundColor Cyan

& git -C $repoRoot fetch origin 2>&1 | Out-Null

$local  = & git -C $repoRoot rev-parse HEAD
$remote = & git -C $repoRoot rev-parse origin/main 2>&1

if ($local -eq $remote) {
    Write-Host "  [~] Already up to date." -ForegroundColor DarkGray
} else {
    Write-Host "  [~~] Updates available — pulling..." -ForegroundColor Yellow
    & git -C $repoRoot pull origin main

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] odoo-ai updated to latest version." -ForegroundColor Green
    } else {
        Write-Host "  [!!] Pull failed — check for local changes or merge conflicts." -ForegroundColor Red
        exit 1
    }
}

# ── REINSTALL SKILLS ──────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  Reinstalling skills..." -ForegroundColor Cyan

$skillsSource = [System.IO.Path]::Combine($repoRoot, "skills")
$skillsDest   = [System.IO.Path]::Combine($env:USERPROFILE, ".claude", "skills")

$skills = [System.IO.Directory]::GetDirectories($skillsSource) |
          Where-Object { [System.IO.Path]::GetFileName($_) -ne "archived" }

foreach ($skill in $skills) {
    $name = [System.IO.Path]::GetFileName($skill)
    $dest = [System.IO.Path]::Combine($skillsDest, $name)

    if ([System.IO.Directory]::Exists($dest)) {
        [System.IO.Directory]::Delete($dest, $true)
    }

    Copy-Item -LiteralPath $skill -Destination $dest -Recurse
    Write-Host "  [+] $name" -ForegroundColor Green
}

Write-Host ""
Write-Host "  Update complete." -ForegroundColor Magenta
Write-Host ""
