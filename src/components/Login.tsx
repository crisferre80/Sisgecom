import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Package, Mail, Lock, Eye, EyeOff, UserPlus } from 'lucide-react';
import { useAuth } from '../hooks/useAuth';

const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [isSignUp, setIsSignUp] = useState(false);
  const [name, setName] = useState('');
  const { signIn, signUp } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      if (isSignUp) {
        if (!name.trim()) {
          throw new Error('El nombre es requerido');
        }
        const { error } = await signUp(email, password, name);
        if (error) throw error;
        setError('');
        alert('Usuario creado exitosamente. Ahora puedes iniciar sesión.');
        setIsSignUp(false);
        setName('');
        setEmail('');
        setPassword('');
      } else {
        const { error } = await signIn(email, password);
        if (error) throw error;
        navigate('/');
      }
    } catch (error: any) {
      if (error.message.includes('Invalid login credentials')) {
        setError('Credenciales inválidas. Verifica tu email y contraseña, o crea una cuenta nueva.');
      } else {
        setError(error.message || 'Error en la operación');
      }
    } finally {
      setLoading(false);
    }
  };

  const createDemoUser = async () => {
    setLoading(true);
    setError('');
    
    try {
      const { error } = await signUp('admin@demo.com', 'admin123', 'Demo Admin');
      if (error) throw error;
      alert('Usuario demo creado exitosamente. Ahora puedes iniciar sesión con admin@demo.com / admin123');
      setEmail('admin@demo.com');
      setPassword('admin123');
    } catch (error: any) {
      if (error.message.includes('User already registered')) {
        setError('El usuario demo ya existe. Puedes iniciar sesión con admin@demo.com / admin123');
        setEmail('admin@demo.com');
        setPassword('admin123');
      } else {
        setError(error.message || 'Error al crear usuario demo');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div className="text-center">
          <div className="mx-auto h-16 w-16 bg-blue-600 rounded-full flex items-center justify-center">
            <Package className="h-8 w-8 text-white" />
          </div>
          <h2 className="mt-6 text-3xl font-bold text-gray-900">InventoryPro</h2>
          <p className="mt-2 text-sm text-gray-600">Sistema de Gestión de Inventario</p>
        </div>

        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          <div className="bg-white rounded-lg shadow-lg p-8 space-y-6">
            <div>
              <h3 className="text-lg font-medium text-gray-900 mb-4">
                {isSignUp ? 'Crear Cuenta' : 'Iniciar Sesión'}
              </h3>
              
              {error && (
                <div className="mb-4 bg-red-50 border border-red-200 rounded-md p-4">
                  <p className="text-sm text-red-600">{error}</p>
                </div>
              )}

              <div className="space-y-4">
                {isSignUp && (
                  <div>
                    <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                      Nombre Completo
                    </label>
                    <div className="mt-1 relative">
                      <input
                        id="name"
                        type="text"
                        required={isSignUp}
                        value={name}
                        onChange={(e) => setName(e.target.value)}
                        className="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                        placeholder="Tu nombre completo"
                      />
                    </div>
                  </div>
                )}

                <div>
                  <label htmlFor="email" className="block text-sm font-medium text-gray-700">
                    Correo Electrónico
                  </label>
                  <div className="mt-1 relative">
                    <Mail className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-5 w-5" />
                    <input
                      id="email"
                      type="email"
                      required
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      className="pl-10 w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                      placeholder="usuario@ejemplo.com"
                    />
                  </div>
                </div>

                <div>
                  <label htmlFor="password" className="block text-sm font-medium text-gray-700">
                    Contraseña
                  </label>
                  <div className="mt-1 relative">
                    <Lock className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-5 w-5" />
                    <input
                      id="password"
                      type={showPassword ? 'text' : 'password'}
                      required
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      className="pl-10 pr-10 w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                      placeholder="••••••••"
                      minLength={isSignUp ? 6 : undefined}
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-500"
                    >
                      {showPassword ? (
                        <EyeOff className="h-5 w-5" />
                      ) : (
                        <Eye className="h-5 w-5" />
                      )}
                    </button>
                  </div>
                  {isSignUp && (
                    <p className="mt-1 text-xs text-gray-500">Mínimo 6 caracteres</p>
                  )}
                </div>
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full flex justify-center py-3 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? 
                (isSignUp ? 'Creando cuenta...' : 'Iniciando sesión...') : 
                (isSignUp ? 'Crear Cuenta' : 'Iniciar Sesión')
              }
            </button>

            <div className="text-center space-y-3">
              <button
                type="button"
                onClick={() => {
                  setIsSignUp(!isSignUp);
                  setError('');
                  setEmail('');
                  setPassword('');
                  setName('');
                }}
                className="text-sm font-medium text-blue-600 hover:text-blue-500"
              >
                {isSignUp ? '¿Ya tienes cuenta? Inicia sesión' : '¿No tienes cuenta? Regístrate'}
              </button>

              {!isSignUp && (
                <div className="border-t pt-3">
                  <button
                    type="button"
                    onClick={createDemoUser}
                    disabled={loading}
                    className="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
                  >
                    <UserPlus className="h-4 w-4 mr-2" />
                    Crear Usuario Demo
                  </button>
                  <p className="mt-2 text-xs text-gray-500">
                    Crea un usuario de prueba: admin@demo.com / admin123
                  </p>
                </div>
              )}
            </div>
          </div>
        </form>
      </div>
    </div>
  );
};

export default Login;