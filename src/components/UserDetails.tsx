import React from 'react';
import { X, User as UserIcon, Mail, Phone, Calendar, Badge, Building2, Shield, Clock } from 'lucide-react';
import { User } from '../types';

interface UserDetailsProps {
  user: User;
  onClose: () => void;
  onEdit: (user: User) => void;
}

const UserDetails: React.FC<UserDetailsProps> = ({ user, onClose, onEdit }) => {
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'text-green-600 bg-green-100';
      case 'blocked': return 'text-red-600 bg-red-100';
      case 'inactive': return 'text-gray-600 bg-gray-100';
      default: return 'text-gray-600 bg-gray-100';
    }
  };

  const getRoleColor = (role: string) => {
    switch (role) {
      case 'admin': return 'text-purple-600 bg-purple-100';
      case 'manager': return 'text-blue-600 bg-blue-100';
      case 'cashier': return 'text-green-600 bg-green-100';
      case 'viewer': return 'text-gray-600 bg-gray-100';
      default: return 'text-gray-600 bg-gray-100';
    }
  };

  const getRoleName = (role: string) => {
    switch (role) {
      case 'admin': return 'Administrador';
      case 'manager': return 'Gerente';
      case 'cashier': return 'Cajero';
      case 'viewer': return 'Visualizador';
      default: return 'Sin rol';
    }
  };

  const getStatusName = (status: string) => {
    switch (status) {
      case 'active': return 'Activo';
      case 'blocked': return 'Bloqueado';
      case 'inactive': return 'Inactivo';
      default: return 'Desconocido';
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg max-w-2xl w-full max-h-screen overflow-y-auto">
        <div className="flex items-center justify-between p-6 border-b">
          <h2 className="text-xl font-semibold">Detalles del Usuario</h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
          >
            <X className="h-6 w-6" />
          </button>
        </div>

        <div className="p-6 space-y-6">
          {/* Información básica */}
          <div className="flex items-start gap-6">
            <div className="h-20 w-20 flex-shrink-0">
              {user.avatar_url ? (
                <img 
                  className="h-20 w-20 rounded-full object-cover" 
                  src={user.avatar_url} 
                  alt={user.name}
                />
              ) : (
                <div className="h-20 w-20 rounded-full bg-gray-300 flex items-center justify-center">
                  <UserIcon className="h-10 w-10 text-gray-600" />
                </div>
              )}
            </div>
            <div className="flex-1">
              <h3 className="text-2xl font-bold text-gray-900">{user.name}</h3>
              <p className="text-gray-600">{user.email}</p>
              <div className="flex items-center gap-4 mt-2">
                <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${getRoleColor(user.role || '')}`}>
                  <Shield className="h-4 w-4 mr-1" />
                  {getRoleName(user.role || '')}
                </span>
                <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${getStatusColor(user.status)}`}>
                  {getStatusName(user.status)}
                </span>
              </div>
            </div>
          </div>

          {/* Información de contacto */}
          <div className="bg-gray-50 rounded-lg p-4">
            <h4 className="text-lg font-medium text-gray-900 mb-4">Información de Contacto</h4>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="flex items-center gap-3">
                <Mail className="h-5 w-5 text-gray-400" />
                <div>
                  <p className="text-sm text-gray-600">Email</p>
                  <p className="font-medium">{user.email}</p>
                </div>
              </div>
              {user.phone && (
                <div className="flex items-center gap-3">
                  <Phone className="h-5 w-5 text-gray-400" />
                  <div>
                    <p className="text-sm text-gray-600">Teléfono</p>
                    <p className="font-medium">{user.phone}</p>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Información laboral */}
          <div className="bg-gray-50 rounded-lg p-4">
            <h4 className="text-lg font-medium text-gray-900 mb-4">Información Laboral</h4>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {user.employee_id && (
                <div className="flex items-center gap-3">
                  <Badge className="h-5 w-5 text-gray-400" />
                  <div>
                    <p className="text-sm text-gray-600">ID de Empleado</p>
                    <p className="font-medium">{user.employee_id}</p>
                  </div>
                </div>
              )}
              {user.department && (
                <div className="flex items-center gap-3">
                  <Building2 className="h-5 w-5 text-gray-400" />
                  <div>
                    <p className="text-sm text-gray-600">Departamento</p>
                    <p className="font-medium">{user.department}</p>
                  </div>
                </div>
              )}
              {user.hire_date && (
                <div className="flex items-center gap-3">
                  <Calendar className="h-5 w-5 text-gray-400" />
                  <div>
                    <p className="text-sm text-gray-600">Fecha de Contratación</p>
                    <p className="font-medium">
                      {new Date(user.hire_date).toLocaleDateString('es-ES', {
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric'
                      })}
                    </p>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Información del sistema */}
          <div className="bg-gray-50 rounded-lg p-4">
            <h4 className="text-lg font-medium text-gray-900 mb-4">Información del Sistema</h4>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="flex items-center gap-3">
                <Calendar className="h-5 w-5 text-gray-400" />
                <div>
                  <p className="text-sm text-gray-600">Fecha de Registro</p>
                  <p className="font-medium">
                    {new Date(user.created_at).toLocaleDateString('es-ES', {
                      year: 'numeric',
                      month: 'long',
                      day: 'numeric'
                    })}
                  </p>
                </div>
              </div>
              {user.last_login && (
                <div className="flex items-center gap-3">
                  <Clock className="h-5 w-5 text-gray-400" />
                  <div>
                    <p className="text-sm text-gray-600">Último Acceso</p>
                    <p className="font-medium">
                      {new Date(user.last_login).toLocaleDateString('es-ES', {
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit'
                      })}
                    </p>
                  </div>
                </div>
              )}
              {user.updated_at && (
                <div className="flex items-center gap-3">
                  <Calendar className="h-5 w-5 text-gray-400" />
                  <div>
                    <p className="text-sm text-gray-600">Última Actualización</p>
                    <p className="font-medium">
                      {new Date(user.updated_at).toLocaleDateString('es-ES', {
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric'
                      })}
                    </p>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Estadísticas adicionales */}
          <div className="bg-blue-50 rounded-lg p-4">
            <h4 className="text-lg font-medium text-gray-900 mb-4">Estadísticas</h4>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="text-center">
                <p className="text-2xl font-bold text-blue-600">
                  {user.created_at ? Math.floor((Date.now() - new Date(user.created_at).getTime()) / (1000 * 60 * 60 * 24)) : 0}
                </p>
                <p className="text-sm text-gray-600">Días en el sistema</p>
              </div>
              <div className="text-center">
                <p className="text-2xl font-bold text-green-600">
                  {user.last_login ? Math.floor((Date.now() - new Date(user.last_login).getTime()) / (1000 * 60 * 60 * 24)) : '∞'}
                </p>
                <p className="text-sm text-gray-600">Días desde último acceso</p>
              </div>
              <div className="text-center">
                <p className="text-2xl font-bold text-purple-600">
                  {user.status === 'active' ? '✓' : '✗'}
                </p>
                <p className="text-sm text-gray-600">Estado actual</p>
              </div>
            </div>
          </div>
        </div>

        {/* Botones de acción */}
        <div className="flex justify-end gap-4 p-6 border-t">
          <button
            onClick={onClose}
            className="px-6 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
          >
            Cerrar
          </button>
          <button
            onClick={() => onEdit(user)}
            className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            Editar Usuario
          </button>
        </div>
      </div>
    </div>
  );
};

export default UserDetails;
