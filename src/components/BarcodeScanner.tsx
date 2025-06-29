import React, { useEffect, useRef, useState } from 'react';
import { Html5QrcodeScanner } from 'html5-qrcode';
import { X, Camera, AlertCircle } from 'lucide-react';

interface BarcodeScannerProps {
  onScan: (result: string) => void;
  onClose: () => void;
}

const BarcodeScanner: React.FC<BarcodeScannerProps> = ({ onScan, onClose }) => {
  const scannerRef = useRef<Html5QrcodeScanner | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isInitializing, setIsInitializing] = useState(true);

  useEffect(() => {
    const initializeScanner = async () => {
      try {
        setIsInitializing(true);
        setError(null);

        // Verificar si el navegador soporta getUserMedia
        if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
          throw new Error('Su navegador no soporta el acceso a la cámara');
        }

        // Solicitar permisos de cámara explícitamente
        try {
          await navigator.mediaDevices.getUserMedia({ video: true });
        } catch {
          throw new Error('Se requiere permiso para acceder a la cámara. Por favor, permita el acceso y recargue la página.');
        }

        const config = {
          fps: 10,
          qrbox: { width: 250, height: 250 },
          aspectRatio: 1.0,
          showTorchButtonIfSupported: true,
          showZoomSliderIfSupported: true,
          defaultZoomValueIfSupported: 2,
        };

        const scanner = new Html5QrcodeScanner('qr-reader', config, false);
        scannerRef.current = scanner;

        scanner.render(
          (decodedText) => {
            onScan(decodedText);
            scanner.clear();
          },
          (error) => {
            // Solo mostrar errores relevantes, no todos los errores de lectura
            if (error.includes('NotAllowedError') || error.includes('NotFoundError')) {
              setError('Error de cámara: ' + error);
            }
          }
        );

        setIsInitializing(false);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Error desconocido al inicializar el escáner');
        setIsInitializing(false);
      }
    };

    initializeScanner();

    return () => {
      if (scannerRef.current) {
        scannerRef.current.clear().catch(console.error);
      }
    };
  }, [onScan]);

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" onClick={onClose} />
        
        <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
          <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center">
                <Camera className="h-6 w-6 text-blue-600 mr-2" />
                <h3 className="text-lg font-medium text-gray-900">Escanear Código de Barras</h3>
              </div>
              <button
                onClick={onClose}
                className="text-gray-400 hover:text-gray-500"
              >
                <X className="h-6 w-6" />
              </button>
            </div>
            
            <div className="space-y-4">
              <p className="text-sm text-gray-600">
                Apunte la cámara hacia el código de barras para escanearlo automáticamente.
              </p>
              
              {error && (
                <div className="space-y-3">
                  <div className="flex items-center p-3 bg-red-50 border border-red-200 rounded-md">
                    <AlertCircle className="h-5 w-5 text-red-500 mr-2 flex-shrink-0" />
                    <p className="text-sm text-red-700">{error}</p>
                  </div>
                  <button
                    onClick={() => window.location.reload()}
                    className="w-full inline-flex justify-center rounded-md border border-blue-300 shadow-sm px-4 py-2 bg-blue-50 text-base font-medium text-blue-700 hover:bg-blue-100 sm:text-sm"
                  >
                    Reintentar
                  </button>
                </div>
              )}
              
              {isInitializing && !error && (
                <div className="flex items-center justify-center p-8">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                  <span className="ml-2 text-sm text-gray-600">Iniciando cámara...</span>
                </div>
              )}
              
              <div id="qr-reader" className="w-full"></div>
            </div>
          </div>
          
          <div className="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
            <button
              onClick={onClose}
              className="w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
            >
              Cancelar
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default BarcodeScanner;