# new-project.ps1
# Onboard a new project into engram-sync: creates Drive folders, project.json,
# SECURITY.md, and optionally registers the repo with codesearch.
#
# Usage:
#   new-project.ps1 -ProjectName tortas-gaby
#   new-project.ps1 -ProjectName tortas-gaby -Type odoo -Members Geraldo,Rachel
#   new-project.ps1 -ProjectName tortas-gaby -RepoPath C:\Development\Odoo\18\tortas-gaby

param(
    [Parameter(Mandatory)][string]$ProjectName,
    [ValidateSet("odoo","code","general")][string]$Type = "odoo",
    [string]$Members  = "",
    [string]$RepoPath = ""
)

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

# ── LOAD SHARED UTILITIES ─────────────────────────────────────────────────────

$detectScript = [System.IO.Path]::Combine(
    $PSScriptRoot, "detect-environment.ps1")
. $detectScript -RunDetection:$false

# ── LOAD MASTER CONFIG ────────────────────────────────────────────────────────

$configPath = [System.IO.Path]::Combine($env:USERPROFILE, ".claude", "engram-sync-config.json")
if (-not (Test-Path -LiteralPath $configPath)) {
    Write-Error "Master config not found: $configPath"
    exit 1
}

$config     = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$owner      = $config.owner
$teamRoster = $config.team_roster
$defaults   = $config.defaults

# ── RESOLVE DRIVE PATH ────────────────────────────────────────────────────────

$base = Resolve-DrivePath $config.base_relative
if (-not $base) {
    Write-Error "Google Drive not found. Mount Drive and retry."
    exit 1
}

# ── VALIDATE + RESOLVE MEMBERS ────────────────────────────────────────────────

$rosterNames = $teamRoster | ForEach-Object { $_.name }

if ($Members) {
    $requestedNames = $Members -split "," | ForEach-Object { $_.Trim() }
    $invalid = $requestedNames | Where-Object { $_ -notin $rosterNames }
    if ($invalid) {
        Write-Error "Members not in team_roster: $($invalid -join ', '). Available: $($rosterNames -join ', ')"
        exit 1
    }
    $activeMembers = $teamRoster | Where-Object { $_.name -in $requestedNames }
} else {
    $activeMembers = $teamRoster
}

# ── CREATE DRIVE FOLDERS ──────────────────────────────────────────────────────

$projectBase = [System.IO.Path]::Combine($base, $ProjectName)
$created     = @()

foreach ($member in $activeMembers) {
    $memberDir = [System.IO.Path]::Combine($projectBase, $member.name)
    if (-not (Test-Path -LiteralPath $memberDir)) {
        [System.IO.Directory]::CreateDirectory($memberDir) | Out-Null
        $created += $member.name
    }
}

Write-Host "Folders: $projectBase"
Write-Host "  Created: $($created -join ', ')"

# ── GENERATE project.json ─────────────────────────────────────────────────────

$projectJsonPath = [System.IO.Path]::Combine($projectBase, "project.json")

$membersArray = $activeMembers | ForEach-Object {
    [pscustomobject]@{
        name  = $_.name
        email = $_.email
        role  = $_.role
    }
}

$codesearchEnabled = if ($null -ne $defaults.codesearch) { $defaults.codesearch } else { $false }

$projectData = [pscustomobject]@{
    project           = $ProjectName
    type              = $Type
    created           = (Get-Date -Format "yyyy-MM-dd")
    members           = $membersArray
    restricted_topics = @()
    auto_sync         = $true
    codesearch        = $codesearchEnabled
    notes             = ""
}

$projectData | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $projectJsonPath -Encoding UTF8
Write-Host "project.json: written"

# ── GENERATE SECURITY.md ──────────────────────────────────────────────────────

$securityPath = [System.IO.Path]::Combine($projectBase, "SECURITY.md")

$membersTable = ($activeMembers | ForEach-Object {
    "| $($_.name) | $($_.role) | $($_.email) |"
}) -join "`n"

$restrictedTopics = if ($projectData.restricted_topics.Count -gt 0) {
    ($projectData.restricted_topics | ForEach-Object { "- $_" }) -join "`n"
} else {
    "_None — all topics sync to all members._"
}

$securityContent = @"
# SECURITY — $ProjectName

Generated: $(Get-Date -Format "yyyy-MM-dd")
Type: $Type

## Team Members

| Name | Role | Email |
|------|------|-------|
$membersTable

## Sync Policy

- **auto_sync**: true
- **codesearch**: $codesearchEnabled

## Restricted Topics

Topics in this list are excluded from shared sync (stay local only):

$restrictedTopics

## Access Control

This project's Drive folder should be shared with the emails listed above.
Right-click ``engram-sync/$ProjectName/`` in Google Drive → Share → add each email as **Editor**.

## Notes

_No additional notes._
"@

$securityContent | Set-Content -LiteralPath $securityPath -Encoding UTF8
Write-Host "SECURITY.md: written"

# ── CODESEARCH INTEGRATION ────────────────────────────────────────────────────

if ($RepoPath) {
    if (-not (Test-Path -LiteralPath $RepoPath)) {
        Write-Warning "RepoPath not found: $RepoPath — skipping codesearch registration"
    } elseif (-not (Get-Command codesearch -ErrorAction SilentlyContinue)) {
        Write-Warning "codesearch not in PATH — skipping registration"
    } else {
        Write-Host "codesearch: registering $ProjectName..."
        & codesearch index add --alias $ProjectName --store "$RepoPath\.codesearch.db" $RepoPath
        Write-Host "codesearch: registered"
    }
}

# ── SUMMARY ───────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "=== new-project complete ==="
Write-Host "  Project  : $ProjectName"
Write-Host "  Type     : $Type"
Write-Host "  Members  : $($activeMembers.name -join ', ')"
Write-Host "  Drive    : $projectBase"
Write-Host "  Next     : Share the folder with teammates in Google Drive"
