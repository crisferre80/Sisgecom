import React, { useRef, useEffect, useState } from 'react';
import { X, Camera, RotateCcw } from 'lucide-react';

interface NativeCameraScannerProps {
  onScan: (result: string) => void;
  onClose: () => void;
}

const NativeCameraScanner: React.FC<NativeCameraScannerProps> = ({ onScan, onClose }) => {
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [stream, setStream] = useState<MediaStream | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isCapturing, setIsCapturing] = useState(false);

  useEffect(() => {
    const initializeCamera = async () => {
      try {
        const mediaStream = await navigator.mediaDevices.getUserMedia({
          video: {
            facingMode: 'environment',
            width: { ideal: 1280 },
            height: { ideal: 720 }
          }
        });

        if (videoRef.current) {
          videoRef.current.srcObject = mediaStream;
          setStream(mediaStream);
        }
      } catch (err) {
        setError('No se pudo acceder a la cámara: ' + (err instanceof Error ? err.message : 'Error desconocido'));
      }
    };

    initializeCamera();

    return () => {
      // El cleanup se manejará cuando el componente se desmonte
    };
  }, []);

  useEffect(() => {
    return () => {
      if (stream) {
        stream.getTracks().forEach(track => track.stop());
      }
    };
  }, [stream]);

  const captureImage = () => {
    if (!videoRef.current || !canvasRef.current) return;

    const video = videoRef.current;
    const canvas = canvasRef.current;
    const context = canvas.getContext('2d');

    if (!context) return;

    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    context.drawImage(video, 0, 0);

    // Imagen capturada, permitir entrada manual
    setIsCapturing(true);
  };

  const handleManualInput = () => {
    const input = prompt('Ingrese el código de barras manualmente:');
    if (input && input.trim()) {
      onScan(input.trim());
    }
    setIsCapturing(false);
  };

  if (error) {
    return (
      <div className="fixed inset-0 z-50 overflow-y-auto">
        <div className="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
          <div className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" onClick={onClose} />
          
          <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
            <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-medium text-gray-900">Error de Cámara</h3>
                <button onClick={onClose} className="text-gray-400 hover:text-gray-500">
                  <X className="h-6 w-6" />
                </button>
              </div>
              
              <div className="space-y-4">
                <p className="text-sm text-red-600">{error}</p>
                <button
                  onClick={handleManualInput}
                  className="w-full inline-flex justify-center rounded-md border border-blue-300 shadow-sm px-4 py-2 bg-blue-50 text-base font-medium text-blue-700 hover:bg-blue-100 sm:text-sm"
                >
                  Ingresar Código Manualmente
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" onClick={onClose} />
        
        <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
          <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center">
                <Camera className="h-6 w-6 text-blue-600 mr-2" />
                <h3 className="text-lg font-medium text-gray-900">Cámara Nativa</h3>
              </div>
              <button onClick={onClose} className="text-gray-400 hover:text-gray-500">
                <X className="h-6 w-6" />
              </button>
            </div>
            
            <div className="space-y-4">
              <p className="text-sm text-gray-600">
                Capture una imagen del código de barras y luego ingrese el código manualmente.
              </p>
              
              <div className="relative">
                <video
                  ref={videoRef}
                  autoPlay
                  playsInline
                  className="w-full rounded-lg"
                  style={{ maxHeight: '300px' }}
                />
                <canvas ref={canvasRef} className="hidden" />
              </div>
              
              {isCapturing ? (
                <div className="space-y-2">
                  <p className="text-sm text-green-600">Imagen capturada. Ingrese el código:</p>
                  <button
                    onClick={handleManualInput}
                    className="w-full inline-flex justify-center rounded-md border border-green-300 shadow-sm px-4 py-2 bg-green-50 text-base font-medium text-green-700 hover:bg-green-100 sm:text-sm"
                  >
                    Ingresar Código
                  </button>
                  <button
                    onClick={() => setIsCapturing(false)}
                    className="w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 sm:text-sm"
                  >
                    <RotateCcw className="h-4 w-4 mr-2" />
                    Capturar Otra Vez
                  </button>
                </div>
              ) : (
                <button
                  onClick={captureImage}
                  className="w-full inline-flex justify-center rounded-md border border-blue-300 shadow-sm px-4 py-2 bg-blue-50 text-base font-medium text-blue-700 hover:bg-blue-100 sm:text-sm"
                >
                  <Camera className="h-4 w-4 mr-2" />
                  Capturar Imagen
                </button>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default NativeCameraScanner;
