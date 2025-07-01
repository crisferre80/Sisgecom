# Configuración Manual de Storage para Avatares

## Paso 1: Ejecutar Script SQL
1. Ve a Supabase Dashboard → SQL Editor
2. Copia y pega el contenido de `setup_avatars_storage.sql`
3. Ejecuta el script

## Paso 2: Configurar Políticas de Storage (Manual)

Debido a restricciones de permisos, las políticas de storage deben configurarse manualmente:

### Opción A: Hacer el Bucket Público (Más Fácil)
1. Ve a **Storage** en el menú lateral
2. Busca el bucket **user-avatars**
3. Haz clic en los **3 puntos** → **Make public**
4. Confirma la acción

### Opción B: Configurar Políticas Específicas (Más Seguro)
1. Ve a **Storage** → **user-avatars**
2. Ve a la pestaña **Policies**
3. Crea las siguientes políticas:

#### Política 1: Lectura Pública
- **Name**: `Allow public read`
- **Allowed operation**: `SELECT`
- **Target roles**: `public`
- **USING expression**: `bucket_id = 'user-avatars'`

#### Política 2: Subida Autenticada
- **Name**: `Allow authenticated upload`
- **Allowed operation**: `INSERT`
- **Target roles**: `authenticated`
- **WITH CHECK expression**: `bucket_id = 'user-avatars'`

#### Política 3: Actualización Autenticada
- **Name**: `Allow authenticated update`
- **Allowed operation**: `UPDATE`
- **Target roles**: `authenticated`
- **USING expression**: `bucket_id = 'user-avatars'`

#### Política 4: Eliminación Autenticada
- **Name**: `Allow authenticated delete`
- **Allowed operation**: `DELETE`
- **Target roles**: `authenticated`
- **USING expression**: `bucket_id = 'user-avatars'`

## Paso 3: Verificar Configuración
1. Ve a **Storage** → **user-avatars**
2. Intenta subir una imagen de prueba
3. Verifica que aparezca en la lista
4. Verifica que se pueda ver públicamente

## Paso 4: Probar en la Aplicación
1. Ve al módulo de **Perfil de Usuario**
2. Intenta subir un avatar
3. Verifica que se guarde correctamente
4. Verifica que aparezca en el perfil

## Solución de Problemas

### Si sigue dando error 403:
1. Verifica que el bucket sea público O que las políticas estén bien configuradas
2. Verifica que el usuario esté autenticado
3. Revisa los logs en el navegador para más detalles

### Si sigue dando error 404:
1. Verifica que el bucket `user-avatars` exista
2. Verifica que la tabla `user_profiles` exista
3. Ejecuta nuevamente el script SQL

### Si el avatar no se guarda en el perfil:
1. Verifica que la columna `avatar_url` exista en `user_profiles`
2. Verifica que el usuario tenga permisos de UPDATE en su propio perfil
3. Revisa la consola del navegador para errores de JavaScript

## Error de Caché de Esquema

Si después de ejecutar el script principal sigues viendo errores como:
```
Could not find the 'first_name' column of 'user_profiles' in the schema cache
```

### Solución:
1. Ejecuta el script `refresh_schema_cache.sql`
2. O reinicia manualmente:
   - Ve a **Settings** → **API** → **Restart API** en Supabase Dashboard
3. Espera 30-60 segundos para que se actualice el caché
4. Intenta nuevamente la funcionalidad

## Error 403 - Row Level Security (RLS)

Si ves errores como:
```
Error de subida: {statusCode: '403', error: 'Unauthorized', message: 'new row violates row-level security policy'}
```

### Causa:
Las políticas de Row Level Security en storage.objects están bloqueando la subida.

### Solución A: Configurar Políticas Correctamente
1. Ve a **Storage** → **user-avatars** → **Policies**
2. Asegúrate de que las políticas sean exactamente como se indicó arriba
3. Si existen políticas conflictivas, elimínalas primero

### Solución B: Usar Políticas Súper Permisivas (Recomendado para Testing)
Ejecuta el script `create_permissive_policies.sql` que:
- Elimina todas las políticas conflictivas
- Crea políticas muy abiertas pero seguras
- Mantiene RLS habilitado

### Solución C: Temporalmente Deshabilitar RLS para Testing
**⚠️ Solo para desarrollo/testing, NO para producción**

Ejecuta este script en SQL Editor:
```sql
-- TEMPORAL: Deshabilitar RLS en storage.objects para testing
-- NO usar en producción
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- Para volver a habilitar después:
-- ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
```

O usa el script `disable_rls_emergency.sql`

### Solución D: Hacer el Bucket Completamente Público (Más Simple)
1. Ve a **Storage** → **user-avatars**
2. Ve a **Configuration**
3. Activa **"Public bucket"**
4. Esto sobrepasa las políticas RLS

### Orden de Prueba Recomendado:
1. **Primero**: Solución A (configurar políticas correctamente)
2. **Si falla**: Solución B (políticas súper permisivas)
3. **Si falla**: Solución D (bucket público)
4. **Último recurso**: Solución C (deshabilitar RLS)

## Configuración Completa ✅

Una vez completados todos los pasos, deberías poder:
- ✅ Subir avatares desde el perfil de usuario
- ✅ Ver los avatares en el perfil
- ✅ Actualizar avatares sin problemas
- ✅ Los avatares se almacenan en Supabase Storage
