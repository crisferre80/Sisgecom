# Script de PowerShell para aplicar las migraciones del módulo de pagos
Write-Host "🚀 Aplicando migraciones del módulo de pagos..." -ForegroundColor Green

# Verificar si supabase CLI está instalado
$supabaseCommand = Get-Command supabase -ErrorAction SilentlyContinue
if (-not $supabaseCommand) {
    Write-Host "❌ Supabase CLI no está instalado" -ForegroundColor Red
    Write-Host "📥 Instálelo con: npm install -g supabase" -ForegroundColor Yellow
    exit 1
}

# Verificar si existe el archivo de migración
$migrationFile = "supabase/migrations/20250629050000_payments_module.sql"
if (-not (Test-Path $migrationFile)) {
    Write-Host "❌ No se encontró el archivo de migración: $migrationFile" -ForegroundColor Red
    exit 1
}

Write-Host "📄 Archivo de migración encontrado: $migrationFile" -ForegroundColor Cyan

# Aplicar migración usando supabase CLI
Write-Host "⚡ Aplicando migración..." -ForegroundColor Yellow
$result = & supabase db push 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Migración aplicada exitosamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎯 Tablas creadas:" -ForegroundColor Blue
    Write-Host "   - customers (clientes)" -ForegroundColor Gray
    Write-Host "   - virtual_wallets (billeteras virtuales)" -ForegroundColor Gray
    Write-Host "   - payments (pagos)" -ForegroundColor Gray
    Write-Host "   - payment_reminders (recordatorios)" -ForegroundColor Gray
    Write-Host "   - whatsapp_contacts (contactos WhatsApp)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🔧 Funciones automáticas:" -ForegroundColor Blue
    Write-Host "   - Actualización automática de deuda total" -ForegroundColor Gray
    Write-Host "   - Triggers para timestamps" -ForegroundColor Gray
    Write-Host "   - Índices para optimización" -ForegroundColor Gray
    Write-Host ""
    Write-Host "📊 Datos de ejemplo insertados para testing" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "🚀 El módulo de pagos está listo para usar!" -ForegroundColor Green
} else {
    Write-Host "❌ Error al aplicar la migración:" -ForegroundColor Red
    Write-Host $result -ForegroundColor Red
    exit 1
}

# Mostrar instrucciones adicionales
Write-Host ""
Write-Host "📋 Próximos pasos:" -ForegroundColor Yellow
Write-Host "1. Ejecutar 'npm run dev' para iniciar la aplicación" -ForegroundColor White
Write-Host "2. Navegar a '/payments' para acceder al módulo" -ForegroundColor White
Write-Host "3. Crear clientes y billeteras virtuales" -ForegroundColor White
Write-Host "4. Gestionar pagos y enviar recordatorios por WhatsApp" -ForegroundColor White
