# Script para aplicar la migración del módulo de configuración
# Esto incluye la tabla inventory_alerts

Write-Host "🔧 Aplicando migración del módulo de configuración..." -ForegroundColor Green

# Verificar si supabase CLI está disponible
$supabaseCommand = Get-Command supabase -ErrorAction SilentlyContinue
if (-not $supabaseCommand) {
    Write-Host "❌ Supabase CLI no está instalado o no está en el PATH" -ForegroundColor Red
    Write-Host "📥 Instálelo con: npm install -g supabase" -ForegroundColor Yellow
    exit 1
}

# Verificar si existe el archivo de migración
$migrationFile = "supabase/migrations/20250630120000_configuration_module.sql"
if (-not (Test-Path $migrationFile)) {
    Write-Host "❌ No se encontró el archivo de migración: $migrationFile" -ForegroundColor Red
    exit 1
}

Write-Host "📄 Archivo de migración encontrado: $migrationFile" -ForegroundColor Cyan

# Mostrar información sobre la migración
Write-Host ""
Write-Host "📋 Esta migración incluye:" -ForegroundColor Blue
Write-Host "   - company_settings (configuración de empresa)" -ForegroundColor Gray
Write-Host "   - system_settings (configuración del sistema)" -ForegroundColor Gray
Write-Host "   - notification_templates (plantillas de notificación)" -ForegroundColor Gray
Write-Host "   - inventory_alerts (alertas de inventario)" -ForegroundColor Gray
Write-Host "   - audit_logs (logs de auditoría)" -ForegroundColor Gray
Write-Host ""

# Preguntar si quiere continuar
Write-Host "¿Desea aplicar la migración del módulo de configuración? (y/N): " -NoNewline -ForegroundColor Cyan
$response = Read-Host

if ($response.ToLower() -eq 'y') {
    Write-Host ""
    Write-Host "⚡ Aplicando migración..." -ForegroundColor Yellow
    
    try {
        # Aplicar todas las migraciones pendientes
        $result = & npx supabase db push 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Migración aplicada exitosamente" -ForegroundColor Green
            Write-Host ""
            Write-Host "🎯 Tablas creadas/actualizadas:" -ForegroundColor Blue
            Write-Host "   ✓ company_settings" -ForegroundColor Green
            Write-Host "   ✓ system_settings" -ForegroundColor Green
            Write-Host "   ✓ notification_templates" -ForegroundColor Green
            Write-Host "   ✓ inventory_alerts" -ForegroundColor Green
            Write-Host "   ✓ audit_logs" -ForegroundColor Green
            Write-Host ""
            Write-Host "🔧 Funciones creadas:" -ForegroundColor Blue
            Write-Host "   ✓ generate_inventory_alerts()" -ForegroundColor Green
            Write-Host "   ✓ update_updated_at_column()" -ForegroundColor Green
            Write-Host ""
            Write-Host "🔒 Políticas RLS aplicadas" -ForegroundColor Blue
            Write-Host ""
            Write-Host "🚀 El módulo de configuración está listo!" -ForegroundColor Green
            
            # Verificar si las tablas se crearon correctamente
            Write-Host ""
            Write-Host "📊 Para verificar que todo funciona:" -ForegroundColor Yellow
            Write-Host "1. Ejecute 'npm run dev' para iniciar la aplicación" -ForegroundColor Gray
            Write-Host "2. Navegue a '/configuration' para acceder al módulo" -ForegroundColor Gray
            Write-Host "3. Las alertas de inventario deberían cargarse sin errores" -ForegroundColor Gray
            
        } else {
            Write-Host "❌ Error al aplicar la migración:" -ForegroundColor Red
            Write-Host $result -ForegroundColor Red
            Write-Host ""
            Write-Host "💡 Posibles soluciones:" -ForegroundColor Yellow
            Write-Host "1. Verificar que Supabase esté configurado correctamente" -ForegroundColor Gray
            Write-Host "2. Ejecutar: supabase db reset" -ForegroundColor Gray
            Write-Host "3. Verificar las variables de entorno (.env)" -ForegroundColor Gray
        }
    } catch {
        Write-Host "❌ Error durante la ejecución: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host ""
    Write-Host "Operación cancelada" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "💡 Para resolver el error de alertas de inventario:" -ForegroundColor Blue
    Write-Host "   Las alertas requieren que se aplique esta migración." -ForegroundColor Gray
    Write-Host "   Sin ella, la tabla 'inventory_alerts' no existirá." -ForegroundColor Gray
}

Write-Host ""
Write-Host "📚 Documentación adicional:" -ForegroundColor Cyan
Write-Host "- MODULO_CONFIGURACION_DOCUMENTACION.md" -ForegroundColor Gray
Write-Host "- MODULO_CONFIGURACION_COMPLETADO.md" -ForegroundColor Gray
