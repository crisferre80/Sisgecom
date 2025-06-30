import React, { useState, useEffect, useCallback } from 'react';
import { X, Shield, Check } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { User, UserPermission } from '../types';
import { useAuth } from '../hooks/useAuth.tsx';

interface UserPermissionsProps {
  user: User;
  onClose: () => void;
  onSave: () => void;
}

const UserPermissions: React.FC<UserPermissionsProps> = ({ user, onClose, onSave }) => {
  const { user: currentUser } = useAuth();
  const [permissions, setPermissions] = useState<UserPermission[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const modules = [
    { id: 'inventory', name: 'Inventario', description: 'Gestión de productos y stock' },
    { id: 'sales', name: 'Ventas', description: 'Registro y gestión de ventas' },
    { id: 'payments', name: 'Pagos', description: 'Gestión de pagos y cobranzas' },
    { id: 'users', name: 'Usuarios', description: 'Gestión de usuarios del sistema' },
    { id: 'reports', name: 'Reportes', description: 'Visualización de reportes y estadísticas' },
    { id: 'settings', name: 'Configuración', description: 'Configuración del sistema' }
  ];

  const actions = [
    { id: 'read', name: 'Leer', description: 'Ver información', color: 'text-blue-600 bg-blue-100' },
    { id: 'write', name: 'Escribir', description: 'Crear y modificar', color: 'text-green-600 bg-green-100' },
    { id: 'delete', name: 'Eliminar', description: 'Borrar registros', color: 'text-red-600 bg-red-100' },
    { id: 'admin', name: 'Administrar', description: 'Control total', color: 'text-purple-600 bg-purple-100' }
  ];

  const reloadPermissions = useCallback(async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('user_permissions')
        .select('*')
        .eq('user_id', user.id)
        .eq('is_active', true);

      if (error) throw error;
      setPermissions(data || []);
    } catch (error) {
      console.error('Error loading permissions:', error);
    } finally {
      setLoading(false);
    }
  }, [user.id]);

  useEffect(() => {
    reloadPermissions();
  }, [user.id, reloadPermissions]);

  const hasPermission = (module: string, action: string) => {
    return permissions.some(p => p.module === module && p.action === action);
  };

  const togglePermission = async (module: string, action: string) => {
    const exists = hasPermission(module, action);
    
    try {
      if (exists) {
        // Remover permiso
        const permission = permissions.find(p => p.module === module && p.action === action);
        if (permission) {
          const { error } = await supabase
            .from('user_permissions')
            .update({ is_active: false })
            .eq('id', permission.id);

          if (error) throw error;
          setPermissions(permissions.filter(p => p.id !== permission.id));
        }
      } else {
        // Agregar permiso
        const { data, error } = await supabase
          .from('user_permissions')
          .insert({
            user_id: user.id,
            module,
            action,
            granted_by: currentUser?.id
          })
          .select()
          .single();

        if (error) throw error;
        setPermissions([...permissions, data]);
      }
    } catch (error) {
      console.error('Error toggling permission:', error);
      alert('Error al actualizar permisos.');
    }
  };

  const setRolePermissions = async (role: string) => {
    setSaving(true);
    try {
      // Primero desactivar todos los permisos actuales
      await supabase
        .from('user_permissions')
        .update({ is_active: false })
        .eq('user_id', user.id);

      // Definir permisos por rol
      const rolePermissions: { module: string; action: string }[] = [];
      
      switch (role) {
        case 'admin':
          modules.forEach(module => {
            actions.forEach(action => {
              rolePermissions.push({ module: module.id, action: action.id });
            });
          });
          break;
        case 'manager':
          rolePermissions.push(
            { module: 'inventory', action: 'read' },
            { module: 'inventory', action: 'write' },
            { module: 'sales', action: 'read' },
            { module: 'sales', action: 'write' },
            { module: 'payments', action: 'read' },
            { module: 'payments', action: 'write' },
            { module: 'reports', action: 'read' },
            { module: 'users', action: 'read' }
          );
          break;
        case 'cashier':
          rolePermissions.push(
            { module: 'inventory', action: 'read' },
            { module: 'sales', action: 'read' },
            { module: 'sales', action: 'write' },
            { module: 'payments', action: 'read' },
            { module: 'payments', action: 'write' }
          );
          break;
        case 'viewer':
          rolePermissions.push(
            { module: 'inventory', action: 'read' },
            { module: 'sales', action: 'read' },
            { module: 'payments', action: 'read' },
            { module: 'reports', action: 'read' }
          );
          break;
      }

      // Insertar nuevos permisos
      if (rolePermissions.length > 0) {
        const { error } = await supabase
          .from('user_permissions')
          .insert(
            rolePermissions.map(perm => ({
              user_id: user.id,
              module: perm.module,
              action: perm.action,
              granted_by: currentUser?.id
            }))
          );

        if (error) throw error;
      }

      await reloadPermissions();
    } catch (error) {
      console.error('Error setting role permissions:', error);
      alert('Error al asignar permisos del rol.');
    } finally {
      setSaving(false);
    }
  };

  const clearAllPermissions = async () => {
    if (!confirm('¿Estás seguro de que quieres quitar todos los permisos?')) return;

    try {
      setSaving(true);
      const { error } = await supabase
        .from('user_permissions')
        .update({ is_active: false })
        .eq('user_id', user.id);

      if (error) throw error;
      setPermissions([]);
    } catch (error) {
      console.error('Error clearing permissions:', error);
      alert('Error al limpiar permisos.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg max-w-4xl w-full max-h-screen overflow-y-auto">
        <div className="flex items-center justify-between p-6 border-b">
          <div>
            <h2 className="text-xl font-semibold">Permisos de Usuario</h2>
            <p className="text-sm text-gray-600 mt-1">
              Gestionar permisos para {user.name} ({user.email})
            </p>
          </div>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
          >
            <X className="h-6 w-6" />
          </button>
        </div>

        <div className="p-6 space-y-6">
          {/* Acciones rápidas */}
          <div className="bg-gray-50 rounded-lg p-4">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Acciones Rápidas</h3>
            <div className="flex flex-wrap gap-2">
              <button
                onClick={() => setRolePermissions('admin')}
                disabled={saving}
                className="px-4 py-2 text-sm bg-purple-100 text-purple-700 rounded-lg hover:bg-purple-200 disabled:opacity-50"
              >
                Permisos de Admin
              </button>
              <button
                onClick={() => setRolePermissions('manager')}
                disabled={saving}
                className="px-4 py-2 text-sm bg-blue-100 text-blue-700 rounded-lg hover:bg-blue-200 disabled:opacity-50"
              >
                Permisos de Gerente
              </button>
              <button
                onClick={() => setRolePermissions('cashier')}
                disabled={saving}
                className="px-4 py-2 text-sm bg-green-100 text-green-700 rounded-lg hover:bg-green-200 disabled:opacity-50"
              >
                Permisos de Cajero
              </button>
              <button
                onClick={() => setRolePermissions('viewer')}
                disabled={saving}
                className="px-4 py-2 text-sm bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 disabled:opacity-50"
              >
                Solo Lectura
              </button>
              <button
                onClick={clearAllPermissions}
                disabled={saving}
                className="px-4 py-2 text-sm bg-red-100 text-red-700 rounded-lg hover:bg-red-200 disabled:opacity-50"
              >
                Quitar Todos
              </button>
            </div>
          </div>

          {/* Matriz de permisos */}
          {loading ? (
            <div className="text-center py-8">
              <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
              <p className="mt-2 text-gray-600">Cargando permisos...</p>
            </div>
          ) : (
            <div className="bg-white border rounded-lg overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Módulo
                      </th>
                      {actions.map(action => (
                        <th key={action.id} className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                          <div className="flex flex-col items-center">
                            <span>{action.name}</span>
                            <span className="text-xs text-gray-400 mt-1">{action.description}</span>
                          </div>
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {modules.map(module => (
                      <tr key={module.id} className="hover:bg-gray-50">
                        <td className="px-6 py-4">
                          <div>
                            <div className="text-sm font-medium text-gray-900">{module.name}</div>
                            <div className="text-sm text-gray-500">{module.description}</div>
                          </div>
                        </td>
                        {actions.map(action => (
                          <td key={action.id} className="px-6 py-4 text-center">
                            <button
                              onClick={() => togglePermission(module.id, action.id)}
                              className={`w-8 h-8 rounded-full border-2 flex items-center justify-center ${
                                hasPermission(module.id, action.id)
                                  ? `${action.color} border-current`
                                  : 'border-gray-300 text-gray-400 hover:border-gray-400'
                              }`}
                            >
                              {hasPermission(module.id, action.id) && <Check className="h-4 w-4" />}
                            </button>
                          </td>
                        ))}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* Resumen de permisos */}
          <div className="bg-blue-50 rounded-lg p-4">
            <h3 className="text-lg font-medium text-gray-900 mb-2">Resumen de Permisos</h3>
            <p className="text-sm text-gray-600 mb-4">
              Este usuario tiene {permissions.length} permiso(s) activo(s).
            </p>
            <div className="flex flex-wrap gap-2">
              {permissions.map(permission => (
                <span
                  key={`${permission.module}-${permission.action}`}
                  className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800"
                >
                  {modules.find(m => m.id === permission.module)?.name} - {actions.find(a => a.id === permission.action)?.name}
                </span>
              ))}
            </div>
          </div>
        </div>

        {/* Botones de acción */}
        <div className="flex justify-end gap-4 p-6 border-t">
          <button
            onClick={onClose}
            className="px-6 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
          >
            Cancelar
          </button>
          <button
            onClick={() => {
              onSave();
              onClose();
            }}
            disabled={saving}
            className="flex items-center gap-2 px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
          >
            {saving ? (
              <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
            ) : (
              <Shield className="h-4 w-4" />
            )}
            {saving ? 'Guardando...' : 'Guardar Permisos'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default UserPermissions;
