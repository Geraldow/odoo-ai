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

$gdRunning = Get-Process -Name "GoogleDriveFS","googledrivesync" -ErrorAction SilentlyContinue
Check "Google Drive" ($null -ne $gdRunning) "Install from https://drive.google.com/drive/download (needed for engram-drive)"

Write-Host ""

# ── AUTO-INSTALL: engram ──────────────────────────────────────────────────────

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

# ── AUTO-INSTALL: codesearch ──────────────────────────────────────────────────

$csExe = [System.IO.Path]::Combine($env:SystemDrive, "Tools", "codesearch", "codesearch.exe")

if (-not (Test-Path -LiteralPath $csExe) -and -not (Get-Command codesearch -ErrorAction SilentlyContinue)) {
    Write-Host "  [~~] codesearch not found — downloading latest release..." -ForegroundColor Yellow
    try {
        $release  = Invoke-RestMethod -Uri "https://api.github.com/repos/flupkede/codesearch/releases/latest"
        $asset    = $release.assets | Where-Object { $_.name -match "windows.*x86_64|x86_64.*windows" } | Select-Object -First 1
        if (-not $asset) { $asset = $release.assets | Where-Object { $_.name -match "\.exe$" } | Select-Object -First 1 }

        if ($asset) {
            $csDir = [System.IO.Path]::GetDirectoryName($csExe)
            [System.IO.Directory]::CreateDirectory($csDir) | Out-Null
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $csExe -UseBasicParsing
            Write-Host "  [OK] codesearch installed: $csExe" -ForegroundColor Green
            Write-Host "  [~~] Add to PATH: $csDir" -ForegroundColor DarkGray
            [System.Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";$csDir", "User")
            $env:PATH += ";$csDir"
        } else {
            Write-Host "  [!!] No Windows binary found in release — install manually: https://github.com/flupkede/codesearch/releases" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  [!!] Download failed: $_" -ForegroundColor Yellow
        Write-Host "       Install manually: https://github.com/flupkede/codesearch/releases" -ForegroundColor DarkGray
    }
} else {
    Write-Host "  [OK] codesearch" -ForegroundColor Green
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

$skills = [System.IO.Directory]::GetDirectories($skillsSource)
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

if ($settings.PSObject.Properties['hooks']) {
    Write-Host "  [~] Hooks already present in settings.json — skipped." -ForegroundColor DarkGray
    Write-Host "      To update manually: config-templates/settings-hooks.template.json" -ForegroundColor DarkGray
} else {
    $settings | Add-Member -NotePropertyName 'hooks' -NotePropertyValue $hooksTpl.hooks
    $settings | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $settingsPath -Encoding UTF8
    Write-Host "  [+] Hooks configured in: $settingsPath" -ForegroundColor Green
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

# ── 5d. DETECT GOOGLE DRIVE BASE PATH ────────────────────────────────────────

Write-Host "  Detecting Google Drive path..." -ForegroundColor Cyan

$detectedDriveBase = ""
foreach ($letter in 65..90 | ForEach-Object { [char]$_ }) {
    $root = "${letter}:\"
    if (-not [System.IO.Directory]::Exists($root)) { continue }

    $myDrive = [System.IO.Path]::Combine($root, "My Drive")
    if ([System.IO.Directory]::Exists($myDrive)) {
        $detectedDriveBase = [System.IO.Path]::Combine($myDrive, "Engram", "engram-sync")
        Write-Host "  [OK] Google Drive found at ${letter}: → $detectedDriveBase" -ForegroundColor Green
        break
    }

    # Legacy Google Backup and Sync
    $legacyRoot = [System.IO.Path]::Combine($root, "Google Drive")
    if ([System.IO.Directory]::Exists($legacyRoot)) {
        $detectedDriveBase = [System.IO.Path]::Combine($legacyRoot, "Engram", "engram-sync")
        Write-Host "  [OK] Google Drive (legacy) found at ${letter}: → $detectedDriveBase" -ForegroundColor Green
        break
    }
}

if (-not $detectedDriveBase) {
    Write-Host "  [~~] Google Drive not detected — set 'base' manually in the config after install." -ForegroundColor Yellow
}

Write-Host ""

# ── 6. WRITE CONFIG ───────────────────────────────────────────────────────────

if (-not [System.IO.File]::Exists($configDest)) {
    $template = Get-Content -Raw $configSrc | ConvertFrom-Json

    # Inject workspace_path (Odoo projects root for this machine)
    $template.workspace_path = $odooBase   # e.g. C:\Development\Odoo\18

    $template | ConvertTo-Json -Depth 5 | Set-Content -Path $configDest -Encoding UTF8

    Write-Host "  [+] Config created at: $configDest" -ForegroundColor Green
    Write-Host "      Edit 'owner' and 'team_roster' — then run /engram-drive setup." -ForegroundColor DarkGray
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
