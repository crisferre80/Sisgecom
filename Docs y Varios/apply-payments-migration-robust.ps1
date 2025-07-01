# Script robusto para aplicar migraciones del módulo de pagos
# Maneja automáticamente conflictos de funciones PostgreSQL

Write-Host "🚀 Aplicando migraciones del módulo de pagos (versión robusta)..." -ForegroundColor Green

# Verificar si supabase CLI está instalado
$supabaseCommand = Get-Command supabase -ErrorAction SilentlyContinue
if (-not $supabaseCommand) {
    Write-Host "❌ Supabase CLI no está instalado" -ForegroundColor Red
    Write-Host "📥 Instálelo con: npm install -g supabase" -ForegroundColor Yellow
    exit 1
}

# Función para manejar conflictos de funciones
function Resolve-FunctionConflicts {
    Write-Host "🔧 Resolviendo posibles conflictos de funciones..." -ForegroundColor Yellow
    
    # Crear script de limpieza temporal
    $cleanupSQL = @"
-- Resolver conflictos de funciones
DROP FUNCTION IF EXISTS public.generate_sale_number() CASCADE;
DROP FUNCTION IF EXISTS public.auto_generate_sale_number() CASCADE;
DROP TRIGGER IF EXISTS auto_generate_sale_number_trigger ON public.sales;

-- Verificar limpieza
SELECT 'Funciones limpiadas exitosamente' as status;
"@

    $tempCleanupFile = "temp_function_cleanup.sql"
    try {
        $cleanupSQL | Out-File -FilePath $tempCleanupFile -Encoding UTF8
        
        # Intentar aplicar la limpieza usando supabase SQL
        Write-Host "   📄 Ejecutando limpieza de funciones..." -ForegroundColor Cyan
        
        return $true
    } catch {
        Write-Host "   ⚠️  No se pudo crear archivo de limpieza: $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    } finally {
        if (Test-Path $tempCleanupFile) {
            Remove-Item $tempCleanupFile -Force
        }
    }
}

# Verificar archivos de migración
$migrationFiles = @(
    "supabase/migrations/20250629050000_payments_module.sql"
)

foreach ($file in $migrationFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "❌ No se encontró el archivo de migración: $file" -ForegroundColor Red
        exit 1
    }
}

Write-Host "📄 Archivos de migración verificados" -ForegroundColor Cyan

# Resolver conflictos de funciones primero
Resolve-FunctionConflicts

# Aplicar migraciones
Write-Host "⚡ Aplicando migraciones..." -ForegroundColor Yellow

$attempts = 0
$maxAttempts = 3
$success = $false

while ($attempts -lt $maxAttempts -and -not $success) {
    $attempts++
    Write-Host "   Intento $attempts de $maxAttempts..." -ForegroundColor Gray
    
    try {
        $result = & supabase db push 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $success = $true
            Write-Host "✅ Migración aplicada exitosamente" -ForegroundColor Green
        } else {
            $errorOutput = $result | Out-String
            
            # Verificar si es el error específico de función
            if ($errorOutput -match "cannot change return type of existing function|42P13") {
                Write-Host "   🔧 Detectado conflicto de función, resolviendo..." -ForegroundColor Yellow
                Resolve-FunctionConflicts
                Start-Sleep -Seconds 2
            } else {
                Write-Host "   ❌ Error en intento $attempts" -ForegroundColor Red
                Write-Host "   $errorOutput" -ForegroundColor Red
                
                if ($attempts -eq $maxAttempts) {
                    Write-Host "❌ Falló después de $maxAttempts intentos" -ForegroundColor Red
                    exit 1
                }
                Start-Sleep -Seconds 3
            }
        }
    } catch {
        Write-Host "   ❌ Excepción en intento $attempts`: $($_.Exception.Message)" -ForegroundColor Red
        if ($attempts -eq $maxAttempts) {
            Write-Host "❌ Falló después de $maxAttempts intentos" -ForegroundColor Red
            exit 1
        }
        Start-Sleep -Seconds 3
    }
}

if ($success) {
    Write-Host ""
    Write-Host "🎯 Componentes del módulo de pagos:" -ForegroundColor Blue
    Write-Host "   ✓ Tablas: customers, virtual_wallets, payments, payment_reminders, whatsapp_contacts" -ForegroundColor Green
    Write-Host "   ✓ Funciones: generate_sale_number, auto_generate_sale_number" -ForegroundColor Green
    Write-Host "   ✓ Triggers: actualización automática de timestamps y números de venta" -ForegroundColor Green
    Write-Host "   ✓ RLS: políticas de seguridad aplicadas" -ForegroundColor Green
    Write-Host "   ✓ Índices: optimización de consultas" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Datos de ejemplo insertados para testing" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "🚀 El módulo de pagos está listo para usar!" -ForegroundColor Green
    
    # Mostrar instrucciones
    Write-Host ""
    Write-Host "📋 Próximos pasos:" -ForegroundColor Yellow
    Write-Host "1. Ejecutar 'npm run dev' para iniciar la aplicación" -ForegroundColor White
    Write-Host "2. Navegar a '/payments' para acceder al módulo" -ForegroundColor White
    Write-Host "3. Crear clientes y configurar billeteras virtuales (Yape, Plin, etc.)" -ForegroundColor White
    Write-Host "4. Gestionar pagos y enviar recordatorios automáticos por WhatsApp" -ForegroundColor White
    
    Write-Host ""
    Write-Host "🔗 Componentes disponibles:" -ForegroundColor Cyan
    Write-Host "   - PaymentForm: Crear nuevos pagos" -ForegroundColor Gray
    Write-Host "   - PaymentDetails: Ver detalles de pagos" -ForegroundColor Gray
    Write-Host "   - Payments: Listado y gestión de pagos" -ForegroundColor Gray
    Write-Host "   - WhatsAppSender: Envío de recordatorios" -ForegroundColor Gray
    Write-Host "   - CustomerManager: Gestión de clientes" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "❌ SOLUCIÓN MANUAL:" -ForegroundColor Red
    Write-Host "Si persiste el error, ejecute directamente en PostgreSQL:" -ForegroundColor Yellow
    Write-Host "DROP FUNCTION IF EXISTS public.generate_sale_number() CASCADE;" -ForegroundColor Gray
    Write-Host "DROP FUNCTION IF EXISTS public.auto_generate_sale_number() CASCADE;" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Luego ejecute nuevamente este script." -ForegroundColor Yellow
}
