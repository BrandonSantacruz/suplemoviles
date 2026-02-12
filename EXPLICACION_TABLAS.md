# 📊 ESTRUCTURA DE BASES DE DATOS - EXPLICACIÓN

## 🔍 TUS TABLAS ACTUALES

### 1️⃣ Tabla `profiles` (De template de Supabase)
```sql
create table public.profiles (
    id uuid primary key,
    email text,
    created_at timestamptz default now()
);
```
**Uso**: NO la necesitas. Es de la plantilla por defecto de Supabase.
**Recomendación**: Puedes eliminarla, pero no afecta nada.

---

### 2️⃣ Tabla `usuarios` (LA IMPORTANTE)
```sql
create table public.usuarios (
    id uuid primary key,
    email text not null,
    rol text default 'corredor',
    activo boolean default true,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);
```

**Propósito**: Guardar información de roles y estado de usuarios.

**Campos**:
- `id`: El UUID del usuario (viene de `auth.users`)
- `email`: El email del usuario
- `rol`: 'corredor', 'admin', o 'superadmin' ✅ **ESTE ES EL IMPORTANTE**
- `activo`: Si el usuario está activo (para desactivar sin eliminar)

**Problema anterior**: Esta tabla se llenaba con `rol = 'corredor'` por defecto, sin importar qué rol seleccionabas en el registro.

**Solución**: El trigger `handle_new_user()` que acabamos de agregar lee el rol de los metadatos de auth.users y lo guarda aquí.

---

### 3️⃣ Tabla `ubicaciones_corredores` (Geolocalización)
```sql
create table public.ubicaciones_corredores (
    id uuid primary key default gen_random_uuid(),
    usuario_id uuid not null,
    latitud numeric,
    longitud numeric,
    velocidad numeric,
    timestamp timestamptz default now(),
    updated_at timestamptz default now()
);
```

**Propósito**: Guardar las ubicaciones en tiempo real de los corredores.

**Campos**:
- `id`: ID único del registro de ubicación
- `usuario_id`: Referencia al usuario (debe existir en tabla usuarios)
- `latitud`: Coordenada GPS Y
- `longitud`: Coordenada GPS X
- `velocidad`: Velocidad actual (si lo calcula la app)
- `timestamp`: Cuándo se guardó la ubicación

**Uso en tu app**:
- Corredores envían su ubicación cada X segundos
- Superadmin/Admin consultan esta tabla para ver en el mapa
- Cada corredor tiene UN registro (UNIQUE(usuario_id))

---

## 🔄 FLUJO DE DATOS

### Cuando se registra un usuario:

```
ANTES (SIN trigger):
┌─────────────────────────────────────┐
│ Presiona "Registrarse"              │
├─────────────────────────────────────┤
│ 1. Flutter envía: signUp(            │
│    email: "test@example.com",        │
│    password: "123456",               │
│    data: {'rol': 'superadmin'}  👈   │
│   )                                  │
│                                      │
│ 2. Supabase crea en auth.users:      │
│    raw_user_meta_data: {             │
│      'rol': 'superadmin'   👈 AQUÍ   │
│    }                                  │
│                                      │
│ 3. ❌ PROBLEMA: Tabla usuarios       │
│    NO se actualiza automáticamente   │
│    Sigue teniendo 'corredor'         │
└─────────────────────────────────────┘

DESPUÉS (CON trigger):
┌─────────────────────────────────────┐
│ Presiona "Registrarse"              │
├─────────────────────────────────────┤
│ 1. Flutter envía: signUp(            │
│    data: {'rol': 'superadmin'}       │
│   )                                  │
│                                      │
│ 2. Supabase crea en auth.users ✅    │
│    raw_user_meta_data: {             │
│      'rol': 'superadmin'             │
│    }                                  │
│                                      │
│ 3. ✅ TRIGGER AUTOMÁTICO:            │
│    on_auth_user_created ejecuta      │
│    handle_new_user()                 │
│                                      │
│ 4. ✅ Tabla usuarios se llena:       │
│    id: UUID_DEL_USUARIO              │
│    email: "test@example.com"         │
│    rol: 'superadmin'     ✅ CORRECTO │
│    activo: true          ✅ CORRECTO │
└─────────────────────────────────────┘
```

### Cuando el usuario intenta loguear:

```
┌─────────────────────────────────────┐
│ Presiona "Entrar"                   │
├─────────────────────────────────────┤
│ 1. Flutter autentica en auth ✅      │
│                                      │
│ 2. auth.dart consulta tabla          │
│    "SELECT rol FROM usuarios         │
│     WHERE id = uuid_del_usuario"     │
│                                      │
│ 3. ✅ Obtiene: 'superadmin'          │
│    (porque el trigger lo guardó)     │
│                                      │
│ 4. ✅ Compara: rol == 'superadmin'   │
│    → Navega a PanelSuperAdmin        │
│                                      │
│ 5. ✅ Panel carga con:               │
│    - Mapa con ubicaciones            │
│    - Lista de corredores             │
│    - Botón para crear usuarios       │
└─────────────────────────────────────┘
```

---

## ✅ VERIFICAR QUE TODO ESTÁ CORRECTO

### Query 1: Ver estructura de usuarios
```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'usuarios';
```

**Esperado**: Columnas `id`, `email`, `rol`, `activo`, `created_at`, `updated_at`

---

### Query 2: Ver el trigger
```sql
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_schema = 'public';
```

**Esperado**: `on_auth_user_created` y otros triggers

---

### Query 3: Ver usuarios creados
```sql
SELECT id, email, rol, activo 
FROM usuarios 
ORDER BY created_at DESC;
```

**Esperado después de registro**:
```
id                                    | email                | rol         | activo
--------------------------------------|-------------------  |-------------|-------
550e8400-e29b-41d4-a716-446655440000 | superadmin@test.com | superadmin  | true
```

---

### Query 4: Verificar que RLS policies permiten lectura
```sql
SELECT * FROM usuarios 
WHERE id = 'TU_UUID_AQUI';
```

Deberías poder ver tu propio registro.

---

## 🔐 ROW LEVEL SECURITY (RLS) - PERMISOS

Las políticas de seguridad actuales:

### Tabla `usuarios`:
- ✅ Todos pueden ver su propio perfil (`auth.uid() = id`)
- ✅ Superadmin/Admin pueden ver TODOS (`rol IN ('admin', 'superadmin')`)
- ✅ Solo Superadmin/Admin pueden actualizar/eliminar

### Tabla `ubicaciones_corredores`:
- ✅ Corredores ven sus propias ubicaciones
- ✅ Superadmin/Admin ven TODAS
- ✅ Solo corredores pueden insertar/actualizar sus ubicaciones

---

## 🚨 POSIBLES PROBLEMAS Y SOLUCIONES

### Problema 1: "No se puede consultar la tabla usuarios"
**Causa**: RLS policy está bloqueando

**Solución**:
```sql
-- Verificar que la policy permite select
SELECT * FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'usuarios';

-- Si no hay policies o está rota, recrearla:
CREATE POLICY "Usuarios pueden ver su propio perfil"
  ON usuarios FOR SELECT
  USING (
    auth.uid() = id 
    OR (SELECT rol FROM usuarios WHERE id = auth.uid()) IN ('admin', 'superadmin')
  );
```

---

### Problema 2: "El usuario aparece en auth pero no en usuarios"
**Causa**: El trigger no se ejecutó (probablemente fue creado DESPUÉS de los usuarios)

**Solución**: Ejecutar SQL_SETUP.sql completo y crear nuevos usuarios

---

### Problema 3: "El usuario aparece en usuarios pero con rol = 'corredor'"
**Causa**: El trigger no está leyendo el rol de los metadatos

**Solución**: Verificar que el trigger existe:
```sql
SELECT prosrc FROM pg_proc 
WHERE proname = 'handle_new_user';
```

Deberías ver el código de la función. Si está vacío, recrearla.

---

## 📋 RESUMEN DE TABLAS QUE NECESITAS

| Tabla | Necesaria | Razón |
|-------|-----------|-------|
| `profiles` | ❌ No | Template de Supabase, no la uses |
| `usuarios` | ✅ Sí | Información de roles y estado |
| `ubicaciones_corredores` | ✅ Sí | Geolocalización en tiempo real |

---

## 🔧 MANTENIMIENTO

### Limpiar ubicaciones antiguas
```sql
-- Eliminar ubicaciones más viejas de 6 horas
DELETE FROM ubicaciones_corredores 
WHERE timestamp < NOW() - INTERVAL '6 hours';
```

### Ver estadísticas de usuarios por rol
```sql
SELECT rol, COUNT(*) as cantidad 
FROM usuarios 
GROUP BY rol;
```

### Desactivar usuario sin eliminar
```sql
UPDATE usuarios 
SET activo = false 
WHERE email = 'usuario@example.com';
```

---

**¿Preguntas sobre la estructura?** Revisa el archivo `SQL_SETUP.sql` para ver todas las queries.
