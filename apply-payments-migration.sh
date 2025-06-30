#!/bin/bash

# Script para aplicar las migraciones del módulo de pagos
echo "🚀 Aplicando migraciones del módulo de pagos..."

# Verificar si supabase CLI está instalado
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI no está instalado"
    echo "📥 Instálelo con: npm install -g supabase"
    exit 1
fi

# Verificar si existe el archivo de migración
MIGRATION_FILE="supabase/migrations/20250629050000_payments_module.sql"
if [ ! -f "$MIGRATION_FILE" ]; then
    echo "❌ No se encontró el archivo de migración: $MIGRATION_FILE"
    exit 1
fi

echo "📄 Archivo de migración encontrado: $MIGRATION_FILE"

# Aplicar migración usando supabase CLI
echo "⚡ Aplicando migración..."
supabase db push

if [ $? -eq 0 ]; then
    echo "✅ Migración aplicada exitosamente"
    echo ""
    echo "🎯 Tablas creadas:"
    echo "   - customers (clientes)"
    echo "   - virtual_wallets (billeteras virtuales)"
    echo "   - payments (pagos)"
    echo "   - payment_reminders (recordatorios)"
    echo "   - whatsapp_contacts (contactos WhatsApp)"
    echo ""
    echo "🔧 Funciones automáticas:"
    echo "   - Actualización automática de deuda total"
    echo "   - Triggers para timestamps"
    echo "   - Índices para optimización"
    echo ""
    echo "📊 Datos de ejemplo insertados para testing"
    echo ""
    echo "🚀 El módulo de pagos está listo para usar!"
else
    echo "❌ Error al aplicar la migración"
    exit 1
fi
