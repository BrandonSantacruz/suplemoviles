# ⚡ CHECKLIST RÁPIDO - PANEL SUPERADMIN

## 🎯 EL PROBLEMA EN 30 SEGUNDOS

El trigger `handle_new_user()` NO estaba en tu base de datos Supabase.

**Sin el trigger**: Cuando registras un usuario con `data: {'rol': 'superadmin'}`, el rol se guarda en `auth.users` (metadatos) pero NO en la tabla `usuarios`.

**Resultado**: Cuando el usuario intenta loguear, `auth.dart` consulta la tabla `usuarios` y encuentra `rol = 'corredor'` (valor por defecto), así que te rutea al panel de corredor, NO al superadmin.

---

## ✅ SOLUCIÓN EN 5 PASOS

### 1️⃣ Ejecuta SQL_SETUP.sql en Supabase
- Ve a: https://app.supabase.com
- Proyecto → SQL Editor
- Copia TODO el contenido de `SQL_SETUP.sql`
- Presiona "Run"

### 2️⃣ Verifica el Trigger
En SQL Editor, ejecuta:
```sql
SELECT trigger_name FROM information_schema.triggers 
WHERE event_object_table = 'users' AND trigger_schema = 'auth';
```
**Deberías ver**: `on_auth_user_created` ✅

### 3️⃣ Elimina Usuarios Anteriores (Importante)
```sql
DELETE FROM usuarios WHERE email = 'superadmin@ejemplo.com';
```
(Usa el email que hayas usado antes)

### 4️⃣ Descarga APK Nuevo
La app ya está compilada con debugging agregado.

```bash
# El APK está en:
build/app/outputs/flutter-apk/app-release.apk
```

### 5️⃣ Registra Nuevo Usuario Superadmin
- Registrarse
- Email: `superadmin@test.com`
- Contraseña: `password123`
- **Rol**: Selecciona "Superadmin"
- Registrarse

### 6️⃣ Verifica en SQL
```sql
SELECT email, rol FROM usuarios WHERE email = 'superadmin@test.com';
```
**Deberías ver**: `superadmin@test.com | superadmin` ✅

### 7️⃣ Login
- Login
- Email: `superadmin@test.com`
- Contraseña: `password123`
- Presiona "Entrar"

**Deberías ver**:
- Pantalla de carga: "Rol: superadmin"
- Luego: Panel con mapa + gestión de usuarios ✅

---

## 🚨 SI SIGUE SIN FUNCIONAR

**Ver logs de debugging**:
```bash
cd "/Users/brandonsantacruz/Downloads/Proyecto_Final_Moviles"
flutter run -v
```

Busca logs que empiezan con `DEBUG AUTH:` o `DEBUG PANEL:`

Copia y comparte todo lo que ves en la consola.

---

## 📊 VERIFICACIÓN RÁPIDA DE BASES DE DATOS

### ¿Existe el trigger?
```sql
SELECT prosrc FROM pg_proc WHERE proname = 'handle_new_user';
```
Deberías ver el código de la función.

### ¿Se creó el usuario con rol correcto?
```sql
SELECT id, email, rol, activo FROM usuarios 
WHERE email = 'superadmin@test.com';
```
Deberías ver: `rol = 'superadmin'`

### ¿Puedo consultar la tabla?
```sql
SELECT * FROM usuarios LIMIT 1;
```
Si da error de permisos = Problema de RLS policy.

---

## 📁 ARCHIVOS IMPORTANTES

| Archivo | Propósito |
|---------|-----------|
| `SQL_SETUP.sql` | ✅ Contiene el trigger (ya actualizado) |
| `lib/auth.dart` | ✅ Contiene logs de debugging |
| `lib/pages/panel_superadmin.dart` | ✅ Panel reescrito, sin errores |
| `lib/pages/registro.dart` | ✅ Dropdown con "superadmin" |
| `GUIA_SOLUCION_SUPERADMIN.md` | 📖 Guía detallada paso a paso |
| `EXPLICACION_TABLAS.md` | 📖 Explicación de estructura BD |

---

## 🎉 ESTADO ACTUAL

✅ **Compilación**: APK compilado sin errores
✅ **Código Dart**: Todos los archivos tienen la lógica correcta
✅ **SQL**: Trigger agregado a SQL_SETUP.sql
✅ **Debugging**: Logs agregados para diagnosticar problemas

⏳ **Pendiente**: Ejecutar SQL_SETUP.sql en tu Supabase y crear nuevo usuario

---

## 🔗 URLS ÚTILES

- Supabase Console: https://app.supabase.com
- GitHub Repo: https://github.com/BrandonSantacruz/suplemoviles
- OpenStreetMap: https://www.openstreetmap.org

---

**¿Listo?** Empieza por el Paso 1️⃣ arriba. 🚀
