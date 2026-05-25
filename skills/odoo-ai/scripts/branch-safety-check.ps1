#Requires -Version 7.0
<#
.SYNOPSIS
    Classifies the current (or specified) git branch as ALLOWED, RESTRICTED, or UNKNOWN.
.PARAMETER RepoPath
    Path to the git repository. Defaults to current directory.
.PARAMETER Verbose
    Print remote branches in addition to the current branch.
.OUTPUTS
    Exit 0  — ALLOWED (st_* or st_produccion)
    Exit 1  — RESTRICTED (produccion or db_*)
    Exit 2  — UNKNOWN (any other branch)
    Exit 3  — Environment error (not a git repo, git not found)
#>
param(
    [string]$RepoPath = ".",
    [switch]$Verbose
)

Set-StrictMode -Version Latest

function Get-BranchStatus {
    param([string]$Branch)
    if ($Branch -match '^st_') { return "ALLOWED" }
    if ($Branch -eq "produccion" -or $Branch -match '^db_') { return "RESTRICTED" }
    return "UNKNOWN"
}

function Get-StatusEmoji {
    param([string]$Status)
    switch ($Status) {
        "ALLOWED"    { return "✅" }
        "RESTRICTED" { return "🔒" }
        default      { return "⚠️" }
    }
}

# Verify git is available
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: git not found in PATH"
    exit 3
}

# Verify it's a git repo
$gitCheck = git -C $RepoPath rev-parse --is-inside-work-tree 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Not a git repository: $RepoPath"
    exit 3
}

# Get current branch
$currentBranch = git -C $RepoPath branch --show-current 2>&1
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($currentBranch)) {
    Write-Host "ERROR: Could not determine current branch (detached HEAD?)"
    exit 3
}

$currentStatus = Get-BranchStatus $currentBranch
$emoji = Get-StatusEmoji $currentStatus

# Output current branch
Write-Host ""
Write-Host "Branch Safety Check — $RepoPath"
Write-Host "─────────────────────────────────────────"
Write-Host "$emoji $currentStatus — $currentBranch"

switch ($currentStatus) {
    "ALLOWED"    { Write-Host "   → Proceed normally." }
    "RESTRICTED" { Write-Host "   → STOP. Explicit authorization required before any git operation." }
    "UNKNOWN"    { Write-Host "   → Unrecognized branch pattern. Confirm before proceeding." }
}

# Remote branches (when verbose)
if ($Verbose) {
    Write-Host ""
    Write-Host "Remote branches:"
    $remoteBranches = git -C $RepoPath branch -r 2>&1 | Where-Object { $_ -notmatch 'HEAD' }
    foreach ($rb in $remoteBranches) {
        $name = $rb.Trim() -replace '^origin/', ''
        $status = Get-BranchStatus $name
        $e = Get-StatusEmoji $status
        Write-Host "  $e $status — $name"
    }
}

Write-Host ""

# Exit code based on current branch status
switch ($currentStatus) {
    "ALLOWED"    { exit 0 }
    "RESTRICTED" { exit 1 }
    default      { exit 2 }
}
