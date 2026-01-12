# 🔒 Configuración de Secrets para GitHub Actions

## Secrets requeridos en GitHub

Para que el backup funcione de manera segura, configura estos secrets en tu repositorio:

1. Ve a: `https://github.com/TU_USUARIO/backup-supabase/settings/secrets/actions`
2. Click en **"New repository secret"**
3. Agrega cada uno de estos:

### 🎯 Secrets principales:

```
SUPABASE_DB_URL
```
**Valor:** `postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres`

```
SUPABASE_PROJECT_REF
```
**Valor:** Tu project reference de Supabase

```
SUPABASE_ANON_KEY
```
**Valor:** Tu anon/public key de Supabase

```
SUPABASE_SERVICE_ROLE_KEY
```
**Valor:** Tu service role key de Supabase (¡NUNCA la compartas!)

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