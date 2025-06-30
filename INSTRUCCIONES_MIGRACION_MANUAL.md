# 🚀 MIGRACIÓN DE GESTIÓN DE USUARIOS - APLICACIÓN MANUAL

## ⚠️ Problema Detectado
Hay un problema con npm/npx que impide ejecutar comandos de Supabase CLI directamente desde la terminal.

## ✅ SOLUCIÓN RECOMENDADA: Aplicar desde Supabase Dashboard

### Paso 1: Acceder al Dashboard
1. Ve a https://supabase.com/dashboard
2. Inicia sesión en tu cuenta
3. Selecciona tu proyecto: **Sistema de Gestión Comercial**

### Paso 2: Abrir SQL Editor
1. En el menú lateral, haz clic en **SQL Editor**
2. Haz clic en **New query** o **Nueva consulta**

### Paso 3: Aplicar la Migración
1. Copia **todo** el contenido del archivo: `user_management_simple.sql`
2. Pégalo en el editor SQL
3. Haz clic en **Run** o **Ejecutar** (botón verde)

## 📄 Archivo a Copiar
**Archivo:** `user_management_simple.sql`  
**Ubicación:** En la raíz del proyecto  
**Tamaño:** ~8KB (versión simplificada)

## 🔍 Verificación Post-Migración

### 1. Verificar Tablas Creadas
Ejecuta en SQL Editor:
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE 'user_%'
ORDER BY table_name;
```

**Resultado esperado:**
- user_activities
- user_profiles  
- user_role_assignments
- user_roles
- user_sessions

### 2. Verificar Roles Insertados
```sql
SELECT name, description, is_system_role 
FROM user_roles 
ORDER BY name;
```

**Resultado esperado:**
- admin (Administrador del sistema)
- employee (Empleado)
- manager (Gerente)
- viewer (Solo lectura)

### 3. Verificar Funciones Creadas
```sql
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'is_admin';
```

### 4. Verificar Vista Creada
```sql
SELECT * FROM users_complete LIMIT 1;
```

## 🎯 Características de la Migración

### ✅ Tablas Creadas:
- **user_profiles** - Perfiles de usuario extendidos
- **user_roles** - Roles del sistema (admin, manager, employee, viewer)
- **user_role_assignments** - Asignación de roles a usuarios
- **user_sessions** - Gestión de sesiones activas
- **user_activities** - Log de actividades del usuario

### ✅ Características de Seguridad:
- **RLS (Row Level Security)** habilitado en todas las tablas
- **Políticas de seguridad** configuradas
- **Función is_admin()** para verificar permisos
- **Claves foráneas** con manejo de errores

### ✅ Optimizaciones:
- **Índices** para mejorar rendimiento
- **Triggers** para actualizar `updated_at`
- **Vista users_complete** para consultas fáciles

### ✅ Compatibilidad:
- **Funciona con o sin `auth.users`** existente
- **Crea tabla demo** si `auth.users` no existe
- **Manejo robusto de errores**

## 🔧 Resolución de Problemas npm (Opcional)

Si quieres resolver el problema de npm para uso futuro:

### Opción 1: Limpiar npm
```powershell
# Cerrar VS Code y todas las terminales
# Abrir PowerShell como administrador

npm cache clean --force
npm config delete proxy
npm config delete https-proxy
npm config set registry https://registry.npmjs.org/
```

### Opción 2: Reinstalar Node.js
1. Desinstalar Node.js desde Panel de Control
2. Descargar la versión LTS desde https://nodejs.org
3. Instalar y reiniciar

### Opción 3: Usar yarn en lugar de npm
```powershell
npm install -g yarn
yarn install
yarn dlx supabase db push
```

## 📋 Próximos Pasos

Después de aplicar exitosamente la migración:

### 1. Probar Componentes React ⚛️
- El archivo `src/components/UserManagement.tsx` ya está creado
- Probar la interfaz de gestión de usuarios
- Verificar que las consultas funcionan

### 2. Configurar Autenticación 🔐
- Configurar providers de auth en Supabase
- Probar registro y login
- Verificar creación automática de perfiles

### 3. Crear Usuarios de Prueba 👥
```sql
-- Ejemplo de inserción de usuario de prueba
INSERT INTO user_profiles (user_id, first_name, last_name, is_active) 
VALUES (gen_random_uuid(), 'Admin', 'Sistema', true);

-- Asignar rol de admin
INSERT INTO user_role_assignments (user_id, role_id) 
SELECT up.user_id, ur.id 
FROM user_profiles up, user_roles ur 
WHERE up.first_name = 'Admin' AND ur.name = 'admin';
```

### 4. Verificar Permisos 🛡️
- Probar que las políticas RLS funcionan
- Verificar que solo admins pueden gestionar usuarios
- Probar acceso a datos propios vs datos de otros

## 📞 Soporte

Si encuentras algún error:

1. **Copia el mensaje de error exacto**
2. **Indica en qué paso falló**
3. **Verifica que copiaste todo el SQL**
4. **Asegúrate de estar en el proyecto correcto**

## ✨ Resultado Final

Una vez completada la migración tendrás:

- ✅ Sistema completo de gestión de usuarios
- ✅ Roles y permisos configurados
- ✅ Seguridad RLS implementada
- ✅ Base lista para autenticación
- ✅ Interfaz React lista para usar

**¡La migración está diseñada para ser 100% exitosa!** 🎉
