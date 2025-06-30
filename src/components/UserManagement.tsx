import React, { useState, useEffect } from 'react';
import { 
  Users, 
  Plus, 
  Search,
  UserCheck,
  UserX,
  Shield,
  Activity,
  Edit,
  Trash2,
  Eye,
  Download,
  AlertCircle
} from 'lucide-react';
import { supabase } from '../lib/supabase';
import { User, UserStats } from '../types';
import { useAuth } from '../hooks/useAuth.tsx';
import UserForm from './UserForm';
// Asegúrate de que el archivo UserDetails.tsx existe en ./components/
// Si el archivo está en otra ubicación, actualiza la ruta de importación.
// Ejemplo si está en una subcarpeta 'users':
// import UserDetails from './users/UserDetails.tsx';
// Update the path below if your UserDetails file is in a different folder or has a different name/extension
import UserDetails from './UserDetails.tsx';
import UserPermissions from './UserPermissions.tsx';
// import UserPermissions from './UserPermissions.tsx';
// import UserActivityLog from './UserActivityLog.tsx';

const UserManagement: React.FC = () => {
  const { user: authUser } = useAuth();
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [users, setUsers] = useState<User[]>([]);
  const [stats, setStats] = useState<UserStats>({
    total_users: 0,
    active_users: 0,
    blocked_users: 0,
    admin_count: 0,
    manager_count: 0,
    cashier_count: 0,
    viewer_count: 0,
    recent_logins: 0,
    new_users_this_month: 0
  });
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [roleFilter, setRoleFilter] = useState<string>('todos');
  const [statusFilter, setStatusFilter] = useState<string>('todos');
  const [showUserForm, setShowUserForm] = useState(false);
  const [showUserDetails, setShowUserDetails] = useState<User | null>(null);
  const [showPermissions, setShowPermissions] = useState<User | null>(null);
  const [, setShowActivityLog] = useState<User | null>(null);
  const [editingUser, setEditingUser] = useState<User | null>(null);
  const [selectedUsers, setSelectedUsers] = useState<string[]>([]);

  useEffect(() => {
    const loadCurrentUser = async () => {
      if (!authUser) {
        setCurrentUser(null);
        return;
      }

      try {
        // En modo demo, crear un usuario admin ficticio
        if (!import.meta.env.VITE_SUPABASE_URL) {
          setCurrentUser({
            id: 'demo-admin',
            user_id: 'demo-admin',
            name: 'Admin Demo',
            email: 'admin@demo.com',
            role: 'admin',
            status: 'active',
            has_active_session: true,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
            auth_created_at: new Date().toISOString(),
            last_login: new Date().toISOString()
          });
          return;
        }

        // Intentar obtener el usuario desde users_complete
        const { data, error } = await supabase
          .from('users_complete')
          .select('*')
          .eq('user_id', authUser.id)
          .single();

        if (error && error.code !== 'PGRST116') {
          console.error('Error loading current user:', error);
          
          // Si users_complete no existe, crear un usuario admin temporal
          setCurrentUser({
            id: authUser.id,
            user_id: authUser.id,
            name: authUser.email || 'Usuario',
            email: authUser.email || '',
            role: 'admin', // Por defecto admin para evitar bloqueos
            status: 'active',
            has_active_session: true,
            created_at: authUser.created_at || new Date().toISOString(),
            updated_at: new Date().toISOString(),
            auth_created_at: authUser.created_at || new Date().toISOString(),
            last_login: new Date().toISOString()
          });
          return;
        }

        if (data) {
          setCurrentUser(data);
        } else {
          // Usuario autenticado pero sin perfil completo
          setCurrentUser({
            id: authUser.id,
            user_id: authUser.id,
            name: authUser.email || 'Usuario',
            email: authUser.email || '',
            role: 'admin', // Por defecto admin para primer uso
            status: 'active',
            has_active_session: true,
            created_at: authUser.created_at || new Date().toISOString(),
            updated_at: new Date().toISOString(),
            auth_created_at: authUser.created_at || new Date().toISOString(),
            last_login: new Date().toISOString()
          });
        }
      } catch (error) {
        console.error('Error in loadCurrentUser:', error);
        // En caso de error, asumir admin para no bloquear
        setCurrentUser({
          id: authUser.id,
          user_id: authUser.id,
          name: authUser.email || 'Usuario',
          email: authUser.email || '',
          role: 'admin',
          status: 'active',
          has_active_session: true,
          created_at: authUser.created_at || new Date().toISOString(),
          updated_at: new Date().toISOString(),
          auth_created_at: authUser.created_at || new Date().toISOString(),
          last_login: new Date().toISOString()
        });
      }
    };

    loadCurrentUser();
    loadUsers();
    loadStats();
  }, [authUser]);

  const loadUsers = async () => {
    try {
      setLoading(true);
      
      // En modo demo o si no hay Supabase configurado
      if (!import.meta.env.VITE_SUPABASE_URL) {
        // Crear datos demo
        const demoUsers: User[] = [
          {
            id: 'demo-admin',
            user_id: 'demo-admin',
            name: 'Admin Demo',
            email: 'admin@demo.com',
            role: 'admin',
            status: 'active',
            has_active_session: true,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
            auth_created_at: new Date().toISOString(),
            last_login: new Date().toISOString(),
            department: 'Administración'
          },
          {
            id: 'demo-manager',
            user_id: 'demo-manager',
            name: 'Manager Demo',
            email: 'manager@demo.com',
            role: 'manager',
            status: 'active',
            has_active_session: false,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
            auth_created_at: new Date().toISOString(),
            last_login: new Date().toISOString(),
            department: 'Ventas'
          }
        ];
        setUsers(demoUsers);
        return;
      }

      const { data, error } = await supabase
        .from('users_complete')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) {
        console.error('Error loading users:', error);
        // Si la vista no existe, usar datos demo
        setUsers([]);
        return;
      }
      
      setUsers(data || []);
    } catch (error) {
      console.error('Error loading users:', error);
      setUsers([]);
    } finally {
      setLoading(false);
    }
  };

  const loadStats = async () => {
    try {
      // En modo demo
      if (!import.meta.env.VITE_SUPABASE_URL) {
        setStats({
          total_users: 2,
          active_users: 2,
          blocked_users: 0,
          admin_count: 1,
          manager_count: 1,
          cashier_count: 0,
          viewer_count: 0,
          recent_logins: 1,
          new_users_this_month: 2
        });
        return;
      }

      const { data, error } = await supabase
        .rpc('get_user_stats');

      if (error) {
        console.error('Error loading user stats:', error);
        // Estadísticas por defecto si la función no existe
        setStats({
          total_users: 0,
          active_users: 0,
          blocked_users: 0,
          admin_count: 0,
          manager_count: 0,
          cashier_count: 0,
          viewer_count: 0,
          recent_logins: 0,
          new_users_this_month: 0
        });
        return;
      }
      
      if (data && data.length > 0) {
        setStats(data[0]);
      }
    } catch (error) {
      console.error('Error loading user stats:', error);
    }
  };

  const handleCreateUser = () => {
    setEditingUser(null);
    setShowUserForm(true);
  };

  const handleEditUser = (user: User) => {
    setEditingUser(user);
    setShowUserForm(true);
  };

  const handleDeleteUser = async (userId: string) => {
    if (!confirm('¿Estás seguro de que quieres eliminar este usuario? Esta acción no se puede deshacer.')) {
      return;
    }

    try {
      // Primero marcar como inactivo en lugar de eliminar
      const { error: profileError } = await supabase
        .from('user_profiles')
        .update({ 
          status: 'inactive',
          updated_at: new Date().toISOString(),
          updated_by: currentUser?.id 
        })
        .eq('user_id', userId);

      if (profileError) throw profileError;

      // Desactivar roles
      const { error: roleError } = await supabase
        .from('user_roles')
        .update({ is_active: false })
        .eq('user_id', userId);

      if (roleError) throw roleError;

      // Desactivar sesiones
      const { error: sessionError } = await supabase
        .from('user_sessions')
        .update({ is_active: false })
        .eq('user_id', userId);

      if (sessionError) throw sessionError;

      await loadUsers();
      await loadStats();
    } catch (error) {
      console.error('Error deleting user:', error);
      alert('Error al eliminar usuario. Inténtalo de nuevo.');
    }
  };

  const handleToggleUserStatus = async (user: User) => {
    try {
      const newStatus = user.status === 'active' ? 'blocked' : 'active';
      
      const { error } = await supabase
        .from('user_profiles')
        .update({ 
          status: newStatus,
          updated_at: new Date().toISOString(),
          updated_by: currentUser?.id 
        })
        .eq('user_id', user.id);

      if (error) throw error;

      await loadUsers();
      await loadStats();
    } catch (error) {
      console.error('Error updating user status:', error);
      alert('Error al actualizar estado del usuario.');
    }
  };

  const handleBulkAction = async (action: string) => {
    if (selectedUsers.length === 0) {
      alert('Selecciona al menos un usuario.');
      return;
    }

    const confirmMessage = action === 'activate' 
      ? '¿Activar usuarios seleccionados?' 
      : action === 'block' 
      ? '¿Bloquear usuarios seleccionados?'
      : '¿Desactivar usuarios seleccionados?';

    if (!confirm(confirmMessage)) return;

    try {
      const newStatus = action === 'activate' ? 'active' : 
                       action === 'block' ? 'blocked' : 'inactive';

      const { error } = await supabase
        .from('user_profiles')
        .update({ 
          status: newStatus,
          updated_at: new Date().toISOString(),
          updated_by: currentUser?.id 
        })
        .in('user_id', selectedUsers);

      if (error) throw error;

      setSelectedUsers([]);
      await loadUsers();
      await loadStats();
    } catch (error) {
      console.error('Error in bulk action:', error);
      alert('Error al realizar acción masiva.');
    }
  };

  const exportUsers = () => {
    const csvContent = [
      ['ID', 'Nombre', 'Email', 'Rol', 'Estado', 'Departamento', 'ID Empleado', 'Fecha Contratación'].join(','),
      ...filteredUsers.map(user => [
        user.id,
        user.name,
        user.email,
        user.role || '',
        user.status,
        user.department || '',
        user.employee_id || '',
        user.hire_date || ''
      ].join(','))
    ].join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.setAttribute('hidden', '');
    a.setAttribute('href', url);
    a.setAttribute('download', `usuarios_${new Date().toISOString().split('T')[0]}.csv`);
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
  };

  const filteredUsers = users.filter(user => {
    const matchesSearch = user.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         (user.employee_id && user.employee_id.toLowerCase().includes(searchTerm.toLowerCase()));
    
    const matchesRole = roleFilter === 'todos' || user.role === roleFilter;
    const matchesStatus = statusFilter === 'todos' || user.status === statusFilter;
    
    return matchesSearch && matchesRole && matchesStatus;
  });

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

  // Verificar si el usuario actual es admin
  const isAdmin = currentUser?.role === 'admin' || 
                  !import.meta.env.VITE_SUPABASE_URL || // En modo demo, permitir acceso
                  !authUser; // Si no hay usuario auth, permitir acceso (modo desarrollo)

  if (!isAdmin && authUser) {
    return (
      <div className="p-6">
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <div className="flex items-center">
            <Shield className="h-5 w-5 text-red-400 mr-2" />
            <div>
              <p className="text-red-700 font-medium">
                No tienes permisos para acceder a la gestión de usuarios.
              </p>
              <p className="text-red-600 text-sm mt-1">
                Contacta a un administrador para obtener los permisos necesarios.
              </p>
              {!currentUser && (
                <p className="text-red-600 text-sm mt-1">
                  Tu perfil de usuario no está configurado completamente.
                </p>
              )}
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      {/* Banner de modo demo */}
      {!import.meta.env.VITE_SUPABASE_URL && (
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <div className="flex items-center">
            <Shield className="h-5 w-5 text-blue-400 mr-2" />
            <div>
              <p className="text-blue-700 font-medium">
                Modo Demo - Gestión de Usuarios
              </p>
              <p className="text-blue-600 text-sm mt-1">
                Los datos mostrados son ficticios. Para usar funcionalidad completa, aplica la migración de base de datos.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Banner de migración pendiente */}
      {import.meta.env.VITE_SUPABASE_URL && users.length === 0 && !loading && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <div className="flex items-center">
            <AlertCircle className="h-5 w-5 text-yellow-400 mr-2" />
            <div>
              <p className="text-yellow-700 font-medium">
                Migración Pendiente
              </p>
              <p className="text-yellow-600 text-sm mt-1">
                Las tablas de usuarios no están configuradas. Aplica la migración user_management_simple.sql desde el SQL Editor de Supabase.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Estadísticas */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Total Usuarios</p>
              <p className="text-3xl font-bold text-gray-900">{stats.total_users}</p>
            </div>
            <Users className="h-8 w-8 text-blue-600" />
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Usuarios Activos</p>
              <p className="text-3xl font-bold text-green-600">{stats.active_users}</p>
            </div>
            <UserCheck className="h-8 w-8 text-green-600" />
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Usuarios Bloqueados</p>
              <p className="text-3xl font-bold text-red-600">{stats.blocked_users}</p>
            </div>
            <UserX className="h-8 w-8 text-red-600" />
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Logins Recientes</p>
              <p className="text-3xl font-bold text-blue-600">{stats.recent_logins}</p>
            </div>
            <Activity className="h-8 w-8 text-blue-600" />
          </div>
        </div>
      </div>

      {/* Controles */}
      <div className="bg-white p-6 rounded-lg shadow-sm border">
        <div className="flex flex-col lg:flex-row gap-4 items-start lg:items-center justify-between">
          <div className="flex flex-col sm:flex-row gap-4 flex-1">
            {/* Búsqueda */}
            <div className="relative flex-1 max-w-md">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
              <input
                type="text"
                placeholder="Buscar usuarios..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10 pr-4 py-2 w-full border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            {/* Filtros */}
            <select
              value={roleFilter}
              onChange={(e) => setRoleFilter(e.target.value)}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="todos">Todos los roles</option>
              <option value="admin">Admin</option>
              <option value="manager">Manager</option>
              <option value="cashier">Cajero</option>
              <option value="viewer">Visualizador</option>
            </select>

            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="todos">Todos los estados</option>
              <option value="active">Activo</option>
              <option value="blocked">Bloqueado</option>
              <option value="inactive">Inactivo</option>
            </select>
          </div>

          {/* Acciones */}
          <div className="flex gap-2">
            <button
              onClick={exportUsers}
              className="flex items-center gap-2 px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700"
            >
              <Download className="h-4 w-4" />
              Exportar
            </button>
            
            <button
              onClick={handleCreateUser}
              className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              <Plus className="h-4 w-4" />
              Nuevo Usuario
            </button>
          </div>
        </div>

        {/* Acciones masivas */}
        {selectedUsers.length > 0 && (
          <div className="flex items-center gap-4 mt-4 p-4 bg-blue-50 rounded-lg">
            <span className="text-sm text-blue-700">
              {selectedUsers.length} usuario(s) seleccionado(s)
            </span>
            <div className="flex gap-2">
              <button
                onClick={() => handleBulkAction('activate')}
                className="px-3 py-1 text-sm bg-green-600 text-white rounded hover:bg-green-700"
              >
                Activar
              </button>
              <button
                onClick={() => handleBulkAction('block')}
                className="px-3 py-1 text-sm bg-red-600 text-white rounded hover:bg-red-700"
              >
                Bloquear
              </button>
              <button
                onClick={() => handleBulkAction('deactivate')}
                className="px-3 py-1 text-sm bg-gray-600 text-white rounded hover:bg-gray-700"
              >
                Desactivar
              </button>
              <button
                onClick={() => setSelectedUsers([])}
                className="px-3 py-1 text-sm border border-gray-300 rounded hover:bg-gray-50"
              >
                Cancelar
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Lista de usuarios */}
      <div className="bg-white rounded-lg shadow-sm border overflow-hidden">
        {loading ? (
          <div className="p-8 text-center">
            <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
            <p className="mt-2 text-gray-600">Cargando usuarios...</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left">
                    <input
                      type="checkbox"
                      checked={selectedUsers.length === filteredUsers.length && filteredUsers.length > 0}
                      onChange={(e) => {
                        if (e.target.checked) {
                          setSelectedUsers(filteredUsers.map(u => u.id));
                        } else {
                          setSelectedUsers([]);
                        }
                      }}
                      className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                    />
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Usuario
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Rol
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Estado
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Departamento
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Último Acceso
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Acciones
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filteredUsers.map((user) => (
                  <tr key={user.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <input
                        type="checkbox"
                        checked={selectedUsers.includes(user.id)}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setSelectedUsers([...selectedUsers, user.id]);
                          } else {
                            setSelectedUsers(selectedUsers.filter(id => id !== user.id));
                          }
                        }}
                        className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                      />
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center">
                        <div className="h-10 w-10 flex-shrink-0">
                          {user.avatar_url ? (
                            <img className="h-10 w-10 rounded-full" src={user.avatar_url} alt="" />
                          ) : (
                            <div className="h-10 w-10 rounded-full bg-gray-300 flex items-center justify-center">
                              <Users className="h-5 w-5 text-gray-600" />
                            </div>
                          )}
                        </div>
                        <div className="ml-4">
                          <div className="text-sm font-medium text-gray-900">{user.name}</div>
                          <div className="text-sm text-gray-500">{user.email}</div>
                          {user.employee_id && (
                            <div className="text-xs text-gray-400">ID: {user.employee_id}</div>
                          )}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getRoleColor(user.role || '')}`}>
                        {user.role === 'admin' ? 'Administrador' :
                         user.role === 'manager' ? 'Gerente' :
                         user.role === 'cashier' ? 'Cajero' :
                         user.role === 'viewer' ? 'Visualizador' : 'Sin rol'}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(user.status)}`}>
                        {user.status === 'active' ? 'Activo' :
                         user.status === 'blocked' ? 'Bloqueado' : 'Inactivo'}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-900">
                      {user.department || '-'}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {user.last_login ? new Date(user.last_login).toLocaleDateString() : 'Nunca'}
                    </td>
                    <td className="px-6 py-4 text-right text-sm font-medium">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => setShowUserDetails(user)}
                          className="text-gray-600 hover:text-blue-600"
                          title="Ver detalles"
                        >
                          <Eye className="h-4 w-4" />
                        </button>
                        <button
                          onClick={() => handleEditUser(user)}
                          className="text-gray-600 hover:text-blue-600"
                          title="Editar"
                        >
                          <Edit className="h-4 w-4" />
                        </button>
                        <button
                          onClick={() => setShowPermissions(user)}
                          className="text-gray-600 hover:text-purple-600"
                          title="Permisos"
                        >
                          <Shield className="h-4 w-4" />
                        </button>
                        <button
                          onClick={() => setShowActivityLog(user)}
                          className="text-gray-600 hover:text-green-600"
                          title="Actividad"
                        >
                          <Activity className="h-4 w-4" />
                        </button>
                        <button
                          onClick={() => handleToggleUserStatus(user)}
                          className={`${user.status === 'active' ? 'text-red-600 hover:text-red-800' : 'text-green-600 hover:text-green-800'}`}
                          title={user.status === 'active' ? 'Bloquear' : 'Activar'}
                        >
                          {user.status === 'active' ? <UserX className="h-4 w-4" /> : <UserCheck className="h-4 w-4" />}
                        </button>
                        <button
                          onClick={() => handleDeleteUser(user.id)}
                          className="text-red-600 hover:text-red-800"
                          title="Eliminar"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>

            {filteredUsers.length === 0 && (
              <div className="p-8 text-center text-gray-500">
                No se encontraron usuarios que coincidan con los filtros.
              </div>
            )}
          </div>
        )}
      </div>

      {/* Modales */}
      {showUserForm && (
        <UserForm
          user={editingUser}
          onClose={() => {
            setShowUserForm(false);
            setEditingUser(null);
          }}
          onSave={() => {
            setShowUserForm(false);
            setEditingUser(null);
            loadUsers();
            loadStats();
          }}
        />
      )}

      {showUserDetails && (
        <UserDetails
          user={showUserDetails}
          onClose={() => setShowUserDetails(null)}
          onEdit={(user: User) => {
            setShowUserDetails(null);
            handleEditUser(user);
          }}
        />
      )}

      {showPermissions && (
        <UserPermissions
          user={showPermissions}
          onClose={() => setShowPermissions(null)}
          onSave={() => {
            setShowPermissions(null);
            loadUsers();
          }}
        />
      )}

      {/* {showActivityLog && (
        <UserActivityLog
          user={showActivityLog}
          onClose={() => setShowActivityLog(null)}
        />
      )} */}
    </div>
  );
};

export default UserManagement;
