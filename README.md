# Sistema de Gestión Comercial

Un sistema moderno de gestión comercial desarrollado con React, TypeScript y Supabase.

## 🚀 Características

- **Gestión de Inventario**: Control completo de productos y stock
- **Escáner de Códigos de Barras**: Lectura rápida de códigos para agilizar operaciones
- **Dashboard Intuitivo**: Visualización clara de métricas y datos importantes
- **Autenticación Segura**: Sistema de login robusto
- **Interfaz Moderna**: UI responsive construida con Tailwind CSS

## 🛠️ Tecnologías Utilizadas

- **Frontend**: React 18, TypeScript, Vite
- **Estilos**: Tailwind CSS
- **Backend**: Supabase (Base de datos, Autenticación, API)
- **Herramientas**: ESLint, PostCSS

## 📦 Instalación

1. Clona el repositorio:
```bash
git clone https://github.com/tu-usuario/sistema-gestion-comercial.git
cd sistema-gestion-comercial
```

2. Instala las dependencias:
```bash
npm install
```

3. Configura las variables de entorno:
```bash
cp .env.example .env
```
Edita el archivo `.env` con tus credenciales de Supabase.

4. Ejecuta las migraciones de la base de datos:
```bash
npx supabase db reset
```

5. Inicia el servidor de desarrollo:
```bash
npm run dev
```

## 🗄️ Base de Datos

El proyecto incluye migraciones de Supabase para configurar automáticamente:
- Tablas de productos
- Sistema de usuarios
- Configuraciones del inventario

## 📱 Uso

1. **Acceso**: Inicia sesión en el sistema
2. **Dashboard**: Visualiza el resumen de tu negocio
3. **Inventario**: Gestiona productos y stock
4. **Escáner**: Utiliza la cámara para leer códigos de barras

## 🤝 Contribución

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 📞 Contacto

Tu Nombre - [tu-email@ejemplo.com](mailto:tu-email@ejemplo.com)

Link del Proyecto: [https://github.com/tu-usuario/sistema-gestion-comercial](https://github.com/tu-usuario/sistema-gestion-comercial)
