# Migración de Gestión de Usuarios - Instrucciones Manuales

## Problema Detectado
Hay un problema con npm/npx que impide ejecutar `supabase` directamente. 

## Solución Manual

### Opción 1: Aplicar desde el Dashboard de Supabase
1. Ve al dashboard de tu proyecto en https://supabase.com
2. Ve a SQL Editor
3. Copia y pega el contenido del archivo: `supabase/migrations/20250629055003_user_management_robust.sql`
4. Ejecuta el SQL

### Opción 2: Usar psql directamente
Si tienes PostgreSQL instalado localmente:

```bash
# Conectar a tu base de datos Supabase
psql "postgresql://postgres:[password]@[host]:[port]/[database]"

# Ejecutar el archivo
\i supabase/migrations/20250629055003_user_management_robust.sql
```

### Opción 3: Resolver el problema de npm
```powershell
# Limpiar caché de npm
npm cache clean --force

# Reinstalar dependencias
rm node_modules
rm package-lock.json
npm install

# Intentar de nuevo
npx supabase db push
```

## Contenido de la Migración

La migración `20250629055003_user_management_robust.sql` incluye:

### Tablas Creadas:
- `user_profiles` - Perfiles de usuario
- `user_roles` - Roles del sistema
- `user_role_assignments` - Asignación de roles
- `user_permissions` - Permisos específicos
- `user_permission_assignments` - Asignación de permisos
- `user_sessions` - Sesiones activas
- `user_activities` - Log de actividades
- `user_settings` - Configuraciones personalizadas

### Características:
- ✅ Maneja tanto entornos con `auth.users` como sin él
- ✅ Crea tabla `auth.users` demo si no existe
- ✅ RLS habilitado con políticas de seguridad
- ✅ Funciones auxiliares (`is_admin`, `can_access_user_data`)
- ✅ Vista `users_complete` para consultas fáciles
- ✅ Estadísticas de usuarios (`get_user_stats`)
- ✅ Triggers para `updated_at`
- ✅ Índices para optimización
- ✅ Roles por defecto (admin, manager, employee, viewer)
- ✅ Permisos por defecto
- ✅ Manejo robusto de errores

### Datos Insertados:
```sql
-- Roles por defecto
INSERT INTO user_roles (name, description, permissions, is_system_role) VALUES
    ('admin', 'Administrador del sistema', '["all"]', true),
    ('manager', 'Gerente', '["read", "write", "manage_inventory", "view_reports"]', true),
    ('employee', 'Empleado', '["read", "write"]', true),
    ('viewer', 'Solo lectura', '["read"]', true);

-- Permisos por defecto
INSERT INTO user_permissions (name, description, category) VALUES
    ('read', 'Leer datos', 'general'),
    ('write', 'Escribir datos', 'general'),
    ('delete', 'Eliminar datos', 'general'),
    ('manage_users', 'Gestionar usuarios', 'admin'),
    ('manage_inventory', 'Gestionar inventario', 'inventory'),
    ('view_reports', 'Ver reportes', 'reports'),
    ('manage_settings', 'Gestionar configuraciones', 'admin');
```

## Verificación Post-Migración

Después de aplicar la migración, verifica:

1. **Tablas creadas**:
   ```sql
   SELECT table_name FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name LIKE 'user_%';
   ```

2. **Roles insertados**:
   ```sql
   SELECT * FROM user_roles;
   ```

3. **Permisos insertados**:
   ```sql
   SELECT * FROM user_permissions;
   ```

4. **Funciones creadas**:
   ```sql
   SELECT routine_name FROM information_schema.routines 
   WHERE routine_schema = 'public' 
   AND routine_name IN ('is_admin', 'can_access_user_data', 'get_user_profile', 'get_user_stats');
   ```

## Próximos Pasos

Una vez aplicada la migración:

1. **Probar los componentes React** de gestión de usuarios
2. **Crear usuarios de prueba** si es necesario
3. **Configurar autenticación** en la aplicación
4. **Verificar políticas RLS** están funcionando correctamente

## Troubleshooting

Si encuentras errores:

1. **Error de FK**: La migración maneja automáticamente casos donde `auth.users` no existe
2. **Error de permisos**: Verifica que el usuario de BD tenga permisos para crear tablas
3. **Error de sintaxis**: Copia el SQL exactamente como está en el archivo

## Contacto

Si necesitas ayuda adicional, revisa los logs de error y proporciona:
- El mensaje de error exacto
- El paso donde falló
- La configuración de tu entorno Supabase
