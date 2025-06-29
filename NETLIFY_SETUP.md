# ⚡ Solución al Error "supabaseUrl is required" en Netlify

## 🚨 Problema
El error `Uncaught Error: supabaseUrl is required` indica que Netlify no puede leer las variables de entorno necesarias para conectar con Supabase.

## ✅ Solución Paso a Paso

### 1. Configurar Variables de Entorno en Netlify

1. **Ve a tu panel de Netlify**: https://app.netlify.com
2. **Selecciona tu sitio**
3. **Ve a Site settings** (configuración del sitio)
4. **Busca "Environment variables"** en el menú lateral
5. **Haz clic en "Add variable"** para cada una de estas:

#### Variables Requeridas:

```
Nombre: VITE_SUPABASE_URL
Valor: https://iujpqyedxhbpqdifbmjy.supabase.co
```

```
Nombre: VITE_SUPABASE_ANON_KEY  
Valor: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1anBxeWVkeGhicHFkaWZibWp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTExNjcwMDAsImV4cCI6MjA2Njc0MzAwMH0.9L_tKUic_CaY61Q7L_6HM1VdGDcOod2HvCdzmZ4b2N8
```

### 2. Verificar Configuración de Build

En **Site settings → Build & deploy → Build settings**:

- **Build command**: `npm run build`
- **Publish directory**: `dist`
- **Node version**: 18 o superior

### 3. Hacer un Nuevo Deploy

⚠️ **IMPORTANTE**: Después de agregar las variables de entorno:

1. **Ve a Deploys**
2. **Haz clic en "Trigger deploy"**
3. **Selecciona "Deploy site"**

### 4. Verificación

Si configuraste todo correctamente, tu sitio debería:

- ✅ Cargar sin errores
- ✅ Mostrar el dashboard correctamente
- ✅ Permitir login/registro

Si aún hay errores:

- 🔍 **Abre las herramientas de desarrollador** (F12)
- 📋 **Revisa la consola** para ver mensajes de debug
- 🔄 **Verifica que los nombres de variables sean EXACTOS**

## 🛠️ Diagnóstico de Problemas

### Error Común 1: Variables con espacios
❌ `VITE_SUPABASE_URL = https://...` (con espacios)
✅ `VITE_SUPABASE_URL=https://...` (sin espacios)

### Error Común 2: Nombres incorrectos
❌ `SUPABASE_URL` (sin prefijo VITE_)
✅ `VITE_SUPABASE_URL` (con prefijo VITE_)

### Error Común 3: No hacer nuevo deploy
Netlify solo aplica las variables de entorno en **nuevos deploys**, no en deploys existentes.

## 🔧 Build Commands

Para verificar localmente antes de subir a Netlify:

```bash
# Verificar variables de entorno
npm run check-env

# Diagnosticar problemas
node scripts/diagnose-env.cjs

# Build para producción
npm run build

# Preview del build
npm run preview
```

## 📞 Si Necesitas Ayuda

Si el error persiste después de seguir estos pasos:

1. **Revisa la consola del navegador** en el sitio desplegado
2. **Verifica que las variables estén en Netlify** (no solo en tu archivo .env local)
3. **Asegúrate de haber hecho un nuevo deploy** después de agregar las variables
4. **Verifica que no hay caracteres especiales** en las variables de entorno

## ✨ Verificación Final

Tu aplicación debería:
- ✅ Cargar completamente
- ✅ Mostrar el formulario de login
- ✅ Conectar correctamente con Supabase
- ✅ No mostrar errores en la consola

¡Una vez configurado correctamente, tu Sistema de Gestión Comercial estará completamente funcional en Netlify!
