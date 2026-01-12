# Panel de Control Web para Respaldos Supabase

Una interfaz web moderna y fácil de usar para gestionar respaldos y restauraciones de tu base de datos Supabase directamente desde GitHub Pages.

## 🚀 Características del Panel Web

- ✨ **Interfaz Moderna**: Diseño responsivo y fácil de usar
- 🔄 **Control de Respaldos**: Ejecuta respaldos manuales con un clic  
- 📤 **Restauración Guiada**: Interface paso a paso para restauraciones
- 📊 **Historial Visual**: Ve todos tus respaldos y su estado
- ⚙️ **Configuración Avanzada**: Controla programación y retención
- 📱 **Compatible con Móvil**: Funciona perfectamente en dispositivos móviles

## 🌐 Configurar GitHub Pages

1. **Habilita GitHub Pages**:
   - Ve a tu repositorio → **Settings** → **Pages**
   - En **Source**, selecciona **Deploy from a branch**
   - Selecciona **main** branch y **/ (root)**
   - Haz clic en **Save**

2. **Accede a tu panel**:
   - Tu panel estará disponible en: `https://tu-usuario.github.io/supabase-database-backup/`
   - GitHub te mostrará la URL exacta en la configuración de Pages

## 🔧 Configuración Inicial

1. **Crea un Token de GitHub**:
   - Ve a [GitHub Settings → Developer settings → Personal access tokens](https://github.com/settings/tokens)
   - Genera un token con permisos: `repo`, `workflow`
   - Copia el token (empieza con `ghp_`)

2. **Configura el Panel**:
   - Abre tu panel web
   - Ingresa tu token de GitHub
   - Ingresa tu usuario/organización de GitHub
   - Ingresa el nombre del repositorio
   - Haz clic en **Guardar Configuración**

## 📱 Cómo Usar el Panel

### Crear Respaldo Manual
1. Haz clic en **"Crear Respaldo"**
2. Se ejecutará automáticamente
3. Ve el progreso en el historial

### Restaurar Base de Datos
1. Haz clic en **"Restaurar BD"**
2. Ingresa la URL de tu nueva base de datos Supabase
3. Selecciona qué restaurar (roles, esquema, datos)
4. Confirma la restauración

### Ver Historial
1. Haz clic en **"Historial"**
2. Ve todos los respaldos y restauraciones
3. Accede a detalles completos en GitHub

## 🔒 Seguridad

- **Token Local**: Tu token se guarda solo en tu navegador
- **HTTPS**: Todas las comunicaciones son seguras
- **GitHub API**: Usa la API oficial de GitHub
- **Sin Servidor**: Todo funciona desde el navegador

## 📋 Casos de Uso

### Migración de Emergencia
```
1. Tu Supabase se cae 🚨
2. Creas nuevo proyecto Supabase 
3. Abres el panel web desde tu móvil 📱
4. Restauras con un clic ✅
5. Actualizas tu app con nueva URL 🔄
```

### Respaldos Programados
- Ve el estado de respaldos automáticos
- Ejecuta respaldos manuales cuando necesites
- Controla la retención de archivos

### Desarrollo y Testing  
- Restaura diferentes versiones para testing
- Sincroniza bases de datos entre ambientes
- Gestiona respaldos de manera visual

## 🎯 Ventajas del Panel Web

✅ **Acceso desde cualquier lugar**: Solo necesitas internet  
✅ **No requiere instalaciones**: Funciona en cualquier navegador  
✅ **Interfaz amigable**: No necesitas saber comandos  
✅ **Gratis**: Hospedado en GitHub Pages sin costo  
✅ **Móvil**: Gestiona desde tu teléfono  
✅ **Tiempo real**: Estado actualizado automáticamente  

## 🔧 Personalización

El panel es completamente personalizable:
- Modifica colores en `styles.css`
- Ajusta funcionalidades en `script.js`  
- Cambia el diseño en `index.html`

## 📞 Soporte

Si tienes problemas:
1. Verifica tu token de GitHub
2. Asegúrate que el repositorio sea correcto
3. Revisa la consola del navegador (F12)
4. Verifica que GitHub Pages esté habilitado

---

¡Ahora puedes gestionar tus respaldos de Supabase desde cualquier lugar con una interfaz web profesional! 🎉