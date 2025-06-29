#!/bin/bash
# Script de instalación para Netlify

echo "🔍 Verificando entorno..."
echo "Node version: $(node --version)"
echo "NPM version: $(npm --version)"
echo "PWD: $(pwd)"

echo "📦 Instalando dependencias..."
npm ci --legacy-peer-deps

echo "✅ Dependencias instaladas correctamente"

echo "🚀 Iniciando build..."
npx vite build

echo "✅ Build completado"
