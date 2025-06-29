// Script para verificar variables de entorno en el navegador (solo para desarrollo/debug)
export const debugEnvironment = () => {
  if (typeof window !== 'undefined') {
    console.group('🔍 DEBUG: Variables de Entorno');
    
    const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
    const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
    
    console.log('VITE_SUPABASE_URL:', supabaseUrl || '❌ UNDEFINED');
    console.log('VITE_SUPABASE_ANON_KEY:', supabaseKey ? '✅ DEFINED' : '❌ UNDEFINED');
    
    if (!supabaseUrl || !supabaseKey) {
      console.error('🚨 VARIABLES DE ENTORNO FALTANTES');
      console.error('Esto causará el error: "supabaseUrl is required"');
      console.error('Verifica la configuración en Netlify:');
      console.error('1. Site settings → Environment variables');
      console.error('2. Agrega VITE_SUPABASE_URL y VITE_SUPABASE_ANON_KEY');
      console.error('3. Haz un nuevo deploy');
    } else {
      console.log('✅ Variables de entorno configuradas correctamente');
    }
    
    // Mostrar todas las variables VITE_*
    console.log('📋 Todas las variables VITE_*:');
    Object.keys(import.meta.env)
      .filter(key => key.startsWith('VITE_'))
      .forEach(key => {
        console.log(`  ${key}:`, import.meta.env[key] ? '✅ DEFINED' : '❌ UNDEFINED');
      });
    
    console.groupEnd();
  }
};

// Función para mostrar el estado en la interfaz
export const showEnvironmentStatus = () => {
  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
  const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
  
  if (!supabaseUrl || !supabaseKey) {
    // Mostrar un banner de error en la interfaz
    const errorBanner = document.createElement('div');
    errorBanner.style.cssText = `
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      background: #dc2626;
      color: white;
      padding: 10px;
      text-align: center;
      z-index: 9999;
      font-family: Arial, sans-serif;
    `;
    errorBanner.innerHTML = `
      🚨 ERROR DE CONFIGURACIÓN: Variables de entorno faltantes. 
      <a href="#" onclick="this.parentElement.style.display='none'" style="color: white; margin-left: 10px;">[Cerrar]</a>
    `;
    document.body.insertBefore(errorBanner, document.body.firstChild);
  }
};
