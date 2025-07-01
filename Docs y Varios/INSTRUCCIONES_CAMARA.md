# Instrucciones para el Escáner de Códigos de Barras

## ✅ NUEVAS MEJORAS IMPLEMENTADAS (29 de junio de 2025)

### 🔧 Soluciones para el problema "permisos concedidos pero cámara no enciende":

1. **Verificación más robusta de la cámara**: Ahora verificamos que los tracks de video estén realmente activos
2. **Configuraciones optimizadas**: Preferencia por cámara trasera, resolución específica y configuraciones experimentales
3. **Retraso en inicialización**: Se añadió un delay de 500ms antes de inicializar el escáner para evitar conflictos
4. **Manejo mejorado de streams**: Cierre adecuado de streams temporales antes de que html5-qrcode tome el control
5. **Botón de reintentar sin recargar**: Permite reinicializar el escáner sin perder el contexto de la aplicación
6. **Información de debug**: Botón para ver las cámaras disponibles en el dispositivo

### 📱 Escáner Nativo Alternativo:

Se agregó un **escáner nativo** como respaldo que usa directamente la API de WebRTC:
- **Botón dividido**: El botón principal usa html5-qrcode, el botón 📷 usa la cámara nativa
- **Captura manual**: Permite capturar una imagen y luego ingresar el código manualmente
- **Fallback robusto**: Si html5-qrcode falla, siempre hay una alternativa funcional

## Problemas Comunes y Soluciones

### La cámara no se abre
1. **Permisos de cámara**: El navegador debe tener permisos para acceder a la cámara
   - Chrome/Edge: Hacer clic en el icono de cámara en la barra de direcciones
   - Firefox: Hacer clic en el icono de escudo/cámara en la barra de direcciones
   - Safari: Ir a Configuración > Sitios web > Cámara

2. **HTTPS requerido**: Los navegadores modernos requieren HTTPS para acceder a la cámara
   - En desarrollo local, usar `https://localhost` en lugar de `http://localhost`
   - En producción, asegurar que el sitio tenga certificado SSL

3. **Navegador compatible**: Verificar que el navegador soporte WebRTC
   - Chrome 53+, Firefox 36+, Safari 11+, Edge 12+

### Pasos para habilitar la cámara

#### En Chrome/Chromium:
1. Hacer clic en el icono de cámara (🎥) en la barra de direcciones
2. Seleccionar "Permitir siempre"
3. Recargar la página

#### En Firefox:
1. Hacer clic en el icono de escudo en la barra de direcciones
2. Deshabilitar "Protección contra rastreo mejorada" para este sitio
3. Recargar la página y permitir el acceso a la cámara

#### En Safari:
1. Ir a Safari > Configuración > Sitios web
2. Seleccionar "Cámara" en la barra lateral izquierda
3. Configurar el sitio para "Permitir"

### Solución de problemas técnicos

#### Error "NotAllowedError":
- El usuario denegó el acceso a la cámara
- Solución: Permitir acceso en la configuración del navegador

#### Error "NotFoundError":
- No se encontró ninguna cámara en el dispositivo
- Solución: Conectar una cámara externa o verificar que la cámara integrada esté funcionando

#### Error "NotReadableError":
- La cámara está siendo usada por otra aplicación
- Solución: Cerrar otras aplicaciones que puedan estar usando la cámara

#### La página debe servirse por HTTPS:
- Error: "getUserMedia() no funciona en sitios inseguros"
- Solución: Acceder al sitio usando HTTPS

## Mejoras implementadas

### Escáner Principal (html5-qrcode):
1. **Verificación de compatibilidad**: El código ahora verifica si el navegador soporta acceso a cámara
2. **Solicitud explícita de permisos**: Se solicitan permisos y se verifica que la cámara realmente funcione
3. **Mejor manejo de errores**: Mensajes de error más específicos y útiles
4. **Estado de carga**: Indicador visual mientras se inicializa la cámara
5. **Botón de reintentar**: Permite reintentar sin recargar la página
6. **Configuración mejorada**: Soporte para linterna y zoom si están disponibles
7. **Debug de cámaras**: Información sobre las cámaras disponibles
8. **Configuraciones optimizadas**: Preferencia por cámara trasera y mejores parámetros

### Escáner Nativo (WebRTC directo):
1. **API nativa**: Usa directamente getUserMedia sin librerías intermedias
2. **Captura de imagen**: Permite capturar una foto del código de barras
3. **Entrada manual**: Opción para ingresar el código manualmente después de capturar
4. **Fallback robusto**: Siempre disponible como respaldo

## Uso recomendado

### Opción 1: Escáner Automático (Recomendado)
1. Hacer clic en el botón "Escanear" (el principal)
2. Permitir acceso a la cámara cuando se solicite
3. Apuntar la cámara hacia el código de barras
4. El código se escaneará automáticamente

### Opción 2: Escáner Nativo (Alternativa)
1. Hacer clic en el botón 📷 (junto al botón principal)
2. Permitir acceso a la cámara cuando se solicite
3. Capturar una imagen del código de barras
4. Ingresar el código manualmente

### Si ambos fallan:
- Verificar que el sitio esté en HTTPS (requerido en producción)
- Revisar permisos de cámara en el navegador
- Probar con un navegador diferente
- Verificar que ninguna otra aplicación esté usando la cámara
