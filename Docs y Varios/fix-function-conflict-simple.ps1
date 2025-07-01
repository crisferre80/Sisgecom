# Script simple para resolver el conflicto de función PostgreSQL
Write-Host "🔧 Resolviendo conflicto de función generate_sale_number..." -ForegroundColor Yellow

# Verificar si supabase CLI está instalado
$supabaseCommand = Get-Command supabase -ErrorAction SilentlyContinue
if (-not $supabaseCommand) {
    Write-Host "❌ Supabase CLI no está instalado" -ForegroundColor Red
    Write-Host "📥 Instálelo con: npm install -g supabase" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "📋 SOLUCIÓN AL ERROR: 42P13 - cannot change return type of existing function" -ForegroundColor Cyan
Write-Host ""

Write-Host "🎯 Problema identificado:" -ForegroundColor Yellow
Write-Host "   PostgreSQL no permite cambiar el tipo de retorno de una función existente." -ForegroundColor Gray
Write-Host "   La función 'generate_sale_number' ya existe con un tipo diferente." -ForegroundColor Gray
Write-Host ""

Write-Host "💡 Opciones de solución:" -ForegroundColor Green
Write-Host ""

Write-Host "1️⃣  SOLUCIÓN AUTOMÁTICA (Recomendada):" -ForegroundColor Blue
Write-Host "   Resetear la base de datos y aplicar todas las migraciones desde cero" -ForegroundColor Gray
Write-Host "   Comando: supabase db reset" -ForegroundColor White
Write-Host ""

Write-Host "2️⃣  SOLUCIÓN MANUAL:" -ForegroundColor Blue
Write-Host "   Ejecutar los siguientes comandos SQL en su base de datos:" -ForegroundColor Gray
Write-Host "   DROP FUNCTION IF EXISTS public.generate_sale_number() CASCADE;" -ForegroundColor White
Write-Host "   DROP FUNCTION IF EXISTS public.auto_generate_sale_number() CASCADE;" -ForegroundColor White
Write-Host "   DROP TRIGGER IF EXISTS auto_generate_sale_number_trigger ON public.sales;" -ForegroundColor White
Write-Host ""

Write-Host "3️⃣  USAR ARCHIVO DE LIMPIEZA:" -ForegroundColor Blue
Write-Host "   Ejecutar el script SQL de limpieza que hemos creado:" -ForegroundColor Gray
Write-Host "   Archivo: cleanup-functions.sql" -ForegroundColor White
Write-Host ""

# Preguntar al usuario qué desea hacer
do {
    Write-Host "¿Qué opción desea ejecutar? (1/2/3/s para salir): " -NoNewline -ForegroundColor Cyan
    $choice = Read-Host
    
    switch ($choice.ToLower()) {
        "1" {
            Write-Host ""
            Write-Host "🚀 Ejecutando reset de base de datos..." -ForegroundColor Green
            Write-Host "⚠️  ADVERTENCIA: Esto eliminará todos los datos existentes" -ForegroundColor Red
            Write-Host "¿Está seguro? (y/N): " -NoNewline -ForegroundColor Yellow
            $confirm = Read-Host
            
            if ($confirm.ToLower() -eq 'y') {
                try {
                    Write-Host "   Reseteando base de datos..." -ForegroundColor Yellow
                    $resetResult = & npx supabase db reset 2>&1
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "✅ Base de datos reseteada exitosamente" -ForegroundColor Green
                        Write-Host ""
                        Write-Host "🚀 Ahora puede aplicar las migraciones con:" -ForegroundColor Blue
                        Write-Host "   npx supabase db push" -ForegroundColor White
                        Write-Host "   .\apply-payments-migration.ps1" -ForegroundColor White
                    } else {
                        Write-Host "❌ Error al resetear:" -ForegroundColor Red
                        Write-Host $resetResult -ForegroundColor Red
                    }
                } catch {
                    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
                }
            } else {
                Write-Host "Operación cancelada" -ForegroundColor Yellow
            }
            return
        }
        "2" {
            Write-Host ""
            Write-Host "📋 COMANDOS SQL PARA EJECUTAR MANUALMENTE:" -ForegroundColor Blue
            Write-Host ""
            Write-Host "DROP FUNCTION IF EXISTS public.generate_sale_number() CASCADE;" -ForegroundColor White
            Write-Host "DROP FUNCTION IF EXISTS public.auto_generate_sale_number() CASCADE;" -ForegroundColor White
            Write-Host "DROP TRIGGER IF EXISTS auto_generate_sale_number_trigger ON public.sales;" -ForegroundColor White
            Write-Host ""
            Write-Host "📝 Instrucciones:" -ForegroundColor Yellow
            Write-Host "1. Copie estos comandos" -ForegroundColor Gray
            Write-Host "2. Ejecutelos en su cliente PostgreSQL (pgAdmin, psql, etc.)" -ForegroundColor Gray
            Write-Host "3. Luego ejecute: npx supabase db push" -ForegroundColor Gray
            return
        }
        "3" {
            Write-Host ""
            Write-Host "📄 Contenido del archivo cleanup-functions.sql:" -ForegroundColor Blue
            Write-Host ""
            if (Test-Path "cleanup-functions.sql") {
                Get-Content "cleanup-functions.sql" | ForEach-Object { 
                    Write-Host $_ -ForegroundColor Gray 
                }
                Write-Host ""
                Write-Host "💡 Para usar este archivo:" -ForegroundColor Yellow
                Write-Host "1. Copie el contenido SQL" -ForegroundColor Gray
                Write-Host "2. Ejecutelo en su base de datos PostgreSQL" -ForegroundColor Gray
                Write-Host "3. Luego ejecute: npx supabase db push" -ForegroundColor Gray
            } else {
                Write-Host "❌ Archivo cleanup-functions.sql no encontrado" -ForegroundColor Red
            }
            return
        }
        "s" {
            Write-Host "Saliendo..." -ForegroundColor Yellow
            return
        }
        default {
            Write-Host "Opción inválida. Use 1, 2, 3 o 's'" -ForegroundColor Red
        }
    }
} while ($true)

Write-Host ""
Write-Host "📚 INFORMACIÓN ADICIONAL:" -ForegroundColor Cyan
Write-Host ""
Write-Host "Este error es común cuando:" -ForegroundColor Yellow
Write-Host "• Una función ya existe con un tipo de retorno diferente" -ForegroundColor Gray
Write-Host "• Se intenta modificar una función sin eliminarla primero" -ForegroundColor Gray
Write-Host "• Hay conflictos entre diferentes archivos de migración" -ForegroundColor Gray
Write-Host ""
Write-Host "🔗 Scripts disponibles:" -ForegroundColor Blue
Write-Host "• apply-payments-migration.ps1 - Migración básica de pagos" -ForegroundColor Gray
Write-Host "• apply-users-migration.ps1 - Migración de usuarios" -ForegroundColor Gray
Write-Host "• cleanup-functions.sql - Script de limpieza de funciones" -ForegroundColor Gray
