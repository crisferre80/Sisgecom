# Instrucciones para el Escáner de Códigos de Barras

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

1. **Verificación de compatibilidad**: El código ahora verifica si el navegador soporta acceso a cámara
2. **Solicitud explícita de permisos**: Se solicitan permisos antes de inicializar el escáner
3. **Mejor manejo de errores**: Mensajes de error más específicos y útiles
4. **Estado de carga**: Indicador visual mientras se inicializa la cámara
5. **Botón de reintentar**: Permite reintentar en caso de error
6. **Configuración mejorada**: Soporte para linterna y zoom si están disponibles

## Uso recomendado

1. Abrir el escáner desde el inventario
2. Permitir acceso a la cámara cuando se solicite
3. Apuntar la cámara hacia el código de barras
4. El código se escaneará automáticamente
5. El modal se cerrará y el código se aplicará al producto
