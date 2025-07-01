import React, { useState, useEffect } from 'react';
import { AlertTriangle, CheckCircle, XCircle } from 'lucide-react';

interface DiagnosticResult {
  success: boolean;
  message?: string;
  error?: string;
  warning?: string;
}

const InventoryAlertsDiagnostic: React.FC = () => {
  const [result, setResult] = useState<DiagnosticResult | null>(null);
  const [loading, setLoading] = useState(false);

  const runDiagnostic = async () => {
    setLoading(true);
    try {
      // Importar dinámicamente la función de diagnóstico
      const { diagnosticInventoryAlerts } = await import('../utils/diagnosticInventoryAlerts');
      const diagnosticResult = await diagnosticInventoryAlerts();
      setResult(diagnosticResult);
    } catch (error) {
      setResult({
        success: false,
        error: `Error al ejecutar diagnóstico: ${error instanceof Error ? error.message : 'Error desconocido'}`
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    runDiagnostic();
  }, []);

  const getIcon = () => {
    if (loading) return <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-blue-600"></div>;
    if (result?.success) return <CheckCircle className="h-5 w-5 text-green-600" />;
    if (result?.warning) return <AlertTriangle className="h-5 w-5 text-yellow-600" />;
    return <XCircle className="h-5 w-5 text-red-600" />;
  };

  const getBgColor = () => {
    if (result?.success) return 'bg-green-50 border-green-200';
    if (result?.warning) return 'bg-yellow-50 border-yellow-200';
    return 'bg-red-50 border-red-200';
  };

  const getTextColor = () => {
    if (result?.success) return 'text-green-800';
    if (result?.warning) return 'text-yellow-800';
    return 'text-red-800';
  };

  return (
    <div className={`border rounded-lg p-4 ${getBgColor()}`}>
      <div className="flex items-center space-x-3">
        {getIcon()}
        <div className="flex-1">
          <h3 className={`text-sm font-medium ${getTextColor()}`}>
            Diagnóstico de Alertas de Inventario
          </h3>
          
          {loading && (
            <p className="text-sm text-gray-600 mt-1">
              Verificando configuración de inventory_alerts...
            </p>
          )}
          
          {result && !loading && (
            <div className="mt-2">
              {result.success && result.message && (
                <p className="text-sm text-green-700">{result.message}</p>
              )}
              
              {result.warning && (
                <p className="text-sm text-yellow-700">⚠️ {result.warning}</p>
              )}
              
              {result.error && (
                <div className="text-sm text-red-700">
                  <p className="font-medium">❌ {result.error}</p>
                  
                  {result.error.includes('no existe') && (
                    <div className="mt-2 p-3 bg-red-100 rounded border border-red-200">
                      <p className="font-medium text-red-800">💡 Solución:</p>
                      <ol className="list-decimal list-inside text-red-700 mt-1 space-y-1">
                        <li>Ejecute el script: <code className="bg-red-200 px-1 rounded">apply-configuration-migration.ps1</code></li>
                        <li>O manualmente: <code className="bg-red-200 px-1 rounded">npx supabase db push</code></li>
                        <li>Verifique que las migraciones se aplicaron correctamente</li>
                      </ol>
                    </div>
                  )}
                  
                  {result.error.includes('permisos') && (
                    <div className="mt-2 p-3 bg-red-100 rounded border border-red-200">
                      <p className="font-medium text-red-800">💡 Solución:</p>
                      <ol className="list-decimal list-inside text-red-700 mt-1 space-y-1">
                        <li>Verifique la configuración de RLS (Row Level Security)</li>
                        <li>Asegúrese de que el usuario tiene permisos adecuados</li>
                        <li>Revise las políticas de seguridad en Supabase</li>
                      </ol>
                    </div>
                  )}
                </div>
              )}
            </div>
          )}
        </div>
        
        <button
          onClick={runDiagnostic}
          disabled={loading}
          className="px-3 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
        >
          {loading ? 'Verificando...' : 'Revisar'}
        </button>
      </div>
    </div>
  );
};

export default InventoryAlertsDiagnostic;
