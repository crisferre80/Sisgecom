// Test simple para verificar que la utilidad de diagnóstico funciona
import { diagnosticInventoryAlerts } from './src/utils/diagnosticInventoryAlerts.js';

console.log('🧪 Ejecutando test de diagnóstico...');

diagnosticInventoryAlerts()
  .then(result => {
    console.log('📊 Resultado del diagnóstico:');
    console.log(JSON.stringify(result, null, 2));
    
    if (result.success) {
      console.log('✅ Test exitoso - La utilidad funciona correctamente');
    } else {
      console.log('❌ Test falló - Hay problemas con inventory_alerts');
      console.log('💡 Ejecute: powershell -ExecutionPolicy Bypass -File apply-configuration-migration.ps1');
    }
  })
  .catch(error => {
    console.error('💥 Error en el test:', error);
  });
