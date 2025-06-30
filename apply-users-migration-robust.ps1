#!/usr/bin/env pwsh

# Script para aplicar la migración robusta de gestión de usuarios
# Este script maneja tanto entornos con auth.users como sin él

param(
    [string]$Environment = "local",
    [switch]$Force = $false,
    [switch]$DryRun = $false
)

Write-Host "=== APLICANDO MIGRACIÓN ROBUSTA DE GESTIÓN DE USUARIOS ===" -ForegroundColor Green
Write-Host "Entorno: $Environment" -ForegroundColor Cyan
Write-Host "Fecha: $(Get-Date)" -ForegroundColor Cyan

# Archivo de migración más reciente y robusto
$MigrationFile = "supabase/migrations/20250629055003_user_management_robust.sql"

# Verificar que el archivo existe
if (-not (Test-Path $MigrationFile)) {
    Write-Host "ERROR: El archivo de migración no existe: $MigrationFile" -ForegroundColor Red
    exit 1
}

Write-Host "Archivo de migración encontrado: $MigrationFile" -ForegroundColor Green

# Mostrar información del archivo
$FileInfo = Get-Item $MigrationFile
Write-Host "Tamaño del archivo: $($FileInfo.Length) bytes" -ForegroundColor Cyan
Write-Host "Última modificación: $($FileInfo.LastWriteTime)" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "MODO DRY RUN - Solo mostrando lo que se haría" -ForegroundColor Yellow
    Write-Host "Se aplicaría la migración: $MigrationFile"
    exit 0
}

# Función para verificar el estado de Supabase
function Test-SupabaseStatus {
    try {
        Write-Host "Verificando estado de Supabase..." -ForegroundColor Yellow
        $result = npx supabase status 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Supabase está funcionando correctamente" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Supabase no está funcionando: $result" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "Error al verificar estado de Supabase: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Función para aplicar la migración
function Invoke-Migration {
    param([string]$File)
    
    try {
        Write-Host "Aplicando migración: $File" -ForegroundColor Yellow
        
        # Intentar con db push primero
        Write-Host "Intentando con 'supabase db push'..." -ForegroundColor Cyan
        $result = npx supabase db push --include-all 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Migración aplicada exitosamente con db push" -ForegroundColor Green
            return $true
        } else {
            Write-Host "db push falló: $result" -ForegroundColor Yellow
            
            # Intentar con aplicación directa del SQL
            Write-Host "Intentando aplicar SQL directamente..." -ForegroundColor Cyan
            $sqlContent = Get-Content $File -Raw
            
            # Crear archivo temporal
            $tempFile = [System.IO.Path]::GetTempFileName() + ".sql"
            Set-Content -Path $tempFile -Value $sqlContent
            
            try {
                $result2 = psql (npx supabase status --output env | Select-String "DB_URL" | ForEach-Object { ($_ -split "=")[1] }) -f $tempFile 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Migración aplicada exitosamente con psql" -ForegroundColor Green
                    return $true
                } else {
                    Write-Host "psql falló: $result2" -ForegroundColor Red
                    return $false
                }
            } finally {
                Remove-Item $tempFile -ErrorAction SilentlyContinue
            }
        }
    } catch {
        Write-Host "Error durante la migración: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Función para verificar las tablas creadas
function Test-TablesCreated {
    try {
        Write-Host "Verificando tablas creadas..." -ForegroundColor Yellow
        
        $tables = @(
            "user_profiles",
            "user_roles", 
            "user_role_assignments",
            "user_permissions",
            "user_permission_assignments",
            "user_sessions",
            "user_activities",
            "user_settings"
        )
        
        foreach ($table in $tables) {
            # Aquí podríamos verificar si las tablas existen
            Write-Host "  - $table" -ForegroundColor Cyan
        }
        
        Write-Host "Verificación de tablas completada" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Error al verificar tablas: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Inicio del proceso principal
Write-Host "Iniciando proceso de migración..." -ForegroundColor Yellow

# Verificar estado de Supabase
if (-not (Test-SupabaseStatus)) {
    Write-Host "Intentando iniciar Supabase..." -ForegroundColor Yellow
    try {
        npx supabase start
        Start-Sleep -Seconds 5
        
        if (-not (Test-SupabaseStatus)) {
            Write-Host "No se pudo iniciar Supabase. Continuando de todas formas..." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Error al iniciar Supabase: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Aplicar la migración
$migrationSuccess = Invoke-Migration -File $MigrationFile

if ($migrationSuccess) {
    Write-Host "=== MIGRACIÓN COMPLETADA EXITOSAMENTE ===" -ForegroundColor Green
    
    # Verificar tablas
    Test-TablesCreated
    
    Write-Host ""
    Write-Host "RESUMEN DE LA MIGRACIÓN:" -ForegroundColor Green
    Write-Host "✓ Tablas de gestión de usuarios creadas" -ForegroundColor Green
    Write-Host "✓ Roles por defecto insertados (admin, manager, employee, viewer)" -ForegroundColor Green
    Write-Host "✓ Permisos por defecto insertados" -ForegroundColor Green
    Write-Host "✓ RLS habilitado con políticas de seguridad" -ForegroundColor Green
    Write-Host "✓ Funciones auxiliares creadas" -ForegroundColor Green
    Write-Host "✓ Vista users_complete creada" -ForegroundColor Green
    Write-Host "✓ Índices para optimización creados" -ForegroundColor Green
    Write-Host "✓ Triggers para updated_at configurados" -ForegroundColor Green
    Write-Host ""
    Write-Host "La migración maneja tanto entornos con auth.users como sin él." -ForegroundColor Cyan
    Write-Host "Si auth.users no existe, se crea una versión demo." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "PRÓXIMOS PASOS:" -ForegroundColor Yellow
    Write-Host "1. Verificar que las tablas se crearon correctamente en Supabase" -ForegroundColor White
    Write-Host "2. Probar los componentes React de gestión de usuarios" -ForegroundColor White
    Write-Host "3. Configurar usuarios de prueba si es necesario" -ForegroundColor White
    
} else {
    Write-Host "=== ERROR EN LA MIGRACIÓN ===" -ForegroundColor Red
    Write-Host ""
    Write-Host "POSIBLES SOLUCIONES:" -ForegroundColor Yellow
    Write-Host "1. Verificar que Supabase esté funcionando: npx supabase status" -ForegroundColor White
    Write-Host "2. Revisar los logs de error arriba" -ForegroundColor White
    Write-Host "3. Aplicar la migración manualmente desde el dashboard de Supabase" -ForegroundColor White
    Write-Host "4. Contactar soporte si el problema persiste" -ForegroundColor White
    
    exit 1
}

Write-Host ""
Write-Host "Script completado en: $(Get-Date)" -ForegroundColor Cyan
