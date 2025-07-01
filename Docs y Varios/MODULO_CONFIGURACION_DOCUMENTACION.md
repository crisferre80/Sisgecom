# Módulo de Configuración - Sisgecom

## Descripción

El módulo de configuración permite gestionar todos los aspectos configurables del sistema Sisgecom, incluyendo:

- **Configuración de Empresa**: Datos básicos de la empresa, moneda, prefijos de facturación
- **Configuración del Sistema**: Variables del sistema organizadas por categorías
- **Alertas de Inventario**: Sistema de alertas automáticas para stock bajo
- **Seguridad**: Gestión de claves API y logs de auditoría
- **Notificaciones**: Plantillas de notificación (futuro)
- **Respaldos**: Configuración de respaldos automáticos (futuro)

## Estructura de Tablas

### 1. company_settings
Almacena la configuración básica de la empresa:
- Información de contacto (nombre, email, teléfono, dirección)
- Configuración fiscal (ID fiscal, tasa de impuesto por defecto)
- Configuración de facturación (prefijos, contadores, moneda)

### 2. system_settings
Configuraciones del sistema organizadas por categorías:
- **general**: Configuraciones generales
- **inventory**: Configuraciones de inventario
- **sales**: Configuraciones de ventas
- **payments**: Configuraciones de pagos
- **notifications**: Configuraciones de notificaciones
- **security**: Configuraciones de seguridad

### 3. inventory_alerts
Sistema de alertas automáticas para inventario:
- Alertas de stock bajo
- Alertas de productos agotados
- Niveles de alerta (info, warning, critical)
- Estado de resolución

### 4. audit_logs
Registro de todas las acciones del sistema:
- Usuario que realizó la acción
- Tipo de acción (CREATE, UPDATE, DELETE)
- Entidad afectada
- Valores anteriores y nuevos
- Timestamp y detalles adicionales

### 5. notification_templates
Plantillas para notificaciones automáticas:
- Plantillas de email, SMS, WhatsApp
- Variables dinámicas
- Triggers de eventos

### 6. backup_configurations
Configuración de respaldos automáticos:
- Tipos de respaldo (full, incremental, differential)
- Programación (manual, diario, semanal, mensual)
- Ubicación de almacenamiento

## Funcionalidades

### Configuración de Empresa
```typescript
// Cargar configuración de empresa
const { companySettings, loadCompanySettings } = useConfiguration();

// Guardar configuración
await saveCompanySettings({
  company_name: "Mi Empresa",
  company_email: "contacto@miempresa.com",
  default_currency: "USD",
  default_tax_rate: 16.00
});
```

### Configuración del Sistema
```typescript
// Agregar nueva configuración
await saveSystemSetting({
  setting_key: "low_stock_threshold",
  setting_value: "10",
  setting_type: "number",
  category: "inventory",
  description: "Umbral mínimo de stock"
});

// Obtener valor de configuración
const threshold = getSettingValue("low_stock_threshold", "5");
```

### Alertas de Inventario
```typescript
// Generar alertas automáticamente
await generateAlerts();

// Resolver alerta
await resolveAlert(alertId);

// Cargar alertas pendientes
const { inventoryAlerts } = useConfiguration();
```

### Logs de Auditoría
```typescript
// Registrar evento de auditoría
await logAuditEvent(
  "UPDATE",
  "products",
  productId,
  oldValues,
  newValues,
  "Producto actualizado"
);
```

## Hooks Disponibles

### useConfiguration
Hook principal que proporciona acceso a todas las funcionalidades de configuración:

```typescript
const {
  // Company Settings
  companySettings,
  saveCompanySettings,
  
  // System Settings
  systemSettings,
  saveSystemSetting,
  deleteSystemSetting,
  getSetting,
  getSettingValue,
  
  // Inventory Alerts
  inventoryAlerts,
  resolveAlert,
  generateAlerts,
  
  // Audit Logs
  auditLogs,
  logAuditEvent,
  
  // Loading state
  loading,
  error
} = useConfiguration();
```

## Componentes

### Configuration
Componente principal que renderiza la interfaz de configuración con pestañas:

- **Empresa**: Formulario para configuración de empresa
- **Sistema**: Lista de configuraciones del sistema con opción de agregar/eliminar
- **Alertas**: Lista de alertas de inventario con opción de resolver
- **Seguridad**: Vista de claves API y logs de auditoría
- **Notificaciones**: Configuración de plantillas (próximamente)
- **Respaldos**: Configuración de respaldos (próximamente)

## Permisos y Seguridad

### Row Level Security (RLS)
Todas las tablas tienen RLS habilitado con las siguientes políticas:

- **Lectura**: Usuarios autenticados pueden ver datos públicos
- **Escritura**: Solo administradores pueden modificar configuraciones
- **Alertas**: Usuarios con permisos de inventario pueden gestionar alertas
- **Auditoría**: Solo administradores pueden ver logs completos

### Funciones de Seguridad
- Triggers automáticos para generar alertas de stock
- Logging automático de cambios importantes
- Validación de permisos en todas las operaciones

## Configuraciones por Defecto

El sistema incluye las siguientes configuraciones por defecto:

```sql
-- Inventario
low_stock_threshold: 10
auto_generate_alerts: true

-- Seguridad
session_timeout: 3600
max_login_attempts: 5

-- Notificaciones
email_notifications: true
sms_notifications: false
```

## Plantillas de Notificación por Defecto

- **Alerta de Stock Bajo**: Notifica cuando un producto tiene stock bajo
- **Producto Agotado**: Notifica cuando un producto se agota
- **Nueva Venta**: Notifica cuando se registra una nueva venta

## Uso en Producción

1. **Aplicar Migración**:
   ```bash
   supabase db push
   ```

2. **Configurar Empresa**:
   - Acceder a Configuración > Empresa
   - Completar datos básicos de la empresa
   - Configurar moneda y tasas de impuesto

3. **Configurar Sistema**:
   - Revisar configuraciones por defecto
   - Ajustar umbrales de stock según necesidades
   - Configurar timeouts de seguridad

4. **Activar Alertas**:
   - Las alertas se generan automáticamente
   - Revisar y resolver alertas regularmente
   - Configurar umbrales personalizados

## Mantenimiento

- **Logs de Auditoría**: Se recomienda archivar logs antiguos periódicamente
- **Alertas**: Resolver alertas promptamente para mantener limpio el sistema
- **Respaldos**: Una vez implementado, configurar respaldos automáticos
- **Configuraciones**: Documentar cambios importantes en configuraciones del sistema

## Próximas Funcionalidades

- [ ] Sistema completo de notificaciones por email/SMS
- [ ] Respaldos automáticos programados
- [ ] Dashboard de métricas de configuración
- [ ] Importar/exportar configuraciones
- [ ] Configuraciones por usuario/rol
- [ ] Historial de cambios en configuraciones
