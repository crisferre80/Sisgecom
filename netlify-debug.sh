#!/bin/bash

echo "🔍 Diagnóstico de Build para Netlify"
echo "=================================="

# Verificar Node.js
echo "📍 Versión de Node.js:"
node --version

# Verificar NPM
echo "📍 Versión de NPM:"
npm --version

# Verificar directorio actual
echo "📍 Directorio de trabajo:"
pwd

# Listar archivos importantes
echo "📍 Archivos en el directorio raíz:"
ls -la

# Verificar package.json
echo "📍 Contenido de package.json (scripts):"
cat package.json | grep -A 10 '"scripts"'

# Verificar dependencias
echo "📍 Instalando dependencias..."
npm ci --verbose

# Verificar build
echo "📍 Ejecutando build..."
npm run build-only

echo "✅ Diagnóstico completado"
