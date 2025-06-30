#!/usr/bin/env pwsh

# Script simple para aplicar la migración de usuarios
Write-Host "=== APLICANDO MIGRACIÓN DE GESTIÓN DE USUARIOS ===" -ForegroundColor Green

$MigrationFile = "supabase/migrations/20250629055003_user_management_robust.sql"

if (-not (Test-Path $MigrationFile)) {
    Write-Host "ERROR: Archivo de migración no encontrado: $MigrationFile" -ForegroundColor Red
    exit 1
}

Write-Host "Aplicando migración con db push..." -ForegroundColor Yellow

try {
    # Aplicar todas las migraciones pendientes
    npx supabase db push --include-all
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "=== MIGRACIÓN COMPLETADA EXITOSAMENTE ===" -ForegroundColor Green
        Write-Host "✓ Tablas de gestión de usuarios creadas" -ForegroundColor Green
        Write-Host "✓ RLS y políticas de seguridad aplicadas" -ForegroundColor Green
        Write-Host "✓ Funciones y vistas creadas" -ForegroundColor Green
    } else {
        Write-Host "Error al aplicar la migración" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
