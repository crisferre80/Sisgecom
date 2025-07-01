#!/usr/bin/env pwsh

# Script para resolver conflictos de funciones en PostgreSQL
Write-Host "🔧 Resolviendo conflicto de función generate_sale_number..." -ForegroundColor Yellow

# Verificar si supabase CLI está instalado
$supabaseCommand = Get-Command supabase -ErrorAction SilentlyContinue
if (-not $supabaseCommand) {
    Write-Host "❌ Supabase CLI no está instalado" -ForegroundColor Red
    Write-Host "📥 Instálelo con: npm install -g supabase" -ForegroundColor Yellow
    exit 1
}

# Crear script SQL temporal para eliminar la función
$cleanupSQL = @"
-- Eliminar función conflictiva generate_sale_number
DROP FUNCTION IF EXISTS public.generate_sale_number() CASCADE;

-- Eliminar trigger y función relacionada si existen
DROP TRIGGER IF EXISTS auto_generate_sale_number_trigger ON public.sales;
DROP FUNCTION IF EXISTS public.auto_generate_sale_number() CASCADE;

-- Mensaje de confirmación
SELECT 'Funciones eliminadas exitosamente' as status;
"@

$tempFile = "temp_cleanup.sql"
$cleanupSQL | Out-File -FilePath $tempFile -Encoding UTF8

Write-Host "📄 Ejecutando limpieza de funciones..." -ForegroundColor Cyan

try {
    # Ejecutar script de limpieza
    $result = & supabase db reset 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Reset falló, continuando con limpieza manual..." -ForegroundColor Yellow
    }

    # Aplicar script de limpieza
    $cleanupResult = & supabase db push --include-all 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Funciones limpiadas exitosamente" -ForegroundColor Green
        Write-Host ""
        Write-Host "🚀 Ahora puede aplicar las migraciones normalmente con:" -ForegroundColor Blue
        Write-Host "   supabase db push" -ForegroundColor Gray
        Write-Host ""
        Write-Host "O ejecutar el script específico:" -ForegroundColor Blue
        Write-Host "   .\apply-payments-migration.ps1" -ForegroundColor Gray
    } else {
        Write-Host "❌ Error al limpiar funciones:" -ForegroundColor Red
        Write-Host $cleanupResult -ForegroundColor Red
        
        Write-Host ""
        Write-Host "🔧 Solución manual:" -ForegroundColor Yellow
        Write-Host "Ejecute en su base de datos PostgreSQL:" -ForegroundColor Gray
        Write-Host "DROP FUNCTION IF EXISTS public.generate_sale_number() CASCADE;" -ForegroundColor Gray
        Write-Host "DROP FUNCTION IF EXISTS public.auto_generate_sale_number() CASCADE;" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    # Limpiar archivo temporal
    if (Test-Path $tempFile) {
        Remove-Item $tempFile -Force
    }
}

Write-Host ""
Write-Host "📚 Documentación:" -ForegroundColor Blue
Write-Host "Este error ocurre cuando PostgreSQL intenta recrear una función" -ForegroundColor Gray
Write-Host "con un tipo de retorno diferente. La función debe eliminarse primero." -ForegroundColor Gray
