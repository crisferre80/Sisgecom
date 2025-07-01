# Módulo de Pagos con Billeteras Virtuales

## 🚀 Funcionalidades Implementadas

### 📊 Dashboard de Pagos
- **Resumen financiero**: Total cobrado, pendientes, vencidos
- **Métricas de clientes**: Cantidad de deudores, recaudación mensual
- **Visualización clara**: Cards con iconos y colores distintivos

### 👥 Gestión de Clientes
- **CRUD completo**: Crear, editar, eliminar clientes
- **Información detallada**: Nombre, teléfono, email, dirección, estado
- **Control de deudas**: Cálculo automático de deuda total por cliente
- **Estados de cliente**: Activo, Inactivo, Bloqueado

### 💳 Billeteras Virtuales
- **Tipos soportados**: Yape, Plin, Tunki, Mercado Pago, Banco Digital, Otros
- **Gestión por cliente**: Múltiples billeteras por cliente
- **Verificación**: Estado de verificación de billeteras
- **Alias personalizados**: Nombres descriptivos para facilitar identificación

### 💰 Gestión de Pagos
- **Estados de pago**: Pendiente, Pagado, Vencido, Cancelado
- **Métodos de pago**: Efectivo, Tarjeta, Transferencia, Billetera Virtual
- **Fechas importantes**: Creación, vencimiento, fecha de pago
- **Referencias**: Números de transacción para pagos digitales
- **Notas y descripciones**: Información adicional para cada pago

### 📱 Sistema de WhatsApp
- **Mensajes automáticos**: Templates predefinidos para recordatorios
- **Mensajes personalizados**: Opción de crear mensajes específicos
- **Envío masivo**: Selección múltiple de pagos para envío
- **Registro de comunicaciones**: Historial de mensajes enviados
- **Variables dinámicas**: Personalización automática con datos del cliente

### 🔍 Filtros y Búsqueda
- **Búsqueda inteligente**: Por nombre de cliente o descripción
- **Filtros por estado**: Todos, Pendientes, Pagados, Vencidos, Cancelados
- **Selección múltiple**: Para acciones masivas
- **Tabla responsive**: Adaptada para dispositivos móviles

## 🛠️ Estructura Técnica

### Base de Datos (Supabase)
```sql
-- Tablas principales
customers          -- Información de clientes
virtual_wallets    -- Billeteras virtuales por cliente
payments          -- Registro de pagos
payment_reminders -- Historial de recordatorios enviados
whatsapp_contacts -- Contactos de WhatsApp verificados
```

### Componentes React
```
Payments.tsx          -- Componente principal
PaymentForm.tsx       -- Formulario de creación/edición de pagos
PaymentDetails.tsx    -- Vista detallada de un pago
WhatsAppSender.tsx    -- Sistema de envío de mensajes
CustomerManager.tsx   -- Gestión de clientes y billeteras
```

### Funciones Automáticas
- **Triggers de base de datos**: Actualización automática de deuda total
- **Validación de datos**: Verificación de integridad referencial
- **Timestamps automáticos**: Campos de created_at y updated_at

## 📋 Flujo de Trabajo

### 1. Gestión de Clientes
1. Crear cliente con datos básicos
2. Agregar billeteras virtuales asociadas
3. Verificar billeteras si es necesario

### 2. Creación de Pagos
1. Seleccionar cliente existente
2. Definir monto y fecha de vencimiento
3. Elegir método de pago
4. Especificar billetera virtual si aplica
5. Agregar descripción y notas

### 3. Seguimiento de Pagos
1. Monitorear pagos pendientes en dashboard
2. Identificar pagos vencidos automáticamente
3. Actualizar estado cuando se reciba el pago
4. Registrar fecha y referencia de pago

### 4. Comunicación con Clientes
1. Seleccionar pagos pendientes/vencidos
2. Elegir template de mensaje apropiado
3. Personalizar mensaje si es necesario
4. Enviar vía WhatsApp Web
5. Registrar comunicación en el sistema

## 🎯 Mensajes de WhatsApp

### Templates Incluidos

#### Recordatorio de Pago
```
Estimado/a {nombre},

Le recordamos que tiene un pago pendiente:
💰 Monto: ${monto}
📅 Vencimiento: {fecha_vencimiento}
📋 Concepto: {descripcion}

Puede realizar su pago a través de nuestras billeteras virtuales:
• Yape: [número]
• Plin: [número]
• Transferencia bancaria: [datos]

¡Gracias por su preferencia!
```

#### Pago Vencido
```
Estimado/a {nombre},

Su pago se encuentra VENCIDO:
💰 Monto: ${monto}
📅 Venció el: {fecha_vencimiento}
📋 Concepto: {descripcion}

⚠️ Le solicitamos regularizar su pago a la brevedad para evitar inconvenientes.

Métodos de pago disponibles:
• Yape: [número]
• Plin: [número]
• Transferencia bancaria: [datos]

Para cualquier consulta, contáctenos.
```

### Variables Disponibles
- `{nombre}`: Nombre del cliente
- `{monto}`: Monto del pago con formato de moneda
- `{fecha_vencimiento}`: Fecha de vencimiento formateada
- `{descripcion}`: Descripción del concepto del pago

## 🔒 Seguridad y Validaciones

### Validaciones de Datos
- **Campos obligatorios**: Nombre, teléfono, monto, fecha de vencimiento
- **Formatos de datos**: Validación de email, teléfono, montos
- **Integridad referencial**: Relaciones entre tablas protegidas

### Seguridad
- **Autenticación**: Requiere usuario autenticado
- **Auditoría**: Registro de quién crea/modifica pagos
- **Soft deletes**: Preservación de datos históricos importantes

## 🚀 Cómo Usar

### 1. Acceso al Módulo
- Navegar a "Pagos" desde el menú principal
- El dashboard mostrará un resumen automático

### 2. Gestionar Clientes
- Clic en "Clientes" para abrir el gestor
- Agregar nuevos clientes con sus datos
- Asociar billeteras virtuales a cada cliente

### 3. Crear Pagos
- Clic en "Nuevo Pago"
- Completar formulario con datos del pago
- El sistema calculará automáticamente las deudas

### 4. Enviar Recordatorios
- Seleccionar pagos en la tabla (checkbox)
- Clic en "WhatsApp" o usar el botón principal
- Personalizar mensaje si es necesario
- Confirmar envío para abrir conversaciones

### 5. Gestionar Estados
- Usar la vista detallada para ver información completa
- Editar pagos para actualizar estados
- Marcar como pagado cuando se reciba el dinero

## 📈 Próximas Mejoras

### Funcionalidades Pendientes
- [ ] Integración real con APIs de Yape/Plin
- [ ] Reportes y gráficos avanzados
- [ ] Exportación de datos a Excel/PDF
- [ ] Notificaciones automáticas por email
- [ ] Sistema de cobranza por niveles
- [ ] Integración con sistemas contables
- [ ] App móvil para gestión rápida

### Optimizaciones Técnicas
- [ ] Cache de consultas frecuentes
- [ ] Paginación para grandes volúmenes
- [ ] Búsqueda full-text avanzada
- [ ] Backup automático de datos
- [ ] Métricas de rendimiento
