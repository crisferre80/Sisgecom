#!/bin/bash

# Script para aplicar la migración del módulo de configuración
# Este script debe ejecutarse desde la raíz del proyecto

echo "🔧 Aplicando migración del módulo de configuración..."

# Verificar que Supabase CLI esté instalado
if ! command -v supabase &> /dev/null; then
    echo "❌ Error: Supabase CLI no está instalado"
    echo "   Instálalo con: npm install -g supabase"
    exit 1
fi

# Verificar que estemos en un proyecto Supabase
if [ ! -f "supabase/config.toml" ]; then
    echo "❌ Error: No se encontró configuración de Supabase"
    echo "   Asegúrate de estar en el directorio raíz del proyecto"
    exit 1
fi

# Aplicar la migración
echo "📊 Aplicando migración de configuración..."
supabase db push

if [ $? -eq 0 ]; then
    echo "✅ Migración aplicada exitosamente"
    echo ""
    echo "📋 El módulo de configuración incluye:"
    echo "   • Configuración de empresa"
    echo "   • Configuración del sistema"
    echo "   • Plantillas de notificaciones"
    echo "   • Configuración de respaldos"
    echo "   • Logs de auditoría"
    echo "   • Alertas de inventario"
    echo ""
    echo "🔐 Políticas de seguridad configuradas para:"
    echo "   • Solo administradores pueden modificar configuraciones críticas"
    echo "   • Configuraciones públicas visibles para usuarios autenticados"
    echo "   • Auditoría automática de cambios"
    echo ""
    echo "🎯 Próximos pasos:"
    echo "   1. Verificar que la aplicación compile sin errores"
    echo "   2. Probar el módulo de configuración en el frontend"
    echo "   3. Revisar los logs de auditoría"
else
    echo "❌ Error al aplicar la migración"
    echo "   Revisa los logs de Supabase para más detalles"
    exit 1
fi
