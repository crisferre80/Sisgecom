import React from 'react';
import { AlertTriangle, Settings, ExternalLink } from 'lucide-react';

interface DemoWarningProps {
  show: boolean;
}

const DemoWarning: React.FC<DemoWarningProps> = ({ show }) => {
  if (!show) return null;

  return (
    <div className="fixed top-0 left-0 right-0 z-50 bg-amber-600 text-white p-4 shadow-lg">
      <div className="max-w-7xl mx-auto flex items-center justify-between">
        <div className="flex items-center space-x-3">
          <AlertTriangle className="h-5 w-5 flex-shrink-0" />
          <div>
            <p className="font-semibold">Modo Demo - Supabase No Configurado</p>
            <p className="text-sm opacity-90">
              La aplicación está en modo demo. Para usar todas las funciones, configura las variables de entorno.
            </p>
          </div>
        </div>
        
        <div className="hidden md:flex items-center space-x-4">
          <div className="text-sm">
            <p className="font-medium">Variables requeridas:</p>
            <p className="font-mono text-xs">VITE_SUPABASE_URL</p>
            <p className="font-mono text-xs">VITE_SUPABASE_ANON_KEY</p>
          </div>
          
          <a
            href="https://app.netlify.com"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center space-x-1 bg-amber-700 hover:bg-amber-800 px-3 py-2 rounded-md text-sm font-medium transition-colors"
          >
            <Settings className="h-4 w-4" />
            <span>Configurar en Netlify</span>
            <ExternalLink className="h-3 w-3" />
          </a>
        </div>
      </div>
    </div>
  );
};

export default DemoWarning;
