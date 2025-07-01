# Módulo de Gestión de Usuarios

## 📋 Descripción

El módulo de Gestión de Usuarios proporciona una interfaz completa para administrar usuarios del sistema, roles, permisos, sesiones y actividades. Incluye funcionalidades avanzadas de seguridad, auditoria y control de acceso granular.

## 🎯 Características Principales

### ✅ Gestión Completa de Usuarios
- **CRUD de usuarios**: Crear, leer, actualizar y eliminar usuarios
- **Perfiles extendidos**: Información adicional como departamento, ID de empleado, fecha de contratación
- **Estados de usuario**: Activo, Inactivo, Bloqueado
- **Avatares**: Soporte para URLs de imagen de perfil

### ✅ Sistema de Roles y Permisos
- **Roles predefinidos**: Admin, Manager, Cajero, Visualizador
- **Permisos granulares**: Control por módulo y acción (leer, escribir, eliminar, administrar)
- **Matriz de permisos**: Interfaz visual para gestión de permisos
- **Plantillas de rol**: Asignación rápida de permisos según el rol

### ✅ Seguimiento de Actividad
- **Log de actividades**: Registro completo de acciones del usuario
- **Historial de sesiones**: Control de sesiones activas e inactivas
- **Estadísticas**: Métricas de uso y actividad
- **Filtros avanzados**: Por módulo, acción y fecha

### ✅ Seguridad Avanzada
- **Row Level Security (RLS)**: Políticas de seguridad a nivel de base de datos
- **Validaciones**: Controles de integridad de datos
- **Encriptación**: Contraseñas seguras con Supabase Auth
- **Sesiones controladas**: Gestión de tokens y expiración

### ✅ Interfaz de Usuario
- **Dashboard de estadísticas**: Métricas clave de usuarios
- **Búsqueda y filtros**: Herramientas de navegación eficientes
- **Acciones masivas**: Operaciones en lote
- **Exportación**: Descarga de datos en CSV
- **Responsive**: Adaptado a dispositivos móviles

## 🗂️ Estructura de Archivos

```
src/
├── components/
│   ├── UserManagement.tsx      # Componente principal
│   ├── UserForm.tsx           # Formulario de usuario
│   ├── UserDetails.tsx        # Detalles del usuario
│   ├── UserPermissions.tsx    # Gestión de permisos
│   └── UserActivityLog.tsx    # Log de actividades
├── types/
│   └── index.ts              # Tipos TypeScript expandidos
supabase/
├── migrations/
│   └── 20250629055000_user_management.sql
apply-users-migration.sh       # Script Bash
apply-users-migration.ps1      # Script PowerShell
MODULO_USUARIOS_DOCUMENTACION.md
```

## 🏗️ Arquitectura de Base de Datos

### Tablas Principales

#### `user_profiles`
Perfiles extendidos de usuarios con información adicional:
```sql
- id (UUID, PK)
- user_id (UUID, FK a auth.users)
- name (VARCHAR)
- phone (VARCHAR)
- avatar_url (TEXT)
- status (ENUM: active, inactive, blocked)
- department (VARCHAR)
- employee_id (VARCHAR, UNIQUE)
- hire_date (DATE)
- created_at, updated_at (TIMESTAMP)
- updated_by (UUID, FK)
```

#### `user_roles`
Roles asignados a usuarios:
```sql
- id (UUID, PK)
- user_id (UUID, FK)
- role (ENUM: admin, manager, cashier, viewer)
- assigned_at (TIMESTAMP)
- assigned_by (UUID, FK)
- is_active (BOOLEAN)
```

#### `user_permissions`
Permisos específicos por módulo:
```sql
- id (UUID, PK)
- user_id (UUID, FK)
- module (ENUM: inventory, sales, payments, users, reports, settings)
- action (ENUM: read, write, delete, admin)
- granted_at (TIMESTAMP)
- granted_by (UUID, FK)
- is_active (BOOLEAN)
```

#### `user_sessions`
Control de sesiones activas:
```sql
- id (UUID, PK)
- user_id (UUID, FK)
- session_token (TEXT, UNIQUE)
- ip_address (INET)
- user_agent (TEXT)
- created_at, expires_at, last_activity (TIMESTAMP)
- is_active (BOOLEAN)
```

#### `user_activities`
Log de actividades del sistema:
```sql
- id (UUID, PK)
- user_id (UUID, FK)
- action (VARCHAR)
- module (VARCHAR)
- details (JSONB)
- ip_address (INET)
- created_at (TIMESTAMP)
```

### Vistas y Funciones

#### Vista `users_complete`
Combina datos de auth.users, user_profiles, user_roles y user_sessions para una vista completa del usuario.

#### Función `get_user_stats()`
Retorna estadísticas agregadas de usuarios:
- Total de usuarios
- Usuarios por estado y rol
- Logins recientes
- Nuevos usuarios del mes

## 🚀 Instalación

### 1. Aplicar Migración de Base de Datos

**Linux/Mac:**
```bash
chmod +x apply-users-migration.sh
./apply-users-migration.sh
```

**Windows (PowerShell):**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\apply-users-migration.ps1
```

### 2. Configurar Variables de Entorno

Las siguientes variables deben estar en tu archivo `.env`:
```
VITE_SUPABASE_URL=https://tu-proyecto.supabase.co
VITE_SUPABASE_ANON_KEY=tu_anon_key
```

Para los scripts de migración (opcional):
```
SUPABASE_PROJECT_REF=tu_project_ref
SUPABASE_DB_PASSWORD=tu_db_password
```

### 3. Verificar Instalación

1. Accede a `/users` en tu aplicación
2. Verifica que aparezca el dashboard de usuarios
3. Intenta crear un usuario de prueba
4. Revisa los permisos y actividades

## 👥 Roles y Permisos

### Roles Predefinidos

#### 🔴 **Administrador (admin)**
- **Acceso total** a todos los módulos
- Puede gestionar usuarios, roles y permisos
- Ve todas las actividades del sistema
- Puede realizar acciones críticas

#### 🔵 **Gerente (manager)**
- Acceso de **lectura y escritura** a inventario, ventas y pagos
- **Solo lectura** a gestión de usuarios y reportes
- No puede eliminar usuarios ni cambiar permisos críticos

#### 🟢 **Cajero (cashier)**
- Acceso de **lectura** a inventario
- **Lectura y escritura** a ventas y pagos
- Sin acceso a usuarios ni configuración

#### ⚪ **Visualizador (viewer)**
- **Solo lectura** a inventario, ventas, pagos y reportes
- Sin permisos de escritura o administración

### Permisos por Módulo

| Módulo | Read | Write | Delete | Admin |
|--------|------|-------|---------|-------|
| **inventory** | Ver productos | Crear/editar productos | Eliminar productos | Configurar inventario |
| **sales** | Ver ventas | Registrar ventas | Anular ventas | Configurar ventas |
| **payments** | Ver pagos | Registrar pagos | Eliminar pagos | Configurar pagos |
| **users** | Ver usuarios | Crear/editar usuarios | Eliminar usuarios | Gestionar permisos |
| **reports** | Ver reportes | - | - | Configurar reportes |
| **settings** | Ver configuración | Editar configuración | - | Administrar sistema |

## 📊 Estadísticas y Métricas

### Dashboard Principal
- **Total de usuarios**: Cuenta total de usuarios activos
- **Usuarios activos**: Usuarios con estado "activo"
- **Usuarios bloqueados**: Usuarios con estado "bloqueado"
- **Logins recientes**: Accesos en los últimos 7 días

### Métricas por Usuario
- **Días en el sistema**: Tiempo desde el registro
- **Último acceso**: Fecha y hora del último login
- **Total de actividades**: Número de acciones registradas
- **Actividad por período**: 24 horas, 7 días, 30 días

## 🔒 Seguridad

### Row Level Security (RLS)
- **Perfiles de usuario**: Los usuarios solo ven su propio perfil (excepto admins)
- **Roles y permisos**: Solo admins pueden gestionar roles
- **Actividades**: Los usuarios ven sus propias actividades (excepto admins)
- **Sesiones**: Control de acceso a sesiones propias

### Validaciones
- **Email único**: Verificación de unicidad de emails
- **ID de empleado**: Formato y unicidad validados
- **Contraseñas**: Mínimo 6 caracteres para nuevos usuarios
- **Permisos**: Solo admins pueden modificar permisos críticos

### Auditoria
- **Log automático**: Todas las acciones se registran automáticamente
- **Triggers**: Eventos de base de datos generan logs
- **IP tracking**: Registro de direcciones IP en actividades
- **Trazabilidad**: Cada cambio incluye quién y cuándo

## 🛠️ Uso de la Interfaz

### Gestión de Usuarios

#### Crear Usuario
1. Clic en "Nuevo Usuario"
2. Completar información básica (nombre, email, contraseña)
3. Seleccionar rol y estado
4. Agregar información laboral (opcional)
5. Guardar

#### Editar Usuario
1. Clic en el ícono de edición en la fila del usuario
2. Modificar los campos deseados
3. Guardar cambios

#### Gestionar Permisos
1. Clic en el ícono de escudo (permisos)
2. Usar plantillas rápidas o configurar manualmente
3. Marcar/desmarcar permisos en la matriz
4. Guardar permisos

#### Ver Actividad
1. Clic en el ícono de actividad
2. Filtrar por módulo o tipo de acción
3. Revisar detalles de cada actividad

### Acciones Masivas
1. Seleccionar usuarios usando checkboxes
2. Elegir acción: Activar, Bloquear o Desactivar
3. Confirmar la acción

### Exportación
- Clic en "Exportar" para descargar CSV con datos de usuarios
- Incluye filtros aplicados en el momento de la exportación

## 🔧 Configuración Avanzada

### Personalización de Roles
Para agregar nuevos roles, modifica:
1. El enum en la migración SQL
2. Los tipos TypeScript en `src/types/index.ts`
3. Los componentes React para incluir el nuevo rol

### Nuevos Módulos
Para agregar permisos a nuevos módulos:
1. Actualizar el enum `module` en la base de datos
2. Agregar el módulo en `UserPermissions.tsx`
3. Implementar validaciones en los componentes del módulo

### Políticas RLS Personalizadas
Las políticas se pueden modificar en la migración SQL para casos de uso específicos.

## 🐛 Troubleshooting

### Problemas Comunes

#### Error: "No se encuentra el módulo"
- Verificar que todos los archivos estén en las rutas correctas
- Asegurar que las extensiones `.tsx` estén especificadas en los imports

#### Error de permisos al crear usuario
- Verificar que el usuario actual sea admin
- Comprobar las políticas RLS en Supabase

#### Migración no se aplica
- Verificar variables de entorno
- Comprobar conexión a Supabase
- Revisar logs de PostgreSQL

#### Estadísticas no cargan
- Verificar que la función `get_user_stats()` exista
- Comprobar permisos de la función en Supabase

### Logs y Debugging
- Usar las herramientas de desarrollador del navegador
- Revisar logs de Supabase en el dashboard
- Activar logs de SQL para debugging

## 📈 Próximas Mejoras

### Funcionalidades Planificadas
- [ ] **Importación masiva**: Cargar usuarios desde CSV/Excel
- [ ] **Autenticación 2FA**: Factor de autenticación adicional
- [ ] **Grupos de usuarios**: Organización por equipos o departamentos
- [ ] **Plantillas de permisos**: Configuraciones predefinidas personalizables
- [ ] **Notificaciones**: Alertas por email/SMS para eventos importantes
- [ ] **API REST**: Endpoints para integración externa
- [ ] **Single Sign-On (SSO)**: Integración con proveedores externos
- [ ] **Backup de usuarios**: Exportación/importación completa

### Mejoras de UX
- [ ] **Tutorial interactivo**: Guía paso a paso para nuevos admins
- [ ] **Temas**: Personalización visual
- [ ] **Accesibilidad**: Mejoras para lectores de pantalla
- [ ] **Mobile app**: Aplicación nativa para gestión móvil

## 📚 Referencias

### Enlaces Útiles
- [Documentación de Supabase Auth](https://supabase.com/docs/guides/auth)
- [React Router](https://reactrouter.com/docs)
- [Tailwind CSS](https://tailwindcss.com/docs)
- [Lucide Icons](https://lucide.dev)

### Soporte
Para preguntas o problemas:
1. Revisar esta documentación
2. Consultar logs de la aplicación
3. Revisar issues en el repositorio
4. Contactar al equipo de desarrollo

---

**Versión**: 1.0.0  
**Fecha**: 29 de junio de 2025  
**Autor**: Sistema de Gestión Comercial  
**Licencia**: MIT
