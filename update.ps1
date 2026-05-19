# update.ps1
# Pulls the latest version of each external plugin from its original GitHub repo.
# Run from the odoo-ai directory: powershell -File update.ps1
#
# External plugins managed here:
#   ahmed-lakosha/odoo-plugins
#   maingocdoan1809/odoo-claude-skills
#   PeterUrban111/odoo-claude-skills
#   unclecatvn/agent-skills

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "  odoo-ai updater" -ForegroundColor Magenta
Write-Host "  Pulling latest plugin versions from upstream." -ForegroundColor DarkGray
Write-Host ""

# ── PREREQUISITES ─────────────────────────────────────────────────────────────

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "  [!!] git not found — install from https://git-scm.com" -ForegroundColor Red
    exit 1
}

$pluginsBase = [System.IO.Path]::Combine($PSScriptRoot, "skills", "odoo-development", "plugins")

if (-not [System.IO.Directory]::Exists($pluginsBase)) {
    Write-Host "  [!!] plugins directory not found: $pluginsBase" -ForegroundColor Red
    exit 1
}

# ── PLUGIN REGISTRY ───────────────────────────────────────────────────────────

$plugins = @(
    @{
        name   = "odoo-development-ahmedlakos"
        repo   = "https://github.com/ahmed-lakosha/odoo-plugins.git"
        branch = "main"
    },
    @{
        name   = "odoo-development-maingocdoan"
        repo   = "https://github.com/maingocdoan1809/odoo-claude-skills.git"
        branch = "main"
    },
    @{
        name   = "odoo-development-peterurban"
        repo   = "https://github.com/PeterUrban111/odoo-claude-skills.git"
        branch = "main"
    },
    @{
        name   = "odoo-development-unclecatvn"
        repo   = "https://github.com/unclecatvn/agent-skills.git"
        branch = "main"
    }
)

# ── UPDATE LOOP ───────────────────────────────────────────────────────────────

$updated = 0
$failed  = 0

foreach ($plugin in $plugins) {
    $dest = [System.IO.Path]::Combine($pluginsBase, $plugin.name)

    Write-Host "  Updating $($plugin.name)..." -ForegroundColor Cyan

    # Clone fresh into a temp folder, then swap
    $tmp = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "odoo-ai-update-$($plugin.name)")

    if ([System.IO.Directory]::Exists($tmp)) {
        [System.IO.Directory]::Delete($tmp, $true)
    }

    & git clone --depth 1 --branch $plugin.branch $plugin.repo $tmp 2>&1 | Out-Null

    if ($LASTEXITCODE -ne 0) {
        # Try without --branch in case default branch name differs
        & git clone --depth 1 $plugin.repo $tmp 2>&1 | Out-Null
    }

    if ($LASTEXITCODE -eq 0) {
        # Remove embedded .git so we don't re-create a gitlink
        $innerGit = [System.IO.Path]::Combine($tmp, ".git")
        if ([System.IO.Directory]::Exists($innerGit)) {
            [System.IO.Directory]::Delete($innerGit, $true)
        }

        # Swap: remove old, move new in
        if ([System.IO.Directory]::Exists($dest)) {
            [System.IO.Directory]::Delete($dest, $true)
        }
        [System.IO.Directory]::Move($tmp, $dest)

        Write-Host "  [OK] $($plugin.name)" -ForegroundColor Green
        $updated++
    } else {
        Write-Host "  [!!] Failed to clone $($plugin.repo)" -ForegroundColor Red
        Write-Host "       Check your internet connection or the repo URL." -ForegroundColor DarkGray
        if ([System.IO.Directory]::Exists($tmp)) {
            [System.IO.Directory]::Delete($tmp, $true)
        }
        $failed++
    }
}

# ── SUMMARY ───────────────────────────────────────────────────────────────────

Write-Host ""
if ($failed -eq 0) {
    Write-Host "  $updated plugin(s) updated successfully." -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  Next: copy updated plugins to your skills directory." -ForegroundColor Cyan
    Write-Host "  Run install.ps1 again, or copy manually:" -ForegroundColor DarkGray
    Write-Host "    Copy-Item -Recurse -Force skills\odoo-development\plugins\* ``" -ForegroundColor DarkGray
    Write-Host "      `$env:USERPROFILE\.claude\skills\odoo-development\plugins\" -ForegroundColor DarkGray
} else {
    Write-Host "  $updated updated, $failed failed." -ForegroundColor Yellow
}
Write-Host ""
