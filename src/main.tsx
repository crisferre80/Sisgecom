import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App.tsx';
import './index.css';

// Debug de variables de entorno (solo para diagnóstico)
if (import.meta.env.DEV || import.meta.env.MODE === 'development') {
  import('./lib/debug-env').then(({ debugEnvironment }) => {
    debugEnvironment();
  });
}

// Verificar variables críticas antes de renderizar
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('🚨 VARIABLES DE ENTORNO FALTANTES');
  console.error('VITE_SUPABASE_URL:', supabaseUrl || 'UNDEFINED');
  console.error('VITE_SUPABASE_ANON_KEY:', supabaseKey ? 'DEFINED' : 'UNDEFINED');
  
  // Mostrar mensaje de error en la página
  document.getElementById('root')!.innerHTML = `
    <div style="padding: 20px; background: #fee2e2; border: 1px solid #dc2626; border-radius: 8px; margin: 20px; font-family: Arial, sans-serif;">
      <h2 style="color: #dc2626; margin: 0 0 10px 0;">🚨 Error de Configuración</h2>
      <p><strong>Variables de entorno faltantes:</strong></p>
      <ul>
        <li>VITE_SUPABASE_URL: ${supabaseUrl || '❌ NO DEFINIDA'}</li>
        <li>VITE_SUPABASE_ANON_KEY: ${supabaseKey ? '✅ DEFINIDA' : '❌ NO DEFINIDA'}</li>
      </ul>
      <p><strong>Para solucionarlo:</strong></p>
      <ol>
        <li>Ve a Netlify → Site settings → Environment variables</li>
        <li>Agrega las variables VITE_SUPABASE_URL y VITE_SUPABASE_ANON_KEY</li>
        <li>Haz un nuevo deploy</li>
      </ol>
      <p style="margin: 15px 0 0 0;">
        <button onclick="location.reload()" style="background: #dc2626; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer;">
          Recargar Página
        </button>
      </p>
    </div>
  `;
} else {
  createRoot(document.getElementById('root')!).render(
    <StrictMode>
      <App />
    </StrictMode>
  );
}
