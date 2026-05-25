# install.ps1
# Installs odoo-ai skills, detects Odoo version, clones Community source,
# and configures Enterprise path.
# Run once per machine: powershell -File install.ps1

$ErrorActionPreference = "Continue"

$skillsSource = [System.IO.Path]::Combine($PSScriptRoot, "skills")
$skillsDest   = [System.IO.Path]::Combine($env:USERPROFILE, ".claude", "skills")
$configSrc    = [System.IO.Path]::Combine($PSScriptRoot, "config-templates", "engram-sync-config.template.json")
$configDest   = [System.IO.Path]::Combine($env:USERPROFILE, ".claude", "engram-sync-config.json")

Write-Host ""
Write-Host "  odoo-ai installer" -ForegroundColor Magenta
Write-Host "  think > build > grow." -ForegroundColor DarkMagenta
Write-Host ""

# ── 1. CHECK PREREQUISITES ────────────────────────────────────────────────────

$checks = @{ passed = 0; failed = 0 }

function Check($label, $ok, $hint) {
    if ($ok) {
        Write-Host "  [OK] $label" -ForegroundColor Green
        $checks.passed++
    } else {
        Write-Host "  [!!] $label  →  $hint" -ForegroundColor Yellow
        $checks.failed++
    }
}

Write-Host "  Checking prerequisites..." -ForegroundColor Cyan

Check "Claude Code" (Get-Command claude -ErrorAction SilentlyContinue) "Install from https://claude.ai/code"
Check "git"         (Get-Command git    -ErrorAction SilentlyContinue) "Install from https://git-scm.com"
Check "Go (engram)" (Get-Command go     -ErrorAction SilentlyContinue) "Install from https://go.dev/dl/"

$gdRunning = Get-Process -Name "GoogleDriveFS","googledrivesync" -ErrorAction SilentlyContinue
Check "Google Drive" ($null -ne $gdRunning) "Install from https://drive.google.com/drive/download (needed for engram-drive)"

Write-Host ""

# ── AUTO-INSTALL: engram ──────────────────────────────────────────────────────

if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
    Write-Host "  [~~] Go not found — installing via winget..." -ForegroundColor Yellow
    winget install GoLang.Go --accept-source-agreements --accept-package-agreements -e --silent 2>&1 | Out-Null
    $env:PATH += ";$env:USERPROFILE\go\bin;C:\Program Files\Go\bin"
    if (Get-Command go -ErrorAction SilentlyContinue) {
        Write-Host "  [OK] Go installed" -ForegroundColor Green
    } else {
        Write-Host "  [!!] Go installed — restart terminal for PATH to take effect." -ForegroundColor Yellow
    }
} else {
    Write-Host "  [OK] Go $(go version 2>$null | Select-String -Pattern 'go\d+\.\d+' | ForEach-Object { $_.Matches[0].Value })" -ForegroundColor Green
}

if (-not (Get-Command engram -ErrorAction SilentlyContinue)) {
    Write-Host "  [~~] engram not found — installing via claude plugin..." -ForegroundColor Yellow
    & claude plugin install engram 2>&1 | Out-Null
    if (Get-Command engram -ErrorAction SilentlyContinue) {
        Write-Host "  [OK] engram installed" -ForegroundColor Green
    } else {
        Write-Host "  [!!] engram install may need a terminal restart. Run: claude plugin install engram" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [OK] engram" -ForegroundColor Green
}


Write-Host ""

# ── 2. DETECT ODOO VERSION ────────────────────────────────────────────────────

Write-Host "  Detecting Odoo version..." -ForegroundColor Cyan

$detectedVersion = $null

# Scan common project roots for __manifest__.py and read 'version' field
$searchRoots = @(
    [System.IO.Path]::Combine($env:SystemDrive, "Development", "Odoo", "18"),
    [System.IO.Path]::Combine($env:SystemDrive, "Development", "Odoo", "17"),
    [System.IO.Path]::Combine($env:SystemDrive, "Development", "Odoo"),
    "$env:USERPROFILE\Projects",
    "$env:USERPROFILE\Development"
)

foreach ($root in $searchRoots) {
    if (-not [System.IO.Directory]::Exists($root)) { continue }
    $manifests = [System.IO.Directory]::GetFiles($root, "__manifest__.py", [System.IO.SearchOption]::AllDirectories) |
                 Select-Object -First 5
    foreach ($m in $manifests) {
        $content = [System.IO.File]::ReadAllText($m)
        if ($content -match "'version'\s*:\s*'(\d+)\.\d+") {
            $detectedVersion = $Matches[1]
            break
        }
    }
    if ($detectedVersion) { break }
}

if ($detectedVersion) {
    Write-Host "  [~~] Detected Odoo $detectedVersion from existing project manifests" -ForegroundColor DarkGray
} else {
    Write-Host "  [~~] No existing Odoo project found" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "  Which Odoo version do you want to set up?" -ForegroundColor Cyan
Write-Host "  Supported: 14, 15, 16, 17, 18, 19" -ForegroundColor DarkGray
if ($detectedVersion) {
    Write-Host "  (Press Enter to use detected version: $detectedVersion)" -ForegroundColor DarkGray
}

$userInput = Read-Host "  Version"
$userInput = $userInput.Trim()

if ($userInput -eq "" -and $detectedVersion) {
    $odooVersion = $detectedVersion
    Write-Host "  [OK] Using Odoo $odooVersion" -ForegroundColor Green
} elseif ($userInput -match "^\d+$" -and [int]$userInput -ge 14 -and [int]$userInput -le 19) {
    $odooVersion = $userInput
    Write-Host "  [OK] Using Odoo $odooVersion" -ForegroundColor Green
} elseif ($userInput -eq "" -and -not $detectedVersion) {
    Write-Host "  [!!] No version entered and none detected — defaulting to 18." -ForegroundColor Yellow
    $odooVersion = "18"
} else {
    Write-Host "  [!!] '$userInput' is not a supported version (14–19) — defaulting to 18." -ForegroundColor Yellow
    $odooVersion = "18"
}

$odooBase      = "C:\Development\Odoo\$odooVersion"
$communityPath = "$odooBase\community"
$enterprisePath = "$odooBase\enterprise"

Write-Host ""

# ── 3. ODOO COMMUNITY SOURCE ──────────────────────────────────────────────────

Write-Host "  Odoo Community source..." -ForegroundColor Cyan

if ([System.IO.Directory]::Exists($communityPath)) {
    Write-Host "  [OK] Community source already exists: $communityPath" -ForegroundColor Green
} else {
    Write-Host "  [~~] Not found at: $communityPath" -ForegroundColor Yellow
    Write-Host "       Cloning Odoo $odooVersion Community from GitHub (~1.5 GB, shallow clone)..." -ForegroundColor DarkGray
    Write-Host "       This may take a few minutes." -ForegroundColor DarkGray

    [System.IO.Directory]::CreateDirectory($odooBase) | Out-Null

    & git clone --depth 1 --branch "$odooVersion.0" `
        https://github.com/odoo/odoo.git `
        $communityPath

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Community source cloned to: $communityPath" -ForegroundColor Green
    } else {
        Write-Host "  [!!] Clone failed — check your internet connection and try again." -ForegroundColor Red
    }
}

Write-Host ""

# ── 4. ODOO ENTERPRISE SOURCE ─────────────────────────────────────────────────

Write-Host "  Odoo Enterprise source..." -ForegroundColor Cyan

if ([System.IO.Directory]::Exists($enterprisePath)) {
    Write-Host "  [OK] Enterprise source found: $enterprisePath" -ForegroundColor Green
} else {
    Write-Host "  [~~] Enterprise source not found at: $enterprisePath" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "       Enterprise requires access to the Odoo private repository." -ForegroundColor DarkGray
    Write-Host "       (Available to Odoo partners and customers with an active subscription)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "       Option A — Clone it yourself:" -ForegroundColor DarkGray
    Write-Host "         git clone git@github.com:odoo/enterprise.git $enterprisePath" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "       Option B — You already have it elsewhere?" -ForegroundColor DarkGray
    $existingPath = Read-Host "         Enter the path (or press Enter to skip)"

    if ($existingPath.Trim() -ne "") {
        if ([System.IO.Directory]::Exists($existingPath.Trim())) {
            # Create a symlink pointing to existing location
            New-Item -ItemType Junction -Path $enterprisePath -Target $existingPath.Trim() | Out-Null
            Write-Host "  [OK] Linked Enterprise source: $enterprisePath → $($existingPath.Trim())" -ForegroundColor Green
        } else {
            Write-Host "  [!!] Path not found — skipped. Update 'enterprise_path' in your config manually." -ForegroundColor Yellow
            $enterprisePath = $existingPath.Trim()
        }
    } else {
        Write-Host "  [~~] Skipped — Community-only setup." -ForegroundColor DarkGray
        $enterprisePath = ""
    }
}

Write-Host ""

# ── 5. COPY SKILLS ────────────────────────────────────────────────────────────

Write-Host "  Installing skills to: $skillsDest" -ForegroundColor Cyan

[System.IO.Directory]::CreateDirectory($skillsDest) | Out-Null

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

# ── 5b. COPY HOOK SCRIPTS ─────────────────────────────────────────────────────

$scriptsSrc  = [System.IO.Path]::Combine($PSScriptRoot, "scripts")
$scriptsDest = [System.IO.Path]::Combine($env:USERPROFILE, ".claude", "scripts")

Write-Host "  Installing hook scripts to: $scriptsDest" -ForegroundColor Cyan

[System.IO.Directory]::CreateDirectory($scriptsDest) | Out-Null

$hookScripts = [System.IO.Directory]::GetFiles($scriptsSrc)
foreach ($script in $hookScripts) {
    $name = [System.IO.Path]::GetFileName($script)
    $dest = [System.IO.Path]::Combine($scriptsDest, $name)
    Copy-Item -LiteralPath $script -Destination $dest -Force
    Write-Host "  [+] $name" -ForegroundColor Green
}

Write-Host ""

# ── 5c. CONFIGURE HOOKS IN SETTINGS.JSON ─────────────────────────────────────

$settingsPath = [System.IO.Path]::Combine($env:USERPROFILE, ".claude", "settings.json")
$hooksTplPath = [System.IO.Path]::Combine($PSScriptRoot, "config-templates", "settings-hooks.template.json")

Write-Host "  Configuring Claude Code hooks..." -ForegroundColor Cyan

$hooksTpl = Get-Content -Raw -LiteralPath $hooksTplPath | ConvertFrom-Json

if (Test-Path -LiteralPath $settingsPath) {
    $settings = Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json
} else {
    $settings = [PSCustomObject]@{}
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($settingsPath)) | Out-Null
}

if (-not $settings.PSObject.Properties['hooks']) {
    $settings | Add-Member -NotePropertyName 'hooks' -NotePropertyValue ([PSCustomObject]@{})
}

$added = 0
foreach ($event in $hooksTpl.hooks.PSObject.Properties.Name) {
    $tplEntries = $hooksTpl.hooks.$event
    if (-not $settings.hooks.PSObject.Properties[$event]) {
        $settings.hooks | Add-Member -NotePropertyName $event -NotePropertyValue @()
    }
    $existingCommands = @($settings.hooks.$event | ForEach-Object { $_.hooks | ForEach-Object { $_.command } })
    foreach ($entry in $tplEntries) {
        $cmd = $entry.hooks[0].command
        if ($existingCommands -notcontains $cmd) {
            $settings.hooks.$event += $entry
            $added++
        }
    }
}

# additionalDirectories — essential Odoo ecosystem paths only
$essentialDirs = @(
    [System.IO.Path]::Combine($env:USERPROFILE, ".claude"),
    [System.IO.Path]::Combine($env:USERPROFILE, ".ssh")
)
if (-not $settings.PSObject.Properties['permissions']) {
    $settings | Add-Member -NotePropertyName 'permissions' -NotePropertyValue ([PSCustomObject]@{})
}
if (-not $settings.permissions.PSObject.Properties['additionalDirectories']) {
    $settings.permissions | Add-Member -NotePropertyName 'additionalDirectories' -NotePropertyValue @()
}
$addedDirs = 0
foreach ($dir in $essentialDirs) {
    if (-not ($settings.permissions.additionalDirectories | Where-Object { $_ -ieq $dir })) {
        $settings.permissions.additionalDirectories += $dir
        $addedDirs++
    }
}

$settings | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $settingsPath -Encoding UTF8
if ($added -gt 0 -or $addedDirs -gt 0) {
    Write-Host "  [+] $added hook(s) merged, $addedDirs dir(s) added to additionalDirectories" -ForegroundColor Green
} else {
    Write-Host "  [~] Hooks and directories already configured — no changes needed." -ForegroundColor DarkGray
}

Write-Host ""

# ── 5e. PATCH CLAUDE.MD — multi-project Odoo detection ──────────────────────

Write-Host "  Patching CLAUDE.md for multi-project Odoo detection..." -ForegroundColor Cyan

$claudeMdPath = [System.IO.Path]::Combine($env:USERPROFILE, ".claude", "CLAUDE.md")
$oldTrigger   = '**Trigger:** `__manifest__.py` exists in working directory'
$newTrigger   = '**Trigger:** `__manifest__.py` exists in working directory OR in any subdirectory at depth ≤ 2 (workspace multiproyecto Odoo)'

if ([System.IO.File]::Exists($claudeMdPath)) {
    $claudeContent = [System.IO.File]::ReadAllText($claudeMdPath)
    if ($claudeContent -match [regex]::Escape($oldTrigger)) {
        $claudeContent = $claudeContent.Replace($oldTrigger, $newTrigger)
        [System.IO.File]::WriteAllText($claudeMdPath, $claudeContent, [System.Text.Encoding]::UTF8)
        Write-Host "  [+] CLAUDE.md: multi-project detection activado" -ForegroundColor Green
    } elseif ($claudeContent -match [regex]::Escape($newTrigger)) {
        Write-Host "  [~] CLAUDE.md: ya tiene multi-project detection — sin cambios" -ForegroundColor DarkGray
    } else {
        Write-Host "  [~~] CLAUDE.md: trigger line no encontrada — actualizar manualmente" -ForegroundColor Yellow
        Write-Host "       Buscar: '__manifest__.py exists in working directory'" -ForegroundColor DarkGray
        Write-Host "       Reemplazar con: '$newTrigger'" -ForegroundColor DarkGray
    }
} else {
    Write-Host "  [~~] CLAUDE.md no encontrado en ~/.claude/ — sin cambios" -ForegroundColor Yellow
}

Write-Host ""

# ── 5d. DETECT GOOGLE DRIVE ──────────────────────────────────────────────────

Write-Host "  Detecting Google Drive..." -ForegroundColor Cyan

$detectedDriveLetter = ""
foreach ($letter in 65..90 | ForEach-Object { [char]$_ }) {
    $myDrive = "${letter}:\My Drive"
    $legacyDrive = "${letter}:\Google Drive"
    if ([System.IO.Directory]::Exists($myDrive) -or [System.IO.Directory]::Exists($legacyDrive)) {
        $detectedDriveLetter = "${letter}:"
        Write-Host "  [OK] Google Drive found at ${letter}:" -ForegroundColor Green
        break
    }
}

if (-not $detectedDriveLetter) {
    Write-Host "  [~~] Google Drive not detected — install Google Drive and re-run, or set base_relative manually after install." -ForegroundColor Yellow
}

Write-Host ""

# ── 6. WRITE CONFIG ───────────────────────────────────────────────────────────

Write-Host "  Engram sync configuration..." -ForegroundColor Cyan

if (-not [System.IO.File]::Exists($configDest)) {
    $template = Get-Content -Raw $configSrc | ConvertFrom-Json

    # Ask for owner name (used as personal subfolder in Drive sync)
    Write-Host ""
    Write-Host "  Your first name (used as your subfolder in the shared Drive sync):" -ForegroundColor Cyan
    Write-Host "  Example: Geraldo, Rachel, Percy" -ForegroundColor DarkGray
    $ownerInput = Read-Host "  Name"
    $template.owner = if ($ownerInput.Trim() -ne "") { $ownerInput.Trim() } else { "YourFirstName" }

    # Ask for base_relative (path inside My Drive to the shared engram-sync folder)
    Write-Host ""
    Write-Host "  Path to the shared engram-sync folder inside your Google Drive 'My Drive'." -ForegroundColor Cyan
    Write-Host "  Ask your team lead for the folder path, then add it as a shortcut in your Drive." -ForegroundColor DarkGray
    Write-Host "  Example: Engram/engram-sync" -ForegroundColor DarkGray
    Write-Host "  Example: [1] Geraldo/Projects/engram-sync" -ForegroundColor DarkGray
    Write-Host "  (Press Enter to use default: Engram/engram-sync)" -ForegroundColor DarkGray
    $baseInput = Read-Host "  Drive path"
    $baseRaw = if ($baseInput.Trim() -ne "") { $baseInput.Trim() } else { "Engram\engram-sync" }
    $template.base_relative = $baseRaw.Replace("/", "\")

    # Inject workspace_path
    $template.workspace_path = $odooBase

    $template | ConvertTo-Json -Depth 5 | Set-Content -Path $configDest -Encoding UTF8

    Write-Host "  [+] Config created at: $configDest" -ForegroundColor Green
    Write-Host "      Update 'team_roster' with your team — then run /engram-drive setup." -ForegroundColor DarkGray
} else {
    Write-Host "  [~] Config already exists — skipped: $configDest" -ForegroundColor DarkGray
}

Write-Host ""

# ── 7. NEXT STEPS ─────────────────────────────────────────────────────────────

Write-Host "  Installation complete." -ForegroundColor Magenta
Write-Host ""
Write-Host "  Odoo $odooVersion paths:" -ForegroundColor Cyan
Write-Host "    Community:  $communityPath"
if ($enterprisePath) {
    Write-Host "    Enterprise: $enterprisePath"
}
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Cyan
Write-Host "  1. Edit $configDest — set your 'owner' and 'team_roster'"
Write-Host "  2. Open your AI agent in your Odoo project directory"
Write-Host "  3. Run: /engram-drive setup            → configure team memory sync"
Write-Host "  3. Or:  new-project.ps1 -ProjectName X → onboard a new project directly"
Write-Host "  4. Run: /sdd-init                      → initialize Spec-Driven Development"
Write-Host ""
Write-Host "  Documentation: https://github.com/Geraldow/odoo-ai" -ForegroundColor DarkGray
Write-Host ""
