# 🔒 Configuración de Secrets para GitHub Actions

## Secrets requeridos en GitHub

Para que el backup funcione de manera segura, configura estos secrets en tu repositorio:

1. Ve a: `https://github.com/TU_USUARIO/backup-supabase/settings/secrets/actions`
2. Click en **"New repository secret"**
3. Agrega cada uno de estos:

### 🎯 Secrets principales:

**Para Supabase en Hostinger/IsyPanel:**
```
SUPABASE_DB_URL
```
**Valor:** `postgresql://postgres:your-super-secret-and-long-postgres-password@TU-DOMINIO.COM:5432/postgres`
(Reemplaza TU-DOMINIO.COM con tu dominio real de Hostinger)

```
SUPABASE_PROJECT_REF
```
**Valor:** `hostinger-supabase` (o el nombre de tu proyecto)

```
SUPABASE_ANON_KEY
```
**Valor:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE`

```
SUPABASE_SERVICE_ROLE_KEY
```
**Valor:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJzZXJ2aWNlX3JvbGUiLAogICAgImlzcyI6ICJzdXBhYmFzZS1kZW1vIiwKICAgICJpYXQiOiAxNjQxNzY5MjAwLAogICAgImV4cCI6IDE3OTk1MzU2MDAKfQ.DaYlNEoUrrEn2Ig7tqibS-PHK5vgusbcbo7X36XVt4Q`

```
BACKUP_ENCRYPTION_KEY
```
**Valor:** Una clave segura para encriptar los backups (ej: `MiClave_SuperSegura_2026!`)

### 📍 Cómo obtener estos valores:

1. **Dashboard de Supabase** → Tu proyecto
2. **Settings** → **API**
3. Copia:
   - Project URL
   - Project Reference
   - anon key
   - service_role key

### 🚨 IMPORTANTE:
- ❌ **NUNCA** pongas estos valores directamente en el código
- ✅ **SIEMPRE** usa GitHub Secrets
- 🔒 Los secrets son **privados** aunque el repo sea público

## Variables del repositorio (opcional)

También puedes configurar variables para controlar el comportamiento:

```
BACKUP_ENABLED = true
```