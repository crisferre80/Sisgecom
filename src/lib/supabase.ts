import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

// Modo demo cuando no hay variables configuradas
const DEMO_MODE = !supabaseUrl || !supabaseKey;

if (DEMO_MODE) {
  console.warn('🚨 MODO DEMO: Variables de entorno no configuradas');
  console.warn('Para configurar Supabase:');
  console.warn('1. Ve a Netlify Dashboard → Site settings → Environment variables');
  console.warn('2. Agrega VITE_SUPABASE_URL y VITE_SUPABASE_ANON_KEY');
  console.warn('3. Redeploy el sitio');
}

// Crear cliente con valores por defecto para modo demo
const finalUrl = supabaseUrl || 'https://demo.supabase.co';
const finalKey = supabaseKey || 'demo-key';

export const supabase = createClient(finalUrl, finalKey);

// Auth helpers
export const signIn = async (email: string, password: string) => {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });
  return { data, error };
};

export const signUp = async (email: string, password: string, name: string) => {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        name: name,
        role: 'cashier'
      }
    }
  });
  return { data, error };
};

export const signOut = async () => {
  const { error } = await supabase.auth.signOut();
  return { error };
};

export const getCurrentUser = async () => {
  const { data: { user } } = await supabase.auth.getUser();
  return user;
};