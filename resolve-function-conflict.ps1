# Script para resolver conflicto de funcion PostgreSQL
Write-Host "Resolviendo conflicto de funcion generate_sale_number..." -ForegroundColor Yellow

# Verificar si supabase CLI esta instalado
$supabaseCommand = Get-Command supabase -ErrorAction SilentlyContinue
if (-not $supabaseCommand) {
    Write-Host "Supabase CLI no esta instalado" -ForegroundColor Red
    Write-Host "Instalelo con: npm install -g supabase" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "SOLUCION AL ERROR: 42P13 - cannot change return type of existing function" -ForegroundColor Cyan
Write-Host ""

Write-Host "Problema identificado:" -ForegroundColor Yellow
Write-Host "PostgreSQL no permite cambiar el tipo de retorno de una funcion existente." -ForegroundColor Gray
Write-Host "La funcion 'generate_sale_number' ya existe con un tipo diferente." -ForegroundColor Gray
Write-Host ""

Write-Host "Opciones de solucion:" -ForegroundColor Green
Write-Host ""

Write-Host "1. SOLUCION AUTOMATICA (Recomendada):" -ForegroundColor Blue
Write-Host "   Resetear la base de datos y aplicar todas las migraciones desde cero" -ForegroundColor Gray
Write-Host "   Comando: supabase db reset" -ForegroundColor White
Write-Host ""

Write-Host "2. SOLUCION MANUAL:" -ForegroundColor Blue
Write-Host "   Ejecutar los siguientes comandos SQL en su base de datos:" -ForegroundColor Gray
Write-Host "   DROP FUNCTION IF EXISTS public.generate_sale_number() CASCADE;" -ForegroundColor White
Write-Host "   DROP FUNCTION IF EXISTS public.auto_generate_sale_number() CASCADE;" -ForegroundColor White
Write-Host "   DROP TRIGGER IF EXISTS auto_generate_sale_number_trigger ON public.sales;" -ForegroundColor White
Write-Host ""

Write-Host "3. USAR ARCHIVO DE LIMPIEZA:" -ForegroundColor Blue
Write-Host "   Ejecutar el script SQL de limpieza que hemos creado:" -ForegroundColor Gray
Write-Host "   Archivo: cleanup-functions.sql" -ForegroundColor White
Write-Host ""

# Preguntar al usuario que desea hacer
Write-Host "Que opcion desea ejecutar? (1/2/3/s para salir): " -NoNewline -ForegroundColor Cyan
$choice = Read-Host

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "Ejecutando reset de base de datos..." -ForegroundColor Green
        Write-Host "ADVERTENCIA: Esto eliminara todos los datos existentes" -ForegroundColor Red
        Write-Host "Esta seguro? (y/N): " -NoNewline -ForegroundColor Yellow
        $confirm = Read-Host
        
        if ($confirm.ToLower() -eq 'y') {
            try {
                Write-Host "Reseteando base de datos..." -ForegroundColor Yellow
                $resetResult = & npx supabase db reset 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Base de datos reseteada exitosamente" -ForegroundColor Green
                    Write-Host ""
                    Write-Host "Ahora puede aplicar las migraciones con:" -ForegroundColor Blue
                    Write-Host "npx supabase db push" -ForegroundColor White
                    Write-Host ".\apply-payments-migration.ps1" -ForegroundColor White
                } else {
                    Write-Host "Error al resetear:" -ForegroundColor Red
                    Write-Host $resetResult -ForegroundColor Red
                }
            } catch {
                Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "Operacion cancelada" -ForegroundColor Yellow
        }
    }
    "2" {
        Write-Host ""
        Write-Host "COMANDOS SQL PARA EJECUTAR MANUALMENTE:" -ForegroundColor Blue
        Write-Host ""
        Write-Host "DROP FUNCTION IF EXISTS public.generate_sale_number() CASCADE;" -ForegroundColor White
        Write-Host "DROP FUNCTION IF EXISTS public.auto_generate_sale_number() CASCADE;" -ForegroundColor White
        Write-Host "DROP TRIGGER IF EXISTS auto_generate_sale_number_trigger ON public.sales;" -ForegroundColor White
        Write-Host ""
        Write-Host "Instrucciones:" -ForegroundColor Yellow
        Write-Host "1. Copie estos comandos" -ForegroundColor Gray
        Write-Host "2. Ejecutelos en su cliente PostgreSQL (pgAdmin, psql, etc.)" -ForegroundColor Gray
        Write-Host "3. Luego ejecute: npx supabase db push" -ForegroundColor Gray
    }
    "3" {
        Write-Host ""
        Write-Host "Contenido del archivo cleanup-functions.sql:" -ForegroundColor Blue
        Write-Host ""
        if (Test-Path "cleanup-functions.sql") {
            Get-Content "cleanup-functions.sql" | ForEach-Object { 
                Write-Host $_ -ForegroundColor Gray 
            }
            Write-Host ""
            Write-Host "Para usar este archivo:" -ForegroundColor Yellow
            Write-Host "1. Copie el contenido SQL" -ForegroundColor Gray
            Write-Host "2. Ejecutelo en su base de datos PostgreSQL" -ForegroundColor Gray
            Write-Host "3. Luego ejecute: npx supabase db push" -ForegroundColor Gray
        } else {
            Write-Host "Archivo cleanup-functions.sql no encontrado" -ForegroundColor Red
        }
    }
    "s" {
        Write-Host "Saliendo..." -ForegroundColor Yellow
    }
    default {
        Write-Host "Opcion invalida. Use 1, 2, 3 o 's'" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "INFORMACION ADICIONAL:" -ForegroundColor Cyan
Write-Host ""
Write-Host "Este error es comun cuando:" -ForegroundColor Yellow
Write-Host "Una funcion ya existe con un tipo de retorno diferente" -ForegroundColor Gray
Write-Host "Se intenta modificar una funcion sin eliminarla primero" -ForegroundColor Gray
Write-Host "Hay conflictos entre diferentes archivos de migracion" -ForegroundColor Gray
Write-Host ""
Write-Host "Scripts disponibles:" -ForegroundColor Blue
Write-Host "apply-payments-migration.ps1 - Migracion basica de pagos" -ForegroundColor Gray
Write-Host "apply-users-migration.ps1 - Migracion de usuarios" -ForegroundColor Gray
Write-Host "cleanup-functions.sql - Script de limpieza de funciones" -ForegroundColor Gray
