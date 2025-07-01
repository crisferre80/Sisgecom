import React, { useState, useRef, useEffect, useCallback } from 'react';
import {
  Save,
  Edit2,
  Eye,
  EyeOff,
  Lock,
  Trash2
} from 'lucide-react';
import { useAuth } from '../hooks/useAuth';
import { supabase } from '../lib/supabase';

interface UserProfileData {
  id: string;
  email: string;
  full_name: string;
  first_name?: string;
  last_name?: string;
  phone?: string;
  address?: string;
  city?: string;
  country?: string;
  role: string;
  avatar_url?: string;
  created_at: string;
  last_login?: string;
}

const UserProfile: React.FC = () => {
  const { user } = useAuth();
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [showPasswordForm, setShowPasswordForm] = useState(false);
  const [profileData, setProfileData] = useState<UserProfileData | null>(null);
  const [message, setMessage] = useState<{ type: 'success' | 'error' | 'info'; text: string } | null>(null);
  const [avatarFile, setAvatarFile] = useState<File | null>(null);
  const [avatarPreview, setAvatarPreview] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Formulario de perfil
  const [profileForm, setProfileForm] = useState({
    full_name: '',
    first_name: '',
    last_name: '',
    phone: '',
    address: '',
    city: '',
    country: ''
  });

  // Formulario de cambio de contraseña
  const [passwordForm, setPasswordForm] = useState({
    currentPassword: '',
    newPassword: '',
    confirmPassword: ''
  });

  const [showPasswords, setShowPasswords] = useState({
    current: false,
    new: false,
    confirm: false
  });

  // Detectar modo demo
  const isDemoMode = !import.meta.env.VITE_SUPABASE_URL || !import.meta.env.VITE_SUPABASE_ANON_KEY;

  const showMessage = (type: 'success' | 'error' | 'info', text: string) => {
    setMessage({ type, text });
    setTimeout(() => setMessage(null), 5000);
  };

  // Función para obtener URL válida del avatar existente
  const getValidAvatarUrl = useCallback(async (avatarUrl: string | null | undefined): Promise<string | null> => {
    if (!avatarUrl || !user || isDemoMode) return null;
    
    // Si ya es una URL firmada válida, devolverla
    if (avatarUrl.includes('token=')) {
      return avatarUrl;
    }
    
    try {
      // Si es una URL pública, intentar obtener una URL firmada
      const fileExt = avatarUrl.split('.').pop()?.split('?')[0]; // Remover query params si existen
      const fileName = `${user.id}.${fileExt}`;
      const filePath = `avatars/${fileName}`;
      
      const { data: signedData, error: signedError } = await supabase.storage
        .from('user-avatars')
        .createSignedUrl(filePath, 60 * 60 * 24 * 365); // 1 año
        
      if (signedData && !signedError) {
        console.log('URL firmada regenerada:', signedData.signedUrl);
        return signedData.signedUrl;
      }
    } catch (error) {
      console.error('Error generando URL firmada:', error);
    }
    
    return avatarUrl; // Devolver la original como fallback
  }, [user, isDemoMode]);

  const loadUserProfile = useCallback(async () => {
    if (isDemoMode || !user) {
      // Datos demo para el perfil
      const demoProfile: UserProfileData = {
        id: 'demo-user',
        email: 'demo@example.com',
        full_name: 'Usuario Demo',
        first_name: 'Usuario',
        last_name: 'Demo',
        phone: '+1234567890',
        address: '123 Demo Street',
        city: 'Demo City',
        country: 'Demo Country',
        role: 'admin',
        created_at: new Date().toISOString(),
        last_login: new Date().toISOString()
      };
      setProfileData(demoProfile);
      setProfileForm({
        full_name: demoProfile.full_name,
        first_name: demoProfile.first_name || '',
        last_name: demoProfile.last_name || '',
        phone: demoProfile.phone || '',
        address: demoProfile.address || '',
        city: demoProfile.city || '',
        country: demoProfile.country || ''
      });
      return;
    }

    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', user.id)
        .single();

      if (error) throw error;

      if (data) {
        // Obtener URL válida para el avatar si existe
        let validAvatarUrl = data.avatar_url;
        if (data.avatar_url) {
          validAvatarUrl = await getValidAvatarUrl(data.avatar_url);
        }
        
        const profileWithValidAvatar = {
          ...data,
          avatar_url: validAvatarUrl
        };
        
        setProfileData(profileWithValidAvatar);
        setProfileForm({
          full_name: data.full_name || '',
          first_name: data.first_name || '',
          last_name: data.last_name || '',
          phone: data.phone || '',
          address: data.address || '',
          city: data.city || '',
          country: data.country || ''
        });
      }
    } catch (error) {
      console.error('Error loading profile:', error);
      showMessage('error', 'Error al cargar el perfil');
    } finally {
      setLoading(false);
    }
  }, [isDemoMode, user, getValidAvatarUrl]);

  useEffect(() => {
    if (user) {
      loadUserProfile();
    }
  }, [user, loadUserProfile]);

  const handleAvatarChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      if (file.size > 5 * 1024 * 1024) {
        showMessage('error', 'La imagen debe ser menor a 5MB');
        return;
      }

      if (!file.type.startsWith('image/')) {
        showMessage('error', 'Solo se permiten archivos de imagen');
        return;
      }

      setAvatarFile(file);
      const reader = new FileReader();
      reader.onload = (e) => {
        setAvatarPreview(e.target?.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const uploadAvatar = useCallback(async (): Promise<string | null> => {
    if (!avatarFile || !user || isDemoMode) return null;

    try {
      const fileExt = avatarFile.name.split('.').pop();
      const fileName = `${user.id}.${fileExt}`; // Usar user.id que corresponde al id de la tabla
      const filePath = `avatars/${fileName}`;
      const bucketName = 'user-avatars';

      console.log('Subiendo avatar para usuario:', user.id);
      console.log('Ruta del archivo:', filePath);

      // Subir el archivo (upsert: true sobrescribirá si existe)
      const { error: uploadError } = await supabase.storage
        .from(bucketName)
        .upload(filePath, avatarFile, {
          cacheControl: '3600',
          upsert: true // Sobrescribir si existe
        });

      if (uploadError) {
        console.error('Error de subida:', uploadError);
        return null;
      }

      // Intentar obtener URL firmada primero (más confiable)
      const { data: signedData, error: signedError } = await supabase.storage
        .from(bucketName)
        .createSignedUrl(filePath, 60 * 60 * 24 * 365); // 1 año de duración

      if (signedData && !signedError) {
        console.log('URL firmada generada:', signedData.signedUrl);
        return signedData.signedUrl;
      }

      // Si falla la URL firmada, usar URL pública como fallback
      const { data } = supabase.storage
        .from(bucketName)
        .getPublicUrl(filePath);

      console.log('URL pública generada (fallback):', data.publicUrl);
      return data.publicUrl;
    } catch (error) {
      console.error('Error uploading avatar:', error);
      return null;
    }
  }, [avatarFile, user, isDemoMode]);

  const handleSaveProfile = async () => {
    if (!user) return;

    try {
      setSaving(true);
      let avatarUrl = profileData?.avatar_url;

      // Subir nueva imagen si existe
      if (avatarFile) {
        const uploadedAvatarUrl = await uploadAvatar();
        if (uploadedAvatarUrl) {
          avatarUrl = uploadedAvatarUrl;
          console.log('Avatar subido exitosamente:', avatarUrl);
        } else {
          showMessage('error', 'Error al subir la imagen de perfil');
          return;
        }
      }

      if (isDemoMode) {
        // Simular guardado en modo demo
        showMessage('success', 'Perfil actualizado (modo demo)');
        setEditMode(false);
        setAvatarFile(null);
        setAvatarPreview(null);
        return;
      }

      const updateData = {
        ...profileForm,
        avatar_url: avatarUrl,
        updated_at: new Date().toISOString()
      };

      console.log('Actualizando perfil con datos:', updateData);

      const { error } = await supabase
        .from('user_profiles')
        .update(updateData)
        .eq('id', user.id); // Usar 'id' en lugar de 'user_id'

      if (error) {
        console.error('Error al actualizar perfil:', error);
        throw error;
      }

      showMessage('success', 'Perfil actualizado correctamente');
      setEditMode(false);
      setAvatarFile(null);
      setAvatarPreview(null);
      
      // Actualizar el estado local inmediatamente para evitar parpadeos
      setProfileData(prev => prev ? {
        ...prev,
        ...profileForm,
        avatar_url: avatarUrl
      } : null);

    } catch (error) {
      console.error('Error saving profile:', error);
      showMessage('error', 'Error al guardar el perfil');
    } finally {
      setSaving(false);
    }
  };

  const handleChangePassword = async () => {
    if (!user) return;

    try {
      setSaving(true);

      // Validar formulario
      if (!passwordForm.currentPassword || !passwordForm.newPassword || !passwordForm.confirmPassword) {
        showMessage('error', 'Todos los campos son obligatorios');
        return;
      }

      if (passwordForm.newPassword !== passwordForm.confirmPassword) {
        showMessage('error', 'Las contraseñas nuevas no coinciden');
        return;
      }

      // Cambiar contraseña en Supabase
      const { error } = await supabase.auth.updateUser({
        password: passwordForm.newPassword
      });

      if (error) throw error;

      showMessage('success', 'Contraseña cambiada correctamente');
      setShowPasswordForm(false);
    } catch (error) {
      console.error('Error changing password:', error);
      showMessage('error', 'Error al cambiar la contraseña');
    } finally {
      setSaving(false);
    }
  };

  const handleLogout = async () => {
    await supabase.auth.signOut();
  };

  // Resto del componente...

  return (
    <div className="p-4 sm:p-6 lg:p-8">
      <div className="max-w-3xl mx-auto">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-6">
          <h1 className="text-2xl sm:text-3xl font-bold text-gray-900 mb-4 sm:mb-0">
            Perfil de Usuario
          </h1>
          <div className="flex-shrink-0">
            <button
              onClick={() => setEditMode(!editMode)}
              className="inline-flex items-center justify-center px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
            >
              {editMode ? 'Cancelar' : 'Editar Perfil'}
              <Edit2 className="w-4 h-4 ml-2" />
            </button>
          </div>
        </div>

        {message && (
          <div className={`p-4 mb-4 text-sm rounded-lg ${message.type === 'error' ? 'bg-red-50 text-red-800' : message.type === 'success' ? 'bg-green-50 text-green-800' : 'bg-blue-50 text-blue-800'}`} role="alert">
            <span className="font-medium">{message.type === 'error' ? 'Error:' : 'Éxito:'}</span> {message.text}
          </div>
        )}

        {loading ? (
          <div className="flex items-center justify-center py-10">
            <svg aria-hidden="true" className="w-8 h-8 text-gray-200 animate-spin dark:text-gray-600 fill-blue-600" viewBox="0 0 100 101" fill="none">
              <path d="M100 50.5C100 78.2091 78.2091 100 50.5 100C22.791 100 1 78.2091 1 50.5C1 22.791 22.791 1 50.5 1C78.2091 1 100 22.791 100 50.5Z" fill="currentColor"/>
              <path d="M93.9706 50.5C93.9706 75.8528 75.8528 93.9706 50.5 93.9706C25.1472 93.9706 7.02944 75.8528 7.02944 50.5C7.02944 25.1472 25.1472 7.02944 50.5 7.02944C75.8528 7.02944 93.9706 25.1472 93.9706 50.5Z" stroke="currentColor" strokeWidth="2"/>
              <path d="M31.25 50.5C31.25 39.4024 39.4024 31.25 50.5 31.25C61.5976 31.25 69.75 39.4024 69.75 50.5C69.75 61.5976 61.5976 69.75 50.5 69.75C39.4024 69.75 31.25 61.5976 31.25 50.5Z" fill="currentColor"/>
            </svg>
          </div>
        ) : (
          <div className="bg-white shadow rounded-lg p-6 sm:p-8">
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-4">
              <div className="flex items-center">
                <div className="relative">
                  <img
                    src={avatarPreview || profileData?.avatar_url || `https://ui-avatars.com/api/?name=${encodeURIComponent(profileForm.full_name || 'Usuario')}&background=3b82f6&color=fff&size=96`}
                    alt="Avatar"
                    className="w-16 h-16 sm:w-24 sm:h-24 rounded-full object-cover border-2 border-white shadow-md"
                    onLoad={(e) => {
                      console.log('Imagen de avatar cargada exitosamente:', (e.target as HTMLImageElement).src);
                    }}
                    onError={(e) => {
                      const target = e.target as HTMLImageElement;
                      const originalSrc = target.src;
                      console.error('Error cargando imagen de avatar:', originalSrc);
                      
                      // Solo cambiar si no es ya el fallback
                      if (!originalSrc.includes('ui-avatars.com')) {
                        target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(profileForm.full_name || 'Usuario')}&background=3b82f6&color=fff&size=96`;
                      }
                    }}
                  />
                  <span className="absolute inset-0 rounded-full shadow-inner" aria-hidden="true"></span>
                </div>
                <div className="ml-4">
                  <h2 className="text-xl font-semibold text-gray-800">{profileForm.full_name || 'Nombre de Usuario'}</h2>
                  <p className="text-sm text-gray-500">{profileData?.email}</p>
                </div>
              </div>
              {editMode && (
                <div className="mt-4 sm:mt-0 sm:ml-4">
                  <label htmlFor="avatar" className="block text-sm font-medium text-gray-700 mb-1">
                    Cambiar Avatar
                  </label>
                  <input
                    id="avatar"
                    type="file"
                    accept="image/*"
                    onChange={handleAvatarChange}
                    className="block w-full text-sm text-gray-900 border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                    ref={fileInputRef}
                  />
                </div>
              )}
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label htmlFor="first_name" className="block text-sm font-medium text-gray-700 mb-1">
                  Nombre
                </label>
                <input
                  id="first_name"
                  type="text"
                  value={profileForm.first_name}
                  onChange={(e) => setProfileForm({ ...profileForm, first_name: e.target.value })}
                  disabled={!editMode}
                  className="block w-full text-sm text-gray-900 border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
              <div>
                <label htmlFor="last_name" className="block text-sm font-medium text-gray-700 mb-1">
                  Apellido
                </label>
                <input
                  id="last_name"
                  type="text"
                  value={profileForm.last_name}
                  onChange={(e) => setProfileForm({ ...profileForm, last_name: e.target.value })}
                  disabled={!editMode}
                  className="block w-full text-sm text-gray-900 border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
              <div>
                <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1">
                  Correo Electrónico
                </label>
                <input
                  id="email"
                  type="email"
                  value={profileData?.email}
                  disabled
                  className="block w-full text-sm text-gray-900 bg-gray-100 border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
              <div>
                <label htmlFor="phone" className="block text-sm font-medium text-gray-700 mb-1">
                  Teléfono
                </label>
                <input
                  id="phone"
                  type="text"
                  value={profileForm.phone}
                  onChange={(e) => setProfileForm({ ...profileForm, phone: e.target.value })}
                  disabled={!editMode}
                  className="block w-full text-sm text-gray-900 border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
              <div>
                <label htmlFor="address" className="block text-sm font-medium text-gray-700 mb-1">
                  Dirección
                </label>
                <input
                  id="address"
                  type="text"
                  value={profileForm.address}
                  onChange={(e) => setProfileForm({ ...profileForm, address: e.target.value })}
                  disabled={!editMode}
                  className="block w-full text-sm text-gray-900 border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
              <div>
                <label htmlFor="city" className="block text-sm font-medium text-gray-700 mb-1">
                  Ciudad
                </label>
                <input
                  id="city"
                  type="text"
                  value={profileForm.city}
                  onChange={(e) => setProfileForm({ ...profileForm, city: e.target.value })}
                  disabled={!editMode}
                  className="block w-full text-sm text-gray-900 border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
              <div>
                <label htmlFor="country" className="block text-sm font-medium text-gray-700 mb-1">
                  País
                </label>
                <input
                  id="country"
                  type="text"
                  value={profileForm.country}
                  onChange={(e) => setProfileForm({ ...profileForm, country: e.target.value })}
                  disabled={!editMode}
                  className="block w-full text-sm text-gray-900 border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
            </div>

            {editMode && (
              <div className="mt-6">
                <button
                  onClick={handleSaveProfile}
                  className="inline-flex items-center justify-center px-4 py-2 text-sm font-medium text-white bg-green-600 rounded-md hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2"
                >
                  {saving ? 'Guardando...' : 'Guardar Cambios'}
                  <Save className="w-4 h-4 ml-2" />
                </button>
              </div>
            )}
          </div>
        )}

        <div className="mt-8">
          <h2 className="text-xl font-semibold text-gray-800 mb-4">
            Seguridad
          </h2>
          <div className="bg-white shadow rounded-lg p-6 sm:p-8">
            {showPasswordForm ? (
              <div>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label htmlFor="currentPassword" className="block text-sm font-medium text-gray-700 mb-1">
                      Contraseña Actual
                    </label>
                    <input
                      id="currentPassword"
                      type={showPasswords.current ? 'text' : 'password'}
                      value={passwordForm.currentPassword}
                      onChange={(e) => setPasswordForm({ ...passwordForm, currentPassword: e.target.value })}
                      className="block w-full text-sm text-gray-900 border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                    />
                    <button
                      type="button"
                      onClick={() => setShowPasswords({ ...showPasswords, current: !showPasswords.current })}
                      className="absolute inset-y-0 right-0 pr-3 flex items-center text-sm"
                    >
                      {showPasswords.current ? <EyeOff className="h-5 w-5 text-gray-400" /> : <Eye className="h-5 w-5 text-gray-400" />}
                    </button>
                  </div>
                  <div>
                    <label htmlFor="newPassword" className="block text-sm font-medium text-gray-700 mb-1">
                      Nueva Contraseña
                    </label>
                    <input
                      id="newPassword"
                      type={showPasswords.new ? 'text' : 'password'}
                      value={passwordForm.newPassword}
                      onChange={(e) => setPasswordForm({ ...passwordForm, newPassword: e.target.value })}
                      className="block w-full text-sm text-gray-900 border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                    />
                    <button
                      type="button"
                      onClick={() => setShowPasswords({ ...showPasswords, new: !showPasswords.new })}
                      className="absolute inset-y-0 right-0 pr-3 flex items-center text-sm"
                    >
                      {showPasswords.new ? <EyeOff className="h-5 w-5 text-gray-400" /> : <Eye className="h-5 w-5 text-gray-400" />}
                    </button>
                  </div>
                  <div>
                    <label htmlFor="confirmPassword" className="block text-sm font-medium text-gray-700 mb-1">
                      Confirmar Nueva Contraseña
                    </label>
                    <input
                      id="confirmPassword"
                      type={showPasswords.confirm ? 'text' : 'password'}
                      value={passwordForm.confirmPassword}
                      onChange={(e) => setPasswordForm({ ...passwordForm, confirmPassword: e.target.value })}
                      className="block w-full text-sm text-gray-900 border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                    />
                    <button
                      type="button"
                      onClick={() => setShowPasswords({ ...showPasswords, confirm: !showPasswords.confirm })}
                      className="absolute inset-y-0 right-0 pr-3 flex items-center text-sm"
                    >
                      {showPasswords.confirm ? <EyeOff className="h-5 w-5 text-gray-400" /> : <Eye className="h-5 w-5 text-gray-400" />}
                    </button>
                  </div>
                </div>
                <div className="mt-4">
                  <button
                    onClick={handleChangePassword}
                    className="inline-flex items-center justify-center px-4 py-2 text-sm font-medium text-white bg-green-600 rounded-md hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2"
                  >
                    {saving ? 'Guardando...' : 'Cambiar Contraseña'}
                    <Save className="w-4 h-4 ml-2" />
                  </button>
                </div>
              </div>
            ) : (
              <div>
                <p className="text-sm text-gray-500 mb-4">
                  Para mantener la seguridad de tu cuenta, es recomendable cambiar tu contraseña periódicamente.
                </p>
                <button
                  onClick={() => setShowPasswordForm(true)}
                  className="inline-flex items-center justify-center px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
                >
                  Cambiar Contraseña
                  <Lock className="w-4 h-4 ml-2" />
                </button>
              </div>
            )}
          </div>
        </div>

        <div className="mt-8">
          <h2 className="text-xl font-semibold text-gray-800 mb-4">
            Actividad Reciente
          </h2>
          <div className="bg-white shadow rounded-lg p-6 sm:p-8">
            <p className="text-sm text-gray-500">
              Último inicio de sesión: {new Date(profileData?.last_login || '').toLocaleString()}
            </p>
            <p className="text-sm text-gray-500">
              Fecha de creación de la cuenta: {new Date(profileData?.created_at || '').toLocaleString()}
            </p>
          </div>
        </div>

        <div className="mt-8">
          <h2 className="text-xl font-semibold text-gray-800 mb-4">
            Eliminar Cuenta
          </h2>
          <div className="bg-white shadow rounded-lg p-6 sm:p-8">
            <p className="text-sm text-gray-500 mb-4">
              Si deseas eliminar tu cuenta, ten en cuenta que esta acción es irreversible y se perderán todos tus datos.
            </p>
            <button
              onClick={handleLogout}
              className="inline-flex items-center justify-center px-4 py-2 text-sm font-medium text-white bg-red-600 rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2"
            >
              Eliminar Cuenta
              <Trash2 className="w-4 h-4 ml-2" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default UserProfile;
