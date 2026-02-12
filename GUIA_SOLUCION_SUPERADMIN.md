# ✅ GUÍA COMPLETA: RESOLVER PROBLEMA CON PANEL SUPERADMIN

## 🔴 PROBLEMA
- ✅ Se puede crear usuario con rol "superadmin"
- ✅ El rol aparece en Supabase Auth (metadata)
- ❌ Cuando se intenta ingresar, no entra al panel superadmin
- ❌ No hay respuesta (app se congela o vuelve al login)

## 🔍 CAUSA IDENTIFICADA
**El trigger `handle_new_user()` no estaba creado en la base de datos Supabase.**

Sin este trigger, cuando se crea un usuario en `auth.users`, la tabla `usuarios` NO se llena automáticamente.

### Flujo Correcto:
1. Usuario se registra con `data: {'rol': 'superadmin'}`
2. Se crea en `auth.users` con `raw_user_meta_data->>'rol' = 'superadmin'`
3. ⚠️ **FALTA**: Trigger lee este rol y lo copia a tabla `usuarios`
4. Usuario intenta login
5. `auth.dart` consulta tabla `usuarios` para obtener el rol
6. Se encuentra el rol en la tabla y se rutea al panel correcto

## ✅ SOLUCIÓN: PASO A PASO

### PASO 1: Abrir SQL Editor en Supabase

1. Ve a https://app.supabase.com
2. Selecciona tu proyecto
3. Ve a **SQL Editor** (en el menú lateral)
4. Copia y pega TODO el contenido del archivo `SQL_SETUP.sql` actualizado

### PASO 2: Ejecutar el SQL

El SQL_SETUP.sql ahora contiene:

```sql
-- Función para manejar nuevos usuarios
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  user_rol TEXT;
BEGIN
  user_rol := NEW.raw_user_meta_data->>'rol';
  
  IF user_rol IS NULL OR user_rol = '' THEN
    user_rol := 'corredor';
  END IF;
  
  INSERT INTO public.usuarios (id, email, rol, activo)
  VALUES (NEW.id, NEW.email, user_rol, true)
  ON CONFLICT (id) DO UPDATE SET
    email = NEW.email,
    rol = user_rol,
    activo = true;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger automático
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();
```

**Importante**: Ejecuta TODO el archivo SQL_SETUP.sql, no solo este snippet.

### PASO 3: Verificar que el Trigger se Creó

En el SQL Editor, ejecuta:

```sql
SELECT trigger_name 
FROM information_schema.triggers 
WHERE event_object_table = 'users' AND trigger_schema = 'auth';
```

Deberías ver: `on_auth_user_created`

### PASO 4: Eliminar Usuarios Anteriores (Opcional pero Recomendado)

Si ya creaste usuarios de prueba con "superadmin" ANTES de crear el trigger:

```sql
-- Ver usuarios actuales
SELECT id, email, rol FROM usuarios;

-- Eliminar usuario de prueba si existe
DELETE FROM usuarios WHERE email = 'superadmin@example.com';

-- También eliminar de auth si quieres
DELETE FROM auth.users WHERE email = 'superadmin@example.com';
```

### PASO 5: Crear NUEVO Usuario Superadmin

Ahora sí:

1. Descarga e instala el APK actualizado (versión con debugging)
2. Ve a Registrarse
3. Email: `superadmin@test.com` (o el que quieras)
4. Contraseña: `password123` (o segura)
5. **Rol**: Selecciona **"Superadmin"** en el dropdown
6. Presiona "Registrarse"

### PASO 6: Verificar que se Creó Correctamente

En Supabase SQL Editor:

```sql
SELECT id, email, rol, activo FROM usuarios 
WHERE email = 'superadmin@test.com';
```

**Deberías ver**:
- `rol = 'superadmin'` (NO 'corredor')
- `activo = true`

### PASO 7: Probar el Login

1. Abre la app
2. Ve a Login
3. Usa: `superadmin@test.com` / `password123`
4. Presiona "Entrar"

**Lo que deberías ver**:
- Pantalla de carga que dice "Rol: superadmin"
- Luego: Panel Superadmin con mapa + gestión de usuarios

### PASO 8: Ver Logs de Debugging (Opcional)

Si algo sigue fallando, abre Terminal en VS Code:

```bash
# Ejecutar Flutter en modo debug
cd "/Users/brandonsantacruz/Downloads/Proyecto_Final_Moviles"
flutter run

# O con verbose para más detalles
flutter run -v
```

En la salida, busca logs que empiezan con `DEBUG AUTH:` o `DEBUG PANEL:`

Copía y comparte esos logs si necesitas ayuda.

## 📋 CHECKLIST FINAL

- [ ] Ejecuté SQL_SETUP.sql completo en Supabase
- [ ] Verifiqué que el trigger `on_auth_user_created` existe
- [ ] Eliminé usuarios anteriores (opcional)
- [ ] Creé nuevo usuario con rol "superadmin"
- [ ] Verifiqué en la tabla usuarios que rol = 'superadmin'
- [ ] Probé login y accedí al panel superadmin
- [ ] ✅ Panel superadmin carga correctamente

## 🆘 SI SIGUE SIN FUNCIONAR

Si después de estos pasos el panel superadmin NO carga:

1. **Verifica los logs** (`DEBUG AUTH:` en Flutter console)
2. **Revisa la tabla usuarios**: ¿El rol está correcto?
3. **Verifica RLS Policies**: ¿Puede superadmin consultar su propio registro?

**Command para resetear TODO** (si quieres empezar de cero):

```sql
-- ⚠️ CUIDADO: Esto ELIMINA TODOS LOS DATOS
DROP TABLE IF EXISTS ubicaciones_corredores CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- Luego ejecuta SQL_SETUP.sql de nuevo
```

## 📝 CAMBIOS REALIZADOS EN ESTA VERSIÓN

1. ✅ **SQL_SETUP.sql**: Agregué trigger `handle_new_user()`
2. ✅ **lib/auth.dart**: Logs detallados de debugging
3. ✅ **lib/pages/panel_superadmin.dart**: Logs en initState
4. ✅ **APK**: Recompilado con todos los cambios

## 🚀 PRÓXIMOS PASOS (DESPUÉS QUE FUNCIONE)

- [ ] Probar que Admin panel funciona
- [ ] Probar que Corredor panel funciona
- [ ] Crear 3-4 usuarios de prueba (1 admin, 2-3 corredores)
- [ ] Probar geolocalización en tiempo real
- [ ] Documentación final del proyecto

---

**¿Preguntas?** Revisa los logs de Flutter o comparte la captura del error.
