# SOLUCION PARA ERROR: 42P13 - cannot change return type of existing function

Write-Host ""
Write-Host "======================================================" -ForegroundColor Red
Write-Host "ERROR DETECTADO: PostgreSQL Function Conflict" -ForegroundColor Red
Write-Host "======================================================" -ForegroundColor Red
Write-Host ""

Write-Host "PROBLEMA:" -ForegroundColor Yellow
Write-Host "La función 'generate_sale_number' ya existe en la base de datos" -ForegroundColor Gray
Write-Host "con un tipo de retorno diferente al que se intenta crear." -ForegroundColor Gray
Write-Host ""

Write-Host "SOLUCION RECOMENDADA:" -ForegroundColor Green
Write-Host ""

Write-Host "1. Ejecute este comando para limpiar funciones conflictivas:" -ForegroundColor Cyan
Write-Host "   npx supabase db reset" -ForegroundColor White
Write-Host ""

Write-Host "2. Luego aplique las migraciones:" -ForegroundColor Cyan  
Write-Host "   npx supabase db push" -ForegroundColor White
Write-Host ""

Write-Host "ADVERTENCIA:" -ForegroundColor Red
Write-Host "El comando 'db reset' eliminará todos los datos existentes." -ForegroundColor Yellow
Write-Host "Solo use este comando si está trabajando en desarrollo." -ForegroundColor Yellow
Write-Host ""

Write-Host "ALTERNATIVA MANUAL (si no quiere perder datos):" -ForegroundColor Blue
Write-Host ""
Write-Host "Ejecute estos comandos SQL en su base de datos:" -ForegroundColor Cyan
Write-Host ""
Write-Host "DROP FUNCTION IF EXISTS public.generate_sale_number() CASCADE;" -ForegroundColor White
Write-Host "DROP FUNCTION IF EXISTS public.auto_generate_sale_number() CASCADE;" -ForegroundColor White  
Write-Host "DROP TRIGGER IF EXISTS auto_generate_sale_number_trigger ON public.sales;" -ForegroundColor White
Write-Host ""

Write-Host "¿Desea ejecutar la solución automática ahora? (y/N): " -NoNewline -ForegroundColor Green
$response = Read-Host

if ($response.ToLower() -eq 'y') {
    Write-Host ""
    Write-Host "Ejecutando solución automática..." -ForegroundColor Yellow
    Write-Host ""
    
    # Reset de la base de datos
    Write-Host "1. Reseteando base de datos..." -ForegroundColor Cyan
    npx supabase db reset
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ Reset completado" -ForegroundColor Green
        Write-Host ""
        
        # Aplicar migraciones
        Write-Host "2. Aplicando migraciones..." -ForegroundColor Cyan
        npx supabase db push
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✓ Migraciones aplicadas exitosamente" -ForegroundColor Green
            Write-Host ""
            Write-Host "PROBLEMA RESUELTO!" -ForegroundColor Green
            Write-Host "El sistema está listo para usar." -ForegroundColor Gray
        } else {
            Write-Host "   ✗ Error al aplicar migraciones" -ForegroundColor Red
        }
    } else {
        Write-Host "   ✗ Error en el reset" -ForegroundColor Red
    }
} else {
    Write-Host ""
    Write-Host "Solución manual requerida." -ForegroundColor Yellow
    Write-Host "Copie y ejecute los comandos SQL mostrados arriba." -ForegroundColor Gray
}

Write-Host ""
Write-Host "======================================================" -ForegroundColor Blue
Write-Host "Para más ayuda, consulte los archivos de documentación:" -ForegroundColor Blue  
Write-Host "- MODULO_PAGOS_DOCUMENTACION.md" -ForegroundColor Gray
Write-Host "- INSTRUCCIONES_MIGRACION_MANUAL.md" -ForegroundColor Gray
Write-Host "======================================================" -ForegroundColor Blue
