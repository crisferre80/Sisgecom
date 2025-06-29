# 🚨 Solución: Error "Cannot find package 'vite'" en Netlify

## ❌ Problema
```
Cannot find package 'vite' imported from vite.config.ts
```

## ✅ SOLUCIÓN (YA IMPLEMENTADA)

### 1. **Movido Vite a Dependencies** 
En `package.json`, vite ahora está en `dependencies` (no `devDependencies`):

```json
"dependencies": {
  "@vitejs/plugin-react": "^4.3.1",
  "vite": "^5.4.2",
  "react": "^18.3.1",
  // ... otras
}
```

### 2. **Configuración Netlify**
```
Build command: npm run build-only
Publish directory: dist
```

### 3. **Variables de Entorno REQUERIDAS**
```
VITE_SUPABASE_URL=https://iujpqyedxhbpqdifbmjy.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1anBxeWVkeGhicHFkaWZibWp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTExNjcwMDAsImV4cCI6MjA2Njc0MzAwMH0.9L_tKUic_CaY61Q7L_6HM1VdGDcOod2HvCdzmZ4b2N8
```

## 🚀 PASOS PARA IMPLEMENTAR

1. **Commit estos cambios**:
```bash
git add .
git commit -m "fix: move vite to dependencies for Netlify"
git push
```

2. **En Netlify**:
   - Site settings → Build & deploy
   - Build command: `npm run build-only`
   - Publish directory: `dist`
   - Agregar variables de entorno

3. **Deploy nuevo**

## ✅ RESULTADO ESPERADO
- ✅ Build encuentra vite correctamente
- ✅ Build se completa sin errores
- ✅ Deploy exitoso
- ✅ App funciona con variables configuradas

---
**NOTA**: La clave es tener vite en `dependencies`, no en `devDependencies`.
