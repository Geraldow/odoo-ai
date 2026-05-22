# odoo-ai-update-check.ps1
# Checks if origin/main has new commits not yet applied locally.
# Runs via SessionStart hook — silent on success, notifies when behind.

$repoPath = "C:\Development\odoo-ai"

if (-not (Test-Path -LiteralPath $repoPath)) { exit 0 }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { exit 0 }

# Fetch origin/main silently
git -C $repoPath fetch origin main --quiet 2>$null
if ($LASTEXITCODE -ne 0) { exit 0 }

# Count commits on origin/main not in local main
$behind = git -C $repoPath rev-list "main..origin/main" --count 2>$null
if (-not $behind -or $behind -eq "0") { exit 0 }

# Get latest tag on origin/main
$latestTag = git -C $repoPath describe --tags --abbrev=0 origin/main 2>$null
$tagLabel  = if ($latestTag) { " ($latestTag)" } else { "" }

# Get last 3 commit subjects on origin/main
$commits = git -C $repoPath log "main..origin/main" --oneline --no-decorate 2>$null |
    Select-Object -First 3 |
    ForEach-Object { "  • $_" }
$commitList = $commits -join "`n"

$msg = "odoo-ai tiene $behind commit(s) nuevos en main$tagLabel.`n$commitList`nPara actualizar:`n  git -C C:\Development\odoo-ai checkout main && git pull origin main`n  pwsh C:\Development\odoo-ai\install.ps1"

@{ systemMessage = $msg } | ConvertTo-Json -Compress
