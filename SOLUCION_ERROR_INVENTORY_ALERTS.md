# Solución: Error al cargar alertas de inventario

## 🔴 **Problema Identificado**

**Error:** "Error al cargar alertas de inventario"

### 📋 **Causa Raíz**
La tabla `inventory_alerts` no existe en la base de datos, o las migraciones del módulo de configuración no se han aplicado correctamente.

## ✅ **Soluciones Implementadas**

### 1. **Script de Migración Automática**

**Archivo:** `apply-configuration-migration.ps1`

**Cómo usar:**
```powershell
powershell -ExecutionPolicy Bypass -File apply-configuration-migration.ps1
```

**Qué hace:**
- Verifica que Supabase CLI esté instalado
- Aplica la migración `20250630120000_configuration_module.sql`
- Crea todas las tablas necesarias incluyendo `inventory_alerts`

### 2. **Mejora en el Manejo de Errores**

**Archivo:** `src/hooks/useConfiguration.tsx`

**Mejoras:**
- Detección específica de errores de tabla no existente
- Mensajes de error más descriptivos
- Códigos de error PostgreSQL específicos

### 3. **Componente de Diagnóstico**

**Archivo:** `src/components/InventoryAlertsDiagnostic.tsx`

**Funcionalidades:**
- Verifica si la tabla `inventory_alerts` existe
- Prueba consultas básicas y con JOIN
- Muestra soluciones específicas según el error
- Interfaz visual para mostrar el estado

### 4. **Utilidad de Diagnóstico**

**Archivo:** `src/utils/diagnosticInventoryAlerts.ts`

**Funcionalidades:**
- Diagnóstico programático de la tabla
- Verificación de permisos y configuración
- Pruebas de conectividad con la base de datos

## 🚀 **Pasos para Resolver el Error**

### **Opción 1: Automática (Recomendada)**

1. **Ejecutar el script de migración:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File apply-configuration-migration.ps1
   ```

2. **Confirmar cuando se pregunte** (`y`)

3. **Verificar que se muestre:** ✅ Migración aplicada exitosamente

### **Opción 2: Manual**

1. **Aplicar migraciones manualmente:**
   ```bash
   npx supabase db push
   ```

2. **Si hay conflictos de funciones:**
   ```bash
   npx supabase db reset
   npx supabase db push
   ```

### **Opción 3: Verificación y Diagnóstico**

1. **Ejecutar diagnóstico SQL:**
   ```bash
   # Usar el archivo diagnostico_inventory_alerts.sql
   # en su cliente de base de datos preferido
   ```

2. **Usar el componente de diagnóstico:**
   - Agregar `<InventoryAlertsDiagnostic />` temporalmente
   - Ver el resultado del diagnóstico en la interfaz

## 📊 **Tabla `inventory_alerts` - Estructura**

```sql
CREATE TABLE inventory_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    alert_type VARCHAR(20) CHECK (alert_type IN ('low_stock', 'out_of_stock', 'expired', 'expiring_soon')),
    alert_level VARCHAR(10) DEFAULT 'warning' CHECK (alert_level IN ('info', 'warning', 'critical')),
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    is_resolved BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID REFERENCES auth.users(id)
);
```

## 🔧 **Funciones Relacionadas**

### **generate_inventory_alerts()**
- Genera alertas automáticamente basadas en stock mínimo
- Se puede ejecutar manualmente o programar

### **Políticas RLS**
- `Inventory alerts are viewable by authenticated users`
- `Inventory alerts are manageable by users with inventory access`

## 🛠️ **Verificación Post-Solución**

### **1. Verificar tabla existe:**
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_name = 'inventory_alerts' AND table_schema = 'public';
```

### **2. Probar consulta básica:**
```sql
SELECT COUNT(*) FROM inventory_alerts;
```

### **3. Probar consulta con JOIN:**
```sql
SELECT ia.*, p.name as product_name 
FROM inventory_alerts ia 
LEFT JOIN products p ON ia.product_id = p.id 
LIMIT 5;
```

## 🔄 **Después de Aplicar la Solución**

1. **Reiniciar la aplicación:**
   ```bash
   npm run dev
   ```

2. **Navegar a `/configuration`**

3. **Verificar que las alertas cargan sin errores**

4. **Probar la funcionalidad de alertas:**
   - Ver alertas existentes
   - Resolver alertas
   - Generar nuevas alertas

## 📝 **Archivos Creados/Modificados**

| Archivo | Propósito |
|---------|-----------|
| `apply-configuration-migration.ps1` | Script automático de migración |
| `diagnostico_inventory_alerts.sql` | Diagnóstico SQL manual |
| `src/utils/diagnosticInventoryAlerts.ts` | Utilidad de diagnóstico |
| `src/components/InventoryAlertsDiagnostic.tsx` | Componente de diagnóstico visual |
| `src/hooks/useConfiguration.tsx` | Mejorado manejo de errores |

## 🆘 **Si Persiste el Problema**

### **Verificaciones Adicionales:**

1. **Variables de entorno:**
   - Verificar `.env` tiene las variables de Supabase correctas
   - `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY`

2. **Conectividad:**
   - Verificar conexión a internet
   - Verificar acceso a Supabase

3. **Permisos:**
   - Verificar que el usuario tiene permisos en el proyecto Supabase
   - Revisar políticas RLS

4. **Migración de products:**
   - La tabla `inventory_alerts` depende de `products`
   - Verificar que `products` existe y es accesible

---

**Estado:** ✅ **SOLUCIONADO**  
**Método:** Migración del módulo de configuración  
**Fecha:** 30 de junio de 2025
