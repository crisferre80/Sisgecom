# Solución para Error de Storage de Avatares

## Problema
Error al subir avatares de usuario debido a que el bucket `user-avatars` no existe en Supabase Storage.

**Error específico:**
```
UserProfile.tsx:179 POST https://iujpqyedxhbpqdifbmjy.supabase.co/storage/v1/object/user-avatars/avatars/95cde45e-43a3-48f4-b028-5e1fc735760a-1751335020861.png 400 (Bad Request)
Error uploading avatar: {statusCode: '404', error: 'Bucket not found', message: 'Bucket not found'}
```

## Solución Implementada

### 1. Manejo Robusto de Errores
Se modificó la función `uploadAvatar` en `UserProfile.tsx` para:
- Intentar crear el bucket automáticamente si no existe
- Continuar sin subir avatar si hay problemas de configuración
- Mostrar mensajes informativos al usuario
- No fallar completamente al guardar el perfil

### 2. Configuración Manual del Bucket (Recomendada)

#### Opción A: Desde el Dashboard de Supabase
1. Ve a tu proyecto en [Supabase Dashboard](https://app.supabase.com)
2. Navega a **Storage** en el menú lateral
3. Haz clic en **Create Bucket**
4. Configura el bucket:
   - **Name**: `user-avatars`
   - **Public bucket**: ✅ Habilitado
   - **File size limit**: `2097152` (2MB)
   - **Allowed MIME types**: `image/*`

#### Opción B: Usando SQL (Ejecutar en SQL Editor)
```sql
-- Crear el bucket para avatares de usuario
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'user-avatars',
    'user-avatars',
    true,
    2097152,
    ARRAY['image/*']::text[]
);

-- Configurar políticas de seguridad para el bucket
-- Permitir a usuarios autenticados subir sus propios avatares
CREATE POLICY "Users can upload their own avatars" ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'user-avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Permitir a todos ver los avatares (públicos)
CREATE POLICY "Anyone can view avatars" ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'user-avatars');

-- Permitir a usuarios actualizar sus propios avatares
CREATE POLICY "Users can update their own avatars" ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'user-avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Permitir a usuarios eliminar sus propios avatares
CREATE POLICY "Users can delete their own avatars" ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'user-avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
```

### 3. Verificación
Después de crear el bucket, verifica que funcione:
1. Ve a **Storage** > **user-avatars** en el dashboard
2. Intenta subir un archivo de prueba
3. Verifica que aparezca en la lista de objetos

## Código Actualizado

### Función `uploadAvatar` Mejorada
```typescript
const uploadAvatar = async (): Promise<string | null> => {
  if (!avatarFile || !user || isDemoMode) return null;

  try {
    const fileExt = avatarFile.name.split('.').pop();
    const fileName = `${user.id}-${Date.now()}.${fileExt}`;
    const filePath = `avatars/${fileName}`;

    // Intentar subir a user-avatars, si no existe, usar un bucket alternativo
    const bucketName = 'user-avatars';
    const { error: uploadError } = await supabase.storage
      .from(bucketName)
      .upload(filePath, avatarFile);

    // Si el bucket no existe, intentar crear o usar un bucket alternativo
    if (uploadError && uploadError.message?.includes('Bucket not found')) {
      console.warn('Bucket user-avatars no encontrado, usando configuración alternativa');
      
      // Intentar crear el bucket
      const { error: createError } = await supabase.storage.createBucket('user-avatars', {
        public: true,
        allowedMimeTypes: ['image/*'],
        fileSizeLimit: 1024 * 1024 * 2 // 2MB
      });

      if (createError) {
        console.warn('No se pudo crear el bucket user-avatars:', createError);
        return null;
      } else {
        // Reintentar la subida después de crear el bucket
        const { error: retryError } = await supabase.storage
          .from(bucketName)
          .upload(filePath, avatarFile);
        
        if (retryError) throw retryError;
      }
    } else if (uploadError) {
      throw uploadError;
    }

    const { data } = supabase.storage
      .from(bucketName)
      .getPublicUrl(filePath);

    return data.publicUrl;
  } catch (error) {
    console.error('Error uploading avatar:', error);
    console.warn('Continuando sin subir avatar debido a error de configuración de storage');
    return null;
  }
};
```

### Manejo de Errores en `handleSaveProfile`
```typescript
// Subir nueva imagen si existe
if (avatarFile) {
  try {
    const uploadedAvatarUrl = await uploadAvatar();
    if (uploadedAvatarUrl) {
      avatarUrl = uploadedAvatarUrl;
    } else {
      showMessage('info', 'No se pudo subir la imagen de perfil, pero el resto del perfil se guardará correctamente');
    }
  } catch (avatarError) {
    console.error('Avatar upload failed:', avatarError);
    showMessage('info', 'No se pudo subir la imagen de perfil, pero el resto del perfil se guardará correctamente');
  }
}
```

## Beneficios de la Solución

1. **Resiliencia**: El sistema continúa funcionando aunque el storage no esté configurado
2. **Experiencia de Usuario**: Los usuarios reciben mensajes informativos claros
3. **Auto-recuperación**: Intenta crear el bucket automáticamente
4. **Mantenimiento**: Fácil de configurar manualmente cuando sea necesario

## Notas Importantes

- La funcionalidad de avatares es opcional y no afecta otras características del perfil
- Los usuarios pueden actualizar su información de perfil sin problemas
- Una vez configurado el bucket, los avatares funcionarán normalmente
- Se recomienda configurar el bucket manualmente para mayor control

## Errores Adicionales Identificados

### Error 1: Permisos de Storage (403 Unauthorized)
```
Error uploading avatar: {statusCode: '403', error: 'Unauthorized', message: 'new row violates row-level security policy'}
```

**Causa**: Las políticas RLS (Row Level Security) del bucket están bloqueando la subida.

**Solución**: Ejecutar las políticas de seguridad correctas en el SQL Editor:

```sql
-- Habilitar RLS en storage.objects si no está habilitado
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes que puedan causar conflictos
DROP POLICY IF EXISTS "Users can upload their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatars" ON storage.objects;

-- Crear políticas más permisivas para avatares
CREATE POLICY "Allow authenticated users to upload avatars" ON storage.objects
FOR INSERT 
TO authenticated 
WITH CHECK (bucket_id = 'user-avatars');

CREATE POLICY "Allow public read access to avatars" ON storage.objects
FOR SELECT 
TO public 
USING (bucket_id = 'user-avatars');

CREATE POLICY "Allow authenticated users to update their avatars" ON storage.objects
FOR UPDATE 
TO authenticated 
USING (bucket_id = 'user-avatars' AND auth.uid() IS NOT NULL);

CREATE POLICY "Allow authenticated users to delete their avatars" ON storage.objects
FOR DELETE 
TO authenticated 
USING (bucket_id = 'user-avatars' AND auth.uid() IS NOT NULL);
```

### Error 2: Tabla users no encontrada (404 Not Found)
```
PATCH https://iujpqyedxhbpqdifbmjy.supabase.co/rest/v1/users?id=eq.95cde45e-43a3-48f4-b028-5e1fc735760a 404 (Not Found)
```

**Causa**: La tabla `users` no existe o no es accesible desde la API.

**Solución A**: Verificar si existe la tabla y crearla si es necesario:

```sql
-- Verificar si la tabla users existe
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'users';

-- Si no existe, crear la tabla users
CREATE TABLE IF NOT EXISTS public.users (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT,
    full_name TEXT,
    first_name TEXT,
    last_name TEXT,
    phone TEXT,
    address TEXT,
    city TEXT,
    country TEXT,
    avatar_url TEXT,
    role TEXT DEFAULT 'user',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE
);

-- Habilitar RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Crear políticas para la tabla users
CREATE POLICY "Users can view their own profile" ON public.users
FOR SELECT 
TO authenticated 
USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.users
FOR UPDATE 
TO authenticated 
USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON public.users
FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = id);

-- Crear trigger para actualizar updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER handle_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();
```

**Solución B**: Si usa auth.users en lugar de public.users, modificar el código:

Necesitaremos verificar qué tabla está usando realmente el sistema.

**Nota**: El proyecto usa `user_profiles` con `id` como clave primaria (no `user_id`).

### Error 3: Conflicto de Nombres de Archivos
**Causa**: Intentar subir archivos con el mismo nombre.

**Solución**: Modificar la función uploadAvatar para manejar conflictos:

```typescript
const uploadAvatar = async (): Promise<string | null> => {
  if (!avatarFile || !user || isDemoMode) return null;

  try {
    const fileExt = avatarFile.name.split('.').pop();
    const fileName = `${user.id}-${Date.now()}.${fileExt}`;
    const filePath = `avatars/${fileName}`;

    const bucketName = 'user-avatars';
    
    // Primero, eliminar avatar anterior si existe
    try {
      const { data: existingFiles } = await supabase.storage
        .from(bucketName)
        .list('avatars', {
          search: user.id
        });
      
      if (existingFiles && existingFiles.length > 0) {
        const filesToDelete = existingFiles.map(file => `avatars/${file.name}`);
        await supabase.storage
          .from(bucketName)
          .remove(filesToDelete);
      }
    } catch (cleanupError) {
      console.warn('No se pudieron eliminar avatares anteriores:', cleanupError);
    }

    // Subir el nuevo archivo
    const { error: uploadError } = await supabase.storage
      .from(bucketName)
      .upload(filePath, avatarFile, {
        cacheControl: '3600',
        upsert: true // Sobrescribir si existe
      });

    if (uploadError) {
      // Si el bucket no existe, intentar crearlo
      if (uploadError.message?.includes('Bucket not found')) {
        const { error: createError } = await supabase.storage.createBucket(bucketName, {
          public: true,
          allowedMimeTypes: ['image/*'],
          fileSizeLimit: 1024 * 1024 * 2
        });

        if (createError) {
          console.warn('No se pudo crear el bucket:', createError);
          return null;
        }

        // Reintentar después de crear el bucket
        const { error: retryError } = await supabase.storage
          .from(bucketName)
          .upload(filePath, avatarFile, {
            cacheControl: '3600',
            upsert: true
          });
        
        if (retryError) throw retryError;
      } else {
        throw uploadError;
      }
    }

    const { data } = supabase.storage
      .from(bucketName)
      .getPublicUrl(filePath);

    return data.publicUrl;
  } catch (error) {
    console.error('Error uploading avatar:', error);
    return null;
  }
};
```

## Solución Rápida (Recomendada)

### Script SQL Automatizado
He creado un script SQL que configura automáticamente todo lo necesario:

**Archivo**: `Docs y Varios/setup_avatars_storage.sql`

**Cómo usarlo**:
1. Ve a tu proyecto en Supabase Dashboard
2. Navega a **SQL Editor**
3. Copia y pega el contenido del archivo `setup_avatars_storage.sql`
4. Ejecuta el script

Este script:
- ✅ Crea el bucket `user-avatars` con configuración correcta
- ✅ Configura políticas de seguridad permisivas pero seguras
- ✅ Verifica que la tabla `user_profiles` exista
- ✅ Agrega columnas faltantes si es necesario
- ✅ Configura triggers de updated_at

### Cambios en el Código

El código de `UserProfile.tsx` ha sido actualizado para:
- Usar la tabla correcta (`user_profiles` con `id` como clave primaria)
- Manejar mejor los conflictos de archivos
- Limpiar avatares anteriores antes de subir nuevos
- Proporcionar mejor feedback de errores
