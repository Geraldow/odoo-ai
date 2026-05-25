#Requires -Version 7.0
<#
.SYNOPSIS
    Installs or uninstalls Odoo project git hooks into a repository.
.DESCRIPTION
    Copies pre-commit, pre-push, commit-msg, and pre-pr hooks from
    ~/.claude/skills/git-hooks/ into the target repo's .git/hooks/ directory.
    Each hook is a PowerShell script that validates identity, ACL, branch safety,
    and commit message format. No Claude or MCP calls — pure PowerShell only.
.PARAMETER RepoPath
    Path to the git repository. Defaults to current directory.
.PARAMETER Uninstall
    Remove installed hooks instead of installing them.
.PARAMETER DryRun
    Show what would be installed without making changes.
.EXAMPLE
    pwsh ~/.claude/skills/odoo-ai/scripts/git-hooks/install-hooks.ps1 -RepoPath .
    pwsh ~/.claude/skills/odoo-ai/scripts/git-hooks/install-hooks.ps1 -RepoPath . -Uninstall
    pwsh ~/.claude/skills/git-hooks/install-hooks.ps1 -RepoPath C:\Dev\myrepo -DryRun
.OUTPUTS
    Exit 0 — Success
    Exit 1 — Error (not a git repo, hooks source missing)
    Exit 2 — Dry run complete (no changes made)
#>
param(
    [string]$RepoPath  = ".",
    [switch]$Uninstall,
    [switch]$DryRun
)

Set-StrictMode -Version Latest

# ─── Resolve paths ───────────────────────────────────────────────────────────
$repoPath = Resolve-Path $RepoPath -ErrorAction Stop
$gitDir   = Join-Path $repoPath ".git"
$hooksDir = Join-Path $gitDir "hooks"
$sourceDir = $PSScriptRoot   # ~/.claude/skills/git-hooks/

Write-Host ""
Write-Host "Git Hooks — $(if ($Uninstall) { 'Uninstall' } elseif ($DryRun) { 'Dry Run' } else { 'Install' })"
Write-Host "─────────────────────────────────────────"
Write-Host "Repo:    $repoPath"
Write-Host "Hooks:   $hooksDir"
Write-Host ""

# ─── Validate ────────────────────────────────────────────────────────────────
if (-not (Test-Path $gitDir)) {
    Write-Host "ERROR: Not a git repository: $repoPath"
    exit 1
}

if (-not $Uninstall -and -not (Test-Path $sourceDir)) {
    Write-Host "ERROR: Hooks source directory not found: $sourceDir"
    exit 1
}

New-Item -ItemType Directory -Force -Path $hooksDir | Out-Null

# ─── Hook list ───────────────────────────────────────────────────────────────
$hooks = @("pre-commit", "pre-push", "commit-msg")

# ─── Uninstall ───────────────────────────────────────────────────────────────
if ($Uninstall) {
    foreach ($hook in $hooks) {
        $target = Join-Path $hooksDir $hook
        if (Test-Path $target) {
            if ($DryRun) {
                Write-Host "  [DRY RUN] Would remove: $target"
            } else {
                Remove-Item $target -Force
                Write-Host "  ✅ Removed: $hook"
            }
        } else {
            Write-Host "  ℹ️  Not installed: $hook"
        }
    }
    Write-Host ""
    Write-Host "$(if ($DryRun) { '[DRY RUN] ' })Uninstall complete."
    exit $(if ($DryRun) { 2 } else { 0 })
}

# ─── Install ─────────────────────────────────────────────────────────────────
$installed = 0
$skipped   = 0

foreach ($hook in $hooks) {
    $source = Join-Path $sourceDir $hook
    $target = Join-Path $hooksDir $hook

    if (-not (Test-Path $source)) {
        Write-Host "  ⚠️  Source not found, skipping: $hook"
        $skipped++
        continue
    }

    if (Test-Path $target) {
        # Check if already our hook
        $existing = Get-Content $target -Raw -ErrorAction SilentlyContinue
        if ($existing -match '# Odoo project git hook') {
            Write-Host "  🔄 Updated: $hook"
        } else {
            # Backup existing non-managed hook
            $backup = "$target.bak"
            if ($DryRun) {
                Write-Host "  [DRY RUN] Would backup existing $hook → $hook.bak"
            } else {
                Copy-Item $target $backup -Force
                Write-Host "  💾 Backed up existing: $hook → $hook.bak"
            }
        }
    }

    if ($DryRun) {
        Write-Host "  [DRY RUN] Would install: $hook"
    } else {
        Copy-Item $source $target -Force
        # On Unix-like systems via Git Bash, ensure executable bit (no-op on Windows)
        try {
            & git -C $repoPath config core.hooksPath hooks 2>&1 | Out-Null
        } catch {}
        Write-Host "  ✅ Installed: $hook"
        $installed++
    }
}

Write-Host ""
if ($DryRun) {
    Write-Host "[DRY RUN] No changes made. Remove -DryRun to apply."
    exit 2
} else {
    Write-Host "Installed: $installed hook(s) — Skipped: $skipped"
    Write-Host ""
    Write-Host "Hooks active:"
    $hooks | ForEach-Object { Write-Host "  · $_" }
    Write-Host ""
    Write-Host "To uninstall: pwsh $PSCommandPath -RepoPath '$repoPath' -Uninstall"
    exit 0
}
