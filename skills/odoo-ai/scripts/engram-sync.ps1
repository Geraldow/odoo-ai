#Requires -Version 7.0
<#
.SYNOPSIS
    Synchronizes Engram memory observations with Google Drive for cross-device persistence.

.DESCRIPTION
    Manages JSON files at G:\My Drive\Engram\engram-sync\{project}\ organized as:
      decisions/ discoveries/ bugs/ architecture/ sessions/

    Export: writes observation JSON files from a pipeline or input file to Drive.
    Import: reads Drive JSON files and prints them to stdout for Claude Code to process.
    The actual Engram MCP calls (mem_save / mem_search) are handled by Claude Code —
    this script manages only the Drive file I/O layer.

.PARAMETER Direction
    import | export | both
.PARAMETER Project
    Project name (e.g. aeca, conservial). Required.
.PARAMETER DriveBase
    Root path on Google Drive. Default: G:\My Drive\Engram\engram-sync
.PARAMETER InputFile
    For export: path to a JSON file containing observation(s) to write to Drive.
    If omitted, reads from stdin (piped JSON).
.OUTPUTS
    Exit 0 — Sync completed successfully
    Exit 1 — Error during sync
    Exit 2 — Drive path unavailable (non-fatal warning)
    Exit 3 — Invalid parameters
#>
param(
    [Parameter(Mandatory)][ValidateSet("import","export","both")][string]$Direction,
    [Parameter(Mandatory)][string]$Project,
    [string]$DriveBase  = "G:\My Drive\Engram\engram-sync",
    [string]$InputFile  = ""
)

Set-StrictMode -Version Latest

$projectPath = Join-Path $DriveBase $Project
$subdirs     = @("decisions", "discoveries", "bugs", "architecture", "sessions")

# ─── Helpers ───────────────────────────────────────────────────────────────

function Test-DriveAvailable {
    try {
        return Test-Path $DriveBase -ErrorAction Stop
    } catch {
        return $false
    }
}

function Ensure-ProjectDirs {
    New-Item -ItemType Directory -Force -Path $projectPath | Out-Null
    foreach ($sub in $subdirs) {
        New-Item -ItemType Directory -Force -Path (Join-Path $projectPath $sub) | Out-Null
    }
}

function Get-SubdirForType {
    param([string]$Type)
    switch -Regex ($Type) {
        'decision'                    { return "decisions" }
        'bugfix|bug'                  { return "bugs" }
        'discovery|learning|pattern'  { return "discoveries" }
        'architecture|config'         { return "architecture" }
        'session|summary'             { return "sessions" }
        default                       { return "architecture" }
    }
}

function Sanitize-FileName {
    param([string]$Key)
    return ($Key -replace '[\\/:*?"<>|]', '_').Substring(0, [Math]::Min(80, $Key.Length))
}

function Backup-IfExists {
    param([string]$FilePath)
    if (Test-Path $FilePath) {
        $bakPath = "$FilePath.bak"
        Copy-Item $FilePath $bakPath -Force
    }
}

function Write-ObservationToDrive {
    param([hashtable]$Obs)
    $type    = $Obs.type ?? "architecture"
    $subdir  = Get-SubdirForType $type
    $key     = $Obs.topic_key ?? ($Obs.title ?? "unknown")
    $safeName = Sanitize-FileName $key
    $filePath = Join-Path $projectPath $subdir "$safeName.json"

    # Newer wins: compare Drive file mtime vs observation updated_at
    if (Test-Path $filePath) {
        $driveTime = (Get-Item $filePath).LastWriteTimeUtc
        $obsTime   = [datetime]::MinValue
        if ($Obs.ContainsKey("updated_at") -and $Obs.updated_at) {
            try { $obsTime = [datetime]::Parse($Obs.updated_at) } catch {}
        }
        if ($driveTime -gt $obsTime -and $obsTime -ne [datetime]::MinValue) {
            Write-Host "  ⏩ Skipped (Drive newer): $safeName"
            return
        }
        Backup-IfExists $filePath
    }

    $Obs["exported_at"] = (Get-Date -Format "o")
    $Obs | ConvertTo-Json -Depth 10 | Set-Content $filePath -Encoding UTF8
    Write-Host "  ✅ Written: $subdir/$safeName.json"
}

# ─── Main ──────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "Engram Drive Sync — Project: $Project"
Write-Host "─────────────────────────────────────────"

if (-not (Test-DriveAvailable)) {
    Write-Host "⚠️  Google Drive path unavailable: $DriveBase"
    Write-Host "   Sync skipped. Development continues normally."
    exit 2
}

# ─── IMPORT ────────────────────────────────────────────────────────────────
if ($Direction -in @("import", "both")) {
    Write-Host ""
    Write-Host "[IMPORT] Reading Drive → stdout for Claude Code to process"
    Ensure-ProjectDirs

    $allFiles = Get-ChildItem -Path $projectPath -Filter "*.json" -Recurse -ErrorAction SilentlyContinue
    $importCount = 0

    foreach ($file in $allFiles) {
        try {
            $content = Get-Content $file.FullName -Raw -Encoding UTF8
            $obs = $content | ConvertFrom-Json -AsHashtable -ErrorAction Stop
            # Print as structured output for Claude Code to pick up
            Write-Host "ENGRAM_IMPORT:$($file.FullName):$($obs.topic_key ?? $obs.title ?? 'unknown')"
            $importCount++
        } catch {
            Write-Host "  ⚠️  Failed to read: $($file.Name) — $($_.Exception.Message)"
        }
    }
    Write-Host "  → $importCount observation(s) available for import"
    Write-Host "  → Claude Code: call mem_save for each ENGRAM_IMPORT line above"
}

# ─── EXPORT ────────────────────────────────────────────────────────────────
if ($Direction -in @("export", "both")) {
    Write-Host ""
    Write-Host "[EXPORT] Writing observations to Drive"
    Ensure-ProjectDirs

    $observations = [System.Collections.Generic.List[hashtable]]::new()

    # Read from input file
    if (-not [string]::IsNullOrWhiteSpace($InputFile) -and (Test-Path $InputFile)) {
        $rawContent = Get-Content $InputFile -Raw -Encoding UTF8
        try {
            $parsed = $rawContent | ConvertFrom-Json -AsHashtable
            if ($parsed -is [System.Collections.IEnumerable] -and $parsed -isnot [hashtable]) {
                $parsed | ForEach-Object { $observations.Add($_) }
            } else {
                $observations.Add($parsed)
            }
        } catch {
            Write-Host "ERROR: Failed to parse input file: $($_.Exception.Message)"
            exit 1
        }
    }
    # Read from stdin if piped
    elseif (-not [Console]::IsInputRedirected -eq $false) {
        $stdinContent = $input | Out-String
        if (-not [string]::IsNullOrWhiteSpace($stdinContent)) {
            try {
                $parsed = $stdinContent | ConvertFrom-Json -AsHashtable
                if ($parsed -is [System.Collections.IEnumerable] -and $parsed -isnot [hashtable]) {
                    $parsed | ForEach-Object { $observations.Add($_) }
                } else {
                    $observations.Add($parsed)
                }
            } catch {
                Write-Host "⚠️  No valid JSON from stdin — export skipped"
            }
        }
    }

    if ($observations.Count -eq 0) {
        Write-Host "  ℹ️  No observations to export (pass -InputFile or pipe JSON)"
    } else {
        foreach ($obs in $observations) {
            Write-ObservationToDrive $obs
        }
        Write-Host "  → $($observations.Count) observation(s) processed"
    }
}

Write-Host ""
Write-Host "✅ Sync complete — $Project"
exit 0
