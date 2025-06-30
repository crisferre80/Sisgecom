#!/bin/bash

# Script de migración para Gestión de Usuarios
# Fecha: 2025-06-29
# Descripción: Aplicar migración de gestión de usuarios a Supabase

echo "🚀 Aplicando migración de Gestión de Usuarios..."

# Verificar si existe la migración (prioridad: final > fixed > original)
MIGRATION_FILE="supabase/migrations/20250629055002_user_management_final.sql"

if [ ! -f "$MIGRATION_FILE" ]; then
    echo "⚠️  Migración final no encontrada, probando versión corregida..."
    MIGRATION_FILE="supabase/migrations/20250629055001_user_management_fixed.sql"
    
    if [ ! -f "$MIGRATION_FILE" ]; then
        echo "⚠️  Migración corregida no encontrada, usando original..."
        MIGRATION_FILE="supabase/migrations/20250629055000_user_management.sql"
        
        if [ ! -f "$MIGRATION_FILE" ]; then
            echo "❌ Error: No se encuentra ningún archivo de migración válido"
            exit 1
        fi
    fi
fi

echo "📁 Archivo de migración encontrado: $MIGRATION_FILE"

# Verificar variables de entorno
if [ -z "$SUPABASE_PROJECT_REF" ] || [ -z "$SUPABASE_DB_PASSWORD" ]; then
    echo "⚠️  Configurando variables de entorno desde .env..."
    
    if [ -f ".env" ]; then
        # Extraer SUPABASE_URL y obtener project ref
        SUPABASE_URL=$(grep "VITE_SUPABASE_URL" .env | cut -d '=' -f2 | tr -d '"')
        if [ ! -z "$SUPABASE_URL" ]; then
            # Extraer project ref de la URL (formato: https://xxx.supabase.co)
            SUPABASE_PROJECT_REF=$(echo $SUPABASE_URL | sed 's/https:\/\/\([^.]*\).*/\1/')
            export SUPABASE_PROJECT_REF
            echo "✅ SUPABASE_PROJECT_REF extraído: $SUPABASE_PROJECT_REF"
        fi
    fi
    
    if [ -z "$SUPABASE_PROJECT_REF" ]; then
        echo "❌ Error: SUPABASE_PROJECT_REF no está configurado"
        echo "💡 Configura las variables:"
        echo "   export SUPABASE_PROJECT_REF=tu_project_ref"
        echo "   export SUPABASE_DB_PASSWORD=tu_password"
        exit 1
    fi
fi

# Verificar si Supabase CLI está instalado
if ! command -v supabase &> /dev/null; then
    echo "❌ Error: Supabase CLI no está instalado"
    echo "💡 Instala con: npm install -g supabase"
    exit 1
fi

echo "🔍 Verificando conexión con Supabase..."

# Aplicar migración usando Supabase CLI
echo "📤 Aplicando migración..."

# Opción 1: Si estás usando un proyecto local de Supabase
if [ -f "supabase/config.toml" ]; then
    echo "🏠 Detectado proyecto local de Supabase"
    supabase db push
    if [ $? -eq 0 ]; then
        echo "✅ Migración aplicada exitosamente (local)"
    else
        echo "❌ Error aplicando migración local"
        exit 1
    fi
else
    # Opción 2: Aplicar directamente usando psql (si está disponible)
    echo "🌐 Aplicando a proyecto remoto..."
    
    # Construir URL de conexión
    DB_URL="postgresql://postgres:$SUPABASE_DB_PASSWORD@db.$SUPABASE_PROJECT_REF.supabase.co:5432/postgres"
    
    if command -v psql &> /dev/null; then
        echo "🔗 Conectando con psql..."
        psql "$DB_URL" -f "$MIGRATION_FILE"
        if [ $? -eq 0 ]; then
            echo "✅ Migración aplicada exitosamente (remoto)"
        else
            echo "❌ Error aplicando migración remota"
            exit 1
        fi
    else
        echo "⚠️  psql no está disponible"
        echo "💡 Opciones:"
        echo "   1. Instalar psql: sudo apt-get install postgresql-client"
        echo "   2. Copiar el contenido de $MIGRATION_FILE y ejecutarlo manualmente en Supabase Dashboard"
        echo "   3. Usar Supabase CLI con 'supabase db push' en un proyecto inicializado"
        exit 1
    fi
fi

echo ""
echo "🎉 ¡Migración de Gestión de Usuarios completada!"
echo ""
echo "📋 Resumen de lo que se creó:"
echo "   ✅ Tabla user_profiles - Perfiles extendidos de usuario"
echo "   ✅ Tabla user_roles - Roles de usuario"
echo "   ✅ Tabla user_permissions - Permisos específicos"
echo "   ✅ Tabla user_sessions - Sesiones de usuario"
echo "   ✅ Tabla user_activities - Log de actividades"
echo "   ✅ Vista users_complete - Vista completa de usuarios"
echo "   ✅ Función get_user_stats() - Estadísticas de usuarios"
echo "   ✅ Políticas RLS - Seguridad a nivel de fila"
echo "   ✅ Triggers - Automatización de logs"
echo ""
echo "🔧 Próximos pasos:"
echo "   1. Verificar que los componentes React funcionen correctamente"
echo "   2. Crear un usuario administrador inicial si es necesario"
echo "   3. Configurar roles y permisos según tu organización"
echo ""
echo "📚 Documentación: Ver MODULO_USUARIOS_DOCUMENTACION.md"
