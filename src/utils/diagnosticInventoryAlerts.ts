// Script de diagnóstico para el problema de inventory_alerts
import { supabase } from '../lib/supabase';

export const diagnosticInventoryAlerts = async () => {
  console.log('🔍 Iniciando diagnóstico de inventory_alerts...');
  
  try {
    // 1. Verificar si la tabla existe con una consulta directa más simple
    console.log('📋 Verificando si la tabla inventory_alerts existe...');
    
    // Intentar una consulta directa primero
    const { error: tableError } = await supabase
      .from('inventory_alerts')
      .select('*', { count: 'exact', head: true });
    
    if (tableError) {
      // Si hay error, es probable que la tabla no exista
      if (tableError.code === 'PGRST116' || tableError.message.includes('does not exist') || tableError.code === '42P01') {
        console.log('❌ La tabla inventory_alerts NO existe');
        return { 
          success: false, 
          error: 'La tabla inventory_alerts no existe. Debe aplicar la migración del módulo de configuración.' 
        };
      } else {
        console.error('❌ Error al verificar tabla:', tableError);
        return { success: false, error: `Error de conectividad o permisos: ${tableError.message}` };
      }
    }
    
    console.log('✅ La tabla inventory_alerts existe');
    
    // 2. Intentar hacer una consulta simple
    console.log('📊 Probando consulta básica a inventory_alerts...');
    
    const { count, error: countError } = await supabase
      .from('inventory_alerts')
      .select('*', { count: 'exact', head: true });
    
    if (countError) {
      console.error('❌ Error en consulta básica:', countError);
      return { 
        success: false, 
        error: `Error de permisos o configuración en inventory_alerts: ${countError.message}`
      };
    }
    
    console.log(`✅ Consulta básica exitosa. Total de alertas: ${count || 0}`);
    
    // 3. Probar consulta con JOIN (la que falla)
    console.log('🔗 Probando consulta con JOIN a products...');
    
    const { error: joinError } = await supabase
      .from('inventory_alerts')
      .select(`
        *,
        product:products(name, barcode, quantity, min_stock)
      `)
      .limit(1);
    
    if (joinError) {
      console.error('❌ Error en consulta con JOIN:', joinError);
      return { 
        success: false, 
        error: `Error en consulta con productos: ${joinError.message}`
      };
    }
    
    console.log('✅ Consulta con JOIN exitosa');
    
    // 4. Verificar tabla products
    console.log('📦 Verificando tabla products...');
    
    const { count: productsCount, error: productsError } = await supabase
      .from('products')
      .select('*', { count: 'exact', head: true });
    
    if (productsError) {
      console.warn('⚠️ Problema con tabla products:', productsError);
      return {
        success: true,
        warning: 'inventory_alerts funciona, pero products puede tener problemas'
      };
    }
    
    console.log(`✅ Tabla products OK. Total productos: ${productsCount || 0}`);
    
    return { 
      success: true, 
      message: 'inventory_alerts está configurado correctamente' 
    };
    
  } catch (error) {
    console.error('💥 Error inesperado en diagnóstico:', error);
    return { 
      success: false, 
      error: `Error inesperado: ${error instanceof Error ? error.message : 'Error desconocido'}`
    };
  }
};

// Función para mostrar el diagnóstico en el componente
export const showInventoryAlertsDiagnostic = async () => {
  const result = await diagnosticInventoryAlerts();
  
  if (result.success) {
    console.log('🎉', result.message || 'Diagnóstico completado exitosamente');
    if (result.warning) {
      console.warn('⚠️', result.warning);
    }
  } else {
    console.error('❌', result.error);
    alert(`Error en inventory_alerts: ${result.error}`);
  }
  
  return result;
};
