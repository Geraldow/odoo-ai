#Requires -Version 7.0
<#
.SYNOPSIS
    Verifies that the current git committer is an authorized Alesco contributor.
.PARAMETER ContribFile
    Path to CONTRIBUTING.md. Auto-located if omitted.
.PARAMETER RepoPath
    Path to the git repository. Defaults to current directory.
.OUTPUTS
    Exit 0 — Identity verified
    Exit 1 — Identity not authorized (STOP)
    Exit 3 — Environment error
#>
param(
    [string]$ContribFile = "",
    [string]$RepoPath    = ".",
    [switch]$Verbose
)

Set-StrictMode -Version Latest

. "$PSScriptRoot\Get-OdooConfig.ps1"

# Locate CONTRIBUTING.md
if ([string]::IsNullOrWhiteSpace($ContribFile)) {
    $candidates = @(
        (Join-Path $PSScriptRoot "..\plugins\odoo-development-alesco\CONTRIBUTING.md"),
        (Join-Path $PSScriptRoot "..\knowledge\alesco\contributors.md"),
        "~/.claude/skills/odoo-ai/plugins/odoo-development-alesco/CONTRIBUTING.md"
    )
    foreach ($c in $candidates) {
        $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($c)
        if (Test-Path $resolved) {
            $ContribFile = $resolved
            break
        }
    }
}

if ([string]::IsNullOrWhiteSpace($ContribFile) -or -not (Test-Path $ContribFile)) {
    Write-Host "ERROR: CONTRIBUTING.md not found. Pass -ContribFile explicitly."
    exit 3
}

# Read authorized identities from CONTRIBUTING.md
$contribContent = Get-Content $ContribFile -Raw

# Extract authorized emails
$authorizedEmails = [System.Collections.Generic.List[string]]::new()
$contribContent | Select-String -Pattern '\*\*Email[s]? autorizado[s]?\*\*[:\s]+`([^`]+)`' -AllMatches |
    ForEach-Object { $_.Matches } | ForEach-Object {
        $_.Groups[1].Value -split ',' | ForEach-Object { $authorizedEmails.Add($_.Trim()) }
    }
# Also catch plain email format
$contribContent | Select-String -Pattern '`([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})`' -AllMatches |
    ForEach-Object { $_.Matches } | ForEach-Object {
        $email = $_.Groups[1].Value.Trim()
        if (-not $authorizedEmails.Contains($email)) { $authorizedEmails.Add($email) }
    }

# Extract authorized GitHub logins
$authorizedGitHub = [System.Collections.Generic.List[string]]::new()
$contribContent | Select-String -Pattern '\*\*GitHub\*\*:\s*`([^`]+)`' -AllMatches |
    ForEach-Object { $_.Matches } | ForEach-Object { $authorizedGitHub.Add($_.Groups[1].Value.Trim()) }

# Extract authorized names
$authorizedNames = [System.Collections.Generic.List[string]]::new()
$contribContent | Select-String -Pattern '\*\*Nombre en git\*\*:\s*`([^`]+)`' -AllMatches |
    ForEach-Object { $_.Matches } | ForEach-Object { $authorizedNames.Add($_.Groups[1].Value.Trim()) }

if ($Verbose) {
    Write-Host "Authorized emails:  $($authorizedEmails -join ', ')"
    Write-Host "Authorized GitHub:  $($authorizedGitHub -join ', ')"
    Write-Host "Authorized names:   $($authorizedNames -join ', ')"
    Write-Host ""
}

# Get current committer identity
$gitEmail = git -C $RepoPath config user.email 2>&1
$gitName  = git -C $RepoPath config user.name 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Not a git repository or git config not set."
    exit 3
}

Write-Host ""
Write-Host "Commit Identity Check"
Write-Host "─────────────────────────────────────────"
Write-Host "git user.email: $gitEmail"
Write-Host "git user.name:  $gitName"

if ($cfg.Contributor.Email -and $gitEmail.Trim() -eq $cfg.Contributor.Email.Trim()) {
    Write-Host "✅ Identity verified: $($cfg.Contributor.Name) (config.local.yaml email match)"
    exit 0
}

if ($cfg.Contributor.Name -and $gitName.Trim() -eq $cfg.Contributor.Name.Trim()) {
    Write-Host "✅ Identity verified: $($cfg.Contributor.Name) (config.local.yaml name match)"
    exit 0
}

# Check email match
if ($authorizedEmails -contains $gitEmail.Trim()) {
    $matchedContrib = $contribContent | Select-String -Pattern "(?s)###\s+(.+?)(?=###|\z)" -AllMatches |
        ForEach-Object { $_.Matches } | Where-Object { $_.Value -match [regex]::Escape($gitEmail.Trim()) } |
        Select-Object -First 1
    $name = if ($matchedContrib) { ($matchedContrib.Value | Select-String '###\s+(.+)').Matches[0].Groups[1].Value.Trim() } else { $gitEmail }
    Write-Host "✅ Identity verified: $name (email match)"
    exit 0
}

# Check name match
if ($authorizedNames -contains $gitName.Trim()) {
    Write-Host "✅ Identity verified: $gitName (name match)"
    exit 0
}

# Check GitHub login (optional — only if gh CLI available)
$ghLogin = ""
if (Get-Command gh -ErrorAction SilentlyContinue) {
    $ghResult = gh api user --jq '.login' 2>&1
    if ($LASTEXITCODE -eq 0) {
        $ghLogin = $ghResult.Trim()
        Write-Host "GitHub login:   $ghLogin"
        if ($authorizedGitHub -contains $ghLogin) {
            Write-Host "✅ Identity verified: $ghLogin (GitHub match)"
            exit 0
        }
    } else {
        Write-Host "⚠️  gh CLI available but not authenticated — skipping GitHub check"
    }
} else {
    Write-Host "⚠️  gh CLI not found — skipping GitHub check"
}

Write-Host ""
Write-Host "🚫 STOP: Committer identity not authorized."
Write-Host "   Email: $gitEmail"
Write-Host "   Name:  $gitName"
Write-Host "   See: ~/.claude/skills/odoo-ai/plugins/odoo-development-alesco/CONTRIBUTING.md"
Write-Host ""
exit 1
