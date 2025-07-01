# Script de migración para Gestión de Usuarios (PowerShell)
# Fecha: 2025-06-29
# Descripción: Aplicar migración de gestión de usuarios a Supabase

Write-Host "🚀 Aplicando migración de Gestión de Usuarios..." -ForegroundColor Green

# Verificar si existe la migración (prioridad: final > fixed > original)
$MigrationFile = "supabase\migrations\20250629055002_user_management_final.sql"

if (-not (Test-Path $MigrationFile)) {
    Write-Host "⚠️  Migración final no encontrada, probando versión corregida..." -ForegroundColor Yellow
    $MigrationFile = "supabase\migrations\20250629055001_user_management_fixed.sql"
    
    if (-not (Test-Path $MigrationFile)) {
        Write-Host "⚠️  Migración corregida no encontrada, usando original..." -ForegroundColor Yellow
        $MigrationFile = "supabase\migrations\20250629055000_user_management.sql"
        
        if (-not (Test-Path $MigrationFile)) {
            Write-Host "❌ Error: No se encuentra ningún archivo de migración válido" -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host "📁 Archivo de migración encontrado: $MigrationFile" -ForegroundColor Yellow

# Verificar variables de entorno
if (-not $env:SUPABASE_PROJECT_REF -or -not $env:SUPABASE_DB_PASSWORD) {
    Write-Host "⚠️  Configurando variables de entorno desde .env..." -ForegroundColor Yellow
    
    if (Test-Path ".env") {
        # Leer archivo .env
        $envContent = Get-Content ".env"
        foreach ($line in $envContent) {
            if ($line -match "VITE_SUPABASE_URL=(.+)") {
                $supabaseUrl = $matches[1] -replace '"', ''
                if ($supabaseUrl -match "https://([^.]+)\.") {
                    $env:SUPABASE_PROJECT_REF = $matches[1]
                    Write-Host "✅ SUPABASE_PROJECT_REF extraído: $($env:SUPABASE_PROJECT_REF)" -ForegroundColor Green
                }
            }
        }
    }
    
    if (-not $env:SUPABASE_PROJECT_REF) {
        Write-Host "❌ Error: SUPABASE_PROJECT_REF no está configurado" -ForegroundColor Red
        Write-Host "💡 Configura las variables:" -ForegroundColor Cyan
        Write-Host "   `$env:SUPABASE_PROJECT_REF = 'tu_project_ref'" -ForegroundColor Cyan
        Write-Host "   `$env:SUPABASE_DB_PASSWORD = 'tu_password'" -ForegroundColor Cyan
        exit 1
    }
}

# Verificar si Supabase CLI está instalado
$supabaseCmd = Get-Command supabase -ErrorAction SilentlyContinue
if (-not $supabaseCmd) {
    Write-Host "❌ Error: Supabase CLI no está instalado" -ForegroundColor Red
    Write-Host "💡 Instala con: npm install -g supabase" -ForegroundColor Cyan
    exit 1
}

Write-Host "🔍 Verificando conexión con Supabase..." -ForegroundColor Yellow

# Aplicar migración usando Supabase CLI
Write-Host "📤 Aplicando migración..." -ForegroundColor Yellow

# Opción 1: Si estás usando un proyecto local de Supabase
if (Test-Path "supabase\config.toml") {
    Write-Host "🏠 Detectado proyecto local de Supabase" -ForegroundColor Cyan
    $result = & supabase db push
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Migración aplicada exitosamente (local)" -ForegroundColor Green
    } else {
        Write-Host "❌ Error aplicando migración local" -ForegroundColor Red
        exit 1
    }
} else {
    # Opción 2: Aplicar directamente usando psql (si está disponible)
    Write-Host "🌐 Aplicando a proyecto remoto..." -ForegroundColor Cyan
    
    # Construir URL de conexión
    $dbUrl = "postgresql://postgres:$($env:SUPABASE_DB_PASSWORD)@db.$($env:SUPABASE_PROJECT_REF).supabase.co:5432/postgres"
    
    $psqlCmd = Get-Command psql -ErrorAction SilentlyContinue
    if ($psqlCmd) {
        Write-Host "🔗 Conectando con psql..." -ForegroundColor Cyan
        $result = & psql $dbUrl -f $MigrationFile
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Migración aplicada exitosamente (remoto)" -ForegroundColor Green
        } else {
            Write-Host "❌ Error aplicando migración remota" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "⚠️  psql no está disponible" -ForegroundColor Yellow
        Write-Host "💡 Opciones:" -ForegroundColor Cyan
        Write-Host "   1. Instalar PostgreSQL client tools" -ForegroundColor Cyan
        Write-Host "   2. Copiar el contenido de $MigrationFile y ejecutarlo manualmente en Supabase Dashboard" -ForegroundColor Cyan
        Write-Host "   3. Usar Supabase CLI con 'supabase db push' en un proyecto inicializado" -ForegroundColor Cyan
        exit 1
    }
}

Write-Host ""
Write-Host "🎉 ¡Migración de Gestión de Usuarios completada!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Resumen de lo que se creó:" -ForegroundColor Yellow
Write-Host "   ✅ Tabla user_profiles - Perfiles extendidos de usuario" -ForegroundColor Green
Write-Host "   ✅ Tabla user_roles - Roles de usuario" -ForegroundColor Green
Write-Host "   ✅ Tabla user_permissions - Permisos específicos" -ForegroundColor Green
Write-Host "   ✅ Tabla user_sessions - Sesiones de usuario" -ForegroundColor Green
Write-Host "   ✅ Tabla user_activities - Log de actividades" -ForegroundColor Green
Write-Host "   ✅ Vista users_complete - Vista completa de usuarios" -ForegroundColor Green
Write-Host "   ✅ Función get_user_stats() - Estadísticas de usuarios" -ForegroundColor Green
Write-Host "   ✅ Políticas RLS - Seguridad a nivel de fila" -ForegroundColor Green
Write-Host "   ✅ Triggers - Automatización de logs" -ForegroundColor Green
Write-Host ""
Write-Host "🔧 Próximos pasos:" -ForegroundColor Cyan
Write-Host "   1. Verificar que los componentes React funcionen correctamente" -ForegroundColor White
Write-Host "   2. Crear un usuario administrador inicial si es necesario" -ForegroundColor White
Write-Host "   3. Configurar roles y permisos según tu organización" -ForegroundColor White
Write-Host ""
Write-Host "📚 Documentación: Ver MODULO_USUARIOS_DOCUMENTACION.md" -ForegroundColor Cyan
