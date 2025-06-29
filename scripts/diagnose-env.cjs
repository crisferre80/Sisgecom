#!/usr/bin/env node

/**
 * Script de diagnóstico para variables de entorno
 * Este script te ayuda a diagnosticar problemas con las variables de entorno
 */

// Cargar variables de entorno desde .env
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

console.log('🔍 DIAGNÓSTICO DE VARIABLES DE ENTORNO\n');
console.log('=' .repeat(50));

// 1. Verificar si el archivo .env existe
const fs = require('fs');
const envPath = path.join(__dirname, '..', '.env');
console.log(`📁 Archivo .env: ${envPath}`);
console.log(`📁 ¿Existe?: ${fs.existsSync(envPath) ? '✅ SÍ' : '❌ NO'}`);

if (fs.existsSync(envPath)) {
  const envContent = fs.readFileSync(envPath, 'utf8');
  console.log(`📁 Contenido del .env (primeras líneas):`);
  console.log(envContent.split('\n').slice(0, 3).map(line => `    ${line}`).join('\n'));
}

console.log('\n' + '=' .repeat(50));

// 2. Verificar variables específicas
const requiredVars = [
  'VITE_SUPABASE_URL',
  'VITE_SUPABASE_ANON_KEY'
];

console.log('🔍 VERIFICACIÓN DE VARIABLES:\n');

requiredVars.forEach(varName => {
  const value = process.env[varName];
  console.log(`${varName}:`);
  console.log(`  ¿Definida?: ${value ? '✅ SÍ' : '❌ NO'}`);
  if (value) {
    console.log(`  Longitud: ${value.length} caracteres`);
    console.log(`  Primeros chars: ${value.substring(0, 20)}...`);
    console.log(`  ¿Vacía?: ${value.trim() === '' ? '❌ SÍ' : '✅ NO'}`);
  }
  console.log('');
});

console.log('=' .repeat(50));

// 3. Mostrar todas las variables que empiezan con VITE_
console.log('🔍 TODAS LAS VARIABLES VITE_*:\n');
Object.keys(process.env)
  .filter(key => key.startsWith('VITE_'))
  .forEach(key => {
    const value = process.env[key];
    console.log(`${key}: ${value ? value.substring(0, 20) + '...' : 'UNDEFINED'}`);
  });

console.log('\n' + '=' .repeat(50));

// 4. Instrucciones para Netlify
console.log('📋 PARA CONFIGURAR EN NETLIFY:\n');
console.log('1. Ve a tu sitio en Netlify');
console.log('2. Site settings → Environment variables');
console.log('3. Agrega estas variables EXACTAMENTE:');
console.log('');
console.log('   Variable: VITE_SUPABASE_URL');
console.log('   Valor: https://iujpqyedxhbpqdifbmjy.supabase.co');
console.log('');
console.log('   Variable: VITE_SUPABASE_ANON_KEY');
console.log('   Valor: (copia el valor completo del .env)');
console.log('');
console.log('4. ¡IMPORTANTE! NO olvides hacer un nuevo deploy después');
console.log('');
console.log('🔧 VERIFICACIÓN ADICIONAL:');
console.log('- Asegúrate de que no hay espacios extra');
console.log('- Verifica que los nombres sean EXACTOS (case-sensitive)');
console.log('- El prefijo VITE_ es obligatorio para que Vite las incluya');
