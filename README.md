# Respaldo Automático de Base de Datos Supabase con GitHub Actions

Este repositorio proporciona una forma perfecta de automatizar los respaldos de tu base de datos Supabase usando GitHub Actions. Crea respaldos diarios de los roles, esquema y datos de tu base de datos, almacenándolos en tu repositorio. También incluye un mecanismo para restaurar fácilmente tu base de datos en caso de que algo salga mal.

## 🌐 Panel de Control Web

**¡Nuevo!** Ahora incluye un panel de control web completo hospedado en GitHub Pages para gestionar tus respaldos desde cualquier navegador.

### [🚀 Ver Demo del Panel](https://tu-usuario.github.io/supabase-database-backup/)

**Características del Panel Web:**
- ✨ Interfaz moderna y responsive
- 🔄 Ejecutar respaldos con un clic
- 📤 Restauraciones guiadas paso a paso  
- 📊 Historial visual de respaldos
- ⚙️ Configuración avanzada
- 📱 Compatible con dispositivos móviles

---

## Características

- **Respaldos Diarios Automáticos:** Los respaldos programados se ejecutan todos los días a medianoche.
- **Separación de Roles, Esquema y Datos:** Crea archivos de respaldo modulares para roles, esquema y datos.
- **Control Flexible del Flujo de Trabajo:** Habilita o deshabilita respaldos con una simple variable de entorno.
- **Integración con GitHub Actions:** Aprovecha GitHub Actions gratuito y confiable para automatización.
- **Restauración Fácil de Base de Datos:** Pasos claros para restaurar tu base de datos desde respaldos.
- **Panel Web de Control:** Interfaz gráfica para gestionar respaldos desde cualquier lugar.

---

## Comenzando

### 1. **Configuración de Variables del Repositorio**

Ve a la configuración de tu repositorio y navega a **Actions > Variables**. Agrega lo siguiente:

- **Secretos:**

  - `SUPABASE_DB_URL`: Tu cadena de conexión PostgreSQL de Supabase. Formato:  
    `postgresql://<USUARIO>:<CONTRASEÑA>@<HOST>:5432/postgres`

- **Variables:**
  - `BACKUP_ENABLED`: Establece `true` para habilitar respaldos o `false` para deshabilitarlos.

---

### 2. **Cómo Funciona el Flujo de Trabajo**

El flujo de trabajo de GitHub Actions se activa en:

- Push o pull requests a las ramas `main` o `dev`.
- Ejecución manual a través de la interfaz de GitHub.
- Una programación diaria a medianoche.

El flujo de trabajo realiza los siguientes pasos:

1. Verifica si los respaldos están habilitados usando la variable `BACKUP_ENABLED`.
2. Ejecuta el CLI de Supabase para crear tres archivos de respaldo:
   - `roles.sql`: Contiene roles y permisos.
   - `schema.sql`: Contiene la estructura de la base de datos.
   - `data.sql`: Contiene datos de las tablas.
3. Confirma los respaldos en el repositorio usando una acción de auto-commit.

---

### 3. **Restaurando Tu Base de Datos**

#### **Opción A: Restauración Automatizada vía GitHub Actions**

1. Ve a la pestaña **Actions** de tu repositorio
2. Selecciona el flujo de trabajo **"supabase-restore"**
3. Haz clic en **"Run workflow"** y proporciona:
   - **URL de BD Destino**: Tu nueva cadena de conexión de base de datos Supabase
   - **Fecha de Respaldo**: Fecha específica (YYYY-MM-DD) o "latest"
   - **Opciones**: Elige qué restaurar (roles, esquema, datos)

#### **Opción B: Restauración Manual**

**Usando PowerShell (Windows):**
```powershell
.\migrate-database.ps1 -BackupDir ".\prisma\backups\latest" -TargetDbUrl "postgresql://usuario:contraseña@host:5432/postgres"
```

**Usando Bash (Linux/Mac):**
```bash
./migrate-database.sh ./prisma/backups/latest postgresql://usuario:contraseña@host:5432/postgres
```

**Comandos CLI manuales:**
```bash
supabase db execute --db-url "<SUPABASE_DB_URL>" -f roles.sql
supabase db execute --db-url "<SUPABASE_DB_URL>" -f schema.sql
supabase db execute --db-url "<SUPABASE_DB_URL>" -f data.sql
```

#### **Migración a Nuevo Proyecto Supabase**

Cuando tu instancia de Supabase falle y necesites migrar a un nuevo proyecto:

1. **Crea un nuevo proyecto Supabase**
2. **Obtén la nueva URL de base de datos** desde la configuración del proyecto
3. **Ejecuta la restauración** usando cualquier método de arriba con la nueva URL
4. **Actualiza tus aplicaciones** para usar la nueva cadena de conexión

#### **Opciones Avanzadas de Restauración**

**Restauración selectiva:**
```powershell
# Solo restaurar esquema y datos (omitir roles)
.\migrate-database.ps1 -BackupDir ".\prisma\backups\2026-01-12" -TargetDbUrl $env:NEW_DB_URL -NoRoles

# Ejecución en seco para ver qué se restauraría
.\migrate-database.ps1 -BackupDir ".\prisma\backups\latest" -TargetDbUrl $env:TARGET_DB_URL -DryRun -Verbose
```

---

### 4. **Configurar Panel de Control Web (Opcional)**

Para acceder a una interfaz web para gestionar tus respaldos:

1. **Habilita GitHub Pages**:
   - Ve a **Settings** → **Pages** en tu repositorio
   - Selecciona **Deploy from a branch** → **main** → **/ (root)**
   - Guarda los cambios

2. **Accede al Panel**:
   - Tu panel estará en: `https://tu-usuario.github.io/nombre-repo/`
   - Configura tu token de GitHub y información del repositorio

3. **Gestiona desde el Web**:
   - Ejecuta respaldos manuales
   - Restaura bases de datos
   - Ve historial completo
   - Todo desde tu navegador o móvil

📖 **[Guía completa del Panel Web](docs/PANEL-WEB.md)**

---

### Control del Flujo de Trabajo

Usa la variable `BACKUP_ENABLED` para controlar si los respaldos se ejecutan:

- Establece `true` para habilitar respaldos.
- Establece `false` para omitir respaldos sin editar el archivo de flujo de trabajo.

## Requisitos

- Un proyecto Supabase con una base de datos PostgreSQL.
- CLI de Supabase instalado para restauración manual.
- Un repositorio de GitHub con Actions habilitado.

## Contribuyendo

¡Las contribuciones son bienvenidas! Si tienes mejoras o correcciones, no dudes en enviar un pull request.

## Licencia

Este proyecto está licenciado bajo la Licencia MIT. Consulta el archivo LICENSE para más detalles.
