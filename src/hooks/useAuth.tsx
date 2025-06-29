import React, { createContext, useContext, useEffect, useState } from 'react';
import { User } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';

interface AuthContextType {
  user: User | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<{ data: { user: User | null } | null; error: Error | null }>;
  signUp: (email: string, password: string, name: string) => Promise<{ data: { user: User | null } | null; error: Error | null }>;
  signOut: () => Promise<void>;
}

export const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  // Detectar modo demo
  const isDemoMode = !import.meta.env.VITE_SUPABASE_URL || !import.meta.env.VITE_SUPABASE_ANON_KEY;

  useEffect(() => {
    if (isDemoMode) {
      // En modo demo, no intentar conectar a Supabase
      setLoading(false);
      return;
    }

    const getUser = async () => {
      try {
        const { data: { user } } = await supabase.auth.getUser();
        setUser(user);
      } catch (error) {
        console.warn('Error obteniendo usuario:', error);
      }
      setLoading(false);
    };

    getUser();

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_, session) => {
      setUser(session?.user ?? null);
      setLoading(false);
    });

    return () => subscription.unsubscribe();
  }, [isDemoMode]);

  const signIn = async (email: string, password: string): Promise<{ data: { user: User | null } | null; error: Error | null }> => {
    if (isDemoMode) {
      // Simular login exitoso en modo demo
      const demoUser = {
        id: 'demo-user',
        email: 'demo@example.com',
        user_metadata: { name: 'Usuario Demo', role: 'admin' },
        app_metadata: {},
        aud: 'authenticated',
        created_at: new Date().toISOString()
      } as User;
      setUser(demoUser);
      return { data: { user: demoUser }, error: null };
    }

    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      // Normalize the return type
      if (error) {
        return { data: null, error: error as Error };
      }

      // data?.user may be undefined, so ensure it is User | null
      return { data: { user: data?.user ?? null }, error: null };
    } catch (error) {
      return { data: null, error: error instanceof Error ? error : new Error(String(error)) };
    }
  };

  const signUp = async (
    email: string,
    password: string,
    name: string
  ): Promise<{ data: { user: User | null } | null; error: Error | null }> => {
    if (isDemoMode) {
      // En modo demo, simular registro exitoso
      return { data: { user: null }, error: null };
    }

    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: { name, role: 'cashier' }
        }
      });

      // Normalize the return type
      if (error) {
        return { data: null, error: error as Error };
      }

      // data?.user may be undefined, so ensure it is User | null
      return { data: { user: data?.user ?? null }, error: null };
    } catch (error) {
      return { data: null, error: error instanceof Error ? error : new Error(String(error)) };
    }
  };

  const signOut = async () => {
    if (isDemoMode) {
      setUser(null);
      return;
    }
    
    try {
      await supabase.auth.signOut();
    } catch (error) {
      console.warn('Error cerrando sesión:', error);
    }
  };

  return (
    <AuthContext.Provider value={{ user, loading, signIn, signUp, signOut }}>
      {children}
    </AuthContext.Provider>
  );
};

// eslint-disable-next-line react-refresh/only-export-components
export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth debe ser usado dentro de un AuthProvider');
  }
  return context;
};