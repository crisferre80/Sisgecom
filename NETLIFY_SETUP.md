# Configuración de Variables de Entorno para Netlify

## Variables Requeridas

Para que tu aplicación funcione correctamente en Netlify, necesitas configurar las siguientes variables de entorno en el panel de administración de Netlify:

### Variables de Supabase (REQUERIDAS)
```
VITE_SUPABASE_URL=https://iujpqyedxhbpqdifbmjy.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1anBxeWVkeGhicHFkaWZibWp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTExNjcwMDAsImV4cCI6MjA2Njc0MzAwMH0.9L_tKUic_CaY61Q7L_6HM1VdGDcOod2HvCdzmZ4b2N8
```

### Variables de Pago (OPCIONALES)
```
VITE_MERCADOPAGO_PUBLIC_KEY=tu_clave_publica_de_mercadopago
VITE_PAYPAL_CLIENT_ID=tu_client_id_de_paypal
```

## Cómo configurar en Netlify

1. Ve al panel de administración de Netlify
2. Selecciona tu sitio
3. Ve a **Site settings** > **Environment variables**
4. Agrega cada variable con su valor correspondiente
5. Asegúrate de que el nombre sea exacto (incluyendo el prefijo `VITE_`)
6. Haz un nuevo deploy después de configurar las variables

## Verificación Local

Para verificar que las variables están configuradas correctamente en desarrollo, ejecuta:

```bash
npm run dev
```

Si ves errores relacionados con variables de entorno, verifica que el archivo `.env` existe y contiene los valores correctos.

## Solución de Problemas

Si sigues viendo el error "supabaseUrl is required" después de configurar las variables:

1. Verifica que los nombres de las variables sean exactos
2. Asegúrate de que no hay espacios extra en los valores
3. Haz un "Clear cache and deploy" en Netlify
4. Verifica que las variables estén en la sección correcta de Netlify

## Build Command para Netlify

El comando de build debe ser:
```
npm run build
```

Y el directorio de publicación debe ser:
```
dist
```
