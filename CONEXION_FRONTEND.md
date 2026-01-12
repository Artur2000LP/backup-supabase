# 🔌 Guía de Conexión Frontend-Supabase

## ⚠️ IMPORTANTE: Consideraciones de Seguridad

Para **datos sensibles** (trámites, cotizaciones), **NO** conectes directamente el frontend a Supabase.

## 📊 Opciones de Conexión

### 🟢 **Opción 1: Solo lectura pública (SEGURO)**
```javascript
// Para mostrar estadísticas públicas, reportes, etc.
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'https://tu-proyecto.supabase.co',
  'tu-anon-key' // Solo permite lectura de datos públicos
)

// Ejemplo: Mostrar estadísticas de backups
const { data } = await supabase
  .from('backup_stats')
  .select('fecha, estado')
  .order('fecha', { ascending: false })
```

### 🟡 **Opción 2: API Backend personalizada (RECOMENDADO)**
```javascript
// Tu frontend llama a TU API
const response = await fetch('/api/backup-status', {
  method: 'GET',
  headers: {
    'Authorization': 'Bearer tu-token-app'
  }
})

// Tu API backend maneja Supabase con service_role_key
```

### 🔴 **Opción 3: Conexión directa completa (INSEGURO para datos sensibles)**
```javascript
// ❌ NO hacer esto con datos sensibles
const supabase = createClient(
  'https://tu-proyecto.supabase.co',
  'service_role_key' // ⚠️ Esto sería VISIBLE en el navegador
)
```

## 🏗️ Arquitectura Recomendada

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│  Frontend   │───▶│  GitHub API  │───▶│GitHub Actions│
│   (Público) │    │   (GitHub)   │    │ (Seguro)    │
└─────────────┘    └──────────────┘    └─────────────┘
                                              │
                                              ▼
                                    ┌─────────────┐
                                    │  Supabase   │
                                    │(Con secrets)│
                                    └─────────────┘
```

## 🎯 Para tu caso específico:

### **✅ Mantén lo actual para:**
- Backups automáticos
- Restauraciones
- Operaciones con datos sensibles

### **➕ Opcionalmente agrega:**
- Dashboard con estadísticas públicas
- Estado de último backup
- Logs de actividad (sin datos sensibles)

¿Te ayudo a implementar alguna de estas opciones?