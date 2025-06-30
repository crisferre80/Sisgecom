import React, { useState, useEffect } from 'react';
import { X, Activity, Clock, Filter } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { User, UserActivity } from '../types';

interface UserActivityLogProps {
  user: User;
  onClose: () => void;
}

const UserActivityLog: React.FC<UserActivityLogProps> = ({ user, onClose }) => {
  const [activities, setActivities] = useState<UserActivity[]>([]);
  const [loading, setLoading] = useState(true);
  const [moduleFilter, setModuleFilter] = useState<string>('todos');
  const [actionFilter, setActionFilter] = useState<string>('todos');

  useEffect(() => {
    const loadActivities = async () => {
      try {
        setLoading(true);
        const { data, error } = await supabase
          .from('user_activities')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', { ascending: false })
          .limit(100);

        if (error) throw error;
        setActivities(data || []);
      } catch (error) {
        console.error('Error loading activities:', error);
      } finally {
        setLoading(false);
      }
    };

    loadActivities();
  }, [user.id]);

  const filteredActivities = activities.filter(activity => {
    const matchesModule = moduleFilter === 'todos' || activity.module === moduleFilter;
    const matchesAction = actionFilter === 'todos' || activity.action.includes(actionFilter);
    return matchesModule && matchesAction;
  });

  const getActivityIcon = (action: string) => {
    if (action.includes('INSERT')) return '✅';
    if (action.includes('UPDATE')) return '📝';
    if (action.includes('DELETE')) return '🗑️';
    if (action.includes('LOGIN')) return '🔑';
    if (action.includes('LOGOUT')) return '🚪';
    return '📋';
  };

  const getActivityColor = (action: string) => {
    if (action.includes('INSERT')) return 'text-green-600 bg-green-50';
    if (action.includes('UPDATE')) return 'text-blue-600 bg-blue-50';
    if (action.includes('DELETE')) return 'text-red-600 bg-red-50';
    if (action.includes('LOGIN')) return 'text-purple-600 bg-purple-50';
    if (action.includes('LOGOUT')) return 'text-gray-600 bg-gray-50';
    return 'text-gray-600 bg-gray-50';
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffInHours = (now.getTime() - date.getTime()) / (1000 * 60 * 60);

    if (diffInHours < 1) {
      const diffInMinutes = Math.floor(diffInHours * 60);
      return `hace ${diffInMinutes} minuto${diffInMinutes !== 1 ? 's' : ''}`;
    } else if (diffInHours < 24) {
      const hours = Math.floor(diffInHours);
      return `hace ${hours} hora${hours !== 1 ? 's' : ''}`;
    } else {
      return date.toLocaleDateString('es-ES', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
    }
  };

  const modules = [
    'inventory',
    'sales', 
    'payments',
    'users',
    'reports',
    'settings',
    'auth'
  ];

  const actionTypes = [
    'INSERT',
    'UPDATE', 
    'DELETE',
    'LOGIN',
    'LOGOUT'
  ];

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg max-w-4xl w-full max-h-screen overflow-y-auto">
        <div className="flex items-center justify-between p-6 border-b">
          <div>
            <h2 className="text-xl font-semibold">Registro de Actividad</h2>
            <p className="text-sm text-gray-600 mt-1">
              Actividad de {user.name} ({user.email})
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
          {/* Filtros */}
          <div className="flex gap-4 items-center bg-gray-50 p-4 rounded-lg">
            <Filter className="h-5 w-5 text-gray-400" />
            <select
              value={moduleFilter}
              onChange={(e) => setModuleFilter(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="todos">Todos los módulos</option>
              {modules.map(module => (
                <option key={module} value={module}>
                  {module.charAt(0).toUpperCase() + module.slice(1)}
                </option>
              ))}
            </select>

            <select
              value={actionFilter}
              onChange={(e) => setActionFilter(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="todos">Todas las acciones</option>
              {actionTypes.map(action => (
                <option key={action} value={action}>
                  {action}
                </option>
              ))}
            </select>

            <div className="text-sm text-gray-600">
              {filteredActivities.length} de {activities.length} actividades
            </div>
          </div>

          {/* Lista de actividades */}
          {loading ? (
            <div className="text-center py-8">
              <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
              <p className="mt-2 text-gray-600">Cargando actividades...</p>
            </div>
          ) : filteredActivities.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              <Activity className="h-12 w-12 mx-auto mb-4 text-gray-300" />
              <p>No hay actividades registradas.</p>
            </div>
          ) : (
            <div className="space-y-4">
              {filteredActivities.map((activity, index) => (
                <div
                  key={activity.id || index}
                  className={`border rounded-lg p-4 ${getActivityColor(activity.action)}`}
                >
                  <div className="flex items-start gap-4">
                    <div className="text-2xl">
                      {getActivityIcon(activity.action)}
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center justify-between mb-2">
                        <h4 className="font-medium text-gray-900">
                          {activity.action}
                        </h4>
                        <div className="flex items-center gap-2 text-sm text-gray-500">
                          <Clock className="h-4 w-4" />
                          {formatDate(activity.created_at)}
                        </div>
                      </div>
                      
                      <div className="text-sm text-gray-600 mb-2">
                        <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800 mr-2">
                          {activity.module}
                        </span>
                      </div>

                      {activity.details && (
                        <div className="text-sm text-gray-700 bg-white bg-opacity-50 rounded p-2">
                          <strong>Detalles:</strong> {activity.details}
                        </div>
                      )}

                      {activity.ip_address && (
                        <div className="text-xs text-gray-500 mt-2">
                          IP: {activity.ip_address}
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* Estadísticas */}
          {!loading && activities.length > 0 && (
            <div className="bg-blue-50 rounded-lg p-4">
              <h3 className="text-lg font-medium text-gray-900 mb-4">Estadísticas de Actividad</h3>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="text-center">
                  <p className="text-2xl font-bold text-blue-600">{activities.length}</p>
                  <p className="text-sm text-gray-600">Total de actividades</p>
                </div>
                <div className="text-center">
                  <p className="text-2xl font-bold text-green-600">
                    {activities.filter(a => a.created_at > new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()).length}
                  </p>
                  <p className="text-sm text-gray-600">Últimas 24 horas</p>
                </div>
                <div className="text-center">
                  <p className="text-2xl font-bold text-purple-600">
                    {activities.filter(a => a.created_at > new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()).length}
                  </p>
                  <p className="text-sm text-gray-600">Última semana</p>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Botón de cerrar */}
        <div className="flex justify-end p-6 border-t">
          <button
            onClick={onClose}
            className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            Cerrar
          </button>
        </div>
      </div>
    </div>
  );
};

export default UserActivityLog;
