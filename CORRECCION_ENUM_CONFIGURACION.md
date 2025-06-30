# Corrección de Errores de Enum en Módulo de Configuración

## ✅ Problema Resuelto
**Error**: `invalid input value for enum user_role: "super_admin"`

## 🔧 Correcciones Aplicadas

### 1. Análisis del Enum
- **Enum `user_role` válido**: `('admin', 'manager', 'cashier', 'viewer')`
- **Valor inválido usado**: `'super_admin'` (no existe en el enum)

### 2. Políticas SQL Corregidas
Se eliminaron todas las referencias a `'super_admin'` en las políticas RLS:

#### **Company Settings Policies**
```sql
-- ANTES: role IN ('admin', 'super_admin')
-- DESPUÉS: role = 'admin'
CREATE POLICY "Company settings are editable by admin users" ON company_settings
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );
```

#### **System Settings Policies**
```sql
-- ANTES: role IN ('admin', 'super_admin')
-- DESPUÉS: role = 'admin'
CREATE POLICY "Public system settings are viewable by authenticated users" ON system_settings
    FOR SELECT USING (
        auth.role() = 'authenticated' AND
        (is_public = true OR EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        ))
    );
```

#### **Notification Templates Policies**
```sql
-- ANTES: role IN ('admin', 'super_admin')
-- DESPUÉS: role = 'admin'
CREATE POLICY "Notification templates are manageable by admin users" ON notification_templates
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );
```

#### **Backup Configurations Policies**
```sql
-- ANTES: role IN ('admin', 'super_admin')
-- DESPUÉS: role = 'admin'
CREATE POLICY "Backup configurations are manageable by admin users" ON backup_configurations
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );
```

#### **Audit Logs Policies**
```sql
-- ANTES: role IN ('admin', 'super_admin')
-- DESPUÉS: role = 'admin'
CREATE POLICY "Audit logs are viewable by admin users" ON audit_logs
    FOR SELECT USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );
```

#### **Inventory Alerts Policies**
```sql
-- ANTES: role IN ('admin', 'super_admin') OR
-- DESPUÉS: role = 'admin' OR
CREATE POLICY "Inventory alerts are manageable by users with inventory access" ON inventory_alerts
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND (
                role = 'admin' OR
                'inventory_manage' = ANY(permissions) OR
                'inventory_view' = ANY(permissions)
            )
        )
    );
```

## 📊 Verificación de Cambios

### Archivos Modificados
- ✅ `/supabase/migrations/20250630120000_configuration_module.sql`

### Archivos Sin Errores
- ✅ `/src/components/Configuration.tsx`
- ✅ `/src/hooks/useConfiguration.tsx`
- ✅ `/src/types/index.ts`

### Referencias Eliminadas
- ❌ `'super_admin'` (8 ocurrencias eliminadas)
- ✅ Solo `'admin'` para políticas restrictivas

## 🎯 Estado Actual

### ✅ **Listo para Aplicar**
La migración `20250630120000_configuration_module.sql` está corregida y lista para aplicarse.

### 🔄 **Para Aplicar la Migración**
```bash
# Opción 1: Con Supabase CLI (recomendado)
supabase db push

# Opción 2: Aplicar manualmente en la consola de Supabase
# Ejecutar el contenido del archivo de migración
```

### 🔐 **Permisos Actualizados**
- **Administradores (`admin`)**: Acceso completo a configuraciones
- **Managers (`manager`)**: Acceso limitado según permisos específicos
- **Cajeros (`cashier`)**: Acceso de solo lectura a configuraciones públicas
- **Visualizadores (`viewer`)**: Acceso de solo lectura a configuraciones públicas

## 📋 Próximos Pasos

1. **Aplicar la migración** en la base de datos
2. **Probar el módulo** en el frontend
3. **Verificar políticas** de seguridad
4. **Revisar logs** de auditoría
5. **Documentar el uso** del módulo

---
*Corrección completada el 30 de junio de 2025*
