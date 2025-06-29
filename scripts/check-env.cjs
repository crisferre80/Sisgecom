#!/usr/bin/env node

/**
 * Script para verificar variables de entorno requeridas antes del build
 */

// Cargar variables de entorno desde .env
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const requiredEnvVars = [
  'VITE_SUPABASE_URL',
  'VITE_SUPABASE_ANON_KEY'
];

console.log('🔍 Verificando variables de entorno...\n');

let hasError = false;

requiredEnvVars.forEach(varName => {
  const value = process.env[varName];
  
  if (!value || value.trim() === '') {
    console.error(`❌ ERROR: La variable de entorno ${varName} no está definida o está vacía.`);
    hasError = true;
  } else {
    // Mostrar solo los primeros caracteres por seguridad
    const maskedValue = value.length > 10 
      ? `${value.substring(0, 10)}...` 
      : value;
    console.log(`✅ ${varName}: ${maskedValue}`);
  }
});

if (hasError) {
  console.error('\n❌ Faltan variables de entorno requeridas.');
  console.error('\n📋 Para solucionarlo:');
  console.error('1. Verifica que el archivo .env existe en la raíz del proyecto');
  console.error('2. Asegúrate de que contiene todas las variables requeridas');
  console.error('3. Si estás desplegando en Netlify, configura las variables en el panel de administración');
  console.error('\n📖 Consulta NETLIFY_SETUP.md para más información.');
  
  // En CI/CD (como Netlify), no fallar el build, solo advertir
  if (process.env.CI || process.env.NETLIFY) {
    console.warn('\n⚠️  Build continuará, pero la aplicación mostrará errores en runtime.');
    console.warn('🔧 Configura las variables de entorno en Netlify para solucionarlo.');
  } else {
    process.exit(1);
  }
} else {
  console.log('\n✅ Todas las variables de entorno requeridas están configuradas correctamente.');
  console.log('🚀 Procediendo con el build...\n');
}
