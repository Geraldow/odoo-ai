#!/usr/bin/env pwsh
<#
.SYNOPSIS
Docker setup: verifica daemon, containers, y estado de base de datos Odoo.
Si DB no está inicializada, ejecuta -i base automáticamente (con confirmación).

.PARAMETER ProjectDir
Project root directory (defaults to current)
.PARAMETER AutoInit
Inicializar DB sin preguntar (default: false)
#>

param(
    [string]$ProjectDir = (Get-Location),
    [switch]$AutoInit
)

Push-Location $ProjectDir
try {
    if (-not (Test-Path 'docker-compose.yml')) {
        Write-Host "❌ docker-compose.yml not found" -ForegroundColor Red
        exit 1
    }

    # Detectar directorio real de custom addons (el que Docker monta)
    $composeContent = Get-Content 'docker-compose.yml' -Raw
    $mountMatch = [regex]::Matches($composeContent, '(\./[\w/\-]+):/mnt/custom-addons')
    if ($mountMatch.Count -gt 0) {
        $customAddonsDir = $mountMatch[0].Groups[1].Value.TrimStart('./')
        Write-Host "📦 Custom addons montado en Docker: ./$customAddonsDir" -ForegroundColor Cyan
        $mountedPath = Join-Path $ProjectDir $customAddonsDir
        $rootModules = Get-ChildItem $ProjectDir -Directory -Depth 0 |
            Where-Object { Test-Path (Join-Path $_.FullName '__manifest__.py') }
        $duplicates = $rootModules | Where-Object {
            Test-Path (Join-Path $mountedPath $_.Name)
        }
        if ($duplicates) {
            Write-Host "⚠️  Módulos con copia duplicada (raíz ≠ Docker):" -ForegroundColor Yellow
            $duplicates | ForEach-Object {
                Write-Host "   → Editar: ./$customAddonsDir/$($_.Name)/" -ForegroundColor Yellow
                Write-Host "     Ignorar: ./$($_.Name)/ (no montado en Docker)" -ForegroundColor DarkGray
            }
        }
    }

    # Leer db_name desde odoo.conf si existe
    $dbName = 'odoo'
    $confFile = 'etc/odoo.conf'
    if (Test-Path $confFile) {
        $match = Select-String -Path $confFile -Pattern 'db_name\s*=\s*(\S+)'
        if ($match) { $dbName = $match.Matches[0].Groups[1].Value }
    }

    Write-Host "Docker Setup — DB: $dbName" -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan

    # 1. Verificar Docker daemon
    docker ps 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Docker daemon not running" -ForegroundColor Red
        Write-Host "   → Start Docker Desktop"
        exit 1
    }
    Write-Host "✅ Docker daemon running"

    # 2. Verificar containers
    $running = docker-compose ps -q 2>$null
    if (-not $running) {
        Write-Host "⚠️  Containers not running → starting..." -ForegroundColor Yellow
        docker-compose up -d
        Start-Sleep -Seconds 5
    } else {
        Write-Host "✅ Containers running"
    }

    # 3. Verificar si DB está inicializada
    Write-Host ""
    Write-Host "Checking DB initialization..." -ForegroundColor Cyan

    $check = docker-compose exec -T db psql -U odoo -d $dbName -c '\dt ir_module_module' 2>&1
    $dbInitialized = $check -match 'ir_module_module'

    if ($dbInitialized) {
        Write-Host "✅ Database '$dbName' is initialized"
        exit 0
    }

    # 4. DB no inicializada
    Write-Host "⚠️  Database '$dbName' exists but is NOT initialized" -ForegroundColor Yellow
    Write-Host "   → Odoo needs to install base module"

    if (-not $AutoInit) {
        Write-Host ""
        Write-Host "Run the following to initialize:" -ForegroundColor Cyan
        Write-Host "   docker-compose exec web odoo -d $dbName -i base --stop-after-init"
        Write-Host ""
        Write-Host "Or re-run with -AutoInit flag to do it automatically"
        exit 0
    }

    # 5. Auto-inicializar
    Write-Host ""
    Write-Host "Initializing database (this takes 2-3 minutes)..." -ForegroundColor Yellow
    docker-compose exec -T web odoo -d $dbName -i base --stop-after-init
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Database initialized" -ForegroundColor Green
        Write-Host "Restarting web container..."
        docker-compose restart web
        Write-Host "✅ Ready at http://localhost:18069" -ForegroundColor Green
    } else {
        Write-Host "❌ Initialization failed — check logs:" -ForegroundColor Red
        Write-Host "   docker-compose logs web --tail=50"
        exit 1
    }

} finally {
    Pop-Location
}
