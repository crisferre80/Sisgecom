Write-Host "======================================================" -ForegroundColor Red
Write-Host "ERROR: 42P13 - cannot change return type of existing function" -ForegroundColor Red  
Write-Host "======================================================" -ForegroundColor Red
Write-Host ""

Write-Host "PROBLEMA:" -ForegroundColor Yellow
Write-Host "La funcion 'generate_sale_number' ya existe con un tipo diferente." -ForegroundColor Gray
Write-Host ""

Write-Host "SOLUCION AUTOMATICA:" -ForegroundColor Green
Write-Host "1. npx supabase db reset" -ForegroundColor White
Write-Host "2. npx supabase db push" -ForegroundColor White
Write-Host ""

Write-Host "SOLUCION MANUAL (SQL):" -ForegroundColor Blue
Write-Host "DROP FUNCTION IF EXISTS public.generate_sale_number() CASCADE;" -ForegroundColor White
Write-Host "DROP FUNCTION IF EXISTS public.auto_generate_sale_number() CASCADE;" -ForegroundColor White
Write-Host "DROP TRIGGER IF EXISTS auto_generate_sale_number_trigger ON public.sales;" -ForegroundColor White
Write-Host ""

Write-Host "Ejecutar solucion automatica? (y/N): " -NoNewline -ForegroundColor Cyan
$answer = Read-Host

if ($answer -eq "y") {
    Write-Host "Ejecutando reset..." -ForegroundColor Yellow
    npx supabase db reset
    
    Write-Host "Aplicando migraciones..." -ForegroundColor Yellow  
    npx supabase db push
    
    Write-Host "Listo!" -ForegroundColor Green
}
